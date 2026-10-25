## CitadelDirector — the stage mechanics of THE IRON CITADEL (Stage 9, the
## campaign finale; Act III; GDD §15.0 "The Iron Citadel (Act III phase 2)";
## owner-approved proposal "Necropathy: Act III Proposal (The Electronic
## Empire)"), owned and stepped by EnemyDirector on a stage whose STAGE has a
## "citadel" config (CitadelStage.CITADEL; null elsewhere). The four zones are
## MarchDirector's (the clock is authoritative); this director reads the current
## zone (MarchDirector.zone_index) for the zone's own systems:
##   * SHIELD GATES (the "gate" timeline event, one in each of the first three
##     zones: the way into the next zone): an energy wall of gate.wall_length px
##     rises across the necromancer's path, gate.distance px ahead of him, with a
##     Shield Generator (a structure, CitadelEnemyData) at each end and two
##     Sentry Turrets behind it. While it holds, the wall is solid for the
##     necromancer (contain_all(), called last in Arena.resolve_all(): THE one
##     gate push-out; the shield reads the living, so his dead and the Empire's
##     soldiers pass through it) and its garrison pours out of it every
##     gate.garrison_interval s. Both generators destroyed: the wall falls, an
##     XP burst and gate.ash Soul Ash ("objective_ash"). Still holding when the
##     next zone begins: LOCKDOWN (a last garrison wave storms out, the wall
##     powers down, and the Citadel's guns fire gate.lockdown_gun_mult as often
##     for that zone).
##   * LASER GRIDS (a zone's "lasers" config; the Laser Courts and the Core):
##     on a fixed rhythm a grid of parallel beams is telegraphed across the
##     necromancer's ground for `telegraph` s (1 s, thin flickering red lines and
##     their edge emitters), then fires: each beam sweeps `sweep` px sideways in
##     `sweep_time` s and hits every body it crosses once: the necromancer, every
##     summon on the ground, and the Empire's own soldiers too (never a boss, a
##     miniboss, a structure or a Reckoning foe). The orientation turns every
##     cycle (0, 90, 45, 135 degrees); the gaps between the beams are safe.
##   * CITADEL GUNS (a zone's "guns" config): the fortress itself fires orbital
##     strikes on telegraphed circles, more often the deeper the zone, through
##     THE one strike path, EmpireRules.strike() (the Purge Protocol's code):
##     one circle on the necromancer, the rest scattered round him. Slower while
##     the stage boss fights (guns.boss_mult); silent once the Purge Protocol
##     takes the sky at 0:00.
##   * SENTRY TURRETS (the "turrets" event, and two behind each gate): fixed
##     emplacements (SentryKit) that pay turret bounty_ash Soul Ash when they
##     fall; a turret left far behind (turrets.despawn_distance) is taken off
##     the field without a reward.
##   * VALKYRIE 2.0 (the "valkyrie" event): the miniboss arrives with an escort
##     (ValkyrieKit registers her for the HUD bar; ChestManager drops her chest).
##   * GUEST SQUADS: the earlier Act III stages' kinds (the Scrap Wastes', the
##     Assembly Halls') join small squads on a timer when this build knows them
##     (EnemyDirector.is_known_kind(); candidate ids per kind), like Ul-Thalos's
##     guests, so the stage plays the same before and after those stages merge.
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective: never
## recycled), polled with generation checks. Deterministic: the seeded global
## RNG only. Stats: citadel_gates_raised, citadel_gates_broken,
## citadel_lockdowns, citadel_garrison_spawned, citadel_laser_cycles,
## citadel_laser_player_hits, citadel_laser_summon_hits,
## citadel_laser_enemy_hits, citadel_gun_salvos, citadel_gun_strikes,
## citadel_gun_player_hits, citadel_turrets_placed, citadel_turrets_destroyed,
## citadel_turrets_left, citadel_guest_squads, citadel_guests_spawned,
## citadel_wall_pushes, objective_ash.
class_name CitadelDirector
extends Node2D

