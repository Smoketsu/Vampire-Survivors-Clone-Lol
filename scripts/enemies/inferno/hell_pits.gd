## HellPits — THE HELL PITS, the first of the Inferno's shared rules (Act VI;
## GDD §15.0 "Hell Pits"; owner-approved proposal: "Burning pools on the ground
## that damage anyone standing in them, demons excepted. Some are fixed, some
## open on a telegraph (a glowing rim for 1.5 s) and close again ... the army's
## ring has to flow around them. One ground path, like the furnace channels of
## Act III"), owned by Game.inferno. THE one path of every pit:
##   * FIXED pits: a seeded hash of the world cells (PITS fixed_cell; the
##     stage's arena layout seed salts it), one table per zone of the stage
##     (STAGE "zones" start times; PITS fixed_chance per zone), so a stage's
##     fixed pits are the same in every run. Only the cells within
##     active_radius of a necromancer are live (rebuilt every `refresh` s). When
##     a new zone begins, the old zone's pits cool and the new ones glow for
##     `telegraph` s before they burn.
##   * TELEGRAPHED pits: every open_every s (shorter each minute, and in the
##     Last Judgment its own faster clock) a pit opens near each standing
##     necromancer: a glowing rim for `telegraph` s, then it burns for life_min
##     .. life_max s, then cools for close_time s and is gone.
##   * open_pit(at, radius, life, opts): THE public call for phase 2 (the Lilim
##     Witch's pits under the ring, Moloch cracking the arena, the Brimstone
##     spell's short pits).
##   * THE BURN (every `tick` s): every burning pit damages what stands in it
##     through CombatResolver: the necromancer (damage_player()), the summons
##     (damage_unit(), x Salt Circle; airborne and flying summons pass over),
##     and every enemy burns_enemy() lets burn (damage_enemy(); the damned at
##     damned_mult x). A body in two pits burns once.
##   * THE AVOID CHECK the horde reads: avoid_point() moves a ring post out of
##     every pit (StanceFormations._place(), the one caller): the Bone Ring
##     flows around the pits as it flows around obstacles. Not a summon rule:
##     it only moves the posts.
##   * SALT CIRCLE hook (the future Act VI counter-passive; not built in phase
##     1): salt_circle_mult() cuts the burn a summon takes (exactly 1 while the
##     passive does not exist).
## A stage's STAGE "pits" dictionary overrides any InfernoRulesData.PITS key
## ({} = the defaults). Drawn as textures on the ground (z -8: over the floor,
## under the obstacles and the bodies); nothing is drawn headless.
## Determinism: the fixed pits are a pure integer hash of the cell, the zone and
## the stage's seed; the telegraphed pits use the seeded gameplay RNG, only on
## an Act VI stage. Stats: pits_opened, pits_opened_<tag>, pit_burns,
## pit_dmg_you, pit_dmg_summons, pit_dmg_enemies, pit_kills,
## pit_damned_burned, pits_refused, pits_fixed_live_peak.
class_name HellPits
extends Node2D

## Owning run.
var game: Game
## The pits' numbers (InfernoRulesData.PITS, then the stage's "pits" overrides).
var cfg: Dictionary = {}
## The stage's zones (STAGE "zones": [{id, name, start}]; [] = one zone).
var zones: Array = []
## Salt of the fixed-pit hash (the stage's arena layout seed).
var _salt: int = 0

# --- Telegraphed and opened pits (packed arrays; indices [0, count)) ----------
## Live telegraphed / opened pits.
var count: int = 0
## Centre (world px) of each pit.
var _pos: PackedVector2Array = PackedVector2Array()
## Radius (px) of each pit.
var _rad: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each pit appeared (its rim starts glowing).
var _born: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each pit starts burning (born + its telegraph).
var _burn_at: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each pit stops burning and starts to cool (INF = never).
var _close_at: PackedFloat32Array = PackedFloat32Array()
## x the burn of each pit (open_pit() opts "dps_mult").
var _mult: PackedFloat32Array = PackedFloat32Array()
## Stats tag of each pit ("timed", "reckoning", or open_pit()'s opts "tag").
var _tag: PackedStringArray = PackedStringArray()
## 1 for a timed pit (counted against max_temp), 0 for an open_pit() one.
var _timed: PackedByteArray = PackedByteArray()

