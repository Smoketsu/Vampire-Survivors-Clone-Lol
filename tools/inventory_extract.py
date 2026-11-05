#!/usr/bin/env python3
"""Necropathy game-inventory extractor (step 1 of the inventory rebuild).

Role: reads the game's data files (scripts/data/*.gd, scripts/data/stages/*.gd and
the assets/ PNG folders) and writes one JSON dump, model.json, of everything the
complete-game inventory lists: stages, acts, bosses, enemy kinds, spells and their
evolutions, passives, summon classes and evolutions, synergies, characters, skins,
titles, achievements, Ossuary upgrades / masteries / relics / offerings,
difficulties, modifiers, ultimates, power-ups and sound counts.

Nothing is a hand-kept list of content: the stage order and the act names come from
StageRegistry (ORDER, ACTS), the enemy tables from every scripts/data/*enemy_data.gd
file, each stage boss from the stage's `const BOSS = XData.ARRIVAL`, and every other
row from its data table, so a new act or stage appears on the next run. It never
runs Godot and never touches user:// or any save.

The rebuild is three steps (tools/rebuild_inventory.sh runs all of them):
  tools/inventory_extract.py   data files -> model.json         (this script)
  tools/inventory_render.py    model.json -> plain page + docs/INVENTORY.md
  tools/make_inventory_page.py plain page -> final page with sprite thumbnails

Run:  python3 tools/inventory_extract.py --out-dir <dir>      (writes <dir>/model.json)
      --repo <path>   repository root (default: the folder above tools/)
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

# Repository root with a trailing slash (the folder above tools/); --repo overrides it.
R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')) + os.sep
# The data scripts folder (scripts/data/ under R); recomputed after --repo is parsed.
D = R + 'scripts/data/'
# Output folder given by --out-dir (model.json goes here).
OUT = '.'
_ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
_ap.add_argument('--out-dir', required=True, help='folder to write model.json into (created if missing)')
_ap.add_argument('--repo', default=None, help='repository root (default: above tools/)')
_a = _ap.parse_args()
if _a.repo:
    R = os.path.normpath(_a.repo) + os.sep
    D = R + 'scripts/data/'
OUT = _a.out_dir
os.makedirs(OUT, exist_ok=True)



def read(f): return open(D+f).read().split('\n')
def dict_rows(f,startre,depth=1):
    """top-level rows of a const dict: id -> {key: raw value} (depth-2 simple key: value lines)"""
    L=read(f); out={}
    st=None
    for i,l in enumerate(L):
        if re.match(startre,l): st=i;break
    if st is None: return out
    cur=None
    ind='\t'*depth
    for l in L[st+1:]:
        if re.match(r'^\}',l): break
        m=re.match('^'+ind+r'("?)([\w\.]+)\1:\s*\{\s*(#.*)?$',l)
        if m: cur=out.setdefault(m.group(2),{'_id':m.group(2)}); continue
        if cur is not None:
            m=re.match('^'+ind+r'\t"(\w+)":\s*(.+?),?\s*(#.*)?$',l)
            if m: cur.setdefault(m.group(1),m.group(2).strip().rstrip(','))
    return out
def order(f,const):
    """list of (id, section comment) from a const array"""
    L=read(f); res=[];sec='';on=False
    for l in L:
        if not on and re.match(r'^const '+const+r'\b',l): on=True
        if on:
            m=re.match(r'^\s*#\s*---\s*(.*?)\s*---',l)
            if m: sec=m.group(1); continue
            if l.strip().startswith('#'): continue
            for t in re.findall(r'"(\w+)"|(\b[A-Z]\w+\.ID\b)',l.split('#')[0]):
                res.append((t[0] or t[1],sec))
            if ']' in l.split('#')[0]: break
    return res
def s(x): return x.strip('"') if isinstance(x,str) else x

def txt(f): return open(D+f).read()
M={}
# ---------------- stages
# Campaign order of every registered stage (StageRegistry.ORDER).
ORDER_STAGES = [i for i, _ in order('stage_registry.gd', 'ORDER')]
# Act number -> (act name, faction label) taken from StageRegistry.ACTS ("subtitle" is the act's name).
_rt = txt('stage_registry.gd')
_ab = _rt[_rt.index('const ACTS'):]
_ab = _ab[:_ab.index('\n}')]
ACT_NAMES = {int(n): sub for n, sub in re.findall(r'\n\t(\d+): \{"name": "[^"]+", "subtitle": "([^"]+)"', _ab)}
M['act_names'] = ACT_NAMES
# Boss rows that live in the stage file itself (Acts I and II-stage 1/2 have no XData.ARRIVAL):
# stage id -> (display name, boss id).
INLINE_BOSS = {'graveyard': ('Sir Alaric, the Gravebreaker', 'alaric'), 'crimson_march': ('Marshal Vael, the Crimson Bulwark', 'vael')}


def _camel_to_snake(n):
    """HiveMotherData -> hive_mother_data (the data file naming rule)."""
    return re.sub(r'(?<!^)(?=[A-Z])', '_', n).lower()


stages = []
for n, sid in enumerate(ORDER_STAGES, 1):
    t = open(D + 'stages/%s_stage.gd' % sid).read()
    st = t[t.index('const STAGE'):]

    def const(name):
        m = re.search(r'^const %s(?::\s*\w+)?\s*:?=\s*([\d.]+)' % name, t, re.M)
        return float(m.group(1)) if m else None
    s_stage = {"n": n, "id": sid}
    s_stage['name'] = re.search(r'\n\t"display_name":\s*"([^"]+)"', st).group(1)
    s_stage['short'] = re.search(r'\n\t"short_name":\s*"([^"]+)"', st).group(1)
    s_stage['chapter'] = re.search(r'\n\t"chapter":\s*"([^"]+)"', st).group(1)
    a = re.search(r'\n\t"act":\s*(\d)', st)
    s_stage['act'] = int(a.group(1)) if a else 1
    pl = re.search(r'\n\t"playable":\s*(true|false)', st)
    s_stage['playable'] = (pl.group(1) == 'true') if pl else True
    am = re.search(r'\n\t"ash_mult":\s*([\d.]+)', st)
    s_stage['ash'] = float(am.group(1)) if am else const('ASH_MULT')
    hp = re.search(r'\n\t"enemy_hp_mult":\s*([\d.]+)', st)
    s_stage['hpmult'] = float(hp.group(1)) if hp else const('ENEMY_HP_MULT')
    dm = re.search(r'\n\t"enemy_damage_mult":\s*([\d.]+)', st)
    s_stage['dmgmult'] = float(dm.group(1)) if dm else const('ENEMY_DAMAGE_MULT')
    mu = re.search(r'\n\t"music":\s*"(\w+)"', st)
    s_stage['music'] = mu.group(1) if mu else ''
    d = re.search(r'\n\t"description":\s*"(.*?)",\n', st)
    s_stage['desc'] = d.group(1) if d else ''
    ut = re.search(r'\n\t"unlock_text":\s*"(.*?)"', st)
    s_stage['unlock'] = ut.group(1) if ut else ''
    zn = re.findall(r'"name": "([^"]+)"', t[t.find('const ZONES'):t.find('const ZONES') + 7000]) if 'const ZONES' in t else []
    s_stage['zones'] = [z for z in zn if z][:4]
    rk = re.search(r'const RECKONING[^\n]*\{.*?"banner":\s*"([^"]+)"', t, re.S)
    s_stage['reckoning'] = rk.group(1) if rk else ''
    bc = re.search(r'^const BOSS(?::\s*Dictionary)?\s*:?=\s*(\w+)\.ARRIVAL', t, re.M)
    if bc:   # the boss's own data file holds ARRIVAL {id, display_name}
        bt = txt(_camel_to_snake(bc.group(1)) + '.gd')
        i = bt.index('const ARRIVAL')
        s_stage['boss'] = re.search(r'"display_name":\s*"([^"]+)"', bt[i:]).group(1)
        s_stage['bossid'] = re.search(r'"id":\s*"(\w+)"', bt[i:]).group(1)
        s_stage['bossfile'] = _camel_to_snake(bc.group(1)) + '.gd'
    else:
        s_stage['boss'], s_stage['bossid'] = INLINE_BOSS[sid]
        s_stage['bossfile'] = ''
    stages.append(s_stage)
M['stages'] = stages
STAGE_BY_ID = {s_['id']: s_ for s_ in stages}
# ---------------- enemies
# Enemy tables shared by an act (file name -> (faction label, "appears in" label)). Every other
# scripts/data/<stage>_enemy_data.gd is a per-stage table: faction = its stage's act, where = the stage's short name.
SHARED_ENEMY_FILES = {
    'enemy_data.gd': ('Covenant', 'shared / Graveyard'), 'march_enemy_data.gd': ('Covenant', 'Crimson March'),
    'sanctum_enemy_data.gd': ('Covenant', 'Sanctum'), 'battle_sister_data.gd': ('Covenant', 'Crimson March, Sanctum'),
    'eye_enemy_data.gd': ('Ancient Eye', 'Act II shared'), 'empire_enemy_data.gd': ('Empire', 'Act III shared'),
    'pantheon_enemy_data.gd': ('Republic', 'Act IV shared'), 'shogunate_enemy_data.gd': ('Shogunate', 'Act V shared'),
    'inferno_enemy_data.gd': ('Inferno', 'Act VI shared'), 'court_enemy_data.gd': ('Sanguine Court', 'Act VII shared'),
    'city_enemy_data.gd': ('Last Line', 'Act VIII shared'), 'concord_enemy_data.gd': ('Concord', 'Act IX shared'),
}
# Faction label of each act (enemy tables are grouped by it).
ACT_FACTION = {1: 'Covenant', 2: 'Ancient Eye', 3: 'Empire', 4: 'Republic', 5: 'Shogunate', 6: 'Inferno', 7: 'Sanguine Court', 8: 'Last Line', 9: 'Concord'}
M['act_faction'] = ACT_FACTION
FILEFAC = dict((f, v[0]) for f, v in SHARED_ENEMY_FILES.items())
FILESTAGE = dict((f, v[1]) for f, v in SHARED_ENEMY_FILES.items())
for _p in sorted(glob.glob(D + '*_enemy_data.gd')):
    _f = os.path.basename(_p)
    _sid = _f[:-len('_enemy_data.gd')]
    if _f not in FILEFAC and _sid in STAGE_BY_ID:
        FILEFAC[_f] = ACT_FACTION[STAGE_BY_ID[_sid]['act']]
        FILESTAGE[_f] = STAGE_BY_ID[_sid]['short']
_unmapped = [os.path.basename(p) for p in glob.glob(D + '*enemy_data.gd') if os.path.basename(p) not in FILEFAC]
if _unmapped:
    print('note: enemy tables not read (no stage, not shared):', _unmapped, file=sys.stderr)


def erows(f):
    """Rows of a file's `const ENEMIES` dict: list of {id, key: raw value}."""
    L = read(f)
    out = []
    cur = None
    on = False
    for l in L:
        if re.match(r'^const ENEMIES', l):
            on = True
            continue
        if not on:
            continue
        if re.match(r'^\}', l):
            break
        m = re.match(r'^\t"(\w+)":\s*\{\s*$', l)
        if m:
            cur = {'id': m.group(1)}
            out.append(cur)
            continue
        if cur is not None:
            m = re.match(r'^\t\t"(\w+)":\s*(.+?),?\s*(#.*)?$', l)
            if m:
                cur.setdefault(m.group(1), m.group(2).strip().rstrip(','))
    return out


