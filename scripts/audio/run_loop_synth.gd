## RunLoopSynth — renders the dark, minor-key ambient in-run loop (GDD §12
## "ominous choirs, low percussion and ambient drones"; numbers in SoundData)
## into one seamless looping 16-bit mono AudioStreamWAV at Synth.MUSIC_RATE:
## a beating D drone, a slow wind bed, a four-chord "choir" pad crossfading
## around the loop (SoundData.MUSIC_CHORDS) and a soft heartbeat thump. Every
## oscillator and LFO completes a whole number of cycles per loop, so the loop
## point is seamless.
##
## The recipe is a fixed list of small jobs (WEB_SYNTH_CHUNK_SAMPLES of the
## drone pass, of one chord's window, of the peak search or of the encoding;
## the heartbeat; the finish), run in order by step(). Every bit of state a
## pass carries from one sample to the next (oscillator phases, filter states,
## the RNG) lives in members, so the loop is the same however the jobs are
## spread: Synth.render_music() runs them all at once (on a worker thread on
## desktop), the Web build's StartupSynth a few per frame (GDD §15.0 "Web
## build"). Only its own buffers and its own seeded RNG are touched (never
## the gameplay RNG).
##
## SCORES (Act II, GDD §15.0 "Act II: the Ancient Eye"): an optional score
## Dictionary (SoundData.TIDE_SCORE, "Below the Tide") replaces the Act I
## numbers below key by key; an empty score is the Act I loop exactly, sample
## for sample. Keys (all optional): loop_seconds, root_hz, chords, drone_lp_hz,
## wind_lp_hz, wind_swells, vibrato_hz, vibrato_depth, beat_seconds, and
## "toll" (a tolling bell instead of the heartbeat: {every, partials [[ratio,
## amp], ...], root_hz, dur, decay}).
## Act III (SoundData.IRON_SCORE, "Iron Requiem") adds three optional keys, each
## its own job, scheduled only when present (so every other score's job list,
## and its samples, are unchanged):
##   "pulse" — a filtered saw note every `step` s instead of the heartbeat
##             ({step, hz, dur, amp, decay, lp0, lp1, accent_every, accent_amp}),
##   "hits"  — a struck-metal clang every `every` s from `offset` (inharmonic
##             `partials` [[ratio, amp], ...] over root_hz, plus a noise click),
##   "arp"   — an arpeggio: one note every `step` s cycling up the current
##             loop segment's `chords` entry ({step, dur, amp, decay, lp0, wave}).
## Act IV (SoundData.BRONZE_SCORE, "Hymn of Bronze") adds two more, the same way
## ("arp" takes any Synth wave, so the lyre is a plucked "tri"):
##   "drums" — a war drum every `step` s instead of the heartbeat ({step, hz0, hz1,
##             dur, amp, decay, accent_every, accent_amp, slap, ghost_at, ghost_amp}),
##   "horn"  — brass swells: per `starts` entry a saw and its fifth (`notes`
##             [[root, fifth], ...]) through a rising low-pass ({starts, dur,
##             attack, decay, amp, lp0, lp1, notes}).
## Act V (SoundData.SUN_SCORE, "The Setting Sun") adds three more, the same way:
##   "taiko" — drum patterns instead of the heartbeat: per `beats_per_bar`-beat bar
##             (`beat` s a beat) the hits [beat, "don" | "ka", amp] of pattern
##             bar % patterns.size() ({beat, beats_per_bar, don_hz0, don_hz1,
##             don_dur, don_decay, ka_hz0, ka_hz1, ka_dur, ka_decay, slap, patterns}),
##   "koto"  — plucked notes [start, Hz, amp, glide-to Hz (0 = none)] ({dur, decay,
##             lp0, lp1, click, notes}),
##   "flute" — breathy sustained notes [start, Hz, length] ({amp, breath, attack,
##             decay, vib_hz, vib_depth, notes}).
## Every note ends before the loop end, so the loop stays seamless.
class_name RunLoopSynth
extends RefCounted

## Low-pass cutoff (Hz) of the one-pole filter on the drone's saws.
const DRONE_LP_HZ: float = 60.0  # TUNING (not in GDD)
## Low-pass cutoff (Hz) of the one-pole filter on the wind's noise.
const WIND_LP_HZ: float = 140.0  # TUNING (not in GDD)
## Wind swells per loop (its amplitude LFO).
const WIND_SWELLS: float = 2.0  # TUNING (not in GDD)
## Pad vibrato rate (Hz, snapped to whole cycles per loop).
const PAD_VIBRATO_HZ: float = 5.0  # TUNING (not in GDD)
## Pad vibrato depth (fraction of the pitch).
const PAD_VIBRATO_DEPTH: float = 0.004  # TUNING (not in GDD)

