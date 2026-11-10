## HornchargerKit — the kit of the HORNCHARGER (PrimevalEnemyData "horncharger";
## temporary Act XIV, the Great Plain; GDD §15.0 "The Great Plain (Act XIV
## phase 2)"; owner-approved proposal: "Horncharger (male) | Heavy |
## Telegraphed straight charge that stuns summons; stuck in a rock for 2 s on a
## miss | Dodge by Grave Step; Bone Wall"). A three-horned ceratopsian. The
## shared melee AI walks it in; then:
##   * WINDUP: every charge_every s, once a summon or necromancer stands within
##     charge_trigger px, it paws the ground for charge_windup s; a line shows
##     the charge.
##   * CHARGE: it runs charge_speed px/s up to charge_len px along the line;
##     every grounded summon and necromancer it crosses is hit once (gore(),
##     the one charge hit, shared with Old Ironbrow): summons take
##     charge_damage (x the time scaling x Thick Marrow's hook), are STUNNED
##     charge_stun s (CombatResolver.stun_unit(), the one summon stun path) and
##     thrown charge_knock px aside; the necromancer takes charge_player.
##   * STUCK: a charge that runs into a rock (rock_ahead(): an obstacle in the
##     next step) stops there, horns in the stone, for stuck_time s.
## A freeze or stun holds it like any kit (Enemy). Determinism: no RNG, no
## instance ids. Stats: horn_charges, horn_charge_hits, horn_charge_on_you,
## horn_stuck.
class_name HornchargerKit
extends PrimevalKit

## Phase: pawing the ground (the telegraph).
const WINDUP: int = 1
## Phase: the charge.
const CHARGE: int = 2
## Phase: stuck in a rock.
const STUCK: int = 3
## px between two drawn marks of the charge's line (visual only).
const MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only

## Seconds until the next charge may start.
var cd: float = 0.0
## The charge's direction (unit).
var charge_dir: Vector2 = Vector2.RIGHT
## px of the charge run so far.
var charge_run: float = 0.0
## Bodies (SummonedUnit, Necromancer) this charge already hit.
var hit: Array = []
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("charge_first", 2.5)))
	hit.clear()


## Every tick (see the header): true while a phase owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("charge_windup", 0.9)):
				charge_run = 0.0
				hit.clear()
				e.motion_lunge(charge_dir, MotionData.POWER_CAST)
				set_phase(e, CHARGE)
			return true
		CHARGE:
			var step := float(d.get("charge_speed", 330.0)) * delta
			if rock_ahead(g, e.position, charge_dir, step, e.radius):
				g.stat_add("horn_stuck", 1.0)
				e.game.effects.impact(e.position + charge_dir * e.radius, e.radius, Palette.PRIMEVAL_OCHRE)
				set_phase(e, STUCK)
				hold(e)
				return true
			e.velocity = charge_dir * step / maxf(delta, 0.0001)
			e.position += charge_dir * step
			e._update_facing()
			charge_run += step
			var ts := hit_scale(e)
			var n := gore(e, hit, float(d.get("charge_damage", 9.0)) * ts, float(d.get("charge_player", 8.0)) * ts,
					float(d.get("charge_stun", 1.0)), float(d.get("charge_knock", 30.0)), charge_dir, e.kind, _buf)
			if n > 0:
				g.stat_add("horn_charge_hits", float(n))
			if charge_run >= float(d.get("charge_len", 240.0)):
				set_phase(e, IDLE)
			return true
		STUCK:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("stuck_time", 2.0)):
				set_phase(e, IDLE)
			return true
	if cd <= 0.0:
		var t := e.target if e.target != null and e._target_valid() else g.nearest_player(e.position)
		if t != null and t.position.distance_to(e.position) <= float(d.get("charge_trigger", 260.0)):
			cd = float(d.get("charge_every", 7.0))
			var to := t.position - e.position
			charge_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
			g.stat_add("horn_charges", 1.0)
			rules(e).play_sound("horn_charge", e.position, 0.3)
			set_phase(e, WINDUP)
			hold(e)
			return true
	return false


## True when a body of radius `r` at `p` would run into an obstacle within
## `step` px along `dir` (a rock: the charge stops there).
static func rock_ahead(g: Game, p: Vector2, dir: Vector2, step: float, r: float) -> bool:
	return g.arena.is_blocked(p + dir * (step + r * 0.6), r * 0.5)


## THE one charge hit (the Horncharger and Old Ironbrow): every grounded summon
## and standing necromancer touching charger `e` that `hit` does not hold yet
## is hit once: a summon takes `dmg_summon` x Thick Marrow (CombatResolver
## .damage_unit()), is stunned `stun` s (CombatResolver.stun_unit()) and
## thrown `knock` px sideways off the line `dir`; a necromancer takes
## `dmg_player`. Tag `source`. Returns how many bodies it hit.
static func gore(e: Enemy, hit: Array, dmg_summon: float, dmg_player: float, stun: float, knock: float, dir: Vector2, source: String, buf: Array) -> int:
	var g := e.game
	var n := 0
	var marrow := g.primeval.thick_marrow_mult() if g.primeval != null else 1.0  # Thick Marrow (the Last Day builds it; 1 until then).
	g.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, buf)
	for u: SummonedUnit in buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies or hit.has(u):
			continue
		if u.position.distance_to(e.position) > e.radius + u.radius + 2.0:
			continue
		hit.append(u)
		g.combat.damage_unit(u, dmg_summon * marrow * e.undead_damage_mult, source, e)
		if u.active and stun > 0.0:
			g.combat.stun_unit(u, stun, source)
		var side := dir.orthogonal()
		u.position += side * knock * (1.0 if (u.position - e.position).dot(side) >= 0.0 else -1.0)
		n += 1
	for pl in g.all_players:
		if pl.dead or hit.has(pl) or pl.position.distance_to(e.position) > e.radius + pl.radius + 2.0:
			continue
		hit.append(pl)
		g.combat.damage_player(dmg_player, source, pl, e)
		g.stat_add("horn_charge_on_you", 1.0)
		n += 1
	return n


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the charge's line while it paws the ground.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	return line_push(e.position, charge_dir, float(d.get("charge_len", 240.0)), e.radius, p)


## The push sideways out of a charge line from `from` along `dir`, `len` px
## long, `r` px half wide, at `p` (Vector2.ZERO off the line).
static func line_push(from: Vector2, dir: Vector2, len: float, r: float, p: Vector2) -> Vector2:
	var rel := p - from
	var along := rel.dot(dir)
	if along < 0.0 or along > len + 24.0:
		return Vector2.ZERO
	var lat := rel.dot(dir.orthogonal())
	if absf(lat) > r + 24.0:
		return Vector2.ZERO
	return dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)


## Overlay: the charge's line while it paws the ground (visual only, rects in
## world axes).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP:
		return
	unmirror(e, ci)
	var k := clampf(phase_time / maxf(0.01, float(d.get("charge_windup", 0.9))), 0.0, 1.0)
	draw_line_marks(ci, Vector2.ZERO, charge_dir, e.radius, float(d.get("charge_len", 240.0)), k)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draws a charge's telegraph on `ci`: marks every MARK_STEP px from `from`
## along `dir`, from `start` to `len` px, brighter as `k` (0..1) grows.
static func draw_line_marks(ci: CanvasItem, from: Vector2, dir: Vector2, start: float, len: float, k: float) -> void:
	var s := start
	while s < len:
		ci.draw_rect(Rect2(from + dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.PRIMEVAL_LAVA, 0.3 + 0.55 * k))
		s += MARK_STEP