# Boolean row keys shown as traits.
ENEMY_FLAGS = ('miniboss', 'is_structure', 'always_elite', 'fodder', 'super', 'vehicle', 'demon', 'construct', 'flier', 'night', 'bronze', 'floating', 'phases')
enemies = []
for f in FILEFAC:
    fac = FILEFAC[f]
    for r in erows(f):
        flags = [k for k in ENEMY_FLAGS if r.get(k) == 'true']
        kind = 'miniboss' if 'miniboss' in flags else ('structure' if 'is_structure' in flags or r.get('behavior', '').strip('"') in ('structure',) else 'regular')
        enemies.append({'id': r['id'], 'name': s(r.get('display_name', r['id'])), 'faction': fac, 'where': FILESTAGE[f], 'behavior': s(r.get('behavior', '')), 'tier': s(r.get('tier', '')) or '', 'body': (r.get('body', '').split('.')[-1].lower() if r.get('body') else ''), 'flags': flags, 'kind': kind, 'hp': r.get('max_hp'), 'xp': r.get('xp')})
M['enemies'] = enemies
# ---------------- spells / evolutions / passives
sp=dict_rows('ability_data.gd',r'^const SPELLS'); so=order('ability_data.gd','SPELL_ORDER')
ev=dict_rows('evolution_data.gd',r'^const EVOLUTIONS'); eo=order('evolution_data.gd','ORDER')
pa=dict_rows('passive_data.gd',r'^const PASSIVES'); po=order('passive_data.gd','ORDER')
un=dict_rows('unit_data.gd',r'^const UNITS'); uo=order('unit_data.gd','CLASS_ORDER')
se=dict_rows('summon_evolution_data.gd',r'^const EVOLUTIONS'); seo=order('summon_evolution_data.gd','ORDER')
ch=dict_rows('character_data.gd',r'^const CHARACTERS'); co=order('character_data.gd','ORDER')
def secact(sec):
    m=re.search(r'Act (I{1,3}|IV|V|VI{0,3}|IX|X)\b',sec or '')
    return m.group(0) if m else ('Base game' if not sec else sec)
