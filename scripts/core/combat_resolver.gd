## CombatResolver — the single place where damage and healing are applied
## (GDD §22 "CombatResolver: Hits, armor, death, status effects and healing").
## Every attack in the game (summons, spells, enemies, boss) goes through here,
## so armour, death handling, kill counting, XP drops and statistics are
## consistent and easy to tune.
class_name CombatResolver
extends RefCounted

## Owning run.
var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## Damages an enemy. Armour reduces damage by its fraction. Kills, XP drops
## and the kill counter are handled here. `source` tags the damage for the
## run statistics ("warrior", "bolt", "orb"...). Returns damage dealt.
func damage_enemy(e: Enemy, amount: float, source: String) -> float:
	if not e.active or amount <= 0.0:
		return 0.0
	var dealt := minf(amount * (1.0 - e.armor), e.hp)
	e.hp -= dealt
	e.on_hit()
	game.stat_add("damage_dealt", dealt)
	game.stat_add("dmg_" + source, dealt)
	if e.is_boss:
		game.stat_add("bossdmg_" + source, dealt)
	Juice.enemy_hit(e, dealt, source)
	if e.hp <= 0.0:
		_kill_enemy(e)
	return dealt


## Damages a summon. Death is routed to HordeDirector (deregistration,
## replacement queue, pooling). `source` tags the attacker kind for stats.
## Synergies (GDD §6.3): The Unholy Host reduces the damage, then a
## Shieldwall barrier absorbs what it can before HP is lost.
func damage_unit(u: SummonedUnit, amount: float, source: String) -> void:
	if not u.active or u.state == SummonedUnit.State.DEAD or amount <= 0.0:
		return
	var host_dr := game.horde.synergies.value("unholy_host", "damage_reduction")
	if host_dr > 0.0:
		game.stat_add("host_dmg_prevented", amount * host_dr)
		amount *= 1.0 - host_dr
	if u.barrier_hp > 0.0:
		var absorbed := minf(u.barrier_hp, amount)
		u.barrier_hp -= absorbed
		amount -= absorbed
		game.stat_add("shieldwall_absorbed", absorbed)
		if amount <= 0.0:
			u.on_hit()
			return
	var dealt := minf(amount, u.hp)
	u.hp -= amount
	u.on_hit()
	game.stat_add("damage_to_summons", dealt)
	game.stat_add("summon_dmg_from_" + source, dealt)
	if u.hp <= 0.0:
		game.stat_add("death_" + u.unit_class + "_by_" + source, 1.0)
		game.horde.on_unit_died(u)


## Damages the necromancer (i-frames are handled by the player). `source`
## tags the attacker kind for the player_dmg_from_* statistics. Warding Ritual
## (evolution passive) reduces the damage first.
func damage_player(amount: float, source: String) -> void:
	amount *= 1.0 - game.abilities.passive_value("warding_ritual", "damage_reduction")
	var lost := game.player.take_damage(amount)
	if lost > 0.0:
		game.stat_add("damage_to_player", lost)
		game.stat_add("player_dmg_from_" + source, lost)
		game.shake(4.0)


## Heals a summon, capped at max HP. Returns HP actually restored.
func heal_unit(u: SummonedUnit, amount: float) -> float:
	if not u.active:
		return 0.0
	var healed := minf(amount, u.max_hp - u.hp)
	if healed <= 0.0:
		return 0.0
	u.hp += healed
	u.queue_redraw()
	game.stat_add("summon_healing", healed)
	return healed


## Heals the necromancer, capped at max HP. Returns HP restored.
func heal_player(amount: float) -> float:
	var healed := game.player.heal(amount)
	game.stat_add("player_healing", healed)
	return healed


## Heals an enemy (Chaplains), capped at max HP. Returns HP restored.
func heal_enemy(e: Enemy, amount: float) -> float:
	if not e.active:
		return 0.0
	var healed := minf(amount, e.max_hp - e.hp)
	if healed <= 0.0:
		return 0.0
	e.hp += healed
	e.queue_redraw()
	game.stat_add("enemy_healing", healed)
	return healed


## Applies a movement slow to an enemy.
func slow_enemy(e: Enemy, fraction: float, duration: float) -> void:
	if e.active:
		e.apply_slow(fraction, duration)


## Death of an enemy: cosmetic pop, XP crystal, kill counter, then the
## EnemyDirector deactivates/pools it (or ends the run for the boss).
func _kill_enemy(e: Enemy) -> void:
	game.effects.pop(e.position, Palette.CRIMSON if not e.is_boss else Palette.GOLD, e.radius * 1.2)
	Juice.enemy_killed(e)
	if e.xp_value > 0:
		game.pickups.spawn(e.position, e.xp_value)
		game.stat_add("xp_dropped", e.xp_value)
	game.stat_add("kill_" + e.kind, 1.0)
	game.kills += 1
	game.enemies.on_enemy_killed(e)
