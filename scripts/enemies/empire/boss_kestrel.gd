## BossKestrel — KESTREL, THE DEAD PIXEL, the boss of the Scrap Wastes (Act
## III, Stage 7; GDD §15.0 "The Scrap Wastes (Act III phase 2)"; owner-approved
## proposal: "the Empire's sniper commander, a cyborg markswoman
## (figure-redesign style) who never misses by a single pixel"). Loaded by
## name for the boss id "kestrel" (EnemyDirector.EMPIRE_BOSS_DIR +
## "boss_kestrel.gd"); she arrives at 17:00 (3:00 left). Extends Boss, so
## summons, spells and the spatial hash treat her like any enemy. Every ability
## is telegraphed; numbers in KestrelData.BOSS:
##   * Rifle (Marksman, Decoys) — while she walks at the necromancer she fires
##       rifle_rounds-round bursts at him every rifle_interval s through
##       EmpireShots (Line of Fire: undead between them take the rounds).
##   * Perch — every perch_gap s of walking she crouches over a landing marker
##       (leap_windup s), leaps to a sniper perch perch_min..perch_max px from
##       the necromancer (leap_time s, drawn as an arc) and holds it for
##       perch_time s: the window for the army to close in.
##   * Triple Lock-On — on landing she paints three Lock-On lines at once
##       (LockOn.paint() with the boss override: two on the necromancer, one on
##       the summon nearest him or a third on him), each with its own paint time
##       (lock_paint_1..3), so the three rails come one after another: Grave
##       Step out of one line, put a summon in another.
##   * Decoys (below decoy_hp) — every decoy_interval s she stands decoy_cast s
##       and releases decoy_count Decoy Drones (DecoyKit: her hologram, the
##       army's first target).
##   * Twin Blades (below blades_hp) — she drops the rifle (draw_time s), moves
##       at blade_speed and slashes in reach; every charge_cooldown s she
##       telegraphs a lane (charge_telegraph s) and charges down it at
##       charge_speed: the necromancer in the lane is cut, summons are thrown
##       aside, and a blocker of block_mass >= charge_block_mass stops her dead
##       (she staggers charge_stagger s).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks the
## Death Ray spell and Conductive Marrow (UnlockData, boss "kestrel"). Attack
## poses (BossPoseData): bosses/kestrel_aim while she paints or fires from a
## perch, bosses/kestrel_blades once she draws the blades (its strike pose after
## a charge). Determinism: the seeded global RNG only (the perch angle).
## Stats: boss_atk_<special>, kestrel_rails (lines painted), kestrel_rifle_bursts,
## kestrel_decoys, kestrel_charges, kestrel_charges_blocked, kestrel_charge_hits,
## kestrel_decoy_at, kestrel_blades_at.
class_name BossKestrel
extends Boss

