#!/usr/bin/env python3
"""harbour_props.py: draws Gullhaven's thin or repeating props straight onto the art grid.

Why (harbour placeholder art pass, Oct 2026; GDD 15.0 "Harbour placeholder art pass"): these four
were still code shapes in play (HarbourGlyphs), and each is either a mesh / lattice that an AI
source loses in the reduction to the grid (the owner's rule after the lobster pots and net piles,
tools/mesh_props.py) or a plain piece of geometry that must line up exactly when it is repeated
(planks, chain links, foam crests). So they are drawn here pixel by pixel from palette colours
(tools/palette.json), deterministic (no randomness: a rerun reproduces the files).

Usage (from the repo root):
    python3 tools/harbour_props.py            # writes the sprites below
    python3 tools/harbour_props.py --out DIR  # writes them to DIR instead (review)

Outputs (assets/sprites/<key>.png):
  structures/harbour_pier    the smugglers' dry pier (HarbourDirector), 152 x 40, drawn along +x
                             (the engine turns it along the pier): cross planks between two side
                             beams, nails, worn gaps, wet stains and pilings poking out each side.
  overlays/harbour_net       the Netcaster's weighted net over a pinned body, 33 x 33: a round
                             diamond rope mesh with see-through holes, a rim rope and lead weights.
  projectiles/anchor_chain_link  one rusted chain link, 7 x 5 (the Harbourmaster's anchor chain,
                             repeated along the chain, every other link turned edge-on).
  overlays/undertow_crest    one foam crest segment of the Undertow wave, 10 x 14, facing +x (the
                             wave's outward direction); repeated along the wave's arc.
"""
import argparse
import json
import math
from pathlib import Path

from PIL import Image

# Repository root (this file lives in tools/).
ROOT = Path(__file__).resolve().parent.parent
# Where the sprites are written by default (keys below are relative to it).
OUT_DIR = ROOT / "assets" / "sprites"

# Palette colours used, by palette.json name (the only colours these sprites may hold).
COLOR_NAMES = ["ink_warm", "brown", "brown_light", "bone_shade", "bone_mid", "bone", "ink_cold",
               "grey_dark", "grey", "grey_light", "steel_dark", "drowned_dark", "drowned",
               "ink_drowned", "ice", "ice_light", "arcane_dark", "arcane"]

# Pier: size (art px) along the pier (x) and across it (y); HarbourStage pier_length 150 x pier_width 40.
PIER_SIZE = (152, 40)
# Pier: width of one cross plank (art px, joints included).
PIER_PLANK = 5
# Pier: thickness of each side beam (art px).
PIER_BEAM = 3
# Pier: x positions (art px) of the pilings that poke out past both side beams.
PIER_PILINGS = (10, 58, 106, 146)
# Pier: indices of the planks worn through (a dark gap), deterministic.
PIER_GAPS = (7, 19)
# Net: diameter of the net sprite (art px).
NET_SIZE = 33
# Net: spacing of the diamond mesh diagonals (art px; 6 = 5 px holes, like the net piles: 5 read as a checkerboard).
NET_MESH = 6
# Chain link size (art px): (length, height).
LINK_SIZE = (7, 5)
# Undertow crest segment size (art px): (depth along the wave, length along the arc).
CREST_SIZE = (10, 14)


