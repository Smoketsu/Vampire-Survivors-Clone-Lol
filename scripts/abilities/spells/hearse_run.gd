## HearseRun — the Hearse Run spell (AbilityData "hearse_run"; Act VIII, Skid
## Row; GDD §15.0 "Hearse Run, Funeral Procession, Black Car and the Undertaker
## (Act VIII)"; owner-approved proposal: "a spectral hearse drives a lane
## through the enemies"; unlocked by slaying Don Marrow, then offered on every
## stage at the later-item card weight). Every `cooldown` s, `hearses` spectral
## hearses (plus the Undertaker's Last Ride, innate value hearse_extra) pick
## their LANES: each through one of the nearest groups of foes within `range`
## px of the necromancer (each lane's target the nearest open foe at least
## HearseRunData.LANE_APART px from the others; civilians are never a lane's
## target, though a hearse strikes one in its way like any foe). On a city-block layout a
## target standing in a street gets that street's lane (CityBlocks.lane(), the
## street centre line along the street's axis); off the blocks, or a target in
## an alley or a lot, gets the straight line from the necromancer through it.
## The hearse drives `length` px along its lane at `speed` px/s, starting
## 40% of its length before the target, and strikes every foe within `width`
## px of it once for `damage`, shoving it off the line (knockback; never a
## boss, miniboss or structure). A spectral hearse drives through buildings
## and wrecks. Evolved into FUNERAL PROCESSION (EvolutionData
## "funeral_procession", detected by the "procession" key): each hearse is a
## procession of `procession` cars `procession_gap` px apart, each striking
## on its own, and every foe a car kills rises as a PALLBEARER (a temporary
## Warrior through HordeDirector.spawn_temporary(), the one temporary-summon
## path; at most `pallbearers` a cast). BLACK CAR (the paired passive): every
## foe a hearse strikes is slowed by its hearse_slow for
## HearseRunData.BLACK_CAR_SLOW_TIME s (CombatResolver.slow_enemy(), the one
## enemy slow path; 0 while not owned). Works the same on every stage (no act
## rule). Determinism: no RNG; targets by distance in the spatial hash's order.
## Stats: hearse_casts, hearse_hearses, hearse_extra, hearse_hits,
## hearse_black_car_slows, hearse_pallbearers; damage as dmg_hearse_run /
## dmg_funeral_procession.
class_name HearseRun
extends NecroSpell

