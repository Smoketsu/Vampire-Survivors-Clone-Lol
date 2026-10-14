## PixelMarks — small code-drawn pixel marks shared by the archive screens
## (Ossuary, Settings, Recipes; menu modernization wave 2): level pips with
## cut corners, a real arrow glyph (Jersey 10 has no "→", and "->" reads as
## ASCII), a padlock and an empty recipe socket. Everything is drawn from
## whole-pixel rectangles on the 1280x720 layout grid (1 mark px = 1 layout
## px), through the sharp-pixel shader of the Control drawing them
## (SpriteBank.apply_sharp()), so the marks stay crisp at any window scale,
## like the kit frames. Two tiny Controls wrap the most used marks: Pips and
## Arrow. Purely visual.
class_name PixelMarks
extends RefCounted


## A row of level pips (a Control sized to fit them): `count` sockets, the
## first `filled` lit in `fill`; pips after `filled` and up to `idle` drawn
## in `idle_fill` (the Profane Oath's owned-but-lowered tiers).
class Pips:
	extends Control
	## Number of pips (the upgrade's tiers, 1..6).
	var count: int = 0
	## Pips lit in `fill` (bought tiers, or the Oath's active tiers).
	var filled: int = 0
	## Pips lit up to this index in `idle_fill` (>= filled; 0 = none).
	var idle: int = 0
	## Colour of a lit pip.
	var fill: Color = OssuaryUiData.PIP_OWNED
	## Colour of an "idle" pip (between filled and idle).
	var idle_fill: Color = OssuaryUiData.PIP_OATH_IDLE
	## Size (layout px) of one pip.
	var pip: Vector2i = OssuaryUiData.PIP_SIZE

	func _init(p_pip: Vector2i = OssuaryUiData.PIP_SIZE) -> void:
		pip = p_pip
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	## Sets the pips and resizes / redraws when anything changed.
	func set_pips(p_count: int, p_filled: int, p_fill: Color, p_idle: int = 0) -> void:
		if p_count == count and p_filled == filled and p_fill == fill and p_idle == idle:
			return
		count = p_count
		filled = p_filled
		fill = p_fill
		idle = p_idle
		custom_minimum_size = Vector2(PixelMarks.pips_width(count, pip), pip.y)
		update_minimum_size()
		queue_redraw()

	func _draw() -> void:
		var y := floorf((size.y - float(pip.y)) * 0.5)  # Vertically centred (whole px).
		for i in count:
			var col := PixelMarks.EMPTY  # Socket colour.
			if i < filled:
				col = fill
			elif i < idle:
				col = idle_fill
			PixelMarks.draw_pip(self, Vector2(float(i * (pip.x + OssuaryUiData.PIP_GAP)), y), pip, col)


## A right-pointing pixel arrow (shaft + head), `w` x `h` layout px, in
## `color` (the "current → next" arrow of the Ossuary detail panel).
class Arrow:
	extends Control
	## Arrow colour.
	var color: Color = UiTheme.TEXT_DIM

	func _init(p_color: Color = UiTheme.TEXT_DIM, p_size: Vector2 = Vector2(16, 12)) -> void:
		color = p_color
		custom_minimum_size = p_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	func _draw() -> void:
		PixelMarks.draw_arrow(self, Rect2(Vector2.ZERO, size), color)


## Fill marker for an empty pip (PixelMarks.Pips draws its rim).
const EMPTY := Color(0, 0, 0, 0)


## Width (layout px) of a row of `count` pips of size `pip`.
static func pips_width(count: int, pip: Vector2i) -> float:
	return float(maxi(0, count * pip.x + (count - 1) * OssuaryUiData.PIP_GAP))


