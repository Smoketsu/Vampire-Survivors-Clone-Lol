"""mkref.py: enlarge a pixel sprite (nearest) onto a square transparent canvas, the reference image for gen_image.py.
Usage: python3 mkref.py <sprite png> <out png> [canvas px, default 1024]"""
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGBA")
n = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
s = max(1, (n - 40) // max(im.size))
im = im.resize((im.width * s, im.height * s), Image.NEAREST)
c = Image.new("RGBA", (n, n), (0, 0, 0, 0))
c.alpha_composite(im, ((n - im.width) // 2, (n - im.height) // 2))
c.save(sys.argv[2])
