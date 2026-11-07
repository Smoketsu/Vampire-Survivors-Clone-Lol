## AmaterasuHazards — the world-space side of AMATERASU, THE SUN GODDESS
## (BossAmaterasu; Act V, the Road to the Sun; GDD §15.0 "Amaterasu, the Sun
## Goddess"): her attacks once she has started them, stepped by her physics
## (gameplay, step()) and drawn here (visual only):
##   * MIRROR BEAMS: a beam from her mirror, telegraphed, then burning while it
##     sweeps; every body it crosses is burnt each mirror_tick s.
##   * SUN-DISC MINES: discs on the ground; armed after mine_arm s, each bursts
##     when a body comes within mine_trigger px or at mine_fuse s.
##   * ZENITH CIRCLES (noon): a column of light falls on each marked circle
##     after zenith_telegraph s.
##   * THE NOON GLARE: it builds glare_windup s (the view whitening), then
##     scorches every body in the open.
##   * THE SETTING-SUN BEAM (sunset): a wide band from her across the arena,
##     telegraphed, then one strike.
##   * NOON SHADE: during noon the obstacles' noon shadows show on the ground
##     (their footprint grown by shade_pad px, shade_offset px south): a body
##     in one (in_shade(), THE one test, the same geometry as the drawing)
##     takes neither the zenith beams nor the glare.
##   * THE FINALE: the dark sun hanging where she fell, fading over
##     finale_time s (BossAmaterasu._on_defeated()).
## Every hit goes through CombatResolver (damage_player() / damage_unit(), the
## AmaterasuData SRC_* tags), x the enemies' time scaling x her buffs. Two
## layers: this node under the bodies (mine discs, the noon shade) and an
## `_over` child above the night's darkness (z 19: beams, columns, the glare,
## the dark sun). Every shape is a texture (the Web GL rule: no polygon is
## redrawn every frame). No shader reads the screen.
## Determinism: no RNG here (BossAmaterasu picks the spots with the seeded
## global RNG); gameplay only in step(), on game time.
class_name AmaterasuHazards
extends Node2D

## Owning run.
var game: Game
## The boss (her data, her position, her buffs).
var boss: BossAmaterasu = null
## Mirror beams: {a0, a1 (rad, start / end angle), t1 (game time the burn
## starts), t2 (it ends), next (next burn tick), length, width}.
var beams: Array[Dictionary] = []
## Sun-disc mines: {pos, t_arm (game time armed), t_fuse (bursts by then)}.
var mines: Array[Dictionary] = []
## Zenith circles: {pos, t_hit (game time the column falls), t0 (marked)}.
var zeniths: Array[Dictionary] = []
## Noon glare: game time it strikes (-1 = none building) and began.
var glare_at: float = -1.0
## Game time the current glare began to build.
var glare_from: float = -1.0
## Setting-sun beams: {from, dir, t_hit, t_end, done}.
var sunsets: Array[Dictionary] = []
## Columns and bursts still showing (visual): {pos, r, t, col}.
var flashes: Array[Dictionary] = []
## True while the noon shade is shown (BossAmaterasu: her noon).
var noon: bool = false
## Game time the finale began (-1 = not yet) and where.
var finale_at: float = -1.0
## Where the dark sun hangs after her fall (world px).
var finale_pos: Vector2 = Vector2.ZERO
## The upper layer (beams, columns, glare, the dark sun).
var _over: Node2D = null
## Soft beam strip texture (white, bright along its middle row), made once.
var _beam_tex: ImageTexture = null
## Reusable query buffer.
var _buf: Array = []


func _ready() -> void:
	z_index = -1  # Mines and the noon shade lie on the ground.
	_over = Node2D.new()
	_over.z_index = 19  # Above the night's darkness (SunCourse z 18), like the Draw lines.
	_over.z_as_relative = false
	add_child(_over)
	_over.draw.connect(_draw_over)


# =====================================================================================
# Starting attacks (BossAmaterasu)
# =====================================================================================

