## WildGlyphs — code-drawn fallback shapes for THE TURNING YEAR (temporary Act
## XV; GDD §15.0 "The Turning Year foundation (phase 1)"), drawn when a kind
## has no sprite art (assets/sprites/wild/<kind>.png): moss, bark, blossom
## pink, gold leaves and frost white against the deep-bark ink; never the
## necromancer's violet. Also the stubs' placeholder obstacles (old oaks,
## mossy standing stones) and the THORN THICKET every Wild stage grows
## (Thickets; kind WildRulesData.THICKET_KIND). Every Wild kind without a shape
## of its own gets the Thornling's. Discs are textures (SpriteBank.draw_disc),
## the rest plain rects: no polygon redrawn every frame. Purely visual.
class_name WildGlyphs
extends RefCounted

## Outline ink (deep bark, darkest).
const INK := Palette.WILD_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Wild kind `kind`. Returns false when `kind` is not a Wild kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.wild_def(kind)  # Its design row ({} = not a Wild kind).
	if row.is_empty():
		return false
	# Phase 2: each Wild stage's own fallbacks go here, before the shared kinds'.
	match kind:
		# --- Act XV (temporary number): the World-Tree ---
		"gardener_of_roots":
			if not SpriteBank.draw(ci, "wild/treant", o, flash):  # The Treant's art until his own.
				_figure(ci, o, r, flash, Palette.WILD_BARK, Palette.WILD_MOSS_DARK)
			for s: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(o + Vector2(s * r * 0.9 - 1.5, r * 0.2), Vector2(3.0, r * 0.8)), Glyphs._c(Palette.WILD_BARK, flash))  # A root-hand.
		"burial_thicket":
			if not SpriteBank.draw(ci, "obstacles/wild_thicket_m", o, flash):  # The thicket's own art.
				SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
				SpriteBank.draw_disc(ci, o, r - 2.0, Glyphs._c(Palette.WILD_MOSS_DARK, flash))
				for i in 6:
					var a := TAU * float(i) / 6.0
					ci.draw_rect(Rect2(o + Vector2(cos(a), sin(a)) * r * 0.6 - Vector2(1.0, 1.0), Vector2(r * 0.45, 2.0)), Glyphs._c(Palette.WILD_BARK, flash))  # A bramble.
		# --- Act XV (temporary number): the Fae Court ---
		"winter_prince":
			_figure(ci, o, r, flash, Palette.WILD_FROST, Color(0.62, 0.78, 0.92))
			ci.draw_rect(Rect2(o + Vector2(r * 0.7, -r * 1.1), Vector2(2.0, r * 1.5)), Glyphs._c(Palette.WILD_FROST, flash))  # The icicle sword.
		"masked_courtier":
			_figure(ci, o, r, flash, Palette.WILD_BLOSSOM, Palette.WILD_GOLD_LEAF)
			ci.draw_rect(Rect2(o + Vector2(r * 0.7, -r * 0.9), Vector2(1.5, r * 1.3)), Glyphs._c(Palette.WILD_BONE, flash))  # The thorn rapier.
		# --- Act XV (temporary number): the Greenwood ---
		"huntsman":
			if not SpriteBank.draw(ci, "wild/wild_rider", o, flash):  # The Rider's art until his own.
				SpriteBank.draw_disc(ci, o, r * 0.85, Glyphs._c(INK, flash))
				SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(Palette.WILD_MOSS_DARK, flash))
			for s: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(o + Vector2(s * r * 0.35 - 1.0, -r * 1.5), Vector2(2.0, r * 0.6)), Glyphs._c(Palette.WILD_BONE, flash))  # His antlered helm.
		"hunt_hound":
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(Palette.WILD_FROST.darkened(0.35), flash))
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 0.5), Vector2(r * 0.7, r * 0.4)), Glyphs._c(Palette.WILD_FROST.darkened(0.2), flash))  # The muzzle.
		"antler_thicket":
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(Palette.WILD_BARK, flash))
			for i in 4:
				var a := TAU * float(i) / 4.0 + 0.4
				ci.draw_rect(Rect2(o + Vector2(cos(a), sin(a)) * r * 0.7 - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Glyphs._c(Palette.WILD_BONE, flash))  # An antler tine.
		"dryad":
			_figure(ci, o, r, flash, Palette.WILD_MOSS, Palette.WILD_BLOSSOM)
		"treant":
			_figure(ci, o, r, flash, Palette.WILD_BARK, Palette.WILD_MOSS_DARK)
			for s: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(o + Vector2(s * r * 0.6 - 1.5, -r * 1.5), Vector2(3.0, r * 0.7)), Glyphs._c(Palette.WILD_BARK, flash))  # A branch.
		"corpse_bloom":
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(Palette.WILD_MOSS_DARK, flash))
			for i in 5:
				var a := TAU * float(i) / 5.0
				SpriteBank.draw_disc(ci, o + Vector2(cos(a), sin(a)) * r * 0.55, r * 0.32, Glyphs._c(Palette.WILD_BLOSSOM, flash))  # A petal.
			SpriteBank.draw_disc(ci, o, r * 0.25, Glyphs._c(Palette.WILD_BONE, flash))
		"fae_knight":
			_figure(ci, o, r, flash, Palette.WILD_MOSS_DARK, Palette.WILD_GOLD_LEAF)
			ci.draw_rect(Rect2(o + Vector2(r * 0.7, -r * 1.0), Vector2(2.0, r * 1.4)), Glyphs._c(Palette.WILD_BONE, flash))  # The thorn sword.
		"winter_fae":
			_figure(ci, o, r, flash, Palette.WILD_FROST, Color(0.62, 0.78, 0.92))
		"great_stag", "wild_rider":
			SpriteBank.draw_disc(ci, o, r * 0.85, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(Palette.WILD_BARK if kind == "great_stag" else Color(0.55, 0.65, 0.72), flash))
			for s: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(o + Vector2(r * 0.3 + s * r * 0.3, -r * 1.4), Vector2(2.0, r * 0.7)), Glyphs._c(Palette.WILD_BONE, flash))  # Antlers / a spear.
		"will_o_wisp":
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(Color(0.6, 0.95, 0.85, 0.5), flash))
			SpriteBank.draw_disc(ci, o, r * 0.5, Glyphs._c(Palette.WILD_FROST, flash))
		"spore_mother":
			_figure(ci, o, r, flash, Color(0.45, 0.38, 0.28), Palette.WILD_GOLD_LEAF)
			SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.3), r * 0.55, Glyphs._c(Color(0.62, 0.5, 0.36), flash))  # The cap.
		_:
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))  # The Thornling (and any kind without a shape).
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(Palette.WILD_BARK, flash))
			ci.draw_rect(Rect2(o + Vector2(-r, -1.0), Vector2(r * 2.0, 2.0)), Glyphs._c(Palette.WILD_MOSS, flash))  # Twigs.
	return true


