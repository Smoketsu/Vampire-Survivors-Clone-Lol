"""pixel_palette.py: the locked pixel-art palette (tools/palette.json) for the art tools.

Shared by tools/prepare_sprite.py (grid mode snaps sprites to the palette, draws
outlines and rim light from the ramps) and tools/art_check.py (off-palette and
lightness checks). Also renders the labelled swatch sheet the owner approves:

    python3 tools/pixel_palette.py --preview <out.png>

Colour maths: sRGB -> linear -> OKLab (Bjorn Ottosson's perceptual space).
OKLab L is perceptual lightness (0 = black, 1 = white); distances in OKLab are
roughly perceptual colour differences (0.02 is barely visible, 0.1 is a clear
step between two shades of a ramp).

Requires Pillow and numpy.
"""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# Repo root: this file lives in <root>/tools/.
ROOT = Path(__file__).resolve().parent.parent
# The palette's single source of truth (names, hex, ramps, roles).
PALETTE_JSON = ROOT / "tools" / "palette.json"

# Preview layout: one swatch's width and height (px).
SWATCH_W, SWATCH_H = 132, 64
# Preview layout: width (px) of the ramp-name column on the left.
LABEL_W = 260
# Preview layout: outer margin and gap between swatches (px).
PAD, GAP = 16, 8
# Preview text sizes (px): titles, swatch labels, small notes.
FONT_TITLE, FONT_LABEL, FONT_SMALL = 22, 14, 12
# Preview: side (px) of the small "unit on floor" sample squares shown under each ramp.
SAMPLE_PX = 18


def hex_to_rgb(hex_str: str) -> tuple:
    """'#RRGGBB' -> (r, g, b) ints 0-255."""
    h = hex_str.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def srgb_to_oklab(rgb: np.ndarray) -> np.ndarray:
    """Converts an (..., 3) array of sRGB values 0-255 to OKLab (..., 3): L 0-1, a, b about -0.4..0.4."""
    c = rgb.astype(np.float64) / 255.0  # sRGB 0-1.
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)  # Linear light 0-1.
    r, g, b = lin[..., 0], lin[..., 1], lin[..., 2]
    l_ = np.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)  # Cone response L.
    m_ = np.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)  # Cone response M.
    s_ = np.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)  # Cone response S.
    return np.stack([
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    ], axis=-1)


def oklab_to_srgb(lab) -> tuple:
    """Converts one OKLab colour (L, a, b) back to an (r, g, b) tuple of ints 0-255 (clipped)."""
    L, a, b = (float(v) for v in lab)
    l_ = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m_ = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s_ = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    lin = (4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
           -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
           -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_)
    out = []
    for c in lin:
        c = min(max(c, 0.0), 1.0)
        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        out.append(int(round(c * 255)))
    return tuple(out)


def oklab_l(rgb: tuple) -> float:
    """OKLab lightness (0-1) of one (r, g, b) colour 0-255."""
    return float(srgb_to_oklab(np.array(rgb, dtype=np.float64))[0])