## One Shield Gate.
class Gate:
	extends RefCounted
	## The wall's two ends (world px).
	var a: Vector2 = Vector2.ZERO
	## Second end of the wall (world px).
	var b: Vector2 = Vector2.ZERO
	## Unit normal of the wall pointing to the far side (away from the necromancer
	## when it rose): the garrison pours out on the near side, the turrets stand
	## on the far side.
	var normal: Vector2 = Vector2.UP
	## The two Shield Generators' Enemy nodes.
	var gens: Array[Enemy] = []
	## Generation of each generator when it was placed (stale / death guard).
	var gen_ids: PackedInt32Array = PackedInt32Array()
	## Zone index the gate rose in (it leads into the next zone).
	var zone: int = 0
	## Game time of the next garrison squad.
	var next_spawn: float = 0.0
	## Game time it rose (the draw's power-up sweep).
	var born: float = 0.0
	## The timeline event that raised it (rewards, the garrison).
	var ev: Dictionary = {}

## One tracked Sentry Turret.
class Turret:
	extends RefCounted
	## The turret's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed.
	var gen: int = 0
	## Last known world position.
	var pos: Vector2 = Vector2.ZERO

## Owning run.
var game: Game
## The stage's citadel config (CitadelStage.CITADEL).
var config: Dictionary = {}
## Standing Shield Gates.
var gates: Array[Gate] = []
## Sentry Turrets on the field.
var turrets: Array[Turret] = []
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Zone index the systems below last saw (MarchDirector.zone_index).
var _zone: int = 0
## Laser grid of the current zone ({} = none).
var _lasers: Dictionary = {}
## Citadel guns of the current zone ({} = none).
var _guns: Dictionary = {}
## Gun interval multiplier of the current zone (gate.lockdown_gun_mult after a lockdown, else 1).
var _gun_mult: float = 1.0
## Game time of the next gun salvo (INF = none).
var _next_salvo: float = INF
## Game time of the next laser cycle (INF = none).
var _next_laser: float = INF
## Laser cycles fired so far (orientation rotation).
var _laser_cycles: int = 0
## Laser phase: 0 idle, 1 telegraphed, 2 sweeping.
var _laser_phase: int = 0
## Seconds into the current laser phase.
var _laser_time: float = 0.0
## Unit normal of the current grid's sweep (the beams run perpendicular to it).
var _laser_n: Vector2 = Vector2.RIGHT
## Signed offset (px along _laser_n from _laser_origin) of each beam's start line.
var _beam_start: PackedFloat32Array = PackedFloat32Array()
## Origin of the current grid (the necromancer's position when it was laid).
var _laser_origin: Vector2 = Vector2.ZERO
## Sweep fraction (0..1) reached at the last tick (the swept band's back edge).
var _laser_k: float = 0.0
## Bodies already hit this cycle: Object -> generation (0 for the necromancer).
var _laser_hits: Dictionary = {}
## Game time of the next guest squad.
var _next_guest: float = 0.0
## Guest squads sent so far.
var _guest_squads: int = 0
## Gates broken this run.
var gates_broken: int = 0
## Lockdowns this run (a gate still holding at its zone's end).
var lockdowns: int = 0
## "m:ss name" log of the director's events (autotest summary).
var fired: Array[String] = []
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = 1  # The walls and beams glow over the ground and the bodies.
	game.arena.citadel = self
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break
	_enter_zone(0)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var z := game.enemies.march.zone_index if game.enemies.march != null else 0  # Current zone.
	if z != _zone:
		_on_zone_change(_zone, z)
	_step_gates()
	_step_turrets()
	_step_guns()
	_step_lasers(delta)
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()
	if not gates.is_empty() or _laser_phase != 0:
		queue_redraw()


## Runs a citadel timeline event (EnemyDirector forwards "gate", "turrets" and
## "valkyrie").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"gate":
			_raise_gate(ev)
		"turrets":
			_place_turrets(ev)
		"valkyrie":
			_send_valkyrie(ev)
	game.enemies.show_banner(String(ev["banner"]))


# =====================================================================================
# Zones
# =====================================================================================

## The march moved from zone `from` to zone `to`: a gate of the old zone still
## holding locks the Citadel down, then the new zone's guns and lasers start.
func _on_zone_change(from: int, to: int) -> void:
	_gun_mult = 1.0
	var i := gates.size() - 1
	while i >= 0:
		var gt := gates[i]
		if gt.zone <= from:
			_lockdown(gt)
			gates.remove_at(i)
		i -= 1
	_enter_zone(to)


