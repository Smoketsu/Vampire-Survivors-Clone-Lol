## BossKage — KAGE, MISTRESS OF THE HIDDEN HAND, the boss of the Burning
## Province (Act V, Stage 13; GDD §15.0 "Kage, Mistress of the Hidden Hand (Act
## V)"; owner-approved proposal docs/act5/PROPOSAL.md "Stage 13"; female, in the
## figure-redesign style). Loaded by name for the boss id "kage"
## (EnemyDirector.SHOGUNATE_BOSS_DIR + "boss_kage.gd"); she arrives at 17:00
## (3:00 left), at night. Extends Boss, so summons, spells and the spatial hash
## treat her like any enemy. Every ability is telegraphed; numbers in
## KageData.BOSS (its header has the whole kit):
##   * SHADOW CLONES — she stands in a swirl of smoke, vanishes and steps out at
##       one of several points around the necromancer, her clones
##       (KageCloneKit) at the others; light (SunCourse.light_at()) reveals a
##       clone as false and it dissolves. A new split dissolves the old clones.
##   * SMOKE FIELDS — she plants a field of smoke on the Bone Ring that BLINDS
##       every summon inside (ProvinceHazards, CombatResolver.blind_unit(): the
##       one summon blind path).
##   * CHAINED KUNAI — a telegraphed lane toward the summon farthest out on the
##       ring toward her; the kunai HOOKS the first summon on its line, holds it
##       through THE one compel path (SummonedUnit.compel() with no speed) and
##       the chain reels it to her side, out of the ring (an enemy effect on a
##       unit: the same on every stage). The necromancer in the lane is struck
##       and the kunai stops on him.
##   * Phases: more clones and two kunai at once below phase2_hp; "a hundred
##       shadows" (the most clones, faster splits) below phase3_hp.
## She walks and cuts with the shared melee AI between her specials, running
## when far (advance_range). Killing her drops a big XP burst and the boss
## chest, unlocks Hundred Shadows and Hidden Hand (UnlockData, boss "kage")
## and counts for the achievement No Shadow Unlit on the Province
## (ProvinceDirector). Forced onto another stage with --boss=kage she creates
## Game.shogunate (the light she is read through; off Act V the day reveals
## every clone at once). Determinism: only the seeded global RNG (which split
## point is hers, the split's turn); no instance ids. Stats: boss_atk_<special>,
## kage_splits, kage_clones_spawned (KageCloneKit: _revealed, _faded,
## _killed), kage_smoke_fields, kage_kunai_thrown, kage_kunai_hooks,
## kage_kunai_pulled, kage_kunai_player_hits, kage_phase2_at, kage_phase3_at,
## kage_killed.
class_name BossKage
extends Boss

## Boss action phases.
enum Phase { WALK, SPLIT_CAST, SMOKE_CAST, KUNAI_WINDUP, RECOVER }

## One chained kunai (flying, then reeling a hooked summon in).
class Kunai:
	extends RefCounted
	## Where it flies / hangs now (world px).
	var pos: Vector2 = Vector2.ZERO
	## Unit direction of its flight.
	var dir: Vector2 = Vector2.RIGHT
	## Distance (px) of flight left (0 = spent).
	var left: float = 0.0
	## The summon it hooked (null = still flying).
	var hooked: SummonedUnit = null
	## Generation of `hooked` when it was hooked.
	var gen: int = 0
	## Seconds it may still hold the hooked summon.
	var hold_left: float = 0.0

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Fight phase: 0 (from arrival), 1 (below phase2_hp), 2 (below phase3_hp).
var stage: int = 0
## Seconds until her next split.
var split_cd: float = 0.0
## Seconds until her next smoke field.
var smoke_cd: float = 0.0
## Seconds until her next kunai throw.
var kunai_cd: float = 0.0
## Her live clones and their generations (dissolved at the next split or her death).
var _clones: Array[Enemy] = []
## Generation of each `_clones` member when it was spawned.
var _clone_gen: PackedInt32Array = PackedInt32Array()
## Lanes aimed at the current throw (unit directions; one or kunai_pair).
var _aims: Array[Vector2] = []
## Kunai in flight or reeling.
var _kunai: Array[Kunai] = []
## Game times (s) her smoke fields end (at most smoke_max at once).
var _fields: PackedFloat32Array = PackedFloat32Array()
## Move speed of her walk (px/s).
var _base_speed: float = 66.0


