## LastDayDirector — the stage systems of THE LAST DAY (temporary Act XIV stage
## 42, final stage 42, the Age of Titans' finale; GDD §15.0 "The Last Day (Act
## XIV phase 2)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 2, "Stage C: The Last Day"), owned and stepped by EnemyDirector on a
## stage whose STAGE has a "last_day" config (LastDayStage.LAST_DAY;
## `game.enemies.last_day`, null elsewhere). The zones' floors and obstacles
## are MarchDirector's; Packs, Herds, Scavengers and the Extinction (the
## Reckoning) the shared PrimevalRules'. Here:
##   * FIRE FROM THE SKY (the stage mechanic: "small meteorites strike
##     telegraphed circles every 12 s, hurting both armies, with the interval
##     shrinking each zone"): from meteor_first s, every meteor_every[zone] s,
##     meteor_count[zone] circles per standing necromancer within
##     meteor_spread px of him (the seeded gameplay RNG); each lands after
##     meteor_warn s and hits every body inside meteor_radius px: summons
##     meteor_summon (x the time scaling x Thick Marrow), the necromancer
##     meteor_player, enemies meteor_enemy_share of their max HP (bosses,
##     minibosses, structures and objectives spared). Stops at 0:00 (the
##     Extinction falls then).
##   * THE GROWING METEOR ("the HUD clock shows the meteor growing"): a
##     MeteorDial beside the countdown (drawing only).
##   * THUNDERWING, THE SKY KING ("sky_king" event): the stage miniboss swoops
##     in thunder_dist px ahead of the necromancer with an `escort`; tracked
##     for the objective and the report.
## Deterministic: game time and the seeded global RNG only. Stats:
## meteorites, meteorite_summon_hits, meteorite_player_hits,
## meteorite_enemy_hits, thunderwing_spawned.
class_name LastDayDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (LastDayStage.LAST_DAY).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Live meteorites: [landing point (Vector2), game s it lands] each; a landed
## one gets a third entry and stays drawn meteor_show s.
var meteors: Array = []
## "m:ss" Thunderwing fell ("" while alive / never spawned).
var thunder_time: String = ""
## Game time (s) of the next meteorites.
var _next_meteor: float = INF
## Thunderwing once spawned (null before / after; generation-checked).
var _thunder: Enemy = null
## Generation of `_thunder` when he spawned.
var _thunder_gen: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## True while the last redraw showed a meteorite (one more redraw clears it).
var _drawn_any: bool = false
## The HUD's growing meteor (null before the first tick and headless).
var _dial: MeteorDial = null


func _ready() -> void:
	z_index = -9  # Just over the floor (Ground is -10), under every body.
	_draws = DisplayServer.get_name() != "headless"
	_next_meteor = float(config["meteor_first"])


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	if _draws and game.hud != null:
		if _dial == null:
			_dial = MeteorDial.new()
			_dial.game = game
			_dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
			game.hud.add_child(_dial)
		_dial.refresh()
	if now >= _next_meteor and not game.countdown_finished():
		var zi := game.enemies.march.zone_index if game.enemies.march != null else 0
		var every: Array = config["meteor_every"]
		_next_meteor = now + float(every[mini(zi, every.size() - 1)])
		_throw(zi)
	var i := meteors.size() - 1
	while i >= 0:
		var m: Array = meteors[i]
		if now >= float(m[1]) and m.size() == 2:
			_land(m[0])
			m.append(true)
		if now >= float(m[1]) + float(config["meteor_show"]):
			meteors.remove_at(i)
		i -= 1
	if _thunder != null and not (_thunder.active and _thunder.generation == _thunder_gen):
		_thunder = null
		thunder_time = _clock()
		_log("thunderwing_down")
	if _draws:
		var shows := not meteors.is_empty()
		if shows or _drawn_any:
			_drawn_any = shows
			queue_redraw()


# =====================================================================================
# Fire from the Sky
# =====================================================================================

## The circles of zone `zi`'s meteorites round each standing necromancer.
func _throw(zi: int) -> void:
	var counts: Array = config["meteor_count"]
	var spread := float(config["meteor_spread"])
	for pl in game.all_players:
		if pl.dead:
			continue
		for _k in int(counts[mini(zi, counts.size() - 1)]):
			var at := pl.position + Vector2.from_angle(randf() * TAU) * spread * sqrt(randf())
			meteors.append([at, game.elapsed + float(config["meteor_warn"])])
	if game.primeval != null:
		game.primeval.play_sound("meteorite_warn", game.player.position, 0.8)


