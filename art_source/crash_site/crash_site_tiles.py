#!/usr/bin/env python3
"""crash_site_tiles.py: draws the Crash Site's floors and small effect pieces on the art grid (Act IX, Stage 25).

Why (ART_BIBLE "Act IX: the Crash Site"): a zone floor must tile with no seam and stay dark and flat (the floor rule), and
the egg, the mound and the puddle are tiny, so an AI source loses them when it is reduced to the grid. Everything is drawn
here pixel by pixel from Concord palette colours (tools/palette.json hexes), light from the top-left, with seeded noise
only (a rerun reproduces the files exactly).

Outputs (1 art px = 1 screen px; assets/sprites/):
  tiles/crash_site_crater.png    128 x 128 seamless: the Crater's glassed black rock, plates split by dark cracks (a wrapped
        Voronoi map), a few cooled-glass glints and a rare green plasma seam.
  tiles/crash_site_hatchery.png  128 x 128 seamless: the Hatchery's green-black resin over the paving, lumpy cells with
        lighter rims and a few acid-green spores.
  tiles/crash_site_wreck.png     128 x 128 seamless: the Wreck's buckled hull plates in 32 px courses, gunmetal seams,
        rivets, a scorch streak.
  tiles/crash_site_ruins.png     128 x 128 seamless: the Glass Spire's broken paving in 32 px slabs (rows offset), cracks
        and a few glass chips.
  concord/brood_egg.png          14 x 14: an Infestation egg, green-black shell, an acid-green vein, a resin smear at its
        foot (BroodEggKit pulses it by tint).
  concord/brood_egg_hatch.png    4 frames of 16 x 16 (64 x 16): the egg cracking open, the shell splitting, a claw out.
  concord/burrow_mound.png       28 x 16: a heap of loose brown dirt with clods (BurrowerKit.draw_mound() scales it).
  effects/acid_pool.png          32 x 26: a puddle as a GREY TINT MASK (white body, lighter bubbles, a soft rim), tinted
        acid green by AcidPools.
Usage (from the repo root):  python3 art_source/crash_site/crash_site_tiles.py [--out DIR]   (default: assets/sprites)
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image

# Repository root (this file lives in art_source/crash_site/).
ROOT = Path(__file__).resolve().parents[2]
# Palette colours used (the hexes of tools/palette.json and the Concord ramps), name -> (r, g, b).
C = {
    "ink": (0x07, 0x08, 0x0F), "td": (0x1A, 0x1C, 0x22), "gd": (0x1E, 0x24, 0x2C), "gm": (0x3A, 0x42, 0x4C),
    "hs": (0xAE, 0xB8, 0xC4), "pd": (0x1F, 0xA8, 0x4A), "p": (0x3C, 0xFF, 0x6A), "ch": (0x1B, 0x3A, 0x2A),
    "cl": (0x2E, 0x6B, 0x45), "hb": (0xE0, 0xD2, 0xB0), "br": (0x3A, 0x2C, 0x20), "bl": (0x5C, 0x46, 0x32),
    "bd": (0x24, 0x1A, 0x12),
}
# Floor tile size (px).
TILE = 128
# Seeds (one per output) so a rerun reproduces every file.
SEEDS = {"crater": 25, "hatchery": 26, "wreck": 27, "ruins": 28, "egg": 29, "pool": 30}


def blank(w: int, h: int) -> Image.Image:
    """A transparent RGBA canvas of w x h px."""
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def mix(a: tuple, b: tuple, t: float) -> tuple:
    """Colour a blended toward b by t (0..1), as an RGBA tuple (opaque)."""
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def voronoi(rng: random.Random, n: int) -> list:
    """n seed points in the tile (wrapped distances are taken by nearest())."""
    return [(rng.uniform(0, TILE), rng.uniform(0, TILE)) for _ in range(n)]


def nearest(pts: list, x: float, y: float) -> tuple:
    """(index of the nearest seed, distance to it, distance to the second nearest), wrapped around the tile."""
    best, second, bi = 1e9, 1e9, 0
    for i, (px, py) in enumerate(pts):
        dx = min(abs(x - px), TILE - abs(x - px))
        dy = min(abs(y - py), TILE - abs(y - py))
        d = math.hypot(dx, dy)
        if d < best:
            second, best, bi = best, d, i
        elif d < second:
            second = d
    return bi, best, second


def crater() -> Image.Image:
    """The glassed rock: Voronoi plates in two dark shades, cracks on their borders, glints, a rare plasma seam."""
    rng = random.Random(SEEDS["crater"])
    pts = voronoi(rng, 14)
    shade = [rng.random() for _ in pts]
    im = blank(TILE, TILE)
    for y in range(TILE):
        for x in range(TILE):
            i, d1, d2 = nearest(pts, x + 0.5, y + 0.5)
            if d2 - d1 < 1.2:
                col = mix(C["ink"], C["td"], 0.35)  # A crack.
            else:
                col = mix(C["td"], C["gd"], 0.25 + 0.5 * shade[i])
            im.putpixel((x, y), col)
    for _ in range(26):  # Cooled-glass glints.
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        im.putpixel((x, y), mix(C["gm"], C["hs"], 0.15))
    for _ in range(3):  # A short green plasma seam.
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        for k in range(rng.randint(3, 6)):
            im.putpixel(((x + k) % TILE, (y + (k // 2)) % TILE), mix(C["ch"], C["pd"], 0.35))
    return im


def hatchery() -> Image.Image:
    """The resin: lumpy Voronoi cells, darker in their middle and lighter at their rims, a few acid-green spores."""
    rng = random.Random(SEEDS["hatchery"])
    pts = voronoi(rng, 18)
    im = blank(TILE, TILE)
    for y in range(TILE):
        for x in range(TILE):
            _i, d1, d2 = nearest(pts, x + 0.5, y + 0.5)
            edge = d2 - d1
            if edge < 1.0:
                col = mix(C["ink"], C["ch"], 0.2)  # The seam between two lumps.
            elif edge < 2.5:
                col = mix(C["td"], C["ch"], 0.75)  # A slightly lighter rim.
            else:
                col = mix(C["td"], C["ch"], 0.45)  # The resin.
            im.putpixel((x, y), col)
    for _ in range(14):
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        im.putpixel((x, y), mix(C["ch"], C["pd"], 0.4))
    return im


def wreck() -> Image.Image:
    """The hull plates: 32 px courses, gunmetal seams, a lit top-left edge on each plate, rivets, a scorch streak."""
    rng = random.Random(SEEDS["wreck"])
    im = blank(TILE, TILE)
    tone = [[rng.random() for _ in range(4)] for _ in range(4)]
    for y in range(TILE):
        for x in range(TILE):
            px, py = x % 32, y % 32
            t = tone[y // 32][x // 32]
            if px == 0 or py == 0:
                col = mix(C["ink"], C["gd"], 0.6)  # A seam.
            elif px == 1 or py == 1:
                col = mix(C["gd"], C["gm"], 0.55)  # The lit edge.
            else:
                col = mix(C["gd"], C["gm"], 0.15 + 0.2 * t)
            if (px in (4, 28)) and (py in (4, 28)):
                col = mix(C["gm"], C["hs"], 0.2)  # A rivet.
            im.putpixel((x, y), col)
    sy = rng.randrange(TILE)
    for x in range(20, 70):  # A scorch streak.
        y = (sy + (x // 9)) % TILE
        im.putpixel((x, y), mix(C["ink"], C["gd"], 0.3))
    return im


def ruins() -> Image.Image:
    """The broken paving: 32 px slabs, every other row offset, dark joints, a few cracks and glass chips."""
    rng = random.Random(SEEDS["ruins"])
    im = blank(TILE, TILE)
    tone = {}
    for y in range(TILE):
        for x in range(TILE):
            row = y // 32
            sx = (x + (16 if row % 2 else 0)) % TILE
            key = (row, sx // 32)
            if key not in tone:
                tone[key] = rng.random()
            if y % 32 == 0 or sx % 32 == 0:
                col = mix(C["ink"], C["td"], 0.5)
            else:
                col = mix(C["td"], C["gd"], 0.3 + 0.45 * tone[key])
            im.putpixel((x, y), col)
    for _ in range(6):  # Cracks.
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        for k in range(rng.randint(6, 12)):
            x = (x + 1) % TILE
            y = (y + rng.choice((-1, 0, 1))) % TILE
            im.putpixel((x, y), mix(C["ink"], C["td"], 0.4))
    for _ in range(10):  # Glass chips.
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        im.putpixel((x, y), (0x5E, 0x9C, 0x94, 255))
    return im


def egg_shape(size: int, cx: float, cy: float, rx: float, ry: float) -> Image.Image:
    """An egg of radii rx, ry at (cx, cy) on a size x size canvas: ink rim, shell, a lit top-left, an acid vein."""
    im = blank(size, size)
    for y in range(size):
        for x in range(size):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1.0:
                col = C["ch"] + (255,)
                if dx < -0.15 and dy < -0.2 and d < 0.6:
                    col = C["cl"] + (255,)  # Lit from the top-left.
                if abs(dx - 0.15 * math.sin(dy * 3.0)) < 0.12 and -0.6 < dy < 0.6:
                    col = C["pd"] + (255,)  # The glowing vein.
                if d > 0.72:
                    col = C["ink"] + (255,)  # The rim.
                im.putpixel((x, y), col)
    return im


def brood_egg() -> Image.Image:
    """The 14 x 14 egg on its resin smear."""
    im = blank(14, 14)
    for x in range(1, 13):  # The resin smear at its foot.
        for y in (12, 13):
            if abs(x - 6.5) < (6 if y == 12 else 4.5):
                im.putpixel((x, y), C["ch"] + (255,))
    im.alpha_composite(egg_shape(14, 7.0, 6.5, 5.2, 6.4))
    return im


def egg_hatch() -> Image.Image:
    """4 frames of 16 x 16: cracks, more cracks and glow, the shell split, the halves and a claw out."""
    sheet = blank(64, 16)
    for f in range(4):
        fr = egg_shape(16, 8.0, 8.5 if f < 3 else 10.5, 5.2, 6.4 if f < 3 else 4.0)
        if f >= 1:
            for k in range(-3, 4):  # A zig-zag crack across the shell.
                x, y = 8 + k, 7 + (k % 2)
                fr.putpixel((x, y), (C["p"] if f >= 2 else C["ink"]) + (255,))
        if f >= 2:
            for x in range(4, 13):  # The split.
                fr.putpixel((x, 7), C["ink"] + (255,))
                fr.putpixel((x, 6), (0, 0, 0, 0))
        if f == 3:
            for y in range(1, 7):  # A cream claw out of the shell.
                fr.putpixel((9 + (y // 3), y), C["hb"] + (255,))
            fr.putpixel((7, 4), C["p"] + (255,))  # An eye.
        sheet.alpha_composite(fr, (f * 16, 0))
    return sheet


def mound() -> Image.Image:
    """The 28 x 16 dirt mound: an ink rim, dark and light dirt, a few clods."""
    rng = random.Random(SEEDS["egg"])
    im = blank(28, 16)
    for y in range(16):
        for x in range(28):
            dx, dy = (x + 0.5 - 14.0) / 13.5, (y + 0.5 - 11.0) / 9.5
            if dy > 0.5:
                dy *= 2.0  # A flat base.
            d = dx * dx + dy * dy
            if d <= 1.0:
                col = C["br"]
                if dx < 0 and dy < -0.2:
                    col = C["bl"]
                if d > 0.78:
                    col = C["bd"]
                im.putpixel((x, y), col + (255,))
    for _ in range(7):
        x, y = rng.randrange(4, 24), rng.randrange(3, 12)
        if im.getpixel((x, y))[3] > 0:
            im.putpixel((x, y), C["bl"] + (255,))
            im.putpixel((min(27, x + 1), y), C["bd"] + (255,))
    return im


def acid_pool() -> Image.Image:
    """The 32 x 26 acid puddle: a soft rim (plasma dark #1FA84A), a body (plasma #3CFF6A), hull-white bubbles; Act IX art
    review round 1: it was a grey tint mask, now baked in the Concord plasma ramp (AcidPools.POOL_TINT is white)."""
    rng = random.Random(SEEDS["pool"])
    im = blank(32, 26)
    for y in range(26):
        for x in range(32):
            dx, dy = (x + 0.5 - 16.0), (y + 0.5 - 13.0) * 1.23
            ang = math.atan2(dy, dx)
            edge = 14.5 + 1.2 * math.sin(ang * 3.0) + 0.8 * math.sin(ang * 5.0 + 1.3)
            d = math.hypot(dx, dy)
            if d <= edge:
                col = (0x1F, 0xA8, 0x4A) if d > edge - 2.0 else (0x3C, 0xFF, 0x6A)
                im.putpixel((x, y), col + (150 if d > edge - 2.0 else 200))
    for _ in range(9):  # Bubbles.
        x, y = rng.randrange(6, 26), rng.randrange(5, 21)
        if im.getpixel((x, y))[3] > 0:
            im.putpixel((x, y), (0xE8, 0xEC, 0xF0, 230))
    return im


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "assets" / "sprites"))
    out = Path(ap.parse_args().out)
    files = {
        "tiles/crash_site_crater.png": crater(), "tiles/crash_site_hatchery.png": hatchery(),
        "tiles/crash_site_wreck.png": wreck(), "tiles/crash_site_ruins.png": ruins(),
        "concord/brood_egg.png": brood_egg(), "concord/brood_egg_hatch.png": egg_hatch(),
        "concord/burrow_mound.png": mound(), "effects/acid_pool.png": acid_pool(),
    }
    for rel, im in files.items():
        p = out / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        im.save(p)
        print("wrote", p)


if __name__ == "__main__":
    main()
