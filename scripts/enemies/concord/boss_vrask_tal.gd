## BossVraskTal — VRASK'TAL, THE HUNT-LORD, the boss of the Proving Moon (Act IX,
## Stage 26; GDD §15.0 "Vrask'Tal, the Hunt-Lord (Act IX)"; owner-approved
## proposal: "the Stalk (cloaked, picking summons off the ring's edge; each
## kill hangs a skull on his belt), the Duel (he drops his cloak and fights the
## necromancer with a glaive, leaping over the ring), the Last Trophy (he arms
## the bomb on his wrist: a 20 s countdown he tries to finish standing next to
## the necromancer)"). Loaded by name for the boss id "vrask_tal"
## (EnemyDirector.CONCORD_BOSS_DIR + "boss_vrask_tal.gd"); he arrives at 17:00
## (3:00 left). Extends Boss, so summons, spells and the spatial hash treat him
## like any enemy. Every ability is telegraphed; the numbers and the three
## phases are VraskTalData's (see its header):
##   * THE STALK: cloaked while he moves (the Vrask hunter's mechanism,
##     VraskHunterKit.cloak_hit_mult() through damage_taken_mult(); a spell hit
##     reveals him), hunting the ring's edge (think(): the summon near him
##     farthest from its necromancer); his glaive is the shared melee
##     (_melee_hit()); his caster locks his prey (ConcordBeams.fire(), boss
##     override). Every summon his blows kill hangs a SKULL on his belt
##     (_melee_hit() / the leap; hit_mult(): +skull_step each, capped).
##   * THE DUEL: the cloak dropped for good; he walks at the necromancer, his
##     caster locks him, and he LEAPS OVER THE RING onto him (a landing circle;
##     the reach and the throw x the low gravity, ConcordRules.gravity()).
##   * THE LAST TROPHY: the 20 s countdown (trophy_left(), shown as HUD text by
##     ProvingMoonDirector.objective_override() and a banner every 5 s; never a
##     screen effect); his death in time defuses it (the run stat
##     VraskTalData.HUNTED_STAT: the achievement The Hunter Hunted); else THE
##     BOMB, _detonate(), the one path, which kills him too (the boss kill
##     counts for the unlock chain, never for the achievement).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks Soul
## Caster and Trophy Rack (UnlockData, boss "vrask_tal"). No RNG (the prey is
## chosen from the ally grid's deterministic order). Stats: boss_atk_<special>,
## vrask_tal_skulls, vrask_tal_prey_kills, vrask_tal_cloak_cut,
## vrask_tal_reveals, vrask_tal_cloaked_time, vrask_tal_leap_hits, vrask_tal_leap_reach_max,
## vrask_tal_phase2_at, vrask_tal_phase3_at, vrask_tal_bomb_at,
## vrask_tal_bomb_summons, vrask_tal_bomb_dmg_you, vrask_tal_defused_left,
## proving_moon_hunter_hunted, vrask_tal_bombed.
class_name BossVraskTal
extends Boss

