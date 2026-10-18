## TideDirector — Gullhaven Harbour's tide (Act II, GDD §15.0 "Gullhaven Harbour
## (Act II phase 2)"; owner-approved proposal "The tide rises on the clock and
## floods the lanes"), owned and stepped by EnemyDirector on a stage whose
## StageRegistry "tide" config is not empty (HarbourStage.TIDE; null, and so
## inert, everywhere else). Data: HarbourStage.TIDE.
##   * The water: the town has a fixed ground height h(p) (height()); a point
##     is under water while h(p) is below the tide `level`, which rises on the
##     clock (TIDE "levels" keyframes), so each zone floods more of it. In the
##     Seawall zone only a long strip of dry stone along x stays dry (and a
##     few islands), with the sea edge as its wall.
##   * Water slows everyone in it by TIDE "slow" (the undead and the
##     necromancer through TerrainSlow, the one ground-slow path where
##     Brinewalker applies; enemies through Enemy.apply_slow()), except the
##     swimmers (TIDE "swimmers": Deep Kin and their kin, and Abbot Merrow),
##     checked every TIDE "tick" s for every body.
##   * Tide surges: every TIDE.surge "interval" s from "first", a band through
##     a point near the necromancer is telegraphed, then a wave front sweeps
##     along it: bodies it passes are shoved along the band (the necromancer
##     less, never during a Grave Step), and the band behind the front stays
##     flooded for a while.
##   * High Water (start_high_water()): Abbot Merrow at low HP, and the
##     Reckoning (TIDE "reckoning_flood"), call the tide in: the dry strip
##     shrinks to the seawall's top, easing over TIDE.high_water "ease" s.
##   * Piers (add_pier()): HarbourDirector's piers stay dry.
## Drawn by one rect around the necromancer through tide_water.gdshader, which
## computes the same water test on the GPU from the uniforms set here every
## frame (purely visual). Deterministic: game time only; the surge placement
## uses the seeded global RNG (only on this stage). Stats: tide_player_wet_s,
## tide_summon_wet_s (summon-seconds), tide_enemy_wet_s (enemy-seconds),
## tide_swimmer_s, tide_surges, tide_surge_shoved_summons / _enemies /
## _player, tide_high_water.
class_name TideDirector
extends Node2D

## Surge phase: no surge running.
const SURGE_NONE: int = 0
## Surge phase: the band is telegraphed.
const SURGE_TELEGRAPH: int = 1
## Surge phase: the wave front sweeps along the band.
const SURGE_SWEEP: int = 2
## Surge phase: the band stays flooded behind the passed wave.
const SURGE_LINGER: int = 3
## Most dry piers at once (the shader's pier uniform arrays hold 4).
const MAX_PIERS: int = 4
## Margin (px) of the drawn water rect beyond half the visible area.
const DRAW_MARGIN: float = 240.0
## World px per drawn water pixel (the pixel-art grid of the water).
const ART_PX: float = 2.0
## h units per px when the Seawall strip's distance is compared with the
## height field (only shapes the waterline's foam band; any small value works).
const PX_TO_H: float = 0.002
## Seconds a surge's lingering water takes to fade out at its end (visual and
## gameplay: the band is dry again once it has faded).
const SURGE_FADE: float = 1.5

