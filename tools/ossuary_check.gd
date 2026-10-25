## Ossuary deep levels check (expansion step 2, GDD §15.0 "Ossuary deep levels"):
## a unit-style regression for MetaData's deep-level prices and values, the
## difficulty gates (Meta.max_open_tier(), purchase_block() "gated"), the save
## migration (a version-1 / version-0 save written to a temp file, loaded,
## saved and loaded again), Refund all, and the co-op loadout carrying levels
## 6-10. It never touches the real save: Meta.save_path points at a file in
## --check-dir (default user://ossuary_check/, deleted afterwards) while it runs,
## and the Meta state is reset when it ends. Run headless with --autotest:
##   godot --headless res://tools/ossuary_check.tscn -- --autotest [--check-dir=DIR]
## Prints "[ossuary_check] PASS" or the failed checks (exit 1).
## Screenshot mode (a real window, e.g. under xvfb-run; drawing only):
##   godot res://tools/ossuary_check.tscn -- --autotest --shot=PATH [--phone] [--open=N]
## opens the Ossuary over a sample save in memory (some upgrades bought, the
## Lich gate open with --open=7 (default), 5 / 9 / 10 likewise) and saves the
## window to PATH; --phone uses an 844 x 390 CSS px landscape phone at 2x with
## the mobile UI scale (TouchData.UI_SCALE_MAX); --sealed keeps Dominion sealed (no
## Seraphine kill) and --detail=ID shows that upgrade in the detail panel.
## Step 3 (new options and Dominion) adds the option prices / gates, the mid / max
## profiles, Elite Bounty's Soul Ash and the loadout checks.
## tools/.gdignore keeps it out of exports.
extends Node

## Failed checks (any failure exits 1).
var _failures: int = 0
## Directory of the temp save files (an absolute path or user:// subfolder).
var _dir: String = "user://ossuary_check"
## Screenshot target path ("" = run the checks instead).
var _shot: String = ""
## Recolours screenshot (step 6b, `--shot-prerun=PATH`): the pre-run screen of
## `--shot-char=ID` (default bone_oracle) wearing `--shot-skin=ID` with the
## recolour `--shot-rc=ID` bought and worn ("" = none; `--shot-buy` shows an
## unowned one instead), the window saved to PATH.
var _shot_prerun: String = ""
## Recolours screenshot: character id.
var _shot_char: String = "bone_oracle"
## Recolours screenshot: skin id ("" = the character's default skin).
var _shot_skin: String = ""
## Recolours screenshot: recolour id shown.
var _shot_rc: String = ""
## Recolours screenshot: true shows the recolour as an unowned offer.
var _shot_buy: bool = false
## Screenshot mode: emulate a landscape phone.
var _phone: bool = false
## Screenshot mode: the sample save's open level (5, 7, 9 or 10).
var _open: int = 7
## Screenshot mode: Dominion still sealed (--sealed: no Seraphine kill).
var _sealed: bool = false
## Screenshot mode: the upgrade shown in the detail panel (--detail=ID; "" = the default).
var _detail: String = ""
## Screenshot mode: "" = the Trees (the Ossuary screen), "masteries" = the Masteries panel.
var _tab: String = ""


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--check-dir="):
			_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shot="):
			_shot = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-prerun="):
			_shot_prerun = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-char="):
			_shot_char = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-skin="):
			_shot_skin = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-rc="):
			_shot_rc = arg.get_slice("=", 1)
		elif arg == "--shot-buy":
			_shot_buy = true
		elif arg == "--phone":
			_phone = true
		elif arg.begins_with("--tab="):
			_tab = arg.get_slice("=", 1)
		elif arg.begins_with("--open="):
			_open = arg.get_slice("=", 1).to_int()
		elif arg == "--sealed":
			_sealed = true
		elif arg.begins_with("--detail="):
			_detail = arg.get_slice("=", 1)
	call_deferred("_run")


