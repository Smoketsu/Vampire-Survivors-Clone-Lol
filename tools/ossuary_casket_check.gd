## ossuary_casket_check.gd (preloaded by ossuary_check.gd: tools/ has a .gdignore,
## so no class_name) — the Recolour Caskets part of tools/ossuary_check (owner
## request, Oct 2026, GDD §15.0 "Recolour Caskets (owner request, Oct 2026)"):
## checks the data (tiers, weights, price), the prize pool (unlocked skins only, no
## owned prize, shrinking by one per opening, never a duplicate over the whole
## pool), the roll (deterministic per seed and opening count, the weights, tier
## fallback when a tier is empty, the pity casket on the 10th), the blocks (an
## empty pool or too little Soul Ash opens nothing and charges nothing), the save
## (round trip of [caskets], an older save without it, recolours an older save
## bought), Refund all (never returns caskets), a casket-only skin row injected
## through CasketLedger.pool_from() (locked before, unlocked and its recolours in
## the pool after being won) and the tab panel (open, reveal settled at once under
## the autotest, Wear, the empty pool disabling Open). Called from
## ossuary_check.gd's _run(); it uses the same temp save directory and never the
## real save. The screenshot helper open_shot() (--shot-what=caskets |
## casket_mid | casket_epic) lives here too (drawing only).
## tools/.gdignore keeps it out of exports.

extends RefCounted

## The ossuary_check node (its _check() counts failures; its _path() names temp files).
var host: Node


func _init(p_host: Node) -> void:
	host = p_host


## Runs every casket check.
func run() -> void:
	_check_data()
	_check_roll()
	_check_open_all()
	_check_blocks()
	_check_pity_in_play()
	_check_casket_skin()
	_check_save()
	_check_panel()
	Meta._reset()


func _check(ok: bool, what: String) -> void:
	host.call("_check", ok, "caskets: " + what)


## A prize as one "skin|recolour" string (order-independent comparisons).
static func _key(p: Dictionary) -> String:
	return "%s|%s" % [String(p.get("skin", "")), String(p.get("recolour", ""))]


# --- Data ---------------------------------------------------------------------------

func _check_data() -> void:
	_check(CasketData.PRICE == 350, "a casket costs 350 Soul Ash")
	_check(CasketData.TIER_ORDER == ["common", "rare", "epic", "legendary"], "four tiers, lowest first")
	var w := []  # Weights in order.
	for t: String in CasketData.TIER_ORDER:
		w.append(int(CasketData.TIERS[t]["weight"]))
	_check(w == [60, 30, 10, 3], "weights 60 / 30 / 10 / 3 (got %s)" % str(w))
	_check(CasketLedger.recolour_tier("bone") == "common" and CasketLedger.recolour_tier("blood") == "rare" and CasketLedger.recolour_tier("abyss") == "rare"
			and CasketLedger.recolour_tier("gilded") == "epic" and CasketLedger.recolour_tier("verdant") == "epic", "Bone common, Blood / Abyss rare, Gilded / Verdant epic")
	_check(CasketData.CASKET_SKIN_TIER == "legendary" and CasketData.PITY_AFTER == 9 and CasketData.PITY_TIER == "epic", "casket skins legendary, pity after 9 at Epic")
	_check(SkinData.CASKET_SKINS.is_empty(), "no casket-only skin ships yet (no art)")
	_check(OssuaryUiData.TABS.back() == "caskets" and OssuaryUiData.TAB_NAMES.get("caskets", "") == "Caskets" and ResourceLoader.exists(String(OssuaryUiData.TAB_PANELS["caskets"])), "Caskets is the Ossuary's last tab")
	_check(CasketUiData.REVEAL_TIME <= 1.5, "the reveal takes at most 1.5 s (%.2f)" % CasketUiData.REVEAL_TIME)


# --- The roll -----------------------------------------------------------------------

