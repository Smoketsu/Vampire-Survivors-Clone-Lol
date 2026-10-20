## RocketKit — a Swarm Rocket of the Trojan Horse (WastesEnemyData
## "trojan_rocket"; Act III, the Scrap Wastes, GDD §15.0 "The Scrap Wastes (Act
## III phase 2)"; owner-approved proposal: "missile pods that fire volleys of
## slow homing rockets your summons can intercept"). A rocket is a tiny pooled
## Enemy (a MACHINE, no XP, it flies over obstacles), so the army can shoot it
## down like any foe (it ranks high on their target lists). The kit owns its
## flight (physics() returns true every tick, the shared AI never moves it):
##   * launched along a heading (TrojanKit.launch_rocket(): fanned out of the
##     pods), it curves toward the necromancer at rocket_turn rad/s at its row's
##     move speed (slows apply) — homing, but slowly, so it can be outrun;
##   * after rocket_arm s, the FIRST body it touches (a summon in its path
##     intercepts it, like Line of Fire, or the necromancer) makes it burst;
##     it also bursts on its own after rocket_life s;
##   * the burst hits everything within rocket_splash px: the necromancer for
##     the row's damage, each summon for damage x undead_damage_mult (time-
##     scaled), then the rocket leaves the field without a kill
##     (EnemyDirector.despawn()).
## It draws its own body (draws_body()): the rocket sprite (projectiles/
## trojan_rocket when its art exists) turned along its heading, with a short
## flame. Stats: wastes_rockets_launched (TrojanKit), wastes_rockets_burst,
## wastes_rockets_intercepted (a summon took it), wastes_rockets_hit_player,
## wastes_rockets_shot_down. No RNG.
class_name RocketKit
extends CovenantKit

## Unit heading of the rocket.
var heading: Vector2 = Vector2.RIGHT
## Seconds since launch.
var age: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	age = 0.0
	var to := e.game.player.position - e.position  # Toward the necromancer.
	heading = to.normalized() if to.length_squared() > 0.01 else Vector2.RIGHT


## Sets the launch heading (TrojanKit, right after the spawn).
func launch(e: Enemy, dir: Vector2) -> void:
	heading = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	e.queue_redraw()


## Flies, homes, and bursts on the first body it touches (see the header).
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO
	age += delta
	if age >= float(d["rocket_life"]):
		_burst(e, e.position, "")
		return true
	var to := g.player.position - e.position  # Toward the necromancer.
	if to.length_squared() > 1.0:
		var cur := heading.angle()
		var turn := float(d["rocket_turn"]) * delta  # Most it turns this tick (rad).
		heading = Vector2.from_angle(cur + clampf(wrapf(to.angle() - cur, -PI, PI), -turn, turn))
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)  # Speed this tick (px/s).
	var a := e.position  # Where it was.
	var b := a + heading * spd * delta  # Where it is now.
	e.position = b
	e.velocity = heading * spd
	e.queue_redraw()
	if age < float(d["rocket_arm"]):
		return true
	# The first body on the path a -> b (the Line of Fire test of EmpireShots).
	var best_t := INF  # Path fraction of the first touch.
	var hit_summon := false  # A summon was touched first.
	g.ally_grid.query((a + b) * 0.5, (b - a).length() * 0.5 + e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var t := EmpireShots.segment_t(a, b, u.position, u.radius + e.radius)
		if t < best_t:
			best_t = t
			hit_summon = true
	var pl := g.player
	if not pl.dead:
		var tp := EmpireShots.segment_t(a, b, pl.position, pl.radius + e.radius)
		if tp < best_t:
			best_t = tp
			hit_summon = false
	if best_t != INF:
		_burst(e, a.lerp(b, best_t), "intercepted" if hit_summon else "hit_player")
	return true


## The burst at `at`: everything within rocket_splash takes the rocket's
## damage; the rocket leaves without a kill. `why` = the stat suffix.
func _burst(e: Enemy, at: Vector2, why: String) -> void:
	var g := e.game
	var r := float(d["rocket_splash"])  # Burst radius (px).
	var dmg := e.damage * CovenantKit.hit_scale(e)  # Time-scaled burst damage.
	g.effects.impact(at, r, Palette.EMPIRE_SIGNAL_AMBER, "wastes_blast")
	Sfx.play("rocket_burst", at)
	for pl in g.all_players:  # (Co-op: every necromancer inside.)
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			g.combat.damage_player(dmg, e.kind, pl)
	g.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(at) <= r + u.radius:
			g.combat.damage_unit(u, dmg * e.undead_damage_mult, e.kind)
	g.stat_add("wastes_rockets_burst", 1.0)
	if why != "":
		g.stat_add("wastes_rockets_" + why, 1.0)
	g.enemies.despawn(e)


## Shot down by the army (a kill, no XP).
func on_killed(e: Enemy) -> void:
	e.game.stat_add("wastes_rockets_shot_down", 1.0)
	e.game.effects.pop(e.position, Palette.EMPIRE_SIGNAL_AMBER, 8.0)


## The rocket draws itself along its heading (see the header).
func draws_body(_e: Enemy) -> bool:
	return true


## The rocket: its sprite turned along the heading (code-drawn without art), a
## flickering amber flame behind. Drawn in world axes. Visual only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	CovenantKit.unmirror(e, ci)
	var a := heading.angle()  # Heading (rad).
	var back := -heading * (e.radius + 2.0)  # The exhaust (px).
	var f := 0.7 + 0.3 * float(int(age * 20.0) % 2)  # Flame flicker.
	ci.draw_circle(back, 3.5 * f, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.6))
	ci.draw_circle(back, 1.8 * f, Palette.EMPIRE_SIGNAL_GLOW)
	if not SpriteBank.draw_flat(ci, "projectiles/trojan_rocket", Vector2.ZERO, a):
		WastesGlyphs.draw_rocket(ci, Vector2.ZERO, heading, e.radius, e.flash > 0.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
