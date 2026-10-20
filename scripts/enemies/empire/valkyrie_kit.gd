## ValkyrieKit — VALKYRIE 2.0, the Iron Citadel's miniboss (CitadelEnemyData
## "valkyrie_prime", kit "valkyrie"; Act III; GDD §15.0 "The Iron Citadel (Act
## III phase 2)"; owner-approved proposal: "the upgraded leader of the Valkyrie
## Duelists, with a jet dash, a shield bash and a blade storm"; female, in the
## figure-redesign style). A CYBORG. CitadelDirector sends her once (the
## "valkyrie" timeline event) with an escort of Duelists. She walks at the
## necromancer (strides faster beyond advance_range: never kites, never left
## behind), slashes what she reaches, and between attack_gap pauses uses one of
## three telegraphed specials, the first usable one in a fixed rotation (no RNG):
##   Jet dash    — a lane (dash_width wide, up to dash_length px, obstacles cut
##                 it) toward the necromancer for dash_telegraph s, then she
##                 rockets along it: the necromancer in it takes
##                 dash_damage_player once; each summon in it takes
##                 dash_damage_summon and is thrown aside, except a heavy blocker
##                 (block_mass >= dash_block_mass) that stops the dash dead.
##   Shield bash — the necromancer or 3+ summons within bash_range: a frontal
##                 cone (bash_reach, +-bash_half_arc) for bash_telegraph s, then
##                 her tower shield slams through it (damage, knockback).
##   Blade storm — a ring (storm_radius) around her for storm_telegraph s, then
##                 she spins for storm_time s, both blades out, drifting slowly
##                 after the necromancer: every body inside is cut every
##                 storm_tick s.
## Like a boss she shrugs off knockback; Stasis and freezes hold her only for
## the boss share (Enemy.is_miniboss); she is never recycled. She registers as
## EnemyDirector.miniboss for the HUD's bar. On death: an XP burst, a Soul Ash
## bounty (objective_ash, reward_ash) and the miniboss chest (ChestManager).
## Stats: valkyrie_spawned, valkyrie_dashes, valkyrie_dashes_blocked,
## valkyrie_bashes, valkyrie_storms, valkyrie_dash_player_hits,
## valkyrie_bash_player_hits, valkyrie_storm_player_hits, valkyrie_summon_hits,
## valkyrie_kills, valkyrie_ttk (s alive); damage as player_dmg_from_valkyrie_*.
class_name ValkyrieKit
extends CovenantKit

## Phase: the dash lane is telegraphed.
const DASH_WINDUP: int = 1
## Phase: she rockets along the lane.
const DASH: int = 2
## Phase: the bash cone is telegraphed.
const BASH_WINDUP: int = 3
## Phase: the storm ring is telegraphed.
const STORM_WINDUP: int = 4
## Phase: the blade storm spins.
const STORM: int = 5
## Phase: standing after a special.
const RECOVER: int = 6
## The specials in rotation order.
const SPECIALS := ["dash", "bash", "storm"]

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## Index into SPECIALS of the special tried first next time (the rotation).
var _next: int = 0
## Unit direction of the current dash / bash.
var dir: Vector2 = Vector2.RIGHT
## Px of the dash lane still to travel.
var left: float = 0.0
## Length (px) of the telegraphed dash lane.
var lane: float = 0.0
## Seconds until the storm's next cut on the bodies inside.
var _storm_tick: float = 0.0
## True once the current dash struck the necromancer.
var _hit_player: bool = false
## SummonedUnit -> generation of every summon the current dash hit.
var _hits: Dictionary = {}
## Walking speed before the forced march (read on the first tick; -1 = not yet).
var _base_speed: float = -1.0
## Game time she spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SPECIALS:
		cds[id] = 0.0
	_next = 0
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	_hits.clear()
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("valkyrie_spawned", 1.0)


