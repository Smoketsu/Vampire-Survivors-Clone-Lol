## BlitzKit — the kit of BLITZ (CityEnemyData "blitz"; Act VIII, GDD §15.0
## "Supers"; owner-approved proposal: "a speedster who dashes through the
## ring; can't turn mid-dash, so a Bone Wall stops him cold"), the reference
## Super (a SuperKit: guarded x0.6 until his weakness is read). His power and
## weakness, "Fast. Can't turn.":
##   * THE DASH: every dash_every s, with his target within dash_range px, he
##     crouches dash_windup s (a cyan line down his street), then runs
##     dash_length px straight along it at dash_speed px/s, through the ring:
##     every summon and necromancer within dash_width px of his line takes
##     dash_damage once (an enemy attack, not a summon rule). On a city-block
##     layout the dash runs along the street axis nearer his target's
##     direction (the one with the longer clear run); elsewhere straight at it;
##   * HE CANNOT TURN: a dash that ends on a building face, a wreck, a Bone Wall
##     segment (any necromancer's: BoneWall.covers()) or a BLOCKER summon (a
##     summon with a block radius: Warriors, Abominations, Golems...) stops him
##     cold and EXPOSES him (SuperKit.expose(): stunned 1 s, then x1.5 damage
##     taken for 4 s). A dash that simply runs out does not.
## Between dashes he fights in melee with the shared AI.
## Determinism: no RNG (his first dash is staggered by the think slot).
class_name BlitzKit
extends SuperKit

## Phase: crouched, about to dash (his line shows).
const WINDUP: int = 1
## Phase: dashing.
const DASH: int = 2

## Seconds until his next dash may start.
var _cd: float = 0.0
## The dash's direction (unit; fixed: he cannot turn).
var _dir: Vector2 = Vector2.RIGHT
## px run in the current dash.
var _run: float = 0.0
## Bodies his current dash already hit.
var _struck: Array = []
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(d["dash_every"]) * 0.5)
	_struck.clear()


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	match phase:
		WINDUP:
			hold(e)
			phase_time += delta
			if phase_time >= float(d["dash_windup"]):
				set_phase(e, DASH)
				_run = 0.0
				_struck.clear()
				e.game.stat_add("blitz_dashes", 1.0)
				rules(e).play_sound("super_arrive", e.position, 0.4)
			return true
		DASH:
			_dash_step(e, delta)
			return true
	_cd -= delta
	if _cd > 0.0 or not e._target_valid():
		return false
	var to := e.target.position - e.position
	if to.length() > float(d["dash_range"]) or to.length() < 1.0:
		return false
	_dir = _pick_dir(e, to)
	facing = _dir
	_cd = float(d["dash_every"])
	set_phase(e, WINDUP)
	hold(e)
	return true


## The dash's direction toward `to`: on a city-block layout the street axis
## (of the two signed axes toward `to`) with the longer clear run; elsewhere
## straight at it.
func _pick_dir(e: Enemy, to: Vector2) -> Vector2:
	if e.game.arena.city_blocks == null:
		return to.normalized()
	var ax := Vector2(signf(to.x) if to.x != 0.0 else 1.0, 0.0)
	var ay := Vector2(0.0, signf(to.y) if to.y != 0.0 else 1.0)
	var arena := e.game.arena
	var len_x := arena.clear_length(e.position, ax, float(d["dash_length"]), e.radius)
	var len_y := arena.clear_length(e.position, ay, float(d["dash_length"]), e.radius)
	if absf(to.x) >= absf(to.y):
		return ax if len_x >= len_y * 0.5 else ay
	return ay if len_y >= len_x * 0.5 else ax


## One tick of the dash: run on; stop (exposed) on a face, a wreck, a Bone
## Wall segment or a blocker; hit what he passes; end when the run is spent.
func _dash_step(e: Enemy, delta: float) -> void:
	var g := e.game
	var step := float(d["dash_speed"]) * delta
	var next := e.position + _dir * step
	# He cannot turn: what stands in his line stops him cold.
	var o := g.arena.obstacle_at(next)
	if o != null and Arena.separation(o, next, e.radius) != Vector2.ZERO:
		_stop(e, "wreck" if o.kind == CityEnemyData.WRECK else "building")
		return
	for k in g.all_players.size():
		var prev := g.bind_index(k)
		var wall: BoneWall = g.abilities.spells.nodes.get("bone_wall")  # Null until a wall exists.
		var walled := wall != null and wall.covers(next, e.radius)
		g.unbind(prev)
		if walled:
			_stop(e, "bone_wall")
			return
	var width := float(d["dash_width"])
	g.ally_grid.query(next, e.radius + UnitData.MAX_BLOCK_RADIUS + width, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		var gap := u.position.distance_to(next) - e.radius - u.radius
		if u.block_radius > 0.0 and u.position.distance_to(next) < e.radius + u.block_radius and (u.position - e.position).dot(_dir) > 0.0:
			_hit(e, u)
			_stop(e, "blocker")
			return
		if gap <= width:
			_hit(e, u)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(next) <= e.radius + pl.radius + width:
			_hit(e, pl)
	e.position = next
	e.velocity = _dir * float(d["dash_speed"])
	e._update_facing()
	_run += step
	if _run >= float(d["dash_length"]):
		set_phase(e, IDLE)


## His dash strikes body `t` (a summon or a necromancer) once per dash.
func _hit(e: Enemy, t: Node2D) -> void:
	if _struck.has(t):
		return
	_struck.append(t)
	var dmg := float(d["dash_damage"]) * hit_scale(e)
	if t is SummonedUnit:
		e.game.combat.damage_unit(t as SummonedUnit, dmg, CityEnemyData.DASH_SOURCE, e)
	else:
		e.game.combat.damage_player(dmg, CityEnemyData.DASH_SOURCE, t as Necromancer, e)
	e.game.stat_add("blitz_dash_hits", 1.0)


## The dash ends against `by`: he cannot turn, so he is exposed.
func _stop(e: Enemy, by: String) -> void:
	set_phase(e, IDLE)
	hold(e)
	e.game.stat_add("blitz_dash_stopped", 1.0)
	expose(e, by)


## While he crouches: his line down the street (a cyan beam).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase == WINDUP:
		var k := clampf(phase_time / maxf(float(d["dash_windup"]), 0.01), 0.0, 1.0)
		CityGlyphs.draw_headlights(e, Vector2.ZERO, _dir, float(d["dash_length"]), float(d["dash_width"]), 0.2 + 0.3 * k,
				CourtGlyphs.unmirror_xf(e), Palette.CITY_NEON_CYAN)
		e.draw_set_transform_matrix(Transform2D.IDENTITY)


## The autotest autopilot steps off his crouched line.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var rel := p - e.position
	var along := rel.dot(_dir)
	if along < 0.0 or along > float(d["dash_length"]):
		return Vector2.ZERO
	var perp := Vector2(-_dir.y, _dir.x)
	var across := rel.dot(perp)
	var half := float(d["dash_width"]) + 24.0
	if absf(across) >= half:
		return Vector2.ZERO
	return perp * (signf(across) if absf(across) > 0.5 else 1.0) * (1.0 - absf(across) / half)
