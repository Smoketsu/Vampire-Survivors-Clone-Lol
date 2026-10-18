## BossVhalneth — VHAL'NETH, THE DREAMING MOTHER, the final boss of Act II
## (Ul-Thalos, the Risen Spire; StageRegistry boss id "vhalneth", loaded by
## name by EnemyDirector from scripts/enemies/eye/boss_vhalneth.gd; any
## stage's boss slot can send her with the autotest's --boss=vhalneth). She
## arrives at 17:00 (3:00 left) like every boss. All numbers are in
## VhalnethData.BOSS.
## She is colossal and mostly off screen: this node is her FACE, out in the
## sea beside the island (SinkingDirector exempts it from the shore; on a stage
## without the sinking, a fallback "shore" circle around her arrival point),
## and the army fights her ARMS (SpireEnemyData "vhalneth_arm", ArmKit:
## structures rising at the shore that slam telegraphed lanes). She never
## walks: she glides along the coast toward the necromancer's bearing.
##   Dreaming: the face lies under the water (untargetable: out of the enemy
##     grid, no damage), eyes shut. dream_arms_base arms plus one per dream
##     pillar still standing (SpireDirector.standing_pillars(); like
##     Seraphine's attendants) rise around the island. Severing an arm wounds
##     her (dream_wound_share split between them); the last one ends the phase.
##   Stirring (70%): the face surfaces just beyond the shore, in reach; her
##     eyes open and her GAZE rests on the island (VhalnethHazards): Dread
##     climbs fast inside it, so the army has to move. Two arms slam and regrow.
##   Waking (35%): the face rises onto the shore and becomes the weak point
##     (waking_damage_taken), ringed by four arms; she roars (a nova around the
##     face) and gazes more often.
## A phase change takes phase_time s: she is invulnerable and her arms hold.
## Killing her plays the finale: the necromancer raises her and the Eye's
## own ritual binds her to him (the ending text, VhalnethData); the normal
## boss reward fires (EnemyDirector: XP burst; ChestManager: chest). Her arms
## sink with her. The Waking (the stage's Reckoning) still begins at 0:00.
## Stats: vhalneth_spawn_time, vhalneth_stirring_time, vhalneth_waking_time,
## vhalneth_kill_time, vhalneth_dream_arms, vhalneth_pillars_standing,
## vhalneth_arms_raised, vhalneth_arms_severed, bossdmg_severed_arm (the wounds),
## boss_atk_<id> (VhalnethData.SPECIALS).
class_name BossVhalneth
extends Boss

## Fight phases.
enum Phase { RISING, DREAMING, CHANGING, STIRRING, WAKING }

## Damage source tag of an arm's wound to her (CombatResolver-style stats).
const WOUND_SOURCE: String = "severed_arm"

## Current fight phase.
var phase: Phase = Phase.RISING
## Seconds in the current phase.
var phase_time: float = 0.0
## The phase a CHANGING step leads into.
var _next_phase: Phase = Phase.STIRRING
## Index of the fight phase for the slam pace (0 Dreaming, 1 Stirring, 2 Waking).
var pace_index: int = 0
## Her world-hazards layer (gaze, roar, finale).
var hazards: VhalnethHazards = null
## The island's centre (world px).
var shore_center: Vector2 = Vector2.ZERO
## Angle (rad) of her position around the island.
var shore_angle: float = 0.0
## Living arms: each [Enemy, generation, role ("dream" / "later"), slot angle or ring angle].
var _arms: Array = []
## Severed later arms waiting to regrow: [game time, role, slot angle].
var _regrow: Array = []
## Arms of the Dreaming phase (fixed at her arrival).
var dream_arm_count: int = 0
## Seconds until her next gaze (Stirring, Waking).
var _gaze_cd: float = 0.0
## Seconds until her next roar (Waking).
var _roar_cd: float = 0.0
## Game time she arrived.
var _spawn_time: float = 0.0


