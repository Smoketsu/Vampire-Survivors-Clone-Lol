## SinkingDirector — THE SINKING of Ul-Thalos, the Risen Spire (Stage 6; GDD
## §15.0 "Ul-Thalos, the Risen Spire"): the god's city slides back under the
## sea as the clock runs, so the island shrinks and the fight closes in on the
## spire. Owned and stepped by EnemyDirector on a stage whose STAGE has a
## "sinking" config (SpireStage.SINKING; null everywhere else, so no other
## stage runs any of this).
##   * The island is a circle of `radius` px around SINKING.center (the spire,
##     the world origin, where the run starts). Every zone of the stage's
##     `march` config names its shoreline (ZONES[i].shore).
##   * The new shoreline is TELEGRAPHED SINKING.telegraph_lead s before a zone
##     starts (a pulsing biolume line and a banner), then the sea RISES to it
##     over SINKING.flood_time s (smooth in-out).
##   * At 0:00 the Waking floods the island once more, to SINKING.waking_radius.
##   * Deep water cannot be walked: it works like the edge of the world. ONE
##     rule, contain_all(), called by Arena.resolve_all() after the obstacles,
##     keeps the necromancer, every summon (a flying Gargoyle lands on a free
##     point, which is clamped too) and every enemy inside the shore, and the
##     drops (XP crystals, power-ups, chests) are moved out of the sea every
##     contain_interval ticks. Arena.free_point() clamps through clamp_point(),
##     so nothing is ever placed in the sea (spawns, recalls, formation posts,
##     landings), and Arena._generate() asks obstacle_ok() so no obstacle
##     stands in the sea or on the shore being flooded to.
##   * The cultists climb out of the sea: an enemy spawned in deep water
##     (the spawn ring lies out at sea once the island is small) appears at the
##     shore instead, at least SINKING.spawn_gap px from the necromancer
##     (spawn_point(), EnemyDirector), with a splash.
##   * Exempt from the shore: Vhal'Neth herself (BossVhalneth: her face lies
##     in the sea beside the island).
## Drawing: the sea over the floor (under the obstacles and bodies; the water
## tile tiles/spire_water when it exists, else flat colours), the foam on the
## shoreline, the telegraphed shoreline and the band about to flood, and the
## splashes of cultists climbing out. Purely visual; nothing drawn changes
## gameplay. Determinism: game time and positions only, no RNG.
## Stats: sinking_floods, sinking_pushes_player / _summons / _enemies (bodies
## the rising sea moved), sinking_drops_moved, sinking_shore_spawns.
class_name SinkingDirector
extends Node2D

## Segments of the drawn sea ring and the foam / telegraph circles.
const SEGMENTS: int = 96
## Width (px) of the foam band on the shoreline (drawing).
const FOAM_WIDTH: float = 5.0
## Most splashes remembered at once (ring buffer; drawing).
const SPLASH_MAX: int = 24
## Seconds a splash is drawn.
const SPLASH_TIME: float = 0.7
## Size (px) of one water tile when there is no tile art (uv scale).
const TILE_PX: float = 128.0
## Drift (px/s) of the water tile (drawing).
const WATER_DRIFT: Vector2 = Vector2(5.0, 2.0)
## Kind of Vhal'Neth's arms: they rise from the surf at the shore and are
## kept on it like any body (only her face is exempt).
const ARM_KIND: String = "vhalneth_arm"

## Owning run.
var game: Game
## The stage's sinking config (SpireStage.SINKING).
var config: Dictionary = {}
## The island's centre (world px).
var center: Vector2 = Vector2.ZERO
## Current shoreline radius (px).
var radius: float = 1000.0
## Shoreline the sea is rising to (px; = radius when calm).
var target: float = 1000.0
## Radius the current flood started from (px).
var _from: float = 1000.0
## Seconds since the current flood started (-1 = no flood running).
var _flood_t: float = -1.0
## Seconds the current flood takes.
var _flood_time: float = 20.0
## True while a new shoreline is telegraphed but the sea has not started rising.
var pending: bool = false
## Game time (s) at which the telegraph began (drawing: its pulse).
var _pending_since: float = 0.0
## The stage's zones (its march config), each with a `shore` radius.
var _zones: Array = []
## Index of the last zone whose shoreline was telegraphed.
var _telegraphed: int = 0
## Index of the last zone whose flood started.
var _flooded: int = 0
## True once the Waking's flood was started (0:00).
var _waking: bool = false
## Physics ticks since the run started (drop containment pacing).
var _frame: int = 0
## Splashes: [position, game time] (ring buffer, drawing only).
var _splashes: Array = []
## Next slot of the splash ring buffer.
var _splash_next: int = 0
## Game time of the last splash (rate limit).
var _last_splash: float = -1.0
## Log of sinking events, "m:ss name" (autotest summary).
var fired: Array[String] = []


