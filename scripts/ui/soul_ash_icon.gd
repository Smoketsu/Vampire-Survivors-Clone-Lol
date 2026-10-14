## SoulAshIcon — the Soul Ash currency icon of the front door screens (the
## main menu's plaque, the pre-run setup's total plaque; GDD §15.0 "Front door
## screens"). The ONE place that picks its look: the pixel-art badge
## assets/sprites/icons/soul_ash.png (ART_KEY) when it exists (drawn through
## SpriteBank, crisp), else the code-drawn ash mound (MetaGlyphs.draw_soul_ash)
## without a backdrop box. So new Soul Ash art shows up here with no code
## change. Purely visual.
class_name SoulAshIcon
extends Control

## Icon kind of the pixel-art badge (assets/sprites/icons/<ART_KEY>.png).
const ART_KEY: String = "soul_ash"


func _init(px: float = 28.0) -> void:
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)  # The icon box (px).
	if SpriteBank.has_grid_icon(ART_KEY) and SpriteBank.draw_icon_art(self, ART_KEY, r):
		return
	MetaGlyphs.draw_soul_ash(self, r.get_center() + Vector2(0.0, size.y * 0.08), minf(size.x, size.y) * 0.5)