## Boss action phases.
enum Phase { WALK, LEAP_WINDUP, LEAP, PERCH, DECOY_CAST, DRAW_BLADES, CHARGE_WINDUP, CHARGE, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## True once she uses decoys (below decoy_hp).
var decoys_on: bool = false
## True once she drew the twin blades (below blades_hp).
var blades: bool = false
## Seconds of walking left before her next perch.
var perch_cd: float = 0.0
## Seconds until her next rifle burst.
var rifle_cd: float = 0.0
## Rounds of the current rifle burst still to fire.
var _burst_left: int = 0
## Seconds until the burst's next round.
var _burst_cd: float = 0.0
## Index of the burst's next round (its fan offset).
var _burst_index: int = 0
## Seconds until her next decoy release.
var decoy_cd: float = 0.0
## Seconds until her next charge.
var charge_cd: float = 0.0
## Where the current leap started (world px).
var _leap_from: Vector2 = Vector2.ZERO
## The perch she leaps to (world px).
var _leap_to: Vector2 = Vector2.ZERO
## Unit direction of the current charge (locked at its windup).
var _charge_dir: Vector2 = Vector2.RIGHT
## Distance (px) of the charge lane still to run.
var _charge_left: float = 0.0
## Summons already struck by the current charge.
var _charge_hits: Array[SummonedUnit] = []
## True once the current charge struck the necromancer.
var _charge_hit_player: bool = false
## Co-op: the other necromancers the current charge already hit (Necromancer
## -> true; the first in Game.all_players keeps the flag).
var _charge_hit_more: Dictionary = {}
## Seconds the RECOVER phase lasts this time (a blocked charge staggers longer).
var _recover_for: float = 0.0
## Move speed of her current form (px/s).
var _base_speed: float = 54.0


## Sets up Kestrel at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = KestrelData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	decoys_on = false
	blades = false
	perch_cd = float(boss_def["first_perch"])
	rifle_cd = 1.0
	decoy_cd = 0.0
	charge_cd = 0.0
	_burst_left = 0
	_base_speed = move_speed


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return KestrelData.SPECIALS


## True while she walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of her art (engine-motion pivot): the rifle or the blades.
func motion_sprite_key() -> String:
	return "bosses/kestrel_blades" if blades and SpriteBank.has("bosses/kestrel_blades") else "bosses/kestrel"


## Boss physics: her phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	perch_cd -= delta
	rifle_cd -= delta
	decoy_cd -= delta
	charge_cd -= delta
	_step_burst(delta)
	if not decoys_on and hp <= max_hp * float(boss_def["decoy_hp"]):
		decoys_on = true
		decoy_cd = 0.5
		game.stat_add("kestrel_decoy_at", game.elapsed)
		game.enemies.show_banner(String(boss_def["decoy_banner"]))
	if not blades and hp <= max_hp * float(boss_def["blades_hp"]) and (phase == Phase.WALK or phase == Phase.PERCH):
		_start_blades()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.LEAP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["leap_windup"]):
				_set_phase(Phase.LEAP)
				Sfx.play("servo_step", position, 1.3)
		Phase.LEAP:
			_tick_timers(delta)
			var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)  # 0 -> 1 through the leap.
			position = _leap_from.lerp(_leap_to, k)
			velocity = (_leap_to - _leap_from) / maxf(0.01, float(boss_def["leap_time"]))
			queue_redraw()
			if k >= 1.0:
				_land_on_perch()
		Phase.PERCH:
			_hold(delta)
			if decoys_on and decoy_cd <= 0.0:
				_start_decoys()
			elif phase_time >= float(boss_def["perch_time"]):
				perch_cd = float(boss_def["perch_gap"])
				_set_phase(Phase.WALK)
		Phase.DECOY_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["decoy_cast"]):
				_release_decoys()
				_set_phase(Phase.WALK)
		Phase.DRAW_BLADES:
			_hold(delta)
			if phase_time >= float(boss_def["draw_time"]):
				charge_cd = 1.0
				_set_phase(Phase.WALK)
		Phase.CHARGE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["charge_telegraph"]):
				_charge_hits.clear()
				_charge_hit_player = false
				_charge_hit_more.clear()
				Sfx.play("rogue_dash", position, 0.7)
				_set_phase(Phase.CHARGE)
		Phase.CHARGE:
			_step_charge(delta)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= _recover_for:
				_set_phase(Phase.WALK)


## Walking: the shared walk and melee (enemies always advance), striding faster
## when far; the rifle fires; a perch, decoys or a charge start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if blades:
		if charge_cd <= 0.0 and dist >= float(boss_def["charge_min"]) and dist <= float(boss_def["charge_max"]):
			_start_charge()
		return
	if rifle_cd <= 0.0 and dist <= float(boss_def["rifle_range"]):
		rifle_cd = float(boss_def["rifle_interval"])
		_burst_left = int(boss_def["rifle_rounds"])
		_burst_index = 0
		_burst_cd = 0.0
		game.stat_add("kestrel_rifle_bursts", 1.0)
		Sfx.play("rifle_burst", position, 0.85)
	if decoys_on and decoy_cd <= 0.0:
		_start_decoys()
	elif perch_cd <= 0.0:
		_start_leap()


