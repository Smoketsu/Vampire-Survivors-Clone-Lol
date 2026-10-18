## BossMerrow — ABBOT SILAS MERROW, VOICE OF THE DEEP, the boss of Gullhaven
## Harbour (Act II, GDD §15.0 "Gullhaven Harbour (Act II phase 2)"; owner-
## approved proposal: "the town's priest, halfway through his
## transformation"). Loaded by name for the boss id "merrow"
## (EnemyDirector.EYE_BOSS_DIR + "boss_merrow.gd"); he arrives at 17:00 (3:00
## left). Extends Boss, so summons, spells and the spatial hash treat him like
## any enemy. Every ability is telegraphed; numbers in MerrowData.BOSS:
##   * Sermon (robed)      — he climbs a pulpit and preaches for
##                           sermon_duration s: every Ancient Eye cultist
##                           within sermon_radius is buffed through the one
##                           aura-buff path (Enemy.buff_damage / buff_speed /
##                           buff_taken / buff_time, refreshed every
##                           sermon_pulse s). Losing sermon_break of his max HP
##                           breaks it off.
##   * Brine Wave (robed)  — a cone of water toward the necromancer: summons in
##                           it are hurt and thrown back, the necromancer hit.
##   * The Change          — below change_hp he sheds his robes (change_time s
##                           transforming) and fights hand to hand: faster, with
##                           long whipping limbs.
##   * Limb Lash (changed) — lash_count lanes fanned at the necromancer, then
##                           the limbs crack down them; undead in a lane soak
##                           it for whoever stands behind (the first body in
##                           each lane is struck).
##   * Whirl (changed)     — a circle around him, then his limbs whirl through
##                           it: summons inside are hurt and thrown out.
##   * High Water          — below high_water_hp he calls the tide in early:
##                           the arena becomes one long flooded strip with the
##                           seawall at its edge (TideDirector.start_high_water();
##                           just a banner on a stage without the tide), and his
##                           specials come faster.
## Specials are chosen by weight among the ready, usable ones of his form
## (seeded RNG); between them he walks at the necromancer and strikes in
## reach. He swims (HarbourStage.TIDE "swimmers" names "merrow"). Killing him
## drops a big XP burst and the boss chest; slaying him unlocks the Undertow
## spell and Salt of the Deep (UnlockData, boss "merrow").
## Stats: boss_atk_<special>, merrow_sermon_pulses (cultists buffed),
## merrow_sermons_broken, merrow_wave_hits, merrow_lash_hits, merrow_whirl_hits,
## merrow_change_at, merrow_high_water_at.
class_name BossMerrow
extends Boss

## Boss attack phases.
enum Phase { WALK, SERMON, WAVE_WINDUP, CHANGE, LASH_WINDUP, WHIRL_WINDUP, RECOVER }

## Current phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.5
## True once he shed his robes (The Change).
var changed: bool = false
## True once he called the tide in (High Water).
var high_water: bool = false
## Unit direction of the current wave / lash (locked at its windup).
var aim: Vector2 = Vector2.RIGHT
## HP when the current sermon began (breaking it off).
var _sermon_hp: float = 0.0
## Seconds until the next sermon buff pulse.
var _pulse_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var _special_cds: Dictionary = {}
## Last special used (not chosen twice in a row when another is ready).
var _last_special: String = ""
## Move speed of his current form (px/s).
var _base_speed: float = 46.0


## Sets up Abbot Merrow at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MerrowData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	special_cd = float(boss_def["first_special"])
	changed = false
	high_water = false
	_base_speed = move_speed
	for id: String in MerrowData.SPECIALS:
		_special_cds[id] = 0.0


## His specials in report order (Boss hook).
func special_ids() -> Array:
	return MerrowData.SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of his art (engine-motion pivot): robed or changed.
func motion_sprite_key() -> String:
	return "bosses/merrow_changed" if changed else "bosses/merrow"


