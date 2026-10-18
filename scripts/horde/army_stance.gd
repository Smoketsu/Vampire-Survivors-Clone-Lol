## ArmyStance — the army's formation for ONE run (StanceData; GDD §15.0 "Bone Ring is the
## only formation"). Game owns one as `game.stance`; every run holds the Bone Ring (the
## owner removed the other stances and the switching, Oct 2026).
##   * Numbers: the horde director reads the formation's overrides here
##     (engage_radius(), soft_recall(), formation_pull(), jitter(), shape()) in its
##     effective-stat and formation code; bonus() returns the flavour bonus only while
##     StanceData.BONUSES_ENABLED.
##   * Summary stats (autotest): time, kills, army damage taken, hard recalls and the
##     largest / mean unit distance from the necromancer. They live here, NOT in
##     game.stats.
## No RNG anywhere: runs stay deterministic per seed.
class_name ArmyStance
extends RefCounted

## Owning run.
var game: Game
## Current formation id (StanceData.ORDER; always the Bone Ring).
var current: String = StanceData.DEFAULT_ID
## Formation id -> {"time", "kills", "army_dmg", "recalls", "max_spread", "spread_sum",
## "spread_n"} (see _new_bucket()).
var per_stance: Dictionary = {}
## game.kills at the previous step (kill attribution).
var _last_kills: int = 0
## damage_to_summons stat at the previous step (army damage attribution).
var _last_army_dmg: float = 0.0
## horde.hard_recalls at the previous step.
var _last_recalls: int = 0
## Game time of the next army-spread sample.
var _next_spread: float = 0.0


func _init(p_game: Game) -> void:
	game = p_game
	for id: String in StanceData.ORDER:
		per_stance[id] = _new_bucket()


## Empty per-formation stats bucket.
static func _new_bucket() -> Dictionary:
	return {"time": 0.0, "kills": 0, "army_dmg": 0.0, "recalls": 0, "max_spread": 0.0,
		"spread_sum": 0.0, "spread_n": 0}


# =====================================================================================
# Numbers read by the horde director
# =====================================================================================

## Definition of the formation (StanceData.STANCES row).
func def() -> Dictionary:
	return StanceData.def(current)


## Formation shape ("ring").
func shape() -> String:
	return String(def()["shape"])


## Engagement / chase leash (px) before Bound Souls.
func engage_radius() -> float:
	return float(def()["engage_radius"])


## Soft-recall distance (px) before Bound Souls.
func soft_recall() -> float:
	return float(def()["soft_recall"])


## Multiplier on every class's formation pull (w_formation).
func formation_pull() -> float:
	return float(def()["formation_pull"])


## Multiplier on the per-unit angular jitter of formation posts.
func jitter() -> float:
	return float(def()["jitter"])


## Flavour bonus `key` of the formation (0 while the bonuses are off or it has none).
## Key: damage_taken_reduction.
func bonus(key: String) -> float:
	if not StanceData.BONUSES_ENABLED:
		return 0.0
	return float((def()["bonus"] as Dictionary).get(key, 0.0))


# =====================================================================================
# Per-tick bookkeeping
# =====================================================================================

## Called by Game every physics tick (before the horde): the summary stats. No gameplay
## effect.
func step(delta: float) -> void:
	var b: Dictionary = per_stance[current]  # Stats bucket of the formation.
	b["time"] = float(b["time"]) + delta
	b["kills"] = int(b["kills"]) + (game.kills - _last_kills)
	_last_kills = game.kills
	var dmg := float(game.stats.get("damage_to_summons", 0.0))  # Army damage taken so far.
	b["army_dmg"] = float(b["army_dmg"]) + (dmg - _last_army_dmg)
	_last_army_dmg = dmg
	b["recalls"] = int(b["recalls"]) + (game.horde.hard_recalls - _last_recalls)
	_last_recalls = game.horde.hard_recalls
	if game.elapsed >= _next_spread:
		_next_spread = game.elapsed + StanceData.SPREAD_SAMPLE
		_sample_spread(b)


## Records the largest and the mean unit distance from the necromancer.
func _sample_spread(b: Dictionary) -> void:
	var p := game.player.position
	var far := 0.0  # Largest distance this sample (px).
	var sum := 0.0  # Sum of distances this sample (px).
	var n := 0  # Units sampled.
	for u in game.horde.units:
		if not u.active:
			continue
		var d := u.position.distance_to(p)
		far = maxf(far, d)
		sum += d
		n += 1
	if n == 0:
		return
	b["max_spread"] = maxf(float(b["max_spread"]), far)
	b["spread_sum"] = float(b["spread_sum"]) + sum / float(n)
	b["spread_n"] = int(b["spread_n"]) + 1


## One summary line (autotest).
func summary_line() -> String:
	var parts := PackedStringArray()
	for id: String in StanceData.ORDER:
		var b: Dictionary = per_stance[id]
		var mean := float(b["spread_sum"]) / float(b["spread_n"]) if int(b["spread_n"]) > 0 else 0.0  # Mean unit distance (px).
		parts.append("%s: %.0fs kills %d army_dmg %d recalls %d spread max %.0f mean %.0f" % [
			id, float(b["time"]), int(b["kills"]), int(b["army_dmg"]), int(b["recalls"]),
			float(b["max_spread"]), mean])
	return " | ".join(parts)
