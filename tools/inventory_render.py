#!/usr/bin/env python3
"""Necropathy game-inventory renderer (step 2 of the inventory rebuild).

Role: turns model.json (written by tools/inventory_extract.py from the game's data
files) into the inventory's sections and writes
  <out-dir>/sections.json                    the sections as data
  <out-dir>/necropathy_inventory_plain.html  the plain page (search, collapsible
                                             sections, light / dark, phone layout; no thumbnails)
  docs/INVENTORY.md (or --md)                the Markdown twin
Counts, tables and statuses come from the model (a stage is "Playable" unless its
STAGE says "playable": false). The few hand-written parts are marked below: the
boss phase lists (PHASES, from the boss data-file headers), the acts' shared-rule
summaries (acts_rules) and the planned / proposed section at the end (from
docs/proposals/NEW_ACTS_AND_ORDER.md); update them when an act is added.

Run:  python3 tools/inventory_render.py --model <dir>/model.json --out-dir <dir>
Then: python3 tools/make_inventory_page.py --in <dir>/necropathy_inventory_plain.html \\
          --out <dir>/necropathy_inventory.html --model <dir>/model.json
(tools/rebuild_inventory.sh does extract, render and thumbnails in one command.)
"""
import argparse, collections, html, json, os, re, subprocess

