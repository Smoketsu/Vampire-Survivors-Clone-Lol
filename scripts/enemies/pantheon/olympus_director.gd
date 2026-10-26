## OlympusDirector — the stage systems of Mount Olympus, the Pantheon Trial
## (Stage 11; Act IV, GDD §15.0 "Mount Olympus (Act IV phase 2)" and "The
## Pantheon Trial"; owner-approved proposal: "The stage climbs the mountain
## under Zeus's storm, and each zone has its god"), owned and stepped by
## EnemyDirector on a stage whose STAGE has an "olympus" config
## (OlympusStage.OLYMPUS; null elsewhere). The zones are MarchDirector's, the
## wrath (Zeus's lightning) is DivineWrath's, Zeus himself is BossZeus. Data:
## OlympusStage (OLYMPUS, the "god" timeline events) and OlympusEnemyData.
##   * THE TRIAL ("god" events): Ares at 14:00 left, Artemis at 9:30, Poseidon
##     at 6:00 (owner-approved), each spawned on the spawn ring (Artemis at a
##     moonlit grove) through the normal spawn path; their kits (GodKit) take
##     the HUD's one miniboss bar and pay an XP burst, ChestManager drops the
##     miniboss chest. When the god on the bar falls while an older one still
##     lives, the bar goes back to that one (the newest living god). The trial
##     is CLEARED when all three gods and Zeus have fallen in one run (stat
##     olympus_trial_cleared; banner).
##   * THE GROVES (Artemis's): at her event grove_count moonlit groves are laid
##     around the necromancer, grove_min..grove_max px out, evenly spaced with a
##     seeded turn; grove_point() picks her next one (the grove farthest from
##     her among those within grove_reach px of a standing necromancer; when
##     none is, the groves are laid again around him). Drawn as pale moonlit
##     rings with a silver crescent; nothing collides.
## Determinism: only the seeded global RNG (the groves' turn); bodies are
## polled with generation checks. Stats: olympus_gods_spawned,
## olympus_gods_killed, olympus_god_kills_<kind> (GodKit), olympus_groves_laid,
## olympus_trial_cleared.
class_name OlympusDirector
extends Node2D

## One god of the trial.
class God:
	extends RefCounted
	## The god's kind id (OlympusEnemyData.GODS).
	var kind: String = ""
	## Its Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it arrived (stale / death guard).
	var gen: int = 0
	## "m:ss" it arrived.
	var arrived: String = ""
	## "m:ss" it fell ("" while alive or when it never fell).
	var fell: String = ""
	## True while it lives.
	var alive: bool = true


## Owning run.
var game: Game
## The stage's Olympus config (OlympusStage.OLYMPUS).
var config: Dictionary = {}
## The trial's gods, in their order of arrival.
var gods: Array[God] = []
## The moonlit groves (world px; Artemis's teleport points).
var groves: Array[Vector2] = []
## Times the groves were laid (stat and summary).
var groves_laid: int = 0
## True once the trial was cleared (three gods and Zeus fell this run).
var trial_cleared: bool = false
## Log of Olympus events, "m:ss name" (autotest summary).
var fired: Array[String] = []


func _ready() -> void:
	z_index = -1  # The groves lie on the ground, under the bodies.


## Per-tick update (EnemyDirector, after the MarchDirector): the fallen gods,
## the miniboss bar, the trial's end.
func step(_delta: float) -> void:
	for gd in gods:
		if gd.alive and (not gd.enemy.active or gd.enemy.generation != gd.gen):
			gd.alive = false
			if float(game.stats.get("olympus_god_kills_" + gd.kind, 0.0)) > 0.0:
				gd.fell = _clock()
				game.stat_add("olympus_gods_killed", 1.0)
				_log(gd.kind + "_slain")
			else:
				_log(gd.kind + "_gone")
			_hand_back_bar()
	if not trial_cleared and game.enemies.boss != null and not game.enemies.boss.active and _gods_slain() >= OlympusEnemyData.GODS.size():
		trial_cleared = true
		game.stat_add("olympus_trial_cleared", 1.0)
		game.enemies.show_banner("THE PANTHEON TRIAL IS CLEARED: Olympus has no gods left!")
		_log("trial_cleared")


## The miniboss bar goes back to the newest god still alive when the bar's
## god fell (set directly, so co-op's one-time HP scaling is not applied again).
func _hand_back_bar() -> void:
	if game.enemies.miniboss_alive() != null:
		return
	var i := gods.size() - 1
	while i >= 0:
		var gd := gods[i]
		if gd.alive:
			game.enemies.miniboss = gd.enemy
			game.enemies.miniboss_gen = gd.gen
			return
		i -= 1


