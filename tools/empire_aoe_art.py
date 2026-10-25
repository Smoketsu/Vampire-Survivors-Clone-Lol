#!/usr/bin/env python3
"""empire_aoe_art.py: the procedural pixel art of Act III's ground effects, beams and zones.

GDD 15.0 "Act III AoE art" (audit docs/art/audit/act3.md, section A, on branch audit/act3-art): the
Electronic Empire's warnings, beams and zones (the orbital strikes of the Purge Protocol and the
Citadel's guns, the impact flash of ~30 Act III call sites, the Shield Gate walls, the laser grid,
the furnace channels and conveyor belts, the scrap storm veil, the Juggernaut's flame, the Arc
Engineer's static field, the mortar landings, Deus Ex Machina's rings, pulse, sweep and lance, the
Motherboard's stamps, magnets and claws, the Lock-On reticles) and the necromancer's Death Ray were
flat code shapes beside pixel art. This tool draws every piece ON THE ART GRID (1 art px = 1 layout
px) in the locked palette (tools/palette.json), deterministically (a fixed integer hash, no RNG),
so a rerun rebuilds the same files bit for bit. No image generation.

The pieces follow the approved Act I families (tools/covenant_aoe_art.py, tools/aoe_art.py) so they
stay crisp and EXACT at any gameplay size (scripts/fx/empire_fx.gd draws them, numbers in
scripts/data/empire_fx_data.gd): band pieces tiled at 1:1 along the exact hit edge, a seamless fill
tile laid as clipped 2 px rows, beam bodies scrolled along a ray, small stills and short strips.
On top of that the Empire has its OWN visual language, so an Act III warning reads as the machine's
and never as the Covenant's gold: the chrome and signal ramps, a hazard-striped red / amber band
with cyan-white targeting ticks, a red HEX grid fill (not the Covenant's diagonal hatch), a
cyan-white scan line as the timing front, targeting brackets that close in on the area as the
strike nears, white-hot cores, sparks and chrome shards.

Translucent ground pieces (the gate field, beam glows, the furnace haze, the pulse front's tail) use
2-4 stepped alpha levels; the storm veil and its grit are smooth grey masks (not pixel art, tinted
in the game, like holy/soft_disc); every other piece is fully opaque or fully transparent.

Usage (from the repo root):
    python3 tools/empire_aoe_art.py            # writes every PNG under assets/sprites/
    python3 tools/empire_aoe_art.py --review docs/art/act3_aoe_review
                                               # + review images (1x, 4x nearest, GIFs)
    python3 tools/empire_aoe_art.py --only empire_fx/edge,effects/empire_blast
"""
import argparse
import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from covenant_aoe_art import (Canvas, P, ROOT, SPRITES, anoise, from_bitmap, hf, hsh,  # noqa: E402  (tools/ sibling)
                              polar, strip_of, vnoise)

# --- Colours used here (palette names) ---------------------------------------------------------
INK_CH = P["ink_chrome"]  # Chrome's outline ink.
CH_DK = P["chrome_dark"]  # Chrome in shadow.
CH = P["chrome"]  # Chrome.
CH_L = P["chrome_light"]  # Lit chrome.
GLINT = P["chrome_glint"]  # Cyan-white glint: the Empire's targeting colour.
INK_SG = P["ink_signal"]  # Signal ink.
SG_DK = P["signal_dark"]  # Signal housing dark.
SG_RED = P["signal_red"]  # Warning red.
SG_AMB = P["signal_amber"]  # Hard amber.
SG_GLOW = P["signal_glow"]  # White-hot core.
FLAME = P["flame"]  # Molten orange.
INK_W = P["ink_warm"]  # Warm ink (slag, iron).
BROWN = P["brown"]  # Slag brown.
BROWN_L = P["brown_light"]  # Rust highlight.
STEEL_DK = P["steel_dark"]  # Iron rim.
STEEL = P["steel"]  # Rivets.
INK_COLD = P["ink_cold"]  # Belt rubber.
GREY_DK = P["grey_dark"]  # Belt slats.
INK_VIO = P["ink_violet"]  # Death Ray (the necromancer's soul laser): ink.
VIO_DEEP = P["violet_deep"]  # Deep violet.
VIO = P["violet"]  # Violet.
VIO_GLOW = P["violet_glow"]  # Violet glow.
VIO_FLARE = P["violet_flare"]  # Violet flare core.
INK_GREEN = P["ink_green"]  # Soul ink (the finale's binding: the necromancer's power).
SOUL_DK = P["soul_dark"]  # Soul dark.
SOUL = P["soul"]  # Soul fire.
SOUL_GLOW = P["soul_glow"]  # Soul glow.
WHITE = (255, 255, 255)  # Grey-mask white (storm veil, grit).

# Ramps an impact strip is drawn in: (ink, dark, mid, bright, core, spark).
BLAST_RAMPS = {
    "amber": (INK_SG, SG_DK, SG_RED, SG_AMB, SG_GLOW, GLINT),
    "red": (INK_SG, INK_SG, SG_DK, SG_RED, SG_AMB, SG_GLOW),
    "chrome": (INK_CH, CH_DK, CH, CH_L, GLINT, SG_GLOW),
}


def save_frames(frames: list, keys: list) -> None:
    """Writes one canvas per key (frames of a tiled loop: a strip region cannot repeat)."""
    for cv, key in zip(frames, keys):
        cv.save(key)


def dither(x: int, y: int, a: float) -> bool:
    """Ordered 4 x 4 Bayer dither: True where a pixel of coverage `a` (0..1) is set."""
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    return a * 16.0 > bayer[y % 4][x % 4] + 0.5


# =================================================================================================
# 1. The Empire's telegraph set (orbital strikes, guns, mortars, stomps, stamps, every shared
#    Effect telegraph on an Act III stage)
# =================================================================================================

def e_edge() -> Canvas:
    """empire_fx/edge: one 10 px piece of the Empire's warning band, row 0 OUTSIDE: signal ink, a
    warning-red row, two rows of hazard stripes (amber on ink, period 5 so two fit a piece and
    the joins are seamless), a red row and a dark inner row. The hit edge runs through row 3."""
    cv = Canvas(10, 6)
    for x in range(10):
        cv.put(x, 0, INK_SG)
        cv.put(x, 1, SG_RED)
        for y in (2, 3):
            cv.put(x, y, SG_AMB if (x + y) % 5 < 3 else INK_SG)
        cv.put(x, 4, SG_RED)
        cv.put(x, 5, SG_DK)
    return cv


def e_edge_tick() -> Canvas:
    """empire_fx/edge_tick: the band piece with a cyan-white targeting tick pointing INTO the
    danger (every other piece): the Empire's toothless, measured edge (the Covenant's has teeth)."""
    cv = e_edge()
    out = Canvas(10, 10)
    out.im.alpha_composite(cv.im, (0, 0))
    out.px = out.im.load()
    for y in range(6, 10):
        out.put(4, y, GLINT)
        out.put(5, y, CH_L if y < 9 else GLINT)
    for y in range(6, 10):
        out.put(3, y, INK_CH)
        out.put(6, y, INK_CH)
    out.put(4, 9, GLINT)
    return out


def e_front() -> Canvas:
    """empire_fx/front: the timing front, a cyan-white scan line (8 px): lit chrome, a glint row,
    lit chrome. Tiled at radius x progress (circle, cone), across a lane, round a stamp square."""
    return from_bitmap([
        "llllllll",
        "gggggggg",
        "lclllcll",
    ], {"l": CH_L, "g": GLINT, "c": CH})


