"""art_check.py: the art-pass check sheet for one sprite (docs/art/ART_BIBLE.md "Workflow").

Usage (from the repo root):
    python3 tools/art_check.py <sprite key> [--out DIR] [--png FILE] [--no-render]
    e.g. python3 tools/art_check.py player/necromancer

Produces <out>/<key with / as _>_check.png, one image that shows the asset:
  * at its real in-game size, DRAWN BY THE GAME (SpriteBank, nearest filtering)
    on each stage's real floor: the Graveyard, the 4 Crimson March zones and
    the 4 Sanctum zones (Ground / MarchGround / SanctumGround), next to the
    necromancer, a Skeleton Warrior and a Covenant Recruit for scale, at the
    Normal (x1) and Close (x1.5) zooms;
  * as a 4x nearest-neighbour zoom, a greyscale copy (value check) and a solid
    black silhouette (shape check);
  * with the rule checks in text (also printed, exit code 1 on any FAIL):
      height     = SpriteData.HEIGHTS[key] / ART_SCALE art px exactly;
      alpha      fully opaque or fully transparent pixels only;
      palette    every pixel one of tools/palette.json's sprite colours;
      feet       the bottom row holds the feet (an opaque pixel);
      lightness  the main shape (opaque, non-outline pixels; median OKLab L)
                 at least MIN_DELTA_L above each floor (the Sanctum and March
                 floors are read from the stage data, the Graveyard's from Palette);
      faction    violet only on the player (warning), glow colours sparing
                 (warning), no floor colours (warning), single-pixel specks
                 (warning).

Rendering: the project is copied to a scratch folder (WORK_DIR, reused so only
changed files are re-imported), this tool's Godot scene (tools/art_check/,
ignored by Godot in the real project through tools/.gdignore, so it never ships
and never affects --import) is copied in as res://_art_check/, the sprite is
placed at assets/sprites/<key>.png there (from --png, default the repo's file),
then `godot --headless --import` and, under xvfb with the OpenGL renderer,
`godot res://_art_check/art_check.tscn -- --key=K --out=DIR` render the panels.
--no-render skips Godot (the detail views and checks only).

Requires Pillow and numpy; rendering needs the Godot 4.3 binary (GODOT env var,
GODOT_DEFAULT, or `godot` on the PATH) and xvfb-run.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixel_palette import Palette, srgb_to_oklab  # noqa: E402  (tools/ sibling module)

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# The Godot check scene's folder (copied into the scratch project as res://_art_check/).
SCENE_DIR = ROOT / "tools" / "art_check"
# Folder name of the check scene inside the scratch project.
SCENE_RES_DIR = "_art_check"
# Data files read for the sprite heights and the floor colours.
SPRITE_DATA = ROOT / "scripts" / "data" / "sprite_data.gd"
PALETTE_GD = ROOT / "scripts" / "data" / "palette.gd"
MARCH_GD = ROOT / "scripts" / "data" / "stages" / "crimson_march_stage.gd"
SANCTUM_GD = ROOT / "scripts" / "data" / "stages" / "sanctum_stage.gd"
# Godot binary used when neither --godot nor the GODOT env var is set (cloud sessions).
GODOT_DEFAULT = "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64"
# Scratch project copy (reused between runs so Godot only re-imports what changed).
WORK_DIR = Path(tempfile.gettempdir()) / "gravebound_art_check"
# Default output folder for the sheets.
OUT_DIR = Path(tempfile.gettempdir()) / "gravebound_art_check_out"
# Screen px per art px when sprite_data.gd has no ART_SCALE (GDD 15.0: 2).
DEFAULT_ART_SCALE = 2
# Top-level entries of the repo never copied into the scratch project.
SKIP_TOP = {".git", ".godot", ".github", "art_source", "docs", "tools", "build", "export", ".claude"}
# Minimum OKLab L gap (0-1) between the main shape's median lightness and a floor.
MIN_DELTA_L = 0.15
# Glow colours above this share (0-1) of a non-player, non-boss sprite are flagged.
GLOW_MAX_SHARE = 0.04
# Key folders allowed violet (the player's colour) and glow without a warning.
VIOLET_OK = ("player/", "icons/", "projectiles/", "effects/")
GLOW_OK = ("player/", "bosses/", "icons/", "projectiles/", "effects/")
# Single-pixel specks (a lit pixel whose colour no 4-neighbour shares) above this
# share (0-1) of the body are flagged ("nothing smaller than 2 art px").
SPECK_MAX_SHARE = 0.12
# Sheet layout: the detail views' zoom is the largest whole number (DETAIL_ZOOM_MIN to
# DETAIL_ZOOM_MAX) that keeps the sprite's longer side within DETAIL_PX.
DETAIL_ZOOM_MIN, DETAIL_ZOOM_MAX, DETAIL_PX = 2, 10, 300
# Sheet layout: margins (px) and text sizes (px).
PAD = 14
FONT_H1, FONT_TEXT, FONT_SMALL = 22, 15, 12
# Sheet colours: background, text, dim text, PASS / FAIL / WARN.
BG = (12, 13, 15)
TEXT = (232, 228, 214)
DIM = (150, 150, 140)
COL = {"PASS": (110, 210, 120), "FAIL": (240, 80, 80), "WARN": (240, 190, 70), "INFO": (150, 170, 200)}
# Seconds allowed for the Godot import and render steps.
IMPORT_TIMEOUT, RENDER_TIMEOUT = 600, 180


def _font(size: int) -> ImageFont.ImageFont:
    """Pillow's built-in scalable font at `size` px."""
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def _gd_color(text: str) -> tuple:
    """'Color(r, g, b[, a])' floats 0-1 -> (r, g, b) ints 0-255."""
    vals = [float(v) for v in re.findall(r"[0-9.]+", text)[:3]]
    return tuple(int(round(v * 255)) for v in vals)