## Gods of the trial slain this run (kills, not departures).
func _gods_slain() -> int:
	var n := 0
	for k: String in OlympusEnemyData.GODS:
		if float(game.stats.get("olympus_god_kills_" + k, 0.0)) > 0.0:
			n += 1
	return n


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs an Olympus timeline event (EnemyDirector forwards the "god" type;
## keys in OlympusStage.EVENTS): the god `kind` arrives, at a grove when
## `groves` is true (laid first), else on the spawn ring.
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "god":
		return
	var kind := String(ev["kind"])
	var at := game.enemies.ring_point(randf() * TAU)
	if bool(ev.get("groves", false)):
		_lay_groves(game.player.position)
		at = grove_point(game.player.position)
	var e := game.enemies.spawn_at(kind, game.arena.free_point(at, 20.0), false)
	var gd := God.new()
	gd.kind = kind
	gd.enemy = e
	gd.gen = e.generation
	gd.arrived = _clock()
	gods.append(gd)
	game.stat_add("olympus_gods_spawned", 1.0)
	game.shake(6.0)
	game.effects.impact(e.position, 70.0, Palette.GOLD)
	_log(kind + "_arrived")
	queue_redraw()


# =====================================================================================
# The groves (Artemis)
# =====================================================================================

## Lays grove_count groves around world point `p` (evenly spaced, a seeded turn).
func _lay_groves(p: Vector2) -> void:
	groves.clear()
	var n := int(config["grove_count"])
	var turn := randf() * TAU  # The ring's seeded turn (rad).
	for i in n:
		var r := lerpf(float(config["grove_min"]), float(config["grove_max"]), float(i % 2))  # Alternating near / far (px).
		groves.append(game.arena.free_point(p + Vector2.from_angle(turn + TAU * float(i) / float(n)) * r, 30.0))
	groves_laid += 1
	game.stat_add("olympus_groves_laid", 1.0)
	queue_redraw()


## Artemis's next grove from world point `from`: the grove farthest from it
## among those within grove_reach px of a standing necromancer (the groves are
## laid again around him when none is). Vector2.INF when there are no groves.
func grove_point(from: Vector2) -> Vector2:
	var p := game.player.position if game.coop == null else game.coop.nearest_player(from).position
	var reach := float(config["grove_reach"])
	var near := false  # Any grove still within reach of him.
	for g in groves:
		if g.distance_to(p) <= reach:
			near = true
			break
	if not near:
		_lay_groves(p)
	var best := Vector2.INF
	var best_d := -1.0
	for g in groves:
		if g.distance_to(p) > reach:
			continue
		var dist := g.distance_to(from)
		if dist > best_d:
			best_d = dist
			best = g
	return best


# =====================================================================================
# Queries (enemy director, HUD, report)
# =====================================================================================

## HUD objective for the live trial ("" if none): the newest living god.
func objective_override() -> String:
	var i := gods.size() - 1
	while i >= 0:
		var gd := gods[i]
		if gd.alive:
			return String((config["objectives"] as Dictionary).get(gd.kind, ""))
		i -= 1
	return ""


## One-line autotest summary: each god's arrival and fall, the groves, the trial.
func summary_line() -> String:
	var parts := PackedStringArray()
	for gd in gods:
		parts.append("%s arrived %s, %s" % [gd.kind, gd.arrived, ("slain at " + gd.fell) if gd.fell != "" else ("alive" if gd.alive else "gone")])
	return "%s | groves laid %d | gods slain %d of %d | trial %s" % [
		" | ".join(parts) if not parts.is_empty() else "no god arrived", groves_laid, _gods_slain(), OlympusEnemyData.GODS.size(),
		"CLEARED" if trial_cleared else "not cleared"]


## Records an Olympus event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Drawing (world space; visual only)
# =====================================================================================

## The moonlit groves: a pale ring of moonlight on the ground and a silver
## crescent at the centre (drawn while Artemis's groves exist).
func _draw() -> void:
	for g in groves:
		draw_circle(g, 34.0, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.06))
		draw_arc(g, 34.0, 0.0, TAU, 32, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.35), 2.0)
		draw_arc(g, 26.0, 0.0, TAU, 28, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.18), 1.0)
		draw_circle(g + Vector2(-2, 0), 7.0, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.55))
		draw_circle(g + Vector2(2, -2), 6.0, Color(0.05, 0.06, 0.08, 0.9))  # The crescent's dark bite.
