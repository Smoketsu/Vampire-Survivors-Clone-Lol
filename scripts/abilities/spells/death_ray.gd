## DeathRay — the Death Ray spell (AbilityData "death_ray"; Act III, the Scrap
## Wastes; owner-approved Act III proposal: "A soul laser fires from the
## necromancer and sweeps a full circle around you every few seconds, cutting
## everything in its line out to about 420 px, so it reaches the shooters at
## range. It moves with you: nothing to stand in. Each kill on the beam sparks
## lightning to one nearby enemy"). Unlocked by slaying Kestrel (UnlockData),
## then offered on every stage; driven by NecroSpellBook's one dispatch
## (ACT3_IDS) with its EFFECTIVE stats (AbilityManager.spell_stats(): Soul
## Conduit, Abyssal Focus, Conductive Marrow's beam_length / beam_width...).
##   * Every `cooldown` s (start to start; DeathRayData.MIN_GAP at least between
##     two sweeps) a beam `beam_length` px long and `beam_width` px wide leaves
##     the necromancer, pointing at the nearest foe, and turns one full circle
##     around him in `sweep_time` s. It follows him as he walks.
##   * Every enemy the beam crosses takes `damage` once per sweep (its body
##     radius counts; the angular test is exact for the swept sector).
##   * A foe the beam kills sparks lightning (`spark` x the beam's damage) to
##     the nearest other foe within `spark_range` px; the Lightning Abbess's
##     innate sparks to one more (CharacterData "ray_extra_sparks").
## Evolved into Event Horizon (EvolutionData "event_horizon", detected by the
## "chain" key): `beams` beams sweep opposite each other, and every beam kill
## sets off wild chain lightning that arcs from foe to foe through up to
## `chain` enemies, losing `chain_falloff` per jump.
## A beam is not a projectile: an Aegis Bot's shield does not stop it. Sparks
## never spark again (only beam kills do). Drawn as violet soul lasers with a
## fading afterglow; the lightning reuses the Soul Chains arcs. Deterministic:
## no RNG (the jag patterns come from a counter). Stats: ray_sweeps, ray_hits,
## ray_kills, ray_sparks, ray_spark_kills, ray_chain_jumps, abbess_extra_sparks.
class_name DeathRay
extends NecroSpell

## One drawn lightning arc (pooled through `_arc_pool`).
class Arc:
	extends RefCounted
	## Start (world px).
	var a: Vector2 = Vector2.ZERO
	## End (world px).
	var b: Vector2 = Vector2.ZERO
	## Seconds left visible.
	var time_left: float = 0.0
	## Jag pattern seed (a counter).
	var jag_seed: int = 0
	## True for an Event Horizon chain (drawn with its outer glow).
	var wild: bool = false

