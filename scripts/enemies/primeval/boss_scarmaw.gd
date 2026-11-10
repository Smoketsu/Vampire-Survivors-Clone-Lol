## BossScarmaw — SCARMAW, THE GREAT RAPTOR, the boss of the Fern Basin
## (temporary Act XIV, the Age of Titans; GDD §15.0 "Scarmaw, the Great Raptor
## (Act XIV phase 2)"; owner-approved proposal: the Hunt, the Ambush, Blood
## Up). Loaded by name for the boss id "scarmaw"
## (EnemyDirector.PRIMEVAL_BOSS_DIR + "boss_scarmaw.gd"); she arrives at 17:00
## (3:00 left) and runs at the nearest necromancer (enemies always advance),
## raking in reach. Extends Boss, so summons, spells and the spatial hash treat
## her like any enemy. Numbers in ScarmawData.BOSS (its header tells the fight):
##   * THE HUNT: packs of Razorclaws from three sides in turn (spawned in one
##     tick on the spawn ring: PackBrain makes each a pack with its alpha), and
##     the LEAP over the ring onto a landing circle beside the necromancer.
##   * THE AMBUSH (below ambush_hp): she vanishes (Enemy.untargetable and
##     ethereal, the existing one paths; damage_taken_mult() 0 meanwhile),
##     marks fern patches round the necromancer and lunges out of one every
##     ambush_every s, then fights in the open for exposed_time s.
##   * BLOOD UP (below blood_hp): her alpha-guard comes; while it lives every
##     Razorclaw killed (the run stat kill_razorclaw) comes back on the spawn
##     ring and she runs faster. Kill the guard and Blood Up ends.
## The Titans' rules exist wherever she fights (Game.primeval_rules(): the
## packs she calls are PackBrain's). When she falls the short ending text (no
## epilogue part). Slaying her unlocks Pack Leap with Pack Instinct (UnlockData,
## boss "scarmaw"). Determinism: the seeded gameplay RNG only (the patches'
## angle, the patch she lunges from). Stats: boss_atk_<special>,
## scarmaw_leap_hits, scarmaw_leap_on_you, scarmaw_lunge_hits,
## scarmaw_lunge_on_you, scarmaw_hidden_s, scarmaw_ambush_at,
## scarmaw_blood_at, scarmaw_blood_end_at, scarmaw_kill_time.
class_name BossScarmaw
extends Boss

## Boss action states.
enum Act { WALK, LEAP_WINDUP, LEAP, HIDDEN, RUSTLE, LUNGE, RECOVER }

## px the autotest bot keeps beyond a landing circle or a lunge's line (autotest hint only).
const DANGER_MARGIN: float = 26.0  # TUNING (not in GDD) autotest hint only
## px between two drawn marks of a lunge's line (visual only).
const MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only

## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## True once the Ambush began (below ambush_hp).
var ambushing: bool = false
## True while Blood Up runs (the guard alive).
var blood_up: bool = false
## True once Blood Up began (it never begins twice).
var blood_begun: bool = false
## Seconds until the next pack.
var _hunt_cd: float = 0.0
## Packs called so far (each from the next side).
var _hunts: int = 0
## Angle (rad) of the first pack's side.
var _hunt_a0: float = 0.0
## Seconds until the next leap may start.
var _leap_cd: float = 0.0
## Seconds she still fights in the open before she hides again (the Ambush).
var _open_left: float = 0.0
## Seconds she stays hidden before a patch rustles.
var _hide_for: float = 0.0
## The leap's start and landing points (world px).
var _from: Vector2 = Vector2.ZERO
## The leap's landing point (world px).
var _to: Vector2 = Vector2.ZERO
## Fern patches as offsets (px) from the necromancer they ring.
var _patches: Array[Vector2] = []
## Index of the patch that rustles (-1 = none).
var _rustle: int = -1
## The lunge's direction (unit).
var _lunge_dir: Vector2 = Vector2.RIGHT
## px of the lunge run so far.
var _lunge_run: float = 0.0
## Her alpha-guard (null before / after; generation-checked).
var _guard: Enemy = null
## Generation of `_guard` when it came.
var _guard_gen: int = 0
## The run's Razorclaw kills counted so far (Blood Up's returns).
var _kills_seen: int = 0
## Razorclaws owed back by Blood Up.
var _owed: int = 0
## Game time (s) the next Razorclaw may come back.
var _next_return: float = 0.0
## Her running speed (px/s, before the advance stride and Blood Up).
var _base_speed: float = 64.0
## Game time (s) she arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Scarmaw at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ScarmawData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	act = Act.WALK
	act_time = 0.0
	ambushing = false
	blood_up = false
	blood_begun = false
	_hunt_cd = float(boss_def["hunt_first"])
	_hunts = 0
	_hunt_a0 = randf() * TAU
	_leap_cd = float(boss_def["leap_first"])
	_patches.clear()
	_rustle = -1
	_guard = null
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.primeval_rules()  # Her packs are PackBrain's (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return ScarmawData.SPECIALS


