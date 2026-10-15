## StartupSynth — the Web build's renderer for what Sfx synthesizes at
## startup: every SoundData sound effect and the in-run loop (GDD §15.0 "Web
## build"). The no-threads Web build has no worker threads (a
## WorkerThreadPool task would run inside Sfx._ready() and freeze the page),
## so Sfx calls step() once per frame with a small time budget
## (SoundData.WEB_SYNTH_BUDGET_MS) instead.
##
## The work is a fixed list of small jobs: for each sound, its buffer, one
## job per layer (Synth.add_layer() with the sound's own seeded RNG, layers in
## recipe order) and its encoding (Synth.to_stream()); then the in-run loop's
## own jobs (RunLoopSynth). The jobs are exactly the steps Synth.render_sound()
## and Synth.render_music() run in one go, in the same order with the same
## seeds, so every sample is identical to the desktop build's however the
## frames split the work. Sounds are rendered in the order given (Sfx passes
## the cheapest first, so the short UI sounds exist within the first frames)
## and each finished one is handed over at once through `finished`, so a
## sound plays as soon as it exists. Only its own buffers and RNGs are
## touched (never the gameplay RNG).
class_name StartupSynth
extends RefCounted

## Sounds finished since Sfx last collected them: id -> AudioStreamWAV (Sfx
## moves them into its bank and clears this).
var finished: Dictionary = {}
## The in-run loop once rendered (null until then).
var music_stream: AudioStreamWAV = null
## True once every sound effect has been rendered (the loop may still be
## rendering).
var sounds_done: bool = false
## Microseconds of compute spent so far (sum over every step() call).
var compute_usec: int = 0
## Microseconds of compute the sound effects took (set when sounds_done).
var sounds_usec: int = 0

## Fixed job list of the sound effects (Callables), run in order.
var _jobs: Array[Callable] = []
## Index of the next sound job (== _jobs.size() once the sounds are done).
var _next: int = 0
## Mix buffer of the sound being rendered.
var _buf: PackedFloat32Array = PackedFloat32Array()
## Seeded RNG of the sound being rendered (one per sound, as on desktop).
var _rng: RandomNumberGenerator = null
## The in-run loop's renderer (its jobs run after the sounds').
var _music: RunLoopSynth = null
## Seed of the in-run loop's RNG.
var _music_seed: int = 0


## Schedules sounds `ids` (rendered in this order) with RNG seeds `seeds`
## (same index), then the in-run loop with seed `music_seed`. Cheap: no
## audio is rendered here.
func _init(ids: PackedStringArray, seeds: PackedInt32Array, music_seed: int) -> void:
	for k in ids.size():
		var recipe: Dictionary = SoundData.SOUNDS[ids[k]]
		_jobs.append(_job_begin.bind(recipe, seeds[k]))
		for layer: Dictionary in recipe["layers"]:
			_jobs.append(_job_layer.bind(layer))
		_jobs.append(_job_end.bind(ids[k]))
	_music_seed = music_seed


## True once the sounds and the loop all exist.
func done() -> bool:
	return music_stream != null


## Runs jobs until `budget_usec` microseconds have passed (at least one job;
## a budget < 0 runs everything). Returns done().
func step(budget_usec: int) -> bool:
	var t0 := Time.get_ticks_usec()
	var ran := false  # True once this step ran a sound job.
	while _next < _jobs.size():
		_jobs[_next].call()
		_next += 1
		ran = true
		if budget_usec >= 0 and Time.get_ticks_usec() - t0 >= budget_usec:
			break
	if _next >= _jobs.size() and not sounds_done:
		sounds_done = true
		_jobs.clear()
		_next = 0
		sounds_usec = compute_usec + Time.get_ticks_usec() - t0
	var used := Time.get_ticks_usec() - t0  # Budget already spent on sounds.
	# The loop's jobs get what the sounds left of the budget (and at least
	# one job when no sound job ran).
	if sounds_done and music_stream == null and (budget_usec < 0 or not ran or used < budget_usec):
		if _music == null:
			_music = RunLoopSynth.new(_music_seed)
		if _music.step(maxi(0, budget_usec - used) if budget_usec >= 0 else -1):
			music_stream = _music.stream
			_music = null
	compute_usec += Time.get_ticks_usec() - t0
	return done()


## Starts a sound: its silent buffer and its seeded RNG (Synth.render_sound()).
func _job_begin(recipe: Dictionary, rng_seed: int) -> void:
	_buf = Synth.sound_buffer(recipe)
	_rng = RandomNumberGenerator.new()
	_rng.seed = rng_seed


## Mixes one layer of the current sound.
func _job_layer(layer: Dictionary) -> void:
	Synth.add_layer(_buf, Synth.SFX_RATE, layer, _rng)


## Encodes the current sound and hands it over as `id`.
func _job_end(id: String) -> void:
	finished[id] = Synth.to_stream(_buf, Synth.SFX_RATE, false)
	_buf = PackedFloat32Array()
	_rng = null