func _run() -> void:
	if not GameState.autotest:
		push_error("ossuary_check requires --autotest (the real save is never read).")
		get_tree().quit(2)
		return
	if _shot_prerun != "":
		await _screenshot_prerun()
		return
	if _shot != "":
		await _screenshot()
		return
	_check_data()
	_check_gates()
	_check_dominion()
	_check_migration()
	_check_purchase_and_refund()
	_check_coop_loadout()
	_check_masteries()
	_check_recolours()
	Meta._reset()
	Meta.save_path = Meta.DEFAULT_PATH
	if _failures == 0:
		print("[ossuary_check] PASS")
		get_tree().quit(0)
	else:
		print("[ossuary_check] FAIL (%d)" % _failures)
		get_tree().quit(1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		print("[ossuary_check] FAILED: " + what)


# --- Data ---------------------------------------------------------------------------

## Levels 1-5 keep their prices and values; the deep levels follow the rule.
func _check_data() -> void:
	var listed_total := 0  # Price of every listed tier (the Ossuary before the expansion).
	var options_total := 0  # Price of step 3's new options and third levels.
	var new_total := 0  # Price of every new level.
	var rows := PackedStringArray()  # The level table, one line per deep upgrade.
	for id: String in MetaData.UPGRADE_ORDER:
		if id == PactData.OATH_ID:
			continue
		var def: Dictionary = MetaData.UPGRADES[id]
		var costs: Array = def["costs"]
		var old_levels := 0 if MetaData.OPTIONS_UPGRADES.has(id) else int(MetaData.OPTIONS_EXTRA_LEVELS.get(id, costs.size()))  # Levels from before step 3.
		for t in range(1, costs.size() + 1):
			_check(MetaData.tier_cost(id, t) == int(costs[t - 1]), "%s level %d keeps its price" % [id, t])
			_check(is_equal_approx(MetaData.value_at(id, t), float(def["per_tier"]) * float(t)), "%s level %d keeps its value" % [id, t])
			if t <= old_levels:
				listed_total += int(costs[t - 1])
			else:
				options_total += int(costs[t - 1])
		if not MetaData.DEEP_UPGRADES.has(id):
			_check(MetaData.max_tier(id) == costs.size(), "%s keeps %d levels" % [id, costs.size()])
			continue
		_check(costs.size() >= 3, "%s had 3+ levels" % id)
		_check(MetaData.max_tier(id) == MetaData.DEEP_MAX_TIER, "%s goes to level 10" % id)
		var prices := PackedStringArray()  # New-level prices.
		var prev := int(costs[costs.size() - 1])
		for t in range(costs.size() + 1, MetaData.DEEP_MAX_TIER + 1):
			var c := MetaData.tier_cost(id, t)
			_check(c > prev, "%s level %d costs more than level %d" % [id, t, t - 1])
			prev = c
			new_total += c
			prices.append(str(c))
		rows.append("%s: +%s per new level, %s, level 10 = %s" % [id, str(MetaData.deep_per_tier(id)), "/".join(prices),
			str(snappedf(MetaData.value_at(id, 10), 0.001))])
	_check(listed_total == 9635, "levels 1-5 still cost 9,635 in all (got %d)" % listed_total)
	_check(MetaData.tier_cost("necrotic_marrow", 11) == -1 and MetaData.tier_cost("necrotic_marrow", 0) == -1, "no level 0 / 11")
	_check(MetaData.max_tier(PactData.OATH_ID) == 5, "the Oath keeps 5 tiers")
	for r: String in rows:
		print("[ossuary_check] " + r)
	print("[ossuary_check] totals: levels 1-5 %d, new levels %d, all %d (Oath excluded), %d tiers" % [
		listed_total, new_total, listed_total + new_total, MetaData.total_tiers()])
	print("[ossuary_check] new options (step 3): %d upgrades + 2 third levels, %d Soul Ash; everything %d (Oath excluded)" % [
		MetaData.OPTIONS_UPGRADES.size(), options_total, listed_total + new_total + options_total])
	_check(options_total == 9060, "the new options cost 9,060 in all (got %d)" % options_total)
	for id: String in MetaData.OPTIONS_UPGRADES:
		_check(MetaData.UPGRADES.has(id) and MetaData.UPGRADE_ORDER.has(id), "%s is an upgrade" % id)
		_check(not MetaData.DEEP_UPGRADES.has(id) and MetaData.max_tier(id) <= 5, "%s has 1-5 levels, no deep ones" % id)
		_check(MetaData.STATS.has(String(MetaData.UPGRADES[id]["stat"])), "%s raises a known stat" % id)
		_check(MetaData.TREE_ORDER.has(String(MetaData.UPGRADES[id]["tree"])), "%s is in a tree" % id)
	_check(MetaData.upgrades_in("dominion").size() == 3, "Dominion has three upgrades")
	_check(MetaData.max_total_cost() == listed_total + new_total + options_total + 375, "max_total_cost() = all + the Oath's 375")
	var mid := MetaData.autotest_tiers("mid")  # The mid profile must not change.
	_check(int(mid.get("necrotic_marrow", 0)) == 3 and int(mid.get("grave_call", 0)) == 2 and int(mid.get("quickened_rites", 0)) == 2, "--meta=mid unchanged")
	_check(int(mid.get("fates_thread", 0)) == 1 and int(mid.get("banishing_rite", 0)) == 1, "--meta=mid keeps Fate's Thread / Banishing Rite at 1")
	for id: String in MetaData.OPTIONS_UPGRADES:
		_check(int(mid.get(id, 0)) == 0, "--meta=mid leaves out %s" % id)
	var mx := MetaData.autotest_tiers("max")
	_check(int(mx.get("necrotic_marrow", 0)) == 10 and int(mx.get("legion_of_bone", 0)) == 1 and not mx.has(PactData.OATH_ID), "--meta=max = every level")
	_check(int(mx.get("head_start", 0)) == 2 and int(mx.get("fates_thread", 0)) == 3, "--meta=max includes the new options")
	# Elite Bounty raises the elites part of the Soul Ash formula (ash per elite).
	var summary := {"stats": {"elite_kills": 10.0}, "time": 60.0}
	_check(int(Meta.compute_ash(summary, 0.0)["parts"]["elites"]) == 40, "elites pay 4 each")
	_check(int(Meta.compute_ash(summary, 0.0, 3.0)["parts"]["elites"]) == 70, "Elite Bounty III: 7 each")


# --- Gates --------------------------------------------------------------------------

## A victory summary on `diff` (Hyper when `hyper`).
static func _win(diff: String, hyper: bool, victory: bool = true) -> Dictionary:
	return {"victory": victory, "difficulty_id": diff, "hyper": hyper}


func _check_gates() -> void:
	Meta._reset()
	_check(Meta.max_open_tier() == 5, "fresh save: levels 1-5 open")
	Meta._record_clear(_win("deathlord", true, false))
	_check(Meta.max_open_tier() == 5, "a defeat opens nothing")
	Meta._record_clear(_win("necromancer", true))
	_check(Meta.max_open_tier() == 5, "a Necromancer + Hyper clear opens nothing")
	Meta._record_clear(_win("lich", false))
	_check(Meta.max_open_tier() == 7, "a Lich clear opens 6-7")
	Meta._record_clear(_win("lich", true))
	_check(Meta.max_open_tier() == 7, "a Lich + Hyper clear still 6-7")
	Meta._record_clear(_win("deathlord", false))
	_check(Meta.max_open_tier() == 9, "a Deathlord clear opens 8-9")
	Meta._record_clear(_win("initiate", false))
	_check(Meta.max_open_tier() == 9, "an easier clear never lowers it")
	Meta._record_clear(_win("deathlord", true))
	_check(Meta.max_open_tier() == 10, "a Deathlord + Hyper clear opens 10")
	Meta._reset()
	Meta._record_clear(_win("deathlord", true))
	_check(Meta.max_open_tier() == 10, "a Deathlord + Hyper clear alone opens everything")


# --- Dominion (new options, step 3) -------------------------------------------------

func _check_dominion() -> void:
	Meta._reset()
	Meta.soul_ash = 100000
	_check(not Meta.tree_open("dominion") and Meta.tree_open("necromancy"), "fresh save: Dominion sealed, the four trees open")
	_check(Meta.purchase_block("head_start") == "sealed" and not Meta.purchase("head_start"), "a sealed Dominion upgrade is refused")
	_check(Meta.purchase("bone_reserve") and Meta.purchase("elite_bounty"), "the new tree options buy")
	_check(Meta.purchase_block("echo_weaving") == "locked", "Echo Weaving needs Umbral Potency II")
	(Meta.stage_records["sanctum"] as Dictionary)["boss_kills"] = 1.0  # Seraphine slain once.
	_check(Meta.tree_open("dominion") and Meta.purchase("head_start"), "a Seraphine kill opens Dominion")
	Meta._reset()
	Meta.hyper_unlocked = true  # The same boss through the Hyper unlock.
	_check(Meta.tree_open("dominion"), "the Hyper unlock opens Dominion too")
	var mods := MetaModifiers.from_tiers({"head_start": 2, "last_rites": 3, "grave_ward": 2, "gilded_chests": 1})
	_check(mods.int_value("head_start") == 2 and is_equal_approx(mods.value("last_rites"), 3.0) and mods.int_value("ward_hits") == 2 and is_equal_approx(mods.value("gilded_chance"), 0.15), "the new stats sum")
	Meta._reset()


# --- Migration ----------------------------------------------------------------------

## Temp save path `name` inside the check directory.
func _path(name: String) -> String:
	return _dir.path_join(name)


## Writes an older-layout save at `path`: version `version` (0 = no key),
## Soul Ash `ash`, upgrade tiers `t`, and the Deathlord's Due records when
## `deathlord`.
static func _write_old(path: String, version: int, ash: int, t: Dictionary, deathlord: bool) -> void:
	var cfg := ConfigFile.new()
	if version > 0:
		cfg.set_value("meta", "save_version", version)
	cfg.set_value("currency", "soul_ash", ash)
	for id: String in t:
		cfg.set_value("upgrades", id, int(t[id]))
	cfg.set_value("lifetime", "runs", 12.0)
	cfg.set_value("lifetime", "deathlord_victories", 1.0 if deathlord else 0.0)
	cfg.set_value("achievements", "deathlords_due", deathlord)
	cfg.save(path)


func _check_migration() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	var owned := {"necrotic_marrow": 5, "sharpened_bones": 5, "grave_call": 3, "risen_vanguard": 2, "legion_of_bone": 1, "profane_oath": 5}
	var p := _path("v1_save.cfg")
	_write_old(p, 1, 1234, owned, false)
	Meta.save_path = p
	Meta.load_save()
	_check(Meta.load_status == "migrated", "a version-1 save migrates (got %s)" % Meta.load_status)
	_check(Meta.soul_ash == 1234, "migration refunds nothing (%d)" % Meta.soul_ash)
	for id: String in owned:
		_check(Meta.tier(id) == int(owned[id]), "migration keeps %s at %d" % [id, int(owned[id])])
	_check(Meta.best_clear == -1 and Meta.max_open_tier() == 5, "an old save without a Deathlord clear: levels 1-5")
	_check(Meta.purchase_block("necrotic_marrow") == "gated", "level 6 waits on the Lich gate")
	_check(Meta.purchase_block("grave_call") == "", "a 3-level upgrade's level 4 is open")
	# Round trip: save the migrated profile and load it again (version 2 now).
	GameState.autotest_meta_save = true  # Lets save() write (to the temp path only).
	Meta.best_hyper_clear = DifficultyData.ORDER.find("lich")
	_check(Meta.save() == OK, "the migrated save writes")
	GameState.autotest_meta_save = false
	Meta.load_save()
	_check(Meta.load_status == "ok", "the rewritten save loads as current (got %s)" % Meta.load_status)
	_check(Meta.best_hyper_clear == DifficultyData.ORDER.find("lich") and Meta.best_clear == -1, "[clears] round trip")
	_check(Meta.tier("necrotic_marrow") == 5 and Meta.soul_ash == 1234, "tiers and Soul Ash round trip")
	# Retroactive Deathlord clear (content wave 2's Deathlord's Due records).
	var p2 := _path("v1_deathlord.cfg")
	_write_old(p2, 1, 50, {"necrotic_marrow": 5}, true)
	Meta.save_path = p2
	Meta.load_save()
	_check(Meta.best_clear == DifficultyData.ORDER.find("deathlord") and Meta.max_open_tier() == 9, "an old Deathlord clear opens levels 6-9")
	# A version-0 file (no save_version key) and a version-2 file with levels 6-10.
	var p3 := _path("v0_save.cfg")
	_write_old(p3, 0, 10, {"bone_mail": 4}, false)
	Meta.save_path = p3
	Meta.load_save()
	_check(Meta.load_status == "migrated" and Meta.tier("bone_mail") == 4, "a version-0 save migrates and keeps its tiers")
	var p4 := _path("v2_deep.cfg")
	_write_old(p4, 2, 0, {"necrotic_marrow": 10, "grave_call": 8, "risen_vanguard": 2, "legion_of_bone": 3}, false)
	Meta.save_path = p4
	Meta.load_save()
	_check(Meta.tier("necrotic_marrow") == 10 and Meta.tier("grave_call") == 8, "levels 6-10 load")
	_check(Meta.tier("legion_of_bone") == 1, "a tier above an upgrade's range is clamped")
	for f: String in ["v1_save.cfg", "v1_deathlord.cfg", "v0_save.cfg", "v2_deep.cfg"]:
		DirAccess.remove_absolute(_path(f))
	Meta.save_path = Meta.DEFAULT_PATH


# --- Purchases and Refund all -----------------------------------------------------------

func _check_purchase_and_refund() -> void:
	Meta._reset()
	Meta.soul_ash = 100000
	for t in range(1, 6):
		_check(Meta.purchase("necrotic_marrow"), "level %d buys" % t)
	_check(not Meta.purchase("necrotic_marrow") and Meta.tier("necrotic_marrow") == 5, "level 6 is refused while gated")
	_check(not Meta.is_maxed("necrotic_marrow"), "level 5 of 10 is not maxed")
	Meta._record_clear(_win("lich", false))
	var price := Meta.next_cost("necrotic_marrow")
	_check(price == MetaData.deep_cost("necrotic_marrow", 6), "level 6 is priced by deep_cost()")
	var before := Meta.soul_ash
	_check(Meta.purchase("necrotic_marrow") and Meta.soul_ash == before - price, "level 6 buys after a Lich clear")
	_check(Meta.purchase("necrotic_marrow") and Meta.purchase_block("necrotic_marrow") == "gated", "level 7 buys, level 8 waits on Deathlord")
	var mods := MetaModifiers.from_tiers(Meta.tiers)
	_check(is_equal_approx(mods.value("minion_hp"), 0.30 + 0.06), "levels 6-7 add half steps (+3% each)")
	var spent := Meta.spent_total()
	_check(spent == MetaData.cost_up_to("necrotic_marrow", 7), "spent_total counts the deep levels")
	var ash_before := Meta.soul_ash
	_check(Meta.refund_all() == spent and Meta.soul_ash == ash_before + spent and Meta.tier("necrotic_marrow") == 0, "Refund all returns levels 6-7 too")
	Meta._reset()


# --- Co-op loadout ----------------------------------------------------------------------

func _check_coop_loadout() -> void:
	var lo := {"meta_levels": {"necrotic_marrow": 10, "bone_mail": 8, "legion_of_bone": 1}}
	var clean: Dictionary = CoopNet._clean_loadout(lo, 1)
	var lv: Dictionary = clean["meta_levels"]
	_check(int(lv.get("necrotic_marrow", 0)) == 10 and int(lv.get("bone_mail", 0)) == 8, "the co-op loadout keeps levels 6-10")
	var m := MetaModifiers.from_tiers(lv)
	_check(int(m.tiers.get("necrotic_marrow", 0)) == 10 and is_equal_approx(m.value("minion_hp"), MetaData.value_at("necrotic_marrow", 10)), "the partner's level 10 applies")
	_check(is_equal_approx(m.value("damage_reduction"), 0.12 + 4.0 * 0.015), "the partner's Bone Mail 8 applies")
	var lo2 := {"meta_levels": {"commanders_presence": 3, "head_start": 1}}
	var m2 := MetaModifiers.from_tiers(CoopNet._clean_loadout(lo2, 1)["meta_levels"])
	_check(is_equal_approx(m2.value("presence_damage"), 0.03) and m2.int_value("head_start") == 1, "the co-op loadout carries the new options")


# --- Masteries (Ossuary expansion step 4) -----------------------------------------------

func _check_masteries() -> void:
	# Data: every offerable summon class (not the evolved-only Bishop) has a mastery.
	var covered := 0
	for cls: String in UnitData.CLASS_ORDER:
		var evolved: bool = bool(UnitData.UNITS[cls].get("evolved_only", false))
		_check(MasteryData.is_masterable(cls) == not evolved, "%s %s a mastery" % [cls, "has no" if evolved else "has"])
		covered += 0 if evolved else 1
	_check(covered == MasteryData.CLASSES.size(), "every offerable class is in MasteryData.CLASSES")
	_check(MasteryData.cost_up_to(3) == 760 and MasteryData.total_cost() == 12920, "masteries cost 760 a class, 12,920 in all (got %d)" % MasteryData.total_cost())
	print("[ossuary_check] masteries: %d classes x %d / %d / %d = %d" % [MasteryData.CLASSES.size(), MasteryData.PRICES[0], MasteryData.PRICES[1], MasteryData.PRICES[2], MasteryData.total_cost()])
	# Unlock rule and purchases.
	Meta._reset()
	Meta.soul_ash = 10000
	_check(Meta.mastery_block("warrior") == "locked" and not Meta.buy_mastery("warrior"), "a mastery is locked until the class reaches Lv 5")
	_check(not Meta.record_class_level("warrior", 4) and Meta.mastery_block("warrior") == "locked", "Lv 4 opens nothing")
	_check(not Meta.record_class_level("bishop", 5) and not Meta.is_mastery_open("bishop"), "the Bishop has no mastery of its own")
	_check(Meta.record_class_level("warrior", 5) and Meta.is_mastery_open("warrior"), "Lv 5 opens the Warrior mastery")
	_check(not Meta.record_class_level("warrior", 5), "opening is recorded once")
	var ash := Meta.soul_ash
	for lv in range(1, 4):
		_check(Meta.mastery_cost("warrior") == MasteryData.price(lv), "mastery level %d price" % lv)
		_check(Meta.buy_mastery("warrior") and Meta.mastery_level("warrior") == lv, "mastery level %d buys" % lv)
	_check(Meta.soul_ash == ash - 760 and Meta.mastery_spent_total() == 760, "three levels cost 760")
	_check(Meta.mastery_block("warrior") == "maxed" and not Meta.buy_mastery("warrior") and Meta.mastery_cost("warrior") == -1, "level 3 is the last")
	Meta.record_class_level("archer", 5)
	Meta.soul_ash = 100
	_check(Meta.mastery_block("archer") == "cost" and not Meta.buy_mastery("archer"), "too little Soul Ash blocks a purchase")
	# The one stat path: MetaModifiers -> compute_stats reads mastery_value().
	var m := MetaModifiers.from_tiers({}, {"warrior": 3, "mender": 2, "archer": 9, "bishop": 3, "nonsense": 3})
	_check(is_equal_approx(m.mastery_value("warrior", "hp"), 0.12) and is_equal_approx(m.mastery_value("warrior", "damage"), 0.12), "level 3 = +12% HP and damage")
	_check(m.mastery_level("archer") == 3 and m.mastery_value("mage", "hp") == 0.0, "levels clamp to 3; other classes get nothing")
	_check(m.mastery_level("bishop") == 2, "the Bishop takes the better of Mender / Warder (got %d)" % m.mastery_level("bishop"))
	_check(not m.masteries.has("nonsense") and not m.masteries.has("bishop"), "unknown ids and the Bishop are not stored")
	_check(MetaModifiers.from_tiers({}).is_empty() and not m.is_empty(), "masteries count as active")
	_check(MasteryData.autotest_levels("none").is_empty() and MasteryData.autotest_levels("mid").is_empty() and MasteryData.autotest_levels("max").size() == MasteryData.CLASSES.size(), "--meta=max owns every mastery, none / mid none")
	# Save round trip, and the retroactive fill from found summon evolutions.
	DirAccess.make_dir_recursive_absolute(_dir)
	var p := _path("masteries.cfg")
	Meta.save_path = p
	Meta.soul_ash = 500
	GameState.autotest_meta_save = true
	_check(Meta.save() == OK, "a save with masteries writes")
	GameState.autotest_meta_save = false
	Meta.load_save()
	_check(Meta.mastery_level("warrior") == 3 and Meta.is_mastery_open("archer") and Meta.mastery_level("archer") == 0, "[masteries] / [class_lv5] round trip")
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "save_version", MetaData.SAVE_VERSION)
	cfg.set_value("recipes", "lich", true)
	cfg.set_value("recipes", "profane_bishop", true)
	cfg.set_value("masteries", "rogue", 2)
	cfg.set_value("masteries", "banshee", 99)
	cfg.save(p)
	Meta.load_save()
	_check(Meta.is_mastery_open("mage") and Meta.is_mastery_open("mender") and Meta.is_mastery_open("warder") and not Meta.is_mastery_open("warrior"), "found summon evolutions open their base classes")
	_check(Meta.mastery_level("rogue") == 2 and Meta.is_mastery_open("rogue") and Meta.mastery_level("banshee") == 3, "a bought mastery stays open; levels clamp on load")
	var old_p := _path("v2_nomasteries.cfg")
	_write_old(old_p, 2, 70, {"necrotic_marrow": 5}, false)
	Meta.save_path = old_p
	Meta.load_save()
	_check(Meta.load_status == "ok" and Meta.mastery_spent_total() == 0 and Meta.class_lv5.is_empty(), "a save without the sections loads with none")
	for f: String in ["masteries.cfg", "v2_nomasteries.cfg"]:
		DirAccess.remove_absolute(_path(f))
	Meta.save_path = Meta.DEFAULT_PATH
	# Co-op loadout: the partner's masteries travel and apply to their slot.
	var clean: Dictionary = CoopNet._clean_loadout({"mastery_levels": {"warrior": 3, "mage": 7, "nonsense": 2, "rogue": 0}}, 1)
	var ml: Dictionary = clean["mastery_levels"]
	_check(int(ml.get("warrior", 0)) == 3 and int(ml.get("mage", 0)) == 3 and not ml.has("nonsense") and not ml.has("rogue"), "the co-op loadout cleans mastery_levels")
	_check((CoopNet._clean_loadout({}, 0)["mastery_levels"] as Dictionary).is_empty(), "a loadout without masteries is clean")
	Meta._reset()
	Meta.record_class_level("gargoyle", 5)
	Meta.soul_ash = 1000
	Meta.buy_mastery("gargoyle")
	_check(int((CoopNet.make_loadout(RunConfig.new())["mastery_levels"] as Dictionary).get("gargoyle", 0)) == 1, "make_loadout() sends the bought masteries")
	Meta._reset()


