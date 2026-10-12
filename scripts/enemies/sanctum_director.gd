## SanctumDirector — the Sanctum of Judgment's objectives (GDD §8.3, §7.4),
## owned and stepped by EnemyDirector on stages whose StageRegistry `sanctum`
## config is not empty (the battle zones themselves are MarchDirector's).
## Data: SanctumStage (SANCTUM, the "chamber" / "guardian" / "altars"
## timeline events) and SanctumObjectiveData (the structures).
##   * Sanctified chambers ("ward crystals"): a holy circle around two ward
##     crystals placed near the necromancer. Until every crystal falls, each
##     summon inside takes light holy damage every chamber_tick s, and undead
##     minion attacks on a foe standing inside deal chamber_minion_damage
##     (CombatResolver.damage_enemy() asks minion_damage_mult()). Shattering
##     the last crystal cleanses it: the ground turns purple, the penalty
##     ends, corruption rises and the objective's Soul Ash is paid.
##   * The Cathedral Guardian: a plain miniboss (owner decision: it shields
##     nothing) that walks in from the spawn ring, shows on the HUD's miniboss
##     bar (EnemyDirector.miniboss) and drops a treasure chest when it dies.
##   * Sacred altars (optional, open question 4): three altars rise around
##     the necromancer, each guarded by a High Confessor. Each one destroyed
##     cuts SANCTUM.altar_hp_cut off the max HP of every Covenant soldier
##     spawned afterwards (objective_hp_mult(), applied once in
##     EnemyDirector.step()), raises corruption, pays Soul Ash and counts in
##     Game.altars_destroyed (Seraphine brings that many fewer healers).
##     Skipping them costs only the bonus: nothing waits on them.
##   * Corruption: 0..1, raised by cleansed chambers and fallen altars; the
##     floor (SanctumGround) darkens toward purple as it rises.
##   * Dawn's Wrath: once the Reckoning starts, a gold dawn light washes over
##     the field around the necromancer (cosmetic).
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective:
## never recycled), polled here with generation checks to pay their rewards
## once they fall; every placed structure also asks Arena.keep_clear() so a
## later zone change never rebuilds an obstacle on top of it. Deterministic:
## only the seeded global RNG. Everything is drawn here in world space,
## under bodies.
class_name SanctumDirector
extends Node2D

## One sanctified chamber.
class Chamber:
	extends RefCounted
	## World-space centre of the holy circle.
	var pos: Vector2 = Vector2.ZERO
	## Radius of the holy circle (px).
	var radius: float = 220.0
	## The chamber's ward crystals (Enemy nodes; stale once they fall).
	var crystals: Array[Enemy] = []
	## Generation of each crystal when it was placed (stale / death guard).
	var gens: Array[int] = []
	## Last known position of each crystal (rewards spawn there).
	var crystal_pos: Array[Vector2] = []
	## True per crystal once it has fallen.
	var down: Array[bool] = []
	## The timeline event that opened it (rewards).
	var ev: Dictionary = {}
	## True once every crystal fell (no more penalty; drawn purple).
	var cleansed: bool = false
	## Game time it was cleansed (-1 before; fades the purple stain in).
	var cleansed_at: float = -1.0

	## Crystals still standing.
	func live_count() -> int:
		var n := 0
		for d: bool in down:
			if not d:
				n += 1
		return n

## One sacred altar.
class Altar:
	extends RefCounted
	## The altar's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## Last known world position (rewards spawn here once it falls).
	var pos: Vector2 = Vector2.ZERO
	## The timeline event that raised it (rewards).
	var ev: Dictionary = {}

## Owning run.
var game: Game
## The stage's objective config (SanctumStage.SANCTUM).
var config: Dictionary = {}
## Every chamber opened this run (live and cleansed; at most a few).
var chambers: Array[Chamber] = []
## Sacred altars still standing.
var altars: Array[Altar] = []
## Chambers cleansed so far.
var chambers_cleansed: int = 0
## Corruption the floor is heading for (0..1).
var corruption: float = 0.0
## Corruption the floor currently shows (eases toward `corruption`).
var shown_corruption: float = 0.0
## Game time each chamber was cleansed, "m:ss" (summary).
var cleanse_times: PackedStringArray = PackedStringArray()
## Game time each altar fell, "m:ss" (summary).
var altar_times: PackedStringArray = PackedStringArray()
## Game time the Guardian fell ("" while alive / never spawned).
var guardian_time: String = ""
## Log of Sanctum events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The Guardian once spawned (null before / after; generation-checked).
var _guardian: Enemy = null
## Generation of `_guardian` when it spawned.
var _guardian_gen: int = 0
## The "guardian" event that spawned it (rewards).
var _guardian_ev: Dictionary = {}
## Last known position of the Guardian (its chest drops there).
var _guardian_pos: Vector2 = Vector2.ZERO
## Seconds accumulated toward the next chamber damage tick.
var _tick: float = 0.0
## True if something animated was drawn last frame (one final redraw clears it).
var _drew: bool = false
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -7  # On the ground, under bodies (like StageDirector's holy zones).