# --- Fixed pits ------------------------------------------------------------------
## Live fixed pits of the current zone near a necromancer: x, y, radius (px).
var fixed: PackedVector3Array = PackedVector3Array()
## The previous zone's fixed pits while they cool (drawn only).
var _cooling: PackedVector3Array = PackedVector3Array()
## Index of the current zone (its fixed-pit table).
var zone: int = 0
## Game time (s) the current zone began (its fixed pits glow until + telegraph).
var _zone_since: float = 0.0
## Fixed pit of a cell: Vector3i(cx, cy, zone) -> Vector3(x, y, r) (r 0 = none).
var _cell_cache: Dictionary = {}
## Seconds until the next rebuild of `fixed`.
var _refresh_left: float = 0.0
## Seconds toward the next burn tick.
var _tick_acc: float = 0.0
## Game time (s) of the next telegraphed pit.
var _next_open: float = 0.0
## Most fixed pits live at once this run.
var fixed_peak: int = 0
## Telegraphed + opened pits this run.
var opened: int = 0
## Enemies, summons already burned this tick (scratch: a body in two pits burns once).
var _burned: Dictionary = {}
## Grid query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed something.
var _drawn: bool = false


## Builds the pits for `p_game` (InfernoRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "HellPits"
	z_index = -8  # Over the floor (-10), under the obstacles (-6) and the bodies.
	z_as_relative = false
	cfg = InfernoRulesData.PITS.duplicate()
	var over: Dictionary = p_game.stage_def.get("pits", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	zones = p_game.stage_def.get("zones", [])
	var arena: Dictionary = p_game.stage_def.get("arena", {})
	_salt = int(cfg.get("seed", arena.get("layout_seed", 1666)))
	_next_open = float(cfg["start_at"])
	var cap := int(cfg["max_pits"])
	_pos.resize(cap)
	_rad.resize(cap)
	_born.resize(cap)
	_burn_at.resize(cap)
	_close_at.resize(cap)
	_mult.resize(cap)
	_tag.resize(cap)
	_timed.resize(cap)
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE public call (phase 2: the Lilim Witch, Moloch, the Brimstone spell): opens
## a pit of `radius` px at `at` (world px) that glows for opts "telegraph" s
## (default PITS telegraph), then burns for `life` s (INF = until the run ends),
## then cools. opts (all optional): "telegraph" (s), "tag" (stats, default
## "opened"), "dps_mult" (x its burn), "silent" (bool: no sound). Returns false
## when max_pits are open.
func open_pit(at: Vector2, radius: float, life: float, opts: Dictionary = {}) -> bool:
	return _add(at, radius, float(opts.get("telegraph", cfg["telegraph"])), life, float(opts.get("dps_mult", 1.0)),
			String(opts.get("tag", "opened")), false, not bool(opts.get("silent", false)))


## True when world point `p` (a body of radius `r`) stands in a burning pit.
func burning_at(p: Vector2, r: float = 0.0) -> bool:
	var now := game.elapsed
	for i in count:
		if now >= _burn_at[i] and now < _close_at[i] and p.distance_to(_pos[i]) < _rad[i] + r:
			return true
	if _fixed_burning():
		for f in fixed:
			if p.distance_to(Vector2(f.x, f.y)) < f.z + r:
				return true
	return false


## THE avoid check the horde reads (StanceFormations._place()): world point `p`
## (a body of radius `r`) moved out of every pit, glowing or burning, by
## avoid_margin px. Unchanged when it stands in none.
func avoid_point(p: Vector2, r: float) -> Vector2:
	var margin := float(cfg["avoid_margin"])
	var now := game.elapsed
	for _pass in 2:
		var moved := false
		for i in count:
			if now < _close_at[i]:
				var q := _out_of(p, _pos[i], _rad[i] + r + margin)
				moved = moved or q != p
				p = q
		for f in fixed:
			var q := _out_of(p, Vector2(f.x, f.y), f.z + r + margin)
			moved = moved or q != p
			p = q
		if not moved:
			break
	return p


## SALT CIRCLE (the future Act VI counter-passive; the one read): the share of a
## pit's burn summon `u` still takes, 1 - PassiveData row SALT_CIRCLE's value of
## the player who owns it (co-op: its army's slot). Exactly 1 while the passive
## does not exist.
func salt_circle_mult(u: SummonedUnit) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return clampf(1.0 - ab.passive_value(InfernoRulesData.SALT_CIRCLE, InfernoRulesData.SALT_CIRCLE_KEY), 0.0, 1.0)


## True when the pits burn enemy `e`: never a boss, a miniboss, a structure, an
## untargetable body, a DEMON or a FLIER (their InfernoKit rows); every other
## enemy burns (the damned, the living, any kind forced onto the stage).
static func burns_enemy(e: Enemy) -> bool:
	if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.untargetable:
		return false
	if e.kit is InfernoKit:
		var k := e.kit as InfernoKit
		return not k.is_demon() and not k.is_flier()
	return not e.floating  # Any other hovering body passes over the fire.


## Pits glowing or burning now (timed / opened + live fixed), for reports.
func live_count() -> int:
	return count + fixed.size()


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (InfernoRules.step()): the zone's fixed pits, new telegraphed
## pits, closing pits, then the burn.
func step(delta: float) -> void:
	var now := game.elapsed
	var z := _zone_at(now)
	if z != zone:
		_cooling = fixed.duplicate()
		zone = z
		_zone_since = now
		_refresh_left = 0.0
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = float(cfg["refresh"])
		_rebuild_fixed()
	if not _cooling.is_empty() and now >= _zone_since + float(cfg["close_time"]):
		_cooling.clear()
	if now >= _next_open:
		_open_timed()
		_next_open = now + _open_interval()
	var i := 0
	while i < count:
		if now >= _close_at[i] + float(cfg["close_time"]):
			_remove(i)
			continue
		i += 1
	_tick_acc += delta
	var tick := float(cfg["tick"])
	if _tick_acc >= tick:
		_tick_acc -= tick
		_burn(tick)
	if _draws:
		var busy := count > 0 or not fixed.is_empty() or not _cooling.is_empty()
		if busy or _drawn:
			queue_redraw()
		_drawn = busy


## Index of the zone at game time `t` (the last STAGE "zones" row started by then).
func _zone_at(t: float) -> int:
	var z := 0
	for k in zones.size():
		if t >= float((zones[k] as Dictionary).get("start", 0.0)):
			z = k
	return z


## Seconds until the next telegraphed pit: open_every, shorter each minute, down
## to open_every_min; in the Last Judgment its own faster clock.
func _open_interval() -> float:
	if game.inferno != null and game.inferno.judgment.running():
		return game.inferno.judgment.pit_interval()
	var mins := game.elapsed / 60.0
	return maxf(float(cfg["open_every_min"]), float(cfg["open_every"]) - float(cfg["open_every_step"]) * mins)


## Opens one telegraphed pit near each standing necromancer.
func _open_timed() -> void:
	var tag := "reckoning" if game.inferno != null and game.inferno.judgment.running() else "timed"
	for pl in game.all_players:
		if pl.dead:
			continue
		var timed := 0  # Timed pits open now.
		for i in count:
			timed += int(_timed[i])
		if timed >= int(cfg["max_temp"]):
			game.stat_add("pits_refused", 1.0)
			return
		var a := randf() * TAU
		var dist := randf_range(float(cfg["dist_min"]), float(cfg["dist_max"]))
		var r := randf_range(float(cfg["radius_min"]), float(cfg["radius_max"]))
		var life := randf_range(float(cfg["life_min"]), float(cfg["life_max"]))
		var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, r * 0.5)
		_add(at, r, float(cfg["telegraph"]), life, 1.0, tag, true, true)


