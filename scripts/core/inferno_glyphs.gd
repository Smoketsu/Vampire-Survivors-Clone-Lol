## InfernoGlyphs — code-drawn fallback shapes for THE INFERNO (Act VI; GDD §15.0
## "Act VI foundation (phase 1)"), drawn when a kind has no sprite art
## (assets/sprites/inferno/<kind>.png): obsidian, ash, lava orange and
## crimson-violet demon skin, charm pink, obsidian-ink outlines (the obsidian,
## lava, demon and charm ramps, never the undead's bone and soul teal). Also:
##   * the Act VI stubs' placeholder obstacles (obsidian rocks, bone cages,
##     marble columns, velvet divans, obsidian spires and walls);
##   * the shared rules' textures, made once in code (never loaded headless):
##     the Hell Pit's lava pool and its glowing rim (draw_pit(), draw_pit_rim()),
##     the charm heart (draw_heart()), and the Adversary's claw (draw_hand()).
##     Every one is a texture drawn with draw_texture_rect (batched; no polygon
##     redrawn every frame: the Web GL rule in CLAUDE.md).
## Every Inferno kind without a shape of its own gets the plain damned. Purely
## visual.
class_name InfernoGlyphs
extends RefCounted

## Outline ink of the obsidian ramp (darkest).
const INK := Color(0.043, 0.039, 0.063)
## Ash grey (the damned's skin, the ash plain).
const ASH := Color(0.55, 0.53, 0.55)
## Iron (chains, the imp's pitchfork, the knight's blade core).
const IRON := Color(0.42, 0.42, 0.46)
## Side (px) of the made pit / rim textures.
const TEX_SIZE: int = 64

## The lava-pool texture (made on first use).
static var _pit_tex: Texture2D = null
## The glowing-rim texture (made on first use).
static var _rim_tex: Texture2D = null
## The heart texture (made on first use).
static var _heart_tex: Texture2D = null


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Inferno kind `kind`. Returns false when `kind` is not an Inferno kind
## (Glyphs.draw_enemy() then asks the Ancient Eye's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.inferno_def(kind)  # Its design row ({} = not an Inferno kind).
	if row.is_empty():
		return false
	# --- Act VI: the Burning Gate ---
	if BurningGateGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # The Hellhound, the Pit Cultist, the Gatekeeper.
	if SilkPalaceGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # --- Act VI: the Palace of Silk and Ash --- (the Lilim Witch, the Twin Succubi)
	match kind:
		"imp":
			_imp(ci, o, r, flash)
		"hell_knight":
			_hell_knight(ci, o, r, flash)
		"succubus":
			_succubus(ci, o, r, flash)
		"demon_brute":
			_brute(ci, o, r, flash)
		"demon_portal":
			_portal(ci, o, r, flash)
		_:
			_damned(ci, o, r, flash)
	return true


## The Damned: a wailing grey soul in chains.
static func _damned(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.3), Vector2(r * 1.0, r * 1.3))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(ASH, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.0), Vector2(r * 0.8, r * 0.7)), Glyphs._c(ASH.lightened(0.15), flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 0.65), Vector2(r * 0.3, r * 0.3)), INK)  # The wailing mouth.
	ci.draw_line(o + Vector2(-r * 0.6, r * 0.3), o + Vector2(r * 0.6, r * 0.5), Glyphs._c(IRON, flash), 2.0)  # Chains.
	ci.draw_line(o + Vector2(-r * 0.6, r * 0.6), o + Vector2(r * 0.6, r * 0.2), Glyphs._c(IRON, flash), 2.0)


