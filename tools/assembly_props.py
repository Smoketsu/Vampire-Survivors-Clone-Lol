#!/usr/bin/env python3
"""assembly_props.py: draws the Assembly Halls' obstacle sprites straight onto the art grid.

Why (Act III phase 2, GDD 15.0 "The Assembly Halls (Act III phase 2)"): the factory's props are
machine-made boxes and drums with flat panels, rivets and hazard stripes. Such hard geometry is
exactly what an AI source loses when it is reduced to the grid (panel seams and stripes average into
speckle), and the rect kinds need a matching vertical drawing (a long side along y) that a single
three-quarter source cannot give. So every prop is drawn here, pixel by pixel, from palette colours
(tools/palette.json), in the three-quarter view of the game's art (a lighter top face over a front
face, light from the top-left, a 1 px ink outline), at the exact sizes of AssemblyStage.ZONES:
    circle kinds  width = 2 x radius + 2 art px (the footprint plus the outline)
    rect kinds    width = long side + 4 (horizontal) or short side + 2 (vertical, "_v")
Outputs: assets/sprites/obstacles/<kind>_<s|l>[_v].png (EnvironmentArtData key scheme). Drawing is
deterministic (no randomness), so a rerun reproduces the files.

Usage (from the repo root):
    python3 tools/assembly_props.py            # writes every sprite
    python3 tools/assembly_props.py --out DIR  # writes them to DIR instead (review)
"""
import argparse
import json
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Where the sprites are written by default.
OUT_DIR = ROOT / "assets" / "sprites" / "obstacles"

# Circle kinds: kind -> radii (px) of its two sizes (AssemblyStage.ZONES).
CIRCLES = {
    "fuel_drum": [10, 13],
    "parts_bin": [13, 16],
    "robot_arm": [14, 18],
    "crucible": [16, 20],
}
# Rect kinds: kind -> (long sides of its two sizes, short side) in px (AssemblyStage.ZONES).
RECTS = {
    "cargo_crate": ([44, 60], 30),
    "press_machine": ([40, 52], 32),
    "servo_cabinet": ([36, 48], 26),
    "ingot_stack": ([40, 52], 26),
}
# Size suffixes, smallest first (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES for two sizes).
SUFFIXES = ["s", "l"]
# Height of a box's front face as a fraction of its footprint's short side (the 3/4 view).
FRONT = {"cargo_crate": 0.9, "press_machine": 1.1, "servo_cabinet": 1.3, "ingot_stack": 0.6}
# Squash of a box's top face (footprint depth drawn this fraction tall).
TOP_SQUASH = 0.6
# Height of a drum's body as a fraction of its radius.
DRUM_BODY = {"fuel_drum": 1.5, "parts_bin": 0.9, "robot_arm": 0.7, "crucible": 1.0}


