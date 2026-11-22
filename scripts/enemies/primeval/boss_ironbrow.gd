## BossIronbrow — OLD IRONBROW, THE HORNED TITAN, the boss of the Great Plain
## (temporary Act XIV, the Age of Titans; GDD §15.0 "Old Ironbrow, the Horned
## Titan (Act XIV phase 2)"; owner-approved proposal: the Herd, the Charge, the
## Break). Loaded by name for the boss id "ironbrow"
## (EnemyDirector.PRIMEVAL_BOSS_DIR + "boss_ironbrow.gd"); he arrives at 17:00
## (3:00 left) and walks at the nearest necromancer (enemies always advance),
## goring in reach. Extends Boss, so summons, spells and the spatial hash treat
## him like any enemy. Numbers in IronbrowData.BOSS (its header tells the
## fight):
##   * THE CHARGE: a telegraphed straight charge at the necromancer through the
##     ring (HornchargerKit.gore(), the one charge hit); into a rock he is
##     stunned rock_stun s (HornchargerKit.rock_ahead(), the one rock test).
##   * THE HERD: every herd_every-th charge his herd stampedes the same way
##     behind him (Herds.spawn_herd() / launch(), the one stampede start).
##   * THE BREAK (below break_hp): he charges the nearest rock and snaps a horn:
##     three telegraphed shard lines, then faster, more frequent charges.
## The Titans' rules exist wherever he fights (Game.primeval_rules(): his herd
## is Herds'). When he falls the short ending text (no epilogue part). Slaying
## him unlocks Stampede with Calcified Hide (UnlockData, boss "ironbrow").
## Determinism: no RNG of his own (the herd's beasts come through the seeded
## spawn path); the rock search walks eight fixed directions. Stats:
## boss_atk_<special>, ironbrow_charge_hits, ironbrow_rock_stuns,
## ironbrow_herd_new, ironbrow_herd_led, ironbrow_shard_hits,
## ironbrow_shard_on_you, ironbrow_break_at, ironbrow_kill_time.
class_name BossIronbrow
extends Boss

## Boss action states.
enum Act { WALK, WINDUP, CHARGE, STUNNED, SHARDS, RECOVER }

## Directions the Break looks along for a rock (evenly round him).
const BREAK_DIRS: int = 8  # TUNING (not in GDD)

## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## True once the horn snapped (he charges with the stump).
var broken: bool = false
## True while the current charge is the Break's (at a rock).
var _breaking: bool = false
## True once the Break began (it never begins twice).
var _break_begun: bool = false
## Seconds until the next charge may start.
var _charge_cd: float = 0.0
## Charges started so far (every herd_every-th leads the herd).
var _charges: int = 0
## The current charge's direction (unit).
var _dir: Vector2 = Vector2.RIGHT
## px of the current charge run so far.
var _run: float = 0.0
## Seconds the current windup lasts.
var _windup: float = 1.0
## Bodies the current charge already hit.
var _hit: Array = []
## His herd (a Herds.Herd; null before the first).
var _herd: Herds.Herd = null
## The shard lines: their origin (world px) and directions (unit).
var _shard_from: Vector2 = Vector2.ZERO
## The shard lines' directions (unit), one per line.
var _shard_dirs: Array[Vector2] = []
## His walking speed (px/s, before the advance stride).
var _base_speed: float = 48.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Old Ironbrow at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = IronbrowData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	act = Act.WALK
	act_time = 0.0
	broken = false
	_breaking = false
	_break_begun = false
	_charge_cd = float(boss_def["charge_first"])
	_charges = 0
	_herd = null
	_shard_dirs.clear()
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.primeval_rules()  # His herd is Herds' (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return IronbrowData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return IronbrowData.SPRITE


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the Break's threshold, then his action machine.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_charge_cd -= delta
	if not _break_begun and hp <= max_hp * float(boss_def["break_hp"]) and act == Act.WALK:
		_begin_break()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.WINDUP:
			_hold(delta)
			if act_time >= _windup:
				_run = 0.0
				_hit.clear()
				motion_lunge(_dir, MotionData.POWER_CAST)
				game.primeval_rules().play_sound("ironbrow_charge", position, 0.3)
				_set_act(Act.CHARGE)
		Act.CHARGE:
			_tick_timers(delta)
			_step_charge(delta)
		Act.STUNNED:
			_hold(delta)
			if act_time >= float(boss_def["rock_stun"]):
				_set_act(Act.SHARDS if not _shard_dirs.is_empty() else Act.RECOVER)
		Act.SHARDS:
			_hold(delta)
			if act_time >= float(boss_def["shard_warn"]):
				_strike_shards()
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)


