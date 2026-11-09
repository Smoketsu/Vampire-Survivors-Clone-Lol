## HostGlyphs — code-drawn fallback shapes for THE CELESTIAL HOST (temporary
## Act XIII; GDD §15.0 "The Celestial Host foundation (phase 1)"), drawn when a
## kind has no sprite art (assets/sprites/host/<kind>.png): starlight white,
## pale silver, cerulean and dawn rose against the deep night blue ink; never
## crimson, never warm gold, never the necromancer's violet. Inhuman shapes:
## mirror masks, many wings, thin halos (each kit draws its own halo over the
## body). Also the stubs' placeholder obstacles (white pillars, cloud-wrapped
## stair blocks, sphere crystals, standing petals). Every Host kind without a
## shape of its own gets the Virtue. Discs are textures (SpriteBank.draw_disc),
## the rest plain rects: no polygon redrawn every frame. Purely visual.
class_name HostGlyphs
extends RefCounted

## Outline ink (the night blue, darkest).
const INK := Palette.HOST_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Host kind `kind`. Returns false when `kind` is not a Host kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.host_def(kind)  # Its design row ({} = not a Host kind).
	if row.is_empty():
		return false
	# Phase 2: each Host stage's own fallbacks go here, before the shared
	# kinds' (as CourtGlyphs asks RavensmoorGlyphs first).
	match kind:
		# --- Act XIII (temporary number): the Silver Stair ---
		"cherub", "cherub_of_the_gate":
			_cherub(ci, o, r, flash)
		# --- Act XIII (temporary number): the Wheel of Thrones ---
		"ophan":
			_ophan(ci, o, r, flash)
		"dominion_of_the_spheres":
			for k in 3:
				SpriteBank.draw_disc(ci, o + Vector2((float(k) - 1.0) * r * 0.9, r * 0.6), r * 0.22, Glyphs._c(Color(Palette.HOST_CERULEAN, 0.6), flash))  # Crystal rings about him.
			_angel(ci, o, r, flash, Palette.HOST_SILVER, Palette.HOST_CERULEAN, false)
			ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 1.1), Vector2(2.0, r * 1.8)), Glyphs._c(Palette.HOST_STARLIGHT, flash))  # The sceptre.
		"lesser_light":
			_light(ci, o, r, flash)
		"power":
			_angel(ci, o, r, flash, Palette.HOST_STARLIGHT, Palette.HOST_ROSE, true)
		"choir_angel":
			_angel(ci, o, r, flash, Palette.HOST_CLOUD, Palette.HOST_ROSE, false)
		"herald":
			_angel(ci, o, r, flash, Palette.HOST_SILVER, Palette.HOST_CERULEAN, false)
			ci.draw_rect(Rect2(o + Vector2(r * 0.4, -r * 0.5), Vector2(r * 1.1, 2.0)), Glyphs._c(Palette.HOST_SILVER, flash))  # The trumpet.
		"dominion":
			_angel(ci, o, r, flash, Palette.HOST_SILVER, Palette.HOST_CERULEAN, false)
			ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 1.1), Vector2(2.0, r * 1.8)), Glyphs._c(Palette.HOST_STARLIGHT, flash))  # The sceptre.
		"judge":
			_angel(ci, o, r, flash, Palette.HOST_SILVER_DARK, Palette.HOST_ROSE, true)
		_:
			_angel(ci, o, r, flash, Palette.HOST_SILVER, Palette.HOST_CERULEAN, false)
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 1.3), Vector2(1.5, r * 2.2)), Glyphs._c(Palette.HOST_SILVER_DARK, flash))  # The Virtue's spear.
	return true


## A lesser light: a small orb of starlight with two tiny wings.
static func _light(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for s: float in [-1.0, 1.0]:
		SpriteBank.draw_disc(ci, o + Vector2(s * r * 0.75, -r * 0.2), r * 0.45, Glyphs._c(Color(Palette.HOST_CLOUD, 0.8), flash))  # A wing.
	SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.65, Glyphs._c(Palette.HOST_STARLIGHT, flash))
	SpriteBank.draw_disc(ci, o, r * 0.3, Glyphs._c(Palette.HOST_CERULEAN, flash))  # Its heart.


