## BoardingParty — BOARDING, the Black Tide's headline rule (Act X; GDD §15.0
## "Boarding"; owner-approved proposal: "Pirates do not appear at the screen
## edge. Boats pull alongside the rail and pour their crews aboard"). Owned by
## Game.corsair. THE ONLY SPAWN ROUTE of the timeline on a corsair stage:
##   * THE QUEUE: CorsairRules.route_spawn() hands it every crew spawn the
##     wave director asks for (the trickle, wave events, the Reckoning) as an
##     entry {kind, hp scale, elite, damage scale, reckoning, promoted}. The
##     budget is the director's own (EnemyDirector.regular_alive() counts the
##     waiting crew through CorsairRules.alive_adjust()): no extra enemies,
##     only a different door. The queue is capped (`queue_cap`); a spawn past
##     it is refused (counted).
##   * LAUNCH: a boat sets out when `min_crew` wait or the oldest waited
##     `max_wait` s, a boarding point is free and fewer than `max_boats` boats
##     are out (the pooled boats, cap 4). Its LANE is chosen from the stage's
##     free boarding points with the seeded gameplay RNG (BOARDING "points":
##     [x, side] pairs on the straight rail; "whole_rail": anywhere on it).
##     Its SIZE is the smallest of the stage's allowed sizes (the tier cap,
##     "boats") that holds the waiting crew, else the largest; it takes crew
##     from the queue head up to its capacity (CorsairRulesData.BOAT_CREW),
##     while it is out and still has room.
##   * THE LANE (lane_time s, 3 s: owner-approved proposal): a dotted wake line
##     and an amber lantern at the rail point.
##   * HOOKED: the boat (a pooled STRUCTURE enemy of its size's kind, its hull
##     over the rail line so a summon at the rail reaches it) and two GRAPPLE
##     HOOKS (40 HP structures at the rail, `hook_spread` px either side, a
##     rope drawn to the boat). One crewman steps aboard every pour_every s
##     (0.6 s; a raider ship pours two at a time on two planks) through
##     EnemyDirector.spawn_routed() at the plank point (Arena.free_point():
##     on the deck, out of the furniture), with the entry's scaling.
##   * REPEL: both hooks cut -> the boat drifts off for drift_time s (6 s) and
##     vanishes; its remaining crew is cancelled (those aboard stay).
##   * SINK: the hull destroyed -> its remaining crew drowns (no XP), and one
##     floating crate (crate_xp crystals) washes against the rail.
##   * EMPTIED: no crew left and none waiting -> it casts off (leave_time s).
##   * CO-OP: max_boats and queue_cap x the co-op alive cap (CoopData).
##   * THE BLACK TIDE (BlackTide running): the whole rail is a boarding point,
##     tide_max_boats boats at once, a shorter lane and pour, a larger queue.
## Determinism: the seeded gameplay RNG only (lanes), game time, ordered lists
## with pooling generations. Stats: boats_launched, boats_<size>, boats_hooked,
## boats_repelled, boats_sunk, boats_emptied, crew_aboard, crew_cancelled,
## crew_drowned, boarding_refused, hooks_cut; the Smuggler's Cutter's
## boats_sunk_clean (a boat sunk before any of its crew climbed aboard).
## The Cutter's two hooks (its block): the Fog Bank's `fog_reveal` (a lane
## shown only for its last seconds) and the STAGE boarding key "first_pour"
## (s from hooking to the first crewman; absent = half a pour, as before).
class_name BoardingParty
extends RefCounted

## Boat state: its lane shows (the telegraph).
const LANE: int = 0
## Boat state: hooked to the rail, pouring its crew.
const HOOKED: int = 1
## Boat state: repelled (both hooks cut), drifting off.
const DRIFT: int = 2
## Boat state: emptied, casting off.
const LEAVE: int = 3

