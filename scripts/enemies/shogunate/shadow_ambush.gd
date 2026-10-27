## ShadowAmbush — FROM THE SHADOWS, the third of the Shogunate's shared rules
## (Act V; GDD §15.0 "From the Shadows"; owner-approved proposal: "Ninja squads
## do not walk in from the edge: they appear out of obstacle shadows near the
## necromancer, sometimes inside the Bone Ring, after a 1 s smoke puff. Lanterns
## and light show the puff earlier"), owned by Game.shogunate. The ONE path of
## every ambush, and the one exception to "enemies walk in from the edge": once
## they appear, ambushers advance like everyone else.
##   * Squads come from the timeline: an event of type "ambush" ({"time",
##     "type": "ambush", "banner", "groups": [{kind, count, elite}]},
##     start_event()) and a segment's "ambush" trickle ({"every": s, "kind",
##     "count", "elite"}: a squad every `every` s while that segment runs). Both
##     begin at DUSK (SunCourse.is_dusk_or_later()): an earlier squad waits.
##   * Where: with AMBUSH ring_chance the squad appears INSIDE the Bone Ring (a
##     point between ring_min px and the ring's radius from the necromancer);
##     otherwise at an obstacle's SHADOW near him: one of the obstacles whose
##     centre lies between min_dist and search px of him (seeded pick), the
##     spot on its side away from the light (the necromancer, or a nearer lit
##     lantern by night; at dusk the sinking sun's way added). A spot inside a
##     lit stone lantern's pool is refused (SunCourse.in_lit_pool()); without
##     an obstacle the squad appears in the open at that distance (up to
##     `probes` seeded points tried for one outside a lit pool). Every point goes through Arena.free_point() (never inside
##     an obstacle). Co-op: each squad picks a standing necromancer with the
##     seeded RNG.
##   * When: a smoke puff (drawn above the darkness) warns for AMBUSH puff s,
##     plus lit_bonus x light_at(spot) x Paper Lanterns (SunCourse
##     .lantern_mult()): a puff in light shows earlier. Then the squad appears
##     (EnemyDirector.spawn_at(), never past the hard cap) with its banner.
## Determinism: the seeded gameplay RNG only (Act V only). Stats: ambush_squads,
## ambush_units, ambush_in_ring, ambush_lit, ambush_warn_total, ambush_spawned,
## ambush_capped, ambush_waited.
class_name ShadowAmbush
extends Node2D

## One smoke puff waiting to become an ambusher.
class Puff:
	extends RefCounted
	## World px where it appears.
	var pos: Vector2 = Vector2.ZERO
	## Enemy kind it becomes.
	var kind: String = ""
	## True: it appears as an elite.
	var elite: bool = false
	## Game time (s) the puff began.
	var start: float = 0.0
	## Game time (s) the ambusher appears.
	var at: float = 0.0
	## Banner shown when it appears ("" = none; the first puff of a squad).
	var banner: String = ""

## Owning run.
var game: Game
## Squads waiting for dusk or room: {"groups": [...], "banner": String} each.
var queue: Array[Dictionary] = []
## Puffs now.
var puffs: Array[Puff] = []
## Game time (s) of the next trickle squad (INF until a segment asks for one).
var _trickle_at: float = INF
## The segment whose "ambush" trickle runs (its dictionary; {} = none).
var _trickle_seg: Dictionary = {}
## True if the last redraw showed puffs (one more redraw clears them).
var _drawn: bool = false


## Builds the ambush path for `p_game` (ShogunateRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "ShadowAmbush"
	z_index = 19  # Above the night's darkness: the puffs must read.
	z_as_relative = false


## An "ambush" timeline event `ev` (EnemyDirector._run_event()): its squad joins
## the queue (it waits for dusk).
func start_event(ev: Dictionary) -> void:
	queue.append({"groups": ev.get("groups", []), "banner": String(ev.get("banner", ""))})
	if not game.shogunate.sun.is_dusk_or_later():
		game.stat_add("ambush_waited", 1.0)


