## BetaBuildKit — THE BETA BUILD, the Assembly Halls' miniboss (Act III;
## AssemblyEnemyData "beta_build", GDD §15.0 "The Assembly Halls (Act III phase
## 2)"; owner-approved proposal: "an unfinished mech that keeps patching itself
## from any fabricator still standing, so smashing the fabricators first is the
## way to kill it"). Spawned once by AssemblyDirector (the "beta_build" event,
## 9:00 left) through the normal spawn path. It walks at the necromancer
## (strides faster beyond advance_range: it never kites and is never left
## behind), punches what it reaches and, between attack_gap pauses, uses one of
## two telegraphed specials (alternating when both are usable, no RNG):
##   Weld swipe  — a sector toward the necromancer for swipe_telegraph s, then
##                 the welding arm sweeps it: summons inside are hurt and thrown
##                 out, the necromancer inside hurt.
##   Rivet spray — the rivet cannon charges rivets_telegraph s, then a fan of
##                 rivets_count rivets flies at the necromancer through
##                 EmpireShots (Line of Fire: the army in front soaks them).
## PATCHING: every patch_tick s it regains patch_rate of its max HP per second
## for every fabricator still standing anywhere (at most patch_max), through
## CombatResolver.heal_enemy() (a regeneration, not a cast); amber patch cables
## run to the fabricators within patch_beam_reach px (drawn). Like a boss it
## shrugs off knockback; freeze / stun durations use the caller's boss share and
## Stasis holds it only for the boss share (Enemy.is_miniboss); it is never
## recycled. It registers as EnemyDirector.miniboss for the HUD's health bar.
## On death: an XP burst (reward_xp in reward_crystals) and the miniboss chest
## (ChestManager). A MACHINE: no corpse.
## Stats: beta_swipe_used, beta_rivets_used, beta_swipe_hits, beta_patched_hp,
## beta_patch_ticks_with_fabs, beta_kills, beta_ttk.
class_name BetaBuildKit
extends EmpireKit

## Phase: the swipe sector is telegraphed.
const SWIPE_WINDUP: int = 1
## Phase: the rivet cannon charges.
const RIVETS_WINDUP: int = 2
## Phase: standing after a special.
const RECOVER: int = 3
## Special ids in alternation order.
const SPECIALS := ["swipe", "rivets"]
## Damage source tag of the swipe (an area hit for Unholy Resilience).
const SWIPE_SOURCE: String = "beta_swipe"

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## The special used last (the other one goes next when both are usable).
var last_special: String = ""
## Unit direction of the current special (locked at its windup).
var dir: Vector2 = Vector2.RIGHT
## Seconds until the next patch tick.
var _patch_cd: float = 0.0
## Walking speed before the forced march (px/s; read on the first tick so the
## difficulty's speed multiplier is included; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Fabricators it patched from at the last tick (drawn as cables).
var _sources: Array[Enemy] = []
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SPECIALS:
		cds[id] = 0.0
	last_special = ""
	_base_speed = -1.0
	_patch_cd = float(d["patch_tick"])
	_spawned_at = e.game.elapsed
	_sources.clear()
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("beta_spawned", 1.0)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
	var swipe_ok := float(cds["swipe"]) <= 0.0 and dist <= float(d["swipe_range"])
	var rivets_ok := float(cds["rivets"]) <= 0.0 and dist <= float(d["rivets_range"])
	if swipe_ok and rivets_ok:
		if last_special == "swipe":
			swipe_ok = false
		else:
			rivets_ok = false
	var to_p := e.game.player.position - e.position
	dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	if swipe_ok:
		e.game.effects.telegraph_cone(e.position, dir, float(d["swipe_radius"]), float(d["swipe_half_angle"]), float(d["swipe_telegraph"]), e)
		e.motion_lunge(-dir, MotionData.POWER_CAST)  # Engine motion: the arm draws back (visual only).
		_begin(e, "swipe", SWIPE_WINDUP)
	elif rivets_ok:
		var n := int(d["rivets_count"])
		var spread := float(d["rivets_spread"])
		for i in n:
			var a := (float(i) - float(n - 1) * 0.5) * spread
			e.game.effects.telegraph_line(e.position, e.position + dir.rotated(a) * minf(float(d["rivets_range"]), 300.0), 8.0, float(d["rivets_telegraph"]), e)
		_begin(e, "rivets", RIVETS_WINDUP)


