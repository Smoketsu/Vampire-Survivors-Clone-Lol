## VoodooNavigatorKit — the kit of the Voodoo Navigator (CorsairEnemyData
## "voodoo_navigator"; Act X, the Black Tide, the Treasure Galleon's block; a
## woman in the figure-redesign style; GDD §15.0 "The Treasure Galleon (Act X
## phase 2)"; owner-approved proposal: "Marks a spot on the ring; the sea
## strikes it 1.5 s later | Kill her first; the mark fails if she dies").
## A "ranged" support walker (a weak hex bolt is her own blow). Every mark
## "every" s, while a standing necromancer is within mark "reach" px, she
## MARKS a point on his ring: mark "ring" px from him at an angle from the
## seeded gameplay RNG; the sea strikes it through THE strike scheduler
## (SeaStrikes.strike() with her as the strike's OWNER: the dark-water circle
## shows mark "telegraph" s, hits both armies, and fizzles if she dies first).
## Off Act X (no sea) she marks nothing and is a plain ranged walker.
## Determinism: the seeded gameplay RNG only (the mark's angle).
## Stats: navigator_marks (and SeaStrikes' sea_strikes_mark, sea_marks_failed).
class_name VoodooNavigatorKit
extends CorsairKit

## Seconds until her next mark.
var _mark_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_mark_cd = first_cd(e, float((d.get("mark", {}) as Dictionary).get("first", 3.0)))


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	_mark_cd -= delta
	if _mark_cd > 0.0:
		return false
	var m: Dictionary = d.get("mark", {})
	_mark_cd = float(m.get("every", 6.5))
	var r := rules(e)
	if not r.enabled or e.game.ultimates.player_untargetable():
		return false
	var pl := e.game.nearest_player(e.position)
	if pl == null or pl.dead or pl.position.distance_to(e.position) > float(m.get("reach", 360.0)):
		_mark_cd = 1.0  # Nobody in reach: look again soon.
		return false
	var at := pl.position + Vector2.from_angle(randf() * TAU) * float(m.get("ring", 70.0))
	at = e.game.deck.clamp_point(at, 6.0)
	r.sea.strike(at, {"telegraph": float(m.get("telegraph", 1.5)), "radius": float(m.get("radius", 40.0)),
		"dmg_summon": float(m.get("dmg_summon", 11.0)), "dmg_player": float(m.get("dmg_player", 9.0)),
		"dmg_enemy": float(m.get("dmg_enemy", 12.0))}, e)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	e.game.stat_add("navigator_marks", 1.0)
	return false
