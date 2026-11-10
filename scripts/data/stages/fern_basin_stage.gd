## FernBasinStage — STAGE 40 (temporary and final stage 40), THE FERN BASIN
## (temporary Act XIV, the Age of Titans, final slot XIV; GDD §15.0 "The Age
## of Titans foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md
## section XIV and docs/proposals/NEW_ACTS_AND_ORDER.md Part 2). A river basin
## deep in jungle, the day before the impact; the sky is still blue and the
## white streak is faint. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (the
## Voice's fall in the Empyrean opens it); it runs the act's three shared rules
## ("primeval": true: Packs, Herds, Scavengers) and its own systems
## (FernBasinDirector, STAGE "fern_basin"): THE TAR SEEPS (pools of tar that
## slow everyone through TerrainSlow, trap the herbivores as free kills and
## hide the Bog Crocs), the Bog Croc ambushes from the seeps (from the Tar Seep
## zone) and IRONJAW, THE NEST MOTHER (the miniboss, at 11:40) with her nest.
## Its boss is Scarmaw, the Great Raptor (BossScarmaw: the Hunt, the Ambush,
## Blood Up). The Stampede of Ash is its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Fern Floor, the Tar Seep,
## the River Ford and the Nesting Hollow.
## Scarmaw arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XIV (docs/last_acts/PLAN.md: above the
## Concord of Stars), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name FernBasinStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "fern_basin"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XIV sits above the Concord: the Crash Site's 2.15 and up; the step is
## in HP).
const ENEMY_HP_MULT: float = 2.2  # TUNING (not in GDD) phase 2 (the stub's 2.3): the act's first stage is its easiest, a step over the Crash Site's 2.15
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Crash Site's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) phase 2 (the stub's 1.6, a first pass 1.5: the naive bot died on seeds 3, 7 and 11); under the Crash Site's 1.5 because the tar, the crocs and the nest are this stage's extra weight
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The obstacle kinds every zone shares (one size each: the Titans art's
## sprites obstacles/<kind>_m, PrimevalGlyphs without art; every obstacle is
## SHELTER from a stampede, Herds). Rect kinds lie either way (the art has its
## `_v` turn):
##   primeval_rock      — a mossy boulder (circle of 15 px; art 36x36).
##   primeval_fossil    — a fossil rib arch (rect 46 x 12 px; art 52x30).
##   primeval_tree_fern — a tree fern trunk (circle of 10 px; art 40x48, phase
##                        2's art; PrimevalGlyphs until then).
## Only the weights change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## FernBasinGround style, the zone's floor tile tiles/fern_basin_<style>), its
## TAR ("ground" "tar", read by FernBasinGround to draw the pools AND by
## FernBasinDirector to slow and trap, one source: `chance` 0..1 that a tar
## cell holds a pool, pool radius `min`..`max` px, `style` "tar" or "river",
## `salt` the cell hash's salt so each zone lays its own pools) and its
## obstacle layout ("arena"):
##   fern_floor     — the Fern Floor: jungle earth under ferns, a few seeps.
##   tar_seep       — the Tar Seep: black pools everywhere (the Bog Crocs come).
##   river_ford     — the River Ford: shallow brown water over the ford.
##   nesting_hollow — the Nesting Hollow: trampled earth, eggshells, few seeps.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Fern Floor", "id": "fern_floor",  # Owner-approved proposal (zones)
		"blurb": "Jungle earth under ferns the height of a man",
		"ground": {"style": "fern_floor", "base": Color(0.13, 0.20, 0.11), "line": Color(0.19, 0.28, 0.14),
			"accent": Palette.PRIMEVAL_FERN, "trim": Palette.PRIMEVAL_TAR,
			"tar": {"chance": 0.14, "min": 46.0, "max": 70.0, "style": "tar", "salt": 4041}},  # TUNING (not in GDD) a few seeps
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4040,  # TUNING (not in GDD)
			"kinds": {"primeval_tree_fern": {"weight": 0.45, "shape": "circle", "sizes": [10.0]}, "primeval_rock": {"weight": 0.35, "shape": "circle", "sizes": [15.0]},
				"primeval_fossil": {"weight": 0.2, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Tar Seep", "id": "tar_seep",  # Owner-approved proposal (zones)
		"blurb": "Black pools that hold whatever walks into them",
		"ground": {"style": "tar_seep", "base": Color(0.12, 0.15, 0.10), "line": Color(0.09, 0.08, 0.07),
			"accent": Palette.PRIMEVAL_FERN_DARK, "trim": Palette.PRIMEVAL_TAR,
			"tar": {"chance": 0.34, "min": 54.0, "max": 86.0, "style": "tar", "salt": 4051}},  # TUNING (not in GDD) the stage mechanic's zone
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 4050,  # TUNING (not in GDD)
			"kinds": {"primeval_rock": {"weight": 0.45, "shape": "circle", "sizes": [15.0]}, "primeval_tree_fern": {"weight": 0.3, "shape": "circle", "sizes": [10.0]},
				"primeval_fossil": {"weight": 0.25, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The River Ford", "id": "river_ford",  # Owner-approved proposal (zones)
		"blurb": "Shallow brown water where the herds cross",
		"ground": {"style": "river_ford", "base": Color(0.15, 0.18, 0.13), "line": Color(0.22, 0.25, 0.18),
			"accent": Palette.PRIMEVAL_OCHRE_DARK, "trim": Palette.PRIMEVAL_FERN_DARK,
			"tar": {"chance": 0.26, "min": 60.0, "max": 96.0, "style": "river", "salt": 4061}},  # TUNING (not in GDD) river pools: the same slow and hiding place
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 4060,  # TUNING (not in GDD)
			"kinds": {"primeval_rock": {"weight": 0.55, "shape": "circle", "sizes": [15.0]}, "primeval_fossil": {"weight": 0.25, "shape": "rect", "sizes": [46.0], "short": 12.0},
				"primeval_tree_fern": {"weight": 0.2, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Nesting Hollow", "id": "nesting_hollow",  # Owner-approved proposal (zones)
		"blurb": "Trampled earth and broken eggshells: the hunters' den",
		"ground": {"style": "nesting_hollow", "base": Color(0.17, 0.16, 0.11), "line": Color(0.24, 0.21, 0.14),
			"accent": Palette.PRIMEVAL_OCHRE, "trim": Palette.PRIMEVAL_BONE,
			"tar": {"chance": 0.12, "min": 46.0, "max": 72.0, "style": "tar", "salt": 4071}},  # TUNING (not in GDD) a few seeps
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 4070,  # TUNING (not in GDD)
			"kinds": {"primeval_fossil": {"weight": 0.45, "shape": "rect", "sizes": [46.0], "short": 12.0}, "primeval_rock": {"weight": 0.35, "shape": "circle", "sizes": [15.0]},
				"primeval_tree_fern": {"weight": 0.2, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE FERN BASIN  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(0.62, 0.82, 0.48),  # Fern green (Palette.PRIMEVAL_FERN's light): never the player's true gold.
	"fog_color": Color(0.08, 0.10, 0.07),  # Jungle shade.
	"fog_bank_color": Color(0.55, 0.62, 0.48),  # Jungle mist.
	"zones": ZONES,
}

## The Fern Basin's stage systems (FernBasinDirector; StageRegistry
## "fern_basin"):
##   tar_cell      — px of one tar cell (each holds at most one pool, its
##                   centre kept tar_margin px inside the cell).
##   tar_margin    — px a pool's edge keeps from its cell's border.
##   tar_clear     — px round the arena's centre that never holds tar (the
##                   run starts on dry ground).
##   tar_every     — s between two checks of who stands in tar.
##   tar_slow_*    — fraction of move speed lost in tar: the necromancer and
##                   the summons through TerrainSlow (Brinewalker helps), the
##                   enemies through Enemy.apply_slow() (the Bog Croc swims,
##                   the fliers fly over).
##   tar_linger    — s a tar slow outlasts the last check.
##   croc_first / croc_every / croc_count / croc_cap — the Bog Crocs: from
##                   croc_first s, every croc_every s, croc_count crocs come
##                   up in pools croc_min..croc_max px from a standing
##                   necromancer (at most croc_cap alive).
##   croc_search   — tar cells looked at for a pool round each try.
##   nest_objective — HUD objective while Ironjaw or her nest stands.
const FERN := {
	"tar_cell": 340.0,  # TUNING (not in GDD) px
	"tar_margin": 20.0,  # TUNING (not in GDD) px
	"tar_clear": 260.0,  # TUNING (not in GDD) px
	"tar_every": 0.1,  # TUNING (not in GDD) s
	"tar_slow_player": 0.35,  # Owner-approved proposal: "pools of tar slow everyone"; TUNING (not in GDD) the fraction
	"tar_slow_summon": 0.35,  # TUNING (not in GDD)
	"tar_slow_enemy": 0.35,  # TUNING (not in GDD)
	"tar_linger": 0.25,  # TUNING (not in GDD) s
	"croc_first": 300.0,  # TUNING (not in GDD) s: the Tar Seep zone
	"croc_every": 30.0,  # TUNING (not in GDD) s (first pass 24)
	"croc_count": 2,  # TUNING (not in GDD)
	"croc_cap": 4,  # TUNING (not in GDD) (first pass 6: 4,800 damage to the naive bot's summons on seed 11)
	"croc_min": 180.0,  # TUNING (not in GDD) px (first pass 240: two crocs in three came up tired, the ring never passed their pools)
	"croc_max": 460.0,  # TUNING (not in GDD) px (first pass 620)
	"croc_kind": PrimevalEnemyData.BOG_CROC,  # Owner-approved proposal: "Bog Crocs ambush from the seeps"
	"nest_objective": "Ironjaw guards her nest: break the nest, and its Scuttlers stop",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## STAMPEDE OF ASH, shared by the first two Titans stages: the sky burns, herds
## stampede from every side, volcanic bombs fall, packs double and Tyrants
## roam ("kind": the Tyrant, with the shared kinds as companions;
## "stampede_of_ash": PrimevalRulesData.ASH keys; {} = those defaults).
const RECKONING := {
	"banner": "THE STAMPEDE OF ASH: THE SKY BURNS",
	"kind": PrimevalEnemyData.RECKONING_KIND,  # The shared Stampede of Ash heavy (the Tyrant).
	"stampede_of_ash": {},  # PrimevalRulesData.ASH defaults (phase 2 may tune them here).
	"companions": PrimevalEnemyData.RECKONING_COMPANIONS,  # Scuttlers, doubled packs, Frill-Spitters.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 1,  # TUNING (not in GDD) Tyrants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE STAMPEDE OF ASH: the sky burns and every beast runs. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a ramp
## of the shared kinds. The packs come in the EVENTS (a pack is
## a group that arrives together), the herds from Herds, never from these
## weights. The Frill-Spitters stay at 4.5% (balance pass 1: they rose to 7%,
## more than the Great Plain's, and were the top killer of the necromancer).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.96, "frill_spitter": 0.04},
		"objective": "The Fern Floor: the beasts are hungry, and your army smells of meat"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.925, "frill_spitter": 0.045, "skyraider": 0.03},
		"objective": "Skyraiders dive on your crystals: shoot one down and its pile drops. Near you, nothing is taken"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.925, "frill_spitter": 0.045, "skyraider": 0.03},
		"objective": "The herds stampede when a fight comes close: shelter behind a rock, or lure the hunters into their path"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.915, "frill_spitter": 0.045, "skyraider": 0.04},
		"objective": "The Tar Seep: tar slows everyone, and holds a grazing giant fast. Bog Crocs lie in the pools"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.915, "frill_spitter": 0.045, "skyraider": 0.04},
		"objective": "The River Ford: a fallen giant rises as a Fossil Giant for you. A pack circles, holds, then rushes: kill the alpha"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.905, "frill_spitter": 0.045, "skyraider": 0.05},
		"objective": "The Nesting Hollow: the whole basin hunts you"},
	{"start": BOSS_TIME, "rate": 1.7, "max_alive": 48,  # TUNING (not in GDD) thinner during the boss fight (the stub's 2.4 / 64, then 2.0 / 56: the army bot's lowest HP came in Scarmaw's fight on seed 11; balance pass 1: a Scuttler swarm killed it there on seed 7)
		"weights": {"scuttler": 0.915, "frill_spitter": 0.045, "skyraider": 0.04},
		"objective": "Scarmaw has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Each group of
## Razorclaws is a pack (its first is the alpha). Plus the Fern Basin's own
## (FernBasinDirector):
##   "nest_mother" — Ironjaw (kind `kind`) comes in nest_dist px ahead of the
##                   necromancer beside her nest (kind `nest`) with an
##                   `escort` (groups of {kind, count}); the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Scuttlers pours out of the ferns!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A pack of Razorclaws is hunting you: kill the alpha!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 4, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "Skyraiders circle over your crystals!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 3, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 230.0, "type": "wave", "banner": "A bigger pack, and Frill-Spitters behind it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "frill_spitter", "count": 3, "elite": false}]},
	{"time": 340.0, "type": "wave", "banner": "Two packs at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 460.0, "type": "wave", "banner": "The Razorclaws come back with Skyraiders above them!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 6, "elite": false}, {"kind": "skyraider", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "A Tyrant walks out of the river!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "tyrant", "count": 1, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 700.0, "type": "nest_mother", "banner": "IRONJAW, THE NEST MOTHER! Her nest pours out Scuttlers: break it, then bring her down!",  # Owner-approved proposal (miniboss); 8:20 left
		"kind": FernBasinEnemyData.IRONJAW, "nest": FernBasinEnemyData.NEST, "nest_dist": 230.0, "elite": false,  # TUNING (not in GDD) px the nest lies ahead of the necromancer
		"escort": [{"kind": "scuttler", "count": 8}]},  # TUNING (not in GDD) first pass 12
	{"time": 760.0, "type": "wave", "banner": "The great pack of the basin!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "frill_spitter", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Every flier in the basin dives at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 5, "elite": false}, {"kind": "razorclaw", "count": 6, "elite": false}]},
	{"time": 980.0, "type": "wave", "banner": "The hunters gather before Scarmaw!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},  # The stub's Tyrant dropped: it was still biting in Scarmaw's fight (the army bot's lowest HP, seed 11)
]

## Scarmaw's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "scarmaw"). Her script is scripts/enemies/primeval/boss_scarmaw.gd (loaded by
## her id); her numbers are ScarmawData's.
const BOSS := {
	"id": "scarmaw",
	"time": BOSS_TIME,
	"display_name": "Scarmaw, the Great Raptor",
	"short_name": "Scarmaw",
	"arrive_banner": "Scarmaw, the Great Raptor, leaps out of the ferns with her pack!",
	"defeat_banner": "Scarmaw falls, and her pack scatters into the ferns! Hold out until the end...",
	"dead_objective": "Scarmaw is dead. Survive the Stampede of Ash... you cannot.",
}

## Placeholder floor of the foundation stub (PrimevalGround "floor" key), kept
## for the other tools that read it; the stage draws FernBasinGround ("ground").
const FLOOR := {
	"style": "fern",  # jungle earth under ferns.
	"base": Color(0.13, 0.20, 0.11),  # TUNING (not in GDD)
	"line": Color(0.19, 0.28, 0.14),  # TUNING (not in GDD)
	"accent": Palette.PRIMEVAL_FERN,  # TUNING (not in GDD)
	"trim": Palette.PRIMEVAL_TAR,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Fern Basin",
	"short_name": "Fern Basin",
	"chapter": "Chapter XL",  # Temporary and final stage 40 (the reorder pass renumbers if it moves).
	"act": 14,  # Temporary Act XIV, the Age of Titans (final slot XIV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Fern Basin (Act XIV phase 2)").
	"description": "A river basin deep in jungle, the day before the sky falls: ferns, tar and beasts the size of houses, and every one that falls leaves a skeleton.",
	"unlock": {"stage": "empyrean", "boss_kills": 1},  # Plan: the Voice opens the act; each stage opens the next
	"unlock_text": "Defeat the Voice in the Empyrean to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Titans stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "fern_basin",  # FernBasinGround: the four zone floors and the tar pools.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"fern_basin": FERN,  # FernBasinDirector: the Tar Seeps, the Bog Crocs, Ironjaw and her nest.
	"primeval": true,  # Packs, Herds, Scavengers (PrimevalRules).
	"packs": {},  # This stage's Packs overrides ({} = PrimevalRulesData.PACKS).
	"herds": {},  # This stage's Herds ({} = PrimevalRulesData.HERDS).
	"scavengers": {},  # This stage's Scavengers ({} = PrimevalRulesData.SCAVENGERS).
	"zones": ZONES,  # The four zones.
	# Music key: "primordial" (the Titans' "Before the Fall", SoundData.PRIMORDIAL_SCORE; its sound pack "titans").
	"music": "primordial",
}
