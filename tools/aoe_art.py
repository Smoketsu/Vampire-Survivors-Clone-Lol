#!/usr/bin/env python3
"""aoe_art.py: draws the necromancer side's ground-effect pieces straight onto the art grid.

Why (player AoE art pass, Oct 2026; GDD 15.0 "Player AoE art"): the owner saw "quite a few
placeholder graphics for some of the AoEs in act one". The art audit (docs/art/audit/act1_shared.md)
found that they were never missing PNGs: every ground area of the necromancer's spells, summon
specials and abilities was a flat translucent disc, ring or polygon in code, because an old rule kept
"rings, telegraphs, zones, glows" in code. A ground area must match its real hit radius at ANY radius
(levels and area passives grow them), so one stretched image would blur or misplace its edge. These
effects are therefore built from small PIECES drawn 1:1 (art px = screen px, the sharp-pixel shader)
and placed by the game (scripts/fx/aoe_art.gd, numbers in scripts/data/aoe_art_data.gd):

  * ring pieces, repeated along a circle and turned outward (the Undertow crest pattern): the
    piece's +x points AWAY from the centre, its y runs along the rim. Burst pieces are 4-frame
    strips that break up as the shock rolls out;
  * cloud puffs and motes scattered over an area;
  * centre pieces (ground cracks, a frost star) in a few fixed sizes;
  * lane tiles (a body tile repeated along the lane plus a head cap);
  * a few whole sprites (flame loops, a scorch mark, bone spikes, a light column, the black sun).

Everything is palette colours (tools/palette.json) with binary alpha; the game fades a piece with
its draw alpha. Each frame keeps a 1 px transparent border, so the sharp-pixel shader never blends
in a neighbouring frame. Deterministic: no randomness (a fixed hash), so a rerun reproduces the
files exactly.

Usage (from the repo root):
    python3 tools/aoe_art.py                 # writes assets/sprites/aoe/*.png
    python3 tools/aoe_art.py --out DIR       # writes them to DIR instead
    python3 tools/aoe_art.py --preview FILE  # also a contact sheet of every piece (x4, on the floor)
"""
import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Default output folder (the game reads res://assets/sprites/aoe/<id>.png).
OUT_DIR = ROOT / "assets" / "sprites" / "aoe"

# Colour ramps by name, dark -> light, as palette.json colour names. Level 0 is the ramp's ink
# (outline / deepest shade), the last level its brightest highlight. A piece is drawn in levels and
# coloured by one of these, so one shape serves several effects in their own colours.
RAMPS = {
    "bone": ["ink_warm", "bone_shade", "bone_mid", "bone"],
    "earth": ["ink_warm", "brown", "brown_light", "bone_mid"],
    "flesh": ["ink_green", "moss_dark", "moss", "bone_mid"],
    "ice": ["ink_cold", "grey", "ice", "ice_light"],
    "arcane": ["ink_cold", "arcane_dark", "arcane", "arcane_light"],
    "wail": ["ink_cold", "arcane", "arcane_light", "ice_light"],
    "violet": ["ink_violet", "violet_deep", "violet", "violet_glow", "violet_flare"],
    "soul": ["ink_green", "soul_dark", "soul", "soul_glow"],
    "plague": ["ink_green", "moss_dark", "moss", "gold_light"],
    "plague_gas": ["moss_dark", "moss_dark", "moss", "gold_light"],
    "pest_gas": ["ink_violet", "ink_violet", "violet_deep", "moss_dark"],
    "pest": ["ink_violet", "violet_deep", "moss_dark", "moss"],
    "stone": ["ink_cold", "grey_dark", "grey", "grey_light"],
    "flame": ["ink_red", "crimson", "flame", "gold_light"],
    "scorch": ["ink_warm", "ink_red", "crimson_dark", "flame"],
    "gold": ["ink_warm", "brown_light", "gold", "gold_light", "holy_white"],
}

# Burst ring pieces (4-frame strips): cell size (art px) radial x tangent, frame count.
CREST_CELL = (14, 16)
# Frames in every burst crest strip (fresh -> broken up).
CREST_FRAMES = 4
# Telegraph rim piece cell (art px): radial x tangent.
MARK_CELL = (7, 14)
# Cloud puff diameters (art px): small, medium, large.
PUFF_SIZES = (18, 26, 34)
# Cloud rim wisp cell (art px): radial x tangent.
WISP_CELL = (11, 12)
# Wither rune-rim cell (art px): radial x tangent; 2 frames = 2 variants (thorn + rune, thorn).
RUNE_CELL = (10, 16)
# Ground-crack centre piece diameters (art px): small, medium, large.
CRACK_SIZES = (32, 48, 64)
# Flame tongue loop cell (art px) and frames (Hellhound fire patches, shard-field embers).
FLAME_CELL = (14, 20)
# Frames of the flame loop.
FLAME_FRAMES = 4
# Scorch mark diameters (art px) under a fire patch / shard field.
SCORCH_SIZES = (28, 60)
# Bone spike cells (art px, w x h): two variants (Grave Eruption field, Ossuary shard field).
SPIKE_CELLS = ((9, 15), (11, 19))
# Rogue dash lane: body tile (along x) and head cap, both lane-wide (24 px across = UnitData dash_width).
LANE_CELL = (8, 24)
# Dash streak sprite (art px), pointing +x (the dash direction).
STREAK_CELL = (30, 12)
# Summon evolution light column (art px) and its frames.
COLUMN_CELL = (22, 64)
# Frames of the light column loop.
COLUMN_FRAMES = 4
# Eclipse black sun sprite diameter (art px).
SUN_SIZE = 50
# Sovereign's Decree taunt halo diameters (art px): under small, medium and big summons; the last
# one is the necromancer's veil.
HALO_SIZES = (30, 42, 58)
# Grave Tide edge-mist tile (art px): along the view edge x depth into the view.
TIDE_CELL = (24, 40)
# Centre flash strip cell (art px, square) and frames (mage splash, wail, dive).
FLASH_CELL = 25
# Frames of a centre flash.
FLASH_FRAMES = 3
# Frost star centre piece (art px, square) and frames (Deep Freeze).
STAR_CELL = 29
# Mote / bubble cells (art px, square) and their frames.
MOTE_CELL = 7
# Frames of a mote / bubble strip.
MOTE_FRAMES = 3


# --------------------------------------------------------------------------------------
# Palette and raster helpers
# --------------------------------------------------------------------------------------

def palette() -> dict:
    """Colour name -> (r, g, b, 255), read from tools/palette.json."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    return {c["name"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in data["colors"]}


def hsh(*v: float) -> float:
    """Deterministic hash of the numbers `v` to 0..1 (no RNG: reruns reproduce the art)."""
    s = 0.0
    for i, x in enumerate(v):
        s += x * (12.9898 + 7.233 * i)
    h = math.sin(s) * 43758.5453
    return h - math.floor(h)


class Grid:
    """A small raster of ramp levels: -1 transparent, 0.. = ramp level (0 = ink)."""

    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.a = np.full((h, w), -1, dtype=int)

    def put(self, x: float, y: float, v: int, over: bool = True) -> None:
        """Sets pixel (x, y) to level `v` (rounded; outside is ignored; `over` False keeps set pixels)."""
        xi, yi = int(round(x)), int(round(y))
        if 0 <= xi < self.w and 0 <= yi < self.h and (over or self.a[yi, xi] < 0):
            self.a[yi, xi] = v

    def get(self, x: int, y: int) -> int:
        """Level at (x, y), -1 outside or transparent."""
        if 0 <= x < self.w and 0 <= y < self.h:
            return int(self.a[y, x])
        return -1

    def disc(self, cx: float, cy: float, r: float, v: int) -> None:
        """Fills a disc of radius `r` centred on (cx, cy) with level `v`."""
        for y in range(self.h):
            for x in range(self.w):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.a[y, x] = v

    def line(self, x0: float, y0: float, x1: float, y1: float, v: int) -> None:
        """A 1 px line (DDA, rounded) from (x0, y0) to (x1, y1) in level `v`."""
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            t = i / max(n, 1)
            self.put(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, v)

    def shaded_blob(self, cx: float, cy: float, r: float, levels=(1, 2, 3), light: float = 0.45) -> None:
        """A shaded disc: shade on the bottom-right rim, mid body, a light crescent at the top-left.
        `levels` = (shade, mid, light); `light` = how far (fraction of r) the highlight reaches in."""
        sh, mid, lt = levels
        rr = max(r, 0.5)
        for y in range(self.h):
            for x in range(self.w):
                dx, dy = x - cx, y - cy
                d2 = dx * dx + dy * dy
                if d2 > rr * rr:
                    continue
                # A lit sphere: the surface normal against a light from the top-left, in front.
                nx, ny = dx / rr, dy / rr
                nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
                lum = -0.62 * nx - 0.62 * ny + 0.48 * nz  # -1..1.
                if lum < 0.12:
                    self.a[y, x] = sh
                elif lum < 0.92 - light:
                    self.a[y, x] = mid
                else:
                    self.a[y, x] = lt

    def outline(self, v: int = 0, sides: str = "all") -> None:
        """Paints transparent pixels touching an opaque one (4-neighbour) with level `v`.
        `sides` "br" limits it to the bottom and right edges (a drop-shadow outline)."""
        src = self.a.copy()
        dirs = ((1, 0), (-1, 0), (0, 1), (0, -1)) if sides == "all" else ((-1, 0), (0, -1))
        for y in range(self.h):
            for x in range(self.w):
                if src[y, x] >= 0:
                    continue
                for dx, dy in dirs:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and src[ny, nx] > v:
                        self.a[y, x] = v
                        break

    def clear_border(self) -> None:
        """Keeps a 1 px transparent border (no neighbour-frame bleed under the sharp-pixel shader)."""
        self.a[0, :] = -1
        self.a[-1, :] = -1
        self.a[:, 0] = -1
        self.a[:, -1] = -1

    def despeck(self) -> None:
        """Removes isolated single opaque pixels of mid levels (keeps the brightest: glints)."""
        top = int(self.a.max())
        src = self.a.copy()
        for y in range(self.h):
            for x in range(self.w):
                v = src[y, x]
                if v < 0 or v == top:
                    continue
                n = 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and src[ny, nx] >= 0:
                        n += 1
                if n == 0:
                    self.a[y, x] = -1

    def image(self, ramp: list, pal: dict) -> Image.Image:
        """RGBA image of the grid with each level coloured by `ramp` (palette names)."""
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        px = img.load()
        for y in range(self.h):
            for x in range(self.w):
                v = int(self.a[y, x])
                if v >= 0:
                    px[x, y] = pal[ramp[min(v, len(ramp) - 1)]]
        return img


def strip(frames: list, ramp: list, pal: dict) -> Image.Image:
    """A horizontal strip of equal grids (frames), each coloured with `ramp`."""
    w, h = frames[0].w, frames[0].h
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, g in enumerate(frames):
        g.clear_border()
        out.paste(g.image(ramp, pal), (i * w, 0))
    return out


def multi(g: Grid, colours: dict, pal: dict) -> Image.Image:
    """RGBA image of a grid whose levels are keys of `colours` (level -> palette name)."""
    img = Image.new("RGBA", (g.w, g.h), (0, 0, 0, 0))
    px = img.load()
    for y in range(g.h):
        for x in range(g.w):
            v = int(g.a[y, x])
            if v >= 0:
                px[x, y] = pal[colours[v]]
    return img


# --------------------------------------------------------------------------------------
# Burst crests (ring pieces, +x outward, 4 frames: fresh -> broken up)
# --------------------------------------------------------------------------------------

def band(g: Grid, x: float, thick: int, f: int, top: int = 3) -> None:
    """The bright front of a shock crest along the tangent at radial `x` (its outer edge),
    `thick` px deep (levels top, top-1, top-2 inward). It is whole in frame 0 and breaks into
    ever shorter dashes in frames 1-3 (fixed patterns, so the ring tears up evenly)."""
    for y in range(1, g.h - 1):
        if f == 1 and y % 7 == 3:
            continue
        if f == 2 and y % 5 in (0, 1):
            continue
        if f >= 3 and y % 5 not in (2, 3):
            continue
        for t in range(thick):
            g.put(x - t, y, max(1, top - t))


def crest_chunks(f: int) -> Grid:
    """Stomp / boulder / dive shock crest: a 3 px dust band at the front with chunky debris
    behind it; the band tears into dashes and the chunks fly out and shrink as the frames go."""
    w, h = CREST_CELL
    g = Grid(w, h)
    band(g, w - 2 - (1 if f == 0 else 0), [3, 3, 2, 2][f], f)
    for i in range(5):
        if f >= 2 and i % 2 == 1:
            continue
        cx = 3.5 + hsh(i, 1.0) * 3.0 + f * 1.3
        cy = 2.5 + (i + 0.5) * (h - 5) / 5.0 + (hsh(i, 2.0) - 0.5) * 1.6
        cy = h / 2 + (cy - h / 2) * (1.0 + 0.1 * f)
        r = [2.0, 1.9, 1.6, 1.2][f] - (0.3 if i % 2 else 0.0)
        g.shaded_blob(cx, cy, r, (1, 2, 3), light=0.3)
    g.outline(0, "br")
    return g


def crest_shards(f: int) -> Grid:
    """Deep Freeze crest: ice crystals pointing outward that grow, then shatter into glints."""
    w, h = CREST_CELL
    g = Grid(w, h)
    for i in range(3):
        cy = 3 + i * 5 + (1 if i == 1 else 0)
        length = [6, 10, 11, 0][f] + (1 if i == 1 else 0)
        x0 = 1
        if f < 3:
            for k in range(length):
                half = 1.8 * (1.0 - abs(k - length * 0.45) / (length * 0.62))  # Diamond half-width.
                for dy in range(-2, 3):
                    if abs(dy) <= half:
                        v = 3 if dy < 0 or k == length - 1 else (2 if dy == 0 else 1)
                        g.put(x0 + k, cy + dy, v)
            if f == 2:
                g.put(x0 + length, cy, 3)  # Tip glint.
        else:
            for k in range(3):
                g.put(5 + k * 2 + i, cy + (k - 1), 3 if k != 1 else 2)
                g.put(6 + k * 2 + i, cy + (k - 1), 2)
    g.outline(0, "br")
    return g


def crest_ripple(f: int) -> Grid:
    """Banshee wail crest: two sound-wave arcs (gently convex outward) that thin and break."""
    w, h = CREST_CELL
    g = Grid(w, h)
    for j, (x0, lit, thick) in enumerate(((w - 4, 3, 3), (w - 9, 2, 2))):
        if f >= 3 and j == 1:
            continue
        th = max(1, thick - (1 if f >= 2 else 0))
        for y in range(1, h - 1):
            t = (y - (h - 1) / 2.0) / ((h - 2) / 2.0)
            x = x0 + 1.2 * (1.0 - t * t) + f * 0.7
            broken = (f == 1 and j == 1 and y % 4 == 0) or (f == 2 and y % 4 == 0) or (f == 3 and y % 4 in (0, 1))
            if broken:
                continue
            for k in range(th):
                g.put(x - k, y, max(1, lit - k))
    return g


def crest_sparks(f: int) -> Grid:
    """Arcane splash crest: a bright 2-3 px arc band with four-point sparks scattering outward."""
    w, h = CREST_CELL
    g = Grid(w, h)
    band(g, w - 3, [3, 2, 2, 1][f], f)
    for i in range(2):
        if f == 3 and i == 1:
            continue
        cx = 4 + f * 1.6 + i * 1.5
        cy = 4 + i * 8 + (f % 2)
        g.put(cx, cy, 3)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            g.put(cx + dx, cy + dy, 2)
        if f <= 1:
            for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                g.put(cx + dx, cy + dy, 1)
    return g


def crest_puffs(f: int) -> Grid:
    """Spore / dust crest: a front of soft round puffs that swell, then thin into rings."""
    w, h = CREST_CELL
    g = Grid(w, h)
    for i in range(3):
        cy = 3 + i * 5 + (1 if i == 1 else 0)
        cx = 7 + f * 0.9 - (1.5 if i == 1 else 0)
        r = [2.2, 3.0, 3.0, 2.0][f] + (0.4 if i == 1 else 0.0)
        g.shaded_blob(cx, cy, r, (1, 2, 3), light=0.35)
        if f >= 2:
            g.put(cx, cy, -1)
            g.put(cx - 1, cy, -1)
            if f == 3:
                g.put(cx, cy - 1, -1)
    g.outline(0, "br")
    return g


def crest_wisps(f: int) -> Grid:
    """Soul / violet crest: flame wisps (teardrops, tip outward) that lick out and gutter."""
    w, h = CREST_CELL
    g = Grid(w, h)
    for i in range(3):
        if f == 3 and i == 1:
            continue
        cy = 3.5 + i * 4.5
        base = 2 + f * 1.4 + (1.5 if i == 1 else 0)
        length = [6, 8, 7, 4][f]
        for k in range(length):
            rad = 2.0 * (1.0 - k / float(length)) + 0.4
            yy = cy + math.sin(k * 0.9 + i + f) * 0.6
            for dy in range(-2, 3):
                if abs(dy) <= rad:
                    v = 3 if abs(dy) < 1 and k >= 1 else (2 if abs(dy) < rad - 0.6 else 1)
                    g.put(base + k, yy + dy, v)
    return g

# Heavy dust crest cell (art px): radial x tangent (stomps, boulders, dives).
DUST_CELL = (18, 20)


def crest_dust(f: int) -> Grid:
    """Heavy impact crest (stomp, boulder, dive): a front of big dust puffs rolling outward with
    a couple of rocks flung ahead; the puffs swell, then hollow out and shrink as they settle."""
    w, h = DUST_CELL
    g = Grid(w, h)
    for i in range(3):
        cy = 4 + i * 6 + (0.5 if i == 1 else 0)
        cx = [7, 9, 10.5, 11.5][f] - (1.5 if i == 1 else 0)
        r = [3.0, 4.2, 4.4, 3.2][f] + (0.5 if i == 1 else 0.0)
        g.shaded_blob(cx, cy, r, (1, 2, 3), light=0.2)
    if f >= 2:
        for i in range(3):
            cy = 4 + i * 6 + (0.5 if i == 1 else 0)
            cx = [7, 9, 10.5, 11.5][f] - (1.5 if i == 1 else 0)
            for dx in range(-1, 1 + (f == 3)):
                g.put(cx + dx, cy, -1)
                g.put(cx + dx, cy + 1, -1)
    if 1 <= f <= 2:
        for i, cy in enumerate((5, 14)):
            g.shaded_blob(w - 4 + f - i, cy + i, 1.3, (1, 2, 3), light=0.3)
    g.outline(0, "br")
    return g


# Shape name -> frame function (each crest strip is one shape in one ramp).
CREST_SHAPES = {
    "chunks": crest_chunks,
    "shards": crest_shards,
    "ripple": crest_ripple,
    "sparks": crest_sparks,
    "puffs": crest_puffs,
    "dust": crest_dust,
    "wisps": crest_wisps,
}

# Burst crest strips to write: file id -> (shape, ramp).
CRESTS = {
    "crest_stomp": ("dust", "earth"),
    "crest_bone": ("dust", "bone"),
    "crest_stone": ("dust", "stone"),
    "crest_rubble": ("chunks", "earth"),
    "crest_frost": ("shards", "ice"),
    "crest_wail": ("ripple", "wail"),
    "crest_wail_violet": ("ripple", "violet"),
    "crest_ivory": ("ripple", "bone"),
    "crest_arcane": ("sparks", "arcane"),
    "crest_spore": ("puffs", "plague"),
    "crest_dust": ("puffs", "bone"),
    "crest_soul": ("wisps", "soul"),
    "crest_violet": ("wisps", "violet"),
}


# --------------------------------------------------------------------------------------
# Telegraph rim marks (one piece, two frames: plain and lit)
# --------------------------------------------------------------------------------------

def mark(f: int) -> Grid:
    """A dial-like rim mark: a 2 px arc segment along the tangent with an inward tick in the
    middle and bright end caps; frame 1 is the same, lit (the last moment before the strike)."""
    w, h = MARK_CELL
    g = Grid(w, h)
    for y in range(2, h - 2):
        g.put(5, y, 2 + f)
        g.put(4, y, 1 + f)
    for x in range(2, 4):
        g.put(x, h // 2 - 1, 2 + f)
        g.put(x, h // 2, 1 + f)
    g.put(5, 2, 3)
    g.put(5, h - 3, 3)
    g.outline(0, "br")
    return g


# Telegraph mark strips: file id -> ramp.
MARKS = {
    "mark_bone": "bone",
    "mark_ice": "ice",
    "mark_wail": "wail",
    "mark_violet": "violet",
    "mark_soul": "soul",
}


# --------------------------------------------------------------------------------------
# Clouds (Plague Cloud, Pestilence)
# --------------------------------------------------------------------------------------

def puff(d: int, seed: int) -> Grid:
    """A lumpy cloud puff of diameter `d`: three or four lumps along the bottom and one or two
    on top, painted back to front (top lumps first) so each front lump's shaded rim shows over
    the one behind it; a small highlight on the upper-left of each lump."""
    g = Grid(d + 2, d + 2)
    c = (d + 1) / 2.0
    lumps = []
    for i in range(2):
        lumps.append((c - d * 0.12 + i * d * 0.22, c - d * 0.16 - i * d * 0.04, d * (0.24 - 0.05 * i)))
    n = 3 if d < 24 else 4
    for i in range(n):
        x = c - d * 0.3 + i * (d * 0.6) / (n - 1)
        y = c + d * 0.1 + (hsh(seed, i) - 0.5) * d * 0.08
        lumps.append((x, y, d * (0.2 + 0.05 * hsh(i, seed, 3.0))))
    lumps.append((c, c + d * 0.02, d * 0.27))  # The main body, in front.
    for (x, y, r) in lumps:
        g.shaded_blob(x, y, r, (1, 2, 3), light=0.12)
    g.despeck()
    g.outline(0, "br")
    return g


def wisp(f: int) -> Grid:
    """A cloud rim tongue: a thick curl rooted at the inner side, its tip curling outward;
    frame 1 is the curl swayed the other way (the rim breathes)."""
    w, h = WISP_CELL
    g = Grid(w, h)
    for k in range(9):
        t = k / 8.0
        x = 1.5 + t * 7.5
        y = h / 2.0 + math.sin(t * 2.6 + f * 1.2) * 2.2 * t - (1.0 if f else 0.0) * t
        r = 3.2 * (1.0 - t) + 0.7
        g.shaded_blob(x, y, r, (1, 2, 3), light=0.15)
    g.despeck()
    g.outline(0, "br")
    return g


def bubble(f: int) -> Grid:
    """A rising plague bubble: small ring, bigger ring, popped (four specks)."""
    g = Grid(MOTE_CELL, MOTE_CELL)
    c = MOTE_CELL // 2
    if f == 0:
        for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
            g.put(c + dx, c + dy, 2)
        g.put(c - 1, c - 1, 3)
    elif f == 1:
        for dx, dy in ((0, -2), (1, -2), (2, -1), (2, 0), (2, 1), (1, 2), (0, 2), (-1, 2), (-2, 1), (-2, 0), (-2, -1), (-1, -2)):
            g.put(c + dx, c + dy, 2)
        g.put(c - 1, c - 1, 3)
    else:
        for dx, dy in ((0, -2), (2, 0), (0, 2), (-2, 0)):
            g.put(c + dx, c + dy, 3)
    return g


def mote(f: int) -> Grid:
    """A soul mote: a small glowing diamond (frame 0), brighter (1), shrunk (2)."""
    g = Grid(MOTE_CELL, MOTE_CELL)
    c = MOTE_CELL // 2
    if f < 2:
        for dx, dy in ((0, -2), (-1, -1), (0, -1), (1, -1), (-2, 0), (-1, 0), (1, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (0, 2)):
            g.put(c + dx, c + dy, 1 + f)
        for dx, dy in ((0, 0), (0, -1), (-1, 0)):
            g.put(c + dx, c + dy, 2 + f)
    else:
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            g.put(c + dx, c + dy, 1)
        g.put(c, c, 3)
    return g


# --------------------------------------------------------------------------------------
# Wither rune rim
# --------------------------------------------------------------------------------------

def rune(f: int) -> Grid:
    """One Wither rim segment: a 2 px thorny vine along the tangent with a thorn hooking
    outward; frame 0 also carries a rune mark on the inner side (a hooked stave and a dot),
    frame 1 a drooping drip. Ink-outlined so it reads on every floor."""
    w, h = RUNE_CELL
    g = Grid(w, h)
    for y in range(1, h - 1):
        x = 5 + (1 if 5 <= y <= 10 else 0)
        g.put(x, y, 2)
        g.put(x - 1, y, 1)
    # Thorn outward (a 3 px hook).
    for (x, y, v) in ((7, 6, 2), (7, 7, 3), (8, 7, 3), (7, 8, 1)):
        g.put(x, y, v)
    if f == 0:
        for (x, y) in ((2, 3), (2, 4), (2, 5), (2, 6), (3, 6), (3, 3)):
            g.put(x, y, 2)
        g.put(2, 9, 3)
        g.put(2, 10, 2)
    else:
        for (x, y) in ((3, 11), (2, 11), (2, 12)):
            g.put(x, y, 2)
        g.put(2, 13, 3)
    g.outline(0, "all")
    return g


# --------------------------------------------------------------------------------------
# Centre pieces: ground cracks, frost star, flashes
# --------------------------------------------------------------------------------------

def crack(d: int, seed: int, glow: bool) -> Grid:
    """Ground cracks radiating from a small crater, diameter `d`. Plain: dark ink cracks with
    a lit lip (level 2) on the side facing the light. `glow`: the crack's core is level 3 (a
    glowing seam, Grave Eruption)."""
    g = Grid(d, d)
    c = (d - 1) / 2.0
    rays = 7 if d < 40 else 9
    for i in range(rays):
        ang = math.tau * (i + hsh(seed, i) * 0.6) / rays
        length = d * 0.5 * (0.55 + 0.4 * hsh(i, seed, 1.0)) - 1.5
        x, y = c, c
        steps = int(length)
        a = ang
        for s in range(steps):
            a += (hsh(i, s, seed) - 0.5) * 0.7
            x += math.cos(a)
            y += math.sin(a)
            core = 3 if glow and s < steps * 0.7 else 0
            g.put(x, y, core)
            if s < steps * 0.55:
                # 2 px wide near the crater: the second px beside it, across the crack.
                g.put(x - math.sin(a), y + math.cos(a), 2 if glow else 0)
            # The lit lip: one px toward the top-left on the first part of the crack.
            if s < steps * 0.8:
                g.put(x - 1 if math.sin(a) > 0 else x, y - 1 if math.cos(a) < 0 else y, 2, over=False)
            # A fork halfway.
            if s == steps // 2 and i % 2 == 0:
                fx, fy, fa = x, y, a + 0.9
                for _ in range(max(2, steps // 3)):
                    fx += math.cos(fa)
                    fy += math.sin(fa)
                    g.put(fx, fy, 3 if glow else 0)
    # The crater.
    for y in range(d):
        for x in range(d):
            dd = math.hypot(x - c, y - c)
            if dd <= 2.6:
                g.a[y, x] = 0 if not glow else 3
            elif dd <= 3.6:
                g.a[y, x] = 2 if (x - c) + (y - c) > 0 else 1
    return g


def frost_star(f: int) -> Grid:
    """Deep Freeze centre: a six-armed frost star that grows (frames 0-1) and cracks (2)."""
    d = STAR_CELL
    g = Grid(d, d)
    c = d // 2
    arm = [6, 11, 12][f]
    for i in range(6):
        a = math.tau * i / 6.0 + math.pi / 6.0
        for k in range(1, arm + 1):
            if f == 2 and k % 4 == 2:
                continue
            x, y = c + math.cos(a) * k, c + math.sin(a) * k
            g.put(x, y, 3 if k < arm * 0.5 else 2)
            if k == arm // 2 + 1 and arm > 6:
                for side in (-1, 1):
                    b = a + side * 0.8
                    for j in range(1, 4):
                        g.put(x + math.cos(b) * j, y + math.sin(b) * j, 2)
    for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)):
        g.put(c + dx, c + dy, 3)
    g.outline(1, "all")
    g.outline(0, "br")
    return g


def flash(f: int) -> Grid:
    """A small centre flash: a bright four-point star (0), a ring with rays (1), a broken ring (2)."""
    d = FLASH_CELL
    g = Grid(d, d)
    c = d // 2
    if f == 0:
        for k in range(-7, 8):
            v = 3 if abs(k) <= 3 else 2
            g.put(c + k, c, v)
            g.put(c, c + k, v)
        for dx, dy in ((1, 1), (-1, -1), (1, -1), (-1, 1)):
            g.put(c + dx, c + dy, 2)
    else:
        r = 6 if f == 1 else 9
        n = 28
        for i in range(n):
            a = math.tau * i / n
            if f == 2 and i % 4 == 0:
                continue
            g.put(c + math.cos(a) * r, c + math.sin(a) * r, 3 if f == 1 else 2)
        if f == 1:
            for i in range(4):
                a = math.tau * i / 4.0 + math.pi / 4.0
                for k in range(r + 2, r + 5):
                    g.put(c + math.cos(a) * k, c + math.sin(a) * k, 2)
            g.put(c, c, 3)
    g.outline(1, "all")
    return g


# --------------------------------------------------------------------------------------
# Fire, scorch, spikes (Hellhound fire patches, Ossuary shard fields, Grave Eruption)
# --------------------------------------------------------------------------------------

def flame(f: int, variant: int) -> Grid:
    """A flame tongue loop frame: a teardrop of fire whose tip sways (4 frames loop). Levels:
    0 ink outline, 1 crimson rim, 2 flame body, 3 gold core."""
    w, h = FLAME_CELL
    g = Grid(w, h)
    base_y = h - 2
    height = 13 + (f % 2) + variant
    for yy in range(height):
        t = yy / float(height)  # 0 at the base, 1 at the tip.
        half = 4.4 * math.sqrt(max(0.0, 1.0 - t)) * (1.0 - 0.15 * t)
        sway = math.sin(f * math.pi / 2.0 + t * 2.2 + variant) * 1.6 * t
        cx = w / 2.0 - 0.5 + sway
        y = base_y - yy
        for x in range(w):
            d = abs(x - cx)
            if d <= half:
                rel = d / max(half, 0.01)
                if rel < 0.45 and t < 0.55:
                    v = 3
                elif rel < 0.8:
                    v = 2
                else:
                    v = 1
                g.put(x, y, v)
    # A detached ember above the tip on odd frames.
    if f % 2 == 1:
        g.put(w / 2.0 + math.sin(f + variant) * 2.0, base_y - height - 2, 3)
    g.outline(0, "all")
    return g


def scorch(d: int, seed: int) -> Grid:
    """A scorched patch of ground (diameter `d`): a ragged dark burn with a few glowing embers.
    Levels: 0 deep char, 1 ink red char, 2 crimson-dark embers' halo, 3 flame ember."""
    g = Grid(d, d)
    c = (d - 1) / 2.0
    for y in range(d):
        for x in range(d):
            ang = math.atan2(y - c, x - c)
            edge = d * 0.5 - 1.0 - 2.5 * (0.5 + 0.5 * math.sin(ang * 5.0 + seed)) * hsh(int(ang * 3), seed)
            dd = math.hypot(x - c, y - c)
            if dd <= edge:
                g.a[y, x] = 1 if dd > edge - 2.0 or hsh(x // 3, y // 3, seed) > 0.7 else 0
    n = max(3, d // 9)
    for i in range(n):
        a = math.tau * hsh(i, seed, 5.0)
        r = (d * 0.36) * hsh(seed, i, 7.0)
        x, y = c + math.cos(a) * r, c + math.sin(a) * r
        g.put(x, y, 3)
        g.put(x + 1, y, 2)
        g.put(x, y + 1, 2)
    return g


def spike(variant: int) -> Grid:
    """A bone spike from the ground (base on the bottom row): a curved horn with a lit left
    edge, a shaded right side and an ink outline; a soul-glow chip at its base (level 4)."""
    w, h = SPIKE_CELLS[variant]
    g = Grid(w, h)
    base = h - 2
    height = h - 3
    wide = (w - 3) / 2.0
    for yy in range(height):
        t = yy / float(height)
        half = wide * (1.0 - t) ** 0.9 + 0.35
        bend = 1.4 * t * t * (1 if variant == 0 else -1)
        cx = w / 2.0 - 0.5 + bend
        for x in range(w):
            d = x - cx
            if abs(d) <= half:
                v = 3 if d < -half * 0.35 else (1 if d > half * 0.45 else 2)
                g.put(x, base - yy, v)
    g.outline(0, "all")
    # The glowing grave crack at the root.
    g.put(w // 2 - 1, base + 1, 4)
    g.put(w // 2, base + 1, 4)
    g.put(w // 2 + 1, base + 1, 0)
    return g


# --------------------------------------------------------------------------------------
# Rogue dash lane and streak
# --------------------------------------------------------------------------------------

def lane_body(f: int) -> Grid:
    """One lane tile (8 px along the dash, 24 across): dashed side rails and a chevron pointing
    along the dash (+x). Frame 0 the faint lane, frame 1 the filled (charged) lane."""
    w, h = LANE_CELL
    g = Grid(w, h)
    for x in range(1, w - 3):
        g.put(x, 1, 2 + f)
        g.put(x, h - 2, 2 + f)
        g.put(x, 2, 1 + f)
        g.put(x, h - 3, 1 + f)
    mid = h // 2
    for k in range(5):
        g.put(2 + k, mid - 5 + k, 2 + f)
        g.put(2 + k, mid + 4 - k, 2 + f)
        g.put(1 + k, mid - 5 + k, 1 + f)
        g.put(1 + k, mid + 4 - k, 1 + f)
    return g


def lane_head() -> Grid:
    """The lane's head cap: a broad arrowhead the lane's width, pointing +x."""
    w, h = LANE_CELL
    g = Grid(w, h)
    mid = (h - 1) / 2.0
    for y in range(1, h - 1):
        span = int(round((1.0 - abs(y - mid) / (mid)) * (w - 2)))
        for x in range(span):
            edge = x == span - 1
            g.put(1 + x, y, 3 if edge else (2 if x >= span - 3 else 1))
    return g


def streak() -> Grid:
    """The Rogue's dash streak: a shadow smear thinning backward (-x) with a bone core line."""
    w, h = STREAK_CELL
    g = Grid(w, h)
    mid = h // 2
    for x in range(1, w - 1):
        t = x / float(w - 2)  # 0 at the tail, 1 at the head.
        half = 1.0 + 3.4 * t
        for y in range(h):
            d = abs(y - mid + 0.5)
            if d <= half:
                g.put(x, y, 1 if d > half - 1.0 else 2)
        if t > 0.35:
            g.put(x, mid, 4 if t > 0.75 else 3)
    for x in range(2, w - 2, 5):
        g.put(x, mid - 1, -1)
    return g


# --------------------------------------------------------------------------------------
# Summon evolution column, ultimates
# --------------------------------------------------------------------------------------

def column(f: int) -> Grid:
    """The summon evolution's light column: a soul-light pillar (wide at the base) with violet
    runes rising through it and a bright base ellipse. Levels: 0-3 soul ramp, 5-6 violet."""
    w, h = COLUMN_CELL
    g = Grid(w, h)
    cx = (w - 1) / 2.0
    for y in range(1, h - 1):
        t = 1.0 - y / float(h - 1)  # 0 at the bottom.
        half = 6.5 - 3.0 * t + 0.8 * math.sin(y * 0.5 + f * 1.57) * t
        for x in range(w):
            d = abs(x - cx)
            if d <= half:
                g.put(x, y, 3 if d < half * 0.35 else (2 if d < half * 0.75 else 1))
    # Runes rising.
    for i in range(3):
        ry = (h - 10) - ((i * 18 + f * 6) % (h - 14))
        rx = cx - 2 + (i % 2) * 3
        for (dx, dy) in ((0, 0), (1, 0), (0, 1), (0, 2), (1, 2)):
            g.put(rx + dx, ry + dy, 6 if (dx + dy) % 2 == 0 else 5)
    # Base ellipse.
    for x in range(w):
        for y in range(h - 7, h - 1):
            ex, ey = (x - cx) / 10.0, (y - (h - 4)) / 2.5
            if 0.62 <= ex * ex + ey * ey <= 1.0:
                g.put(x, y, 3 if ey < 0 else 2)
    return g


def black_sun() -> Grid:
    """Eclipse: a black disc with a thin violet rim inside a ragged pale corona with rays.
    Levels: 0 ink violet core, 1 violet_deep rim, 2 violet, 3 violet_glow, 4 violet_flare."""
    d = SUN_SIZE
    g = Grid(d, d)
    c = (d - 1) / 2.0
    for y in range(d):
        for x in range(d):
            dd = math.hypot(x - c, y - c)
            ang = math.atan2(y - c, x - c)
            ray = 0.5 + 0.5 * math.cos(ang * 12.0)
            if dd <= 14.0:
                g.a[y, x] = 0
            elif dd <= 15.0:
                g.a[y, x] = 1
            elif dd <= 17.0:
                g.a[y, x] = 4
            elif dd <= 18.5 + 5.5 * ray ** 3:
                g.a[y, x] = 3 if dd <= 19.5 else 2
    # The thin crescent of light on the core's lower-left (the sun peeking out).
    for y in range(d):
        for x in range(d):
            dd = math.hypot(x - c, y - c)
            if 12.5 <= dd <= 14.0 and (x - c) < -4 and (y - c) > 2:
                g.a[y, x] = 3
    return g


def halo(d: int) -> Grid:
    """Sovereign's Decree taunt halo (diameter `d`): a 2 px gold ring of crown points (a small
    spike every few px) with bright notches; the centre is open."""
    g = Grid(d, d)
    c = (d - 1) / 2.0
    r = d / 2.0 - 3.0
    n = max(16, int(math.tau * r))
    spikes = max(6, int(math.tau * r / 7.0))
    for i in range(n):
        a = math.tau * i / n
        for k, v in ((r, 3), (r - 1.0, 2)):
            g.put(c + math.cos(a) * k, c + math.sin(a) * k, v)
    for i in range(spikes):
        a = math.tau * i / spikes
        g.put(c + math.cos(a) * (r + 1.2), c + math.sin(a) * (r + 1.2), 3)
        g.put(c + math.cos(a) * (r + 2.2), c + math.sin(a) * (r + 2.2), 4)
    g.outline(0, "br")
    return g


def tide_edge(f: int) -> Grid:
    """Grave Tide edge mist tile (along x, depth y from the view edge at y = 0): a solid soul
    band at the edge, a rolling crest of wisps, then stray motes deeper in; 2 frames (it rolls)."""
    w, h = TIDE_CELL
    g = Grid(w, h)
    for x in range(w):
        crest = 9 + 3.0 * math.sin((x + f * 6) * math.tau / w) + 1.5 * math.sin((x * 2 + f * 9) * math.tau / w)
        for y in range(h):
            if y <= crest - 3:
                g.a[y, x] = 1
            elif y <= crest - 1:
                g.a[y, x] = 2
            elif y <= crest:
                g.a[y, x] = 3
    for i in range(3):
        x = (i * 8 + f * 3 + 2) % w
        y = 17 + i * 6 + f * 2
        g.put(x, y, 2)
        g.put(x + 1, y, 3)
        g.put(x, y + 1, 1)
    return g


# --------------------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------------------

def build(pal: dict) -> dict:
    """Builds every piece. Returns file id -> RGBA image."""
    out = {}
    for fid, (shape, ramp) in CRESTS.items():
        out[fid] = strip([CREST_SHAPES[shape](f) for f in range(CREST_FRAMES)], RAMPS[ramp], pal)
    for fid, ramp in MARKS.items():
        out[fid] = strip([mark(0), mark(1)], RAMPS[ramp], pal)
    for variant, ramp in (("plague", "plague_gas"), ("pest", "pest_gas")):
        for i, d in enumerate(PUFF_SIZES):
            g = puff(d, 7 + i * 3)
            g.clear_border()
            out["puff_%s_%d" % (variant, i)] = g.image(RAMPS[ramp], pal)
        out["wisp_%s" % variant] = strip([wisp(0), wisp(1)], RAMPS[ramp], pal)
    out["bubble_plague"] = strip([bubble(f) for f in range(MOTE_FRAMES)], RAMPS["plague"], pal)
    out["mote_soul"] = strip([mote(f) for f in range(MOTE_FRAMES)], RAMPS["soul"], pal)
    out["mote_plague"] = strip([mote(f) for f in range(MOTE_FRAMES)], RAMPS["plague"], pal)
    out["mote_violet"] = strip([mote(f) for f in range(MOTE_FRAMES)], RAMPS["violet"][1:], pal)
    out["rune_plague"] = strip([rune(0), rune(1)], RAMPS["plague"], pal)
    out["rune_soul"] = strip([rune(0), rune(1)], RAMPS["soul"], pal)
    for i, d in enumerate(CRACK_SIZES):
        g = crack(d, 3 + i, False)
        g.clear_border()
        out["crack_%d" % i] = g.image(RAMPS["earth"], pal)
        g = crack(d, 5 + i, True)
        g.clear_border()
        out["crack_soul_%d" % i] = g.image(RAMPS["soul"], pal)
    out["frost_star"] = strip([frost_star(f) for f in range(FLASH_FRAMES)], RAMPS["ice"], pal)
    for ramp in ("arcane", "wail", "violet", "soul"):
        out["flash_%s" % ramp] = strip([flash(f) for f in range(FLASH_FRAMES)], RAMPS[ramp], pal)
    for v in range(3):
        out["flame_%d" % v] = strip([flame(f, v) for f in range(FLAME_FRAMES)], RAMPS["flame"], pal)
    for i, d in enumerate(SCORCH_SIZES):
        g = scorch(d, 11 + i)
        g.clear_border()
        out["scorch_%d" % i] = g.image(RAMPS["scorch"], pal)
    for v in range(2):
        g = spike(v)
        out["spike_%d" % v] = multi(g, {0: "ink_warm", 1: "bone_shade", 2: "bone_mid", 3: "bone", 4: "soul"}, pal)
    out["lane_body"] = strip([lane_body(0), lane_body(1)], RAMPS["violet"], pal)
    g = lane_head()
    g.clear_border()
    out["lane_head"] = g.image(RAMPS["violet"], pal)
    g = streak()
    g.clear_border()
    out["dash_streak"] = g.image(RAMPS["violet"][0:3] + ["bone_mid", "bone"], pal)
    col = {0: "ink_green", 1: "soul_dark", 2: "soul", 3: "soul_glow", 5: "violet", 6: "violet_flare"}
    frames = [column(f) for f in range(COLUMN_FRAMES)]
    img = Image.new("RGBA", (COLUMN_CELL[0] * COLUMN_FRAMES, COLUMN_CELL[1]), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        fr.clear_border()
        img.paste(multi(fr, col, pal), (i * COLUMN_CELL[0], 0))
    out["transform_column"] = img
    g = black_sun()
    g.clear_border()
    out["black_sun"] = g.image(RAMPS["violet"], pal)
    for i, d in enumerate(HALO_SIZES):
        g = halo(d)
        g.clear_border()
        out["halo_%d" % i] = g.image(RAMPS["violet"], pal)
    out["tide_edge"] = strip([tide_edge(0), tide_edge(1)], RAMPS["soul"], pal)
    return out


def preview(pieces: dict, path: Path, pal: dict) -> None:
    """A contact sheet: every piece x4 nearest on the Graveyard soil, in rows."""
    zoom = 4
    pad = 6
    floor = pal["floor_soil"]
    ids = sorted(pieces)
    rows = []
    row, width = [], 0
    for fid in ids:
        im = pieces[fid]
        w = im.width * zoom + pad
        if width + w > 1600 and row:
            rows.append(row)
            row, width = [], 0
        row.append(fid)
        width += w
    rows.append(row)
    heights = [max(pieces[f].height for f in r) * zoom + pad for r in rows]
    sheet = Image.new("RGBA", (1600, sum(heights) + pad), floor)
    y = pad
    for r, hgt in zip(rows, heights):
        x = pad
        for fid in r:
            im = pieces[fid].resize((pieces[fid].width * zoom, pieces[fid].height * zoom), Image.NEAREST)
            sheet.alpha_composite(im, (x, y))
            x += im.width + pad
        y += hgt
    sheet.save(path)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(OUT_DIR), help="output folder")
    ap.add_argument("--preview", default="", help="also write a contact sheet PNG here")
    args = ap.parse_args()
    pal = palette()
    pieces = build(pal)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for fid, im in sorted(pieces.items()):
        im.save(out / (fid + ".png"))
    print("wrote %d pieces to %s" % (len(pieces), out))
    if args.preview:
        preview(pieces, Path(args.preview), pal)
        print("preview:", args.preview)


if __name__ == "__main__":
    main()
