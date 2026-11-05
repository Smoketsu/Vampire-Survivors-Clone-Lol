#!/usr/bin/env python3
"""make_specs.py: writes tools/promo_specs/dayNN.json (the 16 daily TikTok clips) for tools/make_promo_clip.py.

Each clip is a list of shots (stage, seed, start second, length, extra autotest args, caption). A caption is a list of
(line, colour) pairs, one key line in gold; a caption repeated on the next shot is held across the cut. Every clip
ends on the same end card (logo, FREE IN YOUR BROWSER, LINK IN BIO), recorded once and shared through the cache
(it is the only graveyard seed 3 shot). Edit CLIPS and run `python3 tools/promo_specs/make_specs.py`.
Render one day: python3 tools/make_promo_clip.py --spec tools/promo_specs/day04.json --out <dir> --work <shared cache dir>
"""
import json, os
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = ImageFont.truetype(os.path.join(HERE, "../../assets/fonts/Jersey10-Regular.ttf"), 57)
CREAM, GOLD = "cream", "gold"


def cap(*lines):
    """Caption lines: a line starting with '*' is the gold key line."""
    return [(l[1:], GOLD) if l.startswith("*") else (l, CREAM) for l in lines]


def texts(c, dur):
    out = []
    for i, (line, col) in enumerate(c):
        assert FONT.getbbox(line)[2] * 2 <= 838, "caption line too wide: " + line
        out.append({"text": line, "font": "jersey", "size": 57, "scale": 2, "color": col, "y": 230 + 122 * i, "from": 0.0, "to": dur})
    return out


