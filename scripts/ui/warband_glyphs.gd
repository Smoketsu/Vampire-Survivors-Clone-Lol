## WarbandGlyphs — code-drawn fallback shapes (no external assets) for the
## three newest summon classes, their evolutions, their passives' icons and
## their effects (SummonGlyphs.draw_summon() / draw_icon() dispatch these
## kinds here; units and unit icons always go through Glyphs.draw_summon(),
## so sprite art in assets/sprites/summons/<kind>.png wins when present).
## Every silhouette is distinct (GDD §11 / §16 readability: shape first):
##   Bone Hound      = a low, long quadruped skeleton: ribcage barrel, four
##                     thin legs, a long snouted skull with a green eye and a
##                     curled bone tail (the only four-legged summon),
##   Hellhound       = the hound grown bigger and charred black, ember cracks
##                     along the ribs, a mane of flame and burning eyes,
##   Banshee         = a legless, flowing pale veil that frays into wisps,
##                     long streaming hair, a dark wailing mouth and raised
##                     arms (floats above its shadow, BansheeBehavior),
##   Keening Lady    = a taller banshee in a dark violet gown with a silver
##                     circlet and sound ripples rolling from her mouth,
##   Corpse Catapult = a squat frame of bone beams on two bone wheels with a
##                     diagonal throwing arm whose cup holds a skull boulder
##                     (the only wheeled summon),
##   Ossuary Engine  = a larger catapult built from ribcages and spines, three
##                     skulls in a triple cup and ember-lit sinew,
##   passive icons   = Blood Scent: a crimson blood drop with speed streaks;
##                     Mournsong: a pale weeping veil-mouth with violet notes;
##                     Siegecraft: a cracked tower struck by a bone boulder,
##   effects         = the Dirge mark on a weakened enemy (a drooping pale
##                     veil arc; a crossed halo while silenced), Hellhound
##                     fire patches, Ossuary Engine shard fields and the
##                     catapult boulder (HordeHazards).
## Colour language (Palette, GDD §11.2): undead bone / violet / green, with
## hellfire embers for the Hellhound; Covenant gold only on the evolution
## icon frame (ProgressionGlyphs._gold_frame()).
## Polygons are kept convex (or simple fans) so they always triangulate.
class_name WarbandGlyphs
extends RefCounted

## Banshee wail colour: a pale, cold spectral white-blue.
const WAIL := Color(0.80, 0.88, 0.98)
## Keening Lady silence colour (the silence ring and mark): a dim lilac.
const SILENCE := Color(0.72, 0.58, 0.95)
## Banshee veil body colour (translucent spectral white).
const VEIL := Color(0.78, 0.84, 0.92, 0.85)
## Keening Lady gown colour (a dark violet).
const GOWN := Color(0.30, 0.16, 0.42)
## Hellhound charred-bone body colour.
const CHAR := Color(0.30, 0.20, 0.17)
## Catapult timber colour (old coffin wood).
const WOOD := Color(0.36, 0.27, 0.20)
## Blood Scent icon colour.
const BLOOD := Color(0.72, 0.08, 0.12)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws summon glyph `kind` at `o` with body radius `r`. Returns false if
## the kind is unknown here.
static func draw_summon(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"bone_hound":
			draw_hound(ci, o, r, flash, false)
		"hellhound":
			draw_hound(ci, o, r, flash, true)
		"banshee":
			draw_banshee(ci, o, r, flash, false)
		"keening_lady":
			draw_banshee(ci, o, r, flash, true)
		"corpse_catapult":
			draw_catapult(ci, o, r, flash, false)
		"ossuary_engine":
			draw_catapult(ci, o, r, flash, true)
		_:
			return false
	return true


## Draws UI icon `kind` centred at `c` with half-size `s` (evolutions get the
## gold frame). Returns false if the kind is unknown here.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"bone_hound":
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.12), s * 0.55, false)
		"banshee":
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.05), s * 0.5, false)
		"corpse_catapult":
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.12), s * 0.48, false)
		"hellhound":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.14), s * 0.5, false)
		"keening_lady":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(0, s * 0.1), s * 0.44, false)
		"ossuary_engine":
			ProgressionGlyphs._gold_frame(ci, c, s)
			Glyphs.draw_summon(ci, kind, c + Vector2(-s * 0.05, s * 0.14), s * 0.42, false)
		"blood_scent":
			_icon_blood_scent(ci, c, s)
		"mournsong":
			_icon_mournsong(ci, c, s)
		"siegecraft":
			_icon_siegecraft(ci, c, s)
		_:
			return false
	return true


