## MenuThemeData — DESIGNER-TUNABLE score and mix of the main menu theme,
## "Grave Lullaby": a slow D-minor piece that plays on the main menu and every
## screen opened from it (stage select, pre-run setup, Ossuary, settings,
## Codex, Credits) and crossfades with the in-run loop (SoundData) when a run
## starts or ends. Like every sound in the game it is synthesized at startup
## (MenuThemeSynth renders this score; Sfx plays it): there is no audio file.
## The GDD only asks for "ominous choirs, low percussion and ambient drones"
## (§12), so every number here is `# TUNING (not in GDD)`. No logic here.
##
## Form: 16 bars of 4/4 at BPM, one loop of 16 * 4 * 60 / BPM = 51.2 s.
##   A (bars 1-8):  the music-box motif over a choir pad, i–VI–III–VII then
##                  i–VI–iv–V (Dm Bb F C | Dm Bb Gm A); a lute-like harp
##                  joins in bar 5.
##   B (bars 9-16): a sung "aah" lead over flowing harp arpeggios,
##                  iv–i–VI–III–iv–bII–V (Gm Dm Bb F Gm Eb Asus4-A A); the
##                  Neapolitan Eb is the gothic colour, the long A pulls back
##                  to the top through a timpani roll.
## A deep church bell tolls each 4-bar phrase, soft timpani mark the phrase
## starts and cadences, and a quiet wind / candle-crackle bed runs throughout.
##
## Units: times are in BEATS from the top of the loop (0 = bar 1, beat 1;
## 4 = bar 2 ...), pitches are MIDI note numbers (60 = C4, 62 = D4, 69 = A4 =
## 440 Hz), velocities / gains are linear amplitudes (about 0..1).
class_name MenuThemeData
extends RefCounted

# --- Rendering ---------------------------------------------------------------

## Sample rate (Hz) of the bright layers (the music box's short high
## partials, candle crackle) and of the final stream. The mixdown upsamples
## the lower buses to it.
const RATE_HI: int = 22050  # TUNING (not in GDD)
## Sample rate (Hz) of the mid layers (sung lead, harp, drone, wind). Must
## be exactly RATE_HI / 2. The low layers (pad, pedal organ, bell, timpani,
## the music box's body and echoes) and the reverb run at RATE_LO / 2: most
## of the cost is there, at a quarter of the samples, and none of them needs
## highs above about 2.5 kHz.
const RATE_LO: int = 11025  # TUNING (not in GDD)
## Tempo (beats per minute). 75 makes one beat exactly 8820 samples at RATE_LO.
const BPM: float = 75.0  # TUNING (not in GDD)
## Beats per bar (4/4).
const BEATS_PER_BAR: int = 4  # TUNING (not in GDD)
## Bars in the loop (A + B sections).
const BARS: int = 16  # TUNING (not in GDD)
## Seed of the theme's own RandomNumberGenerator (harp excitations, crackle
## times). Never the seeded gameplay RNG.
const SEED: int = 7331  # TUNING (not in GDD)
## Peak level the finished loop is normalised to (0..1 of full scale;
## 0.88 = -1.1 dBFS).
const PEAK: float = 0.88  # TUNING (not in GDD)
## Samples (at the rate of the pass) handled by one chunk of the long
## whole-loop passes (bed, reverb, mixdown, encode), so incremental rendering
## can stop between chunks. Notes are always rendered whole (a few ms each).
const CHUNK_SAMPLES: int = 8192  # TUNING (not in GDD)
## Per-frame time budget (ms) when the theme renders on the main thread in
## small steps (the Web build, where worker threads may be unavailable).
## Desktop builds render it on a worker thread in one go.
const WEB_FRAME_BUDGET_MS: float = 4.0  # TUNING (not in GDD)
## Single-cycle wavetable length (samples) of the pad, bass and choir
## voices. Must be a power of two (the phase is masked).
const TABLE_SIZE: int = 2048  # TUNING (not in GDD)
## Most harmonics a wavetable holds (fewer when they would pass 0.45 x the
## voice's sample rate, so nothing aliases).
const TABLE_MAX_HARMONICS: int = 24  # TUNING (not in GDD)

