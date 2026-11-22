#!/usr/bin/env python3
"""year_tiles.py: draws the Turning Year's floors, markers and effect strips on the art grid (Act XV slot, stage key wild; ART_BIBLE "Act XV
slot: the Turning Year"). Every pixel is a wild_ colour of tools/palette.json; seeded noise only (a rerun reproduces the files exactly).
Floors are neutral, mid-value moss with visible features (ferns, fallen leaves, roots, petals, a toadstool ring, cracks): the seasons tint
them through WildRulesData.SEASON_TINTS (spring x1.0/1.04/0.96 ... winter x1.2/1.24/1.32), so the base stays darker and desaturated.
Outputs (assets/sprites/): tiles/wild_greenwood, wild_fae, wild_tree (128x128 seamless); markers/wild_roots (24x16), wild_sprout (32x32),
wild_blight (64x64, tiling), wild_season_wheel (28x28); fx/wild_smoke_line (4x128, tiling), wild_fire_front (44x128, tiling),
wild_blizzard (128x128 radial), wild_snowfall (8 x 64x64), wild_leaves (8 x 64x64), wild_thicket_burn (6 x 48x48), wild_bury (6 x 40x40).
Usage (repo root): python3 art_source/year/year_tiles.py"""
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
OUT = ROOT / "assets/sprites"  # Output root.
INK = "#14100C"  # Deep-bark outline.
MOSS_D, MOSS, MOSS_L = "#274D24", "#599641", "#9CCB72"  # Moss ramp.
BARK_D, BARK, BARK_L = "#553C27", "#86603E", "#B08A60"  # Bark ramp.
BLO_D, BLO, BLO_L = "#9C5272", "#EFA6C3", "#FBD9E6"  # Blossom ramp.
LEAF_D, LEAF, LEAF_L = "#8A5420", "#D9953C", "#F2C67A"  # Amber leaf ramp.
FRO_D, FRO_M, FRO = "#6F8AA4", "#B9CEE0", "#E4EDF5"  # Frost ramp.
BLI_D, BLI, ASH = "#312E2C", "#57524D", "#86807A"  # Blight ramp.
FIR_D, FIR, FIR_L = "#8F2E12", "#E35C26", "#FFB060"  # Wildfire ramp.


def rgb(h: str, a: int = 255) -> tuple:
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), a)


def tone(h: str, k: float) -> tuple:
    r, g, b, _ = rgb(h)
    return (min(255, round(r * k)), min(255, round(g * k)), min(255, round(b * k)), 255)


class Tile:
    """A wrapping canvas: every put() wraps, so features crossing an edge keep the tile seamless."""

    def __init__(self, size: int, fill: tuple):
        self.n = size
        self.im = Image.new("RGBA", (size, size), fill)

    def put(self, x: int, y: int, c: tuple) -> None:
        self.im.putpixel((x % self.n, y % self.n), c)

    def disc(self, cx: int, cy: int, r: int, c: tuple) -> None:
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r:
                    self.put(cx + x, cy + y, c)


def base(t: Tile, rng: random.Random, col: str, k: float, blots: int) -> None:
    """Low-frequency blotches of the base colour, a little lighter and darker."""
    for _ in range(blots):
        t.disc(rng.randrange(t.n), rng.randrange(t.n), rng.randint(4, 10), tone(col, k * rng.choice((0.82, 0.9, 1.12, 1.22))))


def fern(t: Tile, x: int, y: int, c1: tuple, c2: tuple) -> None:
    """A 7 x 5 fern frond: a spine and two rows of leaflets."""
    for d in range(7):
        t.put(x + d, y, c1)
    for d in (1, 3, 5):
        t.put(x + d, y - 1, c2)
        t.put(x + d, y + 1, c2)
        t.put(x + d + 1, y - 2 if d < 5 else y - 1, c2)
        t.put(x + d + 1, y + 2 if d < 5 else y + 1, c2)