## The finished loop (null until done()).
var stream: AudioStreamWAV = null
## Microseconds of compute spent so far (sum over every step() call).
var compute_usec: int = 0
## Number of jobs in the fixed list (constant after _init).
var job_count: int = 0

## Fixed job list (Callables), run in order.
var _jobs: Array[Callable] = []
## Index of the next job to run (== _jobs.size() once done).
var _next: int = 0
## Mix buffer, one float per sample of the loop.
var _buf: PackedFloat32Array = PackedFloat32Array()
## Samples in the loop (MUSIC_LOOP_SECONDS x MUSIC_RATE).
var _n: int = 0
## Loop length in seconds (SoundData.MUSIC_LOOP_SECONDS).
var _loop_s: float = 0.0
## 1 / MUSIC_RATE (seconds per sample).
var _inv_rate: float = 0.0
## The loop's own seeded RNG (wind noise; never the gameplay RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Drone saw 1 frequency (Hz, snapped to the loop).
var _f1: float = 0.0
## Drone saw 2 frequency (Hz, detuned by 0.6%, snapped).
var _f2: float = 0.0
## Sub-octave sine frequency (Hz, snapped).
var _f_sub: float = 0.0
## Wind swell LFO rate (radians per second).
var _lfo: float = 0.0
## Drone low-pass coefficient (~2*pi*fc/rate).
var _drone_a: float = 0.0
## Wind low-pass coefficient (~2*pi*fc/rate).
var _wind_a: float = 0.0
## Samples the drone / wind filters run before sample 0 (their state at 0
## then equals their state at the loop end).
var _warm: int = 0
## Phase (cycles, 0..1) of drone saw 1.
var _p1: float = 0.0
## Phase (cycles, 0..1) of drone saw 2.
var _p2: float = 0.0
## Phase (cycles, 0..1) of the sub sine.
var _p3: float = 0.0
## Drone low-pass filter state.
var _y_drone: float = 0.0
## Wind low-pass filter state.
var _y_wind: float = 0.0
## Samples per chord segment (loop / chord count).
var _seg: int = 0
## Crossfade overlap (samples) on each side of a chord segment.
var _overlap: int = 0
## Samples of one chord's window (segment plus both overlaps).
var _win: int = 0
## Pad vibrato phase step per sample (radians).
var _vib: float = 0.0
## Current chord's per-voice phase increments (cycles per sample; float32
## storage, as the recipe has always used).
var _freqs: PackedFloat32Array = PackedFloat32Array()
## Current chord's per-voice phases (cycles, 0..1; float32 storage).
var _phases: PackedFloat32Array = PackedFloat32Array()
## Current chord's vibrato phase (radians).
var _vib_phase: float = 0.0
## Running peak of the finished mix (Synth.peak_of()).
var _peak: float = Synth.PEAK_FLOOR
## 16-bit PCM of the loop (2 bytes per sample).
var _bytes: PackedByteArray = PackedByteArray()
## The score (see the header; {} = the Act I loop).
var _score: Dictionary = {}
## Pad chords (Hz per voice), one per loop segment (the score's or SoundData's).
var _chords: Array = []
## Pad vibrato depth (fraction of the pitch).
var _vib_depth: float = PAD_VIBRATO_DEPTH
## Seconds between two heartbeats (the score's or SoundData's).
var _beat_s: float = 0.0