# --- Playback (Sfx) ----------------------------------------------------------

## Volume (dB) of the menu-theme player on the Music bus. Chosen so the theme
## is about as loud (integrated LUFS) as the in-run loop at Sfx.MUSIC_DB:
## measured -15.2 LUFS (menu loop) and -16.5 LUFS (in-run loop) at full
## scale, so -15.2 - 9.5 = -24.7 vs -16.5 - 8 = -24.5 LUFS in game.
const MUSIC_DB: float = -9.5  # TUNING (not in GDD)
## Seconds the menu theme takes to fade in (first start, and after a run).
const FADE_IN: float = 2.0  # TUNING (not in GDD)
## Seconds the menu theme takes to fade out when a run starts (it crossfades
## with the in-run loop through the fade to black).
const FADE_OUT: float = 1.2  # TUNING (not in GDD)
## Seconds the in-run loop takes to fade out when returning to the menu.
const RUN_FADE_OUT: float = 1.0  # TUNING (not in GDD)

# --- Harmony -----------------------------------------------------------------

## The chord track, voice-led: [start beat, length in beats, [3 upper voices
## (MIDI, low to high)], bass note (MIDI)]. The pad sings the upper voices,
## the pedal organ the bass, the harp arpeggiates both.
const CHORDS: Array = [  # TUNING (not in GDD)
	# A: i - VI - III - VII | i - VI - iv - V
	[0.0, 4.0, [57, 62, 65], 38],    # Dm   (A3 D4 F4 / D2)
	[4.0, 4.0, [58, 62, 65], 34],    # Bb   (Bb3 D4 F4 / Bb1)
	[8.0, 4.0, [57, 60, 65], 41],    # F    (A3 C4 F4 / F2)
	[12.0, 4.0, [55, 60, 64], 36],   # C    (G3 C4 E4 / C2)
	[16.0, 4.0, [57, 62, 65], 38],   # Dm
	[20.0, 4.0, [58, 62, 65], 34],   # Bb
	[24.0, 4.0, [58, 62, 67], 43],   # Gm   (Bb3 D4 G4 / G2)
	[28.0, 4.0, [57, 61, 64], 45],   # A    (A3 C#4 E4 / A2)
	# B: iv - i6 - VI - III | iv - bII - V(sus4) - V
	[32.0, 4.0, [55, 58, 62], 43],   # Gm   (G3 Bb3 D4 / G2)
	[36.0, 4.0, [53, 57, 62], 41],   # Dm/F (F3 A3 D4 / F2)
	[40.0, 4.0, [53, 58, 62], 34],   # Bb   (F3 Bb3 D4 / Bb1)
	[44.0, 4.0, [53, 57, 60], 41],   # F    (F3 A3 C4 / F2)
	[48.0, 4.0, [55, 58, 62], 43],   # Gm
	[52.0, 4.0, [55, 58, 63], 39],   # Eb   (G3 Bb3 Eb4 / Eb2), Neapolitan
	[56.0, 2.0, [57, 62, 64], 45],   # Asus4 (A3 D4 E4 / A2)
	[58.0, 6.0, [57, 61, 64], 45],   # A    (A3 C#4 E4 / A2) back to the top
]
## Dynamics: a gain per bar (1..16) for the pad, bass, harp and choir, so
## the loop breathes: quiet opening, growing through B, a peak on the
## Neapolitan Eb (bar 14), relaxing into the turnaround.
const BAR_DYNAMICS: Array = [  # TUNING (not in GDD)
	0.72, 0.74, 0.78, 0.8, 0.84, 0.88, 0.94, 0.9,
	0.94, 0.98, 1.0, 1.0, 1.05, 1.12, 0.96, 0.82,
]

