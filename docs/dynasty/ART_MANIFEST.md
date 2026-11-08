# The Necropolis Dynasty: art and audio manifest

Branch `dynasty-art` (Act VII slot, stage key `dynasty`; GDD §15.0 "The Necropolis Dynasty art and audio"). Rebuild: `art_source/dynasty/` (`gen_prompts.py`, `gen_sheets.py`, `make_art.py`, `make_props.py`, `dynasty_tiles.py`; raw API images in `raw/` and `sheet_*.png`, prompts beside them).
All sprites are true pixel art, 1 art px = 1 screen px, drawn at the heights in `SpriteData.HEIGHTS` (block "Act VII slot: the Necropolis Dynasty"). Strips: `<id>_walk.png` = 8 frames side by side, `<id>_idle.png` = 24 frames (every female figure; bust rigs in `tools/walk_cycle.py`). Every female figure is in the figure-redesign style, fully clothed.

## Palette ramps (`tools/palette.json`, faction set `dynasty` in `prepare_sprite.py`)

| Ramp | Colours (dark to light; ink first) | Use |
|---|---|---|
| `night` | `#0A0B16`, `#1B2038`, `#2E3660`, `#4B5894` | the Dynasty's blue-black night (Act VII slot): Anubis, jackal warriors, Bastet, Ammit; also the act's ink |
| `dyn_bronze` (renamed from `bronze` at the wave 1 integration: Act IV owns the `bronze` ramp) | `#0A0B16`, `#6B5A22`, `#A38E3C`, `#D2BB62` | the Dynasty's DULL bronze-gold: enemy collars, bands, blades (true gold stays the player's reward colour) |
| `lapis` | `#0A0B16`, `#16327C`, `#2B54B8`, `#5F8BE6` | lapis blue: scarabs, headcloth stripes, inlay |
| `sand` | `#0A0B16`, `#8C6B3E`, `#D2B574`, `#F0DDA6` | sandstone: statues, the colossus, tombs, obelisks, columns |
| `linen` | `#0A0B16`, `#8F8670`, `#C9C0A4`, `#F0E8D2` | linen: mummy wrappings, dresses, kilts, Osiris's robe |
| `carnelian` | `#0A0B16`, `#7B1E16`, `#BF3B2B`, `#E87855` | carnelian red: Sekhmet, belts, gems, the sun disc |
| `papyrus` | `#0A0B16`, `#285A30`, `#4E8F40`, `#8CC45E` | papyrus green: the crocodile warden, Osiris, reeds |
| `dynskin` | `#0A0B16`, `#5A3622`, `#8A5430`, `#B87C48` | the Dynasty's skin tones (its own ramp: the Covenant `skin` is a pale peach) |

