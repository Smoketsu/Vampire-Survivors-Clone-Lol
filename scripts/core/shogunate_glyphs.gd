## ShogunateGlyphs — code-drawn fallback shapes for the SHOGUNATE OF THE RISING
## SUN (Act V; GDD §15.0 "Act V foundation (phase 1)"), drawn when a kind has no
## sprite art (assets/sprites/shogunate/<kind>.png): lacquer-red and black
## armour, steel, indigo, sakura accents and lacquer-ink outlines (the lacquer,
## indigo and sakura ramps, never the undead's bone and soul teal). Also the Act
## V stubs' placeholder obstacles, among them the STONE LANTERN (`stone_lantern`)
## that the Sun's Course lights at night (its sprites obstacles/stone_lantern and
## obstacles/stone_lantern_lit when present), and the long dusk shadows every
## obstacle casts on an Act V stage (draw_long_shadow()). Every Shogunate kind
## without a shape of its own gets the plain ashigaru. Purely visual.
class_name ShogunateGlyphs
extends RefCounted

## Obstacle kind id of the stone lantern (the Sun's Course lights it at night).
const LANTERN: String = "stone_lantern"
## Sprite key of the unlit stone lantern (Agent B's art; the glyph when missing).
const LANTERN_ART: String = "obstacles/stone_lantern"
## Sprite key of the lit stone lantern.
const LANTERN_LIT_ART: String = "obstacles/stone_lantern_lit"
## Outline ink of the lacquer ramp (darkest).
const INK := Color(0.102, 0.043, 0.047)
## Steel (the existing grey ramp's light grey): blades, spear heads, the kanabō.
const STEEL := Color(0.72, 0.74, 0.78)
## Lantern stone grey.
const STONE := Color(0.46, 0.45, 0.43)


## Draws Shogunate kind `kind`. Returns false when `kind` is not a Shogunate kind
## (Glyphs.draw_enemy() then asks the Ancient Eye's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.shogunate_def(kind)  # Its design row ({} = not a Shogunate kind).
	if row.is_empty():
		return false
	# --- Act V: the Burning Province ---
	if ProvinceGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # The Kunoichi, the Kappa, Shuten-doji, Kage's shadows.
	# --- Act V: the Road to the Sun ---
	if SunRoadGlyphs.draw_enemy(ci, kind, o, r, flash):
		return true  # The Kitsune, her fox-fire, the Sōhei, the Kirin.
	match kind:
		"samurai":
			_samurai(ci, o, r, flash)
		"teppo_gunner":
			_teppo(ci, o, r, flash)
		"ninja":
			_ninja(ci, o, r, flash)
		"onryo":
			_onryo(ci, o, r, flash)
		"oni":
			_oni(ci, o, r, flash)
		_:
			_ashigaru(ci, o, r, flash)
	return true


## An Ashigaru: a lacquer-red do, a wide flat jingasa hat, a long yari.
static func _ashigaru(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.3), Vector2(r * 1.0, r * 1.25))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_LACQUER, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0, r * 0.55), Vector2(body.size.x, r * 0.18)), Glyphs._c(INK, flash))  # Sash.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.85), Vector2(r * 0.6, r * 0.55)), Glyphs._c(Color(0.86, 0.72, 0.58), flash))  # Face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.95, -r * 1.05), Vector2(r * 1.9, r * 0.3)), Glyphs._c(Palette.SHOGUN_LACQUER_DARK, flash))  # Jingasa.
	ci.draw_line(o + Vector2(r * 0.75, r * 1.0), o + Vector2(r * 0.75, -r * 2.0), INK, 2.0)  # Yari shaft.
	ci.draw_line(o + Vector2(r * 0.75, -r * 1.7), o + Vector2(r * 0.75, -r * 2.3), Glyphs._c(STEEL, flash), 2.0)


