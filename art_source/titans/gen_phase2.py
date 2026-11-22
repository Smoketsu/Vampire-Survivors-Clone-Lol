#!/usr/bin/env python3
"""gen_phase2.py: the Age of Titans' phase 2 raw images: the Fern Basin / Great Plain / Last Day beasts, bosses and their pose stills, the three
violet necromancer characters, the Bonehorn family, and the obstacle / icon sheets. Usage (repo root): python3 art_source/titans/gen_phase2.py
[id ...] (no ids = every missing raw image). Raw images land in art_source/titans/raw/<id>.png, prompts beside this file. Same palette and
animal rules as gen_prompts.py (never crimson, gold or violet on a beast); every prompt names the sex. Poses take the base raw as a reference."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_prompts import COL, HEAD, LOWRES, TAIL  # noqa: E402
from gen_sheets import ICON_HEAD, ICON_COL, ICON_TAIL, OBS_HEAD, OBS_TAIL  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/titans.
BONE_COL = "ONLY flat fills: bone white #9C9078 #E7DEC9 #F8F6EE; dark socket shade #231C18; soul teal #1C6B58 #3DCC94. NO red, NO gold, NO purple."
VIO = "violet #1C0F2B (outline) #3B1F5C #6B39A6 #A35CFA; bone white #CFC7AE #EDE6D0; soul teal #1C6B58 #3DCC94; pale undead skin #B8A8A0 #E8DCD4; ochre leather #7E552A #C89448. NO red, NO gold."
CHAR_HEAD = ("Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view, FULL BODY, FACING RIGHT, ready stance. LOW-RESOLUTION pixel art: "
             "the whole figure is only 56 pixels tall and at most {w} pixels wide, coarse pixel grid shown enlarged with crisp square pixels. Chunky simple shapes, no "
             "anti-aliasing, no gradients, no glow haze. Subject: ")
CHAR_TAIL = ("\n\nColours: ONLY flat fills, at most 3 shades per material: " + VIO + "\nOutline: a clean 1-pixel dark outline in the darkest shade of each part's colour. Light from the top-left.\n"
             "Output: a square PNG with a FULLY TRANSPARENT background, one figure only, centred, filling about 85% of the height. No ground, no shadow, no text.\n"
             "Attached: the game's necromancer and another necromancer of this game: match their pixel size, outline and flat look (not their subjects).")
# id -> (art h, art w, ref name or None, sex line, subject, base raw for pose refs or None)
U = {
    "bog_croc": (30, 72, "bog_croc", "male", "a BOG CROC (male crocodile): tar-black hide with a darker armoured back, a long snout with bone-white teeth showing, a pale ochre belly, low and long, lying along the ground, a thick tail.", None),
    "ironjaw": (60, 80, "tyrant", "female", "IRONJAW, THE NEST MOTHER (a big female predator dinosaur, a beast: no human features): bulky, tar-black hide with iron-grey #4A3A30 #6E5A4C armour-like plates along the back, a heavy iron-grey jaw with bone-white teeth, a fern-green moss patch on her back, a few eggshell-white shards on her feet, protective and fierce, standing side-on.", None),
    "primeval_nest": (32, 48, None, "none (a nest)", "a NEST: a round mound of fern fronds, twigs and mud with several speckled bone-white eggs in it and eggshell pieces, a structure seen from above-front.", None),
    "scarmaw_guard": (40, 44, "razorclaw", "female", "a great female RAZORCLAW ALPHA-GUARD (a big female feathered raptor dinosaur): fern-green hide and feathers, a TALL bone-white feather crest, a pale scar across the muzzle, bone-white sickle claws, powerful, mouth open.", None),
    "scarmaw": (60, 72, "scarmaw", "female", "SCARMAW, THE GREAT RAPTOR (a huge female feathered raptor dinosaur, a beast: no human features): fern-green hide with long fern-green and bone-white wing feathers, a TALL bone-white crest, a pale scarred muzzle with an X-shaped scar, big bone-white sickle claws, leaning forward, mouth open, menacing.", None),
    "scarmaw_leap": (60, 72, "scarmaw", "female", "the same SCARMAW (huge female feathered raptor) in a LEAP: body crouched low with both legs drawn up and the sickle claws thrust forward, wings flared out, head low and forward, mouth open, about to pounce.", "scarmaw"),
    "horncharger": (48, 64, "horncharger", "male", "a HORNCHARGER (male ceratopsian, three horns): ochre hide with fern-green back stripes, a big bone-white frill edged with small points, two long bone-white brow horns and a short nose horn, heavy and low, head lowered ready to charge, standing side-on.", None),
    "clubtail": (44, 64, "clubtail", "female", "a CLUBTAIL (female ankylosaur, a beast: no human features): armour plates of ochre and tar-brown across her back with bone-white spikes along the sides, a heavy bone-white club on a thick tail, low and wide, small head, standing side-on.", None),
    "mother_clubtail": (60, 88, "clubtail", "female", "MOTHER CLUBTAIL (a very big female ankylosaur matriarch, a beast: no human features): thick overlapping armour plates in tar-brown and ochre with big bone-white spikes along the sides and shoulders, a huge bone-white club tail, heavier and bigger than a normal clubtail, scarred, standing side-on.", None),
    "ironbrow": (80, 112, "ironbrow", "male", "OLD IRONBROW, THE HORNED TITAN (a giant male ceratopsian, three horns): grey-brown #4A3A30 #6E5A4C hide with ochre back stripes, a huge frill with bone-white spikes along its edge, two long bone-white brow horns and a short nose horn, scarred, massive, head lowered, standing side-on.", None),
    "ironbrow_broken": (80, 112, "ironbrow", "male", "the same OLD IRONBROW (giant male ceratopsian) after the BREAK: his ONE brow horn (the near one) is SNAPPED OFF to a short jagged stump with a volcanic-orange crack, the other horn intact, otherwise identical, head lowered.", "ironbrow"),
    "stormwing": (44, 72, "skyraider", "female", "a STORMWING (a larger female pterosaur, a beast: no human features) in flight, wings spread wide, seen from above-right: ochre wing membranes with tar-brown bones and volcanic-orange streaks, a long bone-white beak, a tall volcanic-orange crest on the head, small claws.", None),
    "stormwing_landed": (44, 72, "skyraider", "female", "the same STORMWING (female pterosaur) LANDED on the ground: wings folded back against the body like a bat, standing on its feet and wing-fingers, head forward pecking with the long beak, volcanic-orange crest.", "stormwing"),
    "thunderwing": (64, 112, "skyraider", "male", "THUNDERWING, THE SKY KING (a giant male pterosaur) in flight, wings spread very wide, seen from above-right: dark tar-brown wing membranes with ochre and volcanic-orange lightning-like streaks, a huge long bone-white beak, a huge bone-white head crest, scarred.", None),
    "gravejaw": (104, 128, "gravejaw", "male", "OLD GRAVEJAW, THE TYRANT KING (the greatest male tyrannosaur, a beast): tar-black scarred hide with a darker back, X-shaped scars on the flank, a huge head with a wide jaw and bone-white teeth, a glowing volcanic-orange throat, small arms, a heavy tail, standing side-on, towering.", None),
    "gravejaw_roar": (104, 128, "gravejaw", "male", "the same OLD GRAVEJAW (colossal male tyrannosaur) ROARING: head thrown UP and back, jaws opened as wide as possible with the volcanic-orange throat glowing, chest swelled, otherwise identical.", "gravejaw"),
}
CHARS = {
    "fern_huntress": (40, "THE FERN HUNTRESS, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: fitted violet hunting leathers, a violet fur-trimmed cloak, a bone-white raptor-skull headdress, pale undead skin. In her right hand a bone spear-staff with a soul-teal flame at the tip (her casting focus). Silhouette: the raptor-skull headdress, the hourglass figure and the spear-staff."),
    "herd_warden": (42, "THE HERD-WARDEN, a MALE necromancer: broad and heavy, long violet robes over a bone-plated mantle, a ceratopsian skull as a shoulder piece, a hood, pale undead skin, teal glowing eyes. In his right hand a tall staff topped with two curved bone horns holding a soul-teal flame (his casting focus). Silhouette: the horned skull shoulder and the horn-topped staff."),
    "skywatcher": (38, "THE SKYWATCHER, a FEMALE necromancer in the figure-redesign style: an exaggerated hourglass figure, big bust and wide hips, FULLY CLOTHED and modest: a fitted violet dress with a high collar patterned with small bone-white stars, a bone-white astrolabe ring at her hip, pale undead skin. In her right hand a tall staff crowned with a small falling-star stone of soul-teal light (her casting focus). Silhouette: the hourglass figure, the astrolabe and the star staff."),
}
SUMMONS = {
    "bonehorn": (34, 40, "horncharger", "no sex (a skeleton)", "a BONEHORN: the skeleton of a horned charger (ceratopsian), bone white with a skull frill and two long brow horns and a nose horn, a bare ribcage, soul-teal glowing eye sockets, head lowered, standing side-on."),
    "fossil_tyrant": (44, 52, "tyrant", "no sex (a skeleton)", "a FOSSIL TYRANT: the skeleton of a great tyrannosaur, bone white with a huge skull and open jaw, bare ribcage, small arm bones, long tail bones, soul-teal fire burning in the eye sockets and the ribcage, standing side-on."),
    "fossil_giant": (48, 52, "longneck", "no sex (a skeleton)", "a FOSSIL GIANT: the skeleton of a huge herd beast (a sauropod), bone white, a small skull on a long neck, a bare ribcage, pillar leg bones, a long tail of vertebrae, soul-teal glowing eye sockets, standing side-on."),
}
SHEETS = {
    "obstacles2": ("sheet", OBS_HEAD.replace("2 separate", "3 separate") + "1. a TREE FERN: a short thick fibrous trunk with a crown of big fern-green fronds (about 40 px wide, 48 px tall);\n2. a long CANYON WALL segment: a horizontal stretch of red-ochre layered rock cliff with a flat top and dark cracks (about 96 px wide, 32 px tall);\n3. a cooling LAVA ROCK: a black round boulder with glowing volcanic-orange cracks (about 40 px wide, 40 px tall).\n" + OBS_TAIL.replace("moss #24451F #4D8534 #8CC46A; bone #9C9078 #E7DEC9 #F8F6EE.", "fern #24451F #4D8534 #8CC46A; ochre rock #7E552A #C89448 #E8C88A; lava #8A2E0C #EF6B1C #FFC070.")),
    "icon_horns": ("violet", ICON_HEAD.format(n=1) + "1. PETRIFIED HORNS: a pair of curved horns turned to grey stone, cracked, bone-white and tar grey, with a faint soul-teal glint." + ICON_COL + ICON_TAIL),
}


def text(uid: str) -> str:
    if uid in CHARS:
        return CHAR_HEAD.format(w=CHARS[uid][0]) + CHARS[uid][1] + CHAR_TAIL + "\n"
    if uid in SUMMONS:
        h, w, _, sex, subj = SUMMONS[uid]
        return HEAD + subj + "\n\n" + LOWRES.format(h=h, w=w).replace("A prehistoric ANIMAL", "A skeleton") + "\n\nSubject sex: " + sex + ".\n\nColours: " + BONE_COL + "\n\n" + TAIL + "\n"
    h, w, _, sex, subj, _ = U[uid]
    return HEAD + subj + "\n\n" + LOWRES.format(h=h, w=w) + "\n\nSubject sex: " + sex + ".\n\nColours: " + COL + "\n\n" + TAIL + "\n"


def main() -> None:
    allids = list(U) + list(CHARS) + list(SUMMONS) + list(SHEETS)
    ids = sys.argv[1:] or [u for u in allids if not (HERE / (("sheet_" + u) if u in SHEETS else ("raw/" + u)) ).with_suffix(".png").exists()]
    for uid in ids:
        refs, size = [], []
        if uid in SHEETS:
            kind, prompt = SHEETS[uid]
            (HERE / ("sheet_" + uid + ".txt")).write_text(prompt + "\n")
            out = HERE / ("sheet_" + uid + ".png")
            refs = ["--ref", str(HERE / "refs" / ("icon_violet.png" if kind == "violet" else "style_beast.png"))]
            size = ["--size", "1536x1024"]
            txt = HERE / ("sheet_" + uid + ".txt")
        else:
            txt, out = HERE / (uid + ".txt"), HERE / "raw" / (uid + ".png")
            txt.write_text(text(uid))
            if uid in CHARS:
                refs = ["--ref", str(ROOT / "assets/sprites/player/necromancer.png"), "--ref", str(ROOT / "assets/sprites/player" / ("wither_witch.png" if uid != "herd_warden" else "bone_oracle.png"))]
            else:
                rname = (SUMMONS.get(uid) or U[uid])[2]
                refs = ["--ref", str(HERE / "refs" / "style_beast.png")]
                if rname and (HERE / "refs" / (rname + ".png")).exists():
                    refs += ["--ref", str(HERE / "refs" / (rname + ".png"))]
                if uid in U and U[uid][5]:
                    refs += ["--ref", str(HERE / "raw" / (U[uid][5] + ".png"))]
        print("+", uid, flush=True)
        subprocess.run([sys.executable, "tools/gen_image.py", str(txt), str(out), *refs, *size, "--key", "titans2/" + uid], cwd=ROOT)


if __name__ == "__main__":
    main()
