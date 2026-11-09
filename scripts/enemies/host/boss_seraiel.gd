## BossSeraiel — SERAIEL, WARDEN OF THE GATE, the boss of the Silver Stair
## (temporary Act XIII, the Celestial Host; GDD §15.0 "Seraiel, Warden of the
## Gate (Act XIII phase 2)"; owner-approved proposal: the Gate, the Sword, the
## Trial). Loaded by name for the boss id "seraiel"
## (EnemyDirector.HOST_BOSS_DIR + "boss_seraiel.gd"); he arrives at 17:00 (3:00
## left) and walks at the nearest necromancer (enemies always advance), striking
## in reach. Extends Boss, so summons, spells and the spatial hash treat him like
## any enemy (no halo: Grace is a HostKit's). Numbers in SeraielData.BOSS:
##   * THE SWORD (all fight): a telegraphed sweep of his flaming sword across
##     the ring (CherubKit.sweep(), the one blade test).
##   * THE GATE (from phase 2): lanes across a seeded axis round the
##     necromancer; one stays open, the others close one by one toward it, a
##     wall of Hallowed Light sweeping each (HallowedLight.add_shaft(), the
##     Light's one path; the Light's max_live is raised by one while the Gate
##     stands, so the act's own shafts still fall).
##   * THE TRIAL (all fight): a phase he outlasts by trial_time s fills the
##     scales by a third (Judgment.add(), THE one write), once a phase.
## The rules exist wherever he fights (Game.host_rules()); off a Host stage the
## scales stay empty (Judgment is off there), the Gate's walls still burn.
## When he falls the Gate falls with him; the defeat banner and a short ending
## text (no epilogue part). Slaying him unlocks Flaming Sword with Fallen Light
## (UnlockData, boss "seraiel"); Without Sin is SilverStairDirector's.
## Determinism: the seeded gameplay RNG only (the Gate's axis and open lane).
## Stats: boss_atk_<special>, seraiel_sword_cuts, seraiel_lanes_refused,
## seraiel_trials, seraiel_trial_refused, seraiel_phase2_at, seraiel_phase3_at,
## seraiel_kill_time.
class_name BossSeraiel
extends Boss

## His phases (SeraielData header).
enum Form { SWORD, GATE, BOTH }
## Boss action states.
enum Act { WALK, SWORD_WINDUP, SWEEP, GATE_CAST, RECOVER }

## px the autotest bot keeps beyond the sword's reach (autotest hint only).
const DANGER_MARGIN: float = 26.0  # TUNING (not in GDD) autotest hint only
## px between two drawn marks of the blade and its arc (visual only).
const MARK_STEP: float = 7.0  # TUNING (not in GDD) visual only
## px each drawn wall of the Gate runs along its lane (visual only).
const WALL_LENGTH: float = 1400.0  # TUNING (not in GDD) visual only

## Current phase.
var form: Form = Form.SWORD
## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## Seconds until the next sword sweep may start.
var _sword_cd: float = 0.0
## Seconds until the next Gate (INF before phase 2).
var _gate_cd: float = INF
## The current sweep's start angle (rad) and the angle swept so far.
var _sweep_a0: float = 0.0
## Radians swept so far this sweep.
var _swept: float = 0.0
## The sweep's whole arc (rad).
var _arc: float = 0.0
## Seconds the current phase may still run before he has survived it.
var _trial_left: float = 0.0
## True once the current phase's Trial was paid.
var _trial_done: bool = false
## The Gate's centre (world px) and axis (unit; lanes run across it).
var _gate_c: Vector2 = Vector2.ZERO
## The Gate's axis (unit vector).
var _gate_n: Vector2 = Vector2.RIGHT
## Index of the lane that stays open (-1 = no Gate standing).
var _gate_safe: int = -1
## Lanes still to close, in order (the farthest from the open lane first).
var _gate_order: Array[int] = []
## Lanes already closed this Gate.
var _gate_closed: Array[int] = []
## Game time (s) the next lane closes.
var _gate_next: float = INF
## Game time (s) the Gate's walls stop being drawn (and the Light's extra slot ends).
var _gate_end: float = -1.0
## True while the Light's max_live is raised by one for the Gate.
var _gate_slot: bool = false
## His walking speed (px/s, before the advance stride).
var _base_speed: float = 42.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Seraiel at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = SeraielData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	form = Form.SWORD
	act = Act.WALK
	act_time = 0.0
	_sword_cd = float(boss_def["sword_first"])
	_gate_cd = INF
	_gate_safe = -1
	_trial_left = float(boss_def["trial_time"])
	_trial_done = false
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.host_rules()  # His Gate goes through the Light, his Trial through the scales (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["phase1_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return SeraielData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return SeraielData.SPRITE


