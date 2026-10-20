"""Scratch: round 2 of the wave 2 art review (the redone images next to the old ones, and the new skins)."""
import base64
import html
import io
import json
import os
import subprocess
from PIL import Image

REPO = "/home/user/vampire-survivors-clone-lol"
HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = "/tmp/claude-0/-home-user-vampire-survivors-clone-lol/d5c098ec-bb2d-5b61-bfc3-6ed79c1e8fd5/scratchpad/act2/review/template.html"
BEFORE_REV = "f5b5cfc"  # main before the round 1 redos.
CHARS = ["gravecaller", "umbral_warden", "voidcaller", "bone_oracle", "fallen_confessor", "carrion_lord",
         "plague_scholar", "doomsayer", "barrow_warden", "grave_herald", "soulbinder", "wither_witch",
         "brine_widow", "heretic_scribe", "tide_widow"]  # Every playable character.
NOTES = {  # Round 1 note per redone key.
    "summons/bone_golem": "Here's what I'm thinking, in line with making our details bigger, let's make his torso a huge skull.",
    "summons/bone_golem_walk": "In line with changes above",
    "summons/ossuary_titan": "Edit in line with his changes above",
    "summons/ossuary_titan_walk": "As above",
    "icons/bone_golem": "Make the skull bigger",
    "effects/golem_slam": "The crater looked like it was moving in the last frames.",
    "epilogue/act2_4": "Make her more undead looking and hotter",
}
WHAT = {
    "summons/bone_golem": "The whole torso is one huge skull: teal soul flames in the sockets, the glowing jaw at the belly, stacked-bone arms with big fists.",
    "summons/bone_golem_walk": "Walk strip rebuilt from the new still.",
    "summons/ossuary_titan": "The same skull torso, grander: a crown of five bone spikes, gravestone pauldrons, heavier fists.",
    "summons/ossuary_titan_walk": "Walk strip rebuilt from the new still.",
    "icons/bone_golem": "The skull fills the badge (drawn by hand on the palette).",
    "icons/ossuary_titan": "Not flagged, but it still showed the old Titan, so it was redrawn to match.",
    "effects/golem_slam": "Frames 5-8 had jumped about 23 px up; every frame is shifted so the crater stays put.",
    "epilogue/act2_4": "A drowned dead goddess: dead blue-grey skin, glowing violet eyes, bone forearms and hands, ribs through a tear in a high-necked kelp gown; the hourglass figure, fully covered. The army on the left came out a little darker.",
}
REDO = list(WHAT.keys())


def b64(data: bytes) -> str:
    return "data:image/png;base64," + base64.b64encode(data).decode()


