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
##   * plays music tracks on the Music bus and crossfades between them
##     (play_music(), called by Main): the main menu theme (MenuThemeSynth,
##     "Grave Lullaby", MenuThemeData) on the menu and every screen opened
##     from it, the in-run loop during a run, and on an Act II stage the
##     second run loop "Below the Tide" (RunLoopSynth with
##     SoundData.TIDE_SCORE; rendered lazily the first time an Act II run
##     asks for it, like the menu theme, and never headless), on an Act III
##     stage "Iron Requiem" (SoundData.IRON_SCORE, the same way: every
##     SoundData.SCORES entry is a ScoreLoop with its own player and fixed
##     seed, SCORE_SEEDS), and while the
##     epilogue plays its slow "Grave Lullaby" cue (MUSIC_EPILOGUE:
##     MenuThemeSynth with MenuThemeData.EPILOGUE_VARIANT, rendered the first
##     time an epilogue asks for it, never headless). The menu theme is rendered
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
##   * renders a lazily loaded sound PACK (Act III: SoundData.EMPIRE_SOUNDS,
##     SoundData.SCORE_PACKS) the first time its score is asked for, on a
##     worker thread on desktop and one sound per frame on the Web, with its own
##     seeds (PACK_SEED + the pack's PACK_SEED_OFFSETS + i; Act IV: "Hymn of
##     Bronze" asks for SoundData.PANTHEON_SOUNDS), so the startup bank, its order and its seeds stay
##     exactly as they were; play() finds a pack sound once it exists;
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
## play_music() mode: the Act II in-run loop "Below the Tide" (SoundData.TIDE_SCORE;
## a stage whose STAGE has "music": "tide").
const MUSIC_TIDE: StringName = &"tide"
## play_music() mode: the Act III in-run loop "Iron Requiem" (SoundData.IRON_SCORE;
## a stage whose STAGE has "music": "iron").
const MUSIC_IRON: StringName = &"iron"
## play_music() mode: the Act IV in-run loop "Hymn of Bronze" (SoundData.BRONZE_SCORE;
## a stage whose STAGE has "music": "bronze").
const MUSIC_BRONZE: StringName = &"bronze"
## play_music() mode: the epilogue's slow "Grave Lullaby" cue (content wave 2;
## MenuThemeData.EPILOGUE_VARIANT, rendered the first time the epilogue plays).
const MUSIC_EPILOGUE: StringName = &"epilogue"
## Name of the music bus.
const BUS_MUSIC: StringName = &"Music"
## Name of the sound-effect bus.
const BUS_SFX: StringName = &"SFX"
## Seed base for the synth RNGs (sound i uses SYNTH_SEED + i).
const SYNTH_SEED: int = 9001
## Fixed synth seed of each score loop (SoundData.SCORES id -> seed); the tide
## keeps the SYNTH_SEED - 2 it always had.
const SCORE_SEEDS := {"tide": SYNTH_SEED - 2, "iron": SYNTH_SEED - 3, "bronze": SYNTH_SEED - 4}
## Seed base of the lazily rendered sound packs (pack sound i uses PACK_SEED + i).
const PACK_SEED: int = SYNTH_SEED + 5000
## Seed offset of each lazily rendered pack (pack sound i of pack P uses
## PACK_SEED + PACK_SEED_OFFSETS[P] + i), so a pack's sounds never depend on
## which pack was asked for first. The Act III pack keeps offset 0 (its
## seeds are what they always were).
const PACK_SEED_OFFSETS := {"empire": 0, "pantheon": 1000}
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
## Score loops (the Act II and Act III run loops): SoundData.SCORES id ->
## ScoreLoop, one per score, built in _ready().
var _scores: Dictionary = {}
## Lazily rendered pack sounds: id -> recipe (SoundData.EMPIRE_SOUNDS rows),
## filled when a pack is asked for; play() looks a missing SOUNDS id up here.
var _pack_defs: Dictionary = {}
## Packs asked for so far (SoundData.SCORE_PACKS values -> true).
var _packs: Dictionary = {}
## Pack sound ids still to render (oldest first) and their seeds.
var _pack_queue: Array[String] = []
## Seed of each _pack_queue entry.
var _pack_seeds: Array[int] = []
## Desktop: pack renders finished by the worker (id -> stream; guarded by _mutex).
var _pack_done: Dictionary = {}
## Desktop: WorkerThreadPool task id of the pack render (-1 = none).
var _pack_task: int = -1


