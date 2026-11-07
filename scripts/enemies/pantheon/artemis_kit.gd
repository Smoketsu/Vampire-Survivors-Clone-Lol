## ArtemisKit — ARTEMIS, THE HUNTRESS, the second god of the Pantheon Trial
## (Act IV, Mount Olympus; GDD §15.0 "The Pantheon Trial"; owner-approved
## proposal: "Volleys of moonlit arrows and her hunting hounds; teleports
## between groves"; female, figure-redesign style). She arrives with 9:30 left
## (OlympusDirector's "god" event, at a moonlit grove), a GodKit (a third of
## Zeus's HP with the boss's scaling, the miniboss bar, a chest). She walks at
## the necromancer with the shared ranged AI (plain arrows; enemies always
## advance) and between specials:
##   Moonlit volley — volley_telegraph s drawing (a fan of pale lines toward
##             the necromancer), then volley_arrows arrows fanned over
##             volley_spread rad (ProjectileManager.fire_hostile(), tagged
##             "artemis_volley").
##   Hunting hounds — hounds_cast s with her horn raised, then hounds_count
##             Hounds of Artemis (OlympusEnemyData "moon_hound") leap out
##             around her (never beyond the enemy hard cap).
##   Teleport — every teleport_cooldown s, or sooner (after teleport_min s)
##             when crowd_summons summons crowd her within crowd_reach px, she
##             fades out (blink_time s, untargetable: out of the enemy hash) and
##             appears at another moonlit grove (OlympusDirector.grove_point();
##             off the Olympus a point on the spawn ring), then fades in.
## Stats: artemis_volleys, artemis_arrows, artemis_hound_calls, artemis_hounds,
## artemis_teleports. No RNG of its own (the grove choice is the director's).
class_name ArtemisKit
extends GodKit

## Phase: drawing a volley.
const VOLLEY: int = 1
## Phase: calling the hounds.
const HOUNDS: int = 2
## Phase: fading out before a teleport.
const BLINK_OUT: int = 3
## Phase: fading in at the new grove.
const BLINK_IN: int = 4

## Seconds until her next volley.
var volley_cd: float = 0.0
## Seconds until her next hound call.
var hounds_cd: float = 0.0
## Seconds until her next teleport.
var teleport_cd: float = 0.0
## Unit direction of the current volley's centre (locked at its windup).
var _aim: Vector2 = Vector2.RIGHT


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	volley_cd = float(d["first_volley"])
	hounds_cd = float(d["first_hounds"])
	teleport_cd = float(d["teleport_cooldown"])
	e.game.enemies.show_banner("ARTEMIS, THE HUNTRESS, steps out of the moonlit grove!")
	rules(e).play_sound("artemis_horn", e.position)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	volley_cd -= delta
	hounds_cd -= delta
	teleport_cd -= delta
	if phase == IDLE:
		_choose(e)
		if phase == IDLE:
			return walk(e)
	phase_time += delta
	hold(e)
	match phase:
		VOLLEY:
			if phase_time >= float(d["volley_telegraph"]):
				_loose(e)
				set_phase(e, IDLE)
		HOUNDS:
			if phase_time >= float(d["hounds_cast"]):
				_release_hounds(e)
				set_phase(e, IDLE)
		BLINK_OUT:
			e.queue_redraw()
			if phase_time >= float(d["blink_time"]):
				_arrive(e)
				set_phase(e, BLINK_IN)
		BLINK_IN:
			e.queue_redraw()
			if phase_time >= float(d["blink_time"]):
				e.untargetable = false
				set_phase(e, IDLE)
	return true


## Starts a special when one is ready: a teleport first (when crowded or due),
## then the hounds, then a volley.
func _choose(e: Enemy) -> void:
	var g := e.game
	var crowded := teleport_cd <= float(d["teleport_cooldown"]) - float(d["teleport_min"]) \
			and OlympusHits.summons_near(g, e.position, float(d["crowd_reach"]), _tmp) >= int(d["crowd_summons"])
	if teleport_cd <= 0.0 or crowded:
		teleport_cd = float(d["teleport_cooldown"])
		e.untargetable = true
		g.effects.ring(e.position, e.radius * 2.0, Palette.PANTHEON_MARBLE_LIGHT, float(d["blink_time"]))
		rules(e).play_sound("artemis_blink", e.position)
		g.stat_add("artemis_teleports", 1.0)
		set_phase(e, BLINK_OUT)
		return
	if hounds_cd <= 0.0:
		hounds_cd = float(d["hounds_cooldown"])
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		rules(e).play_sound("artemis_horn", e.position)
		g.stat_add("artemis_hound_calls", 1.0)
		set_phase(e, HOUNDS)
		return
	if volley_cd <= 0.0 and e.position.distance_to(g.player.position) <= float(d["attack_range"]) + 120.0:
		volley_cd = float(d["volley_cooldown"])
		var to := g.player.position - e.position
		_aim = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
		e.motion_lunge(-_aim, MotionData.POWER_CAST)
		g.stat_add("artemis_volleys", 1.0)
		set_phase(e, VOLLEY)


