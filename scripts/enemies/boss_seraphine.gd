## BossSeraphine — GRAND INQUISITOR SERAPHINE, VOICE OF THE DAWN (GDD §7.5),
## the Stage 3 boss (StageRegistry boss id "seraphine"; any stage's boss slot
## can send her, e.g. the autotest's --boss=seraphine). She arrives at 17:00
## (3:00 left) like the other bosses. Extends Boss, so summons, spells and
## the spatial hash treat her like any enemy. Every big hit is telegraphed
## (GDD §10.5); all numbers are in SeraphineData.BOSS. Three phases:
##   1. Divine Judgment (100-60% HP): fans of radiant bolts (gold sector
##      warning), delayed holy circles (gold circles that blast after 1.2 s),
##      Templar squads (rally banners, then the squad), and a teleport after
##      a 1 s glow that always lands nearer the necromancer (on his side of
##      her, on a free point). Up to three attendants (High Confessors)
##      arrive with her: 3 minus the sacred altars destroyed on the stage
##      (Game.altars_destroyed, SanctumDirector; 0 on the other stages).
##      While one lives within attend_radius of her she regenerates
##      attend_regen HP/s per attendant.
##   2. Avatar of the Dawn (60-20%): the relic transformation (1 s, she is
##      invulnerable, brighter and larger); two rotating holy beams (warning
##      rays, then a sweep that pulses damage on the necromancer and every
##      summon in the light); radiant barrages (rings of bolts); constructs
##      (Sanctified Sentinels) rising at rally marks; undead suppression (a
##      1.5 s telegraphed 220 px sigil around the army, then for 5 s summons
##      fighting inside deal half damage and are not replaced, through the
##      horde's one suppression path, HordeDirector.add_suppression(), which
##      also draws it); and every 25 s the Judgment
##      nova: the area around her glows gold for 2.5 s while 2-3 safe
##      circles are marked (one always within reach of the necromancer), then
##      everything outside them takes heavy holy damage.
##   3. The Last Light (under 20%): shorter gaps and windups, more circles,
##      faster beams, the fan back in the rotation, novas every 20 s; the
##      attendants flee (no more healing); holy fire closes in from the rim
##      of a 600 px circle around her, shrinking to 300 px over 40 s (damage
##      outside it); and a final wave of her guard forms on the circle.
## She never kites: between specials she walks at the necromancer and
## strikes in reach (inherited melee); every special holds her in place or
## brings her closer. Undead don't dodge: her hazards hit summons where they
## stand; only the necromancer can step out (the autotest autopilot does,
## danger_push()). The world-space hazards live in SeraphineHazards.
## On death the radiant relic shatters (relic_shatter burst), the normal boss
## reward fires (EnemyDirector: XP burst, chest, power-up), and the ending
## text plays as the stage banner. The Reckoning still begins at 0:00.
##
## Her attendants heal her through exactly one path, her attend_regen pulse
## (_attendant_heal_pulse(), CombatResolver.heal_enemy()); the High
## Confessor's set_heal_override() hook is not used, so her healing keeps
## its own tuned rate and drawn gold links. As High Confessors they keep
## their ordinary kit otherwise (heals and holy shields on any ally that
## qualifies, revivals of ordinary soldiers), like a Chaplain near any boss.
class_name BossSeraphine
extends Boss

## Attack phases (the fight phase is `fight_phase`).
enum Phase { WALK, FAN_WINDUP, CIRCLES_CAST, TEMPLARS_WINDUP, TELEPORT_GLOW, BEAMS, BARRAGE, CONSTRUCTS_WINDUP, SUPPRESSION_CAST, NOVA_CAST, TRANSFORM, RECOVER }

## Source tag of her suppression zones (HordeDirector.add_suppression();
## the stat suppression_zones_seraphine).
const SUPPRESSION_SOURCE: String = "seraphine"