## True while she runs at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return ScarmawData.SPRITE


## Any removal brings her out of the ferns (the pool reuses the node).
func deactivate() -> void:
	_show(true)
	super.deactivate()


## Hidden in the ferns, leaping or rustling she cannot be hurt.
func damage_taken_mult(source: String) -> float:
	if act == Act.HIDDEN or act == Act.RUSTLE or act == Act.LEAP:
		return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the thresholds, the Hunt's clock, Blood Up, then her action machine.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_leap_cd -= delta
	if not ambushing and hp <= max_hp * float(boss_def["ambush_hp"]):
		ambushing = true
		_open_left = 0.0
		game.stats["scarmaw_ambush_at"] = game.elapsed
		game.enemies.show_banner(String(boss_def["ambush_banner"]))
	if not blood_begun and hp <= max_hp * float(boss_def["blood_hp"]):
		_begin_blood()
	_step_hunt(delta)
	_step_blood()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.LEAP_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["leap_windup"]):
				_from = position
				ethereal = true
				phases_obstacles = true
				game.primeval_rules().play_sound("scarmaw_leap", position, 0.3)
				_set_act(Act.LEAP)
		Act.LEAP:
			_tick_timers(delta)
			var k := clampf(act_time / maxf(0.05, float(boss_def["leap_time"])), 0.0, 1.0)
			position = _from.lerp(_to, k)
			velocity = Vector2.ZERO
			if k >= 1.0:
				_land()
				_set_act(Act.RECOVER)
		Act.HIDDEN:
			_hold(delta)
			game.stat_add("scarmaw_hidden_s", delta)
			if act_time >= _hide_for:
				_start_rustle()
		Act.RUSTLE:
			_hold(delta)
			game.stat_add("scarmaw_hidden_s", delta)
			if act_time >= float(boss_def["rustle_time"]):
				_start_lunge()
		Act.LUNGE:
			_tick_timers(delta)
			_step_lunge(delta)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)


## Running: the shared AI at her speed (faster from afar and in Blood Up);
## in the Ambush she hides again once her time in the open is up, else she
## leaps over the ring when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0) \
			* (float(boss_def["blood_speed"]) if blood_up else 1.0)
	super.physics_step(delta)
	if ambushing:
		_open_left -= delta
		if _open_left <= 0.0 and stun_timer <= 0.0:
			_vanish(pl)
		return
	if _leap_cd <= 0.0 and dist <= float(boss_def["leap_trigger"]) and stun_timer <= 0.0:
		_leap_cd = float(boss_def["leap_every"])
		var side := position - pl.position
		var dir := side.normalized() if side.length() > 1.0 else Vector2.RIGHT
		_to = game.arena.free_point(pl.position + dir * float(boss_def["leap_land"]), radius)
		game.stat_add("boss_atk_leap", 1.0)
		motion_lunge((_to - position).normalized(), MotionData.POWER_CAST)
		_set_act(Act.LEAP_WINDUP)


## Standing still during a windup, a recovery or a hiding (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Hunt
# =====================================================================================

