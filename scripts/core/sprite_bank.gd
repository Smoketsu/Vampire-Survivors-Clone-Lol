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
## Grid art (GDD §15.0 "Art pass (true pixel art)" and "Art pass grid: 1 art
## px = 1 screen px"): a PNG no taller than its SpriteData.HEIGHTS entry is true
## pixel art stored at art resolution and is drawn at exactly
## SpriteData.ART_SCALE (1) layout px per texel through the sharp-pixel shader.
## Anything taller is a legacy placeholder (stored at 3x) and keeps today's
## smooth scaling to its HEIGHTS size. The rule is evaluated once per key and
## cached.
##
## Sharpness: one art px is one layout px, but the window stretches the
## 1280x720 layout (x1.5 in a 1080p window) and Zoom Close doubles it, so an
## art pixel often covers a fractional number of screen px. Nearest filtering
## would then draw uneven pixels (some 1 px, some 2, shimmering in motion) and
## linear filtering would blur. So the grid texture is wrapped in a
## LINEAR-filtered CanvasTexture (the filter override applies to that one draw
## call), and the CanvasItem drawing it gets the shared sharp-pixel
## ShaderMaterial (apply_sharp(), set once, the first time that node draws grid
## art): crisp pixels whose edges blend over SpriteData.SHARP_EDGE_SOFTNESS
## screen px. The shader falls back to plain linear sampling when a texture is
## drawn smaller than its texels, and untextured shapes are unaffected, so legacy
## sprites, code-drawn shapes and text on the same node look as before. A node
## that already has its own material keeps it (and draws grid art smooth).
##
## Pixel placement: the rect's top-left is placed on whole art px relative to
## the node origin, so the feet offset adds no fraction and a mirrored
## (scale.x = -1) sprite lands on the same grid. It is NOT snapped to absolute
## viewport px: units redraw only when their look changes, not when they move,
## so an absolute snap baked into _draw() would go stale at once, and the
## shader already keeps sub-pixel positions even. The project-wide
## rendering/2d/snap/* settings stay off: they would step every code-drawn
## shape, HP bar and damage number and risk 1 px jitter with the smoothed camera.
##
## Walk cycles (WalkData, GDD §15.0 "Walk cycles"): a grid-art unit sprite may
## have a walk strip "<key>_walk.png", WalkData frames side by side, each
## exactly the still's size. When draw() draws such a key on a UnitLayer (a
## unit's body), it reports the frame count in the layer's walk_count and draws
## the layer's walk_frame from the strip, in the very rect the still would use
## (same corner, same size, same shadow, tint and flash), so a frame lines up
## pixel for pixel with the still. Everything else (icons, previews, death
## dissolves, layers with walk_frame -1) draws the still.
##
## Idle strips (IdleData, GDD §15.0 "Idle breathing bounce"): the same contract
## for "<key>_idle.png", the loop a unit plays while it stands. draw() reports
## its frame count in the layer's idle_count and draws the layer's idle_frame
## from it when no walk frame is shown (a walk frame always wins). Boss attack
## poses (draw_pose()) keep their pose stills.
class_name SpriteBank
extends RefCounted

## key -> Texture2D (a linear-filtered CanvasTexture wrapper for grid art, drawn
## through the sharp-pixel shader), or null when no PNG exists for that key.
static var _cache: Dictionary = {}

## key -> true when that key's PNG is grid art (texture height <= its
## SpriteData.HEIGHTS entry), false for legacy art or no art. Filled with _cache.
static var _grid: Dictionary = {}

## key -> walk strip texture of grid-art sprite `key` (a linear-filtered
## CanvasTexture, like grid art), or null when it has none or its size does not
## fit the still (height equal, width a multiple of the still's of at least 2).
static var _walk: Dictionary = {}

## key -> frames in that key's walk strip (0 = no strip). Filled with _walk.
static var _walk_frames: Dictionary = {}

## key -> idle strip texture of grid-art sprite `key` (IdleData; wrapped like
## _walk), or null when it has none or its size does not fit the still.
static var _idle: Dictionary = {}

## key -> frames in that key's idle strip (0 = no strip). Filled with _idle.
static var _idle_frames: Dictionary = {}

## The shared sharp-pixel ShaderMaterial (SpriteData.SHARP_SHADER), built on
## first use by apply_sharp(); null until then.
static var _sharp_material: ShaderMaterial = null
## The shared white disc texture (disc(); null until first asked for).
static var _disc: Texture2D = null

