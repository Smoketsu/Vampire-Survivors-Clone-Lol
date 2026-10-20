## BossDeusExMachina — DEUS EX MACHINA, with VARN, THE ROOT USER, at its
## controls: the final boss of Act III and of the campaign (the Iron Citadel;
## StageRegistry boss id "deus_ex_machina", loaded by name by EnemyDirector from
## scripts/enemies/empire/boss_deus_ex_machina.gd; any stage's boss slot can send
## it with the autotest's --boss=deus_ex_machina). It arrives at 17:00 (3:00
## left) like every boss. All numbers are in DeusData.BOSS; its world hazards
## (footfall and stomp rings, overload pulses, the finale) in DeusHazards.
## Three phases (owner-approved proposal "The final boss: Deus Ex Machina"):
##   The Walker (100% -> 66%): it strides at the necromancer on four legs, each
##     carrying an armour plate (CitadelEnemyData "deus_leg_plate", DeusPlateKit)
##     the army breaks separately. While a plate stands its body takes
##     plated_damage_taken and never falls below 66%; each plate broken wounds
##     it (plate_wound). All four broken: it kneels and the Siege Core begins.
##     Specials, alternating every attack_gap s: the CHAINGUN SWEEP (an arc of
##     fire through EmpireShots, so Line of Fire applies: the army between it
##     and the necromancer shields him) and the MISSILE SALVO (four Lock-On lines
##     at once, LockOn.paint()'s boss_override, then the rockets, style
##     "missile"); FOOTFALLS land a shockwave ring under each foot as it walks;
##     a heavy STOMP when the necromancer or the army crowds its legs.
##   The Siege Core (66% -> 33%): it plants itself. SHIELD DRONES (DeusDroneKit)
##     orbit it and make the core immune until they are all shot down; it then
##     stays open (exposed_damage_taken) for exposed_time s and redeploys them.
##     The JUDGMENT LANCE sweeps a huge beam across the arena: the FIRST summon
##     standing in the beam takes the hit (ticks) and the necromancer behind it
##     is safe; with nobody in the way he takes the lance once per sweep. HANGAR
##     DOORS open either side of it and release Line Troopers and Valkyrie
##     Duelists.
##   The Founder (33% -> 0): the core cracks open (founder_damage_taken). It
##     drags itself after the necromancer; OVERLOAD PULSES roll out every few
##     seconds, each one stronger (a clock on the fight); it TELEPORTS in short
##     bursts (the destination glows first) and fires everything at once on
##     arrival: a ring of chaingun fire, two missiles, a stomp.
## A phase change takes phase_time s: it is invulnerable and transforms.
## Killing it plays the finale: the banner "Nothing is deathless. Everything is
## mine." (DeusData.ARRIVAL defeat_banner), the ending announcement, the soul
## binding, and every non-Reckoning MACHINE within machines_dark_radius px goes
## dark (taken off the field, no reward: "his machines go dark across the
## realm"); the normal boss reward fires (EnemyDirector: XP burst; ChestManager:
## chest). The Purge Protocol still begins at 0:00.
## Determinism: the seeded global RNG only (teleport destinations).
## Stats: deus_spawn_time, deus_siege_time, deus_founder_time, deus_kill_time,
## deus_plates_broken, bossdmg_deus_plate (the plates' wounds), deus_drones_launched,
## deus_drones_downed, deus_exposures, deus_lance_blocked_ticks,
## deus_lance_player_hits, deus_hangar_spawned, deus_pulses, deus_teleports,
## deus_machines_dark, boss_atk_<id> (DeusData.SPECIALS).
class_name BossDeusExMachina
extends Boss

## Fight phases.
enum Phase { ARRIVING, WALKER, CHANGING, SIEGE, FOUNDER }
## The action running inside a phase.
enum Act { NONE, CHAINGUN_WINDUP, CHAINGUN, STOMP_WINDUP, LANCE_WINDUP, LANCE, HANGAR_WINDUP, TELEPORT_GLOW }

## Damage source tag of a broken plate's wound to it (stats).
const WOUND_SOURCE: String = "deus_plate"
## Footfall order over DeusData.LEGS (a walking gait: diagonal pairs).
const GAIT := [0, 3, 1, 2]

