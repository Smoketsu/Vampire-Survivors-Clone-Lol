## AresKit — ARES, GOD OF WAR, the first god of the Pantheon Trial (Act IV,
## Mount Olympus; GDD §15.0 "The Pantheon Trial"; owner-approved proposal:
## "War-cry buffs every enemy on screen; charges with a spear; dies to
## blockers"). He arrives with 14:00 left (OlympusDirector's "god" event), a
## GodKit (a third of Zeus's HP with the boss's scaling, the miniboss bar, a
## chest). Bronze-clad: Zeus's lightning chains to him. He walks at the
## necromancer with the shared melee AI and, every attack_gap s, uses one of
## two telegraphed specials (alternating when both are ready):
##   War-cry — warcry_cast s with his spear raised (a red ring swelling), then
##             every enemy within warcry_radius px (not bosses, minibosses or
##             structures) is buffed warcry_time s through THE one enemy-buff
##             path, Enemy.apply_buff(): damage x warcry_damage, speed x
##             warcry_speed (drawn as their aura buff).
##   Spear charge — a lane toward the necromancer (charge_telegraph s), then he
##             runs it at charge_speed: the necromancer in it is hit once,
##             summons are thrown aside and hit; a blocker of block_mass >=
##             charge_block_mass (Warriors, Abominations, the Golem) IMPALES
##             him: the charge stops dead, he loses block_self_damage of his max
##             HP (CombatResolver, source "ares_impaled") and is stunned
##             block_stun s (CombatResolver.stun_enemy()).
## Stats: boss-like ares_warcries, ares_buffed (enemies buffed), ares_charges,
## ares_charge_hits, ares_impaled. No RNG.
class_name AresKit
extends GodKit

## Phase: the war-cry winds up.
const WARCRY: int = 1
## Phase: the charge lane is telegraphed.
const CHARGE_WINDUP: int = 2
## Phase: running down the lane.
const CHARGE: int = 3
## Phase: standing after a special.
const RECOVER: int = 4
## Special ids in alternation order.
const SPECIALS := ["warcry", "charge"]

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## The special used last.
var last_special: String = ""
## Unit direction of the current charge (locked at its windup).
var _dir: Vector2 = Vector2.RIGHT
## Px of the charge lane still to run.
var _left: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SPECIALS:
		cds[id] = 0.0
	last_special = ""
	_left = 0.0
	e.game.enemies.show_banner("ARES, GOD OF WAR, takes the field: put a blocker in his charge!")
	rules(e).play_sound("ares_warcry", e.position)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
	var cry_ok := float(cds["warcry"]) <= 0.0
	var charge_ok := float(cds["charge"]) <= 0.0 and dist >= float(d["charge_min"]) and dist <= float(d["charge_max"])
	if cry_ok and charge_ok:
		if last_special == "warcry":
			cry_ok = false
		else:
			charge_ok = false
	if cry_ok:
		_begin(e, "warcry", WARCRY)
		e.game.effects.ring(e.position, float(d["warcry_radius"]) * 0.25, Palette.CRIMSON, float(d["warcry_cast"]))
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	elif charge_ok:
		var to := e.game.player.position - e.position
		_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		_left = e.game.arena.clear_length(e.position, _dir, float(d["charge_length"]), e.radius * 0.8)
		e.game.effects.telegraph_line(e.position, e.position + _dir * _left, float(d["charge_width"]), float(d["charge_telegraph"]), e)
		e.motion_lunge(-_dir, MotionData.POWER_CAST)
		_begin(e, "charge", CHARGE_WINDUP)


