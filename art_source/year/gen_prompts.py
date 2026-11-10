#!/usr/bin/env python3
"""gen_prompts.py: writes the Turning Year's sprite prompts (art_source/year/<id>.txt) and generates each raw API image
(art_source/year/raw/<id>.png) with tools/gen_image.py; crops of the approved lineup (refs/<id>.png) and a style sprite
(refs/style_male|female|beast.png) are the references. Usage (repo root): python3 art_source/year/gen_prompts.py [id ...]  (no ids =
every missing raw image). Every prompt names the figure's sex (or creature); female figures use the figure-redesign style, fully clothed.
Colours: the wild_ ramps of tools/palette.json (moss, bark, blossom pink, amber leaf, frost; never crimson, UI gold or violet)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
COL = ("ONLY flat fills from this list, at most 3 shades per material: moss green #274D24 #599641 #9CCB72; bark brown #553C27 #86603E "
       "#B08A60; blossom pink #9C5272 #EFA6C3 #FBD9E6; amber leaf #8A5420 #D9953C #F2C67A; frost #6F8AA4 #B9CEE0 #E4EDF5; pale skin #B8A8A0 #E8DCD4. "
       "NO red, NO crimson, NO violet, NO purple, NO yellow-gold.")
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above "
        "and slightly in front), FULL BODY, FACING RIGHT, ")
LOWRES = ("LOW-RESOLUTION pixel art: the whole SUBJECT is only {h} pixels tall and about {w} pixels wide, drawn on a coarse pixel grid and "
          "shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail smaller "
          "than 2 pixels except the eyes and small glints. No anti-aliasing, no gradients, no dithering, no soft glow haze.")
FEMALE = (" Figure: an exaggerated hourglass figure, glamorous, a small waist and full hips and bust, FULLY CLOTHED (chest and hips always "
          "covered by opaque cloth, bark, leaves or lace), never nude, no cut-outs.")
TAIL = ("Outline: a clean 1-pixel dark outline around the whole subject in deep bark #14100C. Light from the top-left. Keep the main "
        "shapes clearly brighter than a near-black ground.\n\nOutput: a square PNG with a FULLY TRANSPARENT background (real alpha, not a "
        "checkerboard, no dark glow around the subject), one subject only, centred, filling about 85% of the image. No ground, no "
        "cast shadow, no text, no frame. Draw ONLY ONE subject (no companions, no hounds, no extra creatures).\nAttached: (1) a game sprite of "
        "this game for pixel size, outline weight and flat look; (2) concept art of this unit for its shape and colours only (keep it flat, "
        "chunky and low-resolution; ignore any neighbouring figures in it).")
# id -> (art h, art w, style ref, sex line, subject)
U = {
    "thornling": (20, 22, "beast", "no sex (fodder)", "ONE THORNLING: a tiny twig creature, a bark-brown body of knotted twigs, two stick legs, moss tufts on its back, sharp thorn claws, one small pink blossom on its head; just one creature, small and simple."),
    "dryad": (52, 34, "female", "female", "a DRYAD (female tree spirit, support): a woman with bark-brown skin patches and a pale face, a long gown of bark and green leaves, a flower crown of pink blossoms in her hair, a small seed pouch at her hip, one hand extended holding a glowing seed." + FEMALE),
    "treant": (80, 64, "beast", "no sex (a tree)", "a TREANT (a walking oak, heavy): a huge tree-man with a face in the bark, thick branch arms hanging low, moss on shoulders and legs, root feet, a few small pink blossoms in the crown branches. Standing front-three-quarter."),
    "corpse_bloom": (48, 48, "beast", "no sex (a plant)", "a CORPSE-BLOOM (a carnivorous flower, structure): a huge pink flower with eight petals around a dark toothy maw, growing from a mound of pale bones with twisting green vines at its base. Not a figure: a plant."),
    "corpse_bloom_dead": (48, 48, "beast", "no sex (a plant)", "a DEAD CORPSE-BLOOM (a carnivorous flower, wilted): the same huge flower now wilted and grey-brown, the petals drooping and shrivelled around the maw, a mound of pale bones with dead withered vines. Colours dull and desaturated."),
    "fae_knight": (52, 36, "male", "male", "a FAE KNIGHT (male soldier of the Fae Court): a lean knight in leaf-plate armour of overlapping green leaves, a leaf-crested helm with two small horns, a long THORN SWORD (a blade grown from a bramble branch) held in his right hand."),
    "winter_fae": (52, 34, "female", "female", "a WINTER FAE (female ranged caster of the Winter Court): a lady in a long frost-lace gown of white and pale blue, an icicle crown, two translucent frost wings, one hand raised holding a swirl of frost; small snowflakes around her." + FEMALE),
    "great_stag": (64, 72, "beast", "male (an animal)", "a GREAT STAG (a huge male stag, elite): a brown-and-bark coat with a pale cream chest, huge pale antlers with moss growing in them, glowing pale-frost eyes, standing side-on with its head lowered a little, ready to charge."),
    "wild_rider": (64, 72, "male", "male", "a WILD RIDER (a male spectral horseman of the Wild Hunt, elite): an antlered helm, a green-black cloak, a spear held forward, riding a spectral pale-frost horse with a ghostly blue-white glow; seen side-on, galloping. The rider and the horse only."),
    "will_o_wisp": (28, 24, "beast", "no sex (a light)", "a WILL-O'-WISP (a lure): a drifting teardrop of cold pale-frost light with a faint dark face (two eye dots), a tail of light curling up; just one small light."),
    "spore_mother": (52, 38, "female", "female", "a SPORE MOTHER (female mushroom matron, support): a woman under a wide red-brown-and-amber mushroom cap like a big hat with pale spots, a shawl of green moss over her shoulders, a long autumn gown of amber and brown leaves, small mushrooms around her feet, glowing amber spores drifting from her hands." + FEMALE),
}


def build(uid: str) -> str:
    h, w, style, sexline, subject = U[uid]
    return HEAD + subject + "\n\n" + LOWRES.format(h=h, w=w) + "\n\nSubject sex: " + sexline + ".\n\nColours: " + COL + "\n\n" + TAIL + "\n"


def main() -> None:
    ids = sys.argv[1:] or [u for u in U if not (HERE / "raw" / (u + ".png")).exists()]
    for uid in ids:
        (HERE / (uid + ".txt")).write_text(build(uid))
        style = U[uid][2]
        ref = HERE / "refs" / ((uid if (HERE / "refs" / (uid + ".png")).exists() else uid.replace("_dead", "")) + ".png")
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / (uid + ".txt")), str(HERE / "raw" / (uid + ".png")),
               "--ref", str(HERE / "refs" / ("style_%s.png" % style)), "--ref", str(ref), "--key", "year/" + uid]
        print("+", uid, flush=True)
        subprocess.run(cmd, cwd=ROOT, check=False)


if __name__ == "__main__":
    main()