# --- Choir pad ("ooh") and pedal organ -----------------------------------------

## Overall pad level (per voice, before BAR_DYNAMICS).
const PAD_GAIN: float = 0.075  # TUNING (not in GDD)
## Beats of raised-cosine crossfade between consecutive chords (each chord
## starts fading in this long before its downbeat, half before, half after).
const PAD_XFADE_BEATS: float = 1.25  # TUNING (not in GDD)
## Level (0..1, relative to the first) of the second "singer" on each pad
## voice: the ensemble. 0 = one clean voice.
const PAD_SECOND_SINGER: float = 0.18  # TUNING (not in GDD)
## Largest detune (cents) of the pad's second singer; it drifts slowly
## between 0 and this, so the beating never settles into a steady tremolo.
const PAD_DETUNE_CENTS: float = 6.0  # TUNING (not in GDD)
## Rate (Hz) of that slow detune drift (pad and choir; each voice runs up to
## 30% faster so they never drift together).
const ENSEMBLE_DRIFT_HZ: float = 0.11  # TUNING (not in GDD)
## Pad vibrato rate (Hz) and depth (fraction of the pitch).
const PAD_VIBRATO: Vector2 = Vector2(4.4, 0.0022)  # TUNING (not in GDD)
## "Ooh" vowel of the pad: formants as [centre Hz, bandwidth Hz, gain].
const PAD_FORMANTS: Array = [[330.0, 140.0, 1.0], [780.0, 180.0, 0.42], [2400.0, 320.0, 0.08]]  # TUNING (not in GDD)
## Pedal organ (bass) level.
const BASS_GAIN: float = 0.075  # TUNING (not in GDD)
## Pedal organ harmonic amplitudes (1st, 2nd, ...): a soft flue pipe.
const BASS_HARMONICS: Array = [1.0, 0.42, 0.16, 0.08, 0.04]  # TUNING (not in GDD)
## Beats of crossfade between bass notes (like PAD_XFADE_BEATS).
const BASS_XFADE_BEATS: float = 1.0  # TUNING (not in GDD)

# --- Drone and atmosphere ---------------------------------------------------------

## Drone notes (MIDI) held through the whole loop: low D and its octave,
## felt more than heard. Their frequencies are snapped to whole cycles per
## loop so the loop point is seamless.
const DRONE_NOTES: Array = [26, 38]  # TUNING (not in GDD)
## Drone amplitude per note (same order as DRONE_NOTES).
const DRONE_GAINS: Array = [0.028, 0.026]  # TUNING (not in GDD)
## Drone gain per bar (1..16): it ducks under the Eb chord (bar 14) where a
## D pedal would clash, and under the Gm / A of the B section's end.
const DRONE_BAR_GAIN: Array = [  # TUNING (not in GDD)
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.85, 0.8,
	0.9, 1.0, 1.0, 1.0, 0.8, 0.25, 0.55, 0.8,
]
## Wind bed: [low cut Hz, high cut Hz, gain] of the band-passed noise.
const WIND_BAND: Vector3 = Vector3(160.0, 620.0, 0.11)  # TUNING (not in GDD)
## Wind swells per loop (a whole number keeps the loop seamless) and the
## depth of the swell (0 = steady, 1 = fully silent at its lowest).
const WIND_SWELLS: Vector2 = Vector2(3.0, 0.7)  # TUNING (not in GDD)
## Candle / ember crackle: mean pops per second.
const CRACKLE_RATE: float = 3.5  # TUNING (not in GDD)
## Crackle pop amplitude range (linear).
const CRACKLE_AMP: Vector2 = Vector2(0.015, 0.07)  # TUNING (not in GDD)
## Crackle pop length range (seconds).
const CRACKLE_LEN: Vector2 = Vector2(0.002, 0.007)  # TUNING (not in GDD)

# --- Bell and timpani ----------------------------------------------------------------

