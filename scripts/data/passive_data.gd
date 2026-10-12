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
##                         (at Lv 5 it merges Lv 5 Menders + Warders into
##                         Profane Bishops). Recipes: SummonEvolutionData.
## Every evolution needs its paired passive at Lv 5 (owner rule, GDD §15.0).
## plus the four evolution passives of the newer spells (user request "more
## weapons"; prototype's choice, recorded in GDD §15.0):
##   Shade Stride          — +% necromancer move speed (evolves Bone Spear).
##   Vampiric Rite         — +HP/s regeneration (evolves Soul Siphon).
##   Necrotic Expanse      — +% spell area (evolves Corpse Explosion).
##   Lingering Malediction — +% spell durations (evolves Plague Cloud).
## plus the four later horde passives (GDD §34 names them; the effects are
## the prototype's choice, recorded in GDD §15.0, open question 28). Each
## will pair with a later summon evolution (not built yet; only the card
## text names it):
##   Bone Plating       — minions ignore a flat amount of every hit
##                        (Abominations -> Bone Colossi).
##   Unholy Precision   — minion critical hits (Archers -> Gravebows).
##   Unholy Resilience  — minions take less area and holy damage
##                        (Gargoyles -> Cathedral Horrors).
##   Bound Souls        — minion move speed, leash range and faster returns
##                        (Rogues -> Shadow Reapers).
## Their combat hooks live in CombatResolver (damage) and
## HordeDirector.compute_stats() (move speed, leash, return speed).
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
	"shade_stride", "vampiric_rite", "necrotic_expanse", "lingering_malediction",
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls", PactData.ID]

## Passives that only help summons (a "dead" level-up card while no summon
## class is owned, see AbilityManager.build_offers()).
const ARMY_PASSIVES := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling",
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls"]
## Passives that only help shadow spells (a "dead" card while no spell is owned).
const SPELL_PASSIVES := ["soul_conduit", "abyssal_focus"]