## Sets the loop up (cheap: no audio is rendered here) and schedules every
## job. `rng_seed` seeds the wind noise; `score` (optional) is the track's
## score (see the header; {} = the Act I loop).
func _init(rng_seed: int, score: Dictionary = {}) -> void:
	var rate := Synth.MUSIC_RATE  # Samples per second.
	_score = score
	_loop_s = float(score.get("loop_seconds", SoundData.MUSIC_LOOP_SECONDS))
	_n = int(_loop_s * rate)
	_buf.resize(_n)
	_rng.seed = rng_seed
	_inv_rate = 1.0 / float(rate)
	var root := float(score.get("root_hz", SoundData.MUSIC_ROOT_HZ))  # Drone root (Hz).
	_f1 = Synth.snap(root, _loop_s)
	_f2 = Synth.snap(root * 1.006, _loop_s)
	_f_sub = Synth.snap(root * 0.5, _loop_s)
	_lfo = TAU * float(score.get("wind_swells", WIND_SWELLS)) / _loop_s
	_drone_a = TAU * float(score.get("drone_lp_hz", DRONE_LP_HZ)) * _inv_rate
	_wind_a = TAU * float(score.get("wind_lp_hz", WIND_LP_HZ)) * _inv_rate
	_chords = score.get("chords", SoundData.MUSIC_CHORDS)
	_vib_depth = float(score.get("vibrato_depth", PAD_VIBRATO_DEPTH))
	_beat_s = float(score.get("beat_seconds", SoundData.MUSIC_BEAT_SECONDS))
	# The filters start `warm` samples before 0 (with matching phases, since
	# every frequency loops) so their state at sample 0 equals the state at
	# the loop end: no click at the loop point.
	_warm = rate / 10
	_p1 = fposmod(-_f1 * _warm * _inv_rate, 1.0)
	_p2 = fposmod(-_f2 * _warm * _inv_rate, 1.0)
	_p3 = fposmod(-_f_sub * _warm * _inv_rate, 1.0)
	var chunk := maxi(1, SoundData.WEB_SYNTH_CHUNK_SAMPLES)  # Samples per pass job.
	_schedule(_job_drone, -_warm, _n, chunk)
	var chords: Array = _chords  # One chord per loop segment.
	_seg = _n / chords.size()
	_overlap = _seg / 4
	_win = _seg + 2 * _overlap
	_vib = TAU * Synth.snap(float(score.get("vibrato_hz", PAD_VIBRATO_HZ)), _loop_s) * _inv_rate
	# A chord job does about 3 voices' work per sample: a third of a chunk.
	for c in chords.size():
		_schedule(_job_chord.bind(c), 0, _win, maxi(1, chunk / 3))
	if score.has("toll"):
		_jobs.append(_job_toll)
	elif score.has("pulse"):
		_jobs.append(_job_pulse)  # Act III: the pulsing low synth replaces the heartbeat.
	elif score.has("taiko"):
		_jobs.append(_job_taiko)  # Act V: taiko patterns replace the heartbeat.
	elif score.has("drums"):
		_jobs.append(_job_drums)  # Act IV: the war drum replaces the heartbeat.
	else:
		_jobs.append(_job_heartbeat)
	if score.has("hits"):
		_jobs.append(_job_hits)  # Act III: metallic hits.
	if score.has("arp"):
		_jobs.append(_job_arp)  # Act III: the cold arpeggio (Act IV: the lyre).
	if score.has("horn"):
		_jobs.append(_job_horn)  # Act IV: the brass swells.
	if score.has("koto"):
		_jobs.append(_job_koto)  # Act V: the plucked koto line.
	if score.has("flute"):
		_jobs.append(_job_flute)  # Act V: the shakuhachi lead.
	_schedule(_job_peak, 0, _n, chunk)
	_jobs.append(_job_alloc)
	_schedule(_job_encode, 0, _n, chunk)
	_jobs.append(_job_finish)
	job_count = _jobs.size()


## True once the stream exists.
func done() -> bool:
	return _next >= _jobs.size()


## Runs jobs until `budget_usec` microseconds have passed (at least one job;
## a budget < 0 runs everything). Returns done().
func step(budget_usec: int) -> bool:
	var t0 := Time.get_ticks_usec()
	while _next < _jobs.size():
		_jobs[_next].call()
		_next += 1
		if budget_usec >= 0 and Time.get_ticks_usec() - t0 >= budget_usec:
			break
	compute_usec += Time.get_ticks_usec() - t0
	return done()


## Renders the whole loop in one go and returns it.
func render_all() -> AudioStreamWAV:
	step(-1)
	return stream


## Appends `job` once per `chunk` samples of [from, to), as job(a, b).
func _schedule(job: Callable, from: int, to: int, chunk: int) -> void:
	var a := from
	while a < to:
		var b := mini(to, a + chunk)
		_jobs.append(job.bind(a, b))
		a = b


