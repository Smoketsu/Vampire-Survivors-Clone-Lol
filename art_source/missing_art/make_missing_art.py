#!/usr/bin/env python3
"""make_missing_art.py: the "missing art round" (Nov 2026, audit docs/art/MISSING_ART.md).

Draws, ON THE ART GRID (1 art px = 1 screen px), in the locked palette (tools/palette.json), deterministically
(a fixed integer hash, no RNG, no image generation, so zero API cost), the pieces the audit found still drawn by
code or by a reused icon:
  1. Divine Wrath (Olympian act): pantheon_fx/* band, fill, wave front, wave body, bolt column, arc pieces,
     fissure pieces and effects/wrath_strike (like tools/empire_aoe_art.py does for the Empire).
  2. Obstacles: obstacles/norse_boulder_s/_l, norse_ash_rock_s/_m/_l, maelstrom_wheel_m, galleon_steps_m(_v) and the
     vertical `_v` variants of the Archive, Necropolis and Ul-Thalos rect kinds (derived from the horizontal art).
  3. Markers: markers/scribe_curse, markers/inscription.
  4. Act-spell effects: projectiles/paris_arrow + aoe/paris_trail, pantheon_fx/thunder_orb, styx / lethe water and
     banks, spell_fx/linen_wrap_s/m/l and linen_strand.
  5. Small items: norse/holmgang_*, corsair/cursed_coin(+_spin), icons/fur_lined_bones, icons/cold_iron and the 8
     icons/ach_* badges.
  6. The 23 floor decals (Archive 4, Iron Citadel 3, Ul-Thalos 16).
Usage (from the repo root):   python3 art_source/missing_art/make_missing_art.py [--only prefix,prefix]
Every PNG is written to assets/sprites/<key>.png and listed in art_source/missing_art/manifest.json.
"""
import argparse
import json
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from covenant_aoe_art import Canvas, P, SPRITES, anoise, hf, hsh, strip_of, vnoise  # noqa: E402

MANIFEST = {}  # key -> {"w", "h", "frames", "note"}


def save(c, key, frames=1, note=""):
    """Writes canvas `c` to assets/sprites/<key>.png and records it in the manifest."""
    if key.startswith(("decals/", "obstacles/")):  # decals and obstacles are cropped tight (feet on the last row)
        bb = c.im.getbbox()
        c.im = c.im.crop(bb); c.px = c.im.load(); c.w, c.h = c.im.size
    c.save(key)
    MANIFEST[key] = {"w": c.w, "h": c.h, "frames": frames, "note": note}


# --- drawing helpers (ImageDraw: no anti-aliasing, exact palette pixels) --------------------------
def dr(c):
    return ImageDraw.Draw(c.im)


def fill(col, a=255):
    return (col[0], col[1], col[2], a)


def circle(c, cx, cy, r, col, a=255):
    """Filled disc: pixels whose centre is within r of (cx, cy)."""
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                c.put(x, y, col, a)


def ellipse(c, cx, cy, rx, ry, col, a=255):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                c.put(x, y, col, a)


def poly(c, pts, col, a=255):
    d = dr(c)
    d.polygon(pts, fill=fill(col, a))


def line(c, x0, y0, x1, y1, col, a=255, w=1):
    dr(c).line([(x0, y0), (x1, y1)], fill=fill(col, a), width=w)


def rect(c, x, y, w, h, col, a=255):
    c.rect(int(x), int(y), int(w), int(h), col, a)


def px(c, x, y, col, a=255):
    c.put(int(x), int(y), col, a)


def outline(c, col):
    """1 px ink outline round every opaque pixel (4-neighbours)."""
    c.outline(col)


def per_noise(x, n, seed, period):
    """Smooth noise 0..1 along x that repeats every `period` px (n lattice steps a period)."""
    return anoise(2 * math.pi * (x % period) / period, n, seed)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


# =============================================================================================
# 1. Divine Wrath: pantheon_fx
# =============================================================================================
AEG_INK, AEG_DK, AEG, AEG_L = P["ink_cold"], P["aegean_dark"], P["aegean"], P["aegean_light"]
MAR_DK, MAR, MAR_L = P["marble_dark"], P["marble"], P["marble_light"]
BR_INK, BR_DK, BR, BR_L = P["bronze_ink"], P["bronze_dark"], P["bronze"], P["bronze_light"]
CRIM_DK, CRIM, INK_RED, FLAME = P["crimson_dark"], P["crimson"], P["ink_red"], P["flame"]


