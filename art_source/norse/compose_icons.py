"""compose_icons.py: cut the symbols from art_source/norse/icons_*.png, convert each to 26 art px (prepare_sprite.py) and composite it on the
cut-corner badge template (violet ring for spells / passives, gold ring for evolutions) into assets/sprites/icons/<id>.png (32 x 32)."""
import subprocess, sys
import numpy as np
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
S = Path("/tmp/claude-0/-home-user/9462c562-c5ac-539a-9c62-d10b49b002f0/scratchpad/n/ic"); S.mkdir(exist_ok=True)
FACE = (22, 10, 33, 255)
# sheet -> ids left to right, gold? (evolution) ; Odin's gold ring for evolutions
IDS = {"a": [("barrow_grasp", 0), ("valkyrie_spear", 0), ("gungnir", 0), ("grave_frost", 0)],
       "b": [("einherjars_oath", 0), ("runecraft", 0), ("inglorious", 0), ("calm_blood", 0)],
       "c": [("barrow_lords_embrace", 1), ("chooser_of_the_slain", 1), ("spear_of_the_hanged", 1), ("barrow_king", 1)],
       "d": [("draugr_thane", 0)]}
def template(gold):
    im = Image.open(ROOT / "assets/sprites/icons" / ("ossuary_lance.png" if gold else "shadow_bolt.png")).convert("RGBA")
    a = np.array(im)
    a[3:29, 3:29] = np.where(a[3:29, 3:29, 3:4] > 0, np.array(FACE, dtype=np.uint8), a[3:29, 3:29])
    return Image.fromarray(a)
def clusters(alpha):
    cols = alpha.any(axis=0); runs = []; s = None; gap = 0
    for x, v in enumerate(list(cols) + [False] * 80):
        if v:
            if s is None: s = x
            gap = 0
        elif s is not None:
            gap += 1
            if gap > 40: runs.append((s, x - gap + 1)); s = None
    return runs
for sh, items in IDS.items():
    im = Image.open(ROOT / f"art_source/norse/icons_{sh}.png").convert("RGBA")
    alpha = np.array(im)[..., 3] > 128
    runs = clusters(alpha)
    for (iid, gold), (x0, x1) in zip(items, runs):
        sub = alpha[:, x0:x1]; ys = np.nonzero(sub.any(axis=1))[0]
        crop = im.crop((x0, ys.min(), x1, ys.max() + 1)); src = S / f"{iid}.png"
        w, h = crop.size; side = max(w, h) + 8; sq = Image.new("RGBA", (side, side), (0, 0, 0, 0)); sq.paste(crop, ((side - w) // 2, (side - h) // 2)); sq.save(src)
        out = S / f"{iid}_sym.png"
        subprocess.run([sys.executable, str(ROOT / "tools/prepare_sprite.py"), str(src), "icons/_tmp", "--art-height", str(max(8, round(26 * h / max(w, h)))), "--no-center", "--no-prune", "--no-levels", "--no-cleanup", "--no-outline", "--out", str(out)], cwd=ROOT, capture_output=True, text=True)
        sym = Image.open(out).convert("RGBA")
        badge = template(gold); canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        ox, oy = (32 - sym.width) // 2, (32 - sym.height) // 2
        bt = np.array(badge); st = np.array(sym); res = bt.copy()
        for y in range(sym.height):
            for x in range(sym.width):
                X, Y = x + ox, y + oy
                if 0 <= X < 32 and 0 <= Y < 32 and st[y, x, 3] > 0 and tuple(bt[Y, X]) == FACE: res[Y, X] = st[y, x]
        Image.fromarray(res).save(ROOT / f"assets/sprites/icons/{iid}.png"); print(iid, sym.size)