## Picks the next special when ready (the first usable one in the rotation).
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var g := e.game
	var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
	for k in SPECIALS.size():
		var id: String = SPECIALS[(_next + k) % SPECIALS.size()]
		if float(cds[id]) > 0.0:
			continue
		var ok := false
		match id:
			"dash":
				ok = not g.ultimates.player_untargetable() and dist >= float(d["dash_range_min"]) and dist <= float(d["dash_range_max"])
			"bash":
				ok = dist <= float(d["bash_range"]) or _summons_near(g, e.position, float(d["bash_range"])) >= 3
			"storm":
				ok = dist <= float(d["storm_radius"]) * 1.6 or _summons_near(g, e.position, float(d["storm_radius"])) >= 4
		if ok:
			_next = (_next + k + 1) % SPECIALS.size()
			_start(e, id)
			return


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	for id: String in SPECIALS:
		cds[id] = float(cds[id]) - delta
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
		return false
	phase_time += delta
	match phase:
		DASH_WINDUP:
			hold(e)
			if phase_time >= float(d["dash_telegraph"]):
				_hit_player = false
				_hits.clear()
				left = lane
				Sfx.play("jet_burst", e.position, 0.8)
				e.motion_lunge(dir, MotionData.POWER_MELEE)
				set_phase(e, DASH)
		DASH:
			_dash_move(e, delta)
			if left <= 0.0 and phase == DASH:
				set_phase(e, RECOVER)
		BASH_WINDUP:
			hold(e)
			if phase_time >= float(d["bash_telegraph"]):
				_bash(e)
				set_phase(e, RECOVER)
		STORM_WINDUP:
			hold(e)
			if phase_time >= float(d["storm_telegraph"]):
				_storm_tick = 0.0
				Sfx.play("blade_storm", e.position)
				set_phase(e, STORM)
		STORM:
			_storm(e, delta)
			if phase_time >= float(d["storm_time"]):
				set_phase(e, RECOVER)
		RECOVER:
			hold(e)
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts special `id`: its telegraph, cooldown and stat.
func _start(e: Enemy, id: String) -> void:
	var g := e.game
	cds[id] = float(d[id + "_cooldown"])
	var to_p := g.player.position - e.position
	dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	match id:
		"dash":
			lane = g.arena.clear_length(e.position, dir, float(d["dash_length"]), e.radius * 0.7)
			if lane < float(d["dash_range_min"]) * 0.5:
				cds[id] = 1.0  # An obstacle in the way: try the next special.
				return
			g.effects.telegraph_line(e.position, e.position + dir * lane, float(d["dash_width"]), float(d["dash_telegraph"]), e)
			g.stat_add("valkyrie_dashes", 1.0)
			set_phase(e, DASH_WINDUP)
		"bash":
			g.effects.telegraph_cone(e.position, dir, float(d["bash_reach"]), float(d["bash_half_arc"]), float(d["bash_telegraph"]), e)
			g.stat_add("valkyrie_bashes", 1.0)
			e.motion_lunge(dir, MotionData.POWER_CAST)
			set_phase(e, BASH_WINDUP)
		"storm":
			g.effects.telegraph_circle(e.position, float(d["storm_radius"]), float(d["storm_telegraph"]), e)
			g.stat_add("valkyrie_storms", 1.0)
			set_phase(e, STORM_WINDUP)


