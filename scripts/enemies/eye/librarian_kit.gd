## LibrarianKit — THE LIBRARIAN, the Hollow Archive's miniboss (ArchiveEnemyData
## "librarian"; Act II, GDD §15.0 "Act II: the Hollow Archive", owner-approved
## proposal "a floating eye wrapped in tendrils"). Spawned once by its stage
## (ArchiveDirector, the "librarian" event) through the normal spawn path. It
## floats at the necromancer (faster beyond advance_range: it never kites and
## is never left behind), lashes what it reaches, and between attack_gap pauses
## uses one of two telegraphed specials (GDD §10.5):
##   The Index beam — a lane (beam_length x beam_width) toward the necromancer
##                    is telegraphed for beam_telegraph s (a slow, readable
##                    tell), then the beam burns down it for beam_fire_time s:
##                    every summon it crosses is TURNED AROUND for turn_time s
##                    (SummonedUnit.misdirect(): it walks away along the beam
##                    and does not fight) and takes beam_damage_summon; the
##                    necromancer in it takes beam_damage_player and, in Act
##                    II, beam_dread Dread ("gaze").
##   Tendril lash   — when lash_min_summons crowd it (or the necromancer is
##                    in reach), a circle of lash_radius around it for
##                    lash_telegraph s, then its tendrils sweep it: summons
##                    inside take lash_damage_summon and are thrown out, the
##                    necromancer takes lash_damage_player.
## The beam is preferred when both are ready (no RNG). Like the Cathedral
## Guardian it shrugs off knockback, Deep Freeze / stuns use the boss share
## (Enemy.is_miniboss), it is never recycled, registers as EnemyDirector
## .miniboss for the HUD's health bar, pays an XP burst on death and drops the
## guaranteed miniboss chest (ChestManager). Stats: librarian_beams,
## librarian_turned (summons turned around), librarian_beam_player_hits,
## librarian_lashes, librarian_lash_summon_hits, librarian_kills, librarian_ttk.
class_name LibrarianKit
extends CovenantKit

## Phase: the beam lane is telegraphed.
const BEAM_WINDUP: int = 1
## Phase: the beam burns down the lane.
const BEAM_FIRE: int = 2
## Phase: the lash circle is telegraphed.
const LASH_WINDUP: int = 3
## Phase: hanging still after a special.
const RECOVER: int = 4

## Seconds until the next special may start (counts down while floating).
var special_cd: float = 0.0
## Seconds until the beam may be used again.
var beam_cd: float = 0.0
## Seconds until the lash may be used again.
var lash_cd: float = 0.0
## Unit direction of the current beam (locked at the windup).
var beam_dir: Vector2 = Vector2.RIGHT
## True once the current beam hit the necromancer.
var _beam_hit_player: bool = false
## SummonedUnit -> generation of every summon the current beam turned.
var _beam_hits: Dictionary = {}
## Floating speed before the forced drift (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	beam_cd = 0.0
	lash_cd = 0.0
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	_beam_hits.clear()
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("librarian_spawned", 1.0)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var g := e.game
	var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
	if beam_cd <= 0.0 and dist <= float(d["beam_range"]):
		_start_beam(e)
	elif lash_cd <= 0.0 and (_crowd(e) >= int(d["lash_min_summons"]) or dist <= float(d["lash_radius"]) + g.player.radius):
		_start_lash(e)


