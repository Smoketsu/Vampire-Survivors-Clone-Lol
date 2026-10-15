## Sfx — audio autoload (GDD §12 Audio). It:
##   * creates the Music and SFX buses (both send to Master) at startup, plus
##     a hard limiter on Master so a burst of sounds never clips;
##   * synthesizes every sound in SoundData and the ambient in-run loop with
##     Synth on WorkerThreadPool threads, so startup is never blocked (the
##     main thread only queues the tasks). The no-threads Web build has no
##     worker threads (a task would run inside _ready and freeze the page), so
##     there StartupSynth renders the same samples in small per-frame steps
##     (SoundData.WEB_SYNTH_BUDGET_MS), the short UI sounds first, each sound
##     playable as soon as it exists (GDD §15.0 "Web build"). A sound
##     requested before it exists is silently skipped, and the in-run loop
##     fades in once it exists. Timings are printed once as "[audio]";
##   * plays two music tracks on the Music bus and crossfades between them
##     (play_music(), called by Main): the main menu theme (MenuThemeSynth,
##     "Grave Lullaby", MenuThemeData) on the menu and every screen opened
##     from it, the in-run loop during a run. The menu theme is rendered
##     lazily, the first time the menu asks for it (so the autotest, which
##     never shows the menu, never renders it): on a worker thread on
##     desktop, in small per-frame steps on the Web (WEB_FRAME_BUDGET_MS),
##     where worker threads may be missing. A track whose loop is not ready
##     yet starts (fading in) as soon as it is. Fades run on real time, so
##     the autotest's time scale and hit-stop never touch them;
##   * plays sounds through a fixed pool of MAX_VOICES AudioStreamPlayers
##     with per-sound limits from SoundData (max_voices, min_interval,
##     priority): GDD §12 "aggressive audio voice limits". A sound at its own
##     cap steals its oldest voice; when the global pool is full the oldest
##     voice of the lowest priority is stolen only if it is not more
##     important than the new sound, otherwise the new sound is dropped. So
##     150 enemies dying in one frame cost at most a handful of voices;
##   * gives every Button / Slider in the UI hover and confirm sounds by
##     watching SceneTree.node_added (no UI script needs to know about audio);
##     a Back / Cancel button (BACK_LABELS, or meta "ui_back" true) plays the
##     back sound instead of the confirm click, and Esc / pad B (ui_cancel)
##     pressed while the focus is inside a screen opened by UiMotion.open()
##     plays it too (watched on the root window's window_input, before any
##     screen handles the event; meta "ui_cancel_silent" on the screen turns
##     that off). play_ui() plays a sound that replaces the generic click of
##     the same press (purchase, denied, card_select).
## Positional sounds are not panned; they are attenuated with distance from
## the camera centre and culled beyond CULL_DISTANCE.
## Runs with PROCESS_MODE_ALWAYS so menus and the level-up panel (tree
## paused) still make sound. In headless runs (dummy audio driver, nothing
## can be heard) synthesis, voice limiting and bookkeeping all still run,
## but players are not started: a playback still alive when the autotest
## calls quit() would be reported as a leaked instance at exit.
## Voice occupancy is tracked from each sound's computed end time rather
## than AudioStreamPlayer.playing, so it behaves the same in both modes.
## Pitch variation uses its own RNG, never the seeded gameplay RNG.
extends Node

