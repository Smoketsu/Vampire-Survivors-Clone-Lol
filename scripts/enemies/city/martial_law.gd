## MartialLaw — MARTIAL LAW, the shared Act VIII Reckoning (GDD §15.0 "Act
## VIII foundation (phase 1)"; owner-approved proposal: "Reckoning, Martial
## Law: at 0:00 the stars break past five: every tier spawns at once, artillery
## walks across the arena, and every Super the run has met returns"), owned by
## Game.city as `martial`. On a stage whose RECKONING has a "martial_law"
## dictionary (its keys override CityRulesData.MARTIAL_LAW; absent = off), from
## 0:00:
##   * EVERY TIER AT ONCE: the RECKONING's "kind" (the tank) and "companions"
##     (one kind of each tier), spawned by EnemyDirector like every Reckoning;
##   * THE ARTILLERY WALKS: every artillery_every s a line of `shells` landing
##     circles along a street lane through a standing necromancer's street
##     (CityBlocks.lane(); a straight line through him off a blocks stage),
##     `spacing` px apart, each landing `walk` s after the last after a `warn` s
##     telegraph (CityShells, both sides hurt; never civilians);
##   * THE SUPERS RETURN: every super_every s the next Super of
##     SuperRoster.met comes back (SuperRoster.call_super()). On a stage whose
##     run met no Super before 0:00 (Skid Row, Fort Kessler), Martial Law
##     instead calls the act's Supers in turn (`act_supers`: Blitz, Aurora,
##     Atlas, Nightjar) through the same SuperRoster.call_super(), every
##     super_every s, at most `act_super_max` of them standing at once (owner,
##     Nov 2, 2026: "Supers appear in Martial Law on every Act VIII stage";
##     GDD §15.0 "Martial Law brings the Supers to every stage").
## Determinism: the seeded gameplay RNG only (which necromancer, the axis, the
## arrival angle). Stats: martial_lines, martial_shells, martial_supers,
## martial_act_supers.
class_name MartialLaw
extends RefCounted

## Owning run.
var game: Game
## Martial Law's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and Martial Law began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Artillery lines fired.
var lines: int = 0
## Supers that returned.
var supers_back: int = 0
## Game time (s) of the next artillery line.
var _next_line: float = INF
## Game time (s) of the next returning Super.
var _next_super: float = INF
## Index of the next met Super to return.
var _super_i: int = 0
## True when the run had met no Super as Martial Law began: it calls the act's
## Supers (cfg "act_supers") in turn instead of the met list.
var act_roster: bool = false
## Act Supers Martial Law called on such a stage (a subset of supers_back).
var act_called: int = 0


## Builds Martial Law for `p_game`; `enabled`: an Act VIII stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("martial_law"):
		cfg = CityRulesData.MARTIAL_LAW.duplicate()
		var over: Dictionary = r["martial_law"]
		for key: String in over:
			cfg[key] = over[key]


## True while Martial Law runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per-tick update (CityRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			started = true
			started_at = game.elapsed
			_next_line = game.elapsed + float(cfg["artillery_first"])
			_next_super = game.elapsed + 2.0  # The first returning Super right after the banner.
			act_roster = game.city.supers.met.is_empty()  # No Super met: the act's Supers come instead.
		return
	if game.elapsed >= _next_line:
		_next_line += float(cfg["artillery_every"])
		_artillery_line()
	if game.elapsed >= _next_super and act_roster:
		_call_act_super()
	elif game.elapsed >= _next_super:
		_next_super += float(cfg["super_every"])
		var met := game.city.supers.met
		if not met.is_empty():
			var id := met[_super_i % met.size()]
			_super_i += 1
			if game.city.supers.call_super(id, game.enemies.ring_point(randf() * TAU)) != null:
				supers_back += 1
				game.stat_add("martial_supers", 1.0)


## On a stage that met no Super: the act's next Super (cfg "act_supers", in
## turn) through SuperRoster.call_super(), unless `act_super_max` already
## stand (then it looks again after `act_super_retry` s).
func _call_act_super() -> void:
	var ids: Array = cfg["act_supers"]
	if ids.is_empty():
		_next_super = INF
		return
	if game.city.supers.alive_count() >= int(cfg["act_super_max"]):
		_next_super = game.elapsed + float(cfg["act_super_retry"])
		return
	_next_super = game.elapsed + float(cfg["super_every"])
	var id := String(ids[_super_i % ids.size()])
	_super_i += 1
	if game.city.supers.call_super(id, game.enemies.ring_point(randf() * TAU)) != null:
		supers_back += 1
		act_called += 1
		game.stat_add("martial_supers", 1.0)
		game.stat_add("martial_act_supers", 1.0)


## One artillery line through a standing necromancer's street: `shells`
## circles walking along the lane, starting `offset` px behind him.
func _artillery_line() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var dir := Vector2.RIGHT if randf() < 0.5 else Vector2.DOWN
	if randf() < 0.5:
		dir = -dir
	var through := pl.position  # A point on the line.
	var cb := game.arena.city_blocks
	if cb != null:
		var ln := cb.lane(pl.position, dir)
		dir = ln["dir"]
		through = ln["point"]
	var n := int(cfg["shells"])
	var start := through - dir * float(cfg["offset"])
	var dmg := float(cfg["damage"]) * game.enemies.damage_mult * pow(float((game.stage_def["reckoning"] as Dictionary).get("damage_growth", 1.0)), float(game.enemies.reckoning_wave))
	for k in n:
		game.city.shells.add(start + dir * float(cfg["spacing"]) * float(k), float(cfg["warn"]) + float(cfg["walk"]) * float(k),
				float(cfg["radius"]), dmg, CityEnemyData.ARTILLERY_SOURCE, true)
	lines += 1
	game.stat_add("martial_lines", 1.0)
	game.stat_add("martial_shells", float(n))
	game.city.play_sound("siren_wail", pl.position, 1.0)
