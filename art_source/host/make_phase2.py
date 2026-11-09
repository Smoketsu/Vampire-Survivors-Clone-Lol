#!/usr/bin/env python3
"""make_phase2.py: builds the Celestial Host's phase 2 sprites from art_source/host/raw (gen_phase2.py) like make_art.py: figures through
pixelate_source.py then tools/prepare_sprite.py (host_ ramps; the characters violet / bone / soul; the summon wheels bone / soul), then the
walk / glide / roll / idle strips (walk_cycle.py rigs "Act X slot" and roll_strip() below for the wheels). Usage (repo root):
python3 art_source/host/make_phase2.py [units] [strips]."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # Repo root.
HERE = Path(__file__).resolve().parent  # art_source/host.
HOST = "host_silver,host_cerulean,host_rose,host_cloud,host_skin"  # Host ramps.
CHAR = "violet,bone,soul,brown,grey"  # Necromancer ramps (as the Dynasty's characters).
BONE = "bone,soul"  # Summon wheels.
# raw id -> (sprite key, art height, ramps, pixelate first)
U = [("cherub", "host/cherub", 56, HOST, True), ("cherub_of_the_gate", "host/cherub_of_the_gate", 76, HOST, True),
     ("seraiel", "host/seraiel", 96, HOST, True), ("seraiel_raised", "host/seraiel_raised", 96, HOST, True),
     ("ophan", "host/ophan", 52, HOST, False), ("dominion_of_the_spheres", "host/dominion_of_the_spheres", 70, HOST, True),
     ("throne", "host/throne", 96, HOST, False), ("throne_open", "host/throne_open", 96, HOST, False),
     ("throne_core", "host/throne_core", 32, HOST, False), ("herald_of_the_seventh_trumpet", "host/herald_of_the_seventh_trumpet", 70, HOST, True),
     ("voice", "host/voice", 104, HOST, False), ("voice_unveiled", "host/voice_unveiled", 104, HOST, False),
     ("bound_ophan", "summons/bound_ophan", 30, BONE, False), ("throne_of_bones", "summons/throne_of_bones", 44, BONE, False),
     ("fallen_herald", "player/fallen_herald", 56, CHAR, False), ("blind_saint", "player/blind_saint", 56, CHAR, True),
     ("the_unveiled", "player/the_unveiled", 56, CHAR, True)]
PAD = ["host/cherub", "host/cherub_of_the_gate", "host/voice"]  # Hovering creatures.
TURN = ["host/throne"]  # Wheels turned frame by frame; the others squeeze.
ROLLS = {"host/ophan": 8, "host/throne": 8, "summons/bound_ophan": 8, "summons/throne_of_bones": 8}  # Wheels: roll strips (turned copies), degrees of one full symmetry step.


def run(a: list) -> None:
    print("+", " ".join(a), flush=True)
    subprocess.run([sys.executable] + a, cwd=ROOT, check=True)


def units() -> None:
    for raw, key, h, ramps, pix in U:
        src = HERE / "raw" / (raw + ".png")
        extra = ["--no-prune"]
        if pix:
            p = HERE / "_work" / (raw + ".png")
            p.parent.mkdir(exist_ok=True)
            run(["tools/pixelate_source.py", str(src), str(h), str(p)])
            src, extra = p, ["--no-cleanup", "--no-prune", "--no-levels"]
        run(["tools/prepare_sprite.py", str(src), key, "--art-height", str(h), "--ink-l", "0.15", "--ramps", ramps] + extra)
        if key in PAD:  # Hover strips need 2 empty rows on top for the bob (HEIGHTS carries the 2 extra rows).
            from PIL import Image
            out = ROOT / "assets/sprites" / (key + ".png")
            im = Image.open(out).convert("RGBA")
            pd = Image.new("RGBA", (im.width, im.height + 2), (0, 0, 0, 0))
            pd.paste(im, (0, 2))
            pd.save(out)
        (HERE / (raw + ".png")).unlink(missing_ok=True)


def roll_strip(key: str) -> None:
    """8 frames side by side, the wheel turned k * (360 / 8 / 8) degrees (a wheel with 8 eyes repeats every 45 degrees); the frame is the still's canvas."""
    from PIL import Image
    im = Image.open(ROOT / "assets/sprites" / (key + ".png")).convert("RGBA")
    n = ROLLS[key]
    S = max(im.size)
    S += S % 2
    sq = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sq.paste(im, ((S - im.width) // 2, (S - im.height) // 2))
    out = Image.new("RGBA", (S * n, S), (0, 0, 0, 0))
    for i in range(n):
        if key in TURN:  # Near-round wheel: turn it.
            fr = sq.rotate(-i * 45.0 / n, resample=Image.NEAREST)
        else:  # Upright ellipse (turning it would change its silhouette): a rolling squeeze, 1.0 / 0.94 / 0.88 / 0.94 wide.
            w = round(S * (1.0, 0.94, 0.88, 0.94)[i % 4])
            fr = Image.new("RGBA", (S, S), (0, 0, 0, 0))
            fr.paste(sq.resize((w, S), Image.NEAREST), ((S - w) // 2, 0))
        out.paste(fr, (i * S, 0))
    out.save(ROOT / "assets/sprites" / (key + "_walk.png"))


def strips() -> None:
    walk = ["host/cherub", "host/cherub_of_the_gate", "host/seraiel", "host/dominion_of_the_spheres", "host/herald_of_the_seventh_trumpet",
            "host/voice", "player/fallen_herald", "player/blind_saint", "player/the_unveiled"]
    run(["tools/walk_cycle.py", "build"] + walk)
    run(["tools/walk_cycle.py", "idle", "player/blind_saint", "player/the_unveiled"])
    for k in ROLLS:
        roll_strip(k)


if __name__ == "__main__":
    for s in sys.argv[1:] or ["units", "strips"]:
        globals()[s]()
