"""ui_kit.py: draws Necropathy's pixel-art UI kit (9-slice frames) and finishes the title logo and app icon.

Art pass, docs/art/ART_BIBLE.md "UI kit and title logo". Usage (from the repo root):

    python3 tools/ui_kit.py frames [--preview sheet.png]   # every frame PNG -> assets/ui/
    python3 tools/ui_kit.py logo <converted.png>           # hand fixes -> assets/ui/logo.png
    python3 tools/ui_kit.py icon                           # assets/ui/logo.png -> assets/ui/icon.png

Frames. UI frames are drawn here by code instead of by the image AI: a 9-slice frame needs exact,
repeatable edges (the AI draws ornate, uneven borders that do not slice), and a ring of a few pixels
is easy to draw from the locked palette (tools/palette.json). Every frame is a square PNG of
2 * SLICE[kind] + CENTER texels (scripts/data/ui_art_data.gd, parsed below, so the game and this tool
agree on the margins): concentric 1-texel rings from the outside in, lit (one shade lighter) on the
top and left edges like the sprites, chamfered corners, small corner ornaments (bone studs, brackets),
then the flat fill. 1 texel = 1 layout px. File name: <kind>_<accent>_<state>.png.

Colours: rings, ornaments and outlines use palette colours only. The fills keep today's UI fill
colours (UiTheme.BG, BG_HOVER and the selected / evolution fills), which are UI-only darks between
the palette's ink and its first violet shade; sprites never use them.

Logo. The wordmark is an image-AI source converted with tools/prepare_sprite.py (grid mode, 90 art
px tall, --ramps violet,bone,soul --inside-outline --no-prune --no-levels --no-center --out <png>);
`logo` then applies the hand fixes listed in fix_logo() (the skull in the O redrawn symmetric with
soul-glow eye glints) and writes assets/ui/logo.png. The source is archived in art_source/ui/logo.png.

Icon. `icon` cuts the O (the pointed shield with the skull and its soul flame) out of the logo and
centres it on a dark violet badge: assets/ui/icon.png (project.godot config/icon), 64 art px drawn
at 2x = 128 px so the window manager scales it down cleanly.

Requires Pillow and numpy.
"""

import argparse
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixel_palette import Palette, hex_to_rgb  # noqa: E402  (tools/ sibling module)

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# Output folder of the kit (UiArtData.ROOT).
UI_DIR = ROOT / "assets" / "ui"
# Data file holding SLICE and CENTER (UiArtData), the 9-slice contract with the game.
UI_DATA = ROOT / "scripts" / "data" / "ui_art_data.gd"

# The locked palette: name -> (r, g, b).
PAL = {c["name"]: hex_to_rgb(c["hex"]) for c in Palette().colors}

# UI-only fill colours (opaque copies of today's UiTheme / screen fills; never used by sprites).
FILL = {
    "base": hex_to_rgb("#140D1F"),  # UiTheme.BG: panels and buttons.
    "hover": hex_to_rgb("#331C4D"),  # UiTheme.BG_HOVER: hovered button.
    "pressed": PAL["violet_deep"],  # UiTheme.BG_PRESSED (0.30, 0.16, 0.42) ~ violet_deep.
    "gold": hex_to_rgb("#3D2614"),  # Selected tile (pre-run SELECTED_BG, character picker, Hyper ON_BG).
    "gold_hover": hex_to_rgb("#4D311B"),  # Selected tile, hovered (lightened 0.08).
    "evo": hex_to_rgb("#2B1C0A"),  # Evolution card (level-up panel).
    "evo_hover": hex_to_rgb("#422B0F"),  # Evolution card, hovered.
    "evo_pressed": hex_to_rgb("#523814"),  # Evolution card, pressed.
    "crimson": hex_to_rgb("#420D14"),  # Active run modifier (pre-run ACTIVE_BG).
    "crimson_hover": hex_to_rgb("#58161E"),  # Active run modifier, hovered.
    "socket": hex_to_rgb("#0B0712"),  # HUD slot socket (recessed, darker than BG).
    "track": hex_to_rgb("#0B0712"),  # Scroll bar track.
}

