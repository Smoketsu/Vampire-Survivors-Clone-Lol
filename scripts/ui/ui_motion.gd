## UiMotion — the shared motion vocabulary of the whole UI (static helpers;
## every number in UiMotionData). Short motion that stops, never busy:
##   * open(root) / close(root, on_done) / hide(root): a screen fades in while
##     its content rises a few px and grows from 0.96 to rest, and fades out
##     quickly before it is freed (close) or hidden (hide). Each plays the
##     soft panel whoosh. A closing screen stops taking mouse and input at
##     once, so a second Esc / B reaches the screen under it.
##   * stagger(nodes): cards, rows or tiles enter one after another (fade,
##     rise, grow with a slight overshoot). settle(nodes) finishes it at once.
##   * Lift and squash (automatic, install() hooks every BaseButton through
##     SceneTree.node_added like UiTheme's _SharpHook): a hovered or focused
##     card / tile rises LIFT_PX and its frame brightens; any button squashes
##     a little while held and springs back. Cards and tiles are recognised by
##     size; meta "ui_lift" true / false forces it, liftable() names the
##     Control to lift when the button is only an underlay (level-up cards),
##     meta "ui_squash" false opts a button out of the squash.
##   * count_up(label, to, fmt): a number rolls up with a rising tick sound.
##   * transition(host, mid): fade through black, call `mid` (switch the
##     screen) while black, fade back in (main menu <-> run, Restart).
## Rules: motion runs on unscaled real time (a driver node steps every UI
## tween with the real frame time, so hit-stop and the autotest's
## Engine.time_scale never touch it), keeps running while the tree is paused,
## and is instant under the autotest and with Settings.reduce_motion
## (enabled()), so it can never gate or delay a run or a test.
## Inside Containers it animates only what a Container does not own or
## re-applies on its own (modulate, scale around pivot_offset, and position
## offsets that are re-based on every sort), and the full-screen content of
## a screen is moved as a whole (the CenterContainer under the screen root).
## Every tween lives on one "channel" per node (meta "_uim_tw_<channel>"): a
## new motion on a channel replaces the old one. Purely visual.
class_name UiMotion
extends RefCounted

## Meta (bool) on a Button: true forces the hover / focus lift, false turns it off.
const META_LIFT: StringName = &"ui_lift"
## Meta (Control) on a Button: the Control that lifts instead of the button
## (set by liftable(); for buttons that are an underlay of a card).
const META_LIFT_TARGET: StringName = &"ui_lift_target"
## Meta (bool) on a Button: false turns its press squash off.
const META_SQUASH: StringName = &"ui_squash"
## Meta (bool) on a screen root opened by open(): marks a UI screen (Sfx
## plays the back sound for Esc / pad B pressed inside one).
const META_SCREEN: StringName = &"ui_screen"
## Meta (bool) on a screen root: true = Esc / pad B inside it is not a "back"
## (the screen gives it another meaning, e.g. claiming a chest), no back sound.
const META_CANCEL_SILENT: StringName = &"ui_cancel_silent"
## Meta (bool) set while a screen closes or hides (cleared by open()).
const META_CLOSING: StringName = &"_uim_closing"
## Meta (bool) set while a node runs its staggered entrance.
const META_ENTERING: StringName = &"_uim_entering"
## Meta (bool) on a lift target: true while it is lifted.
const META_LIFTED: StringName = &"_uim_lifted"
## Meta (float) on a lift target: its rest position.y while lifted (px).
const META_BASE_Y: StringName = &"_uim_base_y"
## Meta (Button) on a lift target: the button whose hover / focus lifts it.
const META_LIFT_SRC: StringName = &"_uim_lift_src"
## Meta (Vector2) on a screen's content: its rest position (px).
const META_BASE_POS: StringName = &"_uim_base_pos"
## Meta key prefix of a node's tween on one channel ("_uim_tw_" + channel).
const META_TWEEN: String = "_uim_tw_"

## Node that steps every UI tween with real time (created on first use).
static var _driver: _Driver = null
## The automatic lift / squash hook (null until install()).
static var _hook: _Hook = null
## CanvasLayer of the fade through black (null until the first transition).
static var _fade_layer: CanvasLayer = null
## Full-screen rect of the fade (its alpha is the fade).
static var _fade_rect: ColorRect = null
## True while a fade through black runs (new requests are ignored).
static var _fading: bool = false


