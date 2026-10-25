## UnderworldDirector — the stage mechanics of THE ASPHODEL UNDERWORLD (Stage 12,
## the Act IV finale; GDD §15.0 "The Asphodel Underworld (Act IV phase 2)";
## owner-approved proposal docs/act4/PROPOSAL.md "Stage 12"), owned and stepped
## by EnemyDirector on a stage whose STAGE has an "underworld" config
## (UnderworldStage.UNDERWORLD; null elsewhere). The four zones are
## MarchDirector's (the clock is authoritative); this director reads the current
## zone (MarchDirector.zone_index):
##   * THE STYX (a zone's "styx": true; the Styx Crossing and the Throne of
##     Hades): bands of black water cross the land (world y, every styx.period
##     px, meandering along x: river_offset(), the one geometry the floor draws
##     too). Every styx.check_every s, whoever wades it:
##       - the LIVING are slowed: the necromancer through TerrainSlow.slow_player()
##         (the one ground-slow path: Brinewalker applies), enemies through their
##         own Enemy.apply_slow() (floating shades, structures, the boss and
##         minibosses are not slowed: they do not wade);
##       - the DEAD FORGET (owner-approved proposal: "a summon wading it is
##         suppressed for 2 s, through the existing add_suppression() path"): a
##         summon in the water lays a suppression zone on its stretch of river
##         (HordeDirector.add_suppression(), the one path; one zone per
##         styx.forget_cell px cell at most every forget_time s) for forget_time
##         s. It is an effect of the ground on everyone standing in it, not a
##         summon rule: summons work the same on every stage.
##   * CERBERUS (the "cerberus" timeline event): the miniboss bounds in from the
##     spawn ring with his escort (CerberusKit registers him for the HUD bar,
##     raises his three heads; ChestManager drops his chest).
##   * GUEST SQUADS: the earlier Act IV stages' kinds (the Shores of Ilion's and
##     Mount Olympus's) join small squads on a timer when this build knows them
##     (EnemyDirector.is_known_kind(); candidate ids per kind), like the Iron
##     Citadel's guests, so the stage plays the same before and after those
##     stages merge.
## Deterministic: the seeded global RNG only (the guests' roll, the spawn
## points); the Styx is pure geometry. Stats: styx_checks, styx_player_wading
## (checks that found him in the water), styx_enemy_slows, styx_forget_zones,
## styx_summons_wading (summon-checks in the water), underworld_guest_squads,
## underworld_guests_spawned, cerberus_spawned (CerberusKit).
class_name UnderworldDirector
extends Node2D

## Owning run.
var game: Game
## The stage's underworld config (UnderworldStage.UNDERWORLD).
var config: Dictionary = {}
## Guest kinds this build knows: [real kind id, weight] (filled in _ready()).
var guests: Array = []
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Zone index the systems below last saw (MarchDirector.zone_index).
var _zone: int = 0
## True while the current zone has the Styx.
var styx_on: bool = false
## Seconds until the next Styx check.
var _styx_cd: float = 0.0
## River cell -> game time its forget zone ends (one zone per cell at a time).
var _forget_cells: Dictionary = {}
## Game time of the next guest squad.
var _next_guest: float = INF
## Guest squads sent so far (their size grows with it).
var _guest_squads: int = 0
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	_next_guest = float(config["guest_first"])
	for g: Dictionary in config["guests"]:
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				guests.append([id, float(g["weight"])])
				break
	_enter_zone(0)


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var z := game.enemies.march.zone_index if game.enemies.march != null else 0  # Current zone.
	if z != _zone:
		_enter_zone(z)
	if styx_on:
		_styx_cd -= delta
		if _styx_cd <= 0.0:
			_styx_cd += float(config["styx"]["check_every"])
			_styx_check()
	if not guests.is_empty() and game.elapsed >= _next_guest and game.elapsed <= float(config["guest_until"]):
		_next_guest += float(config["guest_interval"])
		_send_guests()