## An Imp: a small winged red demon with a pitchfork.
static func _imp(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var lift := Vector2(0.0, -r * 0.6)  # It hovers.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.9), r * 0.7, Color(0, 0, 0, 0.3))
	var c := o + lift
	ci.draw_line(c + Vector2(-r * 0.4, -r * 0.2), c + Vector2(-r * 1.4, -r * 0.9), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 3.0)  # Wings.
	ci.draw_line(c + Vector2(r * 0.4, -r * 0.2), c + Vector2(r * 1.4, -r * 0.9), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 3.0)
	ci.draw_rect(Rect2(c - Vector2(r * 0.6, r * 0.6), Vector2(r * 1.2, r * 1.3)).grow(1.0), INK)
	ci.draw_rect(Rect2(c - Vector2(r * 0.6, r * 0.6), Vector2(r * 1.2, r * 1.3)), Glyphs._c(Palette.INFERNO_DEMON, flash))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.35, -r * 0.35), Vector2(r * 0.25, r * 0.2)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # Eyes.
	ci.draw_rect(Rect2(c + Vector2(r * 0.1, -r * 0.35), Vector2(r * 0.25, r * 0.2)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))
	ci.draw_line(c + Vector2(r * 0.9, r * 0.9), c + Vector2(r * 0.9, -r * 1.3), Glyphs._c(IRON, flash), 1.5)  # Pitchfork.
	ci.draw_line(c + Vector2(r * 0.6, -r * 1.3), c + Vector2(r * 1.2, -r * 1.3), Glyphs._c(IRON, flash), 1.5)


## A Hell Knight: obsidian plate with ember cracks, a burning greatsword.
static func _hell_knight(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.4), Vector2(r * 1.2, r * 1.4))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.INFERNO_OBSIDIAN, flash))
	ci.draw_line(body.position + Vector2(r * 0.2, r * 0.2), body.position + Vector2(r * 0.6, r * 0.9), Glyphs._c(Palette.INFERNO_LAVA, flash), 1.0)  # Ember cracks.
	ci.draw_line(body.position + Vector2(r * 0.9, r * 0.3), body.position + Vector2(r * 0.7, r * 1.1), Glyphs._c(Palette.INFERNO_LAVA, flash), 1.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.1), Vector2(r * 0.9, r * 0.75)).grow(1.0), INK)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.1), Vector2(r * 0.9, r * 0.75)), Glyphs._c(Palette.INFERNO_OBSIDIAN_DARK, flash))  # Helm.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.8), Vector2(r * 0.6, r * 0.12)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # The visor's glow.
	ci.draw_line(o + Vector2(r * 0.7, r * 0.8), o + Vector2(r * 1.2, -r * 1.6), Glyphs._c(Palette.INFERNO_LAVA, flash), 4.0)  # The burning blade.
	ci.draw_line(o + Vector2(r * 0.72, r * 0.6), o + Vector2(r * 1.15, -r * 1.4), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash), 1.5)


## A Succubus: crimson-violet skin, bat wings, horns, a charm-pink corset (the
## sprite carries the figure; the glyph is only a readable placeholder).
static func _succubus(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var lift := Vector2(0.0, -r * 0.5)  # She hovers.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 1.0), r * 0.7, Color(0, 0, 0, 0.3))
	var c := o + lift
	ci.draw_line(c + Vector2(-r * 0.4, -r * 0.3), c + Vector2(-r * 1.7, -r * 1.2), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 4.0)  # Bat wings.
	ci.draw_line(c + Vector2(r * 0.4, -r * 0.3), c + Vector2(r * 1.7, -r * 1.2), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 4.0)
	var body := Rect2(c + Vector2(-r * 0.4, -r * 0.4), Vector2(r * 0.8, r * 1.5))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.INFERNO_DEMON_LIGHT, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0, r * 0.25), Vector2(body.size.x, r * 0.55)), Glyphs._c(Palette.INFERNO_CHARM, flash))  # Corset.
	ci.draw_rect(Rect2(c + Vector2(-r * 0.35, -r * 1.05), Vector2(r * 0.7, r * 0.65)), Glyphs._c(Palette.INFERNO_DEMON_LIGHT, flash))  # Head.
	ci.draw_line(c + Vector2(-r * 0.3, -r * 1.05), c + Vector2(-r * 0.5, -r * 1.45), Glyphs._c(INK, flash), 2.0)  # Horns.
	ci.draw_line(c + Vector2(r * 0.3, -r * 1.05), c + Vector2(r * 0.5, -r * 1.45), Glyphs._c(INK, flash), 2.0)
	ci.draw_line(c + Vector2(0, r * 1.1), c + Vector2(r * 0.8, r * 1.4), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 1.5)  # Tail.


