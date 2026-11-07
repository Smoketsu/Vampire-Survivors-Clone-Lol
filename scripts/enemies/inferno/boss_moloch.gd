## BossMoloch — MOLOCH, THE FURNACE KING, the boss of the Burning Gate (Act VI,
## Stage 16; GDD §15.0 "Moloch, the Furnace King (Act VI)"; owner-approved
## proposal: "a colossal bull-headed demon with a furnace for a belly. He
## swallows summons (they come back burning, as his for 6 s), vents fire waves,
## and cracks the arena into pits"). Loaded by name for the boss id "moloch"
## (EnemyDirector.INFERNO_BOSS_DIR + "boss_moloch.gd"); he arrives at 17:00 (3:00
## left). Extends Boss, so summons, spells and the spatial hash treat him like
## any enemy. Every ability is telegraphed; numbers in MolochData.BOSS. Three
## phases by his HP (the Furnace King, the Furnace Opens, the Molten King):
##   * THE SWALLOW: the furnace door in his belly opens and he inhales (a cone
##     in front of him, swallow_windup s); up to swallow_max summons still in
##     it are dragged into the furnace and come back BURNING, as his, for
##     swallow_time s. That is Temptation's ONE path (HordeDirector.charm(),
##     through InfernoKit.try_charm()) with opts ignore_cap (his swallow is not
##     a succubus's kiss and does not count against her cap), a furnace-orange
##     tint, the name "Burning <class>" and the source tag moloch_swallow: the
##     summon is parked and a hostile body wearing it steps out of his belly;
##     breaking the body frees it (Temptation), and his death breaks every
##     swallow (deactivate() -> HordeDirector.break_charms()). An enemy effect
##     on a unit: no summon has an act rule.
##   * THE FIRE WAVE: wave_count lanes toward the necromancer glow for
##     wave_telegraph s, then a wall of fire runs down each at wave_speed px/s;
##     every necromancer and summon it passes is hit once (OlympusHits.lane(),
##     the shared lane hit: CombatResolver underneath).
##   * THE CRACK: he stamps (crack_windup s) and the ground splits into Hell
##     Pits around the necromancer (HellPits.open_pit(), the one pit path, tag
##     "moloch"; each pit glows its own 1.5 s before it burns). On a stage
##     without the Inferno's pits (--boss=moloch elsewhere) the cracks open
##     nothing that burns (HellPits only burns on an Act VI stage).
##   * THE MOLTEN KING (below phase3_hp): faster, harder blows, and a molten
##     footprint (a small pit) where he walks every footprint_every s.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Brimstone spell and Furnace Heart (UnlockData, boss "moloch"); with enough
## portals sealed it earns Gate Crashed (BurningGateDirector). Attack pose
## (BossPoseData, when the art has one): pose 1 while he inhales or stamps.
## Determinism: the seeded global RNG only (where the cracks split). Stats:
## boss_atk_<special>, moloch_swallowed, moloch_swallow_empty, moloch_wave_hits,
## moloch_crack_pits, moloch_footprints, moloch_phase2_at, moloch_phase3_at.
class_name BossMoloch
extends Boss

## Boss action phases.
enum Phase { WALK, SWALLOW, WAVE_WINDUP, CRACK_WINDUP, RECOVER }

## One fire wave running down its lane.
class Wave:
	extends RefCounted
	## World point the wave starts from (his centre when it was vented).
	var from: Vector2 = Vector2.ZERO
	## Unit direction of the lane.
	var dir: Vector2 = Vector2.RIGHT
	## Px the front has run (0 .. wave_length).
	var front: float = 0.0
	## Bodies this wave already struck (OlympusHits.lane()).
	var struck: Dictionary = {}

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His form: 1 the Furnace King, 2 the Furnace Opens, 3 the Molten King.
var form: int = 1
## Seconds until his next swallow.
var swallow_cd: float = 0.0
## Seconds until his next fire wave.
var wave_cd: float = 0.0
## Seconds until his next crack.
var crack_cd: float = 0.0
## Seconds until his next molten footprint (the Molten King).
var foot_cd: float = 0.0
## Unit direction of the current inhale (locked at its start).
var _face: Vector2 = Vector2.RIGHT
## Unit directions of the telegraphed wave lanes (locked at the windup).
var _lanes: Array[Vector2] = []
## Fire waves running now.
var _waves: Array[Wave] = []
## Move speed of his current form (px/s).
var _base_speed: float = 44.0


