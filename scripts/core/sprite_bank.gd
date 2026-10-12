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

## Icon mode: when > 0, sprites are drawn exactly this tall (px) with no drop
## shadow, so HUD / card icons that reuse the world glyph functions stay inside
## their boxes. Set and cleared by Glyphs.draw_icon(); 0 = world drawing.
static var icon_cap: float = 0.0


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
## height, with a drop shadow; brightened while `flash`). `tint` multiplies
## the colours when not flashing (components above 1 brighten): a playable
## character without its own art draws the necromancer tinted
## (CharacterGlyphs), and a skin's palette fallback tints too (SkinGlyphs).
## Returns false and draws nothing when there is no art, so the caller can
## draw its glyph.
static func draw(ci: CanvasItem, key: String, o: Vector2, flash: bool, tint: Color = Color.WHITE) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return false
	var icon := icon_cap > 0.0  # Drawing a HUD / card icon rather than a world unit.
	var h: float = icon_cap if icon else SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT)  # Drawn height (px).
	var size := Vector2(h * float(tex.get_width()) / float(tex.get_height()), h)  # Drawn size (px).
	if icon and size.x > icon_cap:
		size *= icon_cap / size.x  # Wide sprites also fit the icon box.
	var centre := o + Vector2(0.0, 0.0 if icon else h * SpriteData.CENTER_OFFSET)  # Sprite centre (px).
	if not icon:
		# Drop shadow at the feet: a flattened circle via a scaled transform.
		var sw := h * SpriteData.SHADOW_WIDTH  # Shadow width (px).
		ci.draw_set_transform(centre + Vector2(0.0, h * 0.46), 0.0, Vector2(1.0, SpriteData.SHADOW_SQUASH))
		ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mod := SpriteData.FLASH_MODULATE if flash else tint  # Hit flash, or the caller's (character / skin) tint.
	ci.draw_texture_rect(tex, Rect2(centre - size * 0.5, size), false, mod)
	return true


## Draws a flat sprite (projectile, orb) centred on `o`, rotated by `angle`
## (radians; the art points right), scaled so its longest side is
## SpriteData.FLAT_SIZES[key] px. No shadow or flash. `tint` multiplies the
## colours (e.g. a dim uncharged orb). Returns false when there is no art.
static func draw_flat(ci: CanvasItem, key: String, o: Vector2, angle: float, tint: Color = Color.WHITE) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return false
	var long_side: float = SpriteData.FLAT_SIZES.get(key, SpriteData.DEFAULT_FLAT_SIZE)  # Longest side (px).
	var w := float(tex.get_width())  # Texture width (px).
	var h := float(tex.get_height())  # Texture height (px).
	var k := long_side / maxf(w, h)  # Texture px -> world px.
	var size := Vector2(w, h) * k  # Drawn size (px).
	ci.draw_set_transform(o, angle, Vector2.ONE)
	ci.draw_texture_rect(tex, Rect2(-size * 0.5, size), false, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## Draws icon art for `kind` (assets/sprites/icons/<kind>.png) filling `rect`
## (SpriteData.ICON_ART_FILL of it, centred, aspect kept). Returns false when
## there is no art, so Glyphs.draw_icon() falls back to its drawn symbol.
static func draw_icon_art(ci: CanvasItem, kind: String, rect: Rect2) -> bool:
	var tex := texture("icons/" + kind)  # Icon art, or null.
	if tex == null:
		return false
	var box := minf(rect.size.x, rect.size.y) * SpriteData.ICON_ART_FILL  # Target size (px).
	var w := float(tex.get_width())  # Texture width (px).
	var h := float(tex.get_height())  # Texture height (px).
	var size := Vector2(w, h) * (box / maxf(w, h))  # Drawn size (px).
	ci.draw_texture_rect(tex, Rect2(rect.get_center() - size * 0.5, size), false)
	return true


## True when an effect animation strip exists for `id` (assets/sprites/effects/<id>.png).
static func has_anim(id: String) -> bool:
	return texture("effects/" + id) != null


## Draws frame `progress` (0..1 through the animation) of effect animation `id`
## centred on `o`, `diameter` px across (square frames in a horizontal strip;
## frame count = width / height). `alpha` fades it. Returns false without art.
static func draw_anim(ci: CanvasItem, id: String, o: Vector2, diameter: float, progress: float, alpha: float = 1.0) -> bool:
	var tex := texture("effects/" + id)  # Strip of square frames, or null.
	if tex == null:
		return false
	var fh := float(tex.get_height())  # Frame size (px).
	var frames := maxi(1, int(round(float(tex.get_width()) / fh)))  # Frame count.
	var f := mini(int(progress * float(frames)), frames - 1)  # Current frame.
	var src := Rect2(fh * float(f), 0.0, fh, fh)  # Frame region in the strip.
	var dst := Rect2(o - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)  # On-screen rect.
	ci.draw_texture_rect_region(tex, dst, src, Color(1, 1, 1, alpha))
	return true
