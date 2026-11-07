#!/usr/bin/env python3
"""make_art.py: builds the Black Tide's art (Act "X", the corsair key; docs/tide/ART_MANIFEST.md) from API sources.

Run from the repo root:  python3 art_source/corsair/make_art.py <step> [keys...]
Steps:
  gen      write each prompt (art_source/corsair/prompts/<key>.txt) and call tools/gen_image.py (skips a raw that exists);
           raw API images land in art_source/corsair/raw/<key>.png. Several keys can be given to redo only those.
  convert  raw -> assets/sprites/<folder>/<id>.png through tools/pixelate_source.py + tools/prepare_sprite.py.
  strips   walk / glide / hover strips and the female idle strips through tools/walk_cycle.py (rigs added to RIGS first).
  sheets   the obstacle sheet and the icon sheets cut apart and converted.
  tiles    the three deck floors and the water (procedural, tools/corsair_tiles.py).
Every prompt names the figure's sex (or says creature / boat / object); every female figure is in the figure-redesign
style and fully clothed (CLAUDE.md). The unit table below is the single source of truth for heights and ramps.
"""
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/corsair.
RAW = HERE / "raw"  # Raw API images.
REFS = HERE / "refs"  # Reference crops.
PROMPTS = HERE / "prompts"  # Prompt files.
LEDGER = ROOT / "docs" / "art" / "generation_ledger.csv"  # Cost ledger (appended by gen_image.py).

HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view "
        "(camera above and slightly in front), FULL BODY, FACING RIGHT, ")
LOWRES = ("\n\nLOW-RESOLUTION pixel art: the whole SUBJECT is only {h} pixels tall{w}, drawn on a coarse pixel grid and shown enlarged so every "
          "pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail smaller than 2 pixels except "
          "the eyes and small glints. No anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze, no fine trims, "
          "lacing or engravings.\n\n")
TAIL = ("\n\nOutline: a clean 1-pixel dark outline around the whole subject in the darkest shade of each part's own colour (never pure "
        "black). Light from the top-left: the top-left edges one shade lighter. Keep the main shapes clearly brighter than a near-black "
        "ground (#161A1C).\n\nOutput: a {shape} PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white, no dark "
        "glow around the subject), one subject only, centred, filling about 85% of the image {fill}. No ground, no cast shadow, no "
        "scenery, no text, no frame, no watermark. Draw ONLY ONE subject.\nAttached: {att}")
PAL = ("tarred oak #2B1D14 #4A3220 #7A5632; sailcloth cream #8F8466 #D6CBA4 #F0E9CE; brass #7A5A1C #C4912A #EBC85A; powder grey "
       "#2E3239 #5E636C #9498A0; sash red #6A1620 #B02A30 #E2563F; lantern amber #B0661C #F2A63A #FFDF8A; navy #0E1A33 #1B3560 #2F5F96; "
       "weathered skin #5C3824 #96623E #C68B5E")
HUM = "oak,sail,brass,powder,sash,lantern,sea,tan"  # Ramps of a pirate.

# key -> dict(folder, h art px, kind, ramps, sex, subject, colours, [extra prepare args], [ref concept key], [shape], [w text]).
# folder is the sprite folder under assets/sprites; id is the part after the slash.
U = {}


def unit(key, h, sex, subject, ramps=HUM, colours=PAL, ref=None, kind="figure", extra=None, w="", shape="square", ink="0.15"):
    """Registers one generated unit."""
    U[key] = dict(h=h, sex=sex, subject=subject, ramps=ramps, colours=colours, ref=ref or key.split("/")[-1], kind=kind,
                  extra=extra or [], w=w, shape=shape, ink=ink)


# --- the roster (corsair/) ---
unit("corsair/deckhand", 40, "male", "a DECKHAND, a MALE pirate fodder soldier mid-charge with a curved cutlass raised: a red bandana, a "
     "navy-and-cream striped shirt, a red sash, dark trousers, brown boots, a weathered face with stubble. Signature shape: the striped shirt "
     "and the raised cutlass.")
unit("corsair/musketeer", 42, "male", "a MUSKETEER, a MALE pirate marksman aiming a long musket forward: a black tricorn hat, a navy coat "
     "with brass buttons, cream shirt, dark trousers, brown boots. Signature shape: the tricorn and the long musket.")
unit("corsair/powder_runner", 40, "male", "a POWDER RUNNER, a MALE pirate sprinting hunched forward carrying a small barrel (a powder keg) "
     "under one arm with a short LIT FUSE spitting an amber spark: a red bandana, a cream shirt, a red sash, dark trousers, boots. "
     "Signature shape: the keg and the spark.")
unit("corsair/swashbuckler", 44, "female", "a SWASHBUCKLER, a FEMALE pirate duellist in the game's figure-redesign style (an extremely "
     "exaggerated hourglass figure: a very full bust, a tiny cinched waist, very wide hips), glamorous, FACE CLEARLY VISIBLE, in a lunging "
     "duelling stance with a long thin rapier: a black feathered tricorn with a red plume, a long RED coat over a cream blouse, a dark "
     "corset belt, tight dark trousers and tall brown boots, a short dark cape. Chest and hips FULLY COVERED, never nude, tasteful. "
     "Signature shape: the hourglass figure, the plumed tricorn and the rapier.")
