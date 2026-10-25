"""act3_projectiles.py: hand-built pixel art for the Act III projectiles (Act III missing sprites).

Usage (from the repo root):
    python3 tools/act3_projectiles.py [id ...]     rebuild assets/sprites/projectiles/<id>.png (all when no id)

No image generation: every sprite is drawn on the art grid from letter maps or tiny procedural
shapes, in exact colours of tools/palette.json (fully opaque or fully transparent pixels), facing
+x. Strips (the rotor spin, the exhaust flicker) hold their frames side by side, left to right:
    soul_round            12x5   a Grave Gunner's rifle round (soul-teal fire)
    scrap_bolt            14x6   a Scrap Swarm / Rust Prophet bolt (bone shard wrapped in violet)
    iron_shell            18x8   an Iron Revenant / Deus Revenant cannon shell (iron, soul-teal trail)
    trojan_rocket         24x12  the Trojan Horse's Swarm Rocket (chrome, red fins, amber warhead)
    trojan_rocket_flame   36x8   its exhaust, 3 frames of 12x8 (nozzle on the right edge)
    scrap_drone           44x14  a Scrap Swarm drone, 2 rotor frames of 22x14 (bone body, violet eye)
    scrap_drone_bright    44x14  the Deathless Swarm kill drone (violet rotors, brighter eye)
(ART_BIBLE "Act III missing sprites"). SpriteData.FLAT_SIZES holds each file's longest side.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent  # Repo root.
_palette = json.load(open(ROOT / 'tools' / 'palette.json'))
NAME2RGB = {c['name']: tuple(int(c['hex'].lstrip('#')[i:i + 2], 16) for i in (0, 2, 4)) for c in _palette['colors']}


class pal:  # noqa: N801  (a tiny namespace, so the sprite code below reads as before)
    @staticmethod
    def from_names(grid):
        h, w = len(grid), len(grid[0])
        arr = np.zeros((h, w, 4), np.uint8)
        for y in range(h):
            for x in range(w):
                if grid[y][x]:
                    arr[y, x, :3] = NAME2RGB[grid[y][x]]
                    arr[y, x, 3] = 255
        return arr

    @staticmethod
    def save(arr, path):
        Image.fromarray(arr.astype(np.uint8)).save(path)


OUT = str(ROOT / 'assets' / 'sprites' / 'projectiles') + '/'  # Output folder.

# One-letter legend shared by every map ('.' = transparent).
L = {
    'a': 'ink_cold', 'D': 'grey_dark', 'G': 'grey', 'H': 'grey_light',
    'e': 'ink_chrome', 'c': 'chrome_dark', 'C': 'chrome', 'l': 'chrome_light', 'k': 'chrome_glint',
    'I': 'ink_signal', 'S': 'signal_dark', 'r': 'signal_red', 'y': 'signal_amber', 'Y': 'signal_glow',
    'n': 'ink_green', 'u': 'soul_dark', 'o': 'soul', 'O': 'soul_glow',
    'i': 'ink_violet', 'v': 'violet_deep', 'p': 'violet', 'g': 'violet_glow', 'f': 'violet_flare',
    'w': 'ink_warm', 's': 'bone_shade', 'm': 'bone_mid', 'b': 'bone',
}

SPRITES = {}

# ---- Grave Gunner rifle round: a soul-fire slug, 12 x 5 -----------------------------------
SPRITES['soul_round'] = [[
    "....nnnnnn..",
    ".nnuuoooOOn.",
    "nuuoooOOOOOn",
    ".nnuuoooOOn.",
    "....nnnnnn..",
]]

# ---- Scrap bolt: a bone shard wrapped in violet, 14 x 6 -------------------------------------
SPRITES['scrap_bolt'] = [[
    "......iiiiii..",
    ".iii.ivpbbbbi.",
    "iggpvpvbbbbmmi",
    "iggpvpvbmmmmmi",
    ".iii.ivpmmmmi.",
    "......iiiiii..",
]]

# ---- Iron Revenant cannon shell: grey iron, soul-teal fire trail, 18 x 8 --------------------------
SPRITES['iron_shell'] = [[
    "..........aaaa....",
    "....nn..aaDGGHaa..",
    ".nnuuonaaDGGHHHHaa",
    "nuooOOoaaDGGHHHHHa",
    "nuooOOoaaDGGGGHHHa",
    ".nnuuonaaDDGGGHHaa",
    "....nn..aaDDGGaa..",
    "..........aaaa....",
]]

# ---- Trojan Swarm Rocket: chrome missile, red fins and band, amber warhead, 24 x 12 --------------
def _rocket():
    W, H = 24, 12
    g = [[''] * W for _ in range(H)]

    def px(x, y, n):
        g[y][x] = n

    def rect(x0, x1, y0, y1, n):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                px(x, y, n)
    # tail nozzle, body, nose
    rect(3, 4, 4, 7, 'chrome_dark')
    rect(5, 18, 3, 8, 'chrome')
    rect(5, 18, 3, 3, 'chrome_light')       # lit top row (light from the top-left)
    rect(5, 18, 7, 8, 'chrome_dark')        # shaded belly
    rect(6, 10, 3, 3, 'chrome_glint')       # glint
    rect(12, 13, 3, 8, 'signal_red')        # warning-red band
    rect(12, 13, 7, 8, 'signal_dark')
    for x, (y0, y1) in {19: (3, 8), 20: (4, 7), 21: (4, 7), 22: (5, 6)}.items():
        rect(x, x, y0, y1, 'chrome')
    rect(19, 19, 3, 3, 'chrome_light')
    rect(19, 19, 7, 8, 'chrome_dark')
    rect(20, 21, 4, 7, 'signal_amber')      # the warhead light
    rect(22, 22, 5, 6, 'signal_glow')
    rect(20, 20, 7, 7, 'signal_dark')
    # swept fins (warning red; the leading edge a shade lighter)
    for k, (x0, x1) in enumerate([(7, 10), (6, 9), (5, 8)]):
        rect(x0, x1, 2 - k, 2 - k, 'signal_red')           # top fin, rows 2..0
        rect(x0, x1, 9 + k, 9 + k, 'signal_red')           # bottom fin, rows 9..11
        px(x0, 9 + k, 'signal_dark')
    # outline: every transparent pixel next to the rocket
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '':
                        out[y][x] = 'ink_signal' if g[ny][nx] in ('signal_red', 'signal_dark', 'signal_amber', 'signal_glow') else 'ink_chrome'
                        break
    return out


# ---- Scrap Swarm drone: a bone-and-scrap quadcopter seen from above, 22 x 14, 2 rotor frames ----
def _outline(g, W, H, ink_for):
    out = [row[:] for row in g]
    for y in range(H):
        for x in range(W):
            if g[y][x] == '':
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and g[ny][nx] != '':
                        out[y][x] = ink_for(g[ny][nx])
                        break
    return out


def _drone(frame, bright):
    W, H = 22, 14
    g = [[''] * W for _ in range(H)]
    rot = ('violet_deep', 'violet', 'violet_glow') if bright else ('grey_dark', 'grey', 'grey_light')

    def rotor(cx, cy, rx, ry, flip):
        for y in range(H):
            for x in range(W):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    top = y < cy - 0.5
                    g[y][x] = rot[2] if top else rot[1]
        # blade streak: frame 0 a long highlight, frame 1 a short one on the other side
        sx = int(cx - rx + 1) if (frame == 0) != flip else int(cx + 0.5)
        for x in range(sx, sx + 2 if frame else sx + 3):
            if 0 <= x < W and g[int(cy - 0.5)][x]:
                g[int(cy - 0.5)][x] = rot[2]
        g[int(cy + 0.5)][int(cx - 0.5)] = rot[0]          # hub
        g[int(cy + 0.5)][int(cx + 0.5)] = rot[0]
    rw = 3.7 if frame == 0 else 3.2
    ry, cyr = (2.0, 4.0) if frame == 0 else (1.6, 3.6)
    rotor(3.7, cyr, rw, ry, False)
    rotor(18.3, cyr, rw, ry, True)
    # arms from the rotors to the body
    for x in range(6, 9):
        g[6][x] = 'grey_dark'
        g[6][21 - x] = 'grey_dark'
    # the bone skull-body
    cx, cy, r = 10.5, 7.6, 4.7
    for y in range(H):
        for x in range(W):
            d = ((x + 0.5 - cx) / r) ** 2 + ((y + 0.5 - cy) / (r * 0.95)) ** 2
            if d <= 1.0:
                t = (x + 0.5 - cx) / r * 0.6 + (y + 0.5 - cy) / r * 0.8
                g[y][x] = 'bone' if t < -0.15 else ('bone_mid' if t < 0.45 else 'bone_shade')
    # the violet eye (cyclops lens)
    eye = ['.vv.', 'vppv', 'vpgv', '.vv.'] if not bright else ['.gg.', 'gffg', 'gfpg', '.gg.']
    ek = {'v': 'violet_deep', 'p': 'violet_glow', 'g': 'violet_glow' if not bright else 'violet_glow', 'f': 'violet_flare'}
    if bright:
        ek = {'g': 'violet', 'f': 'violet_flare', 'p': 'violet_glow'}
    for dy, row in enumerate(eye):
        for dx, ch in enumerate(row):
            if ch != '.':
                g[6 + dy][9 + dx] = ek[ch]
    if not bright:
        g[7][10] = 'violet_flare'
    # scrap jaw plate and two little feet
    for x in range(8, 13):
        g[11][x] = 'grey' if x % 2 == 0 else 'grey_dark'
    g[12][8], g[12][12] = 'grey_dark', 'grey_dark'
    return _outline(g, W, H, lambda n: 'ink_warm' if n.startswith('bone') else ('ink_violet' if n.startswith('violet') else 'ink_cold'))


SPRITES['scrap_drone'] = [_drone(0, False), _drone(1, False)]
SPRITES['scrap_drone_bright'] = [_drone(0, True), _drone(1, True)]
SPRITES['trojan_rocket'] = [_rocket()]


# ---- Trojan rocket exhaust: 3 flicker frames, 12 x 8, nozzle on the right edge ----------------
def _flame(length, wob):
    W, H = 12, 8
    g = [[''] * W for _ in range(H)]
    for d in range(length):
        x = W - 1 - d
        t = d / float(length)
        hh = 3.0 * (1.0 - t) ** 0.85 + wob * (0.4 if d % 3 == 1 else 0.0)
        for y in range(H):
            dy = abs(y + 0.5 - H / 2.0)
            if dy <= hh:
                if dy <= hh * 0.4 and t < 0.45:
                    g[y][x] = 'signal_glow'
                elif dy <= hh * 0.66 and t < 0.8:
                    g[y][x] = 'signal_amber'
                else:
                    g[y][x] = 'signal_red'
    return g


SPRITES['trojan_rocket_flame'] = [_flame(9, 0.0), _flame(11, 0.6), _flame(8, 0.3)]


def build(name):
    frames = SPRITES[name]
    arrs = []
    for fr in frames:
        if isinstance(fr[0], list):
            grid = fr
        else:
            w = len(fr[0])
            assert all(len(r) == w for r in fr), (name, [len(r) for r in fr])
            grid = [[L[c] if c != '.' else '' for c in row] for row in fr]
        arrs.append(pal.from_names(grid))
    out = np.concatenate(arrs, axis=1)
    pal.save(out, OUT + name + '.png')
    print(name, out.shape[1], 'x', out.shape[0], '(%d frame%s)' % (len(frames), 's' if len(frames) > 1 else ''))


if __name__ == '__main__':
    for n in (sys.argv[1:] or list(SPRITES)):
        build(n)
