## MenuThemeSynth — renders the main menu theme ("Grave Lullaby", score and
## mix in MenuThemeData) into one seamless looping 16-bit mono AudioStreamWAV,
## the same no-audio-files way Synth renders the effects and the in-run loop.
##
## How it is built:
##   * Three rates, so each layer costs only the samples it needs. The short
##     bright partials of the music box and the candle crackle render at
##     RATE_HI into `_hi`; the sung lead and the harp at RATE_LO = RATE_HI / 2
##     into `_wet` (through the reverb), the drone and wind into `_dry` (no
##     reverb); the low layers (choir pad, pedal organ, bell, timpani, the
##     music box's body and echoes) at RATE_LO / 2 into `_deep` (through the
##     reverb). The reverb runs at RATE_LO / 2 too (its tail is dark anyway)
##     and its pass also upsamples `_deep` and its return x2 into `_dry`; a
##     final pass upsamples `_dry` x2 onto `_hi`. Both x2 steps use a 4-tap
##     half-band interpolation (the reverb return a linear one).
##   * Instruments: wavetable voices whose single-cycle tables are shaped by
##     vowel formants per note ("ooh" pad, "aah" lead) or by fixed harmonics
##     (pedal organ), with a second singer whose detune drifts slowly and a
##     vibrato; decaying sine partials (music box, church bell, timpani) from
##     a 2-multiply recursive oscillator; a Karplus-Strong string with
##     all-pass tuning (harp); seeded noise (wind, crackle, strikes).
##   * Seamless loop: every note is written with wrap-around (a tail that
##     runs past the end continues at the top), continuous oscillators are
##     snapped to whole cycles per loop, the wind's noise is read from a table
##     by the wrapped sample index (periodic), and the stateful passes (wind
##     filters, reverb) are first run over the loop's last seconds so their
##     state at sample 0 equals their state at the end. The mean is removed
##     (no DC offset) and the loop is normalised to MenuThemeData.PEAK.
##   * Fast enough for GDScript (about 12 ns per statement): hot loops run
##     over plain index ranges split at the loop end (no per-sample wrap
##     test), voices update vibrato / drift / envelope once per VOICE_BLOCK
##     samples, and the reverb shares one masked write index.
##   * Chunked: the work is a fixed list of small jobs (one note voice, or
##     CHUNK_SAMPLES of a pass). step() runs jobs until a time budget is
##     spent, so the Web build can spread it over frames; Sfx renders it on a
##     worker thread on desktop (render_all()). The job order is fixed, so the
##     result is identical however it is chunked.
## It only touches its own buffers and its own seeded RandomNumberGenerator
## (never the gameplay RNG), so it is safe on a worker thread and the same
## on every run.
class_name MenuThemeSynth
extends RefCounted

## Bus id: the bright RATE_HI bus (`_hi`).
const BUS_HI: int = 0
## Bus id: the RATE_LO bus that feeds the reverb (`_wet`).
const BUS_WET: int = 1
## Bus id: the RATE_LO bus that skips the reverb (`_dry`).
const BUS_DRY: int = 2
## Bus id: the RATE_LO / 2 bus that feeds the reverb (`_deep`).
const BUS_DEEP: int = 3
## Fixed-point fraction bits of a wavetable voice's integer phase.
const PHASE_BITS: int = 16
## Release fade (s) at the end of every decaying partial, so none is cut off.
const PARTIAL_RELEASE: float = 0.05  # TUNING (not in GDD)
## A decaying partial is rendered until its envelope falls to this fraction
## of its start level (then faded out over PARTIAL_RELEASE).
const PARTIAL_FLOOR: float = 0.004  # TUNING (not in GDD)
## Longest a single decaying partial is rendered (s).
const PARTIAL_MAX_SECONDS: float = 7.0  # TUNING (not in GDD)
## Samples per vibrato / drift / envelope update of a wavetable voice
## (32 = 2.9 ms at RATE_LO: far finer than any of those movements).
const VOICE_BLOCK: int = 32
## Seconds of the loop's end the bed pass runs through first, so the wind
## filters (cutoffs >= 100 Hz, settled within a few ms) start the loop in the
## state they end it in.
const BED_PRIME: float = 0.25
## Samples per gain update of the bed pass (a power of two).
const BED_BLOCK: int = 64
## Length of the periodic noise table of the wind (a power of two; 65536
## samples = about 6 s at RATE_LO, long enough not to be heard repeating
## under the band-pass and the swells).
const NOISE_SIZE: int = 65536
## Length of every reverb delay line (a power of two longer than the
## longest delay at the reverb's rate, so one masked index serves them all).
const REVERB_LINE: int = 1024

## The finished loop (null until done()).
var stream: AudioStreamWAV = null
## Microseconds of compute spent so far (sum over every step() call).
var compute_usec: int = 0
## Number of jobs in the render (for progress reports).
var job_count: int = 0