## Adds a pit (see open_pit()); `timed` counts it against max_temp.
func _add(at: Vector2, radius: float, telegraph: float, life: float, mult: float, tag: String, timed: bool, sound: bool) -> bool:
	if count >= _pos.size():
		game.stat_add("pits_refused", 1.0)
		return false
	var i := count
	count += 1
	var now := game.elapsed
	_pos[i] = at
	_rad[i] = radius
	_born[i] = now
	_burn_at[i] = now + maxf(0.0, telegraph)
	_close_at[i] = _burn_at[i] + life if life < INF else INF
	_mult[i] = mult
	_tag[i] = tag
	_timed[i] = 1 if timed else 0
	opened += 1
	game.stat_add("pits_opened", 1.0)
	game.stat_add("pits_opened_" + tag, 1.0)
	if sound and game.inferno != null:
		game.inferno.play_sound("pit_open", at)
	return true


## Removes pit `i` (the last pit moves into its slot).
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_pos[i] = _pos[last]
		_rad[i] = _rad[last]
		_born[i] = _born[last]
		_burn_at[i] = _burn_at[last]
		_close_at[i] = _close_at[last]
		_mult[i] = _mult[last]
		_tag[i] = _tag[last]
		_timed[i] = _timed[last]
	count = last


## True once the current zone's fixed pits have finished glowing.
func _fixed_burning() -> bool:
	return game.elapsed >= _zone_since + float(cfg["telegraph"])


