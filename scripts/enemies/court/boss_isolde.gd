## BossIsolde — ISOLDE VANE, THE WITCH OF THE RED MOON, the boss of the
## Witchwood (Act VII, Stage 20; GDD §15.0 "Isolde Vane, the Witch of the Red
## Moon (Act VII)"; owner-approved proposal: "phase 1, hex circles on the ring
## and cauldron bombs that leave healing pools for her thralls; phase 2, she
## splits into three sisters, and all three must fall within 10 s of each other
## or the fallen ones rise again; phase 3, she calls the Blood Moon and keeps it
## up until she falls"). Female, in the figure-redesign style. Loaded by name
## for the boss id "isolde" (EnemyDirector.COURT_BOSS_DIR + "boss_isolde.gd");
## she arrives at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat her like any enemy while she fights. Numbers in
## IsoldeData (its header tells the fight):
##   * THE WITCH: the shared walk and melee (striding faster when far); HEX
##     CIRCLES ON THE RING through WitchHexes.cast_circle() (the witches' one
##     circle path; under summons spread around the ring); CAULDRON BOMBS
##     (a telegraphed circle, a splash through OlympusHits.circle(), and a blood
##     pool through WitchHexes.open_pool(), the one pool path); THRALL CALLS
##     (blood thralls to drink the pools).
##   * THE THREE SISTERS: at phase2_hp she vanishes into three sisters
##     (WitchwoodEnemyData "isolde_sister", IsoldeSisterKit), herself hidden
##     among them, UNTARGETABLE (Enemy.untargetable: out of the enemy grid; and
##     damage_taken_mult() is 0), following their centre. Their lives are her
##     bar between phase2_hp and phase3_hp in three; the HUD's one boss bar
##     reads her phase 3 share plus what they have left. on_sister_down()
##     counts each fall: all three down within sisters_window s ends the phase
##     (and within coven_break s earns The Coven Breaks: stat
##     witchwood_coven_breaks, MetaProgress counts the runs); a sister down
##     longer than the window while another stands rises where she fell
##     (rise_hp of her life, less for each earlier rise, at least rise_min);
##     after sabbath_wane s the fallen no longer rise.
##   * THE RED MOON: she reforms where the last sister fell with her phase 3
##     share and calls the Blood Moon: BloodMoon.force(moon_hold) every tick
##     while she lives (THE moon's own path: x2 feeding, werebeasts, covens);
##     faster circles and more bombs; a harder, quicker stride.
## Killing her drops the boss XP burst and the boss chest; slaying her unlocks
## Hex Circle and Moonlit Rite (UnlockData, boss "isolde"). Determinism: the
## seeded global RNG only (where the bombs scatter). Stats: boss_atk_<special>,
## isolde_circles, isolde_bombs, isolde_bomb_hits, isolde_thralls,
## isolde_phase2_at, isolde_phase3_at, isolde_sister_falls, isolde_sisters_risen,
## isolde_window_spread (s, the three falls that ended the phase),
## isolde_sabbath_waned, isolde_moon_time, witchwood_coven_breaks.
class_name BossIsolde
extends Boss

## Boss action phases (within her forms).
enum Phase { WALK, CAST, BOMB_WINDUP, RECOVER, SISTERS }

## One cauldron bomb in the air.
class Bomb:
	extends RefCounted
	## Where it lands (world px).
	var at: Vector2 = Vector2.ZERO
	## Game time (s) it lands.
	var lands: float = 0.0

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Her form: 1 the Witch, 2 the Three Sisters, 3 the Red Moon.
var form: int = 1
## Seconds until her next ring of hex circles.
var circle_cd: float = 0.0
## Seconds until her next cauldron bombs.
var bomb_cd: float = 0.0
## Seconds until her next thrall call.
var thrall_cd: float = 0.0
## Her three sisters (index 0..2; null before the split).
var sisters: Array[Enemy] = [null, null, null]
## Their generations (stale guard).
var sister_gen: PackedInt32Array = PackedInt32Array([0, 0, 0])
## Each sister's full life (her bar share).
var sister_max: float = 1.0
## Game time each sister fell (-1 while she stands).
var down_at: PackedFloat32Array = PackedFloat32Array([-1.0, -1.0, -1.0])
## Where each sister fell (world px).
var down_pos: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
## Times each sister has risen.
var risen: PackedInt32Array = PackedInt32Array([0, 0, 0])
## Game time of the split.
var split_at: float = 0.0
## True once the sabbath waned (the fallen no longer rise).
var waned: bool = false
## Cauldron bombs in the air.
var _bombs: Array[Bomb] = []
## Move speed of her current form (px/s).
var _base_speed: float = 50.0
## Summons she means to curse (locked at the cast's start).
var _circle_at: PackedVector2Array = PackedVector2Array()


