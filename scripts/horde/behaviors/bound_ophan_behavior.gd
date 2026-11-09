## BoundOphanBehavior — the Bound Ophan's ORBIT AND ROLL ("orbit_roll", UnitData
## "bound_ophan"; temporary Act XIII, the Empyrean's finale reward; GDD §15.0
## "The Bound Ophan, Throne of Bones and Turning Bones"; owner-approved
## proposal: "Finale summon class the Bound Ophan: a wheel of bone and eyes that
## orbits the Bone Ring and rolls through packs (evolution Throne of Bones)").
## A wheel of bone with soul-teal eyes, the necromancer's own, fighting in
## melee on the Bone Ring's front posts between rolls. Its special, a class
## special that works the same on every stage (owner rule: summons never get
## act-only rules), a ground body all the way (it never flies: the arena's
## push-out keeps it out of the obstacles, enemies can hit it):
##   1. think(): with the roll ready, it picks the DENSEST PACK within
##      roll_range px of its necromancer (the enemy with the most foes within
##      PACK_RADIUS px, of at most SCAN enemies; roll_min_enemies, or an elite
##      / the boss alone);
##   2. ORBIT: it rolls ROUND THE RING for roll_orbit s (roll_orbit_speed rad/s
##      round the necromancer at its distance, clamped to the Bone Ring),
##      striking every foe its rim touches (radius + roll_rim px);
##   3. ROLL: it rolls straight at the pack at roll_speed px/s, through it and
##      roll_past px beyond (at most MAX_ROLL s, never farther than ROLL_LEASH
##      px from its necromancer, stopping at an obstacle), striking every foe
##      under its rim: roll_damage (its own source, SOURCE / EVOLVED_SOURCE)
##      and a sideways knockback (roll_knockback / mass). Each foe is struck
##      once a pass (the orbit and the roll share one pass);
##   4. evolved into THRONE OF BONES (SummonEvolutionData "throne_of_bones",
##      special_set roll_back / throne): BACK: it rolls back the way it came
##      over the same length, a second pass (each foe struck once more);
##   5. the class volley where the last pass ends (VolleyDirector.on_special()),
##      then the shared FSM again.
## Leash and recall stay in charge: a recall cancels the roll
## (SummonBehavior.physics()). Turning Bones (its paired passive, PassiveData
## "turning_bones", read only here): x 1 + turn_damage on the roll damage, the
## roll cooldown / (1 + turn_haste).
## Determinism: no RNG (the densest pack, ties in the spatial hash's order).
## Stats: bound_ophan_rolls, bound_ophan_roll_hits, bound_ophan_orbit_hits,
## throne_of_bones_backs, dmg_bound_ophan_roll / dmg_throne_of_bones_roll,
## summon_special_end_blocked (a roll ending inside an obstacle: must be 0).
class_name BoundOphanBehavior
extends SummonBehavior

## Class id (UnitData, UnlockData, mastery).
const CLASS_ID: String = "bound_ophan"
## Its evolution's id (SummonEvolutionData).
const EVOLUTION_ID: String = "throne_of_bones"
## Damage-source tag of the roll (the base Bound Ophan; a minion special, PassiveData).
const SOURCE: String = "bound_ophan_roll"
## Damage-source tag of Throne of Bones' roll.
const EVOLVED_SOURCE: String = "throne_of_bones_roll"
## Passive id of Turning Bones (its paired passive; PassiveData, UnlockData).
const TURNING: String = "turning_bones"
## Turning Bones' level-row key: share more roll damage (0..1).
const TURNING_DAMAGE_KEY: String = "turn_damage"
## Turning Bones' level-row key: share the roll cooldown is hastened by (0..1).
const TURNING_HASTE_KEY: String = "turn_haste"
## Phase: rolling round the ring.
const ORBIT: int = 1
## Phase: rolling straight through the pack.
const ROLL: int = 2
## Phase: rolling back the way it came (Throne of Bones).
const BACK: int = 3
## Enemies scanned for the densest pack (cost bound).
const SCAN: int = 24  # TUNING (not in GDD)
## Px round a candidate within which its pack is counted.
const PACK_RADIUS: float = 60.0  # TUNING (not in GDD)
## Most seconds of one straight pass.
const MAX_ROLL: float = 1.4  # TUNING (not in GDD)
## Px from its necromancer past which a pass stops (under the soft recall, so
## the leash never cancels a roll on its own).
const ROLL_LEASH: float = 280.0  # TUNING (not in GDD) UnitData.SOFT_RECALL is 320

