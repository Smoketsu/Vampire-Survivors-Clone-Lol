## TitanKit — the kit of the Bronze Titan (PantheonEnemyData "bronze_titan";
## Act IV, GDD §15.0 "Act IV foundation (phase 1)"): the Twilight of the Gods'
## Reckoning kind, a slow, huge bronze colossus that steps out of the ground
## (row "rises": on its first tick a crack in the ground and the rise of its
## body; visual and sound only). BRONZE: Zeus's lightning chains to it.
## Everything else is the shared melee AI. No RNG.
class_name TitanKit
extends PantheonKit

## True once the rise played (its first tick after activation).
var _risen: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_risen = false


## The rise on the first tick (the body's motion is reset after the kit, so it
## cannot start in reset()), then the shared facing.
func physics(e: Enemy, delta: float) -> bool:
	if not _risen:
		_risen = true
		if bool(d.get("rises", false)):
			var g := e.game
			g.effects.impact(e.position, e.radius * 2.2, Palette.PANTHEON_BRONZE)
			rules(e).play_sound("titan_rise", e.position)
			g.stat_add("pantheon_titans_risen", 1.0)
			if e.motion != null:
				e.motion.begin_rise(g.elapsed)  # Climbs out of the ground (visual only).
	return super.physics(e, delta)
