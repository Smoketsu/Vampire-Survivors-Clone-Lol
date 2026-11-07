"""make_badges.py: the Ossuary expansion step 3 badges (GDD §15.0 "Ossuary new options and
Dominion"): every 26 art px symbol in symbols/ (tools/prepare_sprite.py output of the generated
sources, archived in art_source/icons/) centred on the violet cut-corner badge template, written
to assets/sprites/icons/<icon>.png (32 x 32 art px). The template is the art pass's: the approved
badge icons/tree_survival's silhouette, its 1 px edge ring violet, its face ink violet (the same
rule as art_source/placeholders/make_placeholder_art.py). Deterministic. Pillow + numpy.

Run from the repo root:  python3 art_source/ossuary_options/make_badges.py
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent  # art_source/ossuary_options/
ROOT = HERE.parent.parent  # Repo root.
SPRITES = ROOT / "assets" / "sprites"  # In-game sprite folder.
TEMPLATE = SPRITES / "icons" / "tree_survival.png"  # Approved badge whose cut corners are reused.
BADGE = 32  # Badge side (art px).
BOX = 26  # Symbol box inside the badge (art px).
INK_VIOLET = (0x16, 0x0A, 0x21, 255)  # Badge face (palette ink_violet).
VIOLET = (0x7A, 0x42, 0xAD, 255)  # Badge ring (palette violet).


def template() -> np.ndarray:
    """The badge: the template's silhouette, its edge ring violet, the rest ink violet."""
    src = np.array(Image.open(TEMPLATE).convert("RGBA"))
    opaque = src[..., 3] > 0
    pad = np.pad(opaque, 1, constant_values=False)
    h, w = opaque.shape
    edge = np.zeros_like(opaque)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            edge |= ~pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    out = np.zeros_like(src)
    out[opaque] = INK_VIOLET
    out[opaque & edge] = VIOLET
    return out


def main() -> None:
    tpl = template()
    for path in sorted((HERE / "symbols").glob("*.png")):
        sym = np.array(Image.open(path).convert("RGBA"))
        ys, xs = np.where(sym[..., 3] > 0)
        sym = sym[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        h, w = sym.shape[:2]
        if h > BOX or w > BOX:
            sys.exit(f"{path.stem}: symbol {w}x{h} exceeds the {BOX} px box")
        badge = tpl.copy()
        y0 = (BADGE - h) // 2
        x0 = (BADGE - w) // 2
        region = badge[y0:y0 + h, x0:x0 + w]
        mask = sym[..., 3] > 0
        region[mask] = sym[mask]
        dest = SPRITES / "icons" / (path.stem + ".png")
        Image.fromarray(badge.astype(np.uint8), "RGBA").save(dest, optimize=True)
        print(f"icons/{path.stem}: {w}x{h} symbol -> {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
