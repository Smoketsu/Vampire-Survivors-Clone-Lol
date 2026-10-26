#!/usr/bin/env python3
"""Relic and Grave Offering badges (Ossuary expansion steps 5 and 6a, GDD 15.0
"Relics and Grave Offerings"): procedural 32 x 32 pixel-art badges in the style of
the Ossuary's upgrade badges (assets/sprites/icons/necrotic_marrow.png): a cut-corner
plate (violet rim for relics, ember rim for offerings, iron rim for the empty
sockets), a dark fill and a motif drawn from an ASCII mask below, outlined in warm
ink one pixel around. No image generation: everything is in this file.

    python3 tools/relic_badges.py [--out assets/sprites/icons] [--sheet PATH]

Writes <out>/relic_<id>.png, offering_<id>.png, relic_slot.png and offering_slot.png
(Godot imports them on the next --import; SpriteBank treats 32 px icons as grid
badges). --sheet also writes a 4x preview sheet of every badge.
"""
import argparse
import os

from PIL import Image

# Palette: mask character -> RGB (the locked art palette, docs/art/ART_BIBLE.md).
PAL = {
    "b": (232, 225, 200), "B": (180, 170, 138), "d": (127, 120, 95),
    "g": (255, 209, 77), "G": (176, 116, 38),
    "s": (61, 204, 148), "S": (28, 107, 88), "w": (255, 250, 230), "t": (168, 255, 210),
    "r": (214, 40, 52), "R": (115, 13, 23),
    "v": (163, 92, 250), "V": (74, 37, 105),
    "e": (128, 124, 140), "E": (62, 58, 74),
    "f": (255, 140, 38), "y": (255, 220, 120),
    "o": (120, 70, 30), "O": (70, 38, 16),
    "n": (40, 30, 52),
}
INK = (28, 17, 11)  # Motif outline.
FILL = (22, 10, 33)  # Plate fill.
RIMS = {"relic": (122, 66, 173), "offering": (214, 120, 40), "socket": (88, 82, 102)}

