## ScalesBar — the HUD's BALANCE BAR of the Hall of Two Truths (temporary Act
## XII; GDD §15.0 "The Hall of Two Truths (Necropolis Dynasty phase 2)";
## owner-approved proposal: "a Balance bar appears on the HUD"). Drawn under the
## HUD's top-centre block, one line below the Sandstorm's: a short line of text
## (the favour, or the Weighing's countdown) over a bar whose left half is the
## necromancer's soul-teal and right half the Dynasty's dull bronze, with the
## two thresholds marked and a bone marker where the balance stands. Rects and
## one label only (never a screen effect). Reads TruthScales; changes nothing.
## Created by TwoTruthsDirector on first use when the run has a HUD.
class_name ScalesBar
extends Control

## Layout px of the bar itself.
const BAR := Vector2(220.0, 8.0)  # TUNING (not in GDD) drawing only
## Layout px from the HUD's top-centre block to this widget (the Sandstorm's
## line sits in between).
const DROP: float = 34.0  # TUNING (not in GDD) drawing only
## Layout px between the text and the bar.
const GAP: float = 2.0  # TUNING (not in GDD) drawing only
## The necromancer's side (soul-teal: the undead's colour).
const NECRO_COLOR := Color(0.55, 0.92, 0.84)  # TUNING (not in GDD) soul-teal
## The Dynasty's side (the dull bronze-gold: true gold stays the reward colour).
const DYNASTY_COLOR := Color(0.824, 0.733, 0.384)  # TUNING (not in GDD) DYN_BRONZE_LIGHT
## The marker (bone).
const MARK_COLOR := Color(0.94, 0.91, 0.82)  # TUNING (not in GDD) DYN_LINEN_LIGHT

## The Scales it shows.
var scales: TruthScales
## Its owning run (the HUD's layout).
var game: Game
## The text line.
var _label: Label
## The share drawn last (a redraw only when it moves a pixel).
var _drawn_px: int = -9999
## The favour drawn last.
var _drawn_favour: int = -9
## The text colour set last (an override only when it changes).
var _text_col: Color = Color(0, 0, 0, 0)


## Builds the widget for `p_game` showing `p_scales`.
func setup(p_game: Game, p_scales: TruthScales) -> void:
	game = p_game
	scales = p_scales
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiTheme.tier_label("", UiTheme.Tier.BODY, MARK_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


## Lays the widget out under the HUD's top block and refreshes its text
## (TwoTruthsDirector, every tick). `weigh_left` is the Weighing's seconds left
## (< 0 = not weighing).
func refresh(weigh_left: float) -> void:
	var hud := game.hud
	var w := hud.size.x  # HUD width (layout px).
	var text := "The Scales are level"
	var col := MARK_COLOR
	match scales.favour():
		1:
			text = "The Scales favour the Dynasty"
			col = DYNASTY_COLOR
		-1:
			text = "The Scales favour you"
			col = NECRO_COLOR
	if weigh_left >= 0.0:
		text = "THE WEIGHING  %s" % EmpireReport._clock(ceilf(weigh_left))
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
	var px := int(roundf(scales.share() * BAR.x * 0.5))
	if px != _drawn_px or scales.favour() != _drawn_favour:
		_drawn_px = px
		_drawn_favour = scales.favour()
		queue_redraw()


func _draw() -> void:
	if scales == null or _label == null:
		return
	var lh := _label.get_minimum_size().y
	var c := Vector2(size.x * 0.5, lh + GAP + BAR.y * 0.5)  # The bar's centre.
	var r := Rect2(c - BAR * 0.5, BAR)
	draw_rect(r.grow(1.0), Color(0.04, 0.04, 0.09, 0.85))
	draw_rect(Rect2(r.position, Vector2(BAR.x * 0.5, BAR.y)), Color(NECRO_COLOR, 0.35))
	draw_rect(Rect2(r.position + Vector2(BAR.x * 0.5, 0.0), Vector2(BAR.x * 0.5, BAR.y)), Color(DYNASTY_COLOR, 0.35))
	var t := float(scales.cfg["threshold"]) / maxf(float(scales.cfg["limit"]), 0.01) * BAR.x * 0.5  # Threshold offset (px).
	for x: float in [c.x - t, c.x + t]:
		draw_rect(Rect2(Vector2(x - 0.5, r.position.y - 2.0), Vector2(1.0, BAR.y + 4.0)), Color(MARK_COLOR, 0.55))
	draw_rect(Rect2(Vector2(c.x - 0.5, r.position.y), Vector2(1.0, BAR.y)), Color(MARK_COLOR, 0.35))
	var m := c.x + float(_drawn_px)  # The marker.
	var fill := Rect2(Vector2(minf(c.x, m), r.position.y), Vector2(absf(m - c.x), BAR.y))
	draw_rect(fill, Color(NECRO_COLOR if m < c.x else DYNASTY_COLOR, 0.85))
	draw_rect(Rect2(Vector2(m - 1.5, r.position.y - 3.0), Vector2(3.0, BAR.y + 6.0)), MARK_COLOR)
