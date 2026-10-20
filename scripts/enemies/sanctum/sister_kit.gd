## BattleSisterKit — the Sister of the Scourge's lash and zeal (owner request,
## Oct 2026; BattleSisterData "battle_sister", GDD §15.0 "Sister of the
## Scourge"). Her body is the shared "melee" AI: she always advances on her
## target (the necromancer, or a summon in her way) and strikes in contact
## with the scourge handle. On top of that:
##   * Lash: when her target's edge is within lash_trigger px of her centre
##     and the cooldown is up, she stops; a crimson lash line flickers toward
##     it for lash_telegraph s (drawn on her overlay, SisterGlyphs; it pauses
##     while she is frozen like every kit windup), then the scourge cracks
##     along the line, lash_reach px from her centre and lash_width px wide:
##     the first lash_targets bodies in it, summons and the necromancer
##     alike, nearest first, are struck (lash_damage_summon /
##     lash_damage_player, time-scaled, through CombatResolver, source
##     "sister_lash"). A front line in the way shares the crack with whoever
##     stands behind it: undead do not dodge, and the whip reaches past one
##     body, not past two. She stands lash_recover s, then walks on.
##   * Zeal: when a fellow soldier falls within zeal_radius px (the deaths
##     CovenantRites records, so no instance ids), she surges for
##     zeal_duration s: move speed x zeal_speed_mult and her lash cooldown
##     runs zeal_lash_rate times faster; not again within zeal_cooldown s.
## Determinism (CLAUDE.md): no RNG; the first lash is staggered by the think
## slot (CovenantKit.first_cd()); targets are ordered by distance along the
## line, ties kept in the spatial hash's order.
## Stats: sister_lashes, sister_lash_summon_hits, sister_lash_player_hits,
## sister_zeal (surges); damage as summon_dmg_from_sister_lash /
## player_dmg_from_sister_lash (CombatResolver).
class_name BattleSisterKit
extends CovenantKit

## Phase: the lash line is telegraphed.
const WINDUP: int = 1
## Phase: the short stand after the crack.
const RECOVER: int = 2
## Damage source tag of the lash (CombatResolver stats; a strike, so neither
## area nor holy for Unholy Resilience).
const SOURCE: String = "sister_lash"

## Seconds until the next lash may start (counts down while idle).
var cd: float = 0.0
## Unit direction of the current lash (locked at the windup).
var dir: Vector2 = Vector2.RIGHT
## Seconds left of the current zeal surge (0 = calm).
var zeal_left: float = 0.0
## Seconds until a new surge may start.
var zeal_cd: float = 0.0
## Her move speed (px/s) outside a surge, captured on the first think after
## the spawner applied the difficulty's speed multiplier (-1 = not yet).
var _base_speed: float = -1.0
## Game time (s) of her last look for fallen comrades (deaths after it count).
var _seen_until: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["lash_first"]))
	zeal_left = 0.0
	zeal_cd = 0.0
	_base_speed = -1.0
	_seen_until = e.game.elapsed


## Ends a surge when she leaves the field (her speed is reset by activate()).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	zeal_left = 0.0


