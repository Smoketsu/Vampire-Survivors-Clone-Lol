## CombatResolver — the single place where damage and healing are applied
## (GDD §22 "CombatResolver: Hits, armor, death, status effects and healing").
## Every attack in the game (summons, spells, enemies, boss) goes through here,
## so armour, death handling, kill counting, XP drops and statistics are
## consistent and easy to tune.
## The later horde passives act here too (numbers and source lists in
## PassiveData):
##   Unholy Precision  — damage_enemy(): a minion attack (is_minion_source())
##                       may crit for PassiveData.CRIT_DAMAGE_MULT. Rolls use
##                       their own RandomNumberGenerator, seeded from the
##                       autotest seed, so the gameplay RNG stream is
##                       untouched and runs stay deterministic per seed.
##   Unholy Resilience — damage_unit(): less damage from
##                       PassiveData.AREA_HOLY_SOURCES.
##   Bone Plating      — damage_unit(): a flat amount off every hit, after
##                       the other reductions and before barriers.
## Cathedral Horror (summon evolution): stun_enemy() (the dive stun) and the
## stone form check in damage_unit().
## The Gravebow curse (a status, curse_enemy()) amplifies damage here too, and
## a dying Bone Colossus bursts into shrapnel from damage_unit() (ColossusKit).
## The army stance's damage-taken bonus (Bone Ring, ArmyStance.bonus(); 0
## while StanceData.BONUSES_ENABLED is false) is one more category in
## damage_unit(), counted in stance_dmg_prevented.
## Sanctified chambers (Sanctum of Judgment, SanctumDirector): a minion
## attack on a foe standing in an uncleansed chamber is cut to
## SanctumStage.SANCTUM.chamber_minion_damage in damage_enemy(), counted in
## sanctum_chamber_dmg_prevented.
class_name CombatResolver
extends RefCounted

## Owning run.
var game: Game
## Damage-source tag -> true for every minion attack that can crit (built
## once from PassiveData, UnitData and SummonEvolutionData).
var _minion_sources: Dictionary = {}
## Unholy Precision crit RNG, separate from the gameplay RNG.
var _crit_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p_game: Game) -> void:
	game = p_game
	if GameState.autotest:
		_crit_rng.seed = hash("crits:%d" % GameState.autotest_seed)
	else:
		_crit_rng.randomize()
	var tags: Array = []  # Every summon damage tag (class, evolution, extras).
	tags.append_array(UnitData.CLASS_ORDER)
	tags.append_array(SummonEvolutionData.ORDER)
	tags.append_array(PassiveData.MINION_EXTRA_TAGS)
	for tag: String in tags:
		for suffix: String in PassiveData.MINION_SOURCE_SUFFIXES:
			_minion_sources[tag + suffix] = true
	for src: String in PassiveData.MINION_SPECIAL_SOURCES:
		_minion_sources[src] = true


## True if damage tagged `source` is a minion attack (Unholy Precision).
func is_minion_source(source: String) -> bool:
	return _minion_sources.has(source)


