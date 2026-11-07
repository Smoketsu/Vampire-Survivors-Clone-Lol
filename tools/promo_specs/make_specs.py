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


def texts(c, dur, t0=0.0):
    """Caption text entries for one caption c, shown from t0 to dur (s within the shot)."""
    out = []
    for i, (line, col) in enumerate(c):
        assert FONT.getbbox(line)[2] * 2 <= 838, "caption line too wide: " + line
        out.append({"text": line, "font": "jersey", "size": 57, "scale": 2, "color": col, "y": 230 + 122 * i, "from": t0, "to": dur})
    return out


# shot: (stage, seed, start, extra, caption); every shot is SEC seconds
SEC = 5.6  # length of every shot (s of game time = s of video) unless CLIP_SEC overrides it for that clip
CLIP_SEC = {2: 4.6, 4: 4.6, 7: 4.6, 9: 4.6}  # per-clip shot length (s): Days 2, 4, 7 and 9 show five different builds, so each shot is shorter
# Opening title of a clip (caption shown over the first shot only, then the shot's own caption takes over):
# clip number -> (caption, seconds it stays up). Day 2: "36 Spells to Master!" before the first build's names.
INTRO = {2: (cap("*36 Spells", "to Master!"), 1.6),
         4: (cap("Summons Evolve", "*into Monsters!"), 1.6),
         7: (cap("Meet the New", "*Undead Classes!"), 1.6),
         9: (cap("Every Spell Has", "*an Evolution!"), 1.6)}
