## Sfx — audio autoload (GDD §12 Audio). It:
##   * creates the Music and SFX buses (both send to Master) at startup, plus
##     a hard limiter on Master so a burst of sounds never clips;
##   * synthesizes every sound in SoundData and the ambient music loop with
##     Synth on WorkerThreadPool threads, so startup is never blocked (the
##     main thread only queues the tasks). Sounds requested before the bank
##     is ready are silently skipped. Timings are printed once as "[audio]";
##   * plays sounds through a fixed pool of MAX_VOICES AudioStreamPlayers
##     with per-sound limits from SoundData (max_voices, min_interval,
##     priority): GDD §12 "aggressive audio voice limits". A sound at its own
##     cap steals its oldest voice; when the global pool is full the oldest
##     voice of the lowest priority is stolen only if it is not more
##     important than the new sound, otherwise the new sound is dropped. So
##     150 enemies dying in one frame cost at most a handful of voices;
##   * gives every Button / Slider in the UI hover and confirm sounds by
##     watching SceneTree.node_added (no UI script needs to know about audio).
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
## Seconds the music fades in once its loop has been generated.
const MUSIC_FADE_IN: float = 2.5  # TUNING (not in GDD)
## Name of the music bus.
const BUS_MUSIC: StringName = &"Music"
## Name of the sound-effect bus.
const BUS_SFX: StringName = &"SFX"
## Seed base for the synth RNGs (sound i uses SYNTH_SEED + i).
const SYNTH_SEED: int = 9001
## A card_select within this many ms replaces the generic ui_confirm click.
const CONFIRM_SUPPRESS_MSEC: int = 120  # TUNING (not in GDD)

## True once every sound effect has been generated.
var bank_ready: bool = false
## Wall-clock ms from startup until the sound-effect bank was ready.
var sfx_ready_msec: float = 0.0
## Wall-clock ms from startup until the music loop was ready.
var music_ready_msec: float = 0.0
## Ms the main thread spent in _ready (bus setup + queuing synth tasks).
var startup_msec: float = 0.0
## Total sound-effect plays accepted (debug / tests).
var plays_started: int = 0
## Plays dropped by a voice limit or cooldown (debug / tests).
var plays_dropped: int = 0

## Sound ids, most expensive first (index = synth task index).
var _ids: PackedStringArray = PackedStringArray()
## Streams written by the synth tasks, one slot per id (guarded by _mutex).
var _rendered: Array[AudioStreamWAV] = []
## id -> AudioStreamWAV once the bank is ready.
var _streams: Dictionary = {}
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
## Looping music player on the Music bus.
var _music: AudioStreamPlayer
## Seconds of music fade-in remaining.
var _music_fade: float = 0.0
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
	# Longest renders first, so the slowest sounds never start last and
	# stretch the total synthesis time.
	var order: Array = SoundData.SOUNDS.keys()
	order.sort_custom(func(a: String, b: String) -> bool: return _cost(a) > _cost(b))
	for id: String in order:
		_ids.append(id)
	_rendered.resize(_ids.size())
	_music_task = WorkerThreadPool.add_task(_synth_music, true, "Gravebound music synth")
	_sfx_task = WorkerThreadPool.add_group_task(_synth_one, _ids.size(), -1, true, "Gravebound sfx synth")
	get_tree().node_added.connect(_on_node_added)
	startup_msec = float(Time.get_ticks_usec() - _t0_usec) / 1000.0


func _exit_tree() -> void:
	# Never leave worker tasks running at shutdown.
	if _sfx_task >= 0:
		WorkerThreadPool.wait_for_group_task_completion(_sfx_task)
		_sfx_task = -1
	if _music_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
	# Release playbacks so the audio server holds no stream at exit.
	_music.stop()
	_music.stream = null
	for p in _voices:
		p.stop()
		p.stream = null


func _process(delta: float) -> void:
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
		_music.volume_db = -60.0
		_music_fade = MUSIC_FADE_IN
		if not _silent:
			_music.play()
		_report_if_done()
	if _music_fade > 0.0:
		_music_fade = maxf(0.0, _music_fade - delta)
		_music.volume_db = lerpf(MUSIC_DB, -60.0, _music_fade / MUSIC_FADE_IN)


## Prints the synthesis timings once both the bank and the music exist.
func _report_if_done() -> void:
	if bank_ready and _music_task < 0 and _music.stream != null:
		print("[audio] main-thread startup %.1f ms; %d sfx ready after %.0f ms, music loop after %.0f ms (worker threads); display: %s" % [
			startup_msec, _ids.size(), sfx_ready_msec, music_ready_msec, DisplayServer.get_name()])


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
	if not bank_ready:
		return
	var def: Dictionary = SoundData.SOUNDS.get(id, {})
	if def.is_empty():
		return
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
		b.pressed.connect(_on_ui_confirm)
	elif node is Range:
		var r := node as Range
		if r.focus_mode != Control.FOCUS_NONE:
			r.focus_entered.connect(_on_ui_hover)
			r.value_changed.connect(_on_slider_changed)


func _on_ui_hover() -> void:
	play("ui_hover")


func _on_ui_confirm() -> void:
	# The level-up card's own card_select sound replaces the generic click.
	if Time.get_ticks_msec() - int(_last_play.get("card_select", -100000)) < CONFIRM_SUPPRESS_MSEC:
		return
	play("ui_confirm")


func _on_slider_changed(_value: float) -> void:
	play("ui_hover", Vector2.INF, 1.3)


## Plays the level-up card pick sound, cutting a generic confirm click that
## the same button press may have started just before.
func play_card_select() -> void:
	var now := Time.get_ticks_msec()
	for i in MAX_VOICES:
		if _voice_id[i] == "ui_confirm" and now < _voice_end[i] and now - _voice_start[i] < CONFIRM_SUPPRESS_MSEC:
			_voices[i].stop()
			_voice_end[i] = 0
	play("card_select")
