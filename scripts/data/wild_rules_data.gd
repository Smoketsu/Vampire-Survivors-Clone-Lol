## WildRulesData — the numbers of THE TURNING YEAR's shared rules (temporary
## Act XV, final slot XV, the campaign finale and the hardest act; GDD §15.0
## "The Turning Year foundation (phase 1)", "The Turning Year (seasons)",
## "Bloom and Blight", "Overgrowth" and "Spring Returns"; design
## docs/proposals/LAST_SIX_ACTS.md section XV, plan docs/last_acts/PLAN.md).
## Read by WildRules (Game.wild) and its parts:
##   SEASONS        — the 20:00 clock is one year of four seasons (SeasonCycle):
##     ROOTS        — Spring: roots grab whatever stands still 2 s, 1.5 s;
##     WILDFIRE     — Summer: wildfires sweep on telegraphed fronts, both armies;
##     AUTUMN       — Autumn: corpses rot in 3 s, the blight spreads;
##     WINTER       — Winter: snow slows everyone 20%, blizzards cut sight;
##   BLOOM          — the living ground: the army's ground dies into blight, the
##                    Wild heals on living ground only (BloomField);
##   THICKETS       — dryads' seeds grow into thorn thickets, new obstacles that
##                    hold a summon caught in them; fire and blight burn them
##                    back (Thickets);
##   SPRING_RETURNS — the Reckoning: everything grows back at once and buries
##                    the dead (SpringReturns).
## A stage's STAGE "seasons" / "bloom" / "thickets" dictionaries override any
## key of SEASONS / BLOOM / THICKETS; its RECKONING "spring_returns" overrides
## SPRING_RETURNS. Data only, no logic. Every value is TUNING (not in GDD)
## unless it is marked as the owner-approved proposal. Tuned for the act's
## FINAL slot XV (the hardest act of the game), not its temporary number.
class_name WildRulesData
extends RefCounted

## Faction id of the Turning Year's kinds (row "faction").
const FACTION: String = "wild"
## The roster's groups in order (row "group"; the Codex and the report group
## by them): what grows (thornlings, dryads, treants, corpse-blooms), the fae
## (knights, the Winter Court), the Wild Hunt (the stag, the riders), the
## spirits (wisps, spore mothers). Phase 2 adds its stage kinds to these groups.
const GROUPS: Array[String] = ["growth", "fae", "hunt", "spirits"]

# --- The Turning Year (SeasonCycle; one season path) ---------------------------------------
## Season index of Spring (SeasonCycle.season()).
const SPRING: int = 0
## Season index of Summer.
const SUMMER: int = 1
## Season index of Autumn.
const AUTUMN: int = 2
## Season index of Winter.
const WINTER: int = 3
## Season index of Spring Returns (the Reckoning, after 0:00).
const RETURNS: int = 4
## Season ids by index (the rows' "season" key, a segment's "season_weights" keys, the report).
const SEASON_IDS: Array[String] = ["spring", "summer", "autumn", "winter", "spring_returns"]
## Season names by index (banners, the HUD wheel's line).
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter", "Spring Returns"]
## Banner shown when each season begins (index as SEASON_IDS).
const SEASON_BANNERS: Array[String] = [
	"SPRING: the roots wake. Do not stand still.",  # TUNING (not in GDD)
	"SUMMER: the grass is dry. Wildfires sweep the wood.",  # TUNING (not in GDD)
	"AUTUMN: the leaves fall and the dead rot fast. Raise them quickly.",  # TUNING (not in GDD)
	"WINTER: snow slows every step, and the blizzards come.",  # TUNING (not in GDD)
	"SPRING RETURNS: everything grows back at once and buries the dead.",  # TUNING (not in GDD)
]
## Ground tint of each season (index as SEASON_IDS; drawing only: the season
## repaints the arena, Game.ground.modulate).
const SEASON_TINTS: Array[Color] = [
	Color(1.0, 1.04, 0.96),  # TUNING (not in GDD) spring: fresh green
	Color(1.08, 1.02, 0.86),  # TUNING (not in GDD) summer: dry gold grass
	Color(1.1, 0.88, 0.74),  # TUNING (not in GDD) autumn: fallen leaves
	Color(1.2, 1.24, 1.32),  # TUNING (not in GDD) winter: frost white
	Color(0.96, 1.1, 0.94),  # TUNING (not in GDD) spring returns: everything green at once
]
## The year (a stage's STAGE "seasons" overrides any key).
const SEASONS := {
	"length": 300.0,  # Owner-approved proposal: "four seasons of 5 minutes" (the World-Tree: "twice as fast", 150)
	# Optional key a stage may add (absent here): "wildfire_every", s between two
	# wildfire fronts in place of WILDFIRE "every" (the Fae Court's endless summer
	# spaces its fronts out).
}

