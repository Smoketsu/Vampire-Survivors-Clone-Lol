## BossLilith — LILITH, QUEEN OF THE NIGHT, MOTHER OF DEMONS, the boss of the
## Palace of Silk and Ash (Act VI, Stage 17; GDD §15.0 "Lilith, Queen of the
## Night (Act VI)"; owner-approved proposal docs/act6/PROPOSAL.md "Stage 17";
## female, the approved Act VI figure style at its height). Loaded by name for
## the boss id "lilith" (EnemyDirector.INFERNO_BOSS_DIR + "boss_lilith.gd"); she
## arrives at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat her like any enemy. She flies (floating, over the
## obstacles and the pits) at the necromancer with the shared melee AI between
## her specials, faster when far. Every ability is telegraphed; numbers and the
## whole kit in LilithData:
##   * CHARM WAVE — an arc of the Bone Ring facing her is marked in hearts, then
##     every summon in it is charmed through the ONE charm path
##     (HordeDirector.charm() with opts ignore_cap / tint / name / source:
##     LilithData.WAVE_SOURCE); the most summons a wave takes and the arc's
##     width grow with her phase.
##   * THE KISS — a heart flies at the necromancer (LilithHazards); a summon in
##     its way catches it; on him it MARKS him: every heal turned into damage
##     for mark_time s (the one documented check in CombatResolver.heal_player()).
##   * DEMON CHILDREN — imps born from her spread wings.
##   * HER TRUE DEMON FORM (below phase3_hp): invulnerable while she changes,
##     then her demon sprite, a bigger body, faster, shorter cooldowns, harder
##     claws and THE WING STORM (a telegraphed circle around her: damage and
##     summons thrown out).
## Her charm waves are enemy effects on units (the Temptation path): summons get
## no act rule. Killing her drops the XP burst and the boss chest (the shared
## boss path), unlocks Temptation, Velvet Chains, the Succubus and Sweet
## Surrender (UnlockData, boss "lilith") and, on the Palace with no summon
## charmed from her arrival to her fall, counts for the achievement UNMOVED (run
## stat lilith_unmoved_kills; MetaProgress keeps the lifetime count). Forced onto
## another stage with --boss=lilith she creates Game.inferno (the charm path).
## Determinism: no RNG (the wave's summons by distance, ties in the ally grid's
## order; her children on fixed angles); no instance ids. Stats:
## boss_atk_<special>, lilith_wave_charms, lilith_wave_refused, lilith_children,
## lilith_phase2_at, lilith_phase3_at, lilith_spawn_time, lilith_kill_time,
## lilith_unmoved_kills, lilith_storm_hits (LilithHazards: the kisses).
class_name BossLilith
extends Boss