unit("corsair/grappler", 42, "male", "a GRAPPLER, a MALE pirate hauling a coil of rope and swinging a four-pronged iron grappling hook "
     "on a line over his head: a white-grey cap, a cream sleeveless shirt with bare arms, brown leather braces, dark trousers, boots. "
     "Signature shape: the swinging hook and the rope.")
unit("corsair/gunnery_mate", 42, "female", "a GUNNERY MATE, a FEMALE pirate artillerist in the game's figure-redesign style (an extremely "
     "exaggerated hourglass figure, a very full bust, a tiny waist, very wide hips), glamorous, FACE CLEARLY VISIBLE, holding up a round "
     "black grenado (a bomb) with a LIT amber fuse in one hand: a red bandana, a navy waistcoat laced over a cream blouse, a brown belt, "
     "dark trousers and boots. Chest and hips FULLY COVERED, never nude. Signature shape: the hourglass figure and the round bomb with its spark.")
unit("corsair/boatswain", 42, "male", "a BOATSWAIN, a MALE pirate officer with a broad chest bellowing orders, one hand to his open mouth "
     "and a small brass whistle on a chain: a dark navy cap, a cream shirt, a red neckerchief, a brown belt, dark trousers, boots. "
     "Signature shape: the big chest and the hand at the mouth.")
unit("corsair/voodoo_navigator", 44, "female", "a VOODOO NAVIGATOR, a FEMALE dark-skinned sea-witch navigator in the game's figure-redesign "
     "style (an extremely exaggerated hourglass figure, a very full bust, a tiny waist, very wide hips), glamorous and eerie, FACE CLEARLY "
     "VISIBLE, one hand raising a glowing AMBER sigil and the other holding a small bone charm: a red headwrap with a small bone, "
     "layered cream-and-brown wraps and a long cream skirt, brass jewellery. Chest and hips FULLY COVERED by the wraps, never nude. "
     "Signature shape: the hourglass figure, the headwrap and the glowing amber sigil.")
unit("corsair/boarding_bruiser", 56, "male", "a BOARDING BRUISER, a huge MALE pirate heavyweight, bald, bearded, enormous arms, gripping a "
     "big boarding axe: a bare chest with two crossed leather straps, leather bracers, a red sash, dark trousers, heavy boots. Signature "
     "shape: the wide barrel body and the big axe.", w=" and about 48 wide")
unit("corsair/reef_shark", 44, "creature, no sex", "a REEF SHARK, a creature, seen from above-front leaping out of the water with its "
     "toothy jaws open: powder-grey back and fin, a cream belly, red gums and white teeth, a small ring of white sea FOAM splashing at its "
     "base. Signature shape: the dorsal fin and the open toothy jaws.", ramps="powder,sail,foam,sea,sash", colours=PAL + "; foam white #8FB4D2 #D8E9F4 #F6FBFF", kind="creature", w=" and about 44 wide")
unit("corsair/hull_crab", 40, "creature, no sex", "a GIANT HULL CRAB, a creature, seen from above-front, a wide round barnacled shell, two huge "
     "claws raised, eight legs and two stalk eyes. COLOURFUL and SPECKLED, not grey: the shell is bright orange-red with many cream and pale-yellow speckles and "
     "dark red spots, the claws and legs a deeper red with cream tips, small cream barnacles on the shell, a pale cream underside, amber stalk eyes. "
     "NO grey anywhere. Signature shape: the wide speckled shell and the two huge raised claws.", ramps="sash,lantern,sail,brass,foam,sea,oak", kind="creature", w=" and about 56 wide")
unit("corsair/kraken_arm", 56, "creature, no sex", "a KRAKEN ARM, a creature: a single huge purple tentacle rising from a ring of white FOAM, "
     "curled at the tip, two rows of cream-pink suckers down its inner side. Signature shape: the tall curled tentacle with its suckers.",
     ramps="kraken,sail,foam,sea", colours="kraken purple #3A2150 #6B3C86 #A877BC; suckers cream #8F8466 #D6CBA4 #F0E9CE; foam white #8FB4D2 #D8E9F4 #F6FBFF; navy #0E1A33 #1B3560", kind="creature")
unit("corsair/sea_serpent", 52, "creature, no sex", "a SEA SERPENT, a creature: a long teal scaled serpent in an S-shaped coil rising from white "
     "FOAM, a spined crest and finned head with open jaws, amber eye, a cream belly stripe. Signature shape: the S-coil and the finned head.",
     ramps="serpent,sail,foam,sea,lantern", colours="serpent teal #134744 #26827E #66C3BA; belly cream #8F8466 #D6CBA4 #F0E9CE; foam white #8FB4D2 #D8E9F4 #F6FBFF; amber eye #F2A63A", kind="creature", w=" and about 50 wide")
# --- boats (seen mostly from above, bow to the RIGHT; the code rotates them to the rail) ---
BOATC = (PAL + "; foam white #8FB4D2 #D8E9F4 #F6FBFF")
unit("corsair/skiff", 30, "an object (a boat)", "a small SKIFF rowing boat seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), "
     "its pointed bow to the RIGHT, plain tarred-oak planks with lighter ribs, two oars sticking out, a coil of rope and a small amber lantern at the bow, "
     "a rim of white foam along its sides. Signature shape: the narrow pointed hull with the two oars.",
     ramps="oak,sail,brass,powder,sash,lantern,sea,foam", colours=BOATC, kind="boat", shape="wide", w=" (the beam) and about 70 wide")
