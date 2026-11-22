#!/usr/bin/env python3
"""titans_tiles.py: draws the Age of Titans' floors, markers and effect strips on the art grid (Act XIV slot, stage key primeval;
ART_BIBLE "Act XIV slot: the Age of Titans"). Every pixel is a primeval_ colour of tools/palette.json (floors darkened: sprites stand
out against them), light from the top-left, seeded noise only (a rerun reproduces the files exactly).
Outputs (assets/sprites/): tiles/primeval_fern, primeval_plain, primeval_ash (128x128 seamless); markers/primeval_alpha (10x6 chevron),
primeval_shadow (48x24 ellipse), primeval_bomb (64x64 ring); fx/primeval_dust_line (4x128), primeval_dust_front (56x128, tiling),
primeval_bomb_burst (6 frames of 64x64), primeval_fossil_rise (6 frames of 48x48).
Usage (repo root): python3 art_source/titans/titans_tiles.py"""
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
OUT = ROOT / "assets/sprites"  # Output root.
INK = "#120F0D"  # Tar-black outline.
FERN_D, FERN, FERN_L = "#24451F", "#4D8534", "#8CC46A"  # Fern ramp.
OCH_D, OCH, OCH_L = "#7E552A", "#C89448", "#E8C88A"  # Dust ochre ramp.
TAR_D, TAR, TAR_L = "#231C18", "#4A3A30", "#6E5A4C"  # Tar ramp.
LAV_D, LAV, LAV_L = "#8A2E0C", "#EF6B1C", "#FFC070"  # Lava ramp.
BONE_D, BONE, STREAK = "#9C9078", "#E7DEC9", "#F8F6EE"  # Bone ramp.


def rgb(h: str, a: int = 255) -> tuple:
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), a)


def tone(h: str, k: float) -> tuple:
    r, g, b, _ = rgb(h)
    return (min(255, round(r * k)), min(255, round(g * k)), min(255, round(b * k)), 255)


def floor(name: str, base: str, speck: list, seed: int, blade: str, k: float) -> None:
    """Seamless 128x128: a dark base with seeded blotches (low-frequency, wrapped) and sparse light specks / 3 px blades."""
    T = 128
    rng = random.Random(seed)
    im = Image.new("RGBA", (T, T), tone(base, k))
    for _ in range(70):  # Blotches: small filled discs of a slightly lighter or darker base.
        cx, cy, r = rng.randrange(T), rng.randrange(T), rng.randint(3, 8)
        t = tone(base, k * rng.choice((0.8, 0.9, 1.15, 1.25)))
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r:
                    im.putpixel(((cx + x) % T, (cy + y) % T), t)
    for _ in range(190):
        x, y = rng.randrange(T), rng.randrange(T)
        im.putpixel((x, y), tone(rng.choice(speck), k * 1.05))
    for _ in range(40):  # Blades / fronds: three pixels tall.
        x, y = rng.randrange(T), rng.randrange(T)
        for d in range(3):
            im.putpixel((x % T, (y - d) % T), tone(blade, k * (0.9 + 0.12 * d)))
    im.save(OUT / ("tiles/" + name + ".png"))


def chevron() -> None:
    """10 x 6 bone-white chevron over the alpha's head, 1 px ink outline."""
    im = Image.new("RGBA", (10, 6), (0, 0, 0, 0))
    pts = {(1, 1), (2, 2), (3, 3), (4, 4), (5, 4), (6, 3), (7, 2), (8, 1), (2, 1), (3, 2), (4, 3), (5, 3), (6, 2), (7, 1)}
    for x, y in pts:
        im.putpixel((x, y), rgb(BONE if y < 3 else STREAK))
    a = im.copy()
    for y in range(6):
        for x in range(10):
            if a.getpixel((x, y))[3] == 0 and any(0 <= x + dx < 10 and 0 <= y + dy < 6 and a.getpixel((x + dx, y + dy))[3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), rgb(INK))
    im.save(OUT / "markers/primeval_alpha.png")


def shadow() -> None:
    """48 x 24 soft tar-black ellipse (a diving Skyraider's shadow): two stepped alpha bands, no gradient."""
    im = Image.new("RGBA", (48, 24), (0, 0, 0, 0))
    for y in range(24):
        for x in range(48):
            d = math.hypot((x - 23.5) / 24, (y - 11.5) / 12)
            if d <= 0.6:
                im.putpixel((x, y), rgb(INK, 150))
            elif d <= 1.0:
                im.putpixel((x, y), rgb(INK, 80))
    im.save(OUT / "markers/primeval_shadow.png")


