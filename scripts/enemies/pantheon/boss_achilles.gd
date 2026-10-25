## BossAchilles — ACHILLES, THE UNKILLABLE, the boss of the Shores of Ilion (Act
## IV, Stage 10; GDD §15.0 "The Shores of Ilion (Act IV phase 2)"; owner-approved
## proposal docs/act4/PROPOSAL.md "Stage 10"). Loaded by name for the boss id
## "achilles" (EnemyDirector.PANTHEON_BOSS_DIR + "boss_achilles.gd"); he arrives
## at 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy. Every ability is telegraphed; numbers in
## AchillesData.BOSS (its header lists the three phases and the heel table):
##   * THE HEEL — his facing (`pantheon_facing`, read by PantheonRules
##       .facing_of()) turns toward what he fights at turn_rate rad/s;
##       directed_hit_mult() (asked once per directed hit by
##       PantheonRules.directed_hit_mult() from CombatResolver.damage_enemy(),
##       the one front path) cuts a hit to his front to front_mult, a hit on
##       his flank to flank_mult, and lets a hit to his back or from within
##       heel_radius of the gold heel mark under him (heel_offset px behind his
##       centre) through in full and STAGGERS him (stagger_time s standing, no
##       turning; at most every stagger_cooldown s). An undirected hit (area,
##       stomp, damage over time) or an arcing hit from above deals
##       undirected_mult (damage_taken_mult() / above_hit_mult()).
##   * Lunge — every lunge_cooldown s at a necromancer lunge_min..lunge_max px
##       away he telegraphs a lane, then runs it with his spear: the
##       necromancer in it is struck once, summons are struck and thrown aside
##       (the Unkillable is not stopped by a blocker).
##   * The Myrmidon Charge (below guard_hp) — he stands guard_cast s calling his
##       guard: guard_count Hoplites (guard_elites of them elite) form a shield
##       wall guard_ahead px in front of him, again every guard_interval s while
##       fewer than guard_max_alive stand.
##   * The Rage after Patroclus (below rage_hp) — he roars rage_roar s, throws
##       his helmet and shield away (bosses/achilles_rage), moves and strikes
##       faster, lunges rage_lunges times in a row, whirls his spear in a
##       telegraphed circle when the necromancer or whirl_min_summons summons
##       stand close, and his front takes rage_front_mult.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Paris's Arrow and Mortal Heel (UnlockData, boss "achilles"); a killing blow
## to his back or heel counts for the achievement Heel Found (stat
## achilles_heel_kills; MetaProgress keeps the lifetime count). Attack poses
## (BossPoseData): bosses/achilles_strike while he lunges. Determinism: no RNG.
## Stats: boss_atk_<special>, achilles_front_hits, achilles_flank_hits,
## achilles_back_hits, achilles_heel_hits, achilles_undirected_hits,
## achilles_staggers, achilles_lunges, achilles_lunge_hits, achilles_guard_called,
## achilles_whirl_hits, achilles_guard_at, achilles_rage_at,
## achilles_heel_kills, achilles_killed.
class_name BossAchilles
extends Boss