## Sets up Kage at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = KageData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	p_game.shogunate_rules()  # The light that reveals her clones (created here when she is forced onto another stage).
	phase = Phase.WALK
	phase_time = 0.0
	stage = 0
	split_cd = float(boss_def["first_split"])
	smoke_cd = float(boss_def["first_smoke"])
	kunai_cd = float(boss_def["first_kunai"])
	_clones.clear()
	_clone_gen = PackedInt32Array()
	_kunai.clear()
	_aims.clear()
	_fields = PackedFloat32Array()
	_base_speed = move_speed
	p_game.effects.impact(position, radius * 3.0, Palette.SHOGUN_INDIGO_LIGHT)
	p_game.shake(5.0)
	p_game.shogunate.play_sound("smoke_puff", position)


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return KageData.SPECIALS


## True while she walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return KageData.SPRITE


## Her death: the clones go with her, the kunai fall; counted for the stage.
func deactivate() -> void:
	if active and hp <= 0.0:
		game.stat_add("kage_killed", 1.0)
	_dissolve_clones()
	_release_all()
	super.deactivate()


# =====================================================================================
# The fight
# =====================================================================================

## Boss physics: her phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	split_cd -= delta
	smoke_cd -= delta
	kunai_cd -= delta
	_step_kunai(delta)
	_check_stage()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.SPLIT_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["split_cast"]):
				_split()
				_set_phase(Phase.WALK)
		Phase.SMOKE_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["smoke_cast"]):
				_plant_smoke()
				_set_phase(Phase.WALK)
		Phase.KUNAI_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["kunai_telegraph"]):
				_throw_kunai()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Her fight phase from her HP (banners once).
func _check_stage() -> void:
	if stage < 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		stage = 1
		game.stat_add("kage_phase2_at", game.elapsed)
		game.enemies.show_banner(String(boss_def["phase2_banner"]))
		split_cd = minf(split_cd, 1.5)
	if stage < 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		stage = 2
		game.stat_add("kage_phase3_at", game.elapsed)
		game.enemies.show_banner(String(boss_def["phase3_banner"]))
		game.shake(6.0)
		split_cd = minf(split_cd, 1.0)


## Walking: the shared walk and melee, running when far; a split, a smoke
## field or a kunai throw start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if split_cd <= 0.0:
		_start_split()
	elif kunai_cd <= 0.0 and _kunai.is_empty() and _aim_kunai():
		_start_kunai()
	elif smoke_cd <= 0.0 and _live_fields() < int(boss_def["smoke_max"]):
		_start_smoke()


## Standing still during a cast / windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


# --- Shadow clones -----------------------------------------------------------------

## She stands in her smoke (the telegraph of the split).
func _start_split() -> void:
	split_cd = float(boss_def["split_cooldown"]) * (float(boss_def["phase3_cd_mult"]) if stage >= 2 else 1.0)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.effects.ring(position, radius * 2.4, Palette.SHOGUN_INDIGO_LIGHT, float(boss_def["split_cast"]))
	game.stat_add("boss_atk_split", 1.0)
	_set_phase(Phase.SPLIT_CAST)


