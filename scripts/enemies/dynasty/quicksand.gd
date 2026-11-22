## Quicksand — the Black Land's GROUND (temporary Act XII, the Necropolis
## Dynasty; GDD §15.0 "The Black Land"; owner-approved proposal: "Dunes slow
## (quicksand patches through TerrainSlow)"; "Quicksand patches slow
## everyone"), owned by Game.dynasty. THE one path of every patch:
##   * FIXED patches: a pure integer hash of the world cells
##     (QUICKSAND cell px, chance per cell, radius_min..radius_max px; the
##     stage's arena layout seed salts it), so a stage's quicksand is the same
##     in every run; none within clear_radius of the arena centre (the start).
##     Only the cells within active_radius of a standing necromancer are live
##     (rebuilt every `refresh` s). Off a Dynasty stage there are none.
##   * ADDED patches: add_patch(at, radius, life) is THE public call for phase
##     2 (the Crocodile Warden rises from the quicksand; Sekhmet's dunes), at
##     most max_added at once.
##   * THE SLOW (every `tick` s): FenWater.wade(), the one "slows everyone"
##     helper: the necromancer(s) and the summons on the ground through
##     TerrainSlow (Brinewalker as on every ground slow; the summons' share x
##     DynastyRules.dune_slow_mult(), Dune Walkers' hook, exactly 1 today), the
##     living foes through their own Enemy.apply_slow() (the floating, the
##     structures, the bosses and the minibosses pass over).
## Drawn as textures on the ground (z -8: over the floor, under the obstacles
## and the bodies): `tiles/dynasty_quicksand` when it exists, else two sand
## discs (a dark pit and a pale rim). Nothing drawn headless.
## Determinism: pure hashes and game time; no RNG. Stats: quicksand_player,
## quicksand_summons, quicksand_enemies (slow ticks), quicksand_added.
class_name Quicksand
extends Node2D

## Sprite key of a quicksand patch (assets/sprites/tiles/dynasty_quicksand.png).
const SPRITE: String = "tiles/dynasty_quicksand"

## Owning run.
var game: Game
## True on a Dynasty stage: the fixed patches exist.
var enabled: bool = false
## The ground's numbers (QUICKSAND with the STAGE's "quicksand").
var cfg: Dictionary = {}
## Live patches near a necromancer: x, y, radius (px) (fixed and added).
var live: PackedVector3Array = PackedVector3Array()
## Added patches: x, y, radius (px).
var _added: PackedVector3Array = PackedVector3Array()
## Game time (s) each added patch sinks back (INF = never).
var _added_until: PackedFloat32Array = PackedFloat32Array()
## Fixed patch of a cell: Vector2i -> Vector3(x, y, r) (r 0 = none).
var _cell_cache: Dictionary = {}
## Salt of the fixed-patch hash (the stage's arena layout seed).
var _salt: int = 0
## Seconds until the next rebuild of `live`.
var _refresh_left: float = 0.0
## Seconds toward the next slow tick.
var _tick_acc: float = 0.0
## Most live patches at once this run.
var peak: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## The live set drawn last (a redraw only when it changes).
var _drawn: PackedVector3Array = PackedVector3Array()


## Builds the quicksand for `p_game` (DynastyRules adds it as its child);
## `p_enabled`: a Dynasty stage (the fixed patches).
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "Quicksand"
	z_index = -8  # Over the floor (-10), under the obstacles (-6) and the bodies.
	z_as_relative = false
	enabled = p_enabled
	cfg = DynastyRulesData.QUICKSAND.duplicate()
	var over: Dictionary = p_game.stage_def.get("quicksand", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	var arena: Dictionary = p_game.stage_def.get("arena", {})
	_salt = int(cfg["seed"]) if int(cfg["seed"]) != 0 else int(arena.get("layout_seed", 1907))
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE public call for phase 2: a quicksand patch of `radius` px at `at` for
## `life` s (INF = until the run ends). False when max_added are open.
func add_patch(at: Vector2, radius: float, life: float) -> bool:
	if _added.size() >= int(cfg["max_added"]):
		game.stat_add("quicksand_refused", 1.0)
		return false
	_added.append(Vector3(at.x, at.y, radius))
	_added_until.append(game.elapsed + life)
	game.stat_add("quicksand_added", 1.0)
	_refresh_left = 0.0  # Live at the next step.
	return true


## True when a body of radius `r` at `p` stands in a live patch (its centre
## inside the patch, less a quarter of its body).
func in_sand(p: Vector2, r: float) -> bool:
	for v in live:
		if p.distance_to(Vector2(v.x, v.y)) <= v.z - r * 0.25:
			return true
	return false


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (DynastyRules.step()): the added patches' life, the live
## set's rebuild, the slow ticks.
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
	if live.is_empty():
		return
	_tick_acc += delta
	var tick := float(cfg["tick"])
	if _tick_acc >= tick:
		_tick_acc -= tick
		var slow := float(cfg["slow"])
		FenWater.wade(game, in_sand, slow, slow * game.dynasty.dune_slow_mult(), float(cfg["enemy_slow"]),
				float(cfg["linger"]), "quicksand")


## Rebuilds `live`: the fixed patches of the cells near every standing
## necromancer, then the added patches near one.
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


## The fixed patch of cell `c` (cached): Vector3(x, y, radius), radius 0 = none.
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


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Every live patch: its art, else a dark sand pit inside a pale rim.
func _draw() -> void:
	var tex := SpriteBank.texture(SPRITE)
	for v in live:
		var c := Vector2(v.x, v.y)
		var r := v.z
		var rect := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
		if tex != null:
			draw_texture_rect(tex, rect, false)
			continue
		draw_texture_rect(SpriteBank.disc(), rect.grow(3.0), false, Color(Palette.DYN_SAND_LIGHT, 0.3))
		draw_texture_rect(SpriteBank.disc(), rect, false, Color(Palette.DYN_SAND_DARK, 0.7))
		draw_texture_rect(SpriteBank.disc(), rect.grow(-r * 0.3), false, Color(Palette.DYN_SAND_DARK.darkened(0.25), 0.45))
