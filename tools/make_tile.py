"""make_tile.py: seamless zone floor tiles and the March road strip for the art pass.

Usage (from the repo root):
    python3 tools/make_tile.py build <name> [<name> ...]   rebuild tiles from RECIPES
    python3 tools/make_tile.py build --all                 rebuild every recipe
    python3 tools/make_tile.py sheet <name> [--out PNG]    3x3 repeat / variant mix check sheet
    python3 tools/make_tile.py sheet --all [--out-dir DIR]

<name> is a RECIPES key: a zone tile (e.g. march_burned, whose variants _2 / _3
are built with it) or a road strip (march_road, march_road_fortress). The AI
sources live in art_source/tiles/ (Godot ignores art_source/); the game tiles
are written to assets/sprites/tiles/<name>.png (EnvironmentArtData key scheme,
docs/art/ART_BIBLE.md "Environments" -> "Zone floors"). Every number that
shapes a tile is in its recipe, so a rebuild is exact and deterministic.

Why a separate tool (prepare_sprite.py is for sprites): an AI image is never
seamless, a floor must be, and its variants must share the base tile's edges so
any cell can sit next to any other. The pipeline:

 1. Source -> grid. The AI image is composited over its own median colour (the
    generator asks for a transparent background, a texture has none), cropped
    to `box` (fractions of the image; the default drops a CROP margin on every
    side, where AI images often fade), and box-filtered down to the tile grid
    plus the quilting overlap (1 art px = 1 screen px; the prompts ask for
    ~160 px of pixel art, so the reduction is ~6.5 source px per art px).
 2. Flatten. Light falloff and vignettes would make every repeat a visible
    block: the OKLab lightness minus a wide Gaussian blur of itself (sigma
    `flatten` art px, wrap or reflect at the borders), plus its mean, keeps the
    details and removes the gradients. `flatten_axis` "x" only flattens along
    the strip (the road keeps its darker verges).
 3. Normalise. The source's lightness percentiles PCT_LO..PCT_HI are stretched
    over the target colours' lightness range (`l_range`, default the darkest
    to the lightest allowed colour), and its a/b (hue) cloud is moved onto the
    allowed colours' centre and scaled to their spread (at most HUE_GAIN_MAX):
    the AI's brighter, greyer or more saturated render lands on the floor's
    narrow, dark band whatever its exposure, and its relative hues (greener
    grass, browner mud) land on the matching colours.
 4. Make it tile (method "quilt"): minimum-error boundary cuts (image
    quilting). From a (N + o) square, the left o columns are replaced by the
    columns that follow column N - 1 in the source, up to a cut path (one
    column per row, moving at most one column per row) chosen by dynamic
    programming through the overlap where the two candidates differ least; so
    column 0 continues column N - 1 exactly, and the switch happens where it is
    invisible. Then the same for the rows, with a cyclic path (its two ends
    one row apart at most) so the horizontal wrap stays exact. Method "layout"
    instead builds the joints (flagstone courses, a square grid, cloister
    walks, mosaic tesserae, cobbles) from a pattern that is periodic by
    construction and fills each stone from the quilted texture (shifted per
    stone, with a small per-stone lightness offset and a bevel), so regular
    joints line up across every edge.
 5. Snap. Every pixel takes the nearest allowed palette colour in OKLab (a/b
    weighted by `chroma_w`, so a green moss and a brown earth of the same
    lightness stay apart; `bias` adds a per-colour distance to tune shares).
    Or, with `shares`, exact proportions (rank_snap()): `patches` colours take
    the pixels furthest toward their hue, the rest is cut by lightness rank.
    Layout regions (joint, stone, turf, ...) each snap to their own colours.
 6. Despeck. A pixel whose colour none of its 4 neighbours shares takes its
    8 neighbours' majority colour (wrap-aware), except the `keep` colours
    (embers, flecks): single pixels only for accents (ART_BIBLE readability).
 7. Variants (`variants`): the same pipeline on another source region (no
    wrap needed; its histogram first matched to the base source, match_hist()),
    then merged into the base tile: on each side, inside a band of
    VARIANT_BAND px, a minimum-error cut parallel to the edge; outside the cut
    (and always in the outer VARIANT_KEEP rows) the pixels are the base tile's
    (merge_variant(); a layout merges whole stones instead, merge_cells()). A
    variant's edges are therefore identical to the base tile's, so base and
    variant cells mix without a seam (the game draws a variant cell clamped,
    the base repeating). The interior is despecked again.
 8. Road strips (`road`: width x height, horizontal quilting only) can fray
    their top and bottom edges into transparency (`fray` px, a profile that is
    periodic in the strip width) so the road sits on any zone floor.
 9. Writes the PNG (opaque RGB for tiles, RGBA for the road) and prints a
    report: size, colour shares, mean OKLab L, and the seam ratio (mean colour
    difference across the wrap divided by the mean difference between
    neighbouring pixels inside the tile: about 1.0 = no visible seam).

The check sheet (`sheet`) shows the tile as a 3x3 repeat at x2, a 6x4 floor
mixing the base and its variants by a fixed pattern at x1 and x2 with the
approved necromancer, Skeleton Warrior and Covenant Recruit on it, the
half-offset tile (any seam would cross its centre) and the report; a road is
shown over its zone tiles.

Requires Pillow and numpy (tools/pixel_palette.py).
"""

import argparse
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from pixel_palette import Palette, srgb_to_oklab

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# Folder of the AI sources (Godot ignores art_source/).
SOURCE_DIR = ROOT / "art_source" / "tiles"
# Folder of the game's floor tiles (SpriteData.ROOT + EnvironmentArtData.TILE_PREFIX).
TILE_DIR = ROOT / "assets" / "sprites" / "tiles"
# Sprites placed on the check sheet for scale and contrast (approved anchors).
SHEET_UNITS = ["player/necromancer", "summons/warrior", "enemies/recruit"]

# Side of a zone tile (art px = layout px; EnvironmentArtData: 128x128).
TILE = 128
# Default margin (fraction 0-0.5 of each side) cropped off a source before the
# reduction: AI images often darken or fade in their outer few percent.
CROP = 0.03
# Default quilting overlap (art px): the band the cut paths run through.
OVERLAP = 24
# Default flatten sigma (art px): gradients wider than about this are removed.
FLATTEN = 28.0
# Lightness percentiles (0-100) of the source stretched over the target range.
PCT_LO, PCT_HI = 2.0, 98.0
# Largest scale (x) applied to the source's a/b spread when it is matched to the
# allowed colours' spread (a near-grey source is not blown up into noise).
HUE_GAIN_MAX = 3.0
# Default weight of the OKLab a/b axes when snapping (above 1 keeps hues apart).
CHROMA_W = 2.5
# Blur (art px, Gaussian sigma) of the hue score that picks a "patches" colour,
# so the patches come out as coherent areas instead of scattered pixels.
PATCH_SIGMA = 1.5
# Variants: width (art px) of the band along each edge the merge cut runs in
# (28: wide enough for a cut to go around a large patch instead of slicing it straight).
VARIANT_BAND = 28
# Variants: outer rows / columns (art px) always kept from the base tile.
VARIANT_KEEP = 2
# Check sheet: background, text colours and the text size (px).
SHEET_BG, SHEET_TEXT, SHEET_DIM = (12, 13, 15), (232, 228, 214), (150, 150, 140)
SHEET_FONT = 14
# Check sheet: the variant pattern of the 6x4 mix (0 = base, 1 = _2, 2 = _3),
# chosen so every variant touches the base and the other variant on all sides.
MIX = [
    [0, 1, 0, 2, 0, 0],
    [2, 0, 0, 1, 2, 0],
    [0, 0, 1, 0, 1, 1],
    [1, 2, 0, 0, 2, 0],
]

