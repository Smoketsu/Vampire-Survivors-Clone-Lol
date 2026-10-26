## BossAmaterasu — AMATERASU, THE SUN GODDESS, the boss of the Road to the Sun
## and of Act V (Stage 15; GDD §15.0 "Amaterasu, the Sun Goddess";
## owner-approved proposal docs/act5/PROPOSAL.md: "Her place in the sky is the
## phase"). Loaded by name for the boss id "amaterasu"
## (EnemyDirector.SHOGUNATE_BOSS_DIR + "boss_amaterasu.gd"); she rises at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat her
## like any enemy. She never walks and never body-blocks: she hangs in the sky
## (floating, ethereal: no obstacle and no summon holds her) and glides to her
## place around the necromancer, and her place is the phase (numbers and the
## rules in AmaterasuData; its header has the whole fight):
##   * DAWN, east of him: mirror beams that sweep slowly, sun-disc mines.
##   * NOON, directly overhead: beams on marked circles and the noon glare; the
##     obstacles' shadows are the only safe ground (AmaterasuHazards.in_shade()).
##   * SUNSET, west of him: the wide setting-sun beam across the arena and the
##     mirror's slower sweeps; the light turns red and night closes in.
## THE SKY IS HERS: each phase takes the Sun's Course through its ONE override
## (SunCourse.set_override() with AmaterasuData.SKY; the darkening sunset
## re-sent every sunset_sky_every s), so light_at(), the darkness, the wash and
## the shadows follow her with no second lighting path. Off Act V (--boss=
## on another stage) the Sun's Course is off and the override does nothing.
## When she FALLS, THE SUN GOES OUT: SunCourse.clear_override() hands the sky
## back to the night (then the Reckoning is the Endless Night), the dark sun
## hangs where she fell (AmaterasuHazards.start_finale()) and the ending line
## and announcement show, like Hades' and Vhal'Neth's.
## She is invulnerable while she rises and while she crosses the sky between
## two phases, and never falls below the next phase's threshold while a phase
## runs. Determinism: the seeded global RNG only (the mines' and the circles'
## spots). Stats: boss_atk_<special>, amaterasu_noon_at, amaterasu_sunset_at,
## amaterasu_spawn_time, amaterasu_kill_time, amaterasu_player_hits,
## amaterasu_summon_hits, amaterasu_glares, amaterasu_glare_player_hits /
## _shaded, amaterasu_glare_summons_shaded, amaterasu_zenith_player_shaded,
## amaterasu_mine_bursts, amaterasu_sky_<phase> (override changes).
class_name BossAmaterasu
extends Boss

## Her phases.
enum Phase { ARRIVING, DAWN, CHANGING, NOON, SUNSET }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds into the current phase.
var phase_time: float = 0.0
## Phase that follows the CHANGING crossing.
var _next_phase: Phase = Phase.NOON
## Seconds until the next mirror beam.
var mirror_cd: float = 0.0
## Seconds until the next mines.
var mine_cd: float = 0.0
## Seconds until the next zenith circles.
var zenith_cd: float = 0.0
## Seconds until the next glare.
var glare_cd: float = 0.0
## Seconds until the next setting-sun beam.
var sunset_cd: float = 0.0
## Seconds until the darkening sunset sky is re-sent.
var _sky_cd: float = 0.0
## Ambient light last sent at sunset (-1 = none yet).
var _sky_sent: float = -1.0
## Seconds the mirror is raised (her attack pose; visual only).
var _pose_left: float = 0.0
## Game time she arrived.
var _spawn_time: float = 0.0
## Her world-space attacks and drawings (a child of the EnemyDirector).
var hazards: AmaterasuHazards = null


