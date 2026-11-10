## WorldTreeEnemyData — the kinds of THE WORLD-TREE (temporary Act XV stage 45,
## the Turning Year's finale and the campaign's; GDD §15.0 "The World-Tree (Act
## XV phase 2)"; owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section
## XV, "Stage 45: The World-Tree"):
##   gardener_of_roots — THE GARDENER OF ROOTS, the stage miniboss: "a treant
##                       that tends the tree and calls every root in reach"
##                       (GardenerOfRootsKit: the Treant's rooting strike, and
##                       while he lives the roots grab whatever stands still
##                       within root_call_radius px of him in ANY season,
##                       through SeasonCycle.call_roots(), the roots' one path).
##   burial_thicket    — one thicket of the Green Mother's BURIAL: it grows over
##                       a summon she pulls into the earth and holds it until the
##                       ring cuts it down (BurialThicketKit).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData. Rows have
## every key of a WildEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/wild/<kit>_kit.gd, unique across every kit folder). Tuned for
## the act's FINAL slot XV; every value is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name WorldTreeEnemyData
extends RefCounted

## Kind id of the Gardener of Roots (the miniboss).
const GARDENER: String = "gardener_of_roots"

## Kind id -> design row.
const ENEMIES := {
	# THE GARDENER OF ROOTS, the stage miniboss (no sex: a great treant with
	# root-hands). The plain melee AI walks him at the necromancer; every strike
	# on a summon roots it (TreantKit: root_hold s x Deadwood). While he lives,
	# every body that stands still root_call_radius px or nearer to him is
	# grabbed by the roots whatever the season (SeasonCycle.call_roots(): the
	# Spring roots' numbers). Killed, he drops an XP burst (reward_xp in
	# reward_crystals) and the miniboss chest.
	"gardener_of_roots": {
		"display_name": "The Gardener of Roots",
		"max_hp": 1250.0,  # TUNING (not in GDD) a miniboss (the Winter Prince 1,150; slower and heavier)
		"move_speed": 38.0,  # TUNING (not in GDD) px/s; a treant
		"damage": 14.0,  # TUNING (not in GDD) a root-hand, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px (~80 x 88 px sprite)
		"armor": 0.35,  # TUNING (not in GDD) old bark
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 14.0,  # TUNING (not in GDD) the ring does not shove him
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"no_bloom": true,  # A miniboss: never heals on living ground.
		"reward_xp": 260,  # TUNING (not in GDD) as the Winter Prince
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": WildEnemyData.FACTION,
		"kit": "gardener_of_roots",
		"group": "growth",
		"root_hold": 1.4,  # TUNING (not in GDD) s x Deadwood (the Treant's 1.2)
		"root_call_radius": 300.0,  # Owner-approved proposal: "calls every root in reach"; TUNING (not in GDD) px
	},  # The Gardener of Roots.
	# One thicket of THE BURIAL (owner-approved proposal: "she pulls the summons
	# into the earth one by one; each buried summon becomes a thicket until the
	# ring cuts it free"): a structure grown over the buried summon, which it
	# holds (SummonedUnit.held_until, renewed every tick) until it falls to the
	# army's blows or its burial time runs out (BurialThicketKit). Drawn as a
	# thorn thicket. It never heals on living ground (the ring must cut it).
	"burial_thicket": {
		"display_name": "Burial Thicket",
		"max_hp": 60.0,  # TUNING (not in GDD) x the time and stage scaling (an Antler Thicket 120; first pass 110: none was cut down, seed 7)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) bark
		"xp": 0,  # It is in the way, not a prize.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1: the ring cuts its own free first
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback.
		"no_bloom": true,  # It never heals: it must be cut.
		"faction": WildEnemyData.FACTION,
		"kit": "burial_thicket",
		"group": "growth",
	},  # One burial thicket.
}
