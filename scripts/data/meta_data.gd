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
## mid-tier purchases. Levels 1-5 of every upgrade (the Ossuary before the expansion)
## cost 9,635 (Oath excluded; 8,965 before the two Grave Step upgrades), i.e. about 21
## good runs (very roughly 16-27 with weaker runs and Ash Harvest).
## Deep levels (Ossuary expansion step 2, GDD §15.0 "Ossuary deep levels"): the 13
## upgrades with 3+ levels go up to level 10 (DEEP_UPGRADES). Each new level gives
## half of the upgrade's per-level value (DEEP_VALUE_SHARE, one override) and costs
## x1.10 the level before (DEEP_COST_GROWTH, from the upgrade's last old price,
## rounded to 5; DEEP_COST_SCALE scales every new price). The 80 new levels cost
## 24,950 in all (levels 6-10 alone, the gated ones, are 65 levels), so
## everything maxed is 34,585 (Oath excluded; max_total_cost() adds its 375); 140
## tiers in all, the Oath excluded (tools/ossuary_check.gd prints the table).
## Levels 6-7 open after a clear on Lich or harder, 8-9 after a Deathlord clear and 10
## after a Deathlord clear with Hyper (LEVEL_GATES; Meta.max_open_tier()).
##
## Four upgrade trees (GDD §9.2 table):
##   Necromancy  — minion cap, health and damage (+ replacement speed)
##   Shadowcraft — spell damage, cooldown reduction, AoE (+ the Grave Step
##                 dash cooldown)
##   Survival    — health, armor, movement (+ one revival per run and a
##                 second Grave Step charge)
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
## Unlocks: an upgrade whose stat has the "unlock" format is a one-tier
## purchase that switches something on; MetaModifiers.unlocks() reads it (none
## is on sale since the Spearhead stance was retired, RETIRED_REFUNDS).
## Each upgrade raises ONE modifier stat (STATS) by `per_tier` per tier.
## Costs rise per tier. `requires` names a prerequisite inside the same tree
## ({} = none). MetaModifiers sums the stats; the game's stat code reads them.
class_name MetaData
extends RefCounted

## Version written to user://save.cfg ([meta] save_version). Bump it and add
## a step to Meta._migrate() whenever the save layout changes.
## Version 2 (Ossuary deep levels): the [clears] section (hardest difficulty cleared,
## with and without Hyper); tiers above 5 became valid. Nothing moves or is refunded.
const SAVE_VERSION: int = 2

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
## "int" (+N), "unlock" (locked / unlocked). Where each stat is read:
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
##   dash_charges, dash_cooldown  GraveStep._ready (Grave Step dash)
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
	"dash_charges": ["Grave Step charges", "int"],
	"dash_cooldown": ["Grave Step cooldown", "neg_pct"],
}

# --- Upgrades ----------------------------------------------------------------------

## Every upgrade in Ossuary order (grouped by tree, top to bottom).
const UPGRADE_ORDER := [
	"necrotic_marrow", "sharpened_bones", "grave_call", "risen_vanguard", "legion_of_bone",
	"umbral_potency", "quickened_rites", "widening_dark", "shadow_mastery", "restless_shade",
	"grave_flesh", "bone_mail", "fleet_shade", "undying_will", "twin_shadow",
	"soul_magnet", "grave_tithe", "ash_harvest", "fates_thread", "banishing_rite",
	"profane_oath",
]
## Retired upgrades (no longer sold) -> the Soul Ash a save that owns one gets back on its
## next load (MetaProgress.load_save(); the key is not written again, so it is paid once).
##   spearhead_doctrine: unlocked the Spearhead army stance, gone since the Bone Ring became
##   the only formation (GDD §15.0 "Bone Ring is the only formation").
const RETIRED_REFUNDS := {"spearhead_doctrine": 200}  # TUNING (not in GDD) = its old price

