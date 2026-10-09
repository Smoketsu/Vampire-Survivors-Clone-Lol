## BossAlaric — SIR ALARIC, THE GRAVEBREAKER (GDD §11), the Graveyard boss
## that appears at 5:00 in the compressed prototype timeline. Extends Enemy so
## summons, spells and the spatial hash treat him like any other target.
## All five GDD §11 abilities are implemented, each clearly telegraphed
## (GDD §16 "Clear AoE telegraphs", §32 "Bosses can suppress or kill squads
## with clear telegraphs") and tuned in EnemyData.BOSS:
##   * Hammerfall          — gold warning circle on the necromancer's path,
##                           then a smash. Undead inside the circle soak part
##                           of the necromancer's damage (body-blocking).
##   * Divine Charge       — gold warning lane, then a fast dash. Every undead
##                           body in the lane soaks some of its momentum;
##                           enough of them stop it before it reaches him.
##   * Consecrated Ground  — radiant zones (StageDirector holy zones) on and
##                           around the necromancer: they arm after a
##                           telegraph, then burn and slow undead and sting
##                           the necromancer for a few seconds.
##   * Call to Arms        — rally banners mark where infantry will arrive,
##                           then the soldiers appear there.
##   * Judgment of the Dead — sigils marked on summon clusters; when the
##                           light falls, summons inside take heavy damage
##                           (the necromancer is unharmed).
## Specials are chosen by weight among the ones whose own cooldown is ready
## and whose conditions hold; between specials he walks at the player and
## swings at whatever he touches (inherited melee behaviour).
## Phase threshold (GDD has none for Alaric; recorded in GDD §15.0): below
## phase2_hp_fraction HP he enters Wrath — shorter gaps, more zones and marks,
## and an immediate Call to Arms.
## Killing him drops a big XP reward; the run goes on (user brief).
class_name BossAlaric
extends Enemy

## Boss attack phases.
enum Phase { WALK, HAMMER_WINDUP, CHARGE_WINDUP, CHARGING, CONSECRATE_WINDUP, CALL_WINDUP, JUDGMENT_WINDUP, RECOVER }

## Current phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.0
## Boss design data (EnemyData.BOSS).
var boss_def: Dictionary = {}
## True once below phase2_hp_fraction HP ("Wrath").
var enraged: bool = false
## World point Hammerfall will strike.
var hammer_point: Vector2 = Vector2.ZERO
## Unit direction of the current charge.
var charge_dir: Vector2 = Vector2.RIGHT
## Distance (px) still to travel in the current charge.
var charge_left: float = 0.0
## Special id -> seconds until it may be chosen again.
var _special_cds: Dictionary = {}
## Whether the player was already hit by the current charge.
var _charge_hit_player: bool = false
## Instance ids of summons already hit by the current charge.
var _charge_hit_units: Dictionary = {}
## Last special used, so the same one is not chosen twice in a row when
## another is ready.
var _last_special: String = "charge"
## True when the next special must be Call to Arms (Wrath entry).
var _force_call: bool = false
## Points where Call to Arms soldiers will arrive (locked at the windup).
var _call_points: Array[Vector2] = []
## Enemy kinds matching _call_points.
var _call_kinds: Array[String] = []
## Centres of the current Judgment of the Dead marks.
var _judgment_points: Array[Vector2] = []


## Sets up the boss at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = EnemyData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	special_cd = float(boss_def["first_special"])
	enraged = false
	_force_call = false
	for id: String in EnemyData.SPECIALS:
		_special_cds[id] = 0.0


## Picks the next special when ready; otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	match _choose_special():
		"hammer":
			_start_hammerfall()
		"charge":
			_start_charge()
		"consecrate":
			_start_consecrate()
		"call":
			_start_call()
		"judgment":
			_start_judgment()


## Weighted choice among the specials that are off cooldown and usable now.
## Returns "" when none is (he keeps walking and re-checks next think).
func _choose_special() -> String:
	if _force_call and _can_call():
		_force_call = false
		return "call"
	var d := position.distance_to(game.player.position)
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id: String in EnemyData.SPECIALS:
		if float(_special_cds[id]) > 0.0 or not _special_usable(id, d):
			continue
		ids.append(id)
		weights.append(float(boss_def[id + "_weight"]))
	if ids.size() > 1 and ids.has(_last_special):
		var i := ids.find(_last_special)
		ids.remove_at(i)
		weights.remove_at(i)
	if ids.is_empty():
		return ""
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in ids.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ids[i]
	return ids[ids.size() - 1]


