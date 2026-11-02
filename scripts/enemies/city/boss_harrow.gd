## BossHarrow — GENERAL VANCE HARROW, "THE HAMMER", the boss of Fort Kessler
## (Act VIII, Stage 23; GDD §15.0 "General Vance Harrow, the Hammer (Act
## VIII)"; owner-approved proposal: "phase 1, he commands from a command
## vehicle and calls carpet-bombing lines across the arena; phase 2, a tank
## column and his own power armour; phase 3, Broken Arrow: he orders a strike
## on his own position, a 30 s countdown on screen"). Loaded by name for the
## boss id "harrow" (EnemyDirector.CITY_BOSS_DIR + "boss_harrow.gd"); he
## arrives at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat him like any enemy. Every ability is telegraphed; the
## numbers and the three phases are HarrowData's (see its header):
##   * COMMAND: the command vehicle keeps its distance; carpet-bombing lines
##     (CityShells, both sides) and rifle squads.
##   * THE HAMMER: the power armour (its front through city_armour_front() /
##     city_facing(), read by Armour.front_mult(), the act's one front test), the
##     hammer's slam (a landing circle, OlympusHits.circle()), the tank column
##     (tanks through the normal spawn path: the Convoy drives them).
##   * BROKEN ARROW: the 30 s countdown (broken_arrow_left(), shown as HUD text
##     by FortKesslerDirector.objective_override() and a banner every 10 s);
##     his death in time calls it off (the run stat HarrowData.STOPPED_STAT: the
##     achievement Broken Arrow); else THE STRIKE, _strike(), the one path.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks Bone
## Mines and Tripwire (UnlockData, boss "harrow"). No RNG (the carpet axis
## alternates; the squads and the column come in on angles from the game time).
## Stats: boss_atk_<special>, harrow_carpet_shells, harrow_squads,
## harrow_slam_hits, harrow_tanks, harrow_phase2_at, harrow_phase3_at,
## harrow_strike_at, harrow_strike_summons, harrow_strike_enemies,
## harrow_strike_dmg_you, harrow_strike_self, fort_kessler_broken_arrow.
class_name BossHarrow
extends Boss