# Ring colour sets per accent: (outline ink, (lit, shade) of the bright ring, (lit, shade) of the inner
# ring, ornament colours (light, mid, ink)). "hover" sets brighten the rings by one shade.
ACCENTS = {
    "violet": ("ink_violet", ("violet_glow", "violet"), ("violet", "violet_deep"), ("bone", "bone_mid", "ink_warm")),
    "violet_hover": ("ink_violet", ("violet_flare", "violet_glow"), ("violet_glow", "violet"), ("bone", "bone_mid", "ink_warm")),
    "violet_pressed": ("ink_violet", ("violet", "violet_glow"), ("violet_deep", "violet"), ("bone_mid", "bone_shade", "ink_warm")),
    "gold": ("ink_warm", ("gold_light", "gold"), ("gold", "brown_light"), ("gold_light", "gold", "ink_warm")),
    "gold_hover": ("ink_warm", ("holy_white", "gold_light"), ("gold_light", "gold"), ("holy_white", "gold_light", "ink_warm")),
    "gold_pressed": ("ink_warm", ("gold", "gold_light"), ("brown_light", "gold"), ("gold", "brown_light", "ink_warm")),
    "crimson": ("ink_red", ("crimson", "crimson_dark"), ("crimson_dark", "crimson_dark"), ("bone", "bone_mid", "ink_red")),
    "crimson_hover": ("ink_red", ("flame", "crimson"), ("crimson", "crimson_dark"), ("bone", "bone_mid", "ink_red")),
    "soul": ("ink_green", ("soul_glow", "soul"), ("soul", "soul_dark"), ("bone", "bone_mid", "ink_warm")),
    "soul_hover": ("ink_green", ("soul_glow", "soul_glow"), ("soul_glow", "soul"), ("bone", "bone_mid", "ink_warm")),
    "dim": ("ink_violet", ("violet_deep", "violet_deep"), ("ink_violet", "ink_violet"), ("bone_shade", "bone_shade", "ink_warm")),
    "dim_hover": ("ink_violet", ("violet", "violet_deep"), ("violet_deep", "violet_deep"), ("bone_mid", "bone_shade", "ink_warm")),
    "grey": ("ink_cold", ("grey", "grey_dark"), ("grey_dark", "grey_dark"), ("grey_light", "grey", "ink_cold")),
}

# Corner ornaments, drawn at the top-left corner and mirrored to the others: row strings, '.' = keep,
# 'L' / 'M' / 'K' = the accent's ornament light / mid / ink colour. Offsets are (x, y) of the top-left.
STUD = (["..K..",
         ".KLK.",
         "KLLMK",
         ".KMK.",
         "..K.."], (1, 1))  # Panel corner: a small bone stud on the chamfer.
BRACKET = (["KKKKKKK",
            "KLLLLMK",
            "KLKKKKK",
            "KLK....",
            "KLK....",
            "KMK....",
            "KKK...."], (3, 3))  # Card corner: an L-shaped bone bracket just inside the rings.
FOCUS_CORNER = (["LLLLL.",
                 "LLLLL.",
                 "LL....",
                 "LL....",
                 "LL....",
                 "......"], (0, 0))  # Focus ring corner: a thick soul-glow bracket.


def read_slices() -> tuple:
    """Parses CENTER and SLICE from scripts/data/ui_art_data.gd -> (center, {kind: margin})."""
    text = UI_DATA.read_text()
    center = int(re.search(r"const CENTER: int = (\d+)", text).group(1))  # Stretched centre texels.
    block = re.search(r"const SLICE: Dictionary = \{(.*?)\n\}", text, re.S).group(1)  # Dictionary body.
    slices = {k: int(v) for k, v in re.findall(r'"(\w+)": (\d+)', block)}  # kind -> margin.
    return center, slices


