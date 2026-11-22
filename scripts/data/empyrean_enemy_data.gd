## EmpyreanEnemyData — the kinds of THE EMPYREAN's own (temporary Act XIII, the
## Celestial Host; GDD §15.0 "The Celestial Host foundation (phase 1)" and "The
## Empyrean (Act XIII phase 2)"):
##   herald_of_the_seventh_trumpet — the stage MINIBOSS (owner-approved
##                        proposal: "the Herald of the Seventh Trumpet, whose
##                        trumpets call the squads of all the earlier zones"):
##                        a larger Herald (SeventhHeraldKit, group
##                        "guardians"): every blast pushes the ring back and
##                        calls the NEXT of `zone_squads` (one squad per earlier
##                        zone of the Rose, in order, then round again), at most
##                        `calls` (seven trumpets) in his life.
## The Voice's waves of Judges reuse the shared "judge" row (the Last Word,
## Judgment.send_wave()).
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot X.
class_name EmpyreanEnemyData
extends RefCounted

## Kind id of the stage miniboss.
const HERALD_OF_THE_SEVENTH_TRUMPET: String = "herald_of_the_seventh_trumpet"

## Kind id -> design row.
const ENEMIES := {
	# THE HERALD OF THE SEVENTH TRUMPET, the stage miniboss: a towering Herald
	# with a great trumpet. The shared melee AI walks him in; every blast
	# (HeraldKit's: a windup ring, the ring pushed back) calls down the next
	# earlier zone's squad round him. Killed, he drops an XP burst (reward_xp in
	# reward_crystals) and the miniboss chest.
	"herald_of_the_seventh_trumpet": {
		"display_name": "Herald of the Seventh Trumpet",
		"max_hp": 1500.0,  # TUNING (not in GDD) a miniboss before the time / stage scaling (the Dominion of the Spheres 1800; a first pass 1900 outlived most army bot runs, calling all seven squads)
		"move_speed": 32.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) a blow of the trumpet, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
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
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1; "kill on arrival", as every Herald
		"mass": 20.0,  # TUNING (not in GDD) the ring does not shove him
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"reward_xp": 220,  # TUNING (not in GDD) as the other Host minibosses
		"reward_crystals": 12,  # TUNING (not in GDD)
		"faction": HostEnemyData.FACTION,
		"kit": "seventh_herald",
		"group": "guardians",
		"halo": true,  # Owner-approved proposal: Grace (every angel)
		"blast": {
			"first": 2.5,  # TUNING (not in GDD) s after he arrives
			"every": 11.0,  # TUNING (not in GDD) s between two blasts
			"windup": 1.1,  # TUNING (not in GDD) s he raises the great trumpet
			"radius": 140.0,  # TUNING (not in GDD) px of the push (first pass 170)
			"push": 34.0,  # TUNING (not in GDD) px a summon is pushed back (first pass 50: the ring never held)
			"calls": 7,  # Owner-approved proposal: the SEVENTH trumpet: seven calls in his life, then only the push
			"squad": [],  # Unused: each call is the next of zone_squads.
			# One squad per earlier zone of the Rose, called in this order (then
			# round again): the Rose's Edge, the Petals, the Choir.
			"zone_squads": [
				[{"kind": "lesser_light", "count": 6}, {"kind": "virtue", "count": 2}],  # TUNING (not in GDD) the Rose's Edge
				[{"kind": "power", "count": 2}, {"kind": "virtue", "count": 2}],  # TUNING (not in GDD) the Petals
				[{"kind": "choir_angel", "count": 1}, {"kind": "power", "count": 2}],  # TUNING (not in GDD) the Choir
			],
		},
	},
}
