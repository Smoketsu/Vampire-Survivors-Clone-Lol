## GreatPlainDirector — the stage systems of THE GREAT PLAIN (temporary Act XIV
## stage 41, final stage 41; GDD §15.0 "The Great Plain (Act XIV phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Stage
## B: The Great Plain"), owned and stepped by EnemyDirector on a stage whose
## STAGE has a "great_plain" config (GreatPlainStage.PLAIN;
## `game.enemies.great_plain`, null elsewhere). The zones' floors and
## obstacles are MarchDirector's (the Canyon's walls are its obstacles: the
## narrow lanes, every wall SHELTER as every obstacle); Packs, Herds,
## Scavengers and the Stampede of Ash the shared PrimevalRules'. Here:
##   * THE WATERING HOLE (the stage mechanic: "a central lake gathers herds;
##     fighting near it triggers stampedes"): from lake_first s a lake of
##     lake_radius px lies lake_dist px ahead of the necromancer (a new one
##     ahead when he is lake_far px from it). It GATHERS THE HERDS: Herds
##     .gather (the one read in Herds.steer()) draws the grazing beasts within
##     gather_reach px to it, and every herd_every s a herd of the Herds'
##     size comes on at its shore while the Herds' cap allows. FIGHTS START
##     STAMPEDES: every fight_every s, while a standing necromancer is within
##     fight_radius px of the lake and at least fight_min enemies fight within
##     fight_radius px of it, every grazing, rested herd within fight_radius px
##     of the lake stampedes away from him (Herds.launch(), the one stampede
##     start).
##   * THE CANYON (the zone with "canyon": true): its walls make the lanes
##     narrow, and a stampede's front there is canyon_width px wide (the
##     Herds' "width", put back after the zone).
##   * MOTHER CLUBTAIL ("herd_mother" event): the stage miniboss comes in
##     mother_dist px ahead of the necromancer with the herd she guards
##     (Herds.spawn_herd(); ClubtailKit.link_herd()); tracked for the
##     objective and the report.
##   * NOTHING TAKEN (the stage's achievement: "finish the Great Plain without
##     losing a crystal pile to a Skyraider"): when the countdown reaches 0:00
##     with no pile flown to a nest (the run stat scav_nests 0) the run stat
##     NOTHING_TAKEN_STAT is set (MetaProgress counts it).
## Deterministic: game time and the seeded global RNG only. Stats:
## lake_placed, lake_herds, lake_fights, lake_stampedes, canyon_stampedes,
## mother_spawned, mother_killed.
class_name GreatPlainDirector
extends Node2D

## Run stat set (1) by a Great Plain run that reached 0:00 with no crystal pile
## lost to a Skyraider (Nothing Taken; MetaProgress).
const NOTHING_TAKEN_STAT: String = "great_plain_nothing_taken"

## Owning run.
var game: Game
## The stage's config (GreatPlainStage.PLAIN).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The watering hole's centre (world px; Vector2.INF = none yet).
var lake: Vector2 = Vector2.INF
## "m:ss" Mother Clubtail fell ("" while alive / never spawned).
var mother_time: String = ""
## "EARNED" / "lost" / "" (open): Nothing Taken, settled at 0:00.
var nothing_taken: String = ""
## Game time (s) of the next fight check.
var _next_fight: float = 0.0
## Game time (s) of the next lake herd.
var _next_herd: float = 0.0
## True while the Canyon's narrow front is in force.
var _canyon: bool = false
## The Herds' front width before the Canyon narrowed it (px).
var _width: float = 0.0
## Index of the zone seen last (-1 = none).
var _zone: int = -1
## Mother Clubtail once spawned (null before / after; generation-checked).
var _mother: Enemy = null
## Generation of `_mother` when she spawned.
var _mother_gen: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


func _ready() -> void:
	z_index = -9  # Just over the floor (Ground is -10), under every body.
	_draws = DisplayServer.get_name() != "headless"


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	_sync_zone()
	if game.primeval != null and now >= float(config["lake_first"]):
		_step_lake(now)
	if _mother != null and not (_mother.active and _mother.generation == _mother_gen):
		_mother = null
		game.stat_add("mother_killed", 1.0)
		mother_time = _clock()
		_log("mother_down")
	if nothing_taken == "" and game.countdown_finished():
		nothing_taken = "EARNED" if int(game.stats.get("scav_nests", 0.0)) == 0 else "lost"
		if nothing_taken == "EARNED":
			game.stats[NOTHING_TAKEN_STAT] = 1.0
			game.enemies.show_banner(String(config.get("nothing_taken_banner", "NOTHING TAKEN")))
		_log("nothing_taken " + nothing_taken)


# =====================================================================================
# The Watering Hole
# =====================================================================================

## The lake's clock (see the header).
func _step_lake(now: float) -> void:
	var hs := game.primeval.herds
	var pl := game.player
	if lake == Vector2.INF or pl.position.distance_to(lake) > float(config["lake_far"]):
		var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.from_angle(randf() * TAU)
		lake = pl.position + ahead * float(config["lake_dist"])
		hs.gather = lake
		hs.gather_radius = float(config["gather_radius"])
		hs.gather_reach = float(config["gather_reach"])
		game.stat_add("lake_placed", 1.0)
		_log("lake")
		if _draws:
			queue_redraw()
	if now >= _next_herd:
		_next_herd = now + float(config["herd_every"])
		if hs.alive + int(hs.cfg["size"]) <= int(hs.cfg["cap"]):
			var at := lake + Vector2.from_angle(randf() * TAU) * (float(config["lake_radius"]) + 60.0)
			if not hs.spawn_herd(at, int(hs.cfg["size"]), hs.cfg["kinds"]).members.is_empty():
				game.stat_add("lake_herds", 1.0)
	if now >= _next_fight:
		_next_fight = now + float(config["fight_every"])
		_fight_check(hs)


