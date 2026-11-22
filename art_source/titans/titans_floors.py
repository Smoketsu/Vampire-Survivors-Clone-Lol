#!/usr/bin/env python3
"""titans_floors.py: the Age of Titans' zone floors (assets/sprites/tiles/, 128 x 128, seamless, dark and flat so the units read): the Fern Basin's fern_basin_fern_floor /
_tar_seep / _river_ford / _nesting_hollow, the Great Plain's great_plain_dust_flats / _watering_hole / _canyon / _bone_gate, the Last Day's last_day_scorched_plain /
_ash_forest / _lava_fields / _impact_rim, and the tar patch primeval_tar. Each floor has VISIBLE FEATURES drawn on the grid (owner, Host round: plain noise looks weak): fern
fronds, tar bubbles, ripples, eggshells, cracks, hoof prints, strata, bones, embers, charred stumps, glowing lava seams, radial impact cracks. Every colour is a primeval_ ramp
colour of tools/palette.json darkened to the stage's ground base (scripts/data/stages/*_stage.gd), light from the top-left, seeded noise only (a rerun reproduces the files).
Usage (repo root): python3 art_source/titans/titans_floors.py"""
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
OUT = ROOT / "assets/sprites/tiles"  # Output folder.
T = 128  # Tile size (px).
INK = "#120F0D"
FERN = ["#24451F", "#4D8534", "#8CC46A"]  # Fern ramp.
OCH = ["#7E552A", "#C89448", "#E8C88A"]  # Dust ochre ramp.
TAR = ["#231C18", "#4A3A30", "#6E5A4C"]  # Tar ramp.
LAV = ["#8A2E0C", "#EF6B1C", "#FFC070"]  # Lava ramp.
BONE = ["#9C9078", "#E7DEC9", "#F8F6EE"]  # Bone ramp.


def hx(h: str, k: float = 1.0) -> tuple:
    """#RRGGBB scaled by k (clamped)."""
    return tuple(min(255, round(int(h[i:i + 2], 16) * k)) for i in (1, 3, 5)) + (255,)