## Step 6b: the recolour data, the palette remap, the purchase / save / load, the
## run config, the co-op loadout and the pre-run control.
func _check_recolours() -> void:
	# --- Data: four of the five on every skin, a luxury price, one sink total.
	var skins := SkinData.all_ids()  # Every skin of every character.
	var hyper_skin := SkinData.skins_for("gravecaller")[1]  # A Hyper skin.
	var plain_skin := SkinData.default_skin("gravecaller")  # A default skin.
	for id: String in skins:
		_check(RecolourData.ids_for(id).size() == 4, "%s offers four recolours" % id)
	_check(RecolourData.offered(hyper_skin, "verdant") and not RecolourData.offered(hyper_skin, "gilded"), "a Hyper skin offers Verdant, not Gilded")
	_check(RecolourData.offered(plain_skin, "gilded") and not RecolourData.offered(plain_skin, "verdant"), "other skins offer Gilded, not Verdant")
	var lo := 100000  # Cheapest price.
	var hi := 0  # Dearest price.
	for id: String in RecolourData.ORDER:
		lo = mini(lo, RecolourData.price(id))
		hi = maxi(hi, RecolourData.price(id))
	_check(lo >= 300 and hi <= 600, "recolours cost 300-600 each (got %d-%d)" % [lo, hi])
	_check(RecolourData.price_per_skin() == 1800, "one skin's four recolours cost 1,800 (got %d)" % RecolourData.price_per_skin())
	print("[ossuary_check] recolours: %d skins x 4 offers, %d-%d Soul Ash each, %d a skin, %d in all" % [
		skins.size(), lo, hi, RecolourData.price_per_skin(), skins.size() * RecolourData.price_per_skin()])
	# --- The remap: a colour change that keeps alpha, hue families that land where they say, greys that take the cast.
	var purple := Color8(122, 66, 173)  # The necromancer's robe purple.
	var bone_c := Recolour.color(purple, "bone")
	var blood_c := Recolour.color(purple, "blood")
	var abyss_c := Recolour.color(purple, "abyss")
	var gold_c := Recolour.color(purple, "gilded")
	_check(bone_c.s < 0.2, "Bone nearly drains the colour (s %.2f)" % bone_c.s)
	_check(blood_c.h > 0.94 or blood_c.h < 0.03, "Blood lands on red (h %.2f)" % blood_c.h)
	_check(absf(abyss_c.h - 0.52) < 0.05, "Abyss lands on teal-blue (h %.2f)" % abyss_c.h)
	_check(absf(gold_c.h - 0.115) < 0.05, "Gilded lands on gold (h %.2f)" % gold_c.h)
	_check(Recolour.color(purple, "") == purple and Recolour.color(purple, "nope") == purple, "an unknown recolour changes nothing")
	_check(is_equal_approx(Recolour.color(Color(purple, 0.4), "blood").a, 0.4), "the remap keeps alpha")
	var grey := Recolour.color(Color(0.5, 0.5, 0.5), "abyss")  # A grey gets the family's cast.
	_check(grey.s > 0.1 and absf(grey.h - 0.52) < 0.05, "a grey pixel takes Abyss's cast")
	var img := Image.create(3, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, purple)
	img.set_pixel(1, 0, Color(0, 0, 0, 0))
	img.set_pixel(2, 0, Color(0.1, 0.04, 0.13))
	var out := Recolour.image(img, "blood")
	_check(out.get_width() == 3 and out.get_height() == 1, "the remapped image keeps its size")
	_check(out.get_pixel(1, 0).a == 0.0, "a transparent pixel stays transparent")
	_check(absf(out.get_pixel(0, 0).r - blood_c.r) < 0.01 and absf(out.get_pixel(0, 0).g - blood_c.g) < 0.01, "an image pixel matches Recolour.color()")
	_check(img.get_pixel(0, 0).is_equal_approx(purple), "the source image is not edited")
	# --- A real sprite: same size, new pixels, cached (a CanvasTexture in, a CanvasTexture out).
	Recolour.clear_cache()
	var src := SpriteBank.texture("player/necromancer")  # The necromancer's grid art (may be null without art).
	if src != null:
		var rc := Recolour.texture(src, "player/necromancer", "blood")
		var raw: Texture2D = (src as CanvasTexture).diffuse_texture if src is CanvasTexture else src  # The raw pixels' texture.
		var b := raw.get_image()  # Old pixels.
		if b == null or b.is_empty():
			print("[ossuary_check] recolours: this renderer cannot read sprite pixels; the sprite remap is not checked")
		else:
			_check(rc != src and rc.get_width() == src.get_width() and rc.get_height() == src.get_height(), "a recoloured sprite keeps its size")
			_check(Recolour.texture(src, "player/necromancer", "blood") == rc, "a recoloured sprite is cached")
			_check(Recolour.texture(src, "player/necromancer", "") == src, "no recolour returns the original")
			var a := ((rc as CanvasTexture).diffuse_texture if rc is CanvasTexture else rc).get_image()  # New pixels.
			var differs := false  # Any opaque pixel changed.
			for y in b.get_height():
				for x in b.get_width():
					if b.get_pixel(x, y).a > 0.0 and a.get_pixel(x, y).to_rgba32() != b.get_pixel(x, y).to_rgba32():
						differs = true
			_check(differs, "a recoloured sprite has new colours")
	# --- Purchases: price, ownership, blocks, kept by Refund all.
	Meta._reset()
	Meta.soul_ash = 1000
	_check(Meta.recolour_block(plain_skin, "bone") == "" and Meta.recolour_block(plain_skin, "verdant") == "unknown", "bone is for sale, verdant is not offered on a plain skin")
	_check(Meta.recolour_block(hyper_skin, "bone") == "locked", "a locked Hyper skin cannot buy recolours")
	_check(Meta.buy_recolour(plain_skin, "bone") and Meta.soul_ash == 700 and Meta.owns_recolour(plain_skin, "bone"), "Bone buys for 300")
	_check(not Meta.buy_recolour(plain_skin, "bone") and Meta.soul_ash == 700 and Meta.recolour_block(plain_skin, "bone") == "owned", "an owned recolour is not bought twice")
	_check(Meta.buy_recolour(plain_skin, "blood") and Meta.soul_ash == 300, "Blood buys for 400")
	_check(Meta.recolour_block(plain_skin, "abyss") == "cost" and not Meta.buy_recolour(plain_skin, "abyss") and Meta.soul_ash == 300, "Abyss (500) is refused with 300")
	_check(not Meta.owns_recolour(plain_skin, "abyss") and not Meta.owns_recolour(SkinData.default_skin("bone_oracle"), "bone"), "ownership is per skin")
	_check(Meta.recolour_spent_total() == 700, "700 Soul Ash spent on recolours")
	Meta.set_chosen_recolour(plain_skin, "blood")
	_check(Meta.chosen_recolour(plain_skin) == "blood", "the choice is remembered")
	Meta.set_chosen_recolour(plain_skin, "abyss")
	_check(Meta.chosen_recolour(plain_skin) == "blood", "an unowned recolour cannot be chosen")
	Meta.tiers["necrotic_marrow"] = 2
	var ash_before := Meta.soul_ash
	Meta.refund_all()
	_check(Meta.owns_recolour(plain_skin, "bone") and Meta.soul_ash == ash_before + MetaData.cost_up_to("necrotic_marrow", 2), "Refund all does not return recolours")
	# --- Save / load: the [recolours] and [recolour_pick] sections, junk ignored, an old save owns nothing.
	var p := _path("recolours.cfg")
	DirAccess.make_dir_recursive_absolute(_dir)
	Meta.save_path = p
	GameState.autotest_meta_save = true  # Lets save() write (to the temp path only).
	_check(Meta.save() == OK, "a save with recolours writes")
	var cfg_old := ConfigFile.new()  # Add junk beside the real keys.
	cfg_old.load(p)
	cfg_old.set_value("recolours", "no_such_skin", "bone")
	cfg_old.set_value("recolours", SkinData.default_skin("bone_oracle"), "bone,gilded,mystery,verdant,bone")
	cfg_old.set_value("recolour_pick", SkinData.default_skin("bone_oracle"), "abyss")
	cfg_old.save(p)
	GameState.autotest_meta_save = false
	Meta.load_save()
	_check(Meta.load_status == "ok", "a save with recolours loads as current (got %s)" % Meta.load_status)
	_check(Meta.owns_recolour(plain_skin, "bone") and Meta.owns_recolour(plain_skin, "blood") and Meta.chosen_recolour(plain_skin) == "blood", "recolours round trip")
	var bo := SkinData.default_skin("bone_oracle")  # The junk-edited skin.
	_check(Meta.owns_recolour(bo, "bone") and Meta.owns_recolour(bo, "gilded") and not Meta.owns_recolour(bo, "verdant"), "unknown / unoffered recolour ids are ignored on load")
	_check(Meta.owned_recolour_ids(bo).size() == 2 and Meta.chosen_recolour(bo) == "", "a pick that is not owned is dropped; duplicates collapse")
	var p2 := _path("recolours_old.cfg")
	_write_old(p2, 2, 40, {"necrotic_marrow": 3}, false)
	Meta.save_path = p2
	Meta.load_save()
	_check(Meta.owned_recolours.is_empty() and Meta.chosen_recolours.is_empty() and Meta.tier("necrotic_marrow") == 3, "an older save owns no recolours and keeps its tiers")
	DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(p2)
	Meta.save_path = Meta.DEFAULT_PATH
	# --- The run config: the saved choice reaches the next run, only an owned one.
	Meta._reset()
	Meta.owned_recolours[plain_skin] = PackedStringArray(["blood"])
	Meta.chosen_recolours[plain_skin] = "blood"
	var cfg := Meta.prerun_config(StageRegistry.DEFAULT_ID)
	_check(cfg.skin_id == plain_skin and cfg.recolour_id == "blood", "prerun_config() carries the chosen recolour")
	_check(cfg.duplicate_config().recolour_id == "blood", "Restart keeps the recolour")
	cfg.recolour_id = "bone"  # Not owned.
	Meta.remember_prerun(cfg)
	_check(Meta.chosen_recolour(plain_skin) == "", "remember_prerun() never stores an unowned recolour")
	# --- Co-op: the pick travels in the loadout and is cosmetic (nothing else reads it).
	var cfg2 := RunConfig.for_stage(StageRegistry.DEFAULT_ID)
	cfg2.recolour_id = "blood"
	var lod := CoopNet.make_loadout(cfg2)
	_check(String(lod.get("recolour_id", "")) == "blood", "the loadout carries the recolour")
	_check(String(CoopNet._clean_loadout(lod, 1).get("recolour_id", "")) == "blood" and String(CoopNet._clean_loadout({}, 1).get("recolour_id", "x")) == "", "the cleaned loadout keeps / defaults it")
	_check(CoopNet.run_config_for({"loadouts": [lod, lod]}, 1).recolour_id == "blood", "the partner's config has the recolour")
	# --- The pre-run control: cycle, preview an unowned one, buy it (no dialog under the autotest).
	Meta._reset()
	Meta.soul_ash = 450
	var row := PreRunHyperSkins.new()
	row.config = RunConfig.for_stage(StageRegistry.DEFAULT_ID)
	add_child(row)
	_check(row._rc_box.visible and not row._rc_buy.visible and row.shown_recolour() == "", "the control shows on an unlocked skin, no Buy at first")
	row._cycle_recolour()
	_check(row.shown_recolour() == "bone" and row._rc_buy.visible and row.config.recolour_id == "", "cycling onto an unowned recolour previews it with a Buy button and does not wear it")
	row._press_buy()
	_check(Meta.owns_recolour(plain_skin, "bone") and row.config.recolour_id == "bone" and not row._rc_buy.visible and Meta.soul_ash == 150, "Buy wears it and spends 300")
	row._cycle_recolour()  # Blood: 400, too dear with 150.
	_check(row.shown_recolour() == "blood" and row._rc_buy.visible and row.config.recolour_id == "", "Blood is previewed, not worn")
	row._press_buy()
	_check(not Meta.owns_recolour(plain_skin, "blood") and Meta.soul_ash == 150, "Blood is refused with 150 Soul Ash")
	for i in 4:
		row._cycle_recolour()  # Abyss, Gilded, Default, Bone.
	_check(row.shown_recolour() == "bone" and row.config.recolour_id == "bone", "five presses go round to the owned Bone")
	row.preview_recolour("")
	_check(row.config.recolour_id == "" and Meta.chosen_recolour(plain_skin) == "", "Default takes the recolour off")
	row.queue_free()
	Meta._reset()