def palette() -> dict:
    """Name -> (r, g, b, 255) for COLOR_NAMES, read from tools/palette.json."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    hexes = {c["name"]: c["hex"] for c in data["colors"]}
    return {n: tuple(int(hexes[n][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for n in COLOR_NAMES}


def outline(img: Image.Image, ink: tuple) -> None:
    """Paints every transparent pixel that touches an opaque one (4-neighbour) with `ink`."""
    w, h = img.size
    px = img.load()
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and px[nx, ny] != ink:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = ink


def pier(pal: dict) -> Image.Image:
    """The dry pier, along +x: cross planks (alternating brown shades, a lit top row and a dark
    joint each), two side beams, nails at the beams, two worn gaps, wet drowned stains near the
    sea end (+x), and pilings poking out past both beams."""
    w, h = PIER_SIZE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    top, bot = 2, h - 3  # Deck rows (the pilings poke out above and below).
    for x in range(w):
        plank = x // PIER_PLANK  # Plank index along the pier.
        joint = x % PIER_PLANK == PIER_PLANK - 1  # The dark joint after each plank.
        for y in range(top, bot + 1):
            if y < top + PIER_BEAM or y > bot - PIER_BEAM:
                c = pal["brown"] if y in (top, bot - PIER_BEAM + 1) else pal["ink_warm"]  # Side beams, lit top edge.
            elif joint:
                c = pal["ink_warm"]
            elif plank in PIER_GAPS and top + PIER_BEAM + 3 <= y <= bot - PIER_BEAM - 4:
                c = pal["ink_drowned"]  # A board worn through: the dark water under the pier.
            else:
                c = pal["brown"]
                if x % PIER_PLANK == 0 and plank % 3 == 0:
                    c = pal["brown_light"]  # The lit edge of every third (newer) board.
                elif (x * 7 + y * 3 + plank * 5) % 23 == 0:
                    c = pal["ink_warm"]  # A knot or crack in the grain.
                # Wet stains on the last boards at the sea end (+x), creeping up from one side.
                if plank * PIER_PLANK > w * 0.84 and y > (top + bot) // 2 + (plank % 3) * 3 and c == pal["brown"]:
                    c = pal["drowned_dark"]
            px[x, y] = c
        if not joint and x % PIER_PLANK == 2:
            px[x, top + PIER_BEAM] = pal["grey"]  # Nails into the beams.
            px[x, bot - PIER_BEAM] = pal["grey_dark"]
    for x0 in PIER_PILINGS:
        for y0 in (0, h - 4):
            for dy in range(4):
                for dx in range(4):
                    if (dx in (0, 3)) and (dy in (0, 3)):
                        continue  # Rounded post top.
                    lit = dx + dy <= 2
                    px[x0 - 2 + dx, y0 + dy] = pal["brown_light"] if lit else pal["brown"]
            px[x0 - 1, y0 + 1] = pal["bone_shade"]  # Rope wrap glint.
    outline(img, pal["ink_warm"])
    return img


def net(pal: dict) -> Image.Image:
    """The Netcaster's net seen from above, thrown over a body: a round diamond rope mesh (lit
    ropes bone, shaded ropes bone_shade) with see-through holes, a rim rope and four lead weights."""
    n = NET_SIZE
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    c = (n - 1) / 2.0  # Centre (art px).
    r = n / 2.0 - 2.5  # Rim radius (art px).
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c)
            if d > r + 0.5:
                continue
            lit = (x - c) + (y - c) < 0  # Top-left half catches the light.
            on_rim = d > r - 0.9
            mesh = (x + y) % NET_MESH == 0 or (x - y) % NET_MESH == 0
            if on_rim:
                px[x, y] = pal["bone_mid"] if lit else pal["bone_shade"]
            elif mesh:
                px[x, y] = pal["bone"] if lit else pal["bone_shade"]
    for k in range(4):  # Lead weights on the rim.
        a = math.tau * k / 4 + 0.4
        wx, wy = int(round(c + math.cos(a) * r)), int(round(c + math.sin(a) * r))
        for dx in (0, 1):
            for dy in (0, 1):
                if 0 <= wx + dx < n and 0 <= wy + dy < n:
                    px[wx + dx, wy + dy] = pal["grey_dark"] if dx or dy else pal["grey"]
    outline(img, pal["ink_warm"])
    return img


def chain_link(pal: dict) -> Image.Image:
    """One rusted iron link, an oval ring along +x with a dark hole (lit top rust, shaded bottom)."""
    w, h = LINK_SIZE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        for x in range(w):
            ex = (x - (w - 1) / 2) / (w / 2)
            ey = (y - (h - 1) / 2) / (h / 2)
            d = ex * ex + ey * ey
            if d > 1.05:
                continue
            hole = 1 <= x <= w - 2 and y == (h - 1) // 2 and 2 <= x <= w - 3
            if hole:
                continue
            px[x, y] = pal["brown_light"] if y < h / 2 else pal["brown"]
    px[1, 1] = pal["bone_shade"]  # A glint on the lit shoulder.
    return img


def undertow_crest(pal: dict) -> Image.Image:
    """One foam crest of the Undertow wave, facing +x: a curling lip of foam (ice_light) on the
    outer side over a body of cool water (ice, arcane) trailing back into dark water, the segment
    tapering at both ends so neighbouring segments overlap into one rolling line."""
    dw, ln = CREST_SIZE
    img = Image.new("RGBA", (dw, ln), (0, 0, 0, 0))
    px = img.load()
    for y in range(ln):
        t = abs(y - (ln - 1) / 2) / (ln / 2)  # 0 at the middle of the segment, 1 at its ends.
        depth = int(round(dw * (1.0 - 0.55 * t * t)))  # How far back the water trails here.
        lip = dw - 1 - int(round(2 * t * t))  # Outer edge (the crest bulges forward in the middle).
        for x in range(lip - depth + 1, lip + 1):
            if x < 0:
                continue
            k = lip - x  # Px behind the lip.
            if k == 0:
                c = pal["ice_light"]
            elif k == 1:
                c = pal["ice_light"] if y % 3 else pal["ice"]
            elif k <= 3:
                c = pal["ice"]
            elif k <= 5:
                c = pal["arcane"]
            else:
                c = pal["arcane_dark"]
            px[x, y] = c
    return img


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="", help="output folder (default assets/sprites)")
    args = ap.parse_args()
    out = Path(args.out) if args.out else OUT_DIR
    pal = palette()
    sprites = {
        "structures/harbour_pier": pier(pal),
        "overlays/harbour_net": net(pal),
        "projectiles/anchor_chain_link": chain_link(pal),
        "overlays/undertow_crest": undertow_crest(pal),
    }
    for key, img in sprites.items():
        dest = out / (key + ".png")
        dest.parent.mkdir(parents=True, exist_ok=True)
        img.save(dest, optimize=True)
        print(f"{key}: {img.width}x{img.height} -> {dest}")


if __name__ == "__main__":
    main()