## Owning run.
var game: Game
## The stage's tide config (HarbourStage.TIDE).
var config: Dictionary = {}
## Current tide level (h units): ground lower than this is flooded.
var level: float = 0.0
## True once the Seawall zone started (only the dry strip stays dry).
var seawall: bool = false
## World y (px) of the dry strip's centre line now (eases during High Water).
var strip_y: float = 0.0
## Half width (px) of the dry strip now.
var strip_half: float = 0.0
## World y (px) of the sea edge of the seawall (fixed once the zone started).
var wall_y: float = 0.0
## True once the tide was called in (High Water or the Reckoning).
var high_water: bool = false
## Game time High Water began (-1 = never; easing of the strip).
var high_water_at: float = -1.0
## Who called it ("merrow", "reckoning"; summary).
var high_water_by: String = ""
## Current surge phase (SURGE_*).
var surge_phase: int = SURGE_NONE
## Seconds spent in the current surge phase.
var surge_time: float = 0.0
## Surge band centre (world px).
var surge_center: Vector2 = Vector2.ZERO
## Surge sweep direction (unit).
var surge_dir: Vector2 = Vector2.RIGHT
## Distance (px) of the wave front from the band centre along surge_dir.
var surge_front: float = 0.0
## Game time of the next surge.
var next_surge: float = INF
## Surges run so far.
var surges: int = 0
## Dry piers: [centre, unit direction, half length, half width] each.
var piers: Array = []
## Game time each surge started, "m:ss" (summary).
var surge_times: PackedStringArray = PackedStringArray()
## The water rect drawn through the shader (child; purely visual).
var _water: Node2D = null
## The shader material of `_water` (null when the shader failed to load).
var _mat: ShaderMaterial = null
## Half size (px) of the water rect last drawn.
var _drawn_half: Vector2 = Vector2.ZERO
## Seconds accumulated toward the next water check.
var _tick: float = 0.0
## The surge config (TIDE "surge").
var _surge: Dictionary = {}
## Swimmer kinds (TIDE "swimmers") as a set.
var _swimmers: Dictionary = {}
## SummonedUnit -> generation of every summon the current wave shoved.
var _shoved_units: Dictionary = {}
## Enemy -> generation of every enemy the current wave shoved.
var _shoved_enemies: Dictionary = {}
## True once the current wave shoved the necromancer.
var _shoved_player: bool = false
## Wave front of the previous tick (px along the band).
var _prev_front: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -8  # On the ground, under obstacles (-6) and bodies.
	_surge = config.get("surge", {})
	next_surge = float(_surge.get("first", INF))
	for k: String in config.get("swimmers", []):
		_swimmers[k] = true
	level = level_at(game.elapsed)
	_water = Node2D.new()
	_water.z_index = 0  # Relative to this node (-8 in all).
	_water.draw.connect(_draw_water)
	add_child(_water)
	var shader := load("res://scripts/fx/tide_water.gdshader") as Shader  # The water look.
	if shader != null:
		_mat = ShaderMaterial.new()
		_mat.shader = shader
		_water.material = _mat
		_set_static_uniforms()


# =====================================================================================
# Per-tick update
# =====================================================================================

## Per-tick update, called by EnemyDirector after the MarchDirector.
func step(delta: float) -> void:
	var t := game.elapsed
	level = level_at(t)
	_update_seawall(t)
	if not high_water and bool(config.get("reckoning_flood", false)) and game.enemies.reckoning_wave > 0:
		start_high_water("reckoning")
	_ease_strip(t)
	_step_surge(delta, t)
	_tick += delta
	var tick := float(config["tick"])
	if _tick >= tick:
		_tick -= tick
		_apply_water(tick)


## Tide level at elapsed time `t`: the TIDE "levels" keyframes, linearly
## interpolated, held flat after the last one.
func level_at(t: float) -> float:
	var keys: Array = config["levels"]
	if keys.is_empty():
		return 0.0
	if t <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if t <= float(b[0]):
			var k := (t - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), k)
	return float(keys[keys.size() - 1][1])


## The Seawall zone: from its start time only a strip along x through the
## necromancer stays dry; its sea edge (the wall) is on the +y side.
func _update_seawall(t: float) -> void:
	if seawall:
		return
	var sw: Dictionary = config.get("seawall", {})
	if sw.is_empty() or t < float(sw["start"]):
		return
	_begin_seawall()