## A Samurai: black and red lacquered armour, a kabuto with a gold crescent, the
## katana at the hip.
static func _samurai(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.6, -r * 0.35), Vector2(r * 1.2, r * 1.35))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Color(0.10, 0.08, 0.09), flash))
	for k in 3:
		ci.draw_rect(Rect2(body.position + Vector2(r * 0.08, r * (0.1 + 0.35 * float(k))), Vector2(body.size.x - r * 0.16, r * 0.18)), Glyphs._c(Palette.SHOGUN_LACQUER, flash))  # Lacquered lames.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.05), Vector2(r * 0.9, r * 0.7)), INK)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.0), Vector2(r * 0.8, r * 0.5)), Glyphs._c(Color(0.14, 0.11, 0.12), flash))  # Kabuto.
	ci.draw_line(o + Vector2(-r * 0.55, -r * 1.35), o + Vector2(0, -r * 1.05), Glyphs._c(Palette.GOLD, flash), 2.0)  # Crescent crest.
	ci.draw_line(o + Vector2(r * 0.55, -r * 1.35), o + Vector2(0, -r * 1.05), Glyphs._c(Palette.GOLD, flash), 2.0)
	ci.draw_line(o + Vector2(r * 0.4, r * 0.55), o + Vector2(r * 1.3, r * 0.05), Glyphs._c(INK, flash), 3.0)  # Saya at the hip.
	ci.draw_line(o + Vector2(r * 0.35, r * 0.58), o + Vector2(r * 0.15, r * 0.7), Glyphs._c(Palette.SHOGUN_SAKURA_LIGHT, flash), 2.0)  # Hilt wrap.


## A Teppo Gunner: indigo and lacquer, an arquebus held level, a glowing match cord.
static func _teppo(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.35), Vector2(r * 1.1, r * 1.3))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_INDIGO, flash))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, r * 0.35)), Glyphs._c(Palette.SHOGUN_LACQUER, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.85), Vector2(r * 0.6, r * 0.5)), Glyphs._c(Color(0.86, 0.72, 0.58), flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 1.05), Vector2(r * 1.6, r * 0.25)), Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))  # Hat.
	ci.draw_line(o + Vector2(-r * 0.4, r * 0.15), o + Vector2(r * 1.6, r * 0.15), Glyphs._c(Color(0.35, 0.22, 0.12), flash), 3.0)  # The stock.
	ci.draw_line(o + Vector2(r * 0.6, r * 0.12), o + Vector2(r * 1.8, r * 0.12), Glyphs._c(STEEL, flash), 2.0)  # The barrel.
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, r * 0.3), Vector2(3, 3)), Glyphs._c(Palette.SHOGUN_LACQUER_LIGHT, flash))  # The match glow.


## A Ninja: indigo-black, masked, a shuriken in hand, an indigo-light rim (it must
## read on dark ground).
static func _ninja(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.3), Vector2(r * 1.0, r * 1.2))
	ci.draw_rect(body.grow(1.5), Glyphs._c(Palette.SHOGUN_INDIGO_LIGHT, flash))  # The rim.
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.95), Vector2(r * 0.8, r * 0.7)).grow(1.5), Glyphs._c(Palette.SHOGUN_INDIGO_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.95), Vector2(r * 0.8, r * 0.7)), Glyphs._c(Palette.SHOGUN_INDIGO_DARK, flash))  # Hood.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.7), Vector2(r * 0.6, r * 0.15)), Glyphs._c(Color(0.86, 0.72, 0.58), flash))  # Eye slit.
	var s := o + Vector2(r * 0.85, r * 0.1)  # The shuriken.
	ci.draw_line(s + Vector2(-3, 0), s + Vector2(3, 0), Glyphs._c(STEEL, flash), 2.0)
	ci.draw_line(s + Vector2(0, -3), s + Vector2(0, 3), Glyphs._c(STEEL, flash), 2.0)


