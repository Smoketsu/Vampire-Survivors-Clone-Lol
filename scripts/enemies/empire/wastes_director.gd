## WastesDirector — the stage systems of the Scrap Wastes (Stage 7; Act III,
## GDD §15.0 "The Scrap Wastes (Act III phase 2)"; owner-approved proposal
## "Stage 7: The Scrap Wastes"), owned and stepped by EnemyDirector on a stage
## whose STAGE has a "wastes" config (WastesStage.WASTES; null elsewhere). The
## zones are MarchDirector's. Data: WastesStage (WASTES, the "pylons" / "storm"
## / "trojan" timeline events) and WastesEnemyData (the pylon, the miniboss).
##   * Signal Pylons ("pylons" events): structures with a Soul Ash bounty. While
##     one stands, Empire shooters within pylon_radius of it fire from
##     pylon_boost times farther (owner-approved: 30%); destroyed, it pays an
##     XP burst and ash_per_pylon Soul Ash, and the ground it stood on becomes a
##     DEAD ZONE: shooters within dead_zone_radius of it fire from only
##     dead_zone_mult of their range for the rest of the run (owner-approved
##     "destroying one shrinks their range in that area for the rest of the
##     run").
##   * Scrap storms ("storm" events): a dust storm rolls through for
##     storm_duration s (owner-approved 20 s) and halves the sight of the
##     Empire's guns (storm_reach_mult 0.5): every shooter's reach is halved,
##     a window to close the distance. Own decision (owner rule "summons never
##     get act-only rules"): the storm acts on the enemies' sight and on what
##     the player sees (a dust veil drawn around the necromancer); the army's
##     own ranges are unchanged.
##   * The Trojan Horse ("trojan" event): the stage miniboss, spawned on the
##     spawn ring and tracked here (objective, kill time); its kit (TrojanKit)
##     registers it on the HUD's miniboss bar and pays its XP burst.
## THE REACH PATH: reach_mult_at(pos) is this stage's one reach modifier,
## registered with EmpireRules.add_reach_source() and read only through
## EmpireRules.reach_mult() by EmpireKit.refresh_reach() (every "ranged" Empire
## kind, 5 Hz): standing pylon boost x dead-zone cuts x the storm, clamped to
## reach_min. Structures are ordinary pooled Enemy nodes (is_structure,
## is_objective: never recycled), polled with generation checks; each placed
## pylon asks Arena.keep_clear(). Deterministic: only the seeded global RNG.
## Stats: wastes_pylons_raised, wastes_pylons_destroyed, objective_ash,
## wastes_storms, wastes_trojans_spawned, wastes_trojans_killed.
class_name WastesDirector
extends Node2D

## One standing Signal Pylon.
class Pylon:
	extends RefCounted
	## The pylon's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## Last known world position (its reach centre; the dead zone once it falls).
	var pos: Vector2 = Vector2.ZERO
	## The timeline event that raised it (rewards).
	var ev: Dictionary = {}


## The scrap storm's dust veil around the necromancer (drawn above the units,
## under the HUD). Visual only: it reads the director's storm state.
class StormVeil:
	extends Node2D
	## The owning director.
	var director: WastesDirector = null

	func _draw() -> void:
		if director != null:
			director.draw_veil(self)


