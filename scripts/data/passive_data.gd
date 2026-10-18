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
## pairs with a later summon evolution (recipes in SummonEvolutionData; card
## descriptions never spell a recipe out, owner rule "Card text: one
## sentence"):
##   Bone Plating       — minions ignore a flat amount of every hit
##                        (Abominations -> Bone Colossi).
##   Unholy Precision   — minion critical hits (Archers -> Gravebows).
##   Unholy Resilience  — minions take less area and holy damage
##                        (Gargoyles -> Cathedral Horrors).
##   Bound Souls        — minion move speed, leash range and faster returns
##                        (Rogues -> Shadow Reapers).
## Their combat hooks live in CombatResolver (damage) and
## HordeDirector.compute_stats() (move speed, leash, return speed).
## plus the evolution passives of the five later spells (owner-approved, GDD
## §15.0 "Five more spells"; Grave Dominion and Necrotic Vigor above pair
## with Bone Wall and Wither, so no passive pairs with two evolutions):
##   Grim Ledger     — +% damage to elites, minibosses and bosses from every
##                     source (CombatResolver.damage_enemy(); evolves Death
##                     Mark into Doom Brand).
##   Spirit Binding  — every slow, chill, Deep Freeze and stun on enemies
##                     lasts longer (CombatResolver's status calls; evolves
##                     Soul Chains into Chains of the Damned).
##   Restless Dead   — temporary summons (Death Mark Risen, Raise Dead
##                     skeletons, Lich raises, stage reinforcements) last
##                     longer and hit harder (HordeDirector.spawn_temporary();
##                     evolves Raise Dead into Legion of Bones).
## plus the three passives paired with the newest summon classes
## (owner-approved, recorded in GDD §15.0; card lines and the autotest line
## in ClassPassives):
##   Blood Scent  — fast summons (base move speed >= FAST_SUMMON_SPEED) move
##                  and attack faster (HordeDirector.compute_stats(); Bone
##                  Hounds -> Hellhounds).
##   Mournsong    — every weakening effect on enemies lasts longer: slows,
##                  chills, the Dirge's damage cut, curses and Rot
##                  (CombatResolver.debuff_time(); Banshees -> Keening Ladies).
##   Siegecraft   — summons deal more damage to structures, elites and
##                  minibosses (CombatResolver.damage_enemy(); Corpse
##                  Catapults -> Ossuary Engines).
## plus Act II's passives (owner-approved "Unlockable spells and passives",
## GDD §15.0; both are unlockable items, UnlockData):
##   Salt of the Deep — more damage to slowed, chilled or frozen enemies
##                      (CombatResolver.damage_enemy(); evolves Undertow into
##                      Maelstrom; unlocked with Undertow by slaying Merrow).
##   Brinewalker      — a counter-passive, offered only on Act II stages
##                      ("act": 2): water and ink slow the necromancer less,
##                      and summons from BRINEWALKER_SUMMON_LEVEL (TerrainSlow,
##                      the one ground-slow path; unlocked by the Low Tide
##                      achievement).
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
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls",
	"grim_ledger", "spirit_binding", "restless_dead",
	"blood_scent", "mournsong", "siegecraft", PactData.ID,
	# --- Act II: Gullhaven Harbour ---
	"salt_of_the_deep", "brinewalker"]

## Passives that only help summons (a "dead" level-up card while no summon
## class is owned, see AbilityManager.build_offers()).
const ARMY_PASSIVES := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling",
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls",
	"blood_scent", "siegecraft"]

