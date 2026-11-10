## GreatPlainStage — STAGE 41 (temporary and final stage 41), THE GREAT PLAIN
## (temporary Act XIV, the Age of Titans, final slot XIV; GDD §15.0 "The Age
## of Titans foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md
## section XIV and docs/proposals/NEW_ACTS_AND_ORDER.md Part 2). Open grassland
## under a hot sky with a bright white streak; herds dominate the screen. Every number and event that belongs to this stage.
## StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain
## (Scarmaw's fall in the Fern Basin opens it); it runs the act's three shared
## rules ("primeval": true: Packs, Herds, Scavengers) and its own systems
## (GreatPlainDirector, STAGE "great_plain"): THE WATERING HOLE (a lake ahead
## of the necromancer from the Watering Hole zone on: it gathers the herds,
## and a fight near it starts their stampedes), THE CANYON (walls that make
## the lanes narrow, and a narrower stampede front), the Horncharger and the
## Clubtail (shared heavies) and MOTHER CLUBTAIL (the miniboss, at 11:40) with
## the herd she guards; the achievement Nothing Taken. Its boss is Old
## Ironbrow, the Horned Titan (BossIronbrow: the Herd, the Charge, the Break).
## The Stampede of Ash is its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Dust Flats, the Watering
## Hole, the Canyon and the Bone Gate.
## Old Ironbrow arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot XIV (docs/last_acts/PLAN.md: above the
## Concord of Stars), not its temporary number; a little harder than the Fern
## Basin. Every rate, cap and weight is TUNING (not in GDD).
class_name GreatPlainStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "great_plain"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XIV sits above the Concord: the Crash Site's 2.15 and up; the step is
## in HP).
const ENEMY_HP_MULT: float = 2.2  # TUNING (not in GDD) phase 2 (the stub's 2.4, first passes 2.3, 2.25: the naive bot died on seeds 3, 7 and 11): the Fern Basin's 2.2; the heavies, Mother Clubtail and the watering hole are this stage's step up
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Crash Site's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) phase 2 (the stub's 1.7, a first pass 1.45): the Fern Basin's 1.4; the heavies (Hornchargers, Clubtails) and Mother Clubtail are this stage's extra weight
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 2 of the act

