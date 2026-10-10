## PassiveData — immutable design data for the global horde passives listed in
## GDD §34 ("Global passives"). The prototype implements the first four:
##   Grave Dominion  — Capacity.
##   Necrotic Vigor  — Max minion health.
##   Dark Command    — Minion attack damage/speed.
##   Soul Recycling  — Faster replacement.
## plus the three spell-evolution passives of GDD §6.1 (their standalone
## effects are not defined by the GDD, open question 28; these are the
## prototype's choice):
##   Soul Conduit    — +% damage of every shadow spell (evolves Shadow Bolt).
##   Warding Ritual  — -% damage taken by the necromancer (evolves Orb Shield).
##   Abyssal Focus   — -% spell cooldowns / orb recharge (evolves Shadow Blast).
## plus the opt-in difficulty passive (user request, data in PactData):
##   Profane Pact    — stronger, more numerous enemies for more XP, Soul Ash
##                     and power-up drops.
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
const ORDER := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling",
	"soul_conduit", "warding_ritual", "abyssal_focus", PactData.ID]

## Passives that only help summons (a "dead" level-up card while no summon
## class is owned, see AbilityManager.build_offers()).
const ARMY_PASSIVES := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling"]
## Passives that only help shadow spells (a "dead" card while no spell is owned).
const SPELL_PASSIVES := ["soul_conduit", "abyssal_focus"]

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
##   spell_damage       — +% damage of every shadow spell (and its evolution).
##   damage_reduction   — -% damage taken by the necromancer (after wards).
##   cooldown_reduction — -% spell cooldowns, Orb Shield recharge and Eclipse
##                        Ward pulse interval.
const PASSIVES := {
	# Profane Pact (difficulty / reward passive): defined in PactData.
	PactData.ID: PactData.PASSIVE,
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
	"soul_conduit": {
		"display_name": "Soul Conduit",
		"icon": "soul_conduit",
		"description": "Channel harvested souls into your shadow spells. Evolves Shadow Bolt into Void Barrage.",
		"labels": {"spell_damage": ["Spell damage", "pct"]},
		"levels": [
			{"spell_damage": 0.10},  # TUNING (not in GDD)
			{"spell_damage": 0.20},  # TUNING (not in GDD)
			{"spell_damage": 0.30},  # TUNING (not in GDD)
			{"spell_damage": 0.40},  # TUNING (not in GDD)
			{"spell_damage": 0.50},  # TUNING (not in GDD)
		],
	},
	"warding_ritual": {
		"display_name": "Warding Ritual",
		"icon": "warding_ritual",
		"description": "Protective sigils dull every blow you take. Evolves Shadow Orb Shield into Eclipse Ward.",
		"labels": {"damage_reduction": ["Damage taken", "neg_pct"]},
		"levels": [
			{"damage_reduction": 0.05},  # TUNING (not in GDD)
			{"damage_reduction": 0.10},  # TUNING (not in GDD)
			{"damage_reduction": 0.15},  # TUNING (not in GDD)
			{"damage_reduction": 0.20},  # TUNING (not in GDD)
			{"damage_reduction": 0.25},  # TUNING (not in GDD)
		],
	},
	"abyssal_focus": {
		"display_name": "Abyssal Focus",
		"icon": "abyssal_focus",
		"description": "Your spells return faster from the abyss. Evolves Shadow Blast into Abyssal Detonation.",
		"labels": {"cooldown_reduction": ["Spell cooldowns", "neg_pct"]},
		"levels": [
			{"cooldown_reduction": 0.05},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.10},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.15},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.20},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.25},  # TUNING (not in GDD)
		],
	},
}
