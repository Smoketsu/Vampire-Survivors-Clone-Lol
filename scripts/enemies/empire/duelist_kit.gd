## DuelistKit — the Valkyrie Duelist's kit (CitadelEnemyData "valkyrie_duelist",
## kit "duelist"; Act III, the Iron Citadel; GDD §15.0 "The Iron Citadel (Act
## III phase 2)"; owner-approved proposal: "Jet-assisted lunges through your
## ring toward the necromancer with an arm blade. Blockers stop the lunge
## (Warriors, Golem); Sovereign's Decree"). A MELEE elite and a CYBORG: raised,
## she rises as a Grave Gunner. Between lunges she is a plain melee soldier on
## the shared AI (she always advances; nobody kites).
##   * Lunge: when her lunge is ready and the necromancer is lunge_range_min ..
##     lunge_range_max px away, she plants for lunge_telegraph s behind a thin
##     amber lane toward him (EffectManager.telegraph_line, tied to her), then
##     her jets fire and she drives along it at lunge_speed for up to
##     lunge_length px (obstacles cut it, Arena.clear_length()). Each summon she
##     passes through is sliced (lunge_summon_damage) and shoved aside; a summon
##     whose block_mass is at least lunge_block_mass (a Warrior or any heavier
##     blocker) STOPS her dead: a clang, the blocker takes a light hit, and she
##     stands staggered for lunge_stagger s. Reaching the necromancer, she
##     strikes him once (lunge_damage) and stops.
##   * Sovereign's Decree: while the necromancer cannot be targeted
##     (UltimateSystem.player_untargetable()) she never starts a lunge on him.
## While Stasis, a Deep Freeze or a stun holds her, physics() is not called, so
## a lunge waits with her. Determinism: no RNG (her first cooldown is staggered
## by the think slot). Stats: duelist_lunges, duelist_lunges_blocked,
## duelist_lunges_hit (reached the necromancer), duelist_lunge_slices (summons
## passed through); damage as player_dmg_from_duelist_lunge /
## summon_dmg_from_duelist_lunge (CombatResolver).
class_name DuelistKit
extends EmpireKit

## Phase: the lane is telegraphed (she holds still).
const WINDUP: int = 1
## Phase: the jets fire, she drives along the lane.
const LUNGE: int = 2
## Phase: stopped by a blocker, staggered.
const STAGGER: int = 3
## Damage source tag of the lunge (CombatResolver stats).
const SOURCE: String = "duelist_lunge"

## Seconds until the next lunge may start.
var lunge_cd: float = 0.0
## Unit direction of the current lane.
var dir: Vector2 = Vector2.RIGHT
## Px of the lane still to travel.
var left: float = 0.0
## True once the current lunge struck the necromancer.
var _hit_player: bool = false
## SummonedUnit -> generation of every summon the current lunge sliced.
var _hits: Dictionary = {}
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lunge_cd = first_cd(e, float(d["lunge_first"]))
	left = 0.0
	_hits.clear()


## Starts a lunge when it is ready and the necromancer is in reach.
func physics(e: Enemy, delta: float) -> bool:
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["lunge_telegraph"]):
				_hit_player = false
				_hits.clear()
				Sfx.play("jet_burst", e.position)
				e.motion_lunge(dir, MotionData.POWER_MELEE)
				set_phase(e, LUNGE)
			return true
		LUNGE:
			phase_time += delta
			_move(e, delta)
			if left <= 0.0 and phase == LUNGE:
				set_phase(e, IDLE)
			return true
		STAGGER:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["lunge_stagger"]):
				set_phase(e, IDLE)
			return true
	lunge_cd -= delta
	if lunge_cd <= 0.0:
		_try_start(e)
		if phase == WINDUP:
			return true
	return false


