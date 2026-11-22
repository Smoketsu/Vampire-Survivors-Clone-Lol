#!/usr/bin/env python3
"""make_art.py: rebuilds the Turning Year' foundation unit art (Act XIV slot, stage key primeval; ART_BIBLE "Act XIV slot: the Age
of Titans") from its API sources. Run from the repo root: python3 art_source/year/make_art.py [units|strips]. Raw API images in
art_source/year/raw/ (prompts beside this file, written by gen_prompts.py). Steps: units: every beast through tools/pixelate_source.py
then tools/prepare_sprite.py (primeval_ ramps), the art height chosen so the width fits the manifest box (never taller than the manifest);
strips: walk / glide strips (tools/walk_cycle.py, rigs under "# --- Act XIV slot: the Turning Year ---"). Procedural parts: titans_tiles.py;
sheets (icons, obstacles): make_props.py."""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
RAMPS = "wild_moss,wild_bark,wild_blossom,wild_leaf,wild_frost,wild_blight,wild_fire,skin"  # The act's ramps.
# Sprite id -> (max art width, max art height) from the manifest.
UNITS = {"thornling": (22, 20), "dryad": (32, 52), "treant": (64, 80), "corpse_bloom": (48, 48), "corpse_bloom_dead": (48, 48),
         "fae_knight": (36, 52), "winter_fae": (34, 52), "great_stag": (72, 64), "wild_rider": (72, 64), "will_o_wisp": (24, 28),
         "spore_mother": (38, 52)}
STRIPS = ["thornling", "dryad", "treant", "fae_knight", "winter_fae", "great_stag", "wild_rider", "will_o_wisp", "spore_mother"]  # Walk strips (the wisp's is its glide; the corpse-bloom is a structure, no strip).
IDLES = ["dryad", "winter_fae", "spore_mother"]  # Idle strips: the female figures (bust rigs).
TINY = ["thornling", "will_o_wisp"]  # Too small for the grid pass: converted directly.


def run(args: list) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def units(only: list = None) -> None:
    for uid, (mw, mh) in UNITS.items():
        if only and uid not in only:
            continue
        src = HERE / "raw" / (uid + ".png")
        im = Image.open(src).convert("RGBA")
        bb = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
        aspect = (bb[2] - bb[0]) / (bb[3] - bb[1])
        h = min(mh, int((mw - 2) / aspect) + 2)  # +2: the outline rows / columns prepare_sprite adds.
        if uid in TINY:
            run(["tools/prepare_sprite.py", str(src), "wild/" + uid, "--art-height", str(h), "--ink-l", "0.15", "--ramps", RAMPS,
                 "--no-prune", "--no-levels", "--no-cleanup"])
        else:
            pix = HERE / "_work" / (uid + ".png")
            pix.parent.mkdir(exist_ok=True)
            run(["tools/pixelate_source.py", str(src), str(h), str(pix)])
            run(["tools/prepare_sprite.py", str(pix), "wild/" + uid, "--art-height", str(h), "--ink-l", "0.15", "--ramps", RAMPS,
                 "--no-prune", "--no-levels", "--no-cleanup"])
        if uid == "will_o_wisp":  # The glide bob needs 2 empty rows on top: pad the still.
            out = ROOT / "assets/sprites/wild/will_o_wisp.png"
            im = Image.open(out).convert("RGBA")
            pad = Image.new("RGBA", (im.width, im.height + 2), (0, 0, 0, 0))
            pad.paste(im, (0, 2))
            pad.save(out)
        (ROOT / "art_source/wild" / (uid + ".png")).unlink(missing_ok=True)  # prepare_sprite archives the source in art_source/wild/; raw/ is the archive.


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + ["wild/" + k for k in STRIPS])
    run(["tools/walk_cycle.py", "idle"] + ["wild/" + k for k in IDLES])


if __name__ == "__main__":
    for step in sys.argv[1:] or ["units"]:
        if step.startswith("units:"):
            units(step.split(":")[1].split(","))
        else:
            globals()[step]()
