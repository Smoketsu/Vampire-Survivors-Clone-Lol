## CoopMarkers: the downed / revive marker in the world (GDD §15.0 "Co-op HUD
## and visuals"; numbers in CoopHudData). CoopUi adds ONE to the run (a child
## of Game, world space, z MARKER_Z: over the units, so a crowd never hides
## it). Over every downed necromancer, the local one included, it draws:
##   * a faint dashed circle at CoopData.REVIVE_RADIUS (world px, a true
##     circle: the revive reach is a plain distance), soul-teal with a faint
##     fill, brighter while the partner stands inside it;
##   * the revive progress ring round him: a dark track, filling clockwise
##     from the top in green as CoopSlot.revive_progress builds toward
##     CoopData.REVIVE_TIME (and emptying as it decays);
##   * a crimson down-chevron bobbing over his head.
## Motion (the bob) runs on real time and holds still with Reduce motion and
## under the autotest. Nothing is drawn headless. Purely visual: it reads the
## session's downed state and positions, never writes gameplay state and
## never draws from the RNG.
class_name CoopMarkers
extends Node2D

## Owning run.
var game: Game


func _ready() -> void:
	z_index = CoopHudData.MARKER_Z
	process_mode = Node.PROCESS_MODE_ALWAYS  # Notices pauses (hides while a panel is open).
	if DisplayServer.get_name() == "headless":
		visible = false
		set_process(false)


func _process(_delta: float) -> void:
	var want := game != null and game.coop != null and game.run_state == Game.RunState.PLAYING and _any_downed()
	visible = want
	if want:
		queue_redraw()


## True while some slot lies downed.
func _any_downed() -> bool:
	for s in game.coop.slots:
		if s.downed:
			return true
	return false


## True when a standing slot other than `s` is within revive reach of `s`.
static func helper_in_reach(co: CoopSession, s: CoopSlot) -> bool:
	for o in co.slots:
		if o != s and o.alive() and o.player.position.distance_to(s.player.position) <= CoopData.REVIVE_RADIUS:
			return true
	return false


func _draw() -> void:
	if game == null or game.coop == null:
		return
	for s in game.coop.slots:
		if s.downed and s.player != null:
			_draw_downed(s)


## The radius circle, the progress ring and the chevron of downed slot `s`.
func _draw_downed(s: CoopSlot) -> void:
	var at := s.player.position.round()  # Body centre (whole world px).
	var near := helper_in_reach(game.coop, s)  # The partner stands in reach.
	# Revive reach: a faint dashed circle and fill.
	var ra := CoopHudData.RADIUS_ALPHA * (1.6 if near else 1.0)  # Brighter while used.
	draw_circle(at, CoopData.REVIVE_RADIUS, Color(CoopHudData.PARTNER, CoopHudData.RADIUS_FILL_ALPHA * (1.6 if near else 1.0)))
	var n := CoopHudData.RADIUS_DASHES
	for i in n:
		var a0 := TAU * float(i) / float(n)  # Dash start angle.
		var a1 := a0 + TAU / float(n) * 0.55  # Dash end angle (gaps between).
		draw_arc(at, CoopData.REVIVE_RADIUS, a0, a1, 4, Color(CoopHudData.INK, ra * 0.6), 3.0, true)
		draw_arc(at, CoopData.REVIVE_RADIUS, a0, a1, 4, Color(CoopHudData.PARTNER, ra), 1.5, true)
	# Progress ring: a dark track, then the green fill clockwise from the top.
	var rr := CoopHudData.RING_RADIUS
	var w := CoopHudData.RING_WIDTH
	draw_arc(at, rr, 0.0, TAU, CoopHudData.RING_POINTS, Color(CoopHudData.INK, CoopHudData.RING_TRACK_ALPHA + 0.2), w + 2.0, true)
	draw_arc(at, rr, 0.0, TAU, CoopHudData.RING_POINTS, Color(CoopHudData.DOWNED, CoopHudData.RING_TRACK_ALPHA), w, true)
	var share := clampf(s.revive_progress / CoopData.REVIVE_TIME, 0.0, 1.0)  # 0..1 raised.
	if share > 0.0:
		var start := -PI * 0.5  # The top.
		var pts := maxi(3, int(ceil(float(CoopHudData.RING_POINTS) * share)))
		draw_arc(at, rr, start, start + TAU * share, pts, CoopHudData.REVIVE, w, true)
		draw_arc(at, rr - w * 0.5 + 0.5, start, start + TAU * share, pts, CoopHudData.REVIVE.lightened(0.45), 1.0, true)
	# Downed chevron over the head.
	var lift := CoopHudData.MARKER_LIFT
	if UiMotion.enabled():
		var ph := fmod(float(Time.get_ticks_msec()) / 1000.0, CoopHudData.MARKER_BOB_PERIOD) / CoopHudData.MARKER_BOB_PERIOD
		lift += roundf(CoopHudData.MARKER_BOB * (0.5 + 0.5 * sin(TAU * ph)))
	_draw_chevron(at + Vector2(0.0, -lift))


## A crimson down-chevron with a dark rim, centred on `c` (world px).
func _draw_chevron(c: Vector2) -> void:
	var hw := CoopHudData.MARKER_HALF_WIDTH
	var h := CoopHudData.MARKER_HEIGHT
	var notch := h * 0.45  # Depth of the V's inner notch.
	var pts := PackedVector2Array([c + Vector2(-hw, -h * 0.5), c + Vector2(-hw * 0.4, -h * 0.5), c + Vector2(0.0, -h * 0.5 + notch),
		c + Vector2(hw * 0.4, -h * 0.5), c + Vector2(hw, -h * 0.5), c + Vector2(0.0, h * 0.5)])
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, CoopHudData.INK, 3.0)
	draw_colored_polygon(pts, CoopHudData.DOWNED)
	draw_line(pts[0], pts[1], CoopHudData.DOWNED_LIGHT, 1.0)
	draw_line(pts[3], pts[4], CoopHudData.DOWNED_LIGHT, 1.0)
