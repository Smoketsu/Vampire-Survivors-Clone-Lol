## MaelstromStage — STAGE 30, THE MAELSTROM (Act X, the Black Tide, the
## temporary act number of the pirate act until the reorder pass moves it to
## slot II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)" and "The
## Maelstrom (Act X phase 2)"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Stage C: The Maelstrom (the
## finale)"). Every number and event that belongs to this stage. StageRegistry
## exposes it to the run as `Game.stage_def` (the STAGE dictionary at the
## bottom; its keys are documented in StageRegistry).
##
## The ghost ship Hollow Queen, caught in a whirlpool at midnight: a rotting
## deck of 1,300 x 500 px boarded along the whole rail by the full roster,
## ghost crews included. The Black Tide's three shared rules run here
## ("corsair": Boarding, the Deck, Strikes from the Sea) with the act's
## Reckoning; the stage adds (MaelstromDirector, STAGE "maelstrom"):
##   * THE HEAVE: the deck tilts toward a low side that flips every 12 s after
##     a 3 s creaking telegraph and a HUD arrow; everyone slides toward it at
##     30 px/s (the necromancer and the army stop at the rail; enemies are
##     carried by their knockback, so a blow at the low rail drowns them);
##   * THE BROTHERHOOD'S OWN DEAD: a ghost crewman falling on the deck near
##     the necromancer rises for him (HordeDirector.raise_corpse());
##   * THE GHOST BOSUN (the miniboss): his whistle brings a spectral longboat;
##   * CAPTAIN CORNELIUS VANDERMERE (boss_vandermere.gd): the Crew, the
##     Maelstrom and Dead Men's Oath (VandermereData).
## Four clock-driven zones (ZONES through MarchDirector): the Fog of Ships, the
## Gyre, the Eye of the Storm, the Drowned Helm. The boss arrives with 3:00
## left; the Reckoning, the Black Tide, at 0:00 (with the kraken).
## "playable": false until the lead's merge (the brief keeps it for the lead).
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

