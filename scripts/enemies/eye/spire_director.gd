## SpireDirector — the objectives of Ul-Thalos, the Risen Spire (Stage 6; GDD
## §15.0 "Ul-Thalos, the Risen Spire"), owned and stepped by EnemyDirector on
## a stage whose STAGE has a "spire" config (SpireStage.SPIRE; null elsewhere).
## The zones are MarchDirector's and the sinking SinkingDirector's.
##   * Dream pillars (the "pillars" timeline event): three cyclopean obelisks
##     rise around the spire (inside the island's last shoreline, so they
##     never sink), each with its guards. Optional: each one toppled pays an
##     XP burst and SPIRE.ash_per_pillar Soul Ash; each one still standing
##     when Vhal'Neth wakes gives her opening phase one more arm
##     (standing_pillars(), read by BossVhalneth). While one stands, a
##     necromancer close to it feels the god's dream (Dread, "pillar").
##   * Guest squads: the earlier Act II stages' kinds (Gullhaven Harbour, the
##     Hollow Archive) stay in play on the stages after theirs. SPIRE.guests
##     names each kind by its candidate ids; the first one this build knows
##     (EnemyDirector.is_known_kind()) joins small squads on a timer, so the
##     stage plays the same before and after those stages are merged in.
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective:
## never recycled), polled with generation checks. Deterministic: the seeded
## global RNG only.
## Stats: spire_pillars_raised, spire_pillars_toppled, objective_ash,
## spire_guest_squads, spire_guests_spawned.
class_name SpireDirector
extends Node2D

## One dream pillar.
class Pillar:
	extends RefCounted
	## The pillar's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## Last known world position.
	var pos: Vector2 = Vector2.ZERO
	## The timeline event that raised it (rewards).
	var ev: Dictionary = {}

## Owning run.
var game: Game
## The stage's spire config (SpireStage.SPIRE).
var config: Dictionary = {}
## Standing dream pillars.
var pillars: Array[Pillar] = []
## Dream pillars raised this run.
var pillars_raised: int = 0
## Dream pillars toppled this run.
var pillars_toppled: int = 0
## "m:ss" of each toppled pillar (summary).
var topple_times: PackedStringArray = PackedStringArray()
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Game time of the next guest squad.
var _next_guest: float = 0.0
## Guest squads sent so far.
var _guest_squads: int = 0
## Log of spire events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Seconds until the next pillar Dread tick.
var _dread_tick: float = 0.0


func _ready() -> void:
	z_index = -1  # Pillar sigils under the bodies.
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break


## Per-tick update (EnemyDirector, after the march and the sinking).
func step(delta: float) -> void:
	_step_pillars(delta)
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()
	if not pillars.is_empty():
		queue_redraw()


## Runs a spire timeline event (EnemyDirector forwards "pillars").
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) == "pillars":
		_raise_pillars(ev)
	game.enemies.show_banner(String(ev["banner"]))


# =====================================================================================
# Dream pillars
# =====================================================================================

