## CorsairRulesData — the numbers of THE BLACK TIDE's shared rules (Act X, the
## temporary act number of the pirate act until the reorder pass, which moves
## it to slot II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 and
## docs/proposals/LAST_SIX_ACTS.md "II. The Black Tide"). Read by
## CorsairRules (Game.corsair) and its parts: DeckBounds (THE DECK),
## BoardingParty (BOARDING), SeaStrikes (STRIKES FROM THE SEA) and BlackTide
## (the shared Reckoning). A stage overrides any key through its STAGE
## dictionary ("deck", "boarding", "sea"; the RECKONING "black_tide"). No
## logic here. The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal.
class_name CorsairRulesData
extends RefCounted

## Damage source tag of a sea strike's circle (CombatResolver stats:
## summon_dmg_from_sea_strike, player_dmg_from_sea_strike).
const STRIKE_SOURCE: String = "sea_strike"
## Damage source tag of an enemy drowned overboard (DeckBounds; the drowning
## blow goes through CombatResolver.damage_enemy(), the one kill path).
const DROWN_SOURCE: String = "overboard"
## Damage source tag of a powder keg's blast (PowderRunnerKit; it hurts both sides).
const POWDER_SOURCE: String = "powder_blast"
## Damage source tag of the Black Tide's great wave (BlackTide).
const WAVE_SOURCE: String = "black_tide_wave"
## Stun source tag of a tentacle's grab (CombatResolver.stun_unit()).
const GRAB_SOURCE: String = "tentacle_grab"

# --- The Deck ------------------------------------------------------------------------

## THE DECK (DeckBounds; owner-approved proposal "The Deck"): the walkable
## shape, a convex outline in arena coordinates around `center`: a rectangle
## `length` x `beam` px with a tapered BOW at +x (the half-beam narrows over
## the last `bow` px to `bow_tip`) and a chamfered STERN at -x (`stern_cut` px
## corners). A stage's STAGE "deck" overrides any key (the Cutter 960 x 360,
## the Galleon 1500 x 540, the Hollow Queen 1300 x 500: the proposal).
const DECK := {
	"center": Vector2.ZERO,  # World px; the run starts at the origin, mid-deck.
	"length": 960.0,  # TUNING (not in GDD) px, stern to bow (owner-approved proposal: the Cutter's 960)
	"beam": 360.0,  # TUNING (not in GDD) px, rail to rail (owner-approved proposal: the Cutter's 360)
	"bow": 150.0,  # TUNING (not in GDD) px of hull over which the bow narrows
	"bow_tip": 46.0,  # TUNING (not in GDD) px, half-beam at the very tip of the bow
	"stern_cut": 44.0,  # TUNING (not in GDD) px, the stern's chamfered corners
	"flier_band": 120.0,  # Owner-approved proposal: fliers may hover up to 120 px past the rail
	"rail_band": 120.0,  # Owner-approved proposal: the strikes' rail band, 120 px inside the rail
	"drown_knock": 70.0,  # TUNING (not in GDD) px/s of OUTWARD knockback that tips a deck enemy at the rail overboard
	"drown_slack": 3.0,  # TUNING (not in GDD) px a deck enemy's centre may be pushed past the rail line before it falls in
	"drown_hp_mult": 60.0,  # TUNING (not in GDD) x max HP of the drowning blow (DivineWrath's "drowned outright" precedent)
	"contain_interval": 30,  # TUNING (not in GDD) ticks between two passes that move drops off the water
	"water_margin": 140.0,  # TUNING (not in GDD) px of sea the camera shows past the deck on a scrolling deck
	"rail_avoid": 110.0,  # TUNING (not in GDD) px: the autotest bot is pushed off the rail inside this (danger_push)
}

# --- Boarding ------------------------------------------------------------------------

