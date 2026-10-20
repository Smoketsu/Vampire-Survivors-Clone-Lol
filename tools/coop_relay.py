#!/usr/bin/env python3
"""Local co-op relay for Necropathy: the same protocol as the Cloudflare Worker (server/relay/PROTOCOL.md).

For development, the two-process network test (tools/coop_net_test.py) and the Playwright lobby check. It pairs
two players in a lobby named by a 5-letter code and relays their messages in order, with the Worker's checks,
limits, error codes and close codes. Keep the two in step: a change to one is a change to both.

Standard library only (asyncio with a small RFC 6455 WebSocket server): CI needs no pip install, and it can
answer the plain HTTP routes (POST /lobby, CORS preflight) that the `websockets` package refuses to parse.

    python3 tools/coop_relay.py [--host 127.0.0.1] [--port 8765] [--allow-origin '*'] [--quiet]

With --port 0 a free port is chosen. The first line printed is always `LISTENING <host> <port>`.
"""

import argparse
import asyncio
import base64
import hashlib
import json
import secrets
import struct
import sys
import time

# Protocol version spoken (hello `p`). Must match the Worker's PROTOCOL.
PROTOCOL = 1
# Code alphabet: 20 consonants (no vowels, so no words; no O / I / L to misread).
ALPHABET = "BCDFGHJKMNPQRSTVWXYZ"
# Letters in a code.
CODE_LENGTH = 5
# Largest accepted message, text or binary (bytes).
MAX_MESSAGE_BYTES = 16384
# Sustained message rate per socket (messages per second) and the burst allowance (messages).
MSG_RATE = 300.0
MSG_BURST = 600.0
# Sustained byte rate per socket (bytes per second) and the burst allowance (bytes).
BYTE_RATE = 65536.0
BYTE_BURST = 262144.0
# A new socket must send its hello within this time (s).
HELLO_TIMEOUT = 10.0
# A lobby made by POST /lobby stays reserved this long for its first player (s).
RESERVE_TIME = 120.0
# A lobby with no message for this long closes (s).
IDLE_TIME = 600.0
# A lobby older than this closes whatever happens (s).
MAX_AGE = 14400.0
# Period of the housekeeping pass (s).
CHECK_PERIOD = 1.0
# Longest kept hello strings (characters).
MAX_GAME_CHARS = 40
MAX_PLATFORM_CHARS = 16
MAX_NAME_CHARS = 24
# Largest HTTP request head read (bytes).
MAX_HEAD_BYTES = 8192
# GUID of the WebSocket handshake (RFC 6455).
WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
# Error code -> WebSocket close code (PROTOCOL.md "Error codes and close codes").
CLOSE_CODES = {
    "no_lobby": 4001,
    "full": 4002,
    "version": 4003,
    "started": 4004,
    "bad_hello": 4005,
    "host_left": 4006,
    "expired": 4007,
    "rate": 4008,
    "too_big": 4009,
    "protocol": 4010,
}


class Sock:
    """One accepted WebSocket: its stream, its seat (slot -1 until the hello) and its rate buckets."""

    def __init__(self, writer, lobby):
        self.w = writer  # asyncio StreamWriter of the connection.
        self.lobby = lobby  # Lobby joined (None for a refused code).
        self.slot = -1  # 0 = host, 1 = guest, -1 = no hello yet.
        self.gone = False  # True once dropped (no more sends or relays).
        self.at = time.monotonic()  # When the socket was accepted (s, monotonic).
        self.game = ""  # Hello: game version.
        self.platform = ""  # Hello: platform.
        self.name = ""  # Hello: player name.
        self.msgs = MSG_BURST  # Message bucket (messages).
        self.bytes = BYTE_BURST  # Byte bucket (bytes).
        self.bucket_at = time.monotonic()  # Last bucket refill (s, monotonic).

    def peer(self):
        """The hello fields the partner sees."""
        return {"slot": self.slot, "game": self.game, "platform": self.platform, "name": self.name}

    def frame(self, opcode, payload):
        """Writes one unmasked server frame."""
        if self.w.is_closing():
            return
        n = len(payload)
        if n < 126:
            head = struct.pack("!BB", 0x80 | opcode, n)
        elif n < 65536:
            head = struct.pack("!BBH", 0x80 | opcode, 126, n)
        else:
            head = struct.pack("!BBQ", 0x80 | opcode, 127, n)
        self.w.write(head + payload)

    def send_text(self, s):
        """Sends a text frame."""
        self.frame(0x1, s.encode("utf-8"))

    def send_obj(self, obj):
        """Sends `obj` as JSON text."""
        self.send_text(json.dumps(obj, separators=(",", ":")))

    def send_binary(self, b):
        """Sends a binary frame."""
        self.frame(0x2, b)

    def close(self, code, reason):
        """Sends a close frame and closes the stream."""
        self.frame(0x8, struct.pack("!H", code) + reason.encode("utf-8")[:120])
        try:
            self.w.close()
        except Exception:
            pass

    def allow(self, size):
        """True when a message of `size` bytes fits the rate buckets (and spends from them)."""
        now = time.monotonic()
        dt = now - self.bucket_at
        self.bucket_at = now
        self.msgs = min(MSG_BURST, self.msgs + dt * MSG_RATE) - 1.0
        self.bytes = min(BYTE_BURST, self.bytes + dt * BYTE_RATE) - size
        return self.msgs >= 0.0 and self.bytes >= 0.0


