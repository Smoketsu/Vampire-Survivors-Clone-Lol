## BossHades — HADES, LORD OF THE DEAD, the boss of the Asphodel Underworld and
## of Act IV (Stage 12; GDD §15.0 "The Asphodel Underworld (Act IV phase 2)";
## owner-approved proposal docs/act4/PROPOSAL.md: "the first rival
## necromancer"). Loaded by name for the boss id "hades"
## (EnemyDirector.PANTHEON_BOSS_DIR + "boss_hades.gd"); he rises from the ground
## at 17:00 (3:00 left). Extends Boss, so summons, spells and the spatial hash
## treat him like any enemy. Numbers and the phase rules in HadesData (its
## header has the whole fight); in short:
##   * HELM OF DARKNESS: cloaked (untargetable: Enemy.untargetable keeps him out
##     of the enemy spatial hash, and he takes no damage) he walks unseen, his
##     footprints on the ground, and opens his fissures across the Bone Ring;
##     revealed he sweeps his bident and takes every blow.
##   * THE RECLAIMING: he marks the summons nearest him; still marked when the
##     sigil resolves, a summon falls and rises as his shade through THE Claims
##     path (Game.claims_rules(), the one switch that creates EyeClaims outside
##     Act II; EyeClaims.mark(); HordeDirector.claim_fallen()). The gods of
##     Olympus rise as shades for one attack each (HadesData.GOD_SHADES, keyed
##     on the Olympus agent's ids; a god without art is the generic shade).
##   * LORD OF THE DEAD: his ring of Tartarus Wardens (TartarusWardenKit) holds
##     posts around him; behind it he takes ring_damage_taken; once it breaks he
##     staggers, open, then raises a new one.
## WRATH OF THE GODS: his fissures and the Poseidon / Zeus shades' wave and
## bolts are DivineWrath hazards (they hit both armies). LEAD (merge): the
## Mount Olympus agent adds the public DivineWrath.strike(); until then the two
## wrappers below (_wrath_strike(), _open_fissure()) reach DivineWrath's
## private scheduler / fissure list, marked for the lead to switch over.
## Beaten, he KNEELS and gives up his crown (HadesHazards.start_finale(): the
## kneeling figure and the crown at the necromancer's feet; the ending line and
## announcement, like Vhal'Neth's and Deus Ex Machina's).
## Determinism: the seeded global RNG only (none in his own rules: marks are
## the nearest summons, gods come in order). Stats: boss_atk_<special>,
## hades_cloaks, hades_reveals, hades_footprints, hades_ring_fissures,
## hades_marks, hades_taken, hades_shades_risen (EyeClaims), hades_gods,
## hades_god_<id>, hades_god_art_<id> (1 when the god's own art was drawn),
## hades_rings, hades_wardens, hades_ring_breaks, hades_bident_player_hits,
## hades_reclaim_at, hades_lord_at, hades_spawn_time, hades_kill_time.
class_name BossHades
extends Boss

## His phases.
enum Phase { ARRIVING, HELM, CHANGING, RECLAIM, LORD }
## His actions (inside a phase).
enum Act { NONE, BIDENT_WINDUP, RECOVER }

