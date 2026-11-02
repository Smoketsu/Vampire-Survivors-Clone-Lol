#!/usr/bin/env python3
"""city_tiles.py: draws Act VIII's city-block tiles and rooftop decals straight onto the art grid.

Why (Act VIII foundation, GDD 15.0 "Act VIII art: the shared kinds and the city blocks"): the Last Line's
maps are a grid of rectangular building blocks, straight streets and narrow alleys, seen strictly from above.
Hard rectilinear geometry (parapets, lane lines, crosswalk bars, paving joints) is what an AI source loses
when it is reduced to the grid, and every one of these must tile, so each piece is drawn here pixel by pixel
from palette colours (tools/palette.json), light from the top-left, with seeded noise only (a rerun
reproduces the files exactly).

Outputs (1 art px = 1 screen px):
  assets/sprites/tiles/city_roof_<style>.png    96 x 96 atlas of 3 x 3 cells of 32 px: row 0 = corner TL, edge
        top, corner TR; row 1 = edge left, CENTRE, edge right; row 2 = corner BL, edge bottom, corner BR.
        The centre tiles seamlessly in both axes and so do the edge cells along their length. A building
        of W x H px is drawn as the four corners, the edges stretched by repeating them along the
        sides, and the centre repeated inside. Styles: tenement, warehouse, bunker, tower.
  assets/sprites/tiles/city_street.png          64 x 192: asphalt, 64 along a horizontal street and the full 192 across, a dashed centre
        lane line in the middle (rotate 90 degrees for a vertical street); tiles along its length.
  assets/sprites/tiles/city_crosswalk.png       64 x 192: zebra bars across the street's full width (tiles along it; rotate for vertical).
  assets/sprites/tiles/city_sidewalk.png        64 x 32: paving with the kerb on its bottom edge (the street
        side); tiles along its length, rotate for the other sides.
  assets/sprites/tiles/city_alley.png           64 x 80: narrow-alley ground (64 along, 80 across), darker and grimier, no lines.
  assets/sprites/tiles/city_plaza.png           64 x 64: plaza paving (square slabs), tiles in both axes.
  assets/sprites/decals/city_<id>.png           rooftop details placed by code on the roofs: vent, ac_unit,
        water_tank, hatch, antenna (antenna keeps its red lamp unlit; the code pulses it).
Usage (from the repo root):  python3 tools/city_tiles.py [--out DIR]   (default: assets/sprites)
"""
import argparse
import random
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Palette colours used (the fixed Act VIII hexes of tools/palette.json), name -> (r, g, b).
C = {
    "ink": (0x10, 0x11, 0x14), "ad": (0x1E, 0x20, 0x24), "a": (0x3A, 0x3D, 0x44),
    "c": (0x55, 0x59, 0x5F), "cl": (0x7A, 0x7F, 0x87), "hz": (0xF2, 0xC4, 0x18),
    "ol": (0x6B, 0x75, 0x45), "od": (0x4B, 0x53, 0x30), "red": (0xD8, 0x2A, 0x2A),
    "bd": (0x7F, 0x78, 0x5F), "bm": (0xB4, 0xAA, 0x8A), "br": (0x5A, 0x3A, 0x20), "pb": (0x1F, 0x3F, 0x94),
}
# Roof styles: name -> (base colour, lit parapet colour, shade colour, noise colour, seed). The roof reads lighter
# than the street (concrete grey over asphalt), the four styles differ in tone and surface pattern.
STYLES = {
    "tenement": dict(base="c", lit="cl", shade="a", fleck="cl", seed=11, pattern="felt"),
    "warehouse": dict(base="a", lit="c", shade="ad", fleck="c", seed=23, pattern="ribs"),
    "bunker": dict(base="od", lit="ol", shade="ad", fleck="ol", seed=37, pattern="slab"),
    "tower": dict(base="c", lit="cl", shade="a", fleck="a", seed=41, pattern="grid"),
}
# Cell size (px) of the roof atlas and the parapet thickness (px) inside an edge cell.
CELL = 32
PARAPET = 6