# shot: (stage, seed, start, extra, caption); every shot is SEC seconds
SEC = 5.6
G = lambda *a: a
CLIPS = {
 1: [("graveyard", 7, 700, [], cap("Command an Army", "*of the Dead!")),
     ("graveyard", 7, 830, [], cap("Warriors Block,", "Priests Heal,", "*Archers Fire!")),
     ("graveyard", 7, 960, [], cap("Warriors Block,", "Priests Heal,", "*Archers Fire!"))],
 2: [("crimson_march", 5, 600, ["--policy=evolve", "--spells=bone_spear,corpse_explosion,plague_cloud,soul_chains,death_mark"], cap("*36 Spells", "to Master!")),
     ("crimson_march", 5, 666, ["--policy=evolve", "--spells=bone_spear,corpse_explosion,plague_cloud,soul_chains,death_mark"], cap("Bone Spears,", "Soul Chains,", "*Corpse Explosions!")),
     ("crimson_march", 5, 732, ["--policy=evolve", "--spells=bone_spear,corpse_explosion,plague_cloud,soul_chains,death_mark"], cap("Bone Spears,", "Soul Chains,", "*Corpse Explosions!"))],
 3: [("burning_gate", 4, 600, [], cap("*Descend into Hell!")),
     ("burning_gate", 4, 780, [], cap("Break the Portals,", "*Survive the Pits!")),
     ("pandemonium", 4, 800, [], cap("Hell Comes for", "*Your Souls!"))],
 4: [("sanctum", 5, 620, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Summons Evolve", "*into Monsters!")),
     ("sanctum", 5, 700, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Hellhounds,", "Bone Colossi,", "*Winter Revenants!")),
     ("sanctum", 5, 840, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Hellhounds,", "Bone Colossi,", "*Winter Revenants!"))],
 5: [("province", 3, 700, [], cap("Samurai, Ninjas", "*and Oni!")),
     ("province", 3, 900, [], cap("Day Turns", "*to Night!")),
     ("province", 3, 1040, [], cap("Day Turns", "*to Night!"))],
 6: [("sanctum", 3, 1030, [], cap("*Epic Boss Fights!")),
     ("sanctum", 3, 1055, [], cap("*Epic Boss Fights!")),
     ("underworld", 3, 1035, [], cap("Every Stage Has", "*Its Own Boss!"))],
 7: [("crimson_march", 9, 600, ["--classes=abomination,gargoyle,frost_wraith,bone_hound,banshee"], cap("Abominations,", "Gargoyles, Wraiths,", "*Hounds, Banshees!")),
     ("crimson_march", 9, 720, ["--classes=abomination,gargoyle,frost_wraith,bone_hound,banshee"], cap("Abominations,", "Gargoyles, Wraiths,", "*Hounds, Banshees!")),
     ("sanctum", 9, 700, ["--classes=corpse_catapult,bone_golem,abomination,banshee"], cap("Catapults, Golems", "*and More!"))],
 8: [("ravensmoor", 4, 700, [], cap("Enter the", "*Sanguine Court!")),
     ("ravensmoor", 4, 900, [], cap("Vampires, Bats,", "Werewolves,", "*Witches!")),
     ("castle_sanguis", 4, 1040, [], cap("Face Queen", "*Carmilla!"))],
 9: [("graveyard", 6, 600, ["--policy=evolve", "--spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud,death_mark"], cap("Every Spell Has", "*an Evolution!")),
     ("graveyard", 6, 660, ["--policy=evolve", "--spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud,death_mark"], cap("Bone Spear Becomes", "*Ossuary Lance!")),
     ("graveyard", 6, 720, ["--policy=evolve", "--spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud,death_mark"], cap("Soul Rapture,", "Pestilence,", "*Grave Eruption!"))],
 10: [("skid_row", 4, 640, [], cap("Gangs, Police, SWAT,", "*Army and Heroes!")),
      ("skid_row", 4, 800, [], cap("Gangs, Police, SWAT,", "*Army and Heroes!")),
      ("liberty_heights", 4, 830, [], cap("*Supers Fight Back!"))],
 11: [("crimson_march", 6, 1192, [], cap("Survive the", "*Reckoning!")),
      ("crimson_march", 6, 1199, [], cap("At 0:00 the", "*Reckoning Begins!")),
      ("crimson_march", 6, 1211, [], cap("Near-Unbeatable", "*Enemies Swarm In!"))],
 12: [("olympus", 4, 800, [], cap("Face the Gods", "*of Olympus!")),
      ("olympus", 4, 950, [], cap("Wrath of the Gods", "*Hits Both Armies!")),
      ("underworld", 4, 700, [], cap("Wrath of the Gods", "*Hits Both Armies!"))],
 13: [("crimson_march", 5, 560, ["--character=bone_oracle"], cap("Play as", "*36 Necromancers!")),
      ("crimson_march", 5, 560, ["--character=plague_scholar"], cap("Play as", "*36 Necromancers!")),
      ("crimson_march", 5, 560, ["--character=barrow_warden"], cap("Each Wields a", "*Different Spell!")),
      ("crimson_march", 5, 560, ["--character=soulbinder"], cap("Each Wields a", "*Different Spell!"))],
 14: [("ark", 5, 700, [], cap("Aliens Come to", "*Reap the World!")),
      ("ark", 5, 900, [], cap("Saucers Abduct", "*Your Undead!")),
      ("proving_moon", 5, 800, [], cap("Saucers Abduct", "*Your Undead!"))],
 15: [("harbour", 4, 800, [], cap("Tides Rise", "*at Gullhaven!")),
      ("spire", 4, 800, [], cap("Islands Sink", "*Beneath You!")),
      ("citadel", 4, 900, [], cap("Machines Take Aim", "*at Your Army!"))],
 16: [("crimson_march", 8, 1000, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Build the", "*Ultimate Horde!")),
      ("crimson_march", 8, 1080, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Build the", "*Ultimate Horde!")),
      ("crimson_march", 8, 1160, ["--policy=summon", "--classes=bone_hound,abomination,gargoyle,frost_wraith", "--passives=blood_scent,bone_plating,unholy_resilience,soul_recycling"], cap("Build the", "*Ultimate Horde!"))],
}

END = {"id": "end", "stage": "graveyard", "seed": 3, "start": 900, "seconds": 3.2, "dim": 0.6,
       "logo": {"y": 520, "scale": 3, "from": 0.0, "to": 3.2},
       "texts": [{"text": "FREE IN YOUR BROWSER", "font": "jersey", "size": 38, "scale": 3, "color": "gold", "y": 900, "from": 0.3, "to": 3.2},
                 {"text": "LINK IN BIO", "font": "jersey", "size": 57, "scale": 3, "color": "teal", "y": 1080, "from": 0.7, "to": 3.2}]}

if __name__ == "__main__":
    for n, shots in CLIPS.items():
        out = []
        for i, (stage, seed, start, extra, c) in enumerate(shots):
            s = {"id": "s%d" % i, "stage": stage, "seed": seed, "start": start, "seconds": SEC}
            if extra:
                s["extra"] = extra
            s["texts"] = texts(c, SEC)
            out.append(s)
        out.append(END)
        spec = {"name": "day%02d" % n, "render": [1080, 1920], "size": [1080, 1920], "fps": 30, "lufs": -14, "art_scale": 2, "shots": out}
        json.dump(spec, open(os.path.join(HERE, "day%02d.json" % n), "w"), indent=1)
