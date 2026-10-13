## MarchGround — the Crimson March's procedural floor (GDD §8.2 art: "roads,
## devastated settlements, forests, camps, barricades and distant fortress
## towers"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). The old road runs along y = 0 through every
## zone (Arena keeps it free of obstacles); around it each battle zone has
## its own soil colour and hash-placed decorations (CrimsonMarchStage.ZONES
## "ground"):
##   burned      — ash drifts, charred stumps, smouldering embers, arrows.
##   checkpoint  — grass, mud, sharpened stakes, crimson pennants.
##   camp        — trampled dirt, campfires, tent pegs, small crates.
##   fortress    — cobbles, rubble, gold-and-crimson banner posts, wall
##                 shadows of the fortress towers.
## MarchDirector calls set_zone() at each zone change. Art pass: the zone's
## floor tile (tiles/march_<style>.png) replaces the soil colour and grid, and
## the road strip (tiles/march_road[_<style>].png) the code road, each only
## when its PNG exists (Ground header, EnvironmentArt); on the tile floor the
## decorations become floor decals (decals/march_<style>_<name>.png, the road
## arrow decals/march_arrow.png), are dropped, or stay code-drawn (the tower
## shadows), per DecalData. Purely cosmetic.
class_name MarchGround
extends Ground

## Current zone look (a ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = CrimsonMarchStage.ZONES
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
		var line: Color = _look["line"]
		var x := floorf(rect.position.x / GRID) * GRID
		while x <= rect.end.x:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, 1.0)
			x += GRID
		var y := floorf(rect.position.y / GRID) * GRID
		while y <= rect.end.y:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.0)
			y += GRID
	if not EnvironmentArt.draw_road(self, rect, String(_look["style"])):
		_draw_road(rect)
	var c0 := Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
	var c1 := Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			_draw_march_cell(cx, cy)


## The old road along y = 0: packed earth (or paving near the fortress)
## with darker verges and wheel ruts.
func _draw_road(rect: Rect2) -> void:
	var half := float(CrimsonMarchStage.MARCH["road_half_width"])
	if rect.position.y > half or rect.end.y < -half:
		return
	var road: Color = _look["road"]
	var edge: Color = _look["road_edge"]
	draw_rect(Rect2(rect.position.x, -half, rect.size.x, half * 2.0), road)
	draw_rect(Rect2(rect.position.x, -half, rect.size.x, 6.0), edge)
	draw_rect(Rect2(rect.position.x, half - 6.0, rect.size.x, 6.0), edge)
	for rut: float in [-22.0, -14.0, 14.0, 22.0]:
		draw_line(Vector2(rect.position.x, rut), Vector2(rect.end.x, rut), road.darkened(0.25), 2.0)
	if String(_look["style"]) == "fortress":
		# Paving stones.
		var px := floorf(rect.position.x / 40.0) * 40.0
		while px <= rect.end.x:
			draw_line(Vector2(px, -half + 6.0), Vector2(px, half - 6.0), road.darkened(0.3), 1.0)
			px += 40.0


## The March's cell hash (salted, so its decorations differ from the Graveyard's).
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 77)))


## Decal key prefix of the current zone: march_<style>_.
func _decal_prefix() -> String:
	return "march_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/march_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "march_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone.
func _draw_march_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	if absf(p.y) < float(CrimsonMarchStage.MARCH["road_half_width"]) - 8.0:
		# On the road: only the odd dropped arrow or a cart rut puddle.
		if roll < 0.08 and not _decal("march_arrow", p, h):
			draw_line(p, p + Vector2(10, -4), Color(0.45, 0.35, 0.22), 1.0)
		return
	match String(_look["style"]):
		"burned":
			_decor_burned(p, roll, h)
		"checkpoint":
			_decor_checkpoint(p, roll, h)
		"camp":
			_decor_camp(p, roll, h)
		_:
			_decor_fortress(p, roll, h)


