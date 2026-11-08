## BossCrow — CAPTAIN EZEKIEL CROW, THE GULL KING, the boss of the Smuggler's
## Cutter (Act X, the Black Tide; GDD §15.0 "Captain Crow (Act X)";
## owner-approved proposal: "Broadside ... The Duel ... Fire Ship"). Loaded by
## name for the boss id "crow" (EnemyDirector.CORSAIR_BOSS_DIR +
## "boss_crow.gd"); he arrives at 17:00 (3:00 left). Extends Boss, so summons,
## spells and the spatial hash treat him like any enemy. A lean MALE pirate
## captain. Every number is CrowData.BOSS's; the phases are documented in
## CrowData:
##   * BROADSIDE: his sloop (CutterEnemyData "crow_sloop", a boat structure in
##     the water) lies alongside the rail; he commands from its deck, out of
##     reach (Enemy.untargetable / ethereal, the Hive Mother's path), drawn on
##     the sloop. Rolling broadsides of three cannon lines across the deck
##     (both armies; enemies knocked toward the far rail, where they drown) and
##     his crew boarding double through THE spawn route
##     (CorsairRules.route_spawn()). Sinking the sloop ends it early.
##   * THE DUEL: he swings aboard on a landing circle (his LEAP) and fights with
##     the shared melee AI (the cutlass), his pistol (an ordinary hostile shot,
##     ProjectileManager.fire_hostile()) and more leaps over the ring.
##   * THE FIRE SHIP: below fire_hp his sloop burns and rams the hull
##     (CutterDirector.fire_ship(): the hull stagger, then short fire patches
##     through THE Hell Pits ground path until he falls; stop_fire()).
## Every shove of the army is an enemy effect through the existing paths
## (TerrainSlow.push_summon() x Sea Legs, damage_unit(), damage_player()); the
## deck clamps him like any deck body (a boss never drowns). The shared rules
## are created on first use (Game.corsair_rules()), so --boss=crow works on any
## stage: there the Broadside has no sloop or deck (lines centred on the
## necromancer, a timed phase) and the Fire Ship lights no planks.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Chain Shot and Bosun's Whistle (UnlockData, boss "crow"); his fall shows a
## short ending text only (no epilogue, owner).
## Determinism: no RNG (the lines and leaps follow the necromancer, fixed
## steps). Stats: boss_atk_<special>, crow_broadsides, crow_lines,
## crow_line_hits_summons, crow_line_hits_you, crow_line_enemy_hits,
## crow_crew_sent, crow_sloop_sunk, crow_leaps, crow_leap_hits, crow_pistol,
## crow_duel_at, crow_fire_at, crow_kill_time.
class_name BossCrow
extends Boss

## His phases.
enum Form { BROADSIDE = 1, DUEL = 2, FIRE = 3 }
## His action within a phase.
enum Act { COMMAND, LEAP, RECOVER, WALK }

## px the autotest bot keeps beyond a line's or a landing's edge (autotest hint only).
const DANGER_MARGIN: float = 22.0  # TUNING (not in GDD) autotest hint only

