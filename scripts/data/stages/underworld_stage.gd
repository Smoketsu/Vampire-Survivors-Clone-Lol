## UnderworldStage — STAGE 12, THE ASPHODEL UNDERWORLD, the finale of Act IV (the
## Olympian Republic; GDD §15.0 "Act IV foundation (phase 1)" and "The Asphodel
## Underworld (Act IV phase 2)"; owner-approved proposal docs/act4/PROPOSAL.md
## "Stage 12: The Asphodel Underworld"). With Olympus silent, the necromancer
## goes down to the god who started it all: grey fields of asphodel, the River
## Styx, Charon's ferry, the Judges' Hall and the gates of Tartarus before
## Hades' throne. Every number and event that belongs to this stage;
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE dictionary
## at the bottom; its keys are documented in StageRegistry). Unlocked by
## toppling Zeus on Mount Olympus.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of grey mist, the
## obstacles and floor re-drawn as the next zone), and the Underworld's own
## systems (UnderworldDirector, UNDERWORLD) read the current zone:
##   20:00  Zone I,   the Asphodel Fields: grey flowers, the wandering dead;
##                                         Hades' fissures open from 19:20
##   15:00  Zone II,  the Styx Crossing:   THE STYX flows across the land in
##                                         bands: it slows the living and makes
##                                         a summon wading it forget (2 s of
##                                         suppression); Charon's posts
##    8:30  CERBERUS (in the Judges' Hall's run-up), the miniboss
##   10:00  Zone III, the Judges' Hall:    marble columns, the judges' benches
##    5:00  Zone IV,  the Throne of Hades: obsidian and bronze; the Styx again,
##                                         a moat before the throne
##    3:00  HADES, Lord of the Dead (BossHades, HadesData)
##    0:00  the TWILIGHT OF THE GODS (the shared Act IV Reckoning: Bronze Titans,
##          every wrath at once, faster each minute)
## The kinds of the earlier Act IV stages (Ilion's, Olympus's) join as guest
## squads once this build knows them (UNDERWORLD "guests"), like the Iron
## Citadel's guests. The Wrath of the Gods here is Hades' fissures; Phalanx and
## Glory as on every Act IV stage. Every rate, cap and weight is TUNING (not in
## GDD) unless marked as the owner-approved proposal.
class_name UnderworldStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "underworld"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IV starts a step above the Iron Citadel's 1.4 and climbs stage by stage).
const ENEMY_HP_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the lead's balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.25  # TUNING (not in GDD) placeholder (the stub's 1.45 lowered: the Citadel's lesson, the step above is in HP, not damage)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00 (Act III)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 3.75  # TUNING (not in GDD) placeholder (Mount Olympus x3.5)

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Twilight
## of the Gods, shared by every Act IV stage: Bronze Titans step out of the
## ground ("kind") while every wrath kind fires together, faster each minute
## ("twilight": PantheonRulesData.TWILIGHT keys; {} = those defaults).
const RECKONING := {
	"banner": "THE TWILIGHT OF THE GODS: THE SKY SPLITS",
	"kind": PantheonEnemyData.BRONZE_TITAN,  # The shared Twilight kind.
	"twilight": {},  # PantheonRulesData.TWILIGHT defaults.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) Titans are few and huge
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE TWILIGHT OF THE GODS: the heavens fall on you. Endure."

## Wrath of the Gods on this stage (DivineWrath): Hades' fissures. Any other
## key overrides PantheonRulesData.WRATH["fissures"] ({} = those defaults).
const WRATH := {
	"kind": "fissures",  # Owner-approved proposal: Hades' fissures (Underworld)
}

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). Shades of the Dead are the fodder, Shade Hoplites
## (the Underworld's dead in their ranks) and Hoplites the shield walls, Heroes
## the rare elites. Shades alone for the first minute (the Act III lesson: the
## starting army needs room).
const SEGMENTS := [
	# Zone I, the Asphodel Fields.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 1.0},
		"objective": "The Asphodel Fields: the dead wander the grey flowers"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.8, "shade_hoplite": 0.2},
		"objective": "The dead still march in their ranks: break the walls from the flanks"},
	{"start": 180.0, "rate": 2.0, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.7, "shade_hoplite": 0.22, "hoplite": 0.08},
		"objective": "Hades' fissures swallow the dead: no corpse rises there"},
	# Zone II, the Styx Crossing.
	{"start": 300.0, "rate": 2.3, "max_alive": 56,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.62, "shade_hoplite": 0.24, "hoplite": 0.13, "hero": 0.01},
		"objective": "The Styx: the living slow in it, your dead forget"},
	{"start": 420.0, "rate": 2.6, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.58, "shade_hoplite": 0.26, "hoplite": 0.145, "hero": 0.015},
		"objective": "Fight on the banks: keep your dead out of the river"},
	{"start": 540.0, "rate": 2.8, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.56, "shade_hoplite": 0.27, "hoplite": 0.155, "hero": 0.015},
		"objective": "Cross the Styx: the Judges wait beyond"},
	# Zone III, the Judges' Hall.
	{"start": 600.0, "rate": 3.0, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.54, "shade_hoplite": 0.28, "hoplite": 0.16, "hero": 0.02},
		"objective": "The Judges' Hall: the dead are weighed here"},
	{"start": 750.0, "rate": 3.3, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.52, "shade_hoplite": 0.29, "hoplite": 0.17, "hero": 0.02},
		"objective": "The hound of the gates hunts you: kill his heads one by one"},
	# Zone IV, the Throne of Hades.
	{"start": 900.0, "rate": 3.6, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.5, "shade_hoplite": 0.3, "hoplite": 0.175, "hero": 0.025},
		"objective": "The Throne of Hades: the Lord of the Dead stirs"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"shade_of_dead": 0.6, "shade_hoplite": 0.26, "hoplite": 0.125, "hero": 0.015},
		"objective": "Make the Lord of the Dead kneel"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave": formation + groups; "line" rows lock as they arrive), plus the
