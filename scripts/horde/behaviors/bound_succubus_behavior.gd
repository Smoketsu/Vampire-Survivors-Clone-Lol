## BoundSuccubusBehavior — the Succubus summon class's attacks ("allure",
## UnitData "bound_succubus"; Act VI, the Palace of Silk and Ash; GDD §15.0 "The
## Succubus, the Lilim Matriarch and Sweet Surrender"; owner-approved proposal: "a
## flying charm support"). The same on every stage (owner rule: summons never
## get act-only rules).
##   * Kiss bolts: the class's attack_profile "allure" is released here as a
##     soul-pink bolt (Projectile.Kind.PRIEST_BOLT, source = the unit's
##     dmg_source: "bound_succubus" / "lilim_matriarch").
##   * THE CHARM: think() starts it when the charm is ready and its target (in
##     reach) can be turned (Enthrall.can_turn(): never a boss, miniboss,
##     structure, objective or Reckoning foe) and the army holds fewer than
##     TemptData.MAX_THRALLS thralls. It hovers and blows a kiss for
##     charm_windup s (a pink line of hearts to the foe; CASTING), then the foe
##     (and, for the Lilim Matriarch, charm_targets - 1 more within
##     charm_spread px of it, the nearest first) is turned for charm_duration s
##     through THE one Enthrall path (HordeDirector.enthrall_foe(); thralls hit
##     for thrall_damage, source TemptData.CLASS_SOURCE).
##   * SWEET SURRENDER (its paired passive): the charm comes allure_haste sooner
##     (cooldown()) and lasts allure_time longer, read from the summon's own
##     necromancer's build (co-op: its slot, as Oni's Resolve).
##   * Floating: the body is drawn FLOAT_LIFT px above a ground shadow; it is
##     not airborne (enemies can target and hit it).
## Determinism: no RNG beyond the shared first-cooldown roll; the extra targets
## by distance, ties in the spatial hash's order. Stats: succubus_charms,
## succubus_charm_foes, succubus_charm_missed.
class_name BoundSuccubusBehavior
extends SummonBehavior

## Phase: the kiss is blown.
const CAST: int = 1
## px the floating body is drawn above its shadow.
const FLOAT_LIFT: float = 6.0
## Sweet Surrender (PassiveData id).
const SURRENDER: String = "sweet_surrender"
## Sweet Surrender's level key: the charm's cooldown cut (fraction).
const HASTE_KEY: String = "allure_haste"
## Sweet Surrender's level key: the charm's extra time (fraction).
const TIME_KEY: String = "allure_time"

## The foe the kiss is blown at.
var _target: Enemy = null
## Its generation when the kiss began (stale guard).
var _target_gen: int = 0
## Reusable enemy query buffer.
var _buf: Array = []


## The summon's own necromancer's passive value `key` of Sweet Surrender (co-op:
## the slot whose army it is); 0 while not owned.
static func surrender(u: SummonedUnit, key: String) -> float:
	var ab := u.game.abilities  # The bound player's passives.
	if u.game.coop != null:
		for s in u.game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return ab.passive_value(SURRENDER, key)


## Full charm cooldown (s), Sweet Surrender included.
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("charm_cooldown", 9.0)) * (1.0 - clampf(surrender(u, HASTE_KEY), 0.0, 0.8))


## Starts a charm on the current target when it can be turned.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0 or not u.target_alive():
		return false
	var t := u.target
	if not Enthrall.can_turn(t):
		return false
	if u.director.enthrall != null and u.director.enthrall.count() >= TemptData.MAX_THRALLS:
		return false
	if u.position.distance_to(t.position) > u.attack_range + t.radius:
		return false
	_target = t
	_target_gen = t.generation
	begin_special(u, CAST)
	return true


## The kiss, then the charm.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	if phase == CAST and phase_time >= float(u.special["charm_windup"]):
		_charm(u)
		end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## Turns the target (and the Matriarch's others) through the Enthrall path.
func _charm(u: SummonedUnit) -> void:
	var g := u.game
	var t := _target
	_target = null
	if t == null or not t.active or t.generation != _target_gen or not Enthrall.can_turn(t):
		g.stat_add("succubus_charm_missed", 1.0)
		return
	var dur := float(u.special["charm_duration"]) * (1.0 + surrender(u, TIME_KEY))
	var opts := {"source": TemptData.CLASS_SOURCE, "damage": float(u.special["thrall_damage"])}
	var foes: Array[Enemy] = [t]
	var extra := int(u.special.get("charm_targets", 1)) - 1
	var spread := float(u.special.get("charm_spread", 0.0))
	if extra > 0 and spread > 0.0:
		g.enemy_grid.query(t.position, spread, _buf)
		_buf.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.position.distance_squared_to(t.position) < b.position.distance_squared_to(t.position))
		for e: Enemy in _buf:
			if foes.size() > extra:
				break
			if e != t and Enthrall.can_turn(e) and e.position.distance_to(t.position) <= spread:
				foes.append(e)
	var n := 0
	for e in foes:
		if u.director.enthrall_foe(e, dur, opts) != null:
			n += 1
	g.stat_add("succubus_charms", 1.0)
	g.stat_add("succubus_charm_foes", float(n))
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	g.volleys.on_special(u, u.position, t.position, u.damage)  # Bullet heaven: a ring of hearts.


## The target died or the cast was cut: nothing to undo.
func on_cancel(_u: SummonedUnit) -> void:
	_target = null


## "allure" attack profile: a kiss bolt at the target.
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	u.game.projectiles.fire_friendly(Projectile.Kind.PRIEST_BOLT, u.position, u.target, u.damage, u.projectile_speed, 0, u.dmg_source)


## Elites and foes closing on the necromancer first (the dirge profile), and a
## foe that can be turned over one that cannot.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	return 0.3 if special_cd <= 0.5 and Enthrall.can_turn(e) and e.is_elite else 0.0


## The body floats above its shadow.
func body_lift(_u: SummonedUnit) -> float:
	return FLOAT_LIFT


## Ground shadow (it floats) and the blown kiss: a pink line of hearts to the
## foe. Visual only.
func draw_under(u: SummonedUnit) -> void:
	u.draw_set_transform(Vector2(0, u.radius * 0.95), 0.0, Vector2(1.0, 0.4))
	u.draw_circle(Vector2.ZERO, u.radius * 0.8, Color(0, 0, 0, 0.3))
	body_space(u)
	if phase != CAST or _target == null or not _target.active:
		return
	world_space(u)
	var to := _target.position - u.position  # The foe, from its centre.
	var k := clampf(phase_time / maxf(float(u.special["charm_windup"]), 0.01), 0.0, 1.0)
	u.draw_line(Vector2(0, -FLOAT_LIFT), to, Color(TemptData.HEART_COLOR, 0.2 + 0.3 * k), 1.0)
	for i in 3:
		var f := fmod(k + float(i) / 3.0, 1.0)
		InfernoGlyphs.draw_heart(u, to * f + Vector2(0, -FLOAT_LIFT), 3.0, Color(TemptData.HEART_COLOR, 0.9))
	body_space(u)