# unlocks
ut=txt('unlock_data.gd'); blk=ut[ut.index('const UNLOCKS'):ut.index('const PLATE_HEADINGS')]
unl={}
cur=None
for l in blk.split('\n'):
    m=re.match(r'^\t"(\w+)": \{(.*)$',l)
    if m: cur=m.group(1); unl[cur]=m.group(2); continue
    if cur and l.startswith('\t\t'): unl[cur]+=' '+l.strip()
    elif l.startswith('\t') and not l.startswith('\t#') : pass
U={}
for k,b in unl.items():
    ty=re.search(r'"type": "(\w+)"',b).group(1)
    src=re.search(r'"(boss|achievement)": "(\w+)"',b)
    tx=re.search(r'"text": "(.*?)"\s*[,}]',b)
    U[k]={'type':ty,'src':src.group(1) if src else '', 'val':src.group(2) if src else '','text':tx.group(1) if tx else ''}
M['unlocks']=U
spells=[]
evo_by_base={e['base'][0] if False else v['base'].strip('"'):k for k,v in ev.items()}
for i,sec in so:
    r=sp[i]; e=evo_by_base.get(i)
    spells.append({'id':i,'name':s(r['display_name']),'desc':s(r['description']),'section':secact(sec),'evo':s(ev[e]['display_name']) if e else '','evo_id':e,'evo_desc':s(ev[e]['description']) if e else '','passive':s(ev[e]['passive']) if e else '','unlock':U.get(i,{}).get('text','')})
