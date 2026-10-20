## CoopNetData: every number and message of the co-op connection (CoopNet,
## scripts/coop/coop_net.gd) and the lobby screens (CoopScreen, CoopLobby,
## CoopJoinPad, CoopPlayerCard; GDD §15.0 "Online co-op: relay and lobby").
## The relay's own limits live in server/relay/src/index.js and
## tools/coop_relay.py (server/relay/PROTOCOL.md); the numbers here must agree
## with them where they meet (protocol, code alphabet, message size). Sizes
## are layout px on the 1280x720 layout. Data only, no logic.
class_name CoopNetData
extends RefCounted

# ------------------------------------------------------------------ relay

## Address of the deployed Cloudflare relay (Worker `necropathy-relay` on the owner's
## smoketsu.workers.dev subdomain; deployed by CI's deploy-relay job, docs/coop/RELAY_SETUP.md).
## "" would mean not deployed: Host / Join then say co-op is not set up.
## Tests override it: `--relay=ws://...` on desktop, `?relay=ws://...` in the Web build's page address.
const RELAY_URL: String = "wss://necropathy-relay.smoketsu.workers.dev"  # TUNING (not in GDD) owner's Cloudflare account (Oct 2026)
## Relay protocol version sent in the hello (PROTOCOL.md; the relay refuses any other). Range 1+.
const PROTOCOL: int = 1  # TUNING (not in GDD)
## Letters a lobby code is made of: 20 consonants (no vowels, so no words; no O / I / L to misread).
const CODE_ALPHABET: String = "BCDFGHJKMNPQRSTVWXYZ"  # TUNING (not in GDD) must match the relay's ALPHABET
## Letters in a lobby code.
const CODE_LENGTH: int = 5  # TUNING (not in GDD) must match the relay's CODE_LENGTH
## Relay error code -> its WebSocket close code (PROTOCOL.md), so a refusal whose error message
## was lost still reads plainly.
const CLOSE_CODES: Dictionary = {
	"no_lobby": 4001, "full": 4002, "version": 4003, "started": 4004, "bad_hello": 4005,  # TUNING (not in GDD) must match the relay
	"host_left": 4006, "expired": 4007, "rate": 4008, "too_big": 4009, "protocol": 4010,  # TUNING (not in GDD) must match the relay
}
## Largest message the relay accepts (bytes); send_frame() refuses bigger frames.
const MAX_MESSAGE_BYTES: int = 16384  # TUNING (not in GDD) must match the relay's MAX_MESSAGE_BYTES

# ------------------------------------------------------------------ socket

## Seconds to wait for the relay's welcome after starting to connect (then: relay unreachable).
const CONNECT_TIMEOUT: float = 8.0  # TUNING (not in GDD)
## WebSocketPeer inbound buffer (bytes): room for a burst of frames between two polls.
const INBOUND_BUFFER_BYTES: int = 1048576  # TUNING (not in GDD)
## WebSocketPeer outbound buffer (bytes).
const OUTBOUND_BUFFER_BYTES: int = 1048576  # TUNING (not in GDD)
## WebSocketPeer queued packet limit (packets) each way.
const MAX_QUEUED_PACKETS: int = 8192  # TUNING (not in GDD)
## Seconds between two partner pings (round-trip time through the relay).
const PING_INTERVAL: float = 1.0  # TUNING (not in GDD)
## Pings kept unanswered before the oldest is forgotten (count).
const MAX_PENDING_PINGS: int = 16  # TUNING (not in GDD)
## Weight of a new round-trip sample in the smoothed RTT (0-1).
const RTT_SMOOTHING: float = 0.25  # TUNING (not in GDD)
## Allow a partner on another platform (web with desktop). DESIGN.md: allowed only if the lockstep
## checksum test passes between them; set false if WASM and native builds desync.
const ALLOW_MIXED_PLATFORMS: bool = true  # TUNING (not in GDD) pending the sim agent's cross-platform checksum test

# ------------------------------------------------------------------ lobby

## Player names by slot when a loadout carries none (0 = host, 1 = guest).
const DEFAULT_NAMES: Array = ["Host", "Guest"]  # TUNING (not in GDD)
## Longest player name kept (characters).
const MAX_NAME_CHARS: int = 16  # TUNING (not in GDD)
## Title of the share sheet / the text copied with the code (web): %s = code, then the join link.
const SHARE_TEXT: String = "Join my Necropathy lobby: %s"  # TUNING (not in GDD)
## Page query key that opens the Join pad with a code filled in (`?join=BCDFG`, the shared link).
const JOIN_QUERY_KEY: String = "join"  # TUNING (not in GDD)
## Page query key overriding RELAY_URL in the Web build (tests).
const RELAY_QUERY_KEY: String = "relay"  # TUNING (not in GDD)