## Upgrade definitions.
##   tree         — TREES key.
##   display_name — UI name.
##   icon         — MetaGlyphs kind.
##   description  — Ossuary flavour + effect text.
##   stat         — STATS key raised by this upgrade.
##   per_tier     — stat added per purchased tier up to the last listed one
##                  (each deep level after it adds deep_per_tier(); value_at()).
##   costs        — Soul Ash price of each listed tier (levels 1-5 at most; the
##                  later levels of DEEP_UPGRADES are priced by deep_cost()).
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
	# Grave Step cooldown (the dash, PlayerAbilityData): 3 tiers of -10% take
	# it from 5 s to 3.5 s (owner brief). Priced like Grave Call, a comparable
	# 3-tier quality-of-life upgrade.
	"restless_shade": {"tree": "shadowcraft", "display_name": "Restless Shade", "icon": "restless_shade",
		"description": "Your Grave Step gathers its shadow sooner.",
		"stat": "dash_cooldown", "per_tier": 0.10, "costs": [60, 120, 190], "requires": {}},  # TUNING (not in GDD)
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
	# Second Grave Step charge (owner brief). A movement upgrade, so it needs
	# Fleet Shade I; priced like a strong single-tier pick, between Fate's
	# Thread (120 / 250) and the 450-550 capstones.
	"twin_shadow": {"tree": "survival", "display_name": "Twin Shadow", "icon": "twin_shadow",
		"description": "Your shadow splits in two: store a second Grave Step.",
		"stat": "dash_charges", "per_tier": 1.0, "costs": [300], "requires": {"id": "fleet_shade", "tier": 1}},  # TUNING (not in GDD)
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

# --- Deep levels (Ossuary expansion step 2, owner decisions Oct 2026) ------------------

## Highest level of an upgrade with deep levels (owner: "levels 6-10").
const DEEP_MAX_TIER: int = 10  # GDD §15.0 "Ossuary expansion: owner decisions"
## Upgrades that get deep levels: every upgrade with 3+ levels before the expansion
## (the one- and two-level unlock-style ones and the Profane Oath keep their tiers).
## One with fewer than 5 listed levels gets its missing levels up to 5 as well: new
## levels under the same value and price rule, but open from the start (no gate).
const DEEP_UPGRADES := [
	"necrotic_marrow", "sharpened_bones", "grave_call",
	"umbral_potency", "quickened_rites", "widening_dark", "restless_shade",
	"grave_flesh", "bone_mail", "fleet_shade",
	"soul_magnet", "grave_tithe", "ash_harvest",
]  # GDD §15.0 "Ossuary deep levels"
## Share (0..1) of an upgrade's listed per_tier that each new level adds (owner brief:
## "about half of today's per-level value").
const DEEP_VALUE_SHARE: float = 0.5  # TUNING (not in GDD)
## Upgrade id -> stat added per new level, replacing per_tier * DEEP_VALUE_SHARE:
##   restless_shade 0.03 (Grave Step cooldown share per level): half (0.05) over seven
##   new levels would take the dash from 3.5 s to 1.75 s; at 0.03 level 10 is -51%,
##   2.45 s, so the i-frame dash stays a choice rather than a stream.
const DEEP_PER_TIER_OVERRIDES := {"restless_shade": 0.03}  # TUNING (not in GDD)
## Price growth per new level: level N costs DEEP_COST_GROWTH x level N-1 (the first
## new level grows from the last listed price).
const DEEP_COST_GROWTH: float = 1.10  # TUNING (not in GDD) retuned from the measured economy (docs/ossuary/ECONOMY.md): x1.35 made the new levels 60,105, x1.10 makes them ~25,000 of the ~55,000 budget for all new content
## One scale over every new level's price (1.0 = the rule as is; the economy step's
## knob). Keep it at 0.75 or above, or a level 6 would cost less than its level 5.
const DEEP_COST_SCALE: float = 1.0  # TUNING (not in GDD)
## New-level prices are rounded to the nearest multiple of this (Soul Ash).
const DEEP_COST_ROUND: int = 5  # TUNING (not in GDD)
## Highest level a save may buy without any difficulty clear.
const UNGATED_MAX_TIER: int = 5  # GDD §15.0 "Ossuary expansion: owner decisions"
## Difficulty gates, lowest first. A row opens levels `from`..`to` once a run reached
## 0:00 (a victory) on ANY stage on `difficulty` or a harder DifficultyData level, with
## Hyper on when `hyper` is true (Meta.gate_met(), Meta.max_open_tier()). `short` is
## the word a tile shows while its next level waits on this gate.
const LEVEL_GATES := [
	{"from": 6, "to": 7, "difficulty": "lich", "hyper": false, "short": "Lich"},
	{"from": 8, "to": 9, "difficulty": "deathlord", "hyper": false, "short": "Deathlord"},
	{"from": 10, "to": 10, "difficulty": "deathlord", "hyper": true, "short": "Hyper"},
]  # GDD §15.0 "Ossuary expansion: owner decisions" (decision 2)

