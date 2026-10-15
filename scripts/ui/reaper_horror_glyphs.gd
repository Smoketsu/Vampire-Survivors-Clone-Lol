## ReaperHorrorGlyphs — code-drawn fallback glyphs (no external assets) of
## the two special-upgrade summon evolutions, plus their status overlays.
## SummonGlyphs.draw_summon() / draw_icon() route "shadow_reaper" and
## "cathedral_horror" here; Glyphs.draw_summon() tries the sprite art
## (assets/sprites/summons/<id>.png) first, so these only show without it.
##   Shadow Reaper    = the Grave Rogue's forward-leaning hooded chevron made
##                      taller and ragged, wreathed in violet smoke, a bone
##                      skull mask with violet eyes and twin curved scythe
##                      blades (one forward, one swept back).
##   Cathedral Horror = the Crypt Gargoyle grown huge: cracked pale marble,
##                      wider ribbed wings with claw tips, ram horns, glowing
##                      violet runes on the chest and a broken stone plinth
##                      under its claws.
## Status overlays: draw_stun() (stars over a stunned enemy) and
## draw_stone_shell() (the Cathedral Horror's stone form, over its body).
## Colour language (Palette, GDD §11.2): undead violet / bone / stone; no
## Covenant gold except the evolution icon frame (ProgressionGlyphs).
class_name ReaperHorrorGlyphs
extends RefCounted

## Cathedral Horror marble (pale, slightly cold).
const MARBLE := Color(0.70, 0.71, 0.74)
## Marble shading and cracks.
const MARBLE_DARK := Color(0.40, 0.41, 0.46)
## Node self_modulate of a Cathedral Horror in stone form (greys and dims
## the whole body, sprite or glyph).
const STONE_TINT := Color(0.78, 0.78, 0.84)
## Stun star colour over a stunned enemy.
const STUN_STAR := Color(1.0, 0.95, 0.7)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Shadow Reaper: violet smoke trailing behind, a tall ragged hooded cloak
## leaning forward, a bone skull mask with violet eyes, a violet sash and
## twin curved scythe blades.
static func draw_shadow_reaper(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	# Trailing smoke (behind the body).
	for i in 3:
		var p := o + Vector2(-r * (0.7 + 0.35 * float(i)), r * (0.55 - 0.25 * float(i)))  # Smoke puff centre.
		ci.draw_circle(p, r * (0.5 - 0.1 * float(i)), Color(Palette.VIOLET, 0.16 - 0.04 * float(i)))
	var cloak := PackedVector2Array([
		o + Vector2(-r * 0.85, r * 1.15), o + Vector2(-r * 0.6, r * 0.75), o + Vector2(-r * 0.55, -r * 0.6),
		o + Vector2(r * 0.25, -r * 1.35), o + Vector2(r * 0.75, -r * 0.4), o + Vector2(r * 0.3, r * 0.2),
		o + Vector2(r * 0.9, r * 1.15), o + Vector2(r * 0.4, r * 0.9), o + Vector2(0, r * 1.2), o + Vector2(-r * 0.35, r * 0.85)])
	ci.draw_colored_polygon(cloak, _c(Palette.ROGUE_CLOAK.darkened(0.25), flash))
	var edge := cloak.duplicate()  # Closed outline.
	edge.append(cloak[0])
	ci.draw_polyline(edge, _c(Palette.VIOLET, flash), 1.4)
	# Skull mask inside the hood.
	var m := o + Vector2(r * 0.12, -r * 0.5)  # Mask centre.
	ci.draw_circle(m, r * 0.34, Glyphs.EYE)
	ci.draw_circle(m + Vector2(r * 0.04, r * 0.02), r * 0.24, _c(Palette.BONE, flash))
	ci.draw_circle(m + Vector2(-r * 0.05, -r * 0.02), r * 0.07, Palette.VIOLET)
	ci.draw_circle(m + Vector2(r * 0.14, -r * 0.02), r * 0.07, Palette.VIOLET)
	ci.draw_line(m + Vector2(-r * 0.06, r * 0.14), m + Vector2(r * 0.16, r * 0.14), Glyphs.EYE, 1.0)
	# Sash.
	ci.draw_line(o + Vector2(-r * 0.55, r * 0.25), o + Vector2(r * 0.35, r * 0.05), _c(Palette.VIOLET, flash), 2.0)
	# Twin scythe blades: hafts and curved bone-white edges.
	var front := o + Vector2(r * 1.25, -r * 0.25)  # Forward blade's haft end.
	ci.draw_line(o + Vector2(r * 0.45, r * 0.3), front, _c(Palette.DEATH_STEEL.lightened(0.2), flash), 1.5)
	ci.draw_arc(front + Vector2(-r * 0.15, r * 0.45), r * 0.55, -2.2, -0.35, 10, _c(Palette.BONE, flash), 2.0)
	var back := o + Vector2(-r * 1.2, -r * 0.05)  # Swept-back blade's haft end.
	ci.draw_line(o + Vector2(-r * 0.5, r * 0.5), back, _c(Palette.DEATH_STEEL.lightened(0.2), flash), 1.5)
	ci.draw_arc(back + Vector2(r * 0.15, r * 0.45), r * 0.55, -2.8, -0.95, 10, _c(Palette.BONE, flash), 2.0)


## Cathedral Horror: a broken plinth, wide ribbed marble wings with claw
## tips, a hulking cracked marble body with glowing violet runes, a horned
## head with violet eyes, and bone claws.
static func draw_cathedral_horror(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var marble := _c(MARBLE, flash)  # Body colour.
	var dark := _c(MARBLE_DARK, flash)  # Shading / cracks.
	# Broken plinth under its claws.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, r * 0.85), Vector2(r * 1.6, r * 0.3)), Glyphs.OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.72, r * 0.88), Vector2(r * 1.44, r * 0.22)), dark)
	# Wings: membranes, ribs and claw tips.
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			o + Vector2(side * r * 0.25, -r * 0.4), o + Vector2(side * r * 1.25, -r * 1.35), o + Vector2(side * r * 1.9, -r * 1.05),
			o + Vector2(side * r * 1.55, -r * 0.4), o + Vector2(side * r * 1.85, r * 0.15), o + Vector2(side * r * 1.35, r * 0.05),
			o + Vector2(side * r * 1.3, r * 0.5), o + Vector2(side * r * 0.35, r * 0.4)])
		ci.draw_colored_polygon(pts, _c(MARBLE_DARK.darkened(0.15), flash))
		for k in [1, 2, 4]:
			ci.draw_line(o + Vector2(side * r * 0.3, -r * 0.3), pts[k], marble, 1.5)
		ci.draw_circle(pts[2], r * 0.08, _c(Palette.BONE, flash))
	# Body, belly runes and cracks.
	ci.draw_circle(o + Vector2(0, r * 0.2), r * 0.78, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.2), r * 0.7, marble)
	ci.draw_circle(o + Vector2(r * 0.25, r * 0.45), r * 0.3, Color(MARBLE_DARK, 0.5))
	ci.draw_circle(o + Vector2(0, r * 0.2), r * 0.3, Color(Palette.VIOLET, 0.25))
	ci.draw_polyline(ProgressionGlyphs._closed(Glyphs.regular_polygon(o + Vector2(0, r * 0.2), r * 0.22, 3, PI / 2.0)), Palette.VIOLET, 1.5)
	ci.draw_polyline(PackedVector2Array([o + Vector2(-r * 0.55, -r * 0.05), o + Vector2(-r * 0.3, r * 0.2),
		o + Vector2(-r * 0.4, r * 0.5)]), dark, 1.0)
	# Head, ram horns and eyes.
	var h := o + Vector2(0, -r * 0.55)  # Head centre.
	for side: float in [-1.0, 1.0]:
		ci.draw_arc(h + Vector2(side * r * 0.42, -r * 0.2), r * 0.24, PI * 0.9 if side < 0.0 else -PI * 0.1, PI * 2.1 if side < 0.0 else PI * 1.1, 8,
			_c(Palette.BONE, flash), 2.0)
	ci.draw_circle(h, r * 0.42, Glyphs.OUTLINE)
	ci.draw_circle(h, r * 0.36, _c(MARBLE.lightened(0.1), flash))
	ci.draw_line(h + Vector2(-r * 0.2, r * 0.18), h + Vector2(r * 0.2, r * 0.18), dark, 1.5)
	ci.draw_circle(h + Vector2(-r * 0.14, -r * 0.03), r * 0.09, Palette.VIOLET)
	ci.draw_circle(h + Vector2(r * 0.14, -r * 0.03), r * 0.09, Palette.VIOLET)
	# Bone claws gripping the plinth.
	for i in 4:
		var x := (float(i) - 1.5) * r * 0.28  # Claw x offset.
		ci.draw_line(o + Vector2(x, r * 0.75), o + Vector2(x + r * 0.08, r * 1.0), _c(Palette.BONE, flash), 1.5)


