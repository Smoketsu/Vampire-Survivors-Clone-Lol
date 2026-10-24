#!/usr/bin/env python3
"""covenant_aoe_art.py: the procedural pixel art of Act I's enemy-side ground effects.

GDD 15.0 "Act I enemy AoE art": the Covenant's area effects (the shared boss / elite telegraphs,
holy zones, sanctified and cleansed chambers, suppression seals, Seraphine's hazards, the
Cathedral Guardian's beam, the High Confessor's pillar and shield, Marshal Vael's cleave, the boss
death flash, Alaric's Wrath halo, the Graveyard fog) used to be flat code shapes, because an old
art rule kept "rings, telegraphs, zones and glows" in code. That rule is retired for these
effects: this tool draws every piece ON THE ART GRID (1 art px = 1 layout px), in the locked
palette (tools/palette.json), deterministically (no randomness: a fixed integer hash), so a rerun
rebuilds the same files bit for bit.

The pieces are made so they stay crisp at ANY gameplay size (scripts/fx/covenant_fx.gd draws
them, scripts/data/covenant_fx_data.gd holds the keys and numbers):
  * TILES repeated along a shape at 1:1 (a telegraph's edge band around a circle, along a lane
    and a cone; a beam body; a hatch tile that fills any circle, cone or lane row by row);
  * BAKED DISCS at the exact radii the game uses (holy zones r 62 / 85 / 105, the 220 px
    chamber, the 160 / 220 px seals, the altar sigil, the 62 px safe circle), drawn at scale
    radius / baked radius (1.0 for the shipped radii);
  * small STILLS (glints, runes, chevrons, a fist, a shield bubble, a light column, smoke banks,
    fog decals);
  * effect STRIPS (assets/sprites/effects/, AnimData): the boss death flash, the cleave / sweep
    crescents, the structure break (a grey mask the game tints) and the flame tongues of the
    collapsing arena.
Ground effects may use a few stepped alpha levels (a translucent zone is the point of them); every
other piece is fully opaque or fully transparent.

Usage (from the repo root):
    python3 tools/covenant_aoe_art.py            # writes every PNG under assets/sprites/
    python3 tools/covenant_aoe_art.py --review docs/art/act1_enemy_review
                                                 # + review images (1x, 4x nearest, GIFs)
    python3 tools/covenant_aoe_art.py --only telegraphs/edge,holy/zone_85
"""
import argparse
import json
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Repo root.
SPRITES = os.path.join(ROOT, "assets", "sprites")  # Where the game loads sprites from.