## Damages an enemy. Armour reduces damage by its fraction. Kills, XP drops
## and the kill counter are handled here. `source` tags the damage for the
## run statistics ("warrior", "bolt", "orb"...). Returns damage dealt.
## A rotting enemy (Plague Cloud Rot, Enemy.rot_until) takes rot_amp more
## from every source; the extra is counted in the rot_bonus_dmg stat.
## A minion attack may crit first (Unholy Precision; minion_crits and the
## extra damage dealt, minion_crit_bonus_dmg).
## A cursed enemy (Gravebow curse, Enemy.curse_until, curse_enemy()) takes
## curse_amp more from every undead source; the extra is counted in the
## curse_bonus_dmg stat.
func damage_enemy(e: Enemy, amount: float, source: String) -> float:
	if not e.active or amount <= 0.0:
		return 0.0
	var crit_mult := 1.0  # Unholy Precision multiplier of this hit.
	var crit := game.abilities.passive_value("unholy_precision", "crit_chance")  # 0..1, 0 when not owned.
	if crit > 0.0 and is_minion_source(source) and _crit_rng.randf() < crit:
		crit_mult = PassiveData.CRIT_DAMAGE_MULT
		amount *= crit_mult
	# Holy ground of a sanctified chamber (Sanctum only; null elsewhere): the
	# undead fighting on it hit weaker.
	var sanctum := game.enemies.sanctum  # Sanctum objectives (null on other stages).
	if sanctum != null and is_minion_source(source):
		var holy := sanctum.minion_damage_mult(e.position)  # 1, or the chamber penalty.
		if holy != 1.0:
			game.stat_add("sanctum_chamber_dmg_prevented", amount * (1.0 - holy))
			amount *= holy
	# Enemy-side damage modifiers (Crimson March tower shields, aura buffs,
	# Marshal Vael's Shieldwall): exactly 1 for every Graveyard enemy.
	var taken := e.damage_taken_mult(source)
	if taken != 1.0:
		game.stat_add("dmg_resisted_" + e.kind, amount * (1.0 - taken) * (1.0 - e.armor))
		amount *= taken
	# Plague Cloud Rot (applied after the enemy-side modifiers): +rot_amp
	# from every source.
	var rot := e.rot_amp if e.rot_until > game.elapsed else 0.0  # Rot bonus fraction.
	amount *= 1.0 + rot
	# Gravebow curse (applied after Rot): +curse_amp from every undead source.
	var curse := 0.0  # Curse bonus fraction of this hit.
	if e.curse_until > game.elapsed and not source in SummonEvolutionData.CURSE_EXEMPT_SOURCES:
		curse = e.curse_amp
		amount *= 1.0 + curse
	var dealt := minf(amount * (1.0 - e.armor), e.hp)
	if rot > 0.0:
		game.stat_add("rot_bonus_dmg", dealt * rot / (1.0 + rot))
	if curse > 0.0:
		game.stat_add("curse_bonus_dmg", dealt * curse / (1.0 + curse))
	if crit_mult > 1.0:
		game.stat_add("minion_crits", 1.0)
		game.stat_add("minion_crit_bonus_dmg", dealt * (1.0 - 1.0 / crit_mult))
	e.hp -= dealt
	e.on_hit()
	game.stat_add("damage_dealt", dealt)
	game.stat_add("dmg_" + source, dealt)
	if game.dread_rally.buff_active() and is_minion_source(source):
		game.stat_add("rally_minion_dmg", dealt)  # Minion damage dealt under the Dread Rally buff.
	if e.is_boss:
		game.stat_add("bossdmg_" + source, dealt)
	Juice.enemy_hit(e, dealt, source)
	if e.hp <= 0.0:
		if source in MetaData.WARRIOR_KILL_SOURCES:
			game.stat_add("warrior_kills", 1.0)  # Bone Legion achievement (MetaData)
		game.horde.evolutions.on_enemy_killed(e, source)  # Lich raise-the-dead.
		_kill_enemy(e)
	return dealt


