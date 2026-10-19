## EpilogueScreen — the ILLUSTRATED CAMPAIGN EPILOGUE (EpilogueData; GDD
## §15.0 "Ul-Thalos, the Risen Spire" and "Illustrated epilogue (content wave
## 2)"): a short cutscene of slides over a black backdrop, one per paragraph.
## Each slide shows its pixel-art picture panel (assets/sprites/epilogue/,
## 1 art px = 1 layout px through the sharp-pixel shader) in a framed window
## that pans slowly across it, the part's heading and act above, and the
## paragraph fading in under it. A slide moves on by itself after
## EpilogueData.slide_time() (the last one waits); any key, pad button, click
## or tap moves on at once, Esc / pad B or the Skip button (for touch players)
## ends it. A part whose achievement is not earned yet is one "Sealed" slide
## with its goal over its first picture as a dark silhouette; after Act II
## comes the closing card (EpilogueData.CLOSING).
## While it plays the music is the slow "Grave Lullaby" cue
## (Sfx.MUSIC_EPILOGUE; on the Web it may still be rendering for the first
## seconds, the screen does not wait for it), and the menu theme comes back
## when it closes.
## Ways in:
##   * open_over(menu): the main menu's Epilogue item, every part in order
##     (sealed ones as sealed slides);
##   * play_unseen(menu): Main, when the player returns to the menu after a
##     run: only the open parts not seen yet (Meta [epilogue] seen_<id>), and
##     nothing (null) when there are none;
##   * the debug flag `--epilogue` (or `--epilogue=all`: every part as if
##     open, nothing saved) on the command line opens it at startup, for
##     screenshots (Main, debug_request()).
## Every open part shown is marked seen in Meta (never under the autotest,
## which never shows the menu anyway). Motion: real time; with Reduce motion
## (UiMotion.enabled() false) the picture does not pan and every fade is
## instant. Purely cosmetic: no gameplay state, no RNG.
class_name EpilogueScreen
extends Control

## Emitted when the screen is about to be freed.
signal closed

## Command-line user argument that opens the epilogue at startup (debug, screenshots).
const DEBUG_FLAG: String = "--epilogue"
## Its value that shows every part as if open (nothing is marked seen).
const DEBUG_ALL: String = "all"

## True once the startup debug request was handed out (it fires once).
static var _debug_used: bool = false

## Control focused again when the screen closes (may be null).
var return_focus: Control = null
## The slides in order. Each: {"panel": SpriteData key ("" = none),
## "from": Vector2, "to": Vector2 (pan fractions), "act": String,
## "heading": String, "text": String, "tag": String, "sealed": bool}.
var slides: Array = []
## Index of the slide on screen.
var _index: int = 0
## Real seconds the current slide has been on screen.
var _t: float = 0.0
## Real seconds since the last advance (input guard).
var _since_advance: float = 999.0
## True when motion is on (pan and fades); false with Reduce motion.
var _motion: bool = true
## The panning picture window.
var _view: _PictureView
## Part heading of the current slide (HEADER tier, gold).
var _heading: Label
## Act name and slide count (LABEL tier, dim).
var _act: Label
## The paragraph under the picture (NAME tier).
var _text: Label
## Small dim line under the paragraph (the closing card's tag; "" hides it).
var _tag: Label
## The Skip button (top right; never takes focus, so keys stay "next").
var _skip: Button


## The epilogue's picture window: draws the current slide's panel at its pan
## offset and, during a crossfade, the previous slide's frozen view over it,
## both 1 art px = 1 layout px through the sharp-pixel material (set by the
## screen). A missing panel is a flat EMPTY_COLOUR window; a sealed part shows
## its first panel as a dark silhouette (EpilogueData.SEALED_TINT, like the
## Codex's unmet entries).
class _PictureView extends Control:
	## Current slide's texture (null = none).
	var tex: Texture2D = null
	## Colour the current texture is drawn with (white, or the sealed tint).
	var tint: Color = Color.WHITE
	## Current pan offset (art px from the panel's top-left corner).
	var offset: Vector2 = Vector2.ZERO
	## Previous slide's texture during a crossfade (null = none).
	var prev_tex: Texture2D = null
	## Colour the previous texture was drawn with.
	var prev_tint: Color = Color.WHITE
	## Previous slide's frozen offset (art px).
	var prev_offset: Vector2 = Vector2.ZERO
	## Previous slide's opacity (1 -> 0 over EpilogueData.PICTURE_FADE).
	var prev_alpha: float = 0.0
	## True when the previous slide had no picture (fades out an empty window).
	var prev_empty: bool = false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)  # The window.
		draw_rect(r, EpilogueData.EMPTY_COLOUR)
		if tex != null:
			draw_texture_rect_region(tex, r, Rect2(offset, size), tint)
		if prev_alpha > 0.0:
			if prev_tex != null:
				draw_texture_rect_region(prev_tex, r, Rect2(prev_offset, size), Color(prev_tint, prev_alpha))
			elif prev_empty:
				draw_rect(r, Color(EpilogueData.EMPTY_COLOUR, prev_alpha))