## Boss action phases.
enum Phase { WALK, SLAM_WINDUP, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His form: 1 Command (the vehicle), 2 the Hammer, 3 Broken Arrow.
var form: int = 1
## Seconds until his next carpet-bombing line.
var carpet_cd: float = 0.0
## Seconds until his next rifle squad (Command only).
var squad_cd: float = 0.0
## Seconds until his next slam (the Hammer on).
var slam_cd: float = INF
## Seconds until his next tank column (the Hammer on).
var column_cd: float = INF
## Seconds left of Broken Arrow's countdown (-1 = none running).
var arrow_left: float = -1.0
## True once Broken Arrow's strike landed (no second one).
var struck: bool = false
## True once the strike broke his armour's front for good.
var armour_broken: bool = false
## The axis of his next carpet line (0 along x, 1 along y).
var _carpet_axis: int = 0
## Where the slam lands (world px; locked at its windup).
var _slam_at: Vector2 = Vector2.ZERO
## Countdown second of the next "Broken Arrow: n s" banner.
var _next_banner: float = INF
## His tank column (generation-checked).
var _tanks: Array[Enemy] = []
## Pool generation of each entry of `_tanks`.
var _tank_gens: PackedInt32Array = PackedInt32Array()
## Move speed of his current form (px/s).
var _base_speed: float = 52.0
## The facing of his power armour (unit; toward his foe, else his walk).
var _armour_facing: Vector2 = Vector2.RIGHT


## Sets up General Harrow at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = HarrowData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	carpet_cd = float(boss_def["first_carpet"])
	squad_cd = float(boss_def["squad_every"]) * 0.5
	slam_cd = INF
	column_cd = INF
	arrow_left = -1.0
	struck = false
	armour_broken = false
	_carpet_axis = 0
	_next_banner = INF
	_tanks.clear()
	_tank_gens.clear()
	_base_speed = move_speed
	_armour_facing = Vector2.RIGHT
	game.city_rules().play_sound("engine_rev", position)  # The City's rules exist wherever he fights (--boss=harrow elsewhere).
	game.enemies.show_banner(String(boss_def["command_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return HarrowData.SPECIALS


## True while he walks or drives (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK and form >= 2


## Seconds left of Broken Arrow's countdown (-1 when none runs): the HUD text
## (FortKesslerDirector.objective_override()).
func broken_arrow_left() -> float:
	return arrow_left if form == 3 and not struck else -1.0


## Armour's front share of his body (Armour.front_mult(), the act's one front
## test): his power armour's from the Hammer on, 0 in the vehicle and once the
## strike broke it.
func city_armour_front() -> float:
	return float(boss_def["armour_front"]) if form >= 2 and not armour_broken else 0.0


## His facing for Armour's front test (unit).
func city_facing() -> Vector2:
	return _armour_facing


## His fall: Broken Arrow is called off when it was still counting down.
func deactivate() -> void:
	if active and hp <= 0.0 and form == 3 and not struck and arrow_left > 0.0:
		game.stats[HarrowData.STOPPED_STAT] = 1.0
		game.stat_add("harrow_called_off_left", arrow_left)
		game.enemies.show_banner(String(boss_def["called_off_banner"]))
	arrow_left = -1.0
	super.deactivate()


## Boss physics: his forms and phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	carpet_cd -= delta
	squad_cd -= delta
	slam_cd -= delta
	column_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_hammer()
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		_broken_arrow()
	if form == 3 and not struck:
		arrow_left -= delta
		if arrow_left <= _next_banner and _next_banner > 0.0:
			game.enemies.show_banner(String(boss_def["countdown_banner"]) % roundi(_next_banner))
			game.city_rules().play_sound("broken_arrow", position, 1.0)
			_next_banner -= 10.0
		if arrow_left <= 0.0:
			_strike()
	if carpet_cd <= 0.0:
		_carpet_line()
	if form == 1 and squad_cd <= 0.0:
		_squad()
	if form >= 2 and column_cd <= 0.0:
		_column()
	_face()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.SLAM_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["slam_windup"]):
				_land_slam()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## His facing: toward his target, else along his walk.
func _face() -> void:
	if _target_valid():
		var to := target.position - position
		if to.length_squared() > 1.0:
			_armour_facing = to.normalized()
			return
	if velocity.length_squared() > 25.0:
		_armour_facing = velocity.normalized()


## Walking: the vehicle keeps its standoff (Command); on foot he walks at the
## necromancer (the shared walk and melee) and slams when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	if form == 1:
		if dist < float(boss_def["standoff_min"]):
			_hold(delta)  # The command vehicle stands off: he commands, he does not charge.
			return
		super.physics_step(delta)
		return
	super.physics_step(delta)
	if slam_cd <= 0.0 and _target_valid() and target.position.distance_to(position) <= float(boss_def["slam_reach"]):
		_start_slam()


## Standing still during a windup or recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# The forms
# =====================================================================================

## The Hammer: he climbs out of the vehicle in his power armour; the tanks roll.
func _hammer() -> void:
	form = 2
	game.stat_add("harrow_phase2_at", game.elapsed)
	game.stat_add("boss_atk_dismount", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.impact(position, radius * 2.5, Palette.CITY_OLIVE)
	game.city_rules().convoy.wreck_vehicle(self, 28.0)  # His command vehicle stays behind as a burning wreck (the Convoy's one wreck path).
	_base_speed = float(boss_def["hammer_speed"])
	slam_cd = float(boss_def["first_slam"])
	column_cd = float(boss_def["first_column"])
	carpet_cd = maxf(carpet_cd, float(boss_def["carpet_every_p2"]) * 0.5)
	queue_redraw()


## Broken Arrow: the strike is ordered; the countdown starts (HUD text only).
func _broken_arrow() -> void:
	form = 3
	arrow_left = float(boss_def["broken_arrow_time"])
	_next_banner = arrow_left - 10.0
	game.stat_add("harrow_phase3_at", game.elapsed)
	game.stat_add("boss_atk_broken_arrow", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.city_rules().play_sound("broken_arrow", position)
	carpet_cd = minf(carpet_cd, float(boss_def["carpet_every_p3"]))


## THE STRIKE (the ONE documented path of Broken Arrow's blast; see
## HarrowData): every necromancer left at strike_hp_left of his max HP (his
## i-frames cleared first: Grave Step does not dodge it; never lethal by
## itself), every summon in view of a necromancer at strike_summon_share of its
## max HP, every enemy there at strike_enemy_share of its max HP (never a
## civilian, a boss or a structure); Harrow loses strike_self_share of the HP
## he has left and his armour's front.
func _strike() -> void:
	struck = true
	arrow_left = -1.0
	game.stat_add("boss_atk_strike", 1.0)
	game.stat_add("harrow_strike_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["strike_banner"]))
	game.city_rules().play_sound("vehicle_wreck", position)
	var half := game.view_size() * 0.5 + Vector2.ONE * float(boss_def["strike_margin"])  # The view's half size, and a margin.
	var hit_units := {}  # Summons already hit (one blast each).
	var hit_enemies := {}  # Enemies already hit.
	var buf: Array = []
	for pl in game.all_players:
		var box := Rect2(pl.position - half, half * 2.0)
		game.ally_grid.query(pl.position, half.length(), buf)
		for u: SummonedUnit in buf.duplicate():
			if not u.active or u.state == SummonedUnit.State.DEAD or hit_units.has(u) or not box.has_point(u.position):
				continue
			hit_units[u] = true
			game.combat.damage_unit(u, u.max_hp * float(boss_def["strike_summon_share"]), HarrowData.STRIKE_SOURCE, self)
		game.enemy_grid.query(pl.position, half.length(), buf)
		for e: Enemy in buf.duplicate():
			if e == self or hit_enemies.has(e) or not CityRules.hits_enemy(e) or not box.has_point(e.position):
				continue
			hit_enemies[e] = true
			game.combat.damage_enemy(e, e.max_hp * float(boss_def["strike_enemy_share"]), HarrowData.STRIKE_SOURCE)
		game.effects.impact(pl.position, 260.0, Palette.CITY_HERO_ORANGE, "")
	game.stat_add("harrow_strike_summons", float(hit_units.size()))
	game.stat_add("harrow_strike_enemies", float(hit_enemies.size()))
	for pl in game.all_players:
		if pl.dead:
			continue
		var floor_hp := pl.max_hp * float(boss_def["strike_hp_left"])
		if pl.hp > floor_hp:
			var before := pl.hp
			pl.iframes = 0.0  # Grave Step does not dodge Broken Arrow.
			game.combat.damage_player(pl.hp - floor_hp, HarrowData.STRIKE_SOURCE, pl)
			game.stat_add("harrow_strike_dmg_you", maxf(0.0, before - pl.hp))
	var self_loss := hp * float(boss_def["strike_self_share"])
	hp -= self_loss
	armour_broken = true
	game.stat_add("harrow_strike_self", self_loss)
	game.shake(12.0)
	queue_redraw()


# =====================================================================================
# Command: the carpet lines and the squads
# =====================================================================================

## One carpet-bombing line along a street lane through the nearest
## necromancer's street (the axis alternates), both sides hurt.
func _carpet_line() -> void:
	var every := "carpet_every"
	if form == 2:
		every = "carpet_every_p2"
	elif form == 3:
		every = "carpet_every_p3"
	carpet_cd = float(boss_def[every])
	var pl := game.nearest_player(position)
	if pl == null or pl.dead:
		return
	var dir := Vector2.RIGHT if _carpet_axis == 0 else Vector2.DOWN
	_carpet_axis = 1 - _carpet_axis
	if (pl.position - position).dot(dir) < 0.0:
		dir = -dir  # The line walks away from him, through the necromancer.
	var through := pl.position
	var cb := game.arena.city_blocks
	if cb != null:
		var ln := cb.lane(pl.position, dir)
		dir = ln["dir"]
		through = ln["point"]
	var n := int(boss_def["carpet_shells"])
	var start := through - dir * float(boss_def["carpet_offset"])
	var dmg := float(boss_def["carpet_damage"]) * game.enemies.damage_mult * hit_mult()
	for k in n:
		game.city_rules().shells.add(start + dir * float(boss_def["carpet_spacing"]) * float(k),
				float(boss_def["carpet_warn"]) + float(boss_def["carpet_walk"]) * float(k), float(boss_def["carpet_radius"]),
				dmg, HarrowData.CARPET_SOURCE, true)
	game.stat_add("boss_atk_carpet", 1.0)
	game.stat_add("harrow_carpet_shells", float(n))
	game.city_rules().play_sound("carpet_call", position, 1.0)


## A rifle squad comes in on the spawn ring (Command only; under the hard cap).
func _squad() -> void:
	squad_cd = float(boss_def["squad_every"])
	var a := fmod(game.elapsed * 0.37, TAU)  # An angle from the game time (no RNG).
	var c := game.enemies.ring_point(a)
	var side := Vector2.from_angle(a).orthogonal()
	var n := int(boss_def["squad_count"])
	var made := 0
	for k in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		if game.enemies.spawn_at(CityEnemyData.RIFLEMAN, c + side * (float(k) - float(n - 1) * 0.5) * 22.0, false) != null:
			made += 1
	if made > 0:
		game.stat_add("boss_atk_squad", 1.0)
		game.stat_add("harrow_squads", 1.0)


# =====================================================================================
# The Hammer: the slam and the tank column
# =====================================================================================

## The slam: a landing circle where his target stands.
func _start_slam() -> void:
	slam_cd = float(boss_def["slam_every"])
	_slam_at = game.arena.free_point(target.position, 8.0)
	game.effects.telegraph_circle(_slam_at, float(boss_def["slam_radius"]), float(boss_def["slam_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_slam", 1.0)
	_set_phase(Phase.SLAM_WINDUP)


## The slam lands: every necromancer and summon in the circle is hit and the
## summons thrown out.
func _land_slam() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var buf: Array = []
	game.stat_add("harrow_slam_hits", float(OlympusHits.circle(game, _slam_at, float(boss_def["slam_radius"]),
			float(boss_def["slam_damage_player"]) * mult, float(boss_def["slam_damage_summon"]) * mult * undead_damage_mult,
			HarrowData.SLAM_SOURCE, self, float(boss_def["slam_push"]), buf)))
	game.effects.impact(_slam_at, float(boss_def["slam_radius"]), Palette.CITY_HAZARD)
	game.shake(5.0)


## A tank column rolls in along one street from the spawn ring (the Convoy
## drives them), at most column_cap of his standing.
func _column() -> void:
	column_cd = float(boss_def["column_every"])
	var i := _tanks.size() - 1
	while i >= 0:
		if not _tanks[i].active or _tanks[i].generation != _tank_gens[i]:
			_tanks.remove_at(i)
			_tank_gens.remove_at(i)
		i -= 1
	var n := mini(int(boss_def["column_count"]), int(boss_def["column_cap"]) - _tanks.size())
	if n <= 0:
		return
	var a := fmod(game.elapsed * 0.61, TAU)  # An angle from the game time (no RNG).
	var c := game.enemies.ring_point(a)
	var back := Vector2.from_angle(a)  # Outward from the necromancer: the column's tail.
	var made := 0
	for k in n:
		var e := game.enemies.spawn_at(CityEnemyData.TANK, c + back * float(boss_def["column_gap"]) * float(k), false)
		if e == null:
			continue
		_tanks.append(e)
		_tank_gens.append(e.generation)
		made += 1
	if made > 0:
		game.stat_add("boss_atk_column", 1.0)
		game.stat_add("harrow_tanks", float(made))
		game.city_rules().play_sound("engine_rev", c, 0.5)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the slam's landing circle
## (the carpet lines are CityShells', read through CityRules.danger_push()).
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.SLAM_WINDUP:
		var off := p - _slam_at
		var reach := float(boss_def["slam_radius"]) + 24.0
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	return Vector2.ZERO


## Body layer on `ci`: the command vehicle (Command), else his power armour
## (pose 1 while he winds up a slam); a red glow while Broken Arrow counts down.
func _draw_body(ci: CanvasItem) -> void:
	if form == 3 and not struck:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.2), radius * 1.4, Color(Palette.CITY_SIREN_RED, 0.18))
	if form == 1:
		if not SpriteBank.draw(ci, HarrowData.SPRITE_VEHICLE, Vector2.ZERO, flash > 0.0):
			FortKesslerGlyphs.draw_command_vehicle(ci, radius, flash > 0.0)
		return
	var pose := 1 if phase == Phase.SLAM_WINDUP else 0
	if not SpriteBank.draw_pose(ci, HarrowData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		FortKesslerGlyphs.draw_harrow(ci, radius, flash > 0.0, armour_broken)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("harrow_phase2_at", -1.0))
	var p3 := float(st.get("harrow_phase3_at", -1.0))
	var sa := float(st.get("harrow_strike_at", -1.0))
	return "carpet lines %d (shells %d, hits on summons %d, on you %d, on enemies %d) | rifle squads %d | the Hammer %s | slams %d (hits %d) | tank columns %d (tanks %d) | Broken Arrow %s | %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_carpet", 0.0)), int(st.get("harrow_carpet_shells", 0.0)),
		int(st.get("city_blast_hits_summons", 0.0)), int(st.get("city_blast_hits_you", 0.0)), int(st.get("city_blast_hits_enemies", 0.0)),
		int(st.get("harrow_squads", 0.0)), EmpireReport._clock(p2) if p2 >= 0.0 else "not reached",
		int(st.get("boss_atk_slam", 0.0)), int(st.get("harrow_slam_hits", 0.0)),
		int(st.get("boss_atk_column", 0.0)), int(st.get("harrow_tanks", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached",
		("CALLED OFF (%.1f s left)" % float(st.get("harrow_called_off_left", 0.0))) if float(st.get(HarrowData.STOPPED_STAT, 0.0)) > 0.0
			else (("STRUCK at %s: summons %d, enemies %d, your HP -%d, his HP -%d" % [EmpireReport._clock(sa), int(st.get("harrow_strike_summons", 0.0)),
				int(st.get("harrow_strike_enemies", 0.0)), int(st.get("harrow_strike_dmg_you", 0.0)), int(st.get("harrow_strike_self", 0.0))]) if sa >= 0.0 else "no strike"),
		int(st.get("player_dmg_from_" + HarrowData.CARPET_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + HarrowData.SLAM_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + HarrowData.STRIKE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + HarrowData.CARPET_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + HarrowData.SLAM_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + HarrowData.STRIKE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