# Repository root (the folder above tools/).
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
ap = argparse.ArgumentParser(description='Render the inventory sections, the plain page and docs/INVENTORY.md from model.json.')
ap.add_argument('--model', required=True, help='model.json written by tools/inventory_extract.py')
ap.add_argument('--out-dir', required=True, help='folder for sections.json and necropathy_inventory_plain.html')
ap.add_argument('--md', default=os.path.join(REPO, 'docs', 'INVENTORY.md'), help='Markdown twin to write (default docs/INVENTORY.md)')
args = ap.parse_args()
os.makedirs(args.out_dir, exist_ok=True)
M = json.load(open(args.model))
# Short commit id the data was read at (shown on the page); "unknown" outside a git checkout.
try:
    HEAD = subprocess.run(['git', '-C', REPO, 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
except Exception:
    HEAD = 'unknown'
# Branch the inventory describes (shown on the page).
try:
    BRANCH = subprocess.run(['git', '-C', REPO, 'rev-parse', '--abbrev-ref', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
except Exception:
    BRANCH = 'unknown'
# Act number -> act name (StageRegistry.ACTS, via the extractor).
ACTN = {int(k): v for k, v in M['act_names'].items()}
# Roman numeral of each act number.
ROM = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X'}
# Label for a stage / row that is registered but hidden from the stage select ("playable": false); unused while every stage is live.
BNP = "Built, not yet playable (waiting on review)"
stages=M['stages']; S={s['id']:s for s in stages}
npl=sum(1 for s in stages if s['playable']); nbl=len(stages)-npl
en=M['enemies']
reg=[e for e in en if e['kind']=='regular']; mini=[e for e in en if e['kind']=='miniboss']; stru=[e for e in en if e['kind']=='structure']
sp=M['spells']; pas=M['passives']; un=M['units']; sev=M['summon_evos']
counter=[p for p in pas if p['act']]
paired=[p for p in pas if p['paired']]
ach=M['achievements']
tot_levels=sum(u['levels'] for u in M['upgrades'])
nsk_default=len(M['characters'])
skins_total=nsk_default+len(M['hyper_skins'])+len(M['ach_skins'])+len(M['univ_skins'])+M['casket_skins']
sounds=sum(M['sound_counts'].values())
def pl(s): return "Playable" if s['playable'] else "Built, not playable"
def actstat(a): return "Playable" if all(s['playable'] for s in stages if s['act']==a) else "Built, not yet playable"
# Playable state of an act's faction label (for enemy / miniboss rows).
FAC_ACT = {v: k for k, v in M['act_faction'].items()}
def fac_playable(f): return all(s['playable'] for s in stages if str(s['act']) == FAC_ACT[f])
# Run-loop id -> track title (stage "music" key; "" = the Act I loop, unnamed in the data), titles from SoundData.SCORES.
MUSIC = dict(M['music'], **{'': "Act I run loop (unnamed in data)"})
PHASES={
'alaric':"2: five telegraphed attacks (Hammerfall, Divine Charge, Consecrated Ground, Call to Arms, Judgment of the Dead); Wrath at 50% HP",
'vael':"2: Cleave, Command, Standard, Shieldwall; then Last Stand",
'seraphine':"3: Divine Judgment, Avatar of the Dawn, The Last Light",
'merrow':"3: Robed (Sermon), The Change, High Water",
'archivist':"3: the Reading, the Footnotes, the Last Page",
'vhalneth':"3: Dreaming, Stirring, Waking (arms and face)",
'kestrel':"3: Marksman, Decoys, Twin Blades",
'motherboard':"3: base, Full Load (Magnet Pull), Overclock",
'deus_ex_machina':"3: the Walker, the Siege Core, the Founder",
'achilles':"3: the Duel, the Myrmidon Charge, the Rage after Patroclus",
'zeus':"3: the Thunderer, the Storm Throne, the True Form",
'hades':"3: the Helm of Darkness, the Reclaiming, a final lord phase",
'kage':"3: shadow clones, more clones with paired kunai, 'a hundred shadows'",
'shogun':"2: the Command Platform (the bar is his army), the Duel (iai slashes)",
'amaterasu':"3: Dawn, Noon, Sunset (her place in the sky is the phase)",
'moloch':"3: the Furnace King, the Furnace Opens, the Molten King",
'lilith':"3: charm waves widen each phase; the last is her true demon form",
'morning_star':"2: the Angel, the Beast (the Throne phase is cut)",
'vargr':"3: the Hunt, the Turning, the Moon-Eater",
'isolde':"3: the Witch, the Three Sisters, the Red Moon",
'carmilla':"3: the Court (Queen), the Waking, the Elder (two forms that split his health: the vampire lord with a blood-blade lunge and mist step, then the bat-winged horror)",
'don_marrow':"3: the Bounty, the Call, the Last Stand",
'harrow':"3: Command, the Hammer, Broken Arrow",
'paragon':"3: the Hero, Hope, No Restraint",
'hive_mother':"3: the Brood (egg waves, burrowers from every side), the Burrow (dives under the arena and erupts beneath the ring on a telegraph), the Flight (takes to the air, raining acid)",
'vrask_tal':"3: the Stalk (cloaked, picking summons off the ring's edge; a skull per kill), the Duel (leaps over the ring), the Last Trophy (a 20 s wrist bomb)",
'harvester':"3: the Council (takes the Concord's powers in turn), the Reaping (immune; emitters lift summons), the Gardener (true form of light and rings, live-turf rings)",
}
# ---- blocks
B=[] # sections: dict(id,title,status,blocks)
def sec(id,title,blocks,status='',intro=''): B.append({'id':id,'title':title,'status':status,'intro':intro,'blocks':blocks})
def T(headers,rows,cap=''): return {'t':'table','h':headers,'r':rows,'cap':cap}
def P(x): return {'t':'p','x':x}
def L(items): return {'t':'ul','x':items}
def H(x): return {'t':'h','x':x}
# summary
counts=[
("Stages",f"{len(stages)} ({npl} playable" + (f", {nbl} built not yet playable)" if nbl else ")")),
("Acts",f"{len(ACTN)} (" + ("all playable" if nbl==0 else "some built, not yet playable") + ")"),
("Stage bosses",len(stages)),
("Enemy kinds (all data rows)",f"{len(en)} = {len(reg)} regular + {len(mini)} minibosses + {len(stru)} structures"),
("Minibosses (flagged in data)",len(mini)),
("Spells",len(sp)),
("Evolutions",f"{len(sp)+len(sev)} ({len(sp)} spell + {len(sev)} summon)"),
("Passives (incl. Profane Pact)",f"{len(pas)} ({len(counter)} act-only counter-passives)"),
("Summon classes",f"{len(un)} ({len(un)-1} offerable + the Profane Bishop, evolved only)"),
("Synergies",len(M['synergies'])),
("Playable characters",len(M['characters'])),
("Skins",f"{skins_total} ({nsk_default} default + {len(M['hyper_skins'])} Hyper + {len(M['ach_skins'])} achievement + {len(M['univ_skins'])} universal; {M['casket_skins']} casket-only so far) + {len(M['recolours'])} recolours"),
("Ultimates",len(M['ultimates'])),
("Difficulties / run modifiers",f"{len(M['difficulties'])} / {len(M['modifiers'])}"),
("Achievements",len(ach)),
("Titles",len(M['titles'])),
("Ossuary upgrades",f"{len(M['upgrades'])} ({tot_levels} purchasable levels, {len(set(u['tree'] for u in M['upgrades']))} trees incl. Oath)"),
("Masteries",f"{len(M['mastery_classes'])} summon classes x 3 levels"),
("Relics / Grave Offerings",f"{len(M['relics'])} / {len(M['offerings'])}"),
("Music tracks",f"{len(M['music'])+2} (Act I loop, {len(M['music'])} act scores, menu theme {M['menu_theme']})"),
("Synthesised sound recipes",sounds),
("Epilogue parts / panels / closing cards",f"{len(M['epilogue_parts'])} / {sum(p['panels'] for p in M['epilogue_parts'])} / {len(M['closings'])}"),
("Codex tabs",len(M['codex_tabs'])),
("Sprite PNGs in assets/",f"{M['sprite_total']:,}"),
]
sec('summary',"Summary",[
 P("Built from the code on branch " + BRANCH + " at HEAD " + HEAD + " (Acts I to IX all playable), read from scripts/data/ and scripts/data/stages/. Counts are rows in the data tables, not estimates."),
 T(["Item","Count"],[[a,str(b)] for a,b in counts]),
 H("Playtime"),
 P(f"Owner's estimate: a full clear of every stage takes about 13 hours. For scale, {len(stages)} stages at a 20:00 countdown is {len(stages)*20/60:g} hours of clock alone, before boss fights past 0:00, menus and build choices. This is an estimate, not a measured figure."),
 H("Status key"),
 L(["Playable: reachable from the stage select in a normal build. Acts I to IX are all playable (Acts VI to IX went live in Nov 2026).",
    "Planned or proposed: not in the game; listed only at the end, in their own section."]
   + ([f"Built, not yet playable: {nbl} stage(s) hidden behind \"playable\": false."] if nbl else [])),
])
# campaign
rows=[]
for s in stages:
    rows.append([str(s['n']),s['name'],f"{ROM[s['act']]}",s['boss'],'Playable' if s['playable'] else 'Built, not yet playable',f"x{s['ash']:g}",f"x{s['hpmult']:g}",MUSIC.get(s['music'],s['music'])])
acts_rules={
1:("Crimson Covenant","No shared act rules (the baseline). Stage mechanics: Graveyard empowered graves, desecration and Crypt Defender; Crimson March battle zones, outposts, ward generators, supply carts; Sanctum ward chambers, sacred altars, floor corruption.","The Reckoning / Dawn's Wrath"),
2:("Ancient Eye","Dread (damage taken +5% per 25), Claims (fallen summons rise as hostile Drowned Thralls). Tide, ink wells, sinking island on the stages.","The Deep Rises / The Stacks Unwrite Themselves / The Waking"),
3:("Electronic Empire","Line of Fire, Lock-On, Steel has no soul (machines leave no corpse; cyborgs rise as Grave Gunners).","Purge Protocol (kill-drones, orbital strikes)"),
4:("Olympian Republic","Wrath of the Gods (waves, lightning, fissures hitting both armies), Phalanx (shield fronts), Glory (Heroes grow with kills).","The Twilight of the Gods (Bronze Titans)"),
5:("Shogunate","The Sun's Course (day, dusk, night with darkness and lit lanterns), the Draw (iai cuts), From the Shadows (ambushes revealed by light).","The Endless Night"),
6:("Inferno","Hell Pits, Portals (sealable), Temptation (succubi charm summons).","The Last Judgment (portals open, pits open faster, the Adversary's hand)"),
7:("Sanguine Court","Bloodfeast (enemies heal on hits, blood shield), Night Wings (bats fly over the ring), the Blood Moon every 4:00 for 45 s.","The Endless Feast (Blood Moon never sets, coffins release Vampire Nobles)"),
8:("Last Line","City blocks arenas, a clock escalation (gangs, police, SWAT, army, heroes), Armour (frontal cuts, vehicles, wrecks), Supers, Civilians.","Martial Law (every tier at once, artillery lines, the Supers return)"),
9:("Concord","Beams (only Bone Walls stop them, barriers reflect them), Abduction (saucers lift summons away), Terraforming (alien turf heals Concord units; spells burn it back). Crash Site: Infestation eggs. Proving Moon: low gravity. Ark: vault beasts, reactor vents, reaping emitters.","The Final Harvest (the mothership's eye opens, saucers fill the sky, the abduction cap is gone)"),
}
arows=[]
for a in sorted(ACTN):
    f,r,k=acts_rules[a]
    st=[s['short'] for s in stages if s['act']==a]
    arows.append([ROM[a],ACTN[a],actstat(a),", ".join(st),r,k])
sec('campaign',"Campaign: acts and stages",[
 H(f"The {len(ACTN)} acts"),
 T(["Act","Name","Status","Stages","Shared rules","Reckoning at 0:00"],arows),
 H(f"The {len(stages)} stages"),
 T(["#","Stage","Act","Boss (arrives with 3:00 left)","Status","Soul Ash","Enemy HP mult","Music"],rows),
 P("Every stage is a 20:00 countdown. The boss arrives at 17:00 (BOSS_TIME 1020 s). At 0:00 the Reckoning begins; dying after 0:00 is a victory. Soul Ash multipliers follow the per-act rule x1, x1.25, x1.5 (stage 1, 2, 3 of each act)."),
 H("Stage zones"),
 T(["Stage","Zones (clock-driven, in order)","Reckoning banner"],[[s['name'],", ".join(s['zones']) or "(single zone; stage events and graves)",s['reckoning']] for s in stages]),
 H("Stage unlock chain"),
 T(["Stage","How it unlocks"],[[s['name'],s['unlock'] or 'Always open'] for s in stages]),
])
# bosses
brows=[[str(s['n']),s['boss'],s['name'],PHASES[s['bossid']],'Playable' if s['playable'] else 'Built, not yet playable'] for s in stages]
sec('bosses',f"Bosses ({len(stages)})",[T(["#","Boss","Stage","Phases","Status"],brows),
 P("Phase lists are taken from each boss data file header and the README; Hades' last phase and Lilith's mid-phase names are not itemised in the data. The Harvester shows its true form (a being of light and rings) in the Gardener phase; the Elder's two forms share the health Carmilla gave him.")])
# minibosses
mrows=[[e['name'],e['faction'],e['where'],e['behavior'],'Playable' if fac_playable(e['faction']) else 'Built, not yet playable'] for e in mini]
sec('minibosses',f"Minibosses ({len(mini)} flagged + Supers)",[T(["Miniboss","Faction","Stage","Behaviour","Status"],mrows),
 P("Act VIII also promotes its Supers to zone minibosses at runtime (Liberty Heights: Blitz 17:30, Aurora 13:30, Atlas 8:30, Nightjar from 5:00). The Supers are listed with the Last Line enemies. Crimson March and the Graveyard have no flagged miniboss rows. Act IX miniboss rows: the Brood Matriarch (Crash Site, 10:30), the Warbeast (Proving Moon) and the Luminous Archon (Ark).")])
# enemies
def role(e):
    bits=[e['behavior']]
    if e['tier']: bits.append('tier '+e['tier'])
    if e['body']: bits.append(e['body'])
    for f in e['flags']:
        if f in('miniboss','is_structure'): continue
        bits.append({'always_elite':'always elite','fodder':'fodder','super':'Super','vehicle':'vehicle','demon':'demon','construct':'construct','flier':'flier','night':'night only','bronze':'bronze','floating':'floating','phases':'phases through obstacles'}.get(f,f))
    return ", ".join(bits)
# Faction labels in act order (enemy tables are grouped by them).
FACS=[M['act_faction'][str(a)] for a in sorted(ACTN)]
FACN={"Covenant":"Crimson Covenant (Act I)","Ancient Eye":"The Ancient Eye (Act II)","Empire":"The Electronic Empire (Act III)","Republic":"The Olympian Republic (Act IV)","Shogunate":"The Shogunate (Act V)","Inferno":"The Inferno (Act VI)","Sanguine Court":"The Sanguine Court (Act VII)","Last Line":"The Last Line (Act VIII)","Concord":"The Concord of Stars (Act IX)"}
eb=[P("All rows from the enemy data tables (EnemyData, MarchEnemyData, SanctumEnemyData, BattleSisterData and each act's shared and per-stage tables). Bosses are listed in their own section. Act IX adds the eggs (Brood Egg), the freed Vault Beast and the Specimen Tanks / Reactor Vents / Reaping Emitters as rows. The Reckoning Inquisitor (\"Inquisitor of the End\") is the Act I Reckoning kind and is counted in neither group."),
    T(["Faction","Regular","Minibosses","Structures","Total"],[[FACN[f],str(sum(1 for e in en if e['faction']==f and e['kind']=='regular')),str(sum(1 for e in en if e['faction']==f and e['kind']=='miniboss')),str(sum(1 for e in en if e['faction']==f and e['kind']=='structure')),str(sum(1 for e in en if e['faction']==f))] for f in FACS]+[["Total",str(len(reg)),str(len(mini)),str(len(stru)),str(len(en))]])]
for f in FACS:
    rs=[e for e in en if e['faction']==f]
    status='' if fac_playable(f) else BNP
    eb.append(H(FACN[f]+(" - built, not yet playable" if status else "")))
    eb.append(T(["Kind","Id","Class","Role and traits","Appears in"],[[e['name'],e['id'],e['kind'],role(e),e['where']] for e in rs]))
sec('enemies',f"Enemies ({len(en)} kinds)",eb)
# spells
srows=[[x['name'],x['id'],x['evo'],x['passive'].replace('_',' ').title(),x['section'],x['unlock'] or 'Open from the start' if x['section']=='Base game' else x['unlock'],x['desc']] for x in sp]
pn={p['id']:p['name'] for p in pas}
srows=[[x['name'],x['evo'],pn.get(x['passive'],x['passive']),x['section'],x['unlock'] or 'Base game',x['desc'],x['evo_desc']] for x in sp]
sec('spells',f"Spells and evolutions ({len(sp)} + {len(sp)})",[
 P(f"{sum(1 for x in sp if x['section']=='Base game')} base-game spells (3 starter spells and 9 later ones) and {sum(1 for x in sp if x['section']!='Base game')} act spells, one unlocked by each stage boss from Act II onward. Each has one evolution, delivered by a treasure chest once the spell and its paired passive are at Lv 5 and 8:00 has elapsed. Six active slots compete among spells and summon classes."),
 T(["Spell","Evolution","Paired passive (Lv 5)","Origin","Unlock","Description","Evolution effect"],srows),
 P("Act IX spells: Bone Beetles / Hive of Bone (Hive Mother; passive Chitin), Soul Caster / Apex Predator (Vrask'Tal; Trophy Rack) and Tractor Beam / Abduction (the Harvester; Starseed). Acts VI to IX are playable since Nov 2026."),
])
# passives
prow=[[p['name'],('Profane Pact (opt-in difficulty)' if p['id']=='profane_pact' else ("Counter-passive, Act "+ROM[int(p['act'])]+" only" if p['act'] else ("Paired: "+", ".join(p['paired']) if p['paired'] else "Standalone"))),p['section'],p['unlock'] or 'Open',p['desc']] for p in pas]
sec('passives',f"Passives ({len(pas)})",[P(f"{len(paired)} passives are paired with an evolution (every evolution needs its paired passive at Lv 5); {len(counter)} are act-only counter-passives earned by an achievement and offered only on that act's stages; plus the Profane Pact."),
 T(["Passive","Type","Origin","Unlock","Effect"],prow),
 P("Act IX adds Chitin, Trophy Rack and Starseed (spell-paired), Crop Circles (paired with the Black Mothership) and the counter-passives Anchored (Nothing Hatched) and Mirror Bones (The Hunter Hunted).")])
# summons
urows=[]
for u in un:
    ev=", ".join(f"{a} (needs {pn.get(b,b)}, {c})" for a,b,c in u['evos']) or ('(evolved form of Mender + Warder)' if u['id']=='bishop' else '')
    urows.append([u['name'],u['section'],u['profile'],ev,u['unlock'] or ('Evolved only' if u['id']=='bishop' else 'Open'),u['desc']])
sec('summons',f"Summon classes ({len(un)}) and summon evolutions ({len(sev)})",[
 T(["Class","Origin","Attack style","Evolution and paired passive","Unlock","Description"],urows),
 H("Summon evolutions"),
 T(["Evolution","Base class(es)","Paired passive","Kind","Origin"],[[e['name'],", ".join(e['bases']),pn.get(e['passive'],e['passive']),e['mode'],e['section']] for e in sev]),
 H("Synergies ("+str(len(M['synergies']))+")"),
 T(["Synergy","Effect"],[[x['name'],x['desc']] for x in M['synergies']]),
 P("Synergies switch on at Lv 2 of each required class. Bone Bastion (Bone Golem plus any blocker) was added with content wave 2; the Charnel Menagerie needs any 4 of the 7 newer classes. Classes from Act V onward (Bound Oni, Succubus, Archfiend, Blood Spawn, Fallen Hero, Ghost Saucer) have no dedicated synergies in the data. The Ghost Saucer (Act IX, unlocked by the Harvester) evolves into the Black Mothership."),
])
# characters & skins
spn={x['id']:x['name'] for x in sp}
crow=[[c['name'],spn[c['spell']],c['innate'],'Open' if c['unlocked'] else 'Spell reaches Lv 5 in any run',c['section']] for c in M['characters']]
hs=dict(M['hyper_skins'])
chn={c['id']:c['name'] for c in M['characters']}
sec('characters',f"Characters ({len(M['characters'])}) and skins ({skins_total})",[
 P("One playable character per spell, each with one innate passive. The Gravecaller is the default (no innate, baseline stats). Characters of Act IX spells are the Broodbound, the Blooded and the Starborn."),
 T(["Character","Starting spell","Innate","Unlock","Origin"],crow),
 H("Skins (cosmetic only)"),
 T(["Kind","Count","Detail"],[
  ["Default",str(nsk_default),"One per character"],
  ["Hyper skins",str(len(hs)),"One per character, earned by a Hyper clear with that character on the Sanctum"],
  ["Achievement skins",str(len(M['ach_skins'])),"; ".join(f"{a['name']} ({chn[a['character']]}): {a['text']}" for a in M['ach_skins'])],
  ["Universal skins",str(len(M['univ_skins'])),", ".join(n for _,n in M['univ_skins'])+" (any character)"],
  ["Casket-only skins","0","Slot exists (SkinData.CASKET_SKINS), empty until art exists"]]),
 H("Hyper skin names"),
 T(["Character","Hyper skin"],[[chn.get(k,k),v] for k,v in M['hyper_skins']]),
])
# rules / modes
sec('systems',"Run systems, difficulty and modes",[
 H("Difficulty levels"),
 T(["Level","Boss HP","Soul Ash","Description"],[[d['name'],'x'+d['boss'],'x'+d['ash'],d['tag']] for d in M['difficulties']]),
 H("Run modifiers"),
 T(["Modifier","Effect","Soul Ash bonus"],[[m['name'],m['desc'],'+'+str(int(float(m['ash'])*100))+'%'] for m in M['modifiers']]),
 H("Profane Pact, Profane Oath and Hyper mode"),
 L(["Profane Pact: an in-run passive, 5 levels (to +25% spawn, +25% HP, +15% damage for +40% XP, +60% Soul Ash, +75% drop chance).",
    "Profane Oath: an Ossuary option, 5 tiers of opt-in difficulty for richer rewards.",
    "Hyper mode: unlocked by slaying Seraphine once. Growth part of enemy HP/damage scaling x2, stage boss HP x1.5, Soul Ash +100%. Hyper clears earn a gold badge per stage and character."]),
 H("Ultimates"),
 T(["Ultimate","Tagline","Effect"],[[n,t,d] for _,n,t,d in M['ultimates']]),
 P("Dread Rally is the default; the other three are earned by achievements. Grave Step is the dash (Shift / RB)."),
 H("Power-ups"),
 P("Six pickups: "+", ".join(x.title() for x in M['powerups'])+"."),
 H("Game modes"),
 L(["Solo run (any unlocked stage, character, difficulty, modifiers, Hyper).",
    "Online co-op: 2 players, lobby codes through a Cloudflare relay, one lockstep simulation, shared XP bar, downed and revived by the partner, enemies x2 spawns, boss HP x1.7. Same platform only.",
    "Autotest and --coop-bot headless modes for development."]),
 H("Platforms"),
 L(["Windows and Linux desktop builds.","Web build for desktop browsers (GitHub Pages).","Phones and tablets in landscape in the browser (touch controls, mobile UI scale, Reduced effects default).","Native Android and iOS apps: deferred, not built."]),
])
# ossuary
byt=collections.defaultdict(list)
for u in M['upgrades']: byt[u['tree']].append(u)
TN={'oath':'Oath','necromancy':'Necromancy','shadowcraft':'Shadowcraft','survival':'Survival','fortune':'Fortune','dominion':'Dominion (opens after Seraphine)'}
orows=[[TN[u['tree']],u['name'],str(u['levels']),u['desc']] for t in ['necromancy','shadowcraft','survival','fortune','dominion','oath'] for u in byt[t]]
sec('ossuary',"The Ossuary (meta-progression)",[
 P(f"{len(M['upgrades'])} upgrades with {tot_levels} purchasable levels. 13 upgrades have levels 6-10, gated by difficulty clears (levels 6-7 Lich, 8-9 Deathlord, 10 Deathlord + Hyper). Soul Ash is kept on death and restarts its multiplier per act."),
 T(["Tree","Upgrade","Levels","Effect"],orows),
 H(f"Masteries ({len(M['mastery_classes'])} classes x 3 levels)"),
 P("One per offerable summon class, unlocked when the class reaches Lv 5 in any run: "+", ".join(M['mastery_classes'])+". Prices 190 / 250 / 320 Soul Ash."),
 H(f"Relics ({len(M['relics'])}; 1 to 3 slots)"),
 T(["Relic","Effect","Price"],[[b,c,d] for _,b,c,d in M['relics']]),
 H(f"Grave Offerings ({len(M['offerings'])})"),
 T(["Offering","Effect","Price"],[[b,c,d] for _,b,c,d in M['offerings']]),
 H("Recolour Caskets"),
 P("350 Soul Ash a casket; one unowned prize each; rarity weights Common 60, Rare 30, Epic 10, Legendary 3 (only while a legendary prize exists), with a pity Epic on the 10th. Recolours: "+", ".join(n for _,n in M['recolours'])+" ("+str(len(M['recolours']))+"). Cosmetic only."),
])
# achievements
atitle={a:b for a,b,c in M['titles']} if False else {t[2]:t[1] for t in M['titles']}
arows=[[a[1],a[2],a[3] or '', atitle.get(a[0],'')] for a in ach]
sec('achievements',f"Achievements ({len(ach)}) and titles ({len(M['titles'])})",[
 T(["Achievement","Condition","Reward"],[[a[1],a[2],a[3]] for a in ach]),
 H("Titles"),
 T(["Title","Earned by achievement"],[[t[1],dict((x[0],x[1]) for x in ach)[t[2]]] for t in M['titles']]),
 P("Act IX adds the achievements Nothing Hatched, The Hunter Hunted and The Last Harvest (the title The Unharvested). Boss and achievement unlock rows in total: "+str(len(M['unlocks']))+"."),
])
# audio & story
# Achievement id -> display name (epilogue parts name the achievement that opens them).
ACH_NAME={a[0]:a[1] for a in ach}
# Music table rows: each track with the acts that use it (read from each stage's "music" key).
def _acts_of(mus):
    xs=sorted(set(s['act'] for s in stages if s['music']==mus))
    return 'Act '+', '.join(ROM[x] for x in xs) if xs else '-'
MUSIC_ROWS=[["Act I run loop",_acts_of('')]]+[[title,_acts_of(k)] for k,title in M['music'].items()]+[[M['menu_theme'],"Main menu"]]
sec('audio',"Audio, Codex and story",[
 H(f"Music ({len(M['music'])+2} tracks)"),
 T(["Track","Used by"],MUSIC_ROWS),
 P("All sound and music is synthesised in-engine. Sound recipes: "+", ".join(f"{k.replace('_SOUNDS','').title() or k} {v}" for k,v in M['sound_counts'].items())+f" = {sounds}. Act packs (Empire, Pantheon, Shogunate, Inferno, Court, City, Concord) render lazily when the act's music starts."),
 H(f"Codex ({len(M['codex_tabs'])} tabs)"),
 P(", ".join(M['codex_tabs'])+". Entries stay dark silhouettes until a run meets them; evolutions show only once obtained."),
 H("Epilogue and closing cards"),
 T(["Part","Opened by","Panels"],[[p['act'].split(': ')[0]+': '+p['heading'],ACH_NAME.get(p['achievement'],p['achievement']),str(p['panels'])] for p in M['epilogue_parts']]),
 T(["Closing card","After"],[[c['heading'],'Act '+ROM[int(c['after'].replace('act',''))]] for c in M['closings']]),
 P("Acts VI to IX have no epilogue part and no closing card yet (owner decision: wait until the act order is settled; Act IX has a short ending text only). The victory screen shows a per-stage title and boss line for every stage."),
 H("Art"),
 T(["Folder","PNG files"],[[k,str(v)] for k,v in sorted(M['sprites'].items(),key=lambda x:-x[1])]+[["Total",str(M['sprite_total'])]]),
])
# planned
sec('planned',"Planned and proposed content (NOT in the game)",[
 P("Nothing in this section exists in code. Source files: docs/proposals/NEW_ACTS_AND_ORDER.md, docs/GDD.md section 15.0. Act IX is built and playable, so it is not listed here."),
 T(["Act","Status","Stages and bosses","Shared rules"],[
  ["Act X: seasons (The Turning Year)","Concept only","Seasons and nature; named The Turning Year in the order proposal (stages 37-39 there)","Not designed"],
  ["The Black Tide (pirate act)","Proposed, awaiting owner","The Smuggler's Cutter (Captain Ezekiel Crow), The Treasure Galleon (Admiral Isabeau Marrec), The Maelstrom (Captain Cornelius Vandermere)","Boarding, the Deck, Strikes from the Sea"],
  ["The Age of Titans (prehistoric act)","Proposed, awaiting owner","The Fern Basin (Scarmaw), The Great Plain (Old Ironbrow), The Last Day (Old Gravejaw); the meteor mechanic","Primeval rules (see proposal)"],
  ["The Necropolis Dynasty (Egyptian act)","Proposed, awaiting owner","The Necropolis of Sand (Anubis), The Temple of the Lioness (Sekhmet), The Hall of Two Truths (Osiris and Ammit)","Rebirth and dynasty rules"],
  ["The Hall of the Slain (Norse act)","On the docket, not scheduled","The Barrow Fields, The Longhouse of Heroes, The Frozen Root","The Choosing, Fimbulwinter, Shield Wall (candidates)"],
 ]),
 P("The same proposal recommends reordering to 13 acts and 39 stages (Part One I-VIII ending with the Inferno, Part Two IX-XIII). The owner has not answered it; the current order in the game is the ORDER list above."),
])
# not determined
sec('gaps',"What the data does not say",[L([
 "Boss base HP is not shown: several data files hold per-phase or per-body values (Shogun, Vhal'Neth, Carmilla and the Elder), so a single number would mislead.",
 "Hades' final phase name and Lilith's phase names are not itemised in the data headers.",
 "The Act I run loop has no title in the data.",
 "Total playtime of 13 hours is the owner's estimate, not derived from data.",
 "Sound recipe counts are rows at the top level of each sound table and may include recipe variants.",
 "Enemy rows include spawned sub-kinds (Lesser and Least Mass, Swarm Rocket, Decoy Drone, Shadow of Kage) and boss-fight structures (Cerberus heads, Vhal'Neth arms, Leg Plates)."])])
json.dump({'B':B,'counts':[[a,str(b)] for a,b in counts]},open(os.path.join(args.out_dir,'sections.json'),'w'))
d={'B':B,'counts':[[a,str(b)] for a,b in counts]}; C=d['counts']
# ---- MD
def md(x): return str(x).replace('|','\\|').replace('\n',' ')
o=["# Necropathy: Complete Game Inventory","",
f"Rebuilt from the code (branch `{BRANCH}`, HEAD {HEAD}, after Act IX; Acts I to IX are all playable). Generated by `tools/rebuild_inventory.sh` (`tools/inventory_extract.py`, `tools/inventory_render.py`) from `scripts/data/`; every count is a data row count.",""]
for s_ in B:
    o+=[f"## {s_['title']}",""]
    for b in s_['blocks']:
        if b['t']=='p': o+=[b['x'],""]
        elif b['t']=='h': o+=[f"### {b['x']}",""]
        elif b['t']=='ul': o+=["- "+i for i in b['x']]+[""]
        else:
            o+=["| "+" | ".join(md(h) for h in b['h'])+" |","|"+"---|"*len(b['h'])]
            o+=["| "+" | ".join(md(c) for c in r)+" |" for r in b['r']]+[""]
open(args.md,'w').write("\n".join(o)+"\n")
print(len(o),'md lines')

# HTML-escape helper for the page.
e=lambda x:html.escape(str(x),quote=False)
def cell(c):
    c=e(c)
    if 'Built, not yet playable' in c or 'built, not yet playable' in c or 'Built, not playable' in c: return f'<span class="pill bnp">{c}</span>' if len(c)<40 else c
    if c=='Playable': return '<span class="pill ok">Playable</span>'
    return c
out=[]
for s in B:
    inner=[]
    for b in s['blocks']:
        if b['t']=='p': inner.append(f"<p>{e(b['x'])}</p>")
        elif b['t']=='h': inner.append(f"<h3>{e(b['x'])}</h3>")
        elif b['t']=='ul': inner.append("<ul>"+"".join(f"<li>{e(i)}</li>" for i in b['x'])+"</ul>")
        else:
            th="".join(f"<th>{e(h)}</th>" for h in b['h'])
            tr="".join("<tr>"+"".join(f"<td>{cell(c)}</td>" for c in r)+"</tr>" for r in b['r'])
            inner.append(f'<div class="tw"><table><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table></div>')
    op=' open' if s['id']=='summary' else ''
    cls=' planned' if s['id']=='planned' else ''
    out.append(f'<details class="sec{cls}" id="{s["id"]}"{op}><summary><span class="t">{e(s["title"])}</span><span class="hit"></span></summary><div class="body">{"".join(inner)}</div></details>')
nav="".join(f'<a href="#{s["id"]}">{e(s["title"].split(" (")[0])}</a>' for s in B)
tiles="".join(f'<div class="tile"><b>{e(v.split(" (")[0])}</b><span>{e(k)}</span></div>' for k,v in C[:12])
page=f'''<title>Necropathy: Complete Game Inventory</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Jersey+10&family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono:wght@400&display=swap">
<style>
/* Layout: a reference sheet; sticky search bar, then one collapsible section per category, wide tables scroll inside their own box. */
:root{{--bg:#f3f1f6;--fg:#1d1a26;--mute:#625d73;--card:#ffffff;--line:#d9d4e3;--accent:#5b2fa8;--ok:#1d7a52;--okbg:#dff3e8;--warn:#9a5b00;--warnbg:#fbeccc;--mark:#fff1a8;
--display:"Jersey 10","Arial Narrow",sans-serif;--body:"IBM Plex Sans",system-ui,sans-serif;--mono:"IBM Plex Mono",ui-monospace,monospace}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#14111c;--fg:#ebe7f3;--mute:#a49db8;--card:#1d1928;--line:#3a3350;--accent:#b58cff;--ok:#6fd3a4;--okbg:#17352a;--warn:#f0b64e;--warnbg:#3b2c10;--mark:#5a4a00;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#14111c;--fg:#ebe7f3;--mute:#a49db8;--card:#1d1928;--line:#3a3350;--accent:#b58cff;--ok:#6fd3a4;--okbg:#17352a;--warn:#f0b64e;--warnbg:#3b2c10;--mark:#5a4a00;color-scheme:dark}}
body{{background:var(--bg);color:var(--fg);font:15px/1.5 var(--body);padding-inline:max(16px,env(safe-area-inset-left,0px)) max(16px,env(safe-area-inset-right,0px));padding-block:20px 60px}}
.wrap{{max-width:1100px;margin:0 auto}}
h1{{font:400 44px/1 var(--display);margin:0 0 6px;letter-spacing:.02em;text-wrap:balance}}
.sub{{color:var(--mute);margin:0 0 16px;max-width:70ch}}
.tiles{{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:10px;margin:0 0 18px}}
.tile{{background:var(--card);border:1px solid var(--line);padding:10px 12px;min-width:0;display:flex;flex-direction:column;gap:2px}}
.tile b{{font:400 30px/1 var(--display);color:var(--accent);font-variant-numeric:tabular-nums}}
.tile span{{font-size:12px;color:var(--mute)}}
.bar{{position:sticky;top:env(safe-area-inset-top,0px);z-index:5;background:var(--bg);padding:8px 0;display:flex;gap:8px;flex-wrap:wrap;align-items:center;border-bottom:1px solid var(--line);margin-bottom:12px}}
.bar input{{flex:1 1 220px;min-width:0;font:inherit;padding:9px 12px;border:1px solid var(--line);background:var(--card);color:var(--fg)}}
.bar button{{font:inherit;padding:9px 12px;border:1px solid var(--line);background:var(--card);color:var(--fg);cursor:pointer}}
.bar button:hover,.bar input:focus,.bar button:focus-visible{{outline:2px solid var(--accent);outline-offset:1px}}
#count{{color:var(--mute);font-size:13px}}
nav{{display:flex;flex-wrap:wrap;gap:4px 12px;margin:0 0 14px;font-size:13px}}
nav a{{color:var(--accent);text-decoration:none}} nav a:hover{{text-decoration:underline}}
details.sec{{background:var(--card);border:1px solid var(--line);margin:0 0 10px}}
details.planned{{border-style:dashed}}
summary{{cursor:pointer;padding:12px 14px;display:flex;gap:10px;align-items:baseline;justify-content:space-between;list-style:none}}
summary::-webkit-details-marker{{display:none}}
summary .t{{font:400 26px/1.1 var(--display);letter-spacing:.02em}}
summary::before{{content:"+";font:400 22px/1 var(--mono);color:var(--accent);width:1ch;flex:none}}
details[open]>summary::before{{content:"-"}}
summary .t{{flex:1}} .hit{{font-size:12px;color:var(--mute)}}
.body{{padding:0 14px 14px;min-width:0}}
h3{{font:400 21px/1.2 var(--display);margin:18px 0 6px;color:var(--accent);letter-spacing:.02em}}
p,li{{max-width:75ch}} p{{margin:8px 0}}
ul{{padding-left:20px}}
.tw{{overflow-x:auto;border:1px solid var(--line);margin:8px 0}}
table{{border-collapse:collapse;width:100%;font-size:13px}}
th,td{{text-align:left;padding:6px 9px;border-bottom:1px solid var(--line);vertical-align:top}}
th{{background:var(--bg);font-weight:600;white-space:nowrap;position:sticky;top:0}}
td{{min-width:70px}}
tr:last-child td{{border-bottom:0}}
.pill{{display:inline-block;padding:1px 7px;font-size:12px;white-space:nowrap}}
.pill.ok{{background:var(--okbg);color:var(--ok)}} .pill.bnp{{background:var(--warnbg);color:var(--warn)}}
mark{{background:var(--mark);color:inherit}}
tr.nomatch{{display:none}}
footer{{color:var(--mute);font-size:12px;margin-top:20px}}
@media(max-width:520px){{h1{{font-size:36px}}}}
@media(prefers-reduced-motion:no-preference){{details.sec{{transition:border-color .15s}}}}
</style>
<div class="wrap">
<h1>Necropathy: Complete Game Inventory</h1>
<p class="sub">Every stage, enemy, boss, spell, passive, summon, character, skin and unlock in the game, read from the data files after Act IX. Acts I to IX are all playable. Planned content is listed last and is not in the game.</p>
<div class="tiles">{tiles}</div>
<div class="bar"><input id="q" type="search" placeholder="Search everything (e.g. Zeus, Rot, Lich, civilian)" aria-label="Search"><button id="all" type="button">Expand all</button><button id="none" type="button">Collapse all</button><span id="count"></span></div>
<nav>{nav}</nav>
{"".join(out)}
<footer>Generated from scripts/data/ on branch {BRANCH} (HEAD {HEAD}). Markdown copy: docs/INVENTORY.md.</footer>
</div>
<script>
(function(){{
var secs=[].slice.call(document.querySelectorAll('details.sec')),q=document.getElementById('q'),cnt=document.getElementById('count');
function clearMarks(el){{[].slice.call(el.querySelectorAll('mark')).forEach(function(m){{m.replaceWith(document.createTextNode(m.textContent));}});el.normalize();}}
function run(){{
 var v=q.value.trim().toLowerCase(),total=0;
 secs.forEach(function(s){{
  var n=0;clearMarks(s);
  var rows=[].slice.call(s.querySelectorAll('tbody tr'));
  rows.forEach(function(r){{var ok=!v||r.textContent.toLowerCase().indexOf(v)>-1;r.classList.toggle('nomatch',!ok);if(ok&&v){{n++;}}}});
  var paras=[].slice.call(s.querySelectorAll('.body > p, .body > ul'));
  paras.forEach(function(p){{if(v&&p.textContent.toLowerCase().indexOf(v)>-1)n++;}});
  var tn=(s.querySelector('summary .t').textContent.toLowerCase().indexOf(v)>-1);
  var hit=s.querySelector('.hit');
  if(!v){{hit.textContent='';s.hidden=false;}}
  else{{hit.textContent=n+' match'+(n==1?'':'es');s.hidden=(n===0&&!tn);if(n>0)s.open=true;total+=n;}}
 }});
 cnt.textContent=v?total+' matches':'';
}}
q.addEventListener('input',run);
document.getElementById('all').onclick=function(){{secs.forEach(function(s){{s.open=true}})}};
document.getElementById('none').onclick=function(){{secs.forEach(function(s){{s.open=false}})}};
function hash(){{var id=location.hash.slice(1),el=id&&document.getElementById(id);if(el&&el.tagName==='DETAILS'){{el.open=true;el.scrollIntoView();}}}}
window.addEventListener('hashchange',hash);hash();
}})();
</script>
'''
# Plain page (no thumbnails yet; tools/make_inventory_page.py adds them).
open(os.path.join(args.out_dir, 'necropathy_inventory_plain.html'), 'w').write(page)
print('plain page', len(page), 'bytes;', len(o), 'md lines')
