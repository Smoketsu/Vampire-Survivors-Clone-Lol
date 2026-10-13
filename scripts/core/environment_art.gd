## EnvironmentArt: optional floor tile and obstacle sprites of the art pass,
## with the code-drawn floors and obstacle glyphs as the fallback whenever a
## PNG is missing (keys and numbers in EnvironmentArtData; manifest in
## docs/art/ART_BIBLE.md "Environments"). Like SpriteBank for units: textures
## are loaded once and cached (a missing file is cached as a miss, so a check
## is one dictionary lookup), every function returns false / an empty list when
## there is no art so the caller draws its code version.
##
## Environment art is always grid art: 1 art px = 1 layout px, drawn on whole
## layout px through the sharp-pixel shader (SpriteBank.apply_sharp() on the
## drawing node; the textures are wrapped in LINEAR-filtered CanvasTextures,
## see the SpriteBank header). Tiles are drawn one rect per cell with
## clamp-to-edge sampling, so a variant next to a different tile never bleeds
## its opposite edge in; adjacent rects share exact whole-px edges, so there
## are no seams at any window scale or zoom.
##
## Purely visual: it reads obstacles and cell hashes but never changes them,
## so determinism and the autotest summaries are unaffected.
class_name EnvironmentArt
extends RefCounted

## key -> Texture2D (a linear-filtered CanvasTexture around the PNG), or null
## when no PNG exists for that key.
static var _cache: Dictionary = {}

## Base tile key -> Array of Texture2D: the base tile then each present
## variant (EnvironmentArtData.TILE_VARIANT_SUFFIXES), or [] without a base tile.
static var _tile_sets: Dictionary = {}


## The texture of environment sprite `key` (wrapped for the sharp-pixel
## shader), or null when there is no PNG for it.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := SpriteData.ROOT + key + ".png"  # Expected file location.
	var tex: Texture2D = null  # Wrapped texture (null = no art yet).
	if ResourceLoader.exists(path):
		var raw := load(path) as Texture2D  # The imported PNG.
		if raw != null:
			var sharp := CanvasTexture.new()  # Per-draw filter override (SpriteBank header).
			sharp.diffuse_texture = raw
			sharp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # The sharp-pixel shader needs linear samples.
			tex = sharp
	_cache[key] = tex
	return tex


## The textures of zone tile `base_key`: the base tile first, then its present
## variants; [] when the base tile has no PNG (the zone keeps its code floor).
static func tile_set(base_key: String) -> Array:
	if _tile_sets.has(base_key):
		return _tile_sets[base_key]
	var tiles: Array = []  # Base tile, then variants.
	var base := texture(base_key)  # The zone's base tile, or null.
	if base != null:
		tiles.append(base)
		for suffix in EnvironmentArtData.TILE_VARIANT_SUFFIXES:
			var v := texture(base_key + suffix)  # An optional variant.
			if v != null:
				tiles.append(v)
	_tile_sets[base_key] = tiles
	return tiles


## The tile of `tiles` (a non-empty tile_set()) for the cell whose stable
## hash is `h` (>= 0): variant i (1-based) for TILE_VARIANT_CHANCE of the
## cells each, the base tile otherwise. Same cell, same tile, on every redraw.
static func pick_tile(tiles: Array, h: int) -> Texture2D:
	if tiles.size() > 1:
		var roll := float((h >> EnvironmentArtData.TILE_VARIANT_HASH_SHIFT) % 1000) / 1000.0  # 0..1, from the cell hash.
		var i := int(roll / EnvironmentArtData.TILE_VARIANT_CHANCE) + 1  # Candidate variant (1-based).
		if i < tiles.size():
			return tiles[i]
	return tiles[0]


## Draws the March road strip for zone style `style` across `rect` (the
## ground's drawn area) on `ci`: EnvironmentArtData.ROAD_HEIGHT tall, centred
## on y = 0, repeated left-right at its own width from x = 0. Returns false
## (drawing nothing) without road art.
static func draw_road(ci: CanvasItem, rect: Rect2, style: String) -> bool:
	var tex := texture(EnvironmentArtData.ROAD_KEY + "_" + style)  # Zone override (the paved fortress road).
	if tex == null:
		tex = texture(EnvironmentArtData.ROAD_KEY)
	if tex == null:
		return false
	var h := EnvironmentArtData.ROAD_HEIGHT  # Strip height (layout px).
	var top := -h * 0.5  # Strip top edge (whole px: ROAD_HEIGHT is even).
	if rect.position.y > top + h or rect.end.y < top:
		return true  # Art exists; the road is just out of view.
	SpriteBank.apply_sharp(ci)
	var w := float(tex.get_width())  # Strip piece width (art px = layout px).
	var x := floorf(rect.position.x / w) * w  # First piece, on the strip's own grid from x = 0.
	while x < rect.end.x:
		ci.draw_texture_rect(tex, Rect2(x, top, w, h), false)
		x += w
	return true


## Sprite key (EnvironmentArtData key scheme) of an obstacle of kind `kind`
## in fixed size variant `size_index` of `size_count` (smallest first),
## `vertical` for a rect laid out along y. Arena stores it on the obstacle
## when it builds it (Obstacle.art_key).
static func obstacle_key(kind: String, size_index: int, size_count: int, vertical: bool) -> String:
	var suffixes: Array = EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES.get(size_count, ["m"])  # Size names, smallest first.
	var suffix := String(suffixes[clampi(size_index, 0, suffixes.size() - 1)])  # This variant's size name.
	var key := EnvironmentArtData.OBSTACLE_PREFIX + kind + "_" + suffix  # Base key.
	if vertical:
		key += EnvironmentArtData.VERTICAL_SUFFIX
	return key


## Draws obstacle `o` from its sprite (o.art_key) on `ci`, base-aligned on its
## collision shape (EnvironmentArtData feet rule) with a flat drop shadow.
## Returns false (drawing nothing) without art, so Arena draws its glyph.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	if o.art_key == "":
		return false
	var tex := texture(o.art_key)  # This kind / size / orientation's sprite, or null.
	if tex == null:
		return false
	SpriteBank.apply_sharp(ci)
	var foot := Vector2(o.radius, o.radius) if o.is_circle else o.half  # Footprint half-size (layout px).
	var base_y := o.center.y + foot.y + float(EnvironmentArtData.OBSTACLE_FOOT_OFFSETS.get(o.art_key, EnvironmentArtData.OBSTACLE_FOOT_OFFSET))  # Sprite bottom edge.
	# Shadow: a flattened ellipse hugging the base line (scaled-circle transform).
	var sw := foot.x * 2.0 * EnvironmentArtData.SHADOW_WIDTH  # Shadow width (px).
	var sh := sw * EnvironmentArtData.SHADOW_SQUASH  # Shadow height (px).
	ci.draw_set_transform(Vector2(o.center.x, base_y - sh * 0.5) + EnvironmentArtData.SHADOW_OFFSET, 0.0, Vector2(1.0, EnvironmentArtData.SHADOW_SQUASH))
	ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, EnvironmentArtData.SHADOW_ALPHA))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var size := Vector2(float(tex.get_width()), float(tex.get_height()))  # Drawn size (1 art px = 1 layout px).
	var top_left := (Vector2(o.center.x - size.x * 0.5, base_y - size.y)).round()  # On whole layout px.
	ci.draw_texture_rect(tex, Rect2(top_left, size), false)
	return true
