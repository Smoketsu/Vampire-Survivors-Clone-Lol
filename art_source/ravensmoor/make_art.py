#!/usr/bin/env python3
"""make_art.py: rebuilds Ravensmoor's art (Act VII, Stage 19; ART_BIBLE "Act VII: Ravensmoor") from its API sources.

Run from the repo root (python3 art_source/ravensmoor/make_art.py [step ...]). Raw API images in
art_source/ravensmoor/raw/ (prompts beside this file), the sheets (icons, props) here, the floor textures in
art_source/tiles/ravensmoor_heath.png and _flags.png. Steps (Pandemonium's recipe):
  1. units: the Ghoul, Old Greymane and Vargr through tools/prepare_sprite.py (--ink-l 0.15, the court ramps);
  2. figures: the Moon-Cursed Huntress and her three skins (the figure redesign) through tools/pixelate_source.py
     first, then prepare_sprite.py --no-cleanup (ART_BIBLE "Converting small figures");
  3. badges: each symbol of the two icon sheets through prepare_sprite.py --art-height 24, set on the frame of an
     approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host); each sheet came back with one extra
     copy of the reference badge, skipped ("");
  4. obstacles: the props of the two sheets converted at each size of RavensmoorStage.ZONES (circles: width =
     footprint x 2 + 4; rects: length + 2 wide, the end-on _v stretched to length + 14 tall); the long sheet's
     stray barrel is skipped;
  5. floors: tools/make_tile.py recipes ravensmoor_*;
  6. walk / idle strips: tools/walk_cycle.py (its rigs under "# --- Act VII: Ravensmoor ---").
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/ravensmoor.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).
RAMPS = "moonlight,blood,velvet,brown,skin,grey,gold"  # The court's ramps plus grey fur and brown cloth.

# Sprite key -> (raw source, extra prepare_sprite arguments).
UNITS = {
    "court/ghoul": ("raw/ghoul.png", ["--ramps", "grey,moonlight,blood,brown", "--ink-l", "0.15"]),
    "court/old_greymane": ("raw/old_greymane.png", ["--ramps", "grey,moonlight,brown,velvet,blood,gold", "--ink-l", "0.15"]),
    "bosses/vargr": ("raw/vargr.png", ["--ramps", "grey,moonlight,blood,velvet,gold", "--ink-l", "0.15"]),
}
# The figure-redesign figures: key -> (raw source, art height, extra arguments).
FIGURES = {
    "player/moon_huntress": ("raw/moon_huntress.png", 56, ["--ramps", "moonlight,velvet,skin,brown,blood"]),  # No gold: her pale face snapped to it; the levels stretch lifts her dark coat (art_check lightness).
    "player/moon_huntress_hyper": ("raw/moon_huntress_hyper.png", 56, ["--ramps", "gold,marble,skin,brown,moonlight", "--no-levels"]),
    "player/moon_huntress_untouchable": ("raw/moon_huntress_untouchable.png", 56, ["--ramps", "marble,soul,grey,skin"]),
    "player/moon_huntress_deathlord": ("raw/moon_huntress_deathlord.png", 56, ["--ramps", "velvet,grey,crimson,skin,moonlight", "--no-levels"]),  # Round 1 redo (act 7): velvet keeps the coat black against the silver hair.
}
# Icon sheets: file -> (badge frame, symbol ids left to right; "" = skip).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["moonfang", "pack_blood", "silver_bones", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["wolf_of_the_red_moon", "ach_coffin_nails", ""]),
}
# Round props (props_round.png, left to right) -> footprint radii (px), smallest first.
ROUND = [("moor_cairn", [12, 16, 20]), ("grave_cross", [10, 13]), ("moor_pine", [14, 18])]
# Long props (props_long.png: top row horizontal, bottom row end-on) -> (lengths, short side).
LONG = [("village_fence", [44, 56], 12), ("thatch_cottage", [56, 72], 30), ("church_ruin", [56, 72], 18)]
SUFFIXES = {2: ["s", "l"], 3: ["s", "m", "l"]}
TALL_MAX = 2.6  # Most height of a round prop as a multiple of its width.
PROP_RAMPS = "grey,moonlight,brown,velvet,gold,soul,blood"


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
        keep = (HERE / src).read_bytes()
        run(["tools/prepare_sprite.py", str(HERE / src), key] + extra)
        (HERE / src).write_bytes(keep)


# Figures lifted before conversion (brighten.py factor): the Huntress's dark coat failed art_check's lightness rule.
LIFT = {"player/moon_huntress": 1.35}


def figures() -> None:
    for key, (src, height, extra) in FIGURES.items():
        pix = SCRATCH / (key.replace("/", "_") + ".png")
        source = HERE / src
        if key in LIFT:
            lit = SCRATCH / (key.replace("/", "_") + "_lit.png")
            run([str(HERE / "brighten.py"), str(source), str(lit), str(LIFT[key])])
            source = lit
        run(["tools/pixelate_source.py", str(source), str(height), str(pix)])
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
    im = Image.open(HERE / "props_round.png").convert("RGBA")
    for (x0, x1), (kind, radii) in zip(islands(im, 0), ROUND):
        prop = crop_tight(im.crop((x0, 0, x1, im.height)))
        p = SCRATCH / (kind + ".png")
        prop.save(p)
        for r, suf in zip(radii, SUFFIXES[len(radii)]):
            w = 2 * r + 4
            h = max(8, min(round(w * prop.height / prop.width), round(w * TALL_MAX)))
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
            th = ln + 14
            tw = short + 10
            st = prop.resize((tw * 8, th * 8), Image.LANCZOS)
            p = SCRATCH / ("%s_v_%s.png" % (kind, suf))
            st.save(p)
            run(["tools/prepare_sprite.py", str(p), "obstacles/%s_%s_v" % (kind, suf), "--art-height", str(th), "--ink-l", "0.2", "--ramps", PROP_RAMPS])


def floors() -> None:
    run(["tools/make_tile.py", "build", "ravensmoor_moor", "ravensmoor_village", "ravensmoor_old_church", "ravensmoor_wolfwood"])


def strips() -> None:
    for key in ["court/ghoul", "court/old_greymane", "bosses/vargr", "player/moon_huntress", "player/moon_huntress_hyper",
                "player/moon_huntress_untouchable", "player/moon_huntress_deathlord"]:
        run(["tools/walk_cycle.py", "build", key])
    for key in ["player/moon_huntress", "player/moon_huntress_hyper", "player/moon_huntress_untouchable", "player/moon_huntress_deathlord"]:
        run(["tools/walk_cycle.py", "idle", key])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "badges", "props", "floors", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
