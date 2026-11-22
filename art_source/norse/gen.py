"""gen.py: prompts and API generation for the Hall of the Slain sprites (Act VI art; GDD 15.0 "Hall of the Slain art and audio").

Usage (repo root): python3 art_source/norse/gen.py <key> [<key> ...]   writes art_source/norse/<key>.txt and <key>.png
Each key's spec: (art height px, concept crop key or None, subject text). Refs: a Concord game sprite (pixel look) + the crop.
"""
import subprocess, sys, os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SCR = Path(os.environ.get("NORSE_SCRATCH", "/tmp/claude-0/-home-user/9462c562-c5ac-539a-9c62-d10b49b002f0/scratchpad/n"))
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter top-down view (camera above and "
        "slightly in front), FULL BODY, FACING RIGHT{pose}\n\nLOW-RESOLUTION pixel art: the whole figure is only {h} pixels tall, drawn on a coarse "
        "pixel grid and shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable shapes; no detail "
        "smaller than 2 pixels except the eyes and small glints. No anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze, no fine "
        "trims, lacing or engravings.\n\nSubject: {subject}\n\n")
TAIL = ("Colours: ONLY flat fills, at most 3 shades per material, from this Norse palette: frost white #EAF2FA #A9BBCC; iron grey #2B3139 #5B6570 #8F99A3; "
        "pine green-black #12281F #1F4A3A; leather and wood brown #5A3A24 #8C6040; skin #E0A882; hearth amber #F0902E; valkyrie pale gold #B08A3C #F5D77A; ice-blue rune glow "
        "#3F72C4 #8FD0FF; undead blue-grey #34495A #6C8CA0 #A6C0CE. Never violet or purple, never bone-white skulls, never teal-green soul fire (those are the player's).\n\n"
        "Outline: a clean 1-pixel dark outline around the whole subject in the darkest shade of each part's own colour (never pure black). Light from the top-left. "
        "Keep the main shapes clearly brighter than a near-black ground (#161A1C).\n\n"
        "Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white, no dark glow around the subject), one subject only, "
        "centred, filling about 85% of the image height. No ground, no cast shadow, no scenery, no text, no frame, no watermark. Draw ONLY ONE subject.\n"
        "Attached: (1) a game sprite for pixel size, outline weight and flat look; (2) concept art of this unit for the costume only (do NOT copy its detail level or painted shading).")
