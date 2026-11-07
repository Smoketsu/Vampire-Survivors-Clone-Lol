## CrashSiteGround — the procedural floor of the Crash Site (Act IX, Stage 25;
## GDD §15.0 "The Crash Site (Act IX phase 2)": "a Harvester scout ship lies
## broken in the ruins of the capital"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its
## own floor (CrashSiteStage.ZONES "ground"), all over the capital's ruins:
##   crater   — the Crater: glassed black rock with cooled glass seams.
##   hatchery — the Hatchery: green-black resin over the paving.
##   wreck    — the Wreck: the scout ship's buckled hull plates.
##   ruins    — the Glass Spire: the capital's broken paving and rubble.
## Art pass: the zone's floor tile (tiles/crash_site_<style>.png) replaces the
## base colour when its PNG exists (Ground header, EnvironmentArt); the rest
## stay code-drawn, sparse and flat (a hull shard, a scorch mark, a glass
## glint, a resin drip). The alien turf is not drawn here (Terraforming draws
## it above the floor). MarchDirector calls set_zone() at each zone change.
## Purely cosmetic: nothing here collides.
class_name CrashSiteGround
extends Ground

## Current zone look (a CrashSiteStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = CrashSiteStage.ZONES
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
	return absi(hash(Vector3i(cx, cy, 2525)))


## Decal key prefix of the current zone: crash_site_<style>_.
func _decal_prefix() -> String:
	return "crash_site_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/crash_site_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "crash_site_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"crater":
			if roll < 0.05:
				draw_rect(Rect2(p, Vector2(4, 2)), Color(trim, 0.55))  # Cooled plasma in a seam.
			elif roll < 0.09:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 5.0)), Color(accent, 0.6))  # A hull shard.
		"hatchery":
			if roll < 0.06:
				draw_rect(Rect2(p, Vector2(3, 6)), Color(accent, 0.5))  # A resin drip.
			elif roll < 0.08:
				draw_rect(Rect2(p, Vector2(2, 2)), Color(trim, 0.7))  # A glowing spore.
		"wreck":
			if roll < 0.05:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.7))  # A deck light still lit.
			elif roll < 0.08:
				draw_rect(Rect2(p, Vector2(14.0, 2.0)), Color(0.05, 0.05, 0.06, 0.5))  # A scorch line.
		_:
			if roll < 0.06:
				draw_rect(Rect2(p, Vector2(10.0 + float(h % 8), 5.0)), Color(accent, 0.65))  # A hull shard.
			elif roll < 0.09:
				draw_rect(Rect2(p, Vector2(2, 3)), Color(trim, 0.6))  # A glint of glass.
