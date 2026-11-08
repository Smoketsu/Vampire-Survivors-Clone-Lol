## CutterStage — STAGE 28, THE SMUGGLER'S CUTTER (Act X, the Black Tide, the
## temporary act number of the pirate act until the reorder pass moves it to
## slot II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)" and "The
## Smuggler's Cutter (Act X phase 2)", owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Stage A"). A small night-time
## sloop slips out of a ruined harbour, the Covenant's coast burning behind it,
## and the Corsair Brotherhood comes for her in small boats. Every number and
## event that belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## STATUS: BUILT (phase 2). It runs the Black Tide's three shared rules
## ("corsair": true: Boarding, the Deck and Strikes from the Sea) on its own
## deck (960 x 360, the camera still) with two boarding points per side and
## skiffs and longboats only, a FIXED furniture layout (the art pass's deck
## mast, hatch, cannons and lashed barrels), and its own systems
## (CutterDirector, STAGE "cutter"): POWDER BARRELS along the rails restocked
## every zone (any hit sets one off: both sides hit, everyone knocked 120 px,
## overboard at the rail), THE FOG BANK (boats show their lane only for its
## last 2 s), BOSUN GORRAN AND THE RAM LONGBOAT (the miniboss, at 11:00: the
## ram staggers the whole army back), NOT ONE ABOARD. Its boss is Captain
## Ezekiel Crow, the Gull King (BossCrow: Broadside, the Duel, the Fire Ship).
## Its timeline adds the shared Grappler and Boatswain. The Black Tide is its
## Reckoning. Playable since the act went live (integration).
## Zones (ZONES; clock-driven, MarchDirector; the camera does not move: the
## zones change the look and the timeline, not the map): the Harbour Mouth,
## Open Water, the Fog Bank, the Cove.
## Captain Crow arrives with 3:00 left; the Reckoning at 0:00.
## Every rate, cap and weight is TUNING (not in GDD).
class_name CutterStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "cutter"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
## Tuned for the act's FINAL slot II (docs/last_acts/PLAN.md): a step above the
## Sanctum (1.1), well below the Sanguine Court (1.85): an early act.
const ENEMY_HP_MULT: float = 1.3  # TUNING (not in GDD) placeholder for slot II, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.15  # TUNING (not in GDD) placeholder for slot II (the Sanctum 1.1, Ravensmoor 1.5)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00 (Acts III to IX)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 1 of the act