## A meteorite strikes at `at` (see the header).
func _land(at: Vector2) -> void:
	game.stat_add("meteorites", 1.0)
	var r := float(config["meteor_radius"])
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var marrow := game.primeval.thick_marrow_mult() if game.primeval != null else 1.0  # Thick Marrow.
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and not u.airborne and u.position.distance_to(at) <= r + u.radius:
				game.combat.damage_unit(u, float(config["meteor_summon"]) * ts * marrow, LastDayStage.METEOR_SOURCE)
				game.stat_add("meteorite_summon_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(config["meteor_player"]) * ts, LastDayStage.METEOR_SOURCE, pl)
			game.stat_add("meteorite_player_hits", 1.0)
	for e in game.enemies.active:
		if e.active and not e.is_boss and not e.is_miniboss and not e.is_structure and not e.is_objective \
				and e.position.distance_to(at) <= r + e.radius:
			game.combat.damage_enemy(e, e.max_hp * float(config["meteor_enemy_share"]), LastDayStage.METEOR_SOURCE)
			game.stat_add("meteorite_enemy_hits", 1.0)
	if _draws:
		game.effects.impact(at, r, Palette.PRIMEVAL_LAVA)
	if game.primeval != null:
		game.primeval.play_sound("meteorite_land", at, 0.2)


## The autotest autopilot's push out of every falling meteorite's circle at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var r := float(config["meteor_radius"]) + 24.0
	for m: Array in meteors:
		if m.size() > 2:
			continue
		var rel := p - (m[0] as Vector2)
		if rel.length() < r:
			push += (rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT) * 1.5
	return push


# =====================================================================================
# Thunderwing, the Sky King
# =====================================================================================

## Runs a Last Day timeline event (EnemyDirector forwards the "sky_king" type;
## keys in LastDayStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "sky_king":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.from_angle(randf() * TAU)
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("thunder_dist", 320.0)), 24.0)
	var e := game.enemies.spawn_at(String(ev.get("kind", LastDayEnemyData.THUNDERWING)), at, bool(ev.get("elite", false)))
	if e != null:
		_thunder = e
		_thunder_gen = e.generation
		game.stat_add("thunderwing_spawned", 1.0)
	game.shake(6.0)
	Sfx.play("boss_impact", at, 0.5)
	var k := 0
	for grp: Dictionary in ev.get("escort", []):
		for j in int(grp.get("count", 0)):
			game.enemies.spawn_at(String(grp["kind"]), game.arena.free_point(at + Vector2.from_angle(float(k) * 0.9) * 70.0, 8.0), false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("sky_king")


## The HUD objective while Thunderwing flies ("" otherwise).
func objective_override() -> String:
	if _thunder != null:
		return String(config.get("thunder_objective", ""))
	return ""


# =====================================================================================
# Drawing and report
# =====================================================================================

## Every meteorite's circle (disc textures only; redrawn only while one shows).
func _draw() -> void:
	var r := float(config["meteor_radius"])
	var warn := maxf(0.01, float(config["meteor_warn"]))
	for m: Array in meteors:
		var at: Vector2 = m[0]
		if m.size() > 2:
			SpriteBank.draw_disc(self, at, r, Color(Palette.PRIMEVAL_LAVA, 0.5))
			continue
		var k := clampf(1.0 - (float(m[1]) - game.elapsed) / warn, 0.0, 1.0)  # 0 -> 1 as it falls.
		SpriteBank.draw_disc(self, at, r, Color(Palette.PRIMEVAL_LAVA, 0.14))
		SpriteBank.draw_disc(self, at, r * k, Color(Palette.PRIMEVAL_STREAK, 0.28))


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "fire from the sky: meteorites %d (hits on summons %d, on you %d, on enemies %d) | thunderwing spawned %d, killed %d%s (gusts %d, pushed %d, landings %d) | stormwings: gusts %d, pushed %d, landings %d | tyrants: swallows %d (cut out %d), roars %d (stunned %d) | events: %s" % [
		int(st.get("meteorites", 0.0)), int(st.get("meteorite_summon_hits", 0.0)), int(st.get("meteorite_player_hits", 0.0)), int(st.get("meteorite_enemy_hits", 0.0)),
		int(st.get("thunderwing_spawned", 0.0)), int(st.get("thunderwing_kills", 0.0)), (" at " + thunder_time) if thunder_time != "" else "",
		int(st.get("gusts_thunderwing", 0.0)), int(st.get("gust_pushed_thunderwing", 0.0)), int(st.get("landings_thunderwing", 0.0)),
		int(st.get("gusts_stormwing", 0.0)), int(st.get("gust_pushed_stormwing", 0.0)), int(st.get("landings_stormwing", 0.0)),
		int(st.get("tyrant_swallows", 0.0)), int(st.get("tyrant_cut_out", 0.0)), int(st.get("tyrant_roars", 0.0)), int(st.get("tyrant_roar_stuns", 0.0)),
		", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