## Fires the rounds of a running rifle burst on their gaps (the walk keeps going).
func _step_burst(delta: float) -> void:
	if _burst_left <= 0 or blades:
		_burst_left = 0
		return
	_burst_cd -= delta
	if _burst_cd > 0.0:
		return
	var to := game.player.position - position  # Toward the necromancer.
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var n := int(boss_def["rifle_rounds"])  # Rounds in a burst.
	var fan := (float(_burst_index) - float(n - 1) * 0.5) * float(boss_def["rifle_spread"])  # Fan offset (rad).
	var dmg := float(boss_def["rifle_damage"]) * game.enemies.damage_mult * hit_mult()  # Time-scaled round damage.
	game.empire_rules().shots.fire(position + dir * (radius + 2.0), dir.rotated(fan), float(boss_def["rifle_speed"]), dmg,
			undead_damage_mult, "round", "kestrel_rifle", float(boss_def["rifle_range"]))
	_burst_index += 1
	_burst_left -= 1
	_burst_cd = float(boss_def["rifle_gap"])


## Standing still during a windup / perch / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# Perches and the triple Lock-On
# =====================================================================================

## Picks a perch around the necromancer and shows its landing marker.
func _start_leap() -> void:
	var p := game.player.position
	var from_p := position - p  # From the necromancer to her.
	var base := from_p.angle() if from_p.length() > 1.0 else 0.0  # Her current bearing (rad).
	var turn := randf_range(float(boss_def["perch_turn_min"]), float(boss_def["perch_turn_max"])) * (1.0 if randf() < 0.5 else -1.0)  # Around him (rad).
	var dist := randf_range(float(boss_def["perch_min"]), float(boss_def["perch_max"]))  # Perch distance (px).
	_leap_from = position
	_leap_to = game.arena.free_point(p + Vector2.from_angle(base + turn) * dist, radius)
	game.effects.telegraph_circle(_leap_to, radius * 2.2, float(boss_def["leap_windup"]) + float(boss_def["leap_time"]), self)
	motion_lunge(_leap_to - position, MotionData.POWER_CAST)  # Engine motion: the crouch (visual only).
	game.stat_add("boss_atk_perch", 1.0)
	_set_phase(Phase.LEAP_WINDUP)


## She lands on the perch: the triple Lock-On.
func _land_on_perch() -> void:
	position = _leap_to
	velocity = Vector2.ZERO
	game.effects.impact(position, radius * 2.0, Palette.EMPIRE_CHROME_LIGHT)
	Sfx.play("servo_step", position, 0.8)
	_paint_triple()
	_set_phase(Phase.PERCH)


## Paints the three lines (LockOn boss override): two on the necromancer, the
## third on the summon nearest him (or on him again when he stands alone).
func _paint_triple() -> void:
	var lock := game.empire_rules().lock_on  # The Lock-On lines.
	var dmg := float(boss_def["lock_damage"]) * game.enemies.damage_mult * hit_mult()  # Time-scaled rail damage.
	var spd := float(boss_def["lock_speed"])
	var reach := float(boss_def["lock_reach"])
	var third: Node2D = _summon_nearest_player()
	if third == null:
		third = game.player
	var targets: Array[Node2D] = [game.player, game.player, third]
	var painted := 0
	for i in targets.size():
		if lock.paint(self, targets[i], dmg, spd, reach, "kestrel_rail", true, float(boss_def["lock_paint_%d" % (i + 1)])):
			painted += 1
	game.stat_add("boss_atk_triple_lock", 1.0)
	game.stat_add("kestrel_rails", float(painted))


## The living summon nearest the necromancer (within 260 px), or null.
func _summon_nearest_player() -> SummonedUnit:
	var p := game.player.position
	game.ally_grid.query(p, 260.0, _tmp)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var d := u.position.distance_to(p)
		if d < best_d:
			best_d = d
			best = u
	return best


# =====================================================================================
# Decoys
# =====================================================================================

## She stands and raises her projector arm.
func _start_decoys() -> void:
	decoy_cd = float(boss_def["decoy_interval"])
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_decoys", 1.0)
	_set_phase(Phase.DECOY_CAST)


