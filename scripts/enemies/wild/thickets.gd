## Thickets — OVERGROWTH, the Turning Year's thorn thickets (temporary Act XV;
## GDD §15.0 "Overgrowth"; owner-approved proposal: "Dryads plant seeds that
## grow into thorn thickets: new obstacles that spread through the run and
## close lanes, and hold a summon caught in them. Fire (Summer's wildfires,
## burning spells), Rot and Wither burn them back. ... Built on the obstacle
## code Act VIII's wrecks already use for obstacles added mid-run"), owned by
## Game.wild as `thickets`. THE one planting path: plant().
##   * A SEED (plant(): a dryad, a spreading thicket, Spring Returns) shows as a
##     sprout for `grow` s, then grows into a THICKET: a solid circle obstacle
##     of `radius` px put into the arena through Arena.add_obstacle() (the one
##     path for an obstacle added mid-run on a scattered layout: snapped into
##     its arena cell, at most one obstacle a cell, like the city's wrecks), so
##     the push-out, the slide, free_point() and every lane test see it. A seed
##     within `player_clear` px of a standing necromancer waits (never walls him
##     in) and dies after `seed_wait` s; one on a taken cell dies at once. At
##     most `cap` seeds and thickets at once.
##   * A summon touching a thicket (within `hold_reach` px of its edge) is
##     CAUGHT: SummonedUnit.held_until for `hold` s (x Deadwood once phase 2
##     builds it), then walks free `regrab` s before it can be caught again.
##   * Every `spread_every` s a thicket plants a seed in a neighbouring arena
##     cell (chosen by a pure hash of its cell and spread count).
##   * BURNING: a wildfire front burns every thicket and seed it crosses
##     (burn_line()); any other fire, Rot or Wither source calls burn_at()
##     (phase 2 wires the burning spells); a thicket on dead ground
##     (BloomField.is_dead()) WITHERS away after `wither` s.
## Drawn: the thickets by the arena (WildGlyphs.draw_obstacle(), kind
## WildRulesData.THICKET_KIND), the sprouts on WildRules' under layer.
## Determinism: game time, positions and pure hashes; no RNG. Stats:
## thicket_seeds, thicket_seeds_capped, thicket_seeds_blocked,
## thicket_seeds_died, thickets_grown, thickets_burnt, thickets_withered,
## thicket_catches, thicket_spreads.
class_name Thickets
extends RefCounted

## One standing thicket.
class Thicket:
	extends RefCounted
	## Its solid obstacle (in the arena's cell table).
	var obstacle: Arena.Obstacle = null
	## Game time (s) it grew.
	var grown_at: float = 0.0
	## Seconds it has stood on dead ground (withers at `wither`).
	var wither: float = 0.0
	## Game time (s) of its next spread.
	var next_spread: float = INF
	## Seeds it has spread so far (the neighbour hash).
	var spreads: int = 0

## Owning run.
var game: Game
## The thickets' numbers (WildRulesData.THICKETS + the stage's "thickets").
var cfg: Dictionary = {}
## Waiting seeds: [position (Vector2), game s it grows, game s it dies, who planted it (String)] each.
var seeds: Array = []
## Standing thickets, oldest first.
var thickets: Array[Thicket] = []
## Most thickets standing at once this run.
var peak: int = 0
## Game time (s) of the next catch / wither check.
var _next_check: float = 0.0


## Builds the thickets for `p_game` (they work on any stage: a forced dryad
## plants there too).
func _init(p_game: Game) -> void:
	game = p_game
	cfg = WildRulesData.THICKETS.duplicate()
	var over: Dictionary = p_game.stage_def.get("thickets", {})
	for key: String in over:
		cfg[key] = over[key]


## THE planting path: a seed at `at` that grows in `grow` s (< 0 = the
## default), planted by `by` (a kind id or a rule's name; stats only).
func plant(at: Vector2, grow: float = -1.0, by: String = "") -> void:
	if seeds.size() + thickets.size() >= int(cfg["cap"]):
		game.stat_add("thicket_seeds_capped", 1.0)
		return
	var t := float(cfg["grow"]) if grow < 0.0 else grow
	seeds.append([at, game.elapsed + t, game.elapsed + t + float(cfg["seed_wait"]), by])
	game.stat_add("thicket_seeds", 1.0)


## Per tick (WildRules.step()): the seeds grow; every `check` s the catches,
## the withering and the spreading.
func step(_delta: float) -> void:
	var now := game.elapsed
	var i := seeds.size() - 1
	while i >= 0:
		var s: Array = seeds[i]
		if now >= float(s[1]):
			var res := _grow(s[0])
			if res != 0 or now >= float(s[2]):
				seeds.remove_at(i)
				if res == 0:
					game.stat_add("thicket_seeds_died", 1.0)
		i -= 1
	if now < _next_check or thickets.is_empty():
		return
	var dt := float(cfg["check"])
	_next_check = now + dt
	var j := thickets.size() - 1
	while j >= 0:
		var th := thickets[j]
		if game.arena.obstacle_at(th.obstacle.center) != th.obstacle:
			thickets.remove_at(j)  # The arena dropped its cell (a zone swap).
		elif game.wild.bloom.enabled and game.wild.bloom.is_dead(th.obstacle.center):
			th.wither += dt
			if th.wither >= float(cfg["wither"]):
				_remove(j)
				game.stat_add("thickets_withered", 1.0)
		elif now >= th.next_spread:
			th.next_spread = now + float(cfg["spread_every"])
			_spread(th)
		j -= 1
	_catch()


