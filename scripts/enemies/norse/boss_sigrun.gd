## BossSigrun — SIGRUN, THE SHIELD-QUEEN, the boss of Valgard, the Hall of
## Heroes (the Hall of the Slain, temporarily Act XI; Stage 17 in the final
## order; GDD §15.0 "Sigrun, the Shield-Queen (the Hall of the Slain)";
## owner-approved proposal: "the Charge (spear dives across the ring on
## telegraphed lines with her valkyrie wing), the Holmgang (she challenges the
## necromancer to a duel: a square of hazel rods closes around the two of them
## for 15 s, and summons cannot enter; spells and Grave Step only), the Doors of
## the Hall"; owner decision Nov 7, 2026: "the Doors of the Hall: every
## Einherjar of the hall marches out at her side", a scripted wave). Loaded by
## name for the boss id "sigrun" (EnemyDirector.NORSE_BOSS_DIR +
## "boss_sigrun.gd"); she arrives at 17:00 (3:00 left) with her valkyrie wing.
## Extends Boss, so summons, spells and the spatial hash treat her like any
## enemy. Every ability is telegraphed; the numbers and the three phases are
## SigrunData's (see its header):
##   * THE CHARGE: her lane through the necromancer and her wing's beside it
##     (WingValkyrieKit.charge(); the one charge hit WingValkyrieKit.lane()).
##   * THE HOLMGANG: the square (Holmgang, the one keep-out path), the duel's
##     spell-only rule (damage_taken_mult(), the one read), her spear lunge, the
##     yield or her win; a duel won without a Grave Step sets
##     SigrunData.HOLMGANG_STAT (the achievement Holmgang).
##   * THE DOORS OF THE HALL: the scripted wave of Einherjar out of the doors
##     beyond her and the Feast's wake (ValgardDirector.wake_feast(); on another
##     stage with --boss=sigrun only the wave marches).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks
## Valkyrie Spear and Einherjar's Oath (UnlockData, boss "sigrun"). No RNG.
## Stats: boss_atk_<special>, sigrun_charge_hits, sigrun_phase2_at,
## sigrun_phase3_at, sigrun_duels, sigrun_duels_won, sigrun_duels_lost,
## sigrun_duels_clean, sigrun_holmgang_warded, sigrun_duel_spell_dmg,
## sigrun_lunge_hits, sigrun_doors_einherjar, sigrun_wing, the run stat
## SigrunData.HOLMGANG_STAT.
class_name BossSigrun
extends Boss

