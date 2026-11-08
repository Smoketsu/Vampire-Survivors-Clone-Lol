## TwoTruthsEnemyData — the kinds of the Hall of Two Truths (stage 3, the finale)
## (temporary Act XII, the Necropolis Dynasty; GDD §15.0 "The Hall of Two Truths
## (Necropolis Dynasty phase 2)"). The stage-only kinds:
##   devourers_whelp — the miniboss: a young hippo-lion-crocodile beast (a
##                     creature) that EATS CORPSES: it seeks the cartouches
##                     near it and eats them (Rebirth.eat(): that body never
##                     returns), healing a little and growing hungrier each
##                     time (DevourersWhelpKit).
## The Crocodile Warden is a shared kind (DynastyEnemyData, so any Dynasty stage
## may use it). EnemyDirector.dynasty_def() looks these rows up after
## DynastyEnemyData. Rows have every key of a DynastyEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/dynasty/<kit>_kit.gd, unique
## across every kit folder).
class_name TwoTruthsEnemyData
extends RefCounted

## Kind id of the Devourer's Whelp (the miniboss).
const WHELP: String = "devourers_whelp"

## Kind id -> design row.
const ENEMIES := {
	# The DEVOURER'S WHELP (owner-approved proposal: "Miniboss: The Devourer's
	# Whelp (a young hippo-lion-crocodile beast), who eats corpses"): a creature,
	# a sacred beast (no Rebirth). It bites in melee; whenever a cartouche lies
	# within seek_reach px it leaves its prey and lopes to it at seek_speed_mult
	# x its speed, and EATS it (Rebirth.eat(): the body never returns), healing
	# eat_heal of its max HP (CombatResolver.heal_enemy(), the shared heal) and
	# taking one HUNGER stack: +hunger_damage x its bite and +hunger_speed x its
	# speed each, at most hunger_max. Raise or smash the Names before it gets
	# there. Every gulp_every s it GULPS: a telegraphed bite (gulp_radius px in
	# front of it, gulp_warn s) on every summon there (gulp_damage).
	"devourers_whelp": {
		"display_name": "The Devourer's Whelp",  # Owner-approved proposal
		"max_hp": 2300.0,  # TUNING (not in GDD) a miniboss (the Kirin 2,300, Polyphemus 2,500)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~60 x 36 sprite)
		"armor": 0.2,  # TUNING (not in GDD) a thick hide
		"xp": 60,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1
		"mass": 14.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) a miniboss
		"miniboss": true,  # Its chest (ChestManager) and the HUD bar (DevourersWhelpKit registers it).
		"faction": DynastyRulesData.FACTION,
		"kit": "devourers_whelp",
		"group": "beasts",  # A sacred beast: no Rebirth.
		"seek_reach": 260.0,  # TUNING (not in GDD) px within which it smells a cartouche
		"seek_speed_mult": 1.6,  # TUNING (not in GDD) x its speed while it lopes to one
		"eat_reach": 10.0,  # TUNING (not in GDD) px between its body edge and the cartouche to eat it
		"eat_heal": 0.015,  # TUNING (not in GDD) share of its max HP a Name heals
		"hunger_damage": 0.05,  # TUNING (not in GDD) x its bite per stack
		"hunger_speed": 0.03,  # TUNING (not in GDD) x its speed per stack
		"hunger_max": 10,  # TUNING (not in GDD) stacks
		"gulp_first": 4.0,  # TUNING (not in GDD) s before its first gulp
		"gulp_every": 7.0,  # TUNING (not in GDD) s between two gulps
		"gulp_warn": 0.7,  # TUNING (not in GDD) s of telegraph
		"gulp_radius": 46.0,  # TUNING (not in GDD) px, a circle just in front of it
		"gulp_damage": 24.0,  # TUNING (not in GDD) per summon, before the time scaling
	},  # The Devourer's Whelp.
}
