#!/usr/bin/env python3
"""gen_phase2.py: the Turning Year's phase 2 raw images (Greenwood, Fae Court, World-Tree): creatures, minibosses, bosses and their pose stills, the three
violet necromancer characters, the Ossuary Oak family and the obstacle / icon sheets. Usage (repo root): python3 art_source/year/gen_phase2.py [id ...]
(no ids = every missing raw image). Raw images land in art_source/year/raw/<id>.png (sheets: sheet_<id>.png), prompts beside this file. Same palette and
rules as gen_prompts.py (never crimson, UI gold or violet on a Wild creature); every prompt names the sex; female figures: figure-redesign style, fully
clothed. Poses take their base raw as a reference."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_prompts import COL, HEAD, LOWRES, TAIL, FEMALE  # noqa: E402
from gen_sheets import ICON_HEAD, ICON_COL, ICON_TAIL  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/year.
BONE_COL = ("ONLY flat fills: bone white #9C9078 #E7DEC9 #F8F6EE; bark brown #553C27 #86603E #B08A60; moss #274D24 #599641; soul teal #1C6B58 #3DCC94 "
            "(knots and eyes only). NO red, NO gold, NO purple.")
VIO = ("violet #1C0F2B (outline) #3B1F5C #6B39A6 #A35CFA; bone white #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94; pale undead skin #B8A8A0 #E8DCD4; "
       "ochre leather #7E552A #C89448. NO red, NO gold.")
CHAR_HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view, FULL BODY, FACING RIGHT, ready stance. LOW-RESOLUTION pixel art: "
             "the whole figure is only 56 pixels tall and at most {w} pixels wide, coarse pixel grid shown enlarged with crisp square pixels. Chunky simple shapes, no "
             "anti-aliasing, no gradients, no glow haze. Subject: ")
CHAR_TAIL = ("\n\nColours: ONLY flat fills, at most 3 shades per material: " + VIO + "\nOutline: a clean 1-pixel dark outline in the darkest shade of each part's colour. Light from the top-left.\n"
             "Output: a square PNG with a FULLY TRANSPARENT background, one figure only, centred, filling about 85% of the height. No ground, no shadow, no text.\n"
             "Attached: the game's necromancer and another necromancer of this game: match their pixel size, outline and flat look (not their subjects).")
# id -> (art h, art w, ref name, sex line, subject, base raw for pose refs or None)
U = {
    "hunt_hound": (28, 40, "great_stag", "none (an animal)", "a spectral HUNT HOUND of the Wild Hunt (a beast): a lean hound in pale frost-white and frost-blue with a ghostly glow, bark-brown ears, glowing pale eyes, running side-on with its jaws open.", None),
    "huntsman": (68, 80, "wild_rider", "male", "THE HUNTSMAN OF THE WILD HUNT (a male rider, miniboss): a broad hunter in a green-black cloak and a leaf-crested antlered helm, a bone hunting horn at his belt, a long spear in his hand, riding a GREAT ANTLERED MOUNT (a huge pale stag with moss in its antlers and glowing frost eyes); side-on, trotting.", None),
    "antler_thicket": (28, 28, None, "none (a plant)", "ONE ANTLER THICKET: a knot of antler-shaped thorny branches growing from a small mound of earth, bark-brown with pale bone-coloured antler tines, a few moss tufts; compact and round, seen from above-front.", None),
    "stag_king": (88, 72, "stag_king", "male", "THE STAG KING (a towering male lord of the forest, boss): a man's tall body with a STAG'S HEAD and huge pale antlers grown with moss, a mantle of green leaves with a white fur collar, a bark-brown torso, a hunting horn hanging at his side, a staff of twisted branches with small white blossoms in his right hand; standing, ready.", None),
    "stag_king_horn": (88, 72, "stag_king", "male", "the same STAG KING (towering male stag-headed lord) with his hunting horn RAISED to his lips with one hand, head tilted back a little, otherwise identical.", "stag_king"),
    "winter_prince": (56, 40, "fae_knight", "male", "THE WINTER PRINCE (a male fae prince of the Winter Court, miniboss): tall, in frost-blue plate armour edged with ice crystals, a long cloak of white snow, an icicle crown, a long icicle sword in his right hand, pale skin, cold glowing eyes.", None),
    "masked_courtier": (52, 32, "dryad", "female", "a MASKED COURTIER (a female fae courtier of the Summer Court): a woman in a gown of pink and red roses and green leaves, her face covered by a pale porcelain-white court mask, a thin thorn rapier in her right hand, a few blossoms in her hair." + FEMALE, None),
    "summer_queen": (80, 64, "summer_queen", "female", "THE SUMMER QUEEN (a female fae queen, boss): large orange-and-amber BUTTERFLY WINGS spread behind her, a long gown of golden-amber petals and pink roses, a crown of blossoms in her hair, a sunflower-topped sceptre in her left hand, a warm calm face." + FEMALE, None),
    "summer_queen_mask": (80, 64, "summer_queen", "female", "the same SUMMER QUEEN (female fae queen with butterfly wings and rose gown) now wearing a pale porcelain-white court MASK over her whole face (two dark eye slits, a small painted smile), otherwise identical.", "summer_queen"),
    "summer_queen_bargain": (80, 64, "summer_queen", "female", "the same SUMMER QUEEN (female fae queen with butterfly wings and rose gown) with one hand held OUT in front, palm up, offering a pink blossom, a gentle smile, otherwise identical.", "summer_queen"),
    "gardener_of_roots": (88, 80, "treant", "none (a tree)", "THE GARDENER OF ROOTS (a great treant, miniboss): a huge broad oak-man with a face in the bark, two huge arms ending in hands made of tangled ROOTS, moss and mushrooms on the shoulders, bark-brown with moss green, a few pink blossoms, roots spreading at the feet; standing front-three-quarter.", None),
    "green_mother": (144, 128, "green_mother", "female", "THE GREEN MOTHER (a colossal female goddess grown from the world tree, boss): a woman's figure of bark, leaves and blossom with a canopy of hair, HALF IN BLOOM (the left half: green leaves, pink blossoms, warm bark) AND HALF IN FROST (the right half: white frost, ice-blue branches, snowflakes), arms held a little out with open hands, her gown of leaves and roots flowing into root feet; calm face." + FEMALE, None),
    "green_mother_cast": (144, 128, "green_mother", "female", "the same GREEN MOTHER (colossal female goddess half in bloom and half in frost) with both ARMS RAISED high above her head, palms open to the sky, small flakes and petals swirling, otherwise identical.", "green_mother"),
    "green_mother_burial": (144, 128, "green_mother", "female", "the same GREEN MOTHER (colossal female goddess half in bloom and half in frost) BENT FORWARD with both hands pressed into the earth, her hair falling forward, roots spreading from her hands, otherwise identical.", "green_mother"),
}
CHARS = {
    "horned_herald": (42, "THE HORNED HERALD, a MALE necromancer: tall, long violet hunting robes, a hood with a bone-white ANTLER crown, pale undead skin and teal glowing eyes, a bone hunting horn at his hip. In his right hand a tall staff topped between antler tines with a soul-teal flame."),
    "changeling_princess": (38, "THE CHANGELING PRINCESS, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: a fitted violet gown with layered gossamer-leaf skirts, pale undead skin, teal eyes. In her left hand a bone-white theatre mask held on a stick, in her right a slim wand topped with a soul-teal moth."),
    "gravegardener": (40, "THE GRAVEGARDENER, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: a fitted violet gardener's robe with an apron of bark-brown roots, a wide-brimmed violet hat, pale undead skin, teal eyes. In her right hand a bone trowel-staff with a sprouting soul-teal seed."),
}
SUMMONS = {
    "ossuary_oak": (56, 48, "treant", "no sex (a tree)", "an OSSUARY OAK: a slow tree made of BONE: a bone-white trunk of fused ribs and femurs, branches like antlers with a few bark-brown leaves, soul-teal glowing knots in the trunk, thick bone roots at its base, standing."),
    "world_root_warden": (64, 56, "treant", "no sex (a tree)", "a WORLD-ROOT WARDEN: a huge tree of BONE, an evolved Ossuary Oak: a thick bone-white trunk with a skull-like face knot with soul-teal glowing eyes, great spreading bone branches with moss and a few leaves, huge bone roots, soul-teal knots, imposing."),
}
SHEETS = {
    "obstacles2": ("sheet", "A sheet of 3 separate pixel-art game OBSTACLE sprites for a top-down 2D horde-survival game (three-quarter top-down view, camera above and slightly in front), in one row, evenly spaced with wide empty gaps, on a FULLY TRANSPARENT background (real alpha). An enchanted forest. LOW-RESOLUTION pixel art, chunky simple shapes, crisp square pixels, a clean 1-pixel dark outline #14100C, flat colours, at most 3 shades per material, light from the top-left. No ground, no shadows, no text.\nFrom left to right:\n1. a SACRED GROVE TREE: a tall slender living tree with a round green crown, pale trunk, a few small white blossoms (about 36 px wide, 46 px tall);\n2. a ROSE-MAZE HEDGE segment: a long horizontal stretch of dense dark-green hedge covered in pink and red roses (about 96 px wide, 30 px tall);\n3. a GREAT ROOT: a long horizontal thick bark-brown root of the world tree arching out of the ground with moss on top (about 96 px wide, 26 px tall).\nColours: bark brown #553C27 #86603E #B08A60; moss #274D24 #599641 #9CCB72; blossom pink #9C5272 #EFA6C3 #FBD9E6; rose red only on the hedge's roses.\nAttached: a game sprite of this game for pixel size, outline weight and flat look."),
    "icon_heartwood": ("violet", ICON_HEAD.format(n=1) + "1. HEARTWOOD: a cross-section of a tree trunk, bark-brown rings round a glowing soul-teal heart, a small green sprout on top." + ICON_COL + ICON_TAIL),
}


def text(uid: str) -> str:
    if uid in CHARS:
        return CHAR_HEAD.format(w=CHARS[uid][0]) + CHARS[uid][1] + CHAR_TAIL + "\n"
    if uid in SUMMONS:
        h, w, _, sex, subj = SUMMONS[uid]
        return HEAD + subj + "\n\n" + LOWRES.format(h=h, w=w) + "\n\nSubject sex: " + sex + ".\n\nColours: " + BONE_COL + "\n\n" + TAIL + "\n"
    h, w, _, sex, subj, _ = U[uid]
    return HEAD + subj + "\n\n" + LOWRES.format(h=h, w=w) + "\n\nSubject sex: " + sex + ".\n\nColours: " + COL + "\n\n" + TAIL + "\n"


def main() -> None:
    allids = list(U) + list(CHARS) + list(SUMMONS) + list(SHEETS)
    ids = sys.argv[1:] or [u for u in allids if not (HERE / (("sheet_" + u) if u in SHEETS else ("raw/" + u))).with_suffix(".png").exists()]
    for uid in ids:
        refs, size = [], []
        if uid in SHEETS:
            kind, prompt = SHEETS[uid]
            (HERE / ("sheet_" + uid + ".txt")).write_text(prompt + "\n")
            out, txt = HERE / ("sheet_" + uid + ".png"), HERE / ("sheet_" + uid + ".txt")
            refs = ["--ref", str(HERE / "refs" / ("icon_violet.png" if kind == "violet" else "style_beast.png"))]
            size = ["--size", "1536x1024"]
        else:
            txt, out = HERE / (uid + ".txt"), HERE / "raw" / (uid + ".png")
            txt.write_text(text(uid))
            if uid in CHARS:
                refs = ["--ref", str(ROOT / "assets/sprites/player/necromancer.png"), "--ref", str(ROOT / "assets/sprites/player" / ("bone_oracle.png" if uid == "horned_herald" else "wither_witch.png"))]
            else:
                rname = (SUMMONS.get(uid) or U[uid])[2]
                style = "female" if "FEMALE" in text(uid).upper()[:0] or (uid in U and U[uid][3] == "female") else "beast"
                refs = ["--ref", str(HERE / "refs" / ("style_%s.png" % ("male" if uid in U and U[uid][3] == "male" else style)))]
                if rname and (HERE / "refs" / (rname + ".png")).exists():
                    refs += ["--ref", str(HERE / "refs" / (rname + ".png"))]
                if uid in U and U[uid][5]:
                    refs += ["--ref", str(HERE / "raw" / (U[uid][5] + ".png"))]
        print("+", uid, flush=True)
        subprocess.run([sys.executable, "tools/gen_image.py", str(txt), str(out), *refs, *size, "--key", "year2/" + uid], cwd=ROOT)


if __name__ == "__main__":
    main()
