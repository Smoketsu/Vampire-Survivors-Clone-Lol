## TouchSupport: phone and tablet support outside the run (GDD §15.0 "Mobile
## browser support"; numbers in TouchData). Main installs ONE of these nodes
## at startup (install(); never under the autotest). It:
##   * tells whether this is a phone or tablet (is_mobile(): on the Web build
##     the browser's primary pointer is a finger, TouchData.MOBILE_QUERY);
##     the input hints then start in InputHints.Device.TOUCH (no key chips,
##     the in-run TouchControls show) and the Effects setting defaults to
##     Reduced (Settings);
##   * applies the mobile UI scale: on a short phone screen in landscape the
##     root Window's content_scale_factor grows until the visible layout area
##     is TouchData.UI_SCALE_MIN_SIZE (at most TouchData.UI_SCALE_MAX), so
##     text and buttons are bigger under the finger; recomputed whenever the
##     window size changes (rotation, browser bars). Desktop never scales;
##   * shows the "turn your device" overlay (RotateOverlay) while a phone or
##     tablet is held in portrait, and reports it (portrait_changed) so Main
##     pauses a running game. A browser can only lock the orientation in
##     fullscreen: the Web shell (web/mobile_shell.html) asks for landscape
##     when the page enters fullscreen; the overlay covers every other case.
##   * on a phone's Web build, caps the canvas resolution (GDD §15.0 "Phone
##     resolution cap"): the page's drawing buffer is css px x devicePixelRatio
##     (3 on an iPhone), which the GPU fills every frame; the shell's
##     necroSetCanvasCap() lowers it to TouchData.CANVAS_DPR_CAP device px per
##     CSS px. Every CSS-size calculation then reads css_scale() (the scale the
##     buffer really has) instead of DisplayServer.screen_get_scale() (which
##     stays the browser's devicePixelRatio), so the UI scale and the thumb-sized
##     controls stay the same size under the finger;
## Static helpers used by the screens: layout_per_css() (layout px per CSS
## px, for thumb-sized controls), css_scale() and pass_drags() (lets a finger
## drag a ScrollContainer that is full of buttons).
## Purely presentation: it never reads or changes gameplay state or RNG.
class_name TouchSupport
extends Node

## The window turned to portrait (true) or back to landscape (false), on a
## phone or tablet only.
signal portrait_changed(portrait: bool)

## Cached is_mobile() answer (-1 = not asked yet, 0 = no, 1 = yes).
static var _mobile: int = -1
## The installed node (null until install(); at most one per session).
static var _instance: TouchSupport = null

## Device px per CSS px of the window as last read (css_scale(); 0 = not read yet).
static var _css_scale: float = 0.0

## The portrait overlay (hidden in landscape).
var _overlay: RotateOverlay = null
## Whether the window was portrait at the last size check.
var _portrait: bool = false


## True on a phone or tablet (never under the autotest or headless): the Web
## build asks the browser (TouchData.MOBILE_QUERY), a native mobile export
## would answer by its OS. Cached after the first call. The co-op screenshot
## walk (--coop-shots=, debug) asks like a player's run, so its phone shots
## show the phone layout.
static func is_mobile() -> bool:
	if _mobile < 0:
		_mobile = 1 if _detect() else 0
	return _mobile == 1


## True under an autotest that keeps the device's own look (the co-op
## screenshot walk, --coop-shots=; debug).
static func _autotest_blind() -> bool:
	return GameState.autotest and GameState.autotest_coop_shots == ""


## The detection itself (see is_mobile()).
static func _detect() -> bool:
	if _autotest_blind() or DisplayServer.get_name() == "headless":
		return false
	if OS.has_feature("web"):
		# A JS boolean comes back as a bool or a number depending on the
		# bridge: ask for 1 / 0 and accept either numeric type.
		var answer: Variant = JavaScriptBridge.eval("(%s) ? 1 : 0" % TouchData.MOBILE_QUERY, true)
		return (typeof(answer) == TYPE_INT or typeof(answer) == TYPE_FLOAT or typeof(answer) == TYPE_BOOL) and int(answer) == 1
	return OS.has_feature("mobile")


