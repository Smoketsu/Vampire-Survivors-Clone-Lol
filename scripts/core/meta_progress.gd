## Meta — persistent meta-progression autoload (GDD §9.2 Soul Ash, §9.4
## achievements, §15.7 q50 "what persists"). Owns everything that outlives a
## run and saves it to user://save.cfg (ConfigFile), separate from
## user://settings.cfg:
##   * Soul Ash balance and the purchased tier of every upgrade (MetaData),
##   * lifetime statistics (runs, best time, total kills, boss kills...),
##   * achievement unlocks (MetaData.ACHIEVEMENTS).
## Run flow: Game asks run_modifiers() at run start (the ONE place meta
## upgrades enter a run, see MetaModifiers) and calls award_run() when the
## run ends, won or lost (Soul Ash is kept on death).
##
## Saving: on every run end, purchase and refund. Never in --autotest unless
## the --meta-save test flag asks for it; the autotest does not even read the
## file and uses an in-memory --meta profile instead.
## Loading is migration-safe: a missing file starts fresh, an unreadable
## (corrupt) file is copied to "<path>.corrupt" and the game starts fresh,
## every value is type-checked and clamped, unknown keys are ignored, and
## tiers whose prerequisite is no longer met are refunded.
## Like Settings this script has no class_name; it is reached as `Meta`.
extends Node

## Emitted after the balance, tiers, lifetime stats or achievements changed.
signal changed

## Default save file location.
const DEFAULT_PATH: String = "user://save.cfg"
## Upper clamp for any stored counter (guards against absurd edited values).
const MAX_STORED: int = 1000000000

## File used by load_save() / save() (tests point this somewhere else).
var save_path: String = DEFAULT_PATH
## Current Soul Ash balance.
var soul_ash: int = 0
## Upgrade id -> purchased tier (every MetaData upgrade id is present).
var tiers: Dictionary = {}
## Lifetime statistics (key -> number). See _default_lifetime().
var lifetime: Dictionary = {}
## Achievement id -> true once unlocked.
var achievements: Dictionary = {}
## Result of the last ConfigFile.load() (OK, ERR_FILE_NOT_FOUND, ERR_PARSE_ERROR...).
var last_load_error: Error = OK
## What the last load did: "fresh" (not loaded), "missing", "corrupt", "ok",
## "migrated" (older save_version) or "newer" (save from a newer build).
var load_status: String = "fresh"
## Breakdown Dictionary of the most recent award_run() (see compute_ash()).
var last_award: Dictionary = {}


func _ready() -> void:
	_reset()
	if not GameState.autotest or GameState.autotest_meta_save:
		load_save()


# =====================================================================================
# Run hooks
# =====================================================================================

## Modifiers for a new run: the purchased tiers, or the --meta profile
## (MetaData.AUTOTEST_PROFILES) in the autotest. Nothing is written.
func run_modifiers() -> MetaModifiers:
	if GameState.autotest:
		return MetaModifiers.from_tiers(MetaData.autotest_tiers(GameState.autotest_meta))
	return MetaModifiers.from_tiers(tiers)


## Soul Ash earned by a finished run (MetaData header formula). Each part is
## floored to whole ash so the breakdown on the end screen adds up exactly.
## `summary` is Game.build_summary(); `ash_gain` is the Ash Harvest bonus.
static func compute_ash(summary: Dictionary, ash_gain: float) -> Dictionary:
	var st: Dictionary = summary.get("stats", {})
	var countdown := float(summary.get("countdown", WaveData.RUN_DURATION))
	var survived := minf(float(summary.get("time", 0.0)), countdown)
	var past_zero := minf(float(summary.get("time_past_zero", 0.0)), MetaData.ASH_RECKONING_CAP_SECONDS)
	var kills := int(summary.get("kills", 0))
	var elites := int(st.get("elite_kills", 0.0))
	var boss := bool(summary.get("boss_defeated", false))
	var parts := {
		"time": floori(survived / 60.0 * MetaData.ASH_PER_MINUTE),
		"kills": floori(float(kills) * MetaData.ASH_PER_KILL),
		"elites": floori(float(elites) * MetaData.ASH_PER_ELITE),
		"boss": floori(MetaData.ASH_BOSS_KILL) if boss else 0,
		"reckoning": floori(past_zero * MetaData.ASH_PER_RECKONING_SECOND),
	}
	var subtotal := 0
	for k: String in parts:
		subtotal += int(parts[k])
	var bonus := floori(float(subtotal) * maxf(0.0, ash_gain))
	return {
		"parts": parts,
		"time_survived": survived,
		"kill_count": kills,
		"elite_count": elites,
		"reckoning_seconds": past_zero,
		"subtotal": subtotal,
		"bonus_pct": ash_gain,
		"bonus": bonus,
		"total": subtotal + bonus,
	}


