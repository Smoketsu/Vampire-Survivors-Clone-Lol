## UnderworldGlyphs — code-drawn shapes of THE ASPHODEL UNDERWORLD (Act IV, Stage
## 12; GDD §15.0 "The Asphodel Underworld (Act IV phase 2)"): the fallbacks of
## its obstacles (their obstacles/<kind>_<size> PNGs replace them), Cerberus
## (his pantheon/cerberus sprite with a dead head shown as a smoking stump),
## Hades (bosses/hades), and the marks of his fight: the Helm of Darkness's
## shimmer and footprints, the sigil over a marked summon, the gods' shades,
## the kneeling Lord of the Dead and his crown, and the River Styx (drawn by
## UnderworldGround). The Underworld's colours: grey ash, marble shades, cold
## Aegean light, dark bronze, Hades' black; never the undead's bone and teal on
## an enemy. Purely visual; no RNG.
class_name UnderworldGlyphs
extends RefCounted

## Outline ink (the bronze ramp's darkest).
const INK := Color(0.118, 0.078, 0.031)
## Hades' robe black.
const HADES_BLACK := Color(0.07, 0.06, 0.09)
## Styx water, deep (the river's body).
const STYX_DEEP := Color(0.02, 0.03, 0.05)
## Styx water near the banks.
const STYX_SHALLOW := Color(0.06, 0.09, 0.12)
## The river's cold glints.
const STYX_GLINT := Color(0.36, 0.55, 0.70)


# =====================================================================================
# Obstacles
# =====================================================================================

## Draws an Underworld obstacle kind; false for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"grave_stele", "judgement_bench":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, INK)
			var stone := Palette.PANTHEON_MARBLE_DARK if o.kind == "grave_stele" else Palette.PANTHEON_MARBLE
			ci.draw_rect(rect.grow(-1.5), stone)
			ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, 3)), Palette.PANTHEON_MARBLE_LIGHT)
			if o.kind == "judgement_bench":
				ci.draw_rect(Rect2(rect.position + Vector2(2, rect.size.y - 5), Vector2(rect.size.x - 4, 3)), Palette.PANTHEON_BRONZE_DARK)
		"dead_poplar":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Color(0.22, 0.21, 0.22))
			for i in 5:
				var a := TAU * float(i) / 5.0 + 0.3
				ci.draw_line(c, c + Vector2.from_angle(a) * r * 1.4, Color(0.30, 0.28, 0.28), 1.5)  # Bare branches.
		"ferry_post", "soul_brazier":
			var r := o.radius
			ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			ci.draw_circle(c, r - 1.5, Palette.PANTHEON_BRONZE_DARK if o.kind == "ferry_post" else Palette.PANTHEON_BRONZE)
			ci.draw_circle(c, r * 0.45, STYX_GLINT if o.kind == "ferry_post" else Palette.PANTHEON_AEGEAN_LIGHT)  # A lantern / a cold soul flame.
		"styx_rock", "judges_column", "obsidian_spire":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, INK)
			var body := Color(0.20, 0.21, 0.23)
			match o.kind:
				"judges_column":
					body = Palette.PANTHEON_MARBLE
				"obsidian_spire":
					body = Color(0.10, 0.08, 0.13)
			ci.draw_circle(c, r - 1.5, body)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, body.lightened(0.25))
		_:
			return false
	return true


# =====================================================================================
# The River Styx (UnderworldGround)
# =====================================================================================