## The main menu's Epilogue item: every part in order (sealed ones sealed),
## then the closing card when Act II is open. Marks the open parts seen.
static func open_over(parent: Control) -> EpilogueScreen:
	return _open(parent, _all_slides(false), _open_ids(false))


## After a run: the open parts not seen yet (and the closing card after Act
## II), marked seen; null when there is nothing new (or under the autotest).
static func play_unseen(parent: Control) -> EpilogueScreen:
	if GameState.autotest:
		return null
	var s: Array = []  # The new parts' slides.
	var ids := PackedStringArray()  # Their part ids.
	for part: Dictionary in EpilogueData.PARTS:
		if EpilogueData.is_open(part) and not Meta.is_epilogue_seen(String(part["id"])):
			s.append_array(_part_slides(part))
			ids.append(String(part["id"]))
			if String(part["id"]) == _closing_part_id():
				s.append(_closing_slide())
	if s.is_empty():
		return null
	return _open(parent, s, ids)


## The startup debug request from the command line: "" (none, or already
## used), "open" (`--epilogue`) or "all" (`--epilogue=all`). Fires once.
static func debug_request() -> String:
	if _debug_used or GameState.autotest:
		return ""
	_debug_used = true
	for a: String in OS.get_cmdline_user_args():
		if a == DEBUG_FLAG:
			return "open"
		if a == DEBUG_FLAG + "=" + DEBUG_ALL:
			return DEBUG_ALL
	return ""


## Opens the debug epilogue: every part, as if open when `all` (nothing is saved then).
static func open_debug(parent: Control, all: bool) -> EpilogueScreen:
	return _open(parent, _all_slides(all), PackedStringArray() if all else _open_ids(false))


## Builds the screen over `parent` with `slides_in`, marks `seen_ids` seen
## and returns it. The control focused at that moment regains focus later.
static func _open(parent: Control, slides_in: Array, seen_ids: PackedStringArray) -> EpilogueScreen:
	var s := EpilogueScreen.new()
	var vp := parent.get_viewport()  # Null when the parent is not in the tree.
	s.return_focus = vp.gui_get_focus_owner() if vp != null else null
	s.slides = slides_in
	parent.add_child(s)
	if not seen_ids.is_empty():
		Meta.mark_epilogue_seen(seen_ids)
	return s


## Every part's slides in order (a sealed part as one sealed slide unless
## `all`), then the closing card when the Act II part is open (or `all`).
static func _all_slides(all: bool) -> Array:
	var s: Array = []
	for part: Dictionary in EpilogueData.PARTS:
		if all or EpilogueData.is_open(part):
			s.append_array(_part_slides(part))
			if String(part["id"]) == _closing_part_id():
				s.append(_closing_slide())
		else:
			var goal := String((MetaData.ACHIEVEMENTS[String(part["achievement"])] as Dictionary)["description"])
			var first: Array = (part["panels"] as Array)[0]  # Its first panel, shown as a silhouette.
			s.append({"panel": String(first[0]), "from": first[1], "to": first[2], "act": String(part["act"]),
				"heading": EpilogueData.SEALED_HEADING, "text": EpilogueData.SEALED % goal, "tag": "", "sealed": true})
	return s


## The ids of the open parts (all of them when `all`).
static func _open_ids(all: bool) -> PackedStringArray:
	var ids := PackedStringArray()
	for part: Dictionary in EpilogueData.PARTS:
		if all or EpilogueData.is_open(part):
			ids.append(String(part["id"]))
	return ids


