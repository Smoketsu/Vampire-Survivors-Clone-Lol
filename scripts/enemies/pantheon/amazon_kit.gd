## AmazonKit — the kit of the Amazon (OlympusEnemyData "amazon"; Act IV, Mount
## Olympus; GDD §15.0 "Mount Olympus kinds"; owner-approved proposal: "Axe and
## crescent shield; leaps over the first row of the ring. Warriors, the
## Golem"; female, figure-redesign style). She runs at the necromancer with the
## shared melee AI; every leap_cooldown s, when he is leap_min..leap_max px away,
## she crouches over a LANDING CIRCLE land_gap px in front of him (inside the
## ring's first row; leap_windup s), flies leap_time s over everything (drawn
## on an arc; nothing blocks her in the air) and lands:
##   * a summon of block_mass >= catch_mass within catch_reach px of the landing
##     CATCHES her (owner-approved "Warriors, the Golem"): she lands on its
##     shield, is stunned catch_stun s (CombatResolver.stun_enemy()) and hurts
##     nothing;
##   * otherwise everything inside land_radius takes land_damage_* (her axe).
## BRONZE: Zeus's lightning chains to her. Stats: amazon_leaps,
## amazon_leaps_caught, amazon_land_hits (summons), amazon_land_player_hits.
## No RNG.
class_name AmazonKit
extends PantheonKit

## Phase: crouching over the landing circle.
const WINDUP: int = 1
## Phase: in the air.
const LEAP: int = 2

## Seconds until her next leap.
var leap_cd: float = 0.0
## Where the leap starts (world px).
var _from: Vector2 = Vector2.ZERO
## Where she lands (world px).
var _to: Vector2 = Vector2.ZERO
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	leap_cd = CovenantKit.first_cd(e, float(d["first_leap"]))


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	leap_cd -= delta
	var g := e.game
	match phase:
		IDLE:
			var p := g.player.position
			var dist := e.position.distance_to(p)
			if leap_cd > 0.0 or dist < float(d["leap_min"]) or dist > float(d["leap_max"]):
				return false
			leap_cd = float(d["leap_cooldown"])
			var back := (e.position - p).normalized() if dist > 1.0 else Vector2.RIGHT  # From him toward her.
			_from = e.position
			_to = g.arena.free_point(p + back * float(d["land_gap"]), e.radius)
			g.effects.telegraph_circle(_to, float(d["land_radius"]), float(d["leap_windup"]) + float(d["leap_time"]), e)
			e.motion_lunge(_to - e.position, MotionData.POWER_CAST)
			g.stat_add("amazon_leaps", 1.0)
			set_phase(e, WINDUP)
			return true
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["leap_windup"]):
				rules(e).play_sound("amazon_leap", e.position)
				set_phase(e, LEAP)
		LEAP:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d["leap_time"])), 0.0, 1.0)
			e.position = _from.lerp(_to, k)
			e.velocity = (_to - _from) / maxf(0.01, float(d["leap_time"]))
			e.queue_redraw()
			if k >= 1.0:
				_land(e)
				set_phase(e, IDLE)
	return true


## She lands: caught by a blocker, or her axe comes down on what is inside.
func _land(e: Enemy) -> void:
	var g := e.game
	e.velocity = Vector2.ZERO
	var catcher := OlympusHits.blocker_at(g, _to, float(d["catch_reach"]), float(d["catch_mass"]), _tmp)
	if catcher != null:
		g.combat.stun_enemy(e, float(d["catch_stun"]), 1.0, 1.0)
		g.effects.slash(_to, (_to - _from).normalized(), Palette.BONE, e.radius * 1.6)
		g.stat_add("amazon_leaps_caught", 1.0)
		return
	var mult := CovenantKit.hit_scale(e)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_to) <= float(d["land_radius"]) + pl.radius:
			g.stat_add("amazon_land_player_hits", 1.0)
	g.stat_add("amazon_land_hits", float(OlympusHits.circle(g, _to, float(d["land_radius"]), float(d["land_damage_player"]) * mult,
			float(d["land_damage_summon"]) * mult, "amazon_leap", e, 0.0, _tmp)))
	g.effects.impact(_to, float(d["land_radius"]), Palette.PANTHEON_BRONZE_LIGHT)
	g.shake(2.0)


## Autopilot hint: out of the landing circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == WINDUP or phase == LEAP:
		var away := p - _to
		if away.length() < float(d["land_radius"]) + 24.0:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## In the air she is drawn on her arc (her sprite lifted).
func draws_body(_e: Enemy) -> bool:
	return phase == LEAP


## Her body on the leap's arc (visual only).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var k := clampf(phase_time / maxf(0.01, float(d["leap_time"])), 0.0, 1.0)
	var lift := Vector2(0.0, -4.0 * k * (1.0 - k) * float(d["leap_height"]))
	if not SpriteBank.draw(ci, "pantheon/amazon", lift, e.flash > 0.0):
		PantheonGlyphs.draw_enemy(ci, e.kind, lift, e.radius, e.flash > 0.0)
