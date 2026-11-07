## CastleSanguisDirector — the stage mechanics of CASTLE SANGUIS (Stage 21, the
## finale of Act VII; GDD §15.0 "Castle Sanguis (Act VII phase 2)";
## owner-approved proposal docs/act7/PROPOSAL.md "Stage 21: Castle Sanguis"),
## owned and stepped by EnemyDirector on a stage whose STAGE has a
## "castle_sanguis" config (CastleSanguisStage.CASTLE_SANGUIS; null elsewhere).
## The four zones are MarchDirector's (the clock is authoritative: the
## Courtyard, the Banquet Hall, the Crypt Gallery, the Throne of Blood); the
## Court's shared rules are Game.court's. This director runs:
##   * THE BANQUET: blood fountains (config "fountains") stand in the Banquet
##     Hall and before the Throne of Blood: `count` pools rise ring_min..
##     ring_max px from the necromancer (at least `spacing` apart), and one left
##     more than `keep` px behind dries up and rises again nearer. Every `tick`
##     s every COURT enemy (a CourtKit kind, or a boss that feeds) whose centre
##     stands in a pool drinks: `heal` x its max HP per second (boss_mult of
##     that for a boss or a miniboss), through CombatResolver.heal_enemy() (the
##     existing enemy heal path; owner-approved: "blood fountains in the hall
##     heal any Court enemy that stands in them"). THE ONE DENIAL CHECK,
##     denied(): a fountain is DENIED (nobody drinks; drawn dry and pale) while
##     a Bone Wall segment of any necromancer covers it (BoneWall.covers()) or
##     a Bone Golem (golem_classes) stands in it (owner-approved: "Bone Wall
##     segments or a Golem parked on a fountain deny it").
##   * THE CHIROPTERAN KING (the "chiropteran_king" timeline event): the
##     miniboss lands at the spawn ring with his escort (ChiropteranKingKit
##     registers him for the HUD bar; ChestManager drops his chest).
##   * GUEST SQUADS: the other Act VII stages' kinds (Ravensmoor's and the
##     Witchwood's, built in parallel) join small squads on a timer when this
##     build knows them (EnemyDirector.is_known_kind(); candidate ids per
##     kind, the first one known), as Pandemonium's guests, so the stage plays
##     the same before and after those stages merge.
## The fountains are drawn here (a structures/blood_fountain sprite, else
## CastleSanguisGlyphs.draw_fountain(); textures only), over the floor and
## under the obstacles and bodies. Deterministic: the seeded global RNG only
## (the fountains' places, the guests' roll, the spawn points). Stats:
## fountain_raised, fountain_moved, fountain_heal, fountain_drinks,
## fountain_heal_<kind>, fountain_denied_ticks, fountain_denied_wall,
## fountain_denied_golem, castle_guest_squads, castle_guests_spawned.
class_name CastleSanguisDirector
extends Node2D

## One blood fountain.
class Fountain:
	extends RefCounted
	## Its centre (world px).
	var at: Vector2 = Vector2.ZERO
	## True while it is denied (a Bone Wall segment or a Golem on it).
	var denied: bool = false
	## Game time it rose (drawn rising).
	var born: float = 0.0

## Owning run.
var game: Game
## The stage's config (CastleSanguisStage.CASTLE_SANGUIS).
var config: Dictionary = {}
## The fountains' numbers (config "fountains").
var fcfg: Dictionary = {}
## Standing fountains.
var fountains: Array[Fountain] = []
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Game time of the next guest squad.
var _next_guest: float = INF
## Guest squads sent so far (their size grows with it).
var _guest_squads: int = 0
## Seconds until the fountains' next heal tick.
var _tick: float = 0.0
## Fountains the current window wants (0 = none).
var _want: int = 0
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false
## Reusable query buffer.
var _buf: Array = []


func _ready() -> void:
	z_index = -7  # Over the floor (-10) and the Hell-Pit layer's slot (-8), under the obstacles (-6) and the bodies.
	z_as_relative = false
	fcfg = config.get("fountains", {})
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()
	if not fcfg.is_empty():
		_step_fountains(delta)


# =====================================================================================
# The Banquet: blood fountains
# =====================================================================================

## The fountains: how many stand now, keeping them near, and the drinking.
func _step_fountains(delta: float) -> void:
	_want = 0
	for w: Array in fcfg["windows"]:
		if game.elapsed >= float(w[0]) and game.elapsed < float(w[1]):
			_want = int(w[2])
	while fountains.size() > _want:
		fountains.pop_back()
	var p := game.player.position
	for f in fountains:
		if f.at.distance_to(p) > float(fcfg["keep"]):
			f.at = _fountain_point()
			f.born = game.elapsed
			game.stat_add("fountain_moved", 1.0)
	while fountains.size() < _want:
		var f := Fountain.new()
		f.at = _fountain_point()
		f.born = game.elapsed
		fountains.append(f)
		game.stat_add("fountain_raised", 1.0)
		if fountains.size() == 1 and game.elapsed - float(_window_start()) < 1.0:
			game.enemies.show_banner("Blood fountains run in the hall: the Court heals in them! Bone Walls and Golems deny them")
	_tick -= delta
	if _tick <= 0.0:
		_tick += float(fcfg["tick"])
		for f in fountains:
			f.denied = denied(f.at)
			if f.denied:
				game.stat_add("fountain_denied_ticks", 1.0)
			else:
				_drink(f)
	var busy := not fountains.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Start (game s) of the current fountain window (0 when none).
func _window_start() -> float:
	for w: Array in fcfg["windows"]:
		if game.elapsed >= float(w[0]) and game.elapsed < float(w[1]):
			return float(w[0])
	return 0.0


