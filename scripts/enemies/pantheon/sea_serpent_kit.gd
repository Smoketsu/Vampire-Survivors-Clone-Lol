## SeaSerpentKit — the kit of the Sea Serpent (OlympusEnemyData "sea_serpent";
## Act IV, Mount Olympus; GDD §15.0 "The Pantheon Trial"; owner-approved
## proposal: Poseidon's "a sea serpent"). It slithers at the nearest prey with
## the shared melee AI; every lunge_cooldown s, when its target (a summon or the
## necromancer) is within lunge_range px, a lane lunge_length px long shows for
## lunge_telegraph s, then it shoots down the lane at lunge_speed biting
## everything in it once (OlympusHits.lane(), source "serpent_lunge"). Stats:
## serpent_lunges, serpent_lunge_hits. No RNG.
class_name SeaSerpentKit
extends PantheonKit

## Phase: the lunge lane is telegraphed.
const WINDUP: int = 1
## Phase: lunging down the lane.
const LUNGE: int = 2

## Seconds until its next lunge.
var lunge_cd: float = 0.0
## Unit direction of the lunge.
var _dir: Vector2 = Vector2.RIGHT
## Px of the lane still to run.
var _left: float = 0.0
## Who the current lunge already bit.
var _struck: Dictionary = {}
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lunge_cd = CovenantKit.first_cd(e, float(d["first_lunge"]))
	_left = 0.0


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	lunge_cd -= delta
	match phase:
		IDLE:
			var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
			var to := t.position - e.position
			if lunge_cd <= 0.0 and to.length() <= float(d["lunge_range"]):
				lunge_cd = float(d["lunge_cooldown"])
				_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
				_left = e.game.arena.clear_length(e.position, _dir, float(d["lunge_length"]), e.radius * 0.8)
				e.game.effects.telegraph_line(e.position, e.position + _dir * _left, float(d["lunge_width"]), float(d["lunge_telegraph"]), e)
				e.game.stat_add("serpent_lunges", 1.0)
				set_phase(e, WINDUP)
				return true
			return false
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["lunge_telegraph"]):
				_struck.clear()
				set_phase(e, LUNGE)
		LUNGE:
			var step_len := minf(float(d["lunge_speed"]) * delta, _left)
			e.position += _dir * step_len
			_left -= step_len
			e.velocity = _dir * float(d["lunge_speed"])
			e.game.stat_add("serpent_lunge_hits", float(OlympusHits.lane(e.game, e.position - _dir * step_len, _dir, step_len + e.radius,
					float(d["lunge_width"]), float(d["lunge_damage_player"]) * CovenantKit.hit_scale(e),
					float(d["lunge_damage_summon"]) * CovenantKit.hit_scale(e), "serpent_lunge", e, _struck, _tmp)))
			if _left <= 0.0:
				e.motion_lunge(_dir, MotionData.POWER_MELEE)
				set_phase(e, IDLE)
	return true