unit("corsair/longboat", 38, "an object (a boat)", "a LONGBOAT seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT, "
     "tarred-oak planks, six oars along each side, a short mast stump with a furled cream sail, a red pennant and an amber lantern at the bow, "
     "white foam along its sides. Signature shape: the long hull with the many oars.",
     ramps="oak,sail,brass,powder,sash,lantern,sea,foam", colours=BOATC, kind="boat", shape="wide", w=" (the beam) and about 110 wide")
unit("corsair/raider_ship", 60, "an object (a boat)", "a RAIDER SHIP, a two-masted pirate sloop seen from nearly directly ABOVE (a plan view "
     "with a slight 3/4 tilt), bow to the RIGHT, tarred-oak deck and rails, two masts with furled cream sails, a black flag with a small white bird, "
     "a raised stern, two boarding planks lying along the rail, amber lanterns, white foam along its sides. Signature shape: the long hull with two masts.",
     ramps="oak,sail,brass,powder,sash,lantern,sea,foam", colours=BOATC, kind="boat", shape="wide", w=" (the beam) and about 150 wide")
unit("corsair/gunboat", 46, "an object (a boat)", "a GUNBOAT, a squat heavy gun barge seen from nearly directly ABOVE (a plan view with a slight "
     "3/4 tilt), bow to the RIGHT, grey-black iron-plated oak, three big brass-and-iron cannons pointing out of one side, a short mast with a "
     "red pennant, an amber lantern, white foam along its sides. Signature shape: the squat hull with the row of cannons.",
     ramps="oak,sail,brass,powder,sash,lantern,sea,foam", colours=BOATC, kind="boat", shape="wide", w=" (the beam) and about 80 wide")
unit("corsair/ram_longboat", 44, "an object (a boat)", "a RAM LONGBOAT, a heavy battering longboat seen from nearly directly ABOVE (a plan view "
     "with a slight 3/4 tilt), bow to the RIGHT with a big iron-capped ram of black wood and a brass ram-head, thick dark oak, rows of oars, "
     "a red banner, an amber lantern, white foam along its sides. Signature shape: the iron-capped ram at the bow.",
     ramps="oak,sail,brass,powder,sash,lantern,sea,foam", colours=BOATC, kind="boat", shape="wide", w=" (the beam) and about 100 wide")
unit("corsair/ghost_longboat", 38, "an object (a boat)", "a GHOST LONGBOAT seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), "
     "bow to the RIGHT, rotting grey-green planks, a ragged pale sail, glowing pale green-white lanterns, a faint pale green mist and foam along its sides. "
     "Signature shape: the long rotten hull with ragged sail.",
     ramps="spectre,oak,powder,sea,foam", colours="ghost green #1D4F4A #46A78F #B7F0DC; rotten oak #2B1D14 #4A3220 #7A5632; powder grey #2E3239 #5E636C #9498A0; navy #0E1A33 #1B3560; foam #8FB4D2 #D8E9F4",
     kind="boat", shape="wide", w=" (the beam) and about 110 wide")
unit("corsair/grapple_hook", 16, "an object", "a GRAPPLING HOOK: a four-pronged iron grapnel with a short length of cream rope tied to its ring, "
     "pointing right, hooked over a short piece of oak rail. Signature shape: the four curved prongs.",
     ramps="powder,oak,sail,brass,sea", kind="object", w=" and about 20 wide")
unit("corsair/boarding_plank", 16, "an object", "a BOARDING PLANK: a long, narrow wooden gangplank seen from above lying horizontally, "
     "tarred oak with cross cleats and rope handrails on both edges, iron-shod ends. Signature shape: the long narrow plank with its cleats.",
     ramps="oak,sail,powder,brass,sea", kind="object", shape="wide", w=" (the width) and about 64 long")
# --- minibosses and bosses ---
unit("corsair/bosun_gorran", 64, "male", "BOSUN GORRAN, a MALE miniboss pirate bosun, enormous, broad and scarred, bellowing, one fist raised "
     "and the other holding a big ship's iron chain-hook: a black bicorne hat with a brass badge, a long dark navy greatcoat open over a bare "
     "chest, a thick red sash, a brass whistle on a chain, big black boots, a grey-streaked beard. Signature shape: the huge frame and the black bicorne.",
     w=" and about 56 wide")
unit("corsair/old_hollow_eye", 72, "creature, no sex", "OLD HOLLOW-EYE, a miniboss creature: a gigantic KRAKEN, a WHOLE OCTOPUS-like monster seen from above-front, "
     "a big bulbous purple head-mantle covered in barnacles and old harpoon scars, ONE pale blind HOLLOW EYE socket (a single huge cloudy white eye) in the middle of its head, and "
     "eight thick tentacles spreading out and curling around it with two rows of cream suckers, all rising from a ring of white FOAM. Signature shape: the big scarred head "
     "with the single hollow eye and the spread of curling tentacles.",
     ramps="kraken,sail,foam,sea,sash", colours="kraken purple #3A2150 #6B3C86 #A877BC; cream #8F8466 #D6CBA4 #F0E9CE; foam white #8FB4D2 #D8E9F4 #F6FBFF; navy #0E1A33 #1B3560", kind="creature", w=" and about 76 wide")