func _ready() -> void:
	z_index = -7  # Over the floor (-10), under the obstacles (-6) and every body.
	center = config.get("center", Vector2.ZERO)
	_zones = (game.stage_def.get("march", {}) as Dictionary).get("zones", [])
	radius = float((_zones[0] as Dictionary).get("shore", 1600.0)) if not _zones.is_empty() else 1600.0
	target = radius
	_from = radius
	game.arena.shore = self  # The one shore rule (Arena push-out, free_point, obstacle layout).


# =====================================================================================
# The clock
# =====================================================================================

## Per-tick update (EnemyDirector): telegraphs, floods, the Waking, drops.
func step(delta: float) -> void:
	_frame += 1
	var t := game.elapsed
	var lead := float(config["telegraph_lead"])
	while _telegraphed + 1 < _zones.size() and t >= float(_zones[_telegraphed + 1]["start"]) - lead:
		_telegraphed += 1
		_telegraph(float(_zones[_telegraphed].get("shore", radius)))
	while _flooded + 1 < _zones.size() and t >= float(_zones[_flooded + 1]["start"]):
		_flooded += 1
		_start_flood(float(_zones[_flooded].get("shore", radius)), float(config["flood_time"]))
	if not _waking and game.enemies.reckoning_wave > 0:
		_waking = true
		_telegraph(minf(target, float(config["waking_radius"])))
		_start_flood(minf(target, float(config["waking_radius"])), float(config["waking_flood_time"]))
		if not _zones.is_empty():
			# Rebuild the terrain for the last shoreline (no zone change follows to do it).
			game.arena.set_layout(_zones[_zones.size() - 1]["arena"], game.player.position, float((game.stage_def["march"] as Dictionary).get("transition_clear", 260.0)))
		_log("waking_flood")
	if _flood_t >= 0.0:
		_flood_t += delta
		var k := clampf(_flood_t / maxf(0.01, _flood_time), 0.0, 1.0)  # Flood progress.
		radius = lerpf(_from, target, k * k * (3.0 - 2.0 * k))  # Smooth in-out.
		game.stat_add("sinking_flood_seconds", delta)
		if k >= 1.0:
			_flood_t = -1.0
			radius = target
			_log("shore_%d" % int(radius))
	if _frame % int(config["contain_interval"]) == 0:
		_contain_drops()
	queue_redraw()


## Shows the coming shoreline `r` (the sea has not risen yet).
func _telegraph(r: float) -> void:
	if r >= radius - 0.5:
		return
	target = r
	pending = true
	_pending_since = game.elapsed
	game.enemies.show_banner("The sea is rising! Get inside the glowing shoreline.")
	game.effects.ring(game.player.position, 140.0, Color(config["telegraph"]), 0.6)
	Sfx.play("boss_telegraph", game.player.position)
	_log("telegraph_%d" % int(r))


## Starts the sea rising from today's shore to `r` over `seconds`.
func _start_flood(r: float, seconds: float) -> void:
	if r >= radius - 0.5:
		pending = false
		return
	_from = radius
	target = r
	_flood_t = 0.0
	_flood_time = seconds
	pending = false
	game.stat_add("sinking_floods", 1.0)
	game.shake(3.0)
	_log("flood_%d" % int(r))


## Records a sinking event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])


# =====================================================================================
# The shore rule (Arena, EnemyDirector)
# =====================================================================================

## The shoreline the island is (or is being) flooded to: no obstacle stands
## beyond it (obstacle_ok()). Equals `radius` when the sea is calm.
func target_radius() -> float:
	return minf(radius, target)


## The island's last shoreline before the Waking (the Spire's): structures
## placed there never sink (SpireDirector's dream pillars).
func final_radius() -> float:
	if _zones.is_empty():
		return radius
	return float((_zones[_zones.size() - 1] as Dictionary).get("shore", radius))


## True when `p` lies in the sea (beyond the current shoreline).
func is_water(p: Vector2) -> bool:
	return p.distance_squared_to(center) > radius * radius


## `p` moved inside the shore for a body of radius `r` (unchanged when it
## already is): the nearest point on the island.
func clamp_point(p: Vector2, r: float) -> Vector2:
	var off := p - center
	var lim := maxf(0.0, radius - r)
	if off.length_squared() <= lim * lim:
		return p
	var d := off.length()
	return center + (off / d if d > 0.001 else Vector2.RIGHT) * lim


## True when an obstacle centred on `c` may stand: inside the shoreline being
## flooded to, obstacle_margin px clear of it (Arena._generate()).
func obstacle_ok(c: Vector2) -> bool:
	var lim := target_radius() - float(config["obstacle_margin"])
	return c.distance_squared_to(center) <= lim * lim