class Tile:
    """A wrapped 128 x 128 canvas with the seeded drawing helpers the floors share."""

    def __init__(self, base: tuple, seed: int) -> None:
        self.im = Image.new("RGBA", (T, T), base + (255,))
        self.rng = random.Random(seed)  # Seeded: reruns reproduce the file.
        self.base = base

    def put(self, x: int, y: int, c: tuple) -> None:
        self.im.putpixel((int(x) % T, int(y) % T), c)

    def shade(self, k: float) -> tuple:
        return tuple(min(255, round(v * k)) for v in self.base) + (255,)

    def blobs(self, n: int, rmin: int, rmax: int, ks: list) -> None:
        for _ in range(n):
            cx, cy, r, k = self.rng.randrange(T), self.rng.randrange(T), self.rng.randint(rmin, rmax), self.rng.choice(ks)
            for y in range(-r, r + 1):
                for x in range(-r, r + 1):
                    if x * x + y * y <= r * r + self.rng.randint(-r, r):
                        self.put(cx + x, cy + y, self.shade(k))

    def specks(self, n: int, cols: list) -> None:
        for _ in range(n):
            self.put(self.rng.randrange(T), self.rng.randrange(T), self.rng.choice(cols))

    def walk(self, x: float, y: float, n: int, col: tuple, heading: float, wander: float = 0.5, hi: tuple = None) -> None:
        """A wandering crack / seam; `hi` is a lighter pixel drawn up-left of each step (a lit lip)."""
        for _ in range(n):
            heading += self.rng.uniform(-wander, wander)
            x += math.cos(heading)
            y += math.sin(heading)
            self.put(x, y, col)
            if hi:
                self.put(x - 1, y - 1, hi)

    def frond(self, x: int, y: int, ln: int, ang: float, cols: list) -> None:
        """A fern frond: a stem with paired leaflets angled back along it."""
        for i in range(ln):
            sx, sy = x + math.cos(ang) * i, y + math.sin(ang) * i
            self.put(sx, sy, cols[0])
            if i > 1 and i % 2 == 0:
                w = max(1, (ln - i) // 3 + 1) if i > ln // 2 else min(4, i // 2 + 1)
                for s in (-1, 1):
                    px, py = math.cos(ang + s * 1.2), math.sin(ang + s * 1.2)
                    for j in range(1, w + 1):
                        self.put(sx + px * j, sy + py * j, cols[1] if j < w else cols[2])

    def save(self, name: str) -> None:
        self.im.save(OUT / (name + ".png"))


def fern_floor() -> None:
    t = Tile((33, 51, 28), 1401)
    t.blobs(60, 4, 11, [0.82, 0.92, 1.12, 1.22])
    t.specks(160, [hx(FERN[2], 0.45), hx(FERN[0], 0.7), hx(OCH[0], 0.6)])
    for _ in range(11):  # Big fronds with leaflets.
        t.frond(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(14, 22), t.rng.uniform(-2.6, -0.5), [hx(FERN[0], 0.9), hx(FERN[1], 0.8), hx(FERN[2], 0.75)])
    for _ in range(14):  # Roots and fallen twigs.
        t.walk(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(8, 16), hx(OCH[0], 0.55), t.rng.uniform(0, 6.3), 0.35)
    t.save("fern_basin_fern_floor")


def tar_seep() -> None:
    t = Tile((31, 38, 26), 1402)
    t.blobs(40, 3, 9, [0.8, 0.92, 1.1])
    for _ in range(6):  # Tar puddles with a lit lip and a gloss pixel.
        cx, cy, rx, ry = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(8, 16), t.rng.randint(5, 9)
        for y in range(-ry - 1, ry + 2):
            for x in range(-rx - 1, rx + 2):
                d = (x / rx) ** 2 + (y / ry) ** 2
                if d <= 1.0:
                    t.put(cx + x, cy + y, hx(TAR[0], 0.8) if d < 0.72 else hx(INK))
                elif d <= 1.25 and x < 0:
                    t.put(cx + x, cy + y, hx(TAR[2], 0.55))
        t.put(cx - rx // 2, cy - ry // 3, hx(TAR[2], 0.9))
        t.put(cx - rx // 2 + 1, cy - ry // 3, hx(TAR[1], 1.2))
        for _ in range(3):  # Bubbles: a ring with a glint.
            bx, by = cx + t.rng.randint(-rx // 2, rx // 2), cy + t.rng.randint(-ry // 2, ry // 2)
            for ox, oy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                t.put(bx + ox, by + oy, hx(TAR[2], 0.7))
    t.specks(90, [hx(FERN[0], 0.8), hx(TAR[2], 0.5)])
    for _ in range(5):
        t.frond(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(8, 12), t.rng.uniform(-2.4, -0.7), [hx(FERN[0], 0.8), hx(FERN[1], 0.65), hx(FERN[2], 0.6)])
    t.save("fern_basin_tar_seep")


def river_ford() -> None:
    t = Tile((38, 46, 33), 1403)
    t.blobs(50, 4, 10, [0.85, 0.95, 1.1, 1.2])
    for _ in range(26):  # Ripples: short horizontal strokes with a pale lit top.
        x, y, ln = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(5, 12)
        for i in range(ln):
            t.put(x + i, y + (1 if i in (0, ln - 1) else 0), hx(FERN[2], 0.42))
            t.put(x + i, y + 1 + (1 if i in (0, ln - 1) else 0), hx(FERN[0], 0.7))
    for _ in range(18):  # Wet pebbles.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(TAR[2], 0.8))
        t.put(x + 1, y, hx(TAR[1], 0.9))
        t.put(x, y - 1, hx(OCH[2], 0.45))
    t.specks(60, [hx(OCH[0], 0.6), hx(BONE[1], 0.3)])
    t.save("fern_basin_river_ford")


def nesting_hollow() -> None:
    t = Tile((43, 41, 28), 1404)
    t.blobs(50, 4, 10, [0.85, 0.95, 1.1, 1.2])
    for _ in range(24):  # Dry twigs and grass.
        t.walk(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(6, 14), hx(OCH[0], 0.75), t.rng.uniform(0, 6.3), 0.3, hx(OCH[1], 0.42))
    for _ in range(20):  # Eggshell fragments: pale curved flecks with a shaded edge.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (3, 1)):
            t.put(x + dx, y + dy, hx(BONE[1], 0.55))
        t.put(x + 3, y + 2, hx(BONE[0], 0.4))
        t.put(x, y - 1, hx(BONE[2], 0.55))
    for _ in range(4):  # Trampled grass tufts.
        t.frond(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(8, 11), t.rng.uniform(-2.5, -0.6), [hx(OCH[0], 0.8), hx(FERN[1], 0.6), hx(FERN[2], 0.5)])
    t.specks(90, [hx(OCH[1], 0.4), hx(TAR[0], 1.4)])
    t.save("fern_basin_nesting_hollow")


def cracks(t: Tile, n: int, dark: tuple, lit: tuple, ln: tuple = (14, 30)) -> None:
    for _ in range(n):
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.walk(x, y, t.rng.randint(*ln), dark, t.rng.uniform(0, 6.3), 0.55, lit)
        if t.rng.random() < 0.5:  # A fork.
            t.walk(x, y, t.rng.randint(6, 12), dark, t.rng.uniform(0, 6.3), 0.5, lit)


def dust_flats() -> None:
    t = Tile((77, 64, 36), 1405)
    t.blobs(50, 5, 12, [0.88, 0.95, 1.08, 1.16])
    for _ in range(14):  # Wind ripples in the dust.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(10, 20)):
            t.put(x + i, y + round(math.sin(i / 3.0)), hx(OCH[2], 0.42))
            t.put(x + i, y + 1 + round(math.sin(i / 3.0)), hx(OCH[0], 0.8))
    cracks(t, 7, hx(INK, 1.4), hx(OCH[2], 0.38))
    for _ in range(9):  # Dry grass tufts.
        t.frond(t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(5, 8), t.rng.uniform(-2.4, -0.7), [hx(OCH[1], 0.5), hx(OCH[2], 0.55), hx(OCH[2], 0.65)])
    t.specks(110, [hx(OCH[2], 0.42), hx(TAR[1], 0.9)])
    t.save("great_plain_dust_flats")


def watering_hole() -> None:
    t = Tile((61, 66, 33), 1406)
    t.blobs(50, 4, 11, [0.85, 0.95, 1.08, 1.18])
    for _ in range(13):  # Hoof prints: two lobes with a dark inside.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for ox in (0, 4):
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (0, 2)):
                t.put(x + ox + dx, y + dy, hx(TAR[0], 1.6))
            t.put(x + ox - 1, y - 1, hx(OCH[2], 0.4))
    for _ in range(7):  # Mud puddles with a glint.
        cx, cy, rx = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(5, 9)
        for y in range(-3, 4):
            for x in range(-rx, rx + 1):
                if (x / rx) ** 2 + (y / 3.2) ** 2 <= 1:
                    t.put(cx + x, cy + y, hx(FERN[0], 1.25))
        t.put(cx - rx // 2, cy - 1, hx(FERN[2], 0.8))
        t.put(cx - rx // 2 + 1, cy - 1, hx(FERN[2], 0.8))
    for _ in range(8):  # Reeds.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(5, 9)):
            t.put(x, y - i, hx(FERN[1], 0.7))
        t.put(x, y - 9, hx(OCH[1], 0.6))
    t.specks(90, [hx(OCH[0], 0.6), hx(FERN[2], 0.4)])
    t.save("great_plain_watering_hole")


def canyon() -> None:
    t = Tile((77, 46, 28), 1407)
    ys = 0
    while ys < T:  # Strata: horizontal bands of slightly different red-ochre, with dark seams.
        h = t.rng.randint(7, 14)
        h = min(h, T - ys) if ys + h + 7 > T else h
        k = t.rng.choice((0.82, 0.92, 1.0, 1.1, 1.2))
        for y in range(ys, ys + h):
            for x in range(T):
                t.put(x, y, t.shade(k * (0.9 if y == ys + h - 1 else 1.0)))
        for x in range(T):
            t.put(x, ys, hx(INK, 1.3))
            if t.rng.random() < 0.5:
                t.put(x, ys + 1, hx(OCH[1], 0.5))
        ys += h
    t.blobs(20, 2, 5, [0.85, 1.15])
    cracks(t, 8, hx(INK, 1.4), hx(OCH[1], 0.5), (10, 22))
    for _ in range(40):  # Rock chips.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(TAR[1], 0.9))
        t.put(x + 1, y, hx(TAR[0], 1.4))
        t.put(x - 1, y - 1, hx(OCH[2], 0.45))
    t.save("great_plain_canyon")


def bone_gate() -> None:
    t = Tile((84, 77, 56), 1408)
    t.blobs(45, 5, 12, [0.88, 0.95, 1.08, 1.15])
    for _ in range(10):  # Rib bones: bone arcs half-buried in the dust.
        x, y, r = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(5, 9)
        for a in range(0, 160, 12):
            px, py = x + math.cos(math.radians(a + 190)) * r, y + math.sin(math.radians(a + 190)) * r
            t.put(px, py, hx(BONE[1], 0.62))
            t.put(px, py + 1, hx(BONE[0], 0.55))
            t.put(px - 1, py - 1, hx(BONE[2], 0.55))
    for _ in range(14):  # Vertebrae and long bone fragments.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(3, 6)):
            t.put(x + i, y, hx(BONE[1], 0.62))
            t.put(x + i, y + 1, hx(BONE[0], 0.55))
        t.put(x - 1, y, hx(BONE[2], 0.6))
        t.put(x - 1, y + 1, hx(BONE[2], 0.6))
    cracks(t, 6, hx(INK, 1.6), hx(OCH[2], 0.4))
    t.specks(100, [hx(OCH[2], 0.45), hx(TAR[1], 1.0)])
    t.save("great_plain_bone_gate")


def scorched_plain() -> None:
    t = Tile((43, 36, 31), 1409)
    t.blobs(55, 4, 11, [0.8, 0.92, 1.1, 1.22])
    cracks(t, 9, hx(INK, 1.3), hx(TAR[2], 0.55))
    for _ in range(10):  # Dead grass stubs, black.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(3, 6)):
            t.put(x, y - i, hx(TAR[0], 1.2))
        t.put(x, y - 6, hx(TAR[1], 0.9))
    for _ in range(16):  # Embers: orange cores with a dim halo.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(LAV[1], 0.95))
        t.put(x + 1, y, hx(LAV[0], 0.9))
        t.put(x, y + 1, hx(LAV[0], 0.7))
    t.specks(160, [hx(BONE[0], 0.42), hx(TAR[2], 0.6)])  # Ash.
    t.save("last_day_scorched_plain")


def ash_forest() -> None:
    t = Tile((56, 54, 51), 1410)
    t.blobs(55, 5, 12, [0.85, 0.95, 1.08, 1.18])
    for _ in range(7):  # Charred stump tops: ring, dark core, a pale ash lip.
        cx, cy, r = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(4, 7)
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                d = x * x + y * y
                if d <= r * r:
                    t.put(cx + x, cy + y, hx(INK, 1.2) if d > (r - 1) ** 2 else hx(TAR[0], 1.5 if (x + y) % 3 else 1.9))
        t.put(cx - r, cy - r + 1, hx(BONE[0], 0.5))
        t.walk(cx + r, cy + 1, 5, hx(INK, 1.3), 0.3, 0.3)  # A fallen branch.
    for _ in range(12):  # Fallen burnt logs.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(8, 14)):
            t.put(x + i, y, hx(TAR[0], 1.3))
            t.put(x + i, y + 1, hx(TAR[1], 0.8))
            t.put(x + i, y - 1, hx(BONE[0], 0.35) if i % 4 == 0 else hx(TAR[1], 0.7))
    t.specks(200, [hx(BONE[1], 0.4), hx(BONE[0], 0.45), hx(TAR[1], 0.8)])
    for _ in range(8):
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(LAV[1], 0.9))
    t.save("last_day_ash_forest")


def lava_fields() -> None:
    t = Tile((31, 26, 23), 1411)
    t.blobs(40, 5, 12, [0.8, 0.92, 1.15, 1.3])
    for _ in range(9):  # Glowing seams: a dark crack with orange fill and a bright core.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        n, h = t.rng.randint(16, 34), t.rng.uniform(0, 6.3)
        t.walk(x, y, n, hx(LAV[0], 0.95), h, 0.45)
        t.walk(x, y, n, hx(LAV[1], 0.9), h, 0.45)
        t.walk(x, y, n, hx(LAV[2], 0.8), h, 0.45)  # Same seed path restarted differs, so the core is a loose bright vein.
    for _ in range(12):  # Basalt plates: lit top-left edge.
        x, y, w, h2 = t.rng.randrange(T), t.rng.randrange(T), t.rng.randint(6, 12), t.rng.randint(4, 8)
        for i in range(w):
            t.put(x + i, y, hx(TAR[2], 0.7))
            t.put(x + i, y + h2, hx(INK))
        for j in range(h2):
            t.put(x, y + j, hx(TAR[2], 0.6))
            t.put(x + w, y + j, hx(INK))
    for _ in range(20):
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(LAV[1], 0.8))
    t.specks(90, [hx(TAR[1], 0.8), hx(TAR[0], 1.4)])
    t.save("last_day_lava_fields")


def impact_rim() -> None:
    t = Tile((77, 71, 66), 1412)
    t.blobs(50, 5, 12, [0.88, 0.95, 1.08, 1.16])
    c = T // 2
    for k in range(9):  # Radial shatter cracks from the middle of the tile (the impact) running past the edges (wrapped).
        a = k * 2 * math.pi / 9 + t.rng.uniform(-0.2, 0.2)
        t.walk(c + math.cos(a) * 6, c + math.sin(a) * 6, t.rng.randint(40, 70), hx(INK, 1.3), a, 0.25, hx(BONE[0], 0.4))
    for r in (18, 34, 50):  # Concentric fracture arcs.
        for d in range(0, 360, 3):
            if t.rng.random() < 0.55:
                a = math.radians(d + t.rng.uniform(-1.5, 1.5))
                t.put(c + math.cos(a) * r, c + math.sin(a) * r, hx(INK, 1.4))
    for _ in range(28):  # Glassy white shards.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        t.put(x, y, hx(BONE[2], 0.62))
        t.put(x + 1, y + 1, hx(BONE[1], 0.5))
        t.put(x + 1, y, hx(BONE[0], 0.4))
    t.specks(120, [hx(BONE[0], 0.4), hx(TAR[1], 1.0)])
    t.save("last_day_impact_rim")


def tar_patch() -> None:
    t = Tile((20, 16, 14), 1413)
    t.blobs(40, 4, 12, [0.85, 1.0, 1.15, 1.3])
    for _ in range(18):  # Gloss streaks (a lit top-left) and bubbles.
        x, y = t.rng.randrange(T), t.rng.randrange(T)
        for i in range(t.rng.randint(3, 7)):
            t.put(x + i, y, hx(TAR[2], 0.75))
            t.put(x + i, y + 1, hx(TAR[1], 0.7))
    for _ in range(12):
        bx, by = t.rng.randrange(T), t.rng.randrange(T)
        for ox, oy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
            t.put(bx + ox, by + oy, hx(TAR[2], 0.65))
        t.put(bx - 1, by - 1, hx(TAR[2], 1.0))
    t.save("primeval_tar")


if __name__ == "__main__":
    for fn in (fern_floor, tar_seep, river_ford, nesting_hollow, dust_flats, watering_hole, canyon, bone_gate, scorched_plain, ash_forest, lava_fields, impact_rim, tar_patch):
        fn()
    print("floors done")
