## BossDonMarrow — DON MARROW, THE KINGPIN, the boss of Skid Row (Act VIII,
## Stage 22; GDD §15.0 "Don Marrow, the Kingpin (Act VIII)"; owner-approved
## proposal: "the Bounty (he puts a price on the necromancer's head: gang spawns
## double while his bounty board is up; break the board to end it), the Call
## (he phones the police on you), the Last Stand (behind the limo's armour with
## a gold-plated minigun that sweeps the arena)"; the lead's call for the Call,
## owner's phase 2 answers of Nov 2, 2026: "the police and SWAT tiers arrive at
## once for the rest of his fight"). Loaded by name for the boss id
## "don_marrow" (EnemyDirector.CITY_BOSS_DIR + "boss_don_marrow.gd"); he arrives
## at 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy; his body radius stays within
## CityBlockData.MAX_BODY_RADIUS (the sprite is drawn larger). A male crime
## boss in a white suit with a gold cane. Every ability is telegraphed; numbers
## in DonMarrowData.BOSS. Three phases by his HP:
##   * THE BOUNTY: board_delay s after he arrives he raises his BOUNTY BOARD
##     (a bounty_board structure, a priority target, never recycled) board_dist
##     px from the necromancer on his side; SkidRowDirector doubles the gangs
##     while it stands (bounty_active(); the board is handed to it). He walks
##     in with the shared AI (his gold cane in reach) and fires his gold
##     REVOLVER: every revolver_every s, his target within revolver_range px, a
##     fan of revolver_shots bullets (tagged marrow_revolver, a ranged City
##     source). The board stands until it is broken (or he falls).
##   * THE CALL: he phones the police on you: from now until he falls a squad
##     of the police and SWAT tiers (call_squad; a squad car with every
##     call_car_every-th squad) comes in together on the spawn ring every
##     call_every s, under the hard cap. The escalation's badge does not change.
##   * THE LAST STAND: his limo rolls up and he fights from behind it: his cover
##     kit (MarrowCoverKit, the Armour rule's one path) cuts cover_front of
##     every hit from the ring's side (his front, kept on the nearest
##     necromancer); he pushes forward at last_speed and stops firing the
##     revolver for the gold MINIGUN: every sweep_every s a STREET LANE through
##     the necromancer (CityBlocks.lane(): the axis whose centre line is nearer
##     him; a straight line through him off the blocks) shows gold for
##     sweep_windup s, then a stream of fire runs along it from his end at
##     sweep_speed px/s for sweep_length px: every summon and necromancer within
##     sweep_half px of the line takes the sweep's damage once (Grave Step's
##     i-frames dodge it; so does stepping out of the lane).
## Killing him drops a big XP burst and the boss chest (EnemyDirector, from his
## boss_def) and takes his board down; slaying him unlocks Hearse Run and Black
## Car (UnlockData, boss "don_marrow"). Attack pose (BossPoseData, when the art
## has one): pose 1 while he aims the revolver or the minigun.
## Determinism: the seeded gameplay RNG only (the revolver's fan has none; the
## squads' ring angle). Stats: boss_atk_<special>, marrow_revolver_shots,
## marrow_calls, marrow_called, marrow_sweeps, marrow_sweep_hits,
## marrow_sweep_on_you, marrow_sweep_dodged, marrow_phase2_at,
## marrow_phase3_at, bounty_board_raised (the board's own stats in its kit).
class_name BossDonMarrow
extends Boss

## Boss action phases.
enum Phase { WALK, AIM, SWEEP_WINDUP, SWEEP, RECOVER }

## Seconds of the revolver's aiming pose before the fan fires.
const AIM_TIME: float = 0.35  # TUNING (not in GDD)
## px the autotest bot keeps beyond a minigun lane's edge (autotest hint only).
const DANGER_MARGIN: float = 26.0  # TUNING (not in GDD) autotest hint only

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His phase: 1 the Bounty, 2 the Call, 3 the Last Stand.
var form: int = 1
## Seconds until the board goes up (INF once raised).
var _board_cd: float = 0.0
## His bounty board (null before / after; generation-checked).
var _board: Enemy = null
## Pool generation of `_board`.
var _board_gen: int = 0
## Seconds until his next revolver fan.
var _revolver_cd: float = 0.0
## Seconds until his next called squad (INF before the Call).
var _call_cd: float = INF
## Squads called so far (the squad car with every call_car_every-th).
var _calls: int = 0
## Seconds until his next minigun sweep (INF before the Last Stand).
var _sweep_cd: float = INF
## Where the current sweep's lane starts (world px; locked at its windup).
var _lane_from: Vector2 = Vector2.ZERO
## The current sweep's direction along its lane (unit).
var _lane_dir: Vector2 = Vector2.RIGHT
## px the stream of fire has run along the lane (the sweep phase).
var _front: float = 0.0
## Bodies the current sweep already hit.
var _swept: Array = []
## Move speed of his current phase (px/s).
var _base_speed: float = 48.0
## Scratch buffer for grid queries.
var _buf: Array = []


