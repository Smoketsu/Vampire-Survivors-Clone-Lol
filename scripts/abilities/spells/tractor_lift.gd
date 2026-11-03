## TractorLift — the Tractor Beam spell (AbilityData "tractor_lift"; Act IX,
## the Ark of the Concord; GDD §15.0 "Tractor Beam, Abduction, Starseed and the
## Starborn"; owner-approved proposal: "Tractor Beam: lifts the strongest enemy
## into the air and slams it down"; unlocked by defeating the Harvester, then
## offered on every stage at the later-item card weight). Every `cooldown` s a
## column of soul light comes down on the STRONGEST open foe within
## TractorLiftData.AIM_RANGE px of the necromancer (the most HP left; one more
## for each extra lift: the evolution's `lifts`, the Starborn's Deserter's
## Signal, at most MAX_LIFTS) and LIFTS it through the one enemy-lift helper
## (EnemyLift: the hold is one CombatResolver.stun_enemy(), `lift_time` s). A
## boss, a miniboss or a structure is never lifted: the spell SLAMS IT IN
## PLACE (after SLAM_IN_PLACE s). When the hold ends it is SLAMMED DOWN:
## `damage` to it and slam_share x the damage to every other foe within
## slam_radius px (CombatResolver.damage_enemy(), the friendly damage path).
## Evolved into ABDUCTION (EvolutionData "star_abduction", detected by the
## "pull" key): more foes a cast, held longer, and every slam first DRAGS the
## foes within `pull` px in toward it (a knockback, pull_force / mass) and
## shakes them for quake_share x the damage. STARSEED (the paired passive):
## its cooldown share and its slam reach are applied by
## AbilityManager.apply_spell_mods() on the spell's own keys.
## Determinism: no RNG; the strongest foes by HP, ties in the spatial hash's
## order; lifts on game time. Stats: tractor_casts, tractor_lifts,
## tractor_slams, tractor_in_place, tractor_slam_hits, tractor_pulls; damage as
## dmg_tractor_lift / dmg_star_abduction / dmg_star_abduction_quake.
class_name TractorLift
extends NecroSpell

## Seconds until the next cast.
var _cd: float = 0.0
## Live lifts (EnemyLift.Lift records).
var lifts: Array = []
## Slams in place waiting to land: {e (Enemy), gen (int), at (world px), t (s)}.
var in_place: Array[Dictionary] = []
## Slams drawn fading: {at, r, t (game s)}.
var _booms: Array[Dictionary] = []
## The stats row of the last step (a lift ending slams with it).
var _stats: Dictionary = {}
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


## Casts when ready; ages the lifts and the slams in place.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_cd -= delta
	if _cd <= 0.0:
		var n := mini(int(stats.get("lifts", 1)) + int(game.character.innate_value(TractorLiftData.EXTRA_KEY)), TractorLiftData.MAX_LIFTS)
		if _cast(n, stats):
			_cd = float(stats["cooldown"])
		else:
			_cd = AbilityData.SPELL_RETRY
	_step_lifts(delta)
	_step_in_place(delta)
	while not _booms.is_empty() and game.elapsed - float(_booms[0]["t"]) > 0.4:
		_booms.pop_front()
	var busy := not lifts.is_empty() or not in_place.is_empty() or not _booms.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Picks the `n` strongest open foes within reach: lifts the light ones, marks
## the heavy ones for a slam in place. False when none is in reach.
func _cast(n: int, stats: Dictionary) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, TractorLiftData.AIM_RANGE, _tmp)
	var picked: Array[Enemy] = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or e.civilian or picked.has(e) or e.position.distance_to(p) > TractorLiftData.AIM_RANGE:
				continue
			if _held(e):
				continue  # Already in the air.
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		picked.append(best)
	if picked.is_empty():
		return false
	var src := TractorLiftData.EVOLVED_SOURCE if stats.has("pull") else TractorLiftData.SOURCE
	for e in picked:
		if EnemyLift.can_lift(e):
			var r := EnemyLift.begin(game, e, float(stats.get("lift_time", 0.9)), src, TractorLiftData.LIFT_PX)
			if r != null:
				lifts.append(r)
				game.stat_add("tractor_lifts", 1.0)
				continue
		in_place.append({"e": e, "gen": e.generation, "at": e.position, "t": 0.0})
		game.stat_add("tractor_in_place", 1.0)
	game.stat_add("tractor_casts", 1.0)
	return true


