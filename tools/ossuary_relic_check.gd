## ossuary_relic_check.gd (preloaded by ossuary_check.gd: tools/ has a .gdignore,
## so no class_name) — the relic and Grave Offering part of tools/ossuary_check
## (Ossuary expansion steps 5 and 6a, GDD §15.0 "Relics and Grave Offerings"):
## checks the data (prices, the ~8,000 budget, offering prices against a good run's
## pay, badge art), RelicEffects (combination rules, the MetaModifiers stats), the
## RelicLedger (buying relics and slots, the feats, equipping, the offering's
## payment and draw), the save (round trip, an older save without the sections,
## edited values) and the co-op loadout. Called from ossuary_check.gd's _run();
## it uses the same temp save directory and never the real save. Screenshot
## helpers for --shot-rites= / --shot-relics= / --shot-offerings= / --shot-picker=
## live here too (drawing only). tools/.gdignore keeps it out of exports.

extends RefCounted

## The ossuary_check node (its _check() counts failures; its _path() names temp files).
var host: Node


func _init(p_host: Node) -> void:
	host = p_host


## Runs every relic / offering check.
func run() -> void:
	_check_data()
	_check_effects()
	_check_ledger()
	_check_offerings()
	_check_save()
	_check_coop()
	Meta._reset()


func _check(ok: bool, what: String) -> void:
	host.call("_check", ok, "relics: " + what)


# --- Data ---------------------------------------------------------------------------

func _check_data() -> void:
	_check(RelicData.ORDER.size() == RelicData.RELICS.size() and RelicData.ORDER.size() >= 12, "ORDER lists every relic (about 15)")
	var rows := PackedStringArray()  # Price table.
	for id: String in RelicData.ORDER:
		var r: Dictionary = RelicData.RELICS[id]
		_check(RelicData.price(id) > 0, "%s has a price" % id)
		_check(ResourceLoader.exists("res://assets/sprites/icons/%s.png" % String(r["icon"])), "%s has its badge" % id)
		for st: String in (r["stats"] as Dictionary):
			_check(MetaData.STATS.has(st), "%s stat %s is a MetaData stat" % [id, st])
		for sp: String in (r["special"] as Dictionary):
			_check(RelicData.SPECIAL_RULES.has(sp), "%s special %s has a rule" % [id, sp])
		_check(String(r["feat"]) == "" or RelicData.FEATS.has(String(r["feat"])), "%s feat is known" % id)
		rows.append("%s %d%s" % [id, RelicData.price(id), " (" + String(r["feat"]) + ")" if String(r["feat"]) != "" else ""])
	var feats := 0  # Relics sold only after a feat.
	for id: String in RelicData.ORDER:
		if String(RelicData.RELICS[id]["feat"]) != "":
			feats += 1
	_check(feats >= 2, "some relics are sold only after a feat")
	_check(RelicData.START_SLOTS == 1 and RelicData.MAX_SLOTS == 3, "1 slot from the start, 3 at most (owner decision)")
	_check(RelicData.slot_price(2) > 0 and RelicData.slot_price(3) > RelicData.slot_price(2) and RelicData.slot_price(4) == -1, "slots 2 and 3 are priced, rising")
	var total := RelicData.total_cost()
	_check(total >= 7000 and total <= 9000, "relics + slots cost about 8,000 (%d)" % total)
	print("[ossuary_check] relics: %s | slots %d + %d | total %d" % [", ".join(rows), RelicData.slot_price(2), RelicData.slot_price(3), total])
	var orows := PackedStringArray()  # Offering table.
	_check(OfferingData.ORDER.size() >= 5 and OfferingData.ORDER.size() <= 6, "5-6 offerings")
	for id: String in OfferingData.ORDER:
		var share := float(OfferingData.price(id)) / float(OfferingData.GOOD_RUN_ASH)  # Share of a good run's pay.
		_check(share >= 0.39 and share <= 0.71, "%s costs 40-70%% of a good run (%.0f%%)" % [id, share * 100.0])
		_check(ResourceLoader.exists("res://assets/sprites/icons/%s.png" % String(OfferingData.OFFERINGS[id]["icon"])), "%s has its badge" % id)
		orows.append("%s %d (%.0f%%)" % [id, OfferingData.price(id), share * 100.0])
	for icon: String in ["relic_slot", "offering_slot"]:
		_check(ResourceLoader.exists("res://assets/sprites/icons/%s.png" % icon), "%s badge" % icon)
	print("[ossuary_check] offerings: %s" % ", ".join(orows))


