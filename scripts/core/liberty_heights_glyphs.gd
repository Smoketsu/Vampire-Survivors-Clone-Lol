## LibertyHeightsGlyphs — drawing for LIBERTY HEIGHTS (Act VIII, Stage 24; GDD
## §15.0 "Liberty Heights (Act VIII phase 2)" and the rows after it) and its
## rewards: the code-drawn fallbacks used when an art PNG is missing (Paragon,
## the Fallen Hero) and the textures its rules draw:
##   * the car Atlas lifts and throws (draw_car(): the burning wreck sprite
##     structures/city_wreck, else a code car);
##   * Paragon's code body (draw_paragon(), only without bosses/paragon.png);
##   * the CRACKS his dives leave (draw_crack(): one made crack texture,
##     turned per crater; LibertyHeightsDirector keeps them);
##   * Hero's Fist (draw_fist(): a spectral fist, a soft disc and a made
##     knuckle shape).
## Every one is a texture drawn with draw_texture_rect (batched; no polygon
## redrawn every frame: the Web GL rule in CLAUDE.md). Purely visual.
class_name LibertyHeightsGlyphs
extends RefCounted

## Side (px) of the made crack texture.
const CRACK_TEX: int = 64
## The crack texture (made on first use; shared by every run).
static var _crack: Texture2D = null


## The car Atlas carries at `o` (local px of `ci`): the wreck sprite (32 px
## art) or a code car. `scale_k` sizes it.
static func draw_car(ci: CanvasItem, o: Vector2, scale_k: float) -> void:
	if SpriteBank.draw(ci, CityEnemyData.WRECK_SPRITE, o, false):
		return
	var w := 26.0 * scale_k
	var h := 13.0 * scale_k
	ci.draw_rect(Rect2(o - Vector2(w, h) * 0.5, Vector2(w, h)), Palette.CITY_CONCRETE)
	ci.draw_rect(Rect2(o - Vector2(w * 0.3, h * 0.5), Vector2(w * 0.6, h * 0.45)), Palette.CITY_ASPHALT_DARK)


## Paragon's code body (without his art): a white-and-silver figure with a blue
## cape, lifted by `lift`. `r` his body radius.
static func draw_paragon(ci: CanvasItem, lift: Vector2, r: float, flash: bool) -> void:
	var white := Palette.IVORY if not flash else Color.WHITE
	SpriteBank.draw_disc(ci, lift + Vector2(0.0, r * 0.1), r * 1.15, Palette.CITY_POLICE_BLUE)  # The cape.
	SpriteBank.draw_disc(ci, lift + Vector2(0.0, -r * 0.2), r * 0.9, white)  # The body.
	SpriteBank.draw_disc(ci, lift + Vector2(0.0, -r * 1.2), r * 0.45, Palette.CITY_CONCRETE_LIGHT)  # The head.


## A crack decal at `o` (local px of `ci`) of radius `r`, turned `angle` rad,
## at `alpha`. Visual only.
static func draw_crack(ci: CanvasItem, o: Vector2, r: float, angle: float, alpha: float) -> void:
	ci.draw_set_transform(o, angle, Vector2.ONE)
	ci.draw_texture_rect(_crack_texture(), Rect2(-Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 1.0, 1.0, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Hero's Fist at `o` (world px on `ci`), `r` px, at `alpha`: a soul-teal
## spectral fist (a disc with a knuckle bar), `evolved` gold-white (Doomsday).
static func draw_fist(ci: CanvasItem, o: Vector2, r: float, alpha: float, evolved: bool) -> void:
	var col := Palette.GOLD if evolved else Palette.NECRO_GREEN
	SpriteBank.draw_disc(ci, o, r * 1.4, Color(col, 0.25 * alpha))  # The glow.
	SpriteBank.draw_disc(ci, o, r, Color(col.lightened(0.3), 0.85 * alpha))  # The fist.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.55), Vector2(r * 1.6, r * 0.35)), Color(Palette.IVORY, 0.8 * alpha))  # The knuckles.


## The crack texture: dark fissures radiating from the centre (a fixed
## pattern; no RNG), on transparency.
static func _crack_texture() -> Texture2D:
	if _crack != null:
		return _crack
	var img := Image.create(CRACK_TEX, CRACK_TEX, false, Image.FORMAT_RGBA8)
	var c := float(CRACK_TEX) * 0.5
	var ink := Color(Palette.CITY_INK, 0.85)
	var rays := [0.2, 1.3, 2.1, 3.0, 3.9, 4.6, 5.5]  # Ray angles (rad).
	for i in rays.size():
		var a: float = rays[i]
		var len := c * (0.75 + 0.2 * float(i % 3) / 2.0)
		var x := c
		var y := c
		var steps := int(len)
		for s in steps:
			var bend := 0.25 * sin(float(s) * 0.35 + float(i))  # A jagged fissure.
			x += cos(a + bend)
			y += sin(a + bend)
			var px := int(x)
			var py := int(y)
			if px >= 0 and py >= 0 and px < CRACK_TEX and py < CRACK_TEX:
				img.set_pixel(px, py, ink)
				if s < steps / 2 and px + 1 < CRACK_TEX:
					img.set_pixel(px + 1, py, ink)  # Wider near the impact.
	for yy in CRACK_TEX:
		for xx in CRACK_TEX:
			var dd := Vector2(xx, yy).distance_to(Vector2(c, c))
			if dd < c * 0.28 and img.get_pixel(xx, yy).a < 0.1:
				img.set_pixel(xx, yy, Color(Palette.CITY_ASPHALT_DARK, 0.55 * (1.0 - dd / (c * 0.28))))  # The crater's scorch.
	_crack = ImageTexture.create_from_image(img)
	return _crack