## Sets up Amaterasu at `pos` with HP scaled by `hp_mult`: she rises in the east.
func setup_boss(p_game: Game, _pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = AmaterasuData.BOSS
	var east := p_game.player.position + Vector2(float(boss_def["sky_distance"]), 0.0)  # Owner-approved: she rises on the east edge.
	activate(p_game, "boss", boss_def, east, hp_mult, false, slot)
	is_boss = true
	floating = true  # The sun is never carried by the ground.
	ethereal = true  # No summon body-blocks her (Enemy.resolve_blocking()).
	phases_obstacles = true  # She hangs above every obstacle.
	z_index = 2
	phase = Phase.ARRIVING
	phase_time = 0.0
	_spawn_time = game.elapsed
	game.stats["amaterasu_spawn_time"] = game.elapsed
	game.shogunate_rules()  # Her sky is the Sun's Course's (on any stage she is sent to).
	hazards = AmaterasuHazards.new()
	hazards.game = game
	hazards.boss = self
	game.enemies.add_child(hazards)
	game.enemies.boss_defeated.connect(_on_defeated)
	_sky("dawn")
	game.effects.impact(position, radius * 3.0, Palette.GOLD)
	game.shake(8.0)
	Sfx.play("amaterasu_rise", position)


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return AmaterasuData.SPECIALS


## True while she holds her place in the sky (Boss hook, the stuck check):
## she never walks, so she is never stuck.
func is_walking() -> bool:
	return false


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/amaterasu"


## Invulnerable while she rises or crosses the sky; never below the next
## phase's threshold while a phase runs.
func damage_taken_mult(source: String) -> float:
	if phase == Phase.ARRIVING or phase == Phase.CHANGING:
		return 0.0
	var m := super.damage_taken_mult(source)
	match phase:
		Phase.DAWN:
			if hp <= max_hp * float(boss_def["noon_hp"]) + 1.0:
				return 0.0
		Phase.NOON:
			if hp <= max_hp * float(boss_def["sunset_hp"]) + 1.0:
				return 0.0
	return m


## Takes the sky for phase `key` (AmaterasuData.SKY), the Sun's Course's one override.
func _sky(key: String, extra: Dictionary = {}) -> void:
	if game.shogunate == null:
		return
	var opts: Dictionary = (AmaterasuData.SKY[key] as Dictionary).duplicate()
	for k: String in extra:
		opts[k] = extra[k]
	game.shogunate.sun.set_override(opts)
	game.stat_add("amaterasu_sky_" + key, 1.0)


# =====================================================================================
# Physics: her place in the sky, the phases
# =====================================================================================

## Where she hangs in phase `p`: east of the necromancer at dawn, north
## (overhead) at noon, west at sunset.
func _post(p: Phase) -> Vector2:
	var c := game.player.position
	match p:
		Phase.NOON:
			return c + Vector2(0.0, -float(boss_def["zenith_distance"]))
		Phase.SUNSET:
			return c + Vector2(-float(boss_def["sky_distance"]), 0.0)
	return c + Vector2(float(boss_def["sky_distance"]), 0.0)


func physics_step(delta: float) -> void:
	_tick_timers(delta)
	phase_time += delta
	knockback = Vector2.ZERO
	_pose_left -= delta
	var target_phase := _next_phase if phase == Phase.CHANGING else (Phase.DAWN if phase == Phase.ARRIVING else phase)
	var to := _post(target_phase) - position
	var spd := float(boss_def["glide_speed"]) * (2.0 if phase == Phase.CHANGING else 1.0)  # She crosses the sky faster.
	velocity = to.limit_length(spd)
	if to.length() < 2.0:
		velocity = Vector2.ZERO
	position += velocity * delta
	_update_facing()
	hazards.step(delta)
	match phase:
		Phase.ARRIVING:
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.DAWN)
		Phase.CHANGING:
			if phase_time >= float(boss_def["change_time"]):
				_enter(_next_phase)
		Phase.DAWN:
			_step_dawn(delta)
			if hp <= max_hp * float(boss_def["noon_hp"]) + 1.0:
				_change(Phase.NOON)
		Phase.NOON:
			_step_noon(delta)
			if hp <= max_hp * float(boss_def["sunset_hp"]) + 1.0 and hazards.glare_at < 0.0:
				_change(Phase.SUNSET)
		Phase.SUNSET:
			_step_sunset(delta)


## Starts phase `p` (its banner, sky and first timers).
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	var b := boss_def
	match p:
		Phase.DAWN:
			mirror_cd = float(b["mirror_first"])
			mine_cd = float(b["mine_first"])
			hazards.noon = false
		Phase.NOON:
			game.stats["amaterasu_noon_at"] = game.elapsed
			game.enemies.show_banner("NOON: the sun stands overhead. Only the shadows are safe!")
			zenith_cd = float(b["zenith_first"])
			glare_cd = float(b["glare_first"])
			hazards.noon = true
		Phase.SUNSET:
			game.stats["amaterasu_sunset_at"] = game.elapsed
			game.enemies.show_banner("SUNSET: Amaterasu sinks to the west. The light turns red!")
			sunset_cd = float(b["sunset_first"])
			mirror_cd = float(b["mirror_first"]) * float(b["sunset_mirror_mult"])
			hazards.noon = false
			_sky_cd = float(b["sunset_sky_every"])
	queue_redraw()


## Crosses the sky (invulnerable) to phase `p`; its sky blends in as she goes.
func _change(p: Phase) -> void:
	_next_phase = p
	phase = Phase.CHANGING
	phase_time = 0.0
	hazards.noon = p == Phase.NOON
	_sky("noon" if p == Phase.NOON else "sunset")
	game.effects.ring(position, 160.0, Palette.GOLD, 0.8)
	game.shake(6.0)
	Sfx.play("amaterasu_rise", position, 0.8)
	queue_redraw()