## The fixed, ordered list of render jobs.
var _jobs: Array[Callable] = []
## Index of the next job to run.
var _next: int = 0
## RATE_LO samples per beat (8820 at 75 BPM).
var _spb: float = 0.0
## Loop length in RATE_LO samples (even).
var _n_lo: int = 0
## Loop length in RATE_HI samples (exactly 2 x _n_lo).
var _n_hi: int = 0
## Bright bus at RATE_HI; becomes the final mix.
var _hi: PackedFloat32Array = PackedFloat32Array()
## Low-rate bus that feeds the reverb.
var _wet: PackedFloat32Array = PackedFloat32Array()
## Low-rate bus that skips the reverb; the reverb pass adds `_wet`, the
## upsampled `_deep` and the reverb return into it, so after that pass it
## holds everything but the bright bus.
var _dry: PackedFloat32Array = PackedFloat32Array()
## Half-low-rate bus (RATE_LO / 2, _n_lo / 2 samples) that feeds the reverb.
var _deep: PackedFloat32Array = PackedFloat32Array()
## Wavetable cache: "kind:midi" -> PackedFloat32Array (TABLE_SIZE samples).
var _tables: Dictionary = {}
## The theme's own RNG (noise tables, harp excitations, crackle placement).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Reverb delay lines, REVERB_LINE samples each: the 4 combs then the 2
## all-passes.
var _rev_lines: Array[PackedFloat32Array] = []
## Reverb state: [comb damping filters x4, last return sample, write index].
var _rev_state: PackedFloat64Array = PackedFloat64Array()
## White noise table of the wind (NOISE_SIZE samples, from `_rng`).
var _noise: PackedFloat32Array = PackedFloat32Array()
## Wind filter states: [low-cut low-pass, high-cut low-pass].
var _wind_lp: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
## First virtual sample of the bed pass (negative: the priming run-in).
var _bed_from: int = 0
## Drone oscillator recursion states: [y1, y2] per drone note, flattened.
var _drone_y: PackedFloat64Array = PackedFloat64Array()
## Running mix statistics over the final buffer: [sum, min, max].
var _stats: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0])
## Final PCM bytes (16-bit little-endian), filled by the encode pass.
var _bytes: PackedByteArray = PackedByteArray()


## Schedules every job (cheap: no audio is rendered here).
func _init() -> void:
	_rng.seed = MenuThemeData.SEED
	_spb = float(MenuThemeData.RATE_LO) * 60.0 / MenuThemeData.BPM
	_n_lo = int(roundf(_spb * MenuThemeData.BEATS_PER_BAR * MenuThemeData.BARS)) / 2 * 2
	_n_hi = _n_lo * 2
	_jobs.append(_job_setup)
	_schedule_pad_and_bass()
	_schedule_bells_and_timpani()
	_schedule_music_box()
	_schedule_harp()
	_schedule_choir()
	_jobs.append(_job_crackle)
	_bed_from = -int(BED_PRIME * MenuThemeData.RATE_LO) / BED_BLOCK * BED_BLOCK
	_schedule_pass(_job_bed, _bed_from, _n_lo)
	# The reverb runs at RATE_LO / 2: its pass counts in those samples.
	var prime_rev := int(MenuThemeData.REVERB_PRIME * MenuThemeData.RATE_LO * 0.5)
	_schedule_pass(_job_reverb, -prime_rev, _n_lo / 2)
	_schedule_pass(_job_mixdown, 0, _n_lo)
	_schedule_pass(_job_encode, 0, _n_hi)
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


## Loop length in seconds.
func loop_seconds() -> float:
	return float(_n_lo) / float(MenuThemeData.RATE_LO)


## MIDI note -> frequency (Hz), A4 = 69 = 440 Hz.
static func midi_hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


# =====================================================================================
# Scheduling
# =====================================================================================

## Queues `job` over the sample range [from, to) in CHUNK_SAMPLES chunks.
func _schedule_pass(job: Callable, from: int, to: int) -> void:
	var a := from
	while a < to:
		var b := mini(to, a + MenuThemeData.CHUNK_SAMPLES)
		_jobs.append(job.bind(a, b))
		a = b


## Beat (from the top) -> RATE_LO sample index.
func _beat_lo(beat: float) -> int:
	return int(roundf(beat * _spb))


## The BAR_DYNAMICS gain at `beat` (bars wrap around the loop).
func _dyn(beat: float) -> float:
	var dyn: Array = MenuThemeData.BAR_DYNAMICS
	return float(dyn[posmod(int(floorf(beat / MenuThemeData.BEATS_PER_BAR)), dyn.size())])


## Pad (three "ooh" voices) and pedal organ for every chord of CHORDS.
func _schedule_pad_and_bass() -> void:
	var xf := MenuThemeData.PAD_XFADE_BEATS
	var bxf := MenuThemeData.BASS_XFADE_BEATS
	var vib: Vector2 = MenuThemeData.PAD_VIBRATO
	for c in MenuThemeData.CHORDS.size():
		var ch: Array = MenuThemeData.CHORDS[c]
		var beat: float = ch[0]
		var beats: float = ch[1]
		var g0 := _dyn(beat)
		var g1 := _dyn(beat + beats)
		var voices: Array = ch[2]
		for v in voices.size():
			var note := int(voices[v])
			_jobs.append(_job_voice.bind(BUS_DEEP, "pad", note, beat - xf * 0.5, beats + xf,
				xf, xf, MenuThemeData.PAD_GAIN * g0, MenuThemeData.PAD_GAIN * g1,
				MenuThemeData.PAD_SECOND_SINGER, MenuThemeData.PAD_DETUNE_CENTS,
				vib.x * (1.0 + 0.07 * float(v)), vib.y, 0.0, 0.13 * float(v) + 0.05 * float(c)))
		_jobs.append(_job_voice.bind(BUS_DEEP, "bass", int(ch[3]), beat - bxf * 0.5, beats + bxf,
			bxf, bxf, MenuThemeData.BASS_GAIN * g0, MenuThemeData.BASS_GAIN * g1, 0.0, 0.0,
			0.0, 0.0, 0.0, 0.0))


