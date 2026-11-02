## WitchHexes — the Court witches' shared hexes (Act VII, the Witchwood; GDD
## §15.0 "The Witchwood (Act VII phase 2)"; owner-approved proposal
## docs/act7/PROPOSAL.md "Roster" and "Stage 20"), owned by Game.court
## (CourtRules.witch_hexes(), created the first time a Crimson Witch, a Bloated
## Thrall, a hex stone or Isolde needs it; stepped from CourtRules.step()). It
## works on any stage the Court's kinds walk (--spawn=), like every Court kind.
## THE ONE PATH of each of these:
##   * THE COVENS: free Crimson Witches (CrimsonWitchKit registers each) within
##     COVEN form_range of each other band into covens of COVEN size (in spawn
##     order: no RNG). A coven may cast while the Blood Moon is up
##     (BloodMoon.is_up(), THE test) or while a standing hex stone powers it
##     (its centre within STONES power_range of one); never on a broken
##     stone's dead ground. When it casts, its witches hold and chant: the HEX
##     CIRCLE glows windup s (a telegraph), then bites for cast_time s: every
##     tick it heals each Court enemy inside (CombatResolver.heal_enemy(), the
##     existing enemy heal path, a witch as the healer: a Keening Lady's
##     silence stops it) and drains each summon inside (damage_unit(),
##     CIRCLE_SOURCE; the necromancer is not drained: "drains the army").
##     KILL ONE WITCH AND THE CIRCLE FAILS (owner-approved proposal): a coven
##     that loses a member dissolves at once, its circle with it; the
##     survivors are free to band again.
##   * THE HEX STONES: HexStoneKit registers each standing stone; a broken one
##     leaves dead ground (add_dead_ground()) for STONES dead_life s or until
##     the stage clears it (clear_dead_ground(), the next zone).
##   * THE BLOOD POOLS: open_pool(at, radius, life, tag), the one pool path (a
##     Bloated Thrall's burst, Isolde's cauldron bombs): every POOLS tick each
##     Court enemy standing in a pool heals POOLS heal_share of its max HP per
##     s (heal_enemy(), the existing path).
##   * ISOLDE'S HEX CIRCLES on the ring (BossIsolde): cast_circle(at, radius,
##     windup, time, heal_share, drain_dps, by, tag) lays a circle with no
##     coven behind it; it bites and heals like a coven's and ends with its
##     time or its caster.
## Drawing: the circles (a crimson ring and a faint fill; textures), the pools
## (dark red discs), the dead ground's broken stumps and the threads from a
## powering stone to the coven it powers; under the bodies, never headless,
## textures only (the Web GL rule).
## Determinism: no RNG, no instance ids; game time only. Stats: hex_covens_formed,
## hex_casts, hex_casts_moon, hex_casts_stone, hex_casts_denied_dead,
## hex_circles_failed, hex_circle_heal, hex_circle_heal_<tag>, hex_drain_hits,
## blood_pools_opened, blood_pools_opened_<tag>, blood_pool_heal,
## hex_stones_raised (the director), hex_stones_broken.
class_name WitchHexes
extends Node2D

## Coven state: banded, waiting for its next cast.
const IDLE: int = 0
## Coven state: the circle glows (the windup).
const WINDUP: int = 1
## Coven state: the circle bites.
const CASTING: int = 2

## One coven of witches (or, with no members, one of Isolde's circles).
class Coven:
	extends RefCounted
	## The witches (empty for a boss's circle).
	var members: Array[Enemy] = []
	## Their pool generations when they banded (stale guard).
	var gens: PackedInt32Array = PackedInt32Array()
	## IDLE / WINDUP / CASTING.
	var state: int = 0
	## Seconds in the current state.
	var t: float = 0.0
	## Seconds until it may start its next cast (IDLE only).
	var cd: float = 0.0
	## World centre of the circle (locked when the windup starts).
	var centre: Vector2 = Vector2.ZERO
	## Circle radius (px).
	var radius: float = 0.0
	## Windup (s) and bite time (s) of the current circle.
	var windup: float = 0.0
	## Seconds the circle bites.
	var cast_time: float = 0.0
	## Heal per second (share of max HP) and drain per second of its circle.
	var heal_share: float = 0.0
	## Drain per second on each summon inside (before the time scaling).
	var drain_dps: float = 0.0
	## Stats tag ("coven", or the boss's).
	var tag: String = "coven"
	## A boss's circle: its caster (it ends with him) and his generation.
	var caster: Enemy = null
	## The caster's generation.
	var caster_gen: int = 0
	## The standing stone powering this cast (null: the moon, or none).
	var stone: Enemy = null
	## Seconds toward the next pulse.
	var acc: float = 0.0

