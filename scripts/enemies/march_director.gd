## MarchDirector — the Crimson March's stage mechanics (GDD §8.2, §7.4),
## owned and stepped by EnemyDirector on stages whose StageRegistry `march`
## config is not empty. Data: CrimsonMarchStage (ZONES, MARCH, the
## "outposts" / "generators" / "cart" timeline events) and MarchEnemyData
## (the structures).
##   * Battle zones (open question 3, GDD §15.0: the clock is authoritative):
##     at each zone's start time the HUD announces the zone, a fog of war
##     sweeps the field, and the arena and ground switch to the next zone's
##     layout and look (Arena.set_layout(), MarchGround.set_zone()) with a
##     clear circle around the necromancer.
##   * Outposts      — "outposts spawn reinforcements until destroyed":
##                     watchtowers / siege outposts placed near the
##                     necromancer that send a squad every `interval` s
##                     while he is within MARCH.active_radius.
##   * Ward generators — "Holy Ward Generators damage/weaken summons in
##                     areas": each one sustains a StageDirector holy zone
##                     (burns and slows undead, stings the necromancer,
##                     blocks summon replacement) until it is destroyed.
##   * Supply carts  — "destroy enemy supply carts for optional rewards": a
##                     cart rolls past with an escort and escapes after its
##                     lifetime; destroying it pays an XP burst and a
##                     power-up (MARCH.cart_rewards, cycled, no RNG).
##   * Timed structures — Marshal Vael's Holy Standard is tracked here and
##                     taken off the field when its time runs out.
## The Sanctum of Judgment reuses the battle zones (its `march` config has
## zones and no road, outposts or carts) with its own zone-change look: the
## optional config keys zone_title, zone_color, fog_color and fog_bank_color
## (absent = the Crimson March's crimson banner and smoke).
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective:
## never recycled), so summons, spells, Stasis and the combat resolver treat
## them like any enemy; this director polls them (generation-checked) to pay
## the rewards once they fall. Deterministic: only the seeded global RNG.
class_name MarchDirector
extends Node2D

## One tracked structure (outpost, ward generator, cart or Holy Standard).
class Structure:
	extends RefCounted
	## "outpost", "generator", "cart" or "standard".
	var role: String = ""
	## The structure's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## The timeline event that placed it (rewards, squads; {} for a standard).
	var ev: Dictionary = {}
	## Last known world position (rewards spawn here once it falls).
	var pos: Vector2 = Vector2.ZERO
	## Game time of the next reinforcement squad (outposts).
	var next_spawn: float = 0.0
	## Seconds left before it leaves the field (carts, standards; INF = never).
	var life: float = INF

## Owning run.
var game: Game
## The stage's march config (CrimsonMarchStage.MARCH, SanctumStage.MARCH).
var config: Dictionary = {}
## Index of the current battle zone in config.zones.
var zone_index: int = 0
## Structures on the field.
var structures: Array[Structure] = []
## Log of march events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Seconds left of the fog-of-war sweep after a zone change (cosmetic).
var _transition_left: float = 0.0
## Index into config.cart_rewards of the next destroyed cart's power-up.
var _cart_reward_index: int = 0


func _ready() -> void:
	z_index = 4  # The fog sweep covers bodies; the HUD stays above it.


## Per-tick update, called by EnemyDirector after the StageDirector.
func step(delta: float) -> void:
	_update_zone()
	_step_structures(delta)
	if _transition_left > 0.0:
		_transition_left -= delta
		queue_redraw()


# =====================================================================================
# Battle zones
# =====================================================================================

## Advances to the last zone whose start time has come.
func _update_zone() -> void:
	var zones: Array = config["zones"]
	while zone_index + 1 < zones.size() and game.elapsed >= float(zones[zone_index + 1]["start"]):
		zone_index += 1
		_enter_zone(zones[zone_index])


## The march reaches zone `z`: announce it, sweep the fog and rebuild the
## terrain around the necromancer as the new zone.
func _enter_zone(z: Dictionary) -> void:
	var p := game.player.position
	game.arena.set_layout(z["arena"], p, float(z.get("clear", config["transition_clear"])))  # A zone may ask a wider clear circle (the Archive's Orrery).
	game.ground.set_zone(z["ground"])
	var title := String(config.get("zone_title", "THE MARCH ADVANCES  -  ZONE %s"))  # Banner title format.
	if game.hud != null:
		game.hud.announce(title % String(z["numeral"]), String(z["name"]), String(z["blurb"]), zone_color())
	_transition_left = float(config["transition_time"])
	game.effects.ring(p, 420.0, config.get("zone_color", Palette.CRIMSON), 0.9)
	game.stat_add("march_zones_entered", 1.0)
	_log("zone_" + String(z["numeral"]))


