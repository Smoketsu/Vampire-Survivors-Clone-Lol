## WorldTreeGround — the floor of THE WORLD-TREE (temporary Act XV, the Turning
## Year's finale; GDD §15.0 "The World-Tree (Act XV phase 2)": "the tree at the
## centre of the world, its roots in the dead and its crown in the sky"). It
## extends WildGround (the act's root and bark decorations, the season tint
## through modulate) and adds the four zone looks (WorldTreeStage.ZONES
## "ground": base, line, accent, trim; MarchDirector calls set_zone() at each
## zone change). Art pass: the zone's floor tile (tiles/world_tree_<style>.png,
## docs/year/ART_MANIFEST.md) replaces the base colour when its PNG exists, else
## the act's own tiles/wild_tree; the decorations stay code-drawn and sparse
## (disc textures and rects: the layer redraws only on a cell change). Purely
## cosmetic: nothing here collides.
class_name WorldTreeGround
extends WildGround

## The act's World-Tree tile, used while a zone has no tile of its own.
const FALLBACK_TILE: String = "tiles/wild_tree"


func _ready() -> void:
	super._ready()
	look = WorldTreeStage.ZONES[0]["ground"]


## Switches to zone look `p_look` and redraws at once.
func set_zone(p_look: Dictionary) -> void:
	look = p_look
	queue_redraw()


## Floor tile key of the current zone: tiles/world_tree_<style>, else the act's tile.
func _tile_key() -> String:
	var key := EnvironmentArtData.TILE_PREFIX + "world_tree_" + String(look.get("style", "roots"))
	return key if SpriteBank.has(key) else FALLBACK_TILE


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, look.get("base", Color(0.13, 0.15, 0.10)))
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_wild_cell(cx, cy, "tree")