## Church bell tolls: [beat, prime note (MIDI), velocity]; one per 4-bar phrase.
const BELL_TOLLS: Array = [[0.0, 50, 1.0], [16.0, 50, 0.72], [32.0, 50, 0.9], [48.0, 50, 0.72]]  # TUNING (not in GDD)
## Bell partials: [ratio to the prime, amplitude, decay time constant (s)]:
## hum (with a slow beating pair), prime, minor-third tierce, quint, nominal
## and two upper partials, slightly stretched like a real cast bell.
const BELL_PARTIALS: Array = [  # TUNING (not in GDD)
	[0.5, 0.5, 3.2], [0.503, 0.32, 3.0], [1.0, 0.55, 2.2], [1.19, 0.42, 1.8],
	[1.5, 0.22, 1.2], [2.0, 0.34, 1.4], [2.51, 0.12, 0.7], [3.02, 0.08, 0.45],
]
## Bell master level.
const BELL_GAIN: float = 0.13  # TUNING (not in GDD)
## Timpani hits: [beat, note (MIDI), velocity]: phrase starts and cadences,
## tuned to D and A like a classical pair.
const TIMPANI_HITS: Array = [  # TUNING (not in GDD)
	[0.0, 38, 0.8], [16.0, 38, 0.5], [28.0, 33, 0.55], [30.0, 33, 0.42],
	[32.0, 38, 0.65], [48.0, 38, 0.55], [52.0, 39, 0.5], [56.0, 33, 0.6],
]
## Timpani roll into the top of the loop: [start beat, end beat, note,
## start velocity, end velocity, strokes per beat].
const TIMPANI_ROLL: Array = [62.0, 64.0, 33, 0.06, 0.4, 6.0]  # TUNING (not in GDD)
## Decay-time multiplier of the roll's strokes (they are short and
## overlapping, so they need less ring).
const TIMPANI_ROLL_DECAY: float = 0.5  # TUNING (not in GDD)
## Timpani modes: [ratio, amplitude, decay time constant (s)].
const TIMPANI_MODES: Array = [[1.0, 1.0, 0.9], [1.5, 0.45, 0.55], [1.98, 0.28, 0.4], [2.44, 0.14, 0.28]]  # TUNING (not in GDD)
## Timpani master level.
const TIMPANI_GAIN: float = 0.15  # TUNING (not in GDD)

# --- Music-box melody (section A): the motif ---------------------------------------

## The melody, [beat, note (MIDI), length in beats, velocity]. Bars 1-4 are
## the motif ("q q q. e | q. e h" twice, a third apart), reusable as the
## game's signature phrase; bars 5-8 climb to Bb5 and fall to a half cadence.
const MELODY: Array = [  # TUNING (not in GDD)
	[0.0, 69, 1.0, 0.8], [1.0, 74, 1.0, 0.85], [2.0, 77, 1.5, 0.95], [3.5, 76, 0.5, 0.7],
	[4.0, 74, 1.5, 0.85], [5.5, 72, 0.5, 0.7], [6.0, 70, 2.0, 0.8],
	[8.0, 69, 1.0, 0.8], [9.0, 72, 1.0, 0.85], [10.0, 77, 1.5, 0.95], [11.5, 76, 0.5, 0.7],
	[12.0, 76, 1.5, 0.85], [13.5, 74, 0.5, 0.7], [14.0, 72, 2.0, 0.8],
	[16.0, 69, 1.0, 0.85], [17.0, 74, 1.0, 0.9], [18.0, 77, 1.0, 0.95], [19.0, 81, 1.0, 1.0],
	[20.0, 82, 1.5, 1.0], [21.5, 81, 0.5, 0.8], [22.0, 77, 2.0, 0.9],
	[24.0, 79, 1.0, 0.9], [25.0, 77, 1.0, 0.85], [26.0, 76, 1.0, 0.85], [27.0, 74, 1.0, 0.8],
	[28.0, 73, 1.5, 0.85], [29.5, 76, 0.5, 0.7], [30.0, 69, 2.0, 0.8],
]
## Music-box partials: [ratio, amplitude, decay time constant (s), bus]:
## a sine-like tine with a fast-fading octave and short inharmonic "ping"
## partials. Bus 0 = the RATE_LO / 2 bus through the reverb (the long, low
## partials, cheap), 1 = the bright RATE_HI bus (the short high partials that
## give the sparkle).
const MUSIC_BOX_PARTIALS: Array = [  # TUNING (not in GDD)
	[1.0, 1.0, 0.75, 0], [2.0, 0.3, 0.3, 0], [3.0, 0.12, 0.14, 1],
	[4.17, 0.11, 0.07, 1], [5.43, 0.07, 0.04, 1], [8.93, 0.035, 0.02, 1],
]
## Music-box master level.
const MUSIC_BOX_GAIN: float = 0.24  # TUNING (not in GDD)
## Tempo-synced echo of the music box: [delay in beats, level, decay time
## constant (s)] per repeat. The repeats are darker (fundamental only, on the
## RATE_LO / 2 bus) and shorter, like a damped delay line.
const MUSIC_BOX_ECHOES: Array = [[0.75, 0.38, 0.45], [1.5, 0.14, 0.4]]  # TUNING (not in GDD)

