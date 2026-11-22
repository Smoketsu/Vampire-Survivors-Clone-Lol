## MaelstromGround — the floor of THE MAELSTROM (Act X, the Black Tide's finale;
## GDD §15.0 "The Maelstrom (Act X phase 2)"): the whirlpool's sea and the
## Hollow Queen's rotting deck, drawn with _draw() like Ground (it extends
## CorsairGround, the act's placeholder, and so Ground's redraw-on-cell-change
## logic: nothing here is redrawn every frame). The art pass's tiles
## (docs/tide/ART_MANIFEST.md, tools/corsair_tiles.py):
##   tiles/corsair_water      the navy sea with foam dashes, repeating under
##                            everything, multiplied by the zone's "sea_tint"
##                            (MaelstromStage.ZONES "ground": the fog's pale
##                            grey, the gyre's ghost green, the eye's moonlit
##                            calm, the helm's deep green);
##   tiles/corsair_maelstrom  the rotting grey-green boards, on the deck's own
##                            outline (Game.deck, DeckBounds: the one deck
##                            shape), one textured polygon.
## The hull band and the rail stay code-drawn (CorsairGround's, no rail art was
## made). Without a tile PNG the placeholder look (CorsairGround) is drawn.
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides (DeckBounds does).
class_name MaelstromGround
extends CorsairGround

## Sprite key of the sea tile.
const SEA_TILE: String = "tiles/corsair_water"
## Sprite key of the Hollow Queen's deck tile.
const DECK_TILE: String = "tiles/corsair_maelstrom"
## Colour of the rail drawn round the deck (the Hollow Queen's weathered oak).
const RAIL_COLOR := Palette.CORSAIR_OAK_LIGHT

## The current zone's look (a MaelstromStage.ZONES "ground" dictionary).
var _zone: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = MaelstromStage.ZONES
	_zone = zones[0]["ground"]


## Switches to zone look `zone` and redraws at once (MarchDirector).
func set_zone(zone: Dictionary) -> void:
	_zone = zone
	queue_redraw()


func _draw() -> void:
	var sea := EnvironmentArt.texture(SEA_TILE, true)
	var planks := EnvironmentArt.texture(DECK_TILE, true)
	var deck: DeckBounds = game.deck if game != null else null
	if sea == null or planks == null or deck == null:
		super._draw()  # No tile art (or no deck): the act's placeholder look.
		return
	SpriteBank.apply_sharp(self)
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var tint: Color = _zone.get("sea_tint", Color.WHITE)
	var ts := Vector2(float(sea.get_width()), float(sea.get_height()))  # Sea tile size (1 art px = 1 layout px).
	var c0 := Vector2(floorf(rect.position.x / ts.x), floorf(rect.position.y / ts.y)) * ts  # On the tile grid.
	var c1 := Vector2(ceilf(rect.end.x / ts.x), ceilf(rect.end.y / ts.y)) * ts
	draw_texture_rect(sea, Rect2(c0, c1 - c0), true, tint)
	var hull := PackedVector2Array()  # The hull band: the outline pushed out.
	for i in deck.outline.size():
		hull.append(deck.outline[i] + (deck.outline[i] - deck.center).normalized() * HULL_W)
	draw_colored_polygon(hull, Palette.CORSAIR_INK)
	var ps := Vector2(float(planks.get_width()), float(planks.get_height()))  # Deck tile size.
	var uvs := PackedVector2Array()  # World px / tile size: the tile repeats on the world grid.
	for p in deck.outline:
		uvs.append(Vector2(p.x / ps.x, p.y / ps.y))
	draw_colored_polygon(deck.outline, Color.WHITE, uvs, planks)
	var outline := deck.outline.duplicate()
	outline.append(deck.outline[0])
	draw_polyline(outline, RAIL_COLOR, RAIL_W)
