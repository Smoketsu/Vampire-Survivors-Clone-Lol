"""gen_icons.py: symbol sheets (4 icon symbols per image) for the Hall of the Slain's icons; compose_icons.py cuts and badges them."""
import subprocess, sys, os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
S = "/tmp/claude-0/-home-user/9462c562-c5ac-539a-9c62-d10b49b002f0/scratchpad/n/"
HEAD = ("A sheet of FOUR separate pixel-art game ICON SYMBOLS in one row, evenly spaced with wide empty gaps between them, on a FULLY TRANSPARENT background (real alpha). "
 "Each symbol is simple, bold and centred in its quarter of the image, drawn as chunky low-resolution pixel art (each symbol about 24 pixels wide on a coarse grid, shown enlarged with crisp square pixels, nearest-neighbour, 1-pixel dark outline, flat colours, at most 3 shades per colour, light from the top-left). No frame, no badge background, no text, no letters.\nFrom left to right:\n")
TAIL = ("\nColours: black #0B0F16; ice-blue rune glow #3F72C4 #8FD0FF #E0F4FF; frost white #A9BBCC #EAF2FA; iron grey #2B3139 #5B6570 #8F99A3; pale gold #B08A3C #F5D77A; pine green #1F4A3A; ember amber #F0902E. Never violet.\n"
 "Attached: an approved icon of this game: match its pixel size, outline weight and flat look (only the symbol, not its frame).")
SHEETS = {
 "a": ["BARROW GRASP: three pale frost-blue skeletal hands bursting up out of dark snowy earth in a ring, ice-blue glow between them.",
       "VALKYRIE SPEAR: a golden spear diving down at an angle with a small white feathered wing on its shaft and a gold light streak behind.",
       "GUNGNIR: a long ornate gold-tipped spear flying straight, with an ice-blue rune glowing on its head and a short light trail.",
       "GRAVE FROST: a frost-blue snowflake crystal over a small grey tombstone."],
 "b": ["EINHERJAR'S OATH: a gold-rimmed round shield with a glowing pale-gold hand raised in an oath above it.",
       "RUNECRAFT: a carved grey stone tablet with one bright ice-blue rune on it.",
       "INGLORIOUS: a pale-gold winged helm with a crack through it and a downward arrow beneath, dull and dim.",
       "CALM BLOOD: a red frenzied bear-claw swirl being cooled, a frost-blue droplet in the centre, grey shield arc below."],
 "c": ["BARROW-LORD'S EMBRACE: a large frost-blue skeletal hand clutching upward out of a ring of gold-edged grave mounds, bright ice glow.",
       "CHOOSER OF THE SLAIN: a gold valkyrie wing carrying a small glowing hero silhouette upward, gold rays.",
       "SPEAR OF THE HANGED: a long gold spear with a rope noose looped on its shaft, bright ice-blue rune on the blade, gold rays.",
       "BARROW KING: a jagged grey iron crown with ice-blue gems on a frost-covered tower shield."],
 "d": ["DRAUGR THANE: a horned iron helm with glowing ice-blue eyes on a frosty blue-grey face, a small axe crossed behind it.",
       "(leave this slot EMPTY)", "(leave this slot EMPTY)", "(leave this slot EMPTY)"],
}
def run(k):
    p = HEAD + "\n".join(f"{i+1}. {t}" for i, t in enumerate(SHEETS[k])) + TAIL
    out = ROOT / "art_source/norse"; (out / f"icons_{k}.txt").write_text(p)
    env = dict(os.environ, GEN_LEDGER=str(ROOT / "docs/art/generation_ledger.csv"))
    r = subprocess.run([sys.executable, str(ROOT / "tools/gen_image.py"), str(out / f"icons_{k}.txt"), str(out / f"icons_{k}.png"), "--key", f"norse/icons_{k}", "--ref", S + "icon_ref.png", "--size", "1536x1024"], env=env, capture_output=True, text=True, cwd=ROOT)
    print(k, r.stdout.strip(), r.stderr.strip()[-200:])
if __name__ == "__main__":
    for k in sys.argv[1:]: run(k)