## Damages a summon. Death is routed to HordeDirector (deregistration,
## replacement queue, pooling). `source` tags the attacker kind for stats.
## Synergies (GDD §6.3): The Unholy Host reduces the damage, then Unholy
## Resilience (area / holy sources only), then Bone Plating (a flat amount,
## keeping at least PassiveData.PLATING_MIN_FRACTION of the hit; holy-ground
## ticks are exempt), then a barrier (Shieldwall, or a Warder / Bishop ally
## barrier) absorbs what it can before HP is lost. Stats:
## host_dmg_prevented, resilience_dmg_prevented (+ _area / _holy),
## plating_dmg_prevented.
func damage_unit(u: SummonedUnit, amount: float, source: String) -> void:
	if not u.active or u.state == SummonedUnit.State.DEAD or amount <= 0.0:
		return
	if u.airborne:
		return  # A flying Gargoyle cannot be hit (GargoyleBehavior).
	if u.stone_form:
		game.stat_add("horror_stone_dmg_prevented", amount)
		return  # A Cathedral Horror in stone form takes no damage (GargoyleBehavior).
	var host_dr := game.horde.synergies.value("unholy_host", "damage_reduction")
	if host_dr > 0.0:
		game.stat_add("host_dmg_prevented", amount * host_dr)
		amount *= 1.0 - host_dr
	var stance_dr := game.stance.bonus("damage_taken_reduction")  # Army stance bonus (0 while off).
	if stance_dr > 0.0:
		game.stat_add("stance_dmg_prevented", amount * stance_dr)
		amount *= 1.0 - stance_dr
	var ab := game.abilities  # Passive levels.
	var res := ab.passive_value("unholy_resilience", "area_holy_reduction")  # 0..1, 0 when not owned.
	if res > 0.0 and PassiveData.AREA_HOLY_SOURCES.has(source):
		game.stat_add("resilience_dmg_prevented", amount * res)
		game.stat_add("resilience_dmg_prevented_" + String(PassiveData.AREA_HOLY_SOURCES[source]), amount * res)
		amount *= 1.0 - res
	var plate := ab.passive_value("bone_plating", "flat_reduction")  # Flat damage off this hit.
	if plate > 0.0 and not source in PassiveData.PLATING_EXEMPT_SOURCES:
		var cut := minf(plate, amount * (1.0 - PassiveData.PLATING_MIN_FRACTION))  # Damage actually removed.
		game.stat_add("plating_dmg_prevented", cut)
		amount -= cut
	if u.barrier_hp > 0.0:
		var absorbed := minf(u.barrier_hp, amount)
		u.barrier_hp -= absorbed
		amount -= absorbed
		game.stat_add("barrier_absorbed", absorbed)
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
		game.horde.colossi.on_unit_killed(u)  # Bone Colossus shrapnel burst.
		game.horde.on_unit_died(u)


## Damages the necromancer (i-frames are handled by the player). `source`
## tags the attacker kind for the player_dmg_from_* statistics. Warding Ritual
## (evolution passive) and the meta Bone Mail armor (own category) reduce the
## damage first.
func damage_player(amount: float, source: String) -> void:
	amount *= 1.0 - game.abilities.passive_value("warding_ritual", "damage_reduction")
	amount *= 1.0 - game.meta.value("damage_reduction")
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


## Frost Wraith chill: a slow of `fraction` for `duration` s, shown as a
## frost tint on the enemy (Enemy.apply_chill).
func chill_enemy(e: Enemy, fraction: float, duration: float) -> void:
	if not e.active:
		return
	e.apply_slow(fraction, duration)
	e.apply_chill(duration)
	game.stat_add("frost_chills", 1.0)


## Gravebow curse: for `duration` s enemy `e` takes `amp` (0..1) more damage
## from every undead source (damage_enemy(); SummonEvolutionData
## CURSE_EXEMPT_SOURCES aside). It is timed on Game.elapsed like Rot, so it
## needs no ticking; a new hit refreshes the duration and keeps the stronger
## amp. A violet tint marks a cursed enemy (Enemy._draw()). Stats:
## curses_applied (a fresh curse), curse_refreshes.
func curse_enemy(e: Enemy, amp: float, duration: float) -> void:
	if not e.active or amp <= 0.0 or duration <= 0.0:
		return
	var now := game.elapsed  # Run time (s).
	if e.curse_until <= now:
		e.curse_amp = amp
		e.queue_redraw()
		game.stat_add("curses_applied", 1.0)
	else:
		e.curse_amp = maxf(e.curse_amp, amp)
		game.stat_add("curse_refreshes", 1.0)
	e.curse_until = maxf(e.curse_until, now + duration)


## Frost Wraith Deep Freeze: holds `e` for `duration` s through the Stasis
## freeze path (EnemyDirector skips its AI, attacks and movement while
## Enemy.freeze_timer > 0). The boss gets `boss_mult` of the duration, elites
## `elite_mult`, Reckoning enemies are immune. Crimson March structures
## (outposts, ward generators, carts, the Holy Standard) are immune too: a
## building cannot be frozen, and a frozen one would stop its own timers
## (the Stasis power-up, a global time stop, still holds them). A longer
## freeze already running is kept. Returns the seconds applied (0 = immune).
func freeze_enemy(e: Enemy, duration: float, boss_mult: float, elite_mult: float) -> float:
	if not e.active or e.is_reckoning or e.is_structure or duration <= 0.0:
		return 0.0
	var d := duration  # Freeze time for this enemy.
	if e.is_boss:
		d *= boss_mult
	elif e.is_elite:
		d *= elite_mult
	e.freeze_timer = maxf(e.freeze_timer, d)
	game.stat_add("frost_freezes", 1.0)
	if e.is_boss:
		game.stat_add("frost_boss_freezes", 1.0)
	return d


