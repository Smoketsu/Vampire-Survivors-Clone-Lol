"""Act IV art review, round 2 and later: each image the owner flagged in the previous round (a Redo, or a note with
no mark), redone and shown next to its previous version with the owner's note, plus any other image the redo changed
("Changed with them"). Marks go in the db collection act4_art_r<round>. Adapted from
docs/act3/tools/make_act3_review_r2.py.

Usage: python3 docs/act4/tools/make_act4_review_r2.py <previous marks dir> <out.html> <before rev> [<round>]
  <previous marks dir>: the JSON files of an ArtifactData `list` of the previous round's collection with `out_dir`
  (one per review id). <before rev>: the commit holding the previous round's images; <round> (default 2).
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
import make_act4_review as r1  # noqa: E402  (round 1's helpers: bible(), describe(), b64(), frames_of(), scale_for(), order())
from PIL import Image  # noqa: E402

BEFORE_REV = ""  # The commit holding the previous round's images (argument 3).
COLLECTION = "act4_art_r2"  # db collection this round's marks are saved in.


def old(key: str) -> bytes | None:
    """The round 1 PNG of `key`, or None when it did not exist then."""
    r = subprocess.run(["git", "show", "%s:assets/sprites/%s.png" % (BEFORE_REV, key)], capture_output=True)
    return r.stdout if r.returncode == 0 and r.stdout else None


def fig(data: bytes, label: str, cls: str, s: int, key: str) -> str:
    """One labelled image of a card (the template animates strips from data-frames)."""
    w, h = Image.open(io.BytesIO(data)).size
    return '<figure class="%s"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>%s</figcaption></figure>' % (
        cls, r1.b64(data), w * s, h * s, html.escape(key + " " + label), label)


def card(key: str, group: str, what: str, note: str, before: bytes | None) -> str:
    """A review card: the new image, the round 1 one beside it, and the owner's round 1 note."""
    now = open(os.path.join("assets/sprites", key + ".png"), "rb").read()
    w, h = Image.open(io.BytesIO(now)).size
    frames = r1.frames_of(key, w, h)
    s = r1.scale_for(key, w, h, frames)
    stage = fig(now, "Now", "now", s, key) + (fig(before, "Before", "was", s, key) if before else "")
    kind = ("walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else
            "effect strip" if frames > 1 else "icon" if key.startswith("icons/") else "floor tile" if key.startswith("tiles/")
            else "still")
    meta = "%d×%d px" % (w, h) + (" · %d frames" % frames if frames > 1 else "") + " · shown ×%d" % s
    info = '<p class="subject">%s</p>' % html.escape(what)
    if note:
        info += '<p class="prev-note">Your note: %s</p>' % html.escape(note)
    cid = key.replace("/", "__")
    name = os.path.basename(key).replace("_", " ").capitalize()
    width = w * s * (2 if before else 1)
    return ('<article class="card%s" data-id="%s" data-owner="%s" data-frames="%d" data-w="%d" data-h="%d" data-s="%d">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">%s</p><p class="meta">%s</p>%s'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (" wide" if width > 560 else "", cid, group, frames, w, h, s, stage, html.escape(name),
                                   kind, html.escape(key), meta, info, html.escape(name), cid, cid)


def main() -> None:
    global BEFORE_REV, COLLECTION
    marks_dir, out, BEFORE_REV = sys.argv[1], sys.argv[2], sys.argv[3]
    rnd = int(sys.argv[4]) if len(sys.argv) > 4 else 2  # Review round this page is.
    COLLECTION = "act4_art_r%d" % rnd
    marks = {}  # Previous round's review id -> {verdict, note}.
    for f in glob.glob(os.path.join(marks_dir, "*.json")):
        d = json.load(open(f))
        marks[os.path.basename(f)[:-5]] = d.get("data", d)
    rows = r1.bible()  # ART_BIBLE descriptions by key.
    redo = []  # Keys flagged last round (a Redo, or a note with no mark); concept lineups are not sprites.
    for cid, d in marks.items():
        if cid.startswith("concepts__"):
            continue
        if d.get("verdict") == "redo" or (not d.get("verdict") and (d.get("note") or "").strip()):
            redo.append(cid.replace("__", "/"))
    changed = subprocess.run(["git", "diff", "--name-only", BEFORE_REV, "HEAD", "--", "assets/sprites/*.png"],
                             capture_output=True, text=True, check=True).stdout.split()
    extra = sorted((p[len("assets/sprites/"):-4] for p in changed
                    if p[len("assets/sprites/"):-4] not in redo and os.path.exists(p)), key=r1.order)
    redo.sort(key=r1.order)
    note_of = {k: (marks[k.replace("/", "__")].get("note") or "").strip() for k in redo}
    groups = [
        ("redo", "Redone", "The images you flagged, new next to the last round. Strips animate both.",
         [card(k, "redo", r1.describe(k, rows), note_of[k], old(k)) for k in redo]),
        ("extra", "Changed with them", "Images you had approved that changed with the fixes (e.g. a shared sheet).",
         [card(k, "extra", r1.describe(k, rows), "", old(k)) for k in extra]),
    ]
    groups = [g for g in groups if g[3]]
    parts = []
    for g, label, blurb, cards in groups:
        parts.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                     '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                     % (g, label, blurb, g, "\n".join(cards)))
    total = sum(len(c) for _, _, _, c in groups)
    page = open(r1.TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act IV Art Review</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act IV Art Review</h1>")
            .replace("{{LEDE}}", ("Round %d: the %d images you flagged, redone next to their round %d version" % (rnd, len(redo), rnd - 1))
                     + (", and %d more that changed with them" % len(extra) if extra else "") + ". Mark each one OK or Redo.")
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l, _, _ in groups))
            .replace("{{CARDS}}", "\n".join(parts)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps({g: len(c) for g, _, _, c in groups})))
    open(out, "w", encoding="utf-8").write(page)
    print(total, "items:", len(redo), "redone,", len(extra), "changed with them,", len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
