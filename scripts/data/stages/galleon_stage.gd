## GalleonStage — STAGE 29, THE TREASURE GALLEON (Act X, the Black Tide, the
## temporary act number of the pirate act until the reorder pass moves it to
## slot II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)",
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1). Every
## number and event that belongs to this stage. StageRegistry exposes it to the
## run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## STATUS: PHASE 2 (GDD §15.0 "The Treasure Galleon (Act X phase 2)"): the
## Black Tide's three shared rules ("corsair": true: Boarding, the Deck and
## Strikes from the Sea) on the big deck that scrolls (1,500 x 540, five
## boarding points, boats up to raider ships, plus gunboats that never board),
## and the stage's own systems in GalleonDirector ("galleon" config below):
## the four zones (the Convoy Lane, the Reef, the Storm, the Gun Deck: the
## looks of GalleonGround, the timeline's mix; the camera scrolls, the map does
## not change), BROADSIDES (an enemy galleon alongside every
## "broadside_every" s of the zone fires a 6-line broadside across the deck,
## 1.5 s telegraph, both armies, enemies knocked toward the far rail) and THE
## DECK CANNONS (the eight "deck_cannon" obstacles: any summon or necromancer
## standing at one for 3 s fires it once at the nearest boat, a world rule),
## OLD HOLLOW-EYE the kraken (the miniboss: "hollow_eye" event) and ADMIRAL
## ISABEAU MARREC (BossMarrec: the Fleet, the Boarding, Gold Fever). Its kinds
## (CorsairEnemyData's Act X Galleon block): the Gunnery Mate, the Voodoo
## Navigator, the Gunboat and the Hull Crab; its own (GalleonEnemyData): Old
## Hollow-Eye and Marrec's cursed coin. Hidden from the stage select
## ("playable": false) until the lead's integration flips the act live.
## Tuned for the act's FINAL slot II (docs/last_acts/PLAN.md: easier than the
## Sanguine Court): pressure from boat traffic and the crews (more crew per
## second, bigger boats, five busy boarding points) rather than raw HP.
## The boss arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name GalleonStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "galleon"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
## Tuned for the act's FINAL slot II (docs/last_acts/PLAN.md): a step above the
## Sanctum (1.1), well below the Sanguine Court (1.85): an early act.
const ENEMY_HP_MULT: float = 1.4  # TUNING (not in GDD) placeholder for slot II, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.2  # TUNING (not in GDD) placeholder for slot II (the Sanctum 1.1, Ravensmoor 1.5)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00 (Acts III to IX)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of the act

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven like every stage): GalleonDirector announces each one,
## switches GalleonGround's look ("ground") and its broadside rhythm
## ("broadside_every" s between two enemy galleons alongside; 0 = none).
const ZONES := [
	{"id": "convoy_lane", "name": "The Convoy Lane", "start": 0.0, "broadside_every": 80.0,  # Owner-approved proposal (names); TUNING (not in GDD) times and rhythm
		"banner": "THE CONVOY LANE: the Brotherhood's boats close on the captured galleon",  # TUNING (not in GDD)
		"ground": {"style": "convoy_lane", "deck": Color(1.0, 0.97, 0.9), "sea": Color(1.0, 1.0, 1.0), "foam": 0.35}},  # TUNING (not in GDD) dawn: the scrubbed deck as drawn, the sea as drawn
	{"id": "reef", "name": "The Reef", "start": 300.0, "broadside_every": 75.0,  # Owner-approved proposal (names); TUNING (not in GDD) times and rhythm
		"banner": "THE REEF: crabs climb the hull and sharks hunt the shallows",  # TUNING (not in GDD)
		"ground": {"style": "reef", "deck": Color(1.0, 0.98, 0.94), "sea": Color(0.82, 1.08, 1.05), "foam": 0.5}},  # TUNING (not in GDD) shallower, greener-blue water and reef rocks (never soul-teal)
	{"id": "storm", "name": "The Storm", "start": 600.0, "broadside_every": 70.0,  # Owner-approved proposal (names); TUNING (not in GDD) times and rhythm
		"banner": "THE STORM: the sky closes, and something vast stirs under the keel",  # TUNING (not in GDD)
		"ground": {"style": "storm", "deck": Color(0.72, 0.74, 0.82), "sea": Color(0.62, 0.66, 0.78), "foam": 0.65}},  # TUNING (not in GDD) a dark, wet deck, a black-blue sea with more foam
	{"id": "gun_deck", "name": "The Gun Deck", "start": 900.0, "broadside_every": 55.0,  # Owner-approved proposal (names); TUNING (not in GDD) times and rhythm
		"banner": "THE GUN DECK: gunboats and broadsides: man the deck cannons!",  # TUNING (not in GDD)
		"ground": {"style": "gun_deck", "deck": Color(1.05, 0.9, 0.78), "sea": Color(0.9, 0.86, 0.86), "foam": 0.45}},  # TUNING (not in GDD) lantern-lit smoke over the guns
]

