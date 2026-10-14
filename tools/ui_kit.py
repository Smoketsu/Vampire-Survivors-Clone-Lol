"""ui_kit.py: draws Necropathy's pixel-art UI kit (9-slice frames, crests, slider and toggle icons) and finishes
the title logo and app icon.

Art pass, docs/art/ART_BIBLE.md "UI kit and title logo". Usage (from the repo root):

    python3 tools/ui_kit.py frames [--preview sheet.png]   # every kit PNG -> assets/ui/
    python3 tools/ui_kit.py logo <converted.png>           # hand fixes -> assets/ui/logo.png
    python3 tools/ui_kit.py icon                           # assets/ui/logo.png -> assets/ui/icon.png

Frames. UI frames are drawn here by code instead of by the image AI: a 9-slice frame needs exact,
repeatable edges (the AI draws ornate, uneven borders that do not slice), and rings of a few pixels are
easy to draw from the locked palette (tools/palette.json). A frame PNG is (2 * SLICE[kind] + CENTER) texels
wide and (2 * SLICE_V[kind] + CENTER) tall (scripts/data/ui_art_data.gd, parsed below, so the game and this
tool agree on the margins; SLICE_V defaults to SLICE). 1 texel = 1 layout px. File name:
<kind>_<accent>_<state>.png. The game tiles (never stretches) the edges and the centre (UiTheme sets
AXIS_STRETCH_MODE_TILE), so every row and column of an edge must repeat cleanly: edges are uniform along
their length, and the dither in the fill has a period that divides CENTER.

How a frame is drawn (the ornamented kit, menu modernization):
  * rings from the outside in, 1 texel each (ink outline, bevels lit one shade lighter on the top and
    left edges like the sprites, ink gaps), with chamfered (cut) corners on every element;
  * the fill: an ordered-dither (4x4 Bayer) vertical gradient, lighter at the top (tinted toward the
    accent) and darker at the bottom, kept inside the top / bottom 9-slice margins so it keeps its pixel
    size on any control (a pressed button inverts it: lit from below);
  * ornaments (bone corner caps, filigree, gems, skulls) are drawn as material masks (B bone, W white
    bone, G gem, K ink, ...), mirrored to the corners and then shaded as a whole by one light from the top
    left (an edge facing up / left is lit, one facing down / right is shaded) and outlined in ink, so a
    mirrored corner is lit correctly, not just flipped.
Crests (the ornate panel's skull keystone, the header's gem finials, the divider's skull) are separate
small PNGs that UiTheme draws on top of a frame at a fixed size (UiArtData.CRESTS), so they never stretch.

Colours: rings, ornaments and outlines use palette colours only. The fills keep the UI's own fill colours
(UiTheme.BG, BG_HOVER and the selected / evolution fills) and the gradient shades mixed from them, which
are UI-only darks between the palette's ink and its first violet shade; sprites never use them.

Logo. The wordmark is an image-AI source converted with tools/prepare_sprite.py (grid mode, 90 art
px tall, --ramps violet,bone,soul --inside-outline --no-prune --no-levels --no-center --out <png>);
`logo` then applies the hand fixes listed in fix_logo() (the skull in the O redrawn symmetric with
soul-glow eye glints) and writes assets/ui/logo.png. The source is archived in art_source/ui/logo.png.

Icon. `icon` cuts the O (the pointed shield with the skull and its soul flame) out of the logo and
centres it on a dark violet badge: assets/ui/icon.png (project.godot config/icon), 64 art px drawn
at 2x = 128 px so the window manager scales it down cleanly.

Requires Pillow and numpy.
"""

import argparse
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixel_palette import Palette, hex_to_rgb  # noqa: E402  (tools/ sibling module)

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# Output folder of the kit (UiArtData.ROOT).
UI_DIR = ROOT / "assets" / "ui"
# Data file holding SLICE, SLICE_V, CENTER and CRESTS (UiArtData), the 9-slice contract with the game.
UI_DATA = ROOT / "scripts" / "data" / "ui_art_data.gd"

# The locked palette: name -> (r, g, b).
PAL = {c["name"]: hex_to_rgb(c["hex"]) for c in Palette().colors}

# UI-only fill colours (opaque copies of the UiTheme / screen fills; never used by sprites).
FILL = {
    "base": hex_to_rgb("#140D1F"),  # UiTheme.BG: panels and buttons.
    "hover": hex_to_rgb("#331C4D"),  # UiTheme.BG_HOVER: hovered button.
    "pressed": PAL["violet_deep"],  # UiTheme.BG_PRESSED (0.30, 0.16, 0.42) ~ violet_deep.
    "gold": hex_to_rgb("#3D2614"),  # Selected tile (pre-run SELECTED_BG, character picker, Hyper ON_BG).
    "gold_hover": hex_to_rgb("#4D311B"),  # Selected tile, hovered (lightened 0.08).
    "evo": hex_to_rgb("#2B1C0A"),  # Evolution card (level-up panel).
    "evo_hover": hex_to_rgb("#422B0F"),  # Evolution card, hovered.
    "evo_pressed": hex_to_rgb("#523814"),  # Evolution card, pressed.
    "crimson": hex_to_rgb("#420D14"),  # Active run modifier (pre-run ACTIVE_BG).
    "crimson_hover": hex_to_rgb("#58161E"),  # Active run modifier, hovered.
    "crimson_base": hex_to_rgb("#1F0A10"),  # Crimson ornate panel / header / ribbon (a dark crimson BG).
    "gold_base": hex_to_rgb("#1E140C"),  # Gold ornate panel / header / ribbon (a dark gold BG).
    "socket": hex_to_rgb("#0B0712"),  # HUD slot socket (recessed, darker than BG).
    "track": hex_to_rgb("#0B0712"),  # Scroll bar and slider track.
}

# Ring colour sets per accent: (outline ink, (lit, shade) of the bright ring, (lit, shade) of the inner
# ring, ornament colours (light, mid, ink)). "hover" sets brighten the rings by one shade.
ACCENTS = {
    "violet": ("ink_violet", ("violet_glow", "violet"), ("violet", "violet_deep"), ("bone", "bone_mid", "ink_warm")),
    "violet_hover": ("ink_violet", ("violet_flare", "violet_glow"), ("violet_glow", "violet"), ("bone", "bone_mid", "ink_warm")),
    "violet_pressed": ("ink_violet", ("violet", "violet_glow"), ("violet_deep", "violet"), ("bone_mid", "bone_shade", "ink_warm")),
    "gold": ("ink_warm", ("gold_light", "gold"), ("gold", "brown_light"), ("gold_light", "gold", "ink_warm")),
    "gold_hover": ("ink_warm", ("holy_white", "gold_light"), ("gold_light", "gold"), ("holy_white", "gold_light", "ink_warm")),
    "gold_pressed": ("ink_warm", ("gold", "gold_light"), ("brown_light", "gold"), ("gold", "brown_light", "ink_warm")),
    "crimson": ("ink_red", ("crimson", "crimson_dark"), ("crimson_dark", "crimson_dark"), ("bone", "bone_mid", "ink_red")),
    "crimson_hover": ("ink_red", ("flame", "crimson"), ("crimson", "crimson_dark"), ("bone", "bone_mid", "ink_red")),
    "soul": ("ink_green", ("soul_glow", "soul"), ("soul", "soul_dark"), ("bone", "bone_mid", "ink_warm")),
    "soul_hover": ("ink_green", ("soul_glow", "soul_glow"), ("soul_glow", "soul"), ("bone", "bone_mid", "ink_warm")),
    "dim": ("ink_violet", ("violet_deep", "violet_deep"), ("ink_violet", "ink_violet"), ("bone_shade", "bone_shade", "ink_warm")),
    "dim_hover": ("ink_violet", ("violet", "violet_deep"), ("violet_deep", "violet_deep"), ("bone_mid", "bone_shade", "ink_warm")),
    "grey": ("ink_cold", ("grey", "grey_dark"), ("grey_dark", "grey_dark"), ("grey_light", "grey", "ink_cold")),
}

