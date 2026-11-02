## CourtGlyphs — code-drawn fallback shapes for THE SANGUINE COURT (Act VII; GDD
## §15.0 "Act VII foundation (phase 1)"), drawn when a kind has no sprite art
## (assets/sprites/court/<kind>.png, structures/court_coffin*.png): blood red,
## black velvet, candle gold and moonlit silver, blood-ink outlines (the blood,
## velvet and moonlight ramps, never the undead's bone and soul teal). Also:
##   * the Act VII stubs' placeholder obstacles (moor stones, gravestones, dead
##     trees, hanging charms, castle pillars, banquet tables);
##   * the shared rules' textures, made once in code (never loaded headless):
##     Bloodfeast's red thread (draw_thread(): one small texture stretched and
##     turned along the line; the noble's drain beam and the beast's lunge
##     line use it too) and the blood shield ring (draw_blood_shield()). Every
##     one is a texture drawn with draw_texture_rect (batched; no polygon
##     redrawn every frame: the Web GL rule in CLAUDE.md).
## Every Court kind without a shape of its own gets the plain thrall. Purely
## visual.
class_name CourtGlyphs
extends RefCounted

## Outline ink of the blood ramp (darkest).
const INK := Color(0.071, 0.024, 0.039)
## Pale thrall skin (moonlight, drained).
const PALE := Color(0.78, 0.76, 0.78)
## Candle gold (the existing gold's warm trim on velvet).
const CANDLE := Color(0.86, 0.68, 0.30)
## Side (px) of the made ring texture.
const TEX_SIZE: int = 64

## The thread texture (made on first use).
static var _thread_tex: Texture2D = null
## The shield ring texture (made on first use).
static var _ring_tex: Texture2D = null


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Court kind `kind`. Returns false when `kind` is not a Court kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.court_def(kind)  # Its design row ({} = not a Court kind).
	if row.is_empty():
		return false
	# Phase 2: each Act VII stage's own fallbacks go here, before the shared
	# kinds' (as InfernoGlyphs asks BurningGateGlyphs first).
	match kind:
		"vampire_bat":
			_bat(ci, o, r, flash)
		"blood_knight":
			_knight(ci, o, r, flash)
		"werewolf":
			_hunter(ci, o, r, flash)
		"vampire_noble":
			_noble(ci, o, r, flash)
		"court_coffin":
			draw_coffin(ci, o, r, flash, false)
		_:
			_thrall(ci, o, r, flash)
	return true


## Blood Thrall: a pale, hunched servant with bite marks.
static func _thrall(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.3), Vector2(r, r * 1.3))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.COURT_VELVET_LIGHT, flash))  # Ragged servant's coat.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.0), Vector2(r * 0.8, r * 0.7)), Glyphs._c(PALE, flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.45), Vector2(r * 0.25, r * 0.15)), Glyphs._c(Palette.COURT_BLOOD, flash))  # The bite.


## Vampire Bat: velvet wings spread, red eyes.
static func _bat(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var wing := Glyphs._c(Palette.COURT_VELVET, flash)
	ci.draw_rect(Rect2(o + Vector2(-r * 1.8, -r * 0.5), Vector2(r * 1.4, r * 0.7)), wing)
	ci.draw_rect(Rect2(o + Vector2(r * 0.4, -r * 0.5), Vector2(r * 1.4, r * 0.7)), wing)
	SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.6, Glyphs._c(Palette.COURT_VELVET_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 0.2), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)
	ci.draw_rect(Rect2(o + Vector2(r * 0.15, -r * 0.2), Vector2(2, 2)), Palette.COURT_BLOOD_LIGHT)


## Blood Knight: blood-red plate, a halberd.
static func _knight(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.9), Vector2(r * 1.2, r * 1.9))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.COURT_BLOOD, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.35), Vector2(r * 0.9, r * 0.6)), Glyphs._c(Palette.COURT_BLOOD_DARK, flash))  # Helm.
	ci.draw_line(o + Vector2(r * 0.9, r * 0.9), o + Vector2(r * 0.9, -r * 1.7), Glyphs._c(Palette.COURT_VELVET_DARK, flash), 2.0)  # Haft.
	ci.draw_rect(Rect2(o + Vector2(r * 0.9, -r * 1.7), Vector2(r * 0.5, r * 0.6)), Glyphs._c(Palette.COURT_MOON, flash))  # The blade.