def palette() -> dict:
    """Name -> (r, g, b, 255) for every palette colour (tools/palette.json)."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    return {c["name"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in data["colors"]}


P = palette()


def rect(px, w, h, x0, y0, x1, y1, col):
    """Fills the inclusive rect (x0, y0)-(x1, y1) with `col` (clipped)."""
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(max(0, x0), min(w, x1 + 1)):
            px[x, y] = col


def ellipse(px, w, h, cx, cy, rx, ry, col):
    """Fills the ellipse centred (cx, cy) with radii rx, ry (art px) with `col`."""
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / max(rx, 0.5)
            dy = (y + 0.5 - cy) / max(ry, 0.5)
            if dx * dx + dy * dy <= 1.0:
                px[x, y] = col


def outline(img, ink):
    """Paints every transparent pixel touching an opaque one (4-neighbour) with `ink`."""
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


def box(kind, fw, fd, vertical):
    """A box prop with footprint fw x fd (px, x by y) in the 3/4 view: top face over a front face."""
    short = min(fw, fd)
    front = max(6, round(short * FRONT[kind]))
    top = max(4, round(fd * TOP_SQUASH))
    w, h = fw + 2, top + front + 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    x0, x1 = 1, w - 2
    ty0, ty1 = 1, top
    fy0, fy1 = top + 1, h - 2
    if kind == "cargo_crate":
        topc, frontc, dark, accent = P["brown_light"], P["brown"], P["ink_warm"], P["signal_amber"]
        rect(px, w, h, x0, ty0, x1, ty1, topc)
        rect(px, w, h, x0, fy0, x1, fy1, frontc)
        # Corrugation ribs on the front, chrome corner brackets, an amber stencil plate.
        step = 4
        for x in range(x0 + 3, x1 - 2, step):
            rect(px, w, h, x, fy0 + 2, x, fy1 - 2, dark)
        for cx in (x0, x1 - 2):
            rect(px, w, h, cx, ty0, cx + 2, fy1, P["chrome"])
        rect(px, w, h, x0 + 3, ty0 + 1, x1 - 3, ty0 + 1, P["brown_light"])
        mx = (x0 + x1) // 2
        rect(px, w, h, mx - 3, fy0 + 3, mx + 3, fy0 + 5, accent)
    elif kind == "press_machine":
        rect(px, w, h, x0, ty0, x1, ty1, P["chrome"])
        rect(px, w, h, x0, fy0, x1, fy1, P["chrome_dark"])
        # The press ram (a darker block on top), two warning lights, hazard stripes at the base.
        mx, my = (x0 + x1) // 2, (ty0 + ty1) // 2
        rw, rh = max(3, (x1 - x0) // 4), max(2, (ty1 - ty0) // 3)
        rect(px, w, h, mx - rw, my - rh, mx + rw, my + rh, P["chrome_dark"])
        rect(px, w, h, mx - rw + 1, my - rh, mx + rw - 1, my - rh, P["chrome_light"])
        rect(px, w, h, x0 + 2, ty0 + 1, x0 + 3, ty0 + 2, P["signal_red"])
        rect(px, w, h, x1 - 3, ty0 + 1, x1 - 2, ty0 + 2, P["signal_amber"])
        for x in range(x0, x1 + 1):
            if ((x - x0) // 3) % 2 == 0:
                rect(px, w, h, x, fy1 - 2, x, fy1, P["signal_amber"])
            else:
                rect(px, w, h, x, fy1 - 2, x, fy1, P["ink_chrome"])
        rect(px, w, h, x0 + 2, fy0 + 2, x1 - 2, fy0 + 2, P["chrome"])
    elif kind == "servo_cabinet":
        rect(px, w, h, x0, ty0, x1, ty1, P["chrome_light"])
        rect(px, w, h, x0, fy0, x1, fy1, P["chrome"])
        # A screen with amber readout lines and vent slats under it.
        sx0, sx1 = x0 + 2, x1 - 2
        sy0, sy1 = fy0 + 2, fy0 + max(4, (fy1 - fy0) // 3)
        rect(px, w, h, sx0, sy0, sx1, sy1, P["ink_chrome"])
        for y in range(sy0 + 1, sy1, 2):
            rect(px, w, h, sx0 + 1, y, sx0 + 1 + ((y * 7) % max(2, sx1 - sx0 - 2)), y, P["signal_amber"])
        for y in range(sy1 + 3, fy1 - 1, 3):
            rect(px, w, h, x0 + 2, y, x1 - 2, y, P["chrome_dark"])
        rect(px, w, h, x1 - 3, ty0 + 1, x1 - 2, ty0 + 1, P["signal_red"])
    else:  # ingot_stack
        rect(px, w, h, x0, ty0, x1, fy1, P["steel_dark"])
        # Rows of steel ingots: a light top bevel on each bar.
        bar = 9 if not vertical else 7  # Ingot length (px) along the row.
        for y in range(ty0 + 1, fy1, 4):
            shift = ((y // 4) % 2) * (bar // 2)
            for x in range(x0 + 1 - shift, x1, bar + 1):
                xa, xb = max(x0 + 1, x), min(x1 - 1, x + bar - 1)
                if xb - xa < 2:
                    continue
                rect(px, w, h, xa, y, xb, min(fy1 - 1, y + 2), P["steel"])
                rect(px, w, h, xa, y, xb, y, P["steel_light"])
        rect(px, w, h, x0, fy1, x1, fy1, P["steel_dark"])
    # Rim light: the top-left edge one shade lighter (the top face's first row / column).
    outline(img, P["ink_chrome"])
    return img


def drum(kind, r):
    """A round prop of footprint radius `r` (px) in the 3/4 view."""
    w = 2 * r + 2
    ry = max(3, round(r * 0.5))
    body = max(4, round(r * DRUM_BODY[kind]))
    extra = round(r * 1.6) if kind == "robot_arm" else 0  # The arm rises above the base.
    h = extra + ry * 2 + body + 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    top_y = extra + 1 + ry
    cols = {
        "fuel_drum": (P["crimson_dark"], P["crimson"], P["chrome_light"]),
        "parts_bin": (P["chrome_dark"], P["chrome"], P["chrome_light"]),
        "robot_arm": (P["chrome_dark"], P["chrome"], P["chrome_light"]),
        "crucible": (P["steel_dark"], P["steel_dark"], P["steel"]),
    }[kind]
    side, topc, light = cols
    # Body: the side wall from the top ellipse down to the bottom ellipse.
    rect(px, w, h, 1, top_y, w - 2, top_y + body, side)
    ellipse(px, w, h, cx, top_y + body, r, ry, side)
    # Bands on the side.
    if kind == "fuel_drum":
        for by in (top_y + body // 3, top_y + 2 * body // 3):
            rect(px, w, h, 1, by, w - 2, by, P["chrome"])
    ellipse(px, w, h, cx, top_y, r, ry, topc)
    if kind == "fuel_drum":
        ellipse(px, w, h, cx, top_y, r - 2, ry - 1, P["crimson_dark"])
        ellipse(px, w, h, cx, top_y, max(1, r // 3), max(1, ry // 3), P["signal_amber"])
    elif kind == "parts_bin":
        ellipse(px, w, h, cx, top_y, r - 2, ry - 1, P["ink_chrome"])
        for i in range(5):
            bx = int(cx - r + 4 + (i * 5) % (2 * r - 6))
            by = int(top_y - ry // 2 + (i * 3) % max(1, ry))
            rect(px, w, h, bx, by, bx + 1, by, light)
    elif kind == "crucible":
        ellipse(px, w, h, cx, top_y, r - 2, ry - 1, P["flame"])
        ellipse(px, w, h, cx, top_y, r - 5, max(1, ry - 2), P["signal_glow"])
        rect(px, w, h, 2, top_y + body // 2, w - 3, top_y + body // 2, P["steel"])
    else:  # robot_arm: a jointed arm rising from the round base, a claw and a red light.
        ellipse(px, w, h, cx, top_y, r - 3, ry - 1, P["chrome_dark"])
        jx, jy = int(cx), top_y
        ex, ey = int(cx - r * 0.35), int(1 + extra * 0.45)
        tx, ty = int(cx + r * 0.45), 2
        for (ax, ay, bx2, by2) in ((jx, jy, ex, ey), (ex, ey, tx, ty)):
            steps = max(abs(bx2 - ax), abs(by2 - ay)) or 1
            for s in range(steps + 1):
                x = round(ax + (bx2 - ax) * s / steps)
                y = round(ay + (by2 - ay) * s / steps)
                rect(px, w, h, x - 1, y - 1, x + 1, y + 1, P["chrome"])
        rect(px, w, h, ex - 2, ey - 2, ex + 2, ey + 2, P["chrome_light"])
        rect(px, w, h, ex - 1, ey - 1, ex, ey, P["signal_amber"])
        rect(px, w, h, tx - 3, ty, tx + 3, ty + 2, P["chrome_light"])
        rect(px, w, h, tx - 3, ty + 3, tx - 2, ty + 5, P["chrome"])
        rect(px, w, h, tx + 2, ty + 3, tx + 3, ty + 5, P["chrome"])
        rect(px, w, h, jx - 1, jy - 1, jx, jy, P["signal_red"])
    # Rim light on the top ellipse's upper-left edge.
    outline(img, P["ink_chrome"] if kind != "crucible" else P["ink_warm"])
    return img


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(OUT_DIR), help="output folder")
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for kind, radii in CIRCLES.items():
        for i, r in enumerate(radii):
            drum(kind, r).save(out / ("%s_%s.png" % (kind, SUFFIXES[i])))
            n += 1
    for kind, (longs, short) in RECTS.items():
        for i, ln in enumerate(longs):
            box(kind, ln + 2, short, False).save(out / ("%s_%s.png" % (kind, SUFFIXES[i])))
            box(kind, short, ln, True).save(out / ("%s_%s_v.png" % (kind, SUFFIXES[i])))
            n += 2
    print("wrote %d sprites to %s" % (n, out))


if __name__ == "__main__":
    main()
