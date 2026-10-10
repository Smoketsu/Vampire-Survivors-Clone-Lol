## StageDirector — the Desecrated Graveyard's stage mechanics (GDD §11) and
## every holy ground hazard, owned by EnemyDirector and stepped by it once per
## tick. Data lives in WaveData (stage events) and EnemyData.BOSS (Alaric's
## Consecrated Ground / Call to Arms / Judgment telegraphs).
##   * Holy zones        — consecrated ground (GDD §10 "holy suppression /
##                         consecration zones apply localized temporary
##                         pressure"). Each zone is telegraphed while it arms,
##                         then burns and slows undead inside it, stings the
##                         necromancer, and blocks summon replacement inside
##                         it (local suppression) until it fades.
##   * Desecration       — "priests attempt to consecrate selected graves;
##                         failure to interrupt creates hazardous anti-undead
##                         spaces": marked graves, a Chaplain walks to each and
##                         channels; kill it to interrupt (XP reward), or the
##                         grave becomes a long-lived holy zone.
##   * Empowered graves  — "near the player add temporary reinforcements or
##                         improve summon replenishment": a glowing grave
##                         rises near the necromancer; walking onto it grants
##                         temporary summons (more of them later in the run)
##                         or refills the whole army.
##   * Crypt Defender    — "briefly awaken ancient guardian units": walking up
##                         to a crypt awakens strong temporary guardians.
##   * Marks             — purely visual boss telegraphs (Call to Arms rally
##                         banners, Judgment of the Dead sigils); BossAlaric
##                         keeps its own timers and applies the effects.
## Everything is drawn here in world space, under bodies and obstacles.
class_name StageDirector
extends Node2D

## Visual style of a boss mark.
enum MarkStyle { RALLY, JUDGMENT }

## One consecrated (holy) zone.
class HolyZone:
	extends RefCounted
	## World-space centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius in px.
	var radius: float = 60.0
	## Seconds left before the zone arms (telegraph); <= 0 once active.
	var arm_left: float = 0.0
	## Total arming time (for the telegraph fill).
	var arm_total: float = 1.0
	## Seconds the zone stays active after arming.
	var life: float = 10.0
	## Total active lifetime (for the fade).
	var life_total: float = 10.0
	## Damage per second to summons inside.
	var undead_dps: float = 0.0
	## Fraction of speed summons lose inside.
	var undead_slow: float = 0.0
	## Damage to the necromancer per player_interval inside.
	var player_damage: float = 0.0
	## Seconds between hits on the necromancer.
	var player_interval: float = 1.0
	## "boss" (Consecrated Ground) or "grave" (desecration event).
	var source: String = ""

## One visual boss telegraph mark.
class Mark:
	extends RefCounted
	## World-space centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius in px.
	var radius: float = 20.0
	## Seconds since it appeared.
	var t: float = 0.0
	## Seconds it is shown.
	var duration: float = 1.0
	## How it is drawn.
	var style: int = MarkStyle.RALLY

## A claimable shrine: an empowered grave or the Crypt Defender's crypt.
class Shrine:
	extends RefCounted
	## "empowered" or "crypt".
	var kind: String = "empowered"
	## World-space centre.
	var pos: Vector2 = Vector2.ZERO
	## Seconds left before it sinks unclaimed.
	var life: float = 20.0
	## Total lifetime (for the fade).
	var life_total: float = 20.0
	## Claim distance in px.
	var claim_radius: float = 30.0
	## Empowered grave reward: "reinforce" or "replenish" ("guardians" for
	## the crypt).
	var reward: String = ""

## A grave a Covenant consecrator is trying to consecrate.
class ConsecrationGrave:
	extends RefCounted
	## World-space grave position.
	var pos: Vector2 = Vector2.ZERO
	## The channelling Chaplain.
	var consecrator: Enemy = null
	## Generation of `consecrator` when it was assigned (stale guard).
	var consecrator_gen: int = 0
	## Seconds of channelling done so far.
	var channel: float = 0.0
	## True while the consecrator stands on the grave.
	var channelling: bool = false