## Starts zone `z`'s guns and lasers (ZONES "guns" / "lasers").
func _enter_zone(z: int) -> void:
	_zone = z
	var zones: Array = config["zones"]
	var zd: Dictionary = zones[clampi(z, 0, zones.size() - 1)]
	_guns = zd.get("guns", {})
	_lasers = zd.get("lasers", {})
	_next_salvo = game.elapsed + float(_guns["first"]) if not _guns.is_empty() else INF
	_next_laser = game.elapsed + float(_lasers["first"]) if not _lasers.is_empty() else INF
	if _laser_phase != 0 and _lasers.is_empty():
		_laser_phase = 0


# =====================================================================================
# Shield gates
# =====================================================================================

## Raises a Shield Gate across the necromancer's path (his movement direction,
## else a random one): the wall, its two generators and the turrets behind it.
func _raise_gate(ev: Dictionary) -> void:
	var gc: Dictionary = config["gate"]
	var p := game.player.position
	var v := game.player.velocity
	var fwd := v.normalized() if v.length() > 5.0 else Vector2.from_angle(randf() * TAU)  # Toward the far side.
	var center := p + fwd * float(gc["distance"])
	var along := Vector2(-fwd.y, fwd.x)  # The wall's direction.
	var half := float(gc["wall_length"]) * 0.5
	var gt := Gate.new()
	gt.a = center - along * half
	gt.b = center + along * half
	gt.normal = fwd
	gt.zone = _zone
	gt.born = game.elapsed
	gt.ev = ev
	gt.next_spawn = game.elapsed + float(gc["garrison_first"])
	var r := float(game.enemies.enemy_def(CitadelEnemyData.GENERATOR)["radius"])  # Generator body radius.
	for end: Vector2 in [gt.a, gt.b]:
		var at := game.arena.free_point(end + fwd * float(gc["generator_back"]), r)
		var e := game.enemies.spawn_at(CitadelEnemyData.GENERATOR, at, false)
		e.is_objective = true
		game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT)
		gt.gens.append(e)
		gt.gen_ids.append(e.generation)
		game.effects.spawn_ring(e.position, Palette.EMPIRE_SIGNAL_AMBER)
	gates.append(gt)
	for k in int(gc["turrets"]):
		var side := (float(k) - (float(gc["turrets"]) - 1.0) * 0.5) * float(gc["turret_spread"])  # Offset along the wall.
		_place_turret(center + along * side + fwd * float(gc["turret_back"]))
	game.stat_add("citadel_gates_raised", 1.0)
	Sfx.play("gate_hum", center)
	_log("gate_raised")


## Gates: dead generators bring the wall down; standing gates send their
## garrison; a gate left far behind powers down quietly.
func _step_gates() -> void:
	var gc: Dictionary = config["gate"]
	var i := gates.size() - 1
	while i >= 0:
		var gt := gates[i]
		var alive := _gens_alive(gt)
		if alive == 0:
			_break_gate(gt)
			gates.remove_at(i)
		elif _mid(gt).distance_to(game.player.position) > float(gc["despawn_distance"]):
			_power_down(gt)
			gates.remove_at(i)
		elif game.elapsed >= gt.next_spawn:
			gt.next_spawn += float(gc["garrison_interval"])
			_garrison(gt, gt.ev.get("garrison", []), false)
		i -= 1


## Living generators of `gt`.
func _gens_alive(gt: Gate) -> int:
	var n := 0
	for k in gt.gens.size():
		var e := gt.gens[k]
		if e.active and e.generation == gt.gen_ids[k]:
			n += 1
	return n


## Centre of `gt`'s wall.
static func _mid(gt: Gate) -> Vector2:
	return (gt.a + gt.b) * 0.5


## A garrison squad pours out of the wall on the necromancer's side (groups as
## the timeline's {kind, count, elite}); `force` (a lockdown) ignores the soft cap
## (only HARD_CAP applies).
func _garrison(gt: Gate, groups: Array, force: bool) -> void:
	var p := game.player.position
	if not force and _mid(gt).distance_to(p) > float(config["gate"]["active_radius"]):
		return
	var cap := game.enemies.hard_cap() if force else mini(game.enemies.soft_cap(), game.enemies.hard_cap() - 10)  # Room for the squad.
	var spawned := 0  # Soldiers sent this time.
	for grp: Dictionary in groups:
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= cap:
				break
			var at := gt.a.lerp(gt.b, randf_range(0.2, 0.8)) - gt.normal * 26.0  # Out of the wall, his side.
			game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
			spawned += 1
	if spawned > 0:
		game.effects.spawn_ring(_mid(gt) - gt.normal * 20.0, Palette.EMPIRE_SIGNAL_RED)
		game.stat_add("citadel_garrison_spawned", float(spawned))


