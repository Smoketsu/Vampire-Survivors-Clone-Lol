## BurrowerKit — the kit of the BURROWER (ConcordEnemyData "burrower"; Act IX,
## the Brood; GDD §15.0 "The Crash Site (Act IX phase 2)"; owner-approved
## proposal: "Burrower | Brood | Soldier | Tunnels in and bursts up inside the
## ring (a dirt mound 1 s ahead) | Blockers inside the ring"). A slate-dark
## armoured insect (a creature). Its phases:
##   * DIG (dig_time s): it stops and digs in where it stands, still hittable
##     (the first tick on the field, or again once knocked or pulled more than
##     reburrow_dist px from the necromancer, at most once every
##     reburrow_every s).
##   * UNDER: it travels UNDERGROUND at burrow_speed px/s toward a point
##     surface_dist px from the nearest standing necromancer on its own side
##     (the point follows him: inside the Bone Ring, among the summons). While
##     under it is UNTARGETABLE (Enemy.untargetable: out of the enemy grid,
##     so nothing aims at it or hits it) and ETHEREAL (Enemy.ethereal: no
##     summon body-blocks it, and it passes under the obstacles), both the
##     existing one paths; only a faint dirt ripple shows where it goes.
##   * MOUND (mound_time s, owner-approved: "a dirt mound 1 s ahead"): the
##     point is fixed and a DIRT MOUND shows there (a texture,
##     `concord/burrow_mound`, else code discs); it is still under. The
##     autotest bot steps off the mound (danger_push()).
##   * BURST: it bursts up: every grounded summon and necromancer within
##     burst_radius px takes burst_damage (time-scaled) once through
##     CombatResolver.damage_unit() / damage_player(); it is targetable and
##     solid again and fights on with the shared melee AI (blockers inside the
##     ring are the answer).
## A freeze or stun while it digs holds it like any kit; underground no hit
## reaches it. Determinism: no RNG, no instance ids. Stats: burrower_dives,
## burrower_bursts, burrower_burst_hits, burrower_burst_on_you,
## burrower_reburrows.
class_name BurrowerKit
extends ConcordKit

## Phase: digging in (still hittable).
const DIG: int = 1
## Phase: travelling underground.
const UNDER: int = 2
## Phase: the dirt mound shows over its fixed surfacing point.
const MOUND: int = 3
## Sprite key of the dirt mound (the art pass; code discs without it).
const MOUND_ART: String = "concord/burrow_mound"

## Where it will surface (world px; fixed when the mound shows).
var surface_at: Vector2 = Vector2.ZERO
## Game time (s) of its last dive (the reburrow cooldown).
var dived_at: float = -INF
## True once it has dived at least once this life.
var dived: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	dived_at = -INF
	dived = false
	surface_at = e.position


func on_deactivate(e: Enemy) -> void:
	_surface_flags(e)
	super.on_deactivate(e)


## Every tick (see the header): true while a phase owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var g := e.game
	var pl := g.nearest_player(e.position)
	match phase:
		DIG:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("dig_time", 0.6)):
				e.untargetable = true
				e.ethereal = true
				e.phases_obstacles = true
				set_phase(e, UNDER)
			return true
		UNDER:
			phase_time += delta
			var goal := _goal(e, pl)
			var to := goal - e.position
			var step := float(d.get("burrow_speed", 105.0)) * delta
			if to.length() <= step + 1.0:
				e.position = goal
				surface_at = goal
				e.velocity = Vector2.ZERO
				set_phase(e, MOUND)
				rules(e).play_sound("burrow", goal, 0.3)
			else:
				e.velocity = to.normalized() * float(d.get("burrow_speed", 105.0))
				e.position += to.normalized() * step
				e._update_facing()
			return true
		MOUND:
			phase_time += delta
			hold(e)
			e.position = surface_at
			if phase_time >= float(d.get("mound_time", 1.0)):
				_burst(e)
				set_phase(e, IDLE)
			return true
	# On the surface: dig in on its first tick, or again when far from the necromancer.
	var far := e.position.distance_to(pl.position) > float(d.get("reburrow_dist", 300.0))
	if not dived or (far and g.elapsed - dived_at >= float(d.get("reburrow_every", 9.0))):
		if dived:
			g.stat_add("burrower_reburrows", 1.0)
		dived = true
		dived_at = g.elapsed
		g.stat_add("burrower_dives", 1.0)
		set_phase(e, DIG)
		hold(e)
		return true
	return false


