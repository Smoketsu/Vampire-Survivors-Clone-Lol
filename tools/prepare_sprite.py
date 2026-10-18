"""prepare_sprite.py: turn an AI-generated sprite into game-ready pixel art.

Usage (from the repo root):
    python3 tools/prepare_sprite.py <source image> <sprite key>            (grid mode, the default)
    e.g. python3 tools/prepare_sprite.py ~/Downloads/necro.png player/necromancer
    python3 tools/prepare_sprite.py <walk sheet> <sprite key> --frames 4   (walk cycle strip)
    python3 tools/prepare_sprite.py --legacy <source image> <sprite key>   (old smooth 3x sprite)
    python3 tools/prepare_sprite.py --anim <GIF or sheet> <effect id> [--frames N | --grid CxR] [--frame-px P]

Grid mode (GDD 15.0 "Art pass (true pixel art)", docs/art/ART_BIBLE.md):
  The sprite is rebuilt at its REAL size on the art grid: 1 art px = ART_SCALE (1)
  screen px at the 1280x720 layout, so a sprite whose on-screen height is
  SpriteData.HEIGHTS[key] = 56 px (the necromancer) is written 56 art px tall.
  Every pixel is one of the locked palette's colours (tools/palette.json), fully
  opaque or fully transparent. The game draws it at HEIGHTS[key] px through its
  sharp-pixel filter (crisp art pixels at any window scale; 2 screen px per art
  px at Zoom Close x2). Steps:
  1. Archives the untouched source to art_source/<key>.png (Godot ignores
     art_source/ through its .gdignore).
  2. Cleans the alpha: alpha >= ALPHA_CUT is opaque, the rest (soft fringe,
     shadows, glow haze) is background.
  3. Crops to the opaque pixels.
  4. Downscales to the art grid: the content is (art height - 2) px tall, the
     2 px being the outline added at the top and bottom (or the full height
     with --inside-outline). Each art pixel is one square cell of the source;
     it is opaque when at least COVER_MIN of the cell is opaque. Its colour is
     chosen material-first (METHOD "ramp"): the cell is box-filtered into
     VOTE_SUBSAMPLES^2 sub-samples; those darker than INK_L are the source's
     linework / deep shadow, the others are sorted into materials (palette
     ramps) by hue. A cell at least INK_YIELD lit takes its majority material
     (a much brighter material holding SALIENT_SHARE of it wins instead: eyes,
     runes, glints) at that material's mean lightness; a mostly dark cell
     becomes an outline ink (unless a bright accent sits in it: eyes in a hood).
     The allowed ramps are the faction set of the key's folder (FACTION_RAMPS,
     or --ramps). No dithering.
  5. Shading: each material's lightness range in this sprite is stretched over
     its ramp's shades ("levels": the moody, dark AI renders otherwise sink to
     the darkest shade and into the floors), then every art pixel takes the
     nearest shade; glow shades only where the source is genuinely that bright.
  6. Ramp pruning (saturated accent ramps such as eyes are exempt, ACCENT_CHROMA):
     ramps covering less than RAMP_MIN_SHARE of the sprite are
     dropped and their pixels re-snapped to the remaining ramps (stray hues from
     the AI's colour noise), except strongly contrasting accents (KEEP_DE).
  7. Cleanup ("readable features are 2+ art px; single pixels only for eyes,
     glints and highlights"): material flecks (a pixel of a material almost
     none of its neighbours share) merge into the surrounding material; a shade
     one step off a large neighbouring area joins it; lone opaque pixels are
     removed; a single-pixel colour island takes its neighbours' majority
     colour, except glow pixels, bright accents in a dark setting (eyes in a
     hood, EYE_DARK_L) and dark accents in a light setting (a skull's eye
     sockets, SOCKET_LIGHT_L).
  8. Outline: every transparent pixel touching the sprite (4-neighbour) becomes
     the outline ink (darkest shade) of the touching pixels' ramp; with
     --inside-outline the sprite's own edge pixels become the outline instead.
  9. Rim light: the sprite's own top and left edge pixels move one shade
     lighter in their ramp (light from the top-left).
  10. Feet on the bottom row (the last row is the lowest opaque row), the canvas
      exactly HEIGHTS[key] / ART_SCALE (= HEIGHTS[key]) px tall, and the body centred
      horizontally: the median column of the lower BODY_ROWS of the sprite sits
      on the canvas centre line (width is even).
  11. Writes assets/sprites/<key>.png and prints a report: size, colours used,
      ramps dropped, pixels cleaned, and the cells where the palette had to move
      a source colour's hue or saturation far (SNAP_WARN_DE), so a source colour
      outside the palette is easy to spot.
  Methods "mode" (each sub-sample snapped to the nearest colour, the cell takes
  the most common) and "mean" (the cell's average, snapped) are kept for
  comparison (--method); "ramp" gave the cleanest results on the AI sources.

Other grid-mode options: --art-height N (tiles, icons: an explicit height),
--allow-floor (tiles and decals may use the floor colours), --no-outline,
--no-rim, --no-levels, --no-cleanup, --no-prune, --no-center, --out FILE.

Walk sheets (--frames N in grid mode, ART_BIBLE "Walk cycles"):
  The source holds N poses in one row (split by fully transparent gaps when
  exactly N are found, else into N equal-width columns). All frames share one
  scale (the tallest pose fills the content height) and one ramp set; each is
  processed as above, then aligned: feet on the bottom row, body centre on the
  frame's centre line. Output strip layout, for the engine:
    assets/sprites/<key>_walk.png: N frames side by side, left to right in play
    order, no gaps; height = HEIGHTS[key] / ART_SCALE (= HEIGHTS[key], same as the still);
    every frame has the same even width FW; FW = the height when every pose
    fits in a square, else the smallest even width that fits the widest pose.
    Frame count = strip width / FW; walk sheets always have WALK_FRAMES (4)
    frames, frame 1 = the idle pose, so FW = strip width / 4.

Legacy mode (--legacy): the old behaviour, a smooth Lanczos copy RENDER_SCALE x
the on-screen height (for comparison only; the art pass replaces it).

Effect animations (--anim): unchanged; see prepare_anim(). The source can be an
animated GIF/WebP/APNG, a sheet of N equal frames in one row (--frames N), a
grid read left to right, top to bottom (--grid CxR), or a single row of frames
separated by fully transparent gaps (the default). Frames are cropped to one
shared square and written as a strip of ANIM_FRAME_PX frames to
assets/sprites/effects/<id>.png (AnimData reads the frame count as width / height).
--frame-px P stores larger (or smaller) frames for an effect drawn far bigger than
128 px on screen (Seraphine's 1300 px nova): the engine reads the frame size
from the strip height, so any square size works.

Requires Pillow and numpy. Sources must have a transparent background.
"""

import argparse
import re
import shutil
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageSequence

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixel_palette import Palette, oklab_to_srgb, srgb_to_oklab  # noqa: E402  (tools/ sibling module)

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# Folder of the untouched originals (ignored by Godot via .gdignore).
SOURCE_DIR = ROOT / "art_source"
# Folder of the in-game sprites (SpriteData.ROOT).
SPRITE_DIR = ROOT / "assets" / "sprites"
# Data file holding the on-screen heights (SpriteData.HEIGHTS) and ART_SCALE.
SPRITE_DATA = ROOT / "scripts" / "data" / "sprite_data.gd"