## Boss action phases.
enum Phase { WALK, CHARGE_WIND, CHARGE_RUN, RECOVER, LUNGE_WIND, LUNGE_RUN, STAGGER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Her form: 1 the Charge, 2 the Holmgang, 3 the Doors of the Hall.
var form: int = 1
## Seconds until her next charge.
var charge_cd: float = 0.0
## Seconds until the next duel may start (the Holmgang form).
var duel_cd: float = 0.0
## Seconds until her next lunge in the square.
var lunge_cd: float = 0.0
## True while a Holmgang runs.
var duel_on: bool = false
## Seconds left of the running duel.
var duel_left: float = 0.0
## The necromancer she challenged (null outside a duel).
var duelist: Necromancer = null
## Her HP when the duel began (the yield test: what his spells took since).
var _duel_hp0: float = 0.0
## The duellist's Grave Step count when the duel began (the clean test).
var _duel_dashes0: int = 0
## Game time until which her guard is down after yielding a duel.
var guard_down_until: float = 0.0
## The Holmgang's square (child of the EnemyDirector, created at setup).
var holmgang: Holmgang = null
## Her valkyrie wing (generation-checked against `_wing_gen`).
var _wing: Array[Enemy] = []
## Pool generation of each entry of `_wing`.
var _wing_gen: PackedInt32Array = PackedInt32Array()
## Where the current charge / lunge starts (world px).
var _l_from: Vector2 = Vector2.ZERO
## Unit direction of the current charge / lunge.
var _l_dir: Vector2 = Vector2.RIGHT
## Length of the current charge / lunge (px).
var _l_len: float = 0.0
## Width of the current charge / lunge lane (px).
var _l_width: float = 30.0
## Bodies the current charge / lunge already struck.
var _struck: Dictionary = {}
## Move speed of her row before the advance bonus (px/s).
var _base_speed: float = 62.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Sigrun at `pos` with HP scaled by `hp_mult`; her wing lands with her.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = SigrunData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	charge_cd = float(boss_def["charge_first"])
	duel_cd = 0.0
	lunge_cd = 0.0
	duel_on = false
	duelist = null
	guard_down_until = 0.0
	_base_speed = move_speed
	game.norse_rules()  # The act's rules exist wherever she fights (--boss=sigrun elsewhere).
	if holmgang == null:
		holmgang = Holmgang.new(game)
		game.enemies.add_child(holmgang)
	_wing.clear()
	_wing_gen.clear()
	var n := int(boss_def["wing_count"])
	for i in n:
		var at := position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * float(boss_def["wing_spread"])
		var w := game.enemies.spawn_at(SigrunData.WING_KIND, at, false)
		if w != null:
			_wing.append(w)
			_wing_gen.append(w.generation)
			game.stat_add("sigrun_wing", 1.0)
	game.norse_rules().play_sound("valkyrie_dive", position)
	game.enemies.show_banner(String(boss_def["charge_banner"]))


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return SigrunData.SPECIALS


## True while she walks (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## THE HOLMGANG's rule (the one read): in the square only the necromancer's
## SPELLS land on her (HundredShadowsData.is_spell_source(); every other hit
## deals 0); after she yields a duel her guard is down (+won_taken).
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if duel_on and not HundredShadowsData.is_spell_source(source):
		game.stat_add("sigrun_holmgang_warded", 1.0)
		return 0.0
	if game.elapsed < guard_down_until:
		m *= 1.0 + float(boss_def["won_taken"])
	return m


## Her fall: a running duel ends with her.
func deactivate() -> void:
	if duel_on:
		_end_duel(0)
	super.deactivate()


## Her target (5 Hz): the duellist in the square; else the shared choice.
func think() -> void:
	if duel_on and duelist != null:
		_set_target(duelist)
		targeting_player = true
		targeting_summon = false
		return
	super.think()


## Boss physics: her forms and phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	charge_cd -= delta
	duel_cd -= delta
	lunge_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_holmgang_form()
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		_doors()
	if duel_on:
		_step_duel(delta)
		holmgang.enforce(self, duelist)
		return
	if form == 2 and duel_cd <= 0.0 and phase == Phase.WALK:
		_start_duel()
		if duel_on:
			holmgang.enforce(self, duelist)
			return
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.CHARGE_WIND:
			_hold(delta)
			if phase_time >= float(boss_def["charge_windup"]):
				_set_phase(Phase.CHARGE_RUN)
		Phase.CHARGE_RUN:
			_tick_timers(delta)
			_run_lane(float(boss_def["charge_time"]), SigrunData.CHARGE_SOURCE)
			if phase_time >= float(boss_def["charge_time"]):
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)
		Phase.STAGGER:
			_hold(delta)
			if phase_time >= float(boss_def["won_stagger"]):
				_set_phase(Phase.WALK)
		_:
			_set_phase(Phase.WALK)


