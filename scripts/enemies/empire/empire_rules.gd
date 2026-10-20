## EmpireRules — the Electronic Empire's shared rules (Act III; GDD §15.0
## "Act III foundation (phase 1)"), run as `Game.empire`. Null on Acts I and II
## (created in Game._ready() only for a stage whose STAGE has "empire": true),
## except that the first Empire shot or Lock-On asked on any other stage (an
## Empire kind forced there with --spawn=) creates it through
## Game.empire_rules(), so a kind works anywhere. Owns ONE path per rule:
##   shots   — EmpireShots: LINE OF FIRE. Every Empire shot is a real
##             projectile that stops on the first summon in its path (Bone Wall
##             segments stop it, Warder barriers absorb it); the necromancer is
##             hit only through the gaps. Arcing shots fly over everything.
##   lock_on — LockOn: LOCK-ON. Spotters paint a thin red line for 1.5 s, then a
##             heavy rail shot fires down it (at most 3 lines; a boss override).
##   steel   — STEEL HAS NO SOUL is gated in Enemy.leaves_corpse() /
##             rises_as_gunner() and HordeDirector.raise_corpse(); this node only
##             counts it (the autotest's "steel" line).
##   purge   — the Purge Protocol (the shared Act III Reckoning hook): after
##             0:00, on a stage whose RECKONING has an "orbital" dictionary,
##             orbital strikes land on telegraphed circles, faster each minute
##             (EmpireRulesData.PURGE; kill-drones are the RECKONING "kind").
##   strikes — THE one orbital strike path (strike()): a telegraphed circle
##             that lands after its telegraph and hits the necromancer and
##             every summon inside. The Purge Protocol's salvos use it, and so
##             do the Iron Citadel's guns (CitadelDirector, Act III phase 2),
##             each strike carrying its own radius, telegraph, damage and
##             stat tag (Purge Protocol behaviour and same-seed results unchanged).
## Stepped by Game right after the ProjectileManager. Determinism: no RNG but the
## seeded gameplay one, and only on Act III (Acts I and II never create it).
class_name EmpireRules
extends Node2D

## Owning run.
var game: Game
## Line of Fire: every Empire shot in flight (child node, drawn above the units).
var shots: EmpireShots
## Lock-On: the painted lines (child node, drawn above the shots).
var lock_on: LockOn
## Purge Protocol settings of this stage (EmpireRulesData.PURGE overridden by
## the RECKONING's "orbital" keys; {} = no orbital strikes).
var purge: Dictionary = {}
## Game time (s) of the next orbital salvo (INF until the Reckoning starts).
var _next_salvo: float = INF
## Pending orbital strikes: x, y = the circle's centre (world px), z = the game
## time (s) it lands. Parallel to _strike_shape / _strike_dmg / _strike_src.
var _strikes: Array[Vector3] = []
## Per pending strike: x = circle radius (px), y = telegraph length (s).
var _strike_shape: PackedVector2Array = PackedVector2Array()
## Per pending strike: x = damage to the necromancer, y = damage to each summon
## inside (both before the time scaling, applied when it lands).
var _strike_dmg: PackedVector2Array = PackedVector2Array()
## Per pending strike: its damage source tag (CombatResolver stats).
var _strike_src: PackedStringArray = PackedStringArray()
## Per pending strike: its stat prefix ("purge": purge_player_hits; the
## Citadel's guns "citadel_gun": citadel_gun_player_hits).
var _strike_stat: PackedStringArray = PackedStringArray()
## Orbital salvos fired so far (stats, the deterministic scatter).
var salvos: int = 0
## Reusable spatial-hash query buffer.
var _tmp: Array = []
## True if the last redraw showed strike circles (one more redraw clears them).
var _drawn: bool = false
# --- Act III: the Scrap Wastes ---
## Stage reach modifiers (objects with reach_mult_at(pos: Vector2) -> float, e.g.
## the WastesDirector's Signal Pylons and scrap storms), multiplied by
## reach_mult(): the one reach path of the Empire's shooters (EmpireKit). Empty
## on every other stage (exactly 1).
var reach_sources: Array[Object] = []


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "EmpireRules"
	z_index = -1  # The strike circles lie on the ground, under the units.
	shots = EmpireShots.new(p_game)
	add_child(shots)
	lock_on = LockOn.new(p_game)
	add_child(lock_on)
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if r.has("orbital"):
		purge = EmpireRulesData.PURGE.duplicate()
		var over: Dictionary = r["orbital"]  # The stage's own overrides.
		for k: String in over:
			purge[k] = over[k]