# --- Grid mode tunables -------------------------------------------------------
# Screen px per art px at the 1280x720 layout when sprite_data.gd has no ART_SCALE
# constant (GDD 15.0 "Art pass (true pixel art)": 1, the art is drawn 1:1).
DEFAULT_ART_SCALE = 1
# Source alpha (0-255) at or above which a pixel is opaque; below it is background.
ALPHA_CUT = 128
# Fraction (0-1) of an art cell that must be opaque for the art pixel to be opaque.
# Below 0.5 keeps thin staffs and blades that straddle two cells; above it trims fuzz.
COVER_MIN = 0.42
# How a cell's colour is chosen: "ramp" (material vote, module doc step 4), "mode"
# (most common snapped sub-sample) or "mean" (the cell's average colour, snapped).
METHOD = "ramp"
# Sub-samples per art cell side used to vote in "ramp" / "mode" (the source is
# box-filtered to this many samples per cell side first; 6 = 36 votes per cell).
# Relative to the cell, so it does not depend on ART_SCALE: at 1:1 a ~1,000 px
# source has ~19 px cells and ~3 px sub-samples, still finer than any AI pixel block.
VOTE_SUBSAMPLES = 6
# Minimum share (0-1) of a cell's lit area for a much brighter material to win the cell.
SALIENT_SHARE = 0.2
# How much brighter (OKLab L, 0-1) than the cell's majority material a material must be
# to win the cell as an accent (eyes, runes, glints).
SALIENT_DL = 0.25
# OKLab chroma weight when snapping a colour directly ("mode", "mean", fallbacks;
# above 1 keeps the hue over the exact lightness).
CHROMA_WEIGHT = 1.4
# "ramp" method: OKLab lightness (0-1) below which a source pixel is linework / deep
# shadow and snaps to an outline ink.
INK_L = 0.27
# "ramp" method: chroma weight used to pick a pixel's ramp (material) by hue.
RAMP_CHROMA_WEIGHT = 2.5
# "ramp" method: a cell ignores the source's dark linework when at least this share
# (0-1) of it is lit material (our own outline replaces the source's lines).
INK_YIELD = 0.45
# "ramp" method, levels: percentiles (0-100) of a material's lightness in the sprite
# mapped to its ramp's darkest and lightest body shade.
LEVELS_LOW, LEVELS_HIGH = 10, 95
# "ramp" method: a glow shade is only used for source pixels at least this close
# (OKLab L) to its lightness, i.e. genuinely bright in the source.
GLOW_TOL = 0.06
# In-ramp smoothing: neighbours (of 8) a shade must hold to absorb a pixel one shade away.
SMOOTH_MIN = 5
# Material flecks: a pixel whose ramp at most this many of its 8 neighbours share
# is a fleck (merged into the surrounding material when SMOOTH_MIN neighbours agree).
FLECK_MAX = 1
# Default ramps per sprite folder (the faction colour rules, ART_BIBLE "Colour language"):
# violet is the player's alone; undead summons are bone, cold grey, soul fire and their
# class accents; the Covenant is crimson, ivory (bone ramp), warm steel and gold.
# Folders not listed may use every ramp. Override with --ramps.
FACTION_RAMPS = {
    "player": ["violet", "bone", "grey", "soul", "moss", "arcane", "ice", "crimson", "brown", "gold", "flame"],
    "summons": ["bone", "grey", "soul", "moss", "arcane", "ice", "brown"],
    "enemies": ["bone", "steel", "crimson", "brown", "gold", "skin", "flame"],
    "bosses": ["bone", "steel", "crimson", "brown", "gold", "skin", "flame"],
    "structures": ["bone", "steel", "crimson", "brown", "gold", "flame"],
    # The Ancient Eye (Act II, assets/sprites/eye/): drowned teal, bone white and
    # bioluminescence, plus cloth, wet stone, skin and rot; never the player's
    # violet or the Covenant's crimson and gold.
    "eye": ["bone", "drowned", "biolume", "grey", "brown", "skin", "moss"],
}
# Per-key exceptions to FACTION_RAMPS: key -> (ramps added, ramps removed). The arcane
# blue of the Mage and Lich and the icy cyan of the frost summons never mix (GDD 15.0 art
# pass); only the fire summons get the flame ramp (its red ink would otherwise outline
# the dark linework of other summons).
KEY_RAMPS = {
    "summons/mage": ([], ["ice"]),
    "summons/lich": ([], ["ice"]),
    "summons/frost_wraith": ([], ["arcane"]),
    "summons/winter_revenant": ([], ["arcane"]),
    "summons/hellhound": (["flame"], []),
    "summons/ossuary_engine": (["flame"], []),
}
# Ramps holding less than this share (0-1) of the opaque pixels are dropped (re-snapped).
RAMP_MIN_SHARE = 0.03
# Ramp pruning: a pixel of a dropped ramp at least this far (OKLab) from its
# replacement is kept as an accent (an eye in a ramp used nowhere else).
KEEP_DE = 0.30
# Cleanup: a single bright pixel survives when its neighbours' mean lightness (OKLab L)
# is below this (an eye in a hood); elsewhere singles are merged.
EYE_DARK_L = 0.40
# Cleanup: a single dark pixel survives when its neighbours' mean lightness (OKLab L, 0-1)
# is at least this and it is SALIENT_DL darker (a skull's eye socket, a mouth, a rivet).
# Added for the 1:1 grid (ART_SCALE 1): a 56 px figure's skull pauldrons and staff
# skull have 1 art px sockets, which the old 2:1 rule merged into the bone (measured on
# the owner's necromancer source). 0.60 sits between bone_shade (0.57) and bone_mid (0.74),
# so only sockets set in lit bone, ivory, steel or skin are kept.
SOCKET_LIGHT_L = 0.60
# A coloured accent survives cleanup and ramp pruning: a pixel whose OKLab chroma is at least
# this (a saturated colour: teal soul-fire eyes, a violet rune, a crimson gem) and whose ramp no
# 8-neighbour shares. Eyes are only a pixel or two, so their ramp is always under
# RAMP_MIN_SHARE and would otherwise be pruned or merged away (the Skeleton Warrior anchor
# lost its teal eyes). Neutral greys, bone and ivory sit near 0.02-0.05, soul teal ~0.13.
ACCENT_CHROMA = 0.09
# Fraction (0-1) of the sprite's rows, from the bottom, used to find the body's centre column.
BODY_ROWS = 0.6
# Palette-snap error reported as a hotspot: OKLab a/b (hue and saturation) distance
# between the source colour an art pixel stands for and its palette colour.
SNAP_WARN_DE = 0.09
# Walk sheets always hold this many frames (ART_BIBLE "Walk cycles"; frame 1 = idle).
WALK_FRAMES = 4