## Walking: the shared AI at his stride (faster from afar); a charge when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)
	if _charge_cd <= 0.0 and dist <= float(boss_def["charge_trigger"]) and stun_timer <= 0.0:
		_charge_cd = float(boss_def["stump_every"] if broken else boss_def["charge_every"])
		var to := pl.position - position
		_start_charge(to.normalized() if to.length() > 1.0 else Vector2.RIGHT)


## Standing still during a windup, a stun or a recovery (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Charge and the Herd
# =====================================================================================

## A charge along `dir` begins (its windup); every herd_every-th leads the herd.
func _start_charge(dir: Vector2) -> void:
	_dir = dir
	_charges += 1
	_windup = float(boss_def["charge_windup"])
	game.stat_add("boss_atk_charge", 1.0)
	if (_charges - 1) % maxi(1, int(boss_def["herd_every"])) == 0 and _lead_herd():
		_windup = maxf(_windup, float(game.primeval.herds.cfg["lead"]))  # His windup is the stampede's dust line.
	_set_act(Act.WINDUP)


## THE HERD: his herd stampedes along the charge, its front behind him (a new
## herd herd_back px behind him when his own is gone or far). Returns true when
## a herd runs.
func _lead_herd() -> bool:
	var hs := game.primeval_rules().herds
	if _herd != null:
		if not hs.herds.has(_herd):
			_herd = null  # Gone.
		elif _herd.state != Herds.GRAZE:
			return false  # Still running its last stampede.
		elif hs.centre(_herd).distance_to(position) > float(boss_def["herd_reach"]):
			_herd = null  # Grazing far off: a new herd follows him.
	if _herd == null:
		if hs.alive + int(boss_def["herd_size"]) > int(boss_def["herd_cap"]):
			return false
		var h := hs.spawn_herd(position - _dir * float(boss_def["herd_back"]), int(boss_def["herd_size"]), boss_def["herd_kinds"])
		if h.members.is_empty():
			return false
		_herd = h
		game.stat_add("ironbrow_herd_new", 1.0)
	hs.launch(_herd, hs.centre(_herd) + _dir * 1000.0)  # Owner-approved proposal: "the front runs behind him".
	game.stat_add("boss_atk_herd", 1.0)
	game.stat_add("ironbrow_herd_led", 1.0)
	game.enemies.show_banner(String(boss_def["herd_banner"]))
	return true


## The charge runs: every body he crosses is gored once; a rock stuns him.
func _step_charge(delta: float) -> void:
	var spd := float(boss_def["charge_speed"]) * (float(boss_def["stump_speed"]) if broken else 1.0)
	var step := spd * delta
	if HornchargerKit.rock_ahead(game, position, _dir, step, radius):
		_hit_rock()
		return
	velocity = _dir * spd
	position += _dir * step
	_update_facing()
	_run += step
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x his buffs.
	var n := HornchargerKit.gore(self, _hit, float(boss_def["charge_damage_summon"]) * ts, float(boss_def["charge_damage"]) * ts,
			float(boss_def["charge_stun"]), float(boss_def["charge_knock"]), _dir, IronbrowData.CHARGE_SOURCE, _buf)
	if n > 0:
		game.stat_add("ironbrow_charge_hits", float(n))
	if _breaking and _run >= float(boss_def["break_search"]) + radius:
		_snap(position)  # The Break's charge found no rock after all: he stamps where he stands.
		_set_act(Act.STUNNED)
	elif _run >= float(boss_def["charge_len"]) and not _breaking:
		position = game.arena.free_point(position, radius)
		_set_act(Act.RECOVER)


