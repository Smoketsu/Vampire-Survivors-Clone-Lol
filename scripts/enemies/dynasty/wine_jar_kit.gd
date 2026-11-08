## WineJarKit — the kit of the RED-WINE JAR (a structure; LionessTempleEnemyData
## "wine_jar"; temporary Act XII, the Temple of the Lioness; GDD §15.0
## "Sekhmet, the Lioness of Retribution (Dynasty phase 2)"; proposal: "the
## Feast: three red-wine jars (structures) fill the arena; break all three
## while she drinks from each and she stumbles for 4 s"). Set down three at a
## time by BossSekhmet in the Feast. It never moves or attacks; it stands
## until broken (Enemy.is_objective: never recycled to the spawn ring) or
## until Sekhmet drains it (BossSekhmet removes it without a kill). Broken by
## the army, it tells her (BossSekhmet.on_jar_broken()). Drawn: the Canopic
## Jar's art tinted wine red over a dark red pool, and a red glow while she
## drinks from it (visual only; no new art). Determinism: no RNG.
class_name WineJarKit
extends DynastyKit

## Tint of the jar's art (the Canopic Jar's sprite, wine red).
const TINT: Color = Color(1.0, 0.55, 0.5)  # TUNING (not in GDD) visual only
## Colour of the wine pool under it.
const POOL: Color = Color(0.45, 0.04, 0.08, 0.55)  # TUNING (not in GDD) visual only

## True while Sekhmet drinks from it (drawn glow).
var drunk_from: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken or drained.
	drunk_from = false


func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	return true


func is_busy() -> bool:
	return true  # It never moves (the stuck check skips it).


## Broken by the army: Sekhmet hears it.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	g.stat_add("wine_jars_broken", 1.0)
	g.effects.pop(e.position, Palette.DYN_CARNELIAN, e.radius * 3.0)
	if g.dynasty != null:
		g.dynasty.play_sound("jar_break", e.position, 0.1)
	var b := g.enemies.boss
	if b != null and b.active and b is BossSekhmet:
		(b as BossSekhmet).on_jar_broken(e)


## The wine pool under it (redder while she drinks).
func draw_under(e: Enemy) -> void:
	var r := e.radius * (2.4 if drunk_from else 1.8)
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, e.radius * 0.5 - r * 0.4), Vector2(r * 2.0, r * 0.8)), false,
			Color(POOL, 0.8 if drunk_from else 0.55))


func draws_body(_e: Enemy) -> bool:
	return true


## The Canopic Jar's art tinted wine red (a code jar without it).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if SpriteBank.draw(ci, LionessTempleEnemyData.WINE_JAR_SPRITE, Vector2.ZERO, e.flash > 0.0, TINT):
		return
	LionessTempleGlyphs.draw_wine_jar(ci, e.radius, e.flash > 0.0)
