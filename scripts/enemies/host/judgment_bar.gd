## JudgmentBar — the HUD's SCALES OF JUDGMENT (temporary Act XIII, the
## Celestial Host; GDD §15.0 "Judgment"; proposal: "A pair of scales on the HUD
## weighs the necromancer's sins"). Drawn under the HUD's top-centre block: a
## short line of text (the scales' state, or the Verdict's countdown) over a
## bar that fills in pale silver with the weight, the two thirds marked in
## cerulean, dawn rose once full. Rects and one label only (never a screen
## effect). Reads Judgment; changes nothing. Created by Judgment on its first
## step that has a HUD (the shape of the Dynasty's ScalesBar).
class_name JudgmentBar
extends Control

## Layout px of the bar itself.
const BAR := Vector2(220.0, 8.0)  # TUNING (not in GDD) drawing only
## Layout px from the HUD's top-centre block to this widget.
const DROP: float = 6.0  # TUNING (not in GDD) drawing only
## Layout px between the text and the bar.
const GAP: float = 2.0  # TUNING (not in GDD) drawing only

## The scales it shows.
var judgment: Judgment
## Its owning run (the HUD's layout).
var game: Game
## The text line.
var _label: Label
## The fill drawn last in px (a redraw only when it moves a pixel).
var _drawn_px: int = -9999
## The Verdict state drawn last.
var _drawn_verdict: bool = false
## The text colour set last (an override only when it changes).
var _text_col: Color = Color(0, 0, 0, 0)


## Builds the widget for `p_game` showing `p_judgment`.
func setup(p_game: Game, p_judgment: Judgment) -> void:
	game = p_game
	judgment = p_judgment
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiTheme.tier_label("", UiTheme.Tier.BODY, Palette.HOST_SILVER)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


## Lays the widget out under the HUD's top block and refreshes its text
## (Judgment, every tick).
func refresh() -> void:
	var hud := game.hud
	var w := hud.size.x  # HUD width (layout px).
	var text := "The Scales of Judgment"
	var col := Palette.HOST_SILVER
	if judgment.verdict_running():
		text = "THE VERDICT  %s" % EmpireReport._clock(ceilf(maxf(0.0, judgment.verdict_until - game.elapsed)))
		col = Palette.HOST_ROSE
	elif judgment.thirds_passed > 0:
		text = "The Scales of Judgment: a Judge is sent"
		col = Palette.HOST_STARLIGHT
	if _label.text != text:
		_label.text = text
	if col != _text_col:
		_text_col = col
		_label.add_theme_color_override("font_color", col)
	var lh := _label.get_minimum_size().y
	_label.size = Vector2(w, lh)
	_label.position = Vector2.ZERO
	size = Vector2(w, lh + GAP + BAR.y)
	position = Vector2(0.0, hud.top_centre_bottom() + DROP)
	var px := int(roundf(judgment.share() * BAR.x))
	if px != _drawn_px or judgment.verdict_running() != _drawn_verdict:
		_drawn_px = px
		_drawn_verdict = judgment.verdict_running()
		queue_redraw()


func _draw() -> void:
	if judgment == null or _label == null:
		return
	var lh := _label.get_minimum_size().y
	var r := Rect2(Vector2(size.x * 0.5 - BAR.x * 0.5, lh + GAP), BAR)
	draw_rect(r.grow(1.0), Color(Palette.HOST_INK, 0.85))
	draw_rect(r, Color(Palette.HOST_SILVER_DARK, 0.3))
	var fill := Palette.HOST_ROSE if _drawn_verdict else Palette.HOST_SILVER
	draw_rect(Rect2(r.position, Vector2(float(_drawn_px), BAR.y)), Color(fill, 0.85))
	for t: float in judgment.cfg["thirds"]:
		var x := r.position.x + t * BAR.x
		draw_rect(Rect2(Vector2(x - 0.5, r.position.y - 2.0), Vector2(1.0, BAR.y + 4.0)), Palette.HOST_CERULEAN)