## Installs the one TouchSupport node under `parent` (Main): the starting
## input device, the UI scale and the portrait overlay. Returns the node
## (its portrait_changed signal); null under the autotest (but the
## --coop-shots walk's).
static func install(parent: Node) -> TouchSupport:
	if OS.has_feature("web") and DisplayServer.get_name() != "headless" and _phone_browser():
		_cap_canvas()  # Drawing resolution only: also under the autotest (the Web perf measurement).
	if _autotest_blind():
		return null
	if _instance != null and is_instance_valid(_instance):
		return _instance
	_instance = TouchSupport.new()
	_instance.name = "TouchSupport"
	parent.add_child(_instance)
	return _instance


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_mobile():
		InputHints.set_device(InputHints.Device.TOUCH)
	_overlay = RotateOverlay.new()
	add_child(_overlay)
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()


## True when the browser's main pointer is a finger (TouchData.MOBILE_QUERY), asked
## directly: unlike is_mobile() also under the autotest, whose runs keep the
## desktop layout and hints but may still be measured at a phone's resolution
## (the canvas cap changes only how many device px are drawn, never the layout).
static func _phone_browser() -> bool:
	var answer: Variant = JavaScriptBridge.eval("(%s) ? 1 : 0" % TouchData.MOBILE_QUERY, true)
	return (typeof(answer) == TYPE_INT or typeof(answer) == TYPE_FLOAT or typeof(answer) == TYPE_BOOL) and int(answer) == 1


## Web build on a phone: asks the page (web/mobile_shell.html) to draw at most
## TouchData.CANVAS_DPR_CAP device px per CSS px. An older page without the hook
## is left as it is.
static func _cap_canvas() -> void:
	if not OS.has_feature("web") or TouchData.CANVAS_DPR_CAP <= 0.0:
		return
	JavaScriptBridge.eval("window.necroSetCanvasCap && window.necroSetCanvasCap(%s)" % str(TouchData.CANVAS_DPR_CAP), true)
	_css_scale = 0.0  # Read again.


## Device px per CSS px of the window: on the Web build the scale the page really
## drew the canvas at (window.necroCanvasScale, which the phone resolution cap
## lowers below devicePixelRatio), elsewhere DisplayServer.screen_get_scale().
## Cached; re-read on every window resize.
static func css_scale() -> float:
	if _css_scale <= 0.0:
		_css_scale = DisplayServer.screen_get_scale()
		if OS.has_feature("web"):
			var v: Variant = JavaScriptBridge.eval("window.necroCanvasScale || window.devicePixelRatio || 1", true)
			if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and float(v) > 0.0:
				_css_scale = float(v)
	return maxf(_css_scale, 0.01)


## Window size changed: re-apply the UI scale and the portrait overlay.
func _on_resize() -> void:
	var root := get_tree().root
	_css_scale = 0.0  # The page may have refitted the canvas (rotation, browser bars).
	if is_mobile():  # A desktop keeps its factor untouched.
		root.content_scale_factor = ui_scale(Vector2(root.size), css_scale())
	var portrait := is_mobile() and root.size.y > root.size.x
	_overlay.visible = portrait
	if portrait != _portrait:
		_portrait = portrait
		portrait_changed.emit(portrait)


## The mobile UI scale for a window of `win` device px at `dpr` device px per
## CSS px: 1 except on a phone held in landscape, where it grows the layout
## (canvas_items / expand stretch from 1280 x 720) until the visible area is
## TouchData.UI_SCALE_MIN_SIZE, at most TouchData.UI_SCALE_MAX.
static func ui_scale(win: Vector2, dpr: float) -> float:
	if not is_mobile() or win.x <= 0.0 or win.y <= 0.0 or win.y > win.x:
		return 1.0
	if win.y / maxf(dpr, 0.01) > TouchData.UI_SCALE_MAX_CSS_HEIGHT:
		return 1.0  # A tablet: the desktop layout is big enough.
	var base := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 1280),
		ProjectSettings.get_setting("display/window/size/viewport_height", 720))  # The design layout.
	var fit := minf(win.x / base.x, win.y / base.y)  # The stretch scale at factor 1.
	var layout := win / fit  # Visible layout area at factor 1 (expand: one side is longer).
	var room := minf(layout.x / TouchData.UI_SCALE_MIN_SIZE.x, layout.y / TouchData.UI_SCALE_MIN_SIZE.y)  # Growth that still fits.
	return clampf(room, 1.0, TouchData.UI_SCALE_MAX)


