#!/usr/bin/env python3
"""make_art.py: rebuilds Castle Sanguis's art (Act VII, Stage 21) from its API sources.

Run from the repo root (python3 art_source/castle_sanguis/make_art.py [step ...]). Sources: the unit sprites are archived
under art_source/<key>.png (prompts in art_source/castle_sanguis/<id>.txt); the sheets (icons, props) live here and the
floor textures in art_source/tiles/. Steps:
  1. units: the Chiropteran, the Chiropteran King, the Elder, the Dhampir and his three skins, the Blood Spawn, Nosferatu
     and the structures (blood fountain, the Elder's coffin closed and open) through tools/prepare_sprite.py with explicit
     --ramps and --ink-l 0.15;
  2. figures: Queen Carmilla (the figure style) through tools/pixelate_source.py first, then prepare_sprite.py
     --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets (split by empty columns) through prepare_sprite.py --art-height 24,
     set on the frame of an approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host), its inner 26 px
     cleared to the frame's fill first;
  4. obstacles: each prop of the two prop sheets (split by empty gaps) converted at each size of
     CastleSanguisStage.ZONES (circles: width = footprint + 4; rects: length + 2 wide, the end-on _v stretched to
     length + 14 tall);
  5. floors: tools/make_tile.py recipes castle_sanguis_* (sources art_source/tiles/castle_sanguis_stone / _marble);
  6. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act VII: Castle Sanguis ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/castle_sanguis.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments).
UNITS = {
    "court/chiropteran": ("art_source/court/chiropteran.png", ["--ramps", "moonlight,velvet,blood,brown,bone", "--ink-l", "0.15"]),
    "court/chiropteran_king": ("art_source/court/chiropteran_king.png", ["--ramps", "moonlight,velvet,blood,brown,bone", "--ink-l", "0.15"]),
    "bosses/elder": ("art_source/bosses/elder.png", ["--ramps", "moonlight,blood,velvet,bone", "--ink-l", "0.15"]),
    "player/dhampir": ("art_source/player/dhampir.png", ["--ramps", "velvet,blood,moonlight,soul,skin", "--ink-l", "0.15", "--no-levels"]),
    "player/dhampir_hyper": ("art_source/player/dhampir_hyper.png", ["--ramps", "gold,marble,velvet,skin,moonlight", "--ink-l", "0.15", "--no-levels"]),
    "player/dhampir_untouchable": ("art_source/player/dhampir_untouchable.png", ["--ramps", "marble,soul,grey,skin", "--ink-l", "0.15"]),
    "player/dhampir_deathlord": ("art_source/player/dhampir_deathlord.png", ["--ramps", "grey,crimson,skin,moonlight", "--ink-l", "0.15", "--no-levels"]),
    "summons/blood_spawn": ("art_source/summons/blood_spawn.png", ["--ramps", "grey,bone,soul,blood", "--ink-l", "0.15"]),
    "summons/nosferatu": ("art_source/summons/nosferatu.png", ["--ramps", "grey,bone,soul,blood", "--ink-l", "0.15"]),
    "structures/blood_fountain": ("art_source/structures/blood_fountain.png", ["--ramps", "grey,blood,gold", "--ink-l", "0.15"]),
    "structures/elder_coffin": ("art_source/structures/elder_coffin.png", ["--ramps", "velvet,blood,moonlight,bone,gold", "--ink-l", "0.15", "--no-levels"]),
    "structures/elder_coffin_open": ("art_source/structures/elder_coffin_open.png", ["--ramps", "velvet,blood,moonlight,bone,gold", "--ink-l", "0.15", "--no-levels"]),
}
# The figure-redesign figures: key -> (source, art height, extra arguments). --no-levels keeps the black velvet dark.
FIGURES = {
    "bosses/carmilla": ("art_source/bosses/carmilla.png", 64, ["--ramps", "velvet,blood,gold,moonlight,skin", "--no-levels"]),
}
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["night_swarm", "old_blood", "blood_spawn", "thirst_eternal", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["nocturne", "nosferatu", "ach_last_supper", "", ""]),
}
# Round props (props_round.png, left to right) -> their footprint radii (px), smallest first (CastleSanguisStage.ZONES).
ROUND = [("castle_well", [14, 18]), ("gargoyle_statue", [12, 15]), ("candelabra", [10, 12]),
         ("wine_barrel", [10, 12]), ("crypt_pillar", [14, 18, 22]), ("blood_urn", [10, 12])]
# Long props (props_long.png: top row horizontal, bottom row end-on) -> (long sides, short side) (CastleSanguisStage.ZONES).
LONG = [("castle_wall", [44, 60], 16), ("feast_table", [44, 60], 16), ("sarcophagus", [44, 60], 16)]
# Size suffixes by the number of sizes (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES).
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
# Most height of a round prop as a multiple of its width (a slender crop would stand far above the units).
TALL_MAX = 2.6
# Ramps of the props (the converter prunes the ones a prop does not use).
PROP_RAMPS = "grey,blood,velvet,gold,brown,bone"


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


def props() -> None:
    im = Image.open(HERE / "props_round.png").convert("RGBA")
    for (x0, x1), (kind, radii) in zip(islands(im, 0), ROUND):
        prop = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (kind + ".png")
        prop.save(p)
        for r, suf in zip(radii, SUFFIXES[len(radii)]):
            w = 2 * r + 4  # Art px wide: the footprint plus 4.
            h = max(8, min(round(w * prop.height / prop.width), round(w * TALL_MAX)))  # A slender crop is capped.
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
    run(["tools/make_tile.py", "build", "castle_sanguis_courtyard", "castle_sanguis_banquet", "castle_sanguis_crypt", "castle_sanguis_throne"])


def strips() -> None:
    for key in ["court/chiropteran", "court/chiropteran_king", "bosses/carmilla", "bosses/elder", "player/dhampir",
                "summons/blood_spawn", "summons/nosferatu"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/dhampir_hyper", "player/dhampir_untouchable", "player/dhampir_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    run(["tools/walk_cycle.py", "idle", "bosses/carmilla"])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
