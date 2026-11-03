## ArkGlyphs — code-drawn shapes of THE ARK OF THE CONCORD (Act IX, Stage 27;
## GDD §15.0 "The Ark of the Concord (Act IX phase 2)" and the rows after it),
## drawn when a sprite is missing (assets/sprites/concord/<kind>.png,
## structures/<kind>.png, bosses/harvester*.png, obstacles/ark_*.png): hull
## white and gunmetal, plasma green, the Luminous's white-gold; never the
## necromancer's violet and bone on a Concord kind. Also the looks the Ark's
## systems and rewards draw every frame: the Harvester's throne of rings, a
## wreck on the floor, Tractor Beam's lift column and the Ghost Saucer's short
## beams. Every look is a texture drawn with draw_texture_rect (SpriteBank's
## soft disc, ConcordBeams.line_texture(), the effects/ark_ring mask when
## present): no polygon redrawn every frame (the Web GL rule in CLAUDE.md).
## Purely visual.
class_name ArkGlyphs
extends RefCounted

## Outline ink (the Concord's starfield black).
const INK := Palette.CONCORD_INK
## The necromancer's soul colour (Tractor Beam, the Ghost Saucer: never a
## Concord colour, so a player never mistakes his own beam for theirs).
const SOUL := Color(0.70, 0.92, 0.86)  # TUNING (not in GDD) the soul-teal of the volleys


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Ark kind `kind` (ArkEnemyData, or the shared Grey Overseer). Returns
## false for any other kind (ConcordGlyphs then draws the shared ones).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"grey_overseer":
			_overseer(ci, o, r, flash)
		"luminous_archon":
			_archon(ci, o, r, flash)
		"specimen_tank":
			_tank(ci, o, r, flash)
		"vault_beast":
			_beast(ci, o, r, flash)
		"reactor_vent":
			_vent(ci, o, r, flash)
		"reap_emitter":
			_emitter(ci, o, r, flash)
		_:
			return false
	return true


## Grey Overseer: a tall grey in a gunmetal mantle, a plasma crown.
static func _overseer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.4), Vector2(r * 1.2, r * 1.6))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CONCORD_GUNMETAL, flash))  # The mantle.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.62, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.55, Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # The great head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.05), Vector2(r * 0.3, r * 0.22)), INK)  # Black eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 1.05), Vector2(r * 0.3, r * 0.22)), INK)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.6), Vector2(r * 0.9, 2.0)), Palette.CONCORD_PLASMA)  # The crown.


## Luminous Archon: a tall being of white-gold light in crystal plates.
static func _archon(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.5), r * 1.6, Color(Palette.CONCORD_LUMEN, 0.25))  # Its light.
	var body := Rect2(o + Vector2(-r * 0.55, -r * 1.0), Vector2(r * 1.1, r * 2.0))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # Crystal plates.
	ci.draw_rect(body.grow(-2.0), Glyphs._c(Palette.CONCORD_LUMEN, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.35), r * 0.45, Glyphs._c(Palette.CONCORD_LUMEN, flash))  # Head of light.
	for k in 3:
		var w := o + Vector2((float(k) - 1.0) * r * 0.7, -r * 1.9)
		ci.draw_rect(Rect2(w, Vector2(2.0, r * 0.5)), Palette.CONCORD_HULL)  # A crown of crystal shards.


