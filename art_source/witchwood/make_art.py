"""make_art.py: the Witchwood's obstacle sprites, hex stones and icon badges (Act VII phase 2; ART_BIBLE "Act VII: the
Witchwood"), from the pieces split_sheet.py cut out of the API sheets (raw/props_round.png, raw/props_long.png,
raw/icons_violet.png, raw/icons_gold.png). The Burning Gate's recipe:
  * props through prepare_sprite.py at each size (circles: footprint x 2 + 4 wide; rects: length + 2 wide, the end-on
    `_v` length + 14 tall); sizes must match WitchwoodStage.ZONES "arena" kinds;
  * the hex stone and its broken stump as structures at their SpriteData heights;
  * badges: each symbol at 24 art px on the frame of an approved badge (violet `abyssal_pact`, gold
    `tidecallers_host`) whose inner 26 px are cleared to its face colour. Each icon sheet came back with one extra
    symbol copied from the reference badge (violet piece 3, gold piece 2): those pieces are not used.

Usage (repo root): python3 art_source/witchwood/make_art.py <split dir>
"""
import subprocess
import sys
from PIL import Image

PROP_RAMPS = "brown,moss,grey,blood,velvet,bone,obsidian"
# kind -> (H piece, V piece or None, sizes px (full length / footprint radius), shape)
PROPS = {
    "fen_snag": ("props_round_0", None, [12.0, 16.0, 20.0], "circle"),
    "standing_stone": ("props_round_1", None, [12.0, 16.0, 22.0], "circle"),
    "witch_cauldron": ("props_round_3", None, [12.0, 16.0, 22.0], "circle"),
    "charm_fence": ("props_long_0", "props_long_1", [44.0, 56.0], "rect"),
}
# Most art height of a circle prop, x its footprint radius (the stones and snags are tall: at full width they stood
# twice the necromancer's height).
TALL_CAP = 2.8
SUFFIX = {1: ["m"], 2: ["s", "l"], 3: ["s", "m", "l"]}
# structure key -> (piece, art height)
STRUCTURES = {
    "structures/hex_stone": ("props_round_2", 44),
    "structures/hex_stone_broken": ("props_round_4", 28),
}
# icon key -> (split piece, frame badge).
BADGES = {
    "witch_circle": ("icons_violet_0", "abyssal_pact"),
    "moonlit_rite": ("icons_violet_1", "abyssal_pact"),
    "embalmed": ("icons_violet_2", "abyssal_pact"),
    "witches_sabbath": ("icons_gold_0", "tidecallers_host"),
    "ach_the_coven_breaks": ("icons_gold_1", "tidecallers_host"),
}
ICON_RAMPS = "blood,velvet,moonlight,gold,bone,violet"


def conv(src, key, width=0, height=0, extra=()):
    im = Image.open(src)
    h = height if height > 0 else max(8, round(width * im.height / im.width))
    subprocess.run(["python3", "tools/prepare_sprite.py", src, key, "--art-height", str(h), "--no-center", "--ink-l", "0.15",
        "--ramps", PROP_RAMPS, *extra], check=True, capture_output=True)
    print(key, Image.open("assets/sprites/%s.png" % key).size)


def props(d):
    for kind, (hp, vp, sizes, shape) in PROPS.items():
        for i, s in enumerate(sizes):
            key = "obstacles/%s_%s" % (kind, SUFFIX[len(sizes)][i])
            if shape == "circle":
                src = "%s/%s.png" % (d, hp)
                im = Image.open(src)
                h = round((s * 2 + 4) * im.height / im.width)
                if h > s * TALL_CAP:
                    conv(src, key, height=int(s * TALL_CAP))  # A tall prop (a snag, a stone) is capped, not drawn giant.
                else:
                    conv(src, key, width=int(s * 2 + 4))
            else:
                conv("%s/%s.png" % (d, hp), key, width=int(s + 2))
                conv("%s/%s.png" % (d, vp), key + "_v", height=int(s + 14))
    for key, (piece, h) in STRUCTURES.items():
        conv("%s/%s.png" % (d, piece), key, height=h)


def badges(d):
    for key, (piece, frame) in BADGES.items():
        tmp = "%s/%s_sym.png" % (d, key)
        subprocess.run(["python3", "tools/prepare_sprite.py", "%s/%s.png" % (d, piece), "icons/" + key, "--art-height", "24",
            "--no-center", "--no-prune", "--ink-l", "0.12", "--ramps", ICON_RAMPS, "--out", tmp], check=True, capture_output=True)
        base = Image.open("assets/sprites/icons/%s.png" % frame).convert("RGBA")
        fill = base.getpixel((4, 4))
        for y in range(3, 29):
            for x in range(3, 29):
                base.putpixel((x, y), fill)
        sym = Image.open(tmp).convert("RGBA")
        if sym.width > 26:
            sym = sym.resize((26, max(1, round(sym.height * 26 / sym.width))), Image.NEAREST)
        base.alpha_composite(sym, ((32 - sym.width) // 2, (32 - sym.height) // 2))
        base.save("assets/sprites/icons/%s.png" % key)
        print(key, sym.size)


if __name__ == "__main__":
    props(sys.argv[1])
    badges(sys.argv[1])
