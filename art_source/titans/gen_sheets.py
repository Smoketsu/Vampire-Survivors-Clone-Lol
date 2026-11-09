#!/usr/bin/env python3
"""gen_sheets.py: the Age of Titans' icon sheets and the obstacle sheet (one API image each, symbols in a row on transparent alpha).
Usage (repo root): python3 art_source/titans/gen_sheets.py [sheet ...]   (no names = every missing sheet). Sheets land in
art_source/titans/sheet_<name>.png; make_props.py cuts them apart (the symbols' order here is the order it reads)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/titans.
ICON_HEAD = ("A sheet of {n} separate pixel-art game ICON SYMBOLS in one row, evenly spaced with a wide empty gap between them, on a FULLY "
             "TRANSPARENT background (real alpha). Each symbol is simple, bold and centred in its part of the image, drawn as chunky "
             "low-resolution pixel art (each symbol about 24 pixels wide on a coarse grid, shown enlarged with crisp square pixels, "
             "nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left). No frame, no "
             "badge background, no text, no letters, no people.\nFrom left to right:\n")
ICON_COL = "\nColours: fern green #24451F #4D8534 #8CC46A; dust ochre #7E552A #C89448 #E8C88A; bone white #9C9078 #E7DEC9 #F8F6EE; volcanic orange #8A2E0C #EF6B1C #FFC070; tar #231C18 #4A3A30; ghost soul-teal #3DCC94 only where named. NO red, NO gold."
ICON_TAIL = "\nAttached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame)."
OBS_HEAD = ("A sheet of 2 separate pixel-art game OBSTACLE sprites for a top-down 2D horde-survival game (three-quarter top-down view, "
            "camera above and slightly in front), laid out in one row, evenly spaced with wide empty gaps between them, on a FULLY "
            "TRANSPARENT background (real alpha). Prehistoric jungle and badlands. LOW-RESOLUTION pixel art, chunky simple shapes, crisp "
            "square pixels (nearest-neighbour), a clean 1-pixel dark outline #120F0D, flat colours, at most 3 shades per material, light "
            "from the top-left. No ground under them, no cast shadows, no text.\nFrom left to right:\n")
OBS_TAIL = "\nColours: grey-brown rock #231C18 #4A3A30 #6E5A4C; moss #24451F #4D8534 #8CC46A; bone #9C9078 #E7DEC9 #F8F6EE.\nAttached: a game sprite of this game for pixel size, outline weight and flat look."
SHEETS = {
    "icons_a": ("violet", ICON_HEAD.format(n=4) + "1. PACK LEAP: three small raptor silhouettes in bone white leaping in an arc, with soul-teal glints.\n2. STAMPEDE: a bone-white horned skull charging right with three speed lines of ochre dust.\n3. METEOR CALL: a white-hot meteor with a volcanic-orange flame tail falling to the lower left.\n4. PACK INSTINCT: a raptor claw mark of three slashes in fern green over a bone-white paw print." + ICON_COL + ICON_TAIL),
    "icons_b": ("violet", ICON_HEAD.format(n=4) + "1. CALCIFIED HIDE: an ochre scaly hide plate with bone-white ridges, like a section of armour.\n2. COSMIC DUST: a small swirl of white sparkling dust with a volcanic-orange spark, a tiny streak.\n3. HOARDERS BONES: a pile of bone-white bones around a single glowing orange crystal.\n4. THICK MARROW: a bone-white long bone cut open, showing an ochre marrow core." + ICON_COL + ICON_TAIL),
    "icons_c": ("gold", ICON_HEAD.format(n=4) + "1. APEX PACK: a large raptor head in bone white with a tall crest, flanked by two small raptor heads.\n2. HERD OF AGES: a row of three horned skulls in bone white, big in front, ochre dust below.\n3. EXTINCTION EVENT: a huge white meteor breaking into pieces with a big volcanic-orange fireball.\n4. FOSSIL TYRANT: a bone-white tyrannosaur skull, jaw open, soul-teal glow in the eye." + ICON_COL + " Teal #3DCC94 only for item 4." + ICON_TAIL),
    "icons_d": ("gold", ICON_HEAD.format(n=4) + "1. NOTHING TAKEN: a glowing orange crystal inside a closed bone-white claw cage.\n2. TRAMPLED: a big three-toed footprint pressing into cracked ochre earth.\n3. THE DAY THE SKY FELL: a white streak across a dark sky ending in a volcanic-orange burst.\n4. BONEHORN: a skeletal horned charger skull with a bone-white horn and soul-teal glowing eye sockets (#3DCC94)." + ICON_COL + " Teal #3DCC94 only for item 4." + ICON_TAIL),
    "obstacles": ("sheet", OBS_HEAD + "1. a mossy BOULDER: a round rock with moss and ferns on top (about 36 px wide, 36 px tall);\n2. a FOSSIL RIB ARCH: a row of bone-white curved ribs arching over a dark rock base, lying lengthwise (about 52 px wide, 30 px tall)." + OBS_TAIL),
}


def main() -> None:
    names = sys.argv[1:] or [n for n in SHEETS if not (HERE / ("sheet_" + n + ".png")).exists()]
    for n in names:
        kind, prompt = SHEETS[n]
        (HERE / ("sheet_" + n + ".txt")).write_text(prompt + "\n")
        ref = "icon_violet" if kind == "violet" else "icon_gold" if kind == "gold" else None
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / ("sheet_" + n + ".txt")), str(HERE / ("sheet_" + n + ".png")), "--key", "titans/" + n, "--size", "1536x1024"]
        cmd += ["--ref", str(HERE / "refs" / (ref + ".png"))] if ref else ["--ref", str(HERE / "refs" / "style_beast.png")]
        print("+", n, flush=True)
        subprocess.run(cmd, cwd=ROOT)


if __name__ == "__main__":
    main()
