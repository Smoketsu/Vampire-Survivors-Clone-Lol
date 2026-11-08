## NecropolisEnemyData — the kinds of the Necropolis of Sand (stage 1 of the act) (temporary Act XII, the
## Necropolis Dynasty; GDD §15.0 "The Necropolis Dynasty foundation (phase
## 1)" and "The Necropolis of Sand (Act XII phase 2)"):
##   sand_colossus — the stage MINIBOSS (owner-approved proposal: "A huge
##                   statue; ground slam | Burst; stay at range"): a walking
##                   sandstone king (group "stone": statues never return) whose
##                   GROUND SLAM (SandColossusKit) breaks the ground round him.
##                   The Temple of the Lioness may reuse it (its Awakening
##                   Statues: "each becomes an Ushabti or a Sand Colossus").
## The Nile Archer and the Jackal Warrior are shared rows (DynastyEnemyData,
## the Necropolis's block at its end), so every Dynasty stage may field them.
## EnemyDirector.dynasty_def() looks these rows up after DynastyEnemyData.
## Rows have every key of a DynastyEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/dynasty/<kit>_kit.gd, unique across every kit
## folder; "group", "rebirth", "fire_taken", "embalms", "holds_names" and
## "storm_silenced" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot VII.
class_name NecropolisEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const COLOSSUS: String = "sand_colossus"
## Damage tag of the Sand Colossus's ground slam (stats, the death line).
const SLAM_SOURCE: String = "colossus_slam"

## Kind id -> design row.
const ENEMIES := {
	# THE SAND COLOSSUS, the stage miniboss: a huge sandstone statue king who
	# walks (the shared melee AI; his stone fists in reach) and, every
	# slam_every s once a summon or a necromancer stands within slam_radius
	# px, raises both fists for slam_windup s (a telegraph circle round him)
	# and SLAMS the ground: every summon and necromancer within slam_radius
	# takes slam_damage_summon / slam_damage (x the time scaling), each summon
	# hit is stunned slam_stun s (CombatResolver.stun_unit(), the one summon
	# stun path), and the broken ground turns to quicksand for slam_sand_life
	# s (Quicksand.add_patch(), THE public call). Stone: flat armour, no
	# Rebirth, no fire weakness. Killed, he drops an XP burst (reward_xp in
	# reward_crystals) and the miniboss chest. SandColossusKit.
	"sand_colossus": {
		"display_name": "Sand Colossus",
		"max_hp": 2400.0,  # TUNING (not in GDD) a miniboss before the time / stage scaling (Brood Matriarch 1300 x 2.15; the Province's 2600 x 1.55)
		"move_speed": 30.0,  # TUNING (not in GDD) px/s; a walking statue
		"damage": 13.0,  # TUNING (not in GDD) a stone fist, before the time scaling
		"attack_interval": 1.8,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px (~84 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) sandstone
		"flat_armor": 3.0,  # TUNING (not in GDD) a statue: chip damage glances off (Cyclops 3, Sanctified Sentinel 6)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 20.0,  # TUNING (not in GDD) the ring does not shove a statue
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": DynastyEnemyData.FACTION,
		"kit": "sand_colossus",
		"group": "stone",  # Statues never return (no "rebirth").
		"slam_first": 3.0,  # TUNING (not in GDD) s after he arrives
		"slam_every": 6.5,  # TUNING (not in GDD) s between two slams
		"slam_windup": 1.1,  # TUNING (not in GDD) s with both fists raised (the telegraph)
		"slam_radius": 92.0,  # TUNING (not in GDD) px round him ("stay at range")
		"slam_damage": 14.0,  # TUNING (not in GDD) to a necromancer, before the time scaling
		"slam_damage_summon": 13.0,  # TUNING (not in GDD) to each summon, before the time scaling (first pass 16: 4,900 to the seed-7 army, its ring broke at 12:00)
		"slam_stun": 0.6,  # TUNING (not in GDD) s each summon hit is stunned
		"slam_sand": 70.0,  # TUNING (not in GDD) px of the quicksand the slam leaves
		"slam_sand_life": 8.0,  # TUNING (not in GDD) s
		"reward_xp": 240,  # TUNING (not in GDD) as the Brood Matriarch (220)
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # The Sand Colossus.
}
