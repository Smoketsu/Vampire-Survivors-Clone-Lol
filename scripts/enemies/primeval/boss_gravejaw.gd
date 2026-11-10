## BossGravejaw — OLD GRAVEJAW, THE TYRANT KING, the boss of the Last Day, the
## Age of Titans' finale (temporary Act XIV; GDD §15.0 "Old Gravejaw, the
## Tyrant King (Act XIV phase 2)"; owner-approved proposal: the Roar, the
## Hunt, the Last Day). Loaded by name for the boss id "gravejaw"
## (EnemyDirector.PRIMEVAL_BOSS_DIR + "boss_gravejaw.gd"); he arrives at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat him
## like any enemy. Numbers in GravejawData.BOSS (its header tells the fight):
##   * THE HUNT: the shared AI walks him at the nearest necromancer, his target
##     forced to him every tick (no summon draws him); THE BITE lunges through
##     the ring at him, swallowing the first summon it reaches and goring the
##     rest (the swallow is TyrantKit's: `_jaws`, a TyrantKit fed his row).
##   * THE ROAR: the ring round him stunned (TyrantKit.roar()), the herds near
##     him stampede away from him (Herds.launch()), and beasts answer from the
##     spawn ring on his side (EnemyDirector.spawn_at()).
##   * THE LAST DAY (from last_day_time): he rampages to the Mound on his far
##     side (HornchargerKit.gore(), the one charge hit) and stands there,
##     exposed, roaring at the sky.
##   * THE IMPACT: the Extinction leaves him on 10% HP and calls
##     on_extinction(): broken, out of reach (no damage), so his spell is only
##     for the one who slew him before the fall.
## The Titans' rules exist wherever he fights (Game.primeval_rules()). When he
## falls the short ending text (no epilogue part). Slaying him unlocks Meteor
## Call, Cosmic Dust, the Bonehorn and Petrified Horns (UnlockData, boss
## "gravejaw"). Determinism: no RNG of his own (his beasts come through the
## seeded spawn path). Stats: boss_atk_<special>, gravejaw_bite_hits,
## gravejaw_swallows, gravejaw_roar_stuns, gravejaw_called,
## gravejaw_herds_roused, gravejaw_rampage_hits, gravejaw_last_day_at,
## gravejaw_mound_at, gravejaw_broken, gravejaw_kill_time.
class_name BossGravejaw
extends Boss

## Boss action states.
enum Act { WALK, BITE_WINDUP, BITE, ROAR_WINDUP, RECOVER, RAMPAGE, MOUND, BROKEN }

## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## True once the Last Day began.
var last_day: bool = false
## The Mound (world px) he rampages to.
var mound: Vector2 = Vector2.ZERO
## His jaws: a TyrantKit fed his row (the one swallow and roar).
var _jaws: TyrantKit = null
## Seconds until the next bite may start.
var _bite_cd: float = 0.0
## Seconds until the next roar may start.
var _roar_cd: float = 0.0
## The current lunge's direction (unit).
var _dir: Vector2 = Vector2.RIGHT
## px of the current lunge / rampage run so far.
var _run: float = 0.0
## Bodies the current lunge / rampage already hit.
var _hit: Array = []
## His walking speed (px/s, before the advance stride).
var _base_speed: float = 50.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Old Gravejaw at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = GravejawData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	act = Act.WALK
	act_time = 0.0
	last_day = false
	_jaws = TyrantKit.new()
	_jaws.d = boss_def
	_bite_cd = float(boss_def["bite_first"])
	_roar_cd = float(boss_def["roar_first"])
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.primeval_rules()  # His herds and his jaws are the Titans rules' (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return GravejawData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return GravejawData.SPRITE


## THE IMPACT (the Extinction): broken under the ash, out of reach.
func on_extinction() -> void:
	_jaws.release(self)
	game.stat_add("gravejaw_broken", 1.0)
	_set_act(Act.BROKEN)


