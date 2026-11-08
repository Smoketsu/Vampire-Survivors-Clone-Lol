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
## Phase 2 (the Smuggler's Cutter) adds the shared grappler (soldier, male: a
## hook line that drags one summon to the rail) and boatswain (support, male:
## a bellow of speed and shields to his crew), at the end of ENEMIES.
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
	# --- Act X: the Smuggler's Cutter --- (shared rows: any stage may field them)
	# Soldier, male (owner-approved proposal: "Throws a hook line that drags one summon to the rail (into the rail
	# band) | Kill first; Sea Legs passive"). GrapplerKit: every grapple "every" s, when a grounded summon stands
	# within grapple "range" px, he swings the hook (windup s, its line drawn), the hook flies (throw s) and bites:
	# the summon is HELD (SummonedUnit.held_until + one CombatResolver.stun_unit(u, drag, "grapple")) and DRAGGED
	# toward the nearest rail at pull px/s x Sea Legs (TerrainSlow.push_summon(), the act's one shove path) for drag
	# s or until it is rail_stop px from the rail; then it is let go. Killing him cuts the line. A body wider than
	# max_radius px (an Abomination, a Colossus, a Golem) is too heavy to drag (the tentacle's rule).
	"grappler": {
		"display_name": "Grappler",
		"max_hp": 30.0,  # TUNING (not in GDD)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1; owner-approved proposal: "kill first"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "grappler",
		"crew": true,
		"grapple": {"range": 180.0, "min_range": 34.0, "every": 7.5, "windup": 0.6, "throw": 0.3, "drag": 1.4,  # TUNING (not in GDD)
			"pull": 150.0, "rail_stop": 28.0, "damage": 3.0, "max_radius": 13.0},  # TUNING (not in GDD) the hook line (owner-approved: "drags one summon to the rail")
	},  # The Grappler.
	# Support, male (owner-approved proposal: "Bellow: +20% move speed and a short shield to crew within 200 px |
	# Priority target"). BoatswainKit: every bellow "every" s (windup s, his whistle) every OTHER living crewman within
	# radius px moves speed x faster for time s (Enemy.apply_buff(), the one aura buff path) and gains a shield of
	# shield x its max HP for time s (Enemy.holy_shield, the one enemy shield path).
	"boatswain": {
		"display_name": "Boatswain",
		"max_hp": 40.0,  # TUNING (not in GDD)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) per hit, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; owner-approved proposal: "priority target"
		"mass": 1.1,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "boatswain",
		"crew": true,
		"bellow": {"every": 8.0, "windup": 0.5, "radius": 200.0, "speed": 1.2, "shield": 0.25, "time": 4.0},  # Owner-approved proposal: +20% speed, 200 px; TUNING (not in GDD) the rest
	},  # The Boatswain.
	# --- Act X: the Treasure Galleon --- (shared rows: any stage of the act may field them)
	# Ranged soldier, FEMALE, figure style (owner-approved proposal: "Lobs grenadoes over the ring on a landing circle |
	# Rogues, Gargoyles; move"). Brief: "arcing grenadoes on a landing circle that ignore the ring". Her ranged attack is
	# a lob (GunneryMateKit.fire_ranged()): a landing circle shows for grenado "flight" s on the nearest necromancer in
	# her "reach" (else her target), then THE POWDER BLAST (CorsairRules.powder_blast(): both sides, everyone knocked
	# "push" px), so a grenado among her own crew at the rail drowns them.
	"gunnery_mate": {
		"display_name": "Gunnery Mate",
		"max_hp": 30.0,  # TUNING (not in GDD)
		"move_speed": 54.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) her grenadoes deal the damage
		"attack_interval": 4.4,  # TUNING (not in GDD) s between two lobs (first pass 3.6: the naive bot died to the blasts)
		"attack_range": 200.0,  # TUNING (not in GDD) px (she stops this far from her target)
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 200.0,  # TUNING (not in GDD) px/s (unused: the kit lobs)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "gunnery_mate",
		"crew": true,
		"figure": true,  # Female, figure style (owner-approved proposal)
		"grenado": {"reach": 260.0, "flight": 1.2, "radius": 44.0, "dmg_summon": 7.0, "dmg_player": 4.0, "dmg_enemy": 10.0, "push": 34.0},  # TUNING (not in GDD) the lob and its blast (first pass 9 / 7 on summons / you)
	},  # The Gunnery Mate.
	# Support, FEMALE, figure style (owner-approved proposal: "Marks a spot on the ring; the sea strikes it 1.5 s later |
	# Kill her first; the mark fails if she dies"). Brief: "marks a strike on the ring through SeaStrikes.strike(),
	# cancelled if she dies". Every mark "every" s, while a necromancer stands within mark "reach" px, she marks a
	# point on his ring (mark "ring" px from him, a seeded angle): an owned sea strike (SeaStrikes.strike() with her as
	# its owner: it fizzles if she dies first) that lands after mark "telegraph" s. Her own blow is a weak hex bolt.
	"voodoo_navigator": {
		"display_name": "Voodoo Navigator",
		"max_hp": 26.0,  # TUNING (not in GDD)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) per hex bolt, before the time scaling
		"attack_interval": 2.6,  # TUNING (not in GDD) s
		"attack_range": 220.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 180.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1: kill her first
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "voodoo_navigator",
		"crew": true,
		"figure": true,  # Female, figure style (owner-approved proposal)
		"mark": {"every": 6.5, "first": 3.0, "reach": 360.0, "ring": 70.0, "telegraph": 1.5, "radius": 40.0, "dmg_summon": 11.0, "dmg_player": 9.0, "dmg_enemy": 12.0},  # Owner-approved proposal: 1.5 s; TUNING (not in GDD) the rest
	},  # The Voodoo Navigator.
	# A GUNBOAT (a structure in the water; owner-approved proposal: "Never boards; shells the deck in lines from range |
	# Cannons, fliers, ranged"). Brief: "a boat row that never boards and shells the deck in lines". Not a crew boat:
	# GunboatKit.launch() brings it alongside a seeded point of the straight rail (its hull over the rail line, like a
	# boarding boat, so the army reaches it); every shell "every" s it shows shell "lines" lanes across the deck at the
	# necromancer (shell "telegraph" s), then shells them (the army only). After shell "stay" s it casts off. At most
	# shell "cap" gunboats alive. The timeline asks for it like any kind (CorsairRules.route_spawn() hands it to
	# GunboatKit) and the Black Tide brings them (its "gunboat_every"). Barnacle Bones applies (CorsairKit.taken_mult()).
	"gunboat": {
		"display_name": "Gunboat",
		"max_hp": 420.0,  # TUNING (not in GDD) between a longboat (300) and a raider ship (900)
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) its shells deal the damage
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 30.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) iron-plated
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "gunboat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line
		"boat": true,  # Drawn and hit like a boat (CorsairKit.is_boat()); NOT a boarding size (it never boards)
		"gunboat": true,  # GunboatKit.launch() brings it (CorsairRules.route_spawn())
		"shell": {"every": 7.5, "first": 3.0, "lines": 2, "telegraph": 1.4, "width": 34.0, "spread": 120.0, "jitter": 30.0,  # TUNING (not in GDD)
			"dmg_summon": 10.0, "dmg_player": 8.0, "stay": 75.0, "cap": 2, "tide_cap": 3},  # TUNING (not in GDD)
	},  # The Gunboat.
	# Swimmer / climber, a creature (owner-approved proposal: "Climbs the hull and boards at the rail band; armour 4 |
	# Area damage; push it back over"). Brief: "a giant swimmer that climbs the hull and boards at the rail band, armour
	# 4: a new strike type". Its strike type "climb" (SeaStrikes, the Galleon's block): the hull point nearest its
	# target shows a climbing circle for the telegraph, then it heaves itself over the rail into the rail band as an
	# ORDINARY DECK ENEMY (CorsairKit.leave_water(); heavy, flat armour 4, so area blows and knockback answer it).
	"hull_crab": {
		"display_name": "Hull Crab",
		"max_hp": 90.0,  # TUNING (not in GDD)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 7.0,  # TUNING (not in GDD) per pinch, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD) heavy, but a hard blow still tips it over
		"faction": FACTION,
		"kit": "hull_crab",
		"water": true,  # Starts as a swimmer (SeaStrikes); climbs aboard with its strike
		"flat_armor": 4.0,  # Owner-approved proposal: armour 4
		"strike": {"type": "climb", "telegraph": 1.4, "strike_every": 7.0, "radius": 30.0, "dmg_summon": 8.0, "dmg_player": 6.0},  # TUNING (not in GDD) its climb over the rail
	},  # The Hull Crab.
	# --- Act X: the Maelstrom ---
	# Swimmer heavy (a creature; owner-approved proposal: "Breaches in a line across the rail band, then submerges |
	# Step out of the line"). It circles the hull submerged like every swimmer (SeaStrikes) and its STRIKE is the
	# BREACH (CorsairRulesData.BREACH, the "breach" strike type): a lane from the hull across the rail band shows
	# its telegraph, then the serpent's body sweeps it, hitting both armies, and it submerges again. A shared row:
	# any stage of the act may field it. Its id is "corsair_serpent" (Act IV's Olympus owns "sea_serpent"); its art
	# is the art pass's corsair/sea_serpent (CorsairSerpentKit draws it).
	"corsair_serpent": {
		"display_name": "Sea Serpent",  # Owner-approved proposal
		"max_hp": 260.0,  # TUNING (not in GDD) a swimmer heavy (the kraken arm 200)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD) per hit, before the time scaling (its breach is its blow)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) scales
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "corsair_serpent",
		"is_structure": true,  # Never walks the deck: it only breaches and submerges
		"water": true,
		"elite_kind": true,
		"strike": {"type": "breach", "strike_every": 11.0, "dmg_summon": 11.0, "dmg_player": 8.0, "dmg_enemy": 18.0, "surface_time": 1.5},  # TUNING (not in GDD) over SEA (the lane's size in CorsairRulesData.BREACH)
	},  # The Sea Serpent.
}
