## TwoTruthsDirector — the mechanics of THE HALL OF TWO TRUTHS (temporary Act XII,
## the Necropolis Dynasty's finale; GDD §15.0 "The Hall of Two Truths
## (Necropolis Dynasty phase 2)"), created by EnemyDirector when the STAGE has a
## "two_truths" dictionary (TwoTruthsStage.TWO_TRUTHS) and stepped after the
## spawns. It owns:
##   * THE SCALES (`scales`, TruthScales; its HUD widget ScalesBar): the
##     Balance every Rebirth and every raise tips, its favour, the Weighing;
##   * THE DEVOURER'S WHELP (the "devourers_whelp" event): the miniboss from
##     the spawn ring, with its escort round it;
##   * THE CROCODILE WARDENS' RISE (the "crocodile_rise" event): `count`
##     wardens climb out of the sand ring_min..ring_max px from a standing
##     necromancer (the seeded gameplay RNG), each opening its own quicksand
##     (CrocodileWardenKit, Quicksand.add_patch());
##   * THE EMPTY THRONE (set_throne() / clear_throne(), from BossOsiris): while
##     Ammit holds the throne, Osiris is drawn watching from where he sat
##     (faded; a drawing only: nothing there can be hit), and he fades out
##     when she falls.
## Determinism: the seeded gameplay RNG (the rise points) and game time.
## Stats: two_truths_* and the event log (the report).
class_name TwoTruthsDirector
extends Node2D

## Owning run.
var game: Game
## Its config (TwoTruthsStage.TWO_TRUTHS).
var config: Dictionary = {}
## The Scales.
var scales: TruthScales
## Events fired, "m:ss name" (the report).
var fired: PackedStringArray = PackedStringArray()
## The HUD's Balance bar (null until made; never without a HUD).
var _bar: ScalesBar = null
## Where Osiris watches from while Ammit holds the throne (INF = nowhere).
var _throne_at: Vector2 = Vector2.INF
## Game time (s) the throne emptied (Osiris fading; INF = not fading).
var _throne_gone_at: float = INF
## Seconds the Weighing has left (< 0 = no Weighing; set by BossOsiris).
var weigh_left: float = -1.0


func _ready() -> void:
	name = "TwoTruthsDirector"
	z_index = -1  # Over the floor and the obstacles, under the bodies.
	scales = TruthScales.new(game, config["scales"])


## Per tick (EnemyDirector.step()): the Scales and their bar; the fading throne.
func step(delta: float) -> void:
	scales.step(delta)
	if game.hud != null:
		if _bar == null:
			_bar = ScalesBar.new()
			_bar.setup(game, scales)
			game.hud.add_child(_bar)
		_bar.refresh(weigh_left)
	if _throne_at != Vector2.INF:
		queue_redraw()


## Runs a stage event of this director's ("devourers_whelp", "crocodile_rise").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"devourers_whelp":
			_send_whelp(ev)
		"crocodile_rise":
			_raise_crocs(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the miniboss from the spawn ring with its escort around it.
func _send_whelp(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("devourers_whelp")


## `count` Crocodile Wardens climb out of the sand near a standing necromancer.
func _raise_crocs(ev: Dictionary) -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var cfg: Dictionary = config["crocs"]
	var r := float((DynastyEnemyData.ENEMIES[DynastyEnemyData.CROCODILE_WARDEN] as Dictionary)["radius"])
	var n := 0
	for _k in int(ev["count"]):
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			game.stat_add("two_truths_crocs_refused", 1.0)
			break
		var pl: Necromancer = standing[randi() % standing.size()]
		var at := game.arena.free_point(pl.position + Vector2.from_angle(randf() * TAU) * randf_range(float(cfg["ring_min"]), float(cfg["ring_max"])), r)
		if game.enemies.spawn_at(DynastyEnemyData.CROCODILE_WARDEN, at, false) != null:
			n += 1
	game.stat_add("two_truths_crocs_risen", float(n))
	_log("crocodile_rise x%d" % n)


## BossOsiris: Ammit holds the throne; Osiris watches from `at`.
func set_throne(at: Vector2) -> void:
	_throne_at = at
	_throne_gone_at = INF
	queue_redraw()


## BossOsiris: Ammit fell; the throne empties (Osiris fades out).
func clear_throne() -> void:
	if _throne_at != Vector2.INF and _throne_gone_at == INF:
		_throne_gone_at = game.elapsed


## HUD objective while the Whelp hunts or the heart is weighed ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is DevourersWhelpKit:
		return "The Devourer's Whelp eats the Names of the dead: raise or smash them before it reaches them"
	if weigh_left >= 0.0:
		return "THE WEIGHING: raise the dead to tip the Scales your way before your heart is judged"
	return ""


## Osiris watching from the empty throne (faded), fading out once she fell.
func _draw() -> void:
	if _throne_at == Vector2.INF:
		return
	var a := 0.45  # His ghostly watch.
	if _throne_gone_at != INF:
		a *= clampf(1.0 - (game.elapsed - _throne_gone_at) / 2.0, 0.0, 1.0)
		if a <= 0.0:
			_throne_at = Vector2.INF
			return
	if not SpriteBank.draw(self, OsirisData.SPRITE, _throne_at, false, Color(0.8, 0.95, 0.85, a)):
		draw_texture_rect(SpriteBank.disc(), Rect2(_throne_at - Vector2(18, 30), Vector2(36, 60)), false, Color(Palette.DYN_PAPYRUS, a))


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var s := scales
	return "scales: balance %+.0f (peaks %+.0f / %+.0f), favour turned dynasty %d / ma'at %d, time in favour ma'at %ds / none %ds / dynasty %ds, moved by returns %+.0f, raises %+.0f, steals %+.0f, smashes %+.0f | crocs risen %d (refused %d)" % [
		s.balance, s.peak_necro, s.peak_dynasty, s.tipped_dynasty, s.tipped_maat,
		int(s.favour_time[0]), int(s.favour_time[1]), int(s.favour_time[2]),
		s.moved[0], s.moved[1], s.moved[2], s.moved[3],
		int(game.stats.get("two_truths_crocs_risen", 0.0)), int(game.stats.get("two_truths_crocs_refused", 0.0))]


## Logs an event for the report ("m:ss name").
func _log(event_name: String) -> void:
	fired.append("%s %s" % [EmpireReport._clock(game.elapsed), event_name])