def ring_frame(n: int, rings: list, fill, chamfer: int, w: int = 0, h: int = 0) -> np.ndarray:
    """An n x n (or w x h) RGBA frame: rings[k] = (lit, shade) colour names / RGB or None (transparent)
    for the k-th 1-texel ring from the outside; pixels inside the rings get `fill` (RGB or None).
    Corners are cut diagonally `chamfer` texels deep. Lit = top and left edges."""
    w = w or n
    h = h or n
    img = np.zeros((h, w, 4), np.uint8)  # Output RGBA.
    for y in range(h):
        for x in range(w):
            dx = min(x, w - 1 - x)  # Distance to the nearer side edge.
            dy = min(y, h - 1 - y)  # Distance to the nearer top / bottom edge.
            dc = min(dx, dy, dx + dy - chamfer)  # Ring index with the chamfer.
            if dc < 0:
                continue
            if dc < len(rings):
                pair = rings[dc]
                if pair is None:
                    continue
                lit = (y < h / 2) if dy <= dx else (x < w / 2)  # Top or left edge.
                col = pair[0] if lit else pair[1]
            else:
                col = fill
                if col is None:
                    continue
            img[y, x] = (*_rgb(col), 255)
    return img


def _rgb(c) -> tuple:
    """Colour name or RGB tuple -> RGB tuple."""
    return PAL[c] if isinstance(c, str) else c


def stamp(img: np.ndarray, ornament: tuple, colours: tuple, corners: str = "all") -> None:
    """Draws `ornament` (rows, offset) at the frame's corners, mirrored. colours = (light, mid, ink)."""
    rows, (ox, oy) = ornament
    h, w = img.shape[:2]
    key = {"L": colours[0], "M": colours[1], "K": colours[2]}
    for flip_x in (False, True):
        for flip_y in (False, True):
            if corners == "top" and flip_y:
                continue
            for r, row in enumerate(rows):
                for c, ch in enumerate(row):
                    if ch == ".":
                        continue
                    x = ox + c
                    y = oy + r
                    x = w - 1 - x if flip_x else x
                    y = h - 1 - y if flip_y else y
                    # On the bottom corners (the shaded side) the ornament's light becomes its mid.
                    col = colours[1] if (flip_y and ch == "L") else key[ch]
                    img[y, x] = (*_rgb(col), 255)


def accent_rings(accent: str, inner_gap=True) -> tuple:
    """Rings for a button-like frame of `accent`: outline, bright ring, inner ring, inner ink gap."""
    ink, bright, inner, orn = ACCENTS[accent]
    rings = [(ink, ink), bright, inner]
    if inner_gap:
        rings.append((ink, ink))
    return rings, orn


