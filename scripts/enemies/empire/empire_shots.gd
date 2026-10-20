## EmpireShots — LINE OF FIRE, the first of the Electronic Empire's shared
## rules (Act III; GDD §15.0 "Line of Fire: your dead are cover"): "Every Empire
## shot travels as a real projectile and stops on the first summon in its
## path. The necromancer is hit only by shots that find a gap." The ONE path of
## every Empire shot: the kits (drone zaps, rifle bursts) and LockOn's heavy
## rail fire through fire(); a mortar lobs through fire_arc().
##
## Each tick a straight shot moves from a to b and is resolved against, in
## order: the Orb Shield (the Umbral Warden's Eclipsed Guard, then the
## charge-limited intercept: the hostile-arrow rules), then the FIRST body its
## path a -> b touches among
##   * a Bone Wall segment (the spell's or an Ossuary Titan's wall;
##     NecroSpellBook "bone_wall" node, BoneWall.shot_block_t()),
##   * a summon (the ally spatial hash, only the summons near the path; a flying
##     Gargoyle is not in the hash, so shots pass under it): the hit goes
##     through CombatResolver.damage_unit(), where a Warder / Bishop barrier
##     absorbs it like any hit,
##   * the necromancer: CombatResolver.damage_player() (i-frames, wards, Dread
##     and every reduction apply there).
## A shot of an "arc" style (EmpireRulesData.SHOT_STYLES, mortars) ignores Line
## of Fire: it flies over everything to its landing point and bursts there
## (every summon and the necromancer in its splash).
##
## Storage: pooled packed arrays with a hard cap (EmpireRulesData.LINE_OF_FIRE
## "cap"; a shot asked beyond it is dropped and counted), live shots packed in
## [0, count) and removed by swapping the last one in (deterministic order;
## no nodes, no instance ids). Drawn by this one node; Effects: Reduced draws at
## most draw_cap_reduced of them. Nothing here touches ProjectileManager, so
## the Act I / II arrows and their cap are unchanged.
## Stats (Game.stats, Act III only): los_fired, los_fired_heavy, los_fired_arc,
## los_blocked_summon, los_barrier_absorbed, los_blocked_wall, los_blocked_orb,
## los_hit_player, los_player_dmg, los_heavy_blocked, los_heavy_player,
## los_arc_bursts, los_expired, los_capped.
class_name EmpireShots
extends Node2D

## Owning run.
var game: Game
## Live shots (indices [0, count) of every array below).
var count: int = 0
## Most shots alive at once this run (the autotest's "line of fire" line).
var peak: int = 0
## Hard cap (EmpireRulesData.LINE_OF_FIRE "cap").
var _cap: int = 0
## Position (world px) of each shot (arcing: its ground point).
var _pos: PackedVector2Array = PackedVector2Array()
## Velocity (px/s) of each shot (arcing: its ground velocity).
var _vel: PackedVector2Array = PackedVector2Array()
## Damage of each shot (already time-scaled by the firer).
var _dmg: PackedFloat32Array = PackedFloat32Array()
## Multiplier of each shot's damage on a summon (the firer's undead_damage_mult).
var _umult: PackedFloat32Array = PackedFloat32Array()
## Seconds of flight left of each shot (arcing: until it lands).
var _life: PackedFloat32Array = PackedFloat32Array()
## Total flight time (s) of each arcing shot (0 for a straight shot).
var _flight: PackedFloat32Array = PackedFloat32Array()
## Style index (into _style_ids order) of each shot.
var _style: PackedInt32Array = PackedInt32Array()
## Damage source tag of each shot (the firer's kind, "spotter_rail"...).
var _src: PackedStringArray = PackedStringArray()
## Style id -> index (EmpireRulesData.SHOT_STYLES keys, in their order).
var _style_ids: Dictionary = {}
## Style rows by index (EmpireRulesData.SHOT_STYLES values).
var _styles: Array[Dictionary] = []
## Hit radius (px) by style index.
var _radius: PackedFloat32Array = PackedFloat32Array()
## True by style index for an arcing style.
var _arc: Array[bool] = []
## True by style index for a heavy style (the Lock-On rail).
var _heavy: Array[bool] = []
## Reusable spatial-hash query buffer.
var _tmp: Array = []
## True if the last redraw showed shots (one more redraw clears them).
var _drawn: bool = false


## Builds the pool for `p_game` (EmpireRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "EmpireShots"
	z_index = 2  # With the ProjectileManager's arrows, above the units.
	z_as_relative = false  # Not under EmpireRules' ground layer.
	_cap = int(EmpireRulesData.LINE_OF_FIRE["cap"])
	_pos.resize(_cap)
	_vel.resize(_cap)
	_dmg.resize(_cap)
	_umult.resize(_cap)
	_life.resize(_cap)
	_flight.resize(_cap)
	_style.resize(_cap)
	_src.resize(_cap)
	for id: String in EmpireRulesData.SHOT_STYLES:
		var row: Dictionary = EmpireRulesData.SHOT_STYLES[id]
		_style_ids[id] = _styles.size()
		_styles.append(row)
		_radius.append(float(row["radius"]))
		_arc.append(bool(row["arc"]))
		_heavy.append(bool(row["heavy"]))


