## BossThrone — THE THRONE, the boss of the Wheel of Thrones (temporary Act
## XIII, the Celestial Host; GDD §15.0 "The Throne (Act XIII phase 2)";
## owner-approved proposal: the Rolling, the Gaze, the Core). Loaded by name for
## the boss id "throne" (EnemyDirector.HOST_BOSS_DIR + "boss_throne.gd"); it
## arrives at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat it like any enemy (no halo: Grace is a HostKit's).
## Numbers in ThroneData.BOSS. One cycle, again and again:
##   WALK (it turns toward the nearest necromancer: the shared AI, enemies
##   always advance) -> THE ROLLING (a marked line, then it rolls straight,
##   rebounding once it is past roll_bound px from the necromancer and still
##   rolling away; its rim strikes every summon and necromancer under it each
##   roll_tick s) -> THE GAZE (its eyes open, then shafts of Hallowed Light
##   start on its rim and sweep toward the necromancer: HallowedLight.add_shaft(),
##   the Light's one path, the Light's max_live raised by the beams while they
##   run) -> THE CORE (the wheels open for core_time s: the burning eye takes
##   full damage; at every other time the rims take rim_mult of each hit,
##   damage_taken_mult()) -> WALK.
## Below phase2_hp, EVERY EYE OPENS: faster rolls, more beams.
## THE WHEEL BREAKS: it counts the health it loses with the Core open and
## closed (each tick, and the killing blow when it falls);
## WheelOfThronesDirector reads wheel_breaks() when it falls.
## The rules exist wherever it fights (Game.host_rules()); off a Host stage the
## Gaze's shafts still burn. When it falls, a short ending text (no epilogue
## part). Slaying it unlocks Wheel of Eyes with All-Seeing (UnlockData, boss
## "throne").
## Determinism: no RNG (its lines follow the necromancer and its rebounds are
## mirrors). Stats: boss_atk_<special>, throne_roll_hits, throne_gaze_beams,
## throne_gaze_refused, throne_core_dmg, throne_rim_dmg, throne_killed_in_core,
## throne_phase2_at, throne_kill_time.
class_name BossThrone
extends Boss

## Its actions.
enum Act { WALK, ROLL_WINDUP, ROLL, GAZE_CAST, GAZE, CORE }

## px the autotest bot keeps beside its rolling line (autotest hint only).
const DANGER_MARGIN: float = 28.0  # TUNING (not in GDD) autotest hint only
## px between two drawn marks of its line (visual only).
const MARK_STEP: float = 9.0  # TUNING (not in GDD) visual only
## px its marked line runs ahead (visual only).
const LINE_LENGTH: float = 360.0  # TUNING (not in GDD) visual only
## Eyes drawn round each rim of the code shape (visual only).
const RIM_EYES: int = 10  # TUNING (not in GDD) visual only

## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## True below phase2_hp (every eye opens).
var all_eyes: bool = false
## The roll's direction (unit vector).
var _dir: Vector2 = Vector2.RIGHT
## Seconds until the rim strikes again while rolling.
var _strike_cd: float = 0.0
## The wheels' turn (rad; visual only, it spins while rolling).
var _spin: float = 0.0
## Health it had at the end of the last tick (the window count).
var _last_hp: float = 0.0
## Health lost while the Core was open.
var core_dmg: float = 0.0
## Health lost while the wheels were closed.
var rim_dmg: float = 0.0
## True when the killing blow fell on the open Core.
var killed_in_core: bool = false
## Game time (s) the Gaze's extra Light slots end (-1 = none raised).
var _gaze_end: float = -1.0
## Light slots added for the Gaze now.
var _gaze_slots: int = 0
## Its walking speed (px/s).
var _base_speed: float = 36.0
## Game time (s) it arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the Throne at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ThroneData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	act = Act.WALK
	act_time = 0.0
	all_eyes = false
	_last_hp = hp
	core_dmg = 0.0
	rim_dmg = 0.0
	killed_in_core = false
	_gaze_end = -1.0
	_gaze_slots = 0
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.host_rules()  # Its Gaze goes through the Light (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["phase1_banner"]))


## Its abilities in report order (Boss hook).
func special_ids() -> Array:
	return ThroneData.SPECIALS


