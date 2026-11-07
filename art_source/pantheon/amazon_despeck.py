"""Amazon round 5: one gentle despeck pass before amazon_r5_fix.py (the conversion ran with
--no-cleanup to keep her face, abs and bust shapes; that left ~18% single-pixel specks). A body
pixel (not an outline ink, not the axe's marble) whose four neighbours share none of its colour
takes the most common colour among its eight body neighbours. One pass, no new colours.
Usage: amazon_despeck.py <in png> <out png>"""
import json, sys
from collections import Counter
from PIL import Image
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open('tools/palette.json'))['colors']}
SKIP = {P[n] for n in ('bronze_ink', 'ink_warm', 'ink_cold', 'marble_dark', 'marble', 'marble_light')}
im = Image.open(sys.argv[1]).convert('RGBA')
src = im.copy()
w, h = im.size
at = lambda x, y: src.getpixel((x, y)) if 0 <= x < w and 0 <= y < h else (0, 0, 0, 0)
n = 0
for y in range(h):
    for x in range(w):
        p = at(x, y)
        if p[3] == 0 or p in SKIP:
            continue
        if any(at(x + a, y + b) == p for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            continue
        c = Counter(q for a in (-1, 0, 1) for b in (-1, 0, 1) if (a or b) for q in [at(x + a, y + b)] if q[3] and q not in SKIP)
        if c:
            im.putpixel((x, y), c.most_common(1)[0][0]); n += 1
im.save(sys.argv[2])
print(n, 'pixels despecked')
