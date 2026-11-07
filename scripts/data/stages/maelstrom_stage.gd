## MaelstromStage — STAGE 30, THE MAELSTROM (Act X, the Black Tide, the
## temporary act number of the pirate act until the reorder pass moves it to
## slot II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)",
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1). Every
## number and event that belongs to this stage. StageRegistry exposes it to the
## run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1; the finale). The stage is registered,
## unlocked in the campaign chain, runs the Black Tide's three shared rules
## ("corsair": true: Boarding, the Deck and Strikes from the Sea) on its own
## deck ("deck") with its boarding points ("boarding") and a FIXED furniture
## layout, and plays a simple timeline of the shared kinds against a
## PLACEHOLDER boss script (the "vael" boss script under the captain's name),
## with the Black Tide Reckoning. It is hidden from the stage select
## ("playable": false, "Coming soon") until phase 2 builds: the Heave (the deck tilts toward a low side that flips every 12 s; everyone slides at 30 px/s), ghost crews that leave corpses, the Ghost Bosun (the miniboss), Captain Cornelius Vandermere (the Crew, the Maelstrom, Dead Men's Oath).
## Planned zones (ZONES; clock-driven like every stage): The Fog of Ships, The Gyre, The Eye of the Storm, The Drowned Helm.
## The boss arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name MaelstromStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "maelstrom"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
## Tuned for the act's FINAL slot II (docs/last_acts/PLAN.md): a step above the
## Sanctum (1.1), well below the Sanguine Court (1.85): an early act.
const ENEMY_HP_MULT: float = 1.5  # TUNING (not in GDD) placeholder for slot II, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.25  # TUNING (not in GDD) placeholder for slot II (the Sanctum 1.1, Ravensmoor 1.5)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00 (Acts III to IX)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of the act

## The four zones phase 2 builds (names from the owner-approved proposal), each
## from `start` game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "fog_of_ships", "name": "The Fog of Ships", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "gyre", "name": "The Gyre", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "eye_of_the_storm", "name": "The Eye of the Storm", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "drowned_helm", "name": "The Drowned Helm", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

## THE DECK of this stage (DeckBounds; any CorsairRulesData.DECK key; the rest
## are its defaults). Owner-approved proposal: the Hollow Queen's deck, 1,300 x 500 px, rotting.
const DECK := {"length": 1300.0, "beam": 500.0, "bow": 190.0, "bow_tip": 56.0, "stern_cut": 56.0}  # Owner-approved proposal: the Hollow Queen's deck, 1,300 x 500 px, rotting

## BOARDING on this stage (BoardingParty; any CorsairRulesData.BOARDING key):
## "points" lists the boarding points as [x along the deck (px from its centre),
## side (-1 = the upper rail, +1 = the lower rail)]; "whole_rail": true lets a
## boat come alongside anywhere on the straight rail; "boats" is the tier cap
## (the sizes allowed, CorsairRulesData.BOAT_ORDER).
const BOARDING := {"points": [], "whole_rail": true, "boats": ["skiff", "longboat", "raider_ship"]}  # Owner-approved proposal: boarding points: the whole rail; tier cap: the full roster

