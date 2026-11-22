"""Last acts art review, wave 2, round 8: ONE page with the Turning Year's phase 2 stage art (db collection wave2_art_r8): every PNG added since P2_BASE (the Greenwood,
Fae Court and World-Tree bosses, minibosses, creatures, poses, strips, the three violet necromancers, the Ossuary Oak family, obstacles, the heartwood icon and the
floors), grouped (units and strips, characters, summons, obstacles, icons, floors), each as a plain "now" card. Built on r5 / r4 / r3 (imported).

Usage: python3 docs/last_acts/tools/make_wave2_review_r8.py <out.html>   (repository root; new PNGs from the working tree)
"""
import html
import json
import os
import subprocess
import sys


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_wave2_review_r3 as r3  # noqa: E402
import make_wave2_review_r4 as r4  # noqa: E402

COLLECTION = "wave2_art_r8"  # db collection of this page's marks (a fresh one: nothing here is marked yet).
P2_BASE = "d53c6a58"  # The commit before the Turning Year phase 2 art: every PNG added since is shown.
TY_MANIFEST = "docs/year/ART_MANIFEST.md"  # Turning Year descriptions come from here and the art bible.
GROUPS = [("p2_units", "Units and strips", "wild/"), ("p2_chars", "Characters", "player/"), ("p2_summons", "Summons", "summons/"),
          ("p2_obstacles", "Obstacles", "obstacles/"), ("p2_icons", "Icons", "icons/"), ("p2_floors", "Floors", "tiles/")]  # (section id, heading, sprite folder).
LEDE = ("The Turning Year's stage art: bosses, minibosses, creatures, characters, the finale summon class, floors and props. Known flaws: the Masked Courtier is 46 px wide (her thorn rapier; box 32) "
        "and the Changeling Princess's crossed arms sit under her bust box; the Green Mother's cast pose is narrower than her base; the Summer Queen's gown reads orange-amber more than gold; "
        "the Winter Prince and the Hunt Hound are bluish-grey; the grove tree's trunk is pale grey (the blossom ramp); the Ossuary Oak's `_rooted` stills are not made; floors are procedural "
        "(small features), judge them under the four season tints.")


def keys_between(base: str, end: str, folders: list) -> list:
    """Sprite keys (no extension) of the PNGs added between two commits under the given folders, sorted."""
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=A", base, end, "--", "assets/sprites/"], cwd=r3.REPO, capture_output=True, text=True, check=True).stdout.split()
    return sorted(p[len(r3.C):-4] for p in out if p.endswith(".png") and any(p[len(r3.C):].startswith(f) for f in folders))


def section(sid: str, heading: str, blurb: str, cards: list) -> str:
    """One page section (the template's markup)."""
    return ('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2>%s<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
            % (sid, heading, '<p class="ws-blurb">%s</p>' % blurb if blurb else "", sid, "\n".join(cards)))


def main() -> None:
    r3.ACTS.append(("titans", "HEAD", "The Age of Titans", r4.TITANS_MANIFEST))  # So bible() also reads the Titans and Turning Year manifests.
    r3.ACTS.append(("year", "HEAD", "The Turning Year", TY_MANIFEST))
    rows = r3.bible()
    sections, counts, nav = [], {}, []
    year = keys_between(P2_BASE, "HEAD", [g[2] for g in GROUPS])  # the new PNGs.
    for gid, heading, folder in GROUPS:
        cards = []
        for k in [k for k in year if k.startswith(folder)]:
            try:
                cards.append(r4.card_now(k, gid, r3.describe(k, rows)))
            except Exception as e:
                r3.MISSING.append("%s (%s)" % (k, e))
        if cards:
            counts[gid] = len(cards)
            nav.append('<a href="#%s">%s</a>' % (gid, heading))
            sections.append(section(gid, heading, "", cards))
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
