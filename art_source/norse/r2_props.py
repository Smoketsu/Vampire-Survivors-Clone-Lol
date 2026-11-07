#!/usr/bin/env python3
"""r2_props.py: the Long Winter's brazier loops (owner's art review round 2: "animated flames", "the smoke wisp moves").

Usage (repo root): python3 art_source/norse/r2_props.py
Writes assets/sprites/norse/brazier_lit_anim.png and brazier_doused_anim.png: ANIM_FRAMES (8) square 32x32 frames side by side (the
`<key>_walk.png` strip contract: frame i covers x = 32 i .. 32 i + 31), frame 0 = the still. Only the still's own pixels move (no new
colour): the flame's columns stretch and sway (a per-column flicker), the smoke wisp's rows slide sideways in a travelling wave.
Play them like any strip: frame = int(game_time * ANIM_FPS) mod 8 (8 fps), through the sprite's key + "_anim".
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
DIR = ROOT / "assets/sprites/norse"  # Sprite folder.
ANIM_FRAMES = 8  # Frames per loop.
FLAME_BOTTOM = 17  # Last row of the flame (the bowl rim starts under it).


def load(name: str) -> np.ndarray:
    return np.array(Image.open(DIR / (name + ".png")).convert("RGBA"))


def flame(still: np.ndarray, f: int) -> np.ndarray:
    """Frame f of the lit brazier: each column of the flame (rows above the rim) is stretched up or down by a flicker and the tops sway."""
    out = still.copy()
    h, w = still.shape[:2]
    body = still[FLAME_BOTTOM + 1:]  # Rim and stand stay.
    out[:FLAME_BOTTOM + 1] = 0
    for x in range(w):
        col = still[:FLAME_BOTTOM + 1, x]
        ys = np.nonzero(col[:, 3] > 0)[0]
        if len(ys) == 0:
            continue
        top = int(ys[0])
        bot = FLAME_BOTTOM
        ph = 2 * math.pi * f / ANIM_FRAMES
        d = int(round(2.0 * math.sin(ph + x * 0.9) + 1.0 * math.sin(2 * ph + x * 1.7)))  # Rows the tip rises (+) or sinks (-).
        if f == 0:
            d = 0
        new_top = max(0, min(bot - 2, top - d))
        for y in range(new_top, bot + 1):
            sy = top + int(round((y - new_top) * (bot - top) / float(max(1, bot - new_top))))
            sway = int(round(1.0 * math.sin(ph + y * 0.5) * (bot - y) / float(max(1, bot - top)))) if f else 0
            nx = x + sway
            if 0 <= nx < w and col[min(sy, bot), 3] > 0:
                out[y, nx] = col[min(sy, bot)]
    return out


def smoke(still: np.ndarray, f: int) -> np.ndarray:
    """Frame f of the doused brazier: the wisp above the bowl (rows 0-14) drifts sideways in a wave that travels upward."""
    out = still.copy()
    h, w = still.shape[:2]
    out[:15] = 0
    ph = 2 * math.pi * f / ANIM_FRAMES
    for y in range(15):
        d = int(round(1.4 * math.sin(ph - y * 0.55) * (15 - y) / 15.0 * 1.6)) if f else 0
        for x in range(w):
            if still[y, x, 3] > 0 and 0 <= x + d < w:
                out[y, x + d] = still[y, x]
    return out


def strip(frames: list, name: str) -> None:
    Image.fromarray(np.concatenate(frames, axis=1), "RGBA").save(DIR / (name + ".png"), optimize=True)
    print(name, len(frames), "frames")


if __name__ == "__main__":
    lit = load("brazier_lit")
    strip([flame(lit, f) for f in range(ANIM_FRAMES)], "brazier_lit_anim")
    dou = load("brazier_doused")
    strip([smoke(dou, f) for f in range(ANIM_FRAMES)], "brazier_doused_anim")