unit("corsair/ghost_bosun", 48, "male", "THE GHOST BOSUN, a MALE spectral miniboss: a translucent-looking drowned bosun, hollow glowing eyes, "
     "raising a small whistle to his lips, a tattered cap and a ragged coat, dripping with seaweed and pale green mist, pale green-white spectral glow. "
     "Signature shape: the ragged coat and the whistle at the lips.",
     ramps="spectre,sea,powder,oak", colours="ghost green #1D4F4A #46A78F #B7F0DC; navy #0E1A33 #1B3560 #2F5F96; powder grey #2E3239 #5E636C; rotten oak #2B1D14 #4A3220", w=" and about 42 wide")
unit("corsair/crow", 88, "male", "CAPTAIN EZEKIEL CROW, THE GULL KING, a lean MALE pirate captain boss, a cutlass in one hand and a flintlock "
     "pistol raised in the other, a heavy cloak of WHITE GULL FEATHERS over a black coat with brass buttons, a black tricorn with a gull feather, a "
     "red sash, dark trousers, boots, a short dark beard. Signature shape: the feather cloak and the tricorn.",
     colours=PAL + "; gull feather white #8FB4D2 #D8E9F4 #F6FBFF", ramps=HUM + ",foam", w=" and about 80 wide")
unit("corsair/marrec", 92, "female", "ADMIRAL ISABEAU MARREC, THE SEA WOLF, a FEMALE admiral boss in the game's figure-redesign style (an "
     "extremely exaggerated hourglass figure, a very full bust, a tiny cinched waist, very wide hips), glamorous and commanding, FACE CLEARLY VISIBLE, long "
     "brown hair, holding a curved sabre aloft: a navy tricorn with gold trim, a long NAVY COAT with gold epaulettes and gold buttons over a cream "
     "blouse, a brass-buckled belt, tight dark trousers and tall black boots. Chest and hips FULLY COVERED, never nude, tasteful. Signature shape: "
     "the hourglass figure, the gold-trimmed navy coat and the sabre.", w=" and about 70 wide")
unit("corsair/vandermere", 96, "male", "CAPTAIN CORNELIUS VANDERMERE, a ghostly MALE captain boss lashed to a ship's wheel: he stands gripping a big "
     "wooden ship's WHEEL in front of him (rope lashes wound round his arms), a long torn coat and a drooping tricorn, a long ragged beard, "
     "hollow glowing eyes, barnacles on his shoulders, pale green-white spectral glow. Signature shape: the big wheel and the drooping tricorn.",
     ramps="spectre,sea,powder,oak,sail", colours="ghost green #1D4F4A #46A78F #B7F0DC; rotten oak #2B1D14 #4A3220 #7A5632; navy #0E1A33 #1B3560 #2F5F96; powder grey #2E3239 #5E636C #9498A0; cream #8F8466 #D6CBA4", w=" and about 80 wide")
# --- the three playable characters (player/) and the summons (summons/) ---
CHAR_COL = "violet #4A2569 #7A42AD #A35CFA (the dominant colour); bone white #7F785F #B4AA8A #E8E1C8; soul teal glow #1C6B58 #3DCC94 #A8FFD2; pale undead-touched skin #8A8796 #B4B0BE #DAD6E2; brown wood #4F3320 #8C6040; dark #160A21"
CHAR_RAMPS = "violet,bone,grey,soul,brown,arcane"
unit("player/marooned_quartermaster", 56, "male", "THE MAROONED QUARTERMASTER, a MALE playable NECROMANCER of the Black Tide (a necromancer first: the dominant colour is VIOLET), a lean "
     "pale undead-touched castaway ship's quartermaster, a short beard, a torn long VIOLET quartermaster's coat with a high collar and bone-white buttons, a "
     "bone-white peg leg on one side, a worn violet tricorn, a rusted shackle on one wrist, holding a tall staff topped with a glowing soul-teal ship's lantern as his "
     "casting focus. He stands upright and compact (about 44 pixels wide at most, no sprawling arms). Signature shape: the violet coat, the tricorn and the tall lantern staff.",
     ramps=CHAR_RAMPS, colours=CHAR_COL, w=" and at most 46 wide", ink="0.2")
unit("player/corsair_queen", 56, "female", "THE CORSAIR QUEEN, a FEMALE playable NECROMANCER of the Black Tide (a necromancer first: the dominant colour is VIOLET) in the game's "
     "figure-redesign style (an extremely exaggerated hourglass figure, a very full bust, a tiny cinched waist, very wide hips), glamorous and regal, pale "
     "undead-touched skin, FACE CLEARLY VISIBLE, long dark hair under a VIOLET tricorn with a bone-white plume, a long fitted VIOLET captain's coat with bone-white "
     "trim and a violet skirt-length tail, a high collar, tall boots, holding a slim bone-white cutlass raised upright whose blade glows soul-teal as her casting focus. "
     "Chest and hips FULLY COVERED, never nude, tasteful. She stands compact (about 44 pixels wide at most, no sprawling arms). Signature shape: the hourglass figure, the plumed tricorn and the long coat.",
     ramps=CHAR_RAMPS, colours=CHAR_COL, w=" and at most 46 wide", ink="0.2")
