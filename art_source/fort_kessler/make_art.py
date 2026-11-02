#!/usr/bin/env python3
"""make_art.py: rebuilds Fort Kessler's art (Act VIII, Stage 23; ART_BIBLE "Act VIII: Fort Kessler") from its API sources.

Run from the repo root (python3 art_source/fort_kessler/make_art.py [step ...]). Raw API images in
art_source/fort_kessler/raw/ (prompts beside this file), the sheets (icons, props) here, references in refs/.
Steps (Ravensmoor's recipe):
  1. units: the Machine Gunner, the Attack Helicopter, Mammoth, General Harrow and his command vehicle through
     tools/prepare_sprite.py (--ink-l 0.15, the city ramps);
  2. figures: the Fallen Sergeant and her three skins (the figure redesign) through tools/pixelate_source.py first,
     then prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets through prepare_sprite.py --art-height 24, set on the frame of an
     approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host); the gold sheet came back with one extra
     copy of the reference badge, skipped ("");
  4. props: the minefield's mine, the spell's bone mine and the sandbag decal from props.png;
  5. strips: tools/walk_cycle.py walk strips (its rigs under "# --- Act VIII: Fort Kessler ---") and the Fallen
     Sergeant's idle strips.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/fort_kessler.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).
ARMY = "olive,asphalt,concrete,hazard,hero,skin,brown,siren_red,neon_cyan,gold"  # The army's ramps.

# Sprite key -> (raw source, art height, extra prepare_sprite arguments).
UNITS = {
    "city/machine_gunner": ("raw/machine_gunner.png", 40, ["--ramps", ARMY]),
    "city/attack_helicopter": ("raw/attack_helicopter.png", 40, ["--ramps", "olive,asphalt,concrete,neon_cyan,siren_red"]),
    "city/mammoth": ("raw/mammoth.png", 60, ["--ramps", "olive,asphalt,concrete,hazard,brown"]),
    "bosses/harrow": ("raw/harrow.png", 72, ["--ramps", ARMY]),
    "bosses/harrow_command": ("raw/harrow_command.png", 60, ["--ramps", ARMY + ",neon_sodium"]),
}
# The figure-redesign figures: key -> (raw source, art height, extra arguments).
FIGURES = {
    "player/fallen_sergeant": ("raw/fallen_sergeant.png", 56, ["--ramps", "olive,asphalt,grey,neon_cyan,bone,velvet"]),
    "player/fallen_sergeant_hyper": ("raw/fallen_sergeant_hyper.png", 56, ["--ramps", "gold,marble,grey,asphalt,neon_cyan,bone,velvet", "--no-levels"]),
    "player/fallen_sergeant_untouchable": ("raw/fallen_sergeant_untouchable.png", 56, ["--ramps", "marble,soul,grey,asphalt,velvet"]),
    "player/fallen_sergeant_deathlord": ("raw/fallen_sergeant_deathlord.png", 56, ["--ramps", "asphalt,crimson,grey,velvet,bone", "--no-levels"]),
}
# Icon sheets: file -> (badge frame, symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["bone_mines", "tripwire", "armour_piercing_bones"]),
    "icons_gold.png": ("icons/tidecallers_host", ["killing_ground", "ach_broken_arrow", ""]),
}
# Props (props.png, left to right) -> (sprite key, art height, ramps).
PROPS = [
    ("structures/kessler_mine", 9, "olive,asphalt,siren_red"),
    ("spells/bone_mine", 9, "bone,velvet,violet,asphalt"),
    ("decals/fk_sandbags", 16, "brown,bone,asphalt"),
]


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
    for key, (src, height, extra) in UNITS.items():
        keep = (HERE / src).read_bytes()
        run(["tools/prepare_sprite.py", str(HERE / src), key, "--ink-l", "0.15", "--no-prune", "--art-height", str(height)] + extra)
        (HERE / src).write_bytes(keep)
    # The helicopter hovers (walk_cycle.py "hover" bobs 2 px): 2 empty rows above and below its still (40 -> 44).
    p = ROOT / "assets/sprites/city/attack_helicopter.png"
    im = Image.open(p).convert("RGBA")
    if im.height == 40:
        out = Image.new("RGBA", (im.width, im.height + 4), (0, 0, 0, 0))
        out.alpha_composite(im, (0, 2))
        out.save(p)


def figures() -> None:
    for key, (src, height, extra) in FIGURES.items():
        pix = SCRATCH / (key.replace("/", "_") + ".png")
        run(["tools/pixelate_source.py", str(HERE / src), str(height), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--ink-l", "0.15", "--no-cleanup", "--art-height", str(height)] + extra)


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


def props() -> None:
    im = Image.open(HERE / "props.png").convert("RGBA")
    for (x0, x1), (key, height, ramps) in zip(islands(im, 0), PROPS):
        prop = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (key.replace("/", "_") + ".png")
        prop.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(height), "--ink-l", "0.2", "--ramps", ramps])


def strips() -> None:
    for key in ["city/machine_gunner", "city/attack_helicopter", "city/mammoth", "bosses/harrow", "bosses/harrow_command",
                "player/fallen_sergeant", "player/fallen_sergeant_hyper", "player/fallen_sergeant_untouchable",
                "player/fallen_sergeant_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/fallen_sergeant", "player/fallen_sergeant_hyper", "player/fallen_sergeant_untouchable",
                "player/fallen_sergeant_deathlord"]:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
