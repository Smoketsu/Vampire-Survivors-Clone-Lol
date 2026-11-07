## BossZeus — ZEUS, KING OF THE GODS, the boss of Mount Olympus, the Pantheon
## Trial (Act IV, Stage 11; GDD §15.0 "Zeus, King of the Gods"; owner-approved
## proposal: "Lightning storms, the thunderbolt beam, and in phase 3 he takes
## his true colossal form"). Loaded by name for the boss id "zeus"
## (EnemyDirector.PANTHEON_BOSS_DIR + "boss_zeus.gd"); he arrives at 17:00
## (3:00 left) at the summit, after the trial's three gods. Extends Boss, so
## summons, spells and the spatial hash treat him like any enemy. Every ability
## is telegraphed; numbers in ZeusData.BOSS. Three phases by his HP:
##   * The Thunderer — he walks at the necromancer (enemies always advance),
##       striking in reach. LIGHTNING STORM every storm_cooldown s: he stands
##       storm_cast s with the bolt raised, then storm_count bolts strike marked
##       circles around the necromancer through the Wrath of the Gods' strike
##       entry (DivineWrath.strike("lightning"): the wrath's own telegraph,
##       damage and chains to bronze, so the storm also scorches his own
##       bronze host). THE THUNDERBOLT BEAM every beam_cooldown s: a lane toward
##       the necromancer shows beam_telegraph s, then a white beam burns down
##       it for beam_time s, hitting the necromancer and every summon in it once
##       (OlympusHits.lane()).
##   * The Storm Throne (below phase2_hp) — storms come every
##       storm_cooldown_p2 s with storm_count_p2 bolts; the beam splits into
##       beam_fan_p2 lanes beam_fan_angle apart.
##   * The True Form (below phase3_hp) — he stands colossus_time s while he
##       grows into his colossal form (body x colossus_size, the colossus
##       sprite, heavier, slower, harder blows; a window for the army); then the
##       storm rains every storm_cooldown_p3 s, the beam is wider, and the
##       THUNDER STOMP joins: a circle of stomp_radius px around him
##       (stomp_telegraph s), then a shock that hurts and throws out what is in it.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Stolen Thunder spell and Titan's Blood (UnlockData, boss "zeus"). Attack
## pose (BossPoseData): bosses/zeus_cast while he calls a storm or the beam.
## Determinism: the seeded global RNG only (the storm's own scatter, inside
## DivineWrath). Stats: boss_atk_<special>, zeus_storm_bolts, zeus_beam_hits,
## zeus_stomp_hits, zeus_phase2_at, zeus_colossus_at.
class_name BossZeus
extends Boss

## Boss action phases.
enum Phase { WALK, STORM_CAST, BEAM_WINDUP, BEAM, TRANSFORM, STOMP_WINDUP, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His form: 1 the Thunderer, 2 the Storm Throne, 3 the True Form.
var form: int = 1
## True once he took his colossal form (phase 3 finished growing).
var colossus: bool = false
## Seconds until his next storm.
var storm_cd: float = 0.0
## Seconds until his next beam.
var beam_cd: float = 0.0
## Seconds until his next stomp.
var stomp_cd: float = 0.0
## Unit directions of the current beam's lanes (locked at the windup).
var _lanes: Array[Vector2] = []
## Who the current beam or stomp already struck (OlympusHits).
var _struck: Dictionary = {}
## His body radius before the colossal form (px).
var _base_radius: float = 20.0
## Move speed of his current form (px/s).
var _base_speed: float = 50.0


## Sets up Zeus at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ZeusData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	colossus = false
	storm_cd = float(boss_def["first_storm"])
	beam_cd = float(boss_def["first_beam"])
	stomp_cd = 0.0
	_lanes.clear()
	_struck.clear()
	_base_radius = radius
	_base_speed = move_speed
	game.pantheon_rules()  # His storms go through the Wrath of the Gods (created on another stage too, --boss=zeus).


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return ZeusData.SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of his art (engine-motion pivot): his colossal form once he took it.
func motion_sprite_key() -> String:
	return "bosses/zeus_colossus" if colossus and SpriteBank.has("bosses/zeus_colossus") else "bosses/zeus"


## Boss physics: his phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	storm_cd -= delta
	beam_cd -= delta
	stomp_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		form = 2
		game.stat_add("zeus_phase2_at", game.elapsed)
		game.enemies.show_banner(String(boss_def["phase2_banner"]))
		storm_cd = minf(storm_cd, 1.0)
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]) and (phase == Phase.WALK or phase == Phase.RECOVER):
		_start_transform()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.STORM_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["storm_cast"]):
				_call_storm()
				_set_phase(Phase.RECOVER)
		Phase.BEAM_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["beam_telegraph"]):
				_struck.clear()
				game.pantheon_rules().play_sound("zeus_beam", position)
				game.shake(5.0)
				_set_phase(Phase.BEAM)
		Phase.BEAM:
			_hold(delta)
			_burn_beam()
			queue_redraw()
			if phase_time >= float(boss_def["beam_time"]):
				_set_phase(Phase.RECOVER)
		Phase.TRANSFORM:
			_hold(delta)
			queue_redraw()
			if phase_time >= float(boss_def["colossus_time"]):
				_finish_transform()
				_set_phase(Phase.WALK)
		Phase.STOMP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["stomp_telegraph"]):
				_stomp()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Walking: the shared walk and melee, striding faster when far; a storm, the
