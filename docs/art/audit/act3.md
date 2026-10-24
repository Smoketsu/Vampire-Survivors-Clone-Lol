# Act III art audit: the Electronic Empire

Audit only, no art and no code changes (Oct 2026, branch `audit/act3-art`, base `integration` at `3227eea`).
Owner report: "placeholder graphics in places, check every act". Scope: the Scrap Wastes, the Assembly Halls, the
Iron Citadel, the Empire's shared rules (Line of Fire, Lock-On, Purge Protocol), every Empire kind, the three bosses,
the Act III spells / classes / characters, floors, obstacles, the stage cards.

## How it was checked

1. **Static.** Every `_draw()` / `draw_over()` / `draw_under()` / glyph function in scope was read (files named in the
   table), plus every `SpriteBank` / `EnvironmentArt` key the scope can ask for against `assets/sprites/`.
2. **Dynamic** (windowed, `xvfb-run`, 1280x720, `--art-misses` and `--art-shots=`), discovery only:

| Run | Flags | Saw |
|---|---|---|
| wA | `--stage=wastes --policy=army --spells=death_ray` | full run to the Purge Protocol: pylons, storms, mortars, Trojan Horse, Kestrel, Event Horizon, Reckoning |
| aB | `--stage=assembly --policy=army --spells=hollow_puppet` | belts, furnace channels, fabricators, Beta Build, Motherboard, Reckoning |
| cC | `--stage=citadel --policy=army --spells=scrap_swarm --classes=iron_revenant,grave_drone` | gates, laser courts, guns, turrets, Valkyrie 2.0, Deus Ex Machina, finale, Reckoning |
| dD | `--stage=assembly --character=marionette --spells=hollow_puppet --classes=grave_drone --timeout=760` | Marionette, Hollow Puppet / Puppet King, Grave Drones |
| eE | `--stage=assembly --spawn=juggernaut@30x4,arc_engineer@32x6,beta_build@34` | Juggernaut flame, Arc Engineer field |
| fF | `--stage=wastes --spawn=trojan_horse@30,mortar_walker@32x4,spotter@34x3,aegis_bot@36x4,scout_drone@38x8` | Trojan Horse, rockets, mortars, Lock-On |
| vig | scratch scene (not in the repo) that draws `StageVignette` for harbour / wastes / assembly / citadel | the stage-select cards |

`[art-miss]` totals (missing sprite keys, after dropping probes another folder answered): wastes 13 lines (kill drone, Trojan rocket,
and the Kestrel decoy kind, which its kit draws itself), assembly 4 (kill drone), citadel 10 (7 items), marionette build 0. Every miss is in the table below.

**Per-frame polygon?** `y` = drawn by a node that redraws every frame while visible and builds GL objects each time
(`draw_circle` / `draw_arc` / `draw_line` with width / `draw_colored_polygon` / many `draw_rect`s); the CLAUDE.md Web
cost rule. `y*` = redrawn only while the unit moves or changes phase. `n` = once or on a cell change.

**Noticeability:** high = big, common or always in view, or reads as unfinished at a glance; medium = visible in a
specific fight or zone and flat next to the sprites; low = thin, brief or intentionally graphic.

**Verdict on the act as a whole:** every Empire kind, boss, character, summon class, skin, icon, obstacle (all 20
kinds), floor tile (all 12 zone floors) and epilogue panel has a PNG; only 2 kinds and 4 projectile kinds are missing.
What still reads as placeholder is almost all **ground effects and beams**: they are flat code shapes beside pixel art.

## A. AoEs, beams, zones, telegraphs (first)