## The volley: arrows fanned around the aim (each a hostile arrow).
func _loose(e: Enemy) -> void:
	var g := e.game
	var n := int(d["volley_arrows"])  # Arrows this volley.
	var spread := float(d["volley_spread"])  # Fan width (rad).
	var dmg := scaled(e, "volley_damage")
	for i in n:
		var a := (float(i) / maxf(1.0, float(n - 1)) - 0.5) * spread  # This arrow's offset (rad).
		g.projectiles.fire_hostile(e.position + _aim * (e.radius + 4.0), _aim.rotated(a), dmg, float(d["volley_speed"]), e.undead_damage_mult,
				Projectile.Kind.ENEMY_ARROW, "artemis_volley")
	g.stat_add("artemis_arrows", float(n))
	rules(e).play_sound("artemis_volley", e.position)
	e.motion_lunge(_aim, MotionData.POWER_SHOT)


## The hounds leap out around her.
func _release_hounds(e: Enemy) -> void:
	var g := e.game
	var n := int(d["hounds_count"])
	var released := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + Vector2.from_angle(TAU * (float(i) + 0.5) / float(n)) * (e.radius + 22.0)
		g.enemies.spawn_at(OlympusEnemyData.HOUND, g.arena.free_point(at, 8.0), false)
		released += 1
	g.stat_add("artemis_hounds", float(released))
	g.effects.ring(e.position, 70.0, Palette.PANTHEON_MARBLE_LIGHT, 0.4)


## She appears at another grove (or on the spawn ring off the Olympus).
func _arrive(e: Enemy) -> void:
	var g := e.game
	var to: Vector2 = Vector2.INF
	if g.enemies.olympus != null:
		to = g.enemies.olympus.grove_point(e.position)
	if to == Vector2.INF:
		to = g.enemies.ring_point((e.position - g.player.position).angle() + PI * 0.6)
	e.position = g.arena.free_point(to, e.radius)
	e.velocity = Vector2.ZERO
	g.effects.ring(e.position, e.radius * 2.4, Palette.PANTHEON_MARBLE_LIGHT, float(d["blink_time"]))
	rules(e).play_sound("artemis_blink", e.position)


## Her plain arrows: hostile arrows tagged with her kind id (the stats name her).
func fire_ranged(e: Enemy, _t: Node2D, dir: Vector2, dmg: float) -> bool:
	e.game.projectiles.fire_hostile(e.position + dir * (e.radius + 2.0), dir, dmg, e.projectile_speed, e.undead_damage_mult,
			Projectile.Kind.ENEMY_ARROW, e.kind)
	return true


## While blinking she is drawn fading (her sprite with a falling / rising alpha).
func draws_body(_e: Enemy) -> bool:
	return phase == BLINK_OUT or phase == BLINK_IN


## Her body while she fades: the sprite at partial alpha with a moonlight halo.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var k := clampf(phase_time / maxf(0.01, float(d["blink_time"])), 0.0, 1.0)
	var a := 1.0 - k if phase == BLINK_OUT else k  # Opacity (0..1).
	ci.draw_circle(Vector2.ZERO, e.radius * 1.6, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.25 * (1.0 - a)))
	if not SpriteBank.draw(ci, "pantheon/artemis", Vector2.ZERO, false, Color(1, 1, 1, a)):
		ci.draw_circle(Vector2.ZERO, e.radius, Color(Palette.PANTHEON_MARBLE_LIGHT, a))


## The volley's fan of pale aim lines while she draws. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != VOLLEY:
		return
	var k := clampf(phase_time / maxf(0.01, float(d["volley_telegraph"])), 0.0, 1.0)  # 0 -> 1 as she looses.
	var n := int(d["volley_arrows"])
	var spread := float(d["volley_spread"])
	unmirror(e, ci)
	for i in n:
		var a := (float(i) / maxf(1.0, float(n - 1)) - 0.5) * spread
		var dir := _aim.rotated(a)
		ci.draw_line(dir * e.radius, dir * (e.radius + 60.0 + 160.0 * k), Color(Palette.PANTHEON_MARBLE_LIGHT, 0.25 + 0.4 * k), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
