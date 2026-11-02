## LibertyHeightsDirector — the stage mechanics of LIBERTY HEIGHTS (Stage 24, the
## finale of Act VIII; GDD §15.0 "Liberty Heights (Act VIII phase 2)";
## owner-approved proposal docs/act8/PROPOSAL.md "Stage 24: Liberty Heights"),
## owned and stepped by EnemyDirector on a stage whose STAGE has a
## "liberty_heights" config (LibertyHeightsStage.LIBERTY_HEIGHTS; null
## elsewhere). The four zones are MarchDirector's (the clock is authoritative:
## the Plaza, the Rooftops, the Tower Lobby, the Watchtower: new rooftop
## looks and open-lot shares over the same city-block grid, CityBlocks.
## set_zone() through Arena.set_layout()); the Last Line's shared rules are
## Game.city's. This director runs:
##   * THE ZONE SUPERS (owner-approved proposal: "The Supers come in turn:
##     Blitz, Atlas, Aurora and Nightjar each lead one zone as its miniboss";
##     the brief's order: the Plaza Blitz, the Rooftops Aurora, the Tower
##     Lobby Atlas, the Watchtower Nightjar, the STAGE "supers" roster in that
##     order): at each zone's `time` the director brings the roster's next
##     Super through SuperRoster.call_next() (so it joins the met list); the
##     Watchtower's comes with the heroes tier itself (the escalation's own
##     call_next() at 15:00, `escalation` true in the config). Every roster
##     Super that arrives in its zone's window (before the boss) is PROMOTED
##     to the zone's leader: a miniboss (Enemy.is_miniboss: the HUD bar,
##     EnemyDirector.set_miniboss(), the ChestManager's miniboss chest),
##     leader_hp_mult x its health, a banner;
##   * GUEST SQUADS: Fort Kessler's army kinds (the Machine Gunner and the
##     Attack Helicopter, built in parallel) join small squads on a timer when
##     this build knows them (EnemyDirector.is_known_kind(); candidate ids,
##     the first one known), as Castle Sanguis's guests, so the stage plays
##     the same before and after Fort Kessler merges;
##   * THE CRACKS of Paragon's dives from orbit (add_crack(): a crack decal per
##     crater, at most crack_max, the oldest fading; drawn here over the floor,
##     under the bodies; textures only).
## Deterministic: the seeded global RNG only (the spawn points, the guests'
## roll). Stats: lh_leaders, lh_leader_<kind>, lh_leader_killed_<kind>,
## lh_guest_squads, lh_guests_spawned, lh_cracks.
class_name LibertyHeightsDirector
extends Node2D

## One crack left by a crater.
class Crack:
	extends RefCounted
	## Its centre (world px).
	var at: Vector2 = Vector2.ZERO
	## Its radius (px).
	var r: float = 40.0
	## Its turn (rad; from the crack count, no RNG).
	var angle: float = 0.0

## Owning run.
var game: Game
## The stage's config (LibertyHeightsStage.LIBERTY_HEIGHTS).
var config: Dictionary = {}
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the next zone Super entry (config "zone_supers").
var _next_zone: int = 0
## Roster Super id -> the zone leader promoted for it (Enemy; generation in
## _leader_gens).
var _leaders: Dictionary = {}
## Roster Super id -> pool generation of its promoted leader.
var _leader_gens: Dictionary = {}
## Roster Super id -> true once its leader's fall was logged.
var _leaders_down: Dictionary = {}
## Game time of the next guest squad.
var _next_guest: float = INF
## Guest squads sent so far (their size grows with it).
var _guest_squads: int = 0
## The cracks left by Paragon's craters (oldest first).
var cracks: Array[Crack] = []


func _ready() -> void:
	z_index = -7  # Over the floor (-10), under the obstacles (-6) and the bodies.
	z_as_relative = false
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var zs: Array = config["zone_supers"]
	while _next_zone < zs.size() and game.elapsed >= float(zs[_next_zone]["time"]):
		var z: Dictionary = zs[_next_zone]
		_next_zone += 1
		if not bool(z.get("escalation", false)) and game.city != null:
			game.city.supers.call_next()  # The zone's Super (the roster's order is the zones' order).
	_promote()
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()