## Global cap on simultaneous sound-effect voices.
const MAX_VOICES: int = 24  # TUNING (not in GDD)
## Positional sounds farther than this from the camera centre (px) are culled.
const CULL_DISTANCE: float = 900.0  # TUNING (not in GDD)
## Attenuation (dB) at CULL_DISTANCE; it falls off linearly with distance.
const DISTANCE_ATTEN_DB: float = 12.0  # TUNING (not in GDD)
## Volume (dB) of the music player on the Music bus.
const MUSIC_DB: float = -8.0  # TUNING (not in GDD)
## Seconds the in-run music fades in (when a run starts, or once its loop
## has been generated).
const MUSIC_FADE_IN: float = 2.5  # TUNING (not in GDD)
## play_music() mode: the main menu theme.
const MUSIC_MENU: StringName = &"menu"
## play_music() mode: the in-run loop.
const MUSIC_RUN: StringName = &"run"
## Name of the music bus.
const BUS_MUSIC: StringName = &"Music"
## Name of the sound-effect bus.
const BUS_SFX: StringName = &"SFX"
## Seed base for the synth RNGs (sound i uses SYNTH_SEED + i).
const SYNTH_SEED: int = 9001
## A card_select within this many ms replaces the generic ui_confirm click.
const CONFIRM_SUPPRESS_MSEC: int = 120  # TUNING (not in GDD)
## Sounds that replace the generic ui_confirm click of the same press when
## played through play_ui() (the click is cut or skipped within CONFIRM_SUPPRESS_MSEC).
const CONFIRM_REPLACERS: Array = ["card_select", "purchase", "denied", "ui_back"]
## Button captions that mean "go back": they play ui_back instead of ui_confirm.
const BACK_LABELS: Array = ["Back", "Cancel", "Close"]

## True once every sound effect has been generated.
var bank_ready: bool = false
## Wall-clock ms from startup until the sound-effect bank was ready.
var sfx_ready_msec: float = 0.0
## Wall-clock ms from startup until the music loop was ready.
var music_ready_msec: float = 0.0
## Wall-clock ms from startup until the menu theme was ready (0 = not yet).
var menu_theme_ready_msec: float = 0.0
## Compute ms the menu theme's synthesis took (summed over its steps).
var menu_theme_compute_msec: float = 0.0
## Ms the main thread spent in _ready (bus setup + queuing synth tasks).
var startup_msec: float = 0.0
## Web build: compute ms the per-frame sound-effect synthesis took (0 on desktop).
var sfx_compute_msec: float = 0.0
## Web build: compute ms the per-frame synthesis of the sounds and the loop took (0 on desktop).
var startup_compute_msec: float = 0.0
## Total sound-effect plays accepted (debug / tests).
var plays_started: int = 0
## Plays dropped by a voice limit or cooldown (debug / tests).
var plays_dropped: int = 0

