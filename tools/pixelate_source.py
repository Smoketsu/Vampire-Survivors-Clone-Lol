"""pixelate_source.py: put a detailed AI source onto the exact art grid before conversion.

Usage (from the repo root):
    python3 tools/pixelate_source.py <source image> <art height> <output png>
    python3 tools/prepare_sprite.py <output png> <sprite key> [options]

Why (figure redesign, Oct 2026; ART_BIBLE "Converting small figures"): an AI image draws a
figure 900+ px tall, about 19 source px per art px for a 48 px summon. prepare_sprite.py votes
each cell by material and coverage, which fattens thin shapes and drops one-pixel dark lines, so
on the redesigned Banshee the neckline and the gap between the bust and the hair vanished and the
torso became one bone-white blob. The ART_BIBLE notes that a source already drawn on the target
grid converts almost losslessly. This tool makes one: binary alpha (ALPHA_CUT), crop to the
opaque pixels, a premultiplied box downscale to (art height - 2) rows (prepare_sprite adds a 1 px
outline top and bottom), then a BLOCK x nearest-neighbour blow-up, so every art pixel arrives as
one flat block and the converter only snaps colours and draws the outline. Copy the untouched
source to art_source/<key>.png afterwards (prepare_sprite archives the file it was given).
"""

import sys

import numpy as np
from PIL import Image

ALPHA_CUT = 128  # Source alpha (0-255) from which a pixel is opaque (same rule as prepare_sprite).
BLOCK = 16  # Output source px per art px (any whole number; 16 keeps files small).
OUTLINE_ROWS = 2  # Rows prepare_sprite adds around the content (1 px outline top and bottom).


def pixelate(src: str, height: int) -> Image.Image:
    """The source `src` reduced to (height - OUTLINE_ROWS) art rows and blown up BLOCK x."""
    a = np.array(Image.open(src).convert("RGBA"))
    a[..., 3] = np.where(a[..., 3] >= ALPHA_CUT, 255, 0)
    img = Image.fromarray(a)
    img = img.crop(img.getbbox())
    h = height - OUTLINE_ROWS  # Content rows (art px).
    w = max(1, round(img.width * h / img.height))  # Content columns, aspect kept (art px).
    pm = np.array(img).astype(float)
    pm[..., :3] *= pm[..., 3:4] / 255.0  # Premultiply: transparent pixels add no colour.
    small = np.array(Image.fromarray(pm.astype(np.uint8)).resize((w, h), Image.BOX)).astype(float)
    alpha = small[..., 3:4]  # Box-averaged coverage (0-255).
    rgb = np.where(alpha > 0, small[..., :3] * 255.0 / np.maximum(alpha, 1), 0)  # Un-premultiplied colour.
    out = np.dstack([np.clip(rgb, 0, 255), np.where(alpha >= ALPHA_CUT, 255, 0)]).astype(np.uint8)
    return Image.fromarray(out).resize((w * BLOCK, h * BLOCK), Image.NEAREST)


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    src, height, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]  # Source, art height (px), output.
    pixelate(src, height).save(out)
    print(f"{src} -> {out} ({height - OUTLINE_ROWS} content rows, {BLOCK} px blocks)")


if __name__ == "__main__":
    main()
