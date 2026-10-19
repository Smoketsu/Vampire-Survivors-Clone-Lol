"""epilogue_panel.py: convert a wide AI scene into one epilogue picture panel (true pixel art).

Usage (from the repo root):
    python3 tools/epilogue_panel.py <source png> <panel id> [--y-bias F] [--x-bias F] [--drop RAMP,...]
    python3 tools/epilogue_panel.py --all          # rebuild every panel from art_source/epilogue/
    e.g. python3 tools/epilogue_panel.py art_source/epilogue/act1_1.png act1_1

Why a converter of its own (GDD §15.0 "Illustrated epilogue (content wave 2)", docs/art/ART_BIBLE.md
"Epilogue panels"): prepare_sprite.py rebuilds ONE figure on a transparent ground (outline, rim,
faction ramps, feet on the bottom row); a panel is a whole opaque scene edge to edge, and the menu
diorama's native-grid conversion (make_menu_art.py) would make it only ~350 art px wide, because the
AI draws its pixel blocks 4-5 source px wide. The epilogue shows its panels at the game's grid rule,
1 art px = 1 layout px through the sharp-pixel shader, in a picture window about 940 layout px wide, so
the panel must be PANEL_W x PANEL_H art px. Steps:
  1. The source (3:2, 1536 x 1024) is composited over ink_cold (the API may return soft alpha) and
     cropped to 16:9 (full width; the band's vertical place is --y-bias, 0 = top, 0.5 = centre, 1 =
     bottom; --x-bias likewise when the source is wider than 16:9).
  2. A 3 x 3 mode filter merges the AI's colour noise inside its pixel blocks (it keeps edges, unlike
     a blur), then a box downscale to PANEL_W x PANEL_H (1.5 source px per art px: each AI block
     becomes about 3 art px, so every shape is 2+ art px, the art bible's readability rule).
  3. Every pixel snaps (OKLab nearest, no dithering) to the locked palette (tools/palette.json),
     floors included (they are the scene's dark grounds); --drop removes whole ramps from the choice
     (a stray hue the scene does not want, e.g. --drop skin,ice).
  4. Cleanup (owner note "no busy specks"): CLEAN_PASSES times, a pixel that shares its colour with
     none of its 8 neighbours takes the most common neighbouring colour.
The output is assets/sprites/epilogue/<panel id>.png (opaque, palette-only). The source is copied to
art_source/epilogue/<panel id>.png when it is not there yet, so --all can rebuild everything.
Deterministic: the same source always gives the same panel.
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent  # Repo root.
SRC_DIR = ROOT / "art_source" / "epilogue"  # Kept AI sources (and their prompts).
OUT_DIR = ROOT / "assets" / "sprites" / "epilogue"  # Converted panels.
PANEL_W = 1024  # Panel width (art px = layout px). Must match EpilogueData.PANEL_ART.
PANEL_H = 576  # Panel height (art px), 16:9.
CLUSTERS = 128  # Median-cut colour clusters the scene is reduced to before the palette snap.
KMEANS = 3  # k-means refinement passes of those clusters (PIL quantize).
MODE_SIZE = 3  # Mode filter window (source px) applied before the downscale.
CLEAN_PASSES = 2  # Lone-pixel cleanup passes.
LONE_MAX_SAME = 1  # A pixel sharing its colour with at most this many of its 8 neighbours is a fleck...
MAJORITY_MIN = 4  # ...and takes the neighbours' majority colour when at least this many share it
#                   (a pixel with no same-coloured neighbour always does).
BACKGROUND = (15, 20, 28)  # ink_cold: what soft or missing alpha is composited over.
# Per-panel conversion options for --all (panel id -> extra arguments); kept here so a rebuild is exact.
PANEL_OPTS = {
    "act1_1": {"y_bias": 0.6, "drop": ["skin", "ice", "arcane", "biolume"]},  # Keep the relic on the floor.
    "act1_2": {"drop": ["skin", "ice"]},
    "act1_3": {"drop": ["skin", "ice"]},
    "act2_1": {"drop": ["skin", "ice"]},
    "act2_2": {"drop": ["skin", "ice"]},
    "act2_3": {"drop": ["skin", "ice"]},
    "act2_4": {"drop": ["skin", "ice"]},
    "close": {"drop": ["skin", "ice", "violet", "biolume"]},  # The holy orders: no necromancer violet.
}


def oklab(c: np.ndarray) -> np.ndarray:
    """OKLab of sRGB colours `c` (..., 3) in 0-255."""
    c = c / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    l = 0.4122214708 * c[..., 0] + 0.5363325363 * c[..., 1] + 0.0514459929 * c[..., 2]
    m = 0.2119034982 * c[..., 0] + 0.6806995451 * c[..., 1] + 0.1073969566 * c[..., 2]
    s = 0.0883024619 * c[..., 0] + 0.2817188376 * c[..., 1] + 0.6299787005 * c[..., 2]
    l, m, s = np.cbrt(l), np.cbrt(m), np.cbrt(s)
    return np.stack([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s], -1)


def palette(drop: set) -> np.ndarray:
    """(N, 3) uint8 sRGB of the locked palette's colours, minus the ramps in `drop`."""
    data = json.loads((ROOT / "tools" / "palette.json").read_text())
    cols = []
    for c in data["colors"]:
        if c["ramp"] in drop:
            continue
        h = c["hex"].lstrip("#")
        cols.append([int(h[i:i + 2], 16) for i in (0, 2, 4)])
    return np.array(cols, dtype=np.uint8)