MASKS = {
    "relic_grave_lantern": [
        "......eeee......",
        ".....e....e.....",
        ".....e....e.....",
        "....EEEEEEEE....",
        "...EeeeeeeeeE...",
        "...e.tttttt.e...",
        "...e.tsssst.e...",
        "...e.tsyyst.e...",
        "...e.tsyyst.e...",
        "...e.tsssst.e...",
        "...e.tsssst.e...",
        "...e.tttttt.e...",
        "...EeeeeeeeeE...",
        "....EEEEEEEE....",
        ".....EeeeeE.....",
    ],
    "relic_black_banner": [
        "gg..............",
        "Gg..............",
        "eVVVVVVVVVVV....",
        "eVnnnnnnnnnV....",
        "eVnnnbbbnnnV....",
        "eVnnbnbnbnnV....",
        "eVnnnbbbnnnV....",
        "eVnnnnbnnnnV....",
        "eVnnnnnnnnV.....",
        "eVnnnnnnnV......",
        "eVnnVnnnnV......",
        "eVnV.VnnV.......",
        "eV....VV........",
        "e...............",
        "e...............",
        "E...............",
    ],
    "relic_bone_abacus": [
        "bbbbbbbbbbbbbbbb",
        "bB............Bb",
        "bB.gg.ss..gg..Bb",
        "bBeeeeeeeeeeeeBb",
        "bB.gg.ss..gg..Bb",
        "bB............Bb",
        "bB..ss.gg.ss..Bb",
        "bBeeeeeeeeeeeeBb",
        "bB..ss.gg.ss..Bb",
        "bB............Bb",
        "bB.gg..ss..gg.Bb",
        "bBeeeeeeeeeeeeBb",
        "bB.gg..ss..gg.Bb",
        "bB............Bb",
        "bbbbbbbbbbbbbbbb",
    ],
    "relic_hollow_crown": [
        "g.....g.....g...",
        "gg...ggg...gg...",
        "ggg.ggrgg.ggg...",
        "gGgggg.ggggGg...",
        "gGGgg...ggGGg...",
        "gGGg.....gGGg...",
        "gGGg.....gGGg...",
        "gggggggggggggg..",
        "GsGGGGrGGGGsGG..",
        "GGGGGGGGGGGGGG..",
    ],
    "relic_mourners_bell": [
        "......GG......",
        ".....GooG.....",
        "....GgggG.....",
        "...GggyggG....",
        "...GgyggGG....",
        "..GggggggGG...",
        "..GgggggggG...",
        "..GgggggggGG..",
        ".GgggggggggG..",
        ".GggggggggGG..",
        "GGGGGGGGGGGGG.",
        "GgggggggggggG.",
        "......rr......",
        ".....rRRr.....",
        "......rr......",
    ],
    "relic_bone_flute": [
        "..............bb",
        ".............bbB",
        "............bBB.",
        "...........bnB..",
        "..........bBB...",
        ".........bnB....",
        "........bBB.....",
        ".......bnB......",
        "......bBB.......",
        ".....bnB........",
        "....bBB.........",
        "...bBB..........",
        "..bBB...........",
        ".bbB............",
        "bBB.............",
        "BB..............",
    ],
    "relic_martyrs_nail": [
        "..eeeeeee...",
        "..EEEEEEE...",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        ".....eE.....",
        "......E.....",
        "......E.....",
        "......r.....",
        ".....rRr....",
        ".....rRr....",
        "......r.....",
    ],
    "relic_war_drum": [
        "b..............b",
        ".b............b.",
        "..b..........b..",
        "...b........b...",
        "..bbbbbbbbbbbb..",
        ".bBBBBBBBBBBBBb.",
        ".obbbbbbbbbbbbo.",
        ".oOrOOrOOrOOrOo.",
        ".oOOrOOrOOrOOOo.",
        ".oOrOOrOOrOOrOo.",
        ".oOOrOOrOOrOOOo.",
        ".obbbbbbbbbbbbo.",
        "..oooooooooooo..",
    ],
    "relic_shade_cloak": [
        "......VVVV......",
        ".....VvvvvV.....",
        "....VvVVVVvV....",
        "....VvnnnnvV....",
        "...VvnsnnsnvV...",
        "...VvnnnnnnvV...",
        "...VvvnnnnvvV...",
        "..VvvvVnnVvvvV..",
        "..VvvvvVVvvvvV..",
        "..VvvvvvvvvvvV..",
        ".VvvVvvvvvvVvvV.",
        ".VvVVvvvvvvVVvV.",
        ".VVV.VvvvvV.VVV.",
        "V.V..V.VV.V..V.V",
    ],
    "relic_seers_eye": [
        ".....vvvvvv.....",
        "...vvVVVVVVvv...",
        "..vVbbbbbbbbVv..",
        ".vVbbbssssbbbVv.",
        "vVbbbsSSSSsbbbVv",
        "vVbbsSnnnnSsbbVv",
        "vVbbsSnwnnSsbbVv",
        "vVbbbsSSSSsbbbVv",
        ".vVbbbssssbbbVv.",
        "..vVbbbbbbbbVv..",
        "...vvVVVVVVvv...",
        ".....vvvvvv.....",
    ],
    "relic_leaden_shroud": [
        ".....eeeeee.....",
        "....eEEEEEEe....",
        "...eEeeeeeeEe...",
        "...eEeEEEEeEe...",
        "..eEeeeeeeeeEe..",
        "..eEe.e..e.eEe..",
        "..eEeeeeeeeeEe..",
        ".eEeEeeeeeeEeEe.",
        ".eEeeeEeeEeeeEe.",
        ".eEee.eeee.eeEe.",
        "eEeeeeeEEeeeeeEe",
        "eEeEeeeeeeeeEeEe",
        "EEEEEEEEEEEEEEEE",
    ],
    "relic_tallow_candle": [
        "......y.....",
        ".....yfy....",
        ".....yff....",
        "....fyyf....",
        "....fyf.....",
        ".....n......",
        "...bbbbb....",
        "...bbBbbb...",
        "...bbbbBb...",
        "...bBbbbb...",
        "...bbbbbb...",
        "...bbBbbb...",
        "...bbbbbb...",
        ".GGGGGGGGGG.",
        "..GggggggG..",
    ],
    "relic_lichs_phylactery": [
        "....gggggg....",
        "...GGGGGGGG...",
        ".....eeee.....",
        "...eettttee...",
        "..ettssssste..",
        "..etsswssstE..",
        "..etssssssse..",
        "..etsSsssSsE..",
        "..etsssSsssE..",
        "..etssssssse..",
        "..eEsssssssE..",
        "...eEEEEEEE...",
        "..GGGGGGGGGG..",
    ],
    "relic_deathlords_seal": [
        "....rrrrrrr.....",
        "..rrRRRRRRRrr...",
        ".rRRrrrrrrrRRr..",
        ".rRrrbbbbbrrRr..",
        "rRrrbbbbbbbrrRr.",
        "rRrrbnnbnnbrrRr.",
        "rRrrbnnbnnbrrRr.",
        "rRrrbbbnbbbrrRr.",
        "rRrrrbbbbbrrrRr.",
        ".rRrrbbbbbrrRr..",
        ".rRRrrrrrrrRRr..",
        "..rrRRRRRRRrr...",
        "....rrrrrrr.....",
    ],
    "relic_fallen_halo": [
        "....GGGGGGGG....",
        "..GGggggggggGG..",
        ".Gggyy....gggGG.",
        "Ggy..........gG.",
        "Gg............G.",
        "Gg.......n...gG.",
        ".GG.....n...gG..",
        "..GGgg.n..ggG...",
        "....GGGGGGG.....",
        ".........n......",
        "..........n.....",
    ],
    "offering_tithe_of_insight": [
        "......tt......",
        ".....tsst.....",
        "......tt......",
        "..............",
        "bbbbbb..bbbbbb",
        "bBBBBbbbbBBBBb",
        "bBbbbBbbBbbbBb",
        "bBBBBBbbBBBBBb",
        "bBbbbBbbBbbbBb",
        "bBBBBBbbBBBBBb",
        "bbbbbbbbbbbbbb",
        ".ooooooooooooo",
    ],
    "offering_gilded_coffer": [
        "..GGGGGGGGGGGG..",
        ".GggggggggggggG.",
        "GgggggggggggggGG",
        "GGGGGGGGGGGGGGGG",
        "GoooooogyooooooG",
        "GoooooggggoooooG",
        "GGGGGGGggGGGGGGG",
        "GoooooooooooooOG",
        "GoooooooooooooOG",
        "GoooooooooooooOG",
        "GGGGGGGGGGGGGGGG",
    ],
    "offering_borrowed_relic": [
        "...gggg.........",
        "..gGGGGg........",
        ".gG....Gg.......",
        ".gG....Gg.......",
        ".gG....Gg.......",
        "..gGGGGgggggggg.",
        "...gggg.GGGGGGGg",
        "..........gG.gG.",
        "..........gG.gG.",
        "...........G..G.",
        "..ss............",
        ".s..s...s.......",
        "s....s.s.s......",
        "......s...s..ss.",
    ],
    "offering_blood_vigil": [
        "......r.......",
        ".....rr.......",
        "....rrRr......",
        "....rrRr......",
        "...rrrRRr.....",
        "...rwrRRr.....",
        "...rrrRRr.....",
        "....rRRr......",
        ".....rr.......",
        "..............",
        ".GGGGGGGGGGG..",
        "..GgggggggG...",
        "...GgggggG....",
        ".....GGG......",
        ".....GgG......",
        "...GGGGGGG....",
    ],
    "offering_second_breath": [
        "..........tt....",
        "........tss.t...",
        ".......ts....t..",
        "....bbbbbb.ts...",
        "...bbbbbbbbt....",
        "..bbbbbbbbbb....",
        "..bnnbbbnnbb....",
        "..bnnbbbnnbb....",
        "..bbbbnbbbbb....",
        "...bbbbbbbb.....",
        "....bnbnbb......",
        "....bbbbbb......",
    ],
    "offering_war_horn": [
        "bb..............",
        "bBb.............",
        ".bBb............",
        ".bBBb...........",
        "..bBBbb.........",
        "..bBBBbbb.......",
        "...bBBBBbbb.....",
        "...gGgBBBBbbbb..",
        "....gGgBBBBBBbbb",
        ".....gGgBBBBBBBb",
        "......bbbBBBBBbo",
        "........bbbbbbbo",
        "...............o",
    ],
    "relic_slot": [
        "....EEEEEE....",
        "..EE......EE..",
        ".E..........E.",
        ".E..........E.",
        "E............E",
        "E............E",
        "E............E",
        "E............E",
        "E............E",
        ".E..........E.",
        ".E..........E.",
        "..EE......EE..",
        "....EEEEEE....",
    ],
    "offering_slot": [
        "..............",
        "..............",
        "..............",
        "......ff......",
        ".....f..f.....",
        "......ff......",
        "..............",
        "EEEEEEEEEEEEEE",
        ".E..........E.",
        "..E........E..",
        "...EEEEEEEE...",
    ],
}