## Whether special `id` makes sense with the player `d` px away.
func _special_usable(id: String, d: float) -> bool:
	match id:
		"hammer":
			return d <= float(boss_def["hammer_max_range"])
		"charge":
			return d >= float(boss_def["charge_min_range"])
		"call":
			return _can_call()
		"judgment":
			return game.horde.units.size() >= int(boss_def["judgment_min_summons"])
	return true


## Call to Arms needs room under the enemy hard cap.
func _can_call() -> bool:
	return game.enemies.regular_alive() < WaveData.HARD_CAP - 10


## Boss physics: inherited walk/melee while in WALK, otherwise specials.
func physics_step(delta: float) -> void:
	phase_time += delta
	for id: String in EnemyData.SPECIALS:
		_special_cds[id] = float(_special_cds[id]) - delta
	if not enraged and hp <= max_hp * float(boss_def["phase2_hp_fraction"]):
		_enter_wrath()
	match phase:
		Phase.WALK:
			special_cd -= delta
			super.physics_step(delta)
		Phase.HAMMER_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["hammer_telegraph"]):
				_resolve_hammerfall()
				_set_phase(Phase.RECOVER)
		Phase.CHARGE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["charge_telegraph"]):
				_set_phase(Phase.CHARGING)
		Phase.CHARGING:
			_tick_timers(delta)
			_step_charge(delta)
		Phase.CONSECRATE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["consecrate_telegraph"]):
				_set_phase(Phase.RECOVER)
		Phase.CALL_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["call_telegraph"]):
				_resolve_call()
				_set_phase(Phase.RECOVER)
		Phase.JUDGMENT_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["judgment_telegraph"]):
				_resolve_judgment()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				var gap := float(boss_def["attack_gap"])
				if enraged:
					gap *= float(boss_def["phase2_gap_mult"])
				special_cd = gap
				_set_phase(Phase.WALK)


## Standing still during a windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Starts special `id`: bookkeeping shared by every special.
func _begin_special(id: String, next_phase: Phase) -> void:
	_last_special = id
	_special_cds[id] = float(boss_def[id + "_cooldown"])
	game.stat_add("boss_atk_" + id, 1.0)
	_set_phase(next_phase)


## Wrath (phase 2): banner, faster specials, Call to Arms next.
func _enter_wrath() -> void:
	enraged = true
	_force_call = true
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.GOLD)
	game.stat_add("boss_phase2", 1.0)
	queue_redraw()


# =====================================================================================
# Hammerfall
# =====================================================================================

## Hammerfall: telegraph a circle where the player is heading.
func _start_hammerfall() -> void:
	var player := game.player
	hammer_point = player.position + player.velocity * 0.25
	game.effects.telegraph_circle(hammer_point, float(boss_def["hammer_radius"]), float(boss_def["hammer_telegraph"]))
	_begin_special("hammer", Phase.HAMMER_WINDUP)