## Boss action phases.
enum Phase { WALK, LUNGE_WINDUP, LUNGE, RECOVER, GUARD_CAST, ROAR, WHIRL_WINDUP, STAGGER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## The way he faces (unit vector; PantheonRules.facing_of() reads it: his front).
var pantheon_facing: Vector2 = Vector2.LEFT
## True once he called his guard (below guard_hp).
var guarded: bool = false
## True once he rages (below rage_hp).
var raged: bool = false
## Seconds until his next lunge.
var lunge_cd: float = 0.0
## Lunges still to run in the current chain (the rage lunges twice).
var _lunges_left: int = 0
## Seconds until his next guard call.
var guard_cd: float = 0.0
## Seconds until his next whirl.
var whirl_cd: float = 0.0
## Seconds until he can be staggered again.
var stagger_cd: float = 0.0
## Unit direction of the current lunge (locked at its windup).
var _lunge_dir: Vector2 = Vector2.RIGHT
## Distance (px) of the lunge lane still to run.
var _lunge_left: float = 0.0
## Summons already struck by the current lunge.
var _lunge_hits: Array[SummonedUnit] = []
## Necromancers already struck by the current lunge (co-op: each once).
var _lunge_hit_players: Array[Necromancer] = []
## His guard: the Hoplites he called and their generations (alive count).
var _guard: Array[Enemy] = []
## Generation of each `_guard` member when it was called.
var _guard_gen: PackedInt32Array = PackedInt32Array()
## True while the hit being resolved came with a direction (set by
## directed_hit_mult() / above_hit_mult(), read and cleared by
## damage_taken_mult(), which CombatResolver.damage_enemy() calls right after).
var _directed: bool = false
## True when the last hit he took struck his back or heel (Heel Found).
var _last_back: bool = false
## Move speed of his current form (px/s).
var _base_speed: float = 58.0
## Attack interval of his current form (s).
var _base_interval: float = 1.0


## Sets up Achilles at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = AchillesData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	p_game.pantheon_rules()  # His front is read through the Pantheon's one path (created here when he is forced onto another stage).
	phase = Phase.WALK
	phase_time = 0.0
	guarded = false
	raged = false
	var to := p_game.player.position - position
	pantheon_facing = to.normalized() if to.length() > 1.0 else Vector2.LEFT
	lunge_cd = float(boss_def["first_lunge"])
	_lunges_left = 0
	guard_cd = 0.0
	whirl_cd = 0.0
	stagger_cd = 0.0
	_guard.clear()
	_guard_gen = PackedInt32Array()
	_directed = false
	_last_back = false
	_base_speed = move_speed
	_base_interval = attack_interval
	p_game.effects.impact(position, radius * 3.0, Palette.GOLD)
	p_game.shake(6.0)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return AchillesData.SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of his art (engine-motion pivot): the rage form once he rages.
func motion_sprite_key() -> String:
	return "bosses/achilles_rage" if raged and SpriteBank.has("bosses/achilles_rage") else "bosses/achilles"


## The world point of the gold heel mark under him (behind his feet).
func heel_point() -> Vector2:
	return position - pantheon_facing * float(boss_def["heel_offset"])


# =====================================================================================
# The heel (PantheonRules.directed_hit_mult() / CombatResolver.damage_enemy())
# =====================================================================================

## Multiplier on a directed hit from `origin` (see the header). A hit to his
## back or heel staggers him.
func directed_hit_mult(origin: Vector2, _shot: bool, _source: String) -> float:
	_directed = true
	var heel := origin.distance_to(heel_point()) <= float(boss_def["heel_radius"])  # A blow on the heel mark.
	if heel or PantheonRules.hit_from_behind(self, origin, float(boss_def["back_half_angle"])):
		_last_back = true
		game.stat_add("achilles_heel_hits" if heel else "achilles_back_hits", 1.0)
		_try_stagger()
		return 1.0
	_last_back = false
	if PantheonRules.hit_from_front(self, origin, float(boss_def["front_half_angle"])):
		game.stat_add("achilles_front_hits", 1.0)
		knockback = Vector2.ZERO
		return float(boss_def["rage_front_mult"] if raged else boss_def["front_mult"])
	game.stat_add("achilles_flank_hits", 1.0)
	return float(boss_def["flank_mult"])


## Multiplier on an arcing hit from above (CombatResolver.FROM_ABOVE): as an
## undirected hit.
func above_hit_mult(_source: String) -> float:
	_directed = true
	_last_back = false
	game.stat_add("achilles_undirected_hits", 1.0)
	return float(boss_def["undirected_mult"])


## Enemy-side damage modifier (CombatResolver.damage_enemy(), right after the
## directed test): an undirected hit deals undirected_mult.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if not _directed:
		_last_back = false
		game.stat_add("achilles_undirected_hits", 1.0)
		m *= float(boss_def["undirected_mult"])
	_directed = false
	return m


## Staggers him when his stagger is ready (not during the rage's roar).
func _try_stagger() -> void:
	if stagger_cd > 0.0 or phase == Phase.ROAR or phase == Phase.LUNGE:
		return
	stagger_cd = float(boss_def["stagger_cooldown"])
	game.stat_add("achilles_staggers", 1.0)
	game.effects.ring(heel_point(), radius * 1.4, Palette.GOLD, 0.3)
	if game.pantheon != null:
		game.pantheon.play_sound("heel_struck", position)
	_set_phase(Phase.STAGGER)


## His death: a killing blow to the back or heel counts for Heel Found.
func deactivate() -> void:
	if active and hp <= 0.0:
		game.stat_add("achilles_killed", 1.0)
		if _last_back:
			game.stat_add("achilles_heel_kills", 1.0)
	super.deactivate()


# =====================================================================================
# The fight
# =====================================================================================

## Boss physics: his phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	lunge_cd -= delta
	guard_cd -= delta
	whirl_cd -= delta
	stagger_cd -= delta
	if not guarded and hp <= max_hp * float(boss_def["guard_hp"]) and phase == Phase.WALK:
		guarded = true
		guard_cd = 0.0
		game.stat_add("achilles_guard_at", game.elapsed)
	if not raged and hp <= max_hp * float(boss_def["rage_hp"]) and (phase == Phase.WALK or phase == Phase.STAGGER):
		_start_rage()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.LUNGE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["lunge_telegraph"]):
				_lunge_hits.clear()
				_lunge_hit_players.clear()
				Sfx.play("rogue_dash", position, 0.6)
				_set_phase(Phase.LUNGE)
		Phase.LUNGE:
			_step_lunge(delta)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				if _lunges_left > 0:
					_start_lunge()
				else:
					_set_phase(Phase.WALK)
		Phase.GUARD_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["guard_cast"]):
				_call_guard()
				_set_phase(Phase.WALK)
		Phase.ROAR:
			_hold(delta)
			if phase_time >= float(boss_def["rage_roar"]):
				_set_phase(Phase.WALK)
		Phase.WHIRL_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["whirl_telegraph"]):
				_resolve_whirl()
				_set_phase(Phase.RECOVER)
		Phase.STAGGER:
			_hold(delta)
			if phase_time >= float(boss_def["stagger_time"]):
				_set_phase(Phase.WALK)
	_face_sprite()