# --- Units ---------------------------------------------------------------------------

## Bone Hound / Hellhound (`hell`): a low, long quadruped facing right.
static func draw_hound(ci: CanvasItem, o: Vector2, r: float, flash: bool, hell: bool) -> void:
	var body := _c(CHAR if hell else Palette.BONE, flash)  # Bone colour.
	var dark := _c(Palette.BONE.darkened(0.45) if not hell else Color(0.08, 0.05, 0.05), flash)  # Shading.
	var eye := HordeHazards.HELLFIRE if hell else Palette.NECRO_GREEN  # Eye glow.
	# Flat ground shadow and four thin legs.
	_shadow(ci, o + Vector2(0, r * 0.98), r * 1.1)
	for x: float in [-0.95, -0.55, 0.45, 0.85]:
		ci.draw_line(o + Vector2(r * x, r * 0.1), o + Vector2(r * (x - 0.1), r * 0.95), Glyphs.OUTLINE, 2.5)
		ci.draw_line(o + Vector2(r * x, r * 0.1), o + Vector2(r * (x - 0.1), r * 0.95), body, 1.5)
	# Curled tail.
	ci.draw_arc(o + Vector2(-r * 1.25, -r * 0.35), r * 0.38, PI * 0.2, PI * 1.3, 8, body, 1.5)
	# Ribcage barrel (outline, body, rib lines).
	ci.draw_rect(Rect2(o + Vector2(-r * 1.15, -r * 0.5), Vector2(r * 1.95, r * 0.75)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 1.05, -r * 0.42), Vector2(r * 1.75, r * 0.6)), body)
	for i in 4:
		var x := -r * 0.85 + r * 0.4 * float(i)  # Rib x.
		ci.draw_line(o + Vector2(x, -r * 0.4), o + Vector2(x + r * 0.08, r * 0.16), dark, 1.0)
	if hell:
		for i in 3:
			var x := -r * 0.65 + r * 0.45 * float(i)  # Ember crack x.
			ci.draw_line(o + Vector2(x, -r * 0.3), o + Vector2(x + r * 0.15, r * 0.05), HordeHazards.EMBER, 1.2)
		# Mane of flame along the neck and back.
		for i in 3:
			var p := o + Vector2(r * (0.0 + 0.3 * float(i)), -r * 0.45)  # Flame root.
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.15, 0), p + Vector2(r * 0.15, 0),
				p + Vector2(-r * 0.05, -r * (0.55 + 0.15 * float(i)))]), HordeHazards.EMBER)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.07, 0), p + Vector2(r * 0.07, 0),
				p + Vector2(-r * 0.03, -r * (0.3 + 0.1 * float(i)))]), HordeHazards.HELLFIRE)
	# Long snouted skull, forward and a little up.
	var h := o + Vector2(r * 1.05, -r * 0.55)  # Skull centre.
	ci.draw_circle(h, r * 0.5, Glyphs.OUTLINE)
	ci.draw_circle(h, r * 0.42, body)
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(r * 0.1, -r * 0.3), h + Vector2(r * 0.95, -r * 0.05),
		h + Vector2(r * 0.9, r * 0.2), h + Vector2(r * 0.1, r * 0.3)]), body)
	ci.draw_line(h + Vector2(r * 0.3, r * 0.15), h + Vector2(r * 0.85, r * 0.12), dark, 1.0)  # Jaw line.
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-r * 0.3, -r * 0.25), h + Vector2(-r * 0.05, -r * 0.3),
		h + Vector2(-r * 0.25, -r * 0.75)]), body)  # Ear.
	ci.draw_circle(h + Vector2(r * 0.12, -r * 0.08), r * 0.14, Glyphs.EYE)
	ci.draw_circle(h + Vector2(r * 0.12, -r * 0.08), r * 0.08, eye)


