## SunRoadDirector — the stage mechanics of THE ROAD TO THE SUN (Stage 15, the
## Act V finale; GDD §15.0 "The Road to the Sun (Act V phase 2)"; owner-approved
## proposal docs/act5/PROPOSAL.md "Stage 15"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "sun_road" config
## (SunRoadStage.SUN_ROAD; null elsewhere). The four zones are MarchDirector's
## (the clock is authoritative: the Torii Road, the Sacred Forest, the Shrine
## Steps, the High Plain of Heaven); the Sun's Course, the Draw and From the
## Shadows are the Shogunate's shared rules (Game.shogunate). This director runs:
##   * THE KIRIN (the "kirin" timeline event): the miniboss steps out of the
##     light at the spawn ring with its escort (KirinKit registers it for the
##     HUD bar; ChestManager drops its chest).
##   * GUEST SQUADS: the other Act V stages' kinds (the Burning Province's and
##     Castle Kurogane's, built in parallel) join small squads on a timer when
##     this build knows them (EnemyDirector.is_known_kind(); candidate ids per
##     kind), like the Asphodel Underworld's guests, so the stage plays the
##     same before and after those stages merge. A night kind among them comes
##     only at night (SunCourse.filter_groups(), the one timeline helper).
## Deterministic: the seeded global RNG only (the guests' roll, the spawn
## points). Stats: sun_road_guest_squads, sun_road_guests_spawned,
## kirin_spawned (KirinKit).
class_name SunRoadDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (SunRoadStage.SUN_ROAD).
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


## Runs a Road to the Sun timeline event (EnemyDirector forwards "kirin").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"kirin":
			_send_kirin(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the miniboss from the spawn ring with its escort around it.
func _send_kirin(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	var escort: Array = ev.get("escort", [])
	if game.shogunate != null:
		escort = game.shogunate.sun.filter_groups(escort)
	for grp: Dictionary in escort:
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("kirin")


## Sends one guest squad from the spawn ring (one weighted kind, the soft cap
## respected like any continuous source; a night kind only at night).
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
	var groups: Array = [{"kind": kind, "count": n, "elite": false}]
	if game.shogunate != null:
		groups = game.shogunate.sun.filter_groups(groups)  # A night guest only at night.
	if groups.is_empty():
		return
	game.enemies.spawn_formation("arc", groups)
	game.stat_add("sun_road_guest_squads", 1.0)
	game.stat_add("sun_road_guests_spawned", float(n))


## HUD objective while the Kirin hunts ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is KirinKit:
		return "The Kirin: step out of its golden lane and off its rays"
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "guests: %s, squads %d, spawned %d | objective ash %d" % [
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("sun_road_guest_squads", 0.0)),
		int(st.get("sun_road_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