## Boss action phases.
enum Phase { WALK, LEAP_WINDUP, LEAP, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His form: 1 the Stalk, 2 the Duel, 3 the Last Trophy.
var form: int = 1
## Skulls on his belt (summons his blows killed; capped at skull_cap for the damage).
var skulls: int = 0
## True while he is cloaked (the Stalk, moving, not revealed).
var cloaked: bool = false
## Game time (s) until which he is revealed (a spell hit, his own caster's shot).
var revealed_until: float = 0.0
## Seconds until his caster may lock again.
var lock_cd: float = 0.0
## Seconds until his next leap (the Duel on).
var leap_cd: float = INF
## Seconds until he chooses his prey again (the Stalk).
var prey_cd: float = 0.0
## Seconds left of the Last Trophy's countdown (-1 = none running).
var trophy_left_s: float = -1.0
## True once the bomb went off (no second one).
var bombed: bool = false
## Countdown second of the next "The Last Trophy: n s" banner.
var _next_banner: float = INF
## Where a leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where a leap lands (world px; locked at its windup).
var _to: Vector2 = Vector2.ZERO
## Move speed of his current form before the advance bonus (px/s).
var _base_speed: float = 60.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Vrask'Tal at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = VraskTalData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	form = 1
	skulls = 0
	cloaked = false
	revealed_until = 0.0
	lock_cd = float(boss_def["lock_every"]) * 0.5
	leap_cd = INF
	prey_cd = 0.0
	trophy_left_s = -1.0
	bombed = false
	_next_banner = INF
	_base_speed = move_speed
	var r := game.concord_rules()  # The Concord's rules exist wherever he fights (--boss=vrask_tal elsewhere).
	r.play_sound("beam_charge", position)
	game.stat_add("boss_atk_stalk", 1.0)
	game.enemies.show_banner(String(boss_def["stalk_banner"]))


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return VraskTalData.SPECIALS


## True while he walks (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK and not game.concord_rules().beams.has_beam(self)


## Seconds left of the Last Trophy's countdown (-1 when none runs): the HUD
## text (ProvingMoonDirector.objective_override()).
func trophy_left() -> float:
	return trophy_left_s if form == 3 and not bombed else -1.0


## THE SKULLS' damage step: his blows, his leap and his caster (through
## CovenantKit.hit_scale() in ConcordBeams.fire()) deal +skull_step a skull, at
## most skull_cap skulls (the one read).
func hit_mult() -> float:
	return super.hit_mult() * (1.0 + float(boss_def["skull_step"]) * float(mini(skulls, int(boss_def["skull_cap"]))))


## THE CLOAK (the Stalk): the Vrask hunter's hit rule
## (VraskHunterKit.cloak_hit_mult()): while cloaked a summon's or a hazard's
## hit deals cloaked_taken; a spell hit lands in full and reveals him.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if form != 1:
		return m
	var c: Dictionary = boss_def["cloak"]
	if VraskHunterKit.cloak_revealed_by(source):
		if cloaked:
			game.stat_add("vrask_tal_reveals", 1.0)
		_reveal()
		return m
	var cm := VraskHunterKit.cloak_hit_mult(c, source, cloaked)
	if cm < 1.0:
		game.stat_add("vrask_tal_cloak_cut", 1.0)
	return m * cm


## His fall: the Last Trophy is defused when it was counting down; any death
## but his own bomb is the Hunter Hunted (the achievement's run stat).
func deactivate() -> void:
	if active and hp <= 0.0 and not bombed:
		game.stats[VraskTalData.HUNTED_STAT] = 1.0
		if form == 3 and trophy_left_s > 0.0:
			game.stat_add("vrask_tal_defused_left", trophy_left_s)
			game.enemies.show_banner(String(boss_def["defused_banner"]))
	trophy_left_s = -1.0
	super.deactivate()


## His target (5 Hz): the Stalk hunts the ring's edge (_pick_prey()); the Duel
## and the Last Trophy fight the nearest necromancer, unless a blocker holds him
## (the shared engaged rule).
func think() -> void:
	if form == 1:
		if aura_radius > 0.0:
			_pulse_aura()
		if prey_cd <= 0.0 or not _target_valid() or not (target is SummonedUnit):
			prey_cd = float(boss_def["stalk_retarget"])
			_pick_prey()
		targeting_summon = target is SummonedUnit
		targeting_player = target is Necromancer
		return
	super.think()
	if engaged_timer > 0.0 and target is SummonedUnit and _target_valid():
		return
	var pl := game.nearest_player(position)
	if pl != null and not pl.dead:
		_set_target(pl)
		targeting_player = true
		targeting_summon = false


## The Stalk's prey: among the summons within stalk_search px of him, the one
## that stands farthest from the nearest necromancer (the ring's edge); the
## necromancer when none is near.
func _pick_prey() -> void:
	var best: SummonedUnit = null
	var best_d := -1.0
	game.ally_grid.query(position, float(boss_def["stalk_search"]), _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue
		var pl := game.nearest_player(u.position)
		var out := u.position.distance_to(pl.position) if pl != null else 0.0  # px from its necromancer.
		if out > best_d:
			best_d = out
			best = u
	if best != null:
		_set_target(best)
	else:
		_set_target(game.nearest_player(position))


## Boss physics: his forms and phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	lock_cd -= delta
	leap_cd -= delta
	prey_cd -= delta
	if form == 1 and hp <= max_hp * float(boss_def["phase2_hp"]):
		_duel()
	if form == 2 and hp <= max_hp * float(boss_def["phase3_hp"]):
		_last_trophy()
	if form == 3 and not bombed:
		trophy_left_s -= delta
		if trophy_left_s <= _next_banner and _next_banner > 0.0:
			game.enemies.show_banner(String(boss_def["countdown_banner"]) % roundi(_next_banner))
			game.concord_rules().play_sound("beam_charge", position, 1.0)
			_next_banner -= float(boss_def["trophy_banner_every"])
		if trophy_left_s <= 0.0:
			_detonate()
			return
	var beams := game.concord_rules().beams
	if beams.has_beam(self):
		_hold(delta)  # His caster aims and fires: he stands (as every beam firer).
		_set_cloak(false)
		return
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.LEAP_WINDUP:
			_hold(delta)
			if phase_time >= float(boss_def["leap_windup"]):
				_from = position
				_set_phase(Phase.LEAP)
		Phase.LEAP:
			_tick_timers(delta)
			var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
			position = _from.lerp(_to, k)
			velocity = Vector2.ZERO
			queue_redraw()  # The arc.
			if k >= 1.0:
				_land_leap()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)
	_update_cloak()


## Walking: the shared walk and glaive at his target; his caster and his leap
## start when ready.
func _step_walk(delta: float) -> void:
	var pl := game.nearest_player(position)
	var dist := position.distance_to(pl.position)  # To the necromancer (px).
	var spd := _base_speed
	if form == 3:
		spd *= float(boss_def["trophy_speed_mult"])
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)
	if form >= 2 and leap_cd <= 0.0:
		_start_leap(pl)
		if phase != Phase.WALK:
			return
	if form <= 2 and lock_cd <= 0.0:
		_lock()


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
# The cloak and the skulls
# =====================================================================================