## Draws the river bands with settings `s` (UnderworldStage.UNDERWORLD "styx")
## crossing `rect`: dark water between pale banks, a few cold glints. `t` is
## game time (the glints drift).
static func draw_styx(ci: CanvasItem, rect: Rect2, s: Dictionary, t: float) -> void:
	var period := float(s["period"])
	var amp := float(s["amplitude"])
	var wl := float(s["wavelength"])
	var ph := float(s["phase_step"])
	var hw := float(s["half_width"])
	var k0 := floori((rect.position.y - amp - hw) / period)
	var k1 := ceili((rect.end.y + amp + hw) / period)
	var stepx := 24.0  # px between two samples of the bank line.
	for k in range(k0, k1 + 1):
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		var x := floorf(rect.position.x / stepx) * stepx
		while x <= rect.end.x + stepx:
			var cy := UnderworldDirector.river_centre_y(x, k, period, amp, wl, ph)
			top.append(Vector2(x, cy - hw))
			bottom.append(Vector2(x, cy + hw))
			x += stepx
		if top.size() < 2:
			continue
		var poly := top.duplicate()
		for i in range(bottom.size() - 1, -1, -1):
			poly.append(bottom[i])
		ci.draw_colored_polygon(poly, STYX_SHALLOW)
		# The deep channel: the middle half of the river.
		var deep := PackedVector2Array()
		for i in top.size():
			deep.append(top[i].lerp(bottom[i], 0.25))
		for i in range(bottom.size() - 1, -1, -1):
			deep.append(top[i].lerp(bottom[i], 0.75))
		ci.draw_colored_polygon(deep, STYX_DEEP)
		ci.draw_polyline(top, Color(Palette.PANTHEON_MARBLE_DARK, 0.55), 2.0)
		ci.draw_polyline(bottom, Color(Palette.PANTHEON_MARBLE_DARK, 0.55), 2.0)
		# Cold glints drifting down the river.
		for i in range(0, top.size(), 3):
			var q := top[i].lerp(bottom[i], 0.5 + 0.3 * sin(float(i) * 1.7 + float(k)))
			var drift := fmod(t * 14.0 + float(i) * 37.0, stepx * 3.0)
			ci.draw_line(q + Vector2(drift - 8.0, 0.0), q + Vector2(drift, 0.0), Color(STYX_GLINT, 0.45), 1.0)


# =====================================================================================
# Cerberus
# =====================================================================================

## Cerberus (CerberusKit) in his node's local space: his sprite, else a black
## hound with three heads; a dead head is a smoking stump; `breathing` adds the
## fire at the left head's jaws. `dead` = per head (0..2).
static func draw_cerberus(ci: CanvasItem, e: Enemy, dead: Array[bool], breathing: bool, flash: bool) -> void:
	var r := e.radius
	var offs: Array = e.kit.d["head_offsets"] if e.kit != null else []
	if not SpriteBank.draw(ci, "pantheon/cerberus", Vector2.ZERO, flash):
		# Body: a long black hound, a mane of dull fire.
		ci.draw_circle(Vector2(0, r * 0.15), r * 1.02, INK)
		ci.draw_circle(Vector2(0, r * 0.15), r * 0.92, Glyphs._c(Color(0.10, 0.09, 0.10), flash))
		for i in 4:
			var lx := -r * 0.6 + float(i) * r * 0.4
			ci.draw_rect(Rect2(Vector2(lx - 3.0, r * 0.7), Vector2(6.0, r * 0.5)), Glyphs._c(Color(0.08, 0.07, 0.08), flash))
		for i in offs.size():
			var o: Vector2 = offs[i]
			ci.draw_circle(o, 10.0, INK)
			ci.draw_circle(o, 8.5, Glyphs._c(Color(0.13, 0.11, 0.12), flash))
			ci.draw_circle(o + Vector2(3.0, -1.0), 1.8, Palette.FLAME)  # An ember eye.
			ci.draw_arc(o, 11.0, PI * 1.1, PI * 1.9, 8, Color(Palette.FLAME, 0.6), 2.0)  # The fiery mane.
	for i in mini(offs.size(), dead.size()):
		if dead[i]:
			var o: Vector2 = offs[i]
			ci.draw_circle(o, 9.0, Color(0.03, 0.03, 0.04, 0.85))  # The head is a dark stump.
			var t := e.game.elapsed if e.game != null else 0.0
			for k in 3:
				var rise := fmod(t * 18.0 + float(k) * 9.0, 26.0)
				ci.draw_circle(o + Vector2(sin(t * 2.0 + float(k)) * 3.0, -rise), 3.0 + rise * 0.15, Color(0.35, 0.35, 0.38, 0.5 * (1.0 - rise / 26.0)))  # Smoke.
	if breathing and offs.size() > 0 and not dead[0]:
		var o0: Vector2 = offs[0]
		ci.draw_circle(o0 + Vector2(10.0, 2.0), 5.0, Color(Palette.FLAME, 0.8))