## THE DECK of this stage (DeckBounds; any CorsairRulesData.DECK key; the rest
## are its defaults). Owner-approved proposal: a deck 1,500 x 540 px, a quarterdeck, a forecastle, three masts and eight deck cannons.
const DECK := {"length": 1500.0, "beam": 540.0, "bow": 210.0, "bow_tip": 60.0, "stern_cut": 60.0}  # Owner-approved proposal: a deck 1,500 x 540 px, a quarterdeck, a forecastle, three masts and eight deck cannons

## BOARDING on this stage (BoardingParty; any CorsairRulesData.BOARDING key):
## "points" lists the boarding points as [x along the deck (px from its centre),
## side (-1 = the upper rail, +1 = the lower rail)]; "boats" is the tier cap
## (the sizes allowed, CorsairRulesData.BOAT_ORDER). Phase 2: all five points
## busy at once (max_boats 5) and bigger boats (a boat waits for min_crew
## boarders), poured faster: the boat traffic is the stage's pressure. The
## gunboats come apart from the queue (GunboatKit, a timeline kind).
const BOARDING := {"points": [[-400.0, -1], [0.0, -1], [400.0, -1], [-200.0, 1], [300.0, 1]], "boats": ["skiff", "longboat", "raider_ship"],  # Owner-approved proposal: five boarding points; tier cap up to raider ships (and gunboats)
	"max_boats": 5,  # TUNING (not in GDD) one boat per boarding point (the shared default is 4)
	"min_crew": 9,  # TUNING (not in GDD) a boat waits for more than a skiff's crew, so longboats come (the shared default is 3)
	"max_wait": 2.5,  # TUNING (not in GDD) s, unless its oldest crewman waited this long
	"pour_every": 0.4,  # TUNING (not in GDD) s between two crewmen once hooked (the shared default is 0.6)
	"queue_cap": 120,  # TUNING (not in GDD) crew waiting for a boat
}

