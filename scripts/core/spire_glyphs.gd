## SpireGlyphs — code-drawn shapes of Ul-Thalos, the Risen Spire (Act II,
## Stage 6): the fallback glyphs of its kinds and summons when their sprite
## art is missing, and the overlays and telegraphs that are always code-drawn
## (the song's notes, the tentacle grip, the Ascension pillar, the slam lane,
## the gaze, the binding of the finale). Every Eye telegraph uses the Eye's
## bioluminescence (Palette.EYE_BIOLUME: magenta-leaning, never gold and never
## the player's violet). EyeGlyphs.draw_enemy() and SummonGlyphs.draw_summon()
## delegate to it. Purely visual.
class_name SpireGlyphs
extends RefCounted

## Wet green stone of the drowned city.
const STONE := Color(0.20, 0.30, 0.27)
## Barnacle crust and foam.
const BARNACLE := Color(0.50, 0.71, 0.67)
## Necrotic green of the necromancer's bound dead (the finale, his Thralls).
const BOUND := Color(0.42, 0.95, 0.55)
## Bioluminescent flesh in shadow (tools/palette.json biolume_dark #5A2262).
const BIOLUME_DARK := Color(0.353, 0.133, 0.384)
## Tint of a Tidecaller's Host Spawn over the Spawn of the Deep's art (a
## drowned, sea-green wash, so the spell's Spawns read apart from the class's).
const HOST_TINT := Color(0.62, 0.95, 0.88)


# =====================================================================================
# Enemies (fallbacks: the sprite art lands in assets/sprites/eye/)
# =====================================================================================