## A Demon Brute: a hulking four-armed demon with horns.
static func _brute(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.7, -r * 0.55), Vector2(r * 1.4, r * 1.45))
	ci.draw_rect(body.grow(1.5), INK)
	ci.draw_rect(body, Glyphs._c(Palette.INFERNO_DEMON, flash))
	for k in 2:
		var y := r * (-0.3 + 0.45 * float(k))  # Two pairs of arms.
		ci.draw_line(o + Vector2(-r * 0.7, y), o + Vector2(-r * 1.25, y + r * 0.35), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 5.0)
		ci.draw_line(o + Vector2(r * 0.7, y), o + Vector2(r * 1.25, y + r * 0.35), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash), 5.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.05), Vector2(r * 0.8, r * 0.6)), Glyphs._c(Palette.INFERNO_DEMON_DARK, flash))  # Head.
	ci.draw_line(o + Vector2(-r * 0.3, -r * 1.05), o + Vector2(-r * 0.6, -r * 1.5), Glyphs._c(Palette.BONE, flash), 3.0)  # Horns.
	ci.draw_line(o + Vector2(r * 0.3, -r * 1.05), o + Vector2(r * 0.6, -r * 1.5), Glyphs._c(Palette.BONE, flash), 3.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.28, -r * 0.85), Vector2(r * 0.56, r * 0.12)), Glyphs._c(Palette.INFERNO_LAVA_LIGHT, flash))  # Eyes.


## The demon portal: a ring of obsidian and lava with a charm-pink swirl.
static func _portal(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.15, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r, Glyphs._c(Palette.INFERNO_OBSIDIAN, flash))
	SpriteBank.draw_disc(ci, o, r * 0.78, Glyphs._c(Palette.INFERNO_LAVA, flash))
	SpriteBank.draw_disc(ci, o, r * 0.62, Glyphs._c(Palette.INFERNO_DEMON_DARK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.38, Glyphs._c(Palette.INFERNO_CHARM, flash))
	SpriteBank.draw_disc(ci, o, r * 0.16, Glyphs._c(Palette.INFERNO_CHARM_LIGHT, flash))


# =====================================================================================
# Placeholder obstacles (the Act VI stubs)
# =====================================================================================

## Draws one of the Act VI stubs' placeholder obstacles. Returns false for any
## other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"obsidian_rock", "obsidian_spire", "marble_column":
			var r := o.radius
			var face := Palette.INFERNO_OBSIDIAN if o.kind != "marble_column" else Color(0.80, 0.77, 0.80)
			var hi := Palette.INFERNO_OBSIDIAN_LIGHT if o.kind != "marble_column" else Color(0.95, 0.93, 0.95)
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, face)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, hi)
			if o.kind == "obsidian_spire":
				SpriteBank.draw_disc(ci, c, r * 0.25, Palette.INFERNO_LAVA)  # A molten core.
		"bone_cage", "velvet_divan", "obsidian_wall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Palette.INFERNO_OBSIDIAN_DARK
			var line := Palette.INFERNO_LAVA_DARK
			if o.kind == "bone_cage":
				face = Color(0.20, 0.17, 0.15)
				line = Palette.BONE
			elif o.kind == "velvet_divan":
				face = Palette.INFERNO_DEMON_DARK
				line = Palette.INFERNO_CHARM
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			var step := 10.0  # Bars / seams (px).
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

## Draws a burning Hell Pit at `c` of radius `r` with alpha `a` (cooling fades
## it); `t` (game s) pulses its glow.
static func draw_pit(ci: CanvasItem, c: Vector2, r: float, a: float, t: float) -> void:
	if a <= 0.01:
		return
	var pulse := 0.5 + 0.5 * sin(t * 2.4)  # 0..1.
	ci.draw_texture_rect(pit_texture(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 1.0, 1.0, InfernoRulesData.PIT_ALPHA * a))
	SpriteBank.draw_disc(ci, c, r * (0.55 + 0.1 * pulse), Color(Palette.INFERNO_LAVA_LIGHT, InfernoRulesData.PIT_GLOW_ALPHA * a * (0.6 + 0.4 * pulse)))


