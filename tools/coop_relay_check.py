#!/usr/bin/env python3
"""Protocol check of a Necropathy co-op relay (server/relay/PROTOCOL.md).

Runs the same scenario against any relay, so the Python relay (tools/coop_relay.py) and the Cloudflare Worker
(`wrangler dev` in server/relay, or the deployed workers.dev address) can be shown to behave the same: health,
create and join, the welcome / peer / left messages, text and binary relaying in order, start, full, version,
no_lobby, started, bad_hello, too_big, host_left and a POST /lobby reservation. Needs the `websockets` package
(pip install websockets).

    python3 tools/coop_relay_check.py http://127.0.0.1:8765

Exit status 0 when every check passes.
"""

import asyncio
import json
import sys
import urllib.request

import websockets

# Game version sent in the hellos (any string; the check only compares two of them).
GAME = "check-1"
# Binary messages relayed in the ordering check, each way.
ORDER_COUNT = 500
# Seconds to wait for one expected message.
TIMEOUT = 5.0

failures = []  # Names of the failed checks.


def check(name, ok, detail=""):
    print(("PASS " if ok else "FAIL ") + name + ((" (" + detail + ")") if detail and not ok else ""), flush=True)
    if not ok:
        failures.append(name)


async def recv_json(ws):
    while True:
        m = await asyncio.wait_for(ws.recv(), TIMEOUT)
        if isinstance(m, str):
            return json.loads(m)


async def connect(base, code, game=GAME, name="p", hello=True):
    ws = await websockets.connect(base + "/lobby/" + code + "/ws", max_size=None, open_timeout=TIMEOUT)
    if hello:
        try:
            await ws.send(json.dumps({"t": "hello", "p": 1, "game": game, "platform": "check", "name": name}))
        except websockets.exceptions.ConnectionClosed:
            pass  # Refused before the hello (no_lobby): the error is still in the receive buffer.
    return ws


async def expect_error(ws, code, close_code):
    m = await recv_json(ws)
    try:
        await asyncio.wait_for(ws.wait_closed(), TIMEOUT)
    except asyncio.TimeoutError:
        pass
    return m.get("t") == "error" and m.get("code") == code and ws.close_code == close_code, "%s / %s" % (m, ws.close_code)


async def run(http_base):
    ws_base = "ws" + http_base[4:] if http_base.startswith("http") else http_base
    with urllib.request.urlopen(http_base + "/health", timeout=TIMEOUT) as r:
        h = json.loads(r.read())
    check("health", h.get("ok") is True and h.get("protocol") == 1, str(h))

    host = await connect(ws_base, "new", name="Host")
    w = await recv_json(host)
    code = w.get("code", "")
    check("create: welcome slot 0", w.get("t") == "welcome" and w.get("slot") == 0 and w.get("peer") is None, str(w))
    check("code alphabet", len(code) == 5 and all(c in "BCDFGHJKMNPQRSTVWXYZ" for c in code), code)

    guest = await connect(ws_base, code.lower(), name="Guest")
    w = await recv_json(guest)
    check("join: welcome slot 1 with host peer", w.get("t") == "welcome" and w.get("slot") == 1
          and (w.get("peer") or {}).get("name") == "Host", str(w))
    p = await recv_json(host)
    check("host hears peer", p.get("t") == "peer" and p["peer"].get("name") == "Guest" and p["peer"].get("slot") == 1, str(p))

    third = await connect(ws_base, code, name="Third")
    ok, d = await expect_error(third, "full", 4002)
    check("third player: full", ok, d)

    await host.send(json.dumps({"t": "loadout", "x": 1}))
    m = await recv_json(guest)
    check("text relay host->guest", m == {"t": "loadout", "x": 1}, str(m))
    await guest.send(json.dumps({"t": "loadout", "x": 2}))
    m = await recv_json(host)
    check("text relay guest->host", m == {"t": "loadout", "x": 2}, str(m))

    for i in range(ORDER_COUNT):
        await host.send(i.to_bytes(4, "big") + bytes(i % 7))
        await guest.send(i.to_bytes(4, "big"))
    got_g = [int.from_bytes((await asyncio.wait_for(guest.recv(), TIMEOUT))[:4], "big") for _ in range(ORDER_COUNT)]
    got_h = [int.from_bytes((await asyncio.wait_for(host.recv(), TIMEOUT))[:4], "big") for _ in range(ORDER_COUNT)]
    check("binary order both ways", got_g == list(range(ORDER_COUNT)) and got_h == list(range(ORDER_COUNT)))

    await guest.send(b"x" * 20000)
    ok, d = await expect_error(guest, "too_big", 4009)
    check("too_big", ok, d)
    m = await recv_json(host)
    check("host hears left after too_big", m == {"t": "left", "slot": 1}, str(m))

    bad = await connect(ws_base, code, game="other-version", name="Old")
    ok, d = await expect_error(bad, "version", 4003)
    check("version mismatch", ok, d)

    guest = await connect(ws_base, code, name="Guest2")
    w = await recv_json(guest)
    await recv_json(host)  # peer
    check("rejoin slot 1", w.get("slot") == 1, str(w))
    await host.send(json.dumps({"t": "start", "info": {"seed": 7}}))
    m = await recv_json(guest)
    check("start relayed", m.get("t") == "start" and m["info"]["seed"] == 7, str(m))
    late = await connect(ws_base, code, name="Late")
    ok, d = await expect_error(late, "started", 4004)
    check("join after start: started", ok, d)
    await guest.send(json.dumps({"t": "leave"}))
    m = await recv_json(host)
    check("leave after start: host hears left, stays", m == {"t": "left", "slot": 1}, str(m))
    await host.close()

    for c, name in (("AEIOU", "malformed code"), ("BBBBB", "unknown code")):
        ws = await connect(ws_base, c)
        ok, d = await expect_error(ws, "no_lobby", 4001)
        check(name + ": no_lobby", ok, d)

    host = await connect(ws_base, "new", name="H")
    code = (await recv_json(host))["code"]
    ws = await connect(ws_base, code, hello=False)
    await ws.send(json.dumps({"t": "loadout"}))
    ok, d = await expect_error(ws, "bad_hello", 4005)
    check("first message not hello: bad_hello", ok, d)
    guest = await connect(ws_base, code, name="G")
    await recv_json(guest)
    await recv_json(host)
    await host.send(json.dumps({"t": "leave"}))
    m1 = await recv_json(guest)
    ok, d = await expect_error(guest, "host_left", 4006)
    check("host leaves before start: left then host_left", m1 == {"t": "left", "slot": 0} and ok, "%s %s" % (m1, d))
    ws = await connect(ws_base, code)
    ok, d = await expect_error(ws, "no_lobby", 4001)
    check("closed lobby's code is gone", ok, d)

    req = urllib.request.Request(http_base + "/lobby", data=b"", method="POST")
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        code = json.loads(r.read()).get("code", "")
        status = r.status
    check("POST /lobby", status == 201 and len(code) == 5, "%s %s" % (status, code))
    host = await connect(ws_base, code, name="H")
    w = await recv_json(host)
    check("reserved lobby: first joiner is host", w.get("slot") == 0 and w.get("code") == code, str(w))
    await host.close()

    req = urllib.request.Request(http_base + "/health", headers={"Origin": "https://smoketsu.github.io"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        acao = r.headers.get("Access-Control-Allow-Origin")
    check("CORS for the Pages origin", acao == "https://smoketsu.github.io", str(acao))


def main():
    base = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8765").rstrip("/")
    asyncio.run(run(base))
    print("%d failure(s)" % len(failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