## One blood pool.
class Pool:
	extends RefCounted
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 0.0
	## Game time (s) it dries.
	var until: float = 0.0
	## Stats tag ("bloated", "cauldron").
	var tag: String = ""

## Owning run.
var game: Game
## Coven numbers (WitchHexData.COVEN).
var coven_cfg: Dictionary = {}
## Stone numbers (WitchHexData.STONES).
var stone_cfg: Dictionary = {}
## Pool numbers (WitchHexData.POOLS).
var pool_cfg: Dictionary = {}
## Living Crimson Witches in spawn order (CrimsonWitchKit registers them).
var witches: Array[Enemy] = []
## Their generations when registered (stale guard).
var _witch_gens: PackedInt32Array = PackedInt32Array()
## Witch -> her coven (absent: free).
var _coven_of: Dictionary = {}
## Covens and boss circles now.
var covens: Array[Coven] = []
## Standing hex stones (HexStoneKit registers them).
var stones: Array[Enemy] = []
## Dead ground of broken stones: centres (world px).
var dead_pos: PackedVector2Array = PackedVector2Array()
## Game time (s) each dead ground ends.
var dead_until: PackedFloat32Array = PackedFloat32Array()
## Blood pools now.
var pools: Array[Pool] = []
## Seconds toward the next coven banding scan.
var _form_acc: float = 0.0
## Seconds toward the next pool heal.
var _pool_acc: float = 0.0
## Game time of the last coven banner.
var _banner_at: float = -INF
## Grid query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## True if the last frame drew anything.
var _drawn: bool = false


## Builds the hexes for `p_game` (CourtRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "WitchHexes"
	z_index = -4  # On the ground: over the floor (-10), under the bodies and the spells' auras (-3).
	z_as_relative = false
	coven_cfg = WitchHexData.COVEN.duplicate()
	stone_cfg = WitchHexData.STONES.duplicate()
	pool_cfg = WitchHexData.POOLS.duplicate()
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Registration (the kits)
# =====================================================================================

## A Crimson Witch `e` was activated (CrimsonWitchKit.reset()).
func add_witch(e: Enemy) -> void:
	witches.append(e)
	_witch_gens.append(e.generation)


## A Crimson Witch `e` left play: her coven (and its circle) breaks.
func drop_witch(e: Enemy) -> void:
	var i := witches.find(e)
	if i >= 0:
		witches.remove_at(i)
		_witch_gens.remove_at(i)
	var c: Coven = _coven_of.get(e)
	if c != null:
		_break(c, true)


## The coven of witch `e` (null: free).
func coven_of(e: Enemy) -> Coven:
	return _coven_of.get(e)


## A hex stone `e` was raised (HexStoneKit.reset()).
func add_stone(e: Enemy) -> void:
	if not stones.has(e):
		stones.append(e)


## A hex stone `e` left play (broken: `broken`, it leaves dead ground; or
## sunk by the director at a zone change).
func drop_stone(e: Enemy, broken: bool) -> void:
	stones.erase(e)
	if broken:
		add_dead_ground(e.position)
		game.stat_add("hex_stones_broken", 1.0)


## Dead ground of a broken stone at `at` (covens there cannot cast).
func add_dead_ground(at: Vector2) -> void:
	dead_pos.append(at)
	dead_until.append(game.elapsed + float(stone_cfg["dead_life"]))


## Clears every dead ground (the Witchwood's next zone raises new stones).
func clear_dead_ground() -> void:
	dead_pos.clear()
	dead_until.clear()


## True when a coven centred at `p` stands on a broken stone's dead ground.
func on_dead_ground(p: Vector2) -> bool:
	var r := float(stone_cfg["dead_range"])
	for i in dead_pos.size():
		if dead_until[i] > game.elapsed and p.distance_to(dead_pos[i]) <= r:
			return true
	return false


## The standing hex stone powering a coven centred at `p` (null: none).
func powering_stone(p: Vector2) -> Enemy:
	var r := float(stone_cfg["power_range"])
	var best: Enemy = null
	var best_d := INF
	for s in stones:
		if not s.active:
			continue
		var dd := p.distance_to(s.position)
		if dd <= r and dd < best_d:
			best = s
			best_d = dd
	return best


