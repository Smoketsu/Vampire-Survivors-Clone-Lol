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
## Stats: rogue_dashes, rogue_dash_hits, dmg_rogue_dash, dmg_rogue_bleed,
## summon_special_end_blocked (a dash that ended inside an obstacle: must be 0).
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
			if phase_time >= float(u.special["dash_telegraph"]):
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


## Ends the dash at `pos` (moved out of any obstacle) and returns to formation.
func _finish(u: SummonedUnit, pos: Vector2) -> void:
	u.position = u.game.arena.free_point(pos, u.radius)
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)
	u.game.effects.slash(u.position, dash_dir, Palette.VIOLET, u.radius * 1.8)
	u.clear_target()
	end_special(u, SummonedUnit.State.RETURNING)


## Starts (or refreshes) a bleed on `e`.
func _add_bleed(u: SummonedUnit, e: Enemy) -> void:
	var ticks := bleed_ticks(u.special)  # Ticks of a fresh bleed.
	var tick := float(u.special["bleed_tick"])  # Seconds between ticks.
	for b in _bleeds:
		if b["e"] == e and int(b["gen"]) == e.generation:
			b["left"] = ticks
			return
	if _bleeds.size() >= MAX_BLEEDS:
		return
	_bleeds.append({"e": e, "gen": e.generation, "left": ticks, "t": tick, "dmg": float(u.special["bleed_damage"])})


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
		var k := clampf(phase_time / maxf(float(u.special["dash_telegraph"]), 0.01), 0.0, 1.0)  # Fill.
		var v := dash_dir * lane_len  # Lane vector.
		u.draw_colored_polygon(PackedVector2Array([perp, v + perp, v - perp, -perp]), Color(Palette.VIOLET, 0.12))
		u.draw_colored_polygon(PackedVector2Array([perp, v * k + perp, v * k - perp, -perp]), Color(Palette.VIOLET, 0.28))
		u.draw_polyline(PackedVector2Array([perp, v + perp, v - perp, -perp, perp]), Color(Palette.VIOLET, 0.8), 1.5)
	else:
		u.draw_line(-dash_dir * 28.0, Vector2.ZERO, Color(Palette.VIOLET, 0.5), half)
		u.draw_line(-dash_dir * 16.0, Vector2.ZERO, Color(Palette.BONE, 0.6), 2.0)
	body_space(u)