def blank(w: int, h: int) -> Image.Image:
    """A transparent RGBA canvas of w x h px."""
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im: Image.Image, x: int, y: int, name: str) -> None:
    """Sets pixel (x, y) to palette colour `name` when inside the image."""
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), C[name] + (255,))


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, name: str) -> None:
    """Fills [x0, x1) x [y0, y1) with colour `name`."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            put(im, x, y, name)


def roof_centre(st: dict) -> Image.Image:
    """The 32 x 32 tileable roof surface: the base colour, seeded flecks and the style's pattern (periodic in 32)."""
    im = blank(CELL, CELL)
    rect(im, 0, 0, CELL, CELL, st["base"])
    rng = random.Random(st["seed"])
    for _ in range(26):
        put(im, rng.randrange(CELL), rng.randrange(CELL), st["fleck"])
    for _ in range(14):
        put(im, rng.randrange(CELL), rng.randrange(CELL), st["shade"])
    p = st["pattern"]
    if p == "ribs":  # Warehouse: long corrugated ribs (a darker row every 8 px).
        for y in range(0, CELL, 8):
            for x in range(CELL):
                put(im, x, y, st["shade"])
                put(im, x, y + 1, st["lit"]) if x % 2 == 0 else None
    elif p == "slab":  # Bunker: poured concrete slabs with a joint every 16 px.
        for i in range(0, CELL, 16):
            for t in range(CELL):
                put(im, i, t, st["shade"])
                put(im, t, i, st["shade"])
    elif p == "grid":  # Tower: a fine paving grid, a joint every 8 px.
        for i in range(0, CELL, 8):
            for t in range(CELL):
                put(im, i, t, st["shade"])
                put(im, t, i, st["shade"])
    elif p == "felt":  # Tenement: tar-paper strips, a seam every 16 px with a lit lip.
        for y in range(0, CELL, 16):
            for x in range(CELL):
                put(im, x, y, st["shade"])
                put(im, x, y + 1, st["lit"])
    return im


def roof_atlas(st: dict) -> Image.Image:
    """The 96 x 96 atlas: centre, four parapet edges and four corners (light from the top-left)."""
    at = blank(CELL * 3, CELL * 3)
    centre = roof_centre(st)
    for cy in range(3):
        for cx in range(3):
            at.paste(centre, (cx * CELL, cy * CELL))
    ink, lit, base, shade = "ink", st["lit"], st["base"], st["shade"]
    P = PARAPET
    n = CELL * 3
    # Parapet band, outside in: ink outline, lit wall top (P - 2 px), a shaded inner lip. Drawn the same on all four
    # sides, so each edge cell is uniform along its length and the cells tile.
    def band(k: int) -> str:
        return ink if k == 0 else (shade if k == P - 1 else lit)
    for t in range(n):
        for k in range(P):
            put(at, t, k, band(k))
            put(at, t, n - 1 - k, band(k))
            put(at, k, t, band(k))
            put(at, n - 1 - k, t, band(k))
    # The atlas is 3 cells wide, but only the outermost P px of the outer cells are parapet: the cells' inner
    # parts stay roof surface, so each outer cell is parapet on its outer side only and the centre is surface.
    # Re-paste the centre over the cell (1,1) and the inner stretch of the edge cells so edges repeat cleanly:
    # an edge cell's parapet band must not change along its length, so the band is redrawn uniformly below.
    for cy in range(3):
        for cx in range(3):
            if (cx, cy) == (1, 1):
                at.paste(centre, (CELL, CELL))
    # Draw a few rivets on the parapet top (periodic in 32 so edge cells tile).
    for i in range(0, n, 8):
        put(at, i + 3, 2, st["fleck"])
        put(at, i + 3, n - 3, st["fleck"])
        put(at, 2, i + 3, st["fleck"])
        put(at, n - 3, i + 3, st["fleck"])
    return at