class Lobby:
    """One lobby: its code, times, flags and sockets."""

    def __init__(self, code, reserved):
        self.code = code  # The 5-letter code.
        self.created = time.monotonic()  # Creation time (s, monotonic).
        self.started = False  # True once the host sent `start`.
        self.reserved = reserved  # True for a POST /lobby lobby nobody has joined yet.
        self.socks = []  # Accepted sockets (players and those still owing a hello).
        self.active = self.created  # Time of the last message (s, monotonic).
        self.closed = False  # True once deleted (its sockets are being dropped).

    def live(self):
        """Sockets not yet dropped."""
        return [s for s in self.socks if not s.gone]

    def players(self):
        """Live sockets that sent their hello."""
        return [s for s in self.live() if s.slot >= 0]


class Relay:
    """The relay server: lobbies by code, the HTTP routes and the WebSocket loop."""

    def __init__(self, allow_origins, quiet):
        self.lobbies = {}  # Code -> Lobby.
        self.allow_origins = allow_origins  # Allowed browser origins ("*" = any).
        self.quiet = quiet  # True: no per-event log lines.

    def log(self, *args):
        if not self.quiet:
            print(*args, flush=True)

    def origin_ok(self, origin):
        return origin is None or "*" in self.allow_origins or origin in self.allow_origins

    def new_code(self):
        while True:
            code = "".join(secrets.choice(ALPHABET) for _ in range(CODE_LENGTH))
            if code not in self.lobbies:
                return code

    def create(self, reserved):
        lobby = Lobby(self.new_code(), reserved)
        self.lobbies[lobby.code] = lobby
        self.log("lobby", lobby.code, "created")
        return lobby

    def delete(self, lobby):
        if self.lobbies.get(lobby.code) is lobby:
            del self.lobbies[lobby.code]
            self.log("lobby", lobby.code, "deleted")
        lobby.closed = True
        for s in lobby.live():
            self.drop(s, "expired")

    def drop(self, s, err, detail=None):
        """Closes `s`, after an error message when `err` is set; a player's partner learns it left."""
        if s.gone:
            return
        s.gone = True
        if err:
            m = {"t": "error", "code": err}
            if detail is not None:
                m["detail"] = detail
            s.send_obj(m)
        s.close(CLOSE_CODES.get(err, 1008) if err else 1000, err or "bye")
        if s.lobby is not None and s.slot >= 0 and not s.lobby.closed:
            self.after_leave(s.lobby, s.slot)

    def after_leave(self, lobby, slot):
        for p in lobby.players():
            p.send_obj({"t": "left", "slot": slot})
        if slot == 0 and not lobby.started:
            for p in lobby.players():
                self.drop(p, "host_left")
        if not lobby.live():
            self.delete(lobby)

    def relay(self, lobby, slot, opcode, payload):
        for p in lobby.players():
            if p.slot != slot:
                p.frame(opcode, payload)

    def on_message(self, s, opcode, payload):
        lobby = s.lobby
        lobby.active = time.monotonic()
        if len(payload) > MAX_MESSAGE_BYTES:
            return self.drop(s, "too_big")
        if not s.allow(len(payload)):
            return self.drop(s, "rate")
        if opcode == 0x2:
            if s.slot < 0:
                return self.drop(s, "bad_hello")
            return self.relay(lobby, s.slot, 0x2, payload)
        try:
            m = json.loads(payload.decode("utf-8"))
        except Exception:
            m = None
        if not isinstance(m, dict) or not isinstance(m.get("t"), str):
            if s.slot < 0:
                self.drop(s, "bad_hello")
            return
        if s.slot < 0:
            if m["t"] != "hello":
                return self.drop(s, "bad_hello")
            return self.hello(s, m)
        t = m["t"]
        if t == "hello":
            return
        if t == "leave":
            return self.drop(s, None)
        if t == "start":
            if s.slot != 0:
                return
            lobby.started = True
            self.log("lobby", lobby.code, "started")
        self.relay(lobby, s.slot, 0x1, payload)

    def hello(self, s, m):
        lobby = s.lobby
        if m.get("p") != PROTOCOL:
            return self.drop(s, "protocol", PROTOCOL)
        game = m.get("game")
        if not isinstance(game, str) or game == "":
            return self.drop(s, "bad_hello")
        if self.lobbies.get(lobby.code) is not lobby:
            return self.drop(s, "no_lobby")
        if lobby.started:
            return self.drop(s, "started")
        others = lobby.players()
        if len(others) >= 2:
            return self.drop(s, "full")
        game = game[:MAX_GAME_CHARS]
        host = next((p for p in others if p.slot == 0), None)
        if host is not None and host.game != game:
            return self.drop(s, "version", host.game)
        s.slot = 1 if host is not None else 0
        s.game = game
        s.platform = str(m.get("platform", ""))[:MAX_PLATFORM_CHARS]
        s.name = str(m.get("name", ""))[:MAX_NAME_CHARS]
        lobby.reserved = False
        s.send_obj({"t": "welcome", "code": lobby.code, "slot": s.slot, "peer": host.peer() if host else None})
        if host is not None:
            host.send_obj({"t": "peer", "peer": s.peer()})
        self.log("lobby", lobby.code, "slot", s.slot, "joined", s.platform, s.name)

    async def housekeeping(self):
        while True:
            await asyncio.sleep(CHECK_PERIOD)
            now = time.monotonic()
            for lobby in list(self.lobbies.values()):
                for s in lobby.live():
                    if s.slot < 0 and now - s.at >= HELLO_TIMEOUT:
                        self.drop(s, "bad_hello")
                if self.lobbies.get(lobby.code) is not lobby:
                    continue
                if not lobby.players():
                    waiting = [s for s in lobby.live() if s.slot < 0]
                    if lobby.reserved and now - lobby.created < RESERVE_TIME:
                        continue
                    if waiting:
                        continue
                    self.delete(lobby)
                    continue
                if now - lobby.active > IDLE_TIME or now - lobby.created > MAX_AGE:
                    self.delete(lobby)

    # ------------------------------------------------------------------ HTTP

    @staticmethod
    def cors(origin):
        if origin is None:
            return {}
        return {
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "86400",
            "Vary": "Origin",
        }

    @staticmethod
    def respond(writer, status, reason, body=b"", headers=None):
        h = {"Content-Length": str(len(body)), "Connection": "close"}
        if body:
            h["Content-Type"] = "application/json"
        h.update(headers or {})
        head = "HTTP/1.1 %d %s\r\n" % (status, reason) + "".join("%s: %s\r\n" % kv for kv in h.items()) + "\r\n"
        writer.write(head.encode("latin-1") + body)

    async def handle(self, reader, writer):
        try:
            head = await reader.readuntil(b"\r\n\r\n")
        except Exception:
            writer.close()
            return
        if len(head) > MAX_HEAD_BYTES:
            writer.close()
            return
        lines = head.decode("latin-1").split("\r\n")
        try:
            method, target, _version = lines[0].split(" ", 2)
        except ValueError:
            writer.close()
            return
        headers = {}
        for line in lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()
        path = target.split("?", 1)[0].rstrip("/") or "/"
        origin = headers.get("origin")
        if not self.origin_ok(origin):
            self.respond(writer, 403, "Forbidden", b"origin not allowed")
            return await self.finish(writer)
        cors = self.cors(origin)
        if method == "OPTIONS":
            self.respond(writer, 204, "No Content", b"", cors)
            return await self.finish(writer)
        if method == "GET" and path in ("/", "/health"):
            self.respond(writer, 200, "OK", json.dumps({"ok": True, "protocol": PROTOCOL}).encode(), cors)
            return await self.finish(writer)
        if method == "POST" and path == "/lobby":
            n = int(headers.get("content-length", "0") or "0")
            if 0 < n <= 4096:
                await reader.readexactly(n)
            lobby = self.create(True)
            self.respond(writer, 201, "Created", json.dumps({"code": lobby.code}).encode(), cors)
            return await self.finish(writer)
        parts = path.split("/")
        if method == "GET" and len(parts) == 4 and parts[1] == "lobby" and parts[3] == "ws":
            if headers.get("upgrade", "").lower() != "websocket" or "sec-websocket-key" not in headers:
                self.respond(writer, 426, "Upgrade Required", b'{"error":"expected a WebSocket upgrade"}', cors)
                return await self.finish(writer)
            accept = base64.b64encode(hashlib.sha1((headers["sec-websocket-key"] + WS_GUID).encode()).digest()).decode()
            writer.write(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                          "Sec-WebSocket-Accept: %s\r\n\r\n" % accept).encode("latin-1"))
            code = parts[2].upper()
            if parts[2].lower() == "new":
                lobby = self.create(False)
            else:
                lobby = self.lobbies.get(code)
            s = Sock(writer, lobby)
            if lobby is None:
                self.drop(s, "no_lobby")
                return await self.finish(writer)
            lobby.socks.append(s)
            await self.ws_loop(reader, s)
            return
        self.respond(writer, 404, "Not Found", b'{"error":"not found"}', cors)
        await self.finish(writer)

    @staticmethod
    async def finish(writer):
        try:
            await writer.drain()
            writer.close()
        except Exception:
            pass

    async def ws_loop(self, reader, s):
        """Reads frames until the socket closes; whole messages go to on_message()."""
        parts = []  # Payloads of a fragmented message so far.
        first_op = 0  # Opcode of the fragmented message.
        try:
            while not s.gone:
                h = await reader.readexactly(2)
                fin = h[0] & 0x80
                op = h[0] & 0x0F
                masked = h[1] & 0x80
                n = h[1] & 0x7F
                if n == 126:
                    n = struct.unpack("!H", await reader.readexactly(2))[0]
                elif n == 127:
                    n = struct.unpack("!Q", await reader.readexactly(8))[0]
                if n > MAX_MESSAGE_BYTES or sum(len(p) for p in parts) + n > MAX_MESSAGE_BYTES:
                    self.drop(s, "too_big")
                    break
                mask = await reader.readexactly(4) if masked else b""
                data = await reader.readexactly(n)
                if masked:
                    data = bytes(b ^ mask[i & 3] for i, b in enumerate(data))
                if op == 0x8:  # Close.
                    self.drop(s, None)
                    break
                if op == 0x9:  # Ping: pong with the same data.
                    s.frame(0xA, data)
                    continue
                if op == 0xA:  # Pong.
                    continue
                if op in (0x1, 0x2):
                    first_op = op
                    parts = [data]
                elif op == 0x0:
                    parts.append(data)
                else:
                    self.drop(s, "bad_hello" if s.slot < 0 else None)
                    break
                if fin:
                    payload = b"".join(parts)
                    parts = []
                    self.on_message(s, first_op, payload)
                    await s.w.drain()
        except (asyncio.IncompleteReadError, ConnectionError, OSError):
            pass
        finally:
            self.drop(s, None)


async def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--host", default="127.0.0.1", help="address to listen on (default 127.0.0.1)")
    ap.add_argument("--port", type=int, default=8765, help="port (default 8765; 0 = any free port)")
    ap.add_argument("--allow-origin", default="*",
                    help="comma-separated browser origins allowed (default '*' = any)")
    ap.add_argument("--quiet", action="store_true", help="no per-event log lines")
    args = ap.parse_args()
    relay = Relay({o.strip() for o in args.allow_origin.split(",") if o.strip()}, args.quiet)
    server = await asyncio.start_server(relay.handle, args.host, args.port)
    port = server.sockets[0].getsockname()[1]
    print("LISTENING %s %d" % (args.host, port), flush=True)
    asyncio.get_running_loop().create_task(relay.housekeeping())
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit(0)
