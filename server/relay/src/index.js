// Necropathy co-op relay: a Cloudflare Worker with one Durable Object per lobby.
//
// It hands out 5-letter lobby codes and relays the two players' messages to each other in order (the protocol,
// its limits and error codes are in ../PROTOCOL.md; tools/coop_relay.py is the same relay in Python for local
// tests and must stay identical). The Worker routes each request: `/lobby/new/ws` and `POST /lobby` pick a free
// code (retrying on a collision) and create that lobby's Durable Object; `/lobby/CODE/ws` goes to lobby CODE's
// object. Each Lobby object accepts its sockets through the WebSocket Hibernation API (ctx.acceptWebSocket), so
// a lobby waiting for its guest costs nothing while idle; per-socket state (slot, hello fields) lives in the
// socket attachment and the lobby's own state (code, created, started) in its storage, so both survive
// hibernation. Lobbies are SQLite-backed (wrangler.toml `new_sqlite_classes`), which the free plan allows.
import { DurableObject } from "cloudflare:workers";

// Protocol version spoken (hello `p`); bumped on any incompatible change. Range: 1+.
const PROTOCOL = 1;
// Code alphabet: 20 consonants (no vowels, so no words; no O / I / L to misread).
const ALPHABET = "BCDFGHJKMNPQRSTVWXYZ";
// Letters in a code.
const CODE_LENGTH = 5;
// Tries at a free code before giving up (each try is one Durable Object request).
const CREATE_TRIES = 8;
// Largest accepted message, text or binary (bytes).
const MAX_MESSAGE_BYTES = 16384;
// Sustained message rate per socket (messages per second) and the burst allowance (messages).
const MSG_RATE = 300;
const MSG_BURST = 600;
// Sustained byte rate per socket (bytes per second) and the burst allowance (bytes).
const BYTE_RATE = 65536;
const BYTE_BURST = 262144;
// A new socket must send its hello within this time (ms).
const HELLO_TIMEOUT_MS = 10000;
// A lobby made by POST /lobby stays reserved this long for its first player (ms).
const RESERVE_MS = 120000;
// A lobby with no message for this long closes (ms): 10 minutes.
const IDLE_MS = 600000;
// A lobby older than this closes whatever happens (ms): 4 hours.
const MAX_AGE_MS = 14400000;
// Period of the housekeeping alarm while players are connected (ms).
const CHECK_MS = 60000;
// The last-activity time is written to storage at most this often (ms), to keep storage writes low.
const ACTIVE_WRITE_MS = 60000;
// Lobby creations allowed per client IP per window (best effort, per Worker isolate), and the window (ms).
const CREATE_LIMIT = 20;
const CREATE_WINDOW_MS = 600000;
// Longest kept hello strings (characters): game version, platform, player name.
const MAX_GAME_CHARS = 40;
const MAX_PLATFORM_CHARS = 16;
const MAX_NAME_CHARS = 24;
// Error code -> WebSocket close code (PROTOCOL.md "Error codes and close codes").
const CLOSE_CODES = {
  no_lobby: 4001,
  full: 4002,
  version: 4003,
  started: 4004,
  bad_hello: 4005,
  host_left: 4006,
  expired: 4007,
  rate: 4008,
  too_big: 4009,
  protocol: 4010,
};

// Client IP -> {count, since} of recent lobby creations (best effort: one map per isolate).
const createLog = new Map();

// A JSON HTTP response with `status`, plus CORS headers for `origin`.
function json(body, status, origin) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
  });
}