M['spells']=spells
ARMY=[i for i,_ in order('passive_data.gd','ARMY_PASSIVES')]
SPELLP=[i for i,_ in order('passive_data.gd','SPELL_PASSIVES')]
paired={}
for k,v in ev.items(): paired.setdefault(s(v['passive']),[]).append(s(v['display_name'])+' (spell)')
for k,v in se.items(): paired.setdefault(s(v['passive']),[]).append(s(v['display_name'])+' (summon)')
passives=[]
for i,sec in po:
    if i=='PactData.ID':
        passives.append({'id':'profane_pact','name':'Profane Pact','desc':'A dark pact brings more, stronger foes and richer spoils from every death.','section':'Base game','act':'','kind':'Pact (opt-in difficulty)','paired':[],'unlock':''});continue
    r=pa[i]
    kind='Army' if i in ARMY else ('Spell' if i in SPELLP else 'General')
    passives.append({'id':i,'name':s(r['display_name']),'desc':s(r['description']),'section':secact(sec),'act':r.get('act',''),'kind':kind,'paired':paired.get(i,[]),'unlock':U.get(i,{}).get('text',''),'classes':r.get('classes','')})
M['passives']=passives
# summon classes
units=[]
evo_by_class={}
for k,v in se.items():
    for b in re.findall(r'"(\w+)"',v['bases']): evo_by_class.setdefault(b,[]).append(k)