## Obstacle layout (keys as GraveyardStage.ARENA, plus "fixed"): THE DECK'S
## FURNITURE, a FIXED authored layout (Arena "fixed": each entry {kind, at, size
## (index into the kind's sizes)}; at most one per 256 px arena cell, each at
## least ArenaData.CELL_MARGIN from its cell's edges, so the one-lookup
## push-out sees it), never scattered by hash. The kinds are the art pass's
## deck furniture (obstacles/deck_<kind>_<size>, docs/tide/ART_MANIFEST.md): a
## kind with two sizes names its sprites _s / _l, so the single mast, hatch and
## cannon use their size 1 (_l), the lashed barrels both. Every zone keeps it
## (the camera and the map do not move).
const ARENA := {
	"density": 0.0,  # Unused: the layout is fixed.
	"clear_radius": 0.0,  # Unused: the layout is fixed.
	"layout_seed": 2828,  # Unused by a fixed layout (kept for the arena's keys).
	"fixed": [
		{"kind": "deck_mast", "at": Vector2(128.0, -80.0), "size": 1},  # Owner-approved proposal: the single mast
		{"kind": "deck_hatch", "at": Vector2(-128.0, 84.0), "size": 1},  # Owner-approved proposal: one hatch
		{"kind": "deck_barrels", "at": Vector2(-384.0, -104.0), "size": 1},  # lashed powder barrels (furniture)
		{"kind": "deck_barrels", "at": Vector2(360.0, 90.0), "size": 0},
		{"kind": "deck_barrels", "at": Vector2(-384.0, 110.0), "size": 0},
		{"kind": "deck_cannon", "at": Vector2(-128.0, -110.0), "size": 1},  # a deck gun
		{"kind": "deck_cannon", "at": Vector2(128.0, 110.0), "size": 1},
	],
	"kinds": {
		"deck_mast": {"shape": "circle", "sizes": [12.0, 14.0]},  # TUNING (not in GDD) the 38 x 51 mast art (size 1 = _l)
		"deck_hatch": {"shape": "rect", "sizes": [36.0, 44.0], "short": 28.0},  # TUNING (not in GDD) the 44 x 35 hatch art (size 1 = _l)
		"deck_barrels": {"shape": "circle", "sizes": [10.0, 14.0]},  # TUNING (not in GDD) the 30 x 21 (_s) and 40 x 48 (_l) barrel art
		"deck_cannon": {"shape": "rect", "sizes": [34.0, 40.0], "short": 16.0},  # TUNING (not in GDD) the 42 x 22 cannon art (size 1 = _l)
	},
}

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): the same fixed deck ("arena"), its
## own look ("ground", CutterGround: sea_tint a flat rect over the water,
## deck_tint the plank tile's modulate, light the water's own light: the
## burning coast, none, the cove's cliffs) and its own part of the timeline:
##   harbour_mouth — the Harbour Mouth: the Covenant's coast burns behind; the
##                   first skiffs.
##   open_water    — Open Water: plain night, the longboats and the Boatswains.
##   fog_bank      — the Fog Bank: boats show their lane only for its last 2 s
##                   (CutterDirector); Bosun Gorran's ram comes out of it.
##   cove          — the Cove: dark cliffs on both sides; Captain Crow waits.
const ZONES := [
	{"id": "harbour_mouth", "name": "The Harbour Mouth", "start": 0.0, "numeral": "I",  # Owner-approved proposal (names); TUNING (not in GDD) times
		"blurb": "The Covenant's coast burns behind you",
		"arena": ARENA,
		"ground": {"style": "night", "sea_tint": Color(0.10, 0.04, 0.0, 0.18), "deck_tint": Color(1.0, 0.92, 0.82), "light": "coast_fire"}},  # TUNING (not in GDD) the look
	{"id": "open_water", "name": "Open Water", "start": 300.0, "numeral": "II",  # Owner-approved proposal (names); TUNING (not in GDD) times
		"blurb": "Nothing but black water, and the boats on it",
		"arena": ARENA,
		"ground": {"style": "night", "sea_tint": Color(0, 0, 0, 0), "deck_tint": Color.WHITE, "light": ""}},  # TUNING (not in GDD) the look
	{"id": "fog_bank", "name": "The Fog Bank", "start": 600.0, "numeral": "III",  # Owner-approved proposal (names); TUNING (not in GDD) times
		"blurb": "Watch the rail: the boats come out of the fog",
		"arena": ARENA,
		"ground": {"style": "night", "sea_tint": Color(0.55, 0.60, 0.66, 0.14), "deck_tint": Color(0.86, 0.88, 0.92), "light": ""}},  # TUNING (not in GDD) the look
	{"id": "cove", "name": "The Cove", "start": 900.0, "numeral": "IV",  # Owner-approved proposal (names); TUNING (not in GDD) times
		"blurb": "Black cliffs on both sides, and a sloop waiting",
		"arena": ARENA,
		"ground": {"style": "night", "sea_tint": Color(0.0, 0.08, 0.06, 0.22), "deck_tint": Color(0.84, 0.92, 0.88), "light": "cove"}},  # TUNING (not in GDD) the look
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 0.0,  # The fixed deck: nothing is rebuilt round the necromancer.
	"zone_title": "THE SMUGGLER'S CUTTER  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.949, 0.651, 0.227),  # Lantern amber (Palette.CORSAIR_LANTERN), the act's telegraph colour.
	"fog_color": Color(0.05, 0.07, 0.13),  # Night over the water.
	"fog_bank_color": Color(0.55, 0.58, 0.62),  # Sea fog.
	"zones": ZONES,
}

## THE DECK of this stage (DeckBounds; any CorsairRulesData.DECK key; the rest
## are its defaults). Owner-approved proposal: a deck 960 x 360 px, a single mast, one hatch, powder barrels along the rails.
const DECK := {"length": 960.0, "beam": 360.0, "bow": 150.0, "bow_tip": 46.0, "stern_cut": 44.0}  # Owner-approved proposal: a deck 960 x 360 px, a single mast, one hatch, powder barrels along the rails