## STRIKES FROM THE SEA on this stage (SeaStrikes; any CorsairRulesData.SEA key;
## {} = the defaults).
const SEA := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): THE BLACK
## TIDE, shared by every stage of the act ("black_tide":
## CorsairRulesData.BLACK_TIDE keys): every boat closes at once and the whole
## rail boards, the rail band is struck, a great wave every 20 s, and here the
## GUNBOATS shell the deck in lines (gunboat_every, the Galleon's block of the
## Black Tide).
const RECKONING := {
	"banner": "THE BLACK TIDE: EVERY BOAT IN THE SEA CLOSES ON YOU",
	"kind": CorsairEnemyData.RECKONING_KIND,  # The Black Tide's heavy (the Boarding Bruiser), by boat.
	"black_tide": {"gunboat_every": 18.0},  # TUNING (not in GDD) a gunboat comes alongside every 18 s (the Galleon's gunboats in the Black Tide)
	"companions": CorsairEnemyData.RECKONING_COMPANIONS,  # Crews, kegs and duellists.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) bruisers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE BLACK TIDE: the whole rail boards, the gunboats shell the deck. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS). Every spawn
## comes aboard by boat (BoardingParty), from the sea (SeaStrikes: sharks and
## hull crabs) or alongside (GunboatKit: gunboats). `max_alive` counts the crew
## waiting for a boat too (CorsairRules.alive_adjust()). Phase 2: a heavier
## flow than the stub's (the crews are killed as they step aboard, so the flow
## is the pressure), the Gunnery Mate and the Voodoo Navigator from the Reef.
const SEGMENTS := [
	{"start": 0.0, "rate": 2.1, "max_alive": 48,  # TUNING (not in GDD)
		"weights": {"deckhand": 1.0},
		"objective": "Boats pull alongside: watch the amber lanterns at the rail"},
	{"start": 60.0, "rate": 2.7, "max_alive": 62,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.8, "musketeer": 0.2},
		"objective": "Cut both grapple hooks and the boat drifts off with its crew"},
	{"start": 180.0, "rate": 3.3, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.64, "musketeer": 0.2, "powder_runner": 0.1, "reef_shark": 0.06},
		"objective": "Stand at a deck cannon for 3 s and it fires at the nearest boat"},
	{"start": 300.0, "rate": 3.9, "max_alive": 94,  # TUNING (not in GDD) the Reef
		"weights": {"deckhand": 0.52, "musketeer": 0.16, "powder_runner": 0.08, "swashbuckler": 0.05, "gunnery_mate": 0.06, "reef_shark": 0.06, "hull_crab": 0.04, "voodoo_navigator": 0.03},
		"objective": "Hull crabs climb the rail: keep blockers near the rail band"},
	{"start": 600.0, "rate": 4.4, "max_alive": 108,  # TUNING (not in GDD) the Storm
		"weights": {"deckhand": 0.48, "musketeer": 0.16, "powder_runner": 0.08, "swashbuckler": 0.07, "gunnery_mate": 0.07, "boarding_bruiser": 0.02, "reef_shark": 0.05, "hull_crab": 0.04, "voodoo_navigator": 0.03},
		"objective": "A Voodoo Navigator marks the sea's strikes on your ring: kill her and the strike fails"},
	{"start": 900.0, "rate": 4.8, "max_alive": 120,  # TUNING (not in GDD) the Gun Deck
		"weights": {"deckhand": 0.46, "musketeer": 0.16, "powder_runner": 0.09, "swashbuckler": 0.07, "gunnery_mate": 0.08, "boarding_bruiser": 0.03, "reef_shark": 0.04, "hull_crab": 0.04, "voodoo_navigator": 0.03},
		"objective": "The whole Brotherhood is on the water: man the deck cannons"},
	{"start": BOSS_TIME, "rate": 3.4, "max_alive": 90,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"deckhand": 0.56, "musketeer": 0.18, "powder_runner": 0.08, "swashbuckler": 0.06, "gunnery_mate": 0.06, "reef_shark": 0.06},
		"objective": "Admiral Marrec has come for her gold"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus "hollow_eye":
