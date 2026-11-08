## BossAnubis — ANUBIS, OPENER OF THE WAY, the boss of the Necropolis of Sand
## (temporary Act XII, the Necropolis Dynasty; GDD §15.0 "Anubis, Opener of
## the Way (Act XII phase 2)"; owner-approved proposal: "the Procession: he
## leads a funeral march of mummies; every jar must be broken to end Rebirth.
## The Embalmer: he wraps the fallen on the whole map; the cartouche timer is
## 3 s while he does. The Jackal: he drops the wrapped pose and duels: fast,
## with afterimage lunges"). Loaded by name for the boss id "anubis"
## (EnemyDirector.DYNASTY_BOSS_DIR + "boss_anubis.gd"); he arrives at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat him
## like any enemy. A male jackal-headed god. Every number is AnubisData.BOSS's;
## the phases and their rules are documented in AnubisData. Every effect goes
## through the Dynasty's one paths: his jars through Rebirth.place_jar() (by
## NecropolisDirector.place_jar_near(), beside a tomb when one stands near),
## the Procession through Rebirth.set_procession(), the Embalmer's haste
## through DynastyRules.embalm_all (read by embalm_rate(), THE haste read), the
## marchers and wrapped dead through EnemyDirector.spawn_at() (they return by
## Rebirth like any mummy), the lunge strikes through damage_unit() /
## damage_player(). The shared rules are created on first use
## (Game.dynasty_rules()), so --boss=anubis works on any stage (his jars then
## stand where they rise; No Jars Left is the Necropolis's). Killing him drops
## a big XP burst and the boss chest; slaying him unlocks Linen Bind and
## Natron Salts (UnlockData, boss "anubis"); his fall shows a short ending
## text only. Attack poses (BossPoseData, when the art has them): pose 1 while
## he wraps or crouches. Determinism: the seeded gameplay RNG is never used
## (fixed angles turned by counters and his think slot). Stats:
## boss_atk_<special>, anubis_jars, anubis_marches, anubis_marchers,
## anubis_wraps, anubis_wrapped, anubis_lunges, anubis_lunge_hits,
## anubis_lunge_on_you, anubis_phase2_at, anubis_phase3_at, anubis_kill_time.
class_name BossAnubis
extends Boss

## His phases.
enum Form { PROCESSION = 1, EMBALMER = 2, JACKAL = 3 }
## His action within a phase.
enum Act { WALK, WRAP, RECOVER, CROUCH, DASH }

## px the autotest bot keeps beyond the dash line (autotest hint only).
const DANGER_MARGIN: float = 30.0  # TUNING (not in GDD) autotest hint only

## Current phase.
var form: Form = Form.PROCESSION
## Current action.
var act: Act = Act.WALK
## Seconds in the current action.
var act_time: float = 0.0
## Seconds until the next column of the march (the Procession).
var _march_cd: float = 0.0
## Seconds until the next wrapping (the Embalmer).
var _wrap_cd: float = INF
## Seconds until the next lunge (the Jackal).
var _lunge_cd: float = INF
## Columns / wrappings / lunges so far (turn the next one's angles; no RNG).
var _count: int = 0
## Where the current dash starts and ends (world px).
var _dash_from: Vector2 = Vector2.ZERO
## Where the current dash ends (world px).
var _dash_to: Vector2 = Vector2.ZERO
## Summons already struck by the current dash.
var _struck: Array = []
## True once the current dash struck the necromancer.
var _struck_player: bool = false
## Afterimages: [world position, game time it was left] (drawn only).
var _ghosts: Array = []
## Afterimages the current dash has left so far.
var _ghost_n: int = 0
## His walking speed (px/s, before the Jackal's multiplier).
var _base_speed: float = 44.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Anubis at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = AnubisData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	form = Form.PROCESSION
	act = Act.WALK
	act_time = 0.0
	_march_cd = float(boss_def["march_first"])
	_wrap_cd = INF
	_lunge_cd = INF
	_count = 0
	_ghosts.clear()
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	var dy := p_game.dynasty_rules()  # The shared rules exist wherever he fights.
	dy.rebirth.set_procession(true)
	_raise_jars()
	game.enemies.boss_defeated.connect(_on_defeated)
	game.stat_add("boss_atk_procession", 1.0)
	dy.play_sound("jar_rise", position)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return AnubisData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Any removal ends his rules (the Procession, the haste) and leaves him
