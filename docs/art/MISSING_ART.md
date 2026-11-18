# Missing art audit (Nov 2026)

Owner ask: "Check for any effects, characters, or stage effects that don't currently have art assets. Just want to be
sure nothing looks too cheesy." Audit only: no art was made, no gameplay and no default autotest output changed.

**Status: complete.** Static pass, code-effect pass and a runtime pass over all 45 stages (seed 7, army policy). The runtime pass
confirmed the static findings and added the floor decals, the scribe's curse sigil and the Maelstrom wheel.

## Method

1. **Static.** Every enemy kind in every `*_enemy_data.gd` table was resolved through `Glyphs.draw_enemy()`'s lookup (16
   sprite folders) plus each kit's own key (`wears`, `*_SPRITE` constants). Bosses, summon classes and evolutions, the 54
   characters and their skins, icons (passives, spells, evolutions, relics, offerings, ultimates, synergies,
   achievements), projectile kinds, obstacle kind x size per stage and every literal sprite key in `scripts/` were checked
   against `assets/sprites/**.png`. Orphan check: PNGs no script mentions.
2. **Code-only effects.** `_draw` code in enemy kits, bosses, stage directors, hazards and spells was grepped for primitive
   drawing (`draw_circle/arc/polygon/line/rect`) with no `SpriteBank` / `AoeArt` / `EmpireFx` attempt, then read.
3. **Runtime.** `--art-misses` (already in the repo, no code change needed here) records every sprite key a run looks up and finds no PNG for. It
   prints nothing under `--headless` (headless skips `_draw`), but it works in a window: the runs used `xvfb-run` +
   `--rendering-driver opengl3` (Mesa llvmpipe), `--autotest --stage=<id> --seed=7 --policy=army --art-misses`. Enemy
   lookups probe 16 folders in turn, so a kind served by one folder (or by its own kit key) logs 15 "misses"; those probes
   were filtered out and kinds are classified by the static pass. All 45 stages ran to the end with no `SCRIPT ERROR`.
   Coverage limit: a run only meets what its bot meets (one seed, army policy, no naive / spell-only builds), so effects
   of spells and events a run never reached come from the static pass only.

## Most noticeable (top list)

1. **Divine Wrath** (Ilion, Olympus, Underworld; Zeus / Poseidon / Hades fights): the tidal wave is a flat blue polygon with
   a line edge, the lightning warning is concentric circles. No Pantheon AoE art (the Empire has `EmpireFx`, Act I-III have
   `AoeArt`). The act's signature rule.
2. ~~**Hallowed Light shafts** (Silver Stair, Wheel of Thrones, Empyrean; Seraiel, the Throne, the Voice): plain translucent
   rectangles. `fx/host_shaft`, `host_shaft_line`, `host_trumpet_ring` exist but no script loads them.~~ **Done** (Nov 2026,
   GDD §15.0 "Unwired art hooked up").