## BOARDING on this stage (BoardingParty; any CorsairRulesData.BOARDING key):
## "points" lists the boarding points as [x along the deck (px from its centre),
## side (-1 = the upper rail, +1 = the lower rail)]; "boats" is the tier cap
## (the sizes allowed, CorsairRulesData.BOAT_ORDER); "first_pour" the seconds
## from hooking to the first crewman (the Cutter's: the crew climbs the hooks,
## the window for a clean sink, Not One Aboard).
const BOARDING := {"points": [[-200.0, -1], [160.0, -1], [-200.0, 1], [160.0, 1]], "boats": ["skiff", "longboat"],  # Owner-approved proposal: two boarding points per side; tier cap skiffs and longboats
	"first_pour": 1.0,  # TUNING (not in GDD) s (the other stages: half a pour, 0.3 s)
	"leave_time": 1.0,  # TUNING (not in GDD) s an emptied boat takes to cast off (the shared 2.5): the next boat comes sooner
	"min_crew": 4,  # TUNING (not in GDD) crew a queue gathers before a boat launches (fuller boats: more boarders at once)
}

## STRIKES FROM THE SEA on this stage (SeaStrikes; any CorsairRulesData.SEA key;
## {} = the defaults).
const SEA := {}

## THE SMUGGLER'S CUTTER's stage systems (CutterDirector; StageRegistry "cutter").
##   barrels         — the powder barrels' spots, [x along the deck (px from
##                     its centre), side (-1 upper rail, +1 lower)], restocked
##                     at the start of every zone (owner-approved proposal:
##                     "powder barrels along the rails").
##   barrel_inset    — px inside the rail a barrel stands.
##   barrel_avoid    — px past a standing barrel's blast radius the autotest
##                     bot keeps away (CutterDirector.danger_push(); hint only).
##   fog_zone        — the zone id whose boats hide their lane.
##   fog_reveal      — s of lane a boat shows in the fog (owner-approved
##                     proposal: "hides boats until 2 s before").
##   fog_wisps       — fog banks drawn over the water (visual).
##   ram             — Bosun Gorran's ram longboat: lane_time (s its lane
##                     shows), push (px the ram knocks every summon), stagger
##                     (s each is stunned), damage (each takes, before the
##                     time scaling), first_pour / pour_every (s), leave_time
##                     (s it waits empty before it casts off).
##   gorran_objective — HUD objective while Gorran stands.
##   fire            — Captain Crow's Fire Ship: push / stagger of its ram,
##                     first (s to the first patch), every (s between patches),
##                     radius (px), life (s a patch burns), telegraph (s it
##                     glows), dist_min / dist_max (px from the necromancer),
##                     show (s the burning hulk is drawn alongside).
##   not_one_aboard  — clean sinks a run needs for Not One Aboard.
const CUTTER := {
	"barrels": [[-330.0, -1], [-40.0, -1], [300.0, -1], [-330.0, 1], [-40.0, 1], [300.0, 1]],  # Owner-approved proposal: along the rails; TUNING (not in GDD) the spots
	"barrel_inset": 16.0,  # TUNING (not in GDD) px
	"barrel_avoid": 20.0,  # TUNING (not in GDD) px past a barrel's blast the autotest bot keeps (autotest hint only)
	"fog_zone": "fog_bank",  # Owner-approved proposal: the fog zone hides the boats
	"fog_reveal": 2.0,  # Owner-approved proposal: 2 s
	"fog_wisps": 10,  # TUNING (not in GDD) visual
	"ram": {"lane_time": 3.0, "push": 90.0, "stagger": 0.6, "damage": 4.0, "first_pour": 0.6, "pour_every": 0.5, "leave_time": 2.5},  # Owner-approved proposal: "rams the hull (a stagger that knocks every summon back)"; TUNING (not in GDD) the numbers
	"gorran_objective": "Bosun Gorran is aboard: bring him down before his crew swarms the deck",  # TUNING (not in GDD)
	"fire": {"push": 60.0, "stagger": 0.35, "first": 1.0, "every": 2.4, "radius": 30.0, "life": 7.0, "telegraph": 0.9,  # TUNING (not in GDD)
		"dist_min": 50.0, "dist_max": 170.0, "show": 8.0},  # Owner-approved proposal: "burning planks spread as short fire patches"; TUNING (not in GDD) the numbers
	"not_one_aboard": 5,  # Owner-approved proposal: "sink five boats before a single crewman climbs aboard"
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): THE BLACK
## TIDE, shared by every stage of the act: every boat closes at once and the
## whole rail boards, the rail band is struck every 3 s and a great wave shoves
## everything toward the far rail every 20 s ("black_tide":
## CorsairRulesData.BLACK_TIDE keys; {} = those defaults).
const RECKONING := {
	"banner": "THE BLACK TIDE: EVERY BOAT IN THE SEA CLOSES ON YOU",
	"kind": CorsairEnemyData.RECKONING_KIND,  # The Black Tide's heavy (the Boarding Bruiser), by boat.
	"black_tide": {},  # CorsairRulesData.BLACK_TIDE defaults.
	"companions": CorsairEnemyData.RECKONING_COMPANIONS,  # Crews, kegs and duellists.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) bruisers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE BLACK TIDE: the whole rail boards and the sea strikes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS). Every spawn
## comes aboard by boat (BoardingParty) or from the sea (SeaStrikes: the
## sharks). Phase 2: much heavier boat traffic than the stub (the stub's deck
## held only 6-16 boarders: the pressure comes from the boarders, not from HP),
## the Grappler from 2:00 and the Boatswain from 5:00.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD) first pass 1.6 / 34 (the opening is the army's weakest minutes)
		"weights": {"deckhand": 1.0},
		"objective": "Boats pull alongside: watch the amber lanterns at the rail"},
	{"start": 50.0, "rate": 1.8, "max_alive": 38,  # TUNING (not in GDD) first pass 2.1 / 44
		"weights": {"deckhand": 0.86, "musketeer": 0.14},
		"objective": "Cut both grapple hooks and the boat drifts off with its crew"},
	{"start": 120.0, "rate": 2.1, "max_alive": 44,  # TUNING (not in GDD) first pass 2.5 / 52 with powder runners (the seed-1 army bot fell to 18% at 2:00-5:00: kegs and musket shot)
		"weights": {"deckhand": 0.78, "musketeer": 0.14, "grappler": 0.08},
		"objective": "Break a powder barrel when they crowd the rail: the blast throws them overboard"},
	{"start": 210.0, "rate": 2.4, "max_alive": 50,  # TUNING (not in GDD) first pass 2.8 / 58
		"weights": {"deckhand": 0.68, "musketeer": 0.15, "grappler": 0.07, "powder_runner": 0.04, "reef_shark": 0.06},
		"objective": "Knock them over the rail and they drown: knockback is your friend"},
	{"start": 300.0, "rate": 2.9, "max_alive": 62,  # TUNING (not in GDD) first pass 3.1 / 66
		"weights": {"deckhand": 0.53, "musketeer": 0.18, "grappler": 0.08, "boatswain": 0.05, "powder_runner": 0.07, "swashbuckler": 0.04, "reef_shark": 0.05},
		"objective": "Boatswains bellow their crews on: cut them down first"},
	{"start": 600.0, "rate": 3.4, "max_alive": 74,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.5, "musketeer": 0.17, "grappler": 0.09, "boatswain": 0.06, "powder_runner": 0.07, "swashbuckler": 0.05, "boarding_bruiser": 0.02, "reef_shark": 0.04},
		"objective": "Watch the rail: the boats come out of the fog"},
	{"start": 900.0, "rate": 3.7, "max_alive": 82,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.48, "musketeer": 0.17, "grappler": 0.09, "boatswain": 0.06, "powder_runner": 0.08, "swashbuckler": 0.06, "boarding_bruiser": 0.03, "reef_shark": 0.03},
		"objective": "The whole Brotherhood is on the water"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 60,  # TUNING (not in GDD) thinner during the boss fight (his own crew boards double)
		"weights": {"deckhand": 0.6, "musketeer": 0.18, "grappler": 0.06, "powder_runner": 0.08, "swashbuckler": 0.04, "reef_shark": 0.04},
		"objective": "Captain Crow has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Every "wave"