## Any removal ends the Gate (the pool reuses the node).
func deactivate() -> void:
	_end_gate()
	super.deactivate()


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the phases, the Trial, the Gate's lanes, then his action machine.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_sword_cd -= delta
	_gate_cd -= delta
	if form == Form.SWORD and hp <= max_hp * float(boss_def["phase2_hp"]):
		_enter(Form.GATE, "phase2_banner", "seraiel_phase2_at")
	if form == Form.GATE and hp <= max_hp * float(boss_def["phase3_hp"]):
		_enter(Form.BOTH, "phase3_banner", "seraiel_phase3_at")
	_step_trial(delta)
	_step_gate()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.SWORD_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["sword_windup"]):
				_swept = 0.0
				game.host_rules().play_sound("seraiel_sword", position, 0.3)
				_set_act(Act.SWEEP)
		Act.SWEEP:
			_hold(delta)
			_step_sweep(delta)
		Act.GATE_CAST:
			_hold(delta)
			if act_time >= float(boss_def["gate_cast"]):
				_raise_gate()
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)


## A new phase: its banner, a fresh Trial clock, the Gate's clock from phase 2.
func _enter(f: Form, banner: String, stat: String) -> void:
	form = f
	_trial_left = float(boss_def["trial_time"])
	_trial_done = false
	if f == Form.GATE:
		_gate_cd = float(boss_def["gate_first"])
	game.stats[stat] = game.elapsed
	game.enemies.show_banner(String(boss_def[banner]))
	game.shake(4.0)


## THE TRIAL: the phase outlasted its trial_time: the scales fill by a third
## (once a phase; refused while a Verdict runs, or off a Host stage).
func _step_trial(delta: float) -> void:
	if _trial_done:
		return
	_trial_left -= delta
	if _trial_left > 0.0:
		return
	_trial_done = true
	var j := game.host_rules().judgment
	game.stat_add("boss_atk_trial", 1.0)
	if j.add(float(j.cfg["capacity"]) * float(boss_def["trial_share"])):
		game.stat_add("seraiel_trials", 1.0)
	else:
		game.stat_add("seraiel_trial_refused", 1.0)
	game.enemies.show_banner(String(boss_def["trial_banner"]))
	game.host_rules().play_sound("trial", position, 0.5)


## Walking: the shared AI at his speed, faster from afar; a Gate or a sweep
## starts when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)
	if form != Form.SWORD and _gate_cd <= 0.0 and _gate_safe < 0:
		_gate_cd = float(boss_def["gate_every_p3" if form == Form.BOTH else "gate_every"])
		game.stat_add("boss_atk_gate", 1.0)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_act(Act.GATE_CAST)
	elif _sword_cd <= 0.0 and dist <= float(boss_def["sword_trigger"]) and stun_timer <= 0.0:
		_sword_cd = float(boss_def["sword_every_p3" if form == Form.BOTH else "sword_every"])
		_arc = deg_to_rad(float(boss_def["sword_arc"]))
		_sweep_a0 = (pl.position - position).angle() - _arc * 0.5
		game.stat_add("boss_atk_sword", 1.0)
		motion_lunge((pl.position - position).normalized(), MotionData.POWER_CAST)
		_set_act(Act.SWORD_WINDUP)


## The sword turns by this tick's share of its arc and cuts what it passes.
func _step_sweep(delta: float) -> void:
	var da := minf(_arc / maxf(0.05, float(boss_def["sword_time"])) * delta, _arc - _swept)
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x his buffs.
	var n := CherubKit.sweep(game, position, _sweep_a0 + _swept, da, float(boss_def["sword_reach"]),
			float(boss_def["sword_damage_summon"]) * ts * undead_damage_mult, float(boss_def["sword_damage"]) * ts,
			SeraielData.SWORD_SOURCE, self, _buf)
	if n > 0:
		game.stat_add("seraiel_sword_cuts", float(n))
	_swept += da
	queue_redraw()
	if _swept >= _arc - 0.0001:
		_set_act(Act.RECOVER)


## Standing still during a windup or a recovery (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Gate
# =====================================================================================