## Plants and telegraphs a lunge at the necromancer when he is in reach and the
## lane is long enough (else it retries a little later).
func _try_start(e: Enemy) -> void:
	var g := e.game
	if g.ultimates.player_untargetable():
		lunge_cd = 0.5  # Sovereign's Decree: no lunge at an untargetable necromancer.
		return
	var to_p := g.player.position - e.position  # Toward the necromancer.
	var dist := to_p.length()
	if dist < float(d["lunge_range_min"]) or dist > float(d["lunge_range_max"]):
		lunge_cd = 0.4
		return
	dir = to_p / dist
	left = g.arena.clear_length(e.position, dir, minf(float(d["lunge_length"]), dist + 40.0), e.radius * 0.8)
	if left < float(d["lunge_range_min"]):
		lunge_cd = 0.6  # An obstacle in the way: walk on and try again.
		return
	lunge_cd = float(d["lunge_cooldown"])
	g.effects.telegraph_line(e.position, e.position + dir * left, float(d["lunge_width"]), float(d["lunge_telegraph"]), e)
	g.stat_add("duelist_lunges", 1.0)
	set_phase(e, WINDUP)


## One tick of the lunge: forward along the lane, slicing through summons until
## a blocker stops her or she reaches the necromancer.
func _move(e: Enemy, delta: float) -> void:
	var g := e.game
	var spd := float(d["lunge_speed"])
	var step_len := minf(spd * delta, left)
	e.position += dir * step_len
	left -= step_len
	e.velocity = dir * spd
	e.knockback = Vector2.ZERO
	var hit_r := float(d["lunge_width"]) * 0.5  # Half the lane width (px).
	var mult := hit_scale(e)  # Time scaling x weakening.
	var pl := g.player
	if not _hit_player and pl.position.distance_to(e.position) <= hit_r + pl.radius + e.radius * 0.5:
		_hit_player = true
		g.combat.damage_player(float(d["lunge_damage"]) * mult, SOURCE)
		g.effects.slash(pl.position, dir, Palette.EMPIRE_SIGNAL_AMBER, e.radius * 1.8)
		g.stat_add("duelist_lunges_hit", 1.0)
		left = 0.0
		return
	g.ally_grid.query(e.position, hit_r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if _hits.has(u) and int(_hits[u]) == u.generation:
			continue
		var rel := u.position - e.position
		if rel.length() > hit_r + u.radius + e.radius * 0.5:
			continue
		_hits[u] = u.generation
		if u.block_mass >= float(d["lunge_block_mass"]):
			# A blocker holds the line: the lunge ends here (the proposal's counter).
			left = 0.0
			g.combat.damage_unit(u, float(d["lunge_summon_damage"]) * mult * e.undead_damage_mult * 0.5, SOURCE)
			g.effects.slash(e.position + dir * e.radius, dir, Palette.COLD_BLUE, e.radius * 1.6)
			Sfx.play("blade_clang", e.position)
			g.stat_add("duelist_lunges_blocked", 1.0)
			set_phase(e, STAGGER)
			return
		var side := rel - dir * rel.dot(dir)  # Shove the sliced summon out of the lane.
		var push := side.normalized() if side.length() > 0.1 else Vector2(-dir.y, dir.x)
		u.position += push * float(d["lunge_knockback"])
		g.combat.damage_unit(u, float(d["lunge_summon_damage"]) * mult * e.undead_damage_mult, SOURCE)
		g.stat_add("duelist_lunge_slices", 1.0)


## True while a lunge runs (the autotest's stuck check skips her then).
func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of a telegraphed lunge lane, sideways.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var rel := p - e.position
	var along := rel.dot(dir)
	if along < -20.0 or along > left + 30.0:
		return Vector2.ZERO
	var perp := Vector2(-dir.y, dir.x)
	var off := rel.dot(perp)
	if absf(off) > float(d["lunge_width"]) * 0.5 + 26.0:
		return Vector2.ZERO
	return perp if off >= 0.0 else -perp


## The jets' flare while she winds up and drives along the lane. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WINDUP or phase == LUNGE:
		unmirror(e, ci)
		CitadelGlyphs.draw_jets(ci, -dir * (e.radius * 0.9), -dir, e.radius, phase == LUNGE)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif phase == STAGGER:
		ReaperHorrorGlyphs.draw_stun(ci, Vector2(0, e.marker_y(-e.radius * 1.4)), e.radius)
