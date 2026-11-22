#!/usr/bin/env python3
"""make_art.py: rebuilds the Celestial Host's foundation art (Act X slot, stage key host; ART_BIBLE "Act X slot: the Celestial Host")
from its API sources. Run from the repo root: python3 art_source/host/make_art.py [units|strips]. Raw API images in
art_source/host/raw/ (prompts beside this file, written by gen_prompts.py; concept crops in refs/). Steps:
  1. units: every roster figure through tools/prepare_sprite.py (--ink-l 0.15, the host_ ramps); the figures (all but the orb) go through
     tools/pixelate_source.py first (the Act IX recipe; it keeps masks, faces and armour readable);
  2. strips: walk / glide strips (tools/walk_cycle.py, rigs under "# --- Act X slot: the Celestial Host ---") and the idle strips of the
     female figures (bust rigs).
Procedural parts (floors, fx, markers) are art_source/host/host_tiles.py and host_fx.py; sheets (icons, obstacles) make_props.py."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
RAMPS = "host_silver,host_cerulean,host_rose,host_cloud,host_skin"  # The Host's ramps.
# Sprite id (assets/sprites/host/<id>.png) -> (art height, extra prepare_sprite arguments).
UNITS = {
    "lesser_light": (22, ["--no-prune", "--no-levels", "--no-cleanup"]),
    "virtue": (48, ["--no-prune"]),
    "power": (48, ["--no-prune"]),
    "choir_angel": (48, ["--no-prune"]),
    "herald": (48, ["--no-prune"]),
    "dominion": (54, ["--no-prune"]),
    "judge": (56, ["--no-prune"]),
}
STRIPS = ["virtue", "power", "choir_angel", "herald", "dominion", "judge", "lesser_light"]  # Walk / glide strips (rigs in walk_cycle.py).
IDLES = ["power", "choir_angel"]  # Idle strips: the female figures (bust rigs).
PIXELATED = ["virtue", "power", "choir_angel", "herald", "dominion", "judge"]  # Detailed figures: pixelate_source.py first.


def run(args: list) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def units(only: list = None) -> None:
    for uid, (height, extra) in UNITS.items():
        if only and uid not in only:
            continue
        src = HERE / "raw" / (uid + ".png")
        if uid in PIXELATED:
            pix = HERE / "_work" / (uid + ".png")
            pix.parent.mkdir(exist_ok=True)
            run(["tools/pixelate_source.py", str(src), str(height), str(pix)])
            src = pix
            extra = ["--no-cleanup", "--no-prune", "--no-levels"]
        run(["tools/prepare_sprite.py", str(src), "host/" + uid, "--art-height", str(height), "--ink-l", "0.15", "--ramps", RAMPS] + extra)
        if uid == "lesser_light":  # The hover strip needs 2 empty rows on top for the bob: pad the still to 24 rows.
            from PIL import Image
            out = ROOT / "assets/sprites/host/lesser_light.png"
            im = Image.open(out).convert("RGBA")
            pad = Image.new("RGBA", (im.width, im.height + 2), (0, 0, 0, 0))
            pad.paste(im, (0, 2))
            pad.save(out)
        (HERE / (uid + ".png")).unlink(missing_ok=True)  # prepare_sprite archives the source here; raw/ is the archive.


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + ["host/" + k for k in STRIPS])
    run(["tools/walk_cycle.py", "idle"] + ["host/" + k for k in IDLES])


if __name__ == "__main__":
    for step in sys.argv[1:] or ["units"]:
        if step.startswith("units:"):
            units(step.split(":")[1].split(","))
        else:
            globals()[step]()
