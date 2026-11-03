## EnemyLift — THE ONE ENEMY-LIFT HELPER of the necromancer's side (Act IX, the
## Ark of the Concord's rewards; GDD §15.0 "Tractor Beam, Abduction, Starseed
## and the Starborn" and "The Ghost Saucer, Black Mothership and Crop
## Circles"; brief: "The lift holds the enemy through
## CombatResolver.stun_enemy(). Build ONE enemy-lift helper and share it with
## the Ghost Saucer"). Used by Tractor Beam / Abduction (TractorLift) and the
## Ghost Saucer / Black Mothership (GhostSaucerBehavior); never by an enemy
## (the Concord's lifts of summons are Abduction's).
##   * can_lift(): bosses, minibosses, structures, Reckoning enemies,
##     civilians and vehicles are NEVER lifted (the spell slams those in
##     place); `small_only` (the Ghost Saucer) also refuses elites, elite
##     kinds (a row's "elite_kind") and any body over `max_radius` px, and an
##     enemy already stunned (held by another lift).
##   * begin(): THE HOLD is one CombatResolver.stun_enemy(e, hold, 1, 1) (THE
##     enemy stun path: Spirit Binding lengthens it as every stun) and a Lift
##     record; the foe is then kept on its spot (step(), the one place that
##     holds a lifted foe still) and drawn rising in a column of soul light.
##   * step(): ages a lift; false once its hold is over (the caller then
##     slams it) or the foe is gone (died, pooled).
## The lifted foe's body stays where it is (an Enemy has no draw offset): the
## lift reads through the column, a bright mark rising above it and its
## shadow. Determinism: game time only; generation-checked records.
## Stats: enemy_lifts, enemy_lifts_<source>.
class_name EnemyLift
extends RefCounted

## One lift: an enemy held in the air.
class Lift:
	extends RefCounted
	## The lifted enemy.
	var e: Enemy = null
	## Its pool generation (stale guard).
	var gen: int = 0
	## Where it is held (world px).
	var at: Vector2 = Vector2.ZERO
	## Seconds since the lift began.
	var t: float = 0.0
	## Seconds the lift holds it.
	var hold: float = 1.0
	## Px it rises (drawing only).
	var height: float = 26.0

## Seconds a lifted foe takes to rise to its full height (drawing only).
const RISE_TIME: float = 0.3  # TUNING (not in GDD) visual only
## Seconds of the fall at the end of the hold (drawing only).
const FALL_TIME: float = 0.12  # TUNING (not in GDD) visual only


## True when `e` may be lifted (see the header).
static func can_lift(e: Enemy, small_only: bool = false, max_radius: float = 14.0) -> bool:
	if e == null or not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.is_reckoning or e.civilian or e.vehicle:
		return false
	if small_only:
		if e.is_elite or e.radius > max_radius or e.stun_timer > 0.0 or e.frozen:
			return false
		var row := e.game.enemies.enemy_def(e.kind)  # Its design row (an elite kind is not small).
		if bool(row.get("elite_kind", false)):
			return false
	return true


## Lifts `e` for `hold` s (THE hold: one stun_enemy()); `height` px drawn.
## Returns the record (null when it could not be lifted).
static func begin(game: Game, e: Enemy, hold: float, source: String, height: float = 26.0) -> Lift:
	if not can_lift(e):
		return null
	var held := game.combat.stun_enemy(e, hold, 1.0, 1.0)
	if held <= 0.0:
		return null
	var r := Lift.new()
	r.e = e
	r.gen = e.generation
	r.at = e.position
	r.hold = held
	r.height = height
	e.knockback = Vector2.ZERO
	e.velocity = Vector2.ZERO
	game.stat_add("enemy_lifts", 1.0)
	game.stat_add("enemy_lifts_" + source, 1.0)
	return r


## True while the lifted foe is the same live enemy.
static func alive(r: Lift) -> bool:
	return r.e != null and r.e.active and r.e.generation == r.gen


## Ages lift `r` by `delta` s and holds its foe on its spot. False once the
## hold is over or the foe is gone.
static func step(r: Lift, delta: float) -> bool:
	r.t += delta
	if not alive(r):
		return false
	r.e.position = r.at
	r.e.velocity = Vector2.ZERO
	r.e.knockback = Vector2.ZERO
	return r.t < r.hold


## Px the foe of lift `r` is drawn above the ground now (rises, hangs, falls).
static func lift_px(r: Lift) -> float:
	var up := clampf(r.t / RISE_TIME, 0.0, 1.0)
	var down := clampf((r.hold - r.t) / FALL_TIME, 0.0, 1.0)
	return r.height * minf(up, down)


## Draws lift `r` on `ci` (world coordinates): the column of light in `col`,
## `half` px wide, and the mark rising above the foe.
static func draw(ci: CanvasItem, r: Lift, col: Color, half: float) -> void:
	if not alive(r):
		return
	var k := clampf(r.t / RISE_TIME, 0.0, 1.0)
	ArkGlyphs.draw_lift_column(ci, r.at, half, k, col)
	ArkGlyphs.draw_lifted(ci, r.at, lift_px(r), r.e.radius, col)
