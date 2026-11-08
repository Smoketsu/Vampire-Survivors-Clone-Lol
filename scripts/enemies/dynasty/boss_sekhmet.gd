## BossSekhmet — SEKHMET, THE LIONESS OF RETRIBUTION, the boss of the Temple of
## the Lioness (temporary Act XII, the Necropolis Dynasty, final slot VII;
## GDD §15.0 "Sekhmet, the Lioness of Retribution (Dynasty phase 2)"; proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 3 "Stage B": female,
## lioness-masked, figure style). Loaded by name for the boss id "sekhmet"
## (EnemyDirector.DYNASTY_BOSS_DIR + "boss_sekhmet.gd"); she arrives at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat her
## like any enemy. Every ability is telegraphed; numbers in SekhmetData.BOSS.
## Three phases by her HP (see SekhmetData for the numbers):
##   * THE HUNT: she perches by a pillar of the temple, then leaps onto the
##     Bone Ring (a landing circle shows first), and rakes: the landing and
##     the rakes after it strike every necromancer and summon in their circles
##     (OlympusHits.circle(), CombatResolver's one hit paths); then she leaps
##     out to the next pillar, a third of the way round.
##   * THE RED WIND: she calls the Sandstorm early (Sandstorm.force(), the one
##     storm clock; re-forced each second while the phase lasts) and the Heka
##     glyph spreads at double speed (Heka.set_jump_speed(), reset when the
##     phase ends or she leaves); she writes a glyph of her own on the nearest
##     summon every glyph_every s (Heka.write(), the one call), and hunts
##     faster.
##   * THE FEAST: enraged, she cannot be stopped (she takes no damage, and no
##     slow, stun or shove holds her) and sets down three red-wine jars
##     (LionessTempleEnemyData "wine_jar", WineJarKit) around the necromancer;
##     she runs to each in turn and drinks. A jar she finishes is drained (she
##     heals some, at most back to the Feast's line: CombatResolver
##     .heal_enemy(), the one enemy heal path). When the set is gone, if the
##     army broke all three she STUMBLES for 4 s, the only window she can be
##     hurt; a new set stands soon after either way. A failsafe (feast_cap s
##     into the Feast every hit lands at feast_cap_taken) keeps a run from
##     never ending her.
## The Red Wind works on any stage where the Dynasty's rules exist
## (Game.dynasty_rules() creates them with the clocks off, --boss=sekhmet).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks the
## Burning Eye spell and Desert Fury (UnlockData, boss "sekhmet"). Attack pose
## (BossPoseData, when the art has one): pose 1 while she crouches or drinks.
## Determinism: no RNG (her perches turn by a fixed angle, her jars stand on
## fixed angles). Stats: boss_atk_<special>, sekhmet_leap_hits,
## sekhmet_rake_hits, sekhmet_glyphs, sekhmet_red_wind_at, sekhmet_feast_at,
## sekhmet_jars_set, sekhmet_jars_drained, sekhmet_stumbles,
## sekhmet_stumble_dmg, sekhmet_feast_dmg_blocked, sekhmet_feast_capped.
class_name BossSekhmet
extends Boss

## Boss action phases.
enum Phase { PERCH, LEAP_WINDUP, LEAP_IN, RAKE, LEAP_OUT, FEAST_WALK, DRINK, STUMBLE }

## Current action phase.
var phase: Phase = Phase.PERCH
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Her form: 1 the Hunt, 2 the Red Wind, 3 the Feast.
var form: int = 1
## Angle (rad) of her current perch around the necromancer.
var _perch_angle: float = 0.0
## Where a leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where a leap lands (world px; locked at its windup).
var _to: Vector2 = Vector2.ZERO
## Seconds she still waits on her perch.
var _perch_left: float = 0.0
## Rakes left after the landing.
var _rakes_left: int = 0
## Seconds until the next rake.
var _rake_cd: float = 0.0
## Seconds until her next glyph (the Red Wind).
var _glyph_cd: float = 0.0
## Seconds until the Red Wind's storm is forced again.
var _storm_cd: float = 0.0
## The current set of wine jars (generation-checked).
var _jars: Array[Enemy] = []
## Pool generation of each entry of `_jars`.
var _jar_gens: PackedInt32Array = PackedInt32Array()
## Jars of the current set the army broke.
var _broken: int = 0
## Jars of the current set she drained.
var _drained: int = 0
## The jar she drinks from or runs to (null = none).
var _jar: Enemy = null
## Game time a new set of jars stands (INF = a set stands now).
var _refill_at: float = INF
## Game time the Feast began (s).
var _feast_at: float = INF
## Move speed of her current form (px/s).
var _base_speed: float = 64.0


