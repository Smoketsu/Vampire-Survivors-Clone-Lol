## SummonAbilities — the support and evolution kits that the shared summon AI
## (SummonedUnit) calls through one-line hooks. Every kit is driven by the
## unit's effective stats (UnitData rows + SummonEvolutionData overlays), so a
## class without the stat simply never reaches these functions:
##   try_ally_barrier()  Crypt Warder / Profane Bishop: an instant barrier on
##                       the most threatened ally in reach (own cooldown),
##                       stored in SummonedUnit.barrier_hp like the Shieldwall
##                       barrier (the stronger barrier wins, no stacking;
##                       absorbed in CombatResolver.damage_unit()).
##   aura_pulse()        Profane Bishop: heals every ally (and the necromancer)
##                       in its aura and damages every enemy in it.
##   after_melee()       Death Knight: cleave around the struck enemy, then
##                       life drain from all the damage dealt.
## All damage and healing goes through CombatResolver. Statistics use the
## unit's dmg_source tag: heal_by_<tag>, shield_by_<tag> and the damage
## sources ("death_knight_cleave", "bishop"...).
class_name SummonAbilities
extends RefCounted

## Reusable spatial-query buffer (all calls run on the main thread).
static var _buf: Array = []


## Warder / Bishop ally barrier: picks the threatened ally in acquisition
## range whose barrier is weakest (score: missing barrier, missing HP, role
## priority; UnitData.ALLY_WARD_*), raises its barrier to `u.ally_shield_amount`
## and starts the cooldown. An ally is threatened if it was hit within
## UnitData.ALLY_WARD_HIT_WINDOW s, or it is a blocker (warrior / Death
## Knight) fighting in melee. Allies still holding at least
## ALLY_WARD_REFRESH_FRACTION of the barrier are skipped. Nothing to protect
## leaves the cooldown ready (it retries on the next think).
static func try_ally_barrier(u: SummonedUnit) -> void:
	var amount := u.ally_shield_amount  # Barrier HP this unit grants.
	var game := u.game
	game.ally_grid.query(u.position, u.acquisition_range, _buf)
	var best: SummonedUnit = null  # Ally that gets the barrier.
	var best_score := -INF  # Its score.
	for a: SummonedUnit in _buf:
		if not a.active or a.state == SummonedUnit.State.SPAWNING or a.state == SummonedUnit.State.DEAD:
			continue
		if a.barrier_hp >= amount * UnitData.ALLY_WARD_REFRESH_FRACTION:
			continue
		var fighting := a.block_radius > 0.0 and (a.state == SummonedUnit.State.ENGAGING or a.state == SummonedUnit.State.CASTING) and a.target != null
		if a.since_hit > UnitData.ALLY_WARD_HIT_WINDOW and not fighting:
			continue
		var score := UnitData.ALLY_WARD_W_BARRIER * (1.0 - a.barrier_hp / amount) \
				+ UnitData.ALLY_WARD_W_HURT * (1.0 - a.hp / maxf(a.max_hp, 1.0)) \
				+ UnitData.ALLY_WARD_W_ROLE * a.heal_role_priority
		if score > best_score:
			best_score = score
			best = a
	if best == null:
		return
	var gained := amount - best.barrier_hp  # Barrier HP actually added.
	best.barrier_hp = amount
	best.queue_redraw()
	u.ally_shield_cd = u.ally_shield_cooldown
	game.effects.beam(u.position, best.position, Palette.COLD_BLUE)
	game.stat_add("ally_barriers", 1.0)
	game.stat_add("shield_by_" + u.dmg_source, gained)


## Profane Bishop aura pulse: heals every living ally and the necromancer
## within `u.aura_radius` by `u.aura_heal`, and damages every enemy inside by
## `u.aura_damage` (source = the unit's dmg_source). Called from the unit's
## physics step on its own timer.
static func aura_pulse(u: SummonedUnit) -> void:
	var game := u.game
	var r := u.aura_radius  # Pulse radius (px).
	var healed := 0.0  # HP restored by this pulse.
	if u.aura_heal > 0.0:
		game.ally_grid.query(u.position, r, _buf)
		for a: SummonedUnit in _buf:
			if a.active and a.state != SummonedUnit.State.SPAWNING and a.hp < a.max_hp:
				healed += game.combat.heal_unit(a, u.aura_heal)
		var p := game.player
		if not p.dead and p.position.distance_to(u.position) <= r + p.radius:
			healed += game.combat.heal_player(u.aura_heal)
	var hit := 0  # Enemies damaged.
	if u.aura_damage > 0.0:
		game.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
		for e: Enemy in _buf:
			if e.active and e.position.distance_to(u.position) <= r + e.radius:
				game.combat.damage_enemy(e, u.aura_damage, u.dmg_source)
				hit += 1
	if healed > 0.0 or hit > 0:
		game.effects.ring(u.position, r, Palette.NECRO_GREEN, 0.45)
		game.effects.ring(u.position, r * 0.6, Palette.VIOLET, 0.35)
	game.stat_add("aura_pulses", 1.0)
	game.stat_add("heal_by_" + u.dmg_source, healed)


## Death Knight follow-up of a landed melee hit on `primary` (`dealt` damage
## at `center`, swing direction `dir`): every OTHER enemy within `u.cleave_radius` of the
## struck enemy takes `u.cleave_fraction` of the hit (source
## "<evolution>_cleave"); then the unit heals `u.lifesteal` of everything
## dealt (heal_by_<tag>).
static func after_melee(u: SummonedUnit, primary: Enemy, center: Vector2, dir: Vector2, dealt: float) -> void:
	var game := u.game
	var total := dealt  # All damage this swing dealt.
	if u.cleave_radius > 0.0 and u.cleave_fraction > 0.0:
		var src := u.dmg_source + "_cleave"  # Damage tag of the cleave.
		game.enemy_grid.query(center, u.cleave_radius + ProjectileManager.MAX_BODY_RADIUS, _buf)
		for e: Enemy in _buf:
			if not e.active or e == primary:
				continue  # Dead, or the struck enemy itself.
			if e.position.distance_to(center) <= u.cleave_radius + e.radius:
				total += game.combat.damage_enemy(e, u.damage * u.cleave_fraction, src)
		game.effects.slash(center, dir, Palette.VIOLET, u.cleave_radius)
	if u.lifesteal > 0.0 and total > 0.0 and u.active:
		game.stat_add("heal_by_" + u.dmg_source, game.combat.heal_unit(u, total * u.lifesteal))
