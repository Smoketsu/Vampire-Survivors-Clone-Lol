## FortKesslerGround — the floor of Fort Kessler (Act VIII, Stage 23; GDD §15.0
## "Fort Kessler (Act VIII phase 2)"): CityGround (the streets, alleys,
## sidewalks and open lots drawn from the run's CityBlocks) with each zone's
## LOOK on top (FortKesslerStage.ZONES "ground"; MarchDirector calls set_zone()
## at each zone change):
##   * checkpoints — at every street segment a CHECKPOINT: a striped barrier
##     boom half across the roadway and a sandbag nest on the kerb;
##   * minefield   — the open lots are MINEFIELDS ("field": churned earth inside
##     a hazard-taped fence with warning signs; the mines themselves are
##     Minefields', drawn over this) and warning signs along the streets;
##   * airfield    — the open lots are APRONS ("apron": concrete slabs, a
##     hazard taxi line and a helipad ring) and the streets carry hazard
##     chevrons;
##   * bunker      — sandbag walls along the streets and blast doors' hazard
##     paint (the roofs are the `bunker` style: the zone's "blocks").
## The sandbags are decals/fk_sandbags when the PNG exists, else code discs.
## Drawn only when the camera crosses a redraw cell or the zone changes
## (Ground's rule): textures and rects, nothing redrawn every frame. Purely
## cosmetic: nothing here collides.
class_name FortKesslerGround
extends CityGround

## Sprite key of a sandbag decal (assets/sprites/decals/fk_sandbags.png).
const SANDBAG_DECAL: String = "decals/fk_sandbags"
## Width (px) of a code sandbag (the fallback).
const BAG_W: float = 12.0
## Height (px) of a code sandbag (the fallback).
const BAG_H: float = 7.0
## Sandbag fill colour (the fallback).
const BAG_COL := Color(0.55, 0.50, 0.36)


## Switches to zone look `p_look` (a FortKesslerStage.ZONES "ground") and
## forces a redraw.
func set_zone(p_look: Dictionary) -> void:
	look = p_look
	_center_cell = Vector2i(1 << 30, 1 << 30)  # Redraw on the next frame.
	queue_redraw()


## An open lot's look: Fort Kessler's minefields and aprons, else CityGround's.
func _open_lot(b: Rect2, style: String, h: int) -> void:
	match style:
		"field":
			draw_rect(b, Color(0.20, 0.18, 0.13))  # Churned earth.
			for k in 7:
				var hk := absi(hash(Vector2i(h, k)))
				var p := b.position + Vector2(20.0 + float(hk % maxi(1, int(b.size.x - 40.0))), 20.0 + float((hk >> 9) % maxi(1, int(b.size.y - 40.0))))
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(10, 6), Vector2(20, 12)), false, Color(0.13, 0.12, 0.09, 0.8))  # A crater.
			_tape(b.grow(-6.0))
			_sign(b.position + Vector2(18.0, 18.0))
			_sign(Vector2(b.end.x - 18.0, b.end.y - 18.0))
		"apron":
			draw_rect(b, Palette.CITY_CONCRETE)
			var x := b.position.x + 64.0
			while x < b.end.x:
				draw_rect(Rect2(Vector2(x, b.position.y), Vector2(1.0, b.size.y)), Palette.CITY_CONCRETE_LIGHT)  # Slab joints.
				x += 64.0
			draw_rect(Rect2(Vector2(b.position.x, b.get_center().y - 2.0), Vector2(b.size.x, 4.0)), Color(Palette.CITY_HAZARD, 0.8))  # The taxi line.
			draw_texture_rect(CityGlyphs.ring_texture(), Rect2(b.get_center() - Vector2(44, 44), Vector2(88, 88)), false, Color(Palette.CITY_HAZARD, 0.7))  # A helipad.
		_:
			super._open_lot(b, style, h)


## A zone accent near street point `p` (the middle of a horizontal street
## segment; street indices `i`, `k`).
func _accent(p: Vector2, i: int, k: int) -> void:
	var h := absi(hash(Vector3i(i, k, 2323)))
	match String(look.get("style", "checkpoints")):
		"checkpoints":
			if h % 2 == 0:
				_boom(p + Vector2(0.0, -72.0), 64.0)
				_sandbags(p + Vector2(-36.0, -84.0), 4)
		"minefield":
			_sign(p + Vector2(float(h % 80) - 40.0, -84.0))
		"airfield":
			for c in 3:
				draw_rect(Rect2(p + Vector2(-60.0 + 40.0 * float(c), 50.0), Vector2(24.0, 6.0)), Color(Palette.CITY_HAZARD, 0.55))  # Chevrons.
		"bunker":
			_sandbags(p + Vector2(-48.0, -84.0), 8)
			if h % 3 == 0:
				_sandbags(p + Vector2(-24.0, 78.0), 4)


## A striped barrier boom from `at` across `length` px of the roadway (down).
func _boom(at: Vector2, length: float) -> void:
	draw_rect(Rect2(at - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Palette.CITY_CONCRETE_LIGHT)  # The post.
	var y := at.y
	var n := 0
	while y < at.y + length:
		draw_rect(Rect2(Vector2(at.x - 2.0, y), Vector2(4.0, 8.0)), Palette.CITY_SIREN_RED if n % 2 == 0 else Color(0.92, 0.92, 0.88))
		y += 8.0
		n += 1


## A row of `n` sandbags from `at` (the decal when present, else code discs).
func _sandbags(at: Vector2, n: int) -> void:
	if SpriteBank.has(SANDBAG_DECAL):
		for k in maxi(1, n / 4):
			SpriteBank.draw(self, SANDBAG_DECAL, at + Vector2(24.0 + 48.0 * float(k), 0.0), false)
		return
	for k in n:
		var c := at + Vector2(float(k) * (BAG_W - 1.0), 0.0)
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(BAG_W, BAG_H) * 0.5, Vector2(BAG_W, BAG_H)), false, BAG_COL.darkened(0.3))
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(BAG_W, BAG_H) * 0.5 + Vector2(0.0, -2.0), Vector2(BAG_W, BAG_H - 1.0)), false, BAG_COL)


## A hazard-taped fence round `r` (yellow and black dashes).
func _tape(r: Rect2) -> void:
	var x := r.position.x
	var n := 0
	while x < r.end.x:
		var col := Palette.CITY_HAZARD if n % 2 == 0 else Palette.CITY_INK
		draw_rect(Rect2(Vector2(x, r.position.y), Vector2(10.0, 2.0)), col)
		draw_rect(Rect2(Vector2(x, r.end.y - 2.0), Vector2(10.0, 2.0)), col)
		x += 10.0
		n += 1
	var y := r.position.y
	n = 0
	while y < r.end.y:
		var col := Palette.CITY_HAZARD if n % 2 == 0 else Palette.CITY_INK
		draw_rect(Rect2(Vector2(r.position.x, y), Vector2(2.0, 10.0)), col)
		draw_rect(Rect2(Vector2(r.end.x - 2.0, y), Vector2(2.0, 10.0)), col)
		y += 10.0
		n += 1


## A small warning sign at `at` (a red plate on a post; no letters).
func _sign(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-1.0, 0.0), Vector2(2.0, 8.0)), Palette.CITY_INK)
	draw_rect(Rect2(at + Vector2(-6.0, -8.0), Vector2(12.0, 9.0)), Palette.CITY_INK)
	draw_rect(Rect2(at + Vector2(-5.0, -7.0), Vector2(10.0, 7.0)), Palette.CITY_SIREN_RED)