## Banshee / Keening Lady (`lady`): a legless flowing veil with streaming
## hair, a wailing mouth and raised arms.
static func draw_banshee(ci: CanvasItem, o: Vector2, r: float, flash: bool, lady: bool) -> void:
	var veil := _c(GOWN if lady else VEIL, flash)  # Body colour.
	var pale := _c(WAIL, flash)  # Face / hands.
	ci.draw_circle(o, r * (1.5 if lady else 1.3), Color(WAIL, 0.12))
	# Veil: a wide-shouldered trapezoid fraying into three wisps.
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.6, -r * 0.45), o + Vector2(r * 0.6, -r * 0.45),
		o + Vector2(r * 0.8, r * 0.55), o + Vector2(-r * 0.8, r * 0.55)]), veil)
	for i in 3:
		var x := (float(i) - 1.0) * r * 0.5  # Wisp x.
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(x - r * 0.25, r * 0.5), o + Vector2(x + r * 0.25, r * 0.5),
			o + Vector2(x + r * 0.1 * (float(i) - 1.0), r * (1.25 + 0.15 * float(i % 2)))]), veil)
	# Long streaming hair behind the head (to the left).
	var head := o + Vector2(0, -r * 0.75)  # Head centre.
	for i in 3:
		ci.draw_line(head + Vector2(-r * 0.2, -r * 0.2 + r * 0.15 * float(i)), head + Vector2(-r * 1.2, r * (0.2 + 0.35 * float(i))),
			_c(Palette.BONE.lightened(0.2), flash), 1.5)
	# Raised arms.
	ci.draw_line(o + Vector2(-r * 0.5, -r * 0.3), o + Vector2(-r * 0.95, -r * 0.95), pale, 1.5)
	ci.draw_line(o + Vector2(r * 0.5, -r * 0.3), o + Vector2(r * 0.95, -r * 0.95), pale, 1.5)
	# Face and the dark wailing mouth.
	ci.draw_circle(head, r * 0.45, pale)
	ci.draw_circle(head + Vector2(-r * 0.15, -r * 0.08), r * 0.1, Glyphs.EYE)
	ci.draw_circle(head + Vector2(r * 0.15, -r * 0.08), r * 0.1, Glyphs.EYE)
	ci.draw_circle(head + Vector2(0, r * 0.14), r * 0.11, Glyphs.EYE)  # Tall oval mouth: two stacked circles.
	ci.draw_circle(head + Vector2(0, r * 0.26), r * 0.11, Glyphs.EYE)
	if lady:
		# Silver circlet and sound ripples rolling out of the mouth.
		ci.draw_arc(head, r * 0.47, PI * 1.15, PI * 1.85, 8, _c(Palette.SILVER, flash), 1.5)
		ci.draw_circle(head + Vector2(0, -r * 0.47), r * 0.09, _c(Palette.VIOLET, flash))
		for i in 3:
			ci.draw_arc(head + Vector2(r * 0.1, r * 0.2), r * (0.45 + 0.28 * float(i)), -0.6, 0.6, 6,
				Color(SILENCE, 0.8 - 0.2 * float(i)), 1.2)