## Sound ids, most expensive first (index = synth task index).
var _ids: PackedStringArray = PackedStringArray()
## Streams written by the synth tasks, one slot per id (guarded by _mutex).
var _rendered: Array[AudioStreamWAV] = []
## id -> AudioStreamWAV: on desktop every id at once when the bank is ready,
## on the Web each id as soon as it is rendered.
var _streams: Dictionary = {}
## Web build: the per-frame renderer of the sounds and the in-run loop (null
## on desktop, and once both are done).
var _startup_synth: StartupSynth = null
## Guards _rendered and _music_stream while worker threads write them.
var _mutex: Mutex = Mutex.new()
## WorkerThreadPool group task id of the sound-effect synthesis (-1 = none).
var _sfx_task: int = -1
## WorkerThreadPool task id of the music synthesis (-1 = none).
var _music_task: int = -1
## Music loop produced by the worker (null until done).
var _music_stream: AudioStreamWAV = null
## usec timestamp when _ready started (for the timing report).
var _t0_usec: int = 0
## Voice pool (all on the SFX bus).
var _voices: Array[AudioStreamPlayer] = []
## Sound id playing on each voice ("" = never used).
var _voice_id: PackedStringArray = PackedStringArray()
## Start time (ms) of each voice's current sound.
var _voice_start: PackedInt64Array = PackedInt64Array()
## Time (ms) each voice's current sound ends (voice is free after it).
var _voice_end: PackedInt64Array = PackedInt64Array()
## True on the headless display server: players are never started.
var _silent: bool = false
## Priority of each voice's current sound.
var _voice_prio: PackedInt32Array = PackedInt32Array()
## id -> last accepted play time (ms), for min_interval.
var _last_play: Dictionary = {}
## Looping in-run music player on the Music bus.
var _music: AudioStreamPlayer
## Looping main-menu theme player on the Music bus.
var _menu_music: AudioStreamPlayer
## Current music mode: MUSIC_MENU, MUSIC_RUN or &"" (none asked yet).
var _music_mode: StringName = &""
## Linear fade gain (0..1) of the in-run player (applied on top of MUSIC_DB).
var _run_gain: float = 0.0
## Gain the in-run player is fading toward (0 or 1).
var _run_target: float = 0.0
## Gain change per real second of the in-run player's current fade.
var _run_rate: float = 1.0
## Linear fade gain (0..1) of the menu-theme player (on top of its MUSIC_DB).
var _menu_gain: float = 0.0
## Gain the menu-theme player is fading toward (0 or 1).
var _menu_target: float = 0.0
## Gain change per real second of the menu-theme player's current fade.
var _menu_rate: float = 1.0
## The menu theme's renderer while it works (null before it is asked for
## and once its stream is on the player).
var _menu_synth: MenuThemeSynth = null
## WorkerThreadPool task id of the menu theme's synthesis (-1 = none; the
## Web build steps it on the main thread instead).
var _menu_task: int = -1
## True when the menu theme renders in per-frame steps (Web).
var _menu_incremental: bool = false
## usec timestamp of the previous _process (real time, for the music fades).
var _last_usec: int = 0
## Camera centre this frame (Vector2.INF when there is no 2D camera).
var _listener: Vector2 = Vector2.INF
## Cosmetic RNG for pitch variation (never the global, seeded RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_t0_usec = Time.get_ticks_usec()
	_silent = DisplayServer.get_name() == "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_setup_buses()
	for i in MAX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_voices.append(p)
		_voice_id.append("")
		_voice_start.append(0)
		_voice_end.append(0)
		_voice_prio.append(0)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_menu_music = AudioStreamPlayer.new()
	_menu_music.bus = BUS_MUSIC
	_menu_music.volume_db = MenuThemeData.MUSIC_DB
	add_child(_menu_music)
	_last_usec = Time.get_ticks_usec()
	# Longest renders first, so the slowest sounds never start last and
	# stretch the total synthesis time.
	var order: Array = SoundData.SOUNDS.keys()
	order.sort_custom(func(a: String, b: String) -> bool: return _cost(a) > _cost(b))
	for id: String in order:
		_ids.append(id)
	_rendered.resize(_ids.size())
	if OS.has_feature("web"):
		# Same sounds, same seeds (SYNTH_SEED + index in _ids), rendered over
		# frames, cheapest (the UI clicks) first.
		var web_ids := PackedStringArray()  # Render order.
		var seeds := PackedInt32Array()  # Seed of each, by render order.
		for i in range(_ids.size() - 1, -1, -1):
			web_ids.append(_ids[i])
			seeds.append(SYNTH_SEED + i)
		_startup_synth = StartupSynth.new(web_ids, seeds, SYNTH_SEED - 1)
	else:
		_music_task = WorkerThreadPool.add_task(_synth_music, true, "Necropathy music synth")
		_sfx_task = WorkerThreadPool.add_group_task(_synth_one, _ids.size(), -1, true, "Necropathy sfx synth")
	get_tree().node_added.connect(_on_node_added)
	get_tree().root.window_input.connect(_on_window_input)
	startup_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0


func _exit_tree() -> void:
	# Never leave worker tasks running at shutdown.
	if _sfx_task >= 0:
		WorkerThreadPool.wait_for_group_task_completion(_sfx_task)
		_sfx_task = -1
	if _music_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
	if _menu_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_menu_task)
		_menu_task = -1
	_menu_synth = null
	# Release playbacks so the audio server holds no stream at exit.
	_music.stop()
	_music.stream = null
	_menu_music.stop()
	_menu_music.stream = null
	for p in _voices:
		p.stop()
		p.stream = null


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	_listener = cam.get_screen_center_position() if cam != null else Vector2.INF
	if _sfx_task >= 0 and WorkerThreadPool.is_group_task_completed(_sfx_task):
		WorkerThreadPool.wait_for_group_task_completion(_sfx_task)
		_sfx_task = -1
		_mutex.lock()
		for i in _ids.size():
			_streams[_ids[i]] = _rendered[i]
		_mutex.unlock()
		bank_ready = true
		sfx_ready_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0
		_report_if_done()
	if _music_task >= 0 and WorkerThreadPool.is_task_completed(_music_task):
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
		_mutex.lock()
		_music.stream = _music_stream
		_mutex.unlock()
		music_ready_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0
		_report_if_done()
	if _startup_synth != null:
		_step_startup_synth()
	_update_menu_theme()
	# Music fades run on real time (delta follows Engine.time_scale).
	var now := Time.get_ticks_usec()
	var real_dt := minf(0.1, float(now - _last_usec) / 1000000.0)
	_last_usec = now
	_run_gain = _fade_player(_music, MUSIC_DB, _run_gain, _run_target, _run_rate, real_dt)
	_menu_gain = _fade_player(_menu_music, MenuThemeData.MUSIC_DB, _menu_gain, _menu_target, _menu_rate, real_dt)