def make_frames(center: int, slices: dict) -> dict:
    """Every kit PNG: file stem -> RGBA array."""
    out = {}
    # Buttons: chamfer 2, outline + 2-texel bevelled ring + ink gap, fill.
    n = 2 * slices["button"] + center
    for name, accent, fill in [
        ("violet_normal", "violet", FILL["base"]), ("violet_hover", "violet_hover", FILL["hover"]),
        ("violet_pressed", "violet_pressed", FILL["pressed"]), ("violet_disabled", "dim", FILL["base"]),
        ("gold_normal", "gold", FILL["gold"]), ("gold_hover", "gold_hover", FILL["gold_hover"]),
        ("crimson_normal", "crimson", FILL["crimson"]), ("crimson_hover", "crimson_hover", FILL["crimson_hover"]),
        ("soul_normal", "soul", FILL["base"]), ("soul_hover", "soul_hover", FILL["hover"]),
        ("dim_normal", "dim", FILL["base"]), ("dim_hover", "dim_hover", FILL["hover"]),
    ]:
        rings, _orn = accent_rings(accent)
        out["button_" + name] = ring_frame(n, rings, fill, 2)
    # Panels: chamfer 3, outline, two bevelled rings, ink gap, fill; bone studs on the corners.
    n = 2 * slices["panel"] + center
    for accent, fill in [("violet", FILL["base"]), ("gold", FILL["base"]), ("dim", FILL["socket"])]:
        ink, bright, inner, orn = ACCENTS[accent]
        rings = [(ink, ink), inner, bright, inner, (ink, ink)]
        img = ring_frame(n, rings, fill, 3)
        stamp(img, STUD, orn)
        out["panel_%s_normal" % accent] = img
    # Level-up cards: like panels plus L-shaped corner brackets.
    n = 2 * slices["card"] + center
    for accent, state, fill in [
        ("violet", "normal", FILL["base"]), ("violet_hover", "hover", FILL["hover"]),
        ("violet_pressed", "pressed", FILL["pressed"]),
        ("gold", "normal", FILL["evo"]), ("gold_hover", "hover", FILL["evo_hover"]),
        ("gold_pressed", "pressed", FILL["evo_pressed"]),
    ]:
        ink, bright, inner, orn = ACCENTS[accent]
        rings = [(ink, ink), inner, bright, inner, (ink, ink)]
        img = ring_frame(n, rings, fill, 3)
        stamp(img, BRACKET, ("bone", "bone_mid", ink))  # Bone brackets on every card (bone / violet look).
        out["card_%s_%s" % (accent.split("_")[0], state)] = img
    # Focus ring: drawn FOCUS_EXPAND (3) outside the control: a 3 px soul-teal ring (soul edge, two soul-glow
    # rows) around the control's own border, thick corner brackets; open centre.
    n = 2 * slices["focus"] + center
    img = ring_frame(n, [("soul", "soul"), ("soul_glow", "soul_glow"), ("soul_glow", "soul")], None, 2)
    stamp(img, FOCUS_CORNER, ("soul_glow", "soul_glow", "ink_green"))
    out["focus_soul_normal"] = img
    # HUD slot socket: recessed (lit bottom-right), dark fill.
    n = 2 * slices["slot"] + center
    out["slot_grey_normal"] = ring_frame(n, [("ink_cold", "ink_cold"), ("grey_dark", "grey"),
                                              ("ink_cold", "ink_cold")], FILL["socket"], 1)
    # HUD bar frame: outline + bevelled violet edge, open centre (the code fill shows through).
    n = 2 * slices["bar"] + center
    out["bar_violet_normal"] = ring_frame(n, [("ink_violet", "ink_violet"), ("violet", "violet_deep")], None, 1)
    # Tooltip: bone ring.
    n = 2 * slices["tip"] + center
    out["tip_bone_normal"] = ring_frame(n, [("ink_warm", "ink_warm"), ("bone", "bone_mid"),
                                             ("ink_violet", "ink_violet")], FILL["base"], 1)
    # Scroll bar track and grabber.
    n = 2 * slices["scroll"] + center
    out["scroll_violet_normal"] = ring_frame(n, [("ink_violet", "ink_violet"), ("violet_deep", "violet_deep")],
                                             FILL["track"], 1)
    n = 2 * slices["grab"] + center
    for state, ring, fill in [("normal", ("violet_glow", "violet_deep"), "violet"),
                              ("hover", ("violet_flare", "violet"), "violet_glow"),
                              ("pressed", ("violet", "violet_glow"), "violet_deep")]:
        out["grab_violet_%s" % state] = ring_frame(n, [("ink_violet", "ink_violet"), ring], fill, 1)
    # Separator: ink / violet / ink, with bone end dots.
    m = slices["line"]
    line = ring_frame(0, [("ink_violet", "ink_violet"), ("violet", "violet_deep")], "violet", 0,
                      w=2 * m + center, h=3)
    line[1, 0] = (*PAL["bone_mid"], 255)
    line[1, -1] = (*PAL["bone_mid"], 255)
    out["line_violet_normal"] = line
    # CheckButton toggles (32 x 16): a socket with a bone knob left (off) or a soul knob right (on).
    for state, on in [("off", False), ("on", True)]:
        tog = ring_frame(0, [("ink_violet", "ink_violet"), ("violet_deep", "violet") if not on else ("soul_dark", "soul"),
                             ("ink_violet", "ink_violet")], FILL["socket"] if not on else PAL["soul_dark"], 3, w=32, h=16)
        knob = ring_frame(0, [("ink_warm", "ink_warm"), ("bone", "bone_mid")], "bone_mid" if not on else "bone", 2,
                          w=12, h=12)
        x0 = 2 if not on else 18
        mask = knob[..., 3] > 0
        tog[2:14, x0:x0 + 12][mask] = knob[mask]
        out["toggle_%s" % state] = tog
    return out


