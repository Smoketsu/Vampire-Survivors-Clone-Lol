## ChiropteranKit — the kit of the Chiropteran (CourtEnemyData "chiropteran";
## Act VII, built by Castle Sanguis, usable on any stage; GDD §15.0 "Castle
## Sanguis (Act VII phase 2)"; owner-approved proposal: "Mutated bat-people that
## glide over the ring; a sonic shriek cone that stuns summons for 1.5 s ... Hit
## them in the air; Grave Step out of the cone"). A male bat-man, the act's
## elite FLIER (row "flies"):
##   * NIGHT WINGS: CourtKit's shared flight (the ring never body-blocks it; it
##     hunts the necromancer and the priests inside, swoops to bite, feeds
##     through the bite; in flight only airborne summons, ranged attacks and
##     spells hit it). The flight runs whenever no shriek does.
##   * THE SONIC SHRIEK: while it is in the air and its shriek is ready, with a
##     summon or the necromancer within shriek_range px, it hovers and marks a
##     cone (shriek_range px, shriek_arc degrees each side) toward its target
##     for shriek_telegraph s (EffectManager.telegraph_cone, tied to it); then
##     every summon in the cone is stunned shriek_stun s through THE summon stun
##     path (CombatResolver.stun_unit(), source "chiropteran_shriek": an enemy
##     effect on units, no summon act rule) and a necromancer in it takes
##     shriek_damage (time-scaled). The autopilot steps out of the marked cone
##     (danger_push()).
## No RNG. Stats: chiropteran_shrieks, chiropteran_stuns,
## chiropteran_shriek_player_hits.
class_name ChiropteranKit
extends CourtKit

## Phase: the shriek's cone is marked.
const SHRIEK: int = 1

## Seconds until the next shriek may start.
var _shriek_cd: float = 0.0
## Unit direction of the marked cone.
var _dir: Vector2 = Vector2.RIGHT
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_shriek_cd = first_cd(e, float(def.get("shriek_first", 3.0)))


func physics(e: Enemy, delta: float) -> bool:
	if phase == SHRIEK:
		phase_time += delta
		hold(e)
		if phase_time >= float(d["shriek_telegraph"]):
			_shriek(e)
			set_phase(e, IDLE)
		return true
	_shriek_cd -= delta
	if wing_phase == NightWings.AIR and _shriek_cd <= 0.0 and _start_shriek(e):
		return true
	return super.physics(e, delta)


## Starts a shriek at its target (or the necromancer) when one is in range.
## False when nothing is.
func _start_shriek(e: Enemy) -> bool:
	var g := e.game
	var t: Node2D = e.target if e._target_valid() else g.player
	var reach := float(d["shriek_range"])
	if e.position.distance_to(t.position) > reach * 0.85:
		t = g.player
		if e.position.distance_to(t.position) > reach * 0.85:
			return false
	if t == g.player and g.ultimates.player_untargetable():
		return false
	var to := t.position - e.position
	_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	g.effects.telegraph_cone(e.position, _dir, reach, deg_to_rad(float(d["shriek_arc"])), float(d["shriek_telegraph"]), e)
	_shriek_cd = float(d["shriek_every"])
	g.stat_add("chiropteran_shrieks", 1.0)
	set_phase(e, SHRIEK)
	hold(e)
	return true


## The shriek: every summon in the cone is stunned; a necromancer in it struck.
func _shriek(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["shriek_range"])
	var half := deg_to_rad(float(d["shriek_arc"]))
	g.effects.ring(e.position, reach * 0.5, Palette.COURT_MOON_LIGHT, 0.3)
	rules(e).play_sound("bat_screech", e.position, 0.3)
	for p in g.all_players:
		if not p.dead and in_sector(e.position, _dir, reach, half, e.radius, p.position, p.radius):
			g.combat.damage_player(float(d["shriek_damage"]) * hit_scale(e), CastleSanguisEnemyData.SHRIEK_SOURCE, p)
			g.stat_add("chiropteran_shriek_player_hits", 1.0)
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		if not in_sector(e.position, _dir, reach, half, e.radius, u.position, u.radius):
			continue
		if g.combat.stun_unit(u, float(d["shriek_stun"]), CastleSanguisEnemyData.SHRIEK_STUN) > 0.0:
			g.stat_add("chiropteran_stuns", 1.0)


func is_busy() -> bool:
	return phase != IDLE or super.is_busy()


## Autopilot hint: out of the marked cone (Grave Step out of the cone).
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != SHRIEK:
		return Vector2.ZERO
	if in_sector(e.position, _dir, float(d["shriek_range"]) + 20.0, deg_to_rad(float(d["shriek_arc"])) + 0.2, e.radius, p, 12.0):
		var side := _dir.orthogonal()
		var s := 1.0 if side.dot(p - e.position) >= 0.0 else -1.0
		return side * s * 1.6
	return Vector2.ZERO
