## BossStagKing — THE STAG KING, LORD OF THE GREENWOOD, the boss of the Greenwood
## (temporary Act XV, the Turning Year; GDD §15.0 "The Stag King (Act XV phase
## 2)"; owner-approved proposal: the Hunt, the Rut, the Antler Crown). Loaded by
## name for the boss id "stag_king" (EnemyDirector.WILD_BOSS_DIR +
## "boss_stag_king.gd"); he arrives at 17:00 (3:00 left, in the dead of winter)
## and walks at the nearest necromancer (enemies always advance), goring in
## reach. Extends Boss, so summons, spells and the spatial hash treat him like
## any enemy. Numbers in StagKingData.BOSS (its header tells the fight):
##   * THE RUT: a telegraphed charge through the ring (WildKit.trample(), the one
##     Wild trample); into a tree it cracks it into new thickets
##     (Thickets.plant(), the one planting path) and he staggers.
##   * THE HUNT: spectral riders sweep across the arena through the necromancer
##     in a line (two crossing lines below half his HP); data only, drawn here.
##   * THE ANTLER CROWN: at set shares of his HP a ring of thorns
##     (GreenwoodEnemyData "antler_thicket", AntlerThicketKit) grows round him
##     and walks with him; while one stands he takes no damage. Fire burns them
##     (crown_burn(), called through Thickets.ring_burns by Thickets.burn_at()).
## The Wild's rules exist wherever he fights (Game.wild_rules(): his thickets
## are Overgrowth's). When he falls the short ending text (no epilogue part).
## Slaying him unlocks Wild Hunt with Horn of the Hunt (UnlockData, boss
## "stag_king"). Determinism: no RNG of his own (the Hunt's side comes from his
## position and the necromancer's), the thorns through the seeded spawn path.
## Stats: boss_atk_<special>, stag_rut_hits, stag_rut_on_you, stag_rut_cracks,
## stag_rut_seeds, stag_hunt_lines, stag_hunt_hits, stag_hunt_on_you,
## stag_crown_thorns, stag_crown_burnt, stag_crown_broken, stag_crown_blocked,
## stag_crown_time, stag_kill_time.
class_name BossStagKing
extends Boss

## Boss action states.
enum Act { WALK, WINDUP, CHARGE, STAGGER, RECOVER }

## Current action.
var act: Act = Act.WALK
## Seconds spent in the current action.
var act_time: float = 0.0
## Seconds until the next charge may start.
var _charge_cd: float = 0.0
## Seconds until the next Hunt.
var _hunt_cd: float = 0.0
## The current charge's direction (unit).
var _dir: Vector2 = Vector2.RIGHT
## px of the current charge run so far.
var _run: float = 0.0
## Bodies the current charge already hit.
var _hit: Array = []
## The Hunt's lines in flight: {from (Vector2), dir (Vector2), t0 (game s of
## the ride's start, after the lead), hit (Array)} each.
var _lines: Array[Dictionary] = []
## The crown's thorns (Enemy) and their generations.
var _thorns: Array[Enemy] = []
## Generations of `_thorns`, index for index.
var _thorn_gens: Array[int] = []
## Crowns grown so far (index into crown_at).
var _crowns: int = 0
## Game time (s) the current crown grew (-1 = none standing).
var _crown_since: float = -1.0
## His walking speed (px/s, before the advance stride).
var _base_speed: float = 50.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the Stag King at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = StagKingData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	act = Act.WALK
	act_time = 0.0
	_charge_cd = float(boss_def["charge_first"])
	_hunt_cd = float(boss_def["hunt_first"])
	_lines.clear()
	_thorns.clear()
	_thorn_gens.clear()
	_crowns = 0
	_crown_since = -1.0
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.wild_rules().thickets.ring_burns.append(crown_burn)  # His crown burns like a thicket (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return StagKingData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return StagKingData.SPRITE


## THE ANTLER CROWN: no damage while a thorn stands.
func damage_taken_mult(source: String) -> float:
	if crowned():
		game.stat_add("stag_crown_blocked", 1.0)
		return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the crown's thresholds, the Hunt's clock, then his action machine.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_charge_cd -= delta
	_hunt_cd -= delta
	_step_crown()
	_step_hunt()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["charge_windup"]):
				_run = 0.0
				_hit.clear()
				motion_lunge(_dir, MotionData.POWER_CAST)
				game.wild_rules().play_sound("hunt_charge", position, 0.3)
				_set_act(Act.CHARGE)
		Act.CHARGE:
			_tick_timers(delta)
			_step_charge(delta)
		Act.STAGGER:
			_hold(delta)
			if act_time >= float(boss_def["crack_stagger"]):
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)


