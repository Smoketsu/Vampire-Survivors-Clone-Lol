"""Act VIII art review, round 2: each image the owner flagged in round 1 (a Redo, or a note with no mark), redone and
shown next to its round 1 version with the owner's note. Marks go in the db collection act8_art_r2. Adapted from
docs/act6/tools/make_act6_review_r2.py (the two share the card markup; round 1's helpers come from make_act8_review.py).

Usage: python3 docs/act8/tools/make_act8_review_r2.py <round 1 marks dir> <out.html> <before rev>
  <round 1 marks dir>: the JSON files of an ArtifactData `list` of act8_art_r1 (one per review id; the mark may sit at the
  top level or under `data`). <before rev>: the commit holding the round 1 images (the merge base of the redo branches).
Run from the repository root on the merged tree.
"""
import glob
import html
import io
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_act8_review as r1  # noqa: E402  (round 1's helpers: bible(), describe(), b64(), frames_of(), scale_for(), order())
from PIL import Image  # noqa: E402

BEFORE_REV = ""  # The commit holding the round 1 images (argument 3).
COLLECTION = "act8_art_r2"  # db collection this round's marks are saved in.
# Short captions the lead asked for, by sprite key (shown under the description).
CAPTIONS = {
    "city/armoured_limo_walk": "Wheel spin is subtle: the stills barely draw the wheels; a redrawn still would show it better.",
    "city/squad_car_walk": "Wheel spin is subtle: the stills barely draw the wheels; a redrawn still would show it better.",
    "city/civilian_woman_idle": "Keeps a 1 px breathing sink; say if it should be fully still.",
}


def old(key: str) -> bytes | None:
    """The round 1 PNG of `key`, or None when it did not exist then."""
    r = subprocess.run(["git", "show", "%s:assets/sprites/%s.png" % (BEFORE_REV, key)], capture_output=True)
    return r.stdout if r.returncode == 0 and r.stdout else None


def fig(data: bytes, label: str, cls: str, s: int, key: str) -> str:
    """One labelled image of a card (the template animates strips from data-frames)."""
    w, h = Image.open(io.BytesIO(data)).size
    return '<figure class="%s"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>%s</figcaption></figure>' % (
        cls, r1.b64(data), w * s, h * s, html.escape(key + " " + label), label)


def card(key: str, what: str, note: str, before: bytes | None) -> str:
    """A review card: the new image, the round 1 one beside it, the owner's round 1 note and any caption."""
    now = open(os.path.join("assets/sprites", key + ".png"), "rb").read()
    w, h = Image.open(io.BytesIO(now)).size
    frames = r1.frames_of(key, w, h)
    s = r1.scale_for(key, w, h, frames)
    stage = fig(now, "Now", "now", s, key) + (fig(before, "Before", "was", s, key) if before else "")
    kind = "walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else "still"
    meta = "%d×%d px" % (w, h) + (" · %d frames" % frames if frames > 1 else "") + " · shown ×%d" % s
    info = '<p class="subject">%s</p>' % html.escape(what)
    if note:
        info += '<p class="prev-note">Your note: %s</p>' % html.escape(note)
    if key in CAPTIONS:
        info += '<p class="prev-note">%s</p>' % html.escape(CAPTIONS[key])
    cid = key.replace("/", "__")
    name = os.path.basename(key).replace("_", " ").capitalize()
    width = w * s * (2 if before else 1)
    return ('<article class="card%s" data-id="%s" data-owner="redo" data-frames="%d" data-w="%d" data-h="%d" data-s="%d">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">%s</p><p class="meta">%s</p>%s'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (" wide" if width > 560 else "", cid, frames, w, h, s, stage, html.escape(name),
                                   kind, html.escape(key), meta, info, html.escape(name), cid, cid)


def main() -> None:
    global BEFORE_REV
    marks_dir, out, BEFORE_REV = sys.argv[1], sys.argv[2], sys.argv[3]
    marks = {}  # Round 1 review id -> {verdict, note}.
    for f in glob.glob(os.path.join(marks_dir, "*.json")):
        d = json.load(open(f))
        marks[os.path.basename(f)[:-5]] = d.get("data", d)
    rows = r1.bible()
    redo = [cid.replace("__", "/") for cid, d in marks.items() if not cid.startswith("concepts__")
            and (d.get("verdict") == "redo" or (not d.get("verdict") and (d.get("note") or "").strip()))]
    redo.sort(key=r1.order)
    cards = [card(k, r1.describe(k, rows), (marks[k.replace("/", "__")].get("note") or "").strip(), old(k)) for k in redo]
    part = ('<section class="ws" id="redo"><header class="ws-head"><h2>Redone</h2><p class="ws-blurb">The images you flagged, '
            'new next to the last round. Strips animate both.</p><p class="ws-count" data-count="redo"></p></header>'
            '<div class="grid">%s</div></section>' % "\n".join(cards))
    page = open(r1.TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act VIII art review, round 2</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act VIII art review, round 2</h1>")
            .replace("{{LEDE}}", "Round 2: the %d images you flagged, redone next to their round 1 version. Mark each one OK or Redo." % len(redo))
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", '<a href="#redo">Redone</a>')
            .replace("{{CARDS}}", part).replace("{{TOTAL}}", str(len(cards)))
            .replace("{{COUNTS}}", json.dumps({"redo": len(cards)})))
    open(out, "w", encoding="utf-8").write(page)
    print(len(cards), "items,", len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
