# The Age of Titans: art and audio manifest (what to make)

Written by the foundation agent for the art + audio agent and the three stage agents (act slot XIV, temporary Act XIV,
stage key `primeval`; GDD §15.0 "The Age of Titans foundation (phase 1)"). It lists every sprite, strip, icon, floor,
obstacle and marker the foundation and phase 2 need, and the score and sound pack. Model: `docs/host/ART_MANIFEST.md`
(rebuild its tools the same way under `art_source/titans/`).

Rules for every image (CLAUDE.md, `docs/last_acts/PLAN.md`):
- True pixel art, 1 art px = 1 screen px, the reference set's dark 1 px outline and flat shading; heights go in
  `SpriteData.HEIGHTS` (block "Act XIV slot: the Age of Titans"). Strips: `<id>_walk.png` = 8 frames side by side (a
  `_fly` strip for the fliers), `<id>_idle.png` = 24 frames for every female figure in the figure-redesign style (bust
  rig in `tools/walk_cycle.py`). The beasts are animals: no bust rig, no figure style on any beast (the "female alpha" is
  told by her crest and size, not a figure).
- **The act's palette: fern green, volcanic orange, tar black, dust ochre and bone white** (the proposal), plus the white
  streak of the meteor. Gold keeps its meaning (evolution, chest, victory) and crimson stays danger: no beast is gold or
  crimson, and none wears the necromancer's violet. **No humans** fight in this act.
- Concept art (approved): `art_source/concepts/final5/titans_lineup.png`, `titans_bosses.png`, `titans_stage.png` with
  their `.txt` prompts.
- The code draws a fallback for every key below (`PrimevalGlyphs`, the kits, `Herds.draw()`, `Scavengers.draw()`,
  `StampedeOfAsh.draw()`, `PrimevalGround`), so a missing PNG never breaks a run.

## Palette ramps (`tools/palette.json`, faction set `primeval` in `prepare_sprite.py`)

The constants are already in `scripts/data/palette.gd` (`PRIMEVAL_*`); the ramps must use these exact values.

| Ramp | Colours (ink first, dark to light) | Use |
|---|---|---|
| `primeval_ink` / outline | `#120F0D` | every Titans sprite's outline (tar black) |
| `primeval_fern` | `#120F0D`, `#24451F`, `#4D8534`, `#8CC46A` | ferns, the hunters' feathers and hides, the Fern Basin |
| `primeval_ochre` | `#120F0D`, `#7E552A`, `#C89448`, `#E8C88A` | the herds' hides, dust, the Great Plain, the stampede's dust line |
| `primeval_tar` | `#120F0D`, `#231C18`, `#4A3A30`, `#6E5A4C` | tar, the Bog Croc, scorched earth, the Tyrants' dark hide |
| `primeval_lava` | `#120F0D`, `#8A2E0C`, `#EF6B1C`, `#FFC070` | lava, volcanic bombs, a Tyrant's throat, the meteor's tail (orange, never crimson) |
| `primeval_bone` | `#120F0D`, `#9C9078`, `#E7DEC9`, `#F8F6EE` | skeletons, horns, quills, the Fossil Giants, the sky's streak |

## Units (`assets/sprites/primeval/<id>.png`, + strips). Loaded by the code today: the SpriteBank keys `primeval/<kind>`