## Walking: the shared walk and melee (enemies always advance), striding faster
## when far, his front turning toward what he fights; a lunge, his guard or a
## whirl start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	var aim := target.position if target != null and is_instance_valid(target) else game.player.position  # What he fights.
	_turn_to(aim, delta)
	if guarded and not raged and guard_cd <= 0.0 and _guard_alive() < int(boss_def["guard_max_alive"]):
		_start_guard()
	elif raged and whirl_cd <= 0.0 and _whirl_wanted():
		_start_whirl()
	elif lunge_cd <= 0.0 and dist >= float(boss_def["lunge_min"]) and dist <= float(boss_def["lunge_max"]):
		_lunges_left = int(boss_def["rage_lunges"]) if raged else 1
		lunge_cd = float(boss_def["rage_lunge_cooldown"] if raged else boss_def["lunge_cooldown"])
		_start_lunge()


## Turns his front toward world point `at` by at most turn_rate x `delta` rad.
func _turn_to(at: Vector2, delta: float) -> void:
	var to := at - position
	if to.length_squared() <= 1.0:
		return
	var cur := pantheon_facing.angle()
	var diff := wrapf(to.angle() - cur, -PI, PI)
	var rate := float(boss_def["turn_rate"]) * (float(boss_def["rage_speed_mult"]) if raged else 1.0) * delta  # Most he turns this tick (rad).
	pantheon_facing = Vector2.from_angle(cur + clampf(diff, -rate, rate))


