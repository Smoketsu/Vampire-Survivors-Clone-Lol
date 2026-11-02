## HerosFist — the Hero's Fist spell (AbilityData "heros_fist"; Act VIII,
## Liberty Heights; GDD §15.0 "Hero's Fist, Doomsday, Secret Identity and the
## Revenant Heroine"; owner-approved proposal: "a spectral fist slams the
## strongest enemy and sends it flying through the rest"; unlocked by
## defeating Paragon, then offered on every stage at the later-item card
## weight). Every `cooldown` s a spectral fist (plus the Revenant Heroine's
## Back From the Dead innate, at most HerosFistData.MAX_FISTS; `fists` from
## the evolution) comes down on the STRONGEST open foe within AIM_RANGE px of
## the necromancer (the most HP left; the next strongest for each more fist)
## and lands FALL_TIME s later: `damage` to it (CombatResolver.damage_enemy(),
## the friendly damage path). A foe that lives and can be moved is SENT FLYING
## `fling` px straight away from the necromancer (stopped short of a building
## or wreck: Arena.clear_length()) over FLING_TIME s, and every other foe it
## passes within FLING_WIDTH px takes fling_share x the damage once and is
## shoved aside (an enemy moved by a spell: the one place is _step_flights()).
## A boss, a miniboss, a structure or a vehicle is not moved: a shockwave of
## UNMOVED_RADIUS px around it strikes the others there instead (as does a foe
## the slam killed). Evolved into DOOMSDAY (EvolutionData "doomsday", detected
## by the "crater" key): two fists, harder and farther, and where the flung foe
## lands (or at an unmoved one) a CRATER of `crater` px strikes crater_share x
## the damage. SECRET IDENTITY (the paired passive): its cooldown share and its
## fling bonus are applied by AbilityManager.apply_spell_mods() on the spell's
## own keys.
## Determinism: no RNG; the strongest foes by HP, ties in the spatial hash's
## order; flights on game time. Stats: fist_casts, fist_slams, fist_flung,
## fist_fling_hits, fist_unmoved, fist_craters; damage as dmg_heros_fist /
## dmg_heros_fist_fling / dmg_doomsday / dmg_doomsday_crater.
class_name HerosFist
extends NecroSpell

## Seconds until the next cast.
var _cd: float = 0.0
## Fists coming down: {target (Enemy), gen (int), at (world px), t (s)}.
var fists: Array[Dictionary] = []
## Foes in flight: {e (Enemy), gen, from, to (world px), t (s), hit (Array),
## dmg (the fling's damage), crater (px, 0 = none), crater_dmg}.
var flights: Array[Dictionary] = []
## Doomsday's craters drawn fading: {at, r, t (game s)}.
var _booms: Array[Dictionary] = []
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


## Casts when ready; brings the fists down; moves the flung foes.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		var n := mini(int(stats.get("fists", 1)) + int(game.character.innate_value(HerosFistData.EXTRA_KEY)), HerosFistData.MAX_FISTS)
		if _cast(n):
			_cd = float(stats["cooldown"])
		else:
			_cd = AbilityData.SPELL_RETRY
	_step_fists(delta, stats)
	_step_flights(delta)
	while not _booms.is_empty() and game.elapsed - float(_booms[0]["t"]) > 0.4:
		_booms.pop_front()
	var busy := not fists.is_empty() or not flights.is_empty() or not _booms.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Picks the `n` strongest open foes within reach and brings a fist down on
## each. False when none is in reach.
func _cast(n: int) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, HerosFistData.AIM_RANGE, _tmp)
	var picked: Array[Enemy] = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or e.civilian or picked.has(e) or e.position.distance_to(p) > HerosFistData.AIM_RANGE:
				continue
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		picked.append(best)
	if picked.is_empty():
		return false
	for e in picked:
		fists.append({"target": e, "gen": e.generation, "at": e.position, "t": 0.0})
	game.stat_add("fist_casts", 1.0)
	return true


## The fists fall; each lands FALL_TIME s after its cast.
func _step_fists(delta: float, stats: Dictionary) -> void:
	var i := 0
	while i < fists.size():
		var f := fists[i]
		var e: Enemy = f["target"]
		var alive := e != null and e.active and e.generation == int(f["gen"])
		if alive:
			f["at"] = e.position
		f["t"] = float(f["t"]) + delta
		if float(f["t"]) < HerosFistData.FALL_TIME:
			i += 1
			continue
		fists.remove_at(i)
		_land(e if alive else null, f["at"], stats)


## A fist lands at `at` on `e` (null when it died meanwhile): the slam, then
## the fling (or the shockwave of an unmoved foe).
func _land(e: Enemy, at: Vector2, stats: Dictionary) -> void:
	var evolved := stats.has("crater")
	var dmg := float(stats["damage"])
	var share := float(stats.get("fling_share", 0.5))
	var crater := float(stats.get("crater", 0.0))
	var crater_dmg := dmg * float(stats.get("crater_share", 0.0))
	game.effects.ring(at, 26.0, Palette.GOLD if evolved else Palette.NECRO_GREEN, 0.25)
	game.shake(1.5)
	if e != null:
		game.combat.damage_enemy(e, dmg, HerosFistData.EVOLVED_SOURCE if evolved else HerosFistData.SOURCE)
		game.stat_add("fist_slams", 1.0)
	if e == null or not e.active or not _movable(e):
		game.stat_add("fist_unmoved", 1.0)
		_shockwave(at, e, dmg * share)
		if crater > 0.0:
			_crater(at, crater, crater_dmg)
		return
	var dir := e.position - game.player.position
	dir = dir.normalized() if dir.length() > 1.0 else Vector2.RIGHT
	var length := game.arena.clear_length(e.position, dir, float(stats.get("fling", 160.0)), e.radius)
	var to := game.arena.free_point(e.position + dir * length, e.radius)
	flights.append({"e": e, "gen": e.generation, "from": e.position, "to": to, "t": 0.0, "hit": [e],
		"dmg": dmg * share, "crater": crater, "crater_dmg": crater_dmg})
	game.stat_add("fist_flung", 1.0)


