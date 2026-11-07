## CityGround — the PLACEHOLDER floor of the Act VIII stubs (the Last Line; GDD
## §15.0 "Act VIII foundation (phase 1)" and "City blocks"), drawn with _draw()
## like Ground (it extends it and reuses its redraw-on-cell-change logic) from
## the SAME geometry as the buildings (the run's CityBlocks, Game.arena
## .city_blocks), so a street is drawn exactly where the bodies can walk:
##   * the alleys (tiles/city_alley, 64 x 80, along x; turned for the other
##     axis), the streets' asphalt with its dashed centre line
##     (tiles/city_street, 64 x 192), the crossings (plain asphalt) and their
##     crosswalks (tiles/city_crosswalk, 64 x 192, on each approach);
##   * the sidewalks on a building's street sides (tiles/city_sidewalk, 64 x
##     32, its curb on the street edge);
##   * the open lots: plazas (tiles/city_plaza), parking lots (painted bays)
##     and parks (grass and trees), by CityBlocks.open_style();
##   * the stage's style accents (STAGE "floor" style docks / base / downtown:
##     manholes and oil stains, painted hazard bays, neon spill).
## Each piece is the art pass's PNG when present (EnvironmentArt, tiled), else
## the code colours of `look`. Buildings and wrecks are Arena's
## (CityGlyphs.draw_building()). Phase 2 replaces the stub look with each
## stage's own zone floors. Purely cosmetic: nothing here collides.
class_name CityGround
extends Ground

## The stage's floor look (StageRegistry "floor": style, asphalt, sidewalk,
## lane, accent; {} = docks defaults).
var look: Dictionary = {}
## The run (Game sets it before this enters the tree): its arena's CityBlocks
## is the geometry drawn.
var game: Game = null


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var asphalt: Color = look.get("asphalt", Palette.CITY_ASPHALT_DARK)  # Roadway colour (code floor).
	draw_rect(rect, asphalt.darkened(0.25))  # The alleys' darker asphalt under everything.
	var cb := game.arena.city_blocks if game != null and game.arena != null else null  # The geometry.
	if cb == null:
		return
	_draw_alleys(cb, rect, asphalt)
	_draw_streets(cb, rect, asphalt)
	_draw_lots(cb, rect)


## The alley strips (between the buildings of one block), both axes.
func _draw_alleys(cb: CityBlocks, rect: Rect2, asphalt: Color) -> void:
	var tex := EnvironmentArt.texture("tiles/city_alley", true)  # 64 x 80, along x.
	var a := cb.alley
	# Horizontal alleys: centre lines at odd multiples of pitch.y.
	var k0 := floori(rect.position.y / cb.pitch.y)
	var k1 := ceili(rect.end.y / cb.pitch.y)
	for k in range(k0, k1 + 1):
		if (k & 1) == 0:
			continue
		var y := float(k) * cb.pitch.y
		var r := Rect2(Vector2(_snap(rect.position.x), y - a * 0.5), Vector2(rect.size.x + 128.0, a))
		if tex != null:
			draw_texture_rect(tex, r, true)
		else:
			draw_rect(r, asphalt.darkened(0.35))
	# Vertical alleys: centre lines at odd multiples of pitch.x (the tile turned).
	k0 = floori(rect.position.x / cb.pitch.x)
	k1 = ceili(rect.end.x / cb.pitch.x)
	for k in range(k0, k1 + 1):
		if (k & 1) == 0:
			continue
		var x := float(k) * cb.pitch.x
		if tex != null:
			draw_set_transform(Vector2(x + a * 0.5, _snap(rect.position.y)), PI * 0.5, Vector2.ONE)
			draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(rect.size.y + 128.0, a)), true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_rect(Rect2(Vector2(x - a * 0.5, rect.position.y), Vector2(a, rect.size.y)), asphalt.darkened(0.35))