# Ornament material ramps per accent (the accent part before any "_hover" / "_pressed"):
# bone = (lit, mid, shade) of bone ornaments; gem = (lit, mid, shade) of the set gems; glint = the 1-texel
# sparkle on a gem's lit corner (None = no glint).
ORNAMENT = {
    "violet": {"bone": ("bone", "bone_mid", "bone_shade"), "gem": ("violet_flare", "violet_glow", "violet"),
               "glint": "holy_white"},
    "gold": {"bone": ("bone", "bone_mid", "bone_shade"), "gem": ("gold_light", "gold", "brown_light"),
             "glint": "holy_white"},
    "crimson": {"bone": ("bone", "bone_mid", "bone_shade"), "gem": ("flame", "crimson", "crimson_dark"),
                "glint": "gold_light"},
    "soul": {"bone": ("bone", "bone_mid", "bone_shade"), "gem": ("soul_glow", "soul", "soul_dark"),
             "glint": "holy_white"},
    "dim": {"bone": ("bone_mid", "bone_shade", "steel_dark"), "gem": ("violet", "violet_deep", "ink_violet"),
            "glint": None},
    "grey": {"bone": ("grey_light", "grey", "grey_dark"), "gem": ("grey", "grey_dark", "ink_cold"), "glint": None},
}

# Gradient tint per accent: the colour the fill's lit top rows are mixed toward.
TINT = {"violet": "violet", "gold": "brown_light", "crimson": "crimson", "soul": "soul_dark", "dim": "violet_deep",
        "grey": "grey_dark", "bone": "violet_deep"}
# Share of the tint mixed into the fill per gradient level above 0 (level 2 = twice this).
TINT_STEP = 0.075
# Share of black mixed into the fill per gradient level below 0.
DARK_STEP = 0.2

# 4 x 4 Bayer matrix (ordered dither thresholds 0-15); period 4 divides CENTER, so tiled fills repeat cleanly.
BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))

# Legacy corner stamp kept for the app icon badge (make_icon): row strings, '.' = keep, 'L' / 'M' / 'K' = the
# accent's ornament light / mid / ink colour. Offsets are (x, y) of the top-left.
STUD = (["..K..",
         ".KLK.",
         "KLLMK",
         ".KMK.",
         "..K.."], (1, 1))  # A small bone stud on the chamfer.

# --- Ornament masks (top-left corner as drawn; mirrored by code) ------------------------------------------
# Characters: '.' keep the frame pixel, 'B' bone (mid-toned body), 'W' white bone (light body: skulls),
# 'G' gem, 'A' accent metal (the frame's bright ring ramp), 'K' ink (the frame's outline ink),
# 'S' socket dark (FILL["socket"]). Bone, white bone, gems and metal are shaded by shade_layer() and get a
# 1-texel ink outline where they meet untouched pixels.

def mask_rows(size: tuple, cells: dict) -> list:
    """Row strings (see the ornament masks) of a w x h mask from {(x, y): char} cells."""
    w, h = size
    return ["".join(cells.get((x, y), ".") for x in range(w)) for y in range(h)]


def rosette(cells: dict, cx: float, cy: float, gem: float, ink: float, bone: float) -> None:
    """Adds a round bone rosette centred on (cx, cy) to `cells`: a gem out to radius `gem`, an ink setting
    out to `ink` and bone out to `bone` (texels)."""
    for y in range(int(cy - bone) - 1, int(cy + bone) + 2):
        for x in range(int(cx - bone) - 1, int(cx + bone) + 2):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d <= gem:
                cells[(x, y)] = "G"
            elif d <= ink:
                cells[(x, y)] = "K"
            elif d <= bone:
                cells[(x, y)] = "B"


def _panel_cap() -> list:
    """Panel corner (frame: 5 rings, chamfer 3), upper triangle: a small bone rosette with a gem set in
    the cut corner and a pointed bone arm along the bevel band."""
    cells = {}
    for y in (1, 2, 3):
        for x in range(7, 9 if y != 2 else 10):
            cells[(x, y)] = "B"
    rosette(cells, 4.5, 4.5, 1.2, 2.2, 3.7)
    return mask_rows((12, 12), cells)


# Panel corner cap, upper triangle (mirrored across the diagonal by place(transpose=True)).
PANEL_CAP = _panel_cap()


def _card_cap() -> list:
    """Card corner (frame: 5 rings, a dark channel, an inner rail; chamfer 3), upper triangle: the panel
    rosette and arm plus a thin bone bracket along the inner rail ending in a serif bar."""
    cells = {(x, y): ch for y, row in enumerate(_panel_cap()) for x, ch in enumerate(row) if ch != "."}
    for x in range(8, 12):
        cells[(x, 6)] = "B"
    for y in (5, 6, 7):  # A serif bar across the arm's end.
        cells[(12, y)] = "B"
    return mask_rows((14, 14), cells)


# Card corner, upper triangle.
CARD_CAP = _card_cap()


def _ornate_corner() -> list:
    """Ornate corner (frame: 5-ring moulding, a bone inlay, ink, a dark channel, the inner rail; chamfer 6),
    upper triangle: a bone rosette with a large gem in the cut corner, a 3-texel bone arm over the inlay
    with a knuckle and a thorn, ending in a spiral curl that hooks inward."""
    cells = {}
    rows = {3: 19, 4: 20, 5: 21}  # Arm rows -> last x.
    for y, x1 in rows.items():
        for x in range(10, x1 + 1):
            cells[(x, y)] = "B"
    for x in range(12, 15):  # Knuckle: the arm swells by a texel above and below.
        cells[(x, 2)] = "B"
        cells[(x, 6)] = "B"
    cells[(16, 2)] = "B"  # Thorn.
    cells[(17, 1)] = "B"
    curl = {6: (19, 21), 7: (19, 21), 8: (19, 21), 9: (18, 20), 10: (15, 19), 11: (16, 18)}
    for y, (x0, x1) in curl.items():
        for x in range(x0, x1 + 1):
            cells[(x, y)] = "B"
    for x, y in ((15, 8), (16, 8), (15, 9), (16, 9), (16, 7)):  # The spiral's inner end.
        cells[(x, y)] = "B"
    rosette(cells, 7.0, 7.0, 2.3, 3.3, 5.4)
    return mask_rows((26, 26), cells)


# Ornate panel corner, upper triangle.
ORNATE_CORNER = _ornate_corner()