## Owning run.
var game: Game
## The stage's Wastes config (WastesStage.WASTES).
var config: Dictionary = {}
## Standing Signal Pylons.
var pylons: Array[Pylon] = []
## Dead zones of the destroyed pylons: x, y = centre (world px), z = radius (px).
var dead_zones: Array[Vector3] = []
## Signal Pylons raised this run.
var pylons_raised: int = 0
## Signal Pylons destroyed this run.
var pylons_destroyed: int = 0
## "m:ss" of each destroyed pylon (summary).
var destroy_times: PackedStringArray = PackedStringArray()
## Game time (s) the current storm ends (0 = no storm running).
var storm_until: float = 0.0
## Game time (s) the current storm began (the veil's fade-in).
var storm_from: float = -100.0
## Scrap storms this run.
var storms: int = 0
## "m:ss" the Trojan Horse fell ("" while alive / never spawned).
var trojan_time: String = ""
## Reach samples asked of reach_mult_at() (the autotest's reach shares).
var reach_samples: int = 0
## ... of which near a standing pylon (boosted).
var reach_boosted: int = 0
## ... of which in a dead zone (shrunk).
var reach_shrunk: int = 0
## ... of which during a storm (halved).
var reach_stormed: int = 0
## Log of Wastes events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The Trojan Horse once spawned (null before / after; generation-checked).
var _trojan: Enemy = null
## Generation of `_trojan` when it spawned.
var _trojan_gen: int = 0
## True once this director is registered as an EmpireRules reach source.
var _registered: bool = false
## The storm's dust veil (child node, above the units).
var _veil: StormVeil = null
## True if the veil showed dust at its last redraw (one more redraw clears it).
var _veil_drawn: bool = false


func _ready() -> void:
	z_index = -1  # Dead-zone markers lie on the ground, under the bodies.
	_veil = StormVeil.new()
	_veil.director = self
	_veil.z_index = 5  # Over the units and shots, under the HUD (its own layer).
	_veil.z_as_relative = false
	add_child(_veil)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if not _registered:
		game.empire_rules().add_reach_source(self)  # The one reach path (EmpireRules.reach_mult()).
		_registered = true
	_step_pylons()
	_step_trojan()
	var veil := storm_alpha() > 0.0  # The dust veil shows.
	if veil or _veil_drawn:
		_veil.queue_redraw()
	_veil_drawn = veil


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs a Wastes timeline event (EnemyDirector forwards the "pylons", "storm"
## and "trojan" types; keys in WastesStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"pylons":
			_place_pylons(ev)
		"storm":
			_start_storm()
		"trojan":
			_spawn_trojan(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Raises `ev.count` Signal Pylons around the necromancer, spread evenly,
## spaced and out of obstacles, each with its guards.
func _place_pylons(ev: Dictionary) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU  # Angle of the first pylon.
	var kind := String(ev.get("kind", WastesEnemyData.PYLON))
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Body radius.
	var p := game.player.position
	var placed: Array[Vector2] = []
	for i in n:
		var best := p  # Chosen spot.
		for _try in int(config["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			var pos := game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			best = pos
			if spaced:
				break
		placed.append(best)
		var e := game.enemies.spawn_at(kind, best, false)
		e.is_objective = true
		game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
		var py := Pylon.new()
		py.enemy = e
		py.gen = e.generation
		py.pos = e.position
		py.ev = ev
		pylons.append(py)
		pylons_raised += 1
		game.effects.spawn_ring(e.position, Palette.EMPIRE_SIGNAL_AMBER)
		for grp: Dictionary in ev.get("guards", []):
			for _k in int(grp["count"]):
				if game.enemies.regular_alive() >= game.enemies.hard_cap():
					break
				game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 30.0), bool(grp["elite"]))
	game.stat_add("wastes_pylons_raised", float(n))
	Sfx.play("lock_on", p, 0.6)
	_log("pylons_raised_%d" % n)


## A scrap storm rolls in for storm_duration s.
func _start_storm() -> void:
	storm_from = game.elapsed
	storm_until = game.elapsed + float(config["storm_duration"])
	storms += 1
	game.stat_add("wastes_storms", 1.0)
	Sfx.play("storm_wind", Vector2.INF)
	_log("storm")


## Spawns the Trojan Horse on the spawn ring and tracks it (its kit registers
## it on the HUD's miniboss bar; Enemy.is_miniboss: never recycled).
func _spawn_trojan(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev["kind"]), game.enemies.ring_point(randf() * TAU), bool(ev.get("elite", false)))
	_trojan = e
	_trojan_gen = e.generation
	game.stat_add("wastes_trojans_spawned", 1.0)
	Sfx.play("servo_step", e.position, 0.6)
	_log("trojan_arrived")


# =====================================================================================
# Pylons, the Trojan Horse
# =====================================================================================

## Fallen pylons pay their rewards and leave their dead zone.
func _step_pylons() -> void:
	var i := 0
	while i < pylons.size():
		var py := pylons[i]
		var e := py.enemy
		if not e.active or e.generation != py.gen:
			_on_destroyed(py)
			pylons.remove_at(i)
			continue
		py.pos = e.position
		i += 1


## A pylon fell: XP burst, Soul Ash, its dead zone, banner, stats.
func _on_destroyed(py: Pylon) -> void:
	pylons_destroyed += 1
	destroy_times.append(_clock())
	dead_zones.append(Vector3(py.pos.x, py.pos.y, float(config["dead_zone_radius"])))
	game.stat_add("objective_ash", float(config["ash_per_pylon"]))
	game.stat_add("wastes_pylons_destroyed", 1.0)
	var xp := int(py.ev.get("reward_xp", 0))  # XP burst (in reward_crystals crystals).
	var n := maxi(1, int(py.ev.get("reward_crystals", 1)))
	if xp > 0:
		var each := maxi(1, floori(float(xp) / float(n)))
		for k in n:
			game.pickups.spawn(py.pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 46.0), each)
	game.effects.impact(py.pos, 70.0, Palette.EMPIRE_SIGNAL_AMBER, "wastes_blast")
	game.effects.ring(py.pos, float(config["dead_zone_radius"]), Palette.EMPIRE_CHROME_LIGHT, 0.7)
	Sfx.play("pylon_down", py.pos)
	game.enemies.show_banner("A Signal Pylon falls: their guns reach shorter here now!")
	_log("pylon_destroyed")
	queue_redraw()