## Draws one pip at `pos` (top-left, whole px) of size `s`: a cut-corner
## (1 px) block in `col`, or an empty socket (dark fill, 1 px rim) when `col`
## is EMPTY. A lit pip gets a 1 px lighter top row (light from the top-left).
static func draw_pip(ci: CanvasItem, pos: Vector2, s: Vector2i, col: Color) -> void:
	var w := float(s.x)
	var h := float(s.y)
	if col.a <= 0.0:
		ci.draw_rect(Rect2(pos + Vector2(1, 0), Vector2(w - 2, h)), OssuaryUiData.PIP_RIM)
		ci.draw_rect(Rect2(pos + Vector2(0, 1), Vector2(w, h - 2)), OssuaryUiData.PIP_RIM)
		ci.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(w - 2, h - 2)), OssuaryUiData.PIP_EMPTY)
		return
	ci.draw_rect(Rect2(pos + Vector2(1, 0), Vector2(w - 2, h)), col)
	ci.draw_rect(Rect2(pos + Vector2(0, 1), Vector2(w, h - 2)), col)
	ci.draw_rect(Rect2(pos + Vector2(1, 0), Vector2(w - 2, 1)), col.lightened(0.35))
	ci.draw_rect(Rect2(pos + Vector2(1, h - 1), Vector2(w - 2, 1)), col.darkened(0.35))


## Draws a right-pointing arrow filling `r` (whole px): a 2 px shaft and a
## stepped triangular head (a pixel "→").
static func draw_arrow(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var x0 := floorf(r.position.x)  # Shaft start.
	var cy := floorf(r.position.y + r.size.y * 0.5)  # Centre row (the shaft is rows cy-1 and cy).
	var head := floorf(minf(r.size.y * 0.5, r.size.x * 0.5))  # Head half-height (px).
	var head_x := floorf(r.position.x + r.size.x) - head  # First column of the head.
	ci.draw_rect(Rect2(Vector2(x0, cy - 1.0), Vector2(head_x - x0, 2.0)), col)
	for i in int(head):  # Column i of the head, from its base to its tip.
		var half := head - float(i)  # Half-height of this column (px).
		ci.draw_rect(Rect2(Vector2(head_x + float(i), cy - half), Vector2(1.0, half * 2.0)), col)


## Draws a small padlock (9 x 11 px) with its top-left at `pos`: a bone
## shackle and body with a dark keyhole, outlined in ink (locked upgrades).
static func draw_lock(ci: CanvasItem, pos: Vector2) -> void:
	var p := pos.floor()
	var ink := OssuaryUiData.LOCK_INK
	var bone := OssuaryUiData.LOCK_COLOR
	ci.draw_rect(Rect2(p + Vector2(1, 0), Vector2(7, 6)), ink)  # Shackle outline.
	ci.draw_rect(Rect2(p + Vector2(2, 1), Vector2(5, 5)), bone)  # Shackle.
	ci.draw_rect(Rect2(p + Vector2(3, 2), Vector2(3, 4)), ink)  # Shackle hole.
	ci.draw_rect(Rect2(p + Vector2(0, 5), Vector2(9, 6)), ink)  # Body outline.
	ci.draw_rect(Rect2(p + Vector2(1, 6), Vector2(7, 4)), bone)  # Body.
	ci.draw_rect(Rect2(p + Vector2(1, 6), Vector2(7, 1)), bone.lightened(0.3))  # Lit top edge.
	ci.draw_rect(Rect2(p + Vector2(4, 7), Vector2(1, 2)), ink)  # Keyhole.


## Draws an empty recipe socket filling `r` (whole px): a dark recessed
## square with cut corners and a 1 px rim, `rim` coloured (undiscovered
## recipe tiles in the Recipes book: shape only, no hint).
static func draw_socket(ci: CanvasItem, r: Rect2, fill: Color, rim: Color) -> void:
	var p := r.position.floor()
	var s := r.size.floor()
	ci.draw_rect(Rect2(p + Vector2(2, 0), Vector2(s.x - 4, s.y)), rim)
	ci.draw_rect(Rect2(p + Vector2(0, 2), Vector2(s.x, s.y - 4)), rim)
	ci.draw_rect(Rect2(p + Vector2(1, 1), Vector2(s.x - 2, s.y - 2)), rim)
	ci.draw_rect(Rect2(p + Vector2(2, 1), Vector2(s.x - 4, s.y - 2)), fill)
	ci.draw_rect(Rect2(p + Vector2(1, 2), Vector2(s.x - 2, s.y - 4)), fill)
	ci.draw_rect(Rect2(p + Vector2(2, 1), Vector2(s.x - 4, 2)), fill.darkened(0.4))  # Recessed top shadow.