## Owning run.
var game: Game
## True on an Act X stage (the boats run).
var enabled: bool = false
## Boarding's numbers (CorsairRulesData.BOARDING + the STAGE "boarding").
var cfg: Dictionary = {}
## Waiting crew, oldest first: each {kind, hp, elite, dmg, reck, promoted, t}.
var queue: Array[Dictionary] = []
## Boats out, in launch order: each {id, state, t (game s the state began),
## size, rail (Vector2), n (outward normal), lane (int; -1 = whole rail),
## crew (Array of entries aboard), capacity, taken, planks, next_pour,
## boat (Enemy or null), boat_gen, hooks (Array of [Enemy, gen])}.
var boats: Array[Dictionary] = []
## The stage's boarding points as [Vector2 rail point, Vector2 outward normal].
var points: Array = []
## Boats launched this run (and the next boat's id).
var launched: int = 0
## Most crew waiting at once (the report).
var peak_queue: int = 0
## Most boats out at once (the report).
var peak_boats: int = 0
## Crew who stepped aboard this run.
var aboard: int = 0
# --- Act X: the Smuggler's Cutter ---
## THE FOG BANK (CutterDirector sets it while its fog zone lasts; 0 = no fog):
## a boat launched now shows its lane only for its last `fog_reveal` s (the
## boat's "fog" flag; draw() hides the wake and the lantern before that).
var fog_reveal: float = 0.0


## Builds Boarding for `p_game`; `p_enabled` false on a non-Act X stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = CorsairRulesData.BOARDING.duplicate()
	var st: Dictionary = p_game.stage_def.get("boarding", {})
	for k: String in st:
		cfg[k] = st[k]
	if not cfg.has("boats"):
		cfg["boats"] = CorsairRulesData.BOAT_ORDER.duplicate()
	if not cfg.has("points"):
		cfg["points"] = []


## The boarding points (built on first use: the deck exists by then).
func _points() -> Array:
	if points.is_empty() and game.deck != null:
		for pt: Array in cfg["points"]:
			var side := int(pt[1])
			points.append([game.deck.rail_point(float(pt[0]), side), Vector2(0.0, 1.0 if side > 0 else -1.0)])
	return points


# =====================================================================================
# The queue
# =====================================================================================

## A crew spawn from the timeline waits for a boat (refused past the cap).
func enqueue(kind: String, hp_scale: float, elite: bool, dmg_scale: float, reckoning: bool, promoted: bool) -> void:
	if queue.size() >= _cap("queue_cap"):
		game.stat_add("boarding_refused", 1.0)
		return
	queue.append({"kind": kind, "hp": hp_scale, "elite": elite, "dmg": dmg_scale, "reck": reckoning, "promoted": promoted, "t": game.elapsed})
	peak_queue = maxi(peak_queue, queue.size())


## Crew waiting in the queue and aboard the boats (they count as alive).
func waiting() -> int:
	var n := queue.size()
	for b in boats:
		n += (b["crew"] as Array).size()
	return n


## Boats and hooks alive on the field (they do not count as alive crew).
func structures_alive() -> int:
	var n := 0
	for b in boats:
		if _boat_alive(b):
			n += 1
		for h: Array in b["hooks"]:
			if _alive(h[0], int(h[1])):
				n += 1
	return n


## A boarding number, the Black Tide's version while it runs (tide_<key>). In
## co-op (twice the enemies) the boat and queue caps grow with the alive cap
## (CoopData through DifficultyModifiers.coop_mult("alive_cap"); solo x1).
func _cap(key: String) -> int:
	var v := int(cfg["tide_" + key]) if _tide() and cfg.has("tide_" + key) else int(cfg[key])
	if game.coop != null and (key == "max_boats" or key == "queue_cap"):
		v = roundi(float(v) * game.difficulty.coop_mult("alive_cap"))
	return v


## A boarding time (s), the Black Tide's version while it runs.
func _time(key: String) -> float:
	if _tide() and cfg.has("tide_" + key):
		return float(cfg["tide_" + key])
	return float(cfg[key])


## True while the Black Tide runs (the whole rail boards).
func _tide() -> bool:
	return game.corsair != null and game.corsair.tide.running()