## True while `e` is held by one of this spell's lifts.
func _held(e: Enemy) -> bool:
	for r: EnemyLift.Lift in lifts:
		if r.e == e and r.gen == e.generation:
			return true
	return false


## Ages every lift; one whose hold ended slams down (a foe that died in the
## air slams nothing).
func _step_lifts(delta: float) -> void:
	var i := 0
	while i < lifts.size():
		var r: EnemyLift.Lift = lifts[i]
		if EnemyLift.step(r, delta):
			i += 1
			continue
		lifts.remove_at(i)
		if EnemyLift.alive(r):
			_slam(r.e, r.at)


## Ages the slams in place on the heavy foes.
func _step_in_place(delta: float) -> void:
	var i := 0
	while i < in_place.size():
		var s := in_place[i]
		var e: Enemy = s["e"]
		var alive := e != null and e.active and e.generation == int(s["gen"])
		if alive:
			s["at"] = e.position
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) < TractorLiftData.SLAM_IN_PLACE:
			i += 1
			continue
		in_place.remove_at(i)
		_slam(e if alive else null, s["at"])


## The slam at `at` on `e` (null when it died meanwhile): Abduction's pull and
## quake first, then the slam on it and the foes round it.
func _slam(e: Enemy, at: Vector2) -> void:
	var evolved := _stats.has("pull")
	var src := TractorLiftData.EVOLVED_SOURCE if evolved else TractorLiftData.SOURCE
	var dmg := float(_stats.get("damage", 40.0))
	if evolved:
		_pull(at, e, dmg)
	if e != null and e.active:
		game.combat.damage_enemy(e, dmg, src)
	var hits: Array = []
	var r := float(_stats.get("slam_radius", 50.0))
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	for o: Enemy in hits:
		if o != e and o.active and o.position.distance_to(at) <= r + o.radius:
			game.combat.damage_enemy(o, dmg * float(_stats.get("slam_share", 0.5)), src)
			game.stat_add("tractor_slam_hits", 1.0)
	game.stat_add("tractor_slams", 1.0)
	game.effects.ring(at, r, ArkGlyphs.SOUL, 0.3)
	game.shake(1.5)
	_booms.append({"at": at, "r": r, "t": game.elapsed})


## Abduction's pull: every foe within `pull` px (not `skip`) is dragged in
## toward `at` (pull_force / mass) and shaken for quake_share x `dmg`.
func _pull(at: Vector2, skip: Enemy, dmg: float) -> void:
	var hits: Array = []
	var r := float(_stats.get("pull", 110.0))
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	for o: Enemy in hits:
		if o == skip or not o.active or o.position.distance_to(at) > r + o.radius:
			continue
		if not o.is_boss and not o.is_structure:
			var to := at - o.position
			if to.length() > 1.0:
				o.knockback += to.normalized() * float(_stats.get("pull_force", 240.0)) / maxf(o.mass, 0.1)
		game.combat.damage_enemy(o, dmg * float(_stats.get("quake_share", 0.3)), TractorLiftData.QUAKE_SOURCE)
		game.stat_add("tractor_pulls", 1.0)


## Autotest counters (the Tractor Beam line of ArkReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d lifts=%d slams=%d in_place=%d slam_hits=%d pulls=%d" % [int(st.get("tractor_casts", 0.0)), int(st.get("tractor_lifts", 0.0)),
		int(st.get("tractor_slams", 0.0)), int(st.get("tractor_in_place", 0.0)), int(st.get("tractor_slam_hits", 0.0)), int(st.get("tractor_pulls", 0.0))]


## The lift columns, the slams in place and the fading slams. Textures only.
## Visual only.
func _draw() -> void:
	if game == null:
		return
	for r: EnemyLift.Lift in lifts:
		EnemyLift.draw(self, r, ArkGlyphs.SOUL, TractorLiftData.COLUMN_HALF)
	for s in in_place:
		var k := clampf(float(s["t"]) / TractorLiftData.SLAM_IN_PLACE, 0.0, 1.0)
		ArkGlyphs.draw_lift_column(self, s["at"], TractorLiftData.COLUMN_HALF * 1.3, k, ArkGlyphs.SOUL)
	for b in _booms:
		var k := clampf((game.elapsed - float(b["t"])) / 0.4, 0.0, 1.0)
		SpriteBank.draw_disc(self, b["at"], float(b["r"]) * (0.5 + 0.5 * k), Color(ArkGlyphs.SOUL, 0.3 * (1.0 - k)))
