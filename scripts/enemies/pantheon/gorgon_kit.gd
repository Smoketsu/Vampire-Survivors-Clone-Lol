## GorgonKit — the kit of the Gorgon (OlympusEnemyData "gorgon"; Act IV, Mount
## Olympus; GDD §15.0 "Mount Olympus kinds"; owner-approved proposal: "A
## petrifying gaze cone: summons in it turn to stone for 3 s (one stun path).
## Kill it first, or Grave Step out of the cone"; female, figure-redesign
## style). She slithers at the necromancer with the shared melee AI; every
## gaze_cooldown s, when he is within gaze_trigger px, she stops and her eyes
## blaze: a cone of gaze_range px, gaze_half_angle rad each side, aimed at him
## (locked) shows for gaze_telegraph s (EffectManager.telegraph_cone()); then
## every summon in the cone turns to stone for petrify_time s through THE one
## stun path for summons (CombatResolver.stun_unit(), source "gorgon_gaze") and
## the necromancer in it takes gaze_damage_player. Stats: gorgon_gazes,
## gorgon_petrified (summons), gorgon_gaze_player_hits. No RNG.
class_name GorgonKit
extends PantheonKit

## Phase: the gaze is telegraphed.
const GAZE: int = 1

## Seconds until her next gaze.
var gaze_cd: float = 0.0
## Unit direction of the current gaze (locked at its windup).
var _dir: Vector2 = Vector2.RIGHT
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	gaze_cd = CovenantKit.first_cd(e, float(d["first_gaze"]))


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	gaze_cd -= delta
	if phase == IDLE:
		var to := e.game.player.position - e.position
		if gaze_cd <= 0.0 and to.length() <= float(d["gaze_trigger"]):
			gaze_cd = float(d["gaze_cooldown"])
			_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
			e.game.effects.telegraph_cone(e.position, _dir, float(d["gaze_range"]), float(d["gaze_half_angle"]), float(d["gaze_telegraph"]), e)
			rules(e).play_sound("gorgon_gaze", e.position)
			e.game.stat_add("gorgon_gazes", 1.0)
			set_phase(e, GAZE)
		else:
			return false
	phase_time += delta
	hold(e)
	if phase_time >= float(d["gaze_telegraph"]):
		_petrify(e)
		set_phase(e, IDLE)
	return true


## The gaze lands: summons in the cone turn to stone, the necromancer is hurt.
func _petrify(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["gaze_range"])
	var half := float(d["gaze_half_angle"])
	var n := 0  # Summons turned to stone.
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or not CovenantKit.in_sector(e.position, _dir, reach, half, e.radius, u.position, u.radius):
			continue
		if g.combat.stun_unit(u, float(d["petrify_time"]), "gorgon_gaze") > 0.0:
			n += 1
	g.stat_add("gorgon_petrified", float(n))
	for pl in g.all_players:
		if not pl.dead and CovenantKit.in_sector(e.position, _dir, reach, half, e.radius, pl.position, pl.radius):
			g.combat.damage_player(float(d["gaze_damage_player"]) * CovenantKit.hit_scale(e), "gorgon_gaze", pl)
			g.stat_add("gorgon_gaze_player_hits", 1.0)
	if n > 0:
		rules(e).play_sound("petrify", e.position)
	g.effects.ring(e.position, e.radius * 1.6, Palette.GOLD, 0.25)


## Autopilot hint: out of the gaze cone.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == GAZE and CovenantKit.in_sector(e.position, _dir, float(d["gaze_range"]) + 20.0, float(d["gaze_half_angle"]) + 0.15, e.radius, p, 10.0):
		var rel := p - e.position
		var side := rel - _dir * rel.dot(_dir)
		return side.normalized() if side.length() > 0.5 else _dir.orthogonal()
	return Vector2.ZERO


## Her eyes blaze gold while she gazes. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != GAZE:
		return
	var k := clampf(phase_time / maxf(0.01, float(d["gaze_telegraph"])), 0.0, 1.0)
	var y := e.marker_y(-e.radius * 2.0) + 8.0  # About her eyes (px).
	ci.draw_circle(Vector2(0, y), 3.0 + 4.0 * k, Color(Palette.GOLD, 0.35 + 0.5 * k))
