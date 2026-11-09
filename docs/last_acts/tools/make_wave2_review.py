"""Last acts art review, wave 2, round 1: every PNG added by the two foundation art commits (the Celestial Host, 93f910e7,
and the Age of Titans, 609858c9), with the one-line description from each act's ART_MANIFEST.md / the ART_BIBLE, for the
owner's OK / Redo marks (db collection wave2_art_r1). Concept references come first as plain figures (not markable), then
a row of existing characters as a size reference. Derived from make_wave1_review_r3.py.

Usage: python3 docs/last_acts/tools/make_wave2_review.py <out.html>
Run from the repository root; reads every file from git refs (never the worktree).
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
REF = "claude/determined-pasteur-hdy1g6"  # Branch holding both commits, the concept art, the manifests and the template.
TEMPLATE_PATH = "docs/act3/tools/art_review_template.html"  # The shared review page template.
ACTS = [("host", "93f910e7", "The Celestial Host", "docs/host/ART_MANIFEST.md"),
        ("titans", "609858c9", "The Age of Titans", "docs/titans/ART_MANIFEST.md")]  # (id, commit, title, manifest) per act.
BIBLE = "docs/art/ART_BIBLE.md"  # Fallback description source.
CONCEPTS = [("art_source/concepts/act15/host.png", "Celestial Host: concept"),
            ("art_source/concepts/act15/host_lineup.png", "Celestial Host: lineup"),
            ("art_source/concepts/act15/host_bosses.png", "Celestial Host: bosses"),
            ("art_source/concepts/final5/titans_lineup.png", "Age of Titans: lineup"),
            ("art_source/concepts/final5/titans_bosses.png", "Age of Titans: bosses"),
            ("art_source/concepts/final5/titans_stage.png", "Age of Titans: stage")]  # Concept images, shown first.
REFROW = ["necromancer", "bone_oracle", "wither_witch", "ferrywoman"]  # Existing characters shown as a non-markable size reference.
C = "assets/sprites/"  # Sprite root.
KINDS = [("units", "Units and strips"), ("obstacles", "Obstacles"), ("icons", "Icons"), ("floors", "Floors"),
         ("markers", "Markers"), ("effects", "Effects")]  # Group kinds in page order.
FX_FRAMES = {"fx/host_trumpet_ring": 8, "fx/primeval_bomb_burst": 6, "fx/primeval_fossil_rise": 6}  # Frame counts of animated effect strips (from the manifests).
FLAWS = {"host": "Known flaws: the Virtue's torso is flat grey; the Judge is 58 px wide (over the ~46 px figure limit); the petal obstacle came out nearly square.",
         "titans": "Known flaws: the Scuttler is a pale speck; the Tyrant is tar-brown, not tar-black; the Skyraider's flap is a plain shear; the floors are plain noise."}  # Flaws the art agents reported.
COLLECTION = "wave2_art_r1"  # db collection the owner's marks are saved in.
MISSING = []  # Keys that could not be read.


def show(path: str) -> bytes:
    """Bytes of `path` at REF."""
    return subprocess.run(["git", "show", "%s:%s" % (REF, path)], cwd=REPO, capture_output=True, check=True).stdout


def added(commit: str) -> list:
    """Sprite keys (no extension) of the PNGs a commit added."""
    cmd = ["git", "show", "--name-only", "--format=", "--diff-filter=A", commit, "--", "assets/"]
    out = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, check=True).stdout.split()
    return sorted(p[len(C):-4] for p in out if p.startswith(C) and p.endswith(".png"))


def bible() -> dict:
    """Table rows of both manifests and the art bible: sprite key (no .png) -> one-line description."""
    rows = {}
    for path in [a[3] for a in ACTS] + [BIBLE]:
        for line in show(path).decode("utf-8").splitlines():
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
    """Description of `key` (its own row, its base sprite's, or a `_v` / strip variant's)."""
    base = re.sub(r"_(walk|idle|v)$", "", key)
    for k in (key, base):
        if k in rows:
            extra = " (walk strip)" if key.endswith("_walk") else " (idle breathing strip)" if key.endswith("_idle") else " (vertical variant)" if key.endswith("_v") else ""
            return rows[k] + extra
    return os.path.basename(key).replace("_", " ").capitalize() + "."


def kind_of(key: str) -> str:
    """Group kind of a sprite key by its folder."""
    f = key.split("/")[0]
    return {"icons": "icons", "obstacles": "obstacles", "tiles": "floors", "markers": "markers", "fx": "effects"}.get(f, "units")


def b64(data: bytes) -> str:
    """PNG bytes as a data URI."""
    return "data:image/png;base64," + base64.b64encode(data).decode()


def frames_of(key: str, w: int, h: int) -> int:
    """Frames in a strip: effects from FX_FRAMES, walk / idle strips by their still's width."""
    if key in FX_FRAMES:
        return FX_FRAMES[key]
    for suf in ("_walk", "_idle"):
        if key.endswith(suf):
            try:
                still = show(C + key[: -len(suf)] + ".png")
            except subprocess.CalledProcessError:
                return 1
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
    """One review card (the markup the template's script expects)."""
    data = show(C + key + ".png")
    w, h = Image.open(io.BytesIO(data)).size
    frames = frames_of(key, w, h)
    s = scale_for(key, w, h, frames)
    stage = '<figure class="now"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>Now</figcaption></figure>' % (
        b64(data), w * s, h * s, html.escape(key))
    kind = ("walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else
            "effect strip" if frames > 1 else "effect" if key.startswith("fx/") else "icon" if key.startswith("icons/")
            else "floor tile" if key.startswith("tiles/") else "obstacle" if key.startswith("obstacles/")
            else "marker" if key.startswith("markers/") else "still")
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