## Notes when the Trojan Horse fell (its XP burst and banner are its kit's,
## its chest ChestManager's miniboss rule).
func _step_trojan() -> void:
	if _trojan == null or (_trojan.active and _trojan.generation == _trojan_gen):
		return
	_trojan = null
	game.stat_add("wastes_trojans_killed", 1.0)
	trojan_time = _clock()
	_log("trojan_killed")


# =====================================================================================
# The reach path, the storm
# =====================================================================================

## THE reach modifier of the Scrap Wastes (EmpireRules.reach_mult() reads it):
## the multiplier on an Empire shooter's range at `pos` (see the header).
func reach_mult_at(pos: Vector2) -> float:
	var m := 1.0  # Reach multiplier at pos.
	reach_samples += 1
	var boost_r := float(config["pylon_radius"])  # Pylon signal reach (px).
	for py in pylons:
		if py.pos.distance_to(pos) <= boost_r:
			m *= float(config["pylon_boost"])
			reach_boosted += 1
			break  # Pylons do not stack: one signal is enough.
	for z in dead_zones:
		if Vector2(z.x, z.y).distance_to(pos) <= z.z:
			m *= float(config["dead_zone_mult"])
			reach_shrunk += 1
			break  # Dead zones do not stack either.
	if storm_active():
		m *= float(config["storm_reach_mult"])
		reach_stormed += 1
	return maxf(float(config["reach_min"]), m)


## True while a scrap storm halves the Empire's sight.
func storm_active() -> bool:
	return game.elapsed < storm_until


## 0..1 strength of the dust veil (it fades in and out over storm_fade s;
## visual only).
func storm_alpha() -> float:
	var fade := maxf(0.01, float(config["storm_fade"]))  # Fade time (s).
	var t := game.elapsed
	if t < storm_from or t > storm_until + fade:
		return 0.0
	return clampf(minf((t - storm_from) / fade, (storm_until + fade - t) / fade), 0.0, 1.0)


# =====================================================================================
# Queries (enemy director, HUD, autopilot)
# =====================================================================================

## Live pylons.
func standing_pylons() -> int:
	var n := 0
	for py in pylons:
		if py.enemy.active and py.enemy.generation == py.gen:
			n += 1
	return n


