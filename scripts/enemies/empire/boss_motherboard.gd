## BossMotherboard — THE MOTHERBOARD, the boss of the Assembly Halls (Act III,
## Stage 8; GDD §15.0 "The Assembly Halls (Act III phase 2)"; owner-approved
## proposal: "the factory's construction titan, mother of every soldier on the
## line, with two crane arms. It grabs your summons and hurls them, drops
## press-stamps on telegraphed squares, magnet-pulls the army out of the ring,
## and builds turrets mid-fight"). Loaded by name for the boss id "motherboard"
## (EnemyDirector.EMPIRE_BOSS_DIR + "boss_motherboard.gd"); it boots at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat it
## like any enemy. Every special is telegraphed; numbers in MotherboardData.BOSS:
##   * Crane Grab   — each crane arm aims at a summon within grab_reach px (a
##                    claw line for grab_telegraph s), seizes it if it is still
##                    in reach (the one hold path, SummonedUnit.compel()), lifts
##                    it for grab_lift s and hurls it at the necromancer's spot
##                    (a warning-red landing circle, hurl_flight s): the landing
##                    hurts him if he stayed, the summons it lands among, and the
##                    hurled summon itself (hurl_self_share of its max HP).
##   * Press-Stamp  — stamp_count telegraphed squares (one on the necromancer,
##                    the others on the army near him), then the press falls
##                    (MotherboardHazards).
##   * Magnet Pull  — Full Load (below load_hp): its coils charge
##                    magnet_telegraph s, then for magnet_duration s every summon
##                    within magnet_radius px is dragged toward it at
##                    magnet_speed px/s: the army is pulled out of the Bone Ring.
##   * Build Turrets — Full Load: construction frames rise around it for
##                    build_telegraph s, then build_count Motherboard Turrets
##                    (AssemblyEnemyData "motherboard_turret": fixed guns firing
##                    through EmpireShots, Line of Fire) up to build_max standing.
##   * Overclock    — below overclock_hp: shorter gaps, stamp_count_overclock
##                    squares.
## Specials are chosen by weight among the ready, usable ones of its phase
## (seeded RNG); between them it rolls at the necromancer (faster beyond
## advance_range) and strikes in reach. It shrugs off knockback. A MACHINE: no
## corpse. Its turrets go dark when it falls. Slaying it unlocks Hollow Puppet,
## Strings of the Dead and the Grave Drone class with Overclock (UnlockData,
## boss "motherboard"). Stats: boss_atk_<special>, motherboard_grabs (summons
## seized), motherboard_grab_misses, motherboard_hurl_player_hits,
## motherboard_hurl_summon_hits, motherboard_magnet_pulls (summon-ticks),
## motherboard_turrets_built, motherboard_load_at, motherboard_overclock_at.
class_name BossMotherboard
extends Boss

## Boss attack phases.
enum Phase { WALK, GRAB_AIM, GRAB_LIFT, HURL, STAMP_WINDUP, MAGNET_WINDUP, MAGNET_PULL, BUILD_WINDUP, RECOVER }

## Local offsets (px, before mirroring) of the two crane arms' shoulders.
const SHOULDERS := [Vector2(-30, -46), Vector2(30, -46)]
## Height (px) above the boss's centre where a lifted summon hangs.
const LIFT_HEIGHT: float = 70.0

## Current phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.5
## True once it went to Full Load.
var loaded: bool = false
## True once it overclocked.
var overclocked: bool = false
## Its world-hazards layer (stamps, landings, turret frames).
var hazards: MotherboardHazards = null
## Crane arm targets of the current grab: [SummonedUnit, generation] per arm
## (an empty Array = that arm has no target).
var arm_targets: Array = [[], []]
## Summons the arms hold: [SummonedUnit, generation, start position] per arm
## ([] = empty claw).
var arm_held: Array = [[], []]
## Where the current hurl lands (world px).
var hurl_at: Vector2 = Vector2.ZERO
## Where the turrets of the current build rise (world px; the hazards layer
## only draws their frames).
var _build_spots: Array[Vector2] = []
## Turrets it built that may still stand: [Enemy, generation].
var turrets: Array = []
## Special id -> seconds until it may be chosen again.
var _special_cds: Dictionary = {}
## Last special used (not chosen twice in a row when another is ready).
var _last_special: String = ""
## Move speed it walks at (px/s).
var _base_speed: float = 24.0