## Where a cultist spawned at `p` appears: `p` itself on the island, else a
## point spawn_inset px inside the shore toward `p`, walked around the coast
## (away from the necromancer) until it is spawn_gap px from him. A splash
## marks it. EnemyDirector calls it for every spawn and recycle.
func spawn_point(p: Vector2) -> Vector2:
	var inset := float(config["spawn_inset"])
	var lim := radius - inset
	if p.distance_squared_to(center) <= lim * lim:
		return p
	var pl := game.player.position
	var gap := minf(float(config["spawn_gap"]), lim * 1.5)  # A tiny island cannot keep the full gap.
	var a := (p - center).angle()
	var away := (pl - center).angle() + PI  # The far side of the island from him.
	var q := center + Vector2.from_angle(a) * lim
	for _i in 14:
		if q.distance_to(pl) >= gap:
			break
		a = lerp_angle(a, away, 0.25)
		q = center + Vector2.from_angle(a) * lim
	game.stat_add("sinking_shore_spawns", 1.0)
	_splash(q)
	return q


## Remembers a splash at `p` (drawing only; rate limited).
func _splash(p: Vector2) -> void:
	if game.elapsed - _last_splash < float(config["emerge_interval"]):
		return
	_last_splash = game.elapsed
	if _splashes.size() < SPLASH_MAX:
		_splashes.append([p, game.elapsed])
	else:
		_splashes[_splash_next] = [p, game.elapsed]
		_splash_next = (_splash_next + 1) % SPLASH_MAX


## THE shore rule (Arena.resolve_all(), after the obstacles): the necromancer,
## every walking summon and every enemy but Vhal'Neth's face are kept inside
## the shore.
func contain_all() -> void:
	var p := game.player
	var q := clamp_point(p.position, p.radius)
	if q != p.position:
		p.position = q
		game.stat_add("sinking_pushes_player", 1.0)
	var n := 0  # Summons the sea moved this tick.
	for u in game.horde.units:
		if not u.active or u.airborne:
			continue  # A flying Gargoyle passes over the sea (it lands on a free point).
		var uq := clamp_point(u.position, u.radius)
		if uq != u.position:
			u.position = uq
			n += 1
	if n > 0:
		game.stat_add("sinking_pushes_summons", float(n))
	var m := 0  # Enemies the sea moved this tick.
	for e in game.enemies.active:
		if not e.active or e is BossVhalneth:
			continue  # Her face lies in the sea beside the island.
		var eq := clamp_point(e.position, e.radius)
		if eq != e.position:
			e.position = eq
			m += 1
	if m > 0:
		game.stat_add("sinking_pushes_enemies", float(m))


## Moves every drop the sea reached back onto the shore.
func _contain_drops() -> void:
	var moved := 0  # Drops moved this pass.
	for c in game.pickups.active:
		if c.active and is_water(c.position):
			c.position = clamp_point(c.position, 8.0)
			moved += 1
	for d in game.powerups.active:
		if d.active and is_water(d.position):
			d.position = clamp_point(d.position, 12.0)
			moved += 1
	for ch in game.chests.active:
		if ch.active and is_water(ch.position):
			ch.position = clamp_point(ch.position, 16.0)
			moved += 1
	if moved > 0:
		game.stat_add("sinking_drops_moved", float(moved))


## HUD / objective hint while a shoreline is telegraphed or flooding ("" = calm).
func objective_override() -> String:
	if pending:
		return "The sea will rise: get inside the glowing shoreline"
	if _flood_t >= 0.0:
		return "The island sinks: stay on the stone"
	return ""


## Autopilot hint: a push back toward the island's centre when `p` stands in
## the band about to flood (or close to the shore), zero otherwise.
func danger_push(p: Vector2) -> Vector2:
	var d := p.distance_to(center)
	var safe := target_radius() - 60.0
	if d <= safe or d < 1.0:
		return Vector2.ZERO
	return (center - p) / d * clampf((d - safe) / 120.0, 0.2, 1.0)


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "floods %d (%.0f s flooding), shore now %d px | pushed in: player %d, summons %d, enemies %d | drops moved %d | shore spawns %d | events: %s" % [
		int(st.get("sinking_floods", 0.0)), float(st.get("sinking_flood_seconds", 0.0)), int(radius),
		int(st.get("sinking_pushes_player", 0.0)), int(st.get("sinking_pushes_summons", 0.0)), int(st.get("sinking_pushes_enemies", 0.0)),
		int(st.get("sinking_drops_moved", 0.0)), int(st.get("sinking_shore_spawns", 0.0)), ", ".join(fired)]


# =====================================================================================
# Drawing (the sea)
# =====================================================================================

