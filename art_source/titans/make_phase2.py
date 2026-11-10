#!/usr/bin/env python3
"""make_phase2.py: builds the Age of Titans' phase 2 sprites from art_source/titans/raw (gen_phase2.py) the way make_art.py does: every figure through
tools/pixelate_source.py then tools/prepare_sprite.py (primeval_ ramps for beasts, violet / bone / soul for the characters, bone / soul for the Bonehorn
family), the art height chosen so the width fits the manifest box; poses reuse their base's height (same scale); the Bog Croc's submerged still and the
nest's `_dead` still are drawn / derived here; then the obstacle and icon sheets. Usage (repo root): python3 art_source/titans/make_phase2.py [units] [stills]
[props] [strips]. Strips use the rigs in tools/walk_cycle.py ("Act XIV slot, phase 2")."""
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/titans.
sys.path.insert(0, str(HERE))
BEAST = "primeval_fern,primeval_ochre,primeval_tar,primeval_lava,primeval_bone"  # Beast ramps.
CHAR = "violet,bone,soul,brown,grey"  # Necromancer ramps.
BONE = "bone,soul"  # Skeleton ramps.
# raw id -> (sprite key, max art width, max art height, ramps, base raw whose art height a pose reuses)
U = [("bog_croc", "primeval/bog_croc", 72, 30, BEAST, None), ("ironjaw", "primeval/ironjaw", 80, 60, BEAST, None),
     ("primeval_nest", "primeval/primeval_nest", 48, 32, BEAST, None), ("scarmaw_guard", "primeval/scarmaw_guard", 44, 40, BEAST, None),
     ("scarmaw", "primeval/scarmaw", 72, 60, BEAST, None), ("scarmaw_leap", "primeval/scarmaw_leap", 72, 60, BEAST, "scarmaw"),
     ("horncharger", "primeval/horncharger", 64, 48, BEAST, None), ("clubtail", "primeval/clubtail", 64, 44, BEAST, None),
     ("mother_clubtail", "primeval/mother_clubtail", 88, 60, BEAST, None), ("ironbrow", "primeval/ironbrow", 112, 80, BEAST, None),
     ("ironbrow_broken", "primeval/ironbrow_broken", 112, 80, BEAST, "ironbrow"), ("stormwing", "primeval/stormwing", 72, 44, BEAST, None),
     ("stormwing_landed", "primeval/stormwing_landed", 72, 44, BEAST, "stormwing"), ("thunderwing", "primeval/thunderwing", 112, 64, BEAST, None),
     ("gravejaw", "primeval/gravejaw", 128, 104, BEAST, None), ("gravejaw_roar", "primeval/gravejaw_roar", 128, 104, BEAST, "gravejaw"),
     ("fern_huntress", "player/fern_huntress", 40, 56, CHAR, None), ("herd_warden", "player/herd_warden", 42, 56, CHAR, None),
     ("skywatcher", "player/skywatcher", 38, 56, CHAR, None), ("bonehorn", "summons/bonehorn", 40, 34, BONE, None),
     ("fossil_tyrant", "summons/fossil_tyrant", 52, 44, BONE, None), ("fossil_giant", "summons/fossil_giant", 52, 48, BONE, None)]
WALK = ["primeval/bog_croc", "primeval/ironjaw", "primeval/scarmaw_guard", "primeval/scarmaw", "primeval/horncharger", "primeval/clubtail",
        "primeval/mother_clubtail", "primeval/ironbrow", "primeval/stormwing", "primeval/thunderwing", "primeval/gravejaw", "player/fern_huntress",
        "player/herd_warden", "player/skywatcher", "summons/bonehorn", "summons/fossil_tyrant", "summons/fossil_giant"]  # Walk / fly strips.
IDLE = ["player/fern_huntress", "player/skywatcher"]  # Bust rigs: 24-frame idle strips.


def run(a: list) -> None:
    print("+", " ".join(a), flush=True)
    subprocess.run([sys.executable] + a, cwd=ROOT, check=True)


def fit_height(src: Path, mw: int, mh: int) -> int:
    im = Image.open(src).convert("RGBA")
    bb = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    return min(mh, int((mw - 2) / ((bb[2] - bb[0]) / (bb[3] - bb[1]))) + 2)


