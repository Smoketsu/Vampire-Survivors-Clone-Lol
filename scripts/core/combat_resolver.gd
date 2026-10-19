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
##   Grave Masonry     — damage_unit() (content wave 2; with Bone Bastion): the blockers
##                       (PassiveData.MASONRY_CLASSES) take blocker_reduction
##                       less, after Unholy Resilience and before Bone Plating.
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
## Sanctum of Judgment (SanctumEnemyData) mitigation, all in damage_enemy():
##   holy suppression — minion attacks on an enemy inside an armed
##                      suppression zone deal its damage_mult
##                      (HordeDirector.add_suppression(); 1 for the Radiant
##                      Inquisitor's): suppression_dmg_prevented.
##   Sun Paladin ward — a warded enemy (Enemy.ward_until) takes ward_resist
##                      less: paladin_ward_dmg_prevented.
##   flat armour      — after percentage armour, Enemy.flat_armor off every
##                      hit, keeping at least FLAT_ARMOR_MIN_FRACTION:
##                      flat_armor_absorbed_<kind>.
##   holy shield      — Enemy.holy_shield absorbs what is left before HP:
##                      holy_shield_absorbed, holy_shields_broken.
## The Soul Nova ignores the ward, flat armour and shields
## (SanctumEnemyData.FLAT_ARMOR_EXEMPT_SOURCES). A miniboss (Enemy.is_miniboss)
## takes the boss multiplier of a Deep Freeze / dive stun.
## The later spells' passives and statuses act here too (GDD §15.0 "Five
## more spells"):
##   Grim Ledger    — damage_enemy(): elites, minibosses and bosses take
##                    elite_damage more from every source but the Soul Nova
##                    (PassiveData.LEDGER_EXEMPT_SOURCES): grim_ledger_bonus_dmg.
##   Wither shred   — damage_enemy(): an enemy inside the Wither aura
##                    (Enemy.wither_until) has its armour and flat armour cut
##                    by wither_shred: wither_shred_bonus_dmg.
##   Marginalia     — damage_enemy() (Act II, paired with Forbidden Verse):
##                    every on-death effect (VerseData.MARGINALIA_SOURCES)
##                    deals on_death_damage more: marginalia_bonus_dmg.
##   Spirit Binding — slow_enemy(), chill_enemy(), freeze_enemy() and
##                    stun_enemy() lengthen every duration by cc_duration
##                    (cc_mult(); the one path for those statuses).
## The passives of the three newest summon classes act here too:
##   Siegecraft — damage_enemy(): summon damage (is_minion_source() or
##                PassiveData.MINION_DOT_SOURCES) to a structure, an elite or
##                a miniboss (never the stage boss) is raised by siege_damage
##                (stat siege_bonus_dmg).
##   Mournsong  — debuff_time(): every weakening effect applied through here
##                (slow_enemy(), chill_enemy(), curse_enemy(), weaken_enemy())
##                and Rot (rot_enemy(): Plague Cloud, Contagion, Wither) lasts
##                (1 + debuff_duration) times longer. Holds (Deep Freeze,
##                dive stun) are not weakening effects and are unchanged.
## The Banshee Dirge is the ONE debuff path for "weakened" foes:
## weaken_enemy() slows the foe and cuts the damage of its hits
## (Enemy.hit_mult()); a Keening Lady's Dirge also silences it, and a
## silenced healer's heals fail in heal_enemy().
## Act II (Ul-Thalos): Crushing Depths — damage_enemy(): a minion attack on a
## foe that is held, stunned or frozen (Enemy.stun_timer / freeze_timer
## running) is raised by held_damage (stat crushing_depths_bonus_dmg); exactly
## 1 while the passive is not owned.
## Synergies of the newer classes (SynergyData, SynergyManager): damage_enemy()
## multiplies every hit by SynergyManager.hit_mult() once, right after
## Siegecraft (the highest mark bonus of the hit's class on a staggered /
## swooped / chilled / frozen / weakened foe, half on the stage boss, times
## the Charnel Menagerie for the newer classes; exactly 1 while none is
## active) and reports the dealt damage to record_hit(). Requiem stretches a
## Dirge through extend_weaken() (capped at Enemy.weaken_span).
## Every damage to a structure is also counted per source (structdmg_<tag>).
## Act II (Gullhaven Harbour): Salt of the Deep — damage_enemy(): an enemy that
## is slowed, chilled or frozen (Enemy.slow_timer / chill_timer / freeze_timer)
## takes slowed_damage more from every source but the Soul Nova
## (PassiveData.SALT_EXEMPT_SOURCES): salt_bonus_dmg.
## Spirit Binding and Mournsong both lengthen slows and chills (slow_enemy(),
## chill_enemy()); the two multipliers stack multiplicatively.
## Playable characters (CharacterInnates, game.innates; every hook is a
## no-op for the Gravecaller): a killing blow reports to on_enemy_killed()
## (Ossuary Ward shards, Contagion), damage_player() lets an Ossuary Ward
## shard absorb the hit first, and heal_player() passes the HP healed to
## Stolen Grace. Rot (Plague Cloud, Contagion, the Wither Witch's aura) is
## applied through rot_enemy().
## Ultimates (content wave 2, UltimateSystem as game.ultimates; every hook is a
## no-op unless that ultimate runs, so Dread Rally runs are unchanged):
##   Sovereign's Decree — damage_unit(): every summon takes
##                        UltimateData.DECREE_DAMAGE_REDUCTION less (its own
##                        category, decree_dmg_prevented); damage_player():
##                        the untargetable necromancer ignores every hit
##                        before any other rule (decree_player_hits_ignored).
##   Eclipse exposure   — expose_enemy() (the one Eclipse debuff): from
##                        Enemy.expose_from to expose_until the enemy takes
##                        expose_amp more damage from every source in
##                        damage_enemy(), after the curse (eclipse_bonus_dmg).
##                        The Eclipse's hold is freeze_enemy() and its boss
##                        slow slow_enemy(), the existing paths.
##   Grave Tide         — _kill_enemy() reports every kill to
##                        game.ultimates.on_enemy_killed() (the Tide's raises).
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
	# Siegecraft: summon damage to structures, elites and minibosses.
	var siege := 0.0  # Siege bonus fraction of this hit.
	if (e.is_structure or e.is_miniboss or (e.is_elite and not e.is_boss)) \
			and (is_minion_source(source) or source in PassiveData.MINION_DOT_SOURCES):
		siege = game.abilities.passive_value("siegecraft", "siege_damage")  # 0 when not owned.
		amount *= 1.0 + siege
	# Crushing Depths (Act II): minion attacks on a held, stunned or frozen foe.
	var depths := game.abilities.passive_value("crushing_depths", "held_damage")  # 0 when not owned.
	if depths > 0.0 and (e.stun_timer > 0.0 or e.freeze_timer > 0.0) and is_minion_source(source):
		game.stat_add("crushing_depths_bonus_dmg", amount * depths)
		amount *= 1.0 + depths
	# Synergies of the newer classes (SynergyManager.hit_mult(), the one
	# synergy hit path): the highest mark bonus of the hit's class, times the
	# Charnel Menagerie. Exactly 1 while none of them is active.
	var syn := game.horde.synergies  # Army synergies.
	var syn_mult := syn.hit_mult(source, e)  # Synergy multiplier of this hit.
	amount *= syn_mult
	# Holy ground of a sanctified chamber (Sanctum only; null elsewhere): the
	# undead fighting on it hit weaker.
	var sanctum := game.enemies.sanctum  # Sanctum objectives (null on other stages).
	if sanctum != null and is_minion_source(source):
		var holy := sanctum.minion_damage_mult(e.position)  # 1, or the chamber penalty.
		if holy != 1.0:
			game.stat_add("sanctum_chamber_dmg_prevented", amount * (1.0 - holy))
			amount *= holy
	# Holy suppression zones (HordeDirector.add_suppression()): minion attacks
	# on an enemy inside one deal its damage_mult (skipped when none is armed).
	var sup := game.horde.suppression  # The army's suppression field.
	if sup.active_count > 0 and is_minion_source(source):
		var sm := sup.damage_mult_at(e.position)  # Suppression multiplier here.
		if sm < 1.0:
			game.stat_add("suppression_dmg_prevented", amount * (1.0 - sm) * (1.0 - e.armor))
			amount *= sm
	# Enemy-side damage modifiers (Crimson March tower shields, aura buffs,
	# Marshal Vael's Shieldwall): exactly 1 for every Graveyard enemy.
	var taken := e.damage_taken_mult(source)
	if taken != 1.0:
		game.stat_add("dmg_resisted_" + e.kind, amount * (1.0 - taken) * (1.0 - e.armor))
		amount *= taken
	# Sun Paladin ward (one ward per enemy, PaladinKit): ward_resist less.
	if e.ward_until > game.elapsed and not source in SanctumEnemyData.FLAT_ARMOR_EXEMPT_SOURCES:
		game.stat_add("paladin_ward_dmg_prevented", amount * e.ward_resist * (1.0 - e.armor))
		amount *= 1.0 - e.ward_resist
	# Plague Cloud Rot (applied after the enemy-side modifiers): +rot_amp
	# from every source.
	var rot := e.rot_amp if e.rot_until > game.elapsed else 0.0  # Rot bonus fraction.
	amount *= 1.0 + rot
	# Gravebow curse (applied after Rot): +curse_amp from every undead source.
	var curse := 0.0  # Curse bonus fraction of this hit.
	if e.curse_until > game.elapsed and not source in SummonEvolutionData.CURSE_EXEMPT_SOURCES:
		curse = e.curse_amp
		amount *= 1.0 + curse
	# Eclipse exposure (ultimate, expose_enemy()): +expose_amp from every source
	# once the darkness ended. 0 for an enemy no Eclipse caught.
	var expose := e.expose_amp if (e.expose_until > game.elapsed and e.expose_from <= game.elapsed) else 0.0  # Exposure bonus fraction.
	if expose > 0.0:
		amount *= 1.0 + expose
	# Grim Ledger (passive): elites, minibosses and bosses take more.
	if e.is_elite or e.is_boss or e.is_miniboss:
		var ledger := game.abilities.passive_value("grim_ledger", "elite_damage")  # 0 when not owned.
		if ledger > 0.0 and not source in PassiveData.LEDGER_EXEMPT_SOURCES:
			game.stat_add("grim_ledger_bonus_dmg", amount * ledger * (1.0 - e.armor))
			amount *= 1.0 + ledger
	# Salt of the Deep (Act II passive): slowed, chilled or frozen foes take more.
	var salt := game.abilities.passive_value("salt_of_the_deep", "slowed_damage")  # 0 when not owned.
	if salt > 0.0 and (e.slow_timer > 0.0 or e.chill_timer > 0.0 or e.freeze_timer > 0.0) and not source in PassiveData.SALT_EXEMPT_SOURCES:
		game.stat_add("salt_bonus_dmg", amount * salt * (1.0 - e.armor))
		amount *= 1.0 + salt
	# Marginalia (Act II passive, VerseData): every on-death effect (ink bursts,
	# corpse bursts, the frozen shatter, bone shrapnel...) hits harder. 0 when
	# not owned, so the source list is only searched while it is.
	var marg := game.abilities.passive_value(VerseData.MARGINALIA, VerseData.MARGINALIA_KEY)  # On-death bonus fraction.
	if marg > 0.0 and source in VerseData.MARGINALIA_SOURCES:
		game.stat_add("marginalia_bonus_dmg", amount * marg * (1.0 - e.armor))
		amount *= 1.0 + marg
	# Wither aura (Enemy.wither_until): armour and flat armour cut by the shred.
	var shred := e.wither_shred if e.wither_until > game.elapsed else 0.0  # 0..1 of armour removed.
	var armor := e.armor * (1.0 - shred)  # Effective percentage armour of this hit.
	if shred > 0.0 and e.armor > 0.0:
		game.stat_add("wither_shred_bonus_dmg", amount * (e.armor - armor))
	var raw := amount * (1.0 - armor)  # Damage after percentage armour.
	if e.flat_armor > 0.0 or e.holy_shield > 0.0:
		raw = _sanctum_mitigation(e, raw, source, shred)
		if raw <= 0.0:
			e.on_hit()  # Fully absorbed by a holy shield.
			return 0.0
	var dealt := minf(raw, e.hp)
	if rot > 0.0:
		game.stat_add("rot_bonus_dmg", dealt * rot / (1.0 + rot))
	if curse > 0.0:
		game.stat_add("curse_bonus_dmg", dealt * curse / (1.0 + curse))
	if expose > 0.0:
		game.stat_add("eclipse_bonus_dmg", dealt * expose / (1.0 + expose))
	if crit_mult > 1.0:
		game.stat_add("minion_crits", 1.0)
		game.stat_add("minion_crit_bonus_dmg", dealt * (1.0 - 1.0 / crit_mult))
	if siege > 0.0:
		game.stat_add("siege_bonus_dmg", dealt * siege / (1.0 + siege))
	if syn_mult > 1.0:
		syn.record_hit(dealt)  # syn_<id>_hits / _bonus_dmg.
	e.hp -= dealt
	e.on_hit()
	game.stat_add("damage_dealt", dealt)
	game.stat_add("dmg_" + source, dealt)
	if game.dread_rally.buff_active() and is_minion_source(source):
		game.stat_add("rally_minion_dmg", dealt)  # Minion damage dealt under the Dread Rally buff.
	if e.is_boss:
		game.stat_add("bossdmg_" + source, dealt)
	elif e.is_miniboss:
		game.stat_add("minibossdmg_" + source, dealt)  # Cathedral Guardian (autotest).
	if e.is_structure:
		game.stat_add("structdmg_" + source, dealt)  # Outposts, generators, crystals, altars, carts (autotest).
	Juice.enemy_hit(e, dealt, source)
	if e.hp <= 0.0:
		game.stat_add("kills_by_" + source, 1.0)  # Killing blow per damage source (autotest spell summaries).
		if source in MetaData.WARRIOR_KILL_SOURCES:
			game.stat_add("warrior_kills", 1.0)  # Bone Legion achievement (MetaData)
		game.horde.evolutions.on_enemy_killed(e, source)  # Lich raise-the-dead.
		game.innates.on_enemy_killed(e, source)  # Character innates (no-op without one).
		_kill_enemy(e)
	return dealt