## Current fight phase.
var phase: Phase = Phase.ARRIVING
## Seconds in the current phase.
var phase_time: float = 0.0
## The phase a CHANGING step leads into.
var _next_phase: Phase = Phase.SIEGE
## The action running now.
var act: Act = Act.NONE
## Seconds into the current action.
var act_time: float = 0.0
## Its world-hazards layer (rings, pulses, finale).
var hazards: DeusHazards = null
## Seconds until the next special (Walker, Founder).
var special_cd: float = 0.0
## Index of the next Walker special (0 chaingun, 1 salvo; alternating).
var _rot: int = 0
## Seconds until the next footfall (Walker).
var _footfall_cd: float = 0.0
## Index into GAIT of the next footfall.
var _gait: int = 0
## Seconds until the heavy stomp may come again.
var _stomp_cd: float = 0.0
## Game time (s) until which the Walker shows its firing pose after a salvo (visual only).
var _salvo_pose_until: float = 0.0
## Living leg plates: each [Enemy, generation].
var _plates: Array = []
## Plates broken this fight.
var plates_broken: int = 0
## Living shield drones: each [Enemy, generation].
var _drones: Array = []
## Game time the open core closes again (exposed; 0 = shielded or not in the Siege Core).
var _exposed_until: float = 0.0
## Game time new drones launch (INF = none pending).
var _redeploy_at: float = INF
## Chaingun sweep: start / end / current angle (rad, world).
var _sweep_from: float = 0.0
## End angle of the chaingun sweep (rad).
var _sweep_to: float = 0.0
## Current chaingun angle (rad).
var _sweep_angle: float = 0.0
## Seconds until the sweep's next round.
var _sweep_gap: float = 0.0
## Seconds until the next Judgment Lance.
var _lance_cd: float = 0.0
## Judgment Lance: start / end / current angle (rad, world).
var _lance_from: float = 0.0
## End angle of the lance sweep (rad).
var _lance_to: float = 0.0
## Current lance angle (rad).
var _lance_angle: float = 0.0
## Length (px) of the beam this tick (cut at the first summon in it).
var _lance_len: float = 0.0
## Seconds until the summon in the beam is hit again.
var _lance_tick: float = 0.0
## True once the current lance struck the necromancer.
var _lance_hit_player: bool = false
## Seconds until the hangar doors open again.
var _hangar_cd: float = 0.0
## Seconds until the next overload pulse (Founder).
var _pulse_cd: float = 0.0
## Overload pulses released so far (each one stronger).
var pulses: int = 0
## Seconds until the next teleport (Founder).
var _teleport_cd: float = 0.0
## Where the current teleport lands (world px).
var _teleport_to: Vector2 = Vector2.ZERO
## Game time it arrived.
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the engine at `pos` with HP scaled by `hp_mult`; its hazards layer is
## created; it descends (ARRIVING), then the Walker raises its plates.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = DeusData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	act = Act.NONE
	_spawn_time = game.elapsed
	game.stats["deus_spawn_time"] = game.elapsed
	hazards = DeusHazards.new()
	game.enemies.add_child(hazards)
	hazards.setup(game, self)
	game.enemies.boss_defeated.connect(_on_defeated)
	game.effects.impact(position, radius * 2.5, Palette.EMPIRE_SIGNAL_AMBER)
	game.shake(8.0)


## Its specials in report order (Boss hook).
func special_ids() -> Array:
	return DeusData.SPECIALS


## True while it walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return (phase == Phase.WALKER or phase == Phase.FOUNDER) and act == Act.NONE


## Sprite key of its art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/deus_ex_machina"


## Invulnerable while it descends or transforms; armoured (and floored at the
## Siege Core's threshold) while a leg plate stands; immune while a shield drone
## orbits the Siege Core, the weak point once it is open; the cracked core of the
## Founder takes more.
func damage_taken_mult(source: String) -> float:
	if phase == Phase.ARRIVING or phase == Phase.CHANGING:
		return 0.0
	var m := super.damage_taken_mult(source)
	match phase:
		Phase.WALKER:
			if _plates_alive() > 0:
				if hp <= max_hp * float(boss_def["siege_hp_fraction"]) + 1.0:
					return 0.0  # The plates hold the hull together: break them first.
				m *= float(boss_def["plated_damage_taken"])
		Phase.SIEGE:
			if _drones_alive() > 0:
				return 0.0  # The shield drones make the core immune.
			m *= float(boss_def["exposed_damage_taken"])
		Phase.FOUNDER:
			m *= float(boss_def["founder_damage_taken"])
	return m


# =====================================================================================
# Physics: phases and actions
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	_step_plates()
	_step_drones()
	hazards.step(delta)
	queue_redraw()
	match phase:
		Phase.ARRIVING:
			_hold(delta)
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.WALKER)
		Phase.WALKER:
			_walker(delta)
		Phase.CHANGING:
			_hold(delta)
			if phase_time >= float(boss_def["phase_time"]):
				_enter(_next_phase)
		Phase.SIEGE:
			_hold(delta)
			_siege(delta)
			if hp <= max_hp * float(boss_def["founder_hp_fraction"]):
				_change_to(Phase.FOUNDER)
		Phase.FOUNDER:
			_founder(delta)


## Holds still this tick (shared timers still run, no knockback).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO


