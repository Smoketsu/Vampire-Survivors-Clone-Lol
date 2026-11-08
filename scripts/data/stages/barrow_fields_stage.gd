## BarrowFieldsStage — STAGE 16 (final order), THE BARROW FIELDS (the Hall of the
## Slain, temporarily Act XI, final slot VI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)" and "The Barrow Fields (the Hall of the Slain phase
## 2)"; the act's section "Stage 16: The Barrow Fields" of
## docs/proposals/LAST_SIX_ACTS.md, docs/norse/BRIEF_PHASE2.md "Agent A").
## Snowfields of burial mounds above a frozen fjord. The barrows are cracking
## open: the hall's dead walk south, and the living march with them to fill its
## empty benches.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: PLAYABLE (phase 2, opened at the act's integration). It runs the act's
## three shared rules ("norse": true: the Long Winter, Berserkergang and the
## Rune-Stones) with the draugr leading the timeline (male and female, the
## brief: "The draugr lead the timeline"), the living warriors of the hall
## beside them, and its own systems (BarrowFieldsDirector, STAGE
## "barrow_fields"): the braziers placed by the map (the Longshore's here in
## LONG_WINTER "points", each later zone's in BARROW_FIELDS "braziers"), THE
## OPEN BARROWS ("barrow" events: mounds that crack open on a 2 s telegraph and
## let draugr out until broken), the Frozen Fjord's drifts of deep snow
## (TerrainSlow), KEEP THE FIRES (the stage's achievement) and the
## Barrow-Wight (the miniboss, at 10:30). Its boss is Hrimgar the Draugr-King
## (BossHrimgar: the Grave, the Barrow Lord, the Last Rising; he rises three
## times unless his barrow is broken while he is down). Ragnarok is its
## Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Longshore, the Barrows, the
## Frozen Fjord, the Jarl's Hall.
## The boss arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD), tuned for the act's final
## slot VI (between the Shogunate and Olympus).
## CHAIN: the act opens after the Black Tide's last boss (Vandermere, stage `maelstrom`; set at the wave 1 integration).
class_name BarrowFieldsStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "barrow_fields"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (final slot VI: a hair above the Shogunate's 1.55 / 1.6 / 1.65; the step
## between the stages goes in HP, the Act IV lesson).
const ENEMY_HP_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Enemy damage multiplier of this stage on top of the shared time scaling
## (between Olympus's 1.3 and the Shogunate's 1.5).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00, as Acts III to IX
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of the act

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## BarrowFieldsGround style, the zone's floor tile tiles/norse_<style>) and its
## obstacle layout ("arena": the art pass's snowy pines, burial mounds, and in
## the Jarl's Hall long tables and standing shields):
##   longshore    — the Longshore: snow down to the fjord's shore, pines.
##   barrows      — the Barrows: a field of burial mounds (the open barrows
##                  crack among them).
##   frozen_fjord — the Frozen Fjord: open ice and drifts of deep snow
##                  (BARROW_FIELDS "drifts").
##   jarls_hall   — the Jarl's Hall: the draugr-king's yard and hall, long
##                  tables and shields on posts, two rows of hearths.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Longshore", "id": "longshore",  # Owner-approved proposal (zones)
		"blurb": "Snow down to the fjord, where the raiders land",
		"ground": {"style": "snow", "base": Palette.NORSE_FROST_SHADE, "line": Palette.NORSE_FROST,
			"accent": Palette.NORSE_PINE_LIGHT, "trim": Palette.NORSE_RUNE},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 1616,  # TUNING (not in GDD)
			"kinds": {
				"snow_pine": {"weight": 0.55, "shape": "circle", "sizes": [8.0, 11.0]},  # TUNING (not in GDD) art obstacles/snow_pine_s / _l
				"mound": {"weight": 0.45, "shape": "circle", "sizes": [12.0, 17.0]},  # TUNING (not in GDD) art obstacles/mound_s / _l
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Barrows", "id": "barrows",  # Owner-approved proposal (zones)
		"blurb": "A field of burial mounds, and the mounds are opening",
		"ground": {"style": "snow", "base": Palette.NORSE_FROST_SHADE, "line": Palette.NORSE_FROST,
			"accent": Palette.NORSE_DRAUGR, "trim": Palette.NORSE_RUNE},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 1626,  # TUNING (not in GDD)
			"kinds": {
				"mound": {"weight": 0.7, "shape": "circle", "sizes": [12.0, 17.0]},  # TUNING (not in GDD)
				"snow_pine": {"weight": 0.3, "shape": "circle", "sizes": [8.0, 11.0]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Frozen Fjord", "id": "frozen_fjord",  # Owner-approved proposal (zones)
		"blurb": "Open ice and deep snow that slows every foot",
		"ground": {"style": "ice", "base": Palette.NORSE_DRAUGR_LIGHT, "line": Palette.NORSE_FROST,
			"accent": Palette.NORSE_FROST, "trim": Palette.NORSE_DRAUGR_DARK},
		"arena": {"density": 0.08, "clear_radius": 220.0, "layout_seed": 1636,  # TUNING (not in GDD)
			"kinds": {
				"snow_pine": {"weight": 0.6, "shape": "circle", "sizes": [8.0, 11.0]},  # TUNING (not in GDD) the banks' pines
				"mound": {"weight": 0.4, "shape": "circle", "sizes": [12.0, 17.0]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Jarl's Hall", "id": "jarls_hall",  # Owner-approved proposal (zones)
		"blurb": "The draugr-king's hall, its hearths still burning",
		"ground": {"style": "snow", "base": Palette.NORSE_FROST_SHADE, "line": Palette.NORSE_FROST,
			"accent": Palette.NORSE_IRON, "trim": Palette.NORSE_HEARTH_DARK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1646,  # TUNING (not in GDD)
			"kinds": {
				"long_table": {"weight": 0.4, "shape": "rect", "sizes": [46.0, 70.0], "short": 14.0},  # TUNING (not in GDD) art obstacles/long_table_s / _l (+ _v)
				"standing_shield": {"weight": 0.35, "shape": "circle", "sizes": [9.0, 13.0]},  # TUNING (not in GDD) art obstacles/standing_shield_s / _l
				"mound": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 17.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE BARROW FIELDS  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Palette.NORSE_RUNE,  # The act's ice-blue rune glow (never the UI's soul-teal).
	"fog_color": Color(0.82, 0.88, 0.94),  # Snow haze.
	"fog_bank_color": Color(0.66, 0.74, 0.82),  # Banks of blowing snow.
	"zones": ZONES,
}

## The Long Winter on this stage (any key of NorseRulesData.LONG_WINTER):
## "points": the Longshore's five braziers (offsets px from the start), a loose
## ring just beyond the start's clear circle, ~360 px apart, so their warmth
## overlaps along the ring and the start itself is cold (the foundation's note:
## braziers by the map, contested, never out of reach). The later zones' sets
## are BARROW_FIELDS "braziers".
const LONG_WINTER := {
	"points": [Vector2(0.0, -300.0), Vector2(323.0, -105.0), Vector2(176.0, 243.0), Vector2(-200.0, 275.0), Vector2(-285.0, -93.0)],  # TUNING (not in GDD)
	"douse_time": 2.0,  # TUNING (not in GDD) the act's first stage: a longer gutter (the shared 1.2 s), time for the ring to cut the douser down
}
## The Rune-Stones on this stage: {} = the defaults of NorseRulesData.RUNE_STONES.
const RUNE_STONES := {}

## The Barrow Fields' stage systems (BarrowFieldsDirector; StageRegistry
## "barrow_fields"):
##   braziers       — zone id -> the braziers placed at that zone's change
##                    (offsets px from where the necromancer stands then;
##                    LongWinter.place()).
##   retire_dist    — px: at a zone change the braziers farther than this from
##                    the necromancer are retired (LongWinter.retire_far()).
##   barrow_cap     — most open barrows standing at once (over it none cracks).
##   brazier_reach  — px: an event's barrows crack beside the lit braziers
##                    within this of the necromancer (warmth is contested).
##   brazier_side   — px from a brazier its barrow cracks.
##   ring_dist      — px from the necromancer a barrow cracks with no brazier
##                    near.
##   drifts         — the Frozen Fjord's deep snow: zone (id), count, dist_min /
##                    dist_max (px from the necromancer), radius_min /
##                    radius_max (px), slow (share), tick (s).
##   wight_objective — HUD objective while the Barrow-Wight stands.
##   keep_the_fires_banner — banner when Keep the Fires is earned.
const BARROW_FIELDS := {
	"braziers": {
		"barrows": [Vector2(198.0, 198.0), Vector2(-198.0, 198.0), Vector2(-198.0, -198.0), Vector2(198.0, -198.0)],  # TUNING (not in GDD) four braziers among the mounds
		"frozen_fjord": [Vector2(320.0, 0.0), Vector2(0.0, 320.0), Vector2(-320.0, 0.0), Vector2(0.0, -320.0)],  # TUNING (not in GDD) fires on the fjord's banks
		"jarls_hall": [Vector2(-300.0, -140.0), Vector2(0.0, -140.0), Vector2(300.0, -140.0), Vector2(-300.0, 140.0), Vector2(0.0, 140.0), Vector2(300.0, 140.0)],  # TUNING (not in GDD) the hall's two rows of hearths
	},
	"retire_dist": 650.0,  # TUNING (not in GDD) px: the fires far behind are retired at a zone change, the near ones kept (900 retired none: 19 piled up; 0 retired all and the seed-7 army bot spent 543 s cold, frostbite x9)
	"barrow_cap": 6,  # TUNING (not in GDD)
	"brazier_reach": 700.0,  # TUNING (not in GDD) px
	"brazier_side": 90.0,  # TUNING (not in GDD) px
	"ring_dist": 260.0,  # TUNING (not in GDD) px
	"drifts": {"zone": "frozen_fjord", "count": 7, "dist_min": 180.0, "dist_max": 650.0,  # TUNING (not in GDD)
		"radius_min": 60.0, "radius_max": 110.0, "slow": 0.3, "tick": 0.5},  # TUNING (not in GDD) the proposal: "snow slows everyone"
	"wight_objective": "Bring down the Barrow-Wight: keep your ring apart when he throws back his head",  # TUNING (not in GDD)
	"keep_the_fires_banner": "KEEP THE FIRES: no brazier went cold for long. The winter did not take your dead!",  # TUNING (not in GDD)
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
	"ragnarok": {},  # NorseRulesData.RAGNAROK defaults (phase 2 may tune them here).
	"companions": NorseEnemyData.RECKONING_COMPANIONS,  # Raiders, berserkers, wolves, a valkyrie.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) fire-giants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "RAGNAROK: the sun is gone, the hall's heroes march and the giants burn the field. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the draugr
## lead (male and female, about 45% of the weight from 2:30; the brief), the
## living warriors of the hall beside them; berserkers, valkyries and giants
## stay rare (elites and heavies).
const SEGMENTS := [
	# Zone I, the Longshore.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"raider": 0.6, "draugr": 0.2, "draugr_female": 0.2},
		"objective": "The Longshore: raiders come up from the fjord. Keep near the braziers: the cold is coming"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"raider": 0.46, "shield_maiden": 0.14, "draugr": 0.2, "draugr_female": 0.2},
		"objective": "Shield-maidens! Their bash throws your dead out of the ring"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"raider": 0.34, "shield_maiden": 0.14, "draugr": 0.24, "draugr_female": 0.22, "wolf_of_the_wastes": 0.06},
		"objective": "Draugr from the barrows: armoured, and their touch is cold"},
	# Zone II, the Barrows (5:00).
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"raider": 0.28, "shield_maiden": 0.13, "draugr": 0.24, "draugr_female": 0.22, "wolf_of_the_wastes": 0.07, "skald": 0.03, "seer": 0.03},
		"objective": "The Barrows: the mounds crack open. Break them, or the draugr never stop"},
	{"start": 480.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"raider": 0.26, "shield_maiden": 0.13, "draugr": 0.24, "draugr_female": 0.22, "wolf_of_the_wastes": 0.07, "skald": 0.03, "seer": 0.03, "berserker": 0.012, "valkyrie": 0.008},
		"objective": "Wounded warriors go berserk: finish them in one blow"},
	# Zone III, the Frozen Fjord (10:00): the Barrow-Wight at 10:30.
	{"start": 600.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"raider": 0.25, "shield_maiden": 0.13, "draugr": 0.24, "draugr_female": 0.22, "wolf_of_the_wastes": 0.07, "skald": 0.03, "seer": 0.03, "berserker": 0.015, "valkyrie": 0.01, "frost_giant": 0.005},
		"objective": "The Frozen Fjord: the deep snow slows every foot. Frost giants douse the braziers they pass"},
	# Zone IV, the Jarl's Hall (15:00).
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"raider": 0.24, "shield_maiden": 0.13, "draugr": 0.24, "draugr_female": 0.22, "wolf_of_the_wastes": 0.07, "skald": 0.03, "seer": 0.035, "berserker": 0.018, "valkyrie": 0.01, "frost_giant": 0.008},
		"objective": "The Jarl's Hall: keep its hearths burning, and the barrow-dead out of them"},
	# 17:00, the boss: thinner, so the fight is the king.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"raider": 0.32, "shield_maiden": 0.13, "draugr": 0.2, "draugr_female": 0.2, "wolf_of_the_wastes": 0.07, "skald": 0.03, "seer": 0.03, "berserker": 0.01, "valkyrie": 0.01},
		"objective": "Hrimgar the Draugr-King has come for you. Break his barrow while he lies in it"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the type
## "rune_stone": `count` stones rise around the necromancer, RuneStones
## .start_event(), and the Barrow Fields' own (BarrowFieldsDirector):
##   "barrow" — `count` open barrows crack beside the lit braziers nearest the
##              necromancer (else on a ring around him).
##   "wight"  — the Barrow-Wight (kind `kind`) walks in from the spawn ring with
##              an `escort` (groups of {kind, count}); the stage miniboss.
## Wolves come in packs of 5 (owner-approved proposal).
const EVENTS := [
	# Zone I: the Longshore.
	{"time": 25.0, "type": "wave", "banner": "A raiding party comes up from the shore!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "rune_stone", "count": 1, "banner": "A rune-stone rises! Stand by it with your army to take it"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 100.0, "type": "barrow", "count": 1, "banner": "A barrow cracks open by the fire! Break it before the draugr pour out"},  # TUNING (not in GDD) the open barrows
	{"time": 130.0, "type": "wave", "banner": "Wolves of the wastes, hunting in packs!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "A shield line, and a skald to sing it on!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 260.0, "type": "rune_stone", "count": 1, "banner": "Another rune-stone is carved! Its horn will call the hall"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	# Zone II: the Barrows.
	{"time": 310.0, "type": "barrow", "count": 2, "banner": "The Barrows: two mounds crack open beside the fires!"},  # TUNING (not in GDD)
	{"time": 340.0, "type": "wave", "banner": "A berserker! Wound him and he is already in the fury", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 390.0, "type": "barrow", "count": 2, "banner": "More barrows open! The dead climb toward your fires"},  # TUNING (not in GDD)
	{"time": 430.0, "type": "wave", "banner": "A valkyrie! Bring her down with arrows and spells", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "draugr", "count": 3, "elite": false}, {"kind": "draugr_female", "count": 3, "elite": false}]},
	{"time": 480.0, "type": "barrow", "count": 2, "banner": "The mounds keep opening!"},  # TUNING (not in GDD)
	{"time": 520.0, "type": "rune_stone", "count": 1, "banner": "A seer carves a new stone!"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 545.0, "type": "wave", "banner": "Seers walk to the stones you took, and to your fires!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "seer", "count": 2, "elite": false}, {"kind": "shield_maiden", "count": 3, "elite": false}]},
	# Zone III: the Frozen Fjord.
	{"time": 610.0, "type": "wave", "banner": "A frost giant strides across the ice!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "draugr", "count": 3, "elite": false}, {"kind": "draugr_female", "count": 3, "elite": false}]},
	{"time": 630.0, "type": "wight", "banner": "THE BARROW-WIGHT! When he throws back his head, his howl stuns your whole ring!",  # Brief (miniboss); 9:30 left
		"kind": "barrow_wight", "elite": false,
		"escort": [{"kind": "draugr", "count": 5}, {"kind": "draugr_female", "count": 5}]},  # TUNING (not in GDD)
	{"time": 710.0, "type": "wave", "banner": "Two valkyries circle the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 2, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 760.0, "type": "barrow", "count": 2, "banner": "Barrows crack open on the fjord's banks!"},  # TUNING (not in GDD)
	{"time": 780.0, "type": "rune_stone", "count": 1, "banner": "The last rune-stone rises!"},  # TUNING (not in GDD) rule 3: a stone the hall holds
	{"time": 840.0, "type": "wave", "banner": "Berserkers, and a skald to drive them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 2, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	# Zone IV: the Jarl's Hall.
	{"time": 910.0, "type": "barrow", "count": 3, "banner": "The Jarl's Hall: its dead wake beside the hearths!"},  # TUNING (not in GDD)
	{"time": 940.0, "type": "wave", "banner": "Giants and wolves together!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The barrow-host gathers before its king!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "draugr", "count": 6, "elite": false}, {"kind": "draugr_female", "count": 6, "elite": false}, {"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "berserker", "count": 1, "elite": false}]},
]

## The stage boss's arrival (keys as GraveyardStage.BOSS): Hrimgar's own
## HrimgarData.ARRIVAL (boss id "hrimgar"), whose `time` equals BOSS_TIME
## (17:00). His script is scripts/enemies/norse/boss_hrimgar.gd (loaded by his id).
const BOSS: Dictionary = HrimgarData.ARRIVAL

## Placeholder floor of the foundation stub (NorseGround "floor" key), kept for
## the tools that read it; the stage draws BarrowFieldsGround ("ground").
const FLOOR := {
	"style": "snow",  # Snowfields between the barrows, drifts and dead grass, frozen puddles.
	"base": Palette.NORSE_FROST_SHADE,  # TUNING (not in GDD)
	"line": Palette.NORSE_FROST,  # TUNING (not in GDD)
	"accent": Palette.NORSE_PINE_LIGHT,  # TUNING (not in GDD)
	"trim": Palette.NORSE_RUNE,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Barrow Fields",
	"short_name": "Barrow Fields",
	"chapter": "Chapter XVI",
	"act": 11,  # The Hall of the Slain: TEMPORARY act number 11 (final slot VI; the reorder pass renumbers it).
	"playable": true,  # Opened at the Hall of the Slain integration (GDD §15.0 "Hall of the Slain integration").
	"description": "Snowfields of burial mounds above a frozen fjord. The barrows are cracking open: the hall's dead walk south, and the living march with them to fill its empty benches.",
	"unlock": {"stage": "maelstrom", "boss_kills": 1},  # Wave 1 integration: the chain runs ... -> Vandermere -> Hrimgar
	"unlock_text": "Defeat Captain Vandermere in the Maelstrom to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on the act's stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "barrow_fields",  # BarrowFieldsGround: the zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"barrow_fields": BARROW_FIELDS,  # BarrowFieldsDirector: the braziers by the map, the open barrows, the drifts, Keep the Fires, the Barrow-Wight.
	"norse": true,  # The Hall of the Slain: the Long Winter, Berserkergang, the Rune-Stones (NorseRules).
	"long_winter": LONG_WINTER,  # This stage's Long Winter overrides ({} = the defaults).
	"rune_stones": RUNE_STONES,  # This stage's Rune-Stone overrides ({} = the defaults).
	"zones": ZONES,  # The four zones.
	# Music: "Horns at the Last Feast" (SoundData.VALHALL_SCORE).
	"music": "valhall",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