## Sanctum flat armour, then a holy shield, on `raw` post-armour damage to
## `e` (see the header); returns what is left for HP. `shred` (0..1, the
## Wither aura) removes that fraction of the flat armour.
func _sanctum_mitigation(e: Enemy, raw: float, source: String, shred: float = 0.0) -> float:
	if source in SanctumEnemyData.FLAT_ARMOR_EXEMPT_SOURCES:
		return raw
	if e.flat_armor > 0.0:
		var flat := e.flat_armor * (1.0 - shred)  # Flat armour left after the Wither shred.
		var cut := minf(flat, raw * (1.0 - SanctumEnemyData.FLAT_ARMOR_MIN_FRACTION))  # Damage removed.
		game.stat_add("flat_armor_absorbed_" + e.kind, cut)
		raw -= cut
	if e.holy_shield > 0.0:
		var absorbed := minf(e.holy_shield, raw)  # Taken by the shield.
		e.holy_shield -= absorbed
		raw -= absorbed
		game.stat_add("holy_shield_absorbed", absorbed)
		if e.holy_shield <= 0.0:
			e.holy_shield = 0.0
			e.holy_shield_time = 0.0
			e.queue_redraw()
			game.stat_add("holy_shields_broken", 1.0)
	return raw


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
	var decree_dr := game.ultimates.unit_damage_reduction()  # Sovereign's Decree (0 unless it runs).
	if decree_dr > 0.0:
		game.stat_add("decree_dmg_prevented", amount * decree_dr)
		amount *= 1.0 - decree_dr
	var ab := game.abilities  # Passive levels.
	var res := ab.passive_value("unholy_resilience", "area_holy_reduction")  # 0..1, 0 when not owned.
	if res > 0.0 and PassiveData.AREA_HOLY_SOURCES.has(source):
		game.stat_add("resilience_dmg_prevented", amount * res)
		game.stat_add("resilience_dmg_prevented_" + String(PassiveData.AREA_HOLY_SOURCES[source]), amount * res)
		amount *= 1.0 - res
	# Grave Masonry and Bone Bastion (content wave 2): the blockers take less
	# (Masonry) and so does every summon near a Golem (the Bone Bastion synergy);
	# together they cut at most Bone Bastion's max_combined of the hit.
	var mason := ab.passive_value("grave_masonry", "blocker_reduction")  # 0..1, 0 when not owned.
	if not u.unit_class in PassiveData.MASONRY_CLASSES:
		mason = 0.0
	var bastion := game.horde.synergies.bastion_reduction(u)  # 0..1, 0 while the synergy is off.
	if mason > 0.0 or bastion > 0.0:
		var floor_mult := 1.0 - float(SynergyData.SYNERGIES["bone_bastion"]["max_combined"])  # Least share of the hit kept.
		var mult := maxf(floor_mult, (1.0 - mason) * (1.0 - bastion))  # Share of the hit kept.
		var prevented := amount * (1.0 - mult)  # HP the two cut together.
		var by_mason := minf(prevented, amount * mason)  # Masonry's share (counted first).
		if mason > 0.0:
			game.stat_add("masonry_dmg_prevented", by_mason)
		if bastion > 0.0:
			game.stat_add("syn_bastion_prevented", prevented - by_mason)
		amount *= mult
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
## damage first. While Sovereign's Decree runs (UltimateSystem
## .player_untargetable()) every hit is ignored before anything else.
func damage_player(amount: float, source: String) -> void:
	if game.ultimates.player_untargetable():
		game.ultimates.on_player_hit_ignored(amount)
		return  # Sovereign's Decree: the necromancer cannot be targeted (every hit ignored).
	if game.innates.try_block_hit():
		return  # Ossuary Ward shard (Bone Oracle) absorbed the whole hit.
	amount *= 1.0 - game.abilities.passive_value("warding_ritual", "damage_reduction")
	amount *= 1.0 - game.meta.value("damage_reduction")
	if game.dread != null:
		amount *= game.dread.taken_mult()  # Act II Dread: its own multiplier (DreadData).
	var hp_before := game.player.hp  # For the Untouchable counter (RunRewards).
	var lost := game.player.take_damage(amount)
	if lost > 0.0:
		game.rewards.note_player_hit(hp_before, lost, game.player.max_hp)  # Content wave 2: reads only.
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
	if healed > 0.0:
		game.innates.on_player_healed(healed)  # Stolen Grace (no-op without it).
	return healed


