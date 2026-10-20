## PowerupManager — power-up drops and the timed buffs they grant (user
## request; data and drop rules in PowerupData):
##   * rolls a drop on every enemy kill (CombatResolver._kill_enemy calls
##     on_enemy_killed): regular / elite chances scaled by the Profane Pact /
##     Oath reward (game.difficulty.drop_mult()), a guaranteed boss drop, a
##     pity timer, a weighted type draw, a cap on live drops; no drops from
##     Reckoning enemies or after 0:00,
##   * pools Powerup nodes, ages them (despawn after LIFETIME, blinking at the
##     end) and collects them when the necromancer walks over one,
##   * applies the effect: Soul Magnet (XpManager.magnetize_all), Grave Feast
##     (CombatResolver.heal_player), Soul Nova (screen clear through
##     CombatResolver.damage_enemy) or a timed buff (Hyper, Stasis, Dark
##     Frenzy). Re-collecting an active buff refreshes its duration (no
##     stacking),
##   * exposes the buff values the existing stat paths read:
##     spell_damage_mult() / spell_cooldown_mult() (AbilityManager.spell_stats),
##     frenzy_bonus() (HordeDirector.compute_stats) and freezes()
##     (EnemyDirector.step),
##   * counts drops spawned / collected / expired per type and buff uptime in
##     Game.stats for the autotest summary.
## Drop rolls use their own RandomNumberGenerator (seeded from the autotest
## seed), so they never shift the gameplay RNG stream and runs stay
## deterministic per seed.
## Co-op (CoopSession): a drop goes to whichever standing necromancer touches
## it first (slot order), collected with that slot bound; `timers` /
## `stasis_total` are the BOUND slot's (CoopSession.bind() swaps them), so a
## Hyper or Dark Frenzy buff powers its collector's spells and army only, while
## a Stasis from either player holds every enemy (freezes()).
class_name PowerupManager
extends Node2D

## A power-up was collected (HUD / Juice / tests).
signal collected(kind: String)

## Owning run.
var game: Game
## Drops lying in the world.
var active: Array[Powerup] = []
## Idle drop nodes ready for reuse.
var _pool: Array[Powerup] = []
## Total Powerup nodes ever instantiated (debug: pool health).
var created: int = 0
## Timed buff id -> seconds left (absent or <= 0 = inactive).
var timers: Dictionary = {}
## Full duration of the current Stasis (for Sir Alaric's shorter freeze).
var stasis_total: float = 0.0
## Game seconds since the last drop was spawned (pity timer).
var since_drop: float = 0.0
## Drops spawned so far (also the serial of the next drop).
var spawned: int = 0
## Drop / type RNG, separate from the global gameplay RNG.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -1
	if game.seeded():
		_rng.seed = hash("powerups:%d" % game.run_seed())
	else:
		_rng.randomize()


# =====================================================================================
# Per-tick update
# =====================================================================================

## Ages drops, collects the ones the necromancer walks over, ticks buffs.
## Called by Game every physics tick after the XP pickups.
func step(delta: float) -> void:
	since_drop += delta
	var p := game.player.position  # Necromancer position.
	var reach := game.player.radius + PowerupData.PICKUP_RADIUS  # Collection distance (px).
	var i := 0  # Index into `active` (swap-remove while iterating).
	while i < active.size():
		var d := active[i]  # Drop being updated.
		if d.position.distance_to(p) <= reach:
			_release(i)
			collect(d.kind, d.position)
			continue
		if not d.tick(delta):
			game.stat_add("pu_expired_" + d.kind, 1.0)
			_release(i)
			continue
		i += 1
	tick_buffs(delta)


## Co-op (CoopSession.step()): ages the drops and collects the ones a standing
## necromancer touches (the first in slot order), with that slot bound. The
## buffs tick per slot afterwards (tick_buffs()).
func step_drops(delta: float) -> void:
	since_drop += delta
	var co := game.coop
	var i := 0  # Index into `active` (swap-remove while iterating).
	while i < active.size():
		var d := active[i]  # Drop being updated.
		var taker := -1  # Slot that touches it (-1 = none).
		for s in co.slots:
			if s.alive() and d.position.distance_to(s.player.position) <= s.player.radius + PowerupData.PICKUP_RADIUS:
				taker = s.index
				break
		if taker >= 0:
			_release(i)
			var prev := co.bound
			co.bind(taker)
			collect(d.kind, d.position)
			co.bind(prev)
			continue
		if not d.tick(delta):
			game.stat_add("pu_expired_" + d.kind, 1.0)
			_release(i)
			continue
		i += 1


