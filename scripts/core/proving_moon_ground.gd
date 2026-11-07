## ProvingMoonGround — the floor of the Proving Moon (Act IX, Stage 26; GDD §15.0
## "The Proving Moon (Act IX phase 2)": "the Vrask take the necromancer to their
## hunting ground on the moon"), drawn with _draw() like Ground (it extends it
## and reuses its redraw-on-cell-change logic). Each zone has its own floor
## (ProvingMoonStage.ZONES "ground"), over the foundation's "moon" style:
##   landing       — the Landing: grey regolith, small craters, the Vrask's teal
##                   trail markers.
##   craters       — the Craters: pitted regolith, crater bowls with pale rims.
##   trophy_hall   — the Trophy Hall: dark cut stone, the Vrask's trophies
##                   hanging over it (hanging-skull decals).
##   duelling_ring — the Duelling Ring: packed grey dust marked with the
##                   duellists' circles (ring-marking decals) and teal lines.
## Art pass: the zone's floor tile (tiles/proving_moon_<style>.png) replaces the
## base colour when its PNG exists (Ground header, EnvironmentArt), and the
## decorations are decals (decals/proving_moon_<style>_<name>.png, DecalData)
## when theirs exist; the code shapes stay as the fallback. MarchDirector calls
## set_zone() at each zone change. The alien turf is drawn above it by
## Terraforming. Purely cosmetic: nothing here collides.
class_name ProvingMoonGround
extends Ground

## Current zone look (a ProvingMoonStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = ProvingMoonStage.ZONES
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
			_draw_moon_cell(cx, cy)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 2626)))


## Decal key prefix of the current zone: proving_moon_<style>_.
func _decal_prefix() -> String:
	return "proving_moon_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/proving_moon_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "proving_moon_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_moon_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	match String(_look["style"]):
		"trophy_hall":
			if roll < 0.07:
				if _decal(_decal_prefix() + "skulls", p, h):
					return
				for k in 3:
					SpriteBank.draw_disc(self, p + Vector2(float(k) * 7.0, float(k % 2) * 3.0), 2.5, Color(Palette.CONCORD_HIVE_BONE, 0.7))  # Hung skulls.
				draw_line(p + Vector2(-3, -4), p + Vector2(17, -4), Color(trim, 0.6), 1.0)  # Their cord.
			elif roll < 0.2:
				draw_line(p, p + Vector2(24.0, 0.0), Color(line, 0.8), 1.0)  # A stone seam.
		"duelling_ring":
			if roll < 0.06:
				if _decal(_decal_prefix() + "ring", p, h):
					return
				SpriteBank.draw_disc(self, p, 22.0, Color(trim, 0.25))  # A duelling circle.
				SpriteBank.draw_disc(self, p, 19.0, _look["base"])
			elif roll < 0.1:
				draw_rect(Rect2(p, Vector2(10, 2)), Color(trim, 0.6))  # A teal line mark.
		_:
			if roll < (0.16 if String(_look["style"]) == "craters" else 0.1):
				if _decal(_decal_prefix() + "crater", p, h):
					return
				SpriteBank.draw_disc(self, p, 8.0 + float(h % 10), Color(accent, 0.6))  # A small crater.
				SpriteBank.draw_disc(self, p + Vector2(-2, -2), 5.0 + float(h % 6), Color(line.lightened(0.15), 0.5))
			elif roll < 0.14:
				draw_rect(Rect2(p, Vector2(3, 3)), Color(trim, 0.8))  # A trail marker.