## Sets the phase at once.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	act = Act.NONE
	act_time = 0.0
	queue_redraw()


## Starts the change into phase `p`: invulnerable, it transforms; the banner.
func _change_to(p: Phase) -> void:
	_next_phase = p
	_set_phase(Phase.CHANGING)
	hazards.clear()
	if p == Phase.SIEGE:
		hp = minf(hp, max_hp * float(boss_def["siege_hp_fraction"]))
		game.enemies.show_banner(String(boss_def["siege_banner"]))
		game.stats["deus_siege_time"] = game.elapsed
		game.stat_add("boss_phase2", 1.0)
	else:
		game.enemies.show_banner(String(boss_def["founder_banner"]))
		game.stats["deus_founder_time"] = game.elapsed
		game.stat_add("boss_phase3", 1.0)
	game.effects.impact(position, radius * 2.5, Palette.EMPIRE_SIGNAL_RED)
	game.effects.ring(position, radius * 4.0, Palette.EMPIRE_SIGNAL_AMBER, float(boss_def["phase_time"]))
	Sfx.play("deus_transform", position)
	game.shake(7.0)


## Phase `p` begins.
func _enter(p: Phase) -> void:
	_set_phase(p)
	match p:
		Phase.WALKER:
			special_cd = float(boss_def["first_special"])
			_footfall_cd = float(boss_def["footfall_interval"])
			_stomp_cd = float(boss_def["stomp_cooldown"]) * 0.5
			_raise_plates()
		Phase.SIEGE:
			_lance_cd = float(boss_def["lance_first"])
			_hangar_cd = float(boss_def["hangar_first"])
			_exposed_until = 0.0
			_launch_drones()
		Phase.FOUNDER:
			_despawn_drones()
			_pulse_cd = float(boss_def["pulse_first"])
			_teleport_cd = float(boss_def["teleport_first"])
			special_cd = float(boss_def["first_special"])
			pulses = 0


# =====================================================================================
# The Walker
# =====================================================================================

## One Walker tick: walk and kick (the shared melee AI), footfalls, the heavy
## stomp, the two alternating specials; the knees give way once every plate broke.
func _walker(delta: float) -> void:
	if _plates_alive() == 0 and plates_broken > 0:
		_change_to(Phase.SIEGE)
		return
	if _plates_alive() > 0:
		hp = maxf(hp, max_hp * float(boss_def["siege_hp_fraction"]))  # The floor (a big hit may cross it).
	match act:
		Act.CHAINGUN_WINDUP:
			_hold(delta)
			act_time += delta
			if act_time >= float(boss_def["chaingun_telegraph"]):
				act = Act.CHAINGUN
				act_time = 0.0
				_sweep_gap = 0.0
				Sfx.play("chaingun", position)
			return
		Act.CHAINGUN:
			_hold(delta)
			act_time += delta
			var k := clampf(act_time / float(boss_def["chaingun_time"]), 0.0, 1.0)
			_sweep_angle = lerpf(_sweep_from, _sweep_to, k)
			_sweep_gap -= delta
			while _sweep_gap <= 0.0:
				_sweep_gap += float(boss_def["chaingun_gap"])
				_fire_round(Vector2.from_angle(_sweep_angle))
			if k >= 1.0:
				act = Act.NONE
				special_cd = float(boss_def["attack_gap"])
			return
		Act.STOMP_WINDUP:
			_hold(delta)
			act_time += delta
			if act_time >= float(boss_def["stomp_telegraph"]):
				act = Act.NONE
			return
	# Walking.
	special_cd -= delta
	_footfall_cd -= delta
	_stomp_cd -= delta
	super.physics_step(delta)
	knockback = Vector2.ZERO
	if _footfall_cd <= 0.0 and velocity.length() > 4.0:
		_footfall_cd = float(boss_def["footfall_interval"])
		_footfall()
	if _stomp_cd <= 0.0 and _crowded(float(boss_def["stomp_trigger"])):
		_start_stomp()
	elif special_cd <= 0.0:
		if _rot % 2 == 0:
			_start_chaingun()
		else:
			_start_salvo()
		_rot += 1


## True when the necromancer or 4+ summons on the ground are within `r` px.
func _crowded(r: float) -> bool:
	if position.distance_to(game.player.position) <= r + radius:
		return true
	game.ally_grid.query(position, r + radius, _buf)
	var n := 0
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(position) <= r + radius:
			n += 1
	return n >= 4


## A footfall: the next leg of the gait lands on a telegraphed ring.
func _footfall() -> void:
	var legs: Array = DeusData.LEGS
	var at := position + (legs[int(GAIT[_gait % GAIT.size()])] as Vector2)
	_gait += 1
	hazards.ring(at, float(boss_def["footfall_radius"]), float(boss_def["footfall_telegraph"]), float(boss_def["footfall_damage_player"]),
			float(boss_def["footfall_damage_summon"]), float(boss_def["footfall_knockback"]), "deus_footfall", "deus_footfall")
	game.stat_add("boss_atk_footfall", 1.0)


