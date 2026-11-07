#!/usr/bin/env python3
"""norse_tiles.py: draws the Hall of the Slain's floors, obstacles and small overlays on the art grid (deterministic, seeded).

Why (Act VI art, GDD 15.0 "Hall of the Slain art and audio"): floors must tile without a seam and obstacles must read at 1 art px = 1 screen px,
so they are drawn pixel by pixel from tools/palette.json colours (as tools/ark_tiles.py did for the Ark). Light from the top-left.

Outputs (assets/sprites/):
  tiles/norse_snow.png       128 x 128 seamless night snow with grass tufts, stones and drifts (the Barrow Fields: Longshore, Barrows, Jarl's Hall)
  tiles/norse_ice.png        128 x 128 seamless fjord ice with cracks (the Frozen Fjord, Vigrid's Frozen Sea)
  tiles/norse_planks.png     128 x 128 seamless hall planks with nail heads and a few ember specks (Valgard: Shield Yard / Mead Hall)
  tiles/norse_slabs.png      128 x 128 seamless hall slabs with joints and a carved rune border line (Valgard: Hall of Spears / Valkyries' Gate)
  tiles/norse_ash.png        128 x 128 seamless grey ash with ember specks (Vigrid: Ash Plain, Giants' March, the Field)
  obstacles/mound_s / mound_l (+ _v), barrow_closed, barrow_open, long_table_s / _l (+ _v), standing_shield_s / _l (+ _v), pine_s / pine_l
  norse/brazier_lit.png / brazier_doused.png 32 x 32 (Long Winter braziers), norse/frost_creep.png 128 x 48 (vignette frost edge)
  norse/einherjar_overlay.png 48 x 48 dithered pale-gold aura ring (drawn additively under / over an Einherjar), norse/valkyrie_shadow.png 40 x 20
      dithered gold ellipse (the dive telegraph shadow)
Usage (repo root):  python3 tools/norse_tiles.py [--out DIR]
"""
import argparse
import json
import random
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PAL = {c["name"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open(ROOT / "tools/palette.json"))["colors"]}
C = lambda n: PAL[n]  # noqa: E731  Colour by palette name.
INK = C("norse_ink")