## Runs an underworld timeline event (EnemyDirector forwards "cerberus").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"cerberus":
			_send_cerberus(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Starts zone `z`'s systems (ZONES "styx").
func _enter_zone(z: int) -> void:
	_zone = z
	var zones: Array = config["zones"]
	var zd: Dictionary = zones[clampi(z, 0, zones.size() - 1)]
	var was := styx_on
	styx_on = bool(zd.get("styx", false))
	_styx_cd = 0.0
	if styx_on and not was and z > 0:
		_log("styx")


# =====================================================================================
# The Styx
# =====================================================================================

## Signed distance (px, along world y) from `p` to the centre line of the
## nearest band of the river with settings `s` (UnderworldStage.UNDERWORLD
## "styx"): |value| <= half_width means `p` is in the water. Static, so the
## floor (UnderworldGround) draws exactly the same river.
static func river_offset(p: Vector2, s: Dictionary) -> float:
	var period := float(s["period"])
	var amp := float(s["amplitude"])
	var wl := float(s["wavelength"])
	var ph := float(s["phase_step"])
	var k0 := roundi(p.y / period)  # The nearest band's index (before the meander).
	var best := INF
	for k in range(k0 - 1, k0 + 2):
		var cy := river_centre_y(p.x, k, period, amp, wl, ph)
		var off := p.y - cy
		if absf(off) < absf(best):
			best = off
	return best


## World y (px) of band `k`'s centre line at world x `x`.
static func river_centre_y(x: float, k: int, period: float, amp: float, wl: float, ph: float) -> float:
	return float(k) * period + amp * sin(x * TAU / wl + float(k) * ph)


## True when a body of radius `r` at `p` stands in the river (its centre
## inside the water, less a third of its body: the bank is shallow).
func in_river(p: Vector2, r: float) -> bool:
	return absf(river_offset(p, config["styx"])) <= float(config["styx"]["half_width"]) - r * 0.33


## One check of who wades the river (see the header).
func _styx_check() -> void:
	var s: Dictionary = config["styx"]
	var linger := float(s["linger"]) + float(s["check_every"])  # A slow lasts to the next check and a little more.
	game.stat_add("styx_checks", 1.0)
	# The necromancer(s): co-op binds each slot so TerrainSlow reads its own.
	for pl in game.all_players:
		if not in_river(pl.position, pl.radius):
			continue
		game.stat_add("styx_player_wading", 1.0)
		if game.coop == null:
			TerrainSlow.slow_player(game, float(s["slow_player"]), linger)
		else:
			var prev := game.coop.bound
			game.coop.bind(game.coop.slot_of(pl))
			TerrainSlow.slow_player(game, float(s["slow_player"]), linger)
			game.coop.bind(prev)
	# The living foes.
	for e in game.enemies.active:
		if not e.active or e.is_structure or e.is_boss or e.is_miniboss or e.floating or e.untargetable:
			continue
		if in_river(e.position, e.radius):
			e.apply_slow(float(s["slow_enemy"]), linger)
			game.stat_add("styx_enemy_slows", 1.0)
	# The dead forget: one suppression zone per river cell.
	var now := game.elapsed
	var cell := float(s["forget_cell"])
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
				continue
			if not in_river(u.position, u.radius):
				continue
			game.stat_add("styx_summons_wading", 1.0)
			var c := Vector2i(floori(u.position.x / cell), floori(u.position.y / cell))
			if float(_forget_cells.get(c, 0.0)) > now:
				continue
			_forget_cells[c] = now + float(s["forget_time"])
			var centre := (Vector2(c) + Vector2(0.5, 0.5)) * cell
			game.horde.add_suppression(centre, float(s["forget_radius"]), float(s["forget_time"]), float(s["forget_damage_mult"]), 0.0, "styx")
			game.stat_add("styx_forget_zones", 1.0)
	if _forget_cells.size() > 256:
		_prune_cells(now)


## Drops the river cells whose zone ended (keeps the map small).
func _prune_cells(now: float) -> void:
	for c: Vector2i in _forget_cells.keys():
		if float(_forget_cells[c]) <= now:
			_forget_cells.erase(c)


# =====================================================================================
# Cerberus and the guests
# =====================================================================================

## Sends the miniboss from the spawn ring with his escort around him.
func _send_cerberus(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("cerberus")


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
	game.stat_add("underworld_guest_squads", 1.0)
	game.stat_add("underworld_guests_spawned", float(n))


# =====================================================================================
# HUD, autopilot, summary
# =====================================================================================

## HUD objective while Cerberus hunts ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is CerberusKit:
		var left := 0
		for i in 3:
			if not (mb.kit as CerberusKit).head_dead(i):
				left += 1
		return "Kill the heads of Cerberus one by one (%d left)" % left
	return ""


## Autopilot hint: off the river toward the nearer bank while it slows him
## (Vector2.ZERO on dry ground or where no river flows).
func danger_push(p: Vector2) -> Vector2:
	if not styx_on:
		return Vector2.ZERO
	var s: Dictionary = config["styx"]
	var off := river_offset(p, s)
	var hw := float(s["half_width"])
	if absf(off) > hw + 8.0:
		return Vector2.ZERO
	return Vector2(0.0, 1.0 if off >= 0.0 else -1.0) * 0.6


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var names := PackedStringArray()
	for g: Array in guests:
		names.append(String(g[0]))
	var checks := maxf(1.0, float(st.get("styx_checks", 0.0)))
	return "styx: checks %d, you wading %d%% of them, enemy slows %d, summon-checks wading %d, forget zones %d (dmg prevented %d) | guests: %s, squads %d, spawned %d | objective ash %d" % [
		int(st.get("styx_checks", 0.0)), int(roundf(100.0 * float(st.get("styx_player_wading", 0.0)) / checks)),
		int(st.get("styx_enemy_slows", 0.0)), int(st.get("styx_summons_wading", 0.0)), int(st.get("styx_forget_zones", 0.0)),
		int(st.get("suppression_dmg_prevented", 0.0)),
		", ".join(names) if not names.is_empty() else "none in this build", int(st.get("underworld_guest_squads", 0.0)),
		int(st.get("underworld_guests_spawned", 0.0)), int(st.get("objective_ash", 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