# --- Legacy and animation tunables ---------------------------------------------
# Legacy mode: stored resolution relative to the on-screen height.
RENDER_SCALE = 3
# On-screen height (px) for keys missing from HEIGHTS (SpriteData.DEFAULT_HEIGHT).
DEFAULT_HEIGHT = 44.0
# Transparent margin kept around a legacy / effect crop, as a fraction of its height.
MARGIN = 0.03
# Alpha value (0-255) below which a pixel counts as background when cropping (legacy, anim).
ALPHA_THRESHOLD = 8
# Default stored size (px) of one square effect-animation frame (AnimData.FRAME_PX); --frame-px overrides it.
ANIM_FRAME_PX = 128
# Narrowest run of fully transparent columns (px) that counts as a gap between
# frames when splitting a sheet by gaps (narrower runs are holes inside a frame).
GAP_MIN_PX = 4
# Narrowest frame (px) kept when splitting by gaps (thinner slivers are specks).
MIN_FRAME_PX = 6


# =============================================================================
# Shared helpers
# =============================================================================

def on_screen_height(key: str) -> float:
    """Reads the on-screen height for `key` from sprite_data.gd's HEIGHTS (DEFAULT_HEIGHT if absent)."""
    text = SPRITE_DATA.read_text()
    match = re.search(r'"%s"\s*:\s*([0-9.]+)' % re.escape(key), text)
    if not match:
        print(f"warning: {key} is not in SpriteData.HEIGHTS; using {DEFAULT_HEIGHT:g} px")
    return float(match.group(1)) if match else DEFAULT_HEIGHT


def art_scale() -> int:
    """Screen px per art px: SpriteData.ART_SCALE if defined, else DEFAULT_ART_SCALE."""
    match = re.search(r"const\s+ART_SCALE\s*(?::\s*\w+)?\s*:?=\s*([0-9.]+)", SPRITE_DATA.read_text())
    return int(float(match.group(1))) if match else DEFAULT_ART_SCALE


def opaque_mask(img: Image.Image) -> Image.Image:
    """Returns a 1-channel mask: 255 where `img` is opaque, 0 where background (legacy, anim)."""
    return img.getchannel("A").point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)


def archive(src: Path, key: str) -> Path:
    """Copies the source to art_source/<key>.png (converted to PNG) and returns that path."""
    original = SOURCE_DIR / (key + ".png")  # Archived source path.
    original.parent.mkdir(parents=True, exist_ok=True)
    if src.resolve() != original.resolve():
        Image.open(src).convert("RGBA").save(original)
    return original


def split_grid(img: Image.Image, cols: int, rows: int) -> list:
    """Cuts `img` into cols x rows equal cells, read left to right, top to bottom."""
    cw = img.width / cols  # Cell width (px, may be fractional).
    ch = img.height / rows  # Cell height (px, may be fractional).
    cells = []  # Frames in play order.
    for r in range(rows):
        for c in range(cols):
            cells.append(img.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))))
    return cells


def split_by_gaps(img: Image.Image) -> list:
    """Cuts a one-row sheet into frames wherever a run of at least GAP_MIN_PX
    fully transparent columns separates opaque content."""
    mask = opaque_mask(img)  # Opaque pixels of the whole sheet.
    w, h = mask.size  # Sheet size (px).
    filled = (np.array(mask) > 0).any(axis=0).tolist()  # Column has content.
    frames = []  # Frames in play order.
    start = None  # First column of the frame being scanned, or None between frames.
    gap = 0  # Length of the current run of empty columns (px).
    for x in range(w + GAP_MIN_PX):
        on = x < w and filled[x]  # This column has content (past the edge = empty).
        if on:
            if start is None:
                start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= GAP_MIN_PX:
                end = x - gap + 1  # One past the frame's last filled column.
                if end - start >= MIN_FRAME_PX:
                    frames.append(img.crop((start, 0, end, h)))
                start = None
                gap = 0
    return frames


# =============================================================================
# Grid mode
# =============================================================================

def _box(arr: np.ndarray, size: tuple) -> np.ndarray:
    """Exact area-average resize of a 2-D float array to `size` (w, h) (Pillow BOX filter)."""
    return np.asarray(Image.fromarray(arr.astype(np.float32), "F").resize(size, Image.BOX), dtype=np.float64)


class GridSource:
    """One cleaned source image (or walk frame) ready for the grid: RGBA array,
    opaque mask and the crop box of its opaque pixels."""

    def __init__(self, img: Image.Image):
        rgba = np.asarray(img.convert("RGBA"))
        self.mask = rgba[..., 3] >= ALPHA_CUT  # Opaque source pixels.
        if not self.mask.any():
            sys.exit("Image is fully transparent (or has no alpha above ALPHA_CUT): nothing to convert.")
        if self.mask.all():
            print("note: the source has no transparent pixels (fine for a ground tile; for a sprite, ask the AI for a truly transparent background)")
        ys, xs = np.nonzero(self.mask)
        self.box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)  # Crop box (x0, y0, x1, y1).
        x0, y0, x1, y1 = self.box
        self.rgb = rgba[y0:y1, x0:x1, :3]  # Cropped colours.
        self.mask = self.mask[y0:y1, x0:x1]  # Cropped opaque mask.
        self.h, self.w = self.mask.shape  # Crop size (px).


def allowed_colors(key: str, pal: Palette, args) -> list:
    """Palette indices the sprite may use: the colours (inks included) of the
    ramps of --ramps, else of the faction default for the key's folder
    (FACTION_RAMPS, with the KEY_RAMPS exceptions); floor colours only with --allow-floor."""
    if args.ramps:
        ramps = [r.strip() for r in args.ramps.split(",") if r.strip()]
        unknown = [r for r in ramps if r not in pal.ramps]
        if unknown:
            sys.exit(f"unknown ramp(s) {unknown}; known: {', '.join(pal.ramps)}")
    else:
        ramps = FACTION_RAMPS.get(key.split("/")[0]) or [r for r in pal.ramps if r != "floor"]
        added, removed = KEY_RAMPS.get(key, ([], []))
        ramps = [r for r in ramps if r not in removed] + [r for r in added if r not in ramps]
    if args.allow_floor:
        ramps = list(ramps) + ["floor"]
    return sorted({i for r in ramps for i in pal.ramps[r]})


class Cells:
    """One source downscaled to the art grid, before the shades are chosen.
    idx:  palette index per art pixel (-1 = transparent; for "ramp", -2 = a lit
          pixel whose shade is chosen later by shade_cells()).
    ramp: material (ramp name) per lit art pixel ("" elsewhere).
    lum:  source lightness (OKLab L) the lit art pixel stands for.
    src:  source colour (OKLab) the art pixel stands for (for the report)."""

    def __init__(self, gh: int, gw: int):
        self.idx = np.full((gh, gw), -1, dtype=np.int64)
        self.ramp = np.full((gh, gw), "", dtype=object)
        self.lum = np.zeros((gh, gw))
        self.src = np.zeros((gh, gw, 3))


