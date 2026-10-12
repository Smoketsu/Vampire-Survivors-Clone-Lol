## SanctumTerrainGlyphs — placeholder shapes of the Sanctum of Judgment's
## objectives and obstacles (GDD §8.3 art: "cathedral halls, cloisters,
## sacred courtyards, stained glass, giant statues, golden mosaics"; §11
## colour language: the Covenant's ivory, gold and pale stone). Static
## functions draw into the CanvasItem currently inside its _draw(), like
## Glyphs. MarchGlyphs.draw_enemy() / draw_obstacle() delegate the kinds they
## do not know here. Silhouettes:
##   Ward Crystal   = tall faceted ivory-gold crystal on a round plinth, halo
##   Sacred Altar   = wide stone altar block, gold cloth, candles, a sun disc
## Obstacles (the solid outline matches the collision shape):
##   saint_statue, fountain, stone_bench   (Outer Courtyards)
##   pillar, pew                           (Sanctified Halls)
##   cloister_arch, garden_bed, cypress    (Cloisters)
##   giant_statue, marble_column, reliquary (Final Sanctuary)
class_name SanctumTerrainGlyphs
extends RefCounted

## Dark outline colour behind bodies (same as Glyphs.OUTLINE).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)
## Pale cathedral stone.
const PALE_STONE := Color(0.62, 0.60, 0.56)
## Shaded pale stone.
const PALE_SHADE := Color(0.44, 0.42, 0.39)
## Polished marble.
const MARBLE := Color(0.78, 0.77, 0.80)
## Dark obstacle edge.
const EDGE := Color(0.08, 0.07, 0.07)
## Cast shadow under obstacles.
const SHADOW := Color(0, 0, 0, 0.35)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


# --- Objective structures ----------------------------------------------------------

## Draws Sanctum structure `kind`; returns false for kinds it does not know.
static func draw_structure(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"ward_crystal":
			_draw_crystal(ci, o, r, flash)
		"sacred_altar":
			_draw_altar(ci, o, r, flash)
		_:
			return false
	return true


## Ward Crystal: a tall faceted ivory-and-gold crystal on a round plinth,
## ringed by a faint halo (its chamber is drawn by SanctumDirector).
static func _draw_crystal(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.5, Color(Palette.GOLD, 0.14))
	ci.draw_arc(o + Vector2(0, -r * 0.6), r * 1.1, 0.0, TAU, 24, Color(Palette.IVORY, 0.45), 1.5)
	ci.draw_circle(o + Vector2(0, r * 0.45), r * 0.95, OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.45), r * 0.85, _c(PALE_SHADE, flash))
	ci.draw_circle(o + Vector2(0, r * 0.35), r * 0.62, _c(PALE_STONE, flash))
	var top := o + Vector2(0, -r * 1.9)
	var body := PackedVector2Array([top, o + Vector2(r * 0.55, -r * 0.6), o + Vector2(r * 0.35, r * 0.35),
		o + Vector2(-r * 0.35, r * 0.35), o + Vector2(-r * 0.55, -r * 0.6)])
	ci.draw_colored_polygon(body, _c(Palette.IVORY, flash))
	ci.draw_colored_polygon(PackedVector2Array([top, o + Vector2(r * 0.55, -r * 0.6), o + Vector2(r * 0.35, r * 0.35), o + Vector2(0, r * 0.1)]),
			_c(Palette.GOLD, flash))
	body.append(body[0])
	ci.draw_polyline(body, _c(Palette.GOLD.darkened(0.3), flash), 1.5)
	ci.draw_line(top, o + Vector2(0, r * 0.1), _c(Color(1, 1, 1, 0.8), flash), 1.0)


## Sacred Altar: a wide pale-stone altar block draped in gold cloth, two
## candles and a radiant sun disc standing behind it.
static func _draw_altar(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o + Vector2(0, -r * 1.05), r * 0.75, Color(Palette.GOLD, 0.18))
	for i in 10:  # Sun rays.
		var dir := Vector2.from_angle(TAU * float(i) / 10.0)
		ci.draw_line(o + Vector2(0, -r * 1.05) + dir * r * 0.5, o + Vector2(0, -r * 1.05) + dir * r * 0.95, _c(Color(Palette.GOLD, 0.8), flash), 1.5)
	ci.draw_circle(o + Vector2(0, -r * 1.05), r * 0.42, _c(Palette.GOLD, flash))
	var block := Rect2(o + Vector2(-r * 1.1, -r * 0.55), Vector2(r * 2.2, r * 1.25))
	ci.draw_rect(Rect2(block.position + Vector2(3, 4), block.size), SHADOW)
	ci.draw_rect(block.grow(1.5), OUTLINE)
	ci.draw_rect(block, _c(PALE_STONE, flash))
	ci.draw_rect(Rect2(block.position + Vector2(0, block.size.y * 0.7), Vector2(block.size.x, block.size.y * 0.3)), _c(PALE_SHADE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 0.55), Vector2(r * 0.9, r * 1.05)), _c(Palette.GOLD, flash))  # Altar cloth.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 0.4), Vector2(r * 0.2, r * 0.7)), _c(Palette.CRIMSON, flash))
	for sx: float in [-r * 0.8, r * 0.8]:  # Candles.
		ci.draw_rect(Rect2(o + Vector2(sx - 2.0, -r * 0.95), Vector2(4, r * 0.4)), _c(Palette.IVORY, flash))
		ci.draw_circle(o + Vector2(sx, -r * 1.02), 2.0, _c(Palette.FLAME, flash))


# --- Stage obstacles ----------------------------------------------------------------

