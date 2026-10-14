## InputHints — on-screen input hints drawn from the CURRENT bindings (menu
## modernization, GDD §15.0 "Input hints"; numbers and names in
## InputHintData). It replaces every hard-coded "[R / X]" hint string:
##   * chips: one key or pad button as a small pixel chip with cut corners
##     (keyboard: a bone keycap with the key name; pad: Xbox-style A / B / X /
##     Y face buttons as coloured octagons, LB / RB / Start / sticks as grey
##     chips, sticks and the D-pad with a drawn direction arrow);
##   * the last device used: a tiny always-processing node (installed under
##     the tree root on first use) watches every input event and flips
##     between KEYBOARD (keys, mouse) and PAD (buttons, sticks past
##     InputHintData.AXIS_THRESHOLD); every chip redraws when it changes, and
##     when a key is rebound (Settings.changed);
##   * a reusable hint strip for the bottom of a screen:
##     InputHints.strip([["ui_accept", "Select"], ["ui_cancel", "Back"]]).
## A hint "spec" is one of:
##   * an InputMap action name ("ui_accept", "pause", "dash"...): its primary
##     key (Settings.key_name() for the rebindable actions, so rebinds show)
##     or its first pad button / axis;
##   * InputHints.MOVE: the four move keys ("WASD") or the left stick;
##   * a raw Dictionary from InputHints.raw(key, pad) for a fixed key / pad
##     button that is not an action (the level-up panel's R / X); a side left
##     out (-1) shows nothing on that device, so a raw(KEY_1) chip hides
##     while the pad is in use.
## Purely visual: it never reads or changes gameplay state, so headless runs
## and the autotest are unaffected (no input events: the hints stay KEYBOARD).
class_name InputHints
extends RefCounted

## Which family of input the hints show.
##   KEYBOARD: keyboard and mouse (the default until a pad is used).
##   PAD     : a game controller.
enum Device { KEYBOARD, PAD }

## Pseudo-action spec: the movement keys (keyboard) or the left stick (pad).
const MOVE: String = "move"

## Device of the last decisive input event (see device_of()).
static var _device: Device = Device.KEYBOARD
## The always-processing node that watches input (null until first use).
static var _tracker: _Tracker = null
## Cached chip frame textures: "<w>x<h>|<style>|<colour>|<arrow>" -> ImageTexture.
static var _frames: Dictionary = {}


## Watches every input event (even while the tree is paused) and reports
## the device that produced it. Lives under the tree root for the whole
## session.
class _Tracker:
	extends Node
	## The hints' device changed (KEYBOARD <-> PAD).
	signal device_changed(device: int)

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		var d := InputHints.device_of(event)  # -1 = not decisive.
		if d >= 0 and d != InputHints._device:
			InputHints.set_device(d as InputHints.Device)


## One chip for one hint spec. It sizes itself to its text, hides itself
## when the spec has nothing on the current device, and redraws when the
## device or a binding changes.
class Chip:
	extends Control
	## The hint spec (action name, InputHints.MOVE or a raw() Dictionary).
	var spec: Variant
	## Current glyph: {"text", "style" ("key" / "face" / "pad"), "arrow"}.
	var _glyph: Dictionary = {}

	func _init(p_spec: Variant) -> void:
		spec = p_spec
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		refresh()

	func _ready() -> void:
		SpriteBank.apply_sharp(self)  # Crisp frame and text at any window scale.
		InputHints.tracker().device_changed.connect(func(_d: int) -> void: refresh())
		Settings.changed.connect(refresh)
		refresh()

	## Re-reads the glyph for the current device and bindings.
	func refresh() -> void:
		_glyph = InputHints.glyph(spec)
		var t := String(_glyph["text"])  # "" = nothing on this device.
		visible = t != ""
		custom_minimum_size = Vector2(InputHints.chip_width(_glyph), InputHintData.CHIP_HEIGHT)
		update_minimum_size()
		queue_redraw()

	func _draw() -> void:
		if not visible or String(_glyph.get("text", "")) == "":
			return
		InputHints.draw_chip(self, Vector2.ZERO, _glyph)


## One strip entry: its chips and word, hidden while none of its chips has
## anything to show on the current device.
class _Hint:
	extends HBoxContainer
	## The chips of this entry (several for "1 / 2 / 3").
	var chips: Array[Chip] = []

	func _ready() -> void:
		InputHints.tracker().device_changed.connect(func(_d: int) -> void: _refresh())
		_refresh()

	func _refresh() -> void:
		var any := false  # At least one chip is visible.
		for c in chips:
			any = any or c.visible
		visible = any


# =====================================================================================
# Device
# =====================================================================================

## The device the hints show (the last one used).
static func device() -> Device:
	return _device