def grid_cells(src: GridSource, scale: float, pal: Palette, allowed: list, method: str) -> Cells:
    """Downscales `src` to the art grid at `scale` source px per art px (module
    doc, step 4). The crop's bottom edge stays on the grid's bottom edge (feet)
    and it is centred horizontally in whole cells.
    "ramp" (default): every sub-sample (VOTE_SUBSAMPLES^2 per cell, box-filtered)
    darker than INK_L is linework / deep shadow (the nearest ink by hue); the
    rest is classified by material (ramp_of_colors()). A cell that is at least
    INK_YIELD lit takes its majority material (a much brighter material, or a
    much more saturated one (ACCENT_CHROMA), with SALIENT_SHARE of the cell
    wins instead: eyes, runes, glints) and the mean
    lightness of that material's sub-samples; its shade is chosen later for
    the whole sprite (shade_cells()). A mostly dark cell takes its majority ink.
    "mode": the cell takes the palette colour most of its sub-samples snap to.
    "mean": the cell's average colour, snapped."""
    gh = max(1, round(src.h / scale))  # Grid height (art px).
    gw = max(1, int(np.ceil(src.w / scale)))  # Grid width (art px).
    # Pad the crop to exactly gw x gh cells of `scale` px: extra rows go on top, columns split left / right.
    ph, pw = int(round(gh * scale)), int(round(gw * scale))  # Padded size (source px).
    top = max(0, ph - src.h)
    left = max(0, (pw - src.w) // 2)
    mask = np.zeros((max(ph, src.h + top), max(pw, src.w + left)), dtype=np.float64)
    rgb = np.zeros(mask.shape + (3,), dtype=np.uint8)
    mask[top:top + src.h, left:left + src.w] = src.mask
    rgb[top:top + src.h, left:left + src.w] = src.rgb
    lab = srgb_to_oklab(rgb)  # Source colours in OKLab.
    cover = _box(mask, (gw, gh))  # Opaque share per cell (0-1).
    mean = np.stack([_box(lab[..., c] * mask, (gw, gh)) for c in range(3)], -1) / np.maximum(cover, 1e-6)[..., None]
    opaque = cover >= COVER_MIN  # Opaque art pixels.
    out = Cells(gh, gw)
    out.src[:] = mean
    if method == "mean":
        out.idx[opaque] = pal.snap(mean[opaque], allowed, CHROMA_WEIGHT)
        return out
    k = VOTE_SUBSAMPLES
    sub_cover = _box(mask, (gw * k, gh * k))  # Opaque share per sub-sample.
    sub_lab = np.stack([_box(lab[..., c] * mask, (gw * k, gh * k)) for c in range(3)], -1) / np.maximum(sub_cover, 1e-6)[..., None]
    sub_on = sub_cover >= 0.5  # Sub-sample counts as opaque.
    if method == "mode":
        sub_idx = np.full(sub_on.shape, -1, dtype=np.int64)
        sub_idx[sub_on] = pal.snap(sub_lab[sub_on], allowed, CHROMA_WEIGHT)
        for y, x in zip(*np.nonzero(opaque)):
            votes = sub_idx[y * k:(y + 1) * k, x * k:(x + 1) * k]
            votes = votes[votes >= 0]
            out.idx[y, x] = Counter(votes.tolist()).most_common(1)[0][0] if votes.size else \
                pal.snap(mean[y, x][None, :], allowed, CHROMA_WEIGHT)[0]
        return out
    # "ramp": material per sub-sample ("" = ink), ink index for the dark ones.
    inks = [i for i in allowed if pal.group[i] == "ink"]
    sub_ramp = np.full(sub_on.shape, "", dtype=object)
    sub_ink = np.full(sub_on.shape, -1, dtype=np.int64)
    dark = sub_on & (sub_lab[..., 0] < INK_L)
    lit = sub_on & ~dark
    if dark.any():
        sub_ink[dark] = pal.snap(sub_lab[dark], inks, RAMP_CHROMA_WEIGHT)
    if lit.any():
        sub_ramp[lit] = ramp_of_colors(sub_lab[lit], pal, allowed)
    for y, x in zip(*np.nonzero(opaque)):
        cs = (slice(y * k, (y + 1) * k), slice(x * k, (x + 1) * k))  # This cell's sub-samples.
        c_on, c_lit = sub_on[cs], lit[cs]
        if not c_on.any():
            out.idx[y, x] = pal.snap(mean[y, x][None, :], allowed, CHROMA_WEIGHT)[0]
            continue
        ramps = sub_ramp[cs][c_lit]
        ls = sub_lab[cs][..., 0][c_lit]
        if c_lit.sum() < INK_YIELD * c_on.sum():
            # Mostly linework / shadow: the ink, unless a bright accent (eyes in a hood) holds SALIENT_SHARE.
            bright = ramps[ls > INK_L + SALIENT_DL]
            accent = Counter(bright.tolist()).most_common(1)[0] if bright.size else ("", 0)
            if accent[1] >= SALIENT_SHARE * c_on.sum():
                sel = (ramps == accent[0]) & (ls > INK_L + SALIENT_DL)
                out.idx[y, x] = -2
                out.ramp[y, x] = accent[0]
                out.lum[y, x] = ls[sel].mean()
                out.src[y, x] = sub_lab[cs][c_lit][sel].mean(0)
            else:
                out.idx[y, x] = Counter(sub_ink[cs][dark[cs]].tolist()).most_common(1)[0][0]
            continue
        counts = Counter(ramps.tolist())
        best = counts.most_common(1)[0][0]  # Material holding the most lit area.
        best_l = ls[ramps == best].mean()
        # A much brighter material with enough area wins the cell (eyes, runes, glints),
        # and so does a strongly coloured one on a neutral material (teal eyes in a bone
        # face are no brighter than the bone, only far more saturated: ACCENT_CHROMA).
        lit_lab = sub_lab[cs][c_lit]  # OKLab of this cell's lit sub-samples.
        best_c = float(np.hypot(lit_lab[ramps == best][:, 1], lit_lab[ramps == best][:, 2]).mean())  # Majority chroma.
        for r, n in counts.most_common():
            if r == best or n < SALIENT_SHARE * ramps.size:
                continue
            r_c = float(np.hypot(lit_lab[ramps == r][:, 1], lit_lab[ramps == r][:, 2]).mean())  # Candidate chroma.
            if ls[ramps == r].mean() > best_l + SALIENT_DL or (r_c >= ACCENT_CHROMA and r_c > best_c + ACCENT_CHROMA):
                best, best_l = r, ls[ramps == r].mean()
                break
        out.idx[y, x] = -2
        out.ramp[y, x] = best
        out.lum[y, x] = best_l
        out.src[y, x] = sub_lab[cs][c_lit][ramps == best].mean(0)
    return out


def ramp_of_colors(lab: np.ndarray, pal: Palette, allowed: list) -> np.ndarray:
    """Material of each lit OKLab colour (N, 3): the primary ramp of the nearest
    allowed body colour with RAMP_CHROMA_WEIGHT on a / b (hue first)."""
    lit = [i for i in allowed if pal.group[i] != "ink"]
    first = pal.snap(lab, lit, RAMP_CHROMA_WEIGHT)
    return np.array([pal.ramp[c] for c in first], dtype=object)


def shade_cells(cells: list, pal: Palette, allowed: list, levels: bool) -> None:
    """Chooses the shade of every lit "ramp" art pixel, jointly over all `cells`
    (a still, or every walk frame): by lightness inside its material's ramp.
    With `levels`, each material's lightness range in the sprite (LEVELS_LOW to
    LEVELS_HIGH percentile) is first stretched over its ramp's body shades, so
    every material uses its whole ramp (the moody, dark AI sources otherwise
    sit on the darkest shade and sink into the floors). Glow shades are only
    used where the source is genuinely that bright (GLOW_TOL)."""
    lit_all = [i for i in allowed if pal.group[i] != "ink"]
    for r in sorted({v for c in cells for v in c.ramp[c.idx == -2].tolist()}):
        members = [m for m in pal.ramps[r] if m in lit_all]
        body = [m for m in members if pal.group[m] != "glow"] or members  # Shades the stretch spans.
        glows = [m for m in members if pal.group[m] == "glow"]
        body_l = pal.lab[body][:, 0]
        ls_all = np.concatenate([c.lum[(c.idx == -2) & (c.ramp == r)] for c in cells])
        lo, hi = (np.percentile(ls_all, LEVELS_LOW), np.percentile(ls_all, LEVELS_HIGH)) if ls_all.size else (0, 0)
        for c in cells:
            sel = (c.idx == -2) & (c.ramp == r)
            if not sel.any():
                continue
            ls = c.lum[sel]
            target = ls.copy()
            if levels and ls_all.size >= 4 and hi - lo > 0.04:
                target = body_l.min() + (ls - lo) / (hi - lo) * (body_l.max() - body_l.min())
            pick = np.array(body)[np.abs(target[:, None] - body_l[None, :]).argmin(1)]
            for g in glows:
                pick[ls >= pal.lab[g][0] - GLOW_TOL] = g
            c.idx[sel] = pick


def smooth_shading(idx: np.ndarray, pal: Palette) -> tuple:
    """One pass of in-ramp smoothing: a pixel one shade away from a colour of
    its own ramp that holds at least SMOOTH_MIN of its 8 neighbours takes that
    colour (AI texture noise becomes flat areas). Returns (grid, pixels changed)."""
    h, w = idx.shape
    out = idx.copy()
    changed = 0
    for y in range(h):
        for x in range(w):
            c = idx[y, x]
            if c < 0 or pal.group[c] in ("ink", "glow"):
                continue
            nb = [idx[y + dy, x + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                  if (dy or dx) and 0 <= y + dy < h and 0 <= x + dx < w]
            members = pal.ramps[pal.ramp[c]]
            counts = Counter(v for v in nb if v >= 0 and v != c and v in members)
            if not counts:
                continue
            best, n = counts.most_common(1)[0]
            if n >= SMOOTH_MIN and abs(members.index(best) - members.index(c)) == 1:
                out[y, x] = best
                changed += 1
    return out, changed


def merge_flecks(idx: np.ndarray, pal: Palette) -> tuple:
    """Material flecks: a lit pixel whose ramp (material) at most FLECK_MAX of its
    8 neighbours share, inside an area where one other ramp holds at least
    SMOOTH_MIN neighbours, is re-shaded into that ramp (nearest lightness). The
    AI's sub-pixel trims, belts and texture turn into stray dots of another
    material at this size; this keeps the large masses clean. Glow pixels and
    inks are kept. Returns (grid, pixels changed)."""
    h, w = idx.shape
    out = idx.copy()
    changed = 0
    for y in range(h):
        for x in range(w):
            c = idx[y, x]
            if c < 0 or pal.group[c] in ("ink", "glow"):
                continue
            nb = [idx[y + dy, x + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                  if (dy or dx) and 0 <= y + dy < h and 0 <= x + dx < w]
            nb = [v for v in nb if v >= 0 and pal.group[v] != "ink"]
            same = sum(1 for v in nb if pal.ramp[v] == pal.ramp[c])
            if same > FLECK_MAX:
                continue
            ramps = Counter(pal.ramp[v] for v in nb if pal.ramp[v] != pal.ramp[c])
            if not ramps:
                continue
            ramp, n = ramps.most_common(1)[0]
            if n < SMOOTH_MIN:
                continue
            # Body shades of that ramp; a floor ramp (tiles, --allow-floor) has no "unit" group.
            members = [m for m in pal.ramps[ramp] if pal.group[m] == "unit"] or \
                [m for m in pal.ramps[ramp] if pal.group[m] != "ink"]
            if not members:
                continue
            out[y, x] = min(members, key=lambda m: abs(pal.lab[m][0] - pal.lab[c][0]))
            changed += 1
    return out, changed


def is_accent(idx: np.ndarray, y: int, x: int, pal: Palette) -> bool:
    """True when pixel (y, x) is a coloured accent (see ACCENT_CHROMA): a saturated
    colour whose ramp none of its opaque 8-neighbours uses (an eye, a gem, a rune)."""
    c = idx[y, x]
    if c < 0 or pal.group[c] == "ink":
        return False
    if float(np.hypot(pal.lab[c][1], pal.lab[c][2])) < ACCENT_CHROMA:
        return False
    h, w = idx.shape
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if (dy or dx) and 0 <= y + dy < h and 0 <= x + dx < w:
                v = idx[y + dy, x + dx]  # Neighbour colour index (-1 = transparent).
                if v >= 0 and pal.ramp[v] == pal.ramp[c] and pal.group[v] != "ink":
                    return False
    return True


def cleanup(idx: np.ndarray, pal: Palette) -> tuple:
    """Removes lone opaque pixels and merges single-pixel colour islands (a
    pixel whose colour no 4-neighbour shares) into their neighbours' majority
    colour, except glow pixels, bright accents in a dark setting (eyes in a
    hood, a lit rune: neighbours darker than EYE_DARK_L, the pixel SALIENT_DL
    brighter), dark accents in a light setting (a skull's eye sockets:
    neighbours at least SOCKET_LIGHT_L, the pixel SALIENT_DL darker) and
    coloured accents (is_accent(): a saturated pixel of a ramp no neighbour
    uses, such as teal eyes in a bone face). Lone
    floating pixels are always removed. Returns (grid, pixels changed)."""
    h, w = idx.shape
    out = idx.copy()
    changed = 0
    n4 = ((-1, 0), (1, 0), (0, -1), (0, 1))  # 4-neighbour offsets (dy, dx).
    for y in range(h):
        for x in range(w):
            c = idx[y, x]
            if c < 0:
                continue
            nb4 = [idx[y + dy, x + dx] for dy, dx in n4 if 0 <= y + dy < h and 0 <= x + dx < w]
            if all(v < 0 for v in nb4):
                out[y, x] = -1  # Lone floating pixel.
                changed += 1
                continue
            if any(v == c for v in nb4):
                continue  # Part of a 2+ px shape.
            nb8 = [idx[y + dy, x + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                   if (dy or dx) and 0 <= y + dy < h and 0 <= x + dx < w and idx[y + dy, x + dx] >= 0]
            if not nb8:
                continue
            repl = Counter(nb8).most_common(1)[0][0]  # Neighbours' majority colour.
            around = float(np.mean([pal.lab[v][0] for v in nb8]))  # Neighbours' mean lightness.
            # Kept: glow pixels, bright accents in a dark setting (eyes in a hood, a lit rune)
            # and dark accents in a light setting (a skull's eye sockets).
            eye = around < EYE_DARK_L and pal.lab[c][0] - around > SALIENT_DL
            socket = around >= SOCKET_LIGHT_L and around - pal.lab[c][0] > SALIENT_DL
            if pal.group[c] == "glow" or eye or socket or is_accent(idx, y, x, pal):
                continue
            out[y, x] = repl
            changed += 1
    return out, changed


def outline_and_rim(idx: np.ndarray, pal: Palette, outline: bool, rim: bool, inside: bool = False) -> np.ndarray:
    """Draws the 1 px outline and the top-left rim light.
    Outside (default): pads the grid by one pixel; every transparent pixel
    touching the sprite (4-neighbour) becomes the outline ink of the touching
    pixels' ramp (the majority ramp wins, ties go to the darkest ink).
    Inside (--inside-outline, for sources drawn at the target grid with their
    own outline): the sprite's own edge pixels become that outline instead, so
    the size does not grow; a 1 px wide feature keeps its own ramp's ink.
    Rim: the body pixels just inside the outline on the top and left move one
    shade lighter in their ramp (light from the top-left), where they form runs
    of 2+ same-colour pixels (a lone rim pixel would be a speck)."""
    g = np.pad(idx, 1, constant_values=-1)
    h, w = g.shape
    n4 = ((-1, 0), (1, 0), (0, -1), (0, 1))  # 4-neighbour offsets (dy, dx).
    if inside and outline:
        edge = np.zeros(g.shape, dtype=bool)  # Opaque pixels on the sprite's edge.
        for y, x in zip(*np.nonzero(g >= 0)):
            edge[y, x] = any(g[y + dy, x + dx] < 0 for dy, dx in n4)
        body = np.where(edge, -1, g)  # The sprite without its edge ring.
        ring = edge  # Where the outline goes.
    else:
        body = g
        ring = np.zeros(g.shape, dtype=bool)
        if outline:
            for y, x in zip(*np.nonzero(g < 0)):
                ring[y, x] = any(0 <= y + dy < h and 0 <= x + dx < w and g[y + dy, x + dx] >= 0 for dy, dx in n4)
    out = body.copy()
    for y, x in zip(*np.nonzero(ring)):
        inks = [pal.outline_of(body[y + dy, x + dx]) for dy, dx in n4
                if 0 <= y + dy < h and 0 <= x + dx < w and body[y + dy, x + dx] >= 0]
        if inks:
            counts = Counter(inks)
            top = max(counts.values())
            out[y, x] = min((i for i, n in counts.items() if n == top), key=lambda i: pal.lab[i][0])
        else:
            out[y, x] = pal.outline_of(g[y, x])  # A 1 px feature (inside mode): its own ink.
    if rim:
        cand = np.zeros(g.shape, dtype=bool)  # Body pixels on the top or left edge.
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                c = body[y, x]
                if c < 0 or pal.group[c] in ("ink", "glow"):
                    continue
                cand[y, x] = body[y - 1, x] < 0 or ring[y - 1, x] or body[y, x - 1] < 0 or ring[y, x - 1]
        # Only runs of 2+ same-colour edge pixels are lit (a lone rim pixel is a speck).
        for y, x in zip(*np.nonzero(cand)):
            if any(cand[y + dy, x + dx] and body[y + dy, x + dx] == body[y, x] for dy, dx in n4):
                out[y, x] = pal.lighter_of(body[y, x])
    return out


def place(idx: np.ndarray, height: int, center: bool, frame_w: int = 0, cx: float = None) -> np.ndarray:
    """Crops `idx` to its opaque pixels, puts the lowest opaque row on the last
    row of a `height`-row canvas and centres the body column (`cx`, else the
    median column of the lower BODY_ROWS) on an even-width canvas (`frame_w`
    wide when given). Returns the placed grid."""
    ys, xs = np.nonzero(idx >= 0)
    g = idx[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    gh, gw = g.shape
    if gh > height:
        g = g[gh - height:]  # Never taller than the canvas (keeps the feet).
        gh = height
    if cx is None:
        cx = body_center(g) if center else gw / 2.0
    c = int(round(cx))  # Centre line (between columns c - 1 and c).
    half = max(c, gw - c)  # Half width needed (px).
    width = max(frame_w, 2 * half)
    width += width % 2
    left = width // 2 - c
    canvas = np.full((height, width), -1, dtype=np.int64)
    canvas[height - gh:, left:left + gw] = g
    return canvas


def body_center(g: np.ndarray) -> float:
    """Median opaque column (+0.5, a pixel centre) of the lower BODY_ROWS of grid `g`."""
    rows = max(1, int(round(g.shape[0] * BODY_ROWS)))
    ys, xs = np.nonzero(g[-rows:] >= 0)
    return float(np.median(xs)) + 0.5 if xs.size else g.shape[1] / 2.0


def to_image(idx: np.ndarray, pal: Palette) -> Image.Image:
    """Palette-index grid -> RGBA image (alpha 0 or 255 only)."""
    rgba = np.zeros(idx.shape + (4,), dtype=np.uint8)
    on = idx >= 0
    rgba[on, :3] = pal.rgb[idx[on]]
    rgba[on, 3] = 255
    return Image.fromarray(rgba, "RGBA")


def report(key: str, dest: Path, idx: np.ndarray, mean: np.ndarray, snapped: np.ndarray, pal: Palette,
           dropped: list, cleaned: int) -> None:
    """Prints the conversion report: size, colours used, dropped ramps, snap hotspots."""
    h, w = idx.shape
    used = Counter(idx[idx >= 0].tolist())
    print(f"{key}: -> {dest.relative_to(ROOT) if dest.is_relative_to(ROOT) else dest} ({w}x{h} art px, "
          f"{w * art_scale()}x{h * art_scale()} on screen)")
    print(f"  colours used ({len(used)}): " + ", ".join(f"{pal.names[i]} {n}" for i, n in used.most_common()))
    if dropped:
        print(f"  ramps dropped as stray (< {RAMP_MIN_SHARE:.0%} of the sprite): {', '.join(dropped)}")
    print(f"  cleanup: {cleaned} pixel(s) merged or removed (single-pixel noise)")
    on = snapped >= 0
    err = np.zeros(snapped.shape)
    # Hue / saturation error only (OKLab a, b): the lightness is moved on purpose by the levels stretch.
    err[on] = np.linalg.norm(mean[on][:, 1:] - pal.lab[snapped[on]][:, 1:], axis=-1)
    hot = np.argwhere(err > SNAP_WARN_DE)
    print(f"  palette snap (hue / saturation error): mean {err[on].mean():.3f}, {len(hot)} hotspot cell(s) above {SNAP_WARN_DE}"
          + (" (source colours far from every palette ramp: recolour the source or extend the palette)" if len(hot) else ""))
    for y, x in sorted(hot.tolist(), key=lambda p: -err[p[0], p[1]])[:5]:
        src_hex = "#%02X%02X%02X" % oklab_to_srgb(mean[y, x])
        print(f"    content cell ({x},{y}): source {src_hex} -> {pal.names[snapped[y, x]]} (error {err[y, x]:.2f})")


def convert(srcs: list, height: int, key: str, pal: Palette, args) -> tuple:
    """Runs grid steps 4-8 on every source (one still, or the walk frames) with a
    shared scale, shading and ramp set. Returns (grids before placing, source
    colour grids, snapped grids, dropped ramps, cleaned pixel count)."""
    margin = 2 if args.outline and not args.inside_outline else 0  # Outline rows added at the top and bottom.
    content = height - margin  # Content height (art px).
    scale = max(s.h for s in srcs) / content  # Source px per art px, shared.
    allowed = allowed_colors(key, pal, args)
    cells = [grid_cells(s, scale, pal, allowed, args.method) for s in srcs]
    if args.method == "ramp":
        shade_cells(cells, pal, allowed, args.levels)
    # Ramp pruning, shared across all frames: rarely used ramps are stray AI colour noise.
    idx_all = np.concatenate([c.idx.ravel() for c in cells])
    share = Counter(pal.ramp[i] for i in idx_all[idx_all >= 0].tolist() if pal.group[i] != "ink")
    total = max(1, sum(share.values()))
    # A rare ramp is dropped unless it is a saturated accent colour (mean OKLab chroma of its
    # pixels at least ACCENT_CHROMA): a unit's eyes or gem are always rare, never noise to prune.
    chroma = {r: float(np.mean([np.hypot(pal.lab[i][1], pal.lab[i][2]) for i in idx_all[idx_all >= 0].tolist()
                                if pal.ramp[i] == r and pal.group[i] != "ink"])) for r in share}  # Mean chroma per used ramp.
    drop = sorted(r for r, n in share.items()
                  if n < RAMP_MIN_SHARE * total and chroma[r] < ACCENT_CHROMA) if args.prune else []
    keep = [i for i in allowed if pal.ramp[i] not in drop or pal.group[i] == "ink"]
    grids, srcs_lab, snaps, cleaned = [], [], [], 0
    for c in cells:
        idx = c.idx
        snaps.append(idx.copy())
        for y, x in zip(*np.nonzero(np.isin(idx, [i for i in allowed if i not in keep]))):
            if is_accent(c.idx, y, x, pal):
                continue  # A coloured accent (an eye) keeps its pruned ramp.
            alt = pal.snap(c.src[y, x][None, :], keep, RAMP_CHROMA_WEIGHT)[0]
            # A strong accent survives (an eye in a ramp used nowhere else).
            if np.linalg.norm(pal.lab[alt] - pal.lab[idx[y, x]]) <= KEEP_DE:
                idx[y, x] = alt
        if args.cleanup:
            for step in (merge_flecks, smooth_shading, cleanup):
                idx, n = step(idx, pal)
                cleaned += n
        grids.append(outline_and_rim(idx, pal, args.outline, args.rim, args.inside_outline))
        srcs_lab.append(c.src)
    return grids, srcs_lab, snaps, drop, cleaned


def target_height(key: str, args) -> int:
    """Art-px height of the output: --art-height, else HEIGHTS[key] / ART_SCALE (must divide evenly)."""
    if args.art_height:
        return args.art_height
    screen = on_screen_height(key)
    scale = art_scale()
    if abs(screen / scale - round(screen / scale)) > 1e-6:
        sys.exit(f"HEIGHTS[{key}] = {screen:g} is not a multiple of ART_SCALE {scale}")
    return int(round(screen / scale))


def prepare_grid(src: Path, key: str, args) -> None:
    """Grid mode for one still sprite (module doc, steps 1-11)."""
    pal = Palette()
    height = target_height(key, args)
    original = archive(src, key)
    gsrc = GridSource(Image.open(original))
    grids, means, snaps, drop, cleaned = convert([gsrc], height, key, pal, args)
    placed = place(grids[0], height, args.center)
    dest = Path(args.out) if args.out else SPRITE_DIR / (key + ".png")
    dest.parent.mkdir(parents=True, exist_ok=True)
    to_image(placed, pal).save(dest, optimize=True)
    report(key, dest, placed, means[0], snaps[0], pal, drop, cleaned)
    print(f"  original in {original.relative_to(ROOT)}; check it with: python3 tools/art_check.py {key}")


def prepare_walk(src: Path, key: str, args) -> None:
    """Grid mode for a walk sheet of args.frames poses (module doc, "Walk sheets")."""
    pal = Palette()
    height = target_height(key, args)
    original = SOURCE_DIR / (key + "_walk.png")  # Archived sheet.
    original.parent.mkdir(parents=True, exist_ok=True)
    Image.open(src).convert("RGBA").save(original)
    sheet = Image.open(original).convert("RGBA")
    frames = split_by_gaps(sheet)
    how = "transparent gaps"
    if len(frames) != args.frames:
        frames = split_grid(sheet, args.frames, 1)
        how = f"{args.frames} equal columns"
    if args.frames != WALK_FRAMES:
        print(f"warning: walk sheets have {WALK_FRAMES} frames (ART_BIBLE); got --frames {args.frames}")
    srcs = [GridSource(f) for f in frames]
    grids, means, snaps, drop, cleaned = convert(srcs, height, key, pal, args)
    placed = [place(g, height, args.center) for g in grids]
    fw = max(p.shape[1] for p in placed)
    fw = height if fw <= height else fw + fw % 2  # Square frames when every pose fits.
    placed = [place(g, height, args.center, fw) for g in grids]
    strip = np.full((height, fw * len(placed)), -1, dtype=np.int64)
    for i, p in enumerate(placed):
        strip[:, i * fw:(i + 1) * fw] = p[:, (p.shape[1] - fw) // 2:(p.shape[1] - fw) // 2 + fw]
    dest = Path(args.out) if args.out else SPRITE_DIR / (key + "_walk.png")
    dest.parent.mkdir(parents=True, exist_ok=True)
    to_image(strip, pal).save(dest, optimize=True)
    used = Counter(strip[strip >= 0].tolist())
    print(f"{key}_walk: {len(placed)} frames by {how} -> {dest} ({fw * len(placed)}x{height} art px, "
          f"frame {fw}x{height}); {len(used)} colours; ramps dropped: {', '.join(drop) or 'none'}; "
          f"cleanup {cleaned} px; original in {original.relative_to(ROOT)}")


# =============================================================================
# Legacy and effect animations (unchanged behaviour)
# =============================================================================

def prepare_legacy(src: Path, key: str) -> None:
    """Old behaviour: a smooth Lanczos copy RENDER_SCALE x the on-screen height."""
    original = archive(src, key)
    img = Image.open(original).convert("RGBA")  # Working image.
    box = opaque_mask(img).getbbox()  # Bounding box of the opaque pixels.
    if box is None:
        sys.exit("Image is fully transparent: nothing to crop.")
    img = img.crop(box)
    pad = int(img.height * MARGIN)  # Margin in px.
    padded = Image.new("RGBA", (img.width + 2 * pad, img.height + 2 * pad), (0, 0, 0, 0))  # Canvas with margin.
    padded.paste(img, (pad, pad))
    target_h = round(on_screen_height(key) * RENDER_SCALE)  # Stored height (px).
    target_w = round(padded.width * target_h / padded.height)  # Width keeping aspect ratio.
    out = padded.resize((target_w, target_h), Image.LANCZOS)  # Game-ready sprite.
    dest = SPRITE_DIR / (key + ".png")  # In-game path (SpriteBank key).
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest, optimize=True)
    print(f"{key} (legacy): {src.name} -> {dest.relative_to(ROOT)} ({target_w}x{target_h}), original in {original.relative_to(ROOT)}")


def square_frames(frames: list, centre_each: bool) -> list:
    """Crops `frames` to squares around the effect. With `centre_each` false the
    union of all frames' opaque areas is used (positions are kept); otherwise
    each frame's own content is centred in the shared square size."""
    boxes = [opaque_mask(f).getbbox() for f in frames]  # Opaque bbox per frame (None = empty).
    if all(b is None for b in boxes):
        sys.exit("Every frame is fully transparent: nothing to crop.")
    if centre_each:
        side = max(max(b[2] - b[0], b[3] - b[1]) for b in boxes if b)  # Largest content side (px).
    else:
        union = (min(b[0] for b in boxes if b), min(b[1] for b in boxes if b),
                 max(b[2] for b in boxes if b), max(b[3] for b in boxes if b))  # Union bbox.
        side = max(union[2] - union[0], union[3] - union[1])  # Square side (px).
    pad = max(1, int(side * MARGIN))  # Margin in px.
    full = side + 2 * pad  # Square side with margin (px).
    out = []  # Square frames.
    for f, b in zip(frames, boxes):
        canvas = Image.new("RGBA", (full, full), (0, 0, 0, 0))  # Transparent square.
        if b is not None:
            if centre_each:
                part = f.crop(b)  # This frame's content.
                canvas.paste(part, ((full - part.width) // 2, (full - part.height) // 2))
            else:
                # Centre the union box in the square; every frame shares the offset.
                ox = pad + (side - (union[2] - union[0])) // 2 - union[0]  # x shift (px).
                oy = pad + (side - (union[3] - union[1])) // 2 - union[1]  # y shift (px).
                canvas.paste(f, (ox, oy))
        out.append(canvas)
    return out


def prepare_anim(src: Path, anim_id: str, frames_n: int, grid: str, frame_px: int = ANIM_FRAME_PX) -> None:
    """Processes a GIF or sprite sheet into assets/sprites/effects/<id>.png
    (square frames of `frame_px` px, ANIM_FRAME_PX by default)."""
    # 1. Keep the original (any format, untouched bytes).
    original = SOURCE_DIR / "effects" / (anim_id + src.suffix.lower())  # Archived source path.
    original.parent.mkdir(parents=True, exist_ok=True)
    if src.resolve() != original.resolve():
        shutil.copyfile(src, original)

    # 2. Split into frames.
    img = Image.open(src)  # Source (possibly multi-frame).
    centre_each = False  # True when frame positions in the source are arbitrary.
    if getattr(img, "n_frames", 1) > 1:
        frames = [f.convert("RGBA") for f in ImageSequence.Iterator(img)]
        how = "animated source"  # How the frames were found (for the report).
    else:
        sheet = img.convert("RGBA")  # Still sprite sheet.
        if grid:
            cols, rows = (int(v) for v in grid.lower().split("x"))
            frames = split_grid(sheet, cols, rows)
            how = f"{cols}x{rows} grid"
        elif frames_n > 0:
            frames = split_grid(sheet, frames_n, 1)
            how = f"{frames_n} equal frames"
        else:
            frames = split_by_gaps(sheet)
            centre_each = True
            how = "transparent gaps"
    if not frames:
        sys.exit("No frames found. Pass --frames N or --grid CxR.")

    # 3. Square crop around the effect; 4. resize and lay out as a strip.
    squares = square_frames(frames, centre_each)
    strip = Image.new("RGBA", (frame_px * len(squares), frame_px), (0, 0, 0, 0))  # Output strip.
    for i, sq in enumerate(squares):
        strip.paste(sq.resize((frame_px, frame_px), Image.LANCZOS), (i * frame_px, 0))
    dest = SPRITE_DIR / "effects" / (anim_id + ".png")  # In-game path (SpriteBank "effects/<id>").
    dest.parent.mkdir(parents=True, exist_ok=True)
    strip.save(dest, optimize=True)
    print(f"effects/{anim_id}: {src.name} -> {dest.relative_to(ROOT)} ({len(squares)} frames by {how}, "
          f"{frame_px}px each), original in {original.relative_to(ROOT)}")


def main() -> None:
    global INK_L  # --ink-l rebinds the module threshold read by grid_cells().
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("source", help="image, GIF or sprite sheet to process")
    parser.add_argument("key", help="sprite key (e.g. player/necromancer) or, with --anim, effect id")
    parser.add_argument("--anim", action="store_true", help="process an effect animation (smooth 128 px frames)")
    parser.add_argument("--legacy", action="store_true", help="old smooth 3x sprite instead of grid pixel art")
    parser.add_argument("--frames", type=int, default=0,
                        help="grid mode: a walk sheet of N poses (writes <key>_walk.png); --anim: N equal frames in one row")
    parser.add_argument("--grid", default="", help="--anim: CxR grid of equal frames")
    parser.add_argument("--frame-px", type=int, default=ANIM_FRAME_PX,
                        help=f"--anim: stored frame size in px (default {ANIM_FRAME_PX}; larger for huge effects)")
    parser.add_argument("--art-height", type=int, default=0, help="grid mode: output height in art px (default HEIGHTS[key] / ART_SCALE = HEIGHTS[key])")
    parser.add_argument("--method", choices=("ramp", "mode", "mean"), default=METHOD, help="grid mode: how a cell's colour is chosen")
    parser.add_argument("--ramps", default="", help="grid mode: comma-separated ramps allowed (default: the folder's faction set)")
    parser.add_argument("--no-levels", dest="levels", action="store_false", help="grid mode: no per-material lightness stretch")
    parser.add_argument("--ink-l", type=float, default=INK_L,
                        help="grid mode, ramp method: OKLab lightness (0-1) below which source pixels are linework "
                             "(default INK_L; lower it for a dark cloth that must stay cloth, e.g. 0.15)")
    parser.add_argument("--no-outline", dest="outline", action="store_false", help="grid mode: no 1 px outline (tiles)")
    parser.add_argument("--inside-outline", action="store_true",
                        help="grid mode: turn the sprite's own edge into the outline (sources drawn at the target grid)")
    parser.add_argument("--no-rim", dest="rim", action="store_false", help="grid mode: no top-left rim light")
    parser.add_argument("--no-cleanup", dest="cleanup", action="store_false", help="grid mode: keep single-pixel noise")
    parser.add_argument("--no-prune", dest="prune", action="store_false", help="grid mode: keep every ramp, even stray ones")
    parser.add_argument("--no-center", dest="center", action="store_false", help="grid mode: centre the bounding box, not the body")
    parser.add_argument("--allow-floor", action="store_true", help="grid mode: allow the floor colours (ground tiles, decals)")
    parser.add_argument("--out", default="", help="grid mode: write here instead of assets/sprites/<key>.png")
    args = parser.parse_args()
    INK_L = args.ink_l  # --ink-l overrides the linework threshold for this run (read by grid_cells()).
    src = Path(args.source).expanduser()  # Image to process.
    key = args.key.strip("/")  # Sprite key or effect id.
    if args.anim:
        prepare_anim(src, key.removeprefix("effects/"), args.frames, args.grid, args.frame_px)
    elif args.legacy:
        prepare_legacy(src, key)
    elif args.frames > 0:
        prepare_walk(src, key, args)
    else:
        prepare_grid(src, key, args)


if __name__ == "__main__":
    main()
