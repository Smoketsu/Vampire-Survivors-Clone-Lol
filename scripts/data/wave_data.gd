## WaveData — the data-driven 5-minute wave timeline used by EnemyDirector
## and the Graveyard stage events run by StageDirector.
##
## It is modelled on the GDD §11 Desecrated Graveyard timeline (20 minutes),
## compressed 4x to fit the 5-minute prototype loop asked for in GDD §19
## Phase 1 ("five-minute spawner"):
##
##   GDD 20-min timeline         ->  prototype 5-min timeline
##   00:00 Recruits              ->  0:00
##   02:00 (empowered graves)    ->  0:30, then every EMPOWERED_GRAVES.interval
##   03:00 Archers and footmen   ->  0:45
##   05:00 Chaplain elite        ->  1:15
##   08:00 Purifiers             ->  2:00
##   10:00 Grave consecration    ->  2:30 (desecration event: Chaplains walk to
##                                         marked graves and channel; kill them
##                                         or the grave becomes a holy zone)
##   13:00 Templar Knights       ->  3:15 (Templar charge + footman line)
##   15:00 Major assault         ->  3:45
##   16:00 (Crypt Defender)      ->  4:00 (an ancient crypt can be awakened)
##   17:00 (second desecration)  ->  4:15
##   18:00 Final preparation     ->  4:30
##   20:00 Sir Alaric boss       ->  5:00
## The GDD lists empowered graves, desecration events and the Crypt Defender
## as stage mechanics (§11) without times; the bracketed times are TUNING.
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
		"weights": {"recruit": 0.4, "footman": 0.27, "archer": 0.12, "chaplain": 0.04, "purifier": 0.12, "templar": 0.03},
		"objective": "Templar Knights charge your lines"},
	{"start": 225.0, "rate": 3.0, "max_alive": 105,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.22, "archer": 0.12, "chaplain": 0.04, "purifier": 0.12, "templar": 0.03},
		"objective": "Major assault!"},
	{"start": 270.0, "rate": 3.3, "max_alive": 110,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.22, "archer": 0.14, "chaplain": 0.05, "purifier": 0.12, "templar": 0.03},
		"objective": "Final preparation: Sir Alaric approaches"},
	{"start": BOSS_TIME, "rate": 1.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"recruit": 0.6, "footman": 0.25, "archer": 0.15},
		"objective": "Sir Alaric, the Gravebreaker, has come for you"},
]

## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE RECKONING: you survived. Now endure."

