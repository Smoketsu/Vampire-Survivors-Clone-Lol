## Scavengers — SCAVENGERS, the third shared rule of the Age of Titans
## (temporary Act XIV; GDD §15.0 "Scavengers"; owner-approved proposal:
## "Pterosaurs snatch XP crystals and drops: every 8 s a Skyraider dives (a
## shadow circle first), takes the nearest pile worth up to 10 crystals and
## flies to a cliff nest at the arena's edge. Kill it in the air and the pile
## drops where it dies. Anything within 200 px of the necromancer is safe from
## snatching. This pressures the economy, not the army. One path: Scavengers,
## a thin scheduler over the pickup pool; it never changes XP values"), owned
## by Game.primeval as `scavengers`. THE one path:
##   * THE THIEVES: every scavenger kind (row "scavenger") on the field is
##     listed (note_spawn()); while idle it circles `hover_radius` px from the
##     nearest standing necromancer and never bites (SkyraiderKit).
##   * THE DIVE (step(); every `every` s from `first`; a forced Skyraider
##     elsewhere dives too): the first idle thief in the list (spawn order)
##     with a PILE in reach dives on it: the nearest crystal within `search`
##     px that lies farther than safe_radius() px from every standing
##     necromancer and is not already flying to him, plus every such crystal
##     within `pile_radius` px of it, at most `max_crystals`. Its shadow circle
##     shows at the pile for `warn` s while it flies there at `dive_speed`.
##   * THE SNATCH (snatch()): when it arrives and the warning is over, every
##     crystal still lying there and still unsafe is taken out of the world
##     (XpManager.take(): pooled, no XP) and its value carried; the thief flies
##     away from the nearest necromancer at `flee_speed` and, `nest_dist` px
##     from every standing necromancer, reaches its nest and leaves the field
##     with the pile (EnemyDirector.despawn(): lost).
##   * THE DROP (on_killed()): a carrier killed in the air drops its pile where
##     it dies, every crystal with its own value (XpManager.spawn()), so XP
##     values never change; a pile a carrier takes off the field any other way
##     is lost.
## Hoarder's Bones hook: PrimevalRules.hoarders_bones_reach() (0 today) widens
## the safe radius. Determinism: no RNG of its own (XpManager.spawn()'s jitter
## is the seeded gameplay RNG); thieves are an ordered list with pooling
## generations. Stats (the "scavengers" line): scav_dives, scav_snatches,
## scav_crystals_taken, scav_xp_taken, scav_drops, scav_crystals_dropped,
## scav_xp_dropped, scav_nests, scav_xp_lost, scav_dives_empty.
class_name Scavengers
extends RefCounted

## Owning run.
var game: Game
## The thefts' numbers (SCAVENGERS with the STAGE's "scavengers").
var cfg: Dictionary = {}
## Thieves on the field, in spawn order: [Enemy, its generation] each.
var thieves: Array = []
## Most thieves alive at once (the report).
var peak: int = 0
## Game time (s) of the next dive.
var _next: float = 0.0


