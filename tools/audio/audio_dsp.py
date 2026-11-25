"""audio_dsp.py: the small numpy DSP kit shared by build_sfx.py and compose.py (audio overhaul, Nov 2026).

Everything works on float32 numpy arrays at RATE Hz, shape (n,) for mono or (n, 2) for stereo.
Only numpy and the ffmpeg command line are needed. Filters are FFT based (whole-buffer, zero
phase), which is fine offline and keeps the code short.
"""

import subprocess

import numpy as np

RATE = 44100  # Working sample rate of every buffer (Hz).


def decode(path: str, channels: int = 1) -> np.ndarray:
    """Decodes any audio file ffmpeg reads into a float32 array at RATE (channels 1 or 2)."""
    raw = subprocess.run(["ffmpeg", "-v", "quiet", "-i", path, "-ac", str(channels), "-ar", str(RATE),
                          "-f", "f32le", "-"], capture_output=True, check=True).stdout
    a = np.frombuffer(raw, np.float32).copy()
    return a.reshape(-1, 2) if channels == 2 else a


def encode_ogg(a: np.ndarray, path: str, quality: float, out_rate: int = RATE) -> None:
    """Writes `a` as Ogg Vorbis to `path` (quality -1..10, ffmpeg -q:a; out_rate = file sample rate, Hz)."""
    ch = 2 if a.ndim == 2 else 1  # Channel count of the buffer.
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(ch), "-i", "-",
                    "-ar", str(out_rate), "-c:a", "libvorbis", "-q:a", str(quality), path],
                   input=np.ascontiguousarray(a, np.float32).tobytes(), check=True)


def resample(a: np.ndarray, ratio: float) -> np.ndarray:
    """Plays `a` `ratio` times faster (tape-style pitch shift: 0.5 = an octave lower and twice as long)."""
    if abs(ratio - 1.0) < 1e-6:
        return a
    n = int(len(a) / ratio)  # Output length (samples).
    x = np.arange(n) * ratio  # Source position of each output sample.
    if a.ndim == 1:
        return np.interp(x, np.arange(len(a)), a).astype(np.float32)
    return np.stack([np.interp(x, np.arange(len(a)), a[:, c]) for c in range(a.shape[1])], 1).astype(np.float32)


def spectral_filter(a: np.ndarray, lowpass: float = 0.0, highpass: float = 0.0) -> np.ndarray:
    """Zero-phase lowpass / highpass (Hz; 0 = off) with a gentle 2nd-order-like magnitude slope."""
    if lowpass <= 0.0 and highpass <= 0.0:
        return a
    n = len(a)
    spec = np.fft.rfft(a, axis=0)
    f = np.fft.rfftfreq(n, 1.0 / RATE)  # Bin frequencies (Hz).
    g = np.ones_like(f)  # Gain per bin.
    if lowpass > 0.0:
        g /= 1.0 + (f / lowpass) ** 4
    if highpass > 0.0:
        g *= 1.0 / (1.0 + (highpass / np.maximum(f, 1e-3)) ** 4)
    spec *= g[:, None] if a.ndim == 2 else g
    return np.fft.irfft(spec, n, axis=0).astype(np.float32)


def reverb_ir(seconds: float, damp_hz: float, seed: int, stereo: bool) -> np.ndarray:
    """A synthetic room impulse response: decaying noise (-60 dB after `seconds`), darker as it decays
    (`damp_hz` = lowpass of the late tail, Hz). Seeded, so a render is repeatable."""
    rng = np.random.default_rng(seed)
    n = int(seconds * RATE)
    t = np.arange(n) / RATE  # Time of each IR sample (s).
    env = np.exp(-6.9 * t / seconds)  # -60 dB at `seconds`.
    chans = []
    for _ in range(2 if stereo else 1):
        early = rng.standard_normal(n) * env
        late = spectral_filter(early.astype(np.float32), lowpass=damp_hz)
        mix = np.linspace(0.0, 1.0, n)  # Crossfade from bright early reflections to the damped tail.
        chans.append((early * (1.0 - mix) * 0.6 + late * mix) * env)
    ir = np.stack(chans, 1) if stereo else chans[0]
    ir[: int(0.004 * RATE)] *= np.linspace(0.0, 1.0, int(0.004 * RATE))[:, None] if stereo else np.linspace(0.0, 1.0, int(0.004 * RATE))
    return (ir / np.sqrt((ir ** 2).sum(axis=0).max())).astype(np.float32)


def convolve(a: np.ndarray, ir: np.ndarray) -> np.ndarray:
    """FFT convolution; output is len(a) + len(ir) - 1 long. Mono `a` with a stereo IR gives stereo."""
    n = len(a) + len(ir) - 1
    size = 1 << (n - 1).bit_length()  # FFT size (power of two).
    if a.ndim == 1 and ir.ndim == 2:
        a = np.repeat(a[:, None], 2, 1)
    fa = np.fft.rfft(a, size, axis=0)
    fi = np.fft.rfft(ir, size, axis=0)
    if fa.ndim == 2 and fi.ndim == 1:
        fi = fi[:, None]
    return np.fft.irfft(fa * fi, size, axis=0)[:n].astype(np.float32)


def soft_clip(a: np.ndarray, ceiling: float) -> np.ndarray:
    """tanh limiter: unity below about half the ceiling, never above `ceiling` (0..1 full scale)."""
    return (np.tanh(a / ceiling) * ceiling).astype(np.float32)


def db(x: float) -> float:
    """dB -> linear gain."""
    return 10.0 ** (x / 20.0)