## Sets up Isolde at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = IsoldeData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	circle_cd = float(boss_def["first_circle"])
	bomb_cd = float(boss_def["first_bomb"])
	thrall_cd = float(boss_def["first_thralls"])
	sisters = [null, null, null]
	sister_gen = PackedInt32Array([0, 0, 0])
	down_at = PackedFloat32Array([-1.0, -1.0, -1.0])
	risen = PackedInt32Array([0, 0, 0])
	waned = false
	_bombs.clear()
	_base_speed = move_speed
	p_game.court_rules().witch_hexes()  # Her circles and pools use the witches' paths (on another stage too, --boss=isolde).


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return IsoldeData.SPECIALS


## True while she walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of her art (engine-motion pivot, the walk strip).
func motion_sprite_key() -> String:
	return "bosses/isolde"


## Hidden among her sisters she takes no damage (see the header).
func damage_taken_mult(source: String) -> float:
	if form == 2:
		return 0.0
	return super.damage_taken_mult(source)


## Her removal clears her bombs in flight (she cannot fall while hidden among
## her sisters, so no sister outlives her fight).
func deactivate() -> void:
	_bombs.clear()
	super.deactivate()


# =====================================================================================
# The fight
# =====================================================================================

## Boss physics: her form and phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	circle_cd -= delta
	bomb_cd -= delta
	thrall_cd -= delta
	_step_bombs()
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_split()
	if form == 2:
		_step_sisters(delta)
		return
	if form == 3:
		game.court_rules().moon.force(float(boss_def["moon_hold"]))  # THE moon's own path: up until she falls.
		game.stat_add("isolde_moon_time", delta)
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.CAST:
			_hold(delta)
			if phase_time >= float(boss_def["cast_windup"]):
				_curse_ring()
				_set_phase(Phase.RECOVER)
		Phase.BOMB_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["cast_windup"]):
				_throw_bombs()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)
		_:
			_set_phase(Phase.WALK)


## Walking: the shared walk and melee, striding faster when far; a ring of
## circles, a volley of bombs or a thrall call when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if thrall_cd <= 0.0:
		_call_thralls()
	if circle_cd <= 0.0 and _pick_circles():
		circle_cd = float(boss_def["circle_every_p3"] if form == 3 else boss_def["circle_every"])
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		game.stat_add("boss_atk_hex_circle", 1.0)
		_set_phase(Phase.CAST)
	elif bomb_cd <= 0.0 and dist <= float(boss_def["advance_range"]) + 120.0:
		bomb_cd = float(boss_def["bomb_every_p3"] if form == 3 else boss_def["bomb_every"])
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		game.stat_add("boss_atk_cauldron_bomb", 1.0)
		_set_phase(Phase.BOMB_WINDUP)


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
# The Witch: circles, bombs, thralls
# =====================================================================================

## Picks the summons of the ring she will curse: spread around the necromancer
## (the nearest summon in each of `n` arcs within circle_reach of her). False
## when there is none.
func _pick_circles() -> bool:
	_circle_at = PackedVector2Array()
	var n := int(boss_def["circle_count_p3"] if form == 3 else boss_def["circle_count"])
	var reach := float(boss_def["circle_reach"])
	var pp := game.player.position
	var best: Array = []  # Per arc: [distance to the necromancer, position].
	for k in n:
		best.append([INF, Vector2.ZERO])
	game.ally_grid.query(pp, 200.0, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) > reach + 200.0:
			continue
		var rel := u.position - pp
		var arc := clampi(int(floorf(fposmod(rel.angle() + PI, TAU) / TAU * float(n))), 0, n - 1)
		var dd := rel.length()
		if dd < float(best[arc][0]):
			best[arc] = [dd, u.position]
	for b in best:
		if float(b[0]) < INF:
			_circle_at.append(b[1])
	return not _circle_at.is_empty()