# =====================================================================================
# Blood pools and boss circles (public paths)
# =====================================================================================

## THE ONE POOL PATH: opens a blood pool of `radius` px at `at` for `life` s
## (`tag` for the stats: "bloated", "cauldron"). The oldest dries at the cap.
func open_pool(at: Vector2, radius: float, life: float, tag: String) -> void:
	if pools.size() >= int(pool_cfg["max_pools"]):
		pools.remove_at(0)
	var p := Pool.new()
	p.pos = at
	p.radius = radius
	p.until = game.elapsed + life
	p.tag = tag
	pools.append(p)
	game.stat_add("blood_pools_opened", 1.0)
	game.stat_add("blood_pools_opened_" + tag, 1.0)


## True when a body at `p` (radius `r`) stands in a fresh blood pool.
func in_pool(p: Vector2, r: float) -> bool:
	for pool in pools:
		if pool.until > game.elapsed and p.distance_to(pool.pos) <= pool.radius + r * 0.5:
			return true
	return false


## A circle with no coven behind it (Isolde's hex circles on the ring): glows
## `windup` s at `at`, then bites `time` s (heals the Court `heal_share` of max
## HP per s, drains each summon `drain_dps` per s before the time scaling),
## ending early if `by` falls. Stats tag `tag`.
func cast_circle(at: Vector2, radius: float, windup: float, time: float, heal_share: float, drain_dps: float, by: Enemy, tag: String) -> void:
	var c := Coven.new()
	c.state = WINDUP
	c.centre = at
	c.radius = radius
	c.windup = windup
	c.cast_time = time
	c.heal_share = heal_share
	c.drain_dps = drain_dps
	c.tag = tag
	c.caster = by
	c.caster_gen = by.generation if by != null else 0
	covens.append(c)
	game.effects.telegraph_circle(at, radius, windup, by)
	game.stat_add("hex_casts_" + tag, 1.0)


## True when foe `e` stands inside a biting hex circle (any).
func in_circle(p: Vector2) -> bool:
	for c in covens:
		if c.state == CASTING and p.distance_to(c.centre) <= c.radius:
			return true
	return false


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (CourtRules.step()): band free witches, run every coven and
## circle, heal in the pools, age the dead ground.
func step(delta: float) -> void:
	_prune_witches()
	_form_acc += delta
	if _form_acc >= 0.5:
		_form_acc = 0.0
		_band()
	var i := 0
	while i < covens.size():
		if _step_coven(covens[i], delta):
			i += 1
	_step_pools(delta)
	var j := dead_pos.size() - 1
	while j >= 0:
		if dead_until[j] <= game.elapsed:
			dead_pos.remove_at(j)
			dead_until.remove_at(j)
		j -= 1
	if _draws:
		var busy := not covens.is_empty() or not pools.is_empty() or not dead_pos.is_empty()
		if busy or _drawn:
			queue_redraw()
		_drawn = busy


## Drops witches that left play without a deactivate hook (stale guard).
func _prune_witches() -> void:
	var i := witches.size() - 1
	while i >= 0:
		var w := witches[i]
		if not w.active or w.generation != _witch_gens[i]:
			drop_witch(w)
		i -= 1


## Bands free witches into covens: for each free witch in spawn order, the
## nearest free witches within form_range of her join her (all of the size).
func _band() -> void:
	var size := int(coven_cfg["size"])
	var reach := float(coven_cfg["form_range"])
	for w in witches:
		if _coven_of.has(w) or not w.active:
			continue
		var near: Array[Enemy] = []
		for o in witches:
			if o == w or _coven_of.has(o) or not o.active:
				continue
			if o.position.distance_to(w.position) <= reach:
				near.append(o)
		if near.size() < size - 1:
			continue
		near.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.position.distance_squared_to(w.position) < b.position.distance_squared_to(w.position))
		var c := Coven.new()
		c.members.append(w)
		for k in size - 1:
			c.members.append(near[k])
		for m in c.members:
			c.gens.append(m.generation)
			_coven_of[m] = c
		c.cd = float(coven_cfg["first_cast"])
		c.radius = float(coven_cfg["radius"])
		c.windup = float(coven_cfg["windup"])
		c.cast_time = float(coven_cfg["cast_time"])
		c.heal_share = float(coven_cfg["heal_share"])
		c.drain_dps = float(coven_cfg["drain_dps"])
		covens.append(c)
		game.stat_add("hex_covens_formed", 1.0)


