# The Turning Year: art and audio manifest (what to make)

Written by the foundation agent for the art + audio agent and the three stage agents (act slot XV, temporary Act XV,
stage key `wild`; GDD §15.0 "The Turning Year foundation (phase 1)"). It lists every sprite, strip, icon, floor,
obstacle and marker the foundation and phase 2 need, and the score and sound pack. Model: `docs/titans/ART_MANIFEST.md`
(rebuild its tools the same way under `art_source/year/`).

Rules for every image (CLAUDE.md, `docs/last_acts/PLAN.md`):
- True pixel art, 1 art px = 1 screen px, the reference set's dark 1 px outline and flat shading; heights go in
  `SpriteData.HEIGHTS` (block "Act XV slot: the Turning Year"). Strips: `<id>_walk.png` = 8 frames side by side (a
  `_glide` strip for the floating spirits), `<id>_idle.png` = 24 frames for every female figure in the figure-redesign
  style (bust rig in `tools/walk_cycle.py`): the Dryad, the Winter Fae, the Spore Mother, the Summer Queen, the Green
  Mother and the two female characters. Every female figure is **fully clothed** (bark, leaves, frost lace, gowns).
  The beasts (the Great Stag, the Hunt's hounds) are animals: no bust rig.
- **The act's palette: moss, bark, blossom pink, gold leaves and frost white**, and the blight a **dead grey that reads
  strongly** against the living green (the owner's concept note: "the blight should read stronger than this in the
  game"). Gold keeps its meaning (evolution, chest, victory): the leaves are a warmer **amber**, never the UI gold;
  crimson stays danger (the wildfire is orange-red, the roots bark-brown). No Wild creature wears the necromancer's
  violet; the playable characters do.
- Each **season repaints the arena** through a tint on the floor (`WildRulesData.SEASON_TINTS`): make the floors in a
  neutral, mid-value moss so the spring / summer / autumn / winter tints all read (test each tile under the four tints).
- Concept art (approved): `art_source/concepts/final5/year_lineup.png`, `year_bosses.png`, `year_stage.png` with their
  `.txt` prompts.
- The code draws a fallback for every key below (`WildGlyphs`, `SeasonCycle.draw()`, `BloomField.draw()`,
  `Thickets.draw()`, `SeasonWheel`, `WildGround`), so a missing PNG never breaks a run.

## Palette ramps (`tools/palette.json`, faction set `wild` in `prepare_sprite.py`)

The constants are already in `scripts/data/palette.gd` (`WILD_*`); the ramps must use these exact values.

| Ramp | Colours (ink first, dark to light) | Use |
|---|---|---|
| `wild_ink` / outline | `#14100C` | every Wild sprite's outline (deep bark) |
| `wild_moss` | `#14100C`, `#274D24`, `#599641`, `#9CCB72` | living ground, dryads, fae armour, spring |
| `wild_bark` | `#14100C`, `#553C27`, `#86603E`, `#B08A60` | treants, thickets, roots, antlers' base, the Hunt's leather |
| `wild_blossom` | `#14100C`, `#9C5272`, `#EFA6C3`, `#FBD9E6` | the Fae Court, the Summer Queen, corpse-blooms, Spring Returns |
| `wild_leaf` | `#14100C`, `#8A5420`, `#D9953C`, `#F2C67A` | summer grass, autumn leaves, spore mothers (amber, never the UI gold) |
| `wild_frost` | `#14100C`, `#6F8AA4`, `#B9CEE0`, `#E4EDF5` | winter, the Winter Court, the blizzard, the Wild Hunt's spectral glow |
| `wild_blight` | `#14100C`, `#312E2C`, `#57524D`, `#86807A` | blighted ground, dead grass, ash, the smoke line |

## Units (`assets/sprites/wild/<id>.png`, + strips). Loaded by the code today: the SpriteBank keys `wild/<kind>`

| Key | Size (art px, w x h) | Sex | What it is | Strips | Loaded now |
|---|---|---|---|---|---|
| `wild/thornling` | 22x20 | none | fodder: a twig creature, bark body, moss tufts, thorn claws (swarms of 12) | walk | yes |
| `wild/dryad` | 34x52 | female (figure style) | support: a tree spirit in a gown of bark and leaves, blossom in her hair, a seed pouch; plants thicket seeds | walk, idle (bust box moved onto the torso, round 4 redo) | yes |
| `wild/treant` | 64x80 | none | heavy: a walking oak, a face in the bark, branch arms, moss | walk (slow, heavy) | yes |
| `wild/corpse_bloom` | 48x48 | none | structure: a huge pink flower on a mound of bones, petals around a maw; with `_dead` | none | yes |
| `wild/fae_knight` | 36x52 | male | soldier: leaf-plate armour, a thorn sword, a leaf-crested helm | walk | yes |
| `wild/winter_fae` | 34x52 | female (figure style) | ranged: a lady of the Winter Court, frost-lace gown, an icicle crown, frost in her hand (winter only) | walk, idle | yes |
| `wild/great_stag` | 72x64 | male | elite: a huge stag, moss in its antlers, glowing pale eyes | walk | yes |
| `wild/wild_rider` | 72x64 | male | elite: a spectral horseman of the Wild Hunt, antlered helm, a spear, frost-blue glow | walk | yes |
| `wild/hunt_hound` | 40x28 | none | the Rider's two hounds (phase 2: they run with him) | walk | phase 2 |
| `wild/will_o_wisp` | 24x28 | none | lure: a drifting cold light with a faint face | glide | yes |
| `wild/spore_mother` | 38x52 | female (figure style) | support: a mushroom matron, a wide cap like a hat, a shawl of moss, spores at her hands | walk, idle | yes |
| `wild/huntsman` | 80x68 | male | Greenwood miniboss: the Huntsman of the Wild Hunt, a horn at his belt, a great antlered mount | walk | phase 2 |
| `wild/winter_prince` | 40x56 | male | Fae Court miniboss: the Winter Prince, frost armour, a cloak of snow (brings one minute of winter) | walk | phase 2 |
| `wild/gardener_of_roots` | 80x88 | none | World-Tree miniboss: the Gardener of Roots, a great treant with root-hands | walk | phase 2 |

## Bosses (`assets/sprites/wild/<id>.png`; phase 2 wires them, `BossPoseData` poses by the stage agents)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `wild/stag_king` | 72x88 | male | the Stag King: stag-headed, antlered lord of the forest, a hunting horn, a mantle of leaves (the Hunt, the Rut, the Antler Crown) | walk, horn pose, `_crown` (the thicket ring of antlers) |
| `wild/summer_queen` | 64x80 | female (figure style) | the Summer Queen: butterfly wings, a gown of roses, a crown of blossoms; with `_mask` (a court face, the Masque) | glide, idle, bargain pose |
| `wild/green_mother` | 128x144 | female (figure style) | the Green Mother: a colossal goddess grown from the tree, **half in bloom and half in frost** (the whole year in one figure) | idle, cast pose, `_burial` pose |

## Playable characters (`assets/sprites/player/`; PLAN.md's convention: violet necromancers of the act's theme, never a fae; bone-white and soul-teal accents, pale undead-touched skin, a casting focus, 56 px tall, at most ~46 px wide)

| Key | Size | Sex | What | Strips |
|---|---|---|---|---|
| `player/horned_herald` | 42x56 | male | violet hunting robes with a bone-antler hood, a hunting horn of bone at the hip, a staff with a soul flame between antler tines (spell Wild Hunt, the Stag King) | walk |
| `player/changeling_princess` | 38x56 | female (figure style) | a violet gown with gossamer-leaf layers, a bone mask held on a stick, a slim wand with a soul-teal moth (Glamour, the Summer Queen) | walk, idle |
| `player/gravegardener` | 40x56 | female (figure style) | a violet gardener's robe with an apron of roots, a bone trowel-staff with a sprouting soul seed, a wide-brimmed violet hat (Root and Rot, the Green Mother) | walk, idle |

## Summon class (finale reward; `assets/sprites/summons/`)

| Key | Size | What | Strips |
|---|---|---|---|
| `summons/ossuary_oak` | 48x56 | the Ossuary Oak: a slow tree of bone that roots in place as a blocker, thorn lashes, soul-teal knots | walk (slow), `_rooted` still |
| `summons/world_root_warden` | 56x64 | its evolution, the World-Root Warden | walk, `_rooted` still |

## World markers (`assets/sprites/markers/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `markers/wild_roots` | 24x16 | roots sprouting under a body that stood still (Spring; shown 0.6 s before the grab) | no (code rects) |
| `markers/wild_sprout` | 32x32 | a thicket seed sprouting (grows to the thicket's size in 4 s) | no (code disc + rect) |
| `markers/wild_blight` | 64x64 (tiling) | a blighted cell: dead grey grass, cracked earth (drawn per 64 px cell, alpha by blight) | no (code rects) |
| `markers/wild_season_wheel` | 28x28 | the HUD's wheel of the year (four quarters; the hand is code) | no (code arcs) |

## Effects (`assets/sprites/fx/`)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `fx/wild_smoke_line` | 4x128 (tiling) | the wildfire's telegraph line, 2 s ahead of the front (ash grey) | no (code rect) |
| `fx/wild_fire_front` | 44x128 (tiling) | the running wildfire's flames (orange-red, amber core, drawn along the 520 px front) | no (code rects) |
| `fx/wild_blizzard` | 128x128 radial | the blizzard's snow veil (clear inside 400 px of the necromancer) | no (code gradient) |
| `fx/wild_snowfall` | strip 8 x 64x64 | falling snow over the view in winter (optional, drawing only) | no |
| `fx/wild_leaves` | strip 8 x 64x64 | falling leaves in autumn (optional, drawing only) | no |
| `fx/wild_thicket_burn` | strip 6 x 48x48 | a thicket burning to ash | no |
| `fx/wild_bury` | strip 6 x 40x40 | earth closing over a buried summon (Spring Returns) | no |

## Floors (`assets/sprites/tiles/`, 128x128 seamless, dark and flat enough for the units to read; neutral under the four season tints)

| Key | What | Loaded now |
|---|---|---|
| `tiles/wild_greenwood` | the Greenwood's stage-select vignette tile until the stage has its own (moss, ferns, fallen leaves) | yes (vignettes) |
| `tiles/wild_fae` | the Fae Court's vignette tile (grass, petals, a mushroom ring) | yes (vignettes) |
| `tiles/wild_tree` | the World-Tree's vignette tile (bark and great roots) | yes (vignettes) |
| `tiles/greenwood_glade` / `_deep_wood` / `_hunting_grounds` / `_stags_hollow` | the Greenwood's four zones | phase 2 |
| `tiles/fae_court_rose_maze` / `_revel` / `_mirror_lake` / `_throne_of_blossoms` | the Fae Court's four zones | phase 2 |
| `tiles/world_tree_roots` / `_trunk_stair` / `_crown` / `_seed` | the World-Tree's four zones | phase 2 |
| `tiles/wild_fairy_ring` | a fairy ring patch (the Fae Court: half-speed time inside) | phase 2 |

## Obstacles (`assets/sprites/obstacles/`; rect kinds also `_v`, turned 90 degrees). The stubs use these kind ids (code-drawn by `WildGlyphs` today)

| Key | Size | What | Loaded now |
|---|---|---|---|
| `obstacles/wild_oak` | 40x40 | an old oak's trunk, moss on the bark (circle kind) | code |
| `obstacles/wild_stone` + `_v` | 52x30 | a mossy standing stone (rect kind) | code |
| `obstacles/wild_thicket_m` | 52x52 | **the thorn thicket** every Wild stage grows (Overgrowth; collision circle r 26; the code loads this key as soon as it exists) | yes (key set) |
| `obstacles/wild_grove_tree` | 40x48 | phase 2 (the Greenwood): a sacred grove's standing tree (living / dead pair) | phase 2 |
| `obstacles/wild_rose_hedge` + `_v` | 96x32 | phase 2 (the Fae Court): a rose-maze hedge segment | phase 2 |
| `obstacles/wild_great_root` + `_v` | 96x28 | phase 2 (the World-Tree): a great root of the tree | phase 2 |

## Icons (`assets/sprites/icons/<id>.png`, 32x32 badges on the approved frames: violet = spells / passives / counter-passives / classes, gold = evolutions and achievements)

| Id | What |
|---|---|
| `icons/wild_hunt` | spell: Wild Hunt (spectral riders sweep across the screen in a line) |
| `icons/glamour` | spell: Glamour (illusory copies of the necromancer draw enemy attacks) |
| `icons/root_and_rot` | spell: Root and Rot (a ring of roots at the strongest enemy rots everything inside) |
| `icons/the_endless_hunt` | evolution of Wild Hunt |
| `icons/court_of_masks` | evolution of Glamour |
| `icons/return_to_earth` | evolution of Root and Rot |
| `icons/horn_of_the_hunt` | paired passive of Wild Hunt |
| `icons/changeling` | paired passive of Glamour |
| `icons/compost_heart` | paired passive of Root and Rot |
| `icons/deadwood` | counter-passive (roots and thickets hold summons half as long) |
| `icons/fallow_ground` | counter-passive (blight spreads twice as fast) |
| `icons/ach_scorched_earth` | achievement Scorched Earth |
| `icons/ach_a_fair_bargain` | achievement A Fair Bargain |
| `icons/ach_the_first_spring` | achievement The First Spring |
| `icons/ossuary_oak` | summon class icon |
| `icons/world_root_warden` | its evolution icon |

## Audio

- **Music** key `wildwood` (proposed), a score `SoundData.WILDWOOD_SCORE` "The Turning Year" (proposed title): the
  campaign's last loop, pastoral and vast; a lilting 3/4 `flute` melody over a soft `organ` drone, plucked `arp` like a
  harp, bright `bells` at each phrase like birdsong, a low `horn` call (the Wild Hunt) on the turn of each section, and
  `drums` only as a heartbeat that swells in the last section (the year turning). Existing synth jobs only.
  `SoundData.SCORES["wildwood"]`, `SCORE_PACKS["wildwood"] = "wild"`, `Sfx.SCORE_SEEDS["wildwood"]` = `SYNTH_SEED - 15`
  (the next free value after the Titans' `primordial`, `SYNTH_SEED - 14`), `Sfx.MUSIC_WILDWOOD`. The stubs play
  `"primordial"` (the Titans' "Before the Fall": the old world leads into the world itself) until then; the lead switches
  each Wild STAGE's `"music"` at the merge.
- **Sound pack** `SoundData.WILD_SOUNDS` (lazy with the score; `Sfx.PACK_SEED_OFFSETS["wild"]` = 12000, the next free
  offset after the Titans' 11000). Ids, one per `WildRulesData.SOUNDS` event (each event's comment names its pack id; the
  lead points the map at them at the merge): `season_turn` (a bell of wood and wind: the year turns), `roots_grab` (roots
  cracking up through soil, a creak), `wildfire_warn` (a rising crackle, a gust of smoke), `wildfire_burn` (a roar of dry
  grass catching), `blizzard` (a howling white wind), `thicket_grow` (thorns snaking up, a woody snap), `thicket_burn`
  (thorns crackling to ash), `bury` (earth closing, a deep thud), `spring_horn` (Spring Returns: every bird and leaf at
  once, a vast green chord).
- Art and audio agents run no Godot (PLAN.md); the lead's integration imports their files and the owner hears the loop.

## Status (art + audio agent, foundation, Nov 2026)

Made (ART_BIBLE "Act XV slot: the Turning Year"): the palette ramps; the ten shared kinds with walk / glide strips and the Dryad, Winter Fae and Spore Mother idle strips
(`wild/thornling` ... `wild/spore_mother`, `wild/corpse_bloom_dead`); obstacles `wild_oak_s` / `_l`, `wild_stone_s` / `_l` (+ `_v`) and `wild_thicket_m` (the stages' two `sizes` pick
`_s` / `_l`); all 16 icons; floors `wild_greenwood`, `wild_fae`, `wild_tree`; markers `wild_roots`, `wild_sprout`, `wild_blight`, `wild_season_wheel`; effects `wild_smoke_line`, `wild_fire_front`,
`wild_blizzard`, `wild_snowfall`, `wild_leaves`, `wild_thicket_burn`, `wild_bury`; the score (music key `wildwood`) and the pack, wired. Not made (phase 2): `wild/hunt_hound`, `huntsman`,
`winter_prince`, `gardener_of_roots`; the three bosses and their poses / `_crown` / `_mask` / `_burial`; the three characters; the Ossuary Oak and World-Root Warden; the zone floors and
`wild_fairy_ring`; `wild_grove_tree`, `wild_rose_hedge`, `wild_great_root`. The score uses the default heartbeat job instead of a swelling "drums" (the jobs cannot swell inside one loop).

## Status (the Greenwood, phase 2, Nov 2026)

The Greenwood is built and loads these keys as soon as their PNGs exist (code shapes until then; sizes in
`SpriteData.FLAT_SIZES`): `wild/hunt_hound` (+ walk), `wild/huntsman` (+ walk; the Rider's art meanwhile),
`wild/antler_thicket` (one thorn of the Stag King's Antler Crown, about 28 px, no strip), `wild/stag_king` (+ walk, pose 1
`wild/stag_king_horn`: the horn raised while a Hunt rides, `BossPoseData`; the crown is the thorn units, so no `_crown`
sprite is needed), `player/horned_herald` (+ walk), `obstacles/wild_grove_tree` (40x48, a sacred grove's tree, drawn by
`GreenwoodDirector` on the grove's ring; never an obstacle; a dead grove draws grey stumps by code) and the four zone tiles
`tiles/greenwood_glade` / `_deep_wood` / `_hunting_grounds` / `_stags_hollow` (until then the act's `tiles/wild_greenwood`
floors every zone). Icons, the sound pack and the obstacles were already made.

## Status (the Fae Court, phase 2, Nov 2026)

The Fae Court is built and loads these keys as soon as their PNGs exist (code shapes until then; sizes in
`SpriteData.FLAT_SIZES`): `wild/winter_prince` (+ walk; the miniboss, male), `wild/masked_courtier` (+ walk; a fae
courtier in a gown of roses, female, figure style, fully clothed; drawn as `wild/summer_queen_mask` while masked),
`wild/summer_queen` (+ glide, idle; pose 1 `wild/summer_queen_bargain`: a hand held out with the bargain, `BossPoseData`;
female, figure style, fully clothed), `wild/summer_queen_mask` (her masked face, the same 64x80 frame: the Masque's
courtiers wear it too, so it must read as her), `player/changeling_princess` (+ walk, idle; violet necromancer, female,
figure style, fully clothed), `obstacles/wild_rose_hedge_m` and `_m_v` (96x32, a one-size rect kind, so the `_m` key; the
rose-maze hedge), `tiles/wild_fairy_ring` (a fairy ring's patch, drawn stretched over the ring's 160 px circle by
`FaeCourtDirector`) and the four zone tiles `tiles/fae_court_rose_maze` / `_revel` / `_mirror_lake` / `_throne_of_blossoms`
(until then the act's `tiles/wild_fae` floors every zone). Glamour's copies draw the caster's own art in a pale violet
tint (no new sprite). Icons (`glamour`, `court_of_masks`, `changeling`, `deadwood`, `ach_a_fair_bargain`) and the sound
pack were already made.