## Boss action phases.
enum Phase { WALK, WAVE_CAST, KISS_CAST, CHILDREN_CAST, STORM_CAST, CHANGING, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current action phase.
var phase_time: float = 0.0
## Fight phase: 0 (from arrival), 1 (below phase2_hp), 2 (her true form).
var stage: int = 0
## Seconds until her next charm wave.
var wave_cd: float = 0.0
## Seconds until her next kiss.
var kiss_cd: float = 0.0
## Seconds until her next birth of children.
var children_cd: float = 0.0
## Seconds until her next wing storm (true form only).
var storm_cd: float = 0.0
## The marked wave's centre (the necromancer when it was cast, world px).
var wave_center: Vector2 = Vector2.ZERO
## Unit direction from the wave's centre to the middle of its arc (toward her).
var wave_dir: Vector2 = Vector2.RIGHT
## Half-angle (rad) of the marked arc.
var wave_half: float = 0.0
## Her world-space pieces (a child of the EnemyDirector).
var hazards: LilithHazards = null
## Move speed of her glide in this form (px/s).
var _base_speed: float = 52.0
## Game time she arrived.
var _spawn_time: float = 0.0
## Temptation charms made this run when she arrived (Unmoved: none since).
var _charms_at_arrival: float = 0.0
## Summons inside the wave (scratch).
var _buf: Array = []


## Sets up Lilith at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = LilithData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	floating = true  # Winged: she flies over the pits and the obstacles.
	phases_obstacles = true
	z_index = 2
	p_game.inferno_rules()  # The charm path (created here when she is forced onto another stage).
	phase = Phase.WALK
	phase_time = 0.0
	stage = 0
	wave_cd = float(boss_def["first_wave"])
	kiss_cd = float(boss_def["first_kiss"])
	children_cd = float(boss_def["first_children"])
	storm_cd = float(boss_def["storm_cooldown"])
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	_charms_at_arrival = float(p_game.stats.get("charm_charms", 0.0))
	p_game.stats["lilith_spawn_time"] = p_game.elapsed
	hazards = LilithHazards.new()
	hazards.game = p_game
	hazards.boss = self
	p_game.enemies.add_child(hazards)
	p_game.enemies.boss_defeated.connect(_on_defeated)
	p_game.effects.impact(position, radius * 3.0, Palette.INFERNO_CHARM)
	p_game.shake(6.0)
	p_game.inferno.play_sound("charm_kiss", position)


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return LilithData.SPECIALS


## True while she glides at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of her art (engine-motion pivot): her true form in the last phase.
func motion_sprite_key() -> String:
	return LilithData.DEMON_SPRITE if stage >= 2 and phase != Phase.CHANGING else LilithData.SPRITE


## Invulnerable while she takes her true form.
func damage_taken_mult(source: String) -> float:
	if phase == Phase.CHANGING:
		return 0.0
	return super.damage_taken_mult(source)


## True while a charm wave's arc is marked (drawing).
func wave_marked() -> bool:
	return active and phase == Phase.WAVE_CAST


## 0 .. 1 over the wave's cast (drawing).
func wave_progress() -> float:
	return clampf(phase_time / maxf(0.01, float(boss_def["wave_cast"])), 0.0, 1.0)


## True while the wing storm is telegraphed (drawing).
func storm_marked() -> bool:
	return active and phase == Phase.STORM_CAST


## 0 .. 1 over the storm's cast (drawing).
func storm_progress() -> float:
	return clampf(phase_time / maxf(0.01, float(boss_def["storm_cast"])), 0.0, 1.0)


## Her death: the hearts drop with her.
func deactivate() -> void:
	if hazards != null:
		hazards.clear_all()
	super.deactivate()


# =====================================================================================
# The fight
# =====================================================================================

## Boss physics: her phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	var rate := float(boss_def["demon_cd_mult"]) if stage >= 2 else 1.0  # Cooldowns (s) shrink in true form.
	wave_cd -= delta / rate
	kiss_cd -= delta / rate
	children_cd -= delta / rate
	storm_cd -= delta / rate
	hazards.step(delta)
	_check_stage()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.WAVE_CAST:
			_hold()
			if phase_time >= float(boss_def["wave_cast"]):
				_charm_wave()
				_set_phase(Phase.RECOVER)
		Phase.KISS_CAST:
			_hold()
			if phase_time >= float(boss_def["kiss_cast"]):
				_blow_kiss()
				_set_phase(Phase.WALK)
		Phase.CHILDREN_CAST:
			_hold()
			if phase_time >= float(boss_def["children_cast"]):
				_birth()
				_set_phase(Phase.RECOVER)
		Phase.STORM_CAST:
			_hold()
			if phase_time >= float(boss_def["storm_cast"]):
				_storm()
				_set_phase(Phase.RECOVER)
		Phase.CHANGING:
			_hold()
			if phase_time >= float(boss_def["form_time"]):
				_become_demon()
				_set_phase(Phase.WALK)
		Phase.RECOVER:
			_hold()
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Her fight phase from her HP (banners once); the true form starts its change.
func _check_stage() -> void:
	if stage < 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		stage = 1
		game.stats["lilith_phase2_at"] = game.elapsed
		game.enemies.show_banner(String(boss_def["phase2_banner"]))
		wave_cd = minf(wave_cd, 2.0)
	if stage < 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		stage = 2
		game.stats["lilith_phase3_at"] = game.elapsed
		game.enemies.show_banner(String(boss_def["phase3_banner"]))
		game.shake(8.0)
		game.effects.impact(position, radius * 4.0, Palette.INFERNO_DEMON)
		_set_phase(Phase.CHANGING)


## Her true demon form (the change is over): bigger, faster, harder.
func _become_demon() -> void:
	radius = float(boss_def["demon_radius"])
	_base_speed *= float(boss_def["demon_speed_mult"])
	damage *= float(boss_def["demon_damage_mult"])
	storm_cd = minf(storm_cd, 2.0)
	game.effects.impact(position, radius * 3.5, Palette.INFERNO_LAVA)
	game.inferno.play_sound("brute_slam", position)


## Standing still during a cast or a recovery.
func _hold() -> void:
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Gliding: the shared walk and melee, faster when far; a special starts when
## ready (the wave first, then the storm, the children, the kiss).
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if wave_cd <= 0.0:
		_start_wave()
	elif stage >= 2 and storm_cd <= 0.0:
		storm_cd = float(boss_def["storm_cooldown"])
		game.effects.telegraph_circle(position, float(boss_def["storm_radius"]), float(boss_def["storm_cast"]), self)
		game.stat_add("boss_atk_wing_storm", 1.0)
		_set_phase(Phase.STORM_CAST)
	elif children_cd <= 0.0:
		children_cd = float(boss_def["children_cooldown"])
		game.stat_add("boss_atk_children", 1.0)
		_set_phase(Phase.CHILDREN_CAST)
	elif kiss_cd <= 0.0 and not game.ultimates.player_untargetable():
		kiss_cd = float(boss_def["kiss_cooldown"])
		game.stat_add("boss_atk_kiss", 1.0)
		_set_phase(Phase.KISS_CAST)


## Marks the arc of the ring facing her (the wave's telegraph).
func _start_wave() -> void:
	wave_cd = float(boss_def["wave_cooldown"]) * (float(boss_def["wave_cd_mult"]) if stage >= 1 else 1.0)
	wave_center = game.player.position
	var to := position - wave_center
	wave_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var halves: Array = boss_def["wave_half_angle"]
	wave_half = deg_to_rad(float(halves[mini(stage, halves.size() - 1)]))
	game.stat_add("boss_atk_charm_wave", 1.0)
	_set_phase(Phase.WAVE_CAST)


## The wave lands: every summon in the marked arc is charmed (the nearest the
## arc's middle first, at most wave_max[stage]), through the one charm path.
func _charm_wave() -> void:
	var inner := float(boss_def["wave_inner"])
	var outer := float(boss_def["wave_outer"])
	var maxes: Array = boss_def["wave_max"]
	var cap := int(maxes[mini(stage, maxes.size() - 1)])
	var mid := wave_center + wave_dir * (inner + outer) * 0.5
	game.ally_grid.query(wave_center, outer + UnitData.MAX_BLOCK_RADIUS, _buf)
	var cands: Array = []  # [distance to the arc's middle, summon].
	for u: SummonedUnit in _buf:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		var rel := u.position - wave_center
		var dist := rel.length()
		if dist < inner or dist > outer + u.radius:
			continue
		if absf(wave_dir.angle_to(rel)) > wave_half:
			continue
		cands.append([u.position.distance_to(mid), u])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var opts := {"ignore_cap": true, "tint": LilithData.WAVE_TINT, "name": LilithData.WAVE_NAME, "source": LilithData.WAVE_SOURCE}
	var taken := 0
	for c: Array in cands:
		if taken >= cap:
			break
		var u: SummonedUnit = c[1]
		if u.director != null and u.director.charm(u, self, float(boss_def["wave_charm"]), opts):
			taken += 1
		else:
			game.stat_add("lilith_wave_refused", 1.0)
	game.stat_add("lilith_wave_charms", float(taken))
	game.effects.ring(mid, outer * 0.5, Palette.INFERNO_CHARM, 0.5)
	game.shake(3.0)


## The kiss: a heart flies at the nearest standing necromancer.
func _blow_kiss() -> void:
	var target := game.player
	var best := INF
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) < best:
			best = pl.position.distance_to(position)
			target = pl
	var from := position + Vector2(0.0, -radius * 0.8)
	hazards.blow(from, target.position - from)
	game.inferno.play_sound("charm_kiss", from)


