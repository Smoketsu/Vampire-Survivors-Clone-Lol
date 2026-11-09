## SilverStairEnemyData — the kinds of THE SILVER STAIR's own (temporary Act
## XIII, the Celestial Host; GDD §15.0 "The Celestial Host foundation (phase
## 1)" and "The Silver Stair (Act XIII phase 2)"):
##   cherub_of_the_gate — the stage MINIBOSS (owner-approved proposal: "the
##                        Cherub of the Gate, whose flaming sword turns in a
##                        full circle every 6 s"): a larger Cherub (CherubKit,
##                        group "guardians") whose sword NEVER STOPS turning
##                        (sword "every" 0): one full circle every 6 s.
## The Cherub itself is a shared row (HostEnemyData, the Silver Stair's block),
## so every Host stage may field it.
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot X.
class_name SilverStairEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const CHERUB_OF_THE_GATE: String = "cherub_of_the_gate"

## Kind id -> design row.
const ENEMIES := {
	# THE CHERUB OF THE GATE, the stage miniboss: a towering Cherub whose
	# flaming sword turns without pause, one full circle every sword.turn s
	# (the owner-approved 6 s), cutting every summon and necromancer it passes
	# within sword.reach px. The shared melee AI walks it in. Killed, it drops
	# an XP burst (reward_xp in reward_crystals) and the miniboss chest.
	"cherub_of_the_gate": {
		"display_name": "Cherub of the Gate",
		"max_hp": 2000.0,  # TUNING (not in GDD) a miniboss before the time / stage scaling (the Sand Colossus 2400 at x1.5; here x1.7)
		"move_speed": 30.0,  # TUNING (not in GDD) px/s
		"damage": 14.0,  # TUNING (not in GDD) a blow in reach, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px (~76 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 20.0,  # TUNING (not in GDD) the ring does not shove it
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 220,  # TUNING (not in GDD) as the Sand Colossus
		"reward_crystals": 12,  # TUNING (not in GDD)
		"faction": HostEnemyData.FACTION,
		"kit": "cherub",
		"group": "guardians",
		"halo": true,  # Owner-approved proposal: Grace (every angel)
		"sword": {
			"first": 1.5,  # TUNING (not in GDD) s after it arrives
			"every": 0.0,  # Owner-approved proposal: the sword never stops turning
			"windup": 0.0,  # No telegraph: it always turns
			"turn": 6.0,  # Owner-approved proposal: "turns in a full circle every 6 s"
			"turns": 1,
			"reach": 76.0,  # TUNING (not in GDD) px (first pass 96: it cut the whole Bone Ring)
			"damage_summon": 9.0,  # TUNING (not in GDD) per summon passed (once a turn), before the time scaling (first pass 22: the seed-7 army bot's ring collapsed under it)
			"damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
		},
	},
}