## The streets of both axes, their crossings and crosswalks, the lane lines.
func _draw_streets(cb: CityBlocks, rect: Rect2, asphalt: Color) -> void:
	var tex := EnvironmentArt.texture("tiles/city_street", true)  # 64 x 192, the lane along x.
	var walk := EnvironmentArt.texture("tiles/city_crosswalk", true)  # 64 x 192.
	var hs := cb.street * 0.5
	var hk0 := floori(rect.position.y / (2.0 * cb.pitch.y)) - 1
	var hk1 := ceili(rect.end.y / (2.0 * cb.pitch.y)) + 1
	var vk0 := floori(rect.position.x / (2.0 * cb.pitch.x)) - 1
	var vk1 := ceili(rect.end.x / (2.0 * cb.pitch.x)) + 1
	var x0 := _snap(rect.position.x)
	var y0 := _snap(rect.position.y)
	for k in range(hk0, hk1 + 1):
		var y := cb.h_street_y(k)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(x0, y - hs), Vector2(rect.size.x + 128.0, cb.street)), true)
		else:
			draw_rect(Rect2(Vector2(x0, y - hs), Vector2(rect.size.x + 128.0, cb.street)), asphalt)
			_lane_dashes(Vector2(x0, y), Vector2.RIGHT, rect.size.x + 128.0)
	for k in range(vk0, vk1 + 1):
		var x := cb.v_street_x(k)
		if tex != null:
			draw_set_transform(Vector2(x + hs, y0), PI * 0.5, Vector2.ONE)
			draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(rect.size.y + 128.0, cb.street)), true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_rect(Rect2(Vector2(x - hs, y0), Vector2(cb.street, rect.size.y + 128.0)), asphalt)
			_lane_dashes(Vector2(x, y0), Vector2.DOWN, rect.size.y + 128.0)
	# The crossings: plain asphalt (no lane line), then a crosswalk on each approach.
	for j in range(hk0, hk1 + 1):
		for i in range(vk0, vk1 + 1):
			var c := Vector2(cb.v_street_x(i), cb.h_street_y(j))  # Crossing centre.
			var sq := Rect2(c - Vector2(hs, hs), Vector2(cb.street, cb.street))
			if tex != null:
				# The street tile's plain top band (above its lane line), tiled over the square.
				var band := Rect2(Vector2.ZERO, Vector2(64.0, 48.0))
				var yy := sq.position.y
				while yy < sq.end.y:
					var xx := sq.position.x
					while xx < sq.end.x:
						var sz := Vector2(minf(64.0, sq.end.x - xx), minf(48.0, sq.end.y - yy))
						draw_texture_rect_region(tex, Rect2(Vector2(xx, yy), sz), Rect2(band.position, sz))
						xx += 64.0
					yy += 48.0
			else:
				draw_rect(sq, asphalt)
			_crosswalks(c, hs, walk)
	# Style accents: manholes / stains (docks), painted hazard bays (base), neon spill (downtown).
	for k in range(hk0, hk1 + 1):
		for i in range(vk0, vk1 + 1):
			_accent(Vector2(cb.v_street_x(i) + cb.pitch.x, cb.h_street_y(k)), i, k)


## The four crosswalks round the crossing at `c` (half street `hs` px): the
## tile on each approach (turned for the vertical street), else code stripes.
func _crosswalks(c: Vector2, hs: float, walk: Texture2D) -> void:
	var d := CityBlockData.CROSSWALK_DEPTH
	if walk != null:
		var w := 64.0  # The tile's depth along the street (px).
		draw_texture_rect(walk, Rect2(Vector2(c.x + hs, c.y - hs), Vector2(w, hs * 2.0)), false)  # East approach.
		draw_texture_rect(walk, Rect2(Vector2(c.x - hs - w, c.y - hs), Vector2(w, hs * 2.0)), false)  # West approach.
		draw_set_transform(Vector2(c.x + hs, c.y + hs), PI * 0.5, Vector2.ONE)
		draw_texture_rect(walk, Rect2(Vector2.ZERO, Vector2(w, hs * 2.0)), false)  # South approach.
		draw_set_transform(Vector2(c.x + hs, c.y - hs - w), PI * 0.5, Vector2.ONE)
		draw_texture_rect(walk, Rect2(Vector2.ZERO, Vector2(w, hs * 2.0)), false)  # North approach.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var col := Color(0.86, 0.86, 0.84, 0.75)  # Crosswalk paint.
	var lw := CityBlockData.LANE_LINE_W * 2.0
	var y := c.y - hs + 8.0
	while y < c.y + hs - 8.0:
		draw_rect(Rect2(Vector2(c.x + hs + 4.0, y), Vector2(d, lw)), col)
		draw_rect(Rect2(Vector2(c.x - hs - 4.0 - d, y), Vector2(d, lw)), col)
		y += CityBlockData.CROSSWALK_STEP
	var x := c.x - hs + 8.0
	while x < c.x + hs - 8.0:
		draw_rect(Rect2(Vector2(x, c.y + hs + 4.0), Vector2(lw, d)), col)
		draw_rect(Rect2(Vector2(x, c.y - hs - 4.0 - d), Vector2(lw, d)), col)
		x += CityBlockData.CROSSWALK_STEP