# --- Effects -------------------------------------------------------------------------

func _check_effects() -> void:
	var none := RelicEffects.new()
	_check(none.is_empty() and none.stat_values().is_empty(), "an empty set has no stats")
	_check(none.special("max_hp_mult") == 1.0 and none.special("chest_bonus") == 0.0, "an empty set is neutral (x1, +0)")
	var m0 := MetaModifiers.from_tiers({"umbral_potency": 2})
	var before := m0.value("spell_damage")
	m0.attach_rites(RelicEffects.build([]))
	_check(m0.value("spell_damage") == before and m0.relic("max_hp_mult") == 1.0, "attaching nothing changes nothing")
	var r := RelicEffects.build(["hollow_crown", "lichs_phylactery", "martyrs_nail", "unknown", "hollow_crown"], "war_horn")
	_check(r.relics.size() == 3, "unknown and repeated ids are dropped")
	_check(is_equal_approx(r.special("max_hp_mult"), 0.9 * 0.8), "max HP multipliers multiply")
	_check(r.special_int("active_slots") == 1 and is_equal_approx(float(r.stat_values().get("revives", 0.0)), 1.0), "Hollow Crown slot, Phylactery revival")
	_check(r.special("ult_start") == 1.0, "War Horn fills the meter")
	var four := RelicEffects.build(["grave_lantern", "black_banner", "bone_abacus", "hollow_crown"])
	_check(four.relics.size() == RelicData.MAX_SLOTS, "at most MAX_SLOTS relics")
	var banner := RelicEffects.build(["black_banner"], "war_horn")
	_check(banner.special("ult_start") == 1.0, "ult_start keeps the largest")
	var m := MetaModifiers.from_tiers({"umbral_potency": 2})
	m.attach_rites(RelicEffects.build(["martyrs_nail", "war_drum"]))
	_check(is_equal_approx(m.value("spell_damage"), before + 0.15 - 0.10), "relic stats add to the Ossuary stats")
	var lent := RelicEffects.build(["black_banner"], "borrowed_relic", "bone_abacus")
	_check(lent.has("bone_abacus") and lent.all_relics().size() == 2 and lent.special("reroll_every") == 5.0, "the borrowed relic is in effect")
	var bad := RelicEffects.build(["black_banner"], "borrowed_relic", "black_banner")
	_check(bad.borrowed == "", "a borrowed relic that is already equipped is dropped")


# --- Ledger ---------------------------------------------------------------------------

func _check_ledger() -> void:
	Meta._reset()
	var led := Meta.relics
	_check(led.slots == 1 and led.owned.is_empty(), "a fresh save: 1 slot, no relics")
	_check(led.buy_block("black_banner") == "cost" and not led.buy("black_banner"), "no Soul Ash, no relic")
	Meta.soul_ash = 20000
	var p := RelicData.price("black_banner")
	_check(led.buy("black_banner") and Meta.soul_ash == 20000 - p and led.is_owned("black_banner"), "a relic buys once")
	_check(led.buy_block("black_banner") == "owned" and not led.buy("black_banner"), "and not twice")
	_check(led.buy_block("lichs_phylactery") == "feat", "a feat relic waits on its feat")
	Meta._record_clear({"victory": true, "difficulty_id": "lich", "hyper": false})
	_check(led.buy_block("lichs_phylactery") == "" and led.buy_block("deathlords_seal") == "feat", "a Lich clear sells the Phylactery, not the Seal")
	Meta._record_clear({"victory": true, "difficulty_id": "deathlord", "hyper": false})
	_check(led.buy_block("deathlords_seal") == "", "a Deathlord clear sells the Seal")
	_check(led.buy_block("fallen_halo") == "feat", "the Halo waits on a Hyper finale")
	Meta.hyper_clears["citadel-gravecaller"] = true
	_check(led.buy_block("fallen_halo") == "", "an act's last stage cleared on Hyper sells the Halo")
	var ash := Meta.soul_ash
	_check(led.buy_slot() and led.slots == 2 and Meta.soul_ash == ash - RelicData.slot_price(2), "slot 2 buys")
	_check(led.buy_slot() and led.slots == 3 and led.slot_block() == "maxed" and not led.buy_slot(), "slot 3 buys, then maxed")
	led.buy("bone_abacus")
	_check(led.valid_equip(["bone_abacus", "grave_lantern", "black_banner", "bone_abacus"]) == PackedStringArray(["bone_abacus", "black_banner"]), "equip keeps owned relics in slot order")
	_check(led.spent() == RelicData.price("black_banner") + RelicData.price("bone_abacus") + RelicData.slot_price(2) + RelicData.slot_price(3), "spent counts relics and slots")
	var refunded := Meta.refund_all()
	_check(refunded == 0 and led.is_owned("black_banner") and led.slots == 3, "Refund all (upgrades) keeps relics and slots")
	Meta._reset()


