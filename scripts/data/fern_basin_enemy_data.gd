## FernBasinEnemyData — the kinds of THE FERN BASIN's own (temporary Act XIV,
## the Age of Titans, final slot XIV; GDD §15.0 "The Age of Titans foundation
## (phase 1)" and "The Fern Basin (Act XIV phase 2)"):
##   ironjaw        — the stage MINIBOSS (owner-approved proposal: "Ironjaw,
##                    the Nest Mother (female), a bulky predator who defends a
##                    nest"): IronjawKit, group "titans".
##   primeval_nest  — her NEST ("the nest spawns Scuttlers until it is
##                    destroyed"): a structure (PrimevalNestKit), group "swarm".
##   scarmaw_guard  — SCARMAW's ALPHA-GUARD (owner-approved proposal: "Blood Up:
##                    ... kill her alpha-guard to end it"): a great Razorclaw
##                    that runs alone (no pack; RazorclawKit), group "hunters".
## The Bog Croc is a shared row (PrimevalEnemyData, the Fern Basin's block), so
## every Titans stage may field it.
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind). The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal. Tuned for the act's FINAL
## slot XIV.
class_name FernBasinEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const IRONJAW: String = "ironjaw"
## Kind id of her nest.
const NEST: String = "primeval_nest"
## Kind id of Scarmaw's alpha-guard.
const GUARD: String = "scarmaw_guard"

## Kind id -> design row.
const ENEMIES := {
	# IRONJAW, THE NEST MOTHER, the stage miniboss: a bulky tar-dark predator
	# with an iron-grey jaw. The shared melee AI walks her in; every bite_every
	# s she rears for bite_windup s (a line shows her lunge) and LUNGES
	# bite_len px at bite_speed px/s, biting the first summon or necromancer she
	# touches for bite_damage / bite_player (x the time scaling). While her nest
	# stands she DEFENDS it: she takes x nest_ward damage (break the nest
	# first). Killed, she drops an XP burst (reward_xp in reward_crystals) and
	# the miniboss chest.
	"ironjaw": {
		"display_name": "Ironjaw, the Nest Mother",
		"max_hp": 1200.0,  # TUNING (not in GDD) a miniboss (the Brood Matriarch 1300, the Cherub of the Gate 2000 at x1.7; first pass 1500: with her nest she broke the naive bot's army on seeds 3, 7, 11)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 11.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px (~80 x 60 px sprite)
		"armor": 0.25,  # TUNING (not in GDD) a thick hide
		"xp": 0,  # Her XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 14.0,  # TUNING (not in GDD) the ring does not shove her
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 220,  # TUNING (not in GDD) as the Brood Matriarch
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": PrimevalEnemyData.FACTION,
		"kit": "ironjaw",
		"group": "titans",
		"bite_first": 3.0,  # TUNING (not in GDD) s after she arrives
		"bite_every": 7.0,  # TUNING (not in GDD) s between two lunges (first pass 6)
		"bite_windup": 0.8,  # TUNING (not in GDD) s of telegraph
		"bite_trigger": 200.0,  # TUNING (not in GDD) px: a body this close starts a lunge
		"bite_len": 120.0,  # TUNING (not in GDD) px at most
		"bite_speed": 360.0,  # TUNING (not in GDD) px/s
		"bite_damage": 13.0,  # TUNING (not in GDD) to the summon she seizes, before the time scaling (first passes 20, 16)
		"bite_player": 12.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
		"nest_ward": 0.6,  # Owner-approved proposal: "who defends a nest"; TUNING (not in GDD) x damage taken while it stands (first pass 0.5)
	},  # Ironjaw.
	# HER NEST (owner-approved proposal: "the nest spawns Scuttlers until it is
	# destroyed"): a mound of fern and eggshells. It never moves or attacks;
	# every brood_every s it hatches `brood` Scuttlers beside it (at most
	# brood_cap of its own alive). FernBasinDirector lays it beside Ironjaw and
	# keeps it on the field (never recycled). Destroyed, it drops a small XP
	# burst (reward_xp in reward_crystals). PrimevalNestKit.
	"primeval_nest": {
		"display_name": "Ironjaw's Nest",
		"max_hp": 500.0,  # TUNING (not in GDD) a structure (x the time and stage scaling; first pass 700)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px (~48 x 32 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # Its XP is the burst.
		"behavior": "structure",  # It never moves.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; break it first
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback; a summon blocking it takes the whole correction.
		"faction": PrimevalEnemyData.FACTION,
		"kit": "primeval_nest",
		"group": "swarm",
		"brood_first": 2.0,  # TUNING (not in GDD) s after it is laid
		"brood_every": 5.5,  # TUNING (not in GDD) s (first pass 4.5)
		"brood": 2,  # TUNING (not in GDD) Scuttlers a hatching (first pass 3)
		"brood_cap": 8,  # TUNING (not in GDD) of its own Scuttlers alive at most (first pass 14)
		"brood_kind": PrimevalEnemyData.SCUTTLER,  # Owner-approved proposal: "spawns Scuttlers"
		"reward_xp": 60,  # TUNING (not in GDD)
		"reward_crystals": 5,  # TUNING (not in GDD)
	},  # Ironjaw's nest.
	# SCARMAW'S ALPHA-GUARD (owner-approved proposal: "Blood Up: at half health
	# her pack respawns for every kill and she moves faster; kill her
	# alpha-guard to end it"): a great female Razorclaw with a bone crest, who
	# runs alone beside Scarmaw (no pack: the shared melee AI). BossScarmaw
	# calls her and watches her.
	"scarmaw_guard": {
		"display_name": "Scarmaw's Alpha-Guard",
		"max_hp": 520.0,  # TUNING (not in GDD) an elite hunter (x the time and stage scaling)
		"move_speed": 74.0,  # TUNING (not in GDD) px/s
		"damage": 8.0,  # TUNING (not in GDD) a rake, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 9.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (the alpha's 48 px art)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1; kill her to end Blood Up
		"mass": 2.0,  # TUNING (not in GDD)
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"faction": PrimevalEnemyData.FACTION,
		"kit": "razorclaw",  # The Razorclaw's kit without a pack (row "pack" off: the shared melee AI).
		"group": "hunters",
	},  # Scarmaw's alpha-guard.
}