def units(only: list = None) -> None:
    heights = {}
    for raw, key, mw, mh, ramps, base in U:
        if only and raw not in only:
            continue
        src = HERE / "raw" / (raw + ".png")
        h = heights[base] if base in heights else fit_height(src, mw, mh)
        heights[raw] = h
        pix = HERE / "_work" / (raw + ".png")
        pix.parent.mkdir(exist_ok=True)
        run(["tools/pixelate_source.py", str(src), str(h), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", ramps, "--no-prune", "--no-levels", "--no-cleanup"])
        (HERE / (raw + ".png")).unlink(missing_ok=True)


def stills() -> None:
    """The Bog Croc's submerged still (eyes and a ripple over tar, 32 x 12) and the nest's dead still (the live nest, ash-grey and scorched)."""
    out = ROOT / "assets/sprites/primeval"
    ink, tar, tar2, ripple, eye, glint = (18, 15, 13, 255), (35, 28, 24, 255), (74, 58, 48, 255), (110, 90, 76, 255), (239, 107, 28, 255), (255, 192, 112, 255)
    im = Image.new("RGBA", (32, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((1, 3, 30, 10), fill=tar, outline=ink)  # The dark pool patch.
    d.arc((4, 5, 27, 9), 200, 340, fill=tar2)
    for x in (9, 21):  # Two eyes just above the tar, an orange glint each.
        d.rectangle((x, 2, x + 2, 4), fill=ink)
        im.putpixel((x + 1, 3), eye)
    im.putpixel((10, 3), glint)
    im.putpixel((22, 3), glint)
    for x, y in ((5, 8), (15, 9), (26, 8)):  # Ripple ticks.
        d.line((x, y, x + 3, y), fill=ripple)
    im.save(out / "bog_croc_submerged.png")
    nest = Image.open(out / "primeval_nest.png").convert("RGBA")
    px = nest.load()
    for y in range(nest.height):
        for x in range(nest.width):
            r, g, b, a = px[x, y]
            if a:
                v = round(0.3 * r + 0.5 * g + 0.2 * b)
                v = int(v * 0.55)
                px[x, y] = (v + 6, v + 3, v, a) if (x * 7 + y * 3) % 11 else (18, 15, 13, a)  # Scorched: dark grey-brown with soot specks.
    nest.save(out / "primeval_nest_dead.png")


def props() -> None:
    sys.argv = ["make_props.py"]
    import make_props as mp
    mp.SCRATCH.mkdir(exist_ok=True)
    im = Image.open(HERE / "sheet_obstacles2.png").convert("RGBA")
    spans = mp.islands(im, 10)
    assert len(spans) >= 3, spans
    for (x0, x1), (key, w, mh) in zip(spans[:3], [("obstacles/primeval_tree_fern_m", 40, 48), ("obstacles/primeval_canyon_wall_m", 96, 32), ("obstacles/primeval_lava_rock_m", 40, 40)]):
        part = mp.crop_tight(im.crop((x0, 0, x1, im.height)))
        h = max(6, min(mh - 2, round((w - 2) * part.height / part.width)))
        p = mp.SCRATCH / (key.replace("/", "_") + ".png")
        part.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", BEAST])
        if "canyon" in key:
            out = ROOT / "assets/sprites" / (key + ".png")
            wall = Image.open(out).convert("RGBA")
            wall = wall.resize((96, wall.height), Image.NEAREST) if wall.width < 96 else wall  # The art is narrower than the 96 px wall box: stretch it to fit.
            wall.save(out)
            wall.rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))
    sheet = Image.open(HERE / "sheet_icon_horns.png").convert("RGBA")
    sym = mp.crop_tight(sheet.crop((mp.islands(sheet, 16)[0][0], 0, mp.islands(sheet, 16)[0][1], sheet.height)))
    p = mp.SCRATCH / "petrified_horns.png"
    sym.save(p)
    o24 = mp.SCRATCH / "petrified_horns_24.png"
    run(["tools/prepare_sprite.py", str(p), "icons/petrified_horns", "--art-height", "24", "--ink-l", "0.2", "--ramps", mp.ICON_RAMPS, "--out", str(o24)])
    frame = Image.open(ROOT / "assets/sprites/icons/pack_instinct.png").convert("RGBA")  # A violet badge frame of this act.
    fill = frame.getpixel((4, 16))
    for y in range(3, 29):
        for x in range(3, 29):
            frame.putpixel((x, y), fill)
    s = Image.open(o24).convert("RGBA")
    if s.width > 26:
        s = s.resize((26, round(s.height * 26 / s.width)), Image.NEAREST)
    frame.alpha_composite(s, ((32 - s.width) // 2, (32 - s.height) // 2))
    frame.save(ROOT / "assets/sprites/icons/petrified_horns.png")
    for f in mp.SCRATCH.glob("*"):
        f.unlink()
    mp.SCRATCH.rmdir()


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + WALK)
    run(["tools/walk_cycle.py", "idle"] + IDLE)


if __name__ == "__main__":
    for s in sys.argv[1:] or ["units", "stills", "props", "strips"]:
        if s.startswith("units:"):
            units(s.split(":")[1].split(","))
        else:
            globals()[s]()
