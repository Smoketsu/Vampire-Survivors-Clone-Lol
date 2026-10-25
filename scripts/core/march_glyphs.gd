## MarchGlyphs — every placeholder shape of the Crimson March (GDD §8.2 art,
## §11 colour language: the Covenant is crimson / ivory / silver / gold, holy
## magic radiant gold). Static functions draw into the CanvasItem currently
## inside its _draw(), like Glyphs. Each new kind keeps a silhouette of its
## own (GDD §10.5 "all classes must be readable"):
##   Shieldbearer   = tall crimson tower-shield slab in front of a small helm
##   Banner Bearer  = small round body under a tall swallow-tailed banner pole
##   Halberdier     = broad silver trapezoid with a long diagonal halberd
##   Watchtower     = square timber tower with crenellations
##   Siege Outpost  = round palisade around a crimson command tent
##   Ward Generator = gold crystal obelisk on a stone plinth, radiant rays
##   Supply Cart    = wagon box on two wheels with crates
##   Holy Standard  = tall gold pole, big crimson-gold banner, halo
##   Marshal Vael   = huge kite shield + flaming sword, crimson plume
## plus the stage's obstacles (draw_obstacle) and the battlefield-dead corpse
## pile (the march's empowered grave). Glyphs.draw_enemy() and
## Arena._draw_obstacle() delegate here for kinds they do not know; kinds
## unknown here go on to SanctumTerrainGlyphs (the Sanctum's objectives and
## obstacles).
class_name MarchGlyphs
extends RefCounted

## Dark outline colour behind bodies (same as Glyphs.OUTLINE).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)
## Timber brown for towers, carts, stakes and poles.
const WOOD := Color(0.36, 0.25, 0.14)
## Dark timber for shading.
const WOOD_DARK := Color(0.22, 0.15, 0.09)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


# --- Soldiers and structures ------------------------------------------------------

## Draws Crimson March enemy `kind`; returns false for kinds it does not know.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"shieldbearer":
			_draw_shieldbearer(ci, o, r, flash)
		"banner_bearer":
			_draw_banner_bearer(ci, o, r, flash)
		"halberdier":
			_draw_halberdier(ci, o, r, flash)
		"watchtower":
			_draw_watchtower(ci, o, r, flash)
		"outpost":
			_draw_outpost(ci, o, r, flash)
		"ward_generator":
			_draw_generator(ci, o, r, flash)
		"supply_cart":
			_draw_cart(ci, o, r, flash)
		"holy_standard":
			_draw_standard(ci, o, r, flash)
		_:
			return SanctumTerrainGlyphs.draw_structure(ci, kind, o, r, flash)  # Sanctum ward crystals and altars.
	return true


## Covenant Shieldbearer: a tall crimson tower shield (gold cross) held in
## front (+x), a small silver helm peeking over it.
static func _draw_shieldbearer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o + Vector2(-r * 0.3, 0), r * 0.75, OUTLINE)
	ci.draw_circle(o + Vector2(-r * 0.3, 0), r * 0.65, _c(Palette.SILVER.darkened(0.25), flash))
	ci.draw_circle(o + Vector2(-r * 0.25, -r * 0.75), r * 0.36, _c(Palette.SILVER, flash))
	var shield := Rect2(o + Vector2(r * 0.15, -r * 1.15), Vector2(r * 0.75, r * 2.25))
	ci.draw_rect(shield.grow(1.5), OUTLINE)
	ci.draw_rect(shield, _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(shield.position + Vector2(r * 0.3, r * 0.2), Vector2(r * 0.16, r * 1.8)), _c(Palette.GOLD, flash))
	ci.draw_rect(Rect2(shield.position + Vector2(r * 0.08, r * 0.7), Vector2(r * 0.6, r * 0.16)), _c(Palette.GOLD, flash))
	ci.draw_rect(shield, _c(Palette.SILVER, flash), false, 1.0)