## Corpse Catapult / Ossuary Engine (`engine`): a bone-beam frame on two
## wheels with a diagonal throwing arm and a skull load in its cup.
static func draw_catapult(ci: CanvasItem, o: Vector2, r: float, flash: bool, engine: bool) -> void:
	var beam := _c(Palette.BONE.darkened(0.15) if engine else WOOD, flash)  # Frame colour.
	var bone := _c(Palette.BONE, flash)
	_shadow(ci, o + Vector2(0, r * 1.0), r * 1.2)
	# Base beam and two bone wheels.
	ci.draw_rect(Rect2(o + Vector2(-r * 1.0, r * 0.15), Vector2(r * 2.0, r * 0.4)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.95, r * 0.2), Vector2(r * 1.9, r * 0.3)), beam)
	for x: float in [-0.65, 0.65]:
		var w := o + Vector2(r * x, r * 0.65)  # Wheel centre.
		ci.draw_circle(w, r * 0.38, Glyphs.OUTLINE)
		ci.draw_circle(w, r * 0.3, bone)
		ci.draw_circle(w, r * 0.1, Glyphs.EYE)
		ci.draw_line(w + Vector2(-r * 0.3, 0), w + Vector2(r * 0.3, 0), Palette.BONE.darkened(0.4), 1.0)
		ci.draw_line(w + Vector2(0, -r * 0.3), w + Vector2(0, r * 0.3), Palette.BONE.darkened(0.4), 1.0)
	# Upright A-frame.
	ci.draw_line(o + Vector2(-r * 0.4, r * 0.2), o + Vector2(0, -r * 0.55), beam, 2.5)
	ci.draw_line(o + Vector2(r * 0.4, r * 0.2), o + Vector2(0, -r * 0.55), beam, 2.5)
	if engine:
		# Ribcage panels on the frame, ember-lit sinew.
		for i in 3:
			ci.draw_arc(o + Vector2(0, -r * 0.05 + r * 0.12 * float(i)), r * 0.35, PI * 1.1, PI * 1.9, 6, bone, 1.0)
		ci.draw_line(o + Vector2(-r * 0.9, r * 0.2), o + Vector2(r * 0.1, -r * 0.5), HordeHazards.EMBER, 1.0)
	else:
		ci.draw_line(o + Vector2(-r * 0.9, r * 0.2), o + Vector2(r * 0.1, -r * 0.5), _c(Palette.CORPSE_FLESH, flash), 1.0)  # Sinew rope.
	# Throwing arm (pivot at the frame top, cup up and back at the left).
	var pivot := o + Vector2(0, -r * 0.55)  # Arm pivot.
	var cup := o + Vector2(-r * 0.95, -r * 1.25)  # Cup centre.
	ci.draw_line(o + Vector2(r * 0.55, -r * 0.15), cup, Glyphs.OUTLINE, 3.5)
	ci.draw_line(o + Vector2(r * 0.55, -r * 0.15), cup, beam, 2.2)
	ci.draw_circle(pivot, r * 0.12, bone)
	# The load: one skull, or three on an Ossuary Engine.
	if engine:
		ci.draw_arc(cup + Vector2(0, r * 0.1), r * 0.55, 0.2, PI - 0.2, 8, bone, 2.0)
		Glyphs._skull(ci, cup + Vector2(-r * 0.3, -r * 0.05), r * 0.24, flash, HordeHazards.EMBER)
		Glyphs._skull(ci, cup + Vector2(r * 0.3, -r * 0.05), r * 0.24, flash, HordeHazards.EMBER)
		Glyphs._skull(ci, cup + Vector2(0, -r * 0.3), r * 0.26, flash, HordeHazards.EMBER)
	else:
		ci.draw_arc(cup + Vector2(0, r * 0.08), r * 0.38, 0.2, PI - 0.2, 8, bone, 2.0)
		Glyphs._skull(ci, cup + Vector2(0, -r * 0.08), r * 0.3, flash, Palette.NECRO_GREEN)


