#!/usr/bin/env python3
"""make_art.py: rebuilds the Palace of Silk and Ash's art (Act VI, Stage 17) from its API sources.

Run from the repo root (python3 art_source/silk_palace/make_art.py [step ...]). Sources: the unit sprites are kept
under art_source/<key>.png (prompts in art_source/silk_palace/<id>.txt); the sheets (icons, props) live here and the
floor textures in art_source/tiles/. Steps:
  1. units: the bosses (Lilith and her true form) through tools/prepare_sprite.py with explicit --ramps;
  2. figures: the female figures (the Lilim Witch, the Twin Succubi, the Succubus Queen and her three skins, the
     Succubus summon and the Lilim Matriarch) through tools/pixelate_source.py first, then prepare_sprite.py
     --ink-l 0.15 --no-cleanup --no-prune (the succubus's route, ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets (split by empty columns) through prepare_sprite.py --art-height 24,
     set on the frame of an approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host);
  4. obstacles: each prop of the two prop sheets converted at each size of SilkPalaceStage.ZONES (circles:
     width = footprint + 4; rects: length + 2 wide, the end-on _v stretched to length + 14 tall);
  5. floors: tools/make_tile.py recipes silk_palace_* (sources art_source/tiles/silk_palace_soil / _marble);
  6. strips: tools/walk_cycle.py walk and idle strips (rigs under "# --- Act VI: the Palace of Silk and Ash ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/silk_palace.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# The Inferno's ramps (ART_BIBLE "Act VI: the Inferno, the shared kinds").
INF = "obsidian,lava,demon,charm,grey,skin,brown"
# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments): the bosses, converted directly.
UNITS = {
    "bosses/lilith": ("art_source/bosses/lilith.png", ["--ramps", "obsidian,demon,crimson,charm,skin,gold", "--ink-l", "0.18"]),
    "bosses/lilith_demon": ("art_source/bosses/lilith_demon.png", ["--ramps", "obsidian,demon,lava,charm,crimson,grey", "--ink-l", "0.18"]),
}
# The figures (female, the approved Act VI figure style): key -> (source, art height, extra arguments).
FIGURES = {
    "inferno/lilim_witch": ("art_source/inferno/lilim_witch.png", 56, ["--ramps", "obsidian,demon,crimson,charm,lava,skin,marble,gold"]),
    "inferno/twin_naamah": ("art_source/inferno/twin_naamah.png", 62, ["--ramps", "obsidian,demon,charm,violet,skin,gold"]),
    "inferno/twin_agrat": ("art_source/inferno/twin_agrat.png", 62, ["--ramps", "obsidian,demon,crimson,charm,skin,marble,gold"]),
    "player/succubus_queen": ("art_source/player/succubus_queen.png", 56, ["--ramps", "violet,demon,charm,obsidian,skin,gold"]),
    "player/succubus_queen_hyper": ("art_source/player/succubus_queen_hyper.png", 56, ["--ramps", "gold,marble,charm,skin,bone"]),
    "player/succubus_queen_untouchable": ("art_source/player/succubus_queen_untouchable.png", 56, ["--ramps", "marble,soul,grey,bone"]),
    "player/succubus_queen_deathlord": ("art_source/player/succubus_queen_deathlord.png", 58, ["--ramps", "grey,crimson,obsidian,skin,bone"]),
    "summons/bound_succubus": ("art_source/summons/bound_succubus.png", 52, ["--ramps", "obsidian,bone,soul,grey,demon,charm"]),
    "summons/lilim_matriarch": ("art_source/summons/lilim_matriarch.png", 62, ["--ramps", "obsidian,bone,soul,grey,violet,gold"]),
}
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["tempt", "velvet_chains", "bound_succubus", "sweet_surrender", "faithless", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["unholy_desire", "lilim_matriarch", "ach_unmoved", ""]),
}
# Round props (props_round.png, left to right) -> their footprint radii (px), smallest first (SilkPalaceStage.ZONES).
ROUND = [("black_rosebush", [12, 15]), ("rose_column", [12, 16]), ("palace_mirror", [11, 13]), ("candelabra", [9, 11])]
# Long props (props_long.png: top row horizontal, bottom row end-on) -> (long sides, short side) (SilkPalaceStage.ZONES).
LONG = [("velvet_divan", [40, 52], 20), ("mirror_wall", [44, 60], 14)]
# Size suffixes by the number of sizes (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES).
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
# Most height of a round prop as a multiple of its width (a slender crop would stand far above the units).
TALL_MAX = 2.1  # Lower than the Road to the Sun's 2.6: the palace column and mirror would tower over the units.
# Ramps of the props (the converter prunes the ones a prop does not use).
PROP_RAMPS = "obsidian,demon,charm,gold,marble,violet,grey"


def run(args: list) -> None:
    """Runs a repo tool, failing loudly."""
    print("+", " ".join(args))
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def islands(im: Image.Image, axis: int, min_gap: int = 12) -> list:
    """Spans [a, b) of opaque columns (axis 0) or rows (axis 1) separated by >= min_gap empty ones."""
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    w, h = a.size
    occ = []
    for i in range(w if axis == 0 else h):
        box = (i, 0, i + 1, h) if axis == 0 else (0, i, w, i + 1)
        occ.append(a.crop(box).getbbox() is not None)
    spans, start, gap = [], None, 0
    for i, o in enumerate(occ):
        if o:
            if start is None:
                start = i
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                spans.append((start, i - gap + 1))
                start, gap = None, 0
    if start is not None:
        spans.append((start, len(occ)))
    return spans


def crop_tight(im: Image.Image) -> Image.Image:
    """Crops to the opaque pixels."""
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    return im.crop(a.getbbox())


def units() -> None:
    for key, (src, extra) in UNITS.items():
        run(["tools/prepare_sprite.py", src, key] + extra)


def figures() -> None:
    for key, (src, height, extra) in FIGURES.items():
        keep = (ROOT / src).read_bytes()  # The untouched source (prepare_sprite archives the file it is given).
        pix = SCRATCH / (key.replace("/", "_") + ".png")
        run(["tools/pixelate_source.py", src, str(height), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--art-height", str(height), "--ink-l", "0.15", "--no-cleanup", "--no-prune"] + extra)
        (ROOT / src).write_bytes(keep)


def badges() -> None:
    for sheet, (frame_key, ids) in ICONS.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 0)
        for (x0, x1), sid in zip(spans, ids):
            if sid == "":
                continue
            sym = crop_tight(im.crop((x0, 0, x1, im.height)))
            p = SCRATCH / (sid + ".png")
            sym.save(p)
            out = SCRATCH / (sid + "_24.png")
            run(["tools/prepare_sprite.py", str(p), "icons/" + sid, "--art-height", "24", "--ink-l", "0.2", "--out", str(out)])
            frame = Image.open(ROOT / "assets/sprites" / (frame_key + ".png")).convert("RGBA")
            fill = frame.getpixel((4, 16))
            for y in range(3, 29):
                for x in range(3, 29):
                    frame.putpixel((x, y), fill)
            s = Image.open(out).convert("RGBA")
            if s.width > 26:
                s = s.resize((26, round(s.height * 26 / s.width)), Image.NEAREST)
            frame.alpha_composite(s, ((32 - s.width) // 2, (32 - s.height) // 2))
            frame.save(ROOT / "assets/sprites/icons" / (sid + ".png"))


def props() -> None:
    im = Image.open(HERE / "props_round.png").convert("RGBA")
    for (x0, x1), (kind, radii) in zip(islands(im, 0), ROUND):
        prop = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (kind + ".png")
        prop.save(p)
        for r, suf in zip(radii, SUFFIXES[len(radii)]):
            w = 2 * r + 4  # Art px wide: the footprint plus 4.
            h = max(8, min(round(w * prop.height / prop.width), round(w * TALL_MAX)))  # The torii post's slender crop is capped.
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s" % (kind, suf), "--art-height", str(h), "--ink-l", "0.2", "--ramps", PROP_RAMPS])
    im = Image.open(HERE / "props_long.png").convert("RGBA")
    rows = islands(im, 1)
    top = im.crop((0, rows[0][0], im.width, rows[0][1]))
    bottom = im.crop((0, rows[1][0], im.width, rows[1][1]))
    for (x0, x1), (kind, lengths, short) in zip(islands(top, 0), LONG):
        prop = crop_tight(top.crop((x0, 0, x1, top.height)))
        p = SCRATCH / (kind + ".png")
        prop.save(p)
        for ln, suf in zip(lengths, SUFFIXES[len(lengths)]):
            w = ln + 2
            h = max(8, round(w * prop.height / prop.width))
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s" % (kind, suf), "--art-height", str(h), "--ink-l", "0.2", "--ramps", PROP_RAMPS])
    for (x0, x1), (kind, lengths, short) in zip(islands(bottom, 0), LONG):
        prop = crop_tight(bottom.crop((x0, 0, x1, bottom.height)))
        for ln, suf in zip(lengths, SUFFIXES[len(lengths)]):
            th = ln + 14  # Art px tall: the end-on prop stretched to the length.
            tw = short + 10
            st = prop.resize((tw * 8, th * 8), Image.LANCZOS)
            p = SCRATCH / ("%s_v_%s.png" % (kind, suf))
            st.save(p)
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s_v" % (kind, suf), "--art-height", str(th), "--ink-l", "0.2", "--ramps", PROP_RAMPS])


def floors() -> None:
    run(["tools/make_tile.py", "build", "silk_palace_roses", "silk_palace_mirrors", "silk_palace_ballroom", "silk_palace_chamber"])


def strips() -> None:
    walk = ["inferno/lilim_witch", "inferno/twin_naamah", "inferno/twin_agrat", "bosses/lilith", "player/succubus_queen",
            "player/succubus_queen_hyper", "player/succubus_queen_untouchable", "player/succubus_queen_deathlord",
            "summons/bound_succubus", "summons/lilim_matriarch"]
    for key in walk:
        run(["tools/walk_cycle.py", "build", key])
    for key in walk:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