## STRIKES FROM THE SEA on this stage (SeaStrikes; any CorsairRulesData.SEA key;
## {} = the defaults).
const SEA := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): THE BLACK
## TIDE, shared by every stage of the act: every boat closes at once and the
## whole rail boards, the rail band is struck every 3 s and a great wave shoves
## everything toward the far rail every 20 s ("black_tide":
## CorsairRulesData.BLACK_TIDE keys; {} = those defaults).
const RECKONING := {
	"banner": "THE BLACK TIDE: EVERY BOAT IN THE SEA CLOSES ON YOU",
	"kind": CorsairEnemyData.RECKONING_KIND,  # The Black Tide's heavy (the Boarding Bruiser), by boat.
	"black_tide": {},  # CorsairRulesData.BLACK_TIDE defaults (phase 2 may tune them here).
	"companions": CorsairEnemyData.RECKONING_COMPANIONS,  # Crews, kegs and duellists.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) bruisers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE BLACK TIDE: the whole rail boards and the sea strikes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder). Every spawn comes aboard by boat
## (BoardingParty) or from the sea (SeaStrikes: the sharks).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.3, "max_alive": 28,  # TUNING (not in GDD)
		"weights": {"deckhand": 1.0},
		"objective": "Boats pull alongside: watch the amber lanterns at the rail"},
	{"start": 60.0, "rate": 1.6, "max_alive": 36,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.8, "musketeer": 0.2},
		"objective": "Cut both grapple hooks and the boat drifts off with its crew"},
	{"start": 180.0, "rate": 1.9, "max_alive": 44,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.66, "musketeer": 0.2, "powder_runner": 0.08, "reef_shark": 0.06},
		"objective": "Knock them over the rail and they drown: knockback is your friend"},
	{"start": 300.0, "rate": 2.2, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.6, "musketeer": 0.2, "powder_runner": 0.08, "swashbuckler": 0.05, "reef_shark": 0.07},
		"objective": "Sharks circle the hull: a dark ring on the deck is a strike from the sea"},
	{"start": 600.0, "rate": 2.5, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.56, "musketeer": 0.2, "powder_runner": 0.09, "swashbuckler": 0.07, "boarding_bruiser": 0.02, "reef_shark": 0.06},
		"objective": "Stay off the rail: the sea strikes there, and the boarders come over it"},
	{"start": 900.0, "rate": 2.8, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.53, "musketeer": 0.2, "powder_runner": 0.1, "swashbuckler": 0.08, "boarding_bruiser": 0.03, "reef_shark": 0.06},
		"objective": "The whole Brotherhood is on the water"},
	{"start": BOSS_TIME, "rate": 2.2, "max_alive": 58,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"deckhand": 0.6, "musketeer": 0.2, "powder_runner": 0.08, "swashbuckler": 0.06, "reef_shark": 0.06},
		"objective": "Vandermere has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Every group comes
