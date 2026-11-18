# Missing art audit (Nov 2026)

Owner ask: "Check for any effects, characters, or stage effects that don't currently have art assets. Just want to be
sure nothing looks too cheesy." Audit only: no art was made, no gameplay and no default autotest output changed.

**Status: WIP.** The static pass (data tables + code grep) is in; the runtime pass (every stage once) is being merged.

## Method

1. **Static.** Every enemy kind in every `*_enemy_data.gd` table was resolved through `Glyphs.draw_enemy()`'s lookup (16
   sprite folders) plus each kit's own key (`wears`, `*_SPRITE` constants). Bosses, summon classes and evolutions, the 54
   characters and their skins, icons (passives, spells, evolutions, relics, offerings, ultimates, synergies,
   achievements), projectile kinds, obstacle kind x size per stage and every literal sprite key in `scripts/` were checked
   against `assets/sprites/**.png`. Orphan check: PNGs no script mentions.
2. **Code-only effects.** `_draw` code in enemy kits, bosses, stage directors, hazards and spells was grepped for primitive
   drawing (`draw_circle/arc/polygon/line/rect`) with no `SpriteBank` / `AoeArt` / `EmpireFx` attempt, then read.
3. **Runtime.** `--art-misses` (already in the repo) records every sprite key a run looks up and finds no PNG for. It
   prints nothing under `--headless` (headless skips `_draw`), but it works in a window: the runs used `xvfb-run` +
   `--rendering-driver opengl3` (Mesa llvmpipe), `--autotest --stage=<id> --seed=7 --policy=army --art-misses`. Enemy
   lookups probe 16 folders in turn, so a kind served by one folder (or by its own kit key) logs 15 "misses"; those probes
   were filtered out and kinds are classified by the static pass.

## Most noticeable (top 10)

1. **Divine Wrath** (Ilion, Olympus, Underworld; Zeus / Poseidon / Hades fights): the tidal wave is a flat blue polygon with
   a line edge, the lightning warning is concentric circles. No Pantheon AoE art (the Empire has `EmpireFx`, Act I-III have
   `AoeArt`). The act's signature rule.
2. **Hallowed Light shafts** (Silver Stair, Wheel of Thrones, Empyrean; Seraiel, the Throne, the Voice): plain translucent
   rectangles. `fx/host_shaft`, `host_shaft_line`, `host_trumpet_ring` exist but no script loads them.
3. **Vigrid obstacles** (`norse_boulder`, `norse_ash_rock`, Zones I-II of the Hall's finale): stacked flat discs; they are
   most of the map's furniture. No `obstacles/norse_*` PNG.
4. **Act-spell effects** (Stolen Thunder, Paris's Arrow, River Styx, Linen Bind; Death Ray's fallback): zigzag lines, a line
   with a triangle head, thick black lines. The player sees these all run.
5. **Seasonal fronts** (Wild: wildfire front, blizzard veil, snow and leaves; Greenwood, Fae Court, World-Tree): flat rects /
   gradient. Seven `fx/wild_*` strips exist, unwired.
6. **Stampede dust fronts, volcanic bomb burst, Fossil Giant rise** (Age of Titans): rects and discs. Four
   `fx/primeval_*` PNGs exist, unwired.
7. **Hyper skins for 20 characters and Untouchable / Deathlord for 18** (the Act II-XV characters): a palette tint of the base
   sprite plus a code emblem / aura, not a drawn skin.
8. **Holmgang ring** (Valgard, Sigrun's duel): a rectangle of rod rects.
9. **Cursed Coin** (Treasure Galleon, Marrec's gold): a brass disc ("no coin sprite" in the kit).
10. **Soul Siphon / Soul Rapture tethers** (a core starting-pool spell): sine polylines with dots (reads fine, still the
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

Projectile kinds (12 of 12) all have art. Art exists but is **not wired** (no script loads the key, so the old code drawing
still shows):

| Key | Intended for | Currently drawn as | Visibility | Fix |
|---|---|---|---|---|
| `fx/host_shaft`, `host_shaft_line`, `host_trumpet_ring` | Hallowed Light shaft, its telegraph, the Herald's blast ring | rects / disc in `hallowed_light.gd` and the Herald kit | high (boss attacks) | wire (`draw_flat` tiled along the shaft) |
| `fx/wild_smoke_line`, `wild_fire_front`, `wild_blizzard`, `wild_snowfall`, `wild_leaves`, `wild_thicket_burn`, `wild_bury` | wildfire front and its warning, blizzard veil, seasonal particles, thicket burning, buried summons | rects / gradient in `season_cycle.gd` and the Wild kits | high on the Wild stages | wire |
| `fx/primeval_dust_line`, `primeval_dust_front`, `primeval_bomb_burst`, `primeval_fossil_rise` | stampede line and dust front, volcanic bomb, Fossil Giant rise | rect / discs / ring | medium-high | wire |
| `norse/einherjar_overlay`, `norse/valkyrie_shadow` | Einherjar aura, valkyrie dive shadow | code ring / ellipse | low-medium | wire |
| `primeval/primeval_nest_dead`, `primeval/stormwing_landed` | dead nest, landed Stormwing | the live sprite | low | wire |
| `dynasty/mummy_b`, `icons/inglorious` | unused leftovers | n/a | none | delete or ignore |

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
| Vertical rect variants (`_v`) missing: Archive (`bookshelf`, `blank_shelf`, `toppled_shelf`, `reading_desk`, `chart_table`), Necropolis `dyn_tomb`, Spire `toppled_arch`, Galleon `galleon_steps_m` | those stages | a vertical long obstacle falls back to the code rect glyph | medium (only vertical placements) | add `_v` strips |
| Old-style single sprites without size variants: `stone_lantern_m` (Province, Kurogane, Sun Road), `dyn_brazier_m`, `dyn_great_scales_m` | Shogunate, Two Truths | handled by `SINGLE_ART` / one sprite; no gap | none | none |
| Sinking island sea (`sinking_director.gd`) | Ul-Thalos | code water, flood band, foam | medium | tile / edge art |
| Olympus moon groves, Spire dream-pillar aura | Olympus, Ul-Thalos | circles and arcs | low | none |

## Icons and UI

| Thing | Where | Looks now | Visibility | Fix |
|---|---|---|---|---|
| Passive icons `fur_lined_bones`, `cold_iron` | level-up cards, HUD, codex | code icon glyph | medium (shown on every offer of an Act XV-era counter passive) | two badges |
| Achievement badges `mass_grave`, `untouchable`, `full_ossuary`, `deathlords_due`, `swift_judgment`, `keep_the_fires`, `holmgang`, `twilight_of_the_wolf` | Codex Achievements | the matching spell / passive icon (`raise_dead`, `warding_ritual`, ...) | low | 8 `ach_*` badges |
| Closing cards and epilogue panels | after each act's epilogue | every referenced panel exists (`epilogue/*`) | none | none |
| `decals/spire_breakwater_barnacles` | main-menu stage vignette | missing decal slot in `FrontDoorData` | low | one decal |
| Relics (15), offerings (6), ultimates (4), synergies (14), spells (54 incl. evolutions), titles (text only) | | all present | none | none |

## Runtime pass results

Pending.
