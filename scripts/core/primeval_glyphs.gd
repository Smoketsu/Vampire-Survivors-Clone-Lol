## PrimevalGlyphs — code-drawn fallback shapes for THE AGE OF TITANS (temporary
## Act XIV; GDD §15.0 "The Age of Titans foundation (phase 1)"), drawn when a
## kind has no sprite art (assets/sprites/primeval/<kind>.png): fern green,
## volcanic orange, dust ochre and bone white against the tar-black ink; never
## the necromancer's violet. Beasts only, no humans. Also the stubs'
## placeholder obstacles (mossy boulders, fossil rib arches). Every Titans kind
## without a shape of its own gets the Razorclaw's. Discs are textures
## (SpriteBank.draw_disc), the rest plain rects: no polygon redrawn every
## frame. Purely visual.
class_name PrimevalGlyphs
extends RefCounted

## Outline ink (tar black, darkest).
const INK := Palette.PRIMEVAL_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Titans kind `kind`. Returns false when `kind` is not a Titans kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.primeval_def(kind)  # Its design row ({} = not a Titans kind).
	if row.is_empty():
		return false
	# Phase 2: each Titans stage's own fallbacks go here, before the shared
	# kinds' (as CourtGlyphs asks RavensmoorGlyphs first).
	match kind:
		"scuttler":
			_beast(ci, o, r, flash, Palette.PRIMEVAL_OCHRE_DARK, Palette.PRIMEVAL_OCHRE, 0.5, 0.0)
		"frill_spitter":
			_beast(ci, o, r, flash, Palette.PRIMEVAL_FERN_DARK, Palette.PRIMEVAL_FERN, 0.7, 0.0)
			ci.draw_rect(Rect2(o + Vector2(r * 0.3, -r * 1.1), Vector2(3.0, r * 1.0)), Glyphs._c(Palette.PRIMEVAL_LAVA, flash))  # The frill.
		"longneck":
			_beast(ci, o, r, flash, Palette.PRIMEVAL_OCHRE_DARK, Palette.PRIMEVAL_OCHRE, 1.0, 0.0)
			ci.draw_rect(Rect2(o + Vector2(r * 0.4, -r * 2.0), Vector2(r * 0.3, r * 1.8)), Glyphs._c(Palette.PRIMEVAL_OCHRE, flash))  # The neck.
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.6, -r * 2.0), r * 0.25, Glyphs._c(Palette.PRIMEVAL_OCHRE, flash))  # The head.
		"duckbill":
			_beast(ci, o, r, flash, Palette.PRIMEVAL_FERN_DARK, Palette.PRIMEVAL_OCHRE, 0.9, 0.0)
			ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 1.3), Vector2(r * 0.25, r * 0.6)), Glyphs._c(Palette.PRIMEVAL_BONE, flash))  # The crest.
		"skyraider":
			for s: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(o + Vector2(s * r * 0.3 - (r * 1.2 if s < 0.0 else 0.0), -r * 0.4), Vector2(r * 1.2, r * 0.3)), Glyphs._c(Palette.PRIMEVAL_OCHRE, flash))  # A wing.
			SpriteBank.draw_disc(ci, o, r * 0.42, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.34, Glyphs._c(Palette.PRIMEVAL_OCHRE_DARK, flash))
			ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 0.2), Vector2(r * 0.7, 2.0)), Glyphs._c(Palette.PRIMEVAL_BONE, flash))  # The beak.
		"tyrant":
			_beast(ci, o, r, flash, Palette.PRIMEVAL_TAR, Palette.PRIMEVAL_FERN_DARK, 1.0, 0.0)
			ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.6), Vector2(r * 0.5, 2.0)), Glyphs._c(Palette.PRIMEVAL_LAVA, flash))  # The throat's glow.
		_:
			_beast(ci, o, r, flash, Palette.PRIMEVAL_FERN_DARK, Palette.PRIMEVAL_FERN, 0.8, 1.0)  # The Razorclaw (and any kind without a shape).
	return true


## A beast: a body disc in `hide` with a lighter `back`, a head forward, legs;
## `head` 0..1 sizes the head; `crest` adds bone-white raptor quills.
static func _beast(ci: CanvasItem, o: Vector2, r: float, flash: bool, hide: Color, back: Color, head: float, crest: float) -> void:
	for s: float in [-0.5, 0.3]:
		ci.draw_rect(Rect2(o + Vector2(s * r, r * 0.3), Vector2(r * 0.22, r * 0.7)), Glyphs._c(INK, flash))  # A leg.
	SpriteBank.draw_disc(ci, o, r * 0.8, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.7, Glyphs._c(hide, flash))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.1, -r * 0.2), r * 0.45, Glyphs._c(back, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 1.3, -r * 0.1), Vector2(r * 0.6, r * 0.2)), Glyphs._c(hide, flash))  # The tail.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.7, -r * 0.35), r * 0.35 * head, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.7, -r * 0.35), r * 0.28 * head, Glyphs._c(hide, flash))
	if crest > 0.0:
		ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.8), Vector2(2.0, r * 0.4)), Glyphs._c(Palette.PRIMEVAL_BONE, flash))  # A quill.


# =====================================================================================
# Obstacles (the stubs' placeholders)
# =====================================================================================

## Draws obstacle `o` when it is a Titans stub's kind; false otherwise.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	# Phase 2: each Titans stage's own obstacle glyphs go here first.
	var c := o.center
	match o.kind:
		"primeval_rock":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.3))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.PRIMEVAL_OCHRE_DARK)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.4, Palette.PRIMEVAL_OCHRE)
			SpriteBank.draw_disc(ci, c + Vector2(r * 0.2, -r * 0.5), r * 0.3, Color(Palette.PRIMEVAL_FERN, 0.6))  # Moss.
		"primeval_fossil":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.PRIMEVAL_OCHRE_DARK)
			var ribs := maxi(2, int(rect.size.x / 7.0))  # Rib arches across the block.
			for i in ribs:
				var x := rect.position.x + 3.0 + float(i) * (rect.size.x - 6.0) / float(maxi(1, ribs - 1)) - 1.0
				ci.draw_rect(Rect2(Vector2(x, rect.position.y + 2.0), Vector2(2.0, rect.size.y - 4.0)), Palette.PRIMEVAL_BONE)
		_:
			return false
	return true