## solid (the pool reuses the node).
func deactivate() -> void:
	_end_rules()
	phases_obstacles = false
	super.deactivate()


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: his phase machine (see the header and AnubisData).
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_march_cd -= delta
	_wrap_cd -= delta
	_lunge_cd -= delta
	if form == Form.PROCESSION and hp <= max_hp * float(boss_def["phase2_hp"]):
		_enter_embalmer()
	if form == Form.EMBALMER and act == Act.WALK and hp <= max_hp * float(boss_def["phase3_hp"]):
		_enter_jackal()
	if form == Form.PROCESSION and _march_cd <= 0.0:
		_march()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.WRAP:
			_hold(delta)
			if act_time >= float(boss_def["wrap_windup"]):
				_wrap()
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)
		Act.CROUCH:
			_hold(delta)
			if act_time >= float(boss_def["lunge_windup"]):
				_dash_from = position
				_struck.clear()
				_struck_player = false
				_ghost_n = 0
				phases_obstacles = true
				_set_act(Act.DASH)
		Act.DASH:
			_step_dash(delta)
	if not _ghosts.is_empty():
		_age_ghosts()


## Walking: the shared AI (his crook in reach) at his speed, faster from afar;
## a wrapping (the Embalmer) or a lunge (the Jackal) starts when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var spd := _base_speed * (float(boss_def["jackal_speed_mult"]) if form == Form.JACKAL else 1.0)
	var dist := position.distance_to(pl.position)
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if form == Form.EMBALMER and _wrap_cd <= 0.0:
		_wrap_cd = float(boss_def["wrap_every"])
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_act(Act.WRAP)
	elif form == Form.JACKAL and _lunge_cd <= 0.0 and dist >= float(boss_def["lunge_min"]) \
			and not game.ultimates.player_untargetable() and stun_timer <= 0.0:
		_crouch(pl)


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
# The Procession: the jars and the march
# =====================================================================================

## The Procession's jars: procession_jars of them round the nearest
## necromancer at even angles (turned by his think slot), each beside a tomb
## when one stands near (NecropolisDirector's one jar placer; plain
## Rebirth.place_jar() off the Necropolis).
func _raise_jars() -> void:
	var pl := game.nearest_player(position)
	var n := maxi(1, int(boss_def["procession_jars"]))
	var base := float(think_slot) * 0.37
	var made := 0
	for k in n:
		var a := base + TAU * float(k) / float(n)
		var dist := lerpf(float(boss_def["procession_jar_min"]), float(boss_def["procession_jar_max"]), float(k % 2))
		var at := pl.position + Vector2.from_angle(a) * dist
		if NecropolisDirector.place_jar_near(game, at, "procession") != null:
			made += 1
	game.stat_add("anubis_jars", float(made))


## A column of the march: the march groups walk in from the spawn ring behind
## him (the side away from the necromancer), two abreast (under the hard cap).
func _march() -> void:
	_march_cd = float(boss_def["march_every"])
	var pl := game.nearest_player(position)
	var away := (position - pl.position)
	var a := away.angle() if away.length() > 1.0 else float(_count) * 1.3
	var head := game.enemies.ring_point(a)
	var fwd := (pl.position - head).normalized()
	var side := fwd.orthogonal()
	var k := 0
	for grp: Dictionary in boss_def["march"]:
		for j in int(grp.get("count", 0)):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			var at := head + side * (float(k % 2) - 0.5) * 24.0 - fwd * 22.0 * float(k / 2)
			if game.enemies.spawn_at(String(grp["kind"]), at, false) != null:
				game.stat_add("anubis_marchers", 1.0)
			k += 1
	if _count == 0:
		game.enemies.show_banner(String(boss_def["phase1_banner"]))  # After his arrival banner.
	_count += 1
	game.stat_add("boss_atk_march", 1.0)
	game.stat_add("anubis_marches", 1.0)
	game.dynasty_rules().play_sound("rebirth", head, 1.0)


