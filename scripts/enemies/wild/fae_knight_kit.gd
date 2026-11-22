## FaeKnightKit — the kit of the FAE KNIGHT (male; WildEnemyData "fae_knight";
## temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood (Act XV phase
## 2)"; owner-approved proposal: "Fae Knight (male) | Soldier | Leaf armour and a
## thorn sword; short blinks through the ring | Blockers inside the ring"). The
## plain melee AI walks it in; every blink_every s, while the nearest standing
## necromancer is more than blink_min px away and at least one summon stands
## between them (within blink_lane px of the line), it gathers itself for
## blink_warn s (leaves swirl round it) and BLINKS blink_dist px toward him,
## through the ring, landing no nearer than blink_keep px to him
## (Arena.free_point(): never inside an obstacle). Blockers standing inside the
## ring catch it there. Determinism: no RNG, no instance ids. Stats:
## fae_blinks.
class_name FaeKnightKit
extends WildKit

## Phase: gathering itself (the telegraph).
const GATHER: int = 1

## Seconds until the next blink may start.
var cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("blink_first", 3.0)))


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	if phase == GATHER:
		phase_time += delta
		hold(e)
		if phase_time < float(d.get("blink_warn", 0.35)):
			return true
		set_phase(e, IDLE)
		var pl := g.nearest_player(e.position)
		if pl == null or pl.dead:
			return false
		var to := pl.position - e.position
		var dist := to.length()
		var hop := minf(float(d.get("blink_dist", 110.0)), dist - float(d.get("blink_keep", 40.0)) - pl.radius - e.radius)
		if hop > 8.0:
			e.position = g.arena.free_point(e.position + to / dist * hop, e.radius)
			g.effects.ring(e.position, e.radius * 1.6, Palette.WILD_MOSS, 0.25)
			g.stat_add("fae_blinks", 1.0)
			rules(e).play_sound("blink", e.position, 0.3)
		return false
	if cd > 0.0:
		return false
	var p := g.nearest_player(e.position)
	if p == null or p.dead:
		return false
	var off := p.position - e.position
	var dist2 := off.length()
	if dist2 <= float(d.get("blink_min", 120.0)):
		return false
	cd = 0.5  # Look again soon when no summon stands in the way.
	var dir := off / dist2
	var lane := float(d.get("blink_lane", 30.0))
	g.ally_grid.query(e.position + off * 0.5, dist2 * 0.5 + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var rel := u.position - e.position
		var along := rel.dot(dir)
		if along > 0.0 and along < dist2 and absf(rel.dot(dir.orthogonal())) <= lane + u.radius:
			cd = float(d.get("blink_every", 7.0))
			set_phase(e, GATHER)
			hold(e)
			return true
	return false


func is_busy() -> bool:
	return phase != IDLE


## Overlay: leaves swirling round it while it gathers itself (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != GATHER:
		return
	var k := clampf(phase_time / maxf(0.01, float(d.get("blink_warn", 0.35))), 0.0, 1.0)
	for i in 6:
		var a := TAU * float(i) / 6.0 + k * 3.0
		ci.draw_rect(Rect2(Vector2(cos(a), sin(a)) * e.radius * (1.6 - 0.6 * k) - Vector2(1.5, 1.0), Vector2(3.0, 2.0)), Color(Palette.WILD_MOSS, 0.5 + 0.4 * k))