## Sets up Don Marrow at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = DonMarrowData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	_board_cd = float(boss_def["board_delay"])
	_board = null
	_revolver_cd = float(boss_def["revolver_every"])
	_call_cd = INF
	_calls = 0
	_sweep_cd = INF
	_swept.clear()
	_base_speed = move_speed
	game.city_rules().play_sound("engine_rev", position)
	game.stat_add("boss_atk_bounty", 0.0)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return DonMarrowData.SPECIALS


## True while he walks (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## His fall (or any removal) takes the bounty board down with him.
func deactivate() -> void:
	if board_standing():
		game.enemies.despawn(_board)
	_board = null
	_swept.clear()
	super.deactivate()


## True while his bounty board stands (SkidRowDirector.bounty_active()).
func board_standing() -> bool:
	return _board != null and _board.active and _board.generation == _board_gen


## Boss physics: his phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	_board_cd -= delta
	_revolver_cd -= delta
	_call_cd -= delta
	_sweep_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_the_call()
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		_last_stand()
	if _board_cd <= 0.0:
		_raise_board()
	if _call_cd <= 0.0:
		_call_squad()
	if form == 3 and kit is MarrowCoverKit:
		(kit as MarrowCoverKit).face_toward(self, game.nearest_player(position).position)
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.AIM:
			_hold(delta)
			if phase_time >= AIM_TIME:
				_fire_revolver()
				_set_phase(Phase.RECOVER)
		Phase.SWEEP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["sweep_windup"]):
				_front = 0.0
				_swept.clear()
				game.stat_add("marrow_sweeps", 1.0)
				game.city_rules().play_sound("minigun", position, 0.3)
				_set_phase(Phase.SWEEP)
		Phase.SWEEP:
			_hold(delta)
			_step_sweep(delta)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)
	if form == 3 and kit is MarrowCoverKit:
		(kit as MarrowCoverKit).face_toward(self, game.nearest_player(position).position)


