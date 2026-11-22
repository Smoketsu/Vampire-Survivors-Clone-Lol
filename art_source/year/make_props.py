#!/usr/bin/env python3
"""make_props.py: the Turning Year' obstacles and badge icons, cut from the API sheets (gen_sheets.py) and run through tools/prepare_sprite.py
(the Dynasty's recipe, art_source/dynasty/make_props.py). Run from the repo root: python3 art_source/year/make_props.py [obstacles] [badges].
The sheets carry an extra fifth symbol the model added; only the first symbols named below are used."""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).
RAMPS = "wild_moss,wild_bark,wild_blossom,wild_leaf,wild_frost,wild_blight,wild_fire"  # Obstacle ramps.
ICON_RAMPS = RAMPS + ",soul,bone"  # Icon ramps (soul-teal glints, bone-white horns and skulls).
# Obstacle sheet left to right: (key, max art width, max art height). Rect kinds also get a `_v` (the horizontal one turned 90 degrees).
# (key, max art width, max art height, index of the sheet symbol). The oak and the stone have two sizes (`_s` / `_l`: the stages' two `sizes`).
OBSTACLES = [("obstacles/wild_oak_l", 40, 40, 0), ("obstacles/wild_oak_s", 28, 28, 0), ("obstacles/wild_stone_l", 52, 30, 1),
             ("obstacles/wild_stone_s", 38, 22, 1), ("obstacles/wild_thicket_m", 52, 52, 2)]
VERTICAL = ["obstacles/wild_stone_l", "obstacles/wild_stone_s"]
# Badge sheets: file -> the first four symbols left to right: (icon id, frame icon). Violet frame = spells, passives, counter-passives
# and summon classes; gold frame = evolutions and achievements (as the existing icons).
VIOLET, GOLD = "icons/bone_spear", "icons/ossuary_lance"
BADGES = {
    "sheet_icons_a.png": [("wild_hunt", VIOLET), ("glamour", VIOLET), ("root_and_rot", VIOLET), ("horn_of_the_hunt", VIOLET)],
    "sheet_icons_b.png": [("changeling", VIOLET), ("compost_heart", VIOLET), ("deadwood", VIOLET), ("fallow_ground", VIOLET)],
    "sheet_icons_c.png": [("the_endless_hunt", GOLD), ("court_of_masks", GOLD), ("return_to_earth", GOLD), ("world_root_warden", GOLD)],
    "sheet_icons_d.png": [("ach_scorched_earth", GOLD), ("ach_a_fair_bargain", GOLD), ("ach_the_first_spring", GOLD), ("ossuary_oak", VIOLET)],
}


def run(args: list) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def islands(im: Image.Image, min_gap: int) -> list:
    """Spans [a, b) of opaque columns separated by >= min_gap empty ones."""
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    occ = [a.crop((i, 0, i + 1, a.height)).getbbox() is not None for i in range(a.width)]
    spans, start, gap = [], None, 0
    for i, o in enumerate(occ):
        if o:
            start = i if start is None else start
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
    return im.crop(im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox())


def obstacles() -> None:
    im = Image.open(HERE / "sheet_obstacles.png").convert("RGBA")
    spans = islands(im, 10)
    assert len(spans) >= 3, len(spans)
    for key, width, max_h, idx in OBSTACLES:
        x0, x1 = spans[idx]
        part = crop_tight(im.crop((x0, 0, x1, im.height)))
        height = max(6, min(max_h, round(width * part.height / part.width)))
        p = SCRATCH / (key.replace("/", "_") + ".png")
        part.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(height), "--ink-l", "0.15", "--ramps", RAMPS])
        if key in VERTICAL:
            out = ROOT / "assets/sprites" / (key + ".png")
            Image.open(out).convert("RGBA").rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))


def badges() -> None:
    for sheet, items in BADGES.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 16)
        assert len(spans) >= len(items), (sheet, len(spans))
        for (x0, x1), (sid, frame_key) in zip(spans, items):
            if not sid:
                continue
            sym = crop_tight(im.crop((x0, 0, x1, im.height)))
            p = SCRATCH / (sid + ".png")
            sym.save(p)
            out = SCRATCH / (sid + "_24.png")
            run(["tools/prepare_sprite.py", str(p), "icons/" + sid, "--art-height", "24", "--ink-l", "0.2", "--ramps", ICON_RAMPS, "--out", str(out)])
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


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    for step in sys.argv[1:] or ["obstacles", "badges"]:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
