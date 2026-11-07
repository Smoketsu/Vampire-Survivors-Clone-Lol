"""Act VIII art review, round 1: every PNG Act VIII added (the foundation and the three stages), grouped by
who made it, with the ART_BIBLE description of each, for the owner's OK / Redo marks (db collection act8_art_r1).
Concept art first, then the shared kinds and city tiles, then each stage. One in-game screenshot is shown as a
non-markable "in play" reference when SHOTS exists.

Usage: python3 docs/act8/tools/make_act8_review.py <out.html>
Run from the repository root on the merged Act VIII tree (adapted from docs/act7/tools/make_act7_review.py).
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
BASE_REV = "8ac5735"  # The Act VIII foundation briefs: everything added since is Act VIII art (or an excluded redo).
COLLECTION = "act8_art_r1"  # db collection the owner's marks are saved in.
SHOTS = "/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act8/integration/shots"  # In-game screenshots.
EXCLUDE = ("bosses/elder_vampire",)  # Sprite key prefixes added in the range but belonging to Act VII redos.
# Review groups in display order: (id, heading, blurb, commit whose own additions it holds, None, known weak spots).
# "foundation" takes whatever the stage commits do not claim.
GROUPS = [
    ("foundation", "Shared kinds and city tiles", "The Last Line's shared kinds (police, gangs, civilians, SWAT, "
     "military, Blitz), the wrecks, city-block floors and roof decals.", None, None,
     "Known weak spots: men's hands and faces read pale, the civilian woman's skin came out brown, the bunker roof's olive "
     "tint is strong, Blitz's speed rings add clutter."),
    ("skid_row", "Skid Row", "Stage 22: Don Marrow, the Armoured Limo, Big Sal, the bounty board, the spectral hearse, "
     "the Undertaker and his skins, the precinct roof, market stall and footing decals, icons.", "9d163d1", None,
     "Known weak spots: Don Marrow has no attack pose."),
    ("fort_kessler", "Fort Kessler", "Stage 23: the Machine Gunner, Attack Helicopter, Mammoth, General Harrow and his "
     "command car, the Fallen Sergeant and her skins, the Kessler mine, Bone Mines, sandbags, icons.", "e8031e5", None,
     "Known weak spots: the helicopter has no feet by design (it hovers)."),
    ("liberty_heights", "Liberty Heights", "Stage 24: Atlas, Aurora, Nightjar, the Conscript, Paragon, the Revenant "
     "Heroine and her skins, the Fallen Hero, Black Paragon, icons.", "3b73537", None,
     "Known weak spots: the Revenant Heroine, the Fallen Hero and Black Paragon are dark (they fail the lightness check "
     "against older acts' floors, but read on asphalt); the heroine's Deathlord face is small; Paragon has no attack pose; "
     "the Supers are open parody nods (check that no costume is too close to a real trademarked hero)."),
]
CONCEPTS = [("concept_boss", "art_source/concepts/act8_boss.png", "Act VIII boss concept", "Reference: the Act VIII boss."),
            ("concept_lineup", "art_source/concepts/act8_lineup.png", "Act VIII lineup concept", "Reference: the Act VIII lineup."),
            ("concept_stage", "art_source/concepts/act8_stage.png", "Act VIII stage concept", "Reference: the Act VIII stage.")]
LINEUPS = []


def added(rev: str, base=None) -> list:
    """Sprite keys (no extension) of the PNGs `rev` added since `base`."""
    if base is None and rev != "HEAD":  # one commit's own additions
        cmd = ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "--diff-filter=A", rev, "--", "assets/sprites/*.png"]
    else:
        cmd = ["git", "diff", "--name-only", "--diff-filter=A", base or BASE_REV, rev, "--", "assets/sprites/*.png"]
    out = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, check=True).stdout.split()
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
    rank = {"city": 0, "bosses": 1, "summons": 2, "player": 3, "effects": 4, "icons": 5, "tiles": 6, "obstacles": 7, "epilogue": 8}
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
    for gid, _, _, rev, base, _n in GROUPS:
        if rev:
            for k in added(rev, base):
                claimed.setdefault(k, gid)
    every = [k for k in added("HEAD") if os.path.exists(os.path.join(REPO, "assets/sprites", k + ".png")) and not k.startswith(EXCLUDE)]
    sections, counts, total = [], {}, 0
    for gid, label, blurb, _, _, note in GROUPS:
        keys = sorted((k for k in every if claimed.get(k, "foundation") == gid), key=order)
        cards = [card(k, gid, describe(k, rows)) for k in keys]
        counts[gid] = len(cards)
        total += len(cards)
        play = ""
        if gid == "foundation" and os.path.exists(os.path.join(SHOTS, "art_0545.png")):
            im = Image.open(os.path.join(SHOTS, "art_0545.png")).convert("RGB")
            buf = io.BytesIO()
            im.save(buf, "JPEG", quality=80)
            play = ('<figure class="inplay"><img src="data:image/jpeg;base64,%s" alt="In play" style="max-width:100%%;'
                    'height:auto"><figcaption>In play (integration run, city blocks, 10:56): a reference, not marked.'
                    '</figcaption></figure>') % base64.b64encode(buf.getvalue()).decode()
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-blurb"><b>%s</b></p><p class="ws-count" data-count="%s"></p>%s</header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, html.escape(note), gid, play, "\n".join(cards)))
    nav = [("concepts", "Concepts")] + [(g, l) for g, l, _, _, _, _ in GROUPS]
    ccards = [lineup_card(c, p, n, w) for c, p, n, w in CONCEPTS]
    counts["concepts"] = len(ccards)
    total += len(ccards)
    sections.insert(0, '<section class="ws" id="concepts"><header class="ws-head"><h2>Concept art</h2><p class="ws-blurb">The '
                    'reference concepts for the act.</p><p class="ws-count" data-count="concepts"></p></header>'
                    '<div class="grid">%s</div></section>' % "\n".join(ccards))
    page = open(TEMPLATE, encoding="utf-8").read()
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act VIII art review, round 1</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act VIII art review, round 1</h1>")
            .replace("{{LEDE}}", "Round 1: all %d new images for Act VIII, The Last Line, grouped by stage, with the concept art first. "
                     "Strips animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
