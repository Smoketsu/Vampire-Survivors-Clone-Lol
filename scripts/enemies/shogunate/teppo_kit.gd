## TeppoKit — the kit of the Teppo Gunner (ShogunateEnemyData "teppo_gunner";
## Act V, GDD §15.0 "Act V foundation (phase 1)"): arquebus VOLLEYS. Every
## gunner fires on the shared beat (ShogunateRulesData.VOLLEY_BEAT, 6 s of game
## time): when its shot is due between two beats, it waits for the next, so the
## gunners in range fire as one volley; then the long reload (its row's 6 s
## attack_interval) while it keeps advancing (the shared ranged AI). Its balls
## fly through ProjectileManager (the default enemy shot; Line of Fire is Act
## III only). A puff of match-smoke at the muzzle and one volley sound a beat.
## No RNG.
class_name TeppoKit
extends ShogunateKit

## Seconds after a beat during which a due shot still fires (the volley's spread).
const BEAT_WINDOW: float = 0.25  # TUNING (not in GDD) kit rhythm


## Holds a due shot until the next volley beat; never holds the body.
func physics(e: Enemy, _delta: float) -> bool:
	if e.attack_cd <= 0.0:
		var beat := ShogunateRulesData.VOLLEY_BEAT
		var into := fposmod(e.game.elapsed, beat)  # Seconds since the last beat.
		if into > BEAT_WINDOW:
			e.attack_cd = beat - into  # Wait for the volley.
	return false


## The volley shot: one ball through ProjectileManager (the enemy shot, tagged
## with the kind so the reports name it), its smoke and the beat's sound.
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position, dir, dmg, e.projectile_speed, e.undead_damage_mult, Projectile.Kind.ENEMY_ARROW, e.kind)
	e.game.effects.pop(e.position + dir * (e.radius + 4.0), Palette.SHOGUN_INDIGO_LIGHT, 6.0)
	e.game.stat_add("teppo_shots", 1.0)
	rules(e).volley_sound(e.position)
	return true
