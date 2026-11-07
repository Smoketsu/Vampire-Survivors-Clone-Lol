## WitchwoodGround — the procedural floor of the Witchwood (Act VII, Stage 20;
## GDD §15.0 "The Witchwood (Act VII phase 2)": "a black fen and a wood of
## hanging charms where the Court's witches keep their sabbath"), drawn with
## _draw() like Ground (it extends it and reuses its redraw-on-cell-change
## logic). Each zone has its own floor (WitchwoodStage.ZONES "ground"):
##   fen             — the Fen: black peat; with "fen": true THE FEN'S POOLS of
##                     black water on top (WitchwoodGlyphs.draw_fen_pool() at
##                     WitchwoodDirector.fen_pool(), the same geometry that
##                     slows: the water is exactly where it slows).
##   hanging_wood    — the Hanging Wood: dark leaf litter and roots.
##   standing_stones — the Standing Stones: a dark heath.
##   cauldron        — the Cauldron: the witches' scorched clearing.
## Art pass: the zone's floor tile (tiles/witchwood_<style>.png) replaces the
## base colour when its PNG exists (Ground header, EnvironmentArt); the rest stay
## code-drawn, sparse and flat (a reed tuft, a fallen red thread, a pebble).
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides or slows.
class_name WitchwoodGround
extends Ground

## Current zone look (a WitchwoodStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = WitchwoodStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _look["base"])
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_wood_cell(cx, cy)
	if bool(_look.get("fen", false)):
		_draw_fen(rect)


## The Fen's pools in `rect` (the director's geometry).
func _draw_fen(rect: Rect2) -> void:
	var f: Dictionary = WitchwoodStage.WITCHWOOD["fen"]
	var cell := float(f["cell"])
	var x0 := floori(rect.position.x / cell) - 1
	var x1 := floori(rect.end.x / cell) + 1
	var y0 := floori(rect.position.y / cell) - 1
	var y1 := floori(rect.end.y / cell) + 1
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var pool := WitchwoodDirector.fen_pool(cx, cy, f)
			if pool.z > 0.0:
				WitchwoodGlyphs.draw_fen_pool(self, Vector2(pool.x, pool.y), pool.z, absi(hash(Vector2i(cx, cy))))


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 2020)))


## Decal key prefix of the current zone: witchwood_<style>_.
func _decal_prefix() -> String:
	return "witchwood_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/witchwood_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "witchwood_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_wood_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	if roll < 0.06:
		draw_line(p, p + Vector2(-1, -6), Color(accent, 0.8), 1.0)  # A reed tuft / a grass blade.
		draw_line(p + Vector2(2, 0), p + Vector2(3, -5), Color(accent, 0.6), 1.0)
	elif roll < 0.08:
		draw_rect(Rect2(p, Vector2(6, 1)), Color(trim, 0.6))  # A fallen red thread.
	elif roll < 0.1:
		var w := 3.0 + float(h % 3)  # px.
		draw_rect(Rect2(p, Vector2(w, w * 0.6).round()), Color(_look["line"], 0.8))  # A pebble.