## GalleonDirector's miniboss, Old Hollow-Eye, with "arms" kraken arms beside
## him). Every group comes aboard by boat (BoardingParty), from the sea
## (SeaStrikes) or alongside (a gunboat).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A longboat pulls alongside!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 12, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "Musketeers in the boats!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "musketeer", "count": 5, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "Fins in the water! The sharks are circling!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "reef_shark", "count": 3, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "A raider ship runs alongside: two planks at once!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "powder_runner", "count": 3, "elite": false}, {"kind": "deckhand", "count": 18, "elite": false}, {"kind": "musketeer", "count": 3, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "Hull crabs climb out of the Reef!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "hull_crab", "count": 3, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 390.0, "type": "wave", "banner": "A GUNBOAT runs out her guns: step out of the shell lines!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gunboat", "count": 1, "elite": false}, {"kind": "gunnery_mate", "count": 3, "elite": false}, {"kind": "deckhand", "count": 8, "elite": false}]},
	{"time": 470.0, "type": "wave", "banner": "The Voodoo Navigators read the sea against you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "voodoo_navigator", "count": 2, "elite": false}, {"kind": "swashbuckler", "count": 2, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Three boats at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 18, "elite": false}, {"kind": "musketeer", "count": 6, "elite": false}, {"kind": "gunnery_mate", "count": 2, "elite": false}]},
	{"time": 660.0, "type": "hollow_eye", "banner": "OLD HOLLOW-EYE rises from the Storm! Kill it while it is surfaced!", "kind": "old_hollow_eye",  # TUNING (not in GDD) the miniboss
		"arms": 2},
	{"time": 750.0, "type": "wave", "banner": "Two gunboats in the swell!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "gunboat", "count": 2, "elite": false}, {"kind": "boarding_bruiser", "count": 1, "elite": false}, {"kind": "deckhand", "count": 12, "elite": false}]},
	{"time": 840.0, "type": "wave", "banner": "The kraken reaches for your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 2, "elite": false}, {"kind": "hull_crab", "count": 2, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Brotherhood boards from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 18, "elite": false}, {"kind": "swashbuckler", "count": 3, "elite": false}, {"kind": "musketeer", "count": 5, "elite": false}, {"kind": "gunnery_mate", "count": 2, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Admiral's own marines come first!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 2, "elite": false}, {"kind": "deckhand", "count": 14, "elite": false}, {"kind": "gunboat", "count": 1, "elite": false}]},
]

## The Galleon's own systems (GalleonDirector; numbers of the broadsides and
## the deck cannons are GalleonData's): HUD objectives and the zone change.
const GALLEON := {
	"hollow_eye_objective": "Old Hollow-Eye's tentacles grab at the rail: hit it while it is surfaced",  # TUNING (not in GDD)
	"broadside_objective": "An enemy galleon runs out her guns: step out of the broadside's lines!",  # TUNING (not in GDD)
	"plank_objective": "Admiral Marrec crosses her plank: cut both hooks and she falls in the sea!",  # TUNING (not in GDD)
}

## Obstacle layout (keys as GraveyardStage.ARENA, plus "fixed"): THE DECK'S
## FURNITURE, a FIXED authored layout (Arena "fixed": each entry {kind, at, size
## (index into the kind's sizes), vertical}; at most one per 256 px arena cell,
## each at least ArenaData.CELL_MARGIN from its cell's edges, so the
## one-lookup push-out sees it), never scattered by hash. Kinds and sprites
## (EnvironmentArt, obstacles/<kind>_<size>[_v]): three masts (deck_mast_l),
## EIGHT DECK CANNONS (deck_cannon_l_v: their muzzles to the rails; GalleonDirector
## fires them for whoever mans them) and the QUARTERDECK STEPS (galleon_steps,
## code-drawn: the stair up to the quarterdeck at the stern, a choke the ring
## flows round). Hatches and lashed barrels are floor dressing
## (GalleonGround, no collision): a 256 px cell holds one obstacle.
const ARENA := {
	"density": 0.0,  # Unused: the layout is fixed.
	"clear_radius": 0.0,  # Unused: the layout is fixed.
	"layout_seed": 2829,  # Unused by a fixed layout (kept for the arena's keys).
	"fixed": [
		{"kind": "deck_cannon", "at": Vector2(-640.0, -150.0), "size": 1, "vertical": true},  # The quarterdeck's guns.
		{"kind": "deck_cannon", "at": Vector2(-640.0, 150.0), "size": 1, "vertical": true},
		{"kind": "galleon_steps", "at": Vector2(-384.0, -128.0), "size": 0, "vertical": true},  # The quarterdeck stair.
		{"kind": "deck_cannon", "at": Vector2(-384.0, 150.0), "size": 1, "vertical": true},
		{"kind": "deck_mast", "at": Vector2(-128.0, -128.0), "size": 1},  # The mizzen.
		{"kind": "deck_cannon", "at": Vector2(-128.0, 150.0), "size": 1, "vertical": true},
		{"kind": "deck_cannon", "at": Vector2(128.0, -150.0), "size": 1, "vertical": true},
		{"kind": "deck_mast", "at": Vector2(128.0, 128.0), "size": 1},  # The mainmast.
		{"kind": "deck_mast", "at": Vector2(384.0, -128.0), "size": 1},  # The foremast.
		{"kind": "deck_cannon", "at": Vector2(384.0, 150.0), "size": 1, "vertical": true},
		{"kind": "deck_cannon", "at": Vector2(600.0, -150.0), "size": 1, "vertical": true},  # The forecastle's chasers.
		{"kind": "deck_cannon", "at": Vector2(600.0, 150.0), "size": 1, "vertical": true},
	],
	"kinds": {
		"deck_mast": {"shape": "circle", "sizes": [14.0, 16.0]},  # TUNING (not in GDD) obstacles/deck_mast_l (38 x 51)
		"deck_cannon": {"shape": "rect", "sizes": [30.0, 36.0], "short": 18.0},  # TUNING (not in GDD) obstacles/deck_cannon_l_v (22 x 42)
		"galleon_steps": {"shape": "rect", "sizes": [96.0], "short": 26.0},  # TUNING (not in GDD) the quarterdeck stair (GalleonGlyphs, code-drawn)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS; her script is
## scripts/enemies/corsair/boss_marrec.gd, loaded by id).
const BOSS := {
	"id": "marrec",
	"time": BOSS_TIME,
	"display_name": "Admiral Isabeau Marrec, the Sea Wolf",
	"short_name": "Admiral Marrec",
	"arrive_banner": "Admiral Marrec's flagship runs out her guns!",
	"defeat_banner": "The Sea Wolf strikes her colours! Hold out until the end...",
	"dead_objective": "Admiral Marrec is beaten. Survive the Black Tide... you cannot.",
}

## The foundation stub's floor (CorsairGround "floor" key), kept for the tools
## that read it; the stage draws GalleonGround ("ground": the deck tile and the
## sea tile under the zone's tint).
const FLOOR := {
	"style": "dawn",  # The light over the sea (night / dawn / ghost).
	"sea": Palette.CORSAIR_SEA_DARK,  # TUNING (not in GDD) the water (code fallback)
	"foam": Palette.CORSAIR_FOAM,  # TUNING (not in GDD) the foam lines
	"plank": Palette.CORSAIR_OAK_LIGHT,  # TUNING (not in GDD) the deck (code fallback): the galleon's scrubbed oak
	"seam": Palette.CORSAIR_OAK,  # TUNING (not in GDD) the plank seams
	"rail": Palette.CORSAIR_OAK_DARK,  # TUNING (not in GDD) the rail
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Treasure Galleon",
	"short_name": "Galleon",
	"chapter": "Chapter XXIX",
	"act": 10,  # Act X (temporary): the Black Tide, final slot II after the reorder.
	"playable": false,  # Phase 2 built: the lead's integration flips the act live.
	"description": "A captured treasure galleon on open water at dawn, heavy with the gold of a hundred cathedrals, and the Brotherhood's whole fleet wants it back.",
	"unlock": {"stage": "cutter", "boss_kills": 1},  # Lead's plan: the chain runs Harvester -> Crow -> Marrec -> Vandermere
	"unlock_text": "Defeat Captain Crow on the Smuggler's Cutter to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None at sea.
	"consecration": {},  # A Covenant event: none at sea.
	"crypt_defender": {},  # None at sea.
	"arena": ARENA,
	"ground": "galleon",  # Act X phase 2: GalleonGround (the deck and sea tiles, the zones' looks, the floor dressing).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # The zones are GalleonDirector's (the map never changes at sea).
	"corsair": true,  # Act X: Boarding, the Deck, Strikes from the Sea (CorsairRules).
	"deck": DECK,  # Act X: this stage's deck (DeckBounds).
	"boarding": BOARDING,  # Act X: this stage's boarding points and tier cap (BoardingParty).
	"sea": SEA,  # Act X: this stage's sea strikes ({} = the defaults).
	"zones": ZONES,  # Act X: the zones (GalleonDirector).
	"galleon": GALLEON,  # Act X phase 2: GalleonDirector (broadsides, the deck cannons, Old Hollow-Eye, the zones).
	"music": "shanty",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