## beam or (True Form) the stomp start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if colossus and stomp_cd <= 0.0 and (dist <= float(boss_def["stomp_range"]) + game.player.radius \
			or OlympusHits.summons_near(game, position, float(boss_def["stomp_range"]), _tmp) >= int(boss_def["stomp_min_summons"])):
		_start_stomp()
	elif storm_cd <= 0.0:
		_start_storm()
	elif beam_cd <= 0.0 and dist <= float(boss_def["beam_length"]):
		_start_beam()


## Standing still during a windup / beam / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# The lightning storm
# =====================================================================================

## He raises the bolt (the storm's cast).
func _start_storm() -> void:
	var key := "storm_cooldown" if form == 1 else ("storm_cooldown_p2" if not colossus else "storm_cooldown_p3")
	storm_cd = float(boss_def[key])
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_storm", 1.0)
	game.pantheon_rules().play_sound("zeus_cast", position)
	_set_phase(Phase.STORM_CAST)


## The storm: one lightning strike through the Wrath of the Gods' strike
## entry, its circles around the necromancer.
func _call_storm() -> void:
	var key := "storm_count" if form == 1 else ("storm_count_p2" if not colossus else "storm_count_p3")
	var n := game.pantheon_rules().wrath.strike("lightning", game.player.position, {
		"count": int(boss_def[key]),
		"telegraph": float(boss_def["storm_telegraph"]),
		"radius": float(boss_def["storm_radius"]),
		"near": float(boss_def["storm_near"]),
		"scatter": float(boss_def["storm_scatter"]),
	})
	game.stat_add("zeus_storm_bolts", float(n))
	game.effects.ring(position, radius * 3.0, Palette.PANTHEON_AEGEAN_LIGHT, 0.4)


# =====================================================================================
# The thunderbolt beam
# =====================================================================================

