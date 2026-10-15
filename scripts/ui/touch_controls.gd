## TouchControls: the on-screen controls of a run on a phone or tablet (GDD
## §15.0 "Mobile browser support"; every size, place and colour in
## TouchData). Game adds it to the run's UI layer (never under the autotest);
## it shows only while the input hints are on TOUCH (a phone or tablet from
## the start, or after a real touch; any key or pad input hides it again)
## and the run is PLAYING (level-up, chest, pause and the end screen hide it).
##   * Left half: a floating joystick. A finger landing in the left
##     TouchData.STICK_ZONE of the screen puts the stick there; the knob
##     follows it up to STICK_RADIUS (beyond STICK_FOLLOW x that the stick
##     drifts after the thumb), with a dead zone. It drives the SAME move
##     actions the keys and the left stick use (Input.action_press() with a
##     strength on move_left / right / up / down), so Necromancer reads it
##     through its one Input.get_vector() path. A faint rest ring shows where
##     to put the thumb while no finger holds it.
##   * Right side: Grave Step (the big thumb button, its charges as pips and
##     a recharge sweep), Dread Rally (darkened above its soul meter's level
##     like the HUD icon, a bright green border when READY, violet while the
##     rally runs), the Shadow Bolt aim toggle (only while the bolt is owned;
##     the HUD line says which aim) and the four army stances as a rose
##     above Grave Step (each stance in the direction of its controller
##     flick: Escort up, Onslaught right, Spearhead down, Bone Ring left; a
##     finger anywhere in a quarter of the rose picks that stance; the active
##     one is lit in its colour with the lockout bar, a locked one shows its
##     padlock). Pause sits in the top-right corner (the HUD's top-right
##     block moves left for it, Hud.set_top_right_inset()).
##   * Every button injects its existing input action as an InputEventAction
##     (press on finger down, release on finger up) through
##     Input.parse_input_event(), so Game._unhandled_input(), ArmyStance and
##     PauseMenu apply their usual rules, cooldowns and lockouts: there is no
##     second path for any action.
## Multi-touch: each finger is tracked by its index, so the stick and any
## button work at the same time. Sizes are CSS px converted with
## TouchSupport.layout_per_css(), so a button is thumb-sized on any screen;
## hit areas are round and larger than the drawn faces (>= 48 CSS px).
## Faces are octagons (cut corners) in the kit's violet, drawn on two child
## layers: an idle one at TouchData.IDLE_ALPHA (semi-transparent, so the
## action shows through) and one at ACTIVE_ALPHA for whatever a finger
## holds. Icons go through Glyphs.draw_icon(). Purely input and
## presentation: it never reads the RNG and writes no gameplay state itself.
class_name TouchControls
extends Control

## Owning run.
var game: Game = null
## Layout px per CSS px (refreshed every frame while shown).
var _k: float = 1.0
## Whether the controls were shown at the last check.
var _shown: bool = false
## Finger index holding the joystick (-1 = none).
var _stick_finger: int = -1
## Joystick centre (layout px) while held.
var _stick_centre: Vector2 = Vector2.ZERO
## Finger position (layout px) on the joystick while held.
var _stick_at: Vector2 = Vector2.ZERO
## Button id -> finger index holding it (absent = not held).
var _held: Dictionary = {}
## Finger index on the stance rose (-1 = none).
var _rose_finger: int = -1
## Move action -> strength currently pressed by the stick (released at 0).
var _pressed_moves: Dictionary = {}
## Drawing layer of the idle controls (modulate alpha IDLE_ALPHA).
var _idle_layer: Control = null
## Drawing layer of the held controls (modulate alpha ACTIVE_ALPHA).
var _active_layer: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Fingers are read in _input(); nothing here takes clicks.
	process_mode = Node.PROCESS_MODE_ALWAYS  # Notices pauses, to let go of every held action.
	visible = false
	_idle_layer = _make_layer(TouchData.IDLE_ALPHA, false)
	_active_layer = _make_layer(TouchData.ACTIVE_ALPHA, true)


