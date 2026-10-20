## ChestArrows: the chest beacon's edge arrows (owner request, Oct 2026: "show
## you if you missed one. Or if it's slightly off screen"; GDD §15.0 "Chest
## beacon"; numbers in ChestBeaconData). A full-screen Control on the beacon's
## own CanvasLayer (ChestBeaconData.ARROW_LAYER: over the world, under the HUD
## and every menu), created by ChestBeacon outside the headless display server.
## Every frame the run plays it lays out one arrow per chest off screen
## (ChestBeacon.layout_arrows(): nearest first, at most MAX_ARROWS, close ones
## merged into count pips) on an inset rect that keeps out of the HUD's top
## bars, the ability bar, the army list and, on phones and tablets (InputHints
## on TOUCH), the joystick, the buttons and the pause button. An arrow is the
## round gold badge (pixel art markers/chest_badge, or a code badge) with a gold
## pointer turned toward its chest; it fades and its pointer shrinks a little
## with distance, never below ARROW_ALPHA_FAR, nudges toward the chest and
## sends out a gold pulse ring on real time (still with Reduce motion; no ring
## with Effects: Reduced). The rect's top follows the HUD's top-centre block
## (ChestBeacon.arrow_top()). ChestBeacon hides it while the run is not
## PLAYING. Purely visual: it reads the chests' positions only.
class_name ChestArrows
extends Control

## The beacon that owns this overlay (its game, chests and layout).
var beacon: ChestBeacon = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SpriteBank.apply_sharp(self)  # Crisp badge art (code shapes are unaffected).


func _draw() -> void:
	if beacon == null or beacon.game == null:
		return
	var game := beacon.game  # Owning run.
	var view := size  # Visible area (layout px).
	var off: Array[Vector2] = []  # Off-screen chests, screen positions (px).
	var dist: Array[float] = []  # World px past the view edge.
	var zoom := beacon.zoom()  # Screen px per world px.
	for c in game.chests.active:
		var at := c.get_global_transform_with_canvas().origin  # Where the camera puts it (px).
		if ChestBeacon.on_screen(at, view):
			continue
		off.append(at)
		dist.append(ChestBeacon.past_edge((at - view * 0.5) / maxf(zoom, 0.01), view / maxf(zoom, 0.01)))
	if off.is_empty():
		return
	var touch := InputHints.device() == InputHints.Device.TOUCH  # Phone / tablet controls on screen.
	var k := TouchSupport.layout_per_css(get_viewport()) if touch else 1.0  # Layout px per CSS px.
	var nudge := 0.0  # Push toward the chest this frame (px).
	if ChestBeacon.moving():
		nudge = ChestBeaconData.NUDGE * (0.5 - 0.5 * cos(TAU * ChestBeacon.phase(ChestBeaconData.NUDGE_PERIOD)))
	for a: Dictionary in ChestBeacon.layout_arrows(view, off, dist, ChestBeacon.keep_outs(view, k, touch), beacon.arrow_top()):
		_draw_arrow(a["at"] as Vector2, a["dir"] as Vector2, float(a["dist"]), int(a["count"]), nudge)