## Church bell tolls and the timpani hits / roll.
func _schedule_bells_and_timpani() -> void:
	for toll: Array in MenuThemeData.BELL_TOLLS:
		var hz := midi_hz(float(toll[1]))
		var amp := MenuThemeData.BELL_GAIN * float(toll[2])
		for p: Array in MenuThemeData.BELL_PARTIALS:
			_jobs.append(_job_partial.bind(BUS_DEEP, float(toll[0]), hz * float(p[0]),
				amp * float(p[1]), float(p[2]), 0.004))
		_jobs.append(_job_noise_burst.bind(BUS_DEEP, float(toll[0]), amp * 0.35, 0.03, 1800.0))
	for hit: Array in MenuThemeData.TIMPANI_HITS:
		_queue_timpani(float(hit[0]), int(hit[1]), float(hit[2]), MenuThemeData.TIMPANI_MODES.size(), 1.0)
	var roll: Array = MenuThemeData.TIMPANI_ROLL
	var strokes := int(roundf((float(roll[1]) - float(roll[0])) * float(roll[5])))
	for s in strokes:
		var f := float(s) / float(maxi(1, strokes - 1))
		var beat := float(roll[0]) + float(s) / float(roll[5])
		# Alternate hands: every other stroke a touch softer.
		var vel := lerpf(float(roll[3]), float(roll[4]), f * f) * (1.0 if s % 2 == 0 else 0.85)
		_queue_timpani(beat, int(roll[2]), vel, 2, MenuThemeData.TIMPANI_ROLL_DECAY)


## One timpani stroke: its first `modes` modes (decay times x `decay`) plus
## a soft felt thump.
func _queue_timpani(beat: float, note: int, vel: float, modes: int, decay: float) -> void:
	var hz := midi_hz(float(note))
	var amp := MenuThemeData.TIMPANI_GAIN * vel
	for m in mini(modes, MenuThemeData.TIMPANI_MODES.size()):
		var md: Array = MenuThemeData.TIMPANI_MODES[m]
		_jobs.append(_job_partial.bind(BUS_DEEP, beat, hz * float(md[0]), amp * float(md[1]), float(md[2]) * decay, 0.006))
	_jobs.append(_job_noise_burst.bind(BUS_DEEP, beat, amp * 0.5, 0.025, 500.0))


## The music-box melody (its sustained partials on the deep bus, its short
## bright "ping" partials on the bright bus) and its darker echoes.
func _schedule_music_box() -> void:
	for nt: Array in MenuThemeData.MELODY:
		var beat: float = nt[0]
		var hz := midi_hz(float(nt[1]))
		var amp := MenuThemeData.MUSIC_BOX_GAIN * float(nt[3])
		for p: Array in MenuThemeData.MUSIC_BOX_PARTIALS:
			var bus := BUS_HI if int(p[3]) == 1 else BUS_DEEP
			_jobs.append(_job_partial.bind(bus, beat, hz * float(p[0]), amp * float(p[1]), float(p[2]), 0.0015))
		for e: Array in MenuThemeData.MUSIC_BOX_ECHOES:
			_jobs.append(_job_partial.bind(BUS_DEEP, beat + float(e[0]), hz, amp * float(e[1]), float(e[2]), 0.004))


## Harp arpeggios over the chords, phrase by phrase (HARP_PHRASES).
func _schedule_harp() -> void:
	var bpb := float(MenuThemeData.BEATS_PER_BAR)
	for ph: Array in MenuThemeData.HARP_PHRASES:
		var pattern: Array = ph[3]
		var step: float = ph[2]
		var beat := (float(ph[0]) - 1.0) * bpb
		var end := (float(ph[1]) - 1.0) * bpb
		var k := 0
		while beat < end - 0.001:
			var ch := _chord_at(beat)
			var voices: Array = ch[2]
			var tones: Array = [int(ch[3]) + 12, int(voices[0]), int(voices[1]), int(voices[2]), int(voices[0]) + 12]
			var note := int(tones[int(pattern[k % pattern.size()])])
			# A gentle lilt: downbeats of each pattern cycle a little stronger.
			var accent := 1.0 if k % pattern.size() == 0 else 0.82
			_jobs.append(_job_pluck.bind(beat, note, float(ph[4]) * accent * _dyn(beat)))
			beat += step
			k += 1


## The chord of CHORDS sounding at `beat`.
func _chord_at(beat: float) -> Array:
	var found: Array = MenuThemeData.CHORDS[0]
	for ch: Array in MenuThemeData.CHORDS:
		if float(ch[0]) <= beat + 0.001:
			found = ch
	return found


