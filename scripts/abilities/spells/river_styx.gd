## RiverStyx — the River Styx spell (AbilityData "river_styx"; Act IV, the
## Asphodel Underworld; GDD §15.0 "River Styx, Lethe's Flood, Ferryman's Toll and
## the Ferrywoman"; owner-approved proposal: "a black river line that drains and
## slows whatever crosses it"; unlocked by defeating Hades, then offered on every
## stage at the later-item card weight). Every `cooldown` s it lays `rivers`
## river line(s) of black water across the way of the nearest foe within
## RiverStyxData.AIM_RANGE px: a segment `length` px long, `radius` px each side
## of its line, centred between the necromancer and that foe (OFFSET_SHARE of
## the way, at most MAX_OFFSET px out) and lying ACROSS the foe's path (the
## second river of Lethe's Flood crosses the first at a right angle). A river
## flows `duration` s; every `tick` s each foe in it is DRAINED (`damage`, the
## friendly damage path, CombatResolver.damage_enemy()) and SLOWED (`river_slow` for
## `slow_duration` s through CombatResolver.slow_enemy(): Spirit Binding and
## Mournsong apply as on every slow); the necromancer heals `drain_share` of the
## damage drained (CombatResolver.heal_player()), at most `drain_cap` HP a second.
## Evolved into LETHE'S FLOOD (EvolutionData "lethes_flood", detected by the
## "forget" key): two crossing rivers, wider, longer, harder, and a foe entering
## a river FORGETS: it is stunned `forget` s (CombatResolver.stun_enemy(): bosses
## and minibosses FORGET_BOSS_MULT of it, elites FORGET_ELITE_MULT), once per river.
## The Ferrywoman's innate (Ferry of Souls, innate values ferry_cooldown and
## ferry_life): a foe slain in one of her rivers rises as a temporary Risen
## (HordeDirector.spawn_temporary(), the one path: Restless Dead and the Grave
## Herald apply), at most once every ferry_cooldown s.
## Determinism: no RNG; the nearest foe by distance, ties in the spatial hash's
## order. Stats: styx_spell_rivers, styx_spell_drain_heal, styx_spell_forgets,
## ferry_risen; damage as dmg_river_styx / dmg_lethes_flood.
class_name RiverStyx
extends NecroSpell

## Flowing rivers: {a, b (world ends), r (half width px), t0, until (game
## times), touched (Dictionary Enemy -> generation: foes it already made
## forget), evolved (bool)}.
var rivers: Array[Dictionary] = []
## Seconds until the next cast.
var _cd: float = 0.0
## Seconds until the next drain tick.
var _tick: float = 0.0
## Game time the Ferrywoman's next Risen may rise.
var _ferry_ready: float = 0.0
## HP the drain healed in the current one-second window (capped at the
## row's drain_cap per window).
var _heal_window: float = 0.0
## Game time the current heal window started.
var _heal_window_t: float = 0.0
## True if the last redraw showed a river (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown, drains on its tick, dries the old rivers.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := rivers.size() - 1
	while i >= 0:
		if now >= float(rivers[i]["until"]):
			rivers.remove_at(i)
		i -= 1
	_cd -= delta
	if _cd <= 0.0:
		if _cast(stats):
			_cd = float(stats["cooldown"])
		else:
			_cd = AbilityData.SPELL_RETRY
	_tick -= delta
	if _tick <= 0.0:
		_tick += float(stats["tick"])
		if not rivers.is_empty():
			_drain(stats)
	if not rivers.is_empty() or _drawn:
		queue_redraw()
	_drawn = not rivers.is_empty()


## Lays the river(s) across the nearest foe's way. False when no foe is near.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position
	var e := _nearest(p, RiverStyxData.AIM_RANGE)
	if e == null:
		return false
	var to := e.position - p
	var d := to.length()
	var dir := to / d if d > 0.01 else Vector2.RIGHT
	var centre := p + dir * minf(d * RiverStyxData.OFFSET_SHARE, RiverStyxData.MAX_OFFSET)
	var evolved := stats.has("forget")
	var n := int(stats["rivers"])
	var half := float(stats["length"]) * 0.5
	for k in n:
		var along := dir.orthogonal() if k % 2 == 0 else dir  # Across the foe's way; the second crosses it.
		if rivers.size() >= RiverStyxData.MAX_RIVERS:
			rivers.remove_at(0)  # The oldest dries up.
		rivers.append({"a": centre - along * half, "b": centre + along * half, "r": float(stats["radius"]),
			"t0": game.elapsed, "until": game.elapsed + float(stats["duration"]), "touched": {}, "evolved": evolved})
		game.stat_add("styx_spell_rivers", 1.0)
	Sfx.play("plague_cloud", centre, 0.7)  # A startup-bank sound: the spell plays on every stage.
	return true


## The nearest open foe within `reach` px of `p` (null when none).
func _nearest(p: Vector2, reach: float) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	game.enemy_grid.query(p, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e):
			continue
		var dd := p.distance_to(e.position)
		if dd < best_d:
			best_d = dd
			best = e
	return best


