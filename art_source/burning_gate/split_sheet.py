"""split_sheet.py: cut a generated prop / icon sheet into its separate pieces (copied from art_source/kurogane for the Burning Gate, Act VI phase 2).

Usage: python3 art_source/kurogane/split_sheet.py <sheet.png> <out prefix> [--gap N]
Finds the opaque pieces (alpha >= 128) by connected components after a dilation of `gap` px (so a prop's
loose bits stay with it), writes each one's crop (with its own alpha) as <out prefix>_<i>.png, left to right,
top to bottom (rows by the piece's top edge in 1/3-image bands), and prints each piece's box.
"""
import sys
from PIL import Image, ImageFilter

def main():
    src, prefix = sys.argv[1], sys.argv[2]
    gap = int(sys.argv[sys.argv.index("--gap") + 1]) if "--gap" in sys.argv else 12
    im = Image.open(src).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    d = a.filter(ImageFilter.MaxFilter(gap * 2 + 1))
    w, h = d.size
    px = d.load()
    seen = set()
    boxes = []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if px[x, y] and (x, y) not in seen:
                stack = [(x, y)]
                seen.add((x, y))
                x0, y0, x1, y1 = x, y, x, y
                while stack:
                    cx, cy = stack.pop()
                    x0, y0, x1, y1 = min(x0, cx), min(y0, cy), max(x1, cx), max(y1, cy)
                    for nx, ny in ((cx + 2, cy), (cx - 2, cy), (cx, cy + 2), (cx, cy - 2)):
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny]:
                            seen.add((nx, ny))
                            stack.append((nx, ny))
                boxes.append((max(0, x0 - 2), max(0, y0 - 2), min(w, x1 + 3), min(h, y1 + 3)))
    boxes = [b for b in boxes if (b[2] - b[0]) * (b[3] - b[1]) > 900]
    boxes.sort(key=lambda b: (b[1] * 3 // h, b[0]))
    for i, b in enumerate(boxes):
        crop = im.crop(b)
        bb = crop.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
        crop = crop.crop(bb)
        crop.save("%s_%d.png" % (prefix, i))
        print(i, b, crop.size)

if __name__ == "__main__":
    main()