## A full-rect child that draws the idle (`active` false) or held controls
## at opacity `alpha`.
func _make_layer(alpha: float, active: bool) -> Control:
	var l := Control.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = alpha
	l.draw.connect(_draw_layer.bind(l, active))
	add_child(l)
	SpriteBank.apply_sharp(l)  # Crisp icon art.
	return l


func _process(_delta: float) -> void:
	var want := _should_show()
	if want != _shown:
		_shown = want
		visible = want
		if not want:
			_release_all()
		if game != null and game.hud != null:
			game.hud.set_top_right_inset(TouchData.HUD_TOP_RIGHT_SHIFT * _layout_k() if want else 0.0)
	if _shown:
		_k = _layout_k()
		_idle_layer.queue_redraw()
		_active_layer.queue_redraw()


## True while the controls should show: touch input and a running run.
func _should_show() -> bool:
	if game == null or InputHints.device() != InputHints.Device.TOUCH:
		return false
	return game.run_state == Game.RunState.PLAYING and not get_tree().paused


## Layout px per CSS px for this screen.
func _layout_k() -> float:
	return TouchSupport.layout_per_css(get_viewport())


# =====================================================================================
# Fingers
# =====================================================================================

func _input(event: InputEvent) -> void:
	if not _shown:
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_finger_down(touch.index, touch.position)
		else:
			_finger_up(touch.index)
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		if drag.index == _stick_finger:
			_stick_move(drag.position)
		elif drag.index == _rose_finger:
			_rose_pick(drag.position, false)


## A finger landed at `at` (layout px): a button, the rose, or the stick.
func _finger_down(finger: int, at: Vector2) -> void:
	for id: String in TouchData.BUTTON_ORDER:
		if _button_shown(id) and not _held.has(id) and at.distance_to(_button_centre(id)) <= float(TouchData.BUTTONS[id]["hit"]) * _k:
			_held[id] = finger
			_send(String(TouchData.BUTTONS[id]["action"]), true)
			return
	if _rose_finger < 0 and at.distance_to(_rose_centre()) <= TouchData.ROSE_HIT * _k:
		_rose_finger = finger
		_rose_pick(at, true)
		return
	if _stick_finger < 0 and at.x < size.x * TouchData.STICK_ZONE:
		_stick_finger = finger
		_stick_centre = at
		_stick_move(at)


## Finger `finger` lifted (or the browser cancelled it).
func _finger_up(finger: int) -> void:
	if finger == _stick_finger:
		_stick_finger = -1
		_set_move(Vector2.ZERO)
	if finger == _rose_finger:
		_rose_finger = -1
	for id: String in _held.keys():
		if int(_held[id]) == finger:
			_held.erase(id)
			_send(String(TouchData.BUTTONS[id]["action"]), false)


## Lets go of everything (the controls hid: a panel opened, a key was used).
func _release_all() -> void:
	_stick_finger = -1
	_rose_finger = -1
	_set_move(Vector2.ZERO)
	for id: String in _held.keys():
		_send(String(TouchData.BUTTONS[id]["action"]), false)
	_held.clear()


## Injects action `action` pressed / released: the same event a key makes.
func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


# =====================================================================================
# Joystick
# =====================================================================================

## The stick finger moved to `at`: knob, drift and the move input.
func _stick_move(at: Vector2) -> void:
	var r := TouchData.STICK_RADIUS * _k  # Knob travel (layout px).
	var off := at - _stick_centre
	if off.length() > r * TouchData.STICK_FOLLOW:
		_stick_centre = at - off.normalized() * r * TouchData.STICK_FOLLOW  # Drift after the thumb.
		off = at - _stick_centre
	_stick_at = at
	var n := off / maxf(r, 0.001)  # Normalised deflection (length may exceed 1).
	var amount := minf(n.length(), 1.0)  # 0..1 deflection.
	if amount <= TouchData.STICK_DEAD_ZONE:
		_set_move(Vector2.ZERO)
		return
	var k := (amount - TouchData.STICK_DEAD_ZONE) / (1.0 - TouchData.STICK_DEAD_ZONE)  # 0..1 past our dead zone.
	_set_move(n.normalized() * k)


