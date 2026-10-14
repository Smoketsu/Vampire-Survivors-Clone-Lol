## MaskIcon — a small pixel-art UI icon built from a character mask
## (MaskIconData.ICONS) instead of a PNG: the mask becomes a grid-art texture
## once (cached, 1 texel per art px) and is drawn at a whole-number scale
## through the sharp-pixel shader (SpriteBank.apply_sharp()), so it stays as
## crisp as the sprites at any window scale (GDD §15.0 "Front door screens").
## As a Control it sizes itself to the icon times `scale_px`; paint() lets any
## other Control paint one from its own _draw(). Purely visual.
class_name MaskIcon
extends Control

## MaskIconData.ICONS id drawn.
var icon_id: String = ""
## Layout px per art px (whole number, 1-4).
var scale_px: int = 2
## Colour multiplied over the icon (white = as drawn; alpha fades it).
var tint: Color = Color.WHITE

## Built textures: icon id -> Texture2D (a linear CanvasTexture for the shader).
static var _cache: Dictionary = {}


func _init(p_id: String = "", p_scale: int = 2, p_tint: Color = Color.WHITE) -> void:
	icon_id = p_id
	scale_px = maxi(1, p_scale)
	tint = p_tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = art_size(p_id) * float(scale_px)


## Changes the icon (and its size) and redraws.
func set_icon(p_id: String) -> void:
	icon_id = p_id
	custom_minimum_size = art_size(p_id) * float(scale_px)
	queue_redraw()


func _draw() -> void:
	var s := art_size(icon_id) * float(scale_px)  # Drawn size (px).
	paint(self, icon_id, ((size - s) * 0.5).round(), scale_px, tint)


## Size in art px of icon `id` (zero when unknown).
static func art_size(id: String) -> Vector2:
	var rows: Array = MaskIconData.ICONS.get(id, [])
	if rows.is_empty():
		return Vector2.ZERO
	return Vector2(float(String(rows[0]).length()), float(rows.size()))


## Draws icon `id` on `ci` with its top-left at `pos` (layout px, kept whole),
## `scale_px` layout px per art px, multiplied by `tint`. Gives `ci` the
## sharp-pixel material. Returns false when the id is unknown.
static func paint(ci: CanvasItem, id: String, pos: Vector2, scale_px: int, tint: Color = Color.WHITE) -> bool:
	var tex := texture(id)  # Built icon, or null.
	if tex == null:
		return false
	SpriteBank.apply_sharp(ci)
	var s := Vector2(float(tex.get_width()), float(tex.get_height())) * float(maxi(1, scale_px))  # Drawn size (px).
	ci.draw_texture_rect(tex, Rect2(pos.round(), s), false, tint)
	return true


## The texture of icon `id` (built from its mask on first use), or null.
static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var rows: Array = MaskIconData.ICONS.get(id, [])
	if rows.is_empty():
		return null
	var w := String(rows[0]).length()  # Width (art px).
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row := String(rows[y])  # One art row.
		for x in mini(w, row.length()):
			var ch := row[x]  # Colour key ("." = clear).
			if MaskIconData.PALETTE.has(ch):
				img.set_pixel(x, y, MaskIconData.PALETTE[ch])
	var ct := CanvasTexture.new()  # Linear samples for the sharp-pixel shader (SpriteBank header).
	ct.diffuse_texture = ImageTexture.create_from_image(img)
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cache[id] = ct
	return ct
