## ArchiveGround — the Hollow Archive's procedural floor (Act II, Stage 5; GDD
## §15.0 "Act II: the Hollow Archive"), drawn with _draw() like Ground (it
## extends it and reuses its redraw-on-cell-change logic). Each zone has its
## own floor (ArchiveStage.ZONES "ground"):
##   halls   — the Reading Halls: dark parquet with crimson carpet runners
##             along the shelf rows.
##   wells   — the Ink Wells: black marble slabs stained with old ink.
##   orrery  — the Orrery: a dark floor inlaid with a brass star chart.
##   stacks  — the Unwritten Stacks: pale stone strewn with blank pages.
## MarchDirector calls set_zone() at each zone change. Art pass: the zone's
## floor tile (tiles/archive_<style>.png) replaces the base colour and the
## joints when its PNG exists (Ground header, EnvironmentArt); the decorations
## then become floor decals (decals/archive_<style>_<name>.png) or stay
## code-drawn when they are soft light. Purely cosmetic: nothing here collides.
class_name ArchiveGround
extends Ground

## Current zone look (an ArchiveStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = ArchiveStage.ZONES
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
			"halls":
				_planks(rect, 16.0, 96.0)
			"wells":
				_grid(rect, GRID * 1.5, 2.0)
			"orrery":
				_grid(rect, GRID * 2.0, 1.0)
			_:
				_grid(rect, GRID, 1.0)
	if style == "halls" and not _art_floor:
		_runners(rect)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_archive_cell(cx, cy, style)


## Parquet: plank rows `row` px tall, `plank` px long, staggered.
func _planks(rect: Rect2, row: float, plank: float) -> void:
	var line: Color = _look["line"]
	var y := floorf(rect.position.y / row) * row
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.0)
		var shift := plank * 0.5 if int(floorf(y / row)) % 2 == 0 else 0.0
		var x := floorf(rect.position.x / plank) * plank + shift
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + row), line, 1.0)
			x += plank
		y += row


## Crimson carpet runners along the Reading Halls' aisles (between the shelf
## rows, which stand at the centre of every arena cell row).
func _runners(rect: Rect2) -> void:
	var cell := ArenaData.CELL
	var y := floorf(rect.position.y / cell) * cell
	while y <= rect.end.y:
		var mid := y  # The aisle between two shelf rows (cell edges).
		draw_rect(Rect2(rect.position.x, mid - 26.0, rect.size.x, 52.0), Color(_look["accent"], 0.85))
		draw_line(Vector2(rect.position.x, mid - 26.0), Vector2(rect.end.x, mid - 26.0), Color(_look["trim"], 0.5), 2.0)
		draw_line(Vector2(rect.position.x, mid + 26.0), Vector2(rect.end.x, mid + 26.0), Color(_look["trim"], 0.5), 2.0)
		y += cell


## A square joint grid every `step` px, lines `width` px wide.
func _grid(rect: Rect2, step: float, width: float) -> void:
	var line: Color = _look["line"]
	var x := floorf(rect.position.x / step) * step
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, width)
		x += step
	var y := floorf(rect.position.y / step) * step
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, width)
		y += step


## The Archive's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 515)))


## Decal key prefix of the current zone: archive_<style>_.
func _decal_prefix() -> String:
	return "archive_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/archive_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "archive_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_archive_cell(cx: int, cy: int, style: String) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match style:
		"halls":
			if roll < 0.08:
				if _decal(_decal_prefix() + "pages", p, h):
					return
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 7.0 - 8.0, float(i % 2) * 4.0), Vector2(8, 6)), Color(ArchivistData.PAGE_COLOR, 0.35))
			elif roll < 0.13:
				draw_circle(p, 34.0, Color(1.0, 0.85, 0.5, 0.035))  # Candle light (soft: stays code-drawn).
		"wells":
			if roll < 0.18:
				if _decal(_decal_prefix() + "stain", p, h):
					return
				draw_circle(p, 10.0 + float(h % 12), Color(ArchiveEnemyData.INK_COLOR, 0.45))
				draw_circle(p + Vector2(12, 5), 4.0, Color(ArchiveEnemyData.INK_COLOR, 0.45))
		"orrery":
			if roll < 0.10:
				if _decal(_decal_prefix() + "star", p, h):
					return
				for i in 4:
					var a := float(i) * PI * 0.5 + float(h % 7) * 0.2
					draw_line(p, p + Vector2.from_angle(a) * 7.0, Color(trim, 0.5), 1.0)
				draw_circle(p, 1.5, Color(trim, 0.8))
			elif roll < 0.14:
				draw_arc(p, 40.0 + float(h % 30), 0.0, TAU, 32, Color(trim, 0.18), 1.0)  # Inlaid orbit ring.
		_:
			if roll < 0.2:
				if _decal(_decal_prefix() + "pages", p, h):
					return
				for i in 2:
					draw_rect(Rect2(p + Vector2(float(i) * 9.0 - 6.0, float(i) * 3.0), Vector2(10, 7)), Color(accent.lightened(0.2), 0.5))