## True when `e` can be sent flying (not a boss, a miniboss, a structure or a
## vehicle).
static func _movable(e: Enemy) -> bool:
	return not e.is_boss and not e.is_miniboss and not e.is_structure and not e.vehicle and not e.is_reckoning


## The shockwave around an unmoved (or slain) foe: the others within
## UNMOVED_RADIUS px take `dmg`.
func _shockwave(at: Vector2, skip: Enemy, dmg: float) -> void:
	var hits: Array = []
	game.enemy_grid.query(at, HerosFistData.UNMOVED_RADIUS + ProjectileManager.MAX_BODY_RADIUS, hits)
	for o: Enemy in hits:
		if o != skip and o.active and o.position.distance_to(at) <= HerosFistData.UNMOVED_RADIUS + o.radius:
			game.combat.damage_enemy(o, dmg, HerosFistData.FLING_SOURCE)
			game.stat_add("fist_fling_hits", 1.0)
	game.effects.ring(at, HerosFistData.UNMOVED_RADIUS, Palette.IVORY, 0.25)


## THE one place that moves a flung foe: carried along its line; every foe it
## passes is struck once and shoved aside; Doomsday's crater where it lands.
func _step_flights(delta: float) -> void:
	var i := 0
	while i < flights.size():
		var fl := flights[i]
		var e: Enemy = fl["e"]
		var to: Vector2 = fl["to"]
		if not e.active or e.generation != int(fl["gen"]):
			flights.remove_at(i)
			if float(fl["crater"]) > 0.0:
				_crater(to, float(fl["crater"]), float(fl["crater_dmg"]))
			continue
		fl["t"] = float(fl["t"]) + delta
		var k := clampf(float(fl["t"]) / HerosFistData.FLING_TIME, 0.0, 1.0)
		var from: Vector2 = fl["from"]
		e.position = from.lerp(to, k)
		e.velocity = Vector2.ZERO
		e.knockback = Vector2.ZERO
		var dir := (to - from).normalized() if to.distance_to(from) > 0.5 else Vector2.RIGHT
		var hits: Array = []
		game.enemy_grid.query(e.position, e.radius + HerosFistData.FLING_WIDTH + ProjectileManager.MAX_BODY_RADIUS, hits)
		var hit: Array = fl["hit"]
		for o: Enemy in hits:
			if hit.has(o) or not o.active or o.position.distance_to(e.position) > e.radius + o.radius + HerosFistData.FLING_WIDTH:
				continue
			hit.append(o)
			var side := Vector2(-dir.y, dir.x)
			side *= 1.0 if side.dot(o.position - e.position) >= 0.0 else -1.0
			o.knockback += side * HerosFistData.FLING_SHOVE / maxf(o.mass, 0.1)
			game.combat.damage_enemy(o, float(fl["dmg"]), HerosFistData.FLING_SOURCE)
			game.stat_add("fist_fling_hits", 1.0)
		if k >= 1.0:
			flights.remove_at(i)
			if float(fl["crater"]) > 0.0:
				_crater(to, float(fl["crater"]), float(fl["crater_dmg"]))
			continue
		i += 1


## Doomsday's crater at `at` (`r` px): every foe in it takes `dmg`.
func _crater(at: Vector2, r: float, dmg: float) -> void:
	damage_area(at, r, dmg, HerosFistData.CRATER_SOURCE)
	game.stat_add("fist_craters", 1.0)
	game.effects.impact(at, r, Palette.GOLD)
	_booms.append({"at": at, "r": r, "t": game.elapsed})


## Autotest counters (the Hero's Fist line of LibertyHeightsReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d slams=%d flung=%d fling_hits=%d unmoved=%d craters=%d" % [int(st.get("fist_casts", 0.0)), int(st.get("fist_slams", 0.0)),
		int(st.get("fist_flung", 0.0)), int(st.get("fist_fling_hits", 0.0)), int(st.get("fist_unmoved", 0.0)), int(st.get("fist_craters", 0.0))]


## The fists falling, the flung foes' streaks and Doomsday's craters.
## Textures only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var evolved := game.abilities.evolved.has(HerosFistData.ID)
	for f in fists:
		var k := clampf(float(f["t"]) / HerosFistData.FALL_TIME, 0.0, 1.0)
		var at: Vector2 = f["at"]
		SpriteBank.draw_disc(self, at, HerosFistData.FIST_SIZE * 1.6 * k, Color(0.0, 0.0, 0.0, 0.25))  # Its shadow grows.
		LibertyHeightsGlyphs.draw_fist(self, at + Vector2(0.0, -70.0 * (1.0 - k)), HerosFistData.FIST_SIZE, 0.4 + 0.6 * k, evolved)
	for fl in flights:
		var e: Enemy = fl["e"]
		if e.active:
			LibertyHeightsGlyphs.draw_fist(self, e.position, HerosFistData.FIST_SIZE * 0.8, 0.6, evolved)
	for b in _booms:
		var k := clampf((game.elapsed - float(b["t"])) / 0.4, 0.0, 1.0)
		SpriteBank.draw_disc(self, b["at"], float(b["r"]) * (0.5 + 0.5 * k), Color(Palette.GOLD, 0.3 * (1.0 - k)))
