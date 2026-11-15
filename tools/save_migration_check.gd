## Act order and save migration check (GDD §15.0 "The reorder pass, part 1 (order
## and numbering)"): a unit-style regression for StageRegistry's one ordered act
## list (every stage in it once, act numbers / Parts / chapters / Soul Ash and
## the unlock chain derived from it, the owner's chain links) and for the
## version-3 save migration (SaveMigration.legacy_opened(), Meta [stages]
## opened): a version-2 save written under the OLD act order with every boss up
## to Act IX's Harvester slain is migrated, and every stage it had opened must
## stay open, every record keep its stage id, and a save / load round trip keep
## both. It also checks that act-scoped rows (PassiveData "act",
## VictoryData.ACT_LINES, the Codex act tabs, DemoData.ACTS) name real act ids.
## It never touches the real save: Meta.save_path points at temp files in
## --check-dir (default user://save_migration_check/, removed afterwards) and Meta
## is reset when it ends. Run headless:
##   godot --headless res://tools/save_migration_check.tscn -- --autotest [--check-dir=DIR]
## Prints "[save_migration_check] PASS (N checks)" or the failed checks (exit 1).
## tools/.gdignore keeps it out of exports.
extends Node

## Failed checks (any failure exits 1).
var _failures: int = 0
## Checks run.
var _checks: int = 0
## Directory of the temp save files.
var _dir: String = "user://save_migration_check"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--check-dir="):
			_dir = a.trim_prefix("--check-dir=")
	if not GameState.autotest:
		push_error("save_migration_check requires --autotest (the real save is never read).")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_dir)
	_check_order()
	_check_act_rows()
	_check_migration()
	_check_fresh_chain()
	_check_no_stage_records()
	Meta._reset()
	Meta.save_path = Meta.DEFAULT_PATH
	if _failures == 0:
		print("[save_migration_check] PASS (%d checks)" % _checks)
	else:
		print("[save_migration_check] FAIL: %d of %d checks" % [_failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## One check: counts it, prints a failure.
func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		print("[save_migration_check] FAILED: %s" % what)


## Path of temp file `f` in the check directory.
func _path(f: String) -> String:
	return _dir.path_join(f)


## The ordered act list: 15 acts of 3 stages, 3 Parts of 5, every registered
## stage exactly once, the derived numbers, and the owner's chain links.
func _check_order() -> void:
	_expect(StageRegistry.act_count() == 15, "15 acts (%d)" % StageRegistry.act_count())
	_expect(StageRegistry.ORDER.size() == StageRegistry.STAGES.size(), "ORDER holds every stage (%d vs %d)" % [StageRegistry.ORDER.size(), StageRegistry.STAGES.size()])
	_expect(StageRegistry.PARTS.size() * StageRegistry.ACTS_PER_PART == StageRegistry.act_count(), "3 Parts of 5 acts")
	var seen := {}  # Stage ids met in ORDER.
	for i in StageRegistry.ORDER.size():
		var id := StageRegistry.ORDER[i]
		_expect(StageRegistry.STAGES.has(id) and not seen.has(id), "stage %s registered once" % id)
		seen[id] = true
		_expect(String(StageRegistry.STAGES[id]["id"]) == id, "stage %s id key" % id)
		_expect(StageRegistry.act_of(id) == i / 3 + 1, "stage %s act %d" % [id, StageRegistry.act_of(id)])
		_expect(StageRegistry.chapter_of(id) == "Chapter %s" % StageRegistry.roman(i + 1), "stage %s %s" % [id, StageRegistry.chapter_of(id)])
		_expect(is_equal_approx(StageRegistry.ash_mult_of(id), [1.0, 1.25, 1.5][i % 3]), "stage %s Soul Ash x%.2f" % [id, StageRegistry.ash_mult_of(id)])
		_expect(StageRegistry.unlock_of(id) == ("" if i == 0 else StageRegistry.ORDER[i - 1]), "stage %s unlock" % id)
	# The owner's final order and chain (each act's first stage after the last act's finale).
	var links := {"cutter": "sanctum", "ravensmoor": "maelstrom", "skid_row": "castle_sanguis", "province": "liberty_heights",
		"barrow_fields": "sun_road", "necropolis": "vigrid", "ilion": "two_truths", "burning_gate": "underworld",
		"silver_stair": "pandemonium", "harbour": "empyrean", "wastes": "spire", "crash_site": "citadel",
		"fern_basin": "ark", "greenwood": "last_day"}  # New first stage -> the finale whose boss opens it.
	for id: String in links:
		_expect(StageRegistry.unlock_of(id) == String(links[id]), "%s opens after %s (got %s)" % [id, links[id], StageRegistry.unlock_of(id)])
	var numbers := {"covenant": 1, "corsair": 2, "court": 3, "city": 4, "shogunate": 5, "norse": 6, "dynasty": 7, "pantheon": 8,
		"inferno": 9, "host": 10, "eye": 11, "empire": 12, "concord": 13, "primeval": 14, "wild": 15}  # Act id -> final act number.
	for aid: String in numbers:
		_expect(StageRegistry.act_number(aid) == int(numbers[aid]), "act %s is Act %s" % [aid, StageRegistry.roman(int(numbers[aid]))])
	_expect(StageRegistry.part_of_act(5) == 0 and StageRegistry.part_of_act(10) == 1 and StageRegistry.part_of_act(11) == 2, "the Host ends Part Two")
	_expect(StageRegistry.act_name(14) == "Act XIV", "act names in Roman numerals")


## Act-scoped rows name real act ids (by id, never by number).
func _check_act_rows() -> void:
	for id: String in PassiveData.PASSIVES:
		var row: Dictionary = PassiveData.PASSIVES[id]
		if row.has("act"):
			_expect(typeof(row["act"]) == TYPE_STRING and StageRegistry.act_number(String(row["act"])) > 0, "passive %s act %s" % [id, str(row["act"])])
	for aid: Variant in VictoryData.ACT_LINES:
		_expect(StageRegistry.act_number(String(aid)) > 0, "victory line act %s" % str(aid))
	_expect(VictoryData.ACT_LINES.size() == StageRegistry.act_count(), "a victory line per act")
	_expect(CodexData.tabs().size() == CodexData.FIXED_TABS.size() + StageRegistry.act_count(), "a Codex tab per act")
	for aid: String in DemoData.ACTS:
		_expect(StageRegistry.act_number(aid) > 0, "demo act %s" % aid)
	# A counter-passive keeps its act: Iron Mind (the Ancient Eye's) is offered on the Harbour, not on the Cutter.
	_expect(Unlocks.act_allows("iron_mind", StageRegistry.STAGES["harbour"]), "Iron Mind allowed on the Ancient Eye's stages")
	_expect(not Unlocks.act_allows("iron_mind", StageRegistry.STAGES["cutter"]), "Iron Mind not offered in the Black Tide")


## A version-2 save under the old order with every boss slain up to the
## Harvester (old Acts I-IX, stages 1-27): every stage it had opened (those 27
## and the Cutter) stays open; records keep their ids; a round trip keeps both.
func _check_migration() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "save_version", 2)
	cfg.set_value("currency", "soul_ash", 777)
	var legacy := SaveMigration.LEGACY_ORDER  # The old campaign order.
	for i in legacy.size():
		var id := legacy[i]
		cfg.set_value("stages", "%s_runs" % id, float(100 + i) if i < 27 else 0.0)
		cfg.set_value("stages", "%s_boss_kills" % id, 1.0 if i < 27 else 0.0)
		cfg.set_value("stages", "%s_best_time" % id, float(1200 + i) if i < 27 else 0.0)
	var p := _path("v2_act9.cfg")
	cfg.save(p)
	Meta.save_path = p
	Meta.load_save()
	_expect(Meta.load_status == "migrated", "the version-2 save migrates (got %s)" % Meta.load_status)
	_expect(Meta.soul_ash == 777, "Soul Ash kept (%d)" % Meta.soul_ash)
	var was_open := legacy.slice(0, 28)  # Old stages 1-27 and the Cutter (opened by the Harvester).
	for id: String in was_open:
		_expect(Meta.is_stage_unlocked(id), "stage %s stays open" % id)
	for i in 27:
		var rec := Meta.stage_record(legacy[i])
		_expect(int(float(rec["runs"])) == 100 + i and int(float(rec["best_time"])) == 1200 + i, "record of %s kept" % legacy[i])
	_expect(Meta.is_stage_unlocked("galleon") == false, "the Galleon still waits on Captain Crow")
	_expect(Meta.is_stage_unlocked("barrow_fields"), "the new chain opens Barrow Fields (the sun was put out)")
	_expect(not Meta.is_stage_unlocked("valgard"), "Valgard still waits on Hrimgar")
	# Round trip: save the migrated profile (version 3) and load it again.
	GameState.autotest_meta_save = true  # Lets save() write (to the temp path only).
	_expect(Meta.save() == OK, "the migrated save writes")
	GameState.autotest_meta_save = false
	Meta.load_save()
	_expect(Meta.load_status == "ok", "the rewritten save loads as current (got %s)" % Meta.load_status)
	for id: String in was_open:
		_expect(Meta.is_stage_unlocked(id), "stage %s open after the round trip" % id)
	_expect(int(float(Meta.stage_record("ark")["runs"])) == 126, "records after the round trip")
	DirAccess.remove_absolute(p)


## A fresh profile follows the new chain only: Seraphine opens the Cutter, not
## Gullhaven Harbour.
func _check_fresh_chain() -> void:
	Meta._reset()
	_expect(Meta.is_stage_unlocked("graveyard") and not Meta.is_stage_unlocked("crimson_march"), "fresh: only the Graveyard")
	for id: String in ["graveyard", "crimson_march", "sanctum"]:
		var rec := Meta.stage_record(id).duplicate()
		rec["boss_kills"] = 1.0
		Meta.stage_records[id] = rec
	_expect(Meta.is_stage_unlocked("cutter"), "Seraphine opens the Smuggler's Cutter")
	_expect(not Meta.is_stage_unlocked("harbour"), "Seraphine no longer opens Gullhaven Harbour")


## A save from before [stages] existed (no records, lifetime boss kills): the
## Crimson March stays open and the Graveyard record is rebuilt.
func _check_no_stage_records() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("lifetime", "runs", 9.0)
	cfg.set_value("lifetime", "boss_kills", 2.0)
	var p := _path("v0_nostages.cfg")
	cfg.save(p)
	Meta.save_path = p
	Meta.load_save()
	_expect(Meta.is_stage_unlocked("crimson_march"), "an old Alaric kill keeps the Crimson March open")
	_expect(int(float(Meta.stage_record("graveyard")["runs"])) == 9, "the Graveyard record rebuilt from the lifetime stats")
	DirAccess.remove_absolute(p)
