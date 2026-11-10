#!/usr/bin/env python3
"""gen_sheets.py: the Turning Year's icon sheets and the obstacle sheet (one API image each, symbols in a row on transparent alpha).
Usage (repo root): python3 art_source/year/gen_sheets.py [sheet ...]   (no names = every missing sheet). Sheets land in
art_source/year/sheet_<name>.png; make_props.py cuts them apart (the symbols' order here is the order it reads)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
ICON_HEAD = ("A sheet of {n} separate pixel-art game ICON SYMBOLS in one row, evenly spaced with a wide empty gap between them, on a FULLY "
             "TRANSPARENT background (real alpha). Each symbol is simple, bold and centred in its part of the image, drawn as chunky "
             "low-resolution pixel art (each symbol about 24 pixels wide on a coarse grid, shown enlarged with crisp square pixels, "
             "nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left). No frame, no "
             "badge background, no text, no letters, no people.\nFrom left to right:\n")
ICON_COL = ("\nColours: moss green #274D24 #599641 #9CCB72; bark brown #553C27 #86603E #B08A60; blossom pink #9C5272 #EFA6C3 #FBD9E6; amber leaf "
            "#8A5420 #D9953C #F2C67A; frost #6F8AA4 #B9CEE0 #E4EDF5; bone #9C9078 #E7DEC9; dead grey #312E2C #57524D #86807A; wildfire orange #E35C26 only where named; "
            "ghost soul-teal #3DCC94 only where named. NO crimson, NO purple.")
ICON_TAIL = "\nAttached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame)."
OBS_HEAD = ("A sheet of 3 separate pixel-art game OBSTACLE sprites for a top-down 2D horde-survival game (three-quarter top-down view, "
            "camera above and slightly in front), laid out in one row, evenly spaced with wide empty gaps between them, on a FULLY "
            "TRANSPARENT background (real alpha). An enchanted forest. LOW-RESOLUTION pixel art, chunky simple shapes, crisp "
            "square pixels (nearest-neighbour), a clean 1-pixel dark outline #14100C, flat colours, at most 3 shades per material, light "
            "from the top-left. No ground under them, no cast shadows, no text.\nFrom left to right:\n")
OBS_TAIL = ("\nColours: bark brown #553C27 #86603E #B08A60; moss #274D24 #599641 #9CCB72; stone grey #57524D #86807A #B9CEE0; blossom pink #EFA6C3 only for "
            "the few small blossoms.\nAttached: a game sprite of this game for pixel size, outline weight and flat look.")
SHEETS = {
    "icons_a": ("violet", ICON_HEAD.format(n=4) + "1. WILD HUNT: three small spectral antlered horsemen in pale frost-white galloping in a line to the right, with soul-teal glints.\n2. GLAMOUR: a bone-white theatre mask in front with two fading copies of it behind, soul-teal sparkle.\n3. ROOT AND ROT: a ring of bark-brown roots around a bone skull, grey rot seeping through the ring.\n4. HORN OF THE HUNT: a curved bone-white hunting horn with a bark-brown mouthpiece band and three frost-blue sound arcs." + ICON_COL + ICON_TAIL),
    "icons_b": ("violet", ICON_HEAD.format(n=4) + "1. CHANGELING: a green leaf folded like a face, half of it pink blossom, half moss, with a soul-teal eye.\n2. COMPOST HEART: a heart of dark brown compost threaded with green roots and tiny bones, a small green sprout on top.\n3. DEADWOOD: a bare dead grey branch with sharp stubs, a crack running through it.\n4. FALLOW GROUND: a patch of cracked dead grey earth with one dead withered seedling." + ICON_COL + ICON_TAIL),
    "icons_c": ("gold", ICON_HEAD.format(n=4) + "1. THE ENDLESS HUNT: a circle of four small antlered horsemen chasing each other in a ring, pale frost-white, a soul-teal glow in the middle.\n2. COURT OF MASKS: three bone-white masks in a row, the middle one big, blossom-pink ribbons.\n3. RETURN TO EARTH: a bone-white skull sinking into brown earth with a green sprout growing from it.\n4. WORLD-ROOT WARDEN: a huge bone-white tree trunk with great roots, a soul-teal knot in the bark, thorny branches." + ICON_COL + ICON_TAIL),
    "icons_d": ("gold", ICON_HEAD.format(n=4) + "1. SCORCHED EARTH: a patch of burnt dead grey ground with orange wildfire flames across it (wildfire orange #E35C26).\n2. A FAIR BARGAIN: two hands clasping, one holding a pink blossom and one a bone, a soul-teal spark between them.\n3. THE FIRST SPRING: a green sprout with two leaves and a pink blossom pushing up through white snow.\n4. OSSUARY OAK: a small tree of bone-white branches with a bark-brown trunk, soul-teal knots (#3DCC94) in the bark." + ICON_COL + ICON_TAIL),
    "obstacles": ("sheet", OBS_HEAD + "1. an old OAK TRUNK: a thick round trunk seen from above-front with moss on the bark and a few leaves (about 36 px wide, 36 px tall);\n2. a mossy STANDING STONE: a grey standing stone lying lengthwise with moss on top (about 52 px wide, 30 px tall);\n3. a THORN THICKET: a round tangled mound of bark-brown bramble canes with long thorns, a few moss tufts and three small pink blossoms (about 52 px wide, 52 px tall)." + OBS_TAIL),
}


def main() -> None:
    names = sys.argv[1:] or [n for n in SHEETS if not (HERE / ("sheet_" + n + ".png")).exists()]
    for n in names:
        kind, prompt = SHEETS[n]
        (HERE / ("sheet_" + n + ".txt")).write_text(prompt + "\n")
        ref = "icon_violet" if kind == "violet" else "icon_gold" if kind == "gold" else None
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / ("sheet_" + n + ".txt")), str(HERE / ("sheet_" + n + ".png")), "--key", "year/" + n, "--size", "1536x1024"]
        cmd += ["--ref", str(HERE / "refs" / (ref + ".png"))] if ref else ["--ref", str(HERE / "refs" / "style_beast.png")]
        print("+", n, flush=True)
        subprocess.run(cmd, cwd=ROOT)


if __name__ == "__main__":
    main()