## Draws Sanctum obstacle `o` (an Arena.Obstacle); returns false for kinds it
## does not know.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"saint_statue", "giant_statue":
			_draw_statue(ci, o)
		"fountain":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r, SHADOW)
			ci.draw_circle(c, r, EDGE)
			ci.draw_circle(c, r - 2.0, PALE_STONE)
			ci.draw_circle(c, r - 7.0, Color(0.22, 0.38, 0.48))  # Basin water.
			ci.draw_arc(c, r * 0.45, 0.0, TAU, 20, Color(0.55, 0.75, 0.85, 0.6), 1.5)
			ci.draw_circle(c, r * 0.22, PALE_STONE)
			ci.draw_circle(c + Vector2(0, -2), r * 0.1, Color(0.8, 0.92, 1.0))
		"pillar", "marble_column":
			var r := o.radius
			var stone := PALE_STONE if o.kind == "pillar" else MARBLE
			ci.draw_circle(c + Vector2(5, 6), r * 1.05, SHADOW)
			ci.draw_circle(c, r, EDGE)
			ci.draw_circle(c, r - 1.5, stone.darkened(0.15))
			ci.draw_circle(c, r * 0.72, stone)
			for i in 8:  # Fluting.
				var a := TAU * float(i) / 8.0
				ci.draw_line(c + Vector2.from_angle(a) * r * 0.3, c + Vector2.from_angle(a) * r * 0.7, stone.darkened(0.2), 1.0)
			ci.draw_arc(c, r - 1.5, 0.0, TAU, 24, Palette.GOLD.darkened(0.25), 1.5)
		"cypress":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r * 1.2, SHADOW)
			ci.draw_circle(c, r * 1.15, Color(0.08, 0.17, 0.11))
			ci.draw_circle(c + Vector2(-1, -1), r * 0.8, Color(0.12, 0.25, 0.15))
			ci.draw_circle(c + Vector2(-2, -2), r * 0.4, Color(0.18, 0.33, 0.2))
		_:
			if not o.is_circle and o.kind in ["stone_bench", "pew", "cloister_arch", "garden_bed", "reliquary"]:
				_draw_rect_obstacle(ci, o)
			else:
				return false
	return true


## A saint's statue (courtyards) or a giant statue (sanctuary): a square
## plinth with a robed figure seen from above, gold halo.
static func _draw_statue(ci: CanvasItem, o: Arena.Obstacle) -> void:
	var c := o.center
	var r := o.radius
	var stone := PALE_STONE if o.kind == "saint_statue" else MARBLE
	ci.draw_circle(c + Vector2(5, 7), r * 1.1, SHADOW)
	ci.draw_circle(c, r, EDGE)
	ci.draw_colored_polygon(Glyphs.regular_polygon(c, r - 1.5, 8, PI / 8.0), stone.darkened(0.25))  # Plinth.
	ci.draw_circle(c, r * 0.62, stone)  # Robed figure.
	ci.draw_circle(c + Vector2(0, -r * 0.15), r * 0.3, stone.lightened(0.15))  # Head.
	ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.42, 0.0, TAU, 20, Palette.GOLD, 2.0 if o.kind == "giant_statue" else 1.5)  # Halo.
	if o.kind == "giant_statue":
		ci.draw_line(c + Vector2(r * 0.35, -r * 0.6), c + Vector2(r * 0.35, r * 0.6), Palette.GOLD.darkened(0.2), 2.0)  # Sword.


## Rectangular Sanctum obstacles: benches, pews, cloister arches, garden beds
## and reliquaries.
static func _draw_rect_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> void:
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	var horizontal := o.half.x > o.half.y
	ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), SHADOW)
	ci.draw_rect(rect, EDGE)
	var inner := rect.grow(-1.5)
	match o.kind:
		"stone_bench":
			ci.draw_rect(inner, PALE_STONE)
			ci.draw_rect(inner.grow(-3.0), PALE_STONE.lightened(0.1))
		"pew":
			ci.draw_rect(inner, MarchGlyphs.WOOD)
			ci.draw_rect(inner.grow(-3.0), MarchGlyphs.WOOD.lightened(0.12))
			ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, 3.0) if horizontal else Vector2(3.0, inner.size.y)), MarchGlyphs.WOOD_DARK)
		"cloister_arch":
			# A wall pierced by arches: stone with dark arch openings along it.
			ci.draw_rect(inner, PALE_SHADE)
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 10.0
			while k < long_len - 8.0:
				var at := Vector2(rect.position.x + k, rect.get_center().y) if horizontal else Vector2(rect.get_center().x, rect.position.y + k)
				ci.draw_circle(at, minf(o.half.x, o.half.y) * 0.55, Color(0.12, 0.11, 0.1))
				k += 18.0
			ci.draw_rect(inner, Palette.GOLD.darkened(0.4), false, 1.0)
		"garden_bed":
			ci.draw_rect(inner, PALE_SHADE)
			ci.draw_rect(inner.grow(-3.0), Color(0.16, 0.26, 0.14))
			for i in 4:  # Flowers.
				var q := inner.position + Vector2(inner.size.x * (0.2 + 0.2 * float(i)), inner.size.y * (0.35 + 0.3 * float(i % 2)))
				ci.draw_circle(q, 2.5, Palette.IVORY if i % 2 == 0 else Palette.CRIMSON.lightened(0.2))
		_:
			# Reliquary: a gold-trimmed marble chest.
			ci.draw_rect(inner, MARBLE.darkened(0.1))
			ci.draw_rect(inner.grow(-4.0), MARBLE)
			ci.draw_rect(inner, Palette.GOLD.darkened(0.15), false, 2.0)
			ci.draw_circle(inner.get_center(), 3.0, Palette.GOLD)