## She vanishes and steps out at one of the split points; her clones at the
## others (see the header). The old clones dissolve first.
func _split() -> void:
	_dissolve_clones()
	var counts: Array = boss_def["clone_count"]
	var n := int(counts[clampi(stage, 0, counts.size() - 1)])  # Clones this split.
	var c := game.player.position  # Around the necromancer.
	var base := randf() * TAU  # The split's turn (seeded).
	var real := randi() % (n + 1)  # Which point is hers (seeded).
	var r := float(boss_def["split_radius"])
	var rules := game.shogunate_rules()
	for i in n + 1:
		var at := game.arena.free_point(c + Vector2.from_angle(base + TAU * float(i) / float(n + 1)) * r, radius)
		game.effects.impact(at, 26.0, Palette.SHOGUN_INDIGO)
		rules.play_sound("smoke_puff", at)
		if i == real:
			position = at
			continue
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			continue
		var e := game.enemies.spawn_at(ProvinceEnemyData.KAGE_CLONE, at, false)
		if e == null:
			continue
		if e.kit is KageCloneKit:
			(e.kit as KageCloneKit).begin(float(boss_def["clone_life"]), float(boss_def["reveal_light"]),
					float(boss_def["reveal_time"]), float(boss_def["clone_fade"]))
		_clones.append(e)
		_clone_gen.append(e.generation)
		game.stat_add("kage_clones_spawned", 1.0)
	game.stat_add("kage_splits", 1.0)
	rules.play_sound("kage_split", position)
	queue_redraw()


## Takes every live clone off the field (no kill).
func _dissolve_clones() -> void:
	for i in _clones.size():
		var e := _clones[i]
		if e.active and e.generation == _clone_gen[i]:
			game.enemies.despawn(e)
	_clones.clear()
	_clone_gen = PackedInt32Array()


## Her clones still on the field.
func clones_alive() -> int:
	var n := 0
	for i in _clones.size():
		if _clones[i].active and _clones[i].generation == _clone_gen[i]:
			n += 1
	return n


# --- Smoke fields ------------------------------------------------------------------

## She stands planting a smoke field.
func _start_smoke() -> void:
	smoke_cd = float(boss_def["smoke_cooldown"])
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_smoke", 1.0)
	_set_phase(Phase.SMOKE_CAST)


## A smoke field on the Bone Ring, on her side of the necromancer.
func _plant_smoke() -> void:
	var c := game.player.position
	var to := position - c
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var at := c + dir * float(boss_def["smoke_ring"])
	var life := float(boss_def["smoke_life"])
	game.enemies.province_hazards().add_smoke(at, float(boss_def["smoke_radius"]), life, float(boss_def["smoke_blind"]),
			float(boss_def["smoke_check"]), float(boss_def["smoke_blind"]), "kage_smoke")
	_fields.append(game.elapsed + life)
	game.stat_add("kage_smoke_fields", 1.0)
	game.shogunate_rules().play_sound("smoke_puff", at)


## Her smoke fields still hanging (expired ones dropped).
func _live_fields() -> int:
	var keep := PackedFloat32Array()
	for t in _fields:
		if t > game.elapsed:
			keep.append(t)
	_fields = keep
	return _fields.size()


# --- Chained kunai -----------------------------------------------------------------