## Both generators fell: the wall comes down, its reward is paid.
func _break_gate(gt: Gate) -> void:
	var gc: Dictionary = config["gate"]
	gates_broken += 1
	game.stat_add("citadel_gates_broken", 1.0)
	game.stat_add("objective_ash", float(gc["ash"]))
	var mid := _mid(gt)
	var n := maxi(1, int(gc["reward_crystals"]))
	var each := maxi(1, floori(float(gc["reward_xp"]) / float(n)))  # XP per crystal.
	for k in n:
		game.pickups.spawn(mid + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 52.0), each)
	for k in 5:
		game.effects.impact(gt.a.lerp(gt.b, float(k) / 4.0), 34.0, Palette.EMPIRE_SIGNAL_AMBER, EmpireFxData.BLAST)  # Its strip when the art exists (visual only).
	game.shake(6.0)
	Sfx.play("gate_fall", mid)
	var zones: Array = config["zones"]
	var next := String(zones[mini(gt.zone + 1, zones.size() - 1)]["name"])  # The zone it led into.
	game.enemies.show_banner("The Shield Gate falls: the way into %s lies open!" % next)
	_log("gate_broken")


## A gate still holds when its zone ends: LOCKDOWN. A last garrison wave
## storms out, the wall powers down, and the guns of the new zone fire faster.
func _lockdown(gt: Gate) -> void:
	var gc: Dictionary = config["gate"]
	lockdowns += 1
	game.stat_add("citadel_lockdowns", 1.0)
	_garrison(gt, gc["lockdown_groups"], true)
	_gun_mult = float(gc["lockdown_gun_mult"])
	_power_down(gt)
	game.enemies.show_banner("LOCKDOWN: the gate held, and the Citadel's guns lock on!")
	_log("lockdown")


## Takes a gate's generators off the field without a reward (the wall fades).
func _power_down(gt: Gate) -> void:
	for k in gt.gens.size():
		var e := gt.gens[k]
		if e.active and e.generation == gt.gen_ids[k]:
			game.effects.pop(e.position, Palette.EMPIRE_SIGNAL_RED, 18.0)
			game.enemies.despawn(e)


## THE gate push-out (Arena.resolve_all(), after the obstacles): a standing
## wall is solid for the necromancer, who is pushed back out to the side he is
## on. His dead and every enemy pass through it (the shield reads the living).
func contain_all() -> void:
	if gates.is_empty():
		return
	var half := float(config["gate"]["wall_thickness"]) * 0.5
	for pl in game.all_players:  # (Co-op: each necromancer.)
		for gt in gates:
			var ab := gt.b - gt.a
			var t := clampf((pl.position - gt.a).dot(ab) / maxf(1.0, ab.length_squared()), 0.0, 1.0)
			var near := gt.a + ab * t  # Closest point of the wall.
			var off := pl.position - near
			var reach := half + pl.radius
			var dist := off.length()
			if dist >= reach:
				continue
			var n := off / dist if dist > 0.01 else -gt.normal
			pl.position = near + n * reach
			game.stat_add("citadel_wall_pushes", 1.0)


# =====================================================================================
# Sentry turrets
# =====================================================================================

## Places `ev.count` turrets `distance_min`..`distance_max` px from the
## necromancer, spread evenly round him (out of obstacles), plus the event's escort.
func _place_turrets(ev: Dictionary) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU
	var p := game.player.position
	for i in n:
		var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.3, 0.3)
		_place_turret(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])))
	var escort: Dictionary = ev.get("escort", {})
	if not escort.is_empty():
		game.enemies.spawn_formation(String(escort["formation"]), escort["groups"])
	_log("turrets_%d" % n)


## One turret at `at` (moved out of obstacles), unless the cap is reached.
func _place_turret(at: Vector2) -> void:
	var tc: Dictionary = config["turrets"]
	if _turrets_alive() >= int(tc["max_alive"]):
		return
	var r := float(game.enemies.enemy_def(CitadelEnemyData.TURRET)["radius"])
	var e := game.enemies.spawn_at(CitadelEnemyData.TURRET, game.arena.free_point(at, r), false)
	e.is_objective = true
	game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT)
	game.effects.spawn_ring(e.position, Palette.EMPIRE_SIGNAL_AMBER)
	var t := Turret.new()
	t.enemy = e
	t.gen = e.generation
	t.pos = e.position
	turrets.append(t)
	game.stat_add("citadel_turrets_placed", 1.0)


