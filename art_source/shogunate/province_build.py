"""province_build.py: rebuilds the Burning Province's obstacles and icons from their API sources
(Act V phase 2; docs/art/ART_BIBLE.md "Act V: the Burning Province"). Run from the repo root.
The units, bosses and characters are converted by the prepare_sprite.py lines in province_build.sh.
  * Obstacles: one source per kind; the rect kinds hold an H + V pair (split at the widest
    transparent gap). Each size is converted to its footprint width (prepare_sprite.py --no-center,
    --art-height from the part's aspect); a V sprite is the short side wide.
  * Icons: the 26 px symbol (prepare_sprite.py --art-height 26 --no-outline-less) pasted on a
    cut-corner badge cleared from an approved icon (violet border; gold for the evolution and the
    achievement)."""
import subprocess, sys, os
from PIL import Image
import numpy as np

TMP = os.environ.get("PROVINCE_TMP", "/tmp/province_build")
os.makedirs(TMP, exist_ok=True)

# kind -> (ramps, circle widths by size suffix) or (ramps, rect: H widths by suffix, V width, V height factor)
CIRCLES = {
    "rice_sheaves": ("gold,brown,grey", {"s": 26, "l": 34}),
    "bamboo_stand": ("moss,brown,gold", {"s": 26, "m": 34, "l": 42}),
}
RECTS = {
    "burning_house": ("gold,brown,flame,grey,lacquer", {"s": 56, "l": 72}, 40),
    "shrine_hall": ("lacquer,grey,gold,steel,bone", {"s": 52, "l": 64}, 40),
}


def crop_alpha(im):
    a = np.array(im)[:, :, 3] > 200
    ys, xs = np.where(a)
    return im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def split_pair(path):
    """The H (left) and V (right) copies of a pair source, split at the widest empty column gap."""
    im = Image.open(path).convert("RGBA")
    a = np.array(im)[:, :, 3] > 200
    cols = a.any(axis=0)
    best, run, start, gap = 0, 0, 0, (0, 0)
    xs = np.where(cols)[0]
    for x in range(xs.min(), xs.max()):
        if not cols[x]:
            run += 1
            if run == 1:
                start = x
            if run > best:
                best, gap = run, (start, x)
        else:
            run = 0
    mid = (gap[0] + gap[1]) // 2
    return crop_alpha(im.crop((0, 0, mid, im.height))), crop_alpha(im.crop((mid, 0, im.width, im.height)))


def convert(img, key, width, ramps):
    tmp = os.path.join(TMP, key.replace("/", "_") + "_src.png")
    img.save(tmp)
    h = max(8, round(width * img.height / img.width))
    subprocess.run([sys.executable, "tools/prepare_sprite.py", tmp, key, "--art-height", str(h), "--no-center",
                    "--ramps", ramps, "--ink-l", "0.18"], check=True, stdout=subprocess.DEVNULL)


def obstacles():
    for kind, (ramps, sizes) in CIRCLES.items():
        src = crop_alpha(Image.open("art_source/obstacles/%s.png" % kind).convert("RGBA"))
        for suf, w in sizes.items():
            convert(src, "obstacles/%s_%s" % (kind, suf), w, ramps)
    for kind, (ramps, sizes, short) in RECTS.items():
        h_img, v_img = split_pair("art_source/obstacles/%s.png" % kind)
        for suf, w in sizes.items():
            convert(h_img, "obstacles/%s_%s" % (kind, suf), w, ramps)
            convert(v_img, "obstacles/%s_%s_v" % (kind, suf), short, ramps)


ICONS = {  # icon -> (badge it is cleared from, ramps of the symbol)
    "hundred_shadows": ("paris_arrow", "violet,bone"),
    "hidden_hand": ("paris_arrow", "violet,bone"),
    "paper_lanterns": ("paris_arrow", "gold,lacquer"),
    "thousand_shadows": ("arrow_of_fate", "violet,bone,gold"),
    "ach_no_shadow_unlit": ("ach_heel_found", "grey,gold,indigo"),
}
FILL = (22, 10, 33, 255)  # The badge's inner fill.


def icons():
    for name, (badge, ramps) in ICONS.items():
        tmp = os.path.join(TMP, "icon_%s.png" % name)
        src = crop_alpha(Image.open("art_source/icons/%s.png" % name).convert("RGBA"))
        src.save(os.path.join(TMP, "icon_%s_src.png" % name))
        subprocess.run([sys.executable, "tools/prepare_sprite.py", os.path.join(TMP, "icon_%s_src.png" % name), "icons/" + name,
                        "--art-height", "26", "--ramps", ramps, "--no-center", "--out", tmp], check=True, stdout=subprocess.DEVNULL)
        b = Image.open("assets/sprites/icons/%s.png" % badge).convert("RGBA")
        px = b.load()
        border = px[2, 1]  # The badge's border colour.
        for y in range(b.height):
            for x in range(b.width):
                if px[x, y][3] > 0 and px[x, y] != border:
                    px[x, y] = FILL
        sym = Image.open(tmp).convert("RGBA")
        if sym.width > 26:
            sym = sym.resize((26, round(26 * sym.height / sym.width)), Image.NEAREST)
        b.alpha_composite(sym, ((32 - sym.width) // 2, (32 - sym.height) // 2))
        b.save("assets/sprites/icons/%s.png" % name)


if __name__ == "__main__":
    what = sys.argv[1:] or ["obstacles", "icons"]
    if "obstacles" in what:
        obstacles()
    if "icons" in what:
        icons()
