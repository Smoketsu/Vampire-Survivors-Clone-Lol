# The Celestial Host: art and audio manifest (what to make)

Written by the foundation agent for the art + audio agent and the three stage agents (act slot X, temporary Act XIII,
stage key `host`; GDD §15.0 "The Celestial Host foundation (phase 1)"). It lists every sprite, strip, icon, floor,
obstacle and marker the foundation and phase 2 need, and the score and sound pack. Model: `docs/dynasty/ART_MANIFEST.md`
(the Dynasty's, written after its art; rebuild its tools the same way under `art_source/host/`).

Rules for every image (CLAUDE.md, `docs/last_acts/PLAN.md`):
- True pixel art, 1 art px = 1 screen px, the reference set's dark 1 px outline and flat shading; heights go in
  `SpriteData.HEIGHTS` (block "Act X slot: the Celestial Host"). Strips: `<id>_walk.png` = 8 frames side by side (a
  `_glide` strip for floating figures), `<id>_idle.png` = 24 frames for every female figure (bust rig in
  `tools/walk_cycle.py`). Every female figure is in the figure-redesign style, fully clothed.
- **The Host's palette: starlight white, pale silver, cerulean and dawn rose. Never crimson, never warm gold** (gold is the
  player's reward colour; crimson is danger and the Covenant's). Thin geometric halos, never crowns; inhuman shapes (mirror
  masks, many wings, eyes on wings and wheels) so nothing reads as the Covenant or Act VI's fallen angels.
- Concept art (approved): `art_source/concepts/act15/host_lineup.png`, `host_bosses.png`, `host_stage.png`, `host.png`
  with their `.txt` prompts.
- The code draws a fallback for every key below (`HostGlyphs`, the kits, `CloudShade`, `HallowedLight`, `Judgment`), so
  a missing PNG never breaks a run.

## Palette ramps (`tools/palette.json`, faction set `host` in `prepare_sprite.py`)

The constants are already in `scripts/data/palette.gd` (`HOST_*`); the ramps must use these exact values.

| Ramp | Colours (ink first, dark to light) | Use |
|---|---|---|
| `host_ink` / outline | `#0E1626` | every Host sprite's outline (deep night blue) |
| `host_silver` | `#0E1626`, `#8A96AC`, `#C9D2E0`, `#F4F7FF` | armour, mirror masks, halos' rims, the scales |
| `host_cerulean` | `#0E1626`, `#1F4F8F`, `#3E8FD8`, `#9CC8F0` | halos' light, wing eyes, robes' folds, the Ophan's fire |
| `host_rose` | `#0E1626`, `#B07888`, `#F2B8C6`, `#FCE4EA` | dawn rose: sashes, the Choir's hymn, the Judges' pans |
| `host_cloud` | `#0E1626`, `#1A2236`, `#DCE4F0`, `#F4F7FF` | cloud banks, the stair's steps, cloud shadows |
| `host_skin` | `#0E1626`, `#B8A8A0`, `#E8DCD4`, `#FAF4F0` | the rare visible skin (pale, unearthly; most faces are masked or hidden) |

## Units (`assets/sprites/host/<id>.png`, + strips). Loaded by the code today: the SpriteBank keys `host/<kind>`

| Key | Size (art px, w x h) | Sex | What it is | Strips | Loaded now |
|---|---|---|---|---|---|
| `host/lesser_light` | 22x24 | none | fodder: a small orb of white light with two tiny wings (swarms of 12) | glide (bob) | yes |
| `host/virtue` | 30x48 | male | soldier: silver spearman, featureless mirror mask, four wings | walk | yes |
| `host/power` | 30x48 | female (figure style) | soldier: silver armour over a pale robe, a blade of white flame | walk, idle | yes |
| `host/choir_angel` | 28x48 | female (figure style) | support: flowing pale-blue robes, singing, sheet-like light around her | glide, idle | yes |
| `host/herald` | 32x48 | male | support: long silver trumpet, two wings | walk | yes |
| `host/dominion` | 34x54 | male | elite: sceptre, a crown of light rings (rings, not a crown of metal) | walk | yes |
| `host/judge` | 34x56 | male | Judgment's elite: a sword and a set of scales held high, mirror mask | walk | yes |
| `host/cherub` | 48x56 | none (a creature) | phase 2 (guardians): four faces (lion, ox, eagle, man), four wings covered in eyes, a flaming white sword | walk | yes (Silver Stair; `HostGlyphs` until drawn) |
| `host/ophan` | 52x52 | none (a wheel) | phase 2 (guardians): a burning silver wheel within a wheel, rims covered in eyes; rolls | roll (8 frames) | phase 2 |
| `host/cherub_of_the_gate` | 64x76 | none | Silver Stair miniboss: a larger Cherub, its sword turning a full circle | walk | yes (Silver Stair; `HostGlyphs` until drawn) |
| `host/dominion_of_the_spheres` | 44x70 | male | Wheel of Thrones miniboss: a larger Dominion among crystal rings | walk | phase 2 |
| `host/herald_of_the_seventh_trumpet` | 44x70 | male | Empyrean miniboss: a larger Herald, a great trumpet | walk | phase 2 |