## Cathedral Horror dive stun: holds `e` for `duration` s through the same
## hold as the Deep Freeze (EnemyDirector skips its AI, attacks and movement
## while Enemy.stun_timer > 0; drawn with stun stars instead of the frost
## shell). Same immunities and reductions as freeze_enemy(): the boss gets
## `boss_mult` of the duration, elites `elite_mult`, Reckoning enemies and
## Crimson March structures are immune. A longer stun already running is
## kept. Returns the seconds applied (0 = immune). Stats: enemy_stuns,
## enemy_stunned_seconds (Enemy.step_frozen()).
func stun_enemy(e: Enemy, duration: float, boss_mult: float, elite_mult: float) -> float:
	if not e.active or e.is_reckoning or e.is_structure or duration <= 0.0:
		return 0.0
	var d := duration  # Stun time for this enemy.
	if e.is_boss:
		d *= boss_mult
	elif e.is_elite:
		d *= elite_mult
	e.stun_timer = maxf(e.stun_timer, d)
	game.stat_add("enemy_stuns", 1.0)
	return d


## Death of an enemy: cosmetic pop, XP crystal, kill counter, power-up drop
## and chest rolls, then the EnemyDirector deactivates/pools it (or ends the run for the
## boss).
func _kill_enemy(e: Enemy) -> void:
	game.effects.pop(e.position, Palette.CRIMSON if not e.is_boss else Palette.GOLD, e.radius * 1.2)
	Juice.enemy_killed(e)
	if e.xp_value > 0:
		game.pickups.spawn(e.position, e.xp_value)
		game.stat_add("xp_dropped", e.xp_value)
	game.stat_add("kill_" + e.kind, 1.0)
	if e.is_elite:
		game.stat_add("elite_kills", 1.0)  # Soul Ash elite bonus (MetaData)
	game.kills += 1
	game.abilities.on_enemy_killed(e)  # Corpse Explosion corpses, Soul Rapture bursts.
	game.powerups.on_enemy_killed(e)  # Power-up drop roll (PowerupData rules).
	game.chests.on_enemy_killed(e)  # Treasure chest roll (ChestData rules).
	game.dread_rally.on_enemy_killed(e)  # Dread Rally soul meter.
	if e.is_elite and not e.is_boss and not e.is_structure:
		_holy_retribution(e)
	game.enemies.on_enemy_killed(e)


## Holy Retribution (GDD §8.5 run modifier, game.difficulty): a slain elite
## bursts into a ring of radiant bolts (Covenant projectiles, damage scaled
## like every enemy hit by EnemyDirector.damage_mult). No-op when the
## modifier is off. The ring is aligned to the elite's heading to the
## player, so no RNG is used.
func _holy_retribution(e: Enemy) -> void:
	var n := game.difficulty.radiant_bolts()  # Bolts in the ring (0 = off).
	if n <= 0:
		return
	var dmg := game.difficulty.radiant_damage() * game.enemies.damage_mult  # Damage per bolt.
	var speed := game.difficulty.radiant_speed()  # Bolt speed (px/s).
	var a0 := (game.player.position - e.position).angle()  # First bolt aims at the player.
	for i in n:
		var dir := Vector2.from_angle(a0 + TAU * float(i) / float(n))  # This bolt's heading.
		game.projectiles.fire_hostile(e.position + dir * e.radius, dir, dmg, speed, 1.0,
				Projectile.Kind.RADIANT_BOLT, "holy_retribution")
	game.effects.ring(e.position, 34.0, Palette.GOLD, 0.35)
	game.stat_add("holy_retribution_bursts", 1.0)