## HUD objective for the live Wastes objective ("" if none): the Trojan Horse
## first, then a storm, then the standing pylons (until the boss arrives).
func objective_override() -> String:
	if _trojan != null:
		return "Bring down the Trojan Horse: shoot its rockets out of the sky"
	if storm_active():
		return "Scrap storm: their guns are half blind, close in on the shooters!"
	var n := standing_pylons()
	if n > 0 and game.enemies.boss == null:
		return "Tear down the Signal Pylons: they lengthen the Empire's guns (%d left)" % n
	return ""


## Autopilot hint: the nearest standing pylon within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for py in pylons:
		var d := p.distance_to(py.pos)
		if d < best_d:
			best_d = d
			best = py.pos
	return best


## One-line autotest summary: pylons, the reach shares, storms, the Trojan Horse.
func summary_line() -> String:
	var n := maxf(1.0, float(reach_samples))  # Reach samples (never 0 for the shares).
	return "pylons raised %d, destroyed %d (at %s), standing %d, dead zones %d | shooter reach: boosted %.0f%%, shrunk %.0f%%, storm-halved %.0f%% of %d samples | storms %d | trojan horse %s | objective ash %d" % [
		pylons_raised, pylons_destroyed, ", ".join(destroy_times) if not destroy_times.is_empty() else "-", standing_pylons(), dead_zones.size(),
		100.0 * float(reach_boosted) / n, 100.0 * float(reach_shrunk) / n, 100.0 * float(reach_stormed) / n, reach_samples, storms,
		("killed at " + trojan_time) if trojan_time != "" else ("alive" if _trojan != null else "not spawned"),
		int(game.stats.get("objective_ash", 0.0))]


## Records a Wastes event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Drawing (world space; visual only)
# =====================================================================================

## The dead zones of fallen pylons: a faint chrome ring and a toppled mast
## stump at the centre.
func _draw() -> void:
	for z in dead_zones:
		var c := Vector2(z.x, z.y)  # Zone centre.
		draw_arc(c, z.z, 0.0, TAU, 48, Color(Palette.EMPIRE_CHROME_LIGHT, 0.10), 2.0)
		draw_circle(c, 10.0, Color(Palette.EMPIRE_CHROME_DARK, 0.6))
		draw_line(c + Vector2(-9, 4), c + Vector2(12, -6), Palette.EMPIRE_CHROME, 3.0)


## The storm's dust veil on `ci` (StormVeil): rings of ochre dust thickening
## away from the necromancer, so the far field fades out, and streaks of grit
## blowing across. Fewer streaks with Effects: Reduced. No shader (CLAUDE.md).
func draw_veil(ci: CanvasItem) -> void:
	var k := storm_alpha()  # Veil strength 0..1.
	if k <= 0.0:
		return
	var p := game.player.position  # The veil's centre.
	var clear := float(config["storm_clear_radius"])  # Clear radius around him (px).
	var far := game.view_size().length() * 0.6 + 80.0  # Past the screen corners (px).
	var dust: Color = config["storm_color"]  # Dust colour.
	var r := clear
	var band := 46.0  # Ring width (px).
	while r < far:
		var a := clampf((r - clear) / maxf(1.0, far * 0.55 - clear), 0.0, 1.0)  # 0 at the clear edge -> 1 outside.
		ci.draw_arc(p, r + band * 0.5, 0.0, TAU, 64, Color(dust, k * (0.10 + 0.55 * a)), band + 2.0)
		r += band
	var n := 18 if Settings.reduced_effects() else 46  # Grit streaks.
	var t := game.elapsed
	var wind := Vector2(1.0, 0.28).normalized()  # The storm's heading.
	for i in n:
		var h := absi(hash(Vector2i(i, 77)))  # Stable per streak.
		var ox := float(h % 1000) / 1000.0 * far * 2.0 - far
		var oy := float((h >> 10) % 1000) / 1000.0 * far * 2.0 - far
		var speed := 260.0 + float((h >> 20) % 160)  # px/s.
		var along := fposmod(ox + t * speed, far * 2.0) - far
		var q := p + Vector2(along, oy)
		ci.draw_line(q, q + wind * (14.0 + float(h % 12)), Color(dust.lightened(0.25), 0.35 * k), 2.0)