## group comes aboard by boat (BoardingParty) or from the sea (SeaStrikes);
## the "gorran" event is CutterDirector's (Bosun Gorran's own ram longboat:
## "escort" lists the crew after him).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A longboat pulls alongside!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 12, "elite": false}]},
	{"time": 100.0, "type": "wave", "banner": "Musketeers in the boats!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "musketeer", "count": 3, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},  # first pass 5 musketeers
	{"time": 150.0, "type": "wave", "banner": "Grapplers! They will drag your dead to the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "grappler", "count": 4, "elite": false}, {"kind": "deckhand", "count": 8, "elite": false}]},
	{"time": 190.0, "type": "wave", "banner": "Fins in the water! The sharks are circling!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "reef_shark", "count": 3, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "Lit kegs! Powder runners are coming over the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "powder_runner", "count": 3, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},  # first pass 4 runners
	{"time": 330.0, "type": "wave", "banner": "A Boatswain bellows his crew aboard!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "boatswain", "count": 2, "elite": false}, {"kind": "deckhand", "count": 14, "elite": false}]},
	{"time": 400.0, "type": "wave", "banner": "A kraken arm rises at the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 1, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 460.0, "type": "wave", "banner": "Duellists of the Brotherhood board!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "swashbuckler", "count": 3, "elite": false}, {"kind": "deckhand", "count": 12, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Boats on both rails!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 16, "elite": false}, {"kind": "musketeer", "count": 6, "elite": false}, {"kind": "grappler", "count": 3, "elite": false}]},
	{"time": 615.0, "type": "wave", "banner": "Shapes in the fog! Watch the rail!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 14, "elite": false}, {"kind": "powder_runner", "count": 4, "elite": false}]},
	{"time": 660.0, "type": "gorran", "banner": "A RAM LONGBOAT! Bosun Gorran is coming through the hull!",  # TUNING (not in GDD) the miniboss at 11:00
		"escort": [{"kind": "deckhand", "count": 10}, {"kind": "boatswain", "count": 1}, {"kind": "boarding_bruiser", "count": 1}]},  # TUNING (not in GDD)
	{"time": 760.0, "type": "wave", "banner": "The kraken reaches for your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 2, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 840.0, "type": "wave", "banner": "A Boarding Bruiser leads the next crew!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 2, "elite": false}, {"kind": "deckhand", "count": 12, "elite": false}, {"kind": "grappler", "count": 3, "elite": false}]},
	{"time": 920.0, "type": "wave", "banner": "The Brotherhood boards from every side!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 16, "elite": false}, {"kind": "swashbuckler", "count": 3, "elite": false}, {"kind": "musketeer", "count": 5, "elite": false}, {"kind": "boatswain", "count": 2, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The captain's own crew comes first!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 2, "elite": false}, {"kind": "deckhand", "count": 14, "elite": false}]},
]

