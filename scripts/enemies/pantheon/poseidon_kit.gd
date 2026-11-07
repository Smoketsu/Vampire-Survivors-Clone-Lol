## PoseidonKit — POSEIDON, LORD OF THE SEA, the third god of the Pantheon
## Trial (Act IV, Mount Olympus; GDD §15.0 "The Pantheon Trial"; owner-approved
## proposal: "Floods half the arena, trident throws, a sea serpent"). He
## arrives with 6:00 left (OlympusDirector's "god" event), a GodKit (a third of
## Zeus's HP with the boss's scaling, the miniboss bar, a chest). He walks at
## the necromancer with the shared melee AI and, every attack_gap s, uses one
## of his specials:
##   The flood — flood_cast s with the trident raised, then a wall of water
##             from his side across the necromancer through the Wrath of the
##             Gods' strike entry (DivineWrath.strike("waves") with his own
##             heading, half-length and start: half the arena; it pushes both
##             armies and drowns fodder, the wave rule's).
##   Trident throw — a lane toward the necromancer (trident_telegraph s), then
##             the trident flies down it at trident_speed, piercing everything
##             in its width once (OlympusHits.lane()).
##   The sea serpent — at each HP share in serpent_at he stands serpent_cast s
##             and a Sea Serpent (OlympusEnemyData "sea_serpent") rises beside
##             him (never beyond the enemy hard cap).
## Stats: poseidon_floods, poseidon_tridents, poseidon_trident_hits,
## poseidon_serpents. No RNG of its own.
class_name PoseidonKit
extends GodKit

## Phase: the flood winds up.
const FLOOD: int = 1
## Phase: the trident lane is telegraphed.
const TRIDENT_WINDUP: int = 2
## Phase: the trident flies.
const TRIDENT: int = 3
## Phase: calling the serpent.
const SERPENT: int = 4
## Phase: standing after a special.
const RECOVER: int = 5

