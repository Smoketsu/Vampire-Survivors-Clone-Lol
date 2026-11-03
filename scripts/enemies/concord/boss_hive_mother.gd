## BossHiveMother — THE HIVE MOTHER, the boss of the Crash Site (Act IX, Stage
## 25; GDD §15.0 "The Hive Mother (Act IX)"; owner-approved proposal: "a vast
## queen grown into the crater. The Brood (egg waves and burrowers from every
## side), the Burrow (she dives under the arena and erupts beneath the ring on
## a telegraph), the Flight (she tears loose and takes to the air, raining
## acid)"). Loaded by name for the boss id "hive_mother"
## (EnemyDirector.CONCORD_BOSS_DIR + "boss_hive_mother.gd"); she arrives at
## 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat her like any enemy. A vast female insect queen in the figure style,
## her own purple chitin covering her completely. Every number is
## HiveMotherData.BOSS's; the phases and their rules are documented in
## HiveMotherData. Every attack is an enemy effect through the existing one
## paths: the eggs through CrashSiteDirector.lay_anywhere() (THE egg path), the
## burrowers spawn as BurrowerKit kinds, the eruption strikes through
## damage_unit() / damage_player() and leaves turf through Terraforming.seed(),
## the acid rain goes through AcidPools.lob() (THE acid path). Under the arena
## she is out of reach (Enemy.untargetable and ethereal, the existing one
## paths; damage_taken_mult() 0). The shared rules are created on first use
## (Game.concord_rules()), so --boss=hive_mother works on any stage (her eggs
## then hatch on their own; Nothing Hatched is the Crash Site's).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks
## Bone Beetles and Chitin (UnlockData, boss "hive_mother"); her fall shows a
## short ending text only (no epilogue, owner). Attack poses (BossPoseData,
## when the art has them): pose 1 while she rears for an egg wave, pose 3 as
## she bursts out of the ground; her Flight form is its own still
## (HiveMotherData.FLIGHT_SPRITE, with its glide strip); she sinks into the
## ground and rises out of it through SpriteBank.draw_rising().
## Determinism: the seeded gameplay RNG is never used (fixed angles turned by
## counters). Stats: boss_atk_<special>, hive_egg_waves, hive_eggs_laid,
## hive_burrower_waves, hive_burrowers, hive_dives, hive_eruptions,
## hive_erupt_hits, hive_erupt_on_you, hive_acid_volleys, hive_aloft_grazed,
## hive_phase2_at, hive_phase3_at, hive_mother_kill_time.
class_name BossHiveMother
extends Boss

## Her phases.
enum Form { BROOD = 1, BURROW = 2, FLIGHT = 3 }
## Her action within a phase.
enum Act { WALK, REAR, RECOVER, DIVE, UNDER, MOUND, FLY }

## px the autotest bot keeps beyond the eruption's edge (autotest hint only).
const DANGER_MARGIN: float = 26.0  # TUNING (not in GDD) autotest hint only
## px she is drawn above the ground while airborne.
const AIR_LIFT: float = 18.0  # TUNING (not in GDD) drawing only

## Current phase.
var form: Form = Form.BROOD
## Current action.
var act: Act = Act.WALK
## Seconds in the current action.
var act_time: float = 0.0
## Seconds until her next egg wave (the Brood).
var _egg_cd: float = 0.0
## Seconds until her next burrower wave (the Brood and the Burrow; INF in the Flight).
var _burrow_cd: float = 0.0
## Seconds she stays up before her next dive (the Burrow).
var _surface_cd: float = 0.0
## Seconds until her next acid volley (INF before the Flight).
var _acid_cd: float = INF
## Where the current mound shows and she erupts (world px).
var _mound_at: Vector2 = Vector2.ZERO
## Waves / volleys so far (turn the next one's angles; no RNG).
var _waves: int = 0
## Her walking speed (px/s).
var _base_speed: float = 40.0
## Her circling side in the Flight (+1 / -1, from her think slot).
var _side: float = 1.0
## Game time (s) she arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the Hive Mother at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = HiveMotherData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	form = Form.BROOD
	act = Act.WALK
	act_time = 0.0
	_egg_cd = float(boss_def["egg_first"])
	_burrow_cd = float(boss_def["burrowers_first"])
	_surface_cd = 0.0
	_acid_cd = INF
	_waves = 0
	_base_speed = move_speed
	_side = 1.0 if slot % 2 == 0 else -1.0
	_spawn_time = p_game.elapsed
	flies = false
	game.concord_rules().play_sound("hive_scream", position)  # The shared rules exist wherever she fights.
	game.enemies.boss_defeated.connect(_on_defeated)
	game.stat_add("boss_atk_egg_wave", 0.0)


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return HiveMotherData.SPECIALS


