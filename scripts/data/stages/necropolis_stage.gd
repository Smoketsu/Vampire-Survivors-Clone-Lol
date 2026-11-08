## NecropolisStage — STAGE 34 (temporary number; final stage 19), THE NECROPOLIS OF SAND
## (temporary Act XII, the Necropolis Dynasty, final slot VII; GDD §15.0 "The
## Necropolis Dynasty foundation (phase 1)" and "The Necropolis of Sand (Act
## XII phase 2)"; proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 3, "Stage
## A: The Necropolis of Sand"). The tomb road at dusk: dunes, rock-cut tombs
## and mortuary temples, the outer edge of the Dynasty.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable since the act went live (the lead's
## integration). Unlocked in the campaign chain (Odin's fall on
## Vigrid opens it); it runs the Dynasty's three shared rules ("dynasty": true:
## Rebirth, the Black Land, Heka) and its own systems (NecropolisDirector,
## STAGE "necropolis"): THE CANOPIC JARS beside the tombs (the stage mechanic
## that teaches Rebirth: a jar holds the Names within 300 px; break it and its
## bodies return no more), NO JARS LEFT, the Sandstorm Pass's own storm and
## the Sand Colossus (the miniboss, at 10:30). Its kinds: the shared dead,
## scarabs, guards and priests, with the Nile Archer (silenced by the storm)
## and the Jackal Warrior (elite, in pairs, lunges) of its own block in
## DynastyEnemyData. Its boss is Anubis, Opener of the Way (BossAnubis: the
## Procession, the Embalmer, the Jackal). The Devourer's Hour is its
## Reckoning (Rebirth without limit, the endless Sandstorm, the Devourer's
## lanes).
## Zones (ZONES; clock-driven, MarchDirector): the Dunes, the Tomb Road, the
## Sandstorm Pass, the Mortuary Temple.
## Anubis arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot VII (docs/last_acts/PLAN.md: the Shogunate /
## Olympus level), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name NecropolisStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "necropolis"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot VII sits with the Shogunate's 1.55-1.65 and Olympus's 1.45; a
## little lower than the Shogunate, because Rebirth gives an uncountered body
## up to 1 + 0.7 + 0.7 of its HP again).
const ENEMY_HP_MULT: float = 1.5  # TUNING (not in GDD) phase 2 (stub 1.4: the army bot ended near full HP)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (a returned body hits x1.2 per return on top).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) phase 2 (stub 1.3)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to IX (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## NecropolisGround style over the sand, the zone's floor tile
## tiles/necropolis_<style>) and its obstacle layout ("arena"; every rect
## kind lies along x, "orient": "h", as its art is drawn):
##   dunes           — the Dunes: wind-rippled dunes; sandstone blocks, a
##                     half-buried sphinx head, a lone tomb.
##   tomb_road       — the Tomb Road: the paved road of rock-cut tombs and
##                     obelisks (the jars rise at the tombs' feet).
##   sandstorm_pass  — the Sandstorm Pass: a pebbled pass of fallen blocks;
##                     one more storm blows here (NECROPOLIS "pass_storm").
##   mortuary_temple — the Mortuary Temple: inlaid flagstones, obelisks and
##                     the great mastabas.
## Obstacle kinds (the Dynasty art pass's sprites obstacles/<kind>_<size>,
## DynastyGlyphs without art):
##   dyn_tomb             — a rock-cut tomb / mortuary mastaba (rect; s, l)
##   dyn_obelisk          — an obelisk (circle footprint; s, l)
##   dyn_sphinx_head      — a half-buried sphinx head (circle; one size, m)
##   dyn_sandstone_blocks — broken blocks and a snapped column (circle; m)
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Dunes", "id": "dunes",  # Owner-approved proposal (zones)
		"blurb": "Wind-rippled dunes at dusk, where the tomb road begins",
		"ground": {"style": "dunes", "base": Color(0.40, 0.31, 0.20), "line": Color(0.34, 0.26, 0.17),
			"accent": Palette.DYN_SAND, "trim": Palette.DYN_SAND_DARK},
		"arena": {"density": 0.12, "clear_radius": 220.0, "layout_seed": 3434, "orient": "h",  # TUNING (not in GDD)
			"kinds": {
				"dyn_sandstone_blocks": {"weight": 0.45, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD) art 36x31
				"dyn_sphinx_head": {"weight": 0.2, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD) art 36x29
				"dyn_tomb": {"weight": 0.2, "shape": "rect", "sizes": [28.0, 42.0], "short": 14.0},  # TUNING (not in GDD) art 30x27 / 44x29
				"dyn_obelisk": {"weight": 0.15, "shape": "circle", "sizes": [7.0, 9.0]},  # TUNING (not in GDD) art 16x43 / 20x52
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Tomb Road", "id": "tomb_road",  # Owner-approved proposal (zones)
		"blurb": "The road of rock-cut tombs: every Name is kept in a jar beside them",
		"ground": {"style": "tomb_road", "base": Color(0.36, 0.29, 0.20), "line": Color(0.28, 0.22, 0.15),
			"accent": Palette.DYN_SAND_DARK, "trim": Palette.DYN_NIGHT_DARK},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 3444, "orient": "h",  # TUNING (not in GDD) the tombs line the road
			"kinds": {
				"dyn_tomb": {"weight": 0.6, "shape": "rect", "sizes": [28.0, 42.0], "short": 14.0},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.25, "shape": "circle", "sizes": [7.0, 9.0]},  # TUNING (not in GDD)
				"dyn_sandstone_blocks": {"weight": 0.15, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Sandstorm Pass", "id": "sandstorm_pass",  # Owner-approved proposal (zones)
		"blurb": "A pass of fallen stone where the sand never settles",
		"ground": {"style": "sandstorm_pass", "base": Color(0.38, 0.30, 0.21), "line": Color(0.30, 0.24, 0.16),
			"accent": Palette.DYN_SAND_DARK, "trim": Palette.DYN_SAND_LIGHT},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 3454, "orient": "h",  # TUNING (not in GDD)
			"kinds": {
				"dyn_sandstone_blocks": {"weight": 0.5, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD)
				"dyn_tomb": {"weight": 0.3, "shape": "rect", "sizes": [28.0, 42.0], "short": 14.0},  # TUNING (not in GDD)
				"dyn_sphinx_head": {"weight": 0.2, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Mortuary Temple", "id": "mortuary_temple",  # Owner-approved proposal (zones)
		"blurb": "The god of the tombs keeps his temple at the end of the road",
		"ground": {"style": "mortuary_temple", "base": Color(0.30, 0.25, 0.19), "line": Color(0.22, 0.18, 0.14),
			"accent": Palette.DYN_BRONZE_DARK, "trim": Palette.DYN_LAPIS},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 3464, "orient": "h",  # TUNING (not in GDD)
			"kinds": {
				"dyn_obelisk": {"weight": 0.45, "shape": "circle", "sizes": [7.0, 9.0]},  # TUNING (not in GDD)
				"dyn_tomb": {"weight": 0.4, "shape": "rect", "sizes": [28.0, 42.0], "short": 14.0},  # TUNING (not in GDD)
				"dyn_sandstone_blocks": {"weight": 0.15, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE NECROPOLIS OF SAND  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.824, 0.733, 0.384),  # The dull bronze-gold (Palette.DYN_BRONZE_LIGHT): never the player's true gold.
	"fog_color": Color(0.16, 0.13, 0.10),  # Dust over the dunes at dusk.
	"fog_bank_color": Color(0.46, 0.38, 0.26),  # Blown sand.
	"zones": ZONES,
}

## The Necropolis's stage systems (NecropolisDirector; StageRegistry "necropolis").
##   jars       — THE CANOPIC JARS beside the tombs: from `first` s, every
##                `every` s until `until`, a jar rises min..max px from a
##                standing necromancer (the seeded gameplay RNG) at the foot
##                of the nearest tomb (`tomb_kinds`) within tomb_reach px
##                (`tomb_gap` px below it), else at the point; `warn` s of
##                telegraph; at most max_alive stand or rise. The HUD
##                objective names a jar standing within objective_reach px. A
##                jar farther than abandon_reach px from every necromancer
##                for abandon_after s sinks back into the sand (not broken).
##   pass_storm — the Sandstorm Pass's own storm: at `at` s it blows for
##                `duration` s (Sandstorm.force()), with `banner`.
##   colossus_objective — HUD objective while the Sand Colossus stands.
##   jar_objective      — HUD objective while a jar stands near.
##   no_jars_banner     — banner when No Jars Left is earned.
const NECROPOLIS := {
	"jars": {
		"first": 100.0,  # TUNING (not in GDD) s (the stub's clock: 100)
		"every": 80.0,  # TUNING (not in GDD) s
		"until": BOSS_TIME - 20.0,  # TUNING (not in GDD) the Procession brings its own
		"max_alive": 3,  # TUNING (not in GDD)
		"min": 230.0,  # TUNING (not in GDD) px
		"max": 380.0,  # TUNING (not in GDD) px
		"warn": 1.2,  # TUNING (not in GDD) s
		"tomb_kinds": ["dyn_tomb"],  # Owner-approved proposal: "Jars sit beside tombs"
		"tomb_reach": 300.0,  # TUNING (not in GDD) px
		"tomb_gap": 30.0,  # TUNING (not in GDD) px (first pass 6: a mummy wedged in the notch between a jar and its tomb; a body must pass)
		"abandon_reach": 900.0,  # TUNING (not in GDD) px: a jar farther than this from every necromancer...
		"abandon_after": 12.0,  # TUNING (not in GDD) s: ...for this long sinks back into the sand (its Names crumble; it counts as not broken)
		"objective_reach": 600.0,  # TUNING (not in GDD) px
	},
	"pass_storm": {"at": 750.0, "duration": 40.0,  # TUNING (not in GDD) 12:30, the Pass's second storm
		"banner": "THE SANDSTORM PASS: the sand rises again! Bows and spells reach half as far"},  # TUNING (not in GDD)
	"colossus_objective": "Bring down the Sand Colossus: burst him, and stay out of his slam",  # TUNING (not in GDD)
	"jar_objective": "A Canopic Jar holds the Names round it: break it, and its dead return no more",  # TUNING (not in GDD)
	"no_jars_banner": "NO JARS LEFT: every Name on the tomb road is broken!",  # TUNING (not in GDD)
}

## Heka on this stage (keys as DynastyRulesData.HEKA): a glyph runs round the
## ring at least cleanse_after s before a Mender's heal or a Warder's ward can
## lift it (the foundation's flag: Menders cleansed almost every glyph within
## a second, so it never ran).
const HEKA := {
	"cleanse_after": 4.0,  # TUNING (not in GDD) s: two jumps round the ring before a cleanse takes
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## DEVOURER'S HOUR, shared by every Dynasty stage: every sarcophagus opens
## ("kind": the khopesh guard, with the shared kinds as companions), Rebirth
## has no limit, the Sandstorm becomes permanent and the Devourer sweeps its
## lanes ("devourers_hour": DynastyRulesData.DEVOURER keys; {} = those
## defaults).
const RECKONING := {
	"banner": "THE DEVOURER'S HOUR: EVERY SARCOPHAGUS OPENS",
	"kind": DynastyEnemyData.RECKONING_KIND,  # The shared Devourer's Hour heavy (the khopesh guard).
	"devourers_hour": {},  # DynastyRulesData.DEVOURER defaults.
	"companions": DynastyEnemyData.RECKONING_COMPANIONS,  # Mummies, scarabs, a Heka priest.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) guards
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEVOURER'S HOUR: the dead rise without end, and the Devourer eats its lanes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the wrapped
## dead lead, scarabs pour out of the tombs, the guard (khopesh guards, Nile
## Archers from 3:00, Jackal Warriors from 6:00) and the priesthood join; the
## priests and jackals stay rare (the jackals also come in pairs, EVENTS).
const SEGMENTS := [
	# Zone I, the Dunes.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"mummy": 0.6, "mummy_female": 0.4},
		"objective": "The Dunes: the wrapped dead walk. A fallen mummy's Name waits over it: smash it or raise it"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"mummy": 0.45, "mummy_female": 0.3, "scarab_swarm": 0.25},
		"objective": "Scarabs gnaw your Warders' barriers and your Orb Shield. A Name left alone for 6 s stands up again"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"mummy": 0.38, "mummy_female": 0.26, "scarab_swarm": 0.16, "khopesh_guard": 0.09, "nile_archer": 0.07, "heka_priest": 0.04},
		"objective": "Heka priests curse your dead; Nile Archers shoot from the dunes. A Mender's heal clears a glyph that has run"},
	# Zone II, the Tomb Road (5:00).
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"mummy": 0.33, "mummy_female": 0.23, "scarab_swarm": 0.15, "khopesh_guard": 0.11, "nile_archer": 0.08, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "The Tomb Road: the Canopic Jars beside the tombs hold the Names. Break the jars"},
	{"start": 420.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"mummy": 0.32, "mummy_female": 0.22, "scarab_swarm": 0.14, "khopesh_guard": 0.11, "nile_archer": 0.08, "jackal_warrior": 0.03, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "Jackal Warriors hunt in pairs and lunge over your ring. Raise them before they stand again"},
	# Zone III, the Sandstorm Pass (10:00): the Sand Colossus at 10:30.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"mummy": 0.3, "mummy_female": 0.22, "scarab_swarm": 0.14, "khopesh_guard": 0.12, "nile_archer": 0.08, "jackal_warrior": 0.04, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "The Sandstorm Pass: when the sand blows, every bow and spell reaches half as far, and the archers fall silent"},
	# Zone IV, the Mortuary Temple (15:00).
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"mummy": 0.29, "mummy_female": 0.21, "scarab_swarm": 0.14, "khopesh_guard": 0.13, "nile_archer": 0.08, "jackal_warrior": 0.05, "heka_priest": 0.05, "embalmer": 0.05},
		"objective": "The Mortuary Temple: the Dynasty comes for its dead, and for yours"},
	# 17:00, the boss: thinner, so the fight is the procession.
	{"start": BOSS_TIME, "rate": 2.2, "max_alive": 60,  # TUNING (not in GDD) thinner during the boss fight (he brings his own march)
		"weights": {"mummy": 0.34, "mummy_female": 0.24, "scarab_swarm": 0.16, "khopesh_guard": 0.1, "nile_archer": 0.08, "heka_priest": 0.04, "embalmer": 0.04},
		"objective": "Anubis has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS), plus the
## Necropolis's own (NecropolisDirector):
##   "colossus" — the Sand Colossus (kind `kind`) walks in on the spawn ring
##                with an `escort` (groups of {kind, count}); the stage
##                miniboss.
## Jackal Warriors come in pairs (owner-approved proposal: "pack of two").
const EVENTS := [
	# Zone I: the Dunes.
	{"time": 20.0, "type": "wave", "banner": "The wrapped dead rise from the sand!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of scarabs pours out of a tomb!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Heka priest raises his hands: a glyph for your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 1, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 230.0, "type": "wave", "banner": "Nile Archers on the dunes! Kill them before the storm, or wait it out!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "nile_archer", "count": 4, "elite": false}, {"kind": "mummy", "count": 8, "elite": false}]},
	# Zone II: the Tomb Road.
	{"time": 320.0, "type": "wave", "banner": "An Embalmer walks with the dead: their Names return faster!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "embalmer", "count": 1, "elite": false}, {"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 390.0, "type": "wave", "banner": "Two Jackal Warriors hunt you! Blockers, and raise them when they fall!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "jackal_warrior", "count": 2, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 470.0, "type": "wave", "banner": "Two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "The guard of the tombs advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 5, "elite": false}, {"kind": "nile_archer", "count": 3, "elite": false}, {"kind": "heka_priest", "count": 1, "elite": false}]},
	# Zone III: the Sandstorm Pass.
	{"time": 630.0, "type": "colossus", "banner": "THE SAND COLOSSUS! A statue of the old kings walks: stay out of his slam!",  # Owner-approved proposal (miniboss); 9:30 left
		"kind": "sand_colossus", "elite": false,
		"escort": [{"kind": "mummy", "count": 8}, {"kind": "khopesh_guard", "count": 2}]},  # TUNING (not in GDD)
	{"time": 700.0, "type": "wave", "banner": "The priesthood comes to wrap its dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 2, "elite": false}, {"kind": "mummy", "count": 10, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "Jackals in the storm!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "jackal_warrior", "count": 2, "elite": false}, {"kind": "jackal_warrior", "count": 2, "elite": false}, {"kind": "scarab_swarm", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "A procession of the dead!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	# Zone IV: the Mortuary Temple.
	{"time": 930.0, "type": "wave", "banner": "The whole Dynasty comes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 4, "elite": false}, {"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}, {"kind": "nile_archer", "count": 4, "elite": false}, {"kind": "scarab_swarm", "count": 4, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The jackals gather before their master!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "jackal_warrior", "count": 2, "elite": false}, {"kind": "mummy", "count": 10, "elite": false}, {"kind": "mummy_female", "count": 8, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}]},
]

## Anubis's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "anubis"). His script is scripts/enemies/dynasty/boss_anubis.gd (loaded by
## his id); his numbers are AnubisData's.
const BOSS := {
	"id": "anubis",
	"time": BOSS_TIME,
	"display_name": "Anubis, Opener of the Way",
	"short_name": "Anubis",
	"arrive_banner": "Anubis, Opener of the Way, leads the procession of the dead!",
	"defeat_banner": "Anubis falls, and the procession scatters! Hold out until the end...",
	"dead_objective": "Anubis is dead. Survive the Devourer's Hour... you cannot.",
}

## Placeholder floor of the foundation stub (DynastyGround "floor" key), kept
## for the other tools that read it; the stage draws NecropolisGround
## ("ground").
const FLOOR := {
	"style": "sand",  # dunes at dusk, wind ripples, scattered stones.
	"base": Color(0.42, 0.33, 0.22),  # TUNING (not in GDD)
	"line": Color(0.36, 0.28, 0.19),  # TUNING (not in GDD)
	"accent": Palette.DYN_SAND_DARK,  # TUNING (not in GDD)
	"trim": Palette.DYN_NIGHT,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Necropolis of Sand",
	"short_name": "Necropolis",
	"chapter": "Chapter XXXIV",  # Temporary (the reorder pass renumbers; final stage 19).
	"act": 12,  # Temporary Act XII, the Necropolis Dynasty (final slot VII; docs/last_acts/PLAN.md).
	"playable": true,  # The Necropolis Dynasty goes live (integration, GDD §15.0 "The Necropolis Dynasty goes live (integration)").
	"description": "The tomb road at dusk, where the dunes meet the rock-cut tombs: the Dynasty has come to take its dead back, and every mummy it raises knows its name.",
	"unlock": {"stage": "vigrid", "boss_kills": 1},  # PLAN.md: after the Norse act's last boss (odin, stage vigrid; set at the wave 1 integration)
	"unlock_text": "Defeat Odin and Fenrir on Vigrid to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Dynasty stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "necropolis",  # NecropolisGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"necropolis": NECROPOLIS,  # NecropolisDirector: the jars beside the tombs, No Jars Left, the Pass's storm, the Sand Colossus.
	"dynasty": true,  # Rebirth, the Black Land, Heka (DynastyRules).
	"rebirth": {},  # This stage's Rebirth overrides ({} = DynastyRulesData.REBIRTH).
	"jars": {"every": 0.0},  # The stub's jar clock off: NecropolisDirector raises the jars beside the tombs.
	"quicksand": {},  # This stage's quicksand ({} = DynastyRulesData.QUICKSAND).
	"sandstorm": {},  # This stage's Sandstorm ({} = DynastyRulesData.SANDSTORM; the Pass adds one through NECROPOLIS "pass_storm").
	"heka": HEKA,  # This stage's Heka (cleanse_after).
	"zones": ZONES,  # The four zones.
	"music": "weighing",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