## Ends a run for meta-progression: adds its Soul Ash (kept on death),
## updates lifetime stats and achievements (one-time bounties), saves, and
## returns the compute_ash() breakdown plus "achievements" (newly unlocked
## ids), "bounty" and "new_total" for the end screen / autotest summary.
func award_run(summary: Dictionary, mods: MetaModifiers) -> Dictionary:
	var award := compute_ash(summary, mods.value("ash_gain") if mods != null else 0.0)
	var st: Dictionary = summary.get("stats", {})
	_add_lifetime("runs", 1.0)
	_add_lifetime("victories", 1.0 if bool(summary.get("victory", false)) else 0.0)
	_add_lifetime("total_kills", float(summary.get("kills", 0)))
	_add_lifetime("boss_kills", 1.0 if bool(summary.get("boss_defeated", false)) else 0.0)
	_add_lifetime("warrior_kills", float(st.get("warrior_kills", 0.0)))
	_add_lifetime("chaplain_kills", float(st.get("kill_chaplain", 0.0)))
	_add_lifetime("boss_kills_full_army", float(st.get("boss_kill_full_army", 0.0)))
	_add_lifetime("ash_earned", float(award["total"]))
	lifetime["best_time"] = maxf(float(lifetime["best_time"]), float(summary.get("time", 0.0)))
	lifetime["best_reckoning"] = maxf(float(lifetime["best_reckoning"]), float(summary.get("time_past_zero", 0.0)))
	var unlocked := PackedStringArray()
	var bounty := 0
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var def: Dictionary = MetaData.ACHIEVEMENTS[id]
		if not achievements.has(id) and float(lifetime.get(String(def["stat"]), 0.0)) >= float(def["goal"]):
			achievements[id] = true
			unlocked.append(id)
			bounty += int(def["bounty"])
	_add_lifetime("ash_earned", float(bounty))
	soul_ash = mini(soul_ash + int(award["total"]) + bounty, MAX_STORED)
	award["achievements"] = unlocked
	award["bounty"] = bounty
	award["new_total"] = soul_ash
	last_award = award
	save()
	changed.emit()
	return award


# =====================================================================================
# Shop (Ossuary)
# =====================================================================================

## Purchased tier of upgrade `id`.
func tier(id: String) -> int:
	return int(tiers.get(id, 0))


## True when upgrade `id` has every tier.
func is_maxed(id: String) -> bool:
	return tier(id) >= MetaData.max_tier(id)


## True when the prerequisite of upgrade `id` is met (or it has none).
func prerequisite_met(id: String) -> bool:
	var req: Dictionary = MetaData.UPGRADES[id]["requires"]
	return req.is_empty() or tier(String(req["id"])) >= int(req["tier"])


## Price of the next tier of `id` (-1 when maxed).
func next_cost(id: String) -> int:
	return -1 if is_maxed(id) else MetaData.tier_cost(id, tier(id) + 1)


## Why `id` cannot be bought right now: "" (it can), "maxed", "locked"
## (prerequisite missing) or "cost" (not enough Soul Ash).
func purchase_block(id: String) -> String:
	if is_maxed(id):
		return "maxed"
	if not prerequisite_met(id):
		return "locked"
	if soul_ash < next_cost(id):
		return "cost"
	return ""


## Buys the next tier of `id` and saves. Returns false if it was blocked.
func purchase(id: String) -> bool:
	if not MetaData.UPGRADES.has(id) or purchase_block(id) != "":
		return false
	soul_ash -= next_cost(id)
	tiers[id] = tier(id) + 1
	save()
	changed.emit()
	return true


## Soul Ash currently invested in upgrades.
func spent_total() -> int:
	var total := 0
	for id: String in MetaData.UPGRADE_ORDER:
		total += MetaData.cost_up_to(id, tier(id))
	return total


## Respec: refunds every purchased tier in full, saves and returns the refund.
func refund_all() -> int:
	var refund := spent_total()
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = 0
	soul_ash = mini(soul_ash + refund, MAX_STORED)
	save()
	changed.emit()
	return refund


# =====================================================================================
# Save / load
# =====================================================================================

## False in the autotest (unless --meta-save), so tests never touch user://.
func can_write() -> bool:
	return not GameState.autotest or GameState.autotest_meta_save


