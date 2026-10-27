"""fishk.py (round 2): Kage's fishnet. Her legs hold two skin shades (8c6040 shadow, e0a882 light) with the
bodysuit breaking the area up, so the round 1 pass (shadow shade only) left light blocks and a ragged lattice.
This one nets EVERY skin pixel of both shades on the legs (rows >= minrow, cols >= mincol: the far hand stays plain),
with the same period-4 diamond lattice as the Kunoichi's (fishc.py).
usage: fishk.py key minrow mincol fillhex linehex   (run on a fresh prepare_sprite.py conversion)"""
import sys, numpy as np
from PIL import Image
key, minrow, mincol, fill, line = sys.argv[1:6]
root = 'assets/sprites/'
a = np.array(Image.open(root + key + '.png').convert('RGBA'))
h = lambda s: tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))
skins = {h('8c6040'), h('e0a882')}
n = 0
for y in range(int(minrow), a.shape[0]):
    for x in range(int(mincol), a.shape[1]):
        if a[y, x, 3] and tuple(a[y, x, :3]) in skins:
            a[y, x, :3] = h(line) if ((x + y) % 4 == 0 or (x - y) % 4 == 0) else h(fill); n += 1
print(key, n)
Image.fromarray(a).save(root + key + '.png')