## One lazily rendered run loop (a SoundData.SCORES entry) and its player.
class ScoreLoop:
	extends RefCounted
	## Looping player on the Music bus.
	var player: AudioStreamPlayer
	## Linear fade gain (0..1, on top of MUSIC_DB).
	var gain: float = 0.0
	## Gain it is fading toward (0 or 1).
	var target: float = 0.0
	## Gain change per real second of its current fade.
	var rate: float = 1.0
	## The renderer while it works (null before the first run asks for it and
	## once its stream is on the player).
	var synth: RunLoopSynth = null
	## WorkerThreadPool task id of its synthesis (-1 = none; Web: per-frame steps).
	var task: int = -1
	## True when it renders in per-frame steps (Web).
	var incremental: bool = false
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
# --- Content wave 2: E. Illustrated epilogue ---
## Looping epilogue-cue player on the Music bus (MUSIC_EPILOGUE).
var _epi_music: AudioStreamPlayer
## Linear fade gain (0..1) of the epilogue cue (on top of MenuThemeData.EPILOGUE_MUSIC_DB).
var _epi_gain: float = 0.0
## Gain the epilogue cue is fading toward (0 or 1).
var _epi_target: float = 0.0
## Gain change per real second of the epilogue cue's current fade.
var _epi_rate: float = 1.0
## The epilogue cue's renderer while it works (null before the first epilogue
## asks for it and once its stream is on the player).
var _epi_synth: MenuThemeSynth = null
## WorkerThreadPool task id of the cue's synthesis (-1 = none; the Web build
## steps it on the main thread instead, only while the epilogue plays).
var _epi_task: int = -1
## True when the epilogue cue renders in per-frame steps (Web).
var _epi_incremental: bool = false
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
	for sid: String in SoundData.SCORES:
		var sl := ScoreLoop.new()  # Act II / III run loop (rendered on first use).
		sl.player = AudioStreamPlayer.new()
		sl.player.bus = BUS_MUSIC
		sl.player.volume_db = MUSIC_DB
		add_child(sl.player)
		_scores[sid] = sl
	_epi_music = AudioStreamPlayer.new()  # Content wave 2: the epilogue cue (no new bus: GDD §15.0 "Web sound fix").
	_epi_music.bus = BUS_MUSIC
	_epi_music.volume_db = MenuThemeData.EPILOGUE_MUSIC_DB
	add_child(_epi_music)
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
	for sid: String in _scores:
		var sl: ScoreLoop = _scores[sid]
		if sl.task >= 0:
			WorkerThreadPool.wait_for_task_completion(sl.task)
			sl.task = -1
		sl.synth = null
		sl.player.stop()
		sl.player.stream = null
	if _pack_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_pack_task)
		_pack_task = -1
	if _epi_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_epi_task)
		_epi_task = -1
	_epi_synth = null
	_epi_music.stop()
	_epi_music.stream = null
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
	_update_scores()
	_update_packs()
	_update_epilogue_cue()
	# Music fades run on real time (delta follows Engine.time_scale).
	var now := Time.get_ticks_usec()
	var real_dt := minf(0.1, float(now - _last_usec) / 1000000.0)
	_last_usec = now
	_run_gain = _fade_player(_music, MUSIC_DB, _run_gain, _run_target, _run_rate, real_dt)
	_menu_gain = _fade_player(_menu_music, MenuThemeData.MUSIC_DB, _menu_gain, _menu_target, _menu_rate, real_dt)
	for sid: String in _scores:
		var sl: ScoreLoop = _scores[sid]
		sl.gain = _fade_player(sl.player, MUSIC_DB, sl.gain, sl.target, sl.rate, real_dt)
	_epi_gain = _fade_player(_epi_music, MenuThemeData.EPILOGUE_MUSIC_DB, _epi_gain, _epi_target, _epi_rate, real_dt)


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
## on first use), MUSIC_RUN (the in-run loop) or a score loop (MUSIC_TIDE,
## the Act II loop, or MUSIC_IRON, the Act III one: rendered on first use; it
## fades in once it exists; a score's sound pack is asked for with it). The other tracks fade
## out and stop; the asked one starts from its beginning (unless it was still
## fading out, then it just fades back in). Called by Main when the menu is
## shown and when a run starts (run_mode_for() picks the run's loop); asking
## for the current mode does nothing.
func play_music(mode: StringName) -> void:
	if mode == _music_mode:
		return
	_music_mode = mode
	# Content wave 2 (epilogue): every mode but MUSIC_EPILOGUE fades the cue out;
	# the epilogue fades the menu theme and both run loops out under it.
	_epi_target = 0.0
	_epi_rate = 1.0 / MenuThemeData.EPILOGUE_FADE_OUT
	if mode == MUSIC_EPILOGUE:
		_start_epilogue_cue()
		_epi_target = 1.0
		_epi_rate = 1.0 / MenuThemeData.EPILOGUE_FADE_IN
		_menu_target = 0.0
		_menu_rate = 1.0 / MenuThemeData.EPILOGUE_FADE_IN
		_run_target = 0.0
		for sid: String in _scores:
			(_scores[sid] as ScoreLoop).target = 0.0
		return
	if mode == MUSIC_MENU:
		_start_menu_theme()
		_menu_target = 1.0
		_menu_rate = 1.0 / MenuThemeData.FADE_IN
		_run_target = 0.0
		_run_rate = 1.0 / MenuThemeData.RUN_FADE_OUT
		for sid: String in _scores:
			var sl: ScoreLoop = _scores[sid]
			sl.target = 0.0
			sl.rate = 1.0 / MenuThemeData.RUN_FADE_OUT
	else:
		var score := String(mode) if _scores.has(String(mode)) else ""  # A score loop instead of Act I's ("" = none).
		if score != "":
			_start_score(score)
			prepare_pack(String(SoundData.SCORE_PACKS.get(score, "")))
		_run_target = 0.0 if score != "" else 1.0
		_run_rate = 1.0 / (MenuThemeData.RUN_FADE_OUT if score != "" else MUSIC_FADE_IN)
		for sid: String in _scores:
			var sl: ScoreLoop = _scores[sid]
			var on := sid == score  # This score is the run's loop.
			sl.target = 1.0 if on else 0.0
			sl.rate = 1.0 / (MUSIC_FADE_IN if on else MenuThemeData.RUN_FADE_OUT)
		_menu_target = 0.0
		_menu_rate = 1.0 / MenuThemeData.FADE_OUT