## Banner Bearer: small ivory-tabarded body under a tall pole with a
## swallow-tailed crimson-and-gold war banner (the tallest silhouette).
static func _draw_banner_bearer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 0.9, OUTLINE)
	ci.draw_circle(o, r * 0.8, _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 0.4), Vector2(r * 0.5, r * 1.1)), _c(Palette.IVORY, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.75), r * 0.34, _c(Palette.SILVER, flash))
	var top := o + Vector2(r * 0.5, -r * 2.9)
	ci.draw_line(o + Vector2(r * 0.5, r * 0.9), top, _c(WOOD, flash), 2.0)
	ci.draw_circle(top, r * 0.16, _c(Palette.GOLD, flash))
	var flag := PackedVector2Array([top + Vector2(0, r * 0.15), top + Vector2(r * 1.5, r * 0.15),
		top + Vector2(r * 1.1, r * 0.75), top + Vector2(r * 1.5, r * 1.35), top + Vector2(0, r * 1.35)])
	ci.draw_colored_polygon(flag, _c(Palette.CRIMSON, flash))
	ci.draw_circle(top + Vector2(r * 0.55, r * 0.75), r * 0.24, _c(Palette.GOLD, flash))


## Crimson Halberdier: broad silver trapezoid armour, crimson tabard and a
## long diagonal halberd with a flared axe head.
static func _draw_halberdier(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := PackedVector2Array([o + Vector2(-r * 0.6, -r * 0.6), o + Vector2(r * 0.6, -r * 0.6),
		o + Vector2(r * 0.95, r * 0.9), o + Vector2(-r * 0.95, r * 0.9)])
	ci.draw_colored_polygon(body, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.5, -r * 0.5), o + Vector2(r * 0.5, -r * 0.5),
		o + Vector2(r * 0.82, r * 0.8), o + Vector2(-r * 0.82, r * 0.8)]), _c(Palette.SILVER, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.22, -r * 0.4), Vector2(r * 0.44, r * 1.15)), _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.32, -r * 1.15), Vector2(r * 0.64, r * 0.6)), _c(Color(0.62, 0.64, 0.7), flash))
	ci.draw_line(o + Vector2(-r * 0.2, -r * 0.85), o + Vector2(r * 0.2, -r * 0.85), _c(Color.BLACK, flash), 1.5)
	var butt := o + Vector2(-r * 0.6, r * 1.0)
	var head := o + Vector2(r * 1.4, -r * 1.7)
	ci.draw_line(butt, head, _c(WOOD, flash), 2.5)
	var dir := (head - butt).normalized()
	var perp := Vector2(-dir.y, dir.x)
	ci.draw_colored_polygon(PackedVector2Array([head - dir * r * 0.5, head - dir * r * 0.5 + perp * r * 0.75,
		head + perp * r * 0.55, head]), _c(Palette.SILVER, flash))
	ci.draw_line(head, head + dir * r * 0.45, _c(Palette.SILVER, flash), 2.0)


## Checkpoint Watchtower: square timber tower, crenellated top, crimson flag.
static func _draw_watchtower(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_rect(Rect2(o + Vector2(-r + 4, -r + 6), Vector2(r * 2.0, r * 2.0)), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(o - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), OUTLINE)
	ci.draw_rect(Rect2(o - Vector2(r, r) * 0.92, Vector2(r * 1.84, r * 1.84)), _c(WOOD, flash))
	for i in 4:
		var x := -r * 0.92 + float(i) * r * 0.5
		ci.draw_rect(Rect2(o + Vector2(x, -r * 1.15), Vector2(r * 0.3, r * 0.3)), _c(WOOD_DARK, flash))
	ci.draw_line(o + Vector2(-r * 0.9, -r * 0.3), o + Vector2(r * 0.9, -r * 0.3), _c(WOOD_DARK, flash), 2.0)
	ci.draw_line(o + Vector2(-r * 0.9, r * 0.4), o + Vector2(r * 0.9, r * 0.4), _c(WOOD_DARK, flash), 2.0)
	ci.draw_line(o + Vector2(0, -r * 1.15), o + Vector2(0, -r * 2.0), _c(WOOD_DARK, flash), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(1, -r * 2.0), o + Vector2(r * 0.8, -r * 1.8), o + Vector2(1, -r * 1.6)]), _c(Palette.CRIMSON, flash))


