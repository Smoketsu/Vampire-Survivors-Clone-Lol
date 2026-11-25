"""compose.py: writes and renders the per-stage songs in assets/audio/music/ (audio overhaul, Nov 2026; GDD §15.0
"Audio overhaul: sampled sound effects and per-stage songs").

Usage (from the repo root; needs numpy, ffmpeg, `pip install tinysoundfont`, and the GeneralUser GS soundfont):
    python3 tools/audio/compose.py --sf2 PATH/GeneralUser.sf2            # every stage
    python3 tools/audio/compose.py --sf2 PATH/GeneralUser.sf2 graveyard  # only the stages given
    python3 tools/audio/compose.py ... --wav DIR                         # also write uncompressed previews
The soundfont: GeneralUser GS v1.471 by S. Christian Collins (free for any music, commercial included; on npm
as the `generaluser` package, `GeneralUser.sf2`). It is a build input only, never shipped.

How a song is made. The songs themselves are written in songs.py: one THEME per act (scale, key, metre, a two-bar
motif, two chord progressions, an ensemble, a drum style) and one STAGE entry per stage that varies it (tempo, key,
instruments, progressions, energy). Every stage of an act shares its act's motif (a leitmotif), so an act sounds like
one place while each stage is its own song. From that, this file:
  1. lays out the form: a short intro (pad and bass only), then the looping body A, A', B, A'' (8 bars each);
  2. writes the parts bar by bar: pad chords with voice leading, a bass pattern, the melody (the motif placed on a
     chord tone and developed: repeated, sequenced, inverted in B, with a cadence on the root every 8 bars), a
     countermelody from the pad's inner voice, an arpeggio, a doubling voice in A'', bells and a drum pattern;
  3. renders the events with the soundfont (tinysoundfont), the body twice in a row, adds one shared reverb, and
     keeps intro + the SECOND body: that body's start already holds the first body's reverb tail, so jumping from the
     file end back to the body start (SongData.LOOPS, the loop offset in seconds) is seamless;
  4. masters it (RMS to TARGET_RMS, a tanh limiter) and writes Ogg Vorbis, then regenerates
     scripts/data/song_data.gd (titles, loop offsets, tempos) for the game.
Everything is seeded per stage (songs.py "seed"), so a re-render gives the same song.
"""

import argparse
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audio_dsp as dsp  # noqa: E402
import songs  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # Repo root.
OUT_DIR = os.path.join(ROOT, "assets", "audio", "music")  # Where the .ogg songs go.
DATA_FILE = os.path.join(ROOT, "scripts", "data", "song_data.gd")  # The generated loop / title table.
OUT_RATE = 32000  # Sample rate of the shipped files (Hz): the soundfont has little above 16 kHz.
QUALITY = 1  # Vorbis quality of the songs (ffmpeg -q:a; about 70-80 kbps stereo at 32 kHz).
TARGET_RMS = 0.13  # Mastered RMS level (0..1 full scale, about -18 dBFS); Sfx plays songs at SoundData.SONG_DB.
CEILING = 0.95  # Limiter ceiling (0..1 full scale).
SECTION_BARS = 8  # Bars per body section (A, A', B, A'').
MIN_BODY_S = 70.0  # A body shorter than about this (s) repeats each section's bars (compose()), so no loop is under ~50 s.

SCALES = {  # Scale name -> semitones of its 7 degrees above the key root.
    "ionian": [0, 2, 4, 5, 7, 9, 11], "dorian": [0, 2, 3, 5, 7, 9, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11], "mixolydian": [0, 2, 4, 5, 7, 9, 10], "aeolian": [0, 2, 3, 5, 7, 8, 10],
    "harmonic": [0, 2, 3, 5, 7, 8, 11], "hijaz": [0, 1, 4, 5, 7, 8, 10], "melodic": [0, 2, 3, 5, 7, 9, 11],
}
DRUM_CH = 9  # The General MIDI drum channel.
ROLES = ["pad", "bass", "lead", "counter", "arp", "double", "perc", "bells", "drone"]  # Melodic roles; role i plays on channel i.


# --------------------------------------------------------------------------------------------------------------
# Harmony
# --------------------------------------------------------------------------------------------------------------