## Her children are born from her wings: imps on fixed angles at her sides.
func _birth() -> void:
	var counts: Array = boss_def["children_count"]
	var n := int(counts[mini(stage, counts.size() - 1)])
	var made := 0
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var side := -1.0 if i % 2 == 0 else 1.0  # Left wing, right wing.
		var a := (PI if side < 0.0 else 0.0) - side * 0.35 * float(i >> 1)  # Fanned up along each wing.
		var at := position + Vector2.from_angle(a) * (radius + float(boss_def["child_spread"])) + Vector2(0.0, -radius * 0.5)
		if game.enemies.spawn_at(String(boss_def["child_kind"]), at, false) != null:
			made += 1
	game.stat_add("lilith_children", float(made))
	game.effects.ring(position, radius * 2.5, Palette.INFERNO_DEMON_LIGHT, 0.5)
	game.inferno.play_sound("imp_cackle", position)


## The wing storm: everything in the circle around her is struck, summons
## thrown out.
func _storm() -> void:
	var r := float(boss_def["storm_radius"])
	var m := game.enemies.damage_mult * hit_mult()
	game.effects.impact(position, r, Palette.INFERNO_DEMON_LIGHT)
	game.shake(5.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["storm_damage_player"]) * m, LilithData.STORM_SOURCE, pl)
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var push := float(boss_def["storm_push"])
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD or u.position.distance_to(position) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["storm_damage_summon"]) * m, LilithData.STORM_SOURCE, self)
		game.stat_add("lilith_storm_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - position).normalized() if u.position.distance_squared_to(position) > 1.0 else Vector2.RIGHT
			u.position += away * game.arena.clear_length(u.position, away, push, u.radius)


# =====================================================================================
# Her fall, the autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated): her hearts drop, the ending, and
## Unmoved on the Palace when no summon was charmed since she arrived.
func _on_defeated() -> void:
	var pos := position
	if hazards != null:
		hazards.clear_all()
	game.stats["lilith_kill_time"] = game.elapsed - _spawn_time
	var unmoved := float(game.stats.get("charm_charms", 0.0)) <= _charms_at_arrival
	if unmoved and String(game.stage_def.get("id", "")) == SilkPalaceStage.ID:
		game.stat_add("lilith_unmoved_kills", 1.0)  # Unmoved (MetaData; MetaProgress counts it).
	game.effects.ring(pos, 200.0, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, 120.0, Palette.INFERNO_CHARM, 0.8)
	Juice.fx.burst(pos, Palette.INFERNO_CHARM, Palette.NECRO_GREEN, 24, 300.0, 1.0, 3.5)
	game.shake(10.0)
	game.enemies.show_banner(String(LilithData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + LilithData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = LilithData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)


## Danger hint for the autotest autopilot: off a flying heart's path, out of
## the wing storm's circle.
func danger_push(p: Vector2) -> Vector2:
	var push := hazards.danger_push(p) if hazards != null else Vector2.ZERO
	if phase == Phase.STORM_CAST:
		var reach := float(boss_def["storm_radius"]) + 24.0
		var off := p - position
		var dist := off.length()
		if dist < reach:
			push += (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.5
	return push


## Body layer on `ci`: her sprite (her true form in the last phase, flickering
## between the two while she changes); the glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var demon := stage >= 2 and (phase != Phase.CHANGING or int(phase_time * 8.0) % 2 == 1)
	var key := LilithData.DEMON_SPRITE if demon else LilithData.SPRITE
	if SpriteBank.draw(ci, key, Vector2.ZERO, flash > 0.0):
		return
	SilkPalaceGlyphs.draw_lilith(ci, Vector2.ZERO, radius, flash > 0.0, demon)


## Overlay layer on `ci`: the charm swirl in her raised hand while she casts,
## the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if phase == Phase.WAVE_CAST or phase == Phase.KISS_CAST:
		var k := clampf(phase_time / 0.5, 0.0, 1.0)
		InfernoGlyphs.draw_heart(ci, Vector2(radius * 0.9, -radius * 2.2), 4.0 + 3.0 * k, Color(Palette.INFERNO_CHARM, 0.6 + 0.4 * k))
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight (times relative to her arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("lilith_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	return "phase 2 %s, true form %s, killed %s | charm waves %d (summons charmed %d, refused %d) | kisses %d (blocked by the ring %d, landed %d, missed %d; heals turned into damage %d, dmg %d) | children births %d (imps %d) | wing storms %d (summon hits %d) | unmoved %d | dmg to you %d, to summons %d" % [
		rel.call("lilith_phase2_at"), rel.call("lilith_phase3_at"), "%.1fs" % float(st["lilith_kill_time"]) if st.has("lilith_kill_time") else "-",
		int(st.get("boss_atk_charm_wave", 0.0)), int(st.get("lilith_wave_charms", 0.0)), int(st.get("lilith_wave_refused", 0.0)),
		int(st.get("boss_atk_kiss", 0.0)), int(st.get("lilith_kisses_blocked", 0.0)), int(st.get("lilith_kisses_landed", 0.0)),
		int(st.get("lilith_kisses_missed", 0.0)), int(st.get("kiss_heals_turned", 0.0)), int(st.get("player_dmg_from_" + LilithData.KISS_SOURCE, 0.0)),
		int(st.get("boss_atk_children", 0.0)), int(st.get("lilith_children", 0.0)), int(st.get("boss_atk_wing_storm", 0.0)),
		int(st.get("lilith_storm_hits", 0.0)), int(st.get("lilith_unmoved_kills", 0.0)),
		int(st.get("player_dmg_from_boss", 0.0) + st.get("player_dmg_from_" + LilithData.STORM_SOURCE, 0.0) + st.get("player_dmg_from_" + LilithData.KISS_SOURCE, 0.0)),
		int(st.get("summon_dmg_from_boss", 0.0) + st.get("summon_dmg_from_" + LilithData.STORM_SOURCE, 0.0))]