## Picks the next special when ready; otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	match _choose_special():
		"sermon":
			_start_sermon()
		"wave":
			_start_wave()
		"lash":
			_start_lash()
		"whirl":
			_start_whirl()


## Weighted choice among his form's specials that are ready and usable now
## ("" when none is).
func _choose_special() -> String:
	var d := position.distance_to(game.player.position)
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id: String in (MerrowData.CHANGED_SPECIALS if changed else MerrowData.ROBED_SPECIALS):
		if float(_special_cds[id]) > 0.0 or not _usable(id, d):
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


## Whether special `id` makes sense with the necromancer `d` px away.
func _usable(id: String, d: float) -> bool:
	match id:
		"wave":
			return d <= float(boss_def["wave_range"])
		"lash":
			return d <= float(boss_def["lash_range"])
		"whirl":
			return d <= float(boss_def["whirl_range"])
	return true


## Boss physics: inherited walk / melee while walking, otherwise specials.
func physics_step(delta: float) -> void:
	phase_time += delta
	for id: String in MerrowData.SPECIALS:
		_special_cds[id] = float(_special_cds[id]) - delta
	knockback = Vector2.ZERO
	if not changed and phase != Phase.CHANGE and hp <= max_hp * float(boss_def["change_hp"]):
		_start_change()
	if not high_water and hp <= max_hp * float(boss_def["high_water_hp"]):
		_call_high_water()
	match phase:
		Phase.WALK:
			special_cd -= delta
			var spd := _base_speed
			if position.distance_to(game.player.position) > float(boss_def["advance_range"]):
				spd *= float(boss_def["advance_speed_mult"])
				game.stat_add("boss_advance_time", delta)
			move_speed = spd
			super.physics_step(delta)
		Phase.SERMON:
			_hold(delta)
			_step_sermon(delta)
		Phase.WAVE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["wave_telegraph"]):
				_resolve_wave()
				_set_phase(Phase.RECOVER)
		Phase.CHANGE:
			_hold(delta)
			if phase_time >= float(boss_def["change_time"]):
				_end_change()
				_set_phase(Phase.WALK)
		Phase.LASH_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["lash_telegraph"]):
				_resolve_lash()
				_set_phase(Phase.RECOVER)
		Phase.WHIRL_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["whirl_telegraph"]):
				_resolve_whirl()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_end_special()
				_set_phase(Phase.WALK)


## Standing still during a windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	if p == Phase.RECOVER and game != null:
		motion_lunge(game.player.position - position, MotionData.POWER_MELEE)  # Engine motion: the strike lands.
	queue_redraw()


## Starts special `id`: bookkeeping shared by every special.
func _begin_special(id: String, next_phase: Phase) -> void:
	_last_special = id
	_special_cds[id] = float(boss_def[id + "_cooldown"])
	game.stat_add("boss_atk_" + id, 1.0)
	_set_phase(next_phase)


## Sets the gap before the next special (shorter after High Water).
func _end_special() -> void:
	var gap := float(boss_def["attack_gap"])
	if high_water:
		gap *= float(boss_def["high_water_gap_mult"])
	special_cd = gap


## Direction to the necromancer (unit).
func _to_player() -> Vector2:
	var to_p := game.player.position - position
	return to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT


# =====================================================================================
# Sermon
# =====================================================================================

## Sermon: he climbs his pulpit and preaches.
func _start_sermon() -> void:
	_sermon_hp = hp
	_pulse_cd = 0.0
	game.effects.ring(position, float(boss_def["sermon_radius"]), Palette.EYE_BIOLUME, 0.8)
	game.enemies.show_banner("Abbot Merrow preaches: the congregation rallies! Strike him to break the sermon!")
	Sfx.play("toll", position, 0.6)
	_begin_special("sermon", Phase.SERMON)


