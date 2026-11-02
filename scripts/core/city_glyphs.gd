## CityGlyphs — drawing for THE LAST LINE (Act VIII; GDD §15.0 "Act VIII
## foundation (phase 1)" and "City blocks"): the code-drawn fallback shapes of
## its kinds (drawn when a kind has no sprite art, assets/sprites/city/<kind>.png)
## in asphalt, concrete, neon, olive drab and the heroes' bright colours, with
## city-ink outlines; and every texture the shared rules draw:
##   * the city blocks' BUILDINGS (draw_building(): the art pass's rooftop
##     atlas tiles/city_roof_<style>.png, a 96 x 96 atlas of 3 x 3 cells of 32
##     px (corners at the corners, edges between them, the seamless centre in
##     the middle), drawn as the corners, the edges repeated along the sides
##     and the centre repeated inside, plus the rooftop decals
##     decals/city_<vent|ac_unit|water_tank|hatch|antenna>.png at hashed
##     spots; a code roof when the PNG is missing) and the WRECKS (draw_wreck():
##     structures/city_wreck burning, then structures/city_wreck_burnt, turned
##     along a vertical street);
##   * the vehicles' HEADLIGHT LANE (draw_headlights(): one small gradient
##     texture stretched along the lane), the squad car's LIGHT BAR (a soft
##     blue / red pulse at CityRulesData.SIREN_PULSE_HZ, at most 1 Hz: owner
##     rule, never a flash), the Supers' PLATE (draw_plate(): name, power and
##     weakness over the head) and CRACK mark, and the shells' LANDING CIRCLES
##     (draw_shell(): a ring texture, filling as it falls).
## Every one is a texture drawn with draw_texture_rect / draw_texture_rect_region
## (batched; no polygon redrawn every frame: the Web GL rule in CLAUDE.md).
## Building and street drawing happens only when Arena / CityGround redraw (the
## camera crossing a redraw cell). Purely visual.
class_name CityGlyphs
extends RefCounted

## Outline ink of the asphalt ramp (darkest).
const INK := Palette.CITY_INK
## Side (px) of one cell of a rooftop atlas.
const ROOF_CELL: int = 32
## Rooftop decal keys (the art pass's decals; a missing one is skipped).
const ROOF_DECALS: Array[String] = ["decals/city_vent", "decals/city_ac_unit", "decals/city_water_tank", "decals/city_hatch", "decals/city_antenna"]
## The antenna decal (its red lamp is drawn unlit; CityLamps pulses it).
const ANTENNA_DECAL: String = "decals/city_antenna"
## The lamp's centre in the antenna decal's own pixels (from its top-left; the
## 20 x 28 PNG has the 1 x 2 px lamp at column 10, rows 1-2).
const ANTENNA_LAMP: Vector2 = Vector2(10.5, 2.0)
## Code roof colour of each style (when its atlas PNG is missing).
const ROOF_COLORS := {
	"tenement": Color(0.30, 0.30, 0.33),
	"warehouse": Color(0.34, 0.33, 0.30),
	"bunker": Color(0.33, 0.36, 0.26),
	"tower": Color(0.36, 0.38, 0.42),
}
## Side (px) of the made ring texture.
const TEX_SIZE: int = 64

## The headlight gradient texture (made on first use).
static var _beam_tex: Texture2D = null
## The landing-ring texture (made on first use).
static var _ring_tex: Texture2D = null
## A plain white texel (plates, code shapes; made on first use).
static var _white: Texture2D = null


# =====================================================================================
# Kinds (code fallbacks)
# =====================================================================================

