#!/usr/bin/env python3
"""host_floors.py: the Celestial Host's twelve zone floors (assets/sprites/tiles/, 128 x 128, seamless, dark and flat so the units read): the Silver Stair's
silver_stair_ashen_foot / _stair / _cloud_shelf / _pearl_gate, the Wheel of Thrones' wheel_moon / _sun / _stars / _core and the Empyrean's empyrean_rose_edge /
_petals / _choir / _heart. Every pixel is a host_ colour of tools/palette.json darkened (starlight white, pale silver, cerulean, dawn rose; never crimson or warm
gold), light from the top-left, seeded noise only (a rerun reproduces the files). Usage (repo root): python3 art_source/host/host_floors.py"""
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
OUT = ROOT / "assets/sprites/tiles"  # Output folder.
T = 128  # Tile size (px).


def hx(h: str, k: float = 1.0) -> tuple:
    """#RRGGBB darkened / lightened by k."""
    return tuple(min(255, round(int(h[i:i + 2], 16) * k)) for i in (1, 3, 5)) + (255,)


def rosy(h: str, k: float, f: float = 0.22) -> tuple:
    """Dawn rose mixed into the floor blue (a dim rose cast that never reads crimson or brown): `f` share of rose."""
    r = hx(h)
    b = hx("#323C58", k)
    return tuple(round(r[i] * f + b[i] * (1 - f)) for i in range(3)) + (255,)


def blobs(im: Image.Image, rng: random.Random, n: int, rmin: int, rmax: int, cols: list) -> None:
    """Seamless round blobs (wrapped at the edges) of the given colours."""
    for _ in range(n):
        cx, cy, r, c = rng.randrange(T), rng.randrange(T), rng.randint(rmin, rmax), rng.choice(cols)
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r:
                    im.putpixel(((cx + x) % T, (cy + y) % T), c)


def specks(im: Image.Image, rng: random.Random, n: int, cols: list) -> None:
    for _ in range(n):
        im.putpixel((rng.randrange(T), rng.randrange(T)), rng.choice(cols))


def base(h: str, k: float = 1.0) -> Image.Image:
    return Image.new("RGBA", (T, T), hx(h, k))


def ashen_foot(seed: int) -> Image.Image:
    rng = random.Random(seed)
    im = base("#2A3040")
    blobs(im, rng, 40, 3, 9, [hx("#2A3040", 0.9), hx("#343C50"), hx("#242A38")])
    specks(im, rng, 220, [hx("#8A96AC", 0.45), hx("#C9D2E0", 0.4), hx("#1A2236")])
    return im


def steps(seed: int) -> Image.Image:
    """Wide pale steps: 128 x 32 bands with a lit lip."""
    rng = random.Random(seed)
    im = base("#2A3652")
    for r in range(4):
        k = rng.uniform(0.95, 1.15)
        for y in range(32):
            for x in range(T):
                c = hx("#34405E", k)
                if y == 0:
                    c = hx("#1A2236")
                elif y == 1:
                    c = hx("#8A96AC", 0.55 * k)
                elif y > 27:
                    c = hx("#34405E", k * 0.82)
                im.putpixel((x, r * 32 + y), c)
    specks(im, rng, 160, [hx("#C9D2E0", 0.35), hx("#1A2236")])
    return im


def cloud_shelf(seed: int) -> Image.Image:
    rng = random.Random(seed)
    im = base("#26324E")
    blobs(im, rng, 22, 10, 24, [hx("#34456A"), hx("#2E3D5E"), hx("#3C4E76")])
    blobs(im, rng, 14, 5, 12, [hx("#4A5C86"), hx("#3C4E76")])
    specks(im, rng, 140, [hx("#DCE4F0", 0.4), hx("#9CC8F0", 0.35)])
    return im


def pearl(seed: int) -> Image.Image:
    """64 x 64 pearl flagstones, a faint dawn-rose sheen."""
    rng = random.Random(seed)
    im = base("#323A52")
    for r in range(2):
        for c in range(2):
            k = rng.uniform(0.95, 1.2)
            rose = rng.random() < 0.35
            for y in range(64):
                for x in range(64):
                    col = rosy("#F2B8C6", k, 0.2) if rose and (x + y) % 11 < 2 else hx("#3A4460", k)
                    if x == 0 or y == 0:
                        col = hx("#1A2236")
                    elif x == 1 or y == 1:
                        col = hx("#C9D2E0", 0.3 * k)
                    im.putpixel((c * 64 + x, r * 64 + y), col)
    specks(im, rng, 120, [hx("#F4F7FF", 0.35)])
    return im