# --- Choir lead (section B) and harp ---------------------------------------------

## The sung "aah" lead of section B, [beat, note, length in beats, velocity].
## It opens with the motif's "q. e h" rhythm and peaks on the Neapolitan
## G5 - Eb5, then a suspension D5 -> C#5 over the dominant.
const CHOIR_LEAD: Array = [  # TUNING (not in GDD)
	[32.0, 70, 1.5, 0.8], [33.5, 72, 0.5, 0.7], [34.0, 74, 2.0, 0.9],
	[36.0, 77, 1.5, 0.95], [37.5, 76, 0.5, 0.75], [38.0, 74, 2.0, 0.85],
	[40.0, 74, 1.0, 0.85], [41.0, 72, 1.0, 0.8], [42.0, 70, 1.0, 0.8], [43.0, 74, 1.0, 0.85],
	[44.0, 72, 3.0, 0.85], [47.0, 69, 1.0, 0.75],
	[48.0, 70, 1.5, 0.85], [49.5, 72, 0.5, 0.75], [50.0, 74, 1.0, 0.9], [51.0, 79, 1.0, 1.0],
	[52.0, 79, 1.5, 1.0], [53.5, 77, 0.5, 0.85], [54.0, 75, 2.0, 0.95],
	[56.0, 74, 2.0, 0.9], [58.0, 73, 2.0, 0.85],
	[60.0, 76, 2.0, 0.7], [62.0, 73, 2.0, 0.6],
]
## "Aah" vowel of the lead: formants as [centre Hz, bandwidth Hz, gain].
const CHOIR_FORMANTS: Array = [[760.0, 130.0, 1.0], [1150.0, 160.0, 0.6], [2700.0, 260.0, 0.22]]  # TUNING (not in GDD)
## Choir lead level.
const CHOIR_GAIN: float = 0.22  # TUNING (not in GDD)
## Choir attack and release (seconds); the release overlaps the next note.
const CHOIR_ENVELOPE: Vector2 = Vector2(0.16, 0.4)  # TUNING (not in GDD)
## Choir vibrato: [rate Hz, depth (fraction of the pitch), onset delay s].
const CHOIR_VIBRATO: Vector3 = Vector3(5.1, 0.0045, 0.35)  # TUNING (not in GDD)
## Level (0..1) of the lead's second singer (see PAD_SECOND_SINGER).
const CHOIR_SECOND_SINGER: float = 0.3  # TUNING (not in GDD)
## Largest detune (cents) of the lead's drifting second singer.
const CHOIR_DETUNE_CENTS: float = 7.0  # TUNING (not in GDD)
## Harp phrases: [first bar, last bar (exclusive; 1-based bars), step in
## beats, pattern, velocity]. A pattern indexes the chord's harp tones:
## 0 = bass up an octave, 1-3 = the three pad voices, 4 = the lowest pad
## voice up an octave.
const HARP_PHRASES: Array = [  # TUNING (not in GDD)
	[5, 9, 1.0, [0, 1, 2, 3], 0.42],
	[9, 15, 0.5, [0, 1, 2, 3, 4, 3, 2, 1], 0.5],
	[15, 17, 1.0, [0, 2, 4, 2], 0.36],
]
## Harp level.
const HARP_GAIN: float = 0.5  # TUNING (not in GDD)
## Harp string: [loop loss per period (0..1, higher = longer ring),
## brightness of the pluck (0..1), seconds rendered per note].
const HARP_STRING: Vector3 = Vector3(0.9975, 0.45, 1.8)  # TUNING (not in GDD)