## Per-tick update (ShogunateRules): the segment's trickle, the queue, the puffs.
func step(_delta: float) -> void:
	var t := game.elapsed
	var dusk := game.shogunate.sun.is_dusk_or_later()  # Ambushes begin at dusk.
	_step_trickle(t, dusk)
	if dusk:
		var cap := int(ShogunateRulesData.AMBUSH["max_pending"])
		while not queue.is_empty() and puffs.size() < cap:
			var sq: Dictionary = queue.pop_front()
			_place_squad(sq["groups"], String(sq["banner"]))
	var i := puffs.size() - 1
	while i >= 0:
		var p := puffs[i]
		if t >= p.at:
			_appear(p)
			puffs.remove_at(i)
		i -= 1
	var busy := not puffs.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The current segment's "ambush" trickle: a squad every `every` s from dusk on.
func _step_trickle(t: float, dusk: bool) -> void:
	var seg: Dictionary = game.enemies.segments[game.enemies.segment_index]
	var tr: Dictionary = seg.get("ambush", {})  # This segment's trickle ({} = none).
	if not is_same(seg, _trickle_seg):
		_trickle_seg = seg
		_trickle_at = t + float(tr["every"]) if not tr.is_empty() else INF
	if tr.is_empty() or not dusk or t < _trickle_at:
		return
	_trickle_at = t + float(tr["every"])
	queue.append({"groups": [{"kind": String(tr["kind"]), "count": int(tr["count"]), "elite": bool(tr.get("elite", false))}], "banner": ""})


## The necromancer a squad aims at: solo, the player; co-op, one standing
## necromancer picked with the seeded RNG.
func _aim_player() -> Necromancer:
	if game.coop == null:
		return game.player
	var standing: Array[Necromancer] = []  # Necromancers still on their feet.
	for s in game.coop.slots:
		if not s.downed:
			standing.append(s.player)
	if standing.size() <= 1:
		return standing[0] if standing.size() == 1 else game.player
	return standing[randi() % standing.size()]


## Places one squad (`groups` of {kind, count, elite}): one spot (the ring or an
## obstacle's shadow), its members spread around it, each with its puff.
func _place_squad(groups: Array, banner: String) -> void:
	var a: Dictionary = ShogunateRulesData.AMBUSH
	var sun := game.shogunate.sun
	var pl := _aim_player()
	var members: Array[Dictionary] = []
	for g: Dictionary in groups:
		for _k in int(g["count"]):
			members.append({"kind": String(g["kind"]), "elite": bool(g.get("elite", false))})
	if members.is_empty():
		return
	var in_ring := randf() < float(a["ring_chance"])
	var spot := Vector2.INF
	if in_ring:
		var rr := maxf(float(a["ring_min"]) + 1.0, game.horde.ring_radius)  # The Bone Ring's radius (px).
		spot = pl.position + Vector2.from_angle(randf() * TAU) * randf_range(float(a["ring_min"]), rr)
	else:
		spot = _shadow_spot(pl)
	spot = game.arena.free_point(spot, 10.0)
	var light := sun.light_at(spot)  # Light at the spot (0..1).
	var warn := float(a["puff"]) + float(a["lit_bonus"]) * light * sun.lantern_mult(pl)  # Warning (s).
	var t := game.elapsed
	for k in members.size():
		var off := Vector2.ZERO if k == 0 else Vector2.from_angle(float(k) * 2.4) * float(a["spread"]) * sqrt(float(k))
		var p := Puff.new()
		p.pos = game.arena.free_point(spot + off, 10.0)
		p.kind = String(members[k]["kind"])
		p.elite = bool(members[k]["elite"])
		p.start = t
		p.at = t + warn
		p.banner = banner if k == 0 else ""
		puffs.append(p)
	game.stat_add("ambush_squads", 1.0)
	game.stat_add("ambush_units", float(members.size()))
	game.stat_add("ambush_warn_total", warn)
	if in_ring:
		game.stat_add("ambush_in_ring", float(members.size()))
	if light >= float(sun.cfg["pool_light"]):
		game.stat_add("ambush_lit", 1.0)  # Revealed in light (an earlier puff).
	game.shogunate.play_sound("smoke_puff", spot)


