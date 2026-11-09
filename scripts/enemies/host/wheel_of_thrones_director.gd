## WheelOfThronesDirector — the stage systems of THE WHEEL OF THRONES (temporary
## Act XIII stage 38, final stage 29; GDD §15.0 "The Wheel of Thrones (Act XIII
## phase 2)"; owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section X,
## "Stage 29: The Wheel of Thrones"), owned and stepped by EnemyDirector on a
## stage whose STAGE has a "wheel_of_thrones" config (WheelOfThronesStage.SPHERES;
## `game.enemies.wheel_of_thrones`, null elsewhere). The zones' floors and
## obstacles are MarchDirector's; Judgment, Hallowed Light, Grace and the Last
## Trumpet the shared HostRules'. Here:
##   * THE TURNING SPHERES (the stage mechanic, "crystal rings sweep slowly
##     across the map as moving walls; the ring must flow through their
##     gaps"): each zone has its sphere numbers (SPHERES "zones", by start
##     time). Every `every` s (at most `max_live` at once) a RING of crystal
##     comes in: a circle `radius` px round a centre that starts `from` px
##     from a standing necromancer at a seeded angle (the gameplay RNG) and
##     drifts straight across past him (a seeded miss of up to `miss` px) at
##     `speed` px/s for 2 x `from` px, turning `spin` rad/s. The ring is
##     `segments` crystal arcs, each filling `fill` of its share of the circle
##     (the rest are the GAPS), `thickness` px thick.
##     THE MOVING WALLS go through the arena's push-out (Arena.resolve_all()
##     ends with contain_all(), the Citadel's pattern): every necromancer,
##     walking summon and enemy (not a boss, not a phasing body) that WALKS
##     INTO a crystal arc has that step undone (at most its overlap) and
##     turned into a slide along the arc toward the nearer gap, so nobody
##     walks through crystal and the ring flows through the gaps. The ring's
##     own drift never shoves a body: it passes over one that stands still or
##     walks away. Fliers (a swooping Gargoyle, a hovering Grave Drone) pass
##     over, as over every obstacle. The rings cast no shade (the Light
##     passes through crystal).
##   * THE DOMINION OF THE SPHERES ("spheres_dominion" event): the stage
##     miniboss, spawned on the spawn ring with an escort and tracked
##     (objective, kill time); his kit registers the HUD bar and pays his XP.
##   * THE WHEEL BREAKS (the stage's achievement): when the stage boss (the
##     Throne) falls on the Wheel of Thrones and BossThrone.wheel_breaks() (the
##     killing blow on the open Core, at least ThroneData.WHEEL_BREAKS_SHARE of
##     its health lost while the Core was open), the run stat
##     WHEEL_BREAKS_STAT is set (MetaProgress counts the runs, lifetime
##     wheel_breaks_runs, MetaData "the_wheel_breaks"; it unlocks Smoked Glass).
## Deterministic: only the seeded global RNG (the rings' angles and misses,
## where the Dominion comes in). Stats: wheel_rings, wheel_pushes_player,
## wheel_pushes_summons, wheel_pushes_enemies, wheel_zones,
## wheel_dominion_spawned, wheel_dominion_killed, WHEEL_BREAKS_STAT.
class_name WheelOfThronesDirector
extends Node2D

## Run stat set when The Wheel Breaks is earned (MetaProgress reads it).
const WHEEL_BREAKS_STAT: String = "wheel_of_thrones_wheel_breaks"
## Sprite key of a crystal piece drawn along the rings (the stage's obstacle
## art, obstacles/host_crystal_m; rects without it).
const CRYSTAL_KEY: String = "obstacles/host_crystal_m"
## px of crystal one drawn piece covers along a ring (visual only).
const PIECE: float = 34.0  # TUNING (not in GDD) visual only

