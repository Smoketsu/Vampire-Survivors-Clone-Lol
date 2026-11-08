## DynastyGlyphs — code-drawn fallback shapes for THE NECROPOLIS DYNASTY
## (temporary Act XII; GDD §15.0 "The Necropolis Dynasty foundation (phase
## 1)"), drawn when a kind has no sprite art (assets/sprites/dynasty/<kind>.png
## or structures/<kind>.png): wrapped linen, the dull bronze-gold (never the
## player's reward gold), lapis, sandstone, carnelian and papyrus green
## against the blue-black desert night; never the necromancer's violet. Also
## the stubs' placeholder obstacles (rock-cut tombs, dune rocks, painted
## columns, lioness statues, obelisks). Every Dynasty kind without a shape of
## its own gets the mummy. Discs are textures (SpriteBank.draw_disc), the
## rest plain rects: no polygon redrawn every frame. Purely visual. The
## cartouche draws itself (CartoucheKit).
class_name DynastyGlyphs
extends RefCounted

## Outline ink (the night ramp, darkest).
const INK := Palette.DYN_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Dynasty kind `kind`. Returns false when `kind` is not a Dynasty kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.dynasty_def(kind)  # Its design row ({} = not a Dynasty kind).
	if row.is_empty():
		return false
	# Phase 2: each Dynasty stage's own fallbacks go here, before the shared
	# kinds' (as CourtGlyphs asks RavensmoorGlyphs first).
	match kind:
		"scarab_swarm":
			_scarabs(ci, o, r, flash)
		"khopesh_guard":
			_guard(ci, o, r, flash)
		"heka_priest":
			_priest(ci, o, r, flash, Palette.DYN_LINEN, Palette.DYN_BRONZE)
		"embalmer":
			_priest(ci, o, r, flash, Palette.DYN_LINEN, Palette.DYN_PAPYRUS)
		"canopic_jar":
			draw_jar(ci, o, r, flash)
		"mummy_female":
			_mummy(ci, o, r * 0.92, flash)
		_:
			_mummy(ci, o, r, flash)
	return true


## Mummy: a wrapped body, linen bands, dull bronze collar, dark eye slits.
static func _mummy(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 1.6))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.DYN_LINEN, flash))
	var y := body.position.y + 3.0
	while y < body.end.y - 1.0:
		ci.draw_rect(Rect2(Vector2(body.position.x, y), Vector2(body.size.x, 1.0)), Glyphs._c(Palette.DYN_LINEN_DARK, flash))  # Bands.
		y += 4.0
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.85), r * 0.5, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.85), r * 0.43, Glyphs._c(Palette.DYN_LINEN, flash))  # The head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.92), Vector2(r * 0.6, 1.5)), INK)  # Eye slit.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 0.45), Vector2(r * 1.0, 2.0)), Glyphs._c(Palette.DYN_BRONZE, flash))  # Collar.


## Scarab Swarm: a lapis beetle among smaller ones, bronze glints.
static func _scarabs(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for k in 6:
		var p := o + Vector2.from_angle(TAU * float(k) / 6.0 + 0.4) * r * 0.75
		SpriteBank.draw_disc(ci, p, r * 0.3, Glyphs._c(INK, flash))
		SpriteBank.draw_disc(ci, p, r * 0.24, Glyphs._c(Palette.DYN_LAPIS_DARK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.5, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.43, Glyphs._c(Palette.DYN_LAPIS, flash))
	ci.draw_rect(Rect2(o + Vector2(-0.5, -r * 0.4), Vector2(1.0, r * 0.8)), INK)  # Wing-case line.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.5), Vector2(2.0, 2.0)), Palette.DYN_BRONZE_LIGHT)  # A glint.


## Khopesh Guard: linen kilt, striped headcloth, a curved bronze blade.
static func _guard(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.5), Vector2(r * 1.0, r * 1.4))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.DYN_SKIN, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0.0, body.size.y * 0.55), Vector2(body.size.x, body.size.y * 0.45)), Glyphs._c(Palette.DYN_LINEN, flash))  # Kilt.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.75), r * 0.45, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.75), r * 0.38, Glyphs._c(Palette.DYN_LAPIS, flash))  # Headcloth.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.38, -r * 0.8), Vector2(r * 0.76, 1.5)), Palette.DYN_BRONZE)  # Its stripe.
	ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 0.6), Vector2(2.0, r * 1.0)), Glyphs._c(Palette.DYN_BRONZE, flash))  # The blade...
	ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 0.7), Vector2(r * 0.35, 2.0)), Glyphs._c(Palette.DYN_BRONZE_LIGHT, flash))  # ... and its hook.