## Walking: the shared walk and spear at her target; the charge when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var spd := _base_speed
	if pl != null and position.distance_to(pl.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if charge_cd <= 0.0:
		_start_charge(pl)


## Standing still during a windup or recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Her charge and her lunge move her along the marked lane in `time` s,
## striking what it crosses once (WingValkyrieKit.lane(), the one charge hit).
func _run_lane(time: float, source: String) -> void:
	var k := clampf(phase_time / maxf(0.01, time), 0.0, 1.0)  # 0 -> 1 along the lane.
	position = _l_from + _l_dir * _l_len * k
	velocity = Vector2.ZERO
	var s := game.enemies.damage_mult * hit_mult()
	var charge := source == SigrunData.CHARGE_SOURCE
	var dp := float(boss_def["charge_damage_player"] if charge else boss_def["lunge_damage"]) * s
	var ds := float(boss_def["charge_damage_summon"] if charge else 0.0) * s * undead_damage_mult
	var hits := WingValkyrieKit.lane(game, _l_from, _l_dir, _l_len * k, _l_width, dp, ds, source, self,
			float(boss_def["charge_push"]) if charge else 0.0, _struck, _buf)
	game.stat_add("sigrun_charge_hits" if charge else "sigrun_lunge_hits", float(hits))
	queue_redraw()


# =====================================================================================
# The Charge
# =====================================================================================

## THE CHARGE: her lane through the necromancer `pl` and one lane for each
## living valkyrie of her wing, offset to either side (only from charge_reach
## px; else she walks a moment longer).
func _start_charge(pl: Necromancer) -> void:
	if pl == null or pl.dead or game.ultimates.player_untargetable():
		charge_cd = 1.0
		return
	var dist := position.distance_to(pl.position)
	if dist > float(boss_def["charge_reach"]):
		charge_cd = 0.5
		return
	charge_cd = float(boss_def["charge_every_p3"] if form == 3 else boss_def["charge_every"])
	var to := pl.position - position
	_l_from = position
	_l_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_l_len = dist + float(boss_def["charge_overshoot"])
	_l_width = float(boss_def["charge_width"])
	_struck.clear()
	game.effects.telegraph_line(_l_from, _l_from + _l_dir * _l_len, _l_width, float(boss_def["charge_windup"]) + float(boss_def["charge_time"]), self)
	var s := game.enemies.damage_mult * hit_mult()  # Her scaling: the wing's lanes strike as hers.
	var cfg := {"windup": float(boss_def["charge_windup"]), "time": float(boss_def["charge_time"]), "width": _l_width,
		"damage_player": float(boss_def["charge_damage_player"]) * s, "damage_summon": float(boss_def["charge_damage_summon"]) * s,
		"push": float(boss_def["charge_push"])}
	var side := _l_dir.orthogonal()
	var k := 0
	for i in _wing.size():
		var w := _wing[i]
		if not w.active or w.generation != _wing_gen[i] or not (w.kit is WingValkyrieKit):
			continue
		var off := float(boss_def["wing_offset"]) * float((k >> 1) + 1) * (1.0 if k % 2 == 0 else -1.0)
		(w.kit as WingValkyrieKit).charge(w, pl.position + side * off, float(boss_def["charge_overshoot"]), cfg)
		k += 1
	game.stat_add("boss_atk_charge", 1.0)
	game.norse_rules().play_sound("valkyrie_dive", position, 0.5)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	_set_phase(Phase.CHARGE_WIND)


# =====================================================================================
# The Holmgang
# =====================================================================================

## Her second form: the duels begin at once.
func _holmgang_form() -> void:
	form = 2
	duel_cd = 0.0
	game.stat_add("sigrun_phase2_at", game.elapsed)
	if phase != Phase.CHARGE_RUN:
		_set_phase(Phase.WALK)


## THE HOLMGANG: the square closes around the nearest necromancer, and she
## lands in it duel_offset px from him.
func _start_duel() -> void:
	var pl := game.nearest_player(position)
	if pl == null or pl.dead or game.ultimates.player_untargetable():
		duel_cd = 1.0
		return
	duel_on = true
	duelist = pl
	duel_left = float(boss_def["holmgang_time"])
	var dir := position - pl.position
	dir = dir.normalized() if dir.length() > 1.0 else Vector2.RIGHT
	game.effects.ring(position, radius * 2.0, Palette.NORSE_VALKYRIE_GOLD, 0.4)
	position = game.arena.free_point(pl.position + dir * float(boss_def["duel_offset"]), radius * 0.5)
	holmgang.open(pl.position, float(boss_def["holmgang_half"]), float(boss_def["holmgang_close"]))
	_duel_hp0 = hp
	_duel_dashes0 = _dashes_of(pl)
	lunge_cd = float(boss_def["lunge_every"]) * 0.5
	_set_target(pl)
	_set_phase(Phase.WALK)
	game.stat_add("sigrun_duels", 1.0)
	game.stat_add("boss_atk_holmgang", 1.0)
	game.enemies.show_banner(String(boss_def["holmgang_banner"]))
	game.norse_rules().play_sound("horn", position)


## Grave Steps taken by necromancer `pl` so far (his own Grave Step).
func _dashes_of(pl: Necromancer) -> int:
	if pl.dash != null:
		return pl.dash.dashes
	return game.grave_step.dashes if game.grave_step != null else 0


## A tick of the duel: her spear (the shared thrust, and the lunge), the yield
## and the time.
func _step_duel(delta: float) -> void:
	duel_left -= delta
	if duelist == null or duelist.dead:
		_end_duel(0)
		return
	if _duel_hp0 - hp >= max_hp * float(boss_def["yield_share"]):
		_end_duel(1)
		return
	if duel_left <= 0.0:
		_end_duel(-1)
		return
	match phase:
		Phase.LUNGE_WIND:
			_hold(delta)
			if phase_time >= float(boss_def["lunge_windup"]):
				_set_phase(Phase.LUNGE_RUN)
		Phase.LUNGE_RUN:
			_tick_timers(delta)
			_run_lane(float(boss_def["lunge_time"]), SigrunData.LUNGE_SOURCE)
			if phase_time >= float(boss_def["lunge_time"]):
				_set_phase(Phase.WALK)
		_:
			if phase != Phase.WALK:
				_set_phase(Phase.WALK)
			move_speed = _base_speed
			_set_target(duelist)
			super.physics_step(delta)
			var dist := position.distance_to(duelist.position)
			if lunge_cd <= 0.0 and dist > radius + 20.0 and dist < float(boss_def["lunge_length"]):
				_start_lunge()


## Her spear lunge in the square: a lane toward the duellist.
func _start_lunge() -> void:
	lunge_cd = float(boss_def["lunge_every"])
	var to := duelist.position - position
	_l_from = position
	_l_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_l_len = float(boss_def["lunge_length"])
	_l_width = float(boss_def["lunge_width"])
	_struck.clear()
	game.effects.telegraph_line(_l_from, _l_from + _l_dir * _l_len, _l_width, float(boss_def["lunge_windup"]) + float(boss_def["lunge_time"]), self)
	game.stat_add("boss_atk_lunge", 1.0)
	motion_lunge(_l_dir, MotionData.POWER_CAST)
	_set_phase(Phase.LUNGE_WIND)


## The duel ends: `result` 1 he won (she yields: staggered, her guard down; a
## win without a Grave Step is the achievement's), -1 she won (she heals), 0
## broken off (her fall, the Doors, his fall).
func _end_duel(result: int) -> void:
	duel_on = false
	holmgang.close()
	duel_cd = float(boss_def["duel_gap"])
	game.stat_add("sigrun_duel_spell_dmg", maxf(0.0, _duel_hp0 - hp))
	if result > 0:
		game.stat_add("sigrun_duels_won", 1.0)
		game.stat_add("boss_atk_yield", 1.0)
		if duelist != null and _dashes_of(duelist) == _duel_dashes0:
			game.stat_add("sigrun_duels_clean", 1.0)
			game.stats[SigrunData.HOLMGANG_STAT] = 1.0
		guard_down_until = game.elapsed + float(boss_def["won_time"])
		game.enemies.show_banner(String(boss_def["won_banner"]))
		game.effects.ring(position, radius * 2.6, Palette.NORSE_VALKYRIE_GOLD, 0.5)
		if active and hp > 0.0:
			_set_phase(Phase.STAGGER)
	elif result < 0:
		game.stat_add("sigrun_duels_lost", 1.0)
		game.combat.heal_enemy(self, max_hp * float(boss_def["lost_heal"]))
		game.enemies.show_banner(String(boss_def["lost_banner"]))
		_set_phase(Phase.WALK)
	duelist = null


# =====================================================================================
# The Doors of the Hall
# =====================================================================================

## THE DOORS OF THE HALL (owner decision Nov 7, 2026: "every Einherjar of the
## hall marches out at her side"): a running duel is broken off; doors_count
## Einherjar march in two files out of the spawn ring beyond her, and the Feast
## wakes around the necromancer (Valgard).
func _doors() -> void:
	form = 3
	if duel_on:
		_end_duel(0)
	game.stat_add("sigrun_phase3_at", game.elapsed)
	game.stat_add("boss_atk_doors", 1.0)
	game.enemies.show_banner(String(boss_def["doors_banner"]))
	var pl := game.nearest_player(position)
	var from := pl.position if pl != null else game.player.position
	var out := position - from
	var dir := out.normalized() if out.length() > 1.0 else Vector2.RIGHT
	var door := game.enemies.ring_point(dir.angle())
	var side := dir.orthogonal()
	var n := int(boss_def["doors_count"])
	var marched := 0
	for i in n:
		var file := 1.0 if i % 2 == 0 else -1.0
		var row := float(i >> 1)
		var at := door + side * file * float(boss_def["doors_files"]) + dir * row * float(boss_def["doors_spacing"])
		if game.enemies.spawn_at(ValgardEnemyData.EINHERJAR, at, false) != null:
			marched += 1
	game.stat_add("sigrun_doors_einherjar", float(marched))
	if game.enemies.valgard != null:
		game.enemies.valgard.wake_feast(from, int(game.enemies.valgard.config["doors_wake"]), "doors")
	game.norse_rules().play_sound("einherjar_march", position)
	game.norse_rules().play_sound("horn", position)
	charge_cd = minf(charge_cd, 2.0)
	if phase != Phase.CHARGE_RUN:
		_set_phase(Phase.WALK)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: off her charge or lunge lane while it
## shows and while she runs it (the wing's lanes are their kits' hints).
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.CHARGE_WIND or phase == Phase.CHARGE_RUN or phase == Phase.LUNGE_WIND or phase == Phase.LUNGE_RUN:
		return WingValkyrieKit.lane_push(_l_from, _l_dir, _l_len, _l_width, p)
	return Vector2.ZERO


## Body layer on `ci`: her sprite (walk / idle strips through the body layer),
## lifted a little while she charges; a gold light while her guard is down;
## a glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var lift := Vector2.ZERO
	if phase == Phase.CHARGE_RUN:
		lift = Vector2(0.0, -6.0)
	if game != null and game.elapsed < guard_down_until:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.4), radius * 1.4, Color(Palette.NORSE_VALKYRIE_GOLD, 0.14))
	if not SpriteBank.draw(ci, SigrunData.SPRITE, lift, flash > 0.0):
		SpriteBank.draw_disc(ci, lift, radius, Palette.NORSE_IRON)
		SpriteBank.draw_disc(ci, lift + Vector2(0.0, -radius * 0.6), radius * 0.5, Palette.NORSE_VALKYRIE_GOLD)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("sigrun_phase2_at", -1.0))
	var p3 := float(st.get("sigrun_phase3_at", -1.0))
	return "wing %d | charges %d (hits %d, wing lanes %d) | the Holmgang %s: duels %d (won %d, clean %d, lost %d), spell dmg in the square %d, warded hits %d, lunges %d (hits %d), held %d, pushed out: summons %d, enemies %d | the Doors %s: einherjar %d | dmg to you %d (charge %d, lunge %d), to summons %d" % [
		int(st.get("sigrun_wing", 0.0)), int(st.get("boss_atk_charge", 0.0)), int(st.get("sigrun_charge_hits", 0.0)), int(st.get("wing_charges", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached",
		int(st.get("sigrun_duels", 0.0)), int(st.get("sigrun_duels_won", 0.0)), int(st.get("sigrun_duels_clean", 0.0)),
		int(st.get("sigrun_duels_lost", 0.0)), int(st.get("sigrun_duel_spell_dmg", 0.0)), int(st.get("sigrun_holmgang_warded", 0.0)),
		int(st.get("boss_atk_lunge", 0.0)), int(st.get("sigrun_lunge_hits", 0.0)), int(st.get("holmgang_held_player", 0.0)),
		int(st.get("holmgang_pushed_summons", 0.0)), int(st.get("holmgang_pushed_enemies", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("sigrun_doors_einherjar", 0.0)),
		int(st.get("player_dmg_from_boss", 0.0) + st.get("player_dmg_from_" + SigrunData.CHARGE_SOURCE, 0.0) + st.get("player_dmg_from_" + SigrunData.LUNGE_SOURCE, 0.0)),
		int(st.get("player_dmg_from_" + SigrunData.CHARGE_SOURCE, 0.0)), int(st.get("player_dmg_from_" + SigrunData.LUNGE_SOURCE, 0.0)),
		int(st.get("summon_dmg_from_boss", 0.0) + st.get("summon_dmg_from_" + SigrunData.CHARGE_SOURCE, 0.0))]
