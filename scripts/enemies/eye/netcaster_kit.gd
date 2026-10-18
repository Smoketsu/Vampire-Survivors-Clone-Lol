## NetcasterKit — the Netcaster's net (Act II, Gullhaven Harbour;
## HarbourEnemyData "netcaster", GDD §15.0 "Gullhaven Harbour (Act II phase
## 2)"; owner-approved roster "throws a net that pins one summon in place for
## 3 s"). Its body is the shared "melee" AI: it always advances on its target
## and strikes with its gaff in contact. On top of that:
##   * Net: when the cooldown is up and a summon stands within net_range px
##     (the nearest one not already netted, never a flying Gargoyle), it stops
##     and aims: a thin line to that summon is telegraphed for net_telegraph s,
##     then the net flies (net_flight s) and lands on it: net_damage
##     (time-scaled, source "netcaster_net") and the summon is pinned in place
##     for net_pin s: it can still strike, but cannot walk (the generic hold,
##     SummonedUnit.held_until). The netcaster stands net_recover s, then
##     walks on.
##   * Cut the caster: when the Netcaster dies (or leaves the field) its net
##     falls apart and the summon is free at once.
##   * A summon that was just netted cannot be netted again for net_immunity s
##     after its net ends (several Netcasters never hold one summon for good).
## The net (in flight and on the pinned summon) is drawn on the Netcaster's
## overlay layer at world-axis offsets (unmirror()), redrawn every tick while
## it shows. A Netcaster casts one net at a time.
## Determinism (CLAUDE.md): no RNG; the first net is staggered by the think
## slot. Stats: netcaster_nets (thrown), netcaster_pins (landed),
## netcaster_misses, netcaster_pin_seconds, netcaster_nets_cut (freed early).
class_name NetcasterKit
extends CovenantKit

## Phase: the aim line is telegraphed.
const WINDUP: int = 1
## Phase: the net is in the air.
const FLIGHT: int = 2
## Phase: standing after the throw.
const RECOVER: int = 3
## Damage source tag of the net.
const SOURCE: String = "netcaster_net"

## Seconds until the next net may start (counts down while walking).
var cd: float = 0.0
## The summon aimed at (null = none).
var aim: SummonedUnit = null
## Generation of `aim` when chosen (stale guard).
var aim_gen: int = 0
## Where the net left the Netcaster's hands (world px).
var from: Vector2 = Vector2.ZERO
## The summon pinned by this Netcaster's net (null = none).
var pinned: SummonedUnit = null
## Generation of `pinned` when the net landed.
var pinned_gen: int = 0
## Game time (s) the pin ends.
var pinned_until: float = 0.0
## Reusable query buffer.
var _tmp: Array = []

## Summon -> [generation, game time its net immunity ends, its Game] for
## every summon a net landed on (shared by every Netcaster; the Game entry
## keeps one run's records from counting in the next).
static var _immune: Dictionary = {}


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["net_first"]))
	aim = null
	pinned = null


## The net falls apart with its caster: the pinned summon is free.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if _pin_alive(e):
		pinned.held_until = 0.0
		if e.game != null:
			e.game.stat_add("netcaster_nets_cut", 1.0)
	pinned = null
	aim = null


## Aims at the nearest summon in reach when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0 or _pin_alive(e):
		return
	var reach := float(d["net_range"])
	var best: SummonedUnit = null
	var best_d := INF
	e.game.ally_grid.query(e.position, reach, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue
		if u.held_until > e.game.elapsed:
			continue  # Already netted.
		var rec: Variant = _immune.get(u)  # Its last net, if any.
		if rec != null and (rec as Array)[2] == e.game and int((rec as Array)[0]) == u.generation and e.game.elapsed < float((rec as Array)[1]):
			continue  # Netted a moment ago.
		var dist := e.position.distance_to(u.position)
		if dist <= reach and dist < best_d:
			best_d = dist
			best = u
	if best == null:
		return
	aim = best
	aim_gen = best.generation
	e.game.effects.telegraph_line(e.position, best.position, 10.0, float(d["net_telegraph"]), e)
	e.game.stat_add("netcaster_nets", 1.0)
	set_phase(e, WINDUP)


## True while `aim` is still the same living summon.
func _aim_alive() -> bool:
	return aim != null and aim.active and aim.generation == aim_gen


## True while this Netcaster's net still holds a living summon.
func _pin_alive(e: Enemy) -> bool:
	return pinned != null and pinned.active and pinned.generation == pinned_gen and e.game != null and e.game.elapsed < pinned_until


func physics(e: Enemy, delta: float) -> bool:
	if _pin_alive(e):
		e.game.stat_add("netcaster_pin_seconds", delta)
		e.queue_redraw()
	elif pinned != null:
		pinned = null
		e.queue_redraw()
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			if not _aim_alive():
				set_phase(e, RECOVER)
			elif phase_time >= float(d["net_telegraph"]):
				from = e.position
				e.motion_lunge(aim.position - e.position, MotionData.POWER_SHOT)  # Engine motion: the throw (visual only).
				set_phase(e, FLIGHT)
		FLIGHT:
			e.queue_redraw()
			if phase_time >= float(d["net_flight"]):
				_land(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["net_recover"]):
				cd = float(d["net_cooldown"])
				aim = null
				set_phase(e, IDLE)
	return true


## The net lands on the aimed summon (if it still lives and is in reach).
func _land(e: Enemy) -> void:
	var g := e.game
	if not _aim_alive() or aim.airborne or aim.position.distance_to(e.position) > float(d["net_range"]) * 1.4:
		g.stat_add("netcaster_misses", 1.0)
		return
	pinned = aim
	pinned_gen = aim_gen
	pinned_until = g.elapsed + float(d["net_pin"])
	_immune[pinned] = [pinned_gen, pinned_until + float(d["net_immunity"]), g]
	pinned.held_until = maxf(pinned.held_until, pinned_until)
	g.combat.damage_unit(pinned, float(d["net_damage"]) * hit_scale(e), SOURCE)
	g.stat_add("netcaster_pins", 1.0)
	Sfx.play("orb_block", pinned.position, 0.7)


## The net in flight and on the pinned summon (world-axis offsets).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var show_flight := phase == FLIGHT and _aim_alive()
	if not show_flight and pinned == null:
		return
	unmirror(e, ci)
	if show_flight:
		var k := clampf(phase_time / maxf(0.01, float(d["net_flight"])), 0.0, 1.0)
		var at := from.lerp(aim.position, k) - e.position  # Net position relative to the Netcaster.
		HarbourGlyphs.draw_net(ci, at, aim.radius * (0.6 + 0.4 * k), 0.9)
	if pinned != null and pinned.active and pinned.generation == pinned_gen:
		var left := clampf((pinned_until - e.game.elapsed) / maxf(0.01, float(d["net_pin"])), 0.0, 1.0)  # Fades as it ends.
		HarbourGlyphs.draw_net(ci, pinned.position - e.position, pinned.radius, 0.5 + 0.5 * left)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