def floors() -> list:
    """The stage floors to check against: [(label, (r, g, b))], read from the game data."""
    out = []
    m = re.search(r"const GROUND\s*:?=\s*(Color\([^)]*\))", PALETTE_GD.read_text())
    out.append(("Graveyard soil", _gd_color(m.group(1))))
    for path, stage in ((MARCH_GD, "March"), (SANCTUM_GD, "Sanctum")):
        text = path.read_text()
        zones = re.findall(r'"numeral": "([IV]+)", "name": "([^"]+)".*?"ground": \{(.*?)\}', text, re.S)
        for numeral, name, ground in zones:
            base = re.search(r'"base": (Color\([^)]*\))', ground)
            out.append((f"{stage} {numeral} {name}", _gd_color(base.group(1))))
            road = re.search(r'"road": (Color\([^)]*\))', ground)
            if road:
                out.append((f"{stage} {numeral} road", _gd_color(road.group(1))))
    return out


def sprite_height(key: str):
    """SpriteData.HEIGHTS[key] (screen px), or None when the key is not listed."""
    m = re.search(r'"%s"\s*:\s*([0-9.]+)' % re.escape(key), SPRITE_DATA.read_text())
    return float(m.group(1)) if m else None


def art_scale() -> int:
    """Screen px per art px: SpriteData.ART_SCALE if defined, else DEFAULT_ART_SCALE."""
    m = re.search(r"const\s+ART_SCALE\s*(?::\s*\w+)?\s*:?=\s*([0-9.]+)", SPRITE_DATA.read_text())
    return int(float(m.group(1))) if m else DEFAULT_ART_SCALE


