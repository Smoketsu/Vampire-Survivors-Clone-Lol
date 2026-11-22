"""Last acts art review, round 2 (derived from make_wave1_review.py; db collection wave1_art_r2). Round 1 doc follows:

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
ALL = None  # Marker: every PNG the branch added since BASE.
MISSING = []  # Requested keys not found on their branch.
# Groups: (id, heading, blurb, weak spot note, [(ref, [keys or stems])], strips expanded?)
GROUPS = [
    ("chars", "Playable characters (redone as purple necromancers)", "Nine new playable characters, redone as purple necromancers; the existing characters come first as a size reference.",
     "Weak spots: Queen's figure mostly hidden by the long coat; the Embalmer lost some face detail in conversion; bust boxes estimated, so check the bounce.",
     [("tide-art", ["player/marooned_quartermaster", "player/corsair_queen", "player/ghost_helmsman"], True),
      ("norse-art", ["norse/rune_seer", "norse/shield_maiden_hero", "norse/berserker_hero"], True),
      ("dynasty-art", ["player/the_embalmer", "player/lion_priestess", "player/pharaohs_shade"], True)]),
    ("tide", "Black Tide: the owner's round 1 marks", "The sprites the owner marked in round 1.",
     "Weak spot: the ghost bosun is still navy (not redone).",
     [("tide-art", ["corsair/" + k for k in ("bosun_gorran_walk", "grappler_walk", "gunnery_mate_idle", "gunnery_mate_walk", "marrec_idle", "marrec_walk",
        "swashbuckler_idle", "swashbuckler_walk", "hull_crab", "hull_crab_walk", "kraken_arm_walk", "old_hollow_eye", "old_hollow_eye_walk", "vandermere_walk")]
       + ["summons/powder_wraith_walk"], False)]),
    ("norse", "Hall of the Slain: the Long Winter", "The Long Winter pieces: braziers and the frost creep.",
     "No known weak spots.", [("norse-art", ["norse/brazier_lit", "norse/brazier_doused", "norse/frost_creep"], False)]),
    ("norse_rest", "Hall of the Slain: enemies, bosses, floors, obstacles and icons", "Everything else the Hall of the Slain art branch added since round 1 (not yet reviewed).",
     "Weak spots: Odin's eyepatch is hard to read at 72 px; walk rigs auto-fitted (giants, Fenrir, weapon-heavy figures may need tuning); floors and obstacles procedural.",
     [("norse-art", ALL, False)]),
    ("dynasty", "Necropolis Dynasty: enemies, bosses, floors, obstacles and icons", "Everything else the Necropolis Dynasty art branch added since round 1 (not yet reviewed).",
     "Weak spots: Sekhmet is noisy; the mummy's green eyes are lost at 40 px; the scarab swarm is mushy; bust boxes set by eye.",
     [("dynasty-art", ALL, False)]),
]
EXCLUDE = {"norse/rune_seer", "norse/shield_maiden_hero", "norse/berserker_hero", "norse/brazier_lit", "norse/brazier_doused", "norse/frost_creep",
           "player/the_embalmer", "player/lion_priestess", "player/pharaohs_shade"}  # Stems already shown in round 2's character / Long Winter groups.
MANIFESTS = {"tide-art": "docs/tide/ART_MANIFEST.md", "norse-art": "docs/norse/ART_MANIFEST.md", "dynasty-art": "docs/dynasty/ART_MANIFEST.md"}  # Manifest per branch.
COLLECTION = "wave1_art_r2"  # db collection the owner's marks are saved in.
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


def main() -> None:
    rows = bible()
    sections, counts, total = [], {}, 0
    for gid, label, blurb, note, parts in GROUPS:
        keys = []
        for ref, items, expand in parts:
            ks = _strips(ref, items) if expand else []
            if items is ALL:
                for k in sorted(added(BASE, ref), key=order):
                    if re.sub(r"_(walk|idle)$", "", k) not in EXCLUDE:
                        ks.append(k)
            elif not expand:
                for k in items:
                    try:
                        show(ref, C + k + ".png")
                        ks.append(k)
                    except subprocess.CalledProcessError:
                        MISSING.append(k)
            for k in ks:
                KEYREF[k] = ref
            keys += ks
        cards = [card(k, gid, describe(k, rows)) for k in keys]
        counts[gid] = len(cards)
        total += len(cards)
        play = ""
        if gid == "chars":
            sc = scale_for("player/x", 0, max(Image.open(io.BytesIO(show(MAIN, C + "player/necromancer.png"))).size[1], 1), 1)
            play = '<div class="inplay-row" style="display:flex;flex-wrap:wrap;gap:12px">%s</div>' % "".join(ref_fig(n, sc) for n in REFROW)
        sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                        '<p class="ws-blurb"><b>%s</b></p><p class="ws-count" data-count="%s"></p>%s</header><div class="grid">%s</div></section>'
                        % (gid, label, blurb, html.escape(note), gid, play, "\n".join(cards)))
    nav = [(g[0], g[1]) for g in GROUPS]
    page = show(*TEMPLATE_REF).decode("utf-8")
    page = (page.replace("<title>Act II Art Review</title>", "<title>Last Acts Art Review R2</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Last Acts Art Review R2</h1>")
            .replace("{{LEDE}}", "Round 2: %d images (the redone characters, the Black Tide marks, the Long Winter pieces, and the rest of the Hall of the Slain and the Necropolis Dynasty). "
                     "Strips animate. Mark each one OK or Redo, with a note on what should change." % total)
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB", "missing:", MISSING)


if __name__ == "__main__":
    main()
