#!/usr/bin/env python3
"""ark_tiles.py: draws the Ark of the Concord's floors, obstacles, structures and the Harvester's ring on the art grid.

Why (Act IX phase 2, GDD 15.0 "The Ark of the Concord (Act IX phase 2)"): the mothership is made of plates, gratings, glass
and machines, all straight lines and flat panels that must tile without a seam and read at 1 art px = 1 screen px; an AI
source loses that when it is reduced to the grid (as the foundation's turf: tools/concord_tiles.py). Everything is drawn
here pixel by pixel from the Concord palette colours (tools/palette.json), light from the top-left, with seeded noise only
(a rerun reproduces the files exactly).

Outputs (assets/sprites/):
  tiles/ark_hangar.png     128 x 128, seamless: gunmetal deck plates (2 x 2 of 64 px), seams, rivets, a painted guide stripe.
  tiles/ark_vaults.png     128 x 128, seamless: a dark deck grating between two sunken specimen-tank lids (green glass).
  tiles/ark_reactor.png    128 x 128, seamless: a reactor grating, the plasma glow coming up between its bars.
  tiles/ark_bridge.png     128 x 128, seamless: starfield glass (seeded stars) under thin gunmetal ribs every 64 px.
  obstacles/ark_crate_s / _l (+ _v): gunmetal cargo crates with a hull-white band (footprint 40 / 56 x 18).
  obstacles/ark_console_s / _l (+ _v): dark consoles with green screens on top (footprint 40 / 56 x 16).
  obstacles/ark_pillar_s / _l: hull-white pillars with gunmetal bands and a plasma ring light (radius 12 / 16).
  structures/specimen_tank.png (40 high), specimen_tank_dead.png (22), reactor_vent.png (30), reactor_vent_dead.png (22),
      reap_emitter.png (46): the Ark's structures (ArkEnemyData).
  effects/ark_ring.png     64 x 64: one ring of the Harvester's throne as a GREY TINT MASK (white core, grey rim; the code
      tints it and squashes it into a tilted ellipse, ArkGlyphs.draw_throne()).
Usage (from the repo root):  python3 tools/ark_tiles.py [--out DIR]   (default: assets/sprites)
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Palette colours used (the hexes of tools/palette.json's Concord ramps), name -> (r, g, b).
C = {
    "ink": (0x07, 0x08, 0x0F), "gd": (0x1E, 0x24, 0x2C), "gm": (0x3A, 0x42, 0x4C), "gl": (0x5A, 0x64, 0x70),
    "hs": (0xAE, 0xB8, 0xC4), "hl": (0xE8, 0xEC, 0xF0), "pd": (0x1F, 0xA8, 0x4A), "p": (0x3C, 0xFF, 0x6A),
    "pk": (0x0E, 0x3A, 0x1E), "lu": (0xFF, 0xE9, 0xA0), "rust": (0x8E, 0x3A, 0x24), "rustd": (0x5A, 0x24, 0x18),
    "deck": (0x2C, 0x32, 0x3A), "deckd": (0x24, 0x29, 0x30), "void": (0x05, 0x06, 0x0B),
}
# Floor tile size (px), as every zone floor (make_tile.py's).
TILE = 128
# Seeds (one per output) so a rerun reproduces every file.
SEED_HANGAR, SEED_VAULTS, SEED_REACTOR, SEED_BRIDGE = 2701, 2702, 2703, 2704


def blank(w: int, h: int) -> Image.Image:
    """A transparent RGBA canvas of w x h px."""
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def fill(px, x0: int, y0: int, x1: int, y1: int, col: tuple) -> None:
    """Fills the rect [x0, x1) x [y0, y1) of the pixel access `px` with `col` (an RGB tuple)."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            px[x, y] = col + (255,)


def disc(px, cx: float, cy: float, r: float, col: tuple, w: int, h: int, wrap: bool = False) -> None:
    """Fills a disc of radius r at (cx, cy) with `col`; `wrap` tiles it across the w x h edges."""
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                xx, yy = (x % w, y % h) if wrap else (x, y)
                if 0 <= xx < w and 0 <= yy < h:
                    px[xx, yy] = col + (255,)


# =====================================================================================================================
# Floors
# =====================================================================================================================

