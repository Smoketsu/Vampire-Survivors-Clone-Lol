## SoheiKit — the kit of the Sōhei (SunRoadEnemyData "sohei"; Act V, the Road
## to the Sun; GDD §15.0 "The Road to the Sun (Act V phase 2)"; owner-approved
## brief: "Sōhei: a warrior monk with a naginata; soldier, a sweeping cut").
## When its target (the necromancer or a summon) is within sweep_trigger_range
## px and the cut is ready, it stops, shows a cone toward it for
## sweep_telegraph s (EffectManager.telegraph_cone, paused while it is frozen),
## then sweeps the naginata: every summon in the arc takes sweep_damage_summon
## and is thrown sweep_knockback px back, a necromancer in it takes
## sweep_damage_player (both x the enemies' time scaling x its buffs). Undead
## do not dodge (GDD §15.0): a packed front line takes the whole arc. The
## autotest bot steps out of the cone. No RNG (first cut staggered by the think
## slot). Stats: sohei_sweeps, sohei_sweep_summon_hits, sohei_sweep_player_hits.
class_name SoheiKit
extends ShogunateKit

## Phase: the arc is telegraphed (the naginata drawn back).
const WINDUP: int = 1
## Phase: the short pause after the cut.
const RECOVER: int = 2
## Seconds it stands after a cut (lets the swing read; not a balance number).
const RECOVER_TIME: float = 0.35

## Seconds until the next cut may start.
var cd: float = 0.0
## Unit direction of the current cut (locked at its windup).
var dir: Vector2 = Vector2.RIGHT
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["sweep_first"]))


## Starts a cut at a target in reach.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Its target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - e.radius - body_radius(e, t) > float(d["sweep_trigger_range"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.effects.telegraph_cone(e.position, dir, float(d["sweep_radius"]), float(d["sweep_half_angle"]), float(d["sweep_telegraph"]), e)
	e.game.stat_add("sohei_sweeps", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			if phase_time >= float(d["sweep_telegraph"]):
				_sweep(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= RECOVER_TIME:
				cd = float(d["sweep_cooldown"])
				set_phase(e, IDLE)
	return true


## The cut lands: summons in the arc are hurt and thrown back, the necromancer
## is hurt if he stands in it.
func _sweep(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["sweep_radius"])  # Arc reach (px).
	var half := float(d["sweep_half_angle"])  # Arc half-angle (rad).
	var mult := hit_scale(e)  # Time scaling x buffs.
	g.effects.slash(e.position + dir * e.radius, dir, Palette.SHOGUN_SAKURA_LIGHT, reach * 0.9)
	e.motion_lunge(dir, MotionData.POWER_MELEE)
	rules(e).play_sound("draw_cut", e.position)
	var hits := 0  # Summons struck.
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			continue
		hits += 1
		var away := u.position - e.position  # Push direction.
		u.position += (away.normalized() if away.length() > 0.5 else dir) * float(d["sweep_knockback"])
		g.combat.damage_unit(u, float(d["sweep_damage_summon"]) * mult * e.undead_damage_mult, SunRoadEnemyData.SOHEI_SWEEP_SOURCE, e)
	g.stat_add("sohei_sweep_summon_hits", float(hits))
	for p in g.all_players:  # (Co-op: every necromancer inside.)
		if in_sector(e.position, dir, reach, half, e.radius, p.position, p.radius):
			g.stat_add("sohei_sweep_player_hits", 1.0)
			g.combat.damage_player(float(d["sweep_damage_player"]) * mult, SunRoadEnemyData.SOHEI_SWEEP_SOURCE, p)


## Autopilot hint: out of the telegraphed arc.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP or not in_sector(e.position, dir, float(d["sweep_radius"]) + 24.0, float(d["sweep_half_angle"]), e.radius, p, 12.0):
		return Vector2.ZERO
	var away := p - e.position
	return away.normalized() if away.length() > 0.1 else -dir


## The naginata drawn back: a pale glint on the blade while the arc winds up.
## Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP:
		return
	unmirror(e, ci)
	var k := clampf(phase_time / maxf(0.01, float(d["sweep_telegraph"])), 0.0, 1.0)  # 0 .. the cut.
	SpriteBank.draw_disc(ci, -dir * e.radius * 0.6 + Vector2(0, -e.radius), 2.0 + 2.0 * k, Color(1.0, 1.0, 1.0, 0.5 + 0.5 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