## Dawn: the mirror's sweeping beams and the sun-disc mines.
func _step_dawn(delta: float) -> void:
	mirror_cd -= delta
	mine_cd -= delta
	if mirror_cd <= 0.0:
		mirror_cd = float(boss_def["mirror_cooldown"])
		_mirror_beam()
	if mine_cd <= 0.0:
		mine_cd = float(boss_def["mine_cooldown"])
		_mines()


## Noon: the marked circles and the glare.
func _step_noon(delta: float) -> void:
	zenith_cd -= delta
	glare_cd -= delta
	if zenith_cd <= 0.0:
		zenith_cd = float(boss_def["zenith_cooldown"])
		_zenith()
	if glare_cd <= 0.0 and hazards.glare_at < 0.0:
		glare_cd = float(boss_def["glare_cooldown"])
		hazards.start_glare()
		game.stat_add("boss_atk_noon_glare", 1.0)
		game.enemies.show_banner("The noon glare builds: get into the shade!")
		Sfx.play("noon_glare", position, 0.6)


## Sunset: the setting-sun beam, the mirror's slower sweeps, the darkening sky.
func _step_sunset(delta: float) -> void:
	sunset_cd -= delta
	mirror_cd -= delta
	_sky_cd -= delta
	if sunset_cd <= 0.0:
		sunset_cd = float(boss_def["sunset_cooldown"])
		var to := game.player.position - position
		var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		hazards.add_sunset(position, dir)
		game.stat_add("boss_atk_sunset_beam", 1.0)
		_pose_left = float(boss_def["sunset_telegraph"])
		Sfx.play("sun_charge", position)
	if mirror_cd <= 0.0:
		mirror_cd = float(boss_def["mirror_cooldown"]) * float(boss_def["sunset_mirror_mult"])
		_mirror_beam()
	if _sky_cd <= 0.0:
		_sky_cd = float(boss_def["sunset_sky_every"])
		var start := float((AmaterasuData.SKY["sunset"] as Dictionary)["ambient"])
		var left := clampf(hp / maxf(1.0, max_hp * float(boss_def["sunset_hp"])), 0.0, 1.0)  # 1 at sunset's start, 0 at her fall.
		var amb := lerpf(float(boss_def["sunset_ambient_end"]), start, left)
		if _sky_sent < 0.0 or absf(amb - _sky_sent) > 0.02:
			_sky_sent = amb
			_sky("sunset", {"ambient": amb})


## A mirror beam: aimed just to one side of the necromancer and sweeping across
## him (the side alternates with the seeded RNG).
func _mirror_beam() -> void:
	var a := (game.player.position - position).angle()
	var half := float(boss_def["mirror_sweep"]) * 0.5
	var s := 1.0 if randf() < 0.5 else -1.0  # Which way it sweeps.
	hazards.add_beam(a - half * s, a + half * s)
	game.stat_add("boss_atk_mirror_beam", 1.0)
	_pose_left = float(boss_def["mirror_telegraph"]) + float(boss_def["mirror_time"])
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	Sfx.play("sun_charge", position, 0.8)
	queue_redraw()


## Sun-disc mines on a ring around the necromancer (seeded spots).
func _mines() -> void:
	var p := game.player.position
	var n := int(boss_def["mine_count"])
	var a0 := randf() * TAU
	for i in n:
		var a := a0 + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.3, 0.3)
		var d := randf_range(float(boss_def["mine_ring_min"]), float(boss_def["mine_ring_max"]))
		hazards.add_mine(game.arena.free_point(p + Vector2.from_angle(a) * d, 8.0))
	game.stat_add("boss_atk_sun_mines", 1.0)
	Sfx.play("sun_mine", p, 0.6)


## Noon beams: one circle on the necromancer, the rest on his army.
func _zenith() -> void:
	var p := game.player.position
	hazards.add_zenith(p)
	var reach := float(boss_def["zenith_reach"])
	game.ally_grid.query(p, reach, _tmp)
	var picks: Array = []  # Summon positions (the hash's order).
	for u: SummonedUnit in _tmp:
		if u.active and not u.airborne and u.position.distance_to(p) <= reach:
			picks.append(u.position)
	for i in int(boss_def["zenith_count"]) - 1:
		var at := p + Vector2.from_angle(randf() * TAU) * randf_range(60.0, reach)
		if not picks.is_empty():
			at = picks[randi() % picks.size()]
		hazards.add_zenith(at)
	game.stat_add("boss_atk_zenith_beams", 1.0)
	_pose_left = float(boss_def["zenith_telegraph"])