## One-shot scripted events, sorted by time. Keys in every entry:
##   time       — s when the event fires.
##   type       — "wave": a formation of soldiers (EnemyDirector);
##                "consecration": a desecration event (StageDirector,
##                see CONSECRATION);
##                "crypt": the Crypt Defender event (StageDirector, see
##                CRYPT_DEFENDER).
##   banner     — text flashed on the HUD.
## "wave" entries also have:
##   formation  — "ring" (surrounds the player), "arc" (one side) or
##                "line" (a marching column from one direction).
##   groups     — list of {kind, count, elite} spawned in that formation.
## "consecration" entries also have:
##   graves     — number of graves the Covenant tries to consecrate.
##   escort     — list of {kind, count, elite} walking with EACH consecrator.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "Covenant recruits charge!", "formation": "arc",  # TUNING (not in GDD) first-minute beat: shows warrior blocking
		"groups": [{"kind": "recruit", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "wave", "banner": "Archers and footmen march in!", "formation": "arc",  # GDD §11 03:00
		"groups": [{"kind": "footman", "count": 5, "elite": false}, {"kind": "archer", "count": 3, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A Chaplain elite leads the charge!", "formation": "arc",  # GDD §11 05:00
		"groups": [{"kind": "chaplain", "count": 1, "elite": true}, {"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 120.0, "type": "wave", "banner": "Purifiers have come for your dead!", "formation": "ring",  # GDD §11 08:00
		"groups": [{"kind": "purifier", "count": 8, "elite": false}]},
	{"time": 150.0, "type": "consecration", "banner": "Chaplains march to consecrate your graves: stop them!",  # GDD §11 10:00 grave consecration event
		"graves": 3,  # TUNING (not in GDD)
		"escort": [{"kind": "recruit", "count": 4, "elite": false}, {"kind": "purifier", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 195.0, "type": "wave", "banner": "Templar Knights charge!", "formation": "line",  # GDD §11 13:00 Templar Knights
		"groups": [{"kind": "templar", "count": 3, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "templar", "count": 1, "elite": true}]},  # TUNING (not in GDD)
	{"time": 225.0, "type": "wave", "banner": "MAJOR ASSAULT!", "formation": "ring",  # GDD §11 15:00
		"groups": [{"kind": "recruit", "count": 26, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "templar", "count": 2, "elite": false}, {"kind": "chaplain", "count": 2, "elite": true}]},
	{"time": 240.0, "type": "crypt", "banner": "An ancient crypt stirs nearby: awaken its guardians!"},  # TUNING (not in GDD) §11 Crypt Defender event, untimed in the GDD
	{"time": 255.0, "type": "consecration", "banner": "More Chaplains seek to consecrate the graves!",  # TUNING (not in GDD) §11 desecration events recur
		"graves": 2,  # TUNING (not in GDD)
		"escort": [{"kind": "footman", "count": 2, "elite": false}, {"kind": "recruit", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 270.0, "type": "wave", "banner": "Final preparation wave!", "formation": "arc",  # GDD §11 18:00
		"groups": [{"kind": "archer", "count": 6, "elite": false}, {"kind": "purifier", "count": 8, "elite": false}, {"kind": "footman", "count": 1, "elite": true}]},
]

## Empowered graves (GDD §11 "Empowered graves near the player add temporary
## reinforcements or improve summon replenishment"). A glowing grave rises
## near the necromancer; walking onto it claims its reward.
##   first          — game time (s) when the first grave rises.
##   interval       — s between graves.
##   until          — no new grave rises after this game time (s).
##   lifetime       — s a grave waits to be claimed before it sinks.
##   distance_min / distance_max — px from the necromancer where it rises.
##   claim_radius   — px; the necromancer claims it within this distance.
##   rewards        — cycled in order: "reinforce" (temporary summons) or
##                    "replenish" (every missing summon returns at once).
##   reinforce_class    — summon class of the temporary reinforcements.
##   reinforce_count    — temporary summons per "reinforce" grave.
##   reinforce_duration — s before they crumble.
##   reinforce_hp_mult / reinforce_damage_mult — their stat multipliers on
##                    top of the class's current effective stats.
const EMPOWERED_GRAVES := {
	"first": 30.0,  # TUNING (not in GDD)
	"interval": 40.0,  # TUNING (not in GDD)
	"until": 345.0,  # TUNING (not in GDD)
	"lifetime": 22.0,  # TUNING (not in GDD)
	"distance_min": 130.0,  # TUNING (not in GDD)
	"distance_max": 210.0,  # TUNING (not in GDD)
	"claim_radius": 30.0,  # TUNING (not in GDD)
	"rewards": ["reinforce", "replenish"],  # GDD §11 the two empowered-grave effects
	"reinforce_class": "warrior",  # TUNING (not in GDD)
	"reinforce_count": 3,  # TUNING (not in GDD)
	"reinforce_duration": 20.0,  # TUNING (not in GDD)
	"reinforce_hp_mult": 1.0,  # TUNING (not in GDD)
	"reinforce_damage_mult": 1.0,  # TUNING (not in GDD)
}

## Desecration events (GDD §11 "priests attempt to consecrate selected
## graves; failure to interrupt creates hazardous anti-undead spaces";
## §10 "holy suppression / consecration zones apply localized temporary
## pressure"). Each marked grave gets one consecrator who walks in from the
## spawn ring with an escort and channels at the grave. Killing the
## consecrator interrupts it; otherwise the grave becomes a holy zone.
##   grave_distance_min / grave_distance_max — px from the necromancer.
##   consecrator_kind    — EnemyData kind that channels.
##   consecrator_hp_mult — extra HP multiplier for the consecrator.
##   post_radius         — px; channelling starts this close to the grave.
##   channel_time        — s of channelling needed to consecrate.
##   interrupt_xp        — XP dropped at a grave whose consecrator died.
##   interrupt_crystals  — number of crystals that XP is split into.
##   zone                — the holy zone a consecrated grave leaves behind
##                         (keys as in a StageDirector holy zone):
##     radius            — px.
##     arm_time          — s the zone is telegraphed before it hurts.
##     duration          — s it stays active once armed.
##     undead_dps        — damage per second to summons inside.
##     undead_slow       — fraction of speed summons lose inside.
##     player_damage     — damage to the necromancer per player_interval.
##     player_interval   — s between hits on the necromancer inside.
const CONSECRATION := {
	"grave_distance_min": 170.0,  # TUNING (not in GDD)
	"grave_distance_max": 240.0,  # TUNING (not in GDD)
	"consecrator_kind": "chaplain",  # GDD §11 "priests attempt to consecrate"
	"consecrator_hp_mult": 2.0,  # TUNING (not in GDD)
	"post_radius": 6.0,  # TUNING (not in GDD)
	"channel_time": 12.0,  # TUNING (not in GDD)
	"interrupt_xp": 12,  # TUNING (not in GDD)
	"interrupt_crystals": 4,  # TUNING (not in GDD)
	"zone": {
		"radius": 85.0,  # TUNING (not in GDD)
		"arm_time": 1.5,  # TUNING (not in GDD)
		"duration": 45.0,  # TUNING (not in GDD) "temporary" (§10) but long
		"undead_dps": 4.0,  # TUNING (not in GDD)
		"undead_slow": 0.35,  # TUNING (not in GDD)
		"player_damage": 4.0,  # TUNING (not in GDD)
		"player_interval": 1.0,  # TUNING (not in GDD)
	},
}

## Crypt Defender event (GDD §11 "briefly awaken ancient guardian units").
## A sealed crypt appears near the necromancer; walking up to it awakens
## temporary guardians that fight with the horde.
##   distance_min / distance_max — px from the necromancer.
##   lifetime         — s the crypt waits before it seals again.
##   claim_radius     — px; the necromancer awakens it within this distance.
##   guardian_class   — summon class the guardians use (shared AI).
##   guardian_count   — guardians awakened.
##   guardian_duration — s before they return to their crypt.
##   guardian_hp_mult / guardian_damage_mult — stat multipliers on top of
##                      the class's current effective stats.
const CRYPT_DEFENDER := {
	"distance_min": 140.0,  # TUNING (not in GDD)
	"distance_max": 210.0,  # TUNING (not in GDD)
	"lifetime": 25.0,  # TUNING (not in GDD)
	"claim_radius": 34.0,  # TUNING (not in GDD)
	"guardian_class": "warrior",  # TUNING (not in GDD)
	"guardian_count": 4,  # TUNING (not in GDD)
	"guardian_duration": 30.0,  # TUNING (not in GDD) "briefly"
	"guardian_hp_mult": 1.6,  # TUNING (not in GDD)
	"guardian_damage_mult": 1.5,  # TUNING (not in GDD)
}

## Seconds between holy-zone damage ticks on summons (consecrated graves and
## Sir Alaric's Consecrated Ground).
const ZONE_TICK: float = 0.25  # TUNING (not in GDD)
## Seconds a summon stays slowed after its last zone tick (a bit more than
## ZONE_TICK so the slow doesn't flicker).
const ZONE_SLOW_LINGER: float = 0.35  # TUNING (not in GDD)

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