def street_tile() -> Image.Image:
    """64 x 192 asphalt (64 along the street, 192 across, the street's full width) with a dashed centre lane line
    (rows 95-96; a dash every 32 px, 20 long) and a faint worn lane band on each side."""
    im = blank(64, 192)
    # The base is the dark asphalt (L 0.24), not the lighter one: riot and SWAT armour (the asphalt ramp's own shades) must
    # read against the street they fight on; the lighter asphalt is only speckle.
    rect(im, 0, 0, 64, 192, "ad")
    rng = random.Random(5)
    for _ in range(300):
        put(im, rng.randrange(64), rng.randrange(192), "a")
    for _ in range(90):
        put(im, rng.randrange(64), rng.randrange(192), "ink")
    for _ in range(40):
        put(im, rng.randrange(64), rng.randrange(192), "c")
    for dash in (0, 32):
        rect(im, dash + 6, 95, dash + 26, 97, "cl")
    for y in (4, 187):
        rect(im, 0, y, 64, y + 1, "ad")  # A faint edge line along each kerb.
    return im


def crosswalk_tile() -> Image.Image:
    """64 x 192 asphalt with zebra bars: vertical bars 8 px wide every 16 px across the street's width (tiles along it)."""
    im = blank(64, 192)
    rect(im, 0, 0, 64, 192, "ad")
    rng = random.Random(6)
    for _ in range(300):
        put(im, rng.randrange(64), rng.randrange(192), "a")
    for _ in range(90):
        put(im, rng.randrange(64), rng.randrange(192), "ink")
    for x0 in range(4, 64, 16):
        rect(im, x0, 10, x0 + 8, 182, "cl")
        rect(im, x0, 10, x0 + 8, 11, "c")  # Worn top edge.
        for _ in range(14):
            put(im, x0 + rng.randrange(8), 10 + rng.randrange(172), "c")
    return im


def sidewalk_tile() -> Image.Image:
    """64 x 32 pavement slabs (joints every 16 px) with the kerb (a lit line over an ink line) on the bottom edge."""
    im = blank(64, 32)
    rect(im, 0, 0, 64, 32, "c")
    rng = random.Random(7)
    for _ in range(40):
        put(im, rng.randrange(64), rng.randrange(28), "cl")
    for _ in range(30):
        put(im, rng.randrange(64), rng.randrange(28), "a")
    for x in range(0, 64, 16):
        rect(im, x, 0, x + 1, 26, "a")
    rect(im, 0, 12, 64, 13, "a")
    rect(im, 0, 26, 64, 28, "cl")
    rect(im, 0, 28, 64, 30, "ad")
    rect(im, 0, 30, 64, 32, "ink")
    return im


def alley_tile() -> Image.Image:
    """64 x 80 narrow-alley ground (64 along the alley, 80 across): dark grimy asphalt, a puddle and trash flecks, no lines."""
    im = blank(64, 80)
    rect(im, 0, 0, 64, 80, "ad")
    rng = random.Random(8)
    for _ in range(110):
        put(im, rng.randrange(64), rng.randrange(80), "a")
    for _ in range(36):
        put(im, rng.randrange(64), rng.randrange(80), "ink")
    for cx, cy in ((22, 30), (46, 58)):  # Puddles, well inside the tile (lit patches).
        rect(im, cx - 4, cy - 1, cx + 5, cy + 2, "c")
        rect(im, cx - 2, cy - 2, cx + 3, cy + 3, "c")
    for _ in range(8):
        put(im, rng.randrange(64), rng.randrange(80), "bd")
    return im


def plaza_tile() -> Image.Image:
    """64 x 64 plaza paving: 32 px square slabs with joints and a lit top-left bevel, tiles in both axes."""
    im = blank(64, 64)
    rect(im, 0, 0, 64, 64, "c")
    rng = random.Random(9)
    for _ in range(80):
        put(im, rng.randrange(64), rng.randrange(64), "cl")
    for _ in range(40):
        put(im, rng.randrange(64), rng.randrange(64), "a")
    for i in (0, 32):
        rect(im, i, 0, i + 1, 64, "a")
        rect(im, 0, i, 64, i + 1, "a")
        rect(im, i + 1, 1, i + 2, 64, "cl") if False else None
    for x0 in (1, 33):
        for y0 in (1, 33):
            rect(im, x0, y0, x0 + 30, y0 + 1, "cl")
            rect(im, x0, y0, x0 + 1, y0 + 30, "cl")
    return im