## Siege Outpost: a ring of palisade stakes around a striped command tent.
static func _draw_outpost(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o + Vector2(4, 6), r * 1.05, Color(0, 0, 0, 0.35))
	ci.draw_circle(o, r, _c(Color(0.16, 0.12, 0.08), flash))
	for i in 14:
		var a := TAU * float(i) / 14.0
		var p := o + Vector2.from_angle(a) * r * 0.95
		ci.draw_circle(p, r * 0.13, _c(WOOD, flash))
	ci.draw_circle(o, r * 0.62, _c(Palette.IVORY, flash))
	for i in 6:
		var a := TAU * float(i) / 6.0
		ci.draw_line(o, o + Vector2.from_angle(a) * r * 0.62, _c(Palette.CRIMSON, flash), 3.0)
	ci.draw_circle(o, r * 0.16, _c(Palette.GOLD, flash))
	ci.draw_line(o, o + Vector2(0, -r * 1.3), _c(WOOD_DARK, flash), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(1, -r * 1.3), o + Vector2(r * 0.7, -r * 1.12), o + Vector2(1, -r * 0.94)]), _c(Palette.CRIMSON, flash))


## Holy Ward Generator: a gold crystal obelisk on a stone plinth with
## radiant rays (its holy zone is drawn by StageDirector around it).
static func _draw_generator(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.6, Color(Palette.GOLD, 0.12))
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0)
		ci.draw_line(o + dir * r * 0.9, o + dir * r * 1.5, Color(Palette.GOLD, 0.45), 1.5)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.85, r * 0.15), Vector2(r * 1.7, r * 0.7)), OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.78, r * 0.2), Vector2(r * 1.56, r * 0.6)), _c(Palette.STONE.lightened(0.15), flash))
	var crystal := PackedVector2Array([o + Vector2(0, -r * 1.35), o + Vector2(r * 0.45, -r * 0.2),
		o + Vector2(r * 0.3, r * 0.25), o + Vector2(-r * 0.3, r * 0.25), o + Vector2(-r * 0.45, -r * 0.2)])
	ci.draw_colored_polygon(crystal, _c(Palette.GOLD, flash))
	ci.draw_line(o + Vector2(0, -r * 1.3), o + Vector2(0, r * 0.2), _c(Palette.IVORY, flash), 1.5)


## Supply Cart: a wagon box with crates and a crimson cover, on two wheels.
static func _draw_cart(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_rect(Rect2(o + Vector2(-r * 1.1 + 3, -r * 0.6 + 5), Vector2(r * 2.2, r * 1.2)), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(o + Vector2(-r * 1.15, -r * 0.65), Vector2(r * 2.3, r * 1.3)), OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 1.05, -r * 0.55), Vector2(r * 2.1, r * 1.1)), _c(WOOD, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.9, -r * 0.45), Vector2(r * 0.8, r * 0.8)), _c(Color(0.5, 0.38, 0.22), flash))
	ci.draw_rect(Rect2(o + Vector2(0.0, -r * 0.45), Vector2(r * 0.9, r * 0.8)), _c(Palette.CRIMSON, flash))
	ci.draw_line(o + Vector2(0.0, -r * 0.45), o + Vector2(r * 0.9, r * 0.35), _c(Palette.GOLD, flash), 1.0)
	for wx: float in [-r * 0.6, r * 0.6]:
		ci.draw_circle(o + Vector2(wx, r * 0.75), r * 0.32, _c(WOOD_DARK, flash))
		ci.draw_circle(o + Vector2(wx, r * 0.75), r * 0.1, _c(Palette.SILVER, flash))
	ci.draw_line(o + Vector2(r * 1.05, 0), o + Vector2(r * 1.6, -r * 0.1), _c(WOOD_DARK, flash), 2.0)  # Draw pole.