def wrapnoise(n: int, cell: int, rng: random.Random) -> np.ndarray:
    """Seamless value noise n x n (0-1): random grid of n/cell points, bilinear-ish by smoothstep, wrapping."""
    g = np.array([[rng.random() for _ in range(n // cell)] for _ in range(n // cell)])
    out = np.zeros((n, n))
    for y in range(n):
        for x in range(n):
            gx, gy = x / cell, y / cell; x0, y0 = int(gx) % (n // cell), int(gy) % (n // cell)
            x1, y1 = (x0 + 1) % (n // cell), (y0 + 1) % (n // cell); fx, fy = gx - int(gx), gy - int(gy)
            fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
            out[y, x] = (g[y0, x0] * (1 - fx) + g[y0, x1] * fx) * (1 - fy) + (g[y1, x0] * (1 - fx) + g[y1, x1] * fx) * fy
    return out


def shade(noise, names, cuts):
    """Maps noise to three palette colours by thresholds `cuts` (2 values)."""
    n = noise.shape[0]; img = np.zeros((n, n, 4), dtype=np.uint8)
    for y in range(n):
        for x in range(n):
            v = noise[y, x]; img[y, x] = C(names[0] if v < cuts[0] else names[1] if v < cuts[1] else names[2])
    return img


def put(img, x, y, col):
    """Writes a pixel with wrapping (so details on a tile edge stay seamless)."""
    n = img.shape[0]; img[y % n, x % n] = col


def tile_snow(rng):
    nz = 0.6 * wrapnoise(128, 32, rng) + 0.4 * wrapnoise(128, 8, rng)
    img = shade(nz, ["norse_snow_dark", "norse_snow", "norse_snow_light"], (0.36, 0.62))
    for _ in range(26):  # dark grass tufts poking through the snow
        x, y = rng.randrange(128), rng.randrange(128)
        for dx, dy in ((0, 0), (1, 0), (0, -1), (-1, -1), (1, -2)): put(img, x + dx, y + dy, C("norse_pine_dark"))
    for _ in range(14):  # small stones
        x, y = rng.randrange(128), rng.randrange(128)
        for dx, dy, nm in ((0, 0, "norse_iron_dark"), (1, 0, "norse_iron_dark"), (0, -1, "norse_iron"), (1, -1, "norse_iron")): put(img, x + dx, y + dy, C(nm))
    return img


def tile_ice(rng):
    nz = 0.7 * wrapnoise(128, 32, rng) + 0.3 * wrapnoise(128, 16, rng)
    img = shade(nz, ["norse_ice_dark", "norse_ice", "norse_ice"], (0.4, 0.8))
    for _ in range(9):  # crack lines, random walks that wrap
        x, y = rng.randrange(128), rng.randrange(128); dx, dy = rng.choice([(1, 0), (0, 1), (1, 1), (1, -1)])
        for _ in range(rng.randrange(14, 34)):
            put(img, x, y, C("norse_ice_light")); put(img, x + 1, y + 1, C("norse_ice_dark"))
            x += dx; y += dy + (rng.random() < 0.25) * rng.choice([-1, 1])
            if rng.random() < 0.12: dx, dy = rng.choice([(1, 0), (0, 1), (1, 1), (1, -1)])
    return img


def tile_planks(rng):
    img = np.zeros((128, 128, 4), dtype=np.uint8)
    for r in range(0, 128, 16):  # 8 plank rows of 16 px, butt joints staggered
        base = rng.choice(["norse_plank", "norse_plank", "norse_plank_light"]); off = rng.randrange(128)
        for y in range(16):
            for x in range(128):
                col = "norse_plank_dark" if y in (0, 15) else base
                if y == 1: col = "norse_plank_light"
                if (x + off) % 64 == 0: col = "norse_plank_dark"
                if y not in (0, 1, 15) and rng.random() < 0.05: col = "norse_plank_dark"
                img[r + y, x] = C(col)
        for k in range(2): put(img, off + k * 64 + 3, r + 8, C("norse_iron_dark"))
    for _ in range(6): put(img, rng.randrange(128), rng.randrange(128), C("norse_hearth_dark"))
    return img


def tile_slabs(rng):
    img = np.zeros((128, 128, 4), dtype=np.uint8)
    nz = wrapnoise(128, 16, rng)
    for y in range(128):
        for x in range(128):
            v = nz[y, x]; img[y, x] = C("norse_slab_dark" if v < 0.3 else "norse_slab" if v < 0.75 else "norse_slab_light")
    for k in range(0, 128, 64):  # joints
        for i in range(128): put(img, i, k, C("norse_slab_dark")); put(img, k, i, C("norse_slab_dark")); put(img, i, k + 1, C("norse_slab_light")); put(img, k + 1, i, C("norse_slab_light"))
    for i in range(8, 56, 4): put(img, i, 32, C("norse_rune_dark")); put(img, 96, i + 8, C("norse_rune_dark"))  # faint carved rune line
    return img


def tile_ash(rng):
    nz = 0.5 * wrapnoise(128, 32, rng) + 0.5 * wrapnoise(128, 8, rng)
    img = shade(nz, ["norse_ash_dark", "norse_ash", "norse_ash_light"], (0.4, 0.66))
    for _ in range(18): put(img, rng.randrange(128), rng.randrange(128), C("norse_hearth_dark"))
    for _ in range(5): put(img, rng.randrange(128), rng.randrange(128), C("norse_hearth"))
    return img


# ---------- obstacles ----------
def outline(im):
    a = np.array(im); op = a[..., 3] > 0; out = a.copy(); h, w = op.shape
    for y in range(h):
        for x in range(w):
            if not op[y, x] and ((y > 0 and op[y - 1, x]) or (y < h - 1 and op[y + 1, x]) or (x > 0 and op[y, x - 1]) or (x < w - 1 and op[y, x + 1])): out[y, x] = INK
    return Image.fromarray(out)


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def ell(d, box, col): d.ellipse(box, fill=col)


def mound(w, h, rng):
    im = canvas(w, h); d = ImageDraw.Draw(im)
    ell(d, (1, h // 3, w - 2, h - 2), C("norse_pine_dark")); ell(d, (3, h // 3, w - 4, h - 5), C("norse_pine"))
    ell(d, (w // 4, h // 6, w * 3 // 4, h * 3 // 5), C("norse_frost_shade")); ell(d, (w // 4 + 1, h // 6, w * 3 // 4 - 3, h // 2), C("norse_frost"))
    for _ in range(w // 8): x, y = rng.randrange(3, w - 4), rng.randrange(h // 2, h - 4); d.rectangle((x, y, x + 1, y), fill=C("norse_iron"))
    return outline(im)


def barrow(w, h, openn):
    im = canvas(w, h); d = ImageDraw.Draw(im)
    ell(d, (1, 4, w - 2, h - 2), C("norse_pine_dark")); ell(d, (3, 4, w - 4, h - 6), C("norse_pine"))
    ell(d, (w // 5, 3, w * 4 // 5, h // 2), C("norse_frost_shade")); ell(d, (w // 5 + 1, 3, w * 4 // 5 - 3, h // 2 - 2), C("norse_frost"))
    dx0, dx1, dy0 = w // 2 - 7, w // 2 + 7, h - 18  # doorway of two uprights and a lintel
    d.rectangle((dx0 - 2, dy0 - 3, dx1 + 2, h - 3), fill=C("norse_iron_dark")); d.rectangle((dx0 - 2, dy0 - 3, dx1 + 2, dy0), fill=C("norse_iron"))
    if openn:
        d.rectangle((dx0, dy0 + 1, dx1, h - 3), fill=INK)
        for x in range(dx0 + 1, dx1, 3): d.rectangle((x, dy0 + 3, x + 1, h - 4), fill=C("norse_rune_dark"))
        d.rectangle((dx0 + 3, dy0 + 6, dx1 - 3, h - 4), fill=C("norse_rune"))
    else:
        d.rectangle((dx0, dy0 + 1, dx1, h - 3), fill=C("norse_iron")); d.line((w // 2, dy0 + 1, w // 2, h - 3), fill=C("norse_iron_dark"))
        d.rectangle((w // 2 - 2, dy0 + 6, w // 2 + 1, dy0 + 8), fill=C("norse_rune_dark"))  # a sealed rune
    return outline(im)


def table(w, h):
    im = canvas(w, h); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, 4), fill=C("norse_plank")); d.rectangle((0, h - 5, w - 1, h - 1), fill=C("norse_plank"))  # two benches
    d.rectangle((2, 7, w - 3, h - 8), fill=C("brown_light")); d.rectangle((2, 7, w - 3, 8), fill=C("norse_hearth_dark"))
    d.rectangle((2, h - 9, w - 3, h - 8), fill=C("brown"))
    for x in range(8, w - 8, 12): d.rectangle((x, 11, x + 2, 13), fill=C("norse_frost_shade")); d.rectangle((x + 5, h - 14, x + 6, h - 12), fill=C("norse_hearth"))  # cups, a candle
    return outline(im)


def shield_stand(w, h):
    im = canvas(w, h); d = ImageDraw.Draw(im)
    d.rectangle((w // 2 - 1, h // 2, w // 2, h - 2), fill=C("brown"))  # post
    ell(d, (1, 1, w - 2, h * 2 // 3), C("norse_iron")); ell(d, (3, 3, w - 4, h * 2 // 3 - 2), C("norse_pine"))
    for q in range(4): d.line((w // 2, h // 3, w // 2 + (q - 1.5) * w // 3, h // 3 + (q % 2) * 3), fill=C("brown_light"))
    ell(d, (w // 2 - 2, h // 3 - 2, w // 2 + 2, h // 3 + 2), C("norse_iron_light"))
    return outline(im)


def pine(w, h, rng):
    im = canvas(w, h); d = ImageDraw.Draw(im); cx = w // 2
    d.rectangle((cx - 1, h - 6, cx + 1, h - 1), fill=C("brown"))
    tiers = max(3, h // 12)
    for i in range(tiers):
        y1 = h - 5 - i * (h - 10) // tiers; y0 = y1 - (h - 10) // tiers - 5; half = (w // 2 - 1) * (tiers - i + 1) // (tiers + 1) + 2
        d.polygon([(cx, y0), (cx - half, y1), (cx + half, y1)], fill=C("norse_pine"))
        d.polygon([(cx, y0), (cx - half, y1), (cx - half // 2, y1), (cx, y0 + 4)], fill=C("norse_pine_dark"))
        d.polygon([(cx, y0), (cx - half // 2, y0 + (y1 - y0) // 2), (cx + half // 2, y0 + (y1 - y0) // 2)], fill=C("norse_frost_shade"))
        d.polygon([(cx, y0), (cx - half // 3, y0 + (y1 - y0) // 3), (cx + half // 3, y0 + (y1 - y0) // 3)], fill=C("norse_frost"))
    return outline(im)


def aura(n, ring):
    im = canvas(n, n); px = im.load(); c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            r = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / c
            if ring and 0.55 < r < 1.0:
                if r > 0.85: px[x, y] = C("norse_valk_dark") if (x + y) % 2 == 0 else (0, 0, 0, 0)
                elif r > 0.7: px[x, y] = C("norse_valk") if (x + y) % 2 == 0 else (0, 0, 0, 0)
                else: px[x, y] = C("norse_valk_glow") if (x + y) % 3 == 0 else (0, 0, 0, 0)
    return im


def shadow(w, h):
    im = canvas(w, h); px = im.load()
    for y in range(h):
        for x in range(w):
            r = (((x - (w - 1) / 2) / (w / 2)) ** 2 + ((y - (h - 1) / 2) / (h / 2)) ** 2) ** 0.5
            if r < 1 and (x + y) % 2 == 0 or r < 0.55: px[x, y] = C("norse_valk_dark")
    return im


def brazier(lit):
    """A 32 x 32 iron fire-bowl on three legs (the Long Winter's braziers): lit = hearth-amber flames, doused = cold ash and a smoke wisp."""
    im = canvas(32, 32); d = ImageDraw.Draw(im)
    for x in (9, 15, 22): d.rectangle((x, 22, x + 1, 30), fill=C("norse_iron_dark"))  # legs
    d.rectangle((7, 29, 24, 30), fill=C("norse_iron_dark"))
    d.polygon([(5, 17), (26, 17), (23, 24), (8, 24)], fill=C("norse_iron")); d.rectangle((5, 17, 26, 18), fill=C("norse_iron_light"))
    d.rectangle((9, 21, 22, 22), fill=C("norse_iron_dark"))
    if lit:
        d.polygon([(8, 17), (11, 8), (14, 13), (16, 3), (19, 12), (22, 7), (24, 17)], fill=C("norse_hearth_dark"))
        d.polygon([(11, 17), (13, 11), (16, 7), (19, 11), (21, 17)], fill=C("norse_hearth"))
        d.polygon([(14, 17), (16, 11), (18, 17)], fill=C("norse_hearth_glow"))
    else:
        d.rectangle((8, 15, 23, 17), fill=C("norse_iron_dark")); d.rectangle((10, 14, 21, 15), fill=C("norse_ash"))
        for x, y in ((12, 13), (16, 14), (19, 13)): d.point((x, y), fill=C("norse_ash_light"))
        for y, x in ((10, 16), (7, 17), (4, 16), (2, 17)): d.rectangle((x, y, x + 1, y + 1), fill=C("norse_iron"))  # a thin smoke wisp
    return outline(im)


def frost_creep():
    """128 x 48 tileable (horizontally) frost edge for the Long Winter's vignette: the top rows are solid frost, thinning into dithered
    crystals toward the bottom. The code rotates it for each screen edge; drawn flat (no screen read)."""
    w, h = 128, 48; rng = random.Random(77); im = canvas(w, h); px = im.load()
    reach = [int(10 + 20 * wrapnoise(w, 16, rng)[0, x]) for x in range(w)]  # per-column reach of the frost (seamless, from one noise row)
    for x in range(w):
        for y in range(h):
            if y < reach[x]:
                t = y / max(1, reach[x])  # 0 at the edge, 1 at the frost's tip
                keep = t < 0.35 or (t < 0.7 and (x + y) % 2 == 0) or (t < 1 and (x + 2 * y) % 5 == 0)
                if keep: px[x, y] = C("norse_frost") if t < 0.2 else C("norse_frost_shade") if t < 0.6 else C("norse_rune")
    for _ in range(14):  # ice spikes
        x = rng.randrange(w); L = rng.randrange(6, 14)
        for y in range(L): px[(x + (y // 5)) % w, min(h - 1, reach[x] + y - 4)] = C("norse_rune_glow") if y < 2 else C("norse_rune")
    return im


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default=str(ROOT / "assets/sprites")); out = Path(ap.parse_args().out)
    for sub in ("tiles", "obstacles", "norse"): (out / sub).mkdir(parents=True, exist_ok=True)
    rng = random.Random(61)
    for name, fn in (("snow", tile_snow), ("ice", tile_ice), ("planks", tile_planks), ("slabs", tile_slabs), ("ash", tile_ash)):
        Image.fromarray(fn(random.Random(hash(name) % 1000 if False else {"snow": 1, "ice": 2, "planks": 3, "slabs": 4, "ash": 5}[name]))).save(out / f"tiles/norse_{name}.png")
    obs = {"mound_s": mound(36, 24, rng), "mound_l": mound(56, 36, rng), "barrow_closed": barrow(48, 38, False), "barrow_open": barrow(48, 38, True),
           "long_table_s": table(48, 24), "long_table_l": table(72, 26), "standing_shield_s": shield_stand(24, 28), "standing_shield_l": shield_stand(36, 34),
           "pine_s": pine(24, 38, rng), "pine_l": pine(34, 52, rng)}
    for k, im in dict(obs).items():
        if k.startswith(("mound", "long_table", "standing_shield")): obs[k + "_v"] = im.rotate(90, expand=True) if k.startswith("long_table") else im.transpose(Image.FLIP_LEFT_RIGHT)
    for k, im in obs.items(): im.save(out / f"obstacles/{k}.png")
    brazier(True).save(out / "norse/brazier_lit.png"); brazier(False).save(out / "norse/brazier_doused.png"); frost_creep().save(out / "norse/frost_creep.png")
    aura(48, True).save(out / "norse/einherjar_overlay.png"); shadow(40, 20).save(out / "norse/valkyrie_shadow.png")
    print("wrote", len(obs), "obstacles, 5 tiles, 2 overlays to", out)


if __name__ == "__main__":
    main()
