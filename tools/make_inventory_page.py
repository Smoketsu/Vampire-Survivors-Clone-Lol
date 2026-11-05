#!/usr/bin/env python3
"""Add sprite thumbnails to the Necropathy complete-game inventory page.

Role: post-processes the plain inventory HTML page (the one built from the game
data by the inventory extractor, docs/INVENTORY.md is its Markdown twin) and
writes a copy where every row that has art shows its still sprite as a small
pixel-art thumbnail. A row whose sprite file is missing shows a neutral "no art"
box, and a closing section lists every key with no art.

Inputs:
  --in      the plain page (no thumbnails; refuses a page that already has them)
  --out     where to write the result (may equal --in's directory, not --in)
  --model   model.json, the extractor's data dump (ids and display names of
            stages, enemies, spells, passives, summons, characters, skins,
            achievements, upgrades, relics, offerings, ultimates)
  --sprites the repo's assets/sprites folder

How sprites are found (the keys follow scripts/data/sprite_data.gd,
"<folder>/<id>" is assets/sprites/<folder>/<id>.png; strips such as *_walk and
*_idle are never used, only the still):
  enemies / minibosses / structures  the row's Id (or its display name via the model),
                                     searched in the faction folders (ENEMY_DIRS)
  bosses                             bosses/<stage boss id>; alternate forms are a
                                     gallery (BOSS_FORMS)
  characters                         player/<id> (the Gravecaller is player/necromancer)
  skins                              player/<id>_hyper, _<achievement skin>, _untouchable,
                                     _deathlord (a gallery under the characters table)
  summon classes, evolutions         summons/<id>
  spells, evolutions, passives, synergies (syn_), achievements (ach_), Ossuary
  upgrades, relics (relic_), offerings (offering_), ultimates   icons/<id>

Images are embedded once each as base64 data URIs in a JS map (SPR); the page's
script fills in the <img> elements only when a section is opened, so a closed
page costs no decoding. Thumbnail text never enters the DOM text (the "no art"
label is CSS generated), so the page search is unaffected.

Run:  python3 tools/make_inventory_page.py --in plain.html --out final.html \
          --model model.json
"""
import argparse
import base64
import collections
import html
import json
import os
import re
import struct
import sys

# Display box of one thumbnail, CSS px. Art is scaled by a whole number to fit
# TARGET_H px tall (2x for a 24 px icon); bigger art shrinks to fit the box.
BOX = 56
# Height in px a small sprite is scaled up towards (integer factor only).
TARGET_H = 48
# Folders searched, in order, for an enemy id (faction folders, then structures, then bosses).
ENEMY_DIRS = ["enemies", "holy", "court", "city", "concord", "eye", "empire", "pantheon",
              "shogunate", "inferno", "structures", "bosses", "projectiles"]
# Data ids whose sprite file is named differently: (folder-less) id -> file stem.
ID_ALIASES = {
    "deus": "deus_ex_machina",        # the stage's boss id vs bosses/deus_ex_machina.png
    "warlords_seal": "warlord_seal",  # the passive id vs icons/warlord_seal.png
}
# Boss alternate forms and phases shown as a gallery: (key, label). Attack-pose
# stills (_strike, _windup, _cast, _charge ...) are not forms and are left out.
BOSS_FORMS = [
    ("bosses/elder_vampire", "Elder, lord form"),
    ("bosses/lilith_demon", "Lilith, demon form"),
    ("bosses/morning_star_beast", "Morning Star, beast form"),
    ("bosses/merrow_changed", "Merrow, changed"),
    ("bosses/seraphine_avatar", "Seraphine, Avatar of the Dawn"),
    ("bosses/achilles_rage", "Achilles, rage"),
    ("bosses/hades_kneel", "Hades, kneeling"),
    ("bosses/hades_bident", "Hades, bident"),
    ("bosses/harrow_command", "Harrow, command"),
    ("bosses/vael_guard", "Vael, guard"),
    ("bosses/shogun_duel", "Shogun, duel"),
    ("bosses/amaterasu_mirror", "Amaterasu, mirror"),
    ("bosses/deus_ex_machina_founder", "Deus Ex Machina, Founder"),
    ("bosses/deus_ex_machina_siege", "Deus Ex Machina, siege"),
    ("bosses/deus_ex_machina_fire", "Deus Ex Machina, fire"),
    ("bosses/kestrel_blades", "Kestrel, blades"),
    ("bosses/archivist_split", "Archivist, split"),
]
# Player skin file suffixes in gallery column order: (suffix, column title).
SKIN_COLS = [("", "Default"), ("_hyper", "Hyper"), ("_ach", "Achievement"),
             ("_untouchable", "Untouchable"), ("_deathlord", "Deathlord")]