## Draws City kind `kind` when it has no sprite. Returns false when `kind` is
## not a City kind (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.city_def(kind)  # Its design row ({} = not a City kind).
	if row.is_empty():
		return false
	# Phase 2: each Act VIII stage's own fallbacks go here, before the shared kinds'.
	# --- Act VIII: Skid Row ---
	if SkidRowGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # Big Sal's Armoured Limo, Big Sal, the bounty board.
	var body := Palette.CITY_CONCRETE  # Body colour by tier.
	match String(row.get("tier", "gangs")):
		"gangs":
			body = Palette.CITY_NEON_PINK.darkened(0.35)
		"police":
			body = Palette.CITY_POLICE_BLUE
		"swat":
			body = Palette.CITY_ASPHALT
		"army":
			body = Palette.CITY_OLIVE
		"heroes":
			body = Palette.CITY_HERO_ORANGE
	if bool(row.get("civilian", false)):
		body = Palette.CITY_CONCRETE_LIGHT
	if flash:
		body = Color.WHITE
	if bool(row.get("vehicle", false)):
		var hl := float(row.get("half_length", r * 1.6))
		var hw := float(row.get("half_width", r))
		_box(ci, Rect2(o - Vector2(hl, hw), Vector2(hl, hw) * 2.0), body, true)
		_box(ci, Rect2(o - Vector2(hl * 0.35, hw * 0.7), Vector2(hl * 0.7, hw * 1.4)), body.darkened(0.3), false)  # Cab / turret.
		return true
	SpriteBank.draw_disc(ci, o + Vector2(1.5, 2.0), r, Color(0.0, 0.0, 0.0, 0.3))
	SpriteBank.draw_disc(ci, o, r, INK)
	SpriteBank.draw_disc(ci, o, r - 1.5, body)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.55), r * 0.42, Color(0.86, 0.72, 0.6) if not flash else Color.WHITE)  # Head.
	if kind == "riot_cop":
		_box(ci, Rect2(o + Vector2(r * 0.4, -r), Vector2(r * 0.35, r * 2.0)), Color(0.7, 0.8, 0.9, 0.7), false)  # The clear shield.
	return true


## A filled rect with an ink outline when `outline`.
static func _box(ci: CanvasItem, rect: Rect2, col: Color, outline: bool) -> void:
	if outline:
		ci.draw_texture_rect(white(), rect.grow(1.0), false, INK)
	ci.draw_texture_rect(white(), rect, false, col)


# =====================================================================================
# The city blocks (Arena; drawn only on Arena's redraws)
# =====================================================================================

## Draws building `o` (CityBlocks: kind "city_<style>", a rect): the rooftop
## atlas tiled over it, then its decals; the code roof when the atlas is missing.
static func draw_building(ci: CanvasItem, o: Arena.Obstacle) -> void:
	var style := o.kind.substr(5)  # "city_tenement" -> "tenement".
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	ci.draw_texture_rect(white(), Rect2(rect.position + Vector2(6.0, 8.0), rect.size), false, Color(0.0, 0.0, 0.0, 0.35))  # Drop shadow.
	var tex := EnvironmentArt.texture("tiles/city_roof_" + style)  # 96 x 96 atlas, or null.
	if tex != null:
		_draw_roof_atlas(ci, tex, rect)
	else:
		_draw_roof_code(ci, rect, style, o.variant)
	_draw_decals(ci, rect, o.variant)


## The rooftop atlas drawn as a nine-slice of ROOF_CELL px cells: corners at
## the corners, the edge cells repeated along the sides, the centre repeated
## inside (a building is a whole number of cells: 256 x 192 = 8 x 6).
static func _draw_roof_atlas(ci: CanvasItem, tex: Texture2D, rect: Rect2) -> void:
	var c := float(ROOF_CELL)
	var nx := maxi(2, int(rect.size.x / c))  # Cells across.
	var ny := maxi(2, int(rect.size.y / c))  # Cells down.
	for j in ny:
		var sy := 0 if j == 0 else (2 if j == ny - 1 else 1)  # Source row of the atlas.
		for i in nx:
			var sx := 0 if i == 0 else (2 if i == nx - 1 else 1)  # Source column of the atlas.
			ci.draw_texture_rect_region(tex, Rect2(rect.position + Vector2(float(i), float(j)) * c, Vector2(c, c)),
					Rect2(Vector2(float(sx), float(sy)) * c, Vector2(c, c)))


## The code roof: a flat roof in the style's colour, a lit parapet, seams.
static func _draw_roof_code(ci: CanvasItem, rect: Rect2, style: String, variant: int) -> void:
	var base: Color = ROOF_COLORS.get(style, Color(0.3, 0.3, 0.33))
	var p := CityBlockData.PARAPET
	ci.draw_texture_rect(white(), rect, false, INK)
	ci.draw_texture_rect(white(), rect.grow(-1.0), false, Palette.CITY_CONCRETE_LIGHT)
	ci.draw_texture_rect(white(), rect.grow(-p), false, base)
	var step := 24.0 + float(variant % 3) * 8.0  # Seam spacing (px).
	var y := rect.position.y + p + step
	while y < rect.end.y - p:
		ci.draw_texture_rect(white(), Rect2(Vector2(rect.position.x + p, y), Vector2(rect.size.x - 2.0 * p, 1.0)), false, base.darkened(0.25))
		y += step


