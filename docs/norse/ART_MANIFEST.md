# Hall of the Slain: art and audio manifest

Everything the stage agents load by name. Art made by `art_source/norse/gen.py` (prompts `art_source/norse/<key>.txt`, API sources `<key>.png`), `convert.sh` (pixelate + `prepare_sprite.py`), `tools/walk_cycle.py` (rigs in `RIGS`), `gen_icons.py` + `compose_icons.py` (icons), `tools/norse_tiles.py` (floors, obstacles, overlays). Heights are in `SpriteData.HEIGHTS` (`norse/<key>`). Sprite folder `assets/sprites/norse/`; boss and structure sprites live there too (not `bosses/` / `structures/`). The three playable characters live in `assets/sprites/player/` (moved at the wave 1 integration).

## Palette (`tools/palette.json`, folder `norse` in `prepare_sprite.py`)

One hue per ramp, shared ink `norse_ink` #0B0F16: `frost` (#A9BBCC, #EAF2FA), `iron` (#2B3139, #5B6570, #8F99A3), `pine` (#12281F, #1F4A3A), `hearth` (#A24C1A, #F0902E, #FFC766; per key only), `valk` (#B08A3C, #F5D77A, #FFF3C4), `rune` (#3F72C4, #8FD0FF, #E0F4FF; clear of soul-teal #3DCC94), `draugr` (#34495A, #6C8CA0, #A6C0CE), and the ground ramp `norse_floor` (night snow, fjord ice, hall planks, hall slabs, Vigrid ash; floor group, tiles only). `scripts/data/palette.gd` has a `NORSE_<RAMP>[_DARK|_LIGHT|_GLOW]` constant for every unit / glow / ink colour (added or aligned to these hexes at the wave 1 integration; the floor colours are tiles only).

## Sprites (`assets/sprites/norse/`)

| Key | Size (art px) | Files | What it is |
|---|---|---|---|
| `norse/barrow_king` | 52x62 | barrow_king.png, barrow_king_walk.png | the Draugr Thane's evolution (walk) |
| `norse/barrow_wight` | 56x56 | barrow_wight.png, barrow_wight_walk.png | miniboss, male draugr chieftain (walk) |
| `norse/berserker` | 60x50 | berserker.png, berserker_walk.png | male elite in a bear pelt, red eyes (walk) |
| `player/berserker_hero` | 64x56 | berserker_hero.png, berserker_hero_walk.png | playable character (REDONE): male purple-hooded necromancer, bear-skull crest, one soul-teal axe held close (glide) |
| `norse/boss_barrow` | 64x56 | boss_barrow.png | Hrimgar's barrow, intact (still; the necromancer breaks it while he is down) |
| `norse/boss_barrow_broken` | 60x56 | boss_barrow_broken.png | Hrimgar's barrow, broken (still) |
| `norse/draugr` | 36x42 | draugr.png, draugr_walk.png | male barrow-dead soldier (walk) |
| `norse/draugr_female` | 32x42 | draugr_female.png, draugr_female_walk.png, draugr_female_idle.png | FEMALE barrow-dead soldier (walk, bust, idle) |
| `norse/draugr_thane` | 52x54 | draugr_thane.png, draugr_thane_walk.png | finale summon class, undead blocker (walk) |
| `norse/einherjar` | 42x46 | einherjar.png, einherjar_walk.png | male gold-lit hero elite, base for the Einherjar kind and Risen Einherjar (walk) |
| `norse/einherjar_champion` | 52x60 | einherjar_champion.png, einherjar_champion_walk.png | miniboss, male gold-lit hero (walk) |
| `norse/brazier_lit` | 32x32 | brazier_lit.png | Long Winter brazier, lit: hearth-amber flames in an iron bowl (still) |
| `norse/brazier_doused` | 32x32 | brazier_doused.png | the same brazier doused: cold ash, a smoke wisp (still) |
| `norse/frost_creep` | 128x48 | frost_creep.png | tileable (horizontally) frost edge for the Long Winter vignette; flat overlay, the code rotates it per screen edge |
| `norse/einherjar_overlay` | 48x48 | einherjar_overlay.png | 48x48 dithered pale-gold aura ring, draw additively around an Einherjar (the gold overlay) |
| `norse/fenrir` | 100x80 | fenrir.png, fenrir_walk.png | boss creature, giant black wolf with a broken chain, ~100 px long (walk) |
| `norse/fire_giant` | 64x80 | fire_giant.png, fire_giant_walk.png | miniboss, male fire-giant of the south (walk) |
| `norse/frost_giant` | 56x72 | frost_giant.png, frost_giant_walk.png | male heavy, boulder on shoulder (walk) |
| `norse/hrimgar` | 54x88 | hrimgar.png, hrimgar_walk.png | boss, male Draugr-King (walk) |
| `norse/odin` | 48x72 | odin.png, odin_walk.png | boss, male All-Father: eyepatch, dark hooded cloak, no wizard hat, ravens, Gungnir (glide) |
| `norse/raider` | 40x40 | raider.png, raider_walk.png | male fodder, axe and round shield (walk) |
| `norse/raven` | 18x18 | raven.png | Odin's raven, small creature (still) |
| `player/rune_seer` | 38x56 | rune_seer.png, rune_seer_walk.png, rune_seer_idle.png | playable character (REDONE, owner note): FEMALE violet-robed volva necromancer, grey fur mantle, rune staff with a soul-teal rune (glide, bust, idle) |
| `norse/rune_stone` | 28x40 | rune_stone.png | structure, held: glowing runes (still; code draws the capture ring) |
| `norse/rune_stone_taken` | 28x40 | rune_stone_taken.png | structure, taken: dead runes (still) |
| `norse/seer` | 32x46 | seer.png, seer_walk.png, seer_idle.png | FEMALE support (volva), staff and rune (glide, bust, idle) |
| `norse/shield_maiden` | 52x44 | shield_maiden.png, shield_maiden_walk.png, shield_maiden_idle.png | FEMALE soldier, spear and shield (walk, bust, idle) |
| `player/shield_maiden_hero` | 48x56 | shield_maiden_hero.png, shield_maiden_hero_walk.png, shield_maiden_hero_idle.png | playable character (REDONE): FEMALE purple-cloaked necromancer, bone-rimmed shield, soul-flame spear focus (glide, bust, idle) |
| `norse/sigrun` | 60x80 | sigrun.png, sigrun_walk.png, sigrun_idle.png | boss, FEMALE Shield-Queen, wings and shield (glide, bust, idle) |
| `norse/skald` | 36x44 | skald.png, skald_walk.png | male support, war-horn and lyre (glide) |
| `norse/valkyrie` | 46x52 | valkyrie.png, valkyrie_walk.png, valkyrie_idle.png | FEMALE flying elite, white-gold wings (glide + bust + idle; the Choosing; use with valkyrie_shadow) |
| `norse/valkyrie_shadow` | 40x20 | valkyrie_shadow.png | 40x20 dithered gold ellipse, the dive telegraph shadow (code places it 1 s ahead) |
| `norse/wolf_of_the_wastes` | 40x26 | wolf_of_the_wastes.png, wolf_of_the_wastes_walk.png | grey wolf, pack fodder (walk) |

