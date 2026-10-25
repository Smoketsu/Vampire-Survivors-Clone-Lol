## SentinelKit — the Sanctified Sentinel's frontal sweep (GDD §7.2
## "high-armor construct with sweeps"; its flat armour lives in
## CombatResolver.damage_enemy()). When its target (the necromancer or a
## summon) is within sweep_trigger_range, it stops, shows a gold cone toward
## it for sweep_telegraph s (EffectManager.telegraph_cone, paused while the
## Sentinel is frozen), then sweeps: every undead inside takes
## sweep_damage_summon and is shoved sweep_knockback px away from it, and a
## necromancer inside takes sweep_damage_player. Undead do not dodge (GDD
## §15.0), so a packed front line eats the whole sweep. Numbers in
## SanctumEnemyData "sanctified_sentinel".
## Stats: sentinel_sweeps, sentinel_sweep_summon_hits, sentinel_sweep_player_hits.
class_name SentinelKit
extends CovenantKit

## Phase: the cone is telegraphed.
const WINDUP: int = 1
## Phase: the short pause after the sweep.
const RECOVER: int = 2
## Seconds the Sentinel stands after a sweep (not a balance number: lets the
## swing read before it walks on).
const RECOVER_TIME: float = 0.35

## Seconds until the next sweep may start (counts down while idle).
var cd: float = 0.0
## Unit direction of the current sweep (locked at the windup).
var dir: Vector2 = Vector2.RIGHT
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["sweep_first"]))


## Starts a sweep at a target in reach.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Current target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - e.radius - body_radius(e, t) > float(d["sweep_trigger_range"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.effects.telegraph_cone(e.position, dir, float(d["sweep_radius"]), float(d["sweep_half_angle"]), float(d["sweep_telegraph"]), e)
	e.game.stat_add("sentinel_sweeps", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			e.queue_redraw()  # The raised arm glows brighter.
			if phase_time >= float(d["sweep_telegraph"]):
				_sweep(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= RECOVER_TIME:
				cd = float(d["sweep_cooldown"])
				set_phase(e, IDLE)
	return true


## The sweep lands: undead in the cone are hurt and shoved away, the
## necromancer is hurt if he stands in it.
func _sweep(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["sweep_radius"])  # Cone reach (px).
	var half := float(d["sweep_half_angle"])  # Cone half-angle (rad).
	var mult := hit_scale(e)  # Time scaling x aura buff.
	g.effects.slash(e.position + dir * e.radius, dir, Palette.GOLD, reach * 0.8, "sentinel_sweep")  # Its crescent strip when the art exists (visual only).
	e.motion_lunge(dir, MotionData.POWER_MELEE)  # Engine motion: the sweep (visual only).
	g.effects.ring(e.position + dir * reach * 0.5, reach * 0.45, Palette.IVORY, 0.25)
	Sfx.play("abom_stomp", e.position, 1.25)
	var hits := 0  # Summons struck.
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			continue
		hits += 1
		var away := u.position - e.position  # Shove direction.
		u.position += (away.normalized() if away.length() > 0.5 else dir) * float(d["sweep_knockback"])
		g.combat.damage_unit(u, float(d["sweep_damage_summon"]) * mult * e.undead_damage_mult, "sentinel_sweep")
	g.stat_add("sentinel_sweep_summon_hits", float(hits))
	for p in g.all_players:  # (Co-op: every necromancer inside.)
		if in_sector(e.position, dir, reach, half, e.radius, p.position, p.radius):
			g.stat_add("sentinel_sweep_player_hits", 1.0)
			g.combat.damage_player(float(d["sweep_damage_player"]) * mult, "sentinel_sweep", p)


## Autopilot hint: out of the telegraphed cone.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP or not in_sector(e.position, dir, float(d["sweep_radius"]) + 24.0, float(d["sweep_half_angle"]), e.radius, p, 12.0):
		return Vector2.ZERO
	var away := p - e.position
	return away.normalized() if away.length() > 0.1 else -dir


## A raised stone arm while the sweep winds up.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WINDUP:
		unmirror(e, ci)
		CovenantFx.base = Transform2D(0.0, Vector2(e.scale.x, 1.0), 0.0, Vector2.ZERO)  # The arm's art in world axes too.
		SanctumGlyphs.draw_sweep_windup(ci, dir, e.radius, phase_time / maxf(0.01, float(d["sweep_telegraph"])))
		CovenantFx.base = Transform2D.IDENTITY
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
