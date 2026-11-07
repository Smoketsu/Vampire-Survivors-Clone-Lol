## GhostSaucerBehavior — the Ghost Saucer's kit ("saucer_lift", UnitData
## "ghost_saucer"; Act IX, the Ark of the Concord's finale reward; GDD §15.0
## "The Ghost Saucer, Black Mothership and Crop Circles"; owner-approved
## proposal: "Finale summon class: the Ghost Saucer, a flying ranged summon
## that fires short beams and lifts small enemies (evolution Black
## Mothership)"; brief: unlocked by the Harvester). A Concord saucer raised
## by the necromancer: a hull of bone-grey plates and soul-light. It works the
## same on every stage (owner rule: summons never get act-only rules):
##   * IT FLIES: the class row's "flies" (SummonedUnit.flies: over the
##     obstacles, on no conveyor; enemies still target and hit it), so it is
##     NEVER LIFTABLE by the Concord (Abduction.liftable() refuses fliers). Its
##     body is drawn hover_lift px above a ground shadow.
##   * SHORT BEAMS: its attack_profile "saucer_beam" is released here: a beam
##     from its hull along the line to its target, beam_length px long, that
##     strikes every enemy within beam_width px of the line once
##     (CombatResolver.damage_enemy() with the unit's own source,
##     u.dmg_source: "ghost_saucer" / "black_mothership"; the summon attack
##     path, never ConcordBeams, which is the enemies'); Black Mothership fires
##     `beams` beams fanned beam_spread rad apart. Drawn for BEAM_TIME s as a
##     stretched soul-light texture.
##   * THE LIFT (its special, every lift_cooldown s): it picks the nearest
##     SMALL enemy within lift_range px (EnemyLift.can_lift(small_only): never
##     a boss, a miniboss, a structure, a Reckoning enemy, an elite or a body
##     over lift_max_size px) and lifts it through THE ONE ENEMY-LIFT HELPER
##     (EnemyLift: one stun_enemy() for lift_duration s, the column drawn in
##     soul-light); when the hold ends it drops it: lift_damage to it and the
##     foes within lift_radius px (LIFT_SOURCE / EVOLVED_LIFT_SOURCE). Black
##     Mothership lifts `lifts` foes at once. The lift never stops its beams.
## Crop Circles (its paired passive) lengthens every class special's
## *_duration keys (HordeDirector._special_stats(), its own category; 0 when
## not owned), the lift's hold included.
## Determinism: no RNG (the nearest small foe, ties in the spatial hash's
## order). Stats: ghost_saucer_beams, ghost_saucer_beam_hits,
## ghost_saucer_lifts, ghost_saucer_slams.
class_name GhostSaucerBehavior
extends SummonBehavior

## Class id (UnitData, UnlockData, mastery).
const CLASS_ID: String = "ghost_saucer"
## Damage-source tag of the dropped foe's slam (the base saucer).
const LIFT_SOURCE: String = "ghost_saucer_lift"
## Damage-source tag of Black Mothership's slam.
const EVOLVED_LIFT_SOURCE: String = "black_mothership_lift"
## Passive id of Crop Circles (its paired passive; PassiveData, UnlockData).
const CROP: String = "crop_circles"
## Crop Circles' level-row key: share every class special's *_duration keys
## grow by (HordeDirector._special_stats()).
const CROP_KEY: String = "special_hold"
## Seconds a beam stays drawn (visual only).
const BEAM_TIME: float = 0.18  # TUNING (not in GDD) visual only
## Px a lifted foe is drawn rising (visual only).
const LIFT_PX: float = 22.0  # TUNING (not in GDD) visual only

## Live lifts of this saucer (EnemyLift.Lift records).
var lifts: Array = []
## Beams drawn fading: [from (world px), to (world px), game s fired].
var _beams: Array = []
## Reusable enemy query buffer.
var _buf: Array = []


func reset(u: SummonedUnit) -> void:
	super.reset(u)
	lifts.clear()
	_beams.clear()


func on_deactivate(u: SummonedUnit) -> void:
	lifts.clear()  # A lifted foe stays stunned out its hold, then falls unharmed.
	_beams.clear()
	super.on_deactivate(u)


## Full lift cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("lift_cooldown", 7.0))


## 5 Hz: with the lift ready and room for one more, it lifts the nearest
## small foe in reach (never a special state: the saucer keeps firing).
func think(u: SummonedUnit) -> bool:
	if special_cd > 0.0 or lifts.size() >= int(u.special.get("lifts", 1)):
		return false
	var g := u.game
	var reach := float(u.special.get("lift_range", 170.0))
	var max_r := float(u.special.get("lift_max_size", 12.0))
	g.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in _buf:
		if not EnemyLift.can_lift(e, true, max_r):
			continue
		var dist := e.position.distance_to(u.position)
		if dist <= reach and dist < best_d:
			best = e
			best_d = dist
	if best == null:
		return false
	var src := LIFT_SOURCE if not _evolved(u) else EVOLVED_LIFT_SOURCE
	var r := EnemyLift.begin(g, best, float(u.special.get("lift_duration", 1.2)), src, LIFT_PX)
	if r == null:
		return false
	lifts.append(r)
	special_cd = cooldown(u)
	g.stat_add("ghost_saucer_lifts", 1.0)
	return false


