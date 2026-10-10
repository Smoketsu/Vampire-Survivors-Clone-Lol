## MetaData — designer-tunable data for META-PROGRESSION (GDD §9.2 "Persistent
## Currency: Soul Ash", §9.4 achievements, open question 39 "Soul Ash economy":
## earn rates, costs, tiers and per-tier values are unspecified, so every
## number here is TUNING and was chosen for the 20:00 Graveyard stage).
##
## Soul Ash is earned at the end of EVERY run, won or lost (survivor-genre
## convention: kept on death). The earn formula (see Meta.compute_ash()):
##   raw  = ASH_PER_MINUTE           * minutes survived on the countdown (max 20)
##        + ASH_PER_KILL             * enemies slain
##        + ASH_PER_ELITE            * elites slain
##        + ASH_BOSS_KILL            * (Sir Alaric slain ? 1 : 0)
##        + ASH_PER_RECKONING_SECOND * seconds survived past 0:00 (capped)
##   ash  = floor(raw * (1 + Ash Harvest bonus))
## A strong 20-minute run (~3,000 kills, ~15 elites, boss slain, ~30 s of
## Reckoning) earns roughly 150 + 90 + 60 + 75 + 75 = ~450 ash: two or three
## mid-tier purchases. Every upgrade maxed costs max_total_cost() = 8,965,
## i.e. about 20 good runs (very roughly 15-25 with weaker runs and Ash Harvest).
##
## Four upgrade trees (GDD §9.2 table):
##   Necromancy  — minion cap, health and damage (+ replacement speed)
##   Shadowcraft — spell damage, cooldown reduction, AoE
##   Survival    — health, armor, movement (+ one revival per run)
##   Fortune     — pickup radius, reward luck (XP / Soul Ash gain), rerolls
##                 and banishes (GDD open question 7)
## plus one standalone entry outside the four trees (user request, the
## Vampire Survivors "Curse" idea):
##   Oath        — Profane Oath: 5 cheap tiers of opt-in DIFFICULTY (more,
##                 stronger enemies) for more XP, Soul Ash and power-up drops.
##                 Its per-tier effect is PactData.OATH_PER_TIER; it stacks
##                 additively with the in-run Profane Pact passive through
##                 DifficultyModifiers. The player can lower or switch off the
##                 ACTIVE tier in the Ossuary for free (owned tiers stay owned,
##                 Meta.oath_active), and the autotest profiles never include
##                 it (use --oath=N).
## Each upgrade raises ONE modifier stat (STATS) by `per_tier` per tier.
## Costs rise per tier. `requires` names a prerequisite inside the same tree
## ({} = none). MetaModifiers sums the stats; the game's stat code reads them.
class_name MetaData
extends RefCounted

## Version written to user://save.cfg ([meta] save_version). Bump it and add
## a step to Meta._migrate() whenever the save layout changes.
const SAVE_VERSION: int = 1

# --- Soul Ash earn formula (header) -----------------------------------------------

## Soul Ash per minute survived on the countdown (20:00 stage -> 150).
const ASH_PER_MINUTE: float = 7.5  # TUNING (not in GDD)
## Soul Ash per enemy slain (about 1 ash per 33 kills).
const ASH_PER_KILL: float = 0.03  # TUNING (not in GDD)
## Soul Ash per elite slain (elites are the gold-ringed enemies).
const ASH_PER_ELITE: float = 4.0  # TUNING (not in GDD)
## Soul Ash for slaying the stage boss (Sir Alaric).
const ASH_BOSS_KILL: float = 75.0  # TUNING (not in GDD)
## Soul Ash per second survived into the Reckoning (the big bonus, GDD §15.0
## decision 1: only strong builds last there).
const ASH_PER_RECKONING_SECOND: float = 2.5  # TUNING (not in GDD)
## Reckoning seconds that still pay ash (stops an absurd build farming forever).
const ASH_RECKONING_CAP_SECONDS: float = 180.0  # TUNING (not in GDD)

# --- Revival (Survival tree, "Undying Will") ----------------------------------------