## Owning run.
var game: Game
## Active or arming holy zones.
var zones: Array[HolyZone] = []
## Visible boss marks.
var marks: Array[Mark] = []
## Unclaimed empowered graves / crypts.
var shrines: Array[Shrine] = []
## Graves currently being consecrated.
var graves: Array[ConsecrationGrave] = []
## Log of stage events fired, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Game time the next empowered grave rises.
var _next_grave: float = float(WaveData.EMPOWERED_GRAVES["first"])
## Index into EMPOWERED_GRAVES.rewards of the next grave's reward.
var _reward_index: int = 0
## Seconds accumulated toward the next zone damage tick.
var _zone_tick: float = 0.0
## Seconds until a zone may hurt the necromancer again.
var _player_zone_cd: float = 0.0
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -7


# =====================================================================================
# Update
# =====================================================================================

## Per-tick update, called by EnemyDirector after the enemies moved.
func step(delta: float) -> void:
	var t := game.elapsed
	var eg: Dictionary = WaveData.EMPOWERED_GRAVES
	if t >= _next_grave and t <= float(eg["until"]):
		_next_grave += float(eg["interval"])
		_raise_empowered_grave()
	_step_shrines(delta)
	_step_graves(delta)
	_step_zones(delta)
	var hold := _boss_frozen()  # Boss marks pause while Sir Alaric is frozen.
	var i := 0
	while i < marks.size():
		if not hold:
			marks[i].t += delta
		if marks[i].t >= marks[i].duration:
			marks.remove_at(i)
		else:
			i += 1
	var busy := not (zones.is_empty() and marks.is_empty() and shrines.is_empty() and graves.is_empty())
	if busy or _drew:
		queue_redraw()
	_drew = busy


## True while Sir Alaric is held by a Stasis power-up: his marks (Call to
## Arms, Judgment) and the arming of his Consecrated Ground zones pause.
func _boss_frozen() -> bool:
	var b := game.enemies.boss  # Sir Alaric (null before he arrives).
	return b != null and b.active and b.frozen


## Records a fired stage event for the autotest summary and stats.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
	game.stat_add("event_" + event_name, 1.0)


# =====================================================================================
# Holy zones
# =====================================================================================

## Adds a holy zone at `pos` from a zone definition (keys documented at
## WaveData.CONSECRATION.zone). `source` tags it ("boss" / "grave").
func add_zone(pos: Vector2, def: Dictionary, source: String) -> void:
	var z := HolyZone.new()
	z.pos = pos
	z.radius = float(def["radius"])
	z.arm_total = maxf(0.05, float(def["arm_time"]))
	z.arm_left = z.arm_total
	z.life_total = float(def["duration"])
	z.life = z.life_total
	z.undead_dps = float(def["undead_dps"])
	z.undead_slow = float(def["undead_slow"])
	z.player_damage = float(def["player_damage"])
	z.player_interval = float(def["player_interval"])
	z.source = source
	zones.append(z)
	game.stat_add("holy_zones_" + source, 1.0)


## True if `pos` lies inside a holy zone (armed or arming). Summon
## replacement never spawns there (local suppression).
func in_holy_zone(pos: Vector2) -> bool:
	for z in zones:
		if pos.distance_to(z.pos) <= z.radius:
			return true
	return false


