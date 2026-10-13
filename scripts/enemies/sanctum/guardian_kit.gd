## GuardianKit — the Cathedral Guardian, a plain construct miniboss (owner
## decision, GDD §15.0; GDD §7.4 / §8.3 "Cathedral Guardians: construct
## minibosses controlling route access"). Spawned once by its stage through
## the normal spawn path (EnemyDirector.spawn_at("cathedral_guardian", ...)).
## It walks at the necromancer (strides faster beyond advance_range: it never
## kites and never gets left behind), punches what it reaches, and between
## attack_gap pauses uses one of two telegraphed specials (GDD §10.5):
##   Ground slam    — a gold circle (slam_radius) on the necromancer's spot,
##                    slam_telegraph s, then the fists land: undead inside
##                    take slam_damage_summon and are thrown out of the
##                    circle; the necromancer takes slam_damage_player, less
##                    slam_soak_per_unit per summon inside (body-blocking,
##                    capped at slam_soak_max), like Sir Alaric's Hammerfall.
##   Sweeping beam  — a gold sector (beam_length, +-beam_half_arc around the
##                    necromancer) for beam_telegraph s, then a radiant beam
##                    sweeps across it in beam_sweep_time s; everything it
##                    crosses is hit once (beam_damage_player /
##                    beam_damage_summon).
## The two specials alternate when both are usable (no RNG). Like a boss it
## shrugs off knockback (cleared every tick), Deep Freeze / dive stun
## durations use the caller's boss multiplier and Stasis holds it only for
## the boss share (Enemy.is_miniboss, CombatResolver / PowerupManager); it is
## never recycled (EnemyDirector). It registers as EnemyDirector.miniboss for
## the HUD's health bar. On death: an XP burst (reward_xp in reward_crystals
## crystals) and a guaranteed treasure chest (ChestManager, miniboss rule).
## Stats: guardian_slams, guardian_beams, guardian_slam_summon_hits,
## guardian_slam_player_hits, guardian_slam_soaked, guardian_beam_summon_hits,
## guardian_beam_player_hits, guardian_kills, guardian_ttk (s alive, summed).
class_name GuardianKit
extends CovenantKit

## Phase: the slam circle is telegraphed.
const SLAM_WINDUP: int = 1
## Phase: the beam sector is telegraphed.
const BEAM_WINDUP: int = 2
## Phase: the beam sweeps across the sector.
const BEAM_SWEEP: int = 3
## Phase: standing after a special.
const RECOVER: int = 4

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## The special used last (the other one goes next when both are usable).
var last_special: String = ""
## Centre of the current slam (locked at the windup).
var slam_pos: Vector2 = Vector2.ZERO
## Beam start angle (rad, world) of the current sweep.
var beam_from: float = 0.0
## Beam end angle (rad, world) of the current sweep.
var beam_to: float = 0.0
## Current beam angle (rad, world) while sweeping.
var beam_angle: float = 0.0
## True once the current sweep hit the necromancer.
var _beam_hit_player: bool = false
## SummonedUnit -> generation of every summon the current sweep hit.
var _beam_hits: Dictionary = {}
## Walking speed before the forced march (px/s; read on the first tick so
## the difficulty's speed multiplier is included; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SanctumEnemyData.GUARDIAN_SPECIALS:
		cds[id] = 0.0
	last_special = ""
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	_beam_hits.clear()
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("guardian_spawned", 1.0)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
	var slam_ok := float(cds["slam"]) <= 0.0 and dist <= float(d["slam_range"])
	var beam_ok := float(cds["beam"]) <= 0.0 and dist >= float(d["beam_min_range"]) and dist <= float(d["beam_range"])
	if slam_ok and beam_ok:
		if last_special == "slam":
			slam_ok = false
		else:
			beam_ok = false
	if slam_ok:
		_start_slam(e)
	elif beam_ok:
		_start_beam(e)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	for id: String in SanctumEnemyData.GUARDIAN_SPECIALS:
		cds[id] = float(cds[id]) - delta
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
		SLAM_WINDUP:
			if phase_time >= float(d["slam_telegraph"]):
				_resolve_slam(e)
				set_phase(e, RECOVER)
		BEAM_WINDUP:
			if phase_time >= float(d["beam_telegraph"]):
				beam_angle = beam_from
				_beam_hit_player = false
				_beam_hits.clear()
				Sfx.play("lance_cast", e.position, 0.7)
				set_phase(e, BEAM_SWEEP)
		BEAM_SWEEP:
			var k := clampf(phase_time / maxf(0.01, float(d["beam_sweep_time"])), 0.0, 1.0)  # Sweep progress.
			beam_angle = lerpf(beam_from, beam_to, k)
			_beam_tick(e)
			e.queue_redraw()
			if k >= 1.0:
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts special `id`: cooldown, stat, phase.
func _begin(e: Enemy, id: String, p: int) -> void:
	last_special = id
	cds[id] = float(d[id + "_cooldown"])
	e.game.stat_add("guardian_%ss" % id, 1.0)
	set_phase(e, p)


# =====================================================================================
# Ground slam
# =====================================================================================

## Telegraphs the slam circle on the necromancer's spot.
func _start_slam(e: Enemy) -> void:
	slam_pos = e.game.player.position
	e.game.effects.telegraph_circle(slam_pos, float(d["slam_radius"]), float(d["slam_telegraph"]), e)
	_begin(e, "slam", SLAM_WINDUP)