## Two or three rooftop decals at spots hashed from `variant`, inside the
## parapet (each drawn at its own size; a missing PNG is skipped).
static func _draw_decals(ci: CanvasItem, rect: Rect2, variant: int) -> void:
	var h := absi(variant)
	var n := 2 + h % 2  # Decals on this roof.
	for k in n:
		var key := decal_key(variant, k)
		var tex := EnvironmentArt.texture(key)
		if tex == null:
			continue
		ci.draw_texture(tex, (decal_at(rect, variant, k) - tex.get_size() * 0.5).round())


## The decal key of roof decal `k` of a building of `variant` (the hash both
## the roof drawing and the antenna lamps read, so they always agree).
static func decal_key(variant: int, k: int) -> String:
	var hk := absi(hash(Vector2i(absi(variant), k)))
	return ROOF_DECALS[hk % ROOF_DECALS.size()]


## The centre (world px) of roof decal `k` of building rect `rect` of `variant`.
static func decal_at(rect: Rect2, variant: int, k: int) -> Vector2:
	var hk := absi(hash(Vector2i(absi(variant), k)))
	var inner := rect.grow(-float(ROOF_CELL))  # Keep off the parapet.
	return inner.position + Vector2(float((hk >> 4) % maxi(1, int(inner.size.x))), float((hk >> 12) % maxi(1, int(inner.size.y))))


## Appends to `out` the world position of every antenna's red lamp on building
## `o` (a roof whose decals include decals/city_antenna; none when that PNG is
## missing). CityLamps pulses them.
static func antenna_lamps(o: Arena.Obstacle, out: PackedVector2Array) -> void:
	var tex := EnvironmentArt.texture(ANTENNA_DECAL)
	if tex == null:
		return
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	var n := 2 + absi(o.variant) % 2  # Decals on this roof (as _draw_decals()).
	for k in n:
		if decal_key(o.variant, k) == ANTENNA_DECAL:
			out.append((decal_at(rect, o.variant, k) - tex.get_size() * 0.5).round() + ANTENNA_LAMP)