## Rebuilds the live fixed pits: the hashed cells within active_radius of every
## necromancer (each cell once).
func _rebuild_fixed() -> void:
	fixed.clear()
	var cell := float(cfg["fixed_cell"])
	var reach := float(cfg["active_radius"])
	var seen := {}  # Cells already added (Vector2i -> true).
	for pl in game.all_players:
		var c0 := Vector2i(floori((pl.position.x - reach) / cell), floori((pl.position.y - reach) / cell))
		var c1 := Vector2i(floori((pl.position.x + reach) / cell), floori((pl.position.y + reach) / cell))
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var key := Vector2i(cx, cy)
				if seen.has(key):
					continue
				seen[key] = true
				var f := _fixed_in_cell(cx, cy, zone)
				if f.z > 0.0:
					fixed.append(f)
	fixed_peak = maxi(fixed_peak, fixed.size())


## The fixed pit of world cell (`cx`, `cy`) in zone `z`: x, y, radius (radius 0
## = none). A pure hash of the cell, the zone and the stage's seed (cached).
func _fixed_in_cell(cx: int, cy: int, z: int) -> Vector3:
	var key := Vector3i(cx, cy, z)
	if _cell_cache.has(key):
		return _cell_cache[key]
	var chances: Array = cfg["fixed_chance"]
	var chance := float(chances[mini(z, chances.size() - 1)]) if not chances.is_empty() else 0.0
	var h := _mix(cx, cy, z)
	var out := Vector3.ZERO
	if float(h & 0xFFFF) / 65536.0 < chance:
		var cell := float(cfg["fixed_cell"])
		var margin := minf(float(cfg["fixed_margin"]), cell * 0.4)
		var ox := margin + float((h >> 16) & 0xFFFF) / 65536.0 * (cell - 2.0 * margin)
		var oy := margin + float((h >> 32) & 0xFFFF) / 65536.0 * (cell - 2.0 * margin)
		var r := lerpf(float(cfg["fixed_radius_min"]), float(cfg["fixed_radius_max"]), float((h >> 48) & 0xFFF) / 4096.0)
		var c := Vector2(float(cx) * cell + ox, float(cy) * cell + oy)
		if c.length() >= float(cfg["fixed_clear"]) + r and not game.arena.is_blocked(c, r * 0.4):
			out = Vector3(c.x, c.y, r)
	_cell_cache[key] = out
	return out


## A 64-bit integer mix (splitmix64 finaliser) of a cell, a zone and the stage's
## salt: the same bits on every platform (ints wrap; no float, no engine hash).
func _mix(cx: int, cy: int, z: int) -> int:
	var x := cx * 0x9E3779B1 + cy * 0x85EBCA77 + z * 0xC2B2AE3D + _salt * 0x27D4EB2F
	x = (x ^ (x >> 30)) * -4658895280553007687  # 0xBF58476D1CE4E5B9 as a signed 64-bit int.
	x = (x ^ (x >> 27)) * -7723592293110705685  # 0x94D049BB133111EB as a signed 64-bit int.
	x = x ^ (x >> 31)
	return x & 0x7FFFFFFFFFFFFFFF


## `p` pushed radially out of the circle (`c`, `reach`) when inside it.
static func _out_of(p: Vector2, c: Vector2, reach: float) -> Vector2:
	var off := p - c
	var d := off.length()
	if d >= reach:
		return p
	var n := off / d if d > 0.01 else Vector2.RIGHT
	return c + n * reach


