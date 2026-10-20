## CoopData — tunable numbers of online co-op (docs/coop/DESIGN.md, owner and
## lead decisions of Oct 20, 2026; GDD §15.0 "Online co-op"). Two players, each
## with their own necromancer and army, in ONE deterministic simulation (lockstep:
## every machine runs both slots). CoopSession and the co-op parts of Game,
## DifficultyModifiers, EnemyDirector and the pickups read this file; no logic
## here. Nothing of it is read in a solo run (Game.coop is null), so solo plays
## bit-for-bit as before.
##
## Scaling (SCALING, its own category in DifficultyModifiers.coop_mult(), applied
## once on top of every other one):
##   enemy_spawn   trickle rate and segment soft cap (the "doubled" enemies)
##   alive_cap     the hard cap on living regular enemies (WaveData.HARD_CAP)
##   wave_copies   timeline formation waves and Reckoning waves: one copy around
##                 each living necromancer (EnemyDirector.spawn_formation())
##   xp            XP per pickup into the ONE shared bar (both feed it, so x0.5
##                 keeps the solo level pacing)
##   boss_hp       the stage boss's HP
##   miniboss_hp   a miniboss's HP (Cathedral Guardian, Harbourmaster, ...)
## Downed and revive: a necromancer brought to 0 HP before 0:00 lies downed (his
## army crumbles); the partner standing within REVIVE_RADIUS for REVIVE_TIME s
## raises him at REVIVE_HP_FRACTION of max HP. Both down at once ends the run
## (before 0:00 a defeat, after it a victory, like solo).
class_name CoopData
extends RefCounted

## Players in a co-op run (owner decision: two, online only).
const SLOTS: int = 2  # Owner decision Oct 2026 (docs/coop/DESIGN.md)

## Co-op multipliers (see the header). Each is exactly what the stat code
## multiplies by; 1 would be "as solo".
const SCALING := {
	"enemy_spawn": 2.0,  # Owner decision: "double the number of enemies" (docs/coop/DESIGN.md).
	"alive_cap": 2.0,  # Owner decision: the alive cap doubles with the enemies.
	"xp": 0.5,  # TUNING (not in GDD) lead decision: shared bar keeps the solo pacing.
	"boss_hp": 1.7,  # TUNING (not in GDD) lead decision.
	"miniboss_hp": 1.5,  # TUNING (not in GDD) lead decision.
}

## Formation waves (timeline "wave" events, stage escort waves) and Reckoning
## waves spawn once around each living necromancer (count of copies is the number
## of living players, at most this).
const WAVE_COPIES_MAX: int = 2  # TUNING (not in GDD) lead decision (doubling)

# --- Downed and revive ------------------------------------------------------------------

## Distance (px, centre to centre) within which the standing partner revives a
## downed necromancer.
const REVIVE_RADIUS: float = 64.0  # TUNING (not in GDD) owner decision ("stands near them")
## Seconds the partner must stand within REVIVE_RADIUS to raise him (owner: ~3 s).
const REVIVE_TIME: float = 3.0  # Owner decision Oct 2026 (docs/coop/DESIGN.md)
## Revive progress lost per second while nobody stands close (s of progress / s).
const REVIVE_DECAY: float = 1.0  # TUNING (not in GDD)
## Share (0..1) of max HP a revived necromancer rises with (owner: 50%).
const REVIVE_HP_FRACTION: float = 0.5  # Owner decision Oct 2026 (docs/coop/DESIGN.md)
## Seconds of invulnerability after being revived (same feel as Undying Will).
const REVIVE_IFRAMES: float = 2.0  # TUNING (not in GDD)

# --- Placement ----------------------------------------------------------------------------

## Start position of each slot's necromancer (px, world). Slot 0 stands where a
## solo necromancer stands; slot 1 a step beside him.
const START_POSITIONS: Array[Vector2] = [Vector2(-36.0, 0.0), Vector2(36.0, 0.0)]  # TUNING (not in GDD)

# --- Treasure chests ----------------------------------------------------------------------

## Boss chests dropped per living player (lead decision: one per player).
const BOSS_CHESTS_PER_PLAYER: int = 1  # TUNING (not in GDD) lead decision
## Spacing (px) between the boss chests dropped side by side.
const BOSS_CHEST_SPACING: float = 40.0  # TUNING (not in GDD)

# --- Autotest bots (--coop-bot) -------------------------------------------------------------

## A bot farther than this (px) from its partner drifts back toward him.
const BOT_COHESION_RADIUS: float = 320.0  # TUNING (not in GDD) test bot only
## Weight of that drift in the bot's movement mix.
const BOT_COHESION_WEIGHT: float = 0.8  # TUNING (not in GDD) test bot only
## Weight of the walk to a downed partner (above the flee weight, so it goes).
const BOT_REVIVE_WEIGHT: float = 2.5  # TUNING (not in GDD) test bot only
## Within this distance (px) of a downed partner the bot stops fleeing so it
## stays in revive reach.
const BOT_REVIVE_HOLD: float = 40.0  # TUNING (not in GDD) test bot only