## Specimen tank: a glass cylinder of green fluid on a gunmetal base.
static func _tank(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var glass := Rect2(o + Vector2(-r * 0.75, -r * 1.7), Vector2(r * 1.5, r * 2.2))
	ci.draw_rect(glass.grow(1.0), INK)
	ci.draw_rect(glass, Glyphs._c(Color(0.10, 0.30, 0.20), flash))  # The fluid.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.6), r * 0.45, Glyphs._c(Color(0.55, 0.22, 0.14), flash))  # The beast inside.
	ci.draw_rect(Rect2(glass.position, Vector2(glass.size.x, 3.0)), Glyphs._c(Palette.CONCORD_GUNMETAL, flash))  # The cap.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.85, r * 0.5), Vector2(r * 1.7, r * 0.5)), Glyphs._c(Palette.CONCORD_GUNMETAL, flash))  # The base.


## Freed beast: a six-legged rust-red grazer-predator with an ochre crest.
static func _beast(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for k in 3:
		var x := (float(k) - 1.0) * r * 0.6
		ci.draw_rect(Rect2(o + Vector2(x, r * 0.3), Vector2(2.0, r * 0.6)), INK)  # Legs.
	SpriteBank.draw_disc(ci, o, r * 1.0, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.9, Glyphs._c(Color(0.62, 0.24, 0.16), flash))  # Rust-red hide.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.7, -r * 0.95), Vector2(r * 1.4, 2.0)), Glyphs._c(Color(0.86, 0.66, 0.30), flash))  # Ochre crest.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.6, -r * 0.2), 2.0, Palette.CONCORD_LUMEN)  # A glowing eye.


## Reactor vent: a round grating over a plasma glow.
static func _vent(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r, Glyphs._c(Palette.CONCORD_GUNMETAL, flash))
	SpriteBank.draw_disc(ci, o, r * 0.7, Glyphs._c(Palette.CONCORD_PLASMA_DARK, flash))
	for k in 3:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.7, -r * 0.4 + float(k) * r * 0.4), Vector2(r * 1.4, 1.5)), Glyphs._c(Palette.CONCORD_GUNMETAL_DARK, flash))  # The grating.


## Reaping emitter: a gunmetal pylon with a plasma lens.
static func _emitter(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var pylon := Rect2(o + Vector2(-r * 0.45, -r * 1.6), Vector2(r * 0.9, r * 2.1))
	ci.draw_rect(pylon.grow(1.0), INK)
	ci.draw_rect(pylon, Glyphs._c(Palette.CONCORD_GUNMETAL, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, r * 0.3), Vector2(r * 1.6, r * 0.4)), Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # The foot.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.6), r * 0.42, Glyphs._c(Palette.CONCORD_HULL, flash))


## A wreck on the floor (a broken tank or vent): a dark stain and shards.
static func draw_wreck(ci: CanvasItem, at: Vector2, kind: String) -> void:
	var fluid := Color(0.08, 0.30, 0.16, 0.6) if kind == ArkEnemyData.TANK else Color(0.05, 0.06, 0.07, 0.6)
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(20.0, 9.0), Vector2(40.0, 18.0)), false, fluid)
	ci.draw_rect(Rect2(at + Vector2(-12.0, -2.0), Vector2(10.0, 3.0)), Color(Palette.CONCORD_GUNMETAL, 0.9))
	ci.draw_rect(Rect2(at + Vector2(4.0, 1.0), Vector2(7.0, 2.0)), Color(Palette.CONCORD_HULL_SHADE, 0.8))


# =====================================================================================
# The Harvester
# =====================================================================================

## The Harvester without art: a tall grey in white robes, its great head, a
## crown of light in its true form. `a` its opacity (the cloak's shimmer).
static func draw_harvester(ci: CanvasItem, o: Vector2, r: float, flash: bool, a: float, true_form: bool) -> void:
	var robe := Rect2(o + Vector2(-r * 0.5, -r * 0.6), Vector2(r * 1.0, r * 1.6))
	ci.draw_rect(robe.grow(1.0), Color(INK, a))
	ci.draw_rect(robe, Color(Glyphs._c(Palette.CONCORD_HULL, flash), a))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.05), r * 0.6, Color(Glyphs._c(Palette.CONCORD_HULL_SHADE, flash), a))  # The great head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.38, -r * 1.15), Vector2(r * 0.28, r * 0.2)), Color(INK, a))
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 1.15), Vector2(r * 0.28, r * 0.2)), Color(INK, a))
	if true_form:
		draw_true_glow(ci, o, r, 0.0)


## The light of its true form over its body (the Gardener): a white-gold glow.
static func draw_true_glow(ci: CanvasItem, o: Vector2, r: float, t: float) -> void:
	var k := 0.8 + 0.2 * sin(t * 2.0)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 2.4 * k, Color(Palette.CONCORD_LUMEN, 0.18))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 1.2, Color(Palette.CONCORD_LUMEN, 0.22))