def leaf(t: Tile, x: int, y: int, c1: tuple, c2: tuple) -> None:
    """A 3 x 2 fallen leaf with a darker tip."""
    for dx, dy in ((0, 0), (1, 0), (2, 0), (1, 1), (2, 1)):
        t.put(x + dx, y + dy, c1)
    t.put(x + 3, y + 1, c2)


def root(t: Tile, rng: random.Random, x: int, y: int, length: int, c1: tuple, c2: tuple) -> None:
    """A wandering root: a random walk of 2 px wide bark with a lit upper edge."""
    for _ in range(length):
        t.put(x, y, c1)
        t.put(x, y + 1, c1)
        t.put(x, y - 1, c2)
        x += 1
        y += rng.choice((-1, 0, 0, 1))


def greenwood() -> None:
    rng = random.Random(1501)
    t = Tile(128, tone(MOSS_D, 0.9))
    base(t, rng, MOSS_D, 0.9, 80)
    for _ in range(190):  # Grass specks.
        t.put(rng.randrange(128), rng.randrange(128), tone(rng.choice((MOSS, MOSS_L, MOSS_D)), 0.7))
    for _ in range(12):
        fern(t, rng.randrange(128), rng.randrange(128), tone(MOSS, 0.78), tone(MOSS_L, 0.72))
    for _ in range(26):  # Fallen leaves: amber and bark.
        leaf(t, rng.randrange(128), rng.randrange(128), tone(rng.choice((LEAF, LEAF_D, BARK)), 0.85), tone(BARK_D, 0.9))
    for _ in range(5):  # Roots and twigs.
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(10, 20), tone(BARK_D, 1.05), tone(BARK, 0.8))
    t.im.save(OUT / "tiles/wild_greenwood.png")


def fae() -> None:
    rng = random.Random(1502)
    t = Tile(128, tone(MOSS, 0.5))
    base(t, rng, MOSS, 0.5, 80)
    for _ in range(170):  # Short grass blades, three px tall.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(3):
            t.put(x, y - d, tone(rng.choice((MOSS, MOSS_L)), 0.52 + 0.08 * d))
    for _ in range(46):  # Petals: pink flecks of two px.
        x, y = rng.randrange(128), rng.randrange(128)
        c = tone(rng.choice((BLO, BLO_L, BLO_D)), 0.86)
        t.put(x, y, c)
        t.put(x + 1, y, c)
    cx, cy = 64, 64  # A fairy ring of toadstools: cream caps with pink spots on short stems.
    for i in range(11):
        a = i / 11 * math.tau
        x, y = round(cx + math.cos(a) * 24), round(cy + math.sin(a) * 18)
        t.put(x, y + 1, tone(FRO_M, 0.7))
        for dx in (-1, 0, 1):
            t.put(x + dx, y, tone(BLO_D, 0.95))
        t.put(x, y - 1, tone(BLO, 0.9))
        t.put(x + 1, y - 1, tone(FRO, 0.8))
    for _ in range(8):  # Dew sparkles.
        t.put(rng.randrange(128), rng.randrange(128), tone(FRO, 0.75))
    t.im.save(OUT / "tiles/wild_fae.png")


def tree() -> None:
    rng = random.Random(1503)
    t = Tile(128, tone(BARK_D, 0.9))
    base(t, rng, BARK_D, 0.9, 90)
    for _ in range(9):  # Great roots running across the tile, light on top, dark underneath.
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(40, 90), tone(BARK, 0.62), tone(BARK_L, 0.58))
    for _ in range(26):  # Bark cracks: short dark vertical lines.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(rng.randint(3, 7)):
            t.put(x + (d % 2), y + d, tone(INK, 1.4))
    for _ in range(22):  # Moss patches clinging to the roots.
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(1, 3), tone(rng.choice((MOSS_D, MOSS)), 0.7))
    for _ in range(90):
        t.put(rng.randrange(128), rng.randrange(128), tone(BARK_L, 0.55))
    t.im.save(OUT / "tiles/wild_tree.png")


