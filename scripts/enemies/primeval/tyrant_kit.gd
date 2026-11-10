## TyrantKit — the kit of the TYRANT (female / male; PrimevalEnemyData "tyrant";
## temporary Act XIV, the Age of Titans; GDD §15.0 "The Age of Titans
## foundation (phase 1)" and "The Last Day (Act XIV phase 2)"; owner-approved
## proposal: "Bite that swallows a summon for 4 s; a roar that stuns the ring
## 1.2 s | Burst; Bone Wall; the swallowed summon cuts its way out"): the
## Stampede of Ash's heavy ("Tyrants roam"), a heavy biter with a cleave (the
## shared melee AI), and, built by the Last Day:
##   * THE SWALLOW: every swallow_every s, with a grounded summon within
##     swallow_reach px of its jaws, it SWALLOWS it: the summon is held
##     (SummonedUnit.held_until: it cannot walk, but it still strikes, from
##     inside) for swallow_time s, carried along, taking swallow_dps a second (x
##     the time scaling x Thick Marrow's hook); if the Tyrant loses cut_share
##     of its max HP meanwhile, THE SUMMON CUTS ITS WAY OUT early (burst
##     damage frees it; so does the Tyrant's death). Released, it is put on a
##     free point beside it.
##   * THE ROAR: every roar_every s, with a summon within roar_radius px, it
##     rears for roar_windup s (a circle shows the roar), then every grounded
##     summon within roar_radius px is stunned roar_stun s (stun_unit()).
## Summons get no rule of their own: the hold and the stuns are enemy effects
## through the one paths. Determinism: no RNG, no instance ids. Stats:
## tyrant_swallows, tyrant_cut_out, tyrant_digest_dmg, tyrant_roars,
## tyrant_roar_stuns.
class_name TyrantKit
extends PrimevalKit

## Phase: rearing for the roar (its telegraph).
const ROAR: int = 1

## The summon it holds swallowed (null when none; generation-checked).
var prey: SummonedUnit = null
## Generation of `prey` when it was swallowed.
var prey_gen: int = 0
## Game time (s) the prey is spat out at the latest.
var prey_until: float = 0.0
## The Tyrant's HP when it swallowed (the cut-out test).
var hp_at_swallow: float = 0.0
## Seconds until the next swallow may start.
var swallow_cd: float = 0.0
## Seconds until the next roar may start.
var roar_cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	prey = null
	swallow_cd = first_cd(e, float(d.get("swallow_first", 4.0)))
	roar_cd = first_cd(e, float(d.get("roar_first", 6.0)))


## Every tick (see the header): true while the roar owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	swallow_cd -= delta
	roar_cd -= delta
	step_prey(e, delta)
	if phase == ROAR:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("roar_windup", 0.8)):
			roar(e, float(d.get("roar_radius", 110.0)), float(d.get("roar_stun", 1.2)))
			set_phase(e, IDLE)
		return true
	if roar_cd <= 0.0 and summon_near(e, float(d.get("roar_radius", 110.0))) != null:
		roar_cd = float(d.get("roar_every", 12.0))
		rules(e).play_sound("tyrant_roar", e.position, 0.5)
		set_phase(e, ROAR)
		hold(e)
		return true
	if swallow_cd <= 0.0 and prey == null:
		var u := summon_near(e, float(d.get("swallow_reach", 30.0)))
		if u != null:
			swallow_cd = float(d.get("swallow_every", 9.0))
			swallow(e, u, float(d.get("swallow_time", 4.0)))
	return false