# The default Gravecaller sprite is not player/gravecaller.
CHARACTER_FILE = {"gravecaller": "necromancer"}


class Sprites:
    """Index of the sprite folder: (folder, stem) -> path, plus embedding order."""

    def __init__(self, root):
        self.root = root
        self.files = {}
        for dp, _, fns in os.walk(root):
            for f in fns:
                if f.endswith(".png"):
                    self.files[os.path.relpath(os.path.join(dp, f), root)[:-4]] = os.path.join(dp, f)
        self.used = collections.OrderedDict()   # key -> (w, h, data URI)

    def has(self, key):
        return key in self.files

    def use(self, key):
        """Embed `key` once; returns its key, or None when there is no file."""
        if key not in self.files:
            return None
        if key not in self.used:
            data = open(self.files[key], "rb").read()
            w, h = struct.unpack(">II", data[16:24])
            self.used[key] = (w, h, "data:image/png;base64," + base64.b64encode(data).decode())
        return key


class Builder:
    def __init__(self, spr, model):
        self.s = spr
        self.m = model
        self.missing = collections.OrderedDict()  # category -> list of (label, key tried)
        self.shown = 0
        self.listed = set()   # keys already in the no-art listing
        self.by_name = {}
        for kind in ("enemies", "spells", "passives", "units", "summon_evos", "characters", "synergies"):
            self.by_name[kind] = {r["name"]: r for r in model[kind]}
        self.by_name["upgrades"] = {r["name"]: r for r in model["upgrades"]}
        self.by_name["relics"] = {r[1]: r[0] for r in model["relics"]}
        self.by_name["offerings"] = {r[1]: r[0] for r in model["offerings"]}
        self.by_name["ultimates"] = {r[1]: r[0] for r in model["ultimates"]}
        self.by_name["ach"] = {r[1]: r[0] for r in model["achievements"]}
        self.by_name["hyper"] = {r[1]: r[0] for r in model["hyper_skins"]}

    def thumb(self, cat, label, *keys):
        """Thumbnail span for the first existing key; a 'no art' box (and a listing) otherwise."""
        keys = tuple(self.alias(k) for k in keys)
        for k in keys:
            if self.s.use(k):
                self.shown += 1
                return '<span class="th" data-s="%s"></span>' % html.escape(k)
        if keys and keys[0] not in self.listed:   # a key shared by two tables is listed once
            self.listed.add(keys[0])
            self.missing.setdefault(cat, []).append((label, keys[0]))
        return '<span class="th none" title="no art: %s"></span>' % html.escape(keys[0] if keys else label)

    def alias(self, key):
        """Apply ID_ALIASES to the id part of a 'folder/id' key."""
        folder, _, ident = key.partition("/")
        return folder + "/" + ID_ALIASES.get(ident, ident)

    def enemy_keys(self, eid):
        eid = ID_ALIASES.get(eid, eid)
        return ["%s/%s" % (d, eid) for d in ENEMY_DIRS]


def cell_wrap(th, inner):
    """First cell: thumbnail left, original content right."""
    return '<div class="nc">%s<div>%s</div></div>' % (th, inner)