## The sung "aah" lead of section B.
func _schedule_choir() -> void:
	var env: Vector2 = MenuThemeData.CHOIR_ENVELOPE
	var vib: Vector3 = MenuThemeData.CHOIR_VIBRATO
	var att_beats := env.x * MenuThemeData.BPM / 60.0
	var rel_beats := env.y * MenuThemeData.BPM / 60.0
	for i in MenuThemeData.CHOIR_LEAD.size():
		var nt: Array = MenuThemeData.CHOIR_LEAD[i]
		var g := MenuThemeData.CHOIR_GAIN * float(nt[3]) * _dyn(float(nt[0]))
		_jobs.append(_job_voice.bind(BUS_WET, "choir", int(nt[1]), float(nt[0]), float(nt[2]) + rel_beats,
			att_beats, rel_beats, g, g * 0.9, MenuThemeData.CHOIR_SECOND_SINGER,
			MenuThemeData.CHOIR_DETUNE_CENTS, vib.x, vib.y, vib.z, 0.31 * float(i)))


# =====================================================================================
# Jobs
# =====================================================================================

## Allocates the buses, the wind's noise table and the reverb lines.
func _job_setup() -> void:
	_hi.resize(_n_hi)
	_hi.fill(0.0)
	_wet.resize(_n_lo)
	_wet.fill(0.0)
	_dry.resize(_n_lo)
	_dry.fill(0.0)
	_deep.resize(_n_lo / 2)
	_deep.fill(0.0)
	for nt: int in MenuThemeData.DRONE_NOTES:
		_drone_y.append(0.0)
		_drone_y.append(0.0)
	_noise.resize(NOISE_SIZE)
	for i in NOISE_SIZE:
		_noise[i] = _rng.randf() * 2.0 - 1.0
	for i in 6:
		var line := PackedFloat32Array()
		line.resize(REVERB_LINE)
		line.fill(0.0)
		_rev_lines.append(line)
	_rev_state.resize(6)
	_rev_state.fill(0.0)


## The bus array for a bus id.
func _bus(bus: int) -> PackedFloat32Array:
	if bus == BUS_HI:
		return _hi
	if bus == BUS_DEEP:
		return _deep
	return _wet if bus == BUS_WET else _dry


## Sample rate (Hz) of a bus.
static func _bus_rate(bus: int) -> float:
	if bus == BUS_HI:
		return float(MenuThemeData.RATE_HI)
	if bus == BUS_DEEP:
		return float(MenuThemeData.RATE_LO) * 0.5
	return float(MenuThemeData.RATE_LO)


## Beats -> samples of a bus (positions or lengths).
func _bus_n(bus: int, beats: float) -> int:
	return int(roundf(beats * _spb * _bus_rate(bus) / float(MenuThemeData.RATE_LO)))


## Envelope of a wavetable voice at sample `x` of `length`: the gain glides
## g0 -> g1, with raised-cosine fades over the first `in_n` and the last
## `out_n` samples.
static func _voice_env(x: float, length: float, in_n: float, out_n: float, g0: float, g1: float) -> float:
	var g := lerpf(g0, g1, clampf(x / length, 0.0, 1.0))
	if x < in_n:
		g *= 0.5 - 0.5 * cos(PI * x / in_n)
	var r := length - x
	if r < out_n:
		g *= 0.5 - 0.5 * cos(PI * maxf(r, 0.0) / out_n)
	return g


## One wavetable voice (pad / bass / choir note) of `beats` beats from
## `beat`, with raised-cosine fades of `in_beats` / `out_beats` and a gain
## gliding g0 -> g1. `second` (0..1) is the level of a second singer whose
## detune drifts slowly between 0 and `det_cents` (an ensemble whose beating
## keeps changing speed instead of a steady tremolo; 0 = one voice). Vibrato
## `vib_hz` / `vib_depth` eases in over about `vib_delay` s; `phase0` (cycles)
## keeps voices from starting in phase. Pitch, drift and the envelope's slope
## are set once per VOICE_BLOCK samples; the envelope itself ramps linearly
## inside a block, so there is no zipper noise.
func _job_voice(bus: int, kind: String, note: int, beat: float, beats: float, in_beats: float,
		out_beats: float, g0: float, g1: float, second: float, det_cents: float, vib_hz: float,
		vib_depth: float, vib_delay: float, phase0: float) -> void:
	var buf := _bus(bus)
	var n := buf.size()
	var rate := _bus_rate(bus)
	var tbl := _table(kind, note, rate)
	var mask := MenuThemeData.TABLE_SIZE - 1
	var length := _bus_n(bus, beats)
	var flen := float(length)
	var in_n := float(clampi(_bus_n(bus, in_beats), 1, length / 2))
	var out_n := float(clampi(_bus_n(bus, out_beats), 1, length - int(in_n)))
	# Phases are integers in table samples << PHASE_BITS (no float -> int
	# conversion in the hot loop); the table index is (phase >> bits) & mask.
	var one := float(1 << PHASE_BITS)
	var inc := midi_hz(float(note)) / rate * float(MenuThemeData.TABLE_SIZE) * one
	var pa := int(fposmod(phase0, 1.0) * float(MenuThemeData.TABLE_SIZE) * one)
	var pb := int(fposmod(phase0 + 0.37, 1.0) * float(MenuThemeData.TABLE_SIZE) * one)
	var sh := PHASE_BITS
	var vib_w := TAU * vib_hz / rate
	var vib_ph := TAU * phase0
	var drift_w := TAU * MenuThemeData.ENSEMBLE_DRIFT_HZ * (1.0 + 0.3 * fposmod(phase0 * 7.0, 1.0)) / rate
	var det := (pow(2.0, det_cents / 1200.0) - 1.0) * 0.5  # Drift amplitude (frequency ratio).
	var onset := maxf(1.0, vib_delay * rate)
	# Two singers are scaled so the voice keeps the level of one.
	var norm := 1.0 / (1.0 + second)
	var start := posmod(_bus_n(bus, beat), n)
	var e := _voice_env(0.0, flen, in_n, out_n, g0, g1) * norm
	var v := 0
	while v < length:
		var cnt := mini(VOICE_BLOCK, length - v)
		var mid := float(v) + float(cnt) * 0.5
		var depth := vib_depth * (1.0 - exp(-mid / onset)) if vib_delay > 0.0 else vib_depth
		var vm := depth * sin(vib_w * mid + vib_ph)
		var ia := int(inc * (1.0 + vm))
		var ib := int(inc * (1.0 - vm + det * (1.0 + sin(drift_w * mid))))
		var e1 := _voice_env(float(v + cnt), flen, in_n, out_n, g0, g1) * norm
		var de := (e1 - e) / float(cnt)
		var p0 := start + v
		if p0 >= n:
			p0 -= n
		var left := cnt
		while left > 0:
			var piece := mini(left, n - p0)
			if second > 0.0:
				for j in range(p0, p0 + piece):
					buf[j] += (tbl[(pa >> sh) & mask] + tbl[(pb >> sh) & mask] * second) * e
					pa += ia
					pb += ib
					e += de
			else:
				for j in range(p0, p0 + piece):
					buf[j] += tbl[(pa >> sh) & mask] * e
					pa += ia
					e += de
			left -= piece
			p0 = 0
		e = e1
		v += cnt


