## SoulMarker — the soul-wisp focus marker of the main menu's button column
## (GDD §15.0 "Front door screens"; numbers in FrontDoorData "focus wisp"): a
## pair of flickering soul flames (the diorama's menu/wisp art over a stepped
## glow) that flank the focused button, slide to the next one when the focus
## moves and bob gently. A full-rect overlay that ignores the mouse; the menu
## calls follow() from each button's focus / hover. Drawn at 2 layout px per
## art px through the sharp-pixel shader. With motion off (UiMotion.enabled())
## it jumps instead of sliding and holds one frame. Purely cosmetic.
class_name SoulMarker
extends Control

## Layout px per art px of the wisp.
const ART_SCALE: int = 2

## The button marked (null = hidden).
var _target: Control = null
## The marked rect now (px, this control's space), easing toward the target's.
var _rect: Rect2 = Rect2()
## True once _rect holds a real position (the first follow() jumps).
var _placed: bool = false
## Real seconds since the marker appeared (flame frames and bob).
var _t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	SpriteBank.apply_sharp(self)


## Marks `c` (a menu button); null hides the marker.
func follow(c: Control) -> void:
	_target = c
	if c != null and (not _placed or not UiMotion.enabled()):
		_rect = _target_rect()
		_placed = true
	queue_redraw()


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # Real seconds.
	if UiMotion.enabled():
		_t += dt
	var goal := _target_rect()  # Where the marker belongs.
	var k := 1.0 if not UiMotion.enabled() else clampf(dt / maxf(0.01, FrontDoorData.MARKER_SLIDE_TIME) * 2.5, 0.0, 1.0)  # Ease share this frame.
	_rect = Rect2(_rect.position.lerp(goal.position, k), _rect.size.lerp(goal.size, k))
	queue_redraw()


## The target's rect in this control's space.
func _target_rect() -> Rect2:
	var r := _target.get_global_rect()  # Global rect of the button.
	var inv := get_global_transform().affine_inverse()  # Global -> local.
	return Rect2(inv * r.position, r.size)


func _draw() -> void:
	if _target == null or not is_instance_valid(_target) or not _target.is_visible_in_tree():
		return
	var tex := EnvironmentArt.texture(MenuBackdropData.ART + "wisp")  # 4-frame strip of 9 x 14.
	if tex == null:
		return
	var fw := float(tex.get_width()) / 4.0  # Frame width (art px).
	var fh := float(tex.get_height())  # Frame height (art px).
	var k := float(ART_SCALE)
	var size_px := Vector2(fw, fh) * k  # Drawn wisp (px).
	var bob := roundf(sin(TAU * _t / FrontDoorData.MARKER_BOB_PERIOD) * FrontDoorData.MARKER_BOB)  # Bob (px).
	var cy := _rect.position.y + _rect.size.y * 0.5 + bob  # Wisp centre y (px).
	var glow := EnvironmentArt.texture(MenuBackdropData.ART + "glow")  # Glow disc, or null.
	for side in 2:
		var cx := _rect.position.x - FrontDoorData.MARKER_GAP - size_px.x * 0.5 if side == 0 \
				else _rect.end.x + FrontDoorData.MARKER_GAP + size_px.x * 0.5  # Wisp centre x (px).
		var c := Vector2(cx, cy)
		if glow != null:
			var gs := Vector2(float(glow.get_width()), float(glow.get_height())) * FrontDoorData.MARKER_GLOW_SCALE * k  # Glow size (px).
			draw_texture_rect(glow, Rect2((c - gs * 0.5).round(), gs), false, Color(MenuBackdropData.SOUL_GLOW, FrontDoorData.MARKER_GLOW_ALPHA))
		var f := (int(_t * FrontDoorData.MARKER_FPS) + side * 2) % 4  # Frame (the two wisps out of step).
		var tl := ((c - size_px * 0.5) / k).round() * k  # Top-left on the art grid (px).
		draw_texture_rect_region(tex, Rect2(tl, size_px), Rect2(fw * float(f), 0.0, fw, fh))
