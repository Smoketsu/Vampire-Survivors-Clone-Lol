## SeraphineGlyphs — the placeholder shape of Grand Inquisitor Seraphine
## (GDD §7.5; §11 colour language: the Covenant is crimson / ivory / silver
## / gold, holy magic radiant gold). Static functions draw into the
## CanvasItem currently inside its _draw(), like Glyphs and MarchGlyphs.
## Silhouette (GDD §10.5 "readable"): a winged figure in a white-gold bell
## robe with a crimson stole, a sun halo behind her head and a tall relic
## staff crowned by a radiant sunburst. The Avatar of the Dawn is larger and
## brighter (wider wings, long halo rays, a blazing relic); the Last Light
## adds a flickering flame aura. Art: SpriteBank key "bosses/seraphine"
## (and the optional "bosses/seraphine_avatar" for the Avatar form) replaces
## the shape when its PNG exists. Purely visual.
class_name SeraphineGlyphs
extends RefCounted

## Size multiplier of the glyph over her body radius (a boss reads larger
## than the sprite-drawn soldiers around her).
const BASE_SCALE: float = 1.2
## Size multiplier of the Avatar of the Dawn (and the Last Light) glyph.
const AVATAR_SCALE: float = 1.45
## Pale skin tone of her face.
const SKIN := Color(0.96, 0.87, 0.78)
## White-gold of her robe (brighter in the Avatar form).
const ROBE := Color(0.98, 0.95, 0.86)
## Dark outline behind the body (same as Glyphs.OUTLINE).
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Draws Seraphine at `o` with body radius `r`. `pose`: 0 walk, 1 casting
## (relic raised), 2 gathering light (teleport / transformation), 3 recover.
## `fight_phase` 0 Divine Judgment, 1 Avatar, 2 Last Light. `glow` 0..1 is
## the light gathering on her (teleport glow, transformation); `now` (s)
## animates the halo and flames (visual only).
static func draw_seraphine(ci: CanvasItem, o: Vector2, r: float, flash: bool, pose: int, fight_phase: int, glow: float, now: float) -> void:
	var avatar := fight_phase >= 1
	var k := r * (AVATAR_SCALE if avatar else BASE_SCALE)  # Drawing scale (px).
	_draw_aura(ci, o, k, fight_phase, now)
	var key := "bosses/seraphine_avatar" if avatar and SpriteBank.has("bosses/seraphine_avatar") else "bosses/seraphine"
	if SpriteBank.draw_pose(ci, key, pose, o, flash):  # The still, or its attack pose (BossPoseData).
		_draw_glow(ci, o, k, glow)
		return  # Sprite art exists (assets/sprites/bosses/seraphine*.png).
	_draw_wings(ci, o, k, flash, avatar, now)
	_draw_halo(ci, o + Vector2(0, -k * 0.9), k, avatar, now)
	# Shadow and bell robe.
	ci.draw_circle(o + Vector2(0, k * 0.85), k * 0.75, Color(0, 0, 0, 0.25))
	var robe := PackedVector2Array([o + Vector2(-k * 0.42, -k * 0.55), o + Vector2(k * 0.42, -k * 0.55),
		o + Vector2(k * 0.62, k * 0.2), o + Vector2(k * 0.85, k * 0.95), o + Vector2(k * 0.3, k * 1.05),
		o + Vector2(-k * 0.3, k * 1.05), o + Vector2(-k * 0.85, k * 0.95), o + Vector2(-k * 0.62, k * 0.2)])
	var robe_col := ROBE.lerp(Color(1.0, 0.97, 0.8), 0.6) if avatar else ROBE
	ci.draw_colored_polygon(robe, _c(robe_col, flash))
	var robe_line := robe.duplicate()
	robe_line.append(robe[0])
	ci.draw_polyline(robe_line, _c(Palette.GOLD, flash), 2.0)
	ci.draw_line(o + Vector2(-k * 0.8, k * 0.88), o + Vector2(k * 0.8, k * 0.88), _c(Palette.GOLD, flash), 2.0)  # Hem trim.
	# Crimson stole with a gold sun on the chest.
	var stole := PackedVector2Array([o + Vector2(-k * 0.14, -k * 0.55), o + Vector2(k * 0.14, -k * 0.55),
		o + Vector2(k * 0.18, k * 1.0), o + Vector2(-k * 0.18, k * 1.0)])
	ci.draw_colored_polygon(stole, _c(Palette.CRIMSON, flash))
	ci.draw_circle(o + Vector2(0, -k * 0.25), k * 0.13, _c(Palette.GOLD, flash))
	for i in 8:
		var d := Vector2.from_angle(TAU * float(i) / 8.0)
		ci.draw_line(o + Vector2(0, -k * 0.25) + d * k * 0.15, o + Vector2(0, -k * 0.25) + d * k * 0.24, _c(Palette.GOLD, flash), 1.5)
	# Head under a white veil and a gold circlet.
	var head := o + Vector2(0, -k * 0.9)
	ci.draw_circle(head + Vector2(-k * 0.04, k * 0.02), k * 0.33, _c(ROBE, flash))  # Veil.
	ci.draw_circle(head + Vector2(k * 0.05, 0), k * 0.24, _c(SKIN, flash))
	ci.draw_arc(head, k * 0.3, PI * 1.05, PI * 1.95, 10, _c(Palette.GOLD, flash), 2.5)  # Circlet.
	ci.draw_circle(head + Vector2(0, -k * 0.3), k * 0.07, _c(Palette.GOLD, flash))
	ci.draw_line(head + Vector2(k * 0.1, -k * 0.03), head + Vector2(k * 0.22, -k * 0.03), Color(0.2, 0.15, 0.1), 1.5)  # Eyes (facing right).
	_draw_staff(ci, o, k, flash, pose, avatar, now)
	_draw_glow(ci, o, k, glow)