## One exponentially decaying sine partial at `hz` starting at `beat`
## (amplitude `amp`, decay time constant `tau` s, linear attack `attack` s)
## on `bus`, from a recursive oscillator (y = c*y1 - y2). Rendered in three
## segments (attack / body / release), each split where it crosses the loop
## end, so the hot loop is five statements.
func _job_partial(bus: int, beat: float, hz: float, amp: float, tau: float, attack: float) -> void:
	var buf := _bus(bus)
	var n := buf.size()
	var rate := _bus_rate(bus)
	var w := TAU * hz / rate
	if w >= PI * 0.9 or amp <= 0.0:
		return
	var start := _bus_n(bus, beat)
	var length := int(minf(PARTIAL_MAX_SECONDS, tau * log(1.0 / PARTIAL_FLOOR)) * rate)
	var rel := mini(length / 2, int(PARTIAL_RELEASE * rate))
	var att := mini(length / 2, maxi(1, int(attack * rate)))
	var c := 2.0 * cos(w)
	var y1 := sin(-w)
	var y2 := sin(-2.0 * w)
	var env := amp
	var k := exp(-1.0 / (tau * rate))
	var idx := posmod(start, n)
	# [samples, start gain, gain step per sample]; the body has gain 1.
	var segs: Array = [[att, 0.0, 1.0 / float(att)], [length - att - rel, 1.0, 0.0], [rel, 1.0, -1.0 / float(maxi(1, rel))]]
	for seg: Array in segs:
		var left: int = seg[0]
		var g: float = seg[1]
		var dg: float = seg[2]
		while left > 0:
			var piece := mini(left, n - idx)
			if dg == 0.0:
				for j in range(idx, idx + piece):
					var s := c * y1 - y2
					y2 = y1
					y1 = s
					buf[j] += s * env
					env *= k
			else:
				for j in range(idx, idx + piece):
					var s := c * y1 - y2
					y2 = y1
					y1 = s
					buf[j] += s * env * g
					env *= k
					g += dg
			left -= piece
			idx += piece
			if idx >= n:
				idx -= n


## A short low-passed noise burst (bell strike, timpani felt) at `beat`:
## amplitude `amp`, decay time constant `tau` s, low-pass cutoff `lp_hz`.
func _job_noise_burst(bus: int, beat: float, amp: float, tau: float, lp_hz: float) -> void:
	var buf := _bus(bus)
	var n := buf.size()
	var rate := _bus_rate(bus)
	var length := int(tau * 7.0 * rate)
	var a := 1.0 - exp(-TAU * lp_hz / rate)
	var k := exp(-1.0 / (tau * rate))
	var env := amp
	var y := 0.0
	var idx := posmod(_bus_n(bus, beat), n)
	for j in length:
		y += a * (_rng.randf() * 2.0 - 1.0 - y)
		buf[idx] += y * env * minf(1.0, float(j) * 0.02)
		env *= k
		idx += 1
		if idx == n:
			idx = 0