## Owning run.
var game: Game
## The stage's config (WheelOfThronesStage.SPHERES).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the zone whose sphere numbers run (-1 before the first).
var zone_index: int = -1
## Live rings: {c (Vector2, centre), v (Vector2, px/s), a (rad, the turn),
## spin (rad/s), r (px), half (px, half the thickness), seg (int), fill
## (0..1), left (px still to drift)}.
var rings: Array[Dictionary] = []
## Rings that came in this run.
var ring_count: int = 0
## True once the stage boss fell this run.
var boss_down: bool = false
## True once The Wheel Breaks was earned this run.
var wheel_breaks: bool = false
## "m:ss" the Dominion of the Spheres fell ("" while alive / never spawned).
var dominion_time: String = ""
## Game time (s) of the next ring.
var _next_ring: float = INF
## True once the boss signal is connected.
var _hooked: bool = false
## The Dominion of the Spheres once spawned (null before / after; generation-checked).
var _dominion: Enemy = null
## Generation of `_dominion` when he spawned.
var _dominion_gen: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## True while the last redraw showed a ring (one more redraw clears it).
var _drawn_any: bool = false


func _ready() -> void:
	z_index = -5  # Over the obstacles (-6), under the bodies.
	z_as_relative = false
	_draws = DisplayServer.get_name() != "headless"
	game.arena.wheel = self  # The moving walls: Arena.resolve_all() ends with contain_all().


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var now := game.elapsed
	if not _hooked:
		_hooked = true
		game.enemies.boss_defeated.connect(_on_boss_defeated)
	var zones: Array = config.get("zones", [])
	while zone_index + 1 < zones.size() and now >= float((zones[zone_index + 1] as Dictionary)["start"]):
		zone_index += 1
		game.stat_add("wheel_zones", 1.0)
		_next_ring = minf(_next_ring, now + float((zones[zone_index] as Dictionary)["first"]))
		_log("zone_%d" % (zone_index + 1))
	if zone_index >= 0:
		var zc: Dictionary = zones[zone_index]
		if now >= _next_ring:
			_next_ring = now + float(zc["every"])
			if rings.size() < int(zc["max_live"]):
				_add_ring(zc)
	var i := rings.size() - 1
	while i >= 0:
		var rg: Dictionary = rings[i]
		var mv: Vector2 = (rg["v"] as Vector2) * delta
		rg["c"] = (rg["c"] as Vector2) + mv
		rg["a"] = wrapf(float(rg["a"]) + float(rg["spin"]) * delta, 0.0, TAU)
		rg["left"] = float(rg["left"]) - mv.length()
		if float(rg["left"]) <= 0.0:
			rings.remove_at(i)
		i -= 1
	if _dominion != null and not (_dominion.active and _dominion.generation == _dominion_gen):
		_dominion = null
		game.stat_add("wheel_dominion_killed", 1.0)
		dominion_time = _clock()
		_log("dominion_killed")
	if _draws and (not rings.is_empty() or _drawn_any):
		_drawn_any = not rings.is_empty()
		queue_redraw()


# =====================================================================================
# The turning spheres
# =====================================================================================

## A ring comes in from `from` px off a standing necromancer and drifts across.
func _add_ring(zc: Dictionary) -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var dir := Vector2.from_angle(randf() * TAU)  # Its drift.
	var miss := randf_range(-float(zc["miss"]), float(zc["miss"]))  # px it passes beside him.
	var start := float(zc["from"])  # px off him it comes in.
	rings.append({
		"c": pl.position - dir * start + dir.orthogonal() * miss,
		"v": dir * float(zc["speed"]),
		"a": randf() * TAU,
		"spin": float(zc["spin"]) * (1.0 if randf() < 0.5 else -1.0),
		"r": float(zc["radius"]),
		"half": float(zc["thickness"]) * 0.5,
		"seg": maxi(1, int(zc["segments"])),
		"fill": clampf(float(zc["fill"]), 0.05, 0.95),
		"left": start * 2.0,
	})
	ring_count += 1
	game.stat_add("wheel_rings", 1.0)
	game.host_rules().play_sound("sphere_turn", pl.position, 2.0)