# --- Offerings ---------------------------------------------------------------------------

func _check_offerings() -> void:
	Meta._reset()
	var led := Meta.relics
	_check(led.offering_block("war_horn", PackedStringArray()) == "cost", "an offering the balance cannot pay is blocked")
	Meta.soul_ash = 5000
	_check(led.offering_block("war_horn", PackedStringArray()) == "", "an affordable offering can be chosen")
	_check(led.offering_block("borrowed_relic", PackedStringArray()) == "borrow", "nothing to lend: Borrowed Relic blocked")
	var c := RunConfig.new()
	c.offering_id = "war_horn"
	led.prepare_run(c)
	_check(c.offering_id == "war_horn" and Meta.soul_ash == 5000, "confirming the setup pays nothing yet")
	_check(led.pay_offering("war_horn") and Meta.soul_ash == 5000 - OfferingData.price("war_horn"), "the run start pays it")
	Meta.soul_ash = 10
	var c2 := RunConfig.new()
	c2.offering_id = "second_breath"
	led.prepare_run(c2)
	_check(c2.offering_id == "", "an offering the balance cannot pay is dropped on Begin")
	_check(not led.pay_offering("second_breath") and Meta.soul_ash == 10, "and cannot be paid")
	Meta.soul_ash = 20000
	led.buy("black_banner")
	led.buy("bone_abacus")
	var c3 := RunConfig.new()
	c3.relics = PackedStringArray(["black_banner"])
	c3.offering_id = "borrowed_relic"
	led.prepare_run(c3)
	_check(c3.borrowed_relic == "bone_abacus", "Borrowed Relic lends an owned relic that is not equipped")
	var d := c3.duplicate_config()
	_check(d.offering_id == "borrowed_relic" and d.borrowed_relic == "bone_abacus" and d.relics == c3.relics, "the run's copy keeps the rites")
	Meta._reset()


# --- Save --------------------------------------------------------------------------------

func _check_save() -> void:
	var path := String(host.call("_path", "relics_save.cfg"))
	Meta._reset()
	Meta.save_path = path
	Meta.soul_ash = 20000
	Meta.relics.buy("grave_lantern")
	Meta.relics.buy("hollow_crown")
	Meta.relics.buy_slot()
	var cfg := RunConfig.new()
	cfg.relics = PackedStringArray(["hollow_crown", "grave_lantern"])
	Meta.remember_prerun(cfg)
	var saved := ConfigFile.new()  # What Meta.save() writes for the relics (the autotest never writes the real path).
	saved.set_value("meta", "save_version", MetaData.SAVE_VERSION)
	saved.set_value("currency", "soul_ash", Meta.soul_ash)
	Meta.relics.write(saved)
	saved.save(path)
	saved = ConfigFile.new()
	saved.load(path)
	_check(String(saved.get_value("relics", "owned", "")) == "grave_lantern,hollow_crown" and int(saved.get_value("relics", "slots", 0)) == 2, "the save holds [relics]")
	_check(String(saved.get_value("prerun", "relics", "")) == "hollow_crown,grave_lantern", "and [prerun] relics in slot order")
	Meta._reset()
	Meta.load_save()
	_check(Meta.relics.is_owned("hollow_crown") and Meta.relics.slots == 2 and Meta.relics.equipped == PackedStringArray(["hollow_crown", "grave_lantern"]), "relics, slots and the equipped set load")
	_check(Meta.prerun_config("graveyard").relics == PackedStringArray(["hollow_crown", "grave_lantern"]), "the setup screen opens on the equipped set")
	var old := ConfigFile.new()  # An older save without the sections.
	old.set_value("meta", "save_version", 2)
	old.set_value("currency", "soul_ash", 123)
	old.save(path)
	Meta.load_save()
	_check(Meta.soul_ash == 123 and Meta.relics.owned.is_empty() and Meta.relics.slots == 1 and Meta.relics.equipped.is_empty(), "an older save: no relics, 1 slot")
	var edited := ConfigFile.new()  # Hand-edited values.
	edited.set_value("meta", "save_version", 2)
	edited.set_value("relics", "owned", "black_banner,nonsense")
	edited.set_value("relics", "slots", 9)
	edited.set_value("prerun", "relics", "grave_lantern,black_banner")
	edited.save(path)
	Meta.load_save()
	_check(Meta.relics.is_owned("black_banner") and Meta.relics.owned.size() == 1 and Meta.relics.slots == 3, "unknown ids dropped, slots clamped")
	_check(Meta.relics.equipped == PackedStringArray(["black_banner"]), "an unowned equipped relic is dropped")
	DirAccess.remove_absolute(path)
	Meta.save_path = Meta.DEFAULT_PATH
	Meta._reset()