# --- Screenshot mode ---------------------------------------------------------------------

func _screenshot() -> void:
	var win := get_window()
	if _phone:
		win.size = Vector2i(1688, 780)  # 844 x 390 CSS px at 2x (a landscape phone).
		win.content_scale_factor = TouchData.UI_SCALE_MAX  # The mobile UI scale there (TouchSupport.ui_scale()).
	else:
		win.size = Vector2i(1280, 720)
	Meta._reset()
	Meta.soul_ash = 2480
	var sample := {"necrotic_marrow": 7, "sharpened_bones": 5, "grave_call": 3, "risen_vanguard": 2,
		"umbral_potency": 6, "quickened_rites": 4, "widening_dark": 2, "restless_shade": 3,
		"grave_flesh": 5, "bone_mail": 4, "fleet_shade": 3, "undying_will": 1,
		"soul_magnet": 4, "grave_tithe": 3, "ash_harvest": 2, "fates_thread": 1, "profane_oath": 2,
		"bone_reserve": 2, "dark_tithe": 1, "last_rites": 3, "elite_bounty": 1, "head_start": 1}
	for id: String in sample:
		Meta.tiers[id] = mini(int(sample[id]), maxi(_open, MetaData.UNGATED_MAX_TIER))  # Never above the sample's open level.
	Meta.oath_active = 2
	if _sealed:
		Meta.tiers["head_start"] = 0  # Dominion still sealed (no Seraphine kill).
	else:
		(Meta.stage_records["sanctum"] as Dictionary)["boss_kills"] = 1.0  # Seraphine slain: Dominion open.
	match _open:
		7:
			Meta._record_clear(_win("lich", false))
		9:
			Meta._record_clear(_win("deathlord", false))
		10:
			Meta._record_clear(_win("deathlord", true))
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()  # The main menu is not behind it here: a plain dark ground.
	bg.color = Color(0.05, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	add_child(holder)
	if _tab == "masteries":
		await _screenshot_masteries(holder)
		return
	var menu := OssuaryMenu.open_over(holder, null)
	for i in 30:
		await get_tree().process_frame
	menu._show_detail("necrotic_marrow")  # A gated tile in the detail panel (Lich open: level 8 waits on Deathlord).
	if _open == 5:
		menu._show_detail("sharpened_bones")
	if _detail != "" and MetaData.UPGRADES.has(_detail):
		menu._show_detail(_detail)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
	var err := img.save_png(_shot)
	print("[ossuary_check] shot %s (%dx%d): %s" % [_shot, img.get_width(), img.get_height(), error_string(err)])
	Meta._reset()
	get_tree().quit(0 if err == OK else 1)


## Screenshot of the Masteries panel over a sample save (a stand-in header with the
## balance: the tab bar is not part of this check). The sample has some classes
## taken to Lv 5, a few masteries bought, one maxed and the rest locked.
func _screenshot_masteries(holder: Control) -> void:
	Meta._reset()
	Meta.soul_ash = 640
	for cls: String in ["warrior", "archer", "mage", "mender", "warder", "abomination", "rogue", "gargoyle", "frost_wraith", "bone_hound", "corpse_catapult", "bone_golem"]:
		Meta.class_lv5[cls] = true
	Meta.mastery_levels = {"warrior": 3, "archer": 2, "mage": 1, "mender": 1, "abomination": 2}
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)
	TouchSupport.fit_to_screen(center)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", OssuaryUiData.BLOCK_GAP)
	center.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title := UiTheme.tier_label(MasteryUiData.TAB_TITLE, UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(IconGlyph.new("soul_ash", Vector2(OssuaryUiData.BALANCE_ICON, OssuaryUiData.BALANCE_ICON)))
	head.add_child(UiTheme.tier_label(str(Meta.soul_ash), UiTheme.Tier.HEADER, OssuaryUiData.ASH_COLOR))
	root.add_child(head)
	var panel := OssuaryMasteriesPanel.new()
	root.add_child(panel)
	for i in 30:
		await get_tree().process_frame
	(panel.tiles["mender"] as Control).grab_focus()
	var pick := "mage" if _open == 7 else "spawn_of_the_deep"  # --open=5: a locked class in the detail strip.
	panel._show_detail(pick)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
	var err := img.save_png(_shot)
	print("[ossuary_check] shot %s (%dx%d): %s" % [_shot, img.get_width(), img.get_height(), error_string(err)])
	Meta._reset()
	get_tree().quit(0 if err == OK else 1)


# --- Recolours (Ossuary expansion step 6b) ---------------------------------------------------

## Screenshot of the pre-run setup screen over a sample save (see `_shot_prerun`).
func _screenshot_prerun() -> void:
	var win := get_window()
	if _phone:
		win.size = Vector2i(1688, 780)  # 844 x 390 CSS px at 2x (a landscape phone).
		win.content_scale_factor = TouchData.UI_SCALE_MAX
	else:
		win.size = Vector2i(1280, 720)
	Meta._reset()
	Meta.soul_ash = 2480
	Meta.achievements["bone_legion"] = true  # Opens the Ivory Seer (bone_oracle).
	Meta.hyper_unlocked = true
	Meta.hyper_clears["%s-%s" % [HyperData.SKIN_STAGE_ID, _shot_char]] = true  # Opens the Hyper skin.
	Meta.spell_max_levels[String(CharacterData.CHARACTERS[_shot_char]["spell"])] = 5  # Unlocks the character.
	var skin := _shot_skin if _shot_skin != "" else SkinData.default_skin(_shot_char)  # Skin worn.
	if _shot_rc != "" and not _shot_buy:
		Meta.owned_recolours[skin] = PackedStringArray([_shot_rc, "blood"] if _shot_rc != "blood" else ["blood"])
	var cfg := RunConfig.for_stage(StageRegistry.DEFAULT_ID)
	cfg.set_character(_shot_char)
	cfg.skin_id = "" if _shot_skin == "" else _shot_skin
	cfg.recolour_id = _shot_rc if not _shot_buy else ""
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	add_child(holder)
	var setup := PreRunSetup.open_over(holder, null, cfg)
	for i in 30:
		await get_tree().process_frame
	if _shot_buy and setup._extras != null:
		setup._extras.preview_recolour(_shot_rc)  # The unowned offer, previewed.
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot_prerun.get_base_dir())
	var err := img.save_png(_shot_prerun)
	print("[ossuary_check] shot %s (%dx%d): %s" % [_shot_prerun, img.get_width(), img.get_height(), error_string(err)])
	Meta._reset()
	get_tree().quit(0 if err == OK else 1)
