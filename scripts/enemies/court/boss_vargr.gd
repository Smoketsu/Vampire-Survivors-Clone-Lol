## BossVargr — VARGR, THE MOON-EATER, the boss of Ravensmoor (Act VII, Stage 19;
## GDD §15.0 "Vargr, the Moon-Eater (Act VII)"; owner-approved proposal: "the
## werewolf king. He calls his own Blood Moon at each phase: the Hunt (he
## circles the ring and lunges at the weakest summon), the Turning (his pack
## transforms around him and he leaps over the ring at the necromancer), the
## Moon-Eater (he swallows the moon: the arena goes dark except a red circle
## around him, and every hit he lands feeds him)"). Loaded by name for the boss
## id "vargr" (EnemyDirector.COURT_BOSS_DIR + "boss_vargr.gd"); he arrives at
## 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy. Every ability is telegraphed; numbers in
## VargrData.BOSS. Three phases by his HP, each calling HIS OWN MOON through
## BloodMoon.force() (the one moon clock; it works on any stage the Court's
## rules exist, --boss=vargr elsewhere):
##   * THE HUNT: he circles the Bone Ring (circle_radius px from the
##     necromancer) biting what he touches; every lunge_cooldown s he crouches
##     (a red line to his mark) and lunges at the WEAKEST summon within
##     lunge_reach px (least HP left; the necromancer when none), a feeding bite.
##   * THE TURNING: he howls: every werewolf near him turns into the beast at
##     once (WerewolfKit.howl_turn(), the werewolves' one turning path) and his
##     pack steps out around him already turned (under the hard cap, at most
##     pack_cap standing), again every howl_every s; he walks at the
##     necromancer and LEAPS OVER THE RING at him every leap_cooldown s: the
##     landing circle shows, he flies there, and every necromancer and summon
##     in it is hit (OlympusHits.circle(), naming him: it feeds) and thrown out.
##   * THE MOON-EATER: the arena goes dark except a red circle around him
##     (VargrDark, drawn only, never headless); faster, harder, he lunges and
##     leaps both, and every hit he lands feeds him harder (his boss_def
##     "feeds" becomes feeds_p3: Bloodfeast.share_of() reads it, the one path).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Moonfang spell and Pack Blood (UnlockData, boss "vargr"). Attack pose
## (BossPoseData, when the art has one): pose 1 while he crouches or howls.
## Determinism: no RNG (his pack steps out on fixed angles). Stats:
## boss_atk_<special>, vargr_lunge_hits, vargr_lunge_on_you, vargr_leap_hits,
## vargr_pack, vargr_howl_turned, vargr_phase2_at, vargr_phase3_at,
## vargr_moons.
class_name BossVargr
extends Boss

## Boss action phases.
enum Phase { WALK, LUNGE_WINDUP, LUNGE, LEAP_WINDUP, LEAP, HOWL, RECOVER }

## Seconds of the howl's pose.
const HOWL_TIME: float = 0.8  # TUNING (not in GDD)

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His form: 1 the Hunt, 2 the Turning, 3 the Moon-Eater.
var form: int = 1
## Seconds until his next lunge.
var lunge_cd: float = 0.0
## Seconds until his next leap (the Turning on).
var leap_cd: float = INF
## Seconds until his next howl (the Turning on).
var howl_cd: float = INF
## Seconds until the Moon-Eater's moon is forced again.
var _moon_cd: float = 0.0
## The lunge's prey (a summon or a necromancer).
var _prey: Node2D = null
## Pool generation of a summon prey (stale guard; 0 for a necromancer).
var _prey_gen: int = 0
## Where a lunge or leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where a lunge or leap lands (world px; locked at its windup).
var _to: Vector2 = Vector2.ZERO
## Direction he circles (+1 / -1; flips each lunge).
var _orbit_dir: float = 1.0
## His pack: the werewolves his howls brought (generation-checked).
var _pack: Array[Enemy] = []
## Pool generation of each entry of `_pack`.
var _pack_gens: PackedInt32Array = PackedInt32Array()
## The Moon-Eater's darkness (null before; never headless).
var _dark: VargrDark = null
## Move speed of his current form (px/s).
var _base_speed: float = 60.0


