## SilkPalaceDirector — the stage mechanics of THE PALACE OF SILK AND ASH (Stage
## 17, Act VI; GDD §15.0 "The Palace of Silk and Ash (Act VI phase 2)";
## owner-approved proposal docs/act6/PROPOSAL.md "Stage 17"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "silk_palace" config
## (SilkPalaceStage.SILK_PALACE; null elsewhere). The four zones are
## MarchDirector's (the clock is authoritative: the Rose Garden, the Hall of
## Mirrors, the Ballroom, the Queen's Chamber); the Hell Pits, the portals and
## Temptation are the Inferno's shared rules (Game.inferno). This director runs:
##   * THE HALL OF MIRRORS (owner-approved: "reflections of the necromancer
##     confuse summon targeting"): while the Hall is the current zone, every
##     mirror_every s a standing mirror of the hall (an obstacle of
##     mirror_kinds within mirror_reach px of the necromancer, but not closer
##     than mirror_near: the nearest such) SHIMMERS for mirror_shimmer s (the
##     telegraph), then a REFLECTION of the necromancer steps out of it for
##     mirror_life s: up to mirror_turned summons within mirror_lure px of it
##     (the nearest first) are lured toward it through THE one turn-around path
##     (SummonedUnit.misdirect(): they drop their target and walk at the
##     reflection for mirror_turn s at mirror_speed x their speed). An effect of
##     the ground on units, the same for any summon: no summon rule.
##   * THE TWIN SUCCUBI (the "twins" timeline event): the two sisters fly in
##     from the spawn ring `apart` px apart with their escort and are bound to
##     each other (TwinSuccubusKit.bind_sister(): one rages when the other
##     falls; the miniboss bar passes between them).
##   * GUEST SQUADS: the Burning Gate's kinds (built in parallel) join small
##     squads on a timer when this build knows them (EnemyDirector
##     .is_known_kind(); candidate ids per kind), like the Road to the Sun's.
## Deterministic: the seeded global RNG only (the twins' arrival angle, the
## guests' roll); the mirrors come from the arena's hashed layout, the lured
## summons by distance (ties in the ally grid's order). Stats:
## silk_reflections, silk_mirror_lured, silk_guest_squads, silk_guests_spawned,
## twins_spawned (TwinSuccubusKit).
class_name SilkPalaceDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (SilkPalaceStage.SILK_PALACE).
var config: Dictionary = {}
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## World px of the shimmering / standing reflection (Vector2.INF = none).
var reflection_at: Vector2 = Vector2.INF
## Game time the current mirror began to shimmer.
var shimmer_from: float = -INF
## Game time the current reflection steps out (end of the shimmer).
var reflect_at: float = -INF
## Game time the current reflection fades.
var reflect_until: float = -INF
## Game time of the next reflection (INF until the Hall opens).
var _next_mirror: float = INF
## True once the current reflection has lured.
var _lured: bool = false
## True while the Hall of Mirrors is the current zone.
var _in_hall: bool = false
## Game time of the next guest squad.
var _next_guest: float = INF
## Guest squads sent so far (their size grows with it).
var _guest_squads: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## Summons near a reflection (scratch).
var _buf: Array = []


func _ready() -> void:
	z_index = 3  # The reflection stands among the bodies.
	_draws = DisplayServer.get_name() != "headless"
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	_step_mirrors()
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()


## Runs a Palace timeline event (EnemyDirector forwards "twins").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"twins":
			_send_twins(ev)
	game.enemies.show_banner(String(ev["banner"]))


# =====================================================================================
# The Hall of Mirrors
# =====================================================================================

## The current zone's id (MarchDirector's index into ZONES).
func _zone_id() -> String:
	var m := game.enemies.march
	if m == null:
		return ""
	var zones: Array = m.config["zones"]
	return String((zones[m.zone_index] as Dictionary).get("id", ""))


## The reflections: one mirror at a time shimmers, then its reflection lures.
func _step_mirrors() -> void:
	var hall := _zone_id() == String(config["mirror_zone"])
	if hall != _in_hall:
		_in_hall = hall
		if hall:
			_next_mirror = game.elapsed + float(config["mirror_first"])
			_log("hall of mirrors")
		else:
			_next_mirror = INF
	var now := game.elapsed
	if reflection_at != Vector2.INF:
		if not _lured and now >= reflect_at:
			_lure()
		if now >= reflect_until:
			reflection_at = Vector2.INF
		if _draws:
			queue_redraw()
	if not _in_hall or now < _next_mirror or reflection_at != Vector2.INF:
		return
	_next_mirror = now + float(config["mirror_every"])
	var at := _find_mirror()
	if at == Vector2.INF:
		return
	reflection_at = at
	shimmer_from = now
	reflect_at = now + float(config["mirror_shimmer"])
	reflect_until = reflect_at + float(config["mirror_life"])
	_lured = false
	game.effects.spawn_ring(at, Palette.INFERNO_CHARM_LIGHT)