## Hammerfall impact: damages summons inside the circle; each of them soaks
## part of the blow aimed at the necromancer (body-blocking).
func _resolve_hammerfall() -> void:
	var r: float = boss_def["hammer_radius"]
	game.effects.impact(hammer_point, r, Palette.GOLD)
	game.shake(8.0)
	var soakers := 0
	game.ally_grid.query(hammer_point, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(hammer_point) <= r + u.radius:
			soakers += 1
			game.combat.damage_unit(u, float(boss_def["hammer_damage_summon"]), "boss_hammer")
	var player := game.player
	if player.position.distance_to(hammer_point) <= r + player.radius:
		var soak := minf(float(boss_def["hammer_soak_max"]), float(soakers) * float(boss_def["hammer_soak_per_unit"]))
		if soak > 0.0:
			game.stat_add("boss_hammer_soaked", 1.0)
		game.combat.damage_player(float(boss_def["hammer_damage_player"]) * game.enemies.damage_mult * (1.0 - soak), "boss_hammer")


# =====================================================================================
# Divine Charge
# =====================================================================================

## Divine Charge: telegraph a lane toward the player, cut short by obstacles.
func _start_charge() -> void:
	var to_p := game.player.position - position
	charge_dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	charge_left = game.arena.clear_length(position, charge_dir, float(boss_def["charge_length"]), radius * 0.8)
	_charge_hit_player = false
	_charge_hit_units.clear()
	game.effects.telegraph_line(position, position + charge_dir * charge_left, float(boss_def["charge_width"]), float(boss_def["charge_telegraph"]))
	_begin_special("charge", Phase.CHARGE_WINDUP)


## Moves along the charge lane and hits everything touched once. Every
## undead body hit soaks part of the remaining charge; when nothing is left
## the charge stops short (body-blocking, user brief).
func _step_charge(delta: float) -> void:
	var spd := float(boss_def["charge_speed"])
	var step_len := minf(spd * delta, charge_left)
	position += charge_dir * step_len
	charge_left -= step_len
	velocity = charge_dir * spd
	var hit_r := float(boss_def["charge_width"]) * 0.5
	var soaked := false
	game.ally_grid.query(position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _charge_hit_units.has(u.get_instance_id()):
			continue
		if u.position.distance_to(position) <= hit_r + u.radius:
			_charge_hit_units[u.get_instance_id()] = true
			var absorb := float(boss_def["charge_absorb_warrior"] if u.block_radius > 0.0 else boss_def["charge_absorb_summon"])
			charge_left -= absorb
			soaked = soaked or charge_left <= 0.0
			game.combat.damage_unit(u, float(boss_def["charge_damage_summon"]), "boss_charge")
	var player := game.player
	if not _charge_hit_player and player.position.distance_to(position) <= hit_r + player.radius:
		_charge_hit_player = true
		game.combat.damage_player(float(boss_def["charge_damage_player"]) * game.enemies.damage_mult, "boss_charge")
	if charge_left <= 0.0:
		if soaked:
			# Undead bodies soaked the rest of the charge (body-blocking).
			game.stat_add("boss_charge_stopped", 1.0)
			game.effects.impact(position + charge_dir * radius, radius * 1.5, Palette.COLD_BLUE)
			if not _charge_hit_player and _lane_reaches_player():
				game.stat_add("boss_charge_blocked", 1.0)
		velocity = Vector2.ZERO
		_set_phase(Phase.RECOVER)


## True if the player still stands ahead in the charge lane (used to count
## charges the undead stopped before they reached him).
func _lane_reaches_player() -> bool:
	var rel := game.player.position - position
	var along := rel.dot(charge_dir)
	return along > 0.0 and (rel - charge_dir * along).length() <= float(boss_def["charge_width"]) * 0.5 + game.player.radius


# =====================================================================================
# Consecrated Ground
# =====================================================================================

## Consecrated Ground: places holy zones (with their own arming telegraph)
## on the necromancer's path and around him, then holds the pose briefly.
func _start_consecrate() -> void:
	var zone: Dictionary = boss_def["consecrate_zone"]
	var player := game.player
	var count := int(boss_def["consecrate_count"]) + (int(boss_def["phase2_extra_zones"]) if enraged else 0)
	var stage := game.enemies.stage
	stage.add_zone(player.position + player.velocity * float(boss_def["consecrate_lead"]), zone, "boss")
	var offset := randf() * TAU
	for i in range(1, count):
		var a := offset + TAU * float(i) / float(maxi(1, count - 1))
		var dist := randf_range(float(boss_def["consecrate_spread_min"]), float(boss_def["consecrate_spread_max"]))
		stage.add_zone(player.position + Vector2.from_angle(a) * dist, zone, "boss")
	game.effects.ring(position, radius * 2.5, Palette.GOLD, float(boss_def["consecrate_telegraph"]))
	_begin_special("consecrate", Phase.CONSECRATE_WINDUP)


# =====================================================================================
# Call to Arms
# =====================================================================================

## Call to Arms: lock arrival points around Alaric and show rally markers.
func _start_call() -> void:
	_call_points.clear()
	_call_kinds.clear()
	var n := 0
	for g: Dictionary in boss_def["call_groups"]:
		n += int(g["count"])
	var offset := randf() * TAU
	var i := 0
	for g: Dictionary in boss_def["call_groups"]:
		var def: Dictionary = EnemyData.ENEMIES[String(g["kind"])]
		for _k in int(g["count"]):
			var a := offset + TAU * float(i) / float(maxi(1, n))
			var dist := randf_range(float(boss_def["call_radius_min"]), float(boss_def["call_radius_max"]))
			var pt := game.arena.free_point(position + Vector2.from_angle(a) * dist, float(def["radius"]))
			_call_points.append(pt)
			_call_kinds.append(String(g["kind"]))
			game.enemies.stage.add_mark(pt, float(def["radius"]) * 1.6, float(boss_def["call_telegraph"]), StageDirector.MarkStyle.RALLY)
			i += 1
	game.enemies.show_banner("Sir Alaric calls to arms!")
	_begin_special("call", Phase.CALL_WINDUP)


## Call to Arms arrival: soldiers appear at the rally markers (hard cap
## respected).
func _resolve_call() -> void:
	for i in _call_points.size():
		if game.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		game.enemies.spawn_at(_call_kinds[i], _call_points[i], false)
		game.effects.spawn_ring(_call_points[i], Palette.GOLD)
	game.stat_add("boss_call_soldiers", float(_call_points.size()))


# =====================================================================================
# Judgment of the Dead
# =====================================================================================

## Judgment of the Dead: marks the densest summon clusters (marks never
## overlap) and shows a sigil on each.
func _start_judgment() -> void:
	_judgment_points.clear()
	var r := float(boss_def["judgment_radius"])
	var marks := int(boss_def["judgment_marks"]) + (int(boss_def["phase2_extra_marks"]) if enraged else 0)
	var units := game.horde.units
	# Score every summon by how many allies stand within the mark radius.
	var scored: Array[Vector3] = []
	for u in units:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		game.ally_grid.query(u.position, r, _tmp)
		scored.append(Vector3(u.position.x, u.position.y, float(_tmp.size())))
	scored.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	for s in scored:
		if _judgment_points.size() >= marks:
			break
		var p := Vector2(s.x, s.y)
		var overlaps := false
		for q in _judgment_points:
			if q.distance_to(p) < r * 1.6:
				overlaps = true
				break
		if not overlaps:
			_judgment_points.append(p)
	for p in _judgment_points:
		game.enemies.stage.add_mark(p, r, float(boss_def["judgment_telegraph"]), StageDirector.MarkStyle.JUDGMENT)
	_begin_special("judgment", Phase.JUDGMENT_WINDUP)


## Judgment falls: every summon inside a mark takes judgment_damage once.
func _resolve_judgment() -> void:
	var r := float(boss_def["judgment_radius"])
	var hit := {}
	for p in _judgment_points:
		game.effects.impact(p, r, Palette.IVORY)
		game.ally_grid.query(p, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or hit.has(u.get_instance_id()):
				continue
			if u.position.distance_to(p) <= r + u.radius * 0.5:
				hit[u.get_instance_id()] = true
				game.combat.damage_unit(u, float(boss_def["judgment_damage"]), "boss_judgment")
	game.stat_add("boss_judgment_hits", float(hit.size()))
	game.shake(5.0)


# =====================================================================================
# Blocking, autopilot hint, drawing
# =====================================================================================

## The charge bulldozes through the warrior wall (its momentum is soaked in
## _step_charge instead); otherwise Alaric is blocked (mass-weighted, so he
## mostly shoves warriors aside).
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
		Phase.HAMMER_WINDUP, Phase.CONSECRATE_WINDUP, Phase.CALL_WINDUP, Phase.JUDGMENT_WINDUP:
			pose = 1
		Phase.CHARGE_WINDUP, Phase.CHARGING:
			pose = 2
		Phase.RECOVER:
			pose = 3
	if enraged:
		# Wrath: a burning crimson-gold halo around him.
		draw_circle(Vector2.ZERO, radius * 1.6, Color(Palette.FLAME, 0.14))
		draw_arc(Vector2.ZERO, radius * 1.6, 0.0, TAU, 32, Color(Palette.GOLD, 0.7), 2.0)
	Glyphs.draw_boss(self, Vector2.ZERO, radius, flash > 0.0, pose)