## Walking: the shared AI at his stride (faster from afar, slower crowned); a
## charge when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	if crowned():
		move_speed *= float(boss_def["crown_speed"])
	super.physics_step(delta)
	if _charge_cd <= 0.0 and dist <= float(boss_def["charge_trigger"]) and stun_timer <= 0.0:
		_charge_cd = float(boss_def["charge_every"])
		var to := pl.position - position
		_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		game.stat_add("boss_atk_rut", 1.0)
		_set_act(Act.WINDUP)


## Standing still during a windup, a stagger or a recovery (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Rut
# =====================================================================================

## The charge runs: every body he crosses is hit once; a tree cracks.
func _step_charge(delta: float) -> void:
	var step := float(boss_def["charge_speed"]) * delta
	if game.arena.is_blocked(position + _dir * (step + radius * 0.6), radius * 0.5):
		_crack(position + _dir * radius)
		return
	velocity = _dir * float(boss_def["charge_speed"])
	position += _dir * step
	_update_facing()
	_run += step
	var ts := game.enemies.damage_mult * hit_mult()  # The time scaling x his buffs.
	var before := _hit.size()
	var n := WildKit.trample(game, position, radius, _hit, float(boss_def["charge_damage_summon"]) * ts * undead_damage_mult,
			float(boss_def["charge_damage"]) * ts, float(boss_def["charge_stun"]), float(boss_def["charge_knock"]), _dir,
			StagKingData.RUT_SOURCE, self, _buf)
	if n > 0:
		game.stat_add("stag_rut_hits", float(n))
		for i in range(before, _hit.size()):
			if _hit[i] is Necromancer:
				game.stat_add("stag_rut_on_you", 1.0)
	if _run >= float(boss_def["charge_len"]):
		position = game.arena.free_point(position, radius)
		_seed(position, int(boss_def["end_seeds"]), 0.0)
		_set_act(Act.RECOVER)


## He cracks the tree at `at`: seeds sprout round it and he staggers.
func _crack(at: Vector2) -> void:
	game.stat_add("stag_rut_cracks", 1.0)
	game.effects.impact(at, radius * 1.4, Palette.WILD_BARK)
	game.shake(5.0)
	Sfx.play("boss_impact", position, 0.4)
	_seed(at, int(boss_def["crack_seeds"]), float(boss_def["crack_ring"]))
	_set_act(Act.STAGGER)


## Plants `n` seeds `ring` px round `at` (one at `at` when ring is 0), each
## growing in crack_grow s (Thickets.plant(), the one planting path).
func _seed(at: Vector2, n: int, ring: float) -> void:
	var th := game.wild_rules().thickets
	for i in n:
		th.plant(at + _dir.rotated(TAU * float(i) / float(maxi(1, n))) * ring, float(boss_def["crack_grow"]), "stag_king")
		game.stat_add("stag_rut_seeds", 1.0)


# =====================================================================================
# The Hunt
# =====================================================================================

## The Hunt's clock and its riders' sweeps (see the header).
func _step_hunt() -> void:
	if _hunt_cd <= 0.0 and act != Act.CHARGE:
		_hunt_cd = float(boss_def["hunt_every"])
		var pl := game.nearest_player(position)
		if pl != null and not pl.dead:
			var to := pl.position - position
			var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
			_add_line(pl.position, dir)
			if hp <= max_hp * float(boss_def["hunt_split"]):
				_add_line(pl.position, dir.orthogonal())
			game.stat_add("boss_atk_hunt", 1.0)
			game.wild_rules().play_sound("hunt_horn", position, 1.0)
			game.enemies.show_banner(String(boss_def["hunt_banner"]))
			queue_redraw()
	var len := float(boss_def["hunt_len"])
	var i := 0
	while i < _lines.size():
		var ln := _lines[i]
		var ride := (game.elapsed - float(ln["t0"])) * float(boss_def["hunt_speed"])
		if ride > len:
			_lines.remove_at(i)
			queue_redraw()
			continue
		if ride >= 0.0:
			_ride(ln, ride)
		i += 1


## A Hunt line through `through` along `dir`: it starts hunt_back px before him.
func _add_line(through: Vector2, dir: Vector2) -> void:
	_lines.append({"from": through - dir * float(boss_def["hunt_back"]), "dir": dir,
		"t0": game.elapsed + float(boss_def["hunt_lead"]), "hit": []})
	game.stat_add("stag_hunt_lines", 1.0)