## SPRING — the roots (owner-approved proposal: "roots grab anything that
## stands still for 2 s and hold it 1.5 s"), both armies.
const ROOTS := {
	"sample": 0.5,  # TUNING (not in GDD) s between two stillness checks
	"still_time": 2.0,  # Owner-approved proposal: "stands still for 2 s"
	"still_px": 8.0,  # TUNING (not in GDD) px a body may drift and still count as standing still
	"hold": 1.5,  # Owner-approved proposal: "and hold it 1.5 s"
	"warn": 0.6,  # TUNING (not in GDD) drawing only: s the roots show before they grab
	"player_slow": 0.85,  # TUNING (not in GDD) 0..1: the necromancer is not held but slowed (Grave Step breaks free), through TerrainSlow
	"enemy_slow": 0.9,  # TUNING (not in GDD) 0..1 an enemy's slow while held (Enemy.apply_slow(); no boss, miniboss, structure or flier)
}
## SUMMER — the wildfires (owner-approved proposal: "wildfires sweep the dry
## grass on telegraphed fronts and burn both armies").
const WILDFIRE := {
	"first": 10.0,  # TUNING (not in GDD) s into Summer of the first front
	"every": 24.0,  # TUNING (not in GDD) s between two fronts
	"lead": 2.0,  # TUNING (not in GDD) s the smoke line shows where the fire will be (the telegraph)
	"spawn_dist": 620.0,  # TUNING (not in GDD) px from a standing necromancer the front starts, heading through him
	"width": 520.0,  # TUNING (not in GDD) px, the front's width
	"depth": 44.0,  # TUNING (not in GDD) px, the front's depth (a body this close to its line burns)
	"speed": 160.0,  # TUNING (not in GDD) px/s the front runs
	"length": 1300.0,  # TUNING (not in GDD) px the front runs before it burns out
	"burn_summon": 10.0,  # TUNING (not in GDD) per summon, before the time scaling
	"burn_player": 7.0,  # TUNING (not in GDD) before the time scaling (Grave Step's i-frames dodge it)
	"burn_enemy_share": 0.35,  # TUNING (not in GDD) share of an enemy's max HP (bosses, minibosses, structures spared)
}
## Damage source tag of a wildfire front.
const WILDFIRE_SOURCE: String = "wild_wildfire"

## AUTUMN — the rot (owner-approved proposal: "leaves hide the ground; corpses
## rot in 3 s, so raise fast"; the leaves are the ground's tint).
const AUTUMN_RULES := {
	"corpse_life": 3.0,  # Owner-approved proposal: "corpses rot in 3 s" (AbilityData.CORPSE_LIFE in every other season)
}

## WINTER — the snow and the blizzards (owner-approved proposal: "snow slows
## everyone 20%; blizzards cut sight to 400 px").
const WINTER_RULES := {
	"snow_slow": 0.2,  # Owner-approved proposal: "snow slows everyone 20%" (TerrainSlow for the necromancer and summons, Enemy.apply_slow() for enemies)
	"snow_every": 0.5,  # TUNING (not in GDD) s between two snow refreshes
	"blizzard_first": 30.0,  # TUNING (not in GDD) s into Winter of the first blizzard
	"blizzard_every": 70.0,  # TUNING (not in GDD) s between two blizzards' starts
	"blizzard_time": 18.0,  # TUNING (not in GDD) s a blizzard lasts
	"sight": 400.0,  # Owner-approved proposal: "blizzards cut sight to 400 px" (drawing only in phase 1)
}

# --- Bloom and Blight (BloomField; one ground path) ----------------------------------------
## The living ground (a stage's STAGE "bloom" overrides any key).
const BLOOM := {
	"cell": 64.0,  # TUNING (not in GDD) px, one blight cell (a coarse grid)
	"sample": 0.5,  # TUNING (not in GDD) s between two updates
	"rise_player": 0.12,  # TUNING (not in GDD) blight a second where the necromancer stands (0..1 per cell; full in ~8 s)
	"rise_army": 0.1,  # TUNING (not in GDD) blight a second where at least one summon stands
	"regrow": 0.02,  # TUNING (not in GDD) blight lost a second everywhere (50 s from full to living)
	"spring_regrow_mult": 3.0,  # Owner-approved proposal: "Spring regrows blight quickly"
	"autumn_regrow_mult": 0.0,  # Owner-approved proposal: "Autumn spreads it" (no regrowth, and the spread below)
	"autumn_spread": 0.02,  # TUNING (not in GDD) blight a second a full cell gives each of its 4 neighbours in Autumn
	"full": 0.8,  # TUNING (not in GDD) a cell this blighted is dead ground (no heal, thickets wither, Autumn spreads)
	"living": 0.4,  # TUNING (not in GDD) a cell under this is living ground (the Wild heals there)
	"heal": 0.01,  # Owner-approved proposal: "the Wild's creatures heal on living ground"; TUNING (not in GDD) share of max HP a second (first try 0.02: a naive army never killed a Treant on the World-Tree, seed 7)
	"max_cells": 900,  # TUNING (not in GDD) most blighted cells kept (the oldest regrow first)
}

