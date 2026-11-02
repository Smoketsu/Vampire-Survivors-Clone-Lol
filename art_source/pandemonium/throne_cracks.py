#!/usr/bin/env python3
"""throne_cracks.py: draws the lava-filled cracks onto the Throne floor (Act VI art review round 1, owner note
"add some cracks with lava in them").

Run from the repo root right after `tools/make_tile.py build pandemonium_throne` (make_art.py floors() does). It opens
assets/sprites/tiles/pandemonium_throne.png and draws a few thin jagged cracks with a seeded random walk that wraps
around the tile edges, so the tile stays seamless. A crack is a dark red edge pixel line with a dim ember core and, on
a few pixels, a brighter spark; the tones are the lava ramp, kept dim so units read on the floor. NOT idempotent
(always run it on a fresh build). Deterministic: the seed is fixed.
"""
import numpy as np
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
TILE = ROOT / "assets/sprites/tiles/pandemonium_throne.png"  # The tile to draw on (128 x 128 art px).
SEED = 6018  # Fixed seed of the random walks (deterministic).
CRACKS = 4  # Number of cracks per tile.
STEPS = (34, 54)  # Min and max length of a crack (px).
EDGE = (0x2E, 0x10, 0x0A)  # Crack rim: a very dark red-brown (below lava_dark, keeps the floor quiet).
CORE = (0x8A, 0x2A, 0x08)  # Crack core: the lava ramp's dark shade.
SPARK = (0xC8, 0x4A, 0x12)  # A few brighter core pixels: between lava and lava_dark (never the light shade).
SPARK_EVERY = 9  # One spark pixel per this many core pixels.


def main() -> None:
    img = np.array(Image.open(TILE).convert("RGBA"))
    h, w = img.shape[:2]
    rng = np.random.default_rng(SEED)
    core = set()
    for _ in range(CRACKS):
        x, y = int(rng.integers(0, w)), int(rng.integers(0, h))
        ang = float(rng.uniform(0, 6.2832))
        for i in range(int(rng.integers(STEPS[0], STEPS[1] + 1))):
            ang += float(rng.uniform(-0.45, 0.45))  # Jagged but not curling: turn a little every step.
            x += int(round(np.cos(ang) * 1.4))
            y += int(round(np.sin(ang) * 1.4))
            core.add((x % w, y % h))
            if i % 2 == 0:
                core.add(((x + 1) % w, y % h))  # Every other step is 2 px wide: a crack, not a wire.
    rim = set()
    for (x, y) in core:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                p = ((x + dx) % w, (y + dy) % h)
                if p not in core:
                    rim.add(p)
    for (x, y) in rim:
        img[y, x, :3] = EDGE
    for n, (x, y) in enumerate(sorted(core)):
        img[y, x, :3] = SPARK if n % SPARK_EVERY == 0 else CORE
    Image.fromarray(img).save(TILE)
    print("throne cracks: %d core px, %d rim px" % (len(core), len(rim)))


if __name__ == "__main__":
    main()
