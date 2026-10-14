"""make_menu_art.py: builds every sprite of the main-menu diorama (assets/sprites/menu/).

Usage (from the repo root):
    python3 art_source/menu/make_menu_art.py            # rebuild every menu sprite
    python3 art_source/menu/make_menu_art.py --sheet OUT.png   # also write a x3 review sheet

The menu diorama (scripts/ui/menu_backdrop.gd, numbers in scripts/data/menu_backdrop_data.gd,
docs/art/ART_BIBLE.md "Menu diorama") is built from art the game already has (gravestones, dead
trees, crypt walls, statues, the Graveyard floor tile, the walk strips) plus the pieces below.
Everything here is deterministic (fixed seeds), so re-running the script rewrites the same PNGs.

Two kinds of output:
- Converted AI art (art_source/menu/sources/*.png, generated with tools/gen_image.py, prompts beside
  them): the distant Covenant cathedral and the mausoleum. Both sources were drawn as chunky pixel
  art on a regular block grid, so they are converted at their NATIVE grid (one art px per source
  block, the colour of each block = the majority colour of its central sample) and every pixel is
  snapped (OKLab nearest) to a short list of locked-palette colours.
- Procedural pixel art (drawn here in palette colours): the moon, its halo, the stars, clouds, the
  hill silhouettes, the ground lip, fog banks, the iron fence, the soul wisp and both flame strips,
  the glow disc, the grave lantern, the candle cluster and the bat.

Tintable masks: the halo, stars, clouds, hills, fog and glow are stored WHITE (or two light greys)
with stepped alpha, so the game tints them per mood (MenuBackdropData.MOODS). Stepped alpha (2-4
levels, hard edges on the art grid) keeps them pixel art rather than smooth gradients.
"""

import argparse
import math
import os
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
SRC = ROOT / "art_source" / "menu" / "sources"  # AI sources and their prompts.
OUT = ROOT / "assets" / "sprites" / "menu"  # Output folder of the menu sprites.

# Locked palette colours used here (tools/palette.json names -> hex).
P = {
    "ink_cold": "#0F141C", "grey_dark": "#3B4352", "grey": "#6B7A94", "grey_light": "#A7B3C6",
    "ink_warm": "#1C110B", "bone_shade": "#7F785F", "bone_mid": "#B4AA8A", "bone": "#E8E1C8",
    "ink_green": "#081814", "soul_dark": "#1C6B58", "soul": "#3DCC94", "soul_glow": "#A8FFD2",
    "moss_dark": "#3B5529", "moss": "#76984A", "brown": "#4F3320", "brown_light": "#8C6040",
    "gold": "#E0A92E", "gold_light": "#FFDC66", "holy_white": "#FFFAE8",
    "ink_red": "#26070C", "crimson_dark": "#7A0E1B", "crimson": "#C71A29", "flame": "#FF8C26",
    "floor_soil": "#161A1C", "floor_slate": "#26272A", "floor_grass": "#1A2218", "floor_moss": "#26301F",
}


def rgb(name: str) -> tuple:
    """(r, g, b) of palette colour `name`."""
    h = P[name].lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgba(name: str, a: int = 255) -> tuple:
    """(r, g, b, a) of palette colour `name` with alpha `a` (0-255)."""
    return rgb(name) + (a,)


def oklab(c: np.ndarray) -> np.ndarray:
    """OKLab of sRGB colours `c` (..., 3) in 0-255."""
    c = c / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    l = 0.4122214708 * c[..., 0] + 0.5363325363 * c[..., 1] + 0.0514459929 * c[..., 2]
    m = 0.2119034982 * c[..., 0] + 0.6806995451 * c[..., 1] + 0.1073969566 * c[..., 2]
    s = 0.0883024619 * c[..., 0] + 0.2817188376 * c[..., 1] + 0.6299787005 * c[..., 2]
    l, m, s = np.cbrt(l), np.cbrt(m), np.cbrt(s)
    return np.stack([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s], -1)