## Damage source tag of the bident sweep.
const SRC_BIDENT: String = "hades_bident"
## Damage source tag of the blow that takes a marked summon (its fall).
const SRC_RECLAIM: String = "hades_reclaim"
## Damage source tag of a god shade's attack (Ares' charge, Artemis's volley).
const SRC_GOD: String = "hades_god_shade"

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds into the current phase.
var phase_time: float = 0.0
## Phase that follows the CHANGING pause.
var _next_phase: Phase = Phase.RECLAIM
## Current action.
var act: Act = Act.NONE
## Seconds into the current action.
var act_time: float = 0.0
## Seconds until the next bident sweep may start.
var bident_cd: float = 0.0
## Unit direction of the current sweep.
var _bident_dir: Vector2 = Vector2.RIGHT
## Helm: true while cloaked.
var cloaked: bool = false
## Helm: seconds left in the current cloak / reveal.
var _helm_left: float = 0.0
## Helm: seconds until the next footprint.
var _foot_cd: float = 0.0
## Reclaiming: seconds until the next marking.
var reclaim_cd: float = 0.0
## Reclaiming: seconds until the next god shade.
var god_cd: float = 0.0
## Reclaiming: index of the next god (HadesData.GOD_SHADES, in turn).
var _god_index: int = 0
## Reclaiming: marked summons [SummonedUnit, generation, resolve game time].
var marks: Array = []
## Lord: the ring [Enemy, generation] of Tartarus Wardens.
var ring: Array = []
## Lord: true while the ring holds (he takes ring_damage_taken).
var ring_up: bool = false
## Lord: game time the stagger after a break ends (0 = not staggered).
var broken_until: float = 0.0
## Lord: game time the next ring rises (INF = one stands or none due).
var next_ring_at: float = INF
## Lord: seconds until the next fissures under the necromancer's ring.
var lord_fissure_cd: float = 0.0
## Move speed of his walk (px/s).
var _base_speed: float = 50.0
## Game time he arrived.
var _spawn_time: float = 0.0
## His world-space hazards and drawings (footprints, marks, god shades, ring
## links, the kneeling finale); a child of the EnemyDirector.
var hazards: HadesHazards = null


## Sets up Hades at `pos` with HP scaled by `hp_mult`: he rises from the ground.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = HadesData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	act = Act.NONE
	cloaked = false
	marks.clear()
	ring.clear()
	ring_up = false
	broken_until = 0.0
	next_ring_at = INF
	bident_cd = 2.0
	_god_index = 0
	_base_speed = move_speed
	_spawn_time = game.elapsed
	game.stats["hades_spawn_time"] = game.elapsed
	game.claims_rules()  # THE switch: his Reclaiming runs through the Claims path.
	game.pantheon_rules()  # His fissures are the Wrath of the Gods (on any stage he is sent to).
	hazards = HadesHazards.new()
	hazards.game = game
	hazards.boss = self
	game.enemies.add_child(hazards)
	game.enemies.boss_defeated.connect(_on_defeated)
	game.effects.impact(position, radius * 3.0, Palette.PANTHEON_AEGEAN)
	game.shake(8.0)
	Sfx.play("hades_rise", position)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return HadesData.SPECIALS


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.HELM or phase == Phase.RECLAIM or phase == Phase.LORD) and act == Act.NONE and broken_until <= game.elapsed


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/hades"


## Invulnerable while he rises, changes phase or is cloaked; never below the
## next phase's threshold while a phase runs; behind his ring he takes
## ring_damage_taken, staggered broken_damage_taken.
func damage_taken_mult(source: String) -> float:
	if phase == Phase.ARRIVING or phase == Phase.CHANGING or cloaked:
		return 0.0
	var m := super.damage_taken_mult(source)
	match phase:
		Phase.HELM:
			if hp <= max_hp * float(boss_def["reclaim_hp"]) + 1.0:
				return 0.0
		Phase.RECLAIM:
			if hp <= max_hp * float(boss_def["lord_hp"]) + 1.0:
				return 0.0
		Phase.LORD:
			if broken_until > game.elapsed:
				m *= float(boss_def["broken_damage_taken"])
			elif ring_up:
				m *= float(boss_def["ring_damage_taken"])
	return m


# =====================================================================================
# Physics: phases and actions
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	bident_cd -= delta
	_step_marks()
	hazards.step()  # The god shades' attacks.
	match phase:
		Phase.ARRIVING:
			_hold(delta)
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.HELM)
		Phase.CHANGING:
			_hold(delta)
			if phase_time >= float(boss_def["change_time"]):
				_enter(_next_phase)
		Phase.HELM:
			_step_helm(delta)
			if hp <= max_hp * float(boss_def["reclaim_hp"]) + 1.0 and not cloaked and act == Act.NONE:
				_change(Phase.RECLAIM)
		Phase.RECLAIM:
			_step_reclaim(delta)
			if hp <= max_hp * float(boss_def["lord_hp"]) + 1.0 and act == Act.NONE:
				_change(Phase.LORD)
		Phase.LORD:
			_step_lord(delta)