## Sets the hints' device and redraws every chip (the tracker calls it;
## screenshot tools may force PAD).
static func set_device(d: Device) -> void:
	if d == _device:
		return
	_device = d
	tracker().device_changed.emit(int(d))


## The device `event` comes from, or -1 when it says nothing (a key release,
## a tiny mouse move, a resting stick).
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.KEYBOARD if event.is_pressed() else -1
	if event is InputEventMouseMotion:
		var big := (event as InputEventMouseMotion).relative.length() >= InputHintData.MOUSE_MOVE_MIN  # A real move.
		return Device.KEYBOARD if big else -1
	if event is InputEventJoypadButton:
		return Device.PAD if event.is_pressed() else -1
	if event is InputEventJoypadMotion:
		return Device.PAD if absf((event as InputEventJoypadMotion).axis_value) >= InputHintData.AXIS_THRESHOLD else -1
	return -1


## The tracker node (its `device_changed(device)` signal), installed under
## the tree root on first use.
static func tracker() -> _Tracker:
	if _tracker == null or not is_instance_valid(_tracker):
		_tracker = _Tracker.new()
		_tracker.name = "InputHintsTracker"
		var tree := Engine.get_main_loop() as SceneTree  # Null outside a running game.
		if tree != null:
			tree.root.add_child.call_deferred(_tracker)
	return _tracker


# =====================================================================================
# Specs and glyphs
# =====================================================================================

## A raw hint spec for a fixed key (`key`, a Key physical keycode) and pad
## button (`pad`, a JoyButton); -1 on a side = nothing shown on that device.
static func raw(key: int, pad: int = -1) -> Dictionary:
	return {"key": key, "pad": pad}


## The glyph of `spec` on device `d`: {"text": chip text ("" = nothing on
## this device), "style": "key" / "face" / "pad", "arrow": Vector2 direction
## of a drawn arrow (ZERO = none)}.
static func glyph(spec: Variant, d: int = -1) -> Dictionary:
	var dev: int = int(_device) if d < 0 else d  # Device to describe.
	if dev == Device.KEYBOARD:
		return {"text": _key_text(spec), "style": "key", "arrow": Vector2.ZERO}
	return _pad_glyph(spec)


## Short, device-aware text of `spec` (e.g. "Shift" / "RB") for widgets that
## draw their own key labels (the HUD ability keys). Empty when nothing is
## bound on the current device.
static func key_text(spec: Variant) -> String:
	return String(glyph(spec)["text"])


## Keyboard text of `spec` (the shortened primary key name).
static func _key_text(spec: Variant) -> String:
	if spec is Dictionary:
		var k := int((spec as Dictionary).get("key", -1))  # Raw keycode (-1 = none).
		return _short(OS.get_keycode_string(k as Key)) if k > 0 else ""
	var action := String(spec)
	if action == MOVE:
		var keys := PackedStringArray()  # The four move keys, WASD order.
		var all_single := true  # Every key name is one character ("WASD").
		for a: String in InputHintData.MOVE_ACTIONS:
			var n := _key_text(a)  # One move key.
			keys.append(n)
			all_single = all_single and n.length() == 1
		return "".join(keys) if all_single else "/".join(keys)
	if Settings.REBINDABLE.has(action):
		var bound := Settings.key_name(action)  # Follows rebinds.
		return "" if bound == "-" else _short(bound)
	if not InputMap.has_action(action):
		return ""
	for ev: InputEvent in InputMap.action_get_events(action):
		var key := ev as InputEventKey
		if key != null:
			var kc := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode  # Key of the binding.
			return _short(OS.get_keycode_string(kc))
	return ""


## Pad glyph of `spec`: its first pad button, else its first stick / trigger.
static func _pad_glyph(spec: Variant) -> Dictionary:
	var none := {"text": "", "style": "pad", "arrow": Vector2.ZERO}  # Nothing on the pad.
	if spec is Dictionary:
		var b := int((spec as Dictionary).get("pad", -1))  # Raw JoyButton (-1 = none).
		return _button_glyph(b) if b >= 0 else none
	var action := String(spec)
	if action == MOVE:
		return {"text": "LS", "style": "pad", "arrow": Vector2.ZERO}
	if not InputMap.has_action(action):
		return none
	var events := InputMap.action_get_events(action)  # The action's bindings.
	for ev: InputEvent in events:
		var jb := ev as InputEventJoypadButton
		if jb != null:
			return _button_glyph(int(jb.button_index))
	for ev: InputEvent in events:
		var jm := ev as InputEventJoypadMotion
		if jm != null and InputHintData.PAD_AXES.has(int(jm.axis)):
			var axis := int(jm.axis)  # JoyAxis index.
			var arrow := Vector2.ZERO  # Stick direction (triggers have none).
			if axis <= 3:
				arrow = Vector2(signf(jm.axis_value), 0.0) if axis % 2 == 0 else Vector2(0.0, signf(jm.axis_value))
			return {"text": String(InputHintData.PAD_AXES[axis]), "style": "pad", "arrow": arrow}
	return none