## Draws the wreck `o` (CityBlocks) lying along street axis `axis`, `age` s
## after it was placed: burning (with a soft fire glow) for WRECK burn_time s,
## then burnt out.
static func draw_wreck(ci: CanvasItem, o: Arena.Obstacle, axis: int, age: float) -> void:
	var burning := age < float(CityRulesData.WRECK["burn_time"])
	if burning:
		SpriteBank.draw_disc(ci, o.center, o.half.length() * 1.3, Color(Palette.CITY_SODIUM, 0.28))
	var tex := SpriteBank.texture(CityEnemyData.WRECK_SPRITE if burning else CityEnemyData.WRECK_BURNT_SPRITE)
	if tex != null:
		ci.draw_set_transform(o.center, PI * 0.5 if axis == 1 else 0.0, Vector2.ONE)
		ci.draw_texture(tex, (-tex.get_size() * 0.5).round())
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	_box(ci, rect, Color(0.16, 0.14, 0.13), true)
	_box(ci, rect.grow(-4.0), Color(0.24, 0.2, 0.18), false)
	if burning:
		_box(ci, Rect2(o.center - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Palette.CITY_HERO_ORANGE, false)


# =====================================================================================
# The rules' marks (drawn by the kits; visual only)
# =====================================================================================

## The headlight lane: a soft sodium beam from `from` along unit `dir` for
## `length` px, `half_width` px each side, in `ci`'s space under `base` (a
## mirrored enemy passes CourtGlyphs.unmirror_xf(), so world axes draw true),
## in `col` (sodium headlights; Blitz's crouched line is cyan).
static func draw_headlights(ci: CanvasItem, from: Vector2, dir: Vector2, length: float, half_width: float, alpha: float,
		base: Transform2D = Transform2D.IDENTITY, col: Color = Palette.CITY_SODIUM) -> void:
	if length < 1.0 or alpha <= 0.01:
		return
	ci.draw_set_transform_matrix(base * Transform2D(dir.angle(), from))  # Beam space: x along the lane.
	ci.draw_texture_rect(beam_texture(), Rect2(Vector2(0.0, -half_width), Vector2(length, half_width * 2.0)), false, Color(col, alpha))
	ci.draw_set_transform_matrix(base)


## The squad car's light bar at `o` (its roof): blue and red, each a soft disc
## fading in and out at `hz` (<= 1 Hz, owner rule: never a flash) at game
## time `t`; the two halves out of phase.
static func draw_light_bar(ci: CanvasItem, o: Vector2, t: float, hz: float) -> void:
	var k := 0.5 + 0.5 * sin(TAU * minf(hz, 1.0) * t)  # 0..1, a soft fade.
	SpriteBank.draw_disc(ci, o + Vector2(-4.0, 0.0), 4.0, Color(Palette.CITY_POLICE_BLUE, 0.25 + 0.55 * k))
	SpriteBank.draw_disc(ci, o + Vector2(4.0, 0.0), 4.0, Color(Palette.CITY_SIREN_RED, 0.25 + 0.55 * (1.0 - k)))


## A shell's landing circle at `o` of radius `r` (px), `fill` 0..1 of its fall
## (the ring brightens, the inner disc grows), in `col`.
static func draw_shell(ci: CanvasItem, o: Vector2, r: float, fill: float, col: Color) -> void:
	var k := clampf(fill, 0.0, 1.0)
	ci.draw_texture_rect(ring_texture(), Rect2(o - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(col, 0.45 + 0.45 * k))
	SpriteBank.draw_disc(ci, o, r * k, Color(col, 0.18 + 0.12 * k))


## A Super's plate over its head at `o` (the baseline centre): its name, then
## its power and weakness ("Fast. Can't turn."), the edge in `edge` (cyan
## guarded, hazard yellow exposed). Never drawn headless (no font there).
static func draw_plate(ci: CanvasItem, o: Vector2, title: String, line: String, edge: Color) -> void:
	var font := UiTheme.font_for()
	if font == null:
		return
	var fs := UiTheme.tier_px(UiTheme.Tier.BODY)  # 19 px.
	var w := maxf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) + 10.0
	var h := float(fs) * 2.0 + 4.0
	var box := Rect2(Vector2(roundf(o.x - w * 0.5), roundf(o.y - h)), Vector2(roundf(w), roundf(h)))
	ci.draw_texture_rect(white(), box.grow(1.0), false, edge)
	ci.draw_texture_rect(white(), box, false, INK)
	ci.draw_string(font, Vector2(box.position.x + 5.0, box.position.y + float(fs) - 2.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CITY_HERO_ORANGE)
	ci.draw_string(font, Vector2(box.position.x + 5.0, box.position.y + float(fs) * 2.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, edge)


## The crack mark of an exposed Super over a body of radius `r` (three short
## hazard-yellow strokes), `k` 0..1 of the window left.
static func draw_crack(ci: CanvasItem, r: float, k: float) -> void:
	var col := Color(CityRulesData.PLATE_EXPOSED, 0.4 + 0.5 * k)
	for i in 3:
		var a := -0.9 + 0.9 * float(i)  # Stroke angle (rad).
		ci.draw_set_transform(Vector2.from_angle(a - PI * 0.5) * r * 0.4, a, Vector2.ONE)
		ci.draw_texture_rect(white(), Rect2(Vector2(-1.0, -r * 0.5), Vector2(2.0, r)), false, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# =====================================================================================
# Textures (made once in code)
# =====================================================================================

## A plain white 2 x 2 texture (tinted when drawn).
static func white() -> Texture2D:
	if _white == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white


## The headlight beam: 16 x 8 white, bright at its start and fading along its
## length, soft across its width (tinted when drawn). Made once.
static func beam_texture() -> Texture2D:
	if _beam_tex != null:
		return _beam_tex
	var img := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		var across := 1.0 - absf(float(y) - 3.5) / 4.0  # 1 in the middle, 0 at the edges.
		for x in 16:
			var along := 1.0 - float(x) / 16.0  # 1 at the lamps.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(along * (0.4 + 0.6 * across), 0.0, 1.0)))
	_beam_tex = ImageTexture.create_from_image(img)
	return _beam_tex


## The landing ring: a white ring with soft edges (tinted when drawn). Made once.
static func ring_texture() -> Texture2D:
	if _ring_tex != null:
		return _ring_tex
	var n := TEX_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (float(n) - 1.0) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(float(x) - c, float(y) - c).length() / (float(n) * 0.5)  # 0 centre .. 1 edge.
			var a := clampf(1.0 - absf(d - 0.88) / 0.1, 0.0, 1.0)  # A ring near the edge.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_ring_tex = ImageTexture.create_from_image(img)
	return _ring_tex