## One arrow: badge at `at`, pointer toward `dir`, faded for `dist` world px
## past the edge, `count` chests (pips for the merged ones), pushed `nudge` px.
func _draw_arrow(at: Vector2, dir: Vector2, dist: float, count: int, nudge: float) -> void:
	var f := clampf(dist / ChestBeaconData.FAR_DISTANCE, 0.0, 1.0)  # 0 just off screen .. 1 far.
	var alpha := lerpf(ChestBeaconData.ARROW_ALPHA_NEAR, ChestBeaconData.ARROW_ALPHA_FAR, f)  # Arrow opacity.
	var s := lerpf(ChestBeaconData.POINTER_SCALE_NEAR, ChestBeaconData.POINTER_SCALE_FAR, f)  # Pointer size factor.
	var c := (at + dir * nudge).round()  # Badge centre on whole px (crisp art).
	if ChestBeacon.moving() and not Settings.reduced_effects():
		# A gold ring pulsing out of the badge (the ground pulse's rhythm) to catch the eye.
		var p := ChestBeacon.phase(ChestBeaconData.PULSE_PERIOD)  # 0..1 through this pulse.
		var pr := lerpf(ChestBeaconData.BADGE_PULSE_START, ChestBeaconData.BADGE_PULSE_END, p)  # Ring radius (px).
		var pa := ChestBeaconData.PULSE_ALPHA * ChestBeaconData.BADGE_PULSE_ALPHA * (1.0 - p) * alpha  # Ring opacity.
		draw_arc(c, pr, 0.0, TAU, 32, Color(ChestBeaconData.INK, pa * 0.5), ChestBeaconData.RING_WIDTH + 2.0, true)
		draw_arc(c, pr, 0.0, TAU, 32, Color(ChestBeaconData.GOLD_LIGHT, pa), ChestBeaconData.RING_WIDTH, true)
	# Pointer: a gold triangle with a dark rim, just outside the badge.
	var side := Vector2(-dir.y, dir.x)  # Perpendicular to the pointer.
	var base := c + dir * ChestBeaconData.POINTER_GAP  # Middle of the pointer's base (px).
	var tip := base + dir * ChestBeaconData.POINTER_LENGTH * s  # Pointer tip (px).
	var hw := ChestBeaconData.POINTER_HALF_WIDTH * s  # Base half-width (px).
	var rim := ChestBeaconData.POINTER_RIM  # Dark rim (px).
	var ink := PackedVector2Array([tip + dir * rim * 1.6, base + side * (hw + rim) - dir * rim, base - side * (hw + rim) - dir * rim])  # Rim triangle.
	draw_colored_polygon(ink, Color(ChestBeaconData.INK, alpha))
	draw_colored_polygon(PackedVector2Array([tip, base + side * hw, base - side * hw]), Color(ChestBeaconData.GOLD, alpha))
	draw_line(base + side * hw, tip, Color(ChestBeaconData.GOLD_LIGHT, alpha), 1.0)
	# Badge: the pixel art, else a code badge (dark rim, gold ring, plate, little chest).
	if not SpriteBank.draw_flat(self, ChestBeaconData.BADGE_KEY, c, 0.0, Color(1.0, 1.0, 1.0, alpha)):
		var r := ChestBeaconData.BADGE_RADIUS  # Badge radius (px).
		draw_circle(c, r + 1.0, Color(ChestBeaconData.INK, alpha))
		draw_circle(c, r, Color(ChestBeaconData.GOLD, alpha))
		draw_circle(c, r - 2.5, Color(ChestBeaconData.PLATE, alpha))
		draw_rect(Rect2(c - Vector2(4.5, 3.5), Vector2(9.0, 7.0)), Color(ChestBeaconData.GOLD, alpha))
		draw_rect(Rect2(c - Vector2(4.5, 0.5), Vector2(9.0, 1.0)), Color(ChestBeaconData.INK, alpha))
	# Merged chests: one pip each, in a row on the badge's far side from the pointer.
	var pips := mini(count - 1, ChestBeaconData.MAX_PIPS)  # Pips to draw.
	if pips <= 0:
		return
	var ps := ChestBeaconData.PIP_SIZE  # Pip size (px).
	var step := ps + ChestBeaconData.PIP_GAP  # Pip spacing (px).
	var row := c - dir * (ChestBeaconData.BADGE_RADIUS + ps + 1.0)  # Middle of the pip row (px).
	for i in pips:
		var pc := (row + side * (float(i) - float(pips - 1) * 0.5) * step).round()  # Pip centre (px).
		var p := Rect2(pc - Vector2(ps, ps) * 0.5, Vector2(ps, ps))
		draw_rect(p.grow(1.0), Color(ChestBeaconData.INK, alpha))
		draw_rect(p, Color(ChestBeaconData.GOLD_LIGHT, alpha))