## Glyph of pad button `b` (JoyButton index).
static func _button_glyph(b: int) -> Dictionary:
	var t := String(InputHintData.PAD_BUTTONS.get(b, ""))  # Chip text.
	var style := "face" if InputHintData.FACE_COLORS.has(t) else "pad"  # A / B / X / Y are face buttons.
	return {"text": t, "style": style, "arrow": InputHintData.PAD_DIRECTIONS.get(b, Vector2.ZERO)}


## `name` (an OS key name) shortened for a chip (InputHintData.KEY_SHORT).
static func _short(key_name: String) -> String:
	return String(InputHintData.KEY_SHORT.get(key_name, key_name))


# =====================================================================================
# Drawing
# =====================================================================================

## Width (layout px) of the chip for `g` (a glyph()).
static func chip_width(g: Dictionary) -> int:
	var t := String(g.get("text", ""))
	if t == "":
		return 0
	var font := UiTheme.font_for()  # Jersey 10 (null when missing: engine default).
	var f: Font = font if font != null else ThemeDB.fallback_font
	var tw := ceili(f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.tier_px(UiTheme.Tier.BODY)).x)  # Text width.
	var arrow := InputHintData.ARROW_W + 1 if g.get("arrow", Vector2.ZERO) != Vector2.ZERO else 0  # Arrow room.
	var w := tw + 2 * InputHintData.CHIP_PAD_X + arrow
	if String(g.get("style", "")) == "face":
		w = maxi(w, InputHintData.CHIP_HEIGHT)
	return maxi(w, InputHintData.CHIP_MIN_WIDTH)


## Draws the chip for glyph `g` on `ci` with its top-left at `pos` (whole
## layout px): the cached pixel frame, then the text in Jersey 10 at the BODY
## size. Widgets that draw their own HUD (a CanvasItem with the sharp-pixel
## material) can call it directly.
static func draw_chip(ci: CanvasItem, pos: Vector2, g: Dictionary) -> void:
	var t := String(g.get("text", ""))
	if t == "":
		return
	var w := chip_width(g)
	var col := _chip_color(g)  # Border, text and arrow colour.
	var arrow: Vector2 = g.get("arrow", Vector2.ZERO)
	ci.draw_texture(_frame(w, String(g.get("style", "key")), col, arrow), pos)
	var font := UiTheme.font_for()
	var f: Font = font if font != null else ThemeDB.fallback_font
	var px := UiTheme.tier_px(UiTheme.Tier.BODY)  # Text size.
	var text_w := float(w - (InputHintData.ARROW_W + 1 if arrow != Vector2.ZERO else 0))  # Room for the text.
	ci.draw_string(f, pos + Vector2(0.0, float(InputHintData.CHIP_BASELINE)), t, HORIZONTAL_ALIGNMENT_CENTER, text_w, px, col)


## Border / text colour of glyph `g`.
static func _chip_color(g: Dictionary) -> Color:
	match String(g.get("style", "key")):
		"face":
			return InputHintData.FACE_COLORS.get(String(g["text"]), InputHintData.PAD_COLOR)
		"pad":
			return InputHintData.PAD_COLOR
	return InputHintData.KEY_COLOR


## The chip frame texture: a `w` x CHIP_HEIGHT pixel frame with cut corners
## (deep cuts for a face button), a 1 px `col` border on CHIP_FILL, a shadow
## row on keys, and the direction `arrow` (if any) at its right end. Built
## once per look and cached.
static func _frame(w: int, style: String, col: Color, arrow: Vector2) -> Texture2D:
	var key := "%dx%d|%s|%s|%s" % [w, InputHintData.CHIP_HEIGHT, style, col.to_html(), str(arrow)]  # Cache key.
	if _frames.has(key):
		return _frames[key]
	var h := InputHintData.CHIP_HEIGHT
	var cut := InputHintData.FACE_CUT if style == "face" else InputHintData.CHIP_CUT  # Corner cut (px).
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			if not _inside(x, y, w, h, cut):
				continue
			var edge := not (_inside(x - 1, y, w, h, cut) and _inside(x + 1, y, w, h, cut)
				and _inside(x, y - 1, w, h, cut) and _inside(x, y + 1, w, h, cut))  # Border pixel.
			var c := InputHintData.CHIP_FILL  # Pixel colour.
			if edge:
				c = col
			elif style == "key" and not _inside(x, y + 2, w, h, cut):
				c = InputHintData.KEY_SHADOW  # The keycap's shadow row.
			img.set_pixel(x, y, c)
	if arrow != Vector2.ZERO:
		_draw_arrow(img, w - InputHintData.CHIP_PAD_X - InputHintData.ARROW_W + 1, h, arrow, col)
	var tex := ImageTexture.create_from_image(img)
	_frames[key] = tex
	return tex