# =====================================================================================
# Her fall, the autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated, after the reward burst): THE SUN
## GOES OUT. Her attacks end, the sky goes back to the night, the dark sun
## hangs where she fell, the ending line and announcement show.
func _on_defeated() -> void:
	var pos := position
	hazards.clear_all()
	hazards.start_finale(pos)
	if game.shogunate != null:
		game.shogunate.sun.clear_override()
		game.shogunate.play_sound("nightfall", pos)
	game.effects.ring(pos, 220.0, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, 130.0, SunRoadGlyphs.SUN_RED, 0.8)
	Juice.fx.burst(pos, SunRoadGlyphs.SUN_GOLD, Palette.NECRO_GREEN, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("sun_goes_out", pos)
	var late := game.countdown_finished()  # She fell during the Endless Night.
	game.enemies.show_banner(String(AmaterasuData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + AmaterasuData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = AmaterasuData.LATE_ANNOUNCE if late else AmaterasuData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)
	game.stats["amaterasu_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot (AmaterasuHazards.danger_push()).
func danger_push(p: Vector2) -> Vector2:
	return hazards.danger_push(p) if hazards != null else Vector2.ZERO


## Under her body: the sun's disc behind her (gold at dawn and noon, red at
## sunset). Visual only.
func _draw_under() -> void:
	var col := SunRoadGlyphs.SUN_RED if phase == Phase.SUNSET else SunRoadGlyphs.SUN_GOLD
	var a := 0.45
	if phase == Phase.ARRIVING:
		a *= clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.0, 1.0)
	var r := radius * 3.2
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r - radius * 1.2), Vector2(r, r) * 2.0), false, Color(col, a * 0.5))
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r - radius * 1.2) * 0.62, Vector2(r, r) * 1.24), false, Color(SunRoadGlyphs.SUN_WHITE, a * 0.6))


## Body layer on `ci`: her sprite (BossPoseData pose 1, the raised mirror,
## while an attack winds up or burns), the glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var alpha := 1.0
	if phase == Phase.ARRIVING:
		alpha = clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.15, 1.0)
	var pose := 1 if (_pose_left > 0.0 or phase == Phase.CHANGING) else 0
	if SpriteBank.draw_pose(ci, "bosses/amaterasu", pose, Vector2.ZERO, flash > 0.0, Color(1.0, 1.0, 1.0, alpha)):
		return
	SunRoadGlyphs.draw_amaterasu(ci, Vector2.ZERO, radius, flash > 0.0, alpha, pose)


## Overlay layer on `ci`: ice and the stun look (the HP is the HUD's bar).
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of her fight (phase times relative to her arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("amaterasu_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	return "phases: noon %s, sunset %s, the sun goes out %s | sky overrides: dawn %d, noon %d, sunset %d | mirror beams %d, mines %d (bursts %d), zenith beams %d, glares %d (you hit %d, shaded %d; summons shaded %d), sunset beams %d | you hit %d (zenith shaded %d) | dmg to you: mirror %d, mines %d, zenith %d, glare %d, sunset %d | dmg to summons %d" % [
		rel.call("amaterasu_noon_at"), rel.call("amaterasu_sunset_at"), "%.1fs" % float(st["amaterasu_kill_time"]) if st.has("amaterasu_kill_time") else "-",
		int(st.get("amaterasu_sky_dawn", 0.0)), int(st.get("amaterasu_sky_noon", 0.0)), int(st.get("amaterasu_sky_sunset", 0.0)),
		int(st.get("boss_atk_mirror_beam", 0.0)), int(st.get("boss_atk_sun_mines", 0.0)), int(st.get("amaterasu_mine_bursts", 0.0)),
		int(st.get("boss_atk_zenith_beams", 0.0)), int(st.get("amaterasu_glares", 0.0)), int(st.get("amaterasu_glare_player_hits", 0.0)),
		int(st.get("amaterasu_glare_player_shaded", 0.0)), int(st.get("amaterasu_glare_summons_shaded", 0.0)), int(st.get("boss_atk_sunset_beam", 0.0)),
		int(st.get("amaterasu_player_hits", 0.0)), int(st.get("amaterasu_zenith_player_shaded", 0.0)),
		int(st.get("player_dmg_from_" + AmaterasuData.SRC_MIRROR, 0.0)), int(st.get("player_dmg_from_" + AmaterasuData.SRC_MINE, 0.0)),
		int(st.get("player_dmg_from_" + AmaterasuData.SRC_ZENITH, 0.0)), int(st.get("player_dmg_from_" + AmaterasuData.SRC_GLARE, 0.0)),
		int(st.get("player_dmg_from_" + AmaterasuData.SRC_SUNSET, 0.0)),
		int(st.get("summon_dmg_from_" + AmaterasuData.SRC_MIRROR, 0.0)) + int(st.get("summon_dmg_from_" + AmaterasuData.SRC_MINE, 0.0))
			+ int(st.get("summon_dmg_from_" + AmaterasuData.SRC_ZENITH, 0.0)) + int(st.get("summon_dmg_from_" + AmaterasuData.SRC_GLARE, 0.0))
			+ int(st.get("summon_dmg_from_" + AmaterasuData.SRC_SUNSET, 0.0))]