## Current phase.
var form: Form = Form.BROADSIDE
## Current action.
var act: Act = Act.COMMAND
## Seconds in the current action.
var act_time: float = 0.0
## Game time (s) he arrived.
var _spawn_time: float = 0.0
## Seconds until the next broadside.
var _broadside_cd: float = 0.0
## Seconds until he next sends his crew.
var _crew_cd: float = 0.0
## Crewmen sent so far (picks the next kind in turn).
var _crew_n: int = 0
## Seconds until his next leap in the Duel.
var _leap_cd: float = 0.0
## Seconds until his next pistol shot.
var _pistol_cd: float = 0.0
## Live cannon lines: each [x (world px), fire time (game s), shown from (game s)].
var _lines: Array = []
## The rail he came alongside (world px) and its outward normal.
var _rail: Vector2 = Vector2.ZERO
## Outward normal of his rail (toward the sea).
var _rail_n: Vector2 = Vector2.UP
## Half the beam across which the lines run (the deck's, else 180 px).
var _half_beam: float = 180.0
## Centre y of the lines' run (the deck's, else his arrival y).
var _mid_y: float = 0.0
## His sloop (null when sunk / cast off; generation-checked).
var _sloop: Enemy = null
## Pool generation of `_sloop`.
var _sloop_gen: int = 0
## Where a leap starts and lands (world px).
var _leap_from: Vector2 = Vector2.ZERO
## Where the current leap lands (world px).
var _leap_to: Vector2 = Vector2.ZERO
## His walking speed (px/s).
var _base_speed: float = 66.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Captain Crow: his sloop alongside the rail farther from the
## necromancer, he on its deck (out of reach).
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = CrowData.BOSS
	var pl := p_game.player.position
	if p_game.deck != null:
		var side := -1 if pl.y >= p_game.deck.center.y else 1
		var x := clampf(pl.x, -p_game.deck.straight_rail_length() * 0.35, p_game.deck.straight_rail_length() * 0.35)
		_rail = p_game.deck.rail_point(x, side)
		_rail_n = Vector2(0.0, float(side))
		_half_beam = p_game.deck.half_beam
		_mid_y = p_game.deck.center.y
		pos = _rail - _rail_n * (float(boss_def["radius"]) + 4.0)
	else:
		_rail = pos
		_rail_n = Vector2.UP if pos.y < pl.y else Vector2.DOWN
		_half_beam = 180.0
		_mid_y = pl.y
	activate(p_game, "boss", boss_def, pos, hp_mult, false, slot)
	is_boss = true
	z_index = 1
	form = Form.BROADSIDE
	act = Act.COMMAND
	act_time = 0.0
	_spawn_time = p_game.elapsed
	_broadside_cd = float(boss_def["broadside_first"])
	_crew_cd = 1.0
	_crew_n = 0
	_lines.clear()
	_base_speed = move_speed
	untargetable = true  # On his sloop: out of reach (the Hive Mother's path).
	ethereal = true
	phases_obstacles = true
	_sloop = null
	var r := p_game.corsair_rules()  # The shared rules exist wherever he fights.
	if p_game.deck != null:
		_sloop = p_game.enemies.spawn_routed(CutterEnemyData.CROW_SLOOP, _rail, hp_mult, false)
		var row := p_game.enemies.enemy_def(CutterEnemyData.CROW_SLOOP)
		_sloop.position = _rail + _rail_n * float(row["radius"]) * 0.6  # In the water, its hull over the rail line.
		_sloop_gen = _sloop.generation
		_sloop.is_objective = true
	r.play_sound("hook_bite", _rail)
	game.enemies.boss_defeated.connect(_on_defeated)
	game.stat_add("boss_atk_broadside", 0.0)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return CrowData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Any removal leaves him solid and grounded (the pool reuses the node).
func deactivate() -> void:
	untargetable = false
	ethereal = false
	phases_obstacles = false
	flies = false
	super.deactivate()


## Out of reach on his sloop and in the air.
func damage_taken_mult(source: String) -> float:
	if form == Form.BROADSIDE or act == Act.LEAP:
		return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: his phase machine (see the header and CrowData).
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_step_lines()
	match form:
		Form.BROADSIDE:
			_step_broadside(delta)
		_:
			if form == Form.DUEL and hp <= max_hp * float(boss_def["fire_hp"]):
				_enter_fire()
			_step_duel(delta)


