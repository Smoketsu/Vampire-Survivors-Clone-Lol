#!/usr/bin/env python3
"""make_art.py: rebuilds Liberty Heights's art (Act VIII, Stage 24) from its API sources.

Run from the repo root (python3 art_source/liberty_heights/make_art.py [step ...]). Sources: the unit sprites are
archived under art_source/<key>.png (prompts in art_source/liberty_heights/<id>.txt; made with tools/gen_image.py against
the approved concepts art_source/concepts/act8_lineup.png and act8_boss.png); the icon sheets live here. Steps:
  1. units: Atlas, Nightjar, the Conscript, Paragon, the Fallen Hero and Black Paragon through tools/prepare_sprite.py
     with explicit --ramps and --ink-l 0.15;
  2. figures: Aurora and the Revenant Heroine with her three skins (the figure-redesign style) through
     tools/pixelate_source.py first, then prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets (split by empty columns) through prepare_sprite.py --art-height 24,
     set on the frame of an approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host), its inner 26 px
     cleared to the frame's fill first;
  4. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act VIII: Liberty Heights ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/liberty_heights.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments).
UNITS = {
    "city/atlas": ("art_source/city/atlas.png", ["--ramps", "moss,gold,skin,brown", "--ink-l", "0.15"]),
    "city/nightjar": ("art_source/city/nightjar.png", ["--ramps", "concrete,violet,neon_cyan,steel", "--ink-l", "0.15"]),
    "city/conscript": ("art_source/city/conscript.png", ["--ramps", "olive,skin,steel,asphalt", "--ink-l", "0.15"]),
    "bosses/paragon": ("art_source/bosses/paragon.png", ["--ramps", "marble,steel,gold,police,skin,siren_red", "--ink-l", "0.15"]),
    "summons/fallen_hero": ("art_source/summons/fallen_hero.png", ["--ramps", "grey,steel,velvet,soul", "--ink-l", "0.12"]),
    "summons/black_paragon": ("art_source/summons/black_paragon.png", ["--ramps", "grey,steel,velvet,soul", "--ink-l", "0.12"]),
}
# The figure-redesign figures: key -> (source, art height, extra arguments).
FIGURES = {
    "city/aurora": ("art_source/city/aurora.png", 48, ["--ramps", "marble,gold,skin"]),
    "player/revenant_heroine": ("art_source/player/revenant_heroine.png", 56, ["--ramps", "indigo,steel,grey,soul,velvet"]),
    "player/revenant_heroine_hyper": ("art_source/player/revenant_heroine_hyper.png", 56, ["--ramps", "gold,marble,skin,soul"]),
    "player/revenant_heroine_untouchable": ("art_source/player/revenant_heroine_untouchable.png", 56, ["--ramps", "marble,soul,grey"]),
    "player/revenant_heroine_deathlord": ("art_source/player/revenant_heroine_deathlord.png", 56, ["--ramps", "grey,crimson,skin", "--no-levels"]),  # --no-levels keeps the black iron black
}
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["heros_fist", "secret_identity", "fallen_hero", "origin_story", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["doomsday", "black_paragon", "ach_no_more_heroes", ""]),
}
# Walk strips (rigs in tools/walk_cycle.py) and the idle strips of the women (bust rigs).
STRIPS = ["city/atlas", "city/aurora", "city/nightjar", "city/conscript", "bosses/paragon", "player/revenant_heroine",
          "player/revenant_heroine_hyper", "player/revenant_heroine_untouchable", "player/revenant_heroine_deathlord",
          "summons/fallen_hero", "summons/black_paragon"]
IDLES = ["city/aurora", "player/revenant_heroine", "player/revenant_heroine_hyper",
         "player/revenant_heroine_untouchable", "player/revenant_heroine_deathlord"]


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
    steps = sys.argv[1:] or ["units", "figures", "badges", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
