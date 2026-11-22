## GalleonGround — the floor of the Treasure Galleon (Act X, the Black Tide;
## GDD §15.0 "The Treasure Galleon (Act X phase 2)"): the sea and the
## captured galleon's deck, drawn with _draw() like Ground (it extends
## CorsairGround and reuses its redraw-on-cell-change logic: nothing here is
## redrawn every frame). The art pass's tiles replace the code colours when
## their PNGs exist (EnvironmentArt.texture(), repeating):
##   * the SEA: tiles/corsair_water (the navy swell with foam dashes), as one
##     repeating rect, multiplied by the zone's "sea" tint;
##   * the DECK: one textured polygon on Game.deck's outline (the one deck
##     shape) with tiles/corsair_galleon (the scrubbed dawn oak, brass nails),
##     multiplied by the zone's "deck" tint; the QUARTERDECK (behind
##     GalleonData.QUARTERDECK_X) and the FORECASTLE (before FORECASTLE_X) a
##     shade lighter, raised decks, with their edge beams;
##   * the FLOOR DRESSING (GalleonData.DRESSING): the hatches and the lashed
##     barrels as flat sprites (no collision; a 256 px cell holds one
##     colliding obstacle, so these stay floor art);
##   * the hull band and the rail round the outline (CorsairGround's);
##   * the zone's touches: the Reef's dark rocks in the water, the Storm's
##     heavier foam (the zone's "foam" share), the Gun Deck's powder smoke.
## Without the tiles it draws CorsairGround's code deck. GalleonDirector calls
## set_zone() at each zone change. Purely cosmetic: nothing here collides
## (DeckBounds does).
class_name GalleonGround
extends CorsairGround

## The water tile's key (EnvironmentArt; the art pass, tools/corsair_tiles.py).
const WATER_TILE: String = "tiles/corsair_water"
## The galleon deck tile's key.
const DECK_TILE: String = "tiles/corsair_galleon"
## Size (px) of one tile (both tiles are 128 x 128).
const TILE: float = 128.0

## The current zone's look (a GalleonStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # The deck polygon's UVs run past 1: the tile repeats.
	var zones: Array = GalleonStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	if not look.is_empty():
		_look = look
	queue_redraw()


func _draw() -> void:
	var water := EnvironmentArt.texture(WATER_TILE, true)
	var plank := EnvironmentArt.texture(DECK_TILE, true)
	var deck: DeckBounds = game.deck if game != null else null
	if water == null or plank == null or deck == null:
		super._draw()  # The code deck (no tiles yet).
		return
	SpriteBank.apply_sharp(self)
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var c0 := Vector2(floorf(rect.position.x / TILE), floorf(rect.position.y / TILE)) * TILE
	var c1 := Vector2(ceilf(rect.end.x / TILE), ceilf(rect.end.y / TILE)) * TILE
	var sea_tint: Color = _look.get("sea", Color.WHITE)
	draw_texture_rect(water, Rect2(c0, c1 - c0), true, sea_tint)
	_sea_touches(rect, deck)
	var hull := PackedVector2Array()  # The hull band: the outline pushed out.
	for i in deck.outline.size():
		hull.append(deck.outline[i] + (deck.outline[i] - deck.center).normalized() * HULL_W)
	draw_colored_polygon(hull, Palette.CORSAIR_INK)
	var deck_tint: Color = _look.get("deck", Color.WHITE)
	var uvs := PackedVector2Array()
	for p in deck.outline:
		uvs.append(p / TILE)
	draw_polygon(deck.outline, PackedColorArray([deck_tint]), uvs, plank)
	_raised(deck, deck_tint)
	for d: Array in GalleonData.DRESSING:
		var tex := EnvironmentArt.texture(String(d[0]))
		if tex != null:
			var size := Vector2(float(tex.get_width()), float(tex.get_height()))
			var at := deck.center + (d[1] as Vector2) - size * 0.5
			draw_texture_rect(tex, Rect2(at.round(), size), false, deck_tint)
	if String(_look.get("style", "")) == "gun_deck":
		_smoke(deck)
	var outline := deck.outline.duplicate()
	outline.append(deck.outline[0])
	draw_polyline(outline, Palette.CORSAIR_OAK_DARK, RAIL_W)
	draw_polyline(outline, Color(Palette.CORSAIR_OAK_LIGHT, 0.6), 1.5)