# --- Overgrowth (Thickets; one obstacle path) ----------------------------------------------
## The thorn thickets (a stage's STAGE "thickets" overrides any key).
const THICKETS := {
	"grow": 4.0,  # TUNING (not in GDD) s a seed takes to grow into a thicket (the sprout shows meanwhile)
	"radius": 26.0,  # TUNING (not in GDD) px, a thicket's collision circle (under ArenaData.MAX_HALF_EXTENT)
	"cap": 30,  # TUNING (not in GDD) thickets standing at most
	"spread_every": 45.0,  # Owner-approved proposal: "spread through the run"; TUNING (not in GDD) s between two spreads of one thicket
	"player_clear": 110.0,  # TUNING (not in GDD) px: no thicket grows this close to a standing necromancer (the seed waits)
	"seed_wait": 12.0,  # TUNING (not in GDD) s a waiting seed lives before it dies
	"hold_reach": 6.0,  # TUNING (not in GDD) px beyond the thicket's edge a summon is caught
	"hold": 1.0,  # Owner-approved proposal: "hold a summon caught in them"; TUNING (not in GDD) s
	"regrab": 1.5,  # TUNING (not in GDD) s a released summon walks free before the thorns catch it again
	"check": 0.25,  # TUNING (not in GDD) s between two catch checks
	"wither": 6.0,  # TUNING (not in GDD) s on dead ground (BLOOM "full") before a thicket withers away
}
## Obstacle kind of a thorn thicket (Arena; drawn by WildGlyphs until the art).
const THICKET_KIND: String = "wild_thicket"
## Phase 2 (the Greenwood): px round a rotting enemy within which its Rot burns
## the thorn thickets back (CombatResolver.rot_enemy() -> Thickets.burn_at()).
## The fires use their own reach (a Hellhound patch, a Brimstone pit, a Meteor
## Call strike, the Wither aura).
const BURN_ROT_REACH: float = 24.0  # Owner-approved proposal: "Fire, Rot and Wither burn them back"; TUNING (not in GDD) px

# --- Spring Returns (the Reckoning) ---------------------------------------------------------
## Spring Returns (a stage's RECKONING "spring_returns" overrides any key):
## from 0:00 the blight is gone at once, thickets sprout round the
## necromancer, the roots grab twice as fast, the dead rot at once and the
## earth buries summons.
const SPRING_RETURNS := {
	"first": 3.0,  # TUNING (not in GDD) s after 0:00
	"sprout_every": 6.0,  # TUNING (not in GDD) s between two sproutings
	"sprouts": 3,  # TUNING (not in GDD) seeds round each standing necromancer each time
	"sprout_ring": 220.0,  # TUNING (not in GDD) px from him (outside the Bone Ring's 60-150 px)
	"sprout_grow": 1.5,  # TUNING (not in GDD) s those seeds take to grow
	"still_time": 1.0,  # TUNING (not in GDD) s of stillness before the roots grab (Spring's 2 s halved)
	"corpse_life": 0.5,  # TUNING (not in GDD) s: the dead are buried at once
	"bury_every": 9.0,  # Owner-approved proposal: "buries the dead"; TUNING (not in GDD) s between two burials
	"bury": 3,  # TUNING (not in GDD) summons the earth pulls down each time (seeded)
	"bury_summon": 40.0,  # TUNING (not in GDD) damage to each, before the time scaling
	"bury_hold": 2.0,  # TUNING (not in GDD) s each is held
}
## Damage source tag of a burial.
const BURY_SOURCE: String = "wild_burial"