## Centre (world px) of coven `c`'s witches now.
func centre_of(c: Coven) -> Vector2:
	var s := Vector2.ZERO
	for m in c.members:
		s += m.position
	return s / maxf(1.0, float(c.members.size()))


## One coven or circle's tick. Returns false when it was removed.
func _step_coven(c: Coven, delta: float) -> bool:
	if c.members.is_empty():
		# A boss's circle: it ends with its time or its caster.
		if c.caster != null and (not c.caster.active or c.caster.generation != c.caster_gen):
			covens.erase(c)
			return false
	else:
		for k in c.members.size():
			if not c.members[k].active or c.members[k].generation != c.gens[k]:
				_break(c, true)
				return false
	c.t += delta
	match c.state:
		IDLE:
			c.cd -= delta
			if c.cd <= 0.0:
				_try_cast(c)
		WINDUP:
			if c.t >= c.windup:
				c.state = CASTING
				c.t = 0.0
				c.acc = 0.0
				game.court.play_sound("hex_chant", c.centre, 1.0)
		CASTING:
			c.acc += delta
			var tick := float(coven_cfg["tick"])
			while c.acc >= tick:
				c.acc -= tick
				_pulse(c, tick)
			if c.t >= c.cast_time:
				if c.members.is_empty():
					covens.erase(c)
					return false
				c.state = IDLE
				c.t = 0.0
				c.cd = float(coven_cfg["cast_every"])
				c.stone = null
	return true


## A banded coven tries to start a circle: the moon or a stone must power it,
## never on dead ground, and a summon or the necromancer must be in reach.
func _try_cast(c: Coven) -> void:
	var at := centre_of(c)
	var reach := float(coven_cfg["cast_reach"])
	var prey := false
	for pl in game.all_players:
		prey = prey or (not pl.dead and pl.position.distance_to(at) <= reach)
	if not prey:
		game.ally_grid.query(at, reach, _tmp)
		for u: SummonedUnit in _tmp:
			if u.active and u.state != SummonedUnit.State.DEAD and u.position.distance_to(at) <= reach:
				prey = true
				break
	if not prey:
		c.cd = 0.5
		return
	if on_dead_ground(at):
		c.cd = 1.0
		game.stat_add("hex_casts_denied_dead", 1.0)
		return
	var moon := game.court != null and game.court.moon.is_up()
	var stone: Enemy = null if moon else powering_stone(at)
	if not moon and stone == null:
		c.cd = 0.5
		return
	c.state = WINDUP
	c.t = 0.0
	c.centre = at
	c.stone = stone
	game.effects.telegraph_circle(at, c.radius, c.windup, c.members[0])
	game.stat_add("hex_casts", 1.0)
	game.stat_add("hex_casts_moon" if moon else "hex_casts_stone", 1.0)
	if game.elapsed - _banner_at >= float(coven_cfg["cast_banner_gap"]):
		_banner_at = game.elapsed
		game.enemies.show_banner(WitchHexData.COVEN_BANNER)