## Fraction of max HP restored by a revival.
const REVIVE_HP_FRACTION: float = 0.5  # TUNING (not in GDD)
## Invulnerability (s) granted right after a revival.
const REVIVE_IFRAMES: float = 2.5  # TUNING (not in GDD)
## Radius (px) of the revival shockwave that knocks enemies back.
const REVIVE_PUSH_RADIUS: float = 140.0  # TUNING (not in GDD)
## Outward impulse (px/s, divided by enemy mass) of the revival shockwave.
const REVIVE_PUSH_FORCE: float = 420.0  # TUNING (not in GDD)

# --- Trees -------------------------------------------------------------------------

## Display order of the trees (Ossuary columns, left to right).
const TREE_ORDER := ["necromancy", "shadowcraft", "survival", "fortune"]

## Tree definitions (GDD §9.2): display_name, "improves" line from the GDD
## table, icon (MetaGlyphs kind) and accent colour.
const TREES := {
	# Standalone Oath entry (not in TREE_ORDER: shown in the Ossuary's bottom row).
	"oath": {"display_name": "Oath", "improves": "Opt-in difficulty for richer rewards", "icon": "tree_oath", "color": Palette.CRIMSON},  # TUNING (not in GDD)
	"necromancy": {"display_name": "Necromancy", "improves": "Minion cap, health and damage", "icon": "tree_necromancy", "color": Palette.NECRO_GREEN},  # GDD §9.2
	"shadowcraft": {"display_name": "Shadowcraft", "improves": "Spell damage, cooldowns, AoE", "icon": "tree_shadowcraft", "color": Palette.VIOLET},  # GDD §9.2
	"survival": {"display_name": "Survival", "improves": "Health, armor and movement", "icon": "tree_survival", "color": Palette.COLD_BLUE},  # GDD §9.2
	"fortune": {"display_name": "Fortune", "improves": "Pickup radius, luck and rerolls", "icon": "tree_fortune", "color": Palette.GOLD},  # GDD §9.2
}

# --- Modifier stats ----------------------------------------------------------------

## Modifier stat -> [UI label, format]. Formats: "pct" (+N%), "neg_pct" (-N%),
## "int" (+N). Where each stat is read:
##   minion_hp, minion_damage     HordeDirector.compute_stats (own category)
##   replace_reduction            HordeDirector.replenish_interval
##   warrior_capacity             HordeDirector.bonus_capacity (Warriors only)
##   capacity_per_class           HordeDirector.bonus_capacity (every class)
##   spell_damage, spell_cooldown, spell_area   AbilityManager.apply_spell_mods
##   max_hp, move_speed, pickup_radius, revives  MetaModifiers.apply_to_player
##   damage_reduction             CombatResolver.damage_player
##   xp_gain                      Game.add_xp
##   ash_gain                     Meta.compute_ash
##   rerolls, banishes            AbilityManager.setup (added to LevelUpData)
##   oath_tier                    DifficultyModifiers.oath_tier (Profane Oath)
const STATS := {
	"oath_tier": ["Oath tier", "int"],
	"minion_hp": ["Minion HP", "pct"],
	"minion_damage": ["Minion damage", "pct"],
	"replace_reduction": ["Replacement time", "neg_pct"],
	"warrior_capacity": ["Warrior capacity", "int"],
	"capacity_per_class": ["Capacity per class", "int"],
	"spell_damage": ["Spell damage", "pct"],
	"spell_cooldown": ["Spell cooldowns", "neg_pct"],
	"spell_area": ["Spell area", "pct"],
	"max_hp": ["Max HP", "int"],
	"damage_reduction": ["Damage taken", "neg_pct"],
	"move_speed": ["Move speed", "pct"],
	"revives": ["Revivals per run", "int"],
	"pickup_radius": ["Pickup radius", "pct"],
	"xp_gain": ["XP gain", "pct"],
	"ash_gain": ["Soul Ash gain", "pct"],
	"rerolls": ["Rerolls per run", "int"],
	"banishes": ["Banishes per run", "int"],
}

# --- Upgrades ----------------------------------------------------------------------

