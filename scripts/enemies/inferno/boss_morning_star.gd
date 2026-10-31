## BossMorningStar — THE MORNING STAR, the Adversary, the boss of Pandemonium
## and the last of Part One (Act VI, Stage 18; GDD §15.0 "The Morning Star
## (Act VI phase 2)"; owner-approved proposal docs/act6/PROPOSAL.md "Stage 18:
## Pandemonium", with the owner's decision of Oct 26, 2026: two phases, the
## Angel then the Beast; the Throne phase is cut). Loaded by name for the boss
## id "morning_star" (EnemyDirector.INFERNO_BOSS_DIR + "boss_morning_star.gd");
## he rises from his throne at 17:00 (3:00 left). Extends Boss, so summons,
## spells and the spatial hash treat him like any enemy. Numbers and the phase
## rules in MorningStarData (its header has the whole fight); in short:
##   * THE ANGEL: beautiful, six burnt wings, a burning sword. He walks at the
##     necromancer through the shared walk and melee (enemies always advance),
##     swings the BURNING SWORD (a telegraphed cone) at a body in reach, and
##     turns between LIGHT BEAMS (a fan of lines at the necromancer, HOLY) and
##     DARK BEAMS (lines crossing beside him, through his army, AREA), each
##     telegraphed by the shared lines (EffectManager.telegraph_line) and
##     struck when the warning ends.
##   * THE TRANSFORMATION (invulnerable): the angel burns away and the
##     throne-skull Beast rises in his place.
##   * THE BEAST: huge, slow and slamming. Each SLAM (a telegraphed circle on
##     the necromancer) strikes every body in it, throws the summons back and
##     leaves a Hell Pit; and THE WHOLE ARENA TURNS TO PITS: rings of
##     telegraphed pits open around the necromancer, the gaps the only way
##     out. Every pit goes through THE pit path (HellPits.open_pit(), tag
##     "morning_star"; the Hell Pits' own telegraph rim, burn, Salt Circle and
##     avoid check). Off Act VI (--boss=morning_star on another stage) the
##     pits are off and only the slams strike.
## When he FALLS the necromancer takes the throne: the ending line and a short
## announcement (MorningStarData.ENDING_ANNOUNCE), like Amaterasu's and
## Hades'; no epilogue (owner decision Oct 31, 2026). Determinism: the seeded
## global RNG only (the side of the dark beams, the pit ring's start angle).
## Stats: boss_atk_<special>, morning_star_spawn_time, morning_star_beast_at,
## morning_star_kill_time, morning_star_player_hits, morning_star_summon_hits,
## morning_star_pits (pits opened), morning_star_pits_skipped (off Act VI).
class_name BossMorningStar
extends Boss

## His phases.
enum Phase { ARRIVING, ANGEL, CHANGING, BEAST }
## His actions (inside a phase).
enum Act { NONE, SWORD_WINDUP, BEAM_WINDUP, SLAM_WINDUP, RECOVER }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds into the current phase.
var phase_time: float = 0.0
## Current action.
var act: Act = Act.NONE
## Seconds into the current action.
var act_time: float = 0.0
## Seconds until the burning sword may swing again.
var sword_cd: float = 0.0
## Seconds until the next beam attack.
var beam_cd: float = 0.0
## True when the next beam attack is the light one (light and dark take turns).
var _light_next: bool = true
## Seconds until the next slam (the Beast).
var slam_cd: float = 0.0
## Seconds until the next ring of pits (the Beast).
var pits_cd: float = 0.0
## Unit direction of the current sword swing.
var _dir: Vector2 = Vector2.RIGHT
## Lines of the beam attack being telegraphed: [from, to, width, dark (bool)].
var _beams: Array = []
## Where the current slam falls (world px).
var _slam_at: Vector2 = Vector2.ZERO
## Move speed of his walk (px/s).
var _base_speed: float = 44.0
## Game time he arrived.
var _spawn_time: float = 0.0


