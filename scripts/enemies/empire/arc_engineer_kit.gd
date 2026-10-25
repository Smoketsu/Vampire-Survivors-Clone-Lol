## ArcEngineerKit — the Arc Engineer's kit (AssemblyEnemyData "arc_engineer", a
## support CYBORG; Act III, the Assembly Halls; GDD §15.0 "The Assembly Halls
## (Act III phase 2)"; owner-approved proposal: "Repairs machines and briefly
## jams nearby summons (2 s, the existing suppression rule). Priority target,
## like the High Confessor"). It advances on the necromancer like every ranged
## kind and fires single arc bolts through EmpireShots (EmpireKit's marching
## fire: Line of Fire applies), and between them:
##   Repair — every repair_interval s the repair_targets most damaged MACHINES
##            within repair_radius px (drones, Juggernauts, fabricators,
##            turrets; never a boss or a miniboss) regain repair_share of their
##            max HP (at least repair_min) through CombatResolver.heal_enemy()
##            with itself as the healer, so a Keening Lady's Dirge silences it.
##   Jam    — when a summon is within jam_trigger px (every jam_cooldown s) it
##            stands still jam_hold s and lays a static field on that summon:
##            THE suppression path (HordeDirector.add_suppression(): its
##            telegraph, then jam_duration s in which the summons inside hit at
##            jam_damage_mult and no replacement rises there).
## It ranks high on every summon's target list through its row's
## target_priority (the existing path). A CYBORG: raised, it rises as a Grave
## Gunner. No RNG. Stats: arc_repairs, arc_repaired_hp, arc_jams.
class_name ArcEngineerKit
extends EmpireKit

## Phase: casting the jam (held still).
const JAMMING: int = 1
## Damage / suppression source tag of the jam (SuppressionField stats).
const JAM_SOURCE: String = "arc_engineer"
## Seconds a repair arc stays drawn (visual only).
const ARC_FX_TIME: float = 0.35

## Seconds until the next repair.
var repair_cd: float = 0.0
## Seconds until the next jam may start.
var jam_cd: float = 0.0
## World point of the current / last static field.
var jam_at: Vector2 = Vector2.ZERO
## Repair arcs being drawn: [machine Enemy, its generation, game time drawn].
var _arcs: Array = []
## Candidate [missing share, machine] pairs of a repair (reused).
var _cands: Array = []
## Reusable spatial-hash query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	repair_cd = first_cd(e, float(d["repair_first"]))
	jam_cd = first_cd(e, float(d["jam_first"]))
	_arcs.clear()


## Repairs on its clock; starts a jam on a summon in reach.
func think(e: Enemy) -> void:
	if repair_cd <= 0.0:
		repair_cd = float(d["repair_interval"])
		_repair(e)
	if phase != IDLE or jam_cd > 0.0:
		return
	var g := e.game
	var reach := float(d["jam_trigger"])
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null  # Nearest summon in reach.
	var best_d := reach
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dist := u.position.distance_to(e.position)
		if dist < best_d:
			best_d = dist
			best = u
	if best == null:
		return
	jam_at = best.position
	jam_cd = float(d["jam_cooldown"])
	g.horde.add_suppression(jam_at, float(d["jam_radius"]), float(d["jam_duration"]), float(d["jam_damage_mult"]), float(d["jam_telegraph"]), JAM_SOURCE)
	g.stat_add("arc_jams", 1.0)
	Sfx.play("arc_jam", jam_at)
	set_phase(e, JAMMING)


## Marching fire, the timers, and the short hold while it jams.
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	repair_cd -= delta
	jam_cd -= delta
	if not _arcs.is_empty():
		e.queue_redraw()
	if phase == JAMMING:
		phase_time += delta
		hold(e)
		if phase_time >= float(d["jam_hold"]):
			set_phase(e, IDLE)
		return true
	return false


## Repairs the most damaged machines in reach (see the header).
func _repair(e: Enemy) -> void:
	var g := e.game
	var r := float(d["repair_radius"])
	g.enemy_grid.query(e.position, r, _tmp)
	_cands.clear()
	for m: Enemy in _tmp:
		if m == e or not m.active or m.body != EmpireEnemyData.MACHINE or m.is_boss or m.is_miniboss or m.hp >= m.max_hp:
			continue
		if m.position.distance_to(e.position) > r:
			continue
		_cands.append([1.0 - m.hp / m.max_hp, m])
	if _cands.is_empty():
		return
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var healed_any := false
	for k in mini(int(d["repair_targets"]), _cands.size()):
		var m: Enemy = _cands[k][1]
		var amount := maxf(float(d["repair_min"]), m.max_hp * float(d["repair_share"]))
		var healed := g.combat.heal_enemy(m, amount, e)
		if healed > 0.0:
			healed_any = true
			g.stat_add("arc_repaired_hp", healed)
			_arcs.append([m, m.generation, g.elapsed])
	if healed_any:
		g.stat_add("arc_repairs", 1.0)
		Sfx.play("arc_repair", e.position)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the arc emitter pulses (visual only).


## Repair arcs to the machines it patched, and its static field while it casts.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	var now := e.game.elapsed
	var i := _arcs.size() - 1
	while i >= 0:
		var a: Array = _arcs[i]
		var m: Enemy = a[0]
		var age := now - float(a[2])
		if age > ARC_FX_TIME or not m.active or m.generation != int(a[1]):
			_arcs.remove_at(i)
		else:
			AssemblyGlyphs.draw_arc_beam(ci, Vector2(e.radius * 0.6, -e.radius * 0.4), m.position - e.position, 1.0 - age / ARC_FX_TIME)
		i -= 1
	if phase == JAMMING:
		CovenantFx.base = Transform2D(0.0, Vector2(e.scale.x, 1.0), 0.0, Vector2.ZERO)  # The field art in world axes too.
		AssemblyGlyphs.draw_jam_field(ci, jam_at - e.position, float(d["jam_radius"]), clampf(phase_time / maxf(0.01, float(d["jam_hold"])), 0.0, 1.0))
		CovenantFx.base = Transform2D.IDENTITY
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
