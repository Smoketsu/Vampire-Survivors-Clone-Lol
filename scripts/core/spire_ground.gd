## SpireGround — the procedural floor of Ul-Thalos, the Risen Spire (Act II,
## Stage 6; GDD §15.0 "Ul-Thalos, the Risen Spire": wet green stone and wrong
## angles), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor
## (SpireStage.ZONES "ground"):
##   breakwater — wet green flagstones of uneven, slanted courses, tide pools.
##   steps      — broad terraces stepping down toward the sea, kelp in the joints.
##   gate       — dark basalt veined with the biolume glow of the god's dream.
##   spire      — the spire's foot: concentric rings of spiral stone around the
##                island's centre.
## The sea itself is SinkingDirector's (drawn over this floor). Art pass: the
## zone's floor tile (tiles/spire_<style>.png) replaces the base colour and
## joints when its PNG exists (Ground header, EnvironmentArt); the decorations
## then become decals (decals/spire_<style>_<name>.png) when those exist, or
## stay code-drawn (the soft pools and glows). MarchDirector calls set_zone()
## at each zone change. Purely cosmetic.
class_name SpireGround
extends Ground

## Current zone look (a SpireStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = SpireStage.ZONES
	_look = zones[0]["ground"]


## Switches to zone look `look` and redraws at once.
func set_zone(look: Dictionary) -> void:
	_look = look
	queue_redraw()


func _draw() -> void:
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	var style := String(_look["style"])
	_art_floor = _draw_tiles(rect)
	if not _art_floor:
		draw_rect(rect, _look["base"])
		match style:
			"breakwater":
				_slanted_courses(rect, 40.0, 64.0)
			"steps":
				_slanted_courses(rect, 72.0, 112.0)
			"gate":
				_slanted_courses(rect, 56.0, 56.0)
			_:
				_rings(rect)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_spire_cell(cx, cy, style)


## Flagstone courses `row` px tall, slabs `slab` px long, whose joints lean
## (the wrong angles of the drowned city).
func _slanted_courses(rect: Rect2, row: float, slab: float) -> void:
	var line: Color = _look["line"]
	var y := floorf(rect.position.y / row) * row
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.5)
		var shift := slab * 0.37 * float(int(floorf(y / row)) % 3)  # Staggered joints.
		var x := floorf(rect.position.x / slab) * slab + shift
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x + row * 0.25, y + row), line, 1.5)
			x += slab
		y += row


## The Spire's foot: concentric stone rings around the island's centre and
## radial joints.
func _rings(rect: Rect2) -> void:
	var line: Color = _look["line"]
	var far := rect.position.length() + rect.size.length()
	var r := 48.0
	while r < far:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, maxi(24, int(r / 8.0)), line, 1.5)
		r += 48.0
	for i in 24:
		var d := Vector2.from_angle(TAU * float(i) / 24.0 + 0.13)
		draw_line(d * 48.0, d * far, line, 1.0)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 6606)))


## Decal key prefix of the current zone: spire_<style>_.
func _decal_prefix() -> String:
	return "spire_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/spire_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "spire_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_spire_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var k := _decal_prefix()  # Decal key prefix (spire_<style>_).
	var accent: Color = _look["accent"]
	var glow: Color = _look["glow"]
	if roll < 0.14:
		# A tide pool (soft and translucent: code-drawn on the tile floor too).
		var w := 18.0 + float(h % 18)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, w, Color(0.04, 0.12, 0.14, 0.75))
		draw_arc(Vector2.ZERO, w, 0.0, TAU, 20, Color(0.50, 0.71, 0.67, 0.35), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif roll < 0.24:
		if _decal(k + "barnacles", p, h):
			return
		for i in 5:  # Barnacle crust.
			var q := p + Vector2(float((h >> (i * 2)) % 18), float((h >> (i * 2 + 5)) % 12))
			draw_circle(q, 2.0, Color(0.50, 0.71, 0.67, 0.8))
			draw_circle(q, 0.8, Color(0.06, 0.15, 0.17))
	elif roll < 0.32:
		if _decal(k + "kelp", p, h):
			return
		for i in 3:  # A strand of washed-up kelp.
			var a := p + Vector2(float(i) * 7.0, 0.0)
			draw_polyline(PackedVector2Array([a, a + Vector2(4, -6), a + Vector2(1, -12), a + Vector2(5, -18)]), Color(0.16, 0.30, 0.18), 2.0)
	elif roll < 0.38:
		if _decal(k + "glyph", p, h):
			return
		# A carved sigil of the Eye, faintly glowing in the Gate and the Spire.
		var a := 0.0 if style == "breakwater" or style == "steps" else 0.6
		draw_arc(p, 9.0, 0.0, TAU, 14, Color(accent.lightened(0.15), 0.9), 1.5)
		draw_circle(p, 3.0, Color(glow, 0.35 + a * 0.4))
		draw_line(p + Vector2(-12, 0), p + Vector2(12, 0), Color(accent.lightened(0.15), 0.9), 1.0)
	elif roll < 0.42 and (style == "gate" or style == "spire"):
		# A crack of the dream's light (soft: code-drawn on the tile floor too).
		draw_polyline(PackedVector2Array([p, p + Vector2(11, 4), p + Vector2(17, 1), p + Vector2(28, 9)]), Color(glow, 0.55), 1.5)
	elif roll < 0.46:
		if _decal(k + "bones", p, h):
			return
		# Drowned bones bleached by the sea.
		draw_line(p, p + Vector2(10, 3), Color(0.70, 0.67, 0.55, 0.8), 2.0)
		draw_circle(p + Vector2(13, 4), 2.5, Color(0.70, 0.67, 0.55, 0.8))