## The run-loop mode of stage `stage_id`: its STAGE "music" id when that is a
## SoundData.SCORES entry (MUSIC_TIDE on Act II, MUSIC_IRON on Act III, MUSIC_BRONZE on Act IV),
## MUSIC_RUN otherwise.
static func run_mode_for(stage_id: String) -> StringName:
	if StageRegistry.STAGES.has(stage_id):
		var music := String((StageRegistry.STAGES[stage_id] as Dictionary).get("music", ""))  # Its run loop id.
		if SoundData.SCORES.has(music):
			return StringName(music)
	return MUSIC_RUN


## Creates score loop `sid`'s renderer (first call only; never headless): a
## worker task on desktop, per-frame steps on the Web.
func _start_score(sid: String) -> void:
	var sl: ScoreLoop = _scores[sid]
	if _silent or sl.synth != null or sl.player.stream != null:
		return
	sl.synth = RunLoopSynth.new(int(SCORE_SEEDS[sid]), SoundData.SCORES[sid])
	sl.incremental = OS.has_feature("web")
	if not sl.incremental:
		sl.task = WorkerThreadPool.add_task(sl.synth.render_all, true, "Necropathy %s loop synth" % sid)


## Advances every score loop's synthesis (Web: one frame's budget, after the
## startup synthesis is done) and hands a finished loop to its player.
func _update_scores() -> void:
	for sid: String in _scores:
		var sl: ScoreLoop = _scores[sid]
		if sl.synth == null:
			continue
		if sl.incremental:
			if _startup_synth != null:
				continue  # The sounds and the Act I loop first.
			if not sl.synth.step(int(SoundData.WEB_SYNTH_BUDGET_MS * 1000.0)):
				continue
		else:
			if not WorkerThreadPool.is_task_completed(sl.task):
				continue
			WorkerThreadPool.wait_for_task_completion(sl.task)
			sl.task = -1
		sl.player.stream = sl.synth.stream
		print("[audio] %s loop: %.0f ms compute (%s)" % [sid, float(sl.synth.compute_usec) / 1000.0,
			"per-frame steps" if sl.incremental else "worker thread"])
		sl.synth = null


