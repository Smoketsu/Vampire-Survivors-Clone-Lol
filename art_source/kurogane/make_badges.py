"""make_badges.py: Castle Kurogane's icon badges (Act V phase 2). Each symbol split from the two API sheets
(art_source/kurogane/raw/icons_violet.png, icons_gold.png, by split_sheet.py) is converted to 24 art px by
prepare_sprite.py and set on the frame of an approved badge (violet: icons/abyssal_pact; gold: icons/tidecallers_host)
whose inner 26 px are cleared to its face colour, the Underworld's recipe (ART_BIBLE "Act IV: the Asphodel Underworld").

Usage (repo root): python3 art_source/kurogane/make_badges.py <split dir>
"""
import subprocess
import sys
from PIL import Image

# icon key -> (split piece, frame badge).
BADGES = {
    "banner_of_the_dead": ("icons_violet_0", "abyssal_pact"),
    "warlord_seal": ("icons_violet_1", "abyssal_pact"),
    "unbending": ("icons_violet_2", "abyssal_pact"),
    "hundred_banners": ("icons_gold_0", "tidecallers_host"),
    "ach_regiments_broken": ("icons_gold_1", "tidecallers_host"),
}
RAMPS = "violet,bone,lacquer,gold,grey,indigo"

def main():
    d = sys.argv[1]
    for key, (piece, frame) in BADGES.items():
        tmp = "%s/%s_sym.png" % (d, key)
        subprocess.run(["python3", "tools/prepare_sprite.py", "%s/%s.png" % (d, piece), "icons/" + key, "--art-height", "24",
            "--no-center", "--no-prune", "--ink-l", "0.12", "--ramps", RAMPS, "--out", tmp], check=True, capture_output=True)
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
    main()
