## Synth — a tiny offline synthesizer. It renders the SoundData recipes and
## the ambient music drone into 16-bit mono AudioStreamWAV resources, so the
## game ships with no audio files at all (GDD §12 Audio).
##
## Every function is static and touches only its own buffers and its own
## seeded RandomNumberGenerator, so Sfx can run them on WorkerThreadPool
## threads and the result is identical on every run. The global RNG (which
## the autotest seeds for gameplay) is never used. The pieces of a render
## (sound_buffer(), add_layer() per layer, peak_of() / encode_range() /
## pcm_stream() for to_stream(); RunLoopSynth for the music loop) are public
## so the Web build (StartupSynth) can run them in per-frame steps with
## bit-identical results.
##
## A layer is an oscillator (sine / triangle / saw / square / white noise)
## with an exponential pitch sweep, linear attack, exponential decay, an
## optional vibrato and an optional one-pole low-pass sweep. Layers are mixed
## into a float buffer, normalised to PEAK and converted to 16-bit PCM.
class_name Synth
extends RefCounted

## Output sample rate for sound effects (Hz).
const SFX_RATE: int = 22050  # TUNING (not in GDD)
## Output sample rate for the music loop (Hz). The drone, pad and wind are
## all low frequencies, so a low rate cuts generation cost at no audible loss.
const MUSIC_RATE: int = 8000  # TUNING (not in GDD)
## Peak level every rendered sound is normalised to (0..1 of full scale).
const PEAK: float = 0.89  # TUNING (not in GDD)
## Fade-out at the end of every layer (s) so cut-off layers never click.
const TAIL_FADE: float = 0.006  # TUNING (not in GDD)
## Wave name -> internal id (ints are cheaper to branch on per sample).
const WAVES: Dictionary = {"sine": 0, "tri": 1, "saw": 2, "square": 3, "noise": 4}
## Starting value of a peak search (peak_of()): a silent buffer is never
## divided by zero.
const PEAK_FLOOR: float = 0.0001


## Renders one SoundData recipe to a (non-looping) stream.
static func render_sound(recipe: Dictionary, rng_seed: int) -> AudioStreamWAV:
	var buf := sound_buffer(recipe)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for layer: Dictionary in recipe["layers"]:
		add_layer(buf, SFX_RATE, layer, rng)
	return to_stream(buf, SFX_RATE, false)


## The silent SFX_RATE buffer a recipe's layers are mixed into (its "dur").
static func sound_buffer(recipe: Dictionary) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(maxi(1, int(float(recipe["dur"]) * SFX_RATE)))
	return buf


## Mixes one layer (keys documented in SoundData) into `buf`.
static func add_layer(buf: PackedFloat32Array, rate: int, l: Dictionary, rng: RandomNumberGenerator) -> void:
	var start := int(float(l.get("start", 0.0)) * rate)
	var n := mini(int(float(l["dur"]) * rate), buf.size() - start)
	if n <= 0:
		return
	var wave: int = WAVES.get(String(l.get("wave", "sine")), 0)
	var inv_rate := 1.0 / float(rate)
	var f := float(l.get("f0", 440.0))
	var f_mul := pow(float(l.get("f1", f)) / f, 1.0 / float(n))
	var amp := float(l.get("amp", 0.5))
	var attack_n := maxf(1.0, float(l.get("attack", 0.003)) * rate)
	var decay := float(l.get("decay", 0.0))
	var env_mul := exp(-inv_rate / decay) if decay > 0.0 else 1.0
	var fade_start := n - int(TAIL_FADE * rate)
	var inv_fade := 1.0 / maxf(1.0, float(n - fade_start))
	# One-pole low-pass. The coefficient ~ 2*pi*fc/rate (fine for fc << rate)
	# sweeps exponentially; at >= 1 the filter is fully open and skipped.
	var lp := float(l.get("lp0", 0.0))
	var use_lp := lp > 0.0
	var lp_a := TAU * lp * inv_rate
	var lp_mul := pow(float(l.get("lp1", lp)) / lp, 1.0 / float(n)) if use_lp else 1.0
	var vib_step := TAU * float(l.get("vib_hz", 0.0)) * inv_rate
	var vib_depth := float(l.get("vib_depth", 0.0))
	var use_vib := vib_depth > 0.0
	# Phase increment per sample (cycles); swept by f_mul like the frequency.
	var step := f * inv_rate
	var phase := 0.0
	var vib_phase := 0.0
	var env := amp
	var y := 0.0
	var idx := start
	for i in n:
		var s: float
		if wave == 0:
			s = sin(TAU * phase)
		elif wave == 1:
			s = 1.0 - 4.0 * absf(phase - 0.5)
		elif wave == 2:
			s = 2.0 * phase - 1.0
		elif wave == 3:
			s = 1.0 if phase < 0.5 else -1.0
		else:
			s = rng.randf() * 2.0 - 1.0
		if use_lp:
			if lp_a < 1.0:
				y += lp_a * (s - y)
				s = y
			lp_a *= lp_mul
		s *= env
		if i < attack_n:
			s *= float(i) / attack_n
		elif i >= fade_start:
			s *= float(n - i) * inv_fade
		buf[idx] += s
		idx += 1
		env *= env_mul
		if use_vib:
			phase += step * (1.0 + vib_depth * sin(vib_phase))
			vib_phase += vib_step
		else:
			phase += step
		if phase >= 1.0:
			phase -= floorf(phase)
		step *= f_mul


## Normalises `buf` to PEAK and packs it into a 16-bit mono AudioStreamWAV.
## `loop` makes it a seamless forward loop over the whole buffer.
static func to_stream(buf: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var n := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	encode_range(bytes, buf, peak_gain(peak_of(buf, 0, n, PEAK_FLOOR)), 0, n)
	return pcm_stream(bytes, rate, loop)


## Largest absolute sample of buf[from, to), at least `peak` (start with
## PEAK_FLOOR; chain calls over consecutive ranges for the whole buffer).
static func peak_of(buf: PackedFloat32Array, from: int, to: int, peak: float) -> float:
	for i in range(from, to):
		peak = maxf(peak, absf(buf[i]))
	return peak


## Sample-to-PCM gain that normalises a buffer whose peak is `peak` to PEAK.
static func peak_gain(peak: float) -> float:
	return PEAK / peak * 32767.0


## Writes buf[from, to) scaled by `gain` as 16-bit samples into `bytes`
## (sized 2 bytes per sample).
static func encode_range(bytes: PackedByteArray, buf: PackedFloat32Array, gain: float, from: int, to: int) -> void:
	for i in range(from, to):
		bytes.encode_s16(i * 2, int(buf[i] * gain))


## Wraps 16-bit mono PCM `bytes` at `rate` Hz in an AudioStreamWAV; `loop`
## makes it a forward loop over the whole buffer.
static func pcm_stream(bytes: PackedByteArray, rate: int, loop: bool) -> AudioStreamWAV:
	var n := bytes.size() / 2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = n
	return stream


## Snaps `hz` to a whole number of cycles per `loop_s` seconds so a looping
## oscillator ends exactly where it started.
static func snap(hz: float, loop_s: float) -> float:
	return maxf(1.0, roundf(hz * loop_s)) / loop_s


## Renders the dark, minor-key ambient loop (GDD §12 "ominous choirs, low
## percussion and ambient drones") in one go: see RunLoopSynth, which holds
## the recipe as a list of small jobs (the Web build runs them over frames).
static func render_music(rng_seed: int) -> AudioStreamWAV:
	return RunLoopSynth.new(rng_seed).render_all()
