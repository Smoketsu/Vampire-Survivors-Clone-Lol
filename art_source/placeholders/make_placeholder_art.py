"""make_placeholder_art.py: builds the derived art of the placeholder art batch (Oct 2026).

Usage (from the repo root):
    python3 art_source/placeholders/make_placeholder_art.py            # rebuild everything below
    python3 art_source/placeholders/make_placeholder_art.py --out DIR  # write candidates to DIR

The placeholder batch (docs/art/ART_BIBLE.md "Placeholder art batch", GDD 15.0 "Placeholder art
batch") replaced the last code-drawn world markers, overlays and icons with pixel art. Most of it
was generated (tools/gen_image.py, prompts in art_source/placeholders/prompts/) and converted with
tools/prepare_sprite.py like any sprite. This script makes the pieces that are DERIVED from art
already in the game, so they need no image generation and stay pixel-exact with their parents:

  * icons/heal, icons/grave_fortitude, icons/call_of_the_grave: the three fallback level-up cards'
    badges. Each converted 26 px symbol (art_source/placeholders/symbols/<id>.png, the output of
    prepare_sprite.py --art-height 26 --no-center) is centred on the violet cut-corner badge
    template cut from an approved badge (icons/tree_survival.png: its cut-corner silhouette kept, its
    1 px edge ring violet and its face ink violet), like every icon of the art pass.
  * icons/tree_oath: the Ossuary's Oath tree emblem. The Oath tree holds one upgrade, the Profane
    Oath, so its emblem is that upgrade's badge (icons/profane_oath.png), copied.
  * summons/cathedral_horror_stone: the Cathedral Horror in its stone form, the same silhouette and
    pose as summons/cathedral_horror.png turned to grey stone: every outline ink becomes the cold
    ink, every body colour takes the grey ramp shade of its OKLab lightness (STONE_BANDS), and the
    teal soul runes go dark (grey_dark: the statue is dormant).
  * ui/rotate_phone: the phone of the "turn your device" overlay (RotateOverlay), drawn
    procedurally (PHONE_W x PHONE_H art px, soul-teal case, cut corners, dark screen, home dot);
    the overlay draws it upright and turned at its layout size.

Deterministic: the same inputs give the same PNGs. Requires Pillow and numpy.
"""

import argparse
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent  # art_source/placeholders/
ROOT = HERE.parent.parent  # Repo root.
sys.path.insert(0, str(ROOT / "tools"))
from pixel_palette import Palette, srgb_to_oklab  # noqa: E402

SPRITES = ROOT / "assets" / "sprites"  # In-game sprite folder.
SYMBOLS = HERE / "symbols"  # Converted 26 px icon symbols (prepare_sprite.py output).
BADGE_ICONS = ["heal", "grave_fortitude", "call_of_the_grave"]  # Fallback card badges built here.
BADGE_TEMPLATE = "icons/tree_survival"  # Approved violet badge whose silhouette (cut corners) is reused.
BADGE_SIZE = 32  # Badge side (art px).
SYMBOL_BOX = 26  # Symbol box inside the badge (art px), centred.
# Lightness bands (OKLab L upper bounds) mapping a body colour to a grey ramp shade (stone form).
STONE_BANDS = [(0.55, "grey_dark"), (0.80, "grey"), (2.0, "grey_light")]
PHONE_W = 35  # Rotate-overlay phone width (art px), drawn x2 on the 70 x 120 layout phone.
PHONE_H = 60  # Rotate-overlay phone height (art px).
PHONE_CUT = 6  # Corner cut of the phone case (art px).
PHONE_WALL = 3  # Case thickness around the screen (art px).


def load(key: str) -> np.ndarray:
    """RGBA array of assets/sprites/<key>.png."""
    return np.array(Image.open(SPRITES / (key + ".png")).convert("RGBA"))


def save(arr: np.ndarray, key: str, out: Path) -> None:
    """Writes `arr` as <out>/<key>.png and reports it."""
    dest = out / (key + ".png")
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(dest, optimize=True)
    print(f"{key}: {arr.shape[1]}x{arr.shape[0]} -> {dest.relative_to(ROOT) if dest.is_relative_to(ROOT) else dest}")


def colour(pal: Palette, name: str) -> np.ndarray:
    """RGBA of palette colour `name`, opaque."""
    return np.array(list(pal.rgb[pal.index_of[name]]) + [255], dtype=np.uint8)


def badge_template(pal: Palette) -> np.ndarray:
    """The badge template: the approved badge's silhouette (its cut corners), its 1 px edge ring in
    violet and every pixel inside the ring ink violet. The ring is found by shape (an opaque pixel
    with a transparent or off-image 8-neighbour), so no symbol colour can be mistaken for it."""
    src = load(BADGE_TEMPLATE)
    opaque = src[..., 3] > 0
    pad = np.pad(opaque, 1, constant_values=False)
    h, w = opaque.shape
    edge = np.zeros_like(opaque)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            edge |= ~pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    out = np.zeros_like(src)
    out[opaque] = colour(pal, "ink_violet")
    out[opaque & edge] = colour(pal, "violet")
    return out


