#!/usr/bin/env python3
"""skid_row_tiles.py: draws Skid Row's own city pieces straight onto the art grid (Act VIII, Stage 22; ART_BIBLE
"Act VIII: Skid Row").

Run from the repo root: python3 art_source/skid_row/skid_row_tiles.py. Deterministic (no API), built on
tools/city_tiles.py's helpers and palette so the pieces match the foundation's roofs and decals:
  assets/sprites/tiles/city_roof_precinct.png  96 x 96 roof atlas of 3 x 3 cells of 32 px (the Precinct's station roof:
                                               dark concrete slabs and a police-blue stripe inside the
                                               parapet)
  assets/sprites/decals/skid_row_stall.png     34 x 26 a Night Market stall seen from above: a striped awning in light
                                               grey (tinted pink or cyan by SkidRowGround), its frame and a lamp
  assets/sprites/decals/skid_row_footing.png   18 x 18 an overpass pillar's flat concrete footing plate with bolts and a
                                               hazard ring (flat paint: nothing on the floor may look solid)
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
sys.path.insert(0, str(ROOT / "tools"))
import city_tiles as ct  # noqa: E402  (the foundation's grid helpers and palette)

# The police blues of the City palette (tools/palette.json "police" ramp), added to the helpers' colour table.
ct.C.update({"pbm": (0x2E, 0x5F, 0xD0), "pbl": (0x5C, 0x8C, 0xEA), "w": (0xE6, 0xE6, 0xE2), "g1": (0xB4, 0xB8, 0xBE)})
# The precinct's roof style (keys as tools/city_tiles.py STYLES): dark concrete slabs.
PRECINCT = dict(base="a", lit="cl", shade="ad", fleck="c", seed=53, pattern="slab")


def precinct_roof():
    """The Precinct's roof atlas: the slab roof with a police-blue stripe inside the parapet."""
    at = ct.roof_atlas(PRECINCT)
    n = ct.CELL * 3
    p = ct.PARAPET
    # A police-blue stripe just inside the parapet, the same along every edge (so the edge cells repeat).
    for t in range(p, n - p):
        for k in (p, p + 1):
            ct.put(at, t, k, "pbm")
            ct.put(at, t, n - 1 - k, "pbm")
            ct.put(at, k, t, "pbm")
            ct.put(at, n - 1 - k, t, "pbm")
    return at


def stall():
    """A market stall from above: a grey-white striped awning (tinted by code), its dark frame and a hanging lamp."""
    im = ct.blank(34, 26)
    ct.rect(im, 0, 0, 34, 26, "ink")
    ct.rect(im, 1, 1, 33, 21, "g1")
    for x in range(1, 33, 6):  # Awning stripes.
        ct.rect(im, x, 1, x + 3, 21, "w")
    ct.rect(im, 1, 1, 33, 2, "w")  # The lit top edge.
    ct.rect(im, 1, 19, 33, 21, "cl")  # The awning's shaded front lip.
    for x in range(2, 33, 4):  # Its scalloped edge.
        ct.put(im, x, 21, "g1")
    ct.rect(im, 1, 21, 33, 25, "ad")  # The counter under it.
    ct.rect(im, 15, 22, 19, 25, "hz")  # The hanging lamp.
    return im


def footing():
    """An overpass pillar's footing: a flat concrete plate, four bolts and a painted hazard ring."""
    im = ct.blank(18, 18)
    for y in range(18):
        for x in range(18):
            d = (x - 8.5) ** 2 + (y - 8.5) ** 2
            if d <= 8.5 ** 2:
                ct.put(im, x, y, "ink")
            if d <= 7.5 ** 2:
                ct.put(im, x, y, "hz" if d > 5.5 ** 2 and (x + y) % 4 < 2 else ("ad" if d > 5.5 ** 2 else "c"))
            if d <= 4.5 ** 2:
                ct.put(im, x, y, "cl" if (x + y) < 16 else "c")
    for (x, y) in ((6, 6), (11, 6), (6, 11), (11, 11)):
        ct.put(im, x, y, "ad")
    return im


def main() -> None:
    out = ROOT / "assets" / "sprites"
    precinct_roof().save(out / "tiles" / "city_roof_precinct.png")
    stall().save(out / "decals" / "skid_row_stall.png")
    footing().save(out / "decals" / "skid_row_footing.png")
    print("written to", out)


if __name__ == "__main__":
    main()