# --- Recipes --------------------------------------------------------------------------
# One entry per output (TUNING, not in GDD: these are art choices). Keys:
#   source      file in art_source/tiles/ (the AI image)
#   box         (x0, y0, x1, y1) region of the source, fractions 0-1 (default: CROP margin)
#   method      "quilt" (organic textures) or "layout" (regular joints, build_layout())
#   colors      allowed palette colour names (quilt)
#   shares      {colour: fraction} exact proportions by lightness rank (quilt, rank_snap());
#               patches {colour: fraction} taken first by hue
#   layout      the joint pattern: {"type": courses | walks | grid | voronoi, ...} (see its function)
#   regions     layout: {region: colours}; l_ranges {region: (lo, hi)} per region
#   cell_shift  layout: each stone reads the texture at its own seeded offset (seed)
#   cell_l      layout: +/- per-stone OKLab L offset; bevel: L added on lit / taken on shaded edges
#   flat        layout: each cell is one flat colour (its mean: mosaic tesserae)
#   l_range     (lo, hi) OKLab L the source's lightness is stretched over (default: colours' range)
#   chroma_w    snapping weight of a/b (default CHROMA_W)
#   bias        {colour: distance} added when snapping (+ = rarer, - = more common)
#   flatten     Gaussian sigma (art px) of the gradient removal; 0 = off; flatten_axis "xy" / "x"
#   overlap     quilting overlap (art px)
#   keep        colours the despeck keeps as single pixels (accents)
#   variants    list of {"source", "box"} for tiles/<name>_2, _3
#   road        (width, height): a road strip instead of a square tile; "fray" px
#   sheet_floors  road: the zone tiles its check sheet lays it over

# Variant sources are 1536x1024 images (ART_BIBLE: "<zone>_v" prompts); _2 and
# _3 are its left and right squares, at the base tiles' scale (~6.5 source px
# per art px: 832 source px -> 128 art px), overlapping only in the middle.
VARIANT_BOXES = [(0.02, 0.06, 0.56, 0.87), (0.44, 0.06, 0.98, 0.87)]


def halves(src: str) -> list:
    """The two variant entries (tiles/<zone>_2, _3) cut from variant source `src`."""
    return [{"source": src, "box": b} for b in VARIANT_BOXES]


