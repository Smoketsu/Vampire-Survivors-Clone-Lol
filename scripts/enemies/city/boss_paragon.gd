## BossParagon — PARAGON, THE LAST HERO, the boss of Liberty Heights and of Act
## VIII (the Last Line; GDD §15.0 "Paragon, the Last Hero (Act VIII)";
## owner-approved proposal: "the strongest man alive. The Hero (flight,
## heat-vision beams that cut lines through the ring, a punch that sends a
## summon across the arena), Hope (every Super still alive in the run flies
## in to his side: kill them earlier and this phase is short), No Restraint
## (he stops holding back: the sky turns white, and he dives from orbit on
## telegraphed craters that crack the arena)"). Loaded by name for the boss id
## "paragon" (EnemyDirector.CITY_BOSS_DIR + "boss_paragon.gd"); he arrives at
## 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy. Every number is ParagonData.BOSS's; the phases
## and their rules are documented in ParagonData. Every attack is an enemy
## effect: the punch's flight moves a summon through the held hook (the one
## place: _step_fling()), the heat vision strikes through damage_unit() /
## damage_player(), the craters are CityShells (THE landing-circle path). The
## shared rules are created on first use (Game.city_rules()), so --boss=paragon
## works on any stage (Hope then calls the stage's roster: none off Act VIII
## unless a STAGE names one; the cracks need LibertyHeightsDirector).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Hero's Fist and Secret Identity, the Fallen Hero and Origin Story
## (UnlockData, boss "paragon"). NO MORE HEROES (ParagonData) is counted in
## _on_defeated(). Attack pose (BossPoseData, when the art has one): pose 1
## while his eyes burn or he winds up the punch.
## Determinism: no RNG (the biggest summon, ties in the spatial hash's order;
## the extra craters on fixed angles). Stats: boss_atk_<special>,
## paragon_heat_hits, paragon_heat_on_you, paragon_punch_hits,
## paragon_flung_px, paragon_hope_called, paragon_hope_time,
## paragon_hope_at, paragon_restraint_at, paragon_craters,
## paragon_no_heroes_kills, paragon_kill_time.
class_name BossParagon
extends Boss

## His phases.
enum Phase { ARRIVING, HERO, HOPE, RESTRAINT }
## His action within a phase.
enum Act { NONE, HEAT_WINDUP, HEAT, PUNCH_WINDUP, LANDED, DIVE_UP, DIVE_DOWN }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Current action.
var act: Act = Act.NONE
## Seconds in the current phase.
var phase_time: float = 0.0
## Seconds in the current action.
var act_time: float = 0.0
## Seconds until his next heat vision.
var heat_cd: float = 0.0
## Seconds until his next punch.
var punch_cd: float = 0.0
## Seconds until his next dive from orbit (No Restraint).
var dive_cd: float = INF
## Unit directions of the heat-vision lines (locked at the windup).
var _beams: Array[Vector2] = []
## Where the beams start (world px; locked at the windup).
var _beam_from: Vector2 = Vector2.ZERO
## The punch's target summon (null when none).
var _prey: SummonedUnit = null
## Pool generation of `_prey`.
var _prey_gen: int = 0
## The summon flying across the arena: [unit, generation, from, to, t] (empty
## when none).
var _flung: Array = []
## Hope's Supers (generation-checked).
var _allies: Array[Enemy] = []
## Pool generation of each entry of `_allies`.
var _ally_gens: PackedInt32Array = PackedInt32Array()
## Supers Hope called (-1 = Hope has not begun).
var hope_called: int = -1
## Where the dive lands (world px; the main crater).
var _dive_at: Vector2 = Vector2.ZERO
## Every crater of the current dive (world px; the cracks).
var _craters: Array[Vector2] = []
## The white sky of No Restraint (null before; never headless).
var _sky: ParagonSky = null
## His walking speed (px/s) of the current phase.
var _base_speed: float = 62.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Paragon at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ParagonData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	act = Act.NONE
	phase_time = 0.0
	act_time = 0.0
	heat_cd = float(boss_def["heat_first"])
	punch_cd = float(boss_def["punch_first"])
	dive_cd = INF
	_prey = null
	_flung.clear()
	_allies.clear()
	_ally_gens.clear()
	hope_called = -1
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	flies = true
	game.city_rules().play_sound("super_arrive", position)  # The shared rules exist wherever he fights.
	game.enemies.boss_defeated.connect(_on_defeated)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return ParagonData.SPECIALS


