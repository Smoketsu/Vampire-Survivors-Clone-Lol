"""Act IX art review round 2: the Hyper Broodbound's black bee stripes (owner: "a little too gold, let's make her have some
black stripes like a bee"). Reads the round 1 still (raw/broodbound_hyper_gold.png, kept) and paints black bands across her
torso and abdomen, 2 rows black / 2 rows gold, using the still's own colours only (no new shade): gold and brown go to the
still's black 07080f, the gold highlight to its grey 3a424c. Wings, face, arms' cream and outlines are untouched. Writes
assets/sprites/player/broodbound_hyper.png (the strips are rebuilt with tools/walk_cycle.py). Run from the repo root."""
from pathlib import Path
import numpy as np
from PIL import Image

SRC = Path("art_source/crash_site/raw/broodbound_hyper_gold.png")  # The round 1 still.
DST = Path("assets/sprites/player/broodbound_hyper.png")  # The still the game loads.
BANDS = [(25, 27), (29, 31), (33, 35), (37, 39), (41, 43), (45, 47)]  # Black bands, rows [start, end).
COLS = (8, 26)  # Columns [start, end) the bands span (the body and its sides, not the cream wings).
GOLD = {(0xe0, 0xa9, 0x2e), (0x8c, 0x60, 0x40)}  # Gold and its brown shade -> black.
LIGHT = (0xff, 0xdc, 0x66)  # Gold highlight -> the still's dark grey.
BLACK = (0x07, 0x08, 0x0f)
GREY = (0x3a, 0x42, 0x4c)

a = np.array(Image.open(SRC).convert("RGBA"))
for y0, y1 in BANDS:
    for y in range(y0, y1):
        for x in range(*COLS):
            if a[y, x, 3] == 0:
                continue
            c = tuple(int(v) for v in a[y, x, :3])
            if c in GOLD:
                a[y, x, :3] = BLACK
            elif c == LIGHT:
                a[y, x, :3] = GREY
Image.fromarray(a, "RGBA").save(DST, optimize=True)
