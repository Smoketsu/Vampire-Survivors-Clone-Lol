## BossVael — MARSHAL VAEL, THE CRIMSON BULWARK (GDD §7.5), the Crimson March
## boss who arrives at 17:00 (3:00 left, like Sir Alaric). "Shield and
## flaming holy sword." Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy. Every ability is telegraphed (GDD §10.5) and
## tuned in MarchEnemyData.VAEL:
##   * Radiant Cleave      — a gold sector toward the necromancer, then a
##                           flaming sweep. Undead inside take the blow and
##                           each soaks part of the necromancer's damage
##                           (body-blocking, GDD §15.0).
##   * Crusader's Command  — rally banners in a line on the far side of the
##                           necromancer, then a shield line of footmen,
##                           shieldbearers and archers forms there (a pincer).
##   * Holy Standard       — a banner mark, then a destructible Holy Standard
##                           whose aura buffs the Covenant (and Vael) for a
##                           while. Kill it, or pull Vael away from it.
##   * Shieldwall          — he raises his shield (gold rim, slower walk):
##                           spells and projectiles, which come from the
##                           necromancer's side, are mostly blocked; warriors'
##                           blades and bashes reach around it at full damage.
##   * Last Stand          — below 30% HP his sword swings faster, specials
##                           come sooner with shorter windups, and he calls a
##                           Crusader's Command at once.
## Specials are chosen by weight among the ready, usable ones; between them
## he walks at the necromancer and swings his sword (inherited melee).
## Undead body-block him like any enemy (mass-weighted). Killing him drops a
## big XP burst and a guaranteed chest and power-up (ChestManager /
## PowerupManager boss rules); the run goes on.
class_name BossVael
extends Boss

## Boss attack phases (Shieldwall is a stance held while walking).
enum Phase { WALK, CLEAVE_WINDUP, COMMAND_WINDUP, STANDARD_WINDUP, RECOVER }

## Current phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.0
## True once below last_stand_hp_fraction HP (Last Stand).
var last_stand: bool = false
## Seconds the Shieldwall stays raised (0 = lowered).
var shieldwall_left: float = 0.0
## Unit direction of the current Radiant Cleave.
var cleave_dir: Vector2 = Vector2.RIGHT
## Special id -> seconds until it may be chosen again.
var _special_cds: Dictionary = {}
## Last special used (not chosen twice in a row when another is ready).
var _last_special: String = ""
## True when the next special must be Crusader's Command (Last Stand entry).
var _force_command: bool = false
## Arrival points of the Crusader's Command line (locked at the windup).
var _command_points: Array[Vector2] = []
## Enemy kinds matching _command_points.
var _command_kinds: Array[String] = []
## Where the Holy Standard will stand (locked at the windup).
var _standard_point: Vector2 = Vector2.ZERO
## The planted Holy Standard (null = none).
var _standard: Enemy = null
## Generation of `_standard` when planted (stale guard).
var _standard_gen: int = 0
## Move speed with the shield lowered (px/s).
var _base_speed: float = 50.0
## Melee attack interval before Last Stand (s).
var _base_attack_interval: float = 1.0


## Sets up Marshal Vael at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = MarchEnemyData.VAEL
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	special_cd = float(boss_def["first_special"])
	last_stand = false
	shieldwall_left = 0.0
	_force_command = false
	_standard = null
	_base_speed = move_speed
	_base_attack_interval = attack_interval
	for id: String in MarchEnemyData.VAEL_SPECIALS:
		_special_cds[id] = 0.0


## Marshal Vael's specials in report order (Boss hook).
func special_ids() -> Array:
	return MarchEnemyData.VAEL_SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Picks the next special when ready; otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	match _choose_special():
		"cleave":
			_start_cleave()
		"command":
			_start_command()
		"standard":
			_start_standard()
		"shieldwall":
			_start_shieldwall()


