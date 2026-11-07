## BurningGateGround — the procedural floor of the Burning Gate (Act VI, Stage
## 16; GDD §15.0 "The Burning Gate (Act VI phase 2)": "a plain of ash and
## obsidian before the gate of hell, the river of fire Phlegethon along its
## edge"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor
## (BurningGateStage.ZONES "ground"):
##   ash_plain — the Ash Plain: grey ash drifts and obsidian shards.
##   cages     — the Cages: cinder-black earth under the hanging cages.
##   river     — the River of Fire: Phlegethon's scorched red-brown bank (the
##               river itself is the Hell Pits' burning band, drawn by HellPits).
##   gate      — the Gate: black flagstones before the gate of hell.
## Art pass: the zone's floor tile (tiles/burning_gate_<style>.png) replaces the
## base colour when its PNG exists (Ground header, EnvironmentArt); the rest stay
## code-drawn, sparse and flat (an obsidian shard, an ember, a scrap of chain).
## MarchDirector calls set_zone() at each zone change. Purely cosmetic: nothing
## here collides or burns.
class_name BurningGateGround
extends Ground

## Current zone look (a BurningGateStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = BurningGateStage.ZONES
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
			_draw_gate_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 1616)))


## Decal key prefix of the current zone: burning_gate_<style>_.
func _decal_prefix() -> String:
	return "burning_gate_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/burning_gate_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "burning_gate_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_gate_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	if roll < 0.06:
		var w := 4.0 + float(h % 5)  # px.
		draw_rect(Rect2(p, Vector2(w, w * 0.6).round()), Color(accent, 0.5))  # An obsidian shard.
	elif roll < 0.085:
		draw_rect(Rect2(p, Vector2(2, 2)), Color(trim, 0.7))  # An ember.
	elif roll < 0.1:
		draw_rect(Rect2(p, Vector2(6, 2)), Color(InfernoGlyphs.IRON, 0.45))  # A scrap of chain.