## Layout px per CSS px in viewport `vp` (its visible layout height over the
## window's CSS height), at least TouchData.MIN_LAYOUT_PER_CSS. Sizes in CSS
## px times this give thumb-sized layout px on any screen.
static func layout_per_css(vp: Viewport) -> float:
	var win := DisplayServer.window_get_size()  # Device px.
	var css_h := float(win.y) / css_scale()  # Window height in CSS px.
	if css_h <= 0.0:
		return TouchData.MIN_LAYOUT_PER_CSS
	return maxf(vp.get_visible_rect().size.y / css_h, TouchData.MIN_LAYOUT_PER_CSS)


## Keeps a screen's content on screen: `holder` is a full-screen Container
## or Control at the screen's origin (a screen's CenterContainer, or a
## column's parent), and the content is its child `only` (or every child
## when null). Content that sticks out of the visible area is scaled down
## uniformly to fit it with TouchData.FIT_MARGIN to spare: centred on the
## screen, or with `from_top` keeping its top edge (a column anchored to the
## top, which can only run off the bottom). The mobile UI scale makes the
## visible area shorter than the 720 px the screens were laid out for, and a
## CenterContainer grows past the screen with a tall child, so a long
## level-up card or the Codex panel would be cut off. At the desktop's
## layout (never shorter than 720 px) nothing sticks out and no scale is
## touched. Re-checked whenever the holder re-lays out its children.
static func fit_to_screen(holder: Control, only: Control = null, from_top: bool = false) -> void:
	var refit := func() -> void: _fit_children.call_deferred(holder, only, from_top)
	holder.resized.connect(refit)
	if holder is Container:
		(holder as Container).sort_children.connect(refit)
	var watch := func(c: Node) -> void:
		if c is Control and (only == null or c == only):
			(c as Control).resized.connect(refit)
	for c: Node in holder.get_children():
		watch.call(c)
	holder.child_entered_tree.connect(watch)  # Children added after the call.
	refit.call()


## Applies fit_to_screen() to the content of `holder` once.
static func _fit_children(holder: Control, only: Control, from_top: bool) -> void:
	if not is_instance_valid(holder) or not holder.is_inside_tree():
		return
	var view := holder.get_viewport_rect().size  # Visible layout area (the holder's rest frame starts at 0, 0).
	var m := TouchData.FIT_MARGIN
	for n: Node in holder.get_children():
		var c := n as Control
		if c == null or (only != null and c != only) or not c.visible or c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var r := Rect2(c.position, c.size)  # Unscaled rect in the holder.
		var k := 1.0  # Scale that fits.
		if not Rect2(Vector2.ZERO, view).encloses(r):
			k = minf((view.x - 2.0 * m) / r.size.x, (view.y - 2.0 * m) / r.size.y)
			if from_top:
				k = minf((view.x - 2.0 * m) / r.size.x, (view.y - m - r.position.y) / r.size.y)
			k = clampf(k, 0.1, 1.0)
		if k >= 1.0:
			if c.has_meta(&"touch_fit"):
				c.scale = Vector2.ONE  # Fits again (the window grew).
				c.remove_meta(&"touch_fit")
			continue  # Fits: leave it alone (always the case on a desktop).
		c.set_meta(&"touch_fit", true)
		if from_top:
			c.pivot_offset = Vector2(r.size.x * 0.5, 0.0)  # Top centre stays put.
		else:
			# Pivot chosen so the scaled rect is centred on the screen:
			# pivot + k * (centre - pivot) = screen centre.
			var p := (view * 0.5 - r.get_center() * k) / (1.0 - k)  # Pivot in the holder.
			c.pivot_offset = p - r.position
		c.scale = Vector2(k, k)


## Lets a finger drag-scroll ScrollContainer `scroll` even when it starts on
## one of its buttons: every BaseButton under it passes its mouse events on
## (MOUSE_FILTER_PASS), so the container sees the drag and, past its dead
## zone, cancels the button's press (Godot's NOTIFICATION_SCROLL_BEGIN). A
## tap still presses the button. Without a touchscreen the container ignores
## left-button drags, so a desktop behaves exactly as before.
static func pass_drags(scroll: ScrollContainer) -> void:
	_pass_under(scroll)


## Sets MOUSE_FILTER_PASS on every BaseButton under `n` (recursive).
static func _pass_under(n: Node) -> void:
	for c: Node in n.get_children():
		if c is BaseButton:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_under(c)
