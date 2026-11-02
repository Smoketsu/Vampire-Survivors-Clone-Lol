## IsoldeSisterKit — the kit of one of Isolde's three sisters
## (WitchwoodEnemyData "isolde_sister"; Act VII, the Witchwood; GDD §15.0
## "Isolde Vane, the Witch of the Red Moon (Act VII)"; owner-approved proposal:
## "phase 2, she splits into three sisters, and all three must fall within 10 s
## of each other or the fallen ones rise again"). Female, Isolde's own image
## in one of her three colours (IsoldeData.SISTER_TINTS by `index`). BossIsolde
## spawns the three and owns the rule (the window, the rising, the bar); here:
##   * her hex bolts (the row's "ranged" behaviour, the shared shot);
##   * every circle_every s a hex circle under the summon nearest her within
##     circle_reach px (WitchHexes.cast_circle(), the witches' one circle path:
##     it heals the Court inside and drains the summons; tag "sister");
##   * her fall is reported to Isolde (BossIsolde.on_sister_down()).
## No RNG (her first circle is staggered by her index). Stats: sister_circles.
class_name IsoldeSisterKit
extends CourtKit

## Which of the three she is (0..2; set by BossIsolde right after the spawn).
var index: int = 0
## Seconds until her next circle.
var _circle_cd: float = 0.0
## Grid query buffer.
var _q: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	index = 0
	_circle_cd = float(def.get("circle_every", 9.0)) * 0.4


## Isolde names her (staggers the first circle so the three do not cast as one).
func set_index(i: int) -> void:
	index = i
	_circle_cd += float(i) * 1.5


func physics(e: Enemy, delta: float) -> bool:
	_circle_cd -= delta
	if _circle_cd > 0.0:
		return false
	_circle_cd = float(d.get("circle_every", 9.0))
	var g := e.game
	var best: SummonedUnit = null
	var best_d := INF
	g.ally_grid.query(e.position, float(d.get("circle_reach", 220.0)), _q)
	for u: SummonedUnit in _q:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
			continue
		var dd := u.position.distance_squared_to(e.position)
		if dd < best_d:
			best = u
			best_d = dd
	if best == null:
		_circle_cd = 1.0
		return false
	rules(e).witch_hexes().cast_circle(best.position, float(d.get("circle_radius", 62.0)), float(d.get("circle_windup", 1.2)),
			float(d.get("circle_time", 4.0)), float(d.get("circle_heal", 0.04)), float(d.get("circle_drain", 5.0)), e, IsoldeData.SISTER_TAG)
	g.stat_add("sister_circles", 1.0)
	return false


## Her fall: Isolde counts it (the window, the rising, The Coven Breaks).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var b := e.game.enemies.boss
	if b is BossIsolde and b.active:
		(b as BossIsolde).on_sister_down(e, index)


func draws_body(_e: Enemy) -> bool:
	return true


## Isolde's image in her colour (else WitchwoodGlyphs' Isolde, tinted).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var tint: Color = IsoldeData.SISTER_TINTS[index % IsoldeData.SISTER_TINTS.size()]
	if not SpriteBank.draw(ci, WitchwoodGlyphs.SISTER_SPRITE, Vector2.ZERO, e.flash > 0.0, tint):
		WitchwoodGlyphs.draw_isolde(ci, Vector2.ZERO, e.radius, e.flash > 0.0, tint)