## Heals an enemy (Chaplains), capped at max HP. Returns HP restored.
## `healer` is the enemy casting the heal (null = not a cast, e.g. a
## regeneration); a silenced healer (Keening Lady Dirge, is_silenced()) heals
## nothing (stat keening_heals_silenced).
func heal_enemy(e: Enemy, amount: float, healer: Enemy = null) -> float:
	if not e.active:
		return 0.0
	if healer != null and is_silenced(healer):
		game.stat_add("keening_heals_silenced", 1.0)
		return 0.0
	var healed := minf(amount, e.max_hp - e.hp)
	if healed <= 0.0:
		return 0.0
	e.hp += healed
	e.queue_redraw()
	game.stat_add("enemy_healing", healed)
	return healed


## Spirit Binding (passive) multiplier on the duration of every slow, chill,
## Deep Freeze and stun inflicted on an enemy (1 when not owned).
func cc_mult() -> float:
	return 1.0 + game.abilities.passive_value("spirit_binding", "cc_duration")


## Applies a movement slow to an enemy. Spirit Binding (cc_mult()) and
## Mournsong (debuff_time()) both lengthen it; they stack multiplicatively.
func slow_enemy(e: Enemy, fraction: float, duration: float) -> void:
	if e.active:
		e.apply_slow(fraction, debuff_time(duration * cc_mult()))