## Fallen turrets pay their bounty; turrets left far behind are taken off.
func _step_turrets() -> void:
	var tc: Dictionary = config["turrets"]
	var i := turrets.size() - 1
	while i >= 0:
		var t := turrets[i]
		var e := t.enemy
		if not e.active or e.generation != t.gen:
			turrets.remove_at(i)
			game.stat_add("citadel_turrets_destroyed", 1.0)
			game.stat_add("objective_ash", float(game.enemies.enemy_def(CitadelEnemyData.TURRET)["bounty_ash"]))
			game.effects.impact(t.pos, 40.0, Palette.EMPIRE_SIGNAL_AMBER, EmpireFxData.BLAST)  # Its strip when the art exists (visual only).
		elif t.pos.distance_to(game.player.position) > float(tc["despawn_distance"]):
			turrets.remove_at(i)
			game.enemies.despawn(e)
			game.stat_add("citadel_turrets_left", 1.0)
		i -= 1


## Living turrets.
func _turrets_alive() -> int:
	var n := 0
	for t in turrets:
		if t.enemy.active and t.enemy.generation == t.gen:
			n += 1
	return n


# =====================================================================================
# Valkyrie 2.0 and the guests
# =====================================================================================

## Sends the miniboss from the spawn ring with her escort around her.
func _send_valkyrie(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(game.enemies.resolve_kind(String(ev["kind"]))), at, false)
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 30.0), bool(grp["elite"]))
	_log("valkyrie")


## Sends one guest squad from the spawn ring (one weighted kind, the soft cap
## respected like any continuous source).
func _send_guests() -> void:
	var total := 0.0
	for g: Array in guests:
		total += float(g[1])
	var roll := randf() * total
	var kind := String(guests[0][0])
	for g: Array in guests:
		roll -= float(g[1])
		if roll <= 0.0:
			kind = String(g[0])
			break
	var n := mini(int(config["guest_count"]) + floori(float(_guest_squads) * float(config["guest_growth"])), int(config["guest_max"]))
	var room := game.enemies.soft_cap() - game.enemies.regular_alive()  # Soft-cap room.
	n = mini(n, maxi(0, room))
	_guest_squads += 1
	if n <= 0:
		return
	game.enemies.spawn_formation("arc", [{"kind": kind, "count": n, "elite": false}])
	game.stat_add("citadel_guest_squads", 1.0)
	game.stat_add("citadel_guests_spawned", float(n))


# =====================================================================================
# The Citadel's guns (orbital strikes, EmpireRules.strike())
# =====================================================================================

## Fires the zone's gun salvo when it is due (none once the countdown ended:
## the Purge Protocol owns the sky then).
func _step_guns() -> void:
	if _guns.is_empty() or game.elapsed < _next_salvo:
		return
	if game.countdown_finished():
		_next_salvo = INF
		return
	var boss := game.enemies.boss
	var fighting := boss != null and boss.active  # The stage boss is on the field.
	var gap := float(_guns["interval"]) * _gun_mult * (float(_guns["boss_mult"]) if fighting else 1.0)
	_next_salvo = game.elapsed + gap
	var rules := game.empire_rules()
	var p := game.player.position
	var r := float(_guns["radius"])
	var n := int(_guns["count"])
	for k in n:
		var at := p
		if k > 0:
			at = p + Vector2.from_angle(randf() * TAU) * randf_range(r, float(_guns["scatter"]))
		rules.strike(at, float(_guns["telegraph"]), r, float(_guns["damage"]), float(_guns["summon_damage"]), "citadel_gun", "citadel_gun")
	game.stat_add("citadel_gun_salvos", 1.0)
	game.stat_add("citadel_gun_strikes", float(n))


# =====================================================================================
# Laser grids
# =====================================================================================

