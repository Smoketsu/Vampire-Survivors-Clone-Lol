#!/usr/bin/env python3
"""Give an evolution icon the shared gold evolution frame (UI rule: gold = evolution).

Every evolution icon in assets/sprites/icons/ is a 32x32 dark badge with a 1 px gold
border (the one used by void_barrage.png). This tool builds that badge from the
void_barrage frame and pastes the icon's artwork inside it, shrunk with nearest
neighbour to fit the 26x26 inside area when it is larger. Usage:
    python3 tools/evo_frame.py puppet_king wraith_drone [...]
    python3 tools/evo_frame.py --check     # list evolution icons without the frame
"""
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "assets/sprites/icons"
GOLD = (224, 169, 46)
BADGE = (22, 10, 33)
OWN_FRAME = ("unwritten_word",)  # Icons drawn as a full badge with their own brown frame (cropped inside).
INSIDE = 26  # Px of the area inside the frame the artwork may use.


def frame_mask() -> list:
    ref = Image.open(ICONS / "void_barrage.png").convert("RGBA")
    return [(x, y) for x in range(32) for y in range(32) if ref.getpixel((x, y))[:3] == GOLD]


def evolution_icons() -> list:
    ids = []
    for f in ("scripts/data/evolution_data.gd", "scripts/data/summon_evolution_data.gd"):
        t = (ROOT / f).read_text()
        m = re.search(r"const ORDER\s*:?=\s*\[(.*?)\]\n", t, re.S)
        ids += re.findall(r'"(\w+)"', re.sub(r"#.*", "", m.group(1)))
    return ids


def has_frame(name: str, mask: list) -> bool:
    im = Image.open(ICONS / f"{name}.png").convert("RGBA")
    return all(im.getpixel(p)[:3] == GOLD for p in mask)


def apply(name: str) -> None:
    ref = Image.open(ICONS / "void_barrage.png").convert("RGBA")
    art = Image.open(ICONS / f"{name}.png").convert("RGBA")
    if name in OWN_FRAME:
        art = art.crop((7, 7, 25, 25))  # A full-bleed badge with its own (non-gold) frame: keep the inside.
    else:
        art = art.crop(art.getchannel("A").getbbox())
    s = min(1.0, INSIDE / max(art.size))
    if s < 1.0:
        art = art.resize((max(1, round(art.width * s)), max(1, round(art.height * s))), Image.NEAREST)
    out = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(32):
        for x in range(32):
            p = ref.getpixel((x, y))
            if p[3]:
                out.putpixel((x, y), GOLD + (255,) if p[:3] == GOLD else BADGE + (255,))
    out.alpha_composite(art, ((32 - art.width) // 2, (32 - art.height) // 2))
    for y in range(32):  # Re-stamp the border over any art that touched it.
        for x in range(32):
            if ref.getpixel((x, y))[:3] == GOLD:
                out.putpixel((x, y), GOLD + (255,))
    out.save(ICONS / f"{name}.png")


if __name__ == "__main__":
    mask = frame_mask()
    if sys.argv[1:] == ["--check"]:
        for i in evolution_icons():
            if not has_frame(i, mask):
                print("missing gold frame:", i)
    else:
        for n in sys.argv[1:]:
            apply(n)