## Starts phase `p` (its banner and opening state).
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	act = Act.NONE
	match p:
		Phase.HELM:
			cloaked = false
			_cloak(true)
		Phase.RECLAIM:
			game.stat_add("hades_reclaim_at", game.elapsed)
			game.enemies.show_banner("THE RECLAIMING: Hades marks your dead to make them his!")
			reclaim_cd = float(boss_def["reclaim_first"])
			god_cd = float(boss_def["god_first"])
		Phase.LORD:
			game.stat_add("hades_lord_at", game.elapsed)
			game.enemies.show_banner("LORD OF THE DEAD: his own ring of the dead stands against yours!")
			next_ring_at = game.elapsed
			lord_fissure_cd = float(boss_def["lord_fissure_interval"]) * 0.5
	queue_redraw()


## Pauses (invulnerable) before phase `p`.
func _change(p: Phase) -> void:
	if cloaked:
		_cloak(false)
	_next_phase = p
	phase = Phase.CHANGING
	phase_time = 0.0
	act = Act.NONE
	game.effects.ring(position, 160.0, Palette.PANTHEON_AEGEAN_LIGHT, 0.8)
	game.shake(6.0)
	Sfx.play("hades_rise", position, 0.8)
	queue_redraw()


## Standing still (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Walks at the necromancer through the shared walk and melee (enemies always
## advance), striding faster when far; `mult` scales his pace.
func _walk(delta: float, mult: float) -> void:
	var dist := position.distance_to(game.player.position)
	var spd := _base_speed * mult
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
	move_speed = spd
	super.physics_step(delta)


## The bident and its recovery (every phase); true while it owns the tick.
func _step_act(delta: float) -> bool:
	if act == Act.NONE:
		return false
	act_time += delta
	_hold(delta)
	match act:
		Act.BIDENT_WINDUP:
			if act_time >= float(boss_def["bident_telegraph"]):
				_bident()
				act = Act.RECOVER
				act_time = 0.0
		Act.RECOVER:
			if act_time >= 0.4:
				act = Act.NONE
				act_time = 0.0
				queue_redraw()
	return true


## Starts a bident sweep when it is ready and the necromancer or 3+ summons are close.
func _try_bident() -> bool:
	if bident_cd > 0.0:
		return false
	var trig := float(boss_def["bident_trigger"])
	if position.distance_to(game.player.position) > trig and _summons_near(position, trig) < 3:
		return false
	bident_cd = float(boss_def["bident_cooldown"])
	var to := game.player.position - position
	_bident_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	game.effects.telegraph_cone(position, _bident_dir, float(boss_def["bident_range"]), float(boss_def["bident_half_arc"]), float(boss_def["bident_telegraph"]), self)
	motion_lunge(_bident_dir, MotionData.POWER_CAST)
	game.stat_add("boss_atk_bident", 1.0)
	act = Act.BIDENT_WINDUP
	act_time = 0.0
	queue_redraw()
	return true


## The sweep lands: every body in the cone is hit; summons are thrown back.
func _bident() -> void:
	var reach := float(boss_def["bident_range"])
	var half := float(boss_def["bident_half_arc"])
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	game.effects.slash(position + _bident_dir * reach * 0.5, _bident_dir, Palette.PANTHEON_AEGEAN_LIGHT, reach)
	Sfx.play("bident_sweep", position)
	game.shake(4.0)
	for pl in game.all_players:
		if CovenantKit.in_sector(position, _bident_dir, reach, half, radius, pl.position, pl.radius):
			game.combat.damage_player(float(boss_def["bident_damage_player"]) * mult, SRC_BIDENT, pl)
			game.stat_add("hades_bident_player_hits", 1.0)
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not CovenantKit.in_sector(position, _bident_dir, reach, half, radius, u.position, u.radius):
			continue
		var away := u.position - position
		u.position += (away.normalized() if away.length() > 0.5 else _bident_dir) * float(boss_def["bident_knockback"])
		game.combat.damage_unit(u, float(boss_def["bident_damage_summon"]) * mult, SRC_BIDENT, self)


