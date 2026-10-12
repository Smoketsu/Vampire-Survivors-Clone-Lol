## RogueBehavior — the Grave Rogue's Dash Strike ("dash", UnitData), modelled
## on the enemy Templar charge. The rogue is an ordinary fast melee summon
## whose target scoring ("assassin" weights + score_bonus()) favours backline
## archers, Chaplains and consecrators at the back of the crowd. Then:
##   1. think(): with the dash ready and its target dash_min..dash_length px
##      away, it measures the lane with Arena.clear_length() (obstacles cut it
##      short; a lane that stops before the target is not used, and the end
##      must stay inside the soft leash), plants itself (CASTING) and shows a
##      violet lane for dash_telegraph s,
##   2. it dashes along the lane at dash_speed: every enemy whose body touches
##      the lane takes dash_damage once and bleeds (bleed_damage every
##      bleed_tick s for bleed_duration s),
##   3. it ends on a free point (Arena.free_point(), never inside an
##      obstacle), drops its target and RETURNs to its formation slot.
## Bleeds are ticked by the rogue that caused them and stop if it dies.
## Shadow Reaper (summon evolution; its special keys come from
## SummonEvolutionData "special_set" and are absent / 0 on the base Rogue,
## which keeps exactly the behaviour above):
##   * chain: when a dash ends and chain dashes are left, the nearest enemy
##     not struck by this chain that passes the same checks as think() (in
##     dash range of the new spot, a lane clear of obstacles reaching it, an
##     end inside the soft leash; target also inside the engagement leash)
##     is dashed at after a short chain_telegraph, in the same CASTING
##     special. Every lane ends on Arena.free_point(). No valid target ends
##     the chain.
##   * stacking bleeds: one rogue keeps up to bleed_stacks bleeds on one
##     enemy; each dash hit adds a stack with its own tick timer and
##     duration (every stack ticks bleed_damage), and at the cap the stack
##     with the fewest ticks left is refreshed instead. The base Rogue has 1
##     stack (a hit refreshes it, as before).
##   * kill reset: a dash hit that kills sets a reset; when the chain ends
##     the cooldown drops to dash_reset_floor (never 0) instead of the full
##     dash_cooldown. At most one reset per chain, so kills cannot loop.
## Stats: rogue_dashes, rogue_dash_hits, dmg_rogue_dash, dmg_rogue_bleed,
## summon_special_end_blocked (a dash that ended inside an obstacle: must be 0);
## Shadow Reaper: reaper_chain_dashes, reaper_cd_resets,
## reaper_bleed_stacks_added, reaper_max_bleed_stacks (a maximum, not a sum).
class_name RogueBehavior
extends SummonBehavior

## Phase: the lane is telegraphed.
const AIM: int = 1
## Phase: dashing along the lane.
const DASH: int = 2
## Safety cap on bleeds ticked by one rogue (not a balance number: a dash
## every few seconds keeps far fewer alive).
const MAX_BLEEDS: int = 24
## Enemy behaviours counted as "backline" for the target bonus.
const BACKLINE := ["ranged", "healer", "consecrator"]
## Safety cap on the lane checks (Arena.clear_length()) one chain search
## makes, nearest candidates first (performance guard, not a balance number).
const CHAIN_LANE_CHECKS: int = 6

## Unit direction of the current dash.
var dash_dir: Vector2 = Vector2.RIGHT
## Length (px) of the current lane (already cut by obstacles).
var lane_len: float = 0.0
## Distance (px) still to dash.
var dash_left: float = 0.0
## Enemy -> generation of every enemy already hit by this dash.
var _hits: Dictionary = {}
## Running bleeds: {"e": Enemy, "gen": int, "left": ticks, "t": s to next tick, "dmg": per tick}.
var _bleeds: Array[Dictionary] = []
## Reusable enemy query buffer.
var _buf: Array = []
## Seconds the current lane is telegraphed (dash_telegraph, or the Shadow
## Reaper's chain_telegraph for a chained dash).
var _aim_time: float = 0.0
## Chained dashes still allowed in the running special (Shadow Reaper; 0 = none).
var _chain_left: int = 0
## True once a dash hit of the running chain killed an enemy (Shadow Reaper
## cooldown reset, applied when the chain ends).
var _reset_pending: bool = false


## Number of bleed ticks for special numbers `s` (bleed_duration / bleed_tick).
static func bleed_ticks(s: Dictionary) -> int:
	return maxi(1, roundi(float(s["bleed_duration"]) / maxf(float(s["bleed_tick"]), 0.05)))


## Full dash cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("dash_cooldown", 4.5))


## Bleeds stop with the rogue.
func on_deactivate(u: SummonedUnit) -> void:
	super(u)
	_bleeds.clear()
	_hits.clear()
	_chain_left = 0
	_reset_pending = false