Palette constants for `palette.gd` (names `DYN_*`): ink `#0A0B16`; night `#1B2038 #2E3660 #4B5894`; bronze (DULL, enemies; true gold stays the player's) `#6B5A22 #A38E3C #D2BB62`; lapis `#16327C #2B54B8 #5F8BE6`; sand `#8C6B3E #D2B574 #F0DDA6`; linen `#8F8670 #C9C0A4 #F0E8D2`; carnelian `#7B1E16 #BF3B2B #E87855`; papyrus `#285A30 #4E8F40 #8CC45E`; skin `#5A3622 #8A5430 #B87C48`.

## Units, bosses, characters, summons (`assets/sprites/dynasty/<id>.png`, + `_walk` / `_idle`)

| Key | Size (art px) | What it is | Strips |
|---|---|---|---|
| `dynasty/mummy` | 28x40 | male fodder | walk; Rebirth; legs walk |
| `dynasty/mummy_female` | 24x40 | female fodder (figure style) | walk, idle; bust rig + idle |
| `dynasty/scarab_swarm` | 34x38 | creature swarm fodder (no Rebirth) | walk |
| `dynasty/khopesh_guard` | 28x46 | male soldier | walk |
| `dynasty/nile_archer` | 32x44 | female ranged (figure style) | walk, idle; robe glide, bust + idle |
| `dynasty/heka_priest` | 36x46 | male support; the gold glyph staff uses true gold | walk |
| `dynasty/embalmer` | 22x44 | female support (figure style) | walk, idle; bust + idle |
| `dynasty/jackal_warrior` | 30x48 | male elite, jackal head | walk |
| `dynasty/bastet_hunter` | 28x44 | female elite (figure style), cat mask | walk, idle; bust + idle |
| `dynasty/crocodile_warden` | 36x50 | male heavy, rises from sand | walk |
| `dynasty/ushabti_statue` | 20x46 | stone servant statue (no sex) | walk |
| `dynasty/canopic_jar` | 18x30 | structure; holds the Names (no strip) | none; still only |
| `dynasty/canopic_jar_dead` | 32x26 | the broken jar (no strip) | none; still only |
| `dynasty/sand_colossus` | 44x84 | miniboss kind: huge sandstone statue | walk |
| `dynasty/lion_warden` | 60x80 | Temple miniboss, male stone warrior | walk |
| `dynasty/devourers_whelp` | 60x36 | Hall of Two Truths miniboss, a creature | walk |
| `dynasty/anubis` | 56x90 | boss, male jackal-headed god | walk |
| `dynasty/sekhmet` | 52x92 | boss, female goddess (figure style) | walk, idle; robe glide, bust + idle |
| `dynasty/osiris` | 46x96 | boss, male god on his throne (no strip; stationary) | none; still only |
| `dynasty/ammit` | 76x44 | boss, monster (Ammit the Devourer) | walk; legs walk |
| `dynasty/ushabti_sentinel` | 20x46 | finale summon class (the necromancer's, soul-teal eyes) | walk |
| `dynasty/eternal_guard` | 32x58 | its evolution (true-gold trim) | walk |

Boss attack poses (cast / strike) are not drawn: the stage agents add them (BossPoseData) once the kits exist. 

## Playable characters (`assets/sprites/player/`, redone Nov 2026 to the game's convention: violet necromancers of the act's theme, bone and soul-teal accents, a casting focus, 56 px tall)

| Key | Size | What | Strips |
|---|---|---|---|
| `player/the_embalmer` | 32x56 | female (figure style): violet linen robe with bandage wraps, canopic-jar staff (spell Linen Bind, Anubis) | walk, idle (bust rig) |
| `player/lion_priestess` | 38x56 | female (figure style): violet priestess dress, lioness-head hood, sun-disc staff (Burning Eye, Sekhmet) | walk, idle (bust rig) |
| `player/pharaohs_shade` | 40x56 | male: violet-robed spectral pharaoh, nemes, crook staff with a soul flame (Feather's Verdict, Osiris) | walk |

Source: `art_source/dynasty/gen_chars.py` (raws in `chars/`). The earlier enemy-styled versions in `dynasty/` were removed.

## World markers

| Key | Size | What |
|---|---|---|
| `markers/dyn_cartouche` | 12x20 | the gold cartouche over a fallen body (Rebirth) (true gold: a mechanic marker) |
| `markers/dyn_heka_glyph` | 16x16 | the gold Heka glyph sigil over a cursed summon (true gold: a mechanic marker) |

## Icons (`assets/sprites/icons/<id>.png`, 32x32 badges on the approved frames: violet = spells / passives / counter-passives / classes, gold = evolutions and achievements)

| Id | What |
|---|---|
| `icons/linen_bind` | spell: Linen Bind |
| `icons/burning_eye` | spell: Burning Eye |
| `icons/feathers_verdict` | spell: Feather's Verdict |
| `icons/eternal_shroud` | evolution of Linen Bind |
| `icons/eye_of_retribution` | evolution of Burning Eye |
| `icons/heart_devoured` | evolution of Feather's Verdict |
| `icons/natron_salts` | paired passive of Linen Bind |
| `icons/desert_fury` | paired passive of Burning Eye |
| `icons/heavy_heart` | paired passive of Feather's Verdict |
| `icons/embalmed_bones` | counter-passive |
| `icons/dune_walkers` | counter-passive |
| `icons/ach_names_taken` | achievement Names Taken |
| `icons/ach_no_jars_left` | achievement No Jars Left |
| `icons/ach_a_light_heart` | achievement A Light Heart |
| `icons/ushabti_sentinel` | summon class icon |
| `icons/eternal_guard` | its evolution icon |

## Obstacles (`assets/sprites/obstacles/`; rect kinds also have `_v`, turned 90 degrees)

| Key | Size | What |
|---|---|---|
| `obstacles/dyn_tomb_s` | 30x27 | small rock-cut tomb |
| `obstacles/dyn_tomb_l` | 44x29 | large mortuary mastaba |
| `obstacles/dyn_obelisk_s` | 16x43 | small obelisk |
| `obstacles/dyn_obelisk_l` | 20x52 | tall obelisk |
| `obstacles/dyn_statue_row_s` | 36x34 | row of 3 dormant ushabti statues (the ones that wake) + _v |
| `obstacles/dyn_statue_row_l` | 56x38 | row of 5 dormant statues + _v |
| `obstacles/dyn_colonnade_s` | 44x39 | short colonnade + _v |
| `obstacles/dyn_colonnade_l` | 72x49 | long colonnade + _v |
| `obstacles/dyn_great_scales` | 66x75 | the great Scales of the hall (stage 21 set piece) |
| `obstacles/dyn_brazier` | 20x44 | stone brazier with fire |
| `obstacles/dyn_sphinx_head_m` | 36x29 | half-buried sphinx head (`_m`: a one-size kind, EnvironmentArtData; renamed in phase 2) |
| `obstacles/dyn_sandstone_blocks_m` | 36x31 | broken blocks and a snapped column (`_m`, renamed in phase 2) |

## Floors (`assets/sprites/tiles/`, 128x128 seamless, dark and flat; drawn by `dynasty_tiles.py`)

| Key | What |
|---|---|
| `tiles/necropolis_dunes` | Necropolis zone 1: wind-rippled dunes |
| `tiles/necropolis_tomb_road` | zone 2: tomb-road paving |
| `tiles/necropolis_sandstorm_pass` | zone 3: pebbled pass |
| `tiles/necropolis_mortuary_temple` | zone 4: temple flagstones, lapis inlay |
| `tiles/lioness_temple_avenue` | Temple zone 1: processional slabs, bronze inlay |
| `tiles/lioness_temple_courtyard` | zone 2: checker court |
| `tiles/lioness_temple_hypostyle` | zone 3: dark slabs, glyph dashes |
| `tiles/lioness_temple_sanctuary` | zone 4: red-tinted slabs, a faint sun ring |
| `tiles/two_truths_reeds` | Hall zone 1: Gate of Reeds, reed mud |
| `tiles/two_truths_fire` | zone 2: River of Fire, basalt with glowing cracks |
| `tiles/two_truths_scales` | zone 3: Hall of the Scales, blue-black marble |
| `tiles/two_truths_throne` | zone 4: Throne of Osiris, night-blue slabs, bronze inlay |
| `tiles/dynasty_quicksand` | quicksand patch (TerrainSlow): golden concentric ripples, lighter than the floors |

## Audio

- Music `weighing`, score `SoundData.WEIGHING_SCORE` "The Weighing of the Heart" (24 s, G Hijaz: maqsum frame drums via `machine`, reed drone via `organ`, ney melody via `flute`, sistrum via `hits`, a low swell via `horn`; only existing synth jobs). `SoundData.SCORES["weighing"]`, `SCORE_PACKS["weighing"] = "dynasty"`, `Sfx.SCORE_SEEDS["weighing"] = SYNTH_SEED - 12`, `Sfx.MUSIC_WEIGHING`. The stage's `"music"` key must be `weighing`.
- Sound pack `SoundData.DYNASTY_SOUNDS` (lazy with the score, `Sfx.PACK_SEED_OFFSETS["dynasty"] = 9000`): `cartouche_chime`, `rebirth_groan`, `sandstorm`, `jar_shatter`, `scarab_swarm`, `heka_glyph`. Nothing plays them yet; the stage agents wire the sound map.
- Not rendered or listened to (no Godot allowed here beyond the import); the owner should hear the loop.

## Cost

About $0.57 of API images (25 unit images, 7 sheets; medium quality), ledger rows tagged `dynasty/...` in `docs/art/generation_ledger.csv`.

## Round 2 of the owner's art review (Nov 7, 2026)
- Bust boxes refit: `bastet_hunter` (the cream chest, rows 12-16), `embalmer` (cols 9-15, rows 11-16), `mummy_female` (rows 10-15); `player/the_embalmer` box 4 px further right. Idle and walk strips rebuilt; sheets in `docs/last_acts/bust_check/`.
- Redrawn (prompts and raw images: `art_source/dynasty/r2/`, `gen.py`): `khopesh_guard` (a real khopesh: straight grip, hooked sickle blade), `mummy` (28 -> 36x40: wrapped head to toe, arms forward, hunched, trailing bandages, faint green eyes), `ushabti_sentinel` (a clean mummiform stone shabti, striped headdress, hieroglyph bands in lapis and dull gold, soul-teal eyes; still 20x46, the height `SpriteData` has), `player/lion_priestess` (a cream lioness head-dress with round ears and fangs over a violet mane, 34x56, violet and bone, box on the chest: cols 13-23, rows 20-26). Walk strips rebuilt (new hips in `walk_cycle.py`); `ushabti_sentinel` ramps now grey, lapis, dyn_bronze, soul, sand (`make_art.py`).
