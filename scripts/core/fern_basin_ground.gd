## FernBasinGround — the floor of THE FERN BASIN (temporary Act XIV, the Age of
## Titans; GDD §15.0 "The Fern Basin (Act XIV phase 2)": "a river basin deep in
## jungle"), drawn with _draw() like Ground (it extends it and reuses its
## redraw-on-cell-change logic). Each zone has its own floor (FernBasinStage.ZONES
## "ground") over the `fern` style:
##   fern_floor     — jungle earth, fern fronds and deep shade.
##   tar_seep       — darker earth, tar spots.
##   river_ford     — wet earth, reeds and pebbles.
##   nesting_hollow — trampled earth, eggshells and bones.
## It also draws THE TAR SEEPS of the current zone: every pool comes from
## FernBasinDirector.pool_in() over the zone's "ground" "tar" dictionary, the
## same pure hash the director slows and traps with, so the drawn tar is the
## slowing tar (a "river" style draws them as brown water). Art pass: the
## zone's floor tile (tiles/fern_basin_<style>.png, docs/titans/ART_MANIFEST.md)
## replaces the base colour when its PNG exists, and tiles/primeval_tar is
## drawn stretched over a pool when it exists (Ground header, EnvironmentArt);
## the decorations stay code-drawn, sparse and flat (disc textures and rects:
## the layer redraws only on a cell change). MarchDirector calls set_zone() at
## each zone change. Purely cosmetic: nothing here collides or slows.
class_name FernBasinGround
extends Ground

## Sprite key of the tar pool art (drawn stretched over a pool when it exists).
const TAR_ART: String = "tiles/primeval_tar"

## Current zone look (a FernBasinStage.ZONES "ground" dictionary).
var _look: Dictionary = {}


func _ready() -> void:
	super._ready()
	var zones: Array = FernBasinStage.ZONES
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
	_draw_tar(rect)


## The floor's cell hash (salted, so its decorations differ from the others').
func _cell_hash(cx: int, cy: int) -> int:
	return absi(hash(Vector3i(cx, cy, 4040)))


## Decal key prefix of the current zone: fern_basin_<style>_.
func _decal_prefix() -> String:
	return "fern_basin_" + String(_look["style"]) + "_"


## Floor tile key of the current zone: tiles/fern_basin_<style>.
func _tile_key() -> String:
	return EnvironmentArtData.TILE_PREFIX + "fern_basin_" + String(_look["style"])


## Draws the (hash-chosen) decoration of one cell for the current zone (disc
## textures and rects only).
func _draw_site_cell(cx: int, cy: int) -> void:
	var h := _cell_hash(cx, cy)
	var roll := float(h % 1000) / 1000.0
	var p := Vector2(float(cx) * CELL + float((h >> 10) % 96) + 16.0, float(cy) * CELL + float((h >> 17) % 96) + 16.0)
	var accent: Color = _look["accent"]
	var trim: Color = _look["trim"]
	var line: Color = _look["line"]
	match String(_look["style"]):
		"fern_floor":
			if roll < 0.18:
				for i in 4:
					draw_rect(Rect2(p + Vector2(float(i) * 2.0, float(i) * 1.5), Vector2(7.0, 1.5)), Color(accent, 0.4))  # A fern frond.
			elif roll < 0.26:
				SpriteBank.draw_disc(self, p, 16.0 + float(h % 8), Color(line, 0.5))  # Deep shade.
		"tar_seep":
			if roll < 0.14:
				SpriteBank.draw_disc(self, p, 5.0 + float(h % 5), Color(trim, 0.6))  # A tar spot.
			elif roll < 0.22:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 2.0, float(i)), Vector2(6.0, 1.5)), Color(accent, 0.45))  # A dark frond.
		"river_ford":
			if roll < 0.12:
				for i in 3:
					draw_rect(Rect2(p + Vector2(float(i) * 3.0, -float(i % 2) * 2.0), Vector2(1.0, 6.0)), Color(trim, 0.55))  # Reeds.
			elif roll < 0.2:
				SpriteBank.draw_disc(self, p, 2.0 + float(h % 2), Color(accent, 0.5))  # A pebble.
		_:
			if roll < 0.1:
				SpriteBank.draw_disc(self, p, 3.0, Color(trim, 0.5))  # An eggshell.
				SpriteBank.draw_disc(self, p + Vector2(4.0, 1.0), 2.0, Color(trim, 0.4))
			elif roll < 0.16:
				draw_rect(Rect2(p, Vector2(10.0, 2.0)), Color(trim, 0.35))  # A gnawed bone.
			elif roll < 0.26:
				SpriteBank.draw_disc(self, p, 14.0 + float(h % 8), Color(line, 0.55))  # Trampled earth.


## Draws every tar pool of the current zone inside `rect` (the director's pools).
func _draw_tar(rect: Rect2) -> void:
	var tar: Dictionary = _look.get("tar", {})
	if tar.is_empty():
		return
	var fern: Dictionary = FernBasinStage.FERN
	var size := float(fern["tar_cell"])
	var river := String(tar.get("style", "tar")) == "river"
	var tex := SpriteBank.texture(TAR_ART) if not river else null
	var c0 := Vector2i(floori(rect.position.x / size), floori(rect.position.y / size))
	var c1 := Vector2i(floori(rect.end.x / size), floori(rect.end.y / size))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var pool := FernBasinDirector.pool_in(Vector2i(cx, cy), tar, fern)
			if pool.z <= 0.0:
				continue
			var c := Vector2(pool.x, pool.y)
			var r := pool.z
			if tex != null:
				SpriteBank.apply_sharp(self)
				draw_texture_rect(tex, Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0), false)
				continue
			var deep := Color(0.20, 0.17, 0.11) if river else Palette.PRIMEVAL_INK  # The pool's body.
			var rim := Color(0.33, 0.28, 0.18) if river else Palette.PRIMEVAL_TAR  # Its edge.
			SpriteBank.draw_disc(self, c, r + 3.0, Color(rim, 0.9))
			SpriteBank.draw_disc(self, c, r, deep)
			SpriteBank.draw_disc(self, c + Vector2(-r * 0.3, -r * 0.25), r * 0.35, Color(rim, 0.6))  # A sheen.
			var hv := absi(hash(Vector2i(cx, cy)))
			for i in 3:
				var b := c + Vector2.from_angle(float((hv >> (i * 4)) % 16) / 16.0 * TAU) * r * 0.55
				SpriteBank.draw_disc(self, b, 2.0, Color(Palette.PRIMEVAL_OCHRE_DARK if river else Palette.PRIMEVAL_FERN_DARK, 0.7))  # A bubble or a leaf.
