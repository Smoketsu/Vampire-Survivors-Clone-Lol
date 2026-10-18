## HarbourGlyphs — code-drawn shapes of Gullhaven Harbour (Act II, GDD §15.0
## "Gullhaven Harbour (Act II phase 2)"): the fallback bodies of the stage's
## kinds when their sprite art (assets/sprites/eye/<kind>.png,
## structures/<kind>.png) is missing (EyeGlyphs.draw_enemy() asks here first),
## the obstacles without obstacle art (Arena), the piers (HarbourDirector), and
## the kits' telegraph accents (the Netcaster's net, the Tide Caller's water
## line, the Harbourmaster's anchor and chain), plus Abbot Merrow's fallback
## (BossMerrow). Palette: the Eye's drowned teal and bioluminescent violet,
## bone and wet wood. Purely visual.
class_name HarbourGlyphs
extends RefCounted

## Wet wood of the piers, crates and posts.
const WOOD := Color(0.30, 0.22, 0.15)
## Darker wood (planks' joints).
const WOOD_DARK := Color(0.18, 0.13, 0.09)
## Salt-white of foam, nets and rope.
const SALT := Color(0.78, 0.82, 0.76)
## Scaled hide of the Deep Kin.
const HIDE := Color(0.20, 0.36, 0.34)
## Rust of the anchor and chains.
const RUST := Color(0.45, 0.28, 0.18)


## Draws Harbour kind `kind` at `o` (body radius `r`); false when it is none
## of them (EyeGlyphs then draws its plain cultist).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"deep_kin", "deep_herald":
			_deep_kin(ci, o, r, flash, kind == "deep_herald")
		"harbourmaster":
			_deep_kin(ci, o, r, flash, false)
			draw_anchor(ci, o + Vector2(r * 0.9, r * 0.2), r * 0.7, flash)
		"tide_caller":
			EyeGlyphs._cultist(ci, o, r, flash)
			var top := o + Vector2(r * 1.0, -r * 1.4)  # Conch staff head.
			ci.draw_line(o + Vector2(r * 0.9, r * 0.8), top, Glyphs._c(Palette.BONE, flash), 2.0)
			ci.draw_circle(top, r * 0.32, Glyphs._c(Palette.EYE_DROWNED, flash))
			ci.draw_arc(top, r * 0.42, 0.0, TAU, 12, Glyphs._c(SALT, flash), 1.0)
		"netcaster":
			EyeGlyphs._cultist(ci, o, r, flash)
			for i in 3:  # A weighted net over the arm.
				ci.draw_line(o + Vector2(r * 0.4, -r * 0.2 + float(i) * r * 0.35), o + Vector2(r * 1.3, r * 0.1 + float(i) * r * 0.35), Glyphs._c(SALT, flash), 1.0)
			ci.draw_line(o + Vector2(r * 0.6, -r * 0.3), o + Vector2(r * 0.9, r * 0.9), Glyphs._c(SALT, flash), 1.0)
		"bell_buoy":
			ci.draw_circle(o + Vector2(0, r * 0.4), r * 0.95, Glyphs.OUTLINE)
			ci.draw_circle(o + Vector2(0, r * 0.4), r * 0.85, Glyphs._c(Palette.CRIMSON.darkened(0.3), flash))  # Float.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 1.3), Vector2(r * 0.3, r * 1.5)), Glyphs._c(RUST, flash))  # Cage.
			ci.draw_circle(o + Vector2(0, -r * 1.2), r * 0.42, Glyphs._c(Palette.GOLD.darkened(0.3), flash))  # Bell.
		"smuggler_cache":
			var box := Rect2(o - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6))
			ci.draw_rect(box.grow(1.0), Glyphs.OUTLINE)
			ci.draw_rect(box, Glyphs._c(WOOD, flash))
			ci.draw_line(box.position + Vector2(0, box.size.y * 0.5), box.end - Vector2(0, box.size.y * 0.5), Glyphs._c(RUST, flash), 2.0)
			ci.draw_rect(Rect2(o - Vector2(r * 0.2, r * 0.25), Vector2(r * 0.4, r * 0.5)), Glyphs._c(Palette.GOLD.darkened(0.2), flash))  # Lock.
		_:
			return false
	return true


