## DevourersHour — THE DEVOURER'S HOUR, the Necropolis Dynasty's Reckoning
## (temporary Act XII; GDD §15.0 "The Devourer's Hour"; owner-approved
## proposal: "at 0:00 every sarcophagus in the necropolis opens: Rebirth has
## no limit, the Sandstorm becomes permanent, and a huge shadow, the Devourer,
## sweeps telegraphed lanes across the map, eating every corpse and unit in
## them"), owned by Game.dynasty as `devourer`. On a stage whose RECKONING has
## a "devourers_hour" dictionary (its keys override
## DynastyRulesData.DEVOURER; absent = off), from 0:00:
##   * REBIRTH UNLIMITED: Rebirth.unlimited (a body returns any number of times);
##   * THE ENDLESS STORM: Sandstorm.start_endless();
##   * THE LANES: every lane_every s (shorter each minute) a lane crosses the
##     view through a point near a standing necromancer at a seeded angle: a
##     telegraphed line (EffectManager.telegraph_line(), the shared look) for
##     lane_warn s, then the Devourer's shadow runs along it in lane_sweep s:
##     every summon it passes takes summon_damage, the necromancer
##     lane_damage (x the time scaling; Grave Step's i-frames dodge it), once
##     per lane, and every cartouche it passes is EATEN (Rebirth.eat(): no
##     return). The army is the Reckoning's prey; the Dynasty's own are spared;
##   * the opened tombs: the RECKONING's "kind" (the khopesh guard) and its
##     companions are spawned by EnemyDirector like every Reckoning.
## Drawn: the shadow (dark disc textures with two carnelian eyes) running
## along each sweeping lane, z 16. Determinism: the seeded gameplay RNG only
## (which necromancer, the angle, the offset), and only on a Dynasty stage.
## Stats: devourer_lanes, devourer_summon_hits, devourer_summon_dmg,
## devourer_player_hits, devourer_lanes_refused.
class_name DevourersHour
extends Node2D

## Owning run.
var game: Game
## The Devourer's Hour's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the Hour began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Lanes swept.
var lanes_swept: int = 0
## Live lanes: [from (Vector2), to (Vector2), game time the sweep starts,
## summons already struck (Dictionary unit -> true), necromancers struck
## (Dictionary), the shadow's progress 0..1].
var lanes: Array = []
## Game time (s) of the next lane.
var _next_lane: float = INF
## True when this build draws (never headless).
var _draws: bool = false
## Ally query buffer.
var _tmp: Array = []


## Builds the Hour for `p_game`; `enabled`: a Dynasty stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	name = "DevourersHour"
	z_index = 16  # Over the units; under the storm's veil.
	z_as_relative = false
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("devourers_hour"):
		cfg = DynastyRulesData.DEVOURER.duplicate()
		var over: Dictionary = r["devourers_hour"]
		for key: String in over:
			cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