def hangar() -> Image.Image:
    """Deck plates of 64 px with dark seams, a light top-left edge, rivets, a dim plasma guide stripe."""
    rng = random.Random(SEED_HANGAR)
    im = blank(TILE, TILE)
    px = im.load()
    fill(px, 0, 0, TILE, TILE, C["deck"])
    for py in (0, 64):
        for qx in (0, 64):
            for x in range(qx, qx + 64):
                px[x, py] = C["gd"] + (255,)
                px[x, py + 1] = C["gl"] + (255,)
            for y in range(py, py + 64):
                px[qx, y] = C["gd"] + (255,)
                px[qx + 1, y] = C["gl"] + (255,)
            for (rx, ry) in ((4, 4), (59, 4), (4, 59), (59, 59)):
                px[qx + rx, py + ry] = C["hs"] + (255,)
                px[qx + rx + 1, py + ry + 1] = C["gd"] + (255,)
    for _ in range(90):  # Scuffs.
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        px[x, y] = C["deckd"] + (255,)
    for x in range(0, TILE):  # The guide stripe (dim plasma, every other 6 px a gap).
        if (x // 6) % 2 == 0:
            for y in (96, 97):
                px[x, y] = C["pk"] + (255,)
    return im


def vaults() -> Image.Image:
    """A dark deck grating (lines every 8 px) between two sunken specimen-tank lids of green glass."""
    im = blank(TILE, TILE)
    px = im.load()
    fill(px, 0, 0, TILE, TILE, C["gd"])
    for y in range(0, TILE, 8):
        for x in range(TILE):
            px[x, y] = C["ink"] + (255,)
    for x in range(0, TILE, 32):
        for y in range(TILE):
            px[x, y] = C["deckd"] + (255,)
    for (cx, cy) in ((32, 36), (96, 100)):
        disc(px, cx, cy, 19, C["gm"], TILE, TILE, True)
        disc(px, cx, cy, 16, C["ink"], TILE, TILE, True)
        disc(px, cx, cy, 14, C["pk"], TILE, TILE, True)
        disc(px, cx - 4, cy - 4, 5, (0x16, 0x5A, 0x30), TILE, TILE, True)
        px[(cx - 6) % TILE, (cy - 6) % TILE] = C["pd"] + (255,)
    return im


def reactor() -> Image.Image:
    """A reactor grating: bars of 5 px with 3 px slots showing a dim plasma glow (brighter at seeded hot spots)."""
    rng = random.Random(SEED_REACTOR)
    hot = [(rng.uniform(0, TILE), rng.uniform(0, TILE)) for _ in range(4)]
    im = blank(TILE, TILE)
    px = im.load()
    for y in range(TILE):
        for x in range(TILE):
            if x % 8 < 5:
                px[x, y] = (C["gd"] if x % 8 > 0 else C["gm"]) + (255,)
            else:
                d = min(math.hypot(min(abs(x - hx), TILE - abs(x - hx)), min(abs(y - hy), TILE - abs(y - hy))) for hx, hy in hot)
                px[x, y] = (C["pd"] if d < 6 else (C["pk"] if d < 22 else (0x0A, 0x1E, 0x12))) + (255,)
    return im


def bridge() -> Image.Image:
    """Starfield glass under gunmetal ribs: near-black, seeded stars (a few bright), ribs every 64 px."""
    rng = random.Random(SEED_BRIDGE)
    im = blank(TILE, TILE)
    px = im.load()
    fill(px, 0, 0, TILE, TILE, C["void"])
    for _ in range(70):
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        px[x, y] = (C["hs"] if rng.random() < 0.7 else C["lu"]) + (255,)
    for _ in range(5):
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        px[x, y] = C["hl"] + (255,)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            px[(x + dx) % TILE, (y + dy) % TILE] = C["gl"] + (255,)
    for k in (0, 64):
        for i in range(TILE):
            for t, col in ((0, C["gd"]), (1, C["gm"])):
                px[i, (k + t) % TILE] = col + (255,)
                px[(k + t) % TILE, i] = col + (255,)
    return im


# =====================================================================================================================
# Obstacles and structures
# =====================================================================================================================

def box(w: int, d: int, face: int, top: tuple, side: tuple, band: tuple, screens: bool) -> Image.Image:
    """A box seen from the 3/4 view: a top face of w x d and a front face `face` px tall, a 1 px ink outline; `band` a
    stripe across the front (crates) and green screens on the top (consoles)."""
    im = blank(w, d + face)
    px = im.load()
    fill(px, 0, 0, w, d, top)
    fill(px, 0, d, w, d + face, side)
    for x in range(w):
        px[x, 1] = tuple(min(255, c + 24) for c in top) + (255,)  # Rim light.
        px[x, d] = C["ink"] + (255,)
    if band is not None:
        fill(px, 0, d + face // 2 - 1, w, d + face // 2 + 2, band)
    if screens:
        for sx in range(4, w - 6, 12):
            fill(px, sx, 3, min(sx + 8, w - 3), max(4, d - 3), C["pk"])
            fill(px, sx + 1, 4, min(sx + 4, w - 4), 5, C["pd"])
    for x in range(w):
        px[x, 0] = C["ink"] + (255,)
        px[x, d + face - 1] = C["ink"] + (255,)
    for y in range(d + face):
        px[0, y] = C["ink"] + (255,)
        px[w - 1, y] = C["ink"] + (255,)
    return im


def pillar(r: int, height: int) -> Image.Image:
    """A hull-white pillar of radius r: shaded column, gunmetal bands, a plasma ring light, an ink outline."""
    w = 2 * r + 2
    im = blank(w, height)
    px = im.load()
    for y in range(height):
        for x in range(1, w - 1):
            t = (x - 1) / max(1, w - 3)
            col = C["hl"] if t < 0.15 else (C["hs"] if t < 0.65 else C["gl"])
            if y % 22 in (0, 1):
                col = C["gm"]
            if y == height - 12 or y == height - 11:
                col = C["p"] if 0.2 < t < 0.8 else C["pd"]
            px[x, y] = col + (255,)
        px[0, y] = C["ink"] + (255,)
        px[w - 1, y] = C["ink"] + (255,)
    for x in range(w):
        px[x, 0] = C["ink"] + (255,)
        px[x, height - 1] = C["ink"] + (255,)
    return im


def specimen_tank(dead: bool) -> Image.Image:
    """A sealed tank of green fluid with a beast curled inside (40 high), or its shattered base and spilt fluid (22)."""
    if dead:
        im = blank(36, 22)
        px = im.load()
        for y in range(8, 22):
            for x in range(36):
                if ((x - 18) / 18.0) ** 2 + ((y - 15) / 7.0) ** 2 <= 1.0:
                    px[x, y] = (0x16, 0x5A, 0x30, 255)
        fill(px, 8, 12, 28, 18, C["gm"])
        fill(px, 8, 12, 28, 13, C["gl"])
        for (x, y, h) in ((10, 5, 7), (17, 3, 9), (24, 6, 6)):  # Broken glass shards.
            for k in range(h):
                px[x, y + k] = C["hs"] + (255,)
                px[x + 1, y + k] = C["gl"] + (255,)
        return im
    im = blank(26, 40)
    px = im.load()
    fill(px, 1, 32, 25, 39, C["gm"])  # Base.
    fill(px, 1, 32, 25, 33, C["gl"])
    fill(px, 3, 6, 23, 32, (0x10, 0x3E, 0x24))  # Fluid.
    fill(px, 3, 6, 5, 32, (0x1A, 0x5E, 0x36))  # Glass light on the left.
    disc(px, 13, 21, 6, C["rust"], 26, 40)  # The beast curled inside.
    disc(px, 11, 19, 3, C["rustd"], 26, 40)
    px[16, 18] = C["lu"] + (255,)
    fill(px, 2, 2, 24, 6, C["gm"])  # Cap.
    fill(px, 2, 2, 24, 3, C["hs"])
    for y in range(1, 40):
        px[1, y] = C["ink"] + (255,)
        px[24, y] = C["ink"] + (255,)
    for x in range(1, 25):
        px[x, 1] = C["ink"] + (255,)
        px[x, 39] = C["ink"] + (255,)
    for y in range(8, 30, 6):  # Bubbles.
        px[18, y] = C["pd"] + (255,)
    return im


def reactor_vent(dead: bool) -> Image.Image:
    """A round grated vent on a gunmetal collar with plasma below (30 high), or the same cracked and dark (22)."""
    h = 22 if dead else 30
    im = blank(32, h)
    px = im.load()
    top = h - 18
    fill(px, 2, top + 6, 30, h - 1, C["gm"])  # The collar's front.
    fill(px, 2, top + 6, 30, top + 7, C["gl"])
    for y in range(top - 2, top + 14):
        for x in range(32):
            if ((x - 16) / 15.0) ** 2 + ((y - (top + 6)) / 7.0) ** 2 <= 1.0:
                inner = ((x - 16) / 12.0) ** 2 + ((y - (top + 6)) / 5.0) ** 2 <= 1.0
                if inner:
                    col = (C["ink"] if dead else C["pd"]) if (x % 4) >= 2 else C["gd"]
                else:
                    col = C["gl"]
                px[x, y] = col + (255,)
    if dead:
        for k in range(10):
            px[8 + k, top + 2 + (k % 3)] = C["ink"] + (255,)
    else:
        pass  # The plasma breath above it is drawn by the code (ReactorVentKit).
    for x in range(2, 30):
        px[x, h - 1] = C["ink"] + (255,)
    return im


def reap_emitter() -> Image.Image:
    """A gunmetal pylon on a hull-white foot, a plasma lens at its top (46 high)."""
    im = blank(26, 46)
    px = im.load()
    fill(px, 1, 38, 25, 45, C["hs"])  # The foot.
    fill(px, 1, 38, 25, 39, C["hl"])
    fill(px, 8, 10, 18, 38, C["gm"])  # The column.
    fill(px, 8, 10, 10, 38, C["gl"])
    for y in range(14, 36, 6):
        fill(px, 8, y, 18, y + 1, C["gd"])
    disc(px, 13, 7, 6, C["gd"], 26, 46)
    disc(px, 13, 7, 4, C["pd"], 26, 46)
    disc(px, 12, 6, 2, C["p"], 26, 46)
    for y in range(46):
        for x in range(26):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < 26 and 0 <= yy < 46 and px[xx, yy][3] == 255 and px[xx, yy][:3] != C["ink"]:
                        px[x, y] = C["ink"] + (254,)
                        break
    for y in range(46):
        for x in range(26):
            if px[x, y][3] == 254:
                px[x, y] = C["ink"] + (255,)
    return im


def ring() -> Image.Image:
    """One ring of the Harvester's throne as a grey tint mask: a white core band with grey rims, 64 x 64."""
    im = blank(64, 64)
    px = im.load()
    for y in range(64):
        for x in range(64):
            d = math.hypot(x + 0.5 - 32, y + 0.5 - 32)
            if 26 <= d < 31:
                core = 27.5 <= d < 29.5
                v = 255 if core else 170
                px[x, y] = (v, v, v, 255)
    return im


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=str(ROOT / "assets" / "sprites"), help="output folder (default: assets/sprites)")
    a = ap.parse_args()
    out = Path(a.out)
    for sub in ("tiles", "obstacles", "structures", "effects"):
        (out / sub).mkdir(parents=True, exist_ok=True)
    for name, fn in (("hangar", hangar), ("vaults", vaults), ("reactor", reactor), ("bridge", bridge)):
        fn().save(out / "tiles" / ("ark_" + name + ".png"))
    for size, length in (("s", 40), ("l", 56)):
        for kind, depth, face, top, side, band, screens in (
                ("ark_crate", 18, 14, C["gl"], C["gm"], C["hs"], False),
                ("ark_console", 16, 10, C["gm"], C["gd"], None, True)):
            box(length, depth, face, top, side, band, screens).save(out / "obstacles" / ("%s_%s.png" % (kind, size)))
            box(depth, length, face, top, side, band, screens).save(out / "obstacles" / ("%s_%s_v.png" % (kind, size)))
    pillar(12, 60).save(out / "obstacles" / "ark_pillar_s.png")
    pillar(16, 72).save(out / "obstacles" / "ark_pillar_l.png")
    specimen_tank(False).save(out / "structures" / "specimen_tank.png")
    specimen_tank(True).save(out / "structures" / "specimen_tank_dead.png")
    reactor_vent(False).save(out / "structures" / "reactor_vent.png")
    reactor_vent(True).save(out / "structures" / "reactor_vent_dead.png")
    reap_emitter().save(out / "structures" / "reap_emitter.png")
    ring().save(out / "effects" / "ark_ring.png")
    print("wrote the Ark's floors, obstacles, structures and ring under", out)


if __name__ == "__main__":
    main()
