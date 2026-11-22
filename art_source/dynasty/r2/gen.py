#!/usr/bin/env python3
"""r2/gen.py: round 2 of the owner's art review: regenerates khopesh_guard, mummy, ushabti_sentinel and lion_priestess (raw images in r2/).
Usage (repo root): python3 art_source/dynasty/r2/gen.py [id ...]"""
import subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty/r2.
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above and "
        "slightly in front), FULL BODY, FACING RIGHT, {pose}\n\nLOW-RESOLUTION pixel art: the whole figure is only {h} pixels tall, drawn on a coarse "
        "pixel grid and shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail "
        "smaller than 2 pixels except the eyes and small glints. No anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze, "
        "no hieroglyph text, no fine trims or engravings.\n\nSubject: {subject}\n\n{colours}\n\n")
TAIL = ("Outline: a clean 1-pixel dark outline around the whole subject in the darkest shade of each part's own colour (never pure black). Light from "
        "the top-left. Keep the main shapes clearly brighter than a near-black ground (#161A1C).\n\nOutput: a square PNG with a FULLY TRANSPARENT "
        "background (real alpha, not a checkerboard, not white, no dark glow), one subject only, centred, filling about 85% of the image height. No "
        "ground, no cast shadow, no scenery, no text, no frame, no watermark. Draw ONLY ONE figure.\nAttached: {refs}")