## The radiant aura behind her: a soft glow in the Avatar form, a
## flickering flame ring in the Last Light.
static func _draw_aura(ci: CanvasItem, o: Vector2, k: float, fight_phase: int, now: float) -> void:
	if fight_phase >= 1 and CovenantFx.has(CovenantFxData.RAY):
		# Pixel art (CovenantFx, GDD §15.0 "Act I enemy AoE art"): the soft glow
		# as the shared disc texture, a slowly turning sunburst of gold rays,
		# and in the Last Light a ring of flame tongues licking outward.
		CovenantFx.soft_disc(ci, o, k * 2.0, Color(Palette.GOLD, 0.1))
		CovenantFx.soft_disc(ci, o, k * 1.45, Color(Palette.IVORY, 0.1))
		CovenantFx.orbit(ci, o, k * 1.78, CovenantFxData.RAY, 16, now * 0.25, Color(1.0, 1.0, 1.0, 0.5), true)
		if fight_phase >= 2 and CovenantFx.has(CovenantFxData.COLLAPSE_FLAME):
			for i in CovenantFxData.LAST_LIGHT_TONGUES:
				var a := TAU * float(i) / float(CovenantFxData.LAST_LIGHT_TONGUES) + now * 0.7
				CovenantFx.flame_tongue(ci, o + Vector2.from_angle(a) * k * 1.5, a, now, i % CovenantFxData.COLLAPSE_FLAME_FRAMES,
					Color(1.0, 1.0, 1.0, 0.85))
			CovenantFx.ring(ci, o, k * 1.55, CovenantFxData.COLLAPSE_EDGE, Color(1.0, 1.0, 1.0, 0.8), 3.0)
		return
	if fight_phase >= 1:
		ci.draw_circle(o, k * 2.0, Color(Palette.GOLD, 0.1))
		ci.draw_circle(o, k * 1.45, Color(Palette.IVORY, 0.1))
	if fight_phase >= 2:
		for i in 14:
			var a := TAU * float(i) / 14.0 + now * 0.7
			var f := 0.5 + 0.5 * sin(now * 11.0 + float(i) * 1.7)
			ci.draw_line(o + Vector2.from_angle(a) * k * 1.5, o + Vector2.from_angle(a) * k * (1.85 + 0.35 * f), Color(Palette.FLAME, 0.55 + 0.3 * f), 3.0)
		ci.draw_arc(o, k * 1.55, 0.0, TAU, 32, Color(Palette.FLAME, 0.7), 2.0)


## Two feathered wings spreading up and out behind her shoulders (wider and
## gold-edged in the Avatar form, with a slow beat).
static func _draw_wings(ci: CanvasItem, o: Vector2, k: float, flash: bool, avatar: bool, now: float) -> void:
	var beat := 0.06 * sin(now * (3.0 if avatar else 2.0))  # Gentle wing beat (rad).
	var span := 1.35 if avatar else 1.0  # Feather length multiplier.
	for side: float in [-1.0, 1.0]:
		var root := o + Vector2(side * k * 0.28, -k * 0.5)
		for j in 5:
			# Feathers fan from near-vertical to sideways, longest in the middle.
			var ang := -PI * 0.5 + side * (0.35 + 0.28 * float(j) + beat)
			var length := k * span * (1.1 + 0.35 * sin(PI * float(j + 1) / 6.0))
			var d := Vector2.from_angle(ang)
			var n := Vector2(-d.y, d.x) * k * 0.13
			var tip := root + d * length
			var feather := PackedVector2Array([root + n, tip + n * 0.4, tip + d * k * 0.12, tip - n * 0.4, root - n])
			ci.draw_colored_polygon(feather, _c(ROBE if j % 2 == 0 else Palette.IVORY.darkened(0.08), flash))
			feather.append(feather[0])
			ci.draw_polyline(feather, _c(Palette.GOLD if avatar else Palette.SILVER, flash), 1.5 if avatar else 1.0)