## The circles fall on the ring (WitchHexes.cast_circle(), the one circle path).
func _curse_ring() -> void:
	var hx := game.court_rules().witch_hexes()
	for at in _circle_at:
		hx.cast_circle(at, float(boss_def["circle_radius"]), float(boss_def["circle_windup"]), float(boss_def["circle_time"]),
				float(boss_def["circle_heal"]), float(boss_def["circle_drain"]), self, IsoldeData.CIRCLE_TAG)
	game.stat_add("isolde_circles", float(_circle_at.size()))
	game.court_rules().play_sound("isolde_cackle", position, 2.0)


## Lobs her cauldron bombs: one at the necromancer, the rest scattered round
## him (seeded RNG), each a glowing circle until it lands.
func _throw_bombs() -> void:
	var n := int(boss_def["bomb_count_p3"] if form == 3 else boss_def["bomb_count"])
	var pp := game.player.position
	var fall := float(boss_def["bomb_fall"])
	for i in n:
		var at := pp
		if i > 0:
			at = pp + Vector2.from_angle(randf() * TAU) * randf_range(40.0, float(boss_def["bomb_scatter"]))
		at = game.arena.free_point(at, 8.0)
		var b := Bomb.new()
		b.at = at
		b.lands = game.elapsed + fall
		_bombs.append(b)
		game.effects.telegraph_circle(at, float(boss_def["bomb_radius"]), fall, self)
	game.stat_add("isolde_bombs", float(n))


## Bombs that land: a splash on everyone under them, then a blood pool.
func _step_bombs() -> void:
	if _bombs.is_empty():
		return
	var i := 0
	var mult := game.enemies.damage_mult * hit_mult()
	while i < _bombs.size():
		var b := _bombs[i]
		if game.elapsed < b.lands:
			i += 1
			continue
		_bombs.remove_at(i)
		var r := float(boss_def["bomb_radius"])
		game.stat_add("isolde_bomb_hits", float(OlympusHits.circle(game, b.at, r, float(boss_def["bomb_damage_player"]) * mult,
				float(boss_def["bomb_damage_summon"]) * mult, IsoldeData.BOMB_SOURCE, self, 0.0, _tmp)))
		game.court_rules().witch_hexes().open_pool(b.at, float(boss_def["pool_radius"]), float(boss_def["pool_life"]), IsoldeData.POOL_TAG)
		game.effects.impact(b.at, r, Palette.COURT_BLOOD)
		game.court_rules().play_sound("blood_burst", b.at, 0.15)


## Her thralls come to drink: thrall_count blood thralls around her (under
## the hard cap).
func _call_thralls() -> void:
	thrall_cd = float(boss_def["thrall_every"])
	var made := 0
	for i in int(boss_def["thrall_count"]):
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := position + Vector2.from_angle(TAU * float(i) / float(boss_def["thrall_count"])) * (radius + 40.0)
		if game.enemies.spawn_at(CourtEnemyData.BLOOD_THRALL, game.arena.free_point(at, 8.0), false) != null:
			made += 1
	game.stat_add("boss_atk_thrall_call", 1.0)
	game.stat_add("isolde_thralls", float(made))


# =====================================================================================
# The Three Sisters
# =====================================================================================

## She splits: three sisters around her, herself hidden among them.
func _split() -> void:
	form = 2
	split_at = game.elapsed
	_bombs.clear()
	game.stat_add("isolde_phase2_at", game.elapsed)
	game.stat_add("boss_atk_sisters", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.COURT_BLOOD_LIGHT)
	game.court_rules().play_sound("isolde_cackle", position)
	game.shake(5.0)
	sister_max = maxf(1.0, max_hp * (float(boss_def["phase2_hp"]) - float(boss_def["phase3_hp"])) / 3.0)
	hp = max_hp * float(boss_def["phase2_hp"])
	untargetable = true
	velocity = Vector2.ZERO
	for i in 3:
		var at := game.arena.free_point(position + Vector2.from_angle(TAU * float(i) / 3.0 - PI * 0.5) * float(boss_def["sister_spread"]), 14.0)
		_raise_sister(i, at, 1.0)
	_set_phase(Phase.SISTERS)