## Mirrors his sprite to his facing (his front, not his movement).
func _face_sprite() -> void:
	if absf(pantheon_facing.x) < 0.2:
		return
	var f := signf(pantheon_facing.x)
	if f != _facing:
		_facing = f
		scale.x = _facing
		queue_redraw()


## Standing still during a windup / call / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# --- The lunge ---------------------------------------------------------------------

## Telegraphs the lunge lane toward the necromancer.
func _start_lunge() -> void:
	_lunges_left -= 1
	var to := game.player.position - position
	_lunge_dir = to.normalized() if to.length() > 1.0 else pantheon_facing
	pantheon_facing = _lunge_dir
	_lunge_left = game.arena.clear_length(position, _lunge_dir, float(boss_def["lunge_length"]), radius * 0.8)
	game.effects.telegraph_line(position, position + _lunge_dir * _lunge_left, float(boss_def["lunge_width"]), float(boss_def["lunge_telegraph"]), self)
	motion_lunge(-_lunge_dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_lunge", 1.0)
	_set_phase(Phase.LUNGE_WINDUP)


## Runs down the lane: strikes the necromancer once, strikes and throws aside
## every summon in it (nothing stops him).
func _step_lunge(delta: float) -> void:
	_tick_timers(delta)
	var spd := float(boss_def["lunge_speed"])
	var step_len := minf(spd * delta, _lunge_left)
	position += _lunge_dir * step_len
	_lunge_left -= step_len
	velocity = _lunge_dir * spd
	var hit_r := float(boss_def["lunge_width"]) * 0.5  # Lane half-width (px).
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	for pl in game.all_players:  # (Co-op: every necromancer in the lane, once.)
		if not _lunge_hit_players.has(pl) and pl.position.distance_to(position) <= hit_r + pl.radius:
			_lunge_hit_players.append(pl)
			game.combat.damage_player(float(boss_def["lunge_damage_player"]) * mult, "achilles_lunge", pl)
	game.ally_grid.query(position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _lunge_hits.has(u):
			continue
		var rel := u.position - position
		if rel.length() > hit_r + u.radius:
			continue
		_lunge_hits.append(u)
		var side := rel - _lunge_dir * rel.dot(_lunge_dir)
		var push := side.normalized() if side.length() > 0.1 else _lunge_dir.orthogonal()
		u.position += push * float(boss_def["lunge_push"])
		game.combat.damage_unit(u, float(boss_def["lunge_damage_summon"]) * mult, "achilles_lunge", self)
		game.stat_add("achilles_lunge_hits", 1.0)
	if _lunge_left <= 0.0:
		game.stat_add("achilles_lunges", 1.0)
		game.effects.slash(position + _lunge_dir * radius, _lunge_dir, Palette.GOLD, radius * 1.8)
		motion_lunge(_lunge_dir, MotionData.POWER_MELEE)
		_set_phase(Phase.RECOVER)


# --- The Myrmidon Charge -----------------------------------------------------------

## He stands calling his guard (the first call shows the banner).
func _start_guard() -> void:
	guard_cd = float(boss_def["guard_interval"])
	if int(game.stats.get("boss_atk_guard", 0.0)) == 0:
		game.enemies.show_banner(String(boss_def["guard_banner"]))
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_guard", 1.0)
	_set_phase(Phase.GUARD_CAST)


## His guard forms a shield wall in front of him (they lock as they arrive).
func _call_guard() -> void:
	var n := int(boss_def["guard_count"])
	var side := Vector2(-pantheon_facing.y, pantheon_facing.x)  # Along the wall.
	var front := position + pantheon_facing * float(boss_def["guard_ahead"])  # The wall's centre.
	var called := 0
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := front + side * (float(i) - float(n - 1) * 0.5) * 24.0
		var e := game.enemies.spawn_at(String(boss_def["guard_kind"]), at, i < int(boss_def["guard_elites"]))
		_guard.append(e)
		_guard_gen.append(e.generation)
		called += 1
	game.effects.ring(position, 90.0, Palette.PANTHEON_AEGEAN_LIGHT, 0.4)
	game.stat_add("achilles_guard_called", float(called))
	if game.pantheon != null:
		game.pantheon.play_sound("shield_lock", position)


## His guard still standing (stale entries dropped).
func _guard_alive() -> int:
	var i := 0
	while i < _guard.size():
		if _guard[i].active and _guard[i].generation == _guard_gen[i]:
			i += 1
		else:
			_guard.remove_at(i)
			_guard_gen.remove_at(i)
	return _guard.size()


# --- The Rage after Patroclus ------------------------------------------------------

## He throws his helmet and shield away and roars: faster, wilder, his guard down.
func _start_rage() -> void:
	raged = true
	_lunges_left = 0
	_base_speed = float(boss_def["move_speed"]) * float(boss_def["rage_speed_mult"])
	attack_interval = _base_interval * float(boss_def["rage_attack_mult"])
	whirl_cd = 1.5
	lunge_cd = minf(lunge_cd, 2.0)
	game.stat_add("achilles_rage_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["rage_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.GOLD)
	game.shake(8.0)
	if game.pantheon != null:
		game.pantheon.play_sound("achilles_rage", position)
	if motion != null:
		motion.reset(UnitMotion.feet_of(motion_sprite_key(), "", radius), radius, MotionData.BOSS_SCALE, false)
	_set_phase(Phase.ROAR)


## True when the necromancer or enough summons stand inside his whirl.
func _whirl_wanted() -> bool:
	var r := float(boss_def["whirl_radius"])  # px.
	if position.distance_to(game.player.position) <= r + game.player.radius:
		return true
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(position) <= r + u.radius:
			n += 1
	return n >= int(boss_def["whirl_min_summons"])


## Telegraphs the whirl's circle.
func _start_whirl() -> void:
	whirl_cd = float(boss_def["whirl_cooldown"])
	game.effects.telegraph_circle(position, float(boss_def["whirl_radius"]), float(boss_def["whirl_telegraph"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_whirl", 1.0)
	_set_phase(Phase.WHIRL_WINDUP)


## The spear sweeps the circle: summons inside are struck and thrown out, the
## necromancer inside struck.
func _resolve_whirl() -> void:
	var r := float(boss_def["whirl_radius"])  # px.
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.ring(position, r, Palette.GOLD, 0.35)
	Sfx.play("rogue_dash", position, 0.45)
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(position) > r + u.radius:
			continue
		var away := u.position - position
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(boss_def["whirl_push"])
		game.combat.damage_unit(u, float(boss_def["whirl_damage_summon"]) * mult, "achilles_whirl", self)
		game.stat_add("achilles_whirl_hits", 1.0)
	for pl in game.all_players:  # (Co-op: every necromancer inside.)
		if pl.position.distance_to(position) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["whirl_damage_player"]) * mult, "achilles_whirl", pl)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the lunge lane or the whirl.
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.LUNGE_WINDUP or phase == Phase.LUNGE:
		var rel := p - position
		var along := rel.dot(_lunge_dir)
		if along > -20.0 and along < float(boss_def["lunge_length"]) + 30.0:
			var side := rel - _lunge_dir * along
			if side.length() < float(boss_def["lunge_width"]) + 30.0:
				return side.normalized() if side.length() > 0.5 else _lunge_dir.orthogonal()
	if phase == Phase.WHIRL_WINDUP:
		var away := p - position
		if away.length() < float(boss_def["whirl_radius"]) + 30.0:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## Ground layer: the gold heel mark under him (behind his feet), brighter while
## he staggers, and his shield's front arc (where blows glance off). Visual only.
func _draw_under() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # World axes (his node is mirrored).
	var h := heel_point() - position  # Heel mark offset (px).
	var hr := float(boss_def["heel_radius"])
	var lit := phase == Phase.STAGGER
	draw_circle(h, hr, Color(Palette.GOLD, 0.35 if lit else 0.18))
	draw_arc(h, hr, 0.0, TAU, 20, Color(Palette.GOLD, 0.95 if lit else 0.6), 2.0)
	draw_line(h + Vector2(-hr * 0.5, 0), h + Vector2(hr * 0.5, 0), Color(Palette.GOLD, 0.7), 1.5)
	draw_line(h + Vector2(0, -hr * 0.5), h + Vector2(0, hr * 0.5), Color(Palette.GOLD, 0.7), 1.5)
	if not raged:
		var a := pantheon_facing.angle()
		var fh := float(boss_def["front_half_angle"])
		draw_arc(Vector2.ZERO, radius * 1.7, a - fh, a + fh, 18, Color(Palette.PANTHEON_BRONZE_LIGHT, 0.45), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Body layer on `ci`: his sprite in the pose of his phase (BossPoseData: 3 the
## lunge), the rage form once he rages; the code glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 3 if (phase == Phase.LUNGE_WINDUP or phase == Phase.LUNGE or phase == Phase.RECOVER) else 0
	var key := motion_sprite_key()
	if SpriteBank.draw_pose(ci, key, pose, Vector2.ZERO, flash > 0.0):
		return
	IlionGlyphs.draw_achilles(ci, Vector2.ZERO, radius, flash > 0.0, raged)


## Overlay layer on `ci`: the rage's gold fire, a stagger star, the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if raged:
		var t := game.elapsed * 6.0  # Flicker phase (visual only).
		ci.draw_arc(Vector2(0, -radius * 1.6), radius * (1.1 + 0.08 * sin(t)), 0.0, TAU, 24, Color(Palette.GOLD, 0.35), 3.0)
	if phase == Phase.STAGGER:
		ci.draw_circle(Vector2(0, marker_y(-radius * 3.2)), 4.0, Palette.GOLD)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var g := float(st.get("achilles_guard_at", -1.0))
	var r := float(st.get("achilles_rage_at", -1.0))
	return "hits: front %d, flank %d, back %d, heel %d, undirected %d | staggers %d | lunges %d (summon hits %d) | myrmidon guard %s (called %d) | rage %s (whirls %d, hits %d) | killed %d, from behind %d | dmg to player %d, summons %d" % [
		int(st.get("achilles_front_hits", 0.0)), int(st.get("achilles_flank_hits", 0.0)), int(st.get("achilles_back_hits", 0.0)),
		int(st.get("achilles_heel_hits", 0.0)), int(st.get("achilles_undirected_hits", 0.0)), int(st.get("achilles_staggers", 0.0)),
		int(st.get("achilles_lunges", 0.0)), int(st.get("achilles_lunge_hits", 0.0)),
		("from %d:%02d" % [floori(g / 60.0), int(g) % 60]) if g >= 0.0 else "no", int(st.get("achilles_guard_called", 0.0)),
		("from %d:%02d" % [floori(r / 60.0), int(r) % 60]) if r >= 0.0 else "no", int(st.get("boss_atk_whirl", 0.0)), int(st.get("achilles_whirl_hits", 0.0)),
		int(st.get("achilles_killed", 0.0)), int(st.get("achilles_heel_kills", 0.0)),
		int(st.get("player_dmg_from_achilles_lunge", 0.0) + st.get("player_dmg_from_achilles_whirl", 0.0) + st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_achilles_lunge", 0.0) + st.get("summon_dmg_from_achilles_whirl", 0.0) + st.get("summon_dmg_from_boss", 0.0))]