def process_tables(page, b):
    """Add thumbnails to every recognised table, in place of the plain first cell."""
    m = b.m
    stages = {s["n"]: s for s in m["stages"]}
    enemy_by_id = {e["id"]: e for e in m["enemies"]}
    character_by_name = b.by_name["characters"]

    def tbl(match):
        table = match.group(0)
        heads = re.findall(r"<th>(.*?)</th>", table)
        rows = list(re.finditer(r"<tr><td>(.*?)</td>(.*?)</tr>", table))
        if not rows:
            return table
        h0 = tuple(heads[:3])
        unesc = html.unescape
        fn = None
        cat = None
        if heads[:2] == ["#", "Boss"]:
            cat = "Bosses"
            def fn(cells):
                st = stages.get(int(cells[0]))
                bid = st["bossid"] if st else ""
                return [("bosses/" + bid,)], unesc(cells[1])
        elif heads[0] == "Miniboss":
            cat = "Minibosses"
            def fn(cells):
                e = b.by_name["enemies"].get(unesc(cells[0]))
                return ([tuple(b.enemy_keys(e["id"]))] if e else [("?/" + unesc(cells[0]),)]), unesc(cells[0])
        elif heads[:2] == ["Kind", "Id"]:
            cat = "Enemies and structures"
            def fn(cells):
                eid = unesc(cells[1])
                return [tuple(b.enemy_keys(eid))], unesc(cells[0])
        elif heads[0] == "Spell":
            cat = "Spells"
            def fn(cells):
                sp = b.by_name["spells"].get(unesc(cells[0]))
                return [("icons/" + sp["id"],)] if sp else [("icons/?",)], unesc(cells[0])
        elif heads[0] == "Passive":
            cat = "Passives"
            def fn(cells):
                p = b.by_name["passives"].get(unesc(cells[0]))
                return [("icons/" + p["id"],)] if p else [("icons/?",)], unesc(cells[0])
        elif heads[0] == "Class":
            cat = "Summon classes"
            def fn(cells):
                u = b.by_name["units"].get(unesc(cells[0]))
                return [("summons/" + u["id"], "icons/" + u["id"])] if u else [("summons/?",)], unesc(cells[0])
        elif heads[0] == "Evolution" and heads[1] == "Base class(es)":
            cat = "Summon evolutions"
            def fn(cells):
                u = b.by_name["summon_evos"].get(unesc(cells[0]))
                return [("summons/" + u["id"], "icons/" + u["id"])] if u else [("summons/?",)], unesc(cells[0])
        elif heads[0] == "Synergy":
            cat = "Synergies"
            def fn(cells):
                u = b.by_name["synergies"].get(unesc(cells[0]))
                return [("icons/syn_" + u["id"],)] if u else [("icons/syn_?",)], unesc(cells[0])
        elif heads[:2] == ["Character", "Starting spell"]:
            cat = "Characters"
            def fn(cells):
                c = character_by_name.get(unesc(cells[0]))
                cid = c["id"] if c else "?"
                return [("player/" + CHARACTER_FILE.get(cid, cid),)], unesc(cells[0])
        elif heads[:2] == ["Character", "Hyper skin"]:
            cat = "Hyper skins"
            def fn(cells):
                c = character_by_name.get(unesc(cells[0]))
                cid = c["id"] if c else "?"
                return [("player/%s_hyper" % cid,)], unesc(cells[1])
        elif heads[0] == "Achievement":
            cat = "Achievements"
            def fn(cells):
                a = b.by_name["ach"].get(unesc(cells[0]))
                return [("icons/ach_" + a,)] if a else [("icons/ach_?",)], unesc(cells[0])
        elif heads[:2] == ["Tree", "Upgrade"]:
            cat = "Ossuary upgrades"
            def fn(cells):
                u = b.by_name["upgrades"].get(unesc(cells[1]))
                return [("icons/" + u["id"],)] if u else [("icons/?",)], unesc(cells[1])
        elif heads[0] == "Relic":
            cat = "Relics"
            def fn(cells):
                r = b.by_name["relics"].get(unesc(cells[0]))
                return [("icons/relic_" + r,)] if r else [("icons/relic_?",)], unesc(cells[0])
        elif heads[0] == "Offering":
            cat = "Offerings"
            def fn(cells):
                r = b.by_name["offerings"].get(unesc(cells[0]))
                return [("icons/offering_" + r,)] if r else [("icons/offering_?",)], unesc(cells[0])
        elif heads[0] == "Ultimate":
            cat = "Ultimates"
            def fn(cells):
                r = b.by_name["ultimates"].get(unesc(cells[0]))
                return [("icons/" + r,)] if r else [("icons/?",)], unesc(cells[0])
        if fn is None:
            return table

        def row(mr):
            # all cells of the row, raw HTML
            cells = re.findall(r"<td>(.*?)</td>", mr.group(0), flags=re.S)
            keysets, label = fn(cells)
            parts = [cell_wrap(b.thumb(cat, label, *keysets[0]), cells[0] if heads[0] != "Tree" else cells[0])]
            # the first cell is wrapped; for the Ossuary table the thumbnail belongs to the Upgrade cell
            if heads[0] == "Tree":
                parts = [cells[0], cell_wrap(b.thumb(cat, label, *keysets[0]), cells[1])] + cells[2:]
                return "<tr>" + "".join("<td>%s</td>" % c for c in parts) + "</tr>"
            parts += cells[1:]
            # a spell row gets a second thumbnail on its Evolution cell
            if heads[0] == "Spell":
                ev = b.by_name["spells"].get(unesc(cells[0]))
                parts[1] = cell_wrap(b.thumb("Spell evolutions", unesc(cells[1]),
                                             "icons/" + (ev["evo_id"] if ev else "?")), cells[1])
            return "<tr>" + "".join("<td>%s</td>" % c for c in parts) + "</tr>"

        return re.sub(r"<tr><td>.*?</tr>", row, table, flags=re.S)

    return re.sub(r"<table>.*?</table>", tbl, page, flags=re.S)