S = {
 "khopesh_guard": (46, "standing guard stance, sword held low and out to the side so the whole blade shows",
  "a KHOPESH GUARD (male): a muscular bare-chested Egyptian soldier in a lapis-and-bronze striped nemes headcloth, white linen kilt with a lapis sash, bronze bracers and a broad bronze collar. In his right hand a REAL KHOPESH: the ancient Egyptian sickle-sword: a short straight grip, then a blade that goes straight out and then curves sharply OUTWARD into a big hooked sickle-shaped crescent (like a reaping sickle or the numeral 7 / question mark), thick bronze blade with the hook clearly visible, NOT a straight sword and NOT a scimitar. Signature shape: the striped headcloth and the hooked sickle blade.",
  "Colours: ONLY flat fills, at most 3 shades per material: brown skin #5A3622 #8A5430 #B87C48; linen #8F8670 #C9C0A4 #F0E8D2; DULL bronze-gold #6B5A22 #A38E3C #D2BB62; lapis blue #16327C #2B54B8 #5F8BE6; blue-black night #1B2038 #2E3660 #4B5894",
  "(1) the old version of this sprite for pixel size, outline and flat look (keep the headcloth, kilt and colours, but REPLACE the sword with a real hooked khopesh); (2) a game sprite for outline weight.",
  ["assets/sprites/dynasty/khopesh_guard.png", "assets/sprites/dynasty/jackal_warrior.png"]),
 "mummy": (40, "shambling, hunched, both arms stretched out in front",
  "a MUMMY of the Necropolis Dynasty (male undead): a hunched, lurching figure WRAPPED HEAD TO TOE in layered dirty-cream linen bandages in criss-crossing strips, no skin visible anywhere, the head fully wrapped as well, a small dark gap in the wraps over the eyes with two FAINTLY glowing dull papyrus-green eyes, both arms held stiffly forward at chest height, many LOOSE BANDAGE STRIPS trailing and hanging from the arms, shoulders and legs, a dull bronze belt. Must read instantly as a classic wrapped mummy.",
  "Colours: ONLY flat fills, at most 3 shades per material: linen #8F8670 #C9C0A4 #F0E8D2; DULL bronze-gold #6B5A22 #A38E3C #D2BB62; papyrus green (eyes only, faint) #285A30 #4E8F40 #8CC45E",
  "(1) the old version of this sprite for pixel size, outline and flat look (make it MORE wrapped and more mummy-like); (2) a game sprite for outline weight.",
  ["assets/sprites/dynasty/mummy.png", "assets/sprites/dynasty/mummy_female.png"]),
 "ushabti_sentinel": (46, "standing straight, symmetrical front-three-quarter view, a small stiff servant statue come alive",
  "an USHABTI SENTINEL (the necromancer's own summon; no sex): a small, clean, readable carved-stone Egyptian shabti servant figure: a MUMMIFORM body (tapering, legs fused into one sheath), arms folded across the chest each holding a small hoe (a short pick with a curved head), a painted striped nemes-style headdress with a lapis band, a plain calm carved face with two soul-teal glowing eyes, a dull-gold collar, and two or three horizontal carved bands of simple hieroglyph blocks down the body, painted lapis and dull gold on dark grey stone. Very simple clear silhouette, symmetrical, like a little statue.",
  "Colours: ONLY flat fills, at most 3 shades per material: dark stone grey #23262B #3E444C #6C747E; lapis blue #16327C #2B54B8 #5F8BE6; dull gold #6B5A22 #A38E3C #D2BB62; soul teal (eyes only) #1C6B58 #3DCC94 #A8FFD2",
  "(1) an Egyptian ushabti statue sprite of this game for the style, outline and flat look; (2) a game sprite for outline weight. Make the new figure CLEANER and simpler than the first reference.",
  ["assets/sprites/dynasty/ushabti_statue.png", "assets/sprites/dynasty/jackal_warrior.png"]),
 "lion_priestess": (56, "neutral ready stance",
  "THE LION-PRIESTESS, a FEMALE character, a necromancer-priestess of the Egyptian war goddess, in the figure-redesign style: an exaggerated hourglass figure with a big bust and wide hips, FULLY CLOTHED and modest (never explicit): a fitted long VIOLET priestess's dress with a high bone-white collar and NO stripes or trim on the dress (only smooth violet in two tones, no cream lines anywhere on the dress or cape). On her head a BIG, BOLD LIONESS HEAD-DRESS, about as wide as her shoulders and a quarter of her height: the head of a lioness in PALE BONE-WHITE / cream fur seen from the front-right, with two large round ears, a clear muzzle with a dark nose and two bone-white fangs, and two bright glowing teal eyes, sitting on top of her head like a helmet, her own pale face looking out beneath the lion's open jaw; behind it a broad MANE of SOLID dark violet in two tones (NO cream stripes in the mane) falling in a smooth shape down to her shoulders and framing her face. Her arms are slender and the staff is held close to her body so the whole figure is narrow (about 34 pixels wide). The lion head must be much LIGHTER (cream) than the dark violet dress and mane so it reads instantly. Pale undead-touched skin, soft teal eyes. In her front (right) hand a tall staff topped with a small sun disc ringed in soul-teal light. Very simple, chunky, high-contrast shapes, very few colours.",
  "Colours: ONLY flat fills, at most 3 shades per material: violet #1C0F2B (outline) #3B1F5C #6B39A6 #A35CFA; bone / cream #A79A80 #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94 #A8FFD2; staff wood #2A1C12 #5B3D26 #8C6040.",
  "(1) the game's necromancer and (2) another necromancer character of this game: match their pixel size, outline weight, violet palette and flat look exactly (not their subjects). Make the pixels BIG and chunky, with much less detail than a typical illustration.",
  ["assets/sprites/player/necromancer.png", "assets/sprites/player/ferrywoman.png"]),
}
for k in (sys.argv[1:] or S):
    h, pose, subj, cols, refs, rf = S[k]
    (HERE / (k + ".txt")).write_text(HEAD.format(pose=pose, h=h, subject=subj, colours=cols) + TAIL.format(refs=refs) + "\n")
    cmd = [sys.executable, "tools/gen_image.py", str(HERE / (k + ".txt")), str(HERE / (k + ".png")), "--key", "dynasty/r2_" + k]
    for r in rf:
        cmd += ["--ref", str(ROOT / r)]
    subprocess.run(cmd, cwd=ROOT)