## Seconds until the next sweep may start.
var _timer: float = DeathRayData.FIRST_SWEEP
## True while a sweep is turning.
var _sweeping: bool = false
## Angle (rad) of beam 0 now.
var _angle: float = 0.0
## Radians swept so far this sweep (a sweep ends at TAU).
var _swept: float = 0.0
## Effective stats of the current sweep (spell_stats(), kept for drawing).
var _stats: Dictionary = {}
## Enemy -> generation struck by the current sweep (once per sweep per beam:
## one dictionary per beam). Lookups only, never iterated.
var _struck: Array[Dictionary] = []
## Beam kills of this tick still allowed to spark (DeathRayData.SPARKS_PER_TICK).
var _sparks_left: int = 0
## Visible lightning arcs.
var _arcs: Array[Arc] = []
## Idle Arc records ready for reuse.
var _arc_pool: Array[Arc] = []
## Lightning casts so far (jag seeds).
var _jags: int = 0
## Enemies struck by the current spark / chain, in order.
var _chain: Array[Enemy] = []
## Own query buffer of the beam's sweep.
var _cand: Array = []
## Own query buffer of the spark search.
var _near: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Starts sweeps on cooldown, turns the beam, fades the arcs.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	if _sweeping:
		_turn(delta, stats)
	else:
		_timer -= delta
		if _timer <= 0.0:
			if not _start(stats):
				_timer = AbilityData.SPELL_RETRY
	var i := 0  # Index into _arcs (swap-remove).
	while i < _arcs.size():
		var arc := _arcs[i]
		arc.time_left -= delta
		if arc.time_left > 0.0:
			i += 1
		else:
			_arcs[i] = _arcs[_arcs.size() - 1]
			_arcs.pop_back()
			_arc_pool.append(arc)
	var busy := _sweeping or not _arcs.is_empty()  # Something to draw.
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Starts a sweep at the nearest foe within the beam's reach. Returns false
## when no foe is in reach (the spell then waits).
func _start(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := float(stats["beam_length"]) + DeathRayData.TRIGGER_SLACK  # Beam reach (px).
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null  # Nearest foe.
	var best_d := INF
	for e: Enemy in _cand:
		if not e.active:
			continue
		var d := p.distance_to(e.position) - e.radius
		if d <= reach and d < best_d:
			best_d = d
			best = e
	if best == null:
		return false
	_angle = (best.position - p).angle() - 0.05  # Start just before it.
	_swept = 0.0
	_sweeping = true
	var beams := maxi(1, int(stats.get("beams", 1)))  # Beams this sweep.
	_struck.resize(beams)
	for k in beams:
		_struck[k] = {}
	game.stat_add("ray_sweeps", 1.0)
	game.player.cast_motion(best.position)  # Engine motion: toward the first foe (visual only).
	Sfx.play("bolt_cast", p, DeathRayData.SWEEP_PITCH)
	return true


## Turns every beam by this tick's share of the circle and strikes what it crosses.
func _turn(delta: float, stats: Dictionary) -> void:
	var rate := TAU / maxf(0.1, float(stats["sweep_time"]))  # rad/s.
	var da := minf(rate * delta, TAU - _swept)  # Angle swept this tick (rad).
	var beams := _struck.size()  # Beams of this sweep.
	_sparks_left = DeathRayData.SPARKS_PER_TICK
	for k in beams:
		_sweep_beam(k, _angle + TAU * float(k) / float(beams), da, stats)
	_angle += da
	_swept += da
	if _swept >= TAU - 0.0001:
		_sweeping = false
		_timer = maxf(DeathRayData.MIN_GAP, float(stats["cooldown"]) - float(stats["sweep_time"]))


## Beam `k` sweeps from angle `a0` by `da` rad: strikes every foe in that sector.
func _sweep_beam(k: int, a0: float, da: float, stats: Dictionary) -> void:
	var p := game.player.position  # The beam's origin.
	var length := float(stats["beam_length"])  # px.
	var half_w := float(stats["beam_width"]) * 0.5  # px.
	var dmg := float(stats["damage"])
	var src := "event_horizon" if stats.has("chain") else "death_ray"  # Stats tag.
	var struck: Dictionary = _struck[k]
	game.enemy_grid.query(p, length + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var hits: Array[Enemy] = []  # Foes crossed this tick (struck after the scan).
	for e: Enemy in _cand:
		if not e.active or int(struck.get(e, -1)) == e.generation:
			continue
		var rel := e.position - p
		var d := rel.length()
		if d > length + e.radius:
			continue
		var tol := (half_w + e.radius) / maxf(d, DeathRayData.MIN_HIT_DIST)  # Angular half-width of its body (rad).
		var off := wrapf(rel.angle() - a0, -PI, PI)  # Its angle past the beam's start.
		if off >= -tol and off <= da + tol:
			hits.append(e)
	for e in hits:
		if not e.active:
			continue  # Killed by an earlier strike's kill hook.
		struck[e] = e.generation
		var at := e.position  # Strike point (before a kill pools it).
		game.combat.damage_enemy(e, dmg, src)
		game.stat_add("ray_hits", 1.0)
		if not e.active:
			game.stat_add("ray_kills", 1.0)
			if _sparks_left > 0:
				_sparks_left -= 1
				_spark_from(at, stats)


## A beam kill at `at`: lightning to the nearest foes (Death Ray), or a wild
## chain through up to `chain` foes (Event Horizon).
func _spark_from(at: Vector2, stats: Dictionary) -> void:
	var dmg := float(stats["damage"]) * float(stats["spark"])  # First spark's damage.
	var reach := float(stats["spark_range"])  # px.
	_chain.clear()
	_jags += 1
	if stats.has("chain"):
		var from := at  # The last strike point.
		var keep := 1.0 - float(stats["chain_falloff"])  # Damage kept per jump.
		for _j in int(stats["chain"]):
			var nxt := _nearest(from, reach)
			if nxt == null:
				break
			_chain.append(nxt)
			var to := nxt.position
			_add_arc(from, to, _jags * 17 + _chain.size(), true)
			game.combat.damage_enemy(nxt, dmg, "ray_spark")
			if not nxt.active:
				game.stat_add("ray_spark_kills", 1.0)
			from = to
			dmg *= keep
		game.stat_add("ray_chain_jumps", float(_chain.size()))
	else:
		var extra := int(game.character.innate_value("ray_extra_sparks"))  # The Lightning Abbess's innate (0 for every other character).
		var n := 1 + extra  # Sparks from this kill.
		for s in n:
			var nxt := _nearest(at, reach)
			if nxt == null:
				break
			_chain.append(nxt)
			_add_arc(at, nxt.position, _jags * 17 + s, false)
			game.combat.damage_enemy(nxt, dmg, "ray_spark")
			if not nxt.active:
				game.stat_add("ray_spark_kills", 1.0)
			if s >= 1:
				game.stat_add("abbess_extra_sparks", 1.0)
	if not _chain.is_empty():
		game.stat_add("ray_sparks", float(_chain.size()))
		Sfx.play("bolt_cast", at, DeathRayData.SPARK_PITCH)
	_chain.clear()


## The nearest live foe within `reach` px of `from` not struck by this spark yet.
func _nearest(from: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(from, reach + ProjectileManager.MAX_BODY_RADIUS, _near)
	var best: Enemy = null  # Nearest so far.
	var best_d := INF
	for e: Enemy in _near:
		if not e.active or e.hp <= 0.0 or _chain.has(e):
			continue
		var d := from.distance_to(e.position) - e.radius
		if d <= reach and d < best_d and d > 0.5:
			best_d = d
			best = e
	return best


## Adds a visible lightning arc (the oldest is dropped beyond the cap).
func _add_arc(a: Vector2, b: Vector2, jag: int, wild: bool) -> void:
	var arc: Arc = null  # Record to fill.
	if _arcs.size() >= DeathRayData.ARC_MAX:
		arc = _arcs[0]
		_arcs.remove_at(0)
	elif not _arc_pool.is_empty():
		arc = _arc_pool.pop_back()
	else:
		arc = Arc.new()
	arc.a = a
	arc.b = b
	arc.time_left = DeathRayData.ARC_TIME
	arc.jag_seed = jag
	arc.wild = wild
	_arcs.append(arc)


## Autotest counters (WastesReport's Act III spell line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "sweeps=%d hits=%d kills=%d sparks=%d spark_kills=%d chain_jumps=%d abbess_extra_sparks=%d" % [int(st.get("ray_sweeps", 0.0)),
		int(st.get("ray_hits", 0.0)), int(st.get("ray_kills", 0.0)), int(st.get("ray_sparks", 0.0)), int(st.get("ray_spark_kills", 0.0)),
		int(st.get("ray_chain_jumps", 0.0)), int(st.get("abbess_extra_sparks", 0.0))]


## The beams (violet soul lasers with a fading afterglow behind them) and the
## lightning. Visual only.
func _draw() -> void:
	if _sweeping and not _stats.is_empty():
		var p := game.player.position  # The beam's origin.
		var length := float(_stats["beam_length"])
		var w := float(_stats["beam_width"])
		var beams := _struck.size()
		for k in beams:
			var a := _angle + TAU * float(k) / float(beams)  # This beam's angle.
			for t in 4:
				var ta := a - DeathRayData.TRAIL_ANGLE * float(t + 1) / 4.0  # Afterglow angle.
				draw_line(p, p + Vector2.from_angle(ta) * length, Color(DeathRayData.GLOW, 0.16 - 0.035 * float(t)), w * 0.8)
			var tip := p + Vector2.from_angle(a) * length
			draw_line(p, tip, Color(DeathRayData.GLOW, 0.35), w + 4.0)
			draw_line(p, tip, Color(DeathRayData.GLOW, 0.85), w)
			draw_line(p, tip, DeathRayData.CORE, maxf(1.0, w * 0.35))
			draw_circle(tip, w * 0.6, Color(DeathRayData.CORE, 0.7))
	for arc in _arcs:
		var life := arc.time_left / DeathRayData.ARC_TIME  # 1 -> 0 as it fades.
		GraveSpellGlyphs.draw_lightning(self, arc.a, arc.b, arc.jag_seed, life, arc.wild)