def bomb_ring() -> None:
    """64 x 64 volcanic bomb landing circle: a lava ring (3 px) with a dark-orange inner edge, dashed outer rim."""
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5)
            if 27 <= d <= 30.5:
                im.putpixel((x, y), rgb(LAV, 235))
            elif 24.5 <= d < 27:
                im.putpixel((x, y), rgb(LAV_D, 190))
            elif 30.5 < d <= 31.9 and (int(math.atan2(y - 31.5, x - 31.5) * 10) % 2 == 0):
                im.putpixel((x, y), rgb(LAV_L, 200))
    im.save(OUT / "markers/primeval_bomb.png")


def dust() -> None:
    """Dust line (4x128, tiles along y: dashes of ochre) and dust front (56x128, tiles along y: stepped alpha ochre puffs)."""
    line = Image.new("RGBA", (4, 128), (0, 0, 0, 0))
    for y in range(128):
        if (y // 8) % 2 == 0:
            for x in (1, 2): line.putpixel((x, y), rgb(OCH_L, 235))
            for x in (0, 3): line.putpixel((x, y), rgb(OCH, 120))
    line.save(OUT / "fx/primeval_dust_line.png")
    rng = random.Random(1414)
    front = Image.new("RGBA", (56, 128), (0, 0, 0, 0))
    for _ in range(46):  # Puffs: wrapped in y so the strip tiles; denser on the right (the front's leading edge).
        cx, cy, r = int(56 * rng.random() ** 0.6), rng.randrange(128), rng.randint(4, 9)
        col = rng.choice(((OCH, 150), (OCH_L, 120), (OCH_D, 140)))
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r and 0 <= cx + x < 56:
                    p = ((cx + x), (cy + y) % 128)
                    if front.getpixel(p)[3] < col[1]:
                        front.putpixel(p, rgb(col[0], col[1]))
    front.save(OUT / "fx/primeval_dust_front.png")


def bomb_burst() -> None:
    """6 frames of 64x64: a splash growing (lava core, orange ring, ember specks flying out), the last frames fading."""
    S = Image.new("RGBA", (6 * 64, 64), (0, 0, 0, 0))
    rng = random.Random(77)
    for f in range(6):
        r = 6 + f * 5
        a = 255 if f < 3 else int(255 * (6 - f) / 3)
        for y in range(64):
            for x in range(64):
                d = math.hypot(x - 31.5, y - 31.5)
                if d <= r * 0.5: S.putpixel((f * 64 + x, y), rgb(LAV_L, a))
                elif d <= r * 0.8: S.putpixel((f * 64 + x, y), rgb(LAV, a))
                elif d <= r: S.putpixel((f * 64 + x, y), rgb(LAV_D, a))
        for _ in range(8 + f * 2):  # Embers.
            ang, dist = rng.random() * math.tau, r + rng.randint(1, 10)
            x, y = int(31.5 + math.cos(ang) * dist), int(31.5 + math.sin(ang) * dist)
            if 0 <= x < 64 and 0 <= y < 64: S.putpixel((f * 64 + x, y), rgb(LAV_L, a))
    S.save(OUT / "fx/primeval_bomb_burst.png")


def fossil_rise() -> None:
    """6 frames of 48x48: bone dust billowing up from a point (bone-white puffs, a few ochre grains), fading."""
    S = Image.new("RGBA", (6 * 48, 48), (0, 0, 0, 0))
    rng = random.Random(91)
    for f in range(6):
        a = 240 if f < 3 else int(240 * (6 - f) / 3)
        for _ in range(14 + f * 4):
            ang = rng.random() * math.tau
            dist = (4 + f * 3.2) * rng.random() ** 0.5 + 2
            cx, cy = 23.5 + math.cos(ang) * dist, 30 + math.sin(ang) * dist * 0.6 - f * 2
            r = rng.randint(1, 3)
            col = rng.choice((BONE, BONE, STREAK, BONE_D, OCH_L))
            for y in range(-r, r + 1):
                for x in range(-r, r + 1):
                    px, py = int(cx + x), int(cy + y)
                    if x * x + y * y <= r * r and 0 <= px < 48 and 0 <= py < 48:
                        S.putpixel((f * 48 + px, py), rgb(col, a))
    S.save(OUT / "fx/primeval_fossil_rise.png")


if __name__ == "__main__":
    (OUT / "markers").mkdir(exist_ok=True)
    (OUT / "fx").mkdir(exist_ok=True)
    floor("primeval_fern", FERN_D, [FERN, FERN_L, TAR], 1401, FERN, 0.62)
    floor("primeval_plain", OCH_D, [OCH, OCH_L, TAR_L], 1402, OCH, 0.7)
    floor("primeval_ash", TAR_D, [TAR_L, TAR, LAV_D], 1403, TAR_L, 1.15)
    chevron()
    shadow()
    bomb_ring()
    dust()
    bomb_burst()
    fossil_rise()