3. **Vigrid obstacles** (`norse_boulder` x2 sizes, `norse_ash_rock` x3 sizes, Zones I-II of the Hall's finale): stacked flat
   discs; they are most of the map's furniture (~3,700 draws a run). No `obstacles/norse_*` PNG. Also the Maelstrom's
   `maelstrom_wheel_m` obstacle (339 draws) is a code glyph.
4. **Scribe's curse sigil** (`markers/scribe_curse`, Archive and Ul-Thalos): the ink sigil over every cursed cultist is an arc
   (480,000 lookups in one Archive run); the Archive is the sharpest-difficulty stage and the sigil is on screen constantly.
   Same for `markers/inscription` (Forbidden Verse mark).
5. **Act-spell effects** (Stolen Thunder, Paris's Arrow, River Styx, Linen Bind; Death Ray's fallback): zigzag lines, a line
   with a triangle head, thick black lines. The player sees these all run.
6. ~~**Seasonal fronts** (Wild: wildfire front, blizzard veil, snow and leaves; Greenwood, Fae Court, World-Tree): flat rects /
   gradient. Seven `fx/wild_*` strips exist, unwired.~~ **Done** (Nov 2026, GDD §15.0 "Unwired art hooked up").
7. ~~**Stampede dust fronts, volcanic bomb burst, Fossil Giant rise** (Age of Titans): rects and discs. Four
   `fx/primeval_*` PNGs exist, unwired.~~ **Done** (Nov 2026, GDD §15.0 "Unwired art hooked up").
8. **Hyper skins for 20 characters and Untouchable / Deathlord for 18** (the Act II-XV characters): a palette tint of the base
   sprite plus a code emblem / aura, not a drawn skin.
9. **Floor decals** (Archive x4, Citadel x3, Ul-Thalos x16 `decals/*`): the hashed floor scatter stays the old code
    dressing instead of pixel decals on those three stages; every other stage's floor tiles and decals are present.
10. **Holmgang ring** (Valgard, Sigrun's duel): a rectangle of rod rects.
11. **Cursed Coin** (Treasure Galleon, Marrec's gold): a brass disc ("no coin sprite" in the kit).
12. **Soul Siphon / Soul Rapture tethers** (a core starting-pool spell): sine polylines with dots (reads fine, still the
    plainest of the core spells). Also: two passive icons (`fur_lined_bones`, `cold_iron`) and eight achievement badges still
    use a reused or code icon.

(Runtime additions are merged below when the stage runs finish.)

## Characters and skins

Counts: 54 playable characters, all with a still and a walk strip; 30 with an idle breathing strip (by design only the
female bust rigs have one).

| Thing | Where it appears | Looks now | Visibility | Suggested fix |
|---|---|---|---|---|
| Hyper skin x20: `brine_widow`, `heretic_scribe`, `marooned_quartermaster`, `corsair_queen`, `ghost_helmsman`, `rune_seer`, `shield_maiden_hero`, `berserker_hero`, `the_embalmer`, `lion_priestess`, `pharaohs_shade`, `fallen_herald`, `blind_saint`, `the_unveiled`, `fern_huntress`, `herd_warden`, `skywatcher`, `horned_herald`, `changeling_princess`, `gravegardener` | pre-run skin picker, in-run sprite on Hyper | tinted reuse (`HYPER_TINTS` multiply + gold corona emblem on the base sprite) | medium | `player/<id>_hyper.png` (the other 34 have one) |
| Untouchable skin x18 and Deathlord skin x18 (the Hyper list above minus `brine_widow` and `heretic_scribe`, which have them) | skin picker, in-run | tinted reuse (over-bright multiply, alpha 0.78; near-black iron tint + crown emblem) | low-medium | one `<id>_untouchable` / `_deathlord` each, or accept the tint (the 36 older ones have art) |
| Casket recolours (bone, blood, abyss, gilded, verdant) | any unit through `SpriteBank.draw(recolour)` | palette swap of existing art, by design | low | none |
| `CASKET_SKINS` | nothing yet (`{}`) | not built | none | future work, no art needed now |

## Enemies and bosses

Counts: 289 enemy rows across 59 tables. 259 have a PNG in a probe folder; the other 30 are all served by other art (kit
key, borrowed `wears` sprite, tinted reuse of a boss / summon / soldier, braziers and rockets with their own folders)
except one code disc. All 45 boss stills exist;
bosses have attack-pose strips only where `boss_pose_data.gd` lists them (optional).

| Thing | Where | Looks now | Visibility | Suggested fix |
|---|---|---|---|---|
| `cursed_coin` | Treasure Galleon (Marrec) | code disc (brass, ink rim, glow) | medium | coin sprite, 2-frame spin |
| Tinted reuse, intentional: `kage_clone` (Kage), `fox_fire` (Kitsune), `kestrel_decoy` (Kestrel), `archivist_copy` (Archivist), `woken_colossus` (Sand Colossus), `charmed` (the charmed summon), `drowned_thrall`, `shade_hoplite` / `tartarus_warden` (Hoplite), `blood_bearer` (Blood Thrall), `ghost_deckhand` / `ghost_gunner` (`GhostCrewKit` spectre tint of the crew), `wine_jar` (Canopic Jar, wine red) | various | the donor sprite with a tint / flicker; reads as a deliberate variant | low | none needed; own sprites only if the owner wants them to read as different creatures |
| `cerberus_head` | Underworld | invisible by design (the body sprite carries the heads) | none | none |
| Boss walk strips absent: `merrow`, `archivist`, `vhalneth`, `motherboard`, `deus_ex_machina`, `osiris` | their stages | still only (they stand or hover) | low | none unless they move |

## Summons

31 offerable classes and 29 evolutions: **all have a still, a walk strip** (`profane_bishop` draws as `bishop` by design);
all but `bishop` have an icon. No gaps.

## Effects, projectiles and spells

Projectile kinds (12 of 12) all have art. Art that existed but was **not wired** (no script loaded the key, so the old code
drawing showed). **All wired in Nov 2026** (GDD §15.0 "Unwired art hooked up"; the code drawing stays the fallback) except the
two leftovers in the last row:

| Key | Intended for | Currently drawn as | Visibility | Fix |
|---|---|---|---|---|
| `fx/host_shaft`, `host_shaft_line`, `host_trumpet_ring` | Hallowed Light shaft, its telegraph, the Herald's blast ring | rects / disc in `hallowed_light.gd` and the Herald kit | high (boss attacks) | **done**: `SpriteBank.draw_band()` over each shaft and line (additive), the ring's frames over the Herald's windup |
| `fx/wild_smoke_line`, `wild_fire_front`, `wild_blizzard`, `wild_snowfall`, `wild_leaves`, `wild_thicket_burn`, `wild_bury` | wildfire front and its warning, blizzard veil, seasonal particles, thicket burning, buried summons | rects / gradient in `season_cycle.gd` and the Wild kits | high on the Wild stages | **done**: bands for the front and line, the art over the blizzard veil, snow / leaves tiled over the view (Full effects), bursts for the burn and the burial |
| `fx/primeval_dust_line`, `primeval_dust_front`, `primeval_bomb_burst`, `primeval_fossil_rise` | stampede line and dust front, volcanic bomb, Fossil Giant rise | rect / discs / ring | medium-high | **done**: bands for the front and line, the bomb's burst, the Fossil Giant's rise through `Herds`' ring |
| `norse/einherjar_overlay`, `norse/valkyrie_shadow` | Einherjar aura, valkyrie dive shadow | code ring / ellipse | low-medium | **done**: the gold light's art; the shadow on a valkyrie's landing mark while she dives |
| `primeval/primeval_nest_dead`, `primeval/stormwing_landed` | dead nest, landed Stormwing | the live sprite | low | **done**: the remains where the nest fell; the Stormwing's body while landed |
| `dynasty/mummy_b`, `icons/inglorious` | unused leftovers | n/a | none | **left unwired**: the old 28 x 40 mummy (replaced by `mummy`) and the dropped counter-passive Inglorious (Calm Blood took its place); nothing shows them |

Code-only effects that stand in for an object or effect (the player would expect art):

| Effect | Where | Looks now | Visibility | Fix |
|---|---|---|---|---|
| Divine Wrath wave and lightning (`divine_wrath.gd`) | Ilion, Olympus, Underworld | water polygon + lines, concentric circle telegraph | high | Pantheon AoE strips (wave front, bolt flash, ground ring), like `EmpireFx` |
| Stolen Thunder arcs (`stolen_thunder.gd`) | Olympus spell (Zeus) | zigzag lines, circle charge orb | medium-high | bolt strips |
| Paris's Arrow (`paris_arrow.gd`) | Ilion spell | line trail, triangle head | medium | arrow + trail sprite |
| River Styx (`river_styx.gd`) | Underworld spell | black line with drift ticks | medium | river-strip tile |
| Linen Bind (`linen_bind.gd`) | Necropolis spell | thin lines and 3 rects per marked enemy | medium | bandage wrap sprite |
| Soul Siphon / Soul Rapture tether (`spell_glyphs.gd`) | core spell | sine polyline + dots | medium | tether strip (fine as is) |
| Death Ray fallback | Wastes | only if `EmpireFx.death_ray` lacks art (it has it) | none | none |
| Holmgang ring (`holmgang.gd`) | Valgard, Sigrun | rect of rods + rope lines | medium | ring sprite |
| Phalanx shield bar, legionary shield, hero Glory ring, Poseidon trident | Pantheon | lines / rects drawn over the sprite | medium | shield-front sprite |
| Lock-On painted lines, orbital / dead-zone rings (Empire) | Act XII | lines and rings (the strikes use `EmpireFx`) | low | none |
| Siren / Spire pillar / grove rings, Siege tower rings | Eye / Pantheon | telegraph rings and auras | low | none (intentional rings) |

Intentional primitive shapes (telegraph rings and wedges, range circles, HP and Judgment / Scales bars, debug) are not
listed.

## Stage effects, floors and obstacles

| Thing | Where | Looks now | Visibility | Fix |
|---|---|---|---|---|
| `norse_boulder`, `norse_ash_rock` obstacles | Vigrid, zones I-II | stacked flat discs (`NorseGlyphs`) | high | `obstacles/norse_boulder_s/_l`, `norse_ash_rock_s/_m/_l` |
| Floor decals (`decals/<stage>_<zone>_<kind>`): Archive `archive_halls_pages`, `archive_orrery_star`, `archive_stacks_pages`, `archive_wells_stain`; Citadel `citadel_courts_scorch`, `citadel_gates_plate`, `citadel_lifts_hazard`; Ul-Thalos `spire_{breakwater,gate,spire,steps}_{barnacles,bones,glyph,kelp}` (16) | Archive, Iron Citadel, Ul-Thalos | the old hashed code decoration (small shapes) on a pixel tile floor | medium (the floor is under every frame; they are small) | 23 small decals; Ul-Thalos first (16 of them) |
| `maelstrom_wheel_m` obstacle | the Maelstrom | `CorsairGlyphs` code wheel (rect / disc) | medium | one obstacle PNG |
| Vertical rect variants (`_v`) missing: Archive (`bookshelf`, `blank_shelf`, `toppled_shelf`, `reading_desk`, `chart_table`; not met in the run, still true by the stage tables), Necropolis `dyn_tomb`, Ul-Thalos `toppled_arch` (met: 96 draws), Galleon `galleon_steps_m` (met: 355 draws) | those stages | a vertical long obstacle falls back to the code rect glyph | medium (only vertical placements) | add `_v` strips |
| `dyn_brazier_m`, `dyn_great_scales_m`, `stone_lantern_m` lookups | Temple, Two Truths, Shogunate | logged as misses but answered by the single-sprite rule (`SINGLE_ART` / `stone_lantern`); no gap | none | none |
| Sinking island sea (`sinking_director.gd`) | Ul-Thalos | code water, flood band, foam | medium | tile / edge art |
| Olympus moon groves, Spire dream-pillar aura | Olympus, Ul-Thalos | circles and arcs | low | none |

## Icons and UI

| Thing | Where | Looks now | Visibility | Fix |
|---|---|---|---|---|
| Passive icons `fur_lined_bones`, `cold_iron` | level-up cards, HUD, codex | code icon glyph | medium (shown on every offer of an Act XV-era counter passive) | two badges |
| Achievement badges `mass_grave`, `untouchable`, `full_ossuary`, `deathlords_due`, `swift_judgment`, `keep_the_fires`, `holmgang`, `twilight_of_the_wolf` | Codex Achievements | the matching spell / passive icon (`raise_dead`, `warding_ritual`, ...) | low | 8 `ach_*` badges |
| `markers/scribe_curse`, `markers/inscription` | Archive / Ul-Thalos world markers on cursed and inscribed enemies | code arc / glyph | high (Archive) | two small marker PNGs |
| Closing cards and epilogue panels | after each act's epilogue | every referenced panel exists (`epilogue/*`) | none | none |
| `decals/spire_breakwater_barnacles` | main-menu stage vignette | missing decal slot in `FrontDoorData` | low | one decal |
| Relics (15), offerings (6), ultimates (4), synergies (14), spells (54 incl. evolutions), titles (text only) | | all present | none | none |

## Runtime pass results

All 45 stages (seed 7, army policy, `--art-misses`, 640x360 window under Xvfb). After dropping the enemy-folder probes:

- **Missing and drawn by a code fallback:** the 23 decals, 1 marker (`scribe_curse`; `inscription` is static-only), 6 obstacle
  keys (`norse_boulder` s/l, `norse_ash_rock` s/m/l, `maelstrom_wheel_m`) and the two `_v` variants listed above.
  `bosses/ares`, `bosses/artemis` are first-choice keys of Hades' god shades (the `pantheon/` art answers them).
  Graveyard, Crimson March, Sanctum, Cutter, Galleon-minus-`galleon_steps_m_v`, Harbour, Ravensmoor, Witchwood, Castle
  Sanguis, Province, Kurogane, Sun Road, Barrow Fields, Valgard, Necropolis, Temple, Two Truths, Ilion, Olympus, Underworld,
  Burning Gate, Silk Palace, Pandemonium, the three Celestial Host stages, the Concord stages, the Age of Titans stages and
  the Turning Year stages: **zero missing sprite keys** beyond the probes.
- **Grid-art bodies drawn without a walk strip** (they slide as a still): mostly stationary things (structures, turrets,
  pylons, braziers, jars, thrones, egg, siege tower) and bosses that hover (Archivist, Vhal'Neth, Deus Ex Machina, Motherboard,
  Osiris, Merrow). Movers worth a look: **Gibbering Mass / Lesser / Least** (`eye/gibbering_*`, Archive and Ul-Thalos, ~56,000
  draws, they crawl at 36 px/s), `eye/unwritten_one`, `eye/librarian`, `host/ophan` (Wheel of Thrones, Empyrean; floats),
  `wild/corpse_bloom`, `norse/boss_barrow`. Cosmetic only; the gibbering masses are the visible ones.