# =====================================================================================
# The clock
# =====================================================================================

## Per-tick update (CorsairRules.step()): every boat's state, then new launches.
func step(delta: float) -> void:
	if not enabled or game.deck == null:
		return
	var now := game.elapsed
	var i := 0
	while i < boats.size():
		if _step_boat(boats[i], now, delta):
			i += 1
		else:
			boats.remove_at(i)
	while not queue.is_empty() and boats.size() < _cap("max_boats"):
		if queue.size() < int(cfg["min_crew"]) and now - float(queue[0]["t"]) < float(cfg["max_wait"]) and not _tide():
			break
		if not _launch(now):
			break
	peak_boats = maxi(peak_boats, boats.size())


## One boat's tick (`delta` s); false when it is gone (drop it from the list).
func _step_boat(b: Dictionary, now: float, delta: float) -> bool:
	var state := int(b["state"])
	if state == LANE or state == HOOKED:
		_fill(b)
	match state:
		LANE:
			if now >= float(b["t"]) + _time("lane_time"):
				_hook(b, now)
		HOOKED:
			if not _boat_alive(b):
				return false  # Sunk (on_boat_killed() already settled it).
			var hooks_left := 0
			for h: Array in b["hooks"]:
				if _alive(h[0], int(h[1])):
					hooks_left += 1
			if hooks_left == 0:
				_repel(b, now)
				return true
			while now >= float(b["next_pour"]) and not (b["crew"] as Array).is_empty():
				for k in int(b["planks"]):
					if not (b["crew"] as Array).is_empty():
						_pour(b, k)
				b["next_pour"] = float(b["next_pour"]) + _time("pour_every")
			if (b["crew"] as Array).is_empty() and (int(b["taken"]) >= int(b["capacity"]) or queue.is_empty()):
				_cast_off(b, now)
		DRIFT, LEAVE:
			var boat: Enemy = b["boat"]
			if _boat_alive(b):
				boat.position += (b["n"] as Vector2) * float(cfg["drift_speed"]) * delta
			var span := float(cfg["drift_time"]) if state == DRIFT else float(cfg["leave_time"])
			if now >= float(b["t"]) + span:
				if _boat_alive(b):
					game.enemies.despawn(boat)
				return false
	return true


## Takes crew from the queue head onto boat `b` while it has room.
func _fill(b: Dictionary) -> void:
	while not queue.is_empty() and int(b["taken"]) < int(b["capacity"]):
		(b["crew"] as Array).append(queue.pop_front())
		b["taken"] = int(b["taken"]) + 1


## Launches one boat if a lane is free (false when none is).
func _launch(now: float) -> bool:
	var lane := _pick_lane()
	if lane.is_empty():
		return false
	var size := _pick_size(queue.size())
	launched += 1
	var b := {"id": launched, "state": LANE, "t": now, "size": size, "rail": lane[0], "n": lane[1], "lane": int(lane[2]),
		"crew": [], "capacity": int(CorsairRulesData.BOAT_CREW[size]), "taken": 0,
		"planks": int(CorsairRulesData.BOAT_PLANKS.get(size, 1)), "next_pour": 0.0, "boat": null, "boat_gen": 0, "hooks": []}
	b["fog"] = fog_reveal  # Act X, the Cutter: the Fog Bank's hidden lane (0 = none).
	b["poured"] = 0  # Act X, the Cutter: crew this boat put aboard (a clean sink has none).
	boats.append(b)
	_fill(b)
	game.stat_add("boats_launched", 1.0)
	game.stat_add("boats_" + size, 1.0)
	return true


