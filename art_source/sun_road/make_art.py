#!/usr/bin/env python3
"""make_art.py: rebuilds the Road to the Sun's art (Act V, Stage 15) from its API sources.

Run from the repo root (python3 art_source/sun_road/make_art.py). Sources: the unit sprites are archived by
tools/prepare_sprite.py under art_source/<key>.png; the sheets (icons, props) and the textures live here and in
art_source/tiles/. Steps:
  1. units, bosses, characters and skins: tools/prepare_sprite.py with explicit --ramps and --ink-l 0.22;
  2. badges: each symbol of the two icon sheets (split by empty columns) through prepare_sprite.py --art-height 24,
     set on the frame of an approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host), its inner
     26 px cleared to the frame's fill first;
  3. obstacles: each prop of the two prop sheets (split by empty gaps) converted at each size of
     SunRoadStage.ZONES (circles: width = footprint + 4; rects: length + 2 wide, the end-on _v stretched to
     length + 14 tall);
  4. floors: tools/make_tile.py recipes sun_road_* (sources art_source/tiles/sun_road_earth / _stone);
  5. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act V: the Road to the Sun ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/sun_road.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments).
UNITS = {

    "shogunate/sohei": ("art_source/shogunate/sohei.png", ["--ramps", "indigo,lacquer,marble,grey,gold,skin,brown", "--ink-l", "0.22"]),
    "shogunate/kirin": ("art_source/shogunate/kirin.png", ["--ramps", "gold,marble,bone,brown,sakura", "--ink-l", "0.22"]),
    "bosses/amaterasu": ("art_source/bosses/amaterasu.png", ["--ramps", "marble,gold,lacquer,indigo,skin", "--ink-l", "0.22", "--no-levels"]),  # Round 1 redo: --no-levels keeps her black hair dark.
    "bosses/amaterasu_mirror": ("art_source/bosses/amaterasu_mirror.png", ["--ramps", "marble,gold,lacquer,indigo,skin", "--ink-l", "0.22", "--no-levels"]),
    "summons/bound_oni": ("art_source/summons/bound_oni.png", ["--ramps", "grey,crimson,bone,gold,soul,brown", "--ink-l", "0.22"]),
    "summons/oni_lord": ("art_source/summons/oni_lord.png", ["--ramps", "grey,crimson,bone,gold,soul,brown", "--ink-l", "0.22"]),
}
# The figure-redesign figures (ART_BIBLE "Converting small figures"): tools/pixelate_source.py puts the source on
# the art grid first, then prepare_sprite.py --ink-l 0.15 --no-cleanup (the Ferrywoman's pipeline; without it the
# faces and necklines melted). Key -> (source, art height, extra arguments: --no-levels keeps the night maiden's black
# hair and robes dark (the levels stretch turned them a bright indigo, or brown without the indigo ramp); the base
# maiden and the Deathlord skin then sit +0.14 over the darkest floors, 0.01 under art_check's +0.15: for review).
FIGURES = {
    "shogunate/kitsune": ("art_source/shogunate/kitsune.png", 52, ["--ramps", "marble,lacquer,sakura,skin,aegean,gold"]),
    "player/shrine_maiden": ("art_source/player/shrine_maiden.png", 56, ["--ramps", "violet,marble,indigo,bone,lacquer,brown", "--no-levels"]),
    "player/shrine_maiden_hyper": ("art_source/player/shrine_maiden_hyper.png", 56, ["--ramps", "gold,marble,indigo,bone,violet,brown", "--no-levels"]),
    "player/shrine_maiden_untouchable": ("art_source/player/shrine_maiden_untouchable.png", 56, ["--ramps", "marble,soul,grey,bone,brown"]),
    "player/shrine_maiden_deathlord": ("art_source/player/shrine_maiden_deathlord.png", 58, ["--ramps", "grey,crimson,bone,brown", "--no-levels"]),
}
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["black_sun", "stolen_dawn", "bound_oni", "onis_resolve"]),
    "icons_gold.png": ("icons/tidecallers_host", ["eclipse_of_heaven", "oni_lord", "ach_the_sun_goes_out", ""]),
}
# Round props (props_round.png, left to right) -> their footprint radii (px), smallest first (SunRoadStage.ZONES).
ROUND = [("torii_post", [9, 11]), ("sacred_cedar", [14, 18, 22]), ("moss_rock", [11, 14]),
         ("komainu", [12, 14]), ("cloud_rock", [14, 18, 22]), ("sun_mirror", [11, 13])]
# Long props (props_long.png: top row horizontal, bottom row end-on) -> (long sides, short side) (SunRoadStage.ZONES).
LONG = [("stone_marker", [30, 40], 16), ("step_wall", [44, 60], 16)]
# Size suffixes by the number of sizes (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES).
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
# Most height of a round prop as a multiple of its width (a slender crop would stand far above the units).
TALL_MAX = 2.6
# Ramps of the props (the converter prunes the ones a prop does not use).
PROP_RAMPS = "lacquer,grey,marble,brown,moss,gold,sakura"


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
        run(["tools/prepare_sprite.py", str(pix), key, "--ink-l", "0.15", "--no-cleanup"] + extra)
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
    run(["tools/make_tile.py", "build", "sun_road_torii", "sun_road_forest", "sun_road_steps", "sun_road_heaven"])


def strips() -> None:
    for key in ["shogunate/kitsune", "shogunate/sohei", "shogunate/kirin", "bosses/amaterasu", "player/shrine_maiden",
                "summons/bound_oni", "summons/oni_lord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/shrine_maiden_hyper", "player/shrine_maiden_untouchable", "player/shrine_maiden_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["shogunate/kitsune", "bosses/amaterasu", "player/shrine_maiden", "player/shrine_maiden_hyper", "player/shrine_maiden_untouchable",
                "player/shrine_maiden_deathlord"]:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
