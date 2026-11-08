## LionessTempleGlyphs — the drawings of the Temple of the Lioness (temporary
## Act XII, Stage 35, final stage 20; GDD §15.0 "The Temple of the Lioness
## (Dynasty phase 2)"). Static helpers only, visual only (nothing here can
## change a run):
##   * draw_obstacle(): the temple's one-size obstacle kinds (ONE_SIZE: the
##     brazier, the half-buried sphinx head, the broken sandstone blocks) from
##     their art (obstacles/<kind>.png, drawn like EnvironmentArt draws every
##     obstacle: centred on the shape, its bottom on the shape's bottom, a flat
##     shadow), since the art pass drew them at one size without a size suffix;
##     a code shape when a PNG is missing. Called from DynastyGlyphs
##     .draw_obstacle() (the Dynasty stages' own kinds first).
##   * draw_waking_row(): the Awakening Statues' glowing eyes over a row about
##     to wake (LionessTempleDirector).
##   * draw_seal(): the Lion Warden's sealed hall, a ring of standing
##     obelisks with one doorway gap (LionessTempleDirector).
##   * draw_wine_jar() and draw_sekhmet(): code fallbacks when the art is
##     missing (WineJarKit, BossSekhmet).
## Textures over polygons (discs from SpriteBank, sprites from EnvironmentArt).
class_name LionessTempleGlyphs
extends RefCounted

## Obstacle kinds drawn at one size from obstacles/<kind>.png (no size suffix).
const ONE_SIZE: Array[String] = ["dyn_brazier", "dyn_sphinx_head", "dyn_sandstone_blocks"]
## Art key of the obelisks standing round the sealed hall.
const SEAL_ART: String = "obstacles/dyn_obelisk_s"
## px between two obelisks of the seal.
const SEAL_STEP: float = 46.0
## Colour of the waking statues' eyes (a hot carnelian glow: a warning).
const EYE_GLOW: Color = Color(1.0, 0.45, 0.22)
## Colour of the dust a waking row sheds.
const DUST: Color = Color(0.94, 0.87, 0.65)


## Draws obstacle `o` when it is one of the temple's one-size kinds; false
## otherwise (Arena draws it its own way).
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	if not ONE_SIZE.has(o.kind):
		return false
	var foot := Vector2(o.radius, o.radius) if o.is_circle else o.half  # Footprint half-size (layout px).
	var base_y := o.center.y + foot.y  # The sprite's bottom edge.
	var tex := EnvironmentArt.texture(EnvironmentArtData.OBSTACLE_PREFIX + o.kind)
	var sw := foot.x * 2.0 * EnvironmentArtData.SHADOW_WIDTH  # Shadow width (px).
	_ellipse(ci, Vector2(o.center.x, base_y - 2.0) + EnvironmentArtData.SHADOW_OFFSET, sw * 0.5, EnvironmentArtData.SHADOW_SQUASH,
			Color(0.0, 0.0, 0.0, EnvironmentArtData.SHADOW_ALPHA))
	if tex == null:
		SpriteBank.draw_disc(ci, o.center, foot.x, Palette.DYN_INK)
		SpriteBank.draw_disc(ci, o.center, foot.x - 1.5, Palette.DYN_SAND_DARK if o.kind != "dyn_brazier" else Palette.DYN_BRONZE)
		if o.kind == "dyn_brazier":
			SpriteBank.draw_disc(ci, o.center + Vector2(0.0, -foot.x), foot.x * 0.6, Color(1.0, 0.6, 0.2, 0.8))  # Its fire.
		return true
	SpriteBank.apply_sharp(ci)
	var size := Vector2(float(tex.get_width()), float(tex.get_height()))  # Drawn size (1 art px = 1 layout px).
	var top_left := Vector2(o.center.x - size.x * 0.5, base_y - size.y).round()  # On whole layout px.
	ci.draw_texture_rect(tex, Rect2(top_left, size), false)
	return true


