## PowerKit — the kit of the POWER (female, figure style; HostEnemyData
## "power"; temporary Act XIII, the Celestial Host; GDD §15.0 "The Celestial
## Host foundation (phase 1)"; proposal: "A blade of white flame; a lunge that
## cuts two summons in a line | Rogues, Gargoyles"). Every lunge "every" s,
## once her target (a summon or the necromancer) is within lunge "trigger" px,
## she plants her feet for "windup" s (a white line shows the cut), then
## LUNGES: the first "targets" bodies along the line ("reach" px long, "width"
## px wide), summons or the necromancer, nearest first, take damage_summon /
## damage_player (x the time scaling and her buffs, CombatResolver), then she
## recovers "recover" s. The pick is the Sister of the Scourge's (a stable
## insertion, no sort). Determinism: no RNG (the think-slot stagger only).
## Stats: power_lunges, power_lunge_summon_hits, power_lunge_player_hits.
class_name PowerKit
extends HostKit

## Phase: planted, the line showing.
const WINDUP: int = 1
## Phase: after the cut.
const RECOVER: int = 2
## Damage source tag of the lunge.
const SOURCE: String = "power_lunge"

## Seconds until she may lunge again.
var cd: float = 0.0
## The lunge's direction (unit vector, set at the windup).
var dir: Vector2 = Vector2.RIGHT
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float((d["lunge"] as Dictionary)["first"]))
	dir = Vector2.RIGHT


func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Current target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - body_radius(e, t) > float((d["lunge"] as Dictionary)["trigger"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.stat_add("power_lunges", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	var ln: Dictionary = d["lunge"]
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			e.queue_redraw()  # The line brightens.
			if phase_time >= float(ln["windup"]):
				_cut(e, ln)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(ln["recover"]):
				cd = float(ln["every"])
				set_phase(e, IDLE)
	return true


## The cut: the first `targets` bodies along the line, nearest first.
func _cut(e: Enemy, ln: Dictionary) -> void:
	var g := e.game
	var reach := float(ln["reach"])
	var half := float(ln["width"]) * 0.5
	var mult := hit_scale(e)  # Time scaling x aura buff.
	e.motion_lunge(dir, MotionData.POWER_MELEE)  # Engine motion (visual only).
	g.effects.beam(e.position + dir * e.radius, e.position + dir * reach, Palette.HOST_STARLIGHT)
	g.host_rules().play_sound("power_lunge", e.position, 0.2)
	var picked: Array[Node2D] = []  # Struck bodies, nearest first.
	var picked_t: Array[float] = []  # Their distance along the line (px).
	var n := int(ln["targets"])
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var t := _along(e, u.position, u.radius, reach, half)
		if t >= 0.0:
			BattleSisterKit._insert(picked, picked_t, u, t, n)
	for p in g.all_players:  # (Co-op: either necromancer can be in the line.)
		if p.dead:
			continue
		var tp := _along(e, p.position, p.radius, reach, half)
		if tp >= 0.0:
			BattleSisterKit._insert(picked, picked_t, p, tp, n)
	for b: Node2D in picked:
		if b is SummonedUnit:
			g.stat_add("power_lunge_summon_hits", 1.0)
			g.combat.damage_unit(b as SummonedUnit, float(ln["damage_summon"]) * mult * e.undead_damage_mult, SOURCE, e)
		else:
			g.stat_add("power_lunge_player_hits", 1.0)
			g.combat.damage_player(float(ln["damage_player"]) * mult, SOURCE, b as Necromancer, e)


## Distance along the line of a body of radius `r` at `pos` (-1 = not in it).
func _along(e: Enemy, pos: Vector2, r: float, reach: float, half: float) -> float:
	var rel := pos - e.position
	var t := rel.dot(dir)
	if t < -r or t > reach + r:
		return -1.0
	if absf(rel.cross(dir)) > half + r:
		return -1.0
	return maxf(0.0, t)


## The autotest autopilot's push out of the line while it shows.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	var ln: Dictionary = d["lunge"]
	if phase != WINDUP or _along(e, p, 12.0, float(ln["reach"]) + 8.0, float(ln["width"]) * 0.5 + 6.0) < 0.0:
		return Vector2.ZERO
	var side := dir.orthogonal()
	return side if (p - e.position).dot(side) >= 0.0 else -side


## The white line of the cut while she winds up, then the halo.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WINDUP:
		unmirror(e, ci)
		var ln: Dictionary = d["lunge"]
		var k := clampf(phase_time / maxf(0.01, float(ln["windup"])), 0.0, 1.0)
		var reach := float(ln["reach"])
		var step := 6.0  # px between two marks of the line.
		var s := e.radius
		while s < reach:
			ci.draw_rect(Rect2(dir * s - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.HOST_STARLIGHT, 0.35 + 0.55 * k))
			s += step
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	super.draw_over(e, ci)