// CORS headers echoing an allowed `origin` (none for a request without an Origin header).
function corsHeaders(origin) {
  if (!origin) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

// True when `origin` may use the relay: no Origin header (the desktop game) or one of ALLOWED_ORIGINS.
function originAllowed(origin, env) {
  if (!origin) return true;
  const list = String(env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s !== "");
  return list.includes("*") || list.includes(origin);
}

// A random lobby code (rejection sampling keeps every letter equally likely).
function randomCode() {
  const out = [];
  const buf = new Uint8Array(16);
  while (out.length < CODE_LENGTH) {
    crypto.getRandomValues(buf);
    for (const b of buf) {
      if (b < 240 && out.length < CODE_LENGTH) out.push(ALPHABET[b % ALPHABET.length]);
    }
  }
  return out.join("");
}

// True when `code` is CODE_LENGTH letters of ALPHABET (already upper-cased).
function validCode(code) {
  if (code.length !== CODE_LENGTH) return false;
  for (const ch of code) if (!ALPHABET.includes(ch)) return false;
  return true;
}

// True when client `ip` may create another lobby now (and counts this one).
function mayCreate(ip) {
  const now = Date.now();
  const e = createLog.get(ip);
  if (!e || now - e.since > CREATE_WINDOW_MS) {
    createLog.set(ip, { count: 1, since: now });
    if (createLog.size > 10000) createLog.clear(); // Bounded memory.
    return true;
  }
  e.count += 1;
  return e.count <= CREATE_LIMIT;
}

// Accepts a WebSocket in the Worker only to refuse it: sends the error, then closes (for malformed codes).
function refuseSocket(err) {
  const pair = new WebSocketPair();
  const [client, server] = Object.values(pair);
  server.accept();
  server.send(JSON.stringify({ t: "error", code: err }));
  server.close(CLOSE_CODES[err] || 1008, err);
  return new Response(null, { status: 101, webSocket: client });
}

// Forwards `request` to lobby `code`'s Durable Object; `create` asks it to make the lobby first.
function toLobby(env, request, code, create) {
  const headers = new Headers(request.headers);
  headers.set("X-Lobby-Code", code);
  headers.set("X-Lobby-Create", create ? "1" : "0");
  const stub = env.LOBBY.get(env.LOBBY.idFromName(code));
  return stub.fetch(new Request(request.url, { method: request.method, headers }));
}

// Creates a lobby under a free code (POST /lobby, or /lobby/new/ws with the upgrade passed on).
async function createLobby(env, request, origin) {
  const ip = request.headers.get("CF-Connecting-IP") || "local";
  if (!mayCreate(ip)) return json({ error: "rate" }, 429, origin);
  for (let i = 0; i < CREATE_TRIES; i++) {
    const res = await toLobby(env, request, randomCode(), true);
    if (res.status !== 409) {
      if (res.webSocket) return res;
      const body = await res.text();
      return new Response(body, { status: res.status, headers: { "Content-Type": "application/json", ...corsHeaders(origin) } });
    }
  }
  return json({ error: "busy" }, 503, origin);
}

export default {
  // Routes every request (see PROTOCOL.md "HTTP").
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin");
    if (!originAllowed(origin, env)) return new Response("origin not allowed", { status: 403 });
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders(origin) });
    const path = url.pathname.replace(/\/+$/, "") || "/";
    if (request.method === "GET" && (path === "/" || path === "/health")) {
      return json({ ok: true, protocol: PROTOCOL }, 200, origin);
    }
    if (request.method === "POST" && path === "/lobby") return createLobby(env, request, origin);
    const m = path.match(/^\/lobby\/([A-Za-z]+)\/ws$/);
    if (m && request.method === "GET") {
      if ((request.headers.get("Upgrade") || "").toLowerCase() !== "websocket") {
        return json({ error: "expected a WebSocket upgrade" }, 426, origin);
      }
      if (m[1].toLowerCase() === "new") return createLobby(env, request, origin);
      const code = m[1].toUpperCase();
      if (!validCode(code)) return refuseSocket("no_lobby");
      return toLobby(env, request, code, false);
    }
    return json({ error: "not found" }, 404, origin);
  },
};