## An obstacle's shadow near necromancer `pl` (see the header), else a point in
## the open at that distance; never inside a lit lantern's pool when avoidable.
## The candidates are the obstacles of the arena cells around him whose centre
## lies between min_dist and search px (gameplay cells, filled by the
## simulation); one is picked with the seeded RNG.
func _shadow_spot(pl: Necromancer) -> Vector2:
	var a: Dictionary = ShogunateRulesData.AMBUSH
	var sun := game.shogunate.sun
	var lo := float(a["min_dist"])
	var hi := float(a["search"])
	var cell := ArenaData.CELL
	var span := ceili(hi / cell)  # Cells each side.
	var c := Vector2i(floori(pl.position.x / cell), floori(pl.position.y / cell))
	var spots: Array[Vector2] = []  # Shadow spots of the obstacles in reach.
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var key := c + Vector2i(dx, dy)
			var o := game.arena.obstacle_at(Vector2((float(key.x) + 0.5) * cell, (float(key.y) + 0.5) * cell))
			if o == null:
				continue
			var d := o.center.distance_to(pl.position)
			if d < lo or d > hi:
				continue
			var away := _away_from_light(o.center, pl)  # The obstacle's dark side.
			var ext := o.radius if o.is_circle else absf(away.x) * o.half.x + absf(away.y) * o.half.y  # Its reach that way (px).
			var spot := o.center + away * (ext + float(a["shadow_gap"]) + 10.0)
			if not sun.in_lit_pool(spot):
				spots.append(spot)
	if not spots.is_empty():
		game.stat_add("ambush_shadow_spots", 1.0)
		return spots[randi() % spots.size()]
	var fallback := Vector2.INF
	for _i in int(a["probes"]):
		var probe := pl.position + Vector2.from_angle(randf() * TAU) * randf_range(lo, hi)
		if not sun.in_lit_pool(probe):
			fallback = probe
			break
	if fallback == Vector2.INF:
		fallback = pl.position + Vector2.from_angle(randf() * TAU) * hi
	return fallback


## Unit vector from the light falling on `c` toward its shadow: away from
## necromancer `pl` (the nearest light: by night his own pool, at dusk the sun
## too, both blended toward him), or away from the nearest lit lantern when one
## is nearer.
func _away_from_light(c: Vector2, pl: Necromancer) -> Vector2:
	var sun := game.shogunate.sun
	var src := pl.position  # The light: the necromancer...
	var best := c.distance_to(src)
	for key: Vector2i in sun.lit:
		var l: Vector2 = sun.lit[key]
		var d := c.distance_to(l)
		if d < best:
			best = d
			src = l  # ... or a nearer lit lantern.
	var away := c - src
	if not sun.is_night():
		away = away.normalized() + (sun.cfg["sun_dir"] as Vector2)  # Dusk: the sun sinking in the west adds its way.
	return away.normalized() if away.length_squared() > 0.0001 else Vector2.RIGHT


## Puff `p` is over: the ambusher appears (never past the hard cap).
func _appear(p: Puff) -> void:
	if game.enemies.regular_alive() >= game.enemies.hard_cap():
		game.stat_add("ambush_capped", 1.0)
		return
	var e := game.enemies.spawn_at(p.kind, game.arena.free_point(p.pos, 10.0), p.elite)
	if e == null:
		return
	game.stat_add("ambush_spawned", 1.0)
	game.effects.pop(e.position, Palette.SHOGUN_INDIGO_LIGHT, e.radius * 1.6)
	if p.banner != "":
		game.enemies.show_banner(p.banner)


## Draws every smoke puff: a swelling indigo-grey cloud with a pale rim, more
## solid as the ambusher nears (texture discs, which batch). Visual only.
func _draw() -> void:
	var t := game.elapsed
	var r0 := float(ShogunateRulesData.AMBUSH["puff_radius"])  # Full puff radius (px).
	for p in puffs:
		var k := clampf((t - p.start) / maxf(p.at - p.start, 0.01), 0.0, 1.0)  # 0 puff begins .. 1 appears.
		var r := r0 * (0.45 + 0.55 * k)
		var wob := sin(t * 9.0 + p.pos.x * 0.05) * 1.5  # A little churn.
		SpriteBank.draw_disc(self, p.pos + Vector2(0.0, 2.0), r * 1.1, Color(Palette.SHOGUN_INDIGO_DARK, 0.45 + 0.3 * k))
		SpriteBank.draw_disc(self, p.pos + Vector2(-r * 0.4, wob), r * 0.7, Color(Palette.SHOGUN_INDIGO_LIGHT, 0.55 + 0.3 * k))
		SpriteBank.draw_disc(self, p.pos + Vector2(r * 0.4, -wob), r * 0.65, Color(Palette.SHOGUN_INDIGO_LIGHT, 0.5 + 0.3 * k))
		SpriteBank.draw_disc(self, p.pos + Vector2(0.0, -r * 0.35), r * 0.55, Color(0.85, 0.87, 0.95, 0.35 + 0.4 * k))
