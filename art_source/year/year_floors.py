#!/usr/bin/env python3
"""year_floors.py: the Turning Year's phase 2 zone floors (assets/sprites/tiles/, 128 x 128, seamless, mid-value and desaturated so the four season tints read):
the Greenwood's greenwood_glade / _deep_wood / _hunting_grounds / _stags_hollow, the Fae Court's fae_court_rose_maze / _revel / _mirror_lake / _throne_of_blossoms,
the World-Tree's world_tree_roots / _trunk_stair / _crown / _seed, and the fairy ring patch wild_fairy_ring (a round patch with a transparent outside). Each floor has
VISIBLE FEATURES drawn on the grid (owner, Host round: plain noise looks weak): flowers, mushroom clusters, hoof prints, antlers and bones, rose hedges' petals and a
flagged path, bunting petals, lily pads and ripples, a blossom carpet, great roots, bark ledges, canopy leaves and light dapples, a seed's glowing rings. Every colour is
a wild_ ramp colour of tools/palette.json (helpers from year_tiles.py), seeded noise only (a rerun reproduces the files). Usage (repo root): python3 art_source/year/year_floors.py"""
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from year_tiles import (ASH, BARK, BARK_D, BARK_L, BLI, BLI_D, BLO, BLO_D, BLO_L, FRO, FRO_D, FRO_M, INK, LEAF, LEAF_D, LEAF_L, MOSS, MOSS_D,  # noqa: E402
                        MOSS_L, OUT, Tile, base, fern, leaf, root, tone)

SOUL = "#3DCC94"  # Soul-teal (the seed's glow only).


def scatter(t: Tile, rng: random.Random, n: int, cols: list, k: float) -> None:
    for _ in range(n):
        t.put(rng.randrange(128), rng.randrange(128), tone(rng.choice(cols), k))


def flower(t: Tile, x: int, y: int, c: str, k: float = 0.9) -> None:
    """A 3 x 3 cross flower with a light centre."""
    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
        t.put(x + dx, y + dy, tone(c, k))
    t.put(x, y, tone(LEAF_L, 0.9))


def shroom(t: Tile, x: int, y: int, cap: str, k: float = 0.85) -> None:
    """A toadstool: a 5 x 2 cap with a pale dot, a short stem."""
    for dx in range(-2, 3):
        t.put(x + dx, y, tone(cap, k))
    for dx in range(-1, 2):
        t.put(x + dx, y - 1, tone(cap, k * 1.1))
    t.put(x, y - 1, tone(FRO, 0.8))
    t.put(x, y + 1, tone(FRO_M, 0.7))
    t.put(x, y + 2, tone(FRO_M, 0.55))


def hoof(t: Tile, x: int, y: int, c: tuple) -> None:
    """A cloven hoof print: two small ticks."""
    for dy in (0, 1, 2):
        t.put(x, y + dy, c)
        t.put(x + 3, y + dy, c)
    t.put(x + 1, y, c)
    t.put(x + 2, y, c)