## Drone (two slightly detuned low-passed saws + sub sine) and wind, samples
## [a, b) of the pass that starts at -_warm.
func _job_drone(a: int, b: int) -> void:
	for i in range(a, b):
		var t := float(i) * _inv_rate
		var saw := (2.0 * _p1 - 1.0) + (2.0 * _p2 - 1.0)
		_y_drone += _drone_a * (saw - _y_drone)
		var wind_amp := 0.05 + 0.04 * sin(_lfo * t)
		_y_wind += _wind_a * (_rng.randf() * 2.0 - 1.0 - _y_wind)
		if i >= 0:
			_buf[i] = _y_drone * 0.32 + sin(TAU * _p3) * 0.22 + _y_wind * wind_amp * 3.0
		_p1 += _f1 * _inv_rate
		_p1 -= floorf(_p1)
		_p2 += _f2 * _inv_rate
		_p2 -= floorf(_p2)
		_p3 += _f_sub * _inv_rate
		_p3 -= floorf(_p3)


## Choir pad, chord `c`, samples [a, b) of its window: the chord fades in /
## out over its segment plus the overlaps, wrapping around the loop end so
## the last chord crossfades into the first.
func _job_chord(a: int, b: int, c: int) -> void:
	if a == 0:
		_freqs = PackedFloat32Array()
		_phases = PackedFloat32Array()
		var voices: Array = _chords[c]  # This chord's voice frequencies (Hz).
		for hz: float in voices:
			_freqs.append(Synth.snap(hz, _loop_s) * _inv_rate)
			_phases.append(0.0)
		_vib_phase = 0.0
	var first := c * _seg - _overlap  # Loop sample of the window's start.
	for j in range(a, b):
		var w := sin(PI * float(j) / float(_win))
		w *= w
		var s := 0.0
		var wob := 1.0 + _vib_depth * sin(_vib_phase)
		for v in _freqs.size():
			var ph := _phases[v]
			s += 1.0 - 4.0 * absf(ph - 0.5)
			ph += _freqs[v] * wob * (1.0 + 0.0015 * float(v))
			_phases[v] = ph - floorf(ph)
		_vib_phase += _vib
		var idx := posmod(first + j, _n)
		_buf[idx] += s * w * 0.11


## Heartbeat: "lub-dub" low thumps every MUSIC_BEAT_SECONDS.
func _job_heartbeat() -> void:
	var beats := int(_loop_s / _beat_s)
	for b in beats:
		for k in 2:
			var at := b * _beat_s + 0.28 * float(k)
			Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": 58.0, "f1": 36.0, "start": at, "dur": 0.35,
				"amp": 0.5 if k == 0 else 0.32, "attack": 0.004, "decay": 0.09}, _rng)


## Tolling bell (a score's "toll", Act II): a struck bell every `every` s, its
## inharmonic partials decaying slowly; each toll ends before the next (and
## before the loop end), so the loop stays seamless.
func _job_toll() -> void:
	var t: Dictionary = _score["toll"]
	var every := float(t["every"])  # Seconds between tolls.
	var root := float(t["root_hz"])  # Bell strike pitch (Hz).
	var tolls := int(_loop_s / every)
	for b in tolls:
		for p: Array in t["partials"]:
			Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": root * float(p[0]), "start": float(b) * every,
				"dur": minf(float(t["dur"]), every - 0.05), "amp": float(p[1]), "attack": 0.006, "decay": float(t["decay"])}, _rng)


## Pulsing low synth (a score's "pulse", Act III): a filtered saw note every
## `step` s, every `accent_every`-th one louder; the last ends before the loop end.
func _job_pulse() -> void:
	var p: Dictionary = _score["pulse"]
	var step := float(p["step"])  # s between notes.
	var dur := float(p["dur"])  # Note length (s).
	var n := int((_loop_s - dur) / step) + 1  # Notes that fit in the loop.
	var every := int(p.get("accent_every", 0))  # Notes per accent (0 = none).
	for k in n:
		var accent := every > 0 and k % every == 0  # A beat note.
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "saw", "f0": float(p["hz"]), "start": float(k) * step, "dur": dur,
			"amp": float(p["accent_amp"]) if accent else float(p["amp"]), "attack": 0.004, "decay": float(p["decay"]),
			"lp0": float(p["lp0"]), "lp1": float(p["lp1"])}, _rng)


