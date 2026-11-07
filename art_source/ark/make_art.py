#!/usr/bin/env python3
"""make_art.py: rebuilds the Ark of the Concord's API art (Act IX, Stage 27) from its sources.

Run from the repo root (python3 art_source/ark/make_art.py [step ...]). Sources: the unit sprites are archived under
art_source/<key>.png (prompts in art_source/ark/<id>.txt; made with tools/gen_image.py against the approved concepts
art_source/concepts/act9_lineup.png and act9_boss.png and the act's own sprites, refs enlarged x4-12 nearest first); the
icon sheets live here. The code-drawn art (floors, obstacles, structures, the ring mask) is tools/ark_tiles.py's. Steps:
  1. units (then pad: the saucers' stills get 2 empty rows above and below for the hover bob): the Grey Overseer, the Luminous Archon, the freed beast, the Harvester and its true form, the Ghost Saucer
     and Black Mothership through tools/prepare_sprite.py with explicit --ramps and --ink-l 0.15;
  2. figures: the Starborn and her three skins (the figure-redesign style) through tools/pixelate_source.py first, then
     prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures"); the Deathlord skin straight (grey first for
     her grey face, --no-levels: the black iron stays black);
  3. badges: each symbol of the two icon sheets (split by empty columns; the generator copied the reference badge in as a
     last symbol, skipped) through prepare_sprite.py --art-height 24, set on the frame of an approved badge (violet
     icons/abyssal_pact, gold icons/tidecallers_host), its inner 26 px cleared to the frame's fill first;
  4. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act IX: the Ark ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/ark.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments).
UNITS = {
    "concord/grey_overseer": ("art_source/concord/grey_overseer.png", ["--ramps", "hull,gunmetal,plasma,lumen", "--ink-l", "0.15"]),
    "concord/luminous_archon": ("art_source/concord/luminous_archon.png", ["--ramps", "lumen,hull,laser,gunmetal", "--ink-l", "0.15"]),
    "concord/vault_beast": ("art_source/concord/vault_beast.png", ["--ramps", "crimson,brown,gold,lumen", "--ink-l", "0.15"]),
    "bosses/harvester": ("art_source/bosses/harvester.png", ["--ramps", "hull,gunmetal,plasma", "--ink-l", "0.15"]),
    "bosses/harvester_true": ("art_source/bosses/harvester_true.png", ["--ramps", "lumen,gold,hull,plasma", "--ink-l", "0.15"]),
    "summons/ghost_saucer": ("art_source/summons/ghost_saucer.png", ["--ramps", "bone,grey,soul", "--ink-l", "0.12"]),
    "summons/black_mothership": ("art_source/summons/black_mothership.png", ["--ramps", "velvet,bone,soul,grey", "--ink-l", "0.12", "--no-levels"]),
}
# Hover units whose stills get 2 empty rows above and below (pad(), after units()): the walk strip's bob.
HOVER_PAD = ["summons/ghost_saucer", "summons/black_mothership"]
# The figure-redesign figures: key -> (source, art height, extra arguments).
FIGURES = {
    "player/starborn": ("art_source/player/starborn.png", 56, ["--ramps", "hull,gunmetal,plasma,grey"]),
    "player/starborn_hyper": ("art_source/player/starborn_hyper.png", 56, ["--ramps", "gold,hull,grey"]),
    "player/starborn_untouchable": ("art_source/player/starborn_untouchable.png", 56, ["--ramps", "marble,soul,grey"]),
    "player/starborn_deathlord": ("art_source/player/starborn_deathlord.png", 56, ["--ramps", "grey,velvet,crimson,hull", "--no-levels"]),  # R1 redo: black half-mask visor (raw in art_source/crash_site/raw/r1/sdl_a.png, archived here by prepare_sprite)  # grey first for her grey face, --no-levels and keeps the black iron black (ART_BIBLE, Act VII round 1)
}
# Figures converted straight by prepare_sprite.py (no pixelate_source step).
DIRECT = ["player/starborn_deathlord"]
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["tractor_lift", "starseed", "ghost_saucer", "crop_circles", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["star_abduction", "black_mothership", "ach_last_harvest", ""]),
}
# Walk strips (rigs in tools/walk_cycle.py) and the idle strips of the women (bust rigs).
STRIPS = ["concord/grey_overseer", "concord/luminous_archon", "concord/vault_beast", "bosses/harvester",
          "player/starborn", "player/starborn_hyper", "player/starborn_untouchable", "player/starborn_deathlord",
          "summons/ghost_saucer", "summons/black_mothership"]
IDLES = ["player/starborn", "player/starborn_hyper", "player/starborn_untouchable", "player/starborn_deathlord"]


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
        keep = (ROOT / src).read_bytes()  # The untouched source (prepare_sprite archives the file it is given).
        run(["tools/prepare_sprite.py", src, key] + extra)
        (ROOT / src).write_bytes(keep)


def pad() -> None:
    """The hover strips bob 2 px: the saucers' stills get 2 empty rows above and below (as concord/saucer)."""
    for key in HOVER_PAD:
        path = ROOT / "assets/sprites" / (key + ".png")
        im = Image.open(path).convert("RGBA")
        out = Image.new("RGBA", (im.width, im.height + 4), (0, 0, 0, 0))
        out.alpha_composite(im, (0, 2))
        out.save(path)


def figures() -> None:
    for key, (src, height, extra) in FIGURES.items():
        keep = (ROOT / src).read_bytes()  # The untouched source.
        pix = SCRATCH / (key.replace("/", "_") + ".png")
        if key in DIRECT:
            run(["tools/prepare_sprite.py", src, key, "--ink-l", "0.15", "--art-height", str(height)] + extra)
            (ROOT / src).write_bytes(keep)
            continue
        run(["tools/pixelate_source.py", src, str(height), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--ink-l", "0.15", "--no-cleanup", "--art-height", str(height)] + extra)
        (ROOT / src).write_bytes(keep)


def badges() -> None:
    for sheet, (frame_key, ids) in ICONS.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 0, min_gap=4)  # The symbols sit close together on these sheets.
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


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + STRIPS)
    run(["tools/walk_cycle.py", "idle"] + IDLES)


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "pad", "figures", "badges", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