## One harp note: a Karplus-Strong string at RATE_LO (a noise burst in a
## delay line, averaged each period), tuned exactly by a first-order all-pass
## for the fractional part of the period. Wet bus.
func _job_pluck(beat: float, note: int, vel: float) -> void:
	var buf := _wet
	var n := buf.size()
	var rate := float(MenuThemeData.RATE_LO)
	var hs: Vector3 = MenuThemeData.HARP_STRING
	var period := rate / midi_hz(float(note))
	# Loop delay = N (line) + 0.5 (averager) + frac (all-pass, kept in 0.1..1.1).
	var line_n := int(floorf(period - 0.6))
	var frac := period - 0.5 - float(line_n)
	var ap_c := (1.0 - frac) / (1.0 + frac)
	var line := PackedFloat32Array()
	line.resize(line_n)
	# Excitation: low-passed noise (brightness = HARP_STRING.y), mean removed.
	var lp := 0.0
	var mean := 0.0
	for i in line_n:
		lp += hs.y * (_rng.randf() * 2.0 - 1.0 - lp)
		line[i] = lp
		mean += lp
	mean /= float(line_n)
	for i in line_n:
		line[i] -= mean
	var amp := MenuThemeData.HARP_GAIN * vel
	var length := int(hs.z * rate)
	var rel_n := int(0.25 * rate)
	var loss := hs.x * 0.5
	var prev := 0.0
	var ax := 0.0
	var ay := 0.0
	var p := 0
	var idx := posmod(_beat_lo(beat), n)
	# [samples, start gain, gain step]: a tiny attack, the ring, a linear release.
	var segs: Array = [[8, 0.0, amp / 8.0], [length - 8 - rel_n, amp, 0.0], [rel_n, amp, -amp / float(rel_n)]]
	for seg: Array in segs:
		var left: int = seg[0]
		var e: float = seg[1]
		var de: float = seg[2]
		while left > 0:
			var piece := mini(left, n - idx)
			for j in range(idx, idx + piece):
				var out := line[p]
				var avg := loss * (out + prev)
				prev = out
				var ap := ap_c * avg + ax - ap_c * ay
				ax = avg
				ay = ap
				line[p] = ap
				p += 1
				if p == line_n:
					p = 0
				buf[j] += out * e
				e += de
			left -= piece
			idx += piece
			if idx >= n:
				idx -= n


## Candle / ember crackle: sparse, tiny, bright noise pops on the bright bus
## (differentiated noise, so they are clicks without a thump).
func _job_crackle() -> void:
	var buf := _hi
	var n := buf.size()
	var rate := float(MenuThemeData.RATE_HI)
	var count := int(MenuThemeData.CRACKLE_RATE * float(n) / rate)
	var amp_r: Vector2 = MenuThemeData.CRACKLE_AMP
	var len_r: Vector2 = MenuThemeData.CRACKLE_LEN
	for c in count:
		var at := _rng.randi_range(0, n - 1)
		var amp := _rng.randf_range(amp_r.x, amp_r.y)
		# Small pops are common, loud ones rare.
		amp *= _rng.randf() * _rng.randf() + 0.25
		var length := int(_rng.randf_range(len_r.x, len_r.y) * rate)
		var k := exp(-5.0 / float(length))
		var prev := 0.0
		var idx := at
		for j in length:
			var x := _rng.randf() * 2.0 - 1.0
			buf[idx] += (x - prev) * amp
			prev = x
			amp *= k
			idx += 1
			if idx == n:
				idx = 0


## Drone + wind bed over virtual samples [a, b) of the low bus (dry). The
## range starts BED_PRIME before 0 so the wind filters are primed with the
## loop's end (nothing is written for negative indices). Drone frequencies
## are snapped to whole cycles per loop and the noise is read from a table by
## the wrapped sample index, so the bed is exactly periodic. Gains move in
## blocks of BED_BLOCK samples (the priming length and CHUNK_SAMPLES are
## multiples of it, so a block never straddles sample 0).
func _job_bed(a: int, b: int) -> void:
	var buf := _dry
	var n := _n_lo
	var rate := float(MenuThemeData.RATE_LO)
	var loop_s := float(n) / rate
	var band: Vector3 = MenuThemeData.WIND_BAND
	var sw: Vector2 = MenuThemeData.WIND_SWELLS
	var a_lo := 1.0 - exp(-TAU * band.x / rate)
	var a_hi := 1.0 - exp(-TAU * band.y / rate)
	var lp_lo := _wind_lp[0]
	var lp_hi := _wind_lp[1]
	var noise := _noise
	var mask := _noise.size() - 1
	var notes: Array = MenuThemeData.DRONE_NOTES
	var gains: Array = MenuThemeData.DRONE_GAINS
	var bar_gain: Array = MenuThemeData.DRONE_BAR_GAIN
	var bars := bar_gain.size()
	var bar_len := _spb * MenuThemeData.BEATS_PER_BAR
	var dn := notes.size()
	var dc := PackedFloat64Array()
	for d in dn:
		var hz := maxf(1.0, roundf(midi_hz(float(notes[d])) * loop_s)) / loop_s
		var w := TAU * hz / rate
		dc.append(2.0 * cos(w))
		if a <= 0 and b > 0:
			# The drone starts exactly at sample 0 (it needs no priming).
			_drone_y[d * 2] = sin(-w)
			_drone_y[d * 2 + 1] = sin(-2.0 * w)
	var v := a
	while v < b:
		var m := mini(b, v + BED_BLOCK)
		var cnt := m - v
		var wv := posmod(v, n)  # Wrapped index of the block's first sample.
		var wind := band.z * (1.0 - sw.y * (0.5 - 0.5 * cos(TAU * sw.x * float(wv) / float(n))))
		if v < 0:
			# Priming: run the wind filters only.
			for j in cnt:
				var nz := noise[(wv + j) & mask]
				lp_lo += a_lo * (nz - lp_lo)
				lp_hi += a_hi * (nz - lp_hi)
			v = m
			continue
		# Drone gain: smoothstep between bar centres.
		var x := float(wv) / bar_len - 0.5
		var i0 := int(floorf(x))
		var f := x - float(i0)
		f = f * f * (3.0 - 2.0 * f)
		var dgain := lerpf(float(bar_gain[posmod(i0, bars)]), float(bar_gain[posmod(i0 + 1, bars)]), f)
		for d in dn:
			var c := dc[d]
			var y1 := _drone_y[d * 2]
			var y2 := _drone_y[d * 2 + 1]
			var g := float(gains[d]) * dgain
			for j in range(v, m):
				var s := c * y1 - y2
				y2 = y1
				y1 = s
				buf[j] += s * g
			_drone_y[d * 2] = y1
			_drone_y[d * 2 + 1] = y2
		var k := wv
		for j in range(v, m):
			var nz := noise[k & mask]
			k += 1
			lp_lo += a_lo * (nz - lp_lo)
			lp_hi += a_hi * (nz - lp_hi)
			buf[j] += (lp_hi - lp_lo) * wind
		v = m
	_wind_lp[0] = lp_lo
	_wind_lp[1] = lp_hi


