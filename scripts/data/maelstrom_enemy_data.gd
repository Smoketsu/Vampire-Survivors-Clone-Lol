## MaelstromEnemyData — the kinds of the Maelstrom only (Act X, the Black Tide;
## GDD §15.0 "Act X foundation: the Black Tide (phase 1)" and "The Maelstrom
## (Act X phase 2)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 1 "Stage C: The Maelstrom"). EnemyDirector.corsair_def() looks them up
## after CorsairEnemyData. Rows as CorsairEnemyData's (same keys), plus:
##   ghost    — true: a GHOST CREWMAN of the Hollow Queen (the dead of the sea).
##              He boards like any crew (BoardingParty) and, unlike every
##              other Black Tide body, his fall on the deck may RAISE him for
##              the necromancer (MaelstromDirector.on_ghost_died(): the one
##              raise of the Brotherhood's own dead; every raise chips
##              Vandermere's Oath). He draws the roster sprite named in `wears`
##              with the spectre tint (no ghost-crew art was drawn: the art
##              pass's note, docs/tide/ART_MANIFEST.md).
##   wears    — the roster sprite a ghost crewman wears ("corsair/<kind>").
##   whistle  — Dictionary: the Ghost Bosun's whistle (GhostBosunKit): first
##              (s before the first), every (s), windup (s he stands with the
##              whistle at his lips), crew (ghost crewmen the spectral longboat
##              carries), gunners (how many of them are gunners).
## The kinds (owner-approved proposal; brief docs/tide/BRIEF_PHASE2.md "Agent C"):
##   ghost_deckhand — the ghost crew's fodder, male: a drowned deckhand.
##   ghost_gunner   — the ghost crew's ranged fodder, male: a drowned musketeer.
##   ghost_bosun    — the miniboss, male: his whistle summons a spectral
##                    longboat (BoardingParty.launch_boat()).
##   ghost_longboat — the spectral longboat (a boat row: BoardingParty brings
##                    it only for the Ghost Bosun and Vandermere's Crew).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked
## as the owner-approved proposal. Tuned for the act's FINAL slot II.
class_name MaelstromEnemyData
extends RefCounted

## Kind id of the ghost crew's fodder.
const GHOST_DECKHAND: String = "ghost_deckhand"
## Kind id of the ghost crew's gunner.
const GHOST_GUNNER: String = "ghost_gunner"
## Kind id of the miniboss.
const GHOST_BOSUN: String = "ghost_bosun"
## Kind id of the spectral longboat (a boat; CorsairRulesData.BOAT_CREW).
const GHOST_LONGBOAT: String = "ghost_longboat"
## Colour multiplied over a ghost crewman's worn sprite (the act's spectre ramp,
## pale green-white; Palette.CORSAIR_SPECTRE_LIGHT with a little transparency).
const GHOST_TINT := Color(0.72, 1.0, 0.88, 0.82)  # TUNING (not in GDD) visual only

## The stage's own kinds, keyed by kind id.
const ENEMIES := {
	# Ghost crew fodder, male (owner-approved proposal: "Ghost crews do leave corpses (they are the dead of the sea),
	# so the necromancer raises the Brotherhood's own dead here"). A drowned deckhand: the Deckhand's body, a little
	# tougher, slower; boards by boat; his fall on the deck may raise him for the necromancer.
	"ghost_deckhand": {
		"display_name": "Ghost Deckhand",
		"max_hp": 20.0,  # TUNING (not in GDD) the Deckhand 16
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": CorsairEnemyData.FACTION,
		"kit": "ghost_deckhand",
		"crew": true,
		"fodder": true,
		"ghost": true,  # The dead of the sea: may rise for the necromancer (MaelstromDirector)
		"wears": "corsair/deckhand",  # No ghost-crew art: the roster's deckhand, spectre-tinted (ART_MANIFEST)
	},  # The Ghost Deckhand.
	# Ghost crew ranged fodder, male (owner-approved proposal: "spectral deckhands and gunners"). A drowned musketeer:
	# ordinary projectiles from the deck.
	"ghost_gunner": {
		"display_name": "Ghost Gunner",
		"max_hp": 20.0,  # TUNING (not in GDD) the Musketeer 18
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 2.6,  # TUNING (not in GDD) s
		"attack_range": 180.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 220.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": CorsairEnemyData.FACTION,
		"kit": "ghost_gunner",
		"crew": true,
		"fodder": true,
		"ghost": true,  # The dead of the sea: may rise for the necromancer (MaelstromDirector)
		"wears": "corsair/musketeer",  # No ghost-crew art: the roster's musketeer, spectre-tinted (ART_MANIFEST)
	},  # The Ghost Gunner.
	# THE MINIBOSS, male (owner-approved proposal: "The Ghost Bosun (male), whose whistle summons a spectral
	# longboat"). He comes over the rail from the sea (EnemyDirector.spawn_at(): the boats are not his door) and
	# walks at the necromancer; every whistle "every" s he stands and blows his whistle, and a spectral longboat
	# comes alongside with his drowned crew (BoardingParty.launch_boat()). His chest drops where he falls.
	"ghost_bosun": {
		"display_name": "The Ghost Bosun",  # Owner-approved proposal
		"max_hp": 3000.0,  # TUNING (not in GDD) a miniboss (first pass 1,500 fell in 15 s to the seed-7 army)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px (a 48 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 50,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1
		"mass": 10.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) a miniboss
		"miniboss": true,  # Its chest (ChestManager) and the HUD bar (GhostBosunKit registers it)
		"faction": CorsairEnemyData.FACTION,
		"kit": "ghost_bosun",
		"whistle": {"first": 2.0, "every": 10.0, "windup": 1.1, "crew": 8, "gunners": 2},  # TUNING (not in GDD) owner-approved proposal: "whose whistle summons a spectral longboat"
	},  # The Ghost Bosun.
	# THE SPECTRAL LONGBOAT (a BOAT: a structure in the water; owner-approved proposal: "whose whistle summons a
	# spectral longboat"; "ghost boats circling the gyre"). BoardingParty brings it only through launch_boat() (the
	# Ghost Bosun's whistle, Vandermere's Crew), never for the timeline's crews (not in CorsairRulesData.BOAT_ORDER).
	"ghost_longboat": {
		"display_name": "Spectral Longboat",
		"max_hp": 260.0,  # TUNING (not in GDD) the longboat 300: rotten planks
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": CorsairEnemyData.FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line
		"boat": true,  # A boarding boat (BoardingParty; its crew in CorsairRulesData.BOAT_CREW)
	},  # The Spectral Longboat.
}
