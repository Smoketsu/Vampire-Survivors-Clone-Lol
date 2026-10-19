#!/usr/bin/env python3
"""mesh_props.py: draws Gullhaven's see-through harbour props straight onto the art grid.

Why (owner's art review, Oct 2026): the lobster pots and net piles are 20-29 art px tall, so an
AI source's rope mesh (holes a few source px wide) averages into speckle when it is reduced to the
grid, and the props read as "a pile of chests" / "a pile of sand". A cage or a net only reads when
every rope line and every hole is a whole art pixel, so these four sprites are drawn here, pixel by
pixel, from palette colours (tools/palette.json), at the same sizes as before (width = footprint
+ 2, HarbourStage obstacle radii 12 / 15 and 14 / 18).

Usage (from the repo root):
    python3 tools/mesh_props.py            # writes the four sprites below
    python3 tools/mesh_props.py --out DIR  # writes them to DIR instead (review)

Outputs: assets/sprites/obstacles/lobster_pots_s.png, lobster_pots_l.png, net_pile_s.png,
net_pile_l.png. Drawing is deterministic (no randomness), so a rerun reproduces the files.
"""
import argparse
import json
import math
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Where the sprites are written by default.
OUT_DIR = ROOT / "assets" / "sprites" / "obstacles"

# Palette colours used, by palette.json name (the only colours these sprites may hold).
COLOR_NAMES = ["ink_warm", "brown", "brown_light", "bone_shade", "bone_mid", "bone",
               "drowned_dark", "drowned", "drowned_light"]

# Sprite key -> (width, height) in art px, the sizes of the sprites they replace.
SIZES = {
    "lobster_pots_s": (26, 20),
    "lobster_pots_l": (32, 25),
    "net_pile_s": (30, 23),
    "net_pile_l": (38, 29),
}

# Lobster pot: spacing of the rope mesh lines (art px; 3 = 2 px holes between 1 px ropes).
POT_MESH = 3
# Lobster pot: every this-many mesh columns is a wooden hoop instead of rope.
POT_HOOP_EVERY = 2
# Lobster pot: height of the flat wooden base board (art px).
POT_BASE = 2
# Net pile: spacing of the diamond mesh diagonals (art px; 6 = 5 px diamond holes, the smallest
# that still reads as a net, not a dither, at 23-29 px; 4 and 5 were tried in review).
NET_MESH = 6
# Net pile: number of folds (darker bands) across the heap.
NET_FOLDS = 2
# Net pile: cork float diameter (art px).
CORK = 3


