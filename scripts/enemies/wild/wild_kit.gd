## WildKit — base class of the Turning Year's kits (temporary Act XV; GDD
## §15.0 "The Turning Year foundation (phase 1)"), a CovenantKit plugged into
## the shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/wild/<id>_kit.gd (CovenantKits, after the Titans' folder; an
## id must not repeat any other folder's). What every Wild kind shares:
##   * creating the shared rules on first use (Game.wild_rules()), so a Wild
##     kind forced onto any stage with --spawn= keeps its seeds there (the
##     season clock stays off off the act);
##   * registering with the rules (WildRules.note_spawn(): its first time;
##     the heal on living ground is BloomField's, read from the row's faction).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.reset() when they override it. Phase 2 (the Greenwood) adds the shared
## helpers: trample() (THE one Wild trample: every charge, sweep and Rut),
## move(), line_push() and draw_line_marks(). Determinism: no RNG, no instance ids.
class_name WildKit
extends CovenantKit

## px between two drawn marks of a charge's telegraph line (visual only).
const LINE_MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.game.wild_rules().note_spawn(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> WildRules:
	return e.game.wild_rules()


## The kind's group (row "group"; WildRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))


# =====================================================================================
# Phase 2 helpers (the Greenwood: the charges, the sweeps, the Rut)
# =====================================================================================

## THE one Wild trample (the Great Stag's charge, the Wild Hunt's sweeps, the
## Huntsman's line, the Stag King's Rut and his Hunt): every grounded summon and
## standing necromancer within `reach` px (+ its own radius) of `at` that `hit`
## does not hold yet is hit once: a summon takes `dmg_summon` x `mult`
## (CombatResolver.damage_unit()), is stunned `stun` s (CombatResolver.stun_unit(),
## the one summon stun path) and thrown `knock` px sideways off the line `dir`
## (the ring scatters); a necromancer takes `dmg_player` (unless `players` is
## false: a led follower's line strikes him once, through its leader). Tag
## `source`, killer `by` (null for a rule's riders). Returns how many bodies it hit.
static func trample(g: Game, at: Vector2, reach: float, hit: Array, dmg_summon: float, dmg_player: float, stun: float, knock: float,
		dir: Vector2, source: String, by: Enemy, buf: Array, mult: float = 1.0, players: bool = true) -> int:
	var n := 0
	g.ally_grid.query(at, reach + UnitData.MAX_BLOCK_RADIUS, buf)
	for u: SummonedUnit in buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies or hit.has(u):
			continue
		if u.position.distance_to(at) > reach + u.radius:
			continue
		hit.append(u)
		g.combat.damage_unit(u, dmg_summon * mult, source, by)
		if u.active and stun > 0.0:
			g.combat.stun_unit(u, stun, source)
		if knock > 0.0:
			var side := dir.orthogonal()
			u.position += side * knock * (1.0 if (u.position - at).dot(side) >= 0.0 else -1.0)
		n += 1
	if not players:
		return n
	for pl in g.all_players:
		if pl.dead or hit.has(pl) or pl.position.distance_to(at) > reach + pl.radius:
			continue
		hit.append(pl)
		g.combat.damage_player(dmg_player, source, pl, by)
		n += 1
	return n


## One steering step of a kit that owns the tick: `e` moves along `dir` (unit)
## at `speed` px/s (x the enemy's slow while one holds it), with the shared
## separation and its knockback, facing its way.
static func move(e: Enemy, dir: Vector2, speed: float, delta: float) -> void:
	var spd := speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	e.velocity = dir * spd + e.sep * spd * EnemyData.SEPARATION_STRENGTH
	e.position += (e.velocity + e.knockback) * delta
	e._update_facing()


## The autopilot's push sideways out of a line from `from` along `dir`, `len`
## px long, `r` px half wide, at `p` (Vector2.ZERO off the line).
static func line_push(from: Vector2, dir: Vector2, len: float, r: float, p: Vector2) -> Vector2:
	var rel := p - from
	var along := rel.dot(dir)
	if along < -24.0 or along > len + 24.0:
		return Vector2.ZERO
	var lat := rel.dot(dir.orthogonal())
	if absf(lat) > r + 24.0:
		return Vector2.ZERO
	return dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)


## Draws a Wild charge's telegraph on `ci`: marks every LINE_MARK_STEP px from
## `from` along `dir`, from `start` to `len` px, brighter as `k` (0..1) grows
## (bark-brown hoof marks with an amber glow: never the UI gold). Rects only.
static func draw_line_marks(ci: CanvasItem, from: Vector2, dir: Vector2, start: float, len: float, k: float) -> void:
	var s := start
	while s < len:
		ci.draw_rect(Rect2(from + dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.WILD_GOLD_LEAF, 0.3 + 0.55 * k))
		s += LINE_MARK_STEP
