## BossMarrec — ADMIRAL ISABEAU MARREC, THE SEA WOLF, the boss of the Treasure
## Galleon (Act X, the Black Tide; GDD §15.0 "Admiral Isabeau Marrec, the Sea
## Wolf (Act X)"; owner-approved proposal: "the Fleet (her flagship's
## broadsides on a 30 s rhythm, a raider ship boards with a plank), the
## Boarding (she leads her marines across the plank; cut both hooks and the
## plank falls with her crew in the water), Gold Fever (cursed coins that
## become short barriers round her marines; area damage clears them; then a
## duel on the quarterdeck)"). A woman in the figure-redesign style (her
## sprite corsair/marrec with its walk and idle strips). Loaded by name for
## the boss id "marrec" (EnemyDirector.CORSAIR_BOSS_DIR + "boss_marrec.gd");
## she arrives at 17:00 (3:00 left). Extends Boss; her kit is MarrecKit (a
## CorsairKit: THE WATER TEST sees her while she is off the deck, so the deck
## clamp leaves her where she stands). Numbers in MarrecData.BOSS. Her forms:
##   1 THE FLEET: she stands on her flagship's deck alongside a seeded rail
##     (ship_off px out in the water, in reach of ranged summons and spells,
##     not of the melee ring), firing her pistol; her flagship fires the
##     galleon's BROADSIDE (GalleonDirector.broadside(), the one broadside
##     path) every broadside_every s, and a raider ship's worth of her crew
##     (fleet_crew) joins Boarding's queue at once (BoardingParty sends the
##     boats; the boarding path, not a second one). It ends after fleet_time
##     s or below fleet_hp of her HP.
##   2 THE BOARDING: she lays her PLANK from her flagship to the rail: two
##     grapple hooks (the shared boarding_hook rows, objectives) stand at the
##     rail either side of it, and she crosses with her marines in plank_time
##     s. CUT BOTH HOOKS before she reaches the rail and THE PLANK FALLS: her
##     marines drown (never spawned; counted), she falls in the sea
##     (fall_share of her max HP through CombatResolver.damage_enemy(), the
##     one kill path), flounders fall_time s, climbs back aboard her flagship
##     and lays a new plank after replank_time s; after max_falls falls she
##     swings across on a rope instead. Reaching the rail, she steps aboard
##     with her marines (spawned there) and the duel begins.
##   3 THE DUEL (on the deck): the shared walk at the necromancer with her
##     cutlass in reach, the pistol, and a telegraphed RAPIER LUNGE
##     (lunge_every s: a lane to the necromancer for lunge_windup s, then she
##     runs it through at lunge_speed: every summon and necromancer in the
##     lane is hit once, OlympusHits.lane()).
##   4 GOLD FEVER (below fever_hp): she scatters `coins` CURSED COINS round
##     her every coin_every s (GalleonEnemyData "cursed_coin": 1 HP
##     structures that keep a barrier on her marines; each standing coin near
##     her also cuts her damage taken by coin_cut, at most coin_cut_max),
##     calls her last marines, RETREATS to the quarterdeck (quarterdeck_in px
##     inside the stern; at most retreat_time s) and duels there with a
##     quicker lunge (fever_lunge_every), still walking at whoever comes.
## Off a deck stage (--boss=marrec elsewhere) the Fleet and the Boarding are
## skipped: she starts in the duel.
## Killing her drops the big XP burst and the boss chest (EnemyDirector), and
## unlocks Cannonade and Black Powder (UnlockData, boss "marrec").
## Determinism: the seeded gameplay RNG only (her rail, the coins' places).
## Stats: boss_atk_<special>, marrec_fleet_crew, marrec_planks,
## marrec_plank_falls, marrec_marines_drowned, marrec_marines_aboard,
## marrec_rope_swings, marrec_aboard_at, marrec_fever_at, marrec_lunges,
## marrec_lunge_hits, coins_dropped, marrec_coin_cut, marrec_slain.
class_name BossMarrec
extends Boss

## Boss action phases.
enum Phase { SHIP, PLANK, FALLEN, WALK, LUNGE_WINDUP, LUNGE, RETREAT, RECOVER }

