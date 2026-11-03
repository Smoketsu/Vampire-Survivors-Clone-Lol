## ConcordGlyphs — code-drawn fallback shapes for THE CONCORD OF STARS (Act IX;
## GDD §15.0 "Act IX foundation (phase 1)"), drawn when a kind has no sprite
## art (assets/sprites/concord/<kind>.png, structures/concord_terraformer*.png):
## hull white and gunmetal, plasma green and laser magenta against starfield
## black, each race with its own accent (the Brood's chitin, the Vrask's teal,
## the Luminous's pale lumen; never the necromancer's violet and bone). Also:
##   * the Act IX stubs' placeholder obstacles (the capital's rubble and the
##     scout ship's torn hull plates, moon rocks and trophy racks, the Ark's
##     conduits and specimen tanks);
##   * the shared rules' looks, every one a texture drawn with
##     draw_texture_rect (batched; no polygon redrawn every frame: the Web GL
##     rule in CLAUDE.md): a terraformer pod's falling streak (draw_streak()),
##     a saucer's tractor cone (draw_tractor()) and the Final Harvest's eye
##     when its art is missing (draw_eye()).
## Every Concord kind without a shape of its own gets the grey drone. Purely
## visual.
class_name ConcordGlyphs
extends RefCounted

## Outline ink of the hull ramp (darkest, starfield black).
const INK := Palette.CONCORD_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Concord kind `kind`. Returns false when `kind` is not a Concord kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.concord_def(kind)  # Its design row ({} = not a Concord kind).
	if row.is_empty():
		return false
	# Phase 2: each Act IX stage's own fallbacks go here, before the shared
	# kinds' (as CourtGlyphs asks RavensmoorGlyphs first).
	# --- Act IX: the Proving Moon ---
	if kind == ProvingMoonEnemyData.WARBEAST:
		ProvingMoonGlyphs.draw_warbeast(ci, o, r, flash, false)
		return true
	match kind:
		"broodling":
			_broodling(ci, o, r, flash)
		"saucer":
			_saucer(ci, o, r, flash)
		"vrask_hunter":
			_hunter(ci, o, r, flash)
		"lumen_sentinel":
			_sentinel(ci, o, r, flash)
		"prism":
			_star_seer(ci, o, r, flash)
		"concord_terraformer":
			draw_pod(ci, o, r, flash)
		_:
			_grey(ci, o, r, flash)
	return true


## Broodling: a small green-black insect, claws forward, acid-green eyes.
static func _broodling(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.9, Glyphs._c(Palette.CONCORD_CHITIN, flash))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.2, -r * 0.3), r * 0.4, Glyphs._c(Palette.CONCORD_CHITIN_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 0.6), Vector2(r * 0.7, 1.5)), Glyphs._c(INK, flash))  # Claws.
	ci.draw_rect(Rect2(o + Vector2(r * 0.6, r * 0.3), Vector2(r * 0.7, 1.5)), Glyphs._c(INK, flash))
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 0.35), Vector2(2, 2)), Palette.CONCORD_PLASMA)  # Eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, r * 0.05), Vector2(2, 2)), Palette.CONCORD_PLASMA)


## Grey Drone: a small grey, a big black-eyed head, a silver suit, a glowing probe.
static func _grey(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.45, -r * 0.1), Vector2(r * 0.9, r * 1.1))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # Silver suit.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.55), r * 0.62, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.55), r * 0.55, Glyphs._c(Palette.CONCORD_HULL, flash))  # The big head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.65), Vector2(r * 0.3, r * 0.25)), INK)  # Black eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 0.65), Vector2(r * 0.3, r * 0.25)), INK)
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.8, r * 0.1), 2.5, Palette.CONCORD_PLASMA)  # The probe.


## Saucer: a white-hulled disc seen from above, a gunmetal ring, plasma lights.
static func _saucer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r, Glyphs._c(Palette.CONCORD_GUNMETAL, flash))
	SpriteBank.draw_disc(ci, o, r * 0.8, Glyphs._c(Palette.CONCORD_HULL, flash))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.1, -r * 0.1), r * 0.38, Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # The dome.
	for k in 6:
		var p := o + Vector2.from_angle(TAU * float(k) / 6.0) * r * 0.9
		SpriteBank.draw_disc(ci, p, 1.8, Palette.CONCORD_PLASMA)  # Lights round the rim.