## True while he flies or walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.HERO or phase == Phase.RESTRAINT) and act == Act.NONE


## His fall (or any removal) lets a flung summon go and fades the sky.
func deactivate() -> void:
	_let_go()
	if _sky != null:
		_sky.release()  # It fades out and frees itself.
		_sky = null
	super.deactivate()


## Immune while he descends, during Hope while a Super stands at his side (or
## its short echo), and while he climbs into orbit; his health never falls
## past Hope's threshold before Hope begins. In flight a grounded melee blow
## deals aloft_melee_taken of itself.
func damage_taken_mult(source: String) -> float:
	match phase:
		Phase.ARRIVING, Phase.HOPE:
			return 0.0
		Phase.HERO:
			if hp <= max_hp * float(boss_def["hope_hp"]) + 1.0:
				return 0.0
	if act == Act.DIVE_UP:
		return 0.0
	var m := super.damage_taken_mult(source)
	if flies and FallenAngelKit.grounded_melee(source):
		game.stat_add("paragon_aloft_grazed", 1.0)
		m *= float(boss_def["aloft_melee_taken"])
	return m


# =====================================================================================
# Physics
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	act_time += delta
	knockback = Vector2.ZERO
	_step_fling(delta)
	match phase:
		Phase.ARRIVING:
			_hold(delta)
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.HERO)
		Phase.HERO:
			_step_fight(delta)
			if hp <= max_hp * float(boss_def["hope_hp"]) + 1.0 and (act == Act.NONE or act == Act.LANDED):
				_begin_hope()
		Phase.HOPE:
			_step_hope(delta)
		Phase.RESTRAINT:
			_step_fight(delta)


## Starts phase `p`.
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	act = Act.NONE
	act_time = 0.0
	queue_redraw()


## Starts action `a`.
func _do(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


## Standing still during a windup or recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## The Hero and No Restraint: fly at the necromancer, then heat vision, the
## punch (the Hero) or the dive (No Restraint) when ready.
func _step_fight(delta: float) -> void:
	heat_cd -= delta
	punch_cd -= delta
	dive_cd -= delta
	match act:
		Act.HEAT_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["heat_windup"]):
				_fire_heat()
				_do(Act.HEAT)
			return
		Act.HEAT:
			_hold(delta)
			if act_time >= float(boss_def["heat_time"]):
				_do(Act.NONE)
			return
		Act.PUNCH_WINDUP:
			_tick_timers(delta)
			if _prey_ok():
				var to := _prey.position - position
				var reach := radius + _prey.radius + 2.0
				if to.length() > reach:
					position += to.normalized() * minf(to.length() - reach, _base_speed * 4.0 * delta)
			velocity = Vector2.ZERO
			if act_time >= float(boss_def["punch_windup"]):
				_punch()
			return
		Act.LANDED:
			if act_time >= float(boss_def["land_time"]):
				flies = true
				_do(Act.NONE)
			else:
				super.physics_step(delta)  # Landed: he walks and strikes; every blow on him lands.
			return
		Act.DIVE_UP:
			_hold(delta)
			if act_time >= float(boss_def["dive_rise"]):
				_dive_mark()
				_do(Act.DIVE_DOWN)
			return
		Act.DIVE_DOWN:
			_hold(delta)
			if act_time >= float(boss_def["dive_windup"]):
				_dive_land()
				_do(Act.NONE)
			return
	_walk(delta)
	if game.ultimates.player_untargetable():
		return
	if phase == Phase.RESTRAINT and dive_cd <= 0.0:
		_start_dive()
	elif heat_cd <= 0.0:
		_start_heat()
	elif phase == Phase.HERO and punch_cd <= 0.0:
		_start_punch()


## Flies at the necromancer (the shared walk and melee; faster from afar).
func _walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)


# =====================================================================================
# The Hero: heat vision and the punch
# =====================================================================================

## His eyes glow: heat_lines lines lock, one at the necromancer.
func _start_heat() -> void:
	heat_cd = float(boss_def["heat_every_p3"] if phase == Phase.RESTRAINT else boss_def["heat_every"])
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_beam_from = position
	_beams.clear()
	var n := int(boss_def["heat_lines"])
	var spread := float(boss_def["heat_spread"])
	for i in n:
		var off := float((i + 1) / 2) * spread * (1.0 if i % 2 == 1 else -1.0)  # 0, +s, -s, +2s, ... (the first on him).
		_beams.append(Vector2.from_angle(dir.angle() + off))
	for b in _beams:
		game.effects.telegraph_line(_beam_from, _beam_from + b * float(boss_def["heat_length"]), float(boss_def["heat_width"]) * 2.0, float(boss_def["heat_windup"]), self)
	game.stat_add("boss_atk_heat_vision", 1.0)
	motion_lunge(dir, MotionData.POWER_CAST)
	game.city_rules().play_sound("weakness_crack", position, 0.3)
	_do(Act.HEAT_WINDUP)