## Draws Ul-Thalos kind `kind` at `o`; false for a kind it does not know.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"eye_siren":
			_siren(ci, o, r, flash)
		"eye_spawn":
			_spawn(ci, o, r, flash, Palette.EYE_DROWNED)
		"eye_hierophant":
			_hierophant(ci, o, r, flash)
		"dream_pillar":
			_pillar(ci, o, r, flash)
		"vhalneth_arm":
			_arm(ci, o, r, flash)
		"eye_waking_horror":
			_spawn(ci, o, r, flash, BIOLUME_DARK)
			ci.draw_circle(o + Vector2(0, -r * 0.3), r * 0.25, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
		_:
			return false
	return true


## The Siren: an hourglass robe of drowned teal, long hair streaming like
## kelp, a pale face and a bioluminescent jewel (fully clothed).
static func _siren(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var gown := PackedVector2Array([o + Vector2(-r * 0.95, r * 1.0), o + Vector2(r * 0.95, r * 1.0), o + Vector2(r * 0.35, r * 0.1),
		o + Vector2(r * 0.55, -r * 0.45), o + Vector2(-r * 0.55, -r * 0.45), o + Vector2(-r * 0.35, r * 0.1)])  # An hourglass gown.
	ci.draw_colored_polygon(gown, Glyphs._c(Palette.EYE_DROWNED, flash))
	ci.draw_polyline(gown + PackedVector2Array([gown[0]]), Glyphs.OUTLINE, 1.0)
	ci.draw_circle(o + Vector2(-r * 0.25, -r * 0.55), r * 0.38, Glyphs._c(Palette.EYE_DROWNED_DARK, flash))  # Hair.
	ci.draw_circle(o + Vector2(r * 0.05, -r * 0.7), r * 0.32, Glyphs._c(Palette.BONE, flash))  # Face.
	ci.draw_line(o + Vector2(-r * 0.5, -r * 0.6), o + Vector2(-r * 0.9, r * 0.4), Glyphs._c(Palette.EYE_DROWNED_DARK, flash), 2.0)
	ci.draw_circle(o + Vector2(0, -r * 0.15), r * 0.14, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))  # Jewel.


## A Spawn of the Deep: a barnacled shell, a crown of tentacles, one eye.
static func _spawn(ci: CanvasItem, o: Vector2, r: float, flash: bool, body: Color) -> void:
	for i in 6:
		var a := PI * 0.15 + PI * 0.7 * float(i) / 5.0
		var tip := o + Vector2.from_angle(a) * r * 1.35
		ci.draw_line(o + Vector2.from_angle(a) * r * 0.5, tip, Glyphs._c(Palette.EYE_DROWNED_DARK, flash), 3.0)
	ci.draw_circle(o, r, Glyphs.OUTLINE)
	ci.draw_circle(o, r * 0.9, Glyphs._c(body, flash))
	ci.draw_circle(o + Vector2(-r * 0.25, -r * 0.3), r * 0.4, Glyphs._c(body.lightened(0.2), flash))
	for i in 5:
		ci.draw_circle(o + Vector2.from_angle(TAU * float(i) / 5.0 + 0.4) * r * 0.6, 2.0, Glyphs._c(BARNACLE, flash))
	ci.draw_circle(o + Vector2(r * 0.2, -r * 0.1), r * 0.22, Glyphs._c(Palette.EYE_BIOLUME, flash))


## A Hierophant: a tall mitre of the Eye over a dark robe, a staff with the
## Eye's sigil.
static func _hierophant(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	EyeGlyphs._cultist(ci, o, r, flash)
	var mitre := PackedVector2Array([o + Vector2(-r * 0.4, -r * 0.95), o + Vector2(r * 0.4, -r * 0.95), o + Vector2(0, -r * 1.8)])
	ci.draw_colored_polygon(mitre, Glyphs._c(Palette.EYE_DROWNED_DARK, flash))
	ci.draw_circle(o + Vector2(0, -r * 1.25), r * 0.14, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
	var top := o + Vector2(r * 1.1, -r * 1.7)
	ci.draw_line(o + Vector2(r * 1.0, r * 0.8), top, Glyphs._c(Palette.BONE, flash), 2.0)
	ci.draw_arc(top, r * 0.35, 0.0, TAU, 12, Glyphs._c(Palette.EYE_BIOLUME, flash), 2.0)


## A dream pillar: a cyclopean obelisk with a glowing eye-glyph.
static func _pillar(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := PackedVector2Array([o + Vector2(-r * 0.8, r), o + Vector2(r * 0.8, r), o + Vector2(r * 0.55, -r * 2.6),
		o + Vector2(0, -r * 3.1), o + Vector2(-r * 0.6, -r * 2.5)])
	ci.draw_colored_polygon(body, Glyphs._c(STONE, flash))
	ci.draw_polyline(body + PackedVector2Array([body[0]]), Glyphs.OUTLINE, 1.5)
	ci.draw_circle(o + Vector2(0, -r * 1.5), r * 0.35, Glyphs._c(Palette.EYE_BIOLUME, flash))
	ci.draw_circle(o + Vector2(0, -r * 1.5), r * 0.15, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))


## One of Vhal'Neth's arms rearing out of the surf: a tapering tentacle with
## suckers, its root in a ring of foam.
static func _arm(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_arc(o + Vector2(0, r * 0.6), r * 1.2, 0.0, TAU, 20, Color(BARNACLE, 0.6), 2.0)
	var pts := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		pts.append(o + Vector2(sin(t * 3.2) * r * 0.5, r * 0.6 - t * r * 5.0))
	for i in pts.size() - 1:
		var w := r * 1.1 * (1.0 - float(i) / float(pts.size()))
		ci.draw_line(pts[i], pts[i + 1], Glyphs.OUTLINE, w + 2.0)
		ci.draw_line(pts[i], pts[i + 1], Glyphs._c(Palette.EYE_DROWNED, flash), w)
	for i in range(1, 7, 2):
		ci.draw_circle(pts[i] + Vector2(r * 0.25, 0), 2.0, Glyphs._c(Palette.EYE_BIOLUME, flash))


# =====================================================================================
# Vhal'Neth's face
# =====================================================================================

## Draws Vhal'Neth's face at `o` (radius `r`): `look` 0 dreaming under the
## water (eyes shut), 1 eyes open (Stirring), 2 risen (Waking); `rise` 0..1
## while she surfaces on arrival. Her sprite art (bosses/vhalneth_dreaming,
## bosses/vhalneth, bosses/vhalneth_waking) wins when it exists.
static func draw_vhalneth(ci: CanvasItem, o: Vector2, r: float, flash: bool, look: int, rise: float, now: float) -> void:
	var key := "bosses/vhalneth_dreaming" if look == 0 else ("bosses/vhalneth_waking" if look == 2 else "bosses/vhalneth")
	if not SpriteBank.has(key):
		key = "bosses/vhalneth"
	var tint := Color(0.55, 0.80, 0.82, 0.55) if look == 0 else Color.WHITE  # Under the water: dim, sea-tinted, see-through.
	if rise < 1.0 and SpriteBank.draw_rising(ci, key, o, rise, false, tint):
		return
	if rise >= 1.0 and SpriteBank.draw(ci, key, o, flash, tint):
		return
	_face(ci, o, r * maxf(0.3, rise), flash, look, now, tint.a)


## The code face: a vast pale-teal oval crowned with tendrils like hair, the
## two great eyes shut or open and glowing, a still mouth.
static func _face(ci: CanvasItem, o: Vector2, r: float, flash: bool, look: int, now: float, alpha: float) -> void:
	var skin := Color(Glyphs._c(Color(0.45, 0.62, 0.60), flash), alpha)
	var dark := Color(Palette.EYE_DROWNED_DARK, alpha)
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		var sway := sin(now * 1.3 + float(i)) * 0.12
		ci.draw_line(o + Vector2.from_angle(a) * r * 0.8, o + Vector2.from_angle(a + sway) * r * 1.6, dark, 5.0)
	ci.draw_set_transform(o, 0.0, Vector2(0.8, 1.0))
	ci.draw_circle(Vector2.ZERO, r * 1.02, Color(0, 0, 0, 0.5 * alpha))
	ci.draw_circle(Vector2.ZERO, r, skin)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for side in [-1.0, 1.0]:
		var eye := o + Vector2(float(side) * r * 0.32, -r * 0.12)
		if look == 0:
			ci.draw_line(eye - Vector2(r * 0.16, 0), eye + Vector2(r * 0.16, 0), dark, 2.0)
		else:
			ci.draw_set_transform(eye, 0.0, Vector2(1.0, 0.55))
			ci.draw_circle(Vector2.ZERO, r * 0.17, Color(Palette.EYE_BIOLUME_GLOW, alpha))
			ci.draw_circle(Vector2.ZERO, r * 0.07, Color(Palette.EYE_DROWNED_DARK, alpha))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mouth := r * (0.18 if look == 2 else 0.08)
	ci.draw_set_transform(o + Vector2(0, r * 0.42), 0.0, Vector2(1.0, 0.5))
	ci.draw_circle(Vector2.ZERO, mouth + r * 0.1, dark)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# =====================================================================================
# Summons (fallbacks: the sprite art lands in assets/sprites/summons/)
# =====================================================================================

## Draws Ul-Thalos summon glyph `kind` (the Spawn of the Deep class, its
## evolution, the necromancer's Drowned Thralls); false when unknown.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"spawn_of_the_deep":
			_spawn(ci, o, r, flash, Color(0.30, 0.50, 0.46))
			ci.draw_circle(o + Vector2(r * 0.2, -r * 0.1), r * 0.12, Glyphs._c(BOUND, flash))  # Its eye burns with the necromancer's green.
		"leviathan":
			_spawn(ci, o, r * 1.1, flash, Color(0.24, 0.42, 0.40))
			ci.draw_arc(o, r * 1.3, PI * 1.1, PI * 1.9, 12, Glyphs._c(Palette.BONE, flash), 2.0)  # A crown of bone spines.
			ci.draw_circle(o + Vector2(r * 0.2, -r * 0.1), r * 0.14, Glyphs._c(BOUND, flash))
		"tide_spawn":
			# A Tidecaller's Host Spawn: the class's art, drowned-tinted.
			if not SpriteBank.draw(ci, "summons/spawn_of_the_deep", o, flash, HOST_TINT):
				_spawn(ci, o, r, flash, Color(0.36, 0.62, 0.58))
		"drowned_thrall_ally":
			EyeGlyphs._cultist(ci, o, r, flash)
			ci.draw_circle(o + Vector2(0, -r * 0.82), r * 0.16, Glyphs._c(BOUND, flash))  # The necromancer's green in its eye.
		_:
			return false
	return true


# =====================================================================================
# Overlays and telegraphs (always code-drawn)
# =====================================================================================

## Over a compelled summon: notes when lured, a tentacle coil when held.
static func draw_compelled(ci: CanvasItem, r: float, lured: bool) -> void:
	if lured:
		draw_notes(ci, Vector2(0, -r * 2.0), 0.4)
	else:
		ci.draw_arc(Vector2.ZERO, r * 1.15, 0.0, TAU, 16, Color(Palette.EYE_DROWNED, 0.9), 3.0)
		ci.draw_arc(Vector2.ZERO, r * 1.15, 0.2, 1.4, 6, Color(BARNACLE, 0.9), 2.0)


## A cluster of rising biolume notes at `o` (`t` s into the song).
static func draw_notes(ci: CanvasItem, o: Vector2, t: float) -> void:
	for i in 3:
		var lift := fmod(t * 14.0 + float(i) * 7.0, 20.0)
		var p := o + Vector2(float(i - 1) * 6.0, -lift)
		var a := clampf(1.0 - lift / 20.0, 0.0, 1.0)
		ci.draw_circle(p, 2.5, Color(Palette.EYE_BIOLUME_GLOW, a))
		ci.draw_line(p + Vector2(2.0, 0.0), p + Vector2(2.0, -7.0), Color(Palette.EYE_BIOLUME_GLOW, a), 1.0)


## A tentacle from `from` to `to` (local px), `w` px thick at its root;
## `reaching` draws its tip open, else coiled around the end.
static func draw_tentacle(ci: CanvasItem, from: Vector2, to: Vector2, w: float, reaching: bool) -> void:
	var n := 7
	var perp := Vector2(-(to - from).y, (to - from).x).normalized()
	var prev := from
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var p := from.lerp(to, t) + perp * sin(t * PI * 2.0) * 5.0
		var width := maxf(1.5, w * (1.0 - t * 0.7))
		ci.draw_line(prev, p, Color(0.02, 0.08, 0.10, 0.9), width + 2.0)
		ci.draw_line(prev, p, Palette.EYE_DROWNED, width)
		prev = p
	if not reaching:
		ci.draw_arc(to, 9.0, 0.0, TAU, 12, Palette.EYE_DROWNED, 3.0)


## The Ascension pillar under a Hierophant (`k` 0..1 of the channel).
static func draw_ascension(ci: CanvasItem, o: Vector2, r: float, k: float, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 5.0)
	var w := r * 1.6
	ci.draw_circle(o, r * 2.2, Color(Palette.EYE_BIOLUME, 0.10 + 0.08 * pulse))
	ci.draw_rect(Rect2(o + Vector2(-w * 0.5, -r * 9.0), Vector2(w, r * 9.0)), Color(Palette.EYE_BIOLUME, 0.18 + 0.12 * k))
	ci.draw_rect(Rect2(o + Vector2(-w * 0.2, -r * 9.0), Vector2(w * 0.4, r * 9.0)), Color(Palette.EYE_BIOLUME_GLOW, 0.20 + 0.2 * k))
	ci.draw_arc(o, r * 2.2, -PI * 0.5, -PI * 0.5 + TAU * k, 32, Palette.EYE_BIOLUME_GLOW, 3.0)  # The ritual's clock.


## The slam lane of an arm from `o` along `dir`, `length` x `width` px; `k`
## 0..1 of the telegraph; `struck` draws the arm lying along it.
static func draw_slam_lane(ci: CanvasItem, o: Vector2, dir: Vector2, length: float, width: float, k: float, struck: bool) -> void:
	var perp := Vector2(-dir.y, dir.x) * width * 0.5
	var far := o + dir * length
	var lane := PackedVector2Array([o + perp, far + perp, far - perp, o - perp])
	if struck:
		ci.draw_colored_polygon(lane, Color(Palette.EYE_DROWNED_DARK, 0.55))
		draw_tentacle(ci, o, far, width * 0.5, false)
		return
	ci.draw_colored_polygon(lane, Color(Palette.EYE_DROWNED, 0.16 + 0.10 * k))
	var fill := PackedVector2Array([o + perp, o + dir * length * k + perp, o + dir * length * k - perp, o - perp])
	ci.draw_colored_polygon(fill, Color(Palette.EYE_BIOLUME, 0.16))
	ci.draw_polyline(lane + PackedVector2Array([lane[0]]), Color(Palette.EYE_BIOLUME, 0.75), 2.0)


## Vhal'Neth's gaze at `o` (`r` px): an eye opening (`k` 0..1), then resting.
static func draw_gaze(ci: CanvasItem, o: Vector2, r: float, k: float, resting: bool, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 4.0)
	ci.draw_circle(o, r, Color(Palette.EYE_BIOLUME, (0.16 + 0.08 * pulse) if resting else 0.08))
	ci.draw_arc(o, r, 0.0, TAU, 48, Color(Palette.EYE_BIOLUME, 0.8 if resting else 0.5), 2.5)
	# The eye: a lens shape opening over the spot.
	ci.draw_set_transform(o, 0.0, Vector2(1.0, maxf(0.05, k) * 0.55))
	ci.draw_circle(Vector2.ZERO, r * 0.55, Color(Palette.EYE_BIOLUME_GLOW, 0.22 if resting else 0.15))
	ci.draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 32, Color(Palette.EYE_BIOLUME_GLOW, 0.7), 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_circle(o, r * 0.16 * k, Color(Palette.EYE_DROWNED_DARK, 0.8))  # The pupil.


## The binding of the finale at `o` (`k` 0..1 of it): necrotic rings closing
## on the dead god, chains of light, her face rising bound.
static func draw_binding(ci: CanvasItem, o: Vector2, r: float, k: float, now: float) -> void:
	var fade := clampf(1.0 - (k - 0.75) / 0.25, 0.0, 1.0) if k > 0.75 else 1.0
	for i in 3:
		var rr := r * (1.0 - k * 0.6) * (1.0 - float(i) * 0.2)
		ci.draw_arc(o, rr, now * (0.6 + float(i) * 0.3), now * (0.6 + float(i) * 0.3) + TAU * 0.8, 48, Color(BOUND, 0.7 * fade), 3.0)
	for i in 6:
		var a := TAU * float(i) / 6.0 + now * 0.2
		ci.draw_line(o + Vector2.from_angle(a) * r * 0.25, o + Vector2.from_angle(a) * r * (1.0 - k * 0.5), Color(Palette.EYE_BIOLUME_GLOW, 0.5 * fade), 2.0)
	var key := "bosses/vhalneth"
	if not SpriteBank.draw(ci, key, o, false, Color(0.62, 1.0, 0.78, 0.8 * fade)):
		_face(ci, o, 44.0, false, 1, now, 0.8 * fade)


## Call of the Drowned: the drowned ring closing under a marked foe (`k` 0..1).
static func draw_tendril_mark(ci: CanvasItem, o: Vector2, r: float, k: float) -> void:
	ci.draw_circle(o, r * (1.0 - k * 0.4), Color(Palette.EYE_DROWNED_DARK, 0.25 + 0.2 * k))
	ci.draw_arc(o, r * (1.0 - k * 0.4), 0.0, TAU, 20, Color(BARNACLE, 0.8), 2.0)
	ci.draw_arc(o, r * 0.5, k * TAU, k * TAU + PI, 10, Color(BOUND, 0.7), 1.5)


## Call of the Drowned: tendrils bursting up at `o` (`k` 0..1 of the rise).
static func draw_tendrils(ci: CanvasItem, o: Vector2, r: float, k: float) -> void:
	var a := 1.0 - k
	for i in 7:
		var ang := TAU * float(i) / 7.0 + 0.3
		var base := o + Vector2.from_angle(ang) * r * 0.5
		var tip := base + Vector2(sin(ang * 3.0) * 4.0, -r * (0.6 + 0.6 * k))
		ci.draw_line(base, tip, Color(Palette.EYE_DROWNED, a), 4.0)
		ci.draw_circle(tip, 2.0, Color(BOUND, a))
	ci.draw_arc(o, r, 0.0, TAU, 24, Color(BARNACLE, 0.6 * a), 2.0)
