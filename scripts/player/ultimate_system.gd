## UltimateSystem — the run's chosen ULTIMATE (content wave 2, owner-approved
## Proposal 4; GDD §15.0 "Ultimates (content wave 2)"; numbers in UltimateData).
## There is ONE soul meter (DreadRally: kills fill it, Space / pad LB / the touch
## button asks for a cast), ONE action, ONE HUD slot and ONE touch button; this
## object (game.ultimates, never null) only says WHICH ultimate the full meter
## casts (RunConfig.ultimate_id, or the autotest's --ultimate=) and runs the
## three new ones. DreadRally.step() spends the meter and calls cast() for every
## ultimate but Dread Rally, whose own code path and numbers are unchanged, so a
## Dread Rally run plays bit-for-bit as before (every hook below is a no-op
## returning 0 / null / false unless a new ultimate is running).
##   * Sovereign's Decree (DECREE_*): for 8 s every living summon taunts the
##     enemies within DECREE_TAUNT_RADIUS (Enemy._pick_target() asks
##     taunt_target() first; bosses, Reckoning enemies and structures ignore
##     it), every summon takes DECREE_DAMAGE_REDUCTION less damage
##     (CombatResolver.damage_unit() reads unit_damage_reduction()), and the
##     necromancer cannot be targeted: enemies retarget summons through the
##     taunt, and every hit that still reaches him (a projectile already in
##     flight, a boss attack, a stage hazard; they hit his body as before and
##     are spent harmlessly) is ignored in CombatResolver.damage_player()
##     before any other rule (player_untargetable()).
##   * Eclipse (ECLIPSE_*): 4 s of darkness. At the cast and twice a second
##     while it lasts, every enemy "on screen" (ECLIPSE_HALF_VIEW around the
##     necromancer: the 1280 x 720 view at Normal zoom, fixed so a zoom setting
##     never changes gameplay) is held for the darkness left through
##     CombatResolver.freeze_enemy() (the one hold path: Reckoning enemies and
##     structures are immune there); bosses and minibosses are never frozen or
##     stunned: CombatResolver.slow_enemy() slows them ECLIPSE_BOSS_SLOW
##     instead. Every enemy caught is exposed through
##     CombatResolver.expose_enemy() (the one Eclipse debuff): from
##     ECLIPSE_EXPOSE_LEAD s before the end of the darkness (from the cast at
##     the default) it takes ECLIPSE_EXPOSE_AMP more damage, until
##     ECLIPSE_EXPOSE_DURATION s after the darkness (ECLIPSE_EXPOSE_BOSS_MULT
##     of it on bosses and minibosses).
##   * Grave Tide (TIDE_*): for 10 s every enemy that dies (on_enemy_killed(),
##     from CombatResolver._kill_enemy()) rises where it fell as a temporary
##     Risen fighting for the necromancer (HordeDirector.spawn_temporary(), so
##     Restless Dead and the Grave Herald's Restless innate apply there); never
##     a boss, miniboss, Reckoning enemy or structure; at most TIDE_MAX_ALIVE
##     alive at once and TIDE_RAISES_PER_TICK raised per tick (deaths are
##     queued and raised in step(), outside the kill code).
## While a new ultimate runs the meter does not charge (the rule of the rally
## buff, PlayerAbilityData.CHARGE_DURING_BUFF); when it ends the meter's next
## fill starts timing (DreadRally.restart_fill()). Each cast plays its burst
## (EffectManager.ring with the ultimate's anim id, so a strip plugs in through
## AnimData), its synthesized sound through Sfx and a screen overlay
## (UltimateOverlay, visual only). No RNG, game time only: deterministic per
## seed. Stats (the autotest's "ultimate" line): ult_casts, decree_*,
## eclipse_*, tide_*.
class_name UltimateSystem
extends RefCounted

