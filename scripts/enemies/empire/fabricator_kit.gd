## FabricatorKit — a Fabricator's build cycle (AssemblyEnemyData "fabricator", a
## MACHINE structure; Act III, the Assembly Halls; GDD §15.0 "The Assembly Halls
## (Act III phase 2)"; owner-approved proposal: "factory structures that build a
## new enemy every few seconds until you smash them"). It never moves (a
## structure: the one exception to "always advance"). While the necromancer is
## within build_radius px, every build_interval s it builds one enemy out of its
## bay (toward him): on the Assembly Halls the AssemblyDirector chooses the kind
## (its timeline event's "builds" in turn, AssemblyDirector.fabricate(), which
## also skips a cycle near the trickle's soft cap); a fabricator spawned on any
## other stage (--spawn=fabricator@T) builds its own row's build_kinds in turn,
## with the same soft-cap rule. Stasis holds it like every enemy (a global
## time stop); a freeze or stun does not (structures are immune). Its amber
## build bar fills toward the next build (drawn on its overlay). No RNG.
class_name FabricatorKit
extends EmpireKit

## Seconds until the next build.
var build_cd: float = 0.0
## Index of the next kind of its own row's build_kinds (off the Assembly Halls).
var _next: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	build_cd = first_cd(e, float(d["build_first"]))
	_next = 0


## The build clock (only while the necromancer is near). Never owns the tick:
## the structure step keeps it in place.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	if e.position.distance_to(g.player.position) > float(d["build_radius"]) or g.countdown_finished():
		return false
	build_cd -= delta
	if build_cd <= 0.0:
		build_cd = float(d["build_interval"])
		_build(e)
	e.queue_redraw()
	return false


## Builds one enemy: the director's kind on the Assembly Halls, else its own.
func _build(e: Enemy) -> void:
	var g := e.game
	var ad := g.enemies.assembly  # The Assembly Halls' director (null on other stages).
	if ad != null and ad.fabricate(e) != "":
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the bay heaves (visual only).
		return
	var kinds: Array = d["build_kinds"]
	if kinds.is_empty() or g.enemies.regular_alive() >= g.enemies.soft_cap():
		return
	AssemblyDirector.build_enemy(g, e, String(kinds[_next % kinds.size()]))
	_next += 1
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)


## The amber build bar over its bay.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	AssemblyGlyphs.draw_build_frame(ci, Vector2.ZERO, e.radius, 1.0 - build_cd / maxf(0.01, float(d["build_interval"])))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