## The Broadside: he stands on his sloop; broadsides and crew on their clocks.
func _step_broadside(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	if game.deck != null:
		position = _rail - _rail_n * (radius + 4.0)
	_broadside_cd -= delta
	_crew_cd -= delta
	if _broadside_cd <= 0.0:
		_broadside_cd = float(boss_def["broadside_every"])
		_broadside()
	if _crew_cd <= 0.0:
		_crew_cd = float(boss_def["crew_every"])
		_send_crew()
	var sunk := game.deck != null and not _alive(_sloop, _sloop_gen)
	if sunk:
		game.stat_add("crow_sloop_sunk", 1.0)
	if sunk or game.elapsed - _spawn_time >= float(boss_def["broadside_time"]):
		_swing_aboard()


## A rolling broadside: three lines round the nearest necromancer's x.
func _broadside() -> void:
	var pl := game.nearest_player(position)
	var n := maxi(1, int(boss_def["lines"]))
	var gap := float(boss_def["line_gap"])
	var now := game.elapsed
	for k in n:
		var x := pl.position.x + (float(k) - float(n - 1) * 0.5) * gap
		if game.deck != null:
			var lim := game.deck.half_length - 40.0
			x = clampf(x, game.deck.center.x - lim, game.deck.center.x + lim)
		_lines.append([x, now + float(boss_def["line_telegraph"]) + float(k) * float(boss_def["line_stagger"]), now])
	game.stat_add("crow_broadsides", 1.0)
	game.stat_add("boss_atk_broadside", 1.0)
	game.corsair_rules().play_sound("cannon_fire", _rail, 0.3)
	queue_redraw()


## Fires every line whose telegraph ran out.
func _step_lines() -> void:
	if _lines.is_empty():
		return
	var i := 0
	while i < _lines.size():
		var ln: Array = _lines[i]
		if game.elapsed >= float(ln[1]):
			_fire_line(float(ln[0]))
			_lines.remove_at(i)
			continue
		i += 1
	queue_redraw()


## One cannon line lands across the deck at `x`: summons, necromancers and deck
## enemies in the band are hit; enemies are knocked toward the far rail.
func _fire_line(x: float) -> void:
	var half := float(boss_def["line_half"])
	var dm := game.enemies.damage_mult * hit_mult()
	var y0 := _mid_y - _half_beam - 20.0
	var y1 := _mid_y + _half_beam + 20.0
	var mid := Vector2(x, _mid_y)
	game.ally_grid.query(mid, _half_beam + 40.0, _buf)
	var hs := 0
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
			continue
		if absf(u.position.x - x) > half + u.radius or u.position.y < y0 or u.position.y > y1:
			continue
		game.combat.damage_unit(u, float(boss_def["line_damage_summon"]) * dm, CrowData.LINE_SOURCE, self)
		hs += 1
	for pl in game.all_players:
		if not pl.dead and absf(pl.position.x - x) <= half + pl.radius and pl.position.y >= y0 and pl.position.y <= y1:
			game.combat.damage_player(float(boss_def["line_damage_player"]) * dm, CrowData.LINE_SOURCE, pl, self)
			game.stat_add("crow_line_hits_you", 1.0)
	var v := sqrt(2.0 * EnemyData.KNOCKBACK_DECAY * float(boss_def["line_push"]))  # px/s that carries an enemy line_push px.
	var hits: Array[Enemy] = []
	game.enemy_grid.query(mid, _half_beam + 40.0, _buf)
	for e: Enemy in _buf:
		if not e.active or e == self or e.is_boss or e.is_miniboss or e.is_structure or CorsairKit.is_in_water(e):
			continue
		if absf(e.position.x - x) <= half + e.radius and e.position.y >= y0 and e.position.y <= y1:
			hits.append(e)
	var hp_scale := game.enemies.hp_mult
	for e in hits:
		if not e.active:
			continue
		e.knockback += -_rail_n * v / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, float(boss_def["line_damage_enemy"]) * hp_scale, CrowData.LINE_SOURCE)
	game.stat_add("crow_lines", 1.0)
	game.stat_add("crow_line_hits_summons", float(hs))
	game.stat_add("crow_line_enemy_hits", float(hits.size()))
	game.effects.impact(Vector2(x, _mid_y), 40.0, Palette.CORSAIR_LANTERN)
	game.shake(3.0)
	game.corsair_rules().play_sound("cannon_hit", Vector2(x, _mid_y), 0.1)


