## RelicEffects — the ONE path through which the equipped relics (RelicData) and
## the run's Grave Offering (OfferingData) reach a run (Ossuary expansion steps 5
## and 6a, GDD §15.0 "Relics and Grave Offerings"). Built once per run and per
## player: Meta.run_modifiers(config) for solo (for_run(): the setup screen's
## choice, checked against the save; the autotest's --relics / --offering /
## --meta=max), CoopSession.meta_for() from each loadout in co-op. It is attached
## to that player's MetaModifiers (MetaModifiers.attach_rites()), so it lives in
## game.meta and follows the co-op slot binding like the Ossuary upgrades:
##   * stat_values() are added to the MetaData.STATS modifier stats once,
##   * special(key) is read where the game applies that thing (RelicData.SPECIALS).
## An empty instance (nothing equipped, no offering) changes nothing, so runs
## without relics play exactly as before (same-seed summaries unchanged).
## No state changes during a run; nothing random (the borrowed relic is chosen
## before the run, RelicLedger.prepare_run()).
class_name RelicEffects
extends RefCounted

## Equipped relic ids for this run (RelicData.ORDER order; the borrowed one included).
var relics: PackedStringArray = PackedStringArray()
## OfferingData id of this run's offering ("" = none).
var offering: String = ""
## RelicData id lent by the Borrowed Relic offering ("" = none; also in `relics`).
var borrowed: String = ""
## Modifier stat (MetaData.STATS key) -> summed value of every source.
var _stats: Dictionary = {}
## Special key (RelicData.SPECIAL_RULES) -> combined value of every source.
var _special: Dictionary = {}


## Effects of relics `relic_ids` (unknown ids and duplicates dropped; at most
## RelicData.MAX_SLOTS kept, in RelicData.ORDER) plus offering `offering_id` ("" =
## none) and, for a Borrowed Relic, `borrowed_id` (a relic not among the others).
static func build(relic_ids: Variant, offering_id: String = "", borrowed_id: String = "") -> RelicEffects:
	var r := RelicEffects.new()
	var wanted: Array = []  # Requested ids (any Array-like input).
	if relic_ids is Array or relic_ids is PackedStringArray:
		for v: Variant in relic_ids:
			wanted.append(String(v))
	for id: String in RelicData.ORDER:
		if wanted.has(id) and r.relics.size() < RelicData.MAX_SLOTS:
			r.relics.append(id)
	if OfferingData.has(offering_id):
		r.offering = offering_id
		if bool(OfferingData.OFFERINGS[offering_id]["borrow"]) and RelicData.has(borrowed_id) and not r.relics.has(borrowed_id):
			r.borrowed = borrowed_id
	for id: String in r.all_relics():
		r._add(RelicData.RELICS[id])
	if r.offering != "":
		r._add(OfferingData.OFFERINGS[r.offering])
	return r


## The effects for a run with `config` (null = none): under the autotest the
## --relics / --offering flags (--meta=max: RelicData.AUTOTEST_MAX_RELICS when no
## --relics is given); otherwise the config's relics that the save owns, within its
## slots (RelicLedger.valid_equip()), and its offering (paid by Game, not here).
static func for_run(config: RunConfig) -> RelicEffects:
	if GameState.autotest:
		var ids: Array = GameState.autotest_relics.duplicate()  # --relics=a,b.
		if ids.is_empty() and GameState.autotest_meta == "max":
			ids = RelicData.AUTOTEST_MAX_RELICS.duplicate()
		var off := GameState.autotest_offering  # --offering=ID ("" = none).
		var lent := ""  # Borrowed Relic: the first relic (ORDER) not equipped, deterministic.
		if OfferingData.has(off) and bool(OfferingData.OFFERINGS[off]["borrow"]):
			for id: String in RelicData.ORDER:
				if not ids.has(id):
					lent = id
					break
		return build(ids, off, lent)
	if config == null:
		return RelicEffects.new()
	return build(Meta.relics.valid_equip(config.relics), config.offering_id, config.borrowed_relic)


## Adds one RelicData / OfferingData row's stats and specials.
func _add(row: Dictionary) -> void:
	var st: Dictionary = row.get("stats", {})
	for k: String in st:
		_stats[k] = float(_stats.get(k, 0.0)) + float(st[k])
	var sp: Dictionary = row.get("special", {})
	for k: String in sp:
		var v := float(sp[k])  # This source's value.
		if not _special.has(k):
			_special[k] = v
			continue
		var cur := float(_special[k])  # Combined so far.
		match String(RelicData.SPECIAL_RULES.get(k, "add")):
			"mul":
				_special[k] = cur * v
			"max":
				_special[k] = maxf(cur, v)
			"min":
				_special[k] = minf(cur, v) if cur > 0.0 and v > 0.0 else maxf(cur, v)
			_:
				_special[k] = cur + v


## Every relic in effect: the equipped ones and the borrowed one.
func all_relics() -> PackedStringArray:
	var out := relics.duplicate()  # Equipped, then the borrowed one.
	if borrowed != "":
		out.append(borrowed)
	return out


## Summed modifier stats (MetaData.STATS key -> value), added once to the run's
## MetaModifiers (attach_rites()).
func stat_values() -> Dictionary:
	return _stats


## Combined special value of `key` (RelicData.SPECIAL_RULES): the rule's neutral
## value when no source has it (1 for "mul", 0 otherwise).
func special(key: String) -> float:
	if _special.has(key):
		return float(_special[key])
	return 1.0 if String(RelicData.SPECIAL_RULES.get(key, "add")) == "mul" else 0.0


## special() rounded to an int (counts: chest upgrades, slots, levels).
func special_int(key: String) -> int:
	return int(roundf(special(key)))


## True when relic `id` is in effect (equipped or borrowed).
func has(id: String) -> bool:
	return relics.has(id) or borrowed == id


## True when nothing is equipped and no offering is made.
func is_empty() -> bool:
	return relics.is_empty() and offering == ""


## Autotest summary text: "relics a, b (+ c borrowed) | offering x".
func describe() -> String:
	var rel := ", ".join(relics) if not relics.is_empty() else "none"  # Equipped list.
	if borrowed != "":
		rel += " (+ %s borrowed)" % borrowed
	return "relics %s | offering %s" % [rel, offering if offering != "" else "none"]