## A flat ground shadow `w` px half-wide centred at `c` (three overlapping
## discs: no draw transform, so it is safe inside any caller's transform).
static func _shadow(ci: CanvasItem, c: Vector2, w: float) -> void:
	for k: float in [-0.55, 0.0, 0.55]:
		ci.draw_circle(c + Vector2(w * k, 0), w * 0.32, Color(0, 0, 0, 0.18))


# --- Effects -------------------------------------------------------------------------

## Banshee Dirge mark on a weakened enemy at `c` (body radius `r`; drawn in
## its _draw()): a pale veil arc drooping over the head and two falling
## tear streaks; while `silenced` (Keening Lady) a crossed lilac halo too.
static func draw_dirge(ci: CanvasItem, c: Vector2, r: float, silenced: bool) -> void:
	ci.draw_arc(c + Vector2(0, -r * 0.2), r * 1.15, PI * 1.15, PI * 1.85, 10, Color(WAIL, 0.7), 1.5)
	ci.draw_line(c + Vector2(-r * 0.75, -r * 0.6), c + Vector2(-r * 0.85, r * 0.1), Color(WAIL, 0.45), 1.0)
	ci.draw_line(c + Vector2(r * 0.75, -r * 0.6), c + Vector2(r * 0.85, r * 0.1), Color(WAIL, 0.45), 1.0)
	if silenced:
		var h := c + Vector2(0, -r * 1.6)  # Halo centre.
		ci.draw_arc(h, r * 0.45 + 1.5, 0.0, TAU, 12, SILENCE, 1.2)
		ci.draw_line(h + Vector2(-r * 0.45, -r * 0.3), h + Vector2(r * 0.45, r * 0.3), SILENCE, 1.5)


## Hellhound fire-trail patch at `pos` (radius `r`), `k` = life left (1..0).
static func draw_fire_patch(ci: CanvasItem, pos: Vector2, r: float, k: float) -> void:
	ci.draw_circle(pos, r, Color(HordeHazards.EMBER, 0.22 * k))
	ci.draw_circle(pos, r * 0.6, Color(HordeHazards.HELLFIRE, 0.3 * k))
	for i in 3:
		var p := pos + Vector2.from_angle(TAU * float(i) / 3.0 + 0.5) * r * 0.45  # Flame tongue root.
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.18, 0), p + Vector2(r * 0.18, 0),
			p + Vector2(0, -r * (0.55 + 0.25 * k))]), Color(HordeHazards.EMBER, 0.7 * k))


## Ossuary Engine shard field at `pos` (radius `r`), `k` = life left (1..0):
## scorched ground, ember glow and bone shards sticking out of it.
static func draw_shard_field(ci: CanvasItem, pos: Vector2, r: float, k: float) -> void:
	ci.draw_circle(pos, r, Color(0.05, 0.03, 0.03, 0.35 * k))
	ci.draw_circle(pos, r * 0.75, Color(HordeHazards.EMBER, 0.14 * k))
	ci.draw_arc(pos, r, 0.0, TAU, 24, Color(HordeHazards.EMBER, 0.45 * k), 1.0)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3  # Shard angle.
		var p := pos + Vector2.from_angle(a) * r * (0.35 + 0.1 * float(i % 3))  # Shard root.
		ci.draw_line(p, p + Vector2.from_angle(a - 1.2) * r * 0.32, Color(Palette.BONE, 0.85 * k), 2.0)


## A catapult boulder at `pos` (radius `r`) spun by `rot` radians; a
## `burning` one (Ossuary Engine) glows with embers.
static func draw_boulder(ci: CanvasItem, pos: Vector2, r: float, rot: float, burning: bool) -> void:
	if burning:
		ci.draw_circle(pos, r * 1.6, Color(HordeHazards.EMBER, 0.3))
	ci.draw_circle(pos, r + 1.0, Glyphs.OUTLINE)
	ci.draw_circle(pos, r, Palette.CORPSE_FLESH.darkened(0.2))
	for i in 3:
		var a := rot + TAU * float(i) / 3.0  # Bone spur angle.
		ci.draw_line(pos + Vector2.from_angle(a) * r * 0.4, pos + Vector2.from_angle(a) * r * 1.3, Palette.BONE, 1.5)
	Glyphs._skull(ci, pos, r * 0.5, false, HordeHazards.EMBER if burning else Palette.NECRO_GREEN)