## An Onryō: a pale ghost in a white burial kimono, long black hair over the face,
## no feet (a fading hem).
static func _onryo(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := Rect2(o + Vector2(-r * 0.55, -r * 0.4), Vector2(r * 1.1, r * 1.5))
	ci.draw_rect(robe, Glyphs._c(Color(0.92, 0.92, 0.95, 0.85), flash))
	ci.draw_rect(Rect2(robe.position + Vector2(0, robe.size.y * 0.75), Vector2(robe.size.x, robe.size.y * 0.25)), Glyphs._c(Color(0.92, 0.92, 0.95, 0.35), flash))  # Fading hem.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 1.05), Vector2(r * 1.0, r * 1.0)), Glyphs._c(Color(0.05, 0.05, 0.07), flash))  # Hair over the face.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 0.7), Vector2(r * 0.2, r * 0.45)), Glyphs._c(Color(0.85, 0.86, 0.9), flash))  # A sliver of pale face.
	ci.draw_line(o + Vector2(-r * 0.55, -r * 0.1), o + Vector2(-r * 1.0, r * 0.3), Glyphs._c(Color(0.92, 0.92, 0.95), flash), 2.0)  # Reaching arms.
	ci.draw_line(o + Vector2(r * 0.55, -r * 0.1), o + Vector2(r * 1.0, r * 0.3), Glyphs._c(Color(0.92, 0.92, 0.95), flash), 2.0)


## An Oni: a huge red-skinned ogre, horns, a tiger-skin loincloth, an iron kanabō.
static func _oni(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.7, -r * 0.55), Vector2(r * 1.4, r * 1.45))
	ci.draw_rect(body.grow(1.5), INK)
	ci.draw_rect(body, Glyphs._c(Palette.SHOGUN_LACQUER, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0, body.size.y * 0.62), Vector2(body.size.x, body.size.y * 0.22)), Glyphs._c(Color(0.85, 0.62, 0.20), flash))  # Tiger skin.
	for k in 3:
		ci.draw_rect(Rect2(body.position + Vector2(r * (0.2 + 0.45 * float(k)), body.size.y * 0.64), Vector2(r * 0.12, body.size.y * 0.18)), INK)  # Stripes.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 1.05), Vector2(r * 0.9, r * 0.6)), Glyphs._c(Palette.SHOGUN_LACQUER_DARK, flash))  # Head.
	ci.draw_line(o + Vector2(-r * 0.35, -r * 1.05), o + Vector2(-r * 0.55, -r * 1.45), Glyphs._c(Palette.BONE, flash), 3.0)  # Horns.
	ci.draw_line(o + Vector2(r * 0.35, -r * 1.05), o + Vector2(r * 0.55, -r * 1.45), Glyphs._c(Palette.BONE, flash), 3.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.85), Vector2(r * 0.6, r * 0.12)), Glyphs._c(Palette.GOLD, flash))  # Eyes.
	ci.draw_line(o + Vector2(r * 0.8, r * 0.7), o + Vector2(r * 1.15, -r * 1.2), Glyphs._c(Color(0.22, 0.22, 0.25), flash), 6.0)  # The kanabō.
	ci.draw_line(o + Vector2(r * 0.85, r * 0.4), o + Vector2(r * 1.15, -r * 1.2), Glyphs._c(STEEL, flash), 2.0)


## Draws one of the Act V stubs' placeholder obstacles (the stone lantern
## unlit, bamboo clumps, stone walls, torii pillars). Returns false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		LANTERN:
			_lantern_glyph(ci, o, false)
		"bamboo_clump":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			for k in 5:
				var p := c + Vector2.from_angle(TAU * float(k) / 5.0 + float(o.variant % 7) * 0.3) * r * 0.55  # One cane.
				ci.draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), INK)
				ci.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.42, 0.58, 0.28))
			SpriteBank.draw_disc(ci, c, r * 0.45, Color(0.30, 0.46, 0.22, 0.85))
		"stone_wall":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			ci.draw_rect(rect.grow(-1.5), Color(0.36, 0.35, 0.34))
			var step := 12.0  # Stone courses (px).
			var y := rect.position.y + step
			while y < rect.end.y - 2.0:
				ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Color(0.24, 0.23, 0.23), 1.0)
				y += step
			ci.draw_line(rect.position + Vector2(2, 3), Vector2(rect.end.x - 2, rect.position.y + 3), Color(0.55, 0.54, 0.52), 1.0)
		"torii_pillar":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.SHOGUN_LACQUER)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.3, Palette.SHOGUN_LACQUER_LIGHT)
		_:
			return false
	return true