## A free lane: [rail point, outward normal, point index (-1 = whole rail)],
## or [] when every boarding point is busy. Seeded gameplay RNG.
func _pick_lane() -> Array:
	var whole := bool(cfg.get("whole_rail", false)) or _tide()
	if not whole:
		var free: Array = []
		var pts := _points()
		for i in pts.size():
			var used := false
			for b in boats:
				if int(b["lane"]) == i:
					used = true
					break
			if not used:
				free.append(i)
		if free.is_empty():
			return []
		var k := int(free[randi() % free.size()])
		return [pts[k][0], pts[k][1], k]
	var length := game.deck.straight_rail_length()
	for _try in 4:
		var side := 1 if randf() < 0.5 else -1
		var x := (randf() - 0.5) * length  # Along the straight rail, from the deck's centre.
		var p := game.deck.rail_point(x, side)
		var clear := true
		for b in boats:
			if (b["rail"] as Vector2).distance_to(p) < 110.0:
				clear = false
				break
		if clear:
			return [p, Vector2(0.0, float(side)), -1]
	return []


## The smallest allowed boat size that holds `waiting` crew, else the largest allowed.
func _pick_size(n_waiting: int) -> String:
	var allowed: Array = cfg["boats"]
	var last := String(allowed[allowed.size() - 1])
	for s: String in CorsairRulesData.BOAT_ORDER:
		if allowed.has(s):
			last = s
			if int(CorsairRulesData.BOAT_CREW[s]) >= n_waiting:
				return s
	return last


## The boat comes alongside: its hull and two grapple hooks are spawned.
func _hook(b: Dictionary, now: float) -> void:
	var rail: Vector2 = b["rail"]
	var n: Vector2 = b["n"]
	var size := String(b["size"])
	var row := game.enemies.enemy_def(size)
	var br := float(row["radius"])
	var boat := game.enemies.spawn_routed(size, rail, game.enemies.hp_mult, false)
	boat.position = rail + n * br * (1.0 - float(cfg["boat_overlap"]))  # In the water, its hull over the rail line.
	b["boat"] = boat
	b["boat_gen"] = boat.generation
	var along := Vector2(-n.y, n.x)  # Along the rail.
	for sgn: float in [-1.0, 1.0]:
		var at := rail - n * float(cfg["hook_inset"]) + along * sgn * float(cfg["hook_spread"])
		var hook := game.enemies.spawn_routed(CorsairEnemyData.HOOK, at, game.enemies.hp_mult, false)
		hook.is_objective = true  # It stands until cut (never recycled).
		(b["hooks"] as Array).append([hook, hook.generation])
	b["state"] = HOOKED
	b["t"] = now
	b["next_pour"] = now + (_time("pour_every") * 0.5 if _tide() or not cfg.has("first_pour") else float(cfg["first_pour"]))  # Act X, the Cutter: STAGE boarding "first_pour" (the crew climbs the hooks)
	game.stat_add("boats_hooked", 1.0)
	if game.corsair != null:
		game.corsair.play_sound("hook_bite", rail, 0.2)


## One crewman steps aboard from plank `k` of boat `b`.
func _pour(b: Dictionary, k: int) -> void:
	var c: Dictionary = (b["crew"] as Array).pop_front()
	var n: Vector2 = b["n"]
	var along := Vector2(-n.y, n.x)
	var off := 0.0 if int(b["planks"]) < 2 else (16.0 if k == 0 else -16.0)  # Two planks side by side.
	var at: Vector2 = (b["rail"] as Vector2) - n * float(cfg["plank_inset"]) + along * off
	var kind := String(c["kind"])
	var e := game.enemies.spawn_routed(kind, at, float(c["hp"]), bool(c["elite"]))
	if bool(c["promoted"]):
		e.is_promoted = true  # A threat, not a loot source (EnemyDirector's trickle rule).
		e.xp_value = int(game.enemies.enemy_def(kind)["xp"])
	if float(c["dmg"]) != 1.0:
		e.damage *= float(c["dmg"])
	if bool(c["reck"]):
		e.is_reckoning = true
	aboard += 1
	b["poured"] = int(b.get("poured", 0)) + 1
	game.stat_add("crew_aboard", 1.0)


## Both hooks cut: the boat drifts off and its remaining crew is cancelled.
func _repel(b: Dictionary, now: float) -> void:
	var left := (b["crew"] as Array).size()
	b["crew"] = []
	b["taken"] = int(b["capacity"])  # It takes no more.
	b["state"] = DRIFT
	b["t"] = now
	game.stat_add("boats_repelled", 1.0)
	game.stat_add("crew_cancelled", float(left))
	if game.corsair != null:
		game.corsair.play_sound("hook_cut", b["rail"], 0.2)