## Starts a dash onto the current target when it is in range and the lane
## reaches it.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0 or not u.target_alive():
		return false
	var t := u.target
	var to_t := t.position - u.position  # Rogue -> target.
	var d := to_t.length()  # Distance to the target (px).
	var max_len := float(u.special["dash_length"])  # Longest lane (px).
	if d < float(u.special["dash_min"]) or d > max_len:
		return false
	var dir := to_t / d  # Dash direction.
	var want := minf(d + float(u.special["dash_overshoot"]), max_len)  # Lane through the target.
	var clear_len := u.game.arena.clear_length(u.position, dir, want, u.radius * 0.8)  # Obstacle-free part.
	if clear_len < d:
		return false  # An obstacle stands between the rogue and its target.
	var end := u.position + dir * clear_len  # Where the dash ends.
	if end.distance_to(u.game.player.position) > u.soft_recall - u.band_max * 0.5:
		return false  # Would end beyond the leash.
	dash_dir = dir
	lane_len = clear_len
	dash_left = clear_len
	_hits.clear()
	_aim_time = float(u.special["dash_telegraph"])
	_chain_left = int(u.special.get("chain_dashes", 0))
	_reset_pending = false
	begin_special(u, AIM)
	u.game.stat_add("rogue_dashes", 1.0)
	return true


## Ticks bleeds every frame, then the base special handling.
func physics(u: SummonedUnit, delta: float) -> bool:
	if not _bleeds.is_empty():
		_tick_bleeds(u, delta)
	return super(u, delta)


## Lane telegraph, then the dash itself.
func step_special(u: SummonedUnit, delta: float) -> bool:
	match phase:
		AIM:
			u.velocity = Vector2.ZERO
			if phase_time >= _aim_time:
				next_phase(DASH)
				Sfx.play("rogue_dash", u.position)
		DASH:
			var step_len := minf(float(u.special["dash_speed"]) * delta, dash_left)  # px this tick.
			var next := u.position + dash_dir * step_len  # Position after this tick.
			dash_left -= step_len
			_hit_lane(u, next)
			if dash_left <= 0.0:
				_finish(u, next)
			else:
				u.velocity = dash_dir * (step_len / maxf(delta, 0.0001))
	return true


## Damages (once) and bleeds every enemy touching the lane at `pos`.
func _hit_lane(u: SummonedUnit, pos: Vector2) -> void:
	var half := float(u.special["dash_width"]) * 0.5  # Lane half-width (px).
	u.game.enemy_grid.query(pos, half + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > half + e.radius:
			continue
		if _hits.has(e) and int(_hits[e]) == e.generation:
			continue
		_hits[e] = e.generation
		u.game.stat_add("rogue_dash_hits", 1.0)
		_add_bleed(u, e)
		u.game.combat.damage_enemy(e, float(u.special["dash_damage"]), "rogue_dash")
		if not e.active and int(u.special.get("dash_kill_reset", 0)) > 0:
			_reset_pending = true  # Shadow Reaper: the dash killed it.


## Ends the dash at `pos` (moved out of any obstacle). A Shadow Reaper with
## chain dashes left chains on; otherwise the special ends (applying a
## pending kill reset) and the rogue returns to formation.
func _finish(u: SummonedUnit, pos: Vector2) -> void:
	u.position = u.game.arena.free_point(pos, u.radius)
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)
	u.game.effects.slash(u.position, dash_dir, Palette.VIOLET, u.radius * 1.8)
	if _chain_left > 0 and _try_chain(u):
		return
	if _reset_pending:
		_reset_pending = false
		special_cd = minf(special_cd, float(u.special["dash_reset_floor"]))
		u.game.stat_add("reaper_cd_resets", 1.0)
		u.game.effects.ring(u.position, u.radius * 2.2, Palette.VIOLET, 0.3)
	_chain_left = 0
	u.clear_target()
	end_special(u, SummonedUnit.State.RETURNING)


## Shadow Reaper chain: picks the nearest enemy not struck by this chain
## whose lane from the current spot passes the think() checks (dash_min..
## dash_length away, target inside the engagement leash, the obstacle-free
## lane reaches it, the lane end inside the soft leash) and starts a chained
## dash at it (AIM for chain_telegraph s). False if there is none.
func _try_chain(u: SummonedUnit) -> bool:
	var game := u.game
	var from := u.position  # Where the last dash ended (a free point).
	var max_len := float(u.special["dash_length"])  # Longest lane (px).
	var min_len := float(u.special["dash_min"])  # Shortest dash (px).
	var player := game.player.position
	var leash := u.soft_recall - u.band_max * 0.5  # Max lane-end distance to the player (px).
	game.enemy_grid.query(from, max_len + ProjectileManager.MAX_BODY_RADIUS, _buf)
	# Candidates passing the cheap checks, as [distance, enemy] pairs.
	var cands: Array = []
	for e: Enemy in _buf:
		if not e.active or (_hits.has(e) and int(_hits[e]) == e.generation):
			continue
		var d := from.distance_to(e.position)  # Distance to the candidate (px).
		if d < min_len or d > max_len or e.position.distance_to(player) > u.engage_radius:
			continue
		cands.append([d, e])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for i in mini(cands.size(), CHAIN_LANE_CHECKS):
		var d := float(cands[i][0])  # Distance to this candidate (px).
		var e: Enemy = cands[i][1]
		var dir := (e.position - from) / d  # Chained dash direction.
		var want := minf(d + float(u.special["dash_overshoot"]), max_len)  # Lane through the target.
		var clear_len := game.arena.clear_length(from, dir, want, u.radius * 0.8)  # Obstacle-free part.
		if clear_len < d:
			continue  # An obstacle stands in the way.
		if (from + dir * clear_len).distance_to(player) > leash:
			continue  # Would end beyond the leash.
		dash_dir = dir
		lane_len = clear_len
		dash_left = clear_len
		_chain_left -= 1
		_aim_time = float(u.special.get("chain_telegraph", u.special["dash_telegraph"]))
		next_phase(AIM)
		u.velocity = Vector2.ZERO
		game.stat_add("reaper_chain_dashes", 1.0)
		return true
	return false