## A fae figure: a robe disc in `robe`, a head, and a hair / crown accent.
static func _figure(ci: CanvasItem, o: Vector2, r: float, flash: bool, robe: Color, accent: Color) -> void:
	SpriteBank.draw_disc(ci, o, r * 0.85, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(robe, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.42, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.34, Glyphs._c(Palette.WILD_BONE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.3), Vector2(r * 0.8, 2.0)), Glyphs._c(accent, flash))  # The crown of leaves.


# =====================================================================================
# Obstacles (the stubs' placeholders and the thorn thickets)
# =====================================================================================

## Draws obstacle `o` when it is a Wild kind; false otherwise.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	# Phase 2: each Wild stage's own obstacle glyphs go here first.
	var c := o.center
	match o.kind:
		# --- Act XV (temporary number): the World-Tree ---
		"wild_great_root":
			var rr := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rr.position + Vector2(3, 4), rr.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(rr, INK)
			ci.draw_rect(rr.grow(-1.5), Palette.WILD_BARK)
			var horiz := rr.size.x >= rr.size.y  # The root's long axis.
			ci.draw_rect(Rect2(rr.position + Vector2(2, 2), Vector2(rr.size.x - 4.0, 2.0) if horiz else Vector2(2.0, rr.size.y - 4.0)), Color(Palette.WILD_MOSS, 0.6))  # Moss along it.
		# --- Act XV (temporary number): the Fae Court ---
		"wild_rose_hedge":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Palette.WILD_MOSS_DARK)
			var long := maxf(rect.size.x, rect.size.y)
			var n := int(long / 12.0)
			for i in n:
				var t := (float(i) + 0.5) / float(n)
				var rp := rect.position + (Vector2(rect.size.x * t, rect.size.y * 0.5) if rect.size.x >= rect.size.y else Vector2(rect.size.x * 0.5, rect.size.y * t))
				SpriteBank.draw_disc(ci, rp, 2.5, Palette.WILD_BLOSSOM if (i + o.variant) % 2 == 0 else Color(0.85, 0.2, 0.3))  # A rose.
		"wild_oak":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.3))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.WILD_BARK)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.2, -r * 0.3), r * 0.55, Color(Palette.WILD_MOSS, 0.55))  # Moss on the trunk.
		"wild_stone":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Color(0.42, 0.44, 0.40))
			ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4.0, 3.0)), Color(Palette.WILD_MOSS, 0.7))  # Moss on top.
		WildRulesData.THICKET_KIND:
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(2, 3), r, Color(0, 0, 0, 0.3))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 2.0, Palette.WILD_MOSS_DARK)
			for i in 7:
				var a := TAU * float(i) / 7.0 + float(o.variant % 7) * 0.3
				ci.draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * r * 0.6 - Vector2(1.0, 1.0), Vector2(r * 0.45, 2.0)), Palette.WILD_BARK)  # A thorny bramble.
				ci.draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * r * 0.8, Vector2(2.0, 2.0)), Palette.WILD_BONE)  # A thorn.
		_:
			return false
	return true