unit("player/ghost_helmsman", 56, "male", "THE GHOST HELMSMAN, a MALE playable NECROMANCER of the Black Tide (a necromancer first: the dominant colour is VIOLET), a broad "
     "spectral drowned ship's helmsman in a long hooded VIOLET oilskin coat with bone-white rope trim, a grey beard, pale undead-touched face with glowing soul-teal eyes, "
     "holding up a small ship's-wheel-topped staff with a glowing soul-teal lantern as his casting focus, a bone-white anchor charm at his belt. He stands upright and "
     "compact (about 44 pixels wide at most). Signature shape: the hooded violet oilskin and the wheel-topped lantern staff.",
     ramps=CHAR_RAMPS, colours=CHAR_COL, w=" and at most 46 wide", ink="0.2")
unit("summons/powder_wraith", 44, "undead skeleton, no sex", "a POWDER WRAITH, an undead SKELETON (a summoned ally) marching forward carrying a lit powder keg "
     "on its shoulder with a short fuse spitting an amber spark, bone-white bones with dark eye sockets, a tattered red sash and a torn black "
     "pirate bandana. Signature shape: the skeleton with the keg and the amber spark.",
     ramps="bone,grey,sash,lantern,oak,brass", colours="bone #8A8070 #C8BC9C #EDE6D0; grey #3A3F4C #5A6070; sash red #6A1620 #B02A30 #E2563F; oak #2B1D14 #4A3220 #7A5632; lantern amber #B0661C #F2A63A #FFDF8A; brass #7A5A1C #C4912A", ref="powder_runner", w=" and about 36 wide")
unit("summons/magazine_lord", 52, "undead skeleton, no sex", "a MAGAZINE LORD, a large armoured undead SKELETON (a summoned ally, the evolved Powder Wraith) "
     "wearing a captain's dark coat and a tricorn with a burning fuse for a plume, bandoleers of small powder kegs and bombs across its chest, a "
     "big stack of three lit kegs on its back with amber fuses, bone-white bones with glowing amber eye sockets. Signature shape: the tower of kegs "
     "and the burning fuse plume.",
     ramps="bone,grey,sash,lantern,oak,brass", colours="bone #8A8070 #C8BC9C #EDE6D0; grey #3A3F4C #5A6070; sash red #6A1620 #B02A30 #E2563F; oak #2B1D14 #4A3220 #7A5632; lantern amber #B0661C #F2A63A #FFDF8A; brass #7A5A1C #C4912A", ref="boarding_bruiser", w=" and about 46 wide")


REF = {"corsair/bosun_gorran": "boatswain", "corsair/ghost_bosun": "boatswain", "player/marooned_quartermaster": "deckhand",
       "player/corsair_queen": "marrec", "player/ghost_helmsman": "vandermere", "corsair/old_hollow_eye": "kraken_arm"}
for _k, _v in REF.items():
    U[_k]["ref"] = _v


# Units converted WITH the level stretch (their AI renders were too dark and sank into the floors).
LEVELS = ["corsair/ghost_bosun", "summons/powder_wraith", "summons/magazine_lord"]


def prompt_for(key: str) -> str:
    """The prompt text of unit `key`."""
    u = U[key]
    kind = u["kind"]
    sexline = {"figure": "", "creature": "", "boat": "", "object": ""}[kind]
    p = HEAD + {"figure": "a confident pose", "creature": "a menacing pose", "boat": "no crew", "object": "no one holding it"}[kind]
    if kind == "boat":
        p = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). A boat seen from nearly directly ABOVE "
             "(plan view with a slight 3/4 tilt), BOW POINTING RIGHT, no crew, ")
    p += LOWRES.format(h=u["h"], w=u["w"])
    p += "Subject (%s): %s\n\nColours: ONLY flat fills from this list, at most 3 shades per material: %s%s" % (u["sex"], u["subject"], u["colours"], sexline)
    shape = "wide (3:2)" if u["shape"] == "wide" else "square"
    fill = "WIDTH" if u["shape"] == "wide" else "height"
    ref = u["ref"]
    male = u["sex"].startswith("male") or "undead" in u["sex"]
    att = ("(1) a game sprite for pixel size, outline weight and flat look (not its subject or colours); (2) concept art of this unit "
           "for its shape and colours only (do NOT copy its painted shading or detail level; redraw it as chunky low-resolution pixel art).")
    p += TAIL.format(shape=shape, fill=fill, att=att)
    return p


def refs_for(key: str) -> list:
    """Reference images of unit `key`: a game sprite, then the concept crop when one exists."""
    u = U[key]
    if key.startswith("player/"):
        return [REFS / "sprite_necro.png", REFS / ("sprite_necro_f.png" if U[key]["sex"] == "female" else "sprite_necro_f2.png")]
    r = []
    r.append(REFS / ("sprite_female.png" if u["sex"].startswith("female") else "sprite_skeleton.png" if "undead" in u["sex"] else "sprite_male.png"))
    c = REFS / ("concept_%s.png" % u["ref"])
    if u["kind"] in ("boat", "object"):
        r = [REFS / "concept_stage.png"]
    elif c.exists():
        r.append(c)
    if key.startswith("player/") or key.startswith("summons/magazine"):
        pass
    return r


def gen_one(key: str) -> None:
    """Generates unit `key`'s raw image (skipped when it exists)."""
    out = RAW / (key.replace("/", "_") + ".png")
    if out.exists():
        return
    PROMPTS.mkdir(exist_ok=True)
    pf = PROMPTS / (key.replace("/", "_") + ".txt")
    pf.write_text(prompt_for(key))
    u = U[key]
    cmd = [sys.executable, "tools/gen_image.py", str(pf), str(out), "--key", "corsair/" + key, "--size", "1536x1024" if u["shape"] == "wide" else "1024x1024"]
    for r in refs_for(key):
        cmd += ["--ref", str(r)]
    for attempt in range(2):
        try:
            subprocess.run(cmd, cwd=ROOT, check=True)
            return
        except subprocess.CalledProcessError:
            print("retry", key)
    print("FAILED", key)


