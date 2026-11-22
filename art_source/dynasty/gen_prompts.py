#!/usr/bin/env python3
"""gen_prompts.py: writes the Necropolis Dynasty's sprite prompts (art_source/dynasty/<id>.txt) and generates each raw API
image (art_source/dynasty/raw/<id>.png) with tools/gen_image.py, the approved concepts as references.

Usage (repo root): python3 art_source/dynasty/gen_prompts.py [id ...]     (no ids = every missing raw image)
Every prompt names the figure's sex (or says creature / statue / machine); every female figure is in the figure-redesign
style (exaggerated hourglass, glamorous, chest and hips covered, never nude). The colours are the dyn_ ramps of
tools/palette.json (ART_BIBLE "Act VII slot: the Necropolis Dynasty").
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/dynasty.
# Colour lists (the dyn_ ramps, dark to light) used in the prompts.
COL = {
    "night": "blue-black night #1B2038 #2E3660 #4B5894",
    "bronze": "DULL bronze-gold #6B5A22 #A38E3C #D2BB62",
    "lapis": "lapis blue #16327C #2B54B8 #5F8BE6",
    "sand": "sandstone #8C6B3E #D2B574 #F0DDA6",
    "linen": "linen #8F8670 #C9C0A4 #F0E8D2",
    "carnelian": "carnelian red #7B1E16 #BF3B2B #E87855",
    "papyrus": "papyrus green #285A30 #4E8F40 #8CC45E",
    "skin": "brown skin #5A3622 #8A5430 #B87C48",
    "wood": "wood #4F3320 #8C6040",
    "gold": "true gold #8A5A12 #E0A92E #FFDC66",
    "soul": "soul teal glow #1C6B58 #3DCC94 #A8FFD2",
    "grey": "stone grey #3B4352 #6B7A94 #A7B3C6",
}
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above "
        "and slightly in front), FULL BODY, FACING RIGHT, ")
LOWRES = ("LOW-RESOLUTION pixel art: the whole SUBJECT is only {h} pixels tall, drawn on a coarse pixel grid and shown enlarged so every pixel "
          "is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail smaller than 2 pixels except the eyes "
          "and small glints. No anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze, no hieroglyph text, no fine "
          "trims or engravings.")
FEMALE = (" Figure: an exaggerated hourglass figure, glamorous, a small waist and full hips and bust, FULLY CLOTHED (chest and hips are always "
          "covered by opaque cloth), never nude, no cut-outs.")
TAIL = ("Outline: a clean 1-pixel dark outline around the whole subject in the darkest shade of each part's own colour (never pure black). "
        "Light from the top-left: the top-left edges one shade lighter. Keep the main shapes clearly brighter than a near-black ground (#161A1C).\n\n"
        "Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white, no dark glow around the subject), "
        "one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no scenery, no text, no frame, no watermark. "
        "Draw ONLY ONE figure.\nAttached: (1) a game sprite of this game for pixel size, outline weight and flat look; (2) concept art of this "
        "unit for its shape and colours only (do NOT copy its detail level or painted shading; keep it flat, chunky and low-resolution).")

# id -> (art height, concept ref crop, style ref, sex/kind line, subject, colour keys)
U = {
    "mummy": (40, "mummy", "male", "male (a shambling undead mummy)",
              "a MUMMY of the Necropolis Dynasty (male): a tall thin man completely wrapped in dirty linen bandages, shambling forward with arms hanging, a dull bronze belt, two glowing papyrus-green eyes in the wrapped face, loose bandage ends trailing. Signature shape that must read in silhouette: the lurching wrapped body and loose bandage tails.",
              ["linen", "bronze", "papyrus"]),
    "mummy_female": (40, "mummy_female", "female", "female (an undead mummy woman)",
                     "a FEMALE MUMMY of the Necropolis Dynasty: a woman wrapped in linen bandages that fully cover her body (opaque wrappings over chest and hips), shaped in an exaggerated hourglass, a dull bronze collar and belt, glowing papyrus-green eyes, striding fast with a loose bandage tail." + FEMALE,
                     ["linen", "bronze", "papyrus"]),
    "scarab_swarm": (30, "scarab_swarm", "male", "a swarm of insects (no sex)",
                     "a SWARM of SCARAB BEETLES (creatures): one larger lapis-blue scarab in the centre with five or six smaller ones around it, all scuttling, glinting bronze legs and wing-case lines, a few tiny carnelian red sparks. Drawn as one connected cluster that reads as a swarm.",
                     ["lapis", "bronze", "carnelian"]),
    "khopesh_guard": (46, "khopesh_guard", "male", "male",
                      "a KHOPESH GUARD (male): a muscular bare-chested Egyptian soldier in a lapis-and-bronze striped nemes headcloth, white linen kilt with a lapis sash, bronze bracers and a broad bronze collar, holding a long curved bronze khopesh sword low in his right hand. Signature shape: the striped headcloth and the sickle sword.",
                      ["skin", "linen", "bronze", "lapis", "night"]),
    "nile_archer": (44, "nile_archer", "female", "female",
                    "a NILE ARCHER (female): an Egyptian archer woman with long black hair and a gold-trimmed headband, a long white linen dress with a papyrus-green and bronze broad collar, drawing a large wooden bow with an arrow nocked." + FEMALE,
                    ["skin", "linen", "bronze", "papyrus", "night", "wood"]),
    "heka_priest": (46, "heka_priest", "male", "male",
                    "a HEKA PRIEST (male): a bald Egyptian priest in a spotted leopard-skin sash over a pale kilt, bronze armbands, holding a tall staff topped with a glowing gold ankh-like glyph (a small bright true-gold glow). Signature shape: the leopard-skin sash and the glowing staff.",
                    ["skin", "linen", "bronze", "wood", "gold", "sand"]),
    "embalmer": (44, "embalmer", "female", "female",
                 "an EMBALMER (female): an Egyptian woman with a white head-wrap, a long white linen dress with a papyrus-green and bronze collar and linen wraps at her arms, carrying a large decorated canopic jar held to her side, trailing a strip of linen." + FEMALE,
                 ["skin", "linen", "bronze", "papyrus", "lapis"]),
    "jackal_warrior": (48, "jackal_warrior", "male", "male (a man with a jackal's head)",
                       "a JACKAL WARRIOR (male): a muscular man with the black-blue head of a jackal, tall pointed ears and amber eyes, a striped bronze-and-lapis nemes collar, white kilt, bronze bracers, holding a tall spear forward. Signature shape: the jackal head with tall ears and the spear.",
                       ["night", "skin", "linen", "bronze", "lapis", "wood"]),
    "bastet_hunter": (44, "bastet_hunter", "female", "female",
                      "a BASTET HUNTER (female): a lithe huntress wearing a black cat mask with pointed ears and amber eyes, long black hair, a fitted white linen dress with bronze collar and sandals, two curved daggers drawn, walking low and fast." + FEMALE,
                      ["night", "skin", "linen", "bronze", "carnelian"]),
    "crocodile_warden": (50, "crocodile_warden", "male", "male (a man with a crocodile's head)",
                         "a CROCODILE WARDEN (male): a hulking man with the green head of a crocodile, a lapis-and-bronze striped headcloth, thick papyrus-green scaled arms, a white kilt, rising half out of a pile of sand with a spray of golden sand at his feet. Signature shape: the long crocodile snout and the hulking arms.",
                         ["papyrus", "linen", "bronze", "lapis", "sand"]),
    "ushabti_statue": (46, "ushabti_statue", "male", "a stone statue (no sex)",
                       "an USHABTI STATUE (a stone servant figure, no sex): a mummiform sandstone statue standing stiff with arms crossed over its chest, a striped lapis headdress carved on, painted bronze and papyrus-green bands, faint carved lines, weathered stone. Signature shape: the narrow mummy-shaped column with crossed arms.",
                       ["sand", "lapis", "bronze", "papyrus"]),
    "canopic_jar": (30, "embalmer", "male", "an object (no sex)",
                    "a CANOPIC JAR (an object, upright, seen from the front and slightly above): a squat sandstone jar with a lapis-blue lid carved as a jackal head, bronze and lapis painted bands around the belly, a faint gold-green glow leaking from the lid. Signature shape: the round jar with the jackal-head lid.",
                    ["sand", "lapis", "bronze", "papyrus"]),
    "canopic_jar_dead": (26, "embalmer", "male", "an object (no sex)",
                         "a SHATTERED CANOPIC JAR (an object): the same squat sandstone jar broken into a few big sandstone shards and a cracked jackal-head lid lying in a small spill of sand, the glow gone dark, painted lapis and bronze band fragments. Low and flat.",
                         ["sand", "lapis", "bronze"]),
    "sand_colossus": (84, "ushabti_statue", "male", "a huge stone statue (no sex)",
                      "a SAND COLOSSUS (a huge animated sandstone statue of a seated-then-standing king, no sex): a massive blocky figure with broad square shoulders, a striped lapis nemes headdress, a bronze collar, thick arms hanging with huge fists, cracks and sand pouring from its joints, glowing papyrus-green eyes. Signature shape: the enormous blocky body and the nemes headdress.",
                      ["sand", "lapis", "bronze", "papyrus"]),
    "lion_warden": (80, "khopesh_guard", "male", "male (a giant stone warrior)",
                    "the LION WARDEN (male): a huge stone warrior with a carved lion's head, a bronze-and-lapis headdress, bare muscular sandstone torso, a short kilt, bronze bracers, carrying a tall shield-like slab and a heavy stone axe, standing like a doorway guardian, glowing carnelian-red eyes. Signature shape: the lion head and the huge slab shield.",
                    ["sand", "lapis", "bronze", "carnelian"]),
    "devourers_whelp": (52, "ammit", "male", "a creature (young, no clothes)",
                        "the DEVOURER'S WHELP (a young beast, creature): a squat young monster with a crocodile's head and green scales, a tawny lion's body and the thick dark hindquarters of a hippo, small claws, chewing, a few bone scraps at its mouth. Signature shape: the long crocodile snout on a stocky tawny body with dark rump.",
                        ["papyrus", "sand", "night", "bronze", "carnelian"]),
    "anubis": (90, "anubis", "male", "male (a god with a jackal's head)",
               "ANUBIS, Opener of the Way (male god): a tall muscular man with the black-blue head of a jackal, tall pointed ears, amber eyes, a bronze-and-lapis striped nemes collar, a long white kilt with a bronze belt, bronze bands on his arms and legs, holding a tall bronze crook-topped staff in his right hand. Signature shape: the tall jackal head with ears and the tall crook staff.",
               ["night", "skin", "linen", "bronze", "lapis", "wood"]),
    "sekhmet": (92, "sekhmet", "female", "female (a goddess with a lioness's head)",
                "SEKHMET, the Lioness of Retribution (female goddess): a woman with the tawny head of a lioness wearing a large carnelian-red sun disc between two bronze horns, a tight long carnelian red gown, a bronze collar and belt, clawed hands raised, tawny furred arms, standing tall." + FEMALE,
                ["sand", "carnelian", "bronze", "night", "skin"]),
    "osiris": (96, "osiris", "male", "male (a god, green-skinned)",
               "OSIRIS, Lord of the Dead (male god) seated on a tall dark throne with bronze trim: green papyrus skin, a tall white atef crown, a long white linen robe, holding a bronze crook and flail crossed on his chest, a stern face. Signature shape: the tall white crown and the throne.",
               ["papyrus", "linen", "bronze", "night", "lapis"]),
    "ammit": (60, "ammit", "male", "a creature (a monster, no sex)",
              "AMMIT the Devourer (a monster, creature): the head and jaws of a crocodile with a striped lapis-and-bronze mane collar, a tawny lion's front body with claws, the thick dark purple-grey hindquarters of a hippopotamus, low and crouched, prowling forward with open jaws. Signature shape: the long open crocodile jaws on a low lion-hippo body.",
              ["papyrus", "sand", "night", "bronze", "lapis", "carnelian"]),
    "the_embalmer": (56, "embalmer", "female", "female (the Embalmer, a PLAYABLE hero)",
                     "THE EMBALMER (female hero, the necromancer's ally): an Egyptian woman in a hooded white linen head-wrap and a long fitted linen dress wrapped with extra bandages, a true gold collar, carrying a jar and a long roll of bandage that glows with soul-teal light, teal glowing eyes, calm. Signature shape: the hooded wrap and the glowing bandage roll." + FEMALE,
                     ["linen", "skin", "gold", "soul", "night", "wood"]),
    "lion_priestess": (56, "sekhmet", "female", "female (the Lion-Priestess, a PLAYABLE hero)",
                       "THE LION-PRIESTESS (female hero, human, NOT a goddess): an Egyptian priestess wearing a gold lioness mask pushed back like a hood, a small carnelian red sun disc on her brow, a long red linen gown with a true gold collar and belt, one hand raised holding a small burning sun, fierce and proud." + FEMALE,
                       ["carnelian", "skin", "gold", "night", "linen"]),
    "pharaohs_shade": (56, "osiris", "male", "male (the Pharaoh's Shade, a PLAYABLE hero)",
                       "THE PHARAOH'S SHADE (male hero, a ghost king): a tall spectral pharaoh in a striped lapis-and-gold nemes headcloth, a broad true-gold collar, a pale linen kilt, translucent teal-green ghostly skin that fades to wisps at the feet, holding a crook and flail, teal glowing eyes. Signature shape: the nemes headcloth and the wispy tail.",
                       ["lapis", "gold", "soul", "linen", "grey"]),
    "ushabti_sentinel": (46, "ushabti_statue", "male", "a stone servant (no sex), the necromancer's own summon",
                         "an USHABTI SENTINEL (a stone servant, no sex, the necromancer's undead army): a mummiform grey-sandstone statue servant standing guard holding a stone staff and a short square shield, crossed carved belt, glowing soul-teal eyes and soul-teal glyph lines glowing in the cracks, bronze-free, calm and sturdy. Signature shape: the narrow stone figure with a staff and square shield.",
                         ["sand", "grey", "soul", "wood"]),
    "eternal_guard": (58, "ushabti_statue", "male", "a stone guardian (no sex), the necromancer's own summon",
                      "an ETERNAL GUARD (an evolved stone servant, no sex, the necromancer's undead army): a taller armoured mummiform sandstone statue with a true-gold striped headdress and true-gold armbands, a tall gold-edged staff and a big square shield with a gold sun carved in it, bright soul-teal glowing eyes and soul-teal light in the cracks. Signature shape: the tall figure with the big shield and gold headdress.",
                      ["sand", "grey", "soul", "gold", "wood"]),
}


def build(uid: str) -> str:
    h, ref, style, sexline, subject, cols = U[uid]
    colours = "; ".join(COL[c] for c in cols)
    return (HEAD + "a " + sexline + " figure.\n\n" if False else HEAD) + subject + "\n\n" + LOWRES.format(h=h) + "\n\nSubject sex: " + sexline + \
        ".\n\nColours: ONLY flat fills from this list, at most 3 shades per material: " + colours + "\n\n" + TAIL + "\n"


def main() -> None:
    ids = sys.argv[1:] or [u for u in U if not (HERE / "raw" / (u + ".png")).exists()]
    for uid in ids:
        (HERE / (uid + ".txt")).write_text(build(uid))
        h, ref, style, *_ = U[uid]
        style_png = ROOT / ("art_source/dynasty/refs/style_%s.png" % style)
        cmd = [sys.executable, "tools/gen_image.py", str(HERE / (uid + ".txt")), str(HERE / "raw" / (uid + ".png")),
               "--ref", str(style_png), "--ref", str(HERE / "refs" / (ref + ".png")), "--key", "dynasty/" + uid]
        print("+", uid, flush=True)
        subprocess.run(cmd, cwd=ROOT, check=False)


if __name__ == "__main__":
    main()