## Sets up the Morning Star at `pos` with HP scaled by `hp_mult`: he rises
## from his throne.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MorningStarData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	act = Act.NONE
	_beams.clear()
	_light_next = true
	sword_cd = 2.0
	_base_speed = move_speed
	_spawn_time = game.elapsed
	game.stats["morning_star_spawn_time"] = game.elapsed
	game.enemies.boss_defeated.connect(_on_defeated)
	game.effects.impact(position, radius * 3.0, Palette.INFERNO_LAVA)
	game.effects.ring(position, radius * 4.0, Palette.GOLD, 0.8)
	game.shake(8.0)
	Sfx.play("boss_impact", position)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return MorningStarData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.ANGEL or phase == Phase.BEAST) and act == Act.NONE


## Sprite key of his art (engine-motion pivot): the Angel, then the Beast.
func motion_sprite_key() -> String:
	return MorningStarData.SPRITE_BEAST if phase == Phase.BEAST else MorningStarData.SPRITE_ANGEL


## Invulnerable while he rises or transforms; the Angel never falls below
## beast_hp (the Beast takes the rest).
func damage_taken_mult(source: String) -> float:
	if phase == Phase.ARRIVING or phase == Phase.CHANGING:
		return 0.0
	if phase == Phase.ANGEL and hp <= max_hp * float(boss_def["beast_hp"]) + 1.0:
		return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Physics: phases and actions
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	sword_cd -= delta
	match phase:
		Phase.ARRIVING:
			_hold(delta)
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.ANGEL)
		Phase.ANGEL:
			_step_angel(delta)
			if hp <= max_hp * float(boss_def["beast_hp"]) + 1.0 and act == Act.NONE:
				_transform()
		Phase.CHANGING:
			_hold(delta)
			if phase_time >= float(boss_def["change_time"]):
				_enter(Phase.BEAST)
		Phase.BEAST:
			_step_beast(delta)


## Starts phase `p` (its banner and opening timers).
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	act = Act.NONE
	act_time = 0.0
	match p:
		Phase.ANGEL:
			beam_cd = float(boss_def["beam_first"])
		Phase.BEAST:
			radius = float(boss_def["beast_radius"])  # The Beast is huge.
			slam_cd = float(boss_def["slam_first"])
			pits_cd = float(boss_def["pits_first"])
			game.stats["morning_star_beast_at"] = game.elapsed
			game.enemies.show_banner("THE BEAST: the throne itself rises! Hell opens beneath you!")
			game.effects.impact(position, radius * 3.0, Palette.INFERNO_LAVA)
			game.shake(10.0)
			Sfx.play("boss_impact", position, 0.7)
	queue_redraw()


## The transformation (invulnerable): the angel burns away.
func _transform() -> void:
	phase = Phase.CHANGING
	phase_time = 0.0
	act = Act.NONE
	_beams.clear()
	game.stat_add("boss_atk_transform", 1.0)
	game.enemies.show_banner("The Angel's wings burn away... something vast rises from the throne!")
	game.effects.ring(position, 180.0, Palette.INFERNO_LAVA, 1.0)
	game.effects.ring(position, 110.0, Palette.GOLD, 0.8)
	Juice.fx.burst(position, Palette.INFERNO_LAVA, Palette.INFERNO_OBSIDIAN_LIGHT, 22, 260.0, 1.0, 3.0)
	game.shake(8.0)
	Sfx.play("boss_impact", position, 0.8)
	queue_redraw()