## Stun stars over a stunned enemy (drawn in its _draw()): three small
## four-point stars on a faint ring, centred at `c` above the body of
## radius `r` (the stars' pixel art, MarkerArtData.STUN_STARS, when present).
static func draw_stun(ci: CanvasItem, c: Vector2, r: float) -> void:
	var rr := maxf(r * 0.7, 6.0)  # Ring radius (px).
	ci.draw_arc(c, rr, 0.0, TAU, 16, Color(STUN_STAR, 0.35), 1.0)
	if SpriteBank.draw_flat(ci, MarkerArtData.STUN_STARS, c, 0.0):
		return  # Pixel-art stars over the faint ring.
	for i in 3:
		var p := c + Vector2.from_angle(TAU * float(i) / 3.0 - PI / 2.0) * Vector2(rr, rr * 0.45)  # Star centre.
		var s := maxf(r * 0.22, 2.5)  # Star half-size (px).
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.3, 0), p + Vector2(0, s), p + Vector2(-s * 0.3, 0)]), STUN_STAR)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s * 0.3), p + Vector2(s, 0), p + Vector2(0, s * 0.3)]), STUN_STAR)


## Cathedral Horror stone form (drawn over its body; the node is also
## tinted with STONE_TINT): a translucent stone shell, cracks and three
## glowing violet rune dots.
static func draw_stone_shell(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, -r * 0.1), r * 1.15, Color(MARBLE, 0.32))
	ci.draw_arc(c + Vector2(0, -r * 0.1), r * 1.15, 0.0, TAU, 24, Color(MARBLE_DARK, 0.9), 1.5)
	ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.8), c + Vector2(-r * 0.2, -r * 0.3),
		c + Vector2(-r * 0.4, r * 0.1), c + Vector2(0, r * 0.6)]), MARBLE_DARK, 1.2)
	ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.7, -r * 0.5), c + Vector2(r * 0.3, -r * 0.1),
		c + Vector2(r * 0.5, r * 0.4)]), MARBLE_DARK, 1.2)
	for i in 3:
		ci.draw_circle(c + Vector2((float(i) - 1.0) * r * 0.45, r * 0.75), r * 0.09, Palette.VIOLET)