## Starts special `id`: cooldown, stat, phase.
func _begin(e: Enemy, id: String, p: int) -> void:
	last_special = id
	cds[id] = float(d[id + "_cooldown"])
	e.game.stat_add("ares_%ss" % id if id == "charge" else "ares_warcries", 1.0)
	set_phase(e, p)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	for id: String in SPECIALS:
		cds[id] = float(cds[id]) - delta
	if phase == IDLE:
		special_cd -= delta
		return walk(e)
	phase_time += delta
	match phase:
		WARCRY:
			hold(e)
			if phase_time >= float(d["warcry_cast"]):
				_war_cry(e)
				set_phase(e, RECOVER)
		CHARGE_WINDUP:
			hold(e)
			if phase_time >= float(d["charge_telegraph"]):
				_struck.clear()
				rules(e).play_sound("ares_charge", e.position)
				set_phase(e, CHARGE)
		CHARGE:
			_step_charge(e, delta)
		RECOVER:
			hold(e)
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## The war-cry: every enemy on screen is buffed through Enemy.apply_buff().
func _war_cry(e: Enemy) -> void:
	var g := e.game
	var r := float(d["warcry_radius"])  # Reach (px).
	var n := 0  # Enemies buffed.
	g.enemy_grid.query(e.position, r, _tmp)
	for o: Enemy in _tmp:
		if o == e or not o.active or o.is_structure or o.is_boss or o.is_miniboss or o.position.distance_to(e.position) > r:
			continue
		o.apply_buff(float(d["warcry_damage"]), float(d["warcry_speed"]), float(d["warcry_taken"]), float(d["warcry_time"]))
		n += 1
	g.stat_add("ares_buffed", float(n))
	g.effects.ring(e.position, r, Palette.CRIMSON, 0.6)
	g.shake(4.0)
	rules(e).play_sound("ares_warcry", e.position)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)


## Runs down the lane: hits the necromancer and summons once, and stops dead
## on a blocker heavy enough (impaled).
func _step_charge(e: Enemy, delta: float) -> void:
	var g := e.game
	var spd := float(d["charge_speed"])
	var step_len := minf(spd * delta, _left)
	e.position += _dir * step_len
	_left -= step_len
	e.velocity = _dir * spd
	var hit_r := float(d["charge_width"]) * 0.5  # Lane half-width (px).
	var blocker := OlympusHits.blocker_at(g, e.position + _dir * e.radius, hit_r, float(d["charge_block_mass"]), _tmp)
	if blocker != null and not _struck.has(blocker):
		_impaled(e, blocker)
		return
	g.stat_add("ares_charge_hits", float(OlympusHits.lane(g, e.position - _dir * step_len, _dir, step_len + e.radius, float(d["charge_width"]),
			scaled(e, "charge_damage_player"), scaled(e, "charge_damage_summon"), "ares_charge", e, _struck, _tmp)))
	_shove_lane(e, hit_r)
	if _left <= 0.0:
		e.motion_lunge(_dir, MotionData.POWER_MELEE)
		set_phase(e, RECOVER)


## Throws the summons beside him out of the lane (sideways).
func _shove_lane(e: Enemy, hit_r: float) -> void:
	e.game.ally_grid.query(e.position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.position.distance_to(e.position) > hit_r + u.radius:
			continue
		var rel := u.position - e.position
		var side := rel - _dir * rel.dot(_dir)
		u.position += (side.normalized() if side.length() > 0.1 else _dir.orthogonal()) * float(d["charge_push"])


## A blocker stands in his path: the spear sticks in the bone, he is hurt and stunned.
func _impaled(e: Enemy, blocker: SummonedUnit) -> void:
	var g := e.game
	_left = 0.0
	g.effects.slash(e.position + _dir * e.radius, _dir, Palette.BONE, e.radius * 1.8)
	g.effects.impact(e.position + _dir * e.radius, e.radius * 1.5, Palette.CRIMSON)
	g.combat.damage_unit(blocker, scaled(e, "charge_damage_summon") * 0.5, "ares_charge", e)
	g.combat.damage_enemy(e, e.max_hp * float(d["block_self_damage"]), "ares_impaled")
	g.combat.stun_enemy(e, float(d["block_stun"]), 1.0, 1.0)
	g.stat_add("ares_impaled", 1.0)
	g.enemies.show_banner("Ares impales himself on your dead!")
	g.shake(5.0)
	set_phase(e, RECOVER)


## Autopilot hint: out of the charge lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == CHARGE_WINDUP or phase == CHARGE:
		var rel := p - e.position
		var along := rel.dot(_dir)
		if along > -20.0 and along < float(d["charge_length"]) + 30.0:
			var side := rel - _dir * along
			if side.length() < float(d["charge_width"]) + 30.0:
				return side.normalized() if side.length() > 0.5 else _dir.orthogonal()
	return Vector2.ZERO


## The war-cry's swelling red ring while it winds up. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WARCRY:
		var k := clampf(phase_time / maxf(0.01, float(d["warcry_cast"])), 0.0, 1.0)  # 0 -> 1 as he cries out.
		unmirror(e, ci)
		ci.draw_arc(Vector2.ZERO, e.radius * (1.2 + 1.3 * k), 0.0, TAU, 28, Color(Palette.CRIMSON, 0.4 + 0.5 * k), 2.0 + 2.0 * k)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
