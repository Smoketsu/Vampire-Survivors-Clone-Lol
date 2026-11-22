## SpringReturns — SPRING RETURNS, the Reckoning of the Turning Year
## (temporary Act XV; GDD §15.0 "Spring Returns"; owner-approved proposal:
## "Reckoning | Spring Returns | Everything grows back at once and buries the
## dead | All of them"), owned by Game.wild as `returns`. On a stage whose
## RECKONING has a "spring_returns" dictionary (its keys override
## WildRulesData.SPRING_RETURNS; absent = off), from 0:00:
##   * EVERYTHING GROWS BACK: the blight is wiped at once (BloomField.wipe()),
##     and SeasonCycle's season is RETURNS (its banner, the green tint);
##   * THE ROOTS grab whatever stands still `still_time` s (Spring's halved;
##     SeasonCycle reads still_time());
##   * THICKETS SPROUT: every `sprout_every` s, `sprouts` seeds on a ring
##     `sprout_ring` px round each standing necromancer that grow in
##     `sprout_grow` s (Thickets.plant(), the one planting path);
##   * THE DEAD ARE BURIED: corpses last `corpse_life` s (SeasonCycle.
##     corpse_life()), and every `bury_every` s the earth pulls down `bury`
##     seeded summons: `bury_summon` damage (x the time scaling) and a
##     `bury_hold` s hold;
## while the RECKONING's "kind" (the Treant) and its companions (all of them)
## are spawned by EnemyDirector like every Reckoning. Determinism: game time
## and the seeded gameplay RNG (the ring's angle, the buried summons). Stats:
## returns_sprouts, returns_burials, returns_bury_dmg.
class_name SpringReturns
extends RefCounted

## Owning run.
var game: Game
## Spring Returns' numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and spring returned.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Sproutings this run.
var sproutings: int = 0
## Summons buried this run.
var buried: int = 0
## Game time (s) of the next sprouting.
var _next_sprout: float = INF
## Game time (s) of the next burial.
var _next_bury: float = INF


## Builds Spring Returns for `p_game`; `enabled`: a Wild stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("spring_returns"):
		cfg = WildRulesData.SPRING_RETURNS.duplicate()
		var over: Dictionary = r["spring_returns"]
		for key: String in over:
			cfg[key] = over[key]


## True when this stage's Reckoning is Spring Returns.
func on() -> bool:
	return not cfg.is_empty()


## True while Spring Returns runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Seconds of stillness before the roots grab during Spring Returns.
func still_time() -> float:
	return float(cfg.get("still_time", WildRulesData.ROOTS["still_time"]))


## Per tick (WildRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	var now := game.elapsed
	if not started:
		if game.countdown_finished():
			started = true
			started_at = now
			game.wild.bloom.wipe()
			_next_sprout = now + float(cfg["first"])
			_next_bury = now + float(cfg["first"])
		return
	if now >= _next_sprout:
		_next_sprout = now + float(cfg["sprout_every"])
		_sprout()
	if now >= _next_bury:
		_next_bury = now + float(cfg["bury_every"])
		_bury()


## A ring of seeds round each standing necromancer.
func _sprout() -> void:
	var n := maxi(1, int(cfg["sprouts"]))
	var a0 := randf() * TAU
	for pl in game.all_players:
		if pl.dead:
			continue
		for k in n:
			var at := pl.position + Vector2.from_angle(a0 + TAU * float(k) / float(n)) * float(cfg["sprout_ring"])
			game.wild.thickets.plant(at, float(cfg["sprout_grow"]), "spring_returns")
	sproutings += 1
	game.stat_add("returns_sprouts", 1.0)


## The earth pulls down `bury` seeded summons (see the header).
func _bury() -> void:
	var pool: Array[SummonedUnit] = []
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD and not u.airborne and not u.flies:
				pool.append(u)
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var hold := float(cfg["bury_hold"]) * game.wild.deadwood_mult()
	for _k in mini(int(cfg["bury"]), pool.size()):
		var u: SummonedUnit = pool.pop_at(randi() % pool.size())
		var dmg := float(cfg["bury_summon"]) * ts
		u.held_until = maxf(u.held_until, game.elapsed + hold)
		game.combat.damage_unit(u, dmg, WildRulesData.BURY_SOURCE)
		buried += 1
		game.stat_add("returns_burials", 1.0)
		game.stat_add("returns_bury_dmg", dmg)
		game.wild.play_sound("bury", u.position, 0.3)