# --- Act XIII (temporary number): the Silver Stair ---
## A Cherub (and the Cherub of the Gate): four wings spread like a cross, each
## marked with eyes, a round body of four faces and a white-flame sword at its
## side (rects and disc textures; the turning sword is CherubKit's).
static func _cherub(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for d: Vector2 in [Vector2(-1.0, -0.5), Vector2(1.0, -0.5), Vector2(-0.8, 0.4), Vector2(0.8, 0.4)]:
		var wc := o + d * r * 0.9
		ci.draw_rect(Rect2(wc - Vector2(r * 0.5, r * 0.25), Vector2(r, r * 0.5)), Glyphs._c(Color(Palette.HOST_CLOUD, 0.9), flash))  # A wing.
		SpriteBank.draw_disc(ci, wc, r * 0.1, Glyphs._c(Palette.HOST_CERULEAN, flash))  # An eye on it.
	SpriteBank.draw_disc(ci, o, r * 0.62, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.55, Glyphs._c(Palette.HOST_SILVER, flash))
	for f: Vector2 in [Vector2(0.0, -0.3), Vector2(0.3, 0.0), Vector2(0.0, 0.3), Vector2(-0.3, 0.0)]:
		SpriteBank.draw_disc(ci, o + f * r, r * 0.13, Glyphs._c(Palette.HOST_STARLIGHT, flash))  # The four faces.
	ci.draw_rect(Rect2(o + Vector2(r * 0.7, -r * 1.1), Vector2(2.5, r * 1.6)), Glyphs._c(Palette.HOST_STARLIGHT, flash))  # The flaming sword.


# --- Act XIII (temporary number): the Wheel of Thrones ---
## An Ophan: a silver wheel within a wheel, its rims marked with eyes, a
## cerulean fire between them (disc textures only; its roll's turning eyes are
## OphanKit's).
static func _ophan(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.05, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.98, Glyphs._c(Color(Palette.HOST_CERULEAN, 0.7), flash))
	SpriteBank.draw_disc(ci, o, r * 0.6, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.5, Glyphs._c(Palette.HOST_SILVER, flash))
	for i in 8:
		SpriteBank.draw_disc(ci, o + Vector2.from_angle(TAU * float(i) / 8.0) * r * 0.8, r * 0.1, Glyphs._c(Palette.HOST_STARLIGHT, flash))  # Eyes on the rim.
	SpriteBank.draw_disc(ci, o, r * 0.14, Glyphs._c(Palette.HOST_CERULEAN, flash))


## An angel: a robed body, two pairs of wings behind it, a mirror-mask head;
## `blade` adds a white-flame blade (the Power, the Judge).
static func _angel(ci: CanvasItem, o: Vector2, r: float, flash: bool, robe: Color, sash: Color, blade: bool) -> void:
	for s: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(o + Vector2(s * r * 0.5 - (r * 0.9 if s < 0.0 else 0.0), -r * 0.9), Vector2(r * 0.9, r * 0.5)), Glyphs._c(Color(Palette.HOST_CLOUD, 0.85), flash))  # Upper wing.
		ci.draw_rect(Rect2(o + Vector2(s * r * 0.5 - (r * 0.7 if s < 0.0 else 0.0), -r * 0.3), Vector2(r * 0.7, r * 0.4)), Glyphs._c(Color(Palette.HOST_SILVER, 0.85), flash))  # Lower wing.
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.5), Vector2(r * 1.0, r * 1.5))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(robe, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0.0, r * 0.5), Vector2(body.size.x, 2.0)), Glyphs._c(sash, flash))  # The sash.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 0.45, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 0.38, Glyphs._c(Palette.HOST_SILVER, flash))  # The mirror mask.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 0.9), Vector2(r * 0.25, 1.5)), Glyphs._c(Palette.HOST_STARLIGHT, flash))  # Its glint.
	if blade:
		ci.draw_rect(Rect2(o + Vector2(r * 0.55, -r * 1.2), Vector2(2.5, r * 1.6)), Glyphs._c(Palette.HOST_STARLIGHT, flash))  # White flame.
		ci.draw_rect(Rect2(o + Vector2(r * 0.55 - 1.0, -r * 1.2), Vector2(1.0, r * 1.4)), Glyphs._c(Palette.HOST_CERULEAN, flash))


# =====================================================================================
# Obstacles (the stubs' placeholders)
# =====================================================================================

## Draws obstacle `o` when it is a Host stub's kind; false otherwise.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	# Phase 2: each Host stage's own obstacle glyphs go here first.
	var c := o.center
	match o.kind:
		"host_pillar":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.3))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.HOST_CLOUD)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Palette.HOST_STARLIGHT)
			SpriteBank.draw_disc(ci, c, r * 0.5, Color(Palette.HOST_CERULEAN, 0.4))  # A band of light.
		"host_cloudstone", "host_crystal", "host_petal":
			var rect := Rect2(c - o.half, o.half * 2.0)
			var face := Palette.HOST_SILVER  # A block of the stair.
			var line := Palette.HOST_CLOUD
			if o.kind == "host_crystal":
				face = Palette.HOST_CERULEAN_DARK
				line = Palette.HOST_CERULEAN  # A shard of a sphere.
			elif o.kind == "host_petal":
				face = Palette.HOST_STARLIGHT
				line = Palette.HOST_ROSE  # A standing petal of light.
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), face)
			ci.draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2(rect.size.x - 4.0, 2.0)), Color(line, 0.85))  # Its lit edge.
		_:
			return false
	return true
