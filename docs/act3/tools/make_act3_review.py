"""Act III art review, round 1: every PNG the Act III foundation and the three stage branches added, grouped by
who made it, with the ART_BIBLE description of each, for the owner's OK / Redo marks (db collection act3_art_r1).

Usage: python3 docs/act3/tools/make_act3_review.py <out.html>
Run from the repository root on the merged `integration` tree.
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

REPO = os.getcwd()  # Repository root (the merged tree).
HERE = os.path.dirname(os.path.abspath(__file__))  # This tools folder (the template lives here).
TEMPLATE = os.path.join(HERE, "art_review_template.html")  # The wave 2 review page template.
BASE_REV = "c0189e9"  # main before the Act III foundation: everything added since is Act III art.
COLLECTION = "act3_art_r1"  # db collection the owner's marks are saved in.
RENAMES = {"obstacles/cargo_crate": "obstacles/citadel_crate"}  # Citadel keys renamed at the merge (clash).
# Review groups in display order: (id, heading, blurb, branch whose additions it holds).
GROUPS = [
    ("foundation", "Foundation", "The Empire's shared kinds and the Grave Gunner: they set the act's look.",
     "act3-foundation"),
    ("wastes", "Scrap Wastes", "Stage 7: its kinds, the Trojan Horse, Kestrel, the Lightning Abbess and her skins, "
     "floors, obstacles, icons.", "origin/act3-wastes"),
    ("assembly", "Assembly Halls", "Stage 8: its kinds, the Beta Build, the Motherboard, the Grave Drones, the "
     "Marionette and her skins, floors, obstacles, icons.", "origin/act3-assembly"),
    ("citadel", "Iron Citadel", "Stage 9: its kinds, Valkyrie 2.0, Deus Ex Machina, the Iron Revenants, the Rust "
     "Prophet and his skins, floors, obstacles, icons.", "origin/act3-citadel"),
]


def added(rev: str) -> list:
    """Sprite keys (no extension) of the PNGs `rev` added since BASE_REV."""
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=A", BASE_REV, rev, "--", "assets/sprites/*.png"],
                         cwd=REPO, capture_output=True, text=True, check=True).stdout.split()
    return [p[len("assets/sprites/"):-4] for p in out]


def bible() -> dict:
    """ART_BIBLE table rows: backticked key -> description cell."""
    rows = {}
    for line in open(os.path.join(REPO, "docs/art/ART_BIBLE.md"), encoding="utf-8"):
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


def b64(data: bytes) -> str:
    return "data:image/png;base64," + base64.b64encode(data).decode()


def frames_of(key: str, w: int, h: int) -> int:
    """Frames in a strip (walk / idle strips by their still's width, effects square)."""
    if key.startswith("effects/"):
        return max(1, w // h)
    for suf in ("_walk", "_idle"):
        if key.endswith(suf):
            still = os.path.join(REPO, "assets/sprites", key[: -len(suf)] + ".png")
            if os.path.exists(still):
                return max(1, round(w / Image.open(still).size[0]))
    return 1


def scale_for(key: str, w: int, h: int, frames: int) -> int:
    """Display scale: icons x6, tiles x2, figures to about 260 px (strips 120)."""
    if key.startswith("icons/"):
        return 6
    if key.startswith("tiles/"):
        return 2
    target = 260 if frames == 1 else 120
    s = max(1, min(6, round(target / max(1, h))))
    while w * s > 900 and s > 1:
        s -= 1
    return s


def card(key: str, group: str, what: str) -> str:
    """One review card (same markup as the wave 2 pages, so the template's script works unchanged)."""
    data = open(os.path.join(REPO, "assets/sprites", key + ".png"), "rb").read()
    w, h = Image.open(io.BytesIO(data)).size
    frames = frames_of(key, w, h)
    s = scale_for(key, w, h, frames)
    stage = '<figure class="now"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>Now</figcaption></figure>' % (
        b64(data), w * s, h * s, html.escape(key))
    kind = ("walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else
            "effect strip" if frames > 1 else "icon" if key.startswith("icons/") else "floor tile" if key.startswith("tiles/")
            else "obstacle" if key.startswith("obstacles/") else "still")
    meta = "%d×%d px" % (w, h) + (" · %d frames" % frames if frames > 1 else "") + " · shown ×%d" % s
    cid = key.replace("/", "__")
    name = os.path.basename(key).replace("_", " ").capitalize()
    return ('<article class="card%s" data-id="%s" data-owner="%s" data-frames="%d" data-w="%d" data-h="%d" data-s="%d">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">%s</p><p class="meta">%s</p><p class="subject">%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (" wide" if w * s > 560 else "", cid, group, frames, w, h, s, stage, html.escape(name),
                                   kind, html.escape(key), meta, html.escape(what), html.escape(name), cid, cid)


def order(key: str) -> tuple:
    """Sort: units and bosses first, then icons, floors, obstacles; a still before its strips."""
    folder = key.split("/")[0]
    rank = {"empire": 0, "bosses": 1, "summons": 2, "player": 3, "effects": 4, "icons": 5, "tiles": 6, "obstacles": 7}
    base = re.sub(r"_(walk|idle)$", "", key)
    return (rank.get(folder, 9), base, 0 if key == base else 1)


def main() -> None:
    rows = bible()
    foundation = set(added("act3-foundation"))
    seen = set()
    sections, counts, total = [], {}, 0
    for gid, label, blurb, rev in GROUPS:
        keys = added(rev)
        if gid == "citadel":  # The Citadel's crate was renamed at the merge (the Assembly Halls keep cargo_crate).
            for old, new in RENAMES.items():
                keys = [k.replace(old, new) if k.startswith(old) else k for k in keys]
        keys = [k for k in keys if (gid == "foundation" or k not in foundation) and k not in seen
                and os.path.exists(os.path.join(REPO, "assets/sprites", k + ".png"))]
        keys.sort(key=order)
        seen.update(keys)
        cards = [card(k, gid, describe(k, rows)) for k in keys]
        counts[gid] = len(cards)
        total += len(cards)
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, gid, "\n".join(cards)))
    page = open(TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act III Art Review</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act III Art Review</h1>")
            .replace("{{LEDE}}", "Round 1: all %d new images for Act III, the Electronic Empire, grouped by stage. Strips "
                     "animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l, _, _ in GROUPS))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
