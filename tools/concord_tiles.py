#!/usr/bin/env python3
"""concord_tiles.py: draws Act IX's alien ground, beam strips and the mothership eye on the art grid.

Why (Act IX foundation, GDD 15.0 "Act IX art: the shared kinds and the turf"): Terraforming spreads patches of alien
flesh ground over the arena in 64 px cells, so every piece must tile and meet its neighbours without a seam, and the
beams are drawn as tinted tiling strips; an AI source loses all of that when it is reduced to the grid. Everything is
drawn here pixel by pixel from the Concord palette colours (tools/palette.json), light from the top-left, with seeded
noise only (a rerun reproduces the files exactly).

Outputs (1 art px = 1 screen px; assets/sprites/):
  tiles/concord_turf.png      192 x 192 atlas of 3 x 3 cells of 64 px, like the city roofs: row 0 = corner TL, edge top,
        corner TR; row 1 = edge left, CENTRE, edge right; row 2 = corner BL, edge bottom, corner BR. The centre is veined
        purple flesh (green veins = the cell borders of a wrapped Voronoi map, a few spores) and tiles seamlessly in both
        axes; the edge cells carry the same surface with a ragged, darker border toward the outside (transparent beyond it),
        so a patch has a soft edge; the edge cells tile along their length. A live cell with no live neighbour on a side
        takes that side's edge piece.
  tiles/concord_scorch.png    64 x 64 burnt ground (ink black, dark turf, a few dull embers): seamless in both axes; drawn
        over a turf cell the spell burnt.
  effects/beam_line.png       4 frames of 64 x 16 (256 x 16): a beam body along +x as a GREY TINT MASK (white core, light
        grey body, dark grey rim, an even flow of brighter bands that moves 16 px a frame), tiling along its length; the
        code tints it laser magenta (ConcordRulesData).
  effects/beam_hit.png        6 frames of 64 x 64 (384 x 64): an impact burst as a grey tint mask (a flash, an expanding
        ring, sparks), like volley_hit.
  concord/mothership_eye.png  192 x 192: the eye of the mothership seen from below (the API source art_source/concord/
        mothership_eye.png reduced to the grid and snapped to the Concord colours), round, transparent corners.
Usage (from the repo root):  python3 tools/concord_tiles.py [--out DIR]   (default: assets/sprites)
"""
import argparse
import math
import random
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Palette colours used (the hexes of tools/palette.json), name -> (r, g, b).
C = {
    "ink": (0x07, 0x08, 0x0F), "td": (0x1A, 0x1C, 0x22), "t": (0x5A, 0x2A, 0x6A), "tl": (0x7E, 0x4A, 0x90),
    "pd": (0x1F, 0xA8, 0x4A), "p": (0x3C, 0xFF, 0x6A), "hl": (0xE8, 0xEC, 0xF0), "hs": (0xAE, 0xB8, 0xC4),
    "gm": (0x3A, 0x42, 0x4C), "gd": (0x1E, 0x24, 0x2C), "lm": (0xFF, 0x2F, 0xB8), "ld": (0xA0, 0x1C, 0x7A),
}
# Cell size (px) of the turf atlas and of the scorch tile.
CELL = 64
# Seed points of the wrapped Voronoi map the turf veins follow (the cell borders), per 64 px tile.
VEIN_POINTS = 9
# Seeds (one per output) so a rerun reproduces every file.
SEED_TURF, SEED_SCORCH = 5, 9


