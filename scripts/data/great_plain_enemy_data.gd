## GreatPlainEnemyData — the kinds of THE GREAT PLAIN's own (temporary Act XIV,
## the Age of Titans, final slot XIV; GDD §15.0 "The Age of Titans foundation
## (phase 1)" and "The Great Plain (Act XIV phase 2)"):
##   mother_clubtail — the stage MINIBOSS (owner-approved proposal: "Mother
##                     Clubtail (female), an armoured matriarch who guards a
##                     herd"): ClubtailKit with the miniboss keys, group
##                     "titans". GreatPlainDirector brings her herd beside her
##                     and links it (ClubtailKit.link_herd()).
## The Horncharger and the Clubtail are shared rows (PrimevalEnemyData, the
## Great Plain's block), so every Titans stage may field them.
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind). The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal. Tuned for the act's FINAL
## slot XIV.
class_name GreatPlainEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const MOTHER: String = "mother_clubtail"

## Kind id -> design row.
const ENEMIES := {
	# MOTHER CLUBTAIL, the stage miniboss: a great armoured matriarch with a
	# bone club as big as a boulder. Everything a Clubtail does (the sweep,
	# the flat armour), bigger; and she GUARDS A HERD: while a beast of the
	# herd she came with grazes within guard_radius px of her she takes x
	# herd_ward damage (ClubtailKit.taken_mult(): stampede her herd away, or
	# bring it down, to break her guard). Killed, she drops an XP burst
	# (reward_xp in reward_crystals) and the miniboss chest.
	"mother_clubtail": {
		"display_name": "Mother Clubtail",
		"max_hp": 1000.0,  # TUNING (not in GDD) a miniboss (Ironjaw 1200 on the Fern Basin, but her plates and her guard are tougher; first passes 1300, 1150)
		"move_speed": 38.0,  # TUNING (not in GDD) px/s
		"damage": 11.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px (~88 x 60 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"flat_armor": 5.0,  # TUNING (not in GDD) a Clubtail's 5 (first pass 7: the naive bot never brought her down)
		"xp": 0,  # Her XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 16.0,  # TUNING (not in GDD) the ring does not shove her
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 240,  # TUNING (not in GDD) a little over Ironjaw's 220
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": PrimevalEnemyData.FACTION,
		"kit": "clubtail",
		"group": "titans",
		"sweep_first": 3.0,  # TUNING (not in GDD) s after she arrives
		"sweep_every": 5.5,  # TUNING (not in GDD) s between two sweeps
		"sweep_windup": 0.9,  # TUNING (not in GDD) s of telegraph
		"sweep_radius": 84.0,  # TUNING (not in GDD) px round her
		"sweep_damage": 8.0,  # TUNING (not in GDD) to each summon in reach, before the time scaling (first pass 11)
		"sweep_player": 10.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
		"sweep_knock": 70.0,  # TUNING (not in GDD) px (first pass 90)
		"herd_ward": 0.65,  # Owner-approved proposal: "who guards a herd"; TUNING (not in GDD) x damage taken while her herd grazes by her (first pass 0.5)
		"guard_radius": 320.0,  # TUNING (not in GDD) px: a beast of her herd this close keeps her guard up
	},  # Mother Clubtail.
}
