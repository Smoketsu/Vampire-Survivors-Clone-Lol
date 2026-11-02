## FortKesslerEnemyData — immutable design data for the City kinds that join on
## Fort Kessler (Stage 23) (Act VIII, the Last Line; GDD §15.0 "Fort Kessler
## (Act VIII phase 2)" and "Mammoth (Act VIII)"; owner-approved proposal
## docs/act8/PROPOSAL.md "Stage 23: Fort Kessler"). The stage's own rows:
##   mammoth — MAMMOTH, the stage's miniboss: a super-heavy tank with two
##             turrets (MammothKit). The Machine Gunner and the Attack
##             Helicopter are shared rows (CityEnemyData, Fort Kessler's block),
##             so any stage may field them; the minefield's mines are not
##             enemies (Minefields, FortKesslerDirector).
## EnemyDirector.city_def() looks these rows up after CityEnemyData. Rows have
## every key of a CityEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/city/<kit>_kit.gd, unique across the Eye, Empire, Pantheon,
## Shogunate, Inferno, Court and City folders; "tier", "armour_front",
## "vehicle", "super" and "civilian" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name FortKesslerEnemyData
extends RefCounted

## Kind id of Mammoth, the stage's miniboss.
const MAMMOTH: String = "mammoth"
## Damage tag of Mammoth's turret shells (both turrets; a ranged source:
## CityEnemyData.FORT_KESSLER_RANGED_SOURCES).
const MAMMOTH_SHELL_SOURCE: String = "mammoth_shell"

## Kind id -> design row.
const ENEMIES := {
	# MAMMOTH (owner-approved proposal: "Miniboss, Mammoth, a super-heavy tank
	# with two turrets"; brief: "a vehicle with armour_front and flat_armor,
	# and its collision radius stays at most 36 px. Each turret has its own
	# cooldown through CityShells, and its wreck is the largest of the act").
	# The CityKit's drive (lanes, headlights, run-over, turns, rams), FRONT
	# ARMOUR and FLAT ARMOUR like the tank, and TWO TURRETS (MammothKit), each
	# on its own cooldown, each through CityShells (the one shell path):
	#   main_*  — THE MAIN GUN: every main_every s, with a summon or the
	#             necromancer within main_range px, one heavy shell on him
	#             (main_radius px, landing after main_windup s, main_damage);
	#   twin_*  — THE TWIN GUN: every twin_every s a short LINE of twin_count
	#             shells walking from twin_start px toward its target, twin_gap
	#             px apart, each twin_walk s after the last (twin_radius px,
	#             twin_damage).
	# Dead, it leaves THE LARGEST WRECK of the act: its own wreck cell and the
	# next one along its street (two wreck rects, CityBlocks.add_wreck() twice
	# through Convoy), each burning and exploding as a wreck does. A
	# miniboss (the HUD bar, the chest) with an XP burst. Never a body larger
	# than CityBlockData.MAX_BODY_RADIUS (26 x 1.35 as an elite = 35.1 px).
	"mammoth": {
		"display_name": "Mammoth",
		"max_hp": 2600.0,  # TUNING (not in GDD) a miniboss (Old Greymane 2,200; the tank 700)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s; super-heavy treads
		"damage": 0.0,  # Unused: run_damage and the turrets.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 26.0,  # TUNING (not in GDD) px (x 1.35 as an elite = 35.1, under MAX_BODY_RADIUS 36)
		"armor": 0.25,  # TUNING (not in GDD)
		"flat_armor": 6.0,  # TUNING (not in GDD) the existing flat armour path (the tank 4)
		"xp": 0,  # Its XP is the burst.
		"behavior": "melee",  # Unused: its kit drives it.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 120.0,  # TUNING (not in GDD)
		"slow_resist": 0.7,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": CityEnemyData.FACTION,
		"kit": "mammoth",
		"tier": "army",  # The army's super-heavy (the report and the Codex group it there).
		"vehicle": true,  # Owner-approved proposal: a tank (Convoy)
		"armour_front": 0.65,  # TUNING (not in GDD) heavier than the tank's 0.6
		"half_length": 40.0,  # TUNING (not in GDD) px (its run-over box; ~96 px sprite)
		"half_width": 26.0,  # TUNING (not in GDD) px
		"run_damage": 10.0,  # TUNING (not in GDD) before the time scaling (the tank 9)
		"main_every": 6.0,  # TUNING (not in GDD) s
		"main_range": 420.0,  # TUNING (not in GDD) px
		"main_windup": 1.4,  # TUNING (not in GDD) s (its landing circle)
		"main_radius": 46.0,  # TUNING (not in GDD) px
		"main_damage": 9.0,  # TUNING (not in GDD) before the time scaling
		"twin_every": 4.0,  # TUNING (not in GDD) s
		"twin_count": 4,  # TUNING (not in GDD) shells in a line
		"twin_start": 70.0,  # TUNING (not in GDD) px in front of it the line starts
		"twin_gap": 52.0,  # TUNING (not in GDD) px between two shells of the line
		"twin_walk": 0.18,  # TUNING (not in GDD) s between two shells landing
		"twin_windup": 1.0,  # TUNING (not in GDD) s (the first landing circle)
		"twin_radius": 26.0,  # TUNING (not in GDD) px
		"twin_damage": 4.0,  # TUNING (not in GDD) before the time scaling
		"reward_xp": 260,  # TUNING (not in GDD) a miniboss (Old Greymane 220)
		"reward_crystals": 12,  # TUNING (not in GDD)
	},  # Mammoth (Fort Kessler).
}
