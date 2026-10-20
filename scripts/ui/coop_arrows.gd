## CoopArrows: the edge arrow toward an off-screen partner (GDD §15.0 "Co-op
## HUD and visuals"; numbers in CoopHudData). A full-screen Control on its own
## CanvasLayer (ChestBeaconData.ARROW_LAYER: over the world, under the HUD and
## every menu), created by CoopUi outside the headless display server. While
## the partner's necromancer is off screen it lays out one arrow with the chest
## beacon's own layout (ChestBeacon.layout_arrows(), keep_outs(), the same
## inset rect clear of the HUD bars, the army list and the touch controls) and
## draws it in the chest arrows' style but its own colour: a round badge with
## the partner's bust inside (a CoopBust child, moved onto the badge) and a
## soul-teal rim and pointer turned toward him. Downed, the rim and pointer turn
## crimson and a crimson ring pulses out of the badge (no ring with Reduce
## motion or Effects: Reduced). No distance number: the arrow fades a little
## with distance instead, never below ARROW_ALPHA_FAR. The badge nudges toward
## the partner on real time (still with Reduce motion). While the partner is on
## screen (and standing) it draws his name in soul-teal over his head instead,
## so he stands out from a crowd of undead. Hidden while the run is not
## PLAYING. Purely visual: it reads the partner's position only.
class_name CoopArrows
extends Control

## Owning run.
var game: Game = null
## The partner's bust inside the badge (moved onto it every frame).
var _bust: CoopBust = null
## Arrows laid out this frame (CoopUi's report reads it; 0 or 1 with two players).
var drawn: int = 0
## This frame's arrows: ChestBeacon.layout_arrows() entries plus "slot" (CoopSlot).
var _arrows: Array[Dictionary] = []
## This frame's name tags over on-screen partners: [{at: Vector2 (px), slot: CoopSlot}].
var _tags: Array[Dictionary] = []
## World px past the view edge of the farthest arrow this frame (0 = none; the
## debug walk waits for a clearly off-screen partner).
var max_past: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SpriteBank.apply_sharp(self)
	var side := floorf(CoopHudData.ARROW_BADGE_RADIUS * 1.42)  # Square inside the round badge (px).
	_bust = CoopBust.new(Vector2(side, side), CoopHudData.ARROW_BUST_DROP, false)
	_bust.visible = false
	add_child(_bust)


func _process(_delta: float) -> void:
	visible = game != null and game.run_state == Game.RunState.PLAYING and not get_tree().paused  # Only while the run plays.
	if not visible:
		_arrows.clear()
		_tags.clear()
		drawn = 0
		return
	_layout()
	queue_redraw()


## The partner slots of this machine's view (every slot but the viewed one).
func _partners() -> Array[CoopSlot]:
	var out: Array[CoopSlot] = []
	for s in game.coop.slots:
		if s.index != game.coop.view_slot and s.player != null:
			out.append(s)
	return out


## Lays out this frame's arrows (_arrows) and puts the bust on the first badge.
func _layout() -> void:
	_arrows.clear()
	_tags.clear()
	max_past = 0.0
	if game == null or game.coop == null:
		_bust.visible = false
		return
	var view := size  # Visible area (layout px).
	var zoom := maxf(game.camera.zoom.x, 0.01) if game.camera != null else 1.0  # Screen px per world px.
	var touch := InputHints.device() == InputHints.Device.TOUCH  # Phone / tablet controls on screen.
	var k := TouchSupport.layout_per_css(get_viewport()) if touch else 1.0  # Layout px per CSS px.
	var top := ChestBeaconData.EDGE_TOP  # Top of the arrows' inset rect (px).
	if game.hud != null:
		top = maxf(top, game.hud.top_centre_bottom() + ChestBeaconData.TOP_HUD_GAP)
	for s in _partners():
		var at := s.player.get_global_transform_with_canvas().origin  # Where the camera puts him (px).
		if ChestBeacon.on_screen(at, view):
			if not s.downed:  # A downed partner has his marker instead.
				_tags.append({"at": (at + Vector2(0.0, -CoopHudData.TAG_LIFT * zoom)).round(), "slot": s})
			continue
		var pts: Array[Vector2] = [at]
		var ds: Array[float] = [ChestBeacon.past_edge((at - view * 0.5) / zoom, view / zoom)]  # World px past the edge.
		max_past = maxf(max_past, ds[0])
		for a: Dictionary in ChestBeacon.layout_arrows(view, pts, ds, ChestBeacon.keep_outs(view, k, touch), top):
			a["slot"] = s
			_arrows.append(a)
	drawn = _arrows.size()
	_bust.visible = not _arrows.is_empty()
	if _bust.visible:
		var a: Dictionary = _arrows[0]
		var s: CoopSlot = a["slot"]
		var c := _badge_centre(a)
		_bust.show_player(s.player, s.downed)
		_bust.position = (c - _bust.size * 0.5).round()
		_bust.modulate.a = _alpha(float(a["dist"]))