## Steps the UI tweens with unscaled real time. The tweens are created
## paused (the SceneTree never steps them, so Engine.time_scale cannot touch
## them) and advanced here with custom_step().
class _Driver:
	extends Node

	## Tweens still running.
	var tweens: Array[Tween] = []
	## usec timestamp of the last step.
	var _last_usec: int = 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_last_usec = Time.get_ticks_usec()

	func _process(_delta: float) -> void:
		var now := Time.get_ticks_usec()  # Real time now (usec).
		var dt := clampf(float(now - _last_usec) / 1000000.0, 0.0, UiMotionData.MAX_STEP)  # Real step (s).
		_last_usec = now
		var running := tweens  # Tweens to step this frame (new ones go to the fresh list).
		tweens = []
		for tw: Tween in running:
			if tw != null and tw.is_valid() and tw.custom_step(dt):
				tweens.append(tw)


## Connects lift / squash handlers to every BaseButton entering the tree.
class _Hook:
	extends RefCounted

	## SceneTree.node_added: a node entered the tree.
	func on_node_added(n: Node) -> void:
		var b := n as BaseButton
		if b == null or b.has_meta(&"_uim_hooked"):
			return
		b.set_meta(&"_uim_hooked", true)
		b.mouse_entered.connect(_later.bind(b))
		b.mouse_exited.connect(_later.bind(b))
		b.focus_entered.connect(_later.bind(b))
		b.focus_exited.connect(_later.bind(b))
		b.button_down.connect(UiMotion._press.bind(b))
		b.button_up.connect(UiMotion._release.bind(b))

	## Re-evaluates the lift of `b` after this event has settled (hover state
	## is updated after the mouse signals are emitted).
	func _later(b: BaseButton) -> void:
		_now.call_deferred(b)

	## The deferred half of _later(): `b` is untyped because the button may
	## have been freed in between (a typed argument would fail to convert).
	func _now(b: Variant) -> void:
		if is_instance_valid(b):
			UiMotion.refresh_lift(b as BaseButton)


# =====================================================================================
# Switches
# =====================================================================================

## True when UI motion animates; false under the autotest and with the
## "Reduce motion" setting (every motion is then instant).
static func enabled() -> bool:
	return not GameState.autotest and not Settings.reduce_motion


## Installs the automatic lift / squash hook (Main calls it once; skipped
## under the autotest, where motion is off anyway).
static func install() -> void:
	if _hook != null or GameState.autotest:
		return
	_hook = _Hook.new()
	(Engine.get_main_loop() as SceneTree).node_added.connect(_hook.on_node_added)


# =====================================================================================
# Screens: open / close / hide
# =====================================================================================

## Opens screen `root` (a full-rect Control): fades it in, its content (the
## first Container child, normally the CenterContainer holding the panel)
## rises OPEN_RISE px and grows from OPEN_SCALE. Plays the panel whoosh
## when `sound`. Makes `root` visible; does nothing when `root` is already
## open (a panel re-opened while shown, e.g. the next pending level-up).
static func open(root: Control, sound: bool = true) -> void:
	if root.has_meta(META_SCREEN) and root.visible and not root.has_meta(META_CLOSING):
		return
	root.set_meta(META_SCREEN, true)
	_unmeta(root, META_CLOSING)
	var content := _content(root)  # Moved as a whole (null = fade only).
	_kill(root, "panel")
	root.visible = true
	if sound:
		Sfx.play("panel_open")
	if content != null:
		_kill(content, "panel")
		if not content.has_meta(META_BASE_POS):
			content.set_meta(META_BASE_POS, content.position)
	if not enabled():
		_rest(root, content)
		return
	root.modulate.a = 0.0
	var tw := _tween(root, "panel")
	tw.tween_property(root, "modulate:a", 1.0, UiMotionData.OPEN_FADE_TIME)
	if content == null:
		return
	var base: Vector2 = content.get_meta(META_BASE_POS)  # Rest position.
	content.pivot_offset = _size_of(content) * 0.5
	content.scale = Vector2.ONE * UiMotionData.OPEN_SCALE
	content.position = base + Vector2(0.0, UiMotionData.OPEN_RISE)
	var ct := _tween(content, "panel")
	ct.set_parallel(true)
	ct.set_trans(UiMotionData.OPEN_TRANS).set_ease(Tween.EASE_OUT)
	ct.tween_property(content, "scale", Vector2.ONE, UiMotionData.OPEN_TIME)
	ct.tween_property(content, "position", base, UiMotionData.OPEN_TIME)