## The heavy stomp: both front feet slam down on telegraphed rings.
func _start_stomp() -> void:
	_stomp_cd = float(boss_def["stomp_cooldown"])
	var legs: Array = DeusData.LEGS
	for i in 2:
		hazards.ring(position + (legs[i] as Vector2) * 1.1, float(boss_def["stomp_radius"]), float(boss_def["stomp_telegraph"]),
				float(boss_def["stomp_damage_player"]), float(boss_def["stomp_damage_summon"]), float(boss_def["stomp_knockback"]), "deus_stomp", "deus_stomp")
	act = Act.STOMP_WINDUP
	act_time = 0.0
	motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)
	game.stat_add("boss_atk_stomp", 1.0)
	Sfx.play("boss_telegraph", position, 0.7)


## Starts the chaingun sweep across an arc toward the necromancer, from the side
## he is moving toward so he must cross it.
func _start_chaingun() -> void:
	var to_p := game.player.position - position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	var half := float(boss_def["chaingun_arc"]) * 0.5
	var side := 1.0 if dir.cross(game.player.velocity) >= 0.0 else -1.0
	_sweep_from = dir.angle() - half * side
	_sweep_to = dir.angle() + half * side
	_sweep_angle = _sweep_from
	act = Act.CHAINGUN_WINDUP
	act_time = 0.0
	game.effects.telegraph_cone(position, dir, minf(320.0, float(boss_def["chaingun_range"])), half, float(boss_def["chaingun_telegraph"]), self)
	motion_lunge(dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_chaingun", 1.0)


## One chaingun round along `dir` through EmpireShots (Line of Fire applies).
func _fire_round(dir: Vector2) -> void:
	var muzzle := position + dir * (radius + 6.0)
	game.empire_rules().shots.fire(muzzle, dir, float(boss_def["chaingun_speed"]), float(boss_def["chaingun_damage"]) * CovenantKit.hit_scale(self),
			undead_damage_mult, "chaingun", "deus_chaingun", float(boss_def["chaingun_range"]))


## Autopilot hint (the autotest bot): where to walk to bring the army to the
## planted Siege Core and its shield drones; INF in every other phase.
func approach_point(_p: Vector2) -> Vector2:
	return position if phase == Phase.SIEGE else Vector2.INF


## True while the Walker holds its firing pose after a salvo (drawing only).
func _salvo_posing() -> bool:
	return game != null and game.elapsed < _salvo_pose_until


## The missile salvo: `lines` Lock-On lines at once (LockOn's boss override):
## one on the necromancer, the rest on the summons nearest him. It keeps walking.
func _start_salvo(lines: int = -1) -> void:
	var n := int(boss_def["salvo_lines"]) if lines < 0 else lines
	var lock := game.empire_rules().lock_on
	_salvo_pose_until = game.elapsed + DeusData.SALVO_POSE_TIME
	var dmg := float(boss_def["salvo_damage"]) * CovenantKit.hit_scale(self)
	var painted := 0  # Lines started.
	if not game.ultimates.player_untargetable():
		if lock.paint(self, game.player, dmg, float(boss_def["salvo_speed"]), float(boss_def["salvo_range"]), "deus_missile", true,
				float(boss_def["salvo_paint"]), "missile"):
			painted += 1
	var cands: Array = []  # [distance to the necromancer, summon].
	game.ally_grid.query(game.player.position, 260.0, _buf)
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.state != SummonedUnit.State.SPAWNING:
			cands.append([u.position.distance_to(game.player.position), u])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c: Array in cands:
		if painted >= n:
			break
		if lock.paint(self, c[1], dmg, float(boss_def["salvo_speed"]), float(boss_def["salvo_range"]), "deus_missile", true,
				float(boss_def["salvo_paint"]), "missile"):
			painted += 1
	special_cd = float(boss_def["attack_gap"])
	game.stat_add("boss_atk_salvo", 1.0)
	Sfx.play("missile_lock", position)


## Raises the four leg plates (each a share of its max HP), one on each leg.
func _raise_plates() -> void:
	_plates.clear()
	for i in DeusData.LEGS.size():
		var e := game.enemies.spawn_at(CitadelEnemyData.PLATE, position + (DeusData.LEGS[i] as Vector2), false)
		e.is_objective = true
		e.max_hp = max_hp * float(boss_def["plate_hp"])
		e.hp = e.max_hp
		if e.kit is DeusPlateKit:
			(e.kit as DeusPlateKit).attach(e, self, i)
		e.queue_redraw()
		_plates.append([e, e.generation])
		game.effects.spawn_ring(e.position, Palette.EMPIRE_SIGNAL_AMBER)


## A broken plate wounds it (never the last blow).
func _step_plates() -> void:
	var i := _plates.size() - 1
	while i >= 0:
		var rec: Array = _plates[i]
		var e: Enemy = rec[0]
		if not e.active or e.generation != int(rec[1]):
			_plates.remove_at(i)
			plates_broken += 1
			var wound := minf(max_hp * float(boss_def["plate_wound"]), maxf(0.0, hp - 1.0))
			hp -= wound
			on_hit()
			game.stat_add("deus_plates_broken", 1.0)
			game.stat_add("bossdmg_" + WOUND_SOURCE, wound)
			game.effects.impact(e.position, 46.0, Palette.EMPIRE_SIGNAL_AMBER)
			game.shake(4.0)
			Sfx.play("plate_break", e.position)
			game.enemies.show_banner("A leg plate shatters! (%d left)" % _plates_alive())
		i -= 1


## Living leg plates.
func _plates_alive() -> int:
	var n := 0
	for rec: Array in _plates:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			n += 1
	return n


# =====================================================================================
# The Siege Core
# =====================================================================================

## One Siege Core tick (it holds still): the drones' cycle, the lance, the hangars.
func _siege(delta: float) -> void:
	var t := game.elapsed
	if _drones_alive() == 0 and _exposed_until == 0.0 and _redeploy_at == INF:
		_exposed_until = t + float(boss_def["exposed_time"])
		game.stat_add("deus_exposures", 1.0)
		game.enemies.show_banner("The shield drones are down: the core is open!")
		Sfx.play("plate_break", position, 0.7)
	if _exposed_until > 0.0 and t >= _exposed_until - float(boss_def["redeploy_time"]) and _redeploy_at == INF:
		_redeploy_at = _exposed_until
	if _redeploy_at != INF and t >= _redeploy_at:
		_redeploy_at = INF
		_exposed_until = 0.0
		_launch_drones()
	match act:
		Act.LANCE_WINDUP:
			act_time += delta
			if act_time >= float(boss_def["lance_telegraph"]):
				act = Act.LANCE
				act_time = 0.0
				_lance_tick = 0.0
				_lance_hit_player = false
				Sfx.play("lance_fire", position)
			return
		Act.LANCE:
			act_time += delta
			var k := clampf(act_time / float(boss_def["lance_time"]), 0.0, 1.0)
			_lance_angle = lerpf(_lance_from, _lance_to, k)
			_lance_step(delta)
			if k >= 1.0:
				act = Act.NONE
			return
		Act.HANGAR_WINDUP:
			act_time += delta
			if act_time >= float(boss_def["hangar_telegraph"]):
				act = Act.NONE
				_open_hangars()
			return
	_lance_cd -= delta
	_hangar_cd -= delta
	if _lance_cd <= 0.0:
		_lance_cd = float(boss_def["lance_interval"])
		_start_lance()
	elif _hangar_cd <= 0.0:
		_hangar_cd = float(boss_def["hangar_interval"])
		act = Act.HANGAR_WINDUP
		act_time = 0.0
		game.stat_add("boss_atk_hangar", 1.0)
		Sfx.play("hangar_open", position)


## Launches a ring of shield drones around the core.
func _launch_drones() -> void:
	_drones.clear()
	var n := int(boss_def["drones"])
	for i in n:
		var a := TAU * float(i) / float(maxi(1, n))
		var e := game.enemies.spawn_at(CitadelEnemyData.SHIELD_DRONE, position + Vector2.from_angle(a) * float(boss_def["drone_orbit"]), false)
		e.is_objective = true
		e.max_hp = max_hp * float(boss_def["drone_hp"])
		e.hp = e.max_hp
		if e.kit is DeusDroneKit:
			(e.kit as DeusDroneKit).attach(e, self, a, float(boss_def["drone_orbit"]), float(boss_def["drone_speed"]))
		_drones.append([e, e.generation])
	game.stat_add("deus_drones_launched", float(n))
	game.stat_add("boss_atk_drones", 1.0)
	game.effects.ring(position, float(boss_def["drone_orbit"]), Palette.EMPIRE_SIGNAL_AMBER, 0.6)


## Drops the shield drones that were shot down.
func _step_drones() -> void:
	var i := _drones.size() - 1
	while i >= 0:
		var rec: Array = _drones[i]
		var e: Enemy = rec[0]
		if not e.active or e.generation != int(rec[1]):
			_drones.remove_at(i)
			game.stat_add("deus_drones_downed", 1.0)
		i -= 1


## Living shield drones.
func _drones_alive() -> int:
	var n := 0
	for rec: Array in _drones:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			n += 1
	return n


## Takes the remaining drones off the field (the Founder phase, its death).
func _despawn_drones() -> void:
	for rec: Array in _drones:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			game.effects.pop(e.position, Palette.EMPIRE_SIGNAL_AMBER, 14.0)
			game.enemies.despawn(e)
	_drones.clear()


## Telegraphs the Judgment Lance across an arc toward the necromancer.
func _start_lance() -> void:
	var to_p := game.player.position - position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	var half := float(boss_def["lance_arc"]) * 0.5
	var side := 1.0 if dir.cross(game.player.velocity) >= 0.0 else -1.0
	_lance_from = dir.angle() - half * side
	_lance_to = dir.angle() + half * side
	_lance_angle = _lance_from
	_lance_len = float(boss_def["lance_reach"])
	act = Act.LANCE_WINDUP
	act_time = 0.0
	game.stat_add("boss_atk_lance", 1.0)
	Sfx.play("lance_charge", position)


## The lance this tick: cut at the first summon in the beam (it takes the hit),
## else it reaches the necromancer if he stands in it.
func _lance_step(delta: float) -> void:
	var dir := Vector2.from_angle(_lance_angle)
	var reach := float(boss_def["lance_reach"])
	var half_w := float(boss_def["lance_width"]) * 0.5
	var mult := CovenantKit.hit_scale(self)
	var blocker: SummonedUnit = null
	var best := reach
	var mid := position + dir * reach * 0.5
	game.ally_grid.query(mid, reach * 0.5 + half_w + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		var rel := u.position - position
		var along := rel.dot(dir)
		if along < 0.0 or along > best:
			continue
		if absf(rel.cross(dir)) <= half_w + u.radius:
			best = along
			blocker = u
	_lance_len = best
	_lance_tick -= delta
	if blocker != null and _lance_tick <= 0.0:
		_lance_tick = float(boss_def["lance_tick"])
		game.combat.damage_unit(blocker, float(boss_def["lance_damage_summon"]) * mult, "deus_lance")
		game.stat_add("deus_lance_blocked_ticks", 1.0)
	var pl := game.player
	if not _lance_hit_player:
		var rel_p := pl.position - position
		var along_p := rel_p.dot(dir)
		if along_p >= 0.0 and along_p <= _lance_len and absf(rel_p.cross(dir)) <= half_w + pl.radius:
			_lance_hit_player = true
			game.combat.damage_player(float(boss_def["lance_damage_player"]) * mult, "deus_lance")
			game.stat_add("deus_lance_player_hits", 1.0)


## World positions of the two hangar doors (either side of the core).
func _doors() -> Array[Vector2]:
	var o := float(boss_def["hangar_offset"])
	return [position + Vector2(-o, o * 0.4), position + Vector2(o, o * 0.4)]


## The hangar doors open: Line Troopers and Valkyrie Duelists march out.
func _open_hangars() -> void:
	var spawned := 0
	for door in _doors():
		for grp: Dictionary in boss_def["hangar_groups"]:
			for _k in int(grp["count"]):
				if game.enemies.regular_alive() >= WaveData.HARD_CAP:
					break
				game.enemies.spawn_at(String(grp["kind"]), door + Vector2(randf_range(-14.0, 14.0), randf_range(6.0, 22.0)), bool(grp["elite"]))
				spawned += 1
		game.effects.spawn_ring(door, Palette.EMPIRE_SIGNAL_RED)
	game.stat_add("deus_hangar_spawned", float(spawned))


# =====================================================================================
# The Founder
# =====================================================================================

## One Founder tick: it drags itself after the necromancer between teleports;
## overload pulses roll out on their shrinking clock.
func _founder(delta: float) -> void:
	_pulse_cd -= delta
	if _pulse_cd <= 0.0 and not hazards.pulse_charging():
		var k := minf(float(boss_def["pulse_growth_max"]), 1.0 + float(boss_def["pulse_growth"]) * float(pulses))  # Each one stronger.
		hazards.charge_pulse(float(boss_def["pulse_charge"]), float(boss_def["pulse_damage_player"]) * k, float(boss_def["pulse_damage_summon"]) * k)
		pulses += 1
		_pulse_cd = maxf(float(boss_def["pulse_interval_min"]), float(boss_def["pulse_interval"]) - float(boss_def["pulse_interval_step"]) * float(pulses))
		game.stat_add("deus_pulses", 1.0)
		game.stat_add("boss_atk_pulse", 1.0)
	if act == Act.TELEPORT_GLOW:
		_hold(delta)
		act_time += delta
		if act_time >= float(boss_def["teleport_glow"]):
			act = Act.NONE
			_arrive()
		return
	_teleport_cd -= delta
	move_speed = float(boss_def["founder_speed"])
	super.physics_step(delta)
	knockback = Vector2.ZERO
	if _teleport_cd <= 0.0:
		_teleport_cd = float(boss_def["teleport_interval"])
		var a := randf() * TAU
		var d := randf_range(float(boss_def["teleport_min"]), float(boss_def["teleport_max"]))
		_teleport_to = game.arena.free_point(game.player.position + Vector2.from_angle(a) * d, radius)
		act = Act.TELEPORT_GLOW
		act_time = 0.0
		game.stat_add("deus_teleports", 1.0)
		game.stat_add("boss_atk_teleport", 1.0)
		Sfx.play("teleport_charge", _teleport_to)


## It lands at the glow and fires everything at once: a ring of chaingun fire,
## two missiles, a stomp.
func _arrive() -> void:
	game.effects.impact(position, radius * 1.5, Palette.EMPIRE_SIGNAL_RED)
	position = _teleport_to
	game.effects.impact(position, radius * 2.0, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("teleport_land", position)
	var n := int(boss_def["volley_rounds"])
	for i in n:
		_fire_round(Vector2.from_angle(TAU * float(i) / float(maxi(1, n))))
	_start_salvo(int(boss_def["volley_missiles"]))
	hazards.ring(position, float(boss_def["volley_stomp_radius"]), 0.5, float(boss_def["stomp_damage_player"]),
			float(boss_def["stomp_damage_summon"]), float(boss_def["stomp_knockback"]), "deus_stomp", "deus_stomp")
	game.shake(7.0)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Its death (EnemyDirector.boss_defeated, after the reward burst): its plates
## and drones fall with it, its machines around the necromancer go dark, and the
## finale plays: "Nothing is deathless. Everything is mine."
func _on_defeated() -> void:
	var pos := position
	hazards.start_finale(pos)
	for rec: Array in _plates:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			game.enemies.despawn(e)
	_plates.clear()
	_despawn_drones()
	var dark := 0  # Machines powered down.
	var reach := float(boss_def["machines_dark_radius"])
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_reckoning or e.body != EmpireEnemyData.MACHINE:
			continue
		if e.position.distance_to(game.player.position) > reach:
			continue
		game.effects.pop(e.position, Palette.EMPIRE_CHROME_DARK, 14.0)
		game.enemies.despawn(e)
		dark += 1
	game.stat_add("deus_machines_dark", float(dark))
	game.effects.ring(pos, DeusData.BINDING_RADIUS, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, DeusData.BINDING_RADIUS * 0.6, Palette.EMPIRE_SIGNAL_AMBER, 0.8)
	Juice.fx.burst(pos, Palette.NECRO_GREEN, Palette.EMPIRE_SIGNAL_GLOW, 24, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("deus_fall", pos)
	var late := game.countdown_finished()  # It fell during the Purge Protocol.
	game.enemies.show_banner(String(DeusData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + DeusData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = DeusData.LATE_ANNOUNCE if late else DeusData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)
	game.stats["deus_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: its rings, the chaingun arc, the
## lance's path and a teleport landing.
func danger_push(p: Vector2) -> Vector2:
	var push := hazards.danger_push(p) if hazards != null else Vector2.ZERO
	var away := p - position
	var n := away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	match act:
		Act.CHAINGUN_WINDUP, Act.CHAINGUN:
			var mid := (_sweep_from + _sweep_to) * 0.5
			if CovenantKit.in_sector(position, Vector2.from_angle(mid), float(boss_def["chaingun_range"]), float(boss_def["chaingun_arc"]) * 0.5 + 0.2, radius, p, 12.0):
				push += n.orthogonal() * (1.0 if n.cross(Vector2.from_angle(mid)) < 0.0 else -1.0)
		Act.LANCE_WINDUP, Act.LANCE:
			var dir := Vector2.from_angle(_lance_angle if act == Act.LANCE else (_lance_from + _lance_to) * 0.5)
			var rel := p - position
			if rel.dot(dir) > 0.0 and absf(rel.cross(dir)) < float(boss_def["lance_width"]) + 40.0:
				push += dir.orthogonal() * (1.0 if rel.cross(dir) < 0.0 else -1.0)
		Act.TELEPORT_GLOW:
			var off := p - _teleport_to
			if off.length() < float(boss_def["volley_stomp_radius"]) + 30.0:
				push += off.normalized() if off.length() > 0.1 else Vector2.RIGHT
	return push


## True while an overload pulse's front is about to reach `p` (the autotest
## bot's Grave Step hint).
func pulse_near(p: Vector2) -> bool:
	return hazards != null and hazards.pulse_near(p)


## Ground layer: the chaingun arc, the lance's telegraph and beam, the hangar
## doors and a teleport's destination glow (world axes).
func _draw_under() -> void:
	CovenantKit.unmirror(self)
	var t := game.elapsed if game != null else 0.0
	match act:
		Act.CHAINGUN_WINDUP:
			CitadelGlyphs.draw_sweep_arc(self, Vector2.ZERO, _sweep_from, _sweep_to, float(boss_def["chaingun_range"]) * 0.6, clampf(act_time / float(boss_def["chaingun_telegraph"]), 0.0, 1.0))
		Act.LANCE_WINDUP:
			var k := clampf(act_time / float(boss_def["lance_telegraph"]), 0.0, 1.0)
			CitadelGlyphs.draw_sweep_arc(self, Vector2.ZERO, _lance_from, _lance_to, float(boss_def["lance_reach"]), k)
			CitadelGlyphs.draw_lance(self, Vector2.from_angle(_lance_from), float(boss_def["lance_reach"]), float(boss_def["lance_width"]), false, k, t)
		Act.LANCE:
			CitadelGlyphs.draw_lance(self, Vector2.from_angle(_lance_angle), _lance_len, float(boss_def["lance_width"]), true, 1.0, t)
		Act.HANGAR_WINDUP:
			for door in _doors():
				CitadelGlyphs.draw_hangar(self, door - position, clampf(act_time / float(boss_def["hangar_telegraph"]), 0.0, 1.0))
		Act.TELEPORT_GLOW:
			CitadelGlyphs.draw_teleport_glow(self, _teleport_to - position, radius, clampf(act_time / float(boss_def["teleport_glow"]), 0.0, 1.0), t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Body layer on `ci`: the engine in the look of its phase.
func _draw_body(ci: CanvasItem) -> void:
	var look := 0  # 0 the Walker, 1 the Siege Core, 2 the Founder.
	match phase:
		Phase.SIEGE:
			look = 1
		Phase.FOUNDER:
			look = 2
		Phase.CHANGING:
			look = 1 if _next_phase == Phase.SIEGE else 2
	var arrive := clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.0, 1.0) if phase == Phase.ARRIVING else 1.0
	CitadelGlyphs.draw_deus(ci, Vector2.ZERO, radius, flash > 0.0, look, arrive, game.elapsed if game != null else 0.0, _exposed_until > 0.0,
			1 if act == Act.CHAINGUN or act == Act.CHAINGUN_WINDUP or _salvo_posing() else 0)


## Overlay layer on `ci`: the Stasis / Deep Freeze ice.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of its fight (phase times relative to its arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("deus_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	return "phases: siege %s, founder %s, kill %s | plates broken %d (wound dmg %d) | chaingun %d, salvos %d, footfalls %d (you hit %d), stomps %d (you hit %d), ring summon hits %d | drones launched %d, downed %d, exposures %d | lances %d (blocked ticks %d, you hit %d), hangars %d (spawned %d) | pulses %d (you hit %d, summons %d), teleports %d | machines dark %d | dmg to you: chaingun %d, missiles %d, rings %d, lance %d, pulses %d" % [
		rel.call("deus_siege_time"), rel.call("deus_founder_time"), "%.1fs" % float(st["deus_kill_time"]) if st.has("deus_kill_time") else "-",
		int(st.get("deus_plates_broken", 0.0)), int(st.get("bossdmg_" + WOUND_SOURCE, 0.0)),
		int(st.get("boss_atk_chaingun", 0.0)), int(st.get("boss_atk_salvo", 0.0)), int(st.get("boss_atk_footfall", 0.0)), int(st.get("deus_footfall_player_hits", 0.0)),
		int(st.get("boss_atk_stomp", 0.0)), int(st.get("deus_stomp_player_hits", 0.0)), int(st.get("deus_ring_summon_hits", 0.0)),
		int(st.get("deus_drones_launched", 0.0)), int(st.get("deus_drones_downed", 0.0)), int(st.get("deus_exposures", 0.0)),
		int(st.get("boss_atk_lance", 0.0)), int(st.get("deus_lance_blocked_ticks", 0.0)), int(st.get("deus_lance_player_hits", 0.0)),
		int(st.get("boss_atk_hangar", 0.0)), int(st.get("deus_hangar_spawned", 0.0)),
		int(st.get("deus_pulses", 0.0)), int(st.get("deus_pulse_player_hits", 0.0)), int(st.get("deus_pulse_summon_hits", 0.0)), int(st.get("deus_teleports", 0.0)),
		int(st.get("deus_machines_dark", 0.0)),
		int(st.get("player_dmg_from_deus_chaingun", 0.0)), int(st.get("player_dmg_from_deus_missile", 0.0)),
		int(st.get("player_dmg_from_deus_footfall", 0.0)) + int(st.get("player_dmg_from_deus_stomp", 0.0)),
		int(st.get("player_dmg_from_deus_lance", 0.0)), int(st.get("player_dmg_from_deus_pulse", 0.0))]
