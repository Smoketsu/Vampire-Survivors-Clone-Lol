## HarbourmasterKit — the Harbourmaster, Gullhaven Harbour's miniboss (Act II;
## HarbourEnemyData "harbourmaster", GDD §15.0 "Gullhaven Harbour (Act II phase
## 2)"; owner-approved proposal "a hulking Deep Kin with a chained anchor. It
## sweeps the anchor in an arc and drags whatever it hits toward itself. It
## drops the stage's miniboss chest"). Spawned once by HarbourDirector through
## the normal spawn path. It walks at the necromancer (strides faster beyond
## advance_range: it never kites and is never left behind), punches what it
## reaches, and between attack_gap pauses uses one of two telegraphed specials:
##   Anchor sweep — a sector (sweep_radius px, +-sweep_half_angle) toward the
##                  necromancer for sweep_telegraph s, then the anchor swings
##                  through it: summons inside take sweep_damage_summon and are
##                  dragged sweep_drag of the way toward him (stopping
##                  sweep_drag_gap px off his body); the necromancer inside
##                  takes sweep_damage_player and is dragged the same way, at
##                  most sweep_player_drag_max px (never during a Grave Step).
##   Anchor hurl  — a lane (hurl_length x hurl_width, cut short by obstacles)
##                  toward the necromancer for hurl_telegraph s, then the
##                  anchor flies down it in hurl_flight s: the FIRST body it
##                  strikes (a summon or the necromancer) takes the hurl damage
##                  and is reeled in beside him (the necromancer at most
##                  hurl_player_drag_max px). Undead in the lane shield their
##                  master: the anchor stops on the first.
## The two specials alternate when both are usable (no RNG). Like a boss it
## shrugs off knockback; freeze / stun durations use the caller's boss share
## and Stasis holds it only for the boss share (Enemy.is_miniboss); it is never
## recycled and swims (HarbourStage.TIDE "swimmers"). It registers as
## EnemyDirector.miniboss for the HUD's health bar. On death: an XP burst
## (reward_xp in reward_crystals) and the miniboss chest (ChestManager).
## Stats: harbourmaster_sweeps, harbourmaster_hurls, harbourmaster_drags
## (summons dragged), harbourmaster_reels (bodies reeled in),
## harbourmaster_player_drags, harbourmaster_kills, harbourmaster_ttk.
class_name HarbourmasterKit
extends CovenantKit

## Phase: the sweep sector is telegraphed.
const SWEEP_WINDUP: int = 1
## Phase: the hurl lane is telegraphed.
const HURL_WINDUP: int = 2
## Phase: the anchor flies down the lane.
const HURL_FLIGHT: int = 3
## Phase: standing after a special.
const RECOVER: int = 4
## Special ids in alternation order.
const SPECIALS := ["sweep", "hurl"]
## Damage source tags (the sweep is an area hit for Unholy Resilience).
const SWEEP_SOURCE: String = "harbourmaster_sweep"
const HURL_SOURCE: String = "harbourmaster_hurl"

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## The special used last (the other one goes next when both are usable).
var last_special: String = ""
## Unit direction of the current special (locked at its windup).
var dir: Vector2 = Vector2.RIGHT
## Length (px) of the current hurl lane.
var lane: float = 0.0
## Distance (px) the anchor has flown along the lane.
var tip: float = 0.0
## Walking speed before the forced march (px/s; read on the first tick so the
## difficulty's speed multiplier is included; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SPECIALS:
		cds[id] = 0.0
	last_special = ""
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("harbourmaster_spawned", 1.0)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
	var sweep_ok := float(cds["sweep"]) <= 0.0 and dist <= float(d["sweep_range"])
	var hurl_ok := float(cds["hurl"]) <= 0.0 and dist >= float(d["hurl_min_range"]) and dist <= float(d["hurl_range"])
	if sweep_ok and hurl_ok:
		if last_special == "sweep":
			sweep_ok = false
		else:
			hurl_ok = false
	var to_p := e.game.player.position - e.position
	dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	if sweep_ok:
		e.game.effects.telegraph_cone(e.position, dir, float(d["sweep_radius"]), float(d["sweep_half_angle"]), float(d["sweep_telegraph"]), e)
		e.motion_lunge(dir, MotionData.POWER_CAST)  # Engine motion: the anchor raised (visual only).
		_begin(e, "sweep", SWEEP_WINDUP)
	elif hurl_ok:
		lane = e.game.arena.clear_length(e.position, dir, float(d["hurl_length"]), float(d["hurl_width"]) * 0.4)
		e.game.effects.telegraph_line(e.position, e.position + dir * lane, float(d["hurl_width"]), float(d["hurl_telegraph"]), e)
		e.motion_lunge(-dir, MotionData.POWER_CAST)  # Engine motion: the wind-up (visual only).
		_begin(e, "hurl", HURL_WINDUP)


