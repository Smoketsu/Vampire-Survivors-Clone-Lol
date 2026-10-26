"""make_prompts.py: writes the image prompts of the Ossuary expansion step 3 badges (the eleven
new upgrades and the Dominion tree emblem) into prompts/<icon>.txt, one symbol per prompt, in the
art pass's icon recipe (docs/art/ART_BIBLE.md "Ossuary and Soul Ash icons": a 26 art px symbol
on a transparent ground, composited later on the violet cut-corner badge by make_badges.py).

Run from the repo root:  python3 art_source/ossuary_options/make_prompts.py
Then, per icon:  GEN_LEDGER=docs/art/generation_ledger.csv python3 tools/gen_image.py \
    art_source/ossuary_options/prompts/<icon>.txt art_source/ossuary_options/raw/<icon>.png \
    --ref assets/sprites/icons/shadow_bolt.png --ref assets/sprites/icons/<tree icon>.png --key icons/<icon>
"""

from pathlib import Path

HERE = Path(__file__).resolve().parent  # art_source/ossuary_options/

# Colour lists per tree (the art bible: Necromancy soul teal + bone, Shadowcraft violet + bone,
# Survival cold blue, Fortune gold + teal crystals; Dominion ivory bone + violet, no Covenant gold).
COLOURS = {
    "necromancy": "bone #1C110B (outline), #7F785F, #B4AA8A, #E8E1C8; soul teal #081814 (outline), #1C6B58, #3DCC94, #A8FFD2",
    "shadowcraft": "violet #160A21 (outline), #4A2569, #7A42AD, #A35CFA, #DDBDFF (one glint); bone #1C110B (outline), #7F785F, #B4AA8A, #E8E1C8",
    "survival": "cold blue #0F141C (outline), #243A99, #4F78EB, #9FB8FF; ice #A6D9EA, #E4FAFF; bone #7F785F, #B4AA8A, #E8E1C8",
    "fortune": "gold #1C110B (outline), #8C6040, #E0A92E, #FFDC66, #FFFAE8 (one glint); soul teal #081814 (outline), #1C6B58, #3DCC94, #A8FFD2",
    "dominion": "bone #1C110B (outline), #7F785F, #B4AA8A, #E8E1C8; violet #160A21 (outline), #4A2569, #7A42AD, #A35CFA",
}

# icon id -> (tree, symbol description). Each reads at 32 px: one bold shape, one accent.
ICONS = {
    "bone_reserve": ("necromancy", '"Bone Reserve" (a fallen summon rises again behind a barrier of bone): a small bone skull rising out of the ground, framed by a curved soul-teal barrier arc made of three overlapping bone plates in front of it'),
    "commanders_presence": ("necromancy", '"Commander\'s Presence" (every summon class you command makes them all stronger): a bone war banner on a bone pole, its pennant soul teal, with three small skull heads of different shapes (a helmed one, a hooded one, a horned one) gathered below it'),
    "echo_weaving": ("shadowcraft", '"Echo Weaving" (your spells echo sooner): a violet shadow orb in the centre with two concentric violet echo rings rippling out of it and a small bone spindle thread wrapping around them'),
    "dark_tithe": ("shadowcraft", '"Dark Tithe" (kills by your own hand feed your ultimate): a bone collection bowl (an upturned skull cap) with three violet soul droplets falling into it from above, a violet glow rising from the bowl'),
    "last_rites": ("survival", '"Last Rites" (death looks away once): a cold-blue tall candle burning with a pale ice-white flame, a small bone skull at its foot, the flame shielded by a cupped cold-blue hand of mist'),
    "grave_ward": ("survival", '"Grave Ward" (a ward that swallows a whole blow): a round cold-blue rune shield seen from the front, a bone tombstone shape in its centre, and a jagged crack across the shield from a blow it stopped'),
    "gilded_chests": ("fortune", '"Gilded Chests" (a chest weighs two rewards and keeps the better): a small gold treasure chest with its lid open, two soul-teal crystals rising out of it side by side, the right one larger and brighter'),
    "elite_bounty": ("fortune", '"Elite Bounty" (elites pay more Soul Ash): a gold ring-crowned skull (an elite trophy) on a little heap of gold coins with one soul-teal ember on top'),
    "head_start": ("dominion", '"Head Start" (begin every run a level ahead): a bone stair of three steps rising to the right, a violet upward chevron arrow above the top step'),
    "chosen_vanguard": ("dominion", '"Chosen Vanguard" (your first summon class rises a level higher): a single bone skeleton helm with a violet plume, a bone laurel of two leaves under it'),
    "patient_grave": ("dominion", '"Patient Grave" (a skipped level-up hands back a reroll): a bone hourglass with violet sand, a small curved violet return arrow circling its lower half'),
    "tree_dominion": ("dominion", '"Dominion" (the necromancer\'s rule over his dead, an Ossuary tree emblem): a bone crown of five spikes, each spike a small finger bone, a violet gem set in its front band'),
}

TEMPLATE = """A single pixel-art game icon SYMBOL for a dark-fantasy necromancer game, on a FULLY TRANSPARENT background (real alpha), with NO badge, NO frame, NO border and NO background square: just the symbol itself.

LOW-RESOLUTION pixel art: the whole symbol is only 26 x 26 pixels, drawn on a coarse pixel grid and shown enlarged so every pixel is a big crisp square block (nearest-neighbour). One bold, simple, readable shape; no detail smaller than 2 pixels except small glints. No anti-aliasing, no gradients, no dithering, no texture noise, no soft glow haze.

Symbol: {symbol}.

Colours: ONLY flat fills from this list: {colours}.
Outline: a clean 1-pixel dark outline around the symbol in the darkest shade of each part's colour (never pure black). Light from the top-left.

Output: a square PNG, the symbol centred, filling about 80% of the image. No text, no frame, no watermark.
Attached: approved icons of this game (shown with their badge): match their pixel size, outline weight and palette exactly, but draw ONLY the symbol, without the badge.
"""


def main() -> None:
    out = HERE / "prompts"
    out.mkdir(parents=True, exist_ok=True)
    for icon, (tree, symbol) in ICONS.items():
        (out / (icon + ".txt")).write_text(TEMPLATE.format(symbol=symbol, colours=COLOURS[tree]))
        print(icon, tree)


if __name__ == "__main__":
    main()