## Closes screen `root`: it stops taking input at once, fades out quickly,
## then `on_done` runs (normally `queue_free`). Plays the panel close whoosh
## when `sound`. Calling it again while it closes does nothing.
static func close(root: Control, on_done: Callable, sound: bool = true) -> void:
	if root.has_meta(META_CLOSING):
		return
	root.set_meta(META_CLOSING, true)
	_lock_input(root)
	_fade_out(root, on_done, sound)


## Hides panel `root` (kept for re-use): it fades out quickly, then becomes
## invisible and is restored to rest for the next open(). Input stays live
## during the short fade (the run resumes under it). Plays the close whoosh
## when `sound`.
static func hide(root: Control, sound: bool = true) -> void:
	if not root.visible or root.has_meta(META_CLOSING):
		return
	root.set_meta(META_CLOSING, true)
	_fade_out(root, func() -> void:
		root.visible = false
		_unmeta(root, META_CLOSING)
		_rest(root, _content(root)), sound)


## True while `node` is closing or hiding (or already queued for deletion):
## screens use it to ignore a second close request.
static func is_closing(node: Node) -> bool:
	return node.is_queued_for_deletion() or node.has_meta(META_CLOSING)


## Fades `root` (and sinks its content), then runs `on_done`.
static func _fade_out(root: Control, on_done: Callable, sound: bool) -> void:
	if sound:
		Sfx.play("panel_close")
	var content := _content(root)
	_kill(root, "panel")
	if content != null:
		_kill(content, "panel")
	if not enabled() or not root.is_visible_in_tree():
		if on_done.is_valid():
			on_done.call()
		return
	var tw := _tween(root, "panel")
	tw.set_trans(UiMotionData.CLOSE_TRANS).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate:a", 0.0, UiMotionData.CLOSE_TIME)
	if on_done.is_valid():
		tw.tween_callback(on_done)
	if content == null:
		return
	var base: Vector2 = content.get_meta(META_BASE_POS, content.position)  # Rest position.
	content.pivot_offset = _size_of(content) * 0.5
	var ct := _tween(content, "panel")
	ct.set_parallel(true)
	ct.set_trans(UiMotionData.CLOSE_TRANS).set_ease(Tween.EASE_OUT)
	ct.tween_property(content, "scale", Vector2.ONE * UiMotionData.CLOSE_SCALE, UiMotionData.CLOSE_TIME)
	ct.tween_property(content, "position", base + Vector2(0.0, UiMotionData.CLOSE_DROP), UiMotionData.CLOSE_TIME)


## Puts `root` and its `content` at rest (opaque, unscaled, at its rest position).
static func _rest(root: Control, content: Control) -> void:
	root.modulate.a = 1.0
	if content != null:
		content.scale = Vector2.ONE
		content.position = content.get_meta(META_BASE_POS, content.position)


## The part of screen `root` that moves as a whole: its first Container
## child (the CenterContainer holding the panel), or null when `root` is
## itself laid out by a Container (then only its alpha animates).
static func _content(root: Control) -> Control:
	if root.get_parent() is Container:
		return null
	for c: Node in root.get_children():
		if c is Container:
			return c as Control
	return null


## Stops mouse and input handling in `root` and everything under it, and
## drops the keyboard / pad focus if it is still inside (a closing screen).
static func _lock_input(root: Control) -> void:
	root.propagate_call(&"set_mouse_filter", [Control.MOUSE_FILTER_IGNORE])
	for m: StringName in [&"set_process_input", &"set_process_unhandled_input", &"set_process_unhandled_key_input", &"set_process_shortcut_input"]:
		root.propagate_call(m, [false])
	var vp := root.get_viewport()  # Null when not in the tree.
	var f: Control = vp.gui_get_focus_owner() if vp != null else null  # Current focus.
	if f != null and root.is_ancestor_of(f):
		f.release_focus()


# =====================================================================================
# Staggered entrance
# =====================================================================================