## Presses the move actions for direction `v` (length 0..1). Input.get_vector()
## subtracts the actions' own dead zone and rescales the rest, so the vector
## is lifted past it: the necromancer's speed then follows `v`.
func _set_move(v: Vector2) -> void:
	var dz := 0.0  # Mean dead zone of the four move actions (project.godot).
	for a: String in InputHintData.MOVE_ACTIONS:
		dz += InputMap.action_get_deadzone(a) / float(InputHintData.MOVE_ACTIONS.size())
	var mag := v.length()
	var lifted := v
	if mag > 0.0:
		lifted = v / mag * (dz + (1.0 - dz) * mag)  # Same direction, length past the dead zone.
	_press_move("move_right", maxf(lifted.x, 0.0))
	_press_move("move_left", maxf(-lifted.x, 0.0))
	_press_move("move_down", maxf(lifted.y, 0.0))
	_press_move("move_up", maxf(-lifted.y, 0.0))


## Presses move action `action` at `strength` (0 releases it, if the stick held it).
func _press_move(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, clampf(strength, 0.0, 1.0))
		_pressed_moves[action] = strength
	elif _pressed_moves.has(action):
		Input.action_release(action)
		_pressed_moves.erase(action)


# =====================================================================================
# Buttons and the stance rose
# =====================================================================================

## Whether button `id` is shown now (the aim toggle needs the Shadow Bolt).
func _button_shown(id: String) -> bool:
	if id == "toggle_aim":
		return game != null and game.abilities != null and game.abilities.spell_level("shadow_bolt") > 0
	return true


## Centre (layout px) of button `id`.
func _button_centre(id: String) -> Vector2:
	var d: Dictionary = TouchData.BUTTONS[id]
	var c: Vector2 = d["centre"] * _k
	if String(d["corner"]) == "top_right":
		return Vector2(size.x - c.x, c.y)
	return Vector2(size.x - c.x, size.y - c.y)


## Centre (layout px) of the stance rose.
func _rose_centre() -> Vector2:
	return Vector2(size.x - TouchData.ROSE_CENTRE.x * _k, size.y - TouchData.ROSE_CENTRE.y * _k)


## The rose finger is at `at`: picks the stance of its quarter on landing,
## and again when it slides into another quarter once the lockout is over
## (ArmyStance applies the lockout and the Spearhead lock either way).
func _rose_pick(at: Vector2, first: bool) -> void:
	var off := at - _rose_centre()
	if off.length() < TouchData.ROSE_DEAD * _k:
		return
	var best := ""  # Stance whose direction is closest to the finger.
	var best_dot := -2.0
	for id: String in StanceData.ORDER:
		var dot := off.normalized().dot(TouchData.ROSE_DIRS[id])
		if dot > best_dot:
			best_dot = dot
			best = id
	if best == "":
		return
	if not first and (game.stance.current == best or game.stance.lockout_left() > 0.0 or not game.stance.is_unlocked(best)):
		return  # Sliding: no repeats, no requests during the lockout.
	var action := String(StanceData.ACTIONS[StanceData.ORDER.find(best)])
	_send(action, true)
	_send(action, false)


# =====================================================================================
# Drawing (two layers: idle and held)
# =====================================================================================

## Draws on `layer` every control whose held state is `active`.
func _draw_layer(layer: Control, active: bool) -> void:
	if not _shown or game == null:
		return
	if (_stick_finger >= 0) == active:
		_draw_stick(layer)
	if (_rose_finger >= 0) == active:
		_draw_rose(layer)
	for id: String in TouchData.BUTTON_ORDER:
		if _button_shown(id) and _held.has(id) == active:
			_draw_button(layer, id)


