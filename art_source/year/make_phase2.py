#!/usr/bin/env python3
"""make_phase2.py: builds the Turning Year's phase 2 sprites from art_source/year/raw (gen_phase2.py) the way make_art.py does: every figure through
tools/pixelate_source.py then tools/prepare_sprite.py (wild_ ramps for creatures, violet / bone / soul for the characters, bone / soul for the oaks), the art
height chosen so the width fits the manifest box; poses reuse their base's height (same scale); then the obstacle and icon sheets and the strips (rigs in
tools/walk_cycle.py "Act XV slot, phase 2"). Usage (repo root): python3 art_source/year/make_phase2.py [units|units:id,id|props|strips]."""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
sys.path.insert(0, str(HERE))
WILD = "wild_moss,wild_bark,wild_blossom,wild_leaf,wild_frost,wild_blight,wild_fire,skin"  # Creature ramps.
CHAR = "violet,bone,soul,brown,grey"  # Necromancer ramps.
BONE = "bone,soul,wild_moss,wild_bark"  # Bone-tree ramps.
# raw id -> (sprite key, max art width, max art height, ramps, base raw whose art height a pose reuses)
U = [("hunt_hound", "wild/hunt_hound", 40, 28, WILD, None), ("huntsman", "wild/huntsman", 80, 68, WILD, None),
     ("antler_thicket", "wild/antler_thicket", 28, 28, WILD, None), ("stag_king", "wild/stag_king", 72, 88, WILD, None),
     ("stag_king_horn", "wild/stag_king_horn", 72, 88, WILD, "stag_king"), ("winter_prince", "wild/winter_prince", 40, 56, WILD, None),
     ("masked_courtier", "wild/masked_courtier", 32, 52, WILD, None), ("summer_queen", "wild/summer_queen", 64, 80, WILD, None),
     ("summer_queen_mask", "wild/summer_queen_mask", 64, 80, WILD, "summer_queen"), ("summer_queen_bargain", "wild/summer_queen_bargain", 64, 80, WILD, "summer_queen"),
     ("gardener_of_roots", "wild/gardener_of_roots", 80, 88, WILD, None), ("green_mother", "wild/green_mother", 128, 144, WILD, None),
     ("green_mother_cast", "wild/green_mother_cast", 128, 144, WILD, "green_mother"), ("green_mother_burial", "wild/green_mother_burial", 128, 144, WILD, "green_mother"),
     ("horned_herald", "player/horned_herald", 42, 56, CHAR, None), ("changeling_princess", "player/changeling_princess", 38, 56, CHAR, None),
     ("gravegardener", "player/gravegardener", 40, 56, CHAR, None), ("ossuary_oak", "summons/ossuary_oak", 48, 56, BONE, None),
     ("world_root_warden", "summons/world_root_warden", 56, 64, BONE, None)]
WALK = ["wild/hunt_hound", "wild/huntsman", "wild/stag_king", "wild/winter_prince", "wild/masked_courtier", "wild/summer_queen", "wild/gardener_of_roots",
        "wild/green_mother", "player/horned_herald", "player/changeling_princess", "player/gravegardener", "summons/ossuary_oak", "summons/world_root_warden"]  # Walk strips.
IDLE = ["wild/masked_courtier", "wild/summer_queen", "wild/green_mother", "player/changeling_princess", "player/gravegardener"]  # Bust rigs: idle strips.


FORCE = {"masked_courtier": 52}  # Raw ids whose art height is forced to the SpriteData height (her thorn rapier makes the width fit give 46; the width then runs to ~43 px).


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
        src = HERE / "raw" / (raw + ".png")
        h = heights[base] if base in heights else FORCE.get(raw) or fit_height(src, mw, mh)
        heights[raw] = h
        if only and raw not in only:
            continue
        pix = HERE / "_work" / (raw + ".png")
        pix.parent.mkdir(exist_ok=True)
        run(["tools/pixelate_source.py", str(src), str(h), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", ramps, "--no-prune", "--no-levels", "--no-cleanup"])
        (ROOT / "art_source/wild" / (raw + ".png")).unlink(missing_ok=True)
        (HERE / (raw + ".png")).unlink(missing_ok=True)


def props() -> None:
    sys.argv = ["make_props.py"]
    import make_props as mp
    mp.SCRATCH.mkdir(exist_ok=True)
    im = Image.open(HERE / "sheet_obstacles2.png").convert("RGBA")
    spans = mp.islands(im, 10)
    assert len(spans) >= 3, spans
    for (x0, x1), (key, w, mh) in zip(spans[:3], [("obstacles/wild_grove_tree", 40, 48), ("obstacles/wild_rose_hedge_m", 96, 32), ("obstacles/wild_great_root_m", 96, 28)]):
        part = mp.crop_tight(im.crop((x0, 0, x1, im.height)))
        h = mh if "tree" in key else max(6, min(mh - 2, round((w - 2) * part.height / part.width)))  # The grove tree takes its full SpriteData height (48).
        p = mp.SCRATCH / (key.replace("/", "_") + ".png")
        part.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", mp.RAMPS])
        if key.endswith("_m") and "tree" not in key:
            out = ROOT / "assets/sprites" / (key + ".png")
            bar = Image.open(out).convert("RGBA")
            if bar.width < 96:
                bar = bar.resize((96, bar.height), Image.NEAREST)  # Narrower than the 96 px box: stretch to fit.
            bar.save(out)
            bar.rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))
    sheet = Image.open(HERE / "sheet_icon_heartwood.png").convert("RGBA")
    sp = mp.islands(sheet, 16)[0]
    sym = mp.crop_tight(sheet.crop((sp[0], 0, sp[1], sheet.height)))
    p = mp.SCRATCH / "heartwood.png"
    sym.save(p)
    o24 = mp.SCRATCH / "heartwood_24.png"
    run(["tools/prepare_sprite.py", str(p), "icons/heartwood", "--art-height", "24", "--ink-l", "0.2", "--ramps", mp.ICON_RAMPS, "--out", str(o24)])
    frame = Image.open(ROOT / "assets/sprites/icons/compost_heart.png").convert("RGBA")  # A violet badge frame of this act.
    fill = frame.getpixel((4, 16))
    for y in range(3, 29):
        for x in range(3, 29):
            frame.putpixel((x, y), fill)
    s = Image.open(o24).convert("RGBA")
    if s.width > 26:
        s = s.resize((26, round(s.height * 26 / s.width)), Image.NEAREST)
    frame.alpha_composite(s, ((32 - s.width) // 2, (32 - s.height) // 2))
    frame.save(ROOT / "assets/sprites/icons/heartwood.png")
    for f in mp.SCRATCH.glob("*"):
        f.unlink()
    mp.SCRATCH.rmdir()


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + WALK)
    run(["tools/walk_cycle.py", "idle"] + IDLE)


if __name__ == "__main__":
    for s in sys.argv[1:] or ["units", "props", "strips"]:
        if s.startswith("units:"):
            units(s.split(":")[1].split(","))
        else:
            globals()[s]()