## Runs the laser rhythm: lay a grid, telegraph it, sweep it, rest.
func _step_lasers(delta: float) -> void:
	if _lasers.is_empty():
		return
	match _laser_phase:
		0:
			if game.elapsed >= _next_laser and not game.countdown_finished():
				_lay_grid()
		1:
			_laser_time += delta
			if _laser_time >= float(_lasers["telegraph"]):
				_laser_phase = 2
				_laser_time = 0.0
				_laser_k = 0.0
				_laser_hits.clear()
				Sfx.play("laser_fire", game.player.position)
		2:
			_laser_time += delta
			var k := clampf(_laser_time / maxf(0.01, float(_lasers["sweep_time"])), 0.0, 1.0)
			_laser_hit(_laser_k, k)
			_laser_k = k
			if k >= 1.0:
				_laser_phase = 0
				_next_laser = game.elapsed + float(_lasers["interval"])


## Lays the next grid across the necromancer's ground: `beams` parallel lines
## `spacing` px apart (one near him, offset by a seeded draw), their sweep
## normal turning every cycle.
func _lay_grid() -> void:
	var angles: Array = _lasers["angles"]
	_laser_n = Vector2.from_angle(deg_to_rad(float(angles[_laser_cycles % angles.size()])))
	_laser_cycles += 1
	_laser_origin = game.player.position
	var n := int(_lasers["beams"])
	var spacing := float(_lasers["spacing"])
	var jitter := randf_range(-0.5, 0.5) * spacing * 0.6  # So the grid never sits the same way on him twice.
	_beam_start.resize(n)
	for i in n:
		_beam_start[i] = (float(i) - float(n - 1) * 0.5) * spacing + jitter - float(_lasers["sweep"]) * 0.5
	_laser_phase = 1
	_laser_time = 0.0
	game.stat_add("citadel_laser_cycles", 1.0)
	Sfx.play("laser_charge", game.player.position)


## Signed offset of `p` along the grid's sweep normal (px from the origin).
func _offset(p: Vector2) -> float:
	return (p - _laser_origin).dot(_laser_n)


## True if a body of radius `r` at `p` lies in the band a beam swept from sweep
## fraction `k0` to `k1` (and within the beam's half length).
func _in_band(p: Vector2, r: float, k0: float, k1: float) -> bool:
	var along := absf((p - _laser_origin).dot(Vector2(-_laser_n.y, _laser_n.x)))  # Along the beam (px from the origin).
	if along > float(_lasers["length"]) * 0.5:
		return false
	var o := _offset(p)
	var w := float(_lasers["width"]) * 0.5 + r
	var sw := float(_lasers["sweep"])
	for s0 in _beam_start:
		if o >= s0 + sw * k0 - w and o <= s0 + sw * k1 + w:
			return true
	return false