## Owning run.
var game: Game
## UltimateData id of the run's ultimate.
var id: String = UltimateData.DEFAULT_ID
## Casts of the run's ultimate (Dread Rally's are counted by DreadRally.rallies too).
var casts: int = 0
## Seconds of Sovereign's Decree left (0 = not running).
var decree_left: float = 0.0
## Seconds of Eclipse darkness left (0 = not running).
var eclipse_left: float = 0.0
## Game time (s) the current darkness ends (the exposure starts then).
var eclipse_end: float = 0.0
## Seconds to the next Eclipse catch pulse while dark.
var _eclipse_pulse: float = 0.0
## Seconds of Grave Tide left (0 = not running).
var tide_left: float = 0.0
## Deaths waiting to rise during the Tide (positions, oldest first).
var _tide_queue: Array[Vector2] = []
## Act III: for each of _tide_queue, true when that foe was a cyborg (it rises
## as a Grave Gunner, HordeDirector.raise_corpse()); a machine is never queued.
var _tide_gunner: Array[bool] = []
## Living Tide Risen as [SummonedUnit, generation] (stale entries dropped).
var _risen: Array = []
## Reusable spatial-query buffer.
var _buf: Array = []


func _init(p_game: Game, p_id: String) -> void:
	game = p_game
	id = p_id if UltimateData.ULTIMATES.has(p_id) else UltimateData.DEFAULT_ID


## True when the run's ultimate is Dread Rally (DreadRally casts it itself).
func is_default() -> bool:
	return id == UltimateData.DEFAULT_ID


## The run ultimate's UltimateData row.
func row() -> Dictionary:
	return UltimateData.ULTIMATES[id]


## Icon key of the run's ultimate (HUD, touch button, pause screen).
func icon() -> String:
	return String(row()["icon"])


## UI name of the run's ultimate.
func display_name() -> String:
	return String(row()["display_name"])


## True while one of the new ultimates runs (the meter does not charge).
func active() -> bool:
	return decree_left > 0.0 or eclipse_left > 0.0 or tide_left > 0.0


## Seconds left of the running ultimate's main effect (Dread Rally: its buff;
## 0 = none running). HUD / touch button.
func time_left() -> float:
	match id:
		"sovereigns_decree":
			return decree_left
		"eclipse":
			return eclipse_left
		"grave_tide":
			return tide_left
	return game.dread_rally.buff_left


## Full length (s) of the run ultimate's main effect (the HUD's time bar).
func duration() -> float:
	match id:
		"sovereigns_decree":
			return UltimateData.DECREE_DURATION
		"eclipse":
			return UltimateData.ECLIPSE_DARK_DURATION
		"grave_tide":
			return UltimateData.TIDE_DURATION
	return PlayerAbilityData.RALLY_DURATION


# =====================================================================================
# Hooks of the single paths (no-ops unless a new ultimate runs)
# =====================================================================================

## Sovereign's Decree taunt (Enemy._pick_target(), before every other choice):
## the nearest living, grounded summon within DECREE_TAUNT_RADIUS of `e`, or
## null (no Decree, nobody in reach, or a boss / Reckoning enemy / structure).
func taunt_target(e: Enemy) -> SummonedUnit:
	if decree_left <= 0.0 or e.is_boss or e.is_reckoning or e.is_structure:
		return null
	game.ally_grid.query(e.position, UltimateData.DECREE_TAUNT_RADIUS, _buf)
	var best: SummonedUnit = null  # Nearest summon in reach.
	var best_d := INF  # Its distance (px).
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue
		var d := e.position.distance_to(u.position)  # Centre distance (px).
		if d <= UltimateData.DECREE_TAUNT_RADIUS and d < best_d:
			best_d = d
			best = u
	return best


## Fraction of a hit on a summon removed by the Decree (CombatResolver
## .damage_unit(); 0 unless it runs).
func unit_damage_reduction() -> float:
	return UltimateData.DECREE_DAMAGE_REDUCTION if decree_left > 0.0 else 0.0


## True while the Decree makes the necromancer untargetable
## (CombatResolver.damage_player() ignores every hit).
func player_untargetable() -> bool:
	return decree_left > 0.0 and UltimateData.DECREE_UNTARGETABLE


## A hit of `amount` on the untargetable necromancer was ignored (stats).
func on_player_hit_ignored(amount: float) -> void:
	game.stat_add("decree_player_hits_ignored", 1.0)
	game.stat_add("decree_player_dmg_prevented", amount)


