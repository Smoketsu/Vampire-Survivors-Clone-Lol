"""prepare_sprite.py: turn a ChatGPT-generated sprite into a game-ready PNG.

Usage (from the repo root):
    python3 tools/prepare_sprite.py <source image> <sprite key>
    e.g. python3 tools/prepare_sprite.py ~/Downloads/necro.png player/necromancer

  Effect animations (docs/art/ART_BIBLE.md "Effects"):
    python3 tools/prepare_sprite.py --anim <GIF or sprite sheet> <effect id> [--frames N | --grid CxR]
    e.g. python3 tools/prepare_sprite.py --anim ~/Downloads/blast.png shadow_blast
  The source can be an animated GIF/WebP/APNG (its frames are used), a sprite
  sheet with N equal frames in one row (--frames N), a grid read left to right,
  top to bottom (--grid CxR), or a single row of frames separated by fully
  transparent gaps (the default for a still image: frames are found by those gaps).

Steps (still sprite):
  1. Copies the untouched source to art_source/<key>.png. That folder has a
     .gdignore, so Godot never imports or exports the large originals.
  2. Crops the transparent border away (with a small margin).
  3. Resizes so the sprite is RENDER_SCALE x its on-screen height from
     scripts/data/sprite_data.gd (HEIGHTS), using high-quality Lanczos
     filtering, so Godot only scales it down a little at runtime.
  4. Writes assets/sprites/<key>.png, which SpriteBank picks up automatically.

Steps (--anim):
  1. Copies the untouched source to art_source/effects/<id>.<ext>.
  2. Splits it into frames (see above).
  3. Crops every frame to one shared square around the effect (the union of
     the frames' opaque areas, centred), so the effect keeps its position and
     growth between frames. Frames found by transparent gaps are each centred
     instead, since their positions in the sheet are arbitrary.
  4. Resizes each frame to ANIM_FRAME_PX square and writes them side by side
     to assets/sprites/effects/<id>.png (AnimData reads the frame count as
     width / height).

Requires Pillow (pip install pillow). Sources must have a transparent
background (the art bible asks ChatGPT for one).
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageSequence

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# Folder of the untouched originals (ignored by Godot via .gdignore).
SOURCE_DIR = ROOT / "art_source"
# Folder of the in-game sprites (SpriteData.ROOT).
SPRITE_DIR = ROOT / "assets" / "sprites"
# Data file holding the on-screen heights (SpriteData.HEIGHTS).
SPRITE_DATA = ROOT / "scripts" / "data" / "sprite_data.gd"
# Stored resolution relative to the on-screen height (3 = crisp on 1080p+).
RENDER_SCALE = 3
# On-screen height (px) for keys missing from HEIGHTS (SpriteData.DEFAULT_HEIGHT).
DEFAULT_HEIGHT = 44.0
# Transparent margin kept around the cropped sprite, as a fraction of its height.
MARGIN = 0.03
# Alpha value (0-255) below which a pixel counts as background when cropping.
ALPHA_THRESHOLD = 8
# Stored size (px) of one square effect-animation frame (AnimData.FRAME_PX).
ANIM_FRAME_PX = 128
# Narrowest run of fully transparent columns (px) that counts as a gap between
# frames when splitting a sheet by gaps (narrower runs are holes inside a frame).
GAP_MIN_PX = 4
# Narrowest frame (px) kept when splitting by gaps (thinner slivers are specks).
MIN_FRAME_PX = 6


def on_screen_height(key: str) -> float:
    """Reads the on-screen height for `key` from sprite_data.gd's HEIGHTS."""
    text = SPRITE_DATA.read_text()
    match = re.search(r'"%s"\s*:\s*([0-9.]+)' % re.escape(key), text)
    return float(match.group(1)) if match else DEFAULT_HEIGHT


def opaque_mask(img: Image.Image) -> Image.Image:
    """Returns a 1-channel mask: 255 where `img` is opaque, 0 where background."""
    return img.getchannel("A").point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)


def prepare_still(src: Path, key: str) -> None:
    """Processes one still sprite into assets/sprites/<key>.png (see module doc)."""
    # 1. Keep the original.
    original = SOURCE_DIR / (key + ".png")  # Archived source path.
    original.parent.mkdir(parents=True, exist_ok=True)
    Image.open(src).convert("RGBA").save(original)

    # 2. Crop the transparent border.
    img = Image.open(original).convert("RGBA")  # Working image.
    box = opaque_mask(img).getbbox()  # Bounding box of the opaque pixels.
    if box is None:
        sys.exit("Image is fully transparent: nothing to crop.")
    img = img.crop(box)
    pad = int(img.height * MARGIN)  # Margin in px.
    padded = Image.new("RGBA", (img.width + 2 * pad, img.height + 2 * pad), (0, 0, 0, 0))  # Canvas with margin.
    padded.paste(img, (pad, pad))

    # 3. Resize to RENDER_SCALE x the on-screen height.
    target_h = round(on_screen_height(key) * RENDER_SCALE)  # Stored height (px).
    target_w = round(padded.width * target_h / padded.height)  # Width keeping aspect ratio.
    out = padded.resize((target_w, target_h), Image.LANCZOS)  # Game-ready sprite.

    # 4. Write the in-game sprite.
    dest = SPRITE_DIR / (key + ".png")  # In-game path (SpriteBank key).
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest, optimize=True)
    print(f"{key}: {src.name} -> {dest.relative_to(ROOT)} ({target_w}x{target_h}), original in {original.relative_to(ROOT)}")


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
    px = mask.load()  # Fast pixel access.
    filled = [any(px[x, y] for y in range(h)) for x in range(w)]  # Column has content.
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


def prepare_anim(src: Path, anim_id: str, frames_n: int, grid: str) -> None:
    """Processes a GIF or sprite sheet into assets/sprites/effects/<id>.png."""
    # 1. Keep the original (any format, untouched bytes).
    original = SOURCE_DIR / "effects" / (anim_id + src.suffix.lower())  # Archived source path.
    original.parent.mkdir(parents=True, exist_ok=True)
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
    strip = Image.new("RGBA", (ANIM_FRAME_PX * len(squares), ANIM_FRAME_PX), (0, 0, 0, 0))  # Output strip.
    for i, sq in enumerate(squares):
        strip.paste(sq.resize((ANIM_FRAME_PX, ANIM_FRAME_PX), Image.LANCZOS), (i * ANIM_FRAME_PX, 0))
    dest = SPRITE_DIR / "effects" / (anim_id + ".png")  # In-game path (SpriteBank "effects/<id>").
    dest.parent.mkdir(parents=True, exist_ok=True)
    strip.save(dest, optimize=True)
    print(f"effects/{anim_id}: {src.name} -> {dest.relative_to(ROOT)} ({len(squares)} frames by {how}, "
          f"{ANIM_FRAME_PX}px each), original in {original.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("source", help="image, GIF or sprite sheet to process")
    parser.add_argument("key", help="sprite key (e.g. player/necromancer) or, with --anim, effect id")
    parser.add_argument("--anim", action="store_true", help="process an effect animation")
    parser.add_argument("--frames", type=int, default=0, help="--anim: N equal frames in one row")
    parser.add_argument("--grid", default="", help="--anim: CxR grid of equal frames")
    args = parser.parse_args()
    src = Path(args.source).expanduser()  # Image to process.
    key = args.key.strip("/")  # Sprite key or effect id.
    if args.anim:
        prepare_anim(src, key.removeprefix("effects/"), args.frames, args.grid)
    else:
        prepare_still(src, key)


if __name__ == "__main__":
    main()
