#!/usr/bin/env python3
"""make_art.py: rebuilds the Proving Moon's art (Act IX, Stage 26; ART_BIBLE "Act IX: the Proving Moon") from its API sources.

Run from the repo root (python3 art_source/proving_moon/make_art.py [step ...]). Raw API images in
art_source/proving_moon/raw/ (prompts beside this file; raw/blooded_a_unused.png is the first Blooded try, kept for the
record), the floor textures in art_source/tiles/proving_moon_regolith.png and _hall.png, references in refs/.
Steps (Ravensmoor's and Fort Kessler's recipe):
  1. units: the Warbeast and Vrask'Tal through tools/prepare_sprite.py (--ink-l 0.15, the concord ramps);
  2. figures: the Blooded and her three skins (the figure redesign) through tools/pixelate_source.py first, then
     prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets through prepare_sprite.py --art-height 24, set on the frame of an
     approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host); each sheet came back with one extra
     symbol (a copy of the reference badge), skipped ("");
  4. obstacles: the props of the two sheets converted at each size of ProvingMoonStage (circles: width = footprint x 2
     + 4; rects: length + 2 wide, the end-on _v stretched to length + 14 tall); the round sheet's third prop (a spire of
     rock the prompt did not ask for) is skipped;
  5. decals: the three floor marks of decals.png (a crater for the Landing and the Craters, fallen trophies for the
     Trophy Hall, a duelling mark for the Duelling Ring);
  6. floors: tools/make_tile.py recipes proving_moon_*;
  7. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act IX: the Proving Moon ---").
"""
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/proving_moon.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).
VRASK = "vrask,gunmetal,hull,laser,lumen"  # The Vrask's ramps: teal scales, dark armour, pale blades, the magenta lamps.

# Sprite key -> (raw source, art height, extra prepare_sprite arguments).
UNITS = {
    "concord/warbeast": ("raw/warbeast.png", 44, ["--ramps", VRASK]),
    "bosses/vrask_tal": ("raw/vrask_tal.png", 84, ["--ramps", VRASK + ",hive_bone"]),
}
# The figure-redesign figures: key -> (raw source, art height, extra arguments).
FIGURES = {
    "player/blooded": ("raw/blooded.png", 56, ["--ramps", "brown,skin,grey,soul,bone,blood,vrask,gold"]),  # art_check lightness +0.14 on the Graveyard soil (need +0.15): the brown ramp has two shades; brightening the source does not move it.
    "player/blooded_hyper": ("raw/blooded_hyper.png", 56, ["--ramps", "gold,marble,grey,soul,blood,bone", "--no-levels"]),
    "player/blooded_untouchable": ("raw/blooded_untouchable.png", 56, ["--ramps", "marble,soul,grey,asphalt"]),
    "player/blooded_deathlord": ("raw/blooded_deathlord.png", 56, ["--ramps", "asphalt,crimson,grey,blood,bone", "--no-levels"]),
}
# Icon sheets: file -> (badge frame, symbol ids left to right; "" = skip).
ICONS = {
    "raw/icons_violet.png": ("icons/abyssal_pact", ["soul_caster", "trophy_rack", "mirror_bones", ""]),
    "raw/icons_gold.png": ("icons/tidecallers_host", ["apex_predator", "ach_the_hunter_hunted", ""]),
}
# Round props (raw/props_round.png, left to right) -> footprint radii (px), smallest first ("" = skip).
ROUND = [("moon_boulder", [12, 18, 24]), ("crater_rim", [22, 30, 38]), ("", [])]
# Long props (raw/props_long.png: top row horizontal, bottom row end-on) -> (lengths, short side).
LONG = [("trophy_pillar", [40, 56], 14)]
# Floor decals (raw/decals.png, left to right) -> ([decal keys], art width, ramps).
DECALS = [
    (["decals/proving_moon_landing_crater", "decals/proving_moon_craters_crater"], 22, "asphalt,grey"),
    (["decals/proving_moon_trophy_hall_skulls"], 26, "hive_bone,asphalt,grey"),
    (["decals/proving_moon_duelling_ring_ring"], 40, "vrask,asphalt"),
]
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
TALL_MAX = 2.6  # Most height of a round prop as a multiple of its width.
PROP_RAMPS = "grey,asphalt,concrete,vrask,gunmetal,hive_bone"


def run(args: list) -> None:
    """Runs a repo tool, failing loudly."""
    print("+", " ".join(args))
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def islands(im: Image.Image, axis: int, min_gap: int = 12) -> list:
    """Spans [a, b) of opaque columns (axis 0) or rows (axis 1) separated by >= min_gap empty ones."""
    a = im.getchannel("A").point(lambda v: 255 if v > 128 else 0)
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
    a = im.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    return im.crop(a.getbbox())


def units() -> None:
    for key, (src, height, extra) in UNITS.items():
        keep = (HERE / src).read_bytes()
        run(["tools/prepare_sprite.py", str(HERE / src), key, "--ink-l", "0.15", "--no-prune", "--art-height", str(height)] + extra)
        (HERE / src).write_bytes(keep)


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
    im = Image.open(HERE / "raw/props_round.png").convert("RGBA")
    for (x0, x1), (kind, radii) in zip(islands(im, 0), ROUND):
        if kind == "":
            continue
        prop = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (kind + ".png")
        prop.save(p)
        for r, suf in zip(radii, SUFFIXES[len(radii)]):
            w = 2 * r + 4
            h = max(8, min(round(w * prop.height / prop.width), round(w * TALL_MAX)))
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s" % (kind, suf), "--art-height", str(h), "--ink-l", "0.2", "--ramps", PROP_RAMPS])
    im = Image.open(HERE / "raw/props_long.png").convert("RGBA")
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
            th = ln + 14
            tw = short + 10
            st = prop.resize((tw * 8, th * 8), Image.LANCZOS)
            p = SCRATCH / ("%s_v_%s.png" % (kind, suf))
            st.save(p)
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s_v" % (kind, suf), "--art-height", str(th), "--ink-l", "0.2", "--ramps", PROP_RAMPS])


def decals() -> None:
    im = Image.open(HERE / "raw/decals.png").convert("RGBA")
    for (x0, x1), (keys, width, ramps) in zip(islands(im, 0, min_gap=20), DECALS):
        mark = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (keys[0].replace("/", "_") + ".png")
        mark.save(p)
        h = max(6, round(width * mark.height / mark.width))
        run(["tools/prepare_sprite.py", str(p), keys[0], "--art-height", str(h), "--ink-l", "0.12", "--ramps", ramps])
        for k in keys[1:]:
            shutil.copyfile(ROOT / "assets/sprites" / (keys[0] + ".png"), ROOT / "assets/sprites" / (k + ".png"))


def floors() -> None:
    run(["tools/make_tile.py", "build", "proving_moon_landing", "proving_moon_craters", "proving_moon_trophy_hall",
         "proving_moon_duelling_ring"])


def strips() -> None:
    for key in ["concord/warbeast", "bosses/vrask_tal", "player/blooded", "player/blooded_hyper", "player/blooded_untouchable",
                "player/blooded_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/blooded", "player/blooded_hyper", "player/blooded_untouchable", "player/blooded_deathlord"]:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "decals", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