## True while she walks or flies at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return act == Act.WALK or act == Act.FLY


## Any removal leaves her solid and grounded (the pool reuses the node).
func deactivate() -> void:
	untargetable = false
	ethereal = false
	flies = false
	super.deactivate()


## Out of reach while she sinks, travels under the arena or waits under her
## mound; aloft a grounded melee blow deals flight_melee_taken of itself.
func damage_taken_mult(source: String) -> float:
	if act == Act.DIVE or act == Act.UNDER or act == Act.MOUND:
		return 0.0
	var m := super.damage_taken_mult(source)
	if flies and FallenAngelKit.grounded_melee(source):
		game.stat_add("hive_aloft_grazed", 1.0)
		m *= float(boss_def["flight_melee_taken"])
	return m


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: her phase machine (see the header and HiveMotherData).
func physics_step(delta: float) -> void:
	act_time += delta
	knockback = Vector2.ZERO
	_egg_cd -= delta
	_burrow_cd -= delta
	_surface_cd -= delta
	_acid_cd -= delta
	if form == Form.BROOD and hp <= max_hp * float(boss_def["phase2_hp"]):
		_enter_burrow()
	if form == Form.BURROW and act == Act.WALK and hp <= max_hp * float(boss_def["phase3_hp"]):
		_enter_flight()
	if form != Form.FLIGHT and _burrow_cd <= 0.0:
		_burrower_wave()
	match act:
		Act.WALK:
			_step_walk(delta)
		Act.REAR:
			_hold(delta)
			if act_time >= float(boss_def["egg_windup"]):
				_egg_wave()
				_set_act(Act.RECOVER)
		Act.RECOVER:
			_hold(delta)
			if act_time >= float(boss_def["recover_time"]):
				_set_act(Act.WALK)
		Act.DIVE:
			_hold(delta)
			if act_time >= float(boss_def["dive_time"]):
				_set_act(Act.UNDER)
		Act.UNDER:
			_step_under(delta)
			if act_time >= float(boss_def["under_time"]):
				_start_mound()
		Act.MOUND:
			_hold(delta)
			position = _mound_at
			if act_time >= float(boss_def["mound_time"]):
				_erupt()
		Act.FLY:
			_step_fly(delta)


## Walking (the Brood and the Burrow's surface time): the shared AI (her claws
## in reach) at her speed, faster from afar; an egg wave (the Brood) or a dive
## (the Burrow) starts when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var spd := _base_speed
	if position.distance_to(pl.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if form == Form.BROOD and _egg_cd <= 0.0:
		_egg_cd = float(boss_def["egg_every"])
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_act(Act.REAR)
	elif form == Form.BURROW and _surface_cd <= 0.0:
		_dive()


## Standing still during a windup or a recovery (the shared timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes action, resets its timer and redraws the pose.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# The Brood: egg waves and burrowers from every side
# =====================================================================================

## An egg wave: egg_count Infestation eggs on a ring around the necromancer
## (THE egg path; the egg cap applies).
func _egg_wave() -> void:
	var pl := game.nearest_player(position)
	var n := maxi(1, int(boss_def["egg_count"]))
	var base := float(_waves) * 0.9  # Turns each wave (no RNG).
	var made := 0
	for k in n:
		var a := base + TAU * float(k) / float(n)
		var dist := lerpf(float(boss_def["egg_min"]), float(boss_def["egg_max"]), float(k % 2))
		var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, 8.0)
		if CrashSiteDirector.lay_anywhere(game, at, "wave") != null:
			made += 1
	_waves += 1
	game.stat_add("boss_atk_egg_wave", 1.0)
	game.stat_add("hive_egg_waves", 1.0)
	game.stat_add("hive_eggs_laid", float(made))
	game.concord_rules().play_sound("hive_scream", position, 1.0)


