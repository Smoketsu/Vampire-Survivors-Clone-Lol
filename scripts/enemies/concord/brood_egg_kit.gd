## BroodEggKit — the kit of the INFESTATION EGG (CrashSiteEnemyData
## "brood_egg"; Act IX, the Crash Site; GDD §15.0 "The Crash Site (Act IX
## phase 2)"; owner answer Nov 3, 2026: "when a Concord enemy dies on the Crash
## Site, an egg sits where it fell for 6 s; any spell or summon hit on that spot
## clears it; otherwise a broodling hatches"). A structure (it never moves or
## attacks; Enemy.is_objective, so it is never recycled to the spawn ring):
##   * its HP is set to CrashSiteEnemyData.EGG_HP at activation, whatever the
##     HP scalings, so every hit that reaches it clears it (CombatResolver asks
##     CrashSiteDirector.clear_egg() before the kill path: no kill, no XP);
##   * after its row's hatch_time s (game time; a Stasis or a freeze holds it,
##     as every kit's physics) it HATCHES: a broodling (row "hatch_kind")
##     spawns where it lay, marked BroodlingKit.hatched (it lays no egg of its
##     own: no chains), the director counts it (on_egg_hatched()) and the egg
##     leaves without a kill (EnemyDirector.despawn()).
## Self-contained, so an egg forced onto any stage (--spawn=brood_egg, a
## Matriarch elsewhere) still hatches. Drawn as a pulsing egg (a slow pulse on
## game time; `concord/brood_egg`), then its hatch strip
## (`concord/brood_egg_hatch`, HATCH_FRAMES frames) over the last HATCH_SHOW
## s; ConcordGlyphs-style discs without the art. Determinism: game time only.
class_name BroodEggKit
extends ConcordKit

## Sprite key of the egg.
const SPRITE: String = "concord/brood_egg"
## Sprite key of the egg's hatch strip (frames side by side, square).
const HATCH_SPRITE: String = "concord/brood_egg_hatch"
## Frames in the hatch strip.
const HATCH_FRAMES: int = 4
## Seconds before hatching the hatch strip plays (and the pulse quickens).
const HATCH_SHOW: float = 1.2  # TUNING (not in GDD) drawing only
## Pulses per second of the egg's glow (slow: no flashing).
const PULSE_HZ: float = 0.8  # TUNING (not in GDD) drawing only

## Game time (s) the egg was laid.
var laid_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.max_hp = CrashSiteEnemyData.EGG_HP
	e.hp = CrashSiteEnemyData.EGG_HP
	e.is_objective = true  # It stands until cleared or hatched (never recycled).
	laid_at = e.game.elapsed


## Every tick: it holds still, and hatches when its time is up. Always true.
func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	if e.game.elapsed - laid_at >= float(d.get("hatch_time", 6.0)):
		_hatch(e)
	elif e.game.elapsed - laid_at >= float(d.get("hatch_time", 6.0)) - HATCH_SHOW:
		e.queue_redraw()  # The hatch strip plays.
	return true


## A broodling hatches where the egg lay; the egg leaves without a kill.
func _hatch(e: Enemy) -> void:
	var g := e.game
	var at := e.position
	var cs := g.enemies.crash_site  # The Crash Site's director (null elsewhere).
	if cs != null:
		cs.on_egg_hatched(e)
	else:
		g.stat_add("crash_site_eggs_hatched", 1.0)
	g.enemies.despawn(e)
	var b := g.enemies.spawn_at(String(d.get("hatch_kind", ConcordEnemyData.BROODLING)), at, false)
	if b != null and b.kit is BroodlingKit:
		(b.kit as BroodlingKit).hatched = true
	g.effects.pop(at, Palette.CONCORD_PLASMA_DARK, 10.0)
	rules(e).play_sound("egg_hatch", at, 0.4)


func is_busy() -> bool:
	return true  # It never moves (the stuck check skips it).


func draws_body(_e: Enemy) -> bool:
	return true


## The egg: its art pulsing slowly (a brighter tint), or the hatch strip over
## its last HATCH_SHOW s; discs without the art.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed - laid_at
	var left := float(d.get("hatch_time", 6.0)) - t  # s until it hatches.
	var hz := PULSE_HZ * (2.0 if left < HATCH_SHOW else 1.0)
	var pulse := 0.5 + 0.5 * sin(t * TAU * hz)
	var tint := Color(1.0 + 0.25 * pulse, 1.0 + 0.35 * pulse, 1.0 + 0.15 * pulse)
	if left < HATCH_SHOW:
		var tex := SpriteBank.texture(HATCH_SPRITE)
		if tex != null:
			var f := clampi(int((1.0 - left / HATCH_SHOW) * float(HATCH_FRAMES)), 0, HATCH_FRAMES - 1)
			SpriteBank.draw_flat_frame(ci, HATCH_SPRITE, HATCH_FRAMES, f, Vector2(0.0, -2.0), 0.0, tint)
			return
	if SpriteBank.draw(ci, SPRITE, Vector2.ZERO, e.flash > 0.0, tint):
		return
	var r := e.radius
	SpriteBank.draw_disc(ci, Vector2(0.0, 1.0), r * 1.3, Color(Palette.CONCORD_INK, 0.6))  # The resin smear.
	SpriteBank.draw_disc(ci, Vector2(0.0, -1.0), r, Palette.CONCORD_INK)
	SpriteBank.draw_disc(ci, Vector2(0.0, -1.0), r - 1.0, Palette.CONCORD_CHITIN)
	SpriteBank.draw_disc(ci, Vector2(-r * 0.25, -r * 0.4), r * 0.45, Color(Palette.CONCORD_PLASMA_DARK, 0.5 + 0.4 * pulse))