## Werewolf (the hunter): a cloaked man with a silver crossbow.
static func _hunter(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.8), Vector2(r * 1.2, r * 1.8))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Color(0.32, 0.24, 0.18), flash))  # A leather coat.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.3), Vector2(r * 0.8, r * 0.6)), Glyphs._c(Color(0.62, 0.5, 0.42), flash))  # Face.
	ci.draw_line(o + Vector2(r * 0.2, -r * 0.1), o + Vector2(r * 1.5, -r * 0.1), Glyphs._c(Palette.COURT_MOON_DARK, flash), 3.0)  # Crossbow.
	ci.draw_line(o + Vector2(r * 1.2, -r * 0.6), o + Vector2(r * 1.2, r * 0.4), Glyphs._c(Palette.COURT_MOON_LIGHT, flash), 1.0)


## Werewolf (the beast): a huge grey-black wolf-man, red maw.
static func draw_beast(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r, Glyphs._c(Color(0.24, 0.22, 0.24), flash))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.35, -r * 0.45), r * 0.45, Glyphs._c(Color(0.32, 0.30, 0.32), flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.4), Vector2(r * 0.35, r * 0.15)), Palette.COURT_BLOOD_LIGHT)  # The maw.
	ci.draw_line(o + Vector2(r * 0.1, -r * 0.85), o + Vector2(r * 0.25, -r * 1.2), Glyphs._c(INK, flash), 2.0)  # Ears.
	ci.draw_line(o + Vector2(r * 0.55, -r * 0.85), o + Vector2(r * 0.6, -r * 1.2), Glyphs._c(INK, flash), 2.0)


## Vampire Noble: the Countess in a velvet gown, gold trim.
static func _noble(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var skirt := Rect2(o + Vector2(-r * 0.8, -r * 0.1), Vector2(r * 1.6, r * 1.2))
	ci.draw_rect(skirt.grow(1.0), INK)
	ci.draw_rect(skirt, Glyphs._c(Palette.COURT_VELVET, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.9), Vector2(r * 0.8, r * 0.85)), Glyphs._c(Palette.COURT_BLOOD_DARK, flash))  # Bodice.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.45), Vector2(r * 0.6, r * 0.55)), Glyphs._c(PALE, flash))  # Face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.1), Vector2(r * 1.6, 1.0)), CANDLE)  # Gold trim.


## A coffin: dark velvet wood, a gold cross; open: the lid aside, a red lining.
static func draw_coffin(ci: CanvasItem, o: Vector2, r: float, flash: bool, open: bool) -> void:
	var box := Rect2(o + Vector2(-r * 0.6, -r * 1.2), Vector2(r * 1.2, r * 2.4))
	ci.draw_rect(Rect2(box.position + Vector2(3, 4), box.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(box.grow(1.0), INK)
	ci.draw_rect(box, Glyphs._c(Palette.COURT_VELVET_DARK, flash))
	if open:
		ci.draw_rect(box.grow(-2.0), Glyphs._c(Palette.COURT_BLOOD_DARK, flash))  # The red lining.
		ci.draw_rect(Rect2(box.position + Vector2(r * 0.9, -r * 0.2), box.size * Vector2(1.0, 0.9)), Glyphs._c(Palette.COURT_VELVET, flash))  # The lid, aside.
	else:
		ci.draw_rect(Rect2(o + Vector2(-1.0, -r * 0.8), Vector2(2.0, r * 1.2)), CANDLE)  # The cross.
		ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.45), Vector2(r * 0.6, 2.0)), CANDLE)


## A noble in mist: a few pale, drifting puffs (`t` game s drifts them).
static func draw_mist(ci: CanvasItem, r: float, t: float) -> void:
	for i in 5:
		var a := t * 1.7 + TAU * float(i) / 5.0
		var p := Vector2(cos(a) * r * 0.7, sin(a * 1.3) * r * 0.5 - r * 0.4)
		SpriteBank.draw_disc(ci, p, r * (0.45 + 0.1 * sin(t * 3.0 + float(i))), Color(Palette.COURT_MOON_LIGHT, 0.35))
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.4), r * 0.5, Color(Palette.COURT_BLOOD_LIGHT, 0.25))


# =====================================================================================
# Placeholder obstacles (the Act VII stubs)
# =====================================================================================

