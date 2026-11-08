## BossHrimgar — HRIMGAR THE DRAUGR-KING, the boss of the Barrow Fields (the
## Hall of the Slain, temporarily Act XI, Stage 16 in the final order; GDD §15.0
## "Hrimgar the Draugr-King"; owner-approved proposal: "he rises three times.
## Each time he falls he sinks into his barrow and returns stronger 20 s later,
## unless the necromancer breaks the barrow while he is down. Phases: the Grave
## (frost mist and draugr from every mound), the Barrow Lord (a cleaving
## greatsword), the Last Rising (he drags summons into the mound with him)").
## Loaded by name for the boss id "hrimgar" (EnemyDirector.NORSE_BOSS_DIR +
## "boss_hrimgar.gd"); he arrives at 17:00 (3:00 left). Extends Boss, so
## summons, spells and the spatial hash treat him like any enemy. A towering
## male draugr king (norse/hrimgar, walk strip). Every number is
## HrimgarData.BOSS's; the phases are documented in HrimgarData. Every attack
## is an enemy effect through the existing one paths: the mist and the cleave
## through damage_unit() / damage_player() and CombatResolver.chill_unit(), the
## barrows through BarrowFieldsDirector.open_barrow_anywhere() (THE barrow
## path), the drag through the held hook (SummonedUnit.held_until) plus one
## CombatResolver.stun_unit(). While he lies in his barrow he is out of reach
## (Enemy.untargetable and ethereal, damage_taken_mult() 0); breaking the
## barrow (HrimgarBarrowKit -> barrow_broken()) kills him through the boss
## kill path (CombatResolver.damage_enemy() with HrimgarData.BROKEN_SOURCE, on
## his next step). Above his life's floor every hit lands; at it he cannot be
## hurt until he falls (the gate). The shared rules are created on first use
## (Game.norse_rules()), so --boss=hrimgar works on any stage.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Barrow Grasp and Grave Frost (UnlockData, boss "hrimgar"). A short ending
## text only (no epilogue until the reorder pass).
## Determinism: the seeded gameplay RNG is never used (fixed angles turned by
## counters). Stats: boss_atk_<special>, hrimgar_mists, hrimgar_mist_hits,
## hrimgar_mist_on_you, hrimgar_calls, hrimgar_call_draugr, hrimgar_cleaves,
## hrimgar_cleave_hits, hrimgar_cleave_on_you, hrimgar_drags,
## hrimgar_dragged, hrimgar_falls, hrimgar_risings, hrimgar_barrow_broken,
## hrimgar_life2_at, hrimgar_life3_at, hrimgar_kill_time.
class_name BossHrimgar
extends Boss

## His action.
enum Act { WALK, CLEAVE, RECOVER, SINK, DOWN, RISE }

## px the autotest bot keeps beyond a telegraph's edge (autotest hint only).
const DANGER_MARGIN: float = 24.0  # TUNING (not in GDD) autotest hint only

## His life (1 the Grave, 2 the Barrow Lord, 3 the Last Rising).
var life: int = 1
## Current action.
var act: Act = Act.WALK
## Seconds in the current action.
var act_time: float = 0.0
## Seconds until his next frost mist.
var _mist_cd: float = 0.0
## Seconds until his next call of the mounds (the Grave).
var _call_cd: float = 0.0
## Seconds until his next cleave (INF in the Grave).
var _cleave_cd: float = INF
## Seconds until his next drag (INF before the Last Rising).
var _drag_cd: float = INF
## Pending mist bursts: [pos (world px), burst time (game s)].
var _mists: Array = []
## Direction of the cleave being wound up (unit).
var _cleave_dir: Vector2 = Vector2.RIGHT
## Summons being dragged: [unit, generation, from (world px), t0 (game s), t_end (game s)].
var _dragged: Array = []
## His barrow while he lies in it (null otherwise; generation-checked).
var _barrow: Enemy = null
## Generation of `_barrow` when it rose.
var _barrow_gen: int = 0
## True once his barrow was broken while he lay in it (he dies on his next step).
var _broken: bool = false
## True when his death came from a broken barrow (the ending text).
var _died_broken: bool = false
## Mists / calls / drags so far (turn the next one's angles; no RNG).
var _waves: int = 0
## His walking speed (px/s; grows with each rising).
var _base_speed: float = 44.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Hrimgar at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = HrimgarData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	life = 1
	act = Act.WALK
	act_time = 0.0
	_mist_cd = float(boss_def["mist_first"])
	_call_cd = float(boss_def["call_first"])
	_cleave_cd = INF
	_drag_cd = INF
	_mists.clear()
	_dragged.clear()
	_barrow = null
	_broken = false
	_died_broken = false
	_waves = 0
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.norse_rules().play_sound("horn", position)  # The shared rules exist wherever he fights.
	game.enemies.boss_defeated.connect(_on_defeated)
	game.stat_add("boss_atk_frost_mist", 0.0)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return HrimgarData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK


## Any removal leaves him solid, and lets every dragged summon go.
func deactivate() -> void:
	_release_dragged()
	untargetable = false
	ethereal = false
	phases_obstacles = false
	super.deactivate()


## Out of reach while he sinks, lies in his barrow and rises; at his life's
## floor he cannot be hurt until he falls; the broken barrow's blow always lands.
func damage_taken_mult(source: String) -> float:
	if source == HrimgarData.BROKEN_SOURCE:
		return 1.0
	if act == Act.SINK or act == Act.DOWN or act == Act.RISE:
		return 0.0
	if life < 3 and hp <= max_hp * _floor() + 1.0:
		return 0.0
	return super.damage_taken_mult(source)


## The HP share his current life ends at (0 in the Last Rising).
func _floor() -> float:
	match life:
		1:
			return float(boss_def["fall1_hp"])
		2:
			return float(boss_def["fall2_hp"])
	return 0.0


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: his falls and risings, then the action of his life.
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_mist_cd -= delta
	_call_cd -= delta
	_cleave_cd -= delta
	_drag_cd -= delta
	_step_mists()
	_step_dragged(delta)
	if _broken:
		_broken = false
		_died_broken = true
		game.stat_add("hrimgar_barrow_broken", 1.0)
		untargetable = false
		ethereal = false
		game.combat.damage_enemy(self, hp * 100.0 + max_hp, HrimgarData.BROKEN_SOURCE)  # He dies in his broken barrow (the boss kill path).
		return
	if life < 3 and (act == Act.WALK or act == Act.RECOVER) and hp <= max_hp * _floor() + 1.0:
		_fall()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.CLEAVE:
			_hold(delta)
			if act_time >= float(boss_def["cleave_windup"]):
				_sword_cleave()
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)
		Act.SINK:
			_hold(delta)
			if act_time >= float(boss_def["sink_time"]):
				_set_act(Act.DOWN)
		Act.DOWN:
			_hold(delta)
			if act_time >= float(boss_def["down_time"]):
				_start_rise()
		Act.RISE:
			_hold(delta)
			if act_time >= float(boss_def["rise_time"]):
				_risen()