## Metallic hits (a score's "hits", Act III): an inharmonic clang of struck
## steel every `every` s from `offset`, with a short noise click.
func _job_hits() -> void:
	var h: Dictionary = _score["hits"]
	var every := float(h["every"])  # s between clangs.
	var dur := float(h["dur"])  # Clang length (s).
	var t := float(h["offset"])  # Next clang (s).
	while t + dur < _loop_s:
		for pr: Array in h["partials"]:
			Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": float(h["root_hz"]) * float(pr[0]), "start": t,
				"dur": dur, "amp": float(pr[1]), "attack": 0.002, "decay": float(h["decay"])}, _rng)
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": t, "dur": 0.03, "amp": float(h["click"]),
			"decay": 0.008, "lp0": 7000.0}, _rng)
		t += every


## Cold arpeggio (a score's "arp", Act III): one note every `step` s, cycling
## up the tones of the chord of the loop segment it falls in.
func _job_arp() -> void:
	var a: Dictionary = _score["arp"]
	var step := float(a["step"])  # s between notes.
	var dur := float(a["dur"])  # Note length (s).
	var chords: Array = a["chords"]  # One tone list per loop segment.
	var seg_s := _loop_s / float(chords.size())  # Segment length (s).
	var n := int((_loop_s - dur) / step) + 1  # Notes that fit in the loop.
	for k in n:
		var t := float(k) * step  # Note start (s).
		var tones: Array = chords[mini(chords.size() - 1, int(t / seg_s))]  # This segment's tones.
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": String(a["wave"]), "f0": float(tones[k % tones.size()]), "start": t,
			"dur": dur, "amp": float(a["amp"]), "attack": 0.003, "decay": float(a["decay"]), "lp0": float(a["lp0"])}, _rng)


## War drum (a score's "drums", Act IV): a skin thump (a falling sine with a
## noise slap) every `step` s, every `accent_every`-th one louder, and a soft
## ghost hit `ghost_at` of a step after each unaccented beat. A hit that would
## not end before the loop end is skipped, so the loop stays seamless.
func _job_drums() -> void:
	var d: Dictionary = _score["drums"]
	var step := float(d["step"])  # s between beats.
	var dur := float(d["dur"])  # Hit length (s).
	var every := int(d.get("accent_every", 0))  # Beats per accent (0 = none).
	var k := 0  # Beat index.
	while float(k) * step + dur < _loop_s:
		var t := float(k) * step  # This beat (s).
		var accent := every > 0 and k % every == 0  # A bar's first beat.
		var amp := float(d["accent_amp"]) if accent else float(d["amp"])  # Thump level.
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": float(d["hz0"]), "f1": float(d["hz1"]), "start": t,
			"dur": dur, "amp": amp, "attack": 0.003, "decay": float(d["decay"])}, _rng)
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": t, "dur": 0.05, "amp": float(d["slap"]),
			"decay": 0.012, "lp0": 1400.0}, _rng)
		var ghost := t + step * float(d["ghost_at"])  # The soft after-beat.
		if not accent and ghost + dur < _loop_s:
			Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": float(d["hz0"]) * 0.9, "f1": float(d["hz1"]),
				"start": ghost, "dur": dur * 0.7, "amp": float(d["ghost_amp"]), "attack": 0.003, "decay": float(d["decay"])}, _rng)
		k += 1


## Brass swells (a score's "horn", Act IV): at each `starts` time a saw and its
## fifth rise out of silence (slow attack) through a low-pass that opens, then
## fade; each ends before the loop end.
func _job_horn() -> void:
	var h: Dictionary = _score["horn"]
	var starts: Array = h["starts"]  # Swell start times (s).
	var notes: Array = h["notes"]  # [root, fifth] (Hz) of each swell.
	var dur := minf(float(h["dur"]), _loop_s)  # Swell length (s).
	for k in starts.size():
		var t := float(starts[k])  # This swell's start (s).
		var pair: Array = notes[mini(k, notes.size() - 1)]  # Its two pitches.
		for hz: float in pair:
			Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "saw", "f0": hz, "start": t, "dur": minf(dur, _loop_s - t - 0.05),
				"amp": float(h["amp"]), "attack": float(h["attack"]), "decay": float(h["decay"]),
				"lp0": float(h["lp0"]), "lp1": float(h["lp1"]), "vib_hz": 5.0, "vib_depth": 0.004}, _rng)