## Every upgrade in Ossuary order (grouped by tree, top to bottom).
const UPGRADE_ORDER := [
	"necrotic_marrow", "sharpened_bones", "grave_call", "risen_vanguard", "legion_of_bone",
	"umbral_potency", "quickened_rites", "widening_dark", "shadow_mastery",
	"grave_flesh", "bone_mail", "fleet_shade", "undying_will",
	"soul_magnet", "grave_tithe", "ash_harvest", "fates_thread", "banishing_rite",
	"profane_oath",
]

## Upgrade definitions.
##   tree         — TREES key.
##   display_name — UI name.
##   icon         — MetaGlyphs kind.
##   description  — Ossuary flavour + effect text.
##   stat         — STATS key raised by this upgrade.
##   per_tier     — stat added per purchased tier (tier N gives N * per_tier).
##   costs        — Soul Ash price of each tier (size = number of tiers).
##   requires     — {"id": upgrade, "tier": N} needed before tier 1 ({} = none).
const UPGRADES := {
	# Oath (standalone, user request): opt-in difficulty, cheap on purpose
	# since it is a risk / reward choice rather than pure power.
	"profane_oath": {"tree": "oath", "display_name": "Profane Oath", "icon": "profane_oath",
		"description": "Swear yourself to the grave: from the first second, more and stronger Covenant soldiers, and richer XP, Soul Ash and power-ups.",
		"stat": "oath_tier", "per_tier": 1.0, "costs": [25, 50, 75, 100, 125], "requires": {}},  # TUNING (not in GDD)
	# Necromancy (GDD §9.2: minion cap, health and damage).
	"necrotic_marrow": {"tree": "necromancy", "display_name": "Necrotic Marrow", "icon": "necrotic_marrow",
		"description": "Grave-marrow thickens the bones of every summon.",
		"stat": "minion_hp", "per_tier": 0.06, "costs": [40, 80, 125, 175, 230], "requires": {}},  # TUNING (not in GDD)
	"sharpened_bones": {"tree": "necromancy", "display_name": "Sharpened Bones", "icon": "sharpened_bones",
		"description": "Your undead strike with honed bone and rusted steel.",
		"stat": "minion_damage", "per_tier": 0.05, "costs": [40, 80, 125, 175, 230], "requires": {}},  # TUNING (not in GDD)
	"grave_call": {"tree": "necromancy", "display_name": "Grave Call", "icon": "grave_call",
		"description": "The fallen answer your call sooner.",
		"stat": "replace_reduction", "per_tier": 0.06, "costs": [60, 125, 200], "requires": {}},  # TUNING (not in GDD)
	"risen_vanguard": {"tree": "necromancy", "display_name": "Risen Vanguard", "icon": "risen_vanguard",
		"description": "More Skeleton Warriors rise with you, from the very first second.",
		"stat": "warrior_capacity", "per_tier": 1.0, "costs": [130, 280], "requires": {"id": "necrotic_marrow", "tier": 2}},  # TUNING (not in GDD)
	"legion_of_bone": {"tree": "necromancy", "display_name": "Legion of Bone", "icon": "legion_of_bone",
		"description": "Every summon class you command fields one more soldier.",
		"stat": "capacity_per_class", "per_tier": 1.0, "costs": [500], "requires": {"id": "risen_vanguard", "tier": 2}},  # TUNING (not in GDD)
	# Shadowcraft (GDD §9.2: spell damage, cooldown reduction, AoE).
	"umbral_potency": {"tree": "shadowcraft", "display_name": "Umbral Potency", "icon": "umbral_potency",
		"description": "Your shadow spells bite deeper.",
		"stat": "spell_damage", "per_tier": 0.05, "costs": [40, 80, 125, 175, 230], "requires": {}},  # TUNING (not in GDD)
	"quickened_rites": {"tree": "shadowcraft", "display_name": "Quickened Rites", "icon": "quickened_rites",
		"description": "Practised incantations return faster.",
		"stat": "spell_cooldown", "per_tier": 0.03, "costs": [60, 115, 180, 250], "requires": {}},  # TUNING (not in GDD)
	"widening_dark": {"tree": "shadowcraft", "display_name": "Widening Dark", "icon": "widening_dark",
		"description": "Shadow Blast and evolved pulses reach farther.",
		"stat": "spell_area", "per_tier": 0.06, "costs": [70, 145, 230], "requires": {"id": "umbral_potency", "tier": 1}},  # TUNING (not in GDD)
	"shadow_mastery": {"tree": "shadowcraft", "display_name": "Shadow Mastery", "icon": "shadow_mastery",
		"description": "The pinnacle of shadowcraft: a final surge of spell power.",
		"stat": "spell_damage", "per_tier": 0.10, "costs": [450], "requires": {"id": "quickened_rites", "tier": 3}},  # TUNING (not in GDD)
	# Survival (GDD §9.2: health, armor and movement).
	"grave_flesh": {"tree": "survival", "display_name": "Grave-Hardened Flesh", "icon": "grave_flesh",
		"description": "Bind grave-earth into your own body.",
		"stat": "max_hp", "per_tier": 10.0, "costs": [40, 80, 125, 175, 230], "requires": {}},  # TUNING (not in GDD)
	"bone_mail": {"tree": "survival", "display_name": "Bone Mail", "icon": "bone_mail",
		"description": "A ribcage of bone plates turns aside every blow (armor).",
		"stat": "damage_reduction", "per_tier": 0.03, "costs": [60, 115, 180, 250], "requires": {}},  # TUNING (not in GDD)
	"fleet_shade": {"tree": "survival", "display_name": "Fleet Shade", "icon": "fleet_shade",
		"description": "Glide over the graveyard like a shadow.",
		"stat": "move_speed", "per_tier": 0.04, "costs": [50, 105, 175], "requires": {}},  # TUNING (not in GDD)
	"undying_will": {"tree": "survival", "display_name": "Undying Will", "icon": "undying_will",
		"description": "Once per run, rise from death with half your health in a burst of grave-fire.",
		"stat": "revives", "per_tier": 1.0, "costs": [550], "requires": {"id": "bone_mail", "tier": 2}},  # TUNING (not in GDD)
	# Fortune (GDD §9.2: pickup radius, reward luck and rerolls).
	"soul_magnet": {"tree": "fortune", "display_name": "Soul Magnet", "icon": "soul_magnet",
		"description": "XP crystals are drawn to you from farther away.",
		"stat": "pickup_radius", "per_tier": 0.10, "costs": [30, 65, 105, 155], "requires": {}},  # TUNING (not in GDD)
	"grave_tithe": {"tree": "fortune", "display_name": "Grave Tithe", "icon": "grave_tithe",
		"description": "Every soul you harvest yields a little more experience (reward luck).",
		"stat": "xp_gain", "per_tier": 0.04, "costs": [60, 125, 200], "requires": {}},  # TUNING (not in GDD)
	"ash_harvest": {"tree": "fortune", "display_name": "Ash Harvest", "icon": "ash_harvest",
		"description": "Sift more Soul Ash from every battle (reward luck).",
		"stat": "ash_gain", "per_tier": 0.05, "costs": [80, 165, 270], "requires": {}},  # TUNING (not in GDD)
	"fates_thread": {"tree": "fortune", "display_name": "Fate's Thread", "icon": "fates_thread",
		"description": "Pull one more thread of fate: +1 level-up reroll per run.",
		"stat": "rerolls", "per_tier": 1.0, "costs": [120, 250], "requires": {}},  # TUNING (not in GDD)
	"banishing_rite": {"tree": "fortune", "display_name": "Banishing Rite", "icon": "banishing_rite",
		"description": "Cast one more offer into the void: +1 level-up banish per run.",
		"stat": "banishes", "per_tier": 1.0, "costs": [150, 310], "requires": {"id": "fates_thread", "tier": 1}},  # TUNING (not in GDD)
}