## Standing still (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Walks at the necromancer through the shared walk and melee, striding faster
## when far; `mult` scales his pace.
func _walk(delta: float, mult: float) -> void:
	var spd := _base_speed * mult
	if position.distance_to(game.player.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
	move_speed = spd
	super.physics_step(delta)


## The current action and its recovery; true while it owns the tick.
func _step_act(delta: float) -> bool:
	if act == Act.NONE:
		return false
	act_time += delta
	_hold(delta)
	match act:
		Act.SWORD_WINDUP:
			if act_time >= float(boss_def["sword_telegraph"]):
				_sword()
				_recover()
		Act.BEAM_WINDUP:
			var tele := float(boss_def["dark_telegraph"]) if (not _beams.is_empty() and bool((_beams[0] as Array)[3])) else float(boss_def["light_telegraph"])
			if act_time >= tele:
				_strike_beams()
				_recover()
		Act.SLAM_WINDUP:
			if act_time >= float(boss_def["slam_telegraph"]):
				_slam()
				_recover()
		Act.RECOVER:
			if act_time >= 0.45:
				act = Act.NONE
				act_time = 0.0
				queue_redraw()
	return true


## Ends an attack: a short recovery.
func _recover() -> void:
	act = Act.RECOVER
	act_time = 0.0


# =====================================================================================
# Phase 1: the Angel
# =====================================================================================

## The Angel: the burning sword in reach, the beams on their clock, else he walks.
func _step_angel(delta: float) -> void:
	beam_cd -= delta
	if _step_act(delta):
		return
	if _try_sword():
		return
	if beam_cd <= 0.0 and not game.ultimates.player_untargetable():
		beam_cd = float(boss_def["beam_cooldown"])
		_start_beams()
		return
	_walk(delta, 1.0)


## Swings the burning sword when it is ready and a body is in reach.
func _try_sword() -> bool:
	if sword_cd > 0.0:
		return false
	var t: Node2D = target if target != null and is_instance_valid(target) else game.player
	var to := t.position - position
	if to.length() > float(boss_def["sword_trigger"]) + radius:
		return false
	sword_cd = float(boss_def["sword_cooldown"])
	_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	game.effects.telegraph_cone(position, _dir, float(boss_def["sword_range"]), deg_to_rad(float(boss_def["sword_arc"])), float(boss_def["sword_telegraph"]), self)
	motion_lunge(_dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_burning_sword", 1.0)
	act = Act.SWORD_WINDUP
	act_time = 0.0
	queue_redraw()
	return true


## The sword lands: every body in the cone is struck; summons are thrown back.
func _sword() -> void:
	var reach := float(boss_def["sword_range"])
	var half := deg_to_rad(float(boss_def["sword_arc"]))
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.slash(position + _dir * reach * 0.5, _dir, Palette.INFERNO_LAVA_LIGHT, reach)
	Sfx.play("boss_impact", position, 1.2)
	game.shake(4.0)
	for pl in game.all_players:
		if not pl.dead and CovenantKit.in_sector(position, _dir, reach, half, radius, pl.position, pl.radius):
			game.combat.damage_player(float(boss_def["sword_damage_player"]) * mult, MorningStarData.SRC_SWORD, pl)
			game.stat_add("morning_star_player_hits", 1.0)
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if not CovenantKit.in_sector(position, _dir, reach, half, radius, u.position, u.radius):
			continue
		game.combat.damage_unit(u, float(boss_def["sword_damage_summon"]) * mult, MorningStarData.SRC_SWORD, self)
		game.stat_add("morning_star_summon_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - position).normalized() if u.position.distance_squared_to(position) > 1.0 else _dir
			u.position += away * game.arena.clear_length(u.position, away, float(boss_def["sword_push"]), u.radius)


## Telegraphs the next beam attack (light and dark take turns).
func _start_beams() -> void:
	_beams.clear()
	var p := game.player.position
	var to := p - position
	var aim := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	if _light_next:
		var n := int(boss_def["light_count"])
		var spread := deg_to_rad(float(boss_def["light_spread"]))
		var length := float(boss_def["light_length"])
		for i in n:
			var a := aim.rotated((float(i) - float(n - 1) * 0.5) * spread)
			_beams.append([position, position + a * length, float(boss_def["light_width"]), false])
		game.stat_add("boss_atk_light_beams", 1.0)
	else:
		var side := 1.0 if randf() < 0.5 else -1.0  # Which side of him the dark lines cross.
		var c := p + aim.orthogonal() * side * float(boss_def["dark_offset"])
		var n := int(boss_def["dark_count"])
		var half := float(boss_def["dark_length"]) * 0.5
		var a0 := aim.angle() + PI / float(maxi(2, n * 2))
		for i in n:
			var a := Vector2.from_angle(a0 + PI * float(i) / float(maxi(1, n)))
			_beams.append([c - a * half, c + a * half, float(boss_def["dark_width"]), true])
		game.stat_add("boss_atk_dark_beams", 1.0)
	var tele := float(boss_def["light_telegraph"]) if _light_next else float(boss_def["dark_telegraph"])
	for bm: Array in _beams:
		game.effects.telegraph_line(bm[0], bm[1], float(bm[2]), tele, self)
	_light_next = not _light_next
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	act = Act.BEAM_WINDUP
	act_time = 0.0
	queue_redraw()


## The beams strike: every body on a line is struck once (light: HOLY; dark: AREA).
func _strike_beams() -> void:
	var mult := game.enemies.damage_mult * hit_mult()
	var hit_p: Dictionary = {}  # Necromancers already struck.
	var hit_u: Dictionary = {}  # Summons already struck.
	game.shake(3.0)
	Sfx.play("boss_impact", position, 1.4)
	for bm: Array in _beams:
		var a: Vector2 = bm[0]
		var b: Vector2 = bm[1]
		var half := float(bm[2]) * 0.5
		var dark := bool(bm[3])
		var src := MorningStarData.SRC_DARK if dark else MorningStarData.SRC_LIGHT
		var dp := float(boss_def["dark_damage_player"] if dark else boss_def["light_damage_player"]) * mult
		var ds := float(boss_def["dark_damage_summon"] if dark else boss_def["light_damage_summon"]) * mult
		game.effects.beam(a, b, Palette.INFERNO_OBSIDIAN_LIGHT if dark else PandemoniumGlyphs.LIGHT)
		for pl in game.all_players:
			if not pl.dead and not hit_p.has(pl) and DivineWrath._seg_dist(pl.position, a, b) <= half + pl.radius:
				hit_p[pl] = true
				game.combat.damage_player(dp, src, pl)
				game.stat_add("morning_star_player_hits", 1.0)
		var buf: Array = []  # Own buffer: a death hook may query the grid again.
		game.ally_grid.query(a.lerp(b, 0.5), a.distance_to(b) * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, buf)
		for u: SummonedUnit in buf:
			if hit_u.has(u) or not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if DivineWrath._seg_dist(u.position, a, b) <= half + u.radius:
				hit_u[u] = true
				game.combat.damage_unit(u, ds, src, self)
				game.stat_add("morning_star_summon_hits", 1.0)
	_beams.clear()


# =====================================================================================
# Phase 2: the Beast
# =====================================================================================

## The Beast: the slam and the rings of pits on their clocks; he lumbers between.
func _step_beast(delta: float) -> void:
	slam_cd -= delta
	pits_cd -= delta
	if pits_cd <= 0.0:
		pits_cd = float(boss_def["pits_every"])
		_pit_ring()
	if _step_act(delta):
		return
	if slam_cd <= 0.0 and not game.ultimates.player_untargetable():
		slam_cd = float(boss_def["slam_cooldown"])
		_slam_at = game.player.position
		game.effects.telegraph_circle(_slam_at, float(boss_def["slam_radius"]), float(boss_def["slam_telegraph"]), self)
		motion_lunge((_slam_at - position).normalized() if _slam_at.distance_to(position) > 1.0 else Vector2.ZERO, MotionData.POWER_CAST)
		game.stat_add("boss_atk_beast_slam", 1.0)
		act = Act.SLAM_WINDUP
		act_time = 0.0
		queue_redraw()
		return
	_walk(delta, float(boss_def["beast_speed_mult"]))


## The slam falls: every body in the circle is struck, summons thrown back,
## and the ground breaks into a pit (Act VI).
func _slam() -> void:
	var r := float(boss_def["slam_radius"])
	var mult := game.enemies.damage_mult * hit_mult()
	game.effects.impact(_slam_at, r, Palette.INFERNO_LAVA)
	game.shake(7.0)
	Sfx.play("boss_impact", _slam_at)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(_slam_at) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["slam_damage_player"]) * mult, MorningStarData.SRC_SLAM, pl)
			game.stat_add("morning_star_player_hits", 1.0)
	game.ally_grid.query(_slam_at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(_slam_at) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["slam_damage_summon"]) * mult, MorningStarData.SRC_SLAM, self)
		game.stat_add("morning_star_summon_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - _slam_at).normalized() if u.position.distance_squared_to(_slam_at) > 1.0 else Vector2.RIGHT
			u.position += away * game.arena.clear_length(u.position, away, float(boss_def["slam_push"]), u.radius)
	_open_pit(_slam_at, float(boss_def["slam_pit_radius"]), float(boss_def["slam_pit_life"]), 0.0)


## The arena turns to pits: a ring of telegraphed pits around the necromancer.
func _pit_ring() -> void:
	var p := game.player.position
	var n := int(boss_def["pits_count"])
	var a0 := randf() * TAU
	for i in n:
		var at := game.arena.free_point(p + Vector2.from_angle(a0 + TAU * float(i) / float(maxi(1, n))) * float(boss_def["pits_ring"]), 8.0)
		_open_pit(at, float(boss_def["pits_radius"]), float(boss_def["pits_life"]), float(boss_def["pits_telegraph"]))
	game.stat_add("boss_atk_pit_ring", 1.0)


## Opens one of his pits through THE pit path (only where the Hell Pits burn).
func _open_pit(at: Vector2, r: float, life: float, telegraph: float) -> void:
	var inf := game.inferno
	if inf == null or not inf.enabled:
		game.stat_add("morning_star_pits_skipped", 1.0)
		return
	if inf.pits.open_pit(at, r, life, {"telegraph": telegraph, "tag": "morning_star"}):
		game.stat_add("morning_star_pits", 1.0)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the
## Adversary falls and the necromancer takes the throne.
func _on_defeated() -> void:
	var pos := position
	_beams.clear()
	game.effects.ring(pos, 220.0, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, 130.0, Palette.GOLD, 0.8)
	Juice.fx.burst(pos, Palette.NECRO_GREEN, Palette.INFERNO_LAVA, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var late := game.countdown_finished()  # He fell during the Last Judgment.
	game.enemies.show_banner(String(MorningStarData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + MorningStarData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = MorningStarData.LATE_ANNOUNCE if late else MorningStarData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)
	game.stats["morning_star_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the sword's cone, off the
## beams and out of the slam while they are telegraphed (the pits are the Hell
## Pits' own hint).
func danger_push(p: Vector2) -> Vector2:
	match act:
		Act.SWORD_WINDUP:
			if CovenantKit.in_sector(position, _dir, float(boss_def["sword_range"]) + 24.0, deg_to_rad(float(boss_def["sword_arc"])) + 0.2, radius, p, 12.0):
				var away := p - position
				return away.normalized() * 1.5 if away.length() > 0.1 else Vector2.RIGHT
		Act.BEAM_WINDUP:
			var push := Vector2.ZERO
			for bm: Array in _beams:
				push += KirinKit._off_line(p, bm[0], bm[1], float(bm[2]) * 0.5 + 18.0)
			return push
		Act.SLAM_WINDUP:
			var reach := float(boss_def["slam_radius"]) + 20.0
			var off := p - _slam_at
			if off.length() < reach:
				return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	return Vector2.ZERO


## Under his body: a burning halo on the ground (gold for the Angel, lava for
## the Beast). Visual only.
func _draw_under() -> void:
	var col := Palette.INFERNO_LAVA if phase == Phase.BEAST else Palette.GOLD
	var a := 0.16
	if phase == Phase.ARRIVING:
		a *= clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.0, 1.0)
	var r := radius * 2.6
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.5), Vector2(r * 2.0, r)), false, Color(col, a))


