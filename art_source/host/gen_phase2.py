#!/usr/bin/env python3
"""gen_phase2.py: the Celestial Host's phase 2 sprite prompts and raw API images (guardians, minibosses, bosses, the three violet
necromancer characters, the finale summon class). Usage (repo root): python3 art_source/host/gen_phase2.py [id ...] (no ids = every missing).
Raw images land in art_source/host/raw/<id>.png, prompts beside this file. Same palette rules as gen_prompts.py (never crimson or warm gold);
every prompt names the sex (or creature / wheel / seraph). Characters: violet necromancers, 56 px, a casting focus (PLAN.md)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_prompts import COL, HEAD, LOWRES, FEMALE, TAIL  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
VIO = "violet #1C0F2B (outline) #3B1F5C #6B39A6 #A35CFA; bone white #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94; pale undead skin #B8A8A0 #E8DCD4. NO red, NO gold."
CHAR_HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view, FULL BODY, FACING RIGHT, ready stance. LOW-RESOLUTION pixel art: "
             "the whole figure is only 56 pixels tall and at most 40 pixels wide, coarse pixel grid shown enlarged with crisp square pixels. Chunky simple shapes, no "
             "anti-aliasing, no gradients, no glow haze. Subject: ")
CHAR_TAIL = ("\n\nColours: ONLY flat fills, at most 3 shades per material: " + VIO + "\nOutline: a clean 1-pixel dark outline in the darkest shade of each part's colour. Light from the top-left.\n"
             "Output: a square PNG with a FULLY TRANSPARENT background, one figure only, centred, filling about 85% of the height. No ground, no shadow, no text.\n"
             "Attached: the game's necromancer and another necromancer of this game: match their pixel size, outline and flat look (not their subjects).")
# id -> (height, refs, sex line, subject). Creature / boss prompts use the Host head.
U = {
    "cherub": (56, "cherub", "creature (no sex)", "a CHERUB (a creature, no sex): four faces around a central body (a lion, an ox, an eagle and a man's mask-like face) and four large wings covered in small cerulean eyes, a flaming white sword of light held in front. Signature shape: four faces and four eye-covered wings."),
    "cherub_of_the_gate": (76, "cherub", "creature (no sex)", "a larger CHERUB OF THE GATE (a creature, no sex): four faces (lion, ox, eagle, man), four huge wings covered in cerulean eyes, a very large flaming white sword in front. Bigger and more imposing than a Cherub."),
    "seraiel": (96, "seraiel", "male", "SERAIEL, WARDEN OF THE GATE (male archangel): a towering man in pale silver armour with a smooth silver mask-helm, FOUR great white wings (two raised high, two low), a huge flaming white sword held down in front of him with both hands, a long white tabard."),
    "seraiel_raised": (96, "seraiel", "male", "SERAIEL, WARDEN OF THE GATE (male archangel) with his sword RAISED high overhead in both hands about to strike: a towering man in pale silver armour, smooth silver mask-helm, FOUR great white wings spread wide, a huge flaming white sword held up above his head, a long white tabard."),
    "ophan": (52, "ophan", "wheel (no sex)", "an OPHAN (a wheel, no sex): a burning silver wheel within a wheel, the rims covered in small cerulean eyes, cerulean fire licking around it, seen as a big ring standing upright. Perfectly symmetrical so it can be rotated."),
    "dominion_of_the_spheres": (70, "dominion", "male", "a DOMINION OF THE SPHERES (male elite angel, larger and grander): a tall man with a silver sceptre topped with a star, a crown of thin cerulean RINGS floating around his head, ornate silver armour and a long pale-blue robe with small crystal shards, smooth mirror mask, two wings."),
    "throne": (96, "throne", "wheel (no sex)", "the THRONE (a colossal wheel, no sex): a huge silver wheel within a wheel, the rims covered in many small cerulean eyes, blue fire around it, an eye-like hub in the middle. Perfectly symmetrical wheel seen face-on, filling the whole image."),
    "throne_open": (96, "throne", "wheel (no sex)", "the THRONE (a colossal wheel, no sex) with its two wheels PARTED: the outer silver wheel and the inner wheel pulled apart leaving an empty open dark-blue gap in the middle, rims covered in small cerulean eyes, blue fire around it. Symmetrical, face-on, filling the whole image."),
    "throne_core": (32, "throne", "an eye (no sex)", "the CORE of the Throne: a single large burning white eye with a cerulean iris and a vertical slit pupil, a ring of blue fire around it, round and symmetrical."),
    "herald_of_the_seventh_trumpet": (70, "herald", "male", "the HERALD OF THE SEVENTH TRUMPET (male elite angel, larger): a tall man in a pale-blue robe with silver shoulder plates, a smooth silver mask, two huge wings, blowing a very long GREAT silver trumpet raised to his lips."),
    "voice": (104, "voice", "seraph (no sex)", "the VOICE (a sexless seraph of light): six white wings, two folded over where the face would be, two folded over the feet, two spread wide, standing in a large white-and-pale-rose lotus-like ROSE of light. No face, no body visible, only wings and the rose."),
    "voice_unveiled": (104, "voice", "seraph (no sex)", "the VOICE UNVEILED (a sexless seraph of light): six white wings, the two face wings now LOWERED to reveal a face of pure bright white light with NO features at all, two wings over the feet, two spread wide, in a large white-and-pale-rose rose of light."),
    "bound_ophan": (30, "ophan", "wheel (no sex)", "a small BOUND OPHAN: a wheel made of BONE-white bones, a wheel within a wheel, with glowing soul-teal (#3DCC94) eyes along the rim. Symmetrical, upright ring. NO silver, NO blue."),
    "throne_of_bones": (44, "ophan", "wheel (no sex)", "a THRONE OF BONES: a larger double wheel of BONE-white bones with soul-teal (#3DCC94) fire burning in the middle and a teal eye hub. Symmetrical upright ring. NO silver, NO blue."),
}
CHARS = {
    "fallen_herald": "THE FALLEN HERALD, a MALE necromancer: a long violet robe and a torn violet cope, one broken bone-white wing on his back, pale undead skin, a hood, teal glowing eyes. In his right hand a tall dark staff with a trumpet-shaped head holding a soul-teal flame (his casting focus). Silhouette: the one broken wing and the trumpet-headed staff.",
    "blind_saint": "THE BLIND SAINT, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: a long fitted violet gown with a high collar, a violet blindfold over her eyes, pale undead skin. In her right hand a tall staff ringed near its top with a small wheel of bone-white closed eyes lit soul-teal (her casting focus). Silhouette: the blindfold, the hourglass figure and the wheel-topped staff.",
    "the_unveiled": "THE UNVEILED, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: a fitted violet dress with a high collar, a violet veil lowered from her head over the face, small grey-white wings folded on her back, pale undead skin. In her right hand a tall staff topped with a small dead star of soul-teal light (her casting focus). Silhouette: the veil, the folded wings, the hourglass figure and the star staff.",
}


def text(uid: str) -> str:
    if uid in CHARS:
        return CHAR_HEAD + CHARS[uid] + CHAR_TAIL + "\n"
    h, _, sexline, subject = U[uid]
    col = COL if not uid.startswith(("bound", "throne_of")) else "ONLY flat fills: bone white #CFC7AE #EDE6D0 #4A3E2E; soul teal #1C6B58 #3DCC94 #A8FFD2. NO red, NO gold."
    fem = FEMALE if sexline == "female" else ""
    return HEAD + subject + fem + "\n\n" + LOWRES.format(h=h) + "\n\nSubject sex: " + sexline + ".\n\nColours: " + col + "\n\n" + TAIL + "\n"


def main() -> None:
    ids = sys.argv[1:] or [u for u in list(U) + list(CHARS) if not (HERE / "raw" / (u + ".png")).exists()]
    for uid in ids:
        (HERE / (uid + ".txt")).write_text(text(uid))
        refs = ["--ref", str(ROOT / "assets/sprites/player/necromancer.png"), "--ref", str(ROOT / "assets/sprites/player/the_embalmer.png")] if uid in CHARS else \
               ["--ref", str(HERE / "refs" / ("style_male.png")), "--ref", str(HERE / "refs" / (U[uid][1] + ".png"))]
        print("+", uid, flush=True)
        subprocess.run([sys.executable, "tools/gen_image.py", str(HERE / (uid + ".txt")), str(HERE / "raw" / (uid + ".png")), *refs, "--key", "host2/" + uid], cwd=ROOT)


if __name__ == "__main__":
    main()