## True while it walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of its art (engine-motion pivot).
func motion_sprite_key() -> String:
	return ThroneData.SPRITE


## Any removal ends the Gaze's extra Light slots (the pool reuses the node).
func deactivate() -> void:
	_end_gaze()
	super.deactivate()


## THE CORE: the closed wheels take rim_mult of every hit, the open Core all.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	return m if act == Act.CORE else m * float(boss_def["rim_mult"])


## Share (0..1) of its lost health that fell while the Core was open.
func core_share() -> float:
	var total := core_dmg + rim_dmg
	return core_dmg / total if total > 0.0 else 0.0


## THE WHEEL BREAKS: the killing blow on the open Core and at least
## ThroneData.WHEEL_BREAKS_SHARE of its health lost with the Core open. Safe
## to call from any boss_defeated listener (the director's runs before its
## own _on_defeated): it counts the killing blow first.
func wheel_breaks() -> bool:
	_count_window()
	return act == Act.CORE and core_share() >= ThroneData.WHEEL_BREAKS_SHARE


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the window count, the phase, the Gaze's slots, its cycle.
func physics_step(delta: float) -> void:
	_count_window()
	act_time += delta
	knockback = Vector2.ZERO
	if not all_eyes and hp <= max_hp * float(boss_def["phase2_hp"]):
		all_eyes = true
		game.stats["throne_phase2_at"] = game.elapsed
		game.enemies.show_banner(String(boss_def["phase2_banner"]))
		game.shake(4.0)
	if _gaze_slots > 0 and game.elapsed >= _gaze_end:
		_end_gaze()
	match act:
		Act.WALK:
			var pl := game.nearest_player(position)
			move_speed = _base_speed
			super.physics_step(delta)
			if act_time >= float(boss_def["walk_time"]):
				_dir = (pl.position - position).normalized() if pl.position.distance_to(position) > 1.0 else Vector2.RIGHT
				game.stat_add("boss_atk_roll", 1.0)
				_set_act(Act.ROLL_WINDUP)
		Act.ROLL_WINDUP:
			_hold(delta)
			var pl2 := game.nearest_player(position)
			if pl2.position.distance_to(position) > 1.0:
				_dir = (pl2.position - position).normalized()  # It keeps its eyes on him until it rolls.
			if act_time >= float(boss_def["roll_windup"]):
				_strike_cd = 0.0
				game.host_rules().play_sound("throne_roll", position, 0.5)
				_set_act(Act.ROLL)
		Act.ROLL:
			_tick_timers(delta)
			_step_roll(delta)
			if act_time >= float(boss_def["roll_time"]):
				game.stat_add("boss_atk_gaze", 1.0)
				game.enemies.show_banner(String(boss_def["gaze_banner"]))
				_set_act(Act.GAZE_CAST)
		Act.GAZE_CAST:
			_hold(delta)
			if act_time >= float(boss_def["gaze_cast"]):
				_open_gaze()
				_set_act(Act.GAZE)
		Act.GAZE:
			_hold(delta)
			if act_time >= float(boss_def["gaze_hold"]):
				game.stat_add("boss_atk_core", 1.0)
				game.enemies.show_banner(String(boss_def["core_banner"]))
				game.host_rules().play_sound("throne_core", position, 0.5)
				_set_act(Act.CORE)
		Act.CORE:
			_hold(delta)
			if act_time >= float(boss_def["core_time"]):
				_set_act(Act.WALK)


## Adds the health lost since the last tick to the Core's or the rims' count.
func _count_window() -> void:
	var lost := _last_hp - maxf(hp, 0.0)
	if lost > 0.0:
		if act == Act.CORE:
			core_dmg += lost
		else:
			rim_dmg += lost
	_last_hp = maxf(hp, 0.0)
	game.stats["throne_core_dmg"] = core_dmg  # (Live, so a run that never breaks it still reports the windows.)
	game.stats["throne_rim_dmg"] = rim_dmg