## Body layer on `ci`: the Angel's sprite (BossPoseData pose 1, the sword
## raised, while he winds up or transforms) or the Beast's, the glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var alpha := 1.0
	if phase == Phase.ARRIVING:
		alpha = clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.15, 1.0)
	var tint := Color(1.0, 1.0, 1.0, alpha)
	if phase == Phase.BEAST:
		if SpriteBank.draw(ci, MorningStarData.SPRITE_BEAST, Vector2.ZERO, flash > 0.0, tint):
			return
		PandemoniumGlyphs.draw_beast(ci, Vector2.ZERO, radius, flash > 0.0)
		return
	if phase == Phase.CHANGING:
		tint = Color(1.0, 0.7, 0.5, clampf(1.0 - phase_time / maxf(0.1, float(boss_def["change_time"])), 0.2, 1.0))  # The angel burns away.
	var pose := 1 if (act == Act.SWORD_WINDUP or act == Act.BEAM_WINDUP or phase == Phase.CHANGING) else 0
	if SpriteBank.draw_pose(ci, MorningStarData.SPRITE_ANGEL, pose, Vector2.ZERO, flash > 0.0, tint):
		return
	PandemoniumGlyphs.draw_angel(ci, Vector2.ZERO, radius, flash > 0.0, tint.a)


