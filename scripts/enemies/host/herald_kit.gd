## HeraldKit — the kit of the HERALD (male; HostEnemyData "herald"; temporary
## Act XIII, the Celestial Host; GDD §15.0 "The Celestial Host foundation
## (phase 1)"; proposal: "A trumpet blast that calls a squad and pushes the
## ring back | Kill on arrival"). blast "first" s after he arrives, then every
## "every" s, he raises the trumpet for "windup" s (a widening silver ring at
## his feet), then BLASTS: every summon within "radius" px is pushed "push" px
## straight away from him (the arena push-out puts it back out of any
## obstacle), and, at most "calls" times in his life, a squad ("squad": kinds
## and counts) lands around him through EnemyDirector.spawn_at() (a Host squad,
## so the regular cap still counts it). Determinism: no RNG (fixed angles).
## Stats: herald_blasts, herald_pushed, herald_called.
class_name HeraldKit
extends HostKit

## Phase: the trumpet raised.
const WINDUP: int = 1
## px from the Herald the called squad lands (a ring around him).
const SQUAD_RING: float = 46.0  # Drawing / placement only, not balance.

## Seconds until the next blast.
var cd: float = 0.0
## Squads called so far in this life.
var calls: int = 0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float((d["blast"] as Dictionary)["first"]))
	calls = 0


func physics(e: Enemy, delta: float) -> bool:
	var bl: Dictionary = d["blast"]
	if phase == IDLE:
		cd -= delta
		if cd <= 0.0:
			set_phase(e, WINDUP)
		return false
	phase_time += delta
	hold(e)
	e.queue_redraw()
	if phase_time >= float(bl["windup"]):
		_blast(e, bl)
		cd = float(bl["every"])
		set_phase(e, IDLE)
	return true


## The blast: the ring pushed back, and a squad called while calls remain.
func _blast(e: Enemy, bl: Dictionary) -> void:
	var g := e.game
	g.stat_add("herald_blasts", 1.0)
	g.host_rules().play_sound("herald_blast", e.position, 0.3)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion (visual only).
	var r := float(bl["radius"])
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var away := u.position - e.position
		if away.length() > r:
			continue
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(bl["push"])
		g.stat_add("herald_pushed", 1.0)
	if calls >= int(bl["calls"]):
		return
	calls += 1
	var n := 0  # Bodies placed so far (their fixed angle on the ring).
	for grp: Dictionary in bl["squad"]:
		for i in int(grp["count"]):
			var at := e.position + Vector2.from_angle(TAU * float(n) / 9.0 + 0.3) * SQUAD_RING
			n += 1
			if g.enemies.spawn_at(String(grp["kind"]), g.arena.free_point(at, 10.0), false) != null:
				g.stat_add("herald_called", 1.0)


## A widening silver ring at his feet while the trumpet is raised.
func draw_under(e: Enemy) -> void:
	if phase != WINDUP:
		return
	var k := clampf(phase_time / maxf(0.01, float((d["blast"] as Dictionary)["windup"])), 0.0, 1.0)
	var r := e.radius * (1.4 + 2.2 * k)
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.4) + Vector2(0.0, e.radius * 0.6), Vector2(r * 2.0, r * 0.8)),
			false, Color(Palette.HOST_SILVER, 0.35 * (1.0 - k) + 0.1))