def run_checks(key: str, img: Image.Image, pal: Palette) -> list:
    """Rule checks on the art PNG. Returns [(status, text)], status PASS / FAIL / WARN / INFO."""
    res = []
    rgba = np.asarray(img.convert("RGBA"))
    a = rgba[..., 3]
    h, w = a.shape
    # Height.
    screen = sprite_height(key)
    scale = art_scale()
    if screen is None:
        res.append(("WARN", f"height: {key} is not in SpriteData.HEIGHTS (drawn {44} px tall by default); art is {h} px"))
    else:
        want = screen / scale
        ok = abs(h - want) < 1e-6  # Exact art height.
        res.append(("PASS" if ok else "FAIL", f"height: {h} art px (HEIGHTS {screen:g} / ART_SCALE {scale} = {want:g})"
                    + ("" if ok else " -> wrong height: re-run prepare_sprite.py")))
    res.append(("INFO", f"size: {w}x{h} art px, {w * scale}x{h * scale} on screen at x1" + ("" if w % 2 == 0 else " (odd width)")))
    # Alpha.
    semi = int(((a > 0) & (a < 255)).sum())
    res.append(("PASS" if semi == 0 else "FAIL", f"alpha: {semi} semi-transparent pixel(s)" + ("" if semi == 0 else " (must be 0 or 255)")))
    on = a == 255
    if not on.any():
        res.append(("FAIL", "the image is empty"))
        return res
    # Palette.
    colors = [tuple(int(v) for v in p) for p in rgba[on][:, :3]]
    idx = np.array([pal.rgb_lookup.get(c, -1) for c in colors])
    off = int((idx < 0).sum())
    offhex = sorted({"#%02X%02X%02X" % c for c, i in zip(colors, idx) if i < 0})[:6]
    res.append(("PASS" if off == 0 else "FAIL", f"palette: {off} off-palette pixel(s)" + (f" e.g. {', '.join(offhex)}" if off else "")
                + f"; {len(set(idx[idx >= 0].tolist()))} palette colours used"))
    # Feet.
    res.append(("PASS" if on[-1].any() else "FAIL", "feet: the bottom row is " + ("opaque (feet on the last row)" if on[-1].any() else "empty (feet must touch the last row)")))
    # Main-shape lightness vs every floor.
    lab = srgb_to_oklab(rgba[on][:, :3])
    body = np.array([i < 0 or pal.group[i] != "ink" for i in idx])
    body_l = float(np.median(lab[body][:, 0])) if body.any() else 0.0
    for label, rgb in floors():
        fl = float(srgb_to_oklab(np.array(rgb))[0])
        delta = body_l - fl
        res.append(("PASS" if round(delta, 2) >= MIN_DELTA_L else "FAIL",
                    f"lightness on {label}: main shape L {body_l:.2f} vs floor L {fl:.2f} ({delta:+.2f}, need +{MIN_DELTA_L})"))
    # Faction and detail warnings.
    known = idx[idx >= 0]
    violet = int(sum(1 for i in known if pal.ramp[i] == "violet"))
    if violet and not key.startswith(VIOLET_OK):
        res.append(("WARN", f"faction: {violet} violet pixel(s); violet is reserved for the player"))
    glow = int(sum(1 for i in known if pal.group[i] == "glow"))
    if glow > GLOW_MAX_SHARE * on.sum() and not key.startswith(GLOW_OK):
        res.append(("WARN", f"glow: {glow} glow pixel(s) ({glow / on.sum():.0%}); glow is for the player, spells, telegraphs, elites, bosses"))
    flo = int(sum(1 for i in known if pal.group[i] == "floor"))
    if flo and not key.startswith("tiles/"):
        res.append(("WARN", f"floor colours: {flo} pixel(s) use floor colours (they vanish on the ground)"))
    full = np.full(on.shape, -1)
    full[on] = idx
    specks = 0
    for y, x in zip(*np.nonzero(on)):
        c = full[y, x]
        if c < 0 or pal.group[c] == "ink":
            continue
        if not any(0 <= y + dy < h and 0 <= x + dx < w and full[y + dy, x + dx] == c for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))):
            specks += 1
    share = specks / max(1, int(body.sum()))
    res.append(("WARN" if share > SPECK_MAX_SHARE else "PASS",
                f"detail: {specks} single-pixel speck(s) ({share:.0%} of the body; nothing under 2 art px, eyes and glints excepted)"))
    return res


def godot_binary(arg: str) -> str:
    """The Godot binary: --godot, $GODOT, GODOT_DEFAULT, or `godot` on the PATH."""
    for cand in (arg, os.environ.get("GODOT", ""), GODOT_DEFAULT, shutil.which("godot") or ""):
        if cand and Path(cand).exists():
            return cand
    return ""


def sync_project(work: Path, key: str, png: Path) -> Path:
    """Mirrors the repo into `work`/project (skipping SKIP_TOP and .godot), adds
    the check scene and the sprite under test, and returns the project path."""
    proj = work / "project"
    proj.mkdir(parents=True, exist_ok=True)
    wanted = set()  # Relative paths that should exist in the copy.
    for src in ROOT.rglob("*"):
        rel = src.relative_to(ROOT)
        if rel.parts[0] in SKIP_TOP or ".godot" in rel.parts or src.is_dir():
            continue
        wanted.add(rel)
        dst = proj / rel
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime or dst.stat().st_size != src.stat().st_size:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    # The check scene.
    for src in SCENE_DIR.iterdir():
        rel = Path(SCENE_RES_DIR) / src.name
        wanted.add(rel)
        (proj / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, proj / rel)
    # The sprite under test.
    rel = Path("assets") / "sprites" / (key + ".png")
    wanted.add(rel)
    wanted.add(rel.with_name(rel.name + ".import"))
    dst = proj / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists() or dst.read_bytes() != png.read_bytes():
        shutil.copyfile(png, dst)
    # Remove files of earlier runs (another key's test sprite) but keep Godot's .import sidecars.
    for f in list(proj.rglob("*")):
        rel_f = f.relative_to(proj)
        if f.is_file() and rel_f.parts[0] != ".godot" and rel_f not in wanted and not f.name.endswith(".import"):
            f.unlink()
            imp = f.with_name(f.name + ".import")
            if imp.exists():
                imp.unlink()
    # Its own user:// folder, so the check never reads or writes the real save.
    cfg = proj / "project.godot"
    text = cfg.read_text()
    if 'config/name="Gravebound"' in text:
        cfg.write_text(text.replace('config/name="Gravebound"', 'config/name="GraveboundArtCheck"'))
    return proj


