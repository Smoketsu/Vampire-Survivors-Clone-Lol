"""touchups.py: scripted touch-ups after a fresh conversion of the Act VI shared kinds (run by build.sh; NOT idempotent).

The imp hovers (walk_cycle.py "hover" bobs the whole sprite 2 px), so its still needs two empty rows on top: this adds them
to the 30 px conversion (a 32 px still; SpriteData HEIGHTS "inferno/imp" 32).
"""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "sprites", "inferno") + os.sep

im = Image.open(ROOT + "imp.png").convert("RGBA")
out = Image.new("RGBA", (im.width, im.height + 2), (0, 0, 0, 0))
out.paste(im, (0, 2))
out.save(ROOT + "imp.png")
