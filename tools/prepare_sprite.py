"""prepare_sprite.py: turn a ChatGPT-generated sprite into a game-ready PNG.

Usage (from the repo root):
    python3 tools/prepare_sprite.py <source image> <sprite key>
    e.g. python3 tools/prepare_sprite.py ~/Downloads/necro.png player/necromancer

Steps:
  1. Copies the untouched source to art_source/<key>.png. That folder has a
     .gdignore, so Godot never imports or exports the large originals.
  2. Crops the transparent border away (with a small margin).
  3. Resizes so the sprite is RENDER_SCALE x its on-screen height from
     scripts/data/sprite_data.gd (HEIGHTS), using high-quality Lanczos
     filtering, so Godot only scales it down a little at runtime.
  4. Writes assets/sprites/<key>.png, which SpriteBank picks up automatically.

Requires Pillow (pip install pillow). The source must have a transparent
background (the art bible asks ChatGPT for one).
"""

import re
import shutil
import sys
from pathlib import Path

from PIL import Image

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


def on_screen_height(key: str) -> float:
    """Reads the on-screen height for `key` from sprite_data.gd's HEIGHTS."""
    text = SPRITE_DATA.read_text()
    match = re.search(r'"%s"\s*:\s*([0-9.]+)' % re.escape(key), text)
    return float(match.group(1)) if match else DEFAULT_HEIGHT


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src = Path(sys.argv[1]).expanduser()  # ChatGPT image to process.
    key = sys.argv[2].strip("/")  # Sprite key, e.g. "player/necromancer".

    # 1. Keep the original.
    original = SOURCE_DIR / (key + ".png")  # Archived source path.
    original.parent.mkdir(parents=True, exist_ok=True)
    Image.open(src).convert("RGBA").save(original)

    # 2. Crop the transparent border.
    img = Image.open(original).convert("RGBA")  # Working image.
    alpha = img.getchannel("A").point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)  # Opaque mask.
    box = alpha.getbbox()  # Bounding box of the opaque pixels.
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


if __name__ == "__main__":
    main()
