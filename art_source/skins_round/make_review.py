"""make_review.py: builds docs/art/skins_round/review.html (self-contained; images embedded once as data URIs)."""
import base64, io, json, os, subprocess
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
P = f"{ROOT}/assets/sprites/player/"
def uri(b): return "data:image/png;base64," + base64.b64encode(b).decode()
def f(path): return uri(open(path, "rb").read())
chars = "brine_widow heretic_scribe marooned_quartermaster corsair_queen ghost_helmsman rune_seer shield_maiden_hero berserker_hero the_embalmer lion_priestess pharaohs_shade fallen_herald blind_saint the_unveiled fern_huntress herd_warden skywatcher horned_herald changeling_princess gravegardener".split()
data = []
for c in chars:
    row = {"id": c, "base": f(P + c + ".png"), "bw": Image.open(P + c + ".png").width, "skins": []}
    for fam in ("hyper", "untouchable", "deathlord"):
        fn = P + f"{c}_{fam}.png"
        if not os.path.exists(fn): continue
        new = os.path.exists(f"{ROOT}/art_source/skins_round/src/{c}_{fam}.png")
        im = Image.open(fn)
        s = {"fam": fam, "new": new, "w": im.width, "h": im.height, "still": f(fn)}
        if os.path.exists(P + f"{c}_{fam}_walk.png"): s["walk"] = f(P + f"{c}_{fam}_walk.png")
        if os.path.exists(P + f"{c}_{fam}_idle.png"): s["idle"] = f(P + f"{c}_{fam}_idle.png")
        row["skins"].append(s)
    data.append(row)
obst = []
names = "bookshelf_s bookshelf_m bookshelf_l blank_shelf_s blank_shelf_m blank_shelf_l toppled_shelf_s toppled_shelf_m toppled_shelf_l reading_desk_s reading_desk_l chart_table_s chart_table_l dyn_tomb_s dyn_tomb_l toppled_arch_s toppled_arch_l".split()
for n in names:
    rel = f"assets/sprites/obstacles/{n}_v.png"
    before = subprocess.run(["git", "show", f"9cf45471^:{rel}"], cwd=ROOT, capture_output=True).stdout
    obst.append({"n": n, "before": uri(before), "after": f(f"{ROOT}/{rel}"), "h": uri(open(f"{ROOT}/assets/sprites/obstacles/{n}.png", "rb").read())})
html = """<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Skins Round Review</title><style>
:root{--bg:#14161a;--fg:#e8e6ef;--dim:#9a98a8;--card:#1f2228;--line:#343844;--gold:#e8b84a}
@media (prefers-color-scheme:light){:root{--bg:#f3f1f7;--fg:#1c1b22;--dim:#5c5a68;--card:#fff;--line:#d5d2e0;--gold:#a8780a}}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.4 system-ui,sans-serif;padding:16px}
h1{font-size:22px;margin:0 0 4px}h2{font-size:17px;margin:28px 0 8px;border-bottom:1px solid var(--line);padding-bottom:4px}
p.n{color:var(--dim);margin:2px 0 12px}
.row{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:10px;margin:10px 0}
.row h3{margin:0 0 8px;font-size:15px}.grid{display:flex;flex-wrap:wrap;gap:14px}
.cell{display:flex;flex-direction:column;gap:4px;min-width:0}.cap{font-size:12px;color:var(--dim)}
.pix{image-rendering:pixelated;display:block}.stage{background:#161a1c;border-radius:4px;padding:6px;display:flex;gap:6px;align-items:flex-end}
.walk{background-repeat:no-repeat;image-rendering:pixelated}.tag{color:var(--gold)}
</style></head><body><h1>Skins round: owner review</h1>
<p class="n">New drawn art (image-generated, converted to the pixel palette). Each skin: base character, the skin still at 1x and 4x, four walk frames at 3x (frames 0, 2, 4, 6), and for bust rigs an idle (exhale) frame. Frames marked "existing" were already drawn before this round and are shown only for reference.</p>
<h2>Drawn skins</h2><div id="skins"></div>
<h2>Upright obstacles (before / after)</h2><p class="n">Before = the rotated horizontal art; after = generated upright art. Horizontal twin on the right for reference. All at 3x.</p><div id="obst"></div>
<script>
const D=%s, O=%s;
function img(src,w,h,z){const i=new Image();i.src=src;i.className='pix';i.style.width=w*z+'px';i.style.height=h*z+'px';return i}
function cell(cap,el){const c=document.createElement('div');c.className='cell';const s=document.createElement('div');s.className='stage';s.appendChild(el);c.appendChild(s);const k=document.createElement('div');k.className='cap';k.textContent=cap;c.appendChild(k);return c}
function frames(src,fw,h,idx,z){const w=document.createElement('div');w.style.display='flex';for(const i of idx){const d=document.createElement('div');d.className='walk';d.style.cssText=`width:${fw*z}px;height:${h*z}px;background-image:url(${src});background-size:auto ${h*z}px;background-position:-${i*fw*z}px 0`;w.appendChild(d)}return w}
const root=document.getElementById('skins');
for(const c of D){const r=document.createElement('div');r.className='row';r.innerHTML='<h3>'+c.id+'</h3>';const g=document.createElement('div');g.className='grid';
 const b=new Image();b.src=c.base;const tmp=b;
 r.appendChild(g);root.appendChild(r);
 const loadH=new Image();loadH.src=c.base;loadH.onload=()=>{const bh=loadH.naturalHeight;g.appendChild(cell('base '+c.bw+'x'+bh,img(c.base,c.bw,bh,4)));
 for(const s of c.skins){const wrap=document.createElement('div');wrap.className='cell';
  const top=document.createElement('div');top.className='grid';
  top.appendChild(cell(s.fam+(s.new?' (new)':' (existing)')+' 1x',img(s.still,s.w,s.h,1)));
  top.appendChild(cell('4x '+s.w+'x'+s.h,img(s.still,s.w,s.h,4)));
  if(s.walk)top.appendChild(cell('walk 0/2/4/6',frames(s.walk,s.w,s.h,[0,2,4,6],3)));
  if(s.idle)top.appendChild(cell('idle: still / exhale',frames(s.idle,s.w,s.h,[0,12],3)));
  wrap.appendChild(top);g.appendChild(wrap)}};}
const ro=document.getElementById('obst');
for(const o of O){const r=document.createElement('div');r.className='row';r.innerHTML='<h3>'+o.n+'_v</h3>';const g=document.createElement('div');g.className='grid';
 for(const [cap,src] of [['before',o.before],['after',o.after],['horizontal twin',o.h]]){const i=new Image();i.src=src;i.onload=()=>{g.appendChild(cell(cap+' '+i.naturalWidth+'x'+i.naturalHeight,img(src,i.naturalWidth,i.naturalHeight,3)))};}
 r.appendChild(g);ro.appendChild(r)}
</script></body></html>""" % (json.dumps(data), json.dumps(obst))
open(f"{ROOT}/docs/art/skins_round/review.html", "w").write(html)
print(len(html) / 1e6, "MB")