// One lobby: up to two players' sockets, relaying between them.
export class Lobby extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    // Cached lobby record from storage ({code, created, started, reserved}); undefined = not loaded, null = none.
    this.record = undefined;
    // Time of the last message (ms since the epoch; 0 = none since the object woke).
    this.lastActive = 0;
    // When `active` was last written to storage (ms since the epoch).
    this.lastStored = 0;
    // WebSocket -> its rate buckets {msgs, bytes, at}; lost on hibernation, which only happens while idle.
    this.buckets = new Map();
  }

  // The lobby record (loaded once per wake-up).
  async lobby() {
    if (this.record === undefined) this.record = (await this.ctx.storage.get("lobby")) || null;
    return this.record;
  }

  // Stores the lobby record.
  async saveLobby(rec) {
    this.record = rec;
    await this.ctx.storage.put("lobby", rec);
  }

  // Schedules the alarm at `t` unless one is already due sooner.
  async alarmBy(t) {
    const cur = await this.ctx.storage.getAlarm();
    if (cur === null || cur > t) await this.ctx.storage.setAlarm(t);
  }

  // A request routed here by the Worker (create and / or join).
  async fetch(request) {
    const code = request.headers.get("X-Lobby-Code") || "";
    const create = request.headers.get("X-Lobby-Create") === "1";
    const upgrade = (request.headers.get("Upgrade") || "").toLowerCase() === "websocket";
    let rec = await this.lobby();
    if (create) {
      if (rec) return new Response("taken", { status: 409 });
      rec = { code, created: Date.now(), started: false, reserved: !upgrade };
      await this.saveLobby(rec);
      await this.alarmBy(Date.now() + (upgrade ? HELLO_TIMEOUT_MS : RESERVE_MS));
      if (!upgrade) return new Response(JSON.stringify({ code }), { status: 201, headers: { "Content-Type": "application/json" } });
    }
    if (!upgrade) return new Response("expected a WebSocket upgrade", { status: 426 });
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ slot: -1, at: Date.now(), gone: false });
    if (!rec) {
      this.drop(server, "no_lobby");
    } else {
      await this.alarmBy(Date.now() + HELLO_TIMEOUT_MS);
    }
    return new Response(null, { status: 101, webSocket: client });
  }

  // Every live socket with its attachment: [{ws, att}] (sockets already dropped are left out).
  sockets() {
    const out = [];
    for (const ws of this.ctx.getWebSockets()) {
      const att = ws.deserializeAttachment();
      if (att && !att.gone) out.push({ ws, att });
    }
    return out;
  }

  // The live sockets that sent their hello (the players).
  players() {
    return this.sockets().filter((s) => s.att.slot >= 0);
  }

  // Sends object `obj` as JSON text to `ws` (errors ignored: the socket is closing).
  send(ws, obj) {
    try {
      ws.send(JSON.stringify(obj));
    } catch (_e) {
      // Closed under us.
    }
  }

  // Relays `msg` (string or ArrayBuffer) from the player in `slot` to the other player, if any.
  relay(slot, msg) {
    for (const p of this.players()) {
      if (p.att.slot !== slot) {
        try {
          p.ws.send(msg);
        } catch (_e) {
          // Closed under us.
        }
      }
    }
  }

  // Notes activity (an idle lobby expires); writes it to storage at most every ACTIVE_WRITE_MS.
  touch() {
    const now = Date.now();
    this.lastActive = now;
    if (now - this.lastStored > ACTIVE_WRITE_MS) {
      this.lastStored = now;
      this.ctx.storage.put("active", now);
    }
  }

  // True when a message of `size` bytes fits `ws`'s rate buckets (and spends from them).
  allow(ws, size) {
    const now = Date.now();
    let b = this.buckets.get(ws);
    if (!b) {
      b = { msgs: MSG_BURST, bytes: BYTE_BURST, at: now };
      this.buckets.set(ws, b);
    }
    const dt = (now - b.at) / 1000;
    b.at = now;
    b.msgs = Math.min(MSG_BURST, b.msgs + dt * MSG_RATE) - 1;
    b.bytes = Math.min(BYTE_BURST, b.bytes + dt * BYTE_RATE) - size;
    return b.msgs >= 0 && b.bytes >= 0;
  }

  // Closes `ws`, after an error message when `err` is set; a player's partner learns it left.
  drop(ws, err, detail) {
    const att = ws.deserializeAttachment() || { slot: -1 };
    if (att.gone) return;
    ws.serializeAttachment({ ...att, gone: true });
    this.buckets.delete(ws);
    if (err) {
      const m = { t: "error", code: err };
      if (detail !== undefined) m.detail = detail;
      this.send(ws, m);
    }
    try {
      ws.close(err ? CLOSE_CODES[err] || 1008 : 1000, err || "bye");
    } catch (_e) {
      // Already closed.
    }
    if (att.slot >= 0) this.ctx.waitUntil(this.afterLeave(att.slot));
  }

  // A player in `slot` left: the partner hears `left`; the host leaving before the start closes the lobby; an
  // empty lobby is deleted.
  async afterLeave(slot) {
    const rec = await this.lobby();
    for (const p of this.players()) this.send(p.ws, { t: "left", slot });
    if (slot === 0 && rec && !rec.started) {
      for (const p of this.players()) this.drop(p.ws, "host_left");
    }
    if (this.sockets().length === 0) await this.cleanup();
  }

  // Deletes the lobby (its code becomes free).
  async cleanup() {
    for (const s of this.sockets()) this.drop(s.ws, "expired");
    this.record = null;
    await this.ctx.storage.deleteAlarm();
    await this.ctx.storage.deleteAll();
  }

  // A message from a socket (Hibernation API).
  async webSocketMessage(ws, message) {
    const att = ws.deserializeAttachment() || { slot: -1 };
    if (att.gone) return;
    this.touch();
    const size = typeof message === "string" ? new TextEncoder().encode(message).length : message.byteLength;
    if (size > MAX_MESSAGE_BYTES) return this.drop(ws, "too_big");
    if (!this.allow(ws, size)) return this.drop(ws, "rate");
    if (typeof message !== "string") {
      if (att.slot < 0) return this.drop(ws, "bad_hello");
      return this.relay(att.slot, message);
    }
    let m = null;
    try {
      m = JSON.parse(message);
    } catch (_e) {
      m = null;
    }
    if (!m || typeof m !== "object" || typeof m.t !== "string") {
      if (att.slot < 0) this.drop(ws, "bad_hello");
      return; // A player's malformed text is ignored.
    }
    if (att.slot < 0) {
      if (m.t !== "hello") return this.drop(ws, "bad_hello");
      return this.hello(ws, att, m);
    }
    switch (m.t) {
      case "hello":
        return; // Only the first counts.
      case "leave":
        return this.drop(ws, null);
      case "start": {
        if (att.slot !== 0) return;
        const rec = await this.lobby();
        if (rec && !rec.started) await this.saveLobby({ ...rec, started: true });
        return this.relay(0, message);
      }
      default:
        return this.relay(att.slot, message);
    }
  }

  // A socket's hello: checks it and seats the player (host first, guest second).
  async hello(ws, att, m) {
    if (m.p !== PROTOCOL) return this.drop(ws, "protocol", PROTOCOL);
    if (typeof m.game !== "string" || m.game === "") return this.drop(ws, "bad_hello");
    const rec = await this.lobby();
    if (!rec) return this.drop(ws, "no_lobby");
    if (rec.started) return this.drop(ws, "started");
    const others = this.players();
    if (others.length >= 2) return this.drop(ws, "full");
    const game = m.game.slice(0, MAX_GAME_CHARS);
    const host = others.find((p) => p.att.slot === 0);
    if (host && host.att.game !== game) return this.drop(ws, "version", host.att.game);
    const seat = {
      slot: host ? 1 : 0,
      at: att.at,
      gone: false,
      game,
      platform: String(m.platform || "").slice(0, MAX_PLATFORM_CHARS),
      name: String(m.name || "").slice(0, MAX_NAME_CHARS),
    };
    ws.serializeAttachment(seat);
    if (rec.reserved) await this.saveLobby({ ...rec, reserved: false });
    const peer = (a) => ({ slot: a.slot, game: a.game, platform: a.platform, name: a.name });
    this.send(ws, { t: "welcome", code: rec.code, slot: seat.slot, peer: host ? peer(host.att) : null });
    if (host) this.send(host.ws, { t: "peer", peer: peer(seat) });
    await this.alarmBy(Date.now() + CHECK_MS);
  }

  // A socket closed (Hibernation API): treated as leaving.
  async webSocketClose(ws, code, reason, _wasClean) {
    this.drop(ws, null);
  }

  // A socket failed (Hibernation API): treated as leaving.
  async webSocketError(ws, _error) {
    this.drop(ws, null);
  }

  // Housekeeping: hello timeouts, the reservation, idle and age limits; deletes an empty lobby.
  async alarm() {
    const now = Date.now();
    const rec = await this.lobby();
    if (!rec) {
      for (const s of this.sockets()) this.drop(s.ws, "no_lobby");
      return;
    }
    for (const s of this.sockets()) {
      if (s.att.slot < 0 && now - s.att.at >= HELLO_TIMEOUT_MS) this.drop(s.ws, "bad_hello");
    }
    const waiting = this.sockets().filter((s) => s.att.slot < 0);
    if (this.players().length === 0) {
      if (rec.reserved && now - rec.created < RESERVE_MS) return this.alarmBy(rec.created + RESERVE_MS);
      if (waiting.length > 0) return this.alarmBy(now + HELLO_TIMEOUT_MS);
      return this.cleanup();
    }
    const stored = (await this.ctx.storage.get("active")) || rec.created;
    const active = Math.max(this.lastActive, stored);
    if (now - active > IDLE_MS || now - rec.created > MAX_AGE_MS) {
      for (const s of this.sockets()) this.drop(s.ws, "expired");
      return this.cleanup();
    }
    await this.ctx.storage.setAlarm(now + (waiting.length > 0 ? Math.min(CHECK_MS, HELLO_TIMEOUT_MS) : CHECK_MS));
  }
}