G = lambda *a: a
# Clip numbers whose gameplay shots carry the burned-in captions (intro title and per-shot names). Owner, Nov 2026: the
# big caption text looks cheesy, so Days 4, 7 and 9 are rendered with none (end card only); the captions stay in CLIPS
# and INTRO, so a new caption style can be added later without re-picking shots: put the day number in this set.
CAPTIONS = {1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16}
CLIPS = {
 1: [("graveyard", 7, 700, [], cap("Command an Army", "*of the Dead!")),
     ("graveyard", 7, 830, [], cap("Warriors Block,", "Priests Heal,", "*Archers Fire!")),
     ("graveyard", 7, 960, [], cap("Warriors Block,", "Priests Heal,", "*Archers Fire!"))],
 2: [("crimson_march", 5, 700, ["--policy=evolve", "--spells=bone_spear,soul_chains,corpse_explosion"], cap("Bone Spear,", "Soul Chains,", "*Corpse Explosion!")),
     ("graveyard", 6, 720, ["--policy=evolve", "--spells=plague_cloud,wither,soul_siphon"], cap("Plague Cloud,", "Wither,", "*Soul Siphon!")),
     ("harbour", 4, 720, ["--policy=evolve", "--spells=undertow,forbidden_verse,call_of_the_drowned"], cap("Undertow,", "Forbidden Verse,", "*Call of the Drowned!")),
     ("wastes", 4, 720, ["--policy=evolve", "--spells=death_ray,stolen_thunder,scrap_swarm"], cap("Death Ray,", "Stolen Thunder,", "*Scrap Swarm!")),
     ("ravensmoor", 4, 720, ["--policy=evolve", "--spells=moonfang,night_swarm,witch_circle"], cap("Moonfang,", "Night Swarm,", "*Witch Circle!"))],
 3: [("burning_gate", 4, 600, [], cap("*Descend into Hell!")),
     ("burning_gate", 4, 780, [], cap("Break the Portals,", "*Survive the Pits!")),
     ("pandemonium", 4, 800, [], cap("Hell Comes for", "*Your Souls!"))],
 # Day 4: five summon evolutions, each its own shot on a different stage and build (all confirmed by headless scouting runs
 # with the same args: --timeout=840 summary "evolutions" line; the evolution gate is 8:00, so every start is after it)
 4: [("crimson_march", 5, 600, ["--policy=summon", "--classes=bone_hound", "--passives=blood_scent"], cap("Hounds Become", "*Hellhounds!")),  # hellhound @8:41
     ("sanctum", 5, 600, ["--policy=summon", "--classes=abomination", "--passives=bone_plating"], cap("Abominations", "Become", "*Bone Colossi!")),  # bone_colossus @8:21
     ("graveyard", 5, 800, ["--policy=summon", "--classes=frost_wraith", "--passives=soul_recycling"], cap("Wraiths Become", "*Winter Revenants!")),  # winter_revenant @8:02
     ("wastes", 6, 660, ["--policy=summon", "--classes=spawn_of_the_deep", "--passives=crushing_depths"], cap("Spawn of the Deep", "Become", "*Leviathans!")),  # leviathan @9:06
     ("olympus", 7, 760, ["--policy=summon", "--classes=bone_golem", "--passives=grave_masonry"], cap("Golems Become", "*Ossuary Titans!"))],  # ossuary_titan @8:36 (province s7 also evolved, @8:03)
 5: [("province", 3, 700, [], cap("Samurai, Ninjas", "*and Oni!")),
     ("province", 3, 900, [], cap("Day Turns", "*to Night!")),
     ("province", 3, 1040, [], cap("Day Turns", "*to Night!"))],
 6: [("sanctum", 3, 1030, [], cap("*Epic Boss Fights!")),
     ("sanctum", 3, 1055, [], cap("*Epic Boss Fights!")),
     ("underworld", 3, 1035, [], cap("Every Stage Has", "*Its Own Boss!"))],
 # Day 7: the newer summon classes, one or two per shot (before the 8:00 evolution gate, so they are still the base forms)
 7: [("crimson_march", 9, 330, ["--classes=abomination,gargoyle"], cap("Abominations", "*and Gargoyles!")),
     ("graveyard", 9, 330, ["--classes=frost_wraith,bone_hound"], cap("Frost Wraiths", "*and Bone Hounds!")),
     ("sanctum", 9, 450, ["--classes=banshee"], cap("Banshees Wail", "*and Weaken Foes!")),
     ("harbour", 9, 450, ["--classes=corpse_catapult"], cap("Corpse Catapults", "*Hurl Boulders!")),
     ("ravensmoor", 9, 330, ["--classes=bone_golem"], cap("Bone Golems", "*Hold the Line!"))],
 8: [("ravensmoor", 4, 700, [], cap("Enter the", "*Sanguine Court!")),
     ("ravensmoor", 4, 900, [], cap("Vampires, Bats,", "Werewolves,", "*Witches!")),
     ("castle_sanguis", 4, 1040, [], cap("Face Queen", "*Carmilla!"))],
 # Day 9: five spell evolutions on five stages from four acts (confirmed by headless scouting runs, --timeout=840 summary)
 9: [("graveyard", 6, 640, ["--policy=evolve", "--spells=bone_spear,soul_siphon"], cap("Ossuary Lance,", "*Soul Rapture!")),  # ossuary_lance @8:11, soul_rapture @8:42
     ("crimson_march", 6, 640, ["--policy=evolve", "--spells=corpse_explosion,plague_cloud"], cap("Grave Eruption,", "*Pestilence!")),  # grave_eruption @8:02, pestilence @8:41
     ("harbour", 4, 640, ["--policy=evolve", "--spells=undertow"], cap("Undertow Becomes", "*Maelstrom!")),  # maelstrom @8:30
     ("wastes", 4, 640, ["--policy=evolve", "--spells=death_ray"], cap("Death Ray Becomes", "*Event Horizon!")),  # event_horizon @8:55
     ("olympus", 4, 760, ["--policy=evolve", "--spells=stolen_thunder"], cap("Stolen Thunder", "Becomes", "*Gigantomachy!"))],  # gigantomachy @8:03
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
            sec = CLIP_SEC.get(n, SEC)
            s = {"id": "s%d" % i, "stage": stage, "seed": seed, "start": start, "seconds": sec}
            if extra:
                s["extra"] = extra
            if n not in CAPTIONS:
                s["texts"] = []  # captions switched off for this clip (see CAPTIONS)
            elif i == 0 and n in INTRO:
                intro, t_intro = INTRO[n]
                s["texts"] = texts(intro, t_intro) + texts(c, sec, t_intro)
            else:
                s["texts"] = texts(c, sec)
            out.append(s)
        out.append(END)
        spec = {"name": "day%02d" % n, "render": [1080, 1920], "size": [1080, 1920], "fps": 30, "lufs": -14, "art_scale": 2, "shots": out}
        json.dump(spec, open(os.path.join(HERE, "day%02d.json" % n), "w"), indent=1)