# A small skull (11 x 12): white bone with ink eye sockets holding a gem glint, a nose and a jaw.
SKULL = [
    "...WWWWW...",
    ".WWWWWWWWW.",
    "WWWWWWWWWWW",
    "WWWWWWWWWWW",
    "WKKKWWWKKKW",
    "WKGKWWWKGKW",
    "WKKKWWWKKKW",
    ".WWWWKWWWW.",
    "..WWKKKWW..",
    "..WWWWWWW..",
    "..WKWKWKW..",
    "...WWWWW...",
]

# The skull keystone crest of the ornate panel: a wedge-shaped stone in the accent's frame colours with the
# skull set in it, flanked by bone wings (drawn by keystone()).
KEYSTONE_SIZE = (60, 26)  # Crest size (texels): UiArtData.CRESTS["ornate"] offsets assume it.

# Header finial crest (14 x 14): a bone diamond holding a gem (drawn procedurally by finial()).
FINIAL_SIZE = 14

# Divider crest (33 x 15): the skull flanked by bone bars ending in small gem diamonds (divider_crest()).
DIVIDER_CREST_SIZE = (33, 15)

# Slider grabber icon (12 x 20) per state: a bone-rimmed gem pommel (grabber()).
GRABBER_SIZE = (12, 20)


def read_slices() -> tuple:
    """Parses CENTER, SLICE and SLICE_V from scripts/data/ui_art_data.gd -> (center, {kind: (h margin,
    v margin)})."""
    text = UI_DATA.read_text()
    center = int(re.search(r"const CENTER: int = (\d+)", text).group(1))  # Stretched centre texels.

    def table(name: str) -> dict:
        block = re.search(r"const %s: Dictionary = \{(.*?)\n\}" % name, text, re.S).group(1)  # Dictionary body.
        return {k: int(v) for k, v in re.findall(r'"(\w+)": (\d+)', block)}  # kind -> margin.

    h = table("SLICE")
    v = table("SLICE_V")
    return center, {k: (m, v.get(k, m)) for k, m in h.items()}


def read_crests() -> dict:
    """Parses CRESTS from ui_art_data.gd -> {kind: [(crest, ax, ay, ox, oy), ...]} (for the preview)."""
    text = UI_DATA.read_text()
    block = re.search(r"const CRESTS: Dictionary = \{(.*?)\n\}", text, re.S).group(1)
    out = {}
    for kind, body in re.findall(r'"(\w+)": \[(\[.*?\])\],', block):
        out[kind] = [(n, float(a), float(b), float(c), float(d)) for n, a, b, c, d in
                     re.findall(r'\["(\w+)", ([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\]', body)]
    return out


def _rgb(c) -> tuple:
    """Colour name or RGB tuple -> RGB tuple."""
    return PAL[c] if isinstance(c, str) else c


def _mix(a, b, t: float) -> tuple:
    """Colour a mixed toward b by t (0-1), as an RGB tuple of ints."""
    a, b = _rgb(a), _rgb(b)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ring_index(x: int, y: int, w: int, h: int, chamfer: int) -> int:
    """Ring of texel (x, y) in a w x h frame with corners cut `chamfer` texels deep (0 = the outer ring,
    negative = outside the cut corner)."""
    dx = min(x, w - 1 - x)  # Distance to the nearer side edge.
    dy = min(y, h - 1 - y)  # Distance to the nearer top / bottom edge.
    return min(dx, dy, dx + dy - chamfer)


def ring_frame(n: int, rings: list, fill, chamfer: int, w: int = 0, h: int = 0) -> np.ndarray:
    """An n x n (or w x h) RGBA frame: rings[k] = (lit, shade) colour names / RGB or None (transparent)
    for the k-th 1-texel ring from the outside; pixels inside the rings get `fill` (RGB or None).
    Corners are cut diagonally `chamfer` texels deep. Lit = top and left edges."""
    w = w or n
    h = h or n
    img = np.zeros((h, w, 4), np.uint8)  # Output RGBA.
    for y in range(h):
        for x in range(w):
            dc = ring_index(x, y, w, h, chamfer)
            if dc < 0:
                continue
            if dc < len(rings):
                pair = rings[dc]
                if pair is None:
                    continue
                dx = min(x, w - 1 - x)
                dy = min(y, h - 1 - y)
                lit = (y < h / 2) if dy <= dx else (x < w / 2)  # Top or left edge.
                col = pair[0] if lit else pair[1]
            else:
                col = fill
                if col is None:
                    continue
            img[y, x] = (*_rgb(col), 255)
    return img


def gradient_fill(img: np.ndarray, inside, fill, tint, top: tuple, bottom: tuple) -> None:
    """Paints the pixels where inside(x, y) is true with an ordered-dither vertical gradient of `fill`.
    top = (rows, level): `level` gradient levels at the first inside row of each column, fading linearly to
    0 over `rows` rows; bottom = the same from the last inside row upward (use a negative level to darken).
    Level k > 0 mixes k * TINT_STEP of `tint` into the fill, k < 0 mixes -k * DARK_STEP of black."""
    h, w = img.shape[:2]
    for x in range(w):
        ys = [y for y in range(h) if inside(x, y)]
        if not ys:
            continue
        y0, y1 = ys[0], ys[-1]
        for y in ys:
            v = 0.0  # Gradient level (fractional).
            if top[0] > 0:
                v += top[1] * max(0.0, 1.0 - (y - y0) / top[0])
            if bottom[0] > 0:
                v += bottom[1] * max(0.0, 1.0 - (y1 - y) / bottom[0])
            lo = int(np.floor(v))
            frac = v - lo
            level = lo + (1 if frac * 16.0 > BAYER[y % 4][x % 4] + 0.5 else 0)  # Ordered dither.
            if level > 0:
                col = _mix(fill, tint, level * TINT_STEP)
            elif level < 0:
                col = _mix(fill, (0, 0, 0), min(1.0, -level * DARK_STEP))
            else:
                col = _rgb(fill)
            img[y, x] = (*col, 255)


def kit_frame(w: int, h: int, rings: list, fill, chamfer: int, tint=None, top=(0, 0.0), bottom=(0, 0.0)) -> np.ndarray:
    """A ring frame (see ring_frame) whose inside is a dithered vertical gradient of `fill` (see
    gradient_fill); `fill` None leaves the centre transparent."""
    img = ring_frame(0, rings, None, chamfer, w=w, h=h)
    if fill is not None:
        n = len(rings)
        gradient_fill(img, lambda x, y: ring_index(x, y, w, h, chamfer) >= n, fill, tint or fill, top, bottom)
    return img


def place(layer: dict, rows: list, ox: int = 0, oy: int = 0, w: int = 0, h: int = 0, corners: str = "tl",
          transpose: bool = False) -> None:
    """Writes mask `rows` (see the ornament masks) into `layer` ({(x, y): char}) at offset (ox, oy) for
    each corner in `corners` ("tl", "tr", "bl", "br" or "all"), mirrored inside a w x h image; transpose
    also writes the mask mirrored across its diagonal (for corner art drawn as its upper triangle)."""
    cells = []
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch != ".":
                cells.append((ox + c, oy + r, ch))
                if transpose:
                    cells.append((ox + r, oy + c, ch))
    for corner in (("tl", "tr", "bl", "br") if corners == "all" else corners.split(",")):
        for x, y, ch in cells:
            if corner in ("tr", "br"):
                x = w - 1 - x
            if corner in ("bl", "br"):
                y = h - 1 - y
            layer[(x, y)] = ch