def antler(t: Tile, rng: random.Random, x: int, y: int) -> None:
    """A shed antler: a 12 px beam with two tines, bone-pale."""
    c, c2 = tone(BARK_L, 0.78), tone(BARK, 1.0)
    for d in range(12):
        t.put(x + d, y - d // 4, c)
        t.put(x + d, y - d // 4 + 1, c2)
    for d in (3, 7):
        for e in range(3):
            t.put(x + d, y - d // 4 - 1 - e, c)


def bone(t: Tile, x: int, y: int) -> None:
    c = tone(FRO, 0.72)
    for d in range(7):
        t.put(x + d, y, c)
    for dx, dy in ((0, -1), (0, 1), (6, -1), (6, 1)):
        t.put(x + dx, y + dy, c)


def ripple(t: Tile, x: int, y: int, w: int, c: tuple) -> None:
    for d in range(w):
        t.put(x + d, y + (1 if d in (0, w - 1) else 0), c)


def save(t: Tile, name: str) -> None:
    t.im.save(OUT / ("tiles/" + name + ".png"))


def glade() -> None:
    rng = random.Random(1601)
    t = Tile(128, tone(MOSS, 0.62))
    base(t, rng, MOSS, 0.62, 90)
    scatter(t, rng, 200, [MOSS, MOSS_L, MOSS_D], 0.74)
    for _ in range(9):
        fern(t, rng.randrange(128), rng.randrange(128), tone(MOSS, 0.8), tone(MOSS_L, 0.74))
    for _ in range(22):  # Wildflowers: white, pink and amber.
        flower(t, rng.randrange(128), rng.randrange(128), rng.choice((FRO, BLO, BLO_L, LEAF)), 0.9)
    for _ in range(10):
        leaf(t, rng.randrange(128), rng.randrange(128), tone(rng.choice((LEAF, LEAF_D)), 0.8), tone(BARK_D, 0.9))
    for _ in range(3):  # Dappled light: pale discs.
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(5, 8), tone(MOSS_L, 0.7))
    save(t, "greenwood_glade")


def deep_wood() -> None:
    rng = random.Random(1602)
    t = Tile(128, tone(MOSS_D, 0.75))
    base(t, rng, MOSS_D, 0.75, 100)
    scatter(t, rng, 150, [MOSS_D, MOSS, BARK_D], 0.62)
    for _ in range(7):
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(28, 60), tone(BARK, 0.6), tone(BARK_L, 0.5))
    for _ in range(14):  # Mushroom clusters (amber caps in the dark).
        x, y = rng.randrange(128), rng.randrange(128)
        for k in range(3):
            shroom(t, x + k * 5 - 4, y + (k % 2) * 3, rng.choice((LEAF_D, BLO_D)), 0.82)
    for _ in range(40):  # Dead leaves.
        leaf(t, rng.randrange(128), rng.randrange(128), tone(rng.choice((BARK, LEAF_D)), 0.6), tone(INK, 1.2))
    for _ in range(10):  # Fireflies of cold light.
        t.put(rng.randrange(128), rng.randrange(128), tone(FRO, 0.7))
    save(t, "greenwood_deep_wood")


def hunting_grounds() -> None:
    rng = random.Random(1603)
    t = Tile(128, tone(MOSS, 0.66))
    base(t, rng, MOSS, 0.66, 70)
    for _ in range(150):  # Tall grass blades, four px.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(4):
            t.put(x + (d // 3), y - d, tone(rng.choice((MOSS, MOSS_L)), 0.6 + 0.07 * d))
    for _ in range(3):  # A trampled track of hoof prints.
        x, y = rng.randrange(128), rng.randrange(128)
        for k in range(7):
            hoof(t, x + k * 9, y + (k % 2) * 6 + k, tone(BARK_D, 0.9))
    for _ in range(3):
        antler(t, rng, rng.randrange(128), rng.randrange(128))
    for _ in range(8):
        leaf(t, rng.randrange(128), rng.randrange(128), tone(LEAF, 0.7), tone(BARK_D, 0.9))
    save(t, "greenwood_hunting_grounds")


def stags_hollow() -> None:
    rng = random.Random(1604)
    t = Tile(128, tone(BARK_D, 0.82))
    base(t, rng, BARK_D, 0.82, 90)
    scatter(t, rng, 170, [BARK, BARK_D, MOSS_D], 0.62)
    t.disc(64, 64, 22, tone(BARK_D, 0.7))  # A trodden ring of bare earth, the stag's dais.
    for a in range(20):
        r = 23
        t.put(round(64 + math.cos(a / 20 * math.tau) * r), round(64 + math.sin(a / 20 * math.tau) * r * 0.9), tone(BARK_L, 0.55))
    for _ in range(6):
        antler(t, rng, rng.randrange(128), rng.randrange(128))
    for _ in range(8):
        bone(t, rng.randrange(128), rng.randrange(128))
    for _ in range(40):
        leaf(t, rng.randrange(128), rng.randrange(128), tone(rng.choice((LEAF_D, BARK)), 0.62), tone(INK, 1.2))
    for _ in range(14):
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(1, 3), tone(MOSS_D, 0.7))
    save(t, "greenwood_stags_hollow")


def rose_maze() -> None:
    rng = random.Random(1611)
    t = Tile(128, tone(MOSS, 0.55))
    base(t, rng, MOSS, 0.55, 80)
    scatter(t, rng, 160, [MOSS, MOSS_L], 0.6)
    for y0 in (28, 92):  # Two flagstone paths (pale, lined) crossing the tile.
        for y in range(y0, y0 + 14):
            for x in range(128):
                t.put(x, y, tone(ASH, 0.78 if (x // 9 + y // 7) % 2 else 0.7))
        for x in range(128):
            t.put(x, y0, tone(INK, 1.6))
            t.put(x, y0 + 13, tone(INK, 1.6))
    for _ in range(36):  # Fallen rose petals, red-pink.
        x, y = rng.randrange(128), rng.randrange(128)
        c = tone(rng.choice((BLO_D, BLO, BLO_L)), 0.85)
        t.put(x, y, c)
        t.put(x + 1, y + 1, c)
    for _ in range(6):  # Thorny leaves.
        leaf(t, rng.randrange(128), rng.randrange(128), tone(MOSS_D, 0.9), tone(BLO_D, 0.8))
    save(t, "fae_court_rose_maze")


def revel() -> None:
    rng = random.Random(1612)
    t = Tile(128, tone(MOSS, 0.6))
    base(t, rng, MOSS, 0.6, 70)
    scatter(t, rng, 130, [MOSS, MOSS_L], 0.66)
    for cx, cy in ((32, 32), (96, 96)):  # Two dance floors of inlaid stone rings.
        for r in (14, 19):
            for a in range(60):
                t.put(round(cx + math.cos(a / 60 * math.tau) * r), round(cy + math.sin(a / 60 * math.tau) * r * 0.85), tone(ASH, 0.82))
        t.disc(cx, cy, 5, tone(BLO_D, 0.8))
        t.disc(cx, cy, 2, tone(BLO_L, 0.85))
    for _ in range(70):  # Confetti petals of every colour.
        x, y = rng.randrange(128), rng.randrange(128)
        c = tone(rng.choice((BLO, BLO_L, LEAF, LEAF_L, FRO)), 0.88)
        t.put(x, y, c)
        t.put(x + 1, y, c)
    for _ in range(3):  # Dropped ribbon strips.
        x, y = rng.randrange(128), rng.randrange(128)
        c = tone(rng.choice((BLO, LEAF)), 0.8)
        for d in range(10):
            t.put(x + d, y + round(math.sin(d / 2.0)), c)
    save(t, "fae_court_revel")


def mirror_lake() -> None:
    rng = random.Random(1613)
    t = Tile(128, tone(FRO_D, 0.5))
    base(t, rng, FRO_D, 0.5, 90)
    for _ in range(46):  # Ripples: short pale arcs.
        ripple(t, rng.randrange(128), rng.randrange(128), rng.randint(6, 14), tone(rng.choice((FRO_M, FRO)), 0.62))
    for _ in range(8):  # Lily pads with a pink bud.
        x, y = rng.randrange(128), rng.randrange(128)
        t.disc(x, y, 4, tone(MOSS_D, 1.05))
        t.disc(x, y, 3, tone(MOSS, 0.7))
        t.put(x + 1, y - 1, tone(BLO, 0.9))
        t.put(x + 4, y, tone(FRO_D, 0.5))  # The pad's notch.
    for _ in range(6):  # Reflected sparkles.
        t.put(rng.randrange(128), rng.randrange(128), tone(FRO, 0.9))
    save(t, "fae_court_mirror_lake")


def throne_of_blossoms() -> None:
    rng = random.Random(1614)
    t = Tile(128, tone(BLO_D, 0.72))
    base(t, rng, BLO_D, 0.72, 90)
    for _ in range(190):  # A carpet of petals.
        x, y = rng.randrange(128), rng.randrange(128)
        c = tone(rng.choice((BLO, BLO_L, BLO_D, LEAF_L)), 0.62 if rng.random() < 0.8 else 0.9)
        t.put(x, y, c)
        t.put(x + 1, y, c)
    for _ in range(12):
        flower(t, rng.randrange(128), rng.randrange(128), rng.choice((BLO_L, BLO, LEAF)), 0.82)
    for _ in range(9):
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(12, 26), tone(MOSS_D, 0.9), tone(MOSS, 0.7))
    for _ in range(5):
        leaf(t, rng.randrange(128), rng.randrange(128), tone(MOSS, 0.6), tone(MOSS_D, 0.8))
    save(t, "fae_court_throne_of_blossoms")


def roots() -> None:
    rng = random.Random(1621)
    t = Tile(128, tone(BARK_D, 0.8))
    base(t, rng, BARK_D, 0.8, 90)
    for _ in range(11):
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(60, 120), tone(BARK, 0.6), tone(BARK_L, 0.55))
    for _ in range(14):  # Thin side roots.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(rng.randint(10, 22)):
            t.put(x + d, y + d // 3, tone(BARK, 0.5))
    for _ in range(18):
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(1, 3), tone(MOSS_D, 0.7))
    scatter(t, rng, 90, [BARK_L], 0.5)
    for _ in range(6):  # Pale root hairs / mycelium threads.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(8):
            t.put(x + d, y + (d % 2), tone(FRO, 0.5))
    save(t, "world_tree_roots")


def trunk_stair() -> None:
    rng = random.Random(1622)
    t = Tile(128, tone(BARK_D, 0.85))
    base(t, rng, BARK_D, 0.85, 70)
    for y in range(0, 128, 32):  # Great bark ledges, each lit on its upper edge and dark beneath: a stair.
        for x in range(128):
            wob = round(2 * math.sin(x / 11.0 + y))
            t.put(x, y + wob, tone(BARK_L, 0.62))
            t.put(x, y + wob + 1, tone(BARK, 0.7))
            t.put(x, y + wob + 2, tone(INK, 1.4))
            t.put(x, y + wob + 3, tone(INK, 1.1))
    for _ in range(40):  # Vertical bark furrows.
        x, y = rng.randrange(128), rng.randrange(128)
        for d in range(rng.randint(6, 16)):
            t.put(x + (d // 6), y + d, tone(INK, 1.35))
    for _ in range(20):
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(1, 2), tone(MOSS_D, 0.75))
    for _ in range(5):
        shroom(t, rng.randrange(128), rng.randrange(128), LEAF_D, 0.8)
    save(t, "world_tree_trunk_stair")


def crown() -> None:
    rng = random.Random(1623)
    t = Tile(128, tone(MOSS_D, 0.78))
    base(t, rng, MOSS_D, 0.78, 110)
    for _ in range(90):  # A canopy of overlapping leaves, dark and mid.
        x, y = rng.randrange(128), rng.randrange(128)
        leaf(t, x, y, tone(rng.choice((MOSS, MOSS_D, MOSS_L)), rng.choice((0.55, 0.7, 0.85))), tone(MOSS_D, 0.7))
    for _ in range(4):  # Dapples of sunlight.
        t.disc(rng.randrange(128), rng.randrange(128), rng.randint(5, 9), tone(MOSS_L, 0.68))
    for _ in range(18):
        flower(t, rng.randrange(128), rng.randrange(128), rng.choice((BLO, BLO_L, FRO)), 0.88)
    for _ in range(8):  # Branches.
        root(t, rng, rng.randrange(128), rng.randrange(128), rng.randint(16, 34), tone(BARK, 0.62), tone(BARK_L, 0.5))
    save(t, "world_tree_crown")


def seed() -> None:
    rng = random.Random(1624)
    t = Tile(128, tone(BARK_D, 0.7))
    base(t, rng, BARK_D, 0.7, 80)
    scatter(t, rng, 120, [BARK_D, BARK, MOSS_D], 0.55)
    for r, k in ((12, 1.0), (24, 0.8), (38, 0.6)):  # Rings of glowing soul-teal motes around the Seed's dais.
        for a in range(int(r * 1.6)):
            ang = a / int(r * 1.6) * math.tau
            t.put(round(64 + math.cos(ang) * r), round(64 + math.sin(ang) * r), tone(SOUL, 0.55 * k + 0.1))
            if a % 3 == 0:
                t.put(round(64 + math.cos(ang) * (r + 1)), round(64 + math.sin(ang) * (r + 1)), tone(SOUL, 0.35))
    t.disc(64, 64, 6, tone(SOUL, 0.5))
    t.disc(64, 64, 3, tone(SOUL, 0.8))
    for _ in range(7):  # Roots reaching to the Seed.
        a = rng.random() * math.tau
        for d in range(30, 62):
            t.put(round(64 + math.cos(a) * d + math.sin(d / 3.0)), round(64 + math.sin(a) * d), tone(BARK, 0.55))
    for _ in range(16):  # Sprouts.
        x, y = rng.randrange(128), rng.randrange(128)
        t.put(x, y, tone(MOSS, 0.85))
        t.put(x, y - 1, tone(MOSS_L, 0.8))
        t.put(x + 1, y - 2, tone(MOSS_L, 0.8))
    save(t, "world_tree_seed")


def fairy_ring() -> None:
    rng = random.Random(1631)
    t = Tile(128, (0, 0, 0, 0))
    r0 = 62
    for y in range(128):
        for x in range(128):
            d = math.hypot(x - 63.5, y - 63.5)
            if d < r0 - (2 if (x + y) % 2 and d > r0 - 6 else 0):  # A dithered edge.
                t.put(x, y, tone(MOSS_L, 0.55 if (x * 3 + y * 5) % 9 else 0.68))
    for _ in range(120):
        x, y = rng.randrange(128), rng.randrange(128)
        if math.hypot(x - 63.5, y - 63.5) < r0 - 4:
            t.put(x, y, tone(rng.choice((MOSS, MOSS_L, FRO)), 0.7))
    for i in range(14):  # The ring of toadstools just inside the edge.
        a = i / 14 * math.tau
        shroom(t, round(63.5 + math.cos(a) * 52), round(63.5 + math.sin(a) * 52), rng.choice((BLO_D, BLO, LEAF_D)), 0.92)
    for _ in range(14):
        x, y = rng.randrange(128), rng.randrange(128)
        if math.hypot(x - 63.5, y - 63.5) < 42:
            t.put(x, y, tone(BLO_L, 0.85))
    save(t, "wild_fairy_ring")


if __name__ == "__main__":
    for f in (glade, deep_wood, hunting_grounds, stags_hollow, rose_maze, revel, mirror_lake, throne_of_blossoms, roots, trunk_stair, crown, seed, fairy_ring):
        f()