## Draws one of the Act VII stubs' placeholder obstacles. Returns false for any
## other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"moor_stone", "dead_tree", "castle_pillar":
			var r := o.radius
			var face := Palette.COURT_MOON_DARK
			var hi := Palette.COURT_MOON
			if o.kind == "dead_tree":
				face = Color(0.20, 0.16, 0.14)
				hi = Color(0.30, 0.25, 0.22)
			elif o.kind == "castle_pillar":
				face = Color(0.34, 0.30, 0.34)
				hi = Color(0.48, 0.44, 0.48)
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, face)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, hi)
			if o.kind == "castle_pillar":
				SpriteBank.draw_disc(ci, c, r * 0.22, Palette.COURT_BLOOD_DARK)  # A banner's knot.
		"gravestone", "hanging_charm", "banquet_table":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Color(0.40, 0.42, 0.46)
			var line := Palette.COURT_MOON_DARK
			if o.kind == "hanging_charm":
				face = Color(0.18, 0.15, 0.12)
				line = Palette.COURT_BLOOD
			elif o.kind == "banquet_table":
				face = Palette.COURT_VELVET_DARK
				line = CANDLE
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			var step := 12.0  # Seams / cords / candles (px).
			if rect.size.x >= rect.size.y:
				var x := rect.position.x + step
				while x < rect.end.x - 2.0:
					ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), Color(line, 0.7), 1.0)
					x += step
			else:
				var y := rect.position.y + step
				while y < rect.end.y - 2.0:
					ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Color(line, 0.7), 1.0)
					y += step
		_:
			return false
	return true


# =====================================================================================
# The shared rules' textures (visual only; made once, never headless)
# =====================================================================================

## Draws a thread `width` px wide from `a` to `b` in `color` on `ci` (local
## coordinates, under the draw transform `base`, e.g. unmirror_xf() on a
## mirrored enemy): the thread texture stretched along the line and turned to
## it (Bloodfeast's red threads, the noble's drain beam, the beast's lunge
## line). Leaves the draw transform at `base`.
static func draw_thread(ci: CanvasItem, a: Vector2, b: Vector2, width: float, color: Color, base: Transform2D = Transform2D.IDENTITY) -> void:
	var v := b - a
	var length_px := v.length()
	if length_px < 1.0 or color.a <= 0.01:
		return
	ci.draw_set_transform_matrix(base * Transform2D(v.angle(), a))  # Line space: x along the thread.
	ci.draw_texture_rect(thread_texture(), Rect2(Vector2(0.0, -width * 0.5), Vector2(length_px, width)), false, color)
	ci.draw_set_transform_matrix(base)


## The draw transform that undoes enemy `e`'s facing mirror (its node is
## mirrored by scale.x), so world-axis offsets from its centre draw true.
static func unmirror_xf(e: Enemy) -> Transform2D:
	return Transform2D(0.0, Vector2(e.scale.x, 1.0), 0.0, Vector2.ZERO)


## Draws a blood shield ring around a body of radius `r` (`fill` 0..1 of the
## cap: the ring brightens and thickens as it fills).
static func draw_blood_shield(ci: CanvasItem, r: float, fill: float) -> void:
	var k := clampf(fill, 0.0, 1.0)
	var s := r * (1.35 + 0.1 * k)  # Ring radius (px).
	ci.draw_texture_rect(ring_texture(), Rect2(Vector2(-s, -s - r * 0.3), Vector2(s, s) * 2.0), false, Color(Palette.COURT_BLOOD_LIGHT, 0.45 + 0.45 * k))


## The thread texture: 8 x 4 white, soft at the edges across its width
## (tinted when drawn). Made once.
static func thread_texture() -> Texture2D:
	if _thread_tex != null:
		return _thread_tex
	var img := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	var rows := [0.35, 1.0, 1.0, 0.35]  # Alpha of each row (soft edges).
	for y in 4:
		for x in 8:
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, rows[y]))
	_thread_tex = ImageTexture.create_from_image(img)
	return _thread_tex


## The shield ring texture: a white ring with soft edges (tinted when drawn).
## Made once.
static func ring_texture() -> Texture2D:
	if _ring_tex != null:
		return _ring_tex
	var n := TEX_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var h := float(n) * 0.5
	for y in n:
		for x in n:
			var dd := Vector2(float(x) + 0.5 - h, float(y) + 0.5 - h).length() / h
			var a := clampf(1.2 - absf(dd - 0.9) / 0.08, 0.0, 1.0)  # A thin band at 0.9 of the radius.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_ring_tex = ImageTexture.create_from_image(img)
	return _ring_tex