## The cloak follows his last step: on while he moves, in the Stalk, unrevealed.
func _update_cloak() -> void:
	var c: Dictionary = boss_def["cloak"]
	_set_cloak(form == 1 and velocity.length() >= float(c.get("min_speed", 8.0)) and game.elapsed >= revealed_until)
	if cloaked:
		game.stat_add("vrask_tal_cloaked_time", get_physics_process_delta_time())


## Switches the cloak (redraws on a change).
func _set_cloak(on: bool) -> void:
	if on != cloaked:
		cloaked = on
		queue_redraw()


## Reveals him for the cloak's reveal_time (a spell hit, his own caster's shot).
func _reveal() -> void:
	revealed_until = maxf(revealed_until, game.elapsed + float((boss_def["cloak"] as Dictionary).get("reveal_time", 2.0)))
	_set_cloak(false)


## His glaive (the shared melee): a summon it kills hangs a skull on his belt.
## (He stands still to cut, which uncloaks him while he strikes, as a hunter
## standing to aim; the cut itself does not reveal him.)
func _melee_hit(t: Node2D, dir: Vector2) -> void:
	var u: SummonedUnit = t as SummonedUnit if t is SummonedUnit else null
	var gen := u.generation if u != null else 0
	super._melee_hit(t, dir)
	if u != null and _killed(u, gen):
		_skull(form == 1)


## True when summon `u` (pool generation `gen` before the blow) died of it.
static func _killed(u: SummonedUnit, gen: int) -> bool:
	return not u.active or u.generation != gen or u.state == SummonedUnit.State.DEAD or u.hp <= 0.0