## THE ROLLING: straight along its line, rebounding past roll_bound; the rim
## strikes what it rolls over.
func _step_roll(delta: float) -> void:
	var speed := float(boss_def["roll_speed_p2" if all_eyes else "roll_speed"])
	var pl := game.nearest_player(position)
	var off := position - pl.position
	if off.length() > float(boss_def["roll_bound"]) and _dir.dot(off) > 0.0:
		var n := off.normalized()
		_dir = (_dir - 2.0 * _dir.dot(n) * n).normalized()  # REBOUND: mirrored about the line back to him.
		if _dir.dot(-n) < 0.5:
			_dir = (_dir - n).normalized()  # A glancing line is bent back toward him, so it crosses the ring again.
		game.stat_add("boss_atk_rebound", 1.0)
	position += _dir * speed * delta
	velocity = _dir * speed
	_spin = wrapf(_spin + speed * delta / maxf(1.0, radius), 0.0, TAU)
	_strike_cd -= delta
	if _strike_cd <= 0.0:
		_strike_cd = float(boss_def["roll_tick"])
		_strike()
	queue_redraw()


## The rim strikes every summon and necromancer under it.
func _strike() -> void:
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x its buffs.
	var reach := radius + float(boss_def["roll_reach"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) <= reach + u.radius:
			game.stat_add("throne_roll_hits", 1.0)
			game.combat.damage_unit(u, float(boss_def["roll_damage_summon"]) * ts * undead_damage_mult, ThroneData.ROLL_SOURCE, self)
	for pl in game.all_players:  # (Co-op: either necromancer can be in its path.)
		if not pl.dead and pl.position.distance_to(position) <= reach + pl.radius:
			game.stat_add("throne_roll_hits", 1.0)
			game.combat.damage_player(float(boss_def["roll_damage"]) * ts, ThroneData.ROLL_SOURCE, pl, self)


## THE GAZE: shafts of Hallowed Light from its rim toward the necromancer, fanned.
func _open_gaze() -> void:
	var light := game.host_rules().light
	var pl := game.nearest_player(position)
	var to := pl.position - position
	var aim := to.angle() if to.length() > 1.0 else 0.0
	var beams := int(boss_def["gaze_beams_p2" if all_eyes else "gaze_beams"])
	var spread := deg_to_rad(float(boss_def["gaze_spread"]))
	_end_gaze()
	_gaze_slots = beams
	light.max_live += beams  # Its beams on top of the act's own shafts.
	var travel := to.length() + float(boss_def["gaze_past"])
	_gaze_end = game.elapsed + travel / maxf(1.0, float(light.cfg["speed"])) + 0.5
	for i in beams:
		var a := aim + spread * (float(i) - float(beams - 1) * 0.5)
		var n := Vector2.from_angle(a)
		if light.add_shaft(position + n * radius, n, float(boss_def["gaze_width"]), travel):
			game.stat_add("throne_gaze_beams", 1.0)
		else:
			game.stat_add("throne_gaze_refused", 1.0)
	game.shake(3.0)


## The Gaze's extra Light slots end.
func _end_gaze() -> void:
	if _gaze_slots > 0 and game != null and game.host != null:
		game.host.light.max_live = maxi(1, game.host.light.max_live - _gaze_slots)
	_gaze_slots = 0
	_gaze_end = -1.0


## Standing still (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Its defeat (EnemyDirector.boss_defeated, after the reward burst): the
## killing blow counted, the short ending text (no epilogue).
func _on_defeated() -> void:
	killed_in_core = act == Act.CORE
	_count_window()
	game.stats["throne_killed_in_core"] = 1.0 if killed_in_core else 0.0
	_end_gaze()
	var pos := position
	game.effects.ring(pos, 240.0, Palette.HOST_STARLIGHT, 1.0)
	game.effects.ring(pos, 140.0, Palette.HOST_CERULEAN, 0.8)
	Juice.fx.burst(pos, Palette.HOST_STARLIGHT, Palette.HOST_CERULEAN, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + ThroneData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = ThroneData.LATE_ANNOUNCE if game.countdown_finished() else ThroneData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.HOST_STARLIGHT)
	game.stats["throne_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of its line while it marks it
## or rolls (the Gaze's beams are shafts: the Light's own hint).
func danger_push(p: Vector2) -> Vector2:
	if act != Act.ROLL_WINDUP and act != Act.ROLL:
		return Vector2.ZERO
	var rel := p - position
	if rel.dot(_dir) < -radius or absf(rel.cross(_dir)) > radius + DANGER_MARGIN:
		return Vector2.ZERO
	var side := _dir.orthogonal()
	return (side if rel.dot(side) >= 0.0 else -side) * 2.0


## Body layer on `ci`: its sprite (pose 1 while the Core is open), the Core's
## eye over it when open; a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if act == Act.CORE else 0
	if not SpriteBank.draw_pose(ci, ThroneData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		_glyph(ci)
	if act == Act.CORE and not SpriteBank.draw(ci, ThroneData.CORE_SPRITE, Vector2.ZERO, flash > 0.0):
		SpriteBank.draw_disc(ci, Vector2.ZERO, radius * 0.42, Glyphs._c(Palette.HOST_CERULEAN, flash > 0.0))
		SpriteBank.draw_disc(ci, Vector2.ZERO, radius * 0.26, Glyphs._c(Palette.HOST_STARLIGHT, flash > 0.0))  # The burning eye.


## Its code shape without the art: two silver rims of eyes, one turning each
## way, round a dark hub (disc textures only).
func _glyph(ci: CanvasItem) -> void:
	var r := radius
	var fl := flash > 0.0
	var open := 1.25 if act == Act.CORE else 1.0  # The wheels part when the Core opens.
	SpriteBank.draw_disc(ci, Vector2.ZERO, r * 1.02 * open, Glyphs._c(HostGlyphs.INK, fl))
	SpriteBank.draw_disc(ci, Vector2.ZERO, r * 0.95 * open, Glyphs._c(Color(Palette.HOST_CERULEAN, 0.55), fl))
	SpriteBank.draw_disc(ci, Vector2.ZERO, r * 0.62, Glyphs._c(HostGlyphs.INK, fl))
	for i in RIM_EYES:
		var a := _spin + TAU * float(i) / float(RIM_EYES)
		SpriteBank.draw_disc(ci, Vector2.from_angle(a) * r * 0.85 * open, 3.0, Glyphs._c(Palette.HOST_SILVER, fl))
		SpriteBank.draw_disc(ci, Vector2.from_angle(-a) * r * 0.55, 2.2, Glyphs._c(Palette.HOST_STARLIGHT, fl))  # The inner wheel turns the other way.


## Overlay layer on `ci`: its marked line before a roll. Visual only: rects.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.ROLL_WINDUP:
		var k := clampf(act_time / maxf(0.01, float(boss_def["roll_windup"])), 0.0, 1.0)
		var s := radius
		while s < LINE_LENGTH:
			ci.draw_rect(Rect2(_dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.HOST_CERULEAN, 0.35 + 0.55 * k))
			s += MARK_STEP
	elif act == Act.GAZE_CAST:
		var k2 := clampf(act_time / maxf(0.01, float(boss_def["gaze_cast"])), 0.0, 1.0)
		for i in RIM_EYES:
			var p := Vector2.from_angle(TAU * float(i) / float(RIM_EYES)) * radius * 1.1
			ci.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.HOST_STARLIGHT, 0.3 + 0.7 * k2))  # Every eye opens.
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of its fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("throne_phase2_at", -1.0))
	var kt := float(st.get("throne_kill_time", -1.0))
	var core := float(st.get("throne_core_dmg", 0.0))
	var rim := float(st.get("throne_rim_dmg", 0.0))
	return "the Rolling: rolls %d, rebounds %d (rim hits %d) | the Gaze: gazes %d, beams %d (refused %d) | the Core: opened %d, health lost core %d / rims %d (core %d%%), killing blow on the core %s | every eye opens %s | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_roll", 0.0)), int(st.get("boss_atk_rebound", 0.0)), int(st.get("throne_roll_hits", 0.0)),
		int(st.get("boss_atk_gaze", 0.0)), int(st.get("throne_gaze_beams", 0.0)), int(st.get("throne_gaze_refused", 0.0)),
		int(st.get("boss_atk_core", 0.0)), int(core), int(rim), roundi(100.0 * core / maxf(1.0, core + rim)),
		str(float(st.get("throne_killed_in_core", 0.0)) > 0.0),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached",
		("%.0f s after it arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + ThroneData.ROLL_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + ThroneData.ROLL_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