def build_badges(pal: Palette, out: Path) -> None:
    """The fallback cards' badges: each symbol centred on the badge template."""
    tpl = badge_template(pal)
    for kind in BADGE_ICONS:
        sym = np.array(Image.open(SYMBOLS / (kind + ".png")).convert("RGBA"))
        ys, xs = np.where(sym[..., 3] > 0)
        sym = sym[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        h, w = sym.shape[:2]
        if h > SYMBOL_BOX or w > SYMBOL_BOX:
            sys.exit(f"{kind}: symbol {w}x{h} exceeds the {SYMBOL_BOX} px box")
        badge = tpl.copy()
        y0 = (BADGE_SIZE - h) // 2
        x0 = (BADGE_SIZE - w) // 2
        region = badge[y0:y0 + h, x0:x0 + w]
        mask = sym[..., 3] > 0
        region[mask] = sym[mask]
        save(badge, "icons/" + kind, out)


def build_tree_oath(out: Path) -> None:
    """The Oath tree emblem: a copy of the Profane Oath badge (the tree's only upgrade)."""
    dest = out / "icons" / "tree_oath.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SPRITES / "icons" / "profane_oath.png", dest)
    print(f"icons/tree_oath: copy of icons/profane_oath -> {dest}")


def build_stone(pal: Palette, out: Path) -> None:
    """The Cathedral Horror turned to stone (same pixels, grey ramp by lightness, dark runes)."""
    src = load("summons/cathedral_horror")
    res = src.copy()
    opaque = src[..., 3] > 0
    lab = srgb_to_oklab(src[..., :3])
    for y, x in zip(*np.where(opaque)):
        idx = pal.rgb_lookup.get(tuple(int(v) for v in src[y, x, :3]))
        if idx is None:
            sys.exit(f"cathedral_horror: off-palette pixel at {x},{y}")
        if pal.is_ink(idx):
            name = "ink_cold"
        elif pal.ramp[idx] == "soul":
            name = "grey_dark"  # Dormant runes.
        else:
            name = next(n for lim, n in STONE_BANDS if lab[y, x, 0] < lim)
        res[y, x] = colour(pal, name)
    save(res, "summons/cathedral_horror_stone", out)


def build_phone(pal: Palette, out: Path) -> None:
    """The rotate overlay's phone: a soul-teal case with cut corners, a dark screen and a home dot."""
    w, h, cut = PHONE_W, PHONE_H, PHONE_CUT
    img = np.zeros((h, w, 4), dtype=np.uint8)

    def inside(x: int, y: int, x0: int, y0: int, x1: int, y1: int, c: int) -> bool:
        """True when (x, y) lies in the rect [x0, x1) x [y0, y1) with its corners cut by c."""
        if not (x0 <= x < x1 and y0 <= y < y1):
            return False
        dx = min(x - x0, x1 - 1 - x)
        dy = min(y - y0, y1 - 1 - y)
        return dx + dy >= c

    sx0, sy0 = PHONE_WALL + 1, PHONE_WALL + 5  # Screen top-left (art px): a taller top bezel.
    sx1, sy1 = w - PHONE_WALL - 1, h - PHONE_WALL - 7  # Screen bottom-right (exclusive).
    for y in range(h):
        for x in range(w):
            if not inside(x, y, 0, 0, w, h, cut):
                continue
            if not inside(x, y, 1, 1, w - 1, h - 1, cut):
                name = "ink_green"  # Outline.
            elif inside(x, y, sx0, sy0, sx1, sy1, 2):
                name = "ink_violet"  # Screen.
            elif inside(x, y, sx0 - 1, sy0 - 1, sx1 + 1, sy1 + 1, 3):
                name = "ink_green"  # Screen bezel line.
            elif x <= 2 or y <= 2 or not inside(x, y, 2, 2, w - 1, h - 1, cut):
                name = "soul"  # Lit top-left edge of the case.
            else:
                name = "soul_dark"  # Case.
            img[y, x] = colour(pal, name)
    # Home button: a 4 x 2 soul-glow bar centred under the screen; speaker slit above the screen.
    hx = w // 2 - 2
    hy = sy1 + 3
    img[hy:hy + 2, hx:hx + 4] = colour(pal, "soul_glow")
    img[sy0 - 3, w // 2 - 3:w // 2 + 3] = colour(pal, "ink_green")
    # A small violet soul glint in the screen's top-left (the screen is lit).
    img[sy0 + 2:sy0 + 4, sx0 + 2:sx0 + 3] = colour(pal, "violet_deep")
    save(img, "ui/rotate_phone", out)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", default="", help="write here instead of assets/sprites/")
    args = parser.parse_args()
    out = Path(args.out) if args.out else SPRITES
    pal = Palette()
    build_badges(pal, out)
    build_tree_oath(out)
    build_stone(pal, out)
    build_phone(pal, out)


if __name__ == "__main__":
    main()
