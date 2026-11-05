## Demo mode check (GDD §15.0 "Demo mode (owner request, Nov 2026)"): a
## unit-style regression for DemoMode's gates, run headless twice, with and
## without the demo switch:
##   godot --headless res://tools/demo_check.tscn -- --autotest --demo
##   godot --headless res://tools/demo_check.tscn -- --autotest
## It fills Meta IN MEMORY with a "finished everything" profile (every stage
## boss slain, every UnlockData item unlocked, every spell at Lv 5; as if a
## full-game save code had been restored into the demo) and checks that in the
## demo only the demo's acts open, only demo items are offerable / unlocked,
## full-game characters stay locked and read "Full game", the save file and
## the co-op version carry the demo suffixes, and the stage select's lock text
## says "Full game"; without --demo, that everything is open and unchanged.
## Nothing is ever written (the autotest's Meta.can_write() is false) and the
## Meta state is reset afterwards. Prints "[demo_check] PASS" or the failed
## checks (exit 1). tools/.gdignore keeps it out of exports.
extends Node

## Failed checks (any failure exits 1).
var _failures: int = 0
## Checks run.
var _checks: int = 0


func _ready() -> void:
	var demo := DemoMode.on()  # Which half of the check runs.
	print("[demo_check] demo mode: %s" % str(demo))
	_fill_everything()
	_check_stages(demo)
	_check_items(demo)
	_check_characters(demo)
	_check_saves_and_coop(demo)
	Meta._reset()
	if _failures == 0:
		print("[demo_check] PASS (%d checks)" % _checks)
	else:
		print("[demo_check] FAIL: %d of %d checks" % [_failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


## Meta in memory: every boss slain on every stage, every lockable item
## unlocked, every spell taken to Lv 5.
func _fill_everything() -> void:
	for id: String in StageRegistry.ORDER:
		var rec := Meta.stage_record(id).duplicate()
		rec["boss_kills"] = 9.0
		rec["victories"] = 9.0
		Meta.stage_records[id] = rec
	for id: String in UnlockData.UNLOCKS:
		Meta.unlocked_items[id] = true
	for id: String in AbilityData.SPELLS:
		Meta.spell_max_levels[id] = 5


## One check: counts it, prints a failure.
func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		print("[demo_check] FAILED: %s" % what)


## Stages: the demo opens only its acts; the full game opens every playable one.
func _check_stages(demo: bool) -> void:
	var open := PackedStringArray()  # Stages the stage select would let the player choose.
	for id: String in StageRegistry.ORDER:
		var in_demo := DemoData.ACTS.has(StageRegistry.act_of(id))  # Expected open in the demo.
		var unlocked := StageSelect._is_open(id)
		if unlocked:
			open.append(id)
		_expect(unlocked == (in_demo or not demo), "stage %s open=%s (act %d)" % [id, str(unlocked), StageRegistry.act_of(id)])
		var lock := StageSelect._lock_text(StageRegistry.STAGES[id])
		if demo and not in_demo:
			_expect(lock == DemoData.LOCK_LINE, "stage %s lock text '%s'" % [id, lock])
		elif not demo:
			_expect(lock != DemoData.LOCK_LINE, "full game: stage %s reads the demo lock line" % id)
	print("[demo_check] stages open: %d (%s)" % [open.size(), ",".join(open) if open.size() <= 6 else ",".join(open.slice(0, 6)) + ",..."])
	_expect(DemoMode.demo_stages() == PackedStringArray(["graveyard", "crimson_march", "sanctum"]), "demo stages %s" % ",".join(DemoMode.demo_stages()))
	_expect(DemoMode.acts_left_out() == StageRegistry.ACTS.size() - DemoData.ACTS.size(), "acts left out %d" % DemoMode.acts_left_out())


## Items: the card pool on every demo stage offers no full-game item; no demo
## run unlocks one; their lock text reads "Full game".
func _check_items(demo: bool) -> void:
	var offered := 0  # Lockable items offerable on an Act I stage.
	for id: String in UnlockData.UNLOCKS:
		var ok_item := DemoData.OPEN_ITEMS.has(id)  # A demo item.
		for sid: String in ["graveyard", "crimson_march", "sanctum"]:
			var off := Unlocks.offerable(id, StageRegistry.STAGES[sid])
			var off_coop := Unlocks.offerable_with(id, StageRegistry.STAGES[sid], Meta.unlocked_items)
			if off:
				offered += 1
			if demo and not ok_item:
				_expect(not off and not off_coop, "full-game item %s offerable on %s" % [id, sid])
		_expect(Unlocks.is_open(id) == (ok_item or not demo), "item %s open=%s" % [id, str(Unlocks.is_open(id))])
		if demo and not ok_item:
			_expect(Unlocks.lock_text(id) == DemoData.LOCK_LINE, "item %s lock text" % id)
	for id: String in DemoData.OPEN_ITEMS:
		_expect(UnlockData.UNLOCKS.has(id), "DemoData.OPEN_ITEMS id %s is not an UnlockData row" % id)
	var all_bosses := {}  # Every boss id, slain at once.
	var got := PackedStringArray()  # Items a run slaying any boss / earning every achievement would unlock.
	var ach := {}
	for a: String in MetaData.ACHIEVEMENT_ORDER:
		ach[a] = true
	for bid: String in StageRegistry.BOSS_ARRIVALS:
		all_bosses[bid] = true
		got.append_array(Unlocks.newly_unlocked(bid, ach, {}))
	var bad := 0  # Full-game items among them.
	for id: String in got:
		if not DemoMode.item_in_demo(id):
			bad += 1
	if demo:
		_expect(bad == 0, "a demo run could unlock %d full-game items" % bad)
	else:
		_expect(bad > 0, "full game: later items unlock as before")
	print("[demo_check] lockable items offerable on Act I stages: %d (row x stage) | full-game unlocks reachable: %d" % [offered, bad])


## Characters: a character of a full-game spell stays locked in the demo.
func _check_characters(demo: bool) -> void:
	var locked := 0  # Characters locked with every spell at Lv 5.
	for cid: String in CharacterModifiers.available_ids():
		var spell := String(CharacterData.CHARACTERS[cid]["spell"])
		var want := not demo or DemoMode.item_in_demo(spell)  # Expected unlocked.
		_expect(Meta.is_character_unlocked(cid) == want, "character %s unlocked=%s" % [cid, str(Meta.is_character_unlocked(cid))])
		if not want:
			locked += 1
			_expect(CharacterModifiers.unlock_text(cid) == DemoData.LOCK_LINE, "character %s lock text" % cid)
	print("[demo_check] characters locked as full game: %d" % locked)


## Saves and co-op: the demo's own save file and co-op version.
func _check_saves_and_coop(demo: bool) -> void:
	var want_path := "user://save_demo.cfg" if demo else Meta.DEFAULT_PATH  # Meta's file.
	_expect(Meta.save_path == want_path, "save path %s" % Meta.save_path)
	_expect(CoopNet.game_version().ends_with(DemoData.COOP_VERSION_SUFFIX) == demo, "co-op version %s" % CoopNet.game_version())
	print("[demo_check] save: %s | co-op version: %s" % [Meta.save_path, CoopNet.game_version()])
	_expect(DemoMode.store_enabled() == (demo and DemoData.STORE_URL != ""), "Wishlist button shown")
	var b := DemoMode.store_button()  # Built (not shown) to check its wiring: one word, never opens headless.
	_expect(b.text == DemoData.CTA_BUTTON and not FeedbackReport.open_link(DemoData.STORE_URL), "Wishlist button")
	b.free()
	_expect(not FeedbackReport.link_allowed("https://example.invalid/"), "no link opens under the autotest")
