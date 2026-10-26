#!/usr/bin/env python3
"""olympus_props.py: draws Mount Olympus's obstacle sprites straight onto the art grid.

Why (Act IV phase 2, GDD 15.0 "Mount Olympus (Act IV phase 2)"): the mountain's props are marble
columns, blocks, balustrades, a fountain basin, bronze braziers, war trophies, wrecked chariots and
dark cypress trees. Their hard geometry (column flutes, balusters, a basin rim) is what an AI source
loses when it is reduced to the grid, and the rect kinds need a matching vertical drawing (a long
side along y) that one three-quarter source cannot give; so, like tools/assembly_props.py, every
prop is drawn here pixel by pixel from palette colours (tools/palette.json: the Act IV ramps
bronze, marble, aegean, gold, plus moss and brown), in the three-quarter view of the game's art (a
lighter top over a front face, light from the top-left, a 1 px ink outline), at the exact sizes of
OlympusStage.ZONES:
    circle kinds  width = 2 x radius + 2 art px (the footprint plus the outline)
    rect kinds    width = long side + 4 (horizontal) or short side + 2 (vertical, "_v")
Outputs: assets/sprites/obstacles/<kind>_<s|m|l>[_v].png (EnvironmentArtData key scheme). Drawing
is deterministic (no randomness), so a rerun reproduces the files. No API image.

Usage (from the repo root):
    python3 tools/olympus_props.py            # writes every sprite
    python3 tools/olympus_props.py --out DIR  # writes them to DIR instead (review)
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

# Circle kinds: kind -> footprint radii (px) of its sizes, smallest first (OlympusStage.ZONES).
CIRCLES = {
    "war_trophy": [11, 14, 17],
    "cypress": [12, 15, 18],
    "moon_shrine": [13, 16],
    "fountain": [15, 19],
    "broken_column": [11, 14, 18],
    "bronze_brazier": [9, 11],
}
# Rect kinds: kind -> (long sides of its sizes, short side) in px (OlympusStage.ZONES).
RECTS = {
    "chariot_wreck": ([44, 60], 24),
    "balustrade": ([52, 70, 86], 18),
    "marble_block": ([40, 56, 72], 26),
}
# Size suffixes by the number of sizes (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES).
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
# Height of a box's front face as a fraction of its footprint's short side (the 3/4 view).
FRONT = {"chariot_wreck": 0.9, "balustrade": 1.5, "marble_block": 0.8}
# Squash of a box's top face (footprint depth drawn this fraction tall).
TOP_SQUASH = 0.6


def palette() -> dict:
    """Name -> (r, g, b, 255) for every palette colour (tools/palette.json)."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    return {c["name"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in data["colors"]}


P = palette()


def rect(px, w, h, x0, y0, x1, y1, col):
    """Fills the inclusive rect (x0, y0)-(x1, y1) with `col` (clipped)."""
    for y in range(max(0, int(y0)), min(h, int(y1) + 1)):
        for x in range(max(0, int(x0)), min(w, int(x1) + 1)):
            px[x, y] = col


def ellipse(px, w, h, cx, cy, rx, ry, col):
    """Fills the ellipse centred (cx, cy) with radii rx, ry (art px) with `col`."""
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / max(rx, 0.5)
            dy = (y + 0.5 - cy) / max(ry, 0.5)
            if dx * dx + dy * dy <= 1.0:
                px[x, y] = col