# =====================================================================================
# The Embalmer: the map-wide haste and the wrapped dead
# =====================================================================================

## The Embalmer begins: the Procession ends (Rebirth's normal jar radius
## again), every cartouche on the map runs at the embalm_timer haste.
func _enter_embalmer() -> void:
	form = Form.EMBALMER
	var dy := game.dynasty_rules()
	dy.rebirth.set_procession(false)
	dy.embalm_all = float(dy.rebirth.cfg["duration"]) / maxf(float(boss_def["embalm_timer"]), 0.1)
	_wrap_cd = float(boss_def["wrap_first"])
	game.stat_add("anubis_phase2_at", game.elapsed)
	game.stat_add("boss_atk_embalmer", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.ring(position, radius * 4.0, Palette.DYN_LINEN, 0.8)
	game.shake(5.0)
	dy.play_sound("cartouche", position)
	if act != Act.WALK:
		_set_act(Act.RECOVER)


## He wraps the fallen: wrap_count wrapped dead rise out of the sand round the
## nearest necromancer (wrap_kinds in turn, at even angles turned by the
## count; under the hard cap).
func _wrap() -> void:
	var pl := game.nearest_player(position)
	var n := maxi(1, int(boss_def["wrap_count"]))
	var kinds: Array = boss_def["wrap_kinds"]
	var base := float(_count) * 0.8 + float(think_slot) * 0.21
	var made := 0
	for k in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var a := base + TAU * float(k) / float(n)
		var dist := lerpf(float(boss_def["wrap_min"]), float(boss_def["wrap_max"]), float(k % 2))
		var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, 10.0)
		if game.enemies.spawn_at(String(kinds[(_count + k) % kinds.size()]), at, false) != null:
			game.effects.pop(at, Palette.DYN_LINEN, 14.0)
			made += 1
	_count += 1
	game.stat_add("boss_atk_wrap", 1.0)
	game.stat_add("anubis_wraps", 1.0)
	game.stat_add("anubis_wrapped", float(made))
	game.dynasty_rules().play_sound("rebirth", position, 0.5)


# =====================================================================================
# The Jackal: the duel and the afterimage lunges
# =====================================================================================

## The Jackal begins: the haste ends; he drops the wrapped pose and duels.
func _enter_jackal() -> void:
	form = Form.JACKAL
	_end_rules()
	_lunge_cd = float(boss_def["lunge_first"])
	game.stat_add("anubis_phase3_at", game.elapsed)
	game.stat_add("boss_atk_jackal", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.DYN_BRONZE_LIGHT)
	game.shake(7.0)
	Sfx.play("boss_telegraph", position, 0.6)


## The crouch: he aims a dash at the necromancer (led on a moving target), a
## bronze line telegraph to where it ends.
func _crouch(pl: Necromancer) -> void:
	_lunge_cd = float(boss_def["lunge_every"])
	var reach := float(boss_def["lunge_reach"])
	var aim := pl.position + pl.velocity * (reach / maxf(float(boss_def["lunge_speed"]), 1.0)) * float(boss_def["lunge_lead"])
	var to := aim - position
	var dash_len := minf(to.length() + radius, reach)
	_dash_to = game.arena.free_point(position + to.normalized() * dash_len, radius) if to.length() > 1.0 else position
	game.effects.telegraph_line(position, _dash_to, float(boss_def["lunge_width"]) * 2.0, float(boss_def["lunge_windup"]), self)
	game.stat_add("boss_atk_lunge", 1.0)
	game.stat_add("anubis_lunges", 1.0)
	motion_lunge((_dash_to - position).normalized(), MotionData.POWER_CAST)
	_set_act(Act.CROUCH)