## Seconds until his next flood.
var flood_cd: float = 0.0
## Seconds until his next trident throw.
var trident_cd: float = 0.0
## Seconds of walking before the next special may start.
var special_cd: float = 0.0
## Serpents called so far (index into serpent_at).
var serpents: int = 0
## Unit direction of the current throw.
var _dir: Vector2 = Vector2.RIGHT
## Where the trident left his hand (world px).
var _from: Vector2 = Vector2.ZERO
## Px the trident has flown.
var _flown: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	flood_cd = float(d["first_flood"])
	trident_cd = float(d["first_trident"])
	special_cd = 1.0
	serpents = 0
	_flown = 0.0
	e.game.enemies.show_banner("POSEIDON, LORD OF THE SEA, rises from the terraces: the sea follows him!")
	rules(e).play_sound("wave", e.position)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	flood_cd -= delta
	trident_cd -= delta
	if phase == IDLE:
		special_cd -= delta
		_choose(e)
		if phase == IDLE:
			return walk(e)
	phase_time += delta
	hold(e)
	match phase:
		FLOOD:
			if phase_time >= float(d["flood_cast"]):
				_flood(e)
				set_phase(e, RECOVER)
		TRIDENT_WINDUP:
			if phase_time >= float(d["trident_telegraph"]):
				_struck.clear()
				_flown = 0.0
				rules(e).play_sound("poseidon_trident", e.position)
				set_phase(e, TRIDENT)
		TRIDENT:
			_step_trident(e, delta)
		SERPENT:
			if phase_time >= float(d["serpent_cast"]):
				_raise_serpent(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts a special when one is ready: the serpent at its HP share first,
## then the flood, then a trident throw.
func _choose(e: Enemy) -> void:
	var g := e.game
	var at: Array = d["serpent_at"]
	if serpents < at.size() and e.hp <= e.max_hp * float(at[serpents]):
		serpents += 1
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		g.effects.telegraph_circle(e.position + Vector2(e.radius * 2.2, 0.0), 26.0, float(d["serpent_cast"]), e)
		set_phase(e, SERPENT)
		return
	if special_cd > 0.0:
		return
	var to := g.player.position - e.position
	var dist := to.length()
	if flood_cd <= 0.0:
		flood_cd = float(d["flood_cooldown"])
		_dir = to / dist if dist > 1.0 else Vector2.RIGHT
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		g.stat_add("poseidon_floods", 1.0)
		set_phase(e, FLOOD)
	elif trident_cd <= 0.0 and dist <= float(d["trident_range"]):
		trident_cd = float(d["trident_cooldown"])
		_dir = to / dist if dist > 1.0 else Vector2.RIGHT
		_from = e.position
		g.effects.telegraph_line(_from, _from + _dir * float(d["trident_length"]), float(d["trident_width"]), float(d["trident_telegraph"]), e)
		e.motion_lunge(-_dir, MotionData.POWER_CAST)
		g.stat_add("poseidon_tridents", 1.0)
		set_phase(e, TRIDENT_WINDUP)


## The flood: one wave through DivineWrath.strike(), rolling from his side
## across the necromancer (the heading locked when he raised the trident).
func _flood(e: Enemy) -> void:
	var g := e.game
	rules(e).wrath.strike("waves", g.player.position, {
		"dir": _dir,
		"half_len": float(d["flood_half_len"]),
		"start_dist": float(d["flood_start"]),
		"telegraph": float(d["flood_telegraph"]),
	})
	g.shake(3.0)
	e.motion_lunge(_dir, MotionData.POWER_MELEE)


## The trident flies down its lane, piercing everything in it once.
func _step_trident(e: Enemy, delta: float) -> void:
	var g := e.game
	var length := float(d["trident_length"])
	var prev := _flown
	_flown = minf(length, _flown + float(d["trident_speed"]) * delta)
	g.stat_add("poseidon_trident_hits", float(OlympusHits.lane(g, _from + _dir * prev, _dir, _flown - prev, float(d["trident_width"]),
			scaled(e, "trident_damage_player"), scaled(e, "trident_damage_summon"), "poseidon_trident", e, _struck, _tmp)))
	e.queue_redraw()
	if _flown >= length:
		set_phase(e, RECOVER)


## A Sea Serpent rises beside him.
func _raise_serpent(e: Enemy) -> void:
	var g := e.game
	if g.enemies.regular_alive() >= g.enemies.hard_cap():
		return
	var at := g.arena.free_point(e.position + Vector2(e.radius * 2.2, 0.0), 16.0)
	g.enemies.spawn_at(OlympusEnemyData.SERPENT, at, false)
	g.effects.impact(at, 40.0, Palette.PANTHEON_AEGEAN_LIGHT)
	rules(e).play_sound("serpent_rise", at)
	g.stat_add("poseidon_serpents", 1.0)
	g.enemies.show_banner("Poseidon calls a SEA SERPENT from the deep!")


## Autopilot hint: out of the trident's lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == TRIDENT_WINDUP or phase == TRIDENT:
		var rel := p - _from
		var along := rel.dot(_dir)
		if along > -20.0 and along < float(d["trident_length"]) + 20.0:
			var side := rel - _dir * along
			if side.length() < float(d["trident_width"]) + 26.0:
				return side.normalized() if side.length() > 0.5 else _dir.orthogonal()
	return Vector2.ZERO


## The flying trident (a gold line with three prongs) and the flood's raised
## glow. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == FLOOD:
		var k := clampf(phase_time / maxf(0.01, float(d["flood_cast"])), 0.0, 1.0)
		unmirror(e, ci)
		ci.draw_arc(Vector2.ZERO, e.radius * (1.2 + k), 0.0, TAU, 28, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.4 + 0.5 * k), 3.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif phase == TRIDENT:
		# The overlay layer moves with the god: draw in world space relative to him.
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))
		var tip := _from + _dir * _flown - e.position
		var tail := tip - _dir * 34.0
		ci.draw_line(tail, tip, Palette.GOLD, 3.0)
		var side := _dir.orthogonal() * 6.0
		ci.draw_line(tip - _dir * 6.0 + side, tip + side * 0.2, Palette.GOLD, 2.0)
		ci.draw_line(tip - _dir * 6.0 - side, tip - side * 0.2, Palette.GOLD, 2.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
