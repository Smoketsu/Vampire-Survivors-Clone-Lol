## Minefields — THE MINEFIELDS of Fort Kessler (Act VIII, Stage 23; GDD §15.0
## "Fort Kessler (Act VIII phase 2)"; owner-approved proposal: "Minefields:
## blinking mines that blow up under anyone, both armies; luring the riflemen
## over them is the counterplay, and the ring has to flow around them (one
## ground path, like Act VI's pits)"), owned by FortKesslerDirector as
## `mines` (a child node, drawn on the ground). THE one ground path of the mines:
##   * WHERE: in the zones the config lists (FortKesslerStage.FORT_KESSLER
##     "minefields" "zones": the Minefield), a pure integer hash of the city
##     blocks lays them out, the same in every run: an OPEN LOT whose hash
##     passes lot_chance holds a grid of lot_cols x lot_rows mines, and a STREET
##     SEGMENT between two crossings whose hash passes street_chance holds a
##     zig-zag row of street_mines mines across its roadway (never in a
##     crossing). Only the mines within active_radius px of a necromancer are
##     live (rebuilt every `refresh` s); none within start_clear px of where a
##     necromancer stood when the zone began; a mine that went off never comes
##     back (`_spent`). Off a blocks stage there are none.
##   * ARMING: when the zone begins, its mines blink for arm_time s before they
##     can go off (the telegraph); they blink slowly (blink_hz, at most 1 Hz:
##     the act's light rule, a soft fade).
##   * THE TRIGGER (every check_every s): anyone with feet within trigger px of
##     an armed mine sets it off (blows up under anyone, both armies): an enemy
##     (never a civilian, a flier or a body that phases), a summon (not
##     airborne, not flying) or a necromancer. The mine burns its fuse for
##     `fuse` s (a bright ring), then BLOWS: CityRules.blast(at, radius, damage
##     x the enemies' damage scaling, MINE_SOURCE, both = true): every summon,
##     necromancer and enemy in it (never a civilian, a boss or a structure).
##   * THE AVOID CHECK the horde reads: avoid_point() moves a Bone Ring post
##     out of every live mine by avoid_margin px (StanceFormations._place(),
##     beside the Hell Pits' check: terrain, not a summon rule).
##   * The autotest bot steps off them (danger_push(), read through
##     CityRules.danger_push()).
## Determinism: the layout is a pure 64-bit integer hash of the lot or street
## segment and the stage's seed; the trigger walks the live mines in index
## order; game time only. Stats: mines_live_peak, mines_triggered,
## mines_triggered_by_<enemy|summon|you>, mines_blown, mine_kills_enemies.
class_name Minefields
extends Node2D

## Owning run.
var game: Game
## The minefields' numbers (FortKesslerStage.FORT_KESSLER "minefields").
var cfg: Dictionary = {}
## The stage's zones (STAGE "zones": [{id, name, start}]).
var zones: Array = []
## Salt of the layout hash (the stage's arena layout seed).
var _salt: int = 0
## Index of the current zone (-1 before the first step).
var zone: int = -1
## Game time (s) the current zone began (its mines arm arm_time s later).
var _zone_since: float = 0.0
## Where each necromancer stood when the zone began (no mine within start_clear).
var _zone_starts: PackedVector2Array = PackedVector2Array()
## True while the current zone has mines.
var _on: bool = false
## Centre (world px) of each live mine.
var _pos: PackedVector2Array = PackedVector2Array()
## Layout key of each live mine (Vector3i: lot / street segment and its slot).
var _keys: Array[Vector3i] = []
## Game time (s) each live mine was set off (INF = not set off).
var _fuse_at: PackedFloat32Array = PackedFloat32Array()
## Layout keys of the mines that went off (never placed again this run).
var _spent: Dictionary = {}
## Seconds until the next rebuild of the live mines.
var _refresh_left: float = 0.0
## Seconds toward the next trigger check.
var _check_acc: float = 0.0
## Mines that went off this run.
var blown: int = 0
## Most mines live at once this run.
var live_peak: int = 0
## Grid query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed something.
var _drawn: bool = false


