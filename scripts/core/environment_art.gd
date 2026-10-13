## EnvironmentArt: optional floor tile and obstacle sprites of the art pass,
## with the code-drawn floors and obstacle glyphs as the fallback whenever a
## PNG is missing (keys and numbers in EnvironmentArtData; manifest in
## docs/art/ART_BIBLE.md "Environments"). Like SpriteBank for units: textures
## are loaded once and cached (a missing file is cached as a miss, so a check
## is one dictionary lookup), and every draw function returns false when there
## is no art, so the caller draws its code version.
##
## Environment art is always grid art: 1 art px = 1 layout px, drawn on whole
## layout px through the sharp-pixel shader (SpriteBank.apply_sharp() on the
## drawing node; the textures are wrapped in LINEAR-filtered CanvasTextures,
## see the SpriteBank header).
##
## Floors (draw_floor()): the zone's base tile is drawn as ONE repeating rect
## over the whole drawn area, aligned to the world tile grid (multiples of
## EnvironmentArtData.TILE_SIZE from the origin), so the sharp-pixel blend at
## each tile edge reads the next tile's first texel through the wrap, exactly
## like a seamless tile should. The variant cells (if any variant PNG exists)
## are then drawn on top, one clamp-to-edge rect per cell, grouped by texture
## so each variant is one batch. A floor is therefore 1 + (variant count) draw
## calls, however large the area. Adjacent rects share exact whole-px edges,
## so there are no seams at any window scale or zoom.
##
## Purely visual: it reads obstacles and cell hashes but never changes them,
## so determinism and the autotest summaries are unaffected.
class_name EnvironmentArt
extends RefCounted

## key -> Texture2D (a linear-filtered CanvasTexture around the PNG, set to
## repeat for a base floor tile), or null when no PNG exists for that key.
static var _cache: Dictionary = {}

## Base tile key -> Array of Texture2D: the base tile (repeating) then each
## present variant (EnvironmentArtData.TILE_VARIANT_SUFFIXES, clamped), or []
## without a base tile.
static var _tile_sets: Dictionary = {}


## The texture of environment sprite `key` (wrapped for the sharp-pixel
## shader; `repeat` makes it tile when drawn larger than itself), or null when
## there is no PNG for it. One key is always loaded with the same `repeat`.
static func texture(key: String, repeat: bool = false) -> Texture2D:
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
			sharp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if repeat else CanvasItem.TEXTURE_REPEAT_DISABLED
			tex = sharp
	_cache[key] = tex
	return tex


## True when environment sprite `key` has a PNG.
static func has(key: String) -> bool:
	return texture(key) != null


## The textures of zone tile `base_key`: the base tile first (repeating), then
## its present variants; [] when the base tile has no PNG (the zone keeps its
## code floor).
static func tile_set(base_key: String) -> Array:
	if _tile_sets.has(base_key):
		return _tile_sets[base_key]
	var tiles: Array = []  # Base tile, then variants.
	var base := texture(base_key, true)  # The zone's base tile, or null.
	if base != null:
		tiles.append(base)
		for suffix in EnvironmentArtData.TILE_VARIANT_SUFFIXES:
			var v := texture(base_key + suffix)  # An optional variant.
			if v != null:
				tiles.append(v)
	_tile_sets[base_key] = tiles
	return tiles


## Index into a tile_set() of `count` (>= 1) textures for the cell whose stable
## hash is `h` (>= 0): variant i (1-based) for TILE_VARIANT_CHANCE of the
## cells each, the base tile (0) otherwise. Same cell, same tile, every redraw.
static func pick_tile(count: int, h: int) -> int:
	if count <= 1:
		return 0
	var roll := float((h >> EnvironmentArtData.TILE_VARIANT_HASH_SHIFT) % 1000) / 1000.0  # 0..1, from the cell hash.
	var i := int(roll / EnvironmentArtData.TILE_VARIANT_CHANCE) + 1  # Candidate variant (1-based).
	return i if i < count else 0


## Covers `rect` on `ci` with the floor tile `base_key` and its variants (see
## the header), the variant of tile cell (cx, cy) chosen from
## `cell_hash.call(cx, cy)` (the floor's own stable cell hash, an int >= 0).
## Returns false, drawing nothing, when the zone has no base tile PNG.
static func draw_floor(ci: CanvasItem, rect: Rect2, base_key: String, cell_hash: Callable) -> bool:
	var tiles := tile_set(base_key)  # Base tile, then variants ([] = no art).
	if tiles.is_empty():
		return false
	SpriteBank.apply_sharp(ci)
	var size := EnvironmentArtData.TILE_SIZE  # Tile side (layout px = art px).
	var c0 := Vector2i(floori(rect.position.x / size), floori(rect.position.y / size))  # First tile cell.
	var c1 := Vector2i(ceili(rect.end.x / size), ceili(rect.end.y / size))  # One past the last tile cell.
	# The base tile: one repeating rect on the world tile grid.
	ci.draw_texture_rect(tiles[0], Rect2(Vector2(c0) * size, Vector2(c1 - c0) * size), true)
	if tiles.size() == 1:
		return true
	# The variant cells, one texture at a time (one batch each).
	var picks: Array[int] = []  # Tile index per cell, row by row.
	for cy in range(c0.y, c1.y):
		for cx in range(c0.x, c1.x):
			picks.append(pick_tile(tiles.size(), int(cell_hash.call(cx, cy))))
	var cols := c1.x - c0.x  # Cells per row.
	for t in range(1, tiles.size()):
		for i in picks.size():
			if picks[i] == t:
				var cell := Vector2(float(c0.x + i % cols), float(c0.y + i / cols)) * size  # Cell top-left (layout px).
				ci.draw_texture_rect(tiles[t], Rect2(cell, Vector2(size, size)), false)
	return true


## Draws the March road strip for zone style `style` across `rect` (the
## ground's drawn area) on `ci`: the strip's own height (1 art px = 1 layout
## px; EnvironmentArtData.ROAD_HEIGHT in the manifest), centred on y = 0,
## repeated left-right at its own width from x = 0 (all pieces one texture, so
## one batch). Returns false (drawing nothing) without road art.
static func draw_road(ci: CanvasItem, rect: Rect2, style: String) -> bool:
	var tex := texture(EnvironmentArtData.ROAD_KEY + "_" + style)  # Zone override (the paved fortress road).
	if tex == null:
		tex = texture(EnvironmentArtData.ROAD_KEY)
	if tex == null:
		return false
	var h := float(tex.get_height())  # Strip height (layout px).
	var top := -floorf(h * 0.5)  # Strip top edge, on a whole px.
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


## Draws obstacle `o` from its sprite (o.art_key) on `ci`: centred
## horizontally on the collision shape, its bottom edge on the shape's bottom
## edge (plus the EnvironmentArtData feet offset), on whole layout px, with a
## flat drop shadow along that base line. Returns false (drawing nothing)
## without art, so Arena draws its code glyph.
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
	ci.draw_set_transform(Vector2(o.center.x, base_y - sh * EnvironmentArtData.SHADOW_RISE) + EnvironmentArtData.SHADOW_OFFSET, 0.0, Vector2(1.0, EnvironmentArtData.SHADOW_SQUASH))
	ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, EnvironmentArtData.SHADOW_ALPHA))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var size := Vector2(float(tex.get_width()), float(tex.get_height()))  # Drawn size (1 art px = 1 layout px).
	var top_left := Vector2(o.center.x - size.x * 0.5, base_y - size.y).round()  # On whole layout px.
	ci.draw_texture_rect(tex, Rect2(top_left, size), false)
	return true