## Per-tick update (Game, after the ProjectileManager): the shots, the Lock-On
## lines and the Purge Protocol's strikes.
func step(delta: float) -> void:
	shots.step(delta)
	lock_on.step(delta)
	if not purge.is_empty():
		_step_purge()
	_step_strikes()


# =====================================================================================
# Purge Protocol (orbital strikes after 0:00)
# =====================================================================================

## Fires the salvos on their clock (the strikes land in _step_strikes()).
func _step_purge() -> void:
	var t := game.elapsed  # Game time (s).
	if _next_salvo == INF and game.countdown_finished():
		_next_salvo = t
	if t >= _next_salvo:
		_salvo(t)


## Lands every pending strike whose time has come (in the order they were
## queued) and redraws the circles.
func _step_strikes() -> void:
	if _strikes.is_empty() and not _drawn:
		return
	var t := game.elapsed  # Game time (s).
	var i := 0
	while i < _strikes.size():
		var s := _strikes[i]
		if t >= s.z:
			var shape := _strike_shape[i]
			var dmg := _strike_dmg[i]
			var src := _strike_src[i]
			var stat := _strike_stat[i]
			_strikes.remove_at(i)
			_strike_shape.remove_at(i)
			_strike_dmg.remove_at(i)
			_strike_src.remove_at(i)
			_strike_stat.remove_at(i)
			_land(Vector2(s.x, s.y), shape.x, dmg.x, dmg.y, src, stat)
		else:
			i += 1
	if not _strikes.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _strikes.is_empty()


## THE one orbital strike path: queues a strike on a telegraphed circle of
## `radius` px at `at`, landing `telegraph` s from now; it then deals `damage`
## to the necromancer and `summon_damage` to each summon inside (both times the
## enemies' damage scaling when it lands), tagged `source`, its hits counted
## under `stat` ("<stat>_player_hits"). Used by the Purge Protocol's salvos and
## the Iron Citadel's guns.
func strike(at: Vector2, telegraph: float, radius: float, damage: float, summon_damage: float,
		source: String = "orbital_strike", stat: String = "purge") -> void:
	_strikes.append(Vector3(at.x, at.y, game.elapsed + telegraph))
	_strike_shape.append(Vector2(radius, telegraph))
	_strike_dmg.append(Vector2(damage, summon_damage))
	_strike_src.append(source)
	_strike_stat.append(stat)


## Pending strikes queued with stat prefix `stat` (CitadelDirector paces its
## guns by it).
func pending_strikes(stat: String) -> int:
	var n := 0
	for k in _strike_stat:
		if k == stat:
			n += 1
	return n


## Minutes past 0:00 (0 at the start of the Reckoning).
func _past_minutes() -> float:
	return maxf(0.0, game.elapsed - WaveData.RUN_DURATION) / 60.0


## One orbital salvo: a strike on the necromancer and the rest scattered
## around him, each telegraphed for purge.telegraph s.
func _salvo(t: float) -> void:
	var m := _past_minutes()  # Minutes past 0:00.
	var n := int(purge["count"]) + int(floorf(m)) * int(purge["count_growth"])  # Strikes this salvo.
	var tele := float(purge["telegraph"])  # Telegraph (s): the landing time is t + this.
	var r := float(purge["radius"])  # Circle radius (px).
	var centres: Array[Vector2] = [game.player.position]  # Necromancer (co-op: each standing one gets a salvo).
	if game.coop != null:
		centres.clear()
		for k in game.coop.alive_slots():
			centres.append(game.coop.slots[k].player.position)
	for p in centres:
		for k in n:
			var at := p
			if k > 0:
				at = p + Vector2.from_angle(randf() * TAU) * randf_range(r, float(purge["scatter"]))
			strike(at, tele, r, float(purge["damage"]), float(purge["summon_damage"]))
	salvos += 1
	game.stat_add("purge_salvos", 1.0)
	game.stat_add("purge_strikes", float(n * centres.size()))
	var gap := maxf(float(purge["interval_min"]), float(purge["interval"]) * pow(float(purge["speedup"]), m))  # s to the next salvo.
	_next_salvo = t + gap


