## CanopicJarKit — the kit of the CANOPIC JAR (a structure; DynastyEnemyData
## "canopic_jar"; temporary Act XII, the Necropolis Dynasty; GDD §15.0
## "Rebirth"; owner-approved proposal: "Canopic Jars (structures) hold the
## Names of every body within 300 px: break the jar and its bodies return no
## more"). It never moves or attacks; it stands until broken (Enemy
## .is_objective: never recycled to the spawn ring). Its row's "holds_names"
## puts it on Rebirth's jar list (DynastyKit -> DynastyRules.note_spawn()):
## every cartouche laid within REBIRTH jar_radius of it is SEALED by it, and
## when it falls those cartouches crumble (Rebirth.on_jar_gone()). Drawn: a
## faint lapis pool under it while it seals a Name (visual only); its body is
## its art (`dynasty/canopic_jar` or `structures/canopic_jar`), else
## DynastyGlyphs.
class_name CanopicJarKit
extends DynastyKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken.


func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	return true


func is_busy() -> bool:
	return true  # It never moves (the stuck check skips it).


## A faint lapis pool under the jar while it seals at least one Name.
func draw_under(e: Enemy) -> void:
	var g := e.game
	if g.dynasty == null:
		return
	for c in g.dynasty.rebirth.cartouches:
		if c.active and (c.kit as CartoucheKit).sealed_by(e):
			var r := e.radius * 2.2
			e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, e.radius * 0.5 - r * 0.4), Vector2(r * 2.0, r * 0.8)), false, Color(Palette.DYN_LAPIS, 0.4))
			return