## Raises `count` pillars `distance_min`..`distance_max` px from the island's
## centre (spread evenly, structure_spacing apart, out of obstacles), each
## with its guards.
func _raise_pillars(ev: Dictionary) -> void:
	var sink := game.enemies.sinking  # The island (null on a stage without one: centre = the necromancer).
	var c := sink.center if sink != null else game.player.position
	var n := int(ev["count"])
	var kind := String(ev["kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Pillar body radius.
	var offset := randf() * TAU
	var placed: Array[Vector2] = []
	for i in n:
		var pos := c
		for _try in int(config["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.3, 0.3)
			pos = game.arena.free_point(c + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			if spaced:
				break
		placed.append(pos)
		var e := game.enemies.spawn_at(kind, pos, false)
		e.is_objective = true
		game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
		game.effects.spawn_ring(e.position, Palette.EYE_BIOLUME)
		var pl := Pillar.new()
		pl.enemy = e
		pl.gen = e.generation
		pl.pos = e.position
		pl.ev = ev
		pillars.append(pl)
		pillars_raised += 1
		for grp: Dictionary in ev["guards"]:
			for _k in int(grp["count"]):
				if game.enemies.regular_alive() >= game.enemies.hard_cap():
					break
				var at := pl.pos + Vector2.from_angle(randf() * TAU) * (e.radius + 26.0)
				game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
	game.stat_add("spire_pillars_raised", float(n))
	_log("pillars_raised_%d" % n)


## Fallen pillars pay their rewards; standing ones feed the dream (Dread on a
## necromancer close to them).
func _step_pillars(delta: float) -> void:
	var i := 0
	while i < pillars.size():
		var pl := pillars[i]
		var e := pl.enemy
		if e.active and e.generation == pl.gen:
			pl.pos = e.position
			i += 1
			continue
		pillars.remove_at(i)
		pillars_toppled += 1
		game.stat_add("spire_pillars_toppled", 1.0)
		game.stat_add("objective_ash", float(config["ash_per_pillar"]))
		_xp_burst(pl.pos, pl.ev)
		game.effects.impact(pl.pos, 70.0, Palette.EYE_BIOLUME)
		game.enemies.show_banner("A dream pillar topples: the god's dream weakens! (%d left)" % pillars.size())
		topple_times.append(_clock())
		_log("pillar_toppled")
	if pillars.is_empty() or game.dread == null:
		return
	_dread_tick -= delta
	if _dread_tick > 0.0:
		return
	_dread_tick += 0.5
	var reach := float(config["pillar_dread_radius"])
	for k in game.all_players.size():  # Each necromancer's own Dread (co-op: bound in turn).
		var prev := game.bind_index(k)
		var p := game.player.position
		for pl in pillars:
			if pl.pos.distance_to(p) <= reach:
				game.dread.add(float(config["pillar_dread"]) * 0.5, "pillar")
				break
		game.unbind(prev)


## Dream pillars still standing (BossVhalneth: one more Dreaming arm each).
func standing_pillars() -> int:
	var n := 0
	for pl in pillars:
		if pl.enemy.active and pl.enemy.generation == pl.gen:
			n += 1
	return n


## XP burst of a fallen pillar (`ev` reward_xp in reward_crystals crystals).
func _xp_burst(pos: Vector2, ev: Dictionary) -> void:
	var xp := int(ev.get("reward_xp", 0))
	var n := maxi(1, int(ev.get("reward_crystals", 1)))
	if xp <= 0:
		return
	var each := maxi(1, floori(float(xp) / float(n)))
	for k in n:
		game.pickups.spawn(pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 46.0), each)


# =====================================================================================
# Guest squads (the earlier Act II stages' kinds)
# =====================================================================================

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
	game.stat_add("spire_guest_squads", 1.0)
	game.stat_add("spire_guests_spawned", float(n))


# =====================================================================================
# HUD, autopilot, summary
# =====================================================================================

## HUD objective while dream pillars stand ("" = none).
func objective_override() -> String:
	var n := standing_pillars()
	if n > 0 and game.enemies.boss == null:
		return "Topple the dream pillars before the god wakes (%d left)" % n
	return ""


## Autopilot hint: the nearest standing pillar within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for pl in pillars:
		var d := p.distance_to(pl.pos)
		if d < best_d:
			best_d = d
			best = pl.pos
	return best


## One-line autotest summary.
func summary_line() -> String:
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "pillars raised %d, toppled %d (at %s), standing %d | guests: %s, squads %d, spawned %d | objective ash %d" % [
		pillars_raised, pillars_toppled, ", ".join(topple_times) if not topple_times.is_empty() else "-", standing_pillars(),
		", ".join(names) if not names.is_empty() else "none in this build", int(game.stats.get("spire_guest_squads", 0.0)),
		int(game.stats.get("spire_guests_spawned", 0.0)), int(game.stats.get("objective_ash", 0.0))]


## Records a spire event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## The game clock as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Drawing: the dream sigil under each pillar
# =====================================================================================

func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for pl in pillars:
		var k := 0.5 + 0.5 * sin(now * 2.2 + pl.pos.x * 0.01)
		draw_circle(pl.pos, 34.0, Color(Palette.EYE_BIOLUME, 0.10 + 0.06 * k))
		draw_arc(pl.pos, 40.0 + 4.0 * k, 0.0, TAU, 32, Color(Palette.EYE_BIOLUME, 0.45), 1.5)
		draw_arc(pl.pos, float(config["pillar_dread_radius"]), 0.0, TAU, 48, Color(Palette.EYE_BIOLUME, 0.12), 1.0)
		for j in 3:
			var a := now * 0.6 + TAU * float(j) / 3.0
			draw_line(pl.pos + Vector2.from_angle(a) * 24.0, pl.pos + Vector2.from_angle(a) * 40.0, Color(Palette.EYE_BIOLUME_GLOW, 0.5), 1.5)