## His crew boards double: crew_count crewmen by the one spawn route.
func _send_crew() -> void:
	var kinds: Array = boss_def["crew_kinds"]
	var r := game.corsair_rules()
	for k in int(boss_def["crew_count"]):
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var kind := String(kinds[_crew_n % kinds.size()])
		_crew_n += 1
		if r.routes():
			r.route_spawn(kind, game.enemies.hp_mult, false, 1.0, false, false)
		else:
			game.enemies.spawn_at(kind, game.enemies.ring_point(float(_crew_n) * 1.7), false)
		game.stat_add("crow_crew_sent", 1.0)
	game.stat_add("boss_atk_crew", 1.0)


# =====================================================================================
# The Duel and the Fire Ship
# =====================================================================================

## He swings aboard: out of the Broadside, the sloop casts off, the first leap.
func _swing_aboard() -> void:
	form = Form.DUEL
	game.stat_add("crow_duel_at", game.elapsed)
	game.stat_add("boss_atk_swing_aboard", 1.0)
	game.enemies.show_banner(String(boss_def["broadside_banner"]))
	if _alive(_sloop, _sloop_gen):
		game.enemies.despawn(_sloop)  # It pulls off to wait for the Fire Ship.
	_sloop = null
	untargetable = false
	ethereal = false
	_leap_cd = float(boss_def["leap_every"])
	_pistol_cd = 2.0
	_start_leap()


## The Fire Ship: his sloop burns and rams the hull at his rail.
func _enter_fire() -> void:
	form = Form.FIRE
	game.stat_add("crow_fire_at", game.elapsed)
	game.stat_add("boss_atk_fire_ship", 1.0)
	game.enemies.show_banner(String(boss_def["fire_banner"]))
	if game.enemies.cutter != null and game.deck != null:
		var x := clampf(game.player.position.x, -game.deck.straight_rail_length() * 0.4, game.deck.straight_rail_length() * 0.4)
		game.enemies.cutter.fire_ship(game.deck.rail_point(x, int(_rail_n.y)), _rail_n)
	game.corsair_rules().play_sound("powder_blast", _rail, 0.3)
	_leap_cd = minf(_leap_cd, 2.0)


## The Duel and the Fire Ship: leaps, the pistol, the cutlass.
func _step_duel(delta: float) -> void:
	match act:
		Act.LEAP:
			_step_leap(delta)
			return
		Act.RECOVER:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)
			return
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)
	_leap_cd -= delta
	_pistol_cd -= delta
	if _leap_cd <= 0.0 and dist >= float(boss_def["leap_min"]):
		_start_leap()
		return
	if _pistol_cd <= 0.0 and dist >= float(boss_def["pistol_min"]) and not game.ultimates.player_untargetable():
		_pistol_cd = float(boss_def["pistol_every"])
		var dir := (pl.position - position).normalized()
		game.projectiles.fire_hostile(position, dir, float(boss_def["pistol_damage"]) * game.enemies.damage_mult * hit_mult(),
				float(boss_def["pistol_speed"]), undead_damage_mult, Projectile.Kind.ENEMY_ARROW, CrowData.PISTOL_SOURCE)
		game.stat_add("crow_pistol", 1.0)
		game.stat_add("boss_atk_pistol", 1.0)
		game.corsair_rules().play_sound("musket_shot", position, 0.3)
	move_speed = _base_speed
	super.physics_step(delta)


## A leap onto a landing circle at the nearest necromancer.
func _start_leap() -> void:
	var pl := game.nearest_player(position)
	_leap_from = position
	_leap_to = pl.position
	if game.deck != null:
		_leap_to = game.deck.clamp_point(_leap_to, radius)
	flies = true
	phases_obstacles = true
	game.effects.telegraph_circle(_leap_to, float(boss_def["leap_radius"]), float(boss_def["leap_time"]), self)
	game.stat_add("crow_leaps", 1.0)
	game.stat_add("boss_atk_leap", 1.0)
	_leap_cd = float(boss_def["fire_leap_every"] if form == Form.FIRE else boss_def["leap_every"])
	_set_act(Act.LEAP)