## Arms, ages and applies every holy zone.
func _step_zones(delta: float) -> void:
	_player_zone_cd -= delta
	var boss_hold := _boss_frozen()  # Boss zones do not arm while he is frozen.
	var i := 0
	while i < zones.size():
		var z := zones[i]
		if z.arm_left > 0.0:
			if boss_hold and z.source == "boss":
				i += 1
				continue
			z.arm_left -= delta
			if z.arm_left <= 0.0:
				game.effects.ring(z.pos, z.radius, Palette.GOLD, 0.35)
		else:
			z.life -= delta
		if z.life <= 0.0:
			zones.remove_at(i)
		else:
			i += 1
	_zone_tick += delta
	var tick := _zone_tick >= WaveData.ZONE_TICK
	if tick:
		_zone_tick -= WaveData.ZONE_TICK
	var player := game.player
	for z in zones:
		if z.arm_left > 0.0:
			continue
		if _player_zone_cd <= 0.0 and player.position.distance_to(z.pos) <= z.radius + player.radius * 0.5:
			_player_zone_cd = z.player_interval
			game.combat.damage_player(z.player_damage * game.enemies.damage_mult, "holy_zone")
		if not tick:
			continue
		game.ally_grid.query(z.pos, z.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(z.pos) > z.radius:
				continue
			u.holy_slow = maxf(u.holy_slow if u.holy_slow_timer > 0.0 else 0.0, z.undead_slow)
			u.holy_slow_timer = WaveData.ZONE_SLOW_LINGER
			game.combat.damage_unit(u, z.undead_dps * WaveData.ZONE_TICK, "holy_zone")


# =====================================================================================
# Boss marks
# =====================================================================================

## Shows a boss telegraph mark at `pos` for `duration` seconds.
func add_mark(pos: Vector2, radius: float, duration: float, style: MarkStyle) -> void:
	var m := Mark.new()
	m.pos = pos
	m.radius = radius
	m.duration = maxf(duration, 0.05)
	m.style = style
	marks.append(m)


# =====================================================================================
# Empowered graves and the Crypt Defender
# =====================================================================================

## A free spot `dmin`..`dmax` px from the necromancer: outside obstacles and
## holy zones (best effort after a few tries).
func _free_spot(dmin: float, dmax: float, r: float) -> Vector2:
	var p := game.player.position
	var pos := p
	for _i in 8:
		pos = game.arena.free_point(p + Vector2.from_angle(randf() * TAU) * randf_range(dmin, dmax), r)
		if not in_holy_zone(pos):
			return pos
	return pos


## Raises the next empowered grave near the necromancer.
func _raise_empowered_grave() -> void:
	var eg: Dictionary = WaveData.EMPOWERED_GRAVES
	var s := Shrine.new()
	s.kind = "empowered"
	s.pos = _free_spot(float(eg["distance_min"]), float(eg["distance_max"]), 16.0)
	s.life_total = float(eg["lifetime"])
	s.life = s.life_total
	s.claim_radius = float(eg["claim_radius"])
	var rewards: Array = eg["rewards"]
	s.reward = String(rewards[_reward_index % rewards.size()])
	_reward_index += 1
	shrines.append(s)
	game.enemies.show_banner("An empowered grave rises nearby!")
	_log("empowered_grave_risen")


## Starts the Crypt Defender event (WaveData.EVENTS "crypt").
func start_crypt(ev: Dictionary) -> void:
	var cd: Dictionary = WaveData.CRYPT_DEFENDER
	var s := Shrine.new()
	s.kind = "crypt"
	s.pos = _free_spot(float(cd["distance_min"]), float(cd["distance_max"]), 22.0)
	s.life_total = float(cd["lifetime"])
	s.life = s.life_total
	s.claim_radius = float(cd["claim_radius"])
	s.reward = "guardians"
	shrines.append(s)
	game.enemies.show_banner(String(ev["banner"]))
	_log("crypt_defender_started")


## Ages shrines and claims the ones the necromancer reaches.
func _step_shrines(delta: float) -> void:
	var p := game.player.position
	var i := 0
	while i < shrines.size():
		var s := shrines[i]
		s.life -= delta
		if p.distance_to(s.pos) <= s.claim_radius:
			_claim(s)
			shrines.remove_at(i)
		elif s.life <= 0.0:
			_log(s.kind + "_expired")
			shrines.remove_at(i)
		else:
			i += 1


## Applies a claimed shrine's reward.
func _claim(s: Shrine) -> void:
	game.effects.ring(s.pos, s.claim_radius * 2.5, Palette.NECRO_GREEN, 0.5)
	match s.reward:
		"reinforce":
			var eg: Dictionary = WaveData.EMPOWERED_GRAVES
			# Temporary summons for this grave: the base count plus the per-minute growth.
			var count := int(eg["reinforce_count"]) + floori(game.elapsed / 60.0 * float(eg["reinforce_growth"]))
			_spawn_temporaries(s.pos, String(eg["reinforce_class"]), count, float(eg["reinforce_duration"]),
					float(eg["reinforce_hp_mult"]), float(eg["reinforce_damage_mult"]))
			game.enemies.show_banner("The grave answers: the dead rise to fight!")
		"replenish":
			var h := game.horde
			var refilled := 0
			for cls: String in UnitData.CLASS_ORDER:
				var missing := h.capacity(cls) - h.count_of(cls)
				if missing > 0:
					h.immediate_spawns[cls] = missing
					refilled += missing
			game.stat_add("grave_replenished_units", float(refilled))
			game.enemies.show_banner("The grave answers: your fallen return at once!")
		"guardians":
			var cd: Dictionary = WaveData.CRYPT_DEFENDER
			_spawn_temporaries(s.pos, String(cd["guardian_class"]), int(cd["guardian_count"]), float(cd["guardian_duration"]),
					float(cd["guardian_hp_mult"]), float(cd["guardian_damage_mult"]))
			game.enemies.show_banner("The ancient guardians awaken!")
	_log(s.kind + "_claimed_" + s.reward)


## Spawns `count` temporary summons of `cls` around `pos`.
func _spawn_temporaries(pos: Vector2, cls: String, count: int, duration: float, hp_mult: float, dmg_mult: float) -> void:
	for i in count:
		var at := pos + Vector2.from_angle(TAU * float(i) / float(maxi(1, count))) * 22.0
		game.horde.spawn_temporary(cls, at, duration, hp_mult, dmg_mult)


# =====================================================================================
# Desecration (grave consecration) events
# =====================================================================================

## Starts a desecration event (WaveData.EVENTS "consecration"): marks graves
## around the necromancer and sends a consecrator (+ escort) to each one from
## the spawn ring in that direction.
func start_consecration(ev: Dictionary) -> void:
	var c: Dictionary = WaveData.CONSECRATION
	var n := int(ev["graves"])
	var offset := randf() * TAU
	var p := game.player.position
	var ed := game.enemies
	for i in n:
		var a := offset + TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
		var g := ConsecrationGrave.new()
		g.pos = game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(c["grave_distance_min"]), float(c["grave_distance_max"])), 16.0)
		var start := ed.ring_point(a)
		var e := ed.spawn_at(String(c["consecrator_kind"]), start, false)
		e.max_hp *= float(c["consecrator_hp_mult"])
		e.hp = e.max_hp
		e.behavior = "consecrator"
		e.post_pos = g.pos
		e.is_objective = true
		e.target_priority = 1.0
		g.consecrator = e
		g.consecrator_gen = e.generation
		graves.append(g)
		for grp: Dictionary in ev["escort"]:
			for _k in int(grp["count"]):
				if ed.regular_alive() >= WaveData.HARD_CAP:
					break
				ed.spawn_at(String(grp["kind"]), start + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0)), bool(grp["elite"]))
	ed.show_banner(String(ev["banner"]))
	_log("desecration_started")


