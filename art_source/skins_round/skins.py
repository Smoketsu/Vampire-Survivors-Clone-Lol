"""skins.py: drives the drawn-skins round (gen_image.py sources -> pixel art stills).
  python3 skins.py gen <char>_<family> ...   build refs + prompt, call tools/gen_image.py (sources in art_source/skins_round/src/)
  python3 skins.py conv <char>_<family> ...  pixelate_source + prepare_sprite -> assets/sprites/player/<id>.png
Family: hyper | untouchable | deathlord. Refs: the character's own still enlarged (square canvas) + one existing
skin of the same family on another character (style only). Walk / idle strips: tools/walk_cycle.py SKINS."""
import subprocess, sys, os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = f"{ROOT}/art_source/skins_round/src"
TMP = "/tmp/claude-0/s/sk"
os.makedirs(SRC, exist_ok=True); os.makedirs(TMP, exist_ok=True)
FEMALE = {"brine_widow", "corsair_queen", "rune_seer", "shield_maiden_hero", "the_embalmer", "lion_priestess", "blind_saint",
          "the_unveiled", "fern_huntress", "skywatcher", "changeling_princess", "gravegardener"}
DESC = {
    "brine_widow": "a crowned sea-widow with a long veil and a hooked driftwood staff",
    "heretic_scribe": "a heretic scribe in a pointed hat with a feather quill-staff and floating scrolls",
    "marooned_quartermaster": "a marooned pirate quartermaster in a tricorn hat and long coat holding a lantern staff",
    "corsair_queen": "a pirate queen in a plumed captain's hat and coat holding a glowing teal blade-staff",
    "ghost_helmsman": "a hooded ghost helmsman in a long sailor's coat with an anchor, holding a ship's-wheel staff and a lantern",
    "rune_seer": "a hooded Norse rune-seer (volva) with a rune-carved staff topped by a glowing teal stone",
    "shield_maiden_hero": "a Norse shield-maiden in a hood with a round shield and a spear-staff with a glowing teal tip",
    "berserker_hero": "a hulking Norse berserker in a bear-pelt hood holding a big axe with a teal glow",
    "the_embalmer": "an Egyptian embalmer wrapped in linen bandages and robes, with a tall staff",
    "lion_priestess": "an Egyptian lioness priestess with a lion-mane headdress and a staff with a glowing teal eye",
    "pharaohs_shade": "the shade of a pharaoh in tattered robes and a striped nemes headdress holding a crook and flail",
    "fallen_herald": "a hooded fallen angel herald with one torn wing, holding a staff topped by a teal flame",
    "blind_saint": "a blind female saint in a hood holding a tall staff topped by a ring of eyes",
    "the_unveiled": "a hooded veiled female angel with a feathered wing, holding a staff with a glowing teal star",
    "fern_huntress": "a prehistoric huntress in a hooded raptor-skull mask with a leaf-and-bone cloak, holding a spear staff with a teal gem",
    "herd_warden": "a broad herd warden in a horned beast-skull mask and heavy cloak with a big staff topped by a teal glow",
    "skywatcher": "a female astronomer sorceress in a tall pointed hat with a staff topped by a glowing teal orb",
    "horned_herald": "an antlered herald of the Wild Hunt in a hooded cloak holding a horn-staff with a teal flame",
    "changeling_princess": "a fae changeling princess in a pointed witch hat and mask with a staff and floating masks",
    "gravegardener": "a female grave-gardener witch in a wide witch hat with roots and vines on her robe, holding a gnarled staff",
}
HYPER = {  # per-character flair for the Hyper skin (the skin's display name is in SkinData.HYPER_NAMES)
    "brine_widow": "Pearl-Crowned Widow: a crown of gold and pearls, gold-pearl veil",
    "heretic_scribe": "Illuminated Heretic: gold-leaf illuminated robes, a golden quill, glowing gold scrolls",
    "marooned_quartermaster": "The Gilded Castaway: a gold-braided captain's coat and hat, a gold lantern",
    "corsair_queen": "The Gilded Queen: a gold-laced royal pirate coat, a gold crown on the hat, a golden blade",
    "ghost_helmsman": "The Gilded Helmsman: gold-trimmed sea-captain's coat, a golden ship's wheel and anchor",
    "rune_seer": "The Gilded Volva: gold-inlaid robe, glowing golden runes, a gold circlet",
    "shield_maiden_hero": "The Gilded Shield: a gold-rimmed shield, gilded mail and spear tip, a winged gold helm circlet",
    "berserker_hero": "The Gilded Bear: gold-plated bear-pelt pauldrons and golden axe blade",
    "the_embalmer": "The Gilded Embalmer: gold-wrapped linen, a golden funerary collar, a golden staff",
    "lion_priestess": "The Golden Lioness: a golden lion-mane headdress, gold collar and bracers",
    "pharaohs_shade": "The Golden King: a solid gold pharaoh's nemes mask and crown, golden crook and flail",
    "fallen_herald": "The Gilded Herald: gilded armour trim, a golden wing and golden flame",
    "blind_saint": "The Gilded Saint: a gold halo-ring of eyes, gold-embroidered robes",
    "the_unveiled": "The Gilded Unveiled: a golden veil, gold-feathered wing, gold trim",
    "fern_huntress": "The Gilded Huntress: a gold-plated raptor skull mask, gold claw trim, gilded spear",
    "herd_warden": "The Gilded Warden: gold-capped horns, gilded mask and staff head",
    "skywatcher": "The Gilded Skywatcher: a gold star-covered hat and robe, a golden orb",
    "horned_herald": "The Gilded Hunter: golden antlers, gold-trimmed cloak, a golden horn",
    "changeling_princess": "The Gilded Changeling: a golden mask and hat, gold masks floating around her",
    "gravegardener": "The Gilded Gardener: a gold-vine hat, golden roots and flowers on her robe",
}
FAM = {
    "hyper": ("a HYPER skin: a dramatic, empowered, gilded take on the character with radiant gold regalia: gold trim and ornaments, "
              "a blazing gold SUN CORONA of rays behind the head, glowing gold highlights. Theme: {h}. The violet cloth stays rich violet so the player stays readable."),
    "untouchable": ("an UNTOUCHABLE skin: a ghost-white phantom: pale luminous robes, cloth and armour in ice white and pale blue, "
                    "the hem and loose cloth dissolving into a few big wisp tails, soul-teal glowing eyes, flames and weapon glow, a pale lavender lining. "
                    "Dark outline kept. Face uncovered in warm bone skin tone so it reads against the cold white."),
    "deathlord": ("a DEATHLORD skin: a crowned dread-king: a big spiked or horned gold crown with a red jewel, a FLAT mid-violet robe or gown, "
                  "black-iron armour pieces with grey edges, gold only on a few LARGE pieces (the crown, one band, the weapon head), "
                  "a crimson-lined mantle, crimson glowing eyes. No scattered tiny trim."),
}
STYLE_REF = {  # existing skin of the family shown as style only: (female, male)
    "hyper": ("soulbinder_hyper", "bone_oracle_hyper"),
    "untouchable": ("soulbinder_untouchable", "bone_oracle_untouchable"),
    "deathlord": ("wither_witch_deathlord", "carrion_lord_deathlord"),
}