Strips: `_walk` 8 frames of the still's size (legs / glide / robe rigs), `_idle` 24 frames (bust rig, every female figure that has one). Frame 0 of each strip is the still.

**The three playable characters follow the necromancer convention (owner note, Nov 2026):** violet dominant, bone and soul-teal accents, pale skin, a casting focus, 56 px tall, at most 40 px wide; converted with the violet / bone / soul / grey ramps added in `KEY_RAMPS`; sources `art_source/norse/gen_chars.py`.

## Tiles and obstacles (`assets/sprites/tiles/`, `obstacles/`)

| File | Size | Use |
|---|---|---|
| `tiles/norse_snow.png` | 128x128 | Barrow Fields: Longshore, Barrows, Jarl's Hall (seamless 128) |
| `tiles/norse_ice.png` | 128x128 | Frozen Fjord, Vigrid's Frozen Sea (seamless 128) |
| `tiles/norse_planks.png` | 128x128 | Valgard Shield Yard / Mead Hall (seamless 128) |
| `tiles/norse_slabs.png` | 128x128 | Valgard Hall of Spears / Valkyries' Gate (seamless 128) |
| `tiles/norse_ash.png` | 128x128 | Vigrid Ash Plain / Giants' March / the Field (seamless 128) |
| `obstacles/mound_s.png` | 36x24 | burial mound (+ `_v`, mirrored) |
| `obstacles/mound_s_v.png` | 36x24 | burial mound (+ `_v`, mirrored) |
| `obstacles/mound_l.png` | 56x36 | burial mound |
| `obstacles/mound_l_v.png` | 56x36 | burial mound |
| `obstacles/barrow_closed.png` | 48x38 | stage barrow, sealed |
| `obstacles/barrow_open.png` | 48x38 | stage barrow, open with ice-blue glow (the Open barrows rule) |
| `obstacles/long_table_s.png` | 48x24 | Valgard long table with benches, horizontal (+ `_v` rotated) |
| `obstacles/long_table_s_v.png` | 24x48 | Valgard long table with benches, horizontal (+ `_v` rotated) |
| `obstacles/long_table_l.png` | 72x26 | long table, horizontal (+ `_v`) |
| `obstacles/long_table_l_v.png` | 26x72 | long table, horizontal (+ `_v`) |
| `obstacles/standing_shield_s.png` | 24x28 | shield on a post (+ `_v`) |
| `obstacles/standing_shield_s_v.png` | 24x28 | shield on a post (+ `_v`) |
| `obstacles/standing_shield_l.png` | 36x34 | shield on a post |
| `obstacles/standing_shield_l_v.png` | 36x34 | shield on a post |
| `obstacles/pine_s.png` | 24x38 | snowy pine |
| `obstacles/pine_l.png` | 34x52 | snowy pine, large |