## Act V: draws a stone lantern from its sprite (lit at night when the Sun's
## Course `sun` has it lit, else unlit), or its glyph when no art exists.
## Placed like EnvironmentArt.draw_obstacle(): centred on the collision shape,
## its bottom on the shape's bottom. Returns false for any other kind (the
## Arena then draws it the usual way).
static func draw_lantern(ci: CanvasItem, o: Arena.Obstacle, sun: SunCourse) -> bool:
	if o.kind != LANTERN:
		return false
	var key := Vector2i(floori(o.center.x / ArenaData.CELL), floori(o.center.y / ArenaData.CELL))  # Its arena cell.
	var on := sun != null and sun.is_lit(key)
	var tex := EnvironmentArt.texture(LANTERN_LIT_ART if on else LANTERN_ART)
	if tex == null and on:
		tex = EnvironmentArt.texture(LANTERN_ART)  # Lit, but no lit sprite yet: the unlit one and a glow dot.
	if tex == null:
		_lantern_glyph(ci, o, on)
		return true
	SpriteBank.apply_sharp(ci)
	var base_y := o.center.y + o.radius + float(EnvironmentArtData.OBSTACLE_FOOT_OFFSET)  # Sprite bottom edge.
	SpriteBank.draw_disc(ci, Vector2(o.center.x + 2.0, base_y - 2.0), o.radius, Color(0, 0, 0, 0.3))
	var size := Vector2(float(tex.get_width()), float(tex.get_height()))  # 1 art px = 1 layout px.
	ci.draw_texture_rect(tex, Rect2(Vector2(o.center.x - size.x * 0.5, base_y - size.y).round(), size), false)
	return true


## The stone lantern's glyph: a grey tōrō seen from above, its window warm when lit.
static func _lantern_glyph(ci: CanvasItem, o: Arena.Obstacle, lit: bool) -> void:
	var c := o.center
	var r := o.radius
	SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), INK)
	ci.draw_rect(Rect2(c - Vector2(r, r) + Vector2(1.5, 1.5), Vector2(r, r) * 2.0 - Vector2(3, 3)), STONE)
	ci.draw_rect(Rect2(c - Vector2(r * 0.55, r * 0.55), Vector2(r, r) * 1.1), Color(0.33, 0.32, 0.31))  # The roof cap.
	var win := Rect2(c - Vector2(r * 0.3, r * 0.3), Vector2(r, r) * 0.6)  # The fire box's window.
	ci.draw_rect(win, Palette.FLAME if lit else Color(0.12, 0.11, 0.11))
	if lit:
		ci.draw_rect(win.grow(-r * 0.12), Palette.GOLD)


## Act V: the long shadow obstacle `o` casts at dusk (none by day; it fades as
## night falls), along the sinking sun's way (SUN sun_dir), drawn under the
## obstacle on the Arena's layer as a stretched soft disc (a texture, which
## batches). Visual only.
static func draw_long_shadow(ci: CanvasItem, o: Arena.Obstacle, sun: SunCourse) -> void:
	if sun == null:
		return
	var k := sun.dusk_amount()  # 0 .. full dusk.
	if k <= 0.02:
		return
	var dir := sun.shadow_dir()  # SUN sun_dir, or the sky override's (Act V, the Road to the Sun).
	var ext := o.radius if o.is_circle else maxf(o.half.x, o.half.y)  # Its size (px).
	var length := ext + float(sun.cfg["shadow_len"]) * k  # Shadow length (px).
	ci.draw_set_transform(o.center + dir * length * 0.6, dir.angle(), Vector2(length / maxf(ext, 1.0), 0.7))
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(ext, ext), Vector2(ext, ext) * 2.0), false, Color(0.05, 0.02, 0.05, 0.32 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