## Weighted choice among the specials that are off cooldown and usable now
## ("" when none is; he keeps walking and re-checks next think).
func _choose_special() -> String:
	if _force_command and _can_command():
		_force_command = false
		return "command"
	var d := position.distance_to(game.player.position)
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id: String in MarchEnemyData.VAEL_SPECIALS:
		if float(_special_cds[id]) > 0.0 or not _special_usable(id, d):
			continue
		ids.append(id)
		weights.append(float(boss_def[id + "_weight"]))
	if ids.size() > 1 and ids.has(_last_special):
		var i := ids.find(_last_special)
		ids.remove_at(i)
		weights.remove_at(i)
	if ids.is_empty():
		return ""
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in ids.size():
		roll -= weights[i]
		if roll <= 0.0:
			return ids[i]
	return ids[ids.size() - 1]


## Whether special `id` makes sense with the necromancer `d` px away.
func _special_usable(id: String, d: float) -> bool:
	match id:
		"cleave":
			return d <= float(boss_def["cleave_max_range"])
		"command":
			return _can_command()
		"standard":
			return not _standard_alive()
		"shieldwall":
			return shieldwall_left <= 0.0 and d >= float(boss_def["shieldwall_min_range"]) and d <= float(boss_def["shieldwall_max_range"])
	return true


## Crusader's Command needs room under the enemy hard cap.
func _can_command() -> bool:
	return game.enemies.regular_alive() < WaveData.HARD_CAP - 12


## True while his Holy Standard still stands.
func _standard_alive() -> bool:
	return _standard != null and _standard.active and _standard.generation == _standard_gen


## A windup length from boss_def `key`, shortened in Last Stand.
func _tele(key: String) -> float:
	return float(boss_def[key]) * (float(boss_def["last_stand_telegraph_mult"]) if last_stand else 1.0)


## Boss physics: inherited walk / melee while in WALK, otherwise specials.
func physics_step(delta: float) -> void:
	phase_time += delta
	for id: String in MarchEnemyData.VAEL_SPECIALS:
		_special_cds[id] = float(_special_cds[id]) - delta
	if not last_stand and hp <= max_hp * float(boss_def["last_stand_hp_fraction"]):
		_enter_last_stand()
	if shieldwall_left > 0.0:
		shieldwall_left -= delta
		if shieldwall_left <= 0.0:
			queue_redraw()
	match phase:
		Phase.WALK:
			special_cd -= delta
			_update_speed(delta)
			super.physics_step(delta)
		Phase.CLEAVE_WINDUP:
			_hold(delta)
			if phase_time >= _tele("cleave_telegraph"):
				_resolve_cleave()
				_set_phase(Phase.RECOVER)
		Phase.COMMAND_WINDUP:
			_hold(delta)
			if phase_time >= _tele("command_telegraph"):
				_resolve_command()
				_set_phase(Phase.RECOVER)
		Phase.STANDARD_WINDUP:
			_hold(delta)
			if phase_time >= _tele("standard_telegraph"):
				_resolve_standard()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_end_special()
				_set_phase(Phase.WALK)