# --- Passive icons -------------------------------------------------------------------

## Blood Scent: a crimson blood drop with three speed streaks behind it.
static func _icon_blood_scent(ci: CanvasItem, c: Vector2, s: float) -> void:
	for i in 3:
		var y := -s * 0.25 + s * 0.25 * float(i)  # Streak height.
		ci.draw_line(c + Vector2(-s * 0.75, y), c + Vector2(-s * 0.3, y), Color(Palette.BONE, 0.7), 1.5)
	var d := c + Vector2(s * 0.15, s * 0.15)  # Drop centre.
	ci.draw_circle(d, s * 0.38, BLOOD)
	ci.draw_colored_polygon(PackedVector2Array([d + Vector2(-s * 0.34, -s * 0.15), d + Vector2(s * 0.34, -s * 0.15),
		d + Vector2(0, -s * 0.75)]), BLOOD)
	ci.draw_circle(d + Vector2(-s * 0.12, -s * 0.05), s * 0.1, Color(1.0, 0.6, 0.6, 0.8))


## Mournsong: a pale weeping veil-mouth with two violet notes.
static func _icon_mournsong(ci: CanvasItem, c: Vector2, s: float) -> void:
	var f := c + Vector2(-s * 0.15, s * 0.05)  # Face centre.
	ci.draw_circle(f, s * 0.42, WAIL)
	ci.draw_circle(f + Vector2(-s * 0.14, -s * 0.1), s * 0.08, Glyphs.EYE)
	ci.draw_circle(f + Vector2(s * 0.14, -s * 0.1), s * 0.08, Glyphs.EYE)
	ci.draw_circle(f + Vector2(0, s * 0.17), s * 0.12, Glyphs.EYE)
	ci.draw_line(f + Vector2(-s * 0.14, 0), f + Vector2(-s * 0.18, s * 0.35), Color(Palette.COLD_BLUE, 0.8), 1.2)
	for i in 2:
		var n := c + Vector2(s * (0.45 + 0.18 * float(i)), -s * (0.15 + 0.3 * float(i)))  # Note head.
		ci.draw_circle(n, s * 0.1, Palette.VIOLET)
		ci.draw_line(n + Vector2(s * 0.09, 0), n + Vector2(s * 0.09, -s * 0.35), Palette.VIOLET, 1.2)


## Siegecraft: a cracked grey tower struck by a bone boulder.
static func _icon_siegecraft(ci: CanvasItem, c: Vector2, s: float) -> void:
	var t := Rect2(c + Vector2(-s * 0.05, -s * 0.45), Vector2(s * 0.6, s * 1.05))  # Tower body.
	ci.draw_rect(t, Palette.STONE.lightened(0.25))
	for i in 3:
		ci.draw_rect(Rect2(t.position + Vector2(s * 0.2 * float(i), -s * 0.15), Vector2(s * 0.14, s * 0.15)), Palette.STONE.lightened(0.25))
	ci.draw_polyline(PackedVector2Array([t.position + Vector2(s * 0.05, s * 0.2), t.position + Vector2(s * 0.25, s * 0.45),
		t.position + Vector2(s * 0.12, s * 0.65), t.position + Vector2(s * 0.3, s * 0.9)]), Glyphs.EYE, 1.5)
	draw_boulder(ci, c + Vector2(-s * 0.5, -s * 0.25), s * 0.24, 0.4, false)
	ci.draw_line(c + Vector2(-s * 0.85, -s * 0.6), c + Vector2(-s * 0.65, -s * 0.4), Color(Palette.BONE, 0.6), 1.5)
