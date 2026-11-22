## CloudShade — the CLOUD BANKS of the Celestial Host's stages (temporary Act
## XIII; GDD §15.0 "Hallowed Light"; proposal: "The shadows of clouds and
## pillars are safe ground"), owned by HostRules' HallowedLight as `clouds`:
## fixed cloud shadows on the ground, one per CLOUDS "cell" at most (chance),
## each placed and sized by a pure hash of its cell and the stage's layout
## seed (the Dynasty's quicksand patches' shape), none within clear_radius of
## the start. in_shade() is the one test the Light asks; add_shade() lets
## phase 2 lay its own (the Silver Stair's low cloud banks, a boss's wings).
## Only the cells within active_radius of a standing necromancer are live
## (rebuilt every refresh s). Off a Host stage it lays no fixed clouds.
## Drawn: a dark cerulean shadow with a pale rim (disc textures), over the
## floor and under the obstacles and bodies, z -8. Determinism: pure hashes
## and game time only.
class_name CloudShade
extends Node2D

## Owning run.
var game: Game
## True on a Host stage (the fixed clouds).
var enabled: bool = false
## The clouds' numbers (HostRulesData.CLOUDS, the stage's "clouds" over it).
var cfg: Dictionary = {}
## Live shadows near a necromancer: Vector3(x, y, radius px).
var live: PackedVector3Array = PackedVector3Array()
## Shadows phase 2 laid (add_shade()): Vector3(x, y, radius px).
var _added: PackedVector3Array = PackedVector3Array()
## Game time (s) each added shadow ends (INF = never).
var _added_until: PackedFloat32Array = PackedFloat32Array()
## Cell -> its fixed shadow (Vector3, radius 0 = none), filled on first use.
var _cell_cache: Dictionary = {}
## The hash salt (CLOUDS "seed", else the arena's layout seed).
var _salt: int = 0
## Seconds until the live set is rebuilt.
var _refresh_left: float = 0.0
## Most live shadows at once this run (the report).
var peak: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## The live set drawn last (a redraw only when it changes).
var _drawn: PackedVector3Array = PackedVector3Array()


## Builds the clouds for `p_game`; `p_enabled`: a Host stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "CloudShade"
	z_index = -8  # Over the floor (-10), under the obstacles (-6) and the bodies.
	z_as_relative = false
	enabled = p_enabled
	cfg = HostRulesData.CLOUDS.duplicate()
	var over: Dictionary = p_game.stage_def.get("clouds", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	var arena: Dictionary = p_game.stage_def.get("arena", {})
	_salt = int(cfg["seed"]) if int(cfg["seed"]) != 0 else int(arena.get("layout_seed", 1313))
	_draws = DisplayServer.get_name() != "headless"


## THE public call for phase 2: a shadow of `radius` px at `at` for `life` s
## (INF = until the run ends).
func add_shade(at: Vector2, radius: float, life: float) -> void:
	_added.append(Vector3(at.x, at.y, radius))
	_added_until.append(game.elapsed + life)
	_refresh_left = 0.0  # Live at the next step.


## THE ONE TEST: true when a body of radius `r` at `p` stands in a live shadow
## (its centre inside the shadow, less a quarter of its body).
func in_shade(p: Vector2, r: float) -> bool:
	for v in live:
		if p.distance_to(Vector2(v.x, v.y)) <= v.z - r * 0.25:
			return true
	return false


## Per tick (HallowedLight.step()): the added shadows' life, the live set.
func step(delta: float) -> void:
	var now := game.elapsed
	var i := _added.size() - 1
	while i >= 0:
		if now >= _added_until[i]:
			_added.remove_at(i)
			_added_until.remove_at(i)
			_refresh_left = 0.0
		i -= 1
	if not enabled and _added.is_empty() and live.is_empty():
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = float(cfg["refresh"])
		_rebuild()


## Rebuilds `live`: the fixed shadows of the cells near every standing
## necromancer, then the added ones near one.
func _rebuild() -> void:
	live.clear()
	var reach := float(cfg["active_radius"])
	var cell := float(cfg["cell"])
	var seen := {}  # Cells already added (two necromancers near one cell).
	for pl in game.all_players:
		if pl.dead:
			continue
		if enabled:
			var c0 := Vector2i(floori((pl.position.x - reach) / cell), floori((pl.position.y - reach) / cell))
			var c1 := Vector2i(floori((pl.position.x + reach) / cell), floori((pl.position.y + reach) / cell))
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var key := Vector2i(cx, cy)
					if seen.has(key):
						continue
					seen[key] = true
					var v := _fixed(key)
					if v.z > 0.0 and pl.position.distance_to(Vector2(v.x, v.y)) <= reach:
						live.append(v)
		for v in _added:
			if pl.position.distance_to(Vector2(v.x, v.y)) <= reach and not live.has(v):
				live.append(v)
	peak = maxi(peak, live.size())
	if _draws and live != _drawn:
		_drawn = live.duplicate()
		queue_redraw()


## The fixed shadow of cell `c` (cached): Vector3(x, y, radius), radius 0 = none.
func _fixed(c: Vector2i) -> Vector3:
	if _cell_cache.has(c):
		return _cell_cache[c]
	var h := absi(hash(Vector3i(c.x, c.y, _salt)))  # The cell's pure hash.
	var out := Vector3.ZERO
	if float(h % 1000) / 1000.0 < float(cfg["chance"]):
		var cell := float(cfg["cell"])
		var rmin := float(cfg["radius_min"])
		var rmax := float(cfg["radius_max"])
		var r := rmin + (rmax - rmin) * float((h >> 10) % 100) / 100.0
		var span := maxf(cell - 2.0 * r, 1.0)
		var x := float(c.x) * cell + r + span * float((h >> 4) % 97) / 97.0
		var y := float(c.y) * cell + r + span * float((h >> 13) % 89) / 89.0
		if Vector2(x, y).length() > float(cfg["clear_radius"]) + r:
			out = Vector3(x, y, r)
	_cell_cache[c] = out
	return out


## Every live shadow: its art (tiles/host_cloud_shadow), else a dark cerulean
## shadow inside a pale rim (disc textures).
func _draw() -> void:
	var tex := SpriteBank.texture("tiles/host_cloud_shadow")
	for v in live:
		var c := Vector2(v.x, v.y)
		var r := v.z
		var rect := Rect2(c - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6))
		if tex != null:
			draw_texture_rect(tex, rect, false)
			continue
		draw_texture_rect(SpriteBank.disc(), rect.grow(4.0), false, Color(Palette.HOST_CLOUD, 0.12))
		draw_texture_rect(SpriteBank.disc(), rect, false, Color(Palette.HOST_SHADE, 0.55))
		draw_texture_rect(SpriteBank.disc(), rect.grow(-r * 0.3), false, Color(Palette.HOST_SHADE, 0.3))