## Where a body of radius `br` at `p` touches a crystal arc of ring `rg`: the
## local angle inside its segment (rad, 0 = the arc's start), or -1 when it
## touches none (off the ring's band, or in a gap).
static func _touch(rg: Dictionary, p: Vector2, br: float) -> float:
	var rel := p - (rg["c"] as Vector2)
	var d := rel.length()
	if absf(d - float(rg["r"])) >= float(rg["half"]) + br or d < 1.0:
		return -1.0
	var span := TAU / float(int(rg["seg"]))  # One segment's share of the circle (rad).
	var arc := span * float(rg["fill"])  # Its crystal (rad).
	var local := fposmod(rel.angle() - float(rg["a"]), span)
	var tol := br / d  # The body's angular half-width (rad).
	if local <= arc + tol or local >= span - tol:
		return minf(local, arc) if local < span - tol else 0.0
	return -1.0


## THE MOVING WALLS (Arena.resolve_all(), after the obstacles): every body
## walking into a crystal arc is held on its side and slides toward the
## nearer gap (see the header and _push()).
func contain_all(delta: float) -> void:
	if rings.is_empty():
		return
	for rg: Dictionary in rings:
		for pl in game.all_players:  # (Co-op: each necromancer.)
			if pl.dead:
				continue
			var q := _push(rg, pl.position, pl.radius, pl.velocity, delta)
			if q != pl.position:
				pl.position = q
				game.stat_add("wheel_pushes_player", 1.0)
		for h in game.all_hordes:
			for u in h.units:
				if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
					continue
				var qu := _push(rg, u.position, u.radius, u.velocity, delta)
				if qu != u.position:
					u.position = qu
					game.stat_add("wheel_pushes_summons", 1.0)
		for e in game.enemies.active:
			if not e.active or e.is_boss or e.phases_obstacles:
				continue
			var qe := _push(rg, e.position, e.radius, e.velocity, delta)
			if qe != e.position:
				e.position = qe
				game.stat_add("wheel_pushes_enemies", 1.0)


## A body of radius `br` at `p` moving at `vel` against ring `rg`: its place
## after the push (`p` when it touches no crystal or does not walk into it).
## Only the body's OWN motion toward the crystal's middle is undone (at most
## the overlap) and turned into a slide toward the nearer gap: the drifting
## ring never shoves a body along, it passes over one that stands or walks
## away (a first pass pushed every touching body out to its side, so a ring
## crossing the Bone Ring carried half the army into the Host).
func _push(rg: Dictionary, p: Vector2, br: float, vel: Vector2, delta: float) -> Vector2:
	var local := _touch(rg, p, br)
	if local < 0.0:
		return p
	var rel := p - (rg["c"] as Vector2)
	var d := rel.length()
	var n := rel / d  # Radial unit vector.
	var off := d - float(rg["r"])  # Signed px from the crystal's middle line (+ outside).
	var side := 1.0 if off >= 0.0 else -1.0
	var into := -vel.dot(n) * side  # px/s the body walks toward the middle line.
	if into <= 0.0:
		return p
	var pen := float(rg["half"]) + br - absf(off)  # px of overlap.
	var out := p + n * side * minf(pen, into * delta)
	var arc := TAU / float(int(rg["seg"])) * float(rg["fill"])
	var t := n.orthogonal() * (-1.0 if local < arc * 0.5 else 1.0)  # Toward the nearer gap (the arc's near end).
	return out + t * into * delta


# =====================================================================================
# The Dominion of the Spheres
# =====================================================================================