## Vrask Hunter: a tall teal-scaled hunter, dark armour, a shoulder caster.
static func _hunter(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.8), Vector2(r * 1.1, r * 1.8))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CONCORD_GUNMETAL_DARK, flash))  # Dark armour.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.35), Vector2(r * 0.8, r * 0.6)), Glyphs._c(Palette.CONCORD_VRASK, flash))  # Scaled head.
	ci.draw_rect(Rect2(o + Vector2(r * 0.3, -r * 1.0), Vector2(r * 0.6, r * 0.3)), Glyphs._c(Palette.CONCORD_GUNMETAL, flash))  # Shoulder caster.
	ci.draw_rect(Rect2(o + Vector2(r * 0.85, -r * 0.95), Vector2(2, 2)), Palette.CITY_SIREN_RED)
	ci.draw_line(o + Vector2(-r * 0.9, r * 0.9), o + Vector2(-r * 0.9, -r * 1.2), Glyphs._c(Palette.CONCORD_HULL_SHADE, flash), 2.0)  # The glaive.


## Lumen Sentinel: a being of pale light in crystal armour, a beam staff.
static func _sentinel(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.3), r * 1.2, Color(Palette.CONCORD_LUMEN, 0.25))  # Its glow.
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.8), Vector2(r * 1.0, r * 1.8))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # Crystal armour.
	ci.draw_rect(body.grow(-2.0), Glyphs._c(Palette.CONCORD_LUMEN, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.15), r * 0.4, Glyphs._c(Palette.CONCORD_LUMEN, flash))  # Head of light.
	ci.draw_line(o + Vector2(r * 0.9, r * 0.9), o + Vector2(r * 0.9, -r * 1.4), Glyphs._c(Palette.CONCORD_HULL, flash), 2.0)  # The staff.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.9, -r * 1.4), 2.5, Palette.CONCORD_LASER)


## The Star-Seer: a figure in an opaque white-and-magenta gown, white-gold
## hair, a floating prism (drawn by her kit).
static func _star_seer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var skirt := Rect2(o + Vector2(-r * 0.75, -r * 0.1), Vector2(r * 1.5, r * 1.2))
	ci.draw_rect(skirt.grow(1.0), INK)
	ci.draw_rect(skirt, Glyphs._c(Palette.CONCORD_HULL, flash))  # The gown (fully covering).
	ci.draw_rect(Rect2(skirt.position + Vector2(0.0, skirt.size.y - 2.0), Vector2(skirt.size.x, 2.0)), Palette.CONCORD_LASER)  # Magenta hem.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.38, -r * 0.95), Vector2(r * 0.76, r * 0.9)), Glyphs._c(Palette.CONCORD_HULL_SHADE, flash))  # High-necked bodice.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 1.5), Vector2(r * 0.6, r * 0.55)), Glyphs._c(Color(0.80, 0.74, 0.90), flash))  # Pale lavender face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.65), Vector2(r * 0.9, r * 0.3)), Glyphs._c(Palette.CONCORD_LUMEN, flash))  # White-gold hair.


## A landing pod (also its fallback as a structure): a hull-white capsule
## rooted in turf, green vents.
static func draw_pod(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.5), r * 1.2, Color(Palette.CONCORD_TURF, 0.8))  # Its turf.
	var shell := Rect2(o + Vector2(-r * 0.6, -r * 1.1), Vector2(r * 1.2, r * 1.8))
	ci.draw_rect(shell.grow(1.0), INK)
	ci.draw_rect(shell, Glyphs._c(Palette.CONCORD_HULL, flash))
	ci.draw_rect(Rect2(shell.position + Vector2(0.0, r * 0.6), Vector2(shell.size.x, 3.0)), Glyphs._c(Palette.CONCORD_GUNMETAL, flash))  # A band.
	for k in 3:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.45 + float(k) * r * 0.35, r * 0.3), Vector2(2, 3)), Palette.CONCORD_PLASMA)  # Vents.


# =====================================================================================
# Placeholder obstacles (the Act IX stubs)
# =====================================================================================