## Taiko (a score's "taiko", Act V): each bar plays one pattern of deep "don" and
## rim "ka" hits; a hit that would not end before the loop end is skipped.
func _job_taiko() -> void:
	var t: Dictionary = _score["taiko"]
	var beat := float(t["beat"])  # s per beat.
	var bar_beats := int(t["beats_per_bar"])  # Beats per bar.
	var patterns: Array = t["patterns"]  # Hit lists, one per pattern.
	var bars := int(_loop_s / (beat * float(bar_beats)))  # Whole bars in the loop.
	for b in bars:
		for h: Array in patterns[b % patterns.size()]:
			var at := (float(b * bar_beats) + float(h[0])) * beat  # Hit time (s).
			var amp := float(h[2])  # Hit level.
			if String(h[1]) == "don":
				var dur := float(t["don_dur"])  # Hit length (s).
				if at + dur >= _loop_s:
					continue
				Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": float(t["don_hz0"]), "f1": float(t["don_hz1"]),
					"start": at, "dur": dur, "amp": amp, "attack": 0.003, "decay": float(t["don_decay"])}, _rng)
				Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": at, "dur": 0.05, "amp": float(t["slap"]),
					"decay": 0.012, "lp0": 1200.0}, _rng)
			else:
				var dur := float(t["ka_dur"])  # Rim hit length (s).
				if at + dur >= _loop_s:
					continue
				Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": float(t["ka_hz0"]), "f1": float(t["ka_hz1"]),
					"start": at, "dur": dur, "amp": amp, "attack": 0.002, "decay": float(t["ka_decay"])}, _rng)
				Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": at, "dur": 0.03, "amp": amp * 0.6,
					"decay": 0.008, "lp0": 4000.0}, _rng)


## Koto (a score's "koto", Act V): plucked triangle notes with a short noise click
## and a closing low-pass; a note may glide to a second pitch. Each is cut at the loop end.
func _job_koto() -> void:
	var k: Dictionary = _score["koto"]
	for n: Array in k["notes"]:
		var at := float(n[0])  # Note start (s).
		var hz := float(n[1])  # Pitch (Hz).
		var to_hz := float(n[3]) if float(n[3]) > 0.0 else hz  # Glide target (Hz).
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "tri", "f0": hz, "f1": to_hz, "start": at,
			"dur": minf(float(k["dur"]), _loop_s - at - 0.05), "amp": float(n[2]), "attack": 0.002, "decay": float(k["decay"]),
			"lp0": float(k["lp0"]), "lp1": float(k["lp1"])}, _rng)
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": at, "dur": 0.02, "amp": float(k["click"]),
			"decay": 0.006, "lp0": 5000.0}, _rng)


## Shakuhachi (a score's "flute", Act V): a sine with slow vibrato and an octave
## overtone, plus a breath of filtered noise that swells in with the note.
func _job_flute() -> void:
	var f: Dictionary = _score["flute"]
	for n: Array in f["notes"]:
		var at := float(n[0])  # Note start (s).
		var hz := float(n[1])  # Pitch (Hz).
		var dur := minf(float(n[2]), _loop_s - at - 0.05)  # Note length (s).
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": hz, "start": at, "dur": dur, "amp": float(f["amp"]),
			"attack": float(f["attack"]), "decay": float(f["decay"]), "vib_hz": float(f["vib_hz"]), "vib_depth": float(f["vib_depth"])}, _rng)
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "sine", "f0": hz * 2.0, "start": at, "dur": dur, "amp": float(f["amp"]) * 0.18,
			"attack": float(f["attack"]) * 1.4, "decay": float(f["decay"]), "vib_hz": float(f["vib_hz"]), "vib_depth": float(f["vib_depth"])}, _rng)
		Synth.add_layer(_buf, Synth.MUSIC_RATE, {"wave": "noise", "start": at, "dur": dur, "amp": float(f["breath"]),
			"attack": float(f["attack"]) * 0.8, "decay": float(f["decay"]), "lp0": hz * 2.5, "lp1": hz * 3.5}, _rng)


## Peak search over samples [a, b) of the finished mix.
func _job_peak(a: int, b: int) -> void:
	_peak = Synth.peak_of(_buf, a, b, _peak)


## Sizes the PCM buffer (2 bytes per sample).
func _job_alloc() -> void:
	_bytes.resize(_n * 2)


## Normalises and encodes samples [a, b) to 16-bit PCM.
func _job_encode(a: int, b: int) -> void:
	Synth.encode_range(_bytes, _buf, Synth.peak_gain(_peak), a, b)


## Wraps the PCM in the looping stream and frees the mix buffer.
func _job_finish() -> void:
	stream = Synth.pcm_stream(_bytes, Synth.MUSIC_RATE, true)
	_buf = PackedFloat32Array()
