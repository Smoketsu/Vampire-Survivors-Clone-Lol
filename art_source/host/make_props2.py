#!/usr/bin/env python3
"""make_props2.py: the Gate of Pearl obstacle (obstacles/host_pearl_gate, 96 px wide) and the Turning Bones badge (icons/turning_bones, on the violet frame)
from the API images of gen_props2.py, cut and converted like make_props.py. Usage (repo root): python3 art_source/host/make_props2.py"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
W = HERE / "_work"  # Scratch.
W.mkdir(exist_ok=True)


def tight(im: Image.Image) -> Image.Image:
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    return im.crop(a.getbbox())


def run(a: list) -> None:
    subprocess.run([sys.executable] + a, cwd=ROOT, check=True)


g = tight(Image.open(HERE / "sheet_pearl_gate.png").convert("RGBA"))
g.save(W / "gate.png")
run(["tools/prepare_sprite.py", str(W / "gate.png"), "obstacles/host_pearl_gate", "--art-height", str(max(6, min(80, round(96 * g.height / g.width)))), "--ink-l", "0.15",
     "--ramps", "host_silver,host_cerulean,host_rose,host_cloud,host_skin"])
s = tight(Image.open(HERE / "sheet_icon_turning.png").convert("RGBA"))
s.save(W / "tb.png")
run(["tools/prepare_sprite.py", str(W / "tb.png"), "icons/turning_bones", "--art-height", "24", "--ink-l", "0.2", "--ramps", "host_silver,host_cerulean,host_rose,host_cloud,host_skin,soul,bone", "--out", str(W / "tb24.png")])
frame = Image.open(ROOT / "assets/sprites/icons/bone_spear.png").convert("RGBA")
fill = frame.getpixel((4, 16))
for y in range(3, 29):
    for x in range(3, 29):
        frame.putpixel((x, y), fill)
i = Image.open(W / "tb24.png").convert("RGBA")
if i.width > 26:
    i = i.resize((26, round(i.height * 26 / i.width)), Image.NEAREST)
frame.alpha_composite(i, ((32 - i.width) // 2, (32 - i.height) // 2))
frame.save(ROOT / "assets/sprites/icons/turning_bones.png")
