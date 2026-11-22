#!/usr/bin/env python3
"""make_art.py: rebuilds the Age of Titans' foundation unit art (Act XIV slot, stage key primeval; ART_BIBLE "Act XIV slot: the Age
of Titans") from its API sources. Run from the repo root: python3 art_source/titans/make_art.py [units|strips]. Raw API images in
art_source/titans/raw/ (prompts beside this file, written by gen_prompts.py). Steps: units: every beast through tools/pixelate_source.py
then tools/prepare_sprite.py (primeval_ ramps), the art height chosen so the width fits the manifest box (never taller than the manifest);
strips: walk / fly strips (tools/walk_cycle.py, rigs under "# --- Act XIV slot: the Age of Titans ---"). Procedural parts: titans_tiles.py;
sheets (icons, obstacles): make_props.py."""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/titans.
RAMPS = "primeval_fern,primeval_ochre,primeval_tar,primeval_lava,primeval_bone"  # The act's ramps.
# Sprite id -> (max art width, max art height) from the manifest.
UNITS = {"scuttler": (20, 14), "razorclaw": (44, 34), "razorclaw_alpha": (48, 38), "frill_spitter": (40, 32), "longneck": (96, 80),
         "duckbill": (68, 56), "skyraider": (56, 36), "tyrant": (88, 72)}
STRIPS = list(UNITS)  # Walk strips (the Skyraider's is its flight).
TINY = ["scuttler"]  # Too small for the grid pass: converted directly.


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
            run(["tools/prepare_sprite.py", str(src), "primeval/" + uid, "--art-height", str(h), "--ink-l", "0.15", "--ramps", RAMPS,
                 "--no-prune", "--no-levels", "--no-cleanup"])
        else:
            pix = HERE / "_work" / (uid + ".png")
            pix.parent.mkdir(exist_ok=True)
            run(["tools/pixelate_source.py", str(src), str(h), str(pix)])
            run(["tools/prepare_sprite.py", str(pix), "primeval/" + uid, "--art-height", str(h), "--ink-l", "0.15", "--ramps", RAMPS,
                 "--no-prune", "--no-levels", "--no-cleanup"])
        (HERE / (uid + ".png")).unlink(missing_ok=True)  # prepare_sprite archives the source here; raw/ is the archive.


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + ["primeval/" + k for k in STRIPS])


if __name__ == "__main__":
    for step in sys.argv[1:] or ["units"]:
        if step.startswith("units:"):
            units(step.split(":")[1].split(","))
        else:
            globals()[step]()