## Opacity (0-1) of an arrow `dist` world px past the view edge.
static func _alpha(dist: float) -> float:
	var f := clampf(dist / CoopHudData.ARROW_FAR_DISTANCE, 0.0, 1.0)  # 0 just off screen .. 1 far.
	return lerpf(CoopHudData.ARROW_ALPHA_NEAR, CoopHudData.ARROW_ALPHA_FAR, f)


## Badge centre (whole px) of arrow `a`, nudged toward the partner on real time.
static func _badge_centre(a: Dictionary) -> Vector2:
	var nudge := 0.0  # Push toward him this frame (px).
	if not Settings.reduce_motion:
		var ph := fmod(float(Time.get_ticks_msec()) / 1000.0, CoopHudData.ARROW_NUDGE_PERIOD) / CoopHudData.ARROW_NUDGE_PERIOD
		nudge = CoopHudData.ARROW_NUDGE * (0.5 - 0.5 * cos(TAU * ph))
	return ((a["at"] as Vector2) + (a["dir"] as Vector2) * nudge).round()


func _draw() -> void:
	for a: Dictionary in _arrows:
		_draw_arrow(a["slot"] as CoopSlot, a)
	for t: Dictionary in _tags:
		_draw_tag(t["slot"] as CoopSlot, t["at"] as Vector2)


## The partner's name in soul-teal (BODY size, a dark shadow) centred on `at`
## (px): over his head while he is on screen, so he stands out in a crowd.
func _draw_tag(s: CoopSlot, at: Vector2) -> void:
	var font := UiTheme.font_for() if UiTheme.font_for() != null else get_theme_default_font()  # Jersey 10.
	var fs := UiTheme.tier_px(UiTheme.Tier.BODY)  # 19 px.
	var w := font.get_string_size(s.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x  # Text width (px).
	var p := Vector2(roundf(at.x - w * 0.5), at.y)  # Baseline start (px).
	draw_string(font, p + Vector2(1, 1), s.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(CoopHudData.INK, 0.9))
	draw_string(font, p, s.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CoopHudData.PARTNER)


## The arrow `a` (ChestBeacon.layout_arrows() entry) toward slot `s`: the
## badge, the pointer toward him, faded with his distance past the edge.
func _draw_arrow(s: CoopSlot, a: Dictionary) -> void:
	var dir := a["dir"] as Vector2  # Toward him (unit).
	var alpha := _alpha(float(a["dist"]))  # Arrow opacity.
	var col := CoopHudData.DOWNED if s.downed else CoopHudData.PARTNER  # Rim / pointer colour.
	var lit := CoopHudData.DOWNED_LIGHT if s.downed else CoopHudData.PARTNER_LIGHT
	var c := _badge_centre(a)  # Badge centre (whole px).
	var r := CoopHudData.ARROW_BADGE_RADIUS
	if s.downed and not Settings.reduce_motion and not Settings.reduced_effects():
		# A crimson ring pulsing out of the badge: he needs raising.
		var p := fmod(float(Time.get_ticks_msec()) / 1000.0, CoopHudData.ARROW_PULSE_PERIOD) / CoopHudData.ARROW_PULSE_PERIOD
		var pr := lerpf(CoopHudData.ARROW_PULSE_START, CoopHudData.ARROW_PULSE_END, p)
		var pa := (1.0 - p) * alpha * 0.85
		draw_arc(c, pr, 0.0, TAU, 32, Color(CoopHudData.INK, pa * 0.5), 4.0, true)
		draw_arc(c, pr, 0.0, TAU, 32, Color(lit, pa), 2.0, true)
	# Pointer: a triangle with a dark rim, just outside the badge.
	var side := Vector2(-dir.y, dir.x)  # Perpendicular to the pointer.
	var base := c + dir * CoopHudData.ARROW_POINTER_GAP  # Middle of the pointer's base.
	var tip := base + dir * CoopHudData.ARROW_POINTER_LENGTH
	var hw := CoopHudData.ARROW_POINTER_HALF_WIDTH
	var rim := ChestBeaconData.POINTER_RIM
	draw_colored_polygon(PackedVector2Array([tip + dir * rim * 1.6, base + side * (hw + rim) - dir * rim, base - side * (hw + rim) - dir * rim]), Color(CoopHudData.INK, alpha))
	draw_colored_polygon(PackedVector2Array([tip, base + side * hw, base - side * hw]), Color(col, alpha))
	draw_line(base + side * hw, tip, Color(lit, alpha), 1.0)
	# Badge: a soft dark halo (it reads over a crowd), dark rim, coloured ring,
	# dark plate; the bust goes on top (child).
	draw_circle(c, r + CoopHudData.ARROW_HALO, Color(CoopHudData.INK, CoopHudData.ARROW_HALO_ALPHA * alpha))
	draw_circle(c, r + 1.0, Color(CoopHudData.INK, alpha))
	draw_circle(c, r, Color(col, alpha))
	draw_circle(c, r - CoopHudData.ARROW_RIM, Color(CoopHudData.PLATE, alpha))