def render(key: str, png: Path, godot: str, work: Path, panel_dir: Path) -> list:
    """Renders the floor panels with Godot. Returns [] on failure (the sheet says why)."""
    proj = sync_project(work, key, png)
    shutil.rmtree(panel_dir, ignore_errors=True)
    panel_dir.mkdir(parents=True)
    imp = subprocess.run([godot, "--headless", "--path", str(proj), "--import"], capture_output=True, text=True, timeout=IMPORT_TIMEOUT)
    errors = [ln for ln in (imp.stdout + imp.stderr).splitlines() if "ERROR" in ln]
    if errors:
        print("import errors in the scratch project:\n  " + "\n  ".join(errors[:10]))
    cmd = ["xvfb-run", "-a", "-s", "-screen 0 1280x720x24", godot, "--path", str(proj), "--rendering-driver", "opengl3",
           "--audio-driver", "Dummy", "--resolution", "1280x720", f"res://{SCENE_RES_DIR}/art_check.tscn",
           "--", f"--key={key}", f"--out={panel_dir}"]
    run = subprocess.run(cmd, capture_output=True, text=True, timeout=RENDER_TIMEOUT)
    log = run.stdout + run.stderr
    bad = [ln for ln in log.splitlines() if "SCRIPT ERROR" in ln or ("ERROR" in ln and "art_check" in ln)]
    if run.returncode != 0 or bad:
        print("render failed:\n  " + "\n  ".join((bad or log.splitlines())[-15:]))
    return sorted(panel_dir.glob("panel_*.png"))


def floor_label(panel_id: str) -> str:
    """Panel id (e.g. 'march2') -> a short floor label."""
    names = {"graveyard": "Graveyard"}
    for path, stage, pre in ((MARCH_GD, "March", "march"), (SANCTUM_GD, "Sanctum", "sanctum")):
        zones = re.findall(r'"numeral": "([IV]+)", "name": "([^"]+)"', path.read_text())
        for i, (num, name) in enumerate(zones):
            names[f"{pre}{i + 1}"] = f"{stage} {num}: {name.removeprefix('The ')}"
    return names.get(panel_id, panel_id)