## He runs into a rock: stunned rock_stun s (the Break's charge snaps his horn).
func _hit_rock() -> void:
	game.stat_add("ironbrow_rock_stuns", 1.0)
	game.effects.impact(position + _dir * radius, radius * 1.4, Palette.PRIMEVAL_OCHRE)
	game.shake(5.0)
	Sfx.play("boss_impact", position, 0.4)
	if _breaking:
		_snap(position + _dir * radius)
	_set_act(Act.STUNNED)


# =====================================================================================
# The Break
# =====================================================================================

## THE BREAK begins: he charges the nearest rock within break_search px (eight
## fixed directions); with none near he stamps where he stands.
func _begin_break() -> void:
	_break_begun = true
	game.stat_add("boss_atk_break", 1.0)
	game.stats["ironbrow_break_at"] = game.elapsed
	game.enemies.show_banner(String(boss_def["break_banner"]))
	var reach := float(boss_def["break_search"])
	var best_d := reach
	var best := Vector2.ZERO
	for i in BREAK_DIRS:
		var dir := Vector2.from_angle(TAU * float(i) / float(BREAK_DIRS))
		var clear := game.arena.clear_length(position, dir, reach, radius * 0.5)
		if clear < best_d - 0.5:
			best_d = clear
			best = dir
	if best == Vector2.ZERO:
		_snap(position)
		_set_act(Act.STUNNED)
		return
	_breaking = true
	_dir = best
	_windup = float(boss_def["charge_windup"])
	_set_act(Act.WINDUP)


## The horn snaps at `at`: the shard lines (toward the necromancer, spread)
## show for shard_warn s, after the stun.
func _snap(at: Vector2) -> void:
	_breaking = false
	broken = true
	_shard_from = at
	_shard_dirs.clear()
	var pl := game.nearest_player(at)
	var to := pl.position - at
	var a0 := to.angle() if to.length() > 1.0 else _dir.angle()
	var n := int(boss_def["shards"])
	for i in n:
		_shard_dirs.append(Vector2.from_angle(a0 + deg_to_rad(float(boss_def["shard_spread"])) * (float(i) - float(n - 1) * 0.5)))
	game.effects.impact(at, radius, Palette.PRIMEVAL_BONE)
	queue_redraw()


## The shards strike: every summon and necromancer within shard_width px of a
## line takes its damage (once per line).
func _strike_shards() -> void:
	var len := float(boss_def["shard_len"])
	var w := float(boss_def["shard_width"])
	var ts := game.enemies.damage_mult * hit_mult()
	for dir: Vector2 in _shard_dirs:
		var mid := _shard_from + dir * len * 0.5
		game.ally_grid.query(mid, len * 0.5 + w + UnitData.MAX_BLOCK_RADIUS, _buf)
		for u: SummonedUnit in _buf.duplicate():
			if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
				continue
			if _on_line(u.position, dir, len, w + u.radius):
				game.combat.damage_unit(u, float(boss_def["shard_damage_summon"]) * ts * undead_damage_mult, IronbrowData.SHARD_SOURCE, self)
				game.stat_add("ironbrow_shard_hits", 1.0)
		for pl in game.all_players:
			if not pl.dead and _on_line(pl.position, dir, len, w + pl.radius):
				game.combat.damage_player(float(boss_def["shard_damage"]) * ts, IronbrowData.SHARD_SOURCE, pl, self)
				game.stat_add("ironbrow_shard_on_you", 1.0)
		game.effects.ring(_shard_from + dir * len, 16.0, Palette.PRIMEVAL_BONE, 0.3)
	_shard_dirs.clear()
	queue_redraw()


