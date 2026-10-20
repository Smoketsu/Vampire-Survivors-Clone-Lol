## ChestBeacon: makes treasure chests easy to find (owner request, Oct 2026;
## GDD §15.0 "Chest beacon"; every number in ChestBeaconData). Game adds ONE
## to the world. It:
##   * draws a gold chevron bobbing over every chest lying in the world
##     (world space, z ChestBeaconData.BEACON_Z: above the units, so a crowd
##     never hides it), the pixel art markers/chest_beacon or a code chevron;
##   * provides the soft ground glow and pulse ring each Chest draws under
##     itself (draw_ground(), called from Chest._draw());
##   * owns the ChestArrows overlay (its own CanvasLayer over the world, under
##     the HUD and the menus) that points at every chest off screen, laid out
##     by layout_arrows() on an inset rect clear of the HUD and the touch
##     controls, nearest chests first, at most MAX_ARROWS;
##   * counts, headless too, what the beacon showed for the autotest's "chest
##     beacon" line: chests marked, chests seen on screen, the most arrows at
##     once and the ticks with an arrow. The count uses the logical view (the
##     camera follows the necromancer; the visible area at the camera's zoom,
##     the 1280 x 720 design layout headless), not the drawn frame, so it is
##     the same at any frame rate.
## Everything moves on real time (Time.get_ticks_msec(), drawing only) and
## holds still with Reduce motion; Effects: Reduced drops the pulse ring. The
## chevrons and arrows hide while the run is not PLAYING (level-up, chest,
## pause and end screens). Nothing is drawn headless (no CanvasLayer, no art
## loaded). Purely visual: it reads the chests and the player, never writes
## gameplay state and never touches the RNG (not even Game.stats), so every
## other autotest summary line is unchanged.
class_name ChestBeacon
extends Node2D

## Owning run.
var game: Game
## The edge arrows (null headless).
var arrows: ChestArrows = null
## True when nothing is drawn (the headless display server).
var _headless: bool = false
## Distinct chests that got a beacon (were lying in the world while PLAYING).
var chests_marked: int = 0
## Distinct chests that were on screen at least once while PLAYING.
var chests_seen: int = 0
## Most edge arrows at once (after merging and the cap).
var max_arrows: int = 0
## Physics ticks with at least one edge arrow.
var ticks_with_arrow: int = 0
## Game seconds with at least one edge arrow (the ticks' deltas summed).
var time_with_arrow: float = 0.0


func _ready() -> void:
	z_index = ChestBeaconData.BEACON_Z
	process_mode = Node.PROCESS_MODE_ALWAYS  # Notices pauses, to hide the chevrons and arrows.
	_headless = DisplayServer.get_name() == "headless"
	if _headless:
		visible = false
		return
	var layer := CanvasLayer.new()  # Over the world, under the HUD (Game's UI layer 10).
	layer.layer = ChestBeaconData.ARROW_LAYER
	add_child(layer)
	arrows = ChestArrows.new()
	arrows.beacon = self
	layer.add_child(arrows)


## True while the run plays (no panel open, tree running): the only time the
## chevrons and arrows show and the counters move.
func showing() -> bool:
	return game != null and game.run_state == Game.RunState.PLAYING and not get_tree().paused


## Counts what the beacon shows this tick (after Game's step: parents process
## first), from the logical view, headless too.
func _physics_process(delta: float) -> void:
	if not showing():
		return
	var screen := count_view_size()  # Visible area (layout px).
	var z := maxf(zoom(), 0.01)  # Screen px per world px.
	var centre := game.player.position  # The camera follows the necromancer.
	var off: Array[Vector2] = []  # Off-screen chests, screen coordinates (px).
	var dist: Array[float] = []  # Their world distance past the view edge (px).
	for c in game.chests.active:
		if not c.beacon_marked:
			c.beacon_marked = true
			chests_marked += 1
		var at := (c.position - centre) * z + screen * 0.5  # Screen position (px).
		if on_screen(at, screen):
			if not c.beacon_seen:
				c.beacon_seen = true
				chests_seen += 1
		else:
			off.append(at)
			dist.append(past_edge(c.position - centre, screen / z))
	if off.is_empty():
		return
	var n := layout_arrows(screen, off, dist, keep_outs(screen, 1.0, false), arrow_top()).size()  # Arrows drawn (desktop layout).
	max_arrows = maxi(max_arrows, n)
	ticks_with_arrow += 1
	time_with_arrow += delta