## Builds the minefields for `p_game` from `p_cfg` (the director adds it).
func _init(p_game: Game, p_cfg: Dictionary) -> void:
	game = p_game
	cfg = p_cfg
	name = "Minefields"
	z_index = -7  # Over the floor and the pits' layer, under the obstacles (-6) and the bodies.
	z_as_relative = false
	zones = p_game.stage_def.get("zones", [])
	var arena: Dictionary = p_game.stage_def.get("arena", {})
	_salt = int(cfg.get("seed", arena.get("layout_seed", 2323)))
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE avoid check the horde reads (StanceFormations._place()): world point
## `p` (a body of radius `r`) moved out of every live mine by avoid_margin px.
## Unchanged when no mine is near (and always off the Minefield's zones).
func avoid_point(p: Vector2, r: float) -> Vector2:
	if _pos.is_empty():
		return p
	var reach := float(cfg["avoid_margin"]) + r
	for _pass in 2:
		var moved := false
		for i in _pos.size():
			var off := p - _pos[i]
			var dist := off.length()
			if dist < reach:
				p = _pos[i] + (off / dist if dist > 0.01 else Vector2.RIGHT) * reach
				moved = true
		if not moved:
			break
	return p


## True when a live mine lies within `r` px of world point `p` (reports, kits).
func mine_at(p: Vector2, r: float) -> bool:
	for i in _pos.size():
		if p.distance_to(_pos[i]) <= r:
			return true
	return false


## Mines live now (reports).
func live_count() -> int:
	return _pos.size()


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (FortKesslerDirector.step()): the zone, the live mines,
## the fuses, the trigger.
func step(delta: float) -> void:
	var now := game.elapsed
	var z := _zone_at(now)
	if z != zone:
		zone = z
		_zone_since = now
		_zone_starts.clear()
		for pl in game.all_players:
			_zone_starts.append(pl.position)
		_on = (cfg["zones"] as Array).has(z) and game.arena.city_blocks != null
		_refresh_left = 0.0
		if not _on:
			_pos.clear()
			_keys.clear()
			_fuse_at.clear()
	if not _on:
		if _drawn and _draws:
			queue_redraw()
			_drawn = false
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = float(cfg["refresh"])
		_rebuild()
	var i := 0
	while i < _pos.size():
		if now >= _fuse_at[i] + float(cfg["fuse"]):
			_blow(i)
			continue
		i += 1
	_check_acc += delta
	if _check_acc >= float(cfg["check_every"]) and now >= _zone_since + float(cfg["arm_time"]):
		_check_acc = 0.0
		_trigger()
	if _draws:
		queue_redraw()
		_drawn = true


## Index of the zone at game time `t` (the last STAGE "zones" row started by then).
func _zone_at(t: float) -> int:
	var z := 0
	for k in zones.size():
		if t >= float((zones[k] as Dictionary).get("start", 0.0)):
			z = k
	return z


