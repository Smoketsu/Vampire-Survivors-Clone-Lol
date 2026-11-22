#!/usr/bin/env python3
"""make_specs2.py: writes tools/promo_specs/batch2/dayNN.json (the second batch of 14 daily TikTok clips) for tools/make_promo_clip.py.

Same style as batch 1 (make_specs.py, whose hook() and END card it reuses): one lowercase hook line over the first shot, then
clean gameplay, then the shared end card. Every shot is recorded SHOT_SEC long; tools/promo_quickcut.py keeps 1.5 s of each
later shot. Lesson from batch 1: every shot must show what the hook says, so each shot lists the autotest args that put the
named subject on screen (--spawn=, --character=, --spells=, --classes=) and a note of what was confirmed in the frames.
Run: python3 tools/promo_specs/make_specs2.py
Render one day: python3 tools/make_promo_clip.py --spec tools/promo_specs/batch2/day01.json --out <dir> --work <cache dir> --jobs 1
Then:           python3 tools/promo_quickcut.py <spec> <out>/dayNN.mp4 <final.mp4> [maxcuts]
"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from make_specs import hook, END, HOOK_SEC  # batch 1's hook line renderer, end card and hook length (s)

SHOT_SEC = 3.0  # length of every recorded shot (s of game time = s of video); the quick cut keeps 1.5 s of it from 0.4 s in
ART = 3         # art scale for every clip (1 art px = 3 video px, a 360x640 view): small subjects stay big in frame

# Day number -> {"hook": hook line, "cuts": later shots the quick cut keeps, "shots": [(stage, seed, start second, extra args, what is shown)]}
DAYS = {}


def add(n, hook_line, cuts, shots):
    """Registers clip n: its hook line, how many later shots the quick cut keeps (maxcuts) and its shot list."""
    DAYS[n] = {"hook": hook_line, "cuts": cuts, "shots": shots}


exec(open(os.path.join(HERE, "batch2_days.py")).read())  # the clips themselves (kept in their own file so each can be re-scouted alone)

if __name__ == "__main__":
    os.makedirs(os.path.join(HERE, "batch2"), exist_ok=True)
    for n, d in DAYS.items():
        shots = []
        for i, (stage, seed, start, extra, _note) in enumerate(d["shots"]):
            s = {"id": "s%d" % i, "stage": stage, "seed": seed, "start": start, "seconds": SHOT_SEC}
            if extra:
                s["extra"] = extra
            s["texts"] = hook(d["hook"], HOOK_SEC) if i == 0 else []
            shots.append(s)
        shots.append(END)
        spec = {"name": "day%02d" % n, "render": [1080, 1920], "size": [1080, 1920], "fps": 30, "lufs": -14, "art_scale": ART, "cuts": d["cuts"], "shots": shots}
        json.dump(spec, open(os.path.join(HERE, "batch2", "day%02d.json" % n), "w"), indent=1)