def roots_marker() -> None:
    """24 x 16: roots sprouting from a dark soil crescent, three bark tendrils curling up."""
    im = Image.new("RGBA", (24, 16), (0, 0, 0, 0))
    for x in range(2, 22):
        for y in range(11, 16):
            if ((x - 11.5) / 10.5) ** 2 + ((y - 15) / 4.5) ** 2 <= 1:
                im.putpixel((x, y), rgb(BARK_D))
    for x0, h, lean in ((5, 9, 1), (11, 12, 0), (17, 8, -1)):
        x = x0
        for d in range(h):
            y = 13 - d
            im.putpixel((x, y), rgb(BARK if d % 3 else BARK_L))
            im.putpixel((x + 1, y), rgb(BARK_D))
            if d % 3 == 2:
                x += lean
    for y in range(16):
        for x in range(24):
            if im.getpixel((x, y))[3] == 0 and any(0 <= x + dx < 24 and 0 <= y + dy < 16 and im.getpixel((x + dx, y + dy))[3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), rgb(INK))
    im.save(OUT / "markers/wild_roots.png")


def sprout_marker() -> None:
    """32 x 32: a seedling on a soil mound, two leaves and a bud (the thicket seed)."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for x in range(6, 26):
        for y in range(20, 30):
            if ((x - 15.5) / 9.5) ** 2 + ((y - 29) / 8.5) ** 2 <= 1:
                im.putpixel((x, y), rgb(BARK_D if y > 23 else BARK))
    for y in range(12, 22):  # Stem.
        im.putpixel((15, y), rgb(MOSS_D))
        im.putpixel((16, y), rgb(MOSS))
    for i in range(7):  # Two leaves.
        im.putpixel((13 - i, 15 - i // 2), rgb(MOSS))
        im.putpixel((12 - i, 15 - i // 2), rgb(MOSS_L if i < 3 else MOSS))
        im.putpixel((18 + i, 13 - i // 2), rgb(MOSS))
        im.putpixel((19 + i, 13 - i // 2), rgb(MOSS_L if i < 3 else MOSS))
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (-1, 0), (2, 0)):  # Bud.
        im.putpixel((15 + dx, 10 + dy), rgb(BLO))
    im.putpixel((15, 9), rgb(BLO_L))
    for y in range(32):
        for x in range(32):
            if im.getpixel((x, y))[3] == 0 and any(0 <= x + dx < 32 and 0 <= y + dy < 32 and im.getpixel((x + dx, y + dy))[3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), rgb(INK))
    im.save(OUT / "markers/wild_sprout.png")


def blight_marker() -> None:
    """64 x 64 tiling: dead grey ground (reads strongly against the living green): ash blotches, dead grass tufts and dark cracks."""
    rng = random.Random(1504)
    t = Tile(64, rgb(BLI))
    for _ in range(36):
        t.disc(rng.randrange(64), rng.randrange(64), rng.randint(3, 7), rgb(rng.choice((BLI_D, BLI, ASH)) if rng.random() < 0.5 else BLI))
    for _ in range(14):  # Cracks: jagged dark runs.
        x, y = rng.randrange(64), rng.randrange(64)
        for _ in range(rng.randint(6, 14)):
            t.put(x, y, rgb(INK))
            x += rng.choice((-1, 0, 1, 1))
            y += rng.choice((0, 1, 1))
    for _ in range(16):  # Dead grass: pale grey blades.
        x, y = rng.randrange(64), rng.randrange(64)
        for d in range(3):
            t.put(x + d // 2, y - d, rgb(ASH))
    for _ in range(40):
        t.put(rng.randrange(64), rng.randrange(64), rgb(ASH))
    t.im.save(OUT / "markers/wild_blight.png")


def season_wheel() -> None:
    """28 x 28: the wheel of the year, four quarters (spring moss, summer amber, autumn bark, winter frost) in a dark ring."""
    im = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    cols = {(1, 0): (MOSS, MOSS_L), (1, 1): (LEAF, LEAF_L), (0, 1): (BARK, BARK_L), (0, 0): (FRO_M, FRO)}  # (right, below) -> colours; spring top-right.
    for y in range(28):
        for x in range(28):
            d = math.hypot(x - 13.5, y - 13.5)
            if d <= 13.5:
                q = (1 if x >= 14 else 0, 1 if y >= 14 else 0)
                c = cols[q]
                if d > 12.2 or d < 4.2 or x in (13, 14) or y in (13, 14):
                    im.putpixel((x, y), rgb(INK))
                else:
                    im.putpixel((x, y), rgb(c[1] if (x + y) % 7 == 0 or d > 10.8 else c[0]))
    im.save(OUT / "markers/wild_season_wheel.png")


def smoke_line() -> None:
    """4 x 128, tiling in y: ash-grey dashes (the wildfire's telegraph)."""
    im = Image.new("RGBA", (4, 128), (0, 0, 0, 0))
    for y in range(128):
        if (y // 8) % 2 == 0:
            for x in (1, 2):
                im.putpixel((x, y), rgb(ASH, 235))
            for x in (0, 3):
                im.putpixel((x, y), rgb(BLI, 150))
    im.save(OUT / "fx/wild_smoke_line.png")


def fire_front() -> None:
    """44 x 128, tiling in y: flame tongues pointing right (x = the direction of travel), dark-orange base on the left, amber core."""
    rng = random.Random(1505)
    im = Image.new("RGBA", (44, 128), (0, 0, 0, 0))
    y = 0
    while y < 128:
        h = rng.randint(10, 16)
        length = rng.randint(28, 42)
        for dy in range(h):
            frac = abs((dy - (h - 1) / 2) / (h / 2))  # 0 centre .. 1 edge.
            ext = int(length * (1 - frac ** 1.6))
            for x in range(ext):
                p = ((x), (y + dy) % 128)
                r = x / max(1, ext)
                c = FIR_D if r < 0.35 else FIR if r < 0.78 else FIR_L
                if frac < 0.35 and 0.2 < r < 0.7:
                    c = FIR_L
                im.putpixel(p, rgb(c, 235))
        y += h - 2
    for yy in range(128):  # Embers dust at the tips.
        if rng.random() < 0.12:
            im.putpixel((rng.randint(30, 43), yy), rgb(FIR_L, 200))
    im.save(OUT / "fx/wild_fire_front.png")


def blizzard() -> None:
    """128 x 128 radial: a snow veil, clear in the middle, frost-white drifts and flakes thickening to the edge (stepped alpha, no gradient)."""
    rng = random.Random(1506)
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    for y in range(128):
        for x in range(128):
            d = math.hypot(x - 63.5, y - 63.5) / 64
            if d < 0.5:
                continue
            a = 70 if d < 0.7 else 120 if d < 0.88 else 170
            if rng.random() < (d - 0.4) * 0.9 and (x + 2 * y) % 3:
                im.putpixel((x, y), rgb(FRO if rng.random() < 0.6 else FRO_M, a))
    for _ in range(120):  # Larger flakes (2 x 2).
        a = rng.random() * math.tau
        r = 34 + rng.random() * 30
        x, y = int(63.5 + math.cos(a) * r), int(63.5 + math.sin(a) * r)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            if 0 <= x + dx < 128 and 0 <= y + dy < 128:
                im.putpixel((x + dx, y + dy), rgb(FRO, 220))
    im.save(OUT / "fx/wild_blizzard.png")


def snowfall() -> None:
    """8 frames of 64x64: flakes falling 8 px a frame (a seamless loop), a slow sideways drift."""
    rng = random.Random(1507)
    flakes = [(rng.randrange(64), rng.randrange(64), rng.choice((1, 1, 2)), rng.choice((FRO, FRO, FRO_M))) for _ in range(34)]
    S = Image.new("RGBA", (8 * 64, 64), (0, 0, 0, 0))
    for f in range(8):
        for x, y, s, c in flakes:
            for dx in range(s):
                for dy in range(s):
                    S.putpixel((f * 64 + (x + f * (s - 1) // 1 + dx) % 64, (y + f * 8 + dy) % 64), rgb(c, 235))
    S.save(OUT / "fx/wild_snowfall.png")


def leaves_fx() -> None:
    """8 frames of 64x64: amber and bark leaves tumbling down 8 px a frame, swaying (a seamless loop)."""
    rng = random.Random(1508)
    ls = [(rng.randrange(64), rng.randrange(64), rng.choice((LEAF, LEAF, LEAF_D, BARK_L)), rng.random() * math.tau) for _ in range(16)]
    S = Image.new("RGBA", (8 * 64, 64), (0, 0, 0, 0))
    for f in range(8):
        for x, y, c, ph in ls:
            sx = round(math.sin(ph + f / 8 * math.tau) * 3)
            px, py = f * 64 + (x + sx) % 64, (y + f * 8) % 64
            for dx, dy in ((0, 0), (1, 0), (1, 1)):
                S.putpixel((f * 64 + ((x + sx + dx) % 64), (py + dy) % 64), rgb(c, 240))
            S.putpixel((f * 64 + ((x + sx + 2) % 64), (py + 1) % 64), rgb(BARK_D, 240))
    S.save(OUT / "fx/wild_leaves.png")


def thicket_burn() -> None:
    """6 frames of 48x48: a thicket burning to ash: flames rising and fading, a bark mound turning grey."""
    rng = random.Random(1509)
    S = Image.new("RGBA", (6 * 48, 48), (0, 0, 0, 0))
    for f in range(6):
        burn = 1 - f / 5  # Flame strength.
        for y in range(48):
            for x in range(48):
                d = math.hypot((x - 23.5) / 22, (y - 30) / 14)
                if d <= 1:
                    c = (BARK if f < 2 else BLI if f < 4 else ASH) if rng.random() < 0.7 else (BARK_D if f < 2 else BLI_D)
                    S.putpixel((f * 48 + x, y), rgb(c))
        for _ in range(int(60 * burn)):
            x = 23 + int(rng.gauss(0, 8))
            y = 30 - int(abs(rng.gauss(0, 10)) * (1.0 + 0.4 * (1 - burn)) * 1.3)
            h = rng.randint(2, 5)
            for d in range(h):
                if 0 <= x < 48 and 0 <= y - d < 48:
                    S.putpixel((f * 48 + x, y - d), rgb(FIR_L if d == 0 and burn > 0.5 else FIR if d < 2 else FIR_D, 235))
        for _ in range(8 + f * 3):  # Ash flecks drifting up.
            S.putpixel((f * 48 + rng.randrange(8, 40), rng.randrange(4, 30)), rgb(ASH, 200))
    S.save(OUT / "fx/wild_thicket_burn.png")


def bury() -> None:
    """6 frames of 40x40: earth closing over a buried summon: a soil mound growing from the edges inward, a few roots on top."""
    rng = random.Random(1510)
    S = Image.new("RGBA", (6 * 40, 40), (0, 0, 0, 0))
    for f in range(6):
        rr = 5 + f * 3.4
        for y in range(40):
            for x in range(40):
                d = math.hypot((x - 19.5) / rr, (y - 26) / (rr * 0.62))
                if d <= 1:
                    c = BARK_L if (d > 0.8 and y < 26) else BARK if d > 0.45 else BARK_D
                    S.putpixel((f * 40 + x, y), rgb(c, 255 if f < 5 else 200))
        for _ in range(4 + f * 2):  # Clods and grass blades flung up.
            a = rng.random() * math.tau
            x, y = int(19.5 + math.cos(a) * (rr + rng.randint(0, 5))), int(26 + math.sin(a) * (rr * 0.6 + rng.randint(0, 4)) - rng.randint(0, 4))
            if 0 <= x < 40 and 0 <= y < 40:
                S.putpixel((f * 40 + x, y), rgb(rng.choice((BARK_D, MOSS, MOSS_L)), 235))
    S.save(OUT / "fx/wild_bury.png")


if __name__ == "__main__":
    (OUT / "markers").mkdir(exist_ok=True)
    (OUT / "fx").mkdir(exist_ok=True)
    greenwood()
    fae()
    tree()
    roots_marker()
    sprout_marker()
    blight_marker()
    season_wheel()
    smoke_line()
    fire_front()
    blizzard()
    snowfall()
    leaves_fx()
    thicket_burn()
    bury()