## Holy Standard: a tall gold pole with a large crimson-and-gold banner and
## a halo at the top (its aura ring is drawn by Enemy._draw()).
static func _draw_standard(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.2, OUTLINE)
	ci.draw_circle(o, r * 1.0, _c(Palette.STONE, flash))
	var top := o + Vector2(0, -r * 4.0)
	ci.draw_line(o, top, _c(Palette.GOLD, flash), 3.0)
	ci.draw_arc(top, r * 0.7, 0.0, TAU, 20, _c(Palette.GOLD, flash), 2.0)
	var flag := Rect2(top + Vector2(r * 0.2, r * 0.6), Vector2(r * 2.0, r * 2.4))
	ci.draw_rect(flag, _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(flag.position + Vector2(r * 0.85, r * 0.25), Vector2(r * 0.3, r * 1.8)), _c(Palette.GOLD, flash))
	ci.draw_rect(Rect2(flag.position + Vector2(r * 0.35, r * 0.8), Vector2(r * 1.3, r * 0.3)), _c(Palette.GOLD, flash))
	ci.draw_rect(flag, _c(Palette.IVORY, flash), false, 1.5)


## Faint gold ring showing an aura's reach (Banner Bearer, Holy Standard): a
## dashed ring of gold pieces (CovenantFx, GDD §15.0 "Act I enemy AoE art")
## over the faint disc, or the code ring without the art.
static func draw_aura(ci: CanvasItem, radius: float) -> void:
	if CovenantFx.has(CovenantFxData.AURA_DASH):
		CovenantFx.soft_disc(ci, Vector2.ZERO, radius, Color(Palette.GOLD, 0.035))
		CovenantFx.ring(ci, Vector2.ZERO, radius, CovenantFxData.AURA_DASH, Color(1.0, 1.0, 1.0, CovenantFxData.AURA_ALPHA), 1.0)
		return
	ci.draw_circle(Vector2.ZERO, radius, Color(Palette.GOLD, 0.035))
	ci.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(Palette.GOLD, 0.28), 1.0)


## Small gold chevron over a soldier buffed by an aura (its pixel art,
## MarkerArtData.BUFF_CHEVRON, when present).
static func draw_buffed(ci: CanvasItem, c: Vector2, s: float) -> void:
	if SpriteBank.draw_flat(ci, MarkerArtData.BUFF_CHEVRON, c, 0.0):
		return
	ci.draw_polyline(PackedVector2Array([c + Vector2(-s, s * 0.5), c + Vector2(0, -s * 0.5), c + Vector2(s, s * 0.5)]), Palette.GOLD, 2.0)


# --- Marshal Vael -----------------------------------------------------------------