def convert_native(src: Path, block: float, colours: list, alpha_cut: int = 128,
                   lift: float = 0.0) -> Image.Image:
    """Converts chunky AI pixel art `src` at its native grid (`block` source px per art px).

    Each art px samples the central half of its source block; it is opaque when most samples are
    (alpha >= alpha_cut), and its colour is the median of the opaque samples, snapped (OKLab nearest)
    to `colours` (palette names). `lift` adds to the OKLab lightness before snapping (the AI drew the
    silhouettes a touch dark)."""
    im = np.asarray(Image.open(src).convert("RGBA")).astype(float)
    ys, xs = np.nonzero(im[..., 3] >= alpha_cut)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    w = int(round((x1 - x0) / block))
    h = int(round((y1 - y0) / block))
    bx = (x1 - x0) / w
    by = (y1 - y0) / h
    pal = np.array([rgb(n) for n in colours], float)
    pal_lab = oklab(pal)
    out = np.zeros((h, w, 4), np.uint8)
    for j in range(h):
        for i in range(w):
            cx0 = int(x0 + (i + 0.25) * bx)
            cx1 = max(cx0 + 1, int(x0 + (i + 0.75) * bx))
            cy0 = int(y0 + (j + 0.25) * by)
            cy1 = max(cy0 + 1, int(y0 + (j + 0.75) * by))
            cell = im[cy0:cy1, cx0:cx1].reshape(-1, 4)
            opaque = cell[cell[:, 3] >= alpha_cut]
            if len(opaque) * 2 < len(cell):
                continue
            c = np.median(opaque[:, :3], 0)
            lab = oklab(c)
            lab[0] += lift
            k = int(np.argmin(((pal_lab - lab) ** 2).sum(-1)))
            out[j, i, :3] = pal[k]
            out[j, i, 3] = 255
    return Image.fromarray(out, "RGBA")


def clean_singles(img: Image.Image) -> Image.Image:
    """Removes lone opaque pixels (no opaque 4-neighbour): AI colour noise at the edges."""
    a = np.asarray(img).copy()
    op = a[..., 3] > 0
    pad = np.pad(op, 1)
    nb = pad[:-2, 1:-1].astype(int) + pad[2:, 1:-1] + pad[1:-1, :-2] + pad[1:-1, 2:]
    a[op & (nb == 0)] = 0
    return Image.fromarray(a, "RGBA")


