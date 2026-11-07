"""Act IX art review, round 1: every PNG Act IX added (the foundation and the three stages), grouped by
who made it, with the ART_BIBLE description of each, for the owner's OK / Redo marks (db collection act9_art_r1).
Concept art first, then the shared kinds and city tiles, then each stage. One in-game screenshot is shown as a
non-markable "in play" reference when SHOTS exists.

Usage: python3 docs/act9/tools/make_act9_review.py <out.html>
Run from the repository root; reads every PNG from git refs (the main branch and the three stage branches).
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

REPO = os.getcwd()  # Repository root (only used to run git; every file is read from a git ref, never the worktree).
MAIN = "claude/charming-lamport-upfhlz"  # Main branch: foundation art, concept art, the template.
TEMPLATE_REF = (MAIN, "docs/act3/tools/art_review_template.html")  # The shared review page template.
COLLECTION = "act9_art_r1"  # db collection the owner's marks are saved in.
SCRATCH = "/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad"  # Scratchpad.
SHOTS = SCRATCH + "/shots"  # In-game screenshots (Crash Site).
# Review groups in display order: (id, heading, blurb, git ref, (base, head) range of added PNGs, known weak spots).
GROUPS = [
    ("foundation", "Shared kinds, turf and effects", "The Concord's shared kinds (Broodling, Grey Drone, Lumen Sentinel, "
     "Prism, Saucer, Vrask Hunter), the Hive Mother, the terraformer, the turf tiles, the beam effects and the mothership eye.",
     MAIN, ("d09e913", "957a8f5"),
     "Known weak spots: the Hive Mother is only partly legible at 96 px, the Prism and Hive Mother bust boxes were set by eye, "
     "the turf's green veins look dashed, the Brood are drawn green-black chitin though the stage concept shows purple."),
    ("crash_site", "The Crash Site", "Stage 25: the Hive Mother's poses, the Acid Spitter, Brood Matriarch, Burrower and "
     "eggs, the Broodbound and her skins, hull and glass obstacles, the four zone floors, icons.",
     "act9-crash-site", ("2c2fb72", "act9-crash-site"),
     "Known weak spots: the Broodbound reads dark at 56 px and her Deathlord skin is very dark; fliers have no feet by design."),
    ("proving_moon", "The Proving Moon", "Stage 26: Vrask'Tal, the Warbeast, the Blooded and his skins, crater, trophy and "
     "duelling-ring decals, obstacles, floors, icons.",
     "act9-proving-moon", ("2c2fb72", "act9-proving-moon"),
     "Known weak spots: Vrask'Tal has no attack pose, the Blooded misses the lightness check by a hair, the duelling-ring "
     "decal is a bright teal ring."),
    ("ark", "The Ark", "Stage 27: the Harvester (and its true form), Grey Overseer, Luminous Archon, Vault Beast, the "
     "Starborn and his skins, the Ghost Saucer and Black Mothership summons, consoles, crates, tanks, vents, floors, icons.",
     "act9-ark", ("2c2fb72", "act9-ark"),
     "Known weak spots: the saucers have no feet by design, lifted enemies are drawn as a light column rather than lifted bodies."),
]
CONCEPTS = [("concept_boss", "art_source/concepts/act9_boss.png", "Act IX boss concept", "Reference: the Act IX boss."),
            ("concept_lineup", "art_source/concepts/act9_lineup.png", "Act IX lineup concept", "Reference: the Act IX lineup."),
            ("concept_stage", "art_source/concepts/act9_stage.png", "Act IX stage concept", "Reference: the Act IX stage.")]
LINEUPS = []
PLAY = [("crash_site", "art_0540.png", "In play (Crash Site, hatchery floor, 11:01)"),
        ("crash_site", "art_0420.png", "In play (Crash Site, 13:01)"),
        ("crash_site", "art_0240.png", "In play (Crash Site, 16:01)")]  # (group, file, caption): references, not marked.
KEYREF = {}  # sprite key -> git ref it is read from, filled by main().


def show(ref: str, path: str) -> bytes:
    """Bytes of `path` at git ref `ref`."""
    return subprocess.run(["git", "show", "%s:%s" % (ref, path)], cwd=REPO, capture_output=True, check=True).stdout


def added(base: str, head: str) -> list:
    """Sprite keys (no extension) of the PNGs added between `base` and `head`."""
    cmd = ["git", "diff", "--name-only", "--diff-filter=A", base, head, "--", "assets/sprites/*.png"]
    out = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, check=True).stdout.split()
    return [p[len("assets/sprites/"):-4] for p in out]


def bible() -> dict:
    """ART_BIBLE table rows: backticked key -> description cell."""
    rows = {}
    lines = []
    for ref in ("act9-integ", "act9-ark", "act9-proving-moon", "act9-crash-site", MAIN):
        try:
            lines += show(ref, "docs/art/ART_BIBLE.md").decode("utf-8").splitlines()
        except subprocess.CalledProcessError:
            pass
    for line in lines:
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
            try:
                still = show(KEYREF[key], "assets/sprites/" + key[: -len(suf)] + ".png")
            except subprocess.CalledProcessError:
                continue
            return max(1, round(w / Image.open(io.BytesIO(still)).size[0]))
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
    data = show(KEYREF[key], "assets/sprites/" + key + ".png")
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
    rank = { "bosses": 1, "summons": 2, "player": 3, "effects": 4, "icons": 5, "tiles": 6, "obstacles": 7, "decals": 7, "structures": 7, "projectiles": 4, "concord": 0, "epilogue": 8}
    base = re.sub(r"_(walk|idle)$", "", key)
    return (rank.get(folder, 9), base, 0 if key == base else 1)


def lineup_card(cid: str, path: str, name: str, what: str) -> str:
    """A review card for one concept lineup (resized to 768 px wide)."""
    im = Image.open(io.BytesIO(show(MAIN, path))).convert("RGB")
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
    sections, counts, total = [], {}, 0
    for gid, label, blurb, ref, (base, head), note in GROUPS:
        keys = sorted(added(base, head), key=order)
        for k in keys:
            KEYREF[k] = ref
        cards = [card(k, gid, describe(k, rows)) for k in keys]
        counts[gid] = len(cards)
        total += len(cards)
        play = ""
        for g, fn, cap in PLAY:
            p = os.path.join(SHOTS, fn)
            if g == gid and os.path.exists(p):
                buf = io.BytesIO()
                Image.open(p).convert("RGB").save(buf, "JPEG", quality=80)
                play += ('<figure class="inplay"><img src="data:image/jpeg;base64,%s" alt="In play" style="max-width:100%%;'
                         'height:auto"><figcaption>%s: a reference, not marked.</figcaption></figure>') % (
                    base64.b64encode(buf.getvalue()).decode(), cap)
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
    page = show(*TEMPLATE_REF).decode("utf-8")
    page = (page.replace("<title>Act II Art Review</title>", "<title>Act IX art review, round 1</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Act IX art review, round 1</h1>")
            .replace("{{LEDE}}", "Round 1: all %d new images for Act IX, The Concord of Stars, grouped by stage, with the concept art first. "
                     "Strips animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB")


if __name__ == "__main__":
    main()