## Blood Scent: a summon class is "fast" (and gets the passive) when its
## UnitData base move_speed is at least this (px/s): Bone Hounds 122, Grave
## Rogues 112, Skeletal Archers and Crypt Gargoyles 95. Warriors (85), the
## priest orders (90), Banshees (92) and the slower classes are not.
const FAST_SUMMON_SPEED: float = 95.0  # TUNING (not in GDD) owner brief: "define fast by base speed threshold in data"
## Siegecraft: minion damage-over-time sources that also count as summon
## damage for its bonus (the strike sources are CombatResolver.
## is_minion_source(); these ticks are left out of crits and suppression
## like the Rogue bleed, but a siege bonus applies to them too).
const MINION_DOT_SOURCES := ["rogue_bleed", "hellhound_burn", "hellhound_trail", "ossuary_shards"]
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
## Lich's raised skeletons, Death Mark's Risen and Raise Dead's skeletons).
const MINION_EXTRA_TAGS := ["lich_risen", "death_mark_risen", "raised_dead"]
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
	"seraphine_bolt": "holy",  # TUNING (not in GDD) Seraphine's radiant fans and barrages.
	"seraphine_circle": "area",  # TUNING (not in GDD) Seraphine's delayed holy circles.
	"seraphine_beam": "holy",  # TUNING (not in GDD) Seraphine's rotating holy beams.
	"seraphine_nova": "holy",  # TUNING (not in GDD) Seraphine's Judgment nova.
	"seraphine_collapse": "holy",  # TUNING (not in GDD) the holy fire of her collapsing arena.
	# --- Act II: Gullhaven Harbour ---
	"deep_kin_leap": "area",  # TUNING (not in GDD) a Deep Kin's landing.
	"tide_wall": "area",  # TUNING (not in GDD) a Tide Caller's water line.
	"harbourmaster_sweep": "area",  # TUNING (not in GDD) the Harbourmaster's anchor sweep.
	"merrow_wave": "area",  # TUNING (not in GDD) Abbot Merrow's Brine Wave.
	"merrow_whirl": "area",  # TUNING (not in GDD) Abbot Merrow's Whirl.
}
## Bone Plating: a plated hit always keeps at least this fraction (0..1) of
## its damage, so the flat reduction never makes a summon immune to the
## early, weak hits (a 3-damage recruit swing still deals 0.75 at Lv 5).
const PLATING_MIN_FRACTION: float = 0.25  # TUNING (not in GDD)
## Bone Plating: damage sources it ignores. Holy ground damages summons in
## small ticks (StageDirector, every WaveData.ZONE_TICK s), which a flat
## per-hit reduction would erase; it is a field, not a hit (Unholy
## Resilience covers it instead).
## Seraphine's beam pulses and collapse fire tick the same way (fields).
const PLATING_EXEMPT_SOURCES := ["holy_zone", "seraphine_beam", "seraphine_collapse"]
## Grim Ledger: damage sources it does NOT amplify. The Soul Nova power-up
## deals an exact share of max HP (like the Gravebow curse exemption).
const LEDGER_EXEMPT_SOURCES := ["nova"]  # TUNING (not in GDD)
## Salt of the Deep: damage sources it does NOT amplify (the Soul Nova deals an
## exact share of max HP, like Grim Ledger's exemption).
const SALT_EXEMPT_SOURCES := ["nova"]  # TUNING (not in GDD)
## Brinewalker: the passive level from which it also helps the summons
## (owner-approved "and summons from Lv 3").
const BRINEWALKER_SUMMON_LEVEL: int = 3  # owner-approved