## The pack's enemy it rolls at (null once it died / was recycled).
var roll_target: Enemy = null
## Generation of `roll_target` at the pick (stale-reference guard).
var roll_gen: int = 0
## Unit direction of the current straight pass.
var _dir: Vector2 = Vector2.RIGHT
## Px still to roll in the current straight pass.
var _left: float = 0.0
## Px the forward pass rolled (Throne of Bones rolls back as far).
var _rolled: float = 0.0
## Its angle (rad) round the necromancer during the orbit.
var _orbit_a: float = 0.0
## Its distance (px) from the necromancer during the orbit.
var _orbit_r: float = 80.0
## The way round it orbits (+1 / -1: toward the pack's side).
var _orbit_way: float = 1.0
## Foes struck in this pass: [Enemy, generation] pairs.
var _struck: Array = []
## Reusable enemy query buffer.
var _buf: Array = []
## Second reusable enemy query buffer (the pack counts).
var _buf2: Array = []


## Full roll cooldown (s), hastened by Turning Bones.
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("roll_cooldown", 6.0)) / (1.0 + u.game.abilities.passive_value(TURNING, TURNING_HASTE_KEY))


## Picks the densest pack near its necromancer and starts orbiting.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var p := u.game.player.position
	var e := _densest(u, p, float(u.special["roll_range"]))
	if e == null:
		return false
	roll_target = e
	roll_gen = e.generation
	var off := u.position - p
	_orbit_a = off.angle()
	_orbit_r = clampf(off.length(), 60.0, StanceData.RING_MAX)
	_orbit_way = 1.0 if off.cross(e.position - p) >= 0.0 else -1.0  # Toward the pack's side of the ring.
	_struck.clear()
	begin_special(u, ORBIT)
	u.game.stat_add("bound_ophan_rolls", 1.0)
	return true


## The enemy with the most foes within PACK_RADIUS px, of the first SCAN
## enemies within `reach` px of `from`; null without a pack (roll_min_enemies,
## or an elite / the boss alone).
func _densest(u: SummonedUnit, from: Vector2, reach: float) -> Enemy:
	var game := u.game
	game.enemy_grid.query(from, reach, _buf)
	var best: Enemy = null
	var best_n := 0
	var seen := 0
	var need := int(u.special["roll_min_enemies"])
	for e: Enemy in _buf:
		if seen >= SCAN:
			break
		if not e.active or e.untargetable or e.is_structure or e.civilian or e.position.distance_to(from) > reach:
			continue
		seen += 1
		var n := count_enemies(game, e.position, PACK_RADIUS, _buf2)
		if e.is_elite or e.is_boss:
			n = maxi(n, need)
		if n > best_n:
			best_n = n
			best = e
	return best if best_n >= need else null