## Staggered entrance of `nodes` (Controls: cards, rows, tiles), in order:
## after `delay` s, one starts every `interval` s; each fades in, moves from
## `offset` px off its rest position and grows from STAGGER_SCALE around its
## bottom centre, with a slight overshoot. Works inside Containers. Instant
## (fully shown) when motion is off. settle() finishes it at once.
static func stagger(nodes: Array, delay: float = 0.0, interval: float = UiMotionData.STAGGER_INTERVAL,
		offset: Vector2 = UiMotionData.STAGGER_OFFSET) -> void:
	for i in nodes.size():
		var c := nodes[i] as Control
		if c == null or not is_instance_valid(c):
			continue
		if not enabled():
			c.modulate.a = 1.0
			continue
		c.modulate.a = 0.0
		c.set_meta(META_ENTERING, true)
		var tw := _tween(c, "enter")
		var wait := delay + interval * float(i)  # This node's start time (s).
		if wait > 0.0:
			tw.tween_interval(wait)
		tw.tween_callback(_enter_prep.bind(c, offset))
		tw.tween_property(c, "modulate:a", 1.0, UiMotionData.STAGGER_TIME * 0.6)
		tw.parallel().tween_property(c, "scale", Vector2.ONE, UiMotionData.STAGGER_TIME) \
				.set_trans(UiMotionData.STAGGER_TRANS).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "position", -offset, UiMotionData.STAGGER_TIME).as_relative() \
				.set_trans(UiMotionData.STAGGER_TRANS).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_enter_done.bind(c))


## Finishes the running entrances (and open / close motions) of `nodes` at
## once, e.g. when the player skips a reveal or acts during an entrance.
static func settle(nodes: Array) -> void:
	for n: Variant in nodes:
		var c := n as Node
		if c == null or not is_instance_valid(c):
			continue
		for ch: String in ["enter", "panel"]:
			var tw := _meta(c, META_TWEEN + ch) as Tween  # Running tween on that channel.
			if tw != null and tw.is_valid():
				tw.custom_step(1000.0)


## Entrance start (after layout): sets the pivot and the start pose.
static func _enter_prep(c: Control, offset: Vector2) -> void:
	c.pivot_offset = Vector2(c.size.x * 0.5, c.size.y)
	c.scale = Vector2.ONE * UiMotionData.STAGGER_SCALE
	c.position += offset


## Entrance end: back to the layout's own position, then any pending lift.
static func _enter_done(c: Control) -> void:
	_unmeta(c, META_ENTERING)
	_resort(c)
	var src := _meta(c, META_LIFT_SRC) as BaseButton  # Button lifting this card.
	refresh_lift(src if src != null and is_instance_valid(src) else c as BaseButton)


# =====================================================================================
# Lift and press squash
# =====================================================================================

## Makes `button` lift on hover / focus (even below the automatic size
## rule). `target` is the Control that rises (default: the button itself),
## e.g. the whole level-up card whose underlay the button is.
static func liftable(button: BaseButton, target: Control = null) -> void:
	button.set_meta(META_LIFT, true)
	if target != null and target != button:
		button.set_meta(META_LIFT_TARGET, target)
		target.set_meta(META_LIFT_SRC, button)


## Lifts or lowers the card of `b` to match its hover / focus state (the
## automatic hook calls it; screens may call it after changing a button).
static func refresh_lift(b: BaseButton) -> void:
	if b == null or not is_instance_valid(b) or not b.is_inside_tree():
		return
	var target := _lift_target(b)  # What rises (null = this button does not lift).
	if target == null or target.has_meta(META_ENTERING):
		return
	var want := b.is_visible_in_tree() and not b.disabled and (b.has_focus() or b.is_hovered())  # Should be lifted.
	if want == bool(target.get_meta(META_LIFTED, false)):
		return
	if want and not enabled():
		return
	target.set_meta(META_LIFTED, want)
	if want and not target.has_meta(META_BASE_Y):
		target.set_meta(META_BASE_Y, target.position.y)
	var base: float = target.get_meta(META_BASE_Y, target.position.y)  # Rest y (px).
	if not enabled():
		_kill(target, "lift")
		target.position.y = base
		b.self_modulate = Color.WHITE
		_lift_rest(target)
		return
	var bright := Color(UiMotionData.LIFT_BRIGHT, UiMotionData.LIFT_BRIGHT, UiMotionData.LIFT_BRIGHT)  # Lifted frame tint.
	var tw := _tween(target, "lift")
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(target, "position:y", base - UiMotionData.LIFT_PX if want else base, UiMotionData.LIFT_TIME)
	tw.tween_property(b, "self_modulate", bright if want else Color.WHITE, UiMotionData.LIFT_TIME)
	if not want:
		tw.chain().tween_callback(_lift_rest.bind(target))