## Reverb over virtual samples [a, b) at RATE_LO / 2 (a small dark
## cathedral, mono Schroeder / Freeverb style): the input is the deep bus
## plus the wet bus (pairs averaged) after the pre-delay; four damped combs
## in parallel, then two all-passes in series (exactly 4 and 2: the loop is
## unrolled), all sharing one write index masked to REVERB_LINE. For indices
## >= 0 it adds into the dry bus the wet bus, the deep bus upsampled x2
## (4-tap half-band) and the return (linearly upsampled x2); negative
## indices only prime the state with the loop's end.
func _job_reverb(a: int, b: int) -> void:
	var n := _n_lo
	var half := n / 2
	var rate := float(MenuThemeData.RATE_LO) * 0.5
	var wet := _wet
	var dry := _dry
	var deep := _deep
	var fb := MenuThemeData.REVERB_FEEDBACK
	var damp := MenuThemeData.REVERB_DAMP
	var apf := MenuThemeData.REVERB_ALLPASS_FEEDBACK
	var ret := MenuThemeData.REVERB_WET
	var mask := REVERB_LINE - 1
	var combs: Array = MenuThemeData.REVERB_COMBS
	var aps: Array = MenuThemeData.REVERB_ALLPASSES
	var d0 := int(float(combs[0]) * rate)
	var d1 := int(float(combs[1]) * rate)
	var d2 := int(float(combs[2]) * rate)
	var d3 := int(float(combs[3]) * rate)
	var e0 := int(float(aps[0]) * rate)
	var e1 := int(float(aps[1]) * rate)
	var c0 := _rev_lines[0]
	var c1 := _rev_lines[1]
	var c2 := _rev_lines[2]
	var c3 := _rev_lines[3]
	var a0 := _rev_lines[4]
	var a1 := _rev_lines[5]
	var f0 := _rev_state[0]
	var f1 := _rev_state[1]
	var f2 := _rev_state[2]
	var f3 := _rev_state[3]
	var prev := _rev_state[4]
	var w := int(_rev_state[5])
	# Comb inputs are scaled so the four combs' sum stays near unity gain
	# (x 0.5 for the pair average).
	var in_gain := (1.0 - fb) * 1.5
	var ds := posmod(a - int(MenuThemeData.REVERB_PREDELAY * rate), half)
	# Rolling taps of the deep bus around the first written sample.
	var s0 := maxi(a, 0)
	var dm1 := deep[posmod(s0 - 1, half)]
	var dd0 := deep[s0 % half]
	var dd1 := deep[(s0 + 1) % half]
	for v in range(a, b):
		var x := (deep[ds] + (wet[ds * 2] + wet[ds * 2 + 1]) * 0.5) * in_gain
		ds += 1
		if ds == half:
			ds = 0
		var y := c0[(w - d0) & mask]
		f0 = y + (f0 - y) * damp
		c0[w] = x + f0 * fb
		var sum := y
		y = c1[(w - d1) & mask]
		f1 = y + (f1 - y) * damp
		c1[w] = x + f1 * fb
		sum += y
		y = c2[(w - d2) & mask]
		f2 = y + (f2 - y) * damp
		c2[w] = x + f2 * fb
		sum += y
		y = c3[(w - d3) & mask]
		f3 = y + (f3 - y) * damp
		c3[w] = x + f3 * fb
		sum += y
		var bo := a0[(w - e0) & mask]
		var o := bo - sum
		a0[w] = sum + bo * apf
		bo = a1[(w - e1) & mask]
		var r := bo - o
		a1[w] = o + bo * apf
		w = (w + 1) & mask
		if v >= 0:
			var dd2 := deep[v + 2 - (half if v + 2 >= half else 0)]
			var i := v * 2
			dry[i] += wet[i] + dd0 + (prev + r) * 0.5 * ret
			dry[i + 1] += wet[i + 1] + (9.0 * (dd0 + dd1) - dm1 - dd2) * 0.0625 + r * ret
			dm1 = dd0
			dd0 = dd1
			dd1 = dd2
		prev = r
	_rev_state[0] = f0
	_rev_state[1] = f1
	_rev_state[2] = f2
	_rev_state[3] = f3
	_rev_state[4] = prev
	_rev_state[5] = float(w)