## One drain tick of every river: each foe in it once (a foe in two rivers is
## drained by each, Lethe's crossing).
func _drain(stats: Dictionary) -> void:
	var src := RiverStyxData.EVOLVED_SOURCE if stats.has("forget") else RiverStyxData.SOURCE
	var dmg := float(stats["damage"])
	var drained := 0.0  # Damage drained this tick.
	for rv in rivers:
		var a: Vector2 = rv["a"]
		var b: Vector2 = rv["b"]
		var r := float(rv["r"])
		var hits: Array = []  # Own buffer: kill hooks may query the grid again.
		game.enemy_grid.query(a.lerp(b, 0.5), a.distance_to(b) * 0.5 + r + ProjectileManager.MAX_BODY_RADIUS, hits)
		var touched: Dictionary = rv["touched"]
		for e: Enemy in hits:
			if not e.active or DivineWrath._seg_dist(e.position, a, b) > r + e.radius:
				continue
			if bool(rv["evolved"]) and int(touched.get(e, -1)) != e.generation:
				touched[e] = e.generation
				if game.combat.stun_enemy(e, float(stats["forget"]), RiverStyxData.FORGET_BOSS_MULT, RiverStyxData.FORGET_ELITE_MULT) > 0.0:
					game.stat_add("styx_spell_forgets", 1.0)
			game.combat.slow_enemy(e, float(stats["river_slow"]), float(stats["slow_duration"]))
			drained += game.combat.damage_enemy(e, dmg, src)
	if drained > 0.0:
		var now := game.elapsed
		if now - _heal_window_t >= 1.0:
			_heal_window_t = now
			_heal_window = 0.0
		var heal := minf(drained * float(stats["drain_share"]), maxf(0.0, float(stats["drain_cap"]) - _heal_window))
		if heal > 0.0:
			_heal_window += heal
			game.stat_add("styx_spell_drain_heal", game.combat.heal_player(heal))


## True when `pos` (a body of radius `r`) lies in one of the rivers.
func in_river(pos: Vector2, r: float) -> bool:
	for rv in rivers:
		if DivineWrath._seg_dist(pos, rv["a"], rv["b"]) <= float(rv["r"]) + r:
			return true
	return false


## The Ferrywoman's Ferry of Souls: a foe slain in her river rises as a
## temporary Risen (once every ferry_cooldown s).
func on_enemy_killed(e: Enemy) -> void:
	var cd := game.character.innate_value("ferry_cooldown")  # 0 for every other character.
	if cd <= 0.0 or game.elapsed < _ferry_ready or rivers.is_empty() or e.is_structure:
		return
	if not in_river(e.position, e.radius):
		return
	_ferry_ready = game.elapsed + cd
	if game.horde.spawn_temporary(RiverStyxData.FERRY_CLASS, e.position, game.character.innate_value("ferry_life"), 1.0, 1.0) != null:
		game.stat_add("ferry_risen", 1.0)


## Autotest counters (the River Styx line of UnderworldReport).
func summary_extra() -> String:
	var st := game.stats
	return "rivers=%d forgets=%d drain_heal=%d ferry_risen=%d" % [int(st.get("styx_spell_rivers", 0.0)), int(st.get("styx_spell_forgets", 0.0)),
		int(st.get("styx_spell_drain_heal", 0.0)), int(st.get("ferry_risen", 0.0))]


## The rivers: black water with pale banks filling from the middle out; Lethe's
## Flood glows a pale silver-blue (the water of forgetting). Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for rv in rivers:
		var a: Vector2 = rv["a"]
		var b: Vector2 = rv["b"]
		var r := float(rv["r"])
		var fill := clampf((now - float(rv["t0"])) / RiverStyxData.FILL_TIME, 0.0, 1.0)  # 0 -> 1 as it fills.
		var fade := clampf((float(rv["until"]) - now) / 0.6, 0.0, 1.0)  # It dries in its last 0.6 s.
		var mid := a.lerp(b, 0.5)
		var a2 := mid.lerp(a, fill)
		var b2 := mid.lerp(b, fill)
		var lethe := bool(rv["evolved"])
		draw_line(a2, b2, Color(Palette.BONE if not lethe else Palette.PANTHEON_MARBLE_LIGHT, 0.35 * fade), r * 2.0 + 4.0)  # The banks.
		draw_line(a2, b2, Color(0.02, 0.02, 0.05, 0.85 * fade), r * 2.0)  # Black water.
		draw_line(a2, b2, Color(Palette.VIOLET if not lethe else Palette.PANTHEON_AEGEAN_LIGHT, 0.45 * fade), maxf(1.0, r * 0.35))  # The current.
		var along := (b - a).normalized()
		var k := 0.0
		while k < a2.distance_to(b2):
			var q := a2 + along * fmod(k + now * 30.0, maxf(1.0, a2.distance_to(b2)))
			draw_line(q, q + along * 6.0, Color(1.0, 1.0, 1.0, 0.25 * fade), 1.0)  # Drift.
			k += 28.0