## One pulse of a biting circle: heals the Court inside, drains the summons.
func _pulse(c: Coven, tick: float) -> void:
	var healer: Enemy = c.members[0] if not c.members.is_empty() else c.caster
	game.enemy_grid.query(c.centre, c.radius + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	var heal_list: Array[Enemy] = []  # Own copy: heals never re-query, but keep the pattern.
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and e.position.distance_to(c.centre) <= c.radius + e.radius * 0.5 and is_court(e):
			heal_list.append(e)
	for e in heal_list:
		var share := c.heal_share * (float(coven_cfg["boss_heal_mult"]) if e.is_boss or e.is_miniboss else 1.0)
		var healed := game.combat.heal_enemy(e, e.max_hp * share * tick, healer)
		if healed > 0.0:
			game.stat_add("hex_circle_heal", healed)
			game.stat_add("hex_circle_heal_" + c.tag, healed)
	var mult := game.enemies.damage_mult * (healer.hit_mult() if healer != null and healer.active else 1.0)
	var dmg := c.drain_dps * tick * mult
	if dmg <= 0.0:
		return
	var victims: Array[SummonedUnit] = []
	game.ally_grid.query(c.centre, c.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and not u.airborne and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD and u.position.distance_to(c.centre) <= c.radius + u.radius * 0.5:
			victims.append(u)
	for u in victims:
		if u.active:
			game.combat.damage_unit(u, dmg, WitchHexData.CIRCLE_SOURCE)
	game.stat_add("hex_drain_hits", float(victims.size()))


## Coven `c` dissolves (a witch fell: `failed` counts a broken circle).
func _break(c: Coven, failed: bool) -> void:
	for m in c.members:
		if _coven_of.get(m) == c:
			_coven_of.erase(m)
	if failed and c.state != IDLE:
		game.stat_add("hex_circles_failed", 1.0)
		game.effects.ring(c.centre, c.radius, Palette.COURT_BLOOD_LIGHT, 0.3)
	covens.erase(c)


## True for a Court enemy (a Court kit's kind, or a Court boss).
static func is_court(e: Enemy) -> bool:
	if e.kit is CourtKit:
		return true
	return e is Boss and String((e as Boss).boss_def.get("faction", "")) == CourtEnemyData.FACTION


## The pools heal every Court enemy standing in them; dry pools leave.
func _step_pools(delta: float) -> void:
	var now := game.elapsed
	var k := pools.size() - 1
	while k >= 0:
		if now >= pools[k].until + float(pool_cfg["fade"]):
			pools.remove_at(k)
		k -= 1
	if pools.is_empty():
		return
	_pool_acc += delta
	var tick := float(pool_cfg["tick"])
	if _pool_acc < tick:
		return
	_pool_acc -= tick
	var healed_any: Dictionary = {}  # A foe in two pools heals once a tick.
	for pool in pools:
		if pool.until <= now:
			continue
		game.enemy_grid.query(pool.pos, pool.radius + ProjectileManager.MAX_BODY_RADIUS, _tmp)
		for e: Enemy in _tmp:
			if not e.active or e.is_structure or healed_any.has(e) or not is_court(e):
				continue
			if e.position.distance_to(pool.pos) > pool.radius + e.radius * 0.5:
				continue
			healed_any[e] = true
			var share := float(pool_cfg["heal_share"]) * (float(pool_cfg["boss_heal_mult"]) if e.is_boss or e.is_miniboss else 1.0)
			var healed := game.combat.heal_enemy(e, e.max_hp * share * tick)
			if healed > 0.0:
				game.stat_add("blood_pool_heal", healed)


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## The pools, the dead ground, the circles and the powering threads. Textures
## only (discs, the Court's ring and thread).
func _draw() -> void:
	var now := game.elapsed
	for pool in pools:
		var a := 1.0
		if now >= pool.until:
			a = clampf(1.0 - (now - pool.until) / float(pool_cfg["fade"]), 0.0, 1.0)
		SpriteBank.draw_disc(self, pool.pos, pool.radius, Color(Palette.COURT_BLOOD_DARK, 0.75 * a))
		SpriteBank.draw_disc(self, pool.pos + Vector2(-pool.radius * 0.15, -pool.radius * 0.15), pool.radius * 0.6, Color(Palette.COURT_BLOOD, 0.45 * a))
		SpriteBank.draw_disc(self, pool.pos + Vector2(-pool.radius * 0.35, -pool.radius * 0.3), pool.radius * 0.15, Color(Palette.COURT_BLOOD_LIGHT, 0.5 * a))
	for i in dead_pos.size():
		if not SpriteBank.draw(self, WitchwoodGlyphs.STONE_BROKEN_SPRITE, dead_pos[i], false):
			WitchwoodGlyphs.draw_hex_stone(self, dead_pos[i], 12.0, false, true)
	for c in covens:
		if c.state == IDLE:
			continue
		var r := c.radius
		var k := 1.0
		var fill := 0.18
		if c.state == WINDUP:
			k = clampf(c.t / maxf(c.windup, 0.01), 0.0, 1.0)
			fill = 0.06 + 0.08 * k
		SpriteBank.draw_disc(self, c.centre, r, Color(Palette.COURT_BLOOD, fill))
		draw_texture_rect(CourtGlyphs.ring_texture(), Rect2(c.centre - Vector2(r, r) / 0.9, Vector2(r, r) * 2.0 / 0.9), false, Color(Palette.COURT_BLOOD_LIGHT, 0.4 + 0.5 * k))
		if c.state == CASTING:
			var spin := now * 0.8
			for n in 6:
				var p := c.centre + Vector2.from_angle(spin + TAU * float(n) / 6.0) * r * 0.82
				SpriteBank.draw_disc(self, p, 3.0, Color(Palette.COURT_BLOOD_LIGHT, 0.85))
			if c.stone != null and c.stone.active:
				CourtGlyphs.draw_thread(self, c.stone.position, c.centre, 2.0, Color(Palette.COURT_BLOOD_LIGHT, 0.5))