def gallery(title, note, cells):
    """A responsive grid of captioned thumbnails: cells = [(thumb html, caption)]."""
    items = "".join('<figure>%s<figcaption>%s</figcaption></figure>' % (t, html.escape(c)) for t, c in cells)
    return '<h3>%s</h3><p>%s</p><div class="gal">%s</div>' % (html.escape(title), html.escape(note), items)


def skin_table(b):
    """Every skin sprite, one row per character with a column per skin kind."""
    m = b.m
    ach = {s["character"]: s["id"] for s in m["ach_skins"]}
    head = "".join("<th>%s</th>" % t for _, t in SKIN_COLS)
    rows = []
    for c in m["characters"]:
        cid = c["id"]
        cells = []
        for suf, title in SKIN_COLS:
            if suf == "":
                key = "player/" + CHARACTER_FILE.get(cid, cid)
            elif suf == "_ach":
                if cid not in ach:
                    cells.append("<td></td>")
                    continue
                key = "player/%s_%s" % (cid, ach[cid])
            else:
                key = "player/" + cid + suf
            cells.append("<td>%s</td>" % b.thumb("Skins", "%s %s" % (c["name"], title.lower()), key))
        rows.append("<tr><td>%s</td>%s</tr>" % (html.escape(c["name"]), "".join(cells)))
    return ("<h3>Skin sprites</h3><p>Every skin still: default, Hyper, the four achievement skins (Dread Sovereign, "
            "Ivory Seer, Plague Doctor, Heretic Saint) and the universal Untouchable and Deathlord skins. "
            "Casket-only skins: none yet.</p>"
            '<div class="tw"><table><thead><tr><th>Character</th>%s</tr></thead><tbody>%s</tbody></table></div>' % (head, "".join(rows)))


def insert_in_section(page, sec_id, block):
    """Append `block` at the end of the body of the <details id=sec_id> section."""
    i = page.index('id="%s"' % sec_id)
    j = page.index("</div></details>", i)
    return page[:j] + block + page[j:]