# --- Achievements (GDD §9.4) ---------------------------------------------------------

## Display order of achievements.
const ACHIEVEMENT_ORDER := ["bone_legion", "heretics_bane", "dread_sovereign", "dawn_extinguished",
	# --- Act II: Gullhaven Harbour ---
	"low_tide",
	# --- Act II: the Hollow Archive ---
	"nothing_unwritten",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"the_dead_god_serves",
	# --- Content wave 2: B. Achievement rewards ---
	"mass_grave", "untouchable", "full_ossuary", "deathlords_due", "swift_judgment",
	# --- Act III: the Assembly Halls ---
	"cold_assembly",
	# --- Act III: the Scrap Wastes ---
	"static_in_the_wastes",
	# --- Act III: the Iron Citadel ---
	"nothing_is_deathless"]

## Achievement definitions (GDD §9.4 "Example Achievement Unlocks"). Each
## achievement is tracked and recorded in the save and pays a one-time Soul
## Ash `bounty`; its REWARD (content wave 2, GDD §15.0 "Achievement rewards
## (content wave 2)": a new option or a cosmetic, never raw power) is an
## UnlockData row whose `achievement` names it (an ultimate, a title, a skin,
## a summon class or a passive), an achievement skin (SkinData) or the epilogue.
##   stat   — lifetime counter in Meta.lifetime that is compared with `goal`
##            (or, with `stage`, that key of the stage's record).
##   stage  — optional StageRegistry id: `stat` is read from that stage's
##            record (Meta.stage_record(); Meta.achievement_progress()).
##   unlock — the reward as one line for the Codex's reward column (the
##            rewards themselves are the UnlockData / SkinData rows).
##   run    — optional, true for the content-wave-2 achievements earned by
##            ONE run's counters (RunRewards): the autotest checks them only
##            with --meta-save or --rewards=on (MetaProgress.award_run()).
## Wording decisions for open question 40: "Warrior kills" are kills whose
## killing blow came from a Skeleton Warrior (strike or shield bash, also as a
## Death Knight); "priests" are Covenant Chaplains. Priest split (GDD §15.0):
## Dread Sovereign's "all 4 summon classes" are the GDD's four roles, with
## either priest order (Mender / Warder, or the merged Profane Bishop) as the
## priest. Dread Sovereign counts a kill of ANY stage boss (Sir Alaric, Marshal
## Vael, Seraphine or an Act II boss), not only Sir Alaric's.
const ACHIEVEMENTS := {
	"bone_legion": {"display_name": "Bone Legion", "description": "Skeleton Warriors slay 1,000 foes",
		"stat": "warrior_kills", "goal": 1000, "unlock": "The Bone Golem summon class, the Ivory Seer skin", "bounty": 100},  # GDD §9.4 goal; bounty TUNING (not in GDD)
	"heretics_bane": {"display_name": "Heretic's Bane", "description": "Defeat 500 Covenant Chaplains",
		"stat": "chaplain_kills", "goal": 500, "unlock": "Title Heretic's Bane, a gold Chaplain-skull frame", "bounty": 100},  # GDD §9.4 goal; bounty TUNING (not in GDD)
	"dread_sovereign": {"display_name": "Dread Sovereign", "description": "Slay a stage boss while commanding Warriors, Archers, Mages and a priest order",
		"stat": "boss_kills_full_army", "goal": 1, "unlock": "Ultimate Sovereign's Decree", "bounty": 150},  # GDD §9.4 goal; bounty TUNING (not in GDD)
	# Owner-approved Stage 3 achievement: the stage boss of the Sanctum slain
	# (counted from the stage record, so it works for any boss the stage names).
	"dawn_extinguished": {"display_name": "Dawn Extinguished", "description": "Defeat Grand Inquisitor Seraphine in the Sanctum of Judgment",
		"stat": "boss_kills", "stage": "sanctum", "goal": 1, "unlock": "Ultimate Eclipse, the Act I epilogue", "bounty": 200},  # GDD §7.5 ending; bounty TUNING (not in GDD)
	# --- Act II: Gullhaven Harbour ---
	# Owner-approved Act II achievement: a victory (the run reached 0:00) on
	# Gullhaven Harbour, counted from the stage record; it unlocks Brinewalker.
	"low_tide": {"display_name": "Low Tide", "description": "Clear Gullhaven Harbour",
		"stat": "victories", "stage": "harbour", "goal": 1, "unlock": "The Brinewalker passive", "bounty": 200},  # owner-approved proposal; bounty TUNING (not in GDD)
	# --- Act II: the Hollow Archive ---
	# Owner-approved proposal: burn every forbidden tome in one Hollow Archive
	# run (ArchiveDirector sets the run stat archive_all_tomes; MetaProgress
	# counts such runs in the lifetime counter archive_all_tomes_runs).
	"nothing_unwritten": {"display_name": "Nothing Unwritten", "description": "Burn every forbidden tome in one Hollow Archive run",
		"stat": "archive_all_tomes_runs", "goal": 1, "unlock": "The Iron Mind passive", "bounty": 150},  # bounty TUNING (not in GDD)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# The finale of Act II (proposal: "Achievement The Dead God Serves unlocks
	# the campaign epilogue"): Vhal'Neth slain on Ul-Thalos. With Dawn
	# Extinguished it opens the epilogue (EpilogueData, the main menu's
	# Epilogue screen): Dawn Extinguished the Act I part, this one Act II's.
	"the_dead_god_serves": {"display_name": "The Dead God Serves", "description": "Slay Vhal'Neth, the Dreaming Mother, on Ul-Thalos and raise her",
		"stat": "boss_kills", "stage": "spire", "goal": 1, "unlock": "Title Master of the Drowned, the Act II epilogue", "bounty": 300},  # Proposal; bounty TUNING (not in GDD)
	# --- Content wave 2: B. Achievement rewards ---
	# Five one-run achievements (owner-approved Proposal 2). Their lifetime
	# counters are filled by MetaProgress.award_run() from the run's RunRewards
	# counters (MetaProgress.run_counters()): a best-run record ("best_*", compared with the goal, so the Codex
	# bar shows the best run so far) or a count of qualifying runs (goal 1).
	"mass_grave": {"display_name": "Mass Grave", "description": "Raise 500 temporary undead in one run",
		"stat": "best_temp_raised", "goal": 500, "run": true, "unlock": "Ultimate Grave Tide", "bounty": 150},  # owner-approved goal; bounty TUNING (not in GDD)
	"untouchable": {"display_name": "Untouchable", "description": "Reach 0:00 on any stage without dropping below half health",
		"stat": "untouchable_runs", "goal": 1, "run": true, "unlock": "The Untouchable skin (any character)", "bounty": 200},  # owner-approved goal; bounty TUNING (not in GDD)
	"full_ossuary": {"display_name": "Full Ossuary", "description": "Hold 4 evolutions at once in one run (spell or summon)",
		"stat": "best_evolutions_held", "goal": 4, "run": true, "unlock": "Title Archnecromancer", "bounty": 150},  # owner-approved goal; bounty TUNING (not in GDD)
	"deathlords_due": {"display_name": "Deathlord's Due", "description": "Clear any stage on Deathlord difficulty",
		"stat": "deathlord_victories", "goal": 1, "run": true, "unlock": "The Deathlord skin (any character)", "bounty": 250},  # owner-approved goal; bounty TUNING (not in GDD)
	"swift_judgment": {"display_name": "Swift Judgment", "description": "Slay a stage boss within 45 s of its arrival",
		"stat": "swift_boss_kills", "goal": 1, "run": true, "unlock": "Title Executioner", "bounty": 150},  # owner-approved goal; bounty TUNING (not in GDD)
	# --- Act III: the Assembly Halls ---
	# Owner-approved Act III proposal: destroy every fabricator in one Assembly
	# Halls run (AssemblyDirector sets the run stat assembly_all_fabricators;
	# MetaProgress counts such runs in the lifetime counter assembly_cold_runs).
	# It unlocks the counter-passive Signal Ghost (UnlockData).
	"cold_assembly": {"display_name": "Cold Assembly", "description": "Destroy every fabricator in one Assembly Halls run",
		"stat": "assembly_cold_runs", "goal": 1, "unlock": "The Signal Ghost passive", "bounty": 200},  # Owner-approved proposal; bounty TUNING (not in GDD)
	# --- Act III: the Scrap Wastes ---
	# Owner-approved Act III achievement: a victory (the run reached 0:00) on
	# the Scrap Wastes, counted from the stage record (like Low Tide); it
	# unlocks the Lead-Lined Bones counter-passive.
	"static_in_the_wastes": {"display_name": "Static in the Wastes", "description": "Clear the Scrap Wastes",
		"stat": "victories", "stage": "wastes", "goal": 1, "unlock": "The Lead-Lined Bones passive", "bounty": 250},  # Owner-approved Act III proposal; bounty TUNING (not in GDD)
	# --- Act III: the Iron Citadel ---
	# The finale of Act III and of the campaign (owner-approved proposal:
	# "Nothing Is Deathless: defeat Deus Ex Machina; reward: the Act III epilogue
	# + title Breaker of Engines"): the stage boss slain in the Iron Citadel,
	# counted from the stage record. Its title is an UnlockData row; its epilogue
	# part is EpilogueData.ACT3_PART (the last row of EpilogueData.PARTS).
	"nothing_is_deathless": {"display_name": "Nothing Is Deathless", "description": "Defeat Deus Ex Machina in the Iron Citadel",
		"stat": "boss_kills", "stage": "citadel", "goal": 1, "unlock": "Title Breaker of Engines, the Act III epilogue", "bounty": 350},  # Owner-approved proposal; bounty TUNING (not in GDD) the campaign's last (The Dead God Serves 300)
}