## The nearest grounded, living summon whose edge lies within `reach` px of
## `e`'s edge (null when none).
func summon_near(e: Enemy, reach: float) -> SummonedUnit:
	e.game.ally_grid.query(e.position, e.radius + reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _buf:
		if not _can_take(u):
			continue
		var dd := u.position.distance_to(e.position) - u.radius - e.radius
		if dd <= reach and dd < best_d:
			best_d = dd
			best = u
	return best


## True for a summon the jaws or the roar can reach (grounded, living, risen).
static func _can_take(u: SummonedUnit) -> bool:
	return u.active and u.state != SummonedUnit.State.DEAD and u.state != SummonedUnit.State.SPAWNING and not u.airborne and not u.flies


## THE SWALLOW: `e` swallows summon `u` for `time` s (see the header; Old
## Gravejaw's bite uses it too).
func swallow(e: Enemy, u: SummonedUnit, time: float) -> void:
	var g := e.game
	prey = u
	prey_gen = u.generation
	prey_until = g.elapsed + time
	hp_at_swallow = e.hp
	u.held_until = maxf(u.held_until, prey_until)  # Held, not stunned: it strikes from inside (it cuts its way out).
	g.stat_add("tyrant_swallows", 1.0)
	rules(e).play_sound("tyrant_swallow", e.position, 0.3)
	e.queue_redraw()


## Carries, digests and frees the swallowed summon (see the header).
func step_prey(e: Enemy, delta: float) -> void:
	if prey == null:
		return
	var g := e.game
	if not prey.active or prey.generation != prey_gen or prey.state == SummonedUnit.State.DEAD:
		prey = null
		return
	prey.position = e.position
	prey.velocity = Vector2.ZERO
	var marrow := g.primeval.thick_marrow_mult() if g.primeval != null else 1.0  # Thick Marrow.
	var dmg := float(d.get("swallow_dps", 5.0)) * delta * hit_scale(e) * e.undead_damage_mult * marrow
	g.combat.damage_unit(prey, dmg, e.kind, e)
	g.stat_add("tyrant_digest_dmg", dmg)
	if prey == null or not prey.active or prey.generation != prey_gen:
		prey = null
		return
	var cut := hp_at_swallow - e.hp >= e.max_hp * float(d.get("cut_share", 0.12))
	if cut:
		g.stat_add("tyrant_cut_out", 1.0)
	if cut or g.elapsed >= prey_until:
		release(e)


## Spits the swallowed summon out on a free point beside `e` (its death, a
## cut-out, the time up).
func release(e: Enemy) -> void:
	if prey != null and prey.active and prey.generation == prey_gen:
		prey.position = e.game.arena.free_point(e.position + Vector2(e.radius + prey.radius + 4.0, 0.0), prey.radius)
		prey.held_until = minf(prey.held_until, e.game.elapsed)
	prey = null
	e.queue_redraw()


## THE ROAR: every grounded summon within `r` px of `e` is stunned `stun` s
## (Old Gravejaw's Roar uses it too). Returns the summons stunned.
func roar(e: Enemy, r: float, stun: float) -> int:
	var g := e.game
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0
	for u: SummonedUnit in _buf.duplicate():
		if _can_take(u) and u.position.distance_to(e.position) <= r + u.radius and g.combat.stun_unit(u, stun, e.kind) > 0.0:
			n += 1
	g.stat_add("tyrant_roars", 1.0)
	g.stat_add("tyrant_roar_stuns", float(n))
	g.effects.ring(e.position, r, Palette.PRIMEVAL_LAVA, 0.4)
	return n


func on_killed(e: Enemy) -> void:
	release(e)
	super.on_killed(e)


func on_deactivate(e: Enemy) -> void:
	release(e)
	super.on_deactivate(e)


func is_busy() -> bool:
	return phase == ROAR


## Overlay: the roar's circle while it rears; a lava glow in its belly while it
## holds a summon (visual only, disc textures).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == ROAR:
		var k := clampf(phase_time / maxf(0.01, float(d.get("roar_windup", 0.8))), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2.ZERO, float(d.get("roar_radius", 110.0)), Color(Palette.PRIMEVAL_LAVA, 0.08 + 0.16 * k))
	if prey != null:
		SpriteBank.draw_disc(ci, Vector2.ZERO, e.radius * 0.5, Color(Palette.PRIMEVAL_LAVA, 0.45))
