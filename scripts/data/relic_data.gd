## RelicData — designer-tunable data for the RELICS (Ossuary expansion step 5,
## owner decisions Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions" and
## "Relics and Grave Offerings"). A relic is a run-shaping perk bought ONCE in the
## Ossuary (its Relics tab) and then EQUIPPED before a run in a limited number of
## slots on the pre-run setup screen (the "Rites" strip): one slot from the start,
## two more can be bought (owner decision 4: max 3). Most relics are a sideways
## trade (a gain with a cost), a few are a plain perk; the slot is the price. Some
## are sold only after a feat (FEATS: a clear on Lich or Deathlord, an act's last
## stage cleared on Hyper).
## Effects go through ONE path: RelicEffects (built from the equipped relics and
## the run's Grave Offering) is attached to the run's MetaModifiers (game.meta, the
## Soul Ash path, so a co-op partner's relics travel with his own slot):
##   * `stats` add to the MetaData.STATS modifier stats (read where the Ossuary
##     upgrades are already read: max HP, move speed, spell / minion damage ...),
##   * `special` keys (SPECIALS) are read in the few places that apply that thing
##     (MetaModifiers.relic(key)), each combined by its SPECIAL_RULES rule.
## Data only, no logic. Every price and value is TUNING (not in GDD). Budget (GDD
## §15.0 "Ossuary deep-level prices from the measured economy"): about 8,000 Soul
## Ash for every relic and both slots (total_cost(); tools/ossuary_check prints it).
class_name RelicData
extends RefCounted

# --- Slots -------------------------------------------------------------------------

## Relic slots every save has from the start (owner decision 4).
const START_SLOTS: int = 1  # GDD §15.0 "Ossuary expansion: owner decisions"
## Most relic slots (owner decision 4: two more can be bought).
const MAX_SLOTS: int = 3  # GDD §15.0 "Ossuary expansion: owner decisions"
## Soul Ash price of each buyable slot, in order (slot 2, slot 3).
const SLOT_COSTS: Array[int] = [1000, 1500]  # TUNING (not in GDD)
## One scale over every relic and slot price (1.0 = the listed prices; the economy
## knob, like MetaData.DEEP_COST_SCALE). Prices are rounded to PRICE_ROUND.
const COST_SCALE: float = 1.0  # TUNING (not in GDD)
## Prices are rounded to the nearest multiple of this (Soul Ash).
const PRICE_ROUND: int = 5  # TUNING (not in GDD)

# --- Feats (relics sold only after one) ---------------------------------------------

## Feat id -> what it asks for. Read by RelicLedger.feat_met():
##   difficulty — a victory (0:00 reached, any stage) on this DifficultyData level or
##                harder ([clears] best, Meta.best_clear),
##   hyper_stages — a Hyper clear (any character, [hyper_clears]) of one of these
##                stages (each act's last stage, whose boss ends the act),
##   text — the one line the Ossuary shows while the feat is missing,
##   short — the one word a locked tile shows instead of a price.
const FEATS := {
	"lich_clear": {"difficulty": "lich", "text": "Clear a stage on Lich to sell it", "short": "Lich"},  # TUNING (not in GDD)
	"deathlord_clear": {"difficulty": "deathlord", "text": "Clear a stage on Deathlord to sell it", "short": "Deathlord"},  # TUNING (not in GDD)
	"hyper_finale": {"hyper_stages": ["sanctum", "spire", "citadel"], "text": "Clear an act's last stage on Hyper to sell it", "short": "Hyper"},  # TUNING (not in GDD)
}

# --- Special effects ---------------------------------------------------------------

## Special key -> how several sources (relics and the offering) combine:
## "add" sums (absent = 0), "mul" multiplies (absent = 1), "max" keeps the
## largest (absent = 0), "min" keeps the smallest positive (absent = 0 = off).
## Where each key is read:
##   chest_bonus     ChestManager.roll_count()        upgrades added to every chest
##   powerup_chance  PowerupManager.on_enemy_killed()  drop chance x (1 + v) (v < 0 = rarer)
##   elite_feast     PowerupManager.on_enemy_killed()  > 0: an elite always drops a Grave Feast
##   ult_start       DreadRally._init()               share (0..1) of the soul meter filled at the start
##   ult_charge      DreadRally.add_points()          soul points x (1 + v)
##   reroll_every    AbilityManager.on_level()        every N-th level adds one reroll (0 = off)
##   active_slots    AbilityManager.active_slots()    extra active slots (spells + summon classes)
##   max_hp_mult     MetaModifiers.apply_to_player()  max HP x v
##   extra_chest     ChestManager._offering_chests()  chests placed beside the necromancer once
const SPECIAL_RULES := {
	"chest_bonus": "add",
	"powerup_chance": "add",
	"elite_feast": "max",
	"ult_start": "max",
	"ult_charge": "add",
	"reroll_every": "min",
	"active_slots": "add",
	"max_hp_mult": "mul",
	"extra_chest": "add",
}

