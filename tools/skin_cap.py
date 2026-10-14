"""skin_cap.py: keep a source image's lit skin on the palette's skin tone before conversion.

Usage (from the repo root):
    python3 tools/skin_cap.py <source image> <output png> [--preview PNG]

Why (figure redesign, Oct 2026; ART_BIBLE "Converting skin"): the palette's `skin` ramp runs
ink_warm, brown_light, skin, bone, so its lightest shade is the ivory `bone`. Converted with
`prepare_sprite.py --no-levels` (the setting that keeps Seraphine's gold from sinking to brown),
every skin highlight brighter than `skin` snapped to that ivory and her face, chest, hands and
leg read as white cloth. This tool finds the skin in the source by colour (a warm peach hue band,
between the low-saturation ivory cloth and the saturated gold trim) and sets every skin pixel
brighter than the palette's `skin` to exactly `skin`; darker skin is left as drawn, so the shade
still lands on `skin` / `brown_light`. Run it on the source, then convert the output:
    python3 tools/skin_cap.py src.png /tmp/capped.png
    python3 tools/prepare_sprite.py /tmp/capped.png bosses/seraphine --no-levels
(and copy the untouched source to art_source/<key>.png, which prepare_sprite overwrote with the
capped copy). With --preview it also writes the mask (skin in magenta over the dimmed image).
"""

import argparse

import numpy as np
from PIL import Image

HUE = (0.02, 0.085)  # Skin hue band (0-1, ~7-31 degrees): warm peach, below the gold (~0.11).
SAT = (0.18, 0.62)  # Skin saturation band (0-1): above the ivory cloth, below the gold trim.
VAL = (0.45, 1.0)  # Skin value band (0-1): lit and mid skin (darker cells shade correctly anyway).
ALPHA_MIN = 128  # Source alpha (0-255) from which a pixel counts as opaque.
SKIN = np.array([0xE0, 0xA8, 0x82], dtype=float)  # Palette `skin` (#E0A882), RGB 0-255.
LUMA = np.array([0.299, 0.587, 0.114])  # Rec. 601 luma weights (brightness comparison).


def skin_mask(img: np.ndarray) -> np.ndarray:
    """Boolean HxW mask of the opaque skin-coloured pixels of the RGBA array `img`."""
    rgb = img[..., :3].astype(float) / 255.0  # Colour channels, 0-1.
    mx, mn = rgb.max(-1), rgb.min(-1)  # Per-pixel max / min channel.
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)  # HSV saturation.
    d = np.maximum(mx - mn, 1e-6)  # Chroma (guarded against 0).
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0  # HSV hue, 0-1.
    return ((img[..., 3] >= ALPHA_MIN) & (hue >= HUE[0]) & (hue <= HUE[1])
            & (sat >= SAT[0]) & (sat <= SAT[1]) & (mx >= VAL[0]) & (mx <= VAL[1]))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", help="AI source image")
    ap.add_argument("out", help="output PNG (the capped copy to convert)")
    ap.add_argument("--preview", default="", help="also write the skin mask preview here")
    args = ap.parse_args()
    img = np.array(Image.open(args.source).convert("RGBA"))
    mask = skin_mask(img)
    bright = mask & ((img[..., :3].astype(float) @ LUMA) > float(SKIN @ LUMA))  # Lit skin above the palette tone.
    img[bright, :3] = SKIN.astype(np.uint8)
    Image.fromarray(img).save(args.out)
    if args.preview:
        vis = np.array(Image.open(args.source).convert("RGBA"))
        vis[..., :3] //= 3
        vis[mask] = (255, 0, 255, 255)
        Image.fromarray(vis).save(args.preview)
    print(f"{args.source}: {int(mask.sum())} skin px, {int(bright.sum())} capped at skin -> {args.out}")


if __name__ == "__main__":
    main()
