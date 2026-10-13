## SpriteBank: optional sprite art with a code-drawn fallback.
## Glyph-drawing code calls SpriteBank.draw(canvas_item, key, ...) first; if a
## PNG exists at SpriteData.ROOT + key + ".png" it is drawn (scaled to
## SpriteData.HEIGHTS[key], with a drop shadow and hit flash) and the call
## returns true, otherwise it returns false and the caller draws its glyph.
## Textures are loaded once and cached; missing files are cached as misses, so
## the check costs a dictionary lookup per draw. Facing is handled by the
## caller's node (scale.x = -1 mirrors the sprite, which faces right).
## Purely visual: it never touches gameplay state, so determinism is unaffected.
##
## Grid art (GDD §15.0 "Art pass (true pixel art)"): a PNG no taller than its
## SpriteData.HEIGHTS entry is true pixel art stored at art resolution and is
## drawn at exactly SpriteData.ART_SCALE screen px per texel, SHARP. Anything
## taller is a legacy placeholder (stored at 3x) and keeps today's smooth
## scaling to its HEIGHTS size. The rule is evaluated once per key and cached.
##
## Filtering: texture filtering is a CanvasItem property in Godot 4, but the
## grid texture is wrapped in a CanvasTexture whose own texture_filter is
## NEAREST, which overrides the drawing node's filter for that one draw call
## (both renderers, GL Compatibility included). So every caller (units,
## structures, bosses, the player, character / skin glyphs, HUD / card icons,
## the Grave Step trail) gets sharp grid art without touching its node, while
## legacy sprites, code-drawn shapes and text on the same node stay linear.
##
## Pixel snapping: with nearest filtering at a whole-number scale (2 at Zoom
## Normal, 3 at Close x1.5), every art pixel covers exactly that many viewport
## px whatever the node's sub-pixel position, so a moving sprite cannot
## shimmer: it moves in whole-pixel steps. The rect is placed on the art grid
## relative to the node origin (top-left on a multiple of ART_SCALE local px),
## so the feet offset adds no fraction and a mirrored (scale.x = -1) sprite
## lands on the same grid. The rect is NOT snapped to absolute viewport px
## here: units redraw only when their look changes, not when they move, so an
## absolute snap baked into _draw() would go stale at once. The project-wide
## rendering/2d/snap/snap_2d_transforms_to_pixel is not used either: it rounds
## every node (code-drawn shapes, HP bars, damage numbers step too), and with
## the smoothed Camera2D and camera shake it is prone to the known 1 px
## player-against-ground jitter; snap_2d_vertices_to_pixel would deform the
## small code-drawn circles and lines. Neither is needed for the whole-pixel look.
class_name SpriteBank
extends RefCounted

## key -> Texture2D (a nearest-filtered CanvasTexture wrapper for grid art), or
## null when no PNG exists for that key.
static var _cache: Dictionary = {}

## key -> true when that key's PNG is grid art (texture height <= its
## SpriteData.HEIGHTS entry), false for legacy art or no art. Filled with _cache.
static var _grid: Dictionary = {}

## Icon mode: when > 0, sprites are drawn this tall (px; grid art at the largest
## whole-number scale that fits, so at most this tall) with no drop shadow, so
## HUD / card icons that reuse the world glyph functions stay inside their
## boxes. Set and cleared by Glyphs.draw_icon() (and the character / skin
## previews); 0 = world drawing.
static var icon_cap: float = 0.0


## Returns the texture for sprite `key`, or null if there is no PNG for it.
## Grid art comes back wrapped in a nearest-filtered CanvasTexture (same size),
## so any caller drawing it directly (the Grave Step trail) draws it sharp.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := SpriteData.ROOT + key + ".png"  # Expected file location.
	var tex: Texture2D = null  # Loaded texture (null = no art yet).
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	var grid := tex != null and SpriteData.HEIGHTS.has(key) \
			and float(tex.get_height()) <= float(SpriteData.HEIGHTS[key])  # Stored at art resolution.
	if grid:
		var sharp := CanvasTexture.new()  # Per-draw filter override (see the header).
		sharp.diffuse_texture = tex
		sharp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex = sharp
	_cache[key] = tex
	_grid[key] = grid
	return tex


