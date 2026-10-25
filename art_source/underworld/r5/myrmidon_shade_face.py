"""Round 5 Myrmidon Shade (owner: "face looks a bit silly but the rest is fine"): only the face in
the Corinthian helmet's opening is repainted on the grid; every other pixel of the round 4 sprite
stays. The round 4 face was a long bone mask hanging out of the helmet on its right side, its eyes
two vertical ink-glow-ink stacks and a two-pixel mouth line like a nose. Now: the helmet's cheek
guards close round it on both sides (grey), a short skull face plate with a bone brow, two dark
sockets each holding one soul-glow eye, a nose hole, a row of teeth and the helmet's chin rim under it, the Legion of Tartarus's
treatment (bone, ink_green sockets, soul_glow eyes) at this size.
Usage (repo root): myrmidon_shade_face.py <in png> <out png>"""
import json, sys
from PIL import Image
P = {c['name']: tuple(int(c['hex'][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in json.load(open('tools/palette.json'))['colors']}
AB = {'3': 'bone', '2': 'bone_mid', '1': 'bone_shade', '6': 'soul_glow', 'x': 'ink_green', 'G': 'grey_dark',
      'g': 'grey', 'c': 'ink_cold'}
# Rows of (first col, pixels): cols 8-14, the helmet opening and its cheek guards.
FACE = {
    11: (8, 'gGGGGGG'),
    12: (8, 'G33332G'),
    13: (8, 'Gx63x6G'),
    14: (8, 'G33x32G'),
    15: (8, 'G3x2x1G'),
    16: (8, 'cG212Gc'),
    17: (8, 'cGgggGc'),
}
im = Image.open(sys.argv[1]).convert('RGBA')
for y, (x0, row) in FACE.items():
    for i, ch in enumerate(row):
        im.putpixel((x0 + i, y), P[AB[ch]])
im.save(sys.argv[2])
