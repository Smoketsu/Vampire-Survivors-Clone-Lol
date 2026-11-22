## SilverStairGround — the floor of THE SILVER STAIR (temporary Act XIII, the
## Celestial Host; GDD §15.0 "The Silver Stair (Act XIII phase 2)": "a stair
## of light rising from hell's ashes into the clouds"), drawn with _draw() like
## Ground (it extends it and reuses its redraw-on-cell-change logic). Each zone
## has its own floor (SilverStairStage.ZONES "ground"), all over the `stair`
## style: bands of steps whose edges lie `step` px apart, wider with every
## zone (the Stair: each zone is a wider step):
##   ashen_foot  — the Ashen Foot: hell's ash on the first step of light.
##   stair       — the Stair: wide pale steps with silver edges.
##   cloud_shelf — the Cloud Shelf: steps among wisps of cloud.
##   pearl_gate  — the Gate of Pearl: pearl flagstones.
## Art pass: the zone's floor tile (tiles/silver_stair_<style>.png,
## docs/host/ART_MANIFEST.md) replaces the base colour and the step bands when
## its PNG exists (Ground header, EnvironmentArt); the decorations stay
## code-drawn, sparse and flat. The cloud shadows are not drawn here
## (CloudShade draws them above the floor). MarchDirector calls set_zone() at
## each zone change. Purely cosmetic: nothing here collides.
class_name SilverStairGround
extends Ground

## Current zone look (a SilverStairStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = SilverStairStage.ZONES
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
		var step := float(_look["step"])  # px between two step edges (the zone's step).
		var y := floorf(rect.position.y / step) * step
		while y <= rect.end.y:
			draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, 3.0)), _look["line"])
			draw_rect(Rect2(Vector2(rect.position.x, y + 3.0), Vector2(rect.size.x, 1.0)), Color(Palette.HOST_SILVER, 0.18))
			y += step
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_site_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 3737)))


## Decal key prefix of the current zone: silver_stair_<style>_.
func _decal_prefix() -> String:
	return "silver_stair_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/silver_stair_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "silver_stair_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (disc
## textures and rects only).
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	match String(_look["style"]):
		"ashen_foot":
			if roll < 0.12:
				SpriteBank.draw_disc(self, p, 5.0 + float(h % 5), Color(0.06, 0.06, 0.08, 0.45))  # Hell's ash.
			elif roll < 0.16:
				draw_rect(Rect2(p, Vector2(12.0, 2.0)), Color(accent, 0.35))  # A first vein of light.
		"stair":
			if roll < 0.08:
				draw_rect(Rect2(p, Vector2(14.0 + float(h % 10), 2.0)), Color(accent, 0.3))  # A silver vein in the step.
			elif roll < 0.11:
				SpriteBank.draw_disc(self, p, 3.0, Color(trim, 0.4))  # A glint.
		"cloud_shelf":
			if roll < 0.12:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(Palette.HOST_CLOUD, 0.12))  # A wisp of cloud.
			elif roll < 0.15:
				draw_rect(Rect2(p, Vector2(16.0, 1.0)), Color(accent, 0.35))
		_:
			if roll < 0.08:
				SpriteBank.draw_disc(self, p, 6.0 + float(h % 4), Color(Palette.HOST_STARLIGHT, 0.14))  # A pearl inlay.
			elif roll < 0.12:
				draw_rect(Rect2(p, Vector2(20.0, 1.0)), Color(trim, 0.45))  # A flagstone joint.