## Overlay layer on `ci`: ice (the HP is the HUD's bar).
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of his fight (phase times relative to his arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("morning_star_spawn_time", -1.0))
	var beast := "%.1fs" % (float(st["morning_star_beast_at"]) - t0) if st.has("morning_star_beast_at") else "-"
	var kill := "%.1fs" % float(st["morning_star_kill_time"]) if st.has("morning_star_kill_time") else "-"
	return "phases: the beast %s, he falls %s | angel: sword %d, light beams %d, dark beams %d | beast: slams %d, pit rings %d, pits opened %d (skipped off Act VI %d) | you hit %d, summon hits %d | dmg to you: sword %d, light %d, dark %d, slam %d | dmg to summons: sword %d, light %d, dark %d, slam %d" % [
		beast, kill, int(st.get("boss_atk_burning_sword", 0.0)), int(st.get("boss_atk_light_beams", 0.0)), int(st.get("boss_atk_dark_beams", 0.0)),
		int(st.get("boss_atk_beast_slam", 0.0)), int(st.get("boss_atk_pit_ring", 0.0)), int(st.get("morning_star_pits", 0.0)), int(st.get("morning_star_pits_skipped", 0.0)),
		int(st.get("morning_star_player_hits", 0.0)), int(st.get("morning_star_summon_hits", 0.0)),
		int(st.get("player_dmg_from_" + MorningStarData.SRC_SWORD, 0.0)), int(st.get("player_dmg_from_" + MorningStarData.SRC_LIGHT, 0.0)),
		int(st.get("player_dmg_from_" + MorningStarData.SRC_DARK, 0.0)), int(st.get("player_dmg_from_" + MorningStarData.SRC_SLAM, 0.0)),
		int(st.get("summon_dmg_from_" + MorningStarData.SRC_SWORD, 0.0)), int(st.get("summon_dmg_from_" + MorningStarData.SRC_LIGHT, 0.0)),
		int(st.get("summon_dmg_from_" + MorningStarData.SRC_DARK, 0.0)), int(st.get("summon_dmg_from_" + MorningStarData.SRC_SLAM, 0.0))]