## The lift is fully down: forget the rest y and let the layout re-apply.
static func _lift_rest(target: Control) -> void:
	_unmeta(target, META_BASE_Y)
	_resort(target)


## The Control that lifts for button `b`, or null when it does not lift:
## meta "ui_lift" false = never; a liftable() target; meta true or a card /
## tile size (UiMotionData.LIFT_MIN_HEIGHT / LIFT_MAX_WIDTH) = the button.
static func _lift_target(b: BaseButton) -> Control:
	var flag: Variant = _meta(b, META_LIFT)  # Forced on / off (null = by size).
	if flag is bool and not bool(flag):
		return null
	var t := _meta(b, META_LIFT_TARGET) as Control  # Named target.
	if t != null and is_instance_valid(t):
		return t
	if flag is bool and bool(flag):
		return b
	if b.size.y >= UiMotionData.LIFT_MIN_HEIGHT and b.size.x <= UiMotionData.LIFT_MAX_WIDTH:
		return b
	return null


## button_down: squashes the button (or its card) a little around its centre.
static func _press(b: BaseButton) -> void:
	var t := _squash_target(b)
	if t == null:
		return
	var s := _size_of(t)
	var k := maxf(UiMotionData.PRESS_SCALE, 1.0 - 2.0 * UiMotionData.PRESS_MAX_PX / maxf(1.0, maxf(s.x, s.y)))  # Press scale.
	t.pivot_offset = s * 0.5
	var tw := _tween(t, "squash")
	tw.tween_property(t, "scale", Vector2.ONE * k, UiMotionData.PRESS_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## button_up: springs the button (or its card) back to rest, if it was
## squashed (even when the press disabled the button, e.g. the last reroll).
static func _release(b: BaseButton) -> void:
	if not is_instance_valid(b):
		return
	var t := _card_of(b)
	if not t.has_meta(META_TWEEN + "squash"):
		return
	if not enabled():
		_kill(t, "squash")
		t.scale = Vector2.ONE
		return
	var tw := _tween(t, "squash")  # Replaces a press squash that may not have finished.
	tw.tween_property(t, "scale", Vector2.ONE, UiMotionData.RELEASE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_squash_rest.bind(t))


## The squash is over: forget it and let the layout re-apply.
static func _squash_rest(t: Control) -> void:
	_unmeta(t, META_TWEEN + "squash")
	_resort(t)


## What squashes for button `b` (its card, else itself), or null when the
## squash is off for it (meta "ui_squash" false, motion off, mid-entrance,
## disabled).
static func _squash_target(b: BaseButton) -> Control:
	if not is_instance_valid(b) or b.disabled or not enabled() or b.get_meta(META_SQUASH, true) == false:
		return null
	var t := _card_of(b)
	return null if t.has_meta(META_ENTERING) else t


## The card button `b` underlays (liftable() target), else `b` itself.
static func _card_of(b: BaseButton) -> Control:
	var t := _meta(b, META_LIFT_TARGET) as Control  # A card the button underlays.
	return t if t != null and is_instance_valid(t) else b


# =====================================================================================
# Count-up
# =====================================================================================

## Rolls `label`'s number from `from` to `to` (shown as `fmt % value`, e.g.
## "+%d SOUL ASH") over `duration` s after `delay` s, with a rising tick
## sound when `tick`. Instant (final text) when motion is off.
static func count_up(label: Label, to: int, fmt: String = "%d", from: int = 0, tick: bool = true,
		delay: float = UiMotionData.COUNT_DELAY, duration: float = UiMotionData.COUNT_TIME) -> void:
	_kill(label, "count")
	if not enabled() or to == from:
		label.text = fmt % to
		return
	label.text = fmt % from
	var tw := _tween(label, "count")
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(_count_step.bind(label, fmt, from, to, tick), 0.0, 1.0, duration) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


## One count-up step at progress `p` (0..1): writes the value and ticks when it changed.
static func _count_step(p: float, label: Label, fmt: String, from: int, to: int, tick: bool) -> void:
	var text := fmt % roundi(lerpf(float(from), float(to), p))  # Text at this step.
	if text == label.text:
		return
	label.text = text
	if tick:
		Sfx.play("ui_tick", Vector2.INF, lerpf(1.0, UiMotionData.COUNT_TICK_PITCH_END, p))


# =====================================================================================
# Fade through black
# =====================================================================================

## Fades the screen to black, calls `mid` (switch screens: free the menu,
## build the run...), holds a moment and fades back in. The fade layer lives
## under `host` (Main), on top of everything; input is off while it runs.
## Instant (just `mid`) when motion is off; ignored while a fade runs.
static func transition(host: Node, mid: Callable) -> void:
	if not enabled():
		mid.call()
		return
	if _fading:
		return
	_ensure_fade(host)
	_fading = true
	var vp := host.get_viewport()  # The window (input off during the fade).
	vp.set_disable_input(true)
	_fade_rect.color = Color(UiMotionData.FADE_COLOR, 0.0)
	_fade_rect.visible = true
	var tw := _tween(_fade_rect, "fade")
	tw.tween_property(_fade_rect, "color:a", 1.0, UiMotionData.FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mid)
	tw.tween_interval(UiMotionData.FADE_HOLD_TIME)
	tw.tween_callback(func() -> void: vp.set_disable_input(false))
	tw.tween_property(_fade_rect, "color:a", 0.0, UiMotionData.FADE_IN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_fade_done)


## True while a fade through black runs.
static func fading() -> bool:
	return _fading


## Builds the fade layer under `host` once (always processing, above all UI).
static func _ensure_fade(host: Node) -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer):
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = UiMotionData.FADE_LAYER
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.visible = false
	_fade_layer.add_child(_fade_rect)
	host.add_child(_fade_layer)