## BOARDING (BoardingParty; owner-approved proposal "Boarding"): boats show
## their lane, hook the rail with two grapple lines (each a 40 HP structure)
## and pour one crewman every pour_every s. Cut both hooks: the boat drifts off
## for drift_time s and its remaining crew is cancelled. Sink the hull: its
## remaining crew drowns (no XP) and one floating crate of loot (crate_xp)
## washes against the rail. A stage's STAGE "boarding" overrides any key.
const BOARDING := {
	"lane_time": 3.0,  # Owner-approved proposal: a boat shows its lane 3 s ahead
	"pour_every": 0.6,  # Owner-approved proposal: one crewman every 0.6 s once hooked
	"drift_time": 6.0,  # Owner-approved proposal: a repelled boat drifts off for 6 s
	"drift_speed": 34.0,  # TUNING (not in GDD) px/s a drifting or leaving boat moves off the rail
	"leave_time": 2.5,  # TUNING (not in GDD) s an emptied boat takes to cast off and vanish
	"hook_spread": 30.0,  # TUNING (not in GDD) px each hook sits from the boarding point along the rail
	"hook_inset": 9.0,  # TUNING (not in GDD) px inside the rail a hook stands
	"boat_overlap": 0.4,  # TUNING (not in GDD) share of the hull's radius over the rail line (a summon at the rail reaches it)
	"plank_inset": 14.0,  # TUNING (not in GDD) px inside the rail a crewman steps aboard
	"max_boats": 4,  # Owner-approved proposal: boats are pooled structures, cap 4 at a time
	"queue_cap": 72,  # TUNING (not in GDD) crew waiting for a boat; more are refused (counted)
	"min_crew": 3,  # TUNING (not in GDD) crew a queue gathers before a boat launches ...
	"max_wait": 1.5,  # TUNING (not in GDD) ... unless its oldest crewman waited this long (s)
	"lane_seed_salt": 1013,  # Unused by the RNG stream (a doc anchor): lanes come from the seeded gameplay RNG
	"crate_xp": 6,  # TUNING (not in GDD) XP of a sunk boat's floating crate
	"lantern_lead": 3.0,  # Owner-approved proposal: the amber lantern at the rail point (drawn for the lane's 3 s)
	# The Reckoning, the Black Tide: every boat closes at once, the whole rail boards.
	"tide_max_boats": 8,  # TUNING (not in GDD) boats at once during the Black Tide
	"tide_pour_every": 0.35,  # TUNING (not in GDD) s between two crewmen during the Black Tide
	"tide_queue_cap": 200,  # TUNING (not in GDD) queue cap during the Black Tide
	"tide_lane_time": 1.5,  # TUNING (not in GDD) s of lane telegraph during the Black Tide
}

## The boat sizes (owner-approved proposal: "skiff (6 crew, 150 hull HP),
## longboat (12 crew, 300), raider ship (24 crew, 900, two planks)"): kind id
## -> crew it carries. The hull HP is the kind's row (CorsairEnemyData). A
## stage's STAGE "boarding" "boats" lists the sizes it allows (the tier cap).
const BOAT_CREW := {
	"skiff": 6,  # Owner-approved proposal
	"longboat": 12,  # Owner-approved proposal
	"raider_ship": 24,  # Owner-approved proposal
	# --- Act X: the Maelstrom ---
	"ghost_longboat": 8,  # TUNING (not in GDD) the spectral longboat (only through BoardingParty.launch_boat(); never in BOAT_ORDER)
}
## Boat sizes in order, smallest first (a launch picks the smallest allowed
## size that holds the waiting crew, else the largest allowed).
const BOAT_ORDER: Array[String] = ["skiff", "longboat", "raider_ship"]
## Planks of each boat size (a raider ship pours two crewmen at a time).
const BOAT_PLANKS := {
	"skiff": 1,  # Owner-approved proposal
	"longboat": 1,  # Owner-approved proposal
	"raider_ship": 2,  # Owner-approved proposal: two planks
}

# --- Strikes from the Sea ------------------------------------------------------------

## STRIKES FROM THE SEA (SeaStrikes; owner-approved proposal "Strikes from the
## Sea"): water creatures swim around and under the ship and strike the RAIL
## BAND with telegraphed circles (a dark-water ring) that hit both armies. A
## creature can only be hit while SURFACED. At most `cap` swimmers alive. A
## kind's row "strike" overrides any key for that kind. A stage's STAGE "sea"
## overrides any key.
const SEA := {
	"cap": 8,  # Owner-approved proposal: at most 8 swimmers alive
	"swim_offset": 44.0,  # TUNING (not in GDD) px off the rail a swimmer circles (its body centre)
	"swim_speed": 46.0,  # TUNING (not in GDD) px/s along the hull
	"telegraph": 1.0,  # Owner-approved proposal: a strike's circle shows 1.0 s
	"surface_time": 2.0,  # Owner-approved proposal: a creature is surfaced (hittable) 2 s
	"strike_every": 10.0,  # Owner-approved proposal: a shark leaps "every ~10 s" (per swimmer, seeded jitter)
	"strike_jitter": 0.4,  # TUNING (not in GDD) +- share of strike_every drawn from the seeded RNG
	"first_strike": 4.0,  # TUNING (not in GDD) s after it appears before a swimmer's first strike
	"radius": 34.0,  # TUNING (not in GDD) px, a strike circle
	"reach": 300.0,  # TUNING (not in GDD) px from the swimmer a strike may land
	"dmg_summon": 9.0,  # TUNING (not in GDD) per strike, x the enemies' damage scaling
	"dmg_player": 7.0,  # TUNING (not in GDD) per strike, x the enemies' damage scaling
	"dmg_enemy": 14.0,  # TUNING (not in GDD) per strike to a deck enemy, x the enemies' HP scaling
}
## The strike types (a kind's row "strike" "type"): "leap" (a shark breaches
## onto the deck: a shadow, then it lands as an ordinary deck enemy) and
## "tentacle" (a kraken arm grabs one summon, holds it, drags it overboard).
const STRIKE_TYPES: Array[String] = ["leap", "tentacle",
	# --- Act X: the Treasure Galleon --- (the Hull Crab's climb over the rail)
	"climb",
	# --- Act X: the Maelstrom ---
	"breach"]
