#!/usr/bin/env python3
"""gen_chars.py: the Dynasty's three playable characters, redone to the game's convention (owner note, Nov 2026): a NECROMANCER of the
act's theme, violet-dominant with bone-white and soul-teal accents, pale undead-touched skin, a casting focus in hand, 56 px tall.
Usage (repo root): python3 art_source/dynasty/gen_chars.py [id ...]; raw images land in art_source/dynasty/chars/<id>.png."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty.
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above and "
        "slightly in front), FULL BODY, FACING RIGHT, neutral ready stance.\n\nLOW-RESOLUTION pixel art: the whole figure is only 56 pixels "
        "tall and at most 40 pixels wide, drawn on a coarse pixel grid and shown enlarged so every pixel is a big crisp square block "
        "(nearest-neighbour). Chunky, simple, readable shapes; no detail smaller than 2 pixels except the eyes and small glints. No "
        "anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze, no fine trims, no hieroglyph writing.\n\nSubject: ")
TAIL = ("\n\nOutline: a clean 1-pixel dark outline around the whole figure in the darkest shade of each part's own colour (never pure black). "
        "Light from the top-left: the top-left edges one shade lighter. Keep the main shapes clearly brighter than a near-black ground (#161A1C).\n\n"
        "Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white, no dark glow around the figure), "
        "one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no scenery, no text, no frame, no watermark.\n"
        "Attached: (1) the game's necromancer and (2) another necromancer character of this game: match their pixel size, outline weight, violet "
        "palette and flat look exactly (not their subjects).")
VIO = "violet #1C0F2B (outline) #3B1F5C #6B39A6 #A35CFA"
C = {
    "the_embalmer": ("THE EMBALMER, a FEMALE character, a necromancer of the Egyptian Necropolis who preserves the dead and now serves the army, in the "
        "figure-redesign style: an exaggerated hourglass figure with a big bust and wide hips, FULLY CLOTHED and modest (never explicit): a hooded "
        "dark violet linen head-wrap and a long fitted violet linen gown wrapped with extra violet-tinged bandage strips and a broad pale collar, "
        "pale bone-white undead-touched skin, a calm pale face with soft teal glowing eyes, bandage ends trailing. In her front (right) hand a "
        "tall staff topped with a small canopic jar whose lid glows soul-teal (her casting focus). Signature shape that must read in silhouette: "
        "the wrapped hood, the hourglass figure and the tall jar-topped staff.",
        "Colours: ONLY flat fills from this list, at most 3 shades per material: " + VIO + "; bandage and skin bone #4A3E2E #A79A80 #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94 #A8FFD2; staff wood #2A1C12 #5B3D26 #8C6040."),
    "lion_priestess": ("THE LION-PRIESTESS, a FEMALE character, a necromancer-priestess of the Egyptian war goddess, in the figure-redesign style: an "
        "exaggerated hourglass figure with a big bust and wide hips, FULLY CLOTHED and modest (never explicit): a fitted long violet priestess's "
        "dress with a high collar and a violet cape, a violet lioness-head headdress (bone-white fangs and ears) worn like a hood over her hair, "
        "pale bone-white undead-touched skin, soft teal glowing eyes. In her front (right) hand a tall staff topped with a small sun disc ringed in "
        "soul-teal light (her casting focus). Signature shape that must read in silhouette: the lioness-head hood, the hourglass figure and the "
        "sun-disc staff.",
        "Colours: ONLY flat fills from this list, at most 3 shades per material: " + VIO + "; bone #4A3E2E #A79A80 #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94 #A8FFD2; staff wood #2A1C12 #5B3D26 #8C6040."),
    "pharaohs_shade": ("THE PHARAOH'S SHADE, a MALE character, a dead king who became a necromancer and serves the army: a tall spectral man in a "
        "long dark violet robe, a violet-and-bone striped nemes headcloth with a small cobra at the brow, a broad bone-white collar, pale grey-white "
        "ghostly undead skin, soul-teal glowing eyes, the robe fading to wisps at the feet. In his front (right) hand a crook staff whose hook holds a "
        "glowing soul-teal flame (his casting focus), a flail hanging at his belt. Signature shape that must read in silhouette: the nemes "
        "headcloth, the crook staff and the wispy hem.",
        "Colours: ONLY flat fills from this list, at most 3 shades per material: " + VIO + "; bone #4A3E2E #A79A80 #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94 #A8FFD2; staff wood #2A1C12 #5B3D26 #8C6040."),
}
for k in (sys.argv[1:] or C):
    subj, cols = C[k]
    (HERE / "chars" / (k + ".txt")).write_text(HEAD + subj + "\n\n" + cols + TAIL + "\n")
    subprocess.run([sys.executable, "tools/gen_image.py", str(HERE / "chars" / (k + ".txt")), str(HERE / "chars" / (k + ".png")),
                    "--ref", str(ROOT / "assets/sprites/player/necromancer.png"), "--ref", str(ROOT / "assets/sprites/player/ferrywoman.png"),
                    "--key", "dynasty/char_" + k], cwd=ROOT)