## One skull on his belt (`prey`: a Stalk kill).
func _skull(prey: bool) -> void:
	skulls += 1
	game.stat_add("vrask_tal_skulls", 1.0)
	if prey:
		game.stat_add("vrask_tal_prey_kills", 1.0)
	queue_redraw()


# =====================================================================================
# The phases
# =====================================================================================

## The Duel: the cloak drops for good; the leaps begin.
func _duel() -> void:
	form = 2
	_set_cloak(false)
	game.stat_add("vrask_tal_phase2_at", game.elapsed)
	game.stat_add("boss_atk_duel", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.effects.ring(position, radius * 2.4, Palette.CONCORD_VRASK, 0.4)
	leap_cd = float(boss_def["first_leap"])
	lock_cd = minf(lock_cd, float(boss_def["lock_every_duel"]))
	_set_target(game.nearest_player(position))
	queue_redraw()


## The Last Trophy: the bomb is armed; the countdown starts (HUD text only).
func _last_trophy() -> void:
	form = 3
	trophy_left_s = float(boss_def["trophy_time"])
	_next_banner = trophy_left_s - float(boss_def["trophy_banner_every"])
	game.stat_add("vrask_tal_phase3_at", game.elapsed)
	game.stat_add("boss_atk_last_trophy", 1.0)
	game.enemies.show_banner(String(boss_def["phase3_banner"]))
	game.concord_rules().play_sound("harvest_eye", position)
	leap_cd = minf(leap_cd, float(boss_def["leap_every_p3"]) * 0.5)
	queue_redraw()


## THE BOMB (the ONE documented path of the Last Trophy's blast; see
## VraskTalData): around where he stands, every necromancer within bomb_radius
## px is left at bomb_hp_left of his max HP (his i-frames cleared first: Grave
## Step does not dodge it; through his ward; never lethal by itself), every
## summon there takes bomb_summon_share of its max HP (destroyed); the enemies
## are spared; Vrask'Tal dies in it (the boss kill counts; the achievement does
## not).
func _detonate() -> void:
	bombed = true
	trophy_left_s = -1.0
	game.stats[VraskTalData.BOMB_STAT] = 1.0
	game.stat_add("boss_atk_bomb", 1.0)
	game.stat_add("vrask_tal_bomb_at", game.elapsed)
	game.enemies.show_banner(String(boss_def["bomb_banner"]))
	game.concord_rules().play_sound("saucer_down", position)
	var r := float(boss_def["bomb_radius"])
	var hit := 0
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.position.distance_to(position) > r + u.radius:
			continue
		game.combat.damage_unit(u, u.max_hp * float(boss_def["bomb_summon_share"]), VraskTalData.BOMB_SOURCE, self)
		hit += 1
	game.stat_add("vrask_tal_bomb_summons", float(hit))
	for pl in game.all_players:
		if pl.dead or pl.position.distance_to(position) > r + pl.radius:
			continue
		var floor_hp := pl.max_hp * float(boss_def["bomb_hp_left"])
		if pl.hp > floor_hp:
			var before := pl.hp
			pl.iframes = 0.0  # Grave Step does not dodge the bomb.
			game.combat.damage_player(pl.hp - floor_hp + pl.shield_hp, VraskTalData.BOMB_SOURCE, pl)  # Through his ward too.
			game.stat_add("vrask_tal_bomb_dmg_you", maxf(0.0, before - pl.hp))
	game.effects.impact(position, r, Palette.CONCORD_LASER, "")
	game.effects.ring(position, r, Palette.CONCORD_VRASK, 0.6)
	game.shake(12.0)
	game.combat.damage_enemy(self, hp * 100.0 + max_hp, VraskTalData.BOMB_SOURCE)  # He dies in his own blast (the boss kill path).


# =====================================================================================
# His caster and his leap
# =====================================================================================

## His shoulder caster: a "lock" beam (three red dots, then a pulse) at his prey
## (the Stalk) or the necromancer (the Duel), through ConcordBeams.fire() with
## the boss override; a refusal retries soon.
func _lock() -> void:
	var t: Node2D = target if _target_valid() else game.nearest_player(position)
	if t == null or t.position.distance_to(position) > float(boss_def["lock_range"]):
		lock_cd = 0.5
		return
	if t is Necromancer and game.ultimates.player_untargetable():
		lock_cd = 1.0
		return
	var over := {"target": t, "dps": float(boss_def["lock_dps"]), "length": float(boss_def["lock_length"]),
		"width": float(boss_def["lock_width"]), "source": VraskTalData.CASTER_SOURCE}
	if game.concord_rules().beams.fire(self, t.position - position, "lock", over, true):
		lock_cd = float(boss_def["lock_every"] if form == 1 else boss_def["lock_every_duel"])
		game.stat_add("boss_atk_lock", 1.0)
		_reveal()
	else:
		lock_cd = float(ConcordRulesData.BEAMS["retry"])


## The leap reach on this stage (px): the row's x the low gravity.
func leap_reach() -> float:
	return float(boss_def["leap_reach"]) * game.concord_rules().gravity()


## The leap over the ring: the landing circle shows where the necromancer
## stands (only from leap_min to leap_reach px; else it waits a moment).
func _start_leap(pl: Necromancer) -> void:
	if pl == null or pl.dead or game.ultimates.player_untargetable():
		leap_cd = 1.0
		return
	var dist := position.distance_to(pl.position)
	if dist < float(boss_def["leap_min"]) or dist > leap_reach():
		leap_cd = 0.5
		return
	leap_cd = float(boss_def["leap_every_p3"] if form == 3 else boss_def["leap_every"])
	_to = game.arena.free_point(pl.position, radius * 0.5)
	game.effects.telegraph_circle(_to, float(boss_def["leap_radius"]), float(boss_def["leap_windup"]), self)
	motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	game.stat_add("boss_atk_leap", 1.0)
	game.stats["vrask_tal_leap_reach_max"] = maxf(float(game.stats.get("vrask_tal_leap_reach_max", 0.0)), dist)
	_set_phase(Phase.LEAP_WINDUP)


## The leap lands: every necromancer and summon in the circle is cut and the
## summons thrown out (x the low gravity); a summon it kills is a skull.
func _land_leap() -> void:
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs x skulls.
	var r := float(boss_def["leap_radius"])
	var gens := {}  # Summon -> its generation before the cut (skulls).
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		gens[u] = u.generation
	game.stat_add("vrask_tal_leap_hits", float(OlympusHits.circle(game, position, r,
			float(boss_def["leap_damage_player"]) * mult, float(boss_def["leap_damage_summon"]) * mult * undead_damage_mult,
			VraskTalData.LEAP_SOURCE, self, float(boss_def["leap_push"]) * game.concord_rules().gravity(), _buf)))
	for u: SummonedUnit in gens:
		if _killed(u, int(gens[u])) and u.position.distance_to(position) <= r + 40.0:
			_skull(false)
	game.effects.impact(position, r, Palette.CONCORD_VRASK)
	game.shake(6.0)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: out of the leap's landing circle,
## and away from him while the Last Trophy counts down (bomb_danger_reach).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if phase == Phase.LEAP_WINDUP or phase == Phase.LEAP:
		var off := p - _to
		var reach := float(boss_def["leap_radius"]) + 24.0
		if off.length() < reach:
			push += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	if form == 3 and not bombed:
		var off := p - position
		var reach := float(boss_def["bomb_danger_reach"])
		if off.length() < reach:
			push += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.0
	return push


## Body layer on `ci`: his sprite in the pose of his phase (pose 1 while he
## crouches to leap or his caster aims), lifted on the leap's arc; a shimmer
## while cloaked (his sprite at the cloak's alpha); a red glow while the bomb
## counts down; his skull belt.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	if phase == Phase.LEAP_WINDUP or (game != null and game.concord != null and game.concord.beams.has_beam(self)):
		pose = 1
	var lift := Vector2.ZERO
	if phase == Phase.LEAP:
		var k := clampf(phase_time / maxf(0.01, float(boss_def["leap_time"])), 0.0, 1.0)
		lift = Vector2(0.0, -float(boss_def["leap_height"]) * 4.0 * k * (1.0 - k))
	if form == 3 and not bombed:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.2), radius * 1.35, Color(Palette.CONCORD_LASER, 0.16))
	var tint := Color.WHITE
	if cloaked:
		var c: Dictionary = boss_def["cloak"]
		var wob := 0.75 + 0.25 * sin(game.elapsed * 9.0)  # The shimmer ripples.
		tint = Color(1.0, 1.0, 1.0, float(c.get("alpha", 0.2)) * wob)
	if not SpriteBank.draw_pose(ci, VraskTalData.SPRITE, pose, lift, flash > 0.0, tint):
		ProvingMoonGlyphs.draw_vrask_tal(ci, lift, radius, flash > 0.0, tint.a, pose == 1)
	if not cloaked:
		ProvingMoonGlyphs.draw_skull_belt(ci, lift + Vector2(0.0, radius * 0.15), radius, mini(skulls, int(boss_def["skull_cap"])))


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: his shadow stays on the ground while he leaps.
func _draw_under() -> void:
	super._draw_under()
	if phase == Phase.LEAP:
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-radius, radius * 0.4), Vector2(radius * 2.0, radius * 0.7)), false, Color(0.0, 0.0, 0.0, 0.35))


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var p2 := float(st.get("vrask_tal_phase2_at", -1.0))
	var p3 := float(st.get("vrask_tal_phase3_at", -1.0))
	var ba := float(st.get("vrask_tal_bomb_at", -1.0))
	var outcome := "not reached"
	if float(st.get(VraskTalData.BOMB_STAT, 0.0)) > 0.0:
		outcome = "BOMB at %s: summons %d, your HP -%d (he died in it)" % [EmpireReport._clock(ba), int(st.get("vrask_tal_bomb_summons", 0.0)), int(st.get("vrask_tal_bomb_dmg_you", 0.0))]
	elif float(st.get(VraskTalData.HUNTED_STAT, 0.0)) > 0.0:
		outcome = ("DEFUSED (%.1f s left)" % float(st.get("vrask_tal_defused_left", 0.0))) if p3 >= 0.0 else "slain before the countdown"
	elif p3 >= 0.0:
		outcome = "counting"
	return "skulls %d (prey kills %d) | cloaked %.1f s, cloak cut %d, reveals %d | locks %d | the Duel %s | leaps %d (hits %d, farthest %d px) | the Last Trophy %s | %s | dmg to you %d, to summons %d" % [
		int(st.get("vrask_tal_skulls", 0.0)), int(st.get("vrask_tal_prey_kills", 0.0)), float(st.get("vrask_tal_cloaked_time", 0.0)),
		int(st.get("vrask_tal_cloak_cut", 0.0)), int(st.get("vrask_tal_reveals", 0.0)), int(st.get("boss_atk_lock", 0.0)),
		EmpireReport._clock(p2) if p2 >= 0.0 else "not reached",
		int(st.get("boss_atk_leap", 0.0)), int(st.get("vrask_tal_leap_hits", 0.0)), int(st.get("vrask_tal_leap_reach_max", 0.0)),
		EmpireReport._clock(p3) if p3 >= 0.0 else "not reached", outcome,
		int(st.get("player_dmg_from_boss", 0.0) + st.get("player_dmg_from_" + VraskTalData.LEAP_SOURCE, 0.0) + st.get("player_dmg_from_" + VraskTalData.CASTER_SOURCE, 0.0) + st.get("player_dmg_from_" + VraskTalData.BOMB_SOURCE, 0.0)),
		int(st.get("summon_dmg_from_boss", 0.0) + st.get("summon_dmg_from_" + VraskTalData.LEAP_SOURCE, 0.0) + st.get("summon_dmg_from_" + VraskTalData.CASTER_SOURCE, 0.0) + st.get("summon_dmg_from_" + VraskTalData.BOMB_SOURCE, 0.0))]
