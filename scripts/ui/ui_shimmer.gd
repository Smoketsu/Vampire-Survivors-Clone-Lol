## UiShimmer — a soft gold sheen that sweeps diagonally across its rect
## every InRunUiData.SHIMMER_PERIOD s: the "this is special" mark of an
## evolution card and an evolution chest reward (gold = evolution). It clips
## to its own rect (put it inside the card's padding so it stays inside the
## frame), ignores the mouse, runs on unscaled real time and draws nothing
## when motion is off (UiMotion.enabled(): the autotest, "Reduce motion").
## Purely visual.
class_name UiShimmer
extends Control

## Sheen colour; its alpha is the band's peak opacity.
var color: Color = InRunUiData.SHIMMER_COLOR
## Real time (usec) of the first sweep's start.
var _start_usec: int = 0


func _init(first_delay: float = InRunUiData.SHIMMER_DELAY) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_start_usec = Time.get_ticks_usec() + int(first_delay * 1000000.0)


func _process(_delta: float) -> void:
	if UiMotion.enabled() and is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if not UiMotion.enabled():
		return
	var t := float(Time.get_ticks_usec() - _start_usec) / 1000000.0  # Seconds since the first sweep.
	if t < 0.0:
		return
	var k := fmod(t, InRunUiData.SHIMMER_PERIOD) / InRunUiData.SHIMMER_SWEEP  # 0..1 through this sweep.
	if k >= 1.0:
		return
	var band := InRunUiData.SHIMMER_BAND  # Band width (px).
	var travel := size.x + size.y + band * 2.0  # Distance the 45-degree band crosses.
	var x := -size.y - band + travel * k  # Band's top-left x (px).
	var a := color.a * sin(k * PI)  # Fades in and out across the sweep.
	var pts := PackedVector2Array([
		Vector2(x + size.y, 0.0), Vector2(x + size.y + band, 0.0),
		Vector2(x + band, size.y), Vector2(x, size.y)])  # Slanted band.
	draw_colored_polygon(pts, Color(color, a))
	var core := PackedVector2Array([
		Vector2(x + size.y + band * 0.4, 0.0), Vector2(x + size.y + band * 0.6, 0.0),
		Vector2(x + band * 0.6, size.y), Vector2(x + band * 0.4, size.y)])  # Brighter core line.
	draw_colored_polygon(core, Color(color, a * 0.9))