## Broken: no damage; at the Mound: exposed.
func damage_taken_mult(source: String) -> float:
	if act == Act.BROKEN:
		return 0.0
	var m := super.damage_taken_mult(source)
	if act == Act.MOUND:
		m *= float(boss_def["mound_taken"])
	return m


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the Last Day's clock, his jaws, then his action machine.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_bite_cd -= delta
	_roar_cd -= delta
	_jaws.step_prey(self, delta)
	if not last_day and act == Act.WALK and game.elapsed >= float(boss_def["last_day_time"]):
		_begin_last_day()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.BITE_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["bite_windup"]):
				_run = 0.0
				_hit.clear()
				motion_lunge(_dir, MotionData.POWER_CAST)
				game.primeval_rules().play_sound("gravejaw_bite", position, 0.3)
				_set_act(Act.BITE)
		Act.BITE:
			_tick_timers(delta)
			_step_bite(delta)
		Act.ROAR_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["roar_windup"]):
				_roar()
				_set_act(Act.MOUND if last_day else Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)
		Act.RAMPAGE:
			_tick_timers(delta)
			_step_rampage(delta)
		Act.MOUND:
			_hold(delta)
			if _roar_cd <= 0.0:
				_start_roar()
		Act.BROKEN:
			_hold(delta)


## THE HUNT: the shared AI at his stride, his target always the nearest
## necromancer; a bite or a roar when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	_set_target(pl)  # No summon draws him (a blocker still holds his body and slows him).
	super.physics_step(delta)
	if stun_timer > 0.0:
		return
	if _roar_cd <= 0.0 and dist <= float(boss_def["bite_trigger"]):
		_start_roar()
	elif _bite_cd <= 0.0 and dist <= float(boss_def["bite_trigger"]):
		_bite_cd = float(boss_def["bite_every"])
		var to := pl.position - position
		_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		game.stat_add("boss_atk_bite", 1.0)
		_set_act(Act.BITE_WINDUP)


## Standing still during a windup, a recovery or at the Mound (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Hunt: the bite
# =====================================================================================