# =====================================================================================
# Firing
# =====================================================================================

## Fires a straight Empire shot from `pos` along unit direction `dir` at
## `speed` px/s, dealing `damage` (already time-scaled; x `undead_mult` on a
## summon), with look `style` (EmpireRulesData.SHOT_STYLES id; an arcing style
## is fired straight here, use fire_arc()) and damage tag `source`. It flies
## `reach` px x LINE_OF_FIRE.life_mult before fading. Returns false when the
## cap dropped it.
func fire(pos: Vector2, dir: Vector2, speed: float, damage: float, undead_mult: float, style: String, source: String, reach: float) -> bool:
	var i := _take()  # Free slot (-1 = capped).
	if i < 0:
		return false
	var si := int(_style_ids.get(style, 0))  # Style index.
	_pos[i] = pos
	_vel[i] = dir * speed
	_dmg[i] = damage
	_umult[i] = undead_mult
	_life[i] = reach * float(EmpireRulesData.LINE_OF_FIRE["life_mult"]) / maxf(speed, 1.0)
	_flight[i] = 0.0
	_style[i] = si
	_src[i] = source
	game.stat_add("los_fired", 1.0)
	if _heavy[si]:
		game.stat_add("los_fired_heavy", 1.0)
	return true


## Lobs an arcing shot (Line of Fire does not apply: mortars) from `from` to
## `dest`, landing after `flight` s and bursting there for `damage` (x
## `undead_mult` on summons) on every body within its style's splash.
## Returns false when the cap dropped it.
func fire_arc(from: Vector2, dest: Vector2, flight: float, damage: float, undead_mult: float, style: String, source: String) -> bool:
	var i := _take()  # Free slot (-1 = capped).
	if i < 0:
		return false
	var f := maxf(0.05, flight)  # Flight time (s).
	_pos[i] = from
	_vel[i] = (dest - from) / f
	_dmg[i] = damage
	_umult[i] = undead_mult
	_life[i] = f
	_flight[i] = f
	_style[i] = int(_style_ids.get(style, 0))
	_src[i] = source
	game.stat_add("los_fired", 1.0)
	game.stat_add("los_fired_arc", 1.0)
	return true


## The next free slot, or -1 when the cap is reached (the shot is counted as capped).
func _take() -> int:
	if count >= _cap:
		game.stat_add("los_capped", 1.0)
		return -1
	count += 1
	peak = maxi(peak, count)
	return count - 1


## Removes shot `i` by moving the last live shot into its slot.
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_dmg[i] = _dmg[last]
		_umult[i] = _umult[last]
		_life[i] = _life[last]
		_flight[i] = _flight[last]
		_style[i] = _style[last]
		_src[i] = _src[last]
	count = last


# =====================================================================================
# Update
# =====================================================================================

## Moves every shot and resolves its hits (EmpireRules.step(), once per tick).
func step(delta: float) -> void:
	var i := 0
	while i < count:
		if _step_one(i, delta):
			i += 1
		else:
			_remove(i)
	if count > 0 or _drawn:
		queue_redraw()
	_drawn = count > 0