## True when pixel (x, y) lies inside a `w` x `h` rectangle with `cut` px
## corner cuts.
static func _inside(x: int, y: int, w: int, h: int, cut: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	var rx := w - 1 - x  # Distance from the right edge.
	var by := h - 1 - y  # Distance from the bottom edge.
	return x + y >= cut and rx + y >= cut and x + by >= cut and rx + by >= cut


## Draws a small solid triangle pointing `dir` into `img`, in an
## ARROW_W x ARROW_W box starting at column `x0`, centred vertically in `h`.
static func _draw_arrow(img: Image, x0: int, h: int, dir: Vector2, col: Color) -> void:
	var n := InputHintData.ARROW_W  # Box size (px).
	var half := n / 2  # Centre offset (px).
	var y0 := (h - n) / 2  # Box top.
	for i in half + 1:  # Row (or column) i of the triangle, from its tip.
		for j in range(half - i, half + i + 1):
			var p := Vector2i.ZERO  # Pixel in the box.
			if dir == Vector2.UP:
				p = Vector2i(j, i + 1)
			elif dir == Vector2.DOWN:
				p = Vector2i(j, n - 2 - i)
			elif dir == Vector2.LEFT:
				p = Vector2i(i + 1, j)
			else:
				p = Vector2i(n - 2 - i, j)
			img.set_pixel(clampi(x0 + p.x, 0, img.get_width() - 1), clampi(y0 + p.y, 0, h - 1), col)


# =====================================================================================
# Widgets
# =====================================================================================

## A chip Control for `spec` (hidden while the spec has nothing on the
## current device).
static func chip(spec: Variant) -> Chip:
	return Chip.new(spec)


## A hint strip for the bottom of a screen: `entries` is a list of
## [spec_or_list_of_specs, word] pairs, e.g.
##   InputHints.strip([["ui_accept", "Select"], ["ui_cancel", "Back"]])
##   InputHints.strip([[[InputHints.raw(KEY_1), InputHints.raw(KEY_2), InputHints.raw(KEY_3), "ui_accept"], "Choose"]])
## Each entry shows its chips then its word (BODY tier); an entry with no
## chip on the current device hides. Centred; set `alignment` to change.
static func strip(entries: Array) -> HBoxContainer:
	var row := HBoxContainer.new()  # The whole strip.
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", InputHintData.HINT_GAP)
	for e: Array in entries:
		row.add_child(hint(e[0], String(e[1])))
	return row


## strip(entries), pinned to the bottom centre of a full-screen parent
## (InputHintData.STRIP_BOTTOM_MARGIN px above its bottom edge): add it as a
## direct child of the screen's full-rect root.
static func bottom_strip(entries: Array) -> HBoxContainer:
	var row := strip(entries)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_top = -InputHintData.STRIP_BOTTOM_MARGIN
	row.offset_bottom = -InputHintData.STRIP_BOTTOM_MARGIN
	return row


## One hint: the chip(s) of `specs` (one spec or an Array of specs) and
## `word`, as a small HBox (hidden while none of its chips shows).
static func hint(specs: Variant, word: String) -> HBoxContainer:
	var h := _Hint.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", InputHintData.CHIP_GAP)
	var list: Array = specs if specs is Array else [specs]  # One or more specs.
	for s: Variant in list:
		var c := chip(s)
		h.add_child(c)
		h.chips.append(c)
	if word != "":
		var gap := Control.new()  # Widens the chip-to-word gap to WORD_GAP.
		gap.custom_minimum_size = Vector2(InputHintData.WORD_GAP - InputHintData.CHIP_GAP, 0)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(gap)
		var l := UiTheme.tier_label(word, UiTheme.Tier.BODY, InputHintData.WORD_COLOR)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	h._refresh()
	return h


## Puts a chip for `spec` inside Button `b`, vertically centred, `inset` px
## from its left edge (or its right edge when `right`). Leave room for it in
## the button's width; the button text stays centred.
static func attach(b: Button, spec: Variant, right: bool = false, inset: float = 8.0) -> Chip:
	var c := chip(spec)
	var h := float(InputHintData.CHIP_HEIGHT)
	c.anchor_left = 1.0 if right else 0.0
	c.anchor_right = c.anchor_left
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_top = -h * 0.5
	c.offset_bottom = h * 0.5
	c.offset_left = -inset if right else inset
	c.offset_right = c.offset_left
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	b.add_child(c)
	return c