## Locks the beam's lanes toward the necromancer and telegraphs them.
func _start_beam() -> void:
	beam_cd = float(boss_def["beam_cooldown"] if form == 1 else boss_def["beam_cooldown_p2"])
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_lanes.clear()
	var n := 1 if form == 1 else int(boss_def["beam_fan_p2"])  # Lanes.
	for i in n:
		_lanes.append(dir.rotated((float(i) - float(n - 1) * 0.5) * float(boss_def["beam_fan_angle"])))
	for l in _lanes:
		game.effects.telegraph_line(position, position + l * float(boss_def["beam_length"]), _beam_width(), float(boss_def["beam_telegraph"]), self)
	motion_lunge(-dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_thunderbolt", 1.0)
	game.pantheon_rules().play_sound("zeus_cast", position)
	_set_phase(Phase.BEAM_WINDUP)


## Width of the beam (px): wider in his true form.
func _beam_width() -> float:
	return float(boss_def["beam_width_p3"] if colossus else boss_def["beam_width"])


## The beam burns: every necromancer and summon in a lane, once per beam.
func _burn_beam() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	for l in _lanes:
		game.stat_add("zeus_beam_hits", float(OlympusHits.lane(game, position, l, float(boss_def["beam_length"]), _beam_width(),
				float(boss_def["beam_damage_player"]) * mult, float(boss_def["beam_damage_summon"]) * mult, "zeus_beam", self, _struck, _tmp)))


# =====================================================================================
# The True Form and the Thunder Stomp
# =====================================================================================

## He starts growing into his colossal form.
func _start_transform() -> void:
	form = 3
	game.stat_add("zeus_colossus_at", game.elapsed)
	game.stat_add("boss_atk_colossus", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.PANTHEON_AEGEAN_LIGHT)
	game.pantheon_rules().play_sound("zeus_transform", position)
	game.shake(8.0)
	_set_phase(Phase.TRANSFORM)


## The colossal form: a bigger, heavier, slower body with harder blows.
func _finish_transform() -> void:
	colossus = true
	radius = _base_radius * float(boss_def["colossus_size"])
	mass = float(boss_def["colossus_mass"])
	_base_speed = float(boss_def["colossus_speed"])
	damage = float(boss_def["colossus_damage"])
	storm_cd = minf(storm_cd, 1.5)
	stomp_cd = 1.0
	game.effects.impact(position, radius * 2.5, Palette.GOLD)
	if motion != null:
		motion.reset(UnitMotion.feet_of(motion_sprite_key(), "", radius), radius, MotionData.BOSS_SCALE, false)


## Telegraphs the stomp circle around him.
func _start_stomp() -> void:
	stomp_cd = float(boss_def["stomp_cooldown"])
	game.effects.telegraph_circle(position, float(boss_def["stomp_radius"]), float(boss_def["stomp_telegraph"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_stomp", 1.0)
	_set_phase(Phase.STOMP_WINDUP)


## The shock: hurts and throws out what is inside the circle.
func _stomp() -> void:
	var mult := game.enemies.damage_mult * hit_mult()
	game.stat_add("zeus_stomp_hits", float(OlympusHits.circle(game, position, float(boss_def["stomp_radius"]),
			float(boss_def["stomp_damage_player"]) * mult, float(boss_def["stomp_damage_summon"]) * mult, "zeus_stomp", self,
			float(boss_def["stomp_push"]), _tmp)))
	game.effects.impact(position, float(boss_def["stomp_radius"]), Palette.PANTHEON_AEGEAN_LIGHT)
	game.pantheon_rules().play_sound("thunder", position)
	game.shake(7.0)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of a beam lane and the stomp
## circle (the storm's circles are the wrath's own hint).
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.BEAM_WINDUP or phase == Phase.BEAM:
		for l in _lanes:
			var rel := p - position
			var along := rel.dot(l)
			if along > -20.0 and along < float(boss_def["beam_length"]) + 20.0:
				var side := rel - l * along
				if side.length() < _beam_width() + 26.0:
					return side.normalized() if side.length() > 0.5 else l.orthogonal()
	if phase == Phase.STOMP_WINDUP:
		var away := p - position
		if away.length() < float(boss_def["stomp_radius"]) + 30.0:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## Body layer on `ci`: his sprite in the pose of his phase (BossPoseData: 1
## calling a storm or the beam), his colossal form once he took it; while he
## grows, the still swells with a storm glow.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.STORM_CAST, Phase.BEAM_WINDUP, Phase.BEAM:
			pose = 1
	if phase == Phase.TRANSFORM:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["colossus_time"])), 0.0, 1.0)
		ci.draw_circle(Vector2.ZERO, radius * (1.4 + 1.2 * k), Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.12 + 0.2 * k))
	var key := motion_sprite_key()
	if SpriteBank.draw_pose(ci, key, pose, Vector2.ZERO, flash > 0.0):
		return
	OlympusGlyphs.draw_zeus(ci, Vector2.ZERO, radius, flash > 0.0, colossus)


## Overlay layer on `ci`: the burning beam (white lanes with a blue core) and
## the Stasis ice. Drawn in world axes from his centre.
func _draw_over(ci: CanvasItem) -> void:
	if phase == Phase.BEAM:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # Undo his mirror: world axes.
		var w := _beam_width()
		var fade := 1.0 - clampf(phase_time / maxf(0.01, float(boss_def["beam_time"])), 0.0, 1.0) * 0.6
		for l in _lanes:
			var b := l * float(boss_def["beam_length"])
			ci.draw_line(Vector2.ZERO, b, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.45 * fade), w)
			ci.draw_line(Vector2.ZERO, b, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.9 * fade), w * 0.4)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("zeus_phase2_at", -1.0))
	var p3 := float(st.get("zeus_colossus_at", -1.0))
	return "storms %d (bolts %d) | thunderbolt beams %d (hits %d) | storm throne %s | true form %s | stomps %d (summon hits %d) | dmg to player %d, summons %d" % [
		int(st.get("boss_atk_storm", 0.0)), int(st.get("zeus_storm_bolts", 0.0)), int(st.get("boss_atk_thunderbolt", 0.0)), int(st.get("zeus_beam_hits", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", EmpireReport._clock(p3) if p3 >= 0.0 else "not reached",
		int(st.get("boss_atk_stomp", 0.0)), int(st.get("zeus_stomp_hits", 0.0)),
		int(st.get("player_dmg_from_zeus_beam", 0.0)) + int(st.get("player_dmg_from_zeus_stomp", 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_zeus_beam", 0.0)) + int(st.get("summon_dmg_from_zeus_stomp", 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