## Its throne of rings under its body at `o` (`r` its radius): three tilted
## rings turning slowly (the effects/ark_ring mask tinted hull white, else a
## soft ring of discs), larger and golden in its true form.
static func draw_throne(ci: CanvasItem, o: Vector2, r: float, t: float, true_form: bool, a: float) -> void:
	var tex := SpriteBank.texture(HarvesterData.RING_SPRITE)
	var col := Color(Palette.CONCORD_LUMEN if true_form else Palette.CONCORD_HULL_SHADE, 0.75 * a)
	var scale := 1.6 if true_form else 1.0
	for i in 3:
		var w := r * (2.6 + float(i) * 0.7) * scale  # Ring width (px).
		var h := w * (0.32 + 0.06 * sin(t * (0.6 + float(i) * 0.25) + float(i)))  # Tilt (it turns).
		var c := o + Vector2(0.0, r * 0.4 - float(i) * 3.0)
		if tex != null:
			ci.draw_texture_rect(tex, Rect2(c - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), false, col)
		else:
			ci.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), false, Color(col, col.a * 0.35))
			ci.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(w * 0.4, h * 0.4), Vector2(w * 0.8, h * 0.8)), false, Color(INK, 0.25 * a))


# =====================================================================================
# The rewards' looks
# =====================================================================================

## Tractor Beam's lift column (also the Ghost Saucer's): a soul-coloured
## column of light from high above down onto `at`, `half` px wide, at
## strength `k` 0..1, with a glowing ring on the ground (textures).
static func draw_lift_column(ci: CanvasItem, at: Vector2, half: float, k: float, col: Color) -> void:
	var top := at + Vector2(0.0, -150.0)
	stretch(ci, top, at, half * 2.4, Color(col, 0.16 * k))
	stretch(ci, top, at, half * 1.1, Color(col, 0.34 * k))
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(half * 1.3, half * 0.5), Vector2(half * 2.6, half)), false, Color(col, 0.35 * k))


## The lifted foe's shadow-free mark in the air: a bright disc `h` px above `at`.
static func draw_lifted(ci: CanvasItem, at: Vector2, h: float, r: float, col: Color) -> void:
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(r, r * 0.4), Vector2(r * 2.0, r * 0.8)), false, Color(0.0, 0.0, 0.0, 0.3))  # Its shadow below.
	SpriteBank.draw_disc(ci, at + Vector2(0.0, -h), r * 0.9, Color(col, 0.5))


## A short soul beam from `a` to `b`, `w` px across (the Ghost Saucer's shot).
static func draw_soul_beam(ci: CanvasItem, a: Vector2, b: Vector2, w: float, k: float) -> void:
	stretch(ci, a, b, w * 2.2, Color(SOUL, 0.25 * k))
	stretch(ci, a, b, w, Color(Palette.IVORY, 0.8 * k))


## A soft line texture stretched from `a` to `b`, `w` px across, tinted `col`
## (the beams' made texture; leaves the identity transform).
static func stretch(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var v := b - a
	var length_px := v.length()
	if length_px < 1.0 or col.a <= 0.01:
		return
	ci.draw_set_transform_matrix(Transform2D(v.angle(), a))
	ci.draw_texture_rect(ConcordBeams.line_texture(), Rect2(Vector2(0.0, -w * 0.5), Vector2(length_px, w)), false, col)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


# =====================================================================================
# Obstacles
# =====================================================================================

## Draws one of the Ark's obstacles without its sprite (crates, consoles,
## pillars). Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"ark_pillar":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.CONCORD_HULL_SHADE)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Palette.CONCORD_HULL)
			SpriteBank.draw_disc(ci, c, r * 0.22, Palette.CONCORD_PLASMA)  # A light ring.
		"ark_crate", "ark_console":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Palette.CONCORD_GUNMETAL if o.kind == "ark_crate" else Palette.CONCORD_GUNMETAL_DARK
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			if o.kind == "ark_console":
				ci.draw_rect(rect.grow(-4.0), Color(Palette.CONCORD_PLASMA_DARK, 0.6))  # Its screens.
			else:
				ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4.0, 2.0)), Palette.CONCORD_HULL_SHADE)  # A white band.
		_:
			return false
	return true