FEM = " Exaggerated hourglass figure (wide hips, narrow waist, full bust), glamorous, fully clothed: chest and hips always covered by opaque cloth or armour, never nude."
SPECS = {
 "raider": (40, "raider", "A MALE NORSE RAIDER (fodder), a broad bearded man in a plain iron helm with a nose guard, fur-trimmed green-black tunic, a round wooden shield with an iron boss on one arm and a single-bit axe in the other hand. Not a woman.", ", mid-charge, axe raised"),
 "shield_maiden": (44, "shield_maiden", "A FEMALE NORSE SHIELD-MAIDEN (soldier), blonde braided hair, a green tunic with fur trim and leather bracers, a round shield on one arm and a spear in the other hand." + FEM, ", advancing, spear levelled"),
 "berserker": (50, "berserker", "A MALE NORSE BERSERKER (elite), a huge muscular man wearing a bear pelt with the bear's head as a hood, glowing RED eyes under the hood, bare scarred arms, two hand axes, hunched in a frenzy. Not a woman.", ", charging, two axes out"),
 "skald": (44, "skald", "A MALE NORSE SKALD (support), a bearded man in a fur-collared green cloak holding a curved war-horn to his lips with one hand and a small lyre in the other, singing. Not a woman.", ", standing"),
 "valkyrie": (52, "valkyrie", "A FEMALE VALKYRIE (flying elite): a woman in white-and-pale-gold plate armour with a winged helm, great white-gold feathered wings spread wide, flying with legs trailing, holding a long gold-tipped spear." + FEM + " Armour covers her chest and hips fully.", ", flying, seen from slightly above"),
 "draugr": (42, "draugr", "A MALE DRAUGR (barrow-dead soldier): a gaunt blue-grey undead man in rusted iron mail and a dented helm, glowing pale ice-blue eyes, frost on his shoulders, a notched sword and a cracked round shield. Not a skeleton.", ", shambling forward"),
 "draugr_female": (42, "draugr", "A FEMALE DRAUGR (barrow-dead soldier): a gaunt blue-grey undead woman with long tangled dark hair, in rusted iron mail and a long ragged skirt, glowing pale ice-blue eyes, frost on her shoulders, a notched axe." + FEM + " Not a skeleton.", ", shambling forward"),
 "wolf_of_the_wastes": (26, "wolf", "A GREY WOLF (creature) of the wastes, lean, shaggy iron-grey fur with frost-white chest, glowing ice-blue eyes, mouth open, lunging, long body about 44 pixels long.", ", side view, lunging"),
 "frost_giant": (72, "frost_giant", "A HUGE MALE FROST GIANT: pale blue-white skin, long white beard, glowing ice-blue eyes, icicles on his fur kilt and wrists, carrying a huge grey boulder on one shoulder, hulking and hunched. Not a woman.", ", heavy stride"),
 "seer": (46, "seer", "A FEMALE NORSE SEER (volva): a woman in a long dark-green hooded cloak with cream fur trim, a carved wooden staff in one hand and a glowing ice-blue rune floating above her other palm." + FEM + " The long cloak covers her fully.", ", standing, casting"),
 "rune_stone": (40, "rune_stone", "A tall carved standing RUNE-STONE (a structure, not a creature), rough iron-grey stone slab with a little snow on top and at its base, glowing ice-blue runes carved down its face, three small stones at the foot. Upright, front view.", ", standing"),
 "rune_stone_taken": (40, "rune_stone", "The same tall carved standing RUNE-STONE but TAKEN by the undead: the runes are dark and dead (no glow), cracked stone, a few cold pale-bone-free cracks, snow; a small amber hearth glint is gone. Dull and inert. Upright, front view.", ", standing"),
 "einherjar": (46, "raider", "A MALE EINHERJAR (a chosen hero of the hall, elite): a bearded warrior in polished iron mail, a helm with a gold crest, a round shield with gold rim and a sword, his whole body lit with pale valkyrie gold light and gold trim, calm, resolute. Not a woman.", ", advancing"),
 "barrow_wight": (56, "draugr", "A MALE BARROW-WIGHT (miniboss, a draugr chieftain): a tall gaunt blue-grey undead jarl in rusted horned-helm and heavy mail, a rotten fur cloak, glowing ice-blue eyes and a gaping howling mouth, a huge two-handed rusted axe, frost clouds on him. Not a skeleton.", ", advancing"),
 "einherjar_champion": (60, "raider", "A MALE EINHERJAR CHAMPION (miniboss): a huge bearded hero in heavy gold-trimmed iron plate, a winged-crest helm, a great tower shield with a gold boss and a long bearded axe, bright pale-gold glow on his armour, a thousand years a warrior. Not a woman.", ", advancing"),
 "fire_giant": (80, "frost_giant", "A HUGE MALE FIRE-GIANT OF THE SOUTH (miniboss): black-iron skinned giant with cracks of glowing amber-orange fire across his body, a burning beard and hair, ember-red eyes, a huge sword of molten iron dragging, hulking. Not a woman.", ", heavy stride"),
 "hrimgar": (88, "hrimgar", "HRIMGAR THE DRAUGR-KING (boss, male): a tall gaunt undead king, a skull-like face with ice-blue eyes under a rusted iron crown, rusted barrow mail and a fur-trimmed shoulder mantle in brown, long bony hands, a huge notched greatsword held low, frost mist at his feet. Not a woman.", ", rising, menacing"),
 "sigrun": (80, "sigrun", "SIGRUN THE SHIELD-QUEEN (boss, female valkyrie captain): a woman in silver plate with blue-and-gold tabard, a winged helm, great white-gold wings, a large round blue shield with a gold eagle emblem, a long spear." + FEM + " Armour covers chest and hips fully.", ", striding forward"),
 "odin": (72, "odin", "ODIN THE ALL-FATHER (boss, male): an old one-eyed god, a black EYEPATCH over the left eye, a long grey beard, a dark hooded iron-blue cloak with fur collar (hood up, a wide dark hat brim is NOT used: no wizard hat), iron-banded leather armour, a long golden-tipped spear (Gungnir), a raven on each shoulder. Not a wizard: a grim war-god. Male.", ", standing, imposing"),
 "fenrir": (80, "fenrir", "FENRIR (boss creature): a gigantic black wolf, long body about 120 pixels long, thick black-iron fur, burning yellow eyes, bared fangs, a broken heavy iron chain hanging from his neck, prowling.", ", side view, prowling"),
 "raven": (18, None, "A black RAVEN (creature) with a yellow eye, wings half open, perched forward-leaning.", ", side view"),
 "boss_barrow": (56, "hrimgar", "A BURIAL MOUND BARROW (structure) of dark earth and frozen turf with a dark stone-lintel doorway, standing grave-stones around it, pale ice-blue frost mist leaking from the door, snow patches. Top-down 3/4 view, a rounded mound about 70 pixels wide.", ", front view"),
 "boss_barrow_broken": (56, "hrimgar", "A BROKEN BURIAL MOUND BARROW (structure): the mound is caved in, split stones and scattered rubble, the doorway collapsed, no mist, dull and dead, snow patches. Top-down 3/4 view, about 70 pixels wide.", ", front view"),
 "rune_seer": (56, "seer", "THE RUNE-SEER (a playable heroine, FEMALE necromancy-allied seer): a woman in a long dark-green hooded cloak with cream fur, hair braids, a rune staff, glowing ice-blue rune carved on her palm and pendant, a hint of ice-blue frost on the hem." + FEM + " Cloak fully covers her.", ", standing, casting"),
 "shield_maiden_hero": (56, "shield_maiden", "THE SHIELD-MAIDEN (a playable heroine, FEMALE): a woman in a green tunic and silver breastplate over mail, red-gold braided hair, a round shield with a pale-gold boss and a spear." + FEM, ", advancing"),
 "berserker_hero": (56, "berserker", "THE BERSERKER (a playable hero, MALE): a muscular man in a bear pelt cloak with the bear skull as a helm-crest, two axes, war-paint, red glowing eyes, a defiant roar. Not a woman.", ", charging"),
 "draugr_thane": (54, "draugr", "THE DRAUGR THANE (an undead ally for the necromancer, MALE): a heavy undead jarl, a huge blue-grey corpse in dented black iron plate with a chieftain's horned helm, ice-blue glowing eyes, a big frost-covered axe and a tower shield, cold mist. Armoured blocker. Not a woman.", ", standing, shield forward"),
 "barrow_king": (62, "hrimgar", "THE BARROW KING (an evolved undead ally, MALE): a towering undead king in black iron plate with a jagged iron crown, a long tattered ice-blue cloak, bright ice-blue eyes, a huge frost greatsword and a gate-sized tower shield, frost crystals and cold mist. Not a woman.", ", standing, imposing"),
}
def build(key):
    h, crop, subj, pose = SPECS[key]
    return HEAD.format(pose=pose, h=h, subject=subj) + TAIL
def run(key):
    h, crop, subj, pose = SPECS[key]
    out = ROOT / "art_source" / "norse"
    (out / f"{key}.txt").write_text(build(key))
    refs = ["--ref", str(SCR / "style.png")] + (["--ref", str(SCR / f"c_{crop}.png")] if crop else [])
    env = dict(os.environ, GEN_LEDGER=str(ROOT / "docs/art/generation_ledger.csv"))
    r = subprocess.run([sys.executable, str(ROOT / "tools/gen_image.py"), str(out / f"{key}.txt"), str(out / f"{key}.png"), "--key", f"norse/{key}", *refs], env=env, capture_output=True, text=True, cwd=ROOT)
    print(key, r.stdout.strip(), r.stderr.strip()[-300:])
if __name__ == "__main__":
    for k in sys.argv[1:]: run(k)
