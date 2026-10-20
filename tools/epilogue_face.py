"""epilogue_face.py: repaint the necromancer's face in an epilogue panel source like his game sprite.

Usage (from the repo root):
    python3 tools/epilogue_face.py <source png> <output png>
    e.g. python3 tools/epilogue_face.py art_source/epilogue/raw/act3_4.png art_source/epilogue/act3_4.png

Owner review, round 4 (act3_4): in the game the necromancer's face is a black void inside the hood with
two glowing violet eyes (assets/sprites/player/necromancer.png), and the AI source drew bone and teal
blotches there. This paints the hood opening black and puts the two eyes in by hand, so it matches the
sprite exactly and leaves every other pixel alone. The unpainted AI source is kept in art_source/epilogue/raw/ (out of
epilogue_panel.py --all's reach). The box and eye places are for act3_4's source.
"""

import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]  # Original source PNG, repainted output PNG.
im = Image.open(src).convert("RGB")
px = im.load()
BOX = (744, 612, 782, 656)  # Hood opening in source px (x0, y0, x1, y1), found on a 10 px grid.
VOID = (18, 10, 26)  # Ink of the hood's inside, the dark of the sprite's face (near ink_violet).
EYE = (163, 92, 250)  # violet #A35CFA, the sprite's eye colour.
EYE_CORE = (221, 189, 255)  # violet_light #DDBDFF, the bright centre of each eye.
for y in range(BOX[1], BOX[3]):
    for x in range(BOX[0], BOX[2]):
        r, g, b = px[x, y]
        hood = b > r + 20 and b > 100 and r > 60  # The violet hood cloth stays as it is.
        if not hood:
            px[x, y] = VOID
EYES = [(753, 626), (764, 626)]  # Top-left corner of each eye (source px), a little above the opening's middle.
EYE_SIZE = 6  # Eye width and height (source px): 4 panel art px after the 1.5x downscale, one sprite eye at this figure size.
for ex, ey in EYES:
    for y in range(ey, ey + EYE_SIZE):
        for x in range(ex, ex + EYE_SIZE):
            px[x, y] = EYE
    for y in range(ey + 1, ey + 4):  # A small bright core, upper-middle of the eye.
        for x in range(ex + 1, ex + 5):
            px[x, y] = EYE_CORE
im.save(out)
