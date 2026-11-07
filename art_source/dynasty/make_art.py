#!/usr/bin/env python3
"""make_art.py: rebuilds the Necropolis Dynasty's art (Act VII slot, stage key dynasty; ART_BIBLE "Act VII slot: the Necropolis Dynasty")
from its API sources.

Run from the repo root: python3 art_source/dynasty/make_art.py [step ...]. Raw API images in art_source/dynasty/raw/ (prompts beside
this file, written by gen_prompts.py; reference crops of the approved concepts in refs/). Steps:
  1. units: every figure, beast, statue, jar and boss through tools/prepare_sprite.py (--ink-l 0.15, the dyn_ ramps per key);
  2. strips: walk / glide strips (tools/walk_cycle.py, rigs under "# --- Act VII slot: the Necropolis Dynasty ---") and the idle strips of
     every female figure (bust rigs);
  3. procedural: art_source/dynasty/dynasty_tiles.py (floors, quicksand, glyph sprites) when present;
  4. obstacles and badges: art_source/dynasty/make_props.py (sheets cut apart; icons on the approved frames).
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty.

# Sprite id (assets/sprites/dynasty/<id>.png) -> (art height, ramps, extra prepare_sprite arguments).
UNITS = {
    "mummy": (40, "linen,dyn_bronze,papyrus,night", ["--no-prune", "--no-levels"]),
    "mummy_female": (40, "linen,dyn_bronze,papyrus,night", ["--no-prune", "--no-levels"]),
    "scarab_swarm": (38, "lapis,dyn_bronze,carnelian,night", ["--no-prune", "--no-levels", "--no-cleanup"]),
    "khopesh_guard": (46, "dynskin,linen,dyn_bronze,lapis,night", ["--no-prune"]),
    "nile_archer": (44, "dynskin,linen,dyn_bronze,papyrus,night,brown", ["--no-prune"]),
    "heka_priest": (46, "dynskin,linen,dyn_bronze,gold,night", ["--no-prune", "--no-levels"]),
    "embalmer": (44, "dynskin,linen,dyn_bronze,papyrus,lapis,brown", ["--no-prune"]),
    "jackal_warrior": (48, "night,dynskin,linen,dyn_bronze,lapis,brown", ["--no-prune"]),
    "bastet_hunter": (44, "night,dynskin,linen,dyn_bronze,carnelian", ["--no-prune", "--no-levels"]),
    "crocodile_warden": (50, "papyrus,linen,dyn_bronze,lapis,sand", ["--no-prune"]),
    "ushabti_statue": (46, "sand,lapis,dyn_bronze,papyrus", ["--no-prune"]),
    "canopic_jar": (30, "sand,lapis,dyn_bronze,papyrus", ["--no-prune"]),
    "canopic_jar_dead": (26, "sand,lapis,dyn_bronze", []),
    "sand_colossus": (84, "sand,lapis,dyn_bronze,papyrus", ["--no-prune"]),
    "lion_warden": (80, "sand,dynskin,lapis,dyn_bronze,carnelian,linen", ["--no-prune"]),
    "devourers_whelp": (36, "papyrus,sand,night,dyn_bronze,carnelian,lapis", ["--no-prune"]),
    "anubis": (90, "night,dynskin,linen,dyn_bronze,lapis,brown", ["--no-prune"]),
    "sekhmet": (92, "sand,carnelian,dyn_bronze,night,dynskin", ["--no-prune"]),
    "osiris": (96, "papyrus,linen,dyn_bronze,night,lapis", ["--no-prune"]),
    "ammit": (44, "papyrus,sand,night,dyn_bronze,lapis,carnelian", ["--no-prune"]),
        "ushabti_sentinel": (46, "sand,grey,soul,brown", ["--no-prune"]),
    "eternal_guard": (58, "sand,grey,soul,gold,brown", ["--no-prune"]),
}
# Walk / glide strips: ids (rigs in tools/walk_cycle.py) and idle strips (bust rigs: the female figures).
STRIPS = ["mummy", "mummy_female", "scarab_swarm", "khopesh_guard", "nile_archer", "heka_priest", "embalmer", "jackal_warrior",
          "bastet_hunter", "crocodile_warden", "ushabti_statue", "sand_colossus", "lion_warden", "devourers_whelp", "anubis", "sekhmet",
          "ammit", "ushabti_sentinel", "eternal_guard"]
IDLES = ["mummy_female", "nile_archer", "embalmer", "bastet_hunter", "sekhmet"]


# Female figures (figure-redesign style) go through tools/pixelate_source.py first (the Act IX women's recipe: it keeps the face,
# collar and hourglass at 40-90 px) and then prepare_sprite.py --no-cleanup --no-levels.
PIXELATED = ["mummy_female", "nile_archer", "embalmer", "bastet_hunter", "sekhmet"]


def run(args: list) -> None:
    """Runs a repo tool, failing loudly."""
    print("+", " ".join(args), flush=True)
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def units(only: list = None) -> None:
    for uid, (height, ramps, extra) in UNITS.items():
        if only and uid not in only:
            continue
        src = HERE / "raw" / (uid + ".png")
        if uid in PIXELATED:
            pix = HERE / "_work" / (uid + ".png")
            pix.parent.mkdir(exist_ok=True)
            run(["tools/pixelate_source.py", str(src), str(height), str(pix)])
            src = pix
            extra = ["--no-cleanup", "--no-prune", "--no-levels"]
        run(["tools/prepare_sprite.py", str(src), "dynasty/" + uid, "--art-height", str(height), "--ink-l", "0.15", "--ramps", ramps] + extra)
        (HERE / (uid + ".png")).unlink(missing_ok=True)  # prepare_sprite archives the source here; raw/ is the archive.


def strips() -> None:
    run(["tools/walk_cycle.py", "build"] + ["dynasty/" + k for k in STRIPS])
    run(["tools/walk_cycle.py", "idle"] + ["dynasty/" + k for k in IDLES])


if __name__ == "__main__":
    steps = sys.argv[1:] or ["units", "strips"]
    for step in steps:
        if step.startswith("units:"):
            units(step.split(":")[1].split(","))
        else:
            globals()[step]()
# NOTE: the three playable characters (player/the_embalmer, lion_priestess, pharaohs_shade) are built by art_source/dynasty/gen_chars.py +
# `tools/prepare_sprite.py art_source/dynasty/chars/<id>.png player/<id> --art-height 56 --ink-l 0.15 --ramps violet,bone,soul,brown,grey --no-levels`
# then `tools/walk_cycle.py build|idle player/<id>` (owner note: purple necromancers of the act's theme).
