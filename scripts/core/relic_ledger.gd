## RelicLedger — the save side of the relics and Grave Offerings (Ossuary
## expansion steps 5 and 6a, GDD §15.0 "Relics and Grave Offerings"): which relics
## the player bought, how many relic slots, the relics last equipped on the pre-run
## setup screen, and the Soul Ash paths (buy a relic, buy a slot, pay an
## offering). The Meta autoload owns one instance as `Meta.relics` and calls
## reset() / read() / write() from its own _reset() / load_save() / save(), so the
## save stays one file (user://save.cfg) with one load path:
##   [relics]  owned = "<id>,<id>,..." (RelicData ids, comma-separated),
##             slots = 1..3 (RelicData.START_SLOTS + slots bought),
##   [prerun]  relics = "<id>,<id>,..." (equipped, slot order).
## The sections are additive: an older save has none and reads as no relics,
## one slot, nothing equipped (no SAVE_VERSION step needed); unknown ids, a relic
## not owned and slots out of range are dropped / clamped. Relics are bought once
## and kept: the Ossuary's Refund all (upgrades only) never returns them.
## Feats (RelicData.FEATS) read the clear records Meta already keeps ([clears]
## best through Meta.best_clear, [hyper_clears] through Meta.hyper_clear_count()).
## Every write goes through Meta.save() (never under the autotest, Meta.can_write()).
class_name RelicLedger
extends RefCounted

## RelicData id -> true for every relic bought.
var owned: Dictionary = {}
## Relic slots owned (RelicData.START_SLOTS .. RelicData.MAX_SLOTS).
var slots: int = RelicData.START_SLOTS
## Relics last equipped on the setup screen, in slot order (owned ids only, at
## most `slots`): the next setup screen opens on them.
var equipped: PackedStringArray = PackedStringArray()


## A fresh profile: nothing bought, one slot, nothing equipped.
func reset() -> void:
	owned = {}
	slots = RelicData.START_SLOTS
	equipped = PackedStringArray()


# =====================================================================================
# Save / load (called by Meta)
# =====================================================================================

## Reads [relics] and [prerun] relics from `cfg` (missing = the fresh profile).
func read(cfg: ConfigFile) -> void:
	reset()
	var o: Variant = cfg.get_value("relics", "owned", "")
	if typeof(o) == TYPE_STRING:
		for id: String in String(o).split(",", false):
			if RelicData.has(id):
				owned[id] = true
	var s: Variant = cfg.get_value("relics", "slots", RelicData.START_SLOTS)
	if typeof(s) == TYPE_INT or typeof(s) == TYPE_FLOAT:
		slots = clampi(int(s), RelicData.START_SLOTS, RelicData.MAX_SLOTS)
	var e: Variant = cfg.get_value("prerun", "relics", "")
	if typeof(e) == TYPE_STRING:
		equipped = valid_equip(String(e).split(",", false))


## Writes the ledger into `cfg` (Meta.save()).
func write(cfg: ConfigFile) -> void:
	var ids := PackedStringArray()  # Owned ids, RelicData.ORDER order.
	for id: String in RelicData.ORDER:
		if owned.has(id):
			ids.append(id)
	cfg.set_value("relics", "owned", ",".join(ids))
	cfg.set_value("relics", "slots", slots)
	cfg.set_value("prerun", "relics", ",".join(equipped))


# =====================================================================================
# Relics
# =====================================================================================

## True when relic `id` was bought.
func is_owned(id: String) -> bool:
	return owned.has(id)


## True when feat `feat` (RelicData.FEATS id; "" = none) is achieved.
static func feat_met(feat: String) -> bool:
	if feat == "":
		return true
	var f: Dictionary = RelicData.FEATS.get(feat, {})
	if f.is_empty():
		return false
	if f.has("difficulty"):
		return Meta.best_clear >= DifficultyData.ORDER.find(String(f["difficulty"]))
	if f.has("hyper_stages"):
		for sid: Variant in f["hyper_stages"]:
			if Meta.hyper_clear_count(String(sid)) > 0:
				return true
	return false


## The feat relic `id` waits on ("" = sold, or bought).
func missing_feat(id: String) -> String:
	if owned.has(id) or not RelicData.has(id):
		return ""
	var feat := String(RelicData.RELICS[id]["feat"])  # Its feat ("" = none).
	return "" if feat_met(feat) else feat


## Why relic `id` cannot be bought now: "" (it can), "owned", "feat" (its feat is
## missing), "cost" (not enough Soul Ash) or "unknown".
func buy_block(id: String) -> String:
	if not RelicData.has(id):
		return "unknown"
	if owned.has(id):
		return "owned"
	if missing_feat(id) != "":
		return "feat"
	if Meta.soul_ash < RelicData.price(id):
		return "cost"
	return ""