# --- Content wave 2: B. Achievement rewards ---
## Untouchable: the lowest share of max HP (0..1) the necromancer may fall to
## before 0:00; a hit that leaves him lower (or kills him) spoils the run.
const UNTOUCHABLE_HP_FRACTION: float = 0.5  # owner-approved Proposal 2
## Swift Judgment: most game seconds from the stage boss's arrival
## (EnemyDirector.boss_spawned) to its death.
const SWIFT_JUDGMENT_SECONDS: float = 45.0  # owner-approved Proposal 2
## Deathlord's Due: the DifficultyData id whose victories count.
const DEATHLORD_DIFFICULTY_ID: String = "deathlord"  # owner-approved Proposal 2

## Damage sources whose killing blow counts as a Skeleton Warrior kill (the
## Death Knight is an evolved Skeleton Warrior: strike, bash and cleave).
const WARRIOR_KILL_SOURCES := ["warrior", "bash", "death_knight", "death_knight_bash", "death_knight_cleave"]
## Classes Dread Sovereign needs (SynergyManager.classes_met, level 1+): the
## GDD's four summon roles, UnitData.CORE_CLASSES; the nested array is "any
## one of" the priest orders (the Profane Bishop counts as both through
## UnitData "counts_as"). The later classes (Abomination, Rogue, Gargoyle,
## Frost Wraith) are never required.
const DREAD_SOVEREIGN_CLASSES: Array = UnitData.CORE_CLASSES

