#!/usr/bin/env python3
"""make_specs.py: writes tools/promo_specs/dayNN.json (the 16 daily TikTok clips) for tools/make_promo_clip.py.

Style (owner, Nov 2026: a solo dev's voice, no ad-style captions): each clip opens with ONE lowercase hook line (HOOKS) for
HOOK_SEC seconds, then plays clean gameplay with no text until the end card. The old per-shot captions stay in CLIPS and
INTRO behind the CAPTIONS switch (empty by default).

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
# Hook line style (all of it burned in by make_promo_clip.py's text renderer).
HOOK_FONT_SIZE = 38   # Jersey 10 native size (px): one of the game's type tiers (19 / 28 / 38 / 57)
HOOK_SCALE = 2        # integer enlargement of the hook text: 38 x 2 = 76 px, about 60-65% of the old 57 x 2 captions
HOOK_COLOR = "white"  # plain white (no gold key words); "white" is defined in make_promo_clip.py COLORS
HOOK_Y = 250          # top of the hook block in the 1080x1920 video (px): the upper third, below TikTok's top bar
HOOK_LINE_GAP = 84    # distance between the tops of the two hook lines (px): 38 x 2 plus a little air
HOOK_MAX_WIDTH = 838  # widest a hook line may be in the video (px): the safe zone x 80..918, clear of TikTok's buttons
HOOK_SEC = 2.2        # how long the hook line stays up from the start of the clip (s)
# Day number -> the hook line (lowercase, no exclamation marks, at most about 50 characters; wrapped to 2 lines by width).
HOOKS = {
 1: "my necromancer doesn't fight. his army does",
 2: "36 spells in my game. here are 5 of them",
 3: "made a whole act where hell comes to collect your souls",
 4: "every summon in my game evolves. here's 5 of them",
 5: "the sun sets mid-run and the ninjas come out",
 6: "every stage ends with a boss fight",
 7: "25 summon classes in my game. here's a few",
 8: "act 7 is all vampires, werewolves and witches",
 9: "every spell evolves too",
 10: "the living fight back. police, then army, then superheroes",
 11: "at 0:00 the game stops being fair",
 12: "the greek gods hit both armies",
 13: "36 characters, each starts with their own spell",
 14: "aliens show up to abduct your undead",
 15: "the tide rises, the island sinks, the machines take aim",
 16: "what a full horde looks like around minute 18",  # shots start at 16:40, 18:00 and 19:20 of the run
}


def cap(*lines):
    """Caption lines: a line starting with '*' is the gold key line."""
    return [(l[1:], GOLD) if l.startswith("*") else (l, CREAM) for l in lines]


def hook(line, dur):
    """Text entries for a clip's hook line: lowercase, plain white, wrapped to at most 2 lines by width, shown 0..dur (s)."""
    font = ImageFont.truetype(os.path.join(HERE, "../../assets/fonts/Jersey10-Regular.ttf"), HOOK_FONT_SIZE)
    width = lambda t: font.getbbox(t)[2] * HOOK_SCALE
    assert line == line.lower() and "!" not in line, "hook must be lowercase without exclamation marks: " + line
    lines = [line]
    if width(line) > HOOK_MAX_WIDTH:  # split at the space that balances the two lines best
        words = line.split(" ")
        best = min(range(1, len(words)), key=lambda k: max(width(" ".join(words[:k])), width(" ".join(words[k:]))))
        lines = [" ".join(words[:best]), " ".join(words[best:])]
    assert len(lines) <= 2 and all(width(l) <= HOOK_MAX_WIDTH for l in lines), "hook too wide: " + line
    return [{"text": l, "font": "jersey", "size": HOOK_FONT_SIZE, "scale": HOOK_SCALE, "color": HOOK_COLOR,
             "y": HOOK_Y + HOOK_LINE_GAP * i, "from": 0.0, "to": dur} for i, l in enumerate(lines)]


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
# Clip numbers whose gameplay shots carry the old burned-in captions (intro title and per-shot names). Owner, Nov 2026: the
# big caption text looks cheesy, so no clip uses them now (hook line and end card only); the captions stay in CLIPS
# and INTRO, so a new caption style can be added later without re-picking shots: put the day number in this set.
CAPTIONS = set()  # was {1, 2, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16} for the old ad-style captions; the hook line (HOOKS) replaces them
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

# End card: logo, then two lowercase white lines in the same quiet style as the hook (same size, tier and colour).
END = {"id": "end", "stage": "graveyard", "seed": 3, "start": 900, "seconds": 3.2, "dim": 0.6,
       "logo": {"y": 520, "scale": 3, "from": 0.0, "to": 3.2},
       "texts": [{"text": "free in your browser", "font": "jersey", "size": HOOK_FONT_SIZE, "scale": HOOK_SCALE, "color": HOOK_COLOR, "y": 960, "from": 0.3, "to": 3.2},
                 {"text": "link in bio", "font": "jersey", "size": HOOK_FONT_SIZE, "scale": HOOK_SCALE, "color": HOOK_COLOR, "y": 960 + HOOK_LINE_GAP, "from": 0.7, "to": 3.2}]}

if __name__ == "__main__":
    for n, shots in CLIPS.items():
        out = []
        for i, (stage, seed, start, extra, c) in enumerate(shots):
            sec = CLIP_SEC.get(n, SEC)
            s = {"id": "s%d" % i, "stage": stage, "seed": seed, "start": start, "seconds": sec}
            if extra:
                s["extra"] = extra
            if n not in CAPTIONS:
                s["texts"] = hook(HOOKS[n], HOOK_SEC) if i == 0 else []  # captions off (see CAPTIONS): the hook line only
            elif i == 0 and n in INTRO:
                intro, t_intro = INTRO[n]
                s["texts"] = texts(intro, t_intro) + texts(c, sec, t_intro)
            else:
                s["texts"] = texts(c, sec)
            out.append(s)
        out.append(END)
        spec = {"name": "day%02d" % n, "render": [1080, 1920], "size": [1080, 1920], "fps": 30, "lufs": -14, "art_scale": 2, "shots": out}
        json.dump(spec, open(os.path.join(HERE, "day%02d.json" % n), "w"), indent=1)
