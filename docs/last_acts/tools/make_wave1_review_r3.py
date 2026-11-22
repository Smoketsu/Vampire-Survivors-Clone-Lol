"""Last acts art review, round 2 (derived from make_wave1_review.py; db collection wave1_art_r3). Round 1 doc follows:

Last acts art review, round 1: every PNG the three wave 1 art branches added (The Black Tide, the Hall of the Slain,
the Necropolis Dynasty), with the one-line description from each branch's ART_MANIFEST.md, for the owner's OK / Redo
marks (db collection wave1_art_r1). Concept references come first as plain figures (not markable); no in-game screenshots exist yet.

Usage: python3 docs/last_acts/tools/make_wave1_review.py <out.html>
Run from the repository root; reads every PNG from git refs (never the worktree).
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
MAIN = "claude/acts-7-9-proposal-ozq8xz"  # Branch holding the concept art and the template.
TEMPLATE_REF = (MAIN, "docs/act3/tools/art_review_template.html")  # The shared review page template.
BASE = "a3e4f5be"  # Commit the three art branches started from.
REFROW = ["necromancer", "bone_oracle", "wither_witch", "ferrywoman", "shrine_maiden", "marionette"]  # Existing characters shown as a non-markable size reference.
C = "assets/sprites/"  # Sprite root.
def _strips(ref, stems):
    """Existing still + _walk + _idle keys of `stems` on `ref`."""
    out = []
    for st in stems:
        for suf in ("", "_walk", "_idle"):
            try:
                show(ref, C + st + suf + ".png")
                out.append(st + suf)
            except subprocess.CalledProcessError:
                if suf == "":
                    MISSING.append(st)
    return out
MISSING = []  # Requested keys not found on the branch.
BUST = ["corsair/swashbuckler", "dynasty/bastet_hunter", "dynasty/embalmer", "dynasty/mummy_female", "norse/seer", "norse/sigrun", "norse/valkyrie",
        "player/lion_priestess", "player/rune_seer", "player/shield_maiden_hero", "player/the_embalmer"]  # Sprites whose bust boxes were refit.
REDRAWN = ["dynasty/khopesh_guard", "dynasty/khopesh_guard_walk", "dynasty/mummy", "dynasty/mummy_walk", "dynasty/ushabti_sentinel", "dynasty/ushabti_sentinel_walk",
           "player/lion_priestess", "norse/draugr_female_walk", "norse/fenrir_walk", "corsair/grappler_walk", "norse/brazier_lit_anim", "norse/brazier_doused_anim"]  # Redrawn / re-animated keys.
GROUPS = [
    ("bust", "Bust boxes (refit and checked on every frame)", "Idle and walk strips of the eleven figures whose bust boxes were refit; each is followed by its check sheet.",
     "Weak spot: Sigrun's wing flap leaves a faint stray pixel line by the shield on some frames; the lion-priestess's face is soft at 56 px.", BUST),
    ("redrawn", "Redrawn and re-animated", "Redrawn stills and strips, plus the two brazier loops (8 frames of 32x32).",
     "Weak spot: the lion-priestess's face is soft at 56 px.", REDRAWN),
]
MANIFESTS = {"tide-art": "docs/tide/ART_MANIFEST.md", "norse-art": "docs/norse/ART_MANIFEST.md", "dynasty-art": "docs/dynasty/ART_MANIFEST.md"}  # Manifest per branch.
COLLECTION = "wave1_art_r3"  # db collection the owner's marks are saved in.
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
    """Manifest table rows of the three branches: sprite key (no .png) -> its one-line description."""
    rows = {}
    for ref, mpath in MANIFESTS.items():
        for line in show(ref, mpath).decode("utf-8").splitlines():
            if not line.startswith("| `"):
                continue
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) < 2:
                continue
            desc = max(cells[1:], key=len)  # The description is the longest cell after the key.
            if re.fullmatch(r"[\d x]+", desc) or desc == cells[0]:
                continue
            desc = re.sub(r"`", "", desc)
            if len(desc) > 190:
                desc = desc[:190].rsplit(" ", 1)[0] + "…"
            for k in re.findall(r"`([^`]+)`", cells[0]):
                rows.setdefault(re.sub(r"\.png$", "", k), desc)
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
    if key.startswith("effects/") or key.endswith("_anim"):
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
    rank = { "bosses": 1, "summons": 2, "player": 3, "effects": 4, "icons": 5, "tiles": 6, "obstacles": 7, "decals": 7, "structures": 7, "projectiles": 4, "corsair": 1, "norse": 1, "dynasty": 1, "concord": 0, "epilogue": 8}
    base = re.sub(r"_(walk|idle)$", "", key)
    return (rank.get(folder, 9), base, 0 if key == base else 1)


def concept_fig(path: str, name: str) -> str:
    """A non-markable reference figure for one concept image (resized to 1000 px wide JPEG)."""
    im = Image.open(io.BytesIO(show(MAIN, path))).convert("RGB")
    im = im.resize((1000, round(im.size[1] * 1000 / im.size[0])), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82)
    return ('<figure class="inplay"><img src="data:image/jpeg;base64,%s" alt="%s" style="max-width:100%%;height:auto">'
            '<figcaption>%s: a reference, not marked.</figcaption></figure>') % (
        base64.b64encode(buf.getvalue()).decode(), html.escape(name), html.escape(name))


def ref_fig(name: str, scale: int) -> str:
    """A non-markable reference figure of an existing character at the cards' pixel scale."""
    data = show(MAIN, C + "player/" + name + ".png")
    w, h = Image.open(io.BytesIO(data)).size
    return ('<figure class="inplay"><img src="%s" width="%d" height="%d" alt="%s" style="image-rendering:pixelated">'
            '<figcaption>%s (existing): a reference, not marked.</figcaption></figure>') % (
        b64(data), w * scale, h * scale, name, name.replace("_", " ").capitalize())