## Advances every consecration: channel while the consecrator stands on its
## grave; its death interrupts, a full channel consecrates the grave.
func _step_graves(delta: float) -> void:
	var c: Dictionary = WaveData.CONSECRATION
	var i := 0
	while i < graves.size():
		var g := graves[i]
		var e := g.consecrator
		if not e.active or e.generation != g.consecrator_gen:
			_interrupt(g)
			graves.remove_at(i)
			continue
		# A consecrator frozen by Stasis does not channel.
		g.channelling = not e.frozen and e.position.distance_to(g.pos) <= float(c["post_radius"]) + e.radius
		if g.channelling:
			g.channel += delta
			if g.channel >= float(c["channel_time"]):
				add_zone(g.pos, c["zone"], "grave")
				e.behavior = "healer"
				e.is_objective = false
				game.enemies.show_banner("A grave has been consecrated: holy ground!")
				_log("grave_consecrated")
				graves.remove_at(i)
				continue
		i += 1


## The consecrator died: the grave is saved and spills XP.
func _interrupt(g: ConsecrationGrave) -> void:
	var c: Dictionary = WaveData.CONSECRATION
	var n := int(c["interrupt_crystals"])
	var each := maxi(1, floori(float(c["interrupt_xp"]) / float(n)))
	for k in n:
		game.pickups.spawn(g.pos + Vector2.from_angle(TAU * float(k) / float(n)) * 14.0, each)
	game.effects.ring(g.pos, 40.0, Palette.NECRO_GREEN, 0.4)
	game.enemies.show_banner("Consecration interrupted!")
	_log("consecration_interrupted")


# =====================================================================================
# Queries for HUD and autopilot
# =====================================================================================