## Kill hook (CombatResolver._kill_enemy()): during the Tide a fallen enemy
## (never a boss, miniboss, Reckoning enemy, structure or Act III machine:
## Enemy.leaves_corpse()) is queued to rise; a cyborg rises as a Grave Gunner.
func on_enemy_killed(e: Enemy) -> void:
	if tide_left <= 0.0:
		return
	if e.is_boss or e.is_miniboss or e.is_reckoning or not e.leaves_corpse():
		return
	if _tide_queue.size() >= UltimateData.TIDE_QUEUE_MAX:
		game.stat_add("tide_capped", 1.0)
		return
	_tide_queue.append(e.position)
	_tide_gunner.append(e.rises_as_gunner())


# =====================================================================================
# Cast and step
# =====================================================================================

## Casts the run's (new) ultimate at the necromancer (DreadRally.step() after
## spending the meter).
func cast() -> void:
	var pos := game.player.position  # Cast centre.
	casts += 1
	game.stat_add("ult_casts", 1.0)
	var r := row()
	match id:
		"sovereigns_decree":
			decree_left = UltimateData.DECREE_DURATION
			_burst(pos, UltimateData.DECREE_RING_RADIUS, UltimateData.DECREE_RING_TIME, UltimateData.DECREE_SHAKE)
		"eclipse":
			eclipse_left = UltimateData.ECLIPSE_DARK_DURATION
			eclipse_end = game.elapsed + UltimateData.ECLIPSE_DARK_DURATION
			_eclipse_catch()
			_eclipse_pulse = 0.5
			_burst(pos, UltimateData.ECLIPSE_RING_RADIUS, UltimateData.ECLIPSE_RING_TIME, UltimateData.ECLIPSE_SHAKE)
		"grave_tide":
			tide_left = UltimateData.TIDE_DURATION
			_burst(pos, UltimateData.TIDE_RING_RADIUS, UltimateData.TIDE_RING_TIME, UltimateData.TIDE_SHAKE)
	Sfx.play(String(r["sound"]), pos)


## The cast burst: the ultimate's strip (or drawn rings), an inner ring and a shake.
func _burst(pos: Vector2, radius: float, time: float, shake: float) -> void:
	var col: Color = row()["color"]
	game.effects.ring(pos, radius, col, time, String(row()["anim"]))
	game.effects.ring_under(pos, radius * 0.6, col.lightened(0.3), time * 0.75, String(row()["anim"]))  # Only without the cast strip (GDD §15.0 "Player AoE art").
	game.shake(shake)


## Per-tick update (Game, right after DreadRally): the timers, the Eclipse
## pulses and the Tide's raises. Ends restart the meter's fill timing.
func step(delta: float) -> void:
	if decree_left > 0.0:
		decree_left -= delta
		game.stat_add("decree_time", delta)
		if decree_left <= 0.0:
			decree_left = 0.0
			_ended()
	if eclipse_left > 0.0:
		eclipse_left -= delta
		_eclipse_pulse -= delta
		if eclipse_left <= 0.0:
			eclipse_left = 0.0
			_ended()
		elif _eclipse_pulse <= 0.0:
			_eclipse_pulse += 0.5
			_eclipse_catch()
	if tide_left > 0.0:
		tide_left -= delta
		if tide_left <= 0.0:
			tide_left = 0.0
			_ended()
	if not _tide_queue.is_empty():
		_raise_tide()


## A new ultimate ended: the meter charges again and times its next fill.
func _ended() -> void:
	if not active():
		game.dread_rally.restart_fill()


