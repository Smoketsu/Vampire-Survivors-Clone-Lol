#!/usr/bin/env python3
"""dynasty_tiles.py: draws the Necropolis Dynasty's zone floors and the quicksand on the art grid (Act VII slot, stage key dynasty).

Why (ART_BIBLE "Act VII slot: the Necropolis Dynasty"): a zone floor must tile with no seam and stay dark and flat (the floor rule:
sprites stand out against it), so every tile is drawn here pixel by pixel from the dyn_ palette colours of tools/palette.json, in
dark tones, light from the top-left, with seeded noise only (a rerun reproduces the files exactly).

Outputs (1 art px = 1 screen px; assets/sprites/tiles/, each 128 x 128 and seamless):
  necropolis_dunes / _tomb_road / _sandstorm_pass / _mortuary_temple      the Necropolis of Sand's four zones
  lioness_temple_avenue / _courtyard / _hypostyle / _sanctuary            the Temple of the Lioness's four zones
  two_truths_reeds / _fire / _scales / _throne                            the Hall of Two Truths's four zones
  dynasty_quicksand      a slightly lighter, golden whirl of concentric ripples (the Black Land's quicksand; TerrainSlow patches)
Usage (repo root):  python3 art_source/dynasty/dynasty_tiles.py [--out DIR]   (default: assets/sprites/tiles)
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
T = 128  # Tile size (px).


def rgb(h: str) -> tuple:
    """'#RRGGBB' -> (r, g, b, 255)."""
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)


def tone(base: str, k: float) -> tuple:
    """The dark floor colour `base` scaled by k (a 0.8..1.25 shade step), opaque."""
    r, g, b, _ = rgb(base)
    return (min(255, round(r * k)), min(255, round(g * k)), min(255, round(b * k)), 255)


def canvas(base: str) -> Image.Image:
    return Image.new("RGBA", (T, T), rgb(base))


def put(im: Image.Image, x: int, y: int, c: tuple) -> None:
    """Sets a pixel with wrap-around (tiles stay seamless whatever is drawn near an edge)."""
    im.putpixel((x % T, y % T), c)


def slabs(im: Image.Image, rng: random.Random, base: str, w: int, h: int, offset: bool, crack: float, seam: float = 0.72) -> None:
    """Paving: slabs of w x h px (rows offset by half when `offset`), each its own shade, a dark seam on the top / left edge and a
    light one under it (light from the top-left), random cracks."""
    rows = T // h
    cols = T // w
    for r in range(rows):
        shift = (w // 2) if (offset and r % 2) else 0
        for c in range(cols):
            k = rng.uniform(0.9, 1.12)
            x0, y0 = c * w + shift, r * h
            for y in range(h):
                for x in range(w):
                    col = tone(base, k)
                    if x == 0 or y == 0:
                        col = tone(base, seam)
                    elif x == 1 or y == 1:
                        col = tone(base, k * 1.12)
                    put(im, x0 + x, y0 + y, col)
            if rng.random() < crack:  # A crack: a short dark run across the slab.
                cx, cy = x0 + rng.randrange(w), y0 + rng.randrange(h)
                for _ in range(rng.randrange(5, 12)):
                    put(im, cx, cy, tone(base, seam * 0.9))
                    cx += rng.choice((-1, 0, 1))
                    cy += 1


def speckle(im: Image.Image, rng: random.Random, base: str, n: int, lo: float, hi: float) -> None:
    """n single-pixel grains of the base colour at a random shade lo..hi."""
    for _ in range(n):
        put(im, rng.randrange(T), rng.randrange(T), tone(base, rng.uniform(lo, hi)))


def ripples(im: Image.Image, rng: random.Random, base: str, period: int, amp: float, n_lines: int) -> None:
    """Wind-blown dune ripples: wrapped sine bands (slightly slanted), a lighter crest line and a darker trough line."""
    for y in range(T):
        for x in range(T):
            v = math.sin(2 * math.pi * (y / period * 2 + math.sin(2 * math.pi * x / T) * amp))
            if v > 0.92:
                put(im, x, y, tone(base, 1.18))
            elif v < -0.92:
                put(im, x, y, tone(base, 0.82))


def voro(im: Image.Image, rng: random.Random, base: str, n: int, edge: float) -> None:
    """Rocky pebbles: a wrapped Voronoi map, each cell its own shade, a dark rim where two cells meet."""
    pts = [(rng.uniform(0, T), rng.uniform(0, T), rng.uniform(0.88, 1.14)) for _ in range(n)]
    for y in range(T):
        for x in range(T):
            ds = []
            for (px, py, k) in pts:
                dx = min(abs(x - px), T - abs(x - px))
                dy = min(abs(y - py), T - abs(y - py))
                ds.append((dx * dx + dy * dy, k))
            ds.sort()
            d1, k1 = ds[0]
            d2 = ds[1][0]
            put(im, x, y, tone(base, edge if (math.sqrt(d2) - math.sqrt(d1)) < 1.4 else k1))


def line_h(im: Image.Image, y: int, c: tuple, dash: int = 0, gap: int = 0) -> None:
    for x in range(T):
        if dash == 0 or (x % (dash + gap)) < dash:
            put(im, x, y, c)


def line_v(im: Image.Image, x: int, c: tuple, dash: int = 0, gap: int = 0) -> None:
    for y in range(T):
        if dash == 0 or (y % (dash + gap)) < dash:
            put(im, x, y, c)


def dunes(rng):
    im = canvas("#2B2415")
    speckle(im, rng, "#2B2415", 500, 0.85, 1.15)
    ripples(im, rng, "#2B2415", 32, 0.18, 4)
    return im


def tomb_road(rng):
    im = canvas("#2F2819")
    slabs(im, rng, "#2F2819", 32, 32, True, 0.5)
    speckle(im, rng, "#2F2819", 200, 0.85, 1.12)
    return im


def sandstorm_pass(rng):
    im = canvas("#2A2318")
    voro(im, rng, "#2A2318", 26, 0.8)
    speckle(im, rng, "#2A2318", 300, 0.85, 1.15)
    return im


def mortuary_temple(rng):
    im = canvas("#2E281C")
    slabs(im, rng, "#2E281C", 64, 64, False, 0.35)
    for y in (31, 95):  # A faint lapis inlay line through each course.
        line_h(im, y, tone("#16327C", 0.62), 6, 2)
    return im


def avenue(rng):
    im = canvas("#2E2719")
    slabs(im, rng, "#2E2719", 32, 32, True, 0.4)
    for x in (56, 71):  # The processional way: two bronze inlay lines down the middle.
        line_v(im, x, tone("#A38E3C", 0.42))
    return im


def courtyard(rng):
    im = canvas("#2C2517")
    for r in range(4):
        for c in range(4):
            base = "#2F281A" if (r + c) % 2 == 0 else "#262013"
            for y in range(32):
                for x in range(32):
                    k = 1.0 if x and y else 0.74
                    put(im, c * 32 + x, r * 32 + y, tone(base, k * rng.uniform(0.97, 1.04)))
    return im


def hypostyle(rng):
    im = canvas("#241F16")
    slabs(im, rng, "#241F16", 32, 64, False, 0.3, 0.7)
    for y in range(8, T, 16):  # Rows of faint carved glyph dashes (no readable writing).
        for x in range(4, T, 8):
            if rng.random() < 0.6:
                put(im, x, y, tone("#8C6B3E", 0.4))
                put(im, x + 1, y, tone("#8C6B3E", 0.4))
    return im


def sanctuary(rng):
    im = canvas("#2B1D17")
    slabs(im, rng, "#2B1D17", 32, 32, False, 0.3, 0.7)
    cx = cy = T // 2
    for a in range(0, 360, 3):  # A faint carnelian ring of the Lioness's sun.
        put(im, round(cx + 40 * math.cos(math.radians(a))), round(cy + 40 * math.sin(math.radians(a))), tone("#7B1E16", 0.7))
    return im


def reeds(rng):
    im = canvas("#1F2316")
    speckle(im, rng, "#1F2316", 600, 0.8, 1.2)
    for _ in range(70):  # Reed blades: short vertical runs of papyrus green.
        x, y = rng.randrange(T), rng.randrange(T)
        for i in range(rng.randrange(3, 8)):
            put(im, x + (i // 4), y - i, tone("#285A30", rng.uniform(0.55, 0.8)))
    return im


def fire(rng):
    im = canvas("#1A1614")
    voro(im, rng, "#1A1614", 22, 0.5)
    for y in range(T):  # The river's glow: dim carnelian in the cracks (the rim pixels of the basalt plates).
        for x in range(T):
            if im.getpixel((x, y)) == tone("#1A1614", 0.5):
                put(im, x, y, tone("#7B1E16", 0.85) if rng.random() < 0.7 else tone("#BF3B2B", 0.7))
    return im


def scales(rng):
    im = canvas("#1F2230")
    slabs(im, rng, "#1F2230", 32, 32, False, 0.15, 0.7)
    for v in (0, 64):
        line_h(im, v + 1, tone("#A38E3C", 0.4), 4, 4)
        line_v(im, v + 1, tone("#A38E3C", 0.4), 4, 4)
    return im


def throne(rng):
    im = canvas("#1C1F33")
    slabs(im, rng, "#1C1F33", 64, 32, True, 0.2, 0.7)
    for y in (15, 47, 79, 111):
        line_h(im, y, tone("#6B5A22", 0.8), 3, 5)
    return im


def quicksand(rng):
    """Concentric wrapped ripples around two wells: the golden, lighter whirl that reads as 'do not walk here'."""
    im = canvas("#3A2F18")
    wells = [(34, 40), (94, 90)]
    for y in range(T):
        for x in range(T):
            d = 99.0
            for (wx, wy) in wells:
                dx = min(abs(x - wx), T - abs(x - wx))
                dy = min(abs(y - wy), T - abs(y - wy))
                d = min(d, math.hypot(dx, dy * 1.2))
            v = math.sin(d * 0.55)
            col = tone("#3A2F18", 1.0 + 0.16 * v)
            if d < 5:
                col = tone("#14100A", 1.0)
            put(im, x, y, col)
    speckle(im, rng, "#3A2F18", 260, 0.85, 1.2)
    return im


TILES = {
    "necropolis_dunes": dunes, "necropolis_tomb_road": tomb_road, "necropolis_sandstorm_pass": sandstorm_pass,
    "necropolis_mortuary_temple": mortuary_temple, "lioness_temple_avenue": avenue, "lioness_temple_courtyard": courtyard,
    "lioness_temple_hypostyle": hypostyle, "lioness_temple_sanctuary": sanctuary, "two_truths_reeds": reeds, "two_truths_fire": fire,
    "two_truths_scales": scales, "two_truths_throne": throne, "dynasty_quicksand": quicksand,
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "assets/sprites/tiles"))
    out = Path(ap.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for i, (name, fn) in enumerate(TILES.items()):
        fn(random.Random(700 + i)).save(out / (name + ".png"))
        print("wrote", name)


if __name__ == "__main__":
    main()