## HUD objective text for an ongoing stage objective ("" if none).
func objective_override() -> String:
	if not graves.is_empty():
		return "Interrupt the consecration: slay the Chaplains at the marked graves (%d left)" % graves.size()
	for s in shrines:
		if s.kind == "crypt":
			return "An ancient crypt stirs: walk to it to awaken its guardians"
	if not shrines.is_empty():
		return "An empowered grave glows nearby: walk onto it"
	return ""


## Autopilot hint: push away from holy zones (armed or arming) near `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for z in zones:
		var diff := p - z.pos
		var d := diff.length()
		var r := z.radius + 24.0
		if d < r:
			push += (diff / d if d > 0.1 else Vector2.RIGHT) * (1.0 - d / r * 0.5)
	return push.limit_length(1.0)


## Autopilot hint: the nearest objective worth walking to (an unclaimed
## shrine, else, if `include_graves`, a grave being consecrated) within
## `reach` px of `p`; Vector2.INF when there is none.
func seek_point(p: Vector2, reach: float, include_graves: bool) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for s in shrines:
		var d := p.distance_to(s.pos)
		if d < best_d:
			best_d = d
			best = s.pos
	if best != Vector2.INF or not include_graves:
		return best
	for g in graves:
		var d := p.distance_to(g.pos)
		if d < best_d:
			best_d = d
			best = g.pos
	return best


# =====================================================================================
# Drawing (world space)
# =====================================================================================

func _draw() -> void:
	var now := game.elapsed
	for z in zones:
		_draw_zone(z, now)
	for g in graves:
		_draw_grave(g, now)
	for s in shrines:
		_draw_shrine(s, now)
	for m in marks:
		_draw_mark(m, now)


