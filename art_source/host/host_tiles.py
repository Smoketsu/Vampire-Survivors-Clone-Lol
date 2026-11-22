#!/usr/bin/env python3
"""host_tiles.py: draws the Celestial Host's floors, markers and effect strips on the art grid (Act X slot, stage key host; ART_BIBLE
"Act X slot: the Celestial Host"). Every pixel is a host_ colour of tools/palette.json (floors darkened, the floor rule: sprites stand out
against them), light from the top-left, seeded noise only (a rerun reproduces the files exactly).
Outputs (assets/sprites/): tiles/host_stair (128x128, seamless: pale-ash steps with a silver edge, darkened), tiles/host_cloud_shadow
(128x102 ellipse, soft pale rim), markers/host_halo + host_halo_cracked (16x6), markers/host_scales (24x20), markers/host_pillar (40x120,
additive light), fx/host_shaft (32x128), fx/host_shaft_line (4x128), fx/host_trumpet_ring (8 frames of 48x24 in a strip).
Usage (repo root): python3 art_source/host/host_tiles.py"""
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
OUT = ROOT / "assets/sprites"  # Output root.
INK, SIL_D, SIL, STAR = "#0E1626", "#8A96AC", "#C9D2E0", "#F4F7FF"  # Host ink, silver dark / silver, starlight.
CER_D, CER, CER_L = "#1F4F8F", "#3E8FD8", "#9CC8F0"  # Cerulean ramp.
ROSE_D, ROSE = "#B07888", "#F2B8C6"  # Dawn rose.
SHADE = "#1A2236"  # Cloud shadow / step shade.


def rgb(h: str, a: int = 255) -> tuple:
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), a)


def tone(h: str, k: float) -> tuple:
    r, g, b, _ = rgb(h)
    return (min(255, round(r * k)), min(255, round(g * k)), min(255, round(b * k)), 255)