## In the air: he flies over the ring to the landing circle.
func _step_leap(delta: float) -> void:
	_tick_timers(delta)
	var k := clampf(act_time / maxf(float(boss_def["leap_time"]), 0.01), 0.0, 1.0)
	var to := _leap_from.lerp(_leap_to, k)
	velocity = (to - position) / maxf(delta, 0.0001)
	position = to
	_update_facing()
	queue_redraw()
	if k >= 1.0:
		_land()


## He lands: every grounded summon in the circle is struck and knocked out; a
## necromancer in it is struck.
func _land() -> void:
	flies = false
	phases_obstacles = false
	var r := float(boss_def["leap_radius"])
	var dm := game.enemies.damage_mult * hit_mult()
	var push := float(boss_def["leap_push"])
	var rules := game.corsair_rules()
	game.ally_grid.query(_leap_to, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
			continue
		var off := u.position - _leap_to
		if off.length() > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["leap_damage_summon"]) * dm, CrowData.LEAP_SOURCE, self)
		if u.active:
			TerrainSlow.push_summon(game, u, (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * push * rules.sea_legs_mult(u), 1.0)
		game.stat_add("crow_leap_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(_leap_to) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["leap_damage_player"]) * dm, CrowData.LEAP_SOURCE, pl, self)
	position = game.arena.free_point(_leap_to, radius)
	game.effects.impact(_leap_to, r, Palette.CORSAIR_SAIL)
	game.shake(5.0)
	rules.play_sound("plank_drop", _leap_to, 0.2)
	rules.play_sound("cutlass_slash", _leap_to, 0.2)
	_set_act(Act.RECOVER)


## Changes action, resets its timer and redraws.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


## True while `e` is the same living enemy it was at generation `gen`.
static func _alive(e: Enemy, gen: int) -> bool:
	return e != null and e.active and e.generation == gen


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the fire
## stops spreading, the short ending text (no epilogue).
func _on_defeated() -> void:
	var pos := position
	if game.enemies.cutter != null:
		game.enemies.cutter.stop_fire()
	if _alive(_sloop, _sloop_gen):
		game.enemies.despawn(_sloop)
	game.effects.ring(pos, 240.0, Palette.CORSAIR_FOAM, 1.0)
	game.effects.ring(pos, 140.0, Palette.CORSAIR_LANTERN, 0.8)
	Juice.fx.burst(pos, Palette.CORSAIR_SAIL_LIGHT, Palette.CORSAIR_LANTERN, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(CrowData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + CrowData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = CrowData.LATE_ANNOUNCE if game.countdown_finished() else CrowData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.CORSAIR_LANTERN_LIGHT)
	game.stats["crow_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the cannon lines and the
## landing circle while they show.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var half := float(boss_def["line_half"]) + DANGER_MARGIN
	for ln: Array in _lines:
		var dx := p.x - float(ln[0])
		if absf(dx) < half:
			push.x += (signf(dx) if absf(dx) > 0.5 else 1.0) * (1.0 - absf(dx) / half) * 3.0
	if act == Act.LEAP:
		var reach := float(boss_def["leap_radius"]) + DANGER_MARGIN
		var off := p - _leap_to
		var d := off.length()
		if d < reach:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / reach) * 3.0
	return push


## Body layer on `ci`: on his sloop during the Broadside (drawn out over the
## water), in the air on his leap's arc, else his still.
func _draw_body(ci: CanvasItem) -> void:
	var o := Vector2.ZERO
	if form == Form.BROADSIDE and game.deck != null:
		o = _rail_n * (radius + 40.0)  # On the sloop's deck.
	elif act == Act.LEAP:
		var k := clampf(act_time / maxf(float(boss_def["leap_time"]), 0.01), 0.0, 1.0)
		o = Vector2(0.0, -float(boss_def["leap_height"]) * 4.0 * k * (1.0 - k))
	if not SpriteBank.draw(ci, CrowData.SPRITE, o, flash > 0.0):
		_glyph(ci, o)


## His code shape without the art: a dark cloak, a tricorn, a cutlass.
func _glyph(ci: CanvasItem, o: Vector2) -> void:
	var r := radius
	var fl := flash > 0.0
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.2), r * 0.95, Glyphs._c(Palette.CORSAIR_INK, fl))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.2), r * 0.85, Glyphs._c(Palette.CORSAIR_SEA_DARK, fl))  # The cloak.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.7), r * 0.4, Glyphs._c(Palette.CORSAIR_TAN, fl))  # His face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 1.15), Vector2(r * 1.2, r * 0.25)), Glyphs._c(Palette.CORSAIR_INK, fl))  # The tricorn.
	ci.draw_line(o + Vector2(r * 0.6, r * 0.3), o + Vector2(r * 1.4, -r * 0.6), Glyphs._c(Palette.CORSAIR_POWDER_LIGHT, fl), 2.0)  # The cutlass.