## Starts special `id`: cooldown, stat, phase.
func _begin(e: Enemy, id: String, p: int) -> void:
	last_special = id
	cds[id] = float(d[id + "_cooldown"])
	e.game.stat_add("beta_" + id + "_used", 1.0)
	set_phase(e, p)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	for id: String in SPECIALS:
		cds[id] = float(cds[id]) - delta
	_step_patch(e, delta)
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
		return false
	phase_time += delta
	hold(e)
	match phase:
		SWIPE_WINDUP:
			if phase_time >= float(d["swipe_telegraph"]):
				_resolve_swipe(e)
				set_phase(e, RECOVER)
		RIVETS_WINDUP:
			if phase_time >= float(d["rivets_telegraph"]):
				_fire_rivets(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Patching: HP from every fabricator still standing (see the header).
func _step_patch(e: Enemy, delta: float) -> void:
	_patch_cd -= delta
	if _patch_cd > 0.0:
		return
	_patch_cd += float(d["patch_tick"])
	var g := e.game
	_sources.clear()
	var ad := g.enemies.assembly  # Null off the Assembly Halls (then nothing patches it).
	if ad == null:
		return
	var fabs := ad.standing_fabricators()
	if fabs.is_empty():
		return
	var n := mini(fabs.size(), int(d["patch_max"]))
	for f in fabs:
		if f.position.distance_to(e.position) <= float(d["patch_beam_reach"]):
			_sources.append(f)
	var healed := g.combat.heal_enemy(e, e.max_hp * float(d["patch_rate"]) * float(d["patch_tick"]) * float(n))
	g.stat_add("beta_patched_hp", healed)
	g.stat_add("beta_patch_ticks_with_fabs", 1.0)
	e.queue_redraw()


## The welding arm sweeps the sector: hits and throws summons out.
func _resolve_swipe(e: Enemy) -> void:
	var g := e.game
	var r := float(d["swipe_radius"])
	var half := float(d["swipe_half_angle"])
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	g.effects.slash(e.position + dir * e.radius, dir, Palette.EMPIRE_SIGNAL_AMBER, r * 0.8)
	e.motion_lunge(dir, MotionData.POWER_MELEE)  # Engine motion: the swing (visual only).
	g.shake(6.0)
	Sfx.play("boss_impact", e.position, 1.1)
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, r, half, e.radius, u.position, u.radius):
			continue
		hits += 1
		var away := u.position - e.position
		u.position += (away.normalized() if away.length() > 0.5 else dir) * float(d["swipe_knockback"])
		g.combat.damage_unit(u, float(d["swipe_damage_summon"]) * mult, SWIPE_SOURCE)
	g.stat_add("beta_swipe_hits", float(hits))
	for p in g.all_players:  # (Co-op: every necromancer inside.)
		if in_sector(e.position, dir, r, half, e.radius, p.position, p.radius):
			g.combat.damage_player(float(d["swipe_damage_player"]) * mult, SWIPE_SOURCE, p)


## The rivet fan through EmpireShots (Line of Fire), aimed along `dir`.
func _fire_rivets(e: Enemy) -> void:
	var g := e.game
	var n := int(d["rivets_count"])
	var spread := float(d["rivets_spread"])
	var dmg := float(d["rivets_damage"]) * hit_scale(e)
	for i in n:
		var a := dir.rotated((float(i) - float(n - 1) * 0.5) * spread)
		g.empire_rules().shots.fire(e.position + a * (e.radius + 2.0), a, e.projectile_speed, dmg, e.undead_damage_mult, "rivet", e.kind, float(d["rivets_range"]))
	Sfx.play("rifle_burst", e.position, 0.8)
	e.motion_lunge(dir, MotionData.POWER_SHOT)


## XP burst on death (the chest comes from ChestManager's miniboss rule).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.EMPIRE_SIGNAL_AMBER)
	g.shake(10.0)
	g.enemies.show_banner("The Beta Build crashes to the floor: build cancelled!")
	g.stat_add("beta_kills", 1.0)
	g.stat_add("beta_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_sources.clear()
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the swipe sector / the rivet fan.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		SWIPE_WINDUP:
			if in_sector(e.position, dir, float(d["swipe_radius"]) + 30.0, float(d["swipe_half_angle"]) + 0.2, e.radius, p, 12.0):
				var away := p - e.position
				return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
		RIVETS_WINDUP:
			var rel := p - e.position
			if rel.dot(dir) > 0.0 and absf(rel.cross(dir)) < 60.0:
				var side := Vector2(-dir.y, dir.x)
				return side * (1.0 if rel.dot(side) >= 0.0 else -1.0)
	return Vector2.ZERO


## The amber patch cables to the fabricators feeding it.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if _sources.is_empty():
		return
	unmirror(e, ci)
	var k := 0.6 + 0.4 * sin(e.game.elapsed * 6.0)  # Cable pulse.
	for f in _sources:
		if f.active:
			ci.draw_line(Vector2(0, -e.radius * 0.5), f.position - e.position, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.35 * k), 2.0)
			AssemblyGlyphs.draw_arc_beam(ci, Vector2(0, -e.radius * 0.5), (f.position - e.position) * 0.25, k)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