# =====================================================================================
# Phase 1: the Helm of Darkness
# =====================================================================================

## Cloaked he walks unseen (footprints) and his fissures open under the ring;
## revealed he fights.
func _step_helm(delta: float) -> void:
	_helm_left -= delta
	if _helm_left <= 0.0 and act == Act.NONE:
		_cloak(not cloaked)
	if cloaked:
		_walk(delta, float(boss_def["cloak_speed_mult"]))
		_foot_cd -= delta
		if _foot_cd <= 0.0:
			_foot_cd = float(boss_def["footprint_every"])
			hazards.add_footprint(position, velocity)
			game.stat_add("hades_footprints", 1.0)
		return
	if _step_act(delta):
		return
	if _try_bident():
		return
	_walk(delta, 1.0)


## Puts the Helm of Darkness on (`on`) or takes it off.
func _cloak(on: bool) -> void:
	cloaked = on
	untargetable = on  # Out of the enemy spatial hash (the next rebuild): nothing finds him.
	_helm_left = float(boss_def["cloak_time"]) if on else float(boss_def["reveal_time"])
	game.effects.ring(position, radius * 2.6, Palette.PANTHEON_MARBLE_LIGHT if on else Palette.PANTHEON_AEGEAN_LIGHT, 0.5)
	if on:
		_foot_cd = 0.0
		game.stat_add("hades_cloaks", 1.0)
		game.stat_add("boss_atk_cloak", 1.0)
		Sfx.play("helm_cloak", position)
		_ring_fissures(int(boss_def["ring_fissures"]))
	else:
		game.stat_add("hades_reveals", 1.0)
		Sfx.play("helm_reveal", position)
	queue_redraw()


## Opens `n` fissures across the Bone Ring around the necromancer: each crack
## centred on the ring (its radius + ring_fissure_offset px from him), lying
## across it (radial), spread evenly from a random start angle.
func _ring_fissures(n: int) -> void:
	var p := game.player.position
	var r := game.horde.ring_radius + float(boss_def["ring_fissure_offset"])  # Ring radius (px).
	var a0 := randf() * TAU
	for i in n:
		var a := a0 + TAU * float(i) / float(maxi(1, n))
		var dir := Vector2.from_angle(a)
		_open_fissure(p + dir * r, dir, float(boss_def["ring_fissure_length"]))
	game.stat_add("hades_ring_fissures", float(n))
	game.stat_add("boss_atk_fissures", 1.0)


## LEAD (merge): replace with the public DivineWrath.strike() the Mount Olympus
## agent adds. Opens one Hades fissure centred at `centre`, lying along `dir`,
## `length` px long, with the stage's fissure settings (telegraph, burn, spit,
## swallow: DivineWrath does the rest exactly as for its own fissures).
func _open_fissure(centre: Vector2, dir: Vector2, length: float) -> void:
	var w := game.pantheon_rules().wrath  # The one wrath path.
	var c: Dictionary = w.cfg["fissures"]
	if w.fissures.size() >= int(PantheonRulesData.WRATH_CAPS["fissures"]):
		game.stat_add("wrath_capped", 1.0)
		return
	var half := dir * length * 0.5
	var open_t := game.elapsed + float(c["telegraph"])  # Game time it opens.
	w.fissures.append({"a": centre - half, "b": centre + half, "open_t": open_t, "close_t": open_t + float(c["open"]),
		"next_tick": open_t, "next_spit": open_t, "spit_until": open_t + float(c["spit_time"]), "opened": false, "c": c})


## LEAD (merge): replace with the public DivineWrath.strike(kind, at, ...) the
## Mount Olympus agent adds. Starts one Wrath of the Gods strike of `kind`
## ("waves", "lightning", "fissures") around the necromancer through
## DivineWrath's own scheduler (its private _strike()).
func _wrath_strike(kind: String) -> void:
	game.pantheon_rules().wrath._strike(kind, game.elapsed)


# =====================================================================================
# Phase 2: the Reclaiming
# =====================================================================================

