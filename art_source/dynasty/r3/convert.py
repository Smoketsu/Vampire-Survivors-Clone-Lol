#!/usr/bin/env python3
"""r3/convert.py: direct converter for the round-3 mummy (prepare_sprite's material vote erased the 1-px bandage gaps at 40 px).
Box-downscales the raw image to the art grid and maps each pixel by lightness onto the `linen` ramp (dark gap / shade / mid / light),
gold-hued pixels onto `dyn_bronze`, green eye pixels onto `papyrus`, then adds the 1-px outline and a top-left rim light.
Usage: python3 art_source/dynasty/r3/convert.py <raw png> <out png> [height=40]"""
import sys, json, colorsys
from PIL import Image, ImageFilter
import numpy as np
src, out = sys.argv[1], sys.argv[2]
H = int(sys.argv[3]) if len(sys.argv) > 3 else 40
pal = json.load(open("tools/palette.json"))
C = {c["name"]: c["hex"] for c in pal["colors"]}
def rgb(n):
    v = C[n]; v = v if isinstance(v, str) else v.get("hex", v)
    v = v.lstrip("#"); return tuple(int(v[i:i+2], 16) for i in (0, 2, 4))
INK, LD, LM, LL = (rgb(n) for n in ("dyn_ink", "dyn_linen_dark", "dyn_linen", "dyn_linen_light"))
BD, BM, BL = (rgb(n) for n in ("dyn_bronze_dark", "dyn_bronze", "dyn_bronze_light"))
PD, PM, PL = (rgb(n) for n in ("dyn_papyrus_dark", "dyn_papyrus", "dyn_papyrus_light"))
im = Image.open(src).convert("RGBA")
a = np.array(im)[:, :, 3] > 128
ys, xs = np.where(a)
im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
ch = H - 2
cw = max(1, round(im.width * ch / im.height))
# premultiplied box downscale
arr = np.array(im).astype(float); al = arr[:, :, 3:4] / 255 * (arr[:, :, 3:4] > 128)
pm = Image.fromarray((arr[:, :, :3] * al).astype(np.uint8)); am = Image.fromarray((al[:, :, 0] * 255).astype(np.uint8))
pm = np.array(pm.resize((cw, ch), Image.BOX)).astype(float); am = np.array(am.resize((cw, ch), Image.BOX)).astype(float) / 255
# local-contrast helpers: a min-filtered value (keeps the thin dark bandage gaps) and a green mask (keeps the eye points)
full = np.array(im).astype(float) / 255
fv = full[:, :, :3].max(axis=2)
fg = ((full[:, :, 1] > full[:, :, 0] * 1.05) & (full[:, :, 1] > full[:, :, 2] * 1.2) & (full[:, :, 3] > 0.5) & (full[:, :, 1] > 0.4)).astype(np.uint8) * 255
k = max(3, im.height // ch // 2 * 2 + 1)
vmin = Image.fromarray((fv * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(k)).resize((cw, ch), Image.BOX)
vmin = np.array(vmin).astype(float) / 255
gm = np.array(Image.fromarray(fg).resize((cw, ch), Image.BOX)).astype(float) / 255
W = cw + 2
grid = [[None] * W for _ in range(H)]
# eyes: the source's glowing slit is a run of green cells; keep only the two end cells as eye points, the middle is the dark wrap gap
for y in range(ch):
    xs_ = [x for x in range(cw) if gm[y, x] > 0.10 and am[y, x] >= 0.5]
    if len(xs_) >= 3:
        for x in xs_[1:-1]: gm[y, x] = 0.0
# value per cell (mean biased a little to the dark gap lines), then an adaptive threshold against the 5x5 neighbourhood: the bands are
# the local light / dark alternation, so they survive at 40 px whatever the absolute brightness of the area
V = np.zeros((ch, cw)); M = np.zeros((ch, cw), bool)
for y in range(ch):
    for x in range(cw):
        if am[y, x] >= 0.5:
            r, g, b = pm[y, x] / max(am[y, x], 1e-3) / 255
            V[y, x] = 0.8 * colorsys.rgb_to_hsv(r, g, b)[2] + 0.2 * vmin[y, x]; M[y, x] = True
for y in range(ch):
    for x in range(cw):
        if not M[y, x]: continue
        r, g, b = pm[y, x] / max(am[y, x], 1e-3) / 255
        h, s_, v = colorsys.rgb_to_hsv(r, g, b)
        y0, y1, x0, x1 = max(0, y - 2), min(ch, y + 3), max(0, x - 2), min(cw, x + 3)
        loc = V[y0:y1, x0:x1][M[y0:y1, x0:x1]].mean()
        d = V[y, x] - loc
        if gm[y, x] > 0.10: c = PL
        elif s_ > 0.55 and 0.08 < h < 0.18 and v > 0.45: c = BM if v > 0.6 else BD   # gold scrap
        elif V[y, x] < 0.17: c = INK
        elif d < -0.07 or V[y, x] < 0.38: c = LD
        elif d > 0.05 and V[y, x] > 0.55: c = LL
        else: c = LM
        grid[y + 1][x + 1] = c
for y in range(H):  # outline
    for x in range(W):
        if grid[y][x] is None and any(0 <= y+dy < H and 0 <= x+dx < W and grid[y+dy][x+dx] not in (None, "o") for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))):
            grid[y][x] = "o"
o = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for y in range(H):
    for x in range(W):
        c = grid[y][x]
        if c is not None: o.putpixel((x, y), (*(INK if c == "o" else c), 255))
bb = o.getbbox(); o = o.crop((0, bb[1], W, bb[3]))
c = Image.new("RGBA", (W, H), (0, 0, 0, 0)); c.alpha_composite(o, (0, H - o.height))
bb = c.getbbox(); c = c.crop((bb[0], 0, bb[2], H))
if c.width % 2: c2 = Image.new("RGBA", (c.width + 1, H), (0, 0, 0, 0)); c2.alpha_composite(c, (0, 0)); c = c2
c.save(out); print(out, c.size)