## Writes everything to save_path (temp file + rename, so a crash mid-write
## cannot corrupt the old save). Skipped (returns OK) when can_write() is false.
func save() -> Error:
	if not can_write():
		return OK
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "save_version", MetaData.SAVE_VERSION)
	cfg.set_value("currency", "soul_ash", soul_ash)
	for id: String in MetaData.UPGRADE_ORDER:
		cfg.set_value("upgrades", id, tier(id))
	for key: String in lifetime:
		cfg.set_value("lifetime", key, lifetime[key])
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		cfg.set_value("achievements", id, achievements.has(id))
	var tmp := save_path + ".tmp"
	var err := cfg.save(tmp)
	if err != OK:
		return cfg.save(save_path)
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		DirAccess.remove_absolute(tmp)
		return cfg.save(save_path)
	return OK


## Loads save_path into memory (see the header for the recovery rules).
func load_save() -> void:
	_reset()
	var cfg := ConfigFile.new()
	last_load_error = cfg.load(save_path)
	if last_load_error == ERR_FILE_NOT_FOUND:
		load_status = "missing"
		changed.emit()
		return
	if last_load_error != OK:
		load_status = "corrupt"
		print("[meta] %s is unreadable (error %d); starting a fresh profile" % [save_path, last_load_error])
		if can_write() and DirAccess.copy_absolute(save_path, save_path + ".corrupt") == OK:
			print("[meta] the unreadable file was kept as %s.corrupt" % save_path)
		changed.emit()
		return
	var version := _read_int(cfg, "meta", "save_version", 0)
	_migrate(cfg, version)
	soul_ash = _read_int(cfg, "currency", "soul_ash", 0)
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = mini(_read_int(cfg, "upgrades", id, 0), MetaData.max_tier(id))
	for key: String in lifetime:
		lifetime[key] = _read_float(cfg, "lifetime", key, float(lifetime[key]))
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var v: Variant = cfg.get_value("achievements", id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			achievements[id] = true
	_enforce_prerequisites()
	if version > MetaData.SAVE_VERSION:
		load_status = "newer"
	elif version < MetaData.SAVE_VERSION:
		load_status = "migrated"
	else:
		load_status = "ok"
	changed.emit()


## Upgrades an older save layout in `cfg` (in memory) to SAVE_VERSION.
## Version 0 is a file without a save_version key; it has the version-1
## layout, so nothing moves. Future layout changes add one step per version
## here (rename / convert keys), so old saves keep loading.
func _migrate(cfg: ConfigFile, from_version: int) -> void:
	if from_version < 1:
		cfg.set_value("meta", "save_version", 1)


## Refunds tiers whose prerequisite is not met (a hand-edited save or a
## data change), repeating until every remaining tier is valid.
func _enforce_prerequisites() -> void:
	var changed_any := true
	while changed_any:
		changed_any = false
		for id: String in MetaData.UPGRADE_ORDER:
			if tier(id) > 0 and not prerequisite_met(id):
				soul_ash = mini(soul_ash + MetaData.cost_up_to(id, tier(id)), MAX_STORED)
				tiers[id] = 0
				changed_any = true


## Clears every persistent value to a fresh profile (in memory only).
func _reset() -> void:
	soul_ash = 0
	tiers = {}
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = 0
	lifetime = _default_lifetime()
	achievements = {}
	last_award = {}
	load_status = "fresh"


## Lifetime statistic keys and their starting values.
static func _default_lifetime() -> Dictionary:
	return {
		"runs": 0.0,  # runs finished (won or lost)
		"victories": 0.0,  # runs that survived the countdown
		"best_time": 0.0,  # longest run, seconds
		"best_reckoning": 0.0,  # most seconds survived past 0:00
		"total_kills": 0.0,  # enemies slain over all runs
		"boss_kills": 0.0,  # Sir Alaric kills
		"warrior_kills": 0.0,  # killing blows by Skeleton Warriors (achievement)
		"chaplain_kills": 0.0,  # Covenant Chaplains slain (achievement)
		"boss_kills_full_army": 0.0,  # boss kills with all 4 classes (achievement)
		"ash_earned": 0.0,  # Soul Ash earned in total (runs + bounties)
	}


## Adds `amount` to lifetime counter `key`.
func _add_lifetime(key: String, amount: float) -> void:
	lifetime[key] = minf(float(lifetime.get(key, 0.0)) + amount, float(MAX_STORED))


## Reads a non-negative int; wrong types fall back to `default`.
static func _read_int(cfg: ConfigFile, section: String, key: String, default: int) -> int:
	var v: Variant = cfg.get_value(section, key, default)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return default
	var f := float(v)
	if is_nan(f) or is_inf(f):
		return default
	return clampi(int(f), 0, MAX_STORED)


## Reads a non-negative float; wrong types fall back to `default`.
static func _read_float(cfg: ConfigFile, section: String, key: String, default: float) -> float:
	var v: Variant = cfg.get_value(section, key, default)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return default
	var f := float(v)
	if is_nan(f) or is_inf(f):
		return default
	return clampf(f, 0.0, float(MAX_STORED))
