## GraveyardStage — STAGE 1, THE DESECRATED GRAVEYARD (GDD §8.1 / §11):
## every number and event that belongs to this stage only. StageRegistry
## exposes it to the run as `Game.stage_def` (the STAGE dictionary at the
## bottom; its keys are documented in StageRegistry). Shared run rules (the
## 20:00 countdown, enemy time scaling, caps, spawn ring) stay in WaveData.
##
## It follows the GDD §11 Desecrated Graveyard timeline (formatted as GDD.md
## §8.1) at its real, uncompressed times (user decision: a 20:00 countdown):
##
##   GDD time   Event                       Prototype (elapsed)
##   00:00      Recruits                    0:00 (recruit waves at 0:12, 0:40, 1:15...)
##   03:00      Archers and footmen         3:00
##   05:00      Chaplain elite              5:00
##   08:00      Purifiers                   8:00
##   10:00      Grave consecration event    10:00 (desecration: Chaplains walk to
##                                                 marked graves and channel; kill
##                                                 them or the grave becomes holy
##                                                 ground)
##   13:00      Templar Knights             13:00
##   15:00      Major assault               15:00
##   18:00      Final preparation wave      16:00 (moved: Sir Alaric now comes at
##                                                 17:00, see below)
##   20:00      Sir Alaric boss             17:00 (user decision: 3:00 left)
##
## The GDD gives no times for the empowered graves, the second desecration
## (14:00), the Crypt Defender (16:30), the waves that fill the gaps between
## the GDD beats, or the two Call to Arms waves during the boss fight; those
## times are TUNING. Pacing (TUNING): density ramps in steps, each GDD beat is
## a peak, and the segment after most peaks is a short lull; the boss fight
## has a thinner trickle of its own.
##
## Spawn rates, caps and weights are all TUNING (not in GDD).
## Moved here unchanged from WaveData / ArenaData by the multi-stage refactor
## (same-seed autotest runs are identical before and after).
class_name GraveyardStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "graveyard"

