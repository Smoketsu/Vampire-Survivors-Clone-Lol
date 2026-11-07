"""Round 5 Hades, after prepare_sprite.py (--ink-l 0.15 --ramps grey,marble,aegean,bronze, levels on,
as round 1) converted the three image-tool EDITS of the round 1 sources (scheme E's colours):
1. Whole-sprite colour steps, no masks: the robe greys one step darker as round 1 did
   (grey_light -> grey, grey -> grey_dark) and the cloak's top shade one step down
   (aegean_light -> aegean), so the cloak is midnight blue (aegean_dark, aegean folds).
2. The approved round 1 head pasted back exactly (pixels copied unchanged from the round 1 sprite,
   commit 16ea7aa, aligned by the best crown/face match: offset 0 for hades and hades_bident,
   -2 px for hades_kneel, which converted 2 px narrower), inside the rectangles below (round 1
   coordinates, x0, y0, x1, y1 exclusive), chosen so they hold only flames, crown, hair, face and
   beard: the converter had redrawn the face and greyed the beard.
Usage (repo root): hades_shift.py <key> <converted png> <round 1 png> <out png>"""
import json, sys
from PIL import Image
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open('tools/palette.json'))['colors']}
MAP = {P['grey']: P['grey_dark'], P['grey_light']: P['grey'], P['aegean_light']: P['aegean']}
HEAD = {  # key: (dx new - round 1, [rectangles in round 1 coordinates])
    'hades': (0, [(18, 0, 56, 30), (35, 30, 56, 34)]),
    'hades_bident': (0, [(45, 0, 80, 25), (62, 25, 76, 35)]),
    'hades_kneel': (-2, [(36, 0, 62, 16), (42, 16, 56, 27), (56, 24, 80, 38)]),
}
key, src, r1p, out = sys.argv[1:5]
im = Image.open(src).convert('RGBA')
im.putdata([MAP.get(p, p) for p in im.getdata()])
r1 = Image.open(r1p).convert('RGBA')
dx, boxes = HEAD[key]
for x0, y0, x1, y1 in boxes:
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x + dx < im.width:
                im.putpixel((x + dx, y), r1.getpixel((x, y)))
if key == 'hades_kneel':
    # 3. The converter drew the fallen bident's bronze_ink outline two pixels thick: an outer
    # bronze_ink pixel (touching the background, no non-ink neighbour) is dropped.
    ink = P['bronze_ink']
    w, h = im.size
    def at(x, y):
        return im.getpixel((x, y)) if 0 <= x < w and 0 <= y < h else (0, 0, 0, 0)
    drop = []
    for y in range(h):
        for x in range(w):
            if im.getpixel((x, y)) != ink:
                continue
            n = [at(x + a, y + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if any(q[3] == 0 for q in n) and not any(q[3] and q != ink and q not in (P['ink_cold'],) for q in n):
                drop.append((x, y))
    for x, y in drop:
        im.putpixel((x, y), (0, 0, 0, 0))
im.save(out)
