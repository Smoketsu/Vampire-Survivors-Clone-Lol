## DreadVignette — the screen edges darkening with the necromancer's DREAD
## (DreadMeter, DreadData; GDD §15.0 "Act II: the Ancient Eye"): an abyssal
## near-black band at the screen edges whose depth and opacity follow the
## meter, with a slow "whisper" pulse. Purely visual (it never reads or
## changes gameplay state), lighter under Reduce motion and Effects = Reduced
## (no pulse with Reduce motion), and never covers the centre of the screen.
## Drawn like HurtVignette, as a ring of vertex-coloured quads (reliable on the
## GL Compatibility renderer). The HUD adds it under its widgets on a stage
## with Dread and calls refresh().
class_name DreadVignette
extends Control

## Segments around the ellipse (smoothness).
const SEGMENTS: int = 48
## Outer edge of the band, as a fraction of the half-diagonal (past the corners).
const OUTER: float = 1.05

## The run whose Dread is shown.
var game: Game
## Opacity drawn now (0..1, before the pulse).
var _alpha: float = 0.0
## Inner edge of the band now (fraction of the half-diagonal).
var _inner: float = 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Re-reads the meter (HUD refresh) and redraws.
func refresh() -> void:
	if game == null or game.dread == null:
		return
	var f := game.dread.fraction()  # 0..1 Dread.
	if game.dread.value < DreadData.VIGNETTE_FROM:
		f = 0.0
	var soft := not UiMotion.enabled() or Settings.reduced_effects()  # The lighter look.
	_alpha = f * DreadData.VIGNETTE_MAX_ALPHA * (DreadData.VIGNETTE_REDUCED if soft else 1.0)
	_inner = 1.0 - DreadData.VIGNETTE_REACH * f
	queue_redraw()


func _process(_delta: float) -> void:
	if _alpha > 0.0 and UiMotion.enabled():
		queue_redraw()  # The whisper pulse.


func _draw() -> void:
	if _alpha <= 0.0:
		return
	var a := _alpha  # Opacity this frame.
	if UiMotion.enabled() and game != null:
		a *= 1.0 - DreadData.VIGNETTE_PULSE * (0.5 + 0.5 * sin(game.elapsed * TAU * DreadData.VIGNETTE_PULSE_HZ))
	var c := size * 0.5  # Screen centre.
	var r := size * 0.5 * sqrt(2.0)  # Half-extents that reach past the corners.
	var edge := Color(DreadData.VIGNETTE_COLOR, a)  # Outer colour.
	var clear := Color(DreadData.VIGNETTE_COLOR, 0.0)  # Transparent inner colour.
	for i in SEGMENTS:
		var a0 := TAU * float(i) / float(SEGMENTS)  # Segment start angle.
		var a1 := TAU * float(i + 1) / float(SEGMENTS)  # Segment end angle.
		var d0 := Vector2(cos(a0), sin(a0)) * r  # Direction scaled to the ellipse.
		var d1 := Vector2(cos(a1), sin(a1)) * r
		var quad := PackedVector2Array([c + d0 * _inner, c + d1 * _inner, c + d1 * OUTER, c + d0 * OUTER])
		draw_polygon(quad, PackedColorArray([clear, clear, edge, edge]))