## Sets up the Motherboard at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MotherboardData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	special_cd = float(boss_def["first_special"])
	loaded = false
	overclocked = false
	_base_speed = move_speed
	arm_targets = [[], []]
	arm_held = [[], []]
	turrets.clear()
	for id: String in MotherboardData.SPECIALS:
		_special_cds[id] = 0.0
	if hazards == null:
		hazards = MotherboardHazards.new()
		game.enemies.add_child(hazards)
		hazards.setup(game, self)


## Its specials in report order (Boss hook).
func special_ids() -> Array:
	return MotherboardData.SPECIALS


## True while it rolls at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of its art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/motherboard"


## Picks the next special when ready; otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	match _choose_special():
		"grab":
			_start_grab()
		"stamp":
			_start_stamp()
		"magnet":
			_start_magnet()
		"build":
			_start_build()


## Weighted choice among its phase's specials that are ready and usable now
## ("" when none is).
func _choose_special() -> String:
	var dist := position.distance_to(game.player.position)
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id: String in (MotherboardData.LOADED_SPECIALS if loaded else MotherboardData.ONLINE_SPECIALS):
		if float(_special_cds[id]) > 0.0 or not _usable(id, dist):
			continue
		ids.append(id)
		weights.append(float(boss_def[id + "_weight"]))
	if ids.size() > 1 and ids.has(_last_special):
		var i := ids.find(_last_special)
		ids.remove_at(i)
		weights.remove_at(i)
	if ids.is_empty():
		return ""
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in ids.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ids[i]
	return ids[ids.size() - 1]


## Whether special `id` makes sense with the necromancer `dist` px away.
func _usable(id: String, dist: float) -> bool:
	match id:
		"grab":
			return not _grab_candidates().is_empty()
		"stamp":
			return dist <= float(boss_def["stamp_range"])
		"magnet":
			return _summons_within(float(boss_def["magnet_radius"])) >= 3
		"build":
			return _turrets_alive() < int(boss_def["build_max"])
	return true


## Boss physics: inherited walk / melee while walking, otherwise specials.
func physics_step(delta: float) -> void:
	phase_time += delta
	for id: String in MotherboardData.SPECIALS:
		_special_cds[id] = float(_special_cds[id]) - delta
	knockback = Vector2.ZERO
	hazards.step(delta)
	if not loaded and hp <= max_hp * float(boss_def["load_hp"]):
		_go_loaded()
	if not overclocked and hp <= max_hp * float(boss_def["overclock_hp"]):
		_go_overclock()
	match phase:
		Phase.WALK:
			special_cd -= delta
			var spd := _base_speed
			if position.distance_to(game.player.position) > float(boss_def["advance_range"]):
				spd *= float(boss_def["advance_speed_mult"])
				game.stat_add("boss_advance_time", delta)
			move_speed = spd
			super.physics_step(delta)
		Phase.GRAB_AIM:
			_hold(delta)
			if phase_time >= float(boss_def["grab_telegraph"]):
				_seize()
		Phase.GRAB_LIFT:
			_hold(delta)
			_carry_held(1.0)
			if phase_time >= float(boss_def["grab_lift"]):
				_throw()
		Phase.HURL:
			_hold(delta)
			_carry_held(1.0 - clampf(phase_time / maxf(0.01, float(boss_def["hurl_flight"])), 0.0, 1.0))
			if phase_time >= float(boss_def["hurl_flight"]):
				_land_hurl()
				_set_phase(Phase.RECOVER)
		Phase.STAMP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["stamp_telegraph"]):
				_set_phase(Phase.RECOVER)
		Phase.MAGNET_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["magnet_telegraph"]):
				Sfx.play("magnet_pull", position)
				_set_phase(Phase.MAGNET_PULL)
		Phase.MAGNET_PULL:
			_hold(delta)
			_pull(delta)
			if phase_time >= float(boss_def["magnet_duration"]):
				_set_phase(Phase.RECOVER)
		Phase.BUILD_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["build_telegraph"]):
				_raise_turrets()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_end_special()
				_set_phase(Phase.WALK)


## Standing still during a windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	if p == Phase.RECOVER and game != null:
		motion_lunge(game.player.position - position, MotionData.POWER_MELEE)  # Engine motion: the strike lands.
	queue_redraw()


