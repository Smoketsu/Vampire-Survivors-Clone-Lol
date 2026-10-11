## SpriteBank: optional sprite art with a code-drawn fallback.
## Glyph-drawing code calls SpriteBank.draw(canvas_item, key, ...) first; if a
## PNG exists at SpriteData.ROOT + key + ".png" it is drawn (scaled to
## SpriteData.HEIGHTS[key], with a drop shadow and hit flash) and the call
## returns true, otherwise it returns false and the caller draws its glyph.
## Textures are loaded once and cached; missing files are cached as misses, so
## the check costs a dictionary lookup per draw. Facing is handled by the
## caller's node (scale.x = -1 mirrors the sprite, which faces right).
## Purely visual: it never touches gameplay state, so determinism is unaffected.
class_name SpriteBank
extends RefCounted

## key -> Texture2D, or null when no PNG exists for that key.
static var _cache: Dictionary = {}


## Returns the texture for sprite `key`, or null if there is no PNG for it.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := SpriteData.ROOT + key + ".png"  # Expected file location.
	var tex: Texture2D = null  # Loaded texture (null = no art yet).
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[key] = tex
	return tex


## True when sprite art exists for `key`.
static func has(key: String) -> bool:
	return texture(key) != null


## Draws sprite `key` centred near `o` on `ci` (scaled to its SpriteData
## height, with a drop shadow; brightened while `flash`). Returns false and
## draws nothing when there is no art, so the caller can draw its glyph.
static func draw(ci: CanvasItem, key: String, o: Vector2, flash: bool) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return false
	var h: float = SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT)  # On-screen height (px).
	var size := Vector2(h * float(tex.get_width()) / float(tex.get_height()), h)  # Drawn size (px).
	var centre := o + Vector2(0.0, h * SpriteData.CENTER_OFFSET)  # Sprite centre (px).
	# Drop shadow at the feet: a flattened circle via a scaled transform.
	var sw := h * SpriteData.SHADOW_WIDTH  # Shadow width (px).
	ci.draw_set_transform(centre + Vector2(0.0, h * 0.46), 0.0, Vector2(1.0, SpriteData.SHADOW_SQUASH))
	ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mod := SpriteData.FLASH_MODULATE if flash else Color.WHITE  # Hit-flash tint.
	ci.draw_texture_rect(tex, Rect2(centre - size * 0.5, size), false, mod)
	return true