## Web build: runs one frame's budget of the sound / loop synthesis and
## takes what it finished: each new sound becomes playable at once, the bank
## is ready with the last one, and the loop goes on its player (fading in if
## a run is on).
func _step_startup_synth() -> void:
	var all_done := _startup_synth.step(int(SoundData.WEB_SYNTH_BUDGET_MS * 1000.0))
	for id: String in _startup_synth.finished.keys():
		_streams[id] = _startup_synth.finished[id]
	_startup_synth.finished.clear()
	if _startup_synth.sounds_done and not bank_ready:
		bank_ready = true
		sfx_ready_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0
		sfx_compute_msec = float(_startup_synth.sounds_usec) / 1000.0
	if all_done:
		_music.stream = _startup_synth.music_stream
		music_ready_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0
		startup_compute_msec = float(_startup_synth.compute_usec) / 1000.0
		_startup_synth = null
		_report_if_done()


## Switches the music to `mode`: MUSIC_MENU (the main menu theme, rendered
## on first use) or MUSIC_RUN (the in-run loop). The other track fades out
## and stops; the asked one starts from its beginning (unless it was still
## fading out, then it just fades back in). Called by Main when the menu is
## shown and when a run starts; asking for the current mode does nothing.
func play_music(mode: StringName) -> void:
	if mode == _music_mode:
		return
	_music_mode = mode
	if mode == MUSIC_MENU:
		_start_menu_theme()
		_menu_target = 1.0
		_menu_rate = 1.0 / MenuThemeData.FADE_IN
		_run_target = 0.0
		_run_rate = 1.0 / MenuThemeData.RUN_FADE_OUT
	else:
		_run_target = 1.0
		_run_rate = 1.0 / MUSIC_FADE_IN
		_menu_target = 0.0
		_menu_rate = 1.0 / MenuThemeData.FADE_OUT


## Moves one music player's fade gain toward `target` over `dt` real
## seconds, starts it (from the top) when it should be heard and its loop
## exists, stops it once faded out, and sets its volume. Returns the gain.
func _fade_player(p: AudioStreamPlayer, base_db: float, gain: float, target: float, rate: float, dt: float) -> float:
	if p.stream == null:
		return 0.0
	gain = move_toward(gain, target, rate * dt)
	if gain <= 0.0:
		if p.playing:
			p.stop()
		return 0.0
	p.volume_db = base_db + linear_to_db(gain)
	if not p.playing and not _silent:
		p.play()
	return gain


## Creates the menu theme's renderer (first call only): a worker task on
## desktop, per-frame steps on the Web.
func _start_menu_theme() -> void:
	if _menu_synth != null or _menu_music.stream != null:
		return
	_menu_synth = MenuThemeSynth.new()
	_menu_incremental = OS.has_feature("web")
	if not _menu_incremental:
		_menu_task = WorkerThreadPool.add_task(_menu_synth.render_all, true, "Necropathy menu theme synth")


