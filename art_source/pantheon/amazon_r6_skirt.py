"""Amazon round 6 (owner: "the skirt is too boxy... it should swish in front of her, and show off
her thighs"): only the war skirt of the approved round 5 still is repainted on the grid; the body,
armour, face, abs, axe and shield stay pixel for pixel.

The skirt (shape after one image-tool edit of the round 5 source, art_source/pantheon/
amazon_r6_skirt.txt, used only as a guide): the bronze belt (rows 33-34) unchanged; a front panel
(cols 26-41, wider than the thighs' inner halves) that hangs over the crotch to row 46, below where the thighs part (row 45), its lower
edge one rounded hem (flat in the middle): no slit, gap, notch, V or point; two short side flaps that
flare out from the belt and are cut high, their hems rising toward the flared tips (the swish), so
the thighs show under them. Pleats hang straight on the panel and fan out on the flaps; a bronze
trim on every hem, ink edges round the outside and down the panel's sides below the flaps; under
the hems a brown shadow on the skin, or an ink edge over the gap between the thighs. The thighs freed at the sides are skin with the shadow side (right) and inner edge in
brown_light; the left column next to the shield is restored from the conversion
(art_source/pantheon/amazon_r5_base.png, round 5's despecked base) where round 5 painted skirt.
Usage (repo root): amazon_r6_skirt.py <round 5 still> <round 5 base> <out png>"""
import json, math, sys
from PIL import Image
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open('tools/palette.json'))['colors']}
AB = {'c': 'ink_cold', 'k': 'ink_warm', 'B': 'bronze', 'L': 'bronze_light', 'D': 'bronze_dark', 'r': 'brown',
      'R': 'brown_light', 's': 'skin', 'A': 'aegean_dark', 'a': 'aegean', '@': 'aegean_light'}
CENTRE = 33.5  # Column between the thighs (art px; they part at cols 33-34 from row 45).
TOP = 35  # First skirt row under the belt.
X0, X1 = 23, 44  # Skirt columns (inclusive); cols 22 and 45 are its edge.
im = Image.open(sys.argv[1]).convert('RGBA')
base = Image.open(sys.argv[2]).convert('RGBA')


def put(x, y, ch):
    im.putpixel((x, y), (0, 0, 0, 0) if ch == '.' else P[AB[ch]])


PANEL = (26, 41)  # The front panel's columns (inclusive), wide: 16 px, past both inner thighs: it hangs over the crotch.
PANEL_HEM = 46  # The panel's hem row (the thighs part at row 45, so it covers where they meet).
LEFT_FLAP = (21, 39, 25, 41)  # Back-side flap: hem from (col, row) at its flared tip to (col, row) by the panel.
RIGHT_FLAP = (42, 41, 46, 40)  # Front-side flap: hem from (col, row) by the panel to its flared tip.


def edge_l(y):
    """Leftmost skirt column in row y: the back flap flares out from the belt (col 24)."""
    return max(LEFT_FLAP[0], 24 - (y - TOP))


def edge_r(y):
    """Rightmost skirt column in row y: the front flap flares out from the belt (col 43)."""
    return min(RIGHT_FLAP[2], 43 + int((y - TOP) * 0.75))


def hem(x):
    """The hem row of column x. The front panel: one rounded edge (flat across the middle, its three
    outer columns each side stepping up a row each), never a point or a split. The side flaps: cut high, rising as they flare out
    (the swish), so the thighs show under them."""
    if PANEL[0] <= x <= PANEL[1]:
        return PANEL_HEM - max(0, 3 - min(x - PANEL[0], PANEL[1] - x))  # Rounded: the 3 outer columns each side rise a row each.
    if x < PANEL[0]:
        x0, y0, x1, y1 = LEFT_FLAP
    else:
        x0, y0, x1, y1 = RIGHT_FLAP
    return int(round(y0 + (y1 - y0) * (x - x0) / float(x1 - x0)))


def inside(x, y):
    """True for the skirt's pixels: within the flare and above (or on) the hem."""
    return TOP <= y and edge_l(y) <= x <= edge_r(y) and y <= hem(x)


def pleat(x, y):
    """True for a pleat in shadow: the panel's pleats hang straight, the flaps' fan out."""
    if PANEL[0] <= x <= PANEL[1]:
        return (x - PANEL[0]) % 3 == 1
    if x < PANEL[0]:
        p = (PANEL[0] - x) * 4.0 / max(1, PANEL[0] - edge_l(y))
    else:
        p = (x - PANEL[1]) * 4.0 / max(1, edge_r(y) - PANEL[1])
    return int(p) % 2 == 1


# The column left of the hips back to the converted pixels (shield edge, hand), rows 35-43.
for y in range(35, 44):
    im.putpixel((21, y), base.getpixel((21, y)))
# Thighs where round 5's skirt was (rows 37-44): skin, shadow side and inner edges brown_light.
for y in range(37, 45):
    put(22, y, 'r')  # Outer edge of the left thigh.
    for x in range(X0, X1 + 1):
        put(x, y, 'R' if x in (32, 35, 44) else ('r' if x in (33, 34) else 's'))
    put(45, y, 'r')  # Outer edge of the right thigh.
    if im.getpixel((46, y))[3] == 0:
        put(46, y, 'k')
# The skirt: the lit left flank, the shadow side, the pleats, the trim, the ink edges.
for y in range(TOP, PANEL_HEM + 1):
    for x in range(LEFT_FLAP[0] - 1, RIGHT_FLAP[2] + 2):
        if not inside(x, y):
            continue
        if not inside(x - 1, y) or not inside(x + 1, y):
            put(x, y, 'c')  # Outer edge (and the panel's sides below the flaps).
        elif not inside(x, y + 1):
            put(x, y, 'L' if x < CENTRE else 'B')  # The hem trim.
        elif not inside(x - 2, y):
            put(x, y, '@')  # Lit flank (light from the top-left).
        elif not inside(x + 3, y):
            put(x, y, 'A')  # The shadow side.
        else:
            put(x, y, 'A' if pleat(x, y) else 'a')
for x in range(LEFT_FLAP[0], RIGHT_FLAP[2] + 1):
    y = hem(x) + 1  # Under the hem: a shadow on the thigh, or the ink edge over the gap.
    if inside(x, y - 1) and y < im.height:
        # Ink across the 6 middle columns (where the thighs meet), so the drape's edge stays ink
        # over the gap even when the walk / idle sway it a pixel sideways.
        put(x, y, 'r' if im.getpixel((x, y))[3] and abs(x - CENTRE) > 2.5 else 'c')
im.save(sys.argv[3])
