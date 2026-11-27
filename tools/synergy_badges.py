#!/usr/bin/env python3
"""synergy_badges.py: draws the pixel-art synergy badges of the later classes'
synergies (GDD §15.0 "Synergies for the later classes (owner decisions, Nov
2026)") procedurally, in the style of the earlier `icons/syn_*.png` badges:
the violet cut-corner badge (border and fill copied from icons/syn_requiem.png),
one 26 art px symbol inside, drawn in the art bible's palette (bone, flesh,
stone, ice, soul-teal) with a dark 1 px outline. Each pair shows its setter's
material meeting its finisher's, like the earlier badges.

usage: python3 tools/synergy_badges.py [ids...]   (default: all of them)
Writes assets/sprites/icons/syn_<id>.png (32 x 32 RGBA).
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent  # Repository root.
ICONS = ROOT / "assets/sprites/icons"  # Badge folder.
TEMPLATE = ICONS / "syn_requiem.png"  # Badge whose border and fill are reused.
BORDER = (122, 66, 173, 255)  # Violet badge border (template colour).
FILL = (22, 10, 33, 255)  # Badge inner fill (template colour).
OUTLINE = (28, 17, 11, 255)  # Symbol outline.
# Palette (sampled from the earlier synergy badges).
BONE_HI, BONE, BONE_LO = (232, 225, 200, 255), (180, 170, 138, 255), (127, 120, 95, 255)
FLESH, FLESH_LO = (118, 152, 74, 255), (59, 85, 41, 255)
STONE_HI, STONE, STONE_LO = (167, 179, 198, 255), (107, 122, 148, 255), (59, 67, 82, 255)
ICE_HI, ICE = (228, 250, 255, 255), (166, 217, 234, 255)
TEAL_HI, TEAL, TEAL_LO = (168, 255, 210, 255), (61, 204, 148, 255), (28, 107, 88, 255)
IRON_HI, IRON = (156, 151, 140, 255), (92, 88, 82, 255)
BLOOD_HI, BLOOD, BLOOD_LO = (240, 96, 92, 255), (190, 38, 48, 255), (110, 18, 30, 255)
FIRE_HI, FIRE = (255, 214, 110, 255), (232, 128, 40, 255)
VIOLET_HI = (190, 140, 240, 255)
BRONZE_HI, BRONZE = (230, 180, 100, 255), (168, 112, 52, 255)


def symbol_pinned_down(d):
    # An iron shell over a bone arrow pinning a soul-teal mark.
    d.ellipse([9, 18, 22, 24], fill=TEAL_LO)
    d.ellipse([11, 19, 20, 23], fill=TEAL)
    d.line([7, 7, 16, 21], fill=BONE, width=2)
    d.polygon([(15, 18), (19, 23), (14, 23)], fill=BONE_HI)
    d.polygon([(6, 5), (9, 6), (7, 9)], fill=BONE_LO)
    d.ellipse([18, 5, 25, 10], fill=IRON)
    d.ellipse([19, 6, 22, 8], fill=IRON_HI)


def symbol_anchor_and_stone(d):
    # A deep-sea tentacle coiled round a falling bone boulder.
    d.ellipse([12, 6, 24, 18], fill=BONE)
    d.ellipse([14, 8, 19, 12], fill=BONE_HI)
    d.ellipse([18, 13, 23, 17], fill=BONE_LO)
    d.arc([5, 10, 21, 27], 100, 330, fill=TEAL_LO, width=3)
    d.arc([6, 11, 20, 26], 110, 320, fill=TEAL, width=1)
    d.ellipse([5, 22, 8, 25], fill=TEAL)


def symbol_broken_guard(d):
    # An iron oni club striking a cracked bone shield.
    d.ellipse([5, 9, 19, 25], fill=BONE)
    d.ellipse([7, 11, 13, 17], fill=BONE_HI)
    d.line([12, 9, 10, 15, 14, 19, 11, 25], fill=OUTLINE, width=1)
    d.line([24, 5, 16, 15], fill=IRON, width=4)
    for x, y in ((22, 6), (20, 9), (18, 12)):
        d.point((x, y), fill=IRON_HI)
    d.line([16, 15, 13, 19], fill=BLOOD_LO, width=2)


def symbol_searchlight(d):
    # A stone wing above a soul-teal beam from a hovering saucer.
    d.polygon([(4, 5), (14, 10), (8, 12)], fill=STONE)
    d.polygon([(5, 6), (11, 9), (8, 10)], fill=STONE_HI)
    d.polygon([(17, 12), (22, 12), (25, 25), (13, 25)], fill=TEAL_LO)
    d.polygon([(18, 13), (21, 13), (23, 25), (15, 25)], fill=TEAL)
    d.ellipse([13, 8, 26, 13], fill=BONE)
    d.ellipse([16, 6, 23, 10], fill=BONE_HI)


def symbol_carrion_swarm(d):
    # A flesh shockwave under three diving bone darts.
    d.arc([4, 17, 27, 31], 180, 360, fill=FLESH_LO, width=3)
    d.arc([5, 18, 26, 30], 190, 350, fill=FLESH, width=1)
    for x, y in ((8, 6), (15, 4), (21, 8)):
        d.line([x, y, x + 3, y + 8], fill=BONE, width=2)
        d.polygon([(x + 2, y + 8), (x + 5, y + 8), (x + 4, y + 11)], fill=BONE_HI)


def symbol_fallen_choir(d):
    # A pale wail ripple round a fallen seraph's feather blade.
    d.arc([3, 5, 17, 27], 110, 250, fill=ICE, width=2)
    d.arc([6, 9, 15, 23], 120, 240, fill=ICE_HI, width=1)
    d.polygon([(23, 4), (26, 7), (15, 26), (13, 24)], fill=BONE)
    d.polygon([(23, 5), (25, 7), (17, 20)], fill=BONE_HI)
    d.line([13, 24, 11, 27], fill=VIOLET_HI, width=2)


def symbol_black_ice(d):
    # A powder keg bursting through an ice crystal.
    d.polygon([(10, 4), (17, 13), (10, 22), (3, 13)], fill=ICE)
    d.polygon([(10, 6), (14, 13), (10, 13)], fill=ICE_HI)
    d.rectangle([15, 15, 25, 26], fill=BONE_LO)
    d.line([15, 18, 25, 18], fill=IRON, width=1)
    d.line([15, 23, 25, 23], fill=IRON, width=1)
    for p in ((20, 9), (25, 11), (16, 11)):
        d.line([20, 15, p[0], p[1]], fill=FIRE, width=2)
    d.ellipse([18, 11, 22, 15], fill=FIRE_HI)


def symbol_blood_in_the_water(d):
    # A blood drop falling into soul-teal water, bone fangs below.
    d.polygon([(16, 3), (21, 11), (16, 15), (11, 11)], fill=BLOOD)
    d.ellipse([11, 8, 21, 16], fill=BLOOD)
    d.ellipse([13, 9, 16, 12], fill=BLOOD_HI)
    d.arc([3, 15, 15, 23], 200, 340, fill=TEAL, width=2)
    d.arc([16, 15, 28, 23], 200, 340, fill=TEAL, width=2)
    d.polygon([(9, 21), (12, 21), (10, 27)], fill=BONE_HI)
    d.polygon([(19, 21), (22, 21), (21, 27)], fill=BONE_HI)


def symbol_aegis_of_tartarus(d):
    # A round bronze hoplite shield behind a soul-teal barrier arc.
    d.ellipse([7, 8, 24, 25], fill=BRONZE)
    d.ellipse([9, 10, 16, 16], fill=BRONZE_HI)
    d.ellipse([13, 14, 18, 19], fill=BONE)
    d.arc([3, 3, 28, 30], 190, 350, fill=TEAL, width=2)
    d.arc([4, 4, 27, 29], 200, 340, fill=TEAL_HI, width=1)


def symbol_unhallowed_legion(d):
    # A bone war banner with a skull over a teal flame (the front line).
    d.line([8, 4, 8, 27], fill=BONE_LO, width=2)
    d.polygon([(9, 5), (25, 5), (22, 11), (25, 17), (9, 17)], fill=TEAL_LO)
    d.polygon([(10, 6), (22, 6), (20, 10), (10, 10)], fill=TEAL)
    d.ellipse([13, 8, 20, 15], fill=BONE)
    d.point((15, 11), fill=OUTLINE)
    d.point((18, 11), fill=OUTLINE)
    d.rectangle([14, 15, 19, 17], fill=BONE)
    d.polygon([(12, 27), (16, 19), (20, 27)], fill=TEAL)


def symbol_rain_of_ruin(d):
    # Bone darts and an iron shell raining from a soul-teal cloud (the ranged ones).
    d.ellipse([4, 3, 16, 11], fill=TEAL_LO)
    d.ellipse([12, 2, 27, 11], fill=TEAL_LO)
    d.ellipse([8, 4, 20, 9], fill=TEAL)
    for x, y in ((7, 14), (14, 17), (21, 13)):
        d.line([x, y, x - 1, y + 7], fill=BONE, width=2)
        d.point((x - 1, y + 8), fill=BONE_HI)
    d.ellipse([17, 22, 22, 27], fill=IRON)
    d.point((18, 23), fill=IRON_HI)


SYMBOLS = {name[len("symbol_"):]: fn for name, fn in globals().items() if name.startswith("symbol_")}


def badge(draw_fn):
    """The badge with one symbol: template border and fill, symbol, outline."""
    tpl = Image.open(TEMPLATE).convert("RGBA")
    out = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(32):
        for x in range(32):
            p = tpl.getpixel((x, y))
            if p[3] == 0:
                continue
            out.putpixel((x, y), BORDER if p == BORDER else FILL)
    sym = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(sym))
    # 1 px dark outline round the symbol, inside the badge's 3 px inset.
    for y in range(2, 30):
        for x in range(2, 30):
            if sym.getpixel((x, y))[3] or out.getpixel((x, y)) != FILL:
                continue
            if any(sym.getpixel((x + dx, y + dy))[3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out.putpixel((x, y), OUTLINE)
    for y in range(32):
        for x in range(32):
            p = sym.getpixel((x, y))
            if p[3] and out.getpixel((x, y)) != BORDER and out.getpixel((x, y))[3]:
                out.putpixel((x, y), p)
    return out


def main():
    ids = sys.argv[1:] or sorted(SYMBOLS)
    for i in ids:
        badge(SYMBOLS[i]).save(ICONS / ("syn_%s.png" % i))
        print("wrote icons/syn_%s.png" % i)


if __name__ == "__main__":
    main()