## The sun halo behind her head: a gold ring with rays (long rays and a
## soft disc in the Avatar form, slowly turning).
static func _draw_halo(ci: CanvasItem, c: Vector2, k: float, avatar: bool, now: float) -> void:
	var hr := k * (0.62 if avatar else 0.5)  # Halo ring radius.
	ci.draw_circle(c, hr, Color(Palette.GOLD, 0.22 if avatar else 0.14))
	var rays := 16 if avatar else 12
	for i in rays:
		var a := TAU * float(i) / float(rays) + now * 0.25
		var long := 0.55 if i % 2 == 0 else 0.3
		ci.draw_line(c + Vector2.from_angle(a) * hr, c + Vector2.from_angle(a) * hr * (1.0 + long * (1.4 if avatar else 1.0)), Color(Palette.GOLD, 0.85), 2.0)
	ci.draw_arc(c, hr, 0.0, TAU, 28, Color(Palette.GOLD, 0.95), 2.5)


## The relic staff in her front hand: a gold rod crowned by a radiant
## sunburst; raised and blazing while she casts, dim while she recovers.
static func _draw_staff(ci: CanvasItem, o: Vector2, k: float, flash: bool, pose: int, avatar: bool, now: float) -> void:
	var raise := k * (0.45 if pose == 1 else 0.0)
	var grip := o + Vector2(k * 0.62, k * 0.1 - raise * 0.5)
	var foot := o + Vector2(k * 0.72, k * 1.0 - raise)
	var top := o + Vector2(k * 0.8, -k * 1.45 - raise)
	ci.draw_line(foot, top, OUTLINE, 5.0)
	ci.draw_line(foot, top, _c(Palette.GOLD.darkened(0.15), flash), 3.0)
	ci.draw_circle(grip, k * 0.12, _c(SKIN, flash))  # Hand.
	var bright := 1.0 if pose == 1 else (0.45 if pose == 3 else 0.75)
	if avatar:
		bright = minf(1.0, bright + 0.25)
	var rr := k * (0.24 if pose != 1 else 0.3) * (1.25 if avatar else 1.0)  # Relic radius.
	ci.draw_circle(top, rr * 2.4, Color(Palette.GOLD, 0.18 * bright + 0.05 * sin(now * 6.0)))
	for i in 8:
		var a := TAU * float(i) / 8.0 + now * 0.8
		ci.draw_line(top + Vector2.from_angle(a) * rr, top + Vector2.from_angle(a) * rr * 2.0, Color(Palette.GOLD, 0.9 * bright), 2.0)
	ci.draw_circle(top, rr, _c(Palette.IVORY, flash))
	ci.draw_arc(top, rr, 0.0, TAU, 16, _c(Palette.GOLD, flash), 2.0)
	ci.draw_line(top + Vector2(0, -rr * 0.7), top + Vector2(0, rr * 0.7), _c(Palette.GOLD, flash), 2.0)  # Cross in the relic.
	ci.draw_line(top + Vector2(-rr * 0.5, -rr * 0.15), top + Vector2(rr * 0.5, -rr * 0.15), _c(Palette.GOLD, flash), 2.0)


## Light gathering on her (teleport glow, transformation): a white bloom
## that grows with `glow` (0..1).
static func _draw_glow(ci: CanvasItem, o: Vector2, k: float, glow: float) -> void:
	if glow <= 0.0:
		return
	if CovenantFx.has(CovenantFxData.T_FRONT):
		# Pixel art: the bloom as the shared disc texture under a white-gold ring.
		CovenantFx.soft_disc(ci, o, k * (0.9 + 0.8 * glow), Color(Palette.IVORY, 0.15 + 0.4 * glow))
		CovenantFx.ring(ci, o, k * (1.2 + 1.0 * glow), CovenantFxData.T_FRONT, Color(1.0, 1.0, 1.0, 0.4 + 0.5 * glow), 1.5)
		return
	ci.draw_circle(o, k * (0.9 + 0.8 * glow), Color(Palette.IVORY, 0.15 + 0.4 * glow))
	ci.draw_arc(o, k * (1.2 + 1.0 * glow), 0.0, TAU, 32, Color(Palette.GOLD, 0.4 + 0.5 * glow), 2.5)