## Its surfacing point: surface_dist px from `pl` on its own side.
func _goal(e: Enemy, pl: Necromancer) -> Vector2:
	var side := e.position - pl.position
	var dir := side.normalized() if side.length() > 1.0 else Vector2.RIGHT
	return e.game.arena.free_point(pl.position + dir * float(d.get("surface_dist", 62.0)), e.radius)


## It bursts up: the burst hits every grounded summon and necromancer near it
## once; it is targetable and solid again.
func _burst(e: Enemy) -> void:
	var g := e.game
	_surface_flags(e)
	var r := float(d.get("burst_radius", 30.0))
	var dmg := float(d.get("burst_damage", 6.0)) * hit_scale(e)
	g.stat_add("burrower_bursts", 1.0)
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(e.position) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind, e)
		g.stat_add("burrower_burst_hits", 1.0)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(dmg, e.kind, pl, e)
			g.stat_add("burrower_burst_on_you", 1.0)
	g.effects.impact(e.position, r, Color(0.36, 0.28, 0.20))
	rules(e).play_sound("burrow", e.position, 0.2)


## Back on the surface: targetable, solid and held by the obstacles again.
func _surface_flags(e: Enemy) -> void:
	e.untargetable = false
	e.ethereal = false
	e.phases_obstacles = bool(d.get("phases", false))


func is_busy() -> bool:
	return phase != IDLE


## Under the ground nothing reaches it (a hit that walks the active list
## rather than the enemy grid finds nothing to hurt); on the surface in full.
func taken_mult(e: Enemy, source: String) -> float:
	if phase == UNDER or phase == MOUND:
		return 0.0
	return super.taken_mult(e, source)


## Autopilot hint: off its dirt mound while it shows (and the ripple close by).
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != MOUND:
		return Vector2.ZERO
	var reach := float(d.get("burst_radius", 30.0)) + 18.0
	var rel := p - surface_at
	var dist := rel.length()
	if dist >= reach:
		return Vector2.ZERO
	return (rel / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0 * (0.5 + 0.5 * clampf(phase_time / maxf(float(d.get("mound_time", 1.0)), 0.01), 0.0, 1.0))


## Under the ground it is not drawn as itself: a ripple, then the mound.
func draws_body(_e: Enemy) -> bool:
	return phase == UNDER or phase == MOUND


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed
	if phase == UNDER:
		var w := 6.0 + 1.5 * sin(t * 12.0)  # A faint ripple of loose dirt.
		SpriteBank.draw_disc(ci, Vector2(0.0, 2.0), w, Color(0.30, 0.24, 0.18, 0.45))
		SpriteBank.draw_disc(ci, Vector2(0.0, 1.0), w * 0.5, Color(0.42, 0.34, 0.26, 0.5))
		return
	draw_mound(ci, Vector2.ZERO, float(d.get("mound_radius", 18.0)), clampf(phase_time / maxf(float(d.get("mound_time", 1.0)), 0.01), 0.0, 1.0), t)


## A dirt mound at `o` of `r` px (`k` 0 just breaking .. 1 about to burst): the
## `concord/burrow_mound` art scaled up as it heaves, else code discs; a slow
## shake on game time. Shared by the Hive Mother's eruption (larger).
static func draw_mound(ci: CanvasItem, o: Vector2, r: float, k: float, t: float) -> void:
	var shake := Vector2(sin(t * 40.0), 0.0) * (1.0 + k)
	var tex := SpriteBank.texture(MOUND_ART)
	if tex != null:
		var s := (r * 2.0) / maxf(float(tex.get_width()), 1.0) * (0.6 + 0.4 * k)  # Grows as it heaves.
		var size := Vector2(tex.get_width(), tex.get_height()) * s
		SpriteBank.apply_sharp(ci)
		ci.draw_texture_rect(tex, Rect2(o + shake - size * 0.5, size), false)
		return
	SpriteBank.draw_disc(ci, o + shake, r * (0.6 + 0.4 * k), Color(0.22, 0.17, 0.12, 0.9))
	SpriteBank.draw_disc(ci, o + shake + Vector2(-r * 0.2, -r * 0.25), r * (0.35 + 0.25 * k), Color(0.40, 0.31, 0.22, 0.95))
	SpriteBank.draw_disc(ci, o + shake + Vector2(r * 0.25, r * 0.15), r * 0.2, Color(0.30, 0.24, 0.17, 0.95))