## The joystick on `ci`: the held stick and its knob, or the faint rest ring.
func _draw_stick(ci: CanvasItem) -> void:
	var r := TouchData.STICK_RADIUS * _k
	var kh := TouchData.KNOB_HALF * _k
	var col := TouchData.STICK_COLOR
	if _stick_finger < 0:
		var rest := Vector2(TouchData.STICK_REST.x * _k, size.y - TouchData.STICK_REST.y * _k)
		var faint := Color(col, TouchData.STICK_REST_ALPHA)
		_outline(ci, _square(rest, r), faint, TouchData.BORDER_WIDTH)
		_outline(ci, _square(rest, kh), faint, TouchData.BORDER_WIDTH)
		return
	var base := _square(_stick_centre, r)
	ci.draw_colored_polygon(base, Color(TouchData.FACE_FILL, TouchData.FACE_FILL.a * 0.5))
	_outline(ci, base, Color(col, 0.7), TouchData.BORDER_WIDTH)
	var knob := _square(_stick_centre + (_stick_at - _stick_centre).limit_length(r), kh)
	ci.draw_colored_polygon(knob, TouchData.FACE_PRESSED)
	_outline(ci, knob, col, TouchData.BORDER_WIDTH)


## The stance rose on `ci`: four stance icons around a small hub.
func _draw_rose(ci: CanvasItem) -> void:
	var c := _rose_centre()
	var st := game.stance
	var hub := TouchData.ROSE_OFFSET * 0.42 * _k  # Hub half size.
	_outline(ci, _square(c, hub), TouchData.BORDER, TouchData.BORDER_WIDTH)
	var h := TouchData.ROSE_HALF * _k  # Half size of one stance face.
	for id: String in StanceData.ORDER:
		var d := StanceData.def(id)
		var at: Vector2 = c + (TouchData.ROSE_DIRS[id] as Vector2) * TouchData.ROSE_OFFSET * _k
		var rect := Rect2(at - Vector2(h, h), Vector2(h, h) * 2.0)
		var face := _square(at, h)
		var current := st.current == id
		ci.draw_colored_polygon(face, TouchData.FACE_FILL)
		Glyphs.draw_icon(ci, String(d["icon"]), rect.grow(-h * 0.12))
		if not st.is_unlocked(id):
			ci.draw_colored_polygon(face, TouchData.SHADE)
			StanceGlyphs.draw_lock(ci, at + Vector2(h, h) * 0.3, h * 0.6)
		elif not current:
			ci.draw_colored_polygon(face, Color(0.0, 0.0, 0.0, 0.3))  # The others are dimmed, as on the HUD.
		var col: Color = d["color"] if current else TouchData.BORDER
		_outline(ci, face, col, TouchData.BORDER_WIDTH * (1.5 if current else 1.0))
		if current and st.lockout_left() > 0.0:
			var left := st.lockout_left() / StanceData.SWITCH_LOCKOUT  # 1 -> 0 lockout bar.
			ci.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y + 2.0), Vector2(rect.size.x * left, 2.0 * _k)), col)


## Button `id` on `ci`: its face, icon and state.
func _draw_button(ci: CanvasItem, id: String) -> void:
	var d: Dictionary = TouchData.BUTTONS[id]
	var c := _button_centre(id)
	var h := float(d["half"]) * _k
	var rect := Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0)
	var face := _square(c, h)
	ci.draw_colored_polygon(face, TouchData.FACE_PRESSED if _held.has(id) else TouchData.FACE_FILL)
	var border := TouchData.BORDER
	var width := TouchData.BORDER_WIDTH
	var icon_rect := rect.grow(-h * 0.22)
	match id:
		"pause":
			_pause_sign(ci, rect.grow(-h * 0.42), UiTheme.TEXT)
		"dash":
			Glyphs.draw_icon(ci, String(d["icon"]), icon_rect)
			var gs := game.grave_step
			if gs.charges <= 0:
				_shade(ci, face, rect, 1.0 - gs.recharge_fraction())
			_pips(ci, rect, gs.max_charges, gs.charges, gs.recharge_fraction())
		"ultimate":
			Glyphs.draw_icon(ci, String(d["icon"]), icon_rect)
			var dr := game.dread_rally
			if dr.buff_active():
				ci.draw_colored_polygon(face, Color(Palette.VIOLET, 0.3))
				border = Palette.VIOLET.lightened(0.3)
			elif dr.is_full():
				border = Palette.NECRO_GREEN
				width *= 2.0
			else:
				_shade(ci, face, rect, 1.0 - dr.fraction())
		_:
			Glyphs.draw_icon(ci, String(d["icon"]), icon_rect)
	_outline(ci, face, border, width)