func _draw() -> void:
	if game == null or game.player == null:
		return
	var view := game.view_size().length() * 0.5 + 64.0  # Half the visible diagonal (px).
	var pd := game.player.position.distance_to(center)  # Necromancer's distance to the spire.
	if pd + view < minf(radius, target) - FOAM_WIDTH * 2.0:
		return  # The island fills the view: no sea to draw.
	var outer := pd + view + 200.0  # Far edge of the drawn sea.
	var now := game.elapsed
	_draw_sea(radius, outer, now)
	if target < radius - 0.5:
		_draw_flood_band(target, radius, now)
	_draw_foam(radius, now)
	if pending or (_flood_t >= 0.0 and target < radius - 0.5):
		_draw_telegraph(target, now)
	_draw_splashes(now)


## The sea from `inner` to `outer` px: the water tile (drifting) or flat colours.
func _draw_sea(inner: float, outer: float, now: float) -> void:
	var tex := EnvironmentArt.texture(EnvironmentArtData.TILE_PREFIX + "spire_water", true)  # Water tile art, or null.
	var water: Color = config["water"]
	var deep: Color = config["deep"]
	if tex != null:
		SpriteBank.apply_sharp(self)
	var tile := Vector2(float(tex.get_width()), float(tex.get_height())) if tex != null else Vector2.ONE * TILE_PX
	var drift := WATER_DRIFT * now  # Tile drift (px).
	var mid := inner + 90.0  # Where the shallows give way to the deep (flat colours only).
	for i in SEGMENTS:
		var a0 := TAU * float(i) / float(SEGMENTS)
		var a1 := TAU * float(i + 1) / float(SEGMENTS)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		if tex != null:
			var pts := PackedVector2Array([center + d0 * inner, center + d1 * inner, center + d1 * outer, center + d0 * outer])
			var uvs := PackedVector2Array()
			for q in pts:
				uvs.append((q + drift) / tile)
			draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)
		else:
			draw_colored_polygon(PackedVector2Array([center + d0 * inner, center + d1 * inner, center + d1 * mid, center + d0 * mid]), water)
			draw_colored_polygon(PackedVector2Array([center + d0 * mid, center + d1 * mid, center + d1 * outer, center + d0 * outer]), deep)
	if tex != null:
		# A darker deep beyond the shallows, over the tile.
		draw_arc(center, mid + (outer - mid) * 0.5, 0.0, TAU, SEGMENTS, Color(deep, 0.45), outer - mid)
	# Slow swell lines (concentric arcs drifting outward).
	for k in 3:
		var r := inner + 26.0 + fmod(now * 9.0 + float(k) * 40.0, 120.0)
		draw_arc(center, r, 0.0, TAU, SEGMENTS, Color(config["foam"], 0.10), 2.0)


## The band about to flood (`from_r` .. `to_r` px): wet, darkening stone.
func _draw_flood_band(from_r: float, to_r: float, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 3.0)
	var w := to_r - from_r
	draw_arc(center, from_r + w * 0.5, 0.0, TAU, SEGMENTS, Color(Color(config["water"]), 0.22 + 0.08 * pulse), w)


## Foam on the shoreline `r`.
func _draw_foam(r: float, now: float) -> void:
	var foam: Color = config["foam"]
	draw_arc(center, r + FOAM_WIDTH * 0.5, 0.0, TAU, SEGMENTS, Color(foam, 0.55), FOAM_WIDTH)
	var wob := 3.0 + 2.0 * sin(now * 1.7)
	draw_arc(center, r + FOAM_WIDTH + wob, 0.0, TAU, SEGMENTS, Color(foam, 0.22), 2.0)


## The telegraphed shoreline `r`: a pulsing biolume dashed ring.
func _draw_telegraph(r: float, now: float) -> void:
	var col: Color = config["telegraph"]
	var pulse := 0.55 + 0.45 * sin((now - _pending_since) * 6.0)
	var dashes := 120
	for i in dashes:
		if i % 2 == 1:
			continue
		var a0 := TAU * float(i) / float(dashes) + now * 0.05
		draw_arc(center, r, a0, a0 + TAU / float(dashes), 3, Color(col, 0.5 + 0.4 * pulse), 3.0)
	draw_arc(center, r - 6.0, 0.0, TAU, SEGMENTS, Color(col, 0.12 * pulse), 10.0)


## Splashes of cultists climbing out of the sea.
func _draw_splashes(now: float) -> void:
	var foam: Color = config["foam"]
	for s: Array in _splashes:
		var age := now - float(s[1])
		if age < 0.0 or age > SPLASH_TIME:
			continue
		var k := age / SPLASH_TIME
		draw_arc(s[0], 6.0 + 18.0 * k, 0.0, TAU, 16, Color(foam, 0.7 * (1.0 - k)), 2.0)
		draw_arc(s[0], 3.0 + 9.0 * k, 0.0, TAU, 12, Color(foam, 0.5 * (1.0 - k)), 1.5)
