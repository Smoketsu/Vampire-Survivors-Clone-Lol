## WheelOfThronesEnemyData — the kinds of THE WHEEL OF THRONES' own (temporary
## Act XIII, the Celestial Host; GDD §15.0 "The Celestial Host foundation
## (phase 1)" and "The Wheel of Thrones (Act XIII phase 2)"):
##   dominion_of_the_spheres — the stage MINIBOSS (owner-approved proposal:
##                             "the Dominion of the Spheres, who keeps halos
##                             returning across the whole zone until he
##                             falls"): a larger Dominion (SpheresDominionKit,
##                             group "guardians") whose regrowth reaches
##                             regrow_radius px (Grace.step(): the whole zone
##                             round him), not only his aura.
## The Ophan itself is a shared row (HostEnemyData, the Wheel of Thrones'
## block), so every Host stage may field it.
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind),
## plus:
##   regrow_radius — px round a regrower within which Grace makes halos whole
##                   again (absent = its aura_radius).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot X.
class_name WheelOfThronesEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const DOMINION_OF_THE_SPHERES: String = "dominion_of_the_spheres"

## Kind id -> design row.
const ENEMIES := {
	# THE DOMINION OF THE SPHERES, the stage miniboss: a towering Dominion
	# among crystal rings. Angels within his aura move faster (the shared aura
	# path); every halo within regrow_radius px that shrugged nothing off for
	# Grace's regrow s is whole again (Grace.step(), the one regrowth), so the
	# whole zone keeps its halos until he falls. The shared melee AI walks him
	# in. Killed, he drops an XP burst (reward_xp in reward_crystals) and the
	# miniboss chest.
	"dominion_of_the_spheres": {
		"display_name": "Dominion of the Spheres",
		"max_hp": 1800.0,  # TUNING (not in GDD) a miniboss before the time / stage scaling (the Cherub of the Gate 2000)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s
		"damage": 14.0,  # TUNING (not in GDD) a sceptre blow, before the time scaling
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~70 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1; "kill first"
		"mass": 20.0,  # TUNING (not in GDD) the ring does not shove him
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"aura_radius": 200.0,  # TUNING (not in GDD) px: angels near him move faster
		"aura_damage_mult": 1.0,  # No damage buff.
		"aura_speed_mult": 1.2,  # TUNING (not in GDD) x, as the Dominion
		"aura_taken_mult": 1.0,  # No damage-taken buff.
		"regrow_radius": 1400.0,  # Owner-approved proposal: "keeps halos returning across the whole zone"; TUNING (not in GDD) px (wider than the view)
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 220,  # TUNING (not in GDD) as the Cherub of the Gate
		"reward_crystals": 12,  # TUNING (not in GDD)
		"faction": HostEnemyData.FACTION,
		"kit": "spheres_dominion",
		"group": "guardians",
		"halo": true,  # Owner-approved proposal: Grace (every angel)
		"regrows": true,  # Owner-approved proposal: his halos come back (Grace's regrower list)
	},
}