## Sound of each Turning Year event: each is an id of the lazy "wild" pack (SoundData.WILD_SOUNDS, rendered with the score
## "wildwood"; the comment names what it sounds like).
const SOUNDS := {
	"season_turn": "season_turn",  # Wild pack id "season_turn" (a bell of wood and wind; the year turns).
	"roots_grab": "roots_grab",  # Wild pack id "roots_grab" (roots cracking up through soil, a creak).
	"wildfire_warn": "wildfire_warn",  # Wild pack id "wildfire_warn" (a rising crackle, a gust of smoke).
	"wildfire_burn": "wildfire_burn",  # Wild pack id "wildfire_burn" (a roar of dry grass catching).
	"blizzard": "blizzard",  # Wild pack id "blizzard" (a howling white wind).
	"thicket_grow": "thicket_grow",  # Wild pack id "thicket_grow" (thorns snaking up, a woody snap).
	"thicket_burn": "thicket_burn",  # Wild pack id "thicket_burn" (thorns crackling to ash).
	"bury": "bury",  # Wild pack id "bury" (earth closing, a deep thud).
	"spring_returns": "spring_horn",  # Wild pack id "spring_horn" (every bird and leaf at once, a vast green chord).
	# --- Act XV (temporary number): the Greenwood ---
	"hunt_charge": "roots_grab",  # Wild pack id "roots_grab" (turf torn up under hooves, a creak): a Wild Hunt charge or sweep begins.
	"hunt_horn": "spring_horn",  # Wild pack id "spring_horn" (a vast horn call): the Stag King and the Huntsman sound the Hunt.
	"grove_dies": "bury",  # Wild pack id "bury" (earth closing, a deep thud): a sacred grove dies.
	"crown_grows": "thicket_grow",  # Wild pack id "thicket_grow" (thorns snaking up): the Antler Crown grows round the Stag King.
	"crown_breaks": "thicket_burn",  # Wild pack id "thicket_burn" (thorns crackling to ash): the Antler Crown falls.
	"blink": "season_turn",  # Wild pack id "season_turn" (a bell of wood and wind): a Fae Knight blinks.
}

# --- The counter-passives (phase 2 builds them; WildRules' hooks read them) -----------------
## Passive id of Deadwood (proposal: "roots and thickets hold summons half as long"; this act only).
const DEADWOOD: String = "deadwood"
## Deadwood's value key: the share of a root / thicket hold on a summon it takes off (0..1; 0.5 at Lv 5).
const DEADWOOD_KEY: String = "hold_cut"
## Passive id of Fallow Ground (proposal: "blight spreads twice as fast"; this act only).
const FALLOW_GROUND: String = "fallow_ground"
## Fallow Ground's value key: + the blight's rise under the army (0..1; 1.0 = twice as fast at Lv 5).
const FALLOW_GROUND_KEY: String = "blight_rise"

# --- Act XV (temporary number): the World-Tree --------------------------------------------------
## THE FIRST SPRING, the World-Tree's ending (FirstSpring, owned by WildRules
## beside `returns`; a stage's RECKONING "first_spring" overrides any key;
## absent = off; owner-approved proposal: "beaten, she does not die. She takes
## the necromancer's dead back into the soil and gives him the one claim left:
## the dead are planted, and in spring they rise to him. The campaign ends on
## the first spring"): with the Green Mother beaten before 0:00, at 0:00 the
## year turns to spring in place of Spring Returns (SeasonCycle.set_override()),
## the blight is wiped, and round each standing necromancer `rise` planted dead
## rise for him on a ring `ring` px wide (HordeDirector.raise_corpse(), the one
## raise path: class `rise_class`, x rise_hp HP, x rise_dmg damage, `life` s,
## tag `tag`); `end_after` s later the run ends in victory (Game.end_run(true,
## "first_spring")). Not beaten: Spring Returns runs as on every Wild stage.
const FIRST_SPRING := {
	"rise": 10,  # TUNING (not in GDD) planted dead a necromancer
	"ring": 90.0,  # TUNING (not in GDD) px
	"rise_class": "warrior",  # TUNING (not in GDD) the dead rise as Risen warriors (the base class's look)
	"rise_hp": 2.0,  # TUNING (not in GDD) x the class's HP
	"rise_dmg": 1.5,  # TUNING (not in GDD) x the class's damage
	"life": 25.0,  # TUNING (not in GDD) s
	"end_after": 20.0,  # TUNING (not in GDD) s from 0:00 to the victory
	"tag": "first_spring",  # The risen's source tag (SummonedUnit.dmg_source)
	"banner": "THE FIRST SPRING: the dead you planted rise to you!",  # TUNING (not in GDD)
}
## Game.end_run() reason of a run the First Spring ended (FeedbackData words).
const FIRST_SPRING_END: String = "first_spring"