## The quarterdeck and the forecastle: a lighter wash behind / before their
## edges, each edge a dark beam with a pale lip.
func _raised(deck: DeckBounds, tint: Color) -> void:
	var lift := Color(Palette.CORSAIR_SAIL_LIGHT, 0.10 * tint.v)
	for x_and_side: Array in [[GalleonData.QUARTERDECK_X, -1.0], [GalleonData.FORECASTLE_X, 1.0]]:
		var x := deck.center.x + float(x_and_side[0])
		var far := deck.center.x + deck.half_length * float(x_and_side[1])
		var lo := minf(x, far)
		var hi := maxf(x, far)
		var band := PackedVector2Array([Vector2(lo, deck.center.y - deck.half_beam - 1.0), Vector2(hi, deck.center.y - deck.half_beam - 1.0),
			Vector2(hi, deck.center.y + deck.half_beam + 1.0), Vector2(lo, deck.center.y + deck.half_beam + 1.0)])
		for poly: PackedVector2Array in Geometry2D.intersect_polygons(deck.outline, band):
			draw_colored_polygon(poly, lift)
		var y0 := deck.center.y - deck.half_beam + 4.0
		var y1 := deck.center.y + deck.half_beam - 4.0
		draw_line(Vector2(x, y0), Vector2(x, y1), Palette.CORSAIR_OAK_DARK, 4.0)
		draw_line(Vector2(x + 2.0 * float(x_and_side[1]), y0), Vector2(x + 2.0 * float(x_and_side[1]), y1), Color(Palette.CORSAIR_OAK_LIGHT, 0.7), 1.0)


## The zone's touches on the water: the Reef's rocks, the Storm's extra foam
## (hashed per cell, never over the deck).
func _sea_touches(rect: Rect2, deck: DeckBounds) -> void:
	var style := String(_look.get("style", ""))
	var foam_share := float(_look.get("foam", 0.35))
	var a := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var b := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(a.y, b.y + 1):
		for cx in range(a.x, b.x + 1):
			var h := absi(hash(Vector3i(cx, cy, 2929)))
			var p := Vector2(float(cx) * CELL + float((h >> 8) % 96) + 16.0, float(cy) * CELL + float((h >> 15) % 96) + 16.0)
			if deck.violation(p, -60.0) <= 0.0:
				continue  # Too close to the hull.
			if style == "reef" and h % 100 < 18:
				var r := 8.0 + float(h % 12)
				SpriteBank.draw_disc(self, p, r + 3.0, Color(Palette.CORSAIR_FOAM, 0.35))
				SpriteBank.draw_disc(self, p, r, Palette.CORSAIR_POWDER_DARK)
				SpriteBank.draw_disc(self, p + Vector2(-r * 0.3, -r * 0.3), r * 0.45, Palette.CORSAIR_POWDER)
			elif float(h % 100) < foam_share * 60.0:
				var w := 12.0 + float(h % 26)
				draw_line(p, p + Vector2(w, 0.0), Color(Palette.CORSAIR_FOAM, 0.45), 1.0)


## The Gun Deck's powder smoke drifting over the planks (soft discs, static).
func _smoke(deck: DeckBounds) -> void:
	for i in 14:
		var h := absi(hash(Vector2i(i, 4141)))
		var p := deck.center + Vector2((float(h % 1000) / 1000.0 - 0.5) * deck.half_length * 1.8, (float((h >> 10) % 1000) / 1000.0 - 0.5) * deck.half_beam * 1.6)
		SpriteBank.draw_disc(self, p, 30.0 + float(h % 30), Color(Palette.CORSAIR_POWDER_LIGHT, 0.08))