## Rebuilds the live mines around every necromancer (a fuse already burning
## is kept: its mine stays live until it blows).
func _rebuild() -> void:
	var keep_pos := PackedVector2Array()
	var keep_keys: Array[Vector3i] = []
	var keep_fuse := PackedFloat32Array()
	var seen := {}  # Keys already live (Vector3i -> true).
	for i in _pos.size():
		if _fuse_at[i] < INF:
			keep_pos.append(_pos[i])
			keep_keys.append(_keys[i])
			keep_fuse.append(_fuse_at[i])
			seen[_keys[i]] = true
	_pos = keep_pos
	_keys = keep_keys
	_fuse_at = keep_fuse
	var cb := game.arena.city_blocks
	var reach := float(cfg["active_radius"])
	for pl in game.all_players:
		var rect := Rect2(pl.position - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
		var r := cb.lot_range(rect)
		for iy in range(r[0].y, r[1].y + 1):
			for ix in range(r[0].x, r[1].x + 1):
				_lot_mines(cb, Vector2i(ix, iy), seen, pl.position, reach)
		var hk0 := cb.h_street(rect.position)
		var hk1 := cb.h_street(rect.end)
		var vk0 := cb.v_street(rect.position)
		var vk1 := cb.v_street(rect.end)
		for k in range(hk0, hk1 + 1):
			for i in range(vk0 - 1, vk1 + 1):
				_street_mines(cb, 0, i, k, seen, pl.position, reach)
		for k in range(vk0, vk1 + 1):
			for i in range(hk0 - 1, hk1 + 1):
				_street_mines(cb, 1, i, k, seen, pl.position, reach)
	live_peak = maxi(live_peak, _pos.size())
	game.stats["mines_live_peak"] = float(live_peak)


## The mines of open lot `lot` (a grid inside its rect), when its hash passes.
func _lot_mines(cb: CityBlocks, lot: Vector2i, seen: Dictionary, around: Vector2, reach: float) -> void:
	var h := _mix(lot.x, lot.y, 1)
	if float(h & 0xFFFF) / 65536.0 >= float(cfg["lot_chance"]):
		return
	if cb.building_of(lot, false) != null:
		return  # A building stands there: no minefield.
	var b := cb.building_rect(lot).grow(-float(cfg["lot_inset"]))
	var cols := int(cfg["lot_cols"])
	var rows := int(cfg["lot_rows"])
	for ry in rows:
		for rx in cols:
			var key := Vector3i(lot.x, lot.y, 100 + ry * cols + rx)
			var stagger := 0.5 * float(ry % 2)  # Every other row offset by half a step.
			var p := b.position + Vector2((float(rx) + 0.5 + stagger * 0.5) / float(cols) * b.size.x, (float(ry) + 0.5) / float(rows) * b.size.y)
			_add_mine(key, p, seen, around, reach)


## The mines of street segment `i` of street `k` on `axis` (0: horizontal
## street k between vertical streets i and i + 1; 1: vertical street k between
## horizontal streets i and i + 1), when its hash passes: a zig-zag row across
## the roadway, clear of the crossings.
func _street_mines(cb: CityBlocks, axis: int, i: int, k: int, seen: Dictionary, around: Vector2, reach: float) -> void:
	var h := _mix(i, k, 2 + axis)
	if float(h & 0xFFFF) / 65536.0 >= float(cfg["street_chance"]):
		return
	var a0: float  # Start of the segment along the street (px, past the crossing).
	var a1: float  # Its end.
	var c: float  # The street's centre line (the fixed coordinate).
	if axis == 0:
		a0 = cb.v_street_x(i) + cb.street * 0.5 + float(cfg["crossing_clear"])
		a1 = cb.v_street_x(i + 1) - cb.street * 0.5 - float(cfg["crossing_clear"])
		c = cb.h_street_y(k)
	else:
		a0 = cb.h_street_y(i) + cb.street * 0.5 + float(cfg["crossing_clear"])
		a1 = cb.h_street_y(i + 1) - cb.street * 0.5 - float(cfg["crossing_clear"])
		c = cb.v_street_x(k)
	var n := int(cfg["street_mines"])
	var off := float(cfg["street_offset"])
	for m in n:
		var along := lerpf(a0, a1, (float(m) + 0.5) / float(n))
		var across := c + off * (1.0 if (m % 2) == 0 else -1.0) * (1.0 if ((h >> 20) & 1) == 0 else -1.0)
		var p := Vector2(along, across) if axis == 0 else Vector2(across, along)
		_add_mine(Vector3i(i, k, (200 + 100 * axis) + m), p, seen, around, reach)


## Adds mine `key` at `p` when it is near `around`, not spent, not already
## live, and clear of where a necromancer stood when the zone began.
func _add_mine(key: Vector3i, p: Vector2, seen: Dictionary, around: Vector2, reach: float) -> void:
	if seen.has(key) or _spent.has(key) or p.distance_to(around) > reach:
		return
	var clear := float(cfg["start_clear"])
	for s in _zone_starts:
		if p.distance_to(s) < clear:
			return
	seen[key] = true
	_pos.append(p)
	_keys.append(key)
	_fuse_at.append(INF)


## THE TRIGGER: every armed mine with a foot on it (anyone's) starts its fuse.
func _trigger() -> void:
	var now := game.elapsed
	var tr := float(cfg["trigger"])
	for i in _pos.size():
		if _fuse_at[i] < INF:
			continue
		var at := _pos[i]
		var who := ""  # What set it off ("" = nothing).
		for pl in game.all_players:
			if not pl.dead and pl.position.distance_to(at) <= tr + pl.radius * 0.5:
				who = "you"
				break
		if who == "":
			game.enemy_grid.query(at, tr + CityBlockData.MAX_BODY_RADIUS, _tmp)
			for e: Enemy in _tmp:
				if e.active and not e.civilian and not e.flies and not e.phases_obstacles and not e.is_structure \
						and e.position.distance_to(at) <= tr + e.radius * 0.5:
					who = "enemy"
					break
		if who == "":
			game.ally_grid.query(at, tr + UnitData.MAX_BLOCK_RADIUS, _tmp)
			for u: SummonedUnit in _tmp:
				if u.active and not u.airborne and not u.flies and u.state != SummonedUnit.State.DEAD \
						and u.position.distance_to(at) <= tr + u.radius * 0.5:
					who = "summon"
					break
		if who != "":
			_fuse_at[i] = now
			game.stat_add("mines_triggered", 1.0)
			game.stat_add("mines_triggered_by_" + who, 1.0)


## Mine `i` blows (both armies; never civilians, bosses or structures).
func _blow(i: int) -> void:
	var at := _pos[i]
	_spent[_keys[i]] = true
	_pos.remove_at(i)
	_keys.remove_at(i)
	_fuse_at.remove_at(i)
	blown += 1
	var dmg := float(cfg["damage"]) * game.enemies.damage_mult
	var r := float(cfg["radius"])
	var before := game.kills  # Kills so far (the blast's own kills counted below).
	game.city.blast(at, r, dmg, FortKesslerStage.MINE_SOURCE, true)
	game.stat_add("mine_kills_enemies", float(game.kills - before))
	game.stat_add("mines_blown", 1.0)
	game.effects.impact(at, r, Palette.CITY_HERO_ORANGE, "")
	game.city.play_sound("mine_blast", at, 0.1)


## A 64-bit integer mix (splitmix64 finaliser, as HellPits') of a lot or street
## segment and the stage's salt: the same bits on every platform.
func _mix(a: int, b: int, c: int) -> int:
	var x := a * 0x9E3779B1 + b * 0x85EBCA77 + c * 0xC2B2AE3D + _salt * 0x27D4EB2F
	x = (x ^ (x >> 30)) * -4658895280553007687  # 0xBF58476D1CE4E5B9 as a signed 64-bit int.
	x = (x ^ (x >> 27)) * -7723592293110705685  # 0x94D049BB133111EB as a signed 64-bit int.
	x = x ^ (x >> 31)
	return x & 0x7FFFFFFFFFFFFFFF


# =====================================================================================
# Autotest and drawing
# =====================================================================================

## Autopilot hint (the autotest bot, through CityRules.danger_push()): a push
## off every live mine within danger_reach px of its blast, stronger nearer
## (and hard off a burning fuse).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var reach := float(cfg["danger_reach"])
	for i in _pos.size():
		var full := reach + (float(cfg["radius"]) if _fuse_at[i] < INF else 0.0)
		var off := p - _pos[i]
		var dist := off.length()
		if dist < full:
			push += (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / full) * 2.5
	return push


## Draws every live mine in view: the mine (its sprite, else a code disc) and a
## slow soft blink (blink_hz, at most 1 Hz; while arming, every mine blinks in
## step); a burning fuse shows a steady bright ring of its blast. Textures only.
func _draw() -> void:
	var now := game.elapsed
	var view := Rect2(game.player.position - Vector2(1400, 900), Vector2(2800, 1800))  # Generous: co-op and zoom.
	var hz := minf(float(cfg["blink_hz"]), 1.0)
	var arming := now < _zone_since + float(cfg["arm_time"])
	for i in _pos.size():
		var at := _pos[i]
		if not view.has_point(at):
			continue
		var phase := 0.0 if arming else float((_keys[i].x * 7 + _keys[i].y * 13 + _keys[i].z) % 10) * 0.1  # Mines blink out of step once armed.
		var k := 0.5 + 0.5 * sin(TAU * (hz * now + phase))  # 0..1, a soft fade.
		if not SpriteBank.draw(self, FortKesslerStage.MINE_SPRITE, at, false):
			SpriteBank.draw_disc(self, at, 6.0, Color(Palette.CITY_OLIVE_DARK, 1.0))
			SpriteBank.draw_disc(self, at, 4.0, Color(Palette.CITY_OLIVE, 1.0))
		SpriteBank.draw_disc(self, at + Vector2(0.0, -1.0), 2.5 + 3.0 * k, Color(Palette.CITY_SIREN_RED, 0.25 + 0.55 * k))
		if _fuse_at[i] < INF:
			CityGlyphs.draw_shell(self, at, float(cfg["radius"]), clampf((now - _fuse_at[i]) / maxf(float(cfg["fuse"]), 0.01), 0.0, 1.0), Palette.CITY_SIREN_RED)