def smooth_noise(w: int, h: int, scale: float, seed: int, wrap_x: bool = False) -> np.ndarray:
    """Smooth value noise in 0..1 (w x h), features about `scale` px; tileable left-right with wrap_x."""
    rng = np.random.default_rng(seed)
    pad = int(scale * 3)
    field = rng.random((h + 2 * pad, w + 2 * pad))
    if wrap_x:
        field[:, :pad] = field[:, w:w + pad]
        field[:, w + pad:] = field[:, pad:2 * pad]
    img = Image.fromarray((field * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(scale))
    n = np.asarray(img).astype(float)[pad:pad + h, pad:pad + w]
    n = (n - n.min()) / max(1e-6, n.max() - n.min())
    return n


def periodic_profile(w: int, terms: list, seed: int) -> np.ndarray:
    """A 1D height profile (px) over w columns that tiles: a sum of sines whose periods divide w.
    `terms` = [(cycles over w, amplitude px), ...]."""
    rng = random.Random(seed)
    x = np.arange(w)
    y = np.zeros(w)
    for cycles, amp in terms:
        y += amp * np.sin(2 * math.pi * cycles * x / w + rng.uniform(0, 2 * math.pi))
    return y


# ---------------------------------------------------------------- the pieces


def make_moon() -> Image.Image:
    """The full moon: a 104 px disc in bone shades, maria, a few craters, the lower-right limb darker."""
    d = 104
    r = d / 2 - 0.5
    img = np.zeros((d, d, 4), np.uint8)
    yy, xx = np.mgrid[0:d, 0:d]
    dx, dy = xx - (d - 1) / 2, yy - (d - 1) / 2
    dist = np.sqrt(dx ** 2 + dy ** 2)
    disc = dist <= r
    n = smooth_noise(d, d, 7.0, 11)
    n2 = smooth_noise(d, d, 3.0, 12)
    shade = np.full((d, d), 3)  # 3 bone, 2 bone_mid, 1 bone_shade, 4 holy_white
    maria = (n * 0.8 + n2 * 0.2) > 0.6
    shade[maria] = 2
    # Craters: (x, y, radius) from the centre.
    for cx, cy, cr in [(-22, -24, 6), (18, 22, 8), (-30, 16, 4), (26, -10, 5), (2, 34, 4), (-8, 2, 3), (34, 12, 3)]:
        cd = np.sqrt((dx - cx) ** 2 + (dy - cy) ** 2)
        floor = cd <= cr
        shade[floor] = 2
        # Shadow rim on the upper-left inside, lit rim on the lower-right (light from the upper-left).
        rim = (cd <= cr) & (cd > cr - 1.6)
        ang = np.arctan2(dy - cy, dx - cx)
        shade[rim & (np.cos(ang + math.pi * 0.75) > 0.3)] = 1
        shade[(cd > cr) & (cd <= cr + 1.2) & (np.cos(ang - math.pi * 0.25) > 0.5)] = 4
    # Limb: the lower-right edge one shade darker (roundness), the upper-left edge a bright rim.
    limb_ang = np.arctan2(dy, dx)
    edge = disc & (dist > r - 3.2)
    lower_right = np.cos(limb_ang - math.pi * 0.25) > 0.15
    shade[edge & lower_right & (shade == 3)] = 2
    shade[edge & lower_right & (shade == 2) & (dist > r - 1.5)] = 1
    shade[disc & (dist > r - 1.6) & (np.cos(limb_ang + math.pi * 0.75) > 0.4) & (shade >= 3)] = 4
    cols = {1: rgba("bone_shade"), 2: rgba("bone_mid"), 3: rgba("bone"), 4: rgba("holy_white")}
    for k, c in cols.items():
        img[disc & (shade == k)] = c
    out = Image.fromarray(img, "RGBA")
    return out


def make_halo() -> Image.Image:
    """The moon's halo: stepped concentric discs, white, alpha levels 255 / 150 / 85 / 40 (tinted in game)."""
    d = 320
    yy, xx = np.mgrid[0:d, 0:d]
    dist = np.sqrt((xx - (d - 1) / 2) ** 2 + (yy - (d - 1) / 2) ** 2)
    a = np.zeros((d, d), np.uint8)
    for radius, alpha in [(158, 40), (122, 85), (90, 150), (66, 255)]:
        a[dist <= radius] = alpha
    img = np.zeros((d, d, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = a
    return Image.fromarray(img, "RGBA")


def make_stars() -> Image.Image:
    """Star strip: 3 frames of 5x5 (a dot, a small plus, a bright plus with a white core), white."""
    img = np.zeros((5, 15, 4), np.uint8)
    img[..., :3] = 255
    # frame 0: a 1 px dot (dimmer), frame 1: a 3 px plus, frame 2: a 5 px plus.
    img[2, 2, 3] = 200
    for x, y, a in [(7, 2, 255), (6, 2, 140), (8, 2, 140), (7, 1, 140), (7, 3, 140)]:
        img[y, x, 3] = a
    for x, y, a in [(12, 2, 255), (11, 2, 190), (13, 2, 190), (12, 1, 190), (12, 3, 190),
                    (10, 2, 90), (14, 2, 90), (12, 0, 90), (12, 4, 90)]:
        img[y, x, 3] = a
    return Image.fromarray(img, "RGBA")


def make_cloud(w: int, h: int, seed: int) -> Image.Image:
    """A long thin cloud band: lit top (white) over a grey body, stepped alpha, tinted in game."""
    n = smooth_noise(w, h, 4.0, seed)
    yy, xx = np.mgrid[0:h, 0:w]
    # Elongated envelope: a lens shape thick in the middle, thin at both ends.
    t = xx / (w - 1)
    thick = np.sin(math.pi * t) ** 0.7 * (h * 0.5)
    prof = periodic_profile(w, [(3, 2.0), (7, 1.2), (13, 0.7)], seed)
    mid = h * 0.55 + prof * 0.4
    top = mid - thick * (0.75 + 0.5 * n)
    bottom = mid + thick * 0.45
    inside = (yy >= top) & (yy <= bottom)
    img = np.zeros((h, w, 4), np.uint8)
    body = inside
    img[body] = (180, 180, 180, 190)
    # The thin fringe (outer 1-2 px) lighter alpha, the lit top 2 px white.
    fringe = inside & ((yy < top + 1.5) | (yy > bottom - 1.2) | (t < 0.06) | (t > 0.94))
    img[fringe & (yy > mid)] = (180, 180, 180, 110)
    lit = inside & (yy < top + 2.5) & (yy >= top + 0.0)
    img[lit] = (255, 255, 255, 220)
    return Image.fromarray(img, "RGBA")


def make_hills(w: int, h: int, seed: int, base: float, terms: list, props: list) -> Image.Image:
    """A tileable hill silhouette strip (white mask), ridge profile from periodic sines, with small
    props on the ridge: ('cross', x), ('tree', x), ('cypress', x)."""
    prof = base + periodic_profile(w, terms, seed)
    img = np.zeros((h, w, 4), np.uint8)
    img[..., :3] = 255
    ridge = np.clip(np.round(prof).astype(int), 2, h - 1)
    for x in range(w):
        img[ridge[x]:, x, 3] = 255

    def put(x, y):
        x %= w
        if 0 <= y < h:
            img[y, x, 3] = 255

    for kind, x in props:
        g = ridge[x % w]
        if kind == "cross":
            for y in range(g - 9, g):
                put(x, y)
                put(x + 1, y)
            for dx in range(-2, 4):
                put(x + dx, g - 7)
                put(x + dx, g - 6)
        elif kind == "tree":
            for y in range(g - 16, g):
                put(x, y)
                put(x + 1, y)
            for i in range(6):
                put(x - 1 - i, g - 9 - i)
                put(x + 2 + i, g - 11 - i // 2 * 2 + (i % 2))
            for i in range(4):
                put(x - 3 - i, g - 13 - i)
                put(x + 5 + i, g - 15 - i)
        elif kind == "cypress":
            top = g - 26
            for y in range(top, g):
                half = int(round(3.2 * math.sin(math.pi * min(1.0, (y - top + 2) / 30.0) ** 0.8)))
                for dx in range(-half, half + 2):
                    put(x + dx, y)
        elif kind == "stone":
            for y in range(g - 6, g):
                for dx in range(0, 5):
                    if not (y == g - 6 and dx in (0, 4)):
                        put(x + dx, y)
    return Image.fromarray(img, "RGBA")


def make_ground_lip(w: int = 128, h: int = 18) -> Image.Image:
    """The near ground's top edge: soil with a ragged top and dead grass tufts, tileable left-right.
    The bottom rows break up into transparency so the Graveyard tile below shows through."""
    rng = random.Random(7)
    img = np.zeros((h, w, 4), np.uint8)
    prof = 8 + periodic_profile(w, [(2, 1.4), (5, 0.9), (11, 0.6)], 3)
    top = np.round(prof).astype(int)
    noise = smooth_noise(w, h, 1.5, 5, wrap_x=True)
    for x in range(w):
        for y in range(top[x], h):
            depth = y - top[x]
            # Fade into the tile: the last rows are kept only where the noise is high.
            if y >= h - 5 and noise[y, x] < (y - (h - 6)) / 6.0:
                continue
            img[y, x] = rgba("floor_soil")
        img[top[x], x] = rgba("floor_moss")
    # Dead grass tufts: 2-3 blades rising from the edge, moss_dark with a moss tip.
    for _ in range(26):
        x = rng.randrange(w)
        blades = rng.choice([2, 3, 3, 4])
        for b in range(blades):
            bx = (x + b * 2 - blades) % w
            hgt = rng.randint(3, 7)
            lean = rng.choice([-1, 0, 0, 1])
            for k in range(hgt):
                yy = top[bx] - 1 - k
                xx = (bx + (lean if k >= hgt // 2 else 0)) % w
                if yy >= 0:
                    img[yy, xx] = rgba("moss" if k == hgt - 1 and rng.random() < 0.5 else "moss_dark")
    return Image.fromarray(img, "RGBA")


def make_fog(w: int, h: int, seed: int) -> Image.Image:
    """A tileable fog bank (white, stepped alpha 70 / 140 / 220, densest at the bottom)."""
    n = smooth_noise(w, h, 5.0, seed, wrap_x=True)
    prof = periodic_profile(w, [(2, h * 0.16), (5, h * 0.09), (9, h * 0.05)], seed)
    yy, xx = np.mgrid[0:h, 0:w]
    level = (yy - (h * 0.35 + prof[None, :])) / (h * 0.65) + (n - 0.5) * 0.5
    a = np.zeros((h, w), np.uint8)
    a[level > 0.0] = 70
    a[level > 0.3] = 140
    a[level > 0.62] = 220
    # Thin the very bottom slightly so stacked banks do not band.
    img = np.zeros((h, w, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = a
    return Image.fromarray(img, "RGBA")


def make_fence(w: int = 64, h: int = 30) -> Image.Image:
    """A wrought-iron graveyard fence section, tileable left-right: 2 px bars with spear tips, two
    rails, one bent bar; ink outline, grey_dark lit left column."""
    img = np.zeros((h, w, 4), np.uint8)
    ink, lit = rgba("ink_cold"), rgba("grey_dark")
    for rail_y in (8, h - 6):
        img[rail_y:rail_y + 2, :] = ink
        img[rail_y, :] = lit
    for i, x in enumerate(range(2, w, 8)):
        bent = i == 5
        tip = 2 if i % 2 == 0 else 4
        for y in range(tip + 3, h):
            xx = x + (1 if bent and y < 12 else 0)
            img[y, xx] = lit
            img[y, xx + 1] = ink
        tx = x + (1 if bent else 0)
        # Spear tip: 3 rows widening then the point.
        img[tip, tx] = lit
        img[tip, tx + 1] = ink
        img[tip + 1, tx - 1:tx + 3] = ink
        img[tip + 1, tx] = lit
        img[tip + 2, tx - 1:tx + 3] = ink
    return Image.fromarray(img, "RGBA")


def make_wisp() -> Image.Image:
    """Soul wisp strip: 4 frames of 9x14, a teal flame teardrop whose tip sways; soul_glow core."""
    fw, fh = 9, 14
    img = np.zeros((fh, fw * 4, 4), np.uint8)
    for f in range(4):
        sway = [0, 1, 0, -1][f]
        for y in range(fh):
            t = y / (fh - 1)  # 0 at the tip, 1 at the bottom
            half = 3.6 * math.sin(math.pi * min(1.0, t * 0.92 + 0.08)) ** 0.9 * (0.35 + 0.65 * t)
            cx = 4 + sway * (1 - t) * 1.6
            for x in range(fw):
                d = abs(x - cx)
                if d <= half + 0.15 and y >= 1:
                    col = "soul_dark"
                    if d <= half - 1.0 and t > 0.25:
                        col = "soul"
                    if d <= half - 2.2 and t > 0.5:
                        col = "soul_glow"
                    img[y, f * fw + x] = rgba(col)
    return Image.fromarray(img, "RGBA")


def make_flame(fire: bool) -> Image.Image:
    """Flame strip: 3 frames of 5x8 (lantern / torch); fire = warm (flame, gold_light, crimson),
    else soul fire (soul_dark, soul, soul_glow)."""
    fw, fh = 5, 8
    outer, mid, core = (("crimson", "flame", "gold_light") if fire else ("soul_dark", "soul", "soul_glow"))
    shapes = [
        ["..o..", "..o..", ".om..", ".omo.", "omcmo", "omcmo", ".omo.", "..o.."],
        ["...o.", "..o..", "..mo.", ".omo.", ".omco", "omcmo", ".omo.", "..o.."],
        [".o...", "..o..", ".om..", ".omo.", "ocmo.", "omcmo", ".omo.", "..o.."],
    ]
    img = np.zeros((fh, fw * 3, 4), np.uint8)
    for f, rows in enumerate(shapes):
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    img[y, f * fw + x] = rgba({"o": outer, "m": mid, "c": core}[ch])
    return Image.fromarray(img, "RGBA")


def make_candle_flame() -> Image.Image:
    """Candle flame strip: 3 frames of 3x5, warm."""
    shapes = [[".g.", ".g.", "gwg", "fgf", ".f."], ["..g", ".g.", "gwg", "fgf", ".f."], ["g..", ".g.", "gwg", "fgf", ".f."]]
    img = np.zeros((5, 9, 4), np.uint8)
    for f, rows in enumerate(shapes):
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    img[y, f * 3 + x] = rgba({"g": "gold_light", "w": "holy_white", "f": "flame"}[ch])
    return Image.fromarray(img, "RGBA")


def make_glow() -> Image.Image:
    """Glow disc (white, stepped alpha 255 / 150 / 80 / 35 at radii 5 / 10 / 16 / 23), tinted in game."""
    d = 48
    yy, xx = np.mgrid[0:d, 0:d]
    dist = np.sqrt((xx - 23.5) ** 2 + (yy - 23.5) ** 2)
    a = np.zeros((d, d), np.uint8)
    for radius, alpha in [(23, 35), (16, 80), (10, 150), (5, 255)]:
        a[dist <= radius] = alpha
    img = np.zeros((d, d, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = a
    return Image.fromarray(img, "RGBA")


def make_lantern() -> Image.Image:
    """Grave lantern on an iron post (13x46): base, post, a caged lantern (glass lit soul_dark from
    inside, the flame is drawn over it by the game), a pointed cap with a ring. Ink outline, grey
    moonlit left edges."""
    rows = [
        ".....ooo.....",
        ".....o.o.....",
        ".....ooo.....",
        "......o......",
        ".....olo.....",
        "....olllo....",
        "...ollllo....",
        "..oolllloo...",
        "..oooooooo...",
        "..olggggglo..",
        "..olgggggo...",
        "..olgggggo...",
        "..olgggggo...",
        "..olgggggo...",
        "..olgggggo...",
        "..olgggggo...",
        "..oooooooo...",
        "...olllloo...",
        "....oooo.....",
        ".....olo.....",
    ]
    rows = [r.ljust(13, ".") for r in rows]
    for _ in range(22):
        rows.append(".....olo.....")
    rows += ["....ollo.....", "...olllo.....", "..olllllo....", "..ooooooo...."]
    h = len(rows)
    img = np.zeros((h, 13, 4), np.uint8)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row[:13]):
            if ch != ".":
                img[y, x] = rgba({"o": "ink_cold", "l": "grey", "g": "soul_dark"}[ch])
    return Image.fromarray(img, "RGBA")


def make_candles() -> Image.Image:
    """Three melted candles at a grave's foot (15x11): bone wax, bone_mid shade, ink wicks. The
    flames (candle_flame) are drawn above the wicks by the game."""
    rows = [
        "...k...........",
        "..obo......k...",
        "..obo.....obo..",
        "..obo..k..obo..",
        "..obmoobo.obmo.",
        "..obmoobo.obmo.",
        "..obmoobmoobmo.",
        ".obbmoobmoobmo.",
        "obbbmmobmobbmmo",
        "ommmmmmmmmmmmmo",
        "ooooooooooooooo",
    ]
    img = np.zeros((len(rows), 15, 4), np.uint8)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img[y, x] = rgba({"o": "ink_warm", "b": "bone", "m": "bone_mid", "k": "ink_warm"}[ch])
    return Image.fromarray(img, "RGBA")


def make_bat() -> Image.Image:
    """Bat strip: 2 frames of 13x7 (wings up, wings down), an ink silhouette with a grey_dark rim,
    flying right (the game mirrors it)."""
    frames = [
        ["o...........o",
         "oo.........oo",
         ".ooo.olo.ooo.",
         "..ooooooooo..",
         "....ooooo....",
         ".....o.o.....",
         "............."],
        [".............",
         ".............",
         ".....olo.....",
         "..ooooooooo..",
         ".ooo.ooo.ooo.",
         "oo...o.o...oo",
         "o...........o"],
    ]
    img = np.zeros((7, 26, 4), np.uint8)
    for f, rows in enumerate(frames):
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    img[y, f * 13 + x] = rgba("grey_dark" if ch == "l" else "ink_cold")
    return Image.fromarray(img, "RGBA")


def build_all() -> dict:
    """Builds every menu sprite; returns {key: Image}."""
    out = {}
    out["moon"] = make_moon()
    out["moon_halo"] = make_halo()
    out["stars"] = make_stars()
    out["cloud_1"] = make_cloud(220, 22, 21)
    out["cloud_2"] = make_cloud(300, 28, 22)
    out["cloud_3"] = make_cloud(150, 16, 23)
    out["hills_far"] = make_hills(320, 70, 31, 38.0, [(1, 9.0), (3, 5.0), (7, 2.0)],
                                  [("cypress", 40), ("cypress", 47), ("tree", 150), ("cross", 228), ("cypress", 270)])
    out["hills_mid"] = make_hills(384, 60, 41, 32.0, [(1, 6.0), (2, 4.0), (5, 2.0), (11, 1.0)],
                                  [("tree", 60), ("cross", 120), ("stone", 135), ("cross", 152),
                                   ("stone", 210), ("tree", 300), ("cross", 340), ("stone", 356)])
    out["ground_lip"] = make_ground_lip()
    out["fog_1"] = make_fog(512, 44, 51)
    out["fog_2"] = make_fog(384, 34, 52)
    out["fence"] = make_fence()
    out["wisp"] = make_wisp()
    out["flame_soul"] = make_flame(False)
    out["flame_fire"] = make_flame(True)
    out["candle_flame"] = make_candle_flame()
    out["glow"] = make_glow()
    out["lantern"] = make_lantern()
    out["candles"] = make_candles()
    out["bat"] = make_bat()
    # Converted AI art (native grid, palette snapped).
    out["cathedral"] = clean_singles(convert_native(
        SRC / "cathedral.png", 6.4,
        ["ink_cold", "floor_soil", "floor_slate", "grey_dark", "gold", "gold_light", "crimson_dark", "crimson", "ink_red"]))
    out["mausoleum"] = clean_singles(convert_native(
        SRC / "mausoleum.png", 13.5,
        ["ink_cold", "grey_dark", "grey", "grey_light", "moss_dark", "moss", "ink_warm", "brown",
         "soul_dark", "soul", "soul_glow"]))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sheet", help="also write a x3 review sheet of every sprite to this PNG")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    imgs = build_all()
    for key, im in imgs.items():
        im.save(OUT / f"{key}.png")
        print(f"menu/{key}: {im.width}x{im.height}")
    if args.sheet:
        pad = 6
        rows, row, rw = [], [], 0
        for im in imgs.values():
            if rw + im.width > 700 and row:
                rows.append(row)
                row, rw = [], 0
            row.append(im)
            rw += im.width + pad
        rows.append(row)
        W = max(sum(i.width + pad for i in r) for r in rows) + pad
        H = sum(max(i.height for i in r) + pad for r in rows) + pad
        sheet = Image.new("RGBA", (W, H), (34, 30, 52, 255))
        y = pad
        for r in rows:
            x = pad
            for im in r:
                sheet.alpha_composite(im, (x, y))
                x += im.width + pad
            y += max(i.height for i in r) + pad
        sheet.resize((W * 3, H * 3), Image.NEAREST).save(args.sheet)


if __name__ == "__main__":
    main()