## True when sprite `key` is grid art (true pixel art at art resolution, drawn
## sharp at SpriteData.ART_SCALE); false for legacy art or no art.
static func is_grid(key: String) -> bool:
	texture(key)
	return bool(_grid[key])


## Size (px) at which draw() shows sprite `key` (texture `tex`, not null),
## honouring icon mode. Grid art: ART_SCALE x its texel size in the world; in
## icon mode the largest whole-number scale that fits icon_cap (minimum 1).
## Legacy art: scaled to its HEIGHTS height (or icon_cap), aspect kept.
static func _drawn_size(key: String, tex: Texture2D) -> Vector2:
	var tsize := Vector2(float(tex.get_width()), float(tex.get_height()))  # Texture size (texels).
	var icon := icon_cap > 0.0  # Drawing a HUD / card icon rather than a world unit.
	if bool(_grid[key]):
		var k := float(SpriteData.ART_SCALE)  # Screen px per texel.
		if icon:
			k = maxf(1.0, floorf(minf(icon_cap / tsize.y, icon_cap / tsize.x)))
		return tsize * k
	var h: float = icon_cap if icon else SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT)  # Drawn height (px).
	var size := Vector2(h * tsize.x / tsize.y, h)  # Drawn size (px).
	if icon and size.x > icon_cap:
		size *= icon_cap / size.x  # Wide sprites also fit the icon box.
	return size


## Height (px) at which draw() would show sprite `key` right now (icon mode
## included); without art, the HEIGHTS size (or icon_cap). Lets callers place
## overlays on the drawn sprite (SkinGlyphs' emblems).
static func drawn_height(key: String) -> float:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return icon_cap if icon_cap > 0.0 else float(SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT))
	return _drawn_size(key, tex).y


## True when sprite art exists for `key`.
static func has(key: String) -> bool:
	return texture(key) != null


## Draws sprite `key` centred near `o` on `ci` (scaled to its SpriteData
## height, with a drop shadow; brightened while `flash`). `tint` multiplies
## the colours when not flashing (components above 1 brighten): a playable
## character without its own art draws the necromancer tinted
## (CharacterGlyphs), and a skin's palette fallback tints too (SkinGlyphs).
## Grid art is drawn sharp at a whole-number scale on the art grid (see the
## header). Returns false and draws nothing when there is no art, so the
## caller can draw its glyph.
static func draw(ci: CanvasItem, key: String, o: Vector2, flash: bool, tint: Color = Color.WHITE) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return false
	var icon := icon_cap > 0.0  # Drawing a HUD / card icon rather than a world unit.
	var size := _drawn_size(key, tex)  # Drawn size (px).
	var h := size.y  # Drawn height (px).
	var centre := o + Vector2(0.0, 0.0 if icon else h * SpriteData.CENTER_OFFSET)  # Sprite centre (px).
	if not icon:
		# Drop shadow at the feet: a flattened circle via a scaled transform.
		var sw := h * SpriteData.SHADOW_WIDTH  # Shadow width (px).
		ci.draw_set_transform(centre + Vector2(0.0, h * 0.46), 0.0, Vector2(1.0, SpriteData.SHADOW_SQUASH))
		ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mod := SpriteData.FLASH_MODULATE if flash else tint  # Hit flash, or the caller's (character / skin) tint.
	var top_left := centre - size * 0.5  # Rect corner (px).
	if bool(_grid[key]):
		# On the art grid: whole art px from the node origin in the world (so a
		# 1 art px step stays one), whole px in an icon box.
		var step := 1.0 if icon else float(SpriteData.ART_SCALE)  # Grid pitch (local px).
		top_left = (top_left / step).round() * step
	ci.draw_texture_rect(tex, Rect2(top_left, size), false, mod)
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
