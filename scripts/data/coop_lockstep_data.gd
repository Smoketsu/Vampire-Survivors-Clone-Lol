## CoopLockstepData — every number and line of the co-op lockstep driver
## (CoopLockstep, scripts/coop/coop_lockstep.gd; GDD §15.0 "Co-op lockstep").
## Both machines run the whole simulation; only each player's inputs travel,
## bundled into frames, and a tick runs only when both players' inputs for it
## are known. Network timing only: nothing here changes how the game plays,
## except GAMEPLAY_VIEW (the one gameplay view size of a co-op run). Data only,
## no logic.
class_name CoopLockstepData
extends RefCounted

# ------------------------------------------------------------------ simulation

## Lockstep ticks per second (= the physics rate the game is built for). Range 60.
const TICK_RATE: int = 60  # TUNING (not in GDD) the game's fixed physics rate
## Game seconds one lockstep tick advances the simulation (1 / TICK_RATE; the
## same constant on every machine, never the engine's measured delta).
const TICK_DELTA: float = 1.0 / 60.0  # TUNING (not in GDD) must equal 1 / TICK_RATE
## The one gameplay view size of a co-op run (world px at Normal zoom): the
## spawn ring, the recycle distance and the Soul Nova read it on every machine
## (Game.gameplay_view_size()), whatever the window, browser or phone. It is
## the headless autotest's viewport (1280 x 720 at ViewData.GAMEPLAY_ZOOM 1),
## so a --coop-bot run plays exactly as before. Rendering keeps the real size.
const GAMEPLAY_VIEW: Vector2 = Vector2(1280.0, 720.0)  # TUNING (not in GDD) lead decision: the design layout

# ------------------------------------------------------------------ input delay

## Input delay at the start of a run (ticks; 6 = 100 ms): the local player's
## input of tick t is scheduled for tick t + delay, so the partner has it in
## time. Brief: start at 4-6 ticks.
const DELAY_START: int = 6  # TUNING (not in GDD)
## Smallest input delay (ticks): never below the bundle (BUNDLE_TICKS) plus one.
const DELAY_MIN: int = 4  # TUNING (not in GDD)
## Largest input delay (ticks; 20 = 333 ms): a worse link stalls instead.
const DELAY_MAX: int = 20  # TUNING (not in GDD)
## Extra ticks of delay on top of the one-way trip and the bundle, for jitter.
const DELAY_MARGIN_TICKS: int = 1  # TUNING (not in GDD)
## Seconds between two input-delay adjustments (real time).
const DELAY_ADJUST_INTERVAL: float = 2.0  # TUNING (not in GDD)
## Weight of each new round-trip sample in the jitter estimate (0-1).
const JITTER_SMOOTHING: float = 0.2  # TUNING (not in GDD)
## Multiple of the smoothed jitter (ms) added to the one-way trip.
const JITTER_WEIGHT: float = 2.0  # TUNING (not in GDD)

# ------------------------------------------------------------------ frames

## Ticks of the local player's input bundled into one frame (the Cloudflare free
## plan bills every incoming WebSocket message: one frame per tick allows only
## ~12 runs a day, one per 3 ticks ~40). A frame also goes out at once when a
## command is waiting or the simulation stalls.
const BUNDLE_TICKS: int = 3  # TUNING (not in GDD) lead brief (~3 ticks)
## Most ticks the driver runs in one physics frame to catch up after a stall
## (when the partner's inputs are well ahead). Range 1+.
const MAX_CATCHUP_TICKS: int = 4  # TUNING (not in GDD)
## Received ticks beyond the input delay (ticks) above which the driver catches up.
const CATCHUP_SLACK: int = 3  # TUNING (not in GDD)
## Quantization of a move axis: a byte from -MOVE_STEPS to MOVE_STEPS (127 = int8).
const MOVE_STEPS: int = 127  # TUNING (not in GDD)
## Steps of a full turn for a dash direction byte (256 = 1.4 degrees).
const DIR_STEPS: int = 256  # TUNING (not in GDD)
## Commands one player can attach to one tick (the rest wait for the next).
const MAX_COMMANDS_PER_TICK: int = 4  # TUNING (not in GDD)

# ------------------------------------------------------------------ desync check

## Ticks between two state checksums (60 = once a second).
const CHECKSUM_INTERVAL: int = 60  # TUNING (not in GDD) lead brief
## Names of the checksum's fields, in order (CoopLockstep.checksum_fields()):
## the first one that differs is logged with the tick.
const CHECKSUM_FIELDS: Array[String] = ["clock", "slot0", "slot1", "enemies", "armies", "shots", "pickups", "rng"]  # TUNING (not in GDD)

# ------------------------------------------------------------------ stalls and drops

## Real seconds without the partner's input before the waiting overlay shows.
const STALL_OVERLAY_S: float = 1.5  # TUNING (not in GDD) lead brief (~1.5 s)
## Real seconds without the partner's input before he counts as gone (the bot
## takes his necromancer over). Brief: ~10 s.
const DROP_S: float = 10.0  # TUNING (not in GDD) lead brief
## The same while the run is paused (a phone tab in the background keeps its
## socket but stops running; the relay's own idle limit is 10 minutes).
const DROP_PAUSED_S: float = 300.0  # TUNING (not in GDD)
## Real seconds the local game keeps polling after the run ended or before
## leaving, so its last frames reach the partner.
const LINGER_S: float = 1.5  # TUNING (not in GDD)
## Card policy of the bot that takes a dropped partner's necromancer over.
const TAKEOVER_POLICY: String = "army"  # TUNING (not in GDD) lead brief: the autotest's army bot

# ------------------------------------------------------------------ lines shown (under the CoopUi waiting panel's "Waiting for partner" headline, the notices)

## Waiting overlay while the partner's inputs are late.
const WAIT_NETWORK_TEXT: String = "Connection is slow"  # TUNING (not in GDD)
## Waiting overlay while the partner picks a level-up card (we picked).
const WAIT_LEVEL_TEXT: String = "Your partner is choosing a card"  # TUNING (not in GDD)
## Waiting overlay while the partner opens a treasure chest.
const WAIT_CHEST_TEXT: String = "Your partner opens a chest"  # TUNING (not in GDD)
## Pause menu line when the partner paused.
const PAUSED_BY_PARTNER_TEXT: String = "Paused by your partner"  # TUNING (not in GDD)
## Co-op notice when the partner left / dropped (CoopUi.notice(); first sentence = headline): %s = his name.
const DROP_NOTICE: String = "%s left the run. A bot leads their necromancer now."  # TUNING (not in GDD)
## Results card subtitle after a desync (the run ends at once; EndScreen).
const DESYNC_TEXT: String = "The two games stopped matching (desync). The run ended; your Soul Ash is kept."  # TUNING (not in GDD)
## Pause menu: the word on the button that leaves a co-op run (it replaces Main Menu; Restart is hidden).
const LEAVE_WORD: String = "Leave"  # TUNING (not in GDD)