## px the autotest bot keeps beyond a lunge lane's edge (autotest hint only).
const DANGER_MARGIN: float = 22.0  # TUNING (not in GDD) autotest hint only

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Her form: 1 the Fleet, 2 the Boarding, 3 the duel, 4 Gold Fever.
var form: int = 1
## The rail her flagship lies along (+1 lower, -1 upper).
var _side: int = -1
## Where she stands on her flagship (world px).
var _ship_at: Vector2 = Vector2.ZERO
## The rail point her plank reaches (world px).
var _rail_at: Vector2 = Vector2.ZERO
## Her plank hooks: [Enemy, generation] each (empty when none).
var _hooks: Array = []
## Falls from the plank so far.
var _falls: int = 0
## Seconds until her next broadside (the Fleet).
var _broadside_cd: float = INF
## Seconds until her next pistol shot.
var _pistol_cd: float = 0.0
## Seconds until her next lunge.
var _lunge_cd: float = INF
## Seconds until her next coin scatter (INF before Gold Fever).
var _coin_cd: float = INF
## The lunge lane's start (world px).
var _lunge_from: Vector2 = Vector2.ZERO
## The lunge lane's end (world px; on the deck).
var _lunge_to: Vector2 = Vector2.ZERO
## Bodies the current lunge already hit (OlympusHits.lane()).
var _struck: Dictionary = {}
## Her cursed coins: [Enemy, generation] each.
var _coins: Array = []
## Move speed of her duel (px/s).
var _base_speed: float = 58.0
## Scratch query buffer.
var _buf: Array = []


## Sets up the Admiral at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MarrecData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase_time = 0.0
	_falls = 0
	_hooks.clear()
	_coins.clear()
	_struck.clear()
	_base_speed = move_speed
	_pistol_cd = float(boss_def["pistol_every"])
	_lunge_cd = INF
	_coin_cd = INF
	_broadside_cd = INF
	game.stat_add("boss_atk_fleet", 0.0)
	if game.deck == null:
		_board_done(false)  # Off a deck stage: straight to the duel.
		return
	form = 1
	_side = 1 if randf() < 0.5 else -1
	var pl := game.nearest_player(game.deck.center)
	_rail_at = game.deck.rail_point(pl.position.x - game.deck.center.x, _side)
	_ship_at = _rail_at + Vector2(0.0, float(_side)) * float(boss_def["ship_off"])
	position = _ship_at
	_set_water(true)
	_set_phase(Phase.SHIP)
	_broadside_cd = float(boss_def["broadside_first"])
	game.stat_add("boss_atk_fleet", 1.0)
	_fleet_crew()


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return MarrecData.SPECIALS


## True while she walks (Boss hook, stuck check): her ship, plank and
## fall are scripted holds, never "stuck".
func is_walking() -> bool:
	return phase == Phase.WALK


## True while she crosses her plank (GalleonDirector's HUD objective).
func on_plank() -> bool:
	return form == 2 and phase == Phase.PLANK


## Her fall takes her hooks and coins with her; the run stat.
func deactivate() -> void:
	if hp <= 0.0:
		game.stat_add(MarrecData.SLAIN_STAT, 1.0)
	_clear_hooks()
	for c: Array in _coins:
		if _alive(c[0], int(c[1])):
			game.enemies.despawn(c[0])
	_coins.clear()
	super.deactivate()


## Each standing coin near her cuts her damage taken (Gold Fever).
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if form != 4 or source == MarrecData.FALL_SOURCE:
		return m
	var n := 0
	for c: Array in _coins:
		var e: Enemy = c[0]
		if _alive(e, int(c[1])) and e.kit is CursedCoinKit and (e.kit as CursedCoinKit).near(e, position):
			n += 1
	if n == 0:
		return m
	game.stat_add("marrec_coin_cut", 1.0)
	return m * (1.0 - minf(float(boss_def["coin_cut_max"]), float(boss_def["coin_cut"]) * float(n)))