## Builds Scavengers for `p_game` (PrimevalRules keeps it).
func _init(p_game: Game) -> void:
	game = p_game
	cfg = PrimevalRulesData.SCAVENGERS.duplicate()
	var over: Dictionary = p_game.stage_def.get("scavengers", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_next = float(cfg["first"])


## Radius (px) round a standing necromancer inside which nothing is snatched
## (Hoarder's Bones widens it: 0 until phase 2 builds it).
func safe_radius() -> float:
	return maxf(float(cfg["safe_radius"]), game.primeval.hoarders_bones_reach())


## A thief came onto the field.
func note_spawn(e: Enemy) -> void:
	thieves.append([e, e.generation])
	peak = maxi(peak, thieves.size())


## A thief left the field.
func note_gone(e: Enemy) -> void:
	for i in thieves.size():
		if thieves[i][0] == e:
			thieves.remove_at(i)
			return


## Per tick (PrimevalRules.step()): the dive clock.
func step(_delta: float) -> void:
	if game.elapsed < _next:
		return
	_next = game.elapsed + float(cfg["every"])
	for t: Array in thieves:
		var e: Enemy = t[0]
		if not e.active or e.generation != int(t[1]):
			continue
		var kit := e.kit as SkyraiderKit
		if kit.phase != SkyraiderKit.IDLE:
			continue
		var pile := find_pile(e.position)
		if pile.is_empty():
			continue
		kit.dive(e, (pile[0] as XpCrystal).position)
		game.stat_add("scav_dives", 1.0)
		game.primeval.play_sound("skyraider_dive", e.position, 0.5)
		return


## True when crystal `c` may be snatched now (lying in the world, not flying
## to a necromancer, farther than safe_radius() from every standing one).
func unsafe(c: XpCrystal) -> bool:
	if not c.active or c.magnet:
		return false
	var safe := safe_radius()
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_squared_to(c.position) <= safe * safe:
			return false
	return true


## The pile a thief at `from` would take (see the header; [] when none): the
## nearest unsafe crystal within `search` px first.
func find_pile(from: Vector2) -> Array[XpCrystal]:
	var first: XpCrystal = null
	var best := float(cfg["search"]) * float(cfg["search"])
	for c in game.pickups.active:
		var d2 := c.position.distance_squared_to(from)
		if d2 < best and unsafe(c):
			best = d2
			first = c
	if first == null:
		return []
	return pile_at(first.position)


## Every unsafe crystal within `pile_radius` px of `at`, nearest first, at most
## `max_crystals` (in the pool's order for equal distances).
func pile_at(at: Vector2) -> Array[XpCrystal]:
	var r2 := float(cfg["pile_radius"]) * float(cfg["pile_radius"])
	var out: Array[XpCrystal] = []
	for c in game.pickups.active:
		if c.position.distance_squared_to(at) <= r2 and unsafe(c):
			out.append(c)
	out.sort_custom(func(a: XpCrystal, b: XpCrystal) -> bool: return a.position.distance_squared_to(at) < b.position.distance_squared_to(at))
	return out.slice(0, int(cfg["max_crystals"]))


## THE snatch: thief `e` takes the pile still lying at `at`; returns the
## crystal values it carries now (empty: nothing was left to take).
func snatch(e: Enemy, at: Vector2) -> PackedInt32Array:
	var taken := PackedInt32Array()
	for c in pile_at(at):
		var v := game.pickups.take(c)
		if v > 0:
			taken.append(v)
	if taken.is_empty():
		game.stat_add("scav_dives_empty", 1.0)
		return taken
	var xp := 0
	for v in taken:
		xp += v
	game.stat_add("scav_snatches", 1.0)
	game.stat_add("scav_crystals_taken", float(taken.size()))
	game.stat_add("scav_xp_taken", float(xp))
	game.primeval.play_sound("snatch", e.position, 0.3)
	return taken


## A carrier was killed in the air: its pile drops where it dies (each crystal
## with its own value).
func drop(e: Enemy, taken: PackedInt32Array) -> void:
	var xp := 0
	for v in taken:
		game.pickups.spawn(e.position, v)
		xp += v
	game.stat_add("scav_drops", 1.0)
	game.stat_add("scav_crystals_dropped", float(taken.size()))
	game.stat_add("scav_xp_dropped", float(xp))
	game.primeval.play_sound("pile_drop", e.position, 0.3)


## A carrier reached its nest with its pile (lost).
func nested(e: Enemy, taken: PackedInt32Array) -> void:
	var xp := 0
	for v in taken:
		xp += v
	game.stat_add("scav_nests", 1.0)
	game.stat_add("scav_xp_lost", float(xp))
	game.enemies.despawn(e)


## True when `e` is farther than `nest_dist` px from every standing necromancer.
func at_nest(e: Enemy) -> bool:
	var r := float(cfg["nest_dist"])
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_squared_to(e.position) <= r * r:
			return false
	return true


## Draws every diving thief's shadow circle on `ci` (PrimevalRules' layer;
## disc textures only).
func draw(ci: CanvasItem) -> void:
	var r := float(cfg["shadow_radius"])
	for t: Array in thieves:
		var e: Enemy = t[0]
		if not e.active or e.generation != int(t[1]):
			continue
		var kit := e.kit as SkyraiderKit
		if kit.phase != SkyraiderKit.DIVE:
			continue
		var k := clampf(kit.phase_time / maxf(0.01, float(cfg["warn"])), 0.0, 1.0)  # The shadow darkens as it comes.
		SpriteBank.draw_disc(ci, kit.dive_at, r * (1.3 - 0.3 * k), Color(Palette.PRIMEVAL_INK, 0.2 + 0.35 * k))


## True while a thief dives (PrimevalRules redraws).
func showing() -> bool:
	for t: Array in thieves:
		var e: Enemy = t[0]
		if e.active and e.generation == int(t[1]) and (e.kit as SkyraiderKit).phase == SkyraiderKit.DIVE:
			return true
	return false