class Palette:
    """The loaded palette: colours by index, their OKLab values, groups and ramps."""

    def __init__(self, path: Path = PALETTE_JSON):
        data = json.loads(Path(path).read_text())  # Parsed palette.json.
        self.colors = data["colors"]  # List of colour dicts (name, hex, ramp, index, group, role).
        self.names = [c["name"] for c in self.colors]  # Colour names by palette index.
        self.index_of = {n: i for i, n in enumerate(self.names)}  # Name -> palette index.
        self.rgb = np.array([hex_to_rgb(c["hex"]) for c in self.colors], dtype=np.uint8)  # (N, 3) sRGB.
        self.lab = srgb_to_oklab(self.rgb)  # (N, 3) OKLab.
        self.group = [c["group"] for c in self.colors]  # "ink" / "unit" / "glow" / "floor" per index.
        self.ramp = [c["ramp"] for c in self.colors]  # Primary ramp name per index.
        self.ramps = {k: [self.index_of[n] for n in v["members"]] for k, v in data["ramps"].items()}  # Ramp -> indices dark -> light.
        self.ramp_roles = {k: v.get("role", "") for k, v in data["ramps"].items()}  # Ramp -> role text.
        self.art_scale = int(data.get("art_scale", 2))  # Screen px per art px.
        self.rgb_lookup = {tuple(int(v) for v in self.rgb[i]): i for i in range(len(self.names))}  # (r,g,b) -> index.

    def sprite_indices(self) -> list:
        """Palette indices a sprite may use (everything but floor colours)."""
        return [i for i, g in enumerate(self.group) if g != "floor"]

    def floor_indices(self) -> list:
        """Palette indices of the floor colours."""
        return [i for i, g in enumerate(self.group) if g == "floor"]

    def outline_of(self, i: int) -> int:
        """Outline ink of colour `i`: the darkest member of its primary ramp."""
        return self.ramps[self.ramp[i]][0]

    def lighter_of(self, i: int) -> int:
        """Colour one step lighter than `i` in its primary ramp (itself at the top)."""
        members = self.ramps[self.ramp[i]]
        pos = members.index(i) if i in members else len(members) - 1
        return members[min(pos + 1, len(members) - 1)]

    def is_ink(self, i: int) -> bool:
        """True for an outline ink (or any ramp's darkest member)."""
        return self.group[i] == "ink"

    def snap(self, lab: np.ndarray, allowed: list, chroma_weight: float = 1.0) -> np.ndarray:
        """Nearest allowed palette index for each OKLab colour in `lab` (..., 3).
        `chroma_weight` scales the a/b axes (above 1 favours keeping hue over lightness)."""
        pal = self.lab[allowed]  # (K, 3) candidate colours.
        w = np.array([1.0, chroma_weight, chroma_weight])  # Axis weights.
        flat = lab.reshape(-1, 3)
        d = (((flat[:, None, :] - pal[None, :, :]) * w) ** 2).sum(-1)  # (P, K) squared distances.
        return np.array(allowed)[d.argmin(1)].reshape(lab.shape[:-1])