| Key | Size (art px, w x h) | Sex | What it is | Strips | Loaded now |
|---|---|---|---|---|---|
| `primeval/scuttler` | 20x14 | none | fodder: a tiny fast lizard, ochre with a dark back (swarms of 12) | walk | yes |
| `primeval/razorclaw` | 44x34 | male | soldier: a feathered raptor, fern-green hide, bone-white claws (the pack's males) | walk | yes |
| `primeval/razorclaw_alpha` | 48x38 | female | the pack's alpha: larger, a tall bone-white feather crest, a scar (drawn instead of the razorclaw when she leads; `RazorclawKit.draws_body()`) | walk | yes |
| `primeval/frill_spitter` | 40x32 | male | ranged: a lizard with a wide orange frill, venom at the jaw | walk | yes |
| `primeval/longneck` | 96x80 | mixed (one sprite) | herd: a huge sauropod, ochre hide, long neck and tail (neutral; it grazes and stampedes) | walk (slow, heavy) | yes |
| `primeval/duckbill` | 68x56 | none | herd: a hadrosaur with a bone-white crest horn | walk | yes |
| `primeval/skyraider` | 56x36 | male | flier, thief: a pterosaur, ochre wings, carrying glowing crystals when loaded (the code adds the glints) | fly | yes |
| `primeval/tyrant` | 88x72 | mixed (one sprite) | titan: a great tyrant, tar-black hide, a lava-orange glow in the throat, huge jaw | walk | yes |
| `primeval/horncharger` | 64x48 | male | phase 2 (the Great Plain): a ceratopsian, three horns, a bone frill; telegraphed charge | walk | phase 2 |
| `primeval/clubtail` | 64x44 | female | phase 2 (the Great Plain): an ankylosaur, armour plates, a bone club tail | walk | phase 2 |
| `primeval/bog_croc` | 72x30 | male | phase 2 (the Fern Basin): a crocodile, tar-black, eyes above the tar; lunges from the seeps | walk, `_submerged` still | phase 2 |
| `primeval/stormwing` | 72x44 | female | phase 2 (the Last Day): a larger pterosaur, a wing gust, lands to peck | fly, `_landed` still | phase 2 |
| `primeval/ironjaw` | 80x60 | female | Fern Basin miniboss: Ironjaw, the Nest Mother, a bulky predator | walk | phase 2 |
| `primeval/primeval_nest` | 48x32 | none | the Nest Mother's nest (a structure that spawns Scuttlers until destroyed), with `_dead` | none | phase 2 |
| `primeval/mother_clubtail` | 88x60 | female | Great Plain miniboss: Mother Clubtail, an armoured matriarch | walk | phase 2 |
| `primeval/thunderwing` | 112x64 | male | Last Day miniboss: Thunderwing, the Sky King, a giant pterosaur | fly | phase 2 |

## Bosses (`assets/sprites/primeval/<id>.png`; phase 2 wires them, `BossPoseData` poses by the stage agents)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `primeval/scarmaw` | 72x60 | female | Scarmaw, the Great Raptor: a huge feathered raptor, a bone crest, scarred muzzle (the Hunt, the Ambush, Blood Up) | walk, leap pose |
| `primeval/ironbrow` | 112x80 | male | Old Ironbrow, the Horned Titan: a giant ceratopsian with one horn broken off (`_broken` still after the Break) | walk |
| `primeval/gravejaw` | 128x104 | male | Old Gravejaw, the Tyrant King: the greatest tyrant, scarred, a lava glow in the throat (the Roar, the Hunt, the Last Day) | walk, roar pose |

## Playable characters (`assets/sprites/player/`; PLAN.md's convention: violet necromancers of the act's theme, never a beast; bone-white and soul-teal accents, pale undead-touched skin, a casting focus, 56 px tall, at most ~46 px wide)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `player/fern_huntress` | 40x56 | female (figure style) | violet hunting leathers and a violet fur-trimmed cloak, a raptor-skull headdress, a bone spear-staff with a soul flame (spell Pack Leap, Scarmaw) | walk, idle |
| `player/herd_warden` | 42x56 | male | heavy violet robes over a bone-plated mantle, a ceratopsian skull shoulder piece, a horn-topped staff (Stampede, Ironbrow) | walk |
| `player/skywatcher` | 38x56 | female (figure style) | violet star-robed dress, a bone astrolabe at the hip, a staff crowned with a small falling-star stone (Meteor Call, Gravejaw) | walk, idle |

## Summon class (finale reward; `assets/sprites/summons/`)

| Key | Size | What | Strips |
|---|---|---|---|
| `summons/bonehorn` | 40x34 | the Bonehorn: a skeletal horned charger (bone-white, soul-teal eye sockets) that tramples through a pack and trots back | walk |
| `summons/fossil_tyrant` | 52x44 | its evolution, the Fossil Tyrant | walk |
| `summons/fossil_giant` | 52x48 | the Fossil Giant (a herd beast's skeleton raised by the Herds rule; `PrimevalRulesData.HERDS` giant `sprite`: the code draws it as soon as the file exists, the Abomination's look until then) | walk |

## World markers (`assets/sprites/markers/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `markers/primeval_alpha` | 10x6 | the alpha's mark over its head (a bone-white chevron) | no (code rects) |
| `markers/primeval_shadow` | 48x24 | a diving Skyraider's shadow on the ground (soft tar-black ellipse) | no (code disc) |
| `markers/primeval_bomb` | 64x64 | a volcanic bomb's landing circle (lava-orange ring) | no (code discs) |

## Effects (`assets/sprites/fx/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `fx/primeval_dust_line` | 4x128 (tiling) | the stampede's telegraph line, 2 s ahead of the front (dust ochre) | no (code rect) |
| `fx/primeval_dust_front` | 56x128 (tiling) | the running front's dust cloud (ochre, soft edges, drawn along the 600 px front) | no (code rects) |
| `fx/primeval_bomb_burst` | strip 6 x 64x64 | a volcanic bomb landing (embers, lava splash) | no (code disc) |
| `fx/primeval_fossil_rise` | strip 6 x 48x48 | a heavy corpse rising as a Fossil Giant (bone dust) | no (code ring) |

## Floors (`assets/sprites/tiles/`, 128x128 seamless, dark and flat enough for the units to read)

| Key | What | Loaded now |
|---|---|---|
| `tiles/primeval_fern` | the Fern Basin's stage-select vignette tile until the stage has its own (jungle earth, fern fronds) | yes (vignettes) |
| `tiles/primeval_plain` | the Great Plain's vignette tile (dry grass, dust) | yes (vignettes) |
| `tiles/primeval_ash` | the Last Day's vignette tile (scorched earth, ash) | yes (vignettes) |
| `tiles/fern_basin_fern_floor` / `_tar_seep` / `_river_ford` / `_nesting_hollow` | the Fern Basin's four zones | phase 2 |
| `tiles/great_plain_dust_flats` / `_watering_hole` / `_canyon` / `_bone_gate` | the Great Plain's four zones | phase 2 |
| `tiles/last_day_scorched_plain` / `_ash_forest` / `_lava_fields` / `_impact_rim` | the Last Day's four zones (the sky's white shows only as a pale haze in value) | phase 2 |
| `tiles/primeval_tar` | a tar seep patch (drawn stretched; phase 2's TerrainSlow ground) | phase 2 |

## Obstacles (`assets/sprites/obstacles/`; rect kinds also `_v`, turned 90 degrees). The stubs use these kind ids (code-drawn by `PrimevalGlyphs` today); every obstacle is SHELTER from a stampede

| Key | Size | What | Loaded now |
|---|---|---|---|
| `obstacles/primeval_rock` | 36x36 | a mossy boulder (circle kind; scorched on the Last Day) | code |
| `obstacles/primeval_fossil` + `_v` | 52x30 | a fossil rib arch (bone ribs over a dark rock) | code |
| `obstacles/primeval_tree_fern` | 40x48 | phase 2 (the Fern Basin): a tree fern trunk | phase 2 |
| `obstacles/primeval_canyon_wall` + `_v` | 96x32 | phase 2 (the Great Plain): a canyon wall segment (the narrow lanes) | phase 2 |
| `obstacles/primeval_lava_rock` | 40x40 | phase 2 (the Last Day): a cooling lava boulder | phase 2 |

## Icons (`assets/sprites/icons/<id>.png`, 32x32 badges on the approved frames: violet = spells / passives / counter-passives / classes, gold = evolutions and achievements)

| Id | What |
|---|---|
| `icons/pack_leap` | spell: Pack Leap (three spectral raptors leap at marked enemies) |
| `icons/stampede` | spell: Stampede (a spectral horned charger tramples a line) |
| `icons/meteor_call` | spell: Meteor Call (a telegraphed meteor on the densest group) |
| `icons/apex_pack` | evolution of Pack Leap |
| `icons/herd_of_ages` | evolution of Stampede |
| `icons/extinction_event` | evolution of Meteor Call |
| `icons/pack_instinct` | paired passive of Pack Leap |
| `icons/calcified_hide` | paired passive of Stampede |
| `icons/cosmic_dust` | paired passive of Meteor Call |
| `icons/hoarders_bones` | counter-passive (crystals within 300 px cannot be snatched) |
| `icons/thick_marrow` | counter-passive (summons take less from trampling, charges and stomps) |
| `icons/ach_nothing_taken` | achievement Nothing Taken |
| `icons/ach_trampled` | achievement Trampled |
| `icons/ach_the_day_the_sky_fell` | achievement The Day the Sky Fell |
| `icons/bonehorn` | summon class icon |
| `icons/fossil_tyrant` | its evolution icon |

## Audio

- **Music** key `primordial` (proposed), a score `SoundData.PRIMORDIAL_SCORE` "Before the Fall" (proposed title): slow,
  heavy and wide; low tom-like `drums` in a loping 6/8, a breathy `flute` melody over a long drone (`organ`), distant
  `horn` calls like beasts, and a high thin tone (`arp`, sparse) that rises through the loop like the streak in the sky.
  Existing synth jobs only. `SoundData.SCORES["primordial"]`, `SCORE_PACKS["primordial"] = "titans"`,
  `Sfx.SCORE_SEEDS["primordial"]` (the next free value after the Host's `hosanna`), `Sfx.MUSIC_PRIMORDIAL`. The stubs
  play `"starsong"` (the Concord's "The Reaping Stars": the Harvesters' log led here) until then; the lead switches each
  Titans STAGE's `"music"` at the merge.
- **Sound pack** `SoundData.TITANS_SOUNDS` (lazy with the score; `Sfx.PACK_SEED_OFFSETS["titans"]`, the next free offset
  after the Host's 10000). Ids, one per `PrimevalRulesData.SOUNDS` event (each event's comment names its pack id; the
  lead points the map at them at the merge): `pack_rustle` (ferns rustling on both flanks, a low chatter), `pack_hiss`
  (a held, rising hiss), `pack_rush` (claws on earth, a shriek), `alpha_slain` (a broken screech, the pack's yelps),
  `stampede_warn` (a deep rolling rumble, a bellow), `stampede_run` (heavy footfalls in rhythm), `trample` (a heavy thud,
  bones cracking), `fossil_rise` (stone cracking, a hollow bone groan), `skyraider_dive` (a falling whistle and a
  screech), `snatch` (a beak clack and crystals chiming away), `pile_drop` (crystals scattering on stone), `bomb_warn` (a
  falling roar of fire), `bomb_land` (a molten crack, a splash of embers), `ash_horn` (the sky burns: a long low roar of
  herds).
- Art and audio agents run no Godot (PLAN.md); the lead's integration imports their files and the owner hears the loop.

## Status (art and audio agent, foundation)

Done: palette ramps `primeval_*`; units `scuttler`, `razorclaw`, `razorclaw_alpha`, `frill_spitter`, `longneck`, `duckbill`, `skyraider`, `tyrant` (+ walk
strips, the Skyraider's flap strip is `_walk`); obstacles `primeval_rock`, `primeval_fossil` (+ `_v`); all 16 icons; floors `primeval_fern`,
`primeval_plain`, `primeval_ash`; markers `primeval_alpha`, `primeval_shadow`, `primeval_bomb`; fx `primeval_dust_line`, `primeval_dust_front`,
`primeval_bomb_burst`, `primeval_fossil_rise`; the score `primordial` "Before the Fall" (seed `SYNTH_SEED - 14`) and the pack `titans` (offset 11000,
14 sounds); both wired (stages' `"music"`, `PrimevalRulesData.SOUNDS`). Sizes: all inside the manifest boxes (Alpha 28x38, Duckbill 48x56, Frill 36x32,
Razorclaw 40x34, Longneck 88x80, Tyrant 86x72, Skyraider 40x36, Scuttler 20x12). Still missing (phase 2): `horncharger`, `clubtail`, `bog_croc`,
`stormwing`, `ironjaw`, `primeval_nest`, `mother_clubtail`, `thunderwing`, the three bosses, the three characters, the summon class sprites
(`bonehorn`, `fossil_tyrant`, `fossil_giant`; the two icons exist), the zone floors, `primeval_tar`, `primeval_tree_fern`, `primeval_canyon_wall`,
`primeval_lava_rock`.