The halo over each angel is drawn by the code (`HostKit.draw_over()`: a ring of cerulean rects that gaps as it cracks), so
**do not paint a halo into the unit sprites**; a later `markers/host_halo` (below) may replace the code ring.

## Bosses (`assets/sprites/host/<id>.png`; phase 2 wires them, `BossPoseData` poses by the stage agents)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `host/seraiel` | 64x96 | male | Seraiel, Warden of the Gate: a towering four-winged archangel in silver armour, a flaming white sword | walk |
| `host/throne` | 96x96 | none | the Throne: a colossal wheel within a wheel of silver and blue fire, rims covered in eyes | roll (8 frames) |
| `host/throne_core` | 32x32 | none | the Throne's burning eye at its centre (the Core, drawn when the wheels open) | none |
| `host/voice` | 80x104 | none (sexless seraph) | the Voice: six wings of light (two over the face, two over the feet, two spread) in a white rose | glide |
| `host/voice_unveiled` | 80x104 | none | the Voice with its face wings lowered (Be Not Afraid): the face is pure light, never features | none |

## Playable characters (`assets/sprites/player/`; PLAN.md's convention: violet necromancers of the act's theme, never members of the Host; bone-white and soul-teal accents, a casting focus, 56 px tall, at most ~46 px wide)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `player/fallen_herald` | 40x56 | male | violet robe and a torn violet cope, one broken bone-white wing, a dark trumpet-headed staff with a soul flame (spell Flaming Sword, Seraiel) | walk |
| `player/blind_saint` | 36x56 | female (figure style) | violet gown, a violet blindfold, a staff ringed with a bone wheel of closed eyes (Wheel of Eyes, the Throne) | walk, idle |
| `player/the_unveiled` | 38x56 | female (figure style) | violet dress, a lowered violet veil, small grey wings folded, a staff of a dead star (Revelation, the Voice) | walk, idle |

## Summon class (finale reward; `assets/sprites/summons/`)

| Key | Size | What | Strips |
|---|---|---|---|
| `summons/bound_ophan` | 30x30 | the Bound Ophan: a wheel of bone and eyes (soul-teal eyes) that orbits the Bone Ring | roll (8 frames) |
| `summons/throne_of_bones` | 44x44 | its evolution: a double wheel of bone, soul-teal fire | roll (8 frames) |

## World markers (`assets/sprites/markers/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `markers/host_halo` | 16x6 | the halo ring (cerulean light, silver rim); phase 2 may swap the code ring for it | no (code ring) |
| `markers/host_halo_cracked` | 16x6 | the cracked halo (two gaps) | no |
| `markers/host_scales` | 24x20 | the scales of Judgment for the HUD bar's end cap (silver, rose pans) | no (code bar) |
| `markers/host_pillar` | 40x120 | the Verdict's falling pillar of light (white, faint cerulean edge), drawn additively | no (code rect) |

## Effects (`assets/sprites/fx/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `fx/host_shaft` | 32x128 (tiling along the shaft) | a shaft of Hallowed Light: soft starlight white, transparent edges | no (code rects) |
| `fx/host_shaft_line` | 4x128 (tiling) | the telegraph line 1.5 s ahead of a shaft (cerulean) | no (code rect) |
| `fx/host_trumpet_ring` | strip 8 x 48x24 | the Herald's / the Last Trumpet's blast ring (silver) | no (code disc) |

## Floors (`assets/sprites/tiles/`, 128x128 seamless, dark and flat enough for the units to read)

| Key | What | Loaded now |
|---|---|---|
| `tiles/host_stair` | the stage-select vignettes' tile until each stage has its own (pale ash step with a silver edge) | yes (vignettes) |
| `tiles/host_cloud_shadow` | a cloud bank's shadow on the ground (128x102 ellipse, dark cerulean, soft pale rim; drawn stretched) | yes (CloudShade) |
| `tiles/silver_stair_ashen_foot` | Silver Stair zone 1: hell's ash, the first step of light | phase 2 |
| `tiles/silver_stair_stair` | zone 2: wide pale steps | phase 2 |
| `tiles/silver_stair_cloud_shelf` | zone 3: steps among cloud | phase 2 |
| `tiles/silver_stair_pearl_gate` | zone 4: pearl flagstones | phase 2 |
| `tiles/wheel_moon` / `wheel_sun` / `wheel_stars` / `wheel_core` | the Wheel of Thrones' four spheres (silver, pale light, deep star-blue, the Wheel's rim) | phase 2 |
| `tiles/empyrean_rose_edge` / `empyrean_petals` / `empyrean_choir` / `empyrean_heart` | the Empyrean's four zones (white petals of light, darker toward the heart only in value, never in hue) | phase 2 |

## Obstacles (`assets/sprites/obstacles/`; rect kinds also `_v`, turned 90 degrees). The stubs use these kind ids (code-drawn by `HostGlyphs` today); phase 2 renames to its own kinds if it wants