## Burned Road: ash drifts, charred stumps, embers, spent arrows. On the tile
## floor each is its decal (_decal(), DecalData) when the PNG exists.
func _decor_burned(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (march_burned_).
	if roll < 0.14:
		if not _decal(k + "ash", p, h):
			draw_circle(p, 26.0 + float(h % 20), Color(0.05, 0.045, 0.045, 0.6))  # Ash drift.
	elif roll < 0.20:
		if _decal(k + "stump", p, h):
			return
		draw_circle(p + Vector2(2, 3), 7.0, Color(0, 0, 0, 0.3))
		draw_circle(p, 6.0, Color(0.12, 0.09, 0.07))  # Charred stump.
		draw_circle(p, 3.0, Color(0.06, 0.05, 0.04))
	elif roll < 0.26:
		if _decal(k + "embers", p, h):
			return
		for i in 3:  # Smouldering embers.
			draw_circle(p + Vector2(float(i) * 6.0 - 6.0, float((h >> (i + 3)) % 7) - 3.0), 1.5, Color(Palette.FLAME, 0.7))
	elif roll < 0.31:
		if _decal("march_arrow", p, h):
			return
		draw_line(p, p + Vector2(9, -9), Color(0.42, 0.32, 0.2), 1.0)  # Spent arrow.
		draw_line(p + Vector2(9, -9), p + Vector2(7, -9), Palette.IVORY, 1.5)
	elif roll < 0.36:
		if not _decal(k + "plank", p, h):
			draw_rect(Rect2(p, Vector2(10, 4)), Color(0.18, 0.12, 0.08))  # Broken plank.


## Fortified Checkpoint: grass, mud, sharpened stakes, crimson pennants.
func _decor_checkpoint(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (march_checkpoint_).
	if roll < 0.18:
		if _decal(k + "grass", p, h):
			return
		var grass := Color(0.16, 0.24, 0.14)
		for i in 3:
			var gp := p + Vector2(float(i) * 5.0 - 5.0, 0)
			draw_line(gp, gp + Vector2(-2, -6), grass, 1.0)
			draw_line(gp, gp + Vector2(2, -7), grass, 1.0)
	elif roll < 0.26:
		if not _decal(k + "mud", p, h):
			draw_circle(p, 18.0 + float(h % 12), Color(0.09, 0.07, 0.05, 0.6))  # Mud.
	elif roll < 0.31:
		if _decal(k + "stakes", p, h):
			return
		for i in 3:  # Sharpened stakes.
			var sp := p + Vector2(float(i) * 7.0 - 7.0, 0)
			draw_line(sp, sp + Vector2(2, -10), Color(0.38, 0.28, 0.16), 2.0)
	elif roll < 0.34:
		if _decal(k + "pennant", p, h):
			return
		draw_line(p, p + Vector2(0, -18), Palette.SILVER.darkened(0.3), 1.5)  # Pennant.
		draw_colored_polygon(PackedVector2Array([p + Vector2(1, -18), p + Vector2(10, -15), p + Vector2(1, -12)]), Palette.CRIMSON)


## Siege Camp: trampled dirt, campfires, tent pegs and ropes, small crates.
func _decor_camp(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (march_camp_).
	if roll < 0.14:
		if not _decal(k + "trampled", p, h):
			draw_circle(p, 22.0 + float(h % 16), Color(0.15, 0.12, 0.09, 0.5))  # Trampled dirt.
	elif roll < 0.19:
		if _decal(k + "campfire", p, h):
			return
		draw_circle(p, 14.0, Color(Palette.FLAME, 0.08))  # Campfire glow.
		draw_circle(p, 5.0, Color(0.1, 0.08, 0.06))
		draw_circle(p, 3.0, Palette.FLAME)
	elif roll < 0.25:
		if _decal(k + "rope", p, h):
			return
		draw_line(p, p + Vector2(16, -6), Color(0.5, 0.45, 0.35), 1.0)  # Rope and peg.
		draw_rect(Rect2(p + Vector2(15, -8), Vector2(3, 4)), Color(0.35, 0.25, 0.15))
	elif roll < 0.30:
		if _decal(k + "crate", p, h):
			return
		draw_rect(Rect2(p + Vector2(1, 2), Vector2(12, 10)), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(p, Vector2(12, 10)), Color(0.36, 0.26, 0.15))  # Small crate.
		draw_line(p, p + Vector2(12, 10), Color(0.25, 0.18, 0.1), 1.0)


## Fortress Approach: cobbles, rubble, banner posts and tower shadows.
func _decor_fortress(p: Vector2, roll: float, h: int) -> void:
	var k := _decal_prefix()  # Decal key prefix (march_fortress_).
	if roll < 0.16:
		if _decal(k + "cobbles", p, h):
			return
		for i in 4:  # Cobbles.
			draw_rect(Rect2(p + Vector2(float(i % 2) * 9.0, floorf(float(i) / 2.0) * 7.0), Vector2(8, 6)), Color(0.17, 0.17, 0.19))
	elif roll < 0.22:
		if _decal(k + "rubble", p, h):
			return
		draw_circle(p, 5.0, Palette.STONE)  # Rubble.
		draw_circle(p + Vector2(7, 3), 3.5, Palette.STONE.darkened(0.2))
	elif roll < 0.26:
		if _decal(k + "banner", p, h):
			return
		draw_line(p, p + Vector2(0, -22), Palette.GOLD.darkened(0.3), 2.0)  # Banner post.
		draw_rect(Rect2(p + Vector2(1, -22), Vector2(9, 12)), Palette.CRIMSON)
		draw_rect(Rect2(p + Vector2(4, -19), Vector2(3, 6)), Palette.GOLD)
	elif roll < 0.30:
		draw_rect(Rect2(p, Vector2(60.0 + float(h % 30), 18)), Color(0, 0, 0, 0.18))  # A tower's long shadow (soft: code-drawn on the tile floor too).