## Per-tick update, called by EnemyDirector after the MarchDirector.
func step(delta: float) -> void:
	_step_chambers(delta)
	_step_altars()
	_step_guardian()
	_ease_corruption(delta)
	var busy := game.enemies.reckoning_wave > 0 or not altars.is_empty()
	for c in chambers:
		busy = busy or not c.cleansed or game.elapsed - c.cleansed_at < 2.0
	if busy or _drew:
		queue_redraw()
	_drew = busy


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs a Sanctum timeline event (EnemyDirector forwards the "chamber",
## "guardian" and "altars" types; keys in SanctumStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"chamber":
			_open_chamber(ev)
		"guardian":
			_spawn_guardian(ev)
		"altars":
			_raise_altars(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Opens a sanctified chamber `distance_min`..`distance_max` px from the
## necromancer with its ward crystals around the centre, plus its escort.
func _open_chamber(ev: Dictionary) -> void:
	var c := Chamber.new()
	c.ev = ev
	c.radius = float(config["chamber_radius"])
	var p := game.player.position
	c.pos = p + Vector2.from_angle(randf() * TAU) * randf_range(float(ev["distance_min"]), float(ev["distance_max"]))
	var kind := String(ev["kind"])
	var n := int(config["crystals_per_chamber"])
	var a0 := randf() * TAU  # Angle of the first crystal around the centre.
	for i in n:
		var at := c.pos + Vector2.from_angle(a0 + TAU * float(i) / float(maxi(1, n))) * float(ev["crystal_offset"])
		var e := _place_structure(kind, at)
		c.crystals.append(e)
		c.gens.append(e.generation)
		c.crystal_pos.append(e.position)
		c.down.append(false)
	chambers.append(c)
	game.effects.ring(c.pos, c.radius, Palette.GOLD, 0.6)
	var escort: Dictionary = ev.get("escort", {})
	if not escort.is_empty():
		game.enemies.spawn_formation(String(escort["formation"]), escort["groups"])
	game.stat_add("sanctum_chambers_opened", 1.0)
	_log("chamber_opened")


## Spawns the Cathedral Guardian on the spawn ring (stand-in HP multiplier
## from the event), shows it on the HUD's miniboss bar and tracks it.
func _spawn_guardian(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev["kind"]), game.enemies.ring_point(randf() * TAU), bool(ev["elite"]))
	e.max_hp *= float(ev.get("hp_mult", 1.0))
	e.hp = e.max_hp
	e.is_objective = true  # Never recycled: it always comes for the necromancer.
	_guardian = e
	_guardian_gen = e.generation
	_guardian_ev = ev
	_guardian_pos = e.position
	game.enemies.set_miniboss(e)
	game.stat_add("sanctum_guardians_spawned", 1.0)
	_log("guardian_arrived")


## Raises `count` sacred altars around the necromancer (spread evenly, at
## least SANCTUM.structure_spacing px apart, out of obstacles), each with its
## guards beside it.
func _raise_altars(ev: Dictionary) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU
	var kind := String(ev["kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Altar body radius.
	var placed: Array[Vector2] = []
	var p := game.player.position
	for i in n:
		var pos := p
		for _try in int(config["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			pos = game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			if spaced:
				break
		placed.append(pos)
		var e := _place_structure(kind, pos)
		var al := Altar.new()
		al.enemy = e
		al.gen = e.generation
		al.pos = e.position
		al.ev = ev
		altars.append(al)
		for grp: Dictionary in ev["guards"]:
			for _k in int(grp["count"]):
				if game.enemies.regular_alive() >= WaveData.HARD_CAP:
					break
				var at := al.pos + Vector2.from_angle(randf() * TAU) * (e.radius + 26.0)
				game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
	game.stat_add("sanctum_altars_raised", float(n))
	_log("altars_raised_%d" % n)


## Spawns objective structure `kind` at (a free point near) `at`, keeps the
## terrain of later zones clear of it and returns it.
func _place_structure(kind: String, at: Vector2) -> Enemy:
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Body radius.
	var e := game.enemies.spawn_at(kind, game.arena.free_point(at, r), false)
	e.is_objective = true
	game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
	game.effects.spawn_ring(e.position, Palette.GOLD)
	return e


# =====================================================================================
# Chambers, altars, the Guardian
# =====================================================================================

## Crystals that fell pay their XP; a chamber whose last crystal fell is
## cleansed; summons inside an uncleansed chamber burn every chamber_tick s.
func _step_chambers(delta: float) -> void:
	for c in chambers:
		if c.cleansed:
			continue
		for i in c.crystals.size():
			if c.down[i]:
				continue
			var e := c.crystals[i]
			if not e.active or e.generation != c.gens[i]:
				c.down[i] = true
				_xp_burst(c.crystal_pos[i], c.ev)
				game.effects.impact(c.crystal_pos[i], 50.0, Palette.GOLD)
				game.stat_add("sanctum_crystals_destroyed", 1.0)
				_log("crystal_destroyed")
				if c.live_count() > 0:
					game.enemies.show_banner("A ward crystal shatters! %d left in this chamber" % c.live_count())
			else:
				c.crystal_pos[i] = e.position
		if c.live_count() == 0:
			_cleanse(c)
	_tick += delta
	var tick := float(config["chamber_tick"])
	if _tick < tick:
		return
	_tick -= tick
	var dmg := float(config["chamber_undead_dps"]) * tick  # Holy damage per summon this tick.
	for c in chambers:
		if c.cleansed:
			continue
		game.ally_grid.query(c.pos, c.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(c.pos) > c.radius:
				continue
			game.combat.damage_unit(u, dmg, "holy_zone")
			game.stat_add("sanctum_chamber_burns", 1.0)
	_check_blocked()


## Every crystal of `c` fell: the chamber is cleansed.
func _cleanse(c: Chamber) -> void:
	c.cleansed = true
	c.cleansed_at = game.elapsed
	chambers_cleansed += 1
	corruption = minf(1.0, corruption + float(config["corruption_per_chamber"]))
	game.stat_add("objective_ash", float(config["ash_per_chamber"]))
	game.stat_add("sanctum_chambers_cleansed", 1.0)
	game.effects.ring(c.pos, c.radius, Palette.VIOLET, 0.8)
	game.enemies.show_banner("The chamber is cleansed: its holy ground rots away!")
	cleanse_times.append(_clock())
	_log("chamber_cleansed")


## Fallen altars weaken the Covenant: later soldiers' HP, corruption, Soul
## Ash, Game.altars_destroyed.
func _step_altars() -> void:
	var i := 0
	while i < altars.size():
		var al := altars[i]
		var e := al.enemy
		if e.active and e.generation == al.gen:
			al.pos = e.position
			i += 1
			continue
		altars.remove_at(i)
		game.altars_destroyed += 1
		corruption = minf(1.0, corruption + float(config["corruption_per_altar"]))
		game.stat_add("objective_ash", float(config["ash_per_altar"]))
		game.stat_add("sanctum_altars_destroyed", 1.0)
		_xp_burst(al.pos, al.ev)
		game.effects.impact(al.pos, 70.0, Palette.VIOLET)
		game.enemies.show_banner("A sacred altar crumbles: the Covenant's soldiers weaken (-%d%% HP)!" % roundi((1.0 - objective_hp_mult()) * 100.0))
		altar_times.append(_clock())
		_log("altar_destroyed")


## The Guardian fell: treasure chest, XP burst, banner.
func _step_guardian() -> void:
	if _guardian == null:
		return
	if _guardian.active and _guardian.generation == _guardian_gen:
		_guardian_pos = _guardian.position
		return
	_guardian = null
	_xp_burst(_guardian_pos, _guardian_ev)
	if bool(_guardian_ev.get("reward_chest", false)) and not game.countdown_finished():
		if game.chests.spawn_chest(_guardian_pos, true):
			game.stat_add("sanctum_guardian_chests", 1.0)
	game.effects.impact(_guardian_pos, 90.0, Palette.GOLD)
	game.enemies.show_banner("The Cathedral Guardian crumbles! Claim its treasure")
	game.stat_add("sanctum_guardians_killed", 1.0)
	guardian_time = _clock()
	_log("guardian_killed")


## XP burst of a fallen objective (`ev` reward_xp in reward_crystals crystals).
func _xp_burst(pos: Vector2, ev: Dictionary) -> void:
	var xp := int(ev.get("reward_xp", 0))
	var n := maxi(1, int(ev.get("reward_crystals", 1)))
	if xp <= 0:
		return
	var each := maxi(1, floori(float(xp) / float(n)))
	for k in n:
		game.pickups.spawn(pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 46.0), each)


## Counts live objective structures overlapping an obstacle (autotest check:
## must stay 0; sampled once per chamber tick).
func _check_blocked() -> void:
	for c in chambers:
		for i in c.crystals.size():
			if not c.down[i] and game.arena.is_blocked(c.crystals[i].position, c.crystals[i].radius):
				game.stat_add("sanctum_structures_blocked", 1.0)
	for al in altars:
		if game.arena.is_blocked(al.enemy.position, al.enemy.radius):
			game.stat_add("sanctum_structures_blocked", 1.0)


## Eases the floor's corruption toward its target and hands it to the ground.
func _ease_corruption(delta: float) -> void:
	if is_equal_approx(shown_corruption, corruption):
		return
	shown_corruption = move_toward(shown_corruption, corruption, float(config["corruption_ease"]) * delta)
	if game.ground is SanctumGround:
		(game.ground as SanctumGround).set_corruption(shown_corruption, config["corrupt_color"], float(config["corrupt_tint"]))


## Records a Sanctum event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Queries (combat, enemy stats, HUD, autopilot)
# =====================================================================================

## Multiplier on an undead minion's damage to a foe at `pos`: the chamber
## penalty inside an uncleansed sanctified chamber, else 1.
func minion_damage_mult(pos: Vector2) -> float:
	for c in chambers:
		if not c.cleansed and pos.distance_squared_to(c.pos) <= c.radius * c.radius:
			return float(config["chamber_minion_damage"])
	return 1.0


## Max-HP multiplier of Covenant soldiers spawned now: -altar_hp_cut per
## destroyed altar (additive). EnemyDirector.step() applies it to hp_mult.
func objective_hp_mult() -> float:
	return maxf(0.1, 1.0 - float(config["altar_hp_cut"]) * float(game.altars_destroyed))


## Live ward crystals over every chamber.
func live_crystals() -> int:
	var n := 0
	for c in chambers:
		if not c.cleansed:
			n += c.live_count()
	return n


## HUD objective for the live Sanctum objective ("" if none): ward crystals
## first, then the Guardian, then the optional altars.
func objective_override() -> String:
	var crystals := live_crystals()
	if crystals > 0:
		return "Shatter the ward crystals: holy ground weakens your dead (%d left)" % crystals
	if _guardian != null:
		return "Slay the Cathedral Guardian: it guards a treasure"
	if not altars.is_empty():
		return "Optional: destroy the sacred altars to weaken the Covenant (%d left)" % altars.size()
	return ""


## Suffix of the HUD zone line ("" until corruption rises).
func hud_suffix() -> String:
	if corruption <= 0.0:
		return ""
	return "  |  Corruption %d%%" % roundi(corruption * 100.0)


## Autopilot hint: the nearest live ward crystal or sacred altar within
## `reach` px of `p` (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for c in chambers:
		if c.cleansed:
			continue
		for i in c.crystals.size():
			if c.down[i]:
				continue
			var d := p.distance_to(c.crystal_pos[i])
			if d < best_d:
				best_d = d
				best = c.crystal_pos[i]
	for al in altars:
		var d := p.distance_to(al.pos)
		if d < best_d:
			best_d = d
			best = al.pos
	return best


## One-line autotest summary: chambers, altars, corruption, HP cut, Guardian.
func summary_line() -> String:
	var st := game.stats
	return "chambers cleansed %d/%d (%s) | crystals destroyed %d | altars destroyed %d/%d (%s) | corruption %.2f | soldier HP cut %d%% | guardian %s | chamber burns %d | objective ash %d | structures in obstacles %d" % [
		chambers_cleansed, chambers.size(), ", ".join(cleanse_times) if not cleanse_times.is_empty() else "-",
		int(st.get("sanctum_crystals_destroyed", 0.0)), game.altars_destroyed, int(st.get("sanctum_altars_raised", 0.0)),
		", ".join(altar_times) if not altar_times.is_empty() else "-", corruption, roundi((1.0 - objective_hp_mult()) * 100.0),
		("killed at " + guardian_time) if guardian_time != "" else ("alive" if _guardian != null else "not spawned"),
		int(st.get("sanctum_chamber_burns", 0.0)), int(st.get("objective_ash", 0.0)), int(st.get("sanctum_structures_blocked", 0.0))]


# =====================================================================================
# Drawing (world space, under bodies)
# =====================================================================================

func _draw() -> void:
	var now := game.elapsed
	for c in chambers:
		if c.cleansed:
			_draw_cleansed(c, now)
		else:
			_draw_chamber(c, now)
	for al in altars:
		_draw_altar_sigil(al, now)
	if game.enemies.reckoning_wave > 0:
		_draw_dawn(now)


## Uncleansed chamber: a pulsing gold disc, an ivory rim, a slowly turning
## rune ring and light beams from each standing crystal to the centre.
func _draw_chamber(c: Chamber, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 3.0 + c.pos.x * 0.01)
	draw_circle(c.pos, c.radius, Color(Palette.GOLD, 0.07 + 0.03 * pulse))
	draw_arc(c.pos, c.radius, 0.0, TAU, 64, Color(Palette.IVORY, 0.7), 2.0)
	draw_arc(c.pos, c.radius - 8.0, 0.0, TAU, 64, Color(Palette.GOLD, 0.35), 1.0)
	var rot := now * 0.25
	for i in 12:
		var a := rot + TAU * float(i) / 12.0
		var q := c.pos + Vector2.from_angle(a) * (c.radius - 18.0)
		draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(Palette.GOLD, 0.45))
	for i in c.crystals.size():
		if not c.down[i]:
			draw_line(c.crystal_pos[i], c.pos, Color(Palette.IVORY, 0.25 + 0.2 * pulse), 3.0)
	draw_circle(c.pos, 10.0 + 3.0 * pulse, Color(Palette.IVORY, 0.35))


## Cleansed chamber: a purple rot stain (fading in over 2 s) with cracks.
func _draw_cleansed(c: Chamber, now: float) -> void:
	var k := clampf((now - c.cleansed_at) / 2.0, 0.0, 1.0)
	draw_circle(c.pos, c.radius, Color(Palette.ROBE, 0.30 * k))
	draw_arc(c.pos, c.radius, 0.0, TAU, 64, Color(Palette.VIOLET, 0.35 * k), 2.0)
	for i in 7:
		var a := TAU * float(i) / 7.0 + c.pos.y * 0.003
		var mid := c.pos + Vector2.from_angle(a + 0.2) * c.radius * 0.45
		draw_polyline(PackedVector2Array([c.pos + Vector2.from_angle(a) * 12.0, mid, c.pos + Vector2.from_angle(a - 0.1) * c.radius * 0.85]),
				Color(Palette.NECRO_GREEN, 0.18 * k), 1.5)


## A standing altar's gold sigil circle on the floor.
func _draw_altar_sigil(al: Altar, now: float) -> void:
	var r := al.enemy.radius * 2.4
	var pulse := 0.5 + 0.5 * sin(now * 2.5 + al.pos.y * 0.02)
	draw_circle(al.pos, r, Color(Palette.GOLD, 0.06 + 0.04 * pulse))
	draw_arc(al.pos, r, 0.0, TAU, 40, Color(Palette.GOLD, 0.6), 1.5)
	for i in 4:
		var dir := Vector2.from_angle(now * 0.5 + TAU * float(i) / 4.0)
		draw_line(al.pos + dir * r * 0.6, al.pos + dir * r, Color(Palette.GOLD, 0.5), 1.5)


## Dawn's Wrath: gold dawn light pooled around the necromancer, with slowly
## turning light shafts.
func _draw_dawn(now: float) -> void:
	var rk: Dictionary = game.stage_def["reckoning"]  # The stage's Reckoning (Dawn's Wrath).
	var light: Color = rk.get("light", Palette.GOLD)  # Dawn light colour.
	var c := game.player.position
	var pulse := 0.5 + 0.5 * sin(now * 1.5)
	for i in 4:
		draw_circle(c, 520.0 - 110.0 * float(i), Color(light, 0.035 + 0.01 * pulse))
	for i in 6:
		var a := now * 0.12 + TAU * float(i) / 6.0
		var dir := Vector2.from_angle(a)
		var side := Vector2(-dir.y, dir.x) * 26.0
		draw_colored_polygon(PackedVector2Array([c + dir * 80.0 - side, c + dir * 560.0 - side * 3.0, c + dir * 560.0 + side * 3.0, c + dir * 80.0 + side]),
				Color(light, 0.05))
