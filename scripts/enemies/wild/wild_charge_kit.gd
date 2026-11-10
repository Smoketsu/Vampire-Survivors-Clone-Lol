## WildChargeKit — the shared CHARGE of the Wild Hunt's kinds (temporary Act XV,
## the Turning Year; GDD §15.0 "The Greenwood (Act XV phase 2)"): the base of the
## Great Stag ("a telegraphed antler charge that scatters the ring"), the Rider of
## the Wild Hunt ("sweeps across the arena in a line"), its hounds and the
## Huntsman of the Wild Hunt (the Greenwood's miniboss: "three riders in a
## sweeping line"). Not a kind's kit itself (no row names "wild_charge"). The
## shared melee AI walks the kind in; then:
##   * WINDUP: every charge_every s (0 = never on its own: a hound runs only when
##     its rider leads it), once a standing necromancer is within charge_trigger
##     px, it holds for charge_windup s while a line shows the charge (aimed
##     through him, so it crosses the ring).
##   * CHARGE: it runs charge_speed px/s up to charge_len px along the line;
##     every grounded summon and necromancer it crosses is hit once
##     (WildKit.trample(), the one Wild trample): summons take charge_damage (x
##     the time scaling), are stunned charge_stun s and thrown charge_knock px
##     aside; the necromancer takes charge_player.
##   * LEAD: a leader (the Rider its hounds, the Huntsman his riders) calls
##     lead() on a follower: it blinks to its place in the line and charges
##     along the leader's line with the leader's windup; while its leader lives
##     a follower never starts a charge of its own.
## Subclasses hook _on_begin() (the charge's windup begins: a leader leads its
## followers here). Determinism: no RNG, no instance ids. Stats per kind:
## <kind>_charges, <kind>_charge_hits, <kind>_charge_on_you.
class_name WildChargeKit
extends WildKit

## Phase: the windup (the telegraph).
const WINDUP: int = 1
## Phase: the charge.
const CHARGE: int = 2

## Seconds until the next charge may start.
var cd: float = 0.0
## The charge's direction (unit).
var charge_dir: Vector2 = Vector2.RIGHT
## px of the charge run so far.
var charge_run: float = 0.0
## Seconds this windup lasts (charge_windup, or the leader's).
var windup: float = 1.0
## Bodies (SummonedUnit, Necromancer) this charge already hit.
var hit: Array = []
## The leader this follower runs with (null when free; generation-checked).
var leader: Enemy = null
## Generation of `leader` when it took this follower.
var leader_gen: int = 0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("charge_first", 3.0)))
	hit.clear()
	leader = null
	windup = float(d.get("charge_windup", 1.0))


## True while this follower's leader still lives.
func led() -> bool:
	if leader != null and not (leader.active and leader.generation == leader_gen):
		leader = null
	return leader != null


## LEAD: follower `e` blinks to `at` and charges along `dir` after `p_windup`
## s, with leader `by` (generation-checked).
func lead(e: Enemy, by: Enemy, at: Vector2, dir: Vector2, p_windup: float) -> void:
	leader = by
	leader_gen = by.generation
	e.position = e.game.arena.free_point(at, e.radius)
	charge_dir = dir
	windup = p_windup
	set_phase(e, WINDUP)
	hold(e)


## Every tick (see the header): true while a phase owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= windup:
				charge_run = 0.0
				hit.clear()
				e.motion_lunge(charge_dir, MotionData.POWER_CAST)
				set_phase(e, CHARGE)
			return true
		CHARGE:
			var step := float(d.get("charge_speed", 320.0)) * delta
			e.velocity = charge_dir * step / maxf(delta, 0.0001)
			e.position += charge_dir * step
			e._update_facing()
			charge_run += step
			var ts := hit_scale(e)
			var before := hit.size()
			var n := trample(g, e.position, e.radius, hit, float(d.get("charge_damage", 8.0)) * ts * e.undead_damage_mult,
					float(d.get("charge_player", 7.0)) * ts, float(d.get("charge_stun", 0.5)), float(d.get("charge_knock", 28.0)),
					charge_dir, e.kind, e, _buf)
			if n > 0:
				g.stat_add(e.kind + "_charge_hits", float(n))
				for i in range(before, hit.size()):
					if hit[i] is Necromancer:
						g.stat_add(e.kind + "_charge_on_you", 1.0)
			if charge_run >= float(d.get("charge_len", 260.0)) or g.arena.is_blocked(e.position + charge_dir * (step + e.radius * 0.6), e.radius * 0.5):
				e.position = g.arena.free_point(e.position, e.radius)
				windup = float(d.get("charge_windup", 1.0))
				set_phase(e, IDLE)
			return true
	if cd <= 0.0 and float(d.get("charge_every", 0.0)) > 0.0 and not led():
		var pl := g.nearest_player(e.position)
		if pl != null and not pl.dead and pl.position.distance_to(e.position) <= float(d.get("charge_trigger", 260.0)):
			cd = float(d.get("charge_every", 8.0))
			var to := pl.position - e.position
			charge_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
			windup = float(d.get("charge_windup", 1.0))
			g.stat_add(e.kind + "_charges", 1.0)
			rules(e).play_sound("hunt_charge", e.position, 0.4)
			set_phase(e, WINDUP)
			hold(e)
			_on_begin(e)
			return true
	return false


## Hook: the charge's windup began (a leader leads its followers here).
func _on_begin(_e: Enemy) -> void:
	pass


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the charge's line while it winds up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	return line_push(e.position, charge_dir, float(d.get("charge_len", 260.0)), e.radius, p)


## Overlay: the charge's line while it winds up (visual only, rects in world axes).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP:
		return
	unmirror(e, ci)
	draw_line_marks(ci, Vector2.ZERO, charge_dir, e.radius, float(d.get("charge_len", 260.0)), clampf(phase_time / maxf(0.01, windup), 0.0, 1.0))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
