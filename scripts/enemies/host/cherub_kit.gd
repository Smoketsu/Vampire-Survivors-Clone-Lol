## CherubKit — the kit of the CHERUB (HostEnemyData "cherub", a guardian) and
## of the Silver Stair's miniboss THE CHERUB OF THE GATE (SilverStairEnemyData
## "cherub_of_the_gate"; temporary Act XIII, the Celestial Host; GDD §15.0
## "The Silver Stair (Act XIII phase 2)"; owner-approved proposal: "Four faces,
## four wings full of eyes and a flaming sword that sweeps all around it |
## Siegecraft; stay out of reach" and "the Cherub of the Gate, whose flaming
## sword turns in a full circle every 6 s"). Its row's "sword":
##   * every > 0 (the Cherub): every `every` s (the first `first` s after it
##     arrives), once a summon or a standing necromancer is within `reach` px,
##     it plants itself for `windup` s (a ring telegraph round it; the autotest
##     bot steps out), then its sword turns `turns` full circles in
##     turns x `turn` s while it walks on;
##   * every <= 0 (the Cherub of the Gate): the sword never stops turning, one
##     full circle every `turn` s, from `first` s after it arrives.
## THE CUT: each tick the blade sweeps the angle it turned (the one blade test,
## sweep(): a body's angular width counts), and every summon and necromancer
## within reach that it passes takes damage_summon / damage_player (x the time
## scaling and its aura buff) through damage_unit() / damage_player(): once a
## pass. A row with "miniboss" registers on the HUD's miniboss bar and drops
## its XP burst (reward_xp in reward_crystals) when it falls; ChestManager
## drops the miniboss chest. Seraiel's Sword uses sweep() too.
## Determinism: no RNG (the think-slot stagger; the blade's angle on game time).
## Stats: cherub_sweeps, cherub_cuts (bodies cut), cherub_gate_kills,
## cherub_gate_ttk; damage as player_dmg_from_cherub_sword /
## summon_dmg_from_cherub_sword.
class_name CherubKit
extends HostKit

## Phase: planted, the ring telegraph showing.
const WINDUP: int = 1
## Phase: the sword turning.
const SWEEP: int = 2
## Damage source tag of the Cherub's sword (stats, the death line).
const SOURCE: String = "cherub_sword"
## px the autotest bot keeps beyond the blade's reach (autotest hint only).
const DANGER_MARGIN: float = 24.0  # TUNING (not in GDD) autotest hint only
## px under which a body's angular width is measured as at this distance (a
## body on top of the hilt is always cut).
const MIN_HIT_DIST: float = 6.0  # TUNING (not in GDD)
## px between two drawn marks of the blade (visual only).
const MARK_STEP: float = 5.0  # TUNING (not in GDD) visual only

## Seconds until the next sweep may start (periodic swords).
var cd: float = 0.0
## The blade's angle now (rad).
var angle: float = 0.0
## Radians the blade still has to turn this sweep (periodic swords).
var left: float = 0.0
## Game time (s) it arrived (the miniboss's time to kill).
var spawned_at: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(_sword()["first"]))
	angle = float(e.think_slot) * 0.7  # A different start per think slot (no RNG).
	left = 0.0
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## The row's sword dictionary.
func _sword() -> Dictionary:
	return d["sword"]


## True when the sword never stops turning (the Cherub of the Gate).
func continuous() -> bool:
	return float(_sword()["every"]) <= 0.0


## True while the blade cuts (a sweep turning, or a continuous sword drawn).
func armed() -> bool:
	return phase == SWEEP or (continuous() and cd <= 0.0)


func physics(e: Enemy, delta: float) -> bool:
	var sw := _sword()
	var rate := TAU / maxf(0.1, float(sw["turn"]))  # rad/s.
	if continuous():
		if cd > 0.0:
			cd -= delta
			return false
		_turn(e, rate * delta, sw)
		e.queue_redraw()
		return false
	match phase:
		IDLE:
			cd -= delta
			if cd <= 0.0 and _body_near(e, float(sw["reach"])):
				set_phase(e, WINDUP)
				e.game.effects.telegraph_circle(e.position, float(sw["reach"]), float(sw["windup"]), e)
				hold(e)
				return true
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(sw["windup"]):
				left = TAU * float(maxi(1, int(sw["turns"])))
				e.game.stat_add("cherub_sweeps", 1.0)
				e.game.host_rules().play_sound("cherub_sword", e.position, 0.3)
				set_phase(e, SWEEP)
			return true
		SWEEP:
			var da := minf(rate * delta, left)
			_turn(e, da, sw)
			left -= da
			e.queue_redraw()
			if left <= 0.0001:
				cd = float(sw["every"])
				set_phase(e, IDLE)
	return false


