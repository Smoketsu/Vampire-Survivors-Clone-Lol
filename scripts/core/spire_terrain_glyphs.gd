## SpireTerrainGlyphs — code-drawn fallback shapes of Ul-Thalos's obstacles
## (Act II, Stage 6; GDD §15.0 "Ul-Thalos, the Risen Spire": wet green
## cyclopean stone and wrong angles), drawn by Arena._draw_obstacle() when an
## obstacle has no sprite art (obstacles/<kind>_<size>.png). The solid outline
## matches the collision shape. Purely visual.
##   cyclopean_block, barnacle_pillar, fallen_idol   (the Breakwater)
##   step_ruin, drowned_idol                         (the Sunken Steps)
##   gate_pylon, toppled_arch                        (the Dream Gate)
##   spire_shard                                     (the Spire)
class_name SpireTerrainGlyphs
extends RefCounted

## Dark obstacle edge (drowned ink).
const EDGE := Color(0.02, 0.08, 0.10)
## Wet green cyclopean stone.
const STONE := Color(0.20, 0.30, 0.27)
## Its shaded face.
const STONE_SHADE := Color(0.13, 0.21, 0.19)
## Its lit, slimy top.
const STONE_LIT := Color(0.29, 0.42, 0.37)
## Barnacles and foam crusts.
const BARNACLE := Color(0.50, 0.71, 0.67)
## The dream's glow in the Gate's stone (the Eye's biolume).
const GLOW := Color(0.69, 0.30, 0.75)
## Cast shadow under obstacles.
const SHADOW := Color(0, 0, 0, 0.35)


## Draws Ul-Thalos obstacle `o`; false for a kind it does not know.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"cyclopean_block", "step_ruin", "fallen_idol", "toppled_arch":
			_block(ci, o)
		"barnacle_pillar", "gate_pylon", "spire_shard":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r * 1.1, SHADOW)
			# A wrong-angled column: an irregular polygon instead of a circle.
			var n := 5 if o.kind == "spire_shard" else 7
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, r, n, float(o.variant % 100) * 0.03), EDGE)
			ci.draw_colored_polygon(Glyphs.regular_polygon(c, r - 2.0, n, float(o.variant % 100) * 0.03), STONE)
			ci.draw_colored_polygon(Glyphs.regular_polygon(c + Vector2(-r * 0.15, -r * 0.2), r * 0.55, n, 0.4), STONE_LIT)
			if o.kind == "barnacle_pillar":
				for i in 4:
					var a := TAU * float(i) / 4.0 + float(o.variant % 60) * 0.05
					ci.draw_circle(c + Vector2.from_angle(a) * r * 0.6, 2.0, BARNACLE)
			else:
				ci.draw_line(c + Vector2(-r * 0.4, -r * 0.1), c + Vector2(r * 0.4, r * 0.15), Color(GLOW, 0.8), 1.5)
		"drowned_idol":
			var r := o.radius
			ci.draw_circle(c + Vector2(4, 5), r * 1.05, SHADOW)
			ci.draw_circle(c, r, EDGE)
			ci.draw_circle(c, r - 2.0, STONE_SHADE)
			ci.draw_circle(c + Vector2(0, -r * 0.15), r * 0.62, STONE)
			# The idol's one great eye, closed.
			ci.draw_line(c + Vector2(-r * 0.35, -r * 0.15), c + Vector2(r * 0.35, -r * 0.15), EDGE, 2.0)
			ci.draw_circle(c + Vector2(0, -r * 0.15), 2.0, Color(GLOW, 0.7))
		_:
			return false
	return true


## A rectangular cyclopean block (and the fallen idols, steps and arches):
## a slab with a lit top face, joints at wrong angles and a crust of
## barnacles; the Gate's arches carry a glowing glyph.
static func _block(ci: CanvasItem, o: Arena.Obstacle) -> void:
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	var horizontal := o.half.x > o.half.y
	ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), SHADOW)
	ci.draw_rect(rect, EDGE)
	var inner := rect.grow(-1.5)
	ci.draw_rect(inner, STONE_SHADE)
	var top := Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.55)) if horizontal \
			else Rect2(inner.position, Vector2(inner.size.x * 0.55, inner.size.y))
	ci.draw_rect(top, STONE)
	var long_len := (o.half.x if horizontal else o.half.y) * 2.0
	var k := 18.0 + float(o.variant % 7)
	while k < long_len - 6.0:
		# A slanted joint (the angles are wrong on purpose).
		if horizontal:
			ci.draw_line(Vector2(rect.position.x + k, rect.position.y + 2.0), Vector2(rect.position.x + k + 5.0, rect.end.y - 2.0), EDGE, 1.0)
		else:
			ci.draw_line(Vector2(rect.position.x + 2.0, rect.position.y + k), Vector2(rect.end.x - 2.0, rect.position.y + k + 5.0), EDGE, 1.0)
		k += 22.0 + float(o.variant % 5)
	for i in 3:
		var t := (float(i) + 0.5) / 3.0
		var p := rect.position + (Vector2(rect.size.x * t, rect.size.y - 3.0) if horizontal else Vector2(rect.size.x - 3.0, rect.size.y * t))
		ci.draw_circle(p, 1.8, BARNACLE)
	if o.kind == "toppled_arch":
		ci.draw_circle(o.center, 3.0, Color(GLOW, 0.75))
		ci.draw_arc(o.center, 6.0, 0.0, TAU, 12, Color(GLOW, 0.5), 1.0)
