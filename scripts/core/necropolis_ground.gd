## NecropolisGround — the floor of the Necropolis of Sand (temporary Act XII,
## the Necropolis Dynasty; GDD §15.0 "The Necropolis of Sand (Act XII phase
## 2)": "the tomb road at dusk: dunes, rock-cut tombs and mortuary temples"),
## drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor
## (NecropolisStage.ZONES "ground"), all over the sand:
##   dunes           — the Dunes: wind-rippled dunes at dusk.
##   tomb_road       — the Tomb Road: the worn paving of the road of tombs.
##   sandstorm_pass  — the Sandstorm Pass: a pebbled pass between the cliffs.
##   mortuary_temple — the Mortuary Temple: flagstones with lapis inlay.
## Art pass: the zone's floor tile (tiles/necropolis_<style>.png, the
## Dynasty art pass) replaces the base colour when its PNG exists (Ground
## header, EnvironmentArt); the rest stay code-drawn, sparse and flat (a wind
## ripple, a half-buried stone, a bronze inlay). The quicksand is not drawn
## here (Quicksand draws it above the floor). MarchDirector calls set_zone()
## at each zone change. Purely cosmetic: nothing here collides.
class_name NecropolisGround
extends Ground

## Current zone look (a NecropolisStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = NecropolisStage.ZONES
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
			_draw_site_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 3434)))


## Decal key prefix of the current zone: necropolis_<style>_.
func _decal_prefix() -> String:
	return "necropolis_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/necropolis_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "necropolis_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"dunes":
			if roll < 0.06:
				draw_rect(Rect2(p, Vector2(18.0, 1.0)), Color(accent, 0.45))  # A wind ripple.
			elif roll < 0.08:
				draw_rect(Rect2(p, Vector2(4.0, 3.0)), Color(trim, 0.5))  # A half-buried stone.
		"tomb_road":
			if roll < 0.05:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 5.0)), Color(accent, 0.55))  # A broken paving slab.
			elif roll < 0.07:
				draw_rect(Rect2(p, Vector2(14.0, 1.0)), Color(trim, 0.5))  # Drifted sand on a joint.
		"sandstorm_pass":
			if roll < 0.07:
				draw_rect(Rect2(p, Vector2(3.0, 2.0)), Color(accent, 0.6))  # A pebble.
			elif roll < 0.09:
				draw_rect(Rect2(p, Vector2(20.0, 1.0)), Color(trim, 0.4))  # A wind streak.
		_:
			if roll < 0.05:
				draw_rect(Rect2(p, Vector2(16.0, 2.0)), Color(accent, 0.6))  # A bronze inlay line.
			elif roll < 0.08:
				draw_rect(Rect2(p, Vector2(3.0, 3.0)), Color(trim, 0.75))  # A lapis stud.