## A hunched, scaled fisherman halfway into the sea (Deep Kin family).
static func _deep_kin(ci: CanvasItem, o: Vector2, r: float, flash: bool, herald: bool) -> void:
	var hide := HIDE.darkened(0.3) if herald else HIDE
	ci.draw_circle(o, r * 1.0, Glyphs.OUTLINE)
	ci.draw_circle(o, r * 0.9, Glyphs._c(hide, flash))
	ci.draw_circle(o + Vector2(r * 0.35, -r * 0.55), r * 0.45, Glyphs._c(hide.lightened(0.15), flash))  # Head.
	ci.draw_circle(o + Vector2(r * 0.55, -r * 0.62), r * 0.1, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))  # Eye.
	for i in 3:  # Fin ridge.
		ci.draw_line(o + Vector2(-r * 0.5 + float(i) * r * 0.3, -r * 0.8), o + Vector2(-r * 0.35 + float(i) * r * 0.3, -r * 1.2), Glyphs._c(Palette.EYE_DROWNED, flash), 2.0)
	if herald:
		ci.draw_arc(o, r * 1.25, 0.0, TAU, 20, Color(Palette.EYE_BIOLUME, 0.6), 2.0)


## A ship's anchor (the Harbourmaster's weapon, also its hurl in flight).
static func draw_anchor(ci: CanvasItem, o: Vector2, s: float, flash: bool) -> void:
	var c := Glyphs._c(RUST, flash)
	ci.draw_line(o + Vector2(0, -s), o + Vector2(0, s), c, 3.0)
	ci.draw_line(o + Vector2(-s * 0.5, -s * 0.6), o + Vector2(s * 0.5, -s * 0.6), c, 2.0)
	ci.draw_arc(o, s, 0.3, PI - 0.3, 10, c, 3.0)
	ci.draw_circle(o + Vector2(0, -s * 1.1), s * 0.22, Glyphs._c(RUST.darkened(0.3), flash))


## A taut chain from `a` to `b` (links every 7 px).
static func draw_chain(ci: CanvasItem, a: Vector2, b: Vector2) -> void:
	var d := b - a
	var n := maxi(1, int(d.length() / 7.0))
	ci.draw_line(a, b, Color(RUST.darkened(0.4), 0.9), 2.0)
	for i in n:
		ci.draw_circle(a + d * (float(i) + 0.5) / float(n), 1.6, RUST)


## A net drawn over a pinned body at `o` (radius `r`), fading with `alpha`.
static func draw_net(ci: CanvasItem, o: Vector2, r: float, alpha: float) -> void:
	var c := Color(SALT, 0.85 * alpha)
	var rr := r * 1.25
	for i in 5:
		var k := (float(i) / 4.0 - 0.5) * 2.0 * rr
		ci.draw_line(o + Vector2(k, -rr), o + Vector2(k * 0.6, rr), c, 1.0)
		ci.draw_line(o + Vector2(-rr, k), o + Vector2(rr, k * 0.6), c, 1.0)
	ci.draw_arc(o, rr, 0.0, TAU, 16, c, 1.0)
	for i in 4:  # Lead weights on the rim.
		ci.draw_circle(o + Vector2.from_angle(TAU * float(i) / 4.0 + 0.4) * rr, 1.8, Color(Palette.STONE, alpha))


## The Tide Caller's rising water line, from `a` to `b`, `w` px wide, at
## height 0..1 `k` (0 = telegraph only, 1 = full crest).
static func draw_water_line(ci: CanvasItem, a: Vector2, b: Vector2, w: float, k: float) -> void:
	var c := Color(Palette.EYE_DROWNED.lightened(0.2), 0.35 + 0.5 * k)
	ci.draw_line(a, b, c, w * (0.4 + 0.6 * k))
	ci.draw_line(a, b, Color(SALT, 0.3 + 0.6 * k), maxf(2.0, w * 0.25 * k))


## A pier: planks across a frame, `half_len` x `half_w` px around `c` along `dir`.
static func draw_pier(ci: CanvasItem, c: Vector2, dir: Vector2, half_len: float, half_w: float) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var corners := PackedVector2Array([c - dir * half_len - perp * half_w, c + dir * half_len - perp * half_w,
		c + dir * half_len + perp * half_w, c - dir * half_len + perp * half_w])
	ci.draw_colored_polygon(corners, WOOD)
	var n := int(half_len * 2.0 / 8.0)  # Planks 8 px apart.
	for i in n + 1:
		var q := c - dir * half_len + dir * float(i) * 8.0
		ci.draw_line(q - perp * half_w, q + perp * half_w, WOOD_DARK, 1.0)
	corners.append(corners[0])
	ci.draw_polyline(corners, WOOD_DARK.darkened(0.4), 2.0)
	for s in [-1.0, 1.0]:  # Pilings along both sides.
		for i in 3:
			ci.draw_circle(c - dir * half_len * 0.8 + dir * half_len * 0.8 * float(i) + perp * half_w * float(s), 3.0, WOOD_DARK)