## Zeal check, then starts a lash at a target in reach.
func think(e: Enemy) -> void:
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	_check_zeal(e)
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Current target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - body_radius(e, t) > float(d["lash_trigger"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.stat_add("sister_lashes", 1.0)
	set_phase(e, WINDUP)


## A comrade fell near her since her last look: a zeal surge.
func _check_zeal(e: Enemy) -> void:
	var now := e.game.elapsed  # Run time (s).
	var since := _seen_until  # Deaths after this time are new to her.
	_seen_until = now
	if zeal_left > 0.0 or zeal_cd > 0.0:
		return
	if not e.game.enemies.rites.death_near(e.position, float(d["zeal_radius"]), since):
		return
	zeal_left = float(d["zeal_duration"])
	zeal_cd = float(d["zeal_cooldown"])
	e.move_speed = _base_speed * float(d["zeal_speed_mult"])
	e.game.stat_add("sister_zeal", 1.0)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the surge (visual only).
	e.queue_redraw()


func physics(e: Enemy, delta: float) -> bool:
	if zeal_cd > 0.0:
		zeal_cd -= delta
	if zeal_left > 0.0:
		zeal_left -= delta
		if zeal_left <= 0.0:
			e.move_speed = _base_speed  # The surge fades.
			e.queue_redraw()
	if phase == IDLE:
		cd -= delta * (float(d["zeal_lash_rate"]) if zeal_left > 0.0 else 1.0)
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			e.queue_redraw()  # The lash line flickers brighter.
			if phase_time >= float(d["lash_telegraph"]):
				_crack(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["lash_recover"]):
				cd = float(d["lash_cooldown"])
				set_phase(e, IDLE)
	return true


## The scourge cracks along the line: the nearest lash_targets bodies in it
## (summons and the necromancer) are struck.
func _crack(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["lash_reach"])  # Lash tip distance from her centre (px).
	var half := float(d["lash_width"]) * 0.5  # Half the lash width (px).
	var mult := hit_scale(e)  # Time scaling x aura buff.
	var tip := e.position + dir * reach  # World point of the lash tip.
	g.effects.beam(e.position + dir * e.radius, tip, Palette.CRIMSON)
	g.effects.slash(tip, dir, Palette.GOLD, 14.0)
	e.motion_lunge(dir, MotionData.POWER_MELEE)  # Engine motion: the crack (visual only).
	Sfx.play("rogue_dash", e.position, 1.45)
	# Pick the nearest bodies along the line (selection, no sort: stable).
	var picked: Array[Node2D] = []  # Struck bodies, nearest first.
	var picked_t: Array[float] = []  # Their distance along the line (px).
	var n := int(d["lash_targets"])  # Bodies one crack can strike.
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var t := _along(e, u.position, u.radius, reach, half)
		if t >= 0.0:
			_insert(picked, picked_t, u, t, n)
	for p in g.all_players:  # (Co-op: either necromancer can be in the line.)
		var tp := _along(e, p.position, p.radius, reach, half)
		if tp >= 0.0:
			_insert(picked, picked_t, p, tp, n)
	var summons := 0  # Summons struck (stat).
	for b: Node2D in picked:
		if b is SummonedUnit:
			summons += 1
			g.combat.damage_unit(b as SummonedUnit, float(d["lash_damage_summon"]) * mult * e.undead_damage_mult, SOURCE)
		else:
			g.stat_add("sister_lash_player_hits", 1.0)
			g.combat.damage_player(float(d["lash_damage_player"]) * mult, SOURCE, b as Necromancer)
	g.stat_add("sister_lash_summon_hits", float(summons))


## Distance (px) along the lash line of a body of radius `r` at `pos`, or -1
## when the body is not in the line (behind her, past the tip, or off it).
func _along(e: Enemy, pos: Vector2, r: float, reach: float, half: float) -> float:
	var rel := pos - e.position
	var t := rel.dot(dir)  # Distance along the line.
	if t < -r or t > reach + r:
		return -1.0
	if absf(rel.cross(dir)) > half + r:
		return -1.0
	return maxf(0.0, t)


## Inserts `b` (at line distance `t`) into the `n` nearest kept so far.
static func _insert(picked: Array[Node2D], picked_t: Array[float], b: Node2D, t: float, n: int) -> void:
	var i := picked.size()  # Insertion index.
	while i > 0 and picked_t[i - 1] > t:
		i -= 1
	if i >= n:
		return
	picked.insert(i, b)
	picked_t.insert(i, t)
	if picked.size() > n:
		picked.resize(n)
		picked_t.resize(n)


## Autopilot hint: sideways out of the telegraphed lash line.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP or _along(e, p, 12.0, float(d["lash_reach"]) + 8.0, float(d["lash_width"]) * 0.5 + 6.0) < 0.0:
		return Vector2.ZERO
	var side := Vector2(-dir.y, dir.x)  # Perpendicular to the line.
	return side if (p - e.position).dot(side) >= 0.0 else -side


## The lash line while it winds up; the zeal glow while she surges.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP and zeal_left <= 0.0:
		return
	unmirror(e, ci)
	if phase == WINDUP:
		SisterGlyphs.draw_lash_windup(ci, dir, e.radius, float(d["lash_reach"]), phase_time / maxf(0.01, float(d["lash_telegraph"])))
	if zeal_left > 0.0:
		SisterGlyphs.draw_zeal(ci, e.radius)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