## UnderworldDirector's:
##   "cerberus" — the miniboss (`kind`) bounds in with his `escort` groups.
const EVENTS := [
	# Zone I: the Asphodel Fields.
	{"time": 20.0, "type": "wave", "banner": "The dead rise from the asphodel!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 12, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "The dead march in their old ranks: strike the wall's flanks!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_hoplite", "count": 6, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Hero's shade takes the field: kill it before it wins Glory!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 1, "elite": false}, {"kind": "shade_of_dead", "count": 8, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "Two shield walls close in!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_hoplite", "count": 8, "elite": false}, {"kind": "hoplite", "count": 4, "elite": false}]},
	# Zone II (5:00): the Styx Crossing.
	{"time": 330.0, "type": "wave", "banner": "The dead ford the Styx toward you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 18, "elite": false}, {"kind": "shade_hoplite", "count": 6, "elite": false}]},
	{"time": 430.0, "type": "wave", "banner": "Heroes lead the host across the river!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "hoplite", "count": 8, "elite": false}, {"kind": "shade_of_dead", "count": 10, "elite": false}]},
	{"time": 530.0, "type": "wave", "banner": "A phalanx of the dead holds the far bank!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_hoplite", "count": 16, "elite": false}]},
	# Zone III (10:00): the Judges' Hall.
	{"time": 615.0, "type": "wave", "banner": "The Judges' Hall: the condemned are loosed on you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 22, "elite": false}, {"kind": "shade_hoplite", "count": 8, "elite": false}, {"kind": "hero", "count": 1, "elite": false}]},
	{"time": 690.0, "type": "cerberus", "banner": "CERBERUS bounds out of the dark: kill his three heads!", "kind": UnderworldEnemyData.CERBERUS,  # Owner-approved proposal: the miniboss
		"escort": [{"kind": "shade_of_dead", "count": 8, "elite": false}]},  # TUNING (not in GDD)
	{"time": 820.0, "type": "wave", "banner": "The phalanx marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "hoplite", "count": 12, "elite": false}, {"kind": "shade_hoplite", "count": 12, "elite": false}]},
	# Zone IV (15:00): the Throne of Hades.
	{"time": 905.0, "type": "wave", "banner": "The Throne of Hades: his court of the dead stands before it!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "shade_hoplite", "count": 16, "elite": false}, {"kind": "shade_of_dead", "count": 14, "elite": false}]},
	{"time": 965.0, "type": "wave", "banner": "The last host of the Underworld!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hero", "count": 2, "elite": false}, {"kind": "hoplite", "count": 14, "elite": false}, {"kind": "shade_of_dead", "count": 16, "elite": false}]},
	# 17:00 Hades (BOSS_TIME), plus two sallies.
	{"time": 1090.0, "type": "wave", "banner": "The dead rally to their lord!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_hoplite", "count": 10, "elite": false}, {"kind": "shade_of_dead", "count": 10, "elite": false}]},
	{"time": 1160.0, "type": "wave", "banner": "Shades pour out of Tartarus!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "shade_of_dead", "count": 20, "elite": false}, {"kind": "hero", "count": 1, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## plus the UnderworldDirector's per-zone systems:
##   styx — true: the River Styx flows in this zone (UNDERWORLD "styx").
## `ground` is an UnderworldGround look: style "asphodel" (grey ash with pale
## asphodel flowers), "styx" (dark wet sand on the river banks), "hall" (cracked
## marble flags) or "throne" (black obsidian veined with bronze); base / line /
## accent / glow colours of the code floor (the tiles/underworld_<style> PNG
## replaces them when it exists). Obstacle kinds are drawn by UnderworldGlyphs
## (their obstacles/<kind> PNGs when they exist).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Asphodel Fields",  # Owner-approved proposal zone I
		"blurb": "Grey fields of pale flowers where the forgotten dead wander",
		"ground": {"style": "asphodel", "base": Color(0.11, 0.11, 0.12), "line": Color(0.15, 0.15, 0.16),
			"accent": Color(0.812, 0.796, 0.769), "glow": Color(0.659, 0.439, 0.180)},
		"arena": {"density": 0.13, "clear_radius": 220.0, "layout_seed": 1231,  # TUNING (not in GDD)
			"kinds": {
				"grave_stele": {"weight": 0.45, "shape": "rect", "sizes": [36.0, 48.0, 60.0], "short": 22.0},  # TUNING (not in GDD)
				"dead_poplar": {"weight": 0.55, "shape": "circle", "sizes": [11.0, 14.0, 18.0]},  # TUNING (not in GDD)
			}},
		"styx": false},
	{"start": 300.0, "numeral": "II", "name": "The Styx Crossing",  # Owner-approved proposal zone II
		"blurb": "Black water that slows the living and makes the dead forget",
		"ground": {"style": "styx", "base": Color(0.085, 0.09, 0.10), "line": Color(0.12, 0.13, 0.14),
			"accent": Color(0.40, 0.42, 0.44), "glow": Color(0.36, 0.55, 0.70)},
		"arena": {"density": 0.1, "clear_radius": 220.0, "layout_seed": 1232,  # TUNING (not in GDD) open banks
			"kinds": {
				"ferry_post": {"weight": 0.5, "shape": "circle", "sizes": [8.0, 10.0]},  # TUNING (not in GDD)
				"styx_rock": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 15.0, 19.0]},  # TUNING (not in GDD)
			}},
		"styx": true},
	{"start": 600.0, "numeral": "III", "name": "The Judges' Hall",  # Owner-approved proposal zone III
		"blurb": "Cracked marble where the three Judges weighed every soul",
		"ground": {"style": "hall", "base": Color(0.16, 0.16, 0.17), "line": Color(0.10, 0.10, 0.11),
			"accent": Color(0.55, 0.55, 0.56), "glow": Color(0.659, 0.439, 0.180)},
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 1233,  # TUNING (not in GDD)
			"kinds": {
				"judges_column": {"weight": 0.6, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"judgement_bench": {"weight": 0.4, "shape": "rect", "sizes": [52.0, 68.0, 84.0], "short": 24.0},  # TUNING (not in GDD)
			}},
		"styx": false},
	{"start": 900.0, "numeral": "IV", "name": "The Throne of Hades",  # Owner-approved proposal zone IV
		"blurb": "Obsidian and bronze before the empty-eyed throne; the Styx runs as its moat",
		"ground": {"style": "throne", "base": Color(0.06, 0.055, 0.07), "line": Color(0.10, 0.09, 0.11),
			"accent": Color(0.26, 0.22, 0.28), "glow": Color(0.659, 0.439, 0.180)},
		"arena": {"density": 0.09, "clear_radius": 240.0, "layout_seed": 1234,  # TUNING (not in GDD) sparse: the boss arena
			"kinds": {
				"obsidian_spire": {"weight": 0.6, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"soul_brazier": {"weight": 0.4, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
			}},
		"styx": true},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO THE UNDERWORLD  -  ZONE %s",
	"zone_color": Color(0.36, 0.55, 0.70),  # Aegean shade (the Underworld's cold light).
	"fog_color": Color(0.05, 0.05, 0.06),  # Grey mist.
	"fog_bank_color": Color(0.30, 0.31, 0.33),  # Ash-grey mist banks.
	"zones": ZONES,
}

## The Underworld's systems (UnderworldDirector; StageRegistry "underworld").
##   zones  — the ZONES list (each zone's "styx" switch).
##   styx   — the River Styx (owner-approved proposal: "a river band that slows
##            the living and makes summons forget (a summon wading it is
##            suppressed for 2 s, through the existing add_suppression() path)"):
##     period       px between two bands (world y; the river repeats across the land).
##     half_width   px each side of a band's centre line that is water.
##     amplitude    px the bands meander (a sine along world x).
##     wavelength   px of one meander.
##     phase_step   rad each band's meander is shifted from the one above.
##     check_every  s between two checks of who stands in the water (5 Hz).
##     slow_player  fraction of speed the necromancer loses wading (TerrainSlow,
##                  Brinewalker applies).
##     slow_enemy   fraction the living enemies lose (Enemy.apply_slow(), their
##                  own slow path; floating shades, structures, the boss and
##                  minibosses are not slowed).
##     linger       s a slow lasts after the last check that found him in it.
##     forget_time  s a summon wading it is suppressed (owner-approved: 2 s).
##     forget_radius px of each suppression zone (one per forget_cell px cell
##                  of the river at most every forget_time s).
##     forget_cell  px; the river is cut into cells this wide for the zones.
##     forget_damage_mult minion damage share inside a forget zone.
##   guest_* / guests — the earlier Act IV stages' kinds in small squads (as
##            CitadelStage.CITADEL): candidate ids per kind (the first one this
##            build knows; none = skipped) and a weight.
const UNDERWORLD := {
	"zones": ZONES,
	"styx": {
		"period": 820.0,  # TUNING (not in GDD) px: about a screen and a half between two crossings
		"half_width": 46.0,  # TUNING (not in GDD) px: a 92 px river, a few steps to ford
		"amplitude": 70.0,  # TUNING (not in GDD) px
		"wavelength": 900.0,  # TUNING (not in GDD) px
		"phase_step": 2.1,  # TUNING (not in GDD) rad
		"check_every": 0.2,  # TUNING (not in GDD) s (5 Hz, the AI's think rate)
		"slow_player": 0.35,  # TUNING (not in GDD) the necromancer wades at 65%
		"slow_enemy": 0.4,  # TUNING (not in GDD) the living foes wade at 60%
		"linger": 0.3,  # TUNING (not in GDD) s
		"forget_time": 2.0,  # Owner-approved proposal: "suppressed for 2 s"
		"forget_radius": 44.0,  # TUNING (not in GDD) px
		"forget_cell": 64.0,  # TUNING (not in GDD) px
		"forget_damage_mult": 0.6,  # TUNING (not in GDD) the dead forget what they fight
	},
	"guest_first": 300.0,  # TUNING (not in GDD) no heavies before 5:00 (the Citadel's lesson)
	"guest_interval": 80.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 7,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["legionary"], "weight": 1.0},  # The Shores of Ilion (Act IV phase 2): the testudo soldiers
		{"ids": ["wolf_of_rome"], "weight": 0.8},
		{"ids": ["cyclops"], "weight": 0.3},
		{"ids": ["centaur_archer"], "weight": 0.6},  # Mount Olympus (Act IV phase 2)
		{"ids": ["amazon"], "weight": 0.5},
		{"ids": ["gorgon"], "weight": 0.3},
	],
}

