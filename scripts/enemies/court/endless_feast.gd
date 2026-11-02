## EndlessFeast — THE ENDLESS FEAST, the shared Act VII Reckoning (GDD §15.0
## "Act VII foundation (phase 1)"; owner-approved proposal: "Reckoning, the
## Endless Feast: at 0:00 the Blood Moon rises and never sets; every coffin on
## the map opens, and the Court feeds three times as hard each minute"), owned
## by Game.court as `endless`. On a stage whose RECKONING has an
## "endless_feast" dictionary (its keys override CourtRulesData.ENDLESS_FEAST;
## absent = off), from 0:00:
##   * THE MOON NEVER SETS: BloodMoon.start_endless();
##   * THE FEAST GROWS: feed_mult() = feed_growth ^ (minutes past 0:00),
##     multiplied into every feed by CourtRules.feed_mult() (on top of the
##     moon's own x2);
##   * THE COFFINS OPEN: `coffins` court_coffin structures open around each
##     standing necromancer at 0:00 (seeded angles), then one more around a
##     necromancer every coffin_every s (at most coffin_max standing); each
##     releases vampire nobles on its own clock (CourtCoffinKit). Phase 2's
##     placed coffins (Ravensmoor's sleeping coffins) open the same way
##     through CourtCoffinKit.open_coffin().
## The Reckoning's heavy (the werewolf, a beast at once under the endless moon)
## is the stage's RECKONING "kind", spawned by EnemyDirector like every
## Reckoning.
## Determinism: the seeded gameplay RNG only (coffin angles), only in an Act VII
## Reckoning. Stats: feast_coffins, coffin_nobles (CourtCoffinKit).
class_name EndlessFeast
extends RefCounted

## Owning run.
var game: Game
## The Endless Feast's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the Endless Feast began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Coffins opened by the Endless Feast this run.
var coffins_opened: int = 0
## Standing coffins it opened (stale ones are dropped on each placement).
var coffins: Array[Enemy] = []
## Pool generation of each entry of `coffins`.
var _gens: PackedInt32Array = PackedInt32Array()
## Game time (s) of the next later coffin.
var _next_coffin: float = INF


## Builds the Endless Feast for `p_game` (CourtRules keeps it); `enabled`: an
## Act VII stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("endless_feast"):
		cfg = CourtRulesData.ENDLESS_FEAST.duplicate()
		var over: Dictionary = r["endless_feast"]
		for key: String in over:
			cfg[key] = over[key]


## True while the Endless Feast runs (after 0:00 on a stage that has one).
func running() -> bool:
	return started


## x on every feed now (CourtRules.feed_mult()): feed_growth per minute past
## 0:00, compounding; 1 before (and on every stage without it).
func feed_mult() -> float:
	if not started:
		return 1.0
	return pow(float(cfg["feed_growth"]), maxf(0.0, game.elapsed - started_at) / 60.0)


## Per-tick update (CourtRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			_begin()
		return
	if game.elapsed >= _next_coffin:
		_next_coffin = game.elapsed + float(cfg["coffin_every"])
		var alive := _alive_players()
		if not alive.is_empty():
			var pl: Necromancer = alive[randi() % alive.size()]
			_open_at(pl.position + Vector2.from_angle(randf() * TAU) * float(cfg["coffin_dist"]))


## 0:00: the moon rises for good and the coffins open around each necromancer.
func _begin() -> void:
	started = true
	started_at = game.elapsed
	game.court.moon.start_endless()
	_next_coffin = game.elapsed + float(cfg["coffin_every"])
	var n := int(cfg["coffins"])
	for pl in _alive_players():
		var offset := randf() * TAU
		for k in n:
			_open_at(pl.position + Vector2.from_angle(offset + TAU * float(k) / float(maxi(1, n))) * float(cfg["coffin_dist"]))


## Opens one coffin near world point `at` (free of obstacles), unless
## coffin_max stand.
func _open_at(at: Vector2) -> void:
	var i := coffins.size() - 1
	while i >= 0:
		if not coffins[i].active or coffins[i].generation != _gens[i]:
			coffins.remove_at(i)
			_gens.remove_at(i)
		i -= 1
	if coffins.size() >= int(cfg["coffin_max"]):
		return
	var e := game.enemies.spawn_at(CourtEnemyData.COFFIN, game.arena.free_point(at, 24.0), false)
	if e == null:
		return
	e.is_objective = true  # Never recycled: it stands until broken.
	if e.kit is CourtCoffinKit:
		(e.kit as CourtCoffinKit).open_coffin(e)
	coffins.append(e)
	_gens.append(e.generation)
	coffins_opened += 1
	game.stat_add("feast_coffins", 1.0)


## The standing necromancers.
func _alive_players() -> Array[Necromancer]:
	var out: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			out.append(pl)
	return out