## Advances the menu theme's synthesis (Web: one frame's budget, only while
## the menu is shown) and hands the finished loop to its player.
func _update_menu_theme() -> void:
	if _menu_synth == null:
		return
	if _menu_incremental:
		if _music_mode != MUSIC_MENU:
			return  # Never spend a run's frames on the menu theme.
		if not _menu_synth.step(int(MenuThemeData.WEB_FRAME_BUDGET_MS * 1000.0)):
			return
	else:
		if not WorkerThreadPool.is_task_completed(_menu_task):
			return
		WorkerThreadPool.wait_for_task_completion(_menu_task)
		_menu_task = -1
	_menu_music.stream = _menu_synth.stream
	menu_theme_compute_msec = float(_menu_synth.compute_usec) / 1000.0
	menu_theme_ready_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0
	print("[audio] menu theme: %.1f s loop, %.0f ms compute (%s), ready %.0f ms after startup" % [
		_menu_synth.loop_seconds(), menu_theme_compute_msec,
		"per-frame steps" if _menu_incremental else "worker thread", menu_theme_ready_msec])
	_menu_synth = null


## Prints the synthesis timings once both the bank and the music exist.
func _report_if_done() -> void:
	if bank_ready and _music_task < 0 and _music.stream != null:
		var how := "worker threads"  # Where the synthesis ran.
		if startup_compute_msec > 0.0:
			how = "per-frame steps: %.0f ms compute, %.0f ms of it sfx" % [startup_compute_msec, sfx_compute_msec]
		print("[audio] main-thread startup %.1f ms; %d sfx ready after %.0f ms, music loop after %.0f ms (%s); display: %s" % [
			startup_msec, _ids.size(), sfx_ready_msec, music_ready_msec, how, DisplayServer.get_name()])


## Rough render cost of sound `id` (duration x layer count).
static func _cost(id: String) -> float:
	var r: Dictionary = SoundData.SOUNDS[id]
	return float(r["dur"]) * float((r["layers"] as Array).size())


## Worker thread: renders sound `i`.
func _synth_one(i: int) -> void:
	var stream := Synth.render_sound(SoundData.SOUNDS[_ids[i]], SYNTH_SEED + i)
	_mutex.lock()
	_rendered[i] = stream
	_mutex.unlock()


## Worker thread: renders the music loop.
func _synth_music() -> void:
	var stream := Synth.render_music(SYNTH_SEED - 1)
	_mutex.lock()
	_music_stream = stream
	_mutex.unlock()


## Adds the Music and SFX buses (if missing) and a limiter on Master.
func _setup_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, AudioEffectHardLimiter.new())


# =====================================================================================
# Playback
# =====================================================================================

## Plays sound `id`. `pos` is a world position for distance attenuation /
## culling (Vector2.INF = non-positional). `pitch` multiplies the random
## per-play pitch variation. Cheap when rejected (cooldown is checked first),
## so gameplay may call it for every hit.
func play(id: String, pos: Vector2 = Vector2.INF, pitch: float = 1.0) -> void:
	if not _streams.has(id):
		return  # Not rendered yet (or not a sound).
	var def: Dictionary = SoundData.SOUNDS[id]
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(id, -100000)) < int(def["min_interval"]):
		plays_dropped += 1
		return
	var vol: float = def["volume_db"]
	if pos != Vector2.INF and _listener != Vector2.INF:
		var d := pos.distance_to(_listener)
		if d > CULL_DISTANCE:
			plays_dropped += 1
			return
		vol -= DISTANCE_ATTEN_DB * d / CULL_DISTANCE
	var prio: int = def["priority"]
	var v := _pick_voice(id, int(def["max_voices"]), prio)
	if v < 0:
		plays_dropped += 1
		return
	_last_play[id] = now
	var p := _voices[v]
	p.stream = _streams[id]
	p.volume_db = vol
	var pv: float = def["pitch_var"]
	p.pitch_scale = maxf(0.05, pitch * (1.0 + (_rng.randf_range(-pv, pv) if pv > 0.0 else 0.0)))
	if not _silent:
		p.play()
	_voice_id[v] = id
	_voice_start[v] = now
	_voice_end[v] = now + int(p.stream.get_length() / p.pitch_scale * 1000.0) + 1
	_voice_prio[v] = prio
	plays_started += 1