## The tentacle (owner-approved proposal: "grabs one summon, holds it 5 s with
## the existing held_until hook, then drags it overboard (lost until the next
## replenish). Kill the tentacle (200 HP, surfaced 3 s) to free it").
const TENTACLE := {
	"hold": 5.0,  # Owner-approved proposal: held 5 s
	"surfaced": 3.0,  # Owner-approved proposal: surfaced 3 s (from the grab)
	"renew": 0.2,  # TUNING (not in GDD) s the held hook is renewed ahead each tick
	"drop_daze": 0.4,  # TUNING (not in GDD) s a freed summon stays dazed
	"max_radius": 13.0,  # TUNING (not in GDD) px: a bigger body (Abomination, Colossus, Golem) is too heavy to drag
}
## The leap (owner-approved proposal: "a shark or serpent breaches with a 0.8
## s shadow on the deck and lands inside the ring as an ordinary deck enemy").
const LEAP := {
	"telegraph": 0.8,  # Owner-approved proposal: a 0.8 s shadow
	"inset": 40.0,  # TUNING (not in GDD) px inside the rail the landing is at least
}
# --- Act X: the Maelstrom ---
## The breach (the Sea Serpent's strike, type "breach"; owner-approved proposal:
## "Breaches in a line across the rail band, then submerges | Step out of the
## line"): a LANE from the serpent's hull point across the rail band toward its
## target shows `telegraph` s (SEA's, 1 s), then the serpent's body sweeps it
## and everything in it is hit once, both armies (the SEA damage keys of its
## row's "strike").
const BREACH := {
	"length": 170.0,  # TUNING (not in GDD) px of the lane from the hull inward (past the 120 px rail band)
	"half_width": 15.0,  # TUNING (not in GDD) px each side of the lane's line
}

# --- Act X: the Treasure Galleon ---
## THE CLIMB (the Hull Crab's strike type "climb"; owner-approved proposal:
## "climbs the hull and boards at the rail band"): at most `inset` px inside
## the rail it lands.
const CLIMB := {
	"inset": 36.0,  # TUNING (not in GDD) px inside the rail (in the rail band)
}

# --- The Reckoning: the Black Tide ---------------------------------------------------

## THE BLACK TIDE (BlackTide; owner-approved proposal "Reckoning, the Black
## Tide": "every boat in the sea closes on the ship at once, the whole rail is
## a boarding point, gunboats shell in lines, and the kraken surfaces. The rail
## band is struck every 3 s and a great wave shoves everything toward the far
## rail every 20 s"). Run from 0:00 on a stage whose RECKONING has a
## "black_tide" dictionary (any key below overrides). Gunboats are phase 2.
const BLACK_TIDE := {
	"strike_every": 3.0,  # Owner-approved proposal: the rail band is struck every 3 s
	"strike_speedup": 0.9,  # TUNING (not in GDD) x the interval per minute past 0:00
	"strike_min": 1.2,  # TUNING (not in GDD) s, the shortest interval
	"wave_every": 20.0,  # Owner-approved proposal: a great wave every 20 s
	"wave_telegraph": 2.0,  # TUNING (not in GDD) s the wave's foam line shows first
	"wave_time": 1.2,  # TUNING (not in GDD) s the wave shoves
	"wave_push": 120.0,  # TUNING (not in GDD) px/s the necromancer and the army are carried (they stop at the far rail)
	"wave_knock": 260.0,  # TUNING (not in GDD) px/s knockback on deck enemies (the far rail drowns them)
	"wave_damage": 6.0,  # TUNING (not in GDD) to every summon and the necromancer it reaches, x the damage scaling
	"strike_radius": 40.0,  # TUNING (not in GDD) px
	# --- Act X: the Treasure Galleon --- (the gunboats shell in lines: GunboatKit)
	"gunboat_every": 0.0,  # TUNING (not in GDD) s between two gunboats the Black Tide brings (0 = none; the Galleon sets it)
	# --- Act X: the Maelstrom --- "the kraken surfaces" (owner-approved proposal):
	# every kraken_every s (the first kraken_first s after 0:00) a kraken arm comes
	# up out of the sea (SeaStrikes.spawn_swimmer(), the Reckoning's flag; the
	# swimmer cap holds). 0 = off.
	"kraken_every": 30.0,  # TUNING (not in GDD) s between two kraken arms in the Black Tide (every stage of the act)
	"kraken_first": 8.0,  # TUNING (not in GDD) s after 0:00 before the first
}

