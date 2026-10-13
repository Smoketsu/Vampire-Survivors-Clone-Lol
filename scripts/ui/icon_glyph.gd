## IconGlyph — a UI Control that draws an ability / summon icon using the same
## shape code as the world (Glyphs.draw_icon), so a card's Archer icon looks
## exactly like an archer in the field. Optional level pips underneath.
## With `slot_frame` (the HUD ability bar) the icon sits in the UI kit's slot
## socket (UiTheme.style("slot"), UiArtData.SLOT_EXPAND px outside the icon
## square); an empty slot then shows just the socket.
class_name IconGlyph
extends Control

## Icon kind: summon class id, spell icon id, passive icon id or "heal".
var kind: String = ""
## Current level for pips (0 = no pips).
var level: int = 0
## Maximum level for pips.
var max_level: int = 0
## True for a HUD ability slot: draws the kit's slot socket behind the icon.
var slot_frame: bool = false


func _init(p_kind: String = "", min_size: Vector2 = Vector2(40, 40)) -> void:
	kind = p_kind
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Changes icon / level and redraws if different.
func set_icon(p_kind: String, p_level: int = 0, p_max: int = 0) -> void:
	if p_kind == kind and p_level == level and p_max == max_level:
		return
	kind = p_kind
	level = p_level
	max_level = p_max
	queue_redraw()


func _draw() -> void:
	var pip_h := 6.0 if max_level > 0 else 0.0
	var icon_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y - pip_h))
	if slot_frame:
		var socket := UiTheme.style("slot")  # Kit socket (a StyleBoxTexture when its PNG exists).
		if socket is StyleBoxTexture:
			SpriteBank.apply_sharp(self)
			draw_style_box(socket, icon_rect.grow(UiArtData.SLOT_EXPAND))
			if kind == "":
				return
	Glyphs.draw_icon(self, kind, icon_rect)
	if max_level > 0:
		var w := size.x / float(max_level)
		for i in max_level:
			var col := Palette.NECRO_GREEN if i < level else Color(0.25, 0.22, 0.3)
			draw_rect(Rect2(Vector2(float(i) * w + 1.0, size.y - 4.0), Vector2(w - 2.0, 4.0)), col)