## Draws a pit's glowing rim while it telegraphs: `k` 0 (just appeared) .. 1
## (about to burn) brightens it and fills its centre with a dull glow.
static func draw_pit_rim(ci: CanvasItem, c: Vector2, r: float, k: float, t: float) -> void:
	var blink := 0.75 + 0.25 * sin(t * (10.0 + 10.0 * k))  # Quickens as it opens.
	SpriteBank.draw_disc(ci, c, r * 0.9, Color(Palette.INFERNO_LAVA_DARK, 0.2 + 0.4 * k))
	ci.draw_texture_rect(rim_texture(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.INFERNO_LAVA_LIGHT, (0.6 + 0.4 * k) * blink))


## Draws a charm heart of half-size `s` px centred on `p` in `color`.
static func draw_heart(ci: CanvasItem, p: Vector2, s: float, color: Color) -> void:
	ci.draw_texture_rect(heart_texture(), Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), false, color)


## Draws the Adversary's claw reaching up at `at` (grab radius `r` px); `k` 1
## (fresh) .. 0 (gone) fades and lowers it.
static func draw_hand(ci: CanvasItem, at: Vector2, r: float, k: float) -> void:
	var col := Color(Palette.INFERNO_OBSIDIAN_DARK, k)
	var glow := Color(Palette.INFERNO_LAVA, k * 0.8)
	var rise := r * 0.9 * k  # How high the fingers reach (px).
	SpriteBank.draw_disc(ci, at, r * 0.55, Color(Palette.INFERNO_LAVA_DARK, 0.5 * k))
	for i in 4:
		var x := (float(i) - 1.5) * r * 0.28
		var base := at + Vector2(x, 0.0)
		var tip := base + Vector2(x * 0.4, -rise)
		ci.draw_line(base, tip, Color(INK, k), 7.0)
		ci.draw_line(base, tip, col, 5.0)
		ci.draw_line(tip, tip + Vector2(-x * 0.3, r * 0.15), glow, 2.0)  # The claw tip.
	ci.draw_line(at + Vector2(-r * 0.55, r * 0.05), at + Vector2(-r * 0.75, -rise * 0.5), col, 5.0)  # The thumb.


## The lava-pool texture: an obsidian crust at the rim, lava inside, a white-hot
## core, a few cooler crusted spots (a fixed hash pattern). Made once.
static func pit_texture() -> Texture2D:
	if _pit_tex != null:
		return _pit_tex
	var n := TEX_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var h := float(n) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(float(x) + 0.5 - h, float(y) + 0.5 - h).length() / h  # 0 centre .. 1 rim.
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col: Color
			if d > 0.86:
				col = Palette.INFERNO_OBSIDIAN_DARK  # The crust.
			elif d > 0.74:
				col = Palette.INFERNO_LAVA_DARK
			elif d > 0.38:
				col = Palette.INFERNO_LAVA
			else:
				col = Palette.INFERNO_LAVA_LIGHT
			var spot := ((x * 73 + y * 151) ^ (x * y * 29)) % 23  # A fixed speckle.
			if d < 0.74 and spot == 0:
				col = Palette.INFERNO_LAVA_DARK  # A crusted spot.
			img.set_pixel(x, y, col)
	_pit_tex = ImageTexture.create_from_image(img)
	return _pit_tex


## The glowing-rim texture: a white ring (tinted when drawn) with soft edges.
## Made once.
static func rim_texture() -> Texture2D:
	if _rim_tex != null:
		return _rim_tex
	var n := TEX_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var h := float(n) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(float(x) + 0.5 - h, float(y) + 0.5 - h).length() / h
			var a := clampf(1.3 - absf(d - 0.88) / 0.12, 0.0, 1.0)  # A solid band around 0.88 of the radius, soft edges.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_rim_tex = ImageTexture.create_from_image(img)
	return _rim_tex


## The heart texture: a 7 x 6 pixel heart (white, tinted when drawn). Made once.
static func heart_texture() -> Texture2D:
	if _heart_tex != null:
		return _heart_tex
	var rows := [".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]  # The heart, top to bottom.
	var img := Image.create(7, 6, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			img.set_pixel(x, y, Color(1, 1, 1, 1) if row[x] == "X" else Color(0, 0, 0, 0))
	_heart_tex = ImageTexture.create_from_image(img)
	return _heart_tex