| id | what | where drawn | current look | per-frame polygon? | noticeable | proposed fix, size (art px) |
|---|---|---|---|---|---|---|
| A1 | **Death Ray / Event Horizon beam** (player spell, sweeps 360 degrees; the evolution has several beams) | `abilities/spells/death_ray.gd:272-290` | no PNG: three stacked `draw_line`s (glow, body, core) plus 4 fading afterglow lines and a tip circle; a flat violet stripe, shot `01` | y (7+ lines per beam per frame) | high | animated beam: tileable body strip 32x16 x 4 frames (energy flowing), tip burst 32x32 x 4 frames, afterglow = 3 fading copies of the texture; draw as a stretched textured rect (no polygons). Shares the Citadel laser (A5) with a red / white-hot recolour |
| A2 | **Orbital strike telegraph** (Purge Protocol Reckoning on all three stages, and the Citadel's guns every 7-16 s all stage) | `enemies/empire/empire_rules.gd:212-223` (called by `citadel_director`, `EmpireRules.strike`) | no PNG: red `draw_circle` filling with time, two `draw_arc` rings, a 2-line crosshair; shot `07` (lower circle), `03` | y (circle + 2 arcs + 2 lines per strike, up to 3 at once) | high | ground reticle texture, ring + corner ticks + crosshair, 112x112 (r 54), tinted and scaled by radius, fill drawn as a scaled soft disc (`SpriteBank.draw_disc` batches); 1 frame, plus a 4-frame "arming" pulse |
| A3 | **Strike / slam landing flash**: `EffectManager.impact()` with no anim, the fallback is a flat tan disc and an ivory ring. ~30 Act III call sites: orbital strikes (`empire_rules.gd:195`), Kestrel, Deus, Motherboard, Trojan, Valkyrie, Beta Build, citadel gates, fabricator death | `core/effect.gd:123-125` (`Kind.IMPACT`), `effect_manager.gd:168` | only the 4 `wastes_blast` calls (pylon, rocket, 2 Trojan) have a strip; every other Act III impact is the flat disc, shots `03`, `04`, `07` (big tan discs with a white rim) | y (circle + 40-seg arc) | high | one amber + one red impact strip, 6 frames 96x96 (scaled by radius, `AnimData` ids `empire_blast` / `empire_blast_red`); pass `anim` at the Act III call sites (no logic change). Shared primitive, so Act I / II would also benefit if the strips are recoloured |
| A4 | **Shield Gate wall**, cables and end posts (3 gates a run) | `core/citadel_glyphs.gd:163-193`, `citadel_director.gd:691-710` | code: 4 lines (amber band, glow edges), a scrolling lattice of thin lines, 2 circle posts, a pulsing cable; shot `05` | y (4 lines + ~20 lattice lines + 2 circles per gate per frame) | high | tileable wall strip 16x40 x 4 frames (hex energy field, scrolls along the wall) drawn as a textured rect, end post sprite 24x32 (chrome emitter with amber core); cable 8x16 tile |
| A5 | **Laser grid beams** + telegraph band (Laser Courts every 9 s, the Core every 13 s; beams 1500 px long) | `citadel_glyphs.gd:197-217`, `citadel_director.gd:710-720` | code: telegraph = 1-2 px blinking red line with end circles and a flat brown-red `draw_colored_polygon` band; firing = 3 stacked red / white lines; shots `06`, `04` | y (lines + a polygon per beam; 2-3 beams) | high | beam tile 32x16 x 4 frames (red body, white-hot core; the A1 family), emitter caps 16x16 (open / firing), band = a tileable hazard-stripe decal 32x32 at 12% alpha |
| A6 | **Furnace channels** (Assembly Hall and Furnace zones; dormant, warning, burning) | `core/assembly_glyphs.gd:87-132` via `assembly_director.gd:564-600` | no PNG: `draw_rect` fills (slag colour, molten orange, white core), hash-placed 2 px cracks / flame ticks and a haze rect; shot `08` is a flat orange stripe | y (a dozen rects per channel, every tick; the director redraws every frame) | high | 3 tileable strips (cold slag 32x36, warning glow 32x36 x 2, molten 32x36 x 4 flicker frames) drawn with `draw_texture_rect(tile=true)`; flame tongues as a 16x24 x 4 strip along the edge |
| A7 | **Conveyor belts** (Docks, Conveyor Floor, Hall) | `assembly_glyphs.gd:51-82` | no PNG: rect fills, 2-line amber chevrons every `CHEVRON_STEP`, roller ticks; reads clean but it is ~150-250 `draw_rect` / `draw_line` calls per frame across the view (visible in shots `03`, `08`) | y (the biggest per-frame item of the act in call count) | medium | belt tile 32 x (2 x half) with rails and chevron, scrolled by UV offset (one `draw_texture_rect` per belt); rubber + rail 9-slice; saves GL objects on the Web |
| A8 | **Scrap storm veil** (4 storms a run, 20 s each, whole screen) | `enemies/empire/wastes_director.gd:376-402` (`StormVeil`) | code: 12-20 concentric 64-seg `draw_arc` rings, 46 px bands (visible banding) plus 18-46 grit lines; shot `02` | y (12-20 wide arcs + up to 46 lines every frame, the worst polygon load in the act) | medium | one radial gradient texture (dither, 256x256, scaled to the view) + a tileable grit streak overlay 128x128 scrolled with the wind; no arcs |
| A9 | **Deus stomp / footfall rings, shocks, overload charge and pulse front, soul binding** | `citadel_glyphs.gd:266-286,335-344`, `deus_hazards.gd:210-232` | code: red disc + 2 arcs; pulse front = 2 thick 64-seg arcs; shot `09` | y | medium (boss fight only) | shockwave ring strip 8 frames 192x192 (scaled by radius) for the pulse and shocks; reticle texture from A2 for stomp rings; green binding ring 4 frames 128x128 |
| A10 | **Deus chaingun sweep sector, Judgment Lance, hangar door, teleport glow** | `citadel_glyphs.gd:290-330`, `boss_deus_ex_machina.gd:796-813` | code: `draw_colored_polygon` fan (17 pts) + lines; lance = 3 stacked lines + circle; hangar = 3 rects | y (polygon) | medium | lance = the A1 / A5 beam family in amber (tile 32x24 x 4); sector = the shared cone telegraph (A15); hangar door sprite 32x20 x 3 frames (closed, opening, open); teleport glow 4 frames 64x64 |
| A11 | **Motherboard stamp squares, hurl landing circle, magnet coils, grab lanes** | `enemies/empire/motherboard_hazards.gd:134-160`, `assembly_glyphs.gd:248-290`, `boss_motherboard.gd:576-580` | code: red / amber filled squares with corner brackets, circle + cross, 3 expanding `draw_arc` rings; claws are line + rect shapes (`draw_claw`) | y | medium (boss only; claws not captured, static read) | stamp reticle 64x64 (square, brackets) + a press-slam impact strip 6 x 96x96; magnet ring texture 128x128 x 3 expanding; claw sprite 16x24 open / closed |
| A12 | **Juggernaut flame stream** (every Juggernaut, Assembly and any stage it is spawned on) | `assembly_glyphs.gd:224-234`, `juggernaut_kit.gd:120` | code: 7 jittered circle pairs along a cone, shot `11` is a chain of orange balls | y* (14 circles per frame while it burns) | medium | flame cone strip 4 frames 96x48 (rotated to `dir`, scaled to reach), plus the shared gold telegraph cone before it |
| A13 | **Arc Engineer static field** and repair arcs | `assembly_glyphs.gd:201-218`, `arc_engineer_kit.gd:128-142` | code: filled circle + 32-seg arc + 8 tick lines; zig-zag 1.5 px lightning for repairs; shot `11` | y* | medium | field ring texture 96x96 (spark ring, closes in over 4 frames), repair arc = reuse `GraveSpellGlyphs.draw_lightning` look (already shared) or a 16x8 x 3 zap strip |
| A14 | **Mortar shell and landing ring** (every Mortar Walker; Motherboard hurls) | `enemies/empire/empire_shots.gd:331-358` | code: shell = 2 circles lifted by an arc height, landing = 28-seg red `draw_arc` ring when under 0.6 s; wA run at 1:26 into the Wreck Gullies (frame not kept) | y (all Empire shots in one `_draw`) | medium | shell sprite 12x12 (spins, 2 frames), landing ring = A2 reticle at 48 px; shell shadow = shared disc |
| A15 | **Shared boss telegraphs**: gold circle, lane and cone (Kestrel leap and charge, Trojan stomp, Beta Build swipe and rivets, Duelist / Valkyrie lanes, Deus chaingun, Motherboard grab) | `core/effect.gd:108-122,126-140` | code: `draw_colored_polygon` fills + `draw_polyline` outline, always Covenant gold (the Empire's own red / amber telegraph rule is not applied); visible in shot `11` and in the Beta Build rivet lanes | y (polygons) | medium; **cross-act** (every boss in every act) | leave the design (readability is the point); on the Web replace polygons with one lane / cone texture (soft edge, 64x64 9-slice) tinted by `color`; an Empire red variant would be optional |
| A16 | Pop / ring / slash / spawn-ring effects (aegis blocks, spawn rings, kill pops) | `effect.gd:90-107` | code arcs and lines, short-lived | y (brief) | low | leave; `summon_rise` strip already exists for spawns, add it to Empire spawn rings if wanted |
| A17 | **Signal Pylon reach ring** and the fallen pylon's dead zone (ring, stump circle and line) | `pylon_kit.gd:26-39`, `wastes_director.gd:365-372` | code: 18 dashed 4-seg arcs, faint; dead zone = faint ring + stump | y* / y | low (thin, faint, informational) | leave the ring; the stump could be a 40x16 broken-mast decal (optional) |
| A18 | **Lock-On painted lines** and reticles | `enemies/empire/lock_on.gd:248-268` | code: 2 thin red lines per painted target, circle + 4-tick reticle (fF run, frame not kept) | y (3 lines max) | low (a thin laser sight is the intended look) | leave; optional 24x24 reticle sprite (open / locked) |
| A19 | **Aegis shield arc**, **Spotter glow ring** | `aegis_kit.gd:96-108`, `spotter_kit.gd:43-47` | code arcs over the sprite; the shield arc reads as an energy shield | y* | low | leave |
| A20 | **Valkyrie jets, blade storm**, Duelist jets, Beta Build patch cables | `citadel_glyphs.gd:109-148`, `valkyrie_kit.gd:338`, `beta_build_kit.gd:242-250` | code lines / arcs over sprites | y* | low | jet flame strip 16x24 x 3 (optional), blade storm = 2 slash strips 64x64 (optional) |

## B. Units and bosses

| id | what | where drawn | current look | per-frame polygon? | noticeable | proposed fix, size (art px) |
|---|---|---|---|---|---|---|
| B1 | **Kill-Drone** (the Purge Protocol's Reckoning kind: dozens at once on every Act III stage; also the Codex entry) | `core/empire_glyphs.gd:25-26,50-60` (`_drone`) | **no PNG** (`empire/kill_drone`, 6,500+ glyph draws in one wastes run, 3,300 in assembly, 1,300 in citadel); code disc with stub rotors and a red lens, shot `03` / `04` (tiny dark drones with a red eye) | y* | high | `empire/kill_drone` 32x32 (the scout drone's frame with a red lens, heavier plating) + walk / hover strip 4 frames; `SpriteData` height 32 |
| B2 | **Trojan Horse Swarm Rocket** (the miniboss's shoot-down-able kind, `trojan_rocket`) | `rocket_kit.gd:118-130` + `core/wastes_glyphs.gd:23-33`; key `projectiles/trojan_rocket` | **no PNG** (6,200 draws in one run); code rocket (rect + polygon) with 2 exhaust circles | y* | medium (small, but it is the thing the fight asks you to shoot) | `projectiles/trojan_rocket` 24x12 facing +x; exhaust flame strip 3 frames 12x10 |
| B3 | Kestrel's decoy holograms | `decoy_kit.gd:38-55` | boss sprite tinted amber + projector circles + 5 scan lines (intended hologram) | y* | low | leave (optional 16x10 projector sprite) |
| B4 | Static bodies drawn without a walk strip: `sentry_turret`, `shield_generator`, `deus_leg_plate`, `deus_shield_drone`, `fabricator`, `motherboard_turret`, `signal_pylon`, `bosses/motherboard`, Deus phases | `art-miss` "no walk strip" list | these are structures or hovering bosses; stills with motion handled in code | n | low (intentional) | none |
| B5 | Sentry barrel, Motherboard turret barrel, Kestrel's scope glint, pylon beacon glow | `citadel_glyphs.gd:123-138`, `motherboard_turret_kit.gd:66-72`, `boss_kestrel.gd:458`, `pylon_kit.gd:42-47` | a drawn line / circle laid over the sprite (the sprite carries the body) | y* | low | optional 24x8 barrel sprite rotated to aim |
| B6 | **Has art, checked (no action):** Scout Drone, Line Trooper, Spotter, Aegis Bot, Mortar Walker, Signal Pylon, Trojan Horse (closed, split), Arc Engineer, Juggernaut, Fabricator, Beta Build, Motherboard Turret, Valkyrie Duelist, Sentry Turret, Shield Generator, Valkyrie 2.0, Deus leg plate and shield drone; bosses Kestrel (pose, blades), Motherboard, Deus Ex Machina (3 phases + fire pose); Grave Gunner, Grave Drone, Wraith Drone, Iron Revenant, Deus Revenant; Lightning Abbess, Marionette, Rust Prophet and all their skins; every spell / class / passive icon | `assets/sprites/empire`, `bosses`, `summons`, `player`, `icons` | pixel art with walk strips (idle strips for the two female characters) | n | n/a | none |

## C. Structures, floors, obstacles

| id | what | where drawn | current look | per-frame polygon? | noticeable | proposed fix, size (art px) |
|---|---|---|---|---|---|---|
| C1 | Floor decals of the Citadel (`decals/citadel_gates_plate`, `citadel_courts_scorch`, `citadel_lifts_hazard`) | `core/citadel_ground.gd:87-132` | no PNG (6,000+ lookups each): code plate rects, scorch lines, hazard-stripe polygons, circuit polylines; the tile floor under them is art | n (redrawn on a cell change) | low | 3 decals + 1-2 variants each, 32x20 / 28x8 / 32x12 (the `make_decals.py` recipe) |
| C2 | Floor decorations of the Wastes and the Assembly Halls | `wastes_ground.gd:83-110`, `assembly_ground.gd:88-120` | tiles are art; sparse code details on top (scrap plates, dead signal light, hazard paint, rivets, scorch blots); no decal keys exist | n | low | optional: 6-10 decals per stage |
| C3 | Obstacles of all three stages (slag mound, wreck plate, titan hull, ridge boulder, wall segment, tank trap; cargo crate, crucible, ingot stack, parts bin, press machine, robot arm, servo cabinet, fuel drum; iron barricade, citadel crate, core conduit, emitter pylon, lift winch, signal bollard) | `assets/sprites/obstacles` | all kinds and sizes have PNGs; `EmpireGlyphs` / `WastesGlyphs` / `AssemblyGlyphs` / `CitadelGlyphs.draw_obstacle` fallbacks never run | n | n/a | none |
| C4 | Zone floor tiles (`wastes_*`, `assembly_*`, `citadel_*`, 12 in all) | `assets/sprites/tiles` | art | n | n/a | none |

## D. Projectiles

| id | what | where drawn | current look | per-frame polygon? | noticeable | proposed fix, size (art px) |
|---|---|---|---|---|---|---|
| D1 | **Scrap Swarm drones** (player spell; 4-12 drones orbiting at 136 px, always on screen while owned; the Rust Prophet's own) | `abilities/spells/scrap_swarm.gd:127-147`, key `projectiles/scrap_drone` | **no PNG** (511,000 draws in one run): a bone-white disc with a violet dot and a 1 px rotor line; tiny and flat, shot `10` | y (3 shapes per drone per frame) | high | `projectiles/scrap_drone` 20x14, 2-frame rotor strip; a brighter variant for Deathless Swarm's kill drones (replaces the code ring) |
| D2 | **Scrap bolt** (Scrap Swarm / Rust Prophet shots) | `abilities/projectile.gd:135-138`, key `projectiles/scrap_bolt` | **no PNG** (8,700 draws): a 3 px violet line and a 4-pt polygon | y | medium | 14x6 shard with violet wrap, facing +x |
| D3 | **Iron Revenant cannon shell** (and Deus Revenant's twin cannons) | `projectile.gd:139-143`, key `projectiles/iron_shell` | **no PNG** (5,200 draws): a teal trail line and two circles | y | medium | 18x8 shell with teal soul-fire trail |
| D4 | **Grave Gunner rifle round** (every raised cyborg; static read only, no gunner appeared in the runs) | `projectile.gd:131-134`, key `projectiles/soul_round` | **no PNG**: 2 lines | y | medium (common once Steel has no soul is in play) | 12x4 round with a soul-teal streak |
| D5 | **Empire shots**: zap, round, rail, bolt, arc bolt, rivet, turret bolt, missile, chaingun | `empire_shots.gd:331-358`, styles in `data/empire_rules_data.gd:50-66` | code tracers: a 2-3 px line with a glow line, heavy shots get a circle head; they read as laser tracers (the amber dashes in shots `03`, `10`); the 46 px rail and the 26 px missile are the thinnest-looking | y (the most common thing on screen in Act III) | medium | optional, the tracers are acceptable; if done: tracer 12x4, rail 48x8, missile 28x10 with exhaust (3 frames), each tinted by the style colour, drawn with `draw_texture` along the heading (batched) |
| D6 | Deus Revenant missiles | `horde/horde_hazards.gd:330-340` (`WarbandGlyphs.draw_boulder`) | thrown as corpse boulders (code stone) with the shared landing telegraph | y | low (one evolution) | `projectiles/deus_missile` 24x10 + a small shadow |
| D7 | Hollow Puppet casting strings and the puppet control bar | `hollow_puppet.gd:152-170`, `assembly_glyphs.gd:293-318` | 1 px string lines, a violet bar rect over tinted foe art; reads fine, dD run, 6:19 (frame not kept) | y* | low | leave |

## E. Other (menus and screens)

| id | what | where drawn | current look | per-frame polygon? | noticeable | proposed fix, size (art px) |
|---|---|---|---|---|---|---|
| E1 | **Stage-select card of the Scrap Wastes** (and the victory card, which reuses it) | `data/front_door_data.gd:256-264` (`VIGNETTES["wastes"]`); comment says "placeholder scene until each stage brings its own" | the floor is the **Crimson March's** `tiles/march_burned`, no props, no boss: two scout drones, a spotter, a trooper, two undead, shot `12` (second card); Assembly and Citadel cards are full scenes with props and their boss | n | high (it is the first Act III card) | recompose from existing art, no new PNG needed: `tiles/wastes_slag`, `obstacles/wreck_plate_s` + `titan_hull_s`, `empire/signal_pylon`, `empire/aegis_bot`, Kestrel in her aim pose (`bosses/kestrel_aim`), drifting embers |
| E2 | Hit flash on heavy bosses | `Glyphs._c`, sprite flash | the Motherboard drew as a solid white silhouette in 3 of 5 captures under army fire; works as designed, but it hides the art during the boss fight | n | low | none (design call: shorter / dimmer flash) |

## Counts

- **A** AoE / effect items: 20 (high 6: A1 A2 A3 A4 A5 A6; medium 9; low 5).
- **B** units / bosses: 6 rows, 2 real gaps (B1 high, B2 medium), 3 low, 1 "has art".
- **C** floors / structures: 4 rows (C1, C2 low; C3, C4 have art).
- **D** projectiles: 7 rows (D1 high; D2, D3, D4, D5 medium; D6, D7 low); 4 projectile keys have no PNG.
- **E** other: 2 rows (E1 high, E2 low).
- Totals: 39 rows: high 9, medium 14, low 13, no action 3 (B6, C3, C4).

## Top 15 to fix (value for effort, in order)

1. **A1** Death Ray / Event Horizon beam (player spell, the flattest thing on screen).
2. **B1** Kill-Drone sprite (every Reckoning, thousands of glyph draws).
3. **A2 + A3** orbital-strike reticle and the Act III impact strip (Purge Protocol, Citadel guns, every boss slam; two assets cover ~30 call sites).
4. **A6** furnace channel strips.
5. **A5** laser beam strip (shares the A1 beam family).
6. **A4** Shield Gate wall strip and posts.
7. **D1** Scrap Swarm drone sprite.
8. **E1** Scrap Wastes stage card (assembly from art that exists).
9. **A8** scrap storm veil as textures (also the biggest Web polygon load of the act).
10. **A12** Juggernaut flame strip.
11. **B2** Trojan Swarm Rocket sprite.
12. **D2 + D3 + D4** scrap bolt, iron shell, soul round (three small PNGs).
13. **A7** conveyor belt as a scrolled tile (Web cost more than looks).
14. **A9 + A10** Deus ring / pulse / lance set (reuses A1, A2, A3 assets).
15. **A14 + A11** mortar shell and the Motherboard stamp / magnet reticles.

## Not checked

- Visually unseen (static read only): Grave Gunner rounds (D4), Wraith Drone, Puppet King and Deus Revenant missiles, the Motherboard's claws / turrets / stamps in motion (A11), Valkyrie 2.0's jets and blade storm (A20), Kestrel's decoys (B3), the Lightning Abbess and Rust Prophet characters in a run (art files exist, no `[art-miss]` for them), Hyper / Deathlord skins.
- Phone / reduced-effects drawing paths (`Settings.reduced_effects()`), the Codex and Ossuary screens for Act III entries, sound.
- The Act III epilogue panels and menu moods (art files exist, not rendered).
- Shot numbers in the table refer to `docs/art/audit/act3_shots/`: `01_death_ray_event_horizon`, `02_scrap_storm_veil`, `03_purge_protocol_wastes`, `04_purge_and_laser_citadel`, `05_shield_gate_wall`, `06_laser_grid`, `07_gun_strike_discs`, `08_furnace_channels`, `09_deus_stomp_ring`, `10_scrap_swarm_drones`, `11_juggernaut_flame_jam_field`, `12_stage_vignettes`. The "fF" / "aB" / "wA" mentions are run names from the table above (full frames not kept).