RECIPES = {
    "march_burned": {
        "source": "march_burned.png", "variants": halves("march_burned_v.png"), "method": "quilt",
        "colors": ["ink_warm", "floor_earth", "floor_ash", "floor_stone", "ink_red"],
        "l_range": (0.19, 0.30), "bias": {"floor_ash": -0.008},
        "keep": ["ink_red", "floor_stone"],
    },
    "march_checkpoint": {
        "source": "march_checkpoint.png", "variants": halves("march_checkpoint_v.png"), "method": "quilt",
        "colors": ["ink_green", "floor_grass", "floor_moss", "floor_earth"],
        "shares": {"ink_green": 0.06, "floor_grass": 0.80, "floor_moss": 0.14}, "patches": {"floor_earth": 0.10},
    },
    "march_camp": {
        "source": "march_camp.png", "variants": halves("march_camp_v.png"), "method": "quilt",
        "colors": ["ink_warm", "floor_earth", "floor_dirt", "floor_stone", "brown"],
        "l_range": (0.19, 0.30), "bias": {"brown": 0.03},
        "keep": ["brown", "floor_stone"],
    },
    "march_fortress": {
        "source": "march_fortress.png", "method": "quilt",  # No variants: the variant source's cobbles came out inverted.
        "colors": ["ink_cold", "floor_soil", "floor_slate", "floor_stone"],
    },
    "sanctum_courtyard": {
        "source": "sanctum_courtyard.png", "variants": halves("sanctum_courtyard_v.png"), "method": "layout",
        "layout": {"type": "courses", "rows": [32, 32, 32, 32], "joint": 1,
                   "slabs": [[48, 40, 40], [36, 56, 36], [44, 44, 40], [40, 48, 40]], "offsets": [0, 20, 8, 30]},
        "regions": {"stone": ["floor_ash", "floor_stone"], "joint": ["floor_soil", "floor_grass"]},
        "bias": {"floor_grass": 0.0}, "cell_shift": True, "cell_l": 0.01, "bevel": 0.01,
    },
    "sanctum_halls": {
        "source": "sanctum_halls.png", "variants": halves("sanctum_halls_v.png"), "method": "layout",
        "layout": {"type": "grid", "step": 8, "joint": 1, "lattice": 8},
        "regions": {"stone": ["floor_earth", "floor_ochre", "floor_dirt"], "inlay": ["floor_dirt"],
                    "node": ["brown"], "joint": ["floor_earth"]},
        "l_ranges": {"stone": (0.22, 0.29)}, "bias": {"floor_ochre": -0.03},
        "flat": True, "cell_l": 0.006,
    },
    "sanctum_cloisters": {
        "source": "sanctum_cloisters.png", "variants": halves("sanctum_cloisters_v.png"), "method": "layout",
        "layout": {"type": "walks", "walk": 16, "slab": 32},
        "regions": {"turf": ["ink_green", "floor_grass", "floor_moss"], "stone": ["floor_ash", "floor_stone"],
                    "joint": ["floor_soil"]},
        "l_ranges": {"turf": (0.19, 0.28)},
        "chroma_w": 3.0, "cell_l": 0.01, "bevel": 0.01,
    },
    "sanctum_sanctuary": {
        "source": "sanctum_sanctuary.png", "method": "layout",  # No variants: every 64 px slab reaches a tile edge (merge_cells()).
        "layout": {"type": "grid", "step": 64, "joint": 1, "stagger": 32},
        "regions": {"stone": ["floor_slate", "floor_marble", "grey_dark"], "joint": ["floor_soil"]},
        "l_ranges": {"stone": (0.25, 0.33)}, "bias": {"grey_dark": 0.02},
        "cell_shift": True, "cell_l": 0.005,
    },
    # --- Act II: the Hollow Archive (no variants: one source each) ---
    "archive_halls": {
        "source": "archive_halls.png", "method": "layout",
        "layout": {"type": "courses", "rows": [16, 16, 16, 16, 16, 16, 16, 16], "joint": 1,
                   "slabs": [[64, 64], [48, 80], [96, 32], [40, 88], [64, 64], [72, 56], [32, 96], [56, 72]],
                   "offsets": [0, 24, 8, 40, 16, 56, 4, 32]},
        "regions": {"stone": ["floor_earth", "floor_dirt"], "joint": ["ink_warm"]},
        "cell_shift": True, "cell_l": 0.008, "bevel": 0.006,
    },
    "archive_wells": {
        "source": "archive_wells.png", "method": "quilt",
        "colors": ["ink_cold", "floor_soil", "floor_slate", "floor_marble"],
        "shares": {"ink_cold": 0.10, "floor_soil": 0.40, "floor_slate": 0.38, "floor_marble": 0.12},
    },
    "archive_orrery": {
        "source": "archive_orrery.png", "method": "quilt",
        "colors": ["floor_soil", "floor_slate", "floor_stone", "floor_ochre"],
        "keep": ["floor_ochre"], "bias": {"floor_ochre": 0.02},
    },
    "archive_stacks": {
        "source": "archive_stacks.png", "method": "quilt",
        "colors": ["floor_ash", "floor_stone", "floor_marble", "floor_slate"],
        "l_range": (0.26, 0.31),
    },
    "march_road": {
        "source": "march_road.png", "method": "quilt", "road": (192, 140), "overlap": 18,
        "box": (0.02, 0.02, 0.98, 0.98), "flatten_axis": "x", "fray": 4,
        "colors": ["ink_warm", "floor_earth", "floor_dirt", "floor_stone"],
        "shares": {"ink_warm": 0.04, "floor_earth": 0.18, "floor_dirt": 0.68, "floor_stone": 0.10},
        "sheet_floors": ["march_burned", "march_checkpoint", "march_camp"],
    },
    "march_road_fortress": {
        "source": "sanctum_courtyard.png", "method": "layout", "road": (192, 140), "overlap": 18,
        "box": (0.03, 0.2, 0.97, 0.83), "flatten_axis": "x", "fray": 0,
        "layout": {"type": "courses", "rows": [8, 31, 31, 31, 31, 8], "joint": 1, "kerb": [0, 5],
                   "slabs": [[24] * 8, [40, 36, 44, 32, 40], [32, 44, 36, 40, 40], [44, 40, 32, 36, 40],
                             [36, 32, 44, 40, 40], [24] * 8],
                   "offsets": [0, 0, 18, 8, 26, 12]},
        "regions": {"stone": ["floor_ash", "floor_stone"], "kerb": ["floor_slate"], "joint": ["floor_soil"]},
        "cell_shift": True, "cell_l": 0.01, "bevel": 0.01,
        "sheet_floors": ["march_fortress"],
    },
    # --- Act II: Gullhaven Harbour (HarbourGround, tiles/harbour_<style>) ---
    "harbour_mudflats": {
        "source": "harbour_mudflats.png", "method": "quilt",  # Wet sand ripples at low tide.
        "colors": ["floor_soil", "floor_slate", "floor_stone"],
        "shares": {"floor_soil": 0.22, "floor_slate": 0.68, "floor_stone": 0.10},
    },
    "harbour_market": {
        "source": "march_fortress.png", "method": "layout",  # Wet market cobbles (the fortress grit as their texture).
        "layout": {"type": "voronoi", "count": 64, "seed": 4, "joint": 1.6},
        "regions": {"stone": ["floor_slate", "floor_stone", "floor_marble"], "joint": ["floor_soil"]},
        "cell_shift": True, "cell_l": 0.012, "bevel": 0.01,
    },
    "harbour_chapel": {
        # The village chapel's old hardwood floor (owner's art review: "a village chapel would have a
        # hardwood floor"; it replaced slimed flagstones): long, narrow 8 px planks in staggered
        # courses over a wood-grain source (16 px courses read as bricks), warmer than the
        # Archive's dark 16 px boards.
        "source": "harbour_chapel_wood.png", "method": "layout",
        "layout": {"type": "courses", "rows": [8] * 16, "joint": 1,
                   "slabs": [[80, 48], [128], [56, 72], [96, 32], [128], [48, 80], [72, 56], [128],
                             [40, 88], [104, 24], [64, 64], [128], [88, 40], [32, 96], [128], [112, 16]],
                   "offsets": [0, 52, 20, 84, 36, 8, 100, 68, 44, 12, 76, 28, 116, 60, 92, 4]},
        "regions": {"stone": ["floor_dirt", "floor_ochre"], "joint": ["ink_warm"]},
        "cell_shift": True, "cell_l": 0.012, "bevel": 0.006,
    },
    "harbour_seawall": {
        "source": "sanctum_courtyard.png", "method": "layout",  # The promenade's long dressed paving stones.
        "layout": {"type": "courses", "rows": [32, 32, 32, 32], "joint": 1,
                   "slabs": [[64, 64], [48, 80], [72, 56], [56, 72]], "offsets": [0, 24, 8, 36]},
        "regions": {"stone": ["floor_slate", "floor_marble"], "joint": ["floor_soil"]},
        "cell_shift": True, "cell_l": 0.01, "bevel": 0.01,
    },
    # --- Act II: Ul-Thalos ---
    # The four zone floors of the Risen Spire (SpireGround) and the sea around the island
    # (SinkingDirector draws tiles/spire_water). The API sources came back with a
    # transparent background, so they were flattened to opaque RGB before archiving.
    "spire_breakwater": {
        "source": "spire_breakwater.png", "variants": halves("spire_breakwater_v.png"), "method": "quilt",
        "colors": ["ink_drowned", "floor_soil", "floor_grass", "floor_moss", "floor_slate"],
        "keep": ["ink_drowned"],
    },
    "spire_steps": {
        "source": "spire_steps.png", "variants": halves("spire_steps_v.png"), "method": "quilt",
        "colors": ["ink_drowned", "floor_soil", "floor_grass", "floor_moss"],
    },
    "spire_gate": {
        "source": "spire_gate.png", "variants": halves("spire_gate_v.png"), "method": "quilt",
        "colors": ["ink_cold", "floor_soil", "floor_slate", "biolume_dark"],
        "bias": {"biolume_dark": 0.02}, "keep": ["biolume_dark"],
    },
    "spire_spire": {
        "source": "spire_spire.png", "method": "quilt",
        "colors": ["ink_drowned", "floor_soil", "floor_slate", "floor_marble"],
    },
    # --- Act III: the Assembly Halls (AssemblyGround, tiles/assembly_<style>) ---
    # The factory's four floors are regular steel joints over existing grit sources (no new API
    # image): the layout builds the plates, the source only gives each plate its wear.
    "assembly_docks": {
        "source": "sanctum_courtyard.png", "method": "layout",  # Scuffed steel deck plates, staggered.
        "layout": {"type": "grid", "step": 64, "joint": 1, "stagger": 32},
        "regions": {"stone": ["floor_soil", "floor_slate"], "joint": ["ink_cold"]},
        "l_ranges": {"stone": (0.21, 0.30)}, "cell_shift": True, "cell_l": 0.008, "bevel": 0.008,
    },
    "assembly_conveyor": {
        "source": "march_fortress.png", "method": "layout",  # Grated walkway: a fine square grid.
        "layout": {"type": "grid", "step": 16, "joint": 1},
        "regions": {"stone": ["floor_slate"], "joint": ["ink_cold"]},
        "flat": True, "cell_l": 0.0,
    },
    "assembly_fabricator": {
        "source": "sanctum_courtyard.png", "method": "layout",  # Polished square panels, blue-steel.
        "layout": {"type": "grid", "step": 32, "joint": 1},
        "regions": {"stone": ["floor_slate", "floor_marble", "chrome_dark"], "joint": ["ink_chrome"]},
        "l_ranges": {"stone": (0.24, 0.32)}, "bias": {"chrome_dark": 0.01}, "cell_shift": True, "cell_l": 0.006, "bevel": 0.01,
    },
    "assembly_furnace": {
        "source": "march_burned.png", "method": "layout",  # Soot-black cast-iron slabs, embers in the joints.
        "layout": {"type": "courses", "rows": [32, 32, 32, 32], "joint": 2,
                   "slabs": [[48, 80], [64, 64], [80, 48], [56, 72]], "offsets": [0, 24, 12, 40]},
        "regions": {"stone": ["floor_soil", "floor_ash", "floor_earth"], "joint": ["ink_warm", "ink_red"]},
        "l_ranges": {"stone": (0.19, 0.27)}, "bias": {"ink_red": 0.02}, "cell_shift": True, "cell_l": 0.01, "bevel": 0.008,
    },
    "spire_water": {
        "source": "spire_water.png", "method": "quilt",
        "colors": ["ink_drowned", "drowned_dark", "drowned"],
        "shares": {"ink_drowned": 0.30, "drowned_dark": 0.66, "drowned": 0.04},
        "keep": ["drowned"],
    },
    # --- Act III: the Scrap Wastes --- (one source each, no variants)
    "wastes_slag": {
        "source": "wastes_slag.png", "method": "quilt",
        "colors": ["ink_warm", "floor_soil", "floor_earth", "floor_ash", "floor_dirt"],
    },
    "wastes_gullies": {
        "source": "wastes_gullies.png", "method": "quilt",
        "colors": ["ink_warm", "floor_earth", "floor_dirt", "floor_ochre"],
    },
    "wastes_ridge": {
        "source": "wastes_ridge.png", "method": "quilt",
        "colors": ["ink_cold", "floor_soil", "floor_slate", "floor_ash"],
    },
    "wastes_wall": {
        "source": "wastes_wall.png", "method": "quilt",
        "colors": ["ink_cold", "floor_slate", "floor_marble", "floor_stone"],
    },
    # --- Act III: the Iron Citadel ---
    # The four zone floors of THE IRON CITADEL (CitadelGround, tiles/citadel_<style>): riveted
    # steel deck plates (one API texture, laid out three ways) and the Core's circuit-etched
    # plating. The API sources came back with alpha, flattened to RGB over floor_soil.
    "citadel_gates": {
        "source": "citadel_plates.png", "method": "layout",  # The Shield Gates: big 32 px deck plates.
        "layout": {"type": "grid", "step": 32, "joint": 1, "stagger": 16},
        "regions": {"stone": ["floor_slate", "floor_marble"], "joint": ["ink_chrome"]},
        "cell_shift": True, "cell_l": 0.01, "bevel": 0.01,
    },
    "citadel_courts": {
        "source": "citadel_plates.png", "method": "layout",  # The Laser Courts: a fine 16 px grid of panels.
        "layout": {"type": "grid", "step": 16, "joint": 1},
        "regions": {"stone": ["floor_soil", "floor_slate"], "joint": ["ink_chrome"]},
        "cell_shift": True, "cell_l": 0.008, "bevel": 0.008,
    },
    "citadel_lifts": {
        "source": "citadel_plates.png", "method": "layout",  # The Spire Lifts: long grating slats.
        "layout": {"type": "courses", "rows": [8] * 16, "joint": 1, "slabs": [[128]] * 16, "offsets": [0] * 16},
        "regions": {"stone": ["floor_soil", "floor_marble"], "joint": ["ink_chrome"]},
        "cell_shift": True, "cell_l": 0.008, "bevel": 0.006,
    },
    "citadel_core": {
        "source": "citadel_core.png", "method": "quilt",  # The Core: circuit-etched plating, dim red traces.
        "colors": ["ink_chrome", "floor_soil", "floor_slate", "chrome_dark", "signal_dark"],
        "bias": {"chrome_dark": 0.02, "signal_dark": 0.03}, "keep": ["chrome_dark", "signal_dark"],
    },
}


