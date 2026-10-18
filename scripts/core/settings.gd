## Settings — player options autoload. Loads user://settings.cfg (ConfigFile)
## at startup, applies it, and saves it when the Settings menu closes
## (GDD §10.5 / §13.4 readability toggles, §15.7 q49 remapping, q50 "what
## persists": only these options so far).
##   * Volumes: Master / Music / SFX, linear 0..1 per bus (0 mutes the bus).
##   * Screen shake and floating damage numbers on/off (read by Juice).
##   * Volleys on/off: the bullet heaven pass (summon volleys, spell patterns,
##     the Rally Barrage, denser fodder; VolleyData), applied from the next run.
##   * Reduce motion on/off (read by UiMotion.enabled(): every UI motion,
##     panel open / close, entrances, lift, squash, count-ups and the fade
##     through black, becomes instant).
##   * Effects quality, Full / Reduced (EffectsData; GDD §15.0 "Mobile
##     browser support"): Reduced draws fewer particles, damage numbers and
##     cosmetic effects and halves the screen shake, purely visually (read
##     by FxLayer, EffectManager and Juice through reduced_effects()). With
##     no saved value a phone or tablet starts on Reduced, a desktop on
##     Full; the autotest always plays on Full.
##   * Fullscreen on/off (ignored on the headless display server). On the
##     Web build it is the browser's fullscreen (GDD §15.0 "Web build"): it is
##     never restored at startup (a browser only allows it right after a click
##     or key press, so the toggle in Settings works), and `fullscreen` follows
##     the page's real state (Esc or F11 change it outside the game;
##     sync_fullscreen()). Where the browser has no page fullscreen (iPhone
##     Safari) the Settings screen shows a line instead (fullscreen_mode()).
##   * Keyboard rebinding of the REBINDABLE actions. Only the PRIMARY
##     keyboard key of each action (its first InputEventKey in the project
##     InputMap) is remapped; secondary keys (arrow keys) and gamepad
##     bindings stay as they are. Binding a key that another rebindable
##     action already uses as its primary swaps the two keys.
## In autotest mode the file is still read (so a broken file shows up in the
## test log) but never written.
extends Node

## Emitted after any option changed and was applied.
signal changed

## Settings file location.
const PATH: String = "user://settings.cfg"
## Actions the player may rebind (keyboard primary key only), in menu order.
## (`dash` = Grave Step, `ultimate` = Dread Rally, GDD §5.5; `stance_*` = the army stances.)
const REBINDABLE: Array = ["move_up", "move_down", "move_left", "move_right", "toggle_aim", "dash", "ultimate", "pause",
	"stance_escort", "stance_onslaught", "stance_spearhead", "stance_bone_ring"]
## Menu labels for REBINDABLE actions.
const ACTION_LABELS: Dictionary = {"move_up": "Move up", "move_down": "Move down", "move_left": "Move left",
	"move_right": "Move right", "toggle_aim": "Shadow Bolt aim", "dash": "Grave Step (dash)",
	"ultimate": "Dread Rally (ultimate)", "pause": "Pause",
	"stance_escort": "Stance: Escort", "stance_onslaught": "Stance: Onslaught", "stance_spearhead": "Stance: Spearhead",
	"stance_bone_ring": "Stance: Bone Ring"}
## fullscreen_mode(): the Settings screen shows the Fullscreen toggle.
const FULLSCREEN_TOGGLE: int = 0
## fullscreen_mode(): already fullscreen (home-screen launch), no row at all.
const FULLSCREEN_NONE: int = 1
## fullscreen_mode(): no Fullscreen API, the game is the page: the "Add to Home Screen" line.
const FULLSCREEN_HOME_SCREEN: int = 2
## fullscreen_mode(): no Fullscreen API and embedded in another page: the "not here" line.
const FULLSCREEN_UNAVAILABLE: int = 3
## Default bus volumes (linear 0..1).
const DEFAULT_VOLUMES: Dictionary = {"Master": 0.8, "Music": 0.6, "SFX": 0.8}  # TUNING (not in GDD)

## Linear volume (0..1) per bus name ("Master", "Music", "SFX").
var volumes: Dictionary = DEFAULT_VOLUMES.duplicate()
## Camera screen shake enabled.
var screen_shake: bool = true
## Floating damage numbers enabled.
var damage_numbers: bool = true
## True = UI motion is instant (accessibility "Reduce motion"; UiMotion).
var reduce_motion: bool = false
## Bullet heaven pass (VolleyData; GDD §15.0 "Bullet heaven pass"): true = summon volleys,
## spell patterns, the Rally Barrage and the denser fodder waves. Read once when a run
## starts (Game.volleys_on), so a change applies from the next run. Default on.
var volleys: bool = true
## Effects quality: an EffectsData.ORDER value ("full" / "reduced"); set in
## _ready() from the device until a saved value overrides it.
var effects: String = EffectsData.DEFAULT_DESKTOP
## Fullscreen window.
var fullscreen: bool = false
## Cached fullscreen_mode() (-1 = not asked yet, else a FULLSCREEN_* value).
var _fullscreen_mode: int = -1
## Camera zoom level id (ViewData.ZOOM_LEVELS key).
var zoom_id: String = ViewData.DEFAULT_ZOOM
## action -> physical keycode of its primary keyboard key (current).
var key_bindings: Dictionary = {}
## action -> physical keycode of its primary key in project.godot (defaults).
var default_bindings: Dictionary = {}
## Load result of the last load_settings() call (OK, ERR_FILE_NOT_FOUND...).
var last_load_error: Error = OK