CSS = """
/* Sprite thumbnails: a fixed box, whole-number pixel scaling, the 'no art' box is generated text so search ignores it. */
.nc{display:flex;gap:10px;align-items:center}
.th{flex:none;width:%(box)dpx;height:%(box)dpx;display:flex;align-items:center;justify-content:center;background:var(--bg);border:1px solid var(--line)}
.th img{image-rendering:pixelated;max-width:100%%;max-height:100%%;object-fit:contain}
.th.none{border-style:dashed;color:var(--mute);font-size:10px;line-height:1.1;text-align:center}
.th.none::after{content:"no art"}
.gal{display:grid;grid-template-columns:repeat(auto-fill,minmax(110px,1fr));gap:10px;margin:8px 0}
.gal figure{margin:0;display:flex;flex-direction:column;align-items:center;gap:4px;text-align:center;font-size:12px;color:var(--mute)}
.gal .th{width:%(big)dpx;height:%(big)dpx}
table .th{width:%(box)dpx}
"""

JS = r"""
/* Thumbnails: SPR maps a sprite key to [width, height, data URI]; images are created when a section opens. */
var SPR=%s;
function fillThumbs(root){
 [].forEach.call(root.querySelectorAll('.th[data-s]'),function(el){
  var d=SPR[el.getAttribute('data-s')];if(!d)return;
  var im=new Image(),s=d[1]<=%d?Math.max(1,Math.floor(%d/d[1])):0;
  im.src=d[2];im.alt='';im.decoding='async';
  if(s){im.width=d[0]*s;im.height=d[1]*s;}
  el.appendChild(im);el.removeAttribute('data-s');
 });
}
[].forEach.call(document.querySelectorAll('details.sec'),function(s){
 s.addEventListener('toggle',function(){if(s.open)fillThumbs(s);});
 if(s.open)fillThumbs(s);
});
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--in", dest="src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--model", required=True)
    ap.add_argument("--sprites", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites"))
    a = ap.parse_args()
    page = open(a.src, encoding="utf-8").read()
    if "<!--sprites-->" in page:
        sys.exit("input already has thumbnails; start from the plain page")
    model = json.load(open(a.model))
    b = Builder(Sprites(a.sprites), model)

    page = process_tables(page, b)
    # boss alternate forms gallery, under the bosses table
    forms = [(b.thumb("Boss forms", lab, k), lab) for k, lab in BOSS_FORMS if b.s.has(k)]
    page = insert_in_section(page, "bosses", gallery(
        "Alternate forms", "Boss forms and phases that have their own still sprite (attack poses and walk strips left out).", forms))
    page = insert_in_section(page, "characters", skin_table(b))

    # no-art section
    total_missing = sum(len(v) for v in b.missing.values())
    parts = ["<p>Rows above that show a dashed 'no art' box have no PNG at the key the game would load. "
             "%d rows have no art; %d thumbnails are shown from %d distinct files.</p>" % (total_missing, b.shown, len(b.s.used))]
    if not b.missing:
        parts.append("<p>Every row has art.</p>")
    for cat, items in b.missing.items():
        li = "".join("<li>%s <code>%s</code></li>" % (html.escape(l), html.escape(k)) for l, k in items)
        parts.append("<h3>%s (%d)</h3><ul>%s</ul>" % (html.escape(cat), len(items), li))
    sec = ('<details class="sec" id="noart"><summary><span class="t">Rows with no art (%d)</span><span class="hit"></span></summary>'
           '<div class="body">%s</div></details>' % (total_missing, "".join(parts)))
    page = page.replace("<footer>", sec + "<footer>", 1)
    page = page.replace("</nav>", '<a href="#noart">No art</a></nav>', 1)
    page = page.replace("</style>", CSS % {"box": BOX, "big": BOX + 8} + "</style>", 1)
    spr = json.dumps({k: list(v) for k, v in b.s.used.items()}, separators=(",", ":"))
    js = JS % (spr, TARGET_H, TARGET_H)
    page = page.replace("</script>", js + "</script>", 1) if False else page.rstrip() + "\n<script>\n" + js + "</script>\n<!--sprites-->\n"
    open(a.out, "w", encoding="utf-8").write(page)
    print("wrote %s: %d bytes, %d thumbnails, %d distinct images, %d rows with no art"
          % (a.out, len(page.encode()), b.shown, len(b.s.used), total_missing))
    for cat, items in b.missing.items():
        print("  %s: %d" % (cat, len(items)))


if __name__ == "__main__":
    main()
