## WaveData — the run rules SHARED by every stage, used by EnemyDirector:
## the 20:00 countdown, enemy time scaling, the regular-enemy hard cap, the
## spawn ring, recycling, banners and formation spacing. Everything that
## belongs to one stage (wave segments, timeline events, the boss time, the
## Reckoning flavour, empowered graves, desecration, the Crypt Defender) lives
## in that stage's file under scripts/data/stages/, reached through
## StageRegistry (`Game.stage_def`).
##
## Run structure (user brief, overrides "kill the boss to win"): the HUD timer
## counts DOWN from RUN_DURATION (20:00). The stage boss arrives with 3:00 left
## (17:00 elapsed); killing him drops a big reward but does not end the run.
## At 0:00 the run counts as survived and THE RECKONING begins: ever stronger
## Inquisitors of the End spawn every reckoning.interval seconds until the
## necromancer falls. Dying after 0:00 = "Run Complete" (victory screen);
## dying before 0:00 = defeat.
class_name WaveData
extends RefCounted

## Total countdown length in seconds (20:00 -> 0:00).
const RUN_DURATION: float = 1200.0  # GDD §8 "20–30 minutes"; user decision 20:00

## Seconds between holy-zone damage ticks on summons (consecrated graves and
## Sir Alaric's Consecrated Ground).
const ZONE_TICK: float = 0.25  # TUNING (not in GDD)
## Seconds a summon stays slowed after its last zone tick (a bit more than
## ZONE_TICK so the slow doesn't flicker).
const ZONE_SLOW_LINGER: float = 0.35  # TUNING (not in GDD)

## Enemy time scaling over the 20-minute run, with m = elapsed minutes:
##   hp_mult     = 1 + HP_SCALE_PER_MINUTE * m + HP_SCALE_PER_MINUTE_SQ * m^2
##   damage_mult = 1 + DAMAGE_SCALE_PER_MINUTE * m + DAMAGE_SCALE_PER_MINUTE_SQ * m^2
## The quadratic term keeps the early game gentle and lets the late game
## catch up with a near-complete build: HP x1.8 / x3.3 / x5.4 / x6.5 / x8.2
## and damage x1.3 / x1.8 / x2.6 / x3.0 / x3.6 at 5 / 10 / 15 / 17 / 20
## minutes (a 20:00 recruit has 115 HP; an evolved spell still kills it in
## one to three hits). Weak builds stop keeping up around the 13:00-17:00
## density peak; a focused build does not.
## Enemy max-HP multiplier gained per minute of game time (linear term).
const HP_SCALE_PER_MINUTE: float = 0.10  # TUNING (not in GDD)
## Enemy max-HP multiplier gained per minute squared (quadratic term).
const HP_SCALE_PER_MINUTE_SQ: float = 0.013  # TUNING (not in GDD)
## Enemy damage multiplier gained per minute of game time (linear term).
const DAMAGE_SCALE_PER_MINUTE: float = 0.03  # TUNING (not in GDD)
## Enemy damage multiplier gained per minute squared (quadratic term).
const DAMAGE_SCALE_PER_MINUTE_SQ: float = 0.005  # TUNING (not in GDD)
## Hard performance cap on living regular enemies, events included
## (GDD §18 performance target: 150–300 enemies).
const HARD_CAP: int = 180  # TUNING (not in GDD)
## Extra distance (px) beyond the visible screen corner at which enemies spawn.
const SPAWN_MARGIN: float = 60.0  # TUNING (not in GDD)
## Enemies farther than this (px) from the player are moved back to the
## spawn ring ahead of the player (keeps pressure on a moving player).
const RECYCLE_DISTANCE: float = 950.0  # TUNING (not in GDD)
## Minimum gap (px) kept between the spawn ring and the recycle distance.
const RECYCLE_MARGIN: float = 200.0  # TUNING (not in GDD)
## Banner display time (s) for event announcements.
const BANNER_TIME: float = 4.0  # TUNING (not in GDD)
## Angular spread (radians) of an "arc" formation.
const ARC_SPREAD: float = 1.6  # TUNING (not in GDD)
## Spacing (px) between soldiers in a "line" formation.
const LINE_SPACING: float = 26.0  # TUNING (not in GDD)