## Ticks the timed buffs of the bound player (solo: the one; co-op: called once
## per slot with it bound).
func tick_buffs(delta: float) -> void:
	for kind: String in PowerupData.TIMED:
		var left := float(timers.get(kind, 0.0))  # Seconds left on this buff.
		if left <= 0.0:
			continue
		var used := minf(left, delta)  # Buff time spent this tick.
		game.stat_add("pu_uptime_" + kind, used)
		timers[kind] = left - delta
		if float(timers[kind]) <= 0.0:
			timers[kind] = 0.0
			_on_buff_changed(kind)


## Removes active[idx] (swap-remove) and pools it.
func _release(idx: int) -> void:
	var d := active[idx]  # Drop leaving the world.
	active[idx] = active[active.size() - 1]
	active.pop_back()
	d.deactivate()
	_pool.append(d)


# =====================================================================================
# Drops
# =====================================================================================

## Kill hook (CombatResolver._kill_enemy): rolls and spawns a drop.
func on_enemy_killed(e: Enemy) -> void:
	if e.is_reckoning or game.countdown_finished():
		return
	if e.is_boss:
		for _n in PowerupData.BOSS_DROPS:
			spawn_drop(_pick_kind(), e.position, true)
		return
	# Base drop chance (an elite promoted by the difficulty level drops like a soldier).
	var chance := PowerupData.CHANCE_ELITE if e.is_elite and not e.is_promoted else PowerupData.CHANCE_NORMAL  # Base drop chance.
	chance *= game.difficulty.drop_mult()
	var pity := since_drop >= PowerupData.PITY_TIME  # Pity timer ran out: guaranteed.
	var rolled := _rng.randf() < chance  # Regular drop roll succeeded.
	if not pity and not rolled:
		return
	if active.size() >= PowerupData.MAX_LIVE:
		# Ground full: a won roll is lost; pity simply waits.
		if rolled:
			game.stat_add("pu_lost_at_cap", 1.0)
		return
	spawn_drop(_pick_kind(), e.position, false)
	if pity and not rolled:
		game.stat_add("pu_pity_drops", 1.0)


## Spawns drop `kind` at `pos`. At MAX_LIVE the drop is lost unless `force`,
## which replaces the oldest live drop. Returns true if a drop was placed.
func spawn_drop(kind: String, pos: Vector2, force: bool) -> bool:
	if active.size() >= PowerupData.MAX_LIVE:
		if not force:
			return false
		var oldest := 0  # Index of the oldest live drop.
		for j in active.size():
			if active[j].serial < active[oldest].serial:
				oldest = j
		_release(oldest)
	var d: Powerup  # Drop node to place (pooled or new).
	if _pool.is_empty():
		d = Powerup.new()
		add_child(d)
		created += 1
	else:
		d = _pool.pop_back()
	d.setup(kind, game.arena.free_point(pos, PowerupData.TOKEN_RADIUS), spawned)
	active.append(d)
	spawned += 1
	since_drop = 0.0
	game.stat_add("pu_spawned_" + kind, 1.0)
	return true


## Weighted random power-up id (PowerupData weights; the Scarcity run
## modifier lowers Grave Feast's through game.difficulty.powerup_weight).
func _pick_kind() -> String:
	var total := 0.0  # Sum of all weights.
	for kind: String in PowerupData.ORDER:
		total += game.difficulty.powerup_weight(kind, float(PowerupData.POWERUPS[kind]["weight"]))
	var roll := _rng.randf() * total  # Position inside the weight line.
	for kind: String in PowerupData.ORDER:
		roll -= game.difficulty.powerup_weight(kind, float(PowerupData.POWERUPS[kind]["weight"]))
		if roll <= 0.0:
			return kind
	return PowerupData.ORDER[0]


# =====================================================================================
# Effects
# =====================================================================================

## Applies power-up `kind` (collected at `pos`). Timed buffs are set to
## their full duration, so collecting one again refreshes it (no stacking).
func collect(kind: String, pos: Vector2) -> void:
	var def: Dictionary = PowerupData.POWERUPS[kind]  # Power-up definition.
	game.stat_add("pu_collected_" + kind, 1.0)
	match kind:
		"magnet":
			game.stat_add("pu_magnet_crystals", float(game.pickups.magnetize_all()))
		"feast":
			game.combat.heal_player(game.player.max_hp * float(def["heal_fraction"]) * game.difficulty.feast_heal_mult())
		"nova":
			_soul_nova(def)
		_:
			var was_active := is_active(kind)  # Refresh instead of a fresh start.
			timers[kind] = float(def["duration"])
			if kind == "stasis":
				stasis_total = float(def["duration"])
			if was_active:
				game.stat_add("pu_refreshed_" + kind, 1.0)
			else:
				_on_buff_changed(kind)
	Juice.powerup_collected(kind, pos)
	collected.emit(kind)