def palette() -> dict:
    """Name -> (r, g, b, 255) for COLOR_NAMES, read from tools/palette.json."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    hexes = {c["name"]: c["hex"] for c in data["colors"]}
    return {n: tuple(int(hexes[n][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for n in COLOR_NAMES}


def outline(img: Image.Image, ink: tuple) -> None:
    """Paints every transparent pixel that touches an opaque one (4-neighbour) with `ink`."""
    w, h = img.size
    px = img.load()
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and px[nx, ny] != ink:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = ink


def draw_pot(img: Image.Image, x0: int, y0: int, w: int, h: int, pal: dict) -> None:
    """One lobster trap (a loaf-shaped cage on a base board) with its box at (x0, y0), w x h px
    INSIDE the outline: dark see-through inside, a rope grid, every other column a wooden hoop,
    lit from the top-left (lit ropes bone, shaded ropes bone_shade)."""
    px = img.load()
    body = h - POT_BASE  # Rows of the cage above the base board.
    r = max(2, body // 2)  # Corner radius of the loaf's rounded top (art px).
    for yy in range(h):
        for xx in range(w):
            if yy < body:
                # Rounded top corners: outside the corner circles is empty.
                cx = r if xx < r else (w - 1 - r if xx > w - 1 - r else xx)
                if yy < r and math.hypot(xx - cx, yy - r) > r + 0.25:
                    continue
                lit = xx + yy < (w + body) * 0.45  # Top-left half of the cage catches the light.
                col_line = (xx % POT_MESH) == 1  # A vertical rope / hoop column.
                row_line = (yy % POT_MESH) == 1 or yy == 0  # A horizontal rope row (top rope included).
                hoop = col_line and (xx // POT_MESH) % POT_HOOP_EVERY == 0
                if hoop:
                    c = pal["brown_light"] if lit else pal["brown"]
                elif col_line or row_line:
                    c = pal["bone"] if lit else pal["bone_shade"]
                else:
                    c = pal["ink_warm"] if yy > 1 else pal["brown"]  # The dark inside, seen through the holes.
                if xx in (0, w - 1) and not row_line:
                    c = pal["brown"]  # The end hoops frame the cage.
            else:
                c = pal["brown_light"] if yy == body else pal["brown"]  # Base board, lit top edge.
            px[x0 + xx, y0 + yy] = c


def lobster_pots(size: tuple, pal: dict) -> Image.Image:
    """A stack of three traps: two side by side on the ground, one on top, centred."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    pw = (w - 3) // 2  # Width of a bottom trap inside its outline (1 px outline each side, 1 px shared gap).
    ph = (h - 3) // 2 + 1  # Height of a trap inside its outline.
    top_w = pw - 2  # The top trap is a little smaller (further away, sits in the groove).
    yb = h - 1 - ph  # Top row of the bottom traps.
    draw_pot(img, 1, yb, pw, ph, pal)
    draw_pot(img, w - 1 - pw, yb, pw, ph, pal)
    draw_pot(img, (w - top_w) // 2, max(1, yb - ph + 2), top_w, ph - 1, pal)
    # A pale rope coil on the top trap's roof (2 px, lit).
    cx = w // 2
    img.load()[cx - 1, max(0, yb - ph + 2)] = pal["bone"]
    img.load()[cx, max(0, yb - ph + 2)] = pal["bone_mid"]
    outline(img, pal["ink_warm"])
    return img


def net_pile(size: tuple, pal: dict) -> Image.Image:
    """A heap of fishing net: a mound filled with a diamond rope mesh (dark holes), scalloped
    hanging loops along its foot, darker fold bands, a string of cork floats and one glass float."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    cx = (w - 1) / 2.0  # Mound centre column.
    rx, ry = (w - 2) / 2.0, h - 2.5  # Mound half-width and height (inside the outline).
    base = h - 2  # Bottom row of the mound.
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            dx = (x - cx) / rx
            dy = (base - y) / ry
            if dx * dx + dy * dy > 1.0:
                continue
            # Scalloped foot: the hanging loops leave a notch every NET_MESH columns.
            if y == base and x % NET_MESH == 0:
                continue
            on_line = (x + y) % NET_MESH == 0 or (x - y) % NET_MESH == 0  # A rope of the diamond mesh.
            lit = (x - cx) + (base - y) * 0.6 < rx * 0.35 and y < base - ry * 0.25  # Top-left of the heap.
            # Fold bands: darker ropes along a few arcs across the heap.
            fold = any(abs((y - base + ry * (k + 1) / (NET_FOLDS + 1)) + 0.12 * (x - cx) * (1 if k % 2 else -1)) < 0.8
                       for k in range(NET_FOLDS))
            if on_line:
                c = pal["bone_shade"] if fold else (pal["bone"] if lit else pal["bone_mid"])
            else:
                # The lower folds seen through the holes: lit on the heap's top-left, dark elsewhere.
                c = pal["brown"] if (lit and not fold) else pal["ink_warm"]
            px[x, y] = c
    # Cork floats strung along one rope across the heap (brown_light with a brown shade).
    for i in range(3):
        fx = int(cx - rx * 0.55 + i * rx * 0.45)
        fy = int(base - ry * (0.55 - 0.12 * i))
        for yy in range(CORK):
            for xx in range(CORK):
                if 0 <= fx + xx < w and 0 <= fy + yy < h and px[fx + xx, fy + yy][3]:
                    px[fx + xx, fy + yy] = pal["brown_light"] if xx + yy < CORK else pal["brown"]
    # One glass float, drowned teal with a lit glint, low on the right.
    gx, gy = int(cx + rx * 0.45), int(base - ry * 0.35)
    for yy in range(CORK + 1):
        for xx in range(CORK + 1):
            if (xx, yy) in ((0, 0), (CORK, 0), (0, CORK), (CORK, CORK)):
                continue
            if 0 <= gx + xx < w and 0 <= gy + yy < h and px[gx + xx, gy + yy][3]:
                px[gx + xx, gy + yy] = pal["drowned"] if xx + yy > 1 else pal["drowned_light"]
    outline(img, pal["ink_warm"])
    return img


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="", help="output folder (default assets/sprites/obstacles)")
    args = ap.parse_args()
    out = Path(args.out) if args.out else OUT_DIR
    out.mkdir(parents=True, exist_ok=True)
    pal = palette()
    for key, size in SIZES.items():
        img = lobster_pots(size, pal) if key.startswith("lobster") else net_pile(size, pal)
        img.save(out / (key + ".png"), optimize=True)
        print(f"obstacles/{key}: {size[0]}x{size[1]} -> {out / (key + '.png')}")


if __name__ == "__main__":
    main()