## A free place for a fountain: ring_min..ring_max px from the necromancer, at
## least `spacing` px from the others, off the obstacles (seeded RNG).
func _fountain_point() -> Vector2:
	var p := game.player.position
	var r := float(fcfg["radius"])
	var best := p + Vector2.RIGHT * float(fcfg["ring_min"])
	for _try in 8:
		var at := p + Vector2.from_angle(randf() * TAU) * randf_range(float(fcfg["ring_min"]), float(fcfg["ring_max"]))
		at = game.arena.free_point(at, r * 0.6)
		best = at
		var ok := true
		for f in fountains:
			if f.at.distance_to(at) < float(fcfg["spacing"]):
				ok = false
				break
		if ok:
			break
	return best


## THE ONE DENIAL CHECK of the Banquet: true while a Bone Wall segment of any
## necromancer covers the pool at `at` (BoneWall.covers()) or a Bone Golem
## (golem_classes) stands in it.
func denied(at: Vector2) -> bool:
	var r := float(fcfg["radius"])
	for ab in _all_abilities():
		var wall: BoneWall = ab.spells.nodes.get("bone_wall")  # Null until a wall exists.
		if wall != null and wall.covers(at, r):
			game.stat_add("fountain_denied_wall", 1.0)
			return true
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and u.state != SummonedUnit.State.DEAD and (fcfg["golem_classes"] as Array).has(u.unit_class) \
				and u.position.distance_to(at) <= r + u.radius * 0.5:
			game.stat_add("fountain_denied_golem", 1.0)
			return true
	return false


## Every necromancer's AbilityManager (co-op: both; solo: the one).
func _all_abilities() -> Array:
	if game.coop == null:
		return [game.abilities]
	var out: Array = []
	for s in game.coop.slots:
		out.append(s.abilities)
	return out


## One heal tick of fountain `f`: every Court enemy standing in it drinks.
func _drink(f: Fountain) -> void:
	var r := float(fcfg["radius"])
	var share := float(fcfg["heal"]) * float(fcfg["tick"])
	game.enemy_grid.query(f.at, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for e: Enemy in _buf:
		if not e.active or e.is_structure or e.position.distance_to(f.at) > r:
			continue
		if not (e.kit is CourtKit or Bloodfeast.share_of(e) > 0.0):
			continue
		var amt := e.max_hp * share * (float(fcfg["boss_mult"]) if (e.is_boss or e.is_miniboss) else 1.0)
		var got := game.combat.heal_enemy(e, amt)
		if got > 0.0:
			game.stat_add("fountain_drinks", 1.0)
			game.stat_add("fountain_heal", got)
			game.stat_add("fountain_heal_" + e.kind, got)


## Every fountain: a sprite (structures/blood_fountain) or the glyph, drawn dry
## and pale while denied, rising for its first half second. Visual only.
func _draw() -> void:
	for f in fountains:
		var k := clampf((game.elapsed - f.born) / 0.5, 0.0, 1.0)
		var tint := Color(0.6, 0.62, 0.7, k) if f.denied else Color(1.0, 1.0, 1.0, k)
		var r := float(fcfg["radius"])
		draw_texture_rect(SpriteBank.disc(), Rect2(f.at - Vector2(r, r * 0.55), Vector2(r * 2.0, r * 1.1)), false,
				Color(Palette.COURT_BLOOD_DARK if not f.denied else Palette.COURT_MOON_DARK, 0.45 * k))  # The pool around it.
		if not SpriteBank.draw(self, CastleSanguisGlyphs.FOUNTAIN_SPRITE, f.at, false, tint):
			CastleSanguisGlyphs.draw_fountain(self, f.at, r, f.denied, k)


# =====================================================================================
# Events and guests
# =====================================================================================

## Runs a Castle Sanguis timeline event (EnemyDirector forwards "chiropteran_king").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"chiropteran_king":
			_send_king(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the miniboss from the spawn ring with his escort around him.
func _send_king(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("chiropteran_king")


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
	game.stat_add("castle_guest_squads", 1.0)
	game.stat_add("castle_guests_spawned", float(n))


## HUD objective while the King fights or the Queen kneels ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is ChiropteranKingKit:
		return "The Chiropteran King: shoot him down before he carries off your dead"
	var b := game.enemies.boss as BossCarmilla
	if b != null and b.active and b.is_kneeling():
		return "The Waking: stun her, chain her, kill the blood bearers before they reach her"
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	return "fountains raised %d, moved %d | drinks %d, healed %d (%s) | denied ticks %d (bone wall %d, golem %d) | guests: %s, squads %d, spawned %d | objective ash %d" % [
		int(st.get("fountain_raised", 0.0)), int(st.get("fountain_moved", 0.0)), int(st.get("fountain_drinks", 0.0)), int(st.get("fountain_heal", 0.0)),
		_heal_by_kind(st), int(st.get("fountain_denied_ticks", 0.0)), int(st.get("fountain_denied_wall", 0.0)), int(st.get("fountain_denied_golem", 0.0)),
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("castle_guest_squads", 0.0)),
		int(st.get("castle_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## "kind HP, ..." of the fountains' heals by kind (the biggest first).
static func _heal_by_kind(st: Dictionary) -> String:
	var rows: Array = []
	for k: String in st.keys():
		if k.begins_with("fountain_heal_"):
			rows.append([k.substr("fountain_heal_".length()), float(st[k])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]) or (float(a[1]) == float(b[1]) and String(a[0]) < String(b[0])))
	var out := PackedStringArray()
	for r: Array in rows:
		out.append("%s %d" % [String(r[0]), int(r[1])])
	return ", ".join(out) if not out.is_empty() else "none"


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