def blank(w: int, h: int) -> Image.Image:
    """A transparent RGBA canvas of w x h px."""
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def turf_centre() -> Image.Image:
    """The 64 x 64 seamless turf surface: flesh base, light ridges, seeded flecks, green veins on the Voronoi borders."""
    rng = random.Random(SEED_TURF)
    pts = [(rng.uniform(0, CELL), rng.uniform(0, CELL)) for _ in range(VEIN_POINTS)]
    im = blank(CELL, CELL)
    px = im.load()

    def nearest(x: int, y: int) -> tuple:
        """(distance to the nearest seed, distance to the second nearest) with wrap-around."""
        d = []
        for (sx, sy) in pts:
            dx = min(abs(x - sx), CELL - abs(x - sx))
            dy = min(abs(y - sy), CELL - abs(y - sy))
            d.append(math.hypot(dx, dy))
        d.sort()
        return d[0], d[1]

    for y in range(CELL):
        for x in range(CELL):
            d1, d2 = nearest(x, y)
            gap = d2 - d1
            if gap < 1.1:
                col = "pd"  # Vein.
            elif gap < 1.8:
                col = "td"  # Shaded flesh beside the vein.
            else:
                col = "t"
            px[x, y] = C[col] + (255,)
    for _ in range(220):  # Flecks: lit ridges and dark pits, seeded.
        x, y = rng.randrange(CELL), rng.randrange(CELL)
        if px[x, y][:3] == C["t"]:
            px[x, y] = C[rng.choice(["tl", "tl", "td"])] + (255,)
    for _ in range(9):  # Spores: a bright pixel with a dim neighbour on the flesh.
        x, y = rng.randrange(1, CELL - 1), rng.randrange(1, CELL - 1)
        if px[x, y][:3] in (C["t"], C["tl"], C["td"]):
            px[x, y] = C["p"] + (255,)
            px[x + 1, y] = C["pd"] + (255,)
    for y in range(CELL):  # Vein junction glints: a vein pixel with three vein neighbours turns bright.
        for x in range(CELL):
            if px[x, y][:3] == C["pd"]:
                n = sum(px[(x + dx) % CELL, (y + dy) % CELL][:3] == C["pd"] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if n >= 3:
                    px[x, y] = C["p"] + (255,)
    return im


def turf_atlas() -> Image.Image:
    """The 192 x 192 atlas: the centre in the middle, edges and corners cut from the same surface with a ragged border."""
    centre = turf_centre()
    atlas = blank(CELL * 3, CELL * 3)
    rng = random.Random(SEED_TURF + 1)
    depth = [5 + rng.randrange(0, 7) for _ in range(CELL)]  # Border depth per position along an edge (periodic: wraps).
    for i in range(CELL):  # Smooth it so the border is a lumpy line, not a comb.
        depth[i] = round((depth[i] + depth[(i + 1) % CELL] + depth[(i - 1) % CELL]) / 3)
    for cy in range(3):
        for cx in range(3):
            cell = blank(CELL, CELL)
            cp, sp = cell.load(), centre.load()
            for y in range(CELL):
                for x in range(CELL):
                    # Distance in from each outside edge this cell has (a side on the patch's outline).
                    gaps = []
                    if cx == 0:
                        gaps.append(x - depth[y])
                    if cx == 2:
                        gaps.append((CELL - 1 - x) - depth[y])
                    if cy == 0:
                        gaps.append(y - depth[x])
                    if cy == 2:
                        gaps.append((CELL - 1 - y) - depth[x])
                    g = min(gaps) if gaps else 99
                    if g < 0:
                        continue  # Outside the patch.
                    col = sp[x, y]
                    if g == 0:
                        col = C["ink"] + (255,)  # Outline.
                    elif g <= 2:
                        col = C["td"] + (255,)  # Shaded rim, so the patch lifts off the ground.
                    cp[x, y] = col
            atlas.paste(cell, (cx * CELL, cy * CELL))
    return atlas


def scorch_tile() -> Image.Image:
    """The 64 x 64 seamless burnt tile: dark turf, ink soot patches and a few dull embers."""
    rng = random.Random(SEED_SCORCH)
    im = blank(CELL, CELL)
    px = im.load()
    for y in range(CELL):
        for x in range(CELL):
            px[x, y] = C["td"] + (255,)
    for _ in range(40):  # Soot blobs (wrapped).
        cx, cy, r = rng.randrange(CELL), rng.randrange(CELL), rng.randrange(2, 5)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    px[(cx + dx) % CELL, (cy + dy) % CELL] = C["ink"] + (255,)
    for _ in range(60):  # Ash flecks.
        px[rng.randrange(CELL), rng.randrange(CELL)] = C["gd"] + (255,)
    for _ in range(14):  # Dull embers.
        px[rng.randrange(CELL), rng.randrange(CELL)] = C["t"] + (255,)
    return im


def beam_line() -> Image.Image:
    """4 frames of 64 x 16: a grey tint-mask beam along +x; bright bands flow 16 px a frame (the strip loops)."""
    strip = blank(64 * 4, 16)
    px = strip.load()
    for f in range(4):
        for x in range(64):
            band = ((x - 16 * f) % 64) < 20  # A brighter run 20 px long in every 64 px.
            for y in range(16):
                d = abs(y - 7.5)
                if d <= 1.5:
                    col = "hl"  # Core.
                elif d <= 4.5:
                    col = "hl" if band else "hs"
                elif d <= 6.5:
                    col = "hs" if band else "gm"
                else:
                    col = "gm" if band else "gd"  # Rim.
                if d > 7:
                    continue
                px[f * 64 + x, y] = C[col] + (255,)
    return strip


def beam_hit() -> Image.Image:
    """6 frames of 64 x 64: an impact burst as a grey tint mask: a flash, a ring that grows and thins, sparks."""
    strip = blank(64 * 6, 64)
    px = strip.load()
    rng = random.Random(21)
    spark_angles = [rng.uniform(0, 2 * math.pi) for _ in range(9)]
    for f in range(6):
        ox = f * 64 + 32
        r_ring = 5 + 5 * f
        thick = max(1.0, 3.2 - 0.5 * f)
        flash = 9 - 2 * f
        for y in range(64):
            for x in range(64):
                d = math.hypot(x - 32 + 0.5, y - 32 + 0.5)
                col = None
                if d <= flash:
                    col = "hl"
                elif abs(d - r_ring) <= thick / 2 + 0.3:
                    col = "hs" if f < 4 else "gm"
                if col:
                    px[f * 64 + x, y] = C[col] + (255,)
        for a in spark_angles:  # Sparks fly outward past the ring and fade to the dark grey.
            r = r_ring + 3 + 2.5 * f
            for k in range(2):
                sx = int(round(32 + math.cos(a) * (r + k)))
                sy = int(round(32 + math.sin(a) * (r + k)))
                if 0 <= sx < 64 and 0 <= sy < 64 and f < 5:
                    px[f * 64 + sx, sy] = C["hl" if f < 3 else "hs"] + (255,)
    return strip


def mothership_eye(src: Path) -> Image.Image:
    """The API source reduced to 192 x 192 art px, every pixel snapped to the nearest Concord colour, corners transparent."""
    palette = [C[k] for k in ("ink", "hl", "hs", "gm", "gd", "p", "pd", "lm", "ld")]
    im = Image.open(src).convert("RGB").resize((192, 192), Image.BOX)
    out = blank(192, 192)
    px, ip = out.load(), im.load()
    for y in range(192):
        for x in range(192):
            if math.hypot(x - 95.5, y - 95.5) > 94:
                continue  # Outside the hull disc: transparent (the code fades the whole texture, no screen read).
            r, g, b = ip[x, y]
            best = min(palette, key=lambda c: (c[0] - r) ** 2 + (c[1] - g) ** 2 + (c[2] - b) ** 2)
            px[x, y] = best + (255,)
    return out


def main() -> None:
    """Writes every output under --out."""
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "assets" / "sprites"))
    out = Path(ap.parse_args().out)
    (out / "tiles").mkdir(parents=True, exist_ok=True)
    (out / "effects").mkdir(parents=True, exist_ok=True)
    (out / "concord").mkdir(parents=True, exist_ok=True)
    turf_atlas().save(out / "tiles" / "concord_turf.png")
    scorch_tile().save(out / "tiles" / "concord_scorch.png")
    beam_line().save(out / "effects" / "beam_line.png")
    beam_hit().save(out / "effects" / "beam_hit.png")
    src = ROOT / "art_source" / "concord" / "mothership_eye.png"
    if src.exists():
        mothership_eye(src).save(out / "concord" / "mothership_eye.png")
    print("wrote concord tiles, scorch, beam strips and the eye to", out)


if __name__ == "__main__":
    main()