## Draws one of the Act IX stubs' placeholder obstacles. Returns false for any
## other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"concord_rubble", "concord_moonrock", "concord_conduit":
			var r := o.radius
			var face := Color(0.30, 0.30, 0.33)  # Broken stone.
			var hi := Color(0.42, 0.42, 0.45)
			if o.kind == "concord_moonrock":
				face = Color(0.34, 0.35, 0.38)
				hi = Color(0.50, 0.51, 0.54)
			elif o.kind == "concord_conduit":
				face = Palette.CONCORD_GUNMETAL
				hi = Palette.CONCORD_HULL_SHADE
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, face)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, hi)
			if o.kind == "concord_conduit":
				SpriteBank.draw_disc(ci, c, r * 0.3, Palette.CONCORD_PLASMA)  # A live conduit.
		"concord_hull_plate", "concord_trophy_rack", "concord_specimen_tank":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Palette.CONCORD_HULL_SHADE  # Torn hull.
			var line := Palette.CONCORD_GUNMETAL
			if o.kind == "concord_trophy_rack":
				face = Palette.CONCORD_GUNMETAL_DARK
				line = Palette.CONCORD_HIVE_BONE  # Hung skulls and bones.
			elif o.kind == "concord_specimen_tank":
				face = Color(0.12, 0.28, 0.20)
				line = Palette.CONCORD_PLASMA
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			var step := 10.0  # Seams / trophies / tank ribs (px).
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
# The shared rules' looks (visual only; textures)
# =====================================================================================

## A terraformer pod's falling streak from `top` to its landing point `at`
## (`k` 0 announced .. 1 landing): a plasma trail and the pod's glow, and a
## green circle where it lands.
static func draw_streak(ci: CanvasItem, top: Vector2, at: Vector2, k: float) -> void:
	var tail := top.lerp(at, maxf(0.0, k - 0.25))  # The trail's end behind the pod.
	_stretch(ci, tail, top.lerp(at, k), 6.0, Color(Palette.CONCORD_PLASMA, 0.55), Transform2D.IDENTITY)
	SpriteBank.draw_disc(ci, top.lerp(at, k), 6.0, Color(Palette.CONCORD_HULL, 0.95))
	SpriteBank.draw_disc(ci, at, 22.0 * (0.4 + 0.6 * k), Color(Palette.CONCORD_PLASMA_DARK, 0.25 + 0.25 * k))


## A saucer's tractor cone from its hull at `a` down to the summon's foot `b`
## (`ci` local coordinates under the draw transform `base`): a wide soft band
## narrowing to the foot (two stretched layers) and a pulsing spot on the
## ground. `half` px half width at the foot; `k` 0..1 its strength. Leaves the
## draw transform at `base`.
static func draw_tractor(ci: CanvasItem, a: Vector2, b: Vector2, half: float, k: float, t: float, base: Transform2D = Transform2D.IDENTITY) -> void:
	var pulse := 0.8 + 0.2 * sin(t * 8.0)
	_stretch(ci, a, b, half * 2.0, Color(Palette.CONCORD_PLASMA, 0.18 * k * pulse), base)
	_stretch(ci, a, b, half, Color(Palette.CONCORD_PLASMA, 0.35 * k * pulse), base)
	ci.draw_set_transform_matrix(base)
	SpriteBank.draw_disc(ci, b, half * (0.6 + 0.4 * k), Color(Palette.CONCORD_PLASMA_DARK, 0.4 * k))


## The Final Harvest's eye when its art is missing: an almond of hull white with
## a laser-magenta iris, opening (`open` 0..1) over the view at `at`, `w` px
## wide, at opacity `alpha` (textures only).
static func draw_eye(ci: CanvasItem, at: Vector2, w: float, open: float, alpha: float, t: float) -> void:
	var h := w * 0.32 * open  # The lids part as it opens.
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(w * 0.55, h * 0.75), Vector2(w * 1.1, h * 1.5)), false, Color(Palette.CONCORD_INK, alpha))
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), false, Color(Palette.CONCORD_HULL_SHADE, alpha))
	var iris := h * 0.9  # Iris diameter (px).
	var look := Vector2(sin(t * 0.4) * w * 0.12, 0.0)  # It searches the world below.
	SpriteBank.draw_disc(ci, at + look, iris * 0.5, Color(Palette.CONCORD_LASER, alpha))
	SpriteBank.draw_disc(ci, at + look, iris * 0.22, Color(Palette.CONCORD_INK, alpha))


## A soft line texture stretched from `a` to `b`, `w` px across, tinted `col`,
## under the draw transform `base` (left there).
static func _stretch(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color, base: Transform2D) -> void:
	var v := b - a
	var length_px := v.length()
	if length_px < 1.0 or col.a <= 0.01:
		return
	ci.draw_set_transform_matrix(base * Transform2D(v.angle(), a))
	ci.draw_texture_rect(ConcordBeams.line_texture(), Rect2(Vector2(0.0, -w * 0.5), Vector2(length_px, w)), false, col)
	ci.draw_set_transform_matrix(base)