## Icon mode: when > 0, sprites are drawn this tall (px; grid art at the largest
## whole-number scale that fits, or scaled down to fit when even 1x is too big) with no drop shadow, so
## HUD / card icons that reuse the world glyph functions stay inside their
## boxes. Set and cleared by Glyphs.draw_icon() (and the character / skin
## previews); 0 = world drawing.
static var icon_cap: float = 0.0


## Returns the texture for sprite `key`, or null if there is no PNG for it.
## Grid art comes back wrapped in a linear-filtered CanvasTexture (same size);
## a caller drawing it directly (the Grave Step trail) calls apply_sharp() on
## its node so it draws sharp.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		if ArtMissLog.on and _cache[key] == null:
			ArtMissLog.miss(key)  # --art-misses: a fallback drawn (or a probe).
		return _cache[key]
	var path := SpriteData.ROOT + key + ".png"  # Expected file location.
	var tex: Texture2D = null  # Loaded texture (null = no art yet).
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	var grid := tex != null and ((SpriteData.HEIGHTS.has(key) \
			and float(tex.get_height()) <= float(SpriteData.HEIGHTS[key])) \
			or (SpriteData.FLAT_SIZES.has(key) \
			and float(maxi(tex.get_width(), tex.get_height())) <= float(SpriteData.FLAT_SIZES[key])) \
			or (key.begins_with("icons/") and tex.get_height() <= SpriteData.ICON_GRID_MAX_PX))  # Stored at art resolution.
	if grid:
		var sharp := CanvasTexture.new()  # Per-draw filter override (see the header).
		sharp.diffuse_texture = tex
		sharp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # The sharp-pixel shader needs linear samples.
		tex = sharp
	_cache[key] = tex
	_grid[key] = grid
	if ArtMissLog.on:
		if tex == null:
			ArtMissLog.miss(key)  # --art-misses: the art audit's record.
		else:
			ArtMissLog.hit(key)
	return tex


## Frames in the walk strip of sprite `key` (WalkData; 0 when it has no
## usable strip: no file, no grid still, or a size that does not fit). Loads
## and caches the strip on first use.
static func walk_frames(key: String) -> int:
	if _walk_frames.has(key):
		return int(_walk_frames[key])
	var strip := _load_strip(key, WalkData.SUFFIX)  # Wrapped strip texture, or null.
	_walk[key] = strip
	_walk_frames[key] = 0 if strip == null else strip.get_width() / texture(key).get_width()
	return int(_walk_frames[key])


## Frames in the idle strip of sprite `key` (IdleData; 0 when it has no
## usable strip: no file, no grid still, or a size that does not fit). Loads
## and caches the strip on first use, with walk_frames()' checks.
static func idle_frames(key: String) -> int:
	if _idle_frames.has(key):
		return int(_idle_frames[key])
	var strip := _load_strip(key, IdleData.SUFFIX)  # Wrapped strip texture, or null.
	_idle[key] = strip
	_idle_frames[key] = 0 if strip == null else strip.get_width() / texture(key).get_width()
	return int(_idle_frames[key])


## The strip "<key><suffix>.png" of grid-art sprite `key`, wrapped in a
## linear-filtered CanvasTexture like grid art, or null when there is no file,
## the still is not grid art, or the strip's size does not fit the still
## (height equal, width a whole multiple of the still's of at least 2).
static func _load_strip(key: String, suffix: String) -> Texture2D:
	var still := texture(key)  # The still: a strip is only used with grid art.
	var path := SpriteData.ROOT + key + suffix + ".png"  # Expected strip file.
	if still == null or not bool(_grid[key]) or not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D  # Raw strip.
	var w := still.get_width()  # Frame width = the still's width (texels).
	if tex == null or w <= 0 or tex.get_height() != still.get_height() \
			or tex.get_width() % w != 0 or tex.get_width() / w < 2:
		return null
	var sharp := CanvasTexture.new()  # Same per-draw filter override as grid art.
	sharp.diffuse_texture = tex
	sharp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sharp


## Gives `ci` the shared sharp-pixel ShaderMaterial so the grid art it draws
## stays crisp at any screen scale (see the header). Does nothing when `ci`
## already has a material of its own. Safe to call from _draw().
static func apply_sharp(ci: CanvasItem) -> void:
	if ci.material != null:
		return
	if _sharp_material == null:
		_sharp_material = ShaderMaterial.new()
		_sharp_material.shader = load(SpriteData.SHARP_SHADER) as Shader
		_sharp_material.set_shader_parameter("edge_softness", SpriteData.SHARP_EDGE_SOFTNESS)
	ci.material = _sharp_material


