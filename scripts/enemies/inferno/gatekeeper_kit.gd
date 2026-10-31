## GatekeeperKit — THE GATEKEEPER, the Burning Gate's miniboss
## (BurningGateEnemyData "gatekeeper"; Act VI, GDD §15.0 "The Burning Gate (Act
## VI phase 2)"; owner-approved proposal: "Miniboss, the Gatekeeper, a chained
## giant that drags the damned in"). Spawned once by BurningGateDirector (the
## "gatekeeper" timeline event, 9:00 left) through the normal spawn path; it
## registers as EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager
## drops the miniboss chest). A DEMON (the pits spare him).
##   * THE CHAINS — every chain_every s, when the necromancer is within
##       chain_range px, chain_count lanes fan out toward him (chain_spread rad
##       apart) and glow chain_telegraph s; then a chain flies down each at
##       chain_speed px/s. The first body it meets is struck: the necromancer
##       takes chain_damage_player (he is never dragged); a summon or a damned
##       soul is HOOKED and dragged to the Gatekeeper's feet through THE ONE
##       PULL PATH, pull() (below). A summon dragged to him is crushed
##       (crush_damage); a damned soul is devoured (taken off without a kill:
##       no XP) and heals him devour_heal of his max HP, so leading the damned
##       through the pits first starves him.
##   * THE ONE PULL PATH, pull(e, body, delta): moves a hooked body toward him
##       at drag_speed px/s. A summon is held by the Act II compel path
##       (SummonedUnit.compel(): it neither thinks nor attacks while the chain
##       holds it, then the shared FSM resumes; released when the chain lets
##       go); an enemy is simply moved. An enemy effect on a unit, like Kage's
##       chained kunai: summons have no act rule of their own.
##   * THE SLAM — when a body comes within slam_trigger px and the slam is
##       ready: a telegraphed circle of slam_radius px around him for
##       slam_windup s, then every necromancer and summon in it is hit and the
##       summons thrown slam_push px out (OlympusHits.circle()).
##   * THE COFFLE — every coffle_every s he hauls a coffle of coffle_count
##       damned souls in on his chains (spawned in a line behind him, under the
##       hard cap): fodder for the pits, food for his chains.
##   * The forced march — beyond advance_range px he strides
##       advance_speed_mult faster (he never kites and is never left behind).
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest,
## every chain lets go. No RNG. Stats: gatekeeper_spawned, gatekeeper_chains,
## gatekeeper_hooked_summons, gatekeeper_hooked_damned, gatekeeper_crushed,
## gatekeeper_devoured, gatekeeper_devour_heal, gatekeeper_chain_hits_player,
## gatekeeper_slams, gatekeeper_slam_hits, gatekeeper_coffles,
## gatekeeper_coffle_damned, gatekeeper_kills, gatekeeper_ttk.
class_name GatekeeperKit
extends InfernoKit

## Phase: the chain lanes glow (the throw's windup).
const CHAIN_WINDUP: int = 1
## Phase: the slam's circle (its windup).
const SLAM_WINDUP: int = 2
## px of reach the autotest bot keeps beyond a telegraph.
const DANGER_PAD: float = 18.0  # TUNING (not in GDD) autotest hint only

## One flying or dragging chain.
class Chain:
	extends RefCounted
	## World point of the chain's head.
	var pos: Vector2 = Vector2.ZERO
	## Unit direction it flies.
	var dir: Vector2 = Vector2.RIGHT
	## Px it may still fly.
	var left: float = 0.0
	## The hooked summon (null: none, or an enemy is hooked).
	var unit: SummonedUnit = null
	## The hooked damned soul (null: none, or a summon is hooked).
	var enemy: Enemy = null
	## Generation of the hooked body (stale guard).
	var gen: int = 0
	## Seconds the chain may still hold its body.
	var hold: float = 0.0