## Draws Harbour obstacle `o` on the Arena layer; false when its kind is not
## one of the Harbour's (Arena keeps its own glyph).
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	var r := o.radius
	var dark := Color(0.06, 0.07, 0.08)
	match o.kind:
		"mooring_post", "bollard":
			ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, WOOD if o.kind == "mooring_post" else Palette.STONE)
			ci.draw_arc(c, r * 0.6, 0.0, TAU, 12, SALT.darkened(0.4), 1.5)
		"wreck_ribs":
			for i in 5:  # Ribs of a wrecked boat.
				var a := -PI * 0.9 + PI * 0.8 * float(i) / 4.0
				ci.draw_line(c, c + Vector2.from_angle(a) * r, WOOD_DARK, 4.0)
				ci.draw_line(c, c + Vector2.from_angle(a) * r, WOOD, 2.0)
			ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), WOOD_DARK, 5.0)
		"net_pile", "lobster_pots":
			ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, Color(0.30, 0.28, 0.22))
			draw_net(ci, c, r * 0.7, 0.8)
		"fish_stall":
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, WOOD)
			for i in 6:  # Striped awning.
				ci.draw_arc(c, r * 0.7, TAU * float(i) / 6.0, TAU * (float(i) + 0.5) / 6.0, 6, Palette.CRIMSON.darkened(0.4), r * 0.5)
		"barrel_stack", "crate_stack":
			ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, WOOD)
			ci.draw_arc(c, r * 0.55, 0.0, TAU, 12, WOOD_DARK, 2.0)
		"drowned_idol", "coral_pillar", "anchor_monument", "tide_font":
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c, r - 1.5, Color(0.26, 0.30, 0.30))
			if o.kind == "anchor_monument":
				draw_anchor(ci, c, r * 0.6, false)
			elif o.kind == "tide_font":
				ci.draw_circle(c, r * 0.65, Palette.EYE_DROWNED_DARK)
			else:
				ci.draw_circle(c + Vector2(0, -r * 0.3), r * 0.25, Palette.EYE_BIOLUME)
		_:
			return false
	return true


## Abbot Merrow's fallback body: robed (`changed` false) or shed of his robes
## (long whipping limbs); `pose` 1 = preaching / winding up.
static func draw_merrow(ci: CanvasItem, o: Vector2, r: float, flash: bool, pose: int, changed: bool) -> void:
	if changed:
		for i in 4:  # Whipping limbs.
			var a := -PI * 0.15 + float(i) * 0.5 + (0.3 if pose == 1 else 0.0)
			var tip := o + Vector2.from_angle(a) * r * 2.2
			ci.draw_line(o, o.lerp(tip, 0.5) + Vector2(0, -r * 0.3), Glyphs._c(HIDE, flash), 4.0)
			ci.draw_line(o.lerp(tip, 0.5) + Vector2(0, -r * 0.3), tip, Glyphs._c(HIDE.lightened(0.2), flash), 3.0)
		ci.draw_circle(o, r * 0.95, Glyphs.OUTLINE)
		ci.draw_circle(o, r * 0.85, Glyphs._c(HIDE, flash))
	else:
		var robe := PackedVector2Array([o + Vector2(-r, r), o + Vector2(r, r), o + Vector2(r * 0.6, -r * 0.4), o + Vector2(-r * 0.6, -r * 0.4)])
		ci.draw_colored_polygon(robe, Glyphs._c(Palette.EYE_DROWNED_DARK, flash))
		ci.draw_rect(Rect2(o + Vector2(-r * 0.12, -r * 0.3), Vector2(r * 0.24, r * 1.2)), Glyphs._c(Palette.BONE.darkened(0.2), flash))  # Stole.
	ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.5, Glyphs._c(Palette.BONE.darkened(0.35), flash))  # Head.
	ci.draw_circle(o + Vector2(r * 0.15, -r * 0.75), r * 0.12, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
	if pose == 1 and not changed:
		ci.draw_line(o + Vector2(-r * 0.6, -r * 0.2), o + Vector2(-r * 0.9, -r * 1.4), Glyphs._c(Palette.BONE, flash), 2.0)  # Raised arms.
		ci.draw_line(o + Vector2(r * 0.6, -r * 0.2), o + Vector2(r * 0.9, -r * 1.4), Glyphs._c(Palette.BONE, flash), 2.0)