# --- Image helpers --------------------------------------------------------------------

def load_source(path: Path) -> np.ndarray:
    """The AI image as float sRGB 0-255 (H, W, 3), composited over its median
    opaque colour (a texture has no background; transparent pixels would turn black)."""
    im = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64)
    rgb, a = im[..., :3], im[..., 3:4] / 255.0
    solid = a[..., 0] > 0.5
    under = np.median(rgb[solid], axis=0) if solid.any() else np.array([30.0, 30.0, 30.0])  # Fill colour.
    return rgb * a + under * (1.0 - a)


def to_grid(rgb: np.ndarray, box, w: int, h: int) -> np.ndarray:
    """Crops `box` (fractions x0, y0, x1, y1) of `rgb` and box-filters it to (h, w) px."""
    H, W = rgb.shape[:2]
    x0, y0, x1, y1 = box
    crop = rgb[int(round(y0 * H)):int(round(y1 * H)), int(round(x0 * W)):int(round(x1 * W))]
    im = Image.fromarray(np.clip(crop, 0, 255).astype(np.uint8))
    return np.asarray(im.resize((w, h), Image.BOX), dtype=np.float64)


def gauss_1d(arr: np.ndarray, sigma: float, axis: int, wrap: bool) -> np.ndarray:
    """1-D Gaussian blur of a 2-D array along `axis` (wrap or reflect at the ends)."""
    r = max(1, int(3 * sigma))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    n = arr.shape[axis]
    idx = np.arange(-r, n + r)
    if wrap:
        idx = idx % n
    else:  # Reflect (period 2n), for sources that are not periodic yet.
        idx = np.abs(idx)
        idx = np.where(idx >= n, 2 * n - 2 - idx, idx)
        idx = np.clip(idx, 0, n - 1)
    padded = np.take(arr, idx, axis=axis)
    out = np.zeros_like(arr)
    for i, kv in enumerate(k):
        out += kv * np.take(padded, np.arange(i, i + n), axis=axis)
    return out


def flatten(lab: np.ndarray, sigma: float, axis: str = "xy", wrap: bool = False) -> np.ndarray:
    """Removes lightness gradients wider than ~sigma art px (step 2 of the header)."""
    if sigma <= 0:
        return lab
    L = lab[..., 0]
    blur = L
    if "x" in axis:
        blur = gauss_1d(blur, sigma, 1, wrap)
    if "y" in axis:
        blur = gauss_1d(blur, sigma, 0, wrap)
    out = lab.copy()
    out[..., 0] = L - blur + L.mean()
    return out


def normalise(lab: np.ndarray, pal: Palette, allowed: list, l_range=None) -> np.ndarray:
    """Stretches the source's lightness over the target range and scales its
    chroma to the allowed colours' (step 3 of the header)."""
    out = lab.copy()
    tl = pal.lab[allowed][:, 0]
    lo, hi = l_range if l_range else (float(tl.min()), float(tl.max()))
    p_lo, p_hi = np.percentile(lab[..., 0], [PCT_LO, PCT_HI])
    out[..., 0] = lo + (lab[..., 0] - p_lo) / max(p_hi - p_lo, 1e-6) * (hi - lo)
    # Hue: the source's a/b cloud is moved onto the allowed colours' centre and
    # scaled to their spread, so the source's relative hues (greener grass,
    # browner mud) land on the matching colours even when the AI's render is
    # almost grey or too saturated.
    ab = lab[..., 1:].reshape(-1, 2)
    t_ab = pal.lab[allowed][:, 1:]
    s_sd = float(np.sqrt(ab.var(0).sum()))
    t_sd = float(np.sqrt(t_ab.var(0).sum()))
    k = min(t_sd / max(s_sd, 1e-6), HUE_GAIN_MAX)  # a/b scale.
    out[..., 1:] = t_ab.mean(0) + (lab[..., 1:] - ab.mean(0)) * k
    return out


def snap(lab: np.ndarray, pal: Palette, allowed: list, chroma_w: float, bias: dict) -> np.ndarray:
    """Nearest allowed palette index per pixel (OKLab, a/b weighted, plus per-colour bias)."""
    cand = pal.lab[allowed]
    w = np.array([1.0, chroma_w, chroma_w])
    flat = lab.reshape(-1, 3)
    d = np.sqrt((((flat[:, None, :] - cand[None, :, :]) * w) ** 2).sum(-1))
    d += np.array([bias.get(pal.names[i], 0.0) for i in allowed])[None, :]
    return np.array(allowed)[d.argmin(1)].reshape(lab.shape[:-1])


