"""Concept art review for Acts VII-IX: the nine concept images (lineup, boss and stage per act) in
art_source/concepts/, grouped by act, for the owner's OK / Redo marks (db collection concepts_7_9_r1).
Each image is downscaled to 1024 px wide and embedded as a JPEG data URI; descriptions come from the "Concept art"
sections of docs/act{7,8,9}/PROPOSAL.md (condensed to one line here).

Usage: python3 docs/act5/tools/make_concepts_7_9_review.py <out.html>
Run from the repository root (adapted from make_act5_review.py; same card markup, so the shared template's script works).
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
COLLECTION = "concepts_7_9_r1"  # db collection the owner's marks are saved in.
WIDTH = 1024  # Embedded image width in px.
QUALITY = 85  # JPEG quality of the embedded images.
LEDE = ("Concept art for Acts VII–IX: approve the look before any sprites are made. "
        "Mark each OK or Redo with a note.")  # Page lede.
# Groups in display order: (id, heading, blurb, [(image, card title, one-line description)]).
GROUPS = [
    ("act7", "Act VII: the Sanguine Court", "Vampires, bat-folk, werewolves and witches in blood red, black velvet and candle gold.", [
        ("act7_lineup", "Lineup", "Thrall, ghoul, vampire bat, Blood Knight, the Vampire Noble (a woman, figure style), the Chiropteran, the Werewolf (the largest), the Crimson Witch (a woman, figure style) and the Bloated Thrall."),
        ("act7_boss", "Bosses", "Queen Carmilla (figure style at its limit, blood-drain beam), the Elder rising from his coffin, and Vargr the Moon-Eater howling, in a candlelit throne hall under the moon, with the necromancer's army at the bottom."),
        ("act7_stage", "Stage", "Ravensmoor in play under the red moon, with Bloodfeast (red threads from bitten skeletons to glowing vampire knights), Night Wings (bats and bat-folk with landing shadows), sleeping coffins, a noble's drain beam and a werewolf."),
    ]),
    ("act8", "Act VIII: the Last Line", "The living fight back: gangs, police, the army and the Supers, on a grid of city blocks.", [
        ("act8_lineup", "Lineup", "Thug, gang gunner, riot cop, SWAT breacher, field medic (a woman, figure style), rifleman, machine gunner, tank, and four Supers: a speedster, a strongman, a flying blaster (a woman, figure style) and a gadget vigilante, redone as looser nods with no emblems, bat shapes or lightning bolts."),
        ("act8_boss", "Bosses", "Paragon (white-and-silver suit, blue cape, heat vision; redone so it no longer reads as the famous red-and-blue hero), Don Marrow behind his gold-minigun limousine, and General Harrow in power armour."),
        ("act8_stage", "Stage", "Skid Row in the new map style, a strict top-down grid of rectangular city blocks with streets, crosswalks and narrow alleys, fleeing civilians, an armoured car with headlight lane lines, a speedster and the ring fighting riot cops, thugs and gunners."),
    ]),
    ("act9", "Act IX: the Concord of Stars", "Hull white and gunmetal, plasma green and laser magenta: the Brood, the Vrask, the Luminous and the Harvesters.", [
        ("act9_lineup", "Lineup", "Broodling, Burrower, Acid Spitter, Grey Drone, Saucer, Grey Overseer, Vrask Hunter, Lumen Sentinel and the Prism (the Star-Seer, a woman, figure style, in an opaque, fully covering gown)."),
        ("act9_boss", "Bosses", "The Harvester floating above a throne of rings on the mothership bridge, with a tractor beam lifting skeletons, its true halo of rings behind it, a Brood queen-guard and a Vrask hunter beside it."),
        ("act9_stage", "Stage", "Stage 25, the Crash Site, with a Harvester scout ship in the crater, magenta aiming lines and a sweeping beam, a saucer abducting a skeleton, Brood swarming, a burrower mound and Terraforming ground (green healing glow on Brood units, patches burnt black)."),
    ]),
]


def card(gid: str, img: str, title: str, what: str) -> str:
    """One review card: the downscaled concept as a JPEG data URI, its description, OK / Redo and a note."""
    path = os.path.join(REPO, "art_source/concepts", img + ".png")
    im = Image.open(path).convert("RGB")
    ow, oh = im.size
    im = im.resize((WIDTH, round(oh * WIDTH / ow)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=QUALITY, optimize=True)
    src = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
    w, h = im.size
    name = "%s %s" % (gid.replace("act", "Act "), title.lower())
    return ('<article class="card wide" data-id="%s" data-owner="%s" data-frames="1" data-w="%d" data-h="%d" data-s="1">'
            '<div class="stage"><div class="ba"><figure class="now"><img src="%s" width="%d" height="%d" alt="%s">'
            '<figcaption>Concept</figcaption></figure></div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">concept</span></div>'
            '<p class="key">art_source/concepts/%s.png</p><p class="meta">%d×%d px (source %d×%d)</p>'
            '<p class="subject">%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (img, gid, w, h, src, w, h, html.escape(name), html.escape(name), img, w, h, ow, oh,
                                   html.escape(what), html.escape(name), img, img)


def main() -> None:
    sections, counts, total = [], {}, 0
    for gid, label, blurb, items in GROUPS:
        cards = [card(gid, i, t, d) for i, t, d in items]
        counts[gid] = len(cards)
        total += len(cards)
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, gid, "\n".join(cards)))
    page = open(TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Concept Art Review</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Concept Art Review</h1>")
            .replace("{{LEDE}}", LEDE)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l.split(":")[0]) for g, l, _, _ in GROUPS))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