## A strike of `r` px lands at `at`: the necromancer and every summon inside
## take its damage (`dmg` / `summon_dmg`, times the damage scaling), tagged
## `source`; a hit on him counts as "<stat>_player_hits".
func _land(at: Vector2, r: float, dmg: float, summon_dmg: float, source: String, stat: String) -> void:
	game.effects.impact(at, r, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("orbital_strike", at)
	for pl in game.all_players:  # Necromancer (co-op: either).
		if pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(dmg * game.enemies.damage_mult, source, pl)
			game.stat_add(stat + "_player_hits", 1.0)
	game.ally_grid.query(at, r + EmpireRulesData.LINE_OF_FIRE["summon_slack"], _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(at) <= r + u.radius:
			game.combat.damage_unit(u, summon_dmg * game.enemies.damage_mult, source)
	game.shake(3.0)


## Draws every pending orbital strike (the Purge Protocol's and the Citadel's
## guns', each with its own radius and telegraph): a warning-red circle (signal ramp,
## never the Covenant's telegraph gold) that fills as the strike nears, and a
## targeting cross at its centre. Visual only.
func _draw() -> void:
	for i in _strikes.size():
		var s := _strikes[i]
		var r := _strike_shape[i].x  # Circle radius (px).
		var tele := maxf(0.01, _strike_shape[i].y)  # Telegraph length (s).
		var c := Vector2(s.x, s.y)  # Circle centre.
		var k := clampf(1.0 - (s.z - game.elapsed) / tele, 0.0, 1.0)  # 0 -> 1 as it nears.
		draw_circle(c, r * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.18 + 0.12 * k))
		draw_arc(c, r, 0.0, TAU, 40, Color(Palette.EMPIRE_SIGNAL_RED, 0.85), 2.0)
		draw_arc(c, r * 0.55, 0.0, TAU, 28, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.5), 1.0)
		draw_line(c - Vector2(r * 0.3, 0), c + Vector2(r * 0.3, 0), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8), 1.0)
		draw_line(c - Vector2(0, r * 0.3), c + Vector2(0, r * 0.3), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8), 1.0)


# =====================================================================================
# Act III: the Scrap Wastes (the reach path)
# =====================================================================================

## Registers stage reach modifier `src` (an object with reach_mult_at(pos)).
func add_reach_source(src: Object) -> void:
	if not reach_sources.has(src):
		reach_sources.append(src)


## Multiplier (> 0) on the firing range of an Empire shooter standing at `pos`:
## the product of every stage reach modifier (1 when none is registered).
func reach_mult(pos: Vector2) -> float:
	var m := 1.0  # Product of the modifiers.
	for src: Object in reach_sources:
		m *= float(src.call("reach_mult_at", pos))
	return m


# =====================================================================================
# Autotest
# =====================================================================================

## Autopilot hint (the autotest bot): a push off every painted Lock-On line and
## out of every orbital strike circle about to land at `p` (the Purge Protocol's
## and the Citadel's guns').
func danger_push(p: Vector2) -> Vector2:
	var push := lock_on.danger_push(p)
	push += shots.arc_danger_push(p)  # Act III, the Scrap Wastes: off the mortar landing circles.
	for i in _strikes.size():
		var s := _strikes[i]
		var reach := _strike_shape[i].x + game.player.radius + 10.0  # Circle reach (px).
		var off := p - Vector2(s.x, s.y)  # Circle centre -> point.
		var d := off.length()
		if d < reach:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / reach) * 1.5
	return push


