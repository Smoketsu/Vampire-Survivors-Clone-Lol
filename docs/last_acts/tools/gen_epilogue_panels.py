"""gen_epilogue_panels.py: make the reorder pass's epilogue picture panels (docs/last_acts/EPILOGUE_PANELS.md).

Usage (repo root): python3 docs/last_acts/tools/gen_epilogue_panels.py <panel id>... [--y-bias F] [--drop a,b]
For each id: writes art_source/epilogue/<id>.txt (shared STYLE block + the brief's scene), runs tools/gen_image.py
(1536x1024, refs: a sheet of the necromancer and a skeleton, the act4_1 panel; REDO ids also their old panel),
then tools/epilogue_panel.py. The three redone existing panels (REDO) keep the old source as <id>_old.png.
"""
import re, subprocess, sys, shutil, argparse
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "art_source" / "epilogue"
STYLE = re.search(r"\n\n(STYLE .*?)\n\nAttached", (SRC / "close_act4.txt").read_text(), re.S).group(1)
REDO = {
    "act1_3": ('SCENE: "The army drifted toward the coast, where a fleet of corsairs circled the Covenant\'s cathedral gold." A wide night scene on high sea cliffs, the same composition as the attached old picture (a cliff path down to the shore on the left, the necromancer with his flame staff standing on a rock at the cliff edge, a pale moon) but the glow under the sea is GONE: instead the black sea (#06151A, #1B4650) is dotted with a drifting fleet of galleons with cream sails and amber lantern light (#E0A92E, #FF8C26), gold glinting in an open hold, one far ship with a black flag. A column of skeleton warriors and archers walks down the cliff path toward the shore. No eye, no teal or violet glow in the sea.', ["act1_3_old"]),
    "close": ('SCENE: "The Eye lit its beacons, and something far across the dark saw them." A wide night composition. A chain of tall stone beacon towers, each topped with a big orange fire (#FF8C26, #FFDC66), runs across dark hills and a black sea toward the horizon, getting smaller. Far on the horizon at the right edge, a single thin RED signal light (#C71A29) and a tiny dark antenna tower, watching, nothing else clearly shown. A faint starry deep-blue sky (#0F141C, #243A99). No knights, no soldiers, no necromancer, no figures at all, no text.', []),
    "close_act4": ('SCENE: "The last city has fallen and its last hero with it. Across the eastern sea, a goddess opens her eyes." Same composition as the attached old picture: across a dark eastern sea a huge RED SUN (#C71A29, #FF8C26, thin gold rim #FFDC66) rises on the horizon in front of a large lacquered red TORII gate standing in the shallow water, and in the sky above the sun a giant pair of calm gold-white almond EYES opens in the clouds (#FFFAE8, #FFDC66). But the DIM FOREGROUND is changed: instead of Olympus marble and a throne, a ruined city street at the shore in dark blue-grey: cracked asphalt, a toppled lamppost, a burnt-out car, a fallen hero\'s tattered cape (blue and gold) and a broken round shield lying on the road. No necromancer, no living figures, no text.', ["close_act4_old"]),
}

def brief(pid):
    md = (ROOT / "docs/last_acts/EPILOGUE_PANELS.md").read_text()
    m = re.search(r"- `epilogue/%s`[^:]*?: (.*?)(?: Pan Vector2| Paragraph:|\n)" % re.escape(pid), md)
    m2 = re.search(r"- `epilogue/%s` \(closing card \"([^\"]+)\"[^:]*\): (.*?)(?: Pan Vector2|\n)" % re.escape(pid), md)
    if m2:
        return f'SCENE: closing card "{m2.group(1)}". A wide picture. {m2.group(2)}'
    para = re.search(r"- `epilogue/%s`:.*?Paragraph: \"(.*?)\"\n" % re.escape(pid), md, re.S)
    return f'SCENE: "{para.group(1) if para else ""}" A wide picture. {m.group(1)}'

def refsheet():
    out = ROOT / "art_source/epilogue/raw/refsheet.png"
    if not out.exists():
        ims = [Image.open(ROOT / p).convert("RGBA") for p in ("assets/sprites/player/necromancer.png", "assets/sprites/summons/warrior.png")]
        ims = [i.resize((i.width * 5, i.height * 5), Image.NEAREST) for i in ims]
        sheet = Image.new("RGBA", (sum(i.width for i in ims) + 60, max(i.height for i in ims) + 40), (15, 20, 28, 255))
        x = 20
        for i in ims:
            sheet.alpha_composite(i, (x, 20)); x += i.width + 20
        out.parent.mkdir(exist_ok=True); sheet.save(out)
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="+"); ap.add_argument("--y-bias", default="0.5"); ap.add_argument("--drop", default="skin,ice")
    ap.add_argument("--extra", default="", help="extra scene text appended (a retry)")
    a = ap.parse_args()
    for pid in a.ids:
        refs = [str(refsheet()), str(ROOT / "assets/sprites/epilogue/act4_1.png")]
        if pid in REDO:
            scene, olds = REDO[pid]
            old = SRC / f"{pid}_old.png"
            if not old.exists():
                shutil.copy(SRC / f"{pid}.png", old)
            refs += [str(old)]
        else:
            scene = brief(pid)
        att = "Attached: a sheet with the necromancer and a skeleton warrior sprite of this game (for their exact look), and one panel of this game for pixel size, outline weight and dark mood." + (" The third attached picture is the OLD version of this panel." if pid in REDO else "")
        (SRC / f"{pid}.txt").write_text(f"{scene} {a.extra}\n\n{STYLE}\n\n{att} Make one single wide 3:2 picture.")
        cmd = [sys.executable, "tools/gen_image.py", f"art_source/epilogue/{pid}.txt", f"art_source/epilogue/{pid}.png", "--key", f"epilogue/{pid}", "--size", "1536x1024"]
        for r in refs: cmd += ["--ref", r]
        subprocess.run(cmd, cwd=ROOT, check=True)
        subprocess.run([sys.executable, "tools/epilogue_panel.py", f"art_source/epilogue/{pid}.png", pid, "--y-bias", a.y_bias, "--drop", a.drop], cwd=ROOT, check=True)

if __name__ == "__main__":
    main()