## Locks the dry strip on the necromancer's current y.
func _begin_seawall() -> void:
	var sw: Dictionary = config["seawall"]
	seawall = true
	strip_y = game.player.position.y
	strip_half = float(sw["half_width"])
	wall_y = strip_y + strip_half
	game.stat_add("tide_seawall", 1.0)


## High Water (Abbot Merrow at low HP, or the Reckoning): the tide comes in
## and the dry strip shrinks to the seawall's top. Starts the Seawall strip
## first when it was not running (e.g. --boss=merrow early). Once per run.
func start_high_water(by: String) -> void:
	if high_water:
		return
	if not seawall:
		_begin_seawall()
	high_water = true
	high_water_at = game.elapsed
	high_water_by = by
	game.stat_add("tide_high_water", 1.0)
	game.effects.ring(game.player.position, 480.0, config["surge_color"], 1.0)
	Sfx.play("toll", game.player.position, 0.7)


## Eases the dry strip toward the High Water strip (the seawall's top).
func _ease_strip(t: float) -> void:
	if not high_water:
		return
	var sw: Dictionary = config["seawall"]
	var hw: Dictionary = config["high_water"]
	var k := clampf((t - high_water_at) / maxf(0.01, float(hw["ease"])), 0.0, 1.0)  # 0 -> 1 as the tide comes in.
	var full_half := float(sw["half_width"])  # The Seawall strip's half width.
	var hw_half := float(hw["half_width"])  # The seawall top's half width.
	strip_half = lerpf(full_half, hw_half, k)
	strip_y = wall_y - strip_half


# =====================================================================================
# The water test
# =====================================================================================

## Ground height (h units, about 0..1) of world point `p` (TIDE "field";
## tide_water.gdshader height() is the same function).
func height(p: Vector2) -> float:
	var h := 0.5
	for w: Array in config["field"]:
		h += float(w[3]) * sin(p.x * float(w[0]) + p.y * float(w[1]) + float(w[2]))
	return h


## Water depth of `p` (> 0 = under water): the tide or the Seawall strip, the
## surge band behind its wave, and the dry piers (tide_water.gdshader).
func depth(p: Vector2) -> float:
	var h := height(p)
	var s := level - h
	if seawall:
		s = minf(PX_TO_H * (absf(p.y - strip_y) - strip_half), float(config["seawall"]["island_level"]) - h)
	if surge_phase >= SURGE_SWEEP:
		var rel := p - surge_center
		var along := rel.dot(surge_dir)
		var across := rel.dot(Vector2(-surge_dir.y, surge_dir.x))
		if absf(across) <= float(_surge["half_width"]) and absf(along) <= float(_surge["length"]) * 0.5:
			if surge_phase == SURGE_LINGER or along <= surge_front:
				s = maxf(s, 0.02 * _surge_fade())
	for pier: Array in piers:
		var q: Vector2 = p - (pier[0] as Vector2)
		var dir: Vector2 = pier[1]
		if absf(q.dot(dir)) <= float(pier[2]) and absf(q.dot(Vector2(-dir.y, dir.x))) <= float(pier[3]):
			return -1.0
	return s


## True if world point `p` is under water.
func flooded(p: Vector2) -> bool:
	return depth(p) > 0.0


## True if enemy `e` swims (never slowed by the water): a swimmer kind, or a
## stage boss whose arrival id is a swimmer (Abbot Merrow).
func swims(e: Enemy) -> bool:
	if _swimmers.has(e.kind):
		return true
	return e.is_boss and _swimmers.has(String(game.enemies.boss_info.get("id", "")))


