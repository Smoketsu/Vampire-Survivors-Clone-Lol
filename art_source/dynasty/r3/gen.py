#!/usr/bin/env python3
"""r3/gen.py: round 3 of the owner's mummy review (male fodder mummy rejected twice): 3 candidates, raw images in r3/ (only the kept one stays).
Usage (repo root): python3 art_source/dynasty/r3/gen.py [a b c]"""
import subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view, FULL BODY, FACING RIGHT.\n\n"
 "LOW-RESOLUTION pixel art: the whole figure is only 40 pixels tall, drawn on a coarse pixel grid and shown enlarged so every pixel is a big crisp "
 "square block. Chunky, flat fills, no gradients, no dithering, no anti-aliasing, no hieroglyph text.\n\n"
 "Subject: the CLASSIC HORROR-MOVIE EGYPTIAN MUMMY. The whole body is wrapped in thick bandages drawn as BOLD, CLEARLY VISIBLE HORIZONTAL AND DIAGONAL "
 "STRIPES: alternate a light cream band, then a dark shadow-brown gap line, then a light band again, across the head, torso, arms and legs, so the stripes "
 "read instantly even at tiny size (like a roll of tape wound round the body). The head is a fully wrapped ROUND ball of bandages with NO face, NO nose, "
 "NO mouth, only a narrow dark slit across the eyes with TWO tiny glowing green eye dots. {extra}Both arms stretched STRAIGHT OUT FORWARD at chest height "
 "(the iconic zombie shamble, stiff, parallel), a STOOPED, hunched, lurching stance, legs wrapped in stripes too. Three or four LOOSE BANDAGE ENDS dangle "
 "and trail from the arm, shoulder and waist. The linen is aged and yellowed with one or two darker dirty-brown stained patches. A small scrap of DULL GOLD "
 "(a broken collar piece or a belt buckle) on the chest.\n\n"
 "Colours: ONLY flat fills: linen #8F8670 #C9C0A4 #F0E8D2; shadow gap lines #3A3326; stain brown #5E4F2E; dull gold #6B5A22 #A38E3C #D2BB62; eyes green #4E8F40 #8CC45E.\n\n"
 "Outline: a clean 1-pixel dark outline around the whole subject in the darkest shade (never pure black). Light from the top-left. Output: a square PNG with "
 "a FULLY TRANSPARENT background (real alpha), one subject only, centred, filling about 85% of the height. No ground, no shadow, no text, no frame. "
 "Draw ONLY ONE figure.\nAttached: a sibling Egyptian mummy sprite for pixel size, outline and flat look (copy the style, NOT the lack of stripes), and a game sprite for outline weight.\n")
V = {"a": "", "b": "The bandage stripes are extra wide and high-contrast, running diagonally across the chest like a sash and crisscrossing. ",
     "c": "Cartoon-bold: very thick alternating light and dark bands, exaggerated big round wrapped head and big hands wrapped like mitts. "}
for k in (sys.argv[1:] or V):
    (HERE / f"mummy_{k}.txt").write_text(HEAD.format(extra=V[k]))
    cmd = [sys.executable, "tools/gen_image.py", str(HERE / f"mummy_{k}.txt"), str(HERE / f"mummy_{k}.png"), "--key", "dynasty/r3_mummy_" + k,
           "--ref", str(ROOT / "assets/sprites/dynasty/mummy_female.png"), "--ref", str(ROOT / "assets/sprites/dynasty/khopesh_guard.png")]
    subprocess.run(cmd, cwd=ROOT)
