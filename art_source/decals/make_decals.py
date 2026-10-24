"""make_decals.py: builds the floor decals (assets/sprites/decals/) from the AI decal sheets.

Usage (from the repo root):
    python3 art_source/decals/make_decals.py                 # rebuild every decal (deterministic)
    python3 art_source/decals/make_decals.py <sheet> ...     # only the decals of these sheets
    python3 art_source/decals/make_decals.py --out DIR ...   # write candidates to DIR instead

Floor decals (docs/art/ART_BIBLE.md "Decals", GDD 15.0 "Floor decals") are small flat details
lying on the zone floor tiles, seen from straight above, with no outline, no rim light and no
cast shadow (nothing on the floor may look solid). Each source sheet in art_source/decals/sheets/
(generated through tools/gen_image.py with the zone floor tile x8 attached; its prompt beside it,
<sheet>.txt) holds several decals in a grid of equal cells. For each recipe below this script:
  1. cuts the decal's grid cell out of its sheet and crops it to the opaque pixels (alpha >= 128);
  2. downscales it to the recipe's height in art px (1 art px = 1 layout px; the width follows
     the aspect): each art pixel is one square block of the source, opaque when at least `cover`
     of the block is opaque (lower for thin things such as arrows), its colour the mean (OKLab)
     of the block's opaque pixels;
  3. colours every pixel from the recipe's own short colour list (palette names,
     tools/palette.json, floor shades included). An "accent" colour (embers, gold glints, iron)
     goes only where at least ACCENT_SHARE of the block's source pixels genuinely are that colour
     (nearest of all the recipe's colours and saturated), so a tiny ember in a dark block still
     shows. Every other pixel takes the nearest "base" colour, optionally after a levels stretch
     ("levels": the decal's own lightness range, LEVEL_PCT percentiles, mapped onto the base
     colours' range, for soft stains such as ash whose AI render sinks into one shade) and an
     optional lightness `shift` (negative keeps a loud cloth mostly in its darkest shade);
  4. cleans up: lone opaque pixels (no 4-neighbour) are removed and single-pixel colour islands
     take their neighbours' majority colour, accents excepted;
  5. optionally turns or flips it (`flip`: "h" or "v") and writes assets/sprites/decals/<key>.png,
     cropped tight on a transparent background.
The Sanctified Halls' carpet runner is built instead (BUILT, build_carpet(): a strip that
repeats left-right, so it is periodic by construction like the tile layouts of tools/make_tile.py).
Deterministic: the same sheets give the same PNGs. Requires Pillow and numpy.
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent  # art_source/decals/
ROOT = HERE.parent.parent  # Repo root.
sys.path.insert(0, str(ROOT / "tools"))
from pixel_palette import Palette, srgb_to_oklab  # noqa: E402

# Source sheets folder (one PNG and its prompt TXT per sheet).
SHEETS_DIR = HERE / "sheets"
# Output folder of the decal PNGs.
OUT_DIR = ROOT / "assets" / "sprites" / "decals"
# Default fraction (0..1) of a source block that must be opaque for its art pixel to be opaque.
COVER = 0.5
# Inset (source px) of each grid cell, so nothing of a neighbouring cell leaks in.
CELL_INSET = 6
# Minimum OKLab chroma of a source pixel to count as an accent pixel.
ACCENT_CHROMA = 0.04
# Share (0..1) of a block's opaque source pixels that must be accent pixels for the art pixel to
# take the accent.
ACCENT_SHARE = 0.2
# Percentiles (low, high) of the decal's base-pixel lightness mapped onto its base colours' range.
LEVEL_PCT = (5.0, 95.0)
# Weight of the a/b (hue) axes when snapping a base pixel (above 1 keeps hue over lightness).
CHROMA_WEIGHT = 1.5

# Sheet name -> (columns, rows) of its grid.
SHEETS = {
    "ash_fire": (3, 2),
    "wood": (3, 2),
    "camp": (3, 2),
    "banners": (3, 2),
    "grass": (3, 2),
    "graves": (2, 1),
    "courtyard": (3, 2),
    "halls_cloisters": (3, 2),
    # Gullhaven Harbour (Act II; the harbour placeholder art pass).
    "harbour_shore": (3, 2),
    "harbour_chapel": (3, 2),
}

# Decal key (assets/sprites/decals/<key>.png) -> recipe:
#   sheet / cell: the source sheet and its grid cell (row-major index);
#   h: height in art px; cover: opaque threshold (default COVER);
#   base: palette names the decal is built from; accent: palette names used only where the
#   source is genuinely that colour; levels: True for the lightness stretch; flip: "h" / "v";
#   rot: quarter turns counter-clockwise; shift: OKLab L added to the base pixels before
#   snapping (negative = darker, so a saturated cloth stays mostly in its darkest shade).
RECIPES = {
    # The Desecrated Graveyard.
    "graveyard_grass": {"sheet": "grass", "cell": 0, "h": 10, "cover": 0.35, "levels": True, "shift": -0.05,
                        "base": ["floor_grass", "floor_moss", "moss_dark"]},
    "graveyard_grass_2": {"sheet": "grass", "cell": 1, "h": 8, "cover": 0.35, "levels": True, "shift": -0.05,
                          "base": ["floor_grass", "floor_moss", "moss_dark"]},
    "graveyard_grass_3": {"sheet": "grass", "cell": 2, "h": 7, "cover": 0.35, "levels": True, "shift": -0.05,
                          "base": ["floor_grass", "floor_moss", "moss_dark"]},
    "graveyard_grave": {"sheet": "graves", "cell": 0, "h": 14,
                        "base": ["ink_cold", "floor_soil", "floor_earth", "grey_dark"]},
    "graveyard_grave_2": {"sheet": "graves", "cell": 1, "h": 13,
                          "base": ["ink_cold", "floor_soil", "floor_earth", "grey_dark"]},
    # March I, the Burned Road.
    "march_burned_ash": {"sheet": "ash_fire", "cell": 0, "h": 28, "levels": True,
                         "base": ["floor_earth", "floor_ash", "floor_stone"]},
    "march_burned_ash_2": {"sheet": "ash_fire", "cell": 1, "h": 20, "levels": True,
                           "base": ["floor_earth", "floor_ash", "floor_stone"]},
    "march_burned_stump": {"sheet": "ash_fire", "cell": 2, "h": 14, "levels": True,
                           "base": ["ink_warm", "floor_dirt", "brown"]},
    "march_burned_stump_2": {"sheet": "ash_fire", "cell": 3, "h": 12, "levels": True,
                             "base": ["ink_warm", "floor_dirt", "brown"]},
    "march_burned_embers": {"sheet": "ash_fire", "cell": 4, "h": 10,
                            "base": ["ink_warm", "floor_earth"], "accent": ["flame"]},
    "march_burned_embers_2": {"sheet": "ash_fire", "cell": 5, "h": 8,
                              "base": ["ink_warm", "floor_earth"], "accent": ["flame"]},
    "march_burned_plank": {"sheet": "wood", "cell": 2, "h": 7,
                           "base": ["ink_warm", "brown", "brown_light"]},
    "march_burned_plank_2": {"sheet": "wood", "cell": 3, "h": 7,
                             "base": ["ink_warm", "brown", "brown_light", "grey_dark"]},
    # The spent arrow: March I, and the odd arrow on the road in every March zone.
    "march_arrow": {"sheet": "wood", "cell": 0, "h": 11, "cover": 0.25,
                    "base": ["ink_warm", "brown", "bone_shade", "grey_dark"]},
    "march_arrow_2": {"sheet": "wood", "cell": 1, "h": 10, "cover": 0.25,
                      "base": ["ink_warm", "brown", "bone_shade", "grey_dark"]},
    # March II, the Fortified Checkpoint.
    "march_checkpoint_stakes": {"sheet": "wood", "cell": 4, "h": 12,
                                "base": ["ink_warm", "brown"], "accent": ["brown_light"]},
    "march_checkpoint_stakes_2": {"sheet": "wood", "cell": 5, "h": 12, "cover": 0.4,
                                  "base": ["ink_warm", "brown"], "accent": ["brown_light"]},
    "march_checkpoint_pennant": {"sheet": "banners", "cell": 0, "h": 9, "cover": 0.35,
                                 "base": ["ink_red", "crimson_dark", "ink_warm", "brown", "steel_dark"]},
    "march_checkpoint_pennant_2": {"sheet": "banners", "cell": 1, "h": 9, "cover": 0.35,
                                   "base": ["ink_red", "crimson_dark", "ink_warm", "brown"]},
    # March III, the Siege Camp.
    "march_camp_campfire": {"sheet": "camp", "cell": 0, "h": 16, "levels": True,
                            "base": ["ink_warm", "floor_earth", "floor_stone", "brown"], "accent": ["flame"]},
    "march_camp_campfire_2": {"sheet": "camp", "cell": 1, "h": 14, "levels": True,
                              "base": ["ink_warm", "floor_earth", "floor_stone", "brown"], "accent": ["flame"]},
    "march_camp_rope": {"sheet": "camp", "cell": 2, "h": 8, "cover": 0.3,
                        "base": ["ink_warm", "brown", "brown_light"]},
    "march_camp_rope_2": {"sheet": "camp", "cell": 2, "h": 8, "cover": 0.3, "flip": "h",
                          "base": ["ink_warm", "brown", "brown_light"]},
    "march_camp_crate": {"sheet": "camp", "cell": 4, "h": 15, "levels": True,
                         "base": ["ink_warm", "floor_earth", "brown"]},
    "march_camp_crate_2": {"sheet": "camp", "cell": 5, "h": 11, "levels": True,
                           "base": ["ink_warm", "floor_earth", "brown"]},
    # March IV, the Fortress Approach.
    "march_fortress_banner": {"sheet": "banners", "cell": 3, "h": 15, "shift": -0.03,
                              "base": ["ink_red", "crimson_dark", "ink_warm", "brown"], "accent": ["gold"]},
    "march_fortress_banner_2": {"sheet": "banners", "cell": 3, "h": 13, "shift": -0.03, "flip": "h",
                                "base": ["ink_red", "crimson_dark", "ink_warm", "brown"], "accent": ["gold"]},
    # Sanctum I, the Outer Courtyards.
    "sanctum_courtyard_moss": {"sheet": "courtyard", "cell": 0, "h": 14, "levels": True,
                               "base": ["floor_grass", "floor_moss", "moss_dark"]},
    "sanctum_courtyard_moss_2": {"sheet": "courtyard", "cell": 1, "h": 10, "levels": True,
                                 "base": ["floor_grass", "floor_moss", "moss_dark"]},
    "sanctum_courtyard_star": {"sheet": "courtyard", "cell": 2, "h": 19, "cover": 0.3, "shift": -0.12,
                               "base": ["floor_dirt", "brown", "brown_light"], "accent": ["gold"]},
    "sanctum_courtyard_star_2": {"sheet": "courtyard", "cell": 3, "h": 15, "cover": 0.3, "shift": -0.12,
                                 "base": ["floor_dirt", "brown", "brown_light"], "accent": ["gold"]},
    "sanctum_courtyard_petals": {"sheet": "courtyard", "cell": 4, "h": 9,
                                 "base": ["steel_dark", "bone_shade"]},
    "sanctum_courtyard_petals_2": {"sheet": "courtyard", "cell": 5, "h": 7,
                                   "base": ["steel_dark", "bone_shade"]},
    # Sanctum II, the Sanctified Halls.
    "sanctum_halls_rosette": {"sheet": "halls_cloisters", "cell": 0, "h": 32, "shift": -0.08,
                              "base": ["ink_warm", "floor_earth", "brown", "brown_light"], "accent": ["gold"]},
    "sanctum_halls_rosette_2": {"sheet": "halls_cloisters", "cell": 0, "h": 24, "shift": -0.08,
                                "base": ["ink_warm", "floor_earth", "brown", "brown_light"], "accent": ["gold"]},
    # Sanctum III, the Cloisters.
    "sanctum_cloisters_sundial": {"sheet": "halls_cloisters", "cell": 2, "h": 28, "cover": 0.3, "shift": -0.08,
                                  "base": ["ink_warm", "brown", "brown_light"]},
    "sanctum_cloisters_sundial_2": {"sheet": "halls_cloisters", "cell": 2, "h": 24, "cover": 0.3, "rot": 1, "shift": -0.08,
                                    "base": ["ink_warm", "brown", "brown_light"]},
    "sanctum_cloisters_flowers": {"sheet": "halls_cloisters", "cell": 4, "h": 12,
                                  "base": ["floor_grass", "floor_moss", "moss_dark"], "accent": ["bone_shade", "crimson_dark"]},
    "sanctum_cloisters_flowers_2": {"sheet": "halls_cloisters", "cell": 4, "h": 10, "flip": "h",
                                    "base": ["floor_grass", "floor_moss", "moss_dark"], "accent": ["bone_shade", "crimson_dark"]},
    "sanctum_cloisters_leaves": {"sheet": "halls_cloisters", "cell": 5, "h": 8, "shift": -0.08,
                                 "base": ["ink_warm", "brown", "brown_light"]},
    "sanctum_cloisters_leaves_2": {"sheet": "halls_cloisters", "cell": 5, "h": 7, "flip": "v", "shift": -0.08,
                                   "base": ["ink_warm", "brown", "brown_light"]},
    # Sanctum IV, the Final Sanctuary.
    "sanctum_sanctuary_inlay": {"sheet": "halls_cloisters", "cell": 3, "h": 18, "shift": -0.06,
                                "base": ["ink_warm", "floor_slate", "floor_marble", "brown", "brown_light"], "accent": ["gold"]},
    # Gullhaven Harbour (Act II), the Mudflats: shells and stranded kelp.
    "harbour_mudflats_shells": {"sheet": "harbour_shore", "cell": 0, "h": 8, "shift": -0.06,
                                "base": ["ink_warm", "steel_dark", "bone_shade"]},
    "harbour_mudflats_shells_2": {"sheet": "harbour_shore", "cell": 1, "h": 7, "shift": -0.06,
                                  "base": ["ink_warm", "steel_dark", "bone_shade"]},
    "harbour_mudflats_kelp": {"sheet": "harbour_shore", "cell": 2, "h": 8, "cover": 0.3, "shift": -0.03,
                              "base": ["ink_green", "floor_moss", "moss_dark"]},
    "harbour_mudflats_kelp_2": {"sheet": "harbour_shore", "cell": 2, "h": 7, "cover": 0.3, "shift": -0.03, "flip": "h",
                                "base": ["ink_green", "floor_moss", "moss_dark"]},
    # The Fish Market: fish scales, rope coils, a dropped fish.
    "harbour_market_fish": {"sheet": "harbour_shore", "cell": 3, "h": 7, "shift": -0.1,
                            "base": ["ink_drowned", "drowned_dark", "drowned"], "accent": ["bone_shade"]},
    "harbour_market_fish_2": {"sheet": "harbour_shore", "cell": 3, "h": 6, "shift": -0.1, "flip": "h",
                              "base": ["ink_drowned", "drowned_dark", "drowned"], "accent": ["bone_shade"]},
    "harbour_market_scales": {"sheet": "harbour_shore", "cell": 4, "h": 10, "cover": 0.4, "shift": -0.1,
                              "base": ["grey_dark", "grey"]},
    "harbour_market_scales_2": {"sheet": "harbour_shore", "cell": 4, "h": 8, "cover": 0.4, "shift": -0.1, "flip": "h",
                                "base": ["grey_dark", "grey"]},
    "harbour_market_rope": {"sheet": "harbour_shore", "cell": 5, "h": 16, "cover": 0.3, "shift": -0.08,
                            "base": ["ink_warm", "brown", "brown_light"]},
    "harbour_market_rope_2": {"sheet": "harbour_shore", "cell": 5, "h": 13, "cover": 0.3, "shift": -0.08, "flip": "h",
                              "base": ["ink_warm", "brown", "brown_light"]},
    # The Chapel of the Deep: coral crust, barnacles, the Eye's carved sigil.
    "harbour_chapel_coral": {"sheet": "harbour_chapel", "cell": 0, "h": 15, "levels": True, "shift": -0.04,
                             "base": ["ink_biolume", "biolume_dark"]},
    "harbour_chapel_coral_2": {"sheet": "harbour_chapel", "cell": 0, "h": 11, "levels": True, "shift": -0.04, "flip": "h",
                               "base": ["ink_biolume", "biolume_dark"]},
    "harbour_chapel_barnacles": {"sheet": "harbour_chapel", "cell": 1, "h": 11, "shift": -0.08,
                                 "base": ["ink_cold", "grey_dark", "grey"]},
    "harbour_chapel_barnacles_2": {"sheet": "harbour_chapel", "cell": 1, "h": 9, "shift": -0.08, "flip": "h",
                                   "base": ["ink_cold", "grey_dark", "grey"]},
    "harbour_chapel_sigil": {"sheet": "harbour_chapel", "cell": 2, "h": 24, "cover": 0.3,
                             "base": ["ink_cold", "grey_dark"], "accent": ["biolume"]},
    # The Seawall: mooring rings, rusted chain, gull feathers.
    "harbour_seawall_ring": {"sheet": "harbour_chapel", "cell": 3, "h": 12, "cover": 0.3, "shift": -0.06,
                             "base": ["ink_warm", "brown", "brown_light"]},
    "harbour_seawall_chain": {"sheet": "harbour_chapel", "cell": 4, "h": 11, "cover": 0.4, "shift": -0.06,
                              "base": ["ink_warm", "brown", "brown_light"]},
    "harbour_seawall_chain_2": {"sheet": "harbour_chapel", "cell": 4, "h": 10, "cover": 0.4, "shift": -0.06, "flip": "h",
                                "base": ["ink_warm", "brown", "brown_light"]},
    "harbour_seawall_feather": {"sheet": "harbour_chapel", "cell": 5, "h": 5, "cover": 0.3, "shift": -0.1,
                                "base": ["grey_dark", "grey", "grey_light"]},
    "harbour_seawall_feather_2": {"sheet": "harbour_chapel", "cell": 5, "h": 5, "cover": 0.3, "shift": -0.1, "flip": "h",
                                  "base": ["grey_dark", "grey", "grey_light"]},
}


# Built decals (no sheet): key -> function returning an index array (-1 = transparent).
# The Sanctified Halls' carpet runner is a strip that repeats left-right along a whole cell row,
# so it is laid out by construction (periodic, like the tiles' layouts in tools/make_tile.py).
CARPET_W = 128  # Strip piece width (art px): one decoration cell, repeating left-right.
CARPET_H = 36  # Strip height (art px): the code runner's width.
CARPET_MOTIF = 32  # Motif period along the strip (art px); CARPET_W is a multiple of it.


def build_carpet(pal: Palette) -> np.ndarray:
    """The crimson carpet runner of the Sanctified Halls, CARPET_W x CARPET_H, seamless left-right:
    a dark-red field (ink_red) between two dull-gold borders (brown with a brown_light line), a
    small crimson_dark diamond every CARPET_MOTIF px with a brown_light centre, and dark worn
    pixels along the field edge."""
    c = {n: pal.index_of[n] for n in ("ink_warm", "ink_red", "crimson_dark", "brown", "brown_light")}
    idx = np.full((CARPET_H, CARPET_W), c["ink_red"], int)
    for y in (0, CARPET_H - 1):
        idx[y, :] = c["ink_warm"]  # Outer edge of the borders.
    for y in (1, 2, CARPET_H - 3, CARPET_H - 2):
        idx[y, :] = c["brown"]  # Dull-gold border band.
    for y in (2, CARPET_H - 3):
        idx[y, ::4] = c["brown_light"]  # Border stitching.
    for y in (3, CARPET_H - 4):
        idx[y, :] = c["ink_warm"]  # Inner line of the borders.
    mid = CARPET_H // 2  # Centre row of the field.
    for x0 in range(0, CARPET_W, CARPET_MOTIF):
        cx = x0 + CARPET_MOTIF // 2  # Motif centre column.
        for d in range(7):  # Diamond outline, radius 6.
            for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
                idx[mid + sy * (6 - d), cx + sx * d] = c["crimson_dark"]
        idx[mid, cx] = c["brown_light"]  # Centre stud.
        for dx in (-1, 1):
            idx[mid, cx + dx] = c["brown"]
        idx[mid - 1, cx] = c["brown"]
        idx[mid + 1, cx] = c["brown"]
        # Small side marks between the diamonds, near the borders.
        idx[6, x0] = c["crimson_dark"]
        idx[CARPET_H - 7, x0] = c["crimson_dark"]
    return idx


BUILT = {
    "sanctum_halls_carpet": build_carpet,
}


def cut_cell(sheet: str, cell: int) -> np.ndarray:
    """RGBA array of grid cell `cell` of sheet `sheet`, cropped to its opaque pixels."""
    cols, rows = SHEETS[sheet]
    im = np.asarray(Image.open(SHEETS_DIR / f"{sheet}.png").convert("RGBA"))
    ch, cw = im.shape[0] // rows, im.shape[1] // cols  # Cell size (source px).
    cx, cy = cell % cols, cell // cols
    c = im[cy * ch + CELL_INSET:(cy + 1) * ch - CELL_INSET, cx * cw + CELL_INSET:(cx + 1) * cw - CELL_INSET]
    ys, xs = np.nonzero(c[..., 3] >= 128)
    if len(ys) == 0:
        sys.exit(f"{sheet} cell {cell}: empty")
    return c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def downscale(pal: Palette, rgba: np.ndarray, recipe: dict) -> tuple:
    """(index HxW int, -1 = transparent; accent HxW bool) of `rgba` scaled to the recipe's
    height (steps 2 and 3 of the header)."""
    h = recipe["h"]
    cover = recipe.get("cover", COVER)
    base = [pal.index_of[n] for n in recipe["base"]]
    accent = [pal.index_of[n] for n in recipe.get("accent", [])]
    sh, sw = rgba.shape[:2]
    scale = sh / h  # Source px per art px.
    w = max(1, int(round(sw / scale)))  # Width (art px).
    lab_src = srgb_to_oklab(rgba[..., :3])
    opaque = rgba[..., 3] >= 128
    # Accent pixels of the source: the nearest recipe colour is an accent, and it is saturated.
    src_acc = np.full(opaque.shape, -1, int)
    if accent:
        near = pal.snap(lab_src, base + accent, 2.0)
        chroma = np.hypot(lab_src[..., 1], lab_src[..., 2])
        hit = opaque & np.isin(near, accent) & (chroma >= ACCENT_CHROMA)
        src_acc[hit] = near[hit]
    mask = np.zeros((h, w), bool)
    lab = np.zeros((h, w, 3))
    acc = np.full((h, w), -1, int)
    for y in range(h):
        y0 = int(round(y * scale))
        y1 = max(int(round((y + 1) * scale)), y0 + 1)
        for x in range(w):
            x0 = int(round(x * scale))
            x1 = max(int(round((x + 1) * scale)), x0 + 1)
            block = opaque[y0:y1, x0:x1]
            if not block.size or block.mean() < cover:
                continue
            mask[y, x] = True
            lab[y, x] = lab_src[y0:y1, x0:x1][block].mean(0)
            a = src_acc[y0:y1, x0:x1][block]
            a = a[a >= 0]
            if len(a) and len(a) >= ACCENT_SHARE * block.sum():
                vals, counts = np.unique(a, return_counts=True)
                acc[y, x] = int(vals[counts.argmax()])
    idx = np.full((h, w), -1, int)
    sel = mask & (acc < 0)  # Base pixels.
    pts = lab[sel]
    if len(pts):
        adj = pts.copy()
        if recipe.get("levels", False) and len(pts) > 1:
            lo, hi = np.percentile(pts[:, 0], LEVEL_PCT)
            bl = pal.lab[base, 0]
            t = np.clip((pts[:, 0] - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
            adj[:, 0] = bl.min() + t * (bl.max() - bl.min())
        adj[:, 0] += float(recipe.get("shift", 0.0))
        idx[sel] = pal.snap(adj, base, CHROMA_WEIGHT)
    idx[acc >= 0] = acc[acc >= 0]
    return idx, acc >= 0


def cleanup(idx: np.ndarray, acc: np.ndarray) -> np.ndarray:
    """Removes lone opaque pixels and merges single-pixel colour islands (accents kept)."""
    h, w = idx.shape
    out = idx.copy()
    for y in range(h):
        for x in range(w):
            if idx[y, x] < 0 or acc[y, x]:
                continue
            nb = [idx[y + dy, x + dx] for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))
                  if 0 <= y + dy < h and 0 <= x + dx < w and idx[y + dy, x + dx] >= 0]
            if not nb:
                out[y, x] = -1
            elif idx[y, x] not in nb and len(nb) >= 3:
                vals, counts = np.unique(nb, return_counts=True)
                out[y, x] = int(vals[counts.argmax()])
    return out


def write(idx: np.ndarray, path: Path, pal: Palette) -> None:
    """Writes palette index array `idx` (-1 = transparent) as an RGBA PNG."""
    img = np.zeros(idx.shape + (4,), np.uint8)
    img[idx >= 0, :3] = pal.rgb[idx[idx >= 0]]
    img[idx >= 0, 3] = 255
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(img, "RGBA").save(path)


def build(key: str, out_dir: Path, pal: Palette) -> Path:
    """Builds decal `key` into out_dir/<key>.png; returns the path."""
    if key in BUILT:
        path = out_dir / f"{key}.png"
        write(BUILT[key](pal), path, pal)
        return path
    r = RECIPES[key]
    idx, acc = downscale(pal, cut_cell(r["sheet"], r["cell"]), r)
    idx = cleanup(idx, acc)
    ys, xs = np.nonzero(idx >= 0)
    idx = idx[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    idx = np.rot90(idx, int(r.get("rot", 0)))
    if r.get("flip") == "h":
        idx = idx[:, ::-1]
    elif r.get("flip") == "v":
        idx = idx[::-1, :]
    path = out_dir / f"{key}.png"
    write(idx, path, pal)
    return path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sheets", nargs="*", help="only the decals of these sheets")
    ap.add_argument("--out", default="", help="write here instead of assets/sprites/decals/")
    args = ap.parse_args()
    pal = Palette()
    out_dir = Path(args.out) if args.out else OUT_DIR
    for key in list(RECIPES) + list(BUILT):
        if args.sheets and RECIPES.get(key, {}).get("sheet", "built") not in args.sheets:
            continue
        im = Image.open(build(key, out_dir, pal))
        print(f"{key}: {im.width}x{im.height}")


if __name__ == "__main__":
    main()