## Sets up Moloch at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MolochData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	swallow_cd = float(boss_def["first_swallow"])
	wave_cd = float(boss_def["first_wave"])
	crack_cd = float(boss_def["first_crack"])
	foot_cd = 0.0
	_lanes.clear()
	_waves.clear()
	_base_speed = move_speed
	game.inferno_rules()  # His swallow and cracks use the Inferno's paths (created on another stage too, --boss=moloch).


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return MolochData.SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## His death (or any removal) breaks every swallow: the summons come back.
func deactivate() -> void:
	if active and game != null and game.horde != null:
		var n := game.horde.break_charms(self)  # Temptation's one path (every army).
		game.stat_add("moloch_swallow_freed_by_death", float(n))
	_waves.clear()
	super.deactivate()


## Boss physics: his phase machine (see the header); the waves run on.
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	swallow_cd -= delta
	wave_cd -= delta
	crack_cd -= delta
	_step_waves(delta)
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		form = 2
		game.stat_add("moloch_phase2_at", game.elapsed)
		game.enemies.show_banner(String(boss_def["phase2_banner"]))
		game.effects.impact(position, radius * 3.0, Palette.INFERNO_LAVA)
		game.inferno_rules().play_sound("moloch_roar", position)
		swallow_cd = minf(swallow_cd, 1.5)
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		form = 3
		game.stat_add("moloch_phase3_at", game.elapsed)
		game.stat_add("boss_atk_molten", 1.0)
		game.enemies.show_banner(String(boss_def["phase3_banner"]))
		game.effects.impact(position, radius * 3.5, Palette.INFERNO_LAVA_LIGHT)
		game.shake(8.0)
		_base_speed = float(boss_def["molten_speed"])
		damage = float(boss_def["molten_damage"])
		crack_cd = minf(crack_cd, 2.0)
	if form == 3:
		foot_cd -= delta
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.SWALLOW:
			_hold(delta)
			if phase_time >= float(boss_def["swallow_windup"]):
				_swallow()
				_set_phase(Phase.RECOVER)
		Phase.WAVE_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["wave_telegraph"]):
				_vent()
				_set_phase(Phase.RECOVER)
		Phase.CRACK_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["crack_windup"]):
				_crack()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Walking: the shared walk and melee, striding faster when far; the molten
## footprints; a swallow, a wave or a crack start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if form == 3 and foot_cd <= 0.0:
		foot_cd = float(boss_def["footprint_every"])
		if _pits().open_pit(position, float(boss_def["footprint_radius"]), float(boss_def["footprint_life"]),
				{"tag": MolochData.CRACK_TAG, "telegraph": 0.6, "silent": true}):
			game.stat_add("moloch_footprints", 1.0)
	if swallow_cd <= 0.0 and _swallow_ready():
		_start_swallow()
	elif wave_cd <= 0.0 and dist <= float(boss_def["wave_length"]):
		_start_wave()
	elif crack_cd <= 0.0:
		_start_crack()


## Standing still during a windup or recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## The Hell Pits (created with the Inferno's rules on first use).
func _pits() -> HellPits:
	return game.inferno_rules().pits


# =====================================================================================
# The swallow (Temptation's one charm path)
# =====================================================================================

## True when enough summons stand in front of him to bother (or the
## necromancer is in reach, so the army comes to him).
func _swallow_ready() -> bool:
	var reach := float(boss_def["swallow_reach"])
	if position.distance_to(game.player.position) <= reach + game.player.radius:
		return true
	return OlympusHits.summons_near(game, position, reach, _tmp) >= int(boss_def["swallow_trigger"])


## The furnace door opens: he inhales toward the necromancer (the cone shows).
func _start_swallow() -> void:
	swallow_cd = float(boss_def["swallow_cooldown"] if form == 1 else boss_def["swallow_cooldown_p2"])
	var to := game.player.position - position
	_face = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	game.effects.telegraph_cone(position, _face, float(boss_def["swallow_reach"]), float(boss_def["swallow_arc"]),
			float(boss_def["swallow_windup"]), self)
	motion_lunge(-_face, MotionData.POWER_CAST)
	game.stat_add("boss_atk_swallow", 1.0)
	game.inferno_rules().play_sound("moloch_roar", position)
	_set_phase(Phase.SWALLOW)