## True when sprite `key` is grid art (true pixel art at art resolution, drawn
## sharp at SpriteData.ART_SCALE); false for legacy art or no art.
static func is_grid(key: String) -> bool:
	texture(key)
	return bool(_grid[key])


## Size (px) at which draw() shows sprite `key` (texture `tex`, not null),
## honouring icon mode. Grid art: ART_SCALE x its texel size in the world; in
## icon mode the largest whole-number scale that fits icon_cap, or a smaller
## (fractional) scale when even 1x does not fit (the shader then samples it
## smoothly, like any minified texture).
## Legacy art: scaled to its HEIGHTS height (or icon_cap), aspect kept.
static func _drawn_size(key: String, tex: Texture2D) -> Vector2:
	var tsize := Vector2(float(tex.get_width()), float(tex.get_height()))  # Texture size (texels).
	var icon := icon_cap > 0.0  # Drawing a HUD / card icon rather than a world unit.
	if bool(_grid[key]):
		var k := float(SpriteData.ART_SCALE)  # Screen px per texel.
		if icon:
			var fit := minf(icon_cap / tsize.y, icon_cap / tsize.x)  # Scale that exactly fits the box.
			k = floorf(fit) if fit >= 1.0 else fit
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


## A white disc (alpha 1 inside its circle, a one-texel soft rim) on a clear
## SpriteData.DISC_PX square, made once: drop shadows and volley glows draw it as
## a tinted rect, which batches, instead of a draw_circle polygon whose buffers the
## renderer rebuilds on every redraw (drawing only).
static func disc() -> Texture2D:
	if _disc == null:
		var n := SpriteData.DISC_PX  # Texture size (px).
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var c := (float(n) - 1.0) * 0.5  # Centre (texel).
		var rad := float(n) * 0.5 - 0.5  # Radius (texels).
		for y in n:
			for x in n:
				var d := Vector2(float(x) - c, float(y) - c).length()
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(rad - d + 0.5, 0.0, 1.0)))
		_disc = ImageTexture.create_from_image(img)
	return _disc


## Draws a filled disc of radius `r` (px) at `o` on `ci` from disc(): the look of
## ci.draw_circle(o, r, color) without the per-redraw polygon.
static func draw_disc(ci: CanvasItem, o: Vector2, r: float, color: Color) -> void:
	ci.draw_texture_rect(disc(), Rect2(o - Vector2(r, r), Vector2(r, r) * 2.0), false, color)


