## AegisKit — the Aegis Bot's kit (WastesEnemyData "aegis_bot"; Act III, the
## Scrap Wastes, GDD §15.0 "The Scrap Wastes (Act III phase 2)"; owner-approved
## proposal: "Carries a frontal energy shield that stops your projectiles; walks
## in front of the troopers. Hit it from the side or above (Rogues, Gargoyles),
## area spells, stomps"). A melee MACHINE: it walks at the necromancer with the
## shared melee AI (enemies always advance) and bashes what it reaches. Its
## shield faces the necromancer, turning at shield_turn rad/s:
##   * every friendly PROJECTILE (ProjectileManager's arrows, bolts and frost
##     bolts, the volley shots, Bone Spears) that arrives within
##     shield_half_angle of its facing is stopped by the shield
##     (Enemy.shield_blocks() -> blocks_shot(), the one projectile-shield
##     check), which loses that shot's damage from its shield HP;
##   * at 0 the shield breaks for shield_recharge s (a crackle, then it comes
##     back full);
##   * melee strikes, area spells, beams, Corpse Explosions, stomps and dives
##     never ask the shield: they hit as usual. A shot from the side or the back
##     passes the shield's edge.
## Shield HP scales with the bot's own max HP (the time scaling and elites).
## A MACHINE: it leaves no corpse. Stats: aegis_shots_blocked,
## aegis_dmg_blocked, aegis_shield_breaks. No RNG.
class_name AegisKit
extends EmpireKit

## Unit direction the shield faces (toward the necromancer, turning).
var facing: Vector2 = Vector2.RIGHT
## Shield HP left (0 = broken).
var shield: float = 0.0
## Full shield HP of this bot (row shield_hp x its HP scaling).
var shield_max: float = 0.0
## Game time (s) the broken shield comes back (0 = not broken).
var down_until: float = 0.0
## Game time (s) of the last blocked shot (the shield's flash, visual only).
var _last_block: float = -10.0
## Shield angle (rad) when the bot was last redrawn (redraw only on a turn).
var _drawn_angle: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	shield_max = float(d["shield_hp"]) * e.max_hp / maxf(1.0, float(d["max_hp"]))
	shield = shield_max
	down_until = 0.0
	_last_block = -10.0
	var to := e.game.player.position - e.position  # Toward the necromancer.
	facing = to.normalized() if to.length_squared() > 0.01 else Vector2.LEFT
	_drawn_angle = facing.angle()


## Turns the shield toward the necromancer; brings a broken shield back.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	if down_until > 0.0 and g.elapsed >= down_until:
		down_until = 0.0
		shield = shield_max
		g.effects.ring(e.position, e.radius * 1.6, Palette.EMPIRE_SIGNAL_AMBER, 0.25)
		e.queue_redraw()
	var to := g.player.position - e.position  # Toward the necromancer.
	if to.length_squared() > 1.0:
		var cur := facing.angle()
		var diff := wrapf(to.angle() - cur, -PI, PI)
		var rate := float(d["shield_turn"]) * delta  # Most it turns this tick (rad).
		facing = Vector2.from_angle(cur + clampf(diff, -rate, rate))
		if absf(wrapf(facing.angle() - _drawn_angle, -PI, PI)) > 0.08:
			_drawn_angle = facing.angle()
			e.queue_redraw()
	return super.physics(e, delta)


## The projectile-shield check (Enemy.shield_blocks()): true when a shot moving
## with `vel` meets the shield's face (its reverse heading within
## shield_half_angle of the facing); the shield loses `dmg` and may break.
func blocks_shot(e: Enemy, vel: Vector2, dmg: float) -> bool:
	if shield <= 0.0 or vel.length_squared() < 0.01:
		return false
	var incoming := -vel.normalized()  # From the bot toward where the shot came from.
	if incoming.dot(facing) < cos(float(d["shield_half_angle"])):
		return false  # From the side or behind: past the shield's edge.
	var g := e.game
	shield -= dmg
	_last_block = g.elapsed
	g.stat_add("aegis_shots_blocked", 1.0)
	g.stat_add("aegis_dmg_blocked", minf(dmg, dmg + shield))
	g.effects.pop(e.position + facing * e.radius * 1.4, Palette.EMPIRE_SIGNAL_GLOW, 5.0)
	if shield <= 0.0:
		shield = 0.0
		down_until = g.elapsed + float(d["shield_recharge"])
		g.stat_add("aegis_shield_breaks", 1.0)
		g.effects.impact(e.position + facing * e.radius, e.radius * 1.4, Palette.EMPIRE_SIGNAL_AMBER)
		Sfx.play("shield_break", e.position)
	e.queue_redraw()
	return true


## The shield: a glowing amber arc in front of the bot, brighter for a moment
## after a block, a faint flicker while broken. Drawn in world axes. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	var half := float(d["shield_half_angle"])  # Arc half-width (rad).
	var a := facing.angle()  # Arc centre (rad).
	var r := e.radius * 1.5  # Arc radius (px).
	if shield > 0.0:
		var hot := clampf(1.0 - (e.game.elapsed - _last_block) / 0.25, 0.0, 1.0)  # Block flash 1 -> 0.
		var k := 0.45 + 0.55 * shield / maxf(shield_max, 1.0)  # Brighter while strong.
		ci.draw_arc(Vector2.ZERO, r, a - half, a + half, 16, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.22 * k + 0.3 * hot), 6.0)
		ci.draw_arc(Vector2.ZERO, r, a - half, a + half, 16, Color(Palette.EMPIRE_SIGNAL_GLOW.lerp(Palette.EMPIRE_SIGNAL_AMBER, 1.0 - hot), 0.75 * k + 0.25 * hot), 2.0)
	else:
		ci.draw_arc(Vector2.ZERO, r, a - half, a + half, 12, Color(Palette.EMPIRE_SIGNAL_RED, 0.25), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