## Current attack phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current attack phase.
var phase_time: float = 0.0
## Fight phase: 0 Divine Judgment, 1 Avatar of the Dawn, 2 The Last Light.
var fight_phase: int = 0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.0
## Seconds until the next Judgment nova (Avatar and Last Light only).
var nova_cd: float = 0.0
## True during the Avatar transformation (no damage taken).
var invulnerable: bool = false
## World-space hazards (circles, beams, nova, suppression, collapse).
var hazards: SeraphineHazards = null
## Special id -> seconds until it may be chosen again.
var _special_cds: Dictionary = {}
## Last special used (not chosen twice in a row when another is ready).
var _last_special: String = ""
## Unit direction of the current radiant fan.
var _fan_dir: Vector2 = Vector2.RIGHT
## Where the current teleport lands (locked at the glow).
var _tele_dest: Vector2 = Vector2.ZERO
## Rally points of the pending Templar squad / constructs.
var _call_points: Array[Vector2] = []
## Enemy kinds matching _call_points.
var _call_kinds: Array[String] = []
## Barrage volleys still to fire.
var _volleys_left: int = 0
## Seconds until the next barrage volley.
var _volley_cd: float = 0.0
## Living attendants (her healers; entries go stale when they die / flee).
var _attendants: Array[Enemy] = []
## Generation of each attendant when spawned (-1 = counted dead / fled).
var _attendant_gens: Array[int] = []
## Seconds until the next attendant heal pulse.
var _attend_tick_left: float = 0.0
## Heal pulses so far (heal beams are drawn on every other one).
var _attend_pulses: int = 0
## Final guard rally points (Last Light), filled when its telegraph ends.
var _guard_points: Array[Vector2] = []
## Enemy kinds matching _guard_points.
var _guard_kinds: Array[String] = []
## Seconds left of the final guard's telegraph (<= 0 = none pending).
var _guard_left: float = 0.0
## Game time she arrived (kill-time stat).
var _spawn_time: float = 0.0


## Sets up Seraphine at `pos` with HP scaled by `hp_mult`; her attendants
## arrive with her and her hazards layer is created.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = SeraphineData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	fight_phase = 0
	special_cd = float(boss_def["first_special"])
	invulnerable = false
	_spawn_time = game.elapsed
	game.stats["seraphine_spawn_time"] = game.elapsed
	for id: String in SeraphineData.SPECIALS:
		_special_cds[id] = 0.0
	hazards = SeraphineHazards.new()
	game.enemies.add_child(hazards)
	hazards.setup(game, self)
	game.enemies.boss_defeated.connect(_on_defeated)
	_spawn_attendants()


## Seraphine's specials in report order (Boss hook).
func special_ids() -> Array:
	return SeraphineData.SPECIALS


## True while she walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


# =====================================================================================
# Choosing specials
# =====================================================================================

## Starts a due Judgment nova first, else picks the next special when ready;
## otherwise normal melee targeting.
func think() -> void:
	super.think()
	if phase != Phase.WALK:
		return
	if fight_phase >= 1 and nova_cd <= 0.0:
		_start_nova()
		return
	if special_cd > 0.0:
		return
	match _choose_special():
		"fan":
			_start_fan()
		"circles":
			_start_circles()
		"templars":
			_start_templars()
		"teleport":
			_start_teleport()
		"beams":
			_start_beams()
		"barrage":
			_start_barrage()
		"constructs":
			_start_constructs()
		"suppression":
			_start_suppression()


## Weighted choice among this fight phase's specials that are off cooldown
## and usable now ("" when none is; she keeps walking and re-checks).
func _choose_special() -> String:
	var d := position.distance_to(game.player.position)
	var ids: Array[String] = []
	var weights: Array[float] = []
	for id: String in boss_def["phase_specials"][fight_phase]:
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
		"fan":
			return d <= float(boss_def["fan_max_range"])
		"circles":
			return d <= float(boss_def["circles_max_range"])
		"templars":
			return game.enemies.regular_alive() < WaveData.HARD_CAP - 12
		"teleport":
			return d >= float(boss_def["teleport_min_range"])
		"beams":
			return d <= float(boss_def["beams_max_range"])
		"barrage":
			return d <= float(boss_def["barrage_max_range"])
		"constructs":
			return game.enemies.regular_alive() < WaveData.HARD_CAP - 6
		"suppression":
			return not game.horde.suppression.has_source(SUPPRESSION_SOURCE) and game.horde.units.size() >= int(boss_def["suppression_min_summons"])
	return true