def compose(key: str, img: Image.Image, checks: list, panels: list, note: str, out: Path) -> None:
    """Lays out the check sheet: title, the Normal and Close panel grids, the
    detail views and the checks."""
    f1, ft, fs = _font(FONT_H1), _font(FONT_TEXT), _font(FONT_SMALL)
    by = {p.stem.removeprefix("panel_"): Image.open(p).convert("RGB") for p in panels}
    order = ["graveyard", "march1", "march2", "march3", "march4", "sanctum1", "sanctum2", "sanctum3", "sanctum4"]
    sections = []  # (title, [(label, image)])
    for zl, title in (("x1", "Normal zoom x1 (1 art px = 2 screen px)"), ("x1.5", "Close zoom x1.5 (1 art px = 3 screen px)")):
        items = [(floor_label(o), by[f"{o}_{zl}"]) for o in order if f"{o}_{zl}" in by]
        if items:
            sections.append((title, items))
    # Detail views.
    z = max(DETAIL_ZOOM_MIN, min(DETAIL_ZOOM_MAX, DETAIL_PX // max(img.width, img.height)))
    rgba = img.convert("RGBA")
    big = rgba.resize((img.width * z, img.height * z), Image.NEAREST)
    grey = Image.merge("RGBA", (*[rgba.convert("L")] * 3, rgba.getchannel("A"))).resize(big.size, Image.NEAREST)
    sil = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    sil.paste((0, 0, 0, 255), mask=rgba.getchannel("A"))
    sil = sil.resize(big.size, Image.NEAREST)
    details = [(f"{z}x zoom (art px)", big, (22, 26, 28)), ("greyscale (values)", grey, (22, 26, 28)), ("silhouette", sil, (200, 200, 196))]
    # Measure.
    cols = 3
    sec_sizes = []
    for _, items in sections:
        cw = max(im.width for _, im in items)
        ch = max(im.height for _, im in items)
        sec_sizes.append((cw, ch))
    probe = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    text_w = max(probe.textlength(t, font=ft) for _, t in checks) + 52 + PAD * 2  # Widest check line (px).
    width = int(max([PAD * 2 + cols * (cw + PAD) for cw, _ in sec_sizes] + [PAD * 2 + sum(d[1].width + 8 + PAD for d in details) + text_w]))
    line_h = FONT_TEXT + 6
    detail_h = max(max(d[1].height for d in details) + 30, len(checks) * line_h + 40)
    height = PAD + 40 + sum(30 + ((len(items) + cols - 1) // cols) * (ch + 24) for (_, items), (_, ch) in zip(sections, sec_sizes)) + detail_h + PAD * 2
    if note:
        height += 30
    sheet = Image.new("RGB", (width, height), BG)
    d = ImageDraw.Draw(sheet)
    fails = sum(1 for s, _ in checks if s == "FAIL")
    warns = sum(1 for s, _ in checks if s == "WARN")
    verdict = "PASS" if not fails else "FAIL"
    d.text((PAD, PAD), f"{key}  -  {verdict}  ({fails} fail, {warns} warning)", fill=COL[verdict], font=f1)
    y = PAD + 40
    if note:
        d.text((PAD, y - 6), note, fill=COL["WARN"], font=ft)
        y += 30
    for (title, items), (cw, ch) in zip(sections, sec_sizes):
        d.text((PAD, y), title + "  -  left: the asset; then the necromancer, a Skeleton Warrior, a Covenant Recruit (their current art or glyph)",
               fill=TEXT, font=ft)
        y += 30
        for i, (label, im) in enumerate(items):
            cx = PAD + (i % cols) * (cw + PAD)
            cy = y + (i // cols) * (ch + 24)
            d.text((cx, cy), label, fill=DIM, font=fs)
            sheet.paste(im, (cx, cy + 16))
        y += ((len(items) + cols - 1) // cols) * (ch + 24)
    # Detail views and checks.
    x = PAD
    for label, im, bg in details:
        d.text((x, y + 4), label, fill=DIM, font=fs)
        box = Image.new("RGB", (im.width + 8, im.height + 8), bg)
        box.paste(im, (4, 4), im)
        sheet.paste(box, (x, y + 22))
        x += box.width + PAD
    cy = y + 4
    for status, text in checks:
        d.text((x + PAD, cy), f"{status:4s}", fill=COL[status], font=ft)
        d.text((x + PAD + 52, cy), text, fill=TEXT, font=ft)
        cy += line_h
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)


def main() -> None:
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument("key", help="sprite key, e.g. player/necromancer")
    parser.add_argument("--out", default=str(OUT_DIR), help="folder for the check sheet")
    parser.add_argument("--png", default="", help="art PNG to check (default assets/sprites/<key>.png)")
    parser.add_argument("--no-render", action="store_true", help="skip the Godot floor panels")
    parser.add_argument("--godot", default="", help="Godot 4.3 binary")
    parser.add_argument("--work", default=str(WORK_DIR), help="scratch folder for the project copy")
    args = parser.parse_args()
    key = args.key.strip("/").removesuffix(".png")
    png = Path(args.png).expanduser() if args.png else ROOT / "assets" / "sprites" / (key + ".png")
    if not png.exists():
        sys.exit(f"no art at {png}; run tools/prepare_sprite.py first or pass --png")
    pal = Palette()
    img = Image.open(png)
    checks = run_checks(key, img, pal)
    out_dir = Path(args.out).expanduser().resolve()
    panels, note = [], ""
    if not args.no_render:
        godot = godot_binary(args.godot)
        if not godot or not shutil.which("xvfb-run"):
            note = "Floor panels skipped: Godot 4.3 or xvfb-run not found (set GODOT=<binary>)."
        else:
            panels = render(key, png.resolve(), godot, Path(args.work).expanduser().resolve(), out_dir / "panels" / key.replace("/", "_"))
            if not panels:
                note = "Floor panels failed to render (see the console output)."
    else:
        note = "Floor panels skipped (--no-render)."
    sheet = out_dir / (key.replace("/", "_") + "_check.png")
    compose(key, img, checks, panels, note, sheet)
    for status, text in checks:
        print(f"{status:4s} {text}")
    print(f"check sheet -> {sheet}")
    sys.exit(1 if any(s == "FAIL" for s, _ in checks) else 0)


if __name__ == "__main__":
    main()
