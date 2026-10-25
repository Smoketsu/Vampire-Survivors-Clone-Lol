#!/usr/bin/env python3
"""aoe_preview.py: renders the player AoE art sheets in the real engine (GDD 15.0 "Player AoE art").

Copies tools/aoe_preview/ into a temporary res://_aoe_preview/ folder of this project (tools/ is
ignored by Godot), runs its scene in a window under xvfb with the OpenGL renderer at 1280x720, saves
one PNG per sheet and removes the folder again (also when Godot fails). Sheets: 0 zones (clouds,
auras, fields), 1 burst rings, 2 telegraphs / lane / column / ultimates. --code draws the code
fallbacks instead (the "before" look).

Usage (from the repo root):
    python3 tools/aoe_preview.py OUT_DIR [--pages 0,1,2] [--code]
Needs the Godot 4.3 binary (GODOT env var or the default path below) and xvfb-run.
"""
import argparse
import os
import shutil
import subprocess
from pathlib import Path

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Godot binary (override with the GODOT environment variable).
GODOT = os.environ.get("GODOT", "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64")
# Temporary scene folder inside the project.
TMP = ROOT / "_aoe_preview"

SCENE = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://_aoe_preview/aoe_preview.gd" id="1"]

[node name="AoePreview" type="Node2D"]
script = ExtResource("1")
"""


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("out", help="output folder for aoe_<page>[_code].png")
    ap.add_argument("--pages", default="0,1,2", help="sheet numbers")
    ap.add_argument("--code", action="store_true", help="draw the code fallbacks (before)")
    args = ap.parse_args()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(exist_ok=True)
    try:
        shutil.copy(ROOT / "tools" / "aoe_preview" / "aoe_preview.gd", TMP / "aoe_preview.gd")
        (TMP / "aoe_preview.tscn").write_text(SCENE)
        subprocess.run([GODOT, "--headless", "--import"], cwd=ROOT, capture_output=True, timeout=900)
        for page in args.pages.split(","):
            png = out / ("aoe_%s%s.png" % (page, "_code" if args.code else ""))
            cmd = ["xvfb-run", "-a", "-s", "-screen 0 1280x720x24", GODOT, "--rendering-driver", "opengl3",
                   "--resolution", "1280x720", "res://_aoe_preview/aoe_preview.tscn", "--",
                   "--page=" + page, "--out=" + str(png)] + (["--code"] if args.code else [])
            r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=300)
            errs = [ln for ln in (r.stdout + r.stderr).splitlines() if "SCRIPT ERROR" in ln or "Parse Error" in ln]
            print(png, "ok" if png.exists() else "MISSING", *errs[:5], sep="\n  ")
    finally:
        shutil.rmtree(TMP, ignore_errors=True)


if __name__ == "__main__":
    main()