## A windup length from boss_def `key`, shortened in later fight phases.
func _tele(key: String) -> float:
	return float(boss_def[key]) * float(boss_def["phase_telegraph_mult"][fight_phase])


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: phase checks, attendants, the final guard and the hazards,
## then the inherited walk / melee in WALK or the current special.
func physics_step(delta: float) -> void:
	phase_time += delta
	for id: String in SeraphineData.SPECIALS:
		_special_cds[id] = float(_special_cds[id]) - delta
	if fight_phase >= 1:
		nova_cd -= delta
	if fight_phase == 0 and hp <= max_hp * float(boss_def["avatar_hp_fraction"]):
		_enter_avatar()
	elif fight_phase == 1 and hp <= max_hp * float(boss_def["last_light_hp_fraction"]):
		_enter_last_light()
	_step_attendants(delta)
	_step_guard(delta)
	hazards.step(delta)
	queue_redraw()  # Halo / relic glow animate every tick (one node).
	match phase:
		Phase.WALK:
			special_cd -= delta
			super.physics_step(delta)
		Phase.FAN_WINDUP:
			_hold(delta)
			if phase_time >= _tele("fan_telegraph"):
				_fire_fan()
				_set_phase(Phase.RECOVER)
		Phase.CIRCLES_CAST, Phase.SUPPRESSION_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["cast_time"]):
				_set_phase(Phase.RECOVER)
		Phase.TEMPLARS_WINDUP, Phase.CONSTRUCTS_WINDUP:
			_hold(delta)
			var key := "templars_telegraph" if phase == Phase.TEMPLARS_WINDUP else "constructs_telegraph"
			if phase_time >= _tele(key):
				_resolve_call(phase == Phase.CONSTRUCTS_WINDUP)
				_set_phase(Phase.RECOVER)
		Phase.TELEPORT_GLOW:
			_hold(delta)
			if phase_time >= _tele("teleport_glow"):
				_resolve_teleport()
				_set_phase(Phase.RECOVER)
		Phase.BEAMS:
			_hold(delta)
			if not hazards.beams_busy():
				_set_phase(Phase.RECOVER)
		Phase.BARRAGE:
			_hold(delta)
			_step_barrage(delta)
		Phase.NOVA_CAST:
			_hold(delta)
			if not hazards.nova_pending:
				_set_phase(Phase.RECOVER)
		Phase.TRANSFORM:
			_hold(delta)
			var t := float(boss_def["avatar_transform_time"] if fight_phase == 1 else boss_def["last_light_time"])
			if phase_time >= t:
				invulnerable = false
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_end_special()
				_set_phase(Phase.WALK)


## Standing still during a windup / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Changes attack phase and resets its timer.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0


## Starts special `id`: bookkeeping shared by every special (the timed
## nova has no cooldown key: nova_cd paces it).
func _begin_special(id: String, next_phase: Phase) -> void:
	_last_special = id
	_special_cds[id] = float(boss_def.get(id + "_cooldown", 0.0))
	game.stat_add("boss_atk_" + id, 1.0)
	_set_phase(next_phase)


## Sets the gap before the next special (shorter in later fight phases).
func _end_special() -> void:
	special_cd = float(boss_def["attack_gap"]) * float(boss_def["phase_gap_mult"][fight_phase])


## Every source is nullified during the Avatar transformation; otherwise
## the shared enemy rules apply (aura buffs).
func damage_taken_mult(source: String) -> float:
	if invulnerable:
		return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Fight phases
# =====================================================================================

