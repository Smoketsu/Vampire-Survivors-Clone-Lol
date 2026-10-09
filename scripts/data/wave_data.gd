## WaveData — the data-driven 5-minute wave timeline used by EnemyDirector.
##
## It is modelled on the GDD §11 Desecrated Graveyard timeline (20 minutes),
## compressed 4x to fit the 5-minute prototype loop asked for in GDD §19
## Phase 1 ("five-minute spawner"):
##
##   GDD 20-min timeline         ->  prototype 5-min timeline
##   00:00 Recruits              ->  0:00
##   03:00 Archers and footmen   ->  0:45
##   05:00 Chaplain elite        ->  1:15
##   08:00 Purifiers             ->  2:00
##   10:00 Grave consecration    ->  2:30 (chaplain + purifier pincer)
##   13:00 Templar Knights       ->  3:15 (Templars not in prototype:
##                                         stand-in footman phalanx)
##   15:00 Major assault         ->  3:45
##   18:00 Final preparation     ->  4:30
##   20:00 Sir Alaric boss       ->  5:00
##
## Spawn rates, caps and weights are all TUNING (not in GDD).
##
## Run structure (user brief, overrides "kill the boss to win"): the HUD timer
## counts DOWN from RUN_DURATION (6:00). Sir Alaric arrives with 1:00 left
## (5:00 elapsed); killing him drops a big reward but does not end the run.
## At 0:00 the run counts as survived and THE RECKONING begins: ever stronger
## Inquisitors of the End spawn every RECKONING.interval seconds until the
## necromancer falls. Dying after 0:00 = "Run Complete" (victory screen);
## dying before 0:00 = defeat.
class_name WaveData
extends RefCounted

## Total countdown length in seconds (prototype: 6:00 -> 0:00).
const RUN_DURATION: float = 360.0  # TUNING (not in GDD) user brief
## Game time (s) at which Sir Alaric appears (1:00 left on the countdown).
const BOSS_TIME: float = 300.0  # GDD §11 20:00, compressed 4x

## The Reckoning (user brief): escalating waves after the countdown ends.
##   banner          — HUD banner when it starts.
##   interval        — s between waves.
##   base_count      — enemies in the first wave.
##   count_growth    — extra enemies per subsequent wave.
##   hp_growth       — HP multiplier compounding per wave (wave n: hp_growth^n).
##   damage_growth   — damage multiplier compounding per wave.
const RECKONING := {
	"banner": "THE RECKONING",
	"interval": 10.0,  # TUNING (not in GDD) user brief "every ~10s"
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}

## Continuous spawning segments, sorted by start time. The active segment is
## the last one whose `start` <= elapsed time.
##   start      — s, segment start time.
##   rate       — enemies spawned per second (trickle around the player).
##   max_alive  — soft cap on living regular enemies during this segment.
##   weights    — relative spawn weights per enemy kind.
##   objective  — HUD objective text for this phase.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.2, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "Survive: the Covenant has found your graveyard"},
	{"start": 45.0, "rate": 1.4, "max_alive": 55,  # TUNING (not in GDD)
		"weights": {"recruit": 0.68, "footman": 0.2, "archer": 0.12},
		"objective": "Archers and footmen join the purge"},
	{"start": 75.0, "rate": 1.6, "max_alive": 65,  # TUNING (not in GDD)
		"weights": {"recruit": 0.55, "footman": 0.23, "archer": 0.12, "chaplain": 0.05},
		"objective": "Chaplains heal their soldiers: kill them first"},
	{"start": 120.0, "rate": 1.8, "max_alive": 75,  # TUNING (not in GDD)
		"weights": {"recruit": 0.48, "footman": 0.2, "archer": 0.12, "chaplain": 0.04, "purifier": 0.12},
		"objective": "Purifiers hunt your undead"},
	{"start": 150.0, "rate": 2.0, "max_alive": 85,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.2, "archer": 0.12, "chaplain": 0.04, "purifier": 0.15},
		"objective": "The graves are being consecrated"},
	{"start": 195.0, "rate": 2.5, "max_alive": 95,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.3, "archer": 0.12, "chaplain": 0.04, "purifier": 0.12},
		"objective": "Heavy infantry advances"},
	{"start": 225.0, "rate": 3.0, "max_alive": 105,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.25, "archer": 0.12, "chaplain": 0.04, "purifier": 0.12},
		"objective": "Major assault!"},
	{"start": 270.0, "rate": 3.3, "max_alive": 110,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.25, "archer": 0.14, "chaplain": 0.05, "purifier": 0.12},
		"objective": "Final preparation: Sir Alaric approaches"},
	{"start": BOSS_TIME, "rate": 1.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"recruit": 0.6, "footman": 0.25, "archer": 0.15},
		"objective": "Sir Alaric, the Gravebreaker, has come for you"},
]

## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE RECKONING: you survived. Now endure."

## One-shot scripted events, sorted by time.
##   time       — s when the event fires.
##   banner     — text flashed on the HUD.
##   formation  — "ring" (surrounds the player), "arc" (one side) or
##                "line" (a marching column from one direction).
##   groups     — list of {kind, count, elite} spawned in that formation.
const EVENTS := [
	{"time": 20.0, "banner": "Covenant recruits charge!", "formation": "arc",  # TUNING (not in GDD) first-minute beat: shows warrior blocking
		"groups": [{"kind": "recruit", "count": 8, "elite": false}]},
	{"time": 45.0, "banner": "Archers and footmen march in!", "formation": "arc",  # GDD §11 03:00
		"groups": [{"kind": "footman", "count": 5, "elite": false}, {"kind": "archer", "count": 3, "elite": false}]},
	{"time": 75.0, "banner": "A Chaplain elite leads the charge!", "formation": "arc",  # GDD §11 05:00
		"groups": [{"kind": "chaplain", "count": 1, "elite": true}, {"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 120.0, "banner": "Purifiers have come for your dead!", "formation": "ring",  # GDD §11 08:00
		"groups": [{"kind": "purifier", "count": 8, "elite": false}]},
	{"time": 150.0, "banner": "The Covenant consecrates the graves!", "formation": "ring",  # GDD §11 10:00
		"groups": [{"kind": "chaplain", "count": 4, "elite": false}, {"kind": "purifier", "count": 6, "elite": false}, {"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 195.0, "banner": "A footman phalanx advances!", "formation": "line",  # GDD §11 13:00 stand-in
		"groups": [{"kind": "footman", "count": 14, "elite": false}, {"kind": "footman", "count": 1, "elite": true}]},
	{"time": 225.0, "banner": "MAJOR ASSAULT!", "formation": "ring",  # GDD §11 15:00
		"groups": [{"kind": "recruit", "count": 28, "elite": false}, {"kind": "footman", "count": 10, "elite": false}, {"kind": "chaplain", "count": 2, "elite": true}]},
	{"time": 270.0, "banner": "Final preparation wave!", "formation": "arc",  # GDD §11 18:00
		"groups": [{"kind": "archer", "count": 6, "elite": false}, {"kind": "purifier", "count": 8, "elite": false}, {"kind": "footman", "count": 1, "elite": true}]},
]

## Enemy max-HP multiplier gained per minute of game time (linear).
const HP_SCALE_PER_MINUTE: float = 0.12  # TUNING (not in GDD)
## Enemy damage multiplier gained per minute of game time (linear).
const DAMAGE_SCALE_PER_MINUTE: float = 0.08  # TUNING (not in GDD)
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
