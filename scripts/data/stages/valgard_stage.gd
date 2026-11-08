## ValgardStage — STAGE 17 (final order), VALGARD, THE HALL OF HEROES (the Hall of the
## Slain, temporarily Act XI, final slot VI; GDD §15.0 "Valgard, the Hall of
## Heroes (the Hall of the Slain phase 2)" and the rows after it; the act's
## section "Stage 17: Valgard, the Hall of Heroes" of
## docs/proposals/LAST_SIX_ACTS.md, with the owner decisions of Nov 7, 2026).
## A vast feast hall at the edge of the sky, long tables and shields on the
## walls. The benches stood empty since the necromancer took the world's dead;
## now the hall's own heroes rise from them.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage runs the act's three shared rules ("norse": true: the Long
## Winter, Berserkergang and the Rune-Stones, NorseRules) and the Ragnarök
## Reckoning. WARRIORS AND VALKYRIES LEAD (raiders, shield-maidens, skalds,
## berserkers and the hall's own Einherjar heavier in the timeline, valkyries
## from the first minutes; the draugr, wolves and giants of the wilds thinner).
## The braziers stand by the MAP (LONG_WINTER "points"): the Mead Hall's long
## hearth either side of the start, the yard fires and the gate braziers
## further out, so warmth is a place to hold, not everywhere.
## Four clock-driven zones (ZONES, MarchDirector; ValgardGround draws their
## floors from the art's hall planks and slabs): THE SHIELD YARD, THE MEAD
## HALL (the long tables, the Feast's heart), THE HALL OF SPEARS (the Einherjar
## Champion, the miniboss) and THE VALKYRIES' GATE (Sigrun's arena).
## THE FEAST (ValgardDirector, VALGARD): Einherjar sit at the long tables
## (drawn, no body) and wake whenever a horn blows (RuneStones.horn_blown, the
## Champion's horn, Sigrun's Doors of the Hall), then fight
## (NorseKit.make_einherjar()). Sigrun, the Shield-Queen (BossSigrun,
## SigrunData) arrives with 3:00 left: the Charge, the Holmgang, the Doors of
## the Hall. The Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD), tuned for the act's final
## slot VI (between the Shogunate and Olympus).
class_name ValgardStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "valgard"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (final slot VI: a hair above the Shogunate's 1.55 / 1.6 / 1.65; the step
## between the stages goes in HP, the Act IV lesson).
const ENEMY_HP_MULT: float = 1.65  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Enemy damage multiplier of this stage on top of the shared time scaling
## (between Olympus's 1.3 and the Shogunate's 1.5).
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00, as Acts III to IX
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of the act

# =====================================================================================
# Zones and their look
# =====================================================================================

## Obstacle kinds of the stage (the art pass's obstacles/<kind>_<size>[_v]);
## each keeps the same sizes in every zone, so its art keys stay the same:
##   long_table      — a long feast table with its benches (rect; the Feast's
##                     seats: ValgardDirector seats Einherjar at them).
##   standing_shield — a round shield on a post (circle).
## The long table's layout entry (shared by every zone; art 48 / 72 px long).
const LONG_TABLE := {"shape": "rect", "sizes": [44.0, 68.0], "short": 14.0}  # TUNING (not in GDD)
## The standing shield's layout entry (shared by every zone; art 24 / 36 px wide).
const STANDING_SHIELD := {"shape": "circle", "sizes": [9.0, 13.0]}  # TUNING (not in GDD)

## The four zones (owner-approved proposal names; the clock is authoritative).
## Keys as CrimsonMarchStage.ZONES (MarchDirector). `ground` is a
## ValgardGround look:
##   style  — "shield_yard" (weathered planks, straw, a shield's rim),
##            "mead_hall" (the hall's planks, rushes, spilt mead, embers),
##            "hall_of_spears" (cut slabs, rune lines, spear racks' shadows) or
##            "valkyries_gate" (slabs under the sky, feathers, gold light).
##   tile   — the art pass's floor tile key under tiles/ (norse_planks or
##            norse_slabs); the code colours below are the fallback.
##   base / line / accent / trim — colours of the code floor, its seams, its
##            decorations and its glints.
## `arena` is the zone's obstacle layout (keys as GraveyardStage.ARENA; each
## kind's entry is one of the constants above plus its weight).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Shield Yard",  # Owner-approved proposal (zones)
		"blurb": "Shields of the fallen on their posts, and the hall's doors above",
		"ground": {"style": "shield_yard", "tile": "norse_planks", "base": Color(0.26, 0.19, 0.13), "line": Color(0.18, 0.12, 0.08),
			"accent": Color(0.62, 0.55, 0.30), "trim": Palette.NORSE_HEARTH},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 1717,  # TUNING (not in GDD)
			"kinds": {
				"standing_shield": {"weight": 0.6, "shape": STANDING_SHIELD["shape"], "sizes": STANDING_SHIELD["sizes"]},  # TUNING (not in GDD)
				"long_table": {"weight": 0.4, "shape": LONG_TABLE["shape"], "sizes": LONG_TABLE["sizes"], "short": LONG_TABLE["short"]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Mead Hall",  # Owner-approved proposal (zones)
		"blurb": "Long tables without end, and the heroes asleep at them",
		"ground": {"style": "mead_hall", "tile": "norse_planks", "base": Color(0.24, 0.16, 0.10), "line": Color(0.17, 0.11, 0.07),
			"accent": Palette.NORSE_HEARTH_DARK, "trim": Palette.NORSE_HEARTH},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 1727,  # TUNING (not in GDD) the Feast's heart: the most tables
			"kinds": {
				"long_table": {"weight": 0.75, "shape": LONG_TABLE["shape"], "sizes": LONG_TABLE["sizes"], "short": LONG_TABLE["short"]},  # TUNING (not in GDD)
				"standing_shield": {"weight": 0.25, "shape": STANDING_SHIELD["shape"], "sizes": STANDING_SHIELD["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Hall of Spears",  # Owner-approved proposal (zones)
		"blurb": "Where the hall's champion has waited a thousand years",
		"ground": {"style": "hall_of_spears", "tile": "norse_slabs", "base": Color(0.17, 0.19, 0.24), "line": Color(0.10, 0.11, 0.15),
			"accent": Palette.NORSE_IRON, "trim": Palette.NORSE_RUNE},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1737,  # TUNING (not in GDD)
			"kinds": {
				"standing_shield": {"weight": 0.55, "shape": STANDING_SHIELD["shape"], "sizes": STANDING_SHIELD["sizes"]},  # TUNING (not in GDD)
				"long_table": {"weight": 0.45, "shape": LONG_TABLE["shape"], "sizes": LONG_TABLE["sizes"], "short": LONG_TABLE["short"]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Valkyries' Gate",  # Owner-approved proposal (zones)
		"blurb": "The hall's edge, open to the sky, where the Shield-Queen lands",
		"ground": {"style": "valkyries_gate", "tile": "norse_slabs", "base": Color(0.20, 0.22, 0.27), "line": Color(0.12, 0.13, 0.17),
			"accent": Palette.NORSE_FROST, "trim": Palette.NORSE_VALKYRIE_GOLD},
		"arena": {"density": 0.14, "clear_radius": 240.0, "layout_seed": 1747,  # TUNING (not in GDD) open ground for Sigrun's charges
			"kinds": {
				"standing_shield": {"weight": 0.7, "shape": STANDING_SHIELD["shape"], "sizes": STANDING_SHIELD["sizes"]},  # TUNING (not in GDD)
				"long_table": {"weight": 0.3, "shape": LONG_TABLE["shape"], "sizes": LONG_TABLE["sizes"], "short": LONG_TABLE["short"]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "VALGARD  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Palette.NORSE_VALKYRIE_GOLD,  # The hall's gold, never the UI's soul-teal.
	"fog_color": Color(0.06, 0.05, 0.04),  # The hall's dark rafters.
	"fog_bank_color": Color(0.55, 0.42, 0.28),  # Hearth smoke.
	"zones": ZONES,
}

## The Long Winter on this stage (keys of NorseRulesData.LONG_WINTER override
## its defaults): the braziers stand BY THE MAP (foundation note: the stub's
## seeded ring left the army bot in the cold 60-75% of the run, and the fight
## drifts thousands of px from the start). At the start ("points": offsets in
## px) the Mead Hall's long hearth burns either side of the necromancer (two
## fires 210 px out, the start just warm between them) with the two yard fires
## 470 px above and below; beyond them THE HALL'S HEARTHS repeat on a lattice
## (VALGARD "hearth_*", ValgardDirector, LongWinter.place()): about six in
## reach at any time, each a warm island ~900 px from the next. Warmth is a
## place to hold; the seers and giants come for it.
const LONG_WINTER := {
	"points": [Vector2(-210.0, 0.0), Vector2(210.0, 0.0), Vector2(0.0, -470.0), Vector2(0.0, 470.0)],  # TUNING (not in GDD) the long hearth, the yard fires
}
## The Rune-Stones on this stage: {} = the defaults of NorseRulesData.RUNE_STONES
## (every horn also wakes the Feast: ValgardDirector listens to horn_blown).
const RUNE_STONES := {}

## THE FEAST and the stage's objectives (ValgardDirector; StageRegistry
## "valgard"):
##   wake_reach      — px around the necromancer within which a horn wakes
##                     seated Einherjar (the nearest tables first).
##   wake_by_zone    — Einherjar a horn wakes at most, per zone (I..IV).
##   per_table       — Einherjar seated at a short / long table.
##   reseat_time     — s before an emptied table is full again.
##   cap_margin      — a wake skips while fewer than this many enemies are left
##                     under the hard cap.
##   rise_offset     — px from the table's centre (toward the necromancer) a
##                     woken Einherjar steps out.
##   seat_scan       — px around the necromancer the seated figures are drawn
##                     (drawing only).
##   doors_wake      — Einherjar the Doors of the Hall wake at the tables (on
##                     top of Sigrun's marching wave).
##   champion_objective — the HUD objective while the Champion stands.
##   hearth_spacing  — px between two of THE HALL'S HEARTHS (the Long Winter's
##                     braziers by the map: the hall's long hearths repeat down
##                     its length and across its bays, a lattice of this
##                     pitch; ValgardDirector lights each one as the
##                     necromancer comes near it, LongWinter.place()).
##   hearth_jitter   — px a hearth stands off its lattice point (seeded by the
##                     cell, the same in every run).
##   hearth_reach    — px around a necromancer within which the hearths of the
##                     lattice are lit.
##   hearth_min_gap  — px kept from every brazier already burning (the start's
##                     hearths of LONG_WINTER "points" included).
##   hearth_max      — lattice hearths lit at most in a run (the braziers are
##                     never removed; LongWinter draws every one).
const VALGARD := {
	"wake_reach": 640.0,  # TUNING (not in GDD) px
	"wake_by_zone": [2, 3, 2, 2],  # TUNING (not in GDD) the Mead Hall wakes the most (first pass 2 / 4 / 3 / 3)
	"per_table": [1, 2],  # TUNING (not in GDD) short / long table
	"reseat_time": 150.0,  # TUNING (not in GDD) s
	"cap_margin": 6,  # TUNING (not in GDD)
	"rise_offset": 22.0,  # TUNING (not in GDD) px
	"seat_scan": 900.0,  # TUNING (not in GDD) px, visual only
	"doors_wake": 6,  # TUNING (not in GDD)
	"champion_objective": "The Einherjar Champion: step out of his sweep. His horn wakes the hall",  # TUNING (not in GDD)
	"hearth_spacing": 900.0,  # TUNING (not in GDD) px: about six hearths in reach at a time (owner: "about 6 brazier structures")
	"hearth_jitter": 150.0,  # TUNING (not in GDD) px
	"hearth_reach": 1250.0,  # TUNING (not in GDD) px
	"hearth_min_gap": 420.0,  # TUNING (not in GDD) px
	"hearth_max": 40,  # TUNING (not in GDD) the seed-7 army bot lights ~30 in a run; a wandering naive bot 80
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): RAGNAROK,
## shared by every stage of the act: the wolf swallows the sun (a dark red
## sky), the Einherjar of the hall march at once, fire-giants step out of the
## south edge, every valkyrie dives at the ring ("ragnarok":
## NorseRulesData.RAGNAROK keys; {} = those defaults). Its waves' heavy is the
## fire-giant, with raiders, berserkers, wolves and a valkyrie.
const RECKONING := {
	"banner": "RAGNAROK: THE WOLF SWALLOWS THE SUN",
	"kind": NorseEnemyData.RECKONING_KIND,  # The shared Ragnarok heavy (the fire-giant).
	"ragnarok": {},  # NorseRulesData.RAGNAROK defaults.
	"companions": NorseEnemyData.RECKONING_COMPANIONS,  # Raiders, berserkers, wolves, a valkyrie.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) fire-giants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "RAGNAROK: the sun is gone, the hall's heroes march and the giants burn the field. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the
## warriors and valkyries of the hall lead (raiders, shield-maidens, skalds,
## berserkers, the hall's Einherjar; valkyries from 1:00), the draugr, wolves
## and giants of the wilds thinner than on the other two stages.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"raider": 1.0},
		"objective": "The Shield Yard: the hall's warriors come for you. Keep by the hearth fires"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"raider": 0.74, "shield_maiden": 0.22, "valkyrie": 0.04},
		"objective": "Shield-maidens! Their bash throws your dead out of the ring"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"raider": 0.62, "shield_maiden": 0.22, "skald": 0.04, "wolf_of_the_wastes": 0.08, "valkyrie": 0.04},
		"objective": "A rune-stone's horn wakes the heroes at the tables. Take the stones"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"raider": 0.5, "shield_maiden": 0.2, "skald": 0.05, "einherjar": 0.04, "draugr": 0.07, "seer": 0.04, "wolf_of_the_wastes": 0.06, "valkyrie": 0.04},
		"objective": "The Mead Hall: every horn wakes the Einherjar at the long tables"},
	{"start": 480.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"raider": 0.46, "shield_maiden": 0.2, "skald": 0.05, "einherjar": 0.05, "draugr": 0.07, "seer": 0.04, "wolf_of_the_wastes": 0.05, "berserker": 0.015, "valkyrie": 0.055},
		"objective": "Wounded warriors go berserk: finish them in one blow"},
	{"start": 720.0, "rate": 2.9, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"raider": 0.44, "shield_maiden": 0.2, "skald": 0.05, "einherjar": 0.055, "draugr": 0.06, "seer": 0.045, "wolf_of_the_wastes": 0.05, "berserker": 0.02, "valkyrie": 0.06, "frost_giant": 0.008},
		"objective": "Seers douse the hearths. Stand by a brazier to relight it"},
	{"start": 900.0, "rate": 3.1, "max_alive": 88,  # TUNING (not in GDD)
		"weights": {"raider": 0.42, "shield_maiden": 0.2, "skald": 0.05, "einherjar": 0.06, "draugr": 0.06, "seer": 0.05, "wolf_of_the_wastes": 0.05, "berserker": 0.025, "valkyrie": 0.065, "frost_giant": 0.01},
		"objective": "The Valkyries' Gate: the Shield-Queen's wing circles the sky"},
	{"start": BOSS_TIME, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"raider": 0.5, "shield_maiden": 0.2, "skald": 0.04, "einherjar": 0.04, "draugr": 0.06, "seer": 0.04, "wolf_of_the_wastes": 0.06, "berserker": 0.02, "valkyrie": 0.04},
		"objective": "Sigrun, the Shield-Queen has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the type
## "rune_stone": `count` stones rise around the necromancer, RuneStones
## .start_event(); and "einherjar_champion": ValgardDirector's miniboss, with an
## "escort" list of {kind, count}). Wolves come in packs of 5 (owner-approved
## proposal).
const EVENTS := [
	{"time": 25.0, "type": "wave", "banner": "A raiding party storms the Shield Yard!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "rune_stone", "count": 1, "banner": "A rune-stone rises! Its horn will wake the heroes at the tables"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 110.0, "type": "wave", "banner": "A shield line, and a skald to sing it on!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 180.0, "type": "wave", "banner": "A valkyrie! Bring her down with arrows and spells", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 250.0, "type": "rune_stone", "count": 1, "banner": "Another rune-stone is carved! Every horn wakes the Feast"},  # TUNING (not in GDD)
	{"time": 330.0, "type": "wave", "banner": "The Mead Hall: a berserker leaves his bench in the fury!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 1, "elite": false}, {"kind": "einherjar", "count": 2, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 430.0, "type": "wave", "banner": "Wolves of the wastes, loosed in the hall!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 500.0, "type": "rune_stone", "count": 1, "banner": "A seer carves a new stone!"},  # TUNING (not in GDD)
	{"time": 540.0, "type": "wave", "banner": "Two valkyries and the seers who call them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 2, "elite": false}, {"kind": "seer", "count": 2, "elite": false}, {"kind": "shield_maiden", "count": 3, "elite": false}]},
	{"time": 660.0, "type": "einherjar_champion", "banner": "THE EINHERJAR CHAMPION rises in the Hall of Spears! A thousand years of battle in his arm",  # TUNING (not in GDD) the miniboss
		"kind": "einherjar_champion", "escort": [{"kind": "einherjar", "count": 2}]},
	{"time": 760.0, "type": "rune_stone", "count": 1, "banner": "The last rune-stone rises!"},  # TUNING (not in GDD)
	{"time": 820.0, "type": "wave", "banner": "Berserkers, and a skald to drive them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 1, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},  # (first pass: two berserkers; berserkers were the seed-2 and seed-7 bots' worst foe)
	{"time": 910.0, "type": "wave", "banner": "The Valkyries' Gate: the wing circles before its queen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 2, "elite": false}, {"kind": "einherjar", "count": 3, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The war-host gathers before its queen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 10, "elite": false}, {"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "einherjar", "count": 2, "elite": false}]},  # (first pass: a frost giant; its stomps took the seed-7 army bot to 68 HP before Sigrun)
]

## Obstacle layout before the first zone change (the Shield Yard's).
const ARENA: Dictionary = ZONES[0]["arena"]

## Sigrun's arrival (keys as GraveyardStage.BOSS): her own SigrunData.ARRIVAL
## (boss id "sigrun"), whose `time` equals BOSS_TIME (17:00). Her script is
## scripts/enemies/norse/boss_sigrun.gd (loaded by her id).
const BOSS: Dictionary = SigrunData.ARRIVAL

## The foundation stub's floor (NorseGround "floor" key), kept for the tools
## that read it; the stage draws ValgardGround ("ground").
const FLOOR := {
	"style": "hall",  # The feast hall's broad planks, rushes and hearth embers.
	"base": Color(0.24, 0.16, 0.10),  # TUNING (not in GDD)
	"line": Color(0.17, 0.11, 0.07),  # TUNING (not in GDD)
	"accent": Palette.NORSE_HEARTH_DARK,  # TUNING (not in GDD)
	"trim": Palette.NORSE_HEARTH,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Valgard, the Hall of Heroes",
	"short_name": "Valgard",
	"chapter": "Chapter XVII",
	"act": 11,  # The Hall of the Slain: TEMPORARY act number 11 (final slot VI; the reorder pass renumbers it).
	"playable": true,  # Opened at the Hall of the Slain integration (GDD §15.0 "Hall of the Slain integration").
	"description": "A vast feast hall at the edge of the sky, long tables and shields on the walls. The benches stood empty since you took the world's dead; now the hall's own heroes rise from them.",
	"unlock": {"stage": "barrow_fields", "boss_kills": 1},
	"unlock_text": "Defeat Hrimgar the Draugr-King in the Barrow Fields to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on the act's stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "valgard",  # ValgardGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"norse": true,  # The Hall of the Slain: the Long Winter, Berserkergang, the Rune-Stones (NorseRules).
	"long_winter": LONG_WINTER,  # This stage's Long Winter: the braziers by the map.
	"rune_stones": RUNE_STONES,  # This stage's Rune-Stone overrides ({} = the defaults).
	"zones": ZONES,  # The four zones.
	"valgard": VALGARD,  # ValgardDirector: the Feast, the Einherjar Champion.
	"music": "valhall",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
