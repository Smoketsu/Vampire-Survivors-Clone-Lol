"""conv.py: one generated obstacle source -> exact-size game PNG (obstacles round, upright variants).
Usage: python3 conv.py <gen png> <key> <W> <H> <ramps> [--cut a b]
  Crops the source to its opaque bounds, optionally deletes the band of rows a..b (fractions of the height; the
  long uniform middle of a shelf, so a longer source makes the shorter twins), box-resizes to exactly W x H art px,
  blows each art px up 16x (pixelate_source's contract) and runs prepare_sprite.py --inside-outline.
Writes assets/sprites/<key>.png and archives the source at art_source/<key>.png (prepare_sprite does that)."""
import subprocess, sys
import numpy as np
from PIL import Image

ROOT = __file__.rsplit("/art_source/", 1)[0]
a = sys.argv[1:]
src, key, W, H, ramps = a[0], a[1], int(a[2]), int(a[3]), a[4]
cut = (float(a[6]), float(a[7])) if len(a) > 7 and a[5] == "--cut" else None
im = np.array(Image.open(src).convert("RGBA"))
im[..., 3] = np.where(im[..., 3] >= 128, 255, 0)
img = Image.fromarray(im)
img = img.crop(img.getbbox())
if cut:
    h = img.height
    y0, y1 = int(h * cut[0]), int(h * cut[1])
    img = Image.fromarray(np.concatenate([np.array(img)[:y0], np.array(img)[y1:]], axis=0))
pm = np.array(img).astype(float)
pm[..., :3] *= pm[..., 3:4] / 255.0
small = np.array(Image.fromarray(pm.astype(np.uint8)).resize((W, H), Image.BOX)).astype(float)
al = small[..., 3:4]
small[..., :3] = np.where(al > 0, small[..., :3] * 255.0 / np.maximum(al, 1), 0)
small[..., 3:4] = np.where(al >= 128, 255, 0)
def run(fw):
    out = Image.fromarray(small.astype(np.uint8)).resize((W * 16, H * 16), Image.NEAREST)
    out = out.resize((round(fw * 16), H * 16), Image.NEAREST)  # prepare_sprite rounds the width from the aspect
    out.save(tmp)
    subprocess.run([sys.executable, f"{ROOT}/tools/prepare_sprite.py", tmp, key, "--art-height", str(H), "--inside-outline",
                    "--no-prune", "--no-levels", "--no-center", "--ramps", ramps], check=True, cwd=ROOT, capture_output=True)
    return Image.open(f"{ROOT}/assets/sprites/{key}.png")
tmp = f"/tmp/claude-0/s/conv_{key.replace('/', '_')}.png"
# prepare_sprite always writes an even width, so an odd W is made one px narrower and padded with a clear column.
r = run(W - (W % 2))
if r.width < W:
    c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    c.alpha_composite(r.convert("RGBA"), (0, 0))
    c.save(f"{ROOT}/assets/sprites/{key}.png")
    r = c
print(key, r.size, "want", (W, H))
