#!/usr/bin/env python3
"""make_art.py: rebuilds Pandemonium's art (Act VI, Stage 18) from its API sources.

Run from the repo root (python3 art_source/pandemonium/make_art.py [step ...]). Sources: the unit sprites are archived
under art_source/<key>.png (prompts in art_source/pandemonium/<id>.txt); the sheets (icons, props) live here and the
floor textures in art_source/tiles/. Steps:
  1. units: the Fallen Seraph General, the Morning Star (the Angel and the Beast), the Archfiend and the Prince of Hell
     through tools/prepare_sprite.py with explicit --ramps and --ink-l 0.15 (the Act VI ink);
  2. figures: the Fallen Angel and the Fallen Saint with her three skins (the figure redesign) through
     tools/pixelate_source.py first, then prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets (split by empty columns) through prepare_sprite.py --art-height 24,
     set on the frame of an approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host), its inner 26 px
     cleared to the frame's fill first;
  4. obstacles: each prop of the two prop sheets (split by empty gaps) converted at each size of
     PandemoniumStage.ZONES (circles: width = footprint + 4; rects: length + 2 wide, the end-on _v stretched to
     length + 14 tall);
  5. floors: tools/make_tile.py recipes pandemonium_* (sources art_source/tiles/pandemonium_obsidian / _ash);
  6. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act VI: Pandemonium ---").
Deterministic: a rerun from the same sources reproduces the files.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/pandemonium.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (source PNG relative to the repo root, extra prepare_sprite arguments).
UNITS = {
    "inferno/seraph_general": ("art_source/inferno/seraph_general.png", ["--ramps", "obsidian,gold,lava,skin,marble,crimson", "--ink-l", "0.15", "--no-levels"]),
    "bosses/morning_star": ("art_source/bosses/morning_star.png", ["--ramps", "obsidian,gold,lava,skin,marble", "--ink-l", "0.15", "--no-levels"]),
    "bosses/morning_star_beast": ("art_source/bosses/morning_star_beast.png", ["--ramps", "obsidian,bone,lava,gold,brown", "--ink-l", "0.15", "--no-levels"]),
    "summons/archfiend": ("art_source/summons/archfiend.png", ["--ramps", "grey,bone,soul,brown,violet", "--ink-l", "0.15"]),
    "summons/prince_of_hell": ("art_source/summons/prince_of_hell.png", ["--ramps", "grey,bone,soul,brown,violet", "--ink-l", "0.15"]),
}
# The figure-redesign figures: key -> (source, art height, extra arguments). --no-levels keeps the black bodysuit,
# the black gown and the skins' dark cloth dark (the levels stretch lightens them).
FIGURES = {
    "inferno/fallen_angel": ("art_source/inferno/fallen_angel.png", 60, ["--ramps", "obsidian,gold,skin,marble,lava,brown", "--no-levels"]),
    "player/fallen_saint": ("art_source/player/fallen_saint.png", 56, ["--ramps", "violet,gold,marble,skin,obsidian,brown", "--no-levels"]),
    "player/fallen_saint_hyper": ("art_source/player/fallen_saint_hyper.png", 56, ["--ramps", "gold,marble,violet,skin,brown", "--no-levels"]),
    "player/fallen_saint_untouchable": ("art_source/player/fallen_saint_untouchable.png", 56, ["--ramps", "marble,soul,grey,skin,brown"]),
    "player/fallen_saint_deathlord": ("art_source/player/fallen_saint_deathlord.png", 56, ["--ramps", "grey,crimson,skin,gold,brown", "--no-levels"]),
}
# Icon sheets: file -> (badge frame to set the symbols on, the symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["fall_from_grace", "pride", "archfiend", "crown_of_horns", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["lightbringer", "prince_of_hell", "ach_morning_star_falls", "", ""]),
}
# Round props (props_round.png, left to right) -> their footprint radii (px), smallest first (PandemoniumStage.ZONES).
ROUND = [("iron_brazier", [12, 15]), ("chain_post", [10, 12]), ("ash_column", [14, 18, 22]),
         ("burning_censer", [10, 12]), ("skull_pillar", [12, 15]), ("obsidian_shard", [12, 15, 18])]
# Long props (props_long.png: top row horizontal, bottom row end-on) -> (long sides, short side) (PandemoniumStage.ZONES).
LONG = [("iron_wall", [44, 60], 16), ("bridge_rail", [44, 60], 16), ("ash_pew", [44, 60], 16)]
# Size suffixes by the number of sizes (EnvironmentArtData.OBSTACLE_SIZE_SUFFIXES).
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
# Most height of a round prop as a multiple of its width (a slender crop would stand far above the units).
TALL_MAX = 2.6
# Ramps of the props (the converter prunes the ones a prop does not use).
PROP_RAMPS = "obsidian,lava,grey,bone,brown,gold"


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
    run(["tools/make_tile.py", "build", "pandemonium_iron", "pandemonium_bridges", "pandemonium_cathedral", "pandemonium_throne"])


def strips() -> None:
    for key in ["inferno/fallen_angel", "inferno/seraph_general", "bosses/morning_star", "bosses/morning_star_beast",
                "player/fallen_saint", "summons/archfiend", "summons/prince_of_hell"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/fallen_saint_hyper", "player/fallen_saint_untouchable", "player/fallen_saint_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["inferno/fallen_angel", "player/fallen_saint", "player/fallen_saint_hyper", "player/fallen_saint_untouchable",
                "player/fallen_saint_deathlord"]:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