## The nearest hall mirror within mirror_reach px of the necromancer (and at
## least mirror_near away): the point just in front of it (south), or INF.
func _find_mirror() -> Vector2:
	var p := game.player.position
	var reach := float(config["mirror_reach"])
	var near := float(config["mirror_near"])
	var kinds: Array = config["mirror_kinds"]
	var cell := ArenaData.CELL
	var n := ceili(reach / cell)
	var best := INF
	var at := Vector2.INF
	var c0 := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dy in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var o := game.arena.obstacle_at(Vector2((float(c0.x + dx) + 0.5) * cell, (float(c0.y + dy) + 0.5) * cell))
			if o == null or not (o.kind in kinds):
				continue
			var front := o.center + Vector2(0.0, (o.radius if o.is_circle else o.half.y) + 12.0)  # Its reflection stands just in front.
			var dist := front.distance_to(p)
			if dist < near or dist > reach or dist >= best:
				continue
			best = dist
			at = front
	return at


## The reflection steps out: the nearest summons around it walk at it.
func _lure() -> void:
	_lured = true
	var at := reflection_at
	var lure := float(config["mirror_lure"])
	game.ally_grid.query(at, lure, _buf)
	_buf.sort_custom(func(a: SummonedUnit, b: SummonedUnit) -> bool: return a.position.distance_squared_to(at) < b.position.distance_squared_to(at))
	var n := 0
	for u: SummonedUnit in _buf:
		if n >= int(config["mirror_turned"]):
			break
		if not u.active or u.charmed or u.position.distance_to(at) > lure:
			continue
		if u.misdirect(at - u.position, float(config["mirror_turn"]), float(config["mirror_speed"])):
			n += 1
	game.stat_add("silk_reflections", 1.0)
	game.stat_add("silk_mirror_lured", float(n))
	game.effects.ring(at, 30.0, Palette.INFERNO_CHARM_LIGHT, 0.4)
	if game.inferno != null:
		game.inferno.play_sound("mirror_lure", at)


## The reflection: the mirror's shimmer, then a pale image of the necromancer.
## Visual only.
func _draw() -> void:
	if reflection_at == Vector2.INF:
		return
	var now := game.elapsed
	var at := reflection_at
	if now < reflect_at:
		var k := clampf((now - shimmer_from) / maxf(0.01, reflect_at - shimmer_from), 0.0, 1.0)
		for i in 6:
			var a := TAU * float(i) / 6.0 + now * 3.0
			SpriteBank.draw_disc(self, at + Vector2.from_angle(a) * (16.0 - 8.0 * k) + Vector2(0, -14), 1.5 + k, Color(Palette.INFERNO_CHARM_LIGHT, 0.4 + 0.5 * k))
		return
	var fade := clampf((reflect_until - now) / 0.5, 0.0, 1.0)
	var tint := Color(0.86, 0.78, 1.0, 0.55 * fade)  # A pale violet ghost of him.
	CharacterGlyphs.draw_player(self, game.character.id, at, game.player.radius, false, tint)  # His own look (the bound slot's character).
	SpriteBank.draw_disc(self, at + Vector2(0, -20), 3.0, Color(Palette.INFERNO_CHARM_LIGHT, 0.6 * fade))


# =====================================================================================
# The Twin Succubi, guests
# =====================================================================================

## Sends the two sisters from the spawn ring with their escort, bound together.
func _send_twins(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var kinds: Array = ev["kinds"]
	var apart := float(ev.get("apart", 90.0))
	var side := (game.player.position - at).normalized().orthogonal()
	var sisters: Array[Enemy] = []
	for i in kinds.size():
		var off := (float(i) - float(kinds.size() - 1) * 0.5) * apart
		var e := game.enemies.spawn_at(String(kinds[i]), at + side * off, false)
		if e != null:
			sisters.append(e)
	if sisters.size() == 2 and sisters[0].kit is TwinSuccubusKit and sisters[1].kit is TwinSuccubusKit:
		(sisters[0].kit as TwinSuccubusKit).bind_sister(sisters[1])
		(sisters[1].kit as TwinSuccubusKit).bind_sister(sisters[0])
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), at + Vector2.from_angle(randf() * TAU) * 40.0, bool(grp["elite"]))
	_log("twins")


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
	game.stat_add("silk_guest_squads", 1.0)
	game.stat_add("silk_guests_spawned", float(n))


## HUD objective while the twins or a reflection are about ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is TwinSuccubusKit:
		return "The Twin Succubi: they charm in turns. Kill one and the other rages"
	if _in_hall:
		return "The Hall of Mirrors: your reflections lure your dead astray"
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "events %s | hall of mirrors: reflections %d, summons lured %d | twins spawned %d, killed %d (rages %d, kisses %d, missed %d, kisses of pain %d hitting %d summons, ttk %.0fs) | lilim witches: curses %d (pits %d), portal rites %d (healed %d) | guests: %s, squads %d, spawned %d | objective ash %d" % [
		", ".join(fired) if not fired.is_empty() else "-",
		int(st.get("silk_reflections", 0.0)), int(st.get("silk_mirror_lured", 0.0)),
		int(st.get("twins_spawned", 0.0)), int(st.get("twins_killed", 0.0)), int(st.get("twin_rages", 0.0)),
		int(st.get("twin_kisses", 0.0)), int(st.get("twin_kiss_missed", 0.0)), int(st.get("twin_pains", 0.0)), int(st.get("twin_pain_hits", 0.0)),
		float(st.get("twins_ttk", 0.0)), int(st.get("lilim_curses", 0.0)), int(st.get("lilim_pits", 0.0)),
		int(st.get("lilim_rites", 0.0)), int(st.get("lilim_healed", 0.0)),
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("silk_guest_squads", 0.0)),
		int(st.get("silk_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
