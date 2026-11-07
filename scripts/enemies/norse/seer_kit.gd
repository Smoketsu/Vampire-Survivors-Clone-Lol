## SeerKit — the kit of the Seer (NorseEnemyData "seer"; the Hall of the Slain,
## temporarily Act XI; GDD §15.0 "Rune-Stones"; owner-approved proposal: "Seer
## (female, figure style) | Support | Re-carves Rune-Stones; a curse that
## weakens one summon | Kill on the way to a stone"). Two specials:
##   * THE RE-CARVING (rule 3): while a TAKEN stone lies within carve_seek px
##     (RuneStones.nearest_taken()), she walks to it instead of advancing on
##     the necromancer, and standing within carve_radius px she carves it
##     (RuneStones.carve(), x carve_rate): carve_time s give it back to the
##     hall. She fights nothing on the way (kill her on the way).
##   * THE CURSE: every curse_every s, when a summon is within curse_range px,
##     a pale rune hangs over it for curse_windup s, then the summon is
##     BLINDED for curse_time s (CombatResolver.blind_unit(), the one summon
##     blind path: it keeps to the ring but cannot find a foe: weakened to
##     nothing for a while). Her target first, else the nearest summon.
## No RNG. Stats: seer_walks (ticks walking to a stone), seer_carve_seconds,
## seer_curses, seer_curse_hits.
class_name SeerKit
extends NorseKit

## Phase: the curse's rune hangs over its summon (the windup).
const CURSE: int = 1

## Seconds until the next curse may start.
var _cd: float = 0.0
## The cursed summon (locked at the windup).
var _victim: SummonedUnit = null
## Generation of `_victim` when locked (stale guard).
var _victim_gen: int = 0
## Scratch for the grid query.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("curse_every", 8.0)) * 0.5)
	_victim = null


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	_cd -= delta
	if phase == CURSE:
		phase_time += delta
		if phase_time >= float(d.get("curse_windup", 0.6)):
			_curse(e)
			set_phase(e, IDLE)
	# The re-carving walk (owns the tick while a taken stone is near).
	if g.norse != null and not g.norse.stones.stones.is_empty():
		var st := g.norse.stones
		var idx := st.nearest_taken(e.position, float(st.cfg["carve_seek"]))
		if idx >= 0:
			var to := st.stones[idx].pos - e.position
			var reach := float(st.cfg["carve_radius"])
			if to.length() > reach:
				var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
				e.velocity = to.normalized() * spd + e.sep * spd * EnemyData.SEPARATION_STRENGTH
				e.position += (e.velocity + e.knockback) * delta
				g.stat_add("seer_walks", 1.0)
			else:
				hold(e)
				st.carve(idx, delta * float(d.get("carve_rate", 1.0)))
				g.stat_add("seer_carve_seconds", delta)
			return true
	if phase == IDLE and _cd <= 0.0:
		var u := _pick(e)
		if u != null:
			_cd = float(d.get("curse_every", 8.0))
			_victim = u
			_victim_gen = u.generation
			g.stat_add("seer_curses", 1.0)
			set_phase(e, CURSE)
	return false


## Her curse's summon: her target when it is a summon in range, else the
## nearest summon in range (null when none).
func _pick(e: Enemy) -> SummonedUnit:
	var r := float(d.get("curse_range", 190.0))
	if e.target is SummonedUnit:
		var t := e.target as SummonedUnit
		if t.active and t.state != SummonedUnit.State.DEAD and t.position.distance_to(e.position) <= r:
			return t
	var best: SummonedUnit = null
	var best_d := r * r
	e.game.ally_grid.query(e.position, r, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		var dsq := u.position.distance_squared_to(e.position)
		if dsq < best_d:
			best_d = dsq
			best = u
	return best


## The curse lands: the locked summon is blinded.
func _curse(e: Enemy) -> void:
	var u := _victim
	_victim = null
	if u == null or not u.active or u.generation != _victim_gen or u.state == SummonedUnit.State.DEAD:
		return
	if e.game.combat.blind_unit(u, float(d.get("curse_time", 2.5)), e.kind) > 0.0:
		e.game.stat_add("seer_curse_hits", 1.0)
		e.game.effects.ring(u.position, 16.0, Palette.NORSE_RUNE, 0.4)


## Over her: the curse's pale rune, drawn over her own head while it gathers.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	if phase != CURSE:
		return
	unmirror(e, ci)
	SpriteBank.draw_disc(ci, Vector2(0.0, e.marker_y(-e.radius * 1.4) - 6.0), 3.0, Color(Palette.NORSE_RUNE, 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
