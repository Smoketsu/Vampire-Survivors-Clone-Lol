"""Act IX art review, round 2: each image the owner flagged in round 1 (a Redo, or a note with no mark), redone and
shown next to its round 1 version with the owner's note. Marks go in the db collection act9_art_r2. Modelled on
docs/act8/tools/make_act8_review_r2.py (the card markup is the same; round 1's helpers come from make_act9_review.py,
but the descriptions, strip frame counts and the template are read from the merged worktree / main here).

Usage: python3 docs/act9/tools/make_act9_review_r2.py <round 1 marks dir> <out.html> <before rev>
  <round 1 marks dir>: the JSON files of an ArtifactData `list` of act9_art_r1 (one per review id; the mark may sit at the
  top level or under `data`). <before rev>: the commit holding the round 1 images (the merge base of the redo branches).
Run from the repository root on the merged tree.
"""
import glob
import html
import io
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_act9_review as r1  # noqa: E402  (round 1's helpers: b64(), scale_for(), order(), show())
from PIL import Image  # noqa: E402

BEFORE_REV = ""  # The commit holding the round 1 images (argument 3).
COLLECTION = "act9_art_r2"  # db collection this round's marks are saved in.
# Short captions the lead asked for, by sprite key (shown under the description).
CAPTIONS = {
    "player/starborn_deathlord": "The face now reads more humanoid than the old grey alien head.",
    "effects/acid_pool": "The old PNG was a grey mask tinted in code; the colour is now in the image.",
}


def old(key: str) -> bytes | None:
    """The round 1 PNG of `key`, or None when it did not exist then."""
    r = subprocess.run(["git", "show", "%s:assets/sprites/%s.png" % (BEFORE_REV, key)], capture_output=True)
    return r.stdout if r.returncode == 0 and r.stdout else None


def bible() -> dict:
    """ART_BIBLE table rows (the merged worktree's file): backticked key -> description cell."""
    rows = {}
    for line in open("docs/art/ART_BIBLE.md", encoding="utf-8").read().splitlines():
        if not line.startswith("| `"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        for k in re.findall(r"`([^`]+)`", cells[0]):
            rows.setdefault(k, re.sub(r"`", "", cells[1]))
    return rows


def describe(key: str, rows: dict) -> str:
    """Best ART_BIBLE description of `key` (its own row, its base sprite's, or its family's)."""
    base = re.sub(r"_(walk|idle)$", "", key)
    fam = re.sub(r"_(s|m|l)(_v)?$", "", base)
    for k in (key, base, fam, fam + "_{s,m,l}", os.path.basename(fam)):
        if k in rows:
            extra = " (walk strip)" if key.endswith("_walk") else " (idle breathing strip)" if key.endswith("_idle") else ""
            return rows[k] + extra
    return os.path.basename(key).replace("_", " ").capitalize() + "."


def frames_of(key: str, w: int, h: int) -> int:
    """Frames in a strip (walk / idle strips by their still's width, effects square)."""
    if key.startswith("effects/"):
        return max(1, w // h)
    for suf in ("_walk", "_idle"):
        if key.endswith(suf):
            p = "assets/sprites/" + key[: -len(suf)] + ".png"
            if os.path.exists(p):
                return max(1, round(w / Image.open(p).size[0]))
    return 1


def fig(data: bytes, label: str, cls: str, s: int, key: str) -> str:
    """One labelled image of a card (the template animates strips from data-frames)."""
    w, h = Image.open(io.BytesIO(data)).size
    return '<figure class="%s"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>%s</figcaption></figure>' % (
        cls, r1.b64(data), w * s, h * s, html.escape(key + " " + label), label)


def card(key: str, what: str, note: str, before: bytes | None) -> str:
    """A review card: the new image, the round 1 one beside it, the owner's round 1 note and any caption."""
    now = open(os.path.join("assets/sprites", key + ".png"), "rb").read()
    w, h = Image.open(io.BytesIO(now)).size
    frames = frames_of(key, w, h)
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
    rows = bible()
    redo = [cid.replace("__", "/") for cid, d in marks.items() if not cid.startswith("concept")
            and (d.get("verdict") == "redo" or (not d.get("verdict") and (d.get("note") or "").strip()))]
    redo.sort(key=r1.order)
    cards = [card(k, describe(k, rows), (marks[k.replace("/", "__")].get("note") or "").strip(), old(k)) for k in redo]
    part = ('<section class="ws" id="redo"><header class="ws-head"><h2>Redone</h2><p class="ws-blurb">The images you flagged, '
            'new next to the last round. Strips animate both.</p><p class="ws-count" data-count="redo"></p></header>'
            '<div class="grid">%s</div></section>' % "\n".join(cards))
    page = r1.show(*r1.TEMPLATE_REF).decode("utf-8")
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act IX art review, round 2</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act IX art review, round 2</h1>")
            .replace("{{LEDE}}", "Round 2: the %d images you flagged, redone next to their round 1 version. Mark each one OK or Redo." % len(redo))
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", '<a href="#redo">Redone</a>')
            .replace("{{CARDS}}", part).replace("{{TOTAL}}", str(len(cards)))
            .replace("{{COUNTS}}", json.dumps({"redo": len(cards)})))
    open(out, "w", encoding="utf-8").write(page)
    print(len(cards), "items,", len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
