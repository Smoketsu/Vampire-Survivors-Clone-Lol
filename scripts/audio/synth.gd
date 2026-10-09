## Synth — a tiny offline synthesizer. It renders the SoundData recipes and
## the ambient music drone into 16-bit mono AudioStreamWAV resources, so the
## game ships with no audio files at all (GDD §12 Audio).
##
## Every function is static and touches only its own buffers and its own
## seeded RandomNumberGenerator, so Sfx can run them on WorkerThreadPool
## threads and the result is identical on every run. The global RNG (which
## the autotest seeds for gameplay) is never used.
##
## A layer is an oscillator (sine / triangle / saw / square / white noise)
## with an exponential pitch sweep, linear attack, exponential decay, an
## optional vibrato and an optional one-pole low-pass sweep. Layers are mixed
## into a float buffer, normalised to PEAK and converted to 16-bit PCM.
class_name Synth
extends RefCounted

## Output sample rate for sound effects (Hz).
const SFX_RATE: int = 22050  # TUNING (not in GDD)
## Output sample rate for the music loop (Hz). The drone is all low
## frequencies, so half rate halves the generation cost at no audible loss.
const MUSIC_RATE: int = 11025  # TUNING (not in GDD)
## Peak level every rendered sound is normalised to (0..1 of full scale).
const PEAK: float = 0.89  # TUNING (not in GDD)
## Fade-out at the end of every layer (s) so cut-off layers never click.
const TAIL_FADE: float = 0.006  # TUNING (not in GDD)
## Wave name -> internal id (ints are cheaper to branch on per sample).
const WAVES: Dictionary = {"sine": 0, "tri": 1, "saw": 2, "square": 3, "noise": 4}


## Renders one SoundData recipe to a (non-looping) stream.
static func render_sound(recipe: Dictionary, rng_seed: int) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	buf.resize(maxi(1, int(float(recipe["dur"]) * SFX_RATE)))
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for layer: Dictionary in recipe["layers"]:
		add_layer(buf, SFX_RATE, layer, rng)
	return to_stream(buf, SFX_RATE, false)


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
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := PEAK / peak * 32767.0
	var n := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(buf[i] * gain))
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
## percussion and ambient drones"): a beating D drone, a slow wind bed, a
## four-chord "choir" pad crossfading around the loop (SoundData.MUSIC_CHORDS)
## and a soft heartbeat thump. Every oscillator and LFO completes a whole
## number of cycles per loop, so the loop point is seamless.
static func render_music(rng_seed: int) -> AudioStreamWAV:
	var rate := MUSIC_RATE
	var loop_s := SoundData.MUSIC_LOOP_SECONDS
	var n := int(loop_s * rate)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var inv_rate := 1.0 / float(rate)
	# --- Drone (two slightly detuned low-passed saws + sub sine) and wind.
	var f1 := snap(SoundData.MUSIC_ROOT_HZ, loop_s)
	var f2 := snap(SoundData.MUSIC_ROOT_HZ * 1.006, loop_s)
	var f_sub := snap(SoundData.MUSIC_ROOT_HZ * 0.5, loop_s)
	var lfo := TAU * 2.0 / loop_s  # wind swells twice per loop
	# The filters start `warm` samples before 0 (with matching phases, since
	# every frequency loops) so their state at sample 0 equals the state at
	# the loop end: no click at the loop point.
	var warm := rate / 10
	var p1 := fposmod(-f1 * warm * inv_rate, 1.0)
	var p2 := fposmod(-f2 * warm * inv_rate, 1.0)
	var p3 := fposmod(-f_sub * warm * inv_rate, 1.0)
	var y_drone := 0.0
	var y_wind := 0.0
	for i in range(-warm, n):
		var t := float(i) * inv_rate
		var saw := (2.0 * p1 - 1.0) + (2.0 * p2 - 1.0)
		y_drone += 0.035 * (saw - y_drone)
		var wind_amp := 0.05 + 0.04 * sin(lfo * t)
		y_wind += 0.08 * (rng.randf() * 2.0 - 1.0 - y_wind)
		if i >= 0:
			buf[i] = y_drone * 0.32 + sin(TAU * p3) * 0.22 + y_wind * wind_amp * 3.0
		p1 += f1 * inv_rate
		p1 -= floorf(p1)
		p2 += f2 * inv_rate
		p2 -= floorf(p2)
		p3 += f_sub * inv_rate
		p3 -= floorf(p3)
	# --- Choir pad: each chord fades in/out over its segment plus overlap,
	# wrapping around the loop end so the last chord crossfades into the first.
	var chords: Array = SoundData.MUSIC_CHORDS
	var seg := n / chords.size()
	var overlap := seg / 4
	var win := seg + 2 * overlap
	var vib := TAU * snap(5.0, loop_s) * inv_rate
	for c in chords.size():
		var voices: Array = chords[c]
		var freqs := PackedFloat32Array()
		var phases := PackedFloat32Array()
		for hz: float in voices:
			freqs.append(snap(hz, loop_s) * inv_rate)
			phases.append(0.0)
		var first := c * seg - overlap
		var vib_phase := 0.0
		for j in win:
			var w := sin(PI * float(j) / float(win))
			w *= w
			var s := 0.0
			var wob := 1.0 + 0.004 * sin(vib_phase)
			for v in freqs.size():
				var ph := phases[v]
				s += 1.0 - 4.0 * absf(ph - 0.5)
				ph += freqs[v] * wob * (1.0 + 0.0015 * float(v))
				phases[v] = ph - floorf(ph)
			vib_phase += vib
			var idx := posmod(first + j, n)
			buf[idx] += s * w * 0.11
	# --- Heartbeat: "lub-dub" low thumps every MUSIC_BEAT_SECONDS.
	var beats := int(loop_s / SoundData.MUSIC_BEAT_SECONDS)
	for b in beats:
		for k in 2:
			var at := b * SoundData.MUSIC_BEAT_SECONDS + 0.28 * float(k)
			add_layer(buf, rate, {"wave": "sine", "f0": 58.0, "f1": 36.0, "start": at, "dur": 0.35,
				"amp": 0.5 if k == 0 else 0.32, "attack": 0.004, "decay": 0.09}, rng)
	return to_stream(buf, rate, true)