## Passive definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind.
##   description  — card text (GDD §34 definition): one short sentence, no
##                  numbers and no evolution recipe (GDD §15.0 "Card text:
##                  one sentence").
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
##   shared_card_pool   — (optional) true for the later passives: a later item,
##                        its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
##                        (like the later summon classes and spells).
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
##   elite_damage       — +% damage elites, minibosses and bosses take from
##                        every source (Grim Ledger).
##   cc_duration        — +% duration of every slow, chill, Deep Freeze and
##                        stun applied to enemies (Spirit Binding).
##   temp_duration      — +% lifetime of temporary summons (Restless Dead).
##   temp_damage        — +% damage of temporary summons (Restless Dead).
##   fast_move_speed    — +% move speed of the fast summon classes
##                        (FAST_SUMMON_SPEED; own category).
##   fast_attack_speed  — +% attack speed of the fast summon classes.
##   debuff_duration    — +% duration of every weakening effect on enemies
##                        (slows, chills, the Dirge, curses, Rot).
##   siege_damage       — +% summon damage to structures, elites and
##                        minibosses (not the stage boss).
##   slowed_damage      — +% damage enemies take while slowed, chilled or
##                        frozen (Salt of the Deep).
##   water_slow_cut     — share (0..1) of a water / ink slow on the
##                        necromancer removed (Brinewalker; 1 = none), and on
##                        summons from BRINEWALKER_SUMMON_LEVEL.
##   act                — (optional) the only campaign act whose stages offer
##                        the card (Unlocks.act_allows()).
const PASSIVES := {
	# Profane Pact (difficulty / reward passive): defined in PactData.
	PactData.ID: PactData.PASSIVE,
	"grave_dominion": {
		"display_name": "Grave Dominion",
		"icon": "grave_dominion",
		"description": "Raises the capacity of every summon class you command.",
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
		"description": "Harvested souls add damage to your spells.",
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
		"description": "Protective sigils dull every blow you take.",
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
		"description": "Your spells return faster from the abyss.",
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
		"description": "Forbidden rites empower your Undead Mages.",
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
		"description": "Unholy blessings strengthen your heals, wards and barriers.",
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
		"description": "You move faster, gliding like a shade across the graves.",
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
		"description": "Stolen life slowly seeps back into you.",
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
		"description": "Your blasts, clouds and bursts spread wider.",
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
		"description": "Your clouds, spike fields and slows linger longer.",
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
		"description": "Bone plates turn the edge of every blow your minions take.",
		"labels": {"flat_reduction": ["Damage ignored per hit", "int"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
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
		"description": "Your minions' attacks can strike critically for double damage.",
		"labels": {"crit_chance": ["Minion critical chance", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
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
		"description": "Your minions shrug off slams, sweeps, holy fire and consecrated ground.",
		"labels": {"area_holy_reduction": ["Area and holy damage taken", "neg_pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
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
		"description": "Your minions move faster, roam farther and return to you sooner.",
		"labels": {"minion_move_speed": ["Minion move speed", "pct"], "leash_range": ["Leash range", "pct"], "return_reduction": ["Return time", "neg_pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"minion_move_speed": 0.06, "leash_range": 0.10, "return_reduction": 0.10},  # TUNING (not in GDD) user brief: +6% / +10% / -10% at Lv 1
			{"minion_move_speed": 0.12, "leash_range": 0.20, "return_reduction": 0.20},  # TUNING (not in GDD)
			{"minion_move_speed": 0.18, "leash_range": 0.30, "return_reduction": 0.30},  # TUNING (not in GDD)
			{"minion_move_speed": 0.24, "leash_range": 0.40, "return_reduction": 0.40},  # TUNING (not in GDD)
			{"minion_move_speed": 0.30, "leash_range": 0.50, "return_reduction": 0.50},  # TUNING (not in GDD) user brief: +30% / +50% / half the return time
		],
	},
	"grim_ledger": {
		"display_name": "Grim Ledger",
		"icon": "grim_ledger",
		"description": "Elites, minibosses and bosses take more damage from everything.",
		"labels": {"elite_damage": ["Damage to elites and bosses", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"elite_damage": 0.05},  # TUNING (not in GDD)
			{"elite_damage": 0.10},  # TUNING (not in GDD)
			{"elite_damage": 0.15},  # TUNING (not in GDD)
			{"elite_damage": 0.20},  # TUNING (not in GDD)
			{"elite_damage": 0.25},  # TUNING (not in GDD)
		],
	},
	"spirit_binding": {
		"display_name": "Spirit Binding",
		"icon": "spirit_binding",
		"description": "Every slow, chill, freeze and stun you inflict lasts longer.",
		"labels": {"cc_duration": ["Slow, freeze and stun duration", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"cc_duration": 0.08},  # TUNING (not in GDD)
			{"cc_duration": 0.16},  # TUNING (not in GDD)
			{"cc_duration": 0.24},  # TUNING (not in GDD)
			{"cc_duration": 0.32},  # TUNING (not in GDD)
			{"cc_duration": 0.40},  # TUNING (not in GDD)
		],
	},
	"restless_dead": {
		"display_name": "Restless Dead",
		"icon": "restless_dead",
		"description": "Temporary summons last longer and strike harder.",
		"labels": {"temp_duration": ["Temporary summon lifetime", "pct"], "temp_damage": ["Temporary summon damage", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"temp_duration": 0.10, "temp_damage": 0.08},  # TUNING (not in GDD)
			{"temp_duration": 0.20, "temp_damage": 0.16},  # TUNING (not in GDD)
			{"temp_duration": 0.30, "temp_damage": 0.24},  # TUNING (not in GDD)
			{"temp_duration": 0.40, "temp_damage": 0.32},  # TUNING (not in GDD)
			{"temp_duration": 0.50, "temp_damage": 0.40},  # TUNING (not in GDD)
		],
	},
	"blood_scent": {
		"display_name": "Blood Scent",
		"icon": "blood_scent",
		"description": "Your swiftest dead move and attack faster.",
		"labels": {"fast_move_speed": ["Fast summon move speed", "pct"], "fast_attack_speed": ["Fast summon attack speed", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"fast_move_speed": 0.05, "fast_attack_speed": 0.06},  # TUNING (not in GDD)
			{"fast_move_speed": 0.10, "fast_attack_speed": 0.12},  # TUNING (not in GDD)
			{"fast_move_speed": 0.15, "fast_attack_speed": 0.18},  # TUNING (not in GDD)
			{"fast_move_speed": 0.20, "fast_attack_speed": 0.24},  # TUNING (not in GDD)
			{"fast_move_speed": 0.25, "fast_attack_speed": 0.30},  # TUNING (not in GDD)
		],
	},
	"mournsong": {
		"display_name": "Mournsong",
		"icon": "mournsong",
		"description": "Slows, chills, curses, Rot and Dirges you inflict all last longer.",
		"labels": {"debuff_duration": ["Weakening effect duration", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"debuff_duration": 0.10},  # TUNING (not in GDD)
			{"debuff_duration": 0.20},  # TUNING (not in GDD)
			{"debuff_duration": 0.30},  # TUNING (not in GDD)
			{"debuff_duration": 0.40},  # TUNING (not in GDD)
			{"debuff_duration": 0.50},  # TUNING (not in GDD)
		],
	},
	"siegecraft": {
		"display_name": "Siegecraft",
		"icon": "siegecraft",
		"description": "Summons deal more damage to structures, elites and minibosses.",
		"labels": {"siege_damage": ["Summon damage to structures, elites, minibosses", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"siege_damage": 0.10},  # TUNING (not in GDD)
			{"siege_damage": 0.20},  # TUNING (not in GDD)
			{"siege_damage": 0.30},  # TUNING (not in GDD)
			{"siege_damage": 0.40},  # TUNING (not in GDD)
			{"siege_damage": 0.50},  # TUNING (not in GDD)
		],
	},
	# --- Act II: Gullhaven Harbour ---
	"salt_of_the_deep": {
		"display_name": "Salt of the Deep",
		"icon": "salt_of_the_deep",
		"description": "Slowed, chilled and frozen foes take more damage from everything.",
		"labels": {"slowed_damage": ["Damage to slowed foes", "pct"]},
		"shared_card_pool": true,  # owner-approved: unlocked Act II items weigh the later items' 0.5
		"levels": [
			{"slowed_damage": 0.06},  # owner-approved "+6% a level"
			{"slowed_damage": 0.12},  # owner-approved
			{"slowed_damage": 0.18},  # owner-approved
			{"slowed_damage": 0.24},  # owner-approved
			{"slowed_damage": 0.30},  # owner-approved "+30% at Lv 5"
		],
	},
	"brinewalker": {
		"display_name": "Brinewalker",
		"icon": "brinewalker",
		"description": "Water and ink slow you less, and your summons too once it grows.",
		"labels": {"water_slow_cut": ["Water and ink slow removed", "pct"]},
		"shared_card_pool": true,  # owner-approved: Act II items weigh the later items' 0.5
		"act": 2,  # owner-approved: counter-passives are offered only on Act II stages
		"levels": [
			{"water_slow_cut": 0.20},  # owner-approved "-20% a level"
			{"water_slow_cut": 0.40},  # owner-approved
			{"water_slow_cut": 0.60},  # owner-approved (summons too from Lv 3)
			{"water_slow_cut": 0.80},  # owner-approved
			{"water_slow_cut": 1.00},  # owner-approved "no slow at Lv 5"
		],
	},
}