## A mirror beam from her: aimed `a0` rad, sweeping to `a1` while it burns.
func add_beam(a0: float, a1: float) -> void:
	var b := boss.boss_def
	var t1 := game.elapsed + float(b["mirror_telegraph"])
	beams.append({"a0": a0, "a1": a1, "t1": t1, "t2": t1 + float(b["mirror_time"]), "next": t1,
		"length": float(b["mirror_length"]), "width": float(b["mirror_width"])})


## A sun-disc mine at `pos`.
func add_mine(pos: Vector2) -> void:
	var b := boss.boss_def
	mines.append({"pos": pos, "t_arm": game.elapsed + float(b["mine_arm"]), "t_fuse": game.elapsed + float(b["mine_fuse"])})


## A zenith circle at `pos` (its telegraph through EffectManager too).
func add_zenith(pos: Vector2) -> void:
	var b := boss.boss_def
	zeniths.append({"pos": pos, "t0": game.elapsed, "t_hit": game.elapsed + float(b["zenith_telegraph"])})
	game.effects.telegraph_circle(pos, float(b["zenith_radius"]), float(b["zenith_telegraph"]))


## The noon glare starts to build.
func start_glare() -> void:
	glare_from = game.elapsed
	glare_at = game.elapsed + float(boss.boss_def["glare_windup"])


## A setting-sun beam from `from` along `dir`.
func add_sunset(from: Vector2, dir: Vector2) -> void:
	var b := boss.boss_def
	var t_hit := game.elapsed + float(b["sunset_telegraph"])
	sunsets.append({"from": from, "dir": dir, "t0": game.elapsed, "t_hit": t_hit, "t_end": t_hit + float(b["sunset_burn"]), "done": false})


## Every attack ends (her defeat).
func clear_all() -> void:
	beams.clear()
	mines.clear()
	zeniths.clear()
	sunsets.clear()
	glare_at = -1.0
	noon = false


## The dark sun hangs at `pos` where she fell (visual only).
func start_finale(pos: Vector2) -> void:
	finale_at = game.elapsed
	finale_pos = pos


# =====================================================================================
# Gameplay (step)
# =====================================================================================

## Gameplay tick (BossAmaterasu.physics_step()): the beams burn, the mines arm
## and burst, the columns fall, the glare strikes.
func step(_delta: float) -> void:
	var t := game.elapsed
	var b := boss.boss_def
	var mult := game.enemies.damage_mult * boss.hit_mult()  # Time scaling x her buffs.
	# Mirror beams.
	var i := beams.size() - 1
	while i >= 0:
		var bm := beams[i]
		if t >= float(bm["t2"]):
			beams.remove_at(i)
		elif t >= float(bm["next"]):
			bm["next"] = float(bm["next"]) + float(b["mirror_tick"])
			var seg := beam_segment(bm)
			_hit_segment(seg[0], seg[1], float(bm["width"]) * 0.5, float(b["mirror_damage_player"]) * mult, float(b["mirror_damage_summon"]) * mult, AmaterasuData.SRC_MIRROR, false)
		i -= 1
	# Mines.
	i = mines.size() - 1
	while i >= 0:
		var m := mines[i]
		if t >= float(m["t_arm"]) and (t >= float(m["t_fuse"]) or _body_near(m["pos"], float(b["mine_trigger"]))):
			mines.remove_at(i)
			_burst_mine(m["pos"], mult)
		i -= 1
	# Zenith columns.
	i = zeniths.size() - 1
	while i >= 0:
		var z := zeniths[i]
		if t >= float(z["t_hit"]):
			zeniths.remove_at(i)
			var p: Vector2 = z["pos"]
			var r := float(b["zenith_radius"])
			flashes.append({"pos": p, "r": r, "t": t, "col": SunRoadGlyphs.SUN_WHITE})
			_hit_circle(p, r, float(b["zenith_damage_player"]) * mult, float(b["zenith_damage_summon"]) * mult, AmaterasuData.SRC_ZENITH, true)
		i -= 1
	# The glare.
	if glare_at >= 0.0 and t >= glare_at:
		glare_at = -1.0
		_glare(mult)
	# Setting-sun beams.
	i = sunsets.size() - 1
	while i >= 0:
		var s := sunsets[i]
		if not bool(s["done"]) and t >= float(s["t_hit"]):
			s["done"] = true
			var a: Vector2 = s["from"]
			var e: Vector2 = a + (s["dir"] as Vector2) * float(b["sunset_length"])
			game.shake(6.0)
			Sfx.play("sun_beam", a.lerp(e, 0.5))
			_hit_segment(a, e, float(b["sunset_width"]) * 0.5, float(b["sunset_damage_player"]) * mult, float(b["sunset_damage_summon"]) * mult, AmaterasuData.SRC_SUNSET, false)
		if t >= float(s["t_end"]):
			sunsets.remove_at(i)
		i -= 1