## Walking: the shared AI (his greatsword in reach), faster from afar; his
## life's specials start on their cooldowns.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var spd := _base_speed
	if position.distance_to(pl.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if life <= 2 and _mist_cd <= 0.0:
		_mist_cd = float(boss_def["mist_every"] if life == 1 else boss_def["mist_every_lord"])
		_frost_mist(pl)
	if life == 1 and _call_cd <= 0.0:
		_call_cd = float(boss_def["call_every"])
		_call_mounds(pl)
	if life == 3 and _drag_cd <= 0.0:
		_drag_cd = float(boss_def["drag_every"])
		_drag()
	if life >= 2 and _cleave_cd <= 0.0:
		_cleave_cd = float(boss_def["cleave_every"] if life == 2 else boss_def["cleave_every_last"])
		var to := pl.position - position
		_cleave_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_act(Act.CLEAVE)


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
# The Grave: frost mist and draugr from every mound
# =====================================================================================

## Frost mist: mist_count telegraphed circles on the ring around `pl`.
func _frost_mist(pl: Necromancer) -> void:
	var n := maxi(1, int(boss_def["mist_count"]))
	var base := float(_waves) * 1.3  # Turns each mist (no RNG).
	var r := float(boss_def["mist_radius"])
	var tele := float(boss_def["mist_telegraph"])
	for k in n:
		var a := base + TAU * float(k) / float(n)
		var dist := lerpf(float(boss_def["mist_min"]), float(boss_def["mist_max"]), float(k % 2))
		var at := pl.position + Vector2.from_angle(a) * dist
		_mists.append([at, game.elapsed + tele])
		game.effects.telegraph_circle(at, r, tele, self)
	_waves += 1
	game.stat_add("boss_atk_frost_mist", 1.0)
	game.stat_add("hrimgar_mists", 1.0)


## The mists whose time is up burst cold.
func _step_mists() -> void:
	var i := 0
	while i < _mists.size():
		var m: Array = _mists[i]
		if game.elapsed < float(m[1]):
			i += 1
			continue
		_mists.remove_at(i)
		_mist_burst(m[0])


## One mist bursts at `at`: grounded summons inside are struck and chilled,
## the necromancer struck.
func _mist_burst(at: Vector2) -> void:
	var r := float(boss_def["mist_radius"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.position.distance_to(at) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["mist_damage_summon"]) * mult * undead_damage_mult, HrimgarData.MIST_SOURCE, self)
		game.combat.chill_unit(u, float(boss_def["mist_chill"]), float(boss_def["mist_chill_time"]), HrimgarData.MIST_SOURCE)
		game.stat_add("hrimgar_mist_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["mist_damage"]) * mult, HrimgarData.MIST_SOURCE, pl, self)
			game.stat_add("hrimgar_mist_on_you", 1.0)
	game.effects.ring(at, r, Palette.NORSE_FROST, 0.5)


## Draugr from every mound: each standing open barrow lets call_per_barrow
## out at once, and call_new new barrows crack around the ring.
func _call_mounds(pl: Necromancer) -> void:
	var made := 0
	for e: Enemy in game.enemies.active:
		if e.active and e.kit is OpenBarrowKit and not (e.kit is HrimgarBarrowKit):
			made += (e.kit as OpenBarrowKit).release(e, int(boss_def["call_per_barrow"]), true)
	var n := int(boss_def["call_new"])
	for k in n:
		var a := float(_waves) * 0.8 + TAU * float(k) / float(maxi(1, n)) + 0.5
		BarrowFieldsDirector.open_barrow_anywhere(game, pl.position + Vector2.from_angle(a) * float(boss_def["call_dist"]), "hrimgar")
	_waves += 1
	game.stat_add("boss_atk_mound_call", 1.0)
	game.stat_add("hrimgar_calls", 1.0)
	game.stat_add("hrimgar_call_draugr", float(made))
	game.norse_rules().play_sound("horn", position, 1.0)


# =====================================================================================
# The Barrow Lord: the cleave
# =====================================================================================

## The cleave lands: summons in the sector are struck and thrown, the
## necromancer struck.
func _sword_cleave() -> void:
	var reach := float(boss_def["cleave_reach"])
	var half := float(boss_def["cleave_half"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var hits := 0
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if not CovenantKit.in_sector(position, _cleave_dir, reach, half, radius, u.position, u.radius):
			continue
		game.combat.damage_unit(u, float(boss_def["cleave_damage_summon"]) * mult * undead_damage_mult, HrimgarData.CLEAVE_SOURCE, self)
		hits += 1
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - position).normalized() if u.position.distance_squared_to(position) > 1.0 else _cleave_dir
			u.position += away * game.arena.clear_length(u.position, away, float(boss_def["cleave_knock"]), u.radius)
	for pl in game.all_players:
		if not pl.dead and CovenantKit.in_sector(position, _cleave_dir, reach, half, radius, pl.position, pl.radius):
			game.combat.damage_player(float(boss_def["cleave_damage"]) * mult, HrimgarData.CLEAVE_SOURCE, pl, self)
			game.stat_add("hrimgar_cleave_on_you", 1.0)
	game.effects.slash(position + _cleave_dir * reach * 0.5, _cleave_dir, Palette.NORSE_FROST, reach)
	game.shake(5.0)
	game.stat_add("boss_atk_cleave", 1.0)
	game.stat_add("hrimgar_cleaves", 1.0)
	game.stat_add("hrimgar_cleave_hits", float(hits))


# =====================================================================================
# The Last Rising: the drag
# =====================================================================================

## He reaches for the drag_count summons nearest him: each is held (the held
## hook and one stun) and drawn into the mound at his feet.
func _drag() -> void:
	var reach := float(boss_def["drag_reach"])
	var n := int(boss_def["drag_count"])
	var pull := float(boss_def["drag_pull"])
	var hold := float(boss_def["drag_hold"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var picks: Array = []
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.held_until > game.elapsed or u.position.distance_to(position) > reach + u.radius:
			continue
		picks.append(u)
	picks.sort_custom(func(a: SummonedUnit, b: SummonedUnit) -> bool: return a.position.distance_squared_to(position) < b.position.distance_squared_to(position))
	var made := 0
	for u: SummonedUnit in picks:
		if made >= n:
			break
		game.combat.stun_unit(u, pull + hold, HrimgarData.DRAG_SOURCE)
		u.held_until = maxf(u.held_until, game.elapsed + pull + hold)
		_dragged.append([u, u.generation, u.position, game.elapsed, game.elapsed + pull + hold])
		made += 1
	_waves += 1
	game.stat_add("boss_atk_drag", 1.0)
	game.stat_add("hrimgar_drags", 1.0)
	game.stat_add("hrimgar_dragged", float(made))
	if made > 0:
		game.effects.ring(position, radius * 2.5, Palette.NORSE_DRAUGR, 0.5)


## THE one place that moves a dragged summon: drawn to the mound at his feet,
## then held there, crushed by drag_dps of its max HP a second.
func _step_dragged(delta: float) -> void:
	if _dragged.is_empty():
		return
	var pull := float(boss_def["drag_pull"])
	var dps := float(boss_def["drag_dps"])
	var i := 0
	while i < _dragged.size():
		var dr: Array = _dragged[i]
		var u: SummonedUnit = dr[0]
		if not u.active or u.generation != int(dr[1]) or u.state == SummonedUnit.State.DEAD or game.elapsed >= float(dr[4]):
			if u.active and u.generation == int(dr[1]):
				u.held_until = minf(u.held_until, game.elapsed)
			_dragged.remove_at(i)
			continue
		var mound := position + Vector2(0.0, radius * 0.6)
		var k := clampf((game.elapsed - float(dr[3])) / maxf(pull, 0.01), 0.0, 1.0)
		u.position = (dr[2] as Vector2).lerp(mound, k)
		u.velocity = Vector2.ZERO
		if k >= 1.0:
			game.combat.damage_unit(u, u.max_hp * dps * delta, HrimgarData.DRAG_SOURCE, self)
		i += 1


## Lets every dragged summon go (his fall, his removal).
func _release_dragged() -> void:
	for dr: Array in _dragged:
		var u: SummonedUnit = dr[0]
		if u.active and u.generation == int(dr[1]):
			u.held_until = minf(u.held_until, game.elapsed)
	_dragged.clear()


# =====================================================================================
# His falls and risings
# =====================================================================================

## He falls at his life's floor: he sinks, and his barrow rises where he fell.
func _fall() -> void:
	_release_dragged()
	_mists.clear()
	untargetable = true
	ethereal = true
	phases_obstacles = true
	game.stat_add("boss_atk_fall", 1.0)
	game.stat_add("hrimgar_falls", 1.0)
	game.enemies.show_banner(String(boss_def["fall1_banner"] if life == 1 else boss_def["fall2_banner"]))
	game.effects.impact(position, radius * 2.5, Palette.NORSE_DRAUGR)
	game.shake(6.0)
	_barrow = game.enemies.spawn_at(BarrowFieldsEnemyData.HRIMGAR_BARROW, position, false)
	if _barrow != null:
		_barrow_gen = _barrow.generation
		if game.coop != null:
			var m := game.difficulty.coop_mult("miniboss_hp")  # Co-op: tougher for two armies (as a miniboss).
			_barrow.max_hp *= m
			_barrow.hp *= m
	_set_act(Act.SINK)


## The barrow `b` was broken while he lay in it (HrimgarBarrowKit): he never
## rises; the kill runs on his next step (not inside the barrow's kill path).
func barrow_broken(b: Enemy) -> void:
	if b != _barrow or not (act == Act.SINK or act == Act.DOWN):
		return
	_barrow = null
	_broken = true


## down_time s passed with his barrow standing: he climbs out of it.
func _start_rise() -> void:
	if _barrow != null and _barrow.active and _barrow.generation == _barrow_gen:
		position = _barrow.position
		game.enemies.despawn(_barrow)  # He rises out of it: the mound goes without a kill.
	_barrow = null
	game.effects.impact(position, radius * 2.5, Palette.NORSE_RUNE)
	game.shake(7.0)
	_set_act(Act.RISE)


## He stands risen: his next life begins, stronger.
func _risen() -> void:
	untargetable = false
	ethereal = false
	phases_obstacles = false
	var fell_at := _floor()  # The floor he fell at.
	life += 1
	hp = minf(max_hp, maxf(hp, max_hp * (fell_at + float(boss_def["rise_heal"]))))
	damage *= float(boss_def["rise_damage"])
	_base_speed *= float(boss_def["rise_speed"])
	position = game.arena.free_point(position, radius)
	game.stat_add("boss_atk_rising", 1.0)
	game.stat_add("hrimgar_risings", 1.0)
	game.stat_add("hrimgar_life%d_at" % life, game.elapsed)
	game.enemies.show_banner(String(boss_def["rise2_banner"] if life == 2 else boss_def["rise3_banner"]))
	game.norse_rules().play_sound("horn", position)
	if life == 2:
		_cleave_cd = float(boss_def["cleave_first"])
		_mist_cd = float(boss_def["mist_every_lord"]) * 0.5
	else:
		_cleave_cd = float(boss_def["cleave_first"]) + float(boss_def["cleave_every_last"]) * 0.5
		_drag_cd = float(boss_def["drag_first"])
	_set_act(Act.RECOVER)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue).
func _on_defeated() -> void:
	var pos := position
	_release_dragged()
	game.effects.ring(pos, 240.0, Palette.NORSE_FROST, 1.0)
	game.effects.ring(pos, 140.0, Palette.NORSE_RUNE, 0.8)
	Juice.fx.burst(pos, Palette.NORSE_FROST, Palette.NORSE_RUNE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(HrimgarData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + HrimgarData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = HrimgarData.BROKEN_ANNOUNCE if _died_broken else (HrimgarData.LATE_ANNOUNCE if game.countdown_finished() else HrimgarData.ENDING_ANNOUNCE)
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NORSE_FROST)
	game.stats["hrimgar_kill_time"] = game.elapsed - _spawn_time
	game.stats["hrimgar_died_life"] = float(life)


## Danger hint for the autotest autopilot: out of the mist circles about to
## burst, out of the cleave's sector while he winds it up.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var mr := float(boss_def["mist_radius"]) + DANGER_MARGIN
	for m: Array in _mists:
		var rel := p - (m[0] as Vector2)
		var dist := rel.length()
		if dist < mr:
			push += (rel / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / mr) * 2.5
	if act == Act.CLEAVE:
		var reach := float(boss_def["cleave_reach"]) + DANGER_MARGIN
		if CovenantKit.in_sector(position, _cleave_dir, reach, float(boss_def["cleave_half"]), radius, p, 8.0):
			var rel2 := p - position
			var side := _cleave_dir.orthogonal()
			push += (side if side.dot(rel2) >= 0.0 else -side) * 2.0 + rel2.normalized() * 1.0
	return push


## Autotest autopilot: his barrow while he lies in it (bring the army to it and
## break it), else Vector2.INF.
func approach_point(_p: Vector2) -> Vector2:
	if (act == Act.SINK or act == Act.DOWN) and _barrow != null and _barrow.active and _barrow.generation == _barrow_gen:
		return _barrow.position
	return Vector2.INF


## Body layer on `ci`: sinking into / rising out of the ground, nothing while
## he lies in his barrow (the barrow is drawn), else his sprite.
func _draw_body(ci: CanvasItem) -> void:
	match act:
		Act.SINK:
			var k := clampf(act_time / maxf(float(boss_def["sink_time"]), 0.01), 0.0, 1.0)
			if not SpriteBank.draw_rising(ci, HrimgarData.SPRITE, Vector2.ZERO, 1.0 - k, false):
				_glyph(ci, Vector2(0.0, radius * k), 1.0 - k)
			return
		Act.DOWN:
			return
		Act.RISE:
			var k2 := clampf(act_time / maxf(float(boss_def["rise_time"]), 0.01), 0.0, 1.0)
			if not SpriteBank.draw_rising(ci, HrimgarData.SPRITE, Vector2.ZERO, k2, false):
				_glyph(ci, Vector2(0.0, radius * (1.0 - k2)), k2)
			return
	if not SpriteBank.draw(ci, HrimgarData.SPRITE, Vector2.ZERO, flash > 0.0):
		_glyph(ci, Vector2.ZERO, 1.0)


## His code shape without the art: a grey-blue draugr king, a rime crown and
## ice-blue eyes (`k` 0..1 how much of him shows).
func _glyph(ci: CanvasItem, o: Vector2, k: float) -> void:
	var r := radius * maxf(0.2, k)
	var fl := flash > 0.0
	SpriteBank.draw_disc(ci, o, r * 1.15, Glyphs._c(Palette.NORSE_INK, fl))
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(Palette.NORSE_DRAUGR_DARK, fl))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 0.5, Glyphs._c(Palette.NORSE_DRAUGR, fl))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.45), Vector2(r * 0.9, 3.0)), Glyphs._c(Palette.NORSE_FROST, fl))  # The rime crown.
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.18, -r * 0.85), 2.0, Glyphs._c(Palette.NORSE_RUNE, fl))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.18, -r * 0.85), 2.0, Glyphs._c(Palette.NORSE_RUNE, fl))