def decal(kind: str) -> Image.Image:
    """A rooftop detail seen from above with a 1 px ink outline: vent, ac_unit, water_tank, hatch or antenna."""
    if kind == "vent":  # 14 x 14 square vent with louvres.
        im = blank(14, 14)
        rect(im, 0, 0, 14, 14, "ink"); rect(im, 1, 1, 13, 13, "c"); rect(im, 1, 1, 13, 2, "cl")
        for y in range(4, 12, 2):
            rect(im, 3, y, 11, y + 1, "ad")
        return im
    if kind == "ac_unit":  # 24 x 18 air conditioner: a box with a round fan grille.
        im = blank(24, 18)
        rect(im, 0, 0, 24, 18, "ink"); rect(im, 1, 1, 23, 17, "cl"); rect(im, 1, 1, 23, 2, "cl"); rect(im, 1, 14, 23, 17, "c")
        for dy in range(-4, 5):
            for dx in range(-4, 5):
                d = dx * dx + dy * dy
                if d <= 16:
                    put(im, 9 + dx, 8 + dy, "ad" if d > 6 else "a")
        for k in range(-3, 4):
            put(im, 9 + k, 8, "c"); put(im, 9, 8 + k, "c")
        rect(im, 17, 4, 21, 6, "a"); rect(im, 17, 8, 21, 10, "a")
        return im
    if kind == "water_tank":  # 26 x 26 round rooftop tank: a lit lid, rust band, small hatch.
        im = blank(26, 26)
        for y in range(26):
            for x in range(26):
                d = (x - 12.5) ** 2 + (y - 12.5) ** 2
                if d <= 12.5 ** 2:
                    put(im, x, y, "ink")
                if d <= 11.5 ** 2:
                    put(im, x, y, "br" if d > 8.5 ** 2 else "bd")
                if d <= 8.5 ** 2:
                    put(im, x, y, "cl" if (x + y) < 22 else "c")
        rect(im, 10, 10, 15, 15, "a"); rect(im, 11, 11, 14, 14, "c")
        return im
    if kind == "hatch":  # 16 x 16 roof access hatch: a doored box with a handle.
        im = blank(16, 16)
        rect(im, 0, 0, 16, 16, "ink"); rect(im, 1, 1, 15, 15, "od"); rect(im, 1, 1, 15, 2, "ol"); rect(im, 1, 1, 2, 15, "ol")
        rect(im, 3, 3, 13, 13, "od"); rect(im, 3, 3, 13, 4, "ol"); rect(im, 7, 8, 11, 9, "hz")
        return im
    if kind == "antenna":  # 20 x 28 radio mast from above-front: a lattice tripod with an UNLIT red lamp on top.
        im = blank(20, 28)
        for y in range(4, 27):
            half = 1 + (y - 4) * 8 // 22
            put(im, 10 - half, y, "ink"); put(im, 10 + half, y, "ink")
            if (y - 4) % 5 == 0:
                for x in range(10 - half, 10 + half + 1):
                    put(im, x, y, "a")
        rect(im, 9, 4, 11, 27, "a")
        rect(im, 8, 24, 13, 28, "ink"); rect(im, 9, 25, 12, 28, "c")
        rect(im, 9, 0, 12, 4, "ink"); rect(im, 10, 1, 11, 3, "red")  # The unlit lamp (the code pulses a glow over it).
        return im
    raise ValueError(kind)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=str(ROOT / "assets" / "sprites"))
    out = Path(ap.parse_args().out)
    (out / "tiles").mkdir(parents=True, exist_ok=True)
    (out / "decals").mkdir(parents=True, exist_ok=True)
    for name, st in STYLES.items():
        roof_atlas(st).save(out / "tiles" / f"city_roof_{name}.png")
    street_tile().save(out / "tiles" / "city_street.png")
    crosswalk_tile().save(out / "tiles" / "city_crosswalk.png")
    sidewalk_tile().save(out / "tiles" / "city_sidewalk.png")
    alley_tile().save(out / "tiles" / "city_alley.png")
    plaza_tile().save(out / "tiles" / "city_plaza.png")
    for k in ("vent", "ac_unit", "water_tank", "hatch", "antenna"):
        decal(k).save(out / "decals" / f"city_{k}.png")
    print("written to", out)


if __name__ == "__main__":
    main()
