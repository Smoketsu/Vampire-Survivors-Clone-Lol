#!/usr/bin/env python3
"""Recolours the feathered wings of assets/sprites/player/succubus_queen_hyper.png white (Act VI art review, round 2, owner:
"can the wings be white?"). A palette edit, no image generation: only pixels of the still's own palette are used.

The wing pixels are the brown (#8c6040) and the dark violet-navy feather bars of the two wing columns (the body, hair, tail, arms
and the gold tips are left as they are). Light comes from the upper left, so the shade steps from bone-white to ivory to grey
with the diagonal x + y. Run once on the round 1 still; it prints how many pixels changed. Then rebuild the strips:
    python3 tools/walk_cycle.py build player/succubus_queen_hyper && python3 tools/walk_cycle.py idle player/succubus_queen_hyper
"""
import numpy as np
from pathlib import Path
from PIL import Image

PATH = Path(__file__).resolve().parent.parent / "assets" / "sprites" / "player" / "succubus_queen_hyper.png"  # The still.
BROWN = (0x8c, 0x60, 0x40)  # The feathers' base colour in the round 1 still.
# Feather bars (dark violet-navy) -> the bar shade of the white wing: palette colours of the still itself.
BARS = {(0x1e, 0x1a, 0x26): (0x8e, 0x8a, 0x86), (0x35, 0x2e, 0x40): (0xb4, 0xaa, 0x8a), (0x5a, 0x50, 0x68): (0xcf, 0xcb, 0xc4)}
# Wing base by the diagonal s = x + y (light from the upper left): bone white, ivory, light grey, shadowed bone.
BASE = [(24, (0xf4, 0xf1, 0xea)), (42, (0xe8, 0xe1, 0xc8)), (70, (0xcf, 0xcb, 0xc4)), (999, (0xb4, 0xaa, 0x8a))]


def wing_mask(h: int, w: int) -> np.ndarray:
    """Boolean mask of the two wings' columns: left x <= 15 (x 16 below row 22), rows 7-35; right x >= 30 (x 29 below row 22), rows 6-38."""
    m = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            if 7 <= y <= 35 and (x <= 15 or (x == 16 and y >= 22)):
                m[y, x] = True
            if 6 <= y <= 38 and (x >= 30 or (x == 29 and y >= 22)):
                m[y, x] = True
    return m


def main() -> None:
    im = np.array(Image.open(PATH).convert("RGBA"))
    m = wing_mask(*im.shape[:2]) & (im[:, :, 3] > 0)
    n = 0
    for y, x in zip(*np.nonzero(m)):
        c = tuple(int(v) for v in im[y, x, :3])
        if c == BROWN:
            for lim, col in BASE:
                if x + y < lim:
                    im[y, x, :3] = col
                    break
            n += 1
        elif c in BARS:
            im[y, x, :3] = BARS[c]
            n += 1
    Image.fromarray(im, "RGBA").save(PATH, optimize=True)
    print(f"{n} wing pixels recoloured")


if __name__ == "__main__":
    main()
