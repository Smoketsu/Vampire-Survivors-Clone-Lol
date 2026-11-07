"""make_props.py: Castle Kurogane's obstacle sprites and its command platform (Act V phase 2), from the pieces
split_sheet.py cut out of the two API prop sheets (art_source/kurogane/raw/props_long.png, props_round.png) and the
platform source (raw/command_platform.png). Each prop goes through prepare_sprite.py at each size (circles: footprint
x 2 + 4 wide; rects: length + 2 wide, the end-on `_v` length + 14 tall), the Underworld's recipe (ART_BIBLE
"Act IV: the Asphodel Underworld"). Sizes must match KuroganeStage.ZONES "arena" kinds.

Usage (repo root): python3 art_source/kurogane/make_props.py <split dir>
"""
import subprocess
import sys
from PIL import Image

RAMPS = "grey,lacquer,brown,gold,indigo,moss,marble"
# kind -> (H piece, V piece or None, sizes px (full length / footprint radius), shape)
PROPS = {
    "castle_wall": ("props_long_0", "props_long_2", [64.0, 88.0], "rect"),
    "palisade_gate": ("props_long_1", "props_long_3", [56.0, 76.0], "rect"),
    "black_pine": ("props_round_0", None, [14.0, 18.0], "circle"),
    "garden_rock": ("props_round_1", None, [12.0, 16.0], "circle"),
    "sake_barrels": ("props_round_2", None, [12.0], "circle"),
    "taiko_drum": ("props_round_3", None, [14.0], "circle"),
}
SUFFIX = {1: ["m"], 2: ["s", "l"], 3: ["s", "m", "l"]}

def conv(src, key, width=0, height=0):
    im = Image.open(src)
    h = height if height > 0 else max(8, round(width * im.height / im.width))
    subprocess.run(["python3", "tools/prepare_sprite.py", src, key, "--art-height", str(h), "--no-center", "--ink-l", "0.15",
        "--ramps", RAMPS], check=True, capture_output=True)
    out = Image.open("assets/sprites/%s.png" % key)
    print(key, out.size)

def main():
    d = sys.argv[1]
    for kind, (hp, vp, sizes, shape) in PROPS.items():
        for i, s in enumerate(sizes):
            suf = SUFFIX[len(sizes)][i]
            key = "obstacles/%s_%s" % (kind, suf)
            if shape == "circle":
                conv("%s/%s.png" % (d, hp), key, width=int(s * 2 + 4))
            else:
                conv("%s/%s.png" % (d, hp), key, width=int(s + 2))
                conv("%s/%s.png" % (d, vp), key + "_v", height=int(s + 14))
    conv("art_source/kurogane/command_platform_cut.png", "shogunate/command_platform", height=124)  # The split piece with the stray palisade cut away (x >= 680, y >= 500).

if __name__ == "__main__":
    main()