for i,sec in uo:
    r=un[i]
    evs=[ (s(se[e]['display_name']),s(se[e]['passive']),s(se[e]['mode'])) for e in evo_by_class.get(i,[])]
    units.append({'id':i,'name':s(r['display_name']),'plural':s(r.get('plural','')),'desc':s(r['description']),'section':secact(sec),'profile':s(r.get('attack_profile','')),'evos':evs,'unlock':U.get(i,{}).get('text','')})
M['units']=units
M['summon_evos']=[{'id':k,'name':s(se[k]['display_name']),'bases':re.findall(r'"(\w+)"',se[k]['bases']),'passive':s(se[k]['passive']),'mode':s(se[k]['mode']),'desc':s(se[k]['description']),'section':secact(dict(seo).get(k,''))} for k,_ in seo]
# synergies
sy=dict_rows('synergy_data.gd',r'^const SYNERGIES'); syo=order('synergy_data.gd','ORDER')
M['synergies']=[{'id':i,'name':s(sy[i]['display_name']),'desc':s(sy[i]['description']),'requires':sy[i].get('requires','')} for i,_ in syo]
# characters
ct=txt('character_data.gd'); cblk=ct[ct.index('const CHARACTERS'):]
cparts=re.split(r'\n\t"(\w+)": \{\n',cblk)
chars=[]
cm={cparts[i]:cparts[i+1] for i in range(1,len(cparts),2)}
for i,sec in co:
    b=cm[i]
    inn=re.search(r'"innate": \{\s*"id": "\w+", "name": "([^"]+)"',b)
    chars.append({'id':i,'name':re.search(r'"display_name": "([^"]+)"',b).group(1),'spell':re.search(r'"spell": "(\w+)"',b).group(1),'innate':inn.group(1) if inn else '(none: baseline)','unlocked':'starts_unlocked": true' in b,'section':secact(sec)})
M['characters']=chars
# skins
sk=txt('skin_data.gd')
hn=sk[sk.index('const HYPER_NAMES'):sk.index('const HYPER_TINTS')]
M['hyper_skins']=re.findall(r'"(\w+)": "([^"]+)"',hn)
ask=sk[sk.index('const ACHIEVEMENT_SKINS'):sk.index('const CASKET_SKINS')]
ap=re.split(r'\n\t"(\w+)": \{\n',ask)
M['ach_skins']=[{'id':ap[i],'name':re.search(r'"display_name": "([^"]+)"',ap[i+1]).group(1),'character':re.search(r'"character": "(\w+)"',ap[i+1]).group(1),'text':re.search(r'"unlock_text": "([^"]+)"',ap[i+1]).group(1)} for i in range(1,len(ap),2)]
us=sk[sk.index('const UNIVERSAL_SKINS'):sk.index('const UNIVERSAL_ORDER')]
M['univ_skins']=re.findall(r'\n\t"(\w+)": \{\n\t\t"display_name": "([^"]+)"',us)
M['casket_skins']=0
# titles
tt=txt('title_data.gd'); tb=tt[tt.index('const TITLES'):tt.index('const NONE_TEXT')]
M['titles']=re.findall(r'"(\w+)": \{"display_name": "([^"]+)", "achievement": "(\w+)"',tb)
# achievements
mt=txt('meta_data.gd'); ab=mt[mt.index('const ACHIEVEMENTS := {'):mt.index('const UNTOUCHABLE_HP_FRACTION')]
ach=[]
for m in re.finditer(r'\n\t"(\w+)": \{"display_name": "([^"]+)", "description": "([^"]+)",\s*\n?\s*(?:"stat"[^\n]*?"unlock": "([^"]*)"|[^\n]*)',ab):
    ach.append((m.group(1),m.group(2),m.group(3),m.group(4) or ''))