class Key:
    """A key: tonic MIDI note `root` and a 7-degree scale (SCALES name)."""

    def __init__(self, root: int, scale: str):
        self.root = root  # Tonic as a MIDI note number (its octave is only a reference).
        self.steps = SCALES[scale]  # Semitones of the 7 degrees.

    def pitch(self, degree: int) -> int:
        """MIDI note of scale degree `degree` (0 = the tonic at `root`; negative / >6 wrap octaves)."""
        return self.root + 12 * (degree // 7) + self.steps[degree % 7]

    def degree_of(self, pitch: int) -> int:
        """Nearest scale degree to MIDI `pitch` (rounding down between degrees)."""
        best, bd = 0, 999
        for d in range(-21, 28):
            dist = abs(self.pitch(d) - pitch)
            if dist < bd or (dist == bd and self.pitch(d) <= pitch):
                best, bd = d, dist
        return best


def chord_tones(key: Key, symbol: str) -> list:
    """Pitch classes (0-11, relative to C) of chord `symbol`: a scale degree 1-7 with an optional quality
    suffix: M (major), m (minor), d (diminished), s (sus4), 7 (add the diatonic 7th), b (flat the root a
    semitone, e.g. "b2" = Neapolitan in minor with M). Without a suffix the triad is diatonic."""
    flat = symbol.startswith("b")
    body = symbol[1:] if flat else symbol
    deg = int(body[0]) - 1  # 0-based degree.
    suf = body[1:]  # Quality letters.
    r = key.pitch(deg) - (1 if flat else 0)  # Chord root (MIDI, near the key root).
    third = key.pitch(deg + 2) - key.pitch(deg)  # Diatonic third (semitones).
    fifth = key.pitch(deg + 4) - key.pitch(deg)  # Diatonic fifth.
    if "M" in suf:
        third, fifth = 4, 7
    if "m" in suf:
        third, fifth = 3, 7
    if "d" in suf:
        third, fifth = 3, 6
    if "s" in suf:
        third = 5
    tones = [r, r + third, r + fifth]
    if "7" in suf:
        tones.append(key.pitch(deg + 6) - (1 if flat else 0))
    return [t % 12 for t in tones]


def voice(tones: list, prev: list, lo: int, hi: int, n: int) -> list:
    """An n-note close voicing of pitch classes `tones` within [lo, hi] that moves least from `prev`."""
    cands = []
    for base in range(lo, hi - 4):
        v = sorted({p for p in range(base, base + 13) for t in tones if p % 12 == t})[:n]
        if len(v) == n and v[-1] <= hi and v[0] % 12 in tones:
            cands.append(v)
    if not prev:
        return cands[len(cands) // 2]
    return min(cands, key=lambda v: sum(abs(a - b) for a, b in zip(v, prev)))


def nearest(tones: list, target: int, lo: int, hi: int) -> int:
    """The MIDI note in [lo, hi] whose pitch class is in `tones` closest to `target`."""
    return min((p for p in range(lo, hi + 1) if p % 12 in tones), key=lambda p: (abs(p - target), p))


# --------------------------------------------------------------------------------------------------------------
# Writing the parts
# --------------------------------------------------------------------------------------------------------------

def parse_motif(text: str) -> list:
    """Motif text -> [(degree offset or None for a rest, beats)]: tokens "deg[:beats]" or "r:beats" ("|" ignored)."""
    out = []
    for tok in text.replace("|", " ").split():
        d, _, b = tok.partition(":")
        out.append((None if d == "r" else int(d), float(b) if b else 1.0))
    return out


class Song:
    """Collects note events for one song: events are (beat, duration beats, channel, MIDI note, velocity)."""

    def __init__(self, spec: dict, rng: np.random.Generator):
        self.spec = spec  # The merged theme + stage spec (songs.py).
        self.rng = rng  # The stage's seeded RNG.
        self.bpb = spec["meter"]  # Beats per bar.
        self.key = Key(spec["root"] + spec.get("shift", 0), spec["scale"])
        self.events = []  # (beat, dur, channel, note, velocity)

    def note(self, beat: float, dur: float, role: str, pitch: int, vel: float) -> None:
        """Adds one note on `role`'s channel (velocity 0..1, humanised by +-6%)."""
        if role not in self.spec["ens"]:
            return
        ch = DRUM_CH if role == "drums" else ROLES.index(role)
        if role != "drums":
            pitch += 12 * self.spec["ens"][role].get("oct", 0)
        v = vel * (1.0 + self.rng.uniform(-0.06, 0.06)) * self.spec["ens"][role].get("vel", 1.0)
        self.events.append((beat, dur, ch, int(pitch), int(np.clip(v * 127, 1, 127))))

    # --- Each section ----------------------------------------------------------------------------------------
    def section(self, start_bar: int, prog: list, kind: str, energy: int) -> None:
        """Writes one section of len(prog) bars at `start_bar`. kind: "intro", "A", "A2", "B", "A3"."""
        bpb = self.bpb
        lead_on = kind != "intro"
        prev_pad = getattr(self, "_prev_pad", [])
        for i, sym in enumerate(prog):
            b0 = (start_bar + i) * bpb  # First beat of the bar.
            tones = chord_tones(self.key, sym)
            pad = voice(tones, prev_pad, 50, 74, 4 if energy >= 2 else 3)
            prev_pad = pad
            pad_vel = {"intro": 0.45, "A": 0.5, "A2": 0.58, "B": 0.55, "A3": 0.62}[kind]
            for p in pad:
                self.note(b0, bpb, "pad", p, pad_vel)
            self.drone(b0, tones, i)
            self.bass(b0, tones, kind, energy)
            if kind != "intro" or energy >= 3:
                self.arp(b0, pad, kind, energy, i)
            if kind in ("A2", "B", "A3") and energy >= 2:
                self.note(b0, bpb / 2, "counter", pad[1] + 12, 0.5)
                self.note(b0 + bpb / 2, bpb / 2, "counter", pad[2] + 12 if len(pad) > 2 else pad[1] + 12, 0.45)
            if i % 4 == 0 and kind != "intro":
                self.note(b0, bpb * 2, "bells", nearest(tones, 76, 72, 84), 0.5)
            self.drums(b0, kind, energy, i, len(prog))
            self.perc(b0, tones, kind, energy)
        self._prev_pad = prev_pad
        if lead_on:
            self.melody(start_bar, prog, kind, energy)

    def drone(self, b0: float, tones: list, i: int) -> None:
        """A low tonic drone, re-struck every 4 bars."""
        if i % 4 == 0:
            self.note(b0, self.bpb * 4, "drone", self.key.pitch(-7), 0.5)

    def bass(self, b0: float, tones: list, kind: str, energy: int) -> None:
        """The bass line of one bar (pattern from the spec's "bass": hold, halves, pulse, drive, walk, waltz, six)."""
        r = nearest([tones[0]], self.key.root - 12, 28, 52)  # Chord root in the bass register.
        f = r + 7  # Its fifth.
        pat = self.spec["bass"] if kind != "intro" else ("hold" if energy < 3 else self.spec["bass"])
        bpb = self.bpb
        if pat == "hold":
            self.note(b0, bpb, "bass", r, 0.7)
        elif pat == "halves":
            self.note(b0, bpb / 2, "bass", r, 0.75)
            self.note(b0 + bpb / 2, bpb / 2, "bass", f if bpb % 2 == 0 else r, 0.65)
        elif pat == "pulse":
            for k in range(int(bpb * 2)):
                self.note(b0 + k * 0.5, 0.45, "bass", r, 0.7 if k % 2 == 0 else 0.55)
        elif pat == "drive":
            for k in range(int(bpb * 2)):
                self.note(b0 + k * 0.5, 0.45, "bass", r + (12 if k % 4 == 3 else 0), 0.75 if k % 2 == 0 else 0.6)
        elif pat == "walk":
            for k, p in enumerate([r, f, r + 12, f][:bpb]):
                self.note(b0 + k, 0.9, "bass", p, 0.7)
        elif pat == "waltz":
            self.note(b0, 1, "bass", r, 0.75)
            self.note(b0 + 1, 2, "bass", f, 0.45)
        elif pat == "six":  # 6/8: dotted-quarter roots and fifths.
            self.note(b0, 2.5, "bass", r, 0.75)
            self.note(b0 + 3, 2.5, "bass", f, 0.6)

    def arp(self, b0: float, pad: list, kind: str, energy: int, i: int) -> None:
        """A broken-chord figure over the bar (rate from the spec's "arp_rate" in beats; up-down)."""
        rate = self.spec.get("arp_rate", 0.5)
        if kind == "A" and energy < 2:
            rate *= 2
        seq = [p + 12 for p in pad] + [pad[-2] + 12] if len(pad) > 2 else [p + 12 for p in pad]
        n = int(self.bpb / rate)
        for k in range(n):
            self.note(b0 + k * rate, rate * 0.95, "arp", seq[k % len(seq)], 0.42 + (0.1 if k == 0 else 0.0))

    def perc(self, b0: float, tones: list, kind: str, energy: int) -> None:
        """Melodic percussion (taiko, timpani, ...): the spec's "perc_pat" beats, on the chord root."""
        pat = self.spec.get("perc_pat")
        if not pat or (kind == "A" and energy < 2) or kind == "intro":
            return
        r = nearest([tones[0]], self.key.root - 12, 36, 55)
        for k, (pos, vel) in enumerate(pat):
            self.note(b0 + pos, 0.5, "perc", r if k % 3 != 2 else r + 7, vel)

    def drums(self, b0: float, kind: str, energy: int, i: int, bars: int) -> None:
        """One bar of the spec's drum style (songs.DRUMS), lighter in A at low energy, a fill on the last bar,
        a crash at the top of a section in A2 / A3."""
        style = self.spec.get("drums")
        if not style or "drums" not in self.spec["ens"] or kind == "intro":
            return
        level = {"A": 0.55 if energy < 2 else 0.8, "A2": 0.9, "B": 0.7, "A3": 1.0}[kind]
        last = i == bars - 1
        for pos, note, vel in songs.DRUMS[style]["fill" if last and energy >= 2 else "bar"]:
            if level < 0.6 and note in (42, 44, 46, 51, 54, 70):  # Sparse: no hats / ride / shakers.
                continue
            self.note(b0 + pos, 0.25, "drums", note, vel * level)
        if i == 0 and kind in ("A2", "A3"):
            self.note(b0, 1, "drums", 49, 0.75)
        if energy >= 3 and kind == "A3" and i % 2 == 1:
            for k in range(int(self.bpb * 4)):
                self.note(b0 + k * 0.25, 0.1, "drums", 42, 0.3 + (0.15 if k % 4 == 0 else 0.0))

    # --- The melody ------------------------------------------------------------------------------------------
    def melody(self, start_bar: int, prog: list, kind: str, energy: int) -> None:
        """The lead line of one section: the motif developed over the section's bars (header of this file)."""
        motif = parse_motif(self.spec["motif"])
        if kind == "B":  # Inverted contour, its own rhythm feel.
            motif = [(None if d is None else -d, b) for d, b in motif]
        span = sum(b for _, b in motif)  # Motif length in beats (normally 2 bars).
        bars_per = max(1, int(round(span / self.bpb)))
        center = self.spec.get("lead_center", 72)  # Register centre of the lead (MIDI).
        prev = center
        bar = 0
        phrase = 0  # Motif statements so far in this section.
        bars = len(prog)
        while bar < bars:
            b0 = (start_bar + bar) * self.bpb
            tones = chord_tones(self.key, prog[bar])
            if bar + bars_per >= bars:  # The last statement: a cadence onto the section's last chord root.
                self.cadence(b0, prog[bar:], prev, kind)
                break
            anchor = nearest(tones, (prev + center) // 2 if phrase else center, center - 7, center + 7)  # Drift back toward the centre.
            start_deg = self.key.degree_of(anchor)
            if phrase % 2 == 1 and self.rng.random() < 0.5:  # Answer phrase: up a step, the sequence.
                start_deg += 1 if self.rng.random() < 0.6 else -1
            t = b0
            for d, beats in motif:
                if d is None:
                    t += beats
                    continue
                p = self.key.pitch(start_deg + d)
                bar_here = start_bar + int((t - start_bar * self.bpb) // self.bpb)
                chord_here = chord_tones(self.key, prog[min(bars - 1, bar_here - start_bar)])
                on_beat = abs((t - start_bar * self.bpb) % self.bpb) < 1e-6  # A bar downbeat.
                if on_beat and p % 12 not in chord_here:  # Downbeats land on a chord tone, keeping the contour's direction.
                    up = p >= prev
                    opts = [q for q in ((p + 1, p + 2, p - 1, p - 2) if up else (p - 1, p - 2, p + 1, p + 2)) if q % 12 in chord_here]
                    p = opts[0] if opts else p
                vel = 0.72 + (0.08 if on_beat else 0.0) + (0.05 if kind == "A3" else 0.0)
                self.note(t, beats * 0.95, "lead", p, vel)
                if kind == "A3" or (kind == "A2" and energy >= 3):
                    self.note(t, beats * 0.95, "double", p - 12, vel * 0.85)
                prev = p
                t += beats
            bar += bars_per
            phrase += 1

    def cadence(self, b0: float, chords: list, prev: int, kind: str) -> None:
        """The phrase ending over the last bars: the motif's first-bar rhythm walking by step from `prev` to the
        final chord's root, which lands on the last bar's downbeat and is held for that bar."""
        last = chord_tones(self.key, chords[-1])
        target = nearest([last[0]], prev, prev - 7, prev + 7)
        rhythm = []  # Durations of the motif's first bar (rests skipped).
        acc = 0.0
        for d, beats in parse_motif(self.spec["motif"]):
            if acc >= self.bpb - 1e-6:
                break
            if d is not None:
                rhythm.append(beats)
            acc += beats
        while len(rhythm) > 4:  # At most four walking notes: merge the shortest neighbouring pair.
            k = min(range(len(rhythm) - 1), key=lambda j: rhythm[j] + rhythm[j + 1])
            rhythm[k:k + 2] = [rhythm[k] + rhythm[k + 1]]
        d1 = self.key.degree_of(target)
        d0 = self.key.degree_of(prev)
        n = len(rhythm)  # Notes before the final one.
        sign = 1 if d0 <= d1 else -1
        if abs(d1 - d0) < n:  # Not far enough: approach from the other side.
            sign = -1 if d0 <= d1 else 1
        degrees = [d1 - sign * (n - k) for k in range(n)]
        t = b0 + (len(chords) - 2) * self.bpb  # The walk takes the second-to-last bar.
        for d, beats in zip(degrees, rhythm):
            self.note(t, beats * 0.95, "lead", self.key.pitch(d), 0.7)
            if kind == "A3":
                self.note(t, beats * 0.95, "double", self.key.pitch(d) - 12, 0.6)
            t += beats
        t = b0 + (len(chords) - 1) * self.bpb
        self.note(t, self.bpb * 0.95, "lead", target, 0.76)
        if kind == "A3":
            self.note(t, self.bpb * 0.95, "double", target - 12, 0.62)


def compose(spec: dict) -> tuple:
    """Writes the whole song. Returns (Song, intro bars, body bars)."""
    rng = np.random.default_rng(spec["seed"])
    s = Song(spec, rng)
    e = spec["energy"]
    a, b = spec["prog_a"], spec["prog_b"]
    def fill(p):  # Repeat a progression to SECTION_BARS bars.
        return (p * (SECTION_BARS // len(p) + 1))[:SECTION_BARS]
    intro = a[: spec.get("intro_bars", 4)]
    s.section(0, intro, "intro", e)
    body0 = len(intro)
    spb = 60.0 / spec["bpm"]  # Seconds per beat.
    reps = max(1, round(MIN_BODY_S / (4 * SECTION_BARS * s.bpb * spb)))  # Short-bar songs (waltzes) play each section longer.
    a2, b2 = fill(a) * reps, fill(b) * reps  # The A and B progressions at the section length.
    form = [(a2, "A"), (a2, "A2"), (b2, "B"), (a2, "A3")]
    body_bars = sum(len(p) for p, _ in form)
    bar = body0  # The body is written once; render() plays it twice with identical events (a seamless loop).
    for prog, kind in form:
        s.section(bar, prog, kind, e)
        bar += len(prog)
    return s, len(intro), body_bars


# --------------------------------------------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------------------------------------------

def render(song: Song, sf2: str, intro_beats: float, body_beats: float) -> tuple:
    """Renders the song with the soundfont: the intro, then the body twice with sample-identical events (each body
    event at the same sample offset and the same human timing in both copies), plus 4 s of tail. Returns
    (stereo float buffer at dsp.RATE, intro length in samples, body length in samples)."""
    import tinysoundfont as tsf
    spec = song.spec
    synth = tsf.Synth(samplerate=dsp.RATE, gain=-6)
    sfid = synth.sfload(sf2, max_voices=256)
    for role, ins in spec["ens"].items():
        if role == "drums":
            synth.program_select(DRUM_CH, sfid, 128, ins["kit"], True)
            synth.control_change(DRUM_CH, 7, ins.get("vol", 100))
            continue
        ch = ROLES.index(role)
        synth.program_select(ch, sfid, 0, ins["prog"])
        synth.control_change(ch, 7, ins.get("vol", 100))
        synth.control_change(ch, 10, ins.get("pan", 64))
    spb = 60.0 / spec["bpm"]  # Seconds per beat.
    intro_n = int(round(intro_beats * spb * dsp.RATE))  # Intro length (samples).
    body_n = int(round(body_beats * spb * dsp.RATE))  # Body length (samples).
    timeline = []  # (sample, kind 1 = on / 0 = off, channel, note, velocity)
    for beat, dur, ch, note, vel in song.events:
        jitter = song.rng.uniform(-0.006, 0.006) if ch != DRUM_CH else 0.0  # Human timing (s), once per event.
        length = max(1, int(dur * spb * dsp.RATE))  # Held length (samples).
        if beat < intro_beats:
            starts = [int((beat * spb + jitter) * dsp.RATE)]
        else:
            off = int(round(((beat - intro_beats) * spb + jitter) * dsp.RATE))  # Offset inside the body (samples).
            starts = [intro_n + off, intro_n + body_n + off]
            if off < 0:  # Starts a hair before the body (human timing): also before the file end, where the loop wraps.
                starts.append(intro_n + 2 * body_n + off)
        for on in starts:
            on = max(0, on)
            timeline.append((on, 1, ch, note, vel))
            timeline.append((on + length, 0, ch, note, 0))
    timeline.sort(key=lambda e: (e[0], e[1]))  # Offs before ons at the same sample (re-strikes sound).
    n_total = intro_n + 2 * body_n + int(4.0 * dsp.RATE)
    out = np.zeros((n_total, 2), np.float32)
    pos = 0
    for smp, kind, ch, note, vel in timeline + [(n_total, -1, 0, 0, 0)]:
        smp = min(smp, n_total)
        if smp > pos:
            out[pos:smp] = np.frombuffer(synth.generate(smp - pos), np.float32).reshape(-1, 2)
            pos = smp
        if kind == 1:
            synth.noteon(ch, note, vel)
        elif kind == 0:
            synth.noteoff(ch, note)
    return out, intro_n, body_n


def master(raw: np.ndarray, spec: dict, intro_n: int, body_n: int) -> np.ndarray:
    """Reverb, cut to intro + second body, RMS to TARGET_RMS, limiter."""
    wet, decay = spec.get("verb", (0.25, 2.2))
    ir = dsp.reverb_ir(decay, 4500.0, spec["seed"], True)
    wet_sig = dsp.convolve(raw, ir)[: len(raw)]
    mix = raw * (1.0 - wet * 0.5) + wet_sig * wet
    song = np.concatenate([mix[:intro_n], mix[intro_n + body_n: intro_n + 2 * body_n]])  # Intro + the second body.
    rms = np.sqrt((song ** 2).mean())
    song = song * (TARGET_RMS / max(rms, 1e-6))
    return dsp.soft_clip(song, CEILING)


def write_data(rows: dict) -> None:
    """Regenerates scripts/data/song_data.gd from every song's (title, loop offset, bpm, seconds)."""
    lines = [
        "## SongData: the per-stage songs (audio overhaul, Nov 2026; GDD §15.0 \"Audio overhaul: sampled sound",
        "## effects and per-stage songs\"). GENERATED by tools/audio/compose.py from tools/audio/songs.py: do not edit",
        "## by hand, re-run the composer. Sfx plays SoundData.SONG_DIR/<stage id>.ogg for a stage's run music and",
        "## loops it from LOOPS (the intro plays once). No logic here.",
        "class_name SongData",
        "extends RefCounted",
        "",
        "## Stage id -> loop start of its song (s from the file start: the end of the intro). TUNING (not in GDD)",
        "const LOOPS: Dictionary = {",
    ]
    lines += ['\t"%s": %.8f,' % (k, v[1]) for k, v in rows.items()]
    lines += ["}", "", "## Stage id -> the song's title (shown nowhere yet; for credits and the Codex). TUNING (not in GDD)",
              "const TITLES: Dictionary = {"]
    lines += ['\t"%s": "%s",' % (k, v[0]) for k, v in rows.items()]
    lines += ["}", "", "## Stage id -> tempo of its song (beats per minute). TUNING (not in GDD)", "const BPM: Dictionary = {"]
    lines += ['\t"%s": %d,' % (k, v[2]) for k, v in rows.items()]
    lines += ["}", "", "## Stage id -> length of its song file (s: intro + one body). TUNING (not in GDD)",
              "const SECONDS: Dictionary = {"]
    lines += ['\t"%s": %.2f,' % (k, v[3]) for k, v in rows.items()]
    lines += ["}", ""]
    with open(DATA_FILE, "w") as f:
        f.write("\n".join(lines))


def read_data() -> dict:
    """The rows already in song_data.gd (so rendering a few stages keeps the others)."""
    rows = {}
    if not os.path.exists(DATA_FILE):
        return rows
    import re
    text = open(DATA_FILE).read()
    def table(name):
        m = re.search(r"const %s: Dictionary = \{(.*?)\}" % name, text, re.S)
        return dict(re.findall(r'"(\w+)": "?([^",\n]*)"?,', m.group(1))) if m else {}
    loops, titles, bpm, secs = table("LOOPS"), table("TITLES"), table("BPM"), table("SECONDS")
    for k in loops:
        rows[k] = (titles.get(k, k), float(loops[k]), int(bpm.get(k, 0)), float(secs.get(k, 0)))
    return rows


def main() -> int:
    """Renders the stages given (all when none); returns the exit code."""
    ap = argparse.ArgumentParser()
    ap.add_argument("--sf2", required=True, help="path to GeneralUser.sf2")
    ap.add_argument("--wav", default="", help="also write .wav previews into this folder")
    ap.add_argument("stages", nargs="*")
    args = ap.parse_args()
    dsp.RATE = OUT_RATE  # Render at the file rate, so the loop point is a whole sample of the shipped file.
    os.makedirs(OUT_DIR, exist_ok=True)
    rows = read_data()
    for sid in args.stages or list(songs.STAGES):
        spec = songs.spec_for(sid)
        song, intro_bars, body_bars = compose(spec)
        spb = 60.0 / spec["bpm"]
        raw, intro_n, body_n = render(song, args.sf2, intro_bars * song.bpb, body_bars * song.bpb)
        out = master(raw, spec, intro_n, body_n)
        intro_s, body_s = intro_n / dsp.RATE, body_n / dsp.RATE
        dsp.encode_ogg(out, os.path.join(OUT_DIR, sid + ".ogg"), QUALITY, OUT_RATE)
        if args.wav:
            import wave
            os.makedirs(args.wav, exist_ok=True)
            with wave.open(os.path.join(args.wav, sid + ".wav"), "wb") as w:
                w.setnchannels(2), w.setsampwidth(2), w.setframerate(dsp.RATE)
                w.writeframes((np.clip(out, -1, 1) * 32767).astype("<i2").tobytes())
        rows[sid] = (spec["title"], intro_s, spec["bpm"], len(out) / dsp.RATE)
        print("%-18s %-34s %3d bpm  intro %4.1f s  loop %5.1f s" % (sid, spec["title"], spec["bpm"], intro_s, body_s))
    order = [k for k in songs.STAGES if k in rows]
    write_data({k: rows[k] for k in order})
    return 0


if __name__ == "__main__":
    sys.exit(main())