## The beams moved from sweep fraction `k0` to `k1` this tick: everything they
## crossed is hit once per cycle.
func _laser_hit(k0: float, k1: float) -> void:
	var lc := _lasers
	var mult := game.enemies.damage_mult  # Time scaling of the fortress's beams.
	for pl in game.all_players:  # (Co-op: every necromancer the beams cross, once a cycle.)
		if not _laser_hits.has(pl) and _in_band(pl.position, pl.radius, k0, k1):
			_laser_hits[pl] = 0
			game.combat.damage_player(float(lc["damage_player"]) * mult, "laser_grid", pl)
			game.stat_add("citadel_laser_player_hits", 1.0)
	var reach := float(lc["length"]) * 0.5
	game.ally_grid.query(_laser_origin, reach, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if _laser_hits.has(u) and int(_laser_hits[u]) == u.generation:
			continue
		if _in_band(u.position, u.radius, k0, k1):
			_laser_hits[u] = u.generation
			game.combat.damage_unit(u, float(lc["damage_summon"]) * mult, "laser_grid")
			game.stat_add("citadel_laser_summon_hits", 1.0)
	var hits: Array = []  # Own buffer: kills may query the grid again.
	game.enemy_grid.query(_laser_origin, reach, hits)
	for e: Enemy in hits:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.is_reckoning:
			continue
		if _laser_hits.has(e) and int(_laser_hits[e]) == e.generation:
			continue
		if _in_band(e.position, e.radius, k0, k1):
			_laser_hits[e] = e.generation
			game.combat.damage_enemy(e, float(lc["damage_enemy"]) * game.enemies.hp_mult, "laser_grid")
			game.stat_add("citadel_laser_enemy_hits", 1.0)


# =====================================================================================
# HUD, autopilot, summary
# =====================================================================================

## HUD objective while a gate stands or turrets fire ("" = none).
func objective_override() -> String:
	if not gates.is_empty():
		return "Destroy the Shield Gate's generators before the zone falls (%d left)" % _gens_alive(gates[0])
	var n := _turrets_alive()
	if n > 0 and game.enemies.boss == null:
		return "Silence the sentry turrets (%d left)" % n
	return ""


## Autopilot hint: the nearest generator, else turret, within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for gt in gates:
		for k in gt.gens.size():
			var e := gt.gens[k]
			if e.active and e.generation == gt.gen_ids[k] and p.distance_to(e.position) < best_d:
				best_d = p.distance_to(e.position)
				best = e.position
	if best != Vector2.INF:
		return best
	for t in turrets:
		var dd := p.distance_to(t.pos)
		if t.enemy.active and t.enemy.generation == t.gen and dd < best_d:
			best_d = dd
			best = t.pos
	return best


## Autopilot hint: out of a telegraphed laser band (toward the nearer gap), and
## back off a gate wall.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if _laser_phase == 1 and not _lasers.is_empty():
		var o := _offset(p)
		var w := float(_lasers["width"]) * 0.5 + game.player.radius + 14.0
		var sw := float(_lasers["sweep"])
		for s0 in _beam_start:
			if o >= s0 - w and o <= s0 + sw + w:
				var mid := s0 + sw * 0.5  # Centre of the band.
				push += _laser_n * (1.0 if o >= mid else -1.0) * 1.5
	return push


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "gates raised %d, broken %d, lockdowns %d, garrison %d, wall pushes %d | lasers: cycles %d, hits you %d / summons %d / enemies %d (dmg to you %d, enemy dmg %d) | guns: salvos %d, strikes %d, hits on you %d (dmg %d), summon dmg %d | turrets placed %d, destroyed %d, left behind %d | guests: %s, squads %d, spawned %d | objective ash %d" % [
		int(st.get("citadel_gates_raised", 0.0)), gates_broken, lockdowns, int(st.get("citadel_garrison_spawned", 0.0)), int(st.get("citadel_wall_pushes", 0.0)),
		int(st.get("citadel_laser_cycles", 0.0)), int(st.get("citadel_laser_player_hits", 0.0)), int(st.get("citadel_laser_summon_hits", 0.0)),
		int(st.get("citadel_laser_enemy_hits", 0.0)), int(st.get("player_dmg_from_laser_grid", 0.0)), int(st.get("dmg_laser_grid", 0.0)),
		int(st.get("citadel_gun_salvos", 0.0)), int(st.get("citadel_gun_strikes", 0.0)), int(st.get("citadel_gun_player_hits", 0.0)),
		int(st.get("player_dmg_from_citadel_gun", 0.0)), int(st.get("summon_dmg_from_citadel_gun", 0.0)),
		int(st.get("citadel_turrets_placed", 0.0)), int(st.get("citadel_turrets_destroyed", 0.0)), int(st.get("citadel_turrets_left", 0.0)),
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("citadel_guest_squads", 0.0)),
		int(st.get("citadel_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])


# =====================================================================================
# Drawing: the gate walls and the laser grid
# =====================================================================================

func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var thick := float(config["gate"]["wall_thickness"])
	for gt in gates:
		var power := clampf((now - gt.born) / 0.8, 0.0, 1.0)  # The wall powers up as it rises.
		CitadelGlyphs.draw_gate_wall(self, gt.a, gt.b, thick, power, now)
		for k in gt.gens.size():
			var e := gt.gens[k]
			if e.active and e.generation == gt.gen_ids[k]:
				CitadelGlyphs.draw_gate_cable(self, e.position, gt.a if k == 0 else gt.b, now)
	if _laser_phase != 0 and not _lasers.is_empty():
		var along := Vector2(-_laser_n.y, _laser_n.x)
		var half := float(_lasers["length"]) * 0.5
		var sw := float(_lasers["sweep"])
		for s0 in _beam_start:
			var k := _laser_k if _laser_phase == 2 else 0.0
			var c := _laser_origin + _laser_n * (s0 + sw * k)  # The beam's line now.
			var tele := clampf(_laser_time / maxf(0.01, float(_lasers["telegraph"])), 0.0, 1.0) if _laser_phase == 1 else 1.0
			CitadelGlyphs.draw_laser(self, c - along * half, c + along * half, float(_lasers["width"]), _laser_phase == 2, tele, now)
			if _laser_phase == 1:
				CitadelGlyphs.draw_laser_band(self, _laser_origin + _laser_n * s0, _laser_n, along, half, sw, tele)
