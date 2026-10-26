"""Round 4 Hades: the round 1 sprites (poses and head untouched), the clothing recoloured so
the robe and the cloak are two different colours. The robe region per pose is the one the
round 2 recolour used (pixels round 2 changed), cleaned: only round 1's cloth greys, holes in a
row filled. Usage: hades_recolour.py <scheme> <out_dir>"""
import json, sys, subprocess
from PIL import Image
ROOT = '/home/user/wt/act4-r4'
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open(ROOT + '/tools/palette.json'))['colors']}
CLOTH = {P['grey_dark'], P['grey']}
SCHEMES = {
    # cloak main, cloak fold, robe main, robe fold, trim on the robe's edge (None = none)
    'A': dict(cloak=('aegean_dark', 'aegean'), robe=('steel_dark', 'steel'), trim='bronze'),
    'B': dict(cloak=('grey_dark', 'grey'), robe=('bone_shade', 'bone_mid'), trim='bronze'),
    'C': dict(cloak=('aegean_dark', 'aegean'), robe=('bone_shade', 'bone_mid'), trim='bronze'),
    'E': dict(cloak=('aegean_dark', 'aegean'), robe=('grey_dark', 'grey'), trim='bronze'),
    'F': dict(cloak=('aegean_dark', 'aegean'), robe=('bronze_dark', 'bronze'), trim='bronze_light'),
    'D': dict(cloak=('aegean_dark', 'grey'), robe=('marble_dark', 'marble'), trim='bronze_dark'),
}


def load(rev, key):
    data = subprocess.run(['git', '-C', ROOT, 'show', f'{rev}:assets/sprites/bosses/{key}.png'], capture_output=True, check=True).stdout
    import io
    return Image.open(io.BytesIO(data)).convert('RGBA')


def robe_mask(r1, r2):
    w, h = r1.size
    m = [[r1.getpixel((x, y)) in CLOTH and r1.getpixel((x, y)) != r2.getpixel((x, y)) for x in range(w)] for y in range(h)]
    for y in range(h):
        xs = [x for x in range(w) if m[y][x]]
        if not xs:
            continue
        for x in range(min(xs), max(xs) + 1):
            if r1.getpixel((x, y)) in CLOTH:
                m[y][x] = True
    return m


def gap_after(img, y, x0):
    """First transparent column after x0 in row y (the bident beyond it is not cloth)."""
    for x in range(x0, img.width):
        if img.getpixel((x, y))[3] == 0:
            return x
    return img.width


def kept(key, img, m, x, y):
    """True for grey pixels that are not cloth: the head (hair round the face, round 1 kept
    exactly) and the bident's iron shaft."""
    if key == 'hades':
        return y < 34 or x >= 60 or x >= gap_after(img, y, 50)
    if key == 'hades_bident':
        return y < 25 or (y < 32 and x >= 60) or (y >= 60 and x >= gap_after(img, y, 60))
    if key == 'hades_kneel':
        if y < 34 and x >= 36:
            return True  # The bowed head and its hair.
        if y >= 67 and x >= 65:
            return True  # The fork on the ground.
        if y >= 73 and x >= 44 and not m[y][x]:
            return True  # The shaft on the ground.
        return y >= 77 or (y == 76 and x >= 34)
    return False


def recolour(key, scheme):
    r1, r2 = load('16ea7aa', key), load('8f2f889', key)
    s = SCHEMES[scheme]
    m = robe_mask(r1, r2)
    out = r1.copy()
    w, h = r1.size
    for y in range(h):
        for x in range(w):
            px = r1.getpixel((x, y))
            if px not in CLOTH or kept(key, r1, m, x, y):
                continue
            fold = px == P['grey']
            if m[y][x]:
                # The trim: robe pixels touching the cloak on the left or right (the robe's opening).
                edge = any(0 <= x + dx < w and r1.getpixel((x + dx, y)) in CLOTH and not m[y][x + dx] and not kept(key, r1, m, x + dx, y) for dx in (-1, 1))
                name = s['trim'] if (edge and s['trim']) else s['robe'][1 if fold else 0]
            else:
                name = s['cloak'][1 if fold else 0]
            out.putpixel((x, y), P[name])
    return out


if __name__ == '__main__':
    scheme, out_dir = sys.argv[1], sys.argv[2]
    for key in ('hades', 'hades_bident', 'hades_kneel'):
        recolour(key, scheme).save(f'{out_dir}/{key}.png')