## Marshal Vael: crimson cape, silver plate octagon with a crimson plume, a
## great kite shield in front (+x) and a flaming holy sword.
## pose 0 = walking, 1 = winding up a special (sword raised, flames high),
## 2 = Shieldwall (shield raised and enlarged, gold rim), 3 = recovering.
## `last_stand` adds a burning aura (Last Stand, below 30% HP).
static func draw_vael(ci: CanvasItem, o: Vector2, r: float, flash: bool, pose: int, last_stand: bool) -> void:
	if SpriteBank.draw_pose(ci, "bosses/vael", pose, o, flash):
		return  # Sprite art exists (bosses/vael.png, plus its attack poses, BossPoseData).
	if last_stand:
		ci.draw_circle(o, r * 1.7, Color(Palette.FLAME, 0.16))
		ci.draw_arc(o, r * 1.7, 0.0, TAU, 32, Color(Palette.FLAME, 0.75), 2.0)
	ci.draw_circle(o + Vector2(-r * 0.2, r * 0.25), r * 1.05, _c(Palette.DARK_CRIMSON, flash))
	var body := Glyphs.regular_polygon(o, r * 0.82, 8, PI / 8.0)
	ci.draw_colored_polygon(body, _c(Palette.SILVER if pose != 3 else Color(0.6, 0.6, 0.65), flash))
	body.append(body[0])
	ci.draw_polyline(body, _c(Palette.CRIMSON, flash), 2.0)
	ci.draw_circle(o + Vector2(-r * 0.1, -r * 0.8), r * 0.36, _c(Color(0.7, 0.72, 0.78), flash))
	ci.draw_line(o + Vector2(-r * 0.3, -r * 0.82), o + Vector2(r * 0.1, -r * 0.82), _c(Color.BLACK, flash), 1.5)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.15, -r * 1.1), o + Vector2(-r * 0.75, -r * 1.55),
		o + Vector2(-r * 0.3, -r * 0.95)]), _c(Palette.CRIMSON, flash))  # Plume.
	# Flaming holy sword (behind the shield, raised in a windup).
	var grip := o + Vector2(-r * 0.55, r * 0.35)
	var tip := o + (Vector2(-r * 0.3, -r * 2.1) if pose == 1 else Vector2(-r * 1.4, -r * 1.1))
	ci.draw_line(grip, tip, _c(Palette.IVORY, flash), 3.0)
	ci.draw_line(grip, tip, Color(Palette.FLAME, 0.55), 6.0)
	ci.draw_circle(tip, r * (0.32 if pose == 1 else 0.22), Color(Palette.FLAME, 0.8))
	ci.draw_line(grip + Vector2(-r * 0.2, -r * 0.05), grip + Vector2(r * 0.2, r * 0.05), _c(Palette.GOLD, flash), 2.5)
	# Kite shield in front: bigger and gold-rimmed during Shieldwall.
	var k := 1.35 if pose == 2 else 1.0
	var sx := r * (0.55 if pose == 2 else 0.45)
	var shield := PackedVector2Array([o + Vector2(sx, -r * 0.95 * k), o + Vector2(sx + r * 0.75 * k, -r * 0.95 * k),
		o + Vector2(sx + r * 0.75 * k, r * 0.3 * k), o + Vector2(sx + r * 0.38 * k, r * 1.05 * k), o + Vector2(sx, r * 0.3 * k)])
	ci.draw_colored_polygon(shield, _c(Palette.CRIMSON, flash))
	shield.append(shield[0])
	ci.draw_polyline(shield, _c(Palette.GOLD if pose == 2 else Palette.SILVER, flash), 2.0 if pose == 2 else 1.5)
	var cx := sx + r * 0.375 * k
	ci.draw_line(o + Vector2(cx, -r * 0.75 * k), o + Vector2(cx, r * 0.7 * k), _c(Palette.GOLD, flash), 2.0)
	ci.draw_line(o + Vector2(sx + r * 0.1 * k, -r * 0.3 * k), o + Vector2(sx + r * 0.65 * k, -r * 0.3 * k), _c(Palette.GOLD, flash), 2.0)
	if pose == 2:
		ci.draw_arc(o, r * 1.55, -0.9, 0.9, 16, Color(Palette.GOLD, 0.8), 3.0)  # Shieldwall: the guarded front.


# --- Stage obstacles and the battlefield dead -------------------------------------