## The decoy drones launch around her.
func _release_decoys() -> void:
	var n := int(boss_def["decoy_count"])  # Drones this release.
	var to := game.player.position - position
	var base := to.angle() if to.length() > 1.0 else 0.0
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := position + Vector2.from_angle(base + TAU * (float(i) + 0.5) / float(n)) * (radius + 46.0)
		game.enemies.spawn_at(WastesEnemyData.DECOY, at, false)
	game.effects.ring(position, 80.0, Palette.EMPIRE_SIGNAL_AMBER, 0.4)
	game.stat_add("kestrel_decoys", float(n))
	Sfx.play("lock_on", position, 0.7)


# =====================================================================================
# Twin Blades and the charge
# =====================================================================================

## She drops the rifle and draws the twin blades.
func _start_blades() -> void:
	blades = true
	_burst_left = 0
	_base_speed = float(boss_def["blade_speed"])
	damage = float(boss_def["blade_damage"])
	attack_interval = float(boss_def["blade_interval"])
	game.stat_add("kestrel_blades_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["blades_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.EMPIRE_SIGNAL_RED)
	Sfx.play("boss_arrive", position, 1.2)
	if motion != null:
		motion.reset(UnitMotion.feet_of(motion_sprite_key(), "", radius), radius, MotionData.BOSS_SCALE, false)
	_set_phase(Phase.DRAW_BLADES)


