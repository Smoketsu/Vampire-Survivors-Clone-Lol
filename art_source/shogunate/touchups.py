"""touchups.py: scripted palette-colour fixes after tools/prepare_sprite.py for the Act V shared kinds (run from the repo root).
Remaps the Covenant's holy_white / the undead's bone to Shogunate colours, joins the samurai's crest prongs into a crescent,
darkens the gunner's helmet. Usage: python3 art_source/shogunate/touchups.py"""
import json
from PIL import Image

PAL = {c["name"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) for c in json.load(open("tools/palette.json"))["colors"]}
ROOT = "assets/sprites/shogunate/"


def load(n):
    return Image.open(ROOT + n + ".png").convert("RGBA")


def remap(im, table):
    px = im.load()
    inv = {PAL[k]: PAL[v] for k, v in table.items()}
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] and p[:3] in inv:
                px[x, y] = inv[p[:3]] + (255,)


def put(im, pts, name):
    for x, y in pts:
        im.putpixel((x, y), PAL[name] + (255,))


# Ashigaru: bone / holy_white -> grey_light (the white sash and gaiters).
im = load("ashigaru"); remap(im, {"bone": "grey_light", "holy_white": "grey_light", "ink_warm": "lacquer_ink"}); im.save(ROOT + "ashigaru.png")
# Samurai: a crescent crest (join the two prongs), no holy_white.
im = load("samurai"); remap(im, {"holy_white": "grey_light", "bone": "grey_light"})
put(im, [(20, 4), (21, 4), (19, 4)], "gold_light"); put(im, [(19, 3), (20, 3), (21, 3), (22, 3)], "lacquer_ink")
im.save(ROOT + "samurai.png")
# Gunner: helmet one shade down (indigo_light -> indigo, indigo -> indigo_dark above row 18), boots' white -> grey_light.
im = load("teppo_gunner"); remap(im, {"bone": "grey_light", "holy_white": "grey_light"})
px = im.load()
for y in range(0, 14):
    for x in range(im.width):
        p = px[x, y][:3]
        if px[x, y][3] and p == PAL["indigo_light"]: px[x, y] = PAL["indigo"] + (255,)
        elif px[x, y][3] and p == PAL["indigo"]: px[x, y] = PAL["indigo_dark"] + (255,)
im.save(ROOT + "teppo_gunner.png")
# Oni: horns and fangs ivory -> sakura_light, hair stays dark.
im = load("oni"); remap(im, {"bone": "sakura_light", "holy_white": "sakura_light"}); im.save(ROOT + "oni.png")

# Onryo: the black hair (head rows) gets indigo_dark inside its ink outline (and two indigo strands) so it reads against the ink edge;
# then two empty rows on top for the hover bob (walk_cycle.py "hover"). Run once after prepare_sprite.py --art-height 34.
im = load("onryo")
if im.height == 34:
    px = im.load()
    def edge(x, y):
        return any(not (0 <= x + dx < im.width and 0 <= y + dy < im.height) or px[x + dx, y + dy][3] == 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    ink = {PAL["bronze_ink"], PAL["ink_cold"], PAL["indigo"], PAL["indigo_light"]}
    for y in range(0, 20):
        for x in range(im.width):
            if px[x, y][3] and px[x, y][:3] in ink and not edge(x, y):
                px[x, y] = PAL["indigo_dark"] + (255,)
            elif px[x, y][3] and px[x, y][:3] in (PAL["indigo"], PAL["indigo_light"]):
                px[x, y] = PAL["indigo_dark"] + (255,)
    out = Image.new("RGBA", (im.width, 36), (0, 0, 0, 0)); out.paste(im, (0, 2)); out.save(ROOT + "onryo.png")

# Stone lantern: the lit state, the window's dark pixels become warm gold (core gold_light, rim gold); the glow pool is drawn by code.
im = Image.open("assets/sprites/obstacles/stone_lantern.png").convert("RGBA"); px = im.load()
win = [(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] and px[x, y][:3] in (PAL["ink_warm"], PAL["lacquer_ink"], PAL["bronze_ink"]) and 8 < y < 26 and 6 < x < im.width - 6]
print("lantern window px:", win)
xs = [p[0] for p in win]; ys = [p[1] for p in win]
for x, y in win:
    core = min(xs) < x < max(xs) and min(ys) < y < max(ys) if len(xs) > 4 else True
    px[x, y] = PAL["gold_light" if core else "gold"] + (255,)
im.save("assets/sprites/obstacles/stone_lantern_lit.png")