## Overlay layer on `ci`: the cleave's sector while he winds it up (dots along
## its edges and arc, in world axes), the frozen look. Visual only.
func _draw_over(ci: CanvasItem) -> void:
	if act == Act.CLEAVE:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))  # Counter the facing mirror: world axes.
		var reach := float(boss_def["cleave_reach"])
		var half := float(boss_def["cleave_half"])
		var k := clampf(act_time / maxf(float(boss_def["cleave_windup"]), 0.01), 0.0, 1.0)
		var col := Color(Palette.NORSE_FROST, 0.35 + 0.5 * k)
		var a0 := _cleave_dir.angle()
		for i in 13:
			var a := a0 - half + 2.0 * half * float(i) / 12.0
			SpriteBank.draw_disc(ci, Vector2.from_angle(a) * reach, 2.2, col)
		for j in 6:
			var f := float(j + 1) / 7.0
			SpriteBank.draw_disc(ci, Vector2.from_angle(a0 - half) * reach * f, 1.8, col)
			SpriteBank.draw_disc(ci, Vector2.from_angle(a0 + half) * reach * f, 1.8, col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen and act != Act.DOWN:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var l2 := float(st.get("hrimgar_life2_at", -1.0))
	var l3 := float(st.get("hrimgar_life3_at", -1.0))
	var kt := float(st.get("hrimgar_kill_time", -1.0))
	return "the Grave: mists %d (hits on summons %d, on you %d), mound calls %d (draugr %d) | falls %d, risings %d (the Barrow Lord %s, the Last Rising %s), barrow broken %s | cleaves %d (hits %d, on you %d) | drags %d (summons %d) | killed %s%s | dmg to you %d, to summons %d" % [
		int(st.get("hrimgar_mists", 0.0)), int(st.get("hrimgar_mist_hits", 0.0)), int(st.get("hrimgar_mist_on_you", 0.0)),
		int(st.get("hrimgar_calls", 0.0)), int(st.get("hrimgar_call_draugr", 0.0)),
		int(st.get("hrimgar_falls", 0.0)), int(st.get("hrimgar_risings", 0.0)),
		EmpireReport._clock(l2) if l2 >= 0.0 else "not reached", EmpireReport._clock(l3) if l3 >= 0.0 else "not reached",
		"yes" if float(st.get("hrimgar_barrow_broken", 0.0)) > 0.0 else "no",
		int(st.get("hrimgar_cleaves", 0.0)), int(st.get("hrimgar_cleave_hits", 0.0)), int(st.get("hrimgar_cleave_on_you", 0.0)),
		int(st.get("hrimgar_drags", 0.0)), int(st.get("hrimgar_dragged", 0.0)),
		("%.0f s after he arrived" % kt) if kt >= 0.0 else "no",
		(" (in life %d)" % int(st.get("hrimgar_died_life", 0.0))) if kt >= 0.0 else "",
		int(st.get("player_dmg_from_" + HrimgarData.MIST_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + HrimgarData.CLEAVE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + HrimgarData.MIST_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + HrimgarData.CLEAVE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + HrimgarData.DRAG_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