# --- Co-op loadout -------------------------------------------------------------------------

func _check_coop() -> void:
	var lo := {"relics": ["hollow_crown", "nonsense", "bone_flute", "hollow_crown", "grave_lantern", "black_banner"],
		"offering": "borrowed_relic", "borrowed": "mourners_bell", "meta_levels": {}}
	var clean: Dictionary = CoopNet._clean_loadout(lo, 1)
	_check((clean["relics"] as Array) == ["hollow_crown", "bone_flute", "grave_lantern"], "the loadout keeps known relics, at most 3")
	_check(String(clean["offering"]) == "borrowed_relic" and String(clean["borrowed"]) == "mourners_bell", "the loadout keeps the offering and its relic")
	var bad: Dictionary = CoopNet._clean_loadout({"offering": "nope", "borrowed": "black_banner"}, 0)
	_check(String(bad["offering"]) == "" and String(bad["borrowed"]) == "" and (bad["relics"] as Array).is_empty(), "a bad offering is dropped")
	var m := MetaModifiers.from_tiers({})
	m.attach_rites(RelicEffects.build(clean["relics"], String(clean["offering"]), String(clean["borrowed"])))
	_check(m.relic_int("active_slots") == 1 and m.relic("elite_feast") > 0.0 and m.relic_int("chest_bonus") == 1, "the partner's relics apply to his slot")


# =====================================================================================
# Screenshots (drawing only)
# =====================================================================================

## A sample save for the screenshots: some relics owned, two slots, Lich cleared.
static func sample_save() -> void:
	Meta._reset()
	Meta.soul_ash = 2480
	for id: String in ["grave_lantern", "black_banner", "bone_abacus", "mourners_bell", "war_drum", "shade_cloak"]:
		Meta.relics.owned[id] = true
	Meta.relics.slots = 2
	Meta.relics.equipped = PackedStringArray(["bone_abacus", "black_banner"])
	Meta._record_clear({"victory": true, "difficulty_id": "lich", "hyper": false})
	Meta.hyper_unlocked = true


## Opens `what` ("rites", "picker", "relics", "offerings") over `holder`.
static func open_shot(holder: Control, what: String) -> void:
	sample_save()
	match what:
		"rites", "picker":
			var c := Meta.prerun_config("graveyard")
			c.offering_id = "gilded_coffer"
			var s := PreRunSetup.open_over(holder, null, c)
			if what == "picker":
				await s.get_tree().process_frame
				await s.get_tree().process_frame
				s._rites._on_slot_pressed(1)
		_:
			var center := CenterContainer.new()
			center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			holder.add_child(center)
			var vb := VBoxContainer.new()
			vb.add_theme_constant_override("separation", 12)
			center.add_child(vb)
			vb.add_child(UiTheme.tier_label(OssuaryUiData.TITLE + "  ·  " + what.capitalize(), UiTheme.Tier.TITLE, UiTheme.TEXT_GOLD))
			var panel: Control = OssuaryRelicsPanel.new() if what == "relics" else OssuaryOfferingsPanel.new()
			vb.add_child(panel)
			await panel.get_tree().process_frame
			(panel.call("first_focus") as Control).grab_focus()
