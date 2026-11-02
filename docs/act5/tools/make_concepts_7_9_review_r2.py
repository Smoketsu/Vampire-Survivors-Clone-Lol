"""Concept art review, round 2, for Act IX: the two images the owner marked Redo (lineup, boss), each new version beside
its r1 version with the owner's note (db collection concepts_7_9_r2). Images are downscaled to 1024 px wide JPEG data URIs.

Usage: python3 docs/act5/tools/make_concepts_7_9_review_r2.py <out.html>
Run from the repository root (adapted from make_concepts_7_9_review.py; same card markup, so the shared template works).
"""
import base64
import html
import io
import json
import os
import sys
from PIL import Image

REPO = os.getcwd()  # Repository root.
TEMPLATE = os.path.join(REPO, "docs/act3/tools/art_review_template.html")  # The shared review page template.
COLLECTION = "concepts_7_9_r2"  # db collection the owner's marks are saved in.
WIDTH = 1024  # Embedded image width in px.
QUALITY = 85  # JPEG quality of the embedded images.
LEDE = ("Round 2 of the Act IX concept art: the two you marked Redo, new on the right of the old one. "
        "Mark each OK or Redo with a note.")  # Page lede.
# Items: (image, card title, owner's r1 note, what changed).
ITEMS = [
    ("act9_lineup", "Lineup", "Can the bug boss lady from the last round of concept art make it in here?",
     "Now ten figures: the Hive Mother joins, drawn from her earlier concept (a vast insect queen, a woman in figure style, "
     "fully covered in purple chitin with horns, spined wings and an egg-sac abdomen), the largest of the row, beside the Prism."),
    ("act9_boss", "Boss", "There is just a big archer summon on the right.",
     "The stray archer is gone: the right side is now the Vrask hunter with his glaive, the Brood queen-guard on the left, "
     "and only the necromancer's small skeleton army at the bottom."),
]


def data_uri(path: str):
    """Downscale an image to WIDTH px and return (JPEG data URI, w, h, source w, source h)."""
    im = Image.open(path).convert("RGB")
    ow, oh = im.size
    im = im.resize((WIDTH, round(oh * WIDTH / ow)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=QUALITY, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode(), im.size[0], im.size[1], ow, oh


def card(img: str, title: str, note: str, what: str) -> str:
    """One review card: the old r1 and the new image side by side, the owner's note, OK / Redo and a note box."""
    d = os.path.join(REPO, "art_source/concepts")
    old, w, h, ow, oh = data_uri(os.path.join(d, img + "_r1.png"))
    new = data_uri(os.path.join(d, img + ".png"))[0]
    name = "Act 9 " + title.lower()
    return ('<article class="card wide" data-id="%s" data-owner="act9" data-frames="1" data-w="%d" data-h="%d" data-s="1">'
            '<div class="stage"><div class="ba">'
            '<figure class="was"><img src="%s" width="%d" height="%d" alt="%s, round 1"><figcaption>Round 1</figcaption></figure>'
            '<figure class="now"><img src="%s" width="%d" height="%d" alt="%s, round 2"><figcaption>Round 2</figcaption></figure>'
            '</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">concept</span></div>'
            '<p class="key">art_source/concepts/%s.png</p><p class="meta">%d×%d px (source %d×%d)</p>'
            '<p class="subject"><b>Your note:</b> %s<br>%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (img, w, h, old, w, h, html.escape(name), new, w, h, html.escape(name),
                                   html.escape(title), img, w, h, ow, oh, html.escape(note), html.escape(what),
                                   html.escape(name), img, img)


def main() -> None:
    cards = [card(*i) for i in ITEMS]
    counts = {"act9": len(cards)}
    total = len(cards)
    sections = ['<section class="ws" id="act9"><header class="ws-head"><h2>Act IX: the Concord of Stars</h2>'
                '<p class="ws-blurb">Round 2: the two Redo marks.</p><p class="ws-count" data-count="act9"></p></header>'
                '<div class="grid">%s</div></section>' % "\n".join(cards)]
    page = open(TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Concept Art Review</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Concept Art Review</h1>")
            .replace("{{LEDE}}", LEDE)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", '<a href="#act9">Act IX</a>')
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
