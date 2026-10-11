## PassiveData — immutable design data for the global horde passives listed in
## GDD §34 ("Global passives"). The prototype implements the first four:
##   Grave Dominion  — Capacity.
##   Necrotic Vigor  — Max minion health.
##   Dark Command    — Minion attack damage/speed (at Lv 5 it also evolves
##                     Lv 5 Skeleton Warriors into Death Knights, user rule).
##   Soul Recycling  — Faster replacement.
## plus the three spell-evolution passives of GDD §6.1 (their standalone
## effects are not defined by the GDD, open question 28; these are the
## prototype's choice):
##   Soul Conduit    — +% damage of every shadow spell (evolves Shadow Bolt).
##   Warding Ritual  — -% damage taken by the necromancer (evolves Orb Shield).
##   Abyssal Focus   — -% spell cooldowns / orb recharge (evolves Shadow Blast).
## plus two summon-evolution passives of GDD §6.1 (user request; standalone
## effects are the prototype's choice, open question 28):
##   Forbidden Knowledge — +% Undead Mage damage and splash radius (at Lv 5
##                         it evolves Lv 5 Mages into Liches).
##   Dark Benediction    — +% heals, wards and barriers of the priest orders
##                         (owned, it merges Lv 5 Menders + Warders into
##                         Profane Bishops). Recipes: SummonEvolutionData.
## plus the four evolution passives of the newer spells (user request "more
## weapons"; prototype's choice, recorded in GDD §15.0):
##   Shade Stride          — +% necromancer move speed (evolves Bone Spear).
##   Vampiric Rite         — +HP/s regeneration (evolves Soul Siphon).
##   Necrotic Expanse      — +% spell area (evolves Corpse Explosion).
##   Lingering Malediction — +% spell durations (evolves Plague Cloud).
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
	"soul_conduit", "warding_ritual", "abyssal_focus", "forbidden_knowledge", "dark_benediction",
	"shade_stride", "vampiric_rite", "necrotic_expanse", "lingering_malediction", PactData.ID]

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
##                  "pct" (0.1 -> +10%), "neg_pct" (0.1 -> -10%) or "num"
##                  (0.4 -> +0.4).
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
##   mage_damage        — +% damage of the `classes` (Undead Mage / Lich).
##   mage_splash        — +% splash radius of the `classes`.
##   support_power      — +% heal, ward, ally barrier and aura heal of the
##                        `classes` (Mender, Warder, Profane Bishop).
##   classes            — (optional) summon classes the passive affects; it
##                        is a "dead" card while none of them is owned.
##   move_speed         — +% necromancer move speed (its own category, on top
##                        of the meta Fleet Shade bonus).
##   hp_regen           — +HP per second added to the necromancer's natural
##                        regeneration (PlayerData.HP_REGEN).
##   spell_area         — +% spell area: the radius stats of every spell
##                        (own category, on top of the meta Widening Dark).
##   spell_duration     — +% spell durations (AbilityData.DURATION_KEYS: Plague
##                        Cloud duration, Grave Eruption spike fields, Shadow
##                        Blast slow).
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
		"description": "Increases minion attack damage and attack speed. At Lv 5, with Warriors at Lv 5, a treasure chest raises them as Death Knights.",
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
	"forbidden_knowledge": {
		"display_name": "Forbidden Knowledge",
		"icon": "forbidden_knowledge",
		"description": "Forbidden rites empower your Undead Mages. At Lv 5, with Mages at Lv 5, a treasure chest raises them as Liches.",
		"labels": {"mage_damage": ["Mage damage", "pct"], "mage_splash": ["Mage splash radius", "pct"]},
		"classes": ["mage"],
		"levels": [
			{"mage_damage": 0.08, "mage_splash": 0.05},  # TUNING (not in GDD)
			{"mage_damage": 0.16, "mage_splash": 0.10},  # TUNING (not in GDD)
			{"mage_damage": 0.24, "mage_splash": 0.15},  # TUNING (not in GDD)
			{"mage_damage": 0.32, "mage_splash": 0.20},  # TUNING (not in GDD)
			{"mage_damage": 0.40, "mage_splash": 0.25},  # TUNING (not in GDD)
		],
	},
	"dark_benediction": {
		"display_name": "Dark Benediction",
		"icon": "dark_benediction",
		"description": "Unholy blessings strengthen Menders, Warders and Bishops. With Menders and Warders at Lv 5, a treasure chest merges them into Profane Bishops.",
		"labels": {"support_power": ["Heals, wards and barriers", "pct"]},
		"classes": ["mender", "warder", "bishop"],
		"levels": [
			{"support_power": 0.08},  # TUNING (not in GDD)
			{"support_power": 0.16},  # TUNING (not in GDD)
			{"support_power": 0.24},  # TUNING (not in GDD)
			{"support_power": 0.32},  # TUNING (not in GDD)
			{"support_power": 0.40},  # TUNING (not in GDD)
		],
	},
	"shade_stride": {
		"display_name": "Shade Stride",
		"icon": "shade_stride",
		"description": "You glide like a shade across the graves. Evolves Bone Spear into Ossuary Lance.",
		"labels": {"move_speed": ["Move speed", "pct"]},
		"levels": [
			{"move_speed": 0.03},  # TUNING (not in GDD)
			{"move_speed": 0.06},  # TUNING (not in GDD)
			{"move_speed": 0.09},  # TUNING (not in GDD)
			{"move_speed": 0.12},  # TUNING (not in GDD)
			{"move_speed": 0.15},  # TUNING (not in GDD)
		],
	},
	"vampiric_rite": {
		"display_name": "Vampiric Rite",
		"icon": "vampiric_rite",
		"description": "Stolen life seeps back into you. Evolves Soul Siphon into Soul Rapture.",
		"labels": {"hp_regen": ["Regeneration (HP/s)", "num"]},
		"levels": [
			{"hp_regen": 0.2},  # TUNING (not in GDD)
			{"hp_regen": 0.4},  # TUNING (not in GDD)
			{"hp_regen": 0.6},  # TUNING (not in GDD)
			{"hp_regen": 0.8},  # TUNING (not in GDD)
			{"hp_regen": 1.0},  # TUNING (not in GDD)
		],
	},
	"necrotic_expanse": {
		"display_name": "Necrotic Expanse",
		"icon": "necrotic_expanse",
		"description": "Your blasts, clouds and bursts spread wider. Evolves Corpse Explosion into Grave Eruption.",
		"labels": {"spell_area": ["Spell area (radius)", "pct"]},
		"levels": [
			{"spell_area": 0.05},  # TUNING (not in GDD)
			{"spell_area": 0.10},  # TUNING (not in GDD)
			{"spell_area": 0.15},  # TUNING (not in GDD)
			{"spell_area": 0.20},  # TUNING (not in GDD)
			{"spell_area": 0.25},  # TUNING (not in GDD)
		],
	},
	"lingering_malediction": {
		"display_name": "Lingering Malediction",
		"icon": "lingering_malediction",
		"description": "Your curses outlast their casting. Evolves Plague Cloud into Pestilence.",
		"labels": {"spell_duration": ["Spell duration", "pct"]},
		"levels": [
			{"spell_duration": 0.10},  # TUNING (not in GDD)
			{"spell_duration": 0.20},  # TUNING (not in GDD)
			{"spell_duration": 0.30},  # TUNING (not in GDD)
			{"spell_duration": 0.40},  # TUNING (not in GDD)
			{"spell_duration": 0.50},  # TUNING (not in GDD)
		],
	},
}