def line(px, w, h, ax, ay, bx, by, col, r=0):
    """Draws a line from (ax, ay) to (bx, by), `r` px thick on each side."""
    steps = int(max(abs(bx - ax), abs(by - ay))) or 1
    for s in range(steps + 1):
        x = round(ax + (bx - ax) * s / steps)
        y = round(ay + (by - ay) * s / steps)
        rect(px, w, h, x - r, y - r, x + r, y + r, col)


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
    ink = P["bronze_ink"]
    if kind == "marble_block":
        # A fallen block of temple marble: a pale top, a shaded front, a crack and a gold inlay band.
        rect(px, w, h, x0, ty0, x1, ty1, P["marble_light"])
        rect(px, w, h, x0, fy0, x1, fy1, P["marble"])
        rect(px, w, h, x0, fy1 - 1, x1, fy1, P["marble_dark"])
        rect(px, w, h, x0, fy0 + 2, x1, fy0 + 2, P["gold"])
        cx = x0 + (x1 - x0) * 2 // 3
        line(px, w, h, cx, ty0 + 1, cx - 2, fy0 + 1, P["marble_dark"])
        line(px, w, h, cx - 2, fy0 + 3, cx + 1, fy1 - 2, P["marble_dark"])
    elif kind == "balustrade":
        # A terrace balustrade: a top rail, balusters with dark gaps, a plinth.
        rect(px, w, h, x0, ty0, x1, ty1, P["marble_light"])
        rect(px, w, h, x0, fy0, x1, fy0 + 1, P["marble"])
        rect(px, w, h, x0, fy1 - 1, x1, fy1, P["marble_dark"])
        if not vertical:
            for x in range(x0 + 1, x1, 4):
                rect(px, w, h, x, fy0 + 2, x + 1, fy1 - 2, P["marble"])
                rect(px, w, h, x + 2, fy0 + 2, x + 2, fy1 - 2, P["marble_dark"])
                rect(px, w, h, x + 3, fy0 + 2, x + 3, fy1 - 2, ink if x + 3 < x1 else P["marble"])
        else:
            rect(px, w, h, x0, fy0 + 2, x1, fy1 - 2, P["marble"])
            for y in range(ty0 + 2, ty1, 4):
                rect(px, w, h, x0 + 2, y, x1 - 2, y, P["marble_dark"])
    else:  # chariot_wreck
        # A war chariot on its side: a bronze car, a broken wheel, a snapped pole.
        rect(px, w, h, x0, ty0, x1, ty1, P["bronze_light"])
        rect(px, w, h, x0, fy0, x1, fy1, P["bronze"])
        rect(px, w, h, x0, fy1 - 1, x1, fy1, P["bronze_dark"])
        rect(px, w, h, x0 + 2, fy0 + 2, x1 - 2, fy0 + 2, P["aegean"])
        if not vertical:
            wr = max(4, (fy1 - fy0) // 2)
            wx, wy = x0 + wr + 2, fy0 + wr
            ellipse(px, w, h, wx, wy, wr, wr, P["brown"])
            ellipse(px, w, h, wx, wy, wr - 2, wr - 2, P["bronze_dark"])
            for a in range(4):
                ang = a * math.pi / 4
                line(px, w, h, wx - math.cos(ang) * (wr - 1), wy - math.sin(ang) * (wr - 1),
                     wx + math.cos(ang) * (wr - 1), wy + math.sin(ang) * (wr - 1), P["brown_light"])
            line(px, w, h, x1 - 2, ty0 + 2, x1 - (x1 - x0) // 3, ty1, P["brown"], 1)
        else:
            wr = max(3, (x1 - x0) // 3)
            ellipse(px, w, h, (x0 + x1) / 2, fy1 - wr, wr, wr, P["brown"])
            ellipse(px, w, h, (x0 + x1) / 2, fy1 - wr, wr - 2, wr - 2, P["bronze_dark"])
    outline(img, ink)
    return img


def column(r, broken=True):
    """A broken fluted marble column on a round footing (radius `r` px)."""
    w = 2 * r + 2
    ry = max(3, round(r * 0.45))
    shaft = round(r * 1.9)
    h = shaft + 2 * ry + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    base_y = h - 2 - ry
    ellipse(px, w, h, cx, base_y, r, ry, P["marble_dark"])  # The footing.
    sr = max(3, round(r * 0.72))  # Shaft radius.
    top_y = base_y - shaft
    rect(px, w, h, cx - sr, top_y, cx + sr - 1, base_y, P["marble"])
    for k in range(-sr + 1, sr - 1, 3):  # Flutes.
        rect(px, w, h, cx + k, top_y + 2, cx + k, base_y - 1, P["marble_dark"])
    rect(px, w, h, cx - sr, top_y, cx - sr + 1, base_y, P["marble_light"])
    if broken:  # A jagged break on top.
        for i, x in enumerate(range(int(cx - sr), int(cx + sr))):
            cut = (i * 5) % 4
            rect(px, w, h, x, top_y - 1, x, top_y + cut - 1, (0, 0, 0, 0))
        ellipse(px, w, h, cx, top_y + 2, sr - 1, max(1, ry - 2), P["marble_light"])
    rect(px, w, h, cx - sr - 1, base_y - 2, cx + sr, base_y, P["marble_light"])  # The base moulding.
    rect(px, w, h, cx - sr - 1, base_y, cx + sr, base_y, P["gold"])
    outline(img, P["bronze_ink"])
    return img


def brazier(r):
    """A bronze brazier on three legs with a fire bowl (radius `r` px)."""
    w = 2 * r + 2
    ry = max(2, round(r * 0.45))
    legs = round(r * 1.3)
    flame = round(r * 1.3)
    h = flame + 2 * ry + legs + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    bowl_y = flame + ry + 1
    for dx in (-r + 2, 0, r - 3):  # The legs.
        line(px, w, h, cx + dx * 0.5, bowl_y, cx + dx, h - 2, P["bronze_dark"])
    ellipse(px, w, h, cx, bowl_y + 1, r, ry + 1, P["bronze"])
    ellipse(px, w, h, cx, bowl_y, r - 1, ry, P["bronze_light"])
    ellipse(px, w, h, cx, bowl_y, r - 2, max(1, ry - 1), P["ink_red"])
    for i in range(3):  # Flame tongues.
        fx = cx - r * 0.5 + i * r * 0.5
        top = flame * (0.5 + 0.25 * ((i + 1) % 2))
        line(px, w, h, fx, bowl_y, fx, bowl_y - top, P["flame"], 1)
        line(px, w, h, fx, bowl_y - 1, fx, bowl_y - top * 0.6, P["gold_light"])
    outline(img, P["bronze_ink"])
    return img


def war_trophy(r):
    """A trophy of captured arms: a post with a crested helmet, a round shield and crossed spears."""
    w = 2 * r + 2
    ry = max(2, round(r * 0.4))
    tall = round(r * 3.0)
    h = tall + ry * 2 + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    base_y = h - 2 - ry
    ellipse(px, w, h, cx, base_y, r - 1, ry, P["brown"])  # The cairn of earth at its foot.
    reach = r - 5  # Half the spread of the shafts' upper ends (px): room for the heads inside the canvas.
    line(px, w, h, cx - reach, base_y - tall * 0.8, cx + r - 2, base_y - 2, P["brown_light"])  # Crossed spears.
    line(px, w, h, cx + reach, base_y - tall * 0.8, cx - r + 2, base_y - 2, P["brown_light"])
    for sx in (-1, 1):  # A bronze leaf head on each spear's upper end (owner's art review, round 1).
        ax, ay = cx - sx * (r - 2), base_y - 2  # Butt.
        bx, by = cx + sx * reach, base_y - tall * 0.8  # Upper end of the shaft.
        ln = math.hypot(bx - ax, by - ay)
        ux, uy = (bx - ax) / ln, (by - ay) / ln  # Unit vector along the shaft, upward.
        head = max(4, round(r * 0.35))  # Head length (px).
        line(px, w, h, bx + ux, by + uy, bx + ux * (head - 1), by + uy * (head - 1), P["bronze"], 1)  # The leaf.
        line(px, w, h, bx + ux, by + uy, bx + ux * (head - 1), by + uy * (head - 1), P["bronze_light"])  # Its lit spine.
        line(px, w, h, bx + ux * head, by + uy * head, bx + ux * (head + 1), by + uy * (head + 1), P["bronze_light"])  # The point.
    rect(px, w, h, cx - 1, base_y - tall, cx, base_y, P["brown"])  # The post.
    sr = max(4, round(r * 0.75))
    sy = base_y - tall * 0.45
    ellipse(px, w, h, cx, sy, sr, sr, P["bronze"])  # The shield.
    ellipse(px, w, h, cx - 1, sy - 1, sr - 2, sr - 2, P["bronze_light"])
    ellipse(px, w, h, cx, sy, max(1, sr // 3), max(1, sr // 3), P["aegean"])
    hy = base_y - tall + 2
    ellipse(px, w, h, cx, hy + 2, max(3, r // 3), max(3, r // 3), P["bronze"])  # The helmet.
    rect(px, w, h, cx - 1, hy + 2, cx, hy + 3, P["bronze_ink"])
    rect(px, w, h, cx - max(3, r // 3), hy - 1, cx + max(2, r // 3) - 1, hy, P["aegean"])  # Its crest.
    outline(img, P["bronze_ink"])
    return img


def cypress(r):
    """A dark cypress: a tall flame-shaped crown of layered green over a short trunk."""
    w = 2 * r + 2
    tall = round(r * 4.0)
    h = tall + 4
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    base = h - 2
    rect(px, w, h, cx - 1, base - 4, cx, base, P["brown"])
    for y in range(2, base - 3):
        t = (y - 2) / max(1, base - 5)  # 0 at the tip, 1 at the bottom.
        half = r * (0.25 + 0.75 * math.sin(min(1.0, t * 1.15) * math.pi / 2)) * (1.0 if t < 0.9 else 0.8)
        for x in range(int(cx - half), int(cx + half) + 1):
            band = (y + int(abs(x - cx))) % 6
            col = P["moss"] if x < cx - half * 0.3 and band < 3 else (P["moss_dark"] if band != 5 else P["ink_green"])
            if 0 <= x < w:
                px[x, y] = col
    outline(img, P["ink_green"])
    return img


def moon_shrine(r):
    """A small round marble shrine: a stepped plinth and a short pillar topped by a silver crescent."""
    w = 2 * r + 2
    ry = max(3, round(r * 0.45))
    tall = round(r * 1.8)
    h = tall + 2 * ry + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    base_y = h - 2 - ry
    ellipse(px, w, h, cx, base_y, r, ry, P["marble_dark"])
    ellipse(px, w, h, cx, base_y - 2, r - 2, max(1, ry - 1), P["marble"])
    pr = max(2, round(r * 0.3))
    top = base_y - tall
    rect(px, w, h, cx - pr, top + pr * 2, cx + pr - 1, base_y - 2, P["marble"])
    rect(px, w, h, cx - pr, top + pr * 2, cx - pr, base_y - 2, P["marble_light"])
    cr = max(3, round(r * 0.45))  # The crescent.
    # The crescent a shade lighter than the marble (owner's art review, round 1): the palette's
    # palest silver, so it no longer reads as the same stone as the pillar under it.
    ellipse(px, w, h, cx, top + cr, cr, cr, P["ice_light"])
    ellipse(px, w, h, cx + cr * 0.45, top + cr - 1, cr * 0.8, cr * 0.8, (0, 0, 0, 0))
    ellipse(px, w, h, cx, top + cr * 2 + 1, 1, 1, P["aegean_light"])
    outline(img, P["bronze_ink"])
    return img


def fountain(r):
    """A round marble fountain basin full of water, a short spout in its middle."""
    w = 2 * r + 2
    ry = max(4, round(r * 0.5))
    wall = max(4, round(r * 0.45))
    spout = round(r * 0.9)
    h = spout + 2 * ry + wall + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx = w / 2.0
    top_y = spout + ry + 1
    rect(px, w, h, 1, top_y, w - 2, top_y + wall, P["marble"])
    ellipse(px, w, h, cx, top_y + wall, r, ry, P["marble_dark"])
    rect(px, w, h, 1, top_y, w - 2, top_y + wall - 1, P["marble"])
    ellipse(px, w, h, cx, top_y, r, ry, P["marble_light"])
    ellipse(px, w, h, cx, top_y, r - 2, ry - 1, P["aegean"])
    ellipse(px, w, h, cx - 2, top_y - 1, r - 5, max(1, ry - 3), P["aegean_light"])
    rect(px, w, h, cx - 1, top_y - spout, cx, top_y, P["marble_light"])  # The spout.
    line(px, w, h, cx + 1, top_y - spout, cx + 3, top_y - spout + 3, P["aegean_light"])
    line(px, w, h, cx - 2, top_y - spout, cx - 4, top_y - spout + 3, P["aegean_light"])
    outline(img, P["bronze_ink"])
    return img


DRAW = {"war_trophy": war_trophy, "cypress": cypress, "moon_shrine": moon_shrine, "fountain": fountain,
        "broken_column": column, "bronze_brazier": brazier}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(OUT_DIR), help="output folder")
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for kind, radii in CIRCLES.items():
        for i, r in enumerate(radii):
            DRAW[kind](r).save(out / ("%s_%s.png" % (kind, SUFFIXES[len(radii)][i])))
            n += 1
    for kind, (longs, short) in RECTS.items():
        for i, ln in enumerate(longs):
            suf = SUFFIXES[len(longs)][i]
            box(kind, ln + 2, short, False).save(out / ("%s_%s.png" % (kind, suf)))
            box(kind, short, ln, True).save(out / ("%s_%s_v.png" % (kind, suf)))
            n += 2
    print("wrote %d sprites to %s" % (n, out))


if __name__ == "__main__":
    main()