## The stage boss's arrival: Captain Ezekiel Crow (CrowData.ARRIVAL; boss id
## "crow", BossCrow in scripts/enemies/corsair/boss_crow.gd).
const BOSS: Dictionary = CrowData.ARRIVAL

## The code look under the tiles (CorsairGround's keys; CutterGround draws the
## art pass's sea and plank tiles over it and falls back to it without them).
const FLOOR := {
	"style": "night",  # The light over the sea (night / dawn / ghost).
	"sea": Palette.CORSAIR_SEA_DARK,  # TUNING (not in GDD) the water
	"foam": Palette.CORSAIR_FOAM,  # TUNING (not in GDD) the foam lines
	"plank": Palette.CORSAIR_OAK,  # TUNING (not in GDD) the deck
	"seam": Palette.CORSAIR_OAK_DARK,  # TUNING (not in GDD) the plank seams
	"rail": Palette.CORSAIR_OAK_LIGHT,  # TUNING (not in GDD) the rail
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Smuggler's Cutter",
	"short_name": "Cutter",
	"chapter": "Chapter XXVIII",
	"act": 10,  # Act X (temporary): the Black Tide, final slot II after the reorder.
	"playable": true,  # The Black Tide goes live (integration, GDD §15.0 "The Black Tide goes live (integration and balance)").
	"description": "A small night-time sloop slips out of a ruined harbour with the Covenant's coast burning behind it, and the Corsair Brotherhood comes for her in small boats.",
	"unlock": {"stage": "ark", "boss_kills": 1},  # Lead's plan: the chain runs Harvester -> Crow -> Marrec -> Vandermere
	"unlock_text": "Defeat the Harvester on the Ark of the Concord to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None at sea.
	"consecration": {},  # A Covenant event: none at sea.
	"crypt_defender": {},  # None at sea.
	"arena": ARENA,
	"ground": "cutter",  # CutterGround: the tiled sea and deck, a look per zone.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"corsair": true,  # Act X: Boarding, the Deck, Strikes from the Sea (CorsairRules).
	"deck": DECK,  # Act X: this stage's deck (DeckBounds).
	"boarding": BOARDING,  # Act X: this stage's boarding points and tier cap (BoardingParty).
	"sea": SEA,  # Act X: this stage's sea strikes ({} = the defaults).
	"zones": ZONES,  # Act X: the four zones.
	"cutter": CUTTER,  # Act X, the Cutter: barrels, fog, Gorran's ram, the Fire Ship, Not One Aboard (CutterDirector).
	# Music key "tide" FOR NOW (Act II's "Below the Tide"): the parallel audio
	# pass adds the act's own score (key "shanty", pack "corsair") and the lead
	# switches this to "shanty" at the merge.
	"music": "shanty",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
