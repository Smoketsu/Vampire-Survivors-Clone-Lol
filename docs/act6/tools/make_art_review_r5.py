"""Act VI and VII art review, round 5: the Ghoul, regenerated from scratch (the owner's one mark), redone and shown
next to its version from commit e1ec3da with the owner's note. Marks go in the db collection art_r5. Adapted from
docs/act6/tools/make_act6_review_r3.py.

Usage: python3 docs/act6/tools/make_art_review_r5.py <out.html> [<before rev>]
  <before rev> (default e1ec3da): the commit holding the previous versions. Run from the repository root on the merged tree.
"""
import html
import json
import io
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_act6_review as r1  # noqa: E402  (round 1's helpers: bible(), describe(), b64(), frames_of(), scale_for(), order())
from PIL import Image  # noqa: E402

BEFORE_REV = "e1ec3da"  # The commit holding the previous versions (argument 2).
COLLECTION = "art_r5"  # db collection this round's marks are saved in.
TITLE = "Ghoul, regenerated"  # Page title and heading.
# The four groups in display order: (id, heading, blurb, [(key, the owner's note, what changed)]).
GROUPS = [
    ("ghoul", "Ghoul", "Regenerated from scratch with the approved Court sprites as style references, 38 px tall (was 30) so the face survives.",
     [("court/ghoul", "Looks like a completely different art style, regenerate this from scratch.",
       "A new image in the Court's own style (no hand painting): a big bald head carried high and forward, two big red eyes under a heavy brow, a hooked nose, jagged teeth and the long lolling tongue; hunched gaunt pale-grey body. Height raised 30 to 38 px."),
      ("court/ghoul_walk", "See above", "Rebuilt from the new still (legs rig refit for the taller sprite).")]),
]


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
    unchanged = before is not None and before == now  # Strips that already matched the approved still.
    if unchanged:
        what = "Unchanged: it already matched the approved still. " + what
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
    global BEFORE_REV
    out = sys.argv[1]
    if len(sys.argv) > 2:
        BEFORE_REV = sys.argv[2]
    groups = [(gid, label, blurb, [card(k, gid, what, note, old(k)) for k, note, what in items])
              for gid, label, blurb, items in GROUPS]
    parts = []
    for g, label, blurb, cards in groups:
        parts.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                     '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                     % (g, label, html.escape(blurb), g, "\n".join(cards)))
    total = sum(len(c) for _, _, _, c in groups)
    page = open(r1.TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>%s</title>" % TITLE)
            .replace("<h1>Act II Art Review</h1>", "<h1>%s</h1>" % TITLE)
            .replace("{{LEDE}}", "The Ghoul, redone next to its previous version (%d images). Mark each one OK or Redo." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l, _, _ in groups))
            .replace("{{CARDS}}", "\n".join(parts)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps({g: len(c) for g, _, _, c in groups})))
    open(out, "w", encoding="utf-8").write(page)
    print(total, "items,", len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