## Holy zone: while arming, a gold warning ring with a growing disc; once
## armed, a pulsing radiant disc with spokes, fading out at the end.
func _draw_zone(z: HolyZone, now: float) -> void:
	if z.arm_left > 0.0:
		var k := 1.0 - z.arm_left / z.arm_total
		draw_circle(z.pos, z.radius, Color(Palette.GOLD, 0.10))
		draw_circle(z.pos, z.radius * k, Color(Palette.GOLD, 0.22))
		draw_arc(z.pos, z.radius, 0.0, TAU, 48, Color(Palette.GOLD, 0.9), 2.0)
		return
	var fade := clampf(z.life, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(now * 4.0 + z.pos.x * 0.01)
	draw_circle(z.pos, z.radius, Color(Palette.GOLD, (0.14 + 0.06 * pulse) * fade))
	draw_arc(z.pos, z.radius, 0.0, TAU, 48, Color(Palette.IVORY, 0.75 * fade), 2.0)
	draw_arc(z.pos, z.radius * 0.6, 0.0, TAU, 32, Color(Palette.GOLD, 0.35 * fade), 1.0)
	var rot := now * 0.4
	for i in 8:
		var dir := Vector2.from_angle(rot + TAU * float(i) / 8.0)
		draw_line(z.pos + dir * z.radius * 0.25, z.pos + dir * z.radius * 0.92, Color(Palette.GOLD, 0.30 * fade), 2.0)
	draw_rect(Rect2(z.pos + Vector2(-2, -9), Vector2(4, 18)), Color(Palette.IVORY, 0.8 * fade))
	draw_rect(Rect2(z.pos + Vector2(-6, -4), Vector2(12, 4)), Color(Palette.IVORY, 0.8 * fade))


## Grave under consecration: a gold target ring, and a channel progress arc
## while the Chaplain stands on it.
func _draw_grave(g: ConsecrationGrave, now: float) -> void:
	var c: Dictionary = WaveData.CONSECRATION
	var r := float(c["zone"]["radius"])
	var blink := 0.5 + 0.5 * sin(now * 6.0)
	draw_arc(g.pos, r, 0.0, TAU, 48, Color(Palette.GOLD, 0.25 + 0.25 * blink), 1.5)
	draw_rect(Rect2(g.pos + Vector2(-9, -6), Vector2(18, 12)), Color(0.05, 0.05, 0.06))
	draw_rect(Rect2(g.pos + Vector2(-9, -6), Vector2(18, 12)), Palette.GOLD, false, 1.5)
	var k := clampf(g.channel / float(c["channel_time"]), 0.0, 1.0)
	draw_arc(g.pos, 24.0, -PI / 2.0, -PI / 2.0 + TAU, 32, Color(0, 0, 0, 0.5), 5.0)
	if k > 0.0:
		draw_arc(g.pos, 24.0, -PI / 2.0, -PI / 2.0 + TAU * k, 32, Palette.GOLD, 4.0)
	if g.channelling:
		draw_line(g.pos, g.pos + Vector2(0, -40.0 - 10.0 * blink), Color(Palette.IVORY, 0.6), 3.0)


## Empowered grave (green-glowing open grave) or crypt (stone door with
## runes), with the claim ring; both fade in their last seconds.
func _draw_shrine(s: Shrine, now: float) -> void:
	var fade := clampf(s.life / 3.0, 0.25, 1.0)
	var pulse := 0.5 + 0.5 * sin(now * 5.0)
	draw_circle(s.pos, s.claim_radius * 1.6, Color(Palette.NECRO_GREEN, (0.06 + 0.06 * pulse) * fade))
	draw_arc(s.pos, s.claim_radius, 0.0, TAU, 32, Color(Palette.NECRO_GREEN, 0.8 * fade), 2.0)
	if s.kind == "crypt":
		var door := Rect2(s.pos + Vector2(-14, -18), Vector2(28, 30))
		draw_rect(door.grow(3.0), Color(0.06, 0.06, 0.07))
		draw_rect(door, Palette.STONE)
		draw_circle(s.pos + Vector2(0, -18), 14.0, Palette.STONE)
		draw_line(s.pos + Vector2(0, -26), s.pos + Vector2(0, 12), Color(0.06, 0.06, 0.07), 2.0)
		for i in 3:
			draw_circle(s.pos + Vector2(-7 + 7 * i, -6), 2.0, Color(Palette.NECRO_GREEN, (0.5 + 0.5 * pulse) * fade))
	else:
		draw_rect(Rect2(s.pos + Vector2(-9, -6), Vector2(18, 12)), Color(0.04, 0.08, 0.06))
		draw_rect(Rect2(s.pos + Vector2(-9, -6), Vector2(18, 12)), Color(Palette.NECRO_GREEN, fade), false, 1.5)
		draw_line(s.pos + Vector2(0, -2), s.pos + Vector2(0, -22 - 6.0 * pulse), Color(Palette.NECRO_GREEN, 0.6 * fade), 3.0)
		Glyphs.draw_icon(self, "warrior" if s.reward == "reinforce" else "soul_recycling", Rect2(s.pos + Vector2(-7, -40), Vector2(14, 14)))


## Boss marks: a crimson rally banner (Call to Arms) or an ivory judgment
## sigil filling up until the light falls (Judgment of the Dead).
func _draw_mark(m: Mark, now: float) -> void:
	var k := clampf(m.t / m.duration, 0.0, 1.0)
	if m.style == MarkStyle.RALLY:
		draw_arc(m.pos, m.radius * (1.6 - 0.6 * k), 0.0, TAU, 20, Color(Palette.CRIMSON, 0.9), 2.0)
		draw_line(m.pos + Vector2(0, 6), m.pos + Vector2(0, -22), Palette.SILVER, 2.0)
		draw_colored_polygon(PackedVector2Array([m.pos + Vector2(1, -22), m.pos + Vector2(13, -18), m.pos + Vector2(1, -13)]), Palette.CRIMSON)
		return
	draw_circle(m.pos, m.radius, Color(Palette.IVORY, 0.08))
	draw_circle(m.pos, m.radius * k, Color(Palette.IVORY, 0.22))
	draw_arc(m.pos, m.radius, 0.0, TAU, 40, Color(Palette.IVORY, 0.9), 2.0)
	var rot := now * 1.5
	for i in 4:
		var dir := Vector2.from_angle(rot + TAU * float(i) / 4.0)
		draw_line(m.pos + dir * m.radius * 0.3, m.pos + dir * m.radius * 0.85, Color(Palette.GOLD, 0.8), 2.0)
	draw_arc(m.pos, m.radius * 0.3, 0.0, TAU, 16, Color(Palette.GOLD, 0.8), 1.5)