## THE HUNT's clock: a pack from the next of three sides, while few hunt.
func _step_hunt(delta: float) -> void:
	_hunt_cd -= delta
	if _hunt_cd > 0.0:
		return
	_hunt_cd = float(boss_def["hunt_every"])
	if _razorclaws() >= int(boss_def["hunt_cap"]):
		return
	var a := _hunt_a0 + deg_to_rad(float(boss_def["hunt_turn"])) * float(_hunts)
	_hunts += 1
	game.stat_add("boss_atk_hunt", 1.0)
	var c := game.enemies.ring_point(a)
	var side := Vector2.from_angle(a).orthogonal()
	var n := int(boss_def["hunt_size"])
	for i in n:
		game.enemies.spawn_at(PrimevalEnemyData.RAZORCLAW, game.arena.free_point(c + side * (float(i) - float(n - 1) * 0.5) * 26.0, 10.0), false)
	game.primeval_rules().play_sound("pack_circle", c, 0.5)


## Razorclaws alive now.
func _razorclaws() -> int:
	var n := 0
	for e in game.enemies.active:
		if e.active and e.kind == PrimevalEnemyData.RAZORCLAW:
			n += 1
	return n


## The leap lands: every grounded summon and necromancer within leap_radius
## px of the landing takes its damage.
func _land() -> void:
	ethereal = false
	phases_obstacles = false
	position = game.arena.free_point(position, radius)
	var r := float(boss_def["leap_radius"])
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x her buffs.
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
			continue
		if u.position.distance_to(position) <= r + u.radius:
			game.combat.damage_unit(u, float(boss_def["leap_damage_summon"]) * ts * undead_damage_mult, ScarmawData.LEAP_SOURCE, self)
			game.stat_add("scarmaw_leap_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["leap_damage"]) * ts, ScarmawData.LEAP_SOURCE, pl, self)
			game.stat_add("scarmaw_leap_on_you", 1.0)
	game.effects.impact(position, r, Palette.PRIMEVAL_FERN)
	game.shake(4.0)


# =====================================================================================
# The Ambush
# =====================================================================================

## She vanishes into the ferns: fern patches round `pl` (a seeded angle).
func _vanish(pl: Necromancer) -> void:
	_show(false)
	_patches.clear()
	var n := int(boss_def["patches"])
	var a0 := randf() * TAU
	for i in n:
		_patches.append(Vector2.from_angle(a0 + TAU * float(i) / float(n)) * float(boss_def["patch_dist"]))
	_rustle = -1
	_hide_for = maxf(0.5, float(boss_def["ambush_every"]) - float(boss_def["rustle_time"]) - float(boss_def["exposed_time"]))
	game.stat_add("boss_atk_ambush", 1.0)
	game.effects.ring(position, radius * 2.0, Palette.PRIMEVAL_FERN, 0.4)
	_set_act(Act.HIDDEN)


## One patch (seeded) rustles: she crouches in it, still hidden.
func _start_rustle() -> void:
	var pl := game.nearest_player(position)
	_rustle = randi() % maxi(1, _patches.size())
	position = game.arena.free_point(pl.position + _patches[_rustle], radius)
	game.primeval_rules().play_sound("scarmaw_rustle", position, 0.5)
	_set_act(Act.RUSTLE)


## Out of the patch at the necromancer.
func _start_lunge() -> void:
	var pl := game.nearest_player(position)
	var to := pl.position - position
	_lunge_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	_lunge_run = 0.0
	_show(true)
	_rustle = -1
	game.stat_add("boss_atk_lunge", 1.0)
	motion_lunge(_lunge_dir, MotionData.POWER_CAST)
	game.primeval_rules().play_sound("scarmaw_lunge", position, 0.3)
	_set_act(Act.LUNGE)


## The lunge runs; the first body she touches is bitten; then the open fight.
func _step_lunge(delta: float) -> void:
	var spd := float(boss_def["lunge_speed"])
	velocity = _lunge_dir * spd
	position += _lunge_dir * spd * delta
	_update_facing()
	_lunge_run += spd * delta
	var ts := game.enemies.damage_mult * hit_mult()
	var hit := BogCrocKit.bite_first(self, float(boss_def["lunge_damage_summon"]) * ts, float(boss_def["lunge_damage"]) * ts, _buf, ScarmawData.LUNGE_SOURCE)
	if hit == 1:
		game.stat_add("scarmaw_lunge_hits", 1.0)
	elif hit == 2:
		game.stat_add("scarmaw_lunge_on_you", 1.0)
	if hit > 0 or _lunge_run >= float(boss_def["lunge_len"]):
		_open_left = float(boss_def["exposed_time"])
		_set_act(Act.RECOVER)


## Shown (`on`) or hidden in the ferns: hidden she is untargetable and ethereal.
func _show(on: bool) -> void:
	untargetable = not on
	ethereal = not on
	phases_obstacles = not on
	queue_redraw()


# =====================================================================================
# Blood Up
# =====================================================================================

## BLOOD UP begins: her alpha-guard comes to her side.
func _begin_blood() -> void:
	blood_begun = true
	var g := game.enemies.spawn_at(FernBasinEnemyData.GUARD, game.arena.free_point(position + Vector2.from_angle(randf() * TAU) * float(boss_def["guard_dist"]), 12.0), false)
	if g == null:
		return
	_guard = g
	_guard_gen = g.generation
	blood_up = true
	_kills_seen = int(game.stats.get("kill_" + PrimevalEnemyData.RAZORCLAW, 0.0))
	_owed = 0
	game.stat_add("boss_atk_blood_up", 1.0)
	game.stats["scarmaw_blood_at"] = game.elapsed
	game.enemies.show_banner(String(boss_def["blood_banner"]))
	game.primeval_rules().play_sound("pack_hold", position, 0.5)


## While Blood Up runs: every Razorclaw killed comes back (capped); the
## guard's death ends it.
func _step_blood() -> void:
	if not blood_up:
		return
	if not (_guard.active and _guard.generation == _guard_gen):
		blood_up = false
		_guard = null
		game.stats["scarmaw_blood_end_at"] = game.elapsed
		game.enemies.show_banner(String(boss_def["blood_end_banner"]))
		return
	var kills := int(game.stats.get("kill_" + PrimevalEnemyData.RAZORCLAW, 0.0))
	_owed += kills - _kills_seen
	_kills_seen = kills
	if _owed <= 0 or game.elapsed < _next_return or _razorclaws() >= int(boss_def["blood_cap"]):
		return
	_owed -= 1
	_next_return = game.elapsed + float(boss_def["blood_gap"])
	var a := (position - game.nearest_player(position).position).angle()  # On her side of the ring.
	if game.enemies.spawn_at(PrimevalEnemyData.RAZORCLAW, game.enemies.ring_point(a), false) != null:
		game.stat_add("boss_atk_blood_respawn", 1.0)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue).