## Hades' arrival (keys as GraveyardStage.BOSS): HadesData.ARRIVAL (boss id
## "hades", the kneeling line as the defeat banner), whose `time` equals
## BOSS_TIME (17:00).
const BOSS: Dictionary = HadesData.ARRIVAL

## Floor look of the placeholder "pantheon" ground (PantheonGround; the stage
## now uses UnderworldGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "asphodel",  # Grey ash fields with pale asphodel flowers.
	"base": Color(0.11, 0.11, 0.12),  # TUNING (not in GDD) grey underworld ash
	"line": Color(0.15, 0.15, 0.16),  # TUNING (not in GDD)
	"accent": Color(0.812, 0.796, 0.769),  # TUNING (not in GDD) marble asphodel petals
	"trim": Color(0.659, 0.439, 0.180),  # TUNING (not in GDD) bronze flower hearts
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Asphodel Underworld",
	"short_name": "Underworld",
	"chapter": "Chapter XII",
	"act": 4,  # Act IV, the Olympian Republic.
	"playable": false,  # Phase 2 built; the lead turns it on after the merge, the review and the owner's playtest.
	"description": "With Olympus silent, go down to the god who started it all: grey fields of asphodel, the River Styx, Charon's ferry and the gates of Tartarus. Hades waits on his throne.",
	"unlock": {"stage": "olympus", "boss_kills": 1},  # Owner-approved: each boss unlocks the next stage
	"unlock_text": "Topple Zeus on Mount Olympus to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IV stages.
	"consecration": {},  # A Covenant event: none in Act IV.
	"crypt_defender": {},  # None in Act IV.
	"arena": ZONES[0]["arena"],
	"ground": "underworld",  # UnderworldGround (the four zone floors and the Styx).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"underworld": UNDERWORLD,  # UnderworldDirector (the Styx, Cerberus, guests).
	"pantheon": true,  # Act IV: Wrath of the Gods, Phalanx, Glory (PantheonRules).
	"wrath": WRATH,  # Act IV: this stage's wrath kind (DivineWrath).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	"music": "bronze",  # "Hymn of Bronze" (SoundData.BRONZE_SCORE), which also loads the Pantheon sound pack
}
