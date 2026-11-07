"""make_art.py: the Burning Gate's obstacle sprites and icon badges (Act VI phase 2; ART_BIBLE "Act VI: the Burning
Gate"), from the pieces split_sheet.py cut out of the API sheets (raw/props_long.png, raw/icons_violet.png,
raw/icons_gold.png) and the single ember rock source (raw/props_round.png). Kurogane's recipe:
  * props through prepare_sprite.py at each size (circles: footprint x 2 + 4 wide; rects: length + 2 wide, the end-on
    `_v` length + 14 tall); sizes must match BurningGateStage.ZONES "arena" kinds;
  * badges: each symbol at 24 art px on the frame of an approved badge (violet `abyssal_pact`, gold
    `tidecallers_host`) whose inner 26 px are cleared to its face colour. Each icon sheet came back with one extra
    symbol copied from the reference badge (violet piece 1, gold piece 2): those pieces are not used.

Usage (repo root): python3 art_source/burning_gate/make_art.py <split dir>
"""
import subprocess
import sys
from PIL import Image

PROP_RAMPS = "obsidian,lava,grey,bone,brown,steel"
# kind -> (H piece or source path, V piece or None, sizes px (full length / footprint radius), shape)
PROPS = {
    "damned_cage": ("props_long_0", "props_long_2", [44.0, 56.0], "rect"),
    "gate_pillar": ("props_long_1", "props_long_3", [56.0, 72.0], "rect"),
    "ember_rock": ("@art_source/burning_gate/raw/props_round.png", None, [12.0, 16.0, 22.0], "circle"),
}
SUFFIX = {1: ["m"], 2: ["s", "l"], 3: ["s", "m", "l"]}
# icon key -> (split piece, frame badge).
BADGES = {
    "brimstone": ("icons_violet_0", "abyssal_pact"),
    "furnace_heart": ("icons_violet_2", "abyssal_pact"),
    "salt_circle": ("icons_violet_3", "abyssal_pact"),
    "rain_of_fire": ("icons_gold_0", "tidecallers_host"),
    "ach_gate_crashed": ("icons_gold_1", "tidecallers_host"),
}
ICON_RAMPS = "violet,bone,obsidian,lava,gold,charm,marble"


def src_of(d, piece):
    return piece[1:] if piece.startswith("@") else "%s/%s.png" % (d, piece)


def conv(src, key, width=0, height=0):
    im = Image.open(src)
    h = height if height > 0 else max(8, round(width * im.height / im.width))
    subprocess.run(["python3", "tools/prepare_sprite.py", src, key, "--art-height", str(h), "--no-center", "--ink-l", "0.15",
        "--ramps", PROP_RAMPS], check=True, capture_output=True)
    print(key, Image.open("assets/sprites/%s.png" % key).size)


def props(d):
    for kind, (hp, vp, sizes, shape) in PROPS.items():
        for i, s in enumerate(sizes):
            key = "obstacles/%s_%s" % (kind, SUFFIX[len(sizes)][i])
            if shape == "circle":
                conv(src_of(d, hp), key, width=int(s * 2 + 4))
            else:
                conv(src_of(d, hp), key, width=int(s + 2))
                conv(src_of(d, vp), key + "_v", height=int(s + 14))


def badges(d):
    for key, (piece, frame) in BADGES.items():
        tmp = "%s/%s_sym.png" % (d, key)
        subprocess.run(["python3", "tools/prepare_sprite.py", src_of(d, piece), "icons/" + key, "--art-height", "24",
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
