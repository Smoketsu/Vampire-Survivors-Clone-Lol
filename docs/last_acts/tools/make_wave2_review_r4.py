"""Last acts art review, wave 2, round 4: ONE page with every image still waiting for the owner's mark (db collection wave2_art_r4): (a) the 18 Celestial Host images
redone in round 3 (commit 50cdff1b), shown exactly as make_wave2_review_r3.py shows them (was / now), then (b) every PNG the Age of Titans phase 2 art commits added,
grouped (units and strips, characters, summons, obstacles, icons, floors), each as a plain "now" card (make_wave2_review_r2.py's card). Built on r3 (imported) and r2.

Usage: python3 docs/last_acts/tools/make_wave2_review_r4.py <out.html>   (repository root; new PNGs from the working tree, old ones from git)
"""
import html
import io
import json
import os
import subprocess
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_wave2_review_r3 as r3  # noqa: E402

COLLECTION = "wave2_art_r4"  # db collection of this page's marks (a fresh one: nothing here is marked yet).
BASE = "a4e8abec"  # The commit before the Titans phase 2 art: every PNG added since is shown.
TITANS_MANIFEST = "docs/titans/ART_MANIFEST.md"  # Titans descriptions come from here and the art bible.
GROUPS = [("titans_units", "Titans: bosses, minibosses, beasts and strips", "primeval/"), ("titans_chars", "Titans: characters", "player/"),
          ("titans_summons", "Titans: the finale summon class", "summons/"), ("titans_obstacles", "Titans: obstacles", "obstacles/"),
          ("titans_icons", "Titans: icons", "icons/"), ("titans_floors", "Titans: floors", "tiles/")]  # (section id, heading, sprite folder).
LEDE = ("Every image waiting for your mark: the 18 Celestial Host images redone after your round 1 marks (round 3, not yet marked), then the Age of Titans' stage art: bosses, "
        "minibosses, beasts, characters, the finale summon class, floors and props. Known flaws: the Scarmaw leap and Ironbrow broken poses read close to their base stills "
        "(the broken horn is an orange crack on a stump); the Fern Huntress and Skywatcher's hourglass figures are faint at 36-38 px; the Bog Croc and Gravejaw tar-dark hides sit "
        "near the dark floors in value; the Herd-Warden is 44 px wide (box 42); the Fossil Giant's neck is thin; the canyon wall was stretched to 96 px; floors are procedural.")


def added_since() -> list:
    """Sprite keys (no extension) of the PNGs added since BASE, sorted."""
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=A", BASE, "HEAD", "--", "assets/sprites/"], cwd=r3.REPO, capture_output=True, text=True, check=True).stdout.split()
    return sorted(p[len(r3.C):-4] for p in out if p.endswith(".png"))


def card_now(key: str, group: str, what: str) -> str:
    """r2's card: the new image alone."""
    data = r3.show(r3.C + key + ".png")
    w, h = Image.open(io.BytesIO(data)).size
    frames = r3.frames_of(key, w, h)
    s = r3.scale_for(key, w, h, frames)
    stage = '<figure class="now"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>Now</figcaption></figure>' % (r3.b64(data), w * s, h * s, html.escape(key))
    kind = ("walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else "icon" if key.startswith("icons/")
            else "floor tile" if key.startswith("tiles/") else "obstacle" if key.startswith("obstacles/") else "still")
    meta = "%d×%d px" % (w, h) + (" · %d frames" % frames if frames > 1 else "") + " · shown ×%d" % s
    cid = key.replace("/", "__")
    name = os.path.basename(key).replace("_", " ").capitalize()
    return ('<article class="card%s" data-id="%s" data-owner="%s" data-frames="%d" data-w="%d" data-h="%d" data-s="%d">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">%s</p><p class="meta">%s</p><p class="subject">%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button><button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label><textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (" wide" if w * s > 560 else "", cid, group, frames, w, h, s, stage, html.escape(name), kind, html.escape(key), meta,
                                   html.escape(what), html.escape(name), cid, cid)


def main() -> None:
    r3.ACTS.append(("titans", "HEAD", "The Age of Titans", TITANS_MANIFEST))  # So bible() also reads the Titans manifest.
    rows = r3.bible()
    sections, counts, nav, total = [], {}, [], 0
    redo = []
    for k in r3.REDONE:
        try:
            redo.append(r3.card(k, "host_redo", r3.describe(k, rows)))
        except Exception as e:  # An unreadable PNG is listed, not fatal.
            r3.MISSING.append("%s (%s)" % (k, e))
    sections.append('<section class="ws" id="host_redo"><header class="ws-head"><h2>The Celestial Host: redone (round 3)</h2><p class="ws-blurb">Each image beside its previous version '
                    '(was / now). Strips animate.</p><p class="ws-count" data-count="host_redo"></p></header><div class="grid">%s</div></section>' % "\n".join(redo))
    counts["host_redo"] = len(redo)
    nav.append('<a href="#host_redo">Host redone</a>')
    keys = added_since()
    for gid, heading, folder in GROUPS:
        cards = []
        for k in [k for k in keys if k.startswith(folder)]:
            try:
                cards.append(card_now(k, gid, r3.describe(k, rows)))
            except Exception as e:
                r3.MISSING.append("%s (%s)" % (k, e))
        if not cards:
            continue
        counts[gid] = len(cards)
        nav.append('<a href="#%s">%s</a>' % (gid, heading.replace("Titans: ", "")))
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>' % (
            gid, heading, gid, "\n".join(cards)))
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