## Runs a Wheel of Thrones timeline event (EnemyDirector forwards the
## "spheres_dominion" type; keys in WheelOfThronesStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "spheres_dominion":
		return
	var a := randf() * TAU
	var e := game.enemies.spawn_at(String(ev.get("kind", WheelOfThronesEnemyData.DOMINION_OF_THE_SPHERES)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
	if e == null:
		return
	_dominion = e
	_dominion_gen = e.generation
	game.stat_add("wheel_dominion_spawned", 1.0)
	game.shake(6.0)
	Sfx.play("boss_impact", e.position, 0.5)
	var side := Vector2.from_angle(a).orthogonal()
	var escort: Array = ev.get("escort", [])
	var k := 0
	for grp: Dictionary in escort:
		for j in int(grp.get("count", 0)):
			var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (40.0 + 18.0 * float(k / 6))
			game.enemies.spawn_at(String(grp["kind"]), at, false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("spheres_dominion")


## The HUD objective while the Dominion of the Spheres stands ("" otherwise).
func objective_override() -> String:
	if _dominion != null and _dominion.active and _dominion.generation == _dominion_gen:
		return String(config.get("dominion_objective", ""))
	return ""


# =====================================================================================
# The Wheel Breaks
# =====================================================================================

## The stage boss fell (EnemyDirector.boss_defeated): The Wheel Breaks when it
## is the Throne, on the Wheel of Thrones, broken by its Core.
func _on_boss_defeated() -> void:
	if boss_down:
		return
	boss_down = true
	_log("boss_down")
	var th := game.enemies.boss as BossThrone
	if th == null or String(game.stage_def.get("id", "")) != WheelOfThronesStage.ID:
		return
	if not th.wheel_breaks():
		_log("core_share_%d" % roundi(100.0 * th.core_share()))
		return
	wheel_breaks = true
	game.stats[WHEEL_BREAKS_STAT] = 1.0
	game.enemies.show_banner(String(config.get("wheel_breaks_banner", "THE WHEEL BREAKS")))
	_log("wheel_breaks")


# =====================================================================================
# Drawing, report
# =====================================================================================

## Every ring's crystal arcs: the crystal art turned along the ring, or
## cerulean rects without it. Visual only: textures and rects.
func _draw() -> void:
	var tex := EnvironmentArt.texture(CRYSTAL_KEY)  # A crystal piece, or null.
	if tex != null:
		SpriteBank.apply_sharp(self)
	for rg: Dictionary in rings:
		var c: Vector2 = rg["c"]
		var r := float(rg["r"])
		var seg := int(rg["seg"])
		var span := TAU / float(seg)
		var arc := span * float(rg["fill"])
		var pieces := maxi(1, ceili(arc * r / PIECE))
		for s in seg:
			var a0 := float(rg["a"]) + span * float(s)
			for k in pieces:
				var th := a0 + arc * (float(k) + 0.5) / float(pieces)
				draw_set_transform(c + Vector2.from_angle(th) * r, th + PI * 0.5, Vector2.ONE)
				if tex != null:
					var sz := Vector2(float(tex.get_width()), float(tex.get_height()))
					draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
				else:
					var h := float(rg["half"])
					draw_rect(Rect2(Vector2(-PIECE * 0.5, -h), Vector2(PIECE - 2.0, h * 2.0)), Color(Palette.HOST_CERULEAN, 0.85))
					draw_rect(Rect2(Vector2(-PIECE * 0.5 + 2.0, -1.0), Vector2(PIECE - 6.0, 2.0)), Color(Palette.HOST_STARLIGHT, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "zones %d | turning spheres: rings %d, pushes player %d / summons %d / enemies %d | dominion of the spheres spawned %d, killed %d%s | the wheel breaks %s | events: %s" % [
		zone_index + 1, ring_count, int(st.get("wheel_pushes_player", 0.0)), int(st.get("wheel_pushes_summons", 0.0)),
		int(st.get("wheel_pushes_enemies", 0.0)), int(st.get("wheel_dominion_spawned", 0.0)), int(st.get("wheel_dominion_killed", 0.0)),
		(" at " + dominion_time) if dominion_time != "" else "",
		"EARNED" if wheel_breaks else ("lost" if boss_down else "open"), ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