## Under layer: the cannon lines across the deck (lantern-amber bands
## brightening as they near), and his shadow while he leaps. Rects and the
## disc texture only.
func _draw_under() -> void:
	super._draw_under()
	if not _lines.is_empty():
		draw_set_transform_matrix(CourtGlyphs.unmirror_xf(self))
		var now := game.elapsed
		var half := float(boss_def["line_half"])
		for ln: Array in _lines:
			var k := clampf((now - float(ln[2])) / maxf(float(ln[1]) - float(ln[2]), 0.01), 0.0, 1.0)
			var x := float(ln[0]) - position.x
			var top := _mid_y - _half_beam - position.y
			var rect := Rect2(Vector2(x - half, top), Vector2(half * 2.0, _half_beam * 2.0))
			draw_rect(rect, Color(Palette.CORSAIR_LANTERN, 0.10 + 0.22 * k))
			draw_rect(Rect2(Vector2(x - 1.0, top), Vector2(2.0, _half_beam * 2.0)), Color(Palette.CORSAIR_LANTERN_LIGHT, 0.35 + 0.5 * k))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	if act == Act.LEAP:
		var w := radius * 1.1
		draw_set_transform_matrix(CourtGlyphs.unmirror_xf(self))
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, radius * 0.6 - w * 0.3), Vector2(w * 2.0, w * 0.6)), false, Color(0.0, 0.0, 0.0, 0.3))
		draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var duel := float(st.get("crow_duel_at", -1.0))
	var fire := float(st.get("crow_fire_at", -1.0))
	var kt := float(st.get("crow_kill_time", -1.0))
	return "broadside: %d broadsides (%d lines; hits on summons %d, on you %d, on enemies %d), crew sent %d, sloop sunk %s | the duel %s: leaps %d (hits %d), pistol %d | the fire ship %s | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("crow_broadsides", 0.0)), int(st.get("crow_lines", 0.0)), int(st.get("crow_line_hits_summons", 0.0)),
		int(st.get("crow_line_hits_you", 0.0)), int(st.get("crow_line_enemy_hits", 0.0)), int(st.get("crow_crew_sent", 0.0)),
		"yes" if float(st.get("crow_sloop_sunk", 0.0)) > 0.0 else "no",
		EmpireReport._clock(duel) if duel >= 0.0 else "not reached", int(st.get("crow_leaps", 0.0)), int(st.get("crow_leap_hits", 0.0)),
		int(st.get("crow_pistol", 0.0)), EmpireReport._clock(fire) if fire >= 0.0 else "not reached",
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + CrowData.LINE_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + CrowData.LEAP_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + CrowData.PISTOL_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + CrowData.LINE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + CrowData.LEAP_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