## The world segment [from, to] a mirror beam `bm` covers now (from her mirror).
func beam_segment(bm: Dictionary) -> Array:
	var t := game.elapsed
	var k := clampf((t - float(bm["t1"])) / maxf(0.01, float(bm["t2"]) - float(bm["t1"])), 0.0, 1.0)
	var a := lerpf(float(bm["a0"]), float(bm["a1"]), k)
	var from := boss.position
	return [from, from + Vector2.from_angle(a) * float(bm["length"])]


## A disc bursts at `p`.
func _burst_mine(p: Vector2, mult: float) -> void:
	var b := boss.boss_def
	var r := float(b["mine_radius"])
	flashes.append({"pos": p, "r": r, "t": game.elapsed, "col": SunRoadGlyphs.SUN_GOLD})
	Sfx.play("sun_mine", p)
	game.stat_add("amaterasu_mine_bursts", 1.0)
	_hit_circle(p, r, float(b["mine_damage_player"]) * mult, float(b["mine_damage_summon"]) * mult, AmaterasuData.SRC_MINE, false)


## The noon glare strikes every body in the open.
func _glare(mult: float) -> void:
	var b := boss.boss_def
	game.stat_add("amaterasu_glares", 1.0)
	Sfx.play("noon_glare", game.player.position)
	game.shake(5.0)
	for pl in game.all_players:
		if in_shade(pl.position, pl.radius):
			game.stat_add("amaterasu_glare_player_shaded", 1.0)
			continue
		game.combat.damage_player(float(b["glare_damage_player"]) * mult, AmaterasuData.SRC_GLARE, pl)
		game.stat_add("amaterasu_glare_player_hits", 1.0)
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
				continue
			if in_shade(u.position, u.radius):
				game.stat_add("amaterasu_glare_summons_shaded", 1.0)
				continue
			game.combat.damage_unit(u, float(b["glare_damage_summon"]) * mult, AmaterasuData.SRC_GLARE, boss)