func _on_defeated() -> void:
	var pos := position
	blood_up = false
	game.effects.ring(pos, 240.0, Palette.PRIMEVAL_FERN, 1.0)
	game.effects.ring(pos, 140.0, Palette.PRIMEVAL_BONE, 0.8)
	Juice.fx.burst(pos, Palette.PRIMEVAL_FERN, Palette.PRIMEVAL_BONE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + ScarmawData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = ScarmawData.LATE_ANNOUNCE if game.countdown_finished() else ScarmawData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.PRIMEVAL_FERN)
	game.stats["scarmaw_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: off the landing circle while she
## crouches or flies, out of the lunge's way while a patch rustles.
func danger_push(p: Vector2) -> Vector2:
	if act == Act.LEAP_WINDUP or act == Act.LEAP:
		var reach := float(boss_def["leap_radius"]) + DANGER_MARGIN
		var off := p - _to
		var dist := off.length()
		if dist >= reach:
			return Vector2.ZERO
		return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 3.0
	if act == Act.RUSTLE:
		var to := p - position
		var side := to.normalized().orthogonal() if to.length() > 1.0 else Vector2.UP
		return side * 1.5 if to.length() < float(boss_def["lunge_len"]) + DANGER_MARGIN else Vector2.ZERO
	return Vector2.ZERO


## Body layer on `ci`: nothing while hidden; her still / walk frame (pose 1
## while she crouches, leaps or lunges); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	if act == Act.HIDDEN or act == Act.RUSTLE:
		return
	var pose := 1 if act == Act.LEAP_WINDUP or act == Act.LEAP or act == Act.LUNGE else 0
	if not SpriteBank.draw_pose(ci, ScarmawData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		PrimevalGlyphs._beast(ci, Vector2.ZERO, radius, flash > 0.0, Palette.PRIMEVAL_FERN_DARK, Palette.PRIMEVAL_FERN, 0.9, 1.0)
		ci.draw_rect(Rect2(Vector2(radius * 0.3, -radius * 1.2), Vector2(radius * 0.5, 3.0)), Glyphs._c(Palette.PRIMEVAL_BONE, flash > 0.0))  # Her bone crest.


## Overlay layer on `ci`: the landing circle while she crouches or flies, the
## fern patches while she hides (the rustling one bright) and the lunge's
## line. Visual only: rects and disc textures in world axes.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.LEAP_WINDUP or act == Act.LEAP:
		var k := clampf(act_time / maxf(0.01, float(boss_def["leap_windup"])), 0.0, 1.0) if act == Act.LEAP_WINDUP else 1.0
		SpriteBank.draw_disc(ci, _to - position, float(boss_def["leap_radius"]), Color(Palette.PRIMEVAL_LAVA, 0.12 + 0.18 * k))
	if act == Act.HIDDEN or act == Act.RUSTLE:
		var pl := game.nearest_player(position)
		for i in _patches.size():
			var c := (position if i == _rustle else pl.position + _patches[i]) - position
			var bright := i == _rustle
			var r := float(boss_def["patch_radius"])
			SpriteBank.draw_disc(ci, c, r, Color(Palette.PRIMEVAL_FERN_DARK, 0.55 if bright else 0.35))
			for j in 5:
				var wob := sin(game.elapsed * (14.0 if bright else 2.0) + float(j)) * (3.0 if bright else 1.0)
				ci.draw_rect(Rect2(c + Vector2.from_angle(float(j) * 1.26) * r * 0.6 + Vector2(wob, 0.0), Vector2(7.0, 2.0)), Color(Palette.PRIMEVAL_FERN, 0.9 if bright else 0.5))  # A frond.
		if act == Act.RUSTLE:
			var to := pl.position - position
			var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
			var s := radius
			while s < float(boss_def["lunge_len"]):
				ci.draw_rect(Rect2(dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.PRIMEVAL_LAVA, 0.6))
				s += MARK_STEP
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen and act != Act.HIDDEN and act != Act.RUSTLE:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var amb := float(st.get("scarmaw_ambush_at", -1.0))
	var bu := float(st.get("scarmaw_blood_at", -1.0))
	var be := float(st.get("scarmaw_blood_end_at", -1.0))
	var kt := float(st.get("scarmaw_kill_time", -1.0))
	return "the Hunt: packs %d, leaps %d (landed on summons %d, you %d) | the Ambush %s: hides %d (%.0f s hidden), lunges %d (bit summons %d, you %d) | Blood Up %s (ended %s): razorclaws back %d | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_hunt", 0.0)), int(st.get("boss_atk_leap", 0.0)), int(st.get("scarmaw_leap_hits", 0.0)), int(st.get("scarmaw_leap_on_you", 0.0)),
		EmpireReport._clock(amb) if amb >= 0.0 else "not reached", int(st.get("boss_atk_ambush", 0.0)), float(st.get("scarmaw_hidden_s", 0.0)),
		int(st.get("boss_atk_lunge", 0.0)), int(st.get("scarmaw_lunge_hits", 0.0)), int(st.get("scarmaw_lunge_on_you", 0.0)),
		EmpireReport._clock(bu) if bu >= 0.0 else "not reached", EmpireReport._clock(be) if be >= 0.0 else "no",
		int(st.get("boss_atk_blood_respawn", 0.0)),
		("%.0f s after she arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + ScarmawData.LEAP_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + ScarmawData.LUNGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + ScarmawData.LEAP_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + ScarmawData.LUNGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