def stair() -> None:
    """Seamless 128 x 128: 32 x 16 px steps in offset rows, each its own dark blue-grey shade, a dark seam and a faint silver lip."""
    T, w, h = 128, 32, 16
    rng = random.Random(1013)
    im = Image.new("RGBA", (T, T), tone(SHADE, 1.5))
    for r in range(T // h):
        shift = (w // 2) if r % 2 else 0
        for c in range(T // w):
            k = rng.uniform(0.95, 1.18)
            for y in range(h):
                for x in range(w):
                    col = tone("#2A3652", k)
                    if x == 0 or y == 0:
                        col = tone(SHADE, 1.1)
                    elif y == 1:
                        col = tone(SIL_D, 0.5 * k)  # The silver edge: a thin lit lip under each seam.
                    im.putpixel(((c * w + x + shift) % T, (r * h + y) % T), col)
    for _ in range(260):
        im.putpixel((rng.randrange(T), rng.randrange(T)), tone("#2A3652", rng.uniform(0.85, 1.3)))
    im.save(OUT / "tiles/host_stair.png")


def cloud_shadow() -> None:
    """128 x 102 ellipse of dark cerulean shade with a one-pixel soft pale rim; transparent corners."""
    W, H = 128, 102
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rng = random.Random(77)
    for y in range(H):
        for x in range(W):
            d = math.hypot((x - W / 2 + 0.5) / (W / 2), (y - H / 2 + 0.5) / (H / 2))
            wob = 1.0 + 0.04 * math.sin(math.atan2(y - H / 2, x - W / 2) * 5)
            d /= wob
            if d <= 0.96:
                im.putpixel((x, y), rgb(SHADE, 255) if d < 0.8 or rng.random() < 0.5 else rgb(CER_D, 255))
            elif d <= 1.0:
                im.putpixel((x, y), rgb(SIL_D, 255))
    im.save(OUT / "tiles/host_cloud_shadow.png")


def ring(w: int, h: int, cracked: bool) -> Image.Image:
    """The halo ring as an ellipse of cerulean-light with a silver rim; the cracked one has two gaps."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            d = math.hypot((x - w / 2 + 0.5) / (w / 2), (y - h / 2 + 0.5) / (h / 2))
            if 0.72 <= d <= 1.0:
                ang = math.atan2(y - h / 2, x - w / 2)
                if cracked and (abs(ang - 0.8) < 0.22 or abs(ang + 2.3) < 0.22):
                    continue
                im.putpixel((x, y), rgb(CER_L if d < 0.9 else SIL))
    return im


def scales() -> None:
    """24 x 20 scales of Judgment: a silver beam and pillar, two dawn-rose pans on chains, 1 px ink outline."""
    im = Image.new("RGBA", (24, 20), (0, 0, 0, 0))
    def px(x, y, c): im.putpixel((x, y), rgb(c))
    for x in range(2, 22): px(x, 4, SIL)
    for y in range(2, 17): px(11, y, SIL); px(12, y, SIL_D)
    for x in range(7, 17): px(x, 18, SIL_D)
    px(11, 1, STAR); px(12, 1, STAR)
    for (cx) in (3, 20):
        for y in range(5, 11): px(cx, y, SIL_D)
        for x in range(cx - 3, cx + 4): px(x, 11, ROSE)
        for x in range(cx - 2, cx + 3): px(x, 12, ROSE_D)
    # outline
    a = im.copy()
    for y in range(20):
        for x in range(24):
            if a.getpixel((x, y))[3] == 0 and any(0 <= x + dx < 24 and 0 <= y + dy < 20 and a.getpixel((x + dx, y + dy))[3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                im.putpixel((x, y), rgb(INK))
    im.save(OUT / "markers/host_scales.png")


def pillar() -> None:
    """40 x 120 pillar of light, drawn additively: white core, faint cerulean edge, stepped (no gradient) in 6 bands."""
    im = Image.new("RGBA", (40, 120), (0, 0, 0, 0))
    for y in range(120):
        for x in range(40):
            d = abs(x - 19.5) / 20
            if d < 0.45: c = rgb(STAR, 235)
            elif d < 0.7: c = rgb(SIL, 170)
            elif d < 0.9: c = rgb(CER_L, 110)
            elif d < 1.0: c = rgb(CER, 70)
            else: continue
            if y > 100: c = c[:3] + (int(c[3] * (120 - y) / 20),)
            im.putpixel((x, y), c)
    im.save(OUT / "markers/host_pillar.png")


def shaft() -> None:
    """32 x 128 shaft of Hallowed Light tiling along its length (no vertical variation): soft starlight bands, transparent edges."""
    im = Image.new("RGBA", (32, 128), (0, 0, 0, 0))
    for x in range(32):
        d = abs(x - 15.5) / 16
        a = 150 if d < 0.4 else 95 if d < 0.65 else 45 if d < 0.85 else 0
        for y in range(128):
            if a: im.putpixel((x, y), rgb(STAR if d < 0.65 else CER_L, a))
    im.save(OUT / "fx/host_shaft.png")
    line = Image.new("RGBA", (4, 128), (0, 0, 0, 0))
    for y in range(128):
        if (y // 8) % 2 == 0:
            for x in (1, 2): line.putpixel((x, y), rgb(CER, 230))
            for x in (0, 3): line.putpixel((x, y), rgb(CER_L, 110))
    line.save(OUT / "fx/host_shaft_line.png")


def trumpet_ring() -> None:
    """Strip of 8 frames of 48 x 24: a silver ring expanding from the centre and fading (frame 0 small and bright, frame 7 wide and faint)."""
    strip = Image.new("RGBA", (8 * 48, 24), (0, 0, 0, 0))
    for f in range(8):
        r = 0.2 + 0.8 * f / 7
        a = int(255 * (1 - 0.7 * f / 7))
        for y in range(24):
            for x in range(48):
                d = math.hypot((x - 23.5) / 24, (y - 11.5) / 12)
                if r - 0.14 <= d <= r:
                    strip.putpixel((f * 48 + x, y), rgb(STAR if d > r - 0.07 else SIL, a))
    strip.save(OUT / "fx/host_trumpet_ring.png")


if __name__ == "__main__":
    (OUT / "markers").mkdir(exist_ok=True)
    (OUT / "fx").mkdir(exist_ok=True)
    stair()
    cloud_shadow()
    ring(16, 6, False).save(OUT / "markers/host_halo.png")
    ring(16, 6, True).save(OUT / "markers/host_halo_cracked.png")
    scales()
    pillar()
    shaft()
    trumpet_ring()