## The boat is empty: its hooks come off and it casts off.
func _cast_off(b: Dictionary, now: float) -> void:
	for h: Array in b["hooks"]:
		if _alive(h[0], int(h[1])):
			game.enemies.despawn(h[0])
	b["state"] = LEAVE
	b["t"] = now
	game.stat_add("boats_emptied", 1.0)


## A boat's hull was destroyed (CorsairBoatKit.on_killed()): its remaining crew
## drowns (no XP), its hooks fall, one floating crate washes against the rail.
func on_boat_killed(boat: Enemy) -> void:
	for b in boats:
		if b["boat"] != boat or int(b["boat_gen"]) != boat.generation:
			continue
		var left := (b["crew"] as Array).size()
		b["crew"] = []
		b["taken"] = int(b["capacity"])
		for h: Array in b["hooks"]:
			if _alive(h[0], int(h[1])):
				game.enemies.despawn(h[0])
		var crate: Vector2 = (b["rail"] as Vector2) - (b["n"] as Vector2) * 12.0
		game.pickups.spawn(crate, int(cfg["crate_xp"]))
		game.stat_add("boats_sunk", 1.0)
		game.stat_add("crew_drowned", float(left))
		if int(b.get("poured", 0)) == 0:
			game.stat_add("boats_sunk_clean", 1.0)  # Act X, the Cutter: sunk before one of its crew climbed aboard (Not One Aboard).
		if game.corsair != null:
			game.corsair.play_sound("hull_creak", boat.position, 0.2)
		return


## A grapple hook was cut (BoardingHookKit.on_killed()).
func on_hook_killed(_hook: Enemy) -> void:
	game.stat_add("hooks_cut", 1.0)


## True while boat `b`'s hull stands.
func _boat_alive(b: Dictionary) -> bool:
	return b["boat"] != null and _alive(b["boat"], int(b["boat_gen"]))


## True while `e` is the same living enemy it was at generation `gen`.
static func _alive(e: Enemy, gen: int) -> bool:
	return e != null and e.active and e.generation == gen


## Draws the lanes (a dotted wake and an amber lantern) and the hooked boats'
## ropes on `ci` (CorsairRules; visual only).
func draw(ci: CanvasItem) -> void:
	var t := game.elapsed
	for b in boats:
		var rail: Vector2 = b["rail"]
		var n: Vector2 = b["n"]
		if int(b["state"]) == LANE and float(b.get("fog", 0.0)) > 0.0 and t < float(b["t"]) + _time("lane_time") - float(b["fog"]):
			continue  # Act X, the Cutter: the Fog Bank hides the lane until its last `fog` s.
		if int(b["state"]) == LANE:
			var k := clampf((t - float(b["t"])) / maxf(_time("lane_time"), 0.01), 0.0, 1.0)  # 0 -> 1 as it nears.
			var d := 40.0
			while d < 380.0:
				if d > 40.0 + (1.0 - k) * 300.0:
					ci.draw_rect(Rect2(rail + n * d - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(Palette.CORSAIR_FOAM, 0.75))
				d += 16.0
			var glow := 0.55 + 0.45 * absf(sin(t * 6.0))
			SpriteBank.draw_disc(ci, rail, 11.0, Color(Palette.CORSAIR_LANTERN, 0.25 * glow))
			SpriteBank.draw_disc(ci, rail, 4.5, Color(Palette.CORSAIR_LANTERN_LIGHT, glow))
		elif int(b["state"]) == HOOKED and _boat_alive(b):
			var boat: Enemy = b["boat"]
			for h: Array in b["hooks"]:
				if _alive(h[0], int(h[1])):
					ci.draw_line((h[0] as Enemy).position, boat.position, Palette.CORSAIR_SAIL_SHADE, 1.5)
