#!/usr/bin/env python3
"""volley_art.py: turn the generated volley art into the game's tint masks.

The bullet heaven pass (GDD 15.0 "Bullet heaven pass" and "Volley art") draws every volley
shot and burst with ADDITIVE blending, tinted with the colour of the class or spell that fired
it (VolleyData). So the art is not palette-coloured like the units: each file is a GREY TINT
MASK (white = the hot core, darker greys = the glow and trail), and the game multiplies it by
the shot's colour. One image per shape serves all twelve classes and their evolutions.

Usage (from the repo root):
    python3 tools/volley_art.py shot <source png> <style>       # assets/sprites/volleys/<style>.png
    python3 tools/volley_art.py strip <source sheet> <id> [--frames N]
                                                                 # assets/sprites/effects/<id>.png

shot:  crops to the art, scales it so the longest side is SHOT_PX (WAVE_PX for "wave"), keeps it
       pointing right, centres it on a canvas of that size, snaps every pixel to GREY_LEVELS
       stepped greys (no dithering) and makes alpha binary (ALPHA_CUT). The untouched source is
       archived to art_source/volleys/<style>.png.
strip: splits the sheet's frames at the transparent gaps between them (exactly N expected; with
       a different count the sheet is cut into N equal columns), centres each frame on its alpha
       centroid in one shared square (so the burst never jumps), scales the strip to FRAME_PX
       frames, then the same grey snap and binary alpha. Source archived to
       art_source/effects/<id>.png. The strip plays through SpriteBank.draw_anim() like every
       other effect strip (timing in scripts/data/anim_data.gd).
"""
import argparse
import os
import shutil

from PIL import Image

# Longest side (px) of a stored shot mask. The game draws it with linear filtering at about
# 15-45 px, so 40 px keeps the pixel steps visible without shimmering when scaled down.
SHOT_PX = 40
# Longest side (px) of the sword-wave mask (drawn up to about 90 px across).
WAVE_PX = 72
# Frame size (px) of an effect strip (drawn about 16-60 px across).
FRAME_PX = 64
# Number of stepped greys a mask may use (the darkest is the faint glow, the lightest white).
GREY_LEVELS = 5
# Lightest grey (0-255) a pixel may snap to: pure white for the core.
GREY_MAX = 255
# Darkest grey (0-255) a pixel may snap to: dimmer than this reads as nothing under additive blend.
GREY_MIN = 80
# Alpha (0-255) at or above which a pixel is opaque after scaling; below it, transparent.
ALPHA_CUT = 110
# Margin (fraction of the frame) kept empty around the largest frame of a strip.
STRIP_MARGIN = 0.04

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Repo root.


def snap_greys(im: Image.Image) -> Image.Image:
    """Returns `im` with binary alpha and every opaque pixel on GREY_LEVELS stepped greys."""
    im = im.convert("RGBA")
    px = im.load()
    step = (GREY_MAX - GREY_MIN) / float(GREY_LEVELS - 1)  # Grey step between two levels.
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < ALPHA_CUT:
                px[x, y] = (0, 0, 0, 0)
                continue
            lum = 0.299 * r + 0.587 * g + 0.114 * b  # Source lightness (0-255).
            # Stretch the source's dark-to-white range onto GREY_MIN..GREY_MAX, then step it.
            t = max(0.0, min(1.0, (lum - 40.0) / 215.0))
            v = int(round(GREY_MIN + round(t * (GREY_LEVELS - 1)) * step))
            px[x, y] = (v, v, v, 255)
    return im