## The fade is over: hide the layer and accept new fades.
static func _fade_done() -> void:
	_fading = false
	if _fade_rect != null and is_instance_valid(_fade_rect):
		_fade_rect.visible = false


# =====================================================================================
# Tween plumbing
# =====================================================================================

## A new real-time tween bound to `node` on `channel` (the previous tween on
## that channel is killed): created paused and stepped by the driver.
static func _tween(node: Node, channel: String) -> Tween:
	_kill(node, channel)
	_ensure_driver()
	var tw := node.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.pause()
	node.set_meta(META_TWEEN + channel, tw)
	_driver.tweens.append(tw)
	return tw


## Kills `node`'s tween on `channel`, if any.
static func _kill(node: Node, channel: String) -> void:
	var key := META_TWEEN + channel  # Meta key of that channel.
	var tw := _meta(node, key) as Tween  # Running tween (may be dead).
	if tw != null and tw.is_valid():
		tw.kill()
	_unmeta(node, key)


## Meta `key` of `node`, or null when it has none (get_meta() with a null
## default reports an error for a missing key).
static func _meta(node: Object, key: StringName) -> Variant:
	return node.get_meta(key) if node.has_meta(key) else null


## Removes meta `key` from `node` when it is there (remove_meta() of a
## missing key reports an error).
static func _unmeta(node: Object, key: StringName) -> void:
	if node.has_meta(key):
		node.remove_meta(key)


## Adds the real-time driver to the tree on first use.
static func _ensure_driver() -> void:
	if _driver != null and is_instance_valid(_driver):
		return
	_driver = _Driver.new()
	_driver.name = "UiMotionDriver"
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_driver)


## Asks `c`'s Container parent (if any) to lay it out again, so a position
## the motion borrowed snaps back to the layout's own value.
static func _resort(c: Control) -> void:
	if c != null and is_instance_valid(c) and c.get_parent() is Container:
		(c.get_parent() as Container).queue_sort()


## `c`'s size, or the viewport size while it has not been laid out yet.
static func _size_of(c: Control) -> Vector2:
	if c.size.x > 0.0 and c.size.y > 0.0:
		return c.size
	return c.get_viewport_rect().size if c.is_inside_tree() else Vector2.ZERO