## Telegraphs the charge lane toward the necromancer.
func _start_charge() -> void:
	charge_cd = float(boss_def["charge_cooldown"])
	var to := game.player.position - position
	_charge_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_charge_left = game.arena.clear_length(position, _charge_dir, float(boss_def["charge_length"]), radius * 0.8)
	game.effects.telegraph_line(position, position + _charge_dir * _charge_left, float(boss_def["charge_width"]), float(boss_def["charge_telegraph"]), self)
	motion_lunge(-_charge_dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_charge", 1.0)
	_set_phase(Phase.CHARGE_WINDUP)


## Runs down the lane: cuts the necromancer once, throws summons aside, and
## stops dead on a blocker heavy enough.
func _step_charge(delta: float) -> void:
	_tick_timers(delta)
	var spd := float(boss_def["charge_speed"])
	var step_len := minf(spd * delta, _charge_left)
	position += _charge_dir * step_len
	_charge_left -= step_len
	velocity = _charge_dir * spd
	var hit_r := float(boss_def["charge_width"]) * 0.5  # Lane half-width (px).
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	for k in game.all_players.size():  # (Co-op: every necromancer in the lane, once.)
		var pl := game.all_players[k]
		var done := _charge_hit_player if k == 0 else _charge_hit_more.has(pl)  # Already hit by this charge.
		if not done and pl.position.distance_to(position) <= hit_r + pl.radius:
			if k == 0:
				_charge_hit_player = true
			else:
				_charge_hit_more[pl] = true
			game.combat.damage_player(float(boss_def["charge_damage_player"]) * mult, "kestrel_charge", pl)
	game.ally_grid.query(position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _charge_hits.has(u):
			continue
		var rel := u.position - position
		if rel.length() > hit_r + u.radius:
			continue
		_charge_hits.append(u)
		if u.block_mass >= float(boss_def["charge_block_mass"]):
			# A blocker stands in her path: the charge ends here.
			_charge_left = 0.0
			game.effects.slash(position + _charge_dir * radius, _charge_dir, Palette.EMPIRE_SIGNAL_GLOW, radius * 1.6)
			game.combat.damage_unit(u, float(boss_def["charge_damage_summon"]) * mult * 0.5, "kestrel_charge")
			game.stat_add("kestrel_charges_blocked", 1.0)
			_recover_for = float(boss_def["charge_stagger"])
			_set_phase(Phase.RECOVER)
			return
		var side := rel - _charge_dir * rel.dot(_charge_dir)
		var push := side.normalized() if side.length() > 0.1 else _charge_dir.orthogonal()
		u.position += push * float(boss_def["charge_push"])
		game.combat.damage_unit(u, float(boss_def["charge_damage_summon"]) * mult, "kestrel_charge")
		game.stat_add("kestrel_charge_hits", 1.0)
	if _charge_left <= 0.0:
		game.stat_add("kestrel_charges", 1.0)
		_recover_for = float(boss_def["recover_time"])
		motion_lunge(_charge_dir, MotionData.POWER_MELEE)
		_set_phase(Phase.RECOVER)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the charge lane (the
## Lock-On lines are LockOn's own hint).
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.CHARGE_WINDUP or phase == Phase.CHARGE:
		var rel := p - position
		var along := rel.dot(_charge_dir)
		if along > -20.0 and along < float(boss_def["charge_length"]) + 30.0:
			var side := rel - _charge_dir * along
			if side.length() < float(boss_def["charge_width"]) + 30.0:
				return side.normalized() if side.length() > 0.5 else _charge_dir.orthogonal()
	return Vector2.ZERO


## Body layer on `ci`: her sprite in the pose of her phase (BossPoseData: 1
## aiming from a perch, 2 leaping, 3 the blades' strike), lifted along the leap.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.PERCH, Phase.DECOY_CAST:
			pose = 1
		Phase.LEAP_WINDUP, Phase.LEAP:
			pose = 2
		Phase.CHARGE, Phase.RECOVER:
			pose = 3
	var lift := Vector2.ZERO  # The leap's arc (visual only).
	if phase == Phase.LEAP:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
		lift = Vector2(0.0, -4.0 * k * (1.0 - k) * float(boss_def["leap_height"]))
	var key := "bosses/kestrel_blades" if blades else "bosses/kestrel"
	if SpriteBank.draw_pose(ci, key, pose, lift, flash > 0.0):
		return
	if blades and SpriteBank.draw(ci, "bosses/kestrel", lift, flash > 0.0):
		return
	WastesGlyphs.draw_kestrel(ci, lift, radius, flash > 0.0, Color.WHITE, 3 if blades else pose)


## Overlay layer on `ci`: the red scope glint while she aims, the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if phase == Phase.PERCH and not blades:
		ci.draw_circle(Vector2(radius * 0.6, -radius * 1.4), 3.0, Color(Palette.EMPIRE_SIGNAL_RED, 0.8))
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var dec := float(st.get("kestrel_decoy_at", -1.0))
	var bla := float(st.get("kestrel_blades_at", -1.0))
	return "perches %d | triple lock-ons %d (rails painted %d, rail dmg to you %d) | rifle bursts %d | decoys %s (drones %d) | twin blades %s | charges %d (blocked by summons %d, summon hits %d) | dmg to player %d, summons %d" % [
		int(st.get("boss_atk_perch", 0.0)), int(st.get("boss_atk_triple_lock", 0.0)), int(st.get("kestrel_rails", 0.0)),
		int(st.get("player_dmg_from_kestrel_rail", 0.0)), int(st.get("kestrel_rifle_bursts", 0.0)),
		("from %d:%02d" % [floori(dec / 60.0), int(dec) % 60]) if dec >= 0.0 else "no", int(st.get("kestrel_decoys", 0.0)),
		("from %d:%02d" % [floori(bla / 60.0), int(bla) % 60]) if bla >= 0.0 else "no",
		int(st.get("kestrel_charges", 0.0)) + int(st.get("kestrel_charges_blocked", 0.0)), int(st.get("kestrel_charges_blocked", 0.0)),
		int(st.get("kestrel_charge_hits", 0.0)),
		int(st.get("player_dmg_from_kestrel_rail", 0.0) + st.get("player_dmg_from_kestrel_rifle", 0.0) + st.get("player_dmg_from_kestrel_charge", 0.0) + st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_kestrel_rail", 0.0) + st.get("summon_dmg_from_kestrel_rifle", 0.0) + st.get("summon_dmg_from_kestrel_charge", 0.0) + st.get("summon_dmg_from_boss", 0.0))]
