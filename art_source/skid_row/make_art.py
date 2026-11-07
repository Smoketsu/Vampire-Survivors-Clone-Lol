#!/usr/bin/env python3
"""make_art.py: rebuilds Skid Row's art (Act VIII, Stage 22; ART_BIBLE "Act VIII: Skid Row") from its API sources.

Run from the repo root (python3 art_source/skid_row/make_art.py [step ...]). Raw API images in art_source/skid_row/raw/
(prompts beside this file), the icon sheets here. Steps (Ravensmoor's recipe):
  1. units: Don Marrow, Big Sal's Armoured Limo, Big Sal, the bounty board, the spectral hearse and the Undertaker
     with his three skins through tools/prepare_sprite.py (--ink-l 0.15, the city ramps per key);
  2. wrecks: the two wrecks of raw/wrecks.png (burning, burnt out) cut apart, stretched to WRECK_SIZE (the wreck's
     52 x 36 collision rect plus a margin: the old 32 px art left bodies stopping on air) and converted;
  3. badges: each symbol of the two icon sheets through prepare_sprite.py --art-height 24, set on the frame of an
     approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host); the gold sheet came back with one
     extra copy of the reference badge, skipped ("");
  4. tiles: art_source/skid_row/skid_row_tiles.py (the precinct roof, the market stall and the overpass footing);
  5. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act VIII: Skid Row ---").
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/skid_row.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (raw source, extra prepare_sprite arguments).
UNITS = {
    "bosses/don_marrow": ("raw/don_marrow.png", ["--ramps", "bone,asphalt,siren_red,skin,neon_sodium,brown,concrete", "--ink-l", "0.15"]),
    "city/armoured_limo": ("raw/armoured_limo.png", ["--ramps", "asphalt,concrete,neon_sodium,brown", "--ink-l", "0.12"]),
    "city/big_sal": ("raw/big_sal.png", ["--ramps", "asphalt,concrete,skin,brown,neon_cyan", "--ink-l", "0.12"]),
    "structures/bounty_board": ("raw/bounty_board.png", ["--ramps", "brown,bone,asphalt,neon_sodium,concrete", "--ink-l", "0.15"]),
    "projectiles/spectral_hearse": ("raw/spectral_hearse.png", ["--ramps", "soul,asphalt,bone", "--ink-l", "0.15", "--no-levels"]),
    "player/undertaker": ("raw/undertaker.png", ["--ramps", "asphalt,concrete,bone,skin,neon_sodium,soul", "--ink-l", "0.12"]),
    "player/undertaker_hyper": ("raw/undertaker_hyper.png", ["--ramps", "gold,bone,asphalt,skin,soul", "--ink-l", "0.15", "--no-levels"]),
    "player/undertaker_untouchable": ("raw/undertaker_untouchable.png", ["--ramps", "marble,soul,grey,skin", "--ink-l", "0.15"]),
    "player/undertaker_deathlord": ("raw/undertaker_deathlord.png", ["--ramps", "velvet,grey,crimson,skin,bone", "--ink-l", "0.15", "--no-levels"]),
}
# The wrecks: sheet raw/wrecks.png (left burning, right burnt) -> sprite keys, and the art size (w, h) both get.
WRECKS = ["structures/city_wreck", "structures/city_wreck_burnt"]
WRECK_SIZE = (58, 38)  # The rect is 52 x 36 (CityBlocks.add_wreck() half 26 x 18): a few px over each side.
WRECK_RAMPS = "asphalt,concrete,brown,hero,neon_sodium,hazard,siren_red"
# Icon sheets: file -> (badge frame, symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["hearse_run", "black_car", "kevlar_bones"]),
    "icons_gold.png": ("icons/tidecallers_host", ["funeral_procession", "ach_no_witnesses", ""]),
}


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
        if not (HERE / src).exists():
            print("skip (no source yet):", key)
            continue
        keep = (HERE / src).read_bytes()
        run(["tools/prepare_sprite.py", str(HERE / src), key] + extra)
        (HERE / src).write_bytes(keep)


def wrecks() -> None:
    im = Image.open(HERE / "raw/wrecks.png").convert("RGBA")
    spans = islands(im, 0)
    for (x0, x1), key in zip(spans, WRECKS):
        part = crop_tight(im.crop((x0, 0, x1, im.height)))
        w, h = WRECK_SIZE
        st = part.resize((w * 8, h * 8), Image.LANCZOS)  # Stretched to the footprint (a car seen from 3/4 above).
        p = SCRATCH / (key.replace("/", "_") + ".png")
        st.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", WRECK_RAMPS])


def badges() -> None:
    for sheet, (frame_key, ids) in ICONS.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 0, min_gap=4)
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


def tiles() -> None:
    run([str(HERE / "skid_row_tiles.py")])


def strips() -> None:
    for key in ["bosses/don_marrow", "city/armoured_limo", "city/big_sal", "player/undertaker", "player/undertaker_hyper",
                "player/undertaker_untouchable", "player/undertaker_deathlord"]:
        if (ROOT / "assets/sprites" / (key + ".png")).exists():
            run(["tools/walk_cycle.py", "build", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "wrecks", "badges", "tiles", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
