#!/usr/bin/env python3
"""gen_sheets.py: the Dynasty's icon sheets and obstacle sheets (one API image each, symbols in a row on transparent alpha).
Usage (repo root): python3 art_source/dynasty/gen_sheets.py [sheet ...]   (no names = every missing sheet). Sheets land in
art_source/dynasty/sheet_<name>.png; make_props.py cuts them apart. The symbols' order here is the order make_props.py reads."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty.
ICON_HEAD = ("A sheet of {n} separate pixel-art game ICON SYMBOLS in one row, evenly spaced with a wide empty gap between them, on a FULLY "
             "TRANSPARENT background (real alpha). Each symbol is simple, bold and centred in its part of the image, drawn as chunky "
             "low-resolution pixel art (each symbol about 24 pixels wide on a coarse grid, shown enlarged with crisp square pixels, "
             "nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left). No frame, no "
             "badge background, no text, no letters, no hieroglyph writing.\nFrom left to right:\n")
ICON_TAIL = "\nAttached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame)."
OBS_HEAD = ("A sheet of {n} separate pixel-art game OBSTACLE sprites for a top-down 2D horde-survival game (three-quarter top-down view, "
            "camera above and slightly in front), laid out in one row, evenly spaced with wide empty gaps between them, on a FULLY "
            "TRANSPARENT background (real alpha). Ancient Egyptian necropolis, sandstone with lapis blue and dull bronze painted details. "
            "LOW-RESOLUTION pixel art, chunky simple shapes, crisp square pixels (nearest-neighbour), a clean 1-pixel dark outline, flat "
            "colours, at most 3 shades per material, light from the top-left. No ground under them, no cast shadows, no text, no hieroglyph writing.\nFrom left to right:\n")
OBS_TAIL = "\nColours: sandstone #8C6B3E #D2B574 #F0DDA6; lapis #16327C #2B54B8 #5F8BE6; dull bronze #6B5A22 #A38E3C #D2BB62; papyrus green #285A30 #4E8F40; night #1B2038 #2E3660; fire #BF3B2B #E87855 #FFDC66.\nAttached: a game sprite of this game for pixel size, outline weight and flat look."
SHEETS = {
    "icons_a": ("violet", ICON_HEAD.format(n=4) + "1. LINEN BIND: a white linen bandage spiralling around a pale skeletal hand, loose ends curling.\n2. BURNING EYE: the Eye of Ra, a carnelian-red and dull-bronze eye with a flame rising from its brow.\n3. FEATHER'S VERDICT: a single upright true-gold feather (the feather of Ma'at) above a small balanced pair of scales.\n4. NATRON SALTS: a small bowl heaped with white-and-pale-blue salt crystals, a few crystals scattered." + "\nColours: linen #8F8670 #C9C0A4 #F0E8D2; bone #8A8070 #C8BC9C; true gold #8A5A12 #E0A92E #FFDC66; carnelian #7B1E16 #BF3B2B #E87855; bronze #6B5A22 #A38E3C; salt #A7B3C6 #E8F0F8; dark #0B0A10." + ICON_TAIL),
    "icons_b": ("violet", ICON_HEAD.format(n=4) + "1. DESERT FURY: a spiral of whirling sand and wind with a small red sun in its centre.\n2. HEAVY HEART: a dark red heart weighed down on one pan of a hanging scale, the pan sagging.\n3. EMBALMED BONES: a bone wrapped in linen bandage with a small scarab-blue gem on it.\n4. DUNE WALKERS: a leather sandal with a gold strap stepping on a sand dune ripple.\nColours: sand #8C6B3E #D2B574 #F0DDA6; carnelian #7B1E16 #BF3B2B #E87855; linen #8F8670 #C9C0A4 #F0E8D2; lapis #2B54B8 #5F8BE6; bronze #6B5A22 #A38E3C #D2BB62; leather #4F3320 #8C6040; dark #0B0A10." + ICON_TAIL),
    "icons_c": ("gold", ICON_HEAD.format(n=4) + "1. ETERNAL SHROUD: a tall linen-wrapped mummy shape glowing with soul-teal light under a gold halo of bandages.\n2. EYE OF RETRIBUTION: a large carnelian-red and true-gold Eye of Ra with a beam of red light shining from it.\n3. HEART DEVOURED: a crocodile-headed jaw biting down on a dark red heart, a gold feather behind it.\n4. NAMES TAKEN: a gold oval cartouche (a rounded rectangle ring with a bar at one end) with three simple glyph marks inside and a small teal glow.\nColours: linen #8F8670 #C9C0A4 #F0E8D2; true gold #8A5A12 #E0A92E #FFDC66; soul teal #1C6B58 #3DCC94 #A8FFD2; carnelian #7B1E16 #BF3B2B #E87855; papyrus green #285A30 #4E8F40 #8CC45E; dark #0B0A10." + ICON_TAIL),
    "icons_d": ("gold", ICON_HEAD.format(n=4) + "1. NO JARS LEFT: a canopic jar with a jackal-head lid shattered into pieces, a gold spark above.\n2. A LIGHT HEART: a glowing true-gold heart lighter than a white feather on a balance scale, the scale tipped toward the heart.\n3. USHABTI SENTINEL: a grey-sandstone mummiform statue servant holding a staff and a shield, soul-teal glowing eyes.\n4. ETERNAL GUARD: a tall true-gold-trimmed sandstone statue servant with a large gold sun shield, soul-teal glowing eyes.\nColours: sandstone #8C6B3E #D2B574 #F0DDA6; stone grey #3B4352 #6B7A94 #A7B3C6; true gold #8A5A12 #E0A92E #FFDC66; soul teal #1C6B58 #3DCC94 #A8FFD2; lapis #2B54B8; dark #0B0A10." + ICON_TAIL),
    "markers": ("none", ICON_HEAD.format(n=2) + "1. A CARTOUCHE: a bright true-gold oval ring (a rounded rectangle, tall, with a short horizontal bar closing it at the bottom) holding two simple dark glyph marks, glowing gold.\n2. A HEKA GLYPH: a small bright true-gold sigil of an eye above a wavy line inside a thin ring, glowing gold.\nColours: true gold #8A5A12 #E0A92E #FFDC66; dark #3A2410. Bold shapes readable at 16 pixels." + ICON_TAIL),
    "obstacles_a": ("sheet", OBS_HEAD.format(n=7) + "1. a SMALL rock-cut TOMB: a low sandstone block with a dark doorway and a lapis lintel (about 30 px wide);\n2. a LARGE mortuary TOMB: a wide stepped sandstone mastaba with a dark doorway and bronze door bands (about 46 px wide);\n3. a SMALL OBELISK: a thin sandstone obelisk with a bronze pointed tip, standing (about 14 px wide, 40 px tall);\n4. a TALL OBELISK: a tall sandstone obelisk with a bronze tip on a stepped base (about 18 px wide, 58 px tall);\n5. a SHORT ROW of three dormant sandstone USHABTI STATUES standing side by side in a shallow niche (about 36 px wide, 34 px tall);\n6. a LONG ROW of five dormant sandstone USHABTI STATUES standing side by side in a shallow niche (about 56 px wide, 34 px tall);\n7. a SHORT COLONNADE: three round sandstone columns with lapis-painted capitals joined by a stone beam on top (about 44 px wide, 32 px tall)." + OBS_TAIL),
    "obstacles_b": ("sheet", OBS_HEAD.format(n=5) + "1. a LONG COLONNADE: five round sandstone columns with lapis-painted capitals joined by a stone beam on top (about 70 px wide, 32 px tall);\n2. the GREAT SCALES: a huge gold-bronze balance scale on a sandstone pedestal, two wide pans hanging from a beam, a small feather weight on one pan (about 64 px wide, 56 px tall);\n3. a stone BRAZIER: a sandstone bowl on a pillar holding a bright fire (about 16 px wide, 28 px tall);\n4. a broken SPHINX HEAD half-buried in sand, lapis striped headdress, weathered (about 34 px wide, 28 px tall);\n5. a heap of broken sandstone BLOCKS and a snapped column (about 36 px wide, 24 px tall)." + OBS_TAIL),
}


def main() -> None:
    names = sys.argv[1:] or [n for n in SHEETS if not (HERE / ("sheet_" + n + ".png")).exists()]
    for n in names:
        kind, prompt = SHEETS[n]
        (HERE / ("sheet_" + n + ".txt")).write_text(prompt + "\n")
        ref = "icon_violet" if kind == "violet" else "icon_gold" if kind in ("gold", "none") else None
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / ("sheet_" + n + ".txt")), str(HERE / ("sheet_" + n + ".png")), "--key", "dynasty/" + n, "--size", "1536x1024"]
        cmd += ["--ref", str(HERE / "refs" / (ref + ".png"))] if ref else ["--ref", str(HERE / "refs" / "style_male.png")]
        print("+", n, flush=True)
        subprocess.run(cmd, cwd=ROOT)


if __name__ == "__main__":
    main()