## The code lane line: dashes from `from` along unit `dir` for `length` px.
func _lane_dashes(from: Vector2, dir: Vector2, length: float) -> void:
	var col: Color = look.get("lane", Palette.CITY_SODIUM)
	var t := 0.0
	var lw := CityBlockData.LANE_LINE_W
	while t < length:
		var p := from + dir * t
		var r := Rect2(p - Vector2(0.0, lw * 0.5), Vector2(CityBlockData.LANE_DASH, lw)) if dir.x != 0.0 \
				else Rect2(p - Vector2(lw * 0.5, 0.0), Vector2(lw, CityBlockData.LANE_DASH))
		draw_rect(r, Color(col, 0.7))
		t += CityBlockData.LANE_DASH + CityBlockData.LANE_GAP


## The sidewalks of every lot in view (on its street sides) and the open lots'
## plazas, parking lots and parks.
func _draw_lots(cb: CityBlocks, rect: Rect2) -> void:
	var walk := EnvironmentArt.texture("tiles/city_sidewalk", true)  # 64 x 32, the curb on its bottom edge.
	var r := cb.lot_range(rect)
	var coop := game.coop != null
	for iy in range(r[0].y - 1, r[1].y + 2):
		for ix in range(r[0].x - 1, r[1].x + 2):
			var lot := Vector2i(ix, iy)
			var b := cb.building_rect(lot)
			var open := cb.building_of(lot, not coop) == null  # Co-op: never fills the cache from a draw.
			_sidewalks(cb, b, lot, walk)
			if open:
				_open_lot(b, cb.open_style(lot), absi(hash(lot)))


## The sidewalk bands of building rect `b` (lot `lot`) on its street sides:
## the low side of an even lot, the high side of an odd one, per axis.
func _sidewalks(cb: CityBlocks, b: Rect2, lot: Vector2i, tex: Texture2D) -> void:
	var sw := cb.sidewalk
	var left := (lot.x & 1) == 0  # The street is on its low-x side.
	var top := (lot.y & 1) == 0  # The street is on its low-y side.
	var ext_top := sw if top else 0.0
	var ext_bot := 0.0 if top else sw
	var span_y := b.size.y + ext_top + ext_bot  # The x band's length, round the corner.
	var under := 8.0  # px a tile reaches under the roof (its curb ends on the street edge).
	if tex == null:
		var col: Color = look.get("sidewalk", Palette.CITY_CONCRETE)
		var xs := b.position.x - sw if left else b.end.x
		draw_rect(Rect2(Vector2(xs, b.position.y - ext_top), Vector2(sw, span_y)), col)
		var ys := b.position.y - sw if top else b.end.y
		draw_rect(Rect2(Vector2(b.position.x, ys), Vector2(b.size.x, sw)), col)
		var curb := Palette.CITY_CONCRETE_LIGHT
		var cw := CityBlockData.CURB_W
		draw_rect(Rect2(Vector2(xs if left else xs + sw - cw, b.position.y - ext_top), Vector2(cw, span_y)), curb)
		draw_rect(Rect2(Vector2(b.position.x, ys if top else ys + sw - cw), Vector2(b.size.x, cw)), curb)
		return
	var h := sw + under  # Drawn band height (px).
	# The y band (above or below), its curb facing the street.
	if top:
		draw_set_transform(Vector2(b.end.x, b.position.y + under), PI, Vector2.ONE)
	else:
		draw_set_transform(Vector2(b.position.x, b.end.y - under), 0.0, Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(b.size.x, h)), true)
	# The x band (left or right), round the corner.
	if left:
		draw_set_transform(Vector2(b.position.x + under, b.position.y - ext_top), PI * 0.5, Vector2.ONE)
	else:
		draw_set_transform(Vector2(b.end.x - under, b.end.y + ext_bot), -PI * 0.5, Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(span_y, h)), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## An open lot's look `style` over its building rect `b` (`h` its hash).
