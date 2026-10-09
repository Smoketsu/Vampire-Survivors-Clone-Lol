## BossAlaric — placeholder for SIR ALARIC, THE GRAVEBREAKER (GDD §11), the
## Graveyard boss that appears at 5:00 in the compressed prototype timeline.
## Extends Enemy so summons, spells and the spatial hash treat him like any
## other target. Implemented specials (both clearly telegraphed, GDD §16
## "Clear AoE telegraphs", §32 "Bosses can suppress or kill squads with clear
## telegraphs"):
##   * Hammerfall    — gold warning circle on the necromancer's position, then
##                     a smash that hurts the player and any summons inside.
##   * Divine Charge — gold warning lane, then a fast straight dash that hits
##                     everything in its path once.
## Between specials he walks toward the player and swings at whatever he
## touches (inherited melee behaviour). Killing him wins the run.
class_name BossAlaric
extends Enemy

## Boss attack phases.
enum Phase { WALK, HAMMER_WINDUP, CHARGE_WINDUP, CHARGING, RECOVER }

## Current phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.0
## Boss design data (EnemyData.BOSS).
var boss_def: Dictionary = {}
## World point Hammerfall will strike.
var hammer_point: Vector2 = Vector2.ZERO
## Unit direction of the current charge.
var charge_dir: Vector2 = Vector2.RIGHT
## Distance (px) still to travel in the current charge.
var charge_left: float = 0.0
## Whether the player was already hit by the current charge.
var _charge_hit_player: bool = false
## Instance ids of summons already hit by the current charge.
var _charge_hit_units: Dictionary = {}
## Last special used ("hammer" / "charge") so they alternate.
var _last_special: String = "charge"


## Sets up the boss at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = EnemyData.BOSS
	activate(p_game, "boss", boss_def, pos, hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	special_cd = 2.0


## Picks the next special when ready; otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	var player := game.player
	var d := position.distance_to(player.position)
	var use_hammer := d <= float(boss_def["hammer_max_range"]) and (_last_special == "charge" or d < 120.0)
	if use_hammer:
		_start_hammerfall()
	else:
		_start_charge()


## Boss physics: inherited walk/melee while in WALK, otherwise specials.
func physics_step(delta: float) -> void:
	phase_time += delta
	match phase:
		Phase.WALK:
			special_cd -= delta
			super.physics_step(delta)
		Phase.HAMMER_WINDUP:
			_tick_timers(delta)
			if phase_time >= float(boss_def["hammer_telegraph"]):
				_resolve_hammerfall()
				_set_phase(Phase.RECOVER)
		Phase.CHARGE_WINDUP:
			_tick_timers(delta)
			if phase_time >= float(boss_def["charge_telegraph"]):
				_set_phase(Phase.CHARGING)
		Phase.CHARGING:
			_tick_timers(delta)
			_step_charge(delta)
		Phase.RECOVER:
			_tick_timers(delta)
			if phase_time >= float(boss_def["recover_time"]):
				special_cd = float(boss_def["attack_gap"])
				_set_phase(Phase.WALK)


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Hammerfall: telegraph a circle where the player is heading.
func _start_hammerfall() -> void:
	_last_special = "hammer"
	var player := game.player
	hammer_point = player.position + player.velocity * 0.25
	game.effects.telegraph_circle(hammer_point, float(boss_def["hammer_radius"]), float(boss_def["hammer_telegraph"]))
	game.stat_add("boss_hammerfalls", 1.0)
	_set_phase(Phase.HAMMER_WINDUP)


## Hammerfall impact: damage the player and summons inside the circle.
func _resolve_hammerfall() -> void:
	var r: float = boss_def["hammer_radius"]
	game.effects.impact(hammer_point, r, Palette.GOLD)
	game.shake(8.0)
	var player := game.player
	if player.position.distance_to(hammer_point) <= r + player.radius:
		game.combat.damage_player(float(boss_def["hammer_damage_player"]) * game.enemies.damage_mult, "boss_hammer")
	game.ally_grid.query(hammer_point, r + 12.0, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(hammer_point) <= r + u.radius:
			game.combat.damage_unit(u, float(boss_def["hammer_damage_summon"]), "boss")


## Divine Charge: telegraph a lane toward the player.
func _start_charge() -> void:
	_last_special = "charge"
	var to_p := game.player.position - position
	charge_dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	charge_left = boss_def["charge_length"]
	_charge_hit_player = false
	_charge_hit_units.clear()
	game.effects.telegraph_line(position, position + charge_dir * charge_left, float(boss_def["charge_width"]), float(boss_def["charge_telegraph"]))
	game.stat_add("boss_charges", 1.0)
	_set_phase(Phase.CHARGE_WINDUP)


## Moves along the charge lane and hits everything touched once.
func _step_charge(delta: float) -> void:
	var step_len := minf(float(boss_def["charge_speed"]) * delta, charge_left)
	position += charge_dir * step_len
	charge_left -= step_len
	var hit_r := float(boss_def["charge_width"]) * 0.5
	var player := game.player
	if not _charge_hit_player and player.position.distance_to(position) <= hit_r + player.radius:
		_charge_hit_player = true
		game.combat.damage_player(float(boss_def["charge_damage_player"]) * game.enemies.damage_mult, "boss_charge")
	game.ally_grid.query(position, hit_r + 12.0, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or _charge_hit_units.has(u.get_instance_id()):
			continue
		if u.position.distance_to(position) <= hit_r + u.radius:
			_charge_hit_units[u.get_instance_id()] = true
			game.combat.damage_unit(u, float(boss_def["charge_damage_summon"]), "boss")
	if charge_left <= 0.0:
		_set_phase(Phase.RECOVER)


## The charge bulldozes through the warrior wall; otherwise Alaric is blocked
## (mass-weighted, so he mostly shoves warriors aside).
func resolve_blocking() -> void:
	if phase != Phase.CHARGING:
		super.resolve_blocking()


## Danger avoidance hint for the autotest autopilot: a push vector away from
## the active telegraph (zero when nothing is telegraphed).
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.HAMMER_WINDUP:
		var diff := p - hammer_point
		var r := float(boss_def["hammer_radius"]) + 30.0
		if diff.length() < r:
			return diff.normalized() if diff.length() > 0.1 else Vector2.RIGHT
	elif phase == Phase.CHARGE_WINDUP or phase == Phase.CHARGING:
		var rel := p - position
		var along := rel.dot(charge_dir)
		var side := rel - charge_dir * along
		if along > -20.0 and along < charge_left + 40.0 and side.length() < float(boss_def["charge_width"]) + 20.0:
			var perp := Vector2(-charge_dir.y, charge_dir.x)
			return perp if side.dot(perp) >= 0.0 else -perp
	return Vector2.ZERO


func _draw() -> void:
	var pose := 0
	match phase:
		Phase.HAMMER_WINDUP:
			pose = 1
		Phase.CHARGE_WINDUP, Phase.CHARGING:
			pose = 2
		Phase.RECOVER:
			pose = 3
	Glyphs.draw_boss(self, Vector2.ZERO, radius, flash > 0.0, pose)