# --- Achievements (GDD §9.4) ---------------------------------------------------------

## Display order of achievements.
const ACHIEVEMENT_ORDER := ["bone_legion", "heretics_bane", "dread_sovereign"]

## Achievement definitions (GDD §9.4 "Example Achievement Unlocks"). The GDD
## unlocks (Bone Golem, priest evolution unlock, Dread Sovereign skin) do not
## exist in the prototype yet, so each achievement is tracked and recorded in
## the save, and pays a one-time Soul Ash `bounty` until its unlock exists.
##   stat   — lifetime counter in Meta.lifetime that is compared with `goal`.
##   unlock — the GDD reward, shown as "(coming later)".
## Wording decisions for open question 40: "Warrior kills" are kills whose
## killing blow came from a Skeleton Warrior (strike or shield bash); "priests"
## are Covenant Chaplains.
const ACHIEVEMENTS := {
	"bone_legion": {"display_name": "Bone Legion", "description": "Skeleton Warriors slay 1,000 foes",
		"stat": "warrior_kills", "goal": 1000, "unlock": "Bone Golem", "bounty": 100},  # GDD §9.4 goal; bounty TUNING (not in GDD)
	"heretics_bane": {"display_name": "Heretic's Bane", "description": "Defeat 500 Covenant Chaplains",
		"stat": "chaplain_kills", "goal": 500, "unlock": "Priest evolution unlock", "bounty": 100},  # GDD §9.4 goal; bounty TUNING (not in GDD)
	"dread_sovereign": {"display_name": "Dread Sovereign", "description": "Slay Sir Alaric while commanding all 4 summon classes",
		"stat": "boss_kills_full_army", "goal": 1, "unlock": "The Dread Sovereign skin", "bounty": 150},  # GDD §9.4 goal; bounty TUNING (not in GDD)
}