# =====================================================================================
# Hades
# =====================================================================================

## Hades without art at `o` (radius `r`): a tall black-robed god with a dark
## bronze crown, a pale grey face, cold Aegean fire in his hair and a bronze
## bident; pose 1 raises the bident. `alpha` fades him (his rise).
static func draw_hades(ci: CanvasItem, o: Vector2, r: float, flash: bool, alpha: float, pose: int) -> void:
	var robe := Color(HADES_BLACK, alpha)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.8, r * 1.1), o + Vector2(r * 0.8, r * 1.1), o + Vector2(r * 0.45, -r * 0.6), o + Vector2(-r * 0.45, -r * 0.6)]), Glyphs._c(robe, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.38, Color(INK, alpha))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.32, Glyphs._c(Color(Palette.PANTHEON_MARBLE_DARK, alpha), flash))  # Grey face.
	ci.draw_circle(o + Vector2(-r * 0.12, -r * 0.88), r * 0.06, Color(Palette.PANTHEON_AEGEAN_LIGHT, alpha))
	ci.draw_circle(o + Vector2(r * 0.12, -r * 0.88), r * 0.06, Color(Palette.PANTHEON_AEGEAN_LIGHT, alpha))
	for i in 5:
		var x := -r * 0.3 + float(i) * r * 0.15
		ci.draw_line(o + Vector2(x, -r * 1.15), o + Vector2(x, -r * (1.35 + 0.08 * float(i % 2))), Color(Palette.PANTHEON_BRONZE_DARK, alpha), 2.0)  # Crown spikes.
	ci.draw_arc(o + Vector2(0, -r * 1.0), r * 0.45, PI, TAU, 12, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.6 * alpha), 2.0)  # Cold fire.
	var lift := -r * 0.5 if pose == 1 else 0.0
	ci.draw_line(o + Vector2(r * 0.7, r * 1.0 + lift), o + Vector2(r * 0.7, -r * 1.6 + lift), Color(Palette.PANTHEON_BRONZE, alpha), 2.0)  # Bident shaft.
	ci.draw_line(o + Vector2(r * 0.5, -r * 1.6 + lift), o + Vector2(r * 0.9, -r * 1.6 + lift), Color(Palette.PANTHEON_BRONZE_LIGHT, alpha), 2.0)
	ci.draw_line(o + Vector2(r * 0.5, -r * 1.6 + lift), o + Vector2(r * 0.5, -r * 1.9 + lift), Color(Palette.PANTHEON_BRONZE_LIGHT, alpha), 2.0)
	ci.draw_line(o + Vector2(r * 0.9, -r * 1.6 + lift), o + Vector2(r * 0.9, -r * 1.9 + lift), Color(Palette.PANTHEON_BRONZE_LIGHT, alpha), 2.0)


## The Helm of Darkness: a faint heat-shimmer where he walks unseen (no body,
## no shadow). `t` game time.
static func draw_helm_shimmer(ci: CanvasItem, r: float, t: float) -> void:
	for i in 3:
		var k := fmod(t * 1.5 + float(i) * 0.33, 1.0)
		ci.draw_arc(Vector2(0, -r * 0.3), r * (0.5 + 0.7 * k), 0.0, TAU, 18, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.10 * (1.0 - k)), 1.0)