# --- Sounds --------------------------------------------------------------------------

## Black Tide sound events -> sound id. The audio pass's ids (the "corsair"
## pack, rendered lazily with the act's music); an id the bank does not hold
## yet plays nothing (Sfx.play() skips it), so the foundation is silent until
## the pack merges.
const SOUNDS := {
	"hook_throw": "hook_throw",  # Corsair pack: a grapple flung at the rail.
	"hook_bite": "hook_bite",  # Corsair pack: the hook bites the rail.
	"hook_cut": "hook_cut",  # Corsair pack: a grapple line cut.
	"splash": "splash",  # Corsair pack: a body hits the water.
	"overboard": "overboard",  # Corsair pack: a deck enemy tips over the rail.
	"shark_leap": "shark_leap",  # Corsair pack: a shark breaches.
	"kraken_rise": "kraken_rise",  # Corsair pack: a kraken arm surfaces.
	"tentacle_grab": "tentacle_grab",  # Corsair pack: the arm closes on a summon.
	"powder_blast": "powder_blast",  # Corsair pack: a keg goes off.
	"fuse_hiss": "fuse_hiss",  # Corsair pack: a lit fuse.
	"cutlass_clash": "cutlass_clash",  # Corsair pack: a rapier lunge lands.
	"hull_creak": "hull_creak",  # Corsair pack: a boat sinks.
	"wave_crash": "wave_crash",  # Corsair pack: the Black Tide's great wave.
	# --- Act X: the Smuggler's Cutter ---
	"cannon_fire": "cannon_fire",  # Corsair pack: Crow's broadside fires.
	"cannon_hit": "cannon_hit",  # Corsair pack: a broadside line lands.
	"musket_shot": "musket_shot",  # Corsair pack: Crow's pistol.
	"cutlass_slash": "cutlass_slash",  # Corsair pack: Crow's cutlass, Gorran's chain sweep.
	"bosun_whistle": "bosun_whistle",  # Corsair pack: a Boatswain's bellow, Gorran's bellow.
	"plank_drop": "plank_drop",  # Corsair pack: Crow lands from his leap; the ram longboat's crew boards.
	# --- Act X: the Treasure Galleon ---
	"crab_climb": "hull_creak",  # Corsair pack: a hull crab heaves itself over the rail.
	"coin_chime": "coin_chime",  # Corsair pack: Gold Fever's cursed coins.
	# --- Act X: the Maelstrom ---
	"heave_creak": "hull_creak",  # Corsair pack: the Heave's telegraph, the deck about to tip.
	"ghost_whistle": "bosun_whistle",  # Corsair pack: the Ghost Bosun's whistle.
	"oath_break": "ghost_moan",  # Corsair pack: Vandermere's Oath breaks.
	"ghost_rise": "ghost_moan",  # Corsair pack: a ghost crewman rises for the necromancer.
	"serpent_breach": "wave_crash",  # Corsair pack: a sea serpent breaches across the rail band.
	"crew_call": "bosun_whistle",  # Corsair pack: Vandermere calls his crew.
	"keg_lit": "fuse_hiss",  # Corsair pack: a Powder Wraith lights its keg.
	"keg_burst": "powder_blast",  # Corsair pack: a Powder Wraith's keg bursts.
	"anchor_drop": "cannon_hit",  # Corsair pack: an Anchor Drop slams down.
}

# --- Counter-passive hooks (not built) -------------------------------------------------

## PassiveData id of Sea Legs (the future counter-passive: the Heave drift and
## grapple pulls are halved for the army). Not built in phase 1.
const SEA_LEGS: String = "sea_legs"
## Its value key: the share of a drift / pull the army ignores (0 while not owned).
const SEA_LEGS_KEY: String = "drift_cut"
## PassiveData id of Barnacle Bones (the future counter-passive: summon hits on
## boats, hooks and surfaced creatures deal more). Not built in phase 1.
const BARNACLE_BONES: String = "barnacle_bones"
## Its value key: the share summon hits on boats, hooks and swimmers deal MORE (0 while not owned).
const BARNACLE_KEY: String = "sea_damage"