# --- Reverb (a small dark cathedral, mono Schroeder / Freeverb style) -----------
# It runs at RATE_LO / 2 (a dark tail needs no highs; half the cost).

## Comb delays in seconds (about 50-62 ms, not multiples of each other).
const REVERB_COMBS: Array = [0.0505, 0.0538, 0.0581, 0.0619]  # TUNING (not in GDD)
## Comb feedback (0..1): reverb time, about 2.3 s.
const REVERB_FEEDBACK: float = 0.85  # TUNING (not in GDD)
## Comb damping (0..1): how fast the highs die in the tail.
const REVERB_DAMP: float = 0.38  # TUNING (not in GDD)
## All-pass diffuser delays in seconds.
const REVERB_ALLPASSES: Array = [0.0164, 0.0126]  # TUNING (not in GDD)
## All-pass feedback.
const REVERB_ALLPASS_FEEDBACK: float = 0.5  # TUNING (not in GDD)
## Pre-delay (seconds) before the reverb starts.
const REVERB_PREDELAY: float = 0.03  # TUNING (not in GDD)
## Seconds of the loop's end fed through the reverb before the real pass, so
## its tail at the top of the loop matches the end (seamless loop point).
const REVERB_PRIME: float = 4.0  # TUNING (not in GDD)
## Reverb return level (the wet bus feeds the reverb fully; the bright
## bus, only short pings and crackle, stays dry).
const REVERB_WET: float = 0.16  # TUNING (not in GDD)

# --- Content wave 2: E. Illustrated epilogue ---
# The epilogue's music cue (GDD §15.0 "Illustrated epilogue (content wave 2)"):
# a short, slow, sparse variant of this same score, rendered by MenuThemeSynth
# (MenuThemeSynth.new(EPILOGUE_VARIANT)) the first time the epilogue plays and
# crossfaded through Sfx.play_music(Sfx.MUSIC_EPILOGUE).

## The variant: "bpm" its tempo (3/4 of BPM: one beat exactly 11760 samples at
## RATE_LO), "bars" the loop is section A only (the music-box motif over the
## pad, bell and drone: 8 bars = 34.1 s at that tempo), "mute" the layers left
## out (the timpani, the harp arpeggios and the candle crackle: sparser).
const EPILOGUE_VARIANT: Dictionary = {  # TUNING (not in GDD)
	"bpm": 56.25,
	"bars": 8,
	"mute": ["timpani", "harp", "crackle"],
}
## Volume (dB) of the epilogue cue's player on the Music bus: measured RMS
## -14.1 dBFS at full scale against the theme's -14.5, so -10.5 sits about
## 1 dB under the theme (a quiet cue under reading).
const EPILOGUE_MUSIC_DB: float = -10.5  # TUNING (not in GDD)
## Seconds the cue takes to fade in (and the menu theme or run loop to fade
## out under it) when the epilogue opens, or once it is rendered.
const EPILOGUE_FADE_IN: float = 2.5  # TUNING (not in GDD)
## Seconds the cue takes to fade out when the epilogue closes.
const EPILOGUE_FADE_OUT: float = 1.5  # TUNING (not in GDD)
