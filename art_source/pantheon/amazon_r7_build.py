"""Amazon round 7 (owner, art review round 6: "start again with fresh generation... the original style,
a bit stronger and more voluptuous, a bit scandalous"): builds assets/sprites/pantheon/amazon.png from the
fresh source art_source/pantheon/amazon.png (prompt amazon_r7.txt). The bronze and the tan skin sat close
and muddied through pixelate_source.py / prepare_sprite.py, so this converts by material instead:
  1. every opaque source pixel (alpha >= 200) gets a palette colour by hue / saturation / value rules
     made for this image (skin pinker than the bronze, hair darker and redder, Aegean, marble, inks);
  2. each art cell (the figure's height / 70 source px) takes its majority colour, ink when ink covers
     at least INK_SHARE of it (the source's 1-native-px lines survive the ~1.1x downscale);
  3. hand fixes on the grid (EDITS): the face, the belt and the war skirt (a curved hem cut high over the
     hips, one solid straight front across both thighs, open air between the thighs below it);
  4. placed like prepare_sprite.place(): feet on the last row, the lower body centred, even width.
Usage (from the repo root): python3 art_source/pantheon/amazon_r7_build.py"""
import colorsys, json
from collections import Counter
import numpy as np
from PIL import Image
ROWS = 70  # Art px tall (SpriteData.HEIGHTS["pantheon/amazon"]).
INK_SHARE = 0.38  # Share of a cell's source px that makes it ink (lines kept).
ALPHA_CUT = 200  # Source alpha at or above this is opaque.
BODY_ROWS = 0.6  # Lower share of the rows whose median column is centred (prepare_sprite.BODY_ROWS).
SRC = 'art_source/pantheon/amazon.png'  # The untouched round 7 source.
DEST = 'assets/sprites/pantheon/amazon.png'  # The game sprite.
PAL = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) for c in json.load(open('tools/palette.json'))['colors']}
INK = {'bronze_ink', 'ink_cold'}  # Outline inks.
CODE = {'K': 'bronze_ink', 'k': 'ink_cold', 'd': 'bronze_dark', 'b': 'bronze', 'B': 'bronze_light', 'S': 'skin', 's': 'brown_light', 'h': 'brown',
        'a': 'aegean_dark', 'A': 'aegean', 'L': 'aegean_light', 'm': 'marble_dark', 'M': 'marble', 'W': 'marble_light', 'i': 'ink_warm'}


def label(r, g, b):
    """Palette colour name for one source pixel, by material."""
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if 0.5 < h < 0.72 and s > 0.35:
        if v < 0.22: return 'ink_cold'
        if v < 0.45: return 'aegean_dark'
        if v < 0.78: return 'aegean'
        return 'aegean_light'
    if v < 0.22: return 'bronze_ink'
    if s < 0.2:
        if v < 0.62: return 'marble_dark'
        if v < 0.86: return 'marble'
        return 'marble_light'
    skin_h = 0.08 if v > 0.88 else 0.072
    if h < skin_h and s < 0.7 and v > 0.74:
        return 'skin' if v >= 0.88 else 'brown_light'
    if h < 0.068:
        return 'brown' if v < 0.4 else 'brown_light'
    if v < 0.58: return 'bronze_dark'
    if v < 0.89: return 'bronze'
    return 'bronze_light'


def convert():
    """Steps 1-2: the source as an RGBA art grid."""
    src = np.array(Image.open(SRC).convert('RGBA'))
    op = src[:, :, 3] >= ALPHA_CUT
    ys, xs = np.where(op)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    names = sorted(PAL)
    cache, lab = {}, np.full(op.shape, -1, int)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if op[y, x]:
                k = tuple(int(c) for c in src[y, x, :3])
                if k not in cache:
                    cache[k] = names.index(label(*k))
                lab[y, x] = cache[k]
    cell = (y1 - y0) / ROWS
    cols = int(np.ceil((x1 - x0) / cell))
    out = np.zeros((ROWS, cols, 4), np.uint8)
    for r in range(ROWS):
        for c in range(cols):
            blk = lab[int(round(y0 + r * cell)):int(round(y0 + (r + 1) * cell)), int(round(x0 + c * cell)):int(round(x0 + (c + 1) * cell))].ravel()
            opq = blk[blk >= 0]
            if blk.size == 0 or opq.size < 0.45 * blk.size:
                continue
            cnt = Counter(opq.tolist())
            n = cnt.most_common(1)[0][0]
            if names[n] not in INK and sum(v for k, v in cnt.items() if names[k] in INK) >= INK_SHARE * blk.size:
                n = max((k for k in cnt if names[k] in INK), key=lambda k: cnt[k])
            out[r, c] = PAL[names[n]] + (255,)
    return out