def _font(size: int) -> ImageFont.ImageFont:
    """Pillow's built-in scalable font at `size` px (bitmap fallback on old Pillow)."""
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def render_preview(out: Path) -> None:
    """Draws the labelled swatch sheet: one row per ramp (dark -> light) with each
    colour's name, hex and OKLab L, small unit-on-floor samples under each ramp,
    and a floor strip with the lightness of every floor."""
    pal = Palette()
    rows = [k for k in pal.ramps if k != "floor"]  # Ramp rows, palette order.
    max_len = max(len(pal.ramps[k]) for k in rows)  # Widest ramp (swatches).
    row_h = SWATCH_H + SAMPLE_PX + 3 * GAP  # Height of one ramp row (px).
    width = PAD * 2 + LABEL_W + max(max_len * (SWATCH_W + GAP), len(pal.ramps["floor"]) * (SWATCH_W * 2 + GAP))
    height = PAD * 2 + 60 + len(rows) * row_h + 150
    floor = tuple(int(v) for v in pal.rgb[pal.index_of["floor_soil"]])  # Sheet background.
    img = Image.new("RGB", (width, height), floor)
    d = ImageDraw.Draw(img)
    f_t, f_l, f_s = _font(FONT_TITLE), _font(FONT_LABEL), _font(FONT_SMALL)
    unit_count = len(pal.sprite_indices())  # Colours sprites may use.
    d.text((PAD, PAD), f"Necropathy locked palette: {len(pal.names)} colours ({unit_count} for sprites, "
           f"{len(pal.floor_indices())} floors). Ramps dark -> light; the first swatch is the ramp's outline ink.",
           fill=(230, 225, 210), font=f_t if width > 1100 else f_l)
    d.text((PAD, PAD + 30), "L = OKLab perceptual lightness (0-1). Shared colours (borrowed from another ramp) are marked *. "
           "Under each ramp: its colours as unit pixels on the three floors.", fill=(170, 170, 160), font=f_s)
    floors = [pal.index_of[n] for n in ("floor_soil", "floor_earth", "floor_stone")]  # Floor sample order.
    y = PAD + 60
    for k in rows:
        d.text((PAD, y + 4), k, fill=(235, 230, 215), font=f_t)
        d.multiline_text((PAD, y + 32), _wrap(pal.ramp_roles[k], 36), fill=(160, 160, 150), font=f_s)
        for j, i in enumerate(pal.ramps[k]):
            x = PAD + LABEL_W + j * (SWATCH_W + GAP)
            rgb = tuple(int(v) for v in pal.rgb[i])
            d.rectangle([x, y, x + SWATCH_W - 1, y + SWATCH_H - 1], fill=rgb, outline=(60, 60, 60))
            L = float(pal.lab[i][0])
            ink = (20, 20, 20) if L > 0.6 else (235, 235, 235)  # Readable label colour on the swatch.
            borrowed = "*" if pal.ramp[i] != k else ""
            d.text((x + 5, y + 4), pal.names[i] + borrowed, fill=ink, font=f_l)
            d.text((x + 5, y + 24), pal.colors[i]["hex"], fill=ink, font=f_s)
            d.text((x + 5, y + 42), f"L {L:.2f}  {pal.group[i]}", fill=ink, font=f_s)
            # Unit-on-floor samples: this colour as a 2x2 art-px block on each floor.
            for fi, fl in enumerate(floors):
                sx = x + fi * (SAMPLE_PX * 2 + 4)
                sy = y + SWATCH_H + GAP
                d.rectangle([sx, sy, sx + SAMPLE_PX * 2 + 1, sy + SAMPLE_PX], fill=tuple(int(v) for v in pal.rgb[fl]))
                d.rectangle([sx + SAMPLE_PX // 2, sy + 4, sx + SAMPLE_PX // 2 + SAMPLE_PX - 1, sy + SAMPLE_PX - 4], fill=rgb)
        y += row_h
    # Floor strip.
    d.text((PAD, y + 4), "floors", fill=(235, 230, 215), font=f_t)
    d.multiline_text((PAD, y + 32), _wrap(pal.ramp_roles["floor"], 36), fill=(160, 160, 150), font=f_s)
    for j, i in enumerate(pal.ramps["floor"]):
        x = PAD + LABEL_W + j * (SWATCH_W * 2 + GAP)
        rgb = tuple(int(v) for v in pal.rgb[i])
        d.rectangle([x, y, x + SWATCH_W * 2 - 1, y + 110], fill=rgb, outline=(70, 70, 70))
        d.text((x + 6, y + 6), f"{pal.names[i]}  {pal.colors[i]['hex']}  L {float(pal.lab[i][0]):.2f}",
               fill=(220, 220, 210), font=f_l)
        d.multiline_text((x + 6, y + 30), _wrap(pal.colors[i]["role"], 34), fill=(170, 170, 160), font=f_s)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"palette preview -> {out} ({width}x{height})")


def _wrap(text: str, width: int) -> str:
    """Greedy word wrap of `text` to lines of at most `width` characters."""
    lines, line = [], ""
    for word in text.split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = word
        else:
            line = (line + " " + word).strip()
    if line:
        lines.append(line)
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Necropathy pixel-art palette tools")
    parser.add_argument("--preview", metavar="OUT_PNG", help="render the labelled swatch sheet to OUT_PNG")
    args = parser.parse_args()
    if args.preview:
        render_preview(Path(args.preview))
    else:
        pal = Palette()
        for k, members in pal.ramps.items():
            print(f"{k:8s} " + "  ".join(f"{pal.names[i]} {pal.colors[i]['hex']} L{pal.lab[i][0]:.2f}" for i in members))


if __name__ == "__main__":
    main()