## The lunge runs: the first summon he reaches is swallowed, the rest gored;
## the necromancer bitten.
func _step_bite(delta: float) -> void:
	var step := float(boss_def["bite_speed"]) * delta
	if HornchargerKit.rock_ahead(game, position, _dir, step, radius) or _run >= float(boss_def["bite_len"]):
		position = game.arena.free_point(position, radius)
		_set_act(Act.RECOVER)
		return
	velocity = _dir * float(boss_def["bite_speed"])
	position += _dir * step
	_update_facing()
	_run += step
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x his buffs.
	var marrow := game.primeval.thick_marrow_mult() if game.primeval != null else 1.0  # Thick Marrow.
	game.ally_grid.query(position, radius + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not TyrantKit._can_take(u) or _hit.has(u) or u.position.distance_to(position) > radius + u.radius + 2.0:
			continue
		_hit.append(u)
		if _jaws.prey == null:
			_jaws.swallow(self, u, float(boss_def["swallow_time"]))
			game.stat_add("gravejaw_swallows", 1.0)
			continue
		game.combat.damage_unit(u, float(boss_def["bite_damage_summon"]) * ts * marrow * undead_damage_mult, GravejawData.BITE_SOURCE, self)
		var side := _dir.orthogonal()
		u.position += side * float(boss_def["bite_knock"]) * (1.0 if (u.position - position).dot(side) >= 0.0 else -1.0)
		game.stat_add("gravejaw_bite_hits", 1.0)
	for pl in game.all_players:
		if pl.dead or _hit.has(pl) or pl.position.distance_to(position) > radius + pl.radius + 2.0:
			continue
		_hit.append(pl)
		game.combat.damage_player(float(boss_def["bite_damage"]) * ts, GravejawData.BITE_SOURCE, pl, self)


# =====================================================================================
# The Roar
# =====================================================================================

## The roar's windup begins.
func _start_roar() -> void:
	_roar_cd = float(boss_def["roar_every"])
	game.stat_add("boss_atk_roar", 1.0)
	game.primeval_rules().play_sound("gravejaw_roar", position, 0.5)
	_set_act(Act.ROAR_WINDUP)


## THE ROAR (see the header).
func _roar() -> void:
	game.stat_add("gravejaw_roar_stuns", float(_jaws.roar(self, float(boss_def["roar_radius"]), float(boss_def["roar_stun"]))))
	var hs := game.primeval_rules().herds
	var reach := float(boss_def["call_reach"])
	for h in hs.herds.duplicate():
		if h.state != Herds.GRAZE or game.elapsed < h.ready_at:
			continue
		var c := hs.centre(h)
		if c.distance_to(position) <= reach:
			hs.launch(h, c * 2.0 - position)  # Away from his roar (the one stampede start).
			game.stat_add("gravejaw_herds_roused", 1.0)
	if not last_day:
		var pl := game.nearest_player(position)
		var side := position - pl.position
		var a := side.angle() if side.length() > 1.0 else 0.0
		var k := 0
		for grp: Dictionary in boss_def["call"]:
			for j in int(grp["count"]):
				var at := game.enemies.ring_point(a + 0.12 * float(k - 6))
				if game.enemies.spawn_at(String(grp["kind"]), at, false) != null:
					game.stat_add("gravejaw_called", 1.0)
				k += 1
		game.enemies.show_banner(String(boss_def["roar_banner"]))
	game.shake(7.0)


# =====================================================================================
# The Last Day
# =====================================================================================

## THE LAST DAY begins: the Mound lies mound_dist px on his far side.
func _begin_last_day() -> void:
	last_day = true
	_jaws.release(self)
	var pl := game.nearest_player(position)
	var away := position - pl.position
	_dir = away.normalized() if away.length() > 1.0 else Vector2.RIGHT
	mound = game.arena.free_point(position + _dir * float(boss_def["mound_dist"]), radius)
	_run = 0.0
	_hit.clear()
	game.stat_add("boss_atk_last_day", 1.0)
	game.stats["gravejaw_last_day_at"] = game.elapsed
	game.enemies.show_banner(String(boss_def["last_day_banner"]))
	_set_act(Act.RAMPAGE)


## The rampage to the Mound: every body in his path gored once.
func _step_rampage(delta: float) -> void:
	var to := mound - position
	var step := float(boss_def["rampage_speed"]) * delta
	if to.length() <= step + 2.0 or act_time > 6.0 or HornchargerKit.rock_ahead(game, position, _dir, step, radius):
		position = game.arena.free_point(position, radius)
		game.stats["gravejaw_mound_at"] = game.elapsed
		_roar_cd = 0.0
		_set_act(Act.MOUND)
		return
	_dir = to.normalized()
	velocity = _dir * float(boss_def["rampage_speed"])
	position += _dir * step
	_update_facing()
	var ts := game.enemies.damage_mult * hit_mult()
	var n := HornchargerKit.gore(self, _hit, float(boss_def["rampage_damage_summon"]) * ts, float(boss_def["rampage_damage"]) * ts,
			float(boss_def["rampage_stun"]), float(boss_def["rampage_knock"]), _dir, GravejawData.RAMPAGE_SOURCE, _buf)
	if n > 0:
		game.stat_add("gravejaw_rampage_hits", float(n))


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue).
func _on_defeated() -> void:
	_jaws.release(self)
	var pos := position
	game.effects.ring(pos, 240.0, Palette.PRIMEVAL_LAVA, 1.0)
	game.effects.ring(pos, 140.0, Palette.PRIMEVAL_BONE, 0.8)
	Juice.fx.burst(pos, Palette.PRIMEVAL_LAVA, Palette.PRIMEVAL_BONE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + GravejawData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = GravejawData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.PRIMEVAL_LAVA)
	game.stats["gravejaw_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the bite's line while he
## rears, out of the roar's circle while he roars, off the rampage's path.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if act == Act.BITE_WINDUP or act == Act.BITE:
		push += HornchargerKit.line_push(position, _dir, float(boss_def["bite_len"]), radius, p) * 2.0
	elif act == Act.RAMPAGE:
		push += HornchargerKit.line_push(position, _dir, position.distance_to(mound), radius, p) * 2.0
	return push


## Body layer on `ci`: his still / walk frame (pose 1, the roar, while he
## roars); a code shape without the art (darker once broken).
func _draw_body(ci: CanvasItem) -> void:
	var roaring := act == Act.ROAR_WINDUP or act == Act.MOUND
	if not SpriteBank.draw_pose(ci, GravejawData.SPRITE, 1 if roaring else 0, Vector2.ZERO, flash > 0.0):
		var hide := Palette.PRIMEVAL_TAR.darkened(0.4) if act == Act.BROKEN else Palette.PRIMEVAL_TAR
		PrimevalGlyphs._beast(ci, Vector2.ZERO, radius, flash > 0.0, hide, Palette.PRIMEVAL_LAVA.darkened(0.5), 1.15, 1.0)
		SpriteBank.draw_disc(ci, Vector2(radius * 0.9, -radius * 0.35), radius * (0.28 if roaring else 0.16), Glyphs._c(Palette.PRIMEVAL_LAVA, flash > 0.0))  # The lava glow in his throat.


## Overlay layer on `ci`: the bite's line while he rears, the roar's circle
## while he roars, the Mound's mark. Visual only: rects and discs in world axes.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.BITE_WINDUP:
		var k := clampf(act_time / maxf(0.01, float(boss_def["bite_windup"])), 0.0, 1.0)
		HornchargerKit.draw_line_marks(ci, Vector2.ZERO, _dir, radius, float(boss_def["bite_len"]), k)
	elif act == Act.ROAR_WINDUP:
		var k2 := clampf(act_time / maxf(0.01, float(boss_def["roar_windup"])), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2.ZERO, float(boss_def["roar_radius"]), Color(Palette.PRIMEVAL_LAVA, 0.06 + 0.14 * k2))
	elif act == Act.RAMPAGE:
		HornchargerKit.draw_line_marks(ci, Vector2.ZERO, _dir, radius, position.distance_to(mound), 0.6)
	if _jaws != null and _jaws.prey != null:
		SpriteBank.draw_disc(ci, Vector2.ZERO, radius * 0.5, Color(Palette.PRIMEVAL_LAVA, 0.45))  # A summon in his belly.
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var ld := float(st.get("gravejaw_last_day_at", -1.0))
	var kt := float(st.get("gravejaw_kill_time", -1.0))
	return "the Hunt: bites %d (swallowed %d, gored %d; cut out %d) | the Roar: %d (stunned %d, herds roused %d, beasts called %d) | the Last Day %s (rampage hits %d, at the Mound %s) | broken by the impact %s | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_bite", 0.0)), int(st.get("gravejaw_swallows", 0.0)), int(st.get("gravejaw_bite_hits", 0.0)), int(st.get("tyrant_cut_out", 0.0)),
		int(st.get("boss_atk_roar", 0.0)), int(st.get("gravejaw_roar_stuns", 0.0)), int(st.get("gravejaw_herds_roused", 0.0)), int(st.get("gravejaw_called", 0.0)),
		EmpireReport._clock(ld) if ld >= 0.0 else "not reached", int(st.get("gravejaw_rampage_hits", 0.0)),
		EmpireReport._clock(float(st["gravejaw_mound_at"])) if st.has("gravejaw_mound_at") else "-",
		"yes" if float(st.get("gravejaw_broken", 0.0)) > 0.0 else "no",
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + GravejawData.BITE_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + GravejawData.RAMPAGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + GravejawData.BITE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + GravejawData.RAMPAGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