## Icons (`assets/sprites/icons/`, 32x32 badges, violet ring; gold ring = evolution)

| File | What |
|---|---|
| `icons/barrow_grasp.png` | spell Barrow Grasp |
| `icons/valkyrie_spear.png` | spell Valkyrie Spear |
| `icons/gungnir.png` | spell Gungnir |
| `icons/grave_frost.png` | passive Grave Frost |
| `icons/einherjars_oath.png` | passive Einherjar's Oath |
| `icons/runecraft.png` | passive Runecraft |
| `icons/inglorious.png` | counter-passive Inglorious |
| `icons/calm_blood.png` | counter-passive Calm Blood |
| `icons/barrow_lords_embrace.png` | evolution Barrow-Lord's Embrace (gold) |
| `icons/chooser_of_the_slain.png` | evolution Chooser of the Slain (gold) |
| `icons/spear_of_the_hanged.png` | evolution Spear of the Hanged (gold) |
| `icons/barrow_king.png` | summon evolution Barrow King (gold) |
| `icons/draugr_thane.png` | summon class Draugr Thane |

## Audio (`scripts/data/sound_data.gd`, `scripts/audio/sfx.gd`)

- Score `SoundData.VALHALL_SCORE`, id `valhall` in `SCORES`, "Horns at the Last Feast" (16 s: war drums, low horn calls, a cold drone, bare organ fifths, frozen chimes; existing jobs only). STAGE key: `"music": "valhall"`. Seed `Sfx.SCORE_SEEDS["valhall"] = SYNTH_SEED - 11`; `MUSIC_VALHALL`.
- Pack `SoundData.NORSE_SOUNDS` (`SCORE_PACKS["valhall"] = "norse"`, `Sfx.PACK_SEED_OFFSETS["norse"] = 8000`): `valkyrie_dive`, `berserk_roar`, `rune_capture`, `horn_call`, `frost_giant_stomp`, `einherjar_rise`. Nothing plays them yet.
- Seeds / offsets assume the plan's order: Black Tide -10 / 7000, Norse -11 / 8000, Dynasty -12 / 9000. Resolve at the merge if another branch took them.

## Not made (decide with the stage agents)
- Spell effect strips (Barrow Grasp hands, spear dive, Gungnir): code-drawn or tint masks later.
- Skins / Hyper skins for the three characters.
- Hearth fire, mead-hall braziers, Fenrir's chain, Odin's ravens in flight (the `raven` still can be spun by code).
- Dedicated Einherjar variants per kind (use `einherjar_overlay` + the kind's sprite, or the `einherjar` hero).

## Round 2 of the owner's art review (Nov 7, 2026)
- Bust boxes refit from the sprites: `seer` (under the collar), `sigrun` (the breastplate, rows 36-43) and `valkyrie` (the chest under the winged helm, rows 23-28); `player/rune_seer` and `player/shield_maiden_hero` boxes 4 px further right. All idle and walk strips rebuilt; sheets in `docs/last_acts/bust_check/`.
- `draugr_female`: no bust rig any more, a plain walk, **the idle strip is deleted** (code falls back to the still, as for every unit without a strip).
- `sigrun` and `valkyrie`: the wings flap in walk and idle (`wings` rig entries; Sigrun's spear and shield stay fixed). `fenrir_walk`: the broken chain on his neck and the loose end under his jaw swing (brown pixels only, `pendulums`).
- `brazier_lit_anim.png` / `brazier_doused_anim.png` (32x32 frames, 8 side by side, 8 fps loop, frame 0 = the still; `art_source/norse/r2_props.py`): flames that flicker and sway, a smoke wisp that drifts. **Code:** play them like any strip, frame = int(game_time * 8) mod 8, drawing region `Rect2(32 * frame, 0, 32, 32)` of `norse/brazier_lit_anim` / `norse/brazier_doused_anim`; the stills stay the fallback. Nothing plays them yet (LongWinter still draws the still).