func _ready() -> void:
	for action: String in REBINDABLE:
		var kc := _primary_key(action)
		default_bindings[action] = kc
		key_bindings[action] = kc
	effects = _default_effects()
	load_settings()


## Reads PATH (missing keys keep their defaults) and applies everything.
func load_settings() -> void:
	var cfg := ConfigFile.new()
	last_load_error = cfg.load(PATH)
	if last_load_error == OK:
		for bus: String in DEFAULT_VOLUMES.keys():
			volumes[bus] = clampf(float(cfg.get_value("audio", bus.to_lower(), DEFAULT_VOLUMES[bus])), 0.0, 1.0)
		screen_shake = bool(cfg.get_value("feel", "screen_shake", true))
		damage_numbers = bool(cfg.get_value("feel", "damage_numbers", true))
		reduce_motion = bool(cfg.get_value("feel", "reduce_motion", false))
		volleys = bool(cfg.get_value("feel", "volleys", true))
		var fx := String(cfg.get_value("video", "effects", _default_effects()))  # Saved effects quality.
		effects = fx if EffectsData.ORDER.has(fx) else _default_effects()
		fullscreen = bool(cfg.get_value("video", "fullscreen", false))
		var z := String(cfg.get_value("video", "zoom", ViewData.DEFAULT_ZOOM))  # Saved zoom id.
		zoom_id = z if ViewData.ZOOM_LEVELS.has(z) else ViewData.DEFAULT_ZOOM  # The dropped "far" (or junk) loads as Normal.
		for action: String in REBINDABLE:
			var kc := int(cfg.get_value("input", action, default_bindings[action]))
			if kc > 0:
				key_bindings[action] = kc
	apply_all()


## Writes the current options to PATH (skipped in autotest mode).
func save_settings() -> Error:
	if GameState.autotest:
		return OK
	var cfg := ConfigFile.new()
	for bus: String in DEFAULT_VOLUMES.keys():
		cfg.set_value("audio", bus.to_lower(), volumes[bus])
	cfg.set_value("feel", "screen_shake", screen_shake)
	cfg.set_value("feel", "damage_numbers", damage_numbers)
	cfg.set_value("feel", "reduce_motion", reduce_motion)
	cfg.set_value("feel", "volleys", volleys)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "zoom", zoom_id)
	cfg.set_value("video", "effects", effects)
	for action: String in REBINDABLE:
		cfg.set_value("input", action, key_bindings[action])
	return cfg.save(PATH)


## Applies every option to the engine.
func apply_all() -> void:
	for bus: String in DEFAULT_VOLUMES.keys():
		_apply_volume(bus)
	if OS.has_feature("web"):
		sync_fullscreen()  # No user gesture here: the browser would refuse.
	else:
		_apply_fullscreen()
	for action: String in REBINDABLE:
		_apply_binding(action)
	changed.emit()


# =====================================================================================
# Setters used by the Settings menu (apply immediately; saved on close)
# =====================================================================================

## Sets the camera zoom level (a ViewData.ZOOM_LEVELS id); a running game
## picks it up through the `changed` signal.
func set_zoom(id: String) -> void:
	if ViewData.ZOOM_LEVELS.has(id):
		zoom_id = id
		changed.emit()


## Camera zoom factor for the current setting (always GAMEPLAY_ZOOM in the
## autotest, so headless runs never depend on a player's settings).
func zoom_value() -> float:
	if GameState.autotest:
		return ViewData.GAMEPLAY_ZOOM
	return float(ViewData.ZOOM_LEVELS[zoom_id]["zoom"])