## Burrowers from every side: burrowers_count of them on the spawn ring at even
## angles (under the hard cap); they tunnel in on their own (BurrowerKit).
func _burrower_wave() -> void:
	_burrow_cd = float(boss_def["burrowers_every"])
	var n := maxi(1, int(boss_def["burrowers_count"]))
	var base := float(_waves) * 0.6 + 0.4  # Turns each wave (no RNG).
	var made := 0
	for k in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		if game.enemies.spawn_at(ConcordEnemyData.BURROWER, game.enemies.ring_point(base + TAU * float(k) / float(n)), false) != null:
			made += 1
	_waves += 1
	game.stat_add("boss_atk_burrowers", 1.0)
	game.stat_add("hive_burrower_waves", 1.0)
	game.stat_add("hive_burrowers", float(made))


# =====================================================================================
# The Burrow: dive, travel under, the mound, the eruption
# =====================================================================================

## The Burrow begins: she dives at once.
func _enter_burrow() -> void:
	form = Form.BURROW
	game.stat_add("hive_phase2_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.shake(6.0)
	_dive()


## She sinks into the ground (out of reach from now until she erupts).
func _dive() -> void:
	untargetable = true
	ethereal = true
	phases_obstacles = true
	game.stat_add("boss_atk_burrow", 1.0)
	game.stat_add("hive_dives", 1.0)
	game.concord_rules().play_sound("burrow", position, 0.3)
	game.effects.ring(position, radius * 2.0, Color(0.36, 0.28, 0.20), 0.4)
	_set_act(Act.DIVE)


## Under the arena: she travels toward the nearest necromancer.
func _step_under(delta: float) -> void:
	_tick_timers(delta)
	var pl := game.nearest_player(position)
	var to := pl.position - position
	var step := float(boss_def["under_speed"]) * delta
	if to.length() > step:
		velocity = to.normalized() * float(boss_def["under_speed"])
		position += to.normalized() * step
	else:
		velocity = Vector2.ZERO
		position = pl.position


## The mound shows where the necromancer stands now (the telegraph).
func _start_mound() -> void:
	var pl := game.nearest_player(position)
	_mound_at = pl.position
	position = _mound_at
	game.effects.telegraph_circle(_mound_at, float(boss_def["erupt_radius"]), float(boss_def["mound_time"]), self)
	game.concord_rules().play_sound("burrow", _mound_at, 0.3)
	_set_act(Act.MOUND)


## She erupts beneath the ring: every grounded summon and necromancer within
## erupt_radius takes the eruption once; the broken ground turns to live turf.
func _erupt() -> void:
	var r := float(boss_def["erupt_radius"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.ally_grid.query(_mound_at, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(_mound_at) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["erupt_damage_summon"]) * mult * undead_damage_mult, HiveMotherData.ERUPT_SOURCE, self)
		game.stat_add("hive_erupt_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(_mound_at) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["erupt_damage"]) * mult, HiveMotherData.ERUPT_SOURCE, pl, self)
			game.stat_add("hive_erupt_on_you", 1.0)
	game.concord_rules().terraforming.seed(_mound_at, float(boss_def["erupt_turf"]), {"live": true, "tag": "eruption"})
	game.effects.impact(_mound_at, r, Color(0.40, 0.30, 0.20))
	game.shake(7.0)
	game.concord_rules().play_sound("hive_scream", _mound_at, 0.5)
	game.stat_add("boss_atk_eruption", 1.0)
	game.stat_add("hive_eruptions", 1.0)
	untargetable = false
	ethereal = false
	phases_obstacles = false
	position = game.arena.free_point(_mound_at, radius)
	_surface_cd = float(boss_def["surface_time"])
	_set_act(Act.RECOVER)


# =====================================================================================
# The Flight: aloft, raining acid
# =====================================================================================

## The Flight begins: she tears loose and takes to the air.
func _enter_flight() -> void:
	form = Form.FLIGHT
	flies = true
	phases_obstacles = true
	_acid_cd = float(boss_def["acid_first"])
	game.stat_add("hive_phase3_at", game.elapsed)
	game.stat_add("boss_atk_flight", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.CONCORD_HIVE)
	game.shake(8.0)
	game.concord_rules().play_sound("hive_scream", position)
	_set_act(Act.FLY)


## Aloft: she circles the nearest necromancer and rains acid on her cooldown.
func _step_fly(delta: float) -> void:
	_tick_timers(delta)
	var pl := game.nearest_player(position)
	var rel := position - pl.position
	var ang := rel.angle() if rel.length() > 1.0 else float(think_slot)
	ang += float(boss_def["hover_turn"]) * _side * delta
	var post := pl.position + Vector2.from_angle(ang) * float(boss_def["hover_radius"])
	var to := post - position
	var spd := float(boss_def["fly_speed"]) * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	var step := minf(to.length(), spd * delta)
	velocity = to.normalized() * spd if to.length() > 1.0 else Vector2.ZERO
	if step > 0.0:
		position += to.normalized() * step
	_update_facing()
	if _acid_cd <= 0.0:
		_acid_rain(pl)


## Acid rain: acid_globs globs fall through THE ACID PATH, the first on the
## necromancer's spot, the rest around him.
func _acid_rain(pl: Necromancer) -> void:
	_acid_cd = float(boss_def["acid_every"])
	if game.ultimates.player_untargetable():
		_acid_cd = 1.0
		return
	var acid := game.concord_rules().acid
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var n := maxi(1, int(boss_def["acid_globs"]))
	var base := float(_waves) * 0.8  # Turns each volley (no RNG).
	var from := position + Vector2(0.0, -AIR_LIFT)
	for k in n:
		var to := pl.position
		if k > 0:
			var a := base + TAU * float(k - 1) / float(maxi(1, n - 1))
			to += Vector2.from_angle(a) * lerpf(float(boss_def["acid_min"]), float(boss_def["acid_max"]), float(k % 2))
		acid.lob(from, to, {
			"flight": float(boss_def["acid_flight"]),
			"radius": float(boss_def["acid_radius"]),
			"life": float(boss_def["acid_life"]),
			"dps": float(boss_def["acid_dps"]) * mult,
			"impact": float(boss_def["acid_impact"]) * mult,
			"umult": undead_damage_mult,
			"source": HiveMotherData.ACID_SOURCE,
		})
	_waves += 1
	game.stat_add("boss_atk_acid_rain", 1.0)
	game.stat_add("hive_acid_volleys", 1.0)
	game.concord_rules().play_sound("acid_spit", position, 0.3)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue).
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 240.0, Palette.CONCORD_HIVE_BONE, 1.0)
	game.effects.ring(pos, 140.0, Palette.CONCORD_HIVE, 0.8)
	Juice.fx.burst(pos, Palette.CONCORD_HIVE_BONE, Palette.CONCORD_HIVE, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(HiveMotherData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + HiveMotherData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = HiveMotherData.LATE_ANNOUNCE if game.countdown_finished() else HiveMotherData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.CONCORD_HIVE_BONE)
	game.stats["hive_mother_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: off the mound while it shows (the
## acid is AcidPools', read through ConcordRules.danger_push()).
func danger_push(p: Vector2) -> Vector2:
	if act != Act.MOUND:
		return Vector2.ZERO
	var reach := float(boss_def["erupt_radius"]) + DANGER_MARGIN
	var rel := p - _mound_at
	var dist := rel.length()
	if dist >= reach:
		return Vector2.ZERO
	return (rel / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 3.0


## Body layer on `ci`: sinking into / rising out of the ground, a ripple under
## the arena, the mound, aloft her Flight form, else her still in the pose of
## her action (pose 1 rearing, pose 3 just burst up).
func _draw_body(ci: CanvasItem) -> void:
	var t := game.elapsed
	match act:
		Act.DIVE:
			var k := clampf(act_time / maxf(float(boss_def["dive_time"]), 0.01), 0.0, 1.0)
			if not SpriteBank.draw_rising(ci, HiveMotherData.SPRITE, Vector2.ZERO, 1.0 - k, false):
				_glyph(ci, Vector2(0.0, radius * k), 1.0 - k)
			BurrowerKit.draw_mound(ci, Vector2(0.0, radius * 0.6), radius * 1.2, k, t)
			return
		Act.UNDER:
			SpriteBank.draw_disc(ci, Vector2(0.0, 4.0), radius * 0.8 + 2.0 * sin(t * 10.0), Color(0.30, 0.24, 0.18, 0.5))
			return
		Act.MOUND:
			BurrowerKit.draw_mound(ci, Vector2.ZERO, float(boss_def["mound_radius"]), clampf(act_time / maxf(float(boss_def["mound_time"]), 0.01), 0.0, 1.0), t)
			return
	if flies:
		var lift := Vector2(0.0, -AIR_LIFT + 2.0 * sin(t * 2.0))
		if SpriteBank.draw(ci, HiveMotherData.FLIGHT_SPRITE, lift, flash > 0.0):
			return
		if SpriteBank.draw_pose(ci, HiveMotherData.SPRITE, 0, lift, flash > 0.0):
			return
		_glyph(ci, lift, 1.0)
		return
	if act == Act.RECOVER and _surface_cd > float(boss_def["surface_time"]) - 0.6:
		var k2 := clampf((float(boss_def["surface_time"]) - _surface_cd) / 0.4, 0.0, 1.0)  # She rises out of the ground.
		if k2 < 1.0 and SpriteBank.draw_rising(ci, HiveMotherData.SPRITE, Vector2.ZERO, k2, false):
			return
		if SpriteBank.draw_pose(ci, HiveMotherData.SPRITE, 3, Vector2.ZERO, flash > 0.0):
			return
	var pose := 1 if act == Act.REAR else 0
	if not SpriteBank.draw_pose(ci, HiveMotherData.SPRITE, pose, Vector2.ZERO, flash > 0.0):
		_glyph(ci, Vector2.ZERO, 1.0)


## Her code shape without the art: a purple queen with cream horns and gold
## eyes (`k` 0..1 how much of her shows).
func _glyph(ci: CanvasItem, o: Vector2, k: float) -> void:
	var r := radius * maxf(0.2, k)
	var fl := flash > 0.0
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.3), r * 1.25, Glyphs._c(Palette.CONCORD_INK, fl))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.3), r * 1.15, Glyphs._c(Palette.CONCORD_HIVE, fl))  # The egg-sac abdomen.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.7), r * 0.55, Glyphs._c(Palette.CONCORD_HIVE, fl))  # Her body and helm.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 1.5), Vector2(3.0, r * 0.6)), Glyphs._c(Palette.CONCORD_HIVE_BONE, fl))  # Horns.
	ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 1.5), Vector2(3.0, r * 0.6)), Glyphs._c(Palette.CONCORD_HIVE_BONE, fl))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.2, -r * 0.8), 2.0, Glyphs._c(Palette.GOLD, fl))  # Eyes.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.2, -r * 0.8), 2.0, Glyphs._c(Palette.GOLD, fl))


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen and act != Act.UNDER and act != Act.MOUND:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: aloft, her shadow on the ground.
func _draw_under() -> void:
	super._draw_under()
	if flies:
		var w := radius * 1.2
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, radius * 0.9 - w * 0.3), Vector2(w * 2.0, w * 0.6)), false, Color(0.0, 0.0, 0.0, 0.3))


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("hive_phase2_at", -1.0))
	var p3 := float(st.get("hive_phase3_at", -1.0))
	var kt := float(st.get("hive_mother_kill_time", -1.0))
	return "the Brood: egg waves %d (eggs %d), burrower waves %d (%d burrowers) | the Burrow %s: dives %d, eruptions %d (hits on summons %d, on you %d) | the Flight %s: acid volleys %d, aloft grazes %d | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("hive_egg_waves", 0.0)), int(st.get("hive_eggs_laid", 0.0)),
		int(st.get("hive_burrower_waves", 0.0)), int(st.get("hive_burrowers", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("hive_dives", 0.0)), int(st.get("hive_eruptions", 0.0)),
		int(st.get("hive_erupt_hits", 0.0)), int(st.get("hive_erupt_on_you", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("hive_acid_volleys", 0.0)), int(st.get("hive_aloft_grazed", 0.0)),
		("%.0f s after she arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + HiveMotherData.ERUPT_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + HiveMotherData.ACID_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + HiveMotherData.ERUPT_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + HiveMotherData.ACID_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
