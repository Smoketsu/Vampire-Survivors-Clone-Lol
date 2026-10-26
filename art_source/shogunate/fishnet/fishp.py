"""fishp.py (round 2): fishnet painted ONLY inside hand-set leg polygons of the API still (never over the skirt).
The round 1 fish.py took every textured area below the hip, which on a pale skirt also netted the cloth.
usage: fishp.py <src hi-res png> <sprite key> <skin hex> <line hex> "x,y x,y ..." ["x,y ..."] ...
Polygons are in the src image's pixel coordinates; the sprite is aligned to the still's opaque bounds the same
way fish.py does. Teal (the scarf / wisp glow) and the outline inks are left alone."""
import sys, numpy as np
from PIL import Image, ImageDraw
from netmask import netmask
src, key, skin, line = sys.argv[1:5]
polys = [[tuple(map(int, p.split(','))) for p in s.split()] for s in sys.argv[5:]]
root = 'assets/sprites/'
spr = Image.open(root + key + '.png').convert('RGBA'); sa = np.array(spr); W, H = spr.size
_, alpha = netmask(src, 0)
ys, xs = np.where(alpha); x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
sc = (H - 2) / (y1 - y0); cw = max(1, round((x1 - x0) * sc)); ch = H - 2
pm = Image.new('L', alpha.shape[::-1], 0); d = ImageDraw.Draw(pm)
for p in polys: d.polygon(p, fill=255)
pm = np.array(pm)
def small(arr):
    return np.array(Image.fromarray(arr[y0:y1, x0:x1].astype(np.uint8)).resize((cw, ch), Image.BOX)) / 255.
sm = small(pm); sal = small(alpha.astype(np.uint8) * 255) > 0.5
body = sa[..., 3] > 0
best = None
for dx in range(0, W - cw + 1):
    for dy in (0, 1, 2):
        sub = np.zeros((H, W), bool); sub[dy:dy + ch, dx:dx + cw] = sal[:min(ch, H - dy)]
        s2 = (sub & body).sum() / (sub | body).sum()
        if best is None or s2 > best[0]: best = (s2, dx, dy)
print('align', best); _, dx, dy = best
full = np.zeros((H, W)); full[dy:dy + ch, dx:dx + cw] = sm[:min(ch, H - dy)]
h = lambda s: tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))
S, L = h(skin), h(line); n = 0
for y in range(H):
    for x in range(W):
        r, g, b, a = (int(v) for v in sa[y, x])
        if a and full[y, x] > 0.5 and not (g > r + 25 and g > b - 10) and max(r, g, b) > 0x55:
            sa[y, x, :3] = L if ((x + y) % 4 == 0 or (x - y) % 4 == 0) else S; n += 1
print('painted', n)
Image.fromarray(sa).save(root + key + '.png')