def ref(sprite, out):
    im = Image.open(f"{ROOT}/assets/sprites/player/{sprite}.png").convert("RGBA")
    s = max(1, 984 // max(im.size))
    im = im.resize((im.width * s, im.height * s), Image.NEAREST)
    c = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    c.alpha_composite(im, ((1024 - im.width) // 2, (1024 - im.height) // 2))
    c.save(out)


def split(sid):
    for f in FAM:
        if sid.endswith("_" + f):
            return sid[: -len(f) - 1], f


def gen(sid, quality="medium"):
    ch, fam = split(sid)
    ref(ch, f"{TMP}/{ch}_base.png")
    st = STYLE_REF[fam][0 if ch in FEMALE else 1]
    ref(st, f"{TMP}/{st}_style.png")
    fig = (" Keep her exaggerated hourglass figure exactly as in the first image (large bust, cinched waist, wide hips), FULLY CLOTHED, tasteful." if ch in FEMALE else "")
    p = (f"Pixel art game character sprite, full body, top-down 3/4 view, facing forward-right, chunky dark outline, limited palette, light from the top-left, "
         f"transparent background, no ground, no shadow, no text. The FIRST attached image is the character: {DESC[ch]}. "
         f"Draw {FAM[fam].format(h=HYPER.get(ch, ''))} It is a NEW costume skin of the character in the first image: same pose, silhouette, proportions and held weapon, "
         f"but redesign the costume completely, not a recolour.{fig} The SECOND attached image is ONLY an example of this skin theme's art style on a different character: "
         f"do not copy that character. One character only, centered, fills the canvas height.")
    open(f"{TMP}/{sid}.txt", "w").write(p)
    subprocess.run([sys.executable, f"{ROOT}/tools/gen_image.py", f"{TMP}/{sid}.txt", f"{SRC}/{sid}.png", "--ref", f"{TMP}/{ch}_base.png",
                    "--ref", f"{TMP}/{st}_style.png", "--key", f"player/{sid}", "--quality", quality], check=True, cwd=ROOT)


def conv(sid):
    ch, fam = split(sid)
    base = Image.open(f"{ROOT}/assets/sprites/player/{ch}.png")
    bh = base.height
    g = np.array(Image.open(f"{SRC}/{sid}.png").convert("RGBA"))
    g[..., 3] = np.where(g[..., 3] >= 128, 255, 0)
    gb = Image.fromarray(g).getbbox()
    # Scale: the base's still fills its canvas the same way; keep the base's body scale via the bbox ratio, clamped to base..base+8 rows.
    rb = Image.open(f"{TMP}/{ch}_base.png").getbbox()
    h = round(bh * (gb[3] - gb[1]) / (rb[3] - rb[1]))
    h = max(bh, min(bh + 8, h))
    sp = f"{TMP}/{sid}_pix.png"
    subprocess.run([sys.executable, f"{ROOT}/tools/pixelate_source.py", f"{SRC}/{sid}.png", str(h), sp], check=True, cwd=ROOT, capture_output=True)
    subprocess.run([sys.executable, f"{ROOT}/tools/prepare_sprite.py", sp, f"player/{sid}", "--art-height", str(h), "--inside-outline",
                    "--no-prune", "--no-levels"], check=True, cwd=ROOT, capture_output=True)
    r = Image.open(f"{ROOT}/assets/sprites/player/{sid}.png")
    print(sid, r.size, "base", base.size)


if __name__ == "__main__":
    cmd, ids = sys.argv[1], sys.argv[2:]
    for i in ids:
        (gen if cmd == "gen" else conv)(i)
