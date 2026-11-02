## BloodBearerKit — the kit of a Blood Bearer (CastleSanguisEnemyData
## "blood_bearer"; Act VII, Castle Sanguis; GDD §15.0 "Queen Carmilla and the
## Elder (Act VII phase 2)"; owner-approved proposal: "Interrupt her (stuns,
## Soul Chains, killing the thralls that bring her blood)"). A thrall with a
## chalice of blood (it wears the Blood Thrall's art, row "wears"; the chalice
## is drawn over it). It owns every tick (it never fights):
##   * while the stage boss is Queen Carmilla kneeling at the Elder's coffin
##     (BossCarmilla.is_kneeling()), it walks at bearer_speed px/s straight to
##     HER and, at pour_reach px of her edge, pours its chalice into the Elder
##     (BossCarmilla.pour(): the existing enemy heal path) and is gone
##     (EnemyDirector.despawn(): no kill, no XP);
##   * otherwise it shambles at the necromancer at its row speed and stops
##     short of him (it never strikes).
## It is always "busy" for the autotest's stuck check (it walks its own path).
## No RNG. Stats: bearers_walked (game s spent walking to the Queen).
class_name BloodBearerKit
extends CourtKit

## Px from the necromancer at which a bearer with no Queen to serve stops.
const IDLE_GAP: float = 40.0  # TUNING (not in GDD)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	var queen := g.enemies.boss as BossCarmilla  # Null unless Carmilla fights.
	if queen != null and queen.active and queen.is_kneeling():
		var to := queen.position - e.position
		var edge := to.length() - e.radius - queen.radius
		if edge <= float(d["pour_reach"]):
			if queen.pour(e):
				g.enemies.despawn(e)
			return true
		e.velocity = Vector2.ZERO
		e.position += to.normalized() * minf(edge, float(d["bearer_speed"]) * delta)
		g.stat_add("bearers_walked", delta)
		return true
	var tp := g.player.position - e.position
	e.velocity = Vector2.ZERO
	if tp.length() > IDLE_GAP:
		e.position += tp.normalized() * e.move_speed * delta
	return true


func is_busy() -> bool:
	return true


## The gold chalice in its hands, brimming red. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var o := Vector2(e.radius * 0.6, -e.radius * 0.2)
	ci.draw_rect(Rect2(o + Vector2(-3, -4), Vector2(6, 4)), Palette.GOLD)
	ci.draw_rect(Rect2(o + Vector2(-2, -4), Vector2(4, 1)), Palette.COURT_BLOOD_LIGHT)
	ci.draw_rect(Rect2(o + Vector2(-1, 0), Vector2(2, 3)), Palette.GOLD.darkened(0.3))
	super.draw_over(e, ci)