## The part the closing card follows (the last part: Act II).
static func _closing_part_id() -> String:
	return String((EpilogueData.PARTS[EpilogueData.PARTS.size() - 1] as Dictionary)["id"])


## One slide per paragraph of `part`, each with its panel and pan.
static func _part_slides(part: Dictionary) -> Array:
	var s: Array = []
	var lines: Array = part["lines"]
	var panels: Array = part.get("panels", [])
	for i in lines.size():
		var p: Array = panels[i] if i < panels.size() else ["", Vector2(0.5, 0.5), Vector2(0.5, 0.5)]
		s.append({"panel": String(p[0]), "from": p[1], "to": p[2], "act": String(part["act"]),
			"heading": String(part["heading"]), "text": String(lines[i]), "tag": "", "sealed": false})
	return s


## The closing card's slide (EpilogueData.CLOSING).
static func _closing_slide() -> Dictionary:
	var c: Dictionary = EpilogueData.CLOSING
	var p: Array = c["panel"]
	return {"panel": String(p[0]), "from": p[1], "to": p[2], "act": String(c["act"]),
		"heading": String(c["heading"]), "text": String(c["line"]), "tag": String(c["tag"]), "sealed": false}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	_motion = UiMotion.enabled()
	# The black backdrop sits under a holder (not a direct ColorRect child), so
	# the main menu's overlay scrim taming leaves it opaque: this is a cutscene.
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scrim := UiTheme.backdrop(EpilogueData.BACKDROP_ALPHA)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Clicks reach the screen (_gui_input: next).
	holder.add_child(scrim)
	add_child(holder)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	TouchSupport.fit_to_screen(center)  # A short phone layout: shrink to fit (no-op at 720 px).
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", EpilogueData.ROW_GAP)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(col)
	var frame_w := EpilogueData.WINDOW.x + 2.0 * EpilogueData.FRAME_PAD  # Outer width of the picture frame.
	col.add_child(_header(frame_w))
	col.add_child(_frame())
	var text_box := VBoxContainer.new()  # Paragraph and tag, a fixed height so nothing jumps between slides.
	text_box.custom_minimum_size = Vector2(frame_w, EpilogueData.TEXT_HEIGHT)
	text_box.add_theme_constant_override("separation", EpilogueData.TAG_GAP)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = frame_w
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_box.add_child(_text)
	_tag = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_box.add_child(_tag)
	col.add_child(text_box)
	add_child(InputHints.bottom_strip([["ui_accept", "Next"], ["ui_cancel", "Skip"]]))
	get_viewport().gui_release_focus()  # Keys belong to the slides, not to a menu button underneath.
	Sfx.play_music(Sfx.MUSIC_EPILOGUE)
	_show(0)
	UiMotion.open(self)


## The row above the picture: heading on the left, act and count, Skip.
func _header(width: float) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.x = width
	row.add_theme_constant_override("separation", EpilogueData.HEADER_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heading = UiTheme.tier_label("", UiTheme.Tier.HEADER, UiTheme.TEXT_GOLD)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_heading)
	_act = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	_act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_act)
	_skip = Button.new()
	_skip.text = "Skip"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.custom_minimum_size = Vector2(EpilogueData.SKIP_WIDTH, EpilogueData.SKIP_HEIGHT)
	_skip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_skip.set_meta("ui_back", true)  # Sfx: the back sound, not the confirm click.
	_skip.pressed.connect(close)
	row.add_child(_skip)
	return row


## The framed picture window (a violet kit panel around the panning view).
func _frame() -> Control:
	var pad := EpilogueData.FRAME_PAD
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	frame.custom_minimum_size = EpilogueData.WINDOW + Vector2(pad, pad) * 2.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = _PictureView.new()
	_view.position = Vector2(pad, pad)
	_view.size = EpilogueData.WINDOW
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SpriteBank.apply_sharp(_view)
	frame.add_child(_view)
	return frame