## One tick of the jet dash along its lane.
func _dash_move(e: Enemy, delta: float) -> void:
	var g := e.game
	var spd := float(d["dash_speed"])
	var step_len := minf(spd * delta, left)
	e.position += dir * step_len
	left -= step_len
	e.velocity = dir * spd
	var hit_r := float(d["dash_width"]) * 0.5  # Half the lane width (px).
	var mult := hit_scale(e)
	var pl := g.player
	if not _hit_player and pl.position.distance_to(e.position) <= hit_r + pl.radius:
		_hit_player = true
		g.combat.damage_player(float(d["dash_damage_player"]) * mult, "valkyrie_dash")
		g.stat_add("valkyrie_dash_player_hits", 1.0)
	g.ally_grid.query(e.position, hit_r + e.radius + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if _hits.has(u) and int(_hits[u]) == u.generation:
			continue
		var rel := u.position - e.position
		if rel.length() > hit_r + u.radius + e.radius * 0.5:
			continue
		_hits[u] = u.generation
		g.stat_add("valkyrie_summon_hits", 1.0)
		if u.block_mass >= float(d["dash_block_mass"]):
			left = 0.0  # A heavy blocker stops the dash dead.
			g.combat.damage_unit(u, float(d["dash_damage_summon"]) * mult * 0.5, "valkyrie_dash")
			g.effects.slash(e.position + dir * e.radius, dir, Palette.COLD_BLUE, e.radius * 1.6)
			Sfx.play("blade_clang", e.position, 0.8)
			g.stat_add("valkyrie_dashes_blocked", 1.0)
			set_phase(e, RECOVER)
			return
		var side := rel - dir * rel.dot(dir)
		var push := side.normalized() if side.length() > 0.1 else Vector2(-dir.y, dir.x)
		u.position += push * float(d["dash_knockback"])
		g.combat.damage_unit(u, float(d["dash_damage_summon"]) * mult, "valkyrie_dash")


## The shield bash lands: every body in the cone is hit and thrown back.
func _bash(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["bash_reach"])
	var half := float(d["bash_half_arc"])
	var mult := hit_scale(e)
	g.effects.impact(e.position + dir * reach * 0.5, reach * 0.6, Palette.EMPIRE_CHROME_LIGHT)
	g.shake(5.0)
	Sfx.play("shield_bash", e.position)
	for pl in g.all_players:  # (Co-op: every necromancer inside.)
		if in_sector(e.position, dir, reach, half, e.radius, pl.position, pl.radius):
			g.combat.damage_player(float(d["bash_damage_player"]) * mult, "valkyrie_bash", pl)
			g.stat_add("valkyrie_bash_player_hits", 1.0)
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			continue
		var away := u.position - e.position
		u.position += (away.normalized() if away.length() > 0.5 else dir) * float(d["bash_knockback"])
		g.combat.damage_unit(u, float(d["bash_damage_summon"]) * mult, "valkyrie_bash")
		g.stat_add("valkyrie_summon_hits", 1.0)


## One tick of the blade storm: she drifts after the necromancer and cuts every
## body inside her ring each storm_tick s.
func _storm(e: Enemy, delta: float) -> void:
	var g := e.game
	var to_p := g.player.position - e.position
	if to_p.length() > 4.0:
		e.velocity = to_p.normalized() * e.move_speed * float(d["storm_move_mult"])
		e.position += e.velocity * delta
	_storm_tick -= delta
	if _storm_tick > 0.0:
		return
	_storm_tick += float(d["storm_tick"])
	var r := float(d["storm_radius"])
	var mult := hit_scale(e)
	for pl in g.all_players:  # (Co-op: every necromancer inside.)
		if pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(float(d["storm_damage_player"]) * mult, "valkyrie_storm", pl)
			g.stat_add("valkyrie_storm_player_hits", 1.0)
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(e.position) > r + u.radius:
			continue
		g.combat.damage_unit(u, float(d["storm_damage_summon"]) * mult, "valkyrie_storm")
		g.stat_add("valkyrie_summon_hits", 1.0)
	g.effects.ring(e.position, r, Palette.EMPIRE_SIGNAL_AMBER, 0.2)


## Living summons on the ground within `r` px of `pos` (body edges included).
func _summons_near(g: Game, pos: Vector2, r: float) -> int:
	g.ally_grid.query(pos, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0  # Summons inside.
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(pos) <= r + u.radius:
			n += 1
	return n


# =====================================================================================
# Death, hints, drawing
# =====================================================================================

## XP burst and Soul Ash bounty on death (the chest comes from ChestManager's
## miniboss rule).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.EMPIRE_SIGNAL_AMBER)
	g.shake(10.0)
	g.enemies.show_banner("%s goes offline!" % e.display_name)
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.stat_add("valkyrie_kills", 1.0)
	g.stat_add("valkyrie_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the dash lane, the bash cone and the storm ring.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	var away := p - e.position
	var n := away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	match phase:
		DASH_WINDUP:
			var along := away.dot(dir)
			var perp := Vector2(-dir.y, dir.x)
			var off := away.dot(perp)
			if along > -20.0 and along < lane + 30.0 and absf(off) < float(d["dash_width"]) * 0.5 + 28.0:
				return perp if off >= 0.0 else -perp
		BASH_WINDUP:
			if in_sector(e.position, dir, float(d["bash_reach"]) + 24.0, float(d["bash_half_arc"]) + 0.2, e.radius, p, 12.0):
				return n
		STORM_WINDUP, STORM:
			if away.length() < float(d["storm_radius"]) + 30.0:
				return n
	return Vector2.ZERO


## Jets while dashing, the spinning blades of the storm. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	match phase:
		DASH_WINDUP, DASH:
			unmirror(e, ci)
			CitadelGlyphs.draw_jets(ci, -dir * (e.radius * 0.7), -dir, e.radius * 1.3, phase == DASH)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		STORM:
			unmirror(e, ci)
			CitadelGlyphs.draw_blade_storm(ci, float(d["storm_radius"]), e.game.elapsed)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