def e_hex() -> Canvas:
    """empire_fx/hex: the Empire's fill, a seamless 14 x 24 tile of a red hex grid (1 px warning-red
    cell walls, amber nodes where three cells meet), laid row by row inside the exact danger shape
    (drawn translucent; denser inside the part the timing has filled). Replaces the Covenant's
    diagonal hatch on every Act III warning."""
    w, h = 14, 24
    cv = Canvas(w, h)
    centres = []
    for j in range(-1, 4):
        for i in range(-1, 3):
            centres.append((i * w + (j % 2) * w / 2.0, j * h / 2.0))
    for y in range(h):
        for x in range(w):
            px, py = x + 0.5, y + 0.5
            ds = sorted(math.hypot(px - cx, (py - cy) * 1.0) for cx, cy in centres)
            if ds[1] - ds[0] < 1.05:
                node = ds[2] - ds[0] < 2.2
                cv.put(x, y, SG_AMB if node else SG_RED)
    return cv


def e_chevron() -> Canvas:
    """empire_fx/chevron: a double chevron pointing +x (amber with a white-hot edge, signal ink
    outline): the direction marks of an Empire lane, lit once the timing passes them, and the
    sweep marks of the laser grid's band."""
    cv = Canvas(13, 13)
    for y in range(1, 12):
        dy = abs(y - 6)
        for x0 in (1, 6):
            for x in range(x0, x0 + 6):
                s = (x - x0) + dy
                if 3 <= s <= 4:
                    cv.put(x, y, SG_GLOW if (y < 6 and s == 3) else SG_AMB)
    cv.outline(INK_SG)
    return cv


def e_target() -> Canvas:
    """empire_fx/target: the impact point (15 x 15): a cyan-white crosshair with a gap at its heart
    and a warning-red centre pip, in chrome ink."""
    rows = [
        ".......k.......",
        "......kgk......",
        "......kgk......",
        "......klk......",
        ".......k.......",
        "...............",
        ".kkkk.....kkkk.",
        "kgglk..r..klggk",
        ".kkkk.....kkkk.",
        "...............",
        ".......k.......",
        "......klk......",
        "......kgk......",
        "......kgk......",
        ".......k.......",
    ]
    return from_bitmap(rows, {"k": INK_CH, "g": GLINT, "l": CH_L, "r": SG_RED})


def e_bracket() -> Canvas:
    """empire_fx/bracket: one corner of the targeting box (9 x 9, the corner at the top left, arms
    along +x and +y): cyan-white in chrome ink. Four close in on an orbital strike or a stamp as it
    nears, ending on the area's bounding box."""
    rows = [
        "kkkkkkkkk",
        "kgggggggk",
        "kglkkkkkk",
        "kgk......",
        "kgk......",
        "kgk......",
        "kgk......",
        "kgk......",
        "kkk......",
    ]
    return from_bitmap(rows, {"k": INK_CH, "g": GLINT, "l": CH_L})


def e_uplink() -> Canvas:
    """empire_fx/uplink: the orbital uplink column (16 x 96, base on the bottom row): a cyan-white
    targeting beam from the sky with a white core and scan rungs, stepped alpha fading upward;
    stretched to height over a strike's last moment (the Purge Protocol and the Citadel's guns)."""
    w, h = 16, 96
    cv = Canvas(w, h)
    for y in range(h):
        up = 1.0 - y / (h - 1.0)  # 1 at the top, 0 at the base.
        a = 255 if up < 0.35 else (170 if up < 0.7 else 90)
        for x in range(w):
            d = abs(x - 7.5)
            if d < 1.0:
                cv.put(x, y, SG_GLOW if up < 0.5 else GLINT, a)
            elif d < 2.0:
                cv.put(x, y, GLINT, a)
            elif d < 3.5:
                cv.put(x, y, CH_L, a if (y % 6) else min(255, a + 60))
            elif d < 5.0 and y % 6 == 0:
                cv.put(x, y, CH_L, a)
            elif d < 6.0 and up < 0.3 and y % 12 == 0:
                cv.put(x, y, CH, a)
    return cv


# =================================================================================================
# 2. Impact strips (EffectManager.impact(..., anim): AnimData empire_blast / _red / _chrome)
# =================================================================================================

