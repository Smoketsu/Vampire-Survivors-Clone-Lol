## WolfKit — the kit of the Wolf of Rome (IlionEnemyData "wolf_of_rome"; Act
## IV, the Shores of Ilion, GDD §15.0 "The Shores of Ilion (Act IV phase 2)";
## owner-approved proposal: "Bronze wolves in packs of 5, fast lunges"):
##   * THE PACK: a wolf spawned on its own (the trickle, a timeline wave, a
##     --spawn=) is a pack leader: on its first tick it brings pack_size - 1
##     packmates around it (pack_spread px; never past the hard cap). Packmates
##     are spawned with `_spawning_pack` set and bring none (no chain).
##   * THE LUNGE: within lunge_range px of what it hunts (its target: a summon
##     or the necromancer) and off cooldown, it crouches lunge_windup s, then
##     leaps lunge_time s at lunge_speed px/s straight at where its prey stood;
##     the first body it reaches (a summon in the way intercepts it) takes
##     lunge_damage x the time scaling, once. Then the shared melee AI again.
## FODDER (Poseidon's waves drown it) and BRONZE (Zeus's lightning chains to
## it). Deterministic: no RNG (the packmates' places are fixed angles from the
## leader's think slot). Stats: wolf_packs, wolf_packmates, wolf_lunges,
## wolf_lunge_hits.
class_name WolfKit
extends PantheonKit

## Phase: crouching before a lunge.
const CROUCH: int = 1
## Phase: in the air.
const LEAP: int = 2

## True while a pack leader is spawning its packmates (they bring none).
static var _spawning_pack: bool = false

## True for a pack leader whose pack has not been brought yet.
var _leader: bool = false
## Seconds until the next lunge may start.
var lunge_cd: float = 0.0
## Unit direction of the current leap.
var _dir: Vector2 = Vector2.RIGHT
## True once the current leap struck a body.
var _struck: bool = false
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_leader = not _spawning_pack
	lunge_cd = CovenantKit.first_cd(e, float(d["first_lunge"]))
	_struck = false


## The pack on the first tick, then the lunge (see the header).
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if _leader:
		_leader = false
		_bring_pack(e)
	lunge_cd -= delta
	if phase == IDLE:
		if lunge_cd <= 0.0:
			var aim := e.target.position if e.target != null and is_instance_valid(e.target) else e.game.player.position  # Its prey.
			var dist := e.position.distance_to(aim)
			if dist <= float(d["lunge_range"]) and dist > e.radius * 2.0:
				_dir = (aim - e.position).normalized()
				lunge_cd = float(d["lunge_cooldown"])
				e.motion_lunge(-_dir, MotionData.POWER_CAST)  # The crouch (visual only).
				set_phase(e, CROUCH)
		return false
	phase_time += delta
	match phase:
		CROUCH:
			hold(e)
			if phase_time >= float(d["lunge_windup"]):
				_struck = false
				e.game.stat_add("wolf_lunges", 1.0)
				set_phase(e, LEAP)
		LEAP:
			e.velocity = _dir * float(d["lunge_speed"])
			e.position += e.velocity * delta
			if not _struck:
				_bite(e)
			if phase_time >= float(d["lunge_time"]):
				set_phase(e, IDLE)
	return true


## The leader's pack: pack_size - 1 wolves around it (fixed angles).
func _bring_pack(e: Enemy) -> void:
	var g := e.game
	var n := int(d["pack_size"]) - 1  # Packmates.
	var base := float(e.think_slot) * 0.7  # Ring offset (rad), no RNG.
	_spawning_pack = true
	var brought := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + Vector2.from_angle(base + TAU * float(i) / float(maxi(1, n))) * float(d["pack_spread"])
		g.enemies.spawn_at(e.kind, at, false)
		brought += 1
	_spawning_pack = false
	g.stat_add("wolf_packs", 1.0)
	g.stat_add("wolf_packmates", float(brought))


## The leap's bite: the first summon or necromancer the wolf reaches.
func _bite(e: Enemy) -> void:
	var g := e.game
	var mult := CovenantKit.hit_scale(e)  # Time scaling x buffs.
	g.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= e.radius + u.radius:
			_struck = true
			g.combat.damage_unit(u, float(d["lunge_damage"]) * mult * e.undead_damage_mult, IlionEnemyData.WOLF_LUNGE_SOURCE, e)
			g.stat_add("wolf_lunge_hits", 1.0)
			set_phase(e, IDLE)
			return
	for p in g.all_players:  # (Co-op: the first necromancer reached.)
		if p.position.distance_to(e.position) <= e.radius + p.radius:
			_struck = true
			g.combat.damage_player(float(d["lunge_damage"]) * mult, IlionEnemyData.WOLF_LUNGE_SOURCE, p)
			g.stat_add("wolf_lunge_hits", 1.0)
			set_phase(e, IDLE)
			return


## True while crouching or leaping (the autotest's stuck check skips it).
func is_busy() -> bool:
	return phase != IDLE
