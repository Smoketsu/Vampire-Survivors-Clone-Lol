#!/usr/bin/env python3
"""gen_props2.py: phase 2 single-symbol API images: the Gate of Pearl obstacle and the Turning Bones icon (art_source/host/sheet_pearl_gate.png,
sheet_icon_turning.png). Usage (repo root): python3 art_source/host/gen_props2.py. make_props2.py turns them into game sprites."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
GATE = ("A single pixel-art game OBSTACLE sprite for a top-down 2D horde-survival game (three-quarter top-down view, camera above and slightly in front) "
        "on a FULLY TRANSPARENT background (real alpha): THE GATE OF PEARL, a wide arched gateway of pearl-white stone, two fluted columns and an arch, tall "
        "closed bars of pale light inside the arch with a cerulean glow, a small star above. About 96 pixels wide and 80 tall. LOW-RESOLUTION pixel art, chunky "
        "simple shapes, crisp square pixels, a clean 1-pixel dark outline #0E1626, flat colours, at most 3 shades per material, light from the top-left. No ground, "
        "no shadow, no text. Colours: pearl white stone #8A96AC #C9D2E0 #F4F7FF; cerulean light #1F4F8F #3E8FD8 #9CC8F0; dawn rose accents #F2B8C6; dark #0E1626. NO red, NO gold, NO yellow.\n"
        "Attached: a game sprite of this game for pixel size, outline weight and flat look.")
ICON = ("A single pixel-art game ICON SYMBOL centred on a FULLY TRANSPARENT background (real alpha), simple, bold, chunky low-resolution (about 24 pixels wide on a coarse grid, "
        "crisp square pixels, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left, no frame, no text): TURNING BONES, a small wheel of "
        "BONE-white bones with two curved soul-teal (#3DCC94) arrows chasing each other around it to show it turning. Colours: bone white #CFC7AE #EDE6D0, soul teal #3DCC94, dark #1C110B. NO red, NO gold.\n"
        "Attached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame).")
for name, text, ref in (("pearl_gate", GATE, "style_male"), ("icon_turning", ICON, "icon_violet")):
    (HERE / ("sheet_" + name + ".txt")).write_text(text + "\n")
    subprocess.run([sys.executable, "tools/gen_image.py", str(HERE / ("sheet_" + name + ".txt")), str(HERE / ("sheet_" + name + ".png")), "--ref", str(HERE / "refs" / (ref + ".png")), "--key", "host2/" + name, "--size", "1536x1024"], cwd=ROOT)