def _blast_frames(ramp_name: str, S: int = 128, n: int = 8, seed: int = 0) -> list:
    """The frames of an Empire blast `S` px square, `n` frames (see fx_blast): every radius scales
    with S / 128, the timing with the frame count; `seed` varies the noise."""
    ink, dark, mid, bright, core, spark = BLAST_RAMPS[ramp_name]
    sc = S / 128.0  # Size scale.
    c = S / 2.0
    frames = []
    fire_tab = (11, 21, 28, 27, 21, 13, 0, 0)  # Fireball radius over the play (art px at 128).
    for f in range(n):
        cv = Canvas(S, S)
        t = f / (n - 1.0)
        u = t * 7.0
        i0 = min(6, int(u))
        fr = (fire_tab[i0] + (fire_tab[i0 + 1] - fire_tab[i0]) * (u - i0)) * sc  # Fireball radius (px).
        ring_r = (15 + 39 * (1 - (1 - t) ** 2.0)) * sc  # Shock ring radius: 0.84 of the half at the end.
        thick = (7.0 * (1 - t) + 2.5) * sc
        late = t >= 0.5  # Ring broken into segments.
        for y in range(S):
            for x in range(S):
                d, a = polar(cv, c, c, x, y)
                # Shock ring, broken into hex-like segments late and eaten away as it fades.
                seg = (math.floor((a + math.pi) / (2 * math.pi) * 15 * max(1.0, sc * 0.75)) + f) % 4
                if ring_r - thick <= d < ring_r and hf(x // 2, y // 2, 60 + f + seed) > t * 0.55:
                    if seg != 0 or not late:
                        cv.put(x, y, bright if d > ring_r - thick * 0.5 else mid)
                    continue
                # Scorched smoke filling in behind the ring (dust clumps, dithered thinner).
                if t >= 0.4 and fr * 0.7 <= d < ring_r - thick:
                    band = 1.0 - abs(d - (ring_r - thick) * 0.78) / max(6.0 * sc, ring_r * 0.32)  # A smoke ring inside the shock.
                    cov = 0.62 * (1.0 - t) ** 1.3 * band * (0.5 + vnoise(x / 6.0, y / 6.0, 72 + f // 2 + seed))
                    if dither(x, y, cov):
                        cv.put(x, y, CH_DK if hf(x // 2, y // 2, 71 + seed) > 0.4 else INK_CH)
                # The fireball: a ragged white-hot / bright / mid ball, growing then collapsing.
                if fr > 0.5:
                    edge = fr * (0.8 + 0.2 * anoise(a, 9, 80 + f + seed))
                    if d < edge:
                        k = d / edge
                        col = core if k < 0.45 - 0.08 * max(0.0, u - 2) else (bright if k < 0.78 else mid)
                        if u >= 3 and hf(x, y, 81 + f + seed) > 0.9 - 0.08 * u:
                            col = dark
                        cv.put(x, y, col)
        if t < 0.2:  # Lens glint: a four-point star, long thin arms.
            arm = int((30 + 70 * t) * sc)
            for k in range(-arm, arm + 1):
                w = 2 if abs(k) < arm * 0.35 else 1
                for o in range(w):
                    col = core if abs(k) < arm * 0.5 else spark
                    cv.put(int(c) + k, int(c) - 1 + o, col)
                    cv.put(int(c) - 1 + o, int(c) + k, col)
        for m in range(int(22 * max(1.0, sc * 0.8))):  # Sparks (streaks) and chrome shards (squares) flung out.
            a = 2 * math.pi * hf(m, 11 + seed)
            rr = (12 + (46 + 10 * hf(m, 12 + seed)) * (1 - (1 - t) ** 1.6)) * sc
            if t > 0.75 and m % 2:
                continue
            px, py = c + math.cos(a) * rr, c + math.sin(a) * rr
            if m % 3:
                ln = (9 * (1 - t) + 3) * min(sc, 1.5)
                cv.thick_line(px, py, px - math.cos(a) * ln, py - math.sin(a) * ln, 1.6, spark if m % 2 else core)
            else:
                cv.rect(int(px), int(py), 3, 2, P["chrome_light"] if ramp_name != "chrome" else bright)
                cv.put(int(px), int(py) + 2, INK_CH)
                cv.put(int(px) + 1, int(py) + 2, INK_CH)
        frames.append(cv)
    return frames


def fx_blast(ramp_name: str) -> Canvas:
    """effects/empire_blast(_red, _chrome): an Empire strike / slam landing (8 frames of 128 px):
    a white-hot flash with a four-point lens glint, a hex-segmented shock ring rolling out to the
    gameplay radius (0.84 of the frame half: AnimData fill 1.2), sparks and chrome shards flung
    out, a scorched smoke ring dissolving. Binary alpha. Ramps: amber (strikes, slams), red
    (overloads, heavy hits), chrome (energy pops, shields, Kestrel's feints)."""
    return strip_of(_blast_frames(ramp_name))


def fx_boss_blast() -> Canvas:
    """effects/empire_boss_death: an Empire stage boss falls (Kestrel, the Motherboard, Deus Ex
    Machina; 10 frames of 256 px): a warning-red blast at the centre (its shock ring ending at 0.84
    of the frame half), four amber secondary blasts popping one after another round the hull and a
    cyan-white shock ring racing out to 0.91 of the frame half (AnimData fill 1.1, as boss_death)."""
    S, n = 256, 10
    main = _blast_frames("red", S, n, 3)
    subs = [(_blast_frames("amber", 96, 8, 10 + k), off, start) for k, (off, start) in enumerate(
        (((-44, -30), 1), ((40, -22), 2), ((-26, 40), 3), ((46, 34), 4)))]
    out = []
    c = S / 2.0
    for f in range(n):
        cv = main[f]
        for frs, (ox, oy), st in subs:
            j = f - st
            if 0 <= j < len(frs):
                cv.im.alpha_composite(frs[j].im, (int(c + ox - 48), int(c + oy - 48)))
                cv.px = cv.im.load()
        t = f / (n - 1.0)
        rr = 30 + 86 * (1 - (1 - t) ** 2.2)  # The cyan-white shock: 116 px (0.91 of 128) at the end.
        th = 3.0 * (1 - t) + 1.5
        for y in range(S):
            for x in range(S):
                d, _ = polar(cv, c, c, x, y)
                if rr - th <= d < rr and hf(x // 2, y // 2, 90 + f) > t * 0.6:
                    cv.put(x, y, GLINT if d > rr - th * 0.5 else CH_L)
        out.append(cv)
    return strip_of(out)


# =================================================================================================
# 3. Beams: the Death Ray (the necromancer's soul laser), the laser grid, the Judgment Lance
# =================================================================================================

def ray_body(ramp: tuple, h: int, streak: tuple) -> Canvas:
    """A 16 px seamless beam body piece `h` rows tall, scrolled along the beam: dark edge rows, the
    mid colour, a glow band and a bright core, with flow streaks (period 16) in the glow band.
    `ramp` = (edge, mid, glow, core, white), `streak` = (colour, colour)."""
    edge, mid, glow, core, white = ramp
    cv = Canvas(16, h)
    for y in range(h):
        d = abs(y - (h - 1) / 2.0) / ((h - 1) / 2.0)  # 0 at the centre, 1 at the edge.
        for x in range(16):
            if d > 0.86:
                col = edge
            elif d > 0.62:
                col = mid
            elif d > 0.3:
                col = glow
                if (x + (0 if y < h / 2 else 8)) % 16 < 5:
                    col = streak[0] if (x % 16) < 3 else streak[1]
            elif d > 0.12 or h < 10:
                col = core
            else:
                col = white
            cv.put(x, y, col)
    return cv


def ray_glow(col, h: int, levels=(70, 130, 190)) -> Canvas:
    """An 8 px glow piece `h` rows tall in `col`, three stepped alphas falling off from the centre;
    stretched to a little over twice the beam's width under it."""
    cv = Canvas(8, h)
    for y in range(h):
        d = abs(y - (h - 1) / 2.0) / ((h - 1) / 2.0)
        a = levels[2] if d < 0.3 else (levels[1] if d < 0.62 else (levels[0] if d < 0.95 else 0))
        if a:
            for x in range(8):
                cv.put(x, y, col, a)
    return cv


def burst_tip(ramp: tuple, size: int, frames: int) -> Canvas:
    """A beam's blazing head (frames of `size` px): a core disc, a glow ring and eight spokes that
    turn and flicker frame by frame. `ramp` = (ink, mid, glow, core)."""
    ink, mid, glow, core = ramp
    out = []
    c = size / 2.0
    for f in range(frames):
        cv = Canvas(size, size)
        rot = f * math.pi / (4 * frames) * 2
        for y in range(size):
            for x in range(size):
                d, a = polar(cv, c, c, x, y)
                core_r = size * (0.16 + 0.03 * (f % 2))
                if d < core_r:
                    cv.put(x, y, core)
                elif d < core_r + 2:
                    cv.put(x, y, glow)
                else:
                    sp = abs(((a - rot) / (math.pi / 4)) % 1.0 - 0.5)  # Spoke closeness 0 (on) .. 0.5.
                    reach = size * (0.46 if (round((a - rot) / (math.pi / 4)) + f) % 2 == 0 else 0.34)
                    if d < reach and sp < 0.09 * (1.0 - d / reach) + 0.02:
                        cv.put(x, y, glow if d < reach * 0.6 else mid)
        cv.outline(ink)
        out.append(cv)
    return strip_of(out)


def death_ray_body() -> Canvas:
    """empire_fx/ray_body: the Death Ray's body (16 x 10 seamless = the beam's base 10 px width,
    scrolled outward along it and drawn at its exact width): violet edges, violet-glow bands with
    flare flow streaks, a 2 px violet-flare core: the necromancer's soul laser, never the Empire's red."""
    rows = [
        "vvvvvvvvvvvvvvvv",
        "gggggggggggggggg",
        "ffggggggffgggggg",
        "gggfffgggggggfff",
        "FFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFF",
        "gggggfffggggfggg",
        "ggfgggggggffgggg",
        "gggggggggggggggg",
        "vvvvvvvvvvvvvvvv",
    ]
    return from_bitmap(rows, {"v": VIO, "g": VIO_GLOW, "f": VIO_FLARE, "F": VIO_FLARE})


def death_ray_glow() -> Canvas:
    """empire_fx/ray_glow: the Death Ray's glow (8 x 12, three stepped violet-glow alphas), under the
    beam and as its fading afterglow."""
    return ray_glow(VIO_GLOW, 12)


def death_ray_tip() -> Canvas:
    """empire_fx/ray_tip: the Death Ray's tip burst (4 frames of 24 px): a flare core, a glow ring
    and turning spokes; also its origin flare, smaller."""
    return burst_tip((INK_VIO, VIO, VIO_GLOW, VIO_FLARE), 24, 4)


def laser_body() -> Canvas:
    """empire_fx/laser_body: a laser grid beam's body (16 x 10 seamless = the beam's 10 px width):
    dark signal edges, warning red, amber, a white-hot core with flow streaks."""
    return ray_body((SG_DK, SG_RED, SG_AMB, SG_GLOW, SG_GLOW), 10, (SG_GLOW, SG_RED))


def laser_glow() -> Canvas:
    """empire_fx/laser_glow: the laser's red glow (8 x 12, three stepped alphas), at 2.6 x its width."""
    return ray_glow(SG_RED, 12, (80, 140, 200))


def laser_warn() -> Canvas:
    """empire_fx/laser_warn: a telegraphed beam's dashed sight line (8 x 3): a 5 px warning-red dash
    with a white-hot heart and a gap; blinks and thickens as the beam arms."""
    return from_bitmap([
        "rrrrr...",
        "aggga...",
        "rrrrr...",
    ], {"r": SG_RED, "a": SG_AMB, "g": SG_GLOW})


def laser_cap() -> Canvas:
    """empire_fx/laser_cap: a laser emitter at each end of a beam (2 frames of 16 px: armed, a red
    lens in a chrome housing; firing, the lens white-hot with a flare)."""
    frames = []
    for f in range(2):
        cv = Canvas(16, 16)
        for y in range(16):
            for x in range(16):
                d, _ = polar(cv, 8, 8, x, y)
                if d < 7.0:
                    cv.put(x, y, CH_DK if d > 5.0 else (SG_RED if f == 0 else SG_AMB))
                if d < 3.2:
                    cv.put(x, y, SG_AMB if f == 0 else SG_GLOW)
                if f == 1 and d < 1.6:
                    cv.put(x, y, SG_GLOW)
        cv.put(5, 4, CH_L)
        cv.put(4, 5, CH_L)
        cv.outline(INK_CH)
        frames.append(cv)
    return strip_of(frames)


def lance_body() -> Canvas:
    """empire_fx/lance_body: the Judgment Lance's body (16 x 30 seamless = its 30 px width): amber
    edges, white-hot glow and core, flow streaks."""
    return ray_body((SG_RED, SG_AMB, SG_GLOW, SG_GLOW, SG_GLOW), 30, (SG_AMB, SG_GLOW))


def lance_glow() -> Canvas:
    """empire_fx/lance_glow: the lance's amber glow (8 x 16, stepped alphas), at 1.8 x its width."""
    return ray_glow(SG_AMB, 16, (60, 110, 170))


def lance_tip() -> Canvas:
    """empire_fx/lance_tip: the lance's blazing head (4 frames of 32 px), amber and white-hot."""
    return burst_tip((INK_SG, SG_AMB, SG_GLOW, SG_GLOW), 32, 4)


# =================================================================================================
# 4. The Iron Citadel: Shield Gate walls; the Scrap Wastes: storm veil, pylon stump
# =================================================================================================

def gate_wall() -> Canvas:
    """empire_fx/gate_wall: a Shield Gate's energy wall (22 x 18 seamless along it = the wall's 18 px
    thickness, scrolled along it): white-hot edge lines, amber edge rows, a translucent amber field
    (two stepped alphas) crossed by a hex lattice of signal glow (cells 11 px wide: two a piece)."""
    w, h = 22, 18
    cv = Canvas(w, h)
    centres = [(i * 11.0 + (j % 2) * 5.5, 3.5 + j * 9.5) for j in range(-1, 3) for i in range(-1, 4)]
    for y in range(h):
        for x in range(w):
            if y in (0, h - 1):
                cv.put(x, y, SG_GLOW)
            elif y in (1, h - 2):
                cv.put(x, y, SG_AMB)
            else:
                ds = sorted(math.hypot(x + 0.5 - cx, y + 0.5 - cy) for cx, cy in centres)
                if ds[1] - ds[0] < 1.0:
                    cv.put(x, y, SG_GLOW, 200)
                else:
                    cv.put(x, y, SG_AMB, 110 if y in (2, h - 3) else 70)
    return cv


def gate_glow() -> Canvas:
    """empire_fx/gate_glow: the wall's outer glow (8 x 28 = thickness + 10, stepped amber alphas)."""
    return ray_glow(SG_AMB, 28, (40, 70, 0))


def gate_post() -> Canvas:
    """empire_fx/gate_post: a wall's end emitter (22 x 22): a chrome housing with lit top bevel and
    an amber core lens with a white-hot heart, ink outline."""
    cv = Canvas(22, 22)
    for y in range(22):
        for x in range(22):
            d, a = polar(cv, 11, 11, x, y)
            if d < 10.0:
                col = CH_DK
                if d > 7.5:
                    col = CH_L if -2.6 < a < -0.6 else (CH if a < 0 else CH_DK)
                elif d < 5.0:
                    col = SG_AMB if d > 2.2 else SG_GLOW
                elif d < 6.0:
                    col = INK_SG
                cv.put(x, y, col)
    for k in range(4):  # Four bolts.
        ang = math.pi / 4 + k * math.pi / 2
        cv.put(int(11 + math.cos(ang) * 8.4), int(11 + math.sin(ang) * 8.4), CH_L)
    cv.outline(INK_CH)
    return cv


def gate_cable() -> Canvas:
    """empire_fx/gate_cable: a generator's power cable piece (8 x 5, scrolled toward the wall): an
    amber line with a white-hot heart and a brighter pulse node every piece."""
    return from_bitmap([
        "kkkkkkkk",
        "aaaaaaga",
        "gggggggg",
        "aaaaaaga",
        "kkkkkkkk",
    ], {"k": INK_SG, "a": SG_AMB, "g": SG_GLOW})


def storm_veil() -> Canvas:
    """empire_fx/storm_veil: the scrap storm's dust veil (256 px grey mask, smooth alpha, tinted
    with the dust colour in the game): clear inside 0.24 of the half-size (the storm's clear radius
    round the necromancer), thickening to 0.65 at 0.55 and beyond, mottled by low-frequency dust
    clumps. One textured rect replaces 12-20 wide arcs a frame (GDD 15.0 "Web GL id leak patch")."""
    n = 256
    cv = Canvas(n, n)
    mid = (n - 1) / 2.0
    clear, full = 0.2393, 0.55
    for y in range(n):
        for x in range(n):
            u = math.hypot(x - mid, y - mid) / (n / 2.0)
            if u < clear - 0.01:
                continue
            ramp = max(0.0, min(1.0, (u - clear) / (full - clear)))
            soft = max(0.0, min(1.0, (u - clear + 0.01) / 0.02))
            clump = 0.82 + 0.36 * vnoise(x / 18.0, y / 18.0, 5) + 0.12 * (vnoise(x / 6.0, y / 6.0, 6) - 0.5)
            a = (0.10 + 0.55 * ramp) * soft * clump
            if a > 0.004:
                cv.put(x, y, WHITE, int(round(min(1.0, a) * 255)))
    return cv


def storm_grit() -> Canvas:
    """empire_fx/storm_grit: the storm's grit (128 x 128 seamless grey mask, two stepped alphas):
    short streaks and specks of scrap leaning with the wind (+x, a 0.28 slope), scrolled with it."""
    n = 128
    cv = Canvas(n, n)
    for m in range(56):
        x0 = hf(m, 1) * n
        y0 = hf(m, 2) * n
        ln = 6 + int(hf(m, 3) * 12)
        a = 255 if m % 3 == 0 else 150
        for k in range(ln):
            cv.put(int(x0 + k) % n, int(y0 + k * 0.28) % n, WHITE, a)
        if m % 4 == 0:
            cv.put(int(x0 + ln + 3) % n, int(y0 + ln * 0.28) % n, WHITE, 255)
    return cv


def pylon_stump() -> Canvas:
    """empire_fx/pylon_stump: a fallen Signal Pylon's toppled mast (30 x 14 decal): a chrome mast
    lying broken across a scorched base plate, its dead signal lens dark."""
    cv = Canvas(30, 14)
    for y in range(14):
        for x in range(30):
            d, _ = polar(cv, 9, 8, x, y)
            if d < 6.5:
                cv.put(x, y, CH_DK if d > 3.5 else INK_CH)
    cv.thick_line(8, 8, 27, 3, 3.0, CH)
    cv.thick_line(9, 7, 27, 2, 1.0, CH_L)
    for k in range(3):
        cv.put(13 + k * 5, 6 - k, INK_CH)
    cv.put(27, 3, SG_DK)
    cv.put(28, 3, SG_DK)
    cv.outline(INK_CH)
    return cv


# =================================================================================================
# 5. The Assembly Halls: furnace channels and conveyor belts
# =================================================================================================

def _voronoi_edge(x: float, y: float, cell: float, seed: int, period: int) -> float:
    """Distance difference between the nearest and second-nearest jittered cell points (a crack
    network seamless over `period` px)."""
    gx, gy = math.floor(x / cell), math.floor(y / cell)
    n = int(period / cell)
    ds = []
    for j in range(-1, 2):
        for i in range(-1, 2):
            cx, cy = gx + i, gy + j
            px = (cx + 0.15 + 0.7 * hf(cx % n, cy % n, seed)) * cell
            py = (cy + 0.15 + 0.7 * hf(cx % n, cy % n, seed + 1)) * cell
            ds.append(math.hypot(x - px, y - py))
    ds.sort()
    return ds[1] - ds[0]


def furnace_slag() -> Canvas:
    """empire_fx/furnace_slag: a cold channel's slag crust (64 x 64 seamless): warm ink with brown
    clinker plates, dark seams between them, a few rusty highlights."""
    n = 64
    cv = Canvas(n, n)
    for y in range(n):
        for x in range(n):
            e = _voronoi_edge(x + 0.5, y + 0.5, 16.0, 31, n)
            if e < 1.1:
                col = INK_SG
            else:
                v = vnoise(x / 5.0, y / 5.0, 32)
                col = BROWN if v > 0.62 else INK_W
                if v > 0.8 and hf(x, y, 33) > 0.6:
                    col = BROWN_L
            cv.put(x, y, col)
    return cv


def furnace_embers() -> Canvas:
    """empire_fx/furnace_embers: the slag's glowing seams (64 x 64 seamless overlay, the same crack
    network): signal-dark seams with molten specks, faded in as the channel warms."""
    n = 64
    cv = Canvas(n, n)
    for y in range(n):
        for x in range(n):
            e = _voronoi_edge(x + 0.5, y + 0.5, 16.0, 31, n)
            if e < 1.1:
                h = hf(x // 3, y // 3, 34)
                cv.put(x, y, FLAME if h > 0.82 else (SG_RED if h > 0.5 else SG_DK))
    return cv


def furnace_molten(frame: int) -> Canvas:
    """empire_fx/furnace_molten_<f>: molten metal (64 x 64 seamless, 3 frames that flicker): flame
    orange with amber flows, white-hot veins and darker cooling skins; scrolled along the channel."""
    n = 64
    cv = Canvas(n, n)
    for y in range(n):
        for x in range(n):
            u = vnoise(x / 9.0, (y + frame * 3) / 9.0, 40) * 0.7 + vnoise(x / 4.0, y / 4.0, 41 + frame) * 0.3
            vein = abs(vnoise(x / 13.0, y / 13.0, 42) - 0.5)
            if vein < 0.035 + 0.01 * frame:
                col = SG_GLOW
            elif u > 0.68:
                col = SG_AMB
            elif u < 0.28:
                col = SG_RED
            else:
                col = FLAME
            cv.put(x, y, col)
    return cv


def furnace_rim() -> Canvas:
    """empire_fx/furnace_rim: a channel's iron rim (12 x 3, along both long sides): warm ink, dark
    steel with a rivet, warm ink."""
    return from_bitmap([
        "kkkkkkkkkkkk",
        "ssssssrsssss",
        "kkkkkkkkkkkk",
    ], {"k": INK_W, "s": STEEL_DK, "r": STEEL})


def furnace_warn() -> Canvas:
    """empire_fx/furnace_warn: a channel's warning edge (10 x 2 hazard stripes, red on signal ink):
    blinks on both edges while the channel is about to flare."""
    cv = Canvas(10, 2)
    for y in range(2):
        for x in range(10):
            cv.put(x, y, SG_RED if (x + y) % 5 < 3 else INK_SG)
    return cv


def furnace_haze() -> Canvas:
    """empire_fx/furnace_haze: the heat haze beside a burning channel (8 x 6, row 0 next to the rim,
    three stepped flame alphas falling off outward)."""
    cv = Canvas(8, 6)
    for y in range(6):
        a = (120, 90, 60, 45, 30, 18)[y]
        for x in range(8):
            cv.put(x, y, FLAME, a)
    return cv


def furnace_flame() -> Canvas:
    """empire_fx/furnace_flame: a flame tongue licking up from molten metal (4 frames of 9 x 14,
    base on the bottom row): flame orange, amber, a white-hot root."""
    frames = []
    for f in range(4):
        cv = Canvas(9, 14)
        sway = (0, 1, 0, -1)[f]
        top = (3, 1, 2, 4)[f]
        for y in range(top, 14):
            k = (y - top) / max(1.0, 13 - top)  # 0 at the tip, 1 at the base.
            half = 0.6 + 3.2 * math.sin(k * math.pi * 0.62)
            cx = 4 + sway * (1 - k)
            for x in range(9):
                d = abs(x + 0.5 - (cx + 0.5))
                if d <= half:
                    col = SG_GLOW if (k > 0.6 and d < half * 0.4) else (SG_AMB if d < half * 0.65 else FLAME)
                    cv.put(x, y, col)
        cv.outline(SG_DK)
        frames.append(cv)
    return strip_of(frames)


def belt_tile(width: int) -> Canvas:
    """empire_fx/belt_<width>: one 112 px repeat of a conveyor belt `width` px across (the belts are
    68, 72 and 80 px wide), running +x: chrome rails (a lit top row) with rollers every 16 px, dark
    rubber with grey slats every 14 px and a dim amber chevron every 28 px pointing along the belt.
    112 px holds 4 chevrons and 7 rollers, so the tile repeats seamlessly; it is scrolled with the
    belt's speed (one textured rect per belt instead of ~60 rects and lines)."""
    L = 112
    cv = Canvas(L, width)
    rail = 3
    inner = width - rail * 2
    arm = int(inner * 0.28)
    mid = rail + inner / 2.0
    for y in range(width):
        for x in range(L):
            if y < rail or y >= width - rail:
                col = CH_DK
                if y == 0:
                    col = CH_L
                if x % 16 in (0, 1) and y > 0:
                    col = INK_CH
                cv.put(x, y, col)
            else:
                col = INK_COLD
                if x % 14 in (0,):
                    col = GREY_DK
                elif x % 14 == 1:
                    col = INK_CH
                cv.put(x, y, col)
    for k in range(4):  # Chevrons (2 px arms; tip at a + arm / 2, wings at a - arm / 2 +- arm).
        a = 14 + k * 28
        tip = (a + arm * 0.5, mid)
        for wing in (mid - arm, mid + arm):
            cv.thick_line(a - arm * 0.5, wing, tip[0], tip[1], 2.0, SG_DK)
        cv.thick_line(tip[0] - 3, tip[1] - 3, tip[0], tip[1], 1.0, SG_AMB)  # A lit tip only: the code drew them at 42%.
        cv.thick_line(tip[0] - 3, tip[1] + 3, tip[0], tip[1], 1.0, SG_AMB)
    return cv


# =================================================================================================
# 6. Kit and boss pieces: Juggernaut flame, Arc Engineer field, mortar shell, Lock-On reticles,
#    Deus Ex Machina, the Motherboard
# =================================================================================================

def jug_flame(size: int) -> Canvas:
    """empire_fx/jug_flame_<i>: one billow of the Juggernaut's flame stream (4 frames of `size` px):
    a ragged ball of flame orange with an amber body and a white-hot heart, a dark signal fringe;
    placed 1:1 along the stream's cone (bigger toward its reach)."""
    frames = []
    c = size / 2.0
    for f in range(4):
        cv = Canvas(size, size)
        rad = size / 2.0 - 1.5
        for y in range(size):
            for x in range(size):
                d, a = polar(cv, c, c, x, y)
                edge = rad * (0.78 + 0.22 * anoise(a, 7, 50 + f))
                if d < edge:
                    k = d / edge
                    col = SG_GLOW if k < 0.3 else (SG_AMB if k < 0.6 else (FLAME if k < 0.88 else SG_RED))
                    if k > 0.6 and hf(x, y, 51 + f) > 0.86:
                        col = SG_DK
                    cv.put(x, y, col)
        frames.append(cv)
    return strip_of(frames)


def static_edge() -> Canvas:
    """empire_fx/static_edge: the Arc Engineer's static field rim (10 x 5, row 0 outside): a broken
    warning-red line with an amber crackle zig-zagging inside it."""
    return from_bitmap([
        "rrrr.rrrr.",
        "....a....g",
        "...a.a..a.",
        "a.a...aa..",
        ".a........",
    ], {"r": SG_RED, "a": SG_AMB, "g": SG_GLOW})


def spark() -> Canvas:
    """empire_fx/spark: a static spark (2 frames of 7 px): a four-point star, white-hot then amber."""
    a = from_bitmap([
        "...g...",
        "...g...",
        "..aga..",
        "gggwggg",
        "..aga..",
        "...g...",
        "...g...",
    ], {"g": SG_GLOW, "a": SG_AMB, "w": SG_GLOW})
    b = from_bitmap([
        ".......",
        "...a...",
        "..aga..",
        ".aggga.",
        "..aga..",
        "...a...",
        ".......",
    ], {"g": SG_GLOW, "a": SG_AMB})
    return strip_of([a, b])


def mortar_shell() -> Canvas:
    """empire_fx/mortar_shell: a Mortar Walker's shell in flight (2 frames of 10 px, turning): a
    chrome casing with an amber fuse light, ink outline."""
    frames = []
    for f in range(2):
        cv = Canvas(10, 10)
        for y in range(10):
            for x in range(10):
                d, a = polar(cv, 5, 5, x, y)
                if d < 3.6:
                    cv.put(x, y, CH_L if (a < -1.2 and a > -2.8) else (CH if d < 2.6 else CH_DK))
        if f == 0:
            cv.put(6, 3, SG_AMB)
            cv.put(6, 4, SG_GLOW)
        else:
            cv.put(3, 6, SG_AMB)
            cv.put(3, 5, SG_GLOW)
        cv.outline(INK_CH)
        frames.append(cv)
    return strip_of(frames)


def lock_reticle(r: int) -> Canvas:
    """empire_fx/lock_open / lock_locked: a Lock-On reticle on a painted target (2 frames: warning
    red, then white-hot for the locked blink): a 1.5 px ring of radius `r` and four ticks crossing it
    (3 px in, 4 px out), in signal ink."""
    size = 2 * (r + 5) + 1
    c = size / 2.0
    frames = []
    for f in range(2):
        cv = Canvas(size, size)
        col = SG_RED if f == 0 else SG_GLOW
        hi = SG_AMB  # The tick crossing the ring.
        for y in range(size):
            for x in range(size):
                d, a = polar(cv, c, c, x, y)
                if abs(d - r) < 0.8:
                    cv.put(x, y, col)
        mid = int(c)
        for k in range(r - 3, r + 5):
            for (dx, dy) in ((k, 0), (-k, 0), (0, k), (0, -k)):
                cv.put(mid + dx, mid + dy, hi if abs(k - r) < 1 else col)
        cv.outline(INK_SG)
        frames.append(cv)
    return strip_of(frames)


def band_piece(rows: list, cols: dict) -> Canvas:
    """A tiled band piece from text rows (row 0 outside)."""
    return from_bitmap(rows, cols)


def shock_edge() -> Canvas:
    """empire_fx/shock_edge: a Deus footfall shock ring piece (10 x 4): lit chrome with a glint row,
    broken into segments."""
    return band_piece([
        "kkkkkkkk..",
        "gggggggk..",
        "lllllllk..",
        "kkkkkkkk..",
    ], {"k": INK_CH, "g": GLINT, "l": CH_L})


def pulse_front() -> Canvas:
    """empire_fx/pulse_front: Deus's overload pulse front (12 x 26 = the front's 26 px, row 0 the
    leading edge, row 13 on the front's radius): a white-hot leading edge, amber, then a warning-red
    wake dithered thinner inward (three stepped alphas)."""
    w, h = 12, 26
    cv = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            if y < 2:
                cv.put(x, y, SG_GLOW)
            elif y < 5:
                cv.put(x, y, SG_AMB)
            elif y < 9:
                cv.put(x, y, SG_RED)
            elif y < 17:
                if dither(x, y, 1.0 - (y - 9) / 10.0):
                    cv.put(x, y, SG_RED, 200)
            elif dither(x, y, 0.35 - (y - 17) / 30.0):
                cv.put(x, y, SG_DK, 140)
    return cv


def pulse_charge() -> Canvas:
    """empire_fx/pulse_charge: the overload charge ring piece (8 x 3) closing on Deus: signal glow
    with an amber row and a gap."""
    return band_piece([
        "aaaaaa..",
        "gggggg..",
        "aaaaaa..",
    ], {"a": SG_AMB, "g": SG_GLOW})


def binding_edge() -> Canvas:
    """empire_fx/binding_edge: a link of the necromancer's soul binding closing on the broken engine
    (10 x 5): soul-green chain links, glowing."""
    return band_piece([
        ".kkkk.kkk.",
        "kssssksgsk",
        "kgggsksssk",
        "kssssksgsk",
        ".kkkk.kkk.",
    ], {"k": INK_GREEN, "s": SOUL, "g": SOUL_GLOW})


def magnet_edge() -> Canvas:
    """empire_fx/magnet_edge: a Motherboard magnet field ring piece (10 x 3): a warning-red coil wave
    with amber crests (tinted amber while it pulls)."""
    return band_piece([
        "..aa....aa",
        "rr..rrrr..",
        "..rr....rr",
    ], {"a": SG_AMB, "r": SG_RED})


def hangar_door() -> Canvas:
    """empire_fx/hangar_door: a Deus hangar door (3 frames of 36 x 24: shut, opening, open): chrome
    plates with hazard stripes, the red-lit bay showing as the doors part."""
    frames = []
    for f in range(3):
        cv = Canvas(36, 24)
        gap = (0, 6, 14)[f]
        for y in range(2, 22):
            for x in range(2, 34):
                col = INK_CH
                if 3 <= y < 21:
                    inside = abs(x + 0.5 - 18) < gap
                    if inside:
                        col = SG_RED if (y + x) % 7 else SG_AMB
                        if 8 <= y <= 15 and abs(x + 0.5 - 18) < gap * 0.5:
                            col = SG_GLOW
                    else:
                        col = CH_DK
                        if y in (3, 20) or (y + x) % 8 < 3 and (y < 6 or y > 17):
                            col = SG_AMB if (y < 6 or y > 17) and (y + x) % 8 < 3 else CH
                        if y == 4 and not ((y + x) % 8 < 3):
                            col = CH_L
                cv.put(x, y, col)
        cv.outline(INK_CH)
        frames.append(cv)
    return strip_of(frames)


def claw() -> Canvas:
    """empire_fx/claw: a Motherboard crane claw (2 frames of 16 x 16: open, clamped), the cable on
    the top row's centre: a chrome head with an amber light, two jaws."""
    frames = []
    for f in range(2):
        cv = Canvas(16, 16)
        cv.rect(4, 2, 8, 5, CH_L)
        cv.rect(4, 5, 8, 2, CH)
        cv.put(7, 3, SG_AMB)
        cv.put(8, 3, SG_GLOW)
        spread = 6 if f == 0 else 2
        for sx in (-1, 1):
            cv.thick_line(8 + sx * 2.5, 7, 8 + sx * spread, 13, 2.0, CH)
            cv.thick_line(8 + sx * spread, 13, 8 + sx * (spread - 2), 15, 1.6, CH_DK)
        cv.outline(INK_CH)
        frames.append(cv)
    return strip_of(frames)


# =================================================================================================
# Registry, review images
# =================================================================================================

# key -> (builder, kind, frames, description). kind: "tile", "still", "strip" (frames > 1), "mask".
ASSETS = {
    "empire_fx/edge": (e_edge, "tile", 1, "Empire warning band piece (10 x 6, row 0 outside): signal ink, warning red, two rows of amber hazard stripes, red, a dark inner row; tiled at 1:1 along every Act III warning circle, lane, cone and stamp square, the hit edge through its middle"),
    "empire_fx/edge_tick": (e_edge_tick, "tile", 1, "The band piece with a cyan-white targeting tick pointing into the danger (every other piece): measured, machine-like, never the Covenant's crimson teeth"),
    "empire_fx/front": (e_front, "tile", 1, "Timing front (8 x 3): a cyan-white scan line at radius x progress (circle, cone), across a lane and round a stamp square"),
    "empire_fx/hex": (e_hex, "tile", 1, "Empire fill (14 x 24 seamless): a warning-red hex grid with amber nodes, laid as 2 px rows clipped to the exact danger shape; denser where the timing has filled"),
    "empire_fx/chevron": (e_chevron, "still", 1, "Double chevron (13 x 13, pointing +x): amber with a white-hot edge; Empire lanes (lit as the timing passes) and the laser grid's sweep band"),
    "empire_fx/target": (e_target, "still", 1, "Impact point (15 x 15): a cyan-white crosshair with a red centre pip"),
    "empire_fx/bracket": (e_bracket, "still", 1, "Targeting box corner (9 x 9): four close in on a strike circle or a stamp square as it nears, ending on its bounding box"),
    "empire_fx/uplink": (e_uplink, "still", 1, "Orbital uplink column (16 x 96, base at the bottom): a cyan-white targeting beam from the sky over a strike's last 0.3 s (Purge Protocol, Citadel guns)"),
    "effects/empire_blast": (lambda: fx_blast("amber"), "strip", 8, "Empire strike / slam landing, amber (8 frames of 128 px): white-hot flash and lens glint, a hex-segmented shock ring rolling out to the gameplay radius, sparks, chrome shards, a smoke ring"),
    "effects/empire_blast_red": (lambda: fx_blast("red"), "strip", 8, "The same landing in warning red (overloads, heavy hits: Kestrel's charge, Deus's phase breaks, the Motherboard's fall, the Trojan's split)"),
    "effects/empire_boss_death": (fx_boss_blast, "strip", 10, "An Empire stage boss falls (10 frames of 256 px): a red blast at the heart, four amber secondary blasts popping round the hull, a cyan-white shock ring racing out (Kestrel, the Motherboard, Deus Ex Machina; the Covenant's holy boss_death elsewhere)"),
    "effects/empire_blast_chrome": (lambda: fx_blast("chrome"), "strip", 8, "The same in chrome and cyan-white (energy pops: Kestrel's leap, Deus's shield drones, the Trojan's stomp, Valkyrie's blade arc)"),
    "empire_fx/ray_body": (death_ray_body, "tile", 1, "Death Ray body (16 x 10 seamless, scrolled outward, drawn at the beam's exact width): the necromancer's violet soul laser with flare flow streaks"),
    "empire_fx/ray_glow": (death_ray_glow, "tile", 1, "Death Ray glow (8 x 12, stepped alphas): under the beam and as its fading afterglow"),
    "empire_fx/ray_tip": (death_ray_tip, "strip", 4, "Death Ray tip burst (4 frames of 24 px): flare core, glow ring, turning spokes; also its origin flare"),
    "empire_fx/laser_body": (laser_body, "tile", 1, "Laser grid beam body (16 x 10 seamless = its 10 px width): warning red, amber, white-hot core and flow streaks"),
    "empire_fx/laser_glow": (laser_glow, "tile", 1, "Laser glow (8 x 12, stepped red alphas), at 2.6 x the beam width"),
    "empire_fx/laser_warn": (laser_warn, "tile", 1, "Telegraphed beam sight line (8 x 3 dash): blinks and thickens as the grid arms"),
    "empire_fx/laser_cap": (laser_cap, "strip", 2, "Laser emitter (2 frames of 16 px: armed red lens, firing white-hot) at both ends of a beam"),
    "empire_fx/lance_body": (lance_body, "tile", 1, "Judgment Lance body (16 x 30 seamless = its 30 px width): amber edges, white-hot glow and core"),
    "empire_fx/lance_glow": (lance_glow, "tile", 1, "Judgment Lance glow (8 x 16, stepped amber alphas), at 1.8 x its width"),
    "empire_fx/lance_tip": (lance_tip, "strip", 4, "Judgment Lance head (4 frames of 32 px), amber and white-hot"),
    "empire_fx/gate_wall": (gate_wall, "tile", 1, "Shield Gate wall (22 x 18 seamless = its 18 px thickness, scrolled along it): white-hot edges, a translucent amber field crossed by a hex lattice"),
    "empire_fx/gate_glow": (gate_glow, "tile", 1, "Shield Gate outer glow (8 x 28 = thickness + 10, stepped amber alphas)"),
    "empire_fx/gate_post": (gate_post, "still", 1, "Shield Gate end emitter (22 x 22): chrome housing, amber lens, white-hot heart"),
    "empire_fx/gate_cable": (gate_cable, "tile", 1, "Generator power cable (8 x 5, scrolled toward the wall): amber with a white-hot heart"),
    "empire_fx/storm_veil": (storm_veil, "mask", 1, "Scrap storm veil (256 px grey mask, smooth alpha, tinted rust-ochre): clear round the necromancer, thickening outward, mottled with dust clumps; one textured rect instead of 12-20 wide arcs a frame"),
    "empire_fx/storm_grit": (storm_grit, "mask", 1, "Scrap storm grit (128 px seamless grey mask): streaks and specks leaning with the wind, scrolled with it (one tiled rect instead of 46 lines)"),
    "empire_fx/pylon_stump": (pylon_stump, "still", 1, "Fallen Signal Pylon (30 x 14 decal): the toppled chrome mast on its scorched plate, the lens dark"),
    "empire_fx/furnace_slag": (furnace_slag, "tile", 1, "Furnace channel, cold (64 x 64 seamless): slag crust of warm ink and brown clinker plates"),
    "empire_fx/furnace_embers": (furnace_embers, "tile", 1, "Furnace channel seams (64 x 64 seamless overlay): signal-dark cracks with molten specks, faded in as it warms"),
    "empire_fx/furnace_molten_0": (lambda: furnace_molten(0), "tile", 1, "Furnace channel, burning (64 x 64 seamless, frame 1 of 3): flame orange, amber flows, white-hot veins; scrolled along the channel"),
    "empire_fx/furnace_molten_1": (lambda: furnace_molten(1), "tile", 1, "Molten metal, frame 2 of 3 (the flicker)"),
    "empire_fx/furnace_molten_2": (lambda: furnace_molten(2), "tile", 1, "Molten metal, frame 3 of 3"),
    "empire_fx/furnace_rim": (furnace_rim, "tile", 1, "Furnace channel iron rim (12 x 3) with rivets, along both long sides"),
    "empire_fx/furnace_warn": (furnace_warn, "tile", 1, "Furnace warning edge (10 x 2 red hazard stripes), blinking on both edges before a flare"),
    "empire_fx/furnace_haze": (furnace_haze, "tile", 1, "Heat haze beside a burning channel (8 x 6, stepped flame alphas falling off outward)"),
    "empire_fx/furnace_flame": (furnace_flame, "strip", 4, "Flame tongue from molten metal (4 frames of 9 x 14, base at the bottom)"),
    "empire_fx/belt_68": (lambda: belt_tile(68), "tile", 1, "Conveyor belt repeat, 68 px wide (the Loading Docks): chrome rails with rollers, dark rubber, grey slats, dim amber chevrons; one scrolled textured rect per belt"),
    "empire_fx/belt_72": (lambda: belt_tile(72), "tile", 1, "Conveyor belt repeat, 72 px wide (the Assembly Hall)"),
    "empire_fx/belt_80": (lambda: belt_tile(80), "tile", 1, "Conveyor belt repeat, 80 px wide (the Conveyor Floor)"),
    "empire_fx/jug_flame_0": (lambda: jug_flame(10), "strip", 4, "Juggernaut flame billow, small (4 frames of 10 px), near the nozzle"),
    "empire_fx/jug_flame_1": (lambda: jug_flame(16), "strip", 4, "Juggernaut flame billow, medium (4 frames of 16 px)"),
    "empire_fx/jug_flame_2": (lambda: jug_flame(22), "strip", 4, "Juggernaut flame billow, large (4 frames of 22 px), at the stream's reach"),
    "empire_fx/static_edge": (static_edge, "tile", 1, "Arc Engineer static field rim (10 x 5): a broken red line with an amber crackle inside it"),
    "empire_fx/spark": (spark, "strip", 2, "Static spark (2 frames of 7 px): closing in on the field as it arms"),
    "empire_fx/mortar_shell": (mortar_shell, "strip", 2, "Mortar shell in flight (2 frames of 10 px, turning): chrome casing, amber fuse light"),
    "empire_fx/lock_open": (lambda: lock_reticle(12), "strip", 2, "Lock-On reticle while painting (2 frames of 35 px: red, white-hot blink), scaled from r 12 to 9 as it tightens"),
    "empire_fx/lock_locked": (lambda: lock_reticle(9), "strip", 2, "Lock-On reticle locked (2 frames of 29 px, r 9): blinks red / white-hot"),
    "empire_fx/shock_edge": (shock_edge, "tile", 1, "Deus footfall shock ring piece (10 x 4): lit chrome and glint, segmented"),
    "empire_fx/pulse_front": (pulse_front, "tile", 1, "Deus overload pulse front (12 x 26 = the 26 px front): white-hot leading edge, amber, a dithered red wake"),
    "empire_fx/pulse_charge": (pulse_charge, "tile", 1, "Deus overload charge ring piece (8 x 3): amber and white-hot, closing on the hull"),
    "empire_fx/binding_edge": (binding_edge, "tile", 1, "The finale's soul binding (10 x 5): soul-green chain links closing on the broken engine"),
    "empire_fx/magnet_edge": (magnet_edge, "tile", 1, "Motherboard magnet ring piece (10 x 3): a red coil wave with amber crests"),
    "empire_fx/hangar_door": (hangar_door, "strip", 3, "Deus hangar door (3 frames of 36 x 24: shut, opening, open): chrome plates with hazard stripes, the red-lit bay"),
    "empire_fx/claw": (claw, "strip", 2, "Motherboard crane claw (2 frames of 16 px: open, clamped)"),
}


def build(only=None) -> list:
    """Builds every asset (or the keys in `only`); returns the keys written."""
    done = []
    for key, (fn, kind, frames, desc) in ASSETS.items():
        if only and key not in only:
            continue
        cv = fn()
        path = cv.save(key)
        print("%-30s %4d x %-4d %s" % (key, cv.w, cv.h, os.path.relpath(path, ROOT)))
        done.append(key)
    return done


def review(out_dir: str, keys: list) -> list:
    """Writes the review images of `keys` into `out_dir`/images: the PNG at 1x, at 4x nearest (2x
    for the big masks), on a dark Act III floor colour, and a GIF of every strip; returns the
    manifest image rows."""
    img_dir = os.path.join(out_dir, "images")
    os.makedirs(img_dir, exist_ok=True)
    rows = []
    bg = (18, 22, 30, 255)  # A dark chrome floor, so the faint pieces read.
    for key in keys:
        fn, kind, frames, desc = ASSETS[key]
        im = Image.open(os.path.join(SPRITES, key + ".png")).convert("RGBA")
        name = key.replace("/", "_")
        p1 = os.path.join(img_dir, name + ".png")
        im.save(p1)
        zoom = 4 if max(im.size) <= 260 else 2
        if kind == "mask":
            zoom = 2
        big = Image.new("RGBA", (im.width * zoom, im.height * zoom), bg)
        src = im
        if kind == "mask":  # Masks shown tinted rust-ochre (the dust), as in the game.
            src = Image.new("RGBA", im.size, (92, 64, 36, 0))
            src.putalpha(im.getchannel("A"))
        big.alpha_composite(src.resize((im.width * zoom, im.height * zoom), Image.NEAREST))
        p4 = os.path.join(img_dir, name + "_x4.png")
        big.save(p4)
        row = {"id": name, "key": key, "path": os.path.relpath(p1, ROOT), "path_x4": os.path.relpath(p4, ROOT),
               "size": [im.width, im.height], "description": desc}
        if frames > 1:
            fw = im.width // frames
            gif = []
            for f in range(frames):
                fr = Image.new("RGBA", (fw * zoom, im.height * zoom), bg)
                fr.alpha_composite(im.crop((f * fw, 0, (f + 1) * fw, im.height)).resize((fw * zoom, im.height * zoom), Image.NEAREST))
                gif.append(fr.convert("RGB"))
            pg = os.path.join(img_dir, name + ".gif")
            gif[0].save(pg, save_all=True, append_images=gif[1:], duration=110, loop=0)
            row["gif"] = os.path.relpath(pg, ROOT)
        rows.append(row)
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", default="", help="comma-separated keys to rebuild")
    ap.add_argument("--review", default="", help="also write review images into this folder")
    args = ap.parse_args()
    only = [k for k in args.only.split(",") if k] or None
    keys = build(only)
    if args.review:
        rows = review(os.path.join(ROOT, args.review), keys)
        with open(os.path.join(ROOT, args.review, "images.json"), "w") as f:
            json.dump(rows, f, indent=1)
        print("review: %d images in %s" % (len(rows), args.review))


if __name__ == "__main__":
    main()