## Damage sources whose killing blow counts as a Skeleton Warrior kill.
const WARRIOR_KILL_SOURCES := ["warrior", "bash"]

# --- Autotest profiles --------------------------------------------------------------

## Autotest --meta profiles: "none" (no upgrades, the default so balance runs
## stay comparable), "mid" (about half of every tree, ~8 good runs) and "max"
## (everything bought). Applied in memory only; user:// is never touched.
## No profile includes the Profane Oath (a difficulty choice, not power), so
## balance comparisons stay clean; the autotest sets it with --oath=N.
const AUTOTEST_PROFILES := ["none", "mid", "max"]


## Number of tiers of upgrade `id`.
static func max_tier(id: String) -> int:
	return (UPGRADES[id]["costs"] as Array).size()


## Soul Ash price of tier `tier` (1-based) of upgrade `id` (-1 if none).
static func tier_cost(id: String, tier: int) -> int:
	var costs: Array = UPGRADES[id]["costs"]
	if tier < 1 or tier > costs.size():
		return -1
	return int(costs[tier - 1])


## Total Soul Ash spent to own tiers 1..`tier` of upgrade `id`.
static func cost_up_to(id: String, tier: int) -> int:
	var total := 0
	for t in range(1, mini(tier, max_tier(id)) + 1):
		total += tier_cost(id, t)
	return total


## Soul Ash needed to buy every tier of every upgrade.
static func max_total_cost() -> int:
	var total := 0
	for id: String in UPGRADE_ORDER:
		total += cost_up_to(id, max_tier(id))
	return total


## Upgrade ids of tree `tree_id`, in Ossuary order.
static func upgrades_in(tree_id: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in UPGRADE_ORDER:
		if String(UPGRADES[id]["tree"]) == tree_id:
			out.append(id)
	return out


## Upgrade id -> tier for an autotest profile (see AUTOTEST_PROFILES). "mid"
## takes half of every upgrade (rounded up) and drops tiers whose
## prerequisite the profile does not meet.
static func autotest_tiers(profile: String) -> Dictionary:
	var out := {}
	if profile == "max":
		for id: String in UPGRADE_ORDER:
			out[id] = max_tier(id)
	elif profile == "mid":
		for id: String in UPGRADE_ORDER:
			out[id] = ceili(float(max_tier(id)) / 2.0)
		for id: String in UPGRADE_ORDER:
			var req: Dictionary = UPGRADES[id]["requires"]
			if not req.is_empty() and int(out.get(String(req["id"]), 0)) < int(req["tier"]):
				out[id] = 0
	out.erase(PactData.OATH_ID)  # Never part of a profile (see above).
	return out