## Walking: the shared AI (his cane in reach) at his phase's speed; the
## revolver (the Bounty and the Call) or the minigun (the Last Stand) start
## when ready.
func _step_walk(delta: float) -> void:
	var pl := game.player
	var dist := position.distance_to(pl.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if form == 3:
		if _sweep_cd <= 0.0:
			_start_sweep()
	elif _revolver_cd <= 0.0 and _target_valid() and position.distance_to(target.position) <= float(boss_def["revolver_range"]):
		_revolver_cd = float(boss_def["revolver_every"])
		motion_lunge(Vector2.ZERO, MotionData.POWER_SHOT)
		_set_phase(Phase.AIM)


## Standing still during an aim, a windup or a recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# The Bounty: the board and the revolver
# =====================================================================================

## The board goes up board_dist px from the necromancer on his side (a
## priority target, never recycled); SkidRowDirector doubles the gangs while it
## stands.
func _raise_board() -> void:
	_board_cd = INF
	var pl := game.player
	var side := (position - pl.position).normalized() if position.distance_to(pl.position) > 1.0 else Vector2.RIGHT
	var row := game.enemies.enemy_def(DonMarrowData.BOARD)
	var at := game.arena.free_point(pl.position + side * float(boss_def["board_dist"]), float(row["radius"]))
	var e := game.enemies.spawn_at(DonMarrowData.BOARD, at, false)
	if e == null:
		return
	e.is_objective = true  # It stands until broken.
	_board = e
	_board_gen = e.generation
	var sr := game.enemies.skid_row  # Skid Row's director (null on another stage, --boss=don_marrow).
	if sr != null:
		sr.on_board_raised(e)
	game.stat_add("boss_atk_bounty", 1.0)
	game.stat_add("bounty_board_raised", 1.0)
	game.effects.ring(at, 40.0, Palette.GOLD, 0.5)
	game.enemies.show_banner(String(boss_def["bounty_banner"]))


## His gold revolver: a fan of bullets at his target.
func _fire_revolver() -> void:
	if not _target_valid():
		return
	var to := target.position - position
	if to.length() < 1.0:
		return
	var dir := to.normalized()
	var n := int(boss_def["revolver_shots"])
	var spread := float(boss_def["revolver_spread"])
	var dmg := float(boss_def["revolver_damage"]) * game.enemies.damage_mult * hit_mult()
	for i in n:
		var a := dir.angle() + (float(i) - float(n - 1) * 0.5) * spread
		game.projectiles.fire_hostile(position + dir * radius, Vector2.from_angle(a), dmg, projectile_speed, undead_damage_mult,
				Projectile.Kind.ENEMY_ARROW, DonMarrowData.REVOLVER_SOURCE)
	game.stat_add("boss_atk_revolver", 1.0)
	game.stat_add("marrow_revolver_shots", float(n))
	game.city_rules().play_sound("gun_burst", position, 0.2)


# =====================================================================================
# The Call: police and SWAT squads together
# =====================================================================================

## The Call: from now until he falls, the police and SWAT squads come.
func _the_call() -> void:
	form = 2
	game.stat_add("marrow_phase2_at", game.elapsed)
	game.stat_add("boss_atk_call", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.city_rules().play_sound("siren_wail", position)
	game.effects.impact(position, radius * 3.0, Palette.CITY_POLICE_BLUE)
	_call_cd = float(boss_def["call_first"])


## One squad of the police and SWAT tiers comes in together on the spawn ring.
func _call_squad() -> void:
	_call_cd = float(boss_def["call_every"])
	_calls += 1
	var a := randf() * TAU
	var c := game.enemies.ring_point(a)
	var side := Vector2.from_angle(a).orthogonal()
	var kinds: Array[String] = []
	for g: Dictionary in boss_def["call_squad"]:
		for k in int(g["count"]):
			kinds.append(String(g["kind"]))
	if _calls % maxi(1, int(boss_def["call_car_every"])) == 0:
		kinds.append(CityEnemyData.SQUAD_CAR)
	var made := 0
	var spread := float(boss_def["call_spread"])
	for i in kinds.size():
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := c + side * (float(i) - float(kinds.size() - 1) * 0.5) * spread
		if game.enemies.spawn_at(kinds[i], at, false) != null:
			made += 1
	game.stat_add("marrow_calls", 1.0)
	game.stat_add("marrow_called", float(made))
	game.city_rules().play_sound("siren_wail", c, 1.0)


# =====================================================================================
# The Last Stand: the limo's cover and the gold minigun
# =====================================================================================

## The Last Stand: the cover goes up, he slows, the minigun comes out.
func _last_stand() -> void:
	form = 3
	game.stat_add("marrow_phase3_at", game.elapsed)
	game.stat_add("boss_atk_last_stand", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.GOLD)
	game.shake(8.0)
	game.city_rules().play_sound("engine_rev", position)
	if kit is MarrowCoverKit:
		(kit as MarrowCoverKit).take_cover(float(boss_def["cover_front"]))
	_base_speed = float(boss_def["last_speed"])
	_sweep_cd = float(boss_def["first_sweep"])
	queue_redraw()


## The minigun's lane: a street through the necromancer (the axis whose centre
## line is nearer him), run from his end; a straight line through him off the
## blocks. The gold lane shows for sweep_windup s.
func _start_sweep() -> void:
	_sweep_cd = float(boss_def["sweep_every"])
	if game.ultimates.player_untargetable():
		_sweep_cd = 1.0
		return
	var pl := game.nearest_player(position)
	var length := float(boss_def["sweep_length"])
	var cb := game.arena.city_blocks
	var mid := pl.position  # The lane's middle (world px).
	var dir := Vector2.RIGHT
	if cb != null:
		var h := cb.lane(pl.position, Vector2.RIGHT)  # His horizontal street.
		var v := cb.lane(pl.position, Vector2.DOWN)  # His vertical street.
		var dh := absf(pl.position.y - float(h["centre"]))
		var dv := absf(pl.position.x - float(v["centre"]))
		var ln: Dictionary = h if dh <= dv else v
		mid = ln["point"]
		dir = ln["dir"]
		if (position - mid).dot(dir) > 0.0:
			dir = -dir  # The fire runs from his end of the street.
	else:
		var to := pl.position - position
		dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_lane_dir = dir
	_lane_from = mid - dir * length * 0.5
	game.effects.telegraph_line(_lane_from, _lane_from + dir * length, float(boss_def["sweep_half"]) * 2.0, float(boss_def["sweep_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_minigun", 1.0)
	_set_phase(Phase.SWEEP_WINDUP)


## One tick of the sweep: the stream of fire runs on and hits each body it
## passes once.
func _step_sweep(delta: float) -> void:
	var length := float(boss_def["sweep_length"])
	var prev := _front
	_front = minf(length, _front + float(boss_def["sweep_speed"]) * delta)
	var half := float(boss_def["sweep_half"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var mid := _lane_from + _lane_dir * (prev + _front) * 0.5  # The stretch swept this tick.
	var reach := (_front - prev) * 0.5 + half + UnitData.MAX_BLOCK_RADIUS
	var perp := Vector2(-_lane_dir.y, _lane_dir.x)
	game.ally_grid.query(mid, reach, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or _swept.has(u):
			continue
		var rel := u.position - _lane_from
		var along := rel.dot(_lane_dir)
		if along < prev - u.radius or along > _front + u.radius or absf(rel.dot(perp)) > half + u.radius:
			continue
		_swept.append(u)
		game.combat.damage_unit(u, float(boss_def["sweep_damage_summon"]) * mult * undead_damage_mult, DonMarrowData.MINIGUN_SOURCE, self)
		game.stat_add("marrow_sweep_hits", 1.0)
	for pl in game.all_players:
		if pl.dead or _swept.has(pl):
			continue
		var rel := pl.position - _lane_from
		var along := rel.dot(_lane_dir)
		if along < prev - pl.radius or along > _front + pl.radius or absf(rel.dot(perp)) > half + pl.radius:
			continue
		_swept.append(pl)
		var hp_before := pl.hp
		game.combat.damage_player(float(boss_def["sweep_damage"]) * mult, DonMarrowData.MINIGUN_SOURCE, pl, self)
		game.stat_add("marrow_sweep_on_you", 1.0)
		if pl.hp >= hp_before:
			game.stat_add("marrow_sweep_dodged", 1.0)  # Grave Step's i-frames (or a ward) took it.
	queue_redraw()
	if _front >= length:
		_swept.clear()
		_set_phase(Phase.RECOVER)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: sideways out of the minigun's lane
## while it shows or the fire has not yet passed him.
func danger_push(p: Vector2) -> Vector2:
	if phase != Phase.SWEEP_WINDUP and phase != Phase.SWEEP:
		return Vector2.ZERO
	var rel := p - _lane_from
	var along := rel.dot(_lane_dir)
	if along < (_front if phase == Phase.SWEEP else 0.0) - 20.0 or along > float(boss_def["sweep_length"]) + 20.0:
		return Vector2.ZERO
	var perp := Vector2(-_lane_dir.y, _lane_dir.x)
	var across := rel.dot(perp)
	var half := float(boss_def["sweep_half"]) + DANGER_MARGIN
	if absf(across) >= half:
		return Vector2.ZERO
	return perp * (signf(across) if absf(across) > 0.5 else 1.0) * (1.0 - absf(across) / half) * 2.5


## Body layer on `ci`: his sprite in the pose of his phase (pose 1 while he
## aims), and in the Last Stand his limo in front of him (the cover).
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if phase == Phase.AIM or phase == Phase.SWEEP_WINDUP or phase == Phase.SWEEP else 0
	if not SpriteBank.draw_pose(ci, DonMarrowData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		SkidRowGlyphs.draw_don(ci, radius, flash > 0.0, form == 3)
	if form == 3:
		var at := Vector2(radius * 0.9, radius * 0.7)  # In front of him (the node faces his walk), lower.
		if not SpriteBank.draw(ci, DonMarrowData.COVER_SPRITE, at, flash > 0.0):
			SkidRowGlyphs.draw_limo(ci, at, radius, flash > 0.0)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: the stream of fire along the swept stretch of the lane.
func _draw_under() -> void:
	super._draw_under()
	if phase == Phase.SWEEP and _front > 1.0:
		var xf := CourtGlyphs.unmirror_xf(self)
		CityGlyphs.draw_headlights(self, _lane_from - position, _lane_dir, _front, float(boss_def["sweep_half"]), 0.45, xf, Palette.CITY_HERO_ORANGE)
		draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("marrow_phase2_at", -1.0))
	var p3 := float(st.get("marrow_phase3_at", -1.0))
	return "the Bounty: board raised %d, broken %d (extra gangs %d) | revolver fans %d (bullets %d) | the Call %s: squads %d (%d soldiers) | the Last Stand %s: sweeps %d (hits on summons %d, on you %d, dodged %d) | cover cut %d | dmg to you %d, to summons %d" % [
		int(st.get("bounty_board_raised", 0.0)), int(st.get("bounty_board_broken", 0.0)), int(st.get("skid_row_bounty_gangs", 0.0)),
		int(st.get("boss_atk_revolver", 0.0)), int(st.get("marrow_revolver_shots", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("marrow_calls", 0.0)), int(st.get("marrow_called", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("marrow_sweeps", 0.0)), int(st.get("marrow_sweep_hits", 0.0)),
		int(st.get("marrow_sweep_on_you", 0.0)), int(st.get("marrow_sweep_dodged", 0.0)),
		int(st.get("armour_front_hits_boss", 0.0)),
		int(st.get("player_dmg_from_" + DonMarrowData.REVOLVER_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + DonMarrowData.MINIGUN_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + DonMarrowData.REVOLVER_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + DonMarrowData.MINIGUN_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