## Error code -> the plain line the lobby screens show (relay codes from PROTOCOL.md plus the
## client's own: bad_code, unreachable, lost, no_relay, platform, partner_left).
const ERROR_TEXT: Dictionary = {
	"no_lobby": "No lobby has that code. Check the letters.",  # TUNING (not in GDD)
	"full": "That lobby is full.",  # TUNING (not in GDD)
	"version": "Your partner runs another version of the game (%s). Update both to the same build.",  # TUNING (not in GDD)
	"started": "That lobby's run has already begun.",  # TUNING (not in GDD)
	"bad_hello": "The relay did not accept the connection.",  # TUNING (not in GDD)
	"host_left": "The host closed the lobby.",  # TUNING (not in GDD)
	"expired": "The lobby closed after a long wait.",  # TUNING (not in GDD)
	"rate": "Too many messages: the relay closed the connection.",  # TUNING (not in GDD)
	"too_big": "A message was too large for the relay.",  # TUNING (not in GDD)
	"protocol": "The relay speaks another protocol. Update the game.",  # TUNING (not in GDD)
	"bad_code": "A code is 5 letters.",  # TUNING (not in GDD)
	"unreachable": "Cannot reach the co-op relay. Check your connection.",  # TUNING (not in GDD)
	"lost": "Connection to the relay lost.",  # TUNING (not in GDD)
	"no_relay": "Co-op is not set up in this build yet (no relay address).",  # TUNING (not in GDD)
	"platform": "Your partner plays on another platform (%s); mixed platforms are off.",  # TUNING (not in GDD)
	"partner_left": "Your partner left.",  # TUNING (not in GDD)
}
## Line for an error code missing from ERROR_TEXT.
const ERROR_FALLBACK: String = "Co-op error: %s"  # TUNING (not in GDD)

# ------------------------------------------------------------------ screens

## Backdrop alpha of the Co-op screen over the menu diorama (0-1).
const SCREEN_SCRIM: float = 0.85  # TUNING (not in GDD)
## Width of the Co-op screen's panel and of the lobby (px).
const PANEL_WIDTH: float = 560.0  # TUNING (not in GDD)
## Lobby width (px; the two player cards and the run line).
const LOBBY_WIDTH: float = 820.0  # TUNING (not in GDD)
## Size of one choice / bottom-row button (px).
const BUTTON_SIZE: Vector2 = Vector2(150.0, 40.0)  # TUNING (not in GDD)
## Size of the strong action buttons (Start, Join) (px).
const ACTION_SIZE: Vector2 = Vector2(170.0, 44.0)  # TUNING (not in GDD)
## One line under the Co-op title.
const SCREEN_LINE: String = "Two necromancers, one run, online. Host a lobby or join a friend's with their code."  # TUNING (not in GDD)
## Status line while connecting.
const CONNECTING_TEXT: String = "Connecting to the relay..."  # TUNING (not in GDD)
## Letter pad columns (the 20 letters as 4 rows of 5).
const PAD_COLUMNS: int = 5  # TUNING (not in GDD)
## Size of one letter pad key (px; big enough for a finger on a phone).
const PAD_KEY: Vector2 = Vector2(64.0, 48.0)  # TUNING (not in GDD)
## Gap between letter pad keys (px).
const PAD_GAP: int = 6  # TUNING (not in GDD)
## Size of one code letter slot on the Join pad and in the lobby (px).
const CODE_SLOT: Vector2 = Vector2(58.0, 70.0)  # TUNING (not in GDD)
## Gap between code letter slots (px).
const CODE_SLOT_GAP: int = 8  # TUNING (not in GDD)
## Size of one player card in the lobby (px).
const CARD_SIZE: Vector2 = Vector2(400.0, 168.0)  # TUNING (not in GDD)
## Size of the character portrait on a player card (px).
const PORTRAIT_SIZE: Vector2 = Vector2(104.0, 128.0)  # TUNING (not in GDD)
## Gap between the two player cards (px).
const CARD_GAP: int = 20  # TUNING (not in GDD)
## Ping colour thresholds (ms): at or under GOOD soul-teal, at or under FAIR plain, above crimson.
const PING_GOOD_MS: float = 90.0  # TUNING (not in GDD)
const PING_FAIR_MS: float = 180.0  # TUNING (not in GDD)
## Seconds the "Copied" note stays on the Copy button.
const COPIED_TIME: float = 1.5  # TUNING (not in GDD)
## Lobby texts.
const WAITING_TEXT: String = "Waiting for a partner. Share the code."  # TUNING (not in GDD)
const GUEST_WAIT_TEXT: String = "Choose your setup, then press Ready."  # TUNING (not in GDD)
const HOST_READY_TEXT: String = "Your partner is ready. Start when you are."  # TUNING (not in GDD)
const HOST_WAIT_READY_TEXT: String = "Waiting for your partner to be ready."  # TUNING (not in GDD)
const GUEST_READY_TEXT: String = "Ready. Waiting for the host to start."  # TUNING (not in GDD)
const EMPTY_SLOT_TEXT: String = "Waiting..."  # TUNING (not in GDD)
## Leave confirm dialog: [title, body, confirm word].
const LEAVE_CONFIRM: Array = ["Leave the lobby?", "Your partner stays behind; you can host or join again.", "Leave"]  # TUNING (not in GDD)