M['achievements']=ach
M['achievement_order']=[i for i,_ in order('meta_data.gd','ACHIEVEMENT_ORDER')]
# upgrades
up=mt[mt.index('const UPGRADES := {'):mt.index('const LAST_RITES_HP_FRACTION')]
ents=re.split(r'\n\t"(\w+)": \{',up)
deep=[i for i,_ in order('meta_data.gd','DEEP_UPGRADES')]
upg=[]
for i in range(1,len(ents),2):
    b=ents[i+1]; idd=ents[i]
    tree=re.search(r'"tree": "(\w+)"',b).group(1); dn=re.search(r'"display_name": "([^"]+)"',b).group(1)
    ds=re.search(r'"description": "([^"]+)"',b)
    costs=re.search(r'"costs": \[([^\]]*)\]',b)
    c=[x.strip() for x in costs.group(1).split(',') if x.strip()]
    upg.append({'id':idd,'tree':tree,'name':dn,'desc':ds.group(1) if ds else '','listed':len(c),'levels':10 if idd in deep else len(c),'costs':c})
M['upgrades']=upg
# relics etc
rt=txt('relic_data.gd'); rb=rt[rt.index('const RELICS'):rt.index('const AUTOTEST_MAX_RELICS')]
M['relics']=re.findall(r'\n\t"(\w+)": \{"display_name": "([^"]+)", "icon": "[^"]+",\s*\n\t\t"short": "([^"]+)".*?"price": (\d+)',rb,re.S)
ot=txt('offering_data.gd'); ob=ot[ot.index('const OFFERINGS'):]
M['offerings']=re.findall(r'\n\t"(\w+)": \{"display_name": "([^"]+)", "icon": "[^"]+",\s*\n\t\t"short": "([^"]+)".*?"price": (\d+)',ob,re.S)
ms=txt('mastery_data.gd'); _i=ms.index('const CLASSES'); mb=ms[_i:ms.index(']',ms.index('=',_i))]
M['mastery_classes']=re.findall(r'"(\w+)"',mb)
rc=txt('recolour_data.gd'); M['recolours']=re.findall(r'\n\t"(\w+)": \{\n\t\t"display_name": "([^"]+)"',rc)
# difficulties / modifiers
dd=txt('difficulty_data.gd'); db=dd[dd.index('const LEVELS'):dd.index('const MULT_KEYS')]
dp=re.split(r'\n\t"(\w+)": \{',db)
M['difficulties']=[{'id':dp[i],'name':re.search(r'"display_name": "([^"]+)"',dp[i+1]).group(1),'tag':re.search(r'"tagline": "([^"]+)"',dp[i+1]).group(1),'ash':re.search(r'"ash_mult": ([\d.]+)',dp[i+1]).group(1),'boss':re.search(r'"boss_hp": ([\d.]+)',dp[i+1]).group(1)} for i in range(1,len(dp),2)]
rm=txt('run_modifier_data.gd'); rb=rm[rm.index('const MODIFIERS'):]
rp=re.split(r'\n\t"(\w+)": \{',rb)
M['modifiers']=[{'id':rp[i],'name':re.search(r'"display_name": "([^"]+)"',rp[i+1]).group(1),'desc':re.search(r'"description": "([^"]+)"',rp[i+1]).group(1),'ash':re.search(r'"ash_gain": ([\d.\-]+)',rp[i+1]).group(1)} for i in range(1,len(rp),2)]
ul=txt('ultimate_data.gd'); ub=ul[ul.index('const ULTIMATES'):ul.index('# --- Sovereign')]
M['ultimates']=re.findall(r'\n\t"(\w+)": \{"display_name": "([^"]+)", "short": "[^"]+", "tagline": "([^"]+)",\s*\n\t\t"description": "([^"]+)"',ub)
# Base max HP of each stage boss from its data file (Alaric and Vael sit in the Act I enemy tables).
bosses = []
for s_ in stages:
    bid = s_['bossid']
    hp = ''
    if bid == 'alaric':
        hp = re.search(r'const BOSS := \{.*?"max_hp": ([\d.]+)', txt('enemy_data.gd'), re.S).group(1)
    elif bid == 'vael':
        hp = re.search(r'const VAEL := \{.*?"max_hp": ([\d.]+)', txt('march_enemy_data.gd'), re.S).group(1)
    elif s_['bossfile']:
        t_ = txt(s_['bossfile'])
        m = re.search(r'"max_hp": ([\d.]+)', t_) or re.search(r'const MAX_HP: float = ([\d.]+)', t_)
        hp = m.group(1) if m else ''
    bosses.append((s_['n'], bid, hp))
