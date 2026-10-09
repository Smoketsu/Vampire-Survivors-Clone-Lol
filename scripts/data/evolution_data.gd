## EvolutionData — immutable design data for spell evolutions (GDD §6.1
## "Evolution Recipes", §5.1 evolution behaviour):
##   Shadow Bolt       + Soul Conduit   = Void Barrage
##   Shadow Orb Shield + Warding Ritual = Eclipse Ward
##   Shadow Blast      + Abyssal Focus  = Abyssal Detonation
##
## Evolution condition (GDD open question 27 is unresolved; prototype decision,
## recorded in GDD §15.0): the base spell is at its max level (5) and the
## paired passive is at level 1 or higher. The GDD's "special elite reward" is
## not implemented yet. While the condition holds, every level-up includes the
## evolution as a highlighted gold card; picking it replaces the base spell in
## its active slot (no extra slot is used) and the passive is kept.
##
## Each evolution has ONE stats row (it does not level further). Keys reuse the
## base spell's keys so the casting code, the card deltas and the passive
## modifiers (Soul Conduit damage, Abyssal Focus cooldowns) work unchanged; new
## keys add the evolved behaviour. All numbers are TUNING (not in GDD).
class_name EvolutionData
extends RefCounted

## Base spell level required before its evolution can be offered.
const BASE_LEVEL_REQUIRED: int = 5  # TUNING (not in GDD) decision for open question 27
## Paired passive level required before the evolution can be offered.
const PASSIVE_LEVEL_REQUIRED: int = 1  # TUNING (not in GDD) decision for open question 27

## Display / card order of evolutions.
const ORDER := ["void_barrage", "eclipse_ward", "abyssal_detonation"]

## Evolution definitions.
##   base         — spell id that evolves (AbilityData.SPELLS key).
##   passive      — paired passive id (PassiveData.PASSIVES key).
##   display_name — UI name.
##   icon         — IconGlyph kind (drawn by ProgressionGlyphs).
##   description  — card text (GDD §5.1 wording).
##   labels       — stat key -> UI label, in card order. Keys missing from the
##                  base spell are shown as new stats.
##   stats        — absolute stats of the evolved spell.
##
## Void Barrage extra keys:
##   split (shards released on the first enemy a bolt hits), split_damage
##   (fraction of bolt damage per shard), split_speed (px/s), split_life (s).
## Eclipse Ward extra keys:
##   pulse_damage, pulse_radius (px), pulse_interval (s), pulse_knockback
##   (px/s outward impulse, divided by enemy mass).
## Abyssal Detonation extra keys:
##   second_delay (s between the two hits), second_damage (fraction of damage
##   dealt by the second hit), pull (px/s inward impulse toward the blast
##   centre, divided by enemy mass), pull_inner (fraction of the radius inside
##   which enemies are no longer pulled).
const EVOLUTIONS := {
	"void_barrage": {
		"base": "shadow_bolt",
		"passive": "soul_conduit",
		"display_name": "Void Barrage",
		"icon": "void_barrage",
		"description": "Rapid piercing void bolts that split into shards on impact.",
		"labels": {"damage": "Damage", "count": "Bolts", "cooldown": "Cooldown (s)", "pierce": "Pierce", "split": "Split shards"},
		"stats": {
			"damage": 30.0, "cooldown": 0.5, "count": 4, "pierce": 3, "speed": 540.0, "range": 460.0,  # TUNING (not in GDD)
			"split": 3, "split_damage": 0.5, "split_speed": 380.0, "split_life": 0.45,  # TUNING (not in GDD)
		},
	},
	"eclipse_ward": {
		"base": "orb_shield",
		"passive": "warding_ritual",
		"display_name": "Eclipse Ward",
		"icon": "eclipse_ward",
		"description": "A rotating eclipse barrier of six orbs that releases periodic damage pulses.",
		"labels": {"orbs": "Orbs", "damage": "Damage", "recharge": "Intercept recharge (s)", "pulse_damage": "Pulse damage", "pulse_interval": "Pulse every (s)"},
		"stats": {
			"orbs": 6, "damage": 24.0, "orbit_radius": 74.0, "orbit_speed": 4.2, "hit_cooldown": 0.4, "recharge": 2.0,  # TUNING (not in GDD)
			"pulse_damage": 34.0, "pulse_radius": 120.0, "pulse_interval": 2.4, "pulse_knockback": 170.0,  # TUNING (not in GDD)
		},
	},
	"abyssal_detonation": {
		"base": "shadow_blast",
		"passive": "abyssal_focus",
		"display_name": "Abyssal Detonation",
		"icon": "abyssal_detonation",
		"description": "The abyss opens twice: a blast that drags foes inward, then a second detonation.",
		"labels": {"damage": "Damage", "radius": "Radius", "cooldown": "Cooldown (s)", "slow": "Slow", "second_damage": "Second hit"},
		"stats": {
			"damage": 60.0, "radius": 150.0, "cooldown": 2.6, "slow": 0.6, "slow_duration": 2.0,  # TUNING (not in GDD)
			"second_delay": 0.4, "second_damage": 0.8, "pull": 240.0, "pull_inner": 0.35,  # TUNING (not in GDD)
		},
	},
}


## Returns the evolution id whose base spell is `spell_id` ("" if none).
static func for_spell(spell_id: String) -> String:
	for id: String in ORDER:
		if String(EVOLUTIONS[id]["base"]) == spell_id:
			return id
	return ""