## Asks for sound pack `pack` (SoundData.SCORE_PACKS value; "" = none; first
## call only): its sounds render on a worker thread on desktop, one per frame on
## the Web (after the startup synthesis), with seeds PACK_SEED + i. Each becomes
## playable as soon as it exists (play() skips it until then).
func prepare_pack(pack: String) -> void:
	if pack == "" or _packs.has(pack):
		return
	_packs[pack] = true
	var defs: Dictionary = {}  # The pack's recipes.
	if pack == "empire":
		defs = SoundData.EMPIRE_SOUNDS
	elif pack == "pantheon":
		defs = SoundData.PANTHEON_SOUNDS
	var k := 0  # Index of the sound within its pack (its seed).
	for id: String in defs:
		_pack_defs[id] = defs[id]
		_pack_queue.append(id)
		_pack_seeds.append(PACK_SEED + int(PACK_SEED_OFFSETS.get(pack, 0)) + k)
		k += 1
	if not OS.has_feature("web") and not _pack_queue.is_empty() and _pack_task < 0:
		_pack_task = WorkerThreadPool.add_task(_render_pack, true, "Necropathy sound pack synth")


## Worker thread (desktop): renders every queued pack sound into _pack_done.
func _render_pack() -> void:
	_mutex.lock()
	var ids := _pack_queue.duplicate()  # What to render.
	var seeds := _pack_seeds.duplicate()  # Their seeds.
	_mutex.unlock()
	for k in ids.size():
		var stream := Synth.render_sound(_pack_defs[ids[k]], seeds[k])
		_mutex.lock()
		_pack_done[ids[k]] = stream
		_mutex.unlock()


## Takes the finished pack sounds (desktop: from the worker; Web: renders one
## queued sound this frame once the startup synthesis is done).
func _update_packs() -> void:
	if _pack_task >= 0:
		if not WorkerThreadPool.is_task_completed(_pack_task):
			return
		WorkerThreadPool.wait_for_task_completion(_pack_task)
		_pack_task = -1
		_mutex.lock()
		for id: String in _pack_done:
			_streams[id] = _pack_done[id]
		_pack_done.clear()
		_pack_queue.clear()
		_pack_seeds.clear()
		_mutex.unlock()
		return
	if _pack_queue.is_empty() or _startup_synth != null:
		return
	var id: String = _pack_queue.pop_front()  # Web: one sound per frame.
	var sd: int = _pack_seeds.pop_front()
	_streams[id] = Synth.render_sound(_pack_defs[id], sd)


## Creates the epilogue cue's renderer (first call only; never headless): a
## worker task on desktop, per-frame steps on the Web. Its stream is kept, so a
## replay starts at once.
func _start_epilogue_cue() -> void:
	if _silent or _epi_synth != null or _epi_music.stream != null:
		return
	_epi_synth = MenuThemeSynth.new(MenuThemeData.EPILOGUE_VARIANT)
	_epi_incremental = OS.has_feature("web")
	if not _epi_incremental:
		_epi_task = WorkerThreadPool.add_task(_epi_synth.render_all, true, "Necropathy epilogue cue synth")


## Advances the epilogue cue's synthesis (Web: one frame's budget, only while
## the epilogue plays and after the startup synthesis) and hands the finished
## loop to its player, which then fades in if the epilogue is still open.
func _update_epilogue_cue() -> void:
	if _epi_synth == null:
		return
	if _epi_incremental:
		if _music_mode != MUSIC_EPILOGUE or _startup_synth != null:
			return
		if not _epi_synth.step(int(MenuThemeData.WEB_FRAME_BUDGET_MS * 1000.0)):
			return
	else:
		if not WorkerThreadPool.is_task_completed(_epi_task):
			return
		WorkerThreadPool.wait_for_task_completion(_epi_task)
		_epi_task = -1
	_epi_music.stream = _epi_synth.stream
	print("[audio] epilogue cue: %.1f s loop, %.0f ms compute (%s)" % [_epi_synth.loop_seconds(),
		float(_epi_synth.compute_usec) / 1000.0, "per-frame steps" if _epi_incremental else "worker thread"])
	_epi_synth = null


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
## Buses are appended with set_bus_count(), never add_bus(): Godot 4.3's Web player
## mirrors add_bus() (always sent as "at -1", even with an explicit end position)
## through GodotAudio.Bus.addAt / move in index.js, which splices the new bus in
## BEFORE Master. Its bus order then no longer matches the engine's, the
## set_bus_send below wires Master into Music / SFX and nothing reaches the
## speakers (the Web build was silent in every browser; GDD §15.0 "Web sound fix").
## set_bus_count() is mirrored by Bus.setCount, which appends in order. On desktop
## both calls build the same buses.
func _setup_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count  # Index the new bus gets (the end of the list).
			AudioServer.set_bus_count(idx + 1)
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
	var def: Dictionary = SoundData.SOUNDS[id] if SoundData.SOUNDS.has(id) else _pack_defs[id]  # Bank or pack recipe.
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