## The riders of line `ln`, `ride` px along it, trample what they touch.
func _ride(ln: Dictionary, ride: float) -> void:
	var dir: Vector2 = ln["dir"]
	var ts := game.enemies.damage_mult * hit_mult()
	var hit: Array = ln["hit"]
	var before := hit.size()
	var n := 0
	for k in _rider_offsets():
		var at := (ln["from"] as Vector2) + dir * ride + dir.orthogonal() * k
		n += WildKit.trample(game, at, float(boss_def["hunt_radius"]), hit, float(boss_def["hunt_damage_summon"]) * ts * undead_damage_mult,
				float(boss_def["hunt_damage"]) * ts, float(boss_def["hunt_stun"]), float(boss_def["hunt_knock"]), dir,
				StagKingData.HUNT_SOURCE, self, _buf)
	if n > 0:
		game.stat_add("stag_hunt_hits", float(n))
		for j in range(before, hit.size()):
			if hit[j] is Necromancer:
				game.stat_add("stag_hunt_on_you", 1.0)


## The riders' lateral offsets (px) across a line, centred.
func _rider_offsets() -> Array[float]:
	var out: Array[float] = []
	var n := int(boss_def["hunt_riders"])
	for k in n:
		out.append(float(boss_def["hunt_spacing"]) * (float(k) - float(n - 1) * 0.5))
	return out


# =====================================================================================
# The Antler Crown
# =====================================================================================

## True while a thorn of his crown stands.
func crowned() -> bool:
	return _crown_since >= 0.0


## Grows the crown at its thresholds; notices when its last thorn falls.
func _step_crown() -> void:
	if crowned():
		for i in range(_thorns.size() - 1, -1, -1):
			if not (_thorns[i].active and _thorns[i].generation == _thorn_gens[i]):
				_thorns.remove_at(i)
				_thorn_gens.remove_at(i)
		if _thorns.is_empty():
			game.stat_add("stag_crown_broken", 1.0)
			game.stat_add("stag_crown_time", game.elapsed - _crown_since)
			_crown_since = -1.0
			game.wild_rules().play_sound("crown_breaks", position, 0.5)
			game.enemies.show_banner(String(boss_def["crown_broken_banner"]))
			queue_redraw()
		return
	var at: Array = boss_def["crown_at"]
	if _crowns < at.size() and hp <= max_hp * float(at[_crowns]):
		_crowns += 1
		_grow_crown()


## THE ANTLER CROWN grows: crown_thorns thorns on a ring round him.
func _grow_crown() -> void:
	var n := int(boss_def["crown_thorns"])
	var r := float(boss_def["crown_radius"])
	for i in n:
		var off := Vector2.from_angle(TAU * float(i) / float(n)) * r
		var t := game.enemies.spawn_at(GreenwoodEnemyData.ANTLER_THICKET, position + off, false)
		if t == null:
			continue
		if t.kit is AntlerThicketKit:
			(t.kit as AntlerThicketKit).bind(self, off)
		t.position = position + off
		_thorns.append(t)
		_thorn_gens.append(t.generation)
		game.stat_add("stag_crown_thorns", 1.0)
	if _thorns.is_empty():
		return
	_crown_since = game.elapsed
	game.stat_add("boss_atk_crown", 1.0)
	game.wild_rules().play_sound("crown_grows", position, 0.5)
	game.enemies.show_banner(String(boss_def["crown_banner"]))
	queue_redraw()


