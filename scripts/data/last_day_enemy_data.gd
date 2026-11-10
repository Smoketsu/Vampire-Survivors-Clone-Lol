## LastDayEnemyData — the kinds of THE LAST DAY's own (temporary Act XIV, the
## Age of Titans' finale, final slot XIV; GDD §15.0 "The Age of Titans
## foundation (phase 1)" and "The Last Day (Act XIV phase 2)"):
##   thunderwing — the stage MINIBOSS (owner-approved proposal: "Thunderwing,
##                 the Sky King (male), a giant pterosaur whose wing gusts
##                 clear the ring"): StormwingKit with the miniboss keys, group
##                 "fliers". LastDayDirector brings him ("sky_king" event).
## The Stormwing is a shared row (PrimevalEnemyData, the Last Day's block), so
## every Titans stage may field it; the Tyrant's swallow and roar are its own
## row's keys (TyrantKit).
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind). The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal. Tuned for the act's FINAL
## slot XIV.
class_name LastDayEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const THUNDERWING: String = "thunderwing"

## Kind id -> design row.
const ENEMIES := {
	# THUNDERWING, THE SKY KING, the stage miniboss: a giant pterosaur, his
	# wings as wide as a herd (a beast: no figure style). Everything a
	# Stormwing does, bigger: his gust clears the whole ring (gust_radius past
	# the Bone Ring's outer posts, gust_push px) and he lands longer. Killed,
	# he drops an XP burst (reward_xp in reward_crystals) and the miniboss
	# chest.
	"thunderwing": {
		"display_name": "Thunderwing, the Sky King",
		"max_hp": 1100.0,  # TUNING (not in GDD) a miniboss (Mother Clubtail 1000; he spends most of his time in the air)
		"move_speed": 120.0,  # TUNING (not in GDD) px/s in the air
		"damage": 12.0,  # TUNING (not in GDD) a peck, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px (~112 x 64 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 12.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"flies": true,  # A pterosaur (grounded while he lands).
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 260,  # TUNING (not in GDD) a little over Mother Clubtail's 240
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": PrimevalEnemyData.FACTION,
		"kit": "stormwing",
		"group": "fliers",
		"hover_radius": 210.0,  # TUNING (not in GDD) px from the necromancer he circles
		"hover_orbit": 0.7,  # TUNING (not in GDD) rad/s
		"gust_first": 3.0,  # TUNING (not in GDD) s after he arrives
		"gust_every": 8.0,  # TUNING (not in GDD) s between two gusts
		"gust_windup": 1.2,  # TUNING (not in GDD) s of telegraph
		"gust_radius": 190.0,  # Owner-approved proposal: "wing gusts clear the ring"; TUNING (not in GDD) px round the necromancer
		"gust_push": 140.0,  # TUNING (not in GDD) px (a Stormwing's 100)
		"gust_damage": 5.0,  # TUNING (not in GDD) to each summon pushed, before the time scaling
		"land_time": 4.0,  # TUNING (not in GDD) s he stands at the landing circle and pecks
		"land_speed": 240.0,  # TUNING (not in GDD) px/s
	},  # Thunderwing, the Sky King.
}