def frames_of(key: str, w: int, h: int) -> int:
    if key.startswith("effects/"):
        return max(1, w // h)
    for suf in ("_walk", "_idle"):
        if key.endswith(suf):
            sw = Image.open(os.path.join(REPO, "assets/sprites", key[: -len(suf)] + ".png")).size[0]
            return max(1, round(w / sw))
    return 1


def scale_for(key: str, w: int, h: int, frames: int) -> int:
    if key.startswith("epilogue/"):
        return 1
    if key.startswith("icons/"):
        return 6
    target = 260 if frames == 1 else 120
    s = max(1, min(6, round(target / max(1, h))))
    while w * s > 900 and s > 1:
        s -= 1
    return s


def fig(data: bytes, label: str, cls: str, s: int, key: str) -> str:
    w, h = Image.open(io.BytesIO(data)).size
    dw, dh = (w * s, h * s) if not key.startswith("epilogue/") else (512, 288)
    return '<figure class="%s"><img src="%s" width="%d" height="%d" alt="%s"><figcaption>%s</figcaption></figure>' % (
        cls, b64(data), dw, dh, html.escape(label), label)


def card(key: str, group: str, what: str, note: str, before: bytes | None, extra: list | None = None) -> str:
    now = open(os.path.join(REPO, "assets/sprites", key + ".png"), "rb").read()
    w, h = Image.open(io.BytesIO(now)).size
    frames = frames_of(key, w, h)
    s = scale_for(key, w, h, frames)
    stage = fig(now, "Now", "now", s, key)
    if before:
        stage += fig(before, "Before", "was", s, key)
    for data, label in (extra or []):
        stage += fig(data, label, "was", s, key)
    kind = "walk strip" if key.endswith("_walk") else "idle strip" if key.endswith("_idle") else (
        "effect strip" if frames > 1 else "panel" if key.startswith("epilogue/") else "icon" if key.startswith("icons/") else "still")
    meta = "%d×%d px" % (w, h) + (" · %d frames" % frames if frames > 1 else "") + (" · shown ×%d" % s if not key.startswith("epilogue/") else "")
    info = '<p class="subject">%s</p>' % html.escape(what)
    if note:
        info += '<p class="prev-note">Your note: %s</p>' % html.escape(note)
    cid = key.replace("/", "__")
    width = (512 if key.startswith("epilogue/") else w * s) * (1 + (1 if before else 0) + len(extra or []))
    name = os.path.basename(key).replace("_", " ").capitalize()
    return ('<article class="card%s" data-id="%s" data-owner="%s" data-frames="%d" data-w="%d" data-h="%d" data-s="%d">'
            '<div class="stage"><div class="ba">%s</div></div>'
            '<div class="info"><div class="title-row"><h4>%s</h4><span class="kind">%s</span></div>'
            '<p class="key">%s</p><p class="meta">%s</p>%s'
            '<div class="verdict" role="group" aria-label="Verdict for %s">'
            '<button type="button" class="v ok" data-v="ok">OK</button>'
            '<button type="button" class="v redo" data-v="redo">Redo</button>'
            '<span class="saved" aria-live="polite"></span></div>'
            '<label class="note-label" for="n-%s">Note</label>'
            '<textarea id="n-%s" class="note" rows="2" placeholder="What should change?"></textarea>'
            '</div></article>') % (" wide" if width > 560 else "", cid, group, frames, w, h, s, stage, html.escape(name),
                                   kind, html.escape(key), meta, info, html.escape(name), cid, cid)


def old(key: str) -> bytes | None:
    r = subprocess.run(["git", "show", "%s:assets/sprites/%s.png" % (BEFORE_REV, key)], cwd=REPO, capture_output=True)
    return r.stdout if r.returncode == 0 and r.stdout else None


def skin_cards(skin: str, blurb: str) -> list:
    out = []
    for c in CHARS:
        base_key = "necromancer" if c == "gravecaller" else c  # The Gravecaller wears the necromancer sprite.
        base = open(os.path.join(REPO, "assets/sprites/player", base_key + ".png"), "rb").read()
        title = c.replace("_", " ").title()
        out.append(card("player/%s_%s" % (c, skin), skin, "%s, %s look." % (title, blurb), "", None, [(base, "Base character")]))
        for suf in ("_walk", "_idle"):
            k = "player/%s_%s%s" % (c, skin, suf)
            if os.path.exists(os.path.join(REPO, "assets/sprites", k + ".png")):
                out.append(card(k, skin, "%s %s strip." % (title, "walk" if suf == "_walk" else "idle breathing"), "", None))
    return out


GROUPS = [
    ("redo", "Redone", "The images you flagged, new next to old. Strips animate the new version.",
     [card(k, "redo", WHAT[k], NOTES.get(k, ""), old(k)) for k in REDO]),
    ("untouchable", "Untouchable", "Drawn ghost-white phantom skins for every character (your note: don't just tint). Each still is shown next to the base character.",
     skin_cards("untouchable", "the ghost-white Untouchable")),
    ("deathlord", "Deathlord", "Drawn crowned dread-king skins for every character, black iron and gold over the player's violet.",
     skin_cards("deathlord", "the crowned Deathlord")),
]
parts = []
for g, label, blurb, cards in GROUPS:
    parts.append('<section class="ws" id="%s"><header class="ws-head"><h2>%s</h2><p class="ws-blurb">%s</p>'
                 '<p class="ws-count" data-count="%s"></p></header><div class="grid">' % (g, label, blurb, g))
    parts += cards
    parts.append("</div></section>")
total = sum(len(c) for _, _, _, c in GROUPS)
page = open(TEMPLATE).read()
page = page.replace("<title>Act II Art Review</title>", "<title>Wave 2 Art Review</title>").replace("<h1>Act II Art Review</h1>", "<h1>Wave 2 Art Review</h1>")
page = (page.replace("{{LEDE}}", "Round 2: the %d images you flagged, redone next to the old version, and the new drawn Untouchable and Deathlord skins for all 15 characters (%d items in all). The closing epilogue card waits for the Act III art. Mark each one OK or Redo." % (len(REDO), total))
        .replace("{{COLLECTION}}", '"wave2_art_r2"')
        .replace("{{NAV}}", "".join('<a href="#%s">%s</a>' % (g, l) for g, l, _, _ in GROUPS))
        .replace("{{CARDS}}", "\n".join(parts)).replace("{{TOTAL}}", str(total))
        .replace("{{COUNTS}}", json.dumps({g: len(c) for g, _, _, c in GROUPS})))
open(os.path.join(HERE, "wave2_art_review.html"), "w").write(page)
print(total, "items,", len(page) // 1024, "KB")