## Seconds until the next chain throw.
var _chain_cd: float = 0.0
## Seconds until the next slam.
var _slam_cd: float = 0.0
## Seconds until the next coffle.
var _coffle_cd: float = 0.0
## Unit directions of the glowing lanes (locked at the windup).
var _lanes: Array[Vector2] = []
## Chains flying or dragging now.
var _chains: Array[Chain] = []
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Grid query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_chain_cd = 3.0
	_slam_cd = float(def["slam_every"]) * 0.5
	_coffle_cd = 4.0
	_lanes.clear()
	_chains.clear()
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("gatekeeper_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	_chain_cd -= delta
	_slam_cd -= delta
	_coffle_cd -= delta
	e.knockback = Vector2.ZERO  # Like a boss: blows do not shove a chained giant.
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	_step_chains(e, delta)
	if _coffle_cd <= 0.0:
		_coffle(e)
	match phase:
		CHAIN_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["chain_telegraph"]):
				_throw(e)
				set_phase(e, IDLE)
			return true
		SLAM_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["slam_windup"]):
				_slam(e)
				set_phase(e, IDLE)
			return true
	var pl := e.game.player
	var dist := e.position.distance_to(pl.position)
	e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else pl
	if _slam_cd <= 0.0 and e.position.distance_to(t.position) - e.radius - body_radius(e, t) <= float(d["slam_trigger"]):
		_slam_cd = float(d["slam_every"])
		e.game.effects.telegraph_circle(e.position, float(d["slam_radius"]), float(d["slam_windup"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		set_phase(e, SLAM_WINDUP)
		hold(e)
		return true
	if _chain_cd <= 0.0 and dist <= float(d["chain_range"]) + 40.0:
		_chain_cd = float(d["chain_every"])
		var to := pl.position - e.position
		var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		_lanes.clear()
		var n := int(d["chain_count"])
		for i in n:
			var l := dir.rotated((float(i) - float(n - 1) * 0.5) * float(d["chain_spread"]))
			_lanes.append(l)
			e.game.effects.telegraph_line(e.position, e.position + l * float(d["chain_range"]), float(d["chain_width"]), float(d["chain_telegraph"]), e)
		e.motion_lunge(-dir, MotionData.POWER_CAST)
		set_phase(e, CHAIN_WINDUP)
		hold(e)
		return true
	return false


# =====================================================================================
# The chains and THE ONE PULL PATH
# =====================================================================================

## The chains fly down the glowing lanes.
func _throw(e: Enemy) -> void:
	for l in _lanes:
		var c := Chain.new()
		c.pos = e.position + l * e.radius
		c.dir = l
		c.left = float(d["chain_range"]) - e.radius
		_chains.append(c)
	e.game.stat_add("gatekeeper_chains", float(_lanes.size()))
	rules(e).play_sound("chain_haul", e.position)


## Every chain flies on, hooks the first body it meets, or drags its body in.
func _step_chains(e: Enemy, delta: float) -> void:
	if _chains.is_empty():
		return
	e.queue_redraw()  # The chains (drawing only).
	var g := e.game
	var mult := hit_scale(e)
	var hw := float(d["chain_width"]) * 0.5
	var i := 0
	while i < _chains.size():
		var c := _chains[i]
		if c.unit != null or c.enemy != null:
			if _drag(e, c, delta, mult):
				i += 1
			else:
				_chains.remove_at(i)
			continue
		var step_len := minf(float(d["chain_speed"]) * delta, c.left)
		c.pos += c.dir * step_len
		c.left -= step_len
		var done := c.left <= 0.0
		for pl in g.all_players:
			if not done and not pl.dead and pl.position.distance_to(c.pos) <= hw + pl.radius:
				g.combat.damage_player(float(d["chain_damage_player"]) * mult, BurningGateEnemyData.CHAIN_SOURCE, pl)
				g.stat_add("gatekeeper_chain_hits_player", 1.0)
				done = true
		if not done:
			done = _hook_summon(e, c, hw, mult) or _hook_damned(e, c, hw)
		if done and c.unit == null and c.enemy == null:
			_chains.remove_at(i)
			continue
		i += 1


## Hooks the first summon at the chain's head. True when one was hooked.
func _hook_summon(e: Enemy, c: Chain, hw: float, mult: float) -> bool:
	var g := e.game
	g.ally_grid.query(c.pos, hw + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.charmed or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(c.pos) > hw + u.radius or u.is_compelled():
			continue
		if not u.compel(u.position, g.elapsed + float(d["drag_hold"]), 0.0):
			continue
		c.unit = u
		c.gen = u.generation
		c.hold = float(d["drag_hold"])
		g.combat.damage_unit(u, float(d["chain_damage_summon"]) * mult * e.undead_damage_mult, BurningGateEnemyData.CHAIN_SOURCE, e)
		g.stat_add("gatekeeper_hooked_summons", 1.0)
		g.effects.ring(u.position, u.radius * 1.6, InfernoGlyphs.IRON, 0.25)
		return true
	return false


## Hooks the first damned soul at the chain's head. True when one was hooked.
func _hook_damned(e: Enemy, c: Chain, hw: float) -> bool:
	var g := e.game
	g.enemy_grid.query(c.pos, hw + 12.0, _tmp)
	for o: Enemy in _tmp:
		if not o.active or o == e or not (o.kit is InfernoKit) or not (o.kit as InfernoKit).is_damned():
			continue
		if o.position.distance_to(c.pos) > hw + o.radius:
			continue
		c.enemy = o
		c.gen = o.generation
		c.hold = float(d["drag_hold"])
		g.stat_add("gatekeeper_hooked_damned", 1.0)
		return true
	return false


## THE ONE PULL PATH of the Gatekeeper's chains: moves hooked `body` (a
## SummonedUnit held by SummonedUnit.compel(), or an Enemy) toward him at
## drag_speed px/s, never into an obstacle. Returns the px left to his side.
func pull(e: Enemy, body: Node2D, body_r: float, delta: float) -> float:
	var side := body.position - e.position
	var dist := side.length()
	var want := e.radius + body_r + 4.0  # Dragged against his side.
	if dist > want:
		var goal := e.position + side / dist * want
		var to := goal - body.position
		var step := minf(float(d["drag_speed"]) * delta, to.length())
		if step > 0.0:
			var dir := to / to.length()
			body.position += dir * e.game.arena.clear_length(body.position, dir, step, body_r * 0.5)
	return maxf(0.0, body.position.distance_to(e.position) - want)


## Drags chain `c`'s body in; at his feet a summon is crushed and a damned
## soul devoured. False when the chain lets go (arrived, gone, out of hold).
func _drag(e: Enemy, c: Chain, delta: float, mult: float) -> bool:
	var g := e.game
	c.hold -= delta
	if c.unit != null:
		var u := c.unit
		if not u.active or u.generation != c.gen or not u.is_compelled() or u.charmed:
			_let_go(c)
			return false
		var left := pull(e, u, u.radius, delta)
		c.pos = u.position
		if left <= 2.0:
			g.combat.damage_unit(u, float(d["crush_damage"]) * mult * e.undead_damage_mult, BurningGateEnemyData.CHAIN_SOURCE, e)
			g.stat_add("gatekeeper_crushed", 1.0)
			_let_go(c)
			return false
	else:
		var o := c.enemy
		if not o.active or o.generation != c.gen:
			c.enemy = null
			return false
		var left := pull(e, o, o.radius, delta)
		c.pos = o.position
		if left <= 2.0:
			var heal := e.max_hp * float(d["devour_heal"])
			var before := e.hp
			e.hp = minf(e.max_hp, e.hp + heal)
			g.stat_add("gatekeeper_devoured", 1.0)
			g.stat_add("gatekeeper_devour_heal", e.hp - before)
			g.effects.ring(e.position, e.radius * 1.4, Palette.INFERNO_LAVA, 0.3)
			g.enemies.despawn(o)  # Devoured: off the field without a kill (no XP).
			c.enemy = null
			return false
	if c.hold <= 0.0:
		_let_go(c)
		return false
	return true


## The chain opens: a hooked summon is free again (its compel ends now).
func _let_go(c: Chain) -> void:
	var u := c.unit
	if u != null and u.active and u.generation == c.gen:
		u.compel_until = minf(u.compel_until, u.game.elapsed)
	c.unit = null
	c.enemy = null


# =====================================================================================
# The slam and the coffle
# =====================================================================================

## The slam: every necromancer and summon in the circle is hit, the summons thrown out.
func _slam(e: Enemy) -> void:
	var g := e.game
	var mult := hit_scale(e)
	g.stat_add("gatekeeper_slams", 1.0)
	g.stat_add("gatekeeper_slam_hits", float(OlympusHits.circle(g, e.position, float(d["slam_radius"]),
			float(d["slam_damage_player"]) * mult, float(d["slam_damage_summon"]) * mult * e.undead_damage_mult,
			BurningGateEnemyData.SLAM_SOURCE, e, float(d["slam_push"]), _tmp)))
	g.effects.impact(e.position, float(d["slam_radius"]), Palette.INFERNO_LAVA)
	g.shake(5.0)
	rules(e).play_sound("brute_slam", e.position)


## A coffle of the damned hauled in on his chains: a line behind him.
func _coffle(e: Enemy) -> void:
	_coffle_cd = float(d["coffle_every"])
	var g := e.game
	var to := g.player.position - e.position
	var back := -(to.normalized() if to.length() > 1.0 else Vector2.RIGHT)
	var side := back.orthogonal()
	var n := int(d["coffle_count"])
	var made := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + back * (e.radius + 30.0 + 18.0 * floorf(float(i) / 2.0)) + side * (16.0 if i % 2 == 0 else -16.0)
		if g.enemies.spawn_at(InfernoEnemyData.DAMNED, at, false) != null:
			made += 1
	g.stat_add("gatekeeper_coffles", 1.0)
	g.stat_add("gatekeeper_coffle_damned", float(made))


# =====================================================================================
# Death, hints, drawing
# =====================================================================================

## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.INFERNO_LAVA_LIGHT)
	g.shake(10.0)
	g.enemies.show_banner("The Gatekeeper falls: his chains go slack!")
	g.stat_add("gatekeeper_kills", 1.0)
	g.stat_add("gatekeeper_ttk", g.elapsed - _spawned_at)


## Every chain lets go; releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	for c in _chains:
		_let_go(c)
	_chains.clear()
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the slam circle and sideways out of the glowing chain lanes.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == SLAM_WINDUP:
		var off := p - e.position
		var reach := float(d["slam_radius"]) + DANGER_PAD
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	if phase == CHAIN_WINDUP:
		for l in _lanes:
			var rel := p - e.position
			var along := rel.dot(l)
			if along > 0.0 and along < float(d["chain_range"]) + DANGER_PAD:
				var side := rel - l * along
				if side.length() < float(d["chain_width"]) * 0.5 + DANGER_PAD:
					return side.normalized() * 2.0 if side.length() > 0.5 else l.orthogonal() * 2.0
	return Vector2.ZERO


## The chains: iron links from his wrists to each head. Visual only (short
## line segments, redrawn only while a chain flies).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if _chains.is_empty():
		return
	unmirror(e, ci)
	for c in _chains:
		var to := c.pos - e.position
		var n := maxi(1, int(to.length() / 8.0))
		for k in n:
			var a := to * (float(k) / float(n))
			var b := to * ((float(k) + 0.6) / float(n))
			ci.draw_line(a, b, InfernoGlyphs.IRON, 2.0)
		SpriteBank.draw_disc(ci, to, 3.0, Palette.INFERNO_LAVA_LIGHT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