## He marks summons and calls the gods' shades; walks and sweeps between.
func _step_reclaim(delta: float) -> void:
	reclaim_cd -= delta
	god_cd -= delta
	if reclaim_cd <= 0.0:
		reclaim_cd = float(boss_def["reclaim_interval"])
		_mark_summons()
	if god_cd <= 0.0:
		god_cd = float(boss_def["god_interval"])
		_raise_god()
	if _step_act(delta):
		return
	if _try_bident():
		return
	_walk(delta, 1.0)


## Marks the reclaim_marks summons nearest him (not temporary, not airborne,
## not in stone).
func _mark_summons() -> void:
	var reach := float(boss_def["reclaim_reach"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var cands: Array = []  # [distance, unit]
	for u: SummonedUnit in _tmp:
		if not u.active or u.is_temporary or u.airborne or u.stone_form or u.state == SummonedUnit.State.DEAD:
			continue
		var d := u.position.distance_to(position)
		if d <= reach + u.radius and not _is_marked(u):
			cands.append([d, u])
	if cands.is_empty():
		reclaim_cd = 1.0
		return
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var until := game.elapsed + float(boss_def["mark_time"])
	var n := mini(int(boss_def["reclaim_marks"]), cands.size())
	for k in n:
		var u: SummonedUnit = cands[k][1]
		marks.append([u, u.generation, until])
	game.stat_add("hades_marks", float(n))
	game.stat_add("boss_atk_reclaim", 1.0)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	Sfx.play("hades_mark", position)


## True when `u` already carries his mark.
func _is_marked(u: SummonedUnit) -> bool:
	for m: Array in marks:
		if m[0] == u and int(m[1]) == u.generation:
			return true
	return false


## Resolves the marks whose time came: a summon still marked is taken (it falls
## and rises at once as his shade through the Claims path).
func _step_marks() -> void:
	var i := marks.size() - 1
	while i >= 0:
		var m: Array = marks[i]
		var u: SummonedUnit = m[0]
		if not u.active or u.generation != int(m[1]):
			marks.remove_at(i)
		elif game.elapsed >= float(m[2]):
			marks.remove_at(i)
			_take(u)
		i -= 1


## Takes summon `u`: his mark on it in the Claims path, then its fall.
func _take(u: SummonedUnit) -> void:
	game.claims_rules().mark(u, game.elapsed + 1.0, float(boss_def["shade_life"]), HadesData.SHADE_TINT, HadesData.SHADE_NAME)
	game.effects.ring(u.position, u.radius * 2.0, Palette.PANTHEON_MARBLE_LIGHT, 0.5)
	game.combat.damage_unit(u, 1.0e6, SRC_RECLAIM, self)
	game.stat_add("hades_taken", 1.0)


## Raises the next god of HadesData.GOD_SHADES as a shade near the necromancer
## for its one attack (HadesHazards runs it).
func _raise_god() -> void:
	var gods: Array = HadesData.GOD_SHADES
	if gods.is_empty():
		return
	var g: Dictionary = gods[_god_index % gods.size()]
	_god_index += 1
	var p := game.player.position
	var at := game.arena.free_point(p + Vector2.from_angle(randf() * TAU) * float(boss_def["god_distance"]), 18.0)
	hazards.raise_god(g, at)
	game.stat_add("hades_gods", 1.0)
	game.stat_add("hades_god_" + String(g["id"]), 1.0)
	game.stat_add("boss_atk_god_shade", 1.0)
	game.enemies.show_banner("Hades raises the shade of %s!" % String(g["name"]))
	Sfx.play("hades_mark", at, 0.7)
	match String(g["attack"]):
		"wave":
			_wrath_strike("waves")  # Poseidon: a wave of the Wrath of the Gods.
		"lightning":
			_wrath_strike("lightning")  # Zeus: a bolt salvo of the Wrath of the Gods.


# =====================================================================================
# Phase 3: Lord of the Dead
# =====================================================================================

## His ring rises, holds, breaks; he walks slowly inside it; fissures open
## under the necromancer's ring.
func _step_lord(delta: float) -> void:
	var alive := _ring_alive()
	if ring_up and alive < int(boss_def["ring_hold"]):
		_break_ring()
	if not ring_up and broken_until <= game.elapsed and game.elapsed >= next_ring_at:
		_raise_ring()
	lord_fissure_cd -= delta
	if lord_fissure_cd <= 0.0:
		lord_fissure_cd = float(boss_def["lord_fissure_interval"])
		_ring_fissures(int(boss_def["ring_fissures"]))
	if broken_until > game.elapsed:
		_hold(delta)  # Staggered: open to every blow.
		return
	if _step_act(delta):
		return
	if _try_bident():
		return
	_walk(delta, float(boss_def["lord_speed_mult"]))


## Raises his ring: Tartarus Wardens on posts around him (the hard cap respected).
func _raise_ring() -> void:
	next_ring_at = INF
	var n := int(boss_def["ring_count"])
	var r := float(boss_def["ring_radius"])
	var raised := 0
	ring.clear()
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var a := TAU * float(i) / float(n)
		var e := game.enemies.spawn_at(UnderworldEnemyData.WARDEN, position + Vector2.from_angle(a) * r, false)
		if e == null:
			continue
		e.max_hp *= float(boss_def["ring_warden_hp"])
		e.hp = e.max_hp
		if e.kit is TartarusWardenKit:
			(e.kit as TartarusWardenKit).bind(self, a, r)
		ring.append([e, e.generation])
		raised += 1
	ring_up = raised >= int(boss_def["ring_hold"])
	game.stat_add("hades_rings", 1.0)
	game.stat_add("hades_wardens", float(raised))
	game.stat_add("boss_atk_ring", 1.0)
	game.effects.ring(position, r * 1.6, Palette.PANTHEON_AEGEAN, 0.8)
	Sfx.play("hades_rise", position, 1.2)


## Living Wardens of his ring.
func _ring_alive() -> int:
	var n := 0
	for rec: Array in ring:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			n += 1
	return n


## The ring breaks: he staggers, open, and raises a new one later.
func _break_ring() -> void:
	ring_up = false
	broken_until = game.elapsed + float(boss_def["broken_time"])
	next_ring_at = broken_until + float(boss_def["reraise_time"])
	act = Act.NONE
	game.stat_add("hades_ring_breaks", 1.0)
	game.enemies.show_banner("His ring breaks: Hades staggers! Strike now!")
	game.effects.impact(position, radius * 3.0, Palette.PANTHEON_MARBLE_LIGHT)
	game.shake(6.0)
	Sfx.play("shield_break", position)
	queue_redraw()


## Living summons on the ground within `r` px of `pos`.
func _summons_near(pos: Vector2, r: float) -> int:
	game.ally_grid.query(pos, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and not u.airborne and u.position.distance_to(pos) <= r + u.radius:
			n += 1
	return n


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): his ring
## crumbles, his marks fade, and he KNEELS and gives up his crown.
func _on_defeated() -> void:
	var pos := position
	for rec: Array in ring:
		var e: Enemy = rec[0]
		if e.active and e.generation == int(rec[1]):
			game.effects.pop(e.position, Palette.PANTHEON_MARBLE, 14.0)
			game.enemies.despawn(e)
	ring.clear()
	marks.clear()
	hazards.start_finale(pos, game.player.position)
	game.effects.ring(pos, 200.0, Palette.NECRO_GREEN, 1.0)
	game.effects.ring(pos, 120.0, Palette.GOLD, 0.8)
	Juice.fx.burst(pos, Palette.NECRO_GREEN, Palette.PANTHEON_AEGEAN_LIGHT, 24, 300.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("hades_kneel", pos)
	var late := game.countdown_finished()  # He fell during the Twilight.
	game.enemies.show_banner(String(HadesData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + HadesData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = HadesData.LATE_ANNOUNCE if late else HadesData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NECRO_GREEN)
	game.stats["hades_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of the bident cone (the god
## shades' lanes are HadesHazards' own, the fissures DivineWrath's).
func danger_push(p: Vector2) -> Vector2:
	var push := hazards.danger_push(p) if hazards != null else Vector2.ZERO
	if act == Act.BIDENT_WINDUP:
		var away := p - position
		if CovenantKit.in_sector(position, _bident_dir, float(boss_def["bident_range"]) + 24.0, float(boss_def["bident_half_arc"]) + 0.2, radius, p, 12.0):
			var n := away.normalized() if away.length() > 0.1 else Vector2.RIGHT
			push += n
	return push


## Body layer on `ci`: his sprite (BossPoseData pose 1 while he sweeps or
## changes phase), only a faint shimmer while cloaked (no sprite, no shadow),
## the glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	if cloaked:
		UnderworldGlyphs.draw_helm_shimmer(ci, radius, game.elapsed if game != null else 0.0)  # No sprite, no shadow: only a shimmer.
		return
	var alpha := 1.0
	if phase == Phase.ARRIVING:
		alpha = clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.15, 1.0)
	var tint := Color(1.0, 1.0, 1.0, alpha)
	var pose := 1 if (act == Act.BIDENT_WINDUP or phase == Phase.CHANGING) else 0
	if SpriteBank.draw_pose(ci, "bosses/hades", pose, Vector2.ZERO, flash > 0.0, tint):
		return
	UnderworldGlyphs.draw_hades(ci, Vector2.ZERO, radius, flash > 0.0, alpha, pose)


## Overlay layer on `ci`: the stagger stars, the ring's shield glow, ice.
func _draw_over(ci: CanvasItem) -> void:
	if cloaked:
		return
	if phase == Phase.LORD and ring_up:
		ci.draw_arc(Vector2.ZERO, radius * 1.5, 0.0, TAU, 32, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.5), 2.0)
	if broken_until > (game.elapsed if game != null else 0.0):
		ReaperHorrorGlyphs.draw_stun(ci, Vector2(0, marker_y(-radius * 1.6)), radius)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of his fight (phase times relative to his arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("hades_spawn_time", -1.0))
	var rel := func(key: String) -> String:
		return "%.1fs" % (float(st[key]) - t0) if st.has(key) else "-"
	var gods := PackedStringArray()
	for g: Dictionary in HadesData.GOD_SHADES:
		var id := String(g["id"])
		if st.has("hades_god_" + id):
			gods.append("%s %d%s" % [id, int(st["hades_god_" + id]), " (art)" if st.has("hades_god_art_" + id) else ""])
	return "phases: reclaiming %s, lord %s, kneels %s | helm: cloaks %d, reveals %d, footprints %d, ring fissures %d | bident %d (you hit %d) | marks %d, taken %d, shades risen %d | gods %d (%s) | rings %d (wardens %d), breaks %d | dmg to you: bident %d, god shades %d | dmg to summons: bident %d, god shades %d" % [
		rel.call("hades_reclaim_at"), rel.call("hades_lord_at"), "%.1fs" % float(st["hades_kill_time"]) if st.has("hades_kill_time") else "-",
		int(st.get("hades_cloaks", 0.0)), int(st.get("hades_reveals", 0.0)), int(st.get("hades_footprints", 0.0)), int(st.get("hades_ring_fissures", 0.0)),
		int(st.get("boss_atk_bident", 0.0)), int(st.get("hades_bident_player_hits", 0.0)),
		int(st.get("hades_marks", 0.0)), int(st.get("hades_taken", 0.0)), int(st.get("hades_shades_risen", 0.0)),
		int(st.get("hades_gods", 0.0)), ", ".join(gods) if not gods.is_empty() else "none",
		int(st.get("hades_rings", 0.0)), int(st.get("hades_wardens", 0.0)), int(st.get("hades_ring_breaks", 0.0)),
		int(st.get("player_dmg_from_" + SRC_BIDENT, 0.0)), int(st.get("player_dmg_from_" + SRC_GOD, 0.0)),
		int(st.get("summon_dmg_from_" + SRC_BIDENT, 0.0)), int(st.get("summon_dmg_from_" + SRC_GOD, 0.0))]