## The obstacle kinds of the stage (one size each: the Titans art's sprites
## obstacles/<kind>_m, PrimevalGlyphs without art; every obstacle is SHELTER
## from a stampede, Herds). Rect kinds lie either way (the art has its `_v`
## turn):
##   primeval_rock        — a sun-baked boulder (circle of 15 px; art 36x36).
##   primeval_fossil      — a fossil rib arch (rect 46 x 12 px; art 52x30).
##   primeval_canyon_wall — a canyon wall segment (rect 88 x 14 px; art 96x32,
##                          phase 2's art; PrimevalGlyphs until then): the
##                          Canyon's narrow lanes.
## Only the weights and the density change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## GreatPlainGround style, the zone's floor tile tiles/great_plain_<style>),
## its obstacle layout ("arena") and, for the Canyon, "canyon": true
## (GreatPlainDirector narrows the stampedes' front there):
##   dust_flats    — the Dust Flats: dry grass and dust, few rocks.
##   watering_hole — the Watering Hole: greener grass, mud and hoof prints
##                   (the lake comes; GreatPlainDirector).
##   canyon        — the Canyon: red rock, canyon walls in narrow lanes.
##   bone_gate     — the Bone Gate: bleached earth under great fossil arches.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Dust Flats", "id": "dust_flats",  # Owner-approved proposal (zones)
		"blurb": "Dry grass to the horizon, and the herds on it",
		"ground": {"style": "dust_flats", "base": Color(0.30, 0.25, 0.14), "line": Color(0.38, 0.32, 0.18),
			"accent": Palette.PRIMEVAL_OCHRE, "trim": Palette.PRIMEVAL_OCHRE_DARK},  # TUNING (not in GDD)
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 4140,  # TUNING (not in GDD) open grassland
			"kinds": {"primeval_rock": {"weight": 0.65, "shape": "circle", "sizes": [15.0]},
				"primeval_fossil": {"weight": 0.35, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Watering Hole", "id": "watering_hole",  # Owner-approved proposal (zones)
		"blurb": "Every herd on the plain comes to drink",
		"ground": {"style": "watering_hole", "base": Color(0.24, 0.26, 0.13), "line": Color(0.31, 0.33, 0.17),
			"accent": Palette.PRIMEVAL_FERN, "trim": Palette.PRIMEVAL_OCHRE_DARK},  # TUNING (not in GDD)
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 4150,  # TUNING (not in GDD)
			"kinds": {"primeval_rock": {"weight": 0.6, "shape": "circle", "sizes": [15.0]},
				"primeval_fossil": {"weight": 0.4, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Canyon", "id": "canyon", "canyon": true,  # Owner-approved proposal (zones; "a Canyon zone makes the stampede lanes narrow")
		"blurb": "Red rock walls, and the herds run between them",
		"ground": {"style": "canyon", "base": Color(0.30, 0.18, 0.11), "line": Color(0.38, 0.24, 0.14),
			"accent": Color(0.52, 0.23, 0.06), "trim": Palette.PRIMEVAL_TAR},  # TUNING (not in GDD) red rock (the lava ramp darkened)
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 4160,  # TUNING (not in GDD) the narrow lanes (first pass 0.26: the naive bot died in the Canyon on seeds 3 and 7)
			"kinds": {"primeval_canyon_wall": {"weight": 0.6, "shape": "rect", "sizes": [88.0], "short": 14.0},
				"primeval_rock": {"weight": 0.4, "shape": "circle", "sizes": [15.0]}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Bone Gate", "id": "bone_gate",  # Owner-approved proposal (zones)
		"blurb": "Bleached earth under the ribs of older titans",
		"ground": {"style": "bone_gate", "base": Color(0.33, 0.30, 0.22), "line": Color(0.40, 0.37, 0.27),
			"accent": Palette.PRIMEVAL_BONE, "trim": Palette.PRIMEVAL_OCHRE_DARK},  # TUNING (not in GDD)
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 4170,  # TUNING (not in GDD)
			"kinds": {"primeval_fossil": {"weight": 0.6, "shape": "rect", "sizes": [46.0], "short": 12.0},
				"primeval_rock": {"weight": 0.4, "shape": "circle", "sizes": [15.0]}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE GREAT PLAIN  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(0.92, 0.78, 0.50),  # Dust ochre's light: never the player's true gold.
	"fog_color": Color(0.16, 0.12, 0.07),  # Dust haze.
	"fog_bank_color": Color(0.70, 0.60, 0.42),  # A dust cloud.
	"zones": ZONES,
}

## The Great Plain's stage systems (GreatPlainDirector; StageRegistry
## "great_plain"):
##   lake_first    — s from which the watering hole lies on the plain (the
##                   Watering Hole zone).
##   lake_dist     — px ahead of the necromancer a lake is placed.
##   lake_far      — px from the lake at which a new one lies ahead of him.
##   lake_radius   — px of the water (drawn; the shore is 14 px more).
##   gather_radius — px from the lake a herd beast grazes before it is drawn
##                   back (Herds.gather).
##   gather_reach  — px from the lake within which a beast keeps to it.
##   herd_every    — s between two herds that come to drink (at the shore,
##                   while the Herds' cap allows).
##   fight_every   — s between two checks for a fight near the lake.
##   fight_radius  — px round the lake: a standing necromancer, the fight and
##                   the herds that it frightens.
##   fight_min     — enemies fighting within fight_radius px for a fight.
##   canyon_width  — px of a stampede's front in the Canyon (Herds "width").
##   mother_objective — HUD objective while Mother Clubtail stands.
##   nothing_taken_banner — banner of Nothing Taken at 0:00.
const PLAIN := {
	"lake_first": 300.0,  # Owner-approved proposal: the Watering Hole (the zone); TUNING (not in GDD) s
	"lake_dist": 320.0,  # TUNING (not in GDD) px
	"lake_far": 900.0,  # TUNING (not in GDD) px
	"lake_radius": 110.0,  # TUNING (not in GDD) px
	"gather_radius": 220.0,  # Owner-approved proposal: "a central lake gathers herds"; TUNING (not in GDD) px
	"gather_reach": 700.0,  # TUNING (not in GDD) px
	"herd_every": 40.0,  # TUNING (not in GDD) s
	"fight_every": 0.5,  # TUNING (not in GDD) s
	"fight_radius": 360.0,  # Owner-approved proposal: "fighting near it triggers stampedes"; TUNING (not in GDD) px
	"fight_min": 8,  # TUNING (not in GDD) enemies
	"canyon_width": 340.0,  # Owner-approved proposal: "a Canyon zone makes the stampede lanes narrow"; TUNING (not in GDD) px (the open plain's 600)
	"mother_objective": "Mother Clubtail guards her herd: drive it off or bring it down, and her guard breaks",  # TUNING (not in GDD)
	"nothing_taken_banner": "NOTHING TAKEN: not one pile flew to a nest!",  # TUNING (not in GDD)
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
## of the shared kinds with the plain's heavies (the Horncharger and the
## Clubtail) from 5:00 (one Horncharger comes alone at 3:30). The packs come in the EVENTS (a pack is a group that
## arrives together), the herds from Herds and the watering hole, never from
## these weights. The heavies weigh little (a first pass at 0.02-0.03 piled six
## of each up by 12:00 and broke the army bot's ring on seed 7).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.96, "frill_spitter": 0.04},
		"objective": "The Dust Flats: the beasts are hungry, and your army smells of meat"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.925, "frill_spitter": 0.045, "skyraider": 0.03},
		"objective": "Skyraiders dive on your crystals: shoot one down and its pile drops. Near you, nothing is taken"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.925, "frill_spitter": 0.045, "skyraider": 0.03},
		"objective": "The herds stampede when a fight comes close: shelter behind a rock, or lure the hunters into their path"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.903, "frill_spitter": 0.045, "skyraider": 0.04, "horncharger": 0.006, "clubtail": 0.006},
		"objective": "The Watering Hole: the herds gather to drink, and a fight near the water sets them running. Hornchargers charge in a line: let them hit a rock"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.899, "frill_spitter": 0.045, "skyraider": 0.04, "horncharger": 0.008, "clubtail": 0.008},
		"objective": "The Canyon: the walls make the lanes narrow. Shelter behind the rock when the herds run"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.889, "frill_spitter": 0.045, "skyraider": 0.05, "horncharger": 0.008, "clubtail": 0.008},
		"objective": "The Bone Gate: the whole plain hunts you"},
	{"start": BOSS_TIME, "rate": 2.0, "max_alive": 56,  # TUNING (not in GDD) thinner during the boss fight (as the Fern Basin)
		"weights": {"scuttler": 0.9, "frill_spitter": 0.06, "skyraider": 0.04},
		"objective": "Old Ironbrow has come for you: make him charge into a rock"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Each group of
## Razorclaws is a pack (its first is the alpha). Plus the Great Plain's own
## (GreatPlainDirector):
##   "herd_mother" — Mother Clubtail (kind `kind`) comes in mother_dist px
##                   ahead of the necromancer with the herd she guards (`herd`:
##                   one herd kind per beast) and an `escort` (groups of
##                   {kind, count}); the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Scuttlers pours out of the grass!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A pack of Razorclaws is hunting you: kill the alpha!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 4, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "Skyraiders circle over your crystals!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 3, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "Hornchargers lower their horns: step out of the line!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "horncharger", "count": 1, "elite": false}, {"kind": "scuttler", "count": 10, "elite": false}]},  # TUNING (not in GDD) first pass 2
	{"time": 270.0, "type": "wave", "banner": "A bigger pack, and Frill-Spitters behind it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "frill_spitter", "count": 3, "elite": false}]},
	{"time": 360.0, "type": "wave", "banner": "Clubtails lumber in: their armour shrugs off the small blows!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "clubtail", "count": 2, "elite": false}, {"kind": "razorclaw", "count": 4, "elite": false}]},  # TUNING (not in GDD) first pass 3 Clubtails
	{"time": 460.0, "type": "wave", "banner": "The Razorclaws come back with Skyraiders above them!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 6, "elite": false}, {"kind": "skyraider", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "A pack hunts you down the Canyon's lanes!", "formation": "arc",  # TUNING (not in GDD) the stub's Tyrant dropped (with the Canyon's heavies and Mother Clubtail it broke the naive bot's army before 12:00)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 700.0, "type": "herd_mother", "banner": "MOTHER CLUBTAIL! While her herd grazes by her, she shrugs off your blows: drive it off!",  # Owner-approved proposal (miniboss); 8:20 left
		"kind": GreatPlainEnemyData.MOTHER, "mother_dist": 260.0, "elite": false,  # TUNING (not in GDD) px she comes in ahead of the necromancer
		"herd": ["duckbill", "longneck", "duckbill"],  # TUNING (not in GDD) the herd she guards
		"escort": [{"kind": "scuttler", "count": 8}]},  # TUNING (not in GDD) first pass 2 Clubtails (with her they broke the army bot's priest-less ring on seed 7)
	{"time": 780.0, "type": "wave", "banner": "The great pack of the plain!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "frill_spitter", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Every flier on the plain dives at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 5, "elite": false}, {"kind": "horncharger", "count": 2, "elite": false}]},
	{"time": 980.0, "type": "wave", "banner": "The hunters gather before Old Ironbrow!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
]

## Old Ironbrow's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "ironbrow"). His script is
## scripts/enemies/primeval/boss_ironbrow.gd (loaded by his id); his numbers
## are IronbrowData's.
const BOSS := {
	"id": "ironbrow",
	"time": BOSS_TIME,
	"display_name": "Old Ironbrow, the Horned Titan",
	"short_name": "Old Ironbrow",
	"arrive_banner": "Old Ironbrow, the Horned Titan, leads the stampede at you!",
	"defeat_banner": "Old Ironbrow falls, and the herd breaks around his body! Hold out until the end...",
	"dead_objective": "Old Ironbrow is dead. Survive the Stampede of Ash... you cannot.",
}

## Placeholder floor of the foundation stub (PrimevalGround "floor" key), kept
## for the other tools that read it; the stage draws GreatPlainGround ("ground").
const FLOOR := {
	"style": "plain",  # dry grassland and dust.
	"base": Color(0.30, 0.25, 0.14),  # TUNING (not in GDD)
	"line": Color(0.38, 0.32, 0.18),  # TUNING (not in GDD)
	"accent": Palette.PRIMEVAL_OCHRE,  # TUNING (not in GDD)
	"trim": Palette.PRIMEVAL_TAR,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Great Plain",
	"short_name": "Great Plain",
	"chapter": "Chapter XLI",  # Temporary and final stage 41 (the reorder pass renumbers if it moves).
	"act": 14,  # Temporary Act XIV, the Age of Titans (final slot XIV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Great Plain (Act XIV phase 2)").
	"description": "Open grassland under a hot sky and a bright white streak, where the herds run and the old titans lead them.",
	"unlock": {"stage": "fern_basin", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat Scarmaw in the Fern Basin to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Titans stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "great_plain",  # GreatPlainGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"great_plain": PLAIN,  # GreatPlainDirector: the Watering Hole, the Canyon's narrow front, Mother Clubtail, Nothing Taken.
	"primeval": true,  # Packs, Herds, Scavengers (PrimevalRules).
	"packs": {},  # This stage's Packs overrides ({} = PrimevalRulesData.PACKS).
	"herds": {},  # This stage's Herds ({} = PrimevalRulesData.HERDS).
	"scavengers": {},  # This stage's Scavengers ({} = PrimevalRulesData.SCAVENGERS).
	"zones": ZONES,  # The four zones.
	# Music key: "primordial" (the Titans' "Before the Fall", SoundData.PRIMORDIAL_SCORE; its sound pack "titans").
	"music": "primordial",
}