# --- Autotest profiles --------------------------------------------------------------

## Autotest --meta profiles: "none" (no upgrades, the default so balance runs
## stay comparable), "mid" (about half of every tree's levels 1-5, ~8 good runs;
## unchanged by the deep levels) and "max" (everything bought, levels 6-10 included). Applied in memory only; user:// is never touched.
## No profile includes the Profane Oath (a difficulty choice, not power), so
## balance comparisons stay clean; the autotest sets it with --oath=N.
const AUTOTEST_PROFILES := ["none", "mid", "max"]


## Number of tiers of upgrade `id` (DEEP_MAX_TIER for a DEEP_UPGRADES one).
static func max_tier(id: String) -> int:
	if DEEP_UPGRADES.has(id):
		return DEEP_MAX_TIER
	return listed_tiers(id)


## Number of tiers listed in upgrade `id`'s `costs` (its levels before the expansion).
static func listed_tiers(id: String) -> int:
	return (UPGRADES[id]["costs"] as Array).size()


## Soul Ash price of tier `tier` (1-based) of upgrade `id` (-1 if none): the listed
## price, or deep_cost() for a new level.
static func tier_cost(id: String, tier: int) -> int:
	if tier < 1 or tier > max_tier(id):
		return -1
	var costs: Array = UPGRADES[id]["costs"]
	if tier <= costs.size():
		return int(costs[tier - 1])
	return deep_cost(id, tier)