## A fire at `at` reaching `r` px (Thickets.burn_at(), through ring_burns)
## burns every thorn of his crown it touches. Returns the thorns burnt.
func crown_burn(at: Vector2, r: float) -> int:
	var n := 0
	for i in _thorns.size():
		var t := _thorns[i]
		if t.active and t.generation == _thorn_gens[i] and t.position.distance_to(at) <= r + t.radius:
			game.combat.damage_enemy(t, t.hp + t.max_hp, "wild_fire")
			n += 1
	if n > 0:
		game.stat_add("stag_crown_burnt", float(n))
	return n


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue); his crown withers with him (AntlerThicketKit).
func _on_defeated() -> void:
	var pos := position
	if game.wild != null:
		game.wild.thickets.ring_burns.erase(crown_burn)
	_lines.clear()
	game.effects.ring(pos, 240.0, Palette.WILD_MOSS, 1.0)
	game.effects.ring(pos, 140.0, Palette.WILD_FROST, 0.8)
	Juice.fx.burst(pos, Palette.WILD_MOSS, Palette.WILD_FROST, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + StagKingData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = StagKingData.LATE_ANNOUNCE if game.countdown_finished() else StagKingData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.WILD_MOSS)
	game.stats["stag_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the Rut's line while he
## lowers his antlers, out of the Hunt's path while its riders come.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if act == Act.WINDUP or act == Act.CHARGE:
		push += WildKit.line_push(position, _dir, float(boss_def["charge_len"]), radius, p) * 2.0
	var half := float(boss_def["hunt_spacing"]) * float(int(boss_def["hunt_riders"])) * 0.5 + float(boss_def["hunt_radius"])
	for ln: Dictionary in _lines:
		push += WildKit.line_push(ln["from"], ln["dir"], float(boss_def["hunt_len"]), half, p) * 2.0
	return push


## Body layer on `ci`: his still / walk frame (pose 1, the horn raised, while a
## Hunt rides); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	if not SpriteBank.draw_pose(ci, StagKingData.SPRITE, 1 if not _lines.is_empty() else 0, Vector2.ZERO, flash > 0.0):
		var f := flash > 0.0
		SpriteBank.draw_disc(ci, Vector2.ZERO, radius, Glyphs._c(Palette.WILD_INK, f))
		SpriteBank.draw_disc(ci, Vector2.ZERO, radius - 2.0, Glyphs._c(Palette.WILD_MOSS_DARK, f))
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.9), radius * 0.45, Glyphs._c(Palette.WILD_BARK, f))  # The stag's head.
		for s: float in [-1.0, 1.0]:
			ci.draw_rect(Rect2(Vector2(s * radius * 0.35 - 1.5, -radius * 1.9), Vector2(3.0, radius * 0.8)), Glyphs._c(Palette.WILD_BONE, f))  # An antler.
			ci.draw_rect(Rect2(Vector2(s * radius * 0.35 + (s * 4.0 if s > 0.0 else -8.0), -radius * 1.7), Vector2(6.0, 3.0)), Glyphs._c(Palette.WILD_BONE, f))  # A tine.


## Overlay layer on `ci`: the Rut's line while he lowers his antlers, the
## crown's thorny glow and the Hunt's paths and riders. Visual only: rects,
## disc textures and the rider sprite, in world axes.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.WINDUP:
		WildKit.draw_line_marks(ci, Vector2.ZERO, _dir, radius, float(boss_def["charge_len"]), clampf(act_time / maxf(0.01, float(boss_def["charge_windup"])), 0.0, 1.0))
	if crowned():
		SpriteBank.draw_disc(ci, Vector2.ZERO, float(boss_def["crown_radius"]) + 10.0, Color(Palette.WILD_BARK, 0.18))
	var len := float(boss_def["hunt_len"])
	for ln: Dictionary in _lines:
		var dir: Vector2 = ln["dir"]
		var from: Vector2 = (ln["from"] as Vector2) - position
		var ride := (game.elapsed - float(ln["t0"])) * float(boss_def["hunt_speed"])
		for k in _rider_offsets():
			var o := from + dir.orthogonal() * k
			if ride < 0.0:
				WildKit.draw_line_marks(ci, o, dir, 0.0, len, clampf(1.0 + ride / maxf(1.0, float(boss_def["hunt_lead"]) * float(boss_def["hunt_speed"])), 0.0, 1.0))
			else:
				var at := o + dir * ride
				if not SpriteBank.draw(ci, StagKingData.RIDER_SPRITE, at, false, StagKingData.RIDER_TINT):
					SpriteBank.draw_disc(ci, at, float(boss_def["hunt_radius"]), StagKingData.RIDER_TINT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Redraws the overlay every tick while a Hunt rides (its riders move).
func _process(_delta: float) -> void:
	if not _lines.is_empty() and active:
		queue_redraw()


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var kt := float(st.get("stag_kill_time", -1.0))
	return "the Rut: %d (hit %d, you %d; trees cracked %d, seeds %d) | the Hunt: %d (lines %d, hit %d, you %d) | the Antler Crown: %d (thorns %d, burnt %d, broken %d in %d s, hits blocked %d) | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_rut", 0.0)), int(st.get("stag_rut_hits", 0.0)), int(st.get("stag_rut_on_you", 0.0)),
		int(st.get("stag_rut_cracks", 0.0)), int(st.get("stag_rut_seeds", 0.0)),
		int(st.get("boss_atk_hunt", 0.0)), int(st.get("stag_hunt_lines", 0.0)), int(st.get("stag_hunt_hits", 0.0)), int(st.get("stag_hunt_on_you", 0.0)),
		int(st.get("boss_atk_crown", 0.0)), int(st.get("stag_crown_thorns", 0.0)), int(st.get("stag_crown_burnt", 0.0)),
		int(st.get("stag_crown_broken", 0.0)), int(st.get("stag_crown_time", 0.0)), int(st.get("stag_crown_blocked", 0.0)),
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + StagKingData.RUT_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + StagKingData.HUNT_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + StagKingData.RUT_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + StagKingData.HUNT_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
