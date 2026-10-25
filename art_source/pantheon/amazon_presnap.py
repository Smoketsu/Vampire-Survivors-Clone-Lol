"""Amazon pre-snap (round 1 redo, reused in round 5): her tan skin sits next to the bronze and
converts to it, so lit skin pixels are snapped to the palette's skin shades by hue before
prepare_sprite.py (hue below 0.068, saturation 0.4-0.8: lit -> skin, shade -> brown_light).
Usage: amazon_presnap.py <in png> <out png>"""
import colorsys, sys
from PIL import Image
SKIN, SHADE = (0xE0, 0xA8, 0x82), (0x8C, 0x60, 0x40)
im = Image.open(sys.argv[1]).convert('RGBA')
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a < 128:
            continue
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if h < 0.068 and 0.4 <= s <= 0.8 and v > 0.35:
            px[x, y] = (SKIN if v >= 0.7 else SHADE) + (a,)
im.save(sys.argv[2])
