## DreadRally — the necromancer's ultimate (GDD §3.1 / §3.3 / §5.5 "Space:
## ultimate, cooldown shown on HUD"; open question 10, resolved in GDD
## §15.0). Instead of a cooldown it has a SOUL METER filled by kills (owner
## decision): CombatResolver._kill_enemy() calls on_enemy_killed(), which
## adds PlayerAbilityData.POINTS_PER_KILL (elites, Crimson March structures
## and the boss are worth more) up to KILLS_TO_FILL. The meter persists and
## caps at full; Space (gamepad LB, action `ultimate`) spends it only when
## full. The rally then, at once:
##   * calls the army: every summon outside its formation band drops its
##     target and RETURNs to the necromancer, and every summon moves
##     SURGE_SPEED_BONUS faster for SURGE_DURATION s (no teleport),
##   * heals every summon RALLY_HEAL_FRACTION of its max HP (CombatResolver
##     .heal_unit, the one healing path),
##   * raises the whole army (RALLY_RAISES_ARMY, owner decision): every
##     missing unit of every owned class is queued for an immediate spawn
##     through HordeDirector.raise_all_missing() (the "Call of the Grave"
##     path), so the fallen rise beside the necromancer at full HP,
##   * buffs the army for RALLY_DURATION s: +RALLY_DAMAGE_BONUS damage and
##     +RALLY_ATTACK_SPEED_BONUS attack speed, read by HordeDirector
##     .compute_stats() through bonus() as its own category (like Dark
##     Frenzy); stats are recomputed when the buff and the surge start / end,
##   * knocks back enemies within KNOCKBACK_RADIUS (impulse divided by the
##     enemy's mass, so bosses resist like every other knockback; structures
##     never move),
##   * plays a dark burst (EffectManager.ring with anim id "dread_rally", so
##     sprite-sheet art plugs in through AnimData) and a big screen shake.
## Game steps it right after the player; all timers run on game time. The
## autotest bots call request() directly. No RNG: deterministic per seed.
## Ultimates (content wave 2, UltimateData): this is the ONE soul meter and the
## ONE cast request of every ultimate. With the run's ultimate (game.ultimates,
## RunConfig.ultimate_id) left at Dread Rally, the default, everything above
## runs exactly as before; with another one, a full meter's cast spends the
## meter and hands over to UltimateSystem.cast() instead (no surge, heal, raise,
## buff, knockback or Rally Barrage), and the meter does not charge while that
## ultimate runs (UltimateSystem.active(), the CHARGE_DURING_BUFF rule).
class_name DreadRally
extends RefCounted

## Owning run.
var game: Game
## Soul points collected (0..PlayerAbilityData.KILLS_TO_FILL).
var meter: float = 0.0
## Seconds of the damage / attack-speed buff left (0 = inactive).
var buff_left: float = 0.0
## Seconds of the surge (move-speed burst toward the necromancer) left.
var surge_left: float = 0.0
## Rallies cast this run.
var rallies: int = 0
## Seconds of charging each fill took (from run start or the end of the
## previous rally's buff to a full meter), in order.
var fill_times: PackedFloat32Array = PackedFloat32Array()
## Game time (s) the current fill started charging.
var _fill_start: float = 0.0
## True when a rally was requested and not processed yet.
var _queued: bool = false
## Reusable spatial-query buffer.
var _tmp: Array = []


func _init(p_game: Game) -> void:
	game = p_game


## True when the meter is full (Space casts the rally).
func is_full() -> bool:
	return meter >= PlayerAbilityData.KILLS_TO_FILL


## Meter fill 0..1 (HUD).
func fraction() -> float:
	return clampf(meter / PlayerAbilityData.KILLS_TO_FILL, 0.0, 1.0)


## True while the rally's damage / attack-speed buff runs.
func buff_active() -> bool:
	return buff_left > 0.0


## Summon stat bonus of the rally for HordeDirector.compute_stats():
## "damage" / "attack_speed" while the buff runs, "move_speed" during the
## surge; 0 otherwise.
func bonus(key: String) -> float:
	match key:
		"damage":
			return PlayerAbilityData.RALLY_DAMAGE_BONUS if buff_left > 0.0 else 0.0
		"attack_speed":
			return PlayerAbilityData.RALLY_ATTACK_SPEED_BONUS if buff_left > 0.0 else 0.0
		"move_speed":
			return PlayerAbilityData.SURGE_SPEED_BONUS if surge_left > 0.0 else 0.0
	return 0.0


## Asks for a rally on the next tick (ignored unless the meter is full).
func request() -> void:
	_queued = true


## A kill charges the meter (CombatResolver._kill_enemy). Kills during the
## buff do not count unless PlayerAbilityData.CHARGE_DURING_BUFF. `own_kill` is
## true when no summon dealt the killing blow (the necromancer's spells and the
## like): Dark Tithe (Ossuary, MetaModifiers "tithe_charge") then adds that share
## of the kill's points (exactly the old points without the upgrade).
func on_enemy_killed(e: Enemy, own_kill: bool = false) -> void:
	var pts := PlayerAbilityData.POINTS_PER_KILL  # Soul points of this kill.
	if e.is_boss:
		pts = PlayerAbilityData.POINTS_PER_BOSS
	elif e.is_elite or e.is_structure:
		pts = PlayerAbilityData.POINTS_PER_ELITE
	var tithe := game.meta.value("tithe_charge") if own_kill else 0.0  # Dark Tithe share (0 = none).
	if tithe > 0.0:
		if not is_full():
			game.stat_add("dark_tithe_points", pts * tithe)
		pts *= 1.0 + tithe
	add_points(pts)