def rank_snap(lab: np.ndarray, pal: Palette, shares: dict, patches: dict) -> np.ndarray:
    """Share-controlled snapping (recipe "shares", replaces snap()): first each
    `patches` colour takes the `share` (0-1) of the pixels whose a/b lies
    furthest toward it from the shares colours' centre (the hue score is
    blurred PATCH_SIGMA px first, so patches stay coherent: mud in grass);
    then the rest is cut by lightness rank into the `shares` colours in
    lightness order, each taking its share (normalised to the rest). Exact
    colour proportions whatever the source's exposure or hue noise."""
    h, w = lab.shape[:2]
    out = np.full((h, w), -1, dtype=np.int64)
    names = sorted(shares, key=lambda n: pal.lab[pal.index_of[n]][0])  # Dark -> light.
    centre = pal.lab[[pal.index_of[n] for n in names]][:, 1:].mean(0)
    for pname, share in patches.items():
        tgt = pal.lab[pal.index_of[pname]][1:] - centre
        score = (lab[..., 1:] - centre) @ (tgt / max(np.linalg.norm(tgt), 1e-9))
        score = gauss_1d(gauss_1d(score, PATCH_SIGMA, 0, True), PATCH_SIGMA, 1, True)
        score[out >= 0] = -1e9
        cut = np.quantile(score[out < 0], 1.0 - share * (h * w) / max((out < 0).sum(), 1))
        out[(score >= cut) & (out < 0)] = pal.index_of[pname]
    rest = out < 0
    L = lab[..., 0][rest]
    total = sum(shares.values())
    edges = np.cumsum([shares[n] / total for n in names])[:-1]
    cuts = np.quantile(L, edges) if len(edges) else []
    pick = np.searchsorted(cuts, L, side="right")
    out[rest] = np.array([pal.index_of[n] for n in names])[pick]
    return out


def despeck(idx: np.ndarray, keep: set, wrap: bool = True, fixed: np.ndarray = None) -> np.ndarray:
    """One pass: a pixel no 4-neighbour shares takes its 8-neighbours' majority
    colour, except `keep` colours and pixels marked in `fixed` (step 6)."""
    h, w = idx.shape
    out = idx.copy()
    for y in range(h):
        for x in range(w):
            c = idx[y, x]
            if c in keep or (fixed is not None and fixed[y, x]):
                continue
            nb4, nb8 = [], []
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if not (dy or dx):
                        continue
                    yy, xx = y + dy, x + dx
                    if wrap:
                        yy, xx = yy % h, xx % w
                    elif not (0 <= yy < h and 0 <= xx < w):
                        continue
                    nb8.append(idx[yy, xx])
                    if dy == 0 or dx == 0:
                        nb4.append(idx[yy, xx])
            if c not in nb4 and nb8:
                out[y, x] = Counter(nb8).most_common(1)[0][0]
    return out


# --- Seamless quilting ----------------------------------------------------------------

def min_path(cost: np.ndarray, lo: int, hi: int, start: int = -1) -> tuple:
    """Minimum-cost path through `cost` (rows x cols): one column per row in
    [lo, hi], moving at most one column between rows. With `start` >= 0 the
    path starts at that column and must end within one column of it (cyclic).
    Returns (path columns per row, total cost)."""
    rows, cols = cost.shape
    inf = 1e18
    acc = np.full((rows, cols), inf)
    back = np.zeros((rows, cols), dtype=np.int64)
    if start >= 0:
        acc[0, start] = cost[0, start]
    else:
        acc[0, lo:hi + 1] = cost[0, lo:hi + 1]
    for y in range(1, rows):
        for x in range(lo, hi + 1):
            best, arg = inf, x
            for dx in (-1, 0, 1):
                xx = x + dx
                if lo <= xx <= hi and acc[y - 1, xx] < best:
                    best, arg = acc[y - 1, xx], xx
            acc[y, x] = best + cost[y, x]
            back[y, x] = arg
    ends = range(lo, hi + 1) if start < 0 else [e for e in (start - 1, start, start + 1) if lo <= e <= hi]
    end = min(ends, key=lambda e: acc[-1, e])
    path = np.zeros(rows, dtype=np.int64)
    path[-1] = end
    for y in range(rows - 1, 0, -1):
        path[y - 1] = back[y, path[y]]
    return path, float(acc[-1, end])


def quilt_x(lab: np.ndarray, n: int, cyclic: bool = False) -> np.ndarray:
    """Makes `lab` (rows x (n + o)) wrap horizontally with period n (step 4):
    columns 0..o-1 come from columns n..n+o-1 left of the cut and stay right of it."""
    o = lab.shape[1] - n
    left, right = lab[:, :o], lab[:, n:n + o]
    cost = np.sqrt(((left - right) ** 2).sum(-1))
    if cyclic:
        best = None
        for s in range(1, o):
            p, c = min_path(cost, 1, o - 1, start=s)
            if best is None or c < best[1]:
                best = (p, c)
        path = best[0]
    else:
        path, _ = min_path(cost, 1, o - 1)
    out = lab[:, :n].copy()
    for y in range(lab.shape[0]):
        out[y, :path[y]] = right[y, :path[y]]
    return out


def make_seamless(lab: np.ndarray, n: int) -> np.ndarray:
    """((n + o) x (n + o)) -> (n x n), wrapping on both axes (quilt_x, then rows)."""
    h = quilt_x(lab, n)  # (n + o) x n, every row periodic.
    v = quilt_x(h.transpose(1, 0, 2), n, cyclic=True)  # Rows, with a cyclic cut.
    return v.transpose(1, 0, 2)


def seam_ratio(idx: np.ndarray, pal: Palette, axis: int) -> float:
    """Mean OKLab difference across the wrap edge on `axis` divided by the mean
    difference between neighbouring pixels inside (1.0 = the wrap reads like any
    other pixel boundary)."""
    lab = pal.lab[idx]
    inner = np.sqrt(((np.diff(lab, axis=axis)) ** 2).sum(-1)).mean()
    a = np.take(lab, [-1], axis=axis)
    b = np.take(lab, [0], axis=axis)
    edge = np.sqrt(((a - b) ** 2).sum(-1)).mean()
    return float(edge / max(inner, 1e-9))


# --- Layouts (method "layout") --------------------------------------------------------

def _courses(n_w: int, n_h: int, spec: dict) -> tuple:
    """Staggered courses: rows of `rows` heights, each split along x into the
    lengths of its row in `slabs` starting at `offsets`; joints `joint` px.
    Optional `kerb` rows (indices) are region "kerb". Returns (cell ids, region names map)."""
    cell = np.zeros((n_h, n_w), dtype=np.int64)
    region = np.full((n_h, n_w), "stone", dtype=object)
    j = spec.get("joint", 1)
    y0, cid = 0, 0
    for r, rh in enumerate(spec["rows"]):
        lengths = spec["slabs"][r % len(spec["slabs"])]
        off = spec["offsets"][r % len(spec["offsets"])]
        x = -off
        edges = []
        while x < n_w:
            for ln in lengths:
                edges.append(x)
                x += ln
        for yy in range(y0, y0 + rh):
            for xx in range(n_w):
                k = max(i for i, e in enumerate(edges) if e <= xx)
                cell[yy, xx] = cid + (k % len(lengths))
                if r in spec.get("kerb", []):
                    region[yy, xx] = "kerb"
                if yy < y0 + j or any((xx - e) % n_w < j for e in edges):
                    region[yy, xx] = "joint"
        cid += len(lengths)
        y0 += rh
    return cell, region


