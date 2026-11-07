#!/usr/bin/env python3
"""make_props.py: the Dynasty's obstacles, badge icons and world markers, cut from the API sheets (gen_sheets.py) and run through
tools/prepare_sprite.py (the Crash Site's recipe, art_source/crash_site/make_art.py). Run from the repo root:
python3 art_source/dynasty/make_props.py [obstacles] [badges] [markers]."""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).
# Obstacle sheets left to right: (key, art width, ramps). Rect kinds in VERTICAL get a `_v` too (the horizontal one turned 90 degrees).
RAMPS = "sand,lapis,bronze,papyrus,night,flame,carnelian"
OBSTACLES = {
    "sheet_obstacles_a.png": [("obstacles/dyn_tomb_s", 28), ("obstacles/dyn_tomb_l", 44), ("obstacles/dyn_obelisk_s", 14),
                              ("obstacles/dyn_obelisk_l", 18), ("obstacles/dyn_statue_row_s", 36), ("obstacles/dyn_statue_row_l", 56),
                              ("obstacles/dyn_colonnade_s", 44)],
    "sheet_obstacles_b.png": [("obstacles/dyn_colonnade_l", 70), ("obstacles/dyn_great_scales", 64), ("obstacles/dyn_brazier", 16),
                              ("obstacles/dyn_sphinx_head", 34), ("obstacles/dyn_sandstone_blocks", 36)],
}
VERTICAL = ["obstacles/dyn_statue_row_s", "obstacles/dyn_statue_row_l", "obstacles/dyn_colonnade_s", "obstacles/dyn_colonnade_l"]
# Badge sheets: file -> symbols left to right ("" = skipped extra symbol): (icon id, frame icon). Violet frame = spells, passives,
# counter-passives and summon classes; gold frame = evolutions and achievements (as the existing icons).
VIOLET, GOLD = "icons/bone_spear", "icons/ossuary_lance"
BADGES = {
    "sheet_icons_a.png": [("linen_bind", VIOLET), ("burning_eye", VIOLET), ("feathers_verdict", VIOLET), ("natron_salts", VIOLET)],
    "sheet_icons_b.png": [("desert_fury", VIOLET), ("heavy_heart", VIOLET), ("embalmed_bones", VIOLET), ("dune_walkers", VIOLET), ("", "")],
    "sheet_icons_c.png": [("eternal_shroud", GOLD), ("eye_of_retribution", GOLD), ("heart_devoured", GOLD), ("ach_names_taken", GOLD), ("", "")],
    "sheet_icons_d.png": [("ach_no_jars_left", GOLD), ("ach_a_light_heart", GOLD), ("ushabti_sentinel", VIOLET), ("eternal_guard", GOLD)],
}
# World markers: sheet_markers.png left to right: (key, art height); the third symbol (a scarab) is unused.
MARKERS = [("markers/dyn_cartouche", 20), ("markers/dyn_heka_glyph", 16), ("", 0)]


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
    for sheet, items in OBSTACLES.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 10)
        assert len(spans) == len(items), (sheet, len(spans))
        for (x0, x1), (key, width) in zip(spans, items):
            part = crop_tight(im.crop((x0, 0, x1, im.height)))
            height = max(6, round(width * part.height / part.width))
            p = SCRATCH / (key.replace("/", "_") + ".png")
            part.save(p)
            run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(height), "--ink-l", "0.15", "--ramps", RAMPS])
            (HERE / "obstacles").mkdir(exist_ok=True)
            if key in VERTICAL:
                out = ROOT / "assets/sprites" / (key + ".png")
                Image.open(out).convert("RGBA").rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))


def badges() -> None:
    for sheet, items in BADGES.items():
        im = Image.open(HERE / sheet).convert("RGBA")
        spans = islands(im, 30)
        assert len(spans) == len(items), (sheet, len(spans))
        for (x0, x1), (sid, frame_key) in zip(spans, items):
            if not sid:
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


def markers() -> None:
    im = Image.open(HERE / "sheet_markers.png").convert("RGBA")
    spans = islands(im, 30)
    assert len(spans) == len(MARKERS), len(spans)
    for (x0, x1), (key, height) in zip(spans, MARKERS):
        if not key:
            continue
        p = SCRATCH / (key.replace("/", "_") + ".png")
        crop_tight(im.crop((x0, 0, x1, im.height))).save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(height), "--ink-l", "0.2", "--ramps", "gold,brown"])


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    for step in sys.argv[1:] or ["obstacles", "badges", "markers"]:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