## Sets up Sekhmet at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = SekhmetData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	form = 1
	_jars.clear()
	_jar_gens.clear()
	_jar = null
	_broken = 0
	_drained = 0
	_refill_at = INF
	_feast_at = INF
	_base_speed = move_speed
	_perch_angle = (position - game.player.position).angle()
	_perch_left = float(boss_def["first_perch"])
	_glyph_cd = float(boss_def["glyph_every"])
	_storm_cd = 0.0
	_set_phase(Phase.PERCH)
	game.dynasty_rules().play_sound("sekhmet_roar", position)
	game.enemies.show_banner(String(boss_def["hunt_banner"]))


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return SekhmetData.SPECIALS


## Sprite key of her art (engine-motion pivot, the walk and idle strips).
func motion_sprite_key() -> String:
	return SekhmetData.SPRITE


## True while she walks or waits (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.FEAST_WALK and _jar == null


## Her fall (or any removal): the glyph's speed returns to the rule's, her
## jars leave the field.
func deactivate() -> void:
	if game != null and game.dynasty != null:
		game.dynasty.heka.set_jump_speed(1.0)
	if game != null and game.enemies != null:
		_clear_jars()
	_jar = null
	super.deactivate()


## THE FEAST: no damage outside her stumbles (the failsafe after feast_cap s).
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if form < 3:
		return m
	if phase == Phase.STUMBLE:
		return m * float(boss_def["stumble_taken"])
	if game.elapsed - _feast_at >= float(boss_def["feast_cap"]):
		game.stat_add("sekhmet_feast_capped", 1.0)
		return m * float(boss_def["feast_cap_taken"])
	game.stat_add("sekhmet_feast_dmg_blocked", 1.0)
	return 0.0


# =====================================================================================
# The phase machine
# =====================================================================================

## Boss physics: her form and phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	if form == 1 and hp <= max_hp * float(boss_def["red_wind_hp"]):
		_red_wind()
	if form == 2 and hp <= max_hp * float(boss_def["feast_hp"]):
		_feast()
	if form == 2:
		_step_red_wind(delta)
	if form == 3 and phase != Phase.STUMBLE:
		stun_timer = 0.0  # Enraged: nothing stops her.
		slow_timer = 0.0
		frozen = false
	match phase:
		Phase.PERCH:
			_hold(delta)
			_perch_left -= delta
			if _perch_left <= 0.0:
				_start_leap_in()
		Phase.LEAP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["leap_windup"]):
				_from = position
				_set_phase(Phase.LEAP_IN)
		Phase.LEAP_IN:
			if _fly(delta):
				_land()
		Phase.RAKE:
			_hold(delta)
			_rake_cd -= delta
			if _rake_cd <= 0.0:
				if _rakes_left > 0:
					_rake()
					_rakes_left -= 1
					_rake_cd = float(boss_def["rake_gap"])
				else:
					_start_leap_out()
		Phase.LEAP_OUT:
			if _fly(delta):
				_perch_left = float(boss_def["perch_time_p2" if form == 2 else "perch_time"])
				_set_phase(Phase.PERCH)
		Phase.FEAST_WALK:
			_step_feast(delta)
		Phase.DRINK:
			_hold(delta)
			if not _jar_alive(_jar):
				_jar = null
				_set_phase(Phase.FEAST_WALK)
			elif phase_time >= float(boss_def["drink_time"]):
				_drain(_jar)
		Phase.STUMBLE:
			_hold(delta)
			if phase_time >= float(boss_def["stumble_time"]):
				_refill_at = game.elapsed + float(boss_def["refill_time"])
				_set_phase(Phase.FEAST_WALK)


## Standing still during a perch, windup, rake, drink or stumble.
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	var pl := game.player
	var f := -1.0 if pl.position.x < position.x else 1.0  # She faces the necromancer.
	if absf(pl.position.x - position.x) > 4.0 and f != _facing:
		_facing = f
		scale.x = _facing
		queue_redraw()


## The leap in flight: true when it lands this tick.
func _fly(delta: float) -> bool:
	_tick_timers(delta)
	var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
	position = _from.lerp(_to, k)
	velocity = Vector2.ZERO
	queue_redraw()  # The arc.
	return k >= 1.0


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# =====================================================================================
# The Hunt: perches, leaps and rakes
# =====================================================================================