## The beams burn: every summon and necromancer on a line is struck once.
func _fire_heat() -> void:
	var mult := game.enemies.damage_mult * hit_mult() * _p3_mult()
	var reach := float(boss_def["heat_length"])
	var w := float(boss_def["heat_width"])
	var hit: Array = []
	for b in _beams:
		var a := _beam_from
		var c := _beam_from + b * reach
		game.ally_grid.query(a + b * reach * 0.5, reach * 0.5 + w + UnitData.MAX_BLOCK_RADIUS, _buf)
		for u: SummonedUnit in _buf:
			if hit.has(u) or not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
				continue
			if _seg_dist(u.position, a, c) <= w + u.radius:
				hit.append(u)
				game.combat.damage_unit(u, float(boss_def["heat_damage_summon"]) * mult * undead_damage_mult, ParagonData.SRC_HEAT, self)
				game.stat_add("paragon_heat_hits", 1.0)
		for pl in game.all_players:
			if hit.has(pl) or pl.dead:
				continue
			if _seg_dist(pl.position, a, c) <= w + pl.radius:
				hit.append(pl)
				game.combat.damage_player(float(boss_def["heat_damage_player"]) * mult, ParagonData.SRC_HEAT, pl, self)
				game.stat_add("paragon_heat_on_you", 1.0)
	game.shake(2.0)