def make_pantheon_fx():
    # --- warning band piece (10 x 6, row 0 outside): a meander (Greek key) between two aegean rails. ---
    for tick in (False, True):
        c = Canvas(10, 6)
        for x in range(10):
            px(c, x, 0, AEG_INK)
            px(c, x, 1, AEG_L)
            px(c, x, 4, AEG_DK)
            px(c, x, 5, AEG_INK)
        key = ["1111111111", "1000000001"]  # meander rows 2-3 (1 = marble white on aegean)
        for x in range(10):
            px(c, x, 2, MAR_L if key[0][x] == "1" and x not in (2, 7) else AEG)
            px(c, x, 3, MAR_L if x in (2, 7) else AEG)
        for x in (4, 5):
            px(c, x, 3, AEG)
        if tick:  # a marble-white tick pointing into the danger (rows 4-5)
            px(c, 4, 4, MAR_L); px(c, 5, 4, MAR_L); px(c, 4, 5, MAR_L); px(c, 5, 5, MAR_L)
        save(c, "pantheon_fx/edge_tick" if tick else "pantheon_fx/edge", note="warning band piece, row 3 on the hit edge")
    # --- seamless fill (16 x 16): a faint laurel-and-key lattice, stepped alpha ---
    c = Canvas(16, 16)
    for y in range(16):
        for x in range(16):
            if (x + y) % 8 == 0 or (x - y) % 8 == 0:
                px(c, x, y, AEG_L, 150)
            elif (x % 8 == 4 and y % 8 == 4):
                px(c, x, y, MAR_L, 200)
    save(c, "pantheon_fx/fill", note="seamless danger fill, laid as clipped rows")
    # --- double chevron pointing +x (13 x 13) ---
    c = Canvas(13, 13)
    for off in (0, 5):
        for k in range(6):
            px(c, 1 + off + k, 6 - k, MAR_L); px(c, 1 + off + k, 6 + k, MAR_L)
            px(c, 2 + off + k, 6 - k, AEG_L); px(c, 2 + off + k, 6 + k, AEG_L)
    outline(c, AEG_INK)
    save(c, "pantheon_fx/chevron", note="direction chevron, points +x")
    # --- impact crosshair with a bolt (15 x 15) ---
    c = Canvas(15, 15)
    for i in range(15):
        if abs(i - 7) > 2:
            px(c, i, 7, MAR_L); px(c, 7, i, MAR_L)
    for a in (-3, 3):
        px(c, 7 + a, 7, AEG_L); px(c, 7, 7 + a, AEG_L)
    for (x, y) in ((7, 5), (6, 6), (7, 7), (8, 8), (7, 9)):  # a small zigzag bolt in the middle
        px(c, x, y, MAR_L)
    px(c, 7, 6, AEG_L); px(c, 8, 7, AEG_L); px(c, 7, 8, AEG_L)
    save(c, "pantheon_fx/target", note="impact point, centre of the warning circle")
    # --- wave front tile 24 x 16: seamless along x, the advancing edge is the BOTTOM (foam on row ~13) ---
    W, H = 24, 16
    c = Canvas(W, H)
    for x in range(W):
        e = 12 + int(round(2.0 * math.sin(2 * math.pi * x / W * 2 + 0.4) + 1.2 * (per_noise(x, 6, 3, W) - 0.5) * 2))
        for y in range(0, e + 1):
            d = e - y  # rows behind the edge
            if d == 0:
                px(c, x, y, MAR_L)  # white foam edge
            elif d == 1:
                px(c, x, y, MAR_L if (x + y) % 3 else AEG_L)
            elif d == 2:
                px(c, x, y, AEG_L)
            elif d < 6:
                px(c, x, y, AEG, 215)
            else:
                px(c, x, y, AEG_DK, 150 if y > 3 else 90)
        if hf(x, 7) > 0.78 and e + 1 < H:  # spray flecks beyond the edge
            px(c, x, e + 1, MAR_L)
    save(c, "pantheon_fx/wave_front", note="tidal wave front, tiles along x, advancing edge = bottom, edge row ~13")
    # --- wave body 32 x 32 seamless (x and y): water with ripples, stepped alpha ---
    c = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            v = math.sin(2 * math.pi * (x / 32 * 2 + y / 32 * 3 + 0.5 * math.sin(2 * math.pi * y / 32 * 2)))
            if v > 0.82:
                px(c, x, y, AEG_L, 190)
            elif v > 0.55:
                px(c, x, y, AEG, 170)
            else:
                px(c, x, y, AEG_DK, 110)
    save(c, "pantheon_fx/wave_body", note="seamless water fill behind the front, scrolled with the wave")
    # --- bolt column 16 x 96, base on the bottom row ---
    c = Canvas(16, 96)
    x = 8.0
    path = []
    for y in range(96):
        t = y / 95.0
        u = y / 5.0
        i0 = int(u)
        f = u - i0
        a0, a1 = hf(i0, 11) - 0.5, hf(i0 + 1, 11) - 0.5
        x = 8 + (a0 * (1 - f) + a1 * f) * 9.0 * (1.0 - t * 0.5)  # diagonal runs between random kinks
        path.append(int(round(x)))
    for y in range(96):
        gx = path[y]
        for dx in range(-5, 6):
            a = 70 if abs(dx) > 3 else 140
            px(c, gx + dx, y, AEG_L, a)
        for dx in range(-2, 3):
            px(c, gx + dx, y, AEG_L if abs(dx) == 2 else MAR_L)
        px(c, gx, y, MAR_L)
    for dx in range(-7, 8):  # base flare
        for dy in range(0, 4 - abs(dx) // 3):
            px(c, 8 + dx, 95 - dy, MAR_L if abs(dx) < 3 else AEG_L)
    save(c, "pantheon_fx/bolt_column", note="the bolt itself from the sky, base on the bottom row, stepped alpha")
    # --- arcs (chain / Stolen Thunder): period-20 zigzag, seamless along x ---
    for name, core, hgt in (("arc_thin", 1, 9), ("arc_thick", 2, 13)):
        c = Canvas(20, hgt)
        cy = hgt // 2
        amp = 3 if hgt == 9 else 4
        pts = [(0, cy), (5, cy + amp), (10, cy), (15, cy - amp), (20, cy)]
        for i in range(4):
            line(c, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], AEG_L, 90, core + 4)
        for i in range(4):
            line(c, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], AEG_L, 200, core + 2)
        for i in range(4):
            line(c, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], MAR_L, 255, core)
        # wrap the last column back to the first so the tile repeats cleanly
        for y in range(hgt):
            c.px[19, y] = c.px[0, y] if c.px[0, y][3] else c.px[19, y]
        save(c, "pantheon_fx/" + name, note="lightning segment, tile and stretch along a->b")
    # --- thunder orb: 4 frames of 16 x 16, growing (Stolen Thunder charge, frame = charge k) ---
    frames = []
    for i in range(4):
        c = Canvas(16, 16)
        r = 2.5 + i * 1.5
        circle(c, 8, 8, r + 2, AEG_L, 80)
        circle(c, 8, 8, r, AEG_L, 200)
        circle(c, 8, 8, max(1.2, r - 1.6), MAR_L)
        for k in range(4 + i):  # crackling spokes
            a = k * math.tau / (4 + i) + i * 0.7
            for s in range(int(r) + 1, int(r) + 3 + i // 2):
                px(c, 8 + math.cos(a) * s, 8 + math.sin(a) * s, MAR_L if s % 2 else AEG_L)
        frames.append(c)
    save(strip_of(frames), "pantheon_fx/thunder_orb", 4, "charge orb, 4 frames by charge fraction, drawn at the caster's lift")
    # --- fissure: body 16 x 22 seamless along x, cap 10 x 22, warning tile 12 x 6 ---
    def crack(c, x0, x1, taper_left=False, period=16):
        H = c.h
        for x in range(x0, x1):
            n1 = per_noise(x, 4, 21, period)
            n2 = per_noise(x, 4, 22, period)
            half = 8.0 + (n1 - 0.5) * 4.2
            if taper_left:
                half *= math.sqrt(max(0.0, (x + 1) / float(x1)))
            top, bot = 11 - half - 1.6 * (n2 - 0.5), 11 + half + 1.6 * (0.5 - n2)
            for y in range(H):
                yy = y + 0.5
                if top - 2 <= yy <= bot + 2:
                    if top <= yy <= bot:
                        d = min(yy - top, bot - yy)
                        col = INK_RED if d > 1.6 else CRIM_DK
                        px(c, x, y, (0, 0, 0) if d > 1.6 else CRIM_DK)
                    else:
                        px(c, x, y, CRIM_DK, 170)  # a scorched lip
            if x0 <= x < x1:  # the glowing seam down the middle
                gy = 11 + int(round((n2 - 0.5) * 4))
                if taper_left and (x + 1) / float(x1) < 0.25:
                    continue
                px(c, x, gy, FLAME); px(c, x, gy + 1, P["gold"] if hf(x, 5) > 0.6 else FLAME)
                if hf(x, 9) > 0.7:
                    px(c, x, gy - 1, CRIM)
    c = Canvas(16, 22); crack(c, 0, 16)
    save(c, "pantheon_fx/fissure_body", note="open crack, tiles along x (18 px wide opening), centre row 11")
    c = Canvas(10, 22); crack(c, 0, 10, taper_left=True)
    save(c, "pantheon_fx/fissure_cap", note="crack end, left cap; flip for the right end")
    c = Canvas(12, 6)
    for x in range(12):
        gy = 2 + (1 if (x // 3) % 2 else 0)
        px(c, x, gy, FLAME if x % 6 < 4 else CRIM); px(c, x, gy + 1, CRIM_DK)
        if x % 6 == 1:
            px(c, x, gy - 1, P["gold"])
    save(c, "pantheon_fx/fissure_warn", note="telegraph: a crimson crack with ember dashes, tiles along x")
    make_wrath_strike()


def make_wrath_strike():
    """effects/wrath_strike: 8 frames x 96 x 96, ring ends at 0.84 of the half (40 px) like effects/empire_blast."""
    frames = []
    for f in range(8):
        c = Canvas(96, 96)
        t = f / 7.0
        cx = cy = 48
        # flash and lens glint
        if f < 4:
            r = [14, 11, 8, 5][f]
            circle(c, cx, cy, r + 3, AEG_L, 120)
            circle(c, cx, cy, r, MAR_L)
            for s in range(-(18 - f * 3), 19 - f * 3):
                px(c, cx + s, cy, MAR_L); px(c, cx, cy + s, MAR_L)
        # shock ring: grows to 40 px
        R = 40 * (0.25 + 0.75 * min(1.0, t * 1.5))
        a = int(255 * (1.0 - max(0.0, t - 0.55) / 0.45))
        if a > 20:
            for k in range(720):
                ang = k * math.tau / 720
                wob = 1.0 + 0.04 * (hf(int(ang * 12), f) - 0.5)
                x = cx + math.cos(ang) * R * wob
                y = cy + math.sin(ang) * R * wob
                col = MAR_L if (k // 6) % 3 else AEG_L
                for wdt in range(0, 2 if t < 0.5 else 1):
                    px(c, x + math.cos(ang) * -wdt, y + math.sin(ang) * -wdt, col, a)
        # ground cracks of light: 8 jagged rays
        reach = 34 * min(1.0, t * 2.2)
        for i in range(8):
            ang = i * math.tau / 8 + 0.2
            for s in range(4, int(reach)):
                j = (hf(i, s // 4, 5) - 0.5) * 3.0
                x = cx + math.cos(ang) * s + math.cos(ang + 1.57) * j
                y = cy + math.sin(ang) * s + math.sin(ang + 1.57) * j
                fa = int(255 * max(0.0, 1.0 - t * 0.9) * (1.0 - s / (reach + 8)))
                if fa > 30:
                    px(c, x, y, AEG_L if s % 3 else MAR_L, min(255, fa + 60))
        # sparks and bronze shards flung out
        for i in range(10):
            ang = hf(i, 31) * math.tau
            d = (6 + 30 * hf(i, 32)) * (0.3 + t)
            fa = int(255 * (1.0 - t))
            if fa > 40:
                px(c, cx + math.cos(ang) * d, cy + math.sin(ang) * d - 12 * t * hf(i, 33), MAR_L if i % 2 else BR_L, fa)
        # dust ring late
        if t > 0.5:
            for i in range(16):
                ang = i * math.tau / 16 + hf(i, 9)
                d = 36 + 5 * (t - 0.5)
                circle(c, cx + math.cos(ang) * d, cy + math.sin(ang) * d, 1.6, MAR, int(160 * (1 - t) + 40))
        frames.append(c)
    save(strip_of(frames), "effects/wrath_strike", 8, "lightning landing, 8 frames 96x96, ring ends at 0.84 of half = 40 px")


# =============================================================================================
# 4. act-spell effects
# =============================================================================================
VIO_INK, VIO_DP, VIO, VIO_FL = P["ink_violet"], P["violet_deep"], P["violet"], P["violet_flare"]
BONE, BONE_MID, BONE_SH = P["bone"], P["bone_mid"], P["bone_shade"]


def make_spell_fx():
    # Paris's Arrow: points +x, 20 x 7, violet shaft, bone head, bone-and-violet fletching.
    c = Canvas(20, 7)
    for x in range(3, 15):
        px(c, x, 3, VIO_FL); px(c, x, 4, VIO)
    for (x, y) in ((15, 3), (16, 3), (17, 3), (18, 3), (19, 3), (15, 2), (16, 2), (17, 2), (15, 4), (16, 4), (17, 4), (15, 1), (15, 5), (16, 1), (16, 5)):
        px(c, x, y, BONE)
    for (x, y) in ((17, 4), (16, 5), (15, 5)):
        px(c, x, y, BONE_MID)
    for (x, y, col) in ((0, 1, BONE), (1, 1, BONE), (1, 2, BONE_MID), (2, 2, VIO_FL), (0, 5, BONE_MID), (1, 5, BONE_MID), (1, 4, BONE_MID), (2, 4, VIO), (2, 3, VIO), (0, 3, VIO)):
        px(c, x, y, col)
    for (x, y) in ((0, 2), (0, 4)):
        px(c, x, y, VIO_FL)
    outline(c, VIO_INK)
    save(c, "projectiles/paris_arrow", note="Paris's Arrow, art points +x, centred on the arrow position, rotated by its direction")
    # trail: 24 x 5 streak, alpha ramps up toward +x (the arrow end), glow + core row
    c = Canvas(24, 5)
    for x in range(24):
        k = x / 23.0
        a = int(40 + 190 * k * k)
        for y, col, aa in ((0, VIO, a // 3), (1, VIO, a // 2), (2, VIO_FL, a), (3, VIO, a // 2), (4, VIO, a // 3)):
            if (x + y * 2) % 5 != 0 or k > 0.5:
                px(c, x, y, col, max(0, min(255, aa)))
    save(c, "aoe/paris_trail", note="arrow trail, stretch along the trail polyline, bright end at the arrow")
    # River Styx: water tiles 32 x 32 seamless (black water + current), banks 16 x 4
    for name, deep, mid, hi, bank_a, bank_b in (
            ("styx", (6, 5, 14), VIO_DP, VIO, BONE_SH, BONE),
            ("lethe", (8, 28, 52), AEG_DK, AEG_L, MAR_DK, MAR_L)):
        c = Canvas(32, 32)
        for y in range(32):
            for x in range(32):
                v = math.sin(2 * math.pi * (x / 32 * 3 + 0.35 * math.sin(2 * math.pi * y / 32 * 2) + y / 32))
                if v > 0.9:
                    px(c, x, y, hi, 170)
                elif v > 0.62 and (x + y) % 2 == 0:
                    px(c, x, y, mid, 230)
                else:
                    px(c, x, y, deep, 235)
        save(c, name + "_water" if False else "pantheon_fx/%s_water" % name, note="river water, seamless, scrolled along the river; alpha ~0.85")
        c = Canvas(16, 4)  # bank: row 0 outside
        for x in range(16):
            n = per_noise(x, 4, 44, 16)
            px(c, x, 0, bank_b if n > 0.55 else bank_a)
            px(c, x, 1, bank_a)
            px(c, x, 2, mix(bank_a, deep, 0.6))
            if n < 0.35:
                px(c, x, 3, deep, 200)
            else:
                px(c, x, 3, mid, 230)
        save(c, "pantheon_fx/%s_bank" % name, note="river bank piece, row 0 outside; flip vertically for the far bank")
    # Linen Bind: wrap overlays 16 / 24 / 36 and a strand tile 16 x 4
    L_DK, L, L_L = P["dyn_linen_dark"], P["dyn_linen"], P["dyn_linen_light"]
    for size, key in ((16, "s"), (24, "m"), (36, "l")):
        c = Canvas(size, size)
        n = 3 if size < 30 else 4
        bw = max(3, size // 6)
        for i in range(n):
            off = (i + 0.5) * size / n - size / 2.0
            for y in range(size):
                for x in range(size):
                    d = ((x + 0.5 - size / 2) - (y + 0.5 - size / 2) * 0.55) - off * 1.0
                    inside = (x + 0.5 - size / 2) ** 2 + (y + 0.5 - size / 2) ** 2 <= (size / 2 - 0.5) ** 2
                    if inside and abs(d) < bw / 2.0:
                        e = abs(d) / (bw / 2.0)
                        px(c, x, y, L_L if (e < 0.35 and y < size * 0.6) else (L if e < 0.8 else L_DK))
        # a crossing band the other way and a loose tail
        for t in range(size):
            x = int(t * 0.9 + size * 0.05); y = int(size * 0.8 - t * 0.55)
            if 0 <= x < size and (x + 0.5 - size / 2) ** 2 + (y + 0.5 - size / 2) ** 2 <= (size / 2) ** 2:
                px(c, x, y, L); px(c, x, y + 1, L_DK)
        tail = size // 2 + 2
        for s in range(max(3, size // 5)):
            px(c, tail + s, size - 3 - s // 2, L_L if s % 2 == 0 else L)
        outline(c, P["dyn_ink"])
        save(c, "spell_fx/linen_wrap_" + key, note="bandage wrap over a marked enemy; pick the size nearest 2x its radius")
    c = Canvas(16, 4)  # strand: a bandage ribbon with a soul-teal glow row
    for x in range(16):
        px(c, x, 0, P["soul"], 110); px(c, x, 1, L_L); px(c, x, 2, L if x % 8 else L_DK); px(c, x, 3, P["soul"], 90)
    save(c, "spell_fx/linen_strand", note="tether ribbon, tiles along a->b (4 px tall)")


# =============================================================================================
# 3. markers
# =============================================================================================
def make_markers():
    INK, BDK, B, BG = P["ink_biolume"], P["biolume_dark"], P["biolume"], P["biolume_glow"]
    I_DK = P["ink_drowned"]
    c = Canvas(12, 12)
    ring = [(4, 0), (5, 0), (6, 0), (7, 0), (2, 1), (3, 1), (8, 1), (9, 1), (1, 2), (10, 2), (0, 4), (0, 5), (0, 6), (0, 7), (11, 4), (11, 5), (11, 6), (11, 7),
            (1, 9), (10, 9), (2, 10), (3, 10), (8, 10), (9, 10), (4, 11), (5, 11), (6, 11), (7, 11)]
    for (x, y) in ring:
        px(c, x, y, BDK)
    for (x, y) in ((1, 3), (1, 8), (10, 3), (10, 8), (5, 1), (6, 1), (5, 10), (6, 10)):
        px(c, x, y, B)
    for (x, y) in ((3, 5), (4, 4), (5, 4), (6, 4), (7, 4), (8, 5), (3, 6), (4, 7), (5, 7), (6, 7), (7, 7), (8, 6)):  # the eye
        px(c, x, y, B)
    for (x, y) in ((5, 5), (6, 5), (5, 6), (6, 6)):
        px(c, x, y, BG)
    for (x, y) in ((4, 5), (7, 5), (4, 6), (7, 6)):
        px(c, x, y, I_DK)
    save(c, "markers/scribe_curse", note="ink sigil over a cursed cultist: a rune ring around an open biolume eye")
    VI, VD, VF = P["violet"], P["violet_deep"], P["violet_flare"]
    c = Canvas(12, 12)
    for (x, y) in ((4, 0), (5, 0), (6, 0), (7, 0), (2, 1), (3, 1), (8, 1), (9, 1), (1, 2), (10, 2), (0, 4), (0, 5), (0, 6), (0, 7), (11, 4), (11, 5), (11, 6), (11, 7), (1, 9), (2, 10), (3, 11)):
        px(c, x, y, VI)
    for (x, y) in ((10, 9), (9, 10), (8, 10), (7, 11), (6, 11)):
        px(c, x, y, VD)
    rect(c, 3, 3, 6, 6, P["bone"])  # a small page
    rect(c, 3, 3, 6, 1, P["bone_mid"])
    for (x0, x1, y) in ((4, 7, 4), (4, 6, 6), (5, 7, 7)):
        for x in range(x0, x1 + 1):
            px(c, x, y, VI)
    px(c, 7, 5, VF); px(c, 5, 5, VD)
    outline(c, VD) if False else None
    save(c, "markers/inscription", note="Forbidden Verse mark: a violet rune ring round a small inscribed page")


# =============================================================================================
# 2. obstacles
# =============================================================================================
def rock(w, h, ramp, seed, snow=None, ember=None, lean=0.0):
    """A 3/4 view rock/boulder: noisy dome lit from the top-left, 4 facet shades, ink outline and rim light.
    ramp = (ink, dark, mid, light). snow = (shade, snow) cap colours; ember = (dark, glow) crack colours."""
    ink, dk, md, lt = ramp
    c = Canvas(w, h)
    cx, cy = w / 2.0, h * 0.55
    rx, ry = w / 2.0 - 1.5, h * 0.5 - 1.2
    for y in range(h):
        for x in range(w):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            ang = math.atan2(ny, nx)
            wob = 1.0 + (anoise(ang, 7, seed) - 0.5) * 0.26
            if ny > 0.55:  # a flat base
                wob *= 1.0 - (ny - 0.55) * 0.35
            r2 = (nx * nx + ny * ny) / (wob * wob)
            if r2 > 1.0:
                continue
            z = math.sqrt(max(0.0, 1.0 - r2))
            nxx, nyy = nx / wob, ny / wob
            lum = 0.5 + 0.45 * (-0.6 * nxx - 0.7 * nyy) + 0.25 * z
            lum += (vnoise(x / 3.2, y / 3.2, seed) - 0.5) * 0.45  # facets
            if ny > 0.35:
                lum -= 0.18  # the underside
            col = lt if lum > 0.78 else (md if lum > 0.5 else (dk if lum > 0.28 else ink))
            if col == ink:
                col = dk
            c.put(x, y, col)
            if snow is not None:
                sn = (-0.5 * nyy) + z * 0.2 + (vnoise(x / 2.5, y / 2.5, seed + 9) - 0.5) * 0.5
                if nyy < 0.1 and sn > 0.28:
                    c.put(x, y, snow[1] if lum > 0.45 else snow[0])
    if ember is not None:
        for i in range(2 if w < 40 else 3):
            x = w * (0.3 + 0.4 * ((i + hf(i, seed, 1) * 0.5) / 2.5)); y = h * 0.22
            for s in range(int(h * 0.55)):
                x += ((hf(i, s // 3, seed) - 0.5) * 2.4) if s % 3 == 0 else 0.0; y += 1
                if c.get_a(int(x), int(y)):
                    c.put(int(x), int(y), ember[1] if s % 4 else ember[0])
                    c.put(int(x) + 1, int(y), ember[0])
    # rim light: lit top-left edge pixels one step lighter
    for y in range(h):
        for x in range(w):
            if c.get_a(x, y) and (not c.get_a(x - 1, y) or not c.get_a(x, y - 1)) and y < h * 0.7:
                if c.px[x, y][:3] in (dk, md):
                    c.put(x, y, lt if c.px[x, y][:3] == md else md)
    outline(c, ink)
    bb = c.im.getbbox()  # trim to the drawn rock so its base touches the last row
    c.im = c.im.crop(bb); c.px = c.im.load(); c.w, c.h = c.im.size
    return c


def vertical_from(h_img, long_px, short_px, top_rows=None):
    """Derives the `_v` sprite of a rect obstacle from its horizontal sprite `h_img` (a PIL RGBA image):
    the top face (its top rows) turned a quarter and stretched to the long side, standing above the near
    end face (the left end of the front face). Width = short + 2, height = long + end-face height."""
    W, Hh = h_img.size
    T = top_rows if top_rows is not None else max(4, min(short_px, Hh // 2))
    sw = short_px + 2
    top = h_img.crop((0, 0, W, T)).transpose(Image.ROTATE_90)  # T wide x W tall
    top = top.resize((sw, long_px), Image.NEAREST)
    end = h_img.crop((0, T, min(W, sw + 3), Hh))
    end = end.resize((sw, end.height), Image.NEAREST)
    bb = end.getbbox()  # trim empty rows so the feet touch the last row
    if bb:
        end = end.crop((0, 0, sw, bb[3]))
    out = Image.new("RGBA", (sw, long_px - 1 + end.height), (0, 0, 0, 0))
    out.alpha_composite(top, (0, 0))
    out.alpha_composite(end, (0, long_px - 1))
    cv = Canvas(out.width, out.height)
    cv.im.alpha_composite(out)
    cv.px = cv.im.load()
    ink = None
    # a 1 px ink seam where the end face meets the top face
    seam = cv.px[sw // 2, long_px - 1]
    return cv


def make_obstacles():
    nrock = (P["norse_ink"], P["norse_iron_dark"], P["norse_iron"], P["norse_iron_light"])
    for (key, w, h, seed) in (("norse_boulder_s", 24, 22, 3), ("norse_boulder_l", 33, 30, 4)):
        save(rock(w, h, nrock, seed, snow=(P["norse_frost_shade"], P["norse_frost"])), "obstacles/" + key,
             note="frozen boulder, snow cap; circle kind, radius 10 / 14 (sprite = 2r + 4 wide)")
    arock = (P["norse_ink"], P["norse_ash_light"], P["norse_iron_dark"], P["norse_iron"])  # ash grey, lighter than the floor
    for (key, w, h, seed) in (("norse_ash_rock_s", 28, 25, 5), ("norse_ash_rock_m", 36, 32, 6), ("norse_ash_rock_l", 48, 42, 7)):
        save(rock(w, h, arock, seed, ember=(P["norse_hearth"], P["norse_hearth_glow"])), "obstacles/" + key,
             note="ash rock with ember cracks; circle kind, radius 12 / 16 / 22")
    make_wheel()
    make_steps()
    # --- vertical variants derived from the horizontal art ---
    RECTS = {  # kind: (suffix list, long sides, short side)
        "bookshelf": (["s", "m", "l"], [80, 88, 96], 20),
        "blank_shelf": (["s", "m", "l"], [72, 84, 96], 20),
        "toppled_shelf": (["s", "m", "l"], [56, 68, 80], 18),
        "reading_desk": (["s", "l"], [40, 48], 24),
        "chart_table": (["s", "l"], [44, 52], 26),
        "dyn_tomb": (["s", "l"], [28, 42], 14),
        "toppled_arch": (["s", "l"], [60, 76], 20),
    }
    for kind, (sfx, longs, short) in RECTS.items():
        for s, lg in zip(sfx, longs):
            src = Image.open(os.path.join(SPRITES, "obstacles", "%s_%s.png" % (kind, s))).convert("RGBA")
            if kind in ("toppled_arch", "toppled_shelf", "dyn_tomb"):  # low things lying flat: a diagonal flip keeps the light top-left
                v = Canvas(src.height, src.width); v.im.alpha_composite(src.transpose(Image.TRANSPOSE)); v.px = v.im.load()
            else:
                v = vertical_from(src, lg, short)
            save(v, "obstacles/%s_%s_v" % (kind, s), note="derived from the horizontal art (tall props: top face above the end face; low props: a diagonal flip)")


def make_wheel():
    """maelstrom_wheel_m: the Drowned Helm's ship wheel, upright on a post, rotten oak with ghost-green wash."""
    INK = P["corsair_ink"]
    OD, OK, OL = P["corsair_oak_dark"], P["corsair_oak"], P["corsair_oak_light"]
    SD, S, SL = P["corsair_spectre_dark"], P["corsair_spectre"], P["corsair_spectre_light"]
    BD, B = P["corsair_brass_dark"], P["corsair_brass"]
    c = Canvas(28, 32)
    cx, cy = 14.0, 13.0
    d = dr(c)
    # post / pedestal
    rect(c, 11, 22, 6, 8, OD); rect(c, 11, 22, 2, 8, OK); rect(c, 9, 28, 10, 3, OD); rect(c, 9, 28, 10, 1, OK)
    # spoke handles + rim
    for k in range(8):
        a = k * math.tau / 8
        x0, y0 = cx + math.cos(a) * 3, cy + math.sin(a) * 3
        x1, y1 = cx + math.cos(a) * 11, cy + math.sin(a) * 11
        line(c, x0, y0, x1, y1, OK, 255, 2)
        circle(c, cx + math.cos(a) * 12.4, cy + math.sin(a) * 12.4, 1.4, OL if k % 2 else OK)
    for y in range(32):
        for x in range(28):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if 8.2 <= r <= 10.6:
                ang = math.atan2(y + 0.5 - cy, x + 0.5 - cx)
                lit = (math.cos(ang + 2.4) > 0.3)
                px(c, x, y, OL if lit else (OK if r < 9.6 else OD))
    circle(c, cx, cy, 3.2, BD); circle(c, cx - 0.6, cy - 0.6, 2.0, B)
    for (x, y) in ((6, 8), (21, 17), (9, 20), (17, 6), (12, 22)):  # ghost-green rot washes
        px(c, x, y, S); px(c, x + 1, y, SD)
    px(c, 8, 5, SL); px(c, 20, 10, SL)
    outline(c, INK)
    save(c, "obstacles/maelstrom_wheel_m", note="circle kind, size 12; one size so suffix m; feet = bottom row")


def make_steps():
    """galleon_steps_m_v (28 x 100): oak treads rising away from the viewer, rope rails; _m is its quarter turn."""
    INK = P["corsair_ink"]
    OD, OK, OL = P["corsair_oak_dark"], P["corsair_oak"], P["corsair_oak_light"]
    TN, TL = P["corsair_tan_dark"], P["corsair_tan"]
    W, H = 28, 100
    c = Canvas(W, H)
    n = 7
    step = (H - 6) // n
    for i in range(n):
        y1 = H - 1 - i * step  # tread bottom (nearest rises first)
        rise = 4
        # riser (dark, facing the viewer)
        rect(c, 3, y1 - rise, W - 6, rise, INK); rect(c, 3, y1 - rise + 1, W - 6, rise - 1, OD)
        for x in range(4, W - 4, 5):
            px(c, x, y1 - 2, INK)
        # tread (lit, top face)
        rect(c, 3, y1 - step, W - 6, step - rise, OL)
        rect(c, 3, y1 - step + 2, W - 6, step - rise - 2, OK)
        for x in range(5, W - 5, 6):
            px(c, x, y1 - step + 2, OD)
    # side rails: rope posts and a sagging rope each side
    for side in (1, W - 3):
        rect(c, side, 8, 2, H - 14, TN)
        for i in range(n + 1):
            y = H - 4 - i * step
            rect(c, side - 1, y, 4, 3, OD); px(c, side, y, TL)
    outline(c, INK)
    save(c, "obstacles/galleon_steps_m_v", note="rect 96 x 26, vertical placement (fixed layout); one size so suffix m")
    save_h = Canvas(H, W)
    save_h.im.paste(c.im.transpose(Image.ROTATE_90), (0, 0))
    save_h.px = save_h.im.load()
    save(save_h, "obstacles/galleon_steps_m", note="horizontal twin (quarter turn of the vertical), not placed by the fixed layout")


# =============================================================================================
# 5. small items
# =============================================================================================
def make_holmgang():
    HZ_DK, HZ, HZ_L = P["norse_plank_dark"], P["norse_plank"], P["norse_plank_light"]
    PN, PN_L = P["norse_pine"], P["norse_pine_dark"]
    # post: 8 x 16 hazel rod with a leaf tuft at the top and a rope knot
    c = Canvas(8, 16)
    rect(c, 3, 3, 3, 13, HZ); rect(c, 3, 3, 1, 13, HZ_L); rect(c, 5, 3, 1, 13, HZ_DK)
    for y in (6, 11):
        rect(c, 2, y, 5, 1, P["brown_light"]); px(c, 4, y + 1, P["brown"])
    for (x, y) in ((1, 2), (2, 1), (2, 2), (6, 1), (7, 2), (6, 2), (3, 0), (4, 0), (5, 0)):
        px(c, x, y, PN)
    for (x, y) in ((3, 1), (4, 1), (5, 1), (4, 2), (3, 2)):
        px(c, x, y, PN_L if (x + y) % 2 else PN)
    px(c, 2, 1, P["norse_pine"]); px(c, 4, 15, P["norse_ink"]); px(c, 3, 15, P["norse_ink"]); px(c, 5, 15, P["norse_ink"])
    outline(c, P["norse_ink"])
    save(c, "norse/holmgang_post", note="hazel rod post, feet on the bottom row; one at each rod position (code draws 3 x 11 rects)")
    # rope tile 16 x 3 (horizontal) and its vertical twin 3 x 16
    c = Canvas(16, 3)
    for x in range(16):
        px(c, x, 0, P["brown_light"] if (x // 2) % 2 else P["brown"]); px(c, x, 1, P["brown"]); px(c, x, 2, P["norse_ink"], 200)
    save(c, "norse/holmgang_rope", note="rope between posts, tiles along x; the code lays it at 7 px above the ground line")
    v = Canvas(3, 16)
    v.im.paste(c.im.transpose(Image.ROTATE_90), (0, 0)); v.px = v.im.load()
    save(v, "norse/holmgang_rope_v", note="vertical sides")
    # ground: 32 x 32 seamless trampled ground with faint gold rune scratches, stepped alpha
    c = Canvas(32, 32)
    for y in range(32):
        for x in range(32):
            h = hf(x, y, 8)
            if h > 0.94:
                px(c, x, y, P["gold"], 110)
            elif h > 0.86:
                px(c, x, y, P["brown"], 70)
    for (x, y, l) in ((3, 5, 5), (18, 9, 6), (8, 22, 7), (24, 25, 5)):
        for s in range(l):
            px(c, (x + s) % 32, (y + (s // 3)) % 32, P["gold"], 130)
    save(c, "norse/holmgang_ground", note="duel ground tint tile (replaces the flat gold rect), seamless, alpha 0.3-0.5 in code")


def make_coin():
    INK = P["corsair_ink"]
    BD, B, BL = P["corsair_brass_dark"], P["corsair_brass"], P["corsair_brass_light"]
    LN, LNL = P["corsair_lantern"], P["corsair_lantern_light"]
    SG = P["corsair_spectre"]

    def face(w):
        c = Canvas(14, 14)
        cx = 7.0
        for y in range(14):
            for x in range(14):
                dx, dy = (x + 0.5 - cx) / (w / 2.0), (y + 0.5 - 7.0) / 6.0
                if dx * dx + dy * dy <= 1.0:
                    c.put(x, y, B if dx + dy < 0.6 else BD)
        if w >= 9:
            for y in range(14):
                for x in range(14):
                    dx, dy = (x + 0.5 - cx) / (w / 2.0), (y + 0.5 - 7.0) / 6.0
                    if 0.55 < dx * dx + dy * dy <= 0.8 and dx + dy < 0.2:
                        c.put(x, y, BL)
            # an embossed skull
            s = [(6, 5), (7, 5), (5, 6), (6, 6), (7, 6), (8, 6), (5, 7), (8, 7), (6, 8), (7, 8)]
            for (x, y) in s:
                if w == 12 or x in range(5, 9):
                    c.put(x, y, BD if (x, y) not in ((5, 7), (8, 7)) else INK)
            c.put(6, 7, SG); c.put(7, 7, SG)
            c.put(5, 4, LNL)
        else:
            for y in range(2, 12):
                c.put(6, y, BL); c.put(7, y, BD)
        outline(c, INK)
        return c

    f0 = face(12)
    save(f0, "corsair/cursed_coin", note="Cursed Coin (radius 6 px), single face; the sickly lantern glow stays code")
    frames = [face(12), face(8), face(3), face(8)]
    frames[3].im = frames[3].im.transpose(Image.FLIP_LEFT_RIGHT); frames[3].px = frames[3].im.load()
    save(strip_of(frames), "corsair/cursed_coin_spin", 4, "spin: face, 3/4, edge, 3/4 mirrored; 4 frames of 14 x 14")


def badge_template(src_key, accent_ring=True):
    """The frame of an existing 32 x 32 icon (outer 3 px ring) over a dark violet field."""
    im = Image.open(os.path.join(SPRITES, "icons", src_key + ".png")).convert("RGBA")
    c = Canvas(32, 32)
    c.im.alpha_composite(im)
    bg = P["ink_violet"]
    for y in range(32):
        for x in range(32):
            if im.getpixel((x, y))[3] and 3 <= x <= 28 and 3 <= y <= 28:
                c.put(x, y, bg)
    c.px = c.im.load()
    return c


def symbol(draw_fn):
    """A 26 x 26 symbol canvas (to be centred in the frame): draws with draw_fn, then outlines it in its own ink."""
    c = Canvas(26, 26)
    draw_fn(c)
    return c


def sym_skull(c, cx, cy, r, col=None, shade=None, eyes=None):
    col = col or P["bone"]; shade = shade or P["bone_shade"]
    ellipse(c, cx, cy - 1, r, r * 0.9, col)
    rect(c, cx - r * 0.55, cy + r * 0.5, r * 1.1, r * 0.7, col)
    for dx in (-r * 0.45, r * 0.45):
        circle(c, cx + dx, cy - 0.5, max(1.0, r * 0.3), eyes or P["ink_cold"])
    rect(c, cx - 0.5, cy + 1, 1, 1, shade)
    for i in range(-1, 2):
        px(c, cx + i * 1.2, cy + r * 1.2, shade)


def draw_symbols():
    out = {}
    BS, BM, BN = P["bone_shade"], P["bone_mid"], P["bone"]
    EARTH, EARTH_L = P["floor_earth"], P["brown"]

    def mass_grave(c):
        poly(c, [(2, 24), (6, 16), (13, 13), (20, 16), (24, 24)], EARTH)  # a heap of grave earth
        poly(c, [(4, 24), (8, 18), (13, 16), (18, 18), (22, 24)], EARTH_L)
        sym_skull(c, 8, 13, 4.2); sym_skull(c, 17, 13, 4.2); sym_skull(c, 12.5, 8, 4.8)
        line(c, 3, 20, 10, 18, BN, 255, 2); line(c, 23, 20, 16, 18, BN, 255, 2)
    out["ach_mass_grave"] = (mass_grave, "gold")

    def untouchable(c):
        poly(c, [(13, 1), (23, 5), (22, 15), (13, 24), (4, 15), (3, 5)], P["violet_deep"])
        poly(c, [(13, 3), (21, 6), (20, 14), (13, 21), (6, 14), (5, 6)], P["violet"])
        poly(c, [(13, 3), (13, 21), (6, 14), (5, 6)], P["violet_deep"] if False else P["violet"])
        poly(c, [(13, 6), (16, 12), (13, 18), (10, 12)], P["violet_flare"])
        line(c, 13, 8, 13, 16, P["holy_white"]); line(c, 10, 12, 16, 12, P["holy_white"])
        for (x, y) in ((3, 3), (23, 3), (24, 22), (2, 20)):
            px(c, x, y, P["holy_white"]); px(c, x - 1, y, P["violet_flare"]); px(c, x + 1, y, P["violet_flare"]); px(c, x, y - 1, P["violet_flare"]); px(c, x, y + 1, P["violet_flare"])
    out["ach_untouchable"] = (untouchable, "gold")

    def full_ossuary(c):
        rect(c, 2, 4, 22, 21, P["grey_dark"])  # a stone arch filled with skulls
        poly(c, [(2, 10), (5, 4), (13, 1), (21, 4), (24, 10)], P["grey_dark"])
        for r_i, y in enumerate((20, 14, 8)):
            for k in range(3 if r_i < 2 else 2):
                x = 5.5 + k * 7.5 + (3.5 if r_i == 2 else 0)
                sym_skull(c, x + (1 if r_i == 1 else 0), y, 3.3)
        rect(c, 2, 24, 22, 1, P["grey"])
    out["ach_full_ossuary"] = (full_ossuary, "gold")

    def deathlords_due(c):
        G, GL, GD = P["gold"], P["gold_light"], P["brown_light"]
        poly(c, [(3, 20), (3, 8), (8, 14), (13, 5), (18, 14), (23, 8), (23, 20)], G)
        poly(c, [(5, 19), (5, 12), (8, 16), (13, 9), (18, 16), (21, 12), (21, 19)], GL)
        rect(c, 3, 20, 20, 3, GD); rect(c, 3, 20, 20, 1, GL)
        sym_skull(c, 13, 15, 3.4, P["bone"], P["bone_shade"], P["crimson_dark"])
        for (x, y) in ((3, 7), (13, 4), (23, 7)):
            circle(c, x, y, 1.6, P["crimson"]); px(c, x, y - 1, P["flame"])
    out["ach_deathlords_due"] = (deathlords_due, "gold")

    def swift_judgment(c):
        BR_, BRL = P["bone_mid"], P["bone"]
        poly(c, [(6, 2), (20, 2), (20, 4), (6, 4)], P["gold"])  # an hourglass
        poly(c, [(6, 22), (20, 22), (20, 24), (6, 24)], P["gold"])
        poly(c, [(8, 4), (18, 4), (14, 12), (18, 22), (8, 22), (12, 12)], P["ice"] if False else P["bone_shade"])
        poly(c, [(9, 18), (17, 18), (17, 21), (9, 21)], P["gold_light"])
        poly(c, [(11, 5), (15, 5), (13, 8)], P["gold_light"])
        # a lightning bolt through it
        poly(c, [(17, 0), (8, 13), (13, 13), (9, 25), (20, 10), (14, 10)], P["soul_glow"])
        poly(c, [(16, 3), (11, 12), (15, 12), (12, 21), (18, 11), (13, 11)], P["holy_white"])
    out["ach_swift_judgment"] = (swift_judgment, "gold")

    def keep_the_fires(c):
        I_, ID = P["norse_iron"], P["norse_iron_dark"]
        poly(c, [(4, 14), (22, 14), (19, 19), (7, 19)], I_)  # bowl
        poly(c, [(5, 14), (21, 14), (20, 16), (6, 16)], P["norse_iron_light"])
        line(c, 8, 19, 5, 25, ID, 255, 2); line(c, 18, 19, 21, 25, ID, 255, 2); line(c, 13, 19, 13, 25, ID, 255, 2)
        poly(c, [(13, 0), (19, 8), (21, 13), (5, 13), (7, 8), (10, 5)], P["flame"])
        poly(c, [(13, 4), (17, 9), (18, 13), (8, 13), (9, 9), (11, 7)], P["norse_hearth"])
        poly(c, [(13, 8), (15, 11), (15, 13), (11, 13), (11, 11)], P["norse_hearth_glow"])
        px(c, 4, 5, P["norse_hearth_glow"]); px(c, 22, 6, P["norse_hearth_glow"]); px(c, 7, 2, P["norse_hearth"])
    out["ach_keep_the_fires"] = (keep_the_fires, "gold")

    def holmgang(c):
        BR_ = P["brown_light"]
        rect(c, 2, 12, 22, 12, P["floor_dirt"] if False else P["brown"])  # a square of hazel rods around a duel ground
        rect(c, 3, 13, 20, 10, P["floor_earth"])
        for x in (2, 12, 23):
            rect(c, x, 9, 2, 15, P["norse_plank_light"]); px(c, x, 8, P["norse_pine"]); px(c, x + 1, 8, P["norse_pine"])
        line(c, 2, 12, 24, 12, P["brown_light"]);
        # two crossed swords
        line(c, 5, 3, 21, 22, P["norse_iron_light"], 255, 2); line(c, 21, 3, 5, 22, P["steel_light"], 255, 2)
        line(c, 3, 6, 8, 3, P["gold"], 255, 2); line(c, 23, 6, 18, 3, P["gold"], 255, 2)
        circle(c, 13, 13, 2.2, P["crimson"])
    out["ach_holmgang"] = (holmgang, "gold")

    def twilight_wolf(c):
        circle(c, 13, 12, 11, P["indigo_dark"] if "indigo_dark" in P else P["violet_deep"])
        circle(c, 17, 8, 5.5, P["gold"]); circle(c, 19, 6, 5, P["violet_deep"])  # a crescent sun going out
        poly(c, [(4, 25), (4, 14), (7, 6), (9, 10), (13, 9), (17, 10), (19, 6), (22, 14), (22, 25)], P["grey"])
        poly(c, [(8, 25), (8, 17), (13, 15), (18, 17), (18, 25)], P["grey_light"])
        poly(c, [(10, 19), (13, 23), (16, 19)], P["grey_dark"])
        px(c, 10, 14, P["crimson"]); px(c, 16, 14, P["crimson"]); px(c, 10, 15, P["flame"]); px(c, 16, 15, P["flame"])
        px(c, 13, 20, P["ink_cold"])
    out["ach_twilight_of_the_wolf"] = (twilight_wolf, "gold")

    def fur_lined(c):
        poly(c, [(3, 20), (6, 17), (19, 4), (22, 4), (23, 8), (10, 21), (7, 24), (3, 24)], BM)  # a femur
        poly(c, [(5, 19), (19, 5), (21, 6), (8, 21)], BN)
        circle(c, 4, 22, 3, BN); circle(c, 21, 5, 3, BN)
        # a thick fur cuff round the middle
        poly(c, [(7, 20), (12, 13), (19, 12), (20, 16), (15, 22)], P["brown"])
        for (x, y) in ((7, 20), (9, 17), (11, 14), (14, 12), (17, 12), (19, 13), (20, 16), (17, 19), (14, 22), (10, 22)):
            circle(c, x, y, 1.5, P["brown_light"])
        for (x, y) in ((12, 16), (15, 15), (13, 19), (17, 16)):
            px(c, x, y, P["floor_earth"])
        px(c, 3, 5, P["norse_snow_light"]); px(c, 22, 20, P["norse_snow_light"]); px(c, 6, 9, P["norse_frost"]); px(c, 2, 10, P["norse_frost"])
    out["fur_lined_bones"] = (fur_lined, "violet")

    def cold_iron(c):
        I_, IL, ID = P["norse_iron"], P["norse_iron_light"], P["norse_iron_dark"]
        # a horseshoe of iron with frost on it
        for y in range(26):
            for x in range(26):
                r = math.hypot(x + 0.5 - 13, y + 0.5 - 12)
                if 5.5 <= r <= 10.5 and not (y > 14 and abs(x + 0.5 - 13) < 4.0 and r < 11 and False):
                    ang = math.atan2(y + 0.5 - 12, x + 0.5 - 13)
                    if not (0.9 < ang < 2.2):  # open at the bottom
                        c.put(x, y, IL if math.cos(ang + 2.3) > 0.4 else (I_ if r < 9 else ID))
        for sx in (4, 21):
            rect(c, sx, 14, 3, 8, I_); rect(c, sx, 14, 1, 8, IL); rect(c, sx + 2, 14, 1, 8, ID)
        for (x, y) in ((6, 15), (6, 18), (22, 17), (22, 20)):
            px(c, x, y, ID)
        for (x, y) in ((8, 3), (13, 2), (18, 3), (4, 8), (22, 8)):  # frost crystals
            line(c, x, y, x, y - 3, P["norse_ice_light"] if "norse_ice_light" in P else P["ice_light"])
            px(c, x - 1, y - 1, P["ice"]); px(c, x + 1, y - 1, P["ice"])
        px(c, 13, 0, P["holy_white"])
    out["cold_iron"] = (cold_iron, "violet")
    return out


def make_icons():
    frames = {"gold": badge_template("ach_low_tide"), "violet": badge_template("grave_dominion")}
    for key, (fn, fr) in draw_symbols().items():
        c = Canvas(32, 32)
        c.im.alpha_composite(frames[fr].im)
        c.px = c.im.load()
        s = symbol(fn)
        # outline the symbol in its own darkest shade so it reads on the dark field
        outline(s, P["ink_cold"])
        big = Canvas(32, 32)
        big.im.alpha_composite(s.im, (3, 3))
        big.px = big.im.load()
        c.im.alpha_composite(big.im)
        c.px = c.im.load()
        save(c, "icons/" + key, note="32 x 32 badge, %s frame" % fr)


# =============================================================================================
# 6. floor decals
# =============================================================================================
def blob(c, cx, cy, rx, ry, seed, col, a=255, rough=0.35):
    for y in range(int(cy - ry - 2), int(cy + ry + 3)):
        for x in range(int(cx - rx - 2), int(cx + rx + 3)):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            ang = math.atan2(ny, nx)
            lim = 1.0 + (anoise(ang, 5, seed) - 0.5) * rough * 2
            if nx * nx + ny * ny <= lim * lim:
                c.put(x, y, col, a)


def d_pages(w, h, seed, inks, paper):
    c = Canvas(w, h)
    for i in range(3 if w > 11 else 2):
        ox, oy = 1 + int(hf(i, seed, 1) * (w - 8)), 1 + int(hf(i, seed, 2) * (h - 6))
        pw, ph = 5 + int(hf(i, seed, 3) * 2), 4 + int(hf(i, seed, 4) * 2)
        shift = int(hf(i, seed, 5) * 3) - 1
        for y in range(ph):
            for x in range(pw):
                c.put(ox + x + (y * shift) // 3, oy + y, paper[0] if (x + y) % 5 else paper[1])
        for y in range(1, ph - 1, 2):
            for x in range(1, pw - 1 - (y % 3)):
                c.put(ox + x + (y * shift) // 3, oy + y, inks)
    return c


def d_star(size, seed, cols):
    c = Canvas(size, size)
    cx = cy = size / 2.0
    ink, mid, hi = cols
    for k in range(8):  # an eight-pointed brass inlay with a ring
        a = k * math.tau / 8
        L = size / 2.0 - 1 if k % 2 == 0 else size / 3.2
        for s in range(2, int(L)):
            wdt = max(0, int(1.5 * (1 - s / L)))
            for w in range(-wdt, wdt + 1):
                c.put(cx + math.cos(a) * s - math.sin(a) * w, cy + math.sin(a) * s + math.cos(a) * w, mid if s % 3 else hi)
    for y in range(size):
        for x in range(size):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if abs(r - size * 0.28) < 0.7:
                c.put(x, y, mid)
            if r < 2.0:
                c.put(x, y, hi)
    for k in range(0, 8):
        a = k * math.tau / 8 + math.pi / 8
        c.put(cx + math.cos(a) * size * 0.43, cy + math.sin(a) * size * 0.43, ink)
    return c


def d_stain(w, h, seed, cols):
    c = Canvas(w, h)
    dk, md, glint = cols
    blob(c, w / 2, h / 2, w / 2 - 1, h / 2 - 1, seed, dk)
    blob(c, w / 2 - 1, h / 2 - 1, w / 3, h / 3, seed + 1, md)
    for i in range(3):
        c.put(1 + hf(i, seed, 8) * (w - 2), 1 + hf(i, seed, 9) * (h - 2), dk)
    c.put(w * 0.35, h * 0.35, glint)
    return c


def d_scorch(w, h, seed, cols):
    c = Canvas(w, h)
    dk, md, ember = cols
    blob(c, w / 2, h / 2, w / 2 - 1, h / 2 - 1, seed, md, rough=0.45)
    blob(c, w / 2, h / 2, w / 3, h / 3, seed + 2, dk, rough=0.4)
    for i in range(5):
        a = hf(i, seed, 1) * math.tau
        for s in range(int(w * 0.25), int(w * 0.48)):
            c.put(w / 2 + math.cos(a) * s, h / 2 + math.sin(a) * s * 0.8, dk)
    for i in range(3):
        c.put(w / 2 + (hf(i, seed, 3) - 0.5) * w * 0.4, h / 2 + (hf(i, seed, 4) - 0.5) * h * 0.4, ember)
    return c


def d_plate(size, seed, cols):
    c = Canvas(size, size)
    ink, dk, md, hi = cols
    rect(c, 0, 0, size, size, ink); rect(c, 1, 1, size - 2, size - 2, dk); rect(c, 2, 2, size - 4, size - 4, md)
    rect(c, 2, 2, size - 4, 1, hi)
    for (x, y) in ((3, 3), (size - 4, 3), (3, size - 4), (size - 4, size - 4)):
        c.put(x, y, ink); c.put(x - 1 if x > 3 else x + 1, y, hi if False else dk)
    line(c, 3, size // 2, size - 4, size // 2, dk)
    line(c, size // 2, 3, size // 2, size - 4, dk)
    return c


def d_hazard(w, h, seed, cols):
    c = Canvas(w, h)
    ink, amber = cols
    rect(c, 0, 0, w, h, ink)
    for y in range(h):
        for x in range(w):
            if (x + y) % 8 < 3 and 0 < y < h - 1:
                c.put(x, y, amber)
    for x in range(w):
        c.put(x, 0, amber if x % 3 else ink); c.put(x, h - 1, ink)
    return c


def d_barnacles(size, seed, cols):
    c = Canvas(size + 2, size)
    dk, md, hi = cols
    for i in range(6 + size // 4):
        x, y = 1 + int(hf(i, seed, 1) * (size - 2)), 1 + int(hf(i, seed, 2) * (size - 3))
        r = 1.3 + hf(i, seed, 3) * 1.2
        circle(c, x, y + 1, r, dk)
        circle(c, x, y, r, md)
        if r > 1.8:
            c.put(x, y, hi)
            c.put(x - 1, y - 1, hi)
    return c


def d_bones(w, h, seed, cols):
    c = Canvas(w, h)
    dk, md, hi = cols
    # a fish skeleton: spine, ribs, skull
    cy = h // 2
    for x in range(2, w - 3):
        c.put(x, cy, md)
    for x in range(4, w - 5, 2):
        c.put(x, cy - 1, hi if x % 4 == 0 else md); c.put(x, cy + 1, hi if x % 4 == 0 else md)
        if h > 7:
            c.put(x, cy - 2, md); c.put(x, cy + 2, md)
    circle(c, w - 3, cy, 2.2, md); c.put(w - 3, cy - 1, dk); c.put(w - 2, cy, hi)
    for (x, y) in ((0, cy - 1), (0, cy + 1), (1, cy)):
        c.put(x, y, dk)
    return c


def d_glyph(size, seed, cols):
    c = Canvas(size, size)
    dk, md, glow = cols
    cx = cy = size / 2.0
    for y in range(size):
        for x in range(size):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if abs(r - size * 0.42) < 0.7:
                c.put(x, y, md if (x + y) % 4 else dk)
            if abs(r - size * 0.2) < 0.6:
                c.put(x, y, dk)
    for k in range(6):  # six rays
        a = k * math.tau / 6 + hf(seed, 2) * 0.4
        for s in range(int(size * 0.22), int(size * 0.4)):
            c.put(cx + math.cos(a) * s, cy + math.sin(a) * s, md)
    c.put(cx, cy, glow); c.put(cx - 1, cy, glow); c.put(cx, cy - 1, glow); c.put(cx - 1, cy - 1, glow)
    return c


def d_kelp(w, h, seed, cols):
    c = Canvas(w, h)
    dk, md, lt = cols
    for blade in range(3):
        x = 1 + blade * (w // 3)
        y = h - 2 - (blade % 2) * 2
        for s in range(w // 2):
            y2 = y - int(math.sin(s * 0.7 + blade + seed) * 1.5)
            c.put(x + s, y2, md); c.put(x + s, y2 + 1, dk)
            if s % 3 == 0:
                c.put(x + s, y2 - 1, lt)
    return c


def make_decals():
    names = {}
    # Archive (floors: warm brown stone)
    ink, brn, bs = P["ink_warm"], P["brown"], P["bone_shade"]
    names["archive_halls_pages"] = d_pages(15, 11, 3, P["ink_warm"], (P["steel_dark"], P["grey_dark"]))
    names["archive_orrery_star"] = d_star(21, 4, (P["ink_warm"], P["brown"], P["brown"]))
    names["archive_stacks_pages"] = d_pages(12, 10, 9, P["ink_warm"], (P["steel_dark"], P["brown"]))
    names["archive_wells_stain"] = d_stain(17, 12, 6, (P["ink_violet"], P["violet_deep"], P["violet"]))
    # Iron Citadel (floors: cold dark steel)
    names["citadel_courts_scorch"] = d_scorch(19, 15, 2, (P["ink_chrome"], P["chrome_dark"], P["flame"]))
    names["citadel_gates_plate"] = d_plate(16, 5, (P["ink_chrome"], P["ink_cold"], P["chrome_dark"], P["chrome"]))
    names["citadel_lifts_hazard"] = d_hazard(21, 11, 1, (P["ink_signal"], P["signal_dark"]))
    # Ul-Thalos (floors: wet drowned stone); one set per zone, each tinted a little differently
    zones = {
        "breakwater": ((P["ink_drowned"], P["drowned_dark"], P["drowned"]), (P["ink_drowned"], P["steel_dark"], P["bone_shade"]), 11),
        "gate": ((P["ink_drowned"], P["steel_dark"], P["bone_shade"]), (P["ink_drowned"], P["bone_shade"], P["bone_mid"]), 23),
        "spire": ((P["ink_biolume"], P["biolume_dark"], P["biolume"]), (P["ink_biolume"], P["steel_dark"], P["bone_shade"]), 37),
        "steps": ((P["ink_cold"], P["grey_dark"], P["grey"]), (P["ink_cold"], P["grey_dark"], P["bone_shade"]), 51),
    }
    for z, (tone, bone, seed) in zones.items():
        names["spire_%s_barnacles" % z] = d_barnacles(9 + seed % 3, seed, tone)
        names["spire_%s_bones" % z] = d_bones(14 + seed % 3, 7 + seed % 2, seed, bone)
        names["spire_%s_glyph" % z] = d_glyph(15 + seed % 3, seed, (tone[0], tone[1], P["biolume"] if z == "spire" else P["biolume_dark"]))
        names["spire_%s_kelp" % z] = d_kelp(14 + seed % 4, 7, seed % 5, (P["ink_green"], P["ink_green"], P["moss_dark"]))
    for k, c in names.items():
        save(c, "decals/" + k, note="floor decal, top-down, no outline")


# =============================================================================================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    only = [s for s in args.only.split(",") if s]
    steps = [("pantheon", make_pantheon_fx), ("spells", make_spell_fx), ("markers", make_markers), ("obstacles", make_obstacles),
             ("holmgang", make_holmgang), ("coin", make_coin), ("icons", make_icons), ("decals", make_decals)]
    for name, fn in steps:
        if not only or name in only:
            fn()
    mp = os.path.join(HERE, "manifest.json")
    old = json.load(open(mp)) if os.path.exists(mp) else {}
    old.update(MANIFEST)
    json.dump(old, open(mp, "w"), indent=1, sort_keys=True)
    print("wrote", len(MANIFEST), "pieces")


if __name__ == "__main__":
    main()