## Rot (Plague Cloud, AbilityData): enemy `e` takes `amount` (0..1) more
## damage from every source until game time `until` (damage_enemy()). The
## stronger Rot wins while one is running and the longer expiry is kept;
## bosses get AbilityData.ROT_BOSS_MULT of `amount`. Also used by the
## Plague Scholar's Contagion and the Wither Witch's Creeping Rot innates.
## The Mournsong passive lengthens what is left of it (debuff_time()).
func rot_enemy(e: Enemy, amount: float, until: float) -> void:
	var a := amount * (AbilityData.ROT_BOSS_MULT if e.is_boss else 1.0)  # Rot for this enemy.
	until = game.elapsed + debuff_time(until - game.elapsed)  # Mournsong lengthens Rot.
	if e.rot_until <= game.elapsed or a >= e.rot_amp:
		e.rot_amp = a
	e.rot_until = maxf(e.rot_until, until)


## Frost Wraith chill: a slow of `fraction` for `duration` s, shown as a
## frost tint on the enemy (Enemy.apply_chill). Spirit Binding and Mournsong
## both lengthen it (multiplicatively, like slow_enemy()).
func chill_enemy(e: Enemy, fraction: float, duration: float) -> void:
	if not e.active:
		return
	var d := debuff_time(duration * cc_mult())  # Chill time after Spirit Binding and Mournsong (s).
	e.apply_slow(fraction, d)
	e.apply_chill(d)
	game.stat_add("frost_chills", 1.0)