## True when `p` lies within `w` px of the shard line from _shard_from along `dir`, `len` px long.
func _on_line(p: Vector2, dir: Vector2, len: float, w: float) -> bool:
	var rel := p - _shard_from
	var along := rel.dot(dir)
	return along >= 0.0 and along <= len and absf(rel.dot(dir.orthogonal())) <= w


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue).
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 240.0, Palette.PRIMEVAL_OCHRE, 1.0)
	game.effects.ring(pos, 140.0, Palette.PRIMEVAL_BONE, 0.8)
	Juice.fx.burst(pos, Palette.PRIMEVAL_OCHRE, Palette.PRIMEVAL_BONE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + IronbrowData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = IronbrowData.LATE_ANNOUNCE if game.countdown_finished() else IronbrowData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.PRIMEVAL_OCHRE)
	game.stats["ironbrow_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the charge's line while he
## lowers his horns, off the shard lines while they show.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if act == Act.WINDUP or act == Act.CHARGE:
		push += HornchargerKit.line_push(position, _dir, float(boss_def["charge_len"]), radius, p) * 2.0
	for dir: Vector2 in _shard_dirs:
		push += HornchargerKit.line_push(_shard_from, dir, float(boss_def["shard_len"]), float(boss_def["shard_width"]), p)
	return push


## Body layer on `ci`: his still / walk frame (pose 1, the broken horn, after
## the Break); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	if not SpriteBank.draw_pose(ci, IronbrowData.SPRITE, 1 if broken else 0, Vector2.ZERO, flash > 0.0):
		PrimevalGlyphs._beast(ci, Vector2.ZERO, radius, flash > 0.0, Palette.PRIMEVAL_OCHRE_DARK, Palette.PRIMEVAL_OCHRE, 1.1, 0.0)
		var c := Glyphs._c(Palette.PRIMEVAL_BONE, flash > 0.0)
		ci.draw_rect(Rect2(Vector2(radius * 0.2, -radius * 1.1), Vector2(radius * 0.25, radius * 0.5)), Glyphs._c(Palette.PRIMEVAL_OCHRE_DARK, flash > 0.0))  # The frill.
		ci.draw_rect(Rect2(Vector2(radius * 0.8, -radius * 0.55), Vector2(radius * (0.25 if broken else 0.6), 3.0)), c)  # The upper horn (a stump after the Break).
		ci.draw_rect(Rect2(Vector2(radius * 0.8, -radius * 0.25), Vector2(radius * 0.55, 3.0)), c)  # The lower horn.


## Overlay layer on `ci`: the charge's line while he lowers his horns and the
## shard lines while they show. Visual only: rects in world axes.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.WINDUP:
		var k := clampf(act_time / maxf(0.01, _windup), 0.0, 1.0)
		HornchargerKit.draw_line_marks(ci, Vector2.ZERO, _dir, radius, float(boss_def["charge_len"]), k)
	if not _shard_dirs.is_empty():
		var k2 := clampf(act_time / maxf(0.01, float(boss_def["shard_warn"])), 0.0, 1.0) if act == Act.SHARDS else 0.2
		for dir: Vector2 in _shard_dirs:
			HornchargerKit.draw_line_marks(ci, _shard_from - position, dir, 0.0, float(boss_def["shard_len"]), k2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var br := float(st.get("ironbrow_break_at", -1.0))
	var kt := float(st.get("ironbrow_kill_time", -1.0))
	return "the Charge: %d (gored %d, into a rock %d) | the Herd: led %d (new herds %d) | the Break %s: shards hit summons %d, you %d | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_charge", 0.0)), int(st.get("ironbrow_charge_hits", 0.0)), int(st.get("ironbrow_rock_stuns", 0.0)),
		int(st.get("ironbrow_herd_led", 0.0)), int(st.get("ironbrow_herd_new", 0.0)),
		EmpireReport._clock(br) if br >= 0.0 else "not reached", int(st.get("ironbrow_shard_hits", 0.0)), int(st.get("ironbrow_shard_on_you", 0.0)),
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + IronbrowData.CHARGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + IronbrowData.SHARD_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + IronbrowData.CHARGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + IronbrowData.SHARD_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