## Distance (px) from `p` to the segment `a`-`b`.
static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## The punch: the biggest summon in reach (by max HP); he dives at it.
func _start_punch() -> void:
	punch_cd = float(boss_def["punch_every"])
	var reach := float(boss_def["punch_reach"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var best: SummonedUnit = null
	for u: SummonedUnit in _buf:
		if not NightjarKit._grabbable(u) or u.position.distance_to(position) > reach + u.radius:
			continue
		if best == null or u.max_hp > best.max_hp:
			best = u
	if best == null:
		punch_cd = 1.5  # Nothing in reach: soon again.
		return
	_prey = best
	_prey_gen = best.generation
	game.effects.telegraph_circle(best.position, best.radius + 14.0, float(boss_def["punch_windup"]), self)
	game.stat_add("boss_atk_punch", 1.0)
	_do(Act.PUNCH_WINDUP)


## True while the punch's target is the summon he picked, alive.
func _prey_ok() -> bool:
	return _prey != null and _prey.active and _prey.generation == _prey_gen and _prey.state != SummonedUnit.State.DEAD


## The punch lands: the summon is struck and flies across the arena; he lands.
func _punch() -> void:
	if _prey_ok() and position.distance_to(_prey.position) <= radius + _prey.radius + 30.0:
		var u := _prey
		var mult := game.enemies.damage_mult * hit_mult() * _p3_mult()
		var dir := (u.position - position).normalized() if u.position.distance_to(position) > 1.0 else Vector2.RIGHT
		game.combat.damage_unit(u, float(boss_def["punch_damage"]) * mult * undead_damage_mult, ParagonData.SRC_PUNCH, self)
		game.stat_add("paragon_punch_hits", 1.0)
		game.effects.impact(u.position, 28.0, Palette.IVORY)
		game.shake(5.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			_let_go()
			var to := game.arena.free_point(u.position + dir * float(boss_def["punch_throw"]), u.radius)
			_flung = [u, u.generation, u.position, to, 0.0]
			u.held_until = maxf(u.held_until, game.elapsed + float(boss_def["fling_time"]) + 0.1)
	_prey = null
	flies = false  # He lands after the blow: every blow on him lands in full.
	_do(Act.LANDED)


## THE one place that moves a flung summon: held, and carried along its line
## to the free point; dropped dazed when it lands.
func _step_fling(delta: float) -> void:
	if _flung.is_empty():
		return
	var u: SummonedUnit = _flung[0]
	if not u.active or u.generation != int(_flung[1]) or u.state == SummonedUnit.State.DEAD:
		_flung.clear()
		return
	_flung[4] = float(_flung[4]) + delta
	var k := clampf(float(_flung[4]) / maxf(float(boss_def["fling_time"]), 0.01), 0.0, 1.0)
	var from: Vector2 = _flung[2]
	var to: Vector2 = _flung[3]
	u.position = from.lerp(to, k)
	u.velocity = Vector2.ZERO
	u.held_until = maxf(u.held_until, game.elapsed + 0.1)
	if k >= 1.0:
		u.position = game.arena.free_point(to, u.radius)
		u.held_until = maxf(u.held_until, game.elapsed + float(boss_def["fling_daze"]))
		game.stat_add("paragon_flung_px", from.distance_to(u.position))
		game.effects.ring(u.position, u.radius * 2.0, Palette.IVORY, 0.3)
		_flung.clear()


## Lets a flung summon go where it is (he died or was pooled mid-flight).
func _let_go() -> void:
	if _flung.is_empty():
		return
	var u: SummonedUnit = _flung[0]
	if u.active and u.generation == int(_flung[1]):
		u.position = game.arena.free_point(u.position, u.radius)
		u.held_until = minf(u.held_until, game.elapsed)
	_flung.clear()


# =====================================================================================
# Hope
# =====================================================================================

## Hope begins: every roster Super not yet killed flies in to his side.
func _begin_hope() -> void:
	_enter(Phase.HOPE)
	flies = true
	_prey = null
	var ros := game.city_rules().supers
	var ids := ros.standing_roster()
	_allies.clear()
	_ally_gens.clear()
	var n := ids.size()
	for i in n:
		var at := position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * float(boss_def["hope_dist"])
		var e := ros.call_super(ids[i], at)
		if e == null:
			continue
		_allies.append(e)
		_ally_gens.append(e.generation)
	hope_called = _allies.size()
	game.stat_add("boss_atk_hope", 1.0)
	game.stats["paragon_hope_called"] = float(hope_called)
	game.stats["paragon_hope_at"] = game.elapsed
	game.effects.ring(position, 160.0, Palette.CITY_NEON_CYAN, 0.8)
	game.city_rules().play_sound("super_arrive", position)
	if hope_called > 0:
		game.enemies.show_banner("HOPE: Paragon calls, and %d hero%s fly to his side! While they stand, he cannot be harmed" % [hope_called, "" if hope_called == 1 else "es"])
	else:
		game.enemies.show_banner("HOPE: Paragon calls... and no hero is left to answer")


## Living Hope Supers now (stale entries dropped).
func allies_alive() -> int:
	var i := _allies.size() - 1
	while i >= 0:
		if not _allies[i].active or _allies[i].generation != _ally_gens[i]:
			_allies.remove_at(i)
			_ally_gens.remove_at(i)
		i -= 1
	return _allies.size()


## Hope: he hovers near the necromancer, immune, his eyes still burning; it
## ends when his Supers have fallen (at least hope_min s, at most hope_max s).
func _step_hope(delta: float) -> void:
	heat_cd -= delta
	match act:
		Act.HEAT_WINDUP:
			_hold(delta)
			if act_time >= float(boss_def["heat_windup"]):
				_fire_heat()
				_do(Act.HEAT)
		Act.HEAT:
			_hold(delta)
			if act_time >= float(boss_def["heat_time"]):
				_do(Act.NONE)
		_:
			var to := game.player.position - position
			var keep := 200.0  # px he hovers from the necromancer while his heroes fight.
			if to.length() > keep + 10.0:
				position += to.normalized() * minf(to.length() - keep, _base_speed * delta)
			velocity = Vector2.ZERO
			_tick_timers(delta)
			if heat_cd <= 0.0 and not game.ultimates.player_untargetable():
				_start_heat()
	var done := phase_time >= float(boss_def["hope_min"]) and allies_alive() == 0
	if (done or phase_time >= float(boss_def["hope_max"])) and act == Act.NONE:
		game.stats["paragon_hope_time"] = phase_time
		_no_restraint()


# =====================================================================================
# No Restraint
# =====================================================================================

## No Restraint: the sky turns white; he is faster and harder; the dives begin.
func _no_restraint() -> void:
	_enter(Phase.RESTRAINT)
	game.stat_add("boss_atk_no_restraint", 1.0)
	game.stats["paragon_restraint_at"] = game.elapsed
	_base_speed = float(boss_def["move_speed"]) * float(boss_def["p3_speed_mult"])
	damage = float(boss_def["damage"]) * float(boss_def["p3_damage_mult"])
	dive_cd = float(boss_def["dive_first"])
	heat_cd = minf(heat_cd, 2.0)
	game.enemies.show_banner("NO RESTRAINT: Paragon stops holding back! The sky turns white")
	game.effects.impact(position, radius * 4.0, Palette.IVORY)
	game.shake(8.0)
	if DisplayServer.get_name() != "headless" and _sky == null:
		_sky = ParagonSky.new(game, self, float(boss_def["sky_fade"]), float(boss_def["sky_alpha"]))
		game.add_child(_sky)


## No Restraint's damage multiplier (1 before it).
func _p3_mult() -> float:
	return float(boss_def["p3_damage_mult"]) if phase == Phase.RESTRAINT else 1.0


## He climbs into orbit (out of sight, immune).
func _start_dive() -> void:
	dive_cd = float(boss_def["dive_every"])
	game.stat_add("boss_atk_dive", 1.0)
	game.effects.ring(position, 40.0, Palette.IVORY, 0.4)
	game.city_rules().play_sound("super_arrive", position, 0.3)
	_do(Act.DIVE_UP)


## From orbit: the craters show (CityShells), the first on the necromancer.
func _dive_mark() -> void:
	var rules := game.city_rules()
	var p := game.player.position
	_dive_at = game.arena.free_point(p, radius)
	_craters.clear()
	_craters.append(_dive_at)
	var dmg := float(boss_def["dive_damage"]) * game.enemies.damage_mult * hit_mult()
	rules.shells.add(_dive_at, float(boss_def["dive_windup"]), float(boss_def["dive_radius"]), dmg, ParagonData.SRC_DIVE, false)
	var n := int(boss_def["dive_extra"])
	var base := float(game.stats.get("boss_atk_dive", 0.0)) * 0.9  # A fixed turn per dive (no RNG).
	for i in n:
		var at := p + Vector2.from_angle(base + TAU * float(i) / float(maxi(1, n))) * float(boss_def["extra_dist"])
		_craters.append(at)
		rules.shells.add(at, float(boss_def["dive_windup"]) + 0.15 * float(i + 1), float(boss_def["extra_radius"]), dmg, ParagonData.SRC_DIVE, false)
	position = _dive_at  # He comes down where the first crater lands (drawn falling).


## He lands: the craters crack the arena.
func _dive_land() -> void:
	position = game.arena.free_point(_dive_at, radius)
	game.effects.impact(position, float(boss_def["dive_radius"]), Palette.IVORY)
	game.shake(9.0)
	var lh: LibertyHeightsDirector = game.enemies.liberty_heights
	for i in _craters.size():
		game.stat_add("paragon_craters", 1.0)
		if lh != null:
			lh.add_crack(_craters[i], float(boss_def["dive_radius"] if i == 0 else boss_def["extra_radius"]), int(boss_def["crack_max"]))


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the
## ending text, and NO MORE HEROES when no Super stood at his side.
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 240.0, Palette.IVORY, 1.0)
	game.effects.ring(pos, 140.0, Palette.CITY_POLICE_BLUE, 0.8)
	Juice.fx.burst(pos, Palette.IVORY, Palette.CITY_POLICE_BLUE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var late := game.countdown_finished()  # He fell during Martial Law.
	game.enemies.show_banner(String(ParagonData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + ParagonData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = ParagonData.LATE_ANNOUNCE if late else ParagonData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.IVORY)
	game.stats["paragon_kill_time"] = game.elapsed - _spawn_time
	var none_at_side := hope_called == 0 or (hope_called < 0 and game.city_rules().supers.standing_roster().is_empty())
	if none_at_side and String(game.stage_def.get("id", "")) == LibertyHeightsStage.ID:
		game.stat_add("paragon_no_heroes_kills", 1.0)  # No More Heroes (MetaData; MetaProgress counts it).
	if _sky != null:
		_sky.release()


## Danger hint for the autotest autopilot: sideways off his heat-vision lines
## while they show and burn (the craters are CityShells').
func danger_push(p: Vector2) -> Vector2:
	if act == Act.HEAT_WINDUP or act == Act.HEAT:
		var out := Vector2.ZERO
		for b in _beams:
			out += KirinKit._off_line(p, _beam_from, _beam_from + b * float(boss_def["heat_length"]), float(boss_def["heat_width"]) + 22.0)
		return out
	return Vector2.ZERO


## Body layer on `ci`: his sprite (pose 1 while his eyes burn or he winds up
## the punch), high above while he climbs into orbit and falling as he dives.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if act == Act.HEAT_WINDUP or act == Act.HEAT or act == Act.PUNCH_WINDUP else 0
	var lift := Vector2(0.0, -6.0) if flies else Vector2.ZERO
	if act == Act.DIVE_UP:
		var k := clampf(act_time / maxf(float(boss_def["dive_rise"]), 0.01), 0.0, 1.0)
		if k > 0.7:
			return  # Out of sight, in orbit.
		lift = Vector2(0.0, -360.0 * k)
	elif act == Act.DIVE_DOWN:
		var k := clampf(act_time / maxf(float(boss_def["dive_windup"]), 0.01), 0.0, 1.0)
		if k < 0.5:
			return  # Still in orbit: only the craters show.
		lift = Vector2(0.0, -260.0 * (1.0 - (k - 0.5) * 2.0))
	elif phase == Phase.ARRIVING:
		var k := clampf(phase_time / maxf(float(boss_def["arrive_time"]), 0.01), 0.0, 1.0)
		lift = Vector2(0.0, -200.0 * (1.0 - k))
	if not SpriteBank.draw_pose(ci, ParagonData.SPRITE, pose, lift, flash > 0.0):
		LibertyHeightsGlyphs.draw_paragon(ci, lift, radius, flash > 0.0)
	if act == Act.HEAT_WINDUP or act == Act.HEAT:
		SpriteBank.draw_disc(ci, lift + Vector2(0.0, -radius * 1.6), 4.0, Color(Palette.CITY_SIREN_RED, 0.85))


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: his shadow (it grows as he dives) and the burning beams.
func _draw_under() -> void:
	super._draw_under()
	if flies:
		var r := radius * 1.3
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, radius * 0.5), Vector2(r * 2.0, r * 0.8)), false, Color(0.0, 0.0, 0.0, 0.3))
	if act == Act.HEAT_WINDUP or act == Act.HEAT:
		var burning := act == Act.HEAT
		var xf := CourtGlyphs.unmirror_xf(self)
		for b in _beams:
			CityGlyphs.draw_headlights(self, _beam_from - position, b, float(boss_def["heat_length"]),
					float(boss_def["heat_width"]) * (1.0 if burning else 0.4), 0.85 if burning else 0.35, xf, Palette.CITY_SIREN_RED)
		draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var hope := float(st.get("paragon_hope_at", -1.0))
	var p3 := float(st.get("paragon_restraint_at", -1.0))
	return "heat vision %d (summon hits %d, on you %d) | punches %d (landed %d, flung %d px on average) | hope %s (supers called %d, lasted %ds) | no restraint %s (dives %d, craters %d) | aloft blows grazed %d | no more heroes %d | killed in %ds | dmg to you %d (heat %d, dives %d, blows %d), to summons %d" % [
		int(st.get("boss_atk_heat_vision", 0.0)), int(st.get("paragon_heat_hits", 0.0)), int(st.get("paragon_heat_on_you", 0.0)),
		int(st.get("boss_atk_punch", 0.0)), int(st.get("paragon_punch_hits", 0.0)),
		int(float(st.get("paragon_flung_px", 0.0)) / maxf(1.0, float(st.get("paragon_punch_hits", 0.0)))),
		EmpireReport._clock(hope) if hope >= 0.0 else "not reached", int(st.get("paragon_hope_called", 0.0)), int(st.get("paragon_hope_time", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("boss_atk_dive", 0.0)), int(st.get("paragon_craters", 0.0)),
		int(st.get("paragon_aloft_grazed", 0.0)), int(st.get("paragon_no_heroes_kills", 0.0)), int(st.get("paragon_kill_time", 0.0)),
		int(st.get("player_dmg_from_" + ParagonData.SRC_HEAT, 0.0)) + int(st.get("player_dmg_from_" + ParagonData.SRC_DIVE, 0.0)) + int(st.get("player_dmg_from_" + ParagonData.SRC_PUNCH, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("player_dmg_from_" + ParagonData.SRC_HEAT, 0.0)), int(st.get("player_dmg_from_" + ParagonData.SRC_DIVE, 0.0)), int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + ParagonData.SRC_HEAT, 0.0)) + int(st.get("summon_dmg_from_" + ParagonData.SRC_DIVE, 0.0)) + int(st.get("summon_dmg_from_" + ParagonData.SRC_PUNCH, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