## Orbit -> roll (-> back) -> the FSM again.
func step_special(u: SummonedUnit, delta: float) -> bool:
	var p := u.game.player.position
	match phase:
		ORBIT:
			_orbit_a += float(u.special["roll_orbit_speed"]) * _orbit_way * delta
			var goal := p + Vector2.from_angle(_orbit_a) * _orbit_r
			u.velocity = (goal - u.position) / maxf(delta, 0.001)
			var cap := float(u.special["roll_speed"])
			if u.velocity.length() > cap:
				u.velocity = u.velocity.normalized() * cap
			_strike(u, "bound_ophan_orbit_hits")
			if phase_time >= float(u.special["roll_orbit"]):
				var at := roll_target.position if roll_target != null and roll_target.active and roll_target.generation == roll_gen else p
				var to := at - u.position
				_dir = to.normalized() if to.length() > 1.0 else Vector2.from_angle(_orbit_a)
				_left = to.length() + float(u.special["roll_past"])
				_rolled = 0.0
				Sfx.play("abom_stomp", u.position, 0.6)  # A startup-bank sound: the class plays on every stage.
				next_phase(ROLL)
		ROLL, BACK:
			var step_len := float(u.special["roll_speed"]) * delta
			var nxt := u.position + _dir * step_len
			var stop := _left <= 0.0 or phase_time >= MAX_ROLL or nxt.distance_to(p) > ROLL_LEASH \
					or u.game.arena.is_blocked(nxt, u.radius)
			if stop:
				u.velocity = Vector2.ZERO
				if phase == ROLL and int(u.special.get("roll_back", 0)) > 0 and _rolled > 1.0:
					_dir = -_dir
					_left = _rolled
					_struck.clear()  # The way back is a second pass.
					u.game.stat_add("throne_of_bones_backs", 1.0)
					next_phase(BACK)
				else:
					_finish(u)
				return true
			u.velocity = _dir * float(u.special["roll_speed"])
			_left -= step_len
			_rolled += step_len
			_strike(u, "bound_ophan_roll_hits")
	return true


## Strikes every foe under its rim not yet struck this pass (stat `stat`).
func _strike(u: SummonedUnit, stat: String) -> void:
	var game := u.game
	var reach := u.radius + float(u.special["roll_rim"])
	var dmg := float(u.special["roll_damage"]) * (1.0 + game.abilities.passive_value(TURNING, TURNING_DAMAGE_KEY))
	var src := EVOLVED_SOURCE if u.special.has("throne") else SOURCE
	var kb := float(u.special["roll_knockback"])
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(u.position) > reach + e.radius:
			continue
		var seen := false
		for h: Array in _struck:
			if h[0] == e and int(h[1]) == e.generation:
				seen = true
				break
		if seen:
			continue
		_struck.append([e, e.generation])
		var side := _dir.orthogonal()
		var away := side if (e.position - u.position).dot(side) >= 0.0 else -side
		e.knockback += away * kb / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, dmg, src, u.director.slot, u.position)
		n += 1
	if n > 0:
		game.stat_add(stat, float(n))


## The last pass ended: the class volley, then back to the shared FSM (on a
## free point: it never ends inside an obstacle).
func _finish(u: SummonedUnit) -> void:
	var g := u.game
	if g.arena.is_blocked(u.position, u.radius):
		u.position = g.arena.free_point(u.position, u.radius)
		if g.arena.is_blocked(u.position, u.radius):
			g.stat_add("summon_special_end_blocked", 1.0)
	g.effects.ring(u.position, u.radius * 3.0, Palette.BONE, 0.25)
	g.volleys.on_special(u, u.position, u.position + _dir, float(u.special["roll_damage"]))  # Bullet heaven: a ring of soul-fire eyes.
	roll_target = null
	_struck.clear()
	end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)


## A recall interrupted the roll: drop the pass (the arena's push-out keeps it
## out of the obstacles).
func on_cancel(_u: SummonedUnit) -> void:
	roll_target = null
	_struck.clear()


## While it rolls: a short soul-teal trail behind it (textures only).
func draw_under(u: SummonedUnit) -> void:
	if phase != ROLL and phase != BACK:
		return
	world_space(u)
	for k in 3:
		var at := -_dir * (u.radius * (1.0 + 0.9 * float(k)))
		var r := u.radius * (0.8 - 0.2 * float(k))
		u.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(r, r * 0.5), Vector2(r * 2.0, r)), false, Color(WheelOfEyesData.FIRE, 0.25 - 0.07 * float(k)))
	body_space(u)