## Sets up Vargr at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = VargrData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	lunge_cd = float(boss_def["first_lunge"])
	leap_cd = INF
	howl_cd = INF
	_moon_cd = 0.0
	_prey = null
	_pack.clear()
	_pack_gens.clear()
	_base_speed = move_speed
	_orbit_dir = 1.0
	var rules := game.court_rules()  # His moon is the Court's (created on another stage too, --boss=vargr).
	rules.moon.force(float(boss_def["moon_hunt"]))
	rules.play_sound("vargr_roar", position)
	game.stat_add("vargr_moons", 1.0)
	game.enemies.show_banner(String(boss_def["hunt_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return VargrData.SPECIALS


## True while he walks or circles (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## His fall (or any removal) lifts the darkness.
func deactivate() -> void:
	if _dark != null:
		_dark.queue_free()
		_dark = null
	_prey = null
	super.deactivate()


## Boss physics: his phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	lunge_cd -= delta
	leap_cd -= delta
	howl_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_turning()
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		_moon_eater()
	if form == 3:
		_moon_cd -= delta
		if _moon_cd <= 0.0:
			_moon_cd = 1.0
			game.court_rules().moon.force(float(boss_def["moon_eater_hold"]))  # He holds the swallowed moon while he lives.
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.LUNGE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["lunge_windup"]):
				_from = position
				_set_phase(Phase.LUNGE)
		Phase.LUNGE:
			_tick_timers(delta)
			var k := clampf(phase_time / maxf(0.01, float(boss_def["lunge_time"])), 0.0, 1.0)
			position = _from.lerp(_to, k)
			velocity = Vector2.ZERO
			if k >= 1.0:
				_land_lunge()
				_set_phase(Phase.RECOVER)
		Phase.LEAP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["leap_windup"]):
				_from = position
				_set_phase(Phase.LEAP)
		Phase.LEAP:
			_tick_timers(delta)
			var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
			position = _from.lerp(_to, k)
			velocity = Vector2.ZERO
			queue_redraw()  # The arc.
			if k >= 1.0:
				_land_leap()
				_set_phase(Phase.RECOVER)
		Phase.HOWL:
			_hold(delta)
			if phase_time >= HOWL_TIME:
				_set_phase(Phase.WALK)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Walking: the Hunt circles the ring, the later forms walk at the
## necromancer (the shared walk and melee); a howl, a leap or a lunge start
## when ready.
func _step_walk(delta: float) -> void:
	var pl := game.player
	var dist := position.distance_to(pl.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	if form == 1:
		_circle(delta)
	else:
		super.physics_step(delta)
	if form >= 2 and howl_cd <= 0.0:
		_start_howl()
	elif form >= 2 and leap_cd <= 0.0 and dist <= float(boss_def["lunge_reach"]) + 260.0:
		_start_leap()
	elif form != 2 and lunge_cd <= 0.0:
		_start_lunge()


## The Hunt: he runs around the necromancer circle_radius px out and bites
## whatever he touches on the way.
func _circle(delta: float) -> void:
	_tick_timers(delta)
	var pl := game.player
	var off := position - pl.position
	var a := off.angle() + float(boss_def["circle_speed"]) * _orbit_dir * delta * 3.0
	var goal := pl.position + Vector2.from_angle(a) * float(boss_def["circle_radius"])
	var to := goal - position
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	var step := minf(spd * delta, to.length())
	velocity = to.normalized() * spd if to.length() > 0.5 else Vector2.ZERO
	if step > 0.0:
		position += to.normalized() * step
	_update_facing()
	if not _target_valid():
		_set_target(pl)
	var t := target
	var tt := t.position - position
	var edge := tt.length() - radius - _radius_of(t)
	if edge <= attack_range and attack_cd <= 0.0:
		_melee_hit(t, tt.normalized() if tt.length() > 0.01 else Vector2.RIGHT)


## Standing still during a windup or recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# The phases (each calls his own moon)
# =====================================================================================

## The Turning: his moon, the banner, a howl at once and the leaps begin.
func _turning() -> void:
	form = 2
	game.stat_add("vargr_phase2_at", game.elapsed)
	game.court_rules().moon.force(float(boss_def["moon_turning"]))
	game.court_rules().play_sound("vargr_roar", position)
	game.stat_add("vargr_moons", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.COURT_BLOOD)
	howl_cd = 0.0
	leap_cd = float(boss_def["first_leap"])
	if phase == Phase.WALK:
		_start_howl()


## The Moon-Eater: he swallows the moon (the darkness), feeds harder, runs faster.
func _moon_eater() -> void:
	form = 3
	game.stat_add("vargr_phase3_at", game.elapsed)
	game.stat_add("boss_atk_moon_eater", 1.0)
	game.stat_add("vargr_moons", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.COURT_BLOOD_LIGHT)
	game.shake(8.0)
	var def := boss_def.duplicate()  # His own copy: the Moon-Eater feeds harder (Bloodfeast.share_of() reads "feeds").
	def["feeds"] = float(boss_def["feeds_p3"])
	boss_def = def
	_base_speed = float(boss_def["eater_speed"])
	damage = float(boss_def["eater_damage"])
	lunge_cd = minf(lunge_cd, 2.0)
	leap_cd = minf(leap_cd, float(boss_def["leap_cooldown_p3"]))
	_moon_cd = 0.0
	game.court_rules().play_sound("vargr_roar", position)
	if DisplayServer.get_name() != "headless" and _dark == null:
		_dark = VargrDark.new(game, self, float(boss_def["dark_radius"]), float(boss_def["dark_alpha"]))
		game.add_child(_dark)


# =====================================================================================
# The lunge at the weakest summon
# =====================================================================================

## Crouches toward the weakest summon in reach (else the necromancer).
func _start_lunge() -> void:
	lunge_cd = float(boss_def["lunge_cooldown_p3"] if form == 3 else boss_def["lunge_cooldown"])
	var reach := float(boss_def["lunge_reach"])
	_prey = null
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	for u: SummonedUnit in _tmp:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) > reach + u.radius:
			continue
		if best == null or u.hp < best.hp or (u.hp == best.hp and u.position.distance_squared_to(position) < best.position.distance_squared_to(position)):
			best = u
	var t: Node2D = best
	if t == null:
		if position.distance_to(game.player.position) > reach or game.ultimates.player_untargetable():
			lunge_cd = 1.0  # Nothing to hunt: try again soon.
			return
		t = game.player
	_prey = t
	_prey_gen = best.generation if best != null else 0
	var to := t.position - position
	var dist := to.length()
	var r := best.radius if best != null else game.player.radius
	_to = t.position - (to / dist * (radius + r) if dist > 0.01 else Vector2.ZERO)
	_to = game.arena.free_point(_to, radius * 0.5)
	game.effects.telegraph_line(position, _to, radius * 1.2, float(boss_def["lunge_windup"]), self)
	motion_lunge(-to.normalized() if dist > 0.01 else Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_lunge", 1.0)
	_orbit_dir = -_orbit_dir
	_set_phase(Phase.LUNGE_WINDUP)


## The lunge lands: the bite on his prey if it is still within reach.
func _land_lunge() -> void:
	var t := _prey
	_prey = null
	if t == null or not is_instance_valid(t):
		return
	if t is SummonedUnit:
		var u := t as SummonedUnit
		if not u.active or u.generation != _prey_gen or u.state == SummonedUnit.State.DEAD:
			return
	elif (t as Necromancer).dead:
		return
	var r := (t as SummonedUnit).radius if t is SummonedUnit else game.player.radius
	if position.distance_to(t.position) - radius - r > attack_range + 14.0:
		return
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.slash(position, t.position - position, Palette.COURT_BLOOD_LIGHT, radius * 1.6)
	game.stat_add("vargr_lunge_hits", 1.0)
	if t is SummonedUnit:
		game.combat.damage_unit(t as SummonedUnit, float(boss_def["lunge_damage"]) * mult * undead_damage_mult, VargrData.LUNGE_SOURCE, self)
	else:
		game.stat_add("vargr_lunge_on_you", 1.0)
		game.combat.damage_player(float(boss_def["lunge_damage_player"]) * mult, VargrData.LUNGE_SOURCE, t as Necromancer, self)
	game.shake(3.0)


# =====================================================================================
# The Turning: the howl and the leap over the ring
# =====================================================================================

## The howl: every werewolf near him turns, and his pack steps out turned.
func _start_howl() -> void:
	howl_cd = float(boss_def["howl_every"])
	game.stat_add("boss_atk_howl", 1.0)
	game.court_rules().play_sound("wolf_howl", position)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	var turned := 0
	game.enemy_grid.query(position, float(boss_def["howl_radius"]), _tmp)
	for o: Enemy in _tmp:
		if o.active and o.kit is WerewolfKit and o.position.distance_to(position) <= float(boss_def["howl_radius"]):
			if (o.kit as WerewolfKit).howl_turn(o):
				turned += 1
	game.stat_add("vargr_howl_turned", float(turned))
	var i := _pack.size() - 1
	while i >= 0:
		if not _pack[i].active or _pack[i].generation != _pack_gens[i]:
			_pack.remove_at(i)
			_pack_gens.remove_at(i)
		i -= 1
	var n := mini(int(boss_def["pack_count"]), int(boss_def["pack_cap"]) - _pack.size())
	for k in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := game.arena.free_point(position + Vector2.from_angle(TAU * float(k) / float(maxi(1, n)) + float(_pack.size())) * float(boss_def["pack_dist"]), 16.0)
		var e := game.enemies.spawn_at(CourtEnemyData.WEREWOLF, at, false)
		if e == null:
			continue
		if e.kit is WerewolfKit:
			(e.kit as WerewolfKit).howl_turn(e)
		_pack.append(e)
		_pack_gens.append(e.generation)
		game.stat_add("vargr_pack", 1.0)
		game.effects.ring(at, 24.0, Palette.COURT_BLOOD, 0.35)
	game.effects.ring(position, float(boss_def["howl_radius"]) * 0.5, Palette.COURT_MOON, 0.5)
	_set_phase(Phase.HOWL)


## The leap: the landing circle shows where the necromancer stands.
func _start_leap() -> void:
	leap_cd = float(boss_def["leap_cooldown_p3"] if form == 3 else boss_def["leap_cooldown"])
	if game.ultimates.player_untargetable():
		leap_cd = 1.0
		return
	_to = game.arena.free_point(game.player.position, radius * 0.5)
	game.effects.telegraph_circle(_to, float(boss_def["leap_radius"]), float(boss_def["leap_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_leap", 1.0)
	_set_phase(Phase.LEAP_WINDUP)


## The leap lands: every necromancer and summon in the circle is hit (naming
## him: Bloodfeast feeds him) and the summons thrown out.
func _land_leap() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.stat_add("vargr_leap_hits", float(OlympusHits.circle(game, position, float(boss_def["leap_radius"]),
			float(boss_def["leap_damage_player"]) * mult, float(boss_def["leap_damage_summon"]) * mult * undead_damage_mult,
			VargrData.LEAP_SOURCE, self, float(boss_def["leap_push"]), _tmp)))
	game.effects.impact(position, float(boss_def["leap_radius"]), Palette.COURT_BLOOD)
	game.shake(6.0)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the leap's landing circle,
## and sideways off the lunge's line.
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.LEAP_WINDUP or phase == Phase.LEAP:
		var off := p - _to
		var reach := float(boss_def["leap_radius"]) + 24.0
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	if (phase == Phase.LUNGE_WINDUP or phase == Phase.LUNGE) and _prey == game.player:
		var off := p - _to
		var reach := radius + 26.0
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.0
	return Vector2.ZERO


## Body layer on `ci`: his sprite in the pose of his phase (pose 1 while he
## crouches or howls), lifted on the leap's arc, a red glow as the Moon-Eater.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.LUNGE_WINDUP, Phase.LEAP_WINDUP, Phase.HOWL:
			pose = 1
	var lift := Vector2.ZERO
	if phase == Phase.LEAP:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
		lift = Vector2(0.0, -float(boss_def["leap_height"]) * 4.0 * k * (1.0 - k))
	if form == 3:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.2), radius * 1.3, Color(Palette.COURT_BLOOD, 0.22))
	if not SpriteBank.draw_pose(ci, VargrData.SPRITE, pose, lift, flash > 0.0):
		RavensmoorGlyphs.draw_vargr(ci, lift, radius, flash > 0.0, form == 3)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: his shadow stays on the ground while he leaps.
func _draw_under() -> void:
	super._draw_under()
	if phase == Phase.LEAP:
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-radius, radius * 0.4), Vector2(radius * 2.0, radius * 0.7)), false, Color(0.0, 0.0, 0.0, 0.35))


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("vargr_phase2_at", -1.0))
	var p3 := float(st.get("vargr_phase3_at", -1.0))
	return "his moons %d | lunges %d (bites %d, on you %d) | howls %d (werewolves turned %d, pack %d) | leaps %d (hits %d) | the Turning %s | the Moon-Eater %s | fed %d | dmg to you %d, to summons %d" % [
		int(st.get("vargr_moons", 0.0)), int(st.get("boss_atk_lunge", 0.0)), int(st.get("vargr_lunge_hits", 0.0)), int(st.get("vargr_lunge_on_you", 0.0)),
		int(st.get("boss_atk_howl", 0.0)), int(st.get("vargr_howl_turned", 0.0)), int(st.get("vargr_pack", 0.0)),
		int(st.get("boss_atk_leap", 0.0)), int(st.get("vargr_leap_hits", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", EmpireReport._clock(p3) if p3 >= 0.0 else "not reached",
		int(st.get("feast_heal_boss", 0.0)),
		int(st.get("player_dmg_from_" + VargrData.LUNGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + VargrData.LEAP_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + VargrData.LUNGE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + VargrData.LEAP_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