## Advances shot `i` by `delta` s. Returns false when it is spent.
func _step_one(i: int, delta: float) -> bool:
	var a := _pos[i]  # Where it was.
	var b := a + _vel[i] * delta  # Where it is now.
	_pos[i] = b
	_life[i] -= delta
	var si := _style[i]  # Style index.
	if _arc[si]:
		if _life[i] <= 0.0:
			_arc_burst(i)
			return false
		return true
	if _life[i] <= 0.0:
		game.stat_add("los_expired", 1.0)
		return false
	var r := _radius[si]  # Hit radius (px).
	# The Orb Shield first (the hostile-arrow rules): any orb destroys a shot
	# with the Eclipsed Guard innate, else a charge-limited intercept.
	if game.innates.eclipsed_guard(b, r) or game.abilities.try_intercept(b, r):
		game.effects.pop(b, Palette.VIOLET, 6.0)
		game.stat_add("los_blocked_orb", 1.0)
		return false
	# The first body on the path a -> b: a Bone Wall segment, a summon or the necromancer.
	var best_t := INF  # Path fraction (0..1) of the first touch.
	var wall: BoneWall = game.abilities.spells.nodes.get("bone_wall")  # Null until a wall exists.
	if wall != null:
		best_t = wall.shot_block_t(a, b, r)
	var hit_unit: SummonedUnit = null  # First summon touched (null = none before best_t).
	var half := (b - a).length() * 0.5  # Half the path length (px).
	game.ally_grid.query((a + b) * 0.5, half + r + float(EmpireRulesData.LINE_OF_FIRE["summon_slack"]), _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var t := segment_t(a, b, u.position, u.radius + r)
		if t < best_t:
			best_t = t
			hit_unit = u
	var pl := game.player  # The necromancer.
	var hit_player := false  # The necromancer is the first body touched.
	if not pl.dead:
		var tp := segment_t(a, b, pl.position, pl.radius + r)
		if tp < best_t:
			best_t = tp
			hit_player = true
			hit_unit = null
	if best_t == INF:
		return true  # Nothing touched: it flies on.
	var at := a.lerp(b, best_t)  # Where it struck.
	var heavy := _heavy[si]  # A Lock-On rail.
	if hit_player:
		var before := float(game.stats.get("damage_to_player", 0.0))  # To count what landed.
		game.combat.damage_player(_dmg[i], _src[i])
		game.stat_add("los_hit_player", 1.0)
		game.stat_add("los_player_dmg", float(game.stats.get("damage_to_player", 0.0)) - before)
		if heavy:
			game.stat_add("los_heavy_player", 1.0)
	elif hit_unit != null:
		if hit_unit.barrier_hp > 0.0:
			game.stat_add("los_barrier_absorbed", 1.0)  # A Warder / Bishop barrier takes it first.
		game.combat.damage_unit(hit_unit, _dmg[i] * _umult[i], _src[i])
		game.stat_add("los_blocked_summon", 1.0)
		if heavy:
			game.stat_add("los_heavy_blocked", 1.0)
	else:
		game.stat_add("los_blocked_wall", 1.0)  # A Bone Wall segment.
	if heavy or int(game.stats.get("los_fired", 0.0)) % 3 == 0:
		game.effects.pop(at, Color(_styles[si]["color"]), 5.0 if not heavy else 9.0)  # A spark (every third light shot).
	return false


## An arcing shot lands: everything within its style's splash takes its damage.
func _arc_burst(i: int) -> void:
	var at := _pos[i]  # Landing point.
	var splash := float(_styles[_style[i]]["splash"])  # Burst radius (px).
	game.effects.impact(at, splash, Color(_styles[_style[i]]["color"]))
	game.stat_add("los_arc_bursts", 1.0)
	var pl := game.player  # The necromancer.
	if not pl.dead and pl.position.distance_to(at) <= splash + pl.radius:
		game.combat.damage_player(_dmg[i], _src[i])
	game.ally_grid.query(at, splash + float(EmpireRulesData.LINE_OF_FIRE["summon_slack"]), _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(at) <= splash + u.radius:
			game.combat.damage_unit(u, _dmg[i] * _umult[i], _src[i])


## The path fraction t (0..1) at which a point moving from `a` to `b` first
## comes within `reach` px of `c`; 0 when `a` is already inside, INF when it
## never does. Shared by the Bone Wall test (BoneWall.shot_block_t()).
static func segment_t(a: Vector2, b: Vector2, c: Vector2, reach: float) -> float:
	var f := a - c  # Centre -> start.
	var cc := f.length_squared() - reach * reach
	if cc <= 0.0:
		return 0.0
	var d := b - a  # Path.
	var aa := d.length_squared()
	if aa < 0.0001:
		return INF
	var bb := 2.0 * f.dot(d)
	if bb >= 0.0:
		return INF  # Moving away from the centre.
	var disc := bb * bb - 4.0 * aa * cc
	if disc < 0.0:
		return INF
	var t := (-bb - sqrt(disc)) / (2.0 * aa)
	return t if t <= 1.0 else INF


# =====================================================================================
# Drawing (cosmetic; never read by gameplay)
# =====================================================================================

func _draw() -> void:
	var n := count  # Shots to draw.
	if Settings.reduced_effects():
		n = mini(n, int(EmpireRulesData.LINE_OF_FIRE["draw_cap_reduced"]))  # Phones draw fewer.
	for i in n:
		var si := _style[i]
		var row := _styles[si]
		var col: Color = row["color"]
		var p := _pos[i]
		var v := _vel[i]
		var dir := v.normalized() if v.length_squared() > 0.01 else Vector2.RIGHT
		var w := float(row["width"])  # Tracer width (px).
		if _arc[si]:
			# A lob: the shell drawn above its ground point, its landing circle shown last.
			var k := 1.0 - _life[i] / maxf(_flight[i], 0.01)  # 0 -> 1 through the flight.
			var dest := p + v * _life[i]  # Landing point.
			var h := 4.0 * k * (1.0 - k) * v.length() * _flight[i] * EmpireRulesData.ARC_HEIGHT_PER_PX  # Height (px).
			if _life[i] <= EmpireRulesData.ARC_TELEGRAPH:
				draw_arc(dest, float(row["splash"]), 0.0, TAU, 28, Color(Palette.EMPIRE_SIGNAL_RED, 0.7), 1.5)
			draw_circle(p + Vector2(0, -h), w * 0.5 + 1.0, Color(col, 0.5))
			draw_circle(p + Vector2(0, -h), w * 0.5, col.lerp(Color.WHITE, 0.3))
			continue
		var length := float(row["length"])  # Tracer length (px).
		var tail := p - dir * length
		draw_line(tail, p, Color(col, 0.35), w + 2.0)
		draw_line(p - dir * length * 0.6, p, col.lerp(Color.WHITE, 0.45), w)
		if _heavy[si]:
			draw_circle(p, w, Palette.EMPIRE_SIGNAL_GLOW)