## Every body standing in water is slowed (swimmers aside).
func _apply_water(tick: float) -> void:
	var slow := float(config["slow"])  # Speed fraction lost in water.
	var linger := float(config["linger"])  # s a check's slow lasts.
	var p := game.player
	if flooded(p.position):
		if TerrainSlow.slow_player(game, slow, linger) > 0.0:
			game.stat_add("tide_player_wet_s", tick)
		else:
			game.stat_add("tide_player_wet_resisted_s", tick)  # Brinewalker Lv 5.
	var wet_units := 0  # Summons in water this check.
	for u in game.horde.units:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if flooded(u.position) and TerrainSlow.slow_summon(game, u, slow, linger) > 0.0:
			wet_units += 1
	if wet_units > 0:
		game.stat_add("tide_summon_wet_s", float(wet_units) * tick)
	var wet_enemies := 0  # Enemies in water this check.
	var swimming := 0  # Swimmers in water this check.
	for e in game.enemies.active:
		if not e.active or e.is_structure:
			continue
		if not flooded(e.position):
			continue
		if swims(e):
			swimming += 1
			continue
		e.apply_slow(slow, linger)
		wet_enemies += 1
	if wet_enemies > 0:
		game.stat_add("tide_enemy_wet_s", float(wet_enemies) * tick)
	if swimming > 0:
		game.stat_add("tide_swimmer_s", float(swimming) * tick)


## Adds a dry pier centred at `center`, running along unit `dir` for
## 2 x `half_len` px and 2 x `half_w` px wide (HarbourDirector's caches). At
## most MAX_PIERS: the oldest is dropped beyond it.
func add_pier(center: Vector2, dir: Vector2, half_len: float, half_w: float) -> void:
	if piers.size() >= MAX_PIERS:
		piers.remove_at(0)
	piers.append([center, dir.normalized(), half_len, half_w])


## Share (0..1) of the necromancer's surroundings under water now, sampled on
## a 9 x 9 grid over 640 px (HUD line and summary).
func flooded_share() -> float:
	var c := game.player.position
	var n := 0
	for iy in 9:
		for ix in 9:
			if flooded(c + Vector2(float(ix) - 4.0, float(iy) - 4.0) * 80.0):
				n += 1
	return float(n) / 81.0


# =====================================================================================
# Tide surges
# =====================================================================================

## Starts, sweeps, lingers and ends the tide surges.
func _step_surge(delta: float, t: float) -> void:
	if _surge.is_empty():
		return
	match surge_phase:
		SURGE_NONE:
			if t >= next_surge:
				next_surge += float(_surge["interval"])
				_start_surge()
		SURGE_TELEGRAPH:
			surge_time += delta
			if surge_time >= float(_surge["telegraph"]):
				surge_phase = SURGE_SWEEP
				surge_time = 0.0
				surge_front = -float(_surge["length"]) * 0.5
				_prev_front = surge_front
				Sfx.play("catapult_impact", game.player.position, 0.55)
				game.shake(5.0)
		SURGE_SWEEP:
			surge_time += delta
			_prev_front = surge_front
			surge_front += float(_surge["speed"]) * delta
			_shove(_prev_front, surge_front)
			if surge_front >= float(_surge["length"]) * 0.5:
				surge_phase = SURGE_LINGER
				surge_time = 0.0
		SURGE_LINGER:
			surge_time += delta
			if surge_time >= float(_surge["linger"]):
				surge_phase = SURGE_NONE
				surge_time = 0.0


## A new surge: a band through a point within offset_max px of the
## necromancer, sweeping along a random direction (seeded RNG).
func _start_surge() -> void:
	var p := game.player.position
	surge_dir = Vector2.from_angle(randf() * TAU)
	var off := Vector2(-surge_dir.y, surge_dir.x) * randf_range(-1.0, 1.0) * float(_surge["offset_max"])  # Sideways offset of the band.
	surge_center = p + off
	surge_phase = SURGE_TELEGRAPH
	surge_time = 0.0
	surge_front = -float(_surge["length"]) * 0.5
	_shoved_units.clear()
	_shoved_enemies.clear()
	_shoved_player = false
	surges += 1
	var s := int(game.elapsed)
	surge_times.append("%d:%02d" % [floori(float(s) / 60.0), s % 60])
	game.stat_add("tide_surges", 1.0)
	game.enemies.show_banner("A TIDE SURGE rolls in: get out of its path!")
	Sfx.play("toll", p, 0.85)


