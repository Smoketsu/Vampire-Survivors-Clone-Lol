## Recolour — the one palette-swap path for skin recolours (RecolourData; GDD
## §15.0 "Ossuary recolours"). It remaps the pixels of a sprite texture to a
## recolour's colour family and caches the result per sprite and recolour, so
## every walk / idle strip and portrait that draws through SpriteBank.draw()'s
## `recolour` parameter (or PreRunHero's stage) follows with no extra art and
## no shader (CLAUDE.md: no shader may read the screen; this one needs none and
## costs the Web nothing per frame: the remap runs once, on the CPU, the first
## time a sprite is drawn in a recolour; Game warms the necromancer's at run
## start). Purely visual: nothing here touches gameplay state or any RNG.
class_name Recolour
extends RefCounted

## "<sprite key and strip>|<recolour id>" -> the recoloured Texture2D (same
## size and, for a CanvasTexture source, the same wrapper type and filter).
static var _cache: Dictionary = {}


## `c` mapped to recolour `id` (RecolourData; unknown id: unchanged). Alpha is kept.
static func color(c: Color, id: String) -> Color:
	if not RecolourData.RECOLOURS.has(id):
		return c
	var p: Dictionary = RecolourData.RECOLOURS[id]  # The recolour's numbers.
	var s := c.s  # Saturation 0..1.
	var w := minf(1.0, s * RecolourData.NEUTRAL_GAIN)  # How coloured the pixel is (0 = grey).
	var d := fposmod(c.h - RecolourData.REF_HUE + 0.5, 1.0) - 0.5  # Hue offset from the art's purple, -0.5..0.5.
	var nh := fposmod(float(p["hue"]) + d * float(p["spread"]) * w, 1.0)  # New hue.
	var ns := clampf(s * float(p["sat_mul"]) + float(p["tint_sat"]) * (1.0 - w), 0.0, 1.0)  # New saturation.
	var nv := clampf(c.v * float(p["val_mul"]) + float(p["val_add"]) * c.v, 0.0, 1.0)  # New value.
	return Color.from_hsv(nh, ns, nv, c.a)


## A recoloured copy of `img` (any format; the copy is RGBA8). Each distinct
## colour is mapped once. Transparent pixels stay as they are.
static func image(img: Image, id: String) -> Image:
	var out := img.duplicate() as Image  # Copy to edit.
	out.convert(Image.FORMAT_RGBA8)
	var data := out.get_data()  # RGBA bytes.
	var map: Dictionary = {}  # Packed RGB -> packed mapped RGB.
	var n := data.size()  # Byte count.
	var i := 0  # Byte index.
	while i < n:
		if data[i + 3] != 0:
			var key := (data[i] << 16) | (data[i + 1] << 8) | data[i + 2]  # Packed source colour.
			var m: int
			if map.has(key):
				m = map[key]
			else:
				var mapped := color(Color(float(data[i]) / 255.0, float(data[i + 1]) / 255.0, float(data[i + 2]) / 255.0), id)  # Mapped colour.
				m = (int(roundf(mapped.r * 255.0)) << 16) | (int(roundf(mapped.g * 255.0)) << 8) | int(roundf(mapped.b * 255.0))
				map[key] = m
			data[i] = (m >> 16) & 255
			data[i + 1] = (m >> 8) & 255
			data[i + 2] = m & 255
		i += 4
	return Image.create_from_data(out.get_width(), out.get_height(), false, Image.FORMAT_RGBA8, data)


## `src` recoloured to `id`, cached under `cache_key` (a sprite key plus a strip
## suffix, e.g. "player/necromancer|walk"). Returns `src` itself for no / an
## unknown recolour, a null source or one whose pixels cannot be read.
## A CanvasTexture source (SpriteBank's linear-filtered grid art) comes back
## as a CanvasTexture of the same filter.
static func texture(src: Texture2D, cache_key: String, id: String) -> Texture2D:
	if src == null or not RecolourData.RECOLOURS.has(id):
		return src
	var ck := cache_key + "|" + id  # Cache entry.
	if _cache.has(ck):
		return _cache[ck]
	var wrapper := src as CanvasTexture  # The filter wrapper, or null for a plain texture.
	var raw: Texture2D = wrapper.diffuse_texture if wrapper != null else src  # The texture holding the pixels.
	var img: Image = raw.get_image() if raw != null else null  # Its pixels (null / empty when unreadable).
	var result: Texture2D = src  # Falls back to the original.
	if img != null and not img.is_empty():
		var tex := ImageTexture.create_from_image(image(img, id))  # The recoloured pixels.
		result = tex
		if wrapper != null:
			var cw := CanvasTexture.new()  # Same per-draw filter override as the source.
			cw.diffuse_texture = tex
			cw.texture_filter = wrapper.texture_filter
			result = cw
	_cache[ck] = result
	return result


## Drops every cached recolour (the check tool).
static func clear_cache() -> void:
	_cache.clear()