## Darkens the top `part` (0..1) of `face` (inside `rect`) on `ci`: the
## not-ready sweep of the HUD icons.
func _shade(ci: CanvasItem, face: PackedVector2Array, rect: Rect2, part: float) -> void:
	if part <= 0.0:
		return
	var cover := Rect2(rect.position, Vector2(rect.size.x, rect.size.y * clampf(part, 0.0, 1.0)))
	var box := PackedVector2Array([cover.position, Vector2(cover.end.x, cover.position.y), cover.end, Vector2(cover.position.x, cover.end.y)])
	for poly: PackedVector2Array in Geometry2D.intersect_polygons(face, box):
		ci.draw_colored_polygon(poly, TouchData.SHADE)


## Grave Step charge pips under `rect` on `ci` (only with 2+ charges):
## filled = ready, the recharging one fills up.
func _pips(ci: CanvasItem, rect: Rect2, count: int, ready: int, fill: float) -> void:
	if count <= 1:
		return
	var w := rect.size.x * 0.6 / float(count)  # One pip's slot width.
	var y := rect.end.y + 3.0 * _k
	for i in count:
		var pip := Rect2(Vector2(rect.position.x + rect.size.x * 0.2 + float(i) * w + 1.0, y), Vector2(w - 2.0, 3.0 * _k))
		ci.draw_rect(pip, Color(0.18, 0.14, 0.24))
		if i < ready:
			ci.draw_rect(pip, Palette.VIOLET.lightened(0.2))
		elif i == ready:
			ci.draw_rect(Rect2(pip.position, Vector2(pip.size.x * fill, pip.size.y)), Color(Palette.VIOLET, 0.55))


## The pause sign (two bars) in `rect` on `ci`.
func _pause_sign(ci: CanvasItem, rect: Rect2, col: Color) -> void:
	var bw := rect.size.x * 0.32  # Bar width.
	ci.draw_rect(Rect2(rect.position, Vector2(bw, rect.size.y)), col)
	ci.draw_rect(Rect2(Vector2(rect.end.x - bw, rect.position.y), Vector2(bw, rect.size.y)), col)


## Closed outline of polygon `poly` on `ci`.
func _outline(ci: CanvasItem, poly: PackedVector2Array, col: Color, width: float) -> void:
	var closed := poly.duplicate()
	closed.append(poly[0])
	ci.draw_polyline(closed, col, width)


## The octagon face of half size `h` centred on `c` (TouchData.CUT_FRACTION).
static func _square(c: Vector2, h: float) -> PackedVector2Array:
	return chamfer(Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0), h * TouchData.CUT_FRACTION)


## The eight corners of `r` with `cut` px cut off each corner (a chamfered
## rectangle; with a big cut, an octagon). Shared by RotateOverlay.
static func chamfer(r: Rect2, cut: float) -> PackedVector2Array:
	var c := minf(cut, minf(r.size.x, r.size.y) * 0.5)  # Cut, at most half the short side.
	var p := r.position
	var e := r.end
	return PackedVector2Array([
		Vector2(p.x + c, p.y), Vector2(e.x - c, p.y), Vector2(e.x, p.y + c), Vector2(e.x, e.y - c),
		Vector2(e.x - c, e.y), Vector2(p.x + c, e.y), Vector2(p.x, e.y - c), Vector2(p.x, p.y + c),
	])