## Returns the voice index to use for `id`, or -1 to drop the sound.
func _pick_voice(id: String, max_same: int, prio: int) -> int:
	var same := 0
	var oldest_same := -1
	var free := -1
	var victim := -1
	var now := Time.get_ticks_msec()
	for i in MAX_VOICES:
		if now >= _voice_end[i]:
			if free < 0:
				free = i
			continue
		if _voice_id[i] == id:
			same += 1
			if oldest_same < 0 or _voice_start[i] < _voice_start[oldest_same]:
				oldest_same = i
		if victim < 0 or _voice_prio[i] < _voice_prio[victim] \
				or (_voice_prio[i] == _voice_prio[victim] and _voice_start[i] < _voice_start[victim]):
			victim = i
	if same >= max_same:
		return oldest_same
	if free >= 0:
		return free
	if victim >= 0 and _voice_prio[victim] <= prio:
		return victim
	return -1


## Number of sound-effect voices currently playing (debug / tests).
func active_voices() -> int:
	var n := 0
	var now := Time.get_ticks_msec()
	for i in MAX_VOICES:
		if now < _voice_end[i]:
			n += 1
	return n


# =====================================================================================
# Automatic UI sounds
# =====================================================================================

## Hooks hover / confirm sounds onto every button and slider that enters
## the tree.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b := node as BaseButton
		b.mouse_entered.connect(_on_ui_hover)
		b.focus_entered.connect(_on_ui_hover)
		b.pressed.connect(_on_ui_confirm.bind(b))
	elif node is Range:
		var r := node as Range
		if r.focus_mode != Control.FOCUS_NONE:
			r.focus_entered.connect(_on_ui_hover)
			r.value_changed.connect(_on_slider_changed)


func _on_ui_hover() -> void:
	play("ui_hover")


## A button was pressed: the back sound for Back / Cancel buttons, else the
## confirm click (skipped when a replacing sound, e.g. card_select or a
## purchase, was just played for the same press).
func _on_ui_confirm(b: BaseButton) -> void:
	if is_instance_valid(b) and (bool(b.get_meta(&"ui_back", false)) or (b is Button and BACK_LABELS.has((b as Button).text))):
		play_ui("ui_back")
		return
	var now := Time.get_ticks_msec()
	for id: String in CONFIRM_REPLACERS:
		if now - int(_last_play.get(id, -100000)) < CONFIRM_SUPPRESS_MSEC:
			return
	play("ui_confirm")


func _on_slider_changed(_value: float) -> void:
	play("ui_hover", Vector2.INF, 1.3)


## Root window input, seen before any node handles it: Esc / pad B
## (ui_cancel) pressed while the keyboard / pad focus is inside a UI screen
## (UiMotion.open() marked it with meta "ui_screen", and it does not carry
## "ui_cancel_silent") plays the back sound. Nothing plays in play (no
## focus), during a fade through black, or for key repeats.
func _on_window_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel", false) or get_tree().root.is_input_disabled():
		return
	var f := get_viewport().gui_get_focus_owner()  # Focused control (null in play).
	if f == null or not f.is_visible_in_tree():
		return
	var n: Node = f  # Walks up to the nearest screen root.
	while n != null:
		if n.has_meta(&"ui_screen"):
			if not bool(n.get_meta(&"ui_cancel_silent", false)):
				play_ui("ui_back")
			return
		n = n.get_parent()


## Plays the level-up card pick sound, cutting a generic confirm click that
## the same button press may have started just before.
func play_card_select() -> void:
	play_ui("card_select")


## Plays UI sound `id` (purchase, denied, card_select, ui_back...) in place
## of the generic confirm click of the same press: a ui_confirm started
## within CONFIRM_SUPPRESS_MSEC is cut, and one requested just after is
## skipped (CONFIRM_REPLACERS).
func play_ui(id: String) -> void:
	var now := Time.get_ticks_msec()
	for i in MAX_VOICES:
		if _voice_id[i] == "ui_confirm" and now < _voice_end[i] and now - _voice_start[i] < CONFIRM_SUPPRESS_MSEC:
			_voices[i].stop()
			_voice_end[i] = 0
	play(id)