## Sister `i` appears at `at` with `share` of her life.
func _raise_sister(i: int, at: Vector2, share: float) -> void:
	var s := game.enemies.spawn_at(IsoldeData.SISTER, at, false)
	if s == null:
		return
	s.max_hp = sister_max
	s.hp = sister_max * share
	if s.kit is IsoldeSisterKit:
		(s.kit as IsoldeSisterKit).set_index(i)
	sisters[i] = s
	sister_gen[i] = s.generation
	down_at[i] = -1.0
	game.effects.spawn_ring(at, Palette.COURT_BLOOD_LIGHT)


## A sister fell (IsoldeSisterKit.on_killed()).
func on_sister_down(s: Enemy, i: int) -> void:
	if form != 2 or i < 0 or i > 2 or sisters[i] != s:
		return
	down_at[i] = game.elapsed
	down_pos[i] = s.position
	sisters[i] = null
	game.stat_add("isolde_sister_falls", 1.0)
	if down_at[0] >= 0.0 and down_at[1] >= 0.0 and down_at[2] >= 0.0:
		var lo := minf(down_at[0], minf(down_at[1], down_at[2]))
		var hi := maxf(down_at[0], maxf(down_at[1], down_at[2]))
		if hi - lo <= float(boss_def["sisters_window"]):
			_coven_falls(hi - lo, s.position)


## The sisters' tick: the bar, the hidden witch following them, the risings.
func _step_sisters(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	var left := 0.0  # Life the standing sisters have left.
	var centre := Vector2.ZERO
	var standing := 0
	for i in 3:
		var s := sisters[i]
		if s != null and (not s.active or s.generation != sister_gen[i]):
			sisters[i] = null  # Gone without a kill (despawned): she counts as fallen now.
			if down_at[i] < 0.0:
				down_at[i] = game.elapsed
				down_pos[i] = s.position
			s = null
		if s != null:
			left += s.hp
			centre += s.position
			standing += 1
	if standing > 0:
		position = centre / float(standing)
	hp = maxf(max_hp * float(boss_def["phase3_hp"]) + left, 1.0)
	if not waned and game.elapsed - split_at >= float(boss_def["sabbath_wane"]):
		waned = true
		game.stat_add("isolde_sabbath_waned", 1.0)
		game.enemies.show_banner(String(boss_def["wane_banner"]))
	if standing == 0:
		var lo := minf(down_at[0], minf(down_at[1], down_at[2]))
		var hi := maxf(down_at[0], maxf(down_at[1], down_at[2]))
		_coven_falls(hi - lo, down_pos[0])
		return
	if waned:
		return
	for i in 3:
		if down_at[i] >= 0.0 and game.elapsed - down_at[i] > float(boss_def["sisters_window"]):
			var share := maxf(float(boss_def["rise_min"]), float(boss_def["rise_hp"]) * pow(float(boss_def["rise_decay"]), float(risen[i])))
			risen[i] += 1
			_raise_sister(i, down_pos[i], share)
			game.stat_add("isolde_sisters_risen", 1.0)
			game.enemies.show_banner(String(boss_def["rise_banner"]))


## The three fell together (`spread` s between the first and the last fall):
## she reforms at `at` and calls the Red Moon.
func _coven_falls(spread: float, at: Vector2) -> void:
	if form != 2:
		return
	game.stats["isolde_window_spread"] = spread
	if spread <= float(boss_def["coven_break"]):
		game.stats["witchwood_coven_breaks"] = 1.0
		game.enemies.show_banner(String(boss_def["coven_break_banner"]))
	form = 3
	untargetable = false
	position = game.arena.free_point(at, radius)
	hp = max_hp * float(boss_def["phase3_hp"])
	_base_speed = float(boss_def["red_moon_speed"])
	damage = float(boss_def["red_moon_damage"])
	circle_cd = minf(circle_cd, 2.0)
	bomb_cd = minf(bomb_cd, 4.0)
	game.stat_add("isolde_phase3_at", game.elapsed)
	game.stat_add("boss_atk_red_moon", 1.0)
	if spread > float(boss_def["coven_break"]):
		game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.court_rules().moon.force(float(boss_def["moon_hold"]))
	game.effects.impact(position, radius * 3.5, Palette.COURT_BLOOD_LIGHT)
	game.shake(7.0)
	_set_phase(Phase.WALK)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of a glowing bomb's circle.
func danger_push(p: Vector2) -> Vector2:
	var r := float(boss_def["bomb_radius"]) + 16.0
	for b in _bombs:
		var off := p - b.at
		if off.length() < r:
			return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / r) * 2.5
	return Vector2.ZERO


