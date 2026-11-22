## FaeCourtGround — the floor of THE FAE COURT (temporary Act XV, the Turning
## Year; GDD §15.0 "The Fae Court (Act XV phase 2)": "a court of endless summer
## under a sky that never sets"). It extends WildGround (the act's petal and
## mushroom decorations, the season tint through modulate) and adds the four
## zone looks (FaeCourtStage.ZONES "ground": base, line, accent, trim;
## MarchDirector calls set_zone() at each zone change). Art pass: the zone's
## floor tile (tiles/fae_court_<style>.png, docs/year/ART_MANIFEST.md) replaces
## the base colour when its PNG exists, else the act's own tiles/wild_fae; the
## decorations stay code-drawn and sparse (disc textures and rects: the layer
## redraws only on a cell change). Purely cosmetic: nothing here collides.
class_name FaeCourtGround
extends WildGround

## The act's Fae Court tile, used while a zone has no tile of its own.
const FALLBACK_TILE: String = "tiles/wild_fae"


func _ready() -> void:
	super._ready()
	look = FaeCourtStage.ZONES[0]["ground"]


## Switches to zone look `p_look` and redraws at once.
func set_zone(p_look: Dictionary) -> void:
	look = p_look
	queue_redraw()


## Floor tile key of the current zone: tiles/fae_court_<style>, else the act's tile.
func _tile_key() -> String:
	var key := EnvironmentArtData.TILE_PREFIX + "fae_court_" + String(look.get("style", "rose_maze"))
	return key if SpriteBank.has(key) else FALLBACK_TILE


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, look.get("base", Color(0.14, 0.17, 0.12)))
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_wild_cell(cx, cy, "fae")
