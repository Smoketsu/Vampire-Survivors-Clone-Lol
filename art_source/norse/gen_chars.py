"""gen_chars.py: the three Hall of the Slain playable characters, redone as NECROMANCERS of the Norse theme (owner note, Nov 2026):
violet robes, bone and soul-teal accents, pale undead-touched skin, a casting focus; 56 px tall, at most ~46 wide.
Usage: python3 art_source/norse/gen_chars.py <key> ..."""
import subprocess, sys, os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]; S = "/tmp/claude-0/-home-user/9462c562-c5ac-539a-9c62-d10b49b002f0/scratchpad/n/"
HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view, FULL BODY, FACING RIGHT, standing, a NARROW compact silhouette (the figure is clearly taller than it is wide, about 46 pixels wide at most).\n\n"
 "LOW-RESOLUTION pixel art: the whole figure is only 56 pixels tall, drawn on a coarse pixel grid and shown enlarged so every pixel is a big crisp square block. Chunky, simple, readable shapes; no detail smaller than 2 pixels except eyes and glints. No anti-aliasing, gradients, dithering or fine trims.\n\n"
 "This is a PLAYABLE NECROMANCER of the same order as the attached player characters (a hooded necromancer): its DOMINANT colour is deep VIOLET / PURPLE (robe, cloak, dress), with bone-white trim and bone accessories, soul-teal glowing accents and pale, grey-white undead-touched skin. The Norse theme shows only in the cut, silhouette and props.\n\nSubject: {subject}\n\n")
TAIL = ("Colours: ONLY flat fills, at most 3 shades per material: violet #2E1A47 #4A2569 #7B4BB0 #A47DDB; bone white #8C8674 #C8C0A8 #E6E0CC; soul teal #1C6B58 #3DCC94 #A8FFD2; pale undead skin #B9B4C4; leather brown #5A3A24 #8C6040; iron grey #5B6570.\n"
 "Outline: a clean 1-pixel dark violet-black outline around the whole figure. Light from the top-left.\n"
 "Output: a square PNG with a FULLY TRANSPARENT background (real alpha), one subject only, centred, filling about 85% of the image height. No ground, no shadow, no scenery, no text, no frame. Draw ONLY ONE figure.\n"
 "Attached: (1) and (2) approved player characters of this game: match their pixel size, outline weight, violet dominance and flat look.")
FEM = " Exaggerated hourglass figure (wide hips, narrow waist, full bust), glamorous, fully clothed: chest and hips always covered by opaque cloth, never nude."
SPECS = {
 "rune_seer": "THE RUNE-SEER (a playable FEMALE necromancer, a Norse volva): a woman in a long violet robe and hooded violet cloak with a thick grey fur mantle on the shoulders, long braided pale hair, pale undead-touched skin, a tall rune-carved staff topped with a glowing soul-teal rune as her casting focus, small bone charms at her belt." + FEM,
 "shield_maiden_hero": "THE SHIELD-MAIDEN (a playable FEMALE necromancer, a Norse shield-maiden): a woman in a violet hooded cloak over violet and dark-leather armour, a round BONE-RIMMED shield with a violet face on one arm and a short spear tipped with a glowing soul-teal flame as her casting focus, a braid, pale undead-touched skin." + FEM,
 "berserker_hero": "THE BERSERKER (a playable MALE necromancer, a Norse berserker): a broad man in a VIOLET hood with a bear-skull as a helm-crest, a violet cloak edged with bear fur, bare pale undead-touched arms with bone bracers, ONE axe held close against his body, its head glowing soul-teal as his casting focus. Compact, upright and controlled, not a sprawling brawler. Not a woman.",
}
def run(k):
    out = ROOT / "art_source/norse"; (out / f"{k}.txt").write_text(HEAD.format(subject=SPECS[k]) + TAIL)
    env = dict(os.environ, GEN_LEDGER=str(ROOT / "docs/art/generation_ledger.csv"))
    r = subprocess.run([sys.executable, str(ROOT / "tools/gen_image.py"), str(out / f"{k}.txt"), str(out / f"{k}.png"), "--key", f"norse/{k}_necro", "--ref", S + "pl_necromancer.png", "--ref", S + "pl_" + ("shrine_maiden" if k != "berserker_hero" else "ferrywoman") + ".png"], env=env, capture_output=True, text=True, cwd=ROOT)
    print(k, r.stdout.strip(), r.stderr.strip()[-200:])
if __name__ == "__main__":
    for k in sys.argv[1:]: run(k)
