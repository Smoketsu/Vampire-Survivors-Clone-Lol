## OdinRavenKit — the kit of a RAVEN OF ODIN (VigridEnemyData "odin_raven";
## the Hall of the Slain, temporarily Act XI; GDD §15.0 "Odin and Fenrir
## (Vigrid)"; owner-approved proposal: "his ravens mark the necromancer").
## BossOdin sends them in pairs (Huginn and Muninn). A raven flies straight at
## the nearest standing necromancer, over the ring and the obstacles (it owns
## its tick: no blows, no blocking), and when it reaches him (mark_reach px
## edge to edge) it MARKS him for mark_time s (BossOdin.mark_player(): the
## All-Father's next Gungnir is thrown at the necromancer himself, whom only
## Grave Step or a Bone Wall saves) and flies home (it leaves the field without
## a kill). A raven shot down on the way marks nobody. After `life` s it gives
## up and flies home. With no Odin on the field (--spawn=odin_raven) its touch
## marks nothing. A flier: the Night Wings test of NorseKit.taken_mult() (a
## grounded blow deals flight_melee_taken). No RNG. Stats: raven_marks,
## raven_home.
class_name OdinRavenKit
extends NorseKit

## Game time (s) it came onto the field.
var _born: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_born = e.game.elapsed


## It flies at the nearest standing necromancer and marks him on touch.
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	e.knockback = Vector2.ZERO
	if g.elapsed - _born >= float(d.get("life", 14.0)):
		g.stat_add("raven_home", 1.0)
		g.enemies.despawn(e)
		return true
	var pl: Necromancer = null
	var best := INF
	for p in g.all_players:
		if not p.dead and p.position.distance_squared_to(e.position) < best:
			best = p.position.distance_squared_to(e.position)
			pl = p
	if pl == null:
		hold(e)
		return true
	var to := pl.position - e.position
	var dist := to.length()
	if dist - e.radius - pl.radius <= float(d.get("mark_reach", 14.0)):
		if g.enemies.boss is BossOdin and g.enemies.boss.active:
			(g.enemies.boss as BossOdin).mark_player(pl, float(d.get("mark_time", 9.0)))
			g.stat_add("raven_marks", 1.0)
		g.effects.ring(pl.position, pl.radius * 2.5, Palette.NORSE_INK, 0.35)
		g.enemies.despawn(e)
		return true
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	e.velocity = to / maxf(dist, 0.01) * spd
	e.position += e.velocity * delta
	return true
