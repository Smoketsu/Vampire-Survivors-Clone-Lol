#!/usr/bin/env python3
"""make_art.py: rebuilds the Crash Site's art (Act IX, Stage 25; ART_BIBLE "Act IX: the Crash Site") from its API sources.

Run from the repo root (python3 art_source/crash_site/make_art.py [step ...]). Raw API images in art_source/crash_site/raw/
(prompts beside this file), the icon sheets here, the reference crops in refs/. Steps (Liberty Heights's recipe):
  1. units: the Burrower, the Acid Spitter and the Brood Matriarch through tools/prepare_sprite.py (--ink-l 0.15, the
     concord ramps per key; insects keep their own colours, never the player's violet and bone);
  2. figures: the Hive Mother's three new stills (her cast and strike poses, her Flight form) and the Broodbound with
     her three skins, through tools/pixelate_source.py first (the women and the boss, as the foundation's Hive Mother),
     then prepare_sprite.py (--no-cleanup);
  3. obstacles: the seven obstacles of raw/obstacles.png cut apart, each at its own art size (the rubble s / m / l, the
     hull shards s / l with their vertical _v turned 90 degrees, the glass spires s / l);
  4. badges: each symbol of the two icon sheets through prepare_sprite.py --art-height 24, set on the frame of an
     approved badge (violet icons/abyssal_pact, gold icons/tidecallers_host); the violet sheet came back with one
     extra symbol and the gold sheet with a bone beetle, skipped ("") or kept as the beetle (step 5);
  5. procedural: art_source/crash_site/crash_site_tiles.py (the four zone floors, the egg and its hatch strip, the
     dirt mound, the acid puddle) and the bone beetle cut from the gold sheet, turned to face right;
  6. walk / glide / idle strips: tools/walk_cycle.py (its rigs under "# --- Act IX: the Crash Site ---").
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/crash_site.
SCRATCH = HERE / "_work"  # Temporary crops (deleted at the end).

# Sprite key -> (raw source, art height, extra prepare_sprite arguments).
UNITS = {
    "concord/burrower": ("raw/burrower.png", 34, ["--ramps", "gunmetal,grey,chitin,hive_bone,laser,brown", "--ink-l", "0.15"]),
    "concord/acid_spitter": ("raw/acid_spitter.png", 32, ["--ramps", "chitin,plasma,hive_bone", "--ink-l", "0.15"]),
    "concord/brood_matriarch": ("raw/brood_matriarch.png", 60, ["--ramps", "chitin,plasma,hive_bone", "--ink-l", "0.15"]),
}
# Figures put on the art grid first (pixelate_source.py): key -> (raw source, art height, extra arguments).
FIGURES = {
    "bosses/hive_mother": ("raw/hive_mother.png", 96, ["--ramps", "hive,hive_bone,gold", "--no-prune", "--no-levels"]),  # R1 redo: wider hips, bigger bust
    "bosses/hive_mother_cast": ("raw/hive_mother_cast.png", 96, ["--ramps", "hive,hive_bone,gold", "--no-prune", "--no-levels"]),
    "bosses/hive_mother_strike": ("raw/hive_mother_strike.png", 96, ["--ramps", "hive,hive_bone,gold,brown", "--no-prune", "--no-levels"]),
    "bosses/hive_mother_flight": ("raw/hive_mother_flight.png", 96, ["--ramps", "hive,hive_bone,gold", "--no-prune", "--no-levels"]),
    # R1 redo (Act IX): the Broodbound is an alien insect woman. Her base converts from raw/broodbound_flat.png (raw/broodbound.png
    # with the thin orange trim lines opened away, so the 56 px conversion stays readable); the skins straight from their raws.
    "player/broodbound": ("raw/broodbound_flat.png", 56, ["--ramps", "plasma,chitin,gold,ice,hive_bone", "--no-levels"]),
    "player/broodbound_hyper": ("raw/broodbound_hyper.png", 56, ["--ramps", "gold,gunmetal,grey,ice", "--no-levels"]),
    "player/broodbound_untouchable": ("raw/broodbound_untouchable.png", 56, ["--ramps", "marble,soul,grey"]),
    "player/broodbound_deathlord": ("raw/broodbound_deathlord.png", 56, ["--ramps", "steel,crimson,grey", "--no-levels"]),
}
# Figures converted straight by prepare_sprite.py (no pixelate_source step): the Broodbound and her Hyper skin (the
# pixelated conversion lost her face and eyes at 56 px; the straight one kept them, as the Revenant Heroine's Deathlord).
DIRECT = ["player/broodbound", "player/broodbound_hyper", "player/broodbound_untouchable", "player/broodbound_deathlord"]  # R1 redo: all four straight (--ink-l 0.15).
# The obstacle sheet raw/obstacles.png, left to right: (key or keys, art width, ramps). A key list gets the vertical _v
# too (turned 90 degrees; rect kinds only).
OBSTACLES = [
    ("obstacles/crash_rubble_s", 26, "grey,steel"),
    ("obstacles/crash_rubble_m", 34, "grey,steel"),
    ("obstacles/crash_rubble_l", 42, "grey,steel"),
    ("obstacles/crash_hull_shard_s", 30, "hull,gunmetal,plasma"),
    ("obstacles/crash_hull_shard_l", 40, "hull,gunmetal,plasma"),
    ("obstacles/glass_spire_s", 22, "ice,grey"),
    ("obstacles/glass_spire_l", 30, "ice,grey"),
]
# Rect kinds whose vertical sprite (_v) is the horizontal one turned 90 degrees.
VERTICAL = ["obstacles/crash_hull_shard_s", "obstacles/crash_hull_shard_l"]
# Icon sheets: file -> (badge frame, symbol ids left to right; "" = skip; "beetle" = the bone beetle, step 5).
ICONS = {
    "icons_violet.png": ("icons/abyssal_pact", ["bone_beetles", "chitin", "anchored", ""]),
    "icons_gold.png": ("icons/tidecallers_host", ["hive_of_bone", "ach_nothing_hatched", "beetle"]),
}
# Hovering stills (hover rigs: the bob moves the whole sprite): PAD empty rows are added above and below each, as the
# saucer's 2 + 2 (walk_cycle.py refuses a bob that would push pixels off the canvas).
HOVER = ["concord/brood_matriarch", "bosses/hive_mother_flight"]
PAD = 2
# Walk / glide strips (rigs in tools/walk_cycle.py) and the idle strips of the women (bust rigs).
STRIPS = ["concord/burrower", "concord/acid_spitter", "concord/brood_matriarch", "bosses/hive_mother_flight",
          "player/broodbound", "player/broodbound_hyper", "player/broodbound_untouchable", "player/broodbound_deathlord"]
IDLES = ["player/broodbound", "player/broodbound_hyper", "player/broodbound_untouchable", "player/broodbound_deathlord"]


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
        keep = (HERE / src).read_bytes()  # prepare_sprite archives the file it is given.
        run(["tools/prepare_sprite.py", str(HERE / src), key, "--art-height", str(height)] + extra)
        (HERE / src).write_bytes(keep)


def figures() -> None:
    for key, (src, height, extra) in FIGURES.items():
        keep = (HERE / src).read_bytes()
        pix = SCRATCH / (key.replace("/", "_") + ".png")
        if key in DIRECT:
            run(["tools/prepare_sprite.py", str(HERE / src), key, "--ink-l", "0.15", "--art-height", str(height)] + extra)
            (HERE / src).write_bytes(keep)
            continue
        run(["tools/pixelate_source.py", str(HERE / src), str(height), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--ink-l", "0.15", "--no-cleanup", "--art-height", str(height)] + extra)
        (HERE / src).write_bytes(keep)


def obstacles() -> None:
    im = Image.open(HERE / "raw/obstacles.png").convert("RGBA")
    spans = islands(im, 0, min_gap=6)
    for (x0, x1), (key, width, ramps) in zip(spans, OBSTACLES):
        part = crop_tight(im.crop((x0, 0, x1, im.height)))
        height = max(6, round(width * part.height / part.width))  # Art rows for this width (aspect kept).
        p = SCRATCH / (key.replace("/", "_") + ".png")
        part.save(p)
        run(["tools/prepare_sprite.py", str(p), key, "--art-height", str(height), "--ink-l", "0.15", "--ramps", ramps])
        if key in VERTICAL:
            out = ROOT / "assets/sprites" / (key + ".png")
            Image.open(out).convert("RGBA").rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))


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
            if sid == "beetle":
                # The bone beetle (Bone Beetles' projectile): 10 art px wide, its head turned to the right.
                turned = SCRATCH / "beetle_turned.png"
                sym.rotate(90, expand=True).save(turned)
                run(["tools/prepare_sprite.py", str(turned), "projectiles/bone_beetle", "--art-height", "10", "--ink-l", "0.2",
                     "--ramps", "hive_bone,brown,gold"])
                continue
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


def procedural() -> None:
    run([str(HERE / "crash_site_tiles.py")])


def pad(key: str) -> None:
    """Adds PAD transparent rows above and below the still `key` (once: a still already padded is left alone)."""
    p = ROOT / "assets/sprites" / (key + ".png")
    im = Image.open(p).convert("RGBA")
    top = im.crop((0, 0, im.width, PAD)).getbbox()
    bottom = im.crop((0, im.height - PAD, im.width, im.height)).getbbox()
    if top is None and bottom is None:
        return
    out = Image.new("RGBA", (im.width, im.height + PAD * 2), (0, 0, 0, 0))
    out.alpha_composite(im, (0, PAD))
    out.save(p)


def strips() -> None:
    for key in HOVER:
        pad(key)
    run(["tools/walk_cycle.py", "build"] + STRIPS)
    run(["tools/walk_cycle.py", "idle"] + IDLES)


if __name__ == "__main__":
    SCRATCH.mkdir(exist_ok=True)
    steps = sys.argv[1:] or ["units", "figures", "obstacles", "badges", "procedural", "strips"]
    for step in steps:
        globals()[step]()
    for f in SCRATCH.glob("*"):
        f.unlink()
    SCRATCH.rmdir()