## One footprint of the cloaked Hades at `p` walking along `dir`, `k` 1 fresh
## -> 0 faded: a dark print pressed into the asphodel, edged in pale light.
static func draw_footprint(ci: CanvasItem, p: Vector2, dir: Vector2, k: float) -> void:
	var ang := dir.angle()
	ci.draw_set_transform(p, ang, Vector2(1.0, 0.55))
	ci.draw_circle(Vector2.ZERO, 5.0, Color(0.0, 0.0, 0.0, 0.55 * k))
	ci.draw_circle(Vector2(5.5, 0.0), 2.5, Color(0.0, 0.0, 0.0, 0.5 * k))
	ci.draw_arc(Vector2.ZERO, 5.5, 0.0, TAU, 10, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.35 * k), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Hades' sigil over a marked summon at `p` (world), `k` 1 fresh -> 0 taken: a
## pale ring closing in around an inverted bident. `t` game time.
static func draw_hades_mark(ci: CanvasItem, p: Vector2, k: float, t: float) -> void:
	var blink := 0.6 + 0.4 * absf(sin(t * 8.0))
	ci.draw_arc(p, 4.0 + 7.0 * k, 0.0, TAU, 16, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.85 * blink), 2.0)
	ci.draw_line(p + Vector2(0, -5), p + Vector2(0, 5), Color(Palette.PANTHEON_AEGEAN_LIGHT, blink), 1.5)
	ci.draw_line(p + Vector2(-3, 5), p + Vector2(3, 5), Color(Palette.PANTHEON_AEGEAN_LIGHT, blink), 1.5)
	ci.draw_line(p + Vector2(-3, 5), p + Vector2(-3, 8), Color(Palette.PANTHEON_AEGEAN_LIGHT, blink), 1.5)
	ci.draw_line(p + Vector2(3, 5), p + Vector2(3, 8), Color(Palette.PANTHEON_AEGEAN_LIGHT, blink), 1.5)


## A god's shade at `p` (world), `a` 0..1 its opacity: the god's own art
## (`key`, tinted pale like a ghost) when it exists, else a tall generic shade
## (degrades gracefully). `t` game time.
static func draw_god_shade(ci: CanvasItem, p: Vector2, key: String, _god_name: String, a: float, t: float) -> void:
	if a <= 0.01:
		return
	var glow := Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.18 * a)
	ci.draw_circle(p + Vector2(0, -10), 30.0 + 3.0 * sin(t * 4.0), glow)
	if key != "" and SpriteBank.draw(ci, key, p, false, Color(HadesData.SHADE_TINT, 0.75 * a)):
		return
	ci.draw_set_transform(p, 0.0, Vector2(1.9, 1.9))
	PantheonGlyphs.draw_enemy(ci, PantheonEnemyData.SHADE, Vector2.ZERO, 10.0, false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_circle(p, 22.0, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.12 * a))


## Hades kneeling at `p` (world) after his defeat, `a` 0..1 its opacity: his
## kneel art (bosses/hades_kneel) when it exists, else the glyph, lowered.
static func draw_kneeling_hades(ci: CanvasItem, p: Vector2, a: float) -> void:
	if SpriteBank.draw(ci, "bosses/hades_kneel", p, false, Color(1.0, 1.0, 1.0, a)):
		return
	ci.draw_set_transform(p + Vector2(0, 8), 0.0, Vector2(1.0, 0.7))
	draw_hades(ci, Vector2.ZERO, 22.0, false, a, 0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## His crown at `p` (world), `a` 0..1 opacity: a dark bronze circlet of spikes
## with a gold glint (the victory's gold).
static func draw_crown(ci: CanvasItem, p: Vector2, a: float) -> void:
	var pts := PackedVector2Array([p + Vector2(-9, 4), p + Vector2(9, 4), p + Vector2(9, -2), p + Vector2(6, -7), p + Vector2(3, -2),
		p + Vector2(0, -9), p + Vector2(-3, -2), p + Vector2(-6, -7), p + Vector2(-9, -2)])
	ci.draw_colored_polygon(pts, Color(Palette.PANTHEON_BRONZE_DARK, a))
	var ring := pts.duplicate()  # The outline, closed.
	ring.append(pts[0])
	ci.draw_polyline(ring, Color(Palette.GOLD, a), 1.0)
	ci.draw_circle(p + Vector2(0, 1), 1.6, Color(Palette.PANTHEON_AEGEAN_LIGHT, a))