## The fists land: summons inside are hurt and thrown out, they soak part
## of the necromancer's damage.
func _resolve_slam(e: Enemy) -> void:
	var g := e.game
	var r := float(d["slam_radius"])  # Circle radius (px).
	var mult := hit_scale(e)  # Time scaling x aura buff.
	g.effects.impact(slam_pos, r, Palette.GOLD, "holy_impact")  # Animation when its art exists (visual only).
	e.motion_lunge(slam_pos - e.position, MotionData.POWER_MELEE)  # Engine motion: the slam (visual only).
	g.shake(8.0)
	Sfx.play("boss_impact", slam_pos, 1.15)
	var soakers := 0  # Summons inside the circle.
	g.ally_grid.query(slam_pos, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(slam_pos) > r + u.radius:
			continue
		soakers += 1
		var away := u.position - slam_pos  # Throw direction.
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(d["slam_knockback"])
		g.combat.damage_unit(u, float(d["slam_damage_summon"]) * mult, "guardian_slam")
	g.stat_add("guardian_slam_summon_hits", float(soakers))
	var p := g.player
	if p.position.distance_to(slam_pos) <= r + p.radius:
		var soak := minf(float(d["slam_soak_max"]), float(soakers) * float(d["slam_soak_per_unit"]))  # Body-blocked share.
		if soak > 0.0:
			g.stat_add("guardian_slam_soaked", 1.0)
		g.stat_add("guardian_slam_player_hits", 1.0)
		g.combat.damage_player(float(d["slam_damage_player"]) * mult * (1.0 - soak), "guardian_slam")


# =====================================================================================
# Sweeping beam
# =====================================================================================

## Telegraphs the beam sector around the direction to the necromancer.
func _start_beam(e: Enemy) -> void:
	var to_p := e.game.player.position - e.position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT  # Sector centre.
	var half := float(d["beam_half_arc"])  # Half the swept arc (rad).
	e.motion_lunge(dir, MotionData.POWER_CAST)  # Engine motion: the beam opens (visual only).
	# Sweep from the side nearer the necromancer's movement so he must cross it.
	var side := 1.0 if dir.cross(e.game.player.velocity) >= 0.0 else -1.0  # Sweep direction sign.
	beam_from = dir.angle() - half * side
	beam_to = dir.angle() + half * side
	beam_angle = beam_from
	e.game.effects.telegraph_cone(e.position, dir, float(d["beam_length"]), half, float(d["beam_telegraph"]), e)
	_begin(e, "beam", BEAM_WINDUP)


## The beam this tick: everything within beam_width / 2 of the ray (out to
## beam_length) is hit, once per sweep.
func _beam_tick(e: Enemy) -> void:
	var g := e.game
	var dir := Vector2.from_angle(beam_angle)  # Beam direction now.
	var length := float(d["beam_length"])  # Beam reach (px).
	var half_w := float(d["beam_width"]) * 0.5  # Half the beam width (px).
	var mult := hit_scale(e)  # Time scaling x aura buff.
	var p := g.player
	if not _beam_hit_player and _on_beam(e.position, dir, length, half_w, p.position, p.radius):
		_beam_hit_player = true
		g.stat_add("guardian_beam_player_hits", 1.0)
		g.combat.damage_player(float(d["beam_damage_player"]) * mult, "guardian_beam")
	var mid := e.position + dir * length * 0.5  # Query centre.
	g.ally_grid.query(mid, length * 0.5 + half_w + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if _beam_hits.has(u) and int(_beam_hits[u]) == u.generation:
			continue
		if not _on_beam(e.position, dir, length, half_w, u.position, u.radius):
			continue
		_beam_hits[u] = u.generation
		g.stat_add("guardian_beam_summon_hits", 1.0)
		g.combat.damage_unit(u, float(d["beam_damage_summon"]) * mult, "guardian_beam")


## True if a body of radius `r` at `p` touches the ray from `o` along `dir`
## (`length` px long, `half_w` px half-width).
static func _on_beam(o: Vector2, dir: Vector2, length: float, half_w: float, p: Vector2, r: float) -> bool:
	var rel := p - o
	var along := rel.dot(dir)  # Distance along the beam.
	if along < -r or along > length + r:
		return false
	return absf(rel.cross(dir)) <= half_w + r


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
	g.effects.impact(e.position, e.radius * 3.0, Palette.GOLD)
	g.shake(10.0)
	g.enemies.show_banner("%s crumbles!" % e.display_name)
	g.stat_add("guardian_kills", 1.0)
	g.stat_add("guardian_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the slam circle / beam sector.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		SLAM_WINDUP:
			var diff := p - slam_pos
			var r := float(d["slam_radius"]) + 30.0
			if diff.length() < r:
				return diff.normalized() if diff.length() > 0.1 else Vector2.RIGHT
		BEAM_WINDUP, BEAM_SWEEP:
			var mid := (beam_from + beam_to) * 0.5  # Sector centre angle.
			if in_sector(e.position, Vector2.from_angle(mid), float(d["beam_length"]) + 20.0, float(d["beam_half_arc"]) + 0.2, e.radius, p, 12.0):
				var away := p - e.position
				return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## Raised fists (slam), a charging eye (beam windup) and the beam itself.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	match phase:
		SLAM_WINDUP:
			SanctumGlyphs.draw_guardian_fists(ci, e.radius)
		BEAM_WINDUP:
			SanctumGlyphs.draw_casting(ci, Vector2(0, -e.radius * 0.55), e.radius * 0.6)
		BEAM_SWEEP:
			unmirror(e, ci)
			SanctumGlyphs.draw_beam(ci, Vector2.from_angle(beam_angle) * float(d["beam_length"]), float(d["beam_width"]))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
