#!/usr/bin/env python3
"""chest_beacon_art.py: draws the chest beacon's two markers straight onto the art grid.

Why (owner request, Oct 2026: "Chests are a bit hard to see, can we add an indicator that sits
above them"): the beacon is two tiny shapes, a down-pointing chevron over every chest on screen
and a round badge on the screen edge for every chest off screen (ChestBeacon, ChestArrows,
GDD §15.0 "Chest beacon"). Shapes this small read best when every edge is a whole art pixel, so
they are drawn here pixel by pixel from palette colours (tools/palette.json), like
tools/mesh_props.py, instead of being generated: gold (the chest's colour in the UI colour
language), a gold_light rim on the top-left, a brown_light shade on the bottom-right, one
holy_white glint, and a solid ink_warm outline (8-neighbour) so they read on the light Sanctum
floors as well as on the near-black Graveyard soil.

Usage (from the repo root):
    python3 tools/chest_beacon_art.py            # writes the two sprites below
    python3 tools/chest_beacon_art.py --out DIR  # writes them to DIR instead (review)

Outputs: assets/sprites/markers/chest_beacon.png (19 x 15), assets/sprites/markers/chest_badge.png
(21 x 21). Drawing is deterministic (no randomness), so a rerun reproduces the files.
"""
import argparse
import json
import math
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Where the sprites are written by default.
OUT_DIR = ROOT / "assets" / "sprites" / "markers"

# Palette colours used, by palette.json name (the only colours these sprites may hold).
COLOR_NAMES = ["ink_warm", "brown", "brown_light", "gold", "gold_light", "holy_white"]

# Chevron size (art px, outline included): wide enough to read at Normal zoom over a 32 px chest.
CHEVRON_SIZE = (19, 15)
# Chevron: half-width of the outer triangle's top edge inside the outline (art px).
CHEVRON_HALF = 8.0
# Chevron: row of the outer triangle's top edge and of its bottom point (inside the outline).
CHEVRON_TOP, CHEVRON_TIP = 1, 13
# Chevron: row of the notch's bottom point (the notch cut from the top makes the V; art px).
CHEVRON_NOTCH = 7

# Badge size (art px, outline included): a round plate with a little chest in it.
BADGE_SIZE = (21, 21)
# Badge: outer radius of the gold ring and inner radius of its dark plate (art px, from the centre).
BADGE_RING_OUT, BADGE_RING_IN = 9.6, 7.4


def palette() -> dict:
    """Name -> (r, g, b, 255) for COLOR_NAMES, read from tools/palette.json."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    hexes = {c["name"]: c["hex"] for c in data["colors"]}
    return {n: tuple(int(hexes[n][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for n in COLOR_NAMES}


def outline(img: Image.Image, ink: tuple) -> None:
    """Paints every transparent pixel that touches an opaque one (8-neighbour) with `ink`: a solid
    dark rim, corners included, so the shape keeps its edge on light floors."""
    w, h = img.size
    px = img.load()
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3]:
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if (dx or dy) and 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and px[nx, ny] != ink:
                        edge.append((x, y))
                        break
                else:
                    continue
                break
    for x, y in edge:
        px[x, y] = ink


def shade_edges(img: Image.Image, mask: set, pal: dict) -> None:
    """Lights the top-left edge of `mask` (gold_light) and shades its bottom-right edge
    (brown_light): light comes from the top-left (ART_BIBLE "Outline and rim")."""
    px = img.load()
    for (x, y) in mask:
        if (x - 1, y) not in mask or (x, y - 1) not in mask:
            px[x, y] = pal["gold_light"]
        elif (x + 1, y) not in mask or (x, y + 1) not in mask:
            px[x, y] = pal["brown_light"]


def chevron(pal: dict) -> Image.Image:
    """The on-screen beacon: a thick gold V pointing down at the chest below it."""
    w, h = CHEVRON_SIZE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = (w - 1) / 2.0  # Centre column (8).
    slope = CHEVRON_HALF / float(CHEVRON_TIP - CHEVRON_TOP)  # Half-width lost per row (art px).
    mask = set()
    for y in range(CHEVRON_TOP, CHEVRON_TIP + 1):
        for x in range(1, w - 1):
            outer = abs(x - cx) <= (CHEVRON_TIP - y) * slope + 0.01
            notch = abs(x - cx) <= (CHEVRON_NOTCH - y) * slope - 0.3
            if outer and not notch:
                mask.add((x, y))
                px[x, y] = pal["gold"]
    shade_edges(img, mask, pal)
    px[3, 2] = pal["holy_white"]  # One glint on the lit left arm.
    outline(img, pal["ink_warm"])
    return img


def badge(pal: dict) -> Image.Image:
    """The off-screen badge: a gold ring round a dark plate holding a little gold chest (lid,
    band and keyhole). Drawn upright; the code adds the pointer that turns toward the chest."""
    w, h = BADGE_SIZE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    c = (w - 1) / 2.0  # Centre (10, 10).
    ring = set()
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - c, y - c)
            if d <= BADGE_RING_IN:
                px[x, y] = pal["ink_warm"] if d > BADGE_RING_IN - 1.2 else pal["brown"]
            elif d <= BADGE_RING_OUT:
                ring.add((x, y))
                px[x, y] = pal["gold"]
    # Ring light: the top-left half of the ring lit, the bottom-right shaded.
    for (x, y) in ring:
        side = (x - c) + (y - c)  # < 0 toward the top-left.
        outer = math.hypot(x - c, y - c) > (BADGE_RING_OUT + BADGE_RING_IN) / 2.0
        if side < -4 and outer:
            px[x, y] = pal["gold_light"]
        elif side > 4 and not outer:
            px[x, y] = pal["brown_light"]
    # The little chest: 9 x 7 inside the plate (lid rows 6-8, band row 9, body rows 10-12).
    x0, y0 = 6, 6
    chest = set()
    for yy in range(7):
        for xx in range(9):
            if yy == 0 and xx in (0, 8):
                continue  # Rounded lid corners.
            chest.add((x0 + xx, y0 + yy))
            px[x0 + xx, y0 + yy] = pal["gold"]
    shade_edges(img, chest, pal)
    for xx in range(9):
        px[x0 + xx, y0 + 3] = pal["brown_light"]  # The lid's seam / iron band.
    px[x0 + 4, y0 + 3] = pal["ink_warm"]  # Lock plate keyhole.
    px[x0 + 4, y0 + 4] = pal["ink_warm"]
    px[x0 + 1, y0 + 1] = pal["holy_white"]  # Glint on the lid.
    outline(img, pal["ink_warm"])
    return img


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="", help="output folder (default assets/sprites/markers)")
    args = ap.parse_args()
    out = Path(args.out) if args.out else OUT_DIR
    out.mkdir(parents=True, exist_ok=True)
    pal = palette()
    for key, img in (("chest_beacon", chevron(pal)), ("chest_badge", badge(pal))):
        img.save(out / (key + ".png"), optimize=True)
        print(f"markers/{key}: {img.size[0]}x{img.size[1]} -> {out / (key + '.png')}")


if __name__ == "__main__":
    main()