## Mournsong: duration (s) of a weakening effect of base `duration` s on an
## enemy, x (1 + debuff_duration) while the passive is owned. The extra
## seconds are counted in mournsong_extra_seconds.
func debuff_time(duration: float) -> float:
	var bonus := game.abilities.passive_value("mournsong", "debuff_duration")  # 0 when not owned.
	if bonus <= 0.0 or duration <= 0.0:
		return duration
	game.stat_add("mournsong_extra_seconds", duration * bonus)
	return duration * (1.0 + bonus)


## Banshee Dirge (the one "weakened" debuff path): for `duration` s (after
## Mournsong) enemy `e` is slowed by `slow` and its hits deal `cut` (0..1)
## less (Enemy.hit_mult(): every soldier strike, arrow, rush and Sanctum kit
## hit, Vael's cleave and Seraphine's fans / barrages; scripted boss and
## stage hazards are not hits of the enemy and are unchanged). The boss and
## minibosses take `boss_mult` of the slow and cut; Reckoning enemies and
## structures are immune. A slow never makes an enemy flee: it only lowers
## its speed. `silence` (Keening Lady) also silences it for the same time:
## its heals fail (heal_enemy()). A new Dirge refreshes the time and keeps the
## stronger cut. Timed on Game.elapsed like the curse. Returns true if it
## applied. Stats: dirge_debuffs, dirge_debuff_seconds (enemy-seconds of
## new coverage), keening_silenced.
func weaken_enemy(e: Enemy, slow: float, cut: float, duration: float, boss_mult: float, silence: bool) -> bool:
	if not e.active or e.is_reckoning or e.is_structure or duration <= 0.0:
		return false
	var k := boss_mult if (e.is_boss or e.is_miniboss) else 1.0  # Share for bosses.
	var d := debuff_time(duration)  # Debuff time after Mournsong (s).
	var now := game.elapsed  # Run time (s).
	e.apply_slow(slow * k, d)
	game.stat_add("dirge_debuff_seconds", maxf(0.0, now + d - maxf(e.weaken_until, now)))
	if e.weaken_until <= now:
		e.weaken_cut = cut * k
		e.weaken_span = d
		e.queue_redraw()
	else:
		e.weaken_cut = maxf(e.weaken_cut, cut * k)
		e.weaken_span = maxf(e.weaken_span, d)
	e.weaken_until = maxf(e.weaken_until, now + d)
	game.stat_add("dirge_debuffs", 1.0)
	if silence:
		if e.silence_until <= now:
			game.stat_add("keening_silenced", 1.0)
		e.silence_until = maxf(e.silence_until, now + d)
	return true


