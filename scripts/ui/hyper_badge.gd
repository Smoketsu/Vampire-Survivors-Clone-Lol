## HyperBadge — the gold HYPER badge (HyperData): a gold sun disc with a dark
## five-pointed star (its pixel art icons/hyper_badge.png, else code-drawn), used on the stage-select cards of stages
## cleared on Hyper (Meta.hyper_clear_count()) and on the setup screen's
## Hyper card. `row()` builds the badge with its caption as one HBox.
class_name HyperBadge
extends Control

## Gold of the disc and rays.
const GOLD := Color(1.0, 0.82, 0.3)
## Dark star on the disc.
const STAR := Color(0.24, 0.14, 0.04)
## SpriteBank key of the badge's pixel art (drawn instead of the shapes when present).
const ART_KEY := "icons/hyper_badge"


func _init(px: float = 18.0) -> void:
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## An HBox holding a badge of `px` px and the caption `text` (gold, in type
## tier `tier`, BODY by default).
static func row(text: String, px: float = 18.0, tier: UiTheme.Tier = UiTheme.Tier.BODY) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(HyperBadge.new(px))
	var l := UiTheme.tier_label(text, tier, UiTheme.TEXT_GOLD)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(l)
	return hb


func _draw() -> void:
	# Pixel art (icons/hyper_badge.png, a 16 px sun) at the largest whole scale that fits, centred and sharp.
	var tex := SpriteBank.texture(ART_KEY)  # Badge art, or null (code-drawn below).
	if tex != null and SpriteBank.is_grid(ART_KEY):
		SpriteBank.apply_sharp(self)
		var k := maxf(1.0, floorf(minf(size.x, size.y) / float(tex.get_height())))  # Whole screen px per art px.
		var sz := Vector2(float(tex.get_width()), float(tex.get_height())) * k  # Drawn size (px).
		draw_texture_rect(tex, Rect2(((size - sz) * 0.5).round(), sz), false)
		return
	var c := size * 0.5  # Centre (px).
	var r := minf(size.x, size.y) * 0.5  # Outer radius (px).
	for i in 8:
		var d := Vector2.from_angle(TAU * float(i) / 8.0)  # Ray direction.
		draw_line(c + d * r * 0.62, c + d * r, GOLD, maxf(1.0, r * 0.16))
	draw_circle(c, r * 0.66, GOLD)
	draw_arc(c, r * 0.66, 0.0, TAU, 20, GOLD.darkened(0.4), 1.0)
	var pts := PackedVector2Array()  # Five-pointed star.
	for i in 10:
		var rr := r * (0.46 if i % 2 == 0 else 0.2)  # Point / notch radius.
		pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr)
	draw_colored_polygon(pts, STAR)