# Face (eye, cheek, nose, mouth, chin) repainted: the converter left it as ink with skin specks.
EDITS = [  # (row, first column, codes); '_' keeps a pixel, '.' clears it.
    (15, 22, "KWkSK"),
    (16, 22, "BSSSSK"),
    (17, 22, "KSSiK"),
    (18, 22, "KSSK"),
    (19, 22, "KKKK"),
]
def pleat(x):
    """Pleat colour of column x: light from the left, a shadow line every third column, the far side dark."""
    if x >= 26: return 'a' if x % 2 else 'A'
    if x <= 13: return 'L' if x % 3 else 'A'
    return 'a' if x % 3 == 2 else 'A'
def row(y, x0, x1, inner):
    EDITS.append((y, x0, 'K' + inner + 'K'))
# Belt (rows 35-36) with a light medallion over the buckle.
EDITS.append((35, 14, 'K' + 'BBBBBB' + 'BB' + 'BBbb' + 'K'))
EDITS.append((36, 13, 'K' + 'b' * 6 + 'BB' + 'bbbb' + 'd' + 'K'))
# The war skirt: pleats from the belt to a curved hem, short and cut high over the hips (the side
# tips at row 39), dipping to one straight solid front across both thighs (row 44). HEM[x] = hem row.
HEM = {11: 39, 12: 40, 13: 40, 14: 41, 15: 43, 16: 44, 17: 44, 18: 44, 19: 44, 20: 44, 21: 44, 22: 44, 23: 44,
       24: 43, 25: 41, 26: 40, 27: 40, 28: 39}
TOP = {11: 38, 12: 37, 27: 37, 28: 38}  # First skirt row per column (row 37 elsewhere).
for x, hem in HEM.items():
    for y in range(TOP.get(x, 37), hem):
        EDITS.append((y, x, pleat(x)))
    EDITS.append((hem, x, 'B' if x < 20 else 'b'))
    EDITS.append((hem + 1, x, 'K'))
    for y in range(hem + 2, 46):
        EDITS.append((y, x, 'S' if x not in (11, 28) else '_'))
EDITS += [(37, 11, 'K'), (36, 12, 'K'), (37, 28, 'K'), (38, 10, 'K'), (39, 10, 'K'), (38, 29, 'K'), (39, 29, 'K'), (40, 29, 'K')]
# Under the hem: open air between the thighs (the back drape removed), the thighs' inner ink kept.
EDITS += [(46, 19, 'K...K'), (47, 18, 'K....K'), (48, 18, 'K...K'), (49, 17, 'K...K')]
# The thighs' outer edges where the old side flaps were.
EDITS += [(41, 11, 'K'), (42, 10, 'KS'), (41, 29, 'K'), (42, 28, 'S')]



def place(g):
    """Step 4: crop, feet on the last row, the lower body's median column on the centre line."""
    ys, xs = np.nonzero(g[:, :, 3])
    g = g[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    gh, gw = g.shape[:2]
    rows = max(1, int(round(gh * BODY_ROWS)))
    c = int(round(float(np.median(np.nonzero(g[-rows:, :, 3])[1])) + 0.5))
    width = 2 * max(c, gw - c)
    width += width % 2
    canvas = np.zeros((ROWS, width, 4), np.uint8)
    canvas[ROWS - gh:, width // 2 - c:width // 2 - c + gw] = g
    return canvas


def main():
    g = convert()
    for y, x0, codes in EDITS:
        for i, ch in enumerate(codes):
            if ch != '_':
                g[y, x0 + i] = (0, 0, 0, 0) if ch == '.' else PAL[CODE[ch]] + (255,)
    img = Image.fromarray(place(g))
    img.save(DEST)
    print(DEST, img.size)


if __name__ == '__main__':
    main()