## Summons inside the lash circle.
func _crowd(e: Enemy) -> int:
	var r := float(d["lash_radius"])
	e.game.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= r + u.radius:
			n += 1
	return n


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	beam_cd -= delta
	lash_cd -= delta
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
		return false
	phase_time += delta
	hold(e)
	match phase:
		BEAM_WINDUP:
			if phase_time >= float(d["beam_telegraph"]):
				_beam_hit_player = false
				_beam_hits.clear()
				Sfx.play("lance_cast", e.position, 0.6)
				set_phase(e, BEAM_FIRE)
		BEAM_FIRE:
			_beam_tick(e)
			if phase_time >= float(d["beam_fire_time"]):
				set_phase(e, RECOVER)
		LASH_WINDUP:
			if phase_time >= float(d["lash_telegraph"]):
				_resolve_lash(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


# =====================================================================================
# The Index beam
# =====================================================================================

## Telegraphs the beam lane toward the necromancer.
func _start_beam(e: Enemy) -> void:
	var to_p := e.game.player.position - e.position
	beam_dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	var length := float(d["beam_length"])
	e.game.effects.telegraph_line(e.position, e.position + beam_dir * length, float(d["beam_width"]), float(d["beam_telegraph"]), e)
	e.motion_lunge(beam_dir, MotionData.POWER_CAST)  # Engine motion: the eye opens (visual only).
	beam_cd = float(d["beam_cooldown"])
	e.game.stat_add("librarian_beams", 1.0)
	set_phase(e, BEAM_WINDUP)


## The beam this tick: summons it crosses are turned around (once each per
## beam), the necromancer is hit once.
func _beam_tick(e: Enemy) -> void:
	var g := e.game
	var length := float(d["beam_length"])
	var half_w := float(d["beam_width"]) * 0.5
	var mult := hit_scale(e)  # Time scaling x aura buff.
	var p := g.player
	if not _beam_hit_player and GuardianKit._on_beam(e.position, beam_dir, length, half_w, p.position, p.radius):
		_beam_hit_player = true
		g.stat_add("librarian_beam_player_hits", 1.0)
		g.combat.damage_player(float(d["beam_damage_player"]) * mult, "librarian_beam")
		if g.dread != null:
			g.dread.add(float(d["beam_dread"]), "gaze")
	var mid := e.position + beam_dir * length * 0.5  # Query centre.
	g.ally_grid.query(mid, length * 0.5 + half_w + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if _beam_hits.has(u) and int(_beam_hits[u]) == u.generation:
			continue
		if not GuardianKit._on_beam(e.position, beam_dir, length, half_w, u.position, u.radius):
			continue
		_beam_hits[u] = u.generation
		g.combat.damage_unit(u, float(d["beam_damage_summon"]) * mult, "librarian_beam")
		if u.active and u.misdirect(beam_dir, float(d["turn_time"]), float(d.get("turn_speed", 0.6))):
			g.stat_add("librarian_turned", 1.0)


# =====================================================================================
# Tendril lash
# =====================================================================================

## Telegraphs the lash circle around itself.
func _start_lash(e: Enemy) -> void:
	e.game.effects.telegraph_circle(e.position, float(d["lash_radius"]), float(d["lash_telegraph"]), e)
	lash_cd = float(d["lash_cooldown"])
	e.game.stat_add("librarian_lashes", 1.0)
	set_phase(e, LASH_WINDUP)


## The tendrils sweep the circle.
func _resolve_lash(e: Enemy) -> void:
	var g := e.game
	var r := float(d["lash_radius"])
	var mult := hit_scale(e)
	g.effects.impact(e.position, r, ArchiveEnemyData.INK_SHEEN)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: the lash (visual only).
	g.shake(5.0)
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(e.position) > r + u.radius:
			continue
		hits += 1
		var away := u.position - e.position  # Throw direction.
		var to := u.position + (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(d["lash_knockback"])
		u.position = g.arena.free_point(to, u.radius)
		g.combat.damage_unit(u, float(d["lash_damage_summon"]) * mult, "librarian_lash")
	g.stat_add("librarian_lash_summon_hits", float(hits))
	var p := g.player
	if p.position.distance_to(e.position) <= r + p.radius:
		g.combat.damage_player(float(d["lash_damage_player"]) * mult, "librarian_lash")


# =====================================================================================
# Death, hints, drawing
# =====================================================================================

## XP burst on death (the chest comes from ChestManager's miniboss rule).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, ArchiveEnemyData.INK_SHEEN)
	g.shake(10.0)
	g.enemies.show_banner("The Librarian's eye closes forever!")
	g.stat_add("librarian_kills", 1.0)
	g.stat_add("librarian_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the beam lane / lash circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		BEAM_WINDUP, BEAM_FIRE:
			var rel := p - e.position
			var along := rel.dot(beam_dir)
			var side := rel.cross(beam_dir)
			if along > -20.0 and along < float(d["beam_length"]) + 20.0 and absf(side) < float(d["beam_width"]) * 0.5 + 24.0:
				var n := Vector2(-beam_dir.y, beam_dir.x)
				return n * (-1.0 if side > 0.0 else 1.0)
		LASH_WINDUP:
			var off := p - e.position
			if off.length() < float(d["lash_radius"]) + 30.0:
				return off.normalized() if off.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## The eye charging (beam windup), the beam itself and the raised tendrils.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	match phase:
		BEAM_WINDUP:
			ArchiveGlyphs.draw_eye_charge(ci, Vector2(0, -e.radius * 0.4), e.radius, phase_time / maxf(0.05, float(d["beam_telegraph"])))
		BEAM_FIRE:
			unmirror(e, ci)
			ArchiveGlyphs.draw_index_beam(ci, beam_dir * float(d["beam_length"]), float(d["beam_width"]), e.game.elapsed)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		LASH_WINDUP:
			ArchiveGlyphs.draw_tendrils_raised(ci, e.radius)