## Draws sprite `key` centred near `o` on `ci` (scaled to its SpriteData
## height, with a drop shadow; brightened while `flash`). `tint` multiplies
## the colours when not flashing (components above 1 brighten): a playable
## character without its own art draws the necromancer tinted
## (CharacterGlyphs), and a skin's palette fallback tints too (SkinGlyphs).
## Grid art is drawn on the art grid through the sharp-pixel shader (see the
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
		draw_disc(ci, Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mod := SpriteData.FLASH_MODULATE if flash else tint  # Hit flash, or the caller's (character / skin) tint.
	var top_left := centre - size * 0.5  # Rect corner (px).
	if bool(_grid[key]):
		apply_sharp(ci)
		# On the art grid: whole art px from the node origin in the world (so a
		# 1 art px step stays one), whole px in an icon box.
		var step := 1.0 if icon else float(SpriteData.ART_SCALE)  # Grid pitch (local px).
		top_left = (top_left / step).round() * step
		if not icon and ci is UnitLayer:
			# A unit body: walk frame from its strip, else idle frame from its
			# idle strip, if it has them (see the header).
			var layer := ci as UnitLayer  # The body layer being drawn.
			var n := walk_frames(key)  # Frames in this sprite's walk strip (0 = none).
			layer.walk_count = n
			var m := idle_frames(key)  # Frames in this sprite's idle strip (0 = none).
			layer.idle_count = m
			if ArtMissLog.on and n == 0:
				ArtMissLog.strip_miss(key)  # --art-misses: a body without a walk strip.
			var fw := float(tex.get_width())  # Frame width (texels) = the still's width.
			if layer.walk_frame > 0 and layer.walk_frame < n:
				var src := Rect2(fw * float(layer.walk_frame), 0.0, fw, float(tex.get_height()))  # Frame in the strip.
				ci.draw_texture_rect_region(_walk[key], Rect2(top_left, size), src, mod)
				return true
			if layer.idle_frame > 0 and layer.idle_frame < m:
				var isrc := Rect2(fw * float(layer.idle_frame), 0.0, fw, float(tex.get_height()))  # Frame in the idle strip.
				ci.draw_texture_rect_region(_idle[key], Rect2(top_left, size), isrc, mod)
				return true
	ci.draw_texture_rect(tex, Rect2(top_left, size), false, mod)
	return true


## Draws stage boss `key` (its still sprite key) in attack pose `pose`
## (BossPoseData: 0 walk, 1 windup / cast, 2 special stance, 3 strike): the
## pose sprite "<key>_<suffix>" when BossPoseData lists one and its grid art
## exists, else the still exactly as draw() does. A pose sprite may be taller
## or wider than the still (a hammer raised overhead), so it is drawn centred
## on `o` horizontally with its bottom edge on the still's bottom edge, under
## the still's drop shadow: the boss's feet never jump when the pose changes.
## Returns false (nothing drawn) when not even the still has art.
static func draw_pose(ci: CanvasItem, key: String, pose: int, o: Vector2, flash: bool, tint: Color = Color.WHITE) -> bool:
	var still := texture(key)  # The boss's still sprite, or null.
	var suffix := String(BossPoseData.POSES.get(key, {}).get(pose, ""))  # This pose's file suffix ("" = none).
	if still == null or suffix == "" or icon_cap > 0.0 or not bool(_grid[key]):
		return draw(ci, key, o, flash, tint)
	var pose_key := key + "_" + suffix  # Pose sprite key.
	var tex := texture(pose_key)  # Pose art, or null.
	if tex == null or not bool(_grid[pose_key]):
		return draw(ci, key, o, flash, tint)
	var still_size := _drawn_size(key, still)  # The still's drawn size (px).
	var h := still_size.y  # The still's drawn height (px).
	var centre := o + Vector2(0.0, h * SpriteData.CENTER_OFFSET)  # The still's centre (px).
	var sw := h * SpriteData.SHADOW_WIDTH  # Shadow width (px), the still's.
	ci.draw_set_transform(centre + Vector2(0.0, h * 0.46), 0.0, Vector2(1.0, SpriteData.SHADOW_SQUASH))
	ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var size := _drawn_size(pose_key, tex)  # Pose drawn size (px).
	var bottom := centre.y + h * 0.5  # The still's bottom edge = the feet line (px).
	var top_left := Vector2(o.x - size.x * 0.5, bottom - size.y)  # Pose rect corner (px).
	var step := float(SpriteData.ART_SCALE)  # Grid pitch (local px).
	top_left = (top_left / step).round() * step
	apply_sharp(ci)
	ci.draw_texture_rect(tex, Rect2(top_left, size), false, SpriteData.FLASH_MODULATE if flash else tint)
	return true


## Draws a flat sprite (projectile, orb) centred on `o`, rotated by `angle`
## (radians; the art points right), scaled so its longest side is
## SpriteData.FLAT_SIZES[key] px. No shadow or flash. `tint` multiplies the
## colours (e.g. a dim uncharged orb). Grid art (longest side no more than
## its FLAT_SIZES entry: projectiles, orbs, pickups) is drawn 1:1 at
## SpriteData.ART_SCALE through the sharp-pixel shader, its corner on whole
## px when unrotated. `scale` (default 1) enlarges it further (an ice shell
## sized to a boss, a boulder high in its arc); the shader keeps the pixels
## sharp. Returns false when there is no art.
static func draw_flat(ci: CanvasItem, key: String, o: Vector2, angle: float, tint: Color = Color.WHITE, scale: float = 1.0) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null:
		return false
	var long_side: float = SpriteData.FLAT_SIZES.get(key, SpriteData.DEFAULT_FLAT_SIZE)  # Longest side (px).
	var w := float(tex.get_width())  # Texture width (px).
	var h := float(tex.get_height())  # Texture height (px).
	var grid := bool(_grid[key])  # True pixel art at art resolution.
	var k := float(SpriteData.ART_SCALE) if grid else long_side / maxf(w, h)  # Texture px -> world px.
	var size := Vector2(w, h) * k * scale  # Drawn size (px).
	var corner := -size * 0.5  # Rect corner in the rotated frame (px).
	if grid:
		apply_sharp(ci)
		if angle == 0.0:
			corner = (o + corner).round() - o  # Whole screen px, so unrotated pickups stay crisp.
	ci.draw_set_transform(o, angle, Vector2.ONE)
	ci.draw_texture_rect(tex, Rect2(corner, size), false, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## Draws sprite `key` like draw() (centred near `o`, feet below it, a drop
## shadow), but only its top `rise` (0..1) of rows, their bottom on the
## sprite's feet line: the sprite grows up out of the ground as `rise` goes
## 0 -> 1 and sinks back as it falls (Bone Wall segments rising and
## crumbling). `flip` mirrors it horizontally (a wall alternates its
## segments). `tint` multiplies the colours. Grid art only (it needs whole
## texel rows); returns false and draws nothing otherwise, so the caller
## draws its glyph.
static func draw_rising(ci: CanvasItem, key: String, o: Vector2, rise: float, flip: bool, tint: Color = Color.WHITE) -> bool:
	var tex := texture(key)  # Art for this key, or null.
	if tex == null or not bool(_grid[key]) or icon_cap > 0.0:
		return false
	var rows := ceilf(float(tex.get_height()) * clampf(rise, 0.0, 1.0))  # Texel rows shown (top of the sprite).
	if rows <= 0.0:
		return true
	var size := _drawn_size(key, tex)  # Full drawn size (px).
	var k := size.y / float(tex.get_height())  # Layout px per texel.
	var centre := o + Vector2(0.0, size.y * SpriteData.CENTER_OFFSET)  # Full sprite centre (px).
	var feet := centre.y + size.y * 0.5  # Feet line (px).
	var sw := size.y * SpriteData.SHADOW_WIDTH * clampf(rise, 0.0, 1.0)  # Shadow width (px), grows with the sprite.
	ci.draw_set_transform(centre + Vector2(0.0, size.y * 0.46), 0.0, Vector2(1.0, SpriteData.SHADOW_SQUASH))
	ci.draw_circle(Vector2.ZERO, sw * 0.5, Color(0.0, 0.0, 0.0, SpriteData.SHADOW_ALPHA * tint.a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var shown := Vector2(size.x, rows * k)  # Drawn part (px).
	var top_left := (Vector2(centre.x - size.x * 0.5, feet - shown.y) / k).round() * k  # On whole art px.
	var src := Rect2(0.0, 0.0, float(tex.get_width()), rows)  # Top rows of the texture.
	apply_sharp(ci)
	if flip:
		# Mirror about the sprite's vertical centre line.
		ci.draw_set_transform(Vector2(top_left.x * 2.0 + size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	ci.draw_texture_rect_region(tex, Rect2(top_left, shown), src, tint)
	if flip:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## True when `kind` has grid pixel-art icon art (a badge icon with its own
## border, SpriteData.ICON_GRID_MAX_PX): Glyphs.draw_icon() then skips its
## code-drawn backdrop.
static func has_grid_icon(kind: String) -> bool:
	return texture("icons/" + kind) != null and bool(_grid["icons/" + kind])


## Draws icon art for `kind` (assets/sprites/icons/<kind>.png) in `rect`,
## centred, aspect kept: grid pixel art fills the whole box through the
## sharp-pixel shader (it is a complete badge); legacy art fills
## SpriteData.ICON_ART_FILL of it, smooth. Returns false when there is no art,
## so Glyphs.draw_icon() falls back to its drawn symbol.
static func draw_icon_art(ci: CanvasItem, kind: String, rect: Rect2) -> bool:
	var tex := texture("icons/" + kind)  # Icon art, or null.
	if tex == null:
		return false
	var grid := bool(_grid["icons/" + kind])  # A pixel-art badge icon.
	if grid:
		apply_sharp(ci)
	var box := minf(rect.size.x, rect.size.y) * (1.0 if grid else SpriteData.ICON_ART_FILL)  # Target size (px).
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
## frame count = width / height). `alpha` fades it; `tint` multiplies its colours
## (the volley bursts, grey masks tinted with the shot's colour). Returns false without art.
static func draw_anim(ci: CanvasItem, id: String, o: Vector2, diameter: float, progress: float, alpha: float = 1.0, tint: Color = Color.WHITE) -> bool:
	var tex := texture("effects/" + id)  # Strip of square frames, or null.
	if tex == null:
		return false
	var fh := float(tex.get_height())  # Frame size (px).
	var frames := maxi(1, int(round(float(tex.get_width()) / fh)))  # Frame count.
	var f := mini(int(progress * float(frames)), frames - 1)  # Current frame.
	var src := Rect2(fh * float(f), 0.0, fh, fh)  # Frame region in the strip.
	var dst := Rect2(o - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)  # On-screen rect.
	ci.draw_texture_rect_region(tex, dst, src, Color(tint, tint.a * alpha))
	return true