## Price of new level `tier` of upgrade `id`: its last listed price x
## DEEP_COST_GROWTH per level after it, x DEEP_COST_SCALE, rounded to DEEP_COST_ROUND.
static func deep_cost(id: String, tier: int) -> int:
	var costs: Array = UPGRADES[id]["costs"]
	var steps := tier - costs.size()  # New levels after the last listed one (1..).
	var raw := float(costs[costs.size() - 1]) * pow(DEEP_COST_GROWTH, float(steps)) * DEEP_COST_SCALE  # Unrounded price.
	return int(roundf(raw / float(DEEP_COST_ROUND))) * DEEP_COST_ROUND


## Stat added by each new (deep) level of upgrade `id`.
static func deep_per_tier(id: String) -> float:
	if DEEP_PER_TIER_OVERRIDES.has(id):
		return float(DEEP_PER_TIER_OVERRIDES[id])
	return float(UPGRADES[id]["per_tier"]) * DEEP_VALUE_SHARE


## Summed stat of upgrade `id` at tier `tier` (clamped to 0..max_tier): per_tier for
## each listed level, deep_per_tier() for each new one. The one value rule:
## MetaModifiers and the Ossuary's current / next values both read it.
static func value_at(id: String, tier: int) -> float:
	var t := clampi(tier, 0, max_tier(id))  # Valid tier.
	var listed := mini(t, listed_tiers(id))  # Listed levels in it.
	return float(UPGRADES[id]["per_tier"]) * float(listed) + deep_per_tier(id) * float(t - listed)


## Number of tiers of every upgrade together (the Oath excluded, like the
## autotest profiles): the autotest's Ossuary line.
static func total_tiers() -> int:
	var n := 0  # Tiers so far.
	for id: String in UPGRADE_ORDER:
		if id != PactData.OATH_ID:
			n += max_tier(id)
	return n


## The LEVEL_GATES row that tier `tier` waits on ({} = open from the start).
static func gate_of(tier: int) -> Dictionary:
	for g: Dictionary in LEVEL_GATES:
		if tier >= int(g["from"]) and tier <= int(g["to"]):
			return g
	return {}


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


## Upgrade id -> tier for an autotest profile (see AUTOTEST_PROFILES). "max"
## is every tier, the deep levels included (a profile ignores the difficulty
## gates); "mid" takes half of every upgrade's LISTED tiers (rounded up: the
## same tiers as before the deep levels) and drops tiers whose prerequisite the
## profile does not meet.
static func autotest_tiers(profile: String) -> Dictionary:
	var out := {}
	if profile == "max":
		for id: String in UPGRADE_ORDER:
			out[id] = max_tier(id)
	elif profile == "mid":
		for id: String in UPGRADE_ORDER:
			out[id] = ceili(float(listed_tiers(id)) / 2.0)
		for id: String in UPGRADE_ORDER:
			var req: Dictionary = UPGRADES[id]["requires"]
			if not req.is_empty() and int(out.get(String(req["id"]), 0)) < int(req["tier"]):
				out[id] = 0
	out.erase(PactData.OATH_ID)  # Never part of a profile (see above).
	return out