## Tries to grow the seed at `at`: 1 grown, -1 refused for good (its cell is
## taken), 0 waiting (a necromancer stands too close).
func _grow(at: Vector2) -> int:
	var c := _snap(at)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(c) < float(cfg["player_clear"]):
			return 0
	var o := Arena.Obstacle.new()
	o.kind = WildRulesData.THICKET_KIND
	o.is_circle = true
	o.center = c
	o.radius = minf(float(cfg["radius"]), ArenaData.MAX_HALF_EXTENT)
	o.variant = absi(hash(Vector2i(roundi(c.x), roundi(c.y))))
	o.art_key = EnvironmentArt.obstacle_key(o.kind, 0, 1, false)  # "obstacles/wild_thicket_m" (drawn once the art exists; WildGlyphs until then).
	if not game.arena.add_obstacle(o):
		game.stat_add("thicket_seeds_blocked", 1.0)
		return -1
	var th := Thicket.new()
	th.obstacle = o
	th.grown_at = game.elapsed
	th.next_spread = game.elapsed + float(cfg["spread_every"])
	thickets.append(th)
	peak = maxi(peak, thickets.size())
	game.stat_add("thickets_grown", 1.0)
	game.wild.play_sound("thicket_grow", c, 0.5)
	return 1


## `at` snapped into the inner square of its arena cell (where the arena puts
## an obstacle: ArenaData.CELL_MARGIN from each edge), whole px.
static func _snap(at: Vector2) -> Vector2:
	var cell := Vector2(floorf(at.x / ArenaData.CELL), floorf(at.y / ArenaData.CELL)) * ArenaData.CELL
	var lo := cell + Vector2.ONE * ArenaData.CELL_MARGIN
	var hi := cell + Vector2.ONE * (ArenaData.CELL - ArenaData.CELL_MARGIN)
	return at.clamp(lo, hi).round()


## Thicket `th` plants a seed in a neighbouring arena cell (a pure hash picks which).
func _spread(th: Thicket) -> void:
	var dirs := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var k := absi(hash(Vector3i(roundi(th.obstacle.center.x), roundi(th.obstacle.center.y), th.spreads))) % 4
	th.spreads += 1
	plant(th.obstacle.center + (dirs[k] as Vector2) * ArenaData.CELL)
	game.stat_add("thicket_spreads", 1.0)


## Takes thicket `j` out (the arena forgets it).
func _remove(j: int) -> void:
	game.arena.remove_obstacle(thickets[j].obstacle)
	thickets.remove_at(j)


## Catches every summon touching a thicket (see the header).
func _catch() -> void:
	var now := game.elapsed
	var reach := float(cfg["hold_reach"])
	var hold := float(cfg["hold"]) * game.wild.deadwood_mult()  # Deadwood: exactly 1 until phase 2 builds it.
	var free_after := now - float(cfg["regrab"])
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.held_until > free_after:
				continue
			for th in thickets:
				if u.position.distance_to(th.obstacle.center) <= th.obstacle.radius + u.radius + reach:
					u.held_until = now + hold
					game.stat_add("thicket_catches", 1.0)
					break


## A wildfire front at `front` running along `dir` (`width` x `depth` px)
## burns every thicket and seed it crosses.
func burn_line(front: Vector2, dir: Vector2, width: float, depth: float) -> void:
	var j := thickets.size() - 1
	while j >= 0:
		var rel := thickets[j].obstacle.center - front
		var r := thickets[j].obstacle.radius
		if absf(rel.dot(dir)) <= depth * 0.5 + r and absf(rel.dot(dir.orthogonal())) <= width * 0.5:
			_remove(j)
			game.stat_add("thickets_burnt", 1.0)
			game.wild.play_sound("thicket_burn", front, 0.3)
		j -= 1
	var i := seeds.size() - 1
	while i >= 0:
		var rel2 := (seeds[i][0] as Vector2) - front
		if absf(rel2.dot(dir)) <= depth * 0.5 and absf(rel2.dot(dir.orthogonal())) <= width * 0.5:
			seeds.remove_at(i)
		i -= 1


## Any other fire, Rot or Wither source burns every thicket within `r` px of
## `at` (phase 2 wires the burning spells here). Returns the thickets burnt.
func burn_at(at: Vector2, r: float) -> int:
	var n := 0
	var j := thickets.size() - 1
	while j >= 0:
		if thickets[j].obstacle.center.distance_to(at) <= r + thickets[j].obstacle.radius:
			_remove(j)
			n += 1
		j -= 1
	if n > 0:
		game.stat_add("thickets_burnt", float(n))
		game.wild.play_sound("thicket_burn", at, 0.3)
	return n


## True while a sprout shows (WildRules redraws the under layer).
func showing() -> bool:
	return not seeds.is_empty()


## Draws every waiting seed on `ci` (the under layer): a sprout that grows to
## its thicket's size (rects and disc textures only).
func draw(ci: CanvasItem) -> void:
	var r := float(cfg["radius"])
	for s: Array in seeds:
		var c := _snap(s[0])
		var k := clampf(1.0 - (float(s[1]) - game.elapsed) / maxf(0.1, float(cfg["grow"])), 0.15, 1.0)  # 0 -> 1 as it grows.
		SpriteBank.draw_disc(ci, c, r * k, Color(Palette.WILD_MOSS_DARK, 0.45))
		ci.draw_rect(Rect2(c + Vector2(-1.0, -6.0 * k), Vector2(2.0, 6.0 * k)), Color(Palette.WILD_MOSS, 0.9))  # The shoot.