func _process(_delta: float) -> void:
	if _headless:
		return
	var want := showing()  # Shown only while the run plays.
	visible = want
	if arrows != null:
		arrows.visible = want
		if want:
			arrows.queue_redraw()
	if want:
		queue_redraw()


## Visible area (layout px) the headless count uses: the real one, but the
## design layout (1280 x 720, project settings) on the headless display
## server, whose window has no meaningful size.
func count_view_size() -> Vector2:
	if _headless:
		return Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
			float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))
	return get_viewport_rect().size


## Top margin (layout px) of the arrows' inset rect now: EDGE_TOP, or lower
## while the HUD's top-centre block (boss and miniboss bars) reaches further.
func arrow_top() -> float:
	var hud_bottom := game.hud.top_centre_bottom() if game != null and game.hud != null else 0.0  # Lowest top-centre line (px).
	return maxf(ChestBeaconData.EDGE_TOP, hud_bottom + ChestBeaconData.TOP_HUD_GAP)


## Camera zoom (screen px per world px; 1 = Normal).
func zoom() -> float:
	return game.camera.zoom.x if game != null and game.camera != null else 1.0


## True when screen position `at` lies inside a view of size `view` (px), at
## least ON_SCREEN_INSET inside its edge.
static func on_screen(at: Vector2, view: Vector2) -> bool:
	var m := ChestBeaconData.ON_SCREEN_INSET  # Inset (px).
	return at.x >= m and at.y >= m and at.x <= view.x - m and at.y <= view.y - m


## World px from the view edge to a chest at offset `rel` from the view centre
## (0 when inside), for the arrow's fade.
static func past_edge(rel: Vector2, view: Vector2) -> float:
	var over := Vector2(maxf(absf(rel.x) - view.x * 0.5, 0.0), maxf(absf(rel.y) - view.y * 0.5, 0.0))  # Overshoot per axis.
	return over.length()


## The corners kept free of arrows in a view of size `view` (px): the army
## list, and on phones (`touch`) the joystick, the buttons and the pause button
## (TouchData sizes in CSS px times `css_k` layout px per CSS px).
static func keep_outs(view: Vector2, css_k: float, touch: bool) -> Array[Rect2]:
	var bl := ChestBeaconData.KEEP_BOTTOM_LEFT  # Bottom-left size (px).
	var out: Array[Rect2] = []
	if touch:
		bl = bl.max(ChestBeaconData.TOUCH_KEEP_BOTTOM_LEFT * css_k)
		var br := ChestBeaconData.TOUCH_KEEP_BOTTOM_RIGHT * css_k  # Buttons' corner (px).
		out.append(Rect2(Vector2(view.x - br.x, view.y - br.y), br))
		var tr := ChestBeaconData.TOUCH_KEEP_TOP_RIGHT * css_k  # Pause button corner (px).
		out.append(Rect2(Vector2(view.x - tr.x, 0.0), tr))
	out.append(Rect2(Vector2(0.0, view.y - bl.y), bl))
	return out