## Starts special `id`: cooldown, stat, phase.
func _begin(e: Enemy, id: String, p: int) -> void:
	last_special = id
	cds[id] = float(d[id + "_cooldown"])
	e.game.stat_add("harbourmaster_%ss" % id, 1.0)
	set_phase(e, p)


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
	hold(e)
	match phase:
		SWEEP_WINDUP:
			if phase_time >= float(d["sweep_telegraph"]):
				_resolve_sweep(e)
				set_phase(e, RECOVER)
		HURL_WINDUP:
			if phase_time >= float(d["hurl_telegraph"]):
				tip = 0.0
				Sfx.play("spear_cast", e.position, 0.6)
				set_phase(e, HURL_FLIGHT)
		HURL_FLIGHT:
			e.queue_redraw()
			var prev := tip  # Anchor distance last tick.
			tip = minf(lane, lane * phase_time / maxf(0.01, float(d["hurl_flight"])))
			if _hurl_tick(e, prev, tip) or tip >= lane:
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## The anchor swings through the sector: hits and drags.
func _resolve_sweep(e: Enemy) -> void:
	var g := e.game
	var r := float(d["sweep_radius"])
	var half := float(d["sweep_half_angle"])
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	g.effects.slash(e.position + dir * e.radius, dir, Palette.EYE_DROWNED, r * 0.8)
	e.motion_lunge(dir, MotionData.POWER_MELEE)  # Engine motion: the swing (visual only).
	g.shake(7.0)
	Sfx.play("boss_impact", e.position, 0.9)
	var dragged := 0  # Summons dragged in.
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, r, half, e.radius, u.position, u.radius):
			continue
		dragged += 1
		u.position = _dragged(e, u.position, u.radius, float(d["sweep_drag"]), INF)
		g.combat.damage_unit(u, float(d["sweep_damage_summon"]) * mult, SWEEP_SOURCE)
	g.stat_add("harbourmaster_drags", float(dragged))
	for p in g.all_players:  # (Co-op: every necromancer inside, each by his own dash.)
		if in_sector(e.position, dir, r, half, e.radius, p.position, p.radius):
			g.combat.damage_player(float(d["sweep_damage_player"]) * mult, SWEEP_SOURCE, p)
			if not p.dash.is_dashing():
				p.position = _dragged(e, p.position, p.radius, float(d["sweep_drag"]), float(d["sweep_player_drag_max"]))
				g.stat_add("harbourmaster_player_drags", 1.0)


## Where a body of radius `r` at `pos` ends after being dragged `share` of the
## way toward the Harbourmaster (stopping sweep_drag_gap px off his body),
## at most `cap` px.
func _dragged(e: Enemy, pos: Vector2, r: float, share: float, cap: float) -> Vector2:
	var rel := pos - e.position
	var dist := rel.length()
	var stop := e.radius + r + float(d["sweep_drag_gap"])  # Closest it is pulled.
	if dist <= stop:
		return pos
	var target := e.position + rel / dist * stop  # Right beside him.
	var moved := pos.lerp(target, share) - pos  # The drag.
	return pos + moved.limit_length(cap)