M['boss_hp']={b:h for _,b,h in bosses}
# sprites
cnt=collections.Counter()
for p in glob.glob(R+'assets/**/*.png',recursive=True):
    rel=os.path.relpath(p,R+'assets').split(os.sep)
    cnt['/'.join(rel[:2]) if rel[0]=='sprites' and len(rel)>2 else rel[0]]+=1
M['sprites']=dict(cnt); M['sprite_total']=sum(cnt.values())
# powerups
M['powerups']=re.findall(r'"(\w+)"',txt('powerup_data.gd')[txt('powerup_data.gd').index('const ORDER'):].split('\n')[0])
# sound
sdt=txt('sound_data.gd')
M['sound_counts']={}
curc=None
for l in sdt.split('\n'):
    m=re.match(r'^const (\w*SOUNDS)\b',l)
    if m: curc=m.group(1);M['sound_counts'][curc]=0;continue
    if curc and re.match(r'^\}',l): curc=None;continue
    if curc and re.match(r'^\t"\w+":',l): M['sound_counts'][curc]+=1
# ---------------- music, epilogue, codex tabs
# Run-loop score titles: SoundData.SCORES keys with the title quoted in the comment above the table
# ("tide" = "Below the Tide"); the Act I loop (music "") and the menu theme "Grave Lullaby" are added by the renderer.
_sd = txt('sound_data.gd')
_sc = _sd[:_sd.index('const SCORES')]
_sc = _sc[_sc.rindex('## Run-loop scores'):]
_keys = re.findall(r'^\t"(\w+)": \w+_SCORE', _sd[_sd.index('const SCORES'):_sd.index('const SCORE_PACKS')], re.M)
_sct = _sd[_sd.index('const SCORES'):_sd.index('const SCORE_PACKS')]   # the table, whose lines may carry the title as a comment
M['music'] = {k: (re.search(r'"%s" = "([^"]+)"' % k, _sc) or re.search(r'"%s": \w+,\s*#[^\n]*?"([^"]+)"' % k, _sct) or [None, k])[1] for k in _keys}
M['menu_theme'] = re.search(r'"(Grave Lullaby)"', txt('menu_theme_data.gd')).group(1)
# Epilogue parts (achievement that opens each, heading, picture panels) and closing cards.
_ep = txt('epilogue_data.gd')
_ep_parts = _ep[:_ep.index('const CLOSINGS')]
_pt = re.split(r'\n\t?\t?"id": "(\w+)",', _ep_parts)
M['epilogue_parts'] = []
for i in range(1, len(_pt), 2):
    b = _pt[i + 1]
    M['epilogue_parts'].append({'id': _pt[i], 'achievement': re.search(r'"achievement": "(\w+)"', b).group(1),
                                'act': re.search(r'"act": "([^"]+)"', b).group(1), 'heading': re.search(r'"heading": "([^"]+)"', b).group(1),
                                'panels': len(re.findall(r'\["epilogue/', b.split('"panels"')[1]))})
_cl = _ep[_ep.index('const CLOSINGS'):]
_cl = _cl[:_cl.index('\n]')]
M['closings'] = [{'after': a, 'heading': h} for a, h in re.findall(r'"after": "(\w+)".*?"heading": "([^"]+)"', _cl, re.S)]
cd_ = txt('codex_data.gd')
M['codex_tabs'] = [b for a, b in re.findall(r'\["(\w+)", "([^"]+)"\]', cd_[cd_.index('const TABS'):cd_.index('const SUMMON_ORDER')])]
json.dump(M, open(os.path.join(OUT, 'model.json'), 'w'), indent=1, default=str)
print({k:(len(v) if hasattr(v,'__len__') else v) for k,v in M.items()})