## Lays out the edge arrows in a view of size `view` (px) for the off-screen
## chests at screen positions `points` (px), `dist` world px past the edge
## each: one arrow per chest on the inset rect's edge where the line from the
## view centre to the chest crosses it (the rect's top `top` px down), slid
## out of the kept-free corners `keep`; nearest chests first, an arrow nearer than MERGE_DISTANCE to one
## already placed (or past MAX_ARROWS) folds into the nearest placed one.
## Returns [{at: Vector2, dir: Vector2 (unit, toward the chest), dist: float,
## count: int (chests it stands for)}]. Pure (no state), shared by the drawing
## and the headless count.
static func layout_arrows(view: Vector2, points: Array[Vector2], dist: Array[float], keep: Array[Rect2], top: float) -> Array[Dictionary]:
	var inner := _inner_rect(view, top)  # Rect the arrows sit on (px).
	var centre := view * 0.5  # The necromancer (camera centre).
	var order: Array[int] = []  # Indices into points, nearest first.
	for i in points.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return dist[a] < dist[b] or (dist[a] == dist[b] and a < b))
	var placed: Array[Dictionary] = []
	for i in order:
		var at := _edge_point(inner, centre, points[i])  # Where its arrow sits (px).
		for k in keep:
			at = _slide_out(inner, k, at)
		var dir := (points[i] - at).normalized()  # Toward the chest.
		if dir == Vector2.ZERO:
			dir = (points[i] - centre).normalized()
		var host := -1  # Placed arrow it merges into (-1 = none).
		var best := INF  # Distance to the nearest placed arrow (px).
		for j in placed.size():
			var d := (placed[j]["at"] as Vector2).distance_to(at)
			if d < best:
				best = d
				host = j
		if host >= 0 and (best < ChestBeaconData.MERGE_DISTANCE or placed.size() >= ChestBeaconData.MAX_ARROWS):
			placed[host]["count"] = int(placed[host]["count"]) + 1
			continue
		placed.append({"at": at, "dir": dir, "dist": dist[i], "count": 1})
	return placed


## The rect (px) whose edge the arrows sit on, in a view of size `view`,
## `top_margin` px below its top (margins shrink on a view too small for them).
static func _inner_rect(view: Vector2, top_margin: float) -> Rect2:
	var side := minf(ChestBeaconData.EDGE_SIDE, view.x * 0.25)  # Left / right margin (px).
	var top := minf(top_margin, view.y * 0.35)  # Top margin (px).
	var bottom := minf(ChestBeaconData.EDGE_BOTTOM, view.y * 0.25)  # Bottom margin (px).
	return Rect2(side, top, maxf(view.x - side * 2.0, 1.0), maxf(view.y - top - bottom, 1.0))


## Where the line from `centre` toward `p` leaves `inner` (px).
static func _edge_point(inner: Rect2, centre: Vector2, p: Vector2) -> Vector2:
	var d := p - centre  # Direction to the chest (px).
	var t := INF  # Line parameter of the first crossing.
	if d.x > 0.0:
		t = minf(t, (inner.end.x - centre.x) / d.x)
	elif d.x < 0.0:
		t = minf(t, (inner.position.x - centre.x) / d.x)
	if d.y > 0.0:
		t = minf(t, (inner.end.y - centre.y) / d.y)
	elif d.y < 0.0:
		t = minf(t, (inner.position.y - centre.y) / d.y)
	if t == INF:
		return Vector2(centre.x, inner.position.y)
	return (centre + d * maxf(t, 0.0)).clamp(inner.position, inner.end)


## Point `at` on the edge of `inner`, moved along that edge out of the
## kept-free corner `k` (px; unchanged when outside it).
static func _slide_out(inner: Rect2, k: Rect2, at: Vector2) -> Vector2:
	if not k.has_point(at):
		return at
	var on_side := absf(at.x - inner.position.x) < 0.5 or absf(at.x - inner.end.x) < 0.5  # On the left / right edge.
	if on_side:
		at.y = k.position.y if k.position.y > inner.position.y else k.end.y  # Up out of a bottom corner, down out of a top one.
	else:
		at.x = k.position.x if k.position.x > inner.position.x else k.end.x  # Left out of a right corner, right out of a left one.
	return at.clamp(inner.position, inner.end)


## Real-time phase (0..1) of a loop of `period` seconds (drawing only).
static func phase(period: float) -> float:
	return fmod(float(Time.get_ticks_msec()) / 1000.0, period) / period


## True when the beacon's motion runs (the Reduce motion setting holds it still).
static func moving() -> bool:
	return not Settings.reduce_motion


func _draw() -> void:
	if _headless or game == null:
		return
	var lift := ChestBeaconData.BEACON_LIFT  # Chevron height above the chest (world px).
	if moving():
		lift += roundf(ChestBeaconData.BOB_HEIGHT * (0.5 + 0.5 * sin(TAU * phase(ChestBeaconData.BOB_PERIOD))))
	for c in game.chests.active:
		var at := (c.position + Vector2(0.0, -lift)).round()  # Chevron centre, on whole world px.
		if not SpriteBank.draw_flat(self, ChestBeaconData.BEACON_KEY, at, 0.0):
			draw_chevron(self, at)