## The anchor flew from `from` to `to` px along the lane this tick: the first
## body it touches is hit and reeled in. Returns true once it struck.
func _hurl_tick(e: Enemy, from: float, to: float) -> bool:
	var g := e.game
	var half_w := float(d["hurl_width"]) * 0.5
	var mid := e.position + dir * (from + to) * 0.5  # Query centre.
	var best: Node2D = null  # First body along the lane this tick.
	var best_along := INF
	g.ally_grid.query(mid, absf(to - from) * 0.5 + half_w + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var along := _along_if_hit(e, u.position, u.radius, from, to, half_w)
		if along < best_along:
			best_along = along
			best = u
	var p := g.player  # The necromancer reeled (co-op: the first one the anchor touches).
	for q in g.all_players:
		var pa := _along_if_hit(e, q.position, q.radius, from, to, half_w)
		if pa < best_along:
			best_along = pa
			best = q
			p = q
	if best == null:
		return false
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	var beside := e.position + dir * (e.radius + 14.0)  # Where the reeled body lands.
	g.effects.impact(best.position, 26.0, Palette.EYE_DROWNED, "tide_splash")
	Sfx.play("boss_impact", best.position, 1.2)
	if best is SummonedUnit:
		var u := best as SummonedUnit
		u.position = beside + dir * u.radius
		g.combat.damage_unit(u, float(d["hurl_damage_summon"]) * mult, HURL_SOURCE)
	else:
		g.combat.damage_player(float(d["hurl_damage_player"]) * mult, HURL_SOURCE, p)
		if not p.dash.is_dashing():
			p.position += (beside + dir * p.radius - p.position).limit_length(float(d["hurl_player_drag_max"]))
			g.stat_add("harbourmaster_player_drags", 1.0)
	g.stat_add("harbourmaster_reels", 1.0)
	return true


## Distance along the lane of a body of radius `r` at `pos` the anchor touched
## between `from` and `to` px (INF when it did not).
func _along_if_hit(e: Enemy, pos: Vector2, r: float, from: float, to: float, half_w: float) -> float:
	var rel := pos - e.position
	var along := rel.dot(dir)
	if along < from - r or along > to + r or along < e.radius:
		return INF
	if absf(rel.cross(dir)) > half_w + r:
		return INF
	return along


## XP burst on death (the chest comes from ChestManager's miniboss rule).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.EYE_DROWNED, "tide_splash")
	g.shake(10.0)
	g.enemies.show_banner("The Harbourmaster sinks beneath the waves!")
	g.stat_add("harbourmaster_kills", 1.0)
	g.stat_add("harbourmaster_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the sweep sector / the hurl lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		SWEEP_WINDUP:
			if in_sector(e.position, dir, float(d["sweep_radius"]) + 30.0, float(d["sweep_half_angle"]) + 0.2, e.radius, p, 12.0):
				var away := p - e.position
				return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
		HURL_WINDUP:
			var rel := p - e.position
			if rel.dot(dir) > 0.0 and absf(rel.cross(dir)) < float(d["hurl_width"]) * 0.5 + 30.0:
				var side := Vector2(-dir.y, dir.x)
				return side * (1.0 if rel.dot(side) >= 0.0 else -1.0)
	return Vector2.ZERO


## The anchor raised (windups) and flying down the lane on its chain.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	match phase:
		SWEEP_WINDUP, HURL_WINDUP:
			unmirror(e, ci)
			HarbourGlyphs.draw_anchor(ci, Vector2(0, -e.radius * 1.3), e.radius * 0.45, false)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		HURL_FLIGHT:
			unmirror(e, ci)
			var at := dir * tip  # The anchor's position relative to him.
			HarbourGlyphs.draw_chain(ci, dir * e.radius * 0.6, at)
			HarbourGlyphs.draw_anchor(ci, at, e.radius * 0.45, false)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
