## PandemoniumDirector — the stage mechanics of PANDEMONIUM (Stage 18, the
## finale of Part One; Act VI; GDD §15.0 "Pandemonium (Act VI phase 2)";
## owner-approved proposal docs/act6/PROPOSAL.md "Stage 18: Pandemonium"),
## owned and stepped by EnemyDirector on a stage whose STAGE has a
## "pandemonium" config (PandemoniumStage.PANDEMONIUM; null elsewhere). The four
## zones are MarchDirector's (the clock is authoritative: the Iron City, the
## Chain Bridges, the Cathedral of Ash, the Throne); the Hell Pits (one fixed
## table per zone: the Chain Bridges run over rivers of lava), the portals and
## Temptation are the Inferno's shared rules (Game.inferno). This director runs:
##   * THE FALLEN SERAPH GENERAL (the "seraph_general" timeline event): the
##     miniboss lands at the spawn ring with his escort (SeraphGeneralKit
##     registers him for the HUD bar; ChestManager drops his chest).
##   * GUEST SQUADS: the other Act VI stages' kinds (the Burning Gate's and the
##     Palace of Silk and Ash's, built in parallel) join small squads on a
##     timer when this build knows them (EnemyDirector.is_known_kind();
##     candidate ids per kind, the first one known), like the Road to the Sun's
##     guests, so the stage plays the same before and after those stages merge.
## Deterministic: the seeded global RNG only (the guests' roll, the spawn
## points). Stats: pandemonium_guest_squads, pandemonium_guests_spawned.
class_name PandemoniumDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (PandemoniumStage.PANDEMONIUM).
var config: Dictionary = {}
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Game time of the next guest squad.
var _next_guest: float = INF
## Guest squads sent so far (their size grows with it).
var _guest_squads: int = 0


func _ready() -> void:
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()


## Runs a Pandemonium timeline event (EnemyDirector forwards "seraph_general").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"seraph_general":
			_send_general(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the miniboss from the spawn ring with his escort around him.
func _send_general(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("seraph_general")


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
	game.stat_add("pandemonium_guest_squads", 1.0)
	game.stat_add("pandemonium_guests_spawned", float(n))


## HUD objective while the General fights ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is SeraphGeneralKit:
		return "The Fallen Seraph General: step out of his cleave and off his feathers"
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "guests: %s, squads %d, spawned %d | objective ash %d" % [
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("pandemonium_guest_squads", 0.0)),
		int(st.get("pandemonium_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
