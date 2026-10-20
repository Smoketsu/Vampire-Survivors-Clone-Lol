## RevenantBehavior — the Iron Revenant's Suppressive Fire ("suppress", UnitData
## "iron_revenant"; Act III, the Iron Citadel; GDD §15.0 "Iron Revenant, Deus
## Revenant and Recoil Frame"; owner-approved proposal: "a reanimated war walker,
## the army's heavy gunner. It holds a back post on the Bone Ring and lays down
## suppressive fire that slows what it hits"). The finale's reward (unlocked by
## defeating Deus Ex Machina), offered on every stage; no act-specific rule (owner
## rule: summons work the same everywhere). It is ordinary heavy artillery in the
## shared AI: formation "back" (inside the Bone Ring with the priests and the
## Catapults), it holds its ground (w_threat low, no kiting) and winds up for
## `windup` s (the shared CASTING windup). Its attack_profile "suppress" is
## released here:
##   * a burst of `shells` cannon shells (Projectile.Kind.IRON_SHELL, the friendly
##     projectile path) fanned shell_spread rad apart down the line to its target,
##     each dealing the unit's damage to the first foe it meets and SLOWING it by
##     `slow` for slow_duration s (CombatResolver.slow_enemy(): Spirit Binding and
##     Mournsong apply as on every slow).
## Deus Revenant (summon evolution; keys from SummonEvolutionData "special_set",
## absent / 0 on the base class, which keeps exactly the behaviour above):
##   * twin cannons (`twin` 1): every burst comes from two muzzles twin_offset px
##     apart, so twice the shells;
##   * a missile salvo every salvo_cooldown s while a foe is within salvo_range
##     px: `salvo_missiles` missiles lobbed at the strongest foes in reach (an
##     elite, a miniboss or the boss first) through the army's arc path
##     (HordeHazards.launch_boulder(): a telegraphed landing circle, splash
##     salvo_radius px), each salvo_fraction x the unit's damage, source
##     "deus_revenant_missile".
## Determinism: no RNG (targets ordered by HP, ties in the spatial hash's order).
## Stats: revenant_bursts, revenant_shells, revenant_salvos, revenant_missiles.
class_name RevenantBehavior
extends SummonBehavior

## Damage-source tag of a Deus Revenant missile (a minion special source).
const MISSILE_SOURCE: String = "deus_revenant_missile"

## Candidate [hp, enemy] pairs of a salvo.
var _cands: Array = []
## Reusable query buffer.
var _buf: Array = []


## Full cooldown of the missile salvo (Deus Revenant; the base class has none).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("salvo_cooldown", 6.0))


## "suppress" attack profile: one burst of slowing shells at the target.
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	var s := u.special  # Special numbers.
	var to := u.target.position - u.position
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	var n := maxi(1, int(s["shells"]))  # Shells per muzzle.
	var twin := int(s.get("twin", 0)) > 0  # Deus Revenant: two cannons.
	var side := Vector2(-dir.y, dir.x) * float(s.get("twin_offset", 0.0))  # Muzzle offset.
	var muzzles: Array[Vector2] = [u.position + dir * u.radius]
	if twin:
		muzzles = [u.position + dir * u.radius + side, u.position + dir * u.radius - side]
	for m in muzzles:
		for i in n:
			var fan := (float(i) - float(n - 1) * 0.5) * float(s["shell_spread"])  # Fan offset (rad).
			var p := u.game.projectiles.fire_friendly_dir(Projectile.Kind.IRON_SHELL, m, dir.rotated(fan), u.damage, u.projectile_speed, 0, u.dmg_source)
			if p != null:
				p.slow_frac = float(s["slow"])
				p.slow_time = float(s["slow_duration"])
				u.game.stat_add("revenant_shells", 1.0)
	u.game.stat_add("revenant_bursts", 1.0)
	u.game.effects.pop(u.position + dir * u.radius, Palette.NECRO_GREEN, 8.0)
	Sfx.play("catapult_launch", u.position, 1.5)  # A startup-bank sound: the class plays on every stage.


## Deus Revenant: fires its missile salvo when it is ready and a foe is in reach
## (an instant side cast: it never interrupts the shared AI).
func think(u: SummonedUnit) -> bool:
	var s := u.special
	if int(s.get("salvo_missiles", 0)) <= 0 or special_cd > 0.0:
		return false
	var reach := float(s["salvo_range"])
	u.game.enemy_grid.query(u.position, reach, _buf)
	_cands.clear()
	for e: Enemy in _buf:
		if not e.active or e.untargetable or e.position.distance_to(u.position) > reach:
			continue
		var weight := e.hp * (3.0 if (e.is_elite or e.is_miniboss or e.is_boss) else 1.0)  # Elites, minibosses and the boss first.
		_cands.append([weight, e])
	if _cands.is_empty():
		special_cd = 0.5
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var n := int(s["salvo_missiles"])
	for k in n:
		var e: Enemy = _cands[k % _cands.size()][1]
		var aim := e.position + Vector2((float(k) - float(n - 1) * 0.5) * 14.0, 0.0)  # Spread a little across the target.
		var flight := clampf(u.position.distance_to(aim) / 360.0, 0.5, 1.0)  # s
		if u.director.hazards.launch_boulder(u.position + Vector2(0, -u.radius), aim, flight, 60.0, u.damage * float(s["salvo_fraction"]),
				float(s["salvo_radius"]), 90.0, 0.8, MISSILE_SOURCE, {}):
			u.game.stat_add("revenant_missiles", 1.0)
	special_cd = cooldown(u)
	u.game.stat_add("revenant_salvos", 1.0)
	Sfx.play("spear_cast", u.position, 0.7)  # A startup-bank sound (every stage).
	return false