func _open_lot(b: Rect2, style: String, h: int) -> void:
	match style:
		"parking":
			draw_rect(b, Palette.CITY_ASPHALT)
			var x := b.position.x + 16.0
			while x < b.end.x - 16.0:
				draw_rect(Rect2(Vector2(x, b.position.y + 8.0), Vector2(2.0, 44.0)), Color(0.85, 0.85, 0.82, 0.6))  # Bays along the top.
				draw_rect(Rect2(Vector2(x, b.end.y - 52.0), Vector2(2.0, 44.0)), Color(0.85, 0.85, 0.82, 0.6))  # Bays along the bottom.
				x += 32.0
		"park":
			draw_rect(b, Color(0.16, 0.22, 0.14))
			for k in 5:
				var hk := absi(hash(Vector2i(h, k)))
				var p := b.position + Vector2(24.0 + float(hk % maxi(1, int(b.size.x - 48.0))), 24.0 + float((hk >> 9) % maxi(1, int(b.size.y - 48.0))))
				draw_texture_rect(SpriteBank.disc(), Rect2(p - Vector2(14, 14), Vector2(28, 28)), false, Color(0.1, 0.16, 0.09))  # A tree's crown.
		_:
			var tex := EnvironmentArt.texture("tiles/city_plaza", true)
			if tex != null:
				draw_texture_rect(tex, b, true)
			else:
				draw_rect(b, look.get("sidewalk", Palette.CITY_CONCRETE))
				var y := b.position.y + 32.0
				while y < b.end.y:
					draw_rect(Rect2(Vector2(b.position.x, y), Vector2(b.size.x, 1.0)), Palette.CITY_CONCRETE_LIGHT)
					y += 32.0


## A stage-style accent near street point `p` (street indices `i`, `k`).
func _accent(p: Vector2, i: int, k: int) -> void:
	var h := absi(hash(Vector3i(i, k, 8081)))
	var accent: Color = look.get("accent", Palette.CITY_NEON_PINK)
	match String(look.get("style", "docks")):
		"base":
			draw_rect(Rect2(p + Vector2(-30.0, -60.0), Vector2(60.0, 4.0)), Color(Palette.CITY_HAZARD, 0.55))  # A painted stop bar.
		"downtown":
			draw_texture_rect(SpriteBank.disc(), Rect2(p + Vector2(-40.0, 40.0), Vector2(80.0, 24.0)), false, Color(accent, 0.12))  # Neon spill.
		_:
			if h % 3 == 0:
				draw_texture_rect(SpriteBank.disc(), Rect2(p + Vector2(float(h % 60) - 30.0, 30.0), Vector2(22.0, 22.0)), false, Color(0.12, 0.12, 0.13))  # A manhole.
			if h % 4 == 1:
				draw_texture_rect(SpriteBank.disc(), Rect2(p + Vector2(-70.0, -40.0), Vector2(40.0, 18.0)), false, Color(0.05, 0.05, 0.06, 0.5))  # An oil stain.


## `v` snapped down to a whole 64 px tile, so tiles line up between redraws.
static func _snap(v: float) -> float:
	return floorf(v / 64.0) * 64.0 - 64.0