def check_fig(key: str) -> str:
    """Non-markable bust check sheet figure for `key`."""
    path = "docs/last_acts/bust_check/" + key.replace("/", "_") + ".png"
    im = Image.open(io.BytesIO(show(MAIN, path))).convert("RGB")
    if im.size[0] > 1100:
        im = im.resize((1100, round(im.size[1] * 1100 / im.size[0])), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "PNG", optimize=True)
    return ('<figure class="inplay"><img src="data:image/png;base64,%s" alt="check %s" style="max-width:100%%;height:auto">'
            '<figcaption>%s bust check sheet: a reference, not marked.</figcaption></figure>') % (
        base64.b64encode(buf.getvalue()).decode(), html.escape(key), html.escape(key))


def main() -> None:
    rows = bible()
    sections, counts, total = [], {}, 0
    for gid, label, blurb, note, stems in GROUPS:
        out = []
        for st in stems:
            if gid == "bust":
                ks = []
                for suf in ("_idle", "_walk"):
                    try:
                        show(MAIN, C + st + suf + ".png")
                        ks.append(st + suf)
                    except subprocess.CalledProcessError:
                        pass
                for k in ks:
                    KEYREF[k] = MAIN
                    out.append(card(k, gid, describe(k, rows)))
                out.append(check_fig(st))
                total += len(ks)
                counts[gid] = counts.get(gid, 0) + len(ks)
            else:
                try:
                    show(MAIN, C + st + ".png")
                except subprocess.CalledProcessError:
                    MISSING.append(st)
                    continue
                KEYREF[st] = MAIN
                out.append(card(st, gid, describe(st, rows)))
                total += 1
                counts[gid] = counts.get(gid, 0) + 1
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-blurb"><b>%s</b></p><p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, html.escape(note), gid, "\n".join(out)))
    nav = [(g[0], g[1]) for g in GROUPS]
    page = show(*TEMPLATE_REF).decode("utf-8")
    page = (page.replace("<title>Act II Art Review</title>", "<title>Last Acts Art Review R3</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Last Acts Art Review R3</h1>")
            .replace("{{LEDE}}", "Round 3: %d images fixed after your round 2 marks. Sigrun's wing flap leaves a faint stray pixel line by the shield on some frames; the lion-priestess's face is soft at 56 px. "
                     "Strips animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB", "missing:", MISSING)


if __name__ == "__main__":
    main()