## Buff pulses while he preaches; enough damage (or its end) stops it.
func _step_sermon(delta: float) -> void:
	_pulse_cd -= delta
	if _pulse_cd <= 0.0:
		_pulse_cd = float(boss_def["sermon_pulse"])
		_sermon_pulse()
	if _sermon_hp - hp >= max_hp * float(boss_def["sermon_break"]):
		game.stat_add("merrow_sermons_broken", 1.0)
		game.enemies.show_banner("The sermon is broken!")
		game.effects.impact(position, radius * 2.0, Palette.BONE)
		_set_phase(Phase.RECOVER)
	elif phase_time >= float(boss_def["sermon_duration"]):
		_set_phase(Phase.RECOVER)


## One sermon pulse: every cultist within sermon_radius (the necromancer's
## enemies, not structures or the Reckoning) gets the sermon buff, the
## strongest of overlapping buffs kept (Enemy._pulse_aura()'s rule).
func _sermon_pulse() -> void:
	var r := float(boss_def["sermon_radius"])
	var dm := float(boss_def["sermon_damage_mult"])
	var sm := float(boss_def["sermon_speed_mult"])
	var tm := float(boss_def["sermon_taken_mult"])
	game.enemy_grid.query(position, r, _tmp)
	var n := 0  # Cultists refreshed.
	for e: Enemy in _tmp:
		if e == self or not e.active or e.is_structure or e.is_reckoning or e.position.distance_to(position) > r:
			continue
		if e.buff_time <= 0.0:
			e.buff_damage = dm
			e.buff_speed = sm
			e.buff_taken = tm
			e.queue_redraw()
		else:
			e.buff_damage = maxf(e.buff_damage, dm)
			e.buff_speed = maxf(e.buff_speed, sm)
			e.buff_taken = minf(e.buff_taken, tm)
		e.buff_time = maxf(e.buff_time, float(boss_def["sermon_linger"]))
		n += 1
	game.stat_add("merrow_sermon_pulses", float(n))


# =====================================================================================
# Brine Wave
# =====================================================================================

## Brine Wave: a cone toward the necromancer.
func _start_wave() -> void:
	aim = _to_player()
	game.effects.telegraph_cone(position, aim, float(boss_def["wave_radius"]), float(boss_def["wave_half_angle"]), float(boss_def["wave_telegraph"]), self)
	_begin_special("wave", Phase.WAVE_WINDUP)