## Requiem (synergy, SynergyManager.hit_mult()): stretches a running Dirge
## weakening on `e` by `seconds`, never beyond now + the Dirge's own length
## (Enemy.weaken_span), so a stretched Dirge is never longer than a fresh
## one. Only the weakening (the damage cut, Enemy.hit_mult()) is stretched,
## not the Dirge's slow. Returns the seconds added (0 when not weakened).
func extend_weaken(e: Enemy, seconds: float) -> float:
	var now := game.elapsed  # Run time (s).
	if not e.active or e.weaken_until <= now or seconds <= 0.0:
		return 0.0
	var until := minf(e.weaken_until + seconds, now + e.weaken_span)  # New end, capped (s).
	if until <= e.weaken_until:
		return 0.0
	var added := until - e.weaken_until  # Seconds added.
	e.weaken_until = until
	return added


## True while enemy `e` is silenced by a Keening Lady's Dirge (its heals fail).
func is_silenced(e: Enemy) -> bool:
	return e.silence_until > game.elapsed


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
	duration = debuff_time(duration)  # Mournsong.
	if e.curse_until <= now:
		e.curse_amp = amp
		e.queue_redraw()
		game.stat_add("curses_applied", 1.0)
	else:
		e.curse_amp = maxf(e.curse_amp, amp)
		game.stat_add("curse_refreshes", 1.0)
	e.curse_until = maxf(e.curse_until, now + duration)


