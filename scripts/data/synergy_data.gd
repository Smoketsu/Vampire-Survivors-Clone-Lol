## SynergyData — immutable design data for the army synergies (GDD §6.3):
##   Shieldwall of the Damned (Warriors + Priests)  priest barriers on the frontline
##   Volley of the Fallen     (Archers + Mages)     mage marks -> archer bonus damage
##   March of the Deathless   (3 different summons) move speed + regeneration
##   The Unholy Host          (all 4 main summons)  attack speed / resilience aura
##
## Activation rule (GDD open question 29 is unresolved; prototype decision,
## recorded in GDD §15.0): a synergy is active automatically while every
## required summon class is owned at skill level MIN_CLASS_LEVEL or higher
## ("distinct" synergies count classes at that level). Units do not need to be
## alive. Synergies are re-evaluated whenever a summon level changes;
## SynergyManager applies them and the HUD lists the active ones.
## All magnitudes are TUNING (not in GDD).
class_name SynergyData
extends RefCounted

## Summon skill level a class needs to count toward a synergy.
const MIN_CLASS_LEVEL: int = 2  # TUNING (not in GDD) decision for open question 29
## Seconds the activation banner stays on screen.
const BANNER_TIME: float = 3.5  # TUNING (not in GDD)

## Display / HUD order.
const ORDER := ["shieldwall", "volley", "deathless", "unholy_host"]

## Synergy definitions.
##   display_name — UI name (banner).
##   short_name   — compact HUD name.
##   icon         — IconGlyph kind (drawn by ProgressionGlyphs).
##   description  — one-line effect text (banner subtitle).
##   requires     — summon classes that must each be at MIN_CLASS_LEVEL+.
##   distinct     — alternatively: number of different classes at
##                  MIN_CLASS_LEVEL+ (0 = use `requires`).
##   (effect keys, see each entry)
const SYNERGIES := {
	"shieldwall": {
		"display_name": "Shieldwall of the Damned",
		"short_name": "Shieldwall",
		"icon": "syn_shieldwall",
		"description": "Priests raise bone barriers on your frontline warriors.",
		"requires": ["warrior", "priest"],
		"distinct": 0,
		## Barrier HP as a fraction of the warrior's max HP (refreshed, not stacked).
		"barrier_fraction": 0.25,  # TUNING (not in GDD)
		## Seconds between barrier refreshes (needs at least one living priest).
		"barrier_interval": 5.0,  # TUNING (not in GDD)
	},
	"volley": {
		"display_name": "Volley of the Fallen",
		"short_name": "Volley",
		"icon": "syn_volley",
		"description": "Mage explosions mark foes; archers deal bonus damage to marked foes.",
		"requires": ["archer", "mage"],
		"distinct": 0,
		## Seconds a mage mark lasts on an enemy.
		"mark_duration": 4.0,  # TUNING (not in GDD)
		## Extra archer arrow damage against marked enemies (+35%).
		"archer_bonus": 0.35,  # TUNING (not in GDD)
	},
	"deathless": {
		"display_name": "March of the Deathless",
		"short_name": "Deathless",
		"icon": "syn_deathless",
		"description": "Your summons move faster and slowly regenerate.",
		"requires": [],
		"distinct": 3,
		## Summon move-speed bonus (+15%), its own stacking category.
		"move_speed": 0.15,  # TUNING (not in GDD)
		## Fraction of max HP each summon regenerates per second.
		"regen_per_s": 0.015,  # TUNING (not in GDD)
	},
	"unholy_host": {
		"display_name": "The Unholy Host",
		"short_name": "Unholy Host",
		"icon": "syn_unholy_host",
		"description": "An unholy aura: all summons attack faster and take less damage.",
		"requires": ["warrior", "archer", "mage", "priest"],
		"distinct": 0,
		## Summon attack-speed bonus (+15%), its own stacking category.
		"attack_speed": 0.15,  # TUNING (not in GDD)
		## Fraction of damage summons ignore (-15% damage taken).
		"damage_reduction": 0.15,  # TUNING (not in GDD)
	},
}
