"""bust_check.py: review sheet for a rig's bust box (owner's Act I-III art review, round 2: "bust boxes in the wrong place").

Usage (repo root): python3 tools/bust_check.py <out.png> <key> [<key> ...] [--scale N]
Per key one row: the still with the rig's `bust` box outlined in magenta (and the `bust_exclude` boxes in cyan), then every frame of
assets/sprites/<key>_idle.png and <key>_walk.png (when they exist) with the same outline, so the box can be judged against what the
bounce really moves. Box rows are drawn at the still's rows (the body dip moves them 0-1 px per frame). Reads RIGS from walk_cycle.py.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import walk_cycle as wc  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent  # Repo root.


def strip_frames(path: Path, w: int) -> list:
    """Splits a strip PNG into frames of width `w`."""
    im = Image.open(path).convert("RGBA")
    return [im.crop((i * w, 0, (i + 1) * w, im.height)) for i in range(im.width // w)]


def draw_one(im: Image.Image, rig: dict, sc: int) -> Image.Image:
    """One frame at `sc`x on a dark panel with the bust outline, cropped to the upper body (the bust box +-9 rows) so the bounce reads."""
    b = rig.get("bust")
    top = max(0, b[2] - 9) if b else 0  # First row shown.
    bot = min(im.height, b[3] + 10) if b else im.height  # Row after the last shown.
    left = max(0, b[0] - 7) if b else 0  # First column shown.
    right = min(im.width, b[1] + 7) if b else im.width  # Column after the last shown.
    im = im.crop((left, top, right, bot))
    p = Image.new("RGBA", (im.width * sc, im.height * sc), (36, 40, 44, 255))
    p.alpha_composite(im.resize((im.width * sc, im.height * sc), Image.NEAREST))
    d = ImageDraw.Draw(p)
    if b:
        d.rectangle([(b[0] - left) * sc, (b[2] - top) * sc, (b[1] - left) * sc - 1, (b[3] - top) * sc - 1], outline=(255, 0, 255, 255))
    for e in rig.get("bust_exclude", []) or []:
        d.rectangle([(e[0] - left) * sc, (e[2] - top) * sc, (e[1] - left) * sc - 1, (e[3] - top) * sc - 1], outline=(0, 220, 255, 70))
    return p


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("keys", nargs="+")
    ap.add_argument("--scale", type=int, default=7)
    a = ap.parse_args()
    rows = []
    for k in a.keys:
        rig = wc.RIGS[k]
        still = Image.open(ROOT / "assets/sprites" / (k + ".png")).convert("RGBA")
        panels = [draw_one(still, rig, a.scale)]
        for suf in ("_idle", "_walk"):
            f = ROOT / "assets/sprites" / (k + suf + ".png")
            if f.exists():
                frs = strip_frames(f, still.width)
                if suf == "_idle":
                    frs = frs[::3]  # Every third idle frame (24 -> 8) keeps the sheet readable.
                panels += [draw_one(fr, rig, a.scale) for fr in frs]
        w = sum(p.width + 3 for p in panels)
        # Wrap long rows: at most 9 panels a line.
        lines = [panels[i:i + 9] for i in range(0, len(panels), 9)]
        for ln in lines:
            r = Image.new("RGB", (sum(p.width + 3 for p in ln), ln[0].height + 2), (90, 90, 90))
            x = 0
            for p in ln:
                r.paste(p.convert("RGB"), (x, 1))
                x += p.width + 3
            rows.append(r)
        rows.append(Image.new("RGB", (10, 8), (0, 0, 0)))
    W = max(r.width for r in rows)
    out = Image.new("RGB", (W, sum(r.height for r in rows)), (0, 0, 0))
    y = 0
    for r in rows:
        out.paste(r, (0, y))
        y += r.height
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    out.save(a.out)
    print("wrote", a.out)


if __name__ == "__main__":
    main()