## A hand-made pool: `n` prizes of each tier in `tiers`.
static func _pool(tiers: Array, n: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Variant in tiers:
		for i in n:
			out.append({"skin": "s%d" % i, "recolour": String(t), "tier": String(t)})
	return out


func _check_roll() -> void:
	var rng := RandomNumberGenerator.new()
	# Weights: 60 / 30 / 10 over a full pool without legendary prizes.
	rng.seed = 12345
	var full := _pool(["common", "rare", "epic"], 4)  # 12 prizes.
	var counts := {"common": 0, "rare": 0, "epic": 0}
	for i in 10000:
		var p := CasketLedger.roll(full, rng, 0)
		counts[String(p["tier"])] += 1
	_check(absi(int(counts["common"]) - 6000) < 300 and absi(int(counts["rare"]) - 3000) < 300 and absi(int(counts["epic"]) - 1000) < 200,
			"10,000 rolls land near 60 / 30 / 10 (got %s)" % str(counts))
	var odds := CasketLedger.odds(full)
	_check(is_equal_approx(float(odds["common"]), 0.6) and not odds.has("legendary"), "odds: an empty tier (Legendary) is left out")
	var with_leg := full.duplicate()
	with_leg.append({"skin": "x", "recolour": "", "tier": "legendary"})
	_check(is_equal_approx(float(CasketLedger.odds(with_leg)["legendary"]), 3.0 / 103.0), "Legendary counts (3 / 103) while a legendary prize exists")
	# Tier fallback: an empty tier is never rolled; the rest renormalise.
	var two := _pool(["rare", "epic"], 3)
	_check(is_equal_approx(float(CasketLedger.odds(two)["rare"]), 0.75), "rare + epic only: rare 75%")
	var only_common := _pool(["common"], 2)
	var ok := true  # Every roll stays common.
	for i in 200:
		ok = ok and String(CasketLedger.roll(only_common, rng, 0)["tier"]) == "common"
	_check(ok, "a pool of commons always rolls common")
	var only_epic := _pool(["epic"], 2)
	ok = true
	for i in 200:
		ok = ok and String(CasketLedger.roll(only_epic, rng, 0)["tier"]) == "epic"
	_check(ok, "a pool of epics always rolls epic (the empty tiers fall through)")
	_check(CasketLedger.roll([], rng, 0).is_empty(), "an empty pool rolls nothing")
	# Pity: at 9 misses the roll is the best non-empty tier at Epic or above.
	ok = true
	for i in 200:
		ok = ok and String(CasketLedger.roll(full, rng, CasketData.PITY_AFTER)["tier"]) == "epic"
	_check(ok, "the pity roll (since 9) is always Epic")
	ok = true
	for i in 200:
		ok = ok and String(CasketLedger.roll(with_leg, rng, CasketData.PITY_AFTER)["tier"]) == "legendary"
	_check(ok, "the pity roll takes Legendary when one exists (the best tier at Epic or above)")
	var low := _pool(["common", "rare"], 3)
	var any_low := true  # The pity roll on a pool without Epic+ is an ordinary roll.
	for i in 200:
		any_low = any_low and ["common", "rare"].has(String(CasketLedger.roll(low, rng, CasketData.PITY_AFTER)["tier"]))
	_check(any_low and not CasketLedger.has_pity_prize(low), "no Epic or better left: the pity cannot fire, the roll stays ordinary")
	# Determinism per (seed, count).
	var led := CasketLedger.new()
	led.casket_seed = 99
	_check(led.rng_for(3).randf() == led.rng_for(3).randf() and led.rng_for(3).randf() != led.rng_for(4).randf(), "each opening's generator depends only on (seed, count)")


# --- Opening the whole pool -----------------------------------------------------------

## Opens every casket of a fresh profile with seed `seed`; returns the prize keys in order.
func _open_everything(seed_value: int) -> PackedStringArray:
	Meta._reset()
	Meta.caskets.casket_seed = seed_value
	var start := Meta.caskets.prize_pool().size()  # Prizes at the start.
	Meta.soul_ash = CasketData.PRICE * start + 100
	var keys := PackedStringArray()
	var shrinks := true  # The pool lost exactly one prize per opening.
	var pity_ok := true  # Every due pity casket gave Epic or better.
	var max_miss := 0  # Longest run below Epic while Epic+ prizes existed.
	var miss := 0
	while true:
		var pool := Meta.caskets.prize_pool()
		if pool.is_empty():
			break
		var due := Meta.caskets.pity_due(pool)  # This one must be Epic or better.
		var had_good := CasketLedger.has_pity_prize(pool)  # Epic+ still in the pool.
		var p := Meta.caskets.open()
		if p.is_empty():
			break
		keys.append(_key(p))
		shrinks = shrinks and Meta.caskets.prize_pool().size() == pool.size() - 1
		var good := ["epic", "legendary"].has(String(p["tier"]))
		if due and not good:
			pity_ok = false
		if had_good:
			miss = 0 if good else miss + 1
			max_miss = maxi(max_miss, miss)
	_check(keys.size() == start, "seed %d: every prize was opened (%d of %d)" % [seed_value, keys.size(), start])
	var seen := {}
	for k: String in keys:
		seen[k] = true
	_check(seen.size() == keys.size(), "seed %d: never a duplicate across the whole pool" % seed_value)
	_check(shrinks, "seed %d: the pool shrinks by one per opening" % seed_value)
	_check(pity_ok and max_miss <= CasketData.PITY_AFTER, "seed %d: the pity fires on the 10th (longest run below Epic %d)" % [seed_value, max_miss])
	_check(Meta.caskets.spent == CasketData.PRICE * start and Meta.soul_ash == 100 and Meta.caskets.opened == start, "seed %d: %d caskets cost %d" % [seed_value, start, CasketData.PRICE * start])
	return keys


func _check_open_all() -> void:
	var a := _open_everything(CasketData.AUTOTEST_SEED)
	var b := _open_everything(CasketData.AUTOTEST_SEED)
	var c := _open_everything(4242)
	_check(a == b, "the same seed opens the same prizes in the same order")
	_check(a != c, "another seed opens them in another order")
	print("[ossuary_check] caskets: %d prizes on a fresh save (the default skins' recolours), all opened without a duplicate; first five %s" % [a.size(), ", ".join(a.slice(0, 5))])
	Meta._reset()
	_check(Meta.caskets.casket_seed == 0, "a fresh profile has no casket seed")
	Meta.soul_ash = CasketData.PRICE
	Meta.caskets.open()
	_check(Meta.caskets.casket_seed == CasketData.AUTOTEST_SEED, "the first opening draws the seed (the fixed one under the autotest)")


# --- Blocks ---------------------------------------------------------------------------

func _check_blocks() -> void:
	Meta._reset()
	Meta.soul_ash = CasketData.PRICE - 1
	var size0 := Meta.caskets.prize_pool().size()
	_check(Meta.caskets.open_block() == "cost" and Meta.caskets.open().is_empty(), "too little Soul Ash opens nothing")
	_check(Meta.soul_ash == CasketData.PRICE - 1 and Meta.caskets.opened == 0 and Meta.caskets.prize_pool().size() == size0, "and charges nothing")
	# Empty pool: every recolour of every unlocked skin owned.
	for id: String in SkinData.all_ids():
		if Meta.is_skin_unlocked(id):
			Meta.owned_recolours[id] = RecolourData.ids_for(id)
	Meta.soul_ash = 5000
	_check(Meta.caskets.prize_pool().is_empty() and Meta.caskets.open_block() == "empty", "everything owned: the pool is empty")
	_check(Meta.caskets.open().is_empty() and Meta.soul_ash == 5000 and Meta.caskets.spent == 0, "an empty pool opens nothing and charges nothing")
	# A locked skin's recolours are not prizes; unlocking it adds them.
	Meta.hyper_clears["%s-%s" % [HyperData.SKIN_STAGE_ID, "gravecaller"]] = true  # The Eclipsed Gravecaller.
	var pool := Meta.caskets.prize_pool()
	var hyper := SkinData.skins_for("gravecaller")[1]
	var only_hyper := pool.size() == 4
	for p: Dictionary in pool:
		only_hyper = only_hyper and String(p["skin"]) == hyper
	_check(only_hyper, "unlocking a skin adds its four recolours (Verdant, not Gilded, on a Hyper skin)")
	var verdant := false
	for p: Dictionary in pool:
		verdant = verdant or (String(p["recolour"]) == "verdant" and String(p["tier"]) == "epic")
	_check(verdant, "the Hyper skin's Verdant is an Epic prize")
	Meta._reset()


## Pity in play: nine misses in a row on a real pool, then the tenth is Epic.
func _check_pity_in_play() -> void:
	Meta._reset()
	Meta.soul_ash = CasketData.PRICE * 2
	Meta.caskets.since_epic = CasketData.PITY_AFTER
	_check(Meta.caskets.pity_left() == 1, "after nine misses the next casket is the pity one")
	var p := Meta.caskets.open()
	_check(String(p.get("tier", "")) == "epic" and Meta.caskets.since_epic == 0, "the 10th casket is Epic and resets the counter (got %s)" % String(p.get("tier", "")))
	Meta.caskets.since_epic = 3
	_check(Meta.caskets.pity_left() == 7, "pity_left counts the pity casket itself")
	Meta._reset()


# --- A casket-only skin (injected row: none ship yet) ----------------------------------

func _check_casket_skin() -> void:
	Meta._reset()
	var id := "test_casket_skin"  # Not in SkinData: passed in as a row.
	var fake := {"id": id, "character": "gravecaller", "display_name": "Test Shade", "kind": "casket", "unlock": {"type": "casket"},
		"look": "", "unlock_short": SkinData.CASKET_UNLOCK_SHORT, "tint": Color.WHITE, "accent": Color(0, 0, 0, 0), "glow": Color.WHITE, "emblem": "none", "sprite": ""}
	var rows := CasketLedger.skin_rows()
	rows.append(fake)
	_check(not Meta.skin_row_unlocked(id, fake), "a casket-only skin is locked before it is won")
	var pool := Meta.caskets.pool_from(rows)
	var leg: Dictionary = {}
	for p: Dictionary in pool:
		if String(p["skin"]) == id:
			leg = p
	_check(not leg.is_empty() and String(leg["recolour"]) == "" and String(leg["tier"]) == "legendary", "it is a Legendary prize while not won")
	_check(CasketLedger.odds(pool).has("legendary"), "the odds line shows Legendary while it exists")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	_check(_key(CasketLedger.roll(pool, rng, CasketData.PITY_AFTER)) == _key(leg), "the pity casket takes it (the best tier at Epic or above)")
	Meta.caskets._grant(leg)
	_check(Meta.skin_row_unlocked(id, fake) and Meta.caskets.has_won(id), "won: it is unlocked")
	var after := Meta.caskets.pool_from(rows)
	var recolours := 0  # Its recolours now in the pool.
	var again := false  # The skin itself still in the pool.
	for p: Dictionary in after:
		if String(p["skin"]) == id:
			if String(p["recolour"]) == "":
				again = true
			else:
				recolours += 1
	_check(not again and recolours == 4, "won: it leaves the pool and its four recolours join it")
	_check(after.size() == pool.size() - 1 + 4, "the pool lost one prize and gained four")
	Meta._reset()


# --- Save, older saves, Refund all ------------------------------------------------------

func _check_save() -> void:
	Meta._reset()
	DirAccess.make_dir_recursive_absolute(String(host.get("_dir")))
	var p: String = host.call("_path", "caskets.cfg")
	Meta.save_path = p
	Meta.soul_ash = CasketData.PRICE * 3 + 50
	Meta.owned_recolours[SkinData.default_skin("bone_oracle")] = PackedStringArray(["abyss"])  # Bought before the Caskets.
	for i in 3:
		Meta.caskets.open()
	var want := [Meta.caskets.casket_seed, Meta.caskets.opened, Meta.caskets.since_epic, Meta.caskets.spent]
	var owned := 0  # Recolours owned before the save.
	for s: String in SkinData.all_ids():
		owned += Meta.owned_recolour_ids(s).size()
	GameState.autotest_meta_save = true  # Lets save() write (to the temp path only).
	_check(Meta.save() == OK, "a save with caskets writes")
	GameState.autotest_meta_save = false
	var cfg := ConfigFile.new()
	cfg.load(p)
	_check(cfg.has_section("caskets") and int(cfg.get_value("caskets", "opened", 0)) == 3, "the [caskets] section is written")
	Meta.load_save()
	var got := [Meta.caskets.casket_seed, Meta.caskets.opened, Meta.caskets.since_epic, Meta.caskets.spent]
	var owned2 := 0
	for s: String in SkinData.all_ids():
		owned2 += Meta.owned_recolour_ids(s).size()
	_check(got == want and owned2 == owned and owned == 4, "seed / opened / pity / spent and the won recolours round trip (%s vs %s)" % [str(got), str(want)])
	_check(Meta.owns_recolour(SkinData.default_skin("bone_oracle"), "abyss"), "a recolour an older save bought stays owned")
	# The next opening after a reload continues the same sequence as without it.
	var next_after_load := _key(Meta.caskets.open())
	cfg.load(p)
	Meta.load_save()
	_check(_key(Meta.caskets.open()) == next_after_load, "a reloaded save opens the same next prize (reproducible per save)")
	# Edited values are clamped; an older save has no section and nothing opened.
	cfg = ConfigFile.new()
	cfg.load(p)
	cfg.set_value("caskets", "since_epic", 50)
	cfg.set_value("caskets", "opened", -4)
	cfg.set_value("casket_skins", "no_such_skin", true)
	cfg.save(p)
	Meta.load_save()
	_check(Meta.caskets.since_epic == CasketData.PITY_AFTER and Meta.caskets.opened == 0 and Meta.caskets.won_skins.is_empty(), "edited values are clamped, unknown casket skins dropped")
	var p2: String = host.call("_path", "caskets_old.cfg")
	host.call("_write_old", p2, 2, 40, {"necrotic_marrow": 3}, false)
	Meta.save_path = p2
	Meta.load_save()
	_check(Meta.caskets.opened == 0 and Meta.caskets.casket_seed == 0 and Meta.caskets.spent == 0 and Meta.tier("necrotic_marrow") == 3, "an older save has no caskets and keeps its tiers")
	DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(p2)
	Meta.save_path = Meta.DEFAULT_PATH
	# Refund all returns upgrades only: never casket spending or what it won.
	Meta._reset()
	Meta.soul_ash = CasketData.PRICE
	var won := Meta.caskets.open()
	Meta.tiers["necrotic_marrow"] = 2
	var before := Meta.soul_ash
	var refund := Meta.refund_all()
	_check(refund == MetaData.cost_up_to("necrotic_marrow", 2) and Meta.soul_ash == before + refund, "Refund all returns the upgrades only (%d)" % refund)
	_check(Meta.caskets.spent == CasketData.PRICE and Meta.owns_recolour(String(won["skin"]), String(won["recolour"])), "Refund all keeps the casket's prize and does not return its price")
	Meta._reset()


# --- The tab panel ------------------------------------------------------------------------

func _check_panel() -> void:
	Meta._reset()
	Meta.soul_ash = CasketData.PRICE * 2
	var panel := OssuaryCasketsPanel.new()
	host.add_child(panel)
	_check(panel.first_focus() == panel.open_button and not panel.open_button.disabled and not panel.wear_button.visible, "the tab opens on Open, Wear hidden")
	panel._on_open_pressed()
	_check(not panel.prize.is_empty() and Meta.soul_ash == CasketData.PRICE and not panel.stage.revealing(), "Open opens one casket; the reveal is instant under the autotest")
	_check(panel.wear_button.visible and panel._name.text == CasketLedger.prize_name(panel.prize) and panel._tier.text != "", "the prize's name and tier show, with Wear")
	panel._on_wear_pressed()
	_check(Meta.caskets.is_worn(panel.prize) and Meta.chosen_recolour(String(panel.prize["skin"])) == String(panel.prize["recolour"]) and panel.wear_button.text == CasketUiData.WORN, "Wear wears the prize on its skin")
	panel._on_open_pressed()
	panel._on_open_pressed()  # 0 Soul Ash left after the second: denied.
	_check(Meta.soul_ash == 0 and Meta.caskets.opened == 2, "a press without the Soul Ash opens nothing")
	for id: String in SkinData.all_ids():
		if Meta.is_skin_unlocked(id):
			Meta.owned_recolours[id] = RecolourData.ids_for(id)
	Meta.changed.emit()
	_check(panel.open_button.disabled and panel._status.text == CasketUiData.EMPTY_LINE, "an empty pool disables Open and says so")
	panel.queue_free()
	Meta._reset()


# --- Screenshots --------------------------------------------------------------------------

## Opens the Ossuary on the Caskets tab over the sample save (ossuary_check's
## _screenshot() made it): `what` = "caskets" (before opening), "casket_mid"
## (mid-reveal, frozen) or "casket_epic" (after an Epic reveal, the pity casket).
static func open_shot(holder: Control, what: String) -> void:
	for ch: String in ["bone_oracle", "plague_scholar", "wither_witch"]:
		Meta.spell_max_levels[String(CharacterData.CHARACTERS[ch]["spell"])] = 5
	Meta.achievements["bone_legion"] = true  # The Ivory Seer.
	Meta.owned_recolours[SkinData.default_skin("gravecaller")] = PackedStringArray(["bone", "blood"])
	Meta.owned_recolours[SkinData.default_skin("bone_oracle")] = PackedStringArray(["abyss"])
	Meta.caskets.casket_seed = CasketData.AUTOTEST_SEED
	Meta.caskets.since_epic = 6
	var menu := OssuaryMenu.open_over(holder, null)
	for i in 10:
		await menu.get_tree().process_frame
	menu.select_tab("caskets")
	var panel: OssuaryCasketsPanel = menu._pages["caskets"]
	panel.open_button.grab_focus()
	if what == "caskets":
		return
	Meta.caskets.since_epic = CasketData.PITY_AFTER  # The pity casket: Epic.
	panel._on_open_pressed()
	if what == "casket_mid":
		var st := panel.stage
		var t := CasketUiData.SHAKE_TIME + CasketUiData.RISE_TIME * 0.45  # Mid-rise, the lid in flight.
		panel._name.text = ""
		panel._tier.text = ""
		panel.wear_button.visible = false
		panel._stage_panel.add_theme_stylebox_override("panel", UiTheme.style("ornate", "violet"))
		st.settled = false
		st.start_usec = Time.get_ticks_usec() - int(t * 1000000.0)
		st._place(t)
		st.queue_redraw()