## The autotest's "line of fire" line (EmpireShots counters).
func line_of_fire_line() -> String:
	var st := game.stats  # Run counters.
	var fired := maxf(1.0, float(st.get("los_fired", 0.0)))  # Shots fired (never 0 for the shares).
	var summon := float(st.get("los_blocked_summon", 0.0))  # Stopped by a summon.
	var wall := float(st.get("los_blocked_wall", 0.0))  # Stopped by a Bone Wall segment.
	var orb := float(st.get("los_blocked_orb", 0.0))  # Intercepted by the Orb Shield.
	var player := float(st.get("los_hit_player", 0.0))  # Reached the necromancer.
	return "shots fired %d (rails %d, arcs %d) | stopped by summons %d (%.0f%%), absorbed by barriers %d | stopped by bone walls %d | orb intercepts %d | reached you %d (%.0f%%), dmg %d | arc bursts %d | expired %d | capped %d | peak %d/%d" % [
		int(st.get("los_fired", 0.0)), int(st.get("los_fired_heavy", 0.0)), int(st.get("los_fired_arc", 0.0)),
		int(summon), 100.0 * summon / fired, int(st.get("los_barrier_absorbed", 0.0)), int(wall), int(orb),
		int(player), 100.0 * player / fired, int(st.get("los_player_dmg", 0.0)), int(st.get("los_arc_bursts", 0.0)),
		int(st.get("los_expired", 0.0)), int(st.get("los_capped", 0.0)), shots.peak, int(EmpireRulesData.LINE_OF_FIRE["cap"])]


## The autotest's "lock-on" line (LockOn counters).
func lock_on_line() -> String:
	var st := game.stats  # Run counters.
	return "painted %d (on you %d, on summons %d) | refused at the cap %d | fired %d | cancelled (spotter killed) %d | rails stopped by summons %d, reached you %d (dmg %d) | most lines at once %d" % [
		int(st.get("lockon_painted", 0.0)), int(st.get("lockon_on_player", 0.0)), int(st.get("lockon_on_summon", 0.0)),
		int(st.get("lockon_refused", 0.0)), int(st.get("lockon_fired", 0.0)), int(st.get("lockon_cancelled", 0.0)),
		int(st.get("los_heavy_blocked", 0.0)), int(st.get("los_heavy_player", 0.0)), int(st.get("player_dmg_from_spotter_rail", 0.0)),
		lock_on.peak]


## The autotest's "steel" line (machine vs cyborg kills, Grave Gunners).
func steel_line() -> String:
	var st := game.stats  # Run counters.
	return "kills: machines %d (no corpse), cyborgs %d | grave gunners raised %d (death mark %d, lich %d, grave tide %d, drowned %d) | gunner dmg %d, kills %d" % [
		int(st.get("steel_kills_machine", 0.0)), int(st.get("steel_kills_cyborg", 0.0)), int(st.get("steel_gunners_raised", 0.0)),
		int(st.get("steel_gunners_from_death_mark_risen", 0.0)), int(st.get("steel_gunners_from_lich_risen", 0.0)),
		int(st.get("steel_gunners_from_grave_tide_risen", 0.0)), int(st.get("steel_gunners_from_drowned_thrall_ally", 0.0)),
		int(st.get("dmg_" + String(EmpireRulesData.STEEL["tag"]), 0.0)), int(st.get("kills_by_" + String(EmpireRulesData.STEEL["tag"]), 0.0))]


## The autotest's "purge protocol" line ("" when the stage has no orbital strikes).
func purge_line() -> String:
	if purge.is_empty():
		return ""
	var st := game.stats  # Run counters.
	return "salvos %d, strikes %d, hits on you %d (dmg %d), summon dmg %d" % [int(st.get("purge_salvos", 0.0)), int(st.get("purge_strikes", 0.0)),
		int(st.get("purge_player_hits", 0.0)), int(st.get("player_dmg_from_orbital_strike", 0.0)), int(st.get("summon_dmg_from_orbital_strike", 0.0))]