## True when a body of radius `r` at `p` is near (within `reach` px edge to edge).
func _body_near(p: Vector2, reach: float) -> bool:
	for pl in game.all_players:
		if pl.position.distance_to(p) <= reach + pl.radius:
			return true
	game.ally_grid.query(p, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(p) <= reach + u.radius:
			return true
	return false


## Hits every body within `half` px of segment a-b (necromancers `dp`, summons
## `du`, tag `src`); with `shade` a body in the noon shade is spared.
func _hit_segment(a: Vector2, b: Vector2, half: float, dp: float, du: float, src: String, shade: bool) -> void:
	for pl in game.all_players:
		if DivineWrath._seg_dist(pl.position, a, b) <= half + pl.radius and not (shade and in_shade(pl.position, pl.radius)):
			game.combat.damage_player(dp, src, pl)
			game.stat_add("amaterasu_player_hits", 1.0)
	var hits: Array = []  # Own buffer (a death hook may query again).
	game.ally_grid.query(a.lerp(b, 0.5), a.distance_to(b) * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, hits)
	for u: SummonedUnit in hits:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if DivineWrath._seg_dist(u.position, a, b) > half + u.radius or (shade and in_shade(u.position, u.radius)):
			continue
		game.combat.damage_unit(u, du, src, boss)
		game.stat_add("amaterasu_summon_hits", 1.0)


## Hits every body within `r` px of `p` (as _hit_segment()).
func _hit_circle(p: Vector2, r: float, dp: float, du: float, src: String, shade: bool) -> void:
	for pl in game.all_players:
		if pl.position.distance_to(p) > r + pl.radius:
			continue
		if shade and in_shade(pl.position, pl.radius):
			game.stat_add("amaterasu_zenith_player_shaded", 1.0)
			continue
		game.combat.damage_player(dp, src, pl)
		game.stat_add("amaterasu_player_hits", 1.0)
	var hits: Array = []  # Own buffer.
	game.ally_grid.query(p, r + UnitData.MAX_BLOCK_RADIUS, hits)
	for u: SummonedUnit in hits:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(p) > r + u.radius or (shade and in_shade(u.position, u.radius)):
			continue
		game.combat.damage_unit(u, du, src, boss)
		game.stat_add("amaterasu_summon_hits", 1.0)


# =====================================================================================
# The noon shade (THE one test; drawn with the same geometry)
# =====================================================================================

## True when a body of radius `r` at `p` stands in an obstacle's noon shadow:
## within the obstacle's footprint grown by shade_pad px (the footprint moved
## shade_offset px south), its centre at least half inside.
func in_shade(p: Vector2, r: float) -> bool:
	return _shade_obstacle(p, r) != null


## The obstacle whose noon shadow holds a body of radius `r` at `p`, or null.
func _shade_obstacle(p: Vector2, r: float) -> Arena.Obstacle:
	var b := boss.boss_def if boss != null else AmaterasuData.BOSS
	var pad := float(b["shade_pad"]) - r * 0.5
	var off := Vector2(0.0, float(b["shade_offset"]))
	var cell := ArenaData.CELL
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var o := game.arena.obstacle_at(Vector2((float(c.x + dx) + 0.5) * cell, (float(c.y + dy) + 0.5) * cell))
			if o == null:
				continue
			if _shade_dist(o, p - off) <= pad:
				return o
	return null


## Distance (px) from `p` to obstacle `o`'s footprint (0 inside).
static func _shade_dist(o: Arena.Obstacle, p: Vector2) -> float:
	if o.is_circle:
		return maxf(0.0, p.distance_to(o.center) - o.radius)
	var q := (p - o.center).abs() - o.half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()


## The centre of the nearest noon shadow within `reach` px of `p` (INF when none):
## the autotest bot walks to it while the glare builds.
func nearest_shade(p: Vector2, reach: float) -> Vector2:
	var cell := ArenaData.CELL
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	var span := ceili(reach / cell)
	var best := Vector2.INF
	var best_d := reach
	var off := Vector2(0.0, float(boss.boss_def["shade_offset"]))
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var o := game.arena.obstacle_at(Vector2((float(c.x + dx) + 0.5) * cell, (float(c.y + dy) + 0.5) * cell))
			if o == null:
				continue
			# The spot just south of the obstacle, inside its shadow.
			var ext := o.radius if o.is_circle else o.half.y
			var spot := o.center + off + Vector2(0.0, ext + float(boss.boss_def["shade_pad"]) * 0.5)
			var dd := p.distance_to(spot)
			if dd < best_d:
				best_d = dd
				best = spot
	return best


# =====================================================================================
# Autopilot hint
# =====================================================================================

## Autopilot hint (the autotest bot): out of the beams, the mines, the marked
## circles and the setting-sun band; into a shadow while the glare builds.
func danger_push(p: Vector2) -> Vector2:
	var b := boss.boss_def
	var push := Vector2.ZERO
	for bm in beams:
		var seg := beam_segment(bm)
		push += KirinKit._off_line(p, seg[0], seg[1], float(bm["width"]) * 0.5 + 26.0)
	for m in mines:
		var off: Vector2 = p - (m["pos"] as Vector2)
		var reach := float(b["mine_radius"]) + 14.0
		if off.length() < reach:
			push += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 1.5
	var shaded := in_shade(p, 12.0)
	for z in zeniths:
		var off: Vector2 = p - (z["pos"] as Vector2)
		var reach := float(b["zenith_radius"]) + 16.0
		if off.length() < reach and not shaded:
			push += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 1.5
	for s in sunsets:
		if bool(s["done"]):
			continue
		var a: Vector2 = s["from"]
		push += KirinKit._off_line(p, a, a + (s["dir"] as Vector2) * float(b["sunset_length"]), float(b["sunset_width"]) * 0.5 + 24.0) * 1.4
	if glare_at >= 0.0 and not shaded:
		var spot := nearest_shade(p, 420.0)
		if spot != Vector2.INF:
			push += (spot - p).normalized() * 1.6
	return push


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

func _process(_delta: float) -> void:
	if game == null:
		return
	var t := game.elapsed
	var i := flashes.size() - 1
	while i >= 0:
		if t - float(flashes[i]["t"]) > 0.5:
			flashes.remove_at(i)
		i -= 1
	queue_redraw()
	_over.queue_redraw()


## The soft beam strip: white, bright along its middle row and fading to its
## edges (made once; drawn stretched and rotated).
func _beam_texture() -> ImageTexture:
	if _beam_tex == null:
		var h := 16  # Rows across the beam.
		var img := Image.create(4, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var k := 1.0 - absf((float(y) + 0.5) / float(h) * 2.0 - 1.0)  # 0 at the edges, 1 in the middle.
			for x in 4:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, k * k * 0.9 + 0.1 * k))
		_beam_tex = ImageTexture.create_from_image(img)
	return _beam_tex