## The inhale ends: the nearest summons still in the cone are swallowed and
## come back burning, as his (HordeDirector.charm() through try_charm()).
func _swallow() -> void:
	var reach := float(boss_def["swallow_reach"])
	var arc := float(boss_def["swallow_arc"])
	var most := int(boss_def["swallow_max"] if form == 1 else boss_def["swallow_max_p2"])
	var picks: Array[SummonedUnit] = []
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if CovenantKit.in_sector(position, _face, reach, arc, radius, u.position, u.radius):
			picks.append(u)
	picks.sort_custom(func(a: SummonedUnit, b: SummonedUnit) -> bool: return a.position.distance_squared_to(position) < b.position.distance_squared_to(position))
	var belly := position + _face * radius * 0.7  # The furnace door: the bodies step out here.
	var n := 0
	for u in picks:
		if n >= most:
			break
		var back := u.position
		u.position = belly  # Dragged into the furnace: its burning body steps out of his belly.
		var cls_name := String(UnitData.UNITS[u.unit_class].get("display_name", u.unit_class))
		if InfernoKit.try_charm(self, u, float(boss_def["swallow_time"]), {"ignore_cap": true, "tint": MolochData.SWALLOW_TINT,
				"name": "Burning " + cls_name, "source": MolochData.SWALLOW_SOURCE}):
			n += 1
		else:
			u.position = back
	game.stat_add("moloch_swallowed", float(n))
	if n == 0:
		game.stat_add("moloch_swallow_empty", 1.0)
	game.effects.impact(belly, radius * 1.5, Palette.INFERNO_LAVA_LIGHT)
	game.shake(4.0)


# =====================================================================================
# The fire waves
# =====================================================================================

## Locks the wave lanes toward the necromancer and telegraphs them.
func _start_wave() -> void:
	wave_cd = float(boss_def["wave_cooldown_p3"] if form == 3 else boss_def["wave_cooldown"])
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_lanes.clear()
	var n := int(boss_def["wave_count"] if form == 1 else boss_def["wave_count_p2"])
	for i in n:
		_lanes.append(dir.rotated((float(i) - float(n - 1) * 0.5) * float(boss_def["wave_spread"])))
	for l in _lanes:
		game.effects.telegraph_line(position, position + l * float(boss_def["wave_length"]), float(boss_def["wave_width"]),
				float(boss_def["wave_telegraph"]), self)
	motion_lunge(-dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_fire_wave", 1.0)
	_set_phase(Phase.WAVE_WINDUP)


## The furnace vents: a wall of fire starts down each lane.
func _vent() -> void:
	for l in _lanes:
		var w := Wave.new()
		w.from = position
		w.dir = l
		_waves.append(w)
	game.inferno_rules().play_sound("pit_open", position)
	game.effects.impact(position + _lanes[0] * radius, radius * 1.4, Palette.INFERNO_LAVA)
	game.shake(5.0)


## The running waves advance and hit what their front passes (once each).
func _step_waves(delta: float) -> void:
	if _waves.is_empty():
		return
	queue_redraw()
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var length := float(boss_def["wave_length"])
	var i := 0
	while i < _waves.size():
		var w := _waves[i]
		var from := w.front
		w.front = minf(length, w.front + float(boss_def["wave_speed"]) * delta)
		game.stat_add("moloch_wave_hits", float(OlympusHits.lane(game, w.from + w.dir * from, w.dir, w.front - from + 1.0,
				float(boss_def["wave_width"]), float(boss_def["wave_damage_player"]) * mult, float(boss_def["wave_damage_summon"]) * mult,
				MolochData.WAVE_SOURCE, self, w.struck, _tmp)))
		if w.front >= length:
			_waves.remove_at(i)
			continue
		i += 1


# =====================================================================================
# The crack (the Hell Pits' one path)
# =====================================================================================

## He raises a hoof.
func _start_crack() -> void:
	crack_cd = float(boss_def["crack_cooldown"])
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_crack", 1.0)
	_set_phase(Phase.CRACK_WINDUP)


## The stamp: the ground splits into pits around the necromancer (seeded RNG).
func _crack() -> void:
	var n := int(boss_def["crack_count"] if form == 1 else boss_def["crack_count_p2"])
	var opened := 0
	var at0 := game.player.position
	var offset := randf() * TAU  # Angle of the first pit.
	for i in n:
		var a := offset + TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
		var d := randf_range(float(boss_def["crack_near"]), float(boss_def["crack_far"]))
		var r := randf_range(float(boss_def["crack_radius_min"]), float(boss_def["crack_radius_max"]))
		var at := game.arena.free_point(at0 + Vector2.from_angle(a) * d, r * 0.5)
		if _pits().open_pit(at, r, float(boss_def["crack_life"]), {"tag": MolochData.CRACK_TAG, "silent": i > 0}):
			opened += 1
	game.stat_add("moloch_crack_pits", float(opened))
	game.effects.impact(position, radius * 2.2, Palette.INFERNO_LAVA_DARK)
	game.inferno_rules().play_sound("brute_slam", position)
	game.shake(7.0)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: sideways out of a glowing or
## burning wave lane (the cracks' pits are the Hell Pits' own hint).
func danger_push(p: Vector2) -> Vector2:
	var lanes: Array = []  # [from, dir, from px, to px] of every live lane.
	if phase == Phase.WAVE_WINDUP:
		for l in _lanes:
			lanes.append([position, l, 0.0, float(boss_def["wave_length"])])
	for w in _waves:
		lanes.append([w.from, w.dir, w.front - 40.0, float(boss_def["wave_length"])])
	for lane in lanes:
		var from: Vector2 = lane[0]
		var dir: Vector2 = lane[1]
		var rel := p - from
		var along := rel.dot(dir)
		if along > float(lane[2]) - 20.0 and along < float(lane[3]) + 20.0:
			var side := rel - dir * along
			if side.length() < float(boss_def["wave_width"]) * 0.5 + 30.0:
				return side.normalized() * 2.0 if side.length() > 0.5 else dir.orthogonal() * 2.0
	return Vector2.ZERO


## Body layer on `ci`: his sprite in the pose of his phase (pose 1 while he
## inhales or stamps), the furnace glow in his belly, molten in phase 3.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.SWALLOW, Phase.CRACK_WINDUP, Phase.WAVE_WINDUP:
			pose = 1
	var glow := 0.25 + (0.35 if phase == Phase.SWALLOW or phase == Phase.WAVE_WINDUP else 0.0) + (0.2 if form == 3 else 0.0)
	SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.2), radius * 1.3, Color(Palette.INFERNO_LAVA, glow * 0.35))
	if not SpriteBank.draw_pose(ci, "bosses/moloch", pose, Vector2.ZERO, flash > 0.0):
		BurningGateGlyphs.draw_moloch(ci, Vector2.ZERO, radius, flash > 0.0, form == 3)
	if phase == Phase.SWALLOW:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["swallow_windup"])), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2(radius * 0.15, -radius * 0.25), radius * (0.3 + 0.25 * k), Color(Palette.INFERNO_LAVA_LIGHT, 0.6 + 0.3 * k))