## aboard by boat (BoardingParty) or from the sea (SeaStrikes).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A longboat pulls alongside!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "Musketeers in the boats!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "musketeer", "count": 4, "elite": false}, {"kind": "deckhand", "count": 8, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "Fins in the water! The sharks are circling!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "reef_shark", "count": 3, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "Lit kegs! Powder runners are coming over the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "powder_runner", "count": 3, "elite": false}, {"kind": "deckhand", "count": 8, "elite": false}]},
	{"time": 340.0, "type": "wave", "banner": "A kraken arm rises at the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 1, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 430.0, "type": "wave", "banner": "Duellists of the Brotherhood board!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "swashbuckler", "count": 2, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Two boats at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 12, "elite": false}, {"kind": "musketeer", "count": 6, "elite": false}]},
	{"time": 660.0, "type": "wave", "banner": "A Boarding Bruiser leads the next crew!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 1, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}, {"kind": "powder_runner", "count": 2, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "The kraken reaches for your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 2, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 900.0, "type": "wave", "banner": "The Brotherhood boards from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 14, "elite": false}, {"kind": "swashbuckler", "count": 2, "elite": false}, {"kind": "musketeer", "count": 4, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The captain's own crew comes first!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 2, "elite": false}, {"kind": "deckhand", "count": 12, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA, plus "fixed"): THE DECK'S
## FURNITURE, a FIXED authored layout (Arena "fixed": each entry {kind, at, size
## (index into the kind's sizes)}; at most one per 256 px arena cell, each at
## least ArenaData.CELL_MARGIN from its cell's edges, so the one-lookup
## push-out sees it), never scattered by hash. Placeholder kinds drawn by
## CorsairGlyphs until phase 2 brings the stage's own art.
const ARENA := {
	"density": 0.0,  # Unused: the layout is fixed.
	"clear_radius": 0.0,  # Unused: the layout is fixed.
	"layout_seed": 2830,  # Unused by a fixed layout (kept for the arena's keys).
	"fixed": [
		{"kind": "maelstrom_wheel", "at": Vector2(-580.0, -100.0), "size": 0},  # the Drowned Helm's wheel
		{"kind": "maelstrom_mast", "at": Vector2(-128.0, -100.0), "size": 0},  # rotting masts
		{"kind": "maelstrom_mast", "at": Vector2(384.0, 100.0), "size": 0},
		{"kind": "maelstrom_barrel", "at": Vector2(128.0, -128.0), "size": 0},  # barrels
		{"kind": "maelstrom_barrel", "at": Vector2(-384.0, 128.0), "size": 1},
		{"kind": "maelstrom_barrel", "at": Vector2(384.0, -128.0), "size": 0},
		{"kind": "maelstrom_cannon", "at": Vector2(-384.0, -128.0), "size": 0},  # dead guns
		{"kind": "maelstrom_cannon", "at": Vector2(128.0, 128.0), "size": 0},
		{"kind": "maelstrom_cannon", "at": Vector2(-128.0, 128.0), "size": 0},
	],
	"kinds": {
		"maelstrom_mast": {"shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD) placeholder art (CorsairGlyphs)
		"maelstrom_wheel": {"shape": "circle", "sizes": [12.0]},  # TUNING (not in GDD) placeholder art (CorsairGlyphs)
		"maelstrom_barrel": {"shape": "circle", "sizes": [10.0, 12.0]},  # TUNING (not in GDD) placeholder art (CorsairGlyphs)
		"maelstrom_cannon": {"shape": "rect", "sizes": [32.0], "short": 16.0},  # TUNING (not in GDD) placeholder art (CorsairGlyphs)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under the captain's name until phase 2 adds
## scripts/enemies/corsair/boss_vandermere.gd (then remove the "script" key).
const BOSS := {
	"id": "vandermere",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_vandermere.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "Captain Cornelius Vandermere, Master of the Hollow Queen",
	"short_name": "Vandermere",
	"arrive_banner": "Vandermere's crew of the dead works the Hollow Queen!",
	"defeat_banner": "The whirlpool closes, and the sea is calm! Hold out until the end...",
	"dead_objective": "Vandermere is beaten. Survive the Black Tide... you cannot.",
}

## Placeholder look (CorsairGround, code-drawn) until phase 2 brings the stage's
## zone art: the deck's planks and rail, the sea around it.
const FLOOR := {
	"style": "ghost",  # The light over the sea (night / dawn / ghost).
	"sea": Palette.CORSAIR_SEA_DARK,  # TUNING (not in GDD) the water
	"foam": Palette.CORSAIR_FOAM,  # TUNING (not in GDD) the foam lines
	"plank": Palette.CORSAIR_OAK,  # TUNING (not in GDD) the deck
	"seam": Palette.CORSAIR_OAK_DARK,  # TUNING (not in GDD) the plank seams
	"rail": Palette.CORSAIR_OAK_LIGHT,  # TUNING (not in GDD) the rail
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Maelstrom",
	"short_name": "Maelstrom",
	"chapter": "Chapter XXX",
	"act": 10,  # Act X (temporary): the Black Tide, final slot II after the reorder.
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The ghost ship Hollow Queen, caught in a whirlpool at midnight, and the captain lashed to her wheel who has kept his oath to the sea for a hundred years.",
	"unlock": {"stage": "galleon", "boss_kills": 1},  # Lead's plan: the chain runs Harvester -> Crow -> Marrec -> Vandermere
	"unlock_text": "Defeat Admiral Marrec on the Treasure Galleon to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None at sea.
	"consecration": {},  # A Covenant event: none at sea.
	"crypt_defender": {},  # None at sea.
	"arena": ARENA,
	"ground": "corsair",  # Placeholder CorsairGround (the sea and the deck) until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector).
	"corsair": true,  # Act X: Boarding, the Deck, Strikes from the Sea (CorsairRules).
	"deck": DECK,  # Act X: this stage's deck (DeckBounds).
	"boarding": BOARDING,  # Act X: this stage's boarding points and tier cap (BoardingParty).
	"sea": SEA,  # Act X: this stage's sea strikes ({} = the defaults).
	"zones": ZONES,  # Act X stub: the planned zones (phase 2 builds them).
	# Music key "tide" FOR NOW (Act II's "Below the Tide"): the parallel audio
	# pass adds the act's own score (key "shanty", pack "corsair") and the lead
	# switches this to "shanty" at the merge.
	"music": "shanty",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