## Adds `pts` soul points to the meter (a kill, or a freed Drowned Thrall's
## soul returning, EyeClaims), under the same rules as a kill: nothing while
## full or, unless PlayerAbilityData.CHARGE_DURING_BUFF, during the buff.
func add_points(pts: float) -> void:
	if is_full() or ((buff_left > 0.0 or game.ultimates.active()) and not PlayerAbilityData.CHARGE_DURING_BUFF):
		return
	meter = minf(PlayerAbilityData.KILLS_TO_FILL, meter + pts)
	if is_full():
		fill_times.append(game.elapsed - _fill_start)
		game.stat_add("rally_meter_fills", 1.0)


## Per-tick update (Game, after the player): casts a queued rally and runs
## the buff and surge timers, recomputing summon stats when one ends.
func step(delta: float) -> void:
	if _queued:
		_queued = false
		if is_full() and not game.player.dead:
			if game.ultimates.is_default():
				_cast()
			else:
				_cast_other()
	if surge_left > 0.0:
		surge_left -= delta
		if surge_left <= 0.0:
			surge_left = 0.0
			game.horde.recompute_all(game.horde.capacity_snapshot())
	if buff_left > 0.0:
		buff_left -= delta
		game.stat_add("rally_buff_time", delta)
		if buff_left <= 0.0:
			buff_left = 0.0
			_fill_start = game.elapsed
			game.horde.recompute_all(game.horde.capacity_snapshot())


## Another ultimate (UltimateSystem): spends the meter and casts it. Its fill
## timing restarts when it ends (restart_fill()).
func _cast_other() -> void:
	meter = 0.0
	_fill_start = game.elapsed
	game.ultimates.cast()


## The meter's next fill is timed from now (UltimateSystem, when its ultimate ends).
func restart_fill() -> void:
	_fill_start = game.elapsed


## Spends the meter: surge, heal, buff, knockback and the burst.
func _cast() -> void:
	var pos := game.player.position  # Rally centre.
	meter = 0.0
	rallies += 1
	game.stat_add("rallies", 1.0)
	buff_left = PlayerAbilityData.RALLY_DURATION
	surge_left = PlayerAbilityData.SURGE_DURATION
	_fill_start = game.elapsed  # Overwritten when the buff ends (kills do not charge meanwhile).
	# Buffed stats first (HP fraction kept), then the heal on the new max HP.
	game.horde.recompute_all(game.horde.capacity_snapshot())
	# Raise the whole army: every fallen unit is queued for an immediate spawn
	# (they rise beside the necromancer at full HP over the next frames, with
	# the rally buff already in their stats).
	if PlayerAbilityData.RALLY_RAISES_ARMY:
		var missing := game.horde.missing_count()  # Units brought back by this rally.
		game.horde.raise_all_missing()
		game.stat_add("rally_raised", float(missing))
	for u in game.horde.units:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		game.stat_add("rally_heal", game.combat.heal_unit(u, u.max_hp * PlayerAbilityData.RALLY_HEAL_FRACTION))
		_call_back(u, pos)
	game.enemy_grid.query(pos, PlayerAbilityData.KNOCKBACK_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if not e.active or e.is_structure:
			continue
		var away := e.position - pos  # Push direction.
		if away.length() > PlayerAbilityData.KNOCKBACK_RADIUS + e.radius:
			continue
		var dir := away / away.length() if away.length() > 0.01 else Vector2.RIGHT
		e.knockback += dir * PlayerAbilityData.KNOCKBACK_FORCE / maxf(e.mass, 0.1)
		game.stat_add("rally_knockbacks", 1.0)
	game.effects.ring(pos, PlayerAbilityData.KNOCKBACK_RADIUS, Palette.VIOLET, PlayerAbilityData.RALLY_RING_TIME, "dread_rally")
	# The inner ring and the vortex show only without the strip, which carries them (GDD §15.0 "Player AoE art").
	game.effects.ring_under(pos, PlayerAbilityData.KNOCKBACK_RADIUS * 0.6, Palette.NECRO_GREEN, PlayerAbilityData.RALLY_RING_TIME * 0.75, "dread_rally")
	game.effects.abyss(pos, PlayerAbilityData.KNOCKBACK_RADIUS * 0.45, "", "dread_rally")
	game.shake(PlayerAbilityData.RALLY_SHAKE)
	Sfx.play("death_nova", pos)
	game.volleys.barrage(PlayerAbilityData.RALLY_DURATION)  # Bullet heaven: the Rally Barrage.


## Surge: a summon outside its formation band (and not busy with a class
## special, a cast or rising) drops its target and returns to the
## necromancer at its (surging) return speed.
func _call_back(u: SummonedUnit, pos: Vector2) -> void:
	if u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.CASTING \
			or u.state == SummonedUnit.State.RETURNING:
		return
	if u.behavior != null and u.behavior.is_busy():
		return
	if u.position.distance_to(pos) <= u.band_max + UnitData.RETURN_ARRIVE_MARGIN:
		return
	u.clear_target()
	u.set_state(SummonedUnit.State.RETURNING)
	game.stat_add("rally_recalled", 1.0)
