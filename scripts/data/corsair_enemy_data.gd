## CorsairEnemyData — immutable design data for the kinds THE BLACK TIDE fields
## on every stage of the pirate act (Act X until the reorder pass; final slot
## II; GDD §15.0 "Act X foundation: the Black Tide (phase 1)"; owner-approved
## proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Roster"). The Corsair
## Brotherhood, a loose fleet of cutthroats under the black flag, boards the
## necromancer's ship from small boats; under the ship the sea has its own
## beasts. Natural beasts only (no fish-folk, nothing cosmic: never Act II).
## The shared kinds of phase 1, every one used by a rule:
##   deckhand         — fodder, male: cutlass mobs off the boats (BOARDING).
##   musketeer        — ranged fodder, male: ordinary projectiles.
##   powder_runner    — fodder, male: a lit keg that blasts both sides and
##                      knocks everyone 60 px (THE DECK: overboard).
##   swashbuckler     — soldier, FEMALE (figure style): a rapier lunge over the
##                      first blocker.
##   boarding_bruiser — heavy, male: flat armour 3 (the Reckoning's heavy).
##   reef_shark       — swimmer / leaper (STRIKES FROM THE SEA: the leap).
##   kraken_arm       — swimmer elite, a structure (the tentacle grab).
##   skiff / longboat / raider_ship — the boats (structures BoardingParty
##                      brings; never in a timeline).
##   boarding_hook    — a boat's grapple (a 40 HP structure at the rail).
## Phase 2 adds the stage kinds in CutterEnemyData / GalleonEnemyData /
## MaelstromEnemyData (the Grappler, Gunnery Mate, Boatswain, Voodoo Navigator,
## Gunboat, Hull Crab, Sea Serpent, the ghost crew, the bosses' allies);
## EnemyDirector.corsair_def() looks them up after this file.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Black Tide keys (absent = off):
##   faction  — "corsair" (the Codex's Black Tide tab, the reports).
##   kit      — a CovenantKit id; a Black Tide kit lives in
##              scripts/enemies/corsair/<kit>_kit.gd (CovenantKits loads it by
##              name after the Concord's folder; ids unique across the folders).
##              Every Black Tide kind has one (a CorsairKit).
##   crew     — true: a boarder. On a corsair stage every spawn of the
##              timeline (trickle, waves, the Reckoning) of a crew kind goes
##              to BoardingParty's queue and comes aboard by boat. A kind with
##              neither "crew" nor "water" (any other act's kind forced onto
##              a corsair stage) boards by boat too.
##   water    — true: starts in the water as a swimmer (SeaStrikes: it never
##              boards, ignores the deck, circles the hull and can only be hit
##              while surfaced; at most SEA cap alive); a boat lies in the
##              water too (never clamped to the deck).
##   strike   — Dictionary: a swimmer's strike: "type" (CorsairRulesData
##              .STRIKE_TYPES) plus any CorsairRulesData.SEA key to override.
##   boat     — true: a boarding boat (BoardingParty; its crew in
##              CorsairRulesData.BOAT_CREW, its planks in BOAT_PLANKS).
##   hook     — true: a boat's grapple hook (BoardingParty).
##   keg      — Dictionary: the Powder Runner's keg (PowderRunnerKit): fuse_range
##              (px from a body it lights the fuse), fuse (s), radius (px),
##              dmg_summon / dmg_player / dmg_enemy (per blast, before the
##              scaling), push (px everyone is knocked).
##   lunge    — Dictionary: the Swashbuckler's rapier lunge (SwashbucklerKit):
##              range (px), every (s), windup (s), speed (px/s), damage.
##   fodder / elite_kind — reports only (an elite_kind is NOT spawned as an
##              elite: its row is already strong).
##   figure   — true: a figure-style woman (the art's bust rig; no rule reads it).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot II (between the
## Covenant and the Sanguine Court: an early act; docs/last_acts/PLAN.md).
class_name CorsairEnemyData
extends RefCounted