## FIGHTS START STAMPEDES (see the header).
func _fight_check(hs: Herds) -> void:
	var r := float(config["fight_radius"])
	var pl := game.nearest_player(lake)
	if pl == null or pl.dead or pl.position.distance_to(lake) > r:
		return
	var n := 0
	for e in game.enemies.active:
		if e.active and not (e.kit is HerdBeastKit) and not e.civilian and e.position.distance_to(lake) <= r:
			n += 1
	if n < int(config["fight_min"]):
		return
	game.stat_add("lake_fights", 1.0)
	for h in hs.herds:
		if h.state != Herds.GRAZE or game.elapsed < h.ready_at:
			continue
		var c := hs.centre(h)
		if c.distance_to(lake) > r:
			continue
		hs.launch(h, c * 2.0 - pl.position)  # Owner answer: away from the fight that frightened it.
		game.stat_add("lake_stampedes", 1.0)
		if _canyon:
			game.stat_add("canyon_stampedes", 1.0)


## Follows MarchDirector's zone: the Canyon narrows the stampedes' front.
func _sync_zone() -> void:
	var zi := game.enemies.march.zone_index if game.enemies.march != null else 0
	if zi == _zone:
		return
	_zone = zi
	var zones: Array = game.stage_def.get("zones", [])
	var canyon := zi < zones.size() and bool((zones[zi] as Dictionary).get("canyon", false))
	if game.primeval == null or canyon == _canyon:
		return
	var hs := game.primeval.herds
	if canyon:
		_width = float(hs.cfg["width"])
		hs.cfg["width"] = float(config["canyon_width"])
	else:
		hs.cfg["width"] = _width
	_canyon = canyon
	_log("canyon" if canyon else "canyon_end")


# =====================================================================================
# Mother Clubtail
# =====================================================================================

## Runs a Great Plain timeline event (EnemyDirector forwards the "herd_mother"
## type; keys in GreatPlainStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "herd_mother":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.from_angle(randf() * TAU)
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("mother_dist", 260.0)), 24.0)
	var e := game.enemies.spawn_at(String(ev.get("kind", GreatPlainEnemyData.MOTHER)), at, bool(ev.get("elite", false)))
	if e != null:
		_mother = e
		_mother_gen = e.generation
		game.stat_add("mother_spawned", 1.0)
		var kinds: Array = ev.get("herd", [])
		if not kinds.is_empty():
			var h := game.primeval_rules().herds.spawn_herd(at + ahead * 110.0, kinds.size(), kinds)
			if not h.members.is_empty() and e.kit is ClubtailKit:
				(e.kit as ClubtailKit).link_herd(h)
	game.shake(6.0)
	Sfx.play("boss_impact", at, 0.5)
	var k := 0
	for grp: Dictionary in ev.get("escort", []):
		for j in int(grp.get("count", 0)):
			game.enemies.spawn_at(String(grp["kind"]), game.arena.free_point(at + Vector2.from_angle(float(k) * 0.52) * 60.0, 8.0), false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("herd_mother")


## The HUD objective while Mother Clubtail stands ("" otherwise).
func objective_override() -> String:
	if _mother != null:
		return String(config.get("mother_objective", ""))
	return ""


# =====================================================================================
# Drawing and report
# =====================================================================================

## The watering hole (disc textures only; redrawn only when it moves).
func _draw() -> void:
	if lake == Vector2.INF:
		return
	var r := float(config["lake_radius"])
	SpriteBank.draw_disc(self, lake, r + 14.0, Color(Palette.PRIMEVAL_OCHRE_DARK, 0.55))  # The trampled mud shore.
	SpriteBank.draw_disc(self, lake, r, Color(0.16, 0.27, 0.30))  # The water.
	SpriteBank.draw_disc(self, lake + Vector2(-r * 0.3, -r * 0.25), r * 0.4, Color(0.30, 0.45, 0.46, 0.6))  # Its sheen.
	for i in 6:
		var b := lake + Vector2.from_angle(float(i) * 1.05) * (r + 6.0)
		SpriteBank.draw_disc(self, b, 4.0, Color(Palette.PRIMEVAL_BONE, 0.5))  # Bleached bones at the shore.


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "watering hole: placed %d, herds %d, fights %d -> stampedes %d (in the canyon %d) | mother clubtail spawned %d, killed %d%s (guarded hits %d) | clubtail sweeps %d (summons %d, you %d) | charges %d (gored %d, you %d; stuck %d) | nothing taken %s (piles lost %d) | events: %s" % [
		int(st.get("lake_placed", 0.0)), int(st.get("lake_herds", 0.0)), int(st.get("lake_fights", 0.0)),
		int(st.get("lake_stampedes", 0.0)), int(st.get("canyon_stampedes", 0.0)),
		int(st.get("mother_spawned", 0.0)), int(st.get("mother_killed", 0.0)), (" at " + mother_time) if mother_time != "" else "",
		int(st.get("mother_warded_hits", 0.0)),
		int(st.get("club_sweeps", 0.0)), int(st.get("club_sweep_hits", 0.0)), int(st.get("club_sweep_on_you", 0.0)),
		int(st.get("horn_charges", 0.0)), int(st.get("horn_charge_hits", 0.0)), int(st.get("horn_charge_on_you", 0.0)), int(st.get("horn_stuck", 0.0)),
		nothing_taken if nothing_taken != "" else "open", int(st.get("scav_nests", 0.0)), ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