## The glowing eyes of statue row `o`, `k` (0 -> 1) of the way to waking at
## game time `now`: a pair of eyes per statue (3 on a short row, 5 on a long
## one) pulsing brighter, and dust at its feet.
static func draw_waking_row(ci: CanvasItem, o: Arena.Obstacle, k: float, now: float) -> void:
	var n := 5 if o.size_index > 0 else 3  # Statues on the row.
	var horiz := o.half.x >= o.half.y  # A row along x (else along y).
	var long := maxf(o.half.x, o.half.y) * 2.0  # The row's length (px).
	var base_y := o.center.y + (o.half.y if not o.is_circle else o.radius)  # Its bottom edge.
	var pulse := 0.55 + 0.45 * sin(now * 14.0)
	var a := clampf(0.25 + 0.75 * k, 0.0, 1.0) * pulse
	for i in n:
		var t := (float(i) + 0.5) / float(n) - 0.5  # -0.5 .. 0.5 along the row.
		var head: Vector2
		if horiz:
			head = Vector2(o.center.x + t * long * 0.9, base_y - 30.0)
		else:
			head = Vector2(o.center.x, o.center.y + t * long * 0.9 - 14.0)
		SpriteBank.draw_disc(ci, head, 5.0 + 3.0 * k, Color(EYE_GLOW, 0.25 * a))
		SpriteBank.draw_disc(ci, head + Vector2(-1.5, 0.0), 1.2, Color(EYE_GLOW, a))
		SpriteBank.draw_disc(ci, head + Vector2(1.5, 0.0), 1.2, Color(EYE_GLOW, a))
	var dust := maxf(o.half.x, o.half.y) + 6.0 + 10.0 * k  # The dust ring's reach (px).
	_ellipse(ci, Vector2(o.center.x, base_y), dust, 0.35, Color(DUST, 0.12 * k))


## The sealed hall: obelisks every SEAL_STEP px on the ring of `r` px at `c`,
## leaving the doorway at `door` rad (`gap` rad wide) open for the Warden.
static func draw_seal(ci: CanvasItem, c: Vector2, r: float, door: float, gap: float, now: float) -> void:
	var n := maxi(8, int(TAU * r / SEAL_STEP))  # Obelisks on a full ring.
	var tex := EnvironmentArt.texture(SEAL_ART)
	var glow := 0.18 + 0.06 * sin(now * 3.0)
	for i in n:
		var a := TAU * float(i) / float(n)
		if absf(wrapf(a - door, -PI, PI)) < gap * 0.5:
			continue  # The doorway.
		var p := c + Vector2.from_angle(a) * r
		_ellipse(ci, p, 10.0, 0.4, Color(Palette.DYN_CARNELIAN, glow))
		if tex != null:
			SpriteBank.apply_sharp(ci)
			var size := Vector2(float(tex.get_width()), float(tex.get_height()))
			ci.draw_texture_rect(tex, Rect2(Vector2(p.x - size.x * 0.5, p.y - size.y + 4.0).round(), size), false)
		else:
			SpriteBank.draw_disc(ci, p + Vector2(0.0, -8.0), 6.0, Palette.DYN_SAND_DARK)


## Code fallback of a red-wine jar (body radius `r`).
static func draw_wine_jar(ci: CanvasItem, r: float, flash: bool) -> void:
	var body := Color(1.0, 1.0, 1.0) if flash else Palette.DYN_CARNELIAN_DARK
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.6), r * 1.05, Palette.DYN_INK)
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.6), r * 0.9, body)
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 1.5), r * 0.45, Palette.DYN_SAND)


## Code fallback of Sekhmet (body radius `r`, lifted by `o`); `rage` adds the
## Feast's red glow.
static func draw_sekhmet(ci: CanvasItem, o: Vector2, r: float, flash: bool, rage: bool) -> void:
	var gown := Color(1.0, 1.0, 1.0) if flash else Palette.DYN_CARNELIAN
	if rage:
		SpriteBank.draw_disc(ci, o + Vector2(0.0, -r), r * 1.8, Color(Palette.DYN_CARNELIAN_LIGHT, 0.25))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.5), r, Palette.DYN_INK)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.5), r - 2.0, gown)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.7), r * 0.55, Palette.DYN_SAND)  # The lioness's head.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 2.5), r * 0.5, Color(1.0, 0.7, 0.25, 0.9))  # The sun disc.


## A flat ellipse of half-width `r` (height x `squash`) at `c` from the disc
## texture (no polygon).
static func _ellipse(ci: CanvasItem, c: Vector2, r: float, squash: float, color: Color) -> void:
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r * squash), Vector2(r, r * squash) * 2.0), false, color)