## Boss physics: her form machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	_pistol_cd -= delta
	_lunge_cd -= delta
	_coin_cd -= delta
	_broadside_cd -= delta
	if form == 1 and (phase_time >= float(boss_def["fleet_time"]) or (_falls == 0 and hp <= max_hp * float(boss_def["fleet_hp"]))):
		_start_plank()
	if form == 3 and hp <= max_hp * float(boss_def["fever_hp"]):
		_gold_fever()
	if _coin_cd <= 0.0:
		_scatter_coins()
	if form <= 2 and _broadside_cd <= 0.0:
		_broadside_cd = float(boss_def["broadside_every"])
		var gd := game.enemies.galleon  # The Galleon's director (null on another stage: no broadside).
		if gd != null and gd.broadside(_side, "marrec"):
			game.stat_add("boss_atk_broadside", 1.0)
	match phase:
		Phase.SHIP:
			_hold(delta)
			position = _ship_at
			_try_pistol()
		Phase.PLANK:
			_hold(delta)
			_step_plank()
		Phase.FALLEN:
			_hold(delta)
			if phase_time >= float(boss_def["fall_time"]):
				position = _ship_at
				_set_phase(Phase.SHIP)
				phase_time = float(boss_def["fleet_time"]) - float(boss_def["replank_time"])  # The SHIP phase's clock: a new plank after replank_time s.
				form = 1
		Phase.WALK:
			_step_walk(delta)
		Phase.LUNGE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["lunge_windup"]):
				_struck.clear()
				_set_phase(Phase.LUNGE)
		Phase.LUNGE:
			_hold(delta)
			_step_lunge(delta)
		Phase.RETREAT:
			_step_retreat(delta)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Walking the deck: the shared AI (her cutlass in reach) at her speed; the
