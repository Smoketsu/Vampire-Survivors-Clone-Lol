## PassiveData — immutable design data for the global horde passives listed in
## GDD §34 ("Global passives"). The prototype implements the first four:
##   Grave Dominion  — Capacity.
##   Necrotic Vigor  — Max minion health.
##   Dark Command    — Minion attack damage/speed.
##   Soul Recycling  — Faster replacement.
## The GDD defines what each passive does but gives no values, so all numbers
## are TUNING (not in GDD).
##
## Stacking rule (GDD §34 "Add like-category bonus percentages, then multiply
## separate categories"): skill-level bonuses (UnitData.LEVELS) and passive
## bonuses (here) are two separate categories, so e.g.
##   effective_hp = base_hp * (1 + skill_hp_bonus) * (1 + vigor_hp_bonus).
class_name PassiveData
extends RefCounted

## Display / card order of passives.
const ORDER := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling"]

## Passive definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind.
##   description  — card text (GDD §34 definition).
##   labels       — stat key -> [UI label, format] where format is "int",
##                  "pct" (0.1 -> +10%) or "neg_pct" (0.1 -> -10%).
##   levels       — 5 rows of ABSOLUTE values at that passive level.
##
## Keys:
##   capacity_per_class — extra population for every summon class you own.
##   minion_hp          — +% minion max HP.
##   minion_damage      — +% minion damage.
##   minion_speed       — +% minion attack speed.
##   replace_reduction  — -% replacement interval.
const PASSIVES := {
	"grave_dominion": {
		"display_name": "Grave Dominion",
		"icon": "grave_dominion",
		"description": "Increases summon capacity of every summon class you command.",
		"labels": {"capacity_per_class": ["Capacity per class", "int"]},
		"levels": [
			{"capacity_per_class": 1},  # TUNING (not in GDD) every level adds +1
			{"capacity_per_class": 2},  # TUNING (not in GDD)
			{"capacity_per_class": 3},  # TUNING (not in GDD)
			{"capacity_per_class": 4},  # TUNING (not in GDD)
			{"capacity_per_class": 5},  # TUNING (not in GDD)
		],
	},
	"necrotic_vigor": {
		"display_name": "Necrotic Vigor",
		"icon": "necrotic_vigor",
		"description": "Increases maximum health of all minions.",
		"labels": {"minion_hp": ["Minion max HP", "pct"]},
		"levels": [
			{"minion_hp": 0.15},  # TUNING (not in GDD)
			{"minion_hp": 0.30},  # TUNING (not in GDD)
			{"minion_hp": 0.45},  # TUNING (not in GDD)
			{"minion_hp": 0.60},  # TUNING (not in GDD)
			{"minion_hp": 0.75},  # TUNING (not in GDD)
		],
	},
	"dark_command": {
		"display_name": "Dark Command",
		"icon": "dark_command",
		"description": "Increases minion attack damage and attack speed.",
		"labels": {"minion_damage": ["Minion damage", "pct"], "minion_speed": ["Minion attack speed", "pct"]},
		"levels": [
			{"minion_damage": 0.10, "minion_speed": 0.05},  # TUNING (not in GDD)
			{"minion_damage": 0.20, "minion_speed": 0.10},  # TUNING (not in GDD)
			{"minion_damage": 0.30, "minion_speed": 0.15},  # TUNING (not in GDD)
			{"minion_damage": 0.40, "minion_speed": 0.20},  # TUNING (not in GDD)
			{"minion_damage": 0.50, "minion_speed": 0.25},  # TUNING (not in GDD)
		],
	},
	"soul_recycling": {
		"display_name": "Soul Recycling",
		"icon": "soul_recycling",
		"description": "Fallen summons are replaced faster.",
		"labels": {"replace_reduction": ["Replacement time", "neg_pct"]},
		"levels": [
			{"replace_reduction": 0.10},  # TUNING (not in GDD)
			{"replace_reduction": 0.20},  # TUNING (not in GDD)
			{"replace_reduction": 0.30},  # TUNING (not in GDD)
			{"replace_reduction": 0.40},  # TUNING (not in GDD)
			{"replace_reduction": 0.50},  # TUNING (not in GDD)
		],
	},
}
