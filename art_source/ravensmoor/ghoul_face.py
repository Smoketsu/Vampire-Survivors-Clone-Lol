"""One-off hand edit of the generated Ghoul still: paint a readable face (brow, two red eyes in dark sockets, teeth, jaw) on its head."""
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
INK = (18, 6, 10, 255)      # darkest outline ink
SOCK = (15, 20, 28, 255)    # dark slate: brow and eye sockets
EYE = (224, 56, 78, 255)    # glowing red eye
EYE_D = (163, 20, 42, 255)  # mid blood red
MOUTH = (90, 10, 20, 255)   # deep red mouth
TOOTH = (230, 238, 247, 255)
MID = (110, 122, 140, 255)  # mid grey skin
LIGHT = (167, 179, 198, 255)
paint = {
    # brow ridge, a dark band over the eyes
    (21, 5): SOCK, (22, 5): SOCK, (23, 5): SOCK, (24, 5): SOCK, (25, 5): SOCK, (26, 5): SOCK,
    # eyes in dark sockets
    (22, 6): SOCK, (23, 6): EYE, (24, 6): SOCK, (25, 6): EYE, (26, 6): SOCK,
    # sunken cheek and nose
    (21, 7): MID, (22, 7): SOCK, (23, 7): MID, (24, 7): LIGHT, (25, 7): MID, (26, 7): MID,
    (22, 8): SOCK, (23, 8): MID, (24, 8): LIGHT, (25, 8): MID, (26, 8): MID,
    # mouth with teeth, jaw under it
    (22, 9): MOUTH, (23, 9): TOOTH, (24, 9): MOUTH, (25, 9): TOOTH, (26, 9): MOUTH,
}
for (x, y), c in paint.items():
    if im.getpixel((x, y))[3]:
        im.putpixel((x, y), c)
im.save(out)
