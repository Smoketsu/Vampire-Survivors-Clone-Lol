"""Act VI and VII art review, round 4 ("the last redos"): the owner's four remaining marks, each image redone and shown
next to its version from commit e1ec3da with the owner's note. Marks go in the db collection art_r4. Adapted from
docs/act6/tools/make_act6_review_r3.py.

Usage: python3 docs/act6/tools/make_art_review_r4.py <out.html> [<before rev>]
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
COLLECTION = "art_r4"  # db collection this round's marks are saved in.
TITLE = "Act VI and VII art review: the last redos"  # Page title and heading.
# The four groups in display order: (id, heading, blurb, [(key, the owner's note, what changed)]).
GROUPS = [
    ("succubus", "Succubus wing flap", "Her bat wings now beat gently on the walk and the idle; bust rig and arm exclusion kept.",
     [("inferno/succubus_walk", "Can we get a lil wing flap here too?", "A small wing flap (about 7 degrees) on both wings."),
      ("inferno/succubus_idle", "See above", "The same flap, slower, on the idle.")]),
    ("saint", "Fallen Saint Deathlord", "Regenerated from the base Fallen Saint: the same iron-grey and crimson scheme, more tonal variance.",
     [("player/fallen_saint_deathlord", "Re generate this entirely. It's a good color scheme but needs a bit more variance.",
       "New still: distinct light, mid and dark shades per material (steel, slate and near-black cloth; three reds; brown hair)."),
      ("player/fallen_saint_deathlord_idle", "See above", "Rebuilt from the new still."),
      ("player/fallen_saint_deathlord_walk", "See above", "Rebuilt from the new still.")]),
    ("queen", "Hyper Succubus Queen", "The black feathered wings are back, with a halo above her head.",
     [("player/succubus_queen_hyper", "this isn't as good as the black wings version. Can you add a halo to the black wings version and show me that?",
       "The black wings with gold tips restored, a thin gold halo added (the canvas grew 6 rows to fit it)."),
      ("player/succubus_queen_hyper_idle", "See above", "Rebuilt with the halo; bust box and arm exclusion refit."),
      ("player/succubus_queen_hyper_walk", "See above", "Rebuilt with the halo; bust box and arm exclusion refit.")]),
    ("ghoul", "Ghoul", "The head is bigger and carried forward; the face reads, and the long tongue stays.",
     [("court/ghoul", "When we added the longer tongue we lost some definition in his face. His head should be clearly visible",
       "A bigger head clear of the shoulders: brow, red eyes in dark sockets, teeth and jaw, with the long tongue."),
      ("court/ghoul_walk", "See above", "Rebuilt from the new still.")]),
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
            .replace("{{LEDE}}", "The %d images from your last marks, redone next to their previous version. Mark each one OK or Redo." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l, _, _ in groups))
            .replace("{{CARDS}}", "\n".join(parts)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps({g: len(c) for g, _, _, c in groups})))
    open(out, "w", encoding="utf-8").write(page)
    print(total, "items,", len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