## Unholy Precision: damage multiplier of a minion critical hit (2 = double
## damage).
const CRIT_DAMAGE_MULT: float = 2.0  # TUNING (not in GDD) user brief: "a crit deals double damage"
## Unholy Precision: the damage-source tags (CombatResolver.damage_enemy
## `source`) that count as a minion attack are every summon tag (each class
## id in UnitData.CLASS_ORDER, each summon evolution id in
## SummonEvolutionData.ORDER, and MINION_EXTRA_TAGS) followed by one of
## these suffixes: "" the basic attack (melee hit, arrow, mage orb, priest
## bolt, frost bolt), "_bash" an evolved shield bash, "_cleave" a Death
## Knight cleave, "_aura" a Profane Bishop aura pulse.
const MINION_SOURCE_SUFFIXES := ["", "_bash", "_cleave", "_aura"]
## Unholy Precision: summon tags that are not a class or evolution id (the
## Lich's raised skeletons).
const MINION_EXTRA_TAGS := ["lich_risen"]
## Unholy Precision: the other minion damage sources that can crit: the
## basic warrior shield bash and the later classes' specials (and the Bone
## Colossus's death shrapnel). The Rogue's
## bleed ("rogue_bleed") is left out on purpose: it is a damage-over-time
## tick, not a strike.
const MINION_SPECIAL_SOURCES := ["bash", "abom_stomp", "rogue_dash", "gargoyle_swoop", "colossus_shrapnel"]
## Unholy Resilience: enemy damage-source tags (CombatResolver.damage_unit
## `source`) that count as AREA or HOLY damage, tag -> category ("area" |
## "holy"; the category only splits the summary stats). Every other source
## (melee swings, arrows, charges) is not reduced. Charges (Templar Knight,
## Sir Alaric) are body hits along a line, not an area, so they are not
## listed.
const AREA_HOLY_SOURCES := {
	"boss_hammer": "area",  # TUNING (not in GDD) Sir Alaric's Hammerfall slam.
	"boss_cleave": "area",  # TUNING (not in GDD) Marshal Vael's cleave sweep.
	"halberdier_cleave": "area",  # TUNING (not in GDD) a Halberdier's sweep onto neighbouring summons.
	"boss_judgment": "holy",  # TUNING (not in GDD) Sir Alaric's Judgment (holy light marks).
	"purifier": "holy",  # TUNING (not in GDD) Purifier holy fire (bonus vs undead).
	"holy_zone": "holy",  # TUNING (not in GDD) holy ground: grave consecration, Holy Ward Generators, boss holy zones.
	"holy_retribution": "holy",  # TUNING (not in GDD) radiant bolts of the Holy Retribution run modifier.
	"sentinel_sweep": "area",  # TUNING (not in GDD) a Sanctified Sentinel's frontal sweep.
	"guardian_slam": "area",  # TUNING (not in GDD) the Cathedral Guardian's ground slam.
	"guardian_beam": "holy",  # TUNING (not in GDD) the Cathedral Guardian's sweeping beam.
	"radiant_inquisitor": "holy",  # TUNING (not in GDD) a Radiant Inquisitor's radiant bolts.
}
## Bone Plating: a plated hit always keeps at least this fraction (0..1) of
## its damage, so the flat reduction never makes a summon immune to the
## early, weak hits (a 3-damage recruit swing still deals 0.75 at Lv 5).
const PLATING_MIN_FRACTION: float = 0.25  # TUNING (not in GDD)
## Bone Plating: damage sources it ignores. Holy ground damages summons in
## small ticks (StageDirector, every WaveData.ZONE_TICK s), which a flat
## per-hit reduction would erase; it is a field, not a hit (Unholy
## Resilience covers it instead).
const PLATING_EXEMPT_SOURCES := ["holy_zone"]

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
##   shared_card_pool   — (optional) true for the later horde passives: their
##                        NEW cards share LevelUpData.NEW_PASSIVE_POOL_WEIGHT
##                        (like the later summon classes and the newer spells).
##   flat_reduction     — damage every hit on a minion loses (after the other
##                        reductions, before barriers; it keeps at least
##                        PLATING_MIN_FRACTION of the hit).
##   crit_chance        — 0..1 chance a minion attack crits (x CRIT_DAMAGE_MULT).
##   area_holy_reduction — -% damage minions take from AREA_HOLY_SOURCES.
##   minion_move_speed  — +% minion move speed (own category).
##   leash_range        — +% minion engagement leash and soft-recall distance
##                        (UnitData.ENGAGE_RADIUS / SOFT_RECALL; the hard
##                        recall distance is unchanged).
##   return_reduction   — -% time a leashed minion needs to come back to you
##                        (its RETURNING speed is divided by 1 - this).
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
		"description": "Fallen summons are replaced faster. At Lv 5, with Frost Wraiths at Lv 5, a treasure chest raises them as Winter Revenants.",
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
		"description": "Channel harvested souls into your shadow spells. At Lv 5, with Shadow Bolt at Lv 5, a treasure chest evolves it into Void Barrage.",
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
		"description": "Protective sigils dull every blow you take. At Lv 5, with Shadow Orb Shield at Lv 5, a treasure chest evolves it into Eclipse Ward.",
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
		"description": "Your spells return faster from the abyss. At Lv 5, with Shadow Blast at Lv 5, a treasure chest evolves it into Abyssal Detonation.",
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
		"description": "Unholy blessings strengthen Menders, Warders and Bishops. At Lv 5, with Menders and Warders at Lv 5, a treasure chest merges them into Profane Bishops.",
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
		"description": "You glide like a shade across the graves. At Lv 5, with Bone Spear at Lv 5, a treasure chest evolves it into Ossuary Lance.",
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
		"description": "Stolen life seeps back into you. At Lv 5, with Soul Siphon at Lv 5, a treasure chest evolves it into Soul Rapture.",
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
		"description": "Your blasts, clouds and bursts spread wider. At Lv 5, with Corpse Explosion at Lv 5, a treasure chest evolves it into Grave Eruption.",
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
		"description": "Your curses outlast their casting. At Lv 5, with Plague Cloud at Lv 5, a treasure chest evolves it into Pestilence.",
		"labels": {"spell_duration": ["Spell duration", "pct"]},
		"levels": [
			{"spell_duration": 0.10},  # TUNING (not in GDD)
			{"spell_duration": 0.20},  # TUNING (not in GDD)
			{"spell_duration": 0.30},  # TUNING (not in GDD)
			{"spell_duration": 0.40},  # TUNING (not in GDD)
			{"spell_duration": 0.50},  # TUNING (not in GDD)
		],
	},
	"bone_plating": {
		"display_name": "Bone Plating",
		"icon": "bone_plating",
		"description": "Bone plates turn the edge of every blow your minions take. At Lv 5, with Abominations at Lv 5, a treasure chest raises them as Bone Colossi.",
		"labels": {"flat_reduction": ["Damage ignored per hit", "int"]},
		"shared_card_pool": true,
		"levels": [
			{"flat_reduction": 2},  # TUNING (not in GDD) user brief: 2 -> 6
			{"flat_reduction": 3},  # TUNING (not in GDD)
			{"flat_reduction": 4},  # TUNING (not in GDD)
			{"flat_reduction": 5},  # TUNING (not in GDD)
			{"flat_reduction": 6},  # TUNING (not in GDD)
		],
	},
	"unholy_precision": {
		"display_name": "Unholy Precision",
		"icon": "unholy_precision",
		"description": "Your minions find the weak points of the living: their attacks can strike critically for double damage. At Lv 5, with Archers at Lv 5, a treasure chest raises them as Gravebows.",
		"labels": {"crit_chance": ["Minion critical chance", "pct"]},
		"shared_card_pool": true,
		"levels": [
			{"crit_chance": 0.05},  # TUNING (not in GDD) user brief: 5% -> 25%
			{"crit_chance": 0.10},  # TUNING (not in GDD)
			{"crit_chance": 0.15},  # TUNING (not in GDD)
			{"crit_chance": 0.20},  # TUNING (not in GDD)
			{"crit_chance": 0.25},  # TUNING (not in GDD)
		],
	},
	"unholy_resilience": {
		"display_name": "Unholy Resilience",
		"icon": "unholy_resilience",
		"description": "Your minions shrug off slams, sweeps, holy fire and consecrated ground. At Lv 5, with Gargoyles at Lv 5, a treasure chest raises them as Cathedral Horrors.",
		"labels": {"area_holy_reduction": ["Area and holy damage taken", "neg_pct"]},
		"shared_card_pool": true,
		"levels": [
			{"area_holy_reduction": 0.08},  # TUNING (not in GDD) user brief: 8% -> 35%
			{"area_holy_reduction": 0.15},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.21},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.28},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.35},  # TUNING (not in GDD)
		],
	},
	"bound_souls": {
		"display_name": "Bound Souls",
		"icon": "bound_souls",
		"description": "Chains of will bind your minions to you: they move faster, roam farther before they are recalled, and return sooner. At Lv 5, with Rogues at Lv 5, a treasure chest raises them as Shadow Reapers.",
		"labels": {"minion_move_speed": ["Minion move speed", "pct"], "leash_range": ["Leash range", "pct"], "return_reduction": ["Return time", "neg_pct"]},
		"shared_card_pool": true,
		"levels": [
			{"minion_move_speed": 0.06, "leash_range": 0.10, "return_reduction": 0.10},  # TUNING (not in GDD) user brief: +6% / +10% / -10% at Lv 1
			{"minion_move_speed": 0.12, "leash_range": 0.20, "return_reduction": 0.20},  # TUNING (not in GDD)
			{"minion_move_speed": 0.18, "leash_range": 0.30, "return_reduction": 0.30},  # TUNING (not in GDD)
			{"minion_move_speed": 0.24, "leash_range": 0.40, "return_reduction": 0.40},  # TUNING (not in GDD)
			{"minion_move_speed": 0.30, "leash_range": 0.50, "return_reduction": 0.50},  # TUNING (not in GDD) user brief: +30% / +50% / half the return time
		],
	},
}