## THE GATE rises round the nearest necromancer: lanes across a seeded axis,
## one left open (seeded), the others queued farthest from it first.
func _raise_gate() -> void:
	var pl := game.nearest_player(position)
	var lanes := int(boss_def["gate_lanes"])
	_gate_c = pl.position
	_gate_n = Vector2.from_angle(randf() * TAU)
	_gate_safe = randi() % lanes
	_gate_order.clear()
	_gate_closed.clear()
	for dist in range(lanes - 1, 0, -1):  # Farthest from the open lane first, the low side before the high.
		for side: int in [-1, 1]:
			var i := _gate_safe + side * dist
			if i >= 0 and i < lanes:
				_gate_order.append(i)
	_gate_next = game.elapsed + float(boss_def["gate_close_every"])
	_gate_end = INF
	if not _gate_slot:
		_gate_slot = true
		game.host_rules().light.max_live += 1  # One more shaft at once while the Gate stands.
	game.effects.ring(_gate_c, float(boss_def["gate_lane"]) * float(lanes) * 0.5, Palette.HOST_STARLIGHT, 0.5)
	game.host_rules().play_sound("gate_raise", _gate_c, 0.5)
	queue_redraw()


## Per tick: the next lane closes on its clock; the Gate ends after the last.
func _step_gate() -> void:
	if _gate_safe < 0:
		return
	var now := game.elapsed
	if not _gate_order.is_empty() and now >= _gate_next:
		_close_lane(_gate_order.pop_front())
		_gate_next = now + float(boss_def["gate_close_every"])
		if _gate_order.is_empty():
			var light := game.host_rules().light
			_gate_end = now + float(boss_def["gate_lane"]) / maxf(1.0, float(light.cfg["speed"])) + float(boss_def["gate_show_after"])
	if now >= _gate_end:
		_end_gate()
	queue_redraw()


## Lane `i` closes: a wall of Hallowed Light sweeps across it toward the open lane.
func _close_lane(i: int) -> void:
	var w := float(boss_def["gate_lane"])
	var lanes := int(boss_def["gate_lanes"])
	var lo := (float(i) - float(lanes) * 0.5) * w  # The lane's low border along the axis (px from the centre).
	var toward := 1.0 if i < _gate_safe else -1.0  # Toward the open lane.
	var start := lo if toward > 0.0 else lo + w
	_gate_closed.append(i)
	game.stat_add("boss_atk_lane_closed", 1.0)
	if not game.host_rules().light.add_shaft(_gate_c + _gate_n * start, _gate_n * toward, float(boss_def["gate_wall"]), w):
		game.stat_add("seraiel_lanes_refused", 1.0)


## The autotest autopilot's goal while the Gate stands: the nearest point on
## the open lane's middle line (Vector2.INF when no Gate stands).
func gate_point(p: Vector2) -> Vector2:
	if _gate_safe < 0:
		return Vector2.INF
	var mid := (float(_gate_safe) + 0.5 - float(int(boss_def["gate_lanes"])) * 0.5) * float(boss_def["gate_lane"])  # The open lane's middle along the axis.
	return p - _gate_n * ((p - _gate_c).dot(_gate_n) - mid)