## Starts special `id`: bookkeeping shared by every special.
func _begin_special(id: String, next_phase: Phase) -> void:
	_last_special = id
	_special_cds[id] = float(boss_def[id + "_cooldown"])
	game.stat_add("boss_atk_" + id, 1.0)
	_set_phase(next_phase)


## Sets the gap before the next special (shorter once overclocked).
func _end_special() -> void:
	var gap := float(boss_def["attack_gap"])
	if overclocked:
		gap *= float(boss_def["overclock_gap_mult"])
	special_cd = gap


## Full Load: the magnet and the turret builds join its specials.
func _go_loaded() -> void:
	loaded = true
	game.stat_add("motherboard_load_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["load_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("boss_arrive", position, 0.9)


## Overclock: faster, more stamps.
func _go_overclock() -> void:
	overclocked = true
	game.stat_add("motherboard_overclock_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["overclock_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.EMPIRE_SIGNAL_RED)
	Sfx.play("boss_arrive", position, 1.1)


## Number of living, grounded summons within `r` px of it.
func _summons_within(r: float) -> int:
	game.ally_grid.query(position, r, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and not u.airborne and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(position) <= r:
			n += 1
	return n


## The summons a crane arm may seize (in reach, on the ground, not already
## compelled), nearest first, at most grab_arms of them.
func _grab_candidates() -> Array:
	var reach := float(boss_def["grab_reach"])
	game.ally_grid.query(position, reach, _tmp)
	var cands: Array = []
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.is_compelled():
			continue
		var dist := u.position.distance_to(position)
		if dist <= reach:
			cands.append([dist, u])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var out: Array = []
	for k in mini(int(boss_def["grab_arms"]), cands.size()):
		out.append(cands[k][1])
	return out


# =====================================================================================
# Crane Grab and the hurl
# =====================================================================================

## Crane Grab: each arm aims a claw at a summon.
func _start_grab() -> void:
	var picks := _grab_candidates()
	arm_targets = [[], []]
	arm_held = [[], []]
	for i in picks.size():
		var u: SummonedUnit = picks[i]
		arm_targets[i] = [u, u.generation]
		game.effects.telegraph_line(position + _shoulder(i), u.position, 10.0, float(boss_def["grab_telegraph"]), self)
	Sfx.play("crane_whir", position)
	_begin_special("grab", Phase.GRAB_AIM)


## World position of arm `i`'s shoulder (the sprite faces its movement).
func _shoulder(i: int) -> Vector2:
	var s: Vector2 = SHOULDERS[i]
	return Vector2(s.x * scale.x, s.y)


## The claws close: every target still in reach is seized and held (compel()).
func _seize() -> void:
	var reach := float(boss_def["grab_reach"]) + float(boss_def["grab_slack"])
	var hold_for := float(boss_def["grab_lift"]) + float(boss_def["hurl_flight"]) + 0.3  # s it stays compelled.
	var any := false
	for i in 2:
		var t: Array = arm_targets[i]
		if t.is_empty():
			continue
		var u: SummonedUnit = t[0]
		if not u.active or u.generation != int(t[1]) or u.position.distance_to(position) > reach or u.airborne:
			game.stat_add("motherboard_grab_misses", 1.0)
			continue
		if u.compel(position, game.elapsed + hold_for, 0.0):
			arm_held[i] = [u, u.generation, u.position]
			game.stat_add("motherboard_grabs", 1.0)
			any = true
	arm_targets = [[], []]
	if any:
		Sfx.play("crane_clamp", position)
		_set_phase(Phase.GRAB_LIFT)
	else:
		_set_phase(Phase.RECOVER)


## Keeps the held summons on their claws: lifted over the titan (k = 1) or
## flying from there to the landing point (k from 1 to 0).
func _carry_held(k: float) -> void:
	for i in 2:
		var h: Array = arm_held[i]
		if h.is_empty():
			continue
		var u: SummonedUnit = h[0]
		if not u.active or u.generation != int(h[1]):
			arm_held[i] = []
			continue
		var hang := position + _shoulder(i) + Vector2(0.0, -LIFT_HEIGHT * 0.4)  # Where it hangs from the claw.
		if phase == Phase.GRAB_LIFT:
			u.position = (h[2] as Vector2).lerp(hang, clampf(phase_time / maxf(0.01, float(boss_def["grab_lift"])), 0.0, 1.0))
		else:
			u.position = hurl_at.lerp(hang, k) + Vector2(float(i * 2 - 1) * 10.0, 0.0) * (1.0 - k)
		u.velocity = Vector2.ZERO


## The arms swing: the held summons fly at the necromancer's spot.
func _throw() -> void:
	var to_p := game.player.position - position
	hurl_at = position + to_p.limit_length(float(boss_def["hurl_max_throw"]))
	hazards.add_landing(hurl_at, float(boss_def["hurl_flight"]))
	Sfx.play("crane_throw", position)
	motion_lunge(to_p, MotionData.POWER_MELEE)
	_set_phase(Phase.HURL)


## The hurled summons land: the necromancer if he stayed, the summons they
## land among, and the hurled summons themselves are hurt.
func _land_hurl() -> void:
	var r := float(boss_def["hurl_radius"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x its buffs.
	var thrown: Array[SummonedUnit] = []
	for i in 2:
		var h: Array = arm_held[i]
		if h.is_empty():
			continue
		var u: SummonedUnit = h[0]
		if u.active and u.generation == int(h[1]):
			u.position = game.arena.free_point(u.position, u.radius)
			u.compel_until = game.elapsed  # Released where it fell.
			thrown.append(u)
	arm_held = [[], []]
	if thrown.is_empty():
		return
	game.effects.impact(hurl_at, r * 1.2, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("press_stamp", hurl_at, 1.2)
	game.shake(5.0)
	for p in game.all_players:  # (Co-op: every necromancer inside.)
		if p.position.distance_to(hurl_at) <= r + p.radius:
			game.combat.damage_player(float(boss_def["hurl_damage_player"]) * mult * float(thrown.size()), MotherboardData.HURL_SOURCE, p)
			game.stat_add("motherboard_hurl_player_hits", 1.0)
	game.ally_grid.query(hurl_at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(hurl_at) > r + u.radius:
			continue
		if u in thrown:
			game.combat.damage_unit(u, u.max_hp * float(boss_def["hurl_self_share"]), MotherboardData.HURL_SOURCE)
		else:
			game.combat.damage_unit(u, float(boss_def["hurl_damage_summon"]) * mult, MotherboardData.HURL_SOURCE)
			game.stat_add("motherboard_hurl_summon_hits", 1.0)


# =====================================================================================
# Press-Stamp, Magnet Pull, Build Turrets
# =====================================================================================

## Press-Stamp: squares on the necromancer and on the army near him.
func _start_stamp() -> void:
	var p := game.player.position
	var n := int(boss_def["stamp_count_overclock"] if overclocked else boss_def["stamp_count"])
	var scatter := float(boss_def["stamp_scatter"])
	var side := float(boss_def["stamp_size"])
	var spots: Array[Vector2] = [p]
	game.ally_grid.query(p, scatter, _tmp)
	for u: SummonedUnit in _tmp:
		if spots.size() >= n:
			break
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var clear := true
		for s in spots:
			clear = clear and (absf(s.x - u.position.x) >= side or absf(s.y - u.position.y) >= side)
		if clear:
			spots.append(u.position)
	var tries := 0
	while spots.size() < n and tries < n * 4:
		tries += 1
		var at := p + Vector2.from_angle(randf() * TAU) * randf_range(side, scatter)
		var clear := true
		for s in spots:
			clear = clear and (absf(s.x - at.x) >= side or absf(s.y - at.y) >= side)
		if clear:
			spots.append(at)
	for s in spots:
		hazards.add_stamp(s.round())
	Sfx.play("press_charge", position)
	_begin_special("stamp", Phase.STAMP_WINDUP)


## Magnet Pull: its coils charge.
func _start_magnet() -> void:
	game.effects.ring(position, float(boss_def["magnet_radius"]), Palette.EMPIRE_SIGNAL_RED, float(boss_def["magnet_telegraph"]))
	game.enemies.show_banner("The Motherboard magnetises the floor: your army is dragged out of the ring!")
	Sfx.play("press_charge", position, 0.7)
	_begin_special("magnet", Phase.MAGNET_WINDUP)


## One tick of the pull: every grounded summon in reach slides toward it.
func _pull(delta: float) -> void:
	var r := float(boss_def["magnet_radius"])
	var speed := float(boss_def["magnet_speed"])
	game.ally_grid.query(position, r, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		var to := position - u.position
		var dist := to.length()
		var stop := radius + u.radius + float(boss_def["magnet_stop"])
		if dist > r or dist <= stop:
			continue
		u.position += to / dist * minf(speed * delta, dist - stop)
		n += 1
	game.stat_add("motherboard_magnet_pulls", float(n))
	queue_redraw()


## Build Turrets: construction frames rise around it.
func _start_build() -> void:
	var n := mini(int(boss_def["build_count"]), int(boss_def["build_max"]) - _turrets_alive())
	_build_spots.clear()
	var base_angle := (game.player.position - position).angle()  # The guns face the necromancer's side.
	for i in n:
		var a := base_angle + (float(i) - float(n - 1) * 0.5) * 1.1
		var at := game.arena.free_point(position + Vector2.from_angle(a) * float(boss_def["build_distance"]), 14.0)
		hazards.add_frame(at, float(boss_def["build_telegraph"]))
		_build_spots.append(at)
	Sfx.play("fabricate", position, 0.8)
	_begin_special("build", Phase.BUILD_WINDUP)


## The frames finish: turrets rise where they stood.
func _raise_turrets() -> void:
	for at in _build_spots:
		_spawn_turret(at)
	_build_spots.clear()
	hazards.frames.clear()


## Spawns one Motherboard Turret at `at` (never recycled: an objective).
func _spawn_turret(at: Vector2) -> void:
	if _turrets_alive() >= int(boss_def["build_max"]):
		return
	var t := game.enemies.spawn_at(AssemblyEnemyData.MB_TURRET, at, false)
	t.is_objective = true
	turrets.append([t, t.generation])
	game.effects.spawn_ring(t.position, Palette.EMPIRE_SIGNAL_AMBER)
	game.stat_add("motherboard_turrets_built", 1.0)


## Its turrets still standing.
func _turrets_alive() -> int:
	var n := 0
	var i := turrets.size() - 1
	while i >= 0:
		var rec: Array = turrets[i]
		var t: Enemy = rec[0]
		if t.active and t.generation == int(rec[1]):
			n += 1
		else:
			turrets.remove_at(i)
		i -= 1
	return n


## Its turrets go dark and its claws let go when it falls (EnemyDirector pools
## nothing here: a boss is never pooled).
func deactivate() -> void:
	for i in 2:
		var h: Array = arm_held[i]
		if not h.is_empty():
			var u: SummonedUnit = h[0]
			if u.active and u.generation == int(h[1]):
				u.compel_until = game.elapsed
	arm_held = [[], []]
	for rec: Array in turrets:
		var t: Enemy = rec[0]
		if t.active and t.generation == int(rec[1]):
			game.effects.pop(t.position, Palette.EMPIRE_SIGNAL_AMBER, t.radius * 1.4)
			game.enemies.despawn(t)
	turrets.clear()
	if hazards != null:
		hazards.clear()
	super.deactivate()


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the stamps and landings, and
## away from it while its magnet charges.
func danger_push(p: Vector2) -> Vector2:
	var push := hazards.danger_push(p) if hazards != null else Vector2.ZERO
	return push


## Ground layer: the magnet's rings while it charges / pulls.
func _draw_under() -> void:
	if phase == Phase.MAGNET_WINDUP or phase == Phase.MAGNET_PULL:
		AssemblyGlyphs.draw_magnet(self, Vector2.ZERO, float(boss_def["magnet_radius"]) * (0.35 if phase == Phase.MAGNET_WINDUP else 1.0), fmod(phase_time * 1.5, 1.0), phase == Phase.MAGNET_PULL)


## Body layer on `ci`: the titan in the pose of its phase (BossPoseData: 1
## winding up a special, 3 the strike / throw).
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.GRAB_AIM, Phase.STAMP_WINDUP, Phase.MAGNET_WINDUP, Phase.MAGNET_PULL, Phase.BUILD_WINDUP, Phase.GRAB_LIFT:
			pose = 1
		Phase.HURL, Phase.RECOVER:
			pose = 3
	if overclocked:
		ci.draw_circle(Vector2.ZERO, radius * 1.6, Color(Palette.EMPIRE_SIGNAL_RED, 0.14))
	if SpriteBank.draw_pose(ci, "bosses/motherboard", pose, Vector2.ZERO, flash > 0.0):
		return
	_draw_fallback(ci)


## Code-drawn titan when its art is missing: a chrome chassis with a circuit
## board front and a screen face.
func _draw_fallback(ci: CanvasItem) -> void:
	var r := radius
	var body := Rect2(Vector2(-r, -r * 1.3), Vector2(r * 2.0, r * 1.9))
	ci.draw_rect(body.grow(2.0), AssemblyGlyphs.INK)
	ci.draw_rect(body, Glyphs._c(Palette.EMPIRE_CHROME, flash > 0.0))
	ci.draw_rect(Rect2(body.position + Vector2(6, 8), Vector2(body.size.x - 12, body.size.y * 0.45)), Glyphs._c(Color(0.06, 0.22, 0.14), flash > 0.0))
	for k in 5:
		var y := body.position.y + 12.0 + float(k) * 6.0
		ci.draw_line(Vector2(body.position.x + 10, y), Vector2(body.end.x - 10, y), Color(Palette.EMPIRE_SIGNAL_AMBER, 0.7), 1.0)
	ci.draw_rect(Rect2(Vector2(-r * 0.5, -r * 1.7), Vector2(r, r * 0.45)), AssemblyGlyphs.INK)
	ci.draw_rect(Rect2(Vector2(-r * 0.4, -r * 1.62), Vector2(r * 0.8, r * 0.3)), Palette.EMPIRE_SIGNAL_RED)
	ci.draw_rect(Rect2(Vector2(-r * 1.1, r * 0.55), Vector2(r * 2.2, r * 0.35)), AssemblyGlyphs.INK)


## Overlay layer on `ci`: the crane arms and claws (aiming, holding, throwing)
## and the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	for i in 2:
		var root := _shoulder(i)
		var claw := root + Vector2(float(i * 2 - 1) * 14.0, 26.0)  # Resting claw.
		var open := true
		var t: Array = arm_targets[i]
		var h: Array = arm_held[i]
		if phase == Phase.GRAB_AIM and not t.is_empty():
			var u: SummonedUnit = t[0]
			if u.active:
				claw = root.lerp(u.position - position, clampf(phase_time / maxf(0.01, float(boss_def["grab_telegraph"])), 0.0, 1.0))
		elif not h.is_empty():
			var u: SummonedUnit = h[0]
			if u.active:
				claw = u.position - position + Vector2(0, -u.radius - 6.0)
				open = false
		AssemblyGlyphs.draw_claw(ci, root, claw, open)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of its fight.
static func summary_line(st: Dictionary) -> String:
	var load_at := float(st.get("motherboard_load_at", -1.0))
	var oc := float(st.get("motherboard_overclock_at", -1.0))
	return "grabs %d (summons seized %d, missed %d, hurls hit you %d, hit summons %d) | stamps %d (hit you %d, summons %d) | magnets %d (summon-ticks pulled %d) | turret builds %d (turrets %d, shots %d) | full load %s | overclock %s | dmg to player %d, summons %d" % [
		int(st.get("boss_atk_grab", 0.0)), int(st.get("motherboard_grabs", 0.0)), int(st.get("motherboard_grab_misses", 0.0)),
		int(st.get("motherboard_hurl_player_hits", 0.0)), int(st.get("motherboard_hurl_summon_hits", 0.0)),
		int(st.get("boss_atk_stamp", 0.0)), int(st.get("motherboard_stamp_player_hits", 0.0)), int(st.get("motherboard_stamp_summon_hits", 0.0)),
		int(st.get("boss_atk_magnet", 0.0)), int(st.get("motherboard_magnet_pulls", 0.0)),
		int(st.get("boss_atk_build", 0.0)), int(st.get("motherboard_turrets_built", 0.0)), int(st.get("mb_turret_shots", 0.0)),
		("at %d:%02d" % [floori(load_at / 60.0), int(load_at) % 60]) if load_at >= 0.0 else "no",
		("at %d:%02d" % [floori(oc / 60.0), int(oc) % 60]) if oc >= 0.0 else "no",
		int(st.get("player_dmg_from_" + MotherboardData.STAMP_SOURCE, 0.0) + st.get("player_dmg_from_" + MotherboardData.HURL_SOURCE, 0.0) + st.get("player_dmg_from_boss", 0.0) + st.get("player_dmg_from_motherboard_turret", 0.0)),
		int(st.get("summon_dmg_from_" + MotherboardData.STAMP_SOURCE, 0.0) + st.get("summon_dmg_from_" + MotherboardData.HURL_SOURCE, 0.0) + st.get("summon_dmg_from_boss", 0.0) + st.get("summon_dmg_from_motherboard_turret", 0.0))]
