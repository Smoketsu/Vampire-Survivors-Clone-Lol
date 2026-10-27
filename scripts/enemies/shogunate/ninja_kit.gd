## NinjaKit — the kit of the Ninja (ShogunateEnemyData "ninja"; Act V, GDD §15.0
## "Act V foundation (phase 1)" and "From the Shadows"): an AMBUSHER (the
## stages hand its squads to ShadowAmbush, so it appears out of an obstacle's
## shadow after a smoke puff). It throws its row's shuriken_count shuriken while
## it closes (one every shuriken_every s at a target between shuriken_min and
## shuriken_max px, through ProjectileManager), then fights with the dagger (the
## shared melee blow). It never stops advancing. No RNG.
class_name NinjaKit
extends ShogunateKit

## Shuriken thrown since it appeared.
var _thrown: int = 0
## Seconds until the next shuriken.
var _cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_thrown = 0
	_cd = first_cd(e, 0.4)


## Shuriken while it closes; never holds the body.
func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if _thrown >= int(d.get("shuriken_count", 0)) or _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else e.game.player
	var to := t.position - e.position
	var dist := to.length()
	if dist < float(d.get("shuriken_min", 40.0)) or dist > float(d.get("shuriken_max", 200.0)):
		return false
	_cd = float(d.get("shuriken_every", 1.0))
	_thrown += 1
	var dmg := float(d.get("shuriken_damage", 3.0)) * e.game.enemies.damage_mult * e.hit_mult()
	e.game.projectiles.fire_hostile(e.position, to / dist, dmg, float(d.get("shuriken_speed", 300.0)), e.undead_damage_mult,
			Projectile.Kind.ENEMY_ARROW, e.kind)
	e.motion_lunge(to / dist, MotionData.POWER_SHOT)
	e.game.stat_add("ninja_shuriken", 1.0)
	return false