## A band from `a` along unit `dir`, `length` px long and `width` wide, in `col`.
func _band(ci: CanvasItem, a: Vector2, dir: Vector2, length: float, width: float, col: Color) -> void:
	ci.draw_set_transform(a, dir.angle(), Vector2.ONE)
	ci.draw_texture_rect(_beam_texture(), Rect2(0.0, -width * 0.5, length, width), false, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A soft disc of radius `r` at `p` in `col` (the shared disc texture).
static func _disc(ci: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


## Ground layer: the noon shade and the mine discs.
func _draw() -> void:
	if game == null:
		return
	var t := game.elapsed
	if noon and boss != null:
		_draw_shade()
	for m in mines:
		var p: Vector2 = m["pos"]
		var armed := t >= float(m["t_arm"])
		var blink := 0.6 + 0.4 * absf(sin(t * (10.0 if armed else 4.0)))
		_disc(self, p, 10.0, Color(SunRoadGlyphs.SUN_GOLD, 0.85 * blink))
		_disc(self, p, 5.0, Color(SunRoadGlyphs.SUN_WHITE, 0.9))
		if armed:
			_disc(self, p, float(boss.boss_def["mine_radius"]) if boss != null else 40.0, Color(SunRoadGlyphs.SUN_GOLD, 0.08 * blink))


## The obstacles' noon shadows in view (the same geometry as in_shade()).
func _draw_shade() -> void:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	var view := Rect2(c - sz * 0.5, sz).grow(64.0)
	var cell := ArenaData.CELL
	var b := boss.boss_def
	var pad := float(b["shade_pad"])
	var off := Vector2(0.0, float(b["shade_offset"]))
	var k := 1.0
	if glare_at >= 0.0:
		k = 1.0 + 0.5 * absf(sin(game.elapsed * 6.0))  # The shade pulses while the glare builds.
	for cy in range(floori(view.position.y / cell), floori(view.end.y / cell) + 1):
		for cx in range(floori(view.position.x / cell), floori(view.end.x / cell) + 1):
			var o := game.arena._peek(Vector2((float(cx) + 0.5) * cell, (float(cy) + 0.5) * cell))
			if o == null:
				continue
			var ext := o.radius if o.is_circle else maxf(o.half.x, o.half.y)
			var r := ext + pad
			if o.is_circle:
				_disc(self, o.center + off, r, Color(0.04, 0.03, 0.08, minf(0.75, 0.42 * k)))
			else:
				var rect := Rect2(o.center + off - o.half - Vector2(pad, pad), (o.half + Vector2(pad, pad)) * 2.0)
				draw_rect(rect, Color(0.04, 0.03, 0.08, minf(0.6, 0.32 * k)))


## Upper layer: the beams and their warnings, the columns, the glare, the
## setting sun's band, the dark sun of the finale.
func _draw_over() -> void:
	if game == null:
		return
	var t := game.elapsed
	var ci := _over
	for bm in beams:
		var seg := beam_segment(bm)
		var a: Vector2 = seg[0]
		var dir: Vector2 = ((seg[1] as Vector2) - a).normalized()
		if t < float(bm["t1"]):
			var k := 1.0 - (float(bm["t1"]) - t) / maxf(0.01, float(boss.boss_def["mirror_telegraph"]) if boss != null else 1.0)
			_band(ci, a, dir, float(bm["length"]), 3.0 + 3.0 * k, Color(SunRoadGlyphs.SUN_WHITE, 0.35 + 0.35 * k))  # The warning: a thin line thickening.
			var a1 := Vector2.from_angle(float(bm["a1"]))
			_band(ci, a, a1, float(bm["length"]) * 0.5, 2.0, Color(SunRoadGlyphs.SUN_GOLD, 0.25 * k))  # Where the sweep ends.
		else:
			_band(ci, a, dir, float(bm["length"]), float(bm["width"]) * 1.6, Color(SunRoadGlyphs.SUN_GOLD, 0.55))
			_band(ci, a, dir, float(bm["length"]), float(bm["width"]) * 0.7, Color(SunRoadGlyphs.SUN_WHITE, 0.9))
	for z in zeniths:
		var k := clampf((t - float(z["t0"])) / maxf(0.01, float(z["t_hit"]) - float(z["t0"])), 0.0, 1.0)
		var p: Vector2 = z["pos"]
		_band(ci, p + Vector2(0, -260.0), Vector2.DOWN, 260.0, 6.0 + 10.0 * k, Color(SunRoadGlyphs.SUN_WHITE, 0.15 + 0.35 * k))  # The column gathering above it.
	for f in flashes:
		var age := t - float(f["t"])
		var a := clampf(1.0 - age / 0.5, 0.0, 1.0)
		var p: Vector2 = f["pos"]
		_disc(ci, p, float(f["r"]) * (1.0 + 0.3 * age), Color(f["col"] as Color, 0.75 * a))
		_band(ci, p + Vector2(0, -300.0), Vector2.DOWN, 300.0, float(f["r"]) * 0.8, Color(SunRoadGlyphs.SUN_WHITE, 0.5 * a))
	for s in sunsets:
		var a: Vector2 = s["from"]
		var dir: Vector2 = s["dir"]
		var w := float(boss.boss_def["sunset_width"]) if boss != null else 90.0
		var length := float(boss.boss_def["sunset_length"]) if boss != null else 1500.0
		if not bool(s["done"]):
			var k := clampf((t - float(s["t0"])) / maxf(0.01, float(s["t_hit"]) - float(s["t0"])), 0.0, 1.0)
			_band(ci, a, dir, length, w, Color(SunRoadGlyphs.SUN_RED, 0.12 + 0.2 * k))  # The warning band, reddening.
			_band(ci, a, dir, length, 3.0, Color(SunRoadGlyphs.SUN_GOLD, 0.6))
		else:
			var fade := clampf((float(s["t_end"]) - t) / maxf(0.01, float(s["t_end"]) - float(s["t_hit"])), 0.0, 1.0)
			_band(ci, a, dir, length, w * 1.3, Color(SunRoadGlyphs.SUN_RED, 0.7 * fade))
			_band(ci, a, dir, length, w * 0.6, Color(SunRoadGlyphs.SUN_WHITE, 0.85 * fade))
	if glare_at >= 0.0:
		var k := clampf((t - glare_from) / maxf(0.01, glare_at - glare_from), 0.0, 1.0)
		var cam := game.camera
		var zoom := cam.zoom if cam != null else Vector2.ONE
		var sz := get_viewport_rect().size / zoom
		var c := cam.get_screen_center_position() if cam != null else game.player.position
		ci.draw_rect(Rect2(c - sz * 0.5, sz), Color(1.0, 0.97, 0.85, 0.32 * k * k))  # The view whitens as the glare builds.
	if finale_at >= 0.0:
		var life := float(AmaterasuData.BOSS["finale_time"])
		var a := clampf(1.0 - (t - finale_at) / life, 0.0, 1.0)
		if a > 0.0:
			_disc(ci, finale_pos, 70.0, Color(SunRoadGlyphs.SUN_RED, 0.35 * a))  # The last corona.
			_disc(ci, finale_pos, 44.0, Color(0.02, 0.01, 0.03, 0.95 * a))  # The dark sun.
