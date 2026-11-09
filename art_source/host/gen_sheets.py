#!/usr/bin/env python3
"""gen_sheets.py: the Host's icon sheets and the obstacle sheet (one API image each, symbols in a row on transparent alpha).
Usage (repo root): python3 art_source/host/gen_sheets.py [sheet ...]   (no names = every missing sheet). Sheets land in
art_source/host/sheet_<name>.png; make_props.py cuts them apart (the symbols' order here is the order it reads)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
ICON_HEAD = ("A sheet of {n} separate pixel-art game ICON SYMBOLS in one row, evenly spaced with a wide empty gap between them, on a FULLY "
             "TRANSPARENT background (real alpha). Each symbol is simple, bold and centred in its part of the image, drawn as chunky "
             "low-resolution pixel art (each symbol about 24 pixels wide on a coarse grid, shown enlarged with crisp square pixels, "
             "nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left). No frame, no "
             "badge background, no text, no letters.\nFrom left to right:\n")
ICON_COL = "\nColours: starlight white #F4F7FF; pale silver #8A96AC #C9D2E0; cerulean #1F4F8F #3E8FD8 #9CC8F0; dawn rose #B07888 #F2B8C6; dark #0E1626. NO red, NO gold, NO yellow."
ICON_TAIL = "\nAttached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame)."
OBS_HEAD = ("A sheet of 4 separate pixel-art game OBSTACLE sprites for a top-down 2D horde-survival game (three-quarter top-down view, "
            "camera above and slightly in front), laid out in one row, evenly spaced with wide empty gaps between them, on a FULLY "
            "TRANSPARENT background (real alpha). Heaven's stair: white stone, cloud and light, no red, no gold. LOW-RESOLUTION pixel art, "
            "chunky simple shapes, crisp square pixels (nearest-neighbour), a clean 1-pixel dark outline #0E1626, flat colours, at most 3 shades "
            "per material, light from the top-left. No ground under them, no cast shadows, no text.\nFrom left to right:\n")
OBS_TAIL = "\nColours: white stone #8A96AC #C9D2E0 #F4F7FF; cerulean light #1F4F8F #3E8FD8 #9CC8F0; cloud #DCE4F0; dark #0E1626.\nAttached: a game sprite of this game for pixel size, outline weight and flat look."
SHEETS = {
    "icons_a": ("violet", ICON_HEAD.format(n=4) + "1. FLAMING SWORD: an upright sword of white flame, silver hilt, cerulean flame edges.\n2. WHEEL OF EYES: a silver ring with a smaller ring inside, small cerulean eyes along the rims.\n3. REVELATION: an open silver eye inside a ring of radiating thin white rays.\n4. FALLEN LIGHT: a single white feather falling with a cerulean spark trail." + ICON_COL + ICON_TAIL),
    "icons_b": ("violet", ICON_HEAD.format(n=4) + "1. ALL-SEEING: one large silver eye with a cerulean iris, rays above it.\n2. SEVENTH SEAL: a round silver seal with seven small dots around a cerulean centre.\n3. ABSOLUTION: a pair of balance scales, the pans lifted, dawn-rose pans, silver beam.\n4. SMOKED GLASS: a dark-blue glass pane (a rounded diamond) with a pale reflection streak." + ICON_COL + ICON_TAIL),
    "icons_c": ("gold", ICON_HEAD.format(n=4) + "1. SWORD AT THE GATE: a tall sword of white flame standing before a small silver arched gate.\n2. OPHANIM: a burning silver wheel within a wheel, covered in small cerulean eyes, cerulean fire around it.\n3. BE NOT AFRAID: six white wings (three each side) around a bright white rose of light.\n4. WITHOUT SIN: a pure white feather inside a thin silver ring, tiny sparks." + ICON_COL + ICON_TAIL),
    "icons_d": ("gold", ICON_HEAD.format(n=4) + "1. THE WHEEL BREAKS: a silver wheel cracked in two with cerulean light leaking out of the crack.\n2. THE LAST WORD: a long silver trumpet with a white burst of sound rays from its bell.\n3. BOUND OPHAN: a small wheel of BONE-white bones with soul-teal glowing eyes (#3DCC94) along the rim.\n4. THRONE OF BONES: a double wheel of bone-white bones with soul-teal fire (#3DCC94) in the middle." + ICON_COL + " Teal #3DCC94 only for items 3 and 4." + ICON_TAIL),
    "obstacles": ("sheet", OBS_HEAD + "1. a PILLAR of white stone: a round fluted column with a glowing cerulean band of light around it (about 30 px wide, 46 px tall);\n2. a CLOUDSTONE: a wide block of the stair wrapped in a puffy white cloud (about 52 px wide, 30 px tall);\n3. a CRYSTAL: a shard of a heavenly sphere, a long cerulean see-through crystal lying along the ground with a pale edge (about 44 px wide, 26 px tall);\n4. a PETAL: a standing petal of light, a long curved white-and-pale-rose petal (about 56 px wide, 24 px tall)." + OBS_TAIL),
}


def main() -> None:
    names = sys.argv[1:] or [n for n in SHEETS if not (HERE / ("sheet_" + n + ".png")).exists()]
    for n in names:
        kind, prompt = SHEETS[n]
        (HERE / ("sheet_" + n + ".txt")).write_text(prompt + "\n")
        ref = "icon_violet" if kind == "violet" else "icon_gold" if kind == "gold" else None
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / ("sheet_" + n + ".txt")), str(HERE / ("sheet_" + n + ".png")), "--key", "host/" + n, "--size", "1536x1024"]
        cmd += ["--ref", str(HERE / "refs" / (ref + ".png"))] if ref else ["--ref", str(HERE / "refs" / "style_male.png")]
        print("+", n, flush=True)
        subprocess.run(cmd, cwd=ROOT)


if __name__ == "__main__":
    main()
