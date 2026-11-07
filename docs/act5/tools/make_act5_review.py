"""Act V art review, round 1: every PNG Act V added (the foundation, the three stages and the epilogue), grouped by
who made it, with the ART_BIBLE description of each, for the owner's OK / Redo marks (db collection act5_art_r1).
The soldier-lineup question was settled in Act IV (the mixed lineup), so this round has no lineup section.

Usage: python3 docs/act5/tools/make_act5_review.py <out.html>
Run from the repository root on the merged Act V tree (adapted from docs/act4/tools/make_act4_review.py).
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
TEMPLATE = os.path.join(REPO, "docs/act3/tools/art_review_template.html")  # The shared review page template.
BASE_REV = "f044ab8"  # main before Act V: everything added since is Act V art.
COLLECTION = "act5_art_r1"  # db collection the owner's marks are saved in.
# Review groups in display order: (id, heading, blurb, commit whose additions it holds, its own base or None).
# "foundation" takes whatever the other groups do not claim.
GROUPS = [
    ("foundation", "Foundation", "The Shogunate's shared kinds (they set the act's look: ashigaru, samurai, teppo "
     "gunner, ninja, and at night the onryo and the oni) and the stone lantern, unlit and lit.", None, None),
    ("province", "Burning Province", "Stage 13: the Kunoichi, the Kappa, Shuten-doji the Oni King, Kage, the Grave "
     "Kunoichi and her skins, floors, obstacles, icons.", "94dc393", "1ea0bf2"),
    ("kurogane", "Castle Kurogane", "Stage 14: the Hatamoto, the Kiba-musha, the General of the Left, Shogun Kurogane "
     "(duel pose, command platform), the Ronin Revenant and his skins, floors, obstacles, icons.", "6ef2444", "1ea0bf2"),
    ("sun_road", "Road to the Sun", "Stage 15: the Sohei, the Kitsune, the Kirin, Amaterasu (and her mirror), the Shrine "
     "Maiden of Night and her skins, the Bound Oni and the Oni Lord, floors, obstacles, icons.", "a342c95", "1ea0bf2"),
    ("epilogue", "Epilogue", "The Sun Goes Out (4 panels) and the Pit Keeps Count card.", "dd556f7", "59d5228"),
]
# No open lineup question in Act V (settled in Act IV: the mixed lineup).
LINEUPS = []


def added(rev: str, base: str = BASE_REV) -> list:
    """Sprite keys (no extension) of the PNGs `rev` added since `base`."""
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=A", base, rev, "--", "assets/sprites/*.png"],
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
    rank = {"pantheon": 0, "bosses": 1, "summons": 2, "player": 3, "effects": 4, "icons": 5, "tiles": 6, "obstacles": 7, "epilogue": 8}
    base = re.sub(r"_(walk|idle)$", "", key)
    return (rank.get(folder, 9), base, 0 if key == base else 1)


def lineup_card(cid: str, path: str, name: str, what: str) -> str:
    """A review card for one concept lineup (resized to 768 px wide)."""
    im = Image.open(os.path.join(REPO, path)).convert("RGB")
    im = im.resize((768, round(im.size[1] * 768 / im.size[0])), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=86)
    src = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
    w, h = im.size
    return ('<article class="card wide" data-id="%s" data-owner="lineup" data-frames="1" data-w="%d" data-h="%d" data-s="1">'
            '<div class="stage"><div class="ba"><figure class="now"><img src="%s" width="%d" height="%d" alt="%s">'
            '<figcaption>Concept</figcaption></figure></div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">concept</span></div>'
            '<p class="key">%s</p><p class="meta">%d×%d px (shown at half size)</p><p class="subject">%s</p>'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (cid, w, h, src, w, h, html.escape(name), html.escape(name), html.escape(path),
                                   w * 2, h * 2, html.escape(what), html.escape(name), cid, cid)


def main() -> None:
    rows = bible()
    claimed = {}
    for gid, _, _, rev, base in GROUPS:
        if rev:
            for k in added(rev, base):
                claimed.setdefault(k, gid)
    every = [k for k in added("HEAD") if os.path.exists(os.path.join(REPO, "assets/sprites", k + ".png"))]
    sections, counts, total = [], {}, 0
    for gid, label, blurb, _, _ in GROUPS:
        keys = sorted((k for k in every if claimed.get(k, "foundation") == gid), key=order)
        cards = [card(k, gid, describe(k, rows)) for k in keys]
        counts[gid] = len(cards)
        total += len(cards)
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, gid, "\n".join(cards)))
    nav = [(g, l) for g, l, _, _, _ in GROUPS]
    page = open(TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act V Art Review</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act V Art Review</h1>")
            .replace("{{LEDE}}", "Round 1: all %d new images for Act V, the Shogunate of the Rising Sun, grouped by stage. "
                     "Strips animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
