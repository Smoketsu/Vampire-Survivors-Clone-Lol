#!/usr/bin/env python3
"""corsair_tiles.py: draws the Black Tide's deck floors and the sea on the art grid (palette colours only, seeded, deterministic).

Outputs (1 art px = 1 screen px; assets/sprites/tiles/), every one SEAMLESS in both axes:
  corsair_cutter.png     128 x 128 deck planks of the Smuggler's Cutter: dark tarred oak at night (16 px planks, staggered butt joints).
  corsair_galleon.png    128 x 128 the Treasure Galleon's deck at dawn: lighter, scrubbed oak with brass nail heads.
  corsair_maelstrom.png  128 x 128 the Hollow Queen's rotting deck: grey-green boards, gaps, ghost-green mould.
  corsair_water.png      128 x 128 the navy sea with white foam lines (frame 0 of the strip).
  corsair_water_strip.png  512 x 128: four frames of the same sea, the foam lines drifting 32 px a frame (loops).
Usage (from the repo root):  python3 tools/corsair_tiles.py [--out DIR]   (default: assets/sprites/tiles)
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent  # Repository root (this file lives in tools/).
N = 128  # Tile size (px).
PLANK = 16  # Plank width (px): eight plank rows a tile.
# Palette colours used (the hexes of tools/palette.json, the Black Tide ramps).
C = {
    "ink": (0x0A, 0x0D, 0x18), "od": (0x2B, 0x1D, 0x14), "o": (0x4A, 0x32, 0x20), "ol": (0x7A, 0x56, 0x32),
    "bd": (0x7A, 0x5A, 0x1C), "b": (0xC4, 0x91, 0x2A), "pd": (0x2E, 0x32, 0x39), "p": (0x5E, 0x63, 0x6C),
    "sd": (0x0E, 0x1A, 0x33), "s": (0x1B, 0x35, 0x60), "sl": (0x2F, 0x5F, 0x96), "fs": (0x8F, 0xB4, 0xD2), "f": (0xD8, 0xE9, 0xF4),
    "gd": (0x1D, 0x4F, 0x4A), "g": (0x46, 0xA7, 0x8F),
}
# Seeds, one per output, so a rerun reproduces every file.
SEEDS = {"cutter": 11, "galleon": 12, "maelstrom": 13, "water": 14}


def deck(name: str, base: list, nails: str, mould: bool) -> Image.Image:
    """A seamless plank floor. `base` = the plank shades (dark -> light); `nails` = a colour key or '' (none)."""
    rng = random.Random(SEEDS[name])
    im = Image.new("RGBA", (N, N), C[base[0]] + (255,))
    px = im.load()
    rows = N // PLANK
    for r in range(rows):
        # Each plank row: butt joints every 64 px (offset per row) and each plank its own shade.
        off = rng.randrange(0, N)
        planks = [(off, off + 64), (off + 64, off + 128)]
        for (a, b) in planks:
            shade = rng.choice(base[:3] if len(base) >= 3 else base)
            for y in range(r * PLANK, (r + 1) * PLANK):
                for x in range(a, b):
                    px[x % N, y] = C[shade] + (255,)
            # Grain: a few long, slightly lighter or darker streaks along the plank, wrapped.
            for _ in range(5):
                gy = r * PLANK + rng.randrange(3, PLANK - 2)
                gx = a + rng.randrange(0, 56)
                ln = rng.randrange(10, 36)
                col = C[base[min(len(base) - 1, base.index(shade) + rng.choice((-1, 1)))] if base.index(shade) > 0 else base[1]]
                for x in range(gx, min(gx + ln, b)):
                    px[x % N, gy] = col + (255,)
            # Nail heads at both ends of the plank.
            if nails:
                for x in (a + 3, b - 4):
                    for y in (r * PLANK + 3, r * PLANK + PLANK - 4):
                        px[x % N, y] = C[nails] + (255,)
            # Butt joint: a dark vertical seam.
            for y in range(r * PLANK, (r + 1) * PLANK):
                px[a % N, y] = C["ink"] + (255,)
            if mould:
                for _ in range(4):
                    mx, my = a + rng.randrange(0, 60), r * PLANK + rng.randrange(2, PLANK - 2)
                    px[mx % N, my] = C["gd"] + (255,)
                    px[(mx + 1) % N, my] = C["gd"] + (255,)
                if rng.random() < 0.5:
                    px[(a + rng.randrange(5, 55)) % N, r * PLANK + rng.randrange(3, PLANK - 3)] = C["g"] + (255,)
        # The seam between plank rows: dark line on top, a light lip below it (light from the top-left).
        for x in range(N):
            px[x, r * PLANK] = C["ink"] + (255,)
            px[x, (r * PLANK + 1) % N] = C[base[-1]] + (255,)
    return im


def water(frame: int) -> Image.Image:
    """The sea: navy with lighter ripples and white foam lines that drift `frame` * 32 px (4 frames loop)."""
    rng = random.Random(SEEDS["water"])
    im = Image.new("RGBA", (N, N), C["sd"] + (255,))
    px = im.load()
    for y in range(N):
        for x in range(N):
            if (x // 8 + y // 8) % 2 == 0 and rng.random() < 0.35:
                px[x, y] = C["s"] + (255,)
    for _ in range(90):  # Ripple flecks (fixed positions, drawn with the same rng stream every frame).
        x, y = rng.randrange(N), rng.randrange(N)
        px[x, y] = C["sl"] + (255,)
        px[(x + 1) % N, y] = C["sl"] + (255,)
    lines = [(18, 1, 0.0, 5), (50, 1, 2.1, 6), (82, 2, 4.0, 4), (110, 1, 1.0, 5)]  # (centre row, cycles, phase, amplitude)
    for (cy, k, ph, amp) in lines:
        for x in range(N):
            t = 2 * math.pi * (k * (x - frame * 32) / N)
            y = cy + amp * math.sin(t + ph)
            for dy, col in ((0, "f"), (1, "fs")):
                if (x // 6 + int(cy)) % 5 == 0:  # Gaps so the line breaks into foam dashes.
                    continue
                px[x % N, int(round(y)) % N + 0] = C["f"] + (255,)
                px[x % N, (int(round(y)) + 1) % N] = C["fs"] + (255,)
    return im


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "assets" / "sprites" / "tiles"))
    out = Path(ap.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    deck("cutter", ["od", "o", "o", "ol"], "bd", False).save(out / "corsair_cutter.png")
    deck("galleon", ["o", "ol", "ol", "ol"], "b", False).save(out / "corsair_galleon.png")
    deck("maelstrom", ["od", "pd", "o", "p"], "", True).save(out / "corsair_maelstrom.png")
    water(0).save(out / "corsair_water.png")
    strip = Image.new("RGBA", (N * 4, N))
    for f in range(4):
        strip.paste(water(f), (f * N, 0))
    strip.save(out / "corsair_water_strip.png")


if __name__ == "__main__":
    main()