## The blade turns `da` rad: every body it passes is cut.
func _turn(e: Enemy, da: float, sw: Dictionary) -> void:
	var mult := hit_scale(e)  # Time scaling x aura buff.
	var n := sweep(e.game, e.position, angle, da, float(sw["reach"]), float(sw["damage_summon"]) * mult * e.undead_damage_mult,
			float(sw["damage_player"]) * mult, SOURCE, e, _tmp)
	if n > 0:
		e.game.stat_add("cherub_cuts", float(n))
	angle = wrapf(angle + da, 0.0, TAU)


## THE ONE BLADE TEST (the Cherubs, Seraiel's Sword): a blade from `origin`,
## `reach` px long, turns from angle `a0` by `da` rad (counter-clockwise, da >
## 0): every summon and standing necromancer whose body it passes takes
## `dmg_summon` / `dmg_player` (already scaled) tagged `source` from `by`.
## `buf` is the caller's query buffer. Returns the bodies cut.
static func sweep(g: Game, origin: Vector2, a0: float, da: float, reach: float, dmg_summon: float, dmg_player: float,
		source: String, by: Enemy, buf: Array) -> int:
	var n := 0
	g.ally_grid.query(origin, reach + UnitData.MAX_BLOCK_RADIUS, buf)
	for u: SummonedUnit in buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if _passed(origin, a0, da, reach, u.position, u.radius):
			g.combat.damage_unit(u, dmg_summon, source, by)
			n += 1
	for pl in g.all_players:  # (Co-op: either necromancer can be in its path.)
		if not pl.dead and _passed(origin, a0, da, reach, pl.position, pl.radius):
			g.combat.damage_player(dmg_player, source, pl, by)
			n += 1
	return n


## True when a body of radius `r` at `p` lies within `reach` of `origin` and
## the blade turning from `a0` by `da` reaches its leading edge in this step:
## the steps of one pass tile the circle half-open, so a body is cut exactly
## once a pass, as the blade first touches it.
static func _passed(origin: Vector2, a0: float, da: float, reach: float, p: Vector2, r: float) -> bool:
	var rel := p - origin
	var dist := rel.length()
	if dist > reach + r:
		return false
	var tol := r / maxf(dist, MIN_HIT_DIST)  # Angular half-width of its body (rad).
	return wrapf(rel.angle() + tol - a0, 0.0, TAU) < da  # Its leading edge, past the blade's start.


## True when a summon or a standing necromancer is within `r` px of it.
func _body_near(e: Enemy, r: float) -> bool:
	var g := e.game
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			return true
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= r + u.radius:
			return true
	return false


## The miniboss's XP burst and the stats of its fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if not bool(d.get("miniboss", false)):
		return
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.HOST_STARLIGHT)
	g.shake(8.0)
	g.stat_add("cherub_gate_kills", 1.0)
	g.stat_add("cherub_gate_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the blade's reach while it turns or winds up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == IDLE and not (continuous() and cd <= 0.0):
		return Vector2.ZERO
	var reach := float(_sword()["reach"]) + DANGER_MARGIN
	var off := p - e.position
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 3.0


## The flaming sword while it turns (marks of white flame with a cerulean
## edge along the blade), then the halo. Visual only: rects.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if armed():
		unmirror(e, ci)
		var reach := float(_sword()["reach"])
		var dir := Vector2.from_angle(angle)
		var s := e.radius * 0.6
		while s < reach:
			var p := dir * s
			ci.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.HOST_CERULEAN, 0.55))
			ci.draw_rect(Rect2(p - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Palette.HOST_STARLIGHT)
			s += MARK_STEP
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	super.draw_over(e, ci)
