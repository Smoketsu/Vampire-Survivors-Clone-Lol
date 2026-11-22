## CutterGround — the floor of the Smuggler's Cutter (Act X, the Black Tide;
## GDD §15.0 "The Smuggler's Cutter (Act X phase 2)": "a small night-time sloop
## slips out of a ruined harbour, the Covenant's coast burning behind it"):
## the sea and the sloop's deck in the art pass's tiles, drawn with _draw()
## like Ground (it extends CorsairGround, so the redraw happens only when the
## camera crosses a redraw cell: the cutter's camera sits still, so it is drawn
## once per zone). Layers:
##   * the SEA: the navy water tile (tiles/corsair_water) over the drawn area,
##     tinted by the zone (CutterStage.ZONES "ground" sea_tint as a flat rect
##     with alpha); CorsairGround's hashed foam lines on top;
##   * the zone's LIGHT on the water: the Harbour Mouth's burning coast (an
##     amber glow in bands toward the top of the view), none on Open Water and
##     in the Fog Bank (the fog itself is CutterDirector's), the Cove's dark
##     cliffs (dark bands at the view's edges);
##   * the HULL band (the deck outline pushed out, ink) and the DECK: one
##     polygon (Game.deck's outline, the one deck shape) filled with the
##     night-deck plank tile (tiles/corsair_cutter, repeating, uv = world px /
##     tile size, modulated by the zone's deck_tint) and the rail round it.
## Without the tiles' PNGs it falls back to CorsairGround's code look.
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides (DeckBounds does).
class_name CutterGround
extends CorsairGround

## Floor tile key of the deck's planks.
const DECK_TILE: String = "tiles/corsair_cutter"
## Floor tile key of the sea.
const SEA_TILE: String = "tiles/corsair_water"

## Current zone look (a CutterStage.ZONES "ground" dictionary).
var _zone_look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zs: Array = CutterStage.ZONES
	_zone_look = zs[0]["ground"]


## Switches to zone look `zl` and redraws at once.
func set_zone(zl: Dictionary) -> void:
	_zone_look = zl
	queue_redraw()


func _draw() -> void:
	var deck: DeckBounds = game.deck if game != null else null
	var sea_tex := EnvironmentArt.texture(SEA_TILE, true)
	var deck_tex := EnvironmentArt.texture(DECK_TILE, true)
	if deck == null or sea_tex == null or deck_tex == null:
		super._draw()  # No art (or no deck): the foundation's code look.
		return
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	SpriteBank.apply_sharp(self)
	var ts := Vector2(float(sea_tex.get_width()), float(sea_tex.get_height()))
	var c0 := (rect.position / ts).floor() * ts
	var c1 := (rect.end / ts).ceil() * ts
	draw_texture_rect(sea_tex, Rect2(c0, c1 - c0), true)
	var tint: Color = _zone_look.get("sea_tint", Color(0, 0, 0, 0))
	if tint.a > 0.0:
		draw_rect(rect, tint)
	_foam(rect, deck)
	_zone_light(deck)
	var hull := PackedVector2Array()  # The hull band: the outline pushed out.
	for i in deck.outline.size():
		hull.append(deck.outline[i] + (deck.outline[i] - deck.center).normalized() * HULL_W)
	draw_colored_polygon(hull, Palette.CORSAIR_INK)
	var dts := Vector2(float(deck_tex.get_width()), float(deck_tex.get_height()))
	var uvs := PackedVector2Array()
	for p in deck.outline:
		uvs.append(p / dts)
	draw_polygon(deck.outline, PackedColorArray([_zone_look.get("deck_tint", Color.WHITE)]), uvs, deck_tex)
	var outline := deck.outline.duplicate()
	outline.append(deck.outline[0])
	draw_polyline(outline, Palette.CORSAIR_OAK_DARK, RAIL_W + 2.0)
	draw_polyline(outline, Palette.CORSAIR_OAK_LIGHT, RAIL_W - 1.0)


## The zone's light on the water (see the header): flat bands with alpha.
func _zone_light(deck: DeckBounds) -> void:
	match String(_zone_look.get("light", "")):
		"coast_fire":
			var top := deck.center.y - deck.half_beam - 60.0
			for k in 6:
				var y := top - 60.0 * float(k + 1)
				draw_rect(Rect2(Vector2(deck.center.x - 1400.0, y), Vector2(2800.0, 60.0)), Color(Palette.CORSAIR_LANTERN_DARK, 0.05 + 0.035 * float(k)))
			for k in 9:
				var x := deck.center.x - 760.0 + 190.0 * float(k)
				draw_rect(Rect2(Vector2(x, top - 380.0 + float((k * 37) % 50)), Vector2(70.0 + float((k * 53) % 60), 6.0)), Color(Palette.CORSAIR_LANTERN, 0.35))
		"cove":
			for k in 4:
				var w := 120.0 - 25.0 * float(k)
				draw_rect(Rect2(Vector2(deck.center.x - 900.0, deck.center.y - 700.0), Vector2(w + 260.0, 1400.0)), Color(0.02, 0.05, 0.05, 0.18))
				draw_rect(Rect2(Vector2(deck.center.x + 640.0 - w, deck.center.y - 700.0), Vector2(w + 260.0, 1400.0)), Color(0.02, 0.05, 0.05, 0.18))