## Body layer on `ci`: her sprite (nothing while hidden among her sisters:
## only a faint red mist where she waits), a red glow at her hand as she casts.
func _draw_body(ci: CanvasItem) -> void:
	if form == 2:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.6), radius * 1.2, Color(Palette.COURT_BLOOD, 0.12))
		return
	if form == 3:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius), radius * 2.2, Color(Palette.COURT_BLOOD, 0.18))
	if not SpriteBank.draw(ci, "bosses/isolde", Vector2.ZERO, flash > 0.0):
		WitchwoodGlyphs.draw_isolde(ci, Vector2.ZERO, radius, flash > 0.0, Color.WHITE)
	if phase == Phase.CAST or phase == Phase.BOMB_WINDUP:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["cast_windup"])), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2(radius * 0.8, -radius * 2.4), 4.0 + 4.0 * k, Color(Palette.COURT_BLOOD_LIGHT, 0.5 + 0.4 * k))


## Overlay layer on `ci`: the bombs in flight (a cauldron-black ball dropping
## onto its shadow; texture discs in world axes from her centre).
func _draw_over(ci: CanvasItem) -> void:
	if not _bombs.is_empty():
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # Undo her mirror: world axes.
		var fall := maxf(0.01, float(boss_def["bomb_fall"]))
		for b in _bombs:
			var k := clampf(1.0 - (b.lands - game.elapsed) / fall, 0.0, 1.0)  # 0 thrown .. 1 landing.
			var at := b.at - position
			SpriteBank.draw_disc(ci, at, 10.0 * (0.4 + 0.6 * k), Color(0.0, 0.0, 0.0, 0.25 + 0.2 * k))
			var drop := at - Vector2(0.0, 110.0 * sin(PI * (1.0 - k) * 0.5))
			SpriteBank.draw_disc(ci, drop, 6.0, Palette.COURT_VELVET_DARK)
			SpriteBank.draw_disc(ci, drop + Vector2(-1.0, -2.0), 3.0, Palette.COURT_BLOOD_LIGHT)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("isolde_phase2_at", -1.0))
	var p3 := float(st.get("isolde_phase3_at", -1.0))
	return "hex circles %d casts (%d circles; healed the Court %d, drained %d hits) | cauldron bombs %d (hits %d, pools %d) | thralls called %d | sisters %s (falls %d, risen %d, spread of the last falls %s, waned %s, coven breaks %s) | red moon %s (moon held %d s) | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_hex_circle", 0.0)), int(st.get("isolde_circles", 0.0)) + int(st.get("sister_circles", 0.0)),
		int(st.get("hex_circle_heal_" + IsoldeData.CIRCLE_TAG, 0.0)) + int(st.get("hex_circle_heal_" + IsoldeData.SISTER_TAG, 0.0)),
		int(st.get("hex_drain_hits", 0.0)),
		int(st.get("isolde_bombs", 0.0)), int(st.get("isolde_bomb_hits", 0.0)), int(st.get("blood_pools_opened_" + IsoldeData.POOL_TAG, 0.0)),
		int(st.get("isolde_thralls", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached", int(st.get("isolde_sister_falls", 0.0)), int(st.get("isolde_sisters_risen", 0.0)),
		("%.1f s" % float(st["isolde_window_spread"])) if st.has("isolde_window_spread") else "-",
		"yes" if float(st.get("isolde_sabbath_waned", 0.0)) > 0.0 else "no",
		"EARNED" if float(st.get("witchwood_coven_breaks", 0.0)) > 0.0 else "no",
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", int(st.get("isolde_moon_time", 0.0)),
		int(st.get("player_dmg_from_" + IsoldeData.BOMB_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + IsoldeData.BOMB_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0)) + int(st.get("summon_dmg_from_" + WitchHexData.CIRCLE_SOURCE, 0.0))]