## Hearses on the road: {from (world px), dir (unit), length (px), t0 (game s
## it set off), speed (px/s), width (px), dmg, cars (int), gap (px), evolved
## (bool), raise (pallbearers left this cast, shared Array [n]), hit (Array of
## Dictionaries, one per car: Enemy -> true)}.
var hearses: Array[Dictionary] = []
## Seconds until the next cast.
var _cd: float = 0.0
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; drives the hearses.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := 0
	while i < hearses.size():
		if _drive(hearses[i], now):
			hearses.remove_at(i)
			continue
		i += 1
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var busy := not hearses.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: the hearses pick their lanes and set off. False when no foe is in
## range.
func _cast(stats: Dictionary) -> bool:
	var base := int(stats["hearses"])
	var n := base + roundi(game.character.innate_value(HearseRunData.EXTRA_HEARSES_KEY))
	var me := game.player.position
	var targets := _targets(me, float(stats["range"]), n)
	if targets.is_empty():
		return false
	var evolved := stats.has("procession")
	var raise: Array = [int(stats.get("pallbearers", 0))]  # Pallbearers left this cast (shared by its hearses).
	var cb := game.arena.city_blocks
	var length := float(stats["length"])
	for k in n:
		if hearses.size() >= HearseRunData.MAX_HEARSES:
			break
		var t: Vector2 = targets[k % targets.size()]
		var dir := (t - me).normalized() if t.distance_to(me) > 1.0 else Vector2.RIGHT
		var through := t  # A point the lane runs through.
		if cb != null and (cb.in_h_street(t) or cb.in_v_street(t)):
			var ln := cb.lane(t, Vector2.RIGHT if cb.in_h_street(t) else Vector2.DOWN)
			var ld: Vector2 = ln["dir"]
			dir = ld if ld.dot(t - me) >= 0.0 else -ld  # Away from the necromancer along the street.
			through = ln["point"]
		var cars := int(stats.get("procession", 1))
		var hit: Array = []
		for c in cars:
			hit.append({})
		hearses.append({"from": through - dir * length * 0.4, "dir": dir, "length": length, "t0": game.elapsed + 0.05 * float(k),
			"speed": float(stats["speed"]), "width": float(stats["width"]), "dmg": float(stats["damage"]), "cars": cars,
			"gap": float(stats.get("procession_gap", 0.0)), "evolved": evolved, "raise": raise, "hit": hit})
	game.stat_add("hearse_casts", 1.0)
	game.stat_add("hearse_hearses", float(n))
	if n > base:
		game.stat_add("hearse_extra", float(n - base))
	Sfx.play("lance_cast", me, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## Up to `n` lane targets within `reach` px of `from`: each the nearest open foe
## at least LANE_APART px from the targets already chosen. Empty when no foe is
## in reach.
func _targets(from: Vector2, reach: float, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cands: Array = []  # [distance, Enemy] of the open foes in reach.
	game.enemy_grid.query(from, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e) or e.untargetable or e.civilian:
			continue
		var dist := from.distance_to(e.position)
		if dist <= reach:
			cands.append([dist, e])
	if cands.is_empty():
		return out
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c in cands:
		if out.size() >= n or out.size() >= HearseRunData.TARGET_SAMPLES:
			break
		var p: Vector2 = (c[1] as Enemy).position
		var free := true
		for q in out:
			free = free and q.distance_to(p) >= HearseRunData.LANE_APART
		if free:
			out.append(p)
	return out


## Drives hearse `h` on to game time `now`: each car strikes the foes it
## reaches. True when the whole procession has run its lane.
func _drive(h: Dictionary, now: float) -> bool:
	var run := (now - float(h["t0"])) * float(h["speed"])  # px the lead car has driven.
	if run < 0.0:
		return false
	var length := float(h["length"])
	var cars := int(h["cars"])
	var gap := float(h["gap"])
	for c in cars:
		var along := run - float(c) * gap
		if along < 0.0 or along > length:
			continue
		_strike(h, c, (h["from"] as Vector2) + (h["dir"] as Vector2) * along)
	return run > length + float(cars - 1) * gap


## Car `c` of hearse `h` at `at` strikes every open foe it touches once.
func _strike(h: Dictionary, c: int, at: Vector2) -> void:
	var width := float(h["width"])
	var hit: Dictionary = (h["hit"] as Array)[c]
	var dir: Vector2 = h["dir"]
	var perp := Vector2(-dir.y, dir.x)
	var src := HearseRunData.EVOLVED_SOURCE if bool(h["evolved"]) else HearseRunData.SOURCE
	var slow := game.abilities.passive_value(HearseRunData.BLACK_CAR, HearseRunData.BLACK_CAR_KEY)  # 0 when not owned.
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, width + HearseRunData.BODY.x + ProjectileManager.MAX_BODY_RADIUS, hits)
	for e: Enemy in hits:
		if not e.active or hit.has(e):
			continue
		var rel := e.position - at
		if absf(rel.dot(dir)) > HearseRunData.BODY.x + e.radius or absf(rel.dot(perp)) > width + e.radius:
			continue
		hit[e] = true
		var side := signf(rel.dot(perp)) if absf(rel.dot(perp)) > 0.5 else 1.0
		game.combat.damage_enemy(e, float(h["dmg"]), src)
		game.stat_add("hearse_hits", 1.0)
		if not e.active:
			_pallbearer(h, e.position)
			continue
		if slow > 0.0:
			game.combat.slow_enemy(e, slow, HearseRunData.BLACK_CAR_SLOW_TIME)
			game.stat_add("hearse_black_car_slows", 1.0)
		if not (e.is_boss or e.is_miniboss or e.is_structure):
			e.knockback += perp * side * HearseRunData.SHOVE


## Funeral Procession: a foe a car killed rises as a pallbearer (while the
## cast has any left).
func _pallbearer(h: Dictionary, at: Vector2) -> void:
	var left: Array = h["raise"]
	if not bool(h["evolved"]) or int(left[0]) <= 0:
		return
	left[0] = int(left[0]) - 1
	if game.horde.spawn_temporary(HearseRunData.PALLBEARER_CLASS, at, HearseRunData.PALLBEARER_TIME,
			HearseRunData.PALLBEARER_MULT, HearseRunData.PALLBEARER_MULT) != null:
		game.stat_add("hearse_pallbearers", 1.0)


## Autotest counters (SkidRowReport's Hearse Run line).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d hearses=%d (extra %d) hits=%d black_car_slows=%d pallbearers=%d" % [int(st.get("hearse_casts", 0.0)), int(st.get("hearse_hearses", 0.0)),
		int(st.get("hearse_extra", 0.0)), int(st.get("hearse_hits", 0.0)), int(st.get("hearse_black_car_slows", 0.0)),
		int(st.get("hearse_pallbearers", 0.0))]


## The hearses: each car a faded spectral hearse (its sprite, else a code
## shape) fading in at the start of its lane and out at the end. Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var tex := SpriteBank.texture(HearseRunData.SPRITE)  # The hearse PNG, or null.
	for h in hearses:
		var run := (now - float(h["t0"])) * float(h["speed"])
		var length := float(h["length"])
		var fade := HearseRunData.FADE_TIME * float(h["speed"])  # px of the fade at each end.
		for c in int(h["cars"]):
			var along := run - float(c) * float(h["gap"])
			if along < 0.0 or along > length:
				continue
			var a := clampf(minf(along, length - along) / maxf(fade, 1.0), 0.0, 1.0)
			SkidRowGlyphs.draw_hearse(self, (h["from"] as Vector2) + (h["dir"] as Vector2) * along, h["dir"],
					HearseRunData.BODY.x, HearseRunData.BODY.y, 0.35 + 0.55 * a, tex)
