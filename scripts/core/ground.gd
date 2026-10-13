## Ground — procedural moonlit graveyard floor (GDD §11 art: cemetery, broken
## tombs, dead trees, fog and spectral blue-green light) drawn with _draw().
## The arena is an endless open plane, so decorations are generated from a
## hash of the grid cell (stable when revisited). The canvas is only redrawn
## when the camera crosses into a new REDRAW_CELL, not every frame.
## Art pass (EnvironmentArt): when the zone's floor tile PNG exists
## (_tile_key(), e.g. tiles/graveyard.png) the base colour and joint grid are
## replaced by a grid of that tile and its variants (tiles/<zone>_2, _3), one
## tile per decoration CELL, the variant picked from the same cell hash as the
## decoration (_cell_hash()), drawn 1 art px = 1 layout px through the
## sharp-pixel shader on the same redraws as before (a few draw calls per
## redraw); the code decorations stay on top. No PNG: the code floor as before.
## Purely cosmetic: nothing here collides.
class_name Ground
extends Node2D

## Size (px) of one decoration cell.
const CELL: float = 128.0
## Camera movement (px) that triggers a redraw.
const REDRAW_CELL: float = 256.0
## Half-size (px) of the drawn area around the redraw cell centre.
const HALF_EXTENT: float = 1200.0
## Spacing (px) of the faint ground grid (2 world tiles of ~32 px, GDD §23).
const GRID: float = 64.0

## Redraw cell the canvas is currently centred on.
var _center_cell: Vector2i = Vector2i(1 << 30, 1 << 30)


func _ready() -> void:
	z_index = -10


## Requests a redraw if `focus` moved into a different redraw cell.
func update_view(focus: Vector2) -> void:
	var c := Vector2i(floori(focus.x / REDRAW_CELL), floori(focus.y / REDRAW_CELL))
	if c != _center_cell:
		_center_cell = c
		queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	if not _draw_tiles(rect):
		draw_rect(rect, Palette.GROUND)
		var x := floorf(rect.position.x / GRID) * GRID
		while x <= rect.end.x:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Palette.GROUND_LINE, 1.0)
			x += GRID
		var y := floorf(rect.position.y / GRID) * GRID
		while y <= rect.end.y:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Palette.GROUND_LINE, 1.0)
			y += GRID
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_cell(cx, cy)


## Switches to battle-zone look `look` (a stage ZONES "ground" dictionary).
## The Graveyard has no zones: a no-op here; MarchGround and SanctumGround
## override it (MarchDirector calls it at each zone change).
func set_zone(_look: Dictionary) -> void:
	pass


## Stable hash (>= 0) of decoration cell (cx, cy): it places the cell's
## decoration and picks its floor tile variant. MarchGround and SanctumGround
## salt it with their own value.
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector2i(cx, cy)))


## Floor tile key of the current zone (EnvironmentArtData key scheme).
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "graveyard"


## Covers `rect` with the current zone's floor tile and its variants
## (EnvironmentArt.draw_floor(): one repeating rect on the world tile grid,
## variants per cell from _cell_hash(); a 128 px tile cell is exactly one
## decoration CELL). Returns false, drawing nothing, when the zone has no tile
## PNG.
func _draw_tiles(rect: Rect2) -> bool:
	return EnvironmentArt.draw_floor(self, rect, _tile_key(), _cell_hash)


## Draws the (hash-chosen) decoration of one cell, if any.
func _draw_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var ox := float((h >> 10) % 96) + 16.0
	var oy := float((h >> 17) % 96) + 16.0
	var p := Vector2(float(cx) * CELL + ox, float(cy) * CELL + oy)
	if roll < 0.12:
		# Tombstone: rounded slab with a dark shadow.
		draw_rect(Rect2(p + Vector2(-8, 2), Vector2(18, 6)), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(p + Vector2(-7, -10), Vector2(14, 14)), Palette.STONE)
		draw_circle(p + Vector2(0, -10), 7.0, Palette.STONE)
		draw_line(p + Vector2(-3, -9), p + Vector2(3, -9), Palette.GROUND_LINE, 1.0)
	elif roll < 0.17:
		# Stone cross.
		draw_rect(Rect2(p + Vector2(-2, -16), Vector2(4, 20)), Palette.STONE)
		draw_rect(Rect2(p + Vector2(-7, -11), Vector2(14, 4)), Palette.STONE)
	elif roll < 0.20:
		# Dead tree.
		var trunk := Color(0.16, 0.13, 0.12)
		draw_line(p + Vector2(0, 6), p + Vector2(0, -26), trunk, 3.0)
		draw_line(p + Vector2(0, -14), p + Vector2(-12, -26), trunk, 2.0)
		draw_line(p + Vector2(0, -20), p + Vector2(10, -32), trunk, 2.0)
	elif roll < 0.23:
		# Broken (open) grave.
		draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 10)), Color(0.05, 0.05, 0.06))
		draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 10)), Palette.STONE, false, 1.5)
	elif roll < 0.36:
		# Spectral fog patch.
		draw_circle(p, 40.0 + float(h % 30), Palette.FOG)
	elif roll < 0.42:
		# Grass tufts.
		var grass := Color(0.14, 0.2, 0.16)
		for i in 3:
			var gp := p + Vector2(float(i) * 5.0 - 5.0, 0)
			draw_line(gp, gp + Vector2(-2, -6), grass, 1.0)
			draw_line(gp, gp + Vector2(2, -7), grass, 1.0)
