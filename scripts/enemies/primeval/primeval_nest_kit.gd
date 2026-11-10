## PrimevalNestKit — the kit of IRONJAW'S NEST (FernBasinEnemyData
## "primeval_nest"; temporary Act XIV, the Fern Basin; GDD §15.0 "The Fern
## Basin (Act XIV phase 2)"; owner-approved proposal: "the nest spawns
## Scuttlers until it is destroyed"). A structure (it never moves or attacks):
## every brood_every s (the first after brood_first s) it hatches `brood`
## Scuttlers (brood_kind) round it through EnemyDirector.spawn_at(), while
## fewer than brood_cap of its own are alive, the stage is under its alive cap
## (EnemyDirector.soft_cap(), as the trickle) and it has hatched fewer than
## brood_total in all (balance pass 1: unbroken, it hatched 146). Destroyed, it drops a small XP
## burst (reward_xp in reward_crystals). FernBasinDirector lays it beside
## Ironjaw and keeps it on the field (Enemy.is_objective: never recycled).
## Determinism: no RNG (the hatchlings' angles turn with its count). Stats:
## nest_hatched, nest_kills.
class_name PrimevalNestKit
extends PrimevalKit

## Seconds until the next hatching.
var cd: float = 0.0
## Hatchlings it brought (their angles turn with it).
var hatched: int = 0
## Its live hatchlings: [Enemy, generation] each.
var brood: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = float(d.get("brood_first", 2.0))
	hatched = 0
	brood.clear()


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	brood.clear()


## Every tick: the hatching clock (a structure never moves: the Enemy's own
## structure step runs after this).
func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if cd > 0.0:
		return false
	cd = float(d.get("brood_every", 4.5))
	brood = brood.filter(func(b: Array) -> bool: return (b[0] as Enemy).active and (b[0] as Enemy).generation == int(b[1]))
	var room := int(d.get("brood_cap", 14)) - brood.size()
	room = mini(room, e.game.enemies.soft_cap() - e.game.enemies.regular_alive())  # The stage's alive cap, as the trickle.
	room = mini(room, int(d.get("brood_total", 30)) - hatched)  # Its lifetime clutch.
	for i in mini(int(d.get("brood", 3)), room):
		var at := e.position + Vector2.from_angle(float(hatched) * 2.4) * (e.radius + 10.0)
		var s := e.game.enemies.spawn_at(String(d.get("brood_kind", PrimevalEnemyData.SCUTTLER)), e.game.arena.free_point(at, 8.0), false)
		hatched += 1
		if s != null:
			brood.append([s, s.generation])
			e.game.stat_add("nest_hatched", 1.0)
	return false


## Its XP burst when destroyed.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 5)))
	var each := maxi(1, floori(float(d.get("reward_xp", 60)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * 20.0, each)
	g.effects.impact(e.position, e.radius * 2.0, Palette.PRIMEVAL_OCHRE)
	g.stat_add("nest_kills", 1.0)


## A mound of fern and eggshells without its art (disc textures and rects).
func draws_body(_e: Enemy) -> bool:
	return not SpriteBank.has(PrimevalEnemyData.SPRITE_DIR + FernBasinEnemyData.NEST)


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var r := e.radius
	var fl := e.flash > 0.0
	SpriteBank.draw_disc(ci, Vector2(0.0, 2.0), r, Glyphs._c(Palette.PRIMEVAL_INK, fl))
	SpriteBank.draw_disc(ci, Vector2.ZERO, r - 1.5, Glyphs._c(Palette.PRIMEVAL_FERN_DARK, fl))
	for i in 5:
		var a := float(i) * 1.26
		SpriteBank.draw_disc(ci, Vector2.from_angle(a) * r * 0.45, r * 0.22, Glyphs._c(Palette.PRIMEVAL_BONE, fl))  # An egg.
	for i in 6:
		ci.draw_rect(Rect2(Vector2.from_angle(float(i) * 1.05) * r * 0.8, Vector2(5.0, 1.5)), Glyphs._c(Palette.PRIMEVAL_FERN, fl))  # A frond.