## THE BURN: every burning pit damages what stands in it, each body once.
func _burn(tick: float) -> void:
	var circles := PackedVector3Array()  # Burning pits now: x, y, r.
	var mults := PackedFloat32Array()  # x the burn of each.
	var now := game.elapsed
	for i in count:
		if now >= _burn_at[i] and now < _close_at[i]:
			circles.append(Vector3(_pos[i].x, _pos[i].y, _rad[i]))
			mults.append(_mult[i])
	if _fixed_burning():
		for f in fixed:
			circles.append(f)
			mults.append(1.0)
	if circles.is_empty():
		return
	game.stat_add("pit_burns", 1.0)
	_burned.clear()
	var dm := game.enemies.damage_mult  # The enemies' damage scaling (necromancer, summons).
	var any := false
	for pl in game.all_players:
		if pl.dead:
			continue
		for k in circles.size():
			var c := circles[k]
			if pl.position.distance_to(Vector2(c.x, c.y)) < c.z + pl.radius * 0.5:
				var before := pl.hp
				game.combat.damage_player(float(cfg["dps_player"]) * tick * dm * mults[k], InfernoRulesData.PIT_SOURCE, pl)
				game.stat_add("pit_dmg_you", maxf(0.0, before - pl.hp))
				any = true
				break
	for k in circles.size():
		var c := circles[k]
		var at := Vector2(c.x, c.y)
		game.ally_grid.query(at, c.z + PantheonRulesData.SUMMON_SLACK, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.airborne or u.flies or u.charmed or u.state == SummonedUnit.State.DEAD or _burned.has(u):
				continue
			if u.position.distance_to(at) >= c.z + u.radius * 0.5:
				continue
			_burned[u] = true
			var hp0 := u.hp
			game.combat.damage_unit(u, float(cfg["dps_summon"]) * tick * dm * mults[k] * salt_circle_mult(u), InfernoRulesData.PIT_SOURCE)
			game.stat_add("pit_dmg_summons", maxf(0.0, hp0 - maxf(u.hp, 0.0)))
			any = true
		game.enemy_grid.query(at, c.z + 24.0, _tmp)
		for e: Enemy in _tmp:
			if _burned.has(e) or not burns_enemy(e):
				continue
			if e.position.distance_to(at) >= c.z + e.radius * 0.5:
				continue
			_burned[e] = true
			var damned := e.kit is InfernoKit and (e.kit as InfernoKit).is_damned()
			var dmg := float(cfg["dps_enemy"]) * tick * game.enemies.hp_mult * mults[k] * (float(cfg["damned_mult"]) if damned else 1.0)
			var dealt := game.combat.damage_enemy(e, dmg, InfernoRulesData.PIT_SOURCE)
			game.stat_add("pit_dmg_enemies", dealt)
			if not e.active or e.hp <= 0.0:
				game.stat_add("pit_kills", 1.0)
				if damned:
					game.stat_add("pit_damned_burned", 1.0)
			any = true
	if any and game.inferno != null:
		game.inferno.play_sound("pit_burn", game.player.position)


# =====================================================================================
# Autotest
# =====================================================================================

## Autopilot hint (the autotest bot): a push out of every pit (glowing or
## burning) within danger_reach px of its edge, stronger inside.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var now := game.elapsed
	var extra := float(cfg["danger_reach"]) + game.player.radius
	for i in count:
		if now < _close_at[i]:
			push += _push_from(p, _pos[i], _rad[i] + extra)
	for f in fixed:
		push += _push_from(p, Vector2(f.x, f.y), f.z + extra)
	return push


## A push away from the circle (`c`, `reach`) at `p` (zero outside it).
static func _push_from(p: Vector2, c: Vector2, reach: float) -> Vector2:
	var off := p - c
	var d := off.length()
	if d >= reach:
		return Vector2.ZERO
	var n := off / d if d > 0.01 else Vector2.RIGHT
	return n * (1.0 - d / reach) * 2.5


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Draws every live pit: a glowing rim while it telegraphs, the lava pool while
## it burns (its glow pulsing on game time), fading as it cools.
func _draw() -> void:
	var now := game.elapsed
	var view := Rect2(game.player.position - Vector2(1400, 900), Vector2(2800, 1800))  # Generous: co-op and zoom.
	for i in count:
		var c := _pos[i]
		if not view.has_point(c):
			continue
		var r := _rad[i]
		if now < _burn_at[i]:
			var k := clampf((now - _born[i]) / maxf(_burn_at[i] - _born[i], 0.01), 0.0, 1.0)  # 0 glowing .. 1 burning.
			InfernoGlyphs.draw_pit_rim(self, c, r, k, now)
		else:
			var a := 1.0
			if now >= _close_at[i]:
				a = clampf(1.0 - (now - _close_at[i]) / maxf(float(cfg["close_time"]), 0.01), 0.0, 1.0)
			InfernoGlyphs.draw_pit(self, c, r, a, now + float(i) * 0.7)
	var fk := clampf((now - _zone_since) / maxf(float(cfg["telegraph"]), 0.01), 0.0, 1.0)  # The zone's pits glowing .. burning.
	for f in fixed:
		var c := Vector2(f.x, f.y)
		if not view.has_point(c):
			continue
		if fk < 1.0:
			InfernoGlyphs.draw_pit_rim(self, c, f.z, fk, now)
		else:
			InfernoGlyphs.draw_pit(self, c, f.z, 1.0, now + f.x * 0.01)
	if not _cooling.is_empty():
		var ca := clampf(1.0 - (now - _zone_since) / maxf(float(cfg["close_time"]), 0.01), 0.0, 1.0)
		for f in _cooling:
			InfernoGlyphs.draw_pit(self, Vector2(f.x, f.y), f.z, ca, now)