## The Gate falls: its walls vanish and the Light's extra slot ends.
func _end_gate() -> void:
	_gate_safe = -1
	_gate_order.clear()
	_gate_end = -1.0
	if _gate_slot:
		_gate_slot = false
		if game != null and game.host != null:
			game.host.light.max_live = maxi(1, game.host.light.max_live - 1)
	queue_redraw()


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the Gate
## falls; the short ending text (no epilogue).
func _on_defeated() -> void:
	_end_gate()
	var pos := position
	game.effects.ring(pos, 240.0, Palette.HOST_STARLIGHT, 1.0)
	game.effects.ring(pos, 140.0, Palette.HOST_CERULEAN, 0.8)
	Juice.fx.burst(pos, Palette.HOST_STARLIGHT, Palette.HOST_CERULEAN, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + SeraielData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = SeraielData.LATE_ANNOUNCE if game.countdown_finished() else SeraielData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.HOST_STARLIGHT)
	game.stats["seraiel_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the sword's reach while it
## is raised or sweeping (the Gate's walls are shafts: the Light's own hint).
func danger_push(p: Vector2) -> Vector2:
	if act != Act.SWORD_WINDUP and act != Act.SWEEP:
		return Vector2.ZERO
	var reach := float(boss_def["sword_reach"]) + DANGER_MARGIN
	var off := p - position
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 3.0


## Body layer on `ci`: his still / walk frame (pose 1 while he raises the
## sword or the Gate); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if act == Act.SWORD_WINDUP or act == Act.SWEEP or act == Act.GATE_CAST else 0
	if not SpriteBank.draw_pose(ci, SeraielData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		_glyph(ci)


## His code shape without the art: a towering silver archangel, four wings,
## a white-flame sword (rects and disc textures).
func _glyph(ci: CanvasItem) -> void:
	var r := radius
	var fl := flash > 0.0
	for s: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(Vector2(s * r * 0.5 - (r * 1.3 if s < 0.0 else 0.0), -r * 1.3), Vector2(r * 1.3, r * 0.55)), Glyphs._c(Color(Palette.HOST_CLOUD, 0.9), fl))  # Upper wings.
		ci.draw_rect(Rect2(Vector2(s * r * 0.5 - (r * 1.0 if s < 0.0 else 0.0), -r * 0.6), Vector2(r * 1.0, r * 0.45)), Glyphs._c(Color(Palette.HOST_SILVER, 0.9), fl))  # Lower wings.
	var body := Rect2(Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 1.7))
	ci.draw_rect(body.grow(1.5), HostGlyphs.INK)
	ci.draw_rect(body, Glyphs._c(Palette.HOST_SILVER, fl))
	ci.draw_rect(Rect2(body.position + Vector2(0.0, r * 0.5), Vector2(body.size.x, 3.0)), Glyphs._c(Palette.HOST_CERULEAN, fl))  # His belt of light.
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.45, Glyphs._c(HostGlyphs.INK, fl))
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.38, Glyphs._c(Palette.HOST_STARLIGHT, fl))  # A face of light.
	ci.draw_rect(Rect2(Vector2(r * 0.6, -r * 1.6), Vector2(3.0, r * 2.2)), Glyphs._c(Palette.HOST_STARLIGHT, fl))  # The flaming sword.


## Overlay layer on `ci`: the sword's arc of marks while raised, the blade
## while it sweeps, and the Gate's walls (the open lane's in dawn rose, the
## next to close in cerulean). Visual only: rects and lines in world axes.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.SWORD_WINDUP or act == Act.SWEEP:
		var reach := float(boss_def["sword_reach"])
		if act == Act.SWORD_WINDUP:
			var k := clampf(act_time / maxf(0.01, float(boss_def["sword_windup"])), 0.0, 1.0)
			var marks := maxi(2, int(_arc * reach / MARK_STEP))
			for i in marks + 1:
				var p := Vector2.from_angle(_sweep_a0 + _arc * float(i) / float(marks)) * reach
				ci.draw_rect(Rect2(p - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.HOST_CERULEAN, 0.35 + 0.55 * k))
		var dir := Vector2.from_angle(_sweep_a0 + _swept)
		var s := radius * 0.6
		while s < reach:
			ci.draw_rect(Rect2(dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.HOST_STARLIGHT, 0.9 if act == Act.SWEEP else 0.4))
			s += MARK_STEP * 0.6
	if _gate_safe >= 0:
		var lanes := int(boss_def["gate_lanes"])
		var w := float(boss_def["gate_lane"])
		var along := _gate_n.orthogonal() * WALL_LENGTH * 0.5
		var next := -1 if _gate_order.is_empty() else _gate_order[0]
		for b in lanes + 1:
			var off := (float(b) - float(lanes) * 0.5) * w  # The border along the axis.
			var c := _gate_c + _gate_n * off - position
			var col := Color(Palette.HOST_STARLIGHT, 0.45)
			if b == _gate_safe or b == _gate_safe + 1:
				col = Color(Palette.HOST_ROSE, 0.8)  # The Gate: the lane that stays open.
			elif b == next or b == next + 1:
				col = Color(Palette.HOST_CERULEAN, 0.85)  # The next lane to close.
			ci.draw_line(c - along, c + along, col, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("seraiel_phase2_at", -1.0))
	var p3 := float(st.get("seraiel_phase3_at", -1.0))
	var kt := float(st.get("seraiel_kill_time", -1.0))
	return "the Sword: sweeps %d (bodies cut %d) | the Gate %s: gates %d, lanes closed %d (refused %d) | the Gate and the Sword %s | the Trial: survived %d (weighed %d, refused %d) | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_sword", 0.0)), int(st.get("seraiel_sword_cuts", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("boss_atk_gate", 0.0)),
		int(st.get("boss_atk_lane_closed", 0.0)), int(st.get("seraiel_lanes_refused", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached",
		int(st.get("boss_atk_trial", 0.0)), int(st.get("seraiel_trials", 0.0)), int(st.get("seraiel_trial_refused", 0.0)),
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + SeraielData.SWORD_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + SeraielData.SWORD_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
