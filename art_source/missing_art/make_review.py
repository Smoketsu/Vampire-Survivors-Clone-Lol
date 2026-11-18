#!/usr/bin/env python3
"""make_review.py: builds docs/art/missing_art_round/review.html (one self-contained page, PNGs inlined as data URIs)
from art_source/missing_art/manifest.json. Run after make_missing_art.py:  python3 art_source/missing_art/make_review.py"""
import base64, io, json, os, html
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SP = os.path.join(ROOT, "assets", "sprites")
M = json.load(open(os.path.join(ROOT, "art_source", "missing_art", "manifest.json")))

def uri(img):
    b = io.BytesIO(); img.save(b, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()

def load(k): return Image.open(os.path.join(SP, k + ".png")).convert("RGBA")

# (title, where it appears, before (the old drawing), keys, kind) ; kind: "tile" shows a tiled sample, "frames:N" strips
G = []
def grp(name, intro, items): G.append((name, intro, items))

grp("1. Divine Wrath (Ilion, Olympus, Underworld)", "The Olympian act's signature rule, drawn by DivineWrath._draw() (scripts/enemies/pantheon/divine_wrath.gd). Wiring plan in WIRING.md.", [
 ("Wave warning band + tick", "Tidal wave telegraph: the line the wave starts on, and the tick every 2nd piece", "A 3 px aegean line plus an 8 px wide translucent line and marble chevron lines", ["pantheon_fx/edge", "pantheon_fx/edge_tick", "pantheon_fx/chevron"], "tile"),
 ("Wave front", "Leading edge of the tidal wave (the advancing edge is the bottom row)", "A 5 px aegean line plus a 2 px marble line on the front", ["pantheon_fx/wave_front"], "tile"),
 ("Wave body", "Water behind the front, scrolled", "Two flat translucent polygons (aegean dark 45%, aegean 40%)", ["pantheon_fx/wave_body"], "tile"),
 ("Lightning warning", "Bolt storm: crosshair at the centre and a lattice fill inside the circle, edge band reuses the band piece", "Concentric circles, a growing disc and a plus of lines", ["pantheon_fx/target", "pantheon_fx/fill"], "tile"),
 ("Bolt column", "The bolt itself dropping on the circle (last part of the telegraph)", "Nothing: the strike was only the circle and the damage tick", ["pantheon_fx/bolt_column"], ""),
 ("Strike landing", "Lightning landing: flash, shock ring (ends at 40 px), light cracks, sparks (8 frames, 96 px)", "Nothing but the circle disappearing", ["effects/wrath_strike"], "frames:8"),
 ("Chain arc", "Chain-lightning hops between enemies (also Stolen Thunder arcs, below)", "A 6-segment zigzag of 4 px aegean line with a 1.5 px white line", ["pantheon_fx/arc_thin", "pantheon_fx/arc_thick"], "tile"),
 ("Fissure", "Earth fissures (Hades / Underworld): telegraph tile, open crack body, end cap", "A crimson line growing to a 24 px black line with a flame line", ["pantheon_fx/fissure_warn", "pantheon_fx/fissure_body", "pantheon_fx/fissure_cap"], "tile"),
])
grp("2. Obstacles", "Placed at the exact keys EnvironmentArt asks for, so they appear with no code change.", [
 ("Frozen boulder (2 sizes)", "Vigrid zones I-II (norse_boulder, radius 10 / 14)", "Stacked flat discs (NorseGlyphs)", ["obstacles/norse_boulder_s", "obstacles/norse_boulder_l"], ""),
 ("Ash rock (3 sizes)", "Vigrid (norse_ash_rock, radius 12 / 16 / 22)", "Stacked flat discs with a dark ember disc", ["obstacles/norse_ash_rock_s", "obstacles/norse_ash_rock_m", "obstacles/norse_ash_rock_l"], ""),
 ("Drowned Helm's wheel", "The Maelstrom (maelstrom_wheel, size 12)", "CorsairGlyphs: a wood disc with 4 spoke lines", ["obstacles/maelstrom_wheel_m"], ""),
 ("Quarterdeck stair", "Treasure Galleon (fixed layout, placed vertical; the horizontal twin is spare)", "CorsairGlyphs._steps(): an oak rect with 7 lines", ["obstacles/galleon_steps_m_v", "obstacles/galleon_steps_m"], ""),
 ("Archive vertical variants", "Hollow Archive bookshelf / blank shelf / toppled shelf / reading desk / chart table when laid vertically (DERIVED from the horizontal art, see note)", "The code rect glyph", ["obstacles/bookshelf_s_v", "obstacles/bookshelf_m_v", "obstacles/bookshelf_l_v", "obstacles/blank_shelf_s_v", "obstacles/blank_shelf_m_v", "obstacles/blank_shelf_l_v", "obstacles/toppled_shelf_s_v", "obstacles/toppled_shelf_m_v", "obstacles/toppled_shelf_l_v", "obstacles/reading_desk_s_v", "obstacles/reading_desk_l_v", "obstacles/chart_table_s_v", "obstacles/chart_table_l_v"], ""),
 ("Tomb and arch vertical variants", "Necropolis dyn_tomb, Ul-Thalos toppled_arch when laid vertically (a diagonal flip of the horizontal art)", "The code rect glyph", ["obstacles/dyn_tomb_s_v", "obstacles/dyn_tomb_l_v", "obstacles/toppled_arch_s_v", "obstacles/toppled_arch_l_v"], ""),
])
grp("3. Markers", "World markers over enemies (SpriteBank.draw_flat, keys already asked for by ArchiveGlyphs).", [
 ("Scribe's curse sigil", "Over every cursed cultist, Archive and Ul-Thalos (fades with the curse)", "A dark disc with a turning arc and a biolume dot", ["markers/scribe_curse"], ""),
 ("Inscription", "Forbidden Verse mark on an inscribed enemy", "A violet arc and a line", ["markers/inscription"], ""),
])
grp("4. Act-spell effects", "Wiring plan in WIRING.md. Death Ray's fallback is not made: EmpireFx.death_ray already has art, so the fallback never shows.", [
 ("Stolen Thunder", "Olympus spell: charge orb (4 frames by charge) and the arcs (arc pieces above)", "A circle with 4 short spokes; zigzag lines", ["pantheon_fx/thunder_orb"], "frames:4"),
 ("Paris's Arrow", "Ilion spell: the arrow and its trail", "A line trail, a 2 px line and a triangle head", ["projectiles/paris_arrow", "aoe/paris_trail"], ""),
 ("River Styx / Lethe", "Underworld spell: water tile and bank piece for the base and the evolved Lethe's Flood", "A black thick line with bone-coloured bank line and drift ticks", ["pantheon_fx/styx_water", "pantheon_fx/styx_bank", "pantheon_fx/lethe_water", "pantheon_fx/lethe_bank"], "tile"),
 ("Linen Bind", "Necropolis spell: wrap over a marked enemy (3 sizes) and the tether ribbon", "Thin lines and 3 white rects per marked enemy", ["spell_fx/linen_wrap_s", "spell_fx/linen_wrap_m", "spell_fx/linen_wrap_l", "spell_fx/linen_strand"], "tile"),
])
grp("5. Small items", "", [
 ("Holmgang ring", "Valgard, Sigrun's duel: rod post, rope (horizontal and vertical), ground tile", "A rect of 3 x 11 rod rects with 1 px rope lines and a flat gold tint", ["norse/holmgang_post", "norse/holmgang_rope", "norse/holmgang_rope_v", "norse/holmgang_ground"], "tile"),
 ("Cursed Coin", "Treasure Galleon, Marrec's gold fever (radius 6 px): still and a 4-frame spin", "A brass disc with an ink rim and a glow", ["corsair/cursed_coin", "corsair/cursed_coin_spin"], "frames:4"),
 ("Passive icons", "Level-up cards, HUD, Codex: Fur-Lined Bones and Cold Iron", "The code icon glyph", ["icons/fur_lined_bones", "icons/cold_iron"], ""),
 ("Achievement badges", "Codex Achievements (each reused another spell / passive icon)", "Mass Grave: raise_dead; Untouchable: warding_ritual; Full Ossuary: forbidden_knowledge; Deathlord's Due: dread_rally; Swift Judgment: death_mark; Keep the Fires: grave_frost; Holmgang: calm_blood; Twilight of the Wolf: gungnir", ["icons/ach_mass_grave", "icons/ach_untouchable", "icons/ach_full_ossuary", "icons/ach_deathlords_due", "icons/ach_swift_judgment", "icons/ach_keep_the_fires", "icons/ach_holmgang", "icons/ach_twilight_of_the_wolf"], ""),
])
grp("6. Floor decals (23)", "Shown alone and laid on their stage's floor tile (a real tile from assets/sprites/tiles, decal at the tile centre). Dark and low contrast by design.", [
 ("Hollow Archive", "archive_halls_pages, archive_orrery_star, archive_stacks_pages, archive_wells_stain", "The hashed code decoration (small shapes)", ["decals/archive_halls_pages", "decals/archive_orrery_star", "decals/archive_stacks_pages", "decals/archive_wells_stain"], "decal"),
 ("Iron Citadel", "citadel_courts_scorch, citadel_gates_plate, citadel_lifts_hazard", "The hashed code decoration", ["decals/citadel_courts_scorch", "decals/citadel_gates_plate", "decals/citadel_lifts_hazard"], "decal"),
 ("Ul-Thalos, breakwater", "spire_breakwater_{barnacles,bones,glyph,kelp} (the barnacles also fill the main-menu vignette slot)", "The hashed code decoration", ["decals/spire_breakwater_" + k for k in ("barnacles", "bones", "glyph", "kelp")], "decal"),
 ("Ul-Thalos, gate", "spire_gate_*", "The hashed code decoration", ["decals/spire_gate_" + k for k in ("barnacles", "bones", "glyph", "kelp")], "decal"),
 ("Ul-Thalos, spire", "spire_spire_*", "The hashed code decoration", ["decals/spire_spire_" + k for k in ("barnacles", "bones", "glyph", "kelp")], "decal"),
 ("Ul-Thalos, steps", "spire_steps_*", "The hashed code decoration", ["decals/spire_steps_" + k for k in ("barnacles", "bones", "glyph", "kelp")], "decal"),
])
TILE = {"archive": "archive_halls", "citadel": "citadel_courts", "spire_breakwater": "spire_breakwater", "spire_gate": "spire_gate", "spire_spire": "spire_spire", "spire_steps": "spire_steps"}

def img_tag(k, z, tile=False):
    im = load(k); w, h = im.size
    if tile:
        return '<div class="tile" style="width:%dpx;height:%dpx;background-image:url(%s);background-size:%dpx %dpx"></div>' % (max(w * z, 96), max(h * z, 64), uri(im), w * z, h * z)
    return '<img src="%s" width="%d" height="%d" alt="">' % (uri(im), w * z, h * z)

def decal_on_tile(k, z):
    name = k.split("/")[1]
    tile = None
    for pre, t in TILE.items():
        if name.startswith(pre):
            tile = t
    tl = load("tiles/" + tile)
    d = load(k)
    box = tl.crop((0, 0, 64, 40)).copy()
    box.alpha_composite(d, ((64 - d.width) // 2, (40 - d.height) // 2))
    return '<img src="%s" width="%d" height="%d" alt="">' % (uri(box), 64 * z, 40 * z)

out = ['''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Missing Art Round</title><style>
:root{--bg:#14141a;--panel:#1d1d26;--ink:#e8e6f0;--dim:#9b98ad;--gold:#e0a82e;--line:#33333f}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,sans-serif}
main{max-width:1180px;margin:0 auto;padding:24px 16px 64px}
h1{font-size:26px;margin:0 0 4px}h2{font-size:20px;margin:36px 0 4px;color:var(--gold)}
p.i{color:var(--dim);margin:0 0 12px}.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px 14px;margin:12px 0}
.card h3{margin:0 0 2px;font-size:16px}.meta{color:var(--dim);font-size:13px;margin:2px 0}.meta b{color:var(--ink)}
.row{display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end;margin-top:10px}
.cell{text-align:left}.cell small{display:block;color:var(--dim);font-size:11px;margin-top:3px;max-width:260px;word-break:break-all}
.lab{font-size:11px;color:var(--dim);text-transform:uppercase;letter-spacing:.06em;margin:10px 0 2px}
img,.tile{image-rendering:pixelated;background:#0b0b10;border:1px solid #262633;display:block}
.tile{background-repeat:repeat;image-rendering:pixelated}.scroll{overflow-x:auto;max-width:100%}
</style></head><body><main><h1>Missing Art Round</h1>
<p class="i">Everything the Nov 2026 missing-art audit asked for, drawn on the art grid (1 art px = 1 screen px) in the locked palette by <code>art_source/missing_art/make_missing_art.py</code> (deterministic, no image generation, so no API cost). Each item at 1x and 4x on a dark background. Effects (groups 1 and 4, the Holmgang ring) are not wired yet: see <code>docs/art/missing_art_round/WIRING.md</code>. Obstacles, markers, icons and decals sit at the keys the code already asks for. Derived pieces (the vertical obstacle variants) are marked.</p>''']
total = 0
for name, intro, items in G:
    out.append("<h2>%s</h2><p class='i'>%s</p>" % (html.escape(name), html.escape(intro)))
    for title, where, before, keys, kind in items:
        out.append('<div class="card"><h3>%s</h3><div class="meta"><b>Where:</b> %s</div><div class="meta"><b>Before:</b> %s</div>' % (html.escape(title), html.escape(where), html.escape(before)))
        out.append('<div class="lab">1x</div><div class="row scroll">')
        for k in keys:
            out.append('<div class="cell">%s<small>%s (%dx%d)</small></div>' % (img_tag(k, 1), k, load(k).width // (int(kind.split(":")[1]) if kind.startswith("frames") else 1), load(k).height))
            total += 1
        out.append('</div><div class="lab">4x</div><div class="row scroll">')
        for k in keys:
            out.append('<div class="cell">%s</div>' % img_tag(k, 4))
        out.append("</div>")
        if kind == "tile":
            out.append('<div class="lab">tiled / repeated, 4x</div><div class="row">')
            for k in keys:
                out.append('<div class="cell">%s</div>' % img_tag(k, 4, True))
            out.append("</div>")
        if kind == "decal":
            out.append('<div class="lab">on its floor tile, 4x (Normal zoom is 1x)</div><div class="row">')
            for k in keys:
                out.append('<div class="cell">%s</div>' % decal_on_tile(k, 4))
            out.append("</div>")
        out.append("</div>")
out.append("</main></body></html>")
page = "\n".join(out)
dst = os.path.join(ROOT, "docs", "art", "missing_art_round", "review.html")
os.makedirs(os.path.dirname(dst), exist_ok=True)
open(dst, "w").write(page)
print(len(page) // 1024, "KB,", total, "pieces")