## Crouches: the landing circle shows on the Bone Ring, between her and the
## necromancer.
func _start_leap_in() -> void:
	if game.ultimates.player_untargetable():
		_perch_left = 1.0
		return
	var pl := game.player.position
	var dir := (position - pl).normalized() if position.distance_to(pl) > 1.0 else Vector2.RIGHT
	_to = game.arena.free_point(pl + dir * float(boss_def["land_offset"]), radius * 0.5)
	game.effects.telegraph_circle(_to, float(boss_def["leap_radius"]), float(boss_def["leap_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_leap", 1.0)
	_set_phase(Phase.LEAP_WINDUP)


## The landing: everything in the circle is struck and the summons thrown out;
## the rakes follow.
func _land() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.stat_add("sekhmet_leap_hits", float(OlympusHits.circle(game, position, float(boss_def["leap_radius"]),
			float(boss_def["leap_damage_player"]) * mult, float(boss_def["leap_damage_summon"]) * mult * undead_damage_mult,
			SekhmetData.LEAP_SOURCE, self, float(boss_def["leap_push"]), _tmp)))
	game.effects.impact(position, float(boss_def["leap_radius"]), Palette.DYN_CARNELIAN)
	game.shake(5.0)
	_rakes_left = int(boss_def["rake_count"])
	_rake_cd = float(boss_def["rake_gap"])
	_set_phase(Phase.RAKE)


## One rake: everything around her is clawed.
func _rake() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.stat_add("boss_atk_rake", 1.0)
	game.stat_add("sekhmet_rake_hits", float(OlympusHits.circle(game, position, float(boss_def["rake_radius"]),
			float(boss_def["rake_damage_player"]) * mult, float(boss_def["rake_damage_summon"]) * mult * undead_damage_mult,
			SekhmetData.RAKE_SOURCE, self, 0.0, _tmp)))
	game.effects.slash(position, Vector2.from_angle(float(_rakes_left) * 2.0), Palette.DYN_CARNELIAN_LIGHT, float(boss_def["rake_radius"]))


## Leaps out to the next pillar, a third of the way round the necromancer.
func _start_leap_out() -> void:
	_perch_angle += float(boss_def["perch_turn"])
	_from = position
	_to = _perch_point(_perch_angle)
	_set_phase(Phase.LEAP_OUT)


## Her perch at `angle` around the necromancer: beside the obstacle (a pillar
## of the temple) nearest the point perch_radius px out when one stands within
## pillar_search px of it, else the point itself.
func _perch_point(angle: float) -> Vector2:
	var pl := game.player.position
	var dir := Vector2.from_angle(angle)
	var p := pl + dir * float(boss_def["perch_radius"])
	var o := game.arena.obstacle_at(p)
	if o != null and o.center.distance_to(p) <= float(boss_def["pillar_search"]):
		var ext := o.radius if o.is_circle else maxf(o.half.x, o.half.y)  # The pillar's reach (px).
		p = o.center - dir * (ext + radius + 4.0)  # On the necromancer's side of the pillar.
		game.stat_add("sekhmet_pillar_perches", 1.0)
	return game.arena.free_point(p, radius * 0.5)


# =====================================================================================
# The Red Wind
# =====================================================================================

## The Red Wind: her storm, the glyph at double speed, the banner.
func _red_wind() -> void:
	form = 2
	game.stat_add("sekhmet_red_wind_at", game.elapsed)
	game.stat_add("boss_atk_red_wind", 1.0)
	var rules := game.dynasty_rules()
	rules.sandstorm.force(float(boss_def["red_wind_storm"]))
	rules.heka.set_jump_speed(float(boss_def["red_wind_jump"]))
	rules.play_sound("sekhmet_roar", position)
	game.enemies.show_banner(String(boss_def["red_wind_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.DYN_CARNELIAN)
	_storm_cd = 1.0
	_glyph_cd = 1.5


## While the Red Wind blows: her storm held up, her own glyph.
func _step_red_wind(delta: float) -> void:
	var rules := game.dynasty_rules()
	_storm_cd -= delta
	if _storm_cd <= 0.0:
		_storm_cd = 1.0
		rules.sandstorm.force(3.0)  # She holds the storm while the phase lasts.
	_glyph_cd -= delta
	if _glyph_cd > 0.0:
		return
	_glyph_cd = float(boss_def["glyph_every"])
	var reach := float(boss_def["glyph_reach"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not Heka.can_take(game, u):
			continue
		var dd := u.position.distance_to(position)
		if dd <= reach and dd < best_d:
			best_d = dd
			best = u
	if best != null and rules.heka.write(self, best):
		game.stat_add("boss_atk_glyph", 1.0)
		game.stat_add("sekhmet_glyphs", 1.0)


# =====================================================================================
# The Feast
# =====================================================================================

## The Feast: enraged, unstoppable, her first set of jars.
func _feast() -> void:
	form = 3
	_feast_at = game.elapsed
	game.stat_add("sekhmet_feast_at", game.elapsed)
	game.stat_add("boss_atk_feast", 1.0)
	var rules := game.dynasty_rules()
	rules.heka.set_jump_speed(1.0)
	rules.play_sound("sekhmet_roar", position)
	game.enemies.show_banner(String(boss_def["feast_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.DYN_CARNELIAN_LIGHT)
	game.shake(7.0)
	_base_speed = float(boss_def["feast_speed"])
	damage = float(boss_def["feast_damage"])
	if phase == Phase.LEAP_IN or phase == Phase.LEAP_OUT:
		position = _to  # She lands at once.
	_set_jars()
	_set_phase(Phase.FEAST_WALK)


## A new set of three jars on fixed angles around the necromancer.
func _set_jars() -> void:
	_clear_jars()
	_broken = 0
	_drained = 0
	_refill_at = INF
	var pl := game.player.position
	var n := int(boss_def["jar_count"])
	var a0 := (position - pl).angle() + PI / float(maxi(1, n))  # Not on top of her.
	for k in n:
		var at := game.arena.free_point(pl + Vector2.from_angle(a0 + TAU * float(k) / float(n)) * float(boss_def["jar_dist"]), 14.0)
		var j := game.enemies.spawn_at(LionessTempleEnemyData.WINE_JAR, at, false)
		if j == null:
			continue
		_jars.append(j)
		_jar_gens.append(j.generation)
		game.effects.pop(at, Palette.DYN_CARNELIAN, 20.0)
	game.stat_add("sekhmet_jars_set", float(_jars.size()))
	if _jars.is_empty():
		_refill_at = game.elapsed + float(boss_def["refill_time"])  # No room: try again soon.


## Takes every jar of the set off the field (her removal).
func _clear_jars() -> void:
	for k in _jars.size():
		var j := _jars[k]
		if j.active and j.generation == _jar_gens[k]:
			game.enemies.despawn(j)
	_jars.clear()
	_jar_gens.clear()


## True while `j` is a jar of the current set still standing.
func _jar_alive(j: Enemy) -> bool:
	if j == null:
		return false
	var i := _jars.find(j)
	return i >= 0 and j.active and j.generation == _jar_gens[i]


## The first jar of the set still standing (null = none).
func _next_jar() -> Enemy:
	for j in _jars:
		if _jar_alive(j):
			return j
	return null


## The Feast's walk: to her next jar, biting what she touches; with no jar,
## at the necromancer; a new set when its time comes.
func _step_feast(delta: float) -> void:
	if _jars.is_empty() or _next_jar() == null:
		if _refill_at == INF and not _jars.is_empty():
			_set_done()
		if game.elapsed >= _refill_at:
			_set_jars()
	_jar = _next_jar()
	move_speed = _base_speed
	if _jar == null:
		super.physics_step(delta)  # At the necromancer (the shared walk and bite).
		return
	_tick_timers(delta)
	var to := _jar.position - position
	var dist := to.length()
	if dist - radius - _jar.radius <= float(boss_def["drink_reach"]):
		(_jar.kit as WineJarKit).drunk_from = true
		_jar.queue_redraw()
		game.stat_add("boss_atk_drink", 1.0)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_phase(Phase.DRINK)
		return
	var spd := move_speed
	velocity = to / dist * spd
	position += velocity * delta
	_update_facing()
	if not _target_valid():
		_set_target(game.player)
	var t := target
	var tt := t.position - position
	if tt.length() - radius - _radius_of(t) <= attack_range and attack_cd <= 0.0:
		_melee_hit(t, tt.normalized() if tt.length() > 0.01 else Vector2.RIGHT)


## She finishes a jar: drained, she heals (at most back to the Feast's line).
func _drain(j: Enemy) -> void:
	_drained += 1
	game.stat_add("sekhmet_jars_drained", 1.0)
	var cap := max_hp * float(boss_def["feast_hp"])
	var amount := minf(max_hp * float(boss_def["drain_heal"]), maxf(0.0, cap - hp))
	if amount > 0.0:
		game.combat.heal_enemy(self, amount, null)
	game.effects.pop(j.position, Palette.DYN_CARNELIAN_DARK, 26.0)
	game.enemies.despawn(j)
	_jar = null
	_set_phase(Phase.FEAST_WALK)
	if _next_jar() == null:
		_set_done()


## A jar of the set was broken by the army (WineJarKit.on_killed()).
func on_jar_broken(j: Enemy) -> void:
	if _jars.find(j) < 0:
		return
	_broken += 1
	if j == _jar:
		_jar = null
		if phase == Phase.DRINK:
			_set_phase(Phase.FEAST_WALK)
	if _next_jar() == null and _broken + _drained >= _jars.size():
		_set_done()


## The set is gone: all broken = she stumbles; any drained = she roars.
## Either way a new set stands refill_time s after.
func _set_done() -> void:
	if _refill_at != INF:
		return
	if _broken >= _jars.size() and _drained == 0 and not _jars.is_empty():
		game.stat_add("boss_atk_stumble", 1.0)
		game.stat_add("sekhmet_stumbles", 1.0)
		game.enemies.show_banner(String(boss_def["stumble_banner"]))
		game.effects.impact(position, radius * 2.5, Palette.DYN_SAND_LIGHT)
		_refill_at = game.elapsed + float(boss_def["stumble_time"]) + float(boss_def["refill_time"])
		_set_phase(Phase.STUMBLE)
	else:
		game.enemies.show_banner(String(boss_def["drained_banner"]))
		game.dynasty_rules().play_sound("sekhmet_roar", position)
		_refill_at = game.elapsed + float(boss_def["refill_time"])


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the landing circle, and out
## of her rakes.
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.LEAP_WINDUP or phase == Phase.LEAP_IN:
		var off := p - _to
		var reach := float(boss_def["leap_radius"]) + 24.0
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	if phase == Phase.RAKE:
		var off := p - position
		var reach := float(boss_def["rake_radius"]) + 20.0
		if off.length() < reach:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.0
	return Vector2.ZERO


## Body layer on `ci`: her sprite in the pose of her phase (pose 1 while she
## crouches or drinks), lifted on the leap's arc, a red glow in the Feast and
## the stumble's sway.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.LEAP_WINDUP, Phase.DRINK:
			pose = 1
	var lift := Vector2.ZERO
	if phase == Phase.LEAP_IN or phase == Phase.LEAP_OUT:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
		lift = Vector2(0.0, -float(boss_def["leap_height"]) * 4.0 * k * (1.0 - k))
	if phase == Phase.STUMBLE:
		lift = Vector2(sin(phase_time * 9.0) * 3.0, 0.0)
	if form == 3 and phase != Phase.STUMBLE:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.4), radius * 1.4, Color(Palette.DYN_CARNELIAN, 0.22))
	if not SpriteBank.draw_pose(ci, SekhmetData.SPRITE, pose, lift, flash > 0.0):
		LionessTempleGlyphs.draw_sekhmet(ci, lift, radius, flash > 0.0, form == 3 and phase != Phase.STUMBLE)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: her shadow stays on the ground while she leaps.
func _draw_under() -> void:
	super._draw_under()
	if phase == Phase.LEAP_IN or phase == Phase.LEAP_OUT:
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-radius, radius * 0.4), Vector2(radius * 2.0, radius * 0.7)), false, Color(0.0, 0.0, 0.0, 0.35))


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("sekhmet_red_wind_at", -1.0))
	var p3 := float(st.get("sekhmet_feast_at", -1.0))
	return "leaps %d (hits %d, by a pillar %d) | rakes %d (hits %d) | the Red Wind %s (her glyphs %d) | the Feast %s: jars %d set, %d broken, %d drained | stumbles %d | blocked hits %d, capped hits %d | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_leap", 0.0)), int(st.get("sekhmet_leap_hits", 0.0)), int(st.get("sekhmet_pillar_perches", 0.0)),
		int(st.get("boss_atk_rake", 0.0)), int(st.get("sekhmet_rake_hits", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("sekhmet_glyphs", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("sekhmet_jars_set", 0.0)), int(st.get("wine_jars_broken", 0.0)),
		int(st.get("sekhmet_jars_drained", 0.0)), int(st.get("sekhmet_stumbles", 0.0)),
		int(st.get("sekhmet_feast_dmg_blocked", 0.0)), int(st.get("sekhmet_feast_capped", 0.0)),
		int(st.get("player_dmg_from_" + SekhmetData.LEAP_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + SekhmetData.RAKE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + SekhmetData.LEAP_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + SekhmetData.RAKE_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