## Buys relic `id` (Soul Ash off, saved). Returns false when blocked.
func buy(id: String) -> bool:
	if buy_block(id) != "":
		return false
	Meta.soul_ash -= RelicData.price(id)
	owned[id] = true
	_commit()
	return true


# =====================================================================================
# Slots
# =====================================================================================

## Price of the next slot (-1 when every slot is owned).
func next_slot_price() -> int:
	return RelicData.slot_price(slots + 1)


## Why the next slot cannot be bought: "" (it can), "maxed" or "cost".
func slot_block() -> String:
	if slots >= RelicData.MAX_SLOTS:
		return "maxed"
	if Meta.soul_ash < next_slot_price():
		return "cost"
	return ""


## Buys the next relic slot (Soul Ash off, saved). Returns false when blocked.
func buy_slot() -> bool:
	if slot_block() != "":
		return false
	Meta.soul_ash -= next_slot_price()
	slots += 1
	_commit()
	return true


## Soul Ash spent on relics and slots (the Ossuary panel's total).
func spent() -> int:
	var total := 0  # Sum so far.
	for id: String in owned:
		total += RelicData.price(id)
	for s in range(RelicData.START_SLOTS + 1, slots + 1):
		total += RelicData.slot_price(s)
	return total


# =====================================================================================
# Equipping (the pre-run setup screen)
# =====================================================================================

## `ids` with unknown, unowned and repeated relics dropped, cut to the owned
## slots; the slot order is kept.
func valid_equip(ids: Variant) -> PackedStringArray:
	var out := PackedStringArray()  # Valid ids, slot order.
	if not (ids is Array or ids is PackedStringArray):
		return out
	for v: Variant in ids:
		var id := String(v)  # Requested relic.
		if owned.has(id) and not out.has(id) and out.size() < slots:
			out.append(id)
	return out


## Remembers equipped relics `ids` for the next setup screen (the caller saves).
## Returns true when they changed.
func remember(ids: PackedStringArray) -> bool:
	var v := valid_equip(ids)  # Cleaned list.
	if v == equipped:
		return false
	equipped = v
	return true


# =====================================================================================
# Grave Offerings
# =====================================================================================

## Owned relics that are not in `equip` (the Borrowed Relic's draw pool), in
## RelicData.ORDER.
func lendable(equip: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()  # Candidates.
	for id: String in RelicData.ORDER:
		if owned.has(id) and not equip.has(id):
			out.append(id)
	return out


## Why offering `id` cannot be chosen for a run with relics `equip`: "" (it can),
## "cost" (the balance cannot pay it) or "borrow" (Borrowed Relic: no owned relic
## left to lend). "" for the empty id (no offering).
func offering_block(id: String, equip: PackedStringArray) -> String:
	if id == "":
		return ""
	if not OfferingData.has(id):
		return "unknown"
	if Meta.soul_ash < OfferingData.price(id):
		return "cost"
	if bool(OfferingData.OFFERINGS[id]["borrow"]) and lendable(equip).is_empty():
		return "borrow"
	return ""


## Finishes `config`'s rites when the setup screen confirms it (Begin, or Done in
## the co-op lobby): the relics cut to the save's, an offering it cannot take
## dropped, and the Borrowed Relic's relic drawn (a menu-side draw, before the run:
## the run itself only reads the result, so it stays deterministic per seed).
func prepare_run(config: RunConfig) -> void:
	config.relics = valid_equip(config.relics)
	if offering_block(config.offering_id, config.relics) != "":
		config.offering_id = ""
	config.borrowed_relic = ""
	if config.offering_id != "" and bool(OfferingData.OFFERINGS[config.offering_id]["borrow"]):
		var pool := lendable(config.relics)  # Owned, not equipped.
		config.borrowed_relic = pool[randi() % pool.size()]


## Pays offering `id` when its run starts (Soul Ash off, saved). Returns false
## (nothing paid) for "" or when the balance cannot pay it. Game never calls it
## under the autotest (whose runs pay nothing); Meta.save() writes nothing there.
func pay_offering(id: String) -> bool:
	if not OfferingData.has(id):
		return false
	if Meta.soul_ash < OfferingData.price(id):
		return false
	Meta.soul_ash -= OfferingData.price(id)
	_commit()
	return true


## Saves and tells the screens (Meta.changed).
func _commit() -> void:
	Meta.save()
	Meta.changed.emit()