## Avatar of the Dawn (GDD §7.5, 60% HP): the relic transformation, a brief
## invulnerable channel; the Judgment nova clock starts.
func _enter_avatar() -> void:
	fight_phase = 1
	invulnerable = true
	hazards.stop_beams()
	hazards.mark_teleport(position, 0.0)  # A cut-short teleport.
	nova_cd = float(boss_def["nova_first"])
	_set_phase(Phase.TRANSFORM)
	game.enemies.show_banner(String(boss_def["avatar_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.GOLD)
	game.effects.ring(position, radius * 5.0, Palette.IVORY, float(boss_def["avatar_transform_time"]))
	game.stats["seraphine_avatar_time"] = game.elapsed
	game.stat_add("boss_phase2", 1.0)


## The Last Light (GDD §7.5, 20% HP): the attendants flee, the arena starts
## collapsing around her, her final guard forms and the novas speed up.
func _enter_last_light() -> void:
	fight_phase = 2
	hazards.stop_beams()
	hazards.mark_teleport(position, 0.0)  # A cut-short teleport.
	nova_cd = minf(nova_cd, float(boss_def["nova_interval_last"]))
	_set_phase(Phase.TRANSFORM)
	game.enemies.show_banner(String(boss_def["last_light_banner"]))
	game.effects.impact(position, radius * 3.5, Palette.FLAME)
	_attendants_flee()
	hazards.start_collapse(position)
	_start_guard()
	game.stats["seraphine_last_light_time"] = game.elapsed
	game.stat_add("boss_phase3", 1.0)


# =====================================================================================
# Attendants (her healers)
# =====================================================================================

## Spawns her attendants around her: attendant_count minus the altars the
## necromancer destroyed on this stage (Game.altars_destroyed, counted by
## SanctumDirector; 0 on the other stages), never below 0.
func _spawn_attendants() -> void:
	var altars := game.altars_destroyed  # Sacred altars destroyed (SanctumDirector; 0 on other stages).
	var n := clampi(int(boss_def["attendant_count"]) - altars, 0, int(boss_def["attendant_count"]))
	var kind := String(boss_def["attendant_kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])
	for i in n:
		var a := TAU * float(i) / float(maxi(1, n)) + PI * 0.5
		var pt := game.arena.free_point(position + Vector2.from_angle(a) * float(boss_def["attendant_spawn_radius"]), r)
		var e := game.enemies.spawn_at(kind, pt, false)
		e.is_objective = true  # Never recycled away from her.
		e.max_hp *= float(boss_def["attendant_hp_mult"])
		e.hp = e.max_hp
		_attendants.append(e)
		_attendant_gens.append(e.generation)
		game.effects.spawn_ring(pt, Palette.GOLD)
	game.stat_add("seraphine_attendants_spawned", float(n))
	game.stats["seraphine_altars_destroyed"] = float(altars)


## True while attendant `i` is the same living unit.
func _attendant_alive(i: int) -> bool:
	var e := _attendants[i]
	return _attendant_gens[i] >= 0 and e.active and e.generation == _attendant_gens[i]


## Counts fallen attendants and runs the heal pulse.
func _step_attendants(delta: float) -> void:
	if _attendants.is_empty():
		return
	for i in _attendants.size():
		if _attendant_gens[i] >= 0 and not _attendant_alive(i):
			_attendant_gens[i] = -1
			game.stat_add("seraphine_attendants_killed", 1.0)
	_attend_tick_left -= delta
	if _attend_tick_left <= 0.0:
		_attend_tick_left += float(boss_def["attend_tick"])
		_attendant_heal_pulse()


## Attendant healing (GDD §15.5 q34): she regenerates attend_regen HP/s for
## every living attendant within attend_radius of her, through
## CombatResolver.heal_enemy(). This is the one attendant-to-boss healing
## path (the High Confessor's set_heal_override() hook is deliberately not
## used; see the header).
func _attendant_heal_pulse() -> void:
	var near := 0  # Attendants in reach.
	_attend_pulses += 1
	for i in _attendants.size():
		if not _attendant_alive(i):
			continue
		var e := _attendants[i]
		if e.position.distance_to(position) > float(boss_def["attend_radius"]):
			continue
		if game.combat.is_silenced(e):
			game.stat_add("keening_heals_silenced", 1.0)
			continue  # Silenced by a Keening Lady's Dirge: this attendant cannot heal her.
		near += 1
		if _attend_pulses % 2 == 0 and hp < max_hp:
			game.effects.beam(e.position, position, Palette.GOLD)
	if near == 0 or hp >= max_hp:
		return
	var healed := game.combat.heal_enemy(self, float(near) * float(boss_def["attend_regen"]) * float(boss_def["attend_tick"]))
	game.stat_add("seraphine_heal_received", healed)


## The Last Light / her death: every living attendant flees the field (no
## kill, no XP) in a flash of gold.
func _attendants_flee() -> void:
	for i in _attendants.size():
		if not _attendant_alive(i):
			continue
		var e := _attendants[i]
		game.effects.spawn_ring(e.position, Palette.GOLD)
		game.effects.ring(e.position, 28.0, Palette.IVORY, 0.4)
		game.enemies.despawn(e)
		_attendant_gens[i] = -1
		game.stat_add("seraphine_attendants_fled", 1.0)


# =====================================================================================
# Radiant fan
# =====================================================================================

## Radiant fan: a gold sector toward the necromancer, then a fan of bolts.
func _start_fan() -> void:
	var to_p := game.player.position - position
	_fan_dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	game.effects.telegraph_cone(position, _fan_dir, float(boss_def["fan_cone"]), float(boss_def["fan_spread"]) * 0.5, _tele("fan_telegraph"), self)
	_begin_special("fan", Phase.FAN_WINDUP)


## Fires the fan (more bolts in the Last Light), re-aimed at the
## necromancer's current position inside the warned sector.
func _fire_fan() -> void:
	var n := int(boss_def["fan_bolts_last" if fight_phase == 2 else "fan_bolts"])
	var spread := float(boss_def["fan_spread"])
	var a0 := _fan_dir.angle()
	var dmg := float(boss_def["fan_damage"]) * game.enemies.damage_mult * hit_mult()
	for i in n:
		var a := a0 + spread * (float(i) / float(maxi(1, n - 1)) - 0.5)
		var dir := Vector2.from_angle(a)
		game.projectiles.fire_hostile(position + dir * radius, dir, dmg, float(boss_def["fan_speed"]), 1.0, Projectile.Kind.RADIANT_BOLT, "seraphine_bolt")
	game.effects.ring(position, radius * 1.8, Palette.GOLD, 0.25)


# =====================================================================================
# Delayed holy circles
# =====================================================================================

## Delayed holy circles: one on the necromancer's path, the rest around him
## (more in the Last Light); each blasts after circles_delay s.
func _start_circles() -> void:
	var pl := game.player
	var n := int(boss_def["circles_count"]) + (int(boss_def["circles_extra_last"]) if fight_phase == 2 else 0)
	var r := float(boss_def["circles_radius"])
	var delay := float(boss_def["circles_delay"])
	hazards.add_circle(_in_arena(pl.position + pl.velocity * float(boss_def["circles_lead"]), r), r, delay)
	var offset := randf() * TAU
	for i in range(1, n):
		var a := offset + TAU * float(i) / float(maxi(1, n - 1))
		var dist := randf_range(float(boss_def["circles_spread_min"]), float(boss_def["circles_spread_max"]))
		hazards.add_circle(_in_arena(pl.position + Vector2.from_angle(a) * dist, r), r, delay)
	game.stat_add("seraphine_circles", float(n))
	_begin_special("circles", Phase.CIRCLES_CAST)


## `p` pulled inside the collapsing circle (margin `m` px) once it exists.
func _in_arena(p: Vector2, m: float) -> Vector2:
	if not hazards.collapse_on:
		return p
	var off := p - hazards.collapse_center
	var lim := maxf(0.0, hazards.collapse_radius() - m)
	return hazards.collapse_center + off.limit_length(lim)


# =====================================================================================
# Templar squads, constructs and the final guard
# =====================================================================================

## Templar squad: rally banners around her, then the squad arrives.
func _start_templars() -> void:
	_call_points.clear()
	_call_kinds.clear()
	var n := 0
	for g: Dictionary in boss_def["templars_groups"]:
		n += int(g["count"])
	var offset := randf() * TAU
	var i := 0
	for g: Dictionary in boss_def["templars_groups"]:
		var kind := String(g["kind"])
		var kr := float(game.enemies.enemy_def(kind)["radius"])
		for _k in int(g["count"]):
			var a := offset + TAU * float(i) / float(maxi(1, n))
			var dist := randf_range(float(boss_def["templars_radius_min"]), float(boss_def["templars_radius_max"]))
			_add_call_point(_in_arena(position + Vector2.from_angle(a) * dist, 30.0), kind, kr, _tele("templars_telegraph"))
			i += 1
	game.enemies.show_banner("Seraphine summons a Templar squad!")
	_begin_special("templars", Phase.TEMPLARS_WINDUP)


## Constructs rise: rally marks between her and the necromancer.
func _start_constructs() -> void:
	_call_points.clear()
	_call_kinds.clear()
	var kind := String(boss_def["construct_kind"])
	var kr := float(game.enemies.enemy_def(kind)["radius"])
	var to_p := game.player.position - position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	var perp := Vector2(-dir.y, dir.x)
	var n := int(boss_def["constructs_count"])
	var base := position + dir * float(boss_def["constructs_offset"])
	for i in n:
		var pt := base + perp * (float(i) - float(n - 1) * 0.5) * float(boss_def["constructs_spread"])
		_add_call_point(_in_arena(pt, 30.0), kind, kr, _tele("constructs_telegraph"))
	game.enemies.show_banner("Sanctified constructs rise from the floor!")
	_begin_special("constructs", Phase.CONSTRUCTS_WINDUP)


## Locks a rally point for `kind` (a free point) and shows its banner mark.
func _add_call_point(p: Vector2, kind: String, kind_radius: float, telegraph: float) -> void:
	var pt := game.arena.free_point(p, kind_radius)
	_call_points.append(pt)
	_call_kinds.append(kind)
	game.enemies.stage.add_mark(pt, kind_radius * 1.6, telegraph, StageDirector.MarkStyle.RALLY)


## The squad / constructs arrive at their marks (hard cap respected).
func _resolve_call(constructs: bool) -> void:
	var spawned := 0
	for i in _call_points.size():
		if game.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		var e := game.enemies.spawn_at(_call_kinds[i], _call_points[i], false)
		if constructs:
			e.max_hp *= float(boss_def["constructs_hp_mult"])
			e.hp = e.max_hp
		game.effects.spawn_ring(_call_points[i], Palette.GOLD if not constructs else Palette.IVORY)
		spawned += 1
	game.stat_add("seraphine_constructs" if constructs else "seraphine_templars", float(spawned))


## The Last Light's final guard: rally marks spread around the collapsing
## circle; the soldiers arrive when the telegraph ends (_step_guard()).
func _start_guard() -> void:
	_guard_points.clear()
	_guard_kinds.clear()
	var n := 0
	for g: Dictionary in boss_def["guard_groups"]:
		n += int(g["count"])
	var offset := randf() * TAU
	var i := 0
	for g: Dictionary in boss_def["guard_groups"]:
		var kind := String(g["kind"])
		var kr := float(game.enemies.enemy_def(kind)["radius"])
		for _k in int(g["count"]):
			var a := offset + TAU * float(i) / float(maxi(1, n))
			var pt := game.arena.free_point(position + Vector2.from_angle(a) * float(boss_def["guard_radius"]), kr)
			_guard_points.append(pt)
			_guard_kinds.append(kind)
			game.enemies.stage.add_mark(pt, kr * 1.6, float(boss_def["guard_telegraph"]), StageDirector.MarkStyle.RALLY)
			i += 1
	_guard_left = float(boss_def["guard_telegraph"])


## Counts the final guard's telegraph down and brings the guard in.
func _step_guard(delta: float) -> void:
	if _guard_left <= 0.0:
		return
	_guard_left -= delta
	if _guard_left > 0.0:
		return
	var spawned := 0
	for i in _guard_points.size():
		if game.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		game.enemies.spawn_at(_guard_kinds[i], _guard_points[i], false)
		game.effects.spawn_ring(_guard_points[i], Palette.GOLD)
		spawned += 1
	game.enemies.show_banner("Seraphine's guard charges in for the Last Light!")
	game.stat_add("seraphine_guard", float(spawned))


# =====================================================================================
# Teleport
# =====================================================================================

## Teleport: she glows for teleport_glow s while light gathers where she will
## land: nearer the necromancer, on his side of her (never farther away),
## on a free point and inside the collapsing circle.
func _start_teleport() -> void:
	var p := game.player.position
	var from_p := position - p
	var bearing := from_p.angle() if from_p.length() > 1.0 else randf() * TAU
	var a := bearing + randf_range(-float(boss_def["teleport_turn"]), float(boss_def["teleport_turn"]))
	var dist := randf_range(float(boss_def["teleport_dist_min"]), float(boss_def["teleport_dist_max"]))
	_tele_dest = game.arena.free_point(_in_arena(p + Vector2.from_angle(a) * dist, 60.0), radius)
	hazards.mark_teleport(_tele_dest, _tele("teleport_glow"))
	game.effects.ring(position, radius * 2.2, Palette.GOLD, _tele("teleport_glow"))
	_begin_special("teleport", Phase.TELEPORT_GLOW)


## The light blinks her to the locked point.
func _resolve_teleport() -> void:
	game.effects.spawn_ring(position, Palette.IVORY)
	game.effects.ring(position, radius * 2.0, Palette.GOLD, 0.3)
	position = _tele_dest
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	sep = Vector2.ZERO
	game.effects.ring(position, radius * 2.6, Palette.IVORY, 0.35)
	game.stat_add("seraphine_teleports", 1.0)


# =====================================================================================
# Rotating holy beams, barrage
# =====================================================================================

## Rotating holy beams: warning rays across the necromancer's bearing (so the
## first sweep reaches him late), then the sweep (faster in the Last Light).
func _start_beams() -> void:
	var to_p := game.player.position - position
	var a := (to_p.angle() if to_p.length() > 1.0 else 0.0) + PI * 0.5
	var dir := 1.0 if randf() < 0.5 else -1.0
	var speed := float(boss_def["beams_speed_last" if fight_phase == 2 else "beams_speed"])
	hazards.start_beams(a, dir, speed, _tele("beams_telegraph"), float(boss_def["beams_duration"]))
	_begin_special("beams", Phase.BEAMS)


## Radiant barrage: a gold glow, then barrage_volleys rings of bolts.
func _start_barrage() -> void:
	_volleys_left = int(boss_def["barrage_volleys"])
	_volley_cd = _tele("barrage_telegraph")
	game.effects.ring(position, radius * 3.0, Palette.GOLD, _volley_cd)
	_begin_special("barrage", Phase.BARRAGE)


## Fires the barrage's volleys (each ring turned by half a bolt gap).
func _step_barrage(delta: float) -> void:
	_volley_cd -= delta
	if _volley_cd > 0.0:
		return
	if _volleys_left <= 0:
		_set_phase(Phase.RECOVER)
		return
	var n := int(boss_def["barrage_bolts"])
	var shift := float(int(boss_def["barrage_volleys"]) - _volleys_left) * 0.5
	var a0 := (game.player.position - position).angle() + TAU / float(n) * shift
	var dmg := float(boss_def["barrage_damage"]) * game.enemies.damage_mult * hit_mult()
	for i in n:
		var dir := Vector2.from_angle(a0 + TAU * float(i) / float(n))
		game.projectiles.fire_hostile(position + dir * radius, dir, dmg, float(boss_def["barrage_speed"]), 1.0, Projectile.Kind.RADIANT_BOLT, "seraphine_bolt")
	game.effects.ring(position, radius * 2.0, Palette.GOLD, 0.2)
	_volleys_left -= 1
	_volley_cd = float(boss_def["barrage_interval"])


# =====================================================================================
# Undead suppression
# =====================================================================================

## Undead suppression (GDD §7.5 / §15.5 q36): a sigil around the necromancer
## (where his army stands), cast through the horde's one suppression path,
## HordeDirector.add_suppression(): it arms for suppression_telegraph s
## (the gold warning ring, drawn by the SuppressionField), then for
## suppression_duration s no summon is replaced inside it, deaths inside it
## are held, and minion attacks on foes inside deal suppression_damage_mult.
## Stats: seraphine_suppressions, seraphine_suppressed_summons (summons
## inside the ring at the cast).
func _start_suppression() -> void:
	var pos := game.player.position  # Centre of the sigil.
	var r := float(boss_def["suppression_radius"])
	game.horde.add_suppression(pos, r, float(boss_def["suppression_duration"]), float(boss_def["suppression_damage_mult"]),
		_tele("suppression_telegraph"), SUPPRESSION_SOURCE)
	var caught := 0  # Summons inside at the cast.
	for u in game.horde.units:
		if u.active and u.position.distance_to(pos) <= r:
			caught += 1
	Sfx.play("boss_telegraph", pos)
	game.stat_add("seraphine_suppressions", 1.0)
	game.stat_add("seraphine_suppressed_summons", float(caught))
	game.enemies.show_banner("Seraphine suppresses the undead!")
	_begin_special("suppression", Phase.SUPPRESSION_CAST)


# =====================================================================================
# Judgment nova
# =====================================================================================

## Judgment nova: she channels while the area around her glows and the safe
## circles are marked: the first within reach of the necromancer, the
## others spread around her, all on free points inside the nova (and the
## collapsing circle).
func _start_nova() -> void:
	var n := int(boss_def["nova_safe_zones_last" if fight_phase == 2 else "nova_safe_zones"])
	var safe: Array[Vector2] = []
	var p := game.player.position
	var to_her := position - p
	var bearing := to_her.angle() if to_her.length() > 1.0 else randf() * TAU  # Toward her: shelter keeps the fight close.
	var a0 := bearing + randf_range(-float(boss_def["nova_near_turn"]), float(boss_def["nova_near_turn"]))
	var near := p + Vector2.from_angle(a0) * randf_range(float(boss_def["nova_near_min"]), float(boss_def["nova_near_max"]))
	safe.append(_safe_point(near))
	var offset := randf() * TAU
	for i in range(1, n):
		var a := offset + TAU * float(i) / float(maxi(1, n - 1))
		var q := position + Vector2.from_angle(a) * randf_range(float(boss_def["nova_far_min"]), float(boss_def["nova_far_max"]))
		safe.append(_safe_point(q))
	hazards.start_nova(position, safe, float(boss_def["nova_telegraph"]))
	nova_cd = float(boss_def["nova_interval_last" if fight_phase == 2 else "nova_interval"])
	game.enemies.show_banner("Judgment! Reach a circle of shelter!")
	game.effects.ring(position, radius * 3.0, Palette.IVORY, float(boss_def["nova_telegraph"]))
	_begin_special("nova", Phase.NOVA_CAST)


## A safe-circle centre near `q`: inside the nova and the collapsing circle,
## off obstacles.
func _safe_point(q: Vector2) -> Vector2:
	var sr := float(boss_def["nova_safe_radius"])
	var off := q - position
	q = position + off.limit_length(float(boss_def["nova_radius"]) - sr - 10.0)
	q = _in_arena(q, sr + 30.0)
	return game.arena.free_point(q, 16.0)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her death (EnemyDirector.boss_defeated, after the reward burst): the
## hazards end, the radiant relic shatters, her attendants flee and the
## ending text plays as the stage banner.
func _on_defeated() -> void:
	hazards.clear()
	_guard_left = 0.0
	_attendants_flee()
	var pos := position
	game.effects.ring(pos, SeraphineData.SHATTER_RADIUS, Palette.IVORY, 0.8, "relic_shatter")
	game.effects.ring(pos, SeraphineData.SHATTER_RADIUS * 0.6, Palette.GOLD, 0.5)
	game.effects.impact(pos + Vector2(radius * 0.8, -radius * 1.5), radius * 2.5, Palette.IVORY)  # The relic itself bursts.
	for i in 16:
		var dir := Vector2.from_angle(TAU * float(i) / 16.0)
		game.effects.slash(pos + dir * radius * (1.5 + float(i % 2)), dir, Palette.GOLD if i % 2 == 0 else Palette.IVORY, radius * 2.2)
	Juice.fx.burst(pos, Palette.GOLD, Palette.IVORY, SeraphineData.SHATTER_SHARDS, 300.0, 0.9, 3.5)
	game.shake(10.0)
	game.enemies.show_banner(String(SeraphineData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + SeraphineData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = SeraphineData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.GOLD)
	game.stats["seraphine_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: the hazards' push, plus out of
## the fan's sector while it is warned.
func danger_push(p: Vector2) -> Vector2:
	var push := hazards.danger_push(p) if hazards != null else Vector2.ZERO
	if phase == Phase.FAN_WINDUP:
		var rel := p - position
		if rel.length() <= float(boss_def["fan_cone"]) + 60.0 and absf(_fan_dir.angle_to(rel)) <= float(boss_def["fan_spread"]) * 0.5 + 0.2:
			var perp := Vector2(-_fan_dir.y, _fan_dir.x)
			push += perp if rel.dot(perp) >= 0.0 else -perp
	return push.limit_length(1.0)


func _draw() -> void:
	var pose := 0
	match phase:
		Phase.FAN_WINDUP, Phase.CIRCLES_CAST, Phase.TEMPLARS_WINDUP, Phase.BEAMS, Phase.BARRAGE, Phase.CONSTRUCTS_WINDUP, Phase.SUPPRESSION_CAST, Phase.NOVA_CAST:
			pose = 1
		Phase.TELEPORT_GLOW, Phase.TRANSFORM:
			pose = 2
		Phase.RECOVER:
			pose = 3
	var glow := 0.0  # 0..1 gathering light (teleport / transformation).
	if phase == Phase.TELEPORT_GLOW:
		glow = clampf(phase_time / maxf(0.05, _tele("teleport_glow")), 0.0, 1.0)
	elif phase == Phase.TRANSFORM:
		glow = 1.0
	SeraphineGlyphs.draw_seraphine(self, Vector2.ZERO, radius, flash > 0.0, pose, fight_phase, glow, game.elapsed if game != null else 0.0)
	if buff_time > 0.0:
		MarchGlyphs.draw_buffed(self, Vector2(0, -radius * 2.6), 5.0)  # A Covenant aura buff.
	if frozen:
		PowerupGlyphs.draw_frozen(self, Vector2.ZERO, radius)  # Stasis / Deep Freeze.


## One-line autotest summary of her fight (phase times relative to her
## arrival, attendants, healing, every mechanic's count and damage).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("seraphine_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	return "phases: avatar %s, last light %s, kill %s | attendants %d spawned (altars %d) / %d killed / %d fled, heal received %d | teleports %d | circles %d (summon hits %d) | beams %d (player pulses %d, summon pulses %d) | barrages %d | templars %d, constructs %d, guard %d | suppressions %d (summons in the ring at the cast %d) | novas %d (player hit %d / safe %d, summons hit %d / spared %d, dmg to player %d) | collapse dmg player %d / summons %d (player ticks %d) | dmg to player: bolts %d, circles %d, beams %d" % [
		rel.call("seraphine_avatar_time"), rel.call("seraphine_last_light_time"),
		"%.1fs" % float(st["seraphine_kill_time"]) if st.has("seraphine_kill_time") else "-",
		int(st.get("seraphine_attendants_spawned", 0.0)), int(st.get("seraphine_altars_destroyed", 0.0)), int(st.get("seraphine_attendants_killed", 0.0)),
		int(st.get("seraphine_attendants_fled", 0.0)), int(st.get("seraphine_heal_received", 0.0)), int(st.get("seraphine_teleports", 0.0)),
		int(st.get("seraphine_circles", 0.0)), int(st.get("seraphine_circle_summon_hits", 0.0)), int(st.get("boss_atk_beams", 0.0)),
		int(st.get("seraphine_beam_player_pulses", 0.0)), int(st.get("seraphine_beam_summon_pulses", 0.0)), int(st.get("boss_atk_barrage", 0.0)),
		int(st.get("seraphine_templars", 0.0)), int(st.get("seraphine_constructs", 0.0)), int(st.get("seraphine_guard", 0.0)),
		int(st.get("seraphine_suppressions", 0.0)), int(st.get("seraphine_suppressed_summons", 0.0)),
		int(st.get("seraphine_novas", 0.0)), int(st.get("seraphine_nova_player_hit", 0.0)), int(st.get("seraphine_nova_player_safe", 0.0)),
		int(st.get("seraphine_nova_summon_hits", 0.0)), int(st.get("seraphine_nova_summon_spared", 0.0)), int(st.get("player_dmg_from_seraphine_nova", 0.0)),
		int(st.get("player_dmg_from_seraphine_collapse", 0.0)), int(st.get("summon_dmg_from_seraphine_collapse", 0.0)), int(st.get("seraphine_collapse_player_ticks", 0.0)),
		int(st.get("player_dmg_from_seraphine_bolt", 0.0)), int(st.get("player_dmg_from_seraphine_circle", 0.0)), int(st.get("player_dmg_from_seraphine_beam", 0.0))]