## True for Black Mothership (its special_set "beams").
static func _evolved(u: SummonedUnit) -> bool:
	return int(u.special.get("beams", 1)) > 1


## Per tick: the cooldown (base), then its lifts age; a hold that ends drops
## its foe. Never owns the tick (the saucer flies and fires on).
func physics(u: SummonedUnit, delta: float) -> bool:
	super.physics(u, delta)
	var i := 0
	while i < lifts.size():
		var r: EnemyLift.Lift = lifts[i]
		if EnemyLift.step(r, delta):
			i += 1
			continue
		lifts.remove_at(i)
		if EnemyLift.alive(r):
			_drop(u, r)
	var g := u.game
	while not _beams.is_empty() and g.elapsed - float(_beams[0][2]) > BEAM_TIME:
		_beams.pop_front()
	if not lifts.is_empty() or not _beams.is_empty():
		u.queue_redraw()
	return false


## The lifted foe falls: lift_damage to it and the foes round it.
func _drop(u: SummonedUnit, r: EnemyLift.Lift) -> void:
	var g := u.game
	var src := LIFT_SOURCE if not _evolved(u) else EVOLVED_LIFT_SOURCE
	var dmg := float(u.special.get("lift_damage", 20.0))
	var rad := float(u.special.get("lift_radius", 36.0))
	g.combat.damage_enemy(r.e, dmg, src)
	g.enemy_grid.query(r.at, rad + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits: Array = _buf.duplicate()  # Own copy: kill hooks may query again.
	for o: Enemy in hits:
		if o != r.e and o.active and o.position.distance_to(r.at) <= rad + o.radius:
			g.combat.damage_enemy(o, dmg * 0.5, src)
	g.stat_add("ghost_saucer_slams", 1.0)
	g.effects.ring(r.at, rad, ArkGlyphs.SOUL, 0.25)
	g.volleys.on_special(u, r.at, r.at + Vector2.RIGHT, dmg)  # Bullet heaven: its special volley (when the class has one).


## Releases its short beams at the target (the "saucer_beam" profile).
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	var g := u.game
	var to := u.target.position - u.position
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	var n := maxi(1, int(u.special.get("beams", 1)))
	var spread := float(u.special.get("beam_spread", 0.25))
	var length := float(u.special.get("beam_length", 200.0))
	var w := float(u.special.get("beam_width", 7.0))
	var muzzle := u.position + Vector2(0.0, -body_lift(u))
	var hit: Array = []  # Each foe once a volley of beams.
	for i in n:
		var d := dir.rotated((float(i) - float(n - 1) * 0.5) * spread)
		var a := u.position
		var b := a + d * length
		g.enemy_grid.query(a + d * length * 0.5, length * 0.5 + w + ProjectileManager.MAX_BODY_RADIUS, _buf)
		var cands: Array = _buf.duplicate()
		for e: Enemy in cands:
			if hit.has(e) or not e.active:
				continue
			if _seg_dist(e.position, a, b) <= w + e.radius:
				hit.append(e)
				g.combat.damage_enemy(e, u.damage, u.dmg_source, -1, u.position)
		_beams.append([muzzle, muzzle + d * length, g.elapsed])
	g.stat_add("ghost_saucer_beams", float(n))
	g.stat_add("ghost_saucer_beam_hits", float(hit.size()))
	u.queue_redraw()


## Distance (px) from `p` to the segment `a`-`b`.
static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## The body hovers above its shadow (drawing only).
func body_lift(u: SummonedUnit) -> float:
	return float(u.special.get("hover_lift", 16.0))


## Ground shadow under the hovering hull, its beams and its lifts (textures,
## world-aligned under the unit).
func draw_under(u: SummonedUnit) -> void:
	var w := u.radius * 1.1  # Shadow half-width (px).
	u.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, u.radius * 0.95 - w * 0.4), Vector2(w * 2.0, w * 0.8)), false, Color(0, 0, 0, 0.28))  # A texture (the Web GL rule).
	var g := u.game
	if lifts.is_empty() and _beams.is_empty():
		return
	# World points drawn in the unit's local space: the node is mirrored by
	# scale.x (+-1, its own inverse), so a world offset maps through it.
	var m := Vector2(signf(u.scale.x) if u.scale.x != 0.0 else 1.0, 1.0)
	for r: EnemyLift.Lift in lifts:
		if not EnemyLift.alive(r):
			continue
		var k := clampf(r.t / EnemyLift.RISE_TIME, 0.0, 1.0)
		ArkGlyphs.draw_lift_column(u, (r.at - u.position) * m, 10.0, k, ArkGlyphs.SOUL)
	for bm: Array in _beams:
		var k := 1.0 - clampf((g.elapsed - float(bm[2])) / BEAM_TIME, 0.0, 1.0)
		ArkGlyphs.draw_soul_beam(u, ((bm[0] as Vector2) - u.position) * m, ((bm[1] as Vector2) - u.position) * m, float(u.special.get("beam_width", 7.0)), k)
	body_space(u)