## Code chevron (the fallback when the PNG is missing): a gold V with a dark
## rim, about 17 x 13 px, centred on `at`.
static func draw_chevron(ci: CanvasItem, at: Vector2) -> void:
	var outer := PackedVector2Array([at + Vector2(-8, -6), at + Vector2(-3, -6), at + Vector2(0, -1), at + Vector2(3, -6), at + Vector2(8, -6), at + Vector2(0, 6)])  # V outline.
	var closed := outer.duplicate()
	closed.append(outer[0])
	ci.draw_polyline(closed, ChestBeaconData.INK, 3.0)
	ci.draw_colored_polygon(outer, ChestBeaconData.GOLD)
	ci.draw_line(outer[0], outer[1], ChestBeaconData.GOLD_LIGHT, 1.0)


## The ground glow under a chest on `ci` (a Chest drawing itself, origin = the
## chest): a steady gold ellipse with a dark under-rim, and, unless Reduce
## motion or Effects: Reduced, a pulse ring growing out and fading on real
## time. Drawn in world px under the chest sprite.
static func draw_ground(ci: CanvasItem) -> void:
	var o := Vector2(0.0, ChestBeaconData.GROUND_DROP)  # Glow centre: the chest's base.
	var r := ChestBeaconData.GLOW_RADIUS  # Glow half-width (px).
	var sq := ChestBeaconData.GROUND_SQUASH  # Ellipse height / width.
	var w := ChestBeaconData.RING_WIDTH  # Ring width (px).
	_ellipse_fill(ci, o, r, sq, Color(ChestBeaconData.GOLD, ChestBeaconData.GLOW_ALPHA))
	_ellipse_line(ci, o, r, sq, Color(ChestBeaconData.INK, ChestBeaconData.GLOW_RIM_ALPHA * 0.6), w + 2.0)
	_ellipse_line(ci, o, r, sq, Color(ChestBeaconData.GOLD_LIGHT, ChestBeaconData.GLOW_RIM_ALPHA), w * 0.5)
	if not moving() or Settings.reduced_effects():
		return
	var p := phase(ChestBeaconData.PULSE_PERIOD)  # 0..1 through this pulse.
	var pr := lerpf(ChestBeaconData.PULSE_START, ChestBeaconData.PULSE_END, p)  # Pulse half-width (px).
	var a := ChestBeaconData.PULSE_ALPHA * (1.0 - p)  # Pulse opacity.
	_ellipse_line(ci, o, pr, sq, Color(ChestBeaconData.INK, a * 0.5), w + 2.0)
	_ellipse_line(ci, o, pr, sq, Color(ChestBeaconData.GOLD_LIGHT, a), w)


## Points of an ellipse of half-width `r`, height ratio `sq`, centred on `o`.
static func _ellipse(o: Vector2, r: float, sq: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := ChestBeaconData.ELLIPSE_POINTS  # Points around.
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		pts.append(o + Vector2(cos(a) * r, sin(a) * r * sq))
	return pts


## Filled ellipse on `ci`.
static func _ellipse_fill(ci: CanvasItem, o: Vector2, r: float, sq: float, col: Color) -> void:
	var pts := _ellipse(o, r, sq)
	pts.remove_at(pts.size() - 1)  # The closing point repeats the first.
	ci.draw_colored_polygon(pts, col)


## Ellipse outline of width `width` on `ci`.
static func _ellipse_line(ci: CanvasItem, o: Vector2, r: float, sq: float, col: Color, width: float) -> void:
	ci.draw_polyline(_ellipse(o, r, sq), col, width, true)


## The autotest's "chest beacon" line.
func summary_line() -> String:
	return "chests marked %d, seen on screen %d | max off-screen arrows at once %d | ticks with an arrow %d (%.1f s)" % [
		chests_marked, chests_seen, max_arrows, ticks_with_arrow, time_with_arrow]