## Strength (1 -> 0) of the lingering surge water as it fades at its end.
func _surge_fade() -> float:
	if surge_phase != SURGE_LINGER:
		return 1.0
	var left := float(_surge["linger"]) - surge_time  # s of linger left.
	return clampf(left / SURGE_FADE, 0.0, 1.0)


## True if a body at `pos` (radius `r`) lies in the surge band and the front
## passed it between `from` and `to` (px along the band).
func _front_passed(pos: Vector2, r: float, from: float, to: float) -> bool:
	var rel := pos - surge_center
	var along := rel.dot(surge_dir)
	var across := rel.dot(Vector2(-surge_dir.y, surge_dir.x))
	return absf(across) <= float(_surge["half_width"]) + r and along > from - r and along <= to + r


## The wave front moved from `from` to `to`: every body it passed is shoved
## once along the band (bosses, minibosses and structures stand fast; the
## necromancer is not shoved during a Grave Step).
func _shove(from: float, to: float) -> void:
	var push := float(_surge["push"])  # px a summon / enemy is shoved.
	var mid := surge_center + surge_dir * (from + to) * 0.5  # Query centre.
	var reach := float(_surge["half_width"]) + absf(to - from) + UnitData.MAX_BLOCK_RADIUS
	game.ally_grid.query(mid, reach, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or int(_shoved_units.get(u, -1)) == u.generation:
			continue
		if _front_passed(u.position, u.radius, from, to):
			_shoved_units[u] = u.generation
			u.position += surge_dir * push
			game.stat_add("tide_surge_shoved_summons", 1.0)
	game.enemy_grid.query(mid, reach, _tmp)
	for e: Enemy in _tmp:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or int(_shoved_enemies.get(e, -1)) == e.generation:
			continue
		if _front_passed(e.position, e.radius, from, to):
			_shoved_enemies[e] = e.generation
			e.position += surge_dir * push
			game.stat_add("tide_surge_shoved_enemies", 1.0)
	var pl := game.player
	if not _shoved_player and _front_passed(pl.position, pl.radius, from, to):
		_shoved_player = true
		if not game.grave_step.is_dashing() and game.grave_step.dodge_time <= 0.0:
			pl.position += surge_dir * float(_surge["push_player"])
			game.stat_add("tide_surge_shoved_player", 1.0)


# =====================================================================================
# Queries (HUD, autopilot, summary)
# =====================================================================================

## Suffix of the HUD zone line: the tide's state.
func hud_suffix() -> String:
	if high_water:
		return "  |  HIGH WATER"
	if seawall:
		return "  |  High tide"
	return "  |  Tide %d%%" % roundi(flooded_share() * 100.0)


## Autopilot hint: out of a telegraphed surge band (sideways), else zero.
func danger_push(p: Vector2) -> Vector2:
	if surge_phase != SURGE_TELEGRAPH:
		return Vector2.ZERO
	var rel := p - surge_center
	var perp := Vector2(-surge_dir.y, surge_dir.x)
	var across := rel.dot(perp)
	if absf(across) > float(_surge["half_width"]) + 30.0:
		return Vector2.ZERO
	return perp * (1.0 if across >= 0.0 else -1.0)


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "level now %.2f (flooded around you %d%%) | seawall %s | high water %s | surges %d (%s) shoved summons %d, enemies %d, you %d | time in water: you %.0f s (resisted %.0f s), summons %.0f unit-s, enemies %.0f enemy-s, swimmers %.0f s" % [
		level, roundi(flooded_share() * 100.0), "yes" if seawall else "no",
		("yes by %s at %s" % [high_water_by, _clock(high_water_at)]) if high_water else "no",
		surges, ", ".join(surge_times) if not surge_times.is_empty() else "-",
		int(st.get("tide_surge_shoved_summons", 0.0)), int(st.get("tide_surge_shoved_enemies", 0.0)), int(st.get("tide_surge_shoved_player", 0.0)),
		float(st.get("tide_player_wet_s", 0.0)), float(st.get("tide_player_wet_resisted_s", 0.0)), float(st.get("tide_summon_wet_s", 0.0)),
		float(st.get("tide_enemy_wet_s", 0.0)), float(st.get("tide_swimmer_s", 0.0))]


## Game time `t` as "m:ss".
static func _clock(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Drawing (the shader rect; purely visual)
# =====================================================================================

## Keeps the water rect on the necromancer and hands the shader its state.
func _process(_delta: float) -> void:
	if game == null or _water == null:
		return
	_water.position = game.player.position
	var half := game.view_size() * 0.5 + Vector2.ONE * DRAW_MARGIN  # Half the rect (px).
	if not half.is_equal_approx(_drawn_half):
		_drawn_half = half
		_water.queue_redraw()
	if _mat == null:
		return
	_mat.set_shader_parameter("level", level)
	_mat.set_shader_parameter("seawall_on", 1.0 if seawall else 0.0)
	_mat.set_shader_parameter("strip_y", strip_y)
	_mat.set_shader_parameter("strip_half", strip_half)
	_mat.set_shader_parameter("wall_y", wall_y)
	_mat.set_shader_parameter("surge_state", float(surge_phase))
	_mat.set_shader_parameter("surge_center", surge_center)
	_mat.set_shader_parameter("surge_dir", surge_dir)
	_mat.set_shader_parameter("surge_front", surge_front)
	_mat.set_shader_parameter("surge_fade", _surge_fade())
	var pa: Array[Vector4] = []  # Pier centres and directions.
	var pb: Array[Vector4] = []  # Pier half sizes and on flags.
	for i in MAX_PIERS:
		if i < piers.size():
			var pr: Array = piers[i]
			var c: Vector2 = pr[0]
			var d: Vector2 = pr[1]
			pa.append(Vector4(c.x, c.y, d.x, d.y))
			pb.append(Vector4(float(pr[2]), float(pr[3]), 1.0, 0.0))
		else:
			pa.append(Vector4(0.0, 0.0, 1.0, 0.0))
			pb.append(Vector4(0.0, 0.0, 0.0, 0.0))
	_mat.set_shader_parameter("pier_a", pa)
	_mat.set_shader_parameter("pier_b", pb)
	_mat.set_shader_parameter("reduced", 1.0 if Settings.reduced_effects() else 0.0)


## Uniforms that never change during the run (the field, the colours).
func _set_static_uniforms() -> void:
	var waves: Array[Vector4] = []  # The height field's waves.
	for w: Array in config["field"]:
		waves.append(Vector4(float(w[0]), float(w[1]), float(w[2]), float(w[3])))
	while waves.size() < 4:
		waves.append(Vector4.ZERO)
	_mat.set_shader_parameter("waves", waves)
	_mat.set_shader_parameter("island_level", float((config.get("seawall", {}) as Dictionary).get("island_level", 1.0)))
	_mat.set_shader_parameter("px_to_h", PX_TO_H)
	_mat.set_shader_parameter("art_px", ART_PX)
	_mat.set_shader_parameter("surge_half_width", float(_surge.get("half_width", 0.0)))
	_mat.set_shader_parameter("surge_half_length", float(_surge.get("length", 0.0)) * 0.5)
	for key: String in ["water_color", "deep_color", "foam_color", "glint_color", "surge_color"]:
		if config.has(key):
			_mat.set_shader_parameter(key, config[key])


## Draws the water rect (the shader paints it).
func _draw_water() -> void:
	_water.draw_rect(Rect2(-_drawn_half, _drawn_half * 2.0), Color.WHITE)