## Overlay layer on `ci`: the running fire waves (disc textures along each
## front, in world axes from his centre; no polygon redrawn every frame).
func _draw_over(ci: CanvasItem) -> void:
	if not _waves.is_empty():
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # Undo his mirror: world axes.
		var half := float(boss_def["wave_width"]) * 0.5
		for w in _waves:
			var c := w.from + w.dir * w.front - position  # The front's centre (from his centre).
			var side := w.dir.orthogonal()
			for k in 5:
				var off := side * half * (float(k) / 2.0 - 1.0)
				SpriteBank.draw_disc(ci, c + off, half * 0.55, Color(Palette.INFERNO_LAVA, 0.75))
				SpriteBank.draw_disc(ci, c + off - w.dir * 6.0, half * 0.3, Color(Palette.INFERNO_LAVA_LIGHT, 0.85))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("moloch_phase2_at", -1.0))
	var p3 := float(st.get("moloch_phase3_at", -1.0))
	return "swallows %d (summons swallowed %d, empty %d; freed by his death %d) | fire waves %d (hits %d) | cracks %d (pits %d), molten footprints %d | furnace opens %s | molten king %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_swallow", 0.0)), int(st.get("moloch_swallowed", 0.0)), int(st.get("moloch_swallow_empty", 0.0)),
		int(st.get("moloch_swallow_freed_by_death", 0.0)),
		int(st.get("boss_atk_fire_wave", 0.0)), int(st.get("moloch_wave_hits", 0.0)),
		int(st.get("boss_atk_crack", 0.0)), int(st.get("moloch_crack_pits", 0.0)), int(st.get("moloch_footprints", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", EmpireReport._clock(p3) if p3 >= 0.0 else "not reached",
		int(st.get("player_dmg_from_" + MolochData.WAVE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + MolochData.WAVE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
