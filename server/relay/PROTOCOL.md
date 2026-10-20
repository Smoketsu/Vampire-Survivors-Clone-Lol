# Necropathy co-op relay protocol (v1)

The relay pairs two players in a **lobby** named by a 5-letter code and passes their messages to each other in
order. It knows nothing about the game: it only checks the hello (protocol and game version), enforces the
limits below and relays. Two implementations speak it and must stay identical:

- `server/relay/src/index.js`: the Cloudflare Worker (one Durable Object per lobby, WebSocket Hibernation API);
- `tools/coop_relay.py`: the local Python relay for development and CI (standard library only).

The game side is the `CoopNet` autoload (`scripts/coop/coop_net.gd`, numbers in `scripts/data/coop_net_data.gd`).

## Codes

Five letters from `BCDFGHJKMNPQRSTVWXYZ` (20 consonants: no vowels, so a code never spells a word, and no
O / 0, I / 1 or L to misread). Codes are case-insensitive on input and always sent upper-case. A code is free again
once its lobby is gone.

## HTTP

| Request | Answer |
| --- | --- |
| `GET /` or `GET /health` | `200 {"ok": true, "protocol": 1}` |
| `POST /lobby` | `201 {"code": "BCDFG"}`: reserves an empty lobby for 120 s (the first player to join it is the host) |
| `OPTIONS *` | CORS preflight (`204`) |
| `GET /lobby/new/ws` (WebSocket upgrade) | creates a lobby and joins it: the caller becomes the host |
| `GET /lobby/CODE/ws` (WebSocket upgrade) | joins lobby `CODE` |

CORS: browser requests are accepted from the origins in `ALLOWED_ORIGINS` (`wrangler.toml`; the GitHub Pages origin
`https://smoketsu.github.io` and local test servers); a request without an `Origin` header (the desktop game) is
always accepted. A WebSocket upgrade from any other origin gets `403`.

A WebSocket is always accepted when the path is well formed, even for a code that has no lobby: the refusal comes
as an `error` message and a close code, so every client (the Godot `WebSocketPeer` cannot read HTTP statuses) can
show it plainly.

## Messages

**Text** frames are JSON objects with a type field `t`. **Binary** frames are opaque game data (the lockstep
frames): relayed as they are to the partner, never read. Text and binary share one ordered stream per player.

### Client to relay

| `t` | Fields | Meaning |
| --- | --- | --- |
| `hello` | `p` (protocol, 1), `game` (game version), `platform` (`web`, `linux`, `windows`, `macos`...), `name` | must be the first message, within 10 s |
| `leave` | | leaving on purpose (the relay closes the socket) |
| `start` | `info` (the start info) | host only: the lobby is marked started (no more joins) and the message is relayed |
| anything else | any | relayed as it is to the partner (dropped while alone) |

### Relay to client

| `t` | Fields | Meaning |
| --- | --- | --- |
| `welcome` | `code`, `slot` (0 = host, 1 = guest), `peer` (the partner's hello fields and `slot`, or `null`) | the hello was accepted |
| `peer` | `peer` | a partner joined |
| `left` | `slot` | the partner left (closed the socket or sent `leave`) |
| `error` | `code`, `detail` (optional) | refusal; the relay closes the socket right after |

Messages the clients relay to each other (`CoopNet`, not read by the relay): `loadout` (`loadout`, `ready`),
`settings` (`config`, host only), `pping` (`id`, `rtt`) and `ppong` (`id`) for the round-trip time.

### Error codes and close codes

| `code` | Close | When |
| --- | --- | --- |
| `no_lobby` | 4001 | the code has no lobby (never made, or expired) |
| `full` | 4002 | the lobby already has two players |
| `version` | 4003 | `game` differs from the host's (`detail` = the host's version) |
| `started` | 4004 | the lobby's run has begun |
| `bad_hello` | 4005 | the first message was not a valid hello, or none came within 10 s |
| `host_left` | 4006 | the host left before the run began (the lobby closes) |
| `expired` | 4007 | no message for 10 minutes, or the lobby is older than 4 hours |
| `rate` | 4008 | more than the message or byte rate below |
| `too_big` | 4009 | a message over 16 KiB |
| `protocol` | 4010 | `p` is not this relay's protocol |

## Rules

- At most **2 players**; the first to send a hello is the host (slot 0), the second the guest (slot 1).
- Before the start, a guest who leaves frees slot 1 for someone else; the host leaving closes the lobby
  (`left`, then `error host_left` to the guest).
- After the start, either player leaving sends `left` to the other, who stays connected (the game goes on solo).
  No one can join a started lobby.
- An empty lobby is deleted at once (a reserved one after 120 s); its code is then free.
- Limits per socket: 16 KiB per message; 300 messages per second sustained (bursts of 600); 64 KiB per second
  sustained (bursts of 256 KiB).

## Cost note (Cloudflare free plan)

Durable Objects bill incoming WebSocket messages at 20 messages per request, and the free plan has 100,000 requests
a day. A 20-minute run sending one frame per tick at 60 ticks per second from each player is about 7,200 requests,
so about a dozen full runs a day fit; sending one frame per 2 to 4 ticks multiplies that. Idle lobbies hibernate
and cost nothing.