def moon(seed: int) -> Image.Image:
    rng = random.Random(seed)
    im = base("#363E50")
    for _ in range(9):  # Craters: a dark rim-lit disc.
        cx, cy, r = rng.randrange(T), rng.randrange(T), rng.randint(4, 11)
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                d = x * x + y * y
                if d <= r * r:
                    c = hx("#262C3C") if d < (r - 2) ** 2 else hx("#8A96AC", 0.5)
                    im.putpixel(((cx + x) % T, (cy + y) % T), c)
    specks(im, rng, 200, [hx("#C9D2E0", 0.4), hx("#2A3040")])
    return im


def sun(seed: int) -> Image.Image:
    """Pale light, never warm: diagonal rays of silver-white on a dim grey-blue field."""
    rng = random.Random(seed)
    im = base("#3C4660")
    for y in range(T):
        for x in range(T):
            if (x + y) % 32 < 3:
                im.putpixel((x, y), hx("#C9D2E0", 0.55))
            elif (x + y) % 32 < 7:
                im.putpixel((x, y), hx("#4A5676"))
    blobs(im, rng, 8, 3, 6, [hx("#F4F7FF", 0.5)])
    specks(im, rng, 160, [hx("#F4F7FF", 0.4), hx("#34405E")])
    return im


def stars(seed: int) -> Image.Image:
    rng = random.Random(seed)
    im = base("#141C36")
    blobs(im, rng, 16, 8, 20, [hx("#1A2442"), hx("#182040")])
    for _ in range(90):
        x, y = rng.randrange(T), rng.randrange(T)
        im.putpixel((x, y), hx(rng.choice(["#9CC8F0", "#F4F7FF", "#3E8FD8"]), 0.6))
    for _ in range(10):  # A few plus-shaped stars.
        x, y = rng.randrange(T), rng.randrange(T)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            im.putpixel(((x + dx) % T, (y + dy) % T), hx("#F4F7FF", 0.55))
    return im


def core(seed: int) -> Image.Image:
    """The Wheel's rim: concentric silver rings round the tile's centre (seamless: rings repeat at the tile period) with eye studs."""
    rng = random.Random(seed)
    im = base("#2A3350")
    for y in range(T):
        for x in range(T):
            d = math.hypot((x % 64) - 32, (y % 64) - 32)
            if abs(d - 24) < 1.5:
                im.putpixel((x, y), hx("#8A96AC", 0.55))
            elif abs(d - 14) < 1.0:
                im.putpixel((x, y), hx("#1F4F8F", 0.9))
    for cx in (32, 96):
        for cy in (32, 96):
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                im.putpixel((cx + dx, cy + dy), hx("#9CC8F0", 0.7))
    specks(im, rng, 140, [hx("#C9D2E0", 0.3), hx("#1A2236")])
    return im


def petals(seed: int, hi: float, rose: float, curl: int) -> Image.Image:
    """Empyrean: overlapping petal arcs of pale light on a dim cool-white / dawn-rose field; `hi` the value, `rose` the share of rose arcs (value only, never a new hue)."""
    rng = random.Random(seed)
    im = base("#323C58", hi)
    for _ in range(26):
        cx, cy, r = rng.randrange(T), rng.randrange(T), rng.randint(14, 30)
        col = rosy("#F2B8C6", hi, 0.2) if rng.random() < rose else hx("#8A96AC", 0.3 * hi)
        for a in range(0, 360, 2):
            for rr in (r, r - 1):
                x = round(cx + rr * math.cos(math.radians(a))) % T
                y = round(cy + rr * math.sin(math.radians(a)) * 0.6) % T
                if (a // curl) % 2 == 0:
                    im.putpixel((x, y), col)
    blobs(im, rng, 18, 4, 10, [hx("#3A4666", hi), hx("#2E3850", hi)])
    specks(im, rng, 150, [hx("#FCE4EA", 0.35 * hi), hx("#F4F7FF", 0.35 * hi)])
    return im


MAKERS = {"silver_stair_ashen_foot": lambda: ashen_foot(11), "silver_stair_stair": lambda: steps(12), "silver_stair_cloud_shelf": lambda: cloud_shelf(13),
          "silver_stair_pearl_gate": lambda: pearl(14), "wheel_moon": lambda: moon(21), "wheel_sun": lambda: sun(22), "wheel_stars": lambda: stars(23),
          "wheel_core": lambda: core(24), "empyrean_rose_edge": lambda: petals(31, 1.0, 0.15, 3), "empyrean_petals": lambda: petals(32, 1.08, 0.3, 4),
          "empyrean_choir": lambda: petals(33, 1.15, 0.45, 5), "empyrean_heart": lambda: petals(34, 1.25, 0.6, 6)}

if __name__ == "__main__":
    for name, fn in MAKERS.items():
        fn().save(OUT / (name + ".png"))
        print(name)
