## SanctumObjectiveData — immutable design data for the Sanctum of
## Judgment's destructible objectives (GDD §7.4 "Ward crystals: sanctified
## chambers punish undead until crystals are destroyed"; "Sacred altars:
## destroying them weakens later enemies"). EnemyDirector.enemy_def() finds
## these kinds after EnemyData.ENEMIES; SanctumDirector places and tracks
## them (the chamber / altar rules themselves are SanctumStage.SANCTUM).
##
## Every row has all the keys of an EnemyData.ENEMIES row (same meaning) plus
## `is_structure` (MarchEnemyData header: never recycled, no target picking,
## no separation steering; a Soul Nova treats them like elites). The GDD
## gives no numbers: everything is TUNING (not in GDD).
class_name SanctumObjectiveData
extends RefCounted

## The Sanctum's objective structures.
const STRUCTURES := {
	# GDD §7.4 "Ward crystals": two per sanctified chamber; the chamber's holy
	# ground lasts until every one of them is destroyed.
	"ward_crystal": {
		"display_name": "Ward Crystal",
		"max_hp": 260.0,  # TUNING (not in GDD) ~370 HP at 3:00, ~600 at 5:30 after time / stage scaling
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 15.0,  # TUNING (not in GDD)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is SanctumDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) top priority for the army, like a ward generator
		"mass": 60.0,  # Immovable.
		"is_structure": true,
	},
	# GDD §7.4 / §8.3 "Sacred altars": optional; each one destroyed weakens
	# every Covenant soldier spawned afterwards (SanctumStage.SANCTUM).
	"sacred_altar": {
		"display_name": "Sacred Altar",
		"max_hp": 450.0,  # TUNING (not in GDD) ~1,900 HP at 10:30 after time / stage scaling
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is SanctumDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
	},
}