## Sets up Vhal'Neth with HP scaled by `hp_mult`: her face takes its place
## out in the sea nearest the necromancer, her Dreaming arms rise, and her
## hazards layer is created.
func setup_boss(p_game: Game, _pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = VhalnethData.BOSS
	game = p_game
	var sink := p_game.enemies.sinking
	shore_center = sink.center if sink != null else p_game.player.position
	var to_p := p_game.player.position - shore_center
	shore_angle = to_p.angle() if to_p.length() > 1.0 else 0.0
	activate(p_game, "boss", boss_def, _coast_point(float(boss_def["submerged_offset"])), hp_mult, false, slot)
	is_boss = true
	untargetable = true
	z_index = -5  # Under the water's surface: over the sea, under the obstacles and bodies.
	phase = Phase.RISING
	phase_time = 0.0
	pace_index = 0
	_spawn_time = game.elapsed
	game.stats["vhalneth_spawn_time"] = game.elapsed
	hazards = VhalnethHazards.new()
	game.enemies.add_child(hazards)
	hazards.setup(game, self)
	game.enemies.boss_defeated.connect(_on_defeated)
	var pillars := game.enemies.spire.standing_pillars() if game.enemies.spire != null else 0  # Dream pillars still standing.
	dream_arm_count = int(boss_def["dream_arms_base"]) + pillars
	game.stats["vhalneth_dream_arms"] = float(dream_arm_count)
	game.stats["vhalneth_pillars_standing"] = float(pillars)
	_raise_dream_arms()


## Her specials in report order (Boss hook).
func special_ids() -> Array:
	return VhalnethData.SPECIALS


## She never walks (Boss hook, stuck check).
func is_walking() -> bool:
	return false


## The slam pace of the current fight phase (ArmKit divides its interval by it).
func slam_pace() -> float:
	var pace: Array = boss_def["slam_pace"]
	return float(pace[clampi(pace_index, 0, pace.size() - 1)])


## True while she takes no damage: rising, dreaming under the sea, changing phase.
func invulnerable() -> bool:
	return phase == Phase.RISING or phase == Phase.DREAMING or phase == Phase.CHANGING


## The face is out of reach, or the weak point once it has risen.
func damage_taken_mult(source: String) -> float:
	if invulnerable():
		return 0.0
	var m := super.damage_taken_mult(source)
	if phase == Phase.WAKING:
		m *= float(boss_def["waking_damage_taken"])
	return m


# =====================================================================================
# The coast
# =====================================================================================

## Radius (px) of the island's shore now (the fallback circle without the sinking).
func _shore_radius() -> float:
	var sink := game.enemies.sinking if game != null else null
	return sink.radius if sink != null else float(boss_def["fallback_radius"])


## The coast point at her angle, `offset` px beyond the shoreline.
func _coast_point(offset: float) -> Vector2:
	return shore_center + Vector2.from_angle(shore_angle) * (_shore_radius() + offset)


## Her offset beyond the shore in the current phase (px).
func _offset() -> float:
	match phase:
		Phase.RISING, Phase.DREAMING:
			return float(boss_def["submerged_offset"])
		Phase.WAKING:
			return float(boss_def["waking_offset"])
		Phase.CHANGING:
			return float(boss_def["waking_offset"] if _next_phase == Phase.WAKING else boss_def["stirring_offset"])
	return float(boss_def["stirring_offset"])


## Glides along the coast toward the necromancer's bearing.
func _glide(delta: float) -> void:
	var to_p := game.player.position - shore_center
	if to_p.length() > 1.0:
		var speed := float(boss_def["waking_glide_speed"] if phase == Phase.WAKING else boss_def["glide_speed"])
		var want := to_p.angle()
		var diff := wrapf(want - shore_angle, -PI, PI)
		shore_angle += clampf(diff, -speed * delta, speed * delta)
	var goal := _coast_point(_offset())
	position = position.move_toward(goal, 80.0 * delta) if position.distance_to(goal) < 400.0 else goal
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO


# =====================================================================================
# Physics: phases, arms, gaze, roar
# =====================================================================================

## She picks no target (her arms and hazards are her attacks).
func think() -> void:
	targeting_player = false
	targeting_summon = false


func physics_step(delta: float) -> void:
	phase_time += delta
	_tick_timers(delta)
	_glide(delta)
	_step_arms()
	hazards.step(delta)
	queue_redraw()
	match phase:
		Phase.RISING:
			if phase_time >= float(boss_def["rise_time"]):
				_set_phase(Phase.DREAMING)
		Phase.DREAMING:
			if _arms_of("dream") == 0:
				_change_to(Phase.STIRRING)
		Phase.CHANGING:
			if phase_time >= float(boss_def["phase_time"]):
				_enter(_next_phase)
		Phase.STIRRING:
			_step_gaze(delta, float(boss_def["gaze_interval"]), float(boss_def["gaze_radius"]))
			if hp <= max_hp * float(boss_def["waking_hp_fraction"]):
				_change_to(Phase.WAKING)
		Phase.WAKING:
			_step_gaze(delta, float(boss_def["gaze_interval_waking"]), float(boss_def["gaze_radius_waking"]))
			_roar_cd -= delta
			if _roar_cd <= 0.0 and not hazards.roar_pending:
				_roar_cd = float(boss_def["roar_interval"])
				hazards.start_roar()


## Sets the fight phase (and the look) at once.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Starts the change into phase `p`: invulnerable, her arms hold, the banner.
func _change_to(p: Phase) -> void:
	_next_phase = p
	_set_phase(Phase.CHANGING)
	untargetable = false
	z_index = 0
	var until := game.elapsed + float(boss_def["phase_time"])
	for rec: Array in _arms:
		var a: Enemy = rec[0]
		if a.active and a.generation == int(rec[1]) and a.kit is ArmKit:
			(a.kit as ArmKit).hold_until(a, until)
	hazards.clear()
	if p == Phase.STIRRING:
		hp = minf(hp, max_hp * float(boss_def["stirring_hp_fraction"]))
		game.enemies.show_banner(String(boss_def["stirring_banner"]))
		game.stats["vhalneth_stirring_time"] = game.elapsed
		game.stat_add("boss_phase2", 1.0)
	else:
		game.enemies.show_banner(String(boss_def["waking_banner"]))
		game.stats["vhalneth_waking_time"] = game.elapsed
		game.stat_add("boss_phase3", 1.0)
	game.effects.impact(position, radius * 2.5, Palette.EYE_DROWNED)
	game.effects.ring(position, radius * 4.0, Palette.EYE_BIOLUME, float(boss_def["phase_time"]))
	game.shake(6.0)


## The phase change is over: phase `p` begins.
func _enter(p: Phase) -> void:
	_set_phase(p)
	if p == Phase.STIRRING:
		pace_index = 1
		_gaze_cd = float(boss_def["gaze_first"])
		for i in int(boss_def["stirring_arms"]):
			var a := shore_angle + (0.7 if i % 2 == 0 else -0.7) * (1.0 + float(i / 2))
			_raise_arm("later", a, false)
	else:
		pace_index = 2
		_gaze_cd = minf(_gaze_cd, float(boss_def["gaze_first"]))
		_roar_cd = float(boss_def["roar_first"])
		for i in int(boss_def["waking_arms"]):
			_raise_arm("ring", TAU * float(i) / float(int(boss_def["waking_arms"])) + PI * 0.25, false)


## Opens her gaze when it is due.
func _step_gaze(delta: float, interval: float, r: float) -> void:
	_gaze_cd -= delta
	if _gaze_cd <= 0.0 and not hazards.gaze_busy():
		_gaze_cd = interval
		hazards.start_gaze(r)


# =====================================================================================
# Her arms
# =====================================================================================

## The Dreaming arms: spread around the island, the first one nearest the
## necromancer's side.
func _raise_dream_arms() -> void:
	var n := dream_arm_count
	for i in n:
		_raise_arm("dream", shore_angle + TAU * float(i) / float(maxi(1, n)) + 0.35, true)


## Raises one arm (`role` "dream", "later" or "ring") at coast angle `a`
## ("ring": around her face at waking_ring_radius px instead).
func _raise_arm(role: String, a: float, dream: bool) -> void:
	var kind := SpireEnemyData.ARM
	var r := float(game.enemies.enemy_def(kind)["radius"])
	var at: Vector2
	var sink := game.enemies.sinking  # The island (null without the sinking).
	var inset := float(sink.config["spawn_inset"]) + 4.0 if sink != null else 0.0  # Just inside where cultists climb out of the sea.
	if role == "ring":
		at = position + Vector2.from_angle(a) * float(boss_def["waking_ring_radius"])
		if sink != null:
			at = sink.clamp_point(at, maxf(r, inset))  # Onto the shore, beside her face.
	else:
		at = shore_center + Vector2.from_angle(a) * maxf(60.0, _shore_radius() - maxf(r, inset))
	var e := game.enemies.spawn_at(kind, at, false)
	e.is_objective = true
	e.max_hp = max_hp * float(boss_def["dream_arm_hp" if dream else "later_arm_hp"])
	e.hp = e.max_hp
	e.queue_redraw()
	_arms.append([e, e.generation, role if dream else "later" if role != "ring" else "ring", a])
	game.effects.impact(e.position, 46.0, Palette.EYE_DROWNED)
	game.stat_add("vhalneth_arms_raised", 1.0)
	game.stat_add("boss_atk_arms", 1.0)


## Severed arms wound her; later arms regrow after arm_regrow s.
func _step_arms() -> void:
	var i := _arms.size() - 1
	while i >= 0:
		var rec: Array = _arms[i]
		var a: Enemy = rec[0]
		if not a.active or a.generation != int(rec[1]):
			_arms.remove_at(i)
			_on_arm_severed(a, String(rec[2]), float(rec[3]))
		i -= 1
	if _regrow.is_empty() or phase == Phase.CHANGING:
		return
	var j := _regrow.size() - 1
	while j >= 0:
		var g: Array = _regrow[j]
		if game.elapsed >= float(g[0]):
			_regrow.remove_at(j)
			_raise_arm(String(g[1]), float(g[2]), false)
		j -= 1


## An arm was severed: she takes its wound (never the last blow: that is
## the face's), and a later arm is scheduled to regrow.
func _on_arm_severed(a: Enemy, role: String, slot: float) -> void:
	var wound := 0.0  # HP the severing takes off her.
	if role == "dream":
		wound = max_hp * float(boss_def["dream_wound_share"]) / float(maxi(1, dream_arm_count))
	else:
		wound = a.max_hp * float(boss_def["later_wound"])
		_regrow.append([game.elapsed + float(boss_def["arm_regrow"]), role, slot])
	wound = minf(wound, maxf(0.0, hp - 1.0))
	hp -= wound
	on_hit()
	game.stat_add("vhalneth_arms_severed", 1.0)
	game.stat_add("bossdmg_" + WOUND_SOURCE, wound)
	game.effects.impact(a.position, 60.0, Palette.EYE_BIOLUME)
	game.enemies.show_banner("An arm of Vhal'Neth is severed!")


## Living arms of `role`.
func _arms_of(role: String) -> int:
	var n := 0
	for rec: Array in _arms:
		var a: Enemy = rec[0]
		if String(rec[2]) == role and a.active and a.generation == int(rec[1]):
			n += 1
	return n


## The nearest living arm to `p` (Vector2.INF when none): the autopilot's goal.
func nearest_arm(p: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_d := INF
	for rec: Array in _arms:
		var a: Enemy = rec[0]
		if a.active and a.generation == int(rec[1]):
			var d := p.distance_to(a.position)
			if d < best_d:
				best_d = d
				best = a.position
	return best


## Where the autopilot should fight: her nearest arm while she dreams, her
## face once it is in reach (the nearer of the two after that).
func approach_point(p: Vector2) -> Vector2:
	var arm := nearest_arm(p)
	if invulnerable() or phase == Phase.RISING:
		return arm
	var face := shore_center + (position - shore_center).normalized() * (_shore_radius() - 60.0)
	if arm == Vector2.INF or p.distance_to(face) < p.distance_to(arm):
		return face
	return arm


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her death (EnemyDirector.boss_defeated, after the reward burst): the
## hazards end, her arms sink with her, and the finale plays: the
## necromancer raises the dead god (the ending text, as the stage banner).
func _on_defeated() -> void:
	var pos := position
	hazards.start_finale(pos)
	for rec: Array in _arms:
		var a: Enemy = rec[0]
		if a.active and a.generation == int(rec[1]):
			game.effects.impact(a.position, 50.0, Palette.EYE_DROWNED)
			game.enemies.despawn(a)
	_arms.clear()
	_regrow.clear()
	game.effects.ring(pos, VhalnethData.BINDING_RADIUS, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, VhalnethData.BINDING_RADIUS * 0.6, Palette.EYE_BIOLUME, 0.8)
	Juice.fx.burst(pos, Palette.NECRO_GREEN, Palette.EYE_BIOLUME_GLOW, 24, 320.0, 1.0, 3.5)
	game.shake(12.0)
	var late := game.countdown_finished()  # She fell during the Waking.
	game.enemies.show_banner(String(VhalnethData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + VhalnethData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = VhalnethData.LATE_ANNOUNCE if late else VhalnethData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)
	game.stats["vhalneth_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: her gaze and roar.
func danger_push(p: Vector2) -> Vector2:
	return hazards.danger_push(p) if hazards != null else Vector2.ZERO


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/vhalneth"


## Ground layer: nothing under her (the sea is SinkingDirector's).
func _draw_under() -> void:
	pass


## Body layer on `ci`: her face in the look of the current phase.
func _draw_body(ci: CanvasItem) -> void:
	var look := 0  # 0 dreaming (eyes shut, under the water), 1 eyes open, 2 risen.
	match phase:
		Phase.STIRRING:
			look = 1
		Phase.WAKING:
			look = 2
		Phase.CHANGING:
			look = 2 if _next_phase == Phase.WAKING else 1
	var rise := clampf(phase_time / maxf(0.1, float(boss_def["rise_time"])), 0.0, 1.0) if phase == Phase.RISING else 1.0
	SpireGlyphs.draw_vhalneth(ci, Vector2.ZERO, radius, flash > 0.0, look, rise, game.elapsed if game != null else 0.0)


## Overlay layer on `ci`: the Stasis / Deep Freeze ice.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of her fight (phase times relative to her
## arrival, arms, the gaze, the roar, her damage).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("vhalneth_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	return "phases: stirring %s, waking %s, kill %s | dream arms %d (pillars standing %d) | arms raised %d, severed %d, wound dmg %d | slams %d (player hits %d, summon hits %d) | gazes %d (player in it %.1f s, summon ticks %d) | roars %d (player hits %d, summon hits %d) | dmg to player: slams %d, gaze %d, roar %d" % [
		rel.call("vhalneth_stirring_time"), rel.call("vhalneth_waking_time"),
		"%.1fs" % float(st["vhalneth_kill_time"]) if st.has("vhalneth_kill_time") else "-",
		int(st.get("vhalneth_dream_arms", 0.0)), int(st.get("vhalneth_pillars_standing", 0.0)),
		int(st.get("vhalneth_arms_raised", 0.0)), int(st.get("vhalneth_arms_severed", 0.0)), int(st.get("bossdmg_" + WOUND_SOURCE, 0.0)),
		int(st.get("boss_atk_slam", 0.0)), int(st.get("vhalneth_slam_player_hits", 0.0)), int(st.get("vhalneth_slam_summon_hits", 0.0)),
		int(st.get("boss_atk_gaze", 0.0)), float(st.get("vhalneth_gaze_player_seconds", 0.0)), int(st.get("vhalneth_gaze_summon_ticks", 0.0)),
		int(st.get("boss_atk_roar", 0.0)), int(st.get("vhalneth_roar_player_hits", 0.0)), int(st.get("vhalneth_roar_summon_hits", 0.0)),
		int(st.get("player_dmg_from_vhalneth_slam", 0.0)), int(st.get("player_dmg_from_vhalneth_gaze", 0.0)), int(st.get("player_dmg_from_vhalneth_roar", 0.0))]