# --- Relics ------------------------------------------------------------------------

## Display order of the relics (Ossuary grid, pre-run picker, the autotest line).
const ORDER := [
	"grave_lantern", "black_banner", "bone_abacus", "hollow_crown", "mourners_bell",
	"bone_flute", "martyrs_nail", "war_drum", "shade_cloak", "seers_eye",
	"leaden_shroud", "tallow_candle", "lichs_phylactery", "deathlords_seal", "fallen_halo",
]

## Relic definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind (assets/sprites/icons/<icon>.png, a 32 px badge).
##   short        — the effect in a few words (tiles, the pre-run picker).
##   description  — flavour + the full effect (detail panel, tooltips).
##   price        — Soul Ash price (x COST_SCALE; price()).
##   stats        — MetaData.STATS key -> value added to that modifier stat.
##   special      — SPECIAL_RULES key -> value.
##   feat         — FEATS id needed before it is sold ("" = sold from the start).
## Stacking audit (owner brief: no two that trivially stack into a broken build):
## the three max-HP relics multiply DOWN (Hollow Crown x Phylactery x Seal = x0.61
## HP: fragile, not broken); Martyr's Nail and War Drum cancel; the two soul-meter
## relics (Black Banner, Fallen Halo) speed the ultimate, never stack its effect;
## Grave Lantern's richer chests halve the power-ups, so with Mourner's Bell the
## Grave Feasts come from elites instead of drops.
const RELICS := {
	"grave_lantern": {"display_name": "Grave Lantern", "icon": "relic_grave_lantern",
		"short": "Chests +1 upgrade, fewer power-ups",
		"description": "A lantern that finds what the dead hid: every chest holds one more upgrade, but power-ups drop half as often.",
		"price": 400, "stats": {}, "special": {"chest_bonus": 1.0, "powerup_chance": -0.5}, "feat": ""},  # TUNING (not in GDD) owner-approved proposal ("chests reveal two choices": see GDD §15.0 "Relics and Grave Offerings")
	"black_banner": {"display_name": "Black Banner", "icon": "relic_black_banner",
		"short": "Ultimate starts half charged",
		"description": "The banner of a war already lost: your soul meter starts every run half full.",
		"price": 250, "stats": {}, "special": {"ult_start": 0.5}, "feat": ""},  # TUNING (not in GDD) owner-approved proposal
	"bone_abacus": {"display_name": "Bone Abacus", "icon": "relic_bone_abacus",
		"short": "A free reroll every 5 levels",
		"description": "Count the dead and the odds come out even: every fifth level adds one level-up reroll.",
		"price": 300, "stats": {}, "special": {"reroll_every": 5.0}, "feat": ""},  # TUNING (not in GDD) owner-approved proposal
	"hollow_crown": {"display_name": "Hollow Crown", "icon": "relic_hollow_crown",
		"short": "+1 active slot, -10% max HP",
		"description": "A crown with room for one more power: +1 active slot (spells and summon classes), but -10% max HP.",
		"price": 600, "stats": {}, "special": {"active_slots": 1.0, "max_hp_mult": 0.9}, "feat": ""},  # TUNING (not in GDD) owner-approved proposal
	"mourners_bell": {"display_name": "Mourner's Bell", "icon": "relic_mourners_bell",
		"short": "Elites drop a Grave Feast",
		"description": "It tolls for the strong: every elite you slay drops a Grave Feast (a heart of healing).",
		"price": 300, "stats": {}, "special": {"elite_feast": 1.0}, "feat": ""},  # TUNING (not in GDD) owner-approved proposal
	"bone_flute": {"display_name": "Bone Flute", "icon": "relic_bone_flute",
		"short": "Summons return faster, -10% minion HP",
		"description": "A tune the fallen cannot ignore: summons return 30% faster, but have -10% HP.",
		"price": 300, "stats": {"replace_reduction": 0.30, "minion_hp": -0.10}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"martyrs_nail": {"display_name": "Martyr's Nail", "icon": "relic_martyrs_nail",
		"short": "Spells +15%, minions -10% damage",
		"description": "Pain kept for yourself: spells deal +15% damage, your summons -10%.",
		"price": 350, "stats": {"spell_damage": 0.15, "minion_damage": -0.10}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"war_drum": {"display_name": "War Drum", "icon": "relic_war_drum",
		"short": "Minions +12%, spells -10% damage",
		"description": "Skin over a ribcage, beaten for the march: summons deal +12% damage, spells -10%.",
		"price": 350, "stats": {"minion_damage": 0.12, "spell_damage": -0.10}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"shade_cloak": {"display_name": "Shade Cloak", "icon": "relic_shade_cloak",
		"short": "+1 Grave Step, -6% speed",
		"description": "A cloak of two shadows: store one more Grave Step, but move 6% slower.",
		"price": 300, "stats": {"dash_charges": 1.0, "move_speed": -0.06}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"seers_eye": {"display_name": "Seer's Eye", "icon": "relic_seers_eye",
		"short": "+2 banishes, -1 reroll",
		"description": "It sees what you will never want: +2 level-up banishes, -1 reroll.",
		"price": 250, "stats": {"banishes": 2.0, "rerolls": -1.0}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"leaden_shroud": {"display_name": "Leaden Shroud", "icon": "relic_leaden_shroud",
		"short": "-10% damage taken, -10% speed",
		"description": "A burial shroud sewn with lead: take 10% less damage, but move 10% slower.",
		"price": 350, "stats": {"damage_reduction": 0.10, "move_speed": -0.10}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"tallow_candle": {"display_name": "Tallow Candle", "icon": "relic_tallow_candle",
		"short": "Spells 10% faster, -15% area",
		"description": "A quick, small flame: spells cool down 10% faster, but their area is 15% smaller.",
		"price": 300, "stats": {"spell_cooldown": 0.10, "spell_area": -0.15}, "special": {}, "feat": ""},  # TUNING (not in GDD)
	"lichs_phylactery": {"display_name": "Lich's Phylactery", "icon": "relic_lichs_phylactery",
		"short": "+1 revival, -20% max HP",
		"description": "Your soul kept in a jar: rise once more per run, but with -20% max HP.",
		"price": 450, "stats": {"revives": 1.0}, "special": {"max_hp_mult": 0.8}, "feat": "lich_clear"},  # TUNING (not in GDD)
	"deathlords_seal": {"display_name": "Deathlord's Seal", "icon": "relic_deathlords_seal",
		"short": "+1 of every summon, -15% max HP",
		"description": "The seal of a lord of the dead: every summon class fields one more soldier, but -15% max HP.",
		"price": 550, "stats": {"capacity_per_class": 1.0}, "special": {"max_hp_mult": 0.85}, "feat": "deathlord_clear"},  # TUNING (not in GDD)
	"fallen_halo": {"display_name": "Fallen Halo", "icon": "relic_fallen_halo",
		"short": "Ultimate charges 35% faster",
		"description": "A saint's halo, tarnished in your hand: the soul meter fills 35% faster.",
		"price": 450, "stats": {}, "special": {"ult_charge": 0.35}, "feat": "hyper_finale"},  # TUNING (not in GDD)
}

# --- Autotest -----------------------------------------------------------------------

## Relics the autotest's --meta=max profile equips (every slot bought; a fixed,
## deterministic set of plain perks, so the max profile shows the strongest
## everyday choice). --relics=a,b overrides it.
const AUTOTEST_MAX_RELICS := ["bone_abacus", "black_banner", "mourners_bell"]  # TUNING (not in GDD)


## Soul Ash price of relic `id` (x COST_SCALE, rounded; -1 for an unknown id).
static func price(id: String) -> int:
	if not RELICS.has(id):
		return -1
	return _scaled(int(RELICS[id]["price"]))


## Price of buyable slot number `slot` (2 or 3; -1 when there is none).
static func slot_price(slot: int) -> int:
	var i := slot - START_SLOTS - 1  # Index in SLOT_COSTS.
	if i < 0 or i >= SLOT_COSTS.size():
		return -1
	return _scaled(SLOT_COSTS[i])


## `p` x COST_SCALE rounded to PRICE_ROUND.
static func _scaled(p: int) -> int:
	return int(roundf(float(p) * COST_SCALE / float(PRICE_ROUND))) * PRICE_ROUND


## Soul Ash for every relic and every buyable slot (the step's budget line).
static func total_cost() -> int:
	var total := 0  # Sum so far.
	for id: String in ORDER:
		total += price(id)
	for s in range(START_SLOTS + 1, MAX_SLOTS + 1):
		total += slot_price(s)
	return total


## True for a known relic id.
static func has(id: String) -> bool:
	return RELICS.has(id)
