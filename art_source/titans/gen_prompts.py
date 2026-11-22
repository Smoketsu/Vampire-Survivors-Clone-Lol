#!/usr/bin/env python3
"""gen_prompts.py: writes the Age of Titans' sprite prompts (art_source/titans/<id>.txt) and generates each raw API image
(art_source/titans/raw/<id>.png) with tools/gen_image.py; crops of the approved lineup (refs/) and an approved beast sprite
(refs/style_beast.png) are the references. Usage (repo root): python3 art_source/titans/gen_prompts.py [id ...]  (no ids = every
missing raw image). Every prompt names the creature's sex; these are animals: no human features, no figure style, no humans.
Colours: the primeval_ ramps of tools/palette.json (fern, ochre, tar, lava orange, bone; never crimson, gold or violet)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/titans.
COL = ("ONLY flat fills from this list, at most 3 shades per material: fern green #24451F #4D8534 #8CC46A; dust ochre #7E552A #C89448 "
       "#E8C88A; tar black-brown #231C18 #4A3A30 #6E5A4C; volcanic orange #8A2E0C #EF6B1C #FFC070; bone white #9C9078 #E7DEC9 #F8F6EE. "
       "NO red, NO crimson, NO gold, NO purple, NO blue.")
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above "
        "and slightly in front), FULL BODY, FACING RIGHT, ")
LOWRES = ("LOW-RESOLUTION pixel art: the whole SUBJECT is only {h} pixels tall and about {w} pixels wide, drawn on a coarse pixel grid and "
          "shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail "
          "smaller than 2 pixels except the eyes. No anti-aliasing, no gradients, no dithering, no glow haze. A prehistoric ANIMAL: no "
          "human features, no clothes, no weapons.")
TAIL = ("Outline: a clean 1-pixel dark outline around the whole subject in tar black #120F0D. Light from the top-left. Keep the main "
        "shapes clearly brighter than a near-black ground.\n\nOutput: a square PNG with a FULLY TRANSPARENT background (real alpha, not a "
        "checkerboard, no dark glow around the subject), one subject only, centred, filling about 85% of the image. No ground, no "
        "cast shadow, no text, no frame.\nAttached: (1) a game sprite of this game for pixel size, outline weight and flat look; (2) "
        "concept art of this creature for its shape only (re-colour it to the list; keep it flat, chunky and low-resolution).")
# id -> (art h, art w, sex line, subject)
U = {
    "scuttler": (14, 20, "no sex (fodder)", "ONE SCUTTLER: a tiny fast lizard seen from above-right, ochre body with a darker tar-brown back stripe, a long thin tail, four tiny legs; just one lizard, small and simple."),
    "razorclaw": (34, 44, "male", "a RAZORCLAW (male feathered raptor dinosaur): fern-green hide and feathers, a lean body leaning forward, long tail held out behind, bone-white sickle claws on the feet, a short plain feather crest, mouth open. Signature shape: the raised sickle claw."),
    "razorclaw_alpha": (38, 48, "female", "the female RAZORCLAW ALPHA (a larger female raptor dinosaur, pack leader): fern-green hide, a TALL bone-white feather crest, a pale scar across the muzzle, bone-white claws, mouth open, powerful and proud. Told from the males by the tall crest and her size."),
    "frill_spitter": (32, 40, "male", "a FRILL SPITTER (male lizard-dinosaur): a wide fan-shaped frill around the head in volcanic orange with tar-brown ribs, fern-green body, a drop of venom at the open jaw."),
    "longneck": (80, 96, "both sexes (one sprite)", "a LONGNECK (a huge sauropod, gentle giant): dust-ochre hide with a pale ochre belly, a long neck and long tail, four thick pillar legs, a small head, standing side-on. The body is long and low-slung; the neck rises to the left-front."),
    "duckbill": (56, 68, "no sex", "a DUCKBILL (hadrosaur): ochre hide, a bone-white crest horn curving back from the head, a flat bill-shaped snout, walking on two thick hind legs with a heavy tail, small arms."),
    "skyraider": (36, 56, "male", "a SKYRAIDER (male pterosaur) in flight, wings spread wide, seen from above-right: ochre wing membranes with tar-brown bones, a long bone-white beak, a head crest, two small claws clutching a glowing volcanic-orange crystal below it."),
    "tyrant": (72, 88, "both sexes (one sprite)", "a TYRANT (a great tyrannosaur titan): tar-black hide with darker back, a huge head with a wide open jaw and bone-white teeth, a glowing volcanic-orange throat, small arms, a heavy tail, standing side-on, menacing."),
}
REF = {"razorclaw_alpha": "razorclaw"}


def build(uid: str) -> str:
    h, w, sexline, subject = U[uid]
    return HEAD + subject + "\n\n" + LOWRES.format(h=h, w=w) + "\n\nSubject sex: " + sexline + ".\n\nColours: " + COL + "\n\n" + TAIL + "\n"


def main() -> None:
    ids = sys.argv[1:] or [u for u in U if not (HERE / "raw" / (u + ".png")).exists()]
    for uid in ids:
        (HERE / (uid + ".txt")).write_text(build(uid))
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / (uid + ".txt")), str(HERE / "raw" / (uid + ".png")),
               "--ref", str(HERE / "refs" / "style_beast.png"), "--key", "titans/" + uid]
        if (HERE / "refs" / (REF.get(uid, uid) + ".png")).exists():
            cmd += ["--ref", str(HERE / "refs" / (REF.get(uid, uid) + ".png"))]
        print("+", uid, flush=True)
        subprocess.run(cmd, cwd=ROOT, check=False)


if __name__ == "__main__":
    main()