def _palette() -> dict:
    """name -> (r, g, b) of the locked palette (tools/palette.json)."""
    with open(os.path.join(ROOT, "tools", "palette.json")) as f:
        data = json.load(f)
    out = {}
    for c in data["colors"]:
        h = c["hex"].lstrip("#")
        out[c["name"]] = (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return out


P = _palette()  # The locked palette by name.

# --- Colours used here (palette names) ---------------------------------------------------------
INK_RED = P["ink_red"]  # Crimson's outline ink.
CRIM_DK = P["crimson_dark"]  # Dark crimson.
CRIMSON = P["crimson"]  # Covenant crimson.
INK_WARM = P["ink_warm"]  # Warm outline ink (gold / bone / steel / brown).
BROWN_L = P["brown_light"]  # Gold's shade.
GOLD = P["gold"]  # Covenant gold.
GOLD_L = P["gold_light"]  # Light gold.
HOLY = P["holy_white"]  # Holy white glow.
BONE_SH = P["bone_shade"]  # Bone shadow.
BONE_MID = P["bone_mid"]  # Bone mid.
BONE = P["bone"]  # Ivory.
FLAME = P["flame"]  # Fire orange.
STEEL_DK = P["steel_dark"]  # Warm steel dark.
STEEL = P["steel"]  # Warm steel.
STEEL_L = P["steel_light"]  # Warm steel light.
ICE = P["ice"]  # Pale icy cyan.
ICE_L = P["ice_light"]  # Icy white.
ARC_DK = P["arcane_dark"]  # Deep cold blue.
ARC = P["arcane"]  # Cold blue.
ARC_L = P["arcane_light"]  # Light cold blue.
INK_COLD = P["ink_cold"]  # Cold ink.
INK_VIO = P["ink_violet"]  # Violet ink (the player's side: the cleansed stain is his work).
VIO_DEEP = P["violet_deep"]  # Deep violet.
VIO = P["violet"]  # Violet.
SOUL_DK = P["soul_dark"]  # Soul fire dark (the rot cracks).
SOUL = P["soul"]  # Soul fire.
MOSS_DK = P["moss_dark"]  # Moss dark.


def hsh(*v: int) -> int:
    """A fixed integer hash of `v` (0..2^32): the tool's only source of variation."""
    h = 2166136261
    for x in v:
        h = ((h ^ (int(x) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
        h ^= h >> 13
        h = (h * 1274126177) & 0xFFFFFFFF
    return h


def hf(*v: int) -> float:
    """hsh() as a float in 0..1."""
    return hsh(*v) / 4294967295.0


def vnoise(x: float, y: float, seed: int) -> float:
    """Smooth value noise in 0..1 on a unit lattice (bilinear, smoothstep)."""
    x0, y0 = math.floor(x), math.floor(y)
    fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = hf(x0, y0, seed)
    b = hf(x0 + 1, y0, seed)
    c = hf(x0, y0 + 1, seed)
    d = hf(x0 + 1, y0 + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def anoise(t: float, n: int, seed: int) -> float:
    """Smooth periodic noise in 0..1 along an angle `t` (rad), `n` lattice steps a turn."""
    u = (t / (2 * math.pi)) % 1.0 * n
    i = int(math.floor(u)) % n
    f = u - math.floor(u)
    f = f * f * (3 - 2 * f)
    return hf(i, seed) * (1 - f) + hf((i + 1) % n, seed) * f


class Canvas:
    """An RGBA pixel canvas with the few drawing operations the effects need."""

    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.im.load()

    def put(self, x: int, y: int, col, a: int = 255) -> None:
        """Sets pixel (x, y) to palette colour `col` with alpha `a` (ignored off the canvas)."""
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = (col[0], col[1], col[2], a)

    def get_a(self, x: int, y: int) -> int:
        """Alpha of pixel (x, y) (0 off the canvas)."""
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[x, y][3]
        return 0

    def rect(self, x0: int, y0: int, w: int, h: int, col, a: int = 255) -> None:
        """Fills a w x h rectangle at (x0, y0)."""
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                self.put(x, y, col, a)

    def thick_line(self, x0: float, y0: float, x1: float, y1: float, wid: float, col, a: int = 255) -> None:
        """A line `wid` px thick from (x0, y0) to (x1, y1) (pixels whose centre is within wid / 2)."""
        dx, dy = x1 - x0, y1 - y0
        ll = dx * dx + dy * dy
        for y in range(int(min(y0, y1) - wid - 1), int(max(y0, y1) + wid + 2)):
            for x in range(int(min(x0, x1) - wid - 1), int(max(x0, x1) + wid + 2)):
                cx, cy = x + 0.5, y + 0.5
                t = 0.0 if ll == 0 else max(0.0, min(1.0, ((cx - x0) * dx + (cy - y0) * dy) / ll))
                ex, ey = x0 + dx * t - cx, y0 + dy * t - cy
                if ex * ex + ey * ey <= (wid * 0.5) ** 2:
                    self.put(x, y, col, a)

    def outline(self, col, inside_of=None) -> None:
        """Paints `col` on every transparent pixel next to an opaque one (4-neighbours)."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[x, y][3] != 0:
                    continue
                if any(self.get_a(x + dx, y + dy) > 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    add.append((x, y))
        for x, y in add:
            self.put(x, y, col)

    def save(self, key: str) -> str:
        """Writes the canvas to assets/sprites/<key>.png and returns the path."""
        path = os.path.join(SPRITES, key + ".png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.im.save(path)
        return path


def from_bitmap(rows: list, colours: dict) -> Canvas:
    """A canvas from text rows: each character is a key of `colours` ('.' = transparent)."""
    c = Canvas(len(rows[0]), len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                c.put(x, y, colours[ch])
    return c


def strip_of(frames: list) -> Canvas:
    """Joins equal-size canvases side by side into one strip."""
    w, h = frames[0].w, frames[0].h
    out = Canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        out.im.alpha_composite(f.im, (i * w, 0))
    out.px = out.im.load()
    return out


def disc_canvas(radius: int, pad: int = 3):
    """A square canvas for a disc of `radius` px and its centre (px): side 2 * (radius + pad)."""
    side = 2 * (radius + pad)
    return Canvas(side, side), side / 2.0


def polar(cv: Canvas, cx: float, cy: float, x: int, y: int):
    """(distance, angle) of pixel (x, y)'s centre from (cx, cy)."""
    dx, dy = x + 0.5 - cx, y + 0.5 - cy
    return math.hypot(dx, dy), math.atan2(dy, dx)


# =================================================================================================
# 1. The shared telegraph set (every boss / elite warning circle, lane and cone, in every act)
# =================================================================================================

def t_edge() -> Canvas:
    """telegraphs/edge: one 10 px piece of the warning band, row 0 OUTSIDE (toward the safe side):
    an ink rim, a 4 px gold band (light gold in its middle), a dark crimson inner row. Tiled at 1:1
    along any circle, lane side or cone edge; the hit edge runs through the band's middle."""
    return from_bitmap([
        "rrrrrrrrrr",
        "gggggggggg",
        "llllllllll",
        "hhhhhhhhhh",
        "gggggggggg",
        "dddddddddd",
    ], {"r": INK_RED, "l": GOLD_L, "g": GOLD, "h": HOLY, "d": CRIM_DK})


def t_edge_tooth() -> Canvas:
    """telegraphs/edge_tooth: the same band piece with a crimson tooth pointing INTO the danger
    (every other piece along a shape: the band reads as the Covenant's serrated warning edge)."""
    return from_bitmap([
        "rrrrrrrrrr",
        "gggggggggg",
        "llllllllll",
        "hhhhhhhhhh",
        "gggggggggg",
        "ddcccccccd",
        ".rcccccccr",
        "..rcccccr.",
        "...rcccr..",
        "....rcr...",
    ], {"r": INK_RED, "l": GOLD_L, "g": GOLD, "h": HOLY, "d": CRIM_DK, "c": CRIMSON})


def t_front() -> Canvas:
    """telegraphs/front: the timing front (the fill's edge as the strike nears): a holy-white line
    in gold, 8 px, tiled at radius x progress (circle, cone) or across the lane."""
    return from_bitmap([
        "gggggggg",
        "hhhhhhhh",
        "llllllll",
    ], {"g": GOLD, "h": HOLY, "l": GOLD_L})


def t_hatch() -> Canvas:
    """telegraphs/hatch: an 8 x 8 seamless tile of diagonal warning stripes (2 px light gold, 1 px
    gold), repeated row by row inside the exact danger shape (drawn translucent; denser inside
    the part already filled by the timing)."""
    c = Canvas(8, 8)
    for y in range(8):
        for x in range(8):
            k = (x + y) % 8
            if k in (0, 1):
                c.put(x, y, GOLD_L)
            elif k == 2:
                c.put(x, y, GOLD)
    return c


def t_chevron() -> Canvas:
    """telegraphs/chevron: a gold chevron pointing +x with an ink-red outline: the direction marks
    along a charge lane (lit once the timing passes them) and Seraphine's beam-sweep arrows."""
    c = Canvas(11, 13)
    for y in range(1, 12):
        for x in range(1, 10):
            s = x + abs(y - 6)
            if 5 <= s <= 8:
                c.put(x, y, GOLD_L if (y < 6 and s <= 6) else GOLD)
    c.outline(INK_RED)
    return c


def t_target() -> Canvas:
    """telegraphs/target: the impact point of a warning circle: a gold diamond with a crimson heart."""
    return from_bitmap([
        "......r......",
        ".....rlr.....",
        "....rlggr....",
        "...rlg.ggr...",
        "..rlg...ggr..",
        ".rlg..c..ggr.",
        "rlg..ccc..ggr",
        ".rgg..c..ggr.",
        "..rgg...ggr..",
        "...rgg.ggr...",
        "....rgggr....",
        ".....rgr.....",
        "......r......",
    ], {"r": INK_RED, "l": GOLD_L, "g": GOLD, "c": CRIMSON})


# =================================================================================================
# 2. Sanctified ground: holy zones, chambers, seals, sigils (baked at the radii the game uses)
# =================================================================================================

# Covenant rune glyphs (5 x 5, '#' = the glyph's light colour), written round the holy circles
# like a script ribbon: a cross, a sun, a diamond eye, a chalice, a key and a crown of bars.
RUNES = [
    ["..#..", ".###.", "..#..", "..#..", "..#.."],
    ["#.#.#", ".###.", "##.##", ".###.", "#.#.#"],
    ["..#..", ".#.#.", "#.#.#", ".#.#.", "..#.."],
    ["#...#", "#...#", ".###.", "..#..", ".###."],
    [".###.", ".#.#.", "#####", "..#..", "..#.."],
    ["#.#.#", "#####", ".....", ".###.", "..#.."],
]


def rune_ribbon(cv: Canvas, c: float, r_out: float, width: int, ribbon, ribbon_a: int, line_out, line_in, glyph,
                glyph_hi, pitch: float = 9.0, seed: int = 0) -> None:
    """A script ribbon round the circle centred (c, c): from r_out - width to r_out, filled with
    `ribbon` at alpha `ribbon_a`, edged by `line_out` (2 px, outside) and `line_in` (1 px, inside),
    with upright rune glyphs every `pitch` px of its middle circumference (light `glyph`, the
    glyph's top-left pixel `glyph_hi`). Upright glyphs keep every pixel on the grid."""
    r_in = r_out - width
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if r_out <= d < r_out + 2:
                cv.put(x, y, line_out)
            elif r_out + 2 <= d < r_out + 3:
                cv.put(x, y, INK_WARM)
            elif r_in <= d < r_in + 1:
                cv.put(x, y, line_in)
            elif r_in + 1 <= d < r_out:
                cv.put(x, y, ribbon, ribbon_a)
    mid = (r_in + 1 + r_out) / 2.0
    n = max(6, int(round(2 * math.pi * mid / pitch)))
    for i in range(n):
        a = 2 * math.pi * (i + 0.5) / n
        gx, gy = int(round(c + math.cos(a) * mid - 2.5)), int(round(c + math.sin(a) * mid - 2.5))
        g = RUNES[hsh(i, seed) % len(RUNES)]
        first = True
        for yy, row in enumerate(g):
            for xx, ch in enumerate(row):
                if ch == "#":
                    cv.put(gx + xx, gy + yy, glyph_hi if first else glyph)
                    first = False


def star_lines(cv: Canvas, c: float, r: float, points: int, step: int, wid: float, col, a: int = 255, rot: float = 0.0) -> None:
    """A star polygon {points/step} inscribed in radius `r` (straight `wid` px lines)."""
    for i in range(points):
        a0 = rot + 2 * math.pi * i / points - math.pi / 2
        a1 = rot + 2 * math.pi * ((i + step) % points) / points - math.pi / 2
        cv.thick_line(c + math.cos(a0) * r, c + math.sin(a0) * r, c + math.cos(a1) * r, c + math.sin(a1) * r, wid, col, a)


def h_zone(radius: int) -> Canvas:
    """holy/zone_<r>: a Covenant holy zone (Chaplain consecration, Alaric's Consecrated Ground), a
    gold magic circle: a script ribbon of Covenant runes (light gold on a translucent dark-gold
    band, a holy-white rim), an eight-point star of gold inlay lines, a small inner ring and an
    ivory cross in the centre. Interior transparent (the game lays a pulsing gold disc under it
    and turns eight glints round the rim)."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    rune_ribbon(cv, c, R - 1, 9, BROWN_L, 170, HOLY, GOLD, GOLD_L, HOLY, seed=radius)
    star_lines(cv, c, R * 0.72, 8, 3, 2.0, GOLD, 210)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R * 0.72 - 1 <= d < R * 0.72 + 1 and int((a + math.pi) * 0.72 * R / 4.0) % 2 == 0:
                cv.put(x, y, GOLD_L, 220)
            elif R * 0.24 <= d < R * 0.24 + 2:
                cv.put(x, y, GOLD_L)
    _cross(cv, int(c), int(c) - 1, 4, 6, HOLY, GOLD_L, outline=INK_WARM)
    return cv


def _cross(cv: Canvas, cx: int, cy: int, arm: int, up: int, col, shade, outline=None) -> None:
    """A small upright cross centred at (cx, cy): 2 px bars, `arm` px side arms, `up` px up and
    `up` + 2 px down, light colour `col` with `shade` on its lower-right half, an optional outline."""
    pts = set()
    for y in range(cy - up, cy + up + 3):
        pts.add((cx - 1, y))
        pts.add((cx, y))
    for x in range(cx - arm - 1, cx + arm + 1):
        pts.add((x, cy - 1))
        pts.add((x, cy))
    if outline is not None:
        for (x, y) in list(pts):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) not in pts:
                    cv.put(x + dx, y + dy, outline)
    for (x, y) in pts:
        cv.put(x, y, shade if (x >= cx and y >= cy) else col)


def h_chamber(radius: int) -> Canvas:
    """holy/chamber_<r>: a sanctified chamber's floor circle (the Sanctum's 220 px holy ground):
    an ivory rim in gold, a band of gold and ivory mosaic tesserae (grouted), an inner light-gold
    ring and a small sun mosaic in the centre. Interior transparent (a pulsing gold disc under it;
    the turning rune ring and the crystal beams are drawn on top)."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    band_in, band_out = R - 13.0, R - 2.0  # Mosaic band (px from the centre).
    cell = 5.0  # Tessera pitch (px).
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R + 1 <= d < R + 2:
                cv.put(x, y, INK_WARM)
            elif R - 0 <= d < R + 1:
                cv.put(x, y, GOLD)
            elif R - 2 <= d < R:
                cv.put(x, y, HOLY)
            elif band_in <= d < band_out:
                u = (a + math.pi) * (band_in + band_out) * 0.5  # Arc length along the band (px).
                v = band_out - d
                n_ring = int(round(2 * math.pi * (band_in + band_out) * 0.5 / cell))
                i = int((a + math.pi) / (2 * math.pi) * n_ring) % n_ring
                j = int(v / (cell + 0.5))
                fu = ((a + math.pi) / (2 * math.pi) * n_ring) % 1.0
                fv = (v / (cell + 0.5)) % 1.0
                if fu < 1.0 / cell or fv < 1.0 / (cell + 0.5):
                    cv.put(x, y, BROWN_L)  # Grout.
                else:
                    k = hsh(i, j, 7) % 7
                    col = (GOLD, GOLD_L, BONE_MID, GOLD, BONE, GOLD, GOLD_L)[k]
                    if (i + j) % 6 == 0:
                        col = CRIMSON  # A crimson tessera now and then.
                    cv.put(x, y, col)
            elif R - 27 <= d < R - 26:
                cv.put(x, y, GOLD_L)
            elif d < 4:
                cv.put(x, y, HOLY)
            elif d < 7:
                cv.put(x, y, GOLD_L)
            elif d < 8:
                cv.put(x, y, GOLD)
    star_lines(cv, c, R * 0.5, 12, 5, 1.0, GOLD, 110)  # Faint gold inlay star.
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R * 0.5 <= d < R * 0.5 + 2:
                cv.put(x, y, GOLD, 170)
            elif R * 0.5 + 2 <= d < R * 0.5 + 3:
                cv.put(x, y, GOLD_L, 170)
    n = 24  # Diamond inlays between the star ring and the mosaic.
    for i in range(n):
        a = 2 * math.pi * (i + 0.5) / n
        x, y = int(round(c + math.cos(a) * R * 0.74)), int(round(c + math.sin(a) * R * 0.74))
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    cv.put(x + dx, y + dy, (GOLD_L if abs(dx) + abs(dy) < 2 else GOLD), 170)
    for i in range(8):  # Sun rays of the centre mosaic.
        a = 2 * math.pi * i / 8.0
        cv.thick_line(c + math.cos(a) * 9.5, c + math.sin(a) * 9.5, c + math.cos(a) * (15.5 if i % 2 == 0 else 12.5),
                      c + math.sin(a) * (15.5 if i % 2 == 0 else 12.5), 2.0, GOLD)
    return cv


def h_cleansed(radius: int) -> Canvas:
    """holy/cleansed_<r>: a cleansed chamber, its marble rotted by the necromancer's corruption: a
    ragged deep-violet stain (two stepped alphas, darker blotches), a violet rim and soul-green
    cracks running out from the centre. The player's colours: this is his work on the Covenant's
    floor. Faded in by the game over 2 s."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            edge = R * (0.94 + 0.06 * anoise(a, 23, 11))  # Ragged outer edge (px).
            if d >= edge:
                continue
            if d >= edge - 3:
                cv.put(x, y, VIO, 150)
            elif d >= edge - 9:
                cv.put(x, y, VIO_DEEP, 120)
            else:
                blot = vnoise((x) / 23.0, (y) / 23.0, 5) * 0.7 + vnoise(x / 9.0, y / 9.0, 6) * 0.3
                if blot > 0.62:
                    cv.put(x, y, INK_VIO, 115)
                else:
                    cv.put(x, y, VIO_DEEP, 78)
    # Cracks: seven main ones (the code fallback's layout) with short side branches.
    for i in range(7):
        a = 2 * math.pi * i / 7.0 + 0.31
        pts = [(c + math.cos(a) * 12, c + math.sin(a) * 12)]
        ang = a + 0.2
        for s in range(1, 9):
            rr = 12 + (R * 0.85 - 12) * s / 8.0
            ang += (hf(i, s, 3) - 0.5) * 0.28
            pts.append((c + math.cos(ang) * rr, c + math.sin(ang) * rr))
        for s in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[s], pts[s + 1]
            cv.thick_line(x0, y0, x1, y1, 3.0, MOSS_DK, 210)
        for s in range(1, len(pts) - 1):
            (x0, y0), (x1, y1) = pts[s], pts[s + 1]
            if s % 2 == 1:
                cv.thick_line(x0, y0, (x0 + x1) / 2, (y0 + y1) / 2, 1.6, SOUL, 230)
            if s in (3, 5):  # A side branch.
                b = ang + (0.7 if (i + s) % 2 else -0.7)
                cv.thick_line(x0, y0, x0 + math.cos(b) * 18, y0 + math.sin(b) * 18, 2.0, SOUL_DK, 200)
    return cv


def h_seal(radius: int) -> Canvas:
    """holy/seal_<r>: a suppression seal (Radiant Inquisitor r 160, Seraphine r 220): a broad
    ivory script ribbon (bone-shade runes on a translucent ivory band, a holy-white rim in gold), a
    dashed light-gold ring 30 px in (the turning crosses ride between it and the ribbon), a ring of
    gold studs, a twelve-point star of faint gold lines and
    a small ivory ring and cross at the centre. Interior transparent (a pale seal-gold disc under
    it; the turning ring of crosses is drawn on top)."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    rune_ribbon(cv, c, R - 1, 11, BONE, 215, HOLY, GOLD, GOLD, GOLD_L, pitch=10.0, seed=radius + 1)
    star_lines(cv, c, R * 0.72, 12, 5, 1.0, GOLD, 120)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R - 31 <= d < R - 29 and int((a + math.pi) * (R - 30) / 4.0) % 3 != 2:
                cv.put(x, y, GOLD_L)
            elif 8 <= d < 11:
                cv.put(x, y, HOLY if d < 10 else GOLD)
    n = int(round(2 * math.pi * (R - 37) / 14.0))  # Studs.
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = int(round(c + math.cos(a) * (R - 37) - 1)), int(round(c + math.sin(a) * (R - 37) - 1))
        cv.rect(x, y, 2, 2, GOLD)
    _cross(cv, int(c), int(c) - 1, 2, 3, GOLD_L, GOLD)
    return cv


def h_altar(radius: int) -> Canvas:
    """holy/altar_<r>: the gold sigil circle under a sacred altar: a narrow script ribbon of runes
    (light gold on dark gold, a light-gold rim), a dashed inner ring and four gold diamonds on the
    diagonals (the turning rays are drawn on top)."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    rune_ribbon(cv, c, R - 1, 8, BROWN_L, 170, GOLD_L, GOLD, GOLD_L, HOLY, seed=radius + 2)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if 0.6 * R - 1 <= d < 0.6 * R and int((a + math.pi) * 0.6 * R / 4.0) % 2 == 0:
                cv.put(x, y, GOLD)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        x, y = int(round(c + math.cos(a) * R * 0.7)), int(round(c + math.sin(a) * R * 0.7))
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    cv.put(x + dx, y + dy, GOLD_L if abs(dx) + abs(dy) < 2 else GOLD)
    return cv


def h_safe(radius: int) -> Canvas:
    """holy/safe_<r>: one of Seraphine's nova safe circles, the ground part: a cool dark hole cut
    in her gold glow (deep ink, two stepped alphas), a cold-blue inner pool and six small ice
    crosses (the bright rim, the countdown and the sanctuary cross are drawn over the bodies)."""
    cv, c = disc_canvas(radius)
    R = float(radius)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if d < R * 0.6:
                cv.put(x, y, ARC_DK, 120)
            elif d < R * 0.62:
                cv.put(x, y, ARC, 150)
            elif d < R:
                cv.put(x, y, INK_COLD, 215)
    for i in range(6):
        a = 2 * math.pi * i / 6.0 + math.pi / 6.0
        _cross(cv, int(round(c + math.cos(a) * R * 0.8)), int(round(c + math.sin(a) * R * 0.8)) - 1, 1, 2, ICE, ARC_L)
    return cv


def h_safe_rim(radius: int) -> Canvas:
    """holy/safe_rim_<r>: the bright rim of a safe circle (over the bodies): a 3 px icy-white ring
    edged in ice and, 4-6 px outside it, a thin cold-blue halo (its alpha pulses in the game)."""
    cv, c = disc_canvas(radius, pad=9)
    R = float(radius)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R - 2 <= d < R + 1:
                cv.put(x, y, ICE_L)
            elif R + 1 <= d < R + 2 or R - 3 <= d < R - 2:
                cv.put(x, y, ICE)
            elif R + 4 <= d < R + 6 and int((a + math.pi) * (R + 5) / 3.0) % 3 != 0:
                cv.put(x, y, ARC_L if d < R + 5 else ARC)
    return cv


# --- Small pieces (orbiting glyphs, ticks, columns) -------------------------------------------

def h_glint() -> Canvas:
    """holy/glint: a 7 px four-point star (holy-white heart, light-gold arms): the glints that orbit
    a holy zone's rim, a lash tip, a revival pillar's crown."""
    return from_bitmap([
        "...g...",
        "...l...",
        "..lhl..",
        "glhhhlg",
        "..lhl..",
        "...l...",
        "...g...",
    ], {"g": GOLD, "l": GOLD_L, "h": HOLY})


def h_rune() -> Canvas:
    """holy/rune: a gold mosaic diamond with a holy-white cross heart (the 12 runes that turn round
    a sanctified chamber)."""
    return from_bitmap([
        "....r....",
        "...rgr...",
        "..rglgr..",
        ".rglhlgr.",
        "rglhhhlgr",
        ".rglhlgr.",
        "..rglgr..",
        "...rgr...",
        "....r....",
    ], {"r": INK_WARM, "g": GOLD, "l": GOLD_L, "h": HOLY})


def h_seal_cross() -> Canvas:
    """holy/seal_cross: a gold cross with an ink outline and a holy-white heart (the ten crosses
    that turn round a suppression seal)."""
    return from_bitmap([
        "..rrr..",
        "..rlr..",
        "rrrlrrr",
        "rllhllr",
        "rrrlgrr",
        "..rlr..",
        "..rlr..",
        "..rgr..",
        "..rrr..",
    ], {"r": INK_WARM, "g": GOLD, "l": GOLD_L, "h": HOLY})


def h_ray() -> Canvas:
    """holy/ray: a short gold light ray, pointing +x (outward), holy-white at its tip: the turning
    rays of an altar sigil and Alaric's Judgment mark, the sun ticks of a Paladin ward."""
    return from_bitmap([
        ".gggggg...",
        "gllllllhh.",
        "gllllllhhh",
        ".gggggg...",
    ], {"g": GOLD, "l": GOLD_L, "h": HOLY})


def h_aura_dash() -> Canvas:
    """holy/aura_dash: one 12 px piece of a faint dashed aura ring (a 6 px dash, a 6 px gap: Banner
    Bearer, Holy Standard, Paladin ward, Seraphine's beam range), tiled along the ring."""
    return from_bitmap([
        "...llllll...",
        "...gggggg...",
    ], {"g": GOLD, "l": GOLD_L})


def h_rally_edge() -> Canvas:
    """holy/rally_edge: a piece of the crimson ring that closes on a Call to Arms rally point and
    rings a zealous Sister of the Scourge."""
    return from_bitmap([
        "rrrrrrrr",
        "cccccccc",
        "dddddddd",
    ], {"r": INK_RED, "c": CRIMSON, "d": CRIM_DK})


def h_warn_line() -> Canvas:
    """holy/warn_line: a dashed gold-and-white warning ray piece (5 px on, 3 off), repeated along
    a beam's path before it ignites."""
    return from_bitmap([
        "ggggg...",
        "hhhhh...",
        "ggggg...",
    ], {"g": GOLD, "h": HOLY})


def h_light_beam() -> Canvas:
    """holy/light_beam: an 8 px piece of a thin light ray (gold sheath, holy-white core with a
    moving bright dash), scrolled along a crystal's beam to its chamber, a Sentinel's raised blade."""
    return from_bitmap([
        "gggggggg",
        "hhhhllll",
        "hhhhhhll",
        "llllllll",
        "gggggggg",
    ], {"g": GOLD, "l": GOLD_L, "h": HOLY})


def h_beam_core() -> Canvas:
    """holy/beam_core: a 16 px piece of a great holy beam 24 px wide (Seraphine's sweeping beams,
    the Cathedral Guardian's beam): gold sheath, light-gold rows, a holy-white core with light-gold
    flow streaks; scrolled along the beam so it flows outward."""
    rows = []
    for y in range(24):
        e = min(y, 23 - y)  # Rows from the beam's edge.
        row = []
        for x in range(16):
            if e <= 1:
                row.append("g")
            elif e <= 4:
                row.append("l")
            elif e in (5, 6) and ((x + (0 if y < 12 else 8)) % 16) < 6:
                row.append("l")
            else:
                row.append("h")
        rows.append("".join(row))
    return from_bitmap(rows, {"g": GOLD, "l": GOLD_L, "h": HOLY})


def h_beam_glow() -> Canvas:
    """holy/beam_glow: a seamless 8 x 16 piece of the soft gold glow round a great beam: three
    stepped alphas, faintest at the edges (stretched to twice the beam's width under it)."""
    c = Canvas(8, 16)
    for y in range(16):
        e = min(y, 15 - y)
        a = 40 if e < 3 else (70 if e < 5 else 100)
        for x in range(8):
            c.put(x, y, GOLD, a)
    return c


def h_beam_cap() -> Canvas:
    """holy/beam_cap: the blazing head of a great beam (and its origin flare): a holy-white heart
    in a light-gold ring, eight gold rays."""
    cv, c = disc_canvas(13, pad=3)
    for i in range(8):
        a = 2 * math.pi * i / 8.0
        ln = 15.0 if i % 2 == 0 else 11.0
        cv.thick_line(c + math.cos(a) * 6, c + math.sin(a) * 6, c + math.cos(a) * ln, c + math.sin(a) * ln, 2.0, GOLD)
    for y in range(cv.h):
        for x in range(cv.w):
            d, _ = polar(cv, c, c, x, y)
            if d < 5:
                cv.put(x, y, HOLY)
            elif d < 8:
                cv.put(x, y, GOLD_L)
    return cv


def h_light_column() -> Canvas:
    """holy/light_column: a column of holy light rising from the ground (24 x 64, base on the
    bottom row): a holy-white core, light-gold and gold sheaths in stepped alphas, thinning and
    fading toward the top. Stretched to a revival pillar's or a teleport landing's height."""
    w, h = 24, 64
    cv = Canvas(w, h)
    for y in range(h):
        t = 1.0 - y / float(h - 1)  # 0 at the bottom, 1 at the top.
        half = 11.0 - 5.0 * t
        fade = 1.0 if t < 0.55 else max(0.25, 1.0 - (t - 0.55) * 1.6)
        for x in range(w):
            e = abs(x + 0.5 - w / 2.0)
            if e > half:
                continue
            if e < half * 0.3:
                cv.put(x, y, HOLY, int(235 * fade))
            elif e < half * 0.62:
                cv.put(x, y, GOLD_L, int(170 * fade))
            else:
                cv.put(x, y, GOLD, int(105 * fade))
    return cv


def h_sunburst() -> Canvas:
    """holy/sunburst: a Covenant casting sunburst (17 px: eight light-gold rays round a holy-white
    heart in a gold ring): an Inquisitor or Confessor casting, the Guardian's charging eye and the
    glow round its raised fists."""
    cv, c = disc_canvas(7, pad=2)
    for i in range(8):
        a = 2 * math.pi * i / 8.0
        cv.thick_line(c + math.cos(a) * 4, c + math.sin(a) * 4, c + math.cos(a) * (8.4 if i % 2 == 0 else 6.6),
                      c + math.sin(a) * (8.4 if i % 2 == 0 else 6.6), 1.6, GOLD_L)
    for y in range(cv.h):
        for x in range(cv.w):
            d, _ = polar(cv, c, c, x, y)
            if d < 2.2:
                cv.put(x, y, HOLY)
            elif d < 3.4:
                cv.put(x, y, GOLD)
    return cv


def h_guardian_fist() -> Canvas:
    """holy/guardian_fist: one of the Cathedral Guardian's raised stone fists (16 x 15): warm
    stone knuckles over a gold-banded wrist, outlined in ink (drawn in the sunburst's glow while
    the slam winds up)."""
    return from_bitmap([
        "...rrrrrrrr.....",
        "..rkskrkskrrr...",
        ".rksssrsssrksr..",
        ".rsssdrsdsrssdr.",
        ".rsssdrsdsrssdr.",
        ".rrrrrrrrrrrsdr.",
        "rlsssssssssrsdr.",
        "rsssssssssssdrr.",
        "rssssssssssddr..",
        ".rddddddddddr...",
        "..rggggggggr....",
        "..rlllllllgr....",
        "..rggggggggr....",
        "...rsssssdr.....",
        "...rrrrrrrr.....",
    ], {"r": INK_WARM, "s": STEEL, "k": STEEL_L, "l": GOLD_L, "d": STEEL_DK, "g": GOLD})


def h_shield() -> Canvas:
    """overlays/holy_shield: a High Confessor's holy shield round an ally (40 px bubble): a gold
    ring with an ink rim, a pale holy-white film inside (stepped alpha) and a bright highlight arc
    at the top-left. Scaled to the shielded body."""
    cv, c = disc_canvas(18, pad=2)
    R = 18.0
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            if R <= d < R + 1:
                cv.put(x, y, INK_WARM)
            elif R - 2 <= d < R:
                cv.put(x, y, GOLD_L if a < -0.2 and a > -2.6 else GOLD)
            elif R - 4 <= d < R - 3 and -2.5 < a < -1.3:
                cv.put(x, y, HOLY)
            elif d < R - 2:
                cv.put(x, y, HOLY, 46 if d > R - 6 else 26)
    return cv


def h_wrath_halo() -> Canvas:
    """holy/wrath_halo: Sir Alaric's Wrath (below half HP), drawn under him: a burning ring of
    flame tongues round a crimson-gold band, a faint flame glow inside (stepped alpha). Baked for
    his 22 px body (ring radius 35 px = 1.6 x his radius)."""
    R = 35.0
    cv, c = disc_canvas(int(R) + 6, pad=2)
    for y in range(cv.h):
        for x in range(cv.w):
            d, a = polar(cv, c, c, x, y)
            tongue = R + 2 + 5.0 * max(0.0, math.sin(a * 9 + 0.6)) ** 2 + 2.0 * anoise(a, 27, 4)
            if d < R - 3:
                cv.put(x, y, FLAME, 34 if d < R - 10 else 52)
            elif d < R - 1:
                cv.put(x, y, GOLD_L)
            elif d < R + 1:
                cv.put(x, y, GOLD)
            elif d < R + 2:
                cv.put(x, y, CRIMSON)
            elif d < tongue:
                cv.put(x, y, FLAME if d < tongue - 2 else CRIMSON, 220)
    return cv


def h_lash() -> Canvas:
    """holy/lash: a 6 px piece of the Sister of the Scourge's lash cord (crimson, ink-edged, a gold
    barb every piece), repeated along the line while the lash winds up."""
    return from_bitmap([
        "rr.rr.",
        "ccrgcc",
        "dddgdd",
        "rr.rr.",
    ], {"r": INK_RED, "c": CRIMSON, "d": CRIM_DK, "g": GOLD_L})


def h_nova_wave() -> Canvas:
    """holy/nova_wave: a 12 px dash of the radiant pulse rings that roll out from Seraphine while
    her Judgment nova charges (holy white in light gold)."""
    return from_bitmap([
        "llllllllll..",
        "hhhhhhhhhh..",
        "llllllllll..",
    ], {"l": GOLD_L, "h": HOLY})


def h_safe_tick() -> Canvas:
    """holy/safe_tick: a 6 px piece of a safe circle's countdown (icy white in cold blue), the ring
    draining as the nova nears."""
    return from_bitmap([
        "aaaaaa",
        "iiiiii",
        "iiiiii",
        "aaaaaa",
    ], {"a": ARC_L, "i": ICE_L})


def h_collapse_edge() -> Canvas:
    """holy/collapse_edge: a 12 px piece of the collapsing arena's burning edge, row 0 OUTSIDE (in
    the fire): crimson, flame, light gold, a 2 px holy-white inner line."""
    return from_bitmap([
        "rrrrrrrrrrrr",
        "ffffffffffff",
        "ffffffffffff",
        "llllllllllll",
        "hhhhhhhhhhhh",
        "hhhhhhhhhhhh",
    ], {"r": CRIMSON, "f": FLAME, "l": GOLD_L, "h": HOLY})


def h_collapse_flames() -> Canvas:
    """effects-like strip holy/collapse_flame: six frames of one flame tongue (12 x 30, its base on
    the bottom row, licking up), crimson at the rim, flame, light gold and a holy-white heart at
    the base; each tongue on the ring plays them from its own offset (flicker)."""
    frames = []
    w, h = 12, 30
    for f in range(6):
        cv = Canvas(w, h)
        ph = f / 6.0 * 2 * math.pi
        top = 20.0 + 6.0 * math.sin(ph) + 2.0 * math.sin(ph * 2 + 1.0)  # Tongue height (px).
        for y in range(h):
            t = (h - 1 - y) / top  # 0 at the base, 1 at the tip.
            if t > 1.0:
                continue
            sway = 2.2 * math.sin(ph + t * 3.2) * t
            half = 5.5 * (1.0 - t) ** 0.75 + 0.6
            for x in range(w):
                e = abs(x + 0.5 - (w / 2.0 + sway))
                if e > half:
                    continue
                inner = e / max(half, 0.01)
                if t < 0.35 and inner < 0.35:
                    col = HOLY
                elif inner < 0.55 and t < 0.75:
                    col = GOLD_L
                elif inner < 0.85:
                    col = FLAME
                else:
                    col = CRIMSON
                cv.put(x, y, col)
        frames.append(cv)
    return strip_of(frames)


def h_collapse_scorch() -> Canvas:
    """holy/collapse_scorch: the burning ground beyond the collapsing arena's edge, a 512 px square
    with a transparent hole of radius 128 px (scaled so the hole is the arena): a hot flame band at
    the edge, stepping down to a dim crimson burn scattered with embers (stepped alphas)."""
    S, H = 512, 128.0
    cv = Canvas(S, S)
    c = S / 2.0
    for y in range(S):
        for x in range(S):
            d, a = polar(cv, c, c, x, y)
            if d < H:
                continue
            e = d - H
            if e < 4:
                cv.put(x, y, GOLD_L, 120)
            elif e < 10:
                cv.put(x, y, FLAME, 135)
            elif e < 19:
                cv.put(x, y, FLAME, 95)
            elif e < 34:
                cv.put(x, y, CRIMSON, 82)
            else:
                ember = hsh(x // 2, y // 2, 9) % 97 == 0
                cv.put(x, y, FLAME if ember else CRIMSON, 110 if ember else 64)
    return cv


def h_smoke(i: int) -> Canvas:
    """holy/smoke_bank (+ _2, _3): a drifting smoke bank of the zone-change sweep, a GREY MASK (the
    game tints it with the stage's bank colour): a lumpy cloud of three stepped alphas, lighter
    puffs on its top-left."""
    w, h = (176, 120, 156)[i], (112, 84, 100)[i]
    cv = Canvas(w, h)
    blobs = []
    for k in range(7):
        bx = w * (0.22 + 0.56 * hf(i, k, 1))
        by = h * (0.3 + 0.4 * hf(i, k, 2))
        br = min(w, h) * (0.22 + 0.14 * hf(i, k, 3))
        blobs.append((bx, by, br))
    for y in range(h):
        for x in range(w):
            best = 0.0
            for bx, by, br in blobs:
                q = 1.0 - math.hypot((x + 0.5 - bx) / br, (y + 0.5 - by) / (br * 0.8))
                best = max(best, q)
            best += (vnoise(x / 11.0, y / 11.0, 30 + i) - 0.5) * 0.25
            if best <= 0.0:
                continue
            top = (x + y) / float(w + h) < 0.45  # Lighter puffs on the top-left.
            if best > 0.45:
                cv.put(x, y, (235, 235, 235) if top else (200, 200, 200), 200)
            elif best > 0.2:
                cv.put(x, y, (200, 200, 200), 150)
            else:
                cv.put(x, y, (170, 170, 170), 95)
    return cv


def h_fog(i: int) -> Canvas:
    """decals/graveyard_fog (+ _2, _3): a patch of spectral graveyard fog (112 / 128 / 144 px wide),
    wispy and flattened, three stepped faint soul-green alphas (it replaces the hard-edged flat
    teal disc)."""
    w = (112, 128, 144)[i]
    h = int(w * 0.62)
    cv = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            nx, ny = (x + 0.5 - w / 2.0) / (w / 2.0), (y + 0.5 - h / 2.0) / (h / 2.0)
            r = math.hypot(nx, ny)
            n = vnoise(x / 13.0, y / 9.0, 50 + i) * 0.6 + vnoise(x / 6.0, y / 5.0, 60 + i) * 0.4
            v = (1.0 - r) + (n - 0.5) * 0.7
            if v > 0.55:
                cv.put(x, y, SOUL, 30)
            elif v > 0.3:
                cv.put(x, y, SOUL, 21)
            elif v > 0.08:
                cv.put(x, y, SOUL_DK, 22)
    return cv


def h_dawn_shaft() -> Canvas:
    """holy/dawn_shaft: one shaft of Dawn's Wrath light (the Sanctum's Reckoning), 64 x 240 from
    its narrow root (bottom) to its wide end (top), three faint stepped alphas of light gold."""
    w, h = 64, 240
    cv = Canvas(w, h)
    for y in range(h):
        t = (h - 1 - y) / float(h - 1)
        half = 10.0 + 22.0 * t
        for x in range(w):
            e = abs(x + 0.5 - w / 2.0)
            if e > half:
                continue
            q = e / half
            a = 34 if q < 0.4 else (24 if q < 0.75 else 14)
            if t < 0.08 or t > 0.9:
                a = a * 2 // 3
            cv.put(x, y, GOLD_L, a)
    return cv


# =================================================================================================
# 3. Effect strips (assets/sprites/effects/, AnimData): played once through SpriteBank.draw_anim()
# =================================================================================================

def fx_boss_death() -> Canvas:
    """effects/boss_death: a stage boss falls (10 frames of 256 px): a holy-white flash with a
    cross of long rays, a gold ring racing outward and breaking into motes, the rays guttering."""
    frames = []
    S = 256
    for f in range(10):
        cv = Canvas(S, S)
        c = S / 2.0
        t = f / 9.0
        ring_r = 18 + 98 * (1 - (1 - t) ** 1.6)  # Ring radius (px).
        ring_w = 7 - 4 * t
        flash_r = 30 * (1 - t) ** 1.5 + 2
        ray_len = 60 + 50 * t if f < 7 else 0
        for y in range(S):
            for x in range(S):
                d, a = polar(cv, c, c, x, y)
                broken = t > 0.5 and int((a + math.pi) * ring_r / 7.0) % 3 == (f % 3) and hf(int((a + math.pi) * 9), f) < t
                if ring_r - ring_w <= d < ring_r and not broken:
                    cv.put(x, y, HOLY if d >= ring_r - 2 else (GOLD_L if d >= ring_r - ring_w * 0.6 else GOLD))
                elif d < flash_r:
                    cv.put(x, y, HOLY if d < flash_r * 0.65 else GOLD_L)
        if ray_len > 0:
            for i in range(8):
                a = i * math.pi / 4
                ln = ray_len * (1.0 if i % 2 == 0 else 0.55) * (1 - 0.6 * max(0.0, t - 0.4))
                wd = (5.0 if i % 2 == 0 else 3.0) * (1 - 0.6 * t)
                cv.thick_line(c + math.cos(a) * flash_r * 0.5, c + math.sin(a) * flash_r * 0.5,
                              c + math.cos(a) * ln, c + math.sin(a) * ln, wd, GOLD_L)
                cv.thick_line(c + math.cos(a) * flash_r * 0.5, c + math.sin(a) * flash_r * 0.5,
                              c + math.cos(a) * ln * 0.7, c + math.sin(a) * ln * 0.7, max(1.0, wd - 2), HOLY)
        if f >= 3:  # Motes flung outward.
            for m in range(26):
                a = 2 * math.pi * hf(m, 1) + 0.2
                rr = ring_r * (0.55 + 0.55 * hf(m, 2)) + 8 * t
                if rr > 124 or hf(m, f, 3) < (t - 0.55):
                    continue
                cv.rect(int(c + math.cos(a) * rr), int(c + math.sin(a) * rr), 2, 2, GOLD_L if m % 3 else HOLY)
        frames.append(cv)
    return strip_of(frames)


def _crescent_frames(n: int, size: int, ramp: tuple) -> list:
    """Frames of a crescent swing toward +x (the slash arc of Effect.Kind.SLASH, -0.9..+0.9 rad):
    the blade's bright edge sweeps across from one end to the other with a trail behind it, then
    the trail breaks up. `ramp` = (edge, light, mid, dark) palette colours."""
    edge, light, mid, dark = ramp
    frames = []
    c = size / 2.0
    R = size * 0.42  # Crescent outer radius (px) = the slash radius x 1 (fill 1.2 in AnimData).
    for f in range(n):
        cv = Canvas(size, size)
        t = (f + 1) / float(n)
        lead = -0.95 + 1.9 * min(1.0, t * 1.35)  # Leading edge angle (rad).
        tail = lead - 1.25  # Trail start.
        fade = max(0.0, (t - 0.72) / 0.28)  # Break-up at the end.
        for y in range(size):
            for x in range(size):
                d, a = polar(cv, c, c, x, y)
                if a > lead or a < max(tail, -0.95):
                    continue
                k = (lead - a) / 1.25  # 0 at the leading edge, 1 at the tail.
                thick = 0.28 * R * (1.0 - k) ** 0.8 + 2.0  # Crescent thickness here (px).
                if not (R - thick <= d < R):
                    continue
                if fade > 0 and hf(x // 2, y // 2, f) < fade:
                    continue
                q = (R - d) / thick  # 0 at the outer edge.
                if q < 0.18 and k < 0.55:
                    col = edge
                elif q < 0.45:
                    col = light
                elif q < 0.75:
                    col = mid
                else:
                    col = dark
                cv.put(x, y, col)
        frames.append(cv)
    return frames


def fx_vael_cleave() -> Canvas:
    """effects/vael_cleave: Marshal Vael's Radiant Cleave (6 frames of 128 px): a crescent of holy
    flame sweeping across the cleave's arc (holy-white edge, gold, flame, crimson trail), drawn
    turned toward the strike."""
    return strip_of(_crescent_frames(6, 128, (HOLY, GOLD_L, FLAME, CRIMSON)))


def fx_sentinel_sweep() -> Canvas:
    """effects/sentinel_sweep: a Sanctified Sentinel's blade sweep (6 frames of 128 px): the same
    crescent in the Sanctum's ivory and gold."""
    return strip_of(_crescent_frames(6, 128, (HOLY, BONE, GOLD_L, GOLD)))


def fx_structure_break() -> Canvas:
    """effects/structure_break: a Covenant structure destroyed (8 frames of 128 px), a GREY MASK
    the game tints with the effect colour (flame on the March, gold for a ward crystal, violet for
    an altar the necromancer brings down): a flash, splinters and chunks flung out, a dust ring
    rolling and thinning."""
    frames = []
    S = 128
    c = S / 2.0
    for f in range(8):
        cv = Canvas(S, S)
        t = f / 7.0
        dust_r = 14 + 40 * (1 - (1 - t) ** 2)
        for y in range(S):
            for x in range(S):
                d, a = polar(cv, c, c, x, y)
                wob = dust_r + 5 * (anoise(a, 13, f // 3) - 0.5)
                thick = 9 * (1 - t) + 3
                if wob - thick <= d < wob and hf(x // 2, y // 2, 40 + f) > t * 0.75:
                    cv.put(x, y, (200, 200, 200) if d > wob - thick * 0.5 else (150, 150, 150))
                elif f < 3 and d < 16 * (1 - f / 3.0) + 3:
                    cv.put(x, y, (255, 255, 255))
        for m in range(14):  # Splinters / chunks.
            a = 2 * math.pi * hf(m, 7)
            rr = 8 + (50 + 10 * hf(m, 8)) * (1 - (1 - t) ** 1.5)
            if t > 0.85 and m % 2:
                continue
            px, py = c + math.cos(a) * rr, c + math.sin(a) * rr
            ln = 4 if m % 3 else 2
            cv.thick_line(px, py, px + math.cos(a) * ln, py + math.sin(a) * ln, 2.0, (255, 255, 255) if m % 4 == 0 else (215, 215, 215))
        frames.append(cv)
    return strip_of(frames)


# =================================================================================================
# Registry, review images
# =================================================================================================

# key -> (builder, kind, frames, description). kind: "tile", "still", "disc", "strip" (frames > 1).
ASSETS = {
    "telegraphs/edge": (t_edge, "tile", 1, "Telegraph warning band piece (10 x 6): ink rim, a 4 px gold band with a holy-white heart, a dark crimson inner row; tiled at 1:1 along every warning circle, lane side and cone edge"),
    "telegraphs/edge_tooth": (t_edge_tooth, "tile", 1, "The band piece with a crimson tooth pointing into the danger (every other piece): the Covenant's serrated warning edge"),
    "telegraphs/front": (t_front, "tile", 1, "Timing front (8 x 3): a holy-white line in gold, at radius x progress (circle, cone) or across the lane"),
    "telegraphs/hatch": (t_hatch, "tile", 1, "Warning hatch (8 x 8 seamless): diagonal light-gold stripes, laid row by row inside the exact danger shape, denser where the timing has filled"),
    "telegraphs/chevron": (t_chevron, "still", 1, "Direction chevron (11 x 13): gold with an ink-red outline; along a charge lane (lit as the timing passes) and on Seraphine's beam-sweep warnings"),
    "telegraphs/target": (t_target, "still", 1, "Impact point (13 x 13): a gold diamond with a crimson heart at the centre of a warning circle"),
    "holy/zone_62": (lambda: h_zone(62), "disc", 1, "Holy zone, r 62 (Alaric's Consecrated Ground): ivory rim in gold, a ring of crosses, dashed inner ring, eight spokes, an ivory centre cross"),
    "holy/zone_85": (lambda: h_zone(85), "disc", 1, "Holy zone, r 85 (a Chaplain's consecration on the Graveyard): the same sigil at its size"),
    "holy/zone_105": (lambda: h_zone(105), "disc", 1, "Holy zone, r 105 (the Crimson March's consecrations): the same sigil at its size"),
    "holy/chamber_220": (lambda: h_chamber(220), "disc", 1, "Sanctified chamber floor circle (r 220): ivory rim, a band of grouted gold and ivory mosaic tesserae with crimson accents, an inner ring, a small sun mosaic in the centre"),
    "holy/cleansed_220": (lambda: h_cleansed(220), "disc", 1, "Cleansed chamber (r 220): a ragged deep-violet rot stain on the marble with darker blotches, a violet rim and soul-green cracks (stepped alphas)"),
    "holy/seal_160": (lambda: h_seal(160), "disc", 1, "Suppression seal, r 160 (Radiant Inquisitor): broad ivory rim in gold, dashed inner ring, a ring of gold studs, a small ivory ring and cross at the centre"),
    "holy/seal_220": (lambda: h_seal(220), "disc", 1, "Suppression seal, r 220 (Seraphine): the same seal at her size"),
    "holy/altar_48": (lambda: h_altar(48), "disc", 1, "Sacred altar sigil (r 48 = 2.4 x the altar): light-gold ring in gold, dashed inner ring, four gold diamonds"),
    "holy/safe_62": (lambda: h_safe(62), "disc", 1, "Seraphine's nova safe circle, ground (r 62): a cool dark hole in her gold glow, a cold-blue pool, six small ice crosses (stepped alphas)"),
    "holy/safe_rim_62": (lambda: h_safe_rim(62), "disc", 1, "Safe circle rim (over the bodies): a 3 px icy-white ring and a dashed cold-blue halo (its alpha pulses)"),
    "holy/glint": (h_glint, "still", 1, "Holy glint (7 x 7): a four-point star; eight orbit a holy zone's rim, one crowns a revival pillar and a lash tip"),
    "holy/rune": (h_rune, "still", 1, "Chamber rune (9 x 9): a gold mosaic diamond with a holy-white cross heart; twelve turn round a sanctified chamber"),
    "holy/seal_cross": (h_seal_cross, "still", 1, "Seal cross (7 x 9): a gold cross with a holy heart; ten turn round a suppression seal"),
    "holy/ray": (h_ray, "still", 1, "Holy ray (10 x 4): a short gold ray pointing outward; the turning rays of an altar sigil and a Judgment mark, a Paladin ward's sun ticks, Seraphine's Avatar halo"),
    "holy/aura_dash": (h_aura_dash, "tile", 1, "Aura dash (12 x 2: a 6 px dash and its gap): tiled along a faint aura ring (Banner Bearer, Holy Standard, Paladin ward) and Seraphine's beam range"),
    "holy/rally_edge": (h_rally_edge, "tile", 1, "Rally ring piece (8 x 3): crimson; the ring closing on a Call to Arms point, a Sister's zeal ring"),
    "holy/warn_line": (h_warn_line, "tile", 1, "Beam warning dash (8 x 3): gold and holy white, along a beam's path before it ignites"),
    "holy/light_beam": (h_light_beam, "tile", 1, "Thin light ray piece (8 x 5): scrolled along a ward crystal's beam to its chamber and a Sentinel's raised blade"),
    "holy/beam_core": (h_beam_core, "tile", 1, "Great beam piece (16 x 24): gold sheath, holy-white core with flow streaks; scrolled along Seraphine's beams and the Cathedral Guardian's beam"),
    "holy/beam_glow": (h_beam_glow, "tile", 1, "Great beam glow piece (8 x 16): three stepped gold alphas, stretched to twice the beam's width under it"),
    "holy/beam_cap": (h_beam_cap, "still", 1, "Great beam head (32 x 32): holy heart in a light-gold ring, eight gold rays; the beam's tip and its origin flare"),
    "holy/light_column": (h_light_column, "still", 1, "Light column (24 x 64, base on the bottom row): a High Confessor's revival pillar and Seraphine's teleport landing, stretched to height"),
    "holy/sunburst": (h_sunburst, "still", 1, "Casting sunburst (18 x 18): eight light-gold rays round a holy heart; Inquisitor / Confessor casting, the Guardian's charging eye and fists"),
    "holy/guardian_fist": (h_guardian_fist, "still", 1, "Cathedral Guardian's raised stone fist (16 x 15): warm stone knuckles over a gold-banded wrist"),
    "holy/wrath_halo": (h_wrath_halo, "disc", 1, "Sir Alaric's Wrath halo (under him below half HP): flame tongues round a gold and crimson ring, a faint flame glow inside"),
    "holy/lash": (h_lash, "tile", 1, "Scourge lash piece (6 x 4): crimson cord with a gold barb, along the Sister's lash while it winds up"),
    "holy/nova_wave": (h_nova_wave, "tile", 1, "Nova pulse dash (12 x 3): the radiant rings rolling out from Seraphine while her Judgment charges"),
    "holy/safe_tick": (h_safe_tick, "tile", 1, "Safe-circle countdown piece (6 x 4): icy white in cold blue, the ring draining as the nova nears"),
    "holy/collapse_edge": (h_collapse_edge, "tile", 1, "Collapsing-arena edge piece (12 x 6): crimson, flame, light gold and a holy-white inner line"),
    "holy/collapse_flame": (h_collapse_flames, "strip", 6, "Flame tongue (6 frames of 12 x 30, base at the bottom): licks up along the collapsing arena's edge and round Seraphine in the Last Light, each from its own frame offset"),
    "holy/collapse_scorch": (h_collapse_scorch, "disc", 1, "Burning ground beyond the collapsing arena (512 px, a 128 px hole scaled to the arena): a hot band stepping down to a dim crimson burn with embers"),
    "holy/smoke_bank": (lambda: h_smoke(0), "still", 1, "Zone-change smoke bank (grey mask tinted with the stage's bank colour), variant 1"),
    "holy/smoke_bank_2": (lambda: h_smoke(1), "still", 1, "Zone-change smoke bank, variant 2"),
    "holy/smoke_bank_3": (lambda: h_smoke(2), "still", 1, "Zone-change smoke bank, variant 3"),
    "holy/dawn_shaft": (h_dawn_shaft, "still", 1, "Dawn's Wrath light shaft (64 x 240, root at the bottom): faint stepped light gold"),
    "overlays/holy_shield": (h_shield, "disc", 1, "High Confessor's holy shield (40 px bubble): gold ring, ink rim, a pale holy film and a top-left highlight arc"),
    "decals/graveyard_fog": (lambda: h_fog(0), "still", 1, "Graveyard fog patch (112 px): wispy, three faint stepped soul-green alphas (was a hard flat teal disc)"),
    "decals/graveyard_fog_2": (lambda: h_fog(1), "still", 1, "Graveyard fog patch, 128 px"),
    "decals/graveyard_fog_3": (lambda: h_fog(2), "still", 1, "Graveyard fog patch, 144 px"),
    "effects/boss_death": (fx_boss_death, "strip", 10, "A stage boss falls (10 frames of 256 px): holy-white flash with a cross of rays, a gold ring racing out and breaking into motes"),
    "effects/vael_cleave": (fx_vael_cleave, "strip", 6, "Marshal Vael's Radiant Cleave (6 frames of 128 px): a crescent of holy flame sweeping the arc, turned toward the strike"),
    "effects/sentinel_sweep": (fx_sentinel_sweep, "strip", 6, "Sanctified Sentinel's sweep (6 frames of 128 px): the crescent in ivory and gold"),
    "effects/structure_break": (fx_structure_break, "strip", 8, "Structure destroyed (8 frames of 128 px, grey mask tinted per stage): a flash, splinters and a dust ring"),
}


def build(only=None) -> list:
    """Builds every asset (or the keys in `only`); returns the keys written."""
    done = []
    for key, (fn, kind, frames, desc) in ASSETS.items():
        if only and key not in only:
            continue
        cv = fn()
        path = cv.save(key)
        print("%-28s %4d x %-4d %s" % (key, cv.w, cv.h, os.path.relpath(path, ROOT)))
        done.append(key)
    return done


def review(out_dir: str, keys: list) -> list:
    """Writes the review images of `keys` into `out_dir`/images: the PNG at 1x, at 4x nearest
    (big discs at 2x), and a GIF of every strip; returns the manifest image rows."""
    img_dir = os.path.join(out_dir, "images")
    os.makedirs(img_dir, exist_ok=True)
    rows = []
    for key in keys:
        fn, kind, frames, desc = ASSETS[key]
        im = Image.open(os.path.join(SPRITES, key + ".png")).convert("RGBA")
        name = key.replace("/", "_")
        p1 = os.path.join(img_dir, name + ".png")
        im.save(p1)
        zoom = 4 if max(im.size) <= 260 else 2
        # Shown on a dark Graveyard-soil backdrop so faint translucent pieces read.
        big = Image.new("RGBA", (im.width * zoom, im.height * zoom), (22, 26, 28, 255))
        big.alpha_composite(im.resize((im.width * zoom, im.height * zoom), Image.NEAREST))
        p4 = os.path.join(img_dir, name + "_x4.png")
        big.save(p4)
        row = {"id": name, "key": key, "path": os.path.relpath(p1, ROOT), "path_x4": os.path.relpath(p4, ROOT),
               "size": [im.width, im.height], "description": desc, "before": "", "after": ""}
        if frames > 1:
            fw = im.width // frames
            gif = []
            for f in range(frames):
                fr = Image.new("RGBA", (fw * zoom, im.height * zoom), (22, 26, 28, 255))
                fr.alpha_composite(im.crop((f * fw, 0, (f + 1) * fw, im.height)).resize((fw * zoom, im.height * zoom), Image.NEAREST))
                gif.append(fr.convert("RGB"))
            pg = os.path.join(img_dir, name + ".gif")
            gif[0].save(pg, save_all=True, append_images=gif[1:], duration=120, loop=0)
            row["gif"] = os.path.relpath(pg, ROOT)
        rows.append(row)
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", default="", help="comma-separated keys to rebuild")
    ap.add_argument("--review", default="", help="also write review images into this folder")
    args = ap.parse_args()
    only = [k for k in args.only.split(",") if k] or None
    keys = build(only)
    if args.review:
        rows = review(os.path.join(ROOT, args.review), keys)
        with open(os.path.join(ROOT, args.review, "images.json"), "w") as f:
            json.dump(rows, f, indent=1)
        print("review: %d images in %s" % (len(rows), args.review))


if __name__ == "__main__":
    main()
