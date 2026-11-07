"""Amazon round 5: hand fixes on the grid after the conversion (pixelate_source.py 70 ->
amazon_presnap.py -> prepare_sprite.py --ink-l 0.15 --no-levels --no-prune --no-cleanup
--ramps bronze,marble,aegean,skin,brown,gold).
1. The war skirt repainted as one closed band (the converter curved its hem down in the middle,
   which read as a front flap, and dropped grey specks in it): a bronze belt (rows 33-34), flat
   Aegean pleats (rows 35-41, aegean with an aegean_dark pleat every third column and on the
   shadow side), a straight bronze hem across both thighs (row 42) and an ink line under it
   (row 43): no slit, no flap, no notch between the thighs.
2. The face in the helmet opening: a brow shadow, one clear eye (white and pupil), cheek, mouth.
3. A six-pack drawn on the stomach.
Run after amazon_despeck.py.
Usage (repo root): amazon_r5_fix.py <in png> <out png>"""
import json, sys
from PIL import Image
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open('tools/palette.json'))['colors']}
AB = {'K': 'bronze_ink', 'k': 'ink_warm', 'c': 'ink_cold', 'D': 'bronze_dark', 'B': 'bronze', 'L': 'bronze_light',
      'r': 'brown', 'R': 'brown_light', 's': 'skin', 'A': 'aegean_dark', 'a': 'aegean', '@': 'aegean_light', 'W': 'marble_light'}
im = Image.open(sys.argv[1]).convert('RGBA')


def put(x, y, ch):
    im.putpixel((x, y), P[AB[ch]])


# 1. Skirt: (row, first col, last col) of the band; the outer columns are outline.
BELT = [(33, 24, 42), (34, 24, 42)]
SKIRT = [(35, 24, 42), (36, 24, 42), (37, 23, 43), (38, 23, 43), (39, 22, 44), (40, 22, 45), (41, 21, 45)]  # Flared over the wide hips.
for y, x0, x1 in BELT:
    for x in range(x0, x1 + 1):
        if x in (x0, x1):
            put(x, y, 'K')
        elif y == 33:
            put(x, y, 'L' if x < 31 else 'B')
        else:
            put(x, y, 'B' if x < 31 else 'D')
put(33, 33, 'L'); put(34, 33, 'L'); put(33, 34, 'L'); put(34, 34, 'B')  # The buckle.
for y, x0, x1 in SKIRT:
    for x in range(x0, x1 + 1):
        if x in (x0, x1):
            put(x, y, 'c')
        elif x == x0 + 1 and y >= 37:
            put(x, y, '@')  # Lit flank of the flare (light from the top-left).
        elif x >= x1 - 3 or (x - 24) % 3 == 2:
            put(x, y, 'A')
        else:
            put(x, y, 'a')
for x in range(21, 46):  # The hem: one straight line across both thighs, ink under it.
    put(x, 42, 'c' if x in (21, 45) else ('L' if x < 29 else 'B'))
    if im.getpixel((x, 44))[3] or 22 <= x <= 44:
        put(x, 43, 'c')
# 2. The face: rows of (first col, pixels).
FACE = {12: (34, 'DDDDr'), 13: (34, 'sWkRs'), 14: (34, 'sssss'), 15: (34, 'BssRs'), 16: (34, 'BsRss'), 17: (34, 'BssR')}
for y, (x0, row) in FACE.items():
    for i, ch in enumerate(row):
        put(x0 + i, y, ch)
# 3. The abs (owner: "huge tits and hips and abs"): a six-pack on the bare stomach under the
# breastplate, a centre line and two cross lines in brown_light on the skin (cols 34-38).
ABS = {28: 'ssRss', 29: 'ssRss', 30: 'RRsRR', 31: 'ssRss', 32: 'RsRsR'}
for y, row in ABS.items():
    for i, ch in enumerate(row):
        put(34 + i, y, ch)
im.save(sys.argv[2])