def shade_layer(img: np.ndarray, layer: dict, accent: str, ink, outline: bool = True, metal: tuple = None,
                margins: tuple = None) -> None:
    """Draws a material layer ({(x, y): char}) onto img with one light from the top left: a texel whose
    up or left neighbour is another material is lit, else one whose down or right neighbour is another
    material is shaded, else it takes the body tone ('B' bone and 'A' metal: mid; 'W' white bone: lit, its
    shaded edge mid and its bottom-right corner shade). Gems get a glint on their top-left corner. With
    `outline`, untouched texels 4-adjacent to bone / gem / metal turn `ink`. margins = the frame's 9-slice
    (h, v) margins: every ornament texel and its outline must lie in the corner squares AND one texel clear
    of the tiled band, else this raises: the game tiles the edges and the centre, and at a tile seam the
    filter blends with the texel just outside the band, so that texel must continue the tiled pattern."""
    h, w = img.shape[:2]
    if margins:
        hm, vm = margins
        for (x, y) in layer:
            for nx, ny in ((x, y), (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (hm - 2 < nx < w - hm + 1) or (vm - 2 < ny < h - vm + 1):
                    if (nx, ny) == (x, y) or (outline and layer.get((x, y)) in tuple("BWGA") and (nx, ny) not in layer):
                        raise ValueError("ornament texel (%d, %d) outside the corner squares" % (nx, ny))
    orn = ORNAMENT[accent.split("_")[0]]
    ramps = {"B": orn["bone"], "W": orn["bone"], "G": orn["gem"], "A": metal or orn["bone"]}

    def same(x: int, y: int, ch: str) -> bool:
        return layer.get((x, y)) == ch or (ch in "BW" and layer.get((x, y)) in ("B", "W"))

    for (x, y), ch in layer.items():
        if not (0 <= x < w and 0 <= y < h):
            continue
        if ch == "K":
            col = ink
        elif ch == "S":
            col = FILL["socket"]
        else:
            lit_c, mid_c, shade_c = ramps[ch]
            up, left = same(x, y - 1, ch), same(x - 1, y, ch)
            down, right = same(x, y + 1, ch), same(x + 1, y, ch)
            if not up or not left:
                col = lit_c
            elif not down or not right:
                col = mid_c if ch == "W" and (down or right) else shade_c
            else:
                col = lit_c if ch == "W" else mid_c
            if ch == "G" and orn["glint"] and not up and not left and same(x + 1, y + 1, "G") \
                    and not same(x - 1, y - 1, "G"):
                col = orn["glint"]
        img[y, x] = (*_rgb(col), 255)
    if outline:
        for (x, y), ch in list(layer.items()):
            if ch not in "BWGA":
                continue
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in layer:
                    img[ny, nx] = (*_rgb(ink), 255)


def stamp(img: np.ndarray, ornament: tuple, colours: tuple, corners: str = "all") -> None:
    """Legacy: draws `ornament` (rows, offset) at the frame's corners, mirrored. colours = (light, mid,
    ink). Kept for the app icon badge (make_icon)."""
    rows, (ox, oy) = ornament
    h, w = img.shape[:2]
    key = {"L": colours[0], "M": colours[1], "K": colours[2]}
    for flip_x in (False, True):
        for flip_y in (False, True):
            if corners == "top" and flip_y:
                continue
            for r, row in enumerate(rows):
                for c, ch in enumerate(row):
                    if ch == ".":
                        continue
                    x = ox + c
                    y = oy + r
                    x = w - 1 - x if flip_x else x
                    y = h - 1 - y if flip_y else y
                    # On the bottom corners (the shaded side) the ornament's light becomes its mid.
                    col = colours[1] if (flip_y and ch == "L") else key[ch]
                    img[y, x] = (*_rgb(col), 255)


def size_of(kind: str, center: int, slices: dict) -> tuple:
    """(width, height) in texels of a 9-slice PNG of `kind`."""
    hm, vm = slices[kind]
    return 2 * hm + center, 2 * vm + center


# --- Frame kinds -----------------------------------------------------------------------------------------

def button(accent: str, fill, w: int, h: int, vm: int, pressed: bool = False) -> np.ndarray:
    """Button / selectable tile: ink outline, bevelled bright ring, inner ring, ink gap, chamfer 2, then
    the gradient fill (inverted when pressed); a 2-texel glint on the bright ring by the top-left cut."""
    ink, bright, inner, _orn = ACCENTS[accent]
    rings = [(ink, ink), bright, inner, (ink, ink)]
    base = accent.split("_")[0]
    grad = vm - len(rings)  # Gradient rows inside the top / bottom margin.
    top, bottom = ((grad, 2.0), (grad, -1.5)) if not pressed else ((grad, -1.5), (grad, 1.5))
    img = kit_frame(w, h, rings, fill, 2, TINT.get(base), top, bottom)
    if not pressed:
        glint = ORNAMENT.get(base, ORNAMENT["violet"])["gem"][0] if base not in ("dim",) else bright[0]
        for x, y in ((3, 1), (4, 1), (1, 3)):  # Sparkle on the lit bevel next to the cut corner.
            img[y, x] = (*_rgb(glint), 255)
    return img


def panel(accent: str, fill, w: int, h: int, vm: int) -> np.ndarray:
    """Panel / window: a raised moulding (ink, inner, bright, inner, ink), chamfer 3, gradient fill, and a
    bone corner cap with a gem in each corner."""
    ink, bright, inner, _orn = ACCENTS[accent]
    rings = [(ink, ink), inner, bright, inner, (ink, ink)]
    grad = vm - len(rings)
    img = kit_frame(w, h, rings, fill, 3, TINT.get(accent), (grad, 2.0), (grad, -1.5))
    layer = {}
    place(layer, PANEL_CAP, 0, 0, w, h, "all", transpose=True)
    shade_layer(img, layer, accent, ink, margins=((w - 4) // 2, vm))
    return img


def card(accent: str, state: str, fill, w: int, h: int, vm: int) -> np.ndarray:
    """Level-up card: the panel moulding, a dark channel and an inner rail (a double frame), chamfer 3,
    gradient fill (inverted when pressed), and a bone cap plus an inner bracket in each corner."""
    ink, bright, inner, _orn = ACCENTS[accent]
    rings = [(ink, ink), inner, bright, inner, (ink, ink), (FILL["socket"], FILL["socket"]), inner, (ink, ink)]
    base = accent.split("_")[0]
    grad = vm - len(rings)
    top, bottom = ((grad, 2.0), (grad, -1.5)) if state != "pressed" else ((grad, -1.5), (grad, 1.5))
    img = kit_frame(w, h, rings, fill, 3, TINT.get(base), top, bottom)
    layer = {}
    place(layer, CARD_CAP, 0, 0, w, h, "all", transpose=True)
    shade_layer(img, layer, base, ink, margins=((w - 4) // 2, vm))
    return img


def ornate(accent: str, fill, w: int, h: int, vm: int) -> np.ndarray:
    """Ornate hero panel: an outer moulding (ink, bright, inner, ink), a bone inlay line between inks, a
    dark channel, an inner rail and ink, chamfer 6, a long gradient fill, and bone filigree corners
    (rosette, gem, knuckled arm, thorn, curl) mirrored to all four corners."""
    ink, bright, inner, _orn = ACCENTS[accent]
    sock = FILL["socket"]
    bone = ORNAMENT[accent]["bone"]
    rings = [(ink, ink), bright, inner, (ink, ink), (bone[1], bone[2]), (ink, ink), (sock, sock), inner,
             (ink, ink)]
    grad = vm - len(rings)
    img = kit_frame(w, h, rings, fill, 6, TINT.get(accent), (grad, 2.5), (grad, -2.0))
    layer = {}
    place(layer, ORNATE_CORNER, 0, 0, w, h, "all", transpose=True)
    shade_layer(img, layer, accent, ink, margins=((w - 4) // 2, vm))
    return img


def header(accent: str, fill, w: int, h: int) -> np.ndarray:
    """Header band: a hexagonal plate (45-degree pointed end caps from a chamfer of h // 2 - 2) with a double
    rule (ink, bright, inner, ink) and a gradient fill; the finial crests are separate (finial())."""
    ink, bright, inner, _orn = ACCENTS[accent]
    rings = [(ink, ink), bright, inner, (ink, ink)]
    return kit_frame(w, h, rings, fill, h // 2 - 2, TINT.get(accent), (5, 2.0), (5, -1.5))


def ribbon(accent: str, fill, w: int, h: int, hm: int, vm: int) -> np.ndarray:
    """Banner ribbon: a front band (rows 0 .. h-5: ink, hem, inner hem, ink, a stitched bone line, the
    gradient fill) and, behind each end, a darker cloth tail with a swallow-tail notch that hangs from the
    band's lower half to 4 texels below it, joined to the band by a shaded fold. The tails lie wholly in
    the bottom 9-slice margin, so they keep their shape at any ribbon height."""
    ink, bright, inner, _orn = ACCENTS[accent]
    img = np.zeros((h, w, 4), np.uint8)
    drop = 4  # Texels the tails hang below the band.
    top = h - vm + 2  # First tail row (inside the bottom margin).
    bx = hm - 6  # Band's left edge (texels); the tail shows to its left.
    notch = 6  # Deepest swallow-tail notch (texels).
    bh = h - drop  # Band height.
    mid = (top + h - 1) / 2  # Tail's middle row (the notch's tip).
    body = _mix(inner[1], (0, 0, 0), 0.2)  # Tail cloth: the accent's inner shade, darkened.
    hem = inner[0]  # Tail hem (top row).
    shadow = _mix(body, (0, 0, 0), 0.45)  # Cloth in the band's shadow and in the fold.
    for side in (0, 1):
        def put(x: int, y: int, col) -> None:
            img[y, x if side == 0 else w - 1 - x] = (*_rgb(col), 255)
        for y in range(top, h):
            d = int(round(notch * (1.0 - abs(y - mid) / (mid - top))))  # Notch depth at row y (a V).
            for x in range(d, bx + 2):
                if x == d or y == top or y == h - 1:
                    col = ink
                elif y == top + 1:
                    col = hem
                elif x >= bx - 3 or y == h - 2:
                    col = shadow
                else:
                    col = body
                put(x, y, col)
        for k in range(drop + 1):  # The fold: a dark triangle under the band's end.
            y = bh - 1 + k
            for x in range(bx, bx + k + 1):
                put(x, y, ink if x == bx + k or y == h - 1 else shadow)
    band = kit_frame(w - 2 * bx, bh, [(ink, ink), bright, inner, (ink, ink)], fill, 2, TINT.get(accent),
                     (vm - 6, 2.0), (vm - 6 - drop, -1.5))
    stitch = ORNAMENT[accent]["bone"][2]  # Stitches: the bone ramp's shade.
    for x in range(5, band.shape[1] - 5):
        if x % 4 < 2:
            band[5, x] = (*_rgb(stitch), 255)
            band[bh - 6, x] = (*_rgb(stitch), 255)
    mask = band[..., 3] > 0
    img[0:bh, bx:w - bx][mask] = band[mask]
    return img


def track(w: int, h: int) -> np.ndarray:
    """Slider track: a recessed socket: a rim darker on the top / left and lighter on the bottom / right
    (light falls into it from above), an ink gap and a dark fill shadowed at the top."""
    return kit_frame(w, h, [("violet_deep", "violet"), ("ink_violet", "ink_violet")], FILL["track"], 1,
                     "violet_deep", (1, -1.0), (1, 1.0))


def slider_fill(w: int, h: int, hover: bool) -> np.ndarray:
    """Slider fill: a raised violet bar (ink, lit top, violet body, shaded bottom), brighter on hover."""
    lit, body, shade = ("violet_flare", "violet_glow", "violet") if hover else ("violet_glow", "violet", "violet_deep")
    img = ring_frame(0, [("ink_violet", "ink_violet")], body, 1, w=w, h=h)
    for x in range(1, w - 1):
        img[1, x] = (*PAL[lit], 255)
        img[h - 2, x] = (*PAL[shade], 255)
    return img


# --- Crests and icons -------------------------------------------------------------------------------------

def keystone(accent: str, fill) -> np.ndarray:
    """The ornate panel's skull keystone (KEYSTONE_SIZE): a wedge (wide top, narrow bottom, cut corners)
    framed like the panel moulding, a dark gradient face and the skull with gem eyes, between two bone
    wings that lie along the frame's inlay (crest rows 12-14 = frame rows 3-5 at the 9-texel lift) and end
    in small gem rosettes."""
    w, h = KEYSTONE_SIZE
    sw = 28  # Wedge width at the top (texels).
    x0 = (w - sw) // 2  # Wedge left edge.
    ink, bright, inner, _orn = ACCENTS[accent]
    img = np.zeros((h, w, 4), np.uint8)
    wings = {}
    for side in (0, 1):
        cells = {}
        for x in range(5, x0 + 2):
            for y in (12, 13, 14):
                cells[(x, y)] = "B"
        rosette(cells, 4.0, 13.0, 1.2, 2.2, 3.6)
        for (x, y), ch in cells.items():
            wings[(x if side == 0 else w - 1 - x, y)] = ch
    shade_layer(img, wings, accent, ink)
    taper = 4  # Texels each side of the wedge narrows from top to bottom.

    def ring(x: int, y: int) -> int:
        """Ring of (x, y) in the wedge (negative = outside)."""
        hw = sw / 2 - taper * y / (h - 1)
        dx = int(np.floor(hw - abs(x + 0.5 - w / 2)))  # Distance inside the slanted side.
        dy = min(y, h - 1 - y)
        return min(dx, dy, dx + dy - 3)

    rings = [(ink, ink), bright, inner, (ink, ink)]
    for y in range(h):
        for x in range(w):
            r = ring(x, y)
            if 0 <= r < len(rings):
                lit = y < 3 or (x < w / 2 and r != 0 and y < h - 3)
                img[y, x] = (*_rgb(rings[r][0] if lit else rings[r][1]), 255)
    gradient_fill(img, lambda x, y: ring(x, y) >= len(rings), fill, TINT.get(accent), (6, 2.0), (6, -1.5))
    layer = {}
    place(layer, SKULL, (w - 11) // 2, 7, w, h)
    shade_layer(img, layer, accent, ink)
    return img


def finial(accent: str) -> np.ndarray:
    """Header finial crest (FINIAL_SIZE square): a bone diamond holding a gem, outlined in ink."""
    n = FINIAL_SIZE
    ink = ACCENTS[accent][0]
    img = np.zeros((n, n, 4), np.uint8)
    c = (n - 1) / 2
    layer = {}
    for y in range(n):
        for x in range(n):
            d = abs(x - c) + abs(y - c)
            if d <= 2.5:
                layer[(x, y)] = "G"
            elif d <= 3.5:
                layer[(x, y)] = "K"
            elif d <= 5.5:
                layer[(x, y)] = "B"
    shade_layer(img, layer, accent, ink)
    return img


def divider_line(accent: str, w: int, h: int) -> np.ndarray:
    """Divider strip (w x h, h = UiArtData.DIVIDER_LINE): an ink / accent / ink rule through the middle
    three rows, tapering at the ends to a bone dot."""
    ink, bright, inner, _orn = ACCENTS[accent]
    img = np.zeros((h, w, 4), np.uint8)
    m = h // 2
    for x in range(w):
        img[m - 1, x] = (*_rgb(ink), 255)
        img[m, x] = (*_rgb(bright[1]), 255)
        img[m + 1, x] = (*_rgb(ink), 255)
    for side in (0, w - 1):
        img[m, side] = (*PAL["bone_mid"], 255)
    return img


def divider_crest(accent: str) -> np.ndarray:
    """Divider crest (DIVIDER_CREST_SIZE): the skull between two bone bars, each ending in a gem diamond."""
    w, h = DIVIDER_CREST_SIZE
    ink = ACCENTS[accent][0]
    img = np.zeros((h, w, 4), np.uint8)
    layer = {}
    cy = h // 2
    for side in (0, 1):
        for x in range(5, 11):  # Bone bar to the skull.
            for y in (cy - 1, cy, cy + 1):
                xx = x if side == 0 else w - 1 - x
                layer[(xx, y)] = "B"
        for y in range(h):  # Gem diamond at the outer end.
            for x in range(0, 8):
                d = abs(x - 3.5) + abs(y - cy)
                xx = x + 1 if side == 0 else w - 2 - x
                if d <= 2.0:
                    layer[(xx, y)] = "G"
                elif d <= 3.0:
                    layer[(xx, y)] = "B"
    place(layer, SKULL, (w - 11) // 2, (h - 12) // 2, w, h)
    shade_layer(img, layer, accent, ink)
    return img


def grabber(state: str) -> np.ndarray:
    """Slider grabber icon (GRABBER_SIZE): a cut-corner pommel, a 2-texel bone rim around a gem (violet;
    soul-teal when hovered / focused; dim when disabled)."""
    w, h = GRABBER_SIZE
    accent = {"normal": "violet", "hover": "soul", "disabled": "dim"}[state]
    img = np.zeros((h, w, 4), np.uint8)
    layer = {}
    for y in range(h):
        for x in range(w):
            r = ring_index(x, y, w, h, 3)
            if r < 0:
                continue
            layer[(x, y)] = "K" if r == 0 or r == 3 else ("B" if r < 3 else "G")
    for x in range(4, w - 4):  # A grip line across the gem.
        layer[(x, h // 2)] = "K"
    shade_layer(img, layer, accent, "ink_violet", outline=False)
    return img


def toggle(on: bool) -> np.ndarray:
    """CheckButton toggle icon (32 x 16): a socket (dark when off, soul-lit when on) and a bone knob with a
    gem (left and dim when off, right and soul-teal when on)."""
    w, h = 32, 16
    if on:
        img = kit_frame(w, h, [("ink_green", "ink_green"), ("soul", "soul_dark"), ("ink_green", "ink_green")],
                        PAL["soul_dark"], 3, "soul", (3, 2.0), (3, -1.5))
    else:
        img = kit_frame(w, h, [("ink_violet", "ink_violet"), ("violet_deep", "violet"),
                               ("ink_violet", "ink_violet")], FILL["socket"], 3, "violet_deep", (3, -1.0), (3, 1.0))
    layer = {}
    x0 = 18 if on else 2
    for y in range(12):
        for x in range(12):
            r = ring_index(x, y, 12, 12, 3)
            if r < 0:
                continue
            layer[(x0 + x, 2 + y)] = "K" if r == 0 else ("B" if r < 3 else ("K" if r == 3 else "G"))
    shade_layer(img, layer, "soul" if on else "dim", "ink_green" if on else "ink_violet", outline=False)
    return img


def make_frames(center: int, slices: dict) -> dict:
    """Every kit PNG: file stem -> RGBA array."""
    out = {}
    # Buttons (and selectable tiles): normal / hover / pressed / disabled, plus accent variants.
    w, h = size_of("button", center, slices)
    vm = slices["button"][1]
    for name, accent, fill in [
        ("violet_normal", "violet", FILL["base"]), ("violet_hover", "violet_hover", FILL["hover"]),
        ("violet_pressed", "violet_pressed", FILL["pressed"]), ("violet_disabled", "dim", FILL["base"]),
        ("gold_normal", "gold", FILL["gold"]), ("gold_hover", "gold_hover", FILL["gold_hover"]),
        ("crimson_normal", "crimson", FILL["crimson"]), ("crimson_hover", "crimson_hover", FILL["crimson_hover"]),
        ("soul_normal", "soul", FILL["base"]), ("soul_hover", "soul_hover", FILL["hover"]),
        ("dim_normal", "dim", FILL["base"]), ("dim_hover", "dim_hover", FILL["hover"]),
    ]:
        out["button_" + name] = button(accent, fill, w, h, vm, pressed=name.endswith("pressed"))
    # Panels.
    w, h = size_of("panel", center, slices)
    vm = slices["panel"][1]
    for accent, fill in [("violet", FILL["base"]), ("gold", FILL["base"]), ("dim", FILL["socket"])]:
        out["panel_%s_normal" % accent] = panel(accent, fill, w, h, vm)
    # Level-up cards.
    w, h = size_of("card", center, slices)
    vm = slices["card"][1]
    for accent, state, fill in [
        ("violet", "normal", FILL["base"]), ("violet_hover", "hover", FILL["hover"]),
        ("violet_pressed", "pressed", FILL["pressed"]),
        ("gold", "normal", FILL["evo"]), ("gold_hover", "hover", FILL["evo_hover"]),
        ("gold_pressed", "pressed", FILL["evo_pressed"]),
    ]:
        out["card_%s_%s" % (accent.split("_")[0], state)] = card(accent, state, fill, w, h, vm)
    # Focus ring: drawn FOCUS_EXPAND (3) outside the control: ink, soul-glow, soul around the control's own
    # border, with thick soul-glow corner brackets outlined in ink; open centre.
    w, h = size_of("focus", center, slices)
    img = ring_frame(0, [("ink_green", "ink_green"), ("soul_glow", "soul_glow"), ("soul", "soul")], None, 2,
                     w=w, h=h)
    layer = {}
    place(layer, ["......", ".GGGGG", ".GGGGG", ".GG...", ".GG...", ".GG..."], 0, 0, w, h, "all")
    shade_layer(img, layer, "soul", "ink_green", margins=slices["focus"])
    out["focus_soul_normal"] = img
    # HUD slot socket: recessed (lit bottom-right), a dark fill shadowed at the top; chamfer 3.
    w, h = size_of("slot", center, slices)
    out["slot_grey_normal"] = kit_frame(w, h, [("ink_cold", "ink_cold"), ("grey_dark", "grey"),
                                               ("ink_cold", "ink_cold")], FILL["socket"], 3, "grey_dark",
                                        (3, -1.0), (3, 1.0))
    # HUD bar frame: outline + bevelled violet edge, open centre (the code fill shows through).
    w, h = size_of("bar", center, slices)
    out["bar_violet_normal"] = ring_frame(0, [("ink_violet", "ink_violet"), ("violet", "violet_deep")], None, 2,
                                          w=w, h=h)
    # Tooltip: bone ring, gradient fill.
    w, h = size_of("tip", center, slices)
    out["tip_bone_normal"] = kit_frame(w, h, [("ink_warm", "ink_warm"), ("bone", "bone_mid"),
                                              ("ink_violet", "ink_violet")], FILL["base"], 2, "violet_deep",
                                       (4, 2.0), (4, -1.5))
    # Scroll bar track and grabber.
    w, h = size_of("scroll", center, slices)
    out["scroll_violet_normal"] = kit_frame(w, h, [("ink_violet", "ink_violet"), ("violet_deep", "violet_deep")],
                                            FILL["track"], 1)
    w, h = size_of("grab", center, slices)
    for state, ring, fill in [("normal", ("violet_glow", "violet_deep"), "violet"),
                              ("hover", ("violet_flare", "violet"), "violet_glow"),
                              ("pressed", ("violet", "violet_glow"), "violet_deep")]:
        out["grab_violet_%s" % state] = ring_frame(0, [("ink_violet", "ink_violet"), ring], fill, 1, w=w, h=h)
    # Separator: ink / violet / ink, with bone end dots.
    m = slices["line"][0]
    line = ring_frame(0, [("ink_violet", "ink_violet"), ("violet", "violet_deep")], "violet", 0, w=2 * m + center, h=3)
    line[1, 0] = (*PAL["bone_mid"], 255)
    line[1, -1] = (*PAL["bone_mid"], 255)
    out["line_violet_normal"] = line
    # CheckButton toggles (32 x 16).
    out["toggle_off"] = toggle(False)
    out["toggle_on"] = toggle(True)
    # --- Ornamented kinds: violet (default), gold (victory, evolution, selection), crimson (danger). ---
    fills = {"violet": FILL["base"], "gold": FILL["gold_base"], "crimson": FILL["crimson_base"]}
    for accent, fill in fills.items():
        w, h = size_of("ornate", center, slices)
        out["ornate_%s_normal" % accent] = ornate(accent, fill, w, h, slices["ornate"][1])
        out["ornate_%s_keystone" % accent] = keystone(accent, fill)
        w, h = size_of("header", center, slices)
        out["header_%s_normal" % accent] = header(accent, fill, w, h)
        out["header_%s_cap" % accent] = finial(accent)
        w, h = size_of("ribbon", center, slices)
        out["ribbon_%s_normal" % accent] = ribbon(accent, fill, w, h, *slices["ribbon"])
        w = size_of("divider", center, slices)[0]
        out["divider_%s_normal" % accent] = divider_line(accent, w, 5)
        out["divider_%s_crest" % accent] = divider_crest(accent)
    # Slider: track, fill (normal / hover) and grabber icons.
    w, h = size_of("track", center, slices)
    out["track_violet_normal"] = track(w, h)
    w, h = size_of("fill", center, slices)
    out["fill_violet_normal"] = slider_fill(w, h, False)
    out["fill_violet_hover"] = slider_fill(w, h, True)
    for state in ("normal", "hover", "disabled"):
        out["grabber_%s" % state] = grabber(state)
    return out


# --- Review sheet -----------------------------------------------------------------------------------------

def nine_slice(im: Image.Image, margins: tuple, w: int, h: int) -> Image.Image:
    """Draws a 9-slice frame at w x h like Godot's StyleBoxTexture with AXIS_STRETCH_MODE_TILE: corners
    kept, edges and centre tiled (texel for texel). margins = (h margin, v margin)."""
    hm, vm = margins
    out = Image.new("RGBA", (w, h))
    sw, sh = im.size
    src = np.array(im)
    dst = np.zeros((h, w, 4), np.uint8)
    cw, ch = sw - 2 * hm, sh - 2 * vm  # Centre size (texels).

    def map_axis(p: int, size: int, m: int, src_size: int, c: int) -> int:
        if p < m:
            return p
        if p >= size - m:
            return src_size - (size - p)
        return m + (p - m) % c

    for y in range(h):
        sy = map_axis(y, h, vm, sh, ch)
        for x in range(w):
            dst[y, x] = src[sy, map_axis(x, w, hm, sw, cw)]
    out.paste(Image.fromarray(dst, "RGBA"))
    return out


def framed(frames: dict, kind: str, accent: str, w: int, h: int, slices: dict, crests: dict,
           state: str = "normal") -> Image.Image:
    """A kit frame 9-sliced to w x h with its crests drawn on top (as UiTheme's KitStyleBox does), on a
    transparent canvas padded 12 texels on every side (crests may overhang)."""
    pad = 12
    canvas = Image.new("RGBA", (w + 2 * pad, h + 2 * pad))
    stem = "%s_%s_%s" % (kind, accent, state)
    if kind == "divider":
        line = Image.fromarray(frames[stem], "RGBA")
        strip = nine_slice(line, (slices[kind][0], 0), w, line.height)
        canvas.alpha_composite(strip, (pad, pad + (h - line.height) // 2))
    else:
        margins = (slices[kind][0], 0) if kind == "line" else slices[kind]  # The line stretches only sideways.
        canvas.alpha_composite(nine_slice(Image.fromarray(frames[stem], "RGBA"), margins, w, h), (pad, pad))
    for name, ax, ay, ox, oy in crests.get(kind, []):
        tex = Image.fromarray(frames["%s_%s_%s" % (kind, accent, name)], "RGBA")
        canvas.alpha_composite(tex, (pad + int(np.floor(w * ax + ox)), pad + int(np.floor(h * ay + oy))))
    return canvas


def preview(frames: dict, path: Path, slices: dict) -> None:
    """Writes a review sheet: every kind at typical sizes (layout px), crests on, enlarged 3x, on the
    menu backdrop colour, with a caption per sample."""
    crests = read_crests()
    scale = 3
    rows = [
        [("button", "violet", "normal", 150, 44), ("button", "violet", "hover", 150, 44),
         ("button", "violet", "pressed", 150, 44), ("button", "violet", "disabled", 150, 44),
         ("button", "gold", "normal", 150, 44), ("button", "crimson", "normal", 150, 44),
         ("button", "soul", "normal", 150, 30), ("button", "dim", "normal", 150, 30)],
        [("panel", "violet", "normal", 190, 120), ("panel", "gold", "normal", 190, 120),
         ("panel", "dim", "normal", 48, 48), ("card", "violet", "normal", 135, 170),
         ("card", "violet", "hover", 135, 170), ("card", "gold", "normal", 135, 170),
         ("tip", "bone", "normal", 120, 30), ("slot", "grey", "normal", 46, 46)],
        [("ornate", "violet", "normal", 300, 170), ("ornate", "gold", "normal", 300, 170),
         ("ornate", "crimson", "normal", 300, 170)],
        [("header", "violet", "normal", 260, 40), ("header", "gold", "normal", 260, 40),
         ("header", "crimson", "normal", 260, 28)],
        [("ribbon", "violet", "normal", 300, 56), ("ribbon", "gold", "normal", 300, 56),
         ("ribbon", "crimson", "normal", 300, 56)],
        [("divider", "violet", "normal", 260, 15), ("divider", "gold", "normal", 260, 15),
         ("divider", "crimson", "normal", 260, 15)],
        [("track", "violet", "normal", 150, 8), ("fill", "violet", "normal", 80, 8),
         ("fill", "violet", "hover", 80, 8), ("bar", "violet", "normal", 150, 14),
         ("scroll", "violet", "normal", 10, 90), ("grab", "violet", "normal", 10, 40),
         ("line", "violet", "normal", 150, 3), ("focus", "soul", "normal", 156, 50)],
    ]
    icons = ["grabber_normal", "grabber_hover", "grabber_disabled", "toggle_off", "toggle_on"]
    cells = []  # (image, caption) per sample.
    for row in rows:
        line = []
        for kind, accent, state, w, h in row:
            line.append((framed(frames, kind, accent, w, h, slices, crests, state),
                         "%s %s %s %dx%d" % (kind, accent, state, w, h)))
        cells.append(line)
    cells.append([(Image.fromarray(frames[n], "RGBA"), n) for n in icons])
    gap, cap = 8, 14
    sheet_w = max(sum(im.width * scale + gap for im, _ in line) for line in cells) + gap
    sheet_h = sum(max(im.height for im, _ in line) * scale + cap + gap for line in cells) + gap
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (8, 5, 13, 255))
    draw = ImageDraw.Draw(sheet)
    y = gap
    for line in cells:
        x = gap
        for im, caption in line:
            draw.text((x, y), caption, fill=(150, 140, 170, 255))
            sheet.alpha_composite(im.resize((im.width * scale, im.height * scale), Image.NEAREST), (x, y + cap))
            x += im.width * scale + gap
        y += max(im.height for im, _ in line) * scale + cap + gap
    sheet.save(path)


def fix_logo(src: Path, dst: Path) -> None:
    """Hand pixel fixes on the converted wordmark (palette colours only): the skull in the O is redrawn
    symmetric (the conversion left lopsided eye sockets) with a soul-glow glint in each eye socket."""
    im = Image.open(src).convert("RGBA")
    if im.size != (246, 90):
        raise SystemExit("logo: expected the 246 x 90 conversion, got %s" % (im.size,))
    key = {"a": "ink_violet", "i": "bone", "h": "bone_mid", "G": "soul_glow"}
    for y in range(44, 63):  # Clear the O's window to ink first.
        for x in range(107, 120):
            im.putpixel((x, y), (*PAL["ink_violet"], 255))
    skull = ["...iiiii...",
             ".iiiiiiiii.",
             "iiiiiiiiiih",
             "iiiiiiiiiih",
             "iiiiiiiiihh",
             "iaaaiiiaaah",
             "iaGaiiiaGah",
             "iaaaiiiaaah",
             "hiiiiaiiihh",
             ".hhiaaaihh.",
             "..hiiiiih..",
             "..iaiaiai..",
             "..hahahah..",
             "...hhhhh..."]
    for r, row in enumerate(skull):
        for c, ch in enumerate(row):
            if ch != ".":
                im.putpixel((108 + c, 46 + r), (*PAL[key[ch]], 255))
    im.save(dst)


def make_icon(logo: Path, dst: Path) -> None:
    """App icon: the logo's O (shield, skull, soul flame) on a dark violet badge, its flame rising over the
    badge's top edge. 64 x 64 art px, saved 2x (128 px). The O is cut out as the connected non-ink shape
    of the skull and the shield (so no bit of the R or the P comes along) and re-outlined in ink."""
    src = np.array(Image.open(logo).convert("RGBA"))
    ink = np.array(PAL["ink_violet"])
    crop = src[18:84, 99:130].copy()  # The O and the lower part of its flame (31 x 66).
    solid = (crop[..., 3] > 0) & (np.abs(crop[..., :3].astype(int) - ink).sum(-1) > 0)  # Coloured pixels.
    keep = np.zeros_like(solid)
    stack = [(30, 14), (32, 4)]  # Seeds: the skull (logo x 113, y 48) and the shield (logo x 103, y 50).
    while stack:
        y, x = stack.pop()
        if 0 <= y < solid.shape[0] and 0 <= x < solid.shape[1] and solid[y, x] and not keep[y, x]:
            keep[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    # Fill the O's window (ink between the skull and the shield) and outline everything 1 px in ink.
    rows = np.where(keep.any(1))[0]
    for y in rows:
        xs = np.where(keep[y])[0]
        keep[y, xs.min():xs.max() + 1] |= crop[y, xs.min():xs.max() + 1, 3] > 0
    grown = keep.copy()
    grown[1:] |= keep[:-1]
    grown[:-1] |= keep[1:]
    grown[:, 1:] |= keep[:, :-1]
    grown[:, :-1] |= keep[:, 1:]
    o = np.zeros_like(crop)
    o[keep] = crop[keep]
    o[grown & ~keep] = (*PAL["ink_violet"], 255)
    o_img = Image.fromarray(o, "RGBA")
    o_img = o_img.crop(o_img.getbbox())
    badge = ring_frame(0, [("ink_violet", "ink_violet"), ("violet", "violet_deep"), ("violet_deep", "ink_violet"),
                           ("ink_violet", "ink_violet")], FILL["base"], 5, w=60, h=54)
    stamp(badge, STUD, ACCENTS["violet"][3])
    canvas = Image.new("RGBA", (64, 64))
    canvas.alpha_composite(Image.fromarray(badge, "RGBA"), (2, 9))
    canvas.alpha_composite(o_img, ((64 - o_img.width) // 2, 60 - o_img.height))
    canvas.resize((128, 128), Image.NEAREST).save(dst)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", choices=("frames", "logo", "icon"))
    ap.add_argument("source", nargs="?", help="logo: the prepare_sprite.py conversion (246 x 90)")
    ap.add_argument("--preview", default="", help="frames: also write a review sheet here")
    args = ap.parse_args()
    UI_DIR.mkdir(parents=True, exist_ok=True)
    if args.command == "frames":
        center, slices = read_slices()
        frames = make_frames(center, slices)
        for name, arr in frames.items():
            Image.fromarray(arr, "RGBA").save(UI_DIR / (name + ".png"))
        print("wrote %d frame PNGs to %s" % (len(frames), UI_DIR))
        if args.preview:
            preview(frames, Path(args.preview), slices)
    elif args.command == "logo":
        if not args.source:
            raise SystemExit("logo: pass the converted PNG")
        fix_logo(Path(args.source), UI_DIR / "logo.png")
        print("wrote", UI_DIR / "logo.png")
    else:
        make_icon(UI_DIR / "logo.png", UI_DIR / "icon.png")
        print("wrote", UI_DIR / "icon.png")


if __name__ == "__main__":
    main()