| Key | Size | What | Loaded now |
|---|---|---|---|
| `obstacles/host_pillar` | 30x46 | a pillar of white stone with a band of light (circle kind; casts a pillar's shadow, safe from the Light) | yes on the Silver Stair, as `host_pillar_m` (one size); code on the stubs |
| `obstacles/host_cloudstone` + `_v` | 52x30 | a cloud-wrapped block of the stair | yes on the Silver Stair, as `host_cloudstone_m` / `_m_v`; code on the stubs |
| `obstacles/host_crystal` + `_v` | 44x26 | a shard of a sphere's crystal (cerulean, see-through edge) | code |
| `obstacles/host_petal` + `_v` | 56x24 | a standing petal of light | code |
| `obstacles/host_pearl_gate` | 96x80 | the Gate of Pearl (Silver Stair set piece) | phase 2 |
| `obstacles/host_crystal_ring` | strip, 3 sizes | the turning spheres' crystal ring segments (moving walls, Wheel of Thrones) | phase 2 |

## Icons (`assets/sprites/icons/<id>.png`, 32x32 badges on the approved frames: violet = spells / passives / counter-passives / classes, gold = evolutions and achievements)

| Id | What |
|---|---|
| `icons/flaming_sword` | spell: Flaming Sword |
| `icons/wheel_of_eyes` | spell: Wheel of Eyes |
| `icons/revelation` | spell: Revelation |
| `icons/sword_at_the_gate` | evolution of Flaming Sword |
| `icons/ophanim` | evolution of Wheel of Eyes |
| `icons/be_not_afraid` | evolution of Revelation |
| `icons/fallen_light` | paired passive of Flaming Sword |
| `icons/all_seeing` | paired passive of Wheel of Eyes |
| `icons/seventh_seal` | paired passive of Revelation |
| `icons/absolution` | counter-passive (the scales fill 30% slower) |
| `icons/smoked_glass` | counter-passive (the Light burns summons for half) |
| `icons/ach_without_sin` | achievement Without Sin |
| `icons/ach_the_wheel_breaks` | achievement The Wheel Breaks |
| `icons/ach_the_last_word` | achievement The Last Word |
| `icons/bound_ophan` | summon class icon |
| `icons/throne_of_bones` | its evolution icon |

## Audio

- **Music** `hosanna`, score `SoundData.HOSANNA_SCORE` "Hosanna in the Silence": slow, vast and bright, a sustained choir
  pad (`organ`), high bell tones (`hits`), a long silver trumpet call every few bars (`horn`), no drums until a soft timpani
  swell near the loop's end; a major mode with a lowered seventh so it reads holy but strange. Existing synth jobs only.
  `SoundData.SCORES["hosanna"]`, `SCORE_PACKS["hosanna"] = "host"`, `Sfx.SCORE_SEEDS["hosanna"]` (the next free value
  after `weighing`'s `SYNTH_SEED - 12`; the lead assigns it if another act's pass claims it first), `Sfx.MUSIC_HOSANNA`.
  The stubs play `"starsong"` until then; the lead switches each Host STAGE's `"music"` to `hosanna` at the merge.
- **Sound pack** `SoundData.HOST_SOUNDS` (lazy with the score; `Sfx.PACK_SEED_OFFSETS["host"]`, the next free offset after
  the Dynasty's 9000). Ids, one per `HostRulesData.SOUNDS` event (the lead points the map at them at the merge):
  `scales_tip` (a small bright bell), `judge_descend` (a falling chord, wings), `judge_slain` (a glass ring breaking),
  `verdict` (a deep struck bell), `pillar_fall` (a white roar of light), `light_warn` (a thin rising tone), `light_burn`
  (a hiss of searing light), `halo_absorb` (a soft glass chime), `halo_regrow` (a rising shimmer), `trumpet` (a long silver
  trumpet blast), `herald_blast` (a short trumpet call and a gust), `power_lunge` (a white-flame sword cut).
- Art and audio agents run no Godot (PLAN.md); the lead's integration imports their files and the owner hears the loop.

## Status (art and audio agent, foundation)

Done: palette ramps `host_*`; units `lesser_light`, `virtue`, `power`, `choir_angel`, `herald`, `dominion`, `judge` (+ strips, idle for the women);
obstacles `host_pillar`, `host_cloudstone`, `host_crystal`, `host_petal` (+ `_v`); all 16 icons; floors `host_stair`, `host_cloud_shadow`; markers
`host_halo`, `host_halo_cracked`, `host_scales`, `host_pillar`; fx `host_shaft`, `host_shaft_line`, `host_trumpet_ring`; the score `hosanna`
(seed `SYNTH_SEED - 13`) and the pack `host` (offset 10000, 12 sounds). `SpriteData.FLAT_SIZES` has the foundation entries. Still missing (phase 2):
`cherub`, `ophan`, the three minibosses, the five bosses, the three characters, the summon class and its two icons' art (the icons exist), the
zone floors, `host_pearl_gate`, `host_crystal_ring`. The lead still has to point the stages' `"music"` at `hosanna` and `HostRulesData.SOUNDS` at the pack.
