"""Last acts art review, wave 2, round 9: ONE page (db collection wave2_art_r9): the 60 round 8 cards (the Turning Year's phase 2 stage art, built by r8's helpers)
first, then an "Epilogue" section with the reorder pass's 53 epilogue picture panels in act order (docs/last_acts/EPILOGUE_PANELS.md): each part panel under its part
heading with the exact paragraph it illustrates, each closing card likewise, and the three redone existing panels (act1_3, close, close_act4) as was / now.
Panels are embedded as lossless WebP (palette art, a fraction of the PNG's size) and shown at 640 px wide (click to double).

Usage: python3 docs/last_acts/tools/make_wave2_review_r9.py <out.html>   (repository root; panels from the working tree, the "was" ones from git HEAD)
"""
import base64
import html
import io
import json
import os
import re
import subprocess
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_wave2_review_r3 as r3  # noqa: E402
import make_wave2_review_r4 as r4  # noqa: E402
import make_wave2_review_r8 as r8  # noqa: E402

COLLECTION = "wave2_art_r9"  # db collection of this page's marks (a fresh one: nothing here is marked yet).
REDONE = ["act1_3", "close", "close_act4"]  # Existing panels redone (was = git HEAD's converted PNG before the redo commits).
WAS_REF = "ae177639"  # The commit holding their old pictures.
PANELS = "assets/sprites/epilogue/"  # Panel folder.
LEDE = (r8.LEDE + " NEW this round: the Epilogue section at the end, 53 picture panels for the epilogue's fifteen parts and their closing cards (50 new, 3 redone with was / now). "
        "Each shows the exact line it illustrates; the panel pans slowly in the game, so judge the whole picture.")


def parse_epilogue() -> list:
    """[(panel key, kind, heading, line)] in play order: each part's panels, then the closing card after it."""
    src = open("scripts/data/epilogue_data.gd", encoding="utf-8").read()
    rows_src, closings_src = src.split("const CLOSINGS")
    s = r'"((?:[^"\\]|\\.)*)"'
    un = lambda t: t.replace('\\"', '"')
    parts, closings = [], {}
    for blk in re.split(r"\n\t\{\n", rows_src)[1:]:
        pid = re.search(r'"id": ' + s, blk).group(1)
        head = un(re.search(r'"heading": ' + s, blk).group(1))
        lines = [un(x) for x in re.findall(r"^\t\t\t" + s + ",", blk, re.M)]
        panels = re.findall(r'\["epilogue/(\w+)"', blk)
        parts.append((pid, head, lines, panels))
    for blk in re.split(r"\n\t\{\n", closings_src)[1:]:
        after = re.search(r'"after": ' + s, blk).group(1)
        closings[after] = (un(re.search(r'"heading": ' + s, blk).group(1)), un(re.search(r'"line": ' + s, blk).group(1)),
                           re.search(r'"panel": \["epilogue/(\w+)"', blk).group(1))
    out = []
    for pid, head, lines, panels in parts:
        for k, line in zip(panels, lines):
            out.append((k, "part panel", head, line))
        if pid in closings:
            h, line, k = closings[pid]
            out.append((k, "closing card after " + head, h, line))
    return out


def webp(data: bytes) -> str:
    """A data URI of a lossless WebP of the PNG `data`."""
    buf = io.BytesIO()
    Image.open(io.BytesIO(data)).convert("RGB").save(buf, "WEBP", lossless=True, quality=100, method=6)
    return "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()


def epilogue_card(key: str, kind: str, heading: str, line: str) -> str:
    """One epilogue card: the panel (was / now when redone), its heading and its line."""
    now = open(PANELS + key + ".png", "rb").read()
    fig = lambda src, cap: ('<figure class="%s"><img src="%s" width="640" height="360" alt="%s %s" style="image-rendering:auto"><figcaption>%s</figcaption></figure>'
                            % (cap.lower(), src, cap.lower(), key, cap))
    stage = fig(webp(now), "Now")
    if key in REDONE:
        was = subprocess.run(["git", "show", "%s:%s%s.png" % (WAS_REF, PANELS, key)], capture_output=True, check=True).stdout
        stage = fig(webp(was), "Was") + stage
    cid = "epilogue__" + key
    return ('<article class="card wide" data-id="%s" data-owner="epilogue" data-frames="1" data-w="1024" data-h="576" data-s="1">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">epilogue/%s</p><p class="meta">1024×576 px</p><p class="subject">%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button><button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label><textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (cid, stage, html.escape(heading), html.escape(kind + (" (redone)" if key in REDONE else "")), key, html.escape(line),
                                   html.escape(heading), cid, cid)


def main() -> None:
    r3.ACTS.append(("titans", "HEAD", "The Age of Titans", r4.TITANS_MANIFEST))
    r3.ACTS.append(("year", "HEAD", "The Turning Year", r8.TY_MANIFEST))
    rows = r3.bible()
    sections, counts, nav = [], {}, []
    year = r8.keys_between(r8.P2_BASE, "HEAD", [g[2] for g in r8.GROUPS])
    for gid, heading, folder in r8.GROUPS:
        cards = []
        for k in [k for k in year if k.startswith(folder)]:
            try:
                cards.append(r4.card_now(k, gid, r3.describe(k, rows)))
            except Exception as e:
                r3.MISSING.append("%s (%s)" % (k, e))
        if cards:
            counts[gid] = len(cards)
            nav.append('<a href="#%s">%s</a>' % (gid, heading))
            sections.append(r8.section(gid, heading, "", cards))
    cards = [epilogue_card(*e) for e in parse_epilogue() if os.path.exists(PANELS + e[0] + ".png")]
    counts["epilogue"] = len(cards)
    nav.append('<a href="#epilogue">Epilogue</a>')
    sections.append(r8.section("epilogue", "Epilogue", "The epilogue's picture panels in act order, each with the line it illustrates. Redone panels show was / now.", cards))
    total = sum(counts.values())
    page = r3.show(r3.TEMPLATE_PATH).decode("utf-8")
    page = page.replace('card.querySelector(".stage img")', 'card.querySelector(".stage .now img")')
    page = (page.replace("<title>Act II Art Review</title>", "<title>Last Acts Art Review W2</title>").replace("<h1>Act II Art Review</h1>", "<h1>Last Acts Art Review W2</h1>")
            .replace("{{LEDE}}", html.escape(LEDE)).replace("{{COLLECTION}}", json.dumps(COLLECTION)).replace("{{NAV}}", " ".join(nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total)).replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB", "missing:", r3.MISSING)


if __name__ == "__main__":
    main()