## Game time (s) at which Sir Alaric appears (3:00 left on the countdown).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) user decision 17:00 (GDD §11 places him at 20:00)

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
	# 0:00-3:00, GDD §11 "00:00 Recruits": recruits only, ramping every minute.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "Survive: the Covenant has found your graveyard"},
	{"start": 60.0, "rate": 1.8, "max_alive": 42,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "Raise your army: more recruits are coming"},
	{"start": 120.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "Hold the graveyard against the recruits"},
	# 3:00, GDD §11 "Archers and footmen".
	{"start": 180.0, "rate": 2.0, "max_alive": 55,  # TUNING (not in GDD)
		"weights": {"recruit": 0.72, "footman": 0.2, "archer": 0.08},
		"objective": "Archers and footmen join the purge"},
	{"start": 255.0, "rate": 1.8, "max_alive": 52,  # TUNING (not in GDD) lull
		"weights": {"recruit": 0.71, "footman": 0.2, "archer": 0.09},
		"objective": "Archers and footmen join the purge"},
	# 5:00, GDD §11 "Chaplain elite".
	{"start": 300.0, "rate": 2.4, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"recruit": 0.62, "footman": 0.22, "archer": 0.1, "chaplain": 0.06},
		"objective": "Chaplains heal their soldiers: kill them first"},
	{"start": 390.0, "rate": 2.7, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"recruit": 0.6, "footman": 0.24, "archer": 0.1, "chaplain": 0.06},
		"objective": "The Covenant tightens its ring"},
	{"start": 450.0, "rate": 2.3, "max_alive": 75,  # TUNING (not in GDD) lull before the Purifiers
		"weights": {"recruit": 0.6, "footman": 0.24, "archer": 0.1, "chaplain": 0.06},
		"objective": "The Covenant tightens its ring"},
	# 8:00, GDD §11 "Purifiers".
	{"start": 480.0, "rate": 3.2, "max_alive": 100,  # TUNING (not in GDD)
		"weights": {"recruit": 0.48, "footman": 0.2, "archer": 0.13, "chaplain": 0.05, "purifier": 0.14},
		"objective": "Purifiers hunt your undead"},
	{"start": 555.0, "rate": 3.6, "max_alive": 110,  # TUNING (not in GDD)
		"weights": {"recruit": 0.46, "footman": 0.21, "archer": 0.13, "chaplain": 0.05, "purifier": 0.15},
		"objective": "Purifiers hunt your undead"},
	# 10:00, GDD §11 "Grave consecration event" (the trickle eases meanwhile).
	{"start": 600.0, "rate": 3.2, "max_alive": 105,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.2, "archer": 0.13, "chaplain": 0.05, "purifier": 0.17},
		"objective": "The graves are being consecrated"},
	{"start": 660.0, "rate": 4.0, "max_alive": 125,  # TUNING (not in GDD)
		"weights": {"recruit": 0.44, "footman": 0.22, "archer": 0.14, "chaplain": 0.05, "purifier": 0.15},
		"objective": "The crusade presses on"},
	{"start": 735.0, "rate": 3.4, "max_alive": 115,  # TUNING (not in GDD) lull before the Templars
		"weights": {"recruit": 0.44, "footman": 0.22, "archer": 0.14, "chaplain": 0.05, "purifier": 0.15},
		"objective": "Steel yourself: heavy knights approach"},
	# 13:00, GDD §11 "Templar Knights".
	{"start": 780.0, "rate": 5.0, "max_alive": 150,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.25, "archer": 0.13, "chaplain": 0.05, "purifier": 0.13, "templar": 0.04},
		"objective": "Templar Knights charge your lines"},
	# 14:00, second desecration (TUNING).
	{"start": 840.0, "rate": 4.8, "max_alive": 150,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.25, "archer": 0.13, "chaplain": 0.05, "purifier": 0.13, "templar": 0.04},
		"objective": "More graves are being consecrated"},
	# 15:00, GDD §11 "Major assault" (the density peak of the run).
	{"start": 900.0, "rate": 7.0, "max_alive": 175,  # TUNING (not in GDD)
		"weights": {"recruit": 0.44, "footman": 0.22, "archer": 0.12, "chaplain": 0.05, "purifier": 0.13, "templar": 0.04},
		"objective": "Major assault!"},
	# 16:00, GDD §11 "Final preparation wave" (GDD 18:00, moved before the boss).
	{"start": 960.0, "rate": 6.0, "max_alive": 170,  # TUNING (not in GDD)
		"weights": {"recruit": 0.4, "footman": 0.22, "archer": 0.14, "chaplain": 0.05, "purifier": 0.15, "templar": 0.04},
		"objective": "Final preparation: Sir Alaric approaches"},
	# 17:00, Sir Alaric: a thinner trickle so the duel stays readable, rising
	# toward the end of the countdown.
	{"start": BOSS_TIME, "rate": 3.2, "max_alive": 100,  # TUNING (not in GDD)
		"weights": {"recruit": 0.55, "footman": 0.25, "archer": 0.15, "purifier": 0.05},
		"objective": "Sir Alaric, the Gravebreaker, has come for you"},
	{"start": 1110.0, "rate": 4.0, "max_alive": 120,  # TUNING (not in GDD)
		"weights": {"recruit": 0.5, "footman": 0.25, "archer": 0.15, "purifier": 0.1},
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
	# 0:00-3:00 recruits (GDD §11 00:00), with early beats so the first minute has action.
	{"time": 12.0, "type": "wave", "banner": "Covenant recruits charge!", "formation": "arc",  # TUNING (not in GDD) first beat: shows warrior blocking
		"groups": [{"kind": "recruit", "count": 7, "elite": false}]},
	{"time": 40.0, "type": "wave", "banner": "Recruits close in from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A recruit column marches in!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "A veteran sergeant leads the recruits!", "formation": "arc",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "recruit", "count": 1, "elite": true}, {"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "The recruits surround you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 16, "elite": false}]},
	# 3:00, GDD §11 "Archers and footmen".
	{"time": 180.0, "type": "wave", "banner": "Archers and footmen march in!", "formation": "arc",  # GDD §11 03:00
		"groups": [{"kind": "footman", "count": 5, "elite": false}, {"kind": "archer", "count": 3, "elite": false}, {"kind": "recruit", "count": 6, "elite": false}]},
	{"time": 225.0, "type": "wave", "banner": "A footman column advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "footman", "count": 6, "elite": false}, {"kind": "recruit", "count": 6, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "Archers take aim!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "archer", "count": 4, "elite": false}, {"kind": "recruit", "count": 10, "elite": false}]},
	# 5:00, GDD §11 "Chaplain elite".
	{"time": 300.0, "type": "wave", "banner": "A Chaplain elite leads the charge!", "formation": "arc",  # GDD §11 05:00
		"groups": [{"kind": "chaplain", "count": 1, "elite": true}, {"kind": "recruit", "count": 12, "elite": false}, {"kind": "footman", "count": 3, "elite": false}]},
	{"time": 360.0, "type": "wave", "banner": "The Covenant closes the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 18, "elite": false}, {"kind": "footman", "count": 4, "elite": false}, {"kind": "footman", "count": 1, "elite": true}]},
	{"time": 420.0, "type": "wave", "banner": "A footman phalanx advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "footman", "count": 10, "elite": false}, {"kind": "archer", "count": 2, "elite": false}, {"kind": "chaplain", "count": 1, "elite": false}]},
	# 8:00, GDD §11 "Purifiers".
	{"time": 480.0, "type": "wave", "banner": "Purifiers have come for your dead!", "formation": "ring",  # GDD §11 08:00
		"groups": [{"kind": "purifier", "count": 8, "elite": false}, {"kind": "purifier", "count": 1, "elite": true}]},
	{"time": 525.0, "type": "wave", "banner": "Purifiers and archers flank you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "purifier", "count": 6, "elite": false}, {"kind": "archer", "count": 6, "elite": false}]},
	{"time": 570.0, "type": "wave", "banner": "The Covenant surges!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 22, "elite": false}, {"kind": "footman", "count": 6, "elite": false}, {"kind": "chaplain", "count": 2, "elite": false}]},
	# 10:00, GDD §11 "Grave consecration event".
	{"time": 600.0, "type": "consecration", "banner": "Chaplains march to consecrate your graves: stop them!",  # GDD §11 10:00 grave consecration event
		"graves": 3,  # TUNING (not in GDD)
		"escort": [{"kind": "recruit", "count": 4, "elite": false}, {"kind": "purifier", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 660.0, "type": "wave", "banner": "Elite Chaplains lead a fresh battalion!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "chaplain", "count": 2, "elite": true}, {"kind": "footman", "count": 10, "elite": false}, {"kind": "archer", "count": 6, "elite": false}]},
	{"time": 720.0, "type": "wave", "banner": "A purge sweeps the graveyard!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 26, "elite": false}, {"kind": "purifier", "count": 8, "elite": false}, {"kind": "purifier", "count": 1, "elite": true}]},
	# 13:00, GDD §11 "Templar Knights".
	{"time": 780.0, "type": "wave", "banner": "Templar Knights charge!", "formation": "line",  # GDD §11 13:00 Templar Knights
		"groups": [{"kind": "templar", "count": 3, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "templar", "count": 1, "elite": true}]},  # TUNING (not in GDD)
	{"time": 815.0, "type": "wave", "banner": "More Templars ride in!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "templar", "count": 4, "elite": false}, {"kind": "archer", "count": 8, "elite": false}]},
	{"time": 840.0, "type": "consecration", "banner": "More Chaplains seek to consecrate the graves!",  # TUNING (not in GDD) §11 desecration events recur
		"graves": 3,  # TUNING (not in GDD)
		"escort": [{"kind": "footman", "count": 2, "elite": false}, {"kind": "recruit", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	# 15:00, GDD §11 "Major assault", in two waves.
	{"time": 900.0, "type": "wave", "banner": "MAJOR ASSAULT!", "formation": "ring",  # GDD §11 15:00
		"groups": [{"kind": "recruit", "count": 30, "elite": false}, {"kind": "footman", "count": 10, "elite": false}, {"kind": "templar", "count": 3, "elite": false}, {"kind": "chaplain", "count": 2, "elite": true}]},
	{"time": 930.0, "type": "wave", "banner": "The assault's second line strikes!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "purifier", "count": 8, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "footman", "count": 1, "elite": true}]},
	# 16:00, GDD §11 "Final preparation wave" (18:00 in the GDD, moved before the boss).
	{"time": 960.0, "type": "wave", "banner": "Final preparation wave!", "formation": "arc",  # GDD §11 18:00, moved to 16:00
		"groups": [{"kind": "archer", "count": 8, "elite": false}, {"kind": "purifier", "count": 10, "elite": false}, {"kind": "footman", "count": 1, "elite": true}, {"kind": "templar", "count": 1, "elite": true}]},
	{"time": 990.0, "type": "crypt", "banner": "An ancient crypt stirs nearby: awaken its guardians!"},  # TUNING (not in GDD) §11 Crypt Defender event, untimed in the GDD
	# 17:00 Sir Alaric (BOSS_TIME): his own Call to Arms, plus two timeline beats.
	{"time": 1080.0, "type": "wave", "banner": "Call to Arms: the Covenant answers Sir Alaric!", "formation": "line",  # TUNING (not in GDD) GDD §11 "Call to Arms" as a timeline beat
		"groups": [{"kind": "footman", "count": 12, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]},
	{"time": 1140.0, "type": "wave", "banner": "Call to Arms: the last crusade surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 20, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "templar", "count": 3, "elite": false}, {"kind": "templar", "count": 1, "elite": true}]},
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
##   reinforce_count    — temporary summons per "reinforce" grave at 0:00.
##   reinforce_growth   — extra temporary summons per minute of game time
##                    (floored), so late graves still matter next to a
##                    large army.
##   reinforce_duration — s before they crumble.
##   reinforce_hp_mult / reinforce_damage_mult — their stat multipliers on
##                    top of the class's current effective stats.
##   sprite         — SpriteBank key of the grave's pixel art (StageDirector
##                    draws its code glyph when the art is missing).
const EMPOWERED_GRAVES := {
	"first": 45.0,  # TUNING (not in GDD)
	"interval": 75.0,  # TUNING (not in GDD) about 15 graves in a 20-minute run
	"until": 1150.0,  # TUNING (not in GDD)
	"lifetime": 25.0,  # TUNING (not in GDD)
	"distance_min": 130.0,  # TUNING (not in GDD)
	"distance_max": 210.0,  # TUNING (not in GDD)
	"claim_radius": 30.0,  # TUNING (not in GDD)
	"rewards": ["reinforce", "replenish"],  # GDD §11 the two empowered-grave effects
	"reinforce_class": "warrior",  # TUNING (not in GDD)
	"reinforce_count": 3,  # TUNING (not in GDD)
	"reinforce_growth": 0.2,  # TUNING (not in GDD) 3 warriors at 0:00, 6 at 15:00
	"reinforce_duration": 25.0,  # TUNING (not in GDD)
	"reinforce_hp_mult": 1.0,  # TUNING (not in GDD)
	"reinforce_damage_mult": 1.0,  # TUNING (not in GDD)
	"sprite": "structures/empowered_grave",  # Art: an open grave pouring green soul-light (figure pass, Oct 2026)
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
	"sprite": "structures/consecration_grave",  # Art of the marked grave (a plain mound and tombstone; the gold ring is drawn in code)
	"grave_distance_min": 170.0,  # TUNING (not in GDD)
	"grave_distance_max": 240.0,  # TUNING (not in GDD)
	"consecrator_kind": "chaplain",  # GDD §11 "priests attempt to consecrate"
	"consecrator_hp_mult": 2.0,  # TUNING (not in GDD)
	"post_radius": 6.0,  # TUNING (not in GDD)
	"channel_time": 12.0,  # TUNING (not in GDD)
	"interrupt_xp": 60,  # TUNING (not in GDD) about a third of a level at 10:00
	"interrupt_crystals": 6,  # TUNING (not in GDD)
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
## temporary guardians that fight with the horde. It rises at 16:30, so
## guardians claimed promptly stand beside the army when Sir Alaric arrives.
##   distance_min / distance_max — px from the necromancer.
##   lifetime         — s the crypt waits before it seals again.
##   claim_radius     — px; the necromancer awakens it within this distance.
##   guardian_class   — summon class the guardians use (shared AI).
##   guardian_count   — guardians awakened.
##   guardian_duration — s before they return to their crypt.
##   guardian_hp_mult / guardian_damage_mult — stat multipliers on top of
##                      the class's current effective stats.
const CRYPT_DEFENDER := {
	"sprite": "structures/crypt_door",  # Art of the crypt (a stone door with green runes; the claim ring is drawn in code)
	"distance_min": 140.0,  # TUNING (not in GDD)
	"distance_max": 210.0,  # TUNING (not in GDD)
	"lifetime": 25.0,  # TUNING (not in GDD)
	"claim_radius": 34.0,  # TUNING (not in GDD)
	"guardian_class": "warrior",  # TUNING (not in GDD)
	"guardian_count": 6,  # TUNING (not in GDD)
	"guardian_duration": 60.0,  # TUNING (not in GDD) "briefly", but long enough to meet Alaric
	"guardian_hp_mult": 1.6,  # TUNING (not in GDD)
	"guardian_damage_mult": 1.5,  # TUNING (not in GDD)
}

## Obstacle layout of the graveyard (read by Arena; the structural limits
## CELL / CELL_MARGIN / MAX_HALF_EXTENT stay in ArenaData). Keys:
##   density      — chance (0..1) that a cell holds an obstacle; low on
##                  purpose ("sparse").
##   clear_radius — px; no obstacle centre this close to the run start, so
##                  the opening seconds are never cramped.
##   layout_seed  — mixed into the cell hash; change it to re-roll the layout.
##   kinds        — obstacle kinds. Field reference:
##     weight      — relative chance among obstacle cells.
##     shape       — "circle" or "rect" (axis-aligned) collision shape.
##     sizes       — the kind's 2-3 FIXED size variants, smallest first:
##                   circle collision radius (px) or rect long side (px);
##                   each obstacle picks one per cell and its collision is
##                   exactly that variant (GDD §15.0 "Art pass (true pixel
##                   art)": obstacles in fixed sizes, one sprite per size,
##                   docs/art/ART_BIBLE.md obstacle manifest; sprite keys
##                   obstacles/<kind>_s|_m|_l, EnvironmentArtData). Rects:
##                   the orientation (horizontal / vertical) is picked per
##                   cell; every size is whole and every rect side even, so
##                   the 1 art px = 1 px sprite sits exactly on the shape.
##     short       — rect short side (px).
const ARENA := {
	"density": 0.22,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 7177,  # TUNING (not in GDD)
	"kinds": {
		# Broken tombs and headstones (GDD §11 art). Two sizes, matching the
		# owner's anchor sprites obstacles/gravestone_s (footprint 22 px) and
		# obstacles/gravestone_l (30 px), ART_BIBLE Anchor 5.
		"gravestone": {"weight": 0.45, "shape": "circle", "sizes": [11.0, 15.0]},  # TUNING (not in GDD)
		# Dead trees (GDD §11 art); the collision is the trunk, branches are cosmetic.
		"dead_tree": {"weight": 0.25, "shape": "circle", "sizes": [13.0, 15.0, 18.0]},  # TUNING (not in GDD)
		# Crypt walls (GDD §11 art "crypts").
		"crypt_wall": {"weight": 0.30, "shape": "rect", "sizes": [64.0, 80.0, 96.0], "short": 20.0},  # TUNING (not in GDD)
	},
}

## Sir Alaric's arrival in this stage (the boss data itself is EnemyData.BOSS).
##   id             — boss script id ("alaric" -> BossAlaric, EnemyData.BOSS).
##   time           — BOSS_TIME.
##   display_name   — HUD boss bar / end screen name.
##   short_name     — end-screen and Soul Ash line name.
##   arrive_banner  — HUD banner when he arrives.
##   defeat_banner  — HUD banner when he dies.
##   dead_objective — HUD objective once he is dead (until 0:00).
const BOSS := {
	"id": "alaric",
	"time": BOSS_TIME,
	"display_name": "Sir Alaric, the Gravebreaker",  # GDD §11
	"short_name": "Sir Alaric",
	"arrive_banner": "Sir Alaric, the Gravebreaker, has arrived!",
	"defeat_banner": "Sir Alaric has fallen! Hold out until the end...",
	"dead_objective": "Sir Alaric is dead. Survive until the countdown ends.",
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Desecrated Graveyard",  # GDD §8.1
	"short_name": "Graveyard",
	"chapter": "Chapter I",
	"description": "Defense and survival. The Crimson Covenant has found your burial grounds: hold them for twenty minutes against recruits, archers, Purifiers and Templars, then face Sir Alaric, the Gravebreaker.",  # GDD §8.1 theme / story
	"unlock": {},  # Always open.
	"unlock_text": "",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": EMPOWERED_GRAVES,
	"consecration": CONSECRATION,
	"crypt_defender": CRYPT_DEFENDER,
	"arena": ARENA,
	"ground": "graveyard",
	"enemy_hp_mult": 1.0,  # Stage 1 is the baseline difficulty.
	"enemy_damage_mult": 1.0,  # Stage 1 is the baseline difficulty.
	"enemy_mult_from": 0.0,  # TUNING (not in GDD) no step-up to delay here
	"ash_mult": 1.0,  # No Soul Ash stage bonus.
	"march": {},  # No Crimson March mechanics.
}