## pistol and the lunge when ready.
func _step_walk(delta: float) -> void:
	var pl := game.player
	var spd := _base_speed
	if position.distance_to(pl.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if _lunge_cd <= 0.0 and _start_lunge():
		return
	_try_pistol()


## Standing still (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## In the water (her flagship, her plank) or on the deck (MarrecKit's water test).
func _set_water(on: bool) -> void:
	if kit is CorsairKit:
		(kit as CorsairKit).in_water = on


## True while `e` is the same living enemy it was at generation `gen`.
static func _alive(e: Enemy, gen: int) -> bool:
	return e != null and e.active and e.generation == gen


# =====================================================================================
# The Fleet: her flagship, her pistol, the raider ship's crew
# =====================================================================================

## A raider ship's worth of her crew joins Boarding's queue (the boats bring them).
func _fleet_crew() -> void:
	if game.corsair == null or not game.corsair.enabled:
		return
	var n := 0
	for g: Dictionary in boss_def["fleet_crew"]:
		for k in int(g["count"]):
			game.corsair.boarding.enqueue(String(g["kind"]), game.enemies.hp_mult, false, 1.0, false, false)
			n += 1
	game.stat_add("marrec_fleet_crew", float(n))


## Her pistol: one bullet at her target in range (every phase but the plank).
func _try_pistol() -> void:
	if _pistol_cd > 0.0 or not _target_valid():
		return
	var to := target.position - position
	if to.length() > float(boss_def["pistol_range"]) or to.length() < 1.0:
		return
	_pistol_cd = float(boss_def["pistol_every"])
	var dir := to.normalized()
	game.projectiles.fire_hostile(position + dir * radius, dir, float(boss_def["pistol_damage"]) * game.enemies.damage_mult * hit_mult(),
			projectile_speed, undead_damage_mult, Projectile.Kind.ENEMY_ARROW, MarrecData.PISTOL_SOURCE)
	motion_lunge(Vector2.ZERO, MotionData.POWER_SHOT)
	game.stat_add("boss_atk_pistol", 1.0)
	if game.corsair != null:
		game.corsair.play_sound("musket_shot", position, 0.2)


# =====================================================================================
# The Boarding: the plank, its hooks, the fall
# =====================================================================================

## She lays her plank (two hooks at the rail), or swings across on a rope
## after max_falls falls.
func _start_plank() -> void:
	form = 2
	if _falls >= int(boss_def["max_falls"]):
		game.stat_add("marrec_rope_swings", 1.0)
		_board_done(true)
		return
	_clear_hooks()
	var n := Vector2(0.0, float(_side))
	var along := Vector2(1.0, 0.0)
	for sgn: float in [-1.0, 1.0]:
		var at := _rail_at - n * 9.0 + along * sgn * float(boss_def["hook_spread"])
		var hook := game.enemies.spawn_routed(CorsairEnemyData.HOOK, at, game.enemies.hp_mult, false)
		hook.is_objective = true  # It stands until cut (never recycled).
		_hooks.append([hook, hook.generation])
	_set_phase(Phase.PLANK)
	game.enemies.show_banner(String(boss_def["plank_banner"]))
	game.stat_add("boss_atk_plank", 1.0)
	game.stat_add("marrec_planks", 1.0)
	if game.corsair != null:
		game.corsair.play_sound("plank_drop", _rail_at, 0.3)


## One tick on the plank: she crosses; both hooks cut -> the plank falls.
func _step_plank() -> void:
	var standing := 0
	for h: Array in _hooks:
		if _alive(h[0], int(h[1])):
			standing += 1
	if standing == 0:
		_plank_falls()
		return
	var k := clampf(phase_time / maxf(0.1, float(boss_def["plank_time"])), 0.0, 1.0)
	position = _ship_at.lerp(_rail_at, k)
	if k >= 1.0:
		_board_done(true)


## THE PLANK FALLS: her marines drown, she falls in the sea and pays for it.
func _plank_falls() -> void:
	_falls += 1
	var drowned := 0
	for g: Dictionary in boss_def["marines"]:
		drowned += int(g["count"])
	game.stat_add("marrec_marines_drowned", float(drowned))
	game.stat_add("marrec_plank_falls", 1.0)
	game.stat_add("boss_atk_plank_fall", 1.0)
	game.enemies.show_banner(String(boss_def["fall_banner"]))
	game.effects.ring(position, 34.0, Palette.CORSAIR_FOAM, 0.5)
	if game.corsair != null:
		game.corsair.play_sound("splash", position, 0.2)
	_clear_hooks()
	_set_phase(Phase.FALLEN)
	game.combat.damage_enemy(self, max_hp * float(boss_def["fall_share"]), MarrecData.FALL_SOURCE)


## She steps aboard (with her marines when `marines`): the duel begins.
func _board_done(marines: bool) -> void:
	form = 3
	_set_water(false)
	_clear_hooks()
	if game.deck != null:
		position = game.deck.clamp_point(_rail_at - Vector2(0.0, float(_side)) * 36.0, radius)
	if marines and game.deck != null:
		var made := _spawn_group(boss_def["marines"], position, -Vector2(0.0, float(_side)))
		game.stat_add("marrec_marines_aboard", float(made))
	_lunge_cd = float(boss_def["lunge_every"]) * 0.5
	game.stat_add("marrec_aboard_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["aboard_banner"]))
	if game.corsair != null:
		game.corsair.play_sound("plank_drop", position, 0.3)
	_set_phase(Phase.WALK)


## Spawns `groups` ({kind, count}) in a short line at `at`, a little toward
## `inward`; returns how many came.
func _spawn_group(groups: Array, at: Vector2, inward: Vector2) -> int:
	var kinds: Array[String] = []
	for g: Dictionary in groups:
		for k in int(g["count"]):
			kinds.append(String(g["kind"]))
	var side := inward.orthogonal()
	var made := 0
	for i in kinds.size():
		var p := at + inward * 24.0 + side * (float(i) - float(kinds.size() - 1) * 0.5) * 26.0
		if game.enemies.spawn_at(kinds[i], p, false) != null:
			made += 1
	return made


## Takes her plank hooks off the field.
func _clear_hooks() -> void:
	for h: Array in _hooks:
		if _alive(h[0], int(h[1])):
			game.enemies.despawn(h[0])
	_hooks.clear()


# =====================================================================================
# The duel: the rapier lunge
# =====================================================================================

## Starts a lunge at the nearest necromancer within lunge_range (false when none).
func _start_lunge() -> bool:
	if game.ultimates.player_untargetable():
		return false
	var pl := game.nearest_player(position)
	var to := pl.position - position
	var dist := to.length()
	if dist > float(boss_def["lunge_range"]) or dist < 1.0:
		return false
	_lunge_cd = float(boss_def["fever_lunge_every"] if form == 4 else boss_def["lunge_every"])
	_lunge_from = position
	_lunge_to = position + to.normalized() * minf(dist + 30.0, float(boss_def["lunge_range"]) + 30.0)
	if game.deck != null:
		_lunge_to = game.deck.clamp_point(_lunge_to, radius)
	game.effects.telegraph_line(_lunge_from, _lunge_to, float(boss_def["lunge_width"]), float(boss_def["lunge_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_lunge", 1.0)
	game.stat_add("marrec_lunges", 1.0)
	_set_phase(Phase.LUNGE_WINDUP)
	return true


## One tick of the lunge: she runs along the lane, hitting each body once.
func _step_lunge(delta: float) -> void:
	var to := _lunge_to - position
	var step := float(boss_def["lunge_speed"]) * delta
	var from := position
	if to.length() <= step:
		position = _lunge_to
	else:
		position += to.normalized() * step
	var seg := position - from
	if seg.length() > 0.5:
		var s := game.enemies.damage_mult * hit_mult()
		game.stat_add("marrec_lunge_hits", float(OlympusHits.lane(game, from, seg.normalized(), seg.length(), float(boss_def["lunge_width"]),
				float(boss_def["lunge_damage"]) * s, float(boss_def["lunge_damage_summon"]) * s * undead_damage_mult, MarrecData.LUNGE_SOURCE, self, _struck, _buf)))
	if position.distance_to(_lunge_to) < 1.0 or phase_time > 1.2:
		if game.corsair != null:
			game.corsair.play_sound("cutlass_slash", position, 0.2)
		_set_phase(Phase.RECOVER)


# =====================================================================================
# Gold Fever: the cursed coins and the quarterdeck
# =====================================================================================

## Gold Fever: the coins, her last marines, the retreat to the quarterdeck.
func _gold_fever() -> void:
	form = 4
	game.stat_add("marrec_fever_at", game.elapsed)
	game.stat_add("boss_atk_gold_fever", 1.0)
	game.enemies.show_banner(String(boss_def["fever_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.CORSAIR_BRASS)
	game.shake(5.0)
	_coin_cd = 0.0
	if game.deck != null:
		_spawn_group(boss_def["fever_marines"], position, Vector2.LEFT)
		_set_phase(Phase.RETREAT)


## Runs to the quarterdeck (at most retreat_time s), then duels there.
func _step_retreat(delta: float) -> void:
	var deck := game.deck
	var to_at := Vector2(deck.center.x - deck.half_length + float(boss_def["quarterdeck_in"]), deck.center.y)
	var to := to_at - position
	if to.length() < 12.0 or phase_time >= float(boss_def["retreat_time"]):
		_lunge_cd = minf(_lunge_cd, 1.0)
		_set_phase(Phase.WALK)
		return
	velocity = to.normalized() * _base_speed * float(boss_def["retreat_speed_mult"])
	position += velocity * delta
	position = deck.clamp_point(game.arena.free_point(position, radius), radius)
	_tick_timers(delta)


## A scatter of cursed coins round her (seeded places, on the deck).
func _scatter_coins() -> void:
	_coin_cd = float(boss_def["coin_every"])
	var i := 0
	while i < _coins.size():
		if not _alive(_coins[i][0], int(_coins[i][1])):
			_coins.remove_at(i)
			continue
		i += 1
	var n := int(boss_def["coins"])
	var made := 0
	for k in n:
		var at := position + Vector2.from_angle(randf() * TAU) * float(boss_def["coin_spread"]) * (0.3 + 0.7 * randf())
		if game.deck != null:
			at = game.deck.clamp_point(at, 8.0)
		var c := game.enemies.spawn_at(GalleonEnemyData.COIN, at, false)
		if c != null:
			_coins.append([c, c.generation])
			made += 1
	game.stat_add("coins_dropped", float(made))
	game.stat_add("boss_atk_coins", 1.0)
	if game.corsair != null:
		game.corsair.play_sound("coin_chime", position, 0.3)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: sideways out of her lunge's lane.
func danger_push(p: Vector2) -> Vector2:
	if phase != Phase.LUNGE_WINDUP and phase != Phase.LUNGE:
		return Vector2.ZERO
	var d := _lunge_to - _lunge_from
	var length := d.length()
	if length < 1.0:
		return Vector2.ZERO
	var dir := d / length
	var rel := p - _lunge_from
	var along := rel.dot(dir)
	if along < -20.0 or along > length + 20.0:
		return Vector2.ZERO
	var perp := dir.orthogonal()
	var across := rel.dot(perp)
	var half := float(boss_def["lunge_width"]) * 0.5 + DANGER_MARGIN
	if absf(across) >= half:
		return Vector2.ZERO
	return perp * (signf(across) if absf(across) > 0.5 else 1.0) * (1.0 - absf(across) / half) * 2.5


## Her sprite key (the engine's motion pivot; walk and idle strips).
func motion_sprite_key() -> String:
	return MarrecData.SPRITE


## Body layer on `ci`: her sprite (pose 1 while she aims or settles a lunge,
## when the art has one), else the Black Tide's code glyph.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if phase == Phase.LUNGE_WINDUP else 0
	if not SpriteBank.draw_pose(ci, MarrecData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		if not SpriteBank.draw(ci, MarrecData.SPRITE, Vector2.ZERO, flash > 0.0):
			CorsairGlyphs.draw_enemy(ci, "swashbuckler", Vector2.ZERO, radius, flash > 0.0)


## Under layer: her flagship's deck under her (the Fleet, the fall) and her
## plank to the rail (the Boarding).
func _draw_under() -> void:
	super._draw_under()
	if form > 2:
		return
	draw_set_transform_matrix(CourtGlyphs.unmirror_xf(self))  # World-axis offsets (the node is mirrored to face her walk).
	if phase == Phase.SHIP or phase == Phase.FALLEN:
		var ship := _ship_at - position + Vector2(0.0, float(_side)) * 30.0
		if not SpriteBank.draw_flat(self, GalleonData.SHIP_SPRITE, ship, 0.0, Color(0.95, 0.9, 0.85), 2.0):
			draw_rect(Rect2(ship - Vector2(120.0, 30.0), Vector2(240.0, 60.0)), Palette.CORSAIR_OAK_DARK)
	if phase == Phase.PLANK:
		var a := _ship_at - position
		var b := _rail_at - position
		draw_line(a, b, Palette.CORSAIR_INK, 9.0)
		draw_line(a, b, Palette.CORSAIR_OAK_LIGHT, 6.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var ab := float(st.get("marrec_aboard_at", -1.0))
	var fv := float(st.get("marrec_fever_at", -1.0))
	return "the Fleet: broadsides %d, crew sent %d | the Boarding: planks %d, falls %d (marines drowned %d), rope swings %d, aboard %s (marines %d) | lunges %d (hits %d), pistol %d | Gold Fever %s: coins %d (cleared %d, faded %d, barriers %d, her cut %d) | dmg to you %d, to summons %d | slain %s" % [
		int(st.get("boss_atk_broadside", 0.0)), int(st.get("marrec_fleet_crew", 0.0)), int(st.get("marrec_planks", 0.0)),
		int(st.get("marrec_plank_falls", 0.0)), int(st.get("marrec_marines_drowned", 0.0)), int(st.get("marrec_rope_swings", 0.0)),
		EmpireReport._clock(ab) if ab >= 0.0 else "never", int(st.get("marrec_marines_aboard", 0.0)),
		int(st.get("marrec_lunges", 0.0)), int(st.get("marrec_lunge_hits", 0.0)), int(st.get("boss_atk_pistol", 0.0)),
		EmpireReport._clock(fv) if fv >= 0.0 else "not reached", int(st.get("coins_dropped", 0.0)), int(st.get("coins_cleared", 0.0)),
		int(st.get("coins_faded", 0.0)), int(st.get("coin_shields", 0.0)), int(st.get("marrec_coin_cut", 0.0)),
		int(st.get("player_dmg_from_" + MarrecData.PISTOL_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + MarrecData.LUNGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + MarrecData.PISTOL_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + MarrecData.LUNGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0)),
		"yes" if float(st.get(MarrecData.SLAIN_STAT, 0.0)) > 0.0 else "no"]