## Obstacle layout (keys as GraveyardStage.ARENA, plus "fixed"): THE DECK'S
## FURNITURE, a FIXED authored layout (Arena "fixed": each entry {kind, at, size
## (index into the kind's sizes), vertical}; at most one per 256 px arena cell,
## each at least ArenaData.CELL_MARGIN from its cell's edges, so the one-lookup
## push-out sees it), never scattered by hash, the same in every zone. The
## deck_* kinds draw the art pass's furniture (EnvironmentArt:
## obstacles/deck_<kind>_<s|l>[_v]; the art exists for the "l" size of the
## mast, hatch and cannon and both barrel sizes); the Hollow Queen's wheel keeps
## its code glyph (CorsairGlyphs: no wheel art was drawn).
const ARENA := {
	"density": 0.0,  # Unused: the layout is fixed.
	"clear_radius": 0.0,  # Unused: the layout is fixed.
	"layout_seed": 2830,  # Unused by a fixed layout (kept for the arena's keys).
	"fixed": [
		{"kind": "maelstrom_wheel", "at": Vector2(-600.0, -100.0), "size": 0},  # the Drowned Helm's wheel at the stern
		{"kind": "deck_mast", "at": Vector2(-128.0, -100.0), "size": 1},  # the mainmast
		{"kind": "deck_mast", "at": Vector2(384.0, 100.0), "size": 1},  # the foremast
		{"kind": "deck_barrels", "at": Vector2(128.0, -128.0), "size": 0},  # lashed powder
		{"kind": "deck_barrels", "at": Vector2(-384.0, 128.0), "size": 1},
		{"kind": "deck_hatch", "at": Vector2(384.0, -128.0), "size": 1},  # the fore hatch
		{"kind": "deck_cannon", "at": Vector2(-384.0, -150.0), "size": 1},  # dead guns along the rails
		{"kind": "deck_cannon", "at": Vector2(128.0, 150.0), "size": 1},
		{"kind": "deck_hatch", "at": Vector2(-128.0, 128.0), "size": 1, "vertical": true},  # the main hatch
	],
	"kinds": {
		"deck_mast": {"shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD) obstacles/deck_mast_l (38 x 51)
		"deck_hatch": {"shape": "rect", "sizes": [36.0, 44.0], "short": 30.0},  # TUNING (not in GDD) obstacles/deck_hatch_l (44 x 35) and _l_v
		"deck_barrels": {"shape": "circle", "sizes": [10.0, 16.0]},  # TUNING (not in GDD) obstacles/deck_barrels_s (30 x 21) / _l (40 x 48)
		"deck_cannon": {"shape": "rect", "sizes": [34.0, 40.0], "short": 18.0},  # TUNING (not in GDD) obstacles/deck_cannon_l (42 x 22)
		"maelstrom_wheel": {"shape": "circle", "sizes": [12.0]},  # TUNING (not in GDD) the helm (CorsairGlyphs: no art)
	},
}

## The four zones (the clock is authoritative; MarchDirector announces each and
## hands its "ground" to MaelstromGround; the deck and its furniture never
## change: every zone keeps ARENA). Keys as CrimsonMarchStage.ZONES, plus
## "heave": x the Heave's slide in this zone (MaelstromDirector: the Fog of
## Ships rolls gently, the Gyre heaves in full, the Eye of the Storm is level
## but the sea rises, the Drowned Helm heaves again).
const ZONES := [
	{"id": "fog_of_ships", "start": 0.0, "numeral": "I", "name": "The Fog of Ships",  # Owner-approved proposal (names)
		"blurb": "The Hollow Queen drifts through a fog full of lanterns, and every lantern is a boat",
		"ground": {"style": "fog", "sea_tint": Color(0.80, 0.90, 0.92)},  # TUNING (not in GDD) a pale fogged sea
		"arena": ARENA, "heave": 0.6},  # TUNING (not in GDD) times; a gentle roll
	{"id": "gyre", "start": 300.0, "numeral": "II", "name": "The Gyre",  # Owner-approved proposal (names)
		"blurb": "The whirlpool has her now: the deck heaves from rail to rail",
		"ground": {"style": "gyre", "sea_tint": Color(0.78, 1.0, 0.92)},  # TUNING (not in GDD) the ghost-green swirl
		"arena": ARENA, "heave": 1.0},  # TUNING (not in GDD)
	{"id": "eye_of_the_storm", "start": 600.0, "numeral": "III", "name": "The Eye of the Storm",  # Owner-approved proposal (names)
		"blurb": "The deck lies level in the eye, and everything that swims comes up to look",
		"ground": {"style": "eye", "sea_tint": Color(0.92, 0.96, 1.0)},  # TUNING (not in GDD) a still, moonlit sea
		"arena": ARENA, "heave": 0.0},  # TUNING (not in GDD) level: the sea strikes instead
	{"id": "drowned_helm", "start": 900.0, "numeral": "IV", "name": "The Drowned Helm",  # Owner-approved proposal (names)
		"blurb": "The far wall of the whirlpool: the helm turns by itself, and the dead stand to their posts",
		"ground": {"style": "helm", "sea_tint": Color(0.70, 0.95, 0.86)},  # TUNING (not in GDD) the darkest, greenest water
		"arena": ARENA, "heave": 1.0},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as ArkStage.MARCH: no road; the zone
## banner, its colour and the fog sweep). Every zone's "arena" is ARENA: the
## deck's furniture never moves.
const MARCH := {
	"transition_time": 1.4,  # TUNING (not in GDD)
	"transition_clear": 0.0,  # Unused by a fixed layout
	"zone_title": "INTO THE MAELSTROM  -  ZONE %s",
	"zone_color": Palette.CORSAIR_SPECTRE_LIGHT,  # The Hollow Queen's ghost-green.
	"fog_color": Color(0.03, 0.06, 0.08),  # The night over the whirlpool.
	"fog_bank_color": Color(0.30, 0.42, 0.40),  # Sea fog.
	"zones": ZONES,
}

## THE MAELSTROM's own rules (MaelstromDirector; GDD §15.0 "The Maelstrom (Act X
## phase 2)"):
##   heave — THE HEAVE (owner-approved proposal: "The whirlpool tilts the deck.
##           Everyone slides toward the low side at 30 px/s, and the low side
##           flips every 12 s with a 3 s creaking telegraph and a HUD arrow"):
##           speed (px/s the necromancer and the army slide, x Sea Legs for the
##           army), enemy_knock (px/s of knockback held on every deck enemy
##           toward the low rail: a blow there tips it over), period (s
##           between two flips), telegraph (s of creaking before a flip), first
##           (game s of the first heave), peak_mult / peak_period (Vandermere's
##           Maelstrom: the tilt peaks), lean (the autotest bot's push uphill),
##           chevrons (drawn arrows along the low rail).
##   raise — THE BROTHERHOOD'S OWN DEAD (owner-approved proposal: "Ghost crews
##           do leave corpses (they are the dead of the sea), so the
##           necromancer raises the Brotherhood's own dead here"): a ghost
##           crewman that falls on the deck within reach px of a standing
##           necromancer rises for him at once (HordeDirector.raise_corpse(), the
##           one raise path) as a temporary `class` for life s (hp_mult /
##           dmg_mult), at most cap at once; every raise chips Vandermere's Oath.
##   ghost_boats — the ghost boats circling the gyre (drawn only): count, the
##           px out from the hull, their turn rate (rad/s), alpha.
##   bosun — the Ghost Bosun's event (MaelstromDirector.start_event()): the
##           banner, the objective while he stands.
const MAELSTROM := {
	"heave": {
		"speed": 30.0,  # Owner-approved proposal: everyone slides toward the low side at 30 px/s
		"enemy_knock": 40.0,  # TUNING (not in GDD) px/s held on deck enemies (DeckBounds drowns from 70 px/s at the rail)
		"period": 12.0,  # Owner-approved proposal: the low side flips every 12 s
		"telegraph": 3.0,  # Owner-approved proposal: a 3 s creaking telegraph
		"first": 20.0,  # TUNING (not in GDD) game s of the first heave
		"peak_mult": 2.0,  # TUNING (not in GDD) Vandermere's Maelstrom: the tilt peaks (x speed and knock: 80 px/s drowns at the rail)
		"peak_period": 9.0,  # TUNING (not in GDD) s between flips while the tilt peaks
		"lean": 0.7,  # TUNING (not in GDD) the autotest bot's push uphill (danger_push units)
		"chevrons": 9,  # TUNING (not in GDD) arrows drawn along the low rail (visual only)
	},
	"raise": {
		"reach": 220.0,  # TUNING (not in GDD) px from a standing necromancer a ghost's fall rises
		"cap": 5,  # TUNING (not in GDD) raised ghosts at once (first pass 10: 838 raises in the seed-7 army run)
		"life": 7.0,  # TUNING (not in GDD) s a raised ghost stands
		"hp_mult": 0.8,  # TUNING (not in GDD) x the class's HP
		"dmg_mult": 0.8,  # TUNING (not in GDD) x the class's damage
		"class": "warrior",  # TUNING (not in GDD) GraveSpellData's risen class (the Death Mark Risen, Raise Dead)
		"tag": "hollow_risen",  # Damage-source tag of a raised ghost (CombatResolver stats)
	},
	"ghost_boats": {"count": 4, "out": 210.0, "turn": 0.07, "alpha": 0.45},  # TUNING (not in GDD) visual only
	"bosun": {
		"objective": "The Ghost Bosun whistles up his crew: cut him down",  # TUNING (not in GDD)
	},
}

## THE DECK of this stage (DeckBounds; any CorsairRulesData.DECK key; the rest
## are its defaults). Owner-approved proposal: the Hollow Queen's deck, 1,300 x 500 px, rotting.
const DECK := {"length": 1300.0, "beam": 500.0, "bow": 190.0, "bow_tip": 56.0, "stern_cut": 56.0}  # Owner-approved proposal: the Hollow Queen's deck, 1,300 x 500 px, rotting

## BOARDING on this stage (BoardingParty; any CorsairRulesData.BOARDING key):
## "points" lists the boarding points as [x along the deck (px from its centre),
## side (-1 = the upper rail, +1 = the lower rail)]; "whole_rail": true lets a
## boat come alongside anywhere on the straight rail; "boats" is the tier cap
## (the sizes allowed, CorsairRulesData.BOAT_ORDER).
const BOARDING := {"points": [], "whole_rail": true, "boats": ["skiff", "longboat", "raider_ship"],  # Owner-approved proposal: boarding points: the whole rail; tier cap: the full roster
	"max_boats": 6, "min_crew": 4, "max_wait": 2.0, "pour_every": 0.45}  # TUNING (not in GDD) phase 2: the finale's traffic (the stubs held 6-16 on deck): more boats at once, sooner, faster

## STRIKES FROM THE SEA on this stage (SeaStrikes; any CorsairRulesData.SEA key;
## {} = the defaults).
const SEA := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): THE BLACK
## TIDE, shared by every stage of the act: every boat closes at once and the
## whole rail boards, the rail band is struck every 3 s, a great wave shoves
## everything toward the far rail every 20 s and the kraken surfaces
## ("black_tide": CorsairRulesData.BLACK_TIDE keys).
const RECKONING := {
	"banner": "THE BLACK TIDE: THE WHIRLPOOL GIVES UP ITS DEAD",
	"kind": CorsairEnemyData.RECKONING_KIND,  # The Black Tide's heavy (the Boarding Bruiser), by boat.
	"black_tide": {"kraken_every": 24.0},  # TUNING (not in GDD) the finale: the kraken comes up more often
	"companions": [
		{"kind": "deckhand", "count": 8, "growth": 2.0},  # TUNING (not in GDD) a boat's crew
		{"kind": "ghost_deckhand", "count": 6, "growth": 1.5},  # TUNING (not in GDD) the Hollow Queen's dead
		{"kind": "musketeer", "count": 3, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": "powder_runner", "count": 2, "growth": 0.5},  # TUNING (not in GDD)
		{"kind": "swashbuckler", "count": 1, "growth": 0.34},  # TUNING (not in GDD)
	],
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) bruisers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE BLACK TIDE: the whole rail boards and the kraken rises. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS). Every spawn
## comes aboard by boat (BoardingParty) or from the sea (SeaStrikes: the sharks,
## the serpents, the kraken). The finale's pressure is its traffic: more boats,
## more crew (phase 2 raised the stubs' rates and caps; HP stays the act's).
const SEGMENTS := [
	{"start": 0.0, "rate": 2.2, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.9, "musketeer": 0.1},
		"objective": "Lanterns in the fog: every one is a boat. Watch the rail"},
	{"start": 60.0, "rate": 2.7, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.72, "musketeer": 0.2, "powder_runner": 0.08},
		"objective": "Cut both grapple hooks and the boat drifts off with its crew"},
	{"start": 180.0, "rate": 3.2, "max_alive": 78,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.5, "ghost_deckhand": 0.16, "musketeer": 0.16, "powder_runner": 0.08, "reef_shark": 0.06, "ghost_gunner": 0.04},
		"objective": "The drowned board too: cut them down near you and they rise for you"},
	{"start": 300.0, "rate": 3.7, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.42, "ghost_deckhand": 0.2, "musketeer": 0.14, "ghost_gunner": 0.06, "powder_runner": 0.07, "swashbuckler": 0.05, "reef_shark": 0.04, "corsair_serpent": 0.02},
		"objective": "The deck heaves: lean uphill, and knock them over the low rail"},
	{"start": 600.0, "rate": 4.1, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.36, "ghost_deckhand": 0.22, "musketeer": 0.12, "ghost_gunner": 0.08, "powder_runner": 0.07, "swashbuckler": 0.06, "boarding_bruiser": 0.02, "reef_shark": 0.04, "corsair_serpent": 0.03},
		"objective": "The eye of the storm: the deck is level, and the sea comes up to look"},
	{"start": 900.0, "rate": 4.5, "max_alive": 120,  # TUNING (not in GDD)
		"weights": {"deckhand": 0.32, "ghost_deckhand": 0.26, "musketeer": 0.1, "ghost_gunner": 0.1, "powder_runner": 0.07, "swashbuckler": 0.07, "boarding_bruiser": 0.03, "reef_shark": 0.03, "corsair_serpent": 0.02},
		"objective": "The dead stand to their posts at the helm"},
	{"start": BOSS_TIME, "rate": 3.4, "max_alive": 90,  # TUNING (not in GDD) thinner during the boss fight (his crew comes by his own boats)
		"weights": {"deckhand": 0.4, "ghost_deckhand": 0.3, "musketeer": 0.12, "ghost_gunner": 0.1, "powder_runner": 0.08},
		"objective": "Vandermere has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Every group comes
## aboard by boat (BoardingParty) or from the sea (SeaStrikes); the
## "ghost_bosun" event is MaelstromDirector's (the miniboss climbs over the rail).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "Two longboats out of the fog!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 14, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "Musketeers in the boats!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "musketeer", "count": 5, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "Fins in the water! The sharks are circling!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "reef_shark", "count": 3, "elite": false}]},
	{"time": 200.0, "type": "wave", "banner": "Ghost boats in the fog! The drowned are boarding!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ghost_deckhand", "count": 12, "elite": false}, {"kind": "ghost_gunner", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "Lit kegs! Powder runners are coming over the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "powder_runner", "count": 4, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "A sea serpent coils round the hull! Step out of its line!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "corsair_serpent", "count": 1, "elite": false}, {"kind": "deckhand", "count": 10, "elite": false}]},
	{"time": 420.0, "type": "wave", "banner": "A kraken arm rises at the rail!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 1, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}, {"kind": "ghost_deckhand", "count": 10, "elite": false}]},
	{"time": 510.0, "type": "ghost_bosun", "kind": MaelstromEnemyData.GHOST_BOSUN,  # TUNING (not in GDD) the miniboss (MaelstromDirector)
		"banner": "The Ghost Bosun climbs over the rail, his whistle at his lips!"},
	{"time": 610.0, "type": "wave", "banner": "In the eye of the storm, the sea rises to look!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "corsair_serpent", "count": 2, "elite": false}, {"kind": "kraken_arm", "count": 1, "elite": false}, {"kind": "reef_shark", "count": 2, "elite": false}]},
	{"time": 690.0, "type": "wave", "banner": "Duellists of the Brotherhood board!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "swashbuckler", "count": 3, "elite": false}, {"kind": "boarding_bruiser", "count": 1, "elite": false}, {"kind": "deckhand", "count": 12, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "The living and the drowned board together!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "deckhand", "count": 12, "elite": false}, {"kind": "ghost_deckhand", "count": 12, "elite": false}, {"kind": "ghost_gunner", "count": 4, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "The kraken reaches for your dead!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "kraken_arm", "count": 2, "elite": false}, {"kind": "corsair_serpent", "count": 1, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The Hollow Queen's dead stand to their posts!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ghost_deckhand", "count": 16, "elite": false}, {"kind": "ghost_gunner", "count": 5, "elite": false}, {"kind": "boarding_bruiser", "count": 1, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The captain's own crew comes first!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "boarding_bruiser", "count": 2, "elite": false}, {"kind": "ghost_deckhand", "count": 12, "elite": false}]},
]

## The stage boss's arrival (keys as GraveyardStage.BOSS): Captain Cornelius
## Vandermere (boss_vandermere.gd; VandermereData.ARRIVAL).
const BOSS: Dictionary = VandermereData.ARRIVAL

## Fallback look for any caller of "floor" (MaelstromGround draws the art
## pass's tiles: tiles/corsair_maelstrom on the deck, tiles/corsair_water round
## it, tinted per zone; these colours only when a tile is missing).
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
	"playable": false,  # Left for the lead's merge (brief docs/tide/BRIEF_PHASE2.md: the stage agents keep it).
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
	"ground": "maelstrom",  # MaelstromGround: the art pass's deck and sea tiles, tinted per zone.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector; every zone keeps ARENA).
	"corsair": true,  # Act X: Boarding, the Deck, Strikes from the Sea (CorsairRules).
	"deck": DECK,  # Act X: this stage's deck (DeckBounds).
	"boarding": BOARDING,  # Act X: this stage's boarding points and tier cap (BoardingParty).
	"sea": SEA,  # Act X: this stage's sea strikes ({} = the defaults).
	"zones": ZONES,  # Act X: the zones (MarchDirector reads them through "march").
	"maelstrom": MAELSTROM,  # Act X, the Maelstrom: the Heave, the raised ghost crew, the Ghost Bosun (MaelstromDirector).
	"music": "shanty",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