## Walking speed this tick: slower behind a raised Shieldwall, faster on a
## forced march while the necromancer is farther than advance_range.
func _update_speed(delta: float) -> void:
	var spd := _base_speed
	if shieldwall_left > 0.0:
		spd *= float(boss_def["shieldwall_speed_mult"])
	if position.distance_to(game.player.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd


## Standing still during a windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	if p == Phase.RECOVER and game != null:
		motion_lunge(game.player.position - position, MotionData.POWER_MELEE)  # Engine motion: the strike lands.
	queue_redraw()


## Starts special `id`: bookkeeping shared by every special.
func _begin_special(id: String, next_phase: Phase) -> void:
	_last_special = id
	_special_cds[id] = float(boss_def[id + "_cooldown"])
	game.stat_add("boss_atk_" + id, 1.0)
	_set_phase(next_phase)


## Sets the gap before the next special (shorter in Last Stand).
func _end_special() -> void:
	var gap := float(boss_def["attack_gap"])
	if last_stand:
		gap *= float(boss_def["last_stand_gap_mult"])
	special_cd = gap


## Last Stand (GDD §7.5 "attack speed boost below 30% HP"): faster sword,
## faster specials, a Crusader's Command next.
func _enter_last_stand() -> void:
	last_stand = true
	_force_command = true
	attack_interval = _base_attack_interval * float(boss_def["last_stand_attack_mult"])
	game.enemies.show_banner(String(boss_def["last_stand_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.FLAME)
	game.stat_add("boss_last_stand", 1.0)
	queue_redraw()


# =====================================================================================
# Radiant Cleave
# =====================================================================================

## Radiant Cleave: telegraph a gold sector toward the necromancer.
func _start_cleave() -> void:
	var to_p := game.player.position - position
	cleave_dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	game.effects.telegraph_cone(position, cleave_dir, float(boss_def["cleave_radius"]), float(boss_def["cleave_half_angle"]), _tele("cleave_telegraph"), self)
	_begin_special("cleave", Phase.CLEAVE_WINDUP)


## True if a body of radius `r` at `p` lies inside the cleave sector.
func _in_cleave(p: Vector2, r: float) -> bool:
	var rel := p - position
	var d := rel.length()
	if d > float(boss_def["cleave_radius"]) + r:
		return false
	if d < radius + r:
		return true  # Hugging him: always caught.
	return absf(cleave_dir.angle_to(rel)) <= float(boss_def["cleave_half_angle"])


## The sweep lands: summons in the sector take the blow and each soaks part
## of the necromancer's damage (body-blocking).
func _resolve_cleave() -> void:
	var r := float(boss_def["cleave_radius"])
	game.effects.slash(position + cleave_dir * radius, cleave_dir, Palette.FLAME, r * 0.8)
	game.effects.impact(position + cleave_dir * r * 0.55, r * 0.5, Palette.FLAME)
	game.shake(7.0)
	var soakers := 0
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or not _in_cleave(u.position, u.radius):
			continue
		soakers += 1
		game.combat.damage_unit(u, float(boss_def["cleave_damage_summon"]) * hit_mult(), "boss_cleave")
	game.stat_add("boss_cleave_summon_hits", float(soakers))
	var player := game.player
	if _in_cleave(player.position, player.radius):
		var soak := minf(float(boss_def["cleave_soak_max"]), float(soakers) * float(boss_def["cleave_soak_per_unit"]))
		if soak > 0.0:
			game.stat_add("boss_cleave_soaked", 1.0)
		game.combat.damage_player(float(boss_def["cleave_damage_player"]) * game.enemies.damage_mult * hit_mult() * (1.0 - soak), "boss_cleave")


# =====================================================================================
# Crusader's Command
# =====================================================================================

## Crusader's Command: rally banners in a line on the far side of the
## necromancer (a pincer with Vael), locked now, filled after the windup.
func _start_command() -> void:
	_command_points.clear()
	_command_kinds.clear()
	var p := game.player.position
	var away := p - position
	var dir := away.normalized() if away.length() > 1.0 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	var n := 0
	for g: Dictionary in boss_def["command_groups"]:
		n += int(g["count"])
	var spacing := float(boss_def["command_spacing"])
	var center := p + dir * float(boss_def["command_distance"])
	var i := 0
	for g: Dictionary in boss_def["command_groups"]:
		var def := game.enemies.enemy_def(String(g["kind"]))
		for _k in int(g["count"]):
			var pt := game.arena.free_point(center + perp * (float(i) - float(n - 1) * 0.5) * spacing, float(def["radius"]))
			_command_points.append(pt)
			_command_kinds.append(String(g["kind"]))
			game.enemies.stage.add_mark(pt, float(def["radius"]) * 1.6, _tele("command_telegraph"), StageDirector.MarkStyle.RALLY)
			i += 1
	game.enemies.show_banner("Crusader's Command: a shield line forms behind you!")
	_begin_special("command", Phase.COMMAND_WINDUP)


## The line forms at the rally banners (hard cap respected).
func _resolve_command() -> void:
	var spawned := 0
	for i in _command_points.size():
		if game.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		game.enemies.spawn_at(_command_kinds[i], _command_points[i], false)
		game.effects.spawn_ring(_command_points[i], Palette.GOLD)
		spawned += 1
	game.stat_add("boss_command_soldiers", float(spawned))


# =====================================================================================
# Holy Standard
# =====================================================================================

## Holy Standard: marks where the banner will be planted, between Vael and
## the necromancer.
func _start_standard() -> void:
	var to_p := game.player.position - position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	var kind := String(boss_def["standard_kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])
	_standard_point = game.arena.free_point(position + dir * (radius + float(boss_def["standard_offset"])), r)
	game.enemies.stage.add_mark(_standard_point, 26.0, _tele("standard_telegraph"), StageDirector.MarkStyle.RALLY)
	game.effects.ring(_standard_point, float(game.enemies.enemy_def(kind)["aura_radius"]), Palette.GOLD, _tele("standard_telegraph"))
	_begin_special("standard", Phase.STANDARD_WINDUP)


## Plants the Holy Standard (a destructible aura structure, removed by the
## MarchDirector when its time runs out).
func _resolve_standard() -> void:
	var kind := String(boss_def["standard_kind"])
	_standard = game.enemies.spawn_at(kind, _standard_point, false)
	_standard.is_objective = true
	_standard_gen = _standard.generation
	if game.enemies.march != null:
		game.enemies.march.track_timed(_standard, "standard", float(boss_def["standard_duration"]))
	game.effects.impact(_standard_point, 40.0, Palette.GOLD)
	game.enemies.show_banner("Marshal Vael plants the Holy Standard!")


# =====================================================================================
# Shieldwall
# =====================================================================================

## Shieldwall: raises the shield for shieldwall_duration s (he keeps walking,
## slower). No windup: the raised gold-rimmed shield is the tell.
func _start_shieldwall() -> void:
	shieldwall_left = float(boss_def["shieldwall_duration"])
	game.effects.ring(position, radius * 2.2, Palette.SILVER, 0.4)
	_last_special = "shieldwall"
	_special_cds["shieldwall"] = float(boss_def["shieldwall_cooldown"])
	game.stat_add("boss_atk_shieldwall", 1.0)
	_end_special()
	queue_redraw()


## Shieldwall (GDD §7.5 "high frontal damage resistance"): while it is
## raised, every source but close-range blades (MarchEnemyData.MELEE_SOURCES)
## is reduced; a Soul Nova ignores it. Aura buffs apply as for any enemy.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if shieldwall_left > 0.0 and source != "nova" and not (source in MarchEnemyData.MELEE_SOURCES):
		m *= float(boss_def["shieldwall_taken_mult"])
	return m


# =====================================================================================
# Autopilot hint, drawing
# =====================================================================================

## Danger hint for the autotest autopilot: away from the cleave sector.
func danger_push(p: Vector2) -> Vector2:
	if phase == Phase.CLEAVE_WINDUP and _in_cleave(p, 30.0):
		var away := p - position
		return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/vael"


## Ground layer (Enemy._draw()): nothing under Marshal Vael.
func _draw_under() -> void:
	pass


## Body layer on `ci`: Marshal Vael in the pose of his current phase.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.CLEAVE_WINDUP, Phase.COMMAND_WINDUP, Phase.STANDARD_WINDUP:
			pose = 1
		Phase.RECOVER:
			pose = 3
	if pose == 0 and shieldwall_left > 0.0:
		pose = 2
	MarchGlyphs.draw_vael(ci, Vector2.ZERO, radius, flash > 0.0, pose, last_stand)


## Overlay layer on `ci`: the aura chevron and the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if buff_time > 0.0:
		MarchGlyphs.draw_buffed(ci, Vector2(0, -radius * 2.0), 5.0)  # Holy Standard aura.
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)  # Stasis power-up.