## Colour of the zone banner and HUD zone line (config zone_color; the
## Crimson March's light crimson by default).
func zone_color() -> Color:
	return config.get("zone_color", Palette.CRIMSON.lightened(0.35))


## HUD line under the timer: "Zone II - The Fortified Checkpoint".
func zone_label() -> String:
	var z: Dictionary = config["zones"][zone_index]
	return "Zone %s  -  %s" % [String(z["numeral"]), String(z["name"])]


# =====================================================================================
# Timeline events: outposts, ward generators, supply carts
# =====================================================================================

## Runs a Crimson March timeline event (EnemyDirector forwards the
## "outposts", "generators" and "cart" types; keys in CrimsonMarchStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"outposts":
			_place_structures(ev, "outpost")
		"generators":
			_place_structures(ev, "generator")
		"cart":
			_start_cart(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Places `ev.count` structures of `ev.kind` around the necromancer (spread
## evenly, at least MARCH.structure_spacing px apart, out of obstacles),
## plus the event's escort wave. Generators also get their holy zone.
func _place_structures(ev: Dictionary, role: String) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU
	var kind := String(ev["kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Body radius.
	var placed: Array[Vector2] = []
	for i in n:
		var pos := game.player.position
		for _try in 6:
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			pos = game.arena.free_point(game.player.position + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			if spaced:
				break
		placed.append(pos)
		var e := game.enemies.spawn_at(kind, pos, false)
		e.is_objective = true
		var s := _track(e, role, ev)
		if role == "outpost":
			s.next_spawn = game.elapsed + float(ev["interval"]) * 0.5
		elif role == "generator":
			var zone := game.enemies.stage.add_zone(pos, ev["zone"], "ward")
			game.enemies.stage.bind_zone(zone, e)
		game.effects.spawn_ring(pos, Palette.GOLD)
		game.stat_add("march_%ss_placed" % role, 1.0)
	var escort: Dictionary = ev.get("escort", {})
	if not escort.is_empty():
		game.enemies.spawn_formation(String(escort["formation"]), escort["groups"])
	_log("%ss_placed_%d" % [role, n])


## A supply cart rolls past the necromancer: it appears pass_distance px
## away on one side, pass_offset px off his line, and drives to the mirrored
## point on the other side (then waits) until its `lifetime` runs out; its
## escort spawns around it.
func _start_cart(ev: Dictionary) -> void:
	var kind := String(ev["kind"])
	var u := Vector2.from_angle(randf() * TAU)  # Travel direction.
	var v := Vector2(-u.y, u.x) * float(ev["pass_offset"])  # Lateral offset of the path.
	var p := game.player.position
	var reach := float(ev["pass_distance"])
	var e := game.enemies.spawn_at(kind, p - u * reach + v, false)
	e.is_objective = true
	e.post_pos = p + u * reach + v
	var s := _track(e, "cart", ev)
	s.life = float(ev["lifetime"])
	for grp: Dictionary in ev["escort"]:
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2(randf_range(-36.0, 36.0), randf_range(-36.0, 36.0)), bool(grp["elite"]))
	game.stat_add("march_carts_placed", 1.0)
	_log("cart_placed")


## Tracks a timed structure (Marshal Vael's Holy Standard): it leaves the
## field after `duration` s unless it is destroyed first.
func track_timed(e: Enemy, role: String, duration: float) -> void:
	var s := _track(e, role, {})
	s.life = duration


## Starts tracking structure `e` in `role`.
func _track(e: Enemy, role: String, ev: Dictionary) -> Structure:
	var s := Structure.new()
	s.role = role
	s.enemy = e
	s.gen = e.generation
	s.ev = ev
	s.pos = e.position
	structures.append(s)
	return s


## Outposts send squads, carts and standards age, and fallen structures pay
## their rewards.
func _step_structures(delta: float) -> void:
	var i := 0
	while i < structures.size():
		var s := structures[i]
		var e := s.enemy
		if not e.active or e.generation != s.gen:
			_on_destroyed(s)
			structures.remove_at(i)
			continue
		s.pos = e.position
		if s.role == "outpost" and game.elapsed >= s.next_spawn:
			s.next_spawn += float(s.ev["interval"])
			_send_squad(s)
		s.life -= delta
		if s.life <= 0.0:
			game.enemies.despawn(e)
			game.stat_add("march_%ss_escaped" % s.role, 1.0)
			if s.role == "cart":
				game.enemies.show_banner("The supply cart got away!")
			_log(s.role + "_gone")
			structures.remove_at(i)
			continue
		i += 1


## An outpost's reinforcement squad (only while the necromancer is within
## MARCH.active_radius and the enemy cap has room). Outposts are a continuous
## source like the trickle, so they stop at the segment's soft cap
## (EnemyDirector.soft_cap()); combined balance pass: they used to fill the
## field up to HARD_CAP - 10, so a struggling army that could not raze them
## faced up to 170 foes where the segment allows 64-145.
func _send_squad(s: Structure) -> void:
	var p := game.player.position
	if s.pos.distance_to(p) > float(config["active_radius"]):
		return
	var cap := mini(game.enemies.soft_cap(), game.enemies.hard_cap() - 10)  # Room for the squad.
	var spawned := 0  # Soldiers sent this time.
	for grp: Dictionary in s.ev["groups"]:
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= cap:
				break
			var at := s.pos + Vector2.from_angle(randf() * TAU) * (s.enemy.radius + 14.0)
			game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
			spawned += 1
	if spawned > 0:
		game.effects.spawn_ring(s.pos, Palette.CRIMSON)
		game.stat_add("march_outpost_reinforcements", float(spawned))


## A structure fell: XP burst (and a power-up for a cart), banner, stats.
func _on_destroyed(s: Structure) -> void:
	game.stat_add("march_%ss_destroyed" % s.role, 1.0)
	_log(s.role + "_destroyed")
	if s.ev.is_empty():
		return  # A Holy Standard: its own small XP crystal is enough.
	var xp := int(s.ev.get("reward_xp", 0))
	var n := maxi(1, int(s.ev.get("reward_crystals", 1)))
	if xp > 0:
		var each := maxi(1, floori(float(xp) / float(n)))
		for k in n:
			game.pickups.spawn(s.pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(16.0, 46.0), each)
	game.effects.impact(s.pos, 60.0, Palette.FLAME)
	if bool(s.ev.get("reward_chest", false)) and not game.countdown_finished():
		if game.chests.spawn_chest(s.pos, false):
			game.stat_add("march_structure_chests", 1.0)
	match s.role:
		"cart":
			var rewards: Array = config["cart_rewards"]
			var kind := String(rewards[_cart_reward_index % rewards.size()])
			_cart_reward_index += 1
			game.powerups.spawn_drop(kind, s.pos, true)
			game.enemies.show_banner("Supply cart destroyed: spoils for the dead!")
		"generator":
			game.enemies.show_banner("A ward generator shatters!")
		"outpost":
			game.enemies.show_banner("Outpost destroyed!")


## Records a march event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])


# =====================================================================================
# Queries for HUD and autopilot
# =====================================================================================

## Live structures with role `role`.
func count_role(role: String) -> int:
	var n := 0
	for s in structures:
		if s.role == role and s.enemy.active and s.enemy.generation == s.gen:
			n += 1
	return n


## HUD objective for the live march objective ("" if none): ward generators
## first, then outposts, then a cart about to escape.
func objective_override() -> String:
	var gens := count_role("generator")
	if gens > 0:
		return "Destroy the Holy Ward Generators (%d left)" % gens
	var outs := count_role("outpost")
	if outs > 0:
		return "Destroy the outposts before they flood the road (%d left)" % outs
	for s in structures:
		if s.role == "cart":
			return "A supply cart escapes in %d s: destroy it for spoils" % ceili(maxf(0.0, s.life))
	return ""


## Autopilot hint: the nearest live outpost, generator or cart within
## `reach` px of `p` (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for s in structures:
		if s.role == "standard":
			continue
		var d := p.distance_to(s.pos)
		if d < best_d:
			best_d = d
			best = s.pos
	return best


# =====================================================================================
# Drawing (fog-of-war sweep at a zone change)
# =====================================================================================

func _draw() -> void:
	if _transition_left <= 0.0:
		return
	var k := clampf(_transition_left / maxf(0.01, float(config["transition_time"])), 0.0, 1.0)  # 1 -> 0.
	var c := game.player.position
	var half := game.view_size() * 0.6 + Vector2.ONE * 80.0
	var veil: Color = config.get("fog_color", Color(0.05, 0.02, 0.03))  # Sweep veil colour.
	var bank: Color = config.get("fog_bank_color", Color(0.12, 0.05, 0.06))  # Drifting bank colour.
	draw_rect(Rect2(c - half, half * 2.0), Color(veil, 0.75 * k))
	# Drifting smoke banks clearing outward from the necromancer.
	for i in 10:
		var a := TAU * float(i) / 10.0
		var r := (1.0 - k) * half.length() * 0.9 + 60.0
		draw_circle(c + Vector2.from_angle(a) * r, 90.0, Color(bank, 0.45 * k))