## Eclipse exposure (the ultimate's one debuff, UltimateSystem): enemy `e`
## takes `amp` (0..1) more damage from every source (damage_enemy()) from game
## time `from` (the end of the darkness) for `duration` s, lengthened by
## Mournsong like every weakening effect (debuff_time()). Reckoning enemies
## and structures are immune. A newer exposure replaces an older one. Timed
## on Game.elapsed like the curse. Stat: eclipse_exposed.
func expose_enemy(e: Enemy, amp: float, from: float, duration: float) -> void:
	if not e.active or e.is_reckoning or e.is_structure or amp <= 0.0 or duration <= 0.0:
		return
	e.expose_amp = amp
	e.expose_from = from
	e.expose_until = from + debuff_time(duration)
	game.stat_add("eclipse_exposed", 1.0)


## Frost Wraith Deep Freeze: holds `e` for `duration` s through the Stasis
## freeze path (EnemyDirector skips its AI, attacks and movement while
## Enemy.freeze_timer > 0). The boss (and a miniboss) gets `boss_mult` of the duration, elites
## `elite_mult`, Reckoning enemies are immune. Crimson March structures
## (outposts, ward generators, carts, the Holy Standard) are immune too: a
## building cannot be frozen, and a frozen one would stop its own timers
## (the Stasis power-up, a global time stop, still holds them). A longer
## freeze already running is kept. Returns the seconds applied (0 = immune).
func freeze_enemy(e: Enemy, duration: float, boss_mult: float, elite_mult: float) -> float:
	if not e.active or e.is_reckoning or e.is_structure or duration <= 0.0:
		return 0.0
	var d := duration * cc_mult()  # Freeze time for this enemy (Spirit Binding lengthens it).
	if e.is_boss or e.is_miniboss:
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
	var d := duration * cc_mult()  # Stun time for this enemy (Spirit Binding lengthens it).
	if e.is_boss or e.is_miniboss:
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
	game.effects.pop(e.position, Palette.CRIMSON if not e.is_boss else Palette.GOLD, e.radius * 1.2, "enemy_death")  # Animation when its art exists (visual only).
	game.motion.on_enemy_killed(e)  # Collapses into holy ash (visual only; not bosses or structures).
	Juice.enemy_killed(e)
	if e.xp_value > 0:
		game.pickups.spawn(e.position, e.xp_value)
		game.stat_add("xp_dropped", e.xp_value)
	game.stat_add("kill_" + e.kind, 1.0)
	game.codex.meet(CodexData.ENEMY, e.kind)  # Codex: a Covenant kind slain (records only).
	if e.rot_until > game.elapsed:
		game.stat_add("rot_kills", 1.0)  # Slain while Rotting (Plague Doctor skin, SkinData)
	if e.is_elite:
		game.stat_add("elite_kills", 1.0)  # Soul Ash elite bonus (MetaData)
	game.kills += 1
	game.abilities.on_enemy_killed(e)  # Corpse Explosion corpses, Soul Rapture bursts.
	game.powerups.on_enemy_killed(e)  # Power-up drop roll (PowerupData rules).
	game.chests.on_enemy_killed(e)  # Treasure chest roll (ChestData rules).
	game.dread_rally.on_enemy_killed(e)  # Dread Rally soul meter.
	game.ultimates.on_enemy_killed(e)  # Grave Tide raises (no-op unless it runs).
	if game.dread != null:
		game.dread.on_kill()  # Act II: a kill steadies the mind.
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