## Sets a bus volume (linear 0..1).
func set_volume(bus: String, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	changed.emit()


## Enables / disables the bullet heaven pass (from the next run on).
func set_volleys(on: bool) -> void:
	volleys = on
	changed.emit()


## Enables / disables screen shake.
func set_screen_shake(on: bool) -> void:
	screen_shake = on
	changed.emit()


## Enables / disables floating damage numbers.
func set_damage_numbers(on: bool) -> void:
	damage_numbers = on
	changed.emit()


## Sets the effects quality (an EffectsData.ORDER value).
func set_effects(value: String) -> void:
	if EffectsData.ORDER.has(value):
		effects = value
		changed.emit()


## True while effects are Reduced (never in the autotest, whose runs must not
## depend on a player's settings; purely visual either way).
func reduced_effects() -> bool:
	return effects == "reduced" and not GameState.autotest


## The effects quality used when none is saved: Reduced on a phone or tablet.
func _default_effects() -> String:
	return EffectsData.DEFAULT_MOBILE if TouchSupport.is_mobile() else EffectsData.DEFAULT_DESKTOP


## Enables / disables reduced UI motion (UiMotion becomes instant).
func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	changed.emit()


## Web build: sets `fullscreen` from the page's real state (the player can
## leave the browser's fullscreen with Esc, or enter it with F11). Called by
## apply_all() and when the Settings menu builds its toggle.
func sync_fullscreen() -> void:
	if OS.has_feature("web"):
		fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


## What the Settings screen offers for fullscreen (GDD §15.0 "iPhone sound and
## fullscreen"): FULLSCREEN_TOGGLE (desktop, and browsers with the Fullscreen API),
## FULLSCREEN_NONE (already fullscreen: a home-screen launch), FULLSCREEN_HOME_SCREEN
## (no Fullscreen API, the game is the page: iPhone Safari, where "Add to Home Screen"
## opens it fullscreen) or FULLSCREEN_UNAVAILABLE (no Fullscreen API and embedded in
## another page, e.g. itch.io on an iPhone). Asked once, then cached.
func fullscreen_mode() -> int:
	if _fullscreen_mode < 0:
		_fullscreen_mode = FULLSCREEN_TOGGLE
		if OS.has_feature("web") and DisplayServer.get_name() != "headless":
			if _js_true(TouchData.STANDALONE_QUERY):
				_fullscreen_mode = FULLSCREEN_NONE
			elif not _js_true(TouchData.FULLSCREEN_QUERY):
				_fullscreen_mode = FULLSCREEN_UNAVAILABLE if _js_true(TouchData.EMBEDDED_QUERY) else FULLSCREEN_HOME_SCREEN
	return _fullscreen_mode


## Web build: evaluates the JavaScript boolean expression `expr` on the page (a JS
## boolean comes back as a bool or a number depending on the bridge: ask for 1 / 0).
func _js_true(expr: String) -> bool:
	var answer: Variant = JavaScriptBridge.eval("(%s) ? 1 : 0" % expr, true)
	return (typeof(answer) == TYPE_INT or typeof(answer) == TYPE_FLOAT or typeof(answer) == TYPE_BOOL) and int(answer) == 1


## Switches fullscreen on / off.
func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	changed.emit()


## Binds physical key `keycode` as the primary key of `action`. If another
## rebindable action has that primary key, it receives `action`'s old key.
func set_binding(action: String, keycode: int) -> void:
	if not key_bindings.has(action) or keycode <= 0:
		return
	var old: int = key_bindings[action]
	for other: String in REBINDABLE:
		if other != action and int(key_bindings[other]) == keycode:
			key_bindings[other] = old
			_apply_binding(other)
	key_bindings[action] = keycode
	_apply_binding(action)
	changed.emit()


## Restores every rebindable action's default primary key.
func reset_bindings() -> void:
	for action: String in REBINDABLE:
		key_bindings[action] = default_bindings[action]
		_apply_binding(action)
	changed.emit()


## Display name of `action`'s primary key (e.g. "W", "Escape").
func key_name(action: String) -> String:
	var kc := int(key_bindings.get(action, 0))
	return OS.get_keycode_string(kc as Key) if kc > 0 else "-"


# =====================================================================================
# Internals
# =====================================================================================

func _apply_volume(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v: float = volumes[bus]
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)


## Physical keycode of `action`'s first keyboard event in the InputMap.
func _primary_key(action: String) -> int:
	if not InputMap.has_action(action):
		return 0
	for ev in InputMap.action_get_events(action):
		var k := ev as InputEventKey
		if k != null:
			return int(k.physical_keycode) if k.physical_keycode != KEY_NONE else int(k.keycode)
	return 0


## Rewrites `action`'s events with the first keyboard event replaced by the
## bound physical key, keeping every other event and their order.
func _apply_binding(action: String) -> void:
	if not InputMap.has_action(action):
		return
	var kc: int = key_bindings[action]
	var events := InputMap.action_get_events(action)
	var replaced := false
	for i in events.size():
		if events[i] is InputEventKey:
			var k := InputEventKey.new()
			k.physical_keycode = kc as Key
			events[i] = k
			replaced = true
			break
	if not replaced:
		var k := InputEventKey.new()
		k.physical_keycode = kc as Key
		events.insert(0, k)
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)