def shot(src: str, style: str) -> None:
    """Converts one shot sprite (see the module docstring)."""
    im = Image.open(src).convert("RGBA")
    box = im.getchannel("A").point(lambda a: 255 if a >= ALPHA_CUT else 0).getbbox()
    im = im.crop(box)
    side = WAVE_PX if style == "wave" else SHOT_PX  # Stored longest side (px).
    k = side / float(max(im.width, im.height))  # Source px -> stored px.
    im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((side - im.width) // 2, (side - im.height) // 2))
    # Crop back to the shape's own height (rows), keeping the full width: flat sprites are
    # scaled by their longest side and drawn centred.
    out = snap_greys(canvas)
    bb = out.getbbox()
    out = out.crop((0, bb[1], side, bb[3])) if bb else out
    _archive(src, os.path.join(ROOT, "art_source", "volleys", style + ".png"))
    dst = os.path.join(ROOT, "assets", "sprites", "volleys", style + ".png")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    out.save(dst)
    print("%s: %dx%d -> %s" % (style, out.width, out.height, os.path.relpath(dst, ROOT)))


def _columns(alpha: Image.Image) -> list:
    """Returns the [x0, x1) column runs of `alpha` that hold any opaque pixel."""
    w, h = alpha.size
    px = alpha.load()
    filled = [any(px[x, y] >= ALPHA_CUT for y in range(h)) for x in range(w)]
    runs, start = [], None
    for x, f in enumerate(filled + [False]):
        if f and start is None:
            start = x
        elif not f and start is not None:
            runs.append([start, x])
            start = None
    return runs


def strip(src: str, anim_id: str, frames: int) -> None:
    """Converts one effect sheet into a strip (see the module docstring)."""
    im = Image.open(src).convert("RGBA")
    runs = _columns(im.getchannel("A"))
    # Merge the narrowest gaps until exactly `frames` runs remain (sparks split a frame).
    while len(runs) > frames:
        gaps = [runs[i + 1][0] - runs[i][1] for i in range(len(runs) - 1)]
        i = gaps.index(min(gaps))
        runs[i:i + 2] = [[runs[i][0], runs[i + 1][1]]]
    if len(runs) != frames:
        cw = im.width / float(frames)  # Equal column width (px).
        runs = [[round(i * cw), round((i + 1) * cw)] for i in range(frames)]
    cells = []  # (frame image, centroid x, centroid y) per frame.
    for x0, x1 in runs:
        f = im.crop((x0, 0, x1, im.height))
        a = f.getchannel("A")
        ap = a.load()
        sx = sy = n = 0
        for y in range(f.height):
            for x in range(f.width):
                if ap[x, y] >= ALPHA_CUT:
                    sx += x
                    sy += y
                    n += 1
        cx, cy = (sx / n, sy / n) if n else (f.width / 2.0, f.height / 2.0)
        cells.append((f, cx, cy))
    # One shared square: the farthest opaque pixel from its frame's centroid, over all frames.
    reach = 1.0
    for f, cx, cy in cells:
        bb = f.getchannel("A").point(lambda v: 255 if v >= ALPHA_CUT else 0).getbbox()
        if bb:
            reach = max(reach, cx - bb[0], bb[2] - cx, cy - bb[1], bb[3] - cy)
    side = int(reach * 2.0 * (1.0 + STRIP_MARGIN * 2.0)) + 2  # Square cell size (source px).
    out = Image.new("RGBA", (FRAME_PX * frames, FRAME_PX), (0, 0, 0, 0))
    for i, (f, cx, cy) in enumerate(cells):
        cell = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        cell.alpha_composite(f, (int(round(side / 2.0 - cx)), int(round(side / 2.0 - cy))))
        cell = cell.resize((FRAME_PX, FRAME_PX), Image.LANCZOS)
        out.alpha_composite(cell, (i * FRAME_PX, 0))
    out = snap_greys(out)
    _archive(src, os.path.join(ROOT, "art_source", "effects", anim_id + ".png"))
    dst = os.path.join(ROOT, "assets", "sprites", "effects", anim_id + ".png")
    out.save(dst)
    print("%s: %d frames of %d px -> %s" % (anim_id, frames, FRAME_PX, os.path.relpath(dst, ROOT)))


def _archive(src: str, dst: str) -> None:
    """Keeps the untouched source next to the other art sources (Godot ignores art_source/)."""
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.abspath(src) != os.path.abspath(dst):
        shutil.copyfile(src, dst)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["shot", "strip"])
    ap.add_argument("src")
    ap.add_argument("key")
    ap.add_argument("--frames", type=int, default=6)
    args = ap.parse_args()
    if args.mode == "shot":
        shot(args.src, args.key)
    else:
        strip(args.src, args.key, args.frames)


if __name__ == "__main__":
    main()