## A priest or an Embalmer: a long robe of `robe`, a collar of `collar`, a dark wig.
static func _priest(ci: CanvasItem, o: Vector2, r: float, flash: bool, robe: Color, collar: Color) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.45), Vector2(r * 1.0, r * 1.55))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(robe, flash))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, 3.0)), Glyphs._c(collar, flash))  # Collar.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.75), r * 0.42, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.72), r * 0.34, Glyphs._c(Palette.DYN_SKIN, flash))  # Face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.05), Vector2(r * 0.8, r * 0.25)), Glyphs._c(Palette.DYN_NIGHT_DARK, flash))  # Wig.


## Canopic Jar: a fired-clay jar with a lapis band and a jackal-head lid.
static func draw_jar(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(2.0, 3.0), r, Color(0.0, 0.0, 0.0, 0.3))
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.7), Vector2(r * 1.2, r * 1.6))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.DYN_SAND, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0.0, body.size.y * 0.35), Vector2(body.size.x, 3.0)), Glyphs._c(Palette.DYN_LAPIS, flash))  # Band.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.45, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.38, Glyphs._c(Palette.DYN_NIGHT, flash))  # The jackal lid.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.35), Vector2(2.0, r * 0.3)), Glyphs._c(Palette.DYN_NIGHT, flash))  # Ears.
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 1.35), Vector2(2.0, r * 0.3)), Glyphs._c(Palette.DYN_NIGHT, flash))


# =====================================================================================
# Obstacles (the stubs' placeholders)
# =====================================================================================

## Draws obstacle `o` when it is a Dynasty placeholder kind; false otherwise.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	# Phase 2: each Dynasty stage's own obstacle kinds go first here.
	var c := o.center
	match o.kind:
		# --- Act XII (temporary number): the Necropolis of Sand --- (their art is obstacles/dyn_*; these are the fallbacks)
		"dynasty_dune_rock", "dynasty_column", "dyn_sandstone_blocks", "dyn_sphinx_head", "dyn_obelisk":
			var r := o.radius
			var face := Palette.DYN_SAND_DARK  # A wind-worn rock.
			var hi := Palette.DYN_SAND
			if o.kind == "dynasty_column":
				face = Palette.DYN_SAND
				hi = Palette.DYN_SAND_LIGHT
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, face)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, hi)
			if o.kind == "dynasty_column":
				SpriteBank.draw_disc(ci, c, r * 0.55, Color(Palette.DYN_LAPIS, 0.6))  # A painted band.
				SpriteBank.draw_disc(ci, c, r * 0.4, face)
		"dynasty_tomb", "dynasty_statue", "dynasty_obelisk", "dyn_tomb":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Palette.DYN_SAND_DARK  # A rock-cut tomb front.
			var line := Palette.DYN_INK
			if o.kind == "dynasty_statue":
				face = Palette.DYN_SAND
				line = Palette.DYN_CARNELIAN  # A painted lioness on her plinth.
			elif o.kind == "dynasty_obelisk":
				face = Palette.DYN_NIGHT_DARK
				line = Palette.DYN_BRONZE  # Basalt with bronze glyphs.
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			var door := Rect2(rect.get_center() - rect.size * Vector2(0.18, 0.3), rect.size * Vector2(0.36, 0.6))  # The doorway / plinth panel.
			ci.draw_rect(door, Color(line, 0.8))
		_:
			return false
	return true
