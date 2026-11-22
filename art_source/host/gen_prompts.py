#!/usr/bin/env python3
"""gen_prompts.py: writes the Celestial Host's sprite prompts (art_source/host/<id>.txt) and generates each raw API image
(art_source/host/raw/<id>.png) with tools/gen_image.py, crops of the approved concept (refs/) as references.
Usage (repo root): python3 art_source/host/gen_prompts.py [id ...]   (no ids = every missing raw image)
Every prompt names the figure's sex (or says creature / orb); female figures use the figure-redesign style, fully clothed.
Colours: the host_ ramps of tools/palette.json (never crimson, never warm gold). The halo is drawn by the code, so never in the sprite."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
COL = ("ONLY flat fills from this list, at most 3 shades per material: starlight white #F4F7FF; pale silver #8A96AC #C9D2E0; cerulean "
       "#1F4F8F #3E8FD8 #9CC8F0; dawn rose #B07888 #F2B8C6 #FCE4EA; pale skin #B8A8A0 #E8DCD4. NO red, NO crimson, NO gold, NO yellow.")
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above "
        "and slightly in front), FULL BODY, FACING RIGHT, ")
LOWRES = ("LOW-RESOLUTION pixel art: the whole SUBJECT is only {h} pixels tall, drawn on a coarse pixel grid and shown enlarged so every pixel "
          "is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail smaller than 2 pixels except the eyes "
          "and small glints. No anti-aliasing, no gradients, no dithering, no soft glow haze. NO HALO above the head (it is added by the game).")
FEMALE = (" Figure: an exaggerated hourglass figure, glamorous, a small waist and full hips and bust, FULLY CLOTHED (chest and hips always "
          "covered by opaque cloth), never nude, no cut-outs.")
TAIL = ("Outline: a clean 1-pixel dark outline around the whole subject in deep night blue #0E1626. Light from the top-left. Keep the main "
        "shapes clearly brighter than a near-black ground.\n\nOutput: a square PNG with a FULLY TRANSPARENT background (real alpha, not a "
        "checkerboard, no dark glow around the subject), one subject only, centred, filling about 85% of the image height. No ground, no "
        "cast shadow, no text, no frame. Draw ONLY ONE figure.\nAttached: (1) a game sprite of this game for pixel size, outline weight and "
        "flat look; (2) concept art of this unit for its shape and colours only (keep it flat, chunky and low-resolution).")
# id -> (art height, style ref, sex line, subject)
U = {
    "lesser_light": (24, "male", "an orb of light (no sex)", "a LESSER LIGHT (a small orb of light): a round glowing starlight-white orb with two tiny pale-silver wings, a pale cerulean rim; just one orb, small and simple."),
    "virtue": (48, "male", "male", "a VIRTUE (male angel soldier): a tall angel in pale silver armour holding a long spear upright in his right hand, a featureless smooth silver MIRROR MASK for a face (no eyes), four pale feathered wings (two raised, two low), a pale blue tabard. Signature shape: the faceless mirror mask, four wings and the spear."),
    "power": (48, "female", "female", "a POWER (female warrior angel): silver armour over a pale-blue robe, a long blade of white flame in her right hand, a smooth silver visor-mask, two wings, a dawn-rose sash." + FEMALE),
    "choir_angel": (48, "female", "female", "a CHOIR ANGEL (female support angel): a woman in long flowing pale-blue robes with wide sleeves, singing with raised head, sheet-like light ribbons around her, a dawn-rose sash, a gown that hides her feet, small wings." + FEMALE),
    "herald": (48, "male", "male", "a HERALD (male angel): a long silver trumpet raised to his lips, a pale-blue robe with silver shoulder plates, a smooth silver mask, two large wings. Signature shape: the long trumpet."),
    "dominion": (54, "male", "male", "a DOMINION (male elite angel): tall, a silver sceptre in his right hand topped with a star, a CROWN OF LIGHT RINGS (thin cerulean rings floating, not a metal crown), ornate silver armour with a long pale-blue robe, a smooth mirror mask, two wings."),
    "judge": (56, "male", "male", "a JUDGE (male angel): a tall silver-armoured angel holding a sword in his right hand and a pair of balance SCALES held high in his left hand (dawn-rose pans), a smooth silver MIRROR MASK, a long white tabard, two wings."),
}
REF = {"judge": "dominion"}


def build(uid: str) -> str:
    h, style, sexline, subject = U[uid]
    return HEAD + subject + "\n\n" + LOWRES.format(h=h) + "\n\nSubject sex: " + sexline + ".\n\nColours: " + COL + "\n\n" + TAIL + "\n"


def main() -> None:
    ids = sys.argv[1:] or [u for u in U if not (HERE / "raw" / (u + ".png")).exists()]
    for uid in ids:
        (HERE / (uid + ".txt")).write_text(build(uid))
        style = U[uid][1]
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / (uid + ".txt")), str(HERE / "raw" / (uid + ".png")),
               "--ref", str(HERE / "refs" / ("style_%s.png" % style)), "--ref", str(HERE / "refs" / (REF.get(uid, uid) + ".png")), "--key", "host/" + uid]
        print("+", uid, flush=True)
        subprocess.run(cmd, cwd=ROOT, check=False)


if __name__ == "__main__":
    main()