## Puts slide `i` on screen: texts, picture, and the crossfade from the last one.
func _show(i: int) -> void:
	var prev: Dictionary = slides[_index] if _index < slides.size() and i != _index else {}
	if not prev.is_empty() and _motion:
		_view.prev_tex = _view.tex
		_view.prev_tint = _view.tint
		_view.prev_offset = _view.offset
		_view.prev_empty = _view.tex == null
		_view.prev_alpha = 1.0
	else:
		_view.prev_alpha = 0.0
	_index = i
	_t = 0.0
	var sl: Dictionary = slides[i]
	var key := String(sl["panel"])
	_view.tex = EnvironmentArt.texture(key) if key != "" else null
	_view.tint = EpilogueData.SEALED_TINT if bool(sl["sealed"]) else Color.WHITE
	_heading.text = String(sl["heading"])
	_heading.add_theme_color_override("font_color", UiTheme.TEXT_DIM if bool(sl["sealed"]) else UiTheme.TEXT_GOLD)
	_act.text = "%s   %d / %d" % [String(sl["act"]), i + 1, slides.size()]
	_text.text = String(sl["text"])
	_text.add_theme_color_override("font_color", UiTheme.TEXT_DIM if bool(sl["sealed"]) else UiTheme.TEXT)
	_tag.text = String(sl["tag"])
	_text.modulate.a = 0.0 if _motion else 1.0
	_tag.modulate.a = _text.modulate.a
	_update_view(0.0)


## Moves the pan, the crossfade (by `dt` real seconds) and the text fade to the current time.
func _update_view(dt: float) -> void:
	var sl: Dictionary = slides[_index]
	var dur := EpilogueData.slide_time(String(sl["text"]))  # This slide's length (s).
	var slack := Vector2.ZERO  # How far the window can travel over the picture (art px).
	if _view.tex != null:
		slack = (Vector2(_view.tex.get_size()) - EpilogueData.WINDOW).max(Vector2.ZERO)
	var f := clampf(_t / dur, 0.0, 1.0) if _motion else 0.5  # Pan progress (Reduce motion: the middle, still).
	f = f * f * (3.0 - 2.0 * f)  # Smoothstep: the pan eases in and out.
	var from: Vector2 = sl["from"]
	var to: Vector2 = sl["to"]
	_view.offset = from.lerp(to, f) * slack  # Sub-pixel: the sharp-pixel shader keeps it crisp and smooth.
	if _motion:
		_view.prev_alpha = maxf(0.0, _view.prev_alpha - dt / EpilogueData.PICTURE_FADE)
		var a := clampf((_t - EpilogueData.TEXT_DELAY) / EpilogueData.TEXT_FADE, 0.0, 1.0)  # Text opacity.
		_text.modulate.a = a
		_tag.modulate.a = a
	_view.queue_redraw()


func _process(delta: float) -> void:
	if UiMotion.is_closing(self) or slides.is_empty():
		return
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # Real seconds (UI never scales).
	_t += dt
	_since_advance += dt
	if _index < slides.size() - 1 and _t >= EpilogueData.slide_time(String((slides[_index] as Dictionary)["text"])):
		_show(_index + 1)
		return
	_update_view(dt)


## Any key or pad button moves on; Esc / pad B ends it. Handled before the GUI,
## so no menu button underneath ever sees them.
func _input(event: InputEvent) -> void:
	if UiMotion.is_closing(self):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	var press := false  # True for a fresh press that should advance.
	if event is InputEventKey:
		press = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventJoypadButton:
		press = (event as InputEventJoypadButton).pressed
	if press:
		get_viewport().set_input_as_handled()
		_press()


## A click or tap anywhere but the Skip button (which takes its own) moves on.
## Taps arrive as emulated mouse clicks.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
		accept_event()
		_press()


## One "next" press, ignored within ADVANCE_GUARD of the previous one.
func _press() -> void:
	if UiMotion.is_closing(self) or _since_advance < EpilogueData.ADVANCE_GUARD:
		return
	_since_advance = 0.0
	advance()


## The next slide, or closes after the last one.
func advance() -> void:
	if _index >= slides.size() - 1:
		close()
		return
	_show(_index + 1)


## Brings the menu music back, restores focus to the opener and frees the screen.
func close() -> void:
	if UiMotion.is_closing(self):
		return
	closed.emit()
	Sfx.play_music(Sfx.MUSIC_MENU)
	if return_focus != null and is_instance_valid(return_focus) and return_focus.is_visible_in_tree():
		return_focus.grab_focus()
	UiMotion.close(self, queue_free)
