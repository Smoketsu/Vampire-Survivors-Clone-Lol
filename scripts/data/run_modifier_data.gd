## RunModifierData — designer-tunable data for the eight optional RUN
## MODIFIERS of GDD §8.5. Each one is toggled on the pre-run setup screen
## (PreRunSetup), they stack freely, and each makes the run harder in its own
## way and adds a Soul Ash reward ("Modifier stacking must show the total
## reward multiplier, not hide it", §8.5). The GDD gives magnitudes for three
## of them (Endless Crusade, Hardened Faith, Divine Fury); the rest and every
## reward are TUNING (open question 38). No logic here: DifficultyModifiers
## (the one difficulty path) reads it.
##
## The chosen ids live in RunConfig.modifiers.
##
## Keys of a modifier row:
##   display_name  UI name (GDD §8.5 name).
##   short_name    one word for the HUD Modifiers area.
##   description   UI effect line (setup screen, end screen).
##   ash_gain      Soul Ash reward: + this fraction of the run subtotal.
##                 Every active modifier's ash_gain ADDS into one end-screen
##                 line ("Run modifiers").
##   effects       what it does; the keys are read by DifficultyModifiers:
##     BONUS keys (summed over the active modifiers, then joined with the
##     Profane Pact / Oath bonus of the same key, see DifficultyModifiers):
##       enemy_spawn       + trickle spawn rate and soft cap
##       enemy_hp          + enemy HP (the boss gets PactData.BOSS_HP_SHARE of it)
##       enemy_damage      + enemy damage
##     BONUS keys of their own category (summed, applied as 1 + sum):
##       minion_damage     + summon damage (HordeDirector.compute_stats)
##       minion_hp         + summon max HP (negative = less HP)
##     FACTOR keys (multiplied over the active modifiers; 1 = unchanged):
##       purifier_weight   x the Purifier share of every trickle segment
##       player_hp         x the necromancer's starting max HP (after the
##                         Soul Ash upgrades; later +max HP cards add on top)
##       feast_heal        x the HP a Grave Feast drop restores
##       feast_weight      x the Grave Feast weight in the power-up draw
##     OTHER keys:
##       purifier_add      Purifier weight added to trickle segments that
##                         have none, from purifier_from s on (more of them,
##                         and earlier)
##       purifier_from     game time (s) from which purifier_add applies
##       radiant_bolts     radiant bolts an elite fires in a ring when it
##                         dies (Covenant projectiles: orbs intercept them,
##                         they hit the necromancer or a summon)
##       radiant_damage    damage of one bolt before the time scaling
##                         (x EnemyDirector.damage_mult, like every enemy hit)
##       radiant_speed     bolt speed (px/s); range = speed x 2 s lifetime
class_name RunModifierData
extends RefCounted

## Modifier ids in UI order (--modifiers= values).
const ORDER := ["endless_crusade", "hardened_faith", "divine_fury", "purge_the_unholy",
	"scarcity", "frail_master", "vengeful_dead", "holy_retribution"]

## Every modifier (see the header for the keys).
const MODIFIERS := {
	"endless_crusade": {
		"display_name": "Endless Crusade",  # GDD §8.5
		"short_name": "Crusade",
		"description": "+30% enemy spawn rate (and a 30% larger horde on the field).",
		"ash_gain": 0.2,  # TUNING (not in GDD)
		"effects": {"enemy_spawn": 0.3},  # GDD §8.5 "+30% enemy spawn rate"
	},
	"hardened_faith": {
		"display_name": "Hardened Faith",  # GDD §8.5
		"short_name": "Faith",
		"description": "+25% enemy health (the boss gets a fifth of it).",
		"ash_gain": 0.2,  # TUNING (not in GDD)
		"effects": {"enemy_hp": 0.25},  # GDD §8.5 "+25% enemy health"
	},
	"divine_fury": {
		"display_name": "Divine Fury",  # GDD §8.5
		"short_name": "Fury",
		"description": "+20% enemy damage.",
		"ash_gain": 0.2,  # TUNING (not in GDD)
		"effects": {"enemy_damage": 0.2},  # GDD §8.5 "+20% enemy damage"
	},
	"purge_the_unholy": {
		"display_name": "Purge the Unholy",  # GDD §8.5
		"short_name": "Purge",
		"description": "More Purifiers: x2.5 of them, and they join the march from 3:00.",
		"ash_gain": 0.15,  # TUNING (not in GDD)
		"effects": {
			"purifier_weight": 2.5,  # TUNING (not in GDD) GDD §8.5 "More Purifiers"
			"purifier_add": 0.08,  # TUNING (not in GDD)
			"purifier_from": 180.0,  # TUNING (not in GDD) 17:00 left on the countdown
		},
	},
	"scarcity": {
		"display_name": "Scarcity",  # GDD §8.5
		"short_name": "Scarcity",
		"description": "Grave Feast drops are 60% rarer and heal half as much.",
		"ash_gain": 0.1,  # TUNING (not in GDD)
		"effects": {
			"feast_weight": 0.4,  # TUNING (not in GDD) GDD §8.5 "Reduced healing drops"
			"feast_heal": 0.5,  # TUNING (not in GDD)
		},
	},
	"frail_master": {
		"display_name": "Frail Master",  # GDD §8.5
		"short_name": "Frail",
		"description": "The necromancer starts with 30% less max HP.",
		"ash_gain": 0.15,  # TUNING (not in GDD)
		"effects": {"player_hp": 0.7},  # TUNING (not in GDD) GDD §8.5 "Reduced player starting HP"
	},
	"vengeful_dead": {
		"display_name": "Vengeful Dead",  # GDD §8.5
		"short_name": "Vengeful",
		"description": "Your undead deal 20% more damage but have 30% less HP.",
		"ash_gain": 0.1,  # TUNING (not in GDD)
		"effects": {
			"minion_damage": 0.2,  # TUNING (not in GDD) GDD §8.5 "Minion damage up"
			"minion_hp": -0.3,  # TUNING (not in GDD) GDD §8.5 "minion HP down"
		},
	},
	"holy_retribution": {
		"display_name": "Holy Retribution",  # GDD §8.5
		"short_name": "Retribution",
		"description": "Slain elites burst into a ring of 8 radiant bolts.",
		"ash_gain": 0.15,  # TUNING (not in GDD)
		"effects": {
			"radiant_bolts": 8,  # TUNING (not in GDD) GDD §8.5 "Elites emit radiant attacks on death"
			"radiant_damage": 9.0,  # TUNING (not in GDD) x damage_mult: ~23 per bolt at 15:00
			"radiant_speed": 150.0,  # TUNING (not in GDD) 300 px reach
		},
	},
}