def concept_fig(path: str, name: str) -> str:
    """A non-markable reference figure for one concept image (resized to 1000 px wide JPEG)."""
    im = Image.open(io.BytesIO(show(path))).convert("RGB")
    im = im.resize((1000, round(im.size[1] * 1000 / im.size[0])), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82)
    return ('<figure class="inplay"><img src="data:image/jpeg;base64,%s" alt="%s" style="max-width:100%%;height:auto">'
            '<figcaption>%s: a reference, not marked.</figcaption></figure>') % (
        base64.b64encode(buf.getvalue()).decode(), html.escape(name), html.escape(name))


def ref_fig(name: str, scale: int) -> str:
    """A non-markable reference figure of an existing character at the cards' pixel scale."""
    data = show(C + "player/" + name + ".png")
    w, h = Image.open(io.BytesIO(data)).size
    return ('<figure class="inplay"><img src="%s" width="%d" height="%d" alt="%s" style="image-rendering:pixelated">'
            '<figcaption>%s (existing): a reference, not marked.</figcaption></figure>') % (
        b64(data), w * scale, h * scale, name, name.replace("_", " ").capitalize())


def main() -> None:
    rows = bible()
    sections = [('<section class="ws" id="refs"><header class="ws-head"><h2>References</h2><p class="ws-blurb">Concept art for both acts, and existing '
                 'characters at the same pixel scale for size.</p></header><div class="grid">%s%s</div></section>') % (
        "".join(concept_fig(p, n) for p, n in CONCEPTS), "".join(ref_fig(n, 3) for n in REFROW))]
    nav, counts, total = [("refs", "References")], {}, 0
    for aid, commit, title, _ in ACTS:
        keys = added(commit)
        for kid, klabel in KINDS:
            ks = [k for k in keys if kind_of(k) == kid]
            if not ks:
                continue
            gid = "%s_%s" % (aid, kid)
            out = []
            for k in ks:
                try:
                    out.append(card(k, gid, describe(k, rows)))
                except Exception as e:  # An unreadable PNG is listed, not fatal.
                    MISSING.append("%s (%s)" % (k, e))
            counts[gid] = len(out)
            total += len(out)
            sections.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s: %s</h2><p class="ws-blurb"><b>%s</b></p>'
                            '<p class="ws-count" data-count="%s"></p></header><div class="grid">%s</div></section>' % (
                                gid, title, klabel.lower(), html.escape(FLAWS[aid]), gid, "\n".join(out)))
            nav.append((gid, "%s %s" % (title.replace("The ", ""), klabel.lower())))
    page = show(TEMPLATE_PATH).decode("utf-8")
    lede = ("Round 1 of the wave 2 art: the Celestial Host's and the Age of Titans' shared enemies, props and icons. Bosses, characters and stage art "
            "come in a later round. %d images below. Flaws the art agents reported. Host: the Virtue's torso is flat grey; the Judge is 58 px wide "
            "(over the ~46 px figure limit); the petal obstacle came out nearly square. Titans: the Scuttler is a pale speck; the Tyrant is "
            "tar-brown, not tar-black; the Skyraider's flap is a plain shear; the floors are plain noise. Strips animate. Mark each one OK or Redo, "
            "with a note on what should change." % total)
    page = (page.replace("<title>Act II Art Review</title>", "<title>Last Acts Art Review W2</title>")
            .replace("<h1>Act II Art Review</h1>", "<h1>Last Acts Art Review W2</h1>")
            .replace("{{LEDE}}", html.escape(lede))
            .replace("{{COLLECTION}}", json.dumps(COLLECTION))
            .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l in nav))
            .replace("{{CARDS}}", "\n".join(sections)).replace("{{TOTAL}}", str(total))
            .replace("{{COUNTS}}", json.dumps(counts)))
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(total, "items", counts, len(page) // 1024, "KB", "missing:", MISSING)


if __name__ == "__main__":
    main()