## Soul Nova: every enemy inside the visible area (plus screen_margin) is
## hit through CombatResolver, so kills drop XP and count as usual. Regular
## enemies take their full HP (armour included, so they die), elites lose
## elite_hp_fraction of their current HP, the boss boss_max_hp_fraction of
## his max HP. Reckoning enemies are immune.
func _soul_nova(def: Dictionary) -> void:
	var half := game.gameplay_view_size() * 0.5 + Vector2.ONE * float(def["screen_margin"])  # Half-extent of the hit area (co-op: one fixed size).
	var area := Rect2(game.player.position - half, half * 2.0)  # Visible world rect.
	var kills_before := game.kills  # To count the Nova's kills.
	for e in game.enemies.active:
		if not e.active or e.is_reckoning or not area.has_point(e.position):
			continue
		var amount := 0.0  # Damage before armour.
		if e.is_boss:
			amount = e.max_hp * float(def["boss_max_hp_fraction"])
		elif e.is_elite or e.is_structure:
			# Crimson March structures (outposts, generators, carts) count as elites.
			amount = e.hp * float(def["elite_hp_fraction"])
		else:
			amount = e.hp + 1.0  # A little extra so rounding never leaves a sliver.
		# Undo armour so the intended amount is what lands.
		game.combat.damage_enemy(e, amount / maxf(0.05, 1.0 - e.armor), "nova")
	game.stat_add("nova_kills", float(game.kills - kills_before))
	game.effects.ring(game.player.position, half.length(), Color(0.92, 0.85, 1.0), 0.6, "soul_nova")  # Animation when its art exists (visual only).
	game.effects.ring_under(game.player.position, half.length() * 0.6, Palette.VIOLET, 0.5, "soul_nova")  # Drawn only without the nova art.
	game.shake(Juice.MAX_SHAKE_PX)


## A timed buff started or ended: refresh the stats that cache it.
func _on_buff_changed(kind: String) -> void:
	match kind:
		"hyper":
			game.abilities.invalidate_spell_stats()
		"frenzy":
			game.horde.recompute_all(game.horde.capacity_snapshot())


## True while timed buff `kind` is running.
func is_active(kind: String) -> bool:
	return float(timers.get(kind, 0.0)) > 0.0


## Seconds left of timed buff `kind` (0 when inactive).
func time_left(kind: String) -> float:
	return maxf(0.0, float(timers.get(kind, 0.0)))


## Spell damage multiplier from Hyper (1 when inactive).
func spell_damage_mult() -> float:
	return float(PowerupData.POWERUPS["hyper"]["damage_mult"]) if is_active("hyper") else 1.0


## Spell cooldown multiplier from Hyper (1 when inactive).
func spell_cooldown_mult() -> float:
	return float(PowerupData.POWERUPS["hyper"]["cooldown_mult"]) if is_active("hyper") else 1.0


## Dark Frenzy bonus of `key` ("damage_bonus" / "attack_speed_bonus"; 0 when
## inactive).
func frenzy_bonus(key: String) -> float:
	return float(PowerupData.POWERUPS["frenzy"][key]) if is_active("frenzy") else 0.0


## True if enemy `e` is held by Stasis right now: every enemy while it runs,
## except Reckoning enemies (immune) and the stage boss (and a miniboss, the
## Cathedral Guardian) after the first boss_fraction of the duration.
func freezes(e: Enemy) -> bool:
	if game.coop != null:
		return game.coop.stasis_freezes(e)  # Co-op: a Stasis of either player stops time.
	var left := time_left("stasis")  # Stasis seconds left.
	if left <= 0.0 or e.is_reckoning:
		return false
	if e.is_boss or e.is_miniboss:
		return stasis_total - left < stasis_total * float(PowerupData.POWERUPS["stasis"]["boss_fraction"])
	return true


## The freezes() rule for one player's buff timers `t` and Stasis length
## `total` (co-op: CoopSession.stasis_freezes() asks it for each slot).
static func stasis_holds(t: Dictionary, total: float, e: Enemy) -> bool:
	var left := maxf(0.0, float(t.get("stasis", 0.0)))  # Stasis seconds left.
	if left <= 0.0 or e.is_reckoning:
		return false
	if e.is_boss or e.is_miniboss:
		return total - left < total * float(PowerupData.POWERUPS["stasis"]["boss_fraction"])
	return true


## HUD helper: [{kind, left, total}] for every running timed buff.
func active_buffs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []  # One entry per running buff.
	for kind: String in PowerupData.TIMED:
		if is_active(kind):
			out.append({"kind": kind, "left": time_left(kind), "total": float(PowerupData.POWERUPS[kind]["duration"])})
	return out


## Nearest live drop within `reach` px of `p` (null if none; autotest bot).
func nearest_drop(p: Vector2, reach: float) -> Powerup:
	var best: Powerup = null  # Closest drop found so far.
	var best_d := reach  # Its distance (starts at the search radius).
	for d in active:
		var dist := d.position.distance_to(p)  # Distance to this drop.
		if dist < best_d:
			best_d = dist
			best = d
	return best