def nine_slice(im: Image.Image, margin: int, w: int, h: int) -> Image.Image:
    """Stretches a 9-slice frame to w x h like Godot's StyleBoxTexture (corners kept, edges stretched)."""
    out = Image.new("RGBA", (w, h))
    sw, sh = im.size
    xs = [(0, margin, 0, margin), (margin, sw - margin, margin, w - margin), (sw - margin, sw, w - margin, w)]
    ys = [(0, margin, 0, margin), (margin, sh - margin, margin, h - margin), (sh - margin, sh, h - margin, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if dx1 > dx0 and dy1 > dy0:
                out.alpha_composite(im.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST), (dx0, dy0))
    return out


# Review sheet sizes (layout px) per frame kind: a typical on-screen size.
PREVIEW_SIZE = {"button": (150, 44), "panel": (150, 90), "card": (135, 170), "focus": (156, 50), "slot": (46, 46),
                "bar": (150, 18), "tip": (120, 30), "scroll": (10, 90), "grab": (10, 40), "line": (150, 3),
                "toggle": (32, 16)}


def preview(frames: dict, path: Path, slices: dict) -> None:
    """Writes a review sheet: every frame 9-sliced to a typical size, enlarged 3x, on the menu backdrop."""
    scale = 3
    cell_w, cell_h = 170, 190
    names = sorted(frames)
    cols = 6
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w * scale, rows * cell_h * scale), (8, 5, 13, 255))
    for i, name in enumerate(names):
        kind = name.split("_")[0]
        im = Image.fromarray(frames[name], "RGBA")
        if kind in slices:
            im = nine_slice(im, slices[kind], *PREVIEW_SIZE[kind])
        big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        sheet.alpha_composite(big, ((i % cols) * cell_w * scale + 10, (i // cols) * cell_h * scale + 10))
    sheet.save(path)


def fix_logo(src: Path, dst: Path) -> None:
    """Hand pixel fixes on the converted wordmark (palette colours only): the skull in the O is redrawn
    symmetric (the conversion left lopsided eye sockets) with a soul-glow glint in each eye socket."""
    im = Image.open(src).convert("RGBA")
    if im.size != (246, 90):
        raise SystemExit("logo: expected the 246 x 90 conversion, got %s" % (im.size,))
    key = {"a": "ink_violet", "i": "bone", "h": "bone_mid", "G": "soul_glow"}
    for y in range(44, 63):  # Clear the O's window to ink first.
        for x in range(107, 120):
            im.putpixel((x, y), (*PAL["ink_violet"], 255))
    skull = ["...iiiii...",
             ".iiiiiiiii.",
             "iiiiiiiiiih",
             "iiiiiiiiiih",
             "iiiiiiiiihh",
             "iaaaiiiaaah",
             "iaGaiiiaGah",
             "iaaaiiiaaah",
             "hiiiiaiiihh",
             ".hhiaaaihh.",
             "..hiiiiih..",
             "..iaiaiai..",
             "..hahahah..",
             "...hhhhh..."]
    for r, row in enumerate(skull):
        for c, ch in enumerate(row):
            if ch != ".":
                im.putpixel((108 + c, 46 + r), (*PAL[key[ch]], 255))
    im.save(dst)


def make_icon(logo: Path, dst: Path) -> None:
    """App icon: the logo's O (shield, skull, soul flame) on a dark violet badge, its flame rising over the
    badge's top edge. 64 x 64 art px, saved 2x (128 px). The O is cut out as the connected non-ink shape
    of the skull and the shield (so no bit of the R or the P comes along) and re-outlined in ink."""
    src = np.array(Image.open(logo).convert("RGBA"))
    ink = np.array(PAL["ink_violet"])
    crop = src[18:84, 99:130].copy()  # The O and the lower part of its flame (31 x 66).
    solid = (crop[..., 3] > 0) & (np.abs(crop[..., :3].astype(int) - ink).sum(-1) > 0)  # Coloured pixels.
    keep = np.zeros_like(solid)
    stack = [(30, 14), (32, 4)]  # Seeds: the skull (logo x 113, y 48) and the shield (logo x 103, y 50).
    while stack:
        y, x = stack.pop()
        if 0 <= y < solid.shape[0] and 0 <= x < solid.shape[1] and solid[y, x] and not keep[y, x]:
            keep[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    # Fill the O's window (ink between the skull and the shield) and outline everything 1 px in ink.
    rows = np.where(keep.any(1))[0]
    for y in rows:
        xs = np.where(keep[y])[0]
        keep[y, xs.min():xs.max() + 1] |= crop[y, xs.min():xs.max() + 1, 3] > 0
    grown = keep.copy()
    grown[1:] |= keep[:-1]
    grown[:-1] |= keep[1:]
    grown[:, 1:] |= keep[:, :-1]
    grown[:, :-1] |= keep[:, 1:]
    o = np.zeros_like(crop)
    o[keep] = crop[keep]
    o[grown & ~keep] = (*PAL["ink_violet"], 255)
    o_img = Image.fromarray(o, "RGBA")
    o_img = o_img.crop(o_img.getbbox())
    badge = ring_frame(0, [("ink_violet", "ink_violet"), ("violet", "violet_deep"), ("violet_deep", "ink_violet"),
                           ("ink_violet", "ink_violet")], FILL["base"], 5, w=60, h=54)
    stamp(badge, STUD, ACCENTS["violet"][3])
    canvas = Image.new("RGBA", (64, 64))
    canvas.alpha_composite(Image.fromarray(badge, "RGBA"), (2, 9))
    canvas.alpha_composite(o_img, ((64 - o_img.width) // 2, 60 - o_img.height))
    canvas.resize((128, 128), Image.NEAREST).save(dst)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", choices=("frames", "logo", "icon"))
    ap.add_argument("source", nargs="?", help="logo: the prepare_sprite.py conversion (246 x 90)")
    ap.add_argument("--preview", default="", help="frames: also write a review sheet here")
    args = ap.parse_args()
    UI_DIR.mkdir(parents=True, exist_ok=True)
    if args.command == "frames":
        center, slices = read_slices()
        frames = make_frames(center, slices)
        for name, arr in frames.items():
            Image.fromarray(arr, "RGBA").save(UI_DIR / (name + ".png"))
        print("wrote %d frame PNGs to %s" % (len(frames), UI_DIR))
        if args.preview:
            preview(frames, Path(args.preview), slices)
    elif args.command == "logo":
        if not args.source:
            raise SystemExit("logo: pass the converted PNG")
        fix_logo(Path(args.source), UI_DIR / "logo.png")
        print("wrote", UI_DIR / "logo.png")
    else:
        make_icon(UI_DIR / "logo.png", UI_DIR / "icon.png")
        print("wrote", UI_DIR / "icon.png")


if __name__ == "__main__":
    main()
