## EmpireKit — base class of the Electronic Empire's kits (Act III; GDD §15.0
## "Act III foundation (phase 1)"), a CovenantKit plugged into the shared Enemy
## AI like every kit. Kits load by name from scripts/enemies/empire/<id>_kit.gd
## (CovenantKits; an id must not repeat an Ancient Eye kit's id). What every
## Empire kind shares:
##   * MARCHING FIRE: a "ranged" Empire kind advances on the necromancer like
##     every ranged kind (enemies always advance; nobody kites) and, when its
##     attack is due, fire_ranged() fires a burst of `burst_rounds` shots
##     (EmpireEnemyData; 1 = a single shot) `burst_gap` s apart through
##     EmpireShots, never ProjectileManager: Line of Fire applies to every one.
##     The later rounds go out from physics() while it keeps walking (it
##     returns false: the burst never holds the enemy still).
##   * the shot's look and rules come from the row's shot_style
##     (EmpireRulesData.SHOT_STYLES), its speed from projectile_speed, its reach
##     from attack_range, its tag from the kind id.
## Phase 2 kinds extend this class (override fire_ranged() for a special shot,
## physics() for a windup) and call fire_shot() / fire_arc_at() for each shot.
## Determinism: no RNG; the burst fans by its round index.
class_name EmpireKit
extends CovenantKit

## Rounds of the current burst still to fire (0 = no burst running).
var burst_left: int = 0
## Seconds until the burst's next round.
var burst_cd: float = 0.0
## Index of the next round in the burst (0 = the first; it sets the fan offset).
var burst_index: int = 0
## Damage of each round of the current burst (time-scaled when it began).
var burst_dmg: float = 0.0
## Unit direction of the last round fired (kept when the target is gone).
var burst_dir: Vector2 = Vector2.RIGHT
## Target of the current burst (the necromancer or a summon).
var burst_target: Node2D = null
## Generation of a summon burst target (stale guard; 0 for the necromancer).
var burst_target_gen: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	burst_left = 0
	burst_cd = 0.0
	burst_index = 0
	burst_target = null


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	burst_left = 0
	burst_target = null


## The attack is due: starts a burst at `t` (the first round at once).
func fire_ranged(e: Enemy, t: Node2D, dir: Vector2, dmg: float) -> bool:
	burst_left = maxi(1, int(d.get("burst_rounds", 1)))
	burst_index = 0
	burst_dmg = dmg
	burst_dir = dir
	burst_target = t
	burst_target_gen = (t as SummonedUnit).generation if t is SummonedUnit else 0
	if burst_left > 1:
		Sfx.play("rifle_burst", e.position)
	else:
		Sfx.play("drone_zap", e.position)
	_fire_round(e)
	return true


## Fires the rest of a running burst on its gaps; never holds the enemy.
func physics(e: Enemy, delta: float) -> bool:
	if burst_left > 0:
		burst_cd -= delta
		if burst_cd <= 0.0:
			_fire_round(e)
	return false


## One round of the burst toward the burst target (or along the last
## direction once it is gone), fanned by its index.
func _fire_round(e: Enemy) -> void:
	if _burst_target_alive():
		var to := burst_target.position - e.position  # Toward the target.
		if to.length_squared() > 0.01:
			burst_dir = to.normalized()
	var n := maxi(1, int(d.get("burst_rounds", 1)))  # Rounds in the burst.
	var fan := (float(burst_index) - float(n - 1) * 0.5) * float(d.get("burst_spread", 0.0))  # Fan offset (rad).
	fire_shot(e, burst_dir.rotated(fan), burst_dmg)
	burst_index += 1
	burst_left -= 1
	burst_cd = float(d.get("burst_gap", 0.1))
	if burst_left <= 0:
		burst_target = null


## True if the burst target is still the same living body.
func _burst_target_alive() -> bool:
	if burst_target == null:
		return false
	if burst_target is SummonedUnit:
		var u := burst_target as SummonedUnit
		return u.active and u.generation == burst_target_gen
	return true


## Fires one straight shot of this kind from `e` along `dir` for `dmg`
## (time-scaled) through EmpireShots (Line of Fire), with the row's style,
## projectile_speed and attack_range. Returns false when the cap dropped it.
static func fire_shot(e: Enemy, dir: Vector2, dmg: float, style: String = "") -> bool:
	var st := style if style != "" else String(e.kit.d.get("shot_style", "round"))  # Shot look.
	var muzzle := e.position + dir * (e.radius + 2.0)  # Where it leaves the barrel.
	return e.game.empire_rules().shots.fire(muzzle, dir, e.projectile_speed, dmg, e.undead_damage_mult, st, e.kind, e.attack_range)


## Lobs one arcing shot (Line of Fire does not apply) from `e` to `dest`,
## landing after `flight` s, for `dmg` (time-scaled). Returns false when capped.
static func fire_arc_at(e: Enemy, dest: Vector2, flight: float, dmg: float, style: String = "mortar") -> bool:
	return e.game.empire_rules().shots.fire_arc(e.position, dest, flight, dmg, e.undead_damage_mult, style, e.kind)