## Adds a bleed stack on `e` (up to bleed_stacks: 1 on the base Rogue, 3
## on the Shadow Reaper); at the cap the stack with the fewest ticks left is
## refreshed instead.
func _add_bleed(u: SummonedUnit, e: Enemy) -> void:
	var ticks := bleed_ticks(u.special)  # Ticks of a fresh bleed.
	var tick := float(u.special["bleed_tick"])  # Seconds between ticks.
	var stacks := maxi(1, int(u.special.get("bleed_stacks", 1)))  # Stack cap per enemy.
	var have := 0  # Stacks already on `e`.
	var oldest: Dictionary = {}  # The stack on `e` with the fewest ticks left.
	for b in _bleeds:
		if b["e"] == e and int(b["gen"]) == e.generation:
			have += 1
			if oldest.is_empty() or int(b["left"]) < int(oldest["left"]):
				oldest = b
	if have >= stacks:
		oldest["left"] = ticks
		return
	if _bleeds.size() >= MAX_BLEEDS * stacks:
		return
	_bleeds.append({"e": e, "gen": e.generation, "left": ticks, "t": tick, "dmg": float(u.special["bleed_damage"])})
	if have > 0:
		u.game.stat_add("reaper_bleed_stacks_added", 1.0)
		u.game.stats["reaper_max_bleed_stacks"] = maxf(float(u.game.stats.get("reaper_max_bleed_stacks", 0.0)), float(have + 1))


## Applies due bleed ticks and drops finished / stale bleeds.
func _tick_bleeds(u: SummonedUnit, delta: float) -> void:
	var tick := float(u.special["bleed_tick"])  # Seconds between ticks.
	var i := 0  # Index (swap-remove while iterating).
	while i < _bleeds.size():
		var b := _bleeds[i]  # One running bleed.
		var e: Enemy = b["e"]
		if not e.active or e.generation != int(b["gen"]) or int(b["left"]) <= 0:
			_bleeds[i] = _bleeds[_bleeds.size() - 1]
			_bleeds.pop_back()
			continue
		b["t"] = float(b["t"]) - delta
		if float(b["t"]) <= 0.0:
			b["t"] = float(b["t"]) + tick
			b["left"] = int(b["left"]) - 1
			u.game.combat.damage_enemy(e, float(b["dmg"]), "rogue_bleed")
		i += 1


## Assassin preference: backline enemies, and enemies far from the player.
func score_bonus(u: SummonedUnit, e: Enemy, dp: float) -> float:
	var s := float(u.special["far_bonus"]) * clampf(dp / u.engage_radius, 0.0, 1.0)  # Bonus.
	if e.behavior in BACKLINE:
		s += float(u.special["backline_bonus"])
	return s


## Lane telegraph (filling like the Templar lane) and the dash streak.
func draw_under(u: SummonedUnit) -> void:
	if phase == IDLE:
		return
	world_space(u)
	var half := float(u.special["dash_width"]) * 0.5  # Lane half-width (px).
	var perp := Vector2(-dash_dir.y, dash_dir.x) * half  # Lane side offset.
	if phase == AIM:
		var k := clampf(phase_time / maxf(_aim_time, 0.01), 0.0, 1.0)  # Fill.
		var v := dash_dir * lane_len  # Lane vector.
		u.draw_colored_polygon(PackedVector2Array([perp, v + perp, v - perp, -perp]), Color(Palette.VIOLET, 0.12))
		u.draw_colored_polygon(PackedVector2Array([perp, v * k + perp, v * k - perp, -perp]), Color(Palette.VIOLET, 0.28))
		u.draw_polyline(PackedVector2Array([perp, v + perp, v - perp, -perp, perp]), Color(Palette.VIOLET, 0.8), 1.5)
	else:
		u.draw_line(-dash_dir * 28.0, Vector2.ZERO, Color(Palette.VIOLET, 0.5), half)
		u.draw_line(-dash_dir * 16.0, Vector2.ZERO, Color(Palette.BONE, 0.6), 2.0)
	body_space(u)