## Eclipse: holds every enemy on screen not caught yet by this Eclipse for the
## darkness left (bosses and minibosses slowed instead) and exposes it from
## ECLIPSE_EXPOSE_LEAD s before the darkness' end (Enemy.expose_from marks the catch).
func _eclipse_catch() -> void:
	var left := eclipse_end - game.elapsed  # Darkness left (s).
	if left <= 0.0:
		return
	var lead := clampf(UltimateData.ECLIPSE_EXPOSE_LEAD, 0.0, UltimateData.ECLIPSE_DARK_DURATION)  # Exposure lead (s).
	var expose_from := eclipse_end - lead  # Game time this Eclipse's exposure starts (also its catch marker).
	var view := Rect2(game.player.position - UltimateData.ECLIPSE_HALF_VIEW, UltimateData.ECLIPSE_HALF_VIEW * 2.0)  # "On screen".
	var c := game.combat
	for e: Enemy in game.enemies.active:
		if not e.active or e.is_structure or e.is_reckoning or not view.has_point(e.position):
			continue
		if e.expose_from == expose_from:
			continue  # Already caught by this Eclipse (held for the rest of the darkness).
		var big := e.is_boss or e.is_miniboss  # Never frozen or stunned (owner guardrail).
		if big:
			c.slow_enemy(e, UltimateData.ECLIPSE_BOSS_SLOW, left)
			game.stat_add("eclipse_bosses_slowed", 1.0)
		elif c.freeze_enemy(e, left, 0.0, UltimateData.ECLIPSE_ELITE_MULT) > 0.0:
			game.stat_add("eclipse_frozen", 1.0)
		var amp := UltimateData.ECLIPSE_EXPOSE_AMP * (UltimateData.ECLIPSE_EXPOSE_BOSS_MULT if big else 1.0)  # Exposure of this enemy.
		c.expose_enemy(e, amp, expose_from, UltimateData.ECLIPSE_EXPOSE_DURATION + lead)


## Grave Tide: raises queued deaths as temporary Risen (cap alive, cap per tick).
func _raise_tide() -> void:
	var n := 0  # Raised this tick.
	while not _tide_queue.is_empty() and n < UltimateData.TIDE_RAISES_PER_TICK:
		var pos: Vector2 = _tide_queue.pop_front()
		var gunner: bool = _tide_gunner.pop_front()  # Act III: a cyborg's corpse.
		if _risen_alive() >= UltimateData.TIDE_MAX_ALIVE:
			game.stat_add("tide_capped", 1.0)
			continue
		var u := game.horde.raise_corpse(UltimateData.TIDE_RISEN_CLASS, pos, UltimateData.TIDE_RISEN_LIFE,
				UltimateData.TIDE_RISEN_HP, UltimateData.TIDE_RISEN_DAMAGE, "grave_tide_risen", "risen", gunner)
		_risen.append([u, u.generation])
		game.stat_add("tide_risen", 1.0)
		n += 1
	if n > 0:
		Sfx.play("summon_rise", game.player.position)


## Living Tide Risen (stale entries are dropped).
func _risen_alive() -> int:
	var i := _risen.size() - 1
	while i >= 0:
		var u: SummonedUnit = _risen[i][0]
		if not u.active or u.generation != int(_risen[i][1]):
			_risen.remove_at(i)
		i -= 1
	return _risen.size()


## Living Tide Risen right now (overlay and summary).
func risen_alive() -> int:
	return _risen_alive()


## The autotest summary line of the run's ultimate ("" for Dread Rally, whose
## own "dread rally" line is unchanged).
func summary_line(st: Dictionary) -> String:
	match id:
		"sovereigns_decree":
			return "sovereign's decree: casts %d | time %.0f s | taunted %d | summon dmg prevented %d | hits on you ignored %d (dmg prevented %d)" % [
				casts, float(st.get("decree_time", 0.0)), int(st.get("decree_taunts", 0.0)), int(st.get("decree_dmg_prevented", 0.0)),
				int(st.get("decree_player_hits_ignored", 0.0)), int(st.get("decree_player_dmg_prevented", 0.0))]
		"eclipse":
			return "eclipse: casts %d | frozen %d | bosses slowed %d | exposed %d, bonus dmg %d" % [
				casts, int(st.get("eclipse_frozen", 0.0)), int(st.get("eclipse_bosses_slowed", 0.0)),
				int(st.get("eclipse_exposed", 0.0)), int(st.get("eclipse_bonus_dmg", 0.0))]
		"grave_tide":
			return "grave tide: casts %d | risen %d (capped %d) | risen dmg %d, kills %d" % [
				casts, int(st.get("tide_risen", 0.0)), int(st.get("tide_capped", 0.0)),
				int(st.get("dmg_grave_tide_risen", 0.0)), int(st.get("kills_by_grave_tide_risen", 0.0))]
	return ""
