## EmpyreanGround — the floor of THE EMPYREAN (temporary Act XIII, the Celestial
## Host's finale; GDD §15.0 "The Empyrean (Act XIII phase 2)": "the highest
## heaven: a white rose of light, endless and silent"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Each zone
## has its own floor (EmpyreanStage.ZONES "ground"), all over the `rose` style:
## pale petals of light crossed by faint curved petal seams (drawn as short
## rects on rings `grid` px apart round the world origin, the rose's heart),
## darker toward the heart only in value, never in hue:
##   rose_edge — the Rose's Edge: the palest petals, scattered motes.
##   petals    — the Petals: petal seams and soft rose blushes.
##   choir     — the Choir: silver lines of the hymn across the petals.
##   heart     — the Heart of the Rose: the deepest light, starlight sparks.
## Art pass: the zone's floor tile (tiles/empyrean_<style>.png,
## docs/host/ART_MANIFEST.md) replaces the base colour and the seams when its
## PNG exists (Ground header, EnvironmentArt); the decorations stay code-drawn,
## sparse and flat. MarchDirector calls set_zone() at each zone change. Purely
## cosmetic: nothing here collides.
class_name EmpyreanGround
extends Ground

## Current zone look (an EmpyreanStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = EmpyreanStage.ZONES
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
		var grid := float(_look["grid"])  # px between two petal seams.
		var y := floorf(rect.position.y / grid) * grid
		while y <= rect.end.y:
			var x := floorf(rect.position.x / grid) * grid
			while x <= rect.end.x:
				draw_rect(Rect2(Vector2(x + grid * 0.25, y), Vector2(grid * 0.5, 1.0)), _look["line"])  # A petal seam.
				x += grid
			y += grid * 0.5
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_site_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 3939)))


## Decal key prefix of the current zone: empyrean_<style>_.
func _decal_prefix() -> String:
	return "empyrean_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/empyrean_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "empyrean_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (disc
## textures and rects only).
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"rose_edge":
			if roll < 0.12:
				SpriteBank.draw_disc(self, p, 5.0 + float(h % 4), Color(Palette.HOST_STARLIGHT, 0.16))  # A mote of light.
		"petals":
			if roll < 0.1:
				SpriteBank.draw_disc(self, p, 8.0 + float(h % 6), Color(trim, 0.12))  # A rose blush on a petal.
			elif roll < 0.14:
				draw_rect(Rect2(p, Vector2(18.0, 1.0)), Color(accent, 0.3))
		"choir":
			if roll < 0.12:
				draw_rect(Rect2(p, Vector2(26.0, 1.0)), Color(accent, 0.35))  # A line of the hymn.
				draw_rect(Rect2(p + Vector2(4.0, 4.0), Vector2(18.0, 1.0)), Color(accent, 0.25))
		_:
			if roll < 0.18:
				SpriteBank.draw_disc(self, p, 1.5 + float(h % 2), Color(Palette.HOST_STARLIGHT, 0.65))  # A spark of the heart.
			elif roll < 0.22:
				SpriteBank.draw_disc(self, p, 4.0, Color(trim, 0.3))