## True while the Hour runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per-tick update (DynastyRules.step()).
func step(delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			started = true
			started_at = game.elapsed
			_next_lane = game.elapsed + float(cfg["lane_first"])
			game.dynasty.rebirth.unlimited = true
			game.dynasty.sandstorm.start_endless()
		return
	if game.elapsed >= _next_lane:
		_next_lane = game.elapsed + _lane_interval()
		_open_lane()
	_sweep(delta)
	if _draws and (not lanes.is_empty()):
		queue_redraw()


## Seconds until the next lane: lane_every, shorter by lane_step each minute
## past 0:00, never below lane_every_min.
func _lane_interval() -> float:
	var minutes := floorf((game.elapsed - started_at) / 60.0)
	return maxf(float(cfg["lane_every_min"]), float(cfg["lane_every"]) - float(cfg["lane_step"]) * minutes)


## A lane opens across a standing necromancer (the seeded gameplay RNG).
func _open_lane() -> void:
	if lanes.size() >= int(cfg["max_lanes"]):
		game.stat_add("devourer_lanes_refused", 1.0)
		return
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var a := randf() * TAU
	var off := randf_range(-float(cfg["lane_offset"]), float(cfg["lane_offset"]))
	var dir := Vector2.from_angle(a)
	var mid := pl.position + dir.orthogonal() * off  # The lane's middle.
	var half := float(cfg["lane_length"]) * 0.5
	var from := mid - dir * half
	var to := mid + dir * half
	var warn := float(cfg["lane_warn"])
	lanes.append([from, to, game.elapsed + warn, {}, {}, 0.0])
	game.effects.telegraph_line(from, to, float(cfg["lane_width"]), warn)
	game.dynasty.play_sound("devourer_lane", pl.position, 0.5)


## Runs every live lane's shadow: what it passes is struck once, cartouches
## are eaten; a lane whose shadow reached its end closes.
func _sweep(delta: float) -> void:
	var now := game.elapsed
	var i := lanes.size() - 1
	while i >= 0:
		var ln: Array = lanes[i]
		if now < float(ln[2]):
			i -= 1
			continue
		var from: Vector2 = ln[0]
		var to: Vector2 = ln[1]
		var prev := float(ln[5])
		var k := minf(1.0, prev + delta / maxf(float(cfg["lane_sweep"]), 0.05))
		ln[5] = k
		_strike_segment(ln, from.lerp(to, prev), from.lerp(to, k))
		if k >= 1.0:
			lanes.remove_at(i)
			lanes_swept += 1
			game.stat_add("devourer_lanes", 1.0)
		i -= 1


## Strikes everything within half the lane's width of the stretch a..b the
## shadow covered this tick.
func _strike_segment(ln: Array, a: Vector2, b: Vector2) -> void:
	var half_w := float(cfg["lane_width"]) * 0.5
	var mid := (a + b) * 0.5
	var reach := a.distance_to(b) * 0.5 + half_w
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var hit_units: Dictionary = ln[3]
	game.ally_grid.query(mid, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or hit_units.has(u):
			continue
		if Geometry2D.get_closest_point_to_segment(u.position, a, b).distance_to(u.position) <= half_w + u.radius:
			hit_units[u] = true
			var dmg := float(cfg["summon_damage"]) * ts
			game.combat.damage_unit(u, dmg, DynastyRulesData.DEVOURER_SOURCE)
			game.stat_add("devourer_summon_hits", 1.0)
			game.stat_add("devourer_summon_dmg", dmg)
	var hit_players: Dictionary = ln[4]
	for pl in game.all_players:
		if pl.dead or hit_players.has(pl):
			continue
		if Geometry2D.get_closest_point_to_segment(pl.position, a, b).distance_to(pl.position) <= half_w + pl.radius:
			hit_players[pl] = true
			game.combat.damage_player(float(cfg["lane_damage"]) * ts, DynastyRulesData.DEVOURER_SOURCE, pl)
			game.stat_add("devourer_player_hits", 1.0)
	var rb := game.dynasty.rebirth
	var j := rb.cartouches.size() - 1
	while j >= 0:
		var c := rb.cartouches[j]
		if c.active and Geometry2D.get_closest_point_to_segment(c.position, a, b).distance_to(c.position) <= half_w + c.radius:
			rb.eat(c)
			game.dynasty.play_sound("devourer_eat", c.position, 0.2)
		j -= 1


## The autotest autopilot's push out of every lane that is showing or sweeping.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var half_w := float(cfg.get("lane_width", 0.0)) * 0.5 + 24.0
	for ln in lanes:
		var a: Vector2 = ln[0]
		var b: Vector2 = ln[1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var off := p - q
		var d := off.length()
		if d < half_w:
			var n := off / d if d > 0.01 else (b - a).normalized().orthogonal()
			push += n * (1.0 - d / half_w)
	return push


## The Devourer's shadow on every sweeping lane (dark discs and two eyes).
func _draw() -> void:
	var now := game.elapsed
	var w := float(cfg.get("lane_width", 96.0))
	for ln in lanes:
		if now < float(ln[2]):
			continue
		var from: Vector2 = ln[0]
		var to: Vector2 = ln[1]
		var p := from.lerp(to, float(ln[5]))
		var dir := (to - from).normalized()
		for s in 3:
			var c := p - dir * float(s) * w * 0.45
			var r := w * (0.62 - 0.12 * float(s))
			draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.DYN_INK, 0.55 - 0.12 * float(s)))
		var side := dir.orthogonal() * w * 0.16
		for e in [p + dir * w * 0.25 + side, p + dir * w * 0.25 - side]:
			draw_texture_rect(SpriteBank.disc(), Rect2(e - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), false, Palette.DYN_CARNELIAN)