## Draws Crimson March obstacle `o` (an Arena.Obstacle); returns false for
## kinds it does not know (the Graveyard's). The solid outline matches the
## collision shape.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	var dark := Color(0.06, 0.05, 0.05)
	match o.kind:
		"burned_house", "cart_wreck", "barricade", "crates", "siege_engine", "fort_wall":
			_draw_rect_obstacle(ci, o, dark)
		"charred_tree":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r * 1.1, Color(0, 0, 0, 0.35))
			for i in 4:
				var a := float(o.variant % 628) * 0.01 + TAU * float(i) / 4.0
				ci.draw_line(c, c + Vector2.from_angle(a) * r * 2.0, Color(0.1, 0.08, 0.07), 3.0)
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 2.0, Color(0.13, 0.1, 0.08))
			ci.draw_circle(c + Vector2(r * 0.2, -r * 0.2), r * 0.3, Color(Palette.FLAME, 0.25))
		"pine":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r * 1.4, Color(0, 0, 0, 0.35))
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, r * 1.5, 7, float(o.variant % 100) * 0.01), Color(0.07, 0.16, 0.1))
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, r * 1.05, 7, 0.4), Color(0.1, 0.22, 0.13))
			ci.draw_circle(c, r * 0.45, Color(0.13, 0.28, 0.16))
			ci.draw_circle(c, r * 0.2, WOOD_DARK)
		"stakes":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.3))
			ci.draw_circle(c, r, Color(0.12, 0.09, 0.06))
			for i in 6:
				var a := TAU * float(i) / 6.0 + float(o.variant % 50) * 0.02
				var base := c + Vector2.from_angle(a) * r * 0.45
				ci.draw_line(base, base + Vector2.from_angle(a) * r * 0.75, WOOD, 3.0)
				ci.draw_circle(base + Vector2.from_angle(a) * r * 0.75, 1.5, Palette.BONE)
		"tent":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 6), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, Palette.IVORY.darkened(0.15))
			for i in 8:
				var a := TAU * float(i) / 8.0
				ci.draw_line(c, c + Vector2.from_angle(a) * (r - 1.5), Palette.CRIMSON.darkened(0.1) if i % 2 == 0 else Palette.IVORY.darkened(0.3), 4.0)
			ci.draw_circle(c, r * 0.18, Palette.GOLD.darkened(0.2))
		"tower_base":
			var r := o.radius
			ci.draw_circle(c + Vector2(6, 8), r * 1.05, Color(0, 0, 0, 0.4))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 2.0, Color(0.27, 0.27, 0.3))
			for i in 10:
				var a := TAU * float(i) / 10.0
				ci.draw_rect(Rect2(c + Vector2.from_angle(a) * (r - 6.0) - Vector2(3, 3), Vector2(6, 6)), Color(0.2, 0.2, 0.23))
			ci.draw_circle(c, r * 0.45, Color(0.16, 0.16, 0.18))
			ci.draw_rect(Rect2(c + Vector2(-2, -r * 0.45), Vector2(4, r * 0.3)), Palette.CRIMSON)
		"rubble":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.3))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, Palette.STONE)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.2), r * 0.4, Palette.STONE.lightened(0.15))
			ci.draw_circle(c + Vector2(r * 0.35, r * 0.25), r * 0.3, Palette.STONE.darkened(0.2))
		_:
			return SanctumTerrainGlyphs.draw_obstacle(ci, o)  # Sanctum obstacles.
	return true