## The wave breaks: summons in the cone are thrown back and hurt.
func _resolve_wave() -> void:
	var r := float(boss_def["wave_radius"])
	var half := float(boss_def["wave_half_angle"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.impact(position + aim * r * 0.55, r * 0.5, Palette.EYE_DROWNED)
	Sfx.play("catapult_impact", position, 0.7)
	game.shake(6.0)
	var hits := 0
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not CovenantKit.in_sector(position, aim, r, half, radius, u.position, u.radius):
			continue
		hits += 1
		var away := u.position - position
		u.position += (away.normalized() if away.length() > 0.5 else aim) * float(boss_def["wave_push"])
		game.combat.damage_unit(u, float(boss_def["wave_damage_summon"]) * mult, "merrow_wave")
	game.stat_add("merrow_wave_hits", float(hits))
	var p := game.player
	if CovenantKit.in_sector(position, aim, r, half, radius, p.position, p.radius):
		game.combat.damage_player(float(boss_def["wave_damage_player"]) * mult, "merrow_wave")


# =====================================================================================
# The Change
# =====================================================================================

## The Change: he stands, shedding his robes.
func _start_change() -> void:
	game.enemies.show_banner(String(boss_def["change_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.EYE_BIOLUME)
	Sfx.play("boss_arrive", position, 0.8)
	game.stat_add("merrow_change_at", game.elapsed)
	_set_phase(Phase.CHANGE)


## Changed: faster, quicker blows, the limb specials.
func _end_change() -> void:
	changed = true
	_base_speed *= float(boss_def["change_speed_mult"])
	attack_interval = float(boss_def["attack_interval"]) * float(boss_def["change_attack_mult"])
	special_cd = 0.6
	if motion != null:
		motion.reset(UnitMotion.feet_of(motion_sprite_key(), "", radius), radius, MotionData.BOSS_SCALE, false)
	queue_redraw()


## High Water: the tide comes in early; his specials come faster.
func _call_high_water() -> void:
	high_water = true
	game.stat_add("merrow_high_water_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["high_water_banner"]))
	if game.enemies.tide != null:
		game.enemies.tide.start_high_water("merrow")


# =====================================================================================
# Limb Lash and Whirl
# =====================================================================================

## Direction of lash lane `i` (fanned around `aim`).
func _lash_dir(i: int) -> Vector2:
	var n := int(boss_def["lash_count"])
	return aim.rotated((float(i) - float(n - 1) * 0.5) * float(boss_def["lash_spread"]))


## Limb Lash: lanes fanned at the necromancer.
func _start_lash() -> void:
	aim = _to_player()
	var length := float(boss_def["lash_length"])
	for i in int(boss_def["lash_count"]):
		var dir := _lash_dir(i)
		game.effects.telegraph_line(position, position + dir * length, float(boss_def["lash_width"]), float(boss_def["lash_telegraph"]), self)
	_begin_special("lash", Phase.LASH_WINDUP)


## The limbs crack down the lanes: the first body in each lane is struck.
func _resolve_lash() -> void:
	var length := float(boss_def["lash_length"])
	var half_w := float(boss_def["lash_width"]) * 0.5
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	Sfx.play("rogue_dash", position, 0.6)
	var hit_player := false  # The necromancer is struck at most once.
	for i in int(boss_def["lash_count"]):
		var dir := _lash_dir(i)
		game.effects.slash(position + dir * length * 0.5, dir, Palette.EYE_DROWNED, length * 0.5)
		var best: SummonedUnit = null  # First summon down this lane.
		var best_along := INF
		game.ally_grid.query(position + dir * length * 0.5, length * 0.5 + half_w + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.state == SummonedUnit.State.SPAWNING:
				continue
			var rel := u.position - position
			var along := rel.dot(dir)
			if along < 0.0 or along > length + u.radius or absf(rel.cross(dir)) > half_w + u.radius:
				continue
			if along < best_along:
				best_along = along
				best = u
		var p := game.player
		var prel := p.position - position
		var p_along := prel.dot(dir)
		var p_in := p_along >= 0.0 and p_along <= length + p.radius and absf(prel.cross(dir)) <= half_w + p.radius
		if p_in and not hit_player and p_along < best_along:
			hit_player = true
			game.combat.damage_player(float(boss_def["lash_damage_player"]) * mult, "merrow_lash")
		elif best != null:
			game.combat.damage_unit(best, float(boss_def["lash_damage_summon"]) * mult, "merrow_lash")
			game.stat_add("merrow_lash_hits", 1.0)


## Whirl: a circle around him.
func _start_whirl() -> void:
	game.effects.telegraph_circle(position, float(boss_def["whirl_radius"]), float(boss_def["whirl_telegraph"]), self)
	_begin_special("whirl", Phase.WHIRL_WINDUP)


## The limbs whirl: summons inside are hurt and thrown out; the necromancer hit.
func _resolve_whirl() -> void:
	var r := float(boss_def["whirl_radius"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.impact(position, r, Palette.EYE_DROWNED)
	Sfx.play("abom_stomp", position, 0.8)
	game.shake(6.0)
	var hits := 0
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(position) > r + u.radius:
			continue
		hits += 1
		var away := u.position - position
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(boss_def["whirl_knockback"])
		game.combat.damage_unit(u, float(boss_def["whirl_damage_summon"]) * mult, "merrow_whirl")
	game.stat_add("merrow_whirl_hits", float(hits))
	var p := game.player
	if p.position.distance_to(position) <= r + p.radius:
		game.combat.damage_player(float(boss_def["whirl_damage_player"]) * mult, "merrow_whirl")


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: away from the cone / circle / lanes.
func danger_push(p: Vector2) -> Vector2:
	var away := p - position
	var out := away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	match phase:
		Phase.WAVE_WINDUP:
			if CovenantKit.in_sector(position, aim, float(boss_def["wave_radius"]) + 30.0, float(boss_def["wave_half_angle"]) + 0.2, radius, p, 12.0):
				return out
		Phase.WHIRL_WINDUP:
			if away.length() < float(boss_def["whirl_radius"]) + 30.0:
				return out
		Phase.LASH_WINDUP:
			if away.length() < float(boss_def["lash_length"]) + 30.0:
				return Vector2(-aim.y, aim.x)
	return Vector2.ZERO


## Ground layer: the pulpit and the sermon's rings while he preaches.
func _draw_under() -> void:
	if phase == Phase.SERMON:
		var k := fmod(phase_time, 1.0)
		draw_arc(Vector2.ZERO, radius * (1.5 + 3.0 * k), 0.0, TAU, 32, Color(Palette.EYE_BIOLUME, 0.5 * (1.0 - k)), 2.0)
		draw_rect(Rect2(Vector2(-radius * 0.9, radius * 0.2), Vector2(radius * 1.8, radius * 0.8)), HarbourGlyphs.WOOD_DARK)  # The pulpit.
		draw_rect(Rect2(Vector2(-radius * 0.8, radius * 0.25), Vector2(radius * 1.6, radius * 0.25)), HarbourGlyphs.WOOD)


## Body layer on `ci`: robed or changed, in the pose of his phase
## (BossPoseData: 1 preaching / winding up, 2 transforming, 3 striking).
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.SERMON, Phase.WAVE_WINDUP, Phase.LASH_WINDUP, Phase.WHIRL_WINDUP:
			pose = 1
		Phase.CHANGE:
			pose = 2
		Phase.RECOVER:
			pose = 3
	var key := "bosses/merrow_changed" if changed else "bosses/merrow"
	if phase == Phase.CHANGE:
		ci.draw_circle(Vector2.ZERO, radius * 1.8, Color(Palette.EYE_BIOLUME, 0.18))
	if SpriteBank.draw_pose(ci, key, pose, Vector2.ZERO, flash > 0.0):
		return
	HarbourGlyphs.draw_merrow(ci, Vector2.ZERO, radius, flash > 0.0, pose, changed)


## Overlay layer on `ci`: the aura chevron and the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if buff_time > 0.0:
		MarchGlyphs.draw_buffed(ci, Vector2(0, -radius * 2.0), 5.0)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var change := float(st.get("merrow_change_at", -1.0))
	var hw := float(st.get("merrow_high_water_at", -1.0))
	return "sermons %d (cultists buffed %d pulses, broken %d) | brine waves %d (summon hits %d) | the change %s | limb lashes %d (summon hits %d) | whirls %d (summon hits %d) | high water %s | dmg to player %d, summons %d" % [
		int(st.get("boss_atk_sermon", 0.0)), int(st.get("merrow_sermon_pulses", 0.0)), int(st.get("merrow_sermons_broken", 0.0)),
		int(st.get("boss_atk_wave", 0.0)), int(st.get("merrow_wave_hits", 0.0)),
		("at %d:%02d" % [floori(change / 60.0), int(change) % 60]) if change >= 0.0 else "no",
		int(st.get("boss_atk_lash", 0.0)), int(st.get("merrow_lash_hits", 0.0)),
		int(st.get("boss_atk_whirl", 0.0)), int(st.get("merrow_whirl_hits", 0.0)),
		("at %d:%02d" % [floori(hw / 60.0), int(hw) % 60]) if hw >= 0.0 else "no",
		int(st.get("player_dmg_from_merrow_wave", 0.0) + st.get("player_dmg_from_merrow_lash", 0.0) + st.get("player_dmg_from_merrow_whirl", 0.0) + st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_merrow_wave", 0.0) + st.get("summon_dmg_from_merrow_lash", 0.0) + st.get("summon_dmg_from_merrow_whirl", 0.0) + st.get("summon_dmg_from_boss", 0.0))]