def _walks(n: int, spec: dict) -> tuple:
    """Cloister walks: a stone band `walk` px wide on all four tile edges (so
    the walks form a grid one tile apart), cut into slabs `slab` px long, with
    turf inside; 1 px joints between slabs and along the turf."""
    w, s = spec["walk"], spec["slab"]
    half = w // 2
    cell = np.zeros((n, n), dtype=np.int64)
    region = np.full((n, n), "turf", dtype=object)
    for y in range(n):
        for x in range(n):
            # Distance into the walk band from the tile edge (the band straddles the edge).
            in_x = x < half or x >= n - (w - half)
            in_y = y < half or y >= n - (w - half)
            if not (in_x or in_y):
                cell[y, x] = 1
                continue
            if in_y:  # Horizontal walk: slabs along x.
                k = ((x + s // 2) // s) % (n // s)
                cell[y, x] = 10 + k
                joint = (x + s // 2) % s == 0 or y == n - (w - half)
                if y == half - 1 and not in_x:
                    joint = True
            else:  # Vertical walk: slabs along y.
                k = ((y + s // 2) // s) % (n // s)
                cell[y, x] = 100 + k
                joint = (y + s // 2) % s == 0 or x == n - (w - half)
                if x == half - 1:
                    joint = True
            region[y, x] = "joint" if joint else "stone"
    return cell, region


def _grid(n: int, spec: dict) -> tuple:
    """Square slabs `step` px with `joint` px joints, rows optionally staggered
    by `stagger` px; or mosaic tesserae with a diamond `lattice` (period in
    tesserae) marked region "inlay"."""
    st, j = spec["step"], spec.get("joint", 1)
    stagger = spec.get("stagger", 0)
    cell = np.zeros((n, n), dtype=np.int64)
    region = np.full((n, n), "stone", dtype=object)
    per = n // st
    for y in range(n):
        r = y // st
        for x in range(n):
            xs = (x + (stagger if r % 2 else 0)) % n
            c = xs // st
            cell[y, x] = r * per + c
            if spec.get("lattice"):
                p = spec["lattice"]
                on_a, on_b = (r + c) % p == 0, (r - c) % p == 0  # On each diagonal family.
                if on_a and on_b:
                    region[y, x] = "node"  # Where two lattice lines cross.
                elif on_a or on_b:
                    region[y, x] = "inlay"
            if y % st < j or xs % st < j:
                region[y, x] = "joint"
    return cell, region


def _voronoi(n: int, spec: dict) -> tuple:
    """Cobbles: periodic Voronoi cells of `count` seeded points (deterministic,
    `seed`); a pixel is a joint where its two nearest points are within `joint`
    px of each other's distance."""
    rng = np.random.default_rng(spec.get("seed", 1))
    pts = rng.random((spec["count"], 2)) * n
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    d = np.full((spec["count"], n, n), 1e9)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(xx - px)
        dy = np.abs(yy - py)
        dx = np.minimum(dx, n - dx)  # Periodic distance: the cells wrap.
        dy = np.minimum(dy, n - dy)
        d[i] = np.hypot(dx, dy)
    order = np.argsort(d, axis=0)
    cell = order[0]
    d1 = np.take_along_axis(d, order[:1], 0)[0]
    d2 = np.take_along_axis(d, order[1:2], 0)[0]
    region = np.where(d2 - d1 < spec.get("joint", 1.6), "joint", "stone").astype(object)
    return cell, region


def build_layout(n_w: int, n_h: int, spec: dict) -> tuple:
    """(cell ids, region names) of layout `spec["type"]` (periodic by construction)."""
    t = spec["type"]
    if t == "courses":
        return _courses(n_w, n_h, spec)
    if t == "walks":
        return _walks(n_w, spec)
    if t == "grid":
        return _grid(n_w, spec)
    if t == "voronoi":
        return _voronoi(n_w, spec)
    raise SystemExit(f"unknown layout {t}")


def fill_layout(tex: np.ndarray, cell: np.ndarray, region: np.ndarray, rec: dict, pal: Palette) -> np.ndarray:
    """Fills a layout from the periodic texture `tex` (OKLab, same size): each
    cell reads the texture shifted by a per-cell offset (`cell_shift`), plus a
    per-cell lightness offset (+/- `cell_l`), a bevel (+`bevel` L on a cell's
    top / left pixels next to a joint, - on its bottom / right ones), or its
    mean when `flat` is set (mosaic tesserae); then each region snaps to its
    own colours (`regions`: name -> colours, normalised separately)."""
    h, w = cell.shape
    rng = np.random.default_rng(rec.get("seed", 7))
    ids = np.unique(cell)
    # Per-cell texture shift (a road strip's texture only wraps along x).
    shift = {int(c): (0 if rec.get("road") else int(rng.integers(0, h)), int(rng.integers(0, w)))
             if rec.get("cell_shift") else (0, 0) for c in ids}
    loff = {int(c): float(rng.uniform(-1, 1)) * rec.get("cell_l", 0.0) for c in ids}
    lab = np.zeros_like(tex)
    for c in ids:
        m = cell == c
        sy, sx = shift[int(c)]
        rolled = np.roll(tex, (sy, sx), axis=(0, 1))
        lab[m] = rolled[m]
        if rec.get("flat"):
            lab[m] = lab[m].mean(0)
        lab[m, 0] += loff[int(c)]
    bevel = rec.get("bevel", 0.0)
    if bevel:
        joint = region == "joint"
        up = np.roll(joint, 1, 0) | np.roll(joint, 1, 1)  # Joint above or to the left (lit edge).
        down = np.roll(joint, -1, 0) | np.roll(joint, -1, 1)  # Joint below or to the right (shade).
        lab[..., 0] += np.where(~joint & up, bevel, 0.0) - np.where(~joint & down & ~up, bevel, 0.0)
    out = np.zeros((h, w), dtype=np.int64)
    for name, colors in rec["regions"].items():
        m = region == name
        if not m.any():
            continue
        allowed = [pal.index_of[c] for c in colors]
        sub = normalise(lab[m][None, ...], pal, allowed, rec.get("l_ranges", {}).get(name))
        out[m] = snap(sub, pal, allowed, rec.get("chroma_w", CHROMA_W), rec.get("bias", {}))[0]
    return out


# --- Building -------------------------------------------------------------------------

def default_box() -> tuple:
    """The whole source minus the CROP margin."""
    return (CROP, CROP, 1.0 - CROP, 1.0 - CROP)


def source_lab(rec: dict, src: str, box, w: int, h: int) -> np.ndarray:
    """Steps 1-2: the source region reduced to (h, w) px, in OKLab, flattened."""
    lab = srgb_to_oklab(to_grid(load_source(SOURCE_DIR / src), box, w, h))
    return flatten(lab, rec.get("flatten", FLATTEN), rec.get("flatten_axis", "xy"))


def match_hist(lab: np.ndarray, ref: np.ndarray) -> np.ndarray:
    """Maps each OKLab channel of `lab` onto the value distribution of `ref`
    (quantile mapping): a variant source keeps its own shapes but takes the
    base source's lightness and hue spread, so a variant whose AI render came
    out darker or bluer still lands on the base tile's colour shares."""
    out = np.empty_like(lab)
    q = np.linspace(0.0, 1.0, 257)
    for ch in range(3):
        src_q = np.quantile(lab[..., ch], q)
        ref_q = np.quantile(ref[..., ch], q)
        out[..., ch] = np.interp(lab[..., ch], src_q, ref_q)
    return out


def texture(rec: dict, pal: Palette, allowed: list, src: str, box, w: int, h: int, periodic: bool,
            ref: np.ndarray = None) -> np.ndarray:
    """Steps 1-4: the source region as an OKLab texture of (h, w) px; periodic
    (quilted) when `periodic`, else just reduced (variants). With `ref` (the
    base tile's flattened source) its distribution is matched to it first."""
    o = rec.get("overlap", OVERLAP) if periodic else 0
    lab = source_lab(rec, src, box, w + o, h + (o if rec.get("road") is None else 0))
    if ref is not None:
        lab = match_hist(lab, ref)
    if rec["method"] == "quilt":
        lab = normalise(lab, pal, allowed, rec.get("l_range"))
    if periodic:
        lab = quilt_x(lab, w) if rec.get("road") else make_seamless(lab, w)
    return lab


def render_tile(rec: dict, pal: Palette, src: str, box, periodic: bool, ref: np.ndarray = None) -> np.ndarray:
    """A tile (or road strip) as palette indices (steps 1-6); `ref`: see texture()."""
    w, h = rec.get("road", (TILE, TILE))
    if rec["method"] == "quilt":
        allowed = [pal.index_of[c] for c in rec["colors"]]
        lab = texture(rec, pal, allowed, src, box, w, h, periodic, ref)
        if rec.get("shares"):
            idx = rank_snap(lab, pal, rec["shares"], rec.get("patches", {}))
        else:
            idx = snap(lab, pal, allowed, rec.get("chroma_w", CHROMA_W), rec.get("bias", {}))
    else:
        allowed = sorted({pal.index_of[c] for cs in rec["regions"].values() for c in cs})
        tex = texture(rec, pal, allowed, src, box, w, h, periodic, ref)
        cell, region = build_layout(w, h, rec["layout"])
        idx = fill_layout(tex, cell, region, rec, pal)
    keep = {pal.index_of[c] for c in rec.get("keep", [])}
    for _ in range(rec.get("despeck", 1)):
        idx = despeck(idx, keep, wrap=periodic)
    return idx


def merge_variant(base: np.ndarray, var: np.ndarray, pal: Palette, keep: set) -> np.ndarray:
    """Step 7: `var` inside, `base` outside a minimum-error cut in a band along
    each edge; the outer VARIANT_KEEP px are always the base tile's."""
    n = base.shape[0]
    cost = np.sqrt(((pal.lab[base] - pal.lab[var]) ** 2).sum(-1))
    use_base = np.zeros_like(base, dtype=bool)
    lo, hi = VARIANT_KEEP, VARIANT_BAND
    # Top and bottom: horizontal cuts (paths over columns), left and right: vertical cuts.
    p, _ = min_path(cost[:hi + 1].T, lo, hi)
    for x in range(n):
        use_base[:p[x], x] = True
    p, _ = min_path(cost[::-1][:hi + 1].T, lo, hi)
    for x in range(n):
        use_base[n - p[x]:, x] = True
    p, _ = min_path(cost[:, :hi + 1], lo, hi)
    for y in range(n):
        use_base[y, :p[y]] = True
    p, _ = min_path(cost[:, ::-1][:, :hi + 1], lo, hi)
    for y in range(n):
        use_base[y, n - p[y]:] = True
    out = np.where(use_base, base, var)
    fixed = np.zeros_like(use_base)
    fixed[:VARIANT_KEEP] = fixed[-VARIANT_KEEP:] = True
    fixed[:, :VARIANT_KEEP] = fixed[:, -VARIANT_KEEP:] = True
    return despeck(out, keep, wrap=False, fixed=fixed)


def merge_cells(base: np.ndarray, var: np.ndarray, cell: np.ndarray) -> np.ndarray:
    """Step 7 for layouts: whole stones. A cell (stone, tessera, turf bed) that
    reaches the outer VARIANT_KEEP px keeps the base tile's pixels, the cells
    inside take the variant's (a cut through a stone would show as a straight
    change of shade inside it)."""
    edge = np.zeros_like(cell, dtype=bool)
    edge[:VARIANT_KEEP] = edge[-VARIANT_KEEP:] = True
    edge[:, :VARIANT_KEEP] = edge[:, -VARIANT_KEEP:] = True
    outer = np.isin(cell, np.unique(cell[edge]))
    return np.where(outer, base, var)


def fray_alpha(w: int, h: int, depth: int, seed: int) -> np.ndarray:
    """Road strip alpha (h, w): the top and bottom `depth` px fray along a
    profile periodic in w (sum of integer-frequency sines), so the strip tiles."""
    a = np.ones((h, w), dtype=bool)
    if depth <= 0:
        return a
    rng = np.random.default_rng(seed)
    x = np.arange(w) / w * 2 * np.pi
    for top in (True, False):
        prof = np.zeros(w)
        for f in (3, 5, 8, 13):
            prof += rng.uniform(0.5, 1.0) / f ** 0.5 * np.sin(f * x + rng.uniform(0, 2 * np.pi))
        prof = (prof - prof.min()) / max(prof.max() - prof.min(), 1e-9)
        d = np.round(prof * depth).astype(int)  # Transparent rows at this column.
        for xx in range(w):
            if top:
                a[:d[xx], xx] = False
            else:
                a[h - d[xx]:, xx] = False
    return a


def report(name: str, idx: np.ndarray, pal: Palette, alpha=None, axes: str = "xy") -> str:
    """One-line stats: size, colour shares, mean OKLab L, and the seam ratio on
    `axes` (quilted wraps; a layout's joints sit on the tile edge by design, so
    its ratio says nothing and is left out with axes "")."""
    sel = idx if alpha is None else idx[alpha]
    cnt = Counter(sel.ravel().tolist())
    shares = ", ".join(f"{pal.names[i]} {100 * c / sel.size:.0f}%" for i, c in cnt.most_common())
    mean_l = float(pal.lab[sel][..., 0].mean())
    seams = " ".join(f"{a} {seam_ratio(idx, pal, 1 if a == 'x' else 0):.2f}" for a in axes)
    seam = f"seam {seams}" if seams else "no seam ratio (layout or variant)"
    return f"{name}: {idx.shape[1]}x{idx.shape[0]}, mean L {mean_l:.3f}, {seam}; {shares}"


def save(idx: np.ndarray, pal: Palette, path: Path, alpha=None) -> None:
    """Writes palette indices as an opaque RGB PNG (or RGBA with `alpha`)."""
    rgb = pal.rgb[idx]
    path.parent.mkdir(parents=True, exist_ok=True)
    if alpha is None:
        Image.fromarray(rgb.astype(np.uint8), "RGB").save(path)
    else:
        rgba = np.dstack([rgb, np.where(alpha, 255, 0)]).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").save(path)


def build(name: str, pal: Palette) -> None:
    """Builds recipe `name` (and its variants) into assets/sprites/tiles/."""
    rec = RECIPES[name]
    idx = render_tile(rec, pal, rec["source"], rec.get("box", default_box()), periodic=True)
    alpha = None
    if rec.get("road"):
        w, h = rec["road"]
        alpha = fray_alpha(w, h, rec.get("fray", 0), rec.get("seed", 7))
    save(idx, pal, TILE_DIR / f"{name}.png", alpha)
    axes = "" if rec["method"] == "layout" else ("x" if rec.get("road") else "xy")  # Wraps the seam ratio means something on.
    print(report(name, idx, pal, alpha, axes))
    keep = {pal.index_of[c] for c in rec.get("keep", [])}
    o = rec.get("overlap", OVERLAP)
    ref = source_lab(rec, rec["source"], rec.get("box", default_box()), TILE + o, TILE + o)  # Base source, for match_hist().
    for i, v in enumerate(rec.get("variants", [])):
        var = render_tile(rec, pal, v["source"], v.get("box", default_box()), periodic=False, ref=ref)
        if rec["method"] == "layout":
            merged = merge_cells(idx, var, build_layout(TILE, TILE, rec["layout"])[0])
        else:
            merged = merge_variant(idx, var, pal, keep)
        vname = f"{name}_{i + 2}"
        edges_same = all(np.array_equal(a, b) for a, b in (
            (merged[0], idx[0]), (merged[-1], idx[-1]), (merged[:, 0], idx[:, 0]), (merged[:, -1], idx[:, -1])))
        save(merged, pal, TILE_DIR / f"{vname}.png")
        print(report(vname, merged, pal, axes="") + f"; edges = base: {edges_same}")


# --- Check sheet ----------------------------------------------------------------------

def _font() -> ImageFont.ImageFont:
    """Pillow's built-in scalable font (bitmap fallback on old Pillow)."""
    try:
        return ImageFont.load_default(size=SHEET_FONT)
    except TypeError:
        return ImageFont.load_default()


def _load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _mix_floor(name: str, cols: int, rows: int) -> Image.Image:
    """A floor of cols x rows tiles: the base and its present variants in the MIX pattern."""
    tiles = [_load_rgba(TILE_DIR / f"{name}.png")]
    for s in ("_2", "_3"):
        p = TILE_DIR / f"{name}{s}.png"
        if p.exists():
            tiles.append(_load_rgba(p))
    t = tiles[0].width
    img = Image.new("RGBA", (cols * t, rows * t))
    for r in range(rows):
        for c in range(cols):
            k = MIX[r % len(MIX)][c % len(MIX[0])]
            img.paste(tiles[k if k < len(tiles) else 0], (c * t, r * t))
    return img


def _units(floor: Image.Image) -> Image.Image:
    """Pastes the SHEET_UNITS sprites (1:1) in a row near the floor's centre."""
    out = floor.copy()
    x = out.width // 2 - 60
    for key in SHEET_UNITS:
        p = ROOT / "assets" / "sprites" / f"{key}.png"
        if p.exists():
            s = _load_rgba(p)
            out.alpha_composite(s, (x, out.height // 2 - s.height // 2))
            x += s.width + 14
    return out


def sheet(name: str, pal: Palette, out: Path) -> None:
    """Writes the check sheet of recipe `name` (see the header)."""
    rec = RECIPES[name]
    font = _font()
    if rec.get("road"):
        zones = rec.get("sheet_floors", ["march_burned"])
        road = _load_rgba(TILE_DIR / f"{name}.png")
        panels = []
        for z in zones:
            fl = _mix_floor(z, 5, 3) if (TILE_DIR / f"{z}.png").exists() else Image.new("RGBA", (640, 384), (30, 26, 22, 255))
            y = fl.height // 2 - road.height // 2
            for x in range(0, fl.width, road.width):
                fl.alpha_composite(road, (x, y))
            panels.append((z, _units(fl)))
        w = max(p.width for _, p in panels) * 2 + 40
        h = sum(p.height * 2 + 30 for _, p in panels) + 60
        img = Image.new("RGB", (w, h), SHEET_BG)
        d = ImageDraw.Draw(img)
        idx = np.asarray(road)[..., :3]
        d.text((14, 10), f"{name}: road strip {road.width}x{road.height}, x2 over its zone floors", fill=SHEET_TEXT, font=font)
        y = 40
        for z, p in panels:
            d.text((14, y), z, fill=SHEET_DIM, font=font)
            img.paste(p.resize((p.width * 2, p.height * 2), Image.NEAREST), (14, y + 18))
            y += p.height * 2 + 30
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        print(f"sheet -> {out}")
        return
    base = _load_rgba(TILE_DIR / f"{name}.png")
    t = base.width
    rep = Image.new("RGBA", (3 * t, 3 * t))
    for r in range(3):
        for c in range(3):
            rep.paste(base, (c * t, r * t))
    rep2 = rep.resize((rep.width * 2, rep.height * 2), Image.NEAREST)
    mix = _units(_mix_floor(name, 6, 4))
    mix2 = _units(_mix_floor(name, 4, 2)).resize((4 * t * 2, 2 * t * 2), Image.NEAREST)
    arr = np.asarray(base)
    half = Image.fromarray(np.roll(arr, (t // 2, t // 2), axis=(0, 1))).resize((t * 3, t * 3), Image.NEAREST)
    pad = 14
    w = pad * 3 + rep2.width + max(mix.width, half.width, mix2.width)
    h = pad + 30 + max(rep2.height, mix.height + half.height + mix2.height + 80) + 40
    img = Image.new("RGB", (w, h), SHEET_BG)
    d = ImageDraw.Draw(img)
    lines = []
    idx_map = {tuple(int(v) for v in pal.rgb[i]): i for i in range(len(pal.names))}
    for s in ("", "_2", "_3"):
        p = TILE_DIR / f"{name}{s}.png"
        if p.exists():
            a = np.asarray(Image.open(p).convert("RGB"))
            idx = np.vectorize(lambda r, g, b: idx_map.get((r, g, b), 0))(a[..., 0], a[..., 1], a[..., 2])
            lines.append(report(name + s, idx, pal, axes="" if (s or rec["method"] == "layout") else "xy"))
    d.text((pad, 8), "   |   ".join(lines[:1]), fill=SHEET_TEXT, font=font)
    for i, ln in enumerate(lines[1:]):
        d.text((pad, h - 34 + i * 16 - 16 * (len(lines) - 2)), ln, fill=SHEET_DIM, font=font)
    y0 = pad + 30
    img.paste(rep2, (pad, y0))
    x1 = pad * 2 + rep2.width
    d.text((x1, y0 - 18), "base + variants mixed, x1 (as in game at Normal zoom)", fill=SHEET_DIM, font=font)
    img.paste(mix, (x1, y0))
    y1 = y0 + mix.height + 26
    d.text((x1, y1 - 18), "x2 (Close zoom)", fill=SHEET_DIM, font=font)
    img.paste(mix2, (x1, y1))
    y2 = y1 + mix2.height + 26
    d.text((x1, y2 - 18), "half-offset base x3 (a seam would cross the centre)", fill=SHEET_DIM, font=font)
    img.paste(half, (x1, y2))
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"sheet -> {out}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["build", "sheet"])
    ap.add_argument("names", nargs="*", help="RECIPES keys")
    ap.add_argument("--all", action="store_true", help="every recipe")
    ap.add_argument("--out", help="sheet: output PNG (one name)")
    ap.add_argument("--out-dir", default="/tmp/necropathy_tiles", help="sheet: output folder")
    args = ap.parse_args()
    names = list(RECIPES) if args.all else args.names
    if not names:
        raise SystemExit("name a recipe or pass --all")
    pal = Palette()
    for n in names:
        if n not in RECIPES:
            raise SystemExit(f"no recipe {n} (have: {', '.join(RECIPES)})")
        if args.cmd == "build":
            build(n, pal)
        else:
            out = Path(args.out) if args.out and len(names) == 1 else Path(args.out_dir) / f"{n}_sheet.png"
            sheet(n, pal, out)


if __name__ == "__main__":
    main()
