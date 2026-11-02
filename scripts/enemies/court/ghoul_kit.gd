## GhoulKit — the kit of the Ghoul (CourtEnemyData "ghoul"; Act VII, Ravensmoor;
## GDD §15.0 "Ravensmoor (Act VII phase 2)"; owner-approved roster: "Ghoul:
## Fodder pack. Packs of 4 that stop to eat corpses (fewer raises) and heal
## doing it | Kill them before they reach the corpses; Corpse Explosion"). A
## gaunt grey corpse-eater in packs of four (the stage's events and
## RavensmoorDirector's pack timer bring them four at a time). It bites like
## every Court kind (feeds 0.25 through Bloodfeast), and:
##   * THE MEAL — when a foe dies within eat_reach px of a ghoul that is free
##     (not eating, its eat_cooldown run out), the nearest such ghoul CLAIMS
##     the corpse (claim_corpse(), called once from CombatResolver's kill path
##     while the Court's rules exist): the corpse is marked eaten
##     (Enemy.ghoul_meal = its generation), so Enemy.leaves_corpse(), THE one
##     gate of every corpse and raise path, answers false for it: Corpse
##     Explosion, Raise Dead, the Lich, Death Mark's Risen and Grave Tide find
##     no body there (the documented "fewer raises" check). The ghoul runs to
##     the corpse (eat_timeout s at most) and eats it for eat_time s, healing
##     eat_heal of its max HP over the meal through CombatResolver.heal_enemy()
##     (the existing enemy heal path), standing still: the counterplay is to
##     kill it on the way or at the table.
## A boss, a miniboss, a structure, a Reckoning foe or a machine is never
## eaten (their leaves_corpse() is false or they are too big to eat).
## No RNG (the nearest free ghoul). Stats: ghoul_claims, ghoul_meals,
## ghoul_meal_heal, ghoul_meals_broken, ghoul_meals_abandoned.
class_name GhoulKit
extends CourtKit

## Phase: running to the claimed corpse.
const TO_MEAL: int = 1
## Phase: eating it.
const EATING: int = 2
## Seconds between two heal ticks of a meal.
const HEAL_TICK: float = 0.5  # TUNING (not in GDD)

## World point of the claimed corpse.
var meal_at: Vector2 = Vector2.ZERO
## Seconds until it may claim again.
var _eat_cd: float = 0.0
## Seconds toward the next heal tick of the meal.
var _heal_acc: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_eat_cd = 0.0
	_heal_acc = 0.0


## True while this ghoul could claim a corpse.
func is_free() -> bool:
	return phase == IDLE and _eat_cd <= 0.0


## THE corpse claim (CombatResolver.damage_enemy()'s kill path, once per kill,
## only while Game.court exists): the nearest free ghoul within its eat_reach
## of dying foe `dead` claims the corpse; the corpse is marked eaten
## (Enemy.ghoul_meal), so Enemy.leaves_corpse() is false for it. True when a
## ghoul claimed it.
static func claim_corpse(g: Game, dead: Enemy) -> bool:
	if dead.is_boss or dead.is_miniboss or dead.is_structure or dead.is_reckoning or not dead.leaves_corpse():
		return false
	var row: Dictionary = CourtEnemyData.ENEMIES.get(CourtEnemyData.GHOUL, {})
	var reach := float(row.get("eat_reach", 140.0))
	var tmp: Array = []  # Own buffer: the kill path may be inside another query.
	g.enemy_grid.query(dead.position, reach, tmp)
	var best: Enemy = null
	var best_d := INF
	for o: Enemy in tmp:
		if o == dead or not o.active or not (o.kit is GhoulKit) or not (o.kit as GhoulKit).is_free():
			continue
		var dist := o.position.distance_to(dead.position)
		if dist <= reach and dist < best_d:
			best = o
			best_d = dist
	if best == null:
		return false
	(best.kit as GhoulKit).start_meal(best, dead.position)
	dead.ghoul_meal = dead.generation
	g.stat_add("ghoul_claims", 1.0)
	return true


## Ghoul `e` runs to the corpse at `at`.
func start_meal(e: Enemy, at: Vector2) -> void:
	meal_at = at
	_heal_acc = 0.0
	set_phase(e, TO_MEAL)


func physics(e: Enemy, delta: float) -> bool:
	_eat_cd -= delta
	match phase:
		TO_MEAL:
			phase_time += delta
			var to := meal_at - e.position
			var dist := to.length()
			if dist <= e.radius + 4.0:
				set_phase(e, EATING)
				rules(e).play_sound("ghoul_feed", e.position, 0.5)
				hold(e)
				return true
			if phase_time >= float(d.get("eat_timeout", 4.0)):
				_end(e)
				e.game.stat_add("ghoul_meals_abandoned", 1.0)
				return false
			var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
			e.velocity = to / dist * spd
			e.position += (e.velocity + e.knockback) * delta
			e._update_facing()
			return true
		EATING:
			phase_time += delta
			hold(e)
			_heal_acc += delta
			var eat := maxf(float(d.get("eat_time", 2.5)), 0.1)
			if _heal_acc >= HEAL_TICK:
				_heal_acc -= HEAL_TICK
				var g := e.game
				var healed := g.combat.heal_enemy(e, e.max_hp * float(d.get("eat_heal", 0.5)) * HEAL_TICK / eat)
				g.stat_add("ghoul_meal_heal", healed)
				g.effects.ring(e.position, e.radius * 1.2, Palette.COURT_BLOOD, 0.15)
			if phase_time >= eat:
				e.game.stat_add("ghoul_meals", 1.0)
				_end(e)
				return false
			return true
	return false


## The meal ends (eaten, abandoned or broken): the cooldown starts.
func _end(e: Enemy) -> void:
	_eat_cd = float(d.get("eat_cooldown", 4.0))
	set_phase(e, IDLE)


## A ghoul killed at the table or on its way: the meal is broken.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if phase != IDLE:
		e.game.stat_add("ghoul_meals_broken", 1.0)


func is_busy() -> bool:
	return phase == EATING or super.is_busy()


## While it eats, a small dark stain under it (a texture).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if phase == EATING:
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-e.radius * 1.2, e.radius * 0.2), Vector2(e.radius * 2.4, e.radius * 0.9)), false, Color(Palette.COURT_BLOOD_DARK, 0.6))