## Faction id of the Black Tide's kinds (row "faction").
const FACTION: String = "corsair"
## Sprite folder of the Black Tide's kinds (assets/sprites/corsair/<kind>.png).
const SPRITE_DIR: String = "corsair/"
## Kind id of the deck fodder.
const DECKHAND: String = "deckhand"
## Kind id of the grapple hook (BoardingParty).
const HOOK: String = "boarding_hook"
## The Black Tide's heavy (the RECKONING "kind" of every Act X stage).
const RECKONING_KIND: String = "boarding_bruiser"
## The Black Tide's companions (the RECKONING "companions" of every Act X stage):
## crews, kegs and duellists; the sharks come by SeaStrikes (the Black Tide raises its cap).
const RECKONING_COMPANIONS: Array = [
	{"kind": "deckhand", "count": 10, "growth": 2.0},  # TUNING (not in GDD) a boat's crew
	{"kind": "musketeer", "count": 3, "growth": 1.0},  # TUNING (not in GDD)
	{"kind": "powder_runner", "count": 2, "growth": 0.5},  # TUNING (not in GDD)
	{"kind": "swashbuckler", "count": 1, "growth": 0.34},  # TUNING (not in GDD)
]

## The Black Tide's shared kinds, keyed by kind id.
const ENEMIES := {
	# Fodder, male (owner-approved proposal: "Cutlass mobs that come off the boats in streams | Anything; Warriors at the
	# boarding point"). Boards by boat (BoardingParty).
	"deckhand": {
		"display_name": "Deckhand",
		"max_hp": 16.0,  # TUNING (not in GDD)
		"move_speed": 60.0,  # TUNING (not in GDD) px/s
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
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "deckhand",
		"crew": true,
		"fodder": true,
	},  # The Deckhand.
	# Ranged fodder, male (owner-approved proposal: "Fires from the boat while it is hooked, then from the deck.
	# Ordinary projectiles, no line rules | Sink or repel the boat; Archers"). Phase 1: from the deck only; firing
	# from a hooked boat is a phase 2 nicety (BoardingParty.boats lists the hooked boats).
	"musketeer": {
		"display_name": "Musketeer",
		"max_hp": 18.0,  # TUNING (not in GDD)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 2.8,  # TUNING (not in GDD) s
		"attack_range": 190.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 230.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "musketeer",
		"crew": true,
		"fodder": true,
	},  # The Musketeer.
	# Fodder, male (owner-approved proposal: "Sprints with a lit keg, 1 s fuse, blast hits both sides and knocks everyone
	# 60 px | Kill at range; let the blast push the crew overboard"). The keg goes off when the fuse ends or when he
	# falls (PowderRunnerKit): kill him at range and the blast tips his own crew over the rail.
	"powder_runner": {
		"display_name": "Powder Runner",
		"max_hp": 12.0,  # TUNING (not in GDD)
		"move_speed": 88.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "powder_runner",
		"crew": true,
		"fodder": true,
		"keg": {"fuse_range": 26.0, "fuse": 1.0, "radius": 64.0, "dmg_summon": 14.0, "dmg_player": 10.0, "dmg_enemy": 18.0, "push": 60.0},  # Owner-approved proposal: 1 s fuse, both sides, 60 px; TUNING (not in GDD) the rest
	},  # The Powder Runner.
	# Soldier, FEMALE, figure style (owner-approved proposal: "Rapier lunge that jumps the first blocker and duels the
	# nearest summon | Rogues, Gargoyles, area damage").
	"swashbuckler": {
		"display_name": "Swashbuckler",
		"max_hp": 44.0,  # TUNING (not in GDD)
		"move_speed": 64.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 1.1,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "swashbuckler",
		"crew": true,
		"figure": true,  # Female, figure style (owner-approved proposal)
		"lunge": {"range": 120.0, "every": 5.0, "windup": 0.4, "speed": 420.0, "damage": 9.0},  # TUNING (not in GDD) the rapier lunge over the first blocker
	},  # The Swashbuckler.
	# Heavy, male (owner-approved proposal: "Axe that chops the Bone Wall and hooks; flat armour 3 | Siegecraft, Wither;
	# push overboard"). Phase 1: the heavy body and the flat armour (the existing path); the Bone Wall chop is phase 2.
	# The Black Tide's Reckoning heavy (RECKONING_KIND).
	"boarding_bruiser": {
		"display_name": "Boarding Bruiser",
		"max_hp": 120.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 2.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "boarding_bruiser",
		"crew": true,
		"flat_armor": 3.0,  # Owner-approved proposal: flat armour 3
		"elite_kind": true,
	},  # The Boarding Bruiser.
	# Swimmer / leaper (a creature; owner-approved proposal: "Circles; leaps at the ring every ~10 s | Hit it at the
	# leap; Orb Shield"). It circles the hull submerged (untargetable), surfaces, and its STRIKE is a leap: a 0.8 s
	# shadow on the deck, then it lands there as an ordinary deck enemy (it can be knocked back overboard).
	"reef_shark": {
		"display_name": "Reef Shark",
		"max_hp": 34.0,  # TUNING (not in GDD)
		"move_speed": 92.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "reef_shark",
		"water": true,  # Starts as a swimmer (SeaStrikes); lands on deck after its leap
		"strike": {"type": "leap"},  # SEA defaults (owner-approved proposal: it leaps at the ring every ~10 s)
	},  # The Reef Shark.
	# Swimmer elite, a STRUCTURE (a creature; owner-approved proposal: "Tentacle Strike; grabs a summon | Kill it while
	# surfaced"; "Kill the tentacle (200 HP, surfaced 3 s) to free it"). It surfaces at the rail, strikes the rail band
	# and grabs one summon (CorsairRulesData.TENTACLE through the held_until hook), then drags it overboard.
	"kraken_arm": {
		"display_name": "Kraken Arm",
		"max_hp": 200.0,  # Owner-approved proposal: 200 HP
		"move_speed": 30.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "kraken_arm",
		"is_structure": true,  # Owner-approved proposal: a swimmer elite (structure)
		"water": true,
		"elite_kind": true,
		"strike": {"type": "tentacle", "strike_every": 9.0, "radius": 30.0, "dmg_summon": 6.0, "dmg_player": 5.0},  # TUNING (not in GDD) a grab first, a light blow
	},  # The Kraken Arm.
	# A BOAT (a structure; BoardingParty spawns it, never the timeline). Owner-approved proposal: skiff, 6 crew, 150 hull HP. It lies alongside, its hull
	# over the rail line, so ranged summons, spells, fliers and a melee summon at the rail all reach it.
	"skiff": {
		"display_name": "Skiff",
		"max_hp": 150.0,  # Owner-approved proposal: skiff, 6 crew, 150 hull HP
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line
		"boat": true,  # A boarding boat (BoardingParty; crew CorsairRulesData.BOAT_CREW)
	},  # The Skiff.
	# A BOAT (a structure; BoardingParty spawns it, never the timeline). Owner-approved proposal: longboat, 12 crew, 300 hull HP. It lies alongside, its hull
	# over the rail line, so ranged summons, spells, fliers and a melee summon at the rail all reach it.
	"longboat": {
		"display_name": "Longboat",
		"max_hp": 300.0,  # Owner-approved proposal: longboat, 12 crew, 300 hull HP
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 28.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line
		"boat": true,  # A boarding boat (BoardingParty; crew CorsairRulesData.BOAT_CREW)
	},  # The Longboat.
	# A BOAT (a structure; BoardingParty spawns it, never the timeline). Owner-approved proposal: raider ship, 24 crew, 900 hull HP, two planks. It lies alongside, its hull
	# over the rail line, so ranged summons, spells, fliers and a melee summon at the rail all reach it.
	"raider_ship": {
		"display_name": "Raider Ship",
		"max_hp": 900.0,  # Owner-approved proposal: raider ship, 24 crew, 900 hull HP, two planks
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 40.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line
		"boat": true,  # A boarding boat (BoardingParty; crew CorsairRulesData.BOAT_CREW)
	},  # The Raider Ship.
	# A GRAPPLE HOOK (a structure; BoardingParty sets two at the rail per boat). Owner-approved proposal: "Each hook
	# is a small structure (40 HP) with a visible rope"; cut both and the boat drifts off. No XP (the boat holds it).
	"boarding_hook": {
		"display_name": "Grapple Hook",
		"max_hp": 40.0,  # Owner-approved proposal: 40 HP
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 7.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 0,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "boarding_hook",
		"is_structure": true,
		"hook": true,  # A boat's grapple (BoardingParty)
	},  # The Grapple Hook.
}