def plate(rim):
    """The 32 x 32 cut-corner plate (rim + fill), as in the Ossuary badges."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = img.load()
    spans = {0: (5, 26), 1: (2, 29), 2: (1, 30), 3: (1, 30)}  # Row -> first..last col of the plate.
    for y in range(32):
        yy = y if y < 16 else 31 - y
        a, b = spans.get(yy, (0, 31))
        for x in range(a, b + 1):
            edge = x in (a, b) or yy == 0 or (yy == 1 and (x <= 4 or x >= 27))
            px[x, y] = (rim if edge else FILL) + (255,)
    return img


def motif(rows):
    """The mask as an image with a one-pixel ink outline (transparent elsewhere)."""
    w = max(len(r) for r in rows)
    h = len(rows)
    img = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    px = img.load()
    solid = set()
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c != "." and c in PAL:
                px[x + 1, y + 1] = PAL[c] + (255,)
                solid.add((x + 1, y + 1))
    for (x, y) in list(solid):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in solid and 0 <= q[0] < w + 2 and 0 <= q[1] < h + 2:
                px[q[0], q[1]] = INK + (255,)
    return img


def badge(key):
    family = "socket" if key in ("relic_slot", "offering_slot") else ("offering" if key.startswith("offering_") else "relic")
    img = plate(RIMS[family])
    m = motif(MASKS[key])
    ox = (32 - m.width) // 2
    oy = (32 - m.height) // 2
    img.alpha_composite(m, (ox, oy))
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/sprites/icons")
    ap.add_argument("--sheet", default="")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    keys = list(MASKS)
    for k in keys:
        badge(k).save(os.path.join(a.out, k + ".png"))
    print("wrote %d badges to %s" % (len(keys), a.out))
    if a.sheet:
        cols = 8
        rows = (len(keys) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * 34 * 4, rows * 34 * 4), (40, 36, 48, 255))
        for i, k in enumerate(keys):
            b = badge(k).resize((128, 128), Image.NEAREST)
            sheet.alpha_composite(b, ((i % cols) * 136 + 4, (i // cols) * 136 + 4))
        sheet.save(a.sheet)
        print("sheet", a.sheet)


if __name__ == "__main__":
    main()
