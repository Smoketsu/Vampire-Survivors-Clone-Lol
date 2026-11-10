"""Last acts art review, wave 2, round 5: ONE page with every image still waiting for the owner's mark (db collection wave2_art_r5): (a) every card of round 4
exactly as make_wave2_review_r4.py builds them (the 18 redone Celestial Host images with was / now, and the Age of Titans stage art), then (b) every PNG the Turning
Year foundation art commits added (since TY_BASE), grouped (units and strips, obstacles and thickets, icons, floors, markers, effects), each as a plain "now" card.
Built on r4 (imported), r3 and r2.

Usage: python3 docs/last_acts/tools/make_wave2_review_r5.py <out.html>   (repository root; new PNGs from the working tree, old ones from git)
"""
import html
import json
import os
import subprocess
import sys


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_wave2_review_r3 as r3  # noqa: E402
import make_wave2_review_r4 as r4  # noqa: E402

COLLECTION = "wave2_art_r5"  # db collection of this page's marks (a fresh one: nothing here is marked yet).
TY_BASE = "9a210f5c"  # The commit before the Turning Year art: every PNG added since is shown in the new sections.
TITANS_END = "9a210f5c"  # Round 4's Titans cards stop here (the Titans art commits all precede the Turning Year's).
TY_MANIFEST = "docs/year/ART_MANIFEST.md"  # Turning Year descriptions come from here and the art bible.
GROUPS = [("year_units", "Turning Year: units and strips", "wild/"), ("year_obstacles", "Turning Year: obstacles and thickets", "obstacles/"),
          ("year_icons", "Turning Year: icons", "icons/"), ("year_floors", "Turning Year: floors", "tiles/"),
          ("year_markers", "Turning Year: markers", "markers/"), ("year_effects", "Turning Year: effects", "fx/")]  # (section id, heading, sprite folder).
LEDE = ("Every image waiting for your mark: the 18 redone Celestial Host images, the Age of Titans' stage art, and the Turning Year's shared art (new). "
        "Turning Year known flaws: the Dryad is 36 px wide (box 34); the Winter Fae and the Wild Rider came out bluish-grey rather than white (the frost ramp is dim next to the dark floors); "
        "the dead Corpse-Bloom is a desaturated brown more than a grey; the oak and stone are one size smaller than their manifest boxes (40x30 stone, 32x40 oak); the A Fair Bargain "
        "hands carry dark-wine shading; the blizzard, blight and burn effects are procedural and dithered; the floors are procedural, so judge them under the four season tints.")
FX = {"fx/wild_snowfall": 8, "fx/wild_leaves": 8, "fx/wild_thicket_burn": 6, "fx/wild_bury": 6}  # Frame counts of the new animated effect strips.


def keys_between(base: str, end: str, folders: list) -> list:
    """Sprite keys (no extension) of the PNGs added between two commits under the given folders, sorted."""
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=A", base, end, "--", "assets/sprites/"], cwd=r3.REPO, capture_output=True, text=True, check=True).stdout.split()
    return sorted(p[len(r3.C):-4] for p in out if p.endswith(".png") and any(p[len(r3.C):].startswith(f) for f in folders))


def section(sid: str, heading: str, blurb: str, cards: list) -> str:
    """One page section (the template's markup)."""
    return ('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2>%s<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
            % (sid, heading, '<p class="ws-blurb">%s</p>' % blurb if blurb else "", sid, "\n".join(cards)))


def main() -> None:
    r3.FX_FRAMES.update(FX)
    r3.ACTS.append(("titans", "HEAD", "The Age of Titans", r4.TITANS_MANIFEST))  # So bible() also reads the Titans and Turning Year manifests.
    r3.ACTS.append(("year", "HEAD", "The Turning Year", TY_MANIFEST))
    rows = r3.bible()
    sections, counts, nav = [], {}, []
    redo = []
    for k in r3.REDONE:  # (a) round 4's first section: the 18 Host redos, was / now.
        try:
            redo.append(r3.card(k, "host_redo", r3.describe(k, rows)))
        except Exception as e:  # An unreadable PNG is listed, not fatal.
            r3.MISSING.append("%s (%s)" % (k, e))
    sections.append(section("host_redo", "The Celestial Host: redone (round 3)", "Each image beside its previous version (was / now). Strips animate.", redo))
    counts["host_redo"] = len(redo)
    nav.append('<a href="#host_redo">Host redone</a>')
    titans = keys_between(r4.BASE, TITANS_END, [g[2] for g in r4.GROUPS])  # (a) round 4's Titans cards.
    for gid, heading, folder in r4.GROUPS:
        cards = []
        for k in [k for k in titans if k.startswith(folder)]:
            try:
                cards.append(r4.card_now(k, gid, r3.describe(k, rows)))
            except Exception as e:
                r3.MISSING.append("%s (%s)" % (k, e))
        if cards:
            counts[gid] = len(cards)
            nav.append('<a href="#%s">%s</a>' % (gid, heading.replace("Titans: ", "Titans ")))
            sections.append(section(gid, heading, "", cards))
    year = keys_between(TY_BASE, "HEAD", [g[2] for g in GROUPS])  # (b) the Turning Year's new PNGs.
    for gid, heading, folder in GROUPS:
        cards = []
        for k in [k for k in year if k.startswith(folder)]:
            try:
                cards.append(r4.card_now(k, gid, r3.describe(k, rows)))
            except Exception as e:
                r3.MISSING.append("%s (%s)" % (k, e))
        if cards:
            counts[gid] = len(cards)
            nav.append('<a href="#%s">%s</a>' % (gid, heading.replace("Turning Year: ", "Year ")))
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
