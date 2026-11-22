## FrillSpitterKit — the kit of the FRILL-SPITTER (male; PrimevalEnemyData
## "frill_spitter"; temporary Act XIV, the Age of Titans; GDD §15.0 "The Age of
## Titans foundation (phase 1)"): it lobs a venom bolt from range through the
## plain ranged attack. The Fern Basin (phase 2) tags the bolt with the kind's
## own id (fire_ranged()), so the damage reports name the Frill-Spitter rather
## than the shared "archer_arrow" tag; the venom puddle is not built.
class_name FrillSpitterKit
extends PrimevalKit


## The venom bolt: the plain hostile shot, tagged "frill_spitter" (stats, the
## death line). Always fires it (true).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position, dir, dmg, e.projectile_speed, e.undead_damage_mult, Projectile.Kind.ENEMY_ARROW, e.kind)
	return true