## Upsamples the low bus x2 onto the bright bus over low samples [a, b):
## even output samples take the low sample, odd ones the 4-tap half-band
## midpoint (-x0 + 9x1 + 9x2 - x3) / 16 (wrapping around the loop). Tracks
## the sum / min / max of the final mix.
func _job_mixdown(a: int, b: int) -> void:
	var n := _n_lo
	var lo := _dry
	var hi := _hi
	var sum := _stats[0]
	var mn := _stats[1]
	var mx := _stats[2]
	var xm1 := lo[posmod(a - 1, n)]
	var x0 := lo[a]
	var x1 := lo[posmod(a + 1, n)]
	# The last two samples of the loop read past its end: handled after.
	var stop := mini(b, n - 2)
	var j := a * 2
	for i in range(a, stop):
		var x2 := lo[i + 2]
		var e := hi[j] + x0
		var o := hi[j + 1] + (9.0 * (x0 + x1) - xm1 - x2) * 0.0625
		hi[j] = e
		hi[j + 1] = o
		j += 2
		sum += e + o
		if e < mn:
			mn = e
		elif e > mx:
			mx = e
		if o < mn:
			mn = o
		elif o > mx:
			mx = o
		xm1 = x0
		x0 = x1
		x1 = x2
	for i in range(maxi(a, stop), b):
		var x2 := lo[(i + 2) % n]
		var e := hi[i * 2] + x0
		var o := hi[i * 2 + 1] + (9.0 * (x0 + x1) - xm1 - x2) * 0.0625
		hi[i * 2] = e
		hi[i * 2 + 1] = o
		sum += e + o
		mn = minf(mn, minf(e, o))
		mx = maxf(mx, maxf(e, o))
		xm1 = x0
		x0 = x1
		x1 = x2
	_stats[0] = sum
	_stats[1] = mn
	_stats[2] = mx


## Encodes final samples [a, b) to 16-bit PCM: mean removed (no DC offset),
## normalised so the peak is MenuThemeData.PEAK.
func _job_encode(a: int, b: int) -> void:
	if a == 0:
		_bytes.resize(_n_hi * 2)
	var hi := _hi
	var bytes := _bytes
	var mean := _stats[0] / float(_n_hi)
	var peak := maxf(0.0001, maxf(_stats[2] - mean, mean - _stats[1]))
	var gain := MenuThemeData.PEAK / peak * 32767.0
	var off := -mean * gain
	for i in range(a, b):
		bytes.encode_s16(i * 2, int(hi[i] * gain + off))


## Wraps the PCM into the looping stream and frees the work buffers.
func _job_finish() -> void:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MenuThemeData.RATE_HI
	s.stereo = false
	s.data = _bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = _n_hi
	stream = s
	_hi = PackedFloat32Array()
	_wet = PackedFloat32Array()
	_dry = PackedFloat32Array()
	_deep = PackedFloat32Array()
	_bytes = PackedByteArray()
	_noise = PackedFloat32Array()
	_tables.clear()
	_rev_lines.clear()


# =====================================================================================
# Wavetables
# =====================================================================================

## The single-cycle table of `kind` ("pad" = "ooh" formants, "choir" =
## "aah" formants, "bass" = BASS_HARMONICS) for MIDI `note` played at sample
## rate `rate` (harmonics stop below 0.45 x rate), built once.
## Formant tables are made per note, so the vowel stays put across pitches.
func _table(kind: String, note: int, rate: float) -> PackedFloat32Array:
	var key := "%s:%d:%d" % [kind, note, int(rate)]
	if _tables.has(key):
		return _tables[key]
	var hz := midi_hz(float(note))
	var k_max := mini(MenuThemeData.TABLE_MAX_HARMONICS, int(0.45 * rate / hz))
	var amps := PackedFloat64Array()
	if kind == "bass":
		var hs: Array = MenuThemeData.BASS_HARMONICS
		for k in mini(k_max, hs.size()):
			amps.append(float(hs[k]))
	else:
		var fm: Array = MenuThemeData.PAD_FORMANTS if kind == "pad" else MenuThemeData.CHOIR_FORMANTS
		for k in range(1, k_max + 1):
			var f := hz * float(k)
			var a := 0.03
			for fr: Array in fm:
				var d := (f - float(fr[0])) / (float(fr[1]) * 0.5)
				a += float(fr[2]) / (1.0 + d * d)
			# Glottal source tilt: the upper harmonics fall off.
			amps.append(a / pow(float(k), 0.8))
	var ts := MenuThemeData.TABLE_SIZE
	var tbl := PackedFloat32Array()
	tbl.resize(ts)
	var peak := 0.0001
	var kn := amps.size()
	for i in ts:
		# sin(k x) for every k by the Chebyshev recursion (one sin per sample).
		var x := TAU * float(i) / float(ts)
		var c := 2.0 * cos(x)
		var s_prev := 0.0
		var s := sin(x)
		var acc := 0.0
		for k in kn:
			acc += amps[k] * s
			var s_next := c * s - s_prev
			s_prev = s
			s = s_next
		tbl[i] = acc
		peak = maxf(peak, absf(acc))
	for i in ts:
		tbl[i] /= peak
	_tables[key] = tbl
	return tbl