## Rectangular march obstacles: charred houses, cart wrecks, barricades,
## crate stacks, siege engines and fortress walls.
static func _draw_rect_obstacle(ci: CanvasItem, o: Arena.Obstacle, dark: Color) -> void:
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	var horizontal := o.half.x > o.half.y
	ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(rect, dark)
	var inner := rect.grow(-1.5)
	match o.kind:
		"burned_house":
			ci.draw_rect(inner, Color(0.12, 0.1, 0.09))
			ci.draw_rect(inner.grow(-5.0), Color(0.07, 0.06, 0.06))
			ci.draw_line(inner.position, inner.end, WOOD_DARK, 3.0)
			ci.draw_line(Vector2(inner.position.x, inner.end.y), Vector2(inner.end.x, inner.position.y), WOOD_DARK, 3.0)
			ci.draw_circle(inner.get_center(), 3.0, Color(Palette.FLAME, 0.4))
		"cart_wreck":
			ci.draw_rect(inner, WOOD_DARK)
			ci.draw_rect(inner.grow(-3.0), WOOD.darkened(0.2))
			ci.draw_circle(inner.position + Vector2(4, 4), 5.0, WOOD_DARK)
		"barricade":
			ci.draw_rect(inner, WOOD)
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 8.0
			while k < long_len - 4.0:
				var p := (Vector2(rect.position.x + k, rect.get_center().y) if horizontal else Vector2(rect.get_center().x, rect.position.y + k))
				var tip := p + (Vector2(0, -o.half.y - 7.0) if horizontal else Vector2(-o.half.x - 7.0, 0))
				ci.draw_line(p, tip, WOOD_DARK, 2.5)
				ci.draw_circle(tip, 1.2, Palette.BONE)
				k += 12.0
		"crates":
			ci.draw_rect(inner, Color(0.42, 0.3, 0.17))
			ci.draw_line(inner.position, inner.end, WOOD_DARK, 1.5)
			ci.draw_line(Vector2(inner.get_center().x, inner.position.y), Vector2(inner.get_center().x, inner.end.y), WOOD_DARK, 1.5)
			ci.draw_rect(Rect2(inner.position + Vector2(2, 2), Vector2(8, 6)), Palette.CRIMSON.darkened(0.2))
		"siege_engine":
			ci.draw_rect(inner, WOOD_DARK)
			ci.draw_rect(inner.grow(-4.0), WOOD)
			ci.draw_line(inner.get_center() - (Vector2(o.half.x, 0) if horizontal else Vector2(0, o.half.y)) * 0.8,
				inner.get_center() + (Vector2(o.half.x, 0) if horizontal else Vector2(0, o.half.y)) * 0.8, WOOD_DARK, 4.0)
			ci.draw_circle(inner.get_center(), 5.0, Palette.SILVER.darkened(0.3))
		_:
			# Fortress wall: pale stone blocks, crenellations, a crimson banner.
			ci.draw_rect(inner, Color(0.3, 0.3, 0.33))
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 10.0
			while k < long_len - 4.0:
				if horizontal:
					ci.draw_rect(Rect2(rect.position.x + k - 4.0, rect.position.y + 2.0, 8.0, 5.0), Color(0.4, 0.4, 0.44))
				else:
					ci.draw_rect(Rect2(rect.position.x + 2.0, rect.position.y + k - 4.0, 5.0, 8.0), Color(0.4, 0.4, 0.44))
				k += 16.0
			ci.draw_rect(Rect2(inner.get_center() - Vector2(4, 4), Vector2(8, 10)), Palette.CRIMSON)


## The battlefield dead (the Crimson March's empowered grave): a heap of
## fallen soldiers' shields and bones stirring with necrotic light.
static func draw_corpse_pile(ci: CanvasItem, p: Vector2, fade: float, pulse: float) -> void:
	ci.draw_circle(p, 13.0, Color(0.05, 0.08, 0.06, 0.8 * fade))
	ci.draw_rect(Rect2(p + Vector2(-11, -2), Vector2(9, 7)), Color(Palette.CRIMSON.darkened(0.4), fade))  # Fallen shield.
	ci.draw_circle(p + Vector2(5, -1), 4.0, Color(Palette.BONE, fade))  # Skull.
	ci.draw_line(p + Vector2(-6, 6), p + Vector2(9, 3), Color(Palette.BONE, 0.8 * fade), 2.0)
	ci.draw_line(p + Vector2(-2, -8), p + Vector2(8, 7), Color(Palette.SILVER.darkened(0.3), fade), 1.5)  # Broken spear.
	ci.draw_line(p + Vector2(0, -4), p + Vector2(0, -20 - 6.0 * pulse), Color(Palette.NECRO_GREEN, 0.6 * fade), 3.0)