## Promotes each roster Super that arrived in its zone's window (before the
## boss) to the zone's leader: a miniboss with leader_hp_mult its health.
func _promote() -> void:
	if game.city == null or game.elapsed >= float(config["leaders_until"]):
		_watch_leaders()
		return
	var zs: Array = config["zone_supers"]
	for e: Enemy in game.city.supers.alive:
		if not e.active or _leaders.has(e.kind):
			continue
		var z := {}
		for row: Dictionary in zs:
			if String(row["id"]) == e.kind and game.elapsed >= float(row["time"]):
				z = row
				break
		if z.is_empty():
			continue
		_leaders[e.kind] = e
		_leader_gens[e.kind] = e.generation
		e.is_miniboss = true  # The zone's miniboss: its chest (ChestManager) and the HUD bar.
		var m := float(config["leader_hp_mult"])
		e.max_hp *= m
		e.hp *= m
		game.enemies.set_miniboss(e)
		game.enemies.show_banner(String(z["banner"]))
		game.stat_add("lh_leaders", 1.0)
		game.stat_add("lh_leader_" + e.kind, 1.0)
		_log("leader_" + e.kind)
	_watch_leaders()


## Logs each promoted leader's fall once.
func _watch_leaders() -> void:
	for id: String in _leaders:
		if _leaders_down.has(id):
			continue
		var e: Enemy = _leaders[id]
		if not e.active or e.generation != int(_leader_gens[id]):
			_leaders_down[id] = true
			if game.city != null and game.city.supers.fallen.has(id):
				game.stat_add("lh_leader_killed_" + id, 1.0)
				_log(id + "_down")


## Sends one guest squad from the spawn ring (one weighted kind, the soft cap
## respected like any continuous source).
func _send_guests() -> void:
	var total := 0.0
	for g: Array in guests:
		total += float(g[1])
	var roll := randf() * total
	var kind := String(guests[0][0])
	for g: Array in guests:
		roll -= float(g[1])
		if roll <= 0.0:
			kind = String(g[0])
			break
	var n := mini(int(config["guest_count"]) + floori(float(_guest_squads) * float(config["guest_growth"])), int(config["guest_max"]))
	var room := game.enemies.soft_cap() - game.enemies.regular_alive()  # Soft-cap room.
	n = mini(n, maxi(0, room))
	_guest_squads += 1
	if n <= 0:
		return
	game.enemies.spawn_formation("arc", [{"kind": kind, "count": n, "elite": false}])
	game.stat_add("lh_guest_squads", 1.0)
	game.stat_add("lh_guests_spawned", float(n))


# =====================================================================================
# The cracks (Paragon's craters)
# =====================================================================================

## A crater cracks the arena at `at` (radius `r` px); at most `cap` cracks are
## kept (the oldest goes). Called by BossParagon when a dive lands.
func add_crack(at: Vector2, r: float, cap: int) -> void:
	var c := Crack.new()
	c.at = at
	c.r = r * 1.15
	c.angle = float(cracks.size() + _cracks_made()) * 1.7
	cracks.append(c)
	while cracks.size() > maxi(1, cap):
		cracks.pop_front()
	game.stat_add("lh_cracks", 1.0)
	queue_redraw()


## Cracks made this run (the turn of the next one; no RNG).
func _cracks_made() -> int:
	return int(game.stats.get("lh_cracks", 0.0))


## Every crack: the made crack texture. Visual only.
func _draw() -> void:
	for c in cracks:
		LibertyHeightsGlyphs.draw_crack(self, c.at, c.r, c.angle, 0.9)


# =====================================================================================
# HUD and report
# =====================================================================================

## HUD objective while a zone's leader stands ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb == null or not _leaders.has(mb.kind) or _leaders[mb.kind] != mb:
		return ""
	for row: Dictionary in config["zone_supers"]:
		if String(row["id"]) == mb.kind:
			return String(row["objective"])
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	var lead := PackedStringArray()
	for row: Dictionary in config["zone_supers"]:
		var id := String(row["id"])
		lead.append("%s %s%s" % [id, "led" if _leaders.has(id) else "-", " (killed)" if int(st.get("lh_leader_killed_" + id, 0.0)) > 0 else ""])
	return "zone supers: %s | fallen %s | guests: %s, squads %d, spawned %d | cracks %d" % [
		", ".join(lead), ", ".join(game.city.supers.fallen) if game.city != null and not game.city.supers.fallen.is_empty() else "-",
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("lh_guest_squads", 0.0)),
		int(st.get("lh_guests_spawned", 0.0)), int(st.get("lh_cracks", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