## The dash: he moves along the line at lunge_speed (no body-block stops
## him), leaving afterimages; every summon he passes within lunge_width px is
## struck once, the necromancer once if the dash reaches him.
func _step_dash(delta: float) -> void:
	_tick_timers(delta)
	var to := _dash_to - position
	var step := float(boss_def["lunge_speed"]) * delta
	var prev := position
	if to.length() <= step:
		position = _dash_to
	else:
		position += to.normalized() * step
	velocity = Vector2.ZERO
	_update_facing()
	var n := maxi(1, int(boss_def["afterimages"]))
	var gap := maxf(_dash_from.distance_to(_dash_to), 1.0) / float(n + 1)  # px between two afterimages.
	var dir := (_dash_to - _dash_from).normalized()
	while _ghost_n < n and _dash_from.distance_to(position) >= gap * float(_ghost_n + 1):
		_ghost_n += 1
		_ghosts.append([_dash_from + dir * gap * float(_ghost_n), game.elapsed])
	_strike_along(prev, position)
	if position == _dash_to or act_time > 1.5:
		phases_obstacles = false
		position = game.arena.free_point(position, radius)
		_set_act(Act.RECOVER)


## Strikes the bodies the dash passed between `a` and `b`.
func _strike_along(a: Vector2, b: Vector2) -> void:
	var w := float(boss_def["lunge_width"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var mid := (a + b) * 0.5
	game.ally_grid.query(mid, a.distance_to(b) * 0.5 + w + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or _struck.has(u):
			continue
		var q := Geometry2D.get_closest_point_to_segment(u.position, a, b)
		if q.distance_to(u.position) > w + u.radius:
			continue
		_struck.append(u)
		game.combat.damage_unit(u, float(boss_def["lunge_damage_summon"]) * mult * undead_damage_mult, AnubisData.LUNGE_SOURCE, self)
		game.stat_add("anubis_lunge_hits", 1.0)
	if _struck_player:
		return
	for pl in game.all_players:
		if pl.dead:
			continue
		var q2 := Geometry2D.get_closest_point_to_segment(pl.position, a, b)
		if q2.distance_to(pl.position) <= w + pl.radius:
			_struck_player = true
			game.combat.damage_player(float(boss_def["lunge_damage"]) * mult, AnubisData.LUNGE_SOURCE, pl, self)
			game.stat_add("anubis_lunge_on_you", 1.0)
			game.effects.slash(pl.position, b - a, Palette.DYN_BRONZE_LIGHT, radius * 1.4)
			break


## Drops the afterimages that faded.
func _age_ghosts() -> void:
	var fade := float(boss_def["afterimage_fade"])
	var i := _ghosts.size() - 1
	while i >= 0:
		if game.elapsed - float(_ghosts[i][1]) > fade:
			_ghosts.remove_at(i)
		i -= 1
	queue_redraw()


## Ends his rules on the field: the Procession and the Embalmer's haste.
func _end_rules() -> void:
	if game != null and game.dynasty != null:
		game.dynasty.rebirth.set_procession(false)
		game.dynasty.embalm_all = 1.0


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): his rules
## end; the short ending text (no epilogue).
func _on_defeated() -> void:
	_end_rules()
	var pos := position
	game.effects.ring(pos, 240.0, Palette.DYN_BRONZE_LIGHT, 1.0)
	game.effects.ring(pos, 140.0, Palette.DYN_LAPIS, 0.8)
	Juice.fx.burst(pos, Palette.DYN_BRONZE_LIGHT, Palette.DYN_NIGHT, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + AnubisData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = AnubisData.LATE_ANNOUNCE if game.countdown_finished() else AnubisData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.DYN_BRONZE_LIGHT)
	game.stats["anubis_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: off the dash line while he crouches
## and dashes.
func danger_push(p: Vector2) -> Vector2:
	if act != Act.CROUCH and act != Act.DASH:
		return Vector2.ZERO
	var a := position if act == Act.CROUCH else _dash_from
	var q := Geometry2D.get_closest_point_to_segment(p, a, _dash_to)
	var reach := float(boss_def["lunge_width"]) + DANGER_MARGIN
	var off := p - q
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	var n := off / dist if dist > 0.01 else (_dash_to - a).normalized().orthogonal()
	return n * (1.0 - dist / reach) * 3.0


## Body layer on `ci`: his afterimages (the Jackal), a linen glow while he
## embalms, then his still / walk frame (pose 1 while he wraps or crouches).
func _draw_body(ci: CanvasItem) -> void:
	var fade := float(boss_def["afterimage_fade"])
	for gh: Array in _ghosts:
		var off: Vector2 = gh[0] - position
		var k := 1.0 - clampf((game.elapsed - float(gh[1])) / maxf(fade, 0.01), 0.0, 1.0)
		var local := Vector2(off.x * scale.x, off.y)  # The node is mirrored by scale.x.
		if not SpriteBank.draw(ci, AnubisData.SPRITE, local, false, Color(0.55, 0.62, 1.0, 0.45 * k)):
			SpriteBank.draw_disc(ci, local, radius, Color(Palette.DYN_NIGHT, 0.4 * k))
	if form == Form.EMBALMER:
		SpriteBank.draw_disc(ci, Vector2(0.0, radius * 0.6), radius * 1.6, Color(Palette.DYN_LINEN, 0.18))
	var pose := 1 if act == Act.WRAP or act == Act.CROUCH else 0
	if not SpriteBank.draw_pose(ci, AnubisData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		_glyph(ci)


## His code shape without the art: a night-blue jackal god with a bronze collar.
func _glyph(ci: CanvasItem) -> void:
	var r := radius
	var fl := flash > 0.0
	SpriteBank.draw_disc(ci, Vector2(0.0, r * 0.3), r * 1.1, Glyphs._c(Palette.DYN_INK, fl))
	SpriteBank.draw_disc(ci, Vector2(0.0, r * 0.3), r, Glyphs._c(Palette.DYN_NIGHT, fl))
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.8), r * 0.5, Glyphs._c(Palette.DYN_NIGHT_DARK, fl))  # The jackal head.
	ci.draw_rect(Rect2(Vector2(-r * 0.45, -r * 1.6), Vector2(3.0, r * 0.6)), Glyphs._c(Palette.DYN_NIGHT_DARK, fl))  # Ears.
	ci.draw_rect(Rect2(Vector2(r * 0.3, -r * 1.6), Vector2(3.0, r * 0.6)), Glyphs._c(Palette.DYN_NIGHT_DARK, fl))
	ci.draw_rect(Rect2(Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, 3.0)), Glyphs._c(Palette.DYN_BRONZE, fl))  # The collar.


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("anubis_phase2_at", -1.0))
	var p3 := float(st.get("anubis_phase3_at", -1.0))
	var kt := float(st.get("anubis_kill_time", -1.0))
	return "the Procession: jars %d, columns %d (%d marchers) | the Embalmer %s: wrappings %d (%d wrapped dead) | the Jackal %s: lunges %d (summons struck %d, on you %d) | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("anubis_jars", 0.0)), int(st.get("anubis_marches", 0.0)), int(st.get("anubis_marchers", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("anubis_wraps", 0.0)), int(st.get("anubis_wrapped", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("anubis_lunges", 0.0)),
		int(st.get("anubis_lunge_hits", 0.0)), int(st.get("anubis_lunge_on_you", 0.0)),
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + AnubisData.LUNGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + AnubisData.LUNGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