def crop_16_9(img: Image.Image, x_bias: float, y_bias: float) -> Image.Image:
    """The largest 16:9 band of `img`, placed by the biases (0..1)."""
    w, h = img.size
    if w * 9 > h * 16:
        cw, ch = h * 16 // 9, h
    else:
        cw, ch = w, w * 9 // 16
    x = round((w - cw) * x_bias)
    y = round((h - ch) * y_bias)
    return img.crop((x, y, x + cw, y + ch))


def clean(idx: np.ndarray, n: int) -> np.ndarray:
    """Lone-pixel cleanup of the palette index map `idx` (H, W); `n` = palette size."""
    h, w = idx.shape
    offs = [(dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]  # The 8 neighbours.
    for _ in range(CLEAN_PASSES):
        pad = np.pad(idx, 1, mode="edge")
        nbs = np.stack([pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy, dx in offs])  # (8, H, W)
        lone = (nbs == idx[None]).sum(0) <= LONE_MAX_SAME
        ys, xs = np.nonzero(lone)
        out = idx.copy()
        for y, x in zip(ys, xs):
            cnt = np.bincount(nbs[:, y, x], minlength=n)
            if cnt.max() >= MAJORITY_MIN or cnt[idx[y, x]] == 0:
                out[y, x] = cnt.argmax()
        idx = out
    return idx


def convert(src: Path, panel: str, x_bias: float = 0.5, y_bias: float = 0.5, drop: set = frozenset(), clusters: int = 0) -> Path:
    """Converts `src` into assets/sprites/epilogue/<panel>.png and returns the output path."""
    img = Image.open(src).convert("RGBA")
    ground = Image.new("RGBA", img.size, BACKGROUND + (255,))
    img = Image.alpha_composite(ground, img).convert("RGB")
    img = crop_16_9(img, x_bias, y_bias)
    img = img.filter(ImageFilter.ModeFilter(MODE_SIZE))
    img = img.resize((PANEL_W, PANEL_H), Image.BOX)
    clusters = clusters or CLUSTERS
    pal = palette(set(drop))
    pal_lab = oklab(pal.astype(float))
    # Cluster first, then snap each cluster: neighbouring in-between colours fall into one cluster,
    # so a stone wall becomes one or two palette shades instead of a scatter of near-equal hues.
    q = img.quantize(colors=clusters, method=Image.Quantize.MEDIANCUT, kmeans=KMEANS, dither=Image.Dither.NONE)
    centres = np.array(q.getpalette()[:clusters * 3], dtype=float).reshape(-1, 3)
    d = ((oklab(centres)[:, None, :] - pal_lab[None, :, :]) ** 2).sum(-1)
    idx = clean(d.argmin(-1)[np.array(q)], len(pal))
    out = OUT_DIR / f"{panel}.png"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pal[idx]).save(out)
    keep = SRC_DIR / f"{panel}.png"
    if src.resolve() != keep.resolve():
        SRC_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, keep)
    used = len(np.unique(idx))
    print(f"{src} -> {out} ({PANEL_W}x{PANEL_H}, {used} palette colours)")
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", nargs="?")
    ap.add_argument("panel", nargs="?")
    ap.add_argument("--x-bias", type=float, default=0.5)
    ap.add_argument("--y-bias", type=float, default=0.5)
    ap.add_argument("--drop", default="", help="comma-separated palette ramps never used")
    ap.add_argument("--clusters", type=int, default=CLUSTERS, help="colour clusters before the palette snap")
    ap.add_argument("--all", action="store_true", help="rebuild every panel from art_source/epilogue/")
    a = ap.parse_args()
    if a.all:
        for src in sorted(SRC_DIR.glob("*.png")):
            o = PANEL_OPTS.get(src.stem, {})
            convert(src, src.stem, o.get("x_bias", 0.5), o.get("y_bias", 0.5), set(o.get("drop", [])),
                    o.get("clusters", CLUSTERS))
        return
    if not a.source or not a.panel:
        sys.exit(__doc__)
    convert(Path(a.source), a.panel, a.x_bias, a.y_bias, set(filter(None, a.drop.split(","))), a.clusters)


if __name__ == "__main__":
    main()