## Picks the lanes of the next throw: the summon farthest out on the ring toward
## her (the nearest to her within kunai_range), a second one from phase 2;
## the necromancer when no summon is in reach. False when nothing is in reach.
func _aim_kunai() -> bool:
	_aims.clear()
	var reach := float(boss_def["kunai_range"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	var second: SummonedUnit = null
	var best_d := INF
	var second_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.is_compelled():
			continue
		var dd := u.position.distance_to(position)
		if dd > reach:
			continue
		if dd < best_d:
			second = best
			second_d = best_d
			best = u
			best_d = dd
		elif dd < second_d:
			second = u
			second_d = dd
	if best != null:
		_aims.append((best.position - position).normalized())
		if stage >= 1 and second != null and int(boss_def["kunai_pair"]) > 1:
			_aims.append((second.position - position).normalized())
		return true
	var to_p := game.player.position - position
	if to_p.length() <= reach and to_p.length() > 1.0:
		_aims.append(to_p.normalized())
		return true
	return false


## The telegraphed lanes of the throw.
func _start_kunai() -> void:
	kunai_cd = float(boss_def["kunai_cooldown"])
	var lane_len := float(boss_def["kunai_length"])  # px.
	for a in _aims:
		var l := game.arena.clear_length(position, a, lane_len, 4.0)
		game.effects.telegraph_line(position, position + a * l, float(boss_def["kunai_width"]) * 2.0, float(boss_def["kunai_telegraph"]), self)
	motion_lunge(_aims[0] if not _aims.is_empty() else Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_kunai", 1.0)
	_set_phase(Phase.KUNAI_WINDUP)


## The kunai leave her hand along the lanes.
func _throw_kunai() -> void:
	var lane_len := float(boss_def["kunai_length"])  # px.
	for a in _aims:
		var k := Kunai.new()
		k.pos = position + a * radius
		k.dir = a
		k.left = game.arena.clear_length(position, a, lane_len, 4.0)
		_kunai.append(k)
		game.stat_add("kage_kunai_thrown", 1.0)
	motion_lunge(_aims[0] if not _aims.is_empty() else Vector2.ZERO, MotionData.POWER_SHOT)
	game.shogunate_rules().play_sound("kunai_chain", position)


## Flies every kunai (it hooks the first summon on its line or strikes the
## necromancer) and reels every hooked summon in (see the header).
func _step_kunai(delta: float) -> void:
	if _kunai.is_empty():
		return
	queue_redraw()  # The chains (visual only).
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	var hw := float(boss_def["kunai_width"]) * 0.5
	var i := 0
	while i < _kunai.size():
		var k := _kunai[i]
		if k.hooked != null:
			if _reel(k, delta, mult):
				i += 1
			else:
				_kunai.remove_at(i)
			continue
		var step_len := minf(float(boss_def["kunai_speed"]) * delta, k.left)
		k.pos += k.dir * step_len
		k.left -= step_len
		var done := k.left <= 0.0
		for pl in game.all_players:  # (Co-op: the first necromancer on the line.)
			if not done and pl.position.distance_to(k.pos) <= hw + pl.radius:
				game.combat.damage_player(float(boss_def["kunai_damage_player"]) * mult, KageData.KUNAI_SOURCE, pl)
				game.stat_add("kage_kunai_player_hits", 1.0)
				done = true
		if not done:
			game.ally_grid.query(k.pos, hw + UnitData.MAX_BLOCK_RADIUS, _tmp)
			for u: SummonedUnit in _tmp:
				if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
					continue
				if u.position.distance_to(k.pos) > hw + u.radius or u.is_compelled():
					continue
				if u.compel(u.position, game.elapsed + float(boss_def["pull_hold"]), 0.0):
					k.hooked = u
					k.gen = u.generation
					k.hold_left = float(boss_def["pull_hold"])
					game.combat.damage_unit(u, float(boss_def["kunai_damage_summon"]) * mult * undead_damage_mult, KageData.KUNAI_SOURCE, self)
					game.stat_add("kage_kunai_hooks", 1.0)
					game.effects.ring(u.position, u.radius * 1.6, ShogunateGlyphs.STEEL, 0.25)
				break
		if k.hooked == null and done:
			_kunai.remove_at(i)
			continue
		i += 1


## Reels hooked summon `k.hooked` to her side; false when the chain lets go
## (it arrived, it died, the hold ran out).
func _reel(k: Kunai, delta: float, mult: float) -> bool:
	var u := k.hooked
	if not u.active or u.generation != k.gen or not u.is_compelled():
		return false
	k.hold_left -= delta
	var side := u.position - position
	var dist := side.length()
	var want := radius + u.radius + 4.0  # Pulled against her side.
	if dist > want:
		u.position = u.position.move_toward(position + side / dist * want, float(boss_def["pull_speed"]) * delta)
		k.pos = u.position
	if u.position.distance_to(position) <= want + 2.0:
		game.combat.damage_unit(u, float(boss_def["pull_damage"]) * mult * undead_damage_mult, KageData.KUNAI_SOURCE, self)
		game.stat_add("kage_kunai_pulled", 1.0)
		_let_go(k)
		return false
	if k.hold_left <= 0.0:
		_let_go(k)
		return false
	return true


## The chain opens: the hooked summon is free again (the compel path ends).
func _let_go(k: Kunai) -> void:
	if k.hooked != null and k.hooked.active and k.hooked.generation == k.gen:
		k.hooked.compel_until = minf(k.hooked.compel_until, game.elapsed)
	k.hooked = null


## Every chain opens (her death).
func _release_all() -> void:
	for k in _kunai:
		_let_go(k)
	_kunai.clear()


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: sideways out of a kunai lane.
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.KUNAI_WINDUP:
		for a in _aims:
			var rel := p - position
			var along := rel.dot(a)
			if along > -10.0 and along < float(boss_def["kunai_length"]) + 20.0:
				var side := rel - a * along
				if side.length() < float(boss_def["kunai_width"]) + 26.0:
					return side.normalized() if side.length() > 0.5 else a.orthogonal()
	return Vector2.ZERO


## Body layer on `ci`: her sprite; her glyph without art. During the split's
## cast she fades into her smoke.
func _draw_body(ci: CanvasItem) -> void:
	var a := 1.0
	if phase == Phase.SPLIT_CAST:
		a = 1.0 - 0.6 * clampf(phase_time / float(boss_def["split_cast"]), 0.0, 1.0)
	var tint := Color(1.0, 1.0, 1.0, a)
	if SpriteBank.draw(ci, KageData.SPRITE, Vector2.ZERO, flash > 0.0, tint):
		return
	ProvinceGlyphs.draw_kage(ci, Vector2.ZERO, radius, flash > 0.0, tint)


## Overlay layer on `ci`: the chains to her kunai, the smoke swirl of a split,
## the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if not _kunai.is_empty():
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # World axes (her node is mirrored).
		for k in _kunai:
			ProvinceGlyphs.draw_chain(ci, Vector2(0.0, -radius * 0.6), k.pos - position, k.hooked != null)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if phase == Phase.SPLIT_CAST or phase == Phase.SMOKE_CAST:
		ProvinceGlyphs.draw_smoke(ci, Vector2(0.0, -radius * 0.4), radius * 1.6, 0.8, game.elapsed)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("kage_phase2_at", -1.0))
	var p3 := float(st.get("kage_phase3_at", -1.0))
	return "splits %d (clones %d: revealed by light %d, faded %d, killed %d) | smoke fields %d (summons blinded %d) | kunai %d (hooked %d, pulled out %d, hit you %d) | phase 2 %s, phase 3 %s | killed %d | dmg to you %d, to summons %d" % [
		int(st.get("kage_splits", 0.0)), int(st.get("kage_clones_spawned", 0.0)), int(st.get("kage_clones_revealed", 0.0)),
		int(st.get("kage_clones_faded", 0.0)), int(st.get("kage_clones_killed", 0.0)), int(st.get("kage_smoke_fields", 0.0)),
		int(st.get("summon_blinds_kage_smoke", 0.0)), int(st.get("kage_kunai_thrown", 0.0)), int(st.get("kage_kunai_hooks", 0.0)),
		int(st.get("kage_kunai_pulled", 0.0)), int(st.get("kage_kunai_player_hits", 0.0)),
		("from %d:%02d" % [floori(p2 / 60.0), int(p2) % 60]) if p2 >= 0.0 else "no",
		("from %d:%02d" % [floori(p3 / 60.0), int(p3) % 60]) if p3 >= 0.0 else "no", int(st.get("kage_killed", 0.0)),
		int(st.get("player_dmg_from_" + KageData.KUNAI_SOURCE, 0.0) + st.get("player_dmg_from_boss", 0.0) + st.get("player_dmg_from_kage_clone", 0.0)),
		int(st.get("summon_dmg_from_" + KageData.KUNAI_SOURCE, 0.0) + st.get("summon_dmg_from_boss", 0.0) + st.get("summon_dmg_from_kage_clone", 0.0))]