def gen(keys: list) -> None:
    keys = keys or list(U)
    RAW.mkdir(exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as ex:
        list(ex.map(gen_one, keys))


def run(args: list) -> None:
    print("+", " ".join(args))
    subprocess.run([sys.executable] + args, cwd=ROOT, check=True)


def convert(keys: list) -> None:
    from PIL import Image
    work = HERE / "_work"
    work.mkdir(exist_ok=True)
    for key in keys or list(U):
        u = U[key]
        raw = RAW / (key.replace("/", "_") + ".png")
        if not raw.exists():
            print("missing", raw)
            continue
        keep = raw.read_bytes()
        pix = work / (key.replace("/", "_") + ".png")
        run(["tools/pixelate_source.py", str(raw), str(u["h"]), str(pix)])
        run(["tools/prepare_sprite.py", str(pix), key, "--ink-l", u["ink"], "--no-cleanup"] + ([] if key in LEVELS else ["--no-levels"]) + ["--no-prune", "--art-height", str(u["h"]), "--ramps", u["ramps"]] + u["extra"])
        raw.write_bytes(keep)



# --- sheets: the deck furniture and the icons (one API image each, cut apart by transparent gaps) ---
SHEET_HEAD = ("A sheet of {n} separate pixel-art game {what} in one row, evenly spaced with wide empty gaps between them, on a FULLY TRANSPARENT "
              "background (real alpha). Each is simple, bold and centred in its share of the image, drawn as chunky low-resolution pixel art "
              "(shown enlarged with crisp square pixels, nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light "
              "from the top-left). No frame, no badge background, no ground shadow, no text, no letters.\nFrom left to right:\n")
PIRATE_COLOURS = ("Colours: tarred oak #2B1D14 #4A3220 #7A5632; brass #7A5A1C #C4912A #EBC85A; powder grey #2E3239 #5E636C #9498A0; sailcloth cream "
                  "#8F8466 #D6CBA4 #F0E9CE; sash red #6A1620 #B02A30 #E2563F; lantern amber #B0661C #F2A63A #FFDF8A; navy #0E1A33 #1B3560 #2F5F96; "
                  "foam white #8FB4D2 #D8E9F4; ghost green #1D4F4A #46A78F #B7F0DC; dark #0B0A10.")
OBSTACLES = ["a ship's MAST seen from above: a thick round tarred-oak mast stub with a brass-banded base, ropes coiled round it and a furled cream sail bundle on top (a round object, about 36 px across)",
             "a ship's HATCH cover seen from above: a rectangular wooden grating hatch with iron corner brackets and a rope handle (a rectangle about 44 x 30 px)",
             "a small cluster of two POWDER BARRELS seen from above, tarred oak with iron bands, one with a red stripe (about 28 px across)",
             "a big stack of four POWDER BARRELS lashed together with rope seen from above, iron bands, a spilled bit of black powder (about 38 px across)",
             "a DECK CANNON on a wooden carriage seen from above, pointing right, a black iron barrel with a brass muzzle ring and brass wheels (a rectangle about 40 x 22 px)"]
OBSTACLE_KEYS = [("obstacles/deck_mast_l", 36, "oak,brass,sail,powder,sea"), ("obstacles/deck_hatch_l", 44, "oak,powder,brass,sea"),
                 ("obstacles/deck_barrels_s", 28, "oak,powder,sash,brass,sea"), ("obstacles/deck_barrels_l", 38, "oak,powder,sash,brass,sea"),
                 ("obstacles/deck_cannon_l", 40, "powder,brass,oak,sea")]
VERTICAL = ["obstacles/deck_hatch_l", "obstacles/deck_cannon_l"]  # Rect kinds whose vertical sprite (_v) is the horizontal one turned 90 degrees.
# Icon sheets: file -> (frame icon, [(id, description)]). violet frame = icons/abyssal_pact, gold frame = icons/tidecallers_host.
ICONSETS = {
    "icons_a": ("icons/abyssal_pact", [
        ("chain_shot", "CHAIN SHOT: two spiked iron balls joined by a short chain, spinning, trailing pale green spectral light"),
        ("cannonade", "CANNONADE: three black cannonballs falling with amber fire trails and a brass cannon muzzle flash below"),
        ("anchor_drop", "ANCHOR DROP: a big rusted iron anchor plunging down, pale green spectral glow, a shock ring on the ground"),
        ("powder_wraith", "POWDER WRAITH: a bone-white skull wearing a torn red bandana with a lit powder keg fuse sparking amber beside it")]),
    "icons_b": ("icons/tidecallers_host", [
        ("keelhauler", "KEELHAULER: a long barnacled chain with a heavy hook swinging through a ring of white foam, pale green glow"),
        ("dead_mens_broadside", "DEAD MEN'S BROADSIDE: a row of five ghostly cannonballs in a fan, amber and pale green fire"),
        ("abyssal_mooring", "ABYSSAL MOORING: a huge anchor with a chain wound round it sinking into dark whirlpool water, pale green glow"),
        ("magazine_lord", "MAGAZINE LORD: a tower of three powder kegs with burning amber fuses under a black tricorn hat")]),
    "icons_c": ("icons/abyssal_pact", [
        ("bosuns_whistle", "BOSUN'S WHISTLE: a brass bosun's whistle on a chain with three small sound waves"),
        ("black_powder", "BLACK POWDER: an open powder horn spilling black grains and an amber spark"),
        ("dead_reckoning", "DEAD RECKONING: a brass compass with a skull on its face and a pale green needle"),
        ("sea_legs", "SEA LEGS: a sturdy brown sea boot planted on a tilted wooden deck, foam at the edge")]),
    "icons_d": ("icons/tidecallers_host", [
        ("barnacle_bones", "BARNACLE BONES: a bone-white ribcage encrusted with grey-white barnacles and a bit of seaweed"),
        ("ach_not_one_aboard", "NOT ONE ABOARD: a small rowboat with a grapple rope cut, a cutlass slashing the rope"),
        ("ach_walked_the_plank", "WALKED THE PLANK: a wooden plank over foam water with a splash at its end"),
        ("ach_dead_men_tell_tales", "DEAD MEN TELL TALES: a pale green ghost skull wearing a tricorn, a rolled scroll beside it")]),
}


def gen_sheets(keys: list) -> None:
    PROMPTS.mkdir(exist_ok=True)
    RAW.mkdir(exist_ok=True)
    jobs = {"obstacles": SHEET_HEAD.format(n=5, what="DECK FURNITURE PIECES (top-down game obstacles)") + "\n".join(
        "%d. %s" % (i + 1, d) for i, d in enumerate(OBSTACLES)) + "\n" + PIRATE_COLOURS}
    for name, (frame, items) in ICONSETS.items():
        jobs[name] = SHEET_HEAD.format(n=4, what="ICON SYMBOLS (each about 24 pixels wide on a coarse grid)") + "\n".join(
            "%d. %s" % (i + 1, d) for i, (_, d) in enumerate(items)) + "\n" + PIRATE_COLOURS + (
            "\nAttached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame).")
    for name, text in jobs.items():
        if keys and name not in keys:
            continue
        out = RAW / (name + ".png")
        if out.exists():
            continue
        pf = PROMPTS / (name + ".txt")
        pf.write_text(text)
        cmd = [sys.executable, "tools/gen_image.py", str(pf), str(out), "--key", "corsair/" + name, "--size", "1536x1024"]
        if name != "obstacles":
            cmd += ["--ref", str(ROOT / "assets/sprites/icons/bone_spear.png")]
        subprocess.run(cmd, cwd=ROOT, check=True)


def islands(im, axis: int, min_gap: int = 12) -> list:
    """Spans [a, b) of opaque columns (axis 0) or rows (axis 1) separated by >= min_gap empty ones."""
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    w, h = a.size
    occ = []
    for i in range(w if axis == 0 else h):
        box = (i, 0, i + 1, h) if axis == 0 else (0, i, w, i + 1)
        occ.append(a.crop(box).getbbox() is not None)
    spans, start, gap = [], None, 0
    for i, o in enumerate(occ):
        if o:
            if start is None:
                start = i
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                spans.append((start, i - gap + 1))
                start, gap = None, 0
    if start is not None:
        spans.append((start, len(occ)))
    return spans


def crop_tight(im):
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    return im.crop(a.getbbox())


def cut_sheets(keys: list) -> None:
    """Cuts the obstacle sheet and each icon sheet apart and converts the pieces (icons set on an approved frame)."""
    from PIL import Image
    work = HERE / "_work"
    work.mkdir(exist_ok=True)
    im = Image.open(RAW / "obstacles.png").convert("RGBA")
    spans = islands(im, 0, 8)
    print("obstacle spans", len(spans))
    for (x0, x1), (key, width, ramps) in zip(spans, OBSTACLE_KEYS):
        part = crop_tight(im.crop((x0, 0, x1, im.height)))
        height = max(6, round(width * part.height / part.width))
        pth = work / (key.replace("/", "_") + ".png")
        part.save(pth)
        run(["tools/prepare_sprite.py", str(pth), key, "--art-height", str(height), "--ink-l", "0.15", "--ramps", ramps])
        if key in VERTICAL:
            out = ROOT / "assets/sprites" / (key + ".png")
            Image.open(out).convert("RGBA").rotate(90, expand=True).save(ROOT / "assets/sprites" / (key + "_v.png"))
    for name, (frame_key, items) in ICONSETS.items():
        sheet = Image.open(RAW / (name + ".png")).convert("RGBA")
        spans = islands(sheet, 0, 10)
        print(name, "spans", len(spans))
        for (x0, x1), (sid, _) in zip(spans, items):
            sym = crop_tight(sheet.crop((x0, 0, x1, sheet.height)))
            p = work / (sid + ".png")
            sym.save(p)
            out = work / (sid + "_24.png")
            run(["tools/prepare_sprite.py", str(p), "icons/" + sid, "--art-height", "24", "--ink-l", "0.2", "--out", str(out),
                 "--ramps", "oak,sail,brass,powder,sash,lantern,sea,foam,spectre,bone,steel,brown"])
            frame = Image.open(ROOT / "assets/sprites" / (frame_key + ".png")).convert("RGBA")
            fill = frame.getpixel((4, 16))
            for y in range(3, 29):
                for x in range(3, 29):
                    frame.putpixel((x, y), fill)
            s = Image.open(out).convert("RGBA")
            if s.width > 26:
                s = s.resize((26, round(s.height * 26 / s.width)), Image.NEAREST)
            frame.alpha_composite(s, ((32 - s.width) // 2, (32 - s.height) // 2))
            frame.save(ROOT / "assets/sprites/icons" / (sid + ".png"))


# Hovering stills (hover rigs: the bob moves the whole sprite): PAD empty rows are added above and below each.
HOVER = ["corsair/vandermere", "corsair/reef_shark", "corsair/hull_crab", "corsair/kraken_arm", "corsair/old_hollow_eye", "corsair/sea_serpent",
         "corsair/skiff", "corsair/longboat", "corsair/raider_ship", "corsair/gunboat", "corsair/ram_longboat", "corsair/ghost_longboat"]
PAD = 2  # Empty rows above and below a hovering still.
# Figures with a bust rig (a 24-frame idle breathing strip each).
IDLES = ["corsair/swashbuckler", "corsair/gunnery_mate", "corsair/voodoo_navigator", "corsair/marrec", "player/corsair_queen"]
# Units without a strip (the hook and the plank are drawn as they are).
NO_STRIP = ["corsair/grapple_hook", "corsair/boarding_plank"]


def pad(key: str) -> None:
    """Adds PAD transparent rows above and below the still `key` (once: a still already padded is left alone)."""
    from PIL import Image
    p = ROOT / "assets/sprites" / (key + ".png")
    im = Image.open(p).convert("RGBA")
    top = im.crop((0, 0, im.width, PAD)).getbbox()
    bottom = im.crop((0, im.height - PAD, im.width, im.height)).getbbox()
    if top is None and bottom is None:
        return
    out = Image.new("RGBA", (im.width, im.height + PAD * 2), (0, 0, 0, 0))
    out.alpha_composite(im, (0, PAD))
    out.save(p)


# Round 1 (owner's marks): tentacles that wave in the air. Each still (padded) is sheared row by row: shift = A * ((h - 1 - y) / (h - 1)) ** 1.3
# * sin(2 pi f / 8 + y * 0.1) px, so the foam at the base stays put and the tips sweep; a row never loses a pixel off the canvas.
WAVE = {"corsair/kraken_arm": 3.0, "corsair/old_hollow_eye": 2.0}
# The Powder Wraith's fuse flash: (tip x, tip y) of the spark in the still, drawn in the lantern colours on these frames of its walk strip.
FLASH = {"summons/powder_wraith": ((33, 9), (1, 2, 5, 6))}


def wave_strip(key: str) -> None:
    """Writes <key>_walk.png: 8 frames of the padded still with the tentacles waving (frame 0 = the still)."""
    import math
    import numpy as np
    from PIL import Image
    still = np.array(Image.open(ROOT / "assets/sprites" / (key + ".png")).convert("RGBA"))
    h, w = still.shape[:2]
    amp = WAVE[key]
    frames = []
    for f in range(8):
        out = np.zeros_like(still)
        for y in range(h):
            row = still[y]
            xs = np.nonzero(row[:, 3])[0]
            if len(xs) == 0:
                continue
            a = amp * ((h - 1 - y) / (h - 1)) ** 1.3
            d = int(round(a * math.sin(2 * math.pi * f / 8 + y * 0.1))) if f else 0
            d = max(-int(xs.min()), min(d, w - 1 - int(xs.max())))  # Never push a pixel off the canvas.
            out[y] = np.roll(row, d, axis=0)
        frames.append(out)
    Image.fromarray(np.concatenate(frames, axis=1)).save(ROOT / "assets/sprites" / (key + "_walk.png"))


def flash_strip(key: str) -> None:
    """Adds the small fuse flash (a plus of lantern pixels where the frame is empty) to the walk strip of `key`."""
    from PIL import Image
    pal = {"c": (0xFF, 0xDF, 0x8A, 255), "m": (0xF2, 0xA6, 0x3A, 255)}
    p = ROOT / "assets/sprites" / (key + "_walk.png")
    im = Image.open(p).convert("RGBA")
    (tx, ty), frames = FLASH[key]
    fw = im.height if False else Image.open(ROOT / "assets/sprites" / (key + ".png")).width
    px = im.load()
    for f in frames:
        for dx, dy, c in ((0, 0, "c"), (-1, 0, "m"), (1, 0, "m"), (0, -1, "m"), (0, 1, "m"), (-2, 0, "m"), (2, -2, "m")):
            x, y = tx + dx, ty + dy
            if 0 <= x < fw and 0 <= y < im.height and px[f * fw + x, y][3] == 0:
                px[f * fw + x, y] = pal[c]
    im.save(p)


def strips(keys: list) -> None:
    for key in HOVER:
        pad(key)
    ks = [k for k in U if k not in NO_STRIP and k not in WAVE]
    run(["tools/walk_cycle.py", "build"] + ks)
    for k in WAVE:
        wave_strip(k)
    for k in FLASH:
        flash_strip(k)
    run(["tools/walk_cycle.py", "idle"] + IDLES)


if __name__ == "__main__":
    step = sys.argv[1]
    keys = sys.argv[2:]
    {"gen": gen, "convert": convert, "strips": strips, "gen_sheets": gen_sheets, "sheets": cut_sheets}.get(step, lambda k: None)(keys)
