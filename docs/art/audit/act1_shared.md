# Act I and shared art audit: placeholder graphics (AoEs first)

Owner report: "I did see quite a few placeholder graphics for some of the AoEs in act one."
Scope: the three Act I stages (Graveyard, Crimson March, Sanctum of Judgment: kinds, structures,
events, hazards, bosses Sir Alaric / Marshal Vael / Grand Inquisitor Seraphine) plus everything
shared by all acts (spells and evolutions, summon classes and their specials, Dread Rally and the
ultimates, Grave Step, power-ups, chests, pickups, the Soul Nova). Act II and Act III stages are not
covered here. Audit only: no art and no code changed.

## How it was done

1. **Static.** Every `_draw()` / `draw_*` site in scope was read (the call sites of `EffectManager`
   `ring` / `impact` / `pop` / `slash` / `beam` / `spawn_ring` / `telegraph_*` were listed one by
   one, because an `Effect` with no `anim` id is a code shape, see "How an AoE is drawn" below).
   Every string-literal sprite key in `scripts/` was checked against `assets/sprites/`, and every Act I
   enemy, summon, boss, structure and obstacle kind against its PNG, walk strip and floor tile.
2. **Dynamic (discovery only).** Windowed runs under `xvfb-run` at 1280x720 with `--art-misses` and
   `--art-shots=T,...` (run lines in section 10). The `[art-miss]` report and the screenshots
   found the items marked "seen" in the table.
3. **Judged** by what a player notices next to the surrounding pixel art: a flat translucent
   disc, a plain polygon lane or a one-pixel arc reads as a placeholder; a thin ring, a progress
   arc or a particle square is intentional and marked low.

## Result in one paragraph

**No sprite key is missing for anything in Act I or the shared systems** (every unit, boss, structure,
obstacle, pickup, marker, floor tile and decal has its PNG; the only misses in the whole `scripts/`
tree are Act II / III keys, listed under "Other"). The placeholder look is **not missing art, it is
art that was never made for ground-area effects**: ART_BIBLE "Placeholder art batch" decided that
"rings, telegraphs, zones, glows and progress arcs stay in code", and that is exactly the set the
owner is now noticing. Every persistent AoE (Plague Cloud, Pestilence, Wither, the Grave Eruption
field, holy zones, sanctified chambers, suppression circles), every boss telegraph and most summon
specials (Abomination stomp, Deep Freeze, Dirge wail, Gargoyle dive, Hellhound fire) are
flat filled discs, rings, polygons and lines. See the "Top 15" list (section 7).

Rows by group and how noticeable they are (a row is one drawing site or a small family of them):

| group | rows | high | medium | low | none (already art) |
|---|---|---|---|---|---|
| AoEs and ground effects | 62 | 16 | 31 | 13 | 2 |
| Units and bosses | 6 | 0 | 4 | 1 | 1 |
| Structures, obstacles, floors | 5 | 0 | 1 | 2 | 2 |
| Projectiles | 4 | 0 | 0 | 1 | 3 |
| Pickups and chests | 2 | 0 | 0 | 1 | 1 |
| Other | 7 | 0 | 2 | 2 | 3 |
| **total** | 86 | 16 | 38 | 20 | 12 |

## How an AoE is drawn (one-time background, it explains most rows)

- `Effect` (`scripts/core/effect.gd:79`) draws a **code shape** per `Kind` (RING = filled disc + 3 px
  arc, IMPACT = disc + ivory arc, SLASH = one 2.5 px arc, BEAM = a line + dot, SPAWN = arc + line,
  POP = arc + 4 lines, TELEGRAPH_CIRCLE / LINE / CONE = a 12% fill, a growing 28% fill and an outline)
  unless the caller passed an `anim` id **and** `assets/sprites/effects/<id>.png` exists. 39 strips
  exist (`AnimData.ANIMS`); every call below marked "no anim" falls through to the code shape.
  Even a call with a strip is often followed by a second, un-animated `ring()` that always draws.
- Persistent zones (clouds, auras, holy zones, chambers, fields) are `_draw()` on a Node2D that
  redraws **every frame while the zone exists** (`draw_circle` / `draw_arc` /
  `draw_colored_polygon`: the Web cost rule in CLAUDE.md). The ground floor, the fog patches and
  decals redraw only when the camera crosses a 256 px cell, so they cost nothing per frame.
- The Harbour pass set the precedent for the fix (`undertow.gd`, `overlays/undertow_crest`,
  `overlays/tide_wall`, `overlays/maelstrom_whirl`, `structures/merrow_pulpit`, ART_BIBLE "Harbour
  placeholder art pass"): a ring or area becomes **sprite crests tiled along an arc plus the shared
  disc texture** (`SpriteBank.draw_disc`, batched, no polygon), or a looping strip drawn as one
  texture per zone. Proposed fixes below follow that pattern; sizes are art px (1 art px = 1 screen
  px, `AnimData` frame sizes 128 / 192 / 256 / 512).

## Legend

- **Look**: `code` = drawn only with `draw_*` shapes; `art+code` = a PNG exists but a code layer
  is drawn with it every time; `art` = pixel art, code only as a missing-PNG fallback.
- **Per-frame polygon**: y = the shape is rebuilt on every redraw while it is on screen
  (`draw_circle` / `draw_arc` / `draw_colored_polygon` / `draw_polyline`; for an `Effect` during its
  0.2 - 0.9 s life); n = a texture, rect or one-off redraw.
- **Seen**: a file name = a kept screenshot in `docs/art/audit/act1_shots/` (section 9); "R#" = seen in
  that run (section 10) but not kept; "log" = only confirmed by the `[art-miss]` report; "code" = read in the
  source, not caught in a run.
- **Noticeable**: high = large, long-lived or on screen in most runs, clearly flat next to the pixel art;
  medium = frequent but small, or short, or only partly placeholder; low = thin, rare or plausibly intentional.

## 1. AoEs and ground effects

### 1a. Player spells and evolutions

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| A01 | **Plague Cloud** zone (r 55 - 70 px, 3 - 4.5 s, several at once) | `spell_glyphs.gd:258` `draw_plague`, called from `plague_cloud.gd:207` | code: one 8% disc, three overlapping 11% discs, a 1.5 px rim arc and rising bubble arcs; reads as overlapping flat green circles | y (6+ circles/arcs per cloud, redrawn each frame) | `wither_plague` | **high** | looping cloud strip, 6 frames x 192 px (one texture per cloud, alpha fade by `life`), rim as tiled crest ring (the Undertow pattern); keep the Rot motes as particles |
| A02 | **Pestilence** (evolved Plague Cloud, r 95 px, 7 s, dark violet rim that thickens when the nova charges) | `spell_glyphs.gd:273` `draw_pestilence` | code: 42% dark disc, overlapping discs (the "flower" of circles in `pestilence_holy_zones`), a violet arc up to 4.5 px | y (8+ shapes per cloud) | `pestilence_holy_zones` | **high** | looping dark-cloud strip, 6 frames x 256 px + a "charge" ring texture; death-nova burst strip (A03) |
| A03 | Pestilence **death nova** (green + violet rings when a cloud ends) | `plague_cloud.gd:201-202` (`ring()` x2, no anim) -> `Effect.Kind.RING` | code ring: filled disc + 3 px arc | y (Effect, 0.45 - 0.55 s) | code | medium | burst strip `plague_nova`, 8 frames x 256 px (a spore burst; nova radius = 2 x cloud) |
| A04 | **Wither / Necrotic Blight** aura (r 80 - 105 px, always on while the spell is owned, follows the necromancer) | `grave_spell_glyphs.gd:248` `draw_wither`, called from `wither.gd:108` | code: a 5 - 10% disc, 16 dashed 1.5 - 2.5 px arcs turning round the rim, five drooping motes; the 0.3 s pulse ring has art (`effects/wither_aura`) but the standing aura does not | y (about 22 shapes, every frame, the whole run) | `wither_plague` | **high** (it sits on the player all game) | looping ground sigil strip, 4 frames x 256 px (a turning rune ring with soft mist, tinted PLAGUE / NECRO_GREEN for Blight), drawn under the army; the existing pulse strip stays |
| A05 | **Grave Eruption spike field** (evolved Corpse Explosion, r 90 px, long lasting) | `spell_glyphs.gd:233` `draw_spike_field` (+ `_spike` polygons at :249), from `corpse_explosion.gd:230` | code: a 35% dark disc, a 1.5 px green rim, a ring of triangle spikes drawn as polygons | y (disc + arc + 8 - 12 polygons) | code (evolution is late, 10 - 14 min) | medium | decal strip `eruption_field`, 6 frames x 192 px (cracked ground, spikes that rise and sink as `life` runs out); spikes as 3 - 4 prop sprites |
| A06 | Corpse Explosion / Eruption **burst accent** (ring + 8 radial lines drawn with the art strip) | `spell_glyphs.gd:222` `draw_bone_burst`, from `corpse_explosion.gd:232` | art+code: the 192 px strip (`corpse_explosion`, `grave_eruption`) plus a code arc and lines | y | R1 (strip plus accent), not kept | low | drop the code accent once the strip is accepted, or leave |
| A07 | **Soul Siphon / Soul Rapture tethers** (wavy beams from the necromancer to up to 3 foes) | `spell_glyphs.gd:158`, `:169` `draw_siphon_tether` / `draw_rapture_tether`, from `soul_siphon.gd:177` | code: two `draw_polyline`s and travelling dots | y | code | medium | beam segment sprite (16 x 8 px, 4-frame flow) tiled along the wave; heal-pulse ring at `soul_siphon.gd:171-172` (RING + POP, no anim) -> `siphon_pulse` strip, 6 frames x 128 px |
| A08 | **Soul Chains** lightning (soul lightning between chained foes; strike flash has art) | `grave_spell_glyphs.gd:218` `draw_lightning`, from `soul_chains.gd:192` | art+code: the 0.18 s `soul_lightning` strip at each struck foe, but the arc itself is three code polylines (jagged line) | y | R1 (chains at 360 s), not kept | medium | 3 bolt-segment sprites (32 x 16 px, 3 jag variants) stretched / tiled between the endpoints, a green "damned" variant |
| A09 | **Orb Shield** orbit ring and pulse ring | `orb_shield.gd:120` (1 px, 12% arc), `:80` pulse `ring()` (no anim) | code: a very faint orbit arc (intentional guide); the orbs have art (`projectiles/orb`) | y | R1, not kept | low | leave the orbit arc; pulse ring (evolved Eclipse Ward) -> reuse `shadow_blast` tinted, or a 6 x 192 px strip |
| A10 | **Eclipse Ward** (evolved Orb Shield): dark rotating barrier band, green segments, inner charge arc | `orb_shield.gd:136` `_draw_eclipse` | art+code: orbs have art (`eclipse_orb`), the 9 px black band, 10 px segment arcs and charge arc are code | y (3 - 8 arcs, big radius) | code | medium | ring-band texture 256 px (a dark band with green rune segments, rotated) + charge arc stays code |
| A11 | **Mage orb splash** (every Mage volley, r 40 px, 3+ mages) | `projectile_manager.gd:379` `ring(p.dest, p.splash, VIOLET, 0.3)` (no anim) -> RING | code ring: 22% violet disc + 3 px arc, 0.3 s | y (Effect) | R6 (faint ring, not kept) | medium (the most frequent AoE of a default army, but faint and 0.3 s) | splash strip `mage_splash`, 6 frames x 96 px (a violet arcane burst, radius 40 -> 80 px wide) |
| A12 | **Bone Wall / Charnel Bastion** burst outer ring | `bone_wall.gd:287` `ring(center, ..., NECRO_GREEN, 0.4)` (no anim) | code RING sized to the whole wall circle (up to ~120 px) after the per-segment `bone_wall_burst` strips | y | code | low | drop it, or `bastion_ring` 8 x 256 px; segments and rise strip are art |
| A13 | **Death Mark / Doom Brand** rings (mark hit ring, doom detonation second ring, raise ring) | `death_mark.gd:153`, `:207`, `:232` (`ring()` no anim) | art+code: skull sprites and the `doom_burst` strip are art; three extra code rings | y | code | low | fold into the `doom_burst` strip |
| A14 | **Dread Rally** burst (the default ultimate): strip + a second green ring + an `abyss()` vortex | `dread_rally.gd:191-193` | art+code: `effects/dread_rally` (256 px) plus a code RING (0.6 x radius) and a code ABYSS (dark disc, green rim, 4 violet arcs; no anim) drawn with it | y | not caught (0.6 s, bots cast it rarely in a shot window) | medium | remove the code ring and abyss from the Rally and let the strip carry it, or make the abyss a strip (`abyss_core`, 8 x 128 px) |
| A15 | **Ultimates**: Sovereign's Decree taunt ring, Eclipse screen dim + black hole, Grave Tide screen-edge bands | `ultimate_overlay.gd:68` `_draw_decree`, `:83` `_draw_eclipse`, `:94` `_draw_tide`; cast bursts `ultimate_system.gd:220-221` | art+code: cast strips exist (`sovereigns_decree`, `eclipse`, `grave_tide`); the lasting overlays are code (rings, a flat rect dim, edge `draw_rect`s) | y (a full-view `draw_rect` + arcs per frame) | code | medium (only the three unlockable ultimates) | Decree: 256 px aura ring strip under each taunted unit group; Eclipse: black-sun sprite 64 px + vignette texture; Tide: tileable wave-edge texture 64 x 16 px |
| A16 | **Soul Nova** power-up | `powerup_manager.gd:261-262` | art (`soul_nova` strip; the code ring is hidden by `ring_under`) | n | - | none (art) | none |
| A17 | **Grave Step** departure puff | `grave_step.gd:157` | art (`grave_step_trail`) | n | - | none (art) | none |

### 1b. Summon specials, evolutions and army effects

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| A20 | **Abomination Stomp** (r 64 px; wind-up telegraph, then impact) | telegraph `abomination_behavior.gd:96-103`; impact `:85-86` (`ring()` x2, no anim) | code: 10% flesh disc + growing 22% disc + 2 px bone rim; the impact is two RING effects + square particles | y | `abomination_stomp` | **high** for any Abomination build | `stomp` strip, 8 frames x 192 px (cracked earth shockwave with bone chips) + a ground crack telegraph decal 128 px (fills in over the wind-up) |
| A21 | **Bone Colossus stomp** (evolved Abomination) | `colossus_kit.gd:105-106` (RING x2) + shrapnel shots | code rings | y | `colossus_stomp_rings` | medium | reuse the `stomp` strip, larger (256 px) with bone shrapnel frames |
| A22 | **Frost Wraith Deep Freeze** (r 52 px, target-point telegraph, shatter) | telegraph `frost_wraith_behavior.gd:101-111`; impact `:77-78` (RING x2, no anim) | code: ice-blue disc + growing disc + 1.5 px ice rim; two code rings | y | code | medium | `deep_freeze` strip, 8 frames x 128 px (frost bloom) + frost sigil telegraph decal 128 px; the frozen shell on foes is already art (`overlays/frozen_shell`) |
| A23 | **Gargoyle swoop / dive** (dive marker, impact, Cathedral Horror stun ring) | `gargoyle_behavior.gd:238-250` (marker), `:178-181` (RING x3, no anim) | code marker disc + arc; impact rings | y | code | medium | reuse the existing `seraph_dive` / `golem_slam` style: `swoop_impact`, 8 frames x 128 px (stone dust and violet cracks) + a 96 px landing mark decal |
| A24 | **Banshee Dirge wail** (telegraphed wail, slows and cuts damage in r 72 px; Keening Lady adds a silence ring) | telegraph `banshee_behavior.gd:154-167`; wail `:123-126` (RING x3, no anim) | code: lilac disc + growing disc + 1.5 px rim + a line to the singer | y | code | medium | `wail` strip, 8 frames x 192 px (concentric sound-ripples with a skull wisp); ripple ring texture for the telegraph |
| A25 | **Dirge mark** on weakened foes (veil arc + tear lines, per foe) | `warband_glyphs.gd:243` `draw_dirge`, from `enemy.gd:1205` | code: one arc and two 1 px lines per affected foe, plus a halo cross when silenced | y (per foe, many at once) | code | low - medium | 24 x 16 px overlay sprite (veil + tears), a 2-frame shimmer |
| A26 | **Corpse Catapult Bone Barrage**: landing telegraph, splash rings, shard field, boulder shadow | telegraph `horde_hazards.gd:321-323`; impact `:279-280` (RING x2); shard field `warband_glyphs.gd:284` | art+code: the boulder sprite is art; the landing circle is 3 discs + a 1.5 px arc, the impact is two code rings, the Ossuary Engine shard field is two discs + a ring + 6 lines | y (disc textures batched, arcs and lines not) | `holy_zone_boulder_rings` (boulder rings); the shard fields were also in R3 at 760 s, not kept | medium | `boulder_impact` strip 8 x 128 px (crater, dust, bone chips), crater decal 96 px for the shard field, a dashed target-reticle texture for the landing |
| A27 | **Hellhound fire patches** (evolved Bone Hound; 40 - 60 patches a pack) | `warband_glyphs.gd:267` `draw_fire_patch`, `horde_hazards.gd:314` | code: two batched `SpriteBank` discs (ember + hellfire) and three flame triangles; already de-polygoned for the Web | n (primitives and discs, batched) | R7 (not kept) | medium (small ember blobs under a busy pack; flat, but at game scale they read as embers) | looping flame-patch strip, 4 frames x 48 px (3 variants), drawn as sprites over a soft scorch decal 48 px |
| A28 | **Rogue dash lane** telegraph + streak (Shadow Reaper chains it) | `rogue_behavior.gd:330-344` | code: a filled polygon lane, a growing second polygon, a 1.5 px outline; the streak is two lines | y (2 polygons + polyline per rogue) | code | medium | slash-streak sprite (64 x 16 px, 4 frames) stretched along the lane; lane telegraph as a dashed tile (see A60) |
| A29 | **Bone Golem slam, Bulwark** | slam `golem_behavior.gd:175` (art strip `golem_slam`); Bulwark `:193-194` (RING x2) and `golem_glyphs.gd:117` stakes (lines + 2 px arc) | art+code: slam is art; the planted Bulwark is rings and 2 px stake lines | y | code | low | `bulwark` ground decal 128 px (bone stakes ring) |
| A30 | **Fallen Seraph dive mark** and feather ring | `seraph_glyphs.gd:143`, `:154`; strip `seraph_dive` | art+code: feather sprites and the dive strip are art; the target mark is a disc + arc + cross | y | code | low | leave, or a 96 px ash-sigil decal |
| A31 | **Summon evolution transform glow** (Death Knight, Lich, Profane Bishop, Colossus ... when a chest evolves a class) | `summon_glyphs.gd:326` `draw_transform_glow` (called `summoned_unit.gd:1264`); rings `summon_evolutions.gd:194-195`, `:251`, `:265-266`; the spell evolution's two rings under its `evolution` strip, `ability_manager.gd:644-645` | code: a translucent rect column, a growing disc and a 2 px arc; the spell evolution has art (`effects/evolution`) but the summon one does not | y | code | medium (rare, about five per run and 0.5 s each, but it is the reward moment of a chest) | reuse / tint the `evolution` strip (10 x 192 px) and add a 6 x 128 px `transform` column strip |
| A32 | **Summon spawn rings** that are not the director's (Raise Dead revive, Death Knight shield, unit revive) | `summoned_unit.gd:734`, `:737`; `summon_evolutions.gd:265` (SPAWN, no anim) | code SPAWN: 2 px arc + a line | y | code | low | pass `"summon_rise"` (the strip exists and is used for normal summons) |
| A33 | **Barrier arc / Unholy Host aura / Bishop aura pulse** on summons | `progression_glyphs.gd:161`, `:168`; `summon_abilities.gd:103-104` (RING x2) | code: a 2 - 4 px arc in front of a Warrior, a violet halo disc on hosted units, two pulse rings | y (per unit) | R3, not kept | low - medium | `barrier_arc` sprite 32 x 16 px, a halo disc via `SpriteBank.draw_disc` (already batched) |
| A34 | **Synergy activation ring** | `synergy_manager.gd:229` | code RING at the necromancer (100 px, 0.6 s) | y | code | low | `synergy_flare` strip, 8 x 192 px |
| A35 | Winter Revenant extra rings | `winter_revenant.gd:106`, `:138` | art+code: strips `frost_shatter`, `frost_nova` plus a second code ring each | y | code | low | drop the second rings |
| A36 | Gravebow / Cathedral Horror / Reaper effects | `gravebow_kit.gd:52` (RING), `summon_evolutions.gd:251` | code rings per proc | y | code | low | small `curse_pop` strip 6 x 96 px |
| A37 | **Character innate effects** (Voidcaller Echoing Dark: a delayed echo burst r ~ 150 px, Plague Scholar Contagion spread, Bone Oracle shard block) | `character_innates.gd:261` (RING, no anim), `:297`, `:196` (POP), `:316` (a 2 px telegraph arc) | code: a ring per burst, a telegraph arc, a small pop; the orbiting shards are art (`markers/oracle_shard`) behind a code glow disc | y | code | low - medium (only the characters that own them) | `echo_burst` strip 8 x 192 px and a 24 px contagion pop strip |

### 1c. Act I stage AoEs, telegraphs and hazards

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| A40 | **Holy zones** (Chaplain consecrations r 85 px / 45 s; Alaric's Consecrated Ground r 62 px / 10 s): the main Graveyard hazard | `stage_director.gd:568` `_draw_zone` (state: arming `:571-573`, armed `:577-585`) | code: gold 10 - 22% discs, 48-seg ivory arc, inner arc, 8 rotating spokes, a small rect cross in the centre | y (2 discs + 2 arcs + 8 lines + 2 rects per zone, per frame) | `pestilence_holy_zones`, `holy_zone_boulder_rings`, `templar_lane_holy_zones` | **high** | two strips: `holy_zone_arm`, 6 frames x 192 px (the sigil draws in) and `holy_zone`, 4-frame loop x 192 px (radiant circle with cross glyphs); 2 sizes (r 62 and 85) from the same art at fill 1.0 / 1.4 |
| A41 | **Rally / Judgment / Call marks** (Alaric's Call to Arms and Judgment of the Dead; Vael's Command points) | `stage_director.gd:642` `_draw_mark` (+ `boss_alaric.gd:396`, `boss_vael.gd:349`: SPAWN rings, no anim) | art+code: the pennant has art (`markers/rally_pennant`); the rally ring and the Judgment disc (ivory 8 / 22% discs, 2 px arc, 8 gold ticks) are code | y | code | medium | `judgment_mark` strip 8 x 128 px (an ivory sigil that closes in over the telegraph time), `call_ring` 6 x 96 px |
| A42 | **Consecration grave** target ring + channel arc (Chaplain channelling) | `stage_director.gd:590` `_draw_grave` | art+code: the grave is art (`structures/consecration_grave`); a gold 1.5 px ring and a 4 px gold progress arc | y | R3, not kept | low (progress arcs stay code by design) | leave |
| A43 | **Necromancer shrines** (claim radius ring, disc at 1.6 x radius) | `stage_director.gd:610` `_draw_shrine` | art+code: shrine sprites exist; a 6 - 12% green disc and a 2 px ring around it | y | code | low | a 96 px sigil decal under each shrine |
| A44 | **Alaric telegraphs**: Hammer (circle), Charge (lane), Consecrate (ring) | `boss_alaric.gd:252`, `:288`, `:358` -> `Effect.TELEGRAPH_CIRCLE / LINE` and RING (no anim); impact `:260` has the `holy_impact` strip | code: 12% fill + a growing 28% fill + a 2 px outline | y | code (the same shapes as the Templar lane in `templar_lane_holy_zones`) | **high** (every Alaric fight, three attacks) | shared telegraph set, see A60 |
| A45 | **Alaric Wrath halo** (below half HP) | `boss_alaric.gd:488` `_draw_under` | code: a 14% flame disc + a 2 px gold arc under him | y | code | medium | `wrath_halo` loop 4 x 96 px under the sprite |
| A46 | **Boss death burst** (Alaric, Vael, and Seraphine on top of her `relic_shatter`: a 120 px gold flash) | `enemy_director.gd:914` `impact(..., GOLD)` (no anim) | code IMPACT: a 45% disc + an ivory arc | y | code | medium (once, but it is the victory beat) | pass `holy_impact` (exists) or a `boss_death` strip 10 x 256 px |
| A47 | **Marshal Vael**: cleave (cone telegraph + slash + impact), Holy Standard ring, Last Stand | `boss_vael.gd:273` (cone), `:292-293` (SLASH + IMPACT, no anim), `:367` (RING), `:260`, `:380`, `:392` | code: a 28% cone fill, a 2.5 px slash arc, flame discs | y | `vael_standard_ring` (the Standard's ring and his flame slash); the cleave cone was not caught | **high** (the Crimson March boss) | cleave slash strip `vael_cleave`, 8 frames x 192 px (a crescent of flame), standard ring -> `standard_ring` 8 x 256 px |
| A48 | **Zone change veil** on the March (a 75% rect fog plus 10 drifting 90 px discs, and a 420 px gold / crimson ring) | `march_director.gd:351` `_draw`, `:105` | code: one rect the size of the view plus 10 `draw_circle`s | y (11 shapes for the 1 - 3 s of a zone change, 3 times a run) | R5 at 781 s (flat 90 px discs), not kept | medium | smoke-bank sprites (3 variants, 192 px, tiled with soft alpha) and a ring strip |
| A49 | **Banner Bearer / Holy Standard aura reach** (r 110 px) | `march_glyphs.gd:189` `draw_aura`, from `enemy.gd:1166` | code: a 3.5% gold disc and a 1 px arc, under every Banner Bearer | y (per bearer) | `vael_standard_ring` (the ring at normal strength is fainter), R4 | low (intentional faint ring) | leave, or a 64 px dotted ring texture |
| A50 | **Structure destroyed** burst (outposts, generators, carts, watchtowers; crystals, altars) | `march_director.gd:281` (`impact` FLAME 60 px), `sanctum_director.gd:253`, `:311` (IMPACT 50 / 70 px, no anim); outpost reinforcement SPAWN `march_director.gd:265` | code IMPACT: a 45% disc + an ivory arc | y | code | medium (every structure kill) | `structure_break` strip, 8 x 192 px (dust, splinters, an ember flash), tinted per stage |
| A51 | **Sanctified Sentinel sweep** (cone telegraph + gold slash + ring) | `sentinel_kit.gd:47`, `:78`, `:80`; `sanctum_glyphs.gd:201` wind-up arm | code: cone fill, a 2.5 px gold slash arc, an ivory ring | y | code | medium | cone telegraph (A60) + `sweep` crescent strip 6 x 128 px |
| A52 | **Radiant Inquisitor suppression / holy zones** (r 160 px, arming then sealed) | `suppression_field.gd:199`, `sanctum_glyphs.gd:257` `draw_suppression`; ring `suppression_field.gd:130` | code: a gold arming disc, a sealed ivory circle, two rim arcs, ten rotating crosses drawn as line pairs, an inner arc | y (2 discs, 3 arcs, 20 lines per field) | `suppression_arming_chamber` | **high** | `suppression_seal` strips: arm (6 x 256 px) and a 4-frame loop (256 px, ring of cross glyphs); one art for every suppression (Inquisitor r 160, Seraphine r 220) |
| A53 | **High Confessor** revival pillar, holy shield bubble, casting sunburst | `covenant_rites.gd:203` + `sanctum_glyphs.gd:242` `draw_revive_pillar` (gold + ivory rects, an 18 px disc, a progress arc); `:174` `draw_holy_shield` (flat 12% disc + two arcs); `:211` `draw_casting` | code: tall rect column, flat disc bubble | y | code (Confessors were in R5, no pillar caught) | **high** (pillar: every revival, up to 3 at once; shield: on shielded allies) | `revive_pillar` loop 6 x 64 x 96 px (rising light column), `holy_shield` overlay sprite 40 x 40 px with a 2-frame shimmer |
| A54 | **Sun Paladin ward aura** (r 110 px) | `paladin_kit.gd:47` -> `sanctum_glyphs.gd:191` | code: a 3% gold disc, a 1 px arc, 12 short ray lines | y | R5 (faint), not kept | low - medium | 64 px dotted sun-ring texture |
| A55 | **Cathedral Guardian** (miniboss): slam telegraph (circle), slam impact, sweeping beam (cone telegraph + beam), raised glowing fists | `guardian_kit.gd:157`, `:167` (strip `holy_impact`), `:205`, `:262`; `sanctum_glyphs.gd:220` `draw_guardian_fists`, `:230` `draw_beam` | art+code: slam impact is art; the beam is three stacked `draw_line`s and a disc, the telegraphs and fists are code | y | `guardian_beam` | **high** (miniboss, one per run, beam 340 x 24 px) | `guardian_beam`: tileable 32 x 24 px core + 24 x 24 px end cap with a 4-frame flow; telegraphs A60 |
| A56 | **Sister of the Scourge** lash wind-up and zeal | `sister_kit.gd:139-140`, `:209-211`; `sister_glyphs.gd:53`, `:65` | code: two crimson / gold lines, a dot, a 2 px flame ring | y | code | medium | a 62 x 12 px whip sprite swing (4 frames) |
| A57 | **Sanctified chambers** (r 220 px holy circle with ward crystals; two of them for most of the run) | `sanctum_director.gd:472` `_draw_chamber`; spawn ring `:168` | code: a pulsing 7 - 10% gold disc, ivory 2 px rim, a gold inner arc, 12 rotating 6 px squares, line beams from each crystal, a centre disc | y (2 discs, 2 arcs, 12 rects, up to 2 lines per chamber, per frame) | `sanctified_chamber`, `suppression_arming_chamber` | **high** (largest persistent AoE in the game, always on screen in the Sanctum) | one 512 px ground decal (holy circle: mosaic ring, gold inlay, rune marks) with a 2-frame slow glow + crystal beams as the Eclipse-style sprite tile (16 x 4 px) |
| A58 | **Cleansed chamber** (violet rot stain with cracks) | `sanctum_director.gd:489` `_draw_cleansed`; ring `:288` | code: 30% robe disc, violet 2 px arc, 7 green polyline cracks | y | code | medium | 512 px stain decal ("rotted marble") fading in; can reuse the chamber decal with a rot palette swap |
| A59 | **Sacred altar sigil** (floor circle round each altar) | `sanctum_director.gd:501` `_draw_altar_sigil` | code: a 6 - 10% gold disc, a 1.5 px arc, 4 rotating lines | y | code | low - medium | 128 px sigil decal |
| A60 | **Shared telegraphs**: `telegraph_circle`, `telegraph_line`, `telegraph_cone` (Alaric hammer / charge, Vael cleave, Seraphine fan and circles, Sentinel sweep, Guardian slam / beam, the Templar charge lane `enemy.gd:944`) | `effect.gd:108`, `:113`, `:126` | code: 12% fill, a growing 28% fill, a 2 px outline (polygon lane, 17-point cone) | y (up to 3 polygons + polyline per telegraph) | `templar_lane_holy_zones` (lane), `seraphine_fan_cone` (cone) | **high** (every boss and elite attack; one fix covers the 9 Act I call sites) | a tile-based set: a hatched-warning fill texture (32 x 32 px, tiled, masked to the shape by drawing it as a disc / strip / cone of tiles), an edge crest tile (16 x 8 px) along the outline, and a 6-frame impact flash; the `holy_impact` strip already closes the attack |
| A61 | **Dawn's Wrath** (Sanctum Reckoning: gold light pooled round the necromancer, six turning shafts) | `sanctum_director.gd:513` `_draw_dawn` | code: four concentric 4% discs up to 520 px, six 4-point polygon shafts | y (4 discs + 6 polygons, the whole Reckoning) | R5 at 1215 s (faint discs and shafts), not kept | low - medium (very faint, it reads as lighting) | a 512 px radial light texture + one 64 x 480 px shaft sprite (additive), rotated |
| A62 | **Seraphine: nova** (640 px gold glow with 3 pulse rings, cold-blue safe circles, afterglow) | `seraphine_hazards.gd:445` `_draw` (:450-464); strip `seraphine_nova` | art+code: the 512 px strip plays at the end; the telegraph (the gold disc, pulse arcs 3 - 4 px, dark safe holes, blue safe discs) is code | y | not caught (the nova needs her to live past her phase 2; R5 and R8 killed or missed it); read in code | **high** | `nova_field` 512 px loop (heat shimmer) and a `safe_circle` 128 px sprite (a cold-blue sanctuary with the existing cross) |
| A63 | **Seraphine: judgment beams** (rotating golden beams over the arena) | `seraphine_hazards.gd:513` `_draw_beams` (:522-540) | code: lines, side hairlines, three polygons (glow, body, flicker), a tip disc, a 1.5 px range arc; beam wind-up arrows | y | R8 at 1054 s (beam lines and range arc), not kept | **high** | `beam_core` tile 32 x 24 px + `beam_head` 48 x 48 px with a 4-frame flow, `holy_beam` strip already exists for the ignition |
| A64 | **Seraphine: collapsing arena** (fire band, flames along the edge) | `seraphine_hazards.gd:545`, `:555`, `:575` `_annulus` | code: `RING_SEGMENTS` `draw_polygon` quads for two fire gradients, two arcs, `FLAME_TONGUES` double polygons, redrawn every frame; the heaviest polygon user in Act I | y (dozens of polygons per frame) | `seraphine_collapse_band_aura` | **high** | a flame-edge tile strip (48 x 32 px, 6 frames, drawn along the circle like the Undertow crests) over a scorch gradient texture (the shared disc texture ring) |
| A65 | **Seraphine: teleport mark, hazard circles, fan cone, suppression** | `seraphine_hazards.gd:498` `_draw_teleport_mark`, `:161` (circle telegraph + `holy_impact`), `boss_seraphine.gd:462` (cone), `:744` | code: ivory / gold discs and arcs, a trapezoid polygon | y | `seraphine_fan_cone`; teleport marks in R5, not kept | medium | `teleport_mark` strip 8 x 128 px, circles and cone via A60, suppression via A52 |
| A66 | **Seraphine aura and glow** (phases 2 - 3: gold / ivory halo, 14 flame lines and a ring in the Last Light; the teleport bloom) | `seraphine_glyphs.gd:80` `_draw_aura`, `:151` `_draw_glow`, called every frame from `:38` | art+code: her sprites and poses are art; the aura is two discs, 14 3 px lines and an arc, the bloom a disc and an arc | y | `seraphine_collapse_band_aura` (the gold Avatar halo) | **high** (final boss, on screen the whole phase) | `seraphine_aura` loop 6 x 192 px behind her (two variants: Avatar halo, Last Light flames), `bloom` 8 x 192 px |

## 2. Units and bosses

Every Act I and shared unit, boss, miniboss and playable character has its pixel-art still (the
`[art-miss]` report names no unit key). What is left is walk strips and code layers drawn with the
sprite.

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| U01 | **Sanctum Covenant kinds without a walk strip**: Sanctified Sentinel, Radiant Inquisitor, High Confessor, Sun Paladin, Cathedral Guardian | `SpriteBank.draw()` (`sprite_bank.gd:262`), keys `enemies/<kind>`; `ArtMissLog` in R5: `sanctified_sentinel_walk` 11392 draws, `cathedral_guardian_walk` 5735, `sun_paladin_walk` 1230, `high_confessor_walk` 471, `radiant_inquisitor_walk` 368 | art: a still sprite that only bobs (the Recruit, Footman, Archer, Chaplain, Purifier, Templar, Shieldbearer, Banner Bearer, Halberdier and Battle Sister all have 8-frame strips) | n | log (R5) | medium (the Sentinels and Guardians are big slow bodies that slide; the Sanctum's late roster) | 8-frame walk strips with `walk_cycle.py` rigs, at the stills' size (Guardian 64 px, others 40 - 48 px) |
| U02 | **Summon classes without a walk strip**: Corpse Abomination, Bone Colossus, Crypt Gargoyle, Cathedral Horror (and its stone form), Frost Wraith, Winter Revenant, Corpse Catapult, Ossuary Engine, and the Profane Bishop (static check; the Bishop was not in a run) | `summons/<key>` (`ArtMissLog` draws in R3: `cathedral_horror_stone` 30095, `bone_colossus` 18459, `ossuary_engine` 16919, `cathedral_horror` 15199, `corpse_catapult` 7813, `gargoyle` 7146, `winter_revenant` 6879, `abomination` 6051, `frost_wraith` 3433) | art: a still sprite that bobs, next to classes whose 8-frame walk strips exist (Warrior, Archer, Mage, Mender, Warder, Rogue, Bone Hound, Banshee, Death Knight) | n | log | medium for the walkers (Abomination, Bone Colossus: heavy bodies that slide), low for the flyers and the catapults | 8-frame walk strips at the stills' sizes (hover rig for Gargoyle, Cathedral Horror, Frost Wraith, Winter Revenant; the engine's rigs exist) |
| U03 | **Sir Alaric, Marshal Vael and the Reckoning Inquisitor have no walk strip** (Seraphine has walk, idle and glide strips); the bosses' attack poses exist (`_windup`, `_strike`, `_charge`, `_guard`) | `bosses/alaric`, `bosses/vael`, `enemies/inquisitor` (`ArtMissLog`: `bosses/alaric_walk` 1067 draws, `bosses/vael_walk` 675, `enemies/inquisitor_walk` 1500 - 1683) | art: a still + bob; the Inquisitor is the executioner of every stage's Reckoning (the last 3 - 5 minutes of every run) | n | log (R1, R2) | medium (the Inquisitor, in every run's finale) / low (the two bosses, which move little) | 8-frame walk strips (Inquisitor 48 px; Alaric and Vael 56 px) with `walk_cycle.py` |
| U04 | **Chill film** on foes slowed by a Frost Wraith | `summon_glyphs.gd:475` `draw_chill`, from `enemy.gd:1217` | code: a 22% frost disc, an arc and two ice ticks, per chilled foe, per frame | y (per foe: many in a Frost build) | code | medium | a 32 x 32 px frost-film overlay sprite (batched), 2-frame shimmer |
| U06 | **Gravebow curse tint** on cursed foes | `gravebow_colossus_glyphs.gd:165` | code overlay | y | code | low | a small violet-curse overlay sprite 24 px |
| U07 | **Stone form shell** (Cathedral Horror) | `reaper_horror_glyphs.gd:132`, only when `stone_key()` has no art | fallback only (the stone sprites exist) | n | - | none | none |

## 3. Structures, obstacles and floors

Every structure, obstacle kind and zone floor of the three stages has pixel art; the code in
`arena.gd:442-508` (obstacles), `ground.gd`, `march_ground.gd`, `sanctum_ground.gd` is a fallback
that never runs with the PNGs present. What still draws in code is the ground around them.

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| T01 | **Graveyard fog patches** (about one cell in nine, r 40 - 70 px) | `ground.gd:151` `draw_circle(p, 40 + h % 30, Palette.FOG)`; kept as code on the tile floor by `DecalData` ("a soft translucent effect") | code: a hard-edged flat teal disc, visible in every Graveyard screenshot | n (redrawn on a 256 px camera step only) | every Graveyard shot (`wither_plague`, `abomination_stomp`, `holy_zone_boulder_rings`) | medium (looks like a flat circle, not fog) | 3 soft fog decals, 112 / 128 / 144 px, dithered feathered edge, 18% alpha, drawn like the other decals |
| T02 | **Fortress Approach tower shadows** (March zone IV) | `march_ground.gd:220` (a 60 - 90 x 18 px rect at 18% black, code by `DecalData`) | code: a flat dark rectangle | n | code | low | 96 px shadow decal |
| T03 | **Final Sanctuary light pools** (Sanctum zone IV) | `sanctum_ground.gd:256-262` (translucent rhombus and pools, code by `DecalData`) | code: flat translucent coloured shapes | n | code | low | 3 light-pool decals, 128 px |
| T06 | **Obstacles** (26 kinds x 2 - 3 sizes, both orientations) | `arena.gd:442` `_draw_obstacle` only without the PNG | art | n | log | none | none |
| T07 | **Zone floors and decals** (graveyard, 4 March zones, 4 Sanctum zones) | `ground.gd`, `march_ground.gd`, `sanctum_ground.gd` | art (tiles + decals); `ArtMissLog` printed no tile or decal key | n | log | none | none |

## 4. Projectiles and shots

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| P01 | Every Act I projectile kind (Shadow Bolt, Arrow, Mage Orb, Priest Bolt, Enemy Arrow, Void Bolt / Shard, Frost Bolt, Radiant Bolt), Bone Spear, Ossuary Lance, Orb, Eclipse Orb, Oracle Shard, Corpse Boulder (+ burning), Seraph Feather | `projectile.gd:90` `SpriteBank.draw_flat`; the 100 lines after it are the fallback | art | n | log | none | none |
| P02 | **Gravebow curse trail** under arrows | `projectile.gd:87-88` | art+code: a 4.5 px violet line and a dot behind the arrow sprite | y | code | low | a 24 x 8 px curse-trail sprite |
| P03 | **Volleys** (the bullet heaven pass): 7 shot styles | `volley_director.gd:577` | art: a tinted grey mask per style (`volleys/*.png`), glows as batched discs; the code shapes at `:612-630` only without the PNG | n | log | none | none |
| P04 | Soul Round / Scrap Bolt / Iron Shell | `projectile.gd:131`, `:46`, `:50` | code (no PNG), Act III Grave Gunners and Empire kinds | y | code | n/a here | belongs to the Act III audit |

## 5. Pickups and chests

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| K01 | XP crystals (3 sizes), power-up medallions (6), treasure chest, chest beacon + badge | `xp_crystal.gd:31`, `powerup_glyphs.gd:32`, `chest.gd:42`, `chest_beacon.gd:250` | art; each draws a 10 - 18% glow disc / shadow disc under the sprite | y (one `draw_circle` per pickup per frame; hundreds of crystals) | every shot | low (it reads as a glow) | swap the glow `draw_circle`s for `SpriteBank.draw_disc` (batched, Web cost) rather than new art |
| K02 | Chest open burst, evolution, level-up | `game.gd:872`, `:908` | art strips | n | - | none | none |

## 6. Other

| id | what it is | where drawn | current look | per-frame polygon | seen | noticeable | proposed fix (art px) |
|---|---|---|---|---|---|---|---|
| O01 | **Slash arcs** (every melee swing of a Warrior, Rogue, Abomination, Catapult, Footman, Halberdier, Sentinel, boss cleaves) | `effect.gd` `Kind.SLASH` (2.5 px arc), from `summoned_unit.gd:886`, `:1170`, `enemy.gd:974`, `:1104`, `:1130` | code: one thin arc, 0.2 - 0.3 s | y | R3 (thin arcs), not kept | low - medium (ubiquitous but small) | `slash` strip, 5 frames x 64 px, tinted per caller |
| O02 | **Heal / chain beams** (Mender, Chaplain, Confessor, Golem) | `effect.gd` `Kind.BEAM` from `summoned_unit.gd:1197`, `enemy.gd:1145`, `confessor_kit.gd:105` | code: a line plus a dot | y | R3, not kept | low - medium | a 16 x 6 px beam tile with a 4-frame flow |
| O03 | **Small POP / SPAWN / RING effects** on hits and spawns (e.g. violet 6 px hit pop, spawn rings of Sanctum rites and boss calls) | `projectile_manager.gd:331-361`, `boss_seraphine.gd:389`, `:447`, `:571`, `:611`, `boss_alaric.gd:396`, `covenant_rites.gd:189-190` | code: small arcs | y | code | low | pass the existing `summon_rise`, `enemy_death`, `bolt_impact` anim ids |
| O04 | **Particles** (`Juice.fx.burst`: squares) | `fx_layer.gd:243` | code: coloured squares (a pixel-art-compatible look) | n | every shot | none (intentional) | none |
| O05 | **Dread meter / vignettes, the Reckoning** | `dread_vignette.gd`, `hurt_vignette.gd`; the Reckoning spawns regular sprite kinds | n/a (HUD overlays, Act II) | n | - | none | none |
| O06 | Sprite keys referenced but with no PNG in the whole tree | string-literal scan of `scripts/` against `assets/sprites/` | Act II / III only: `decals/spire_breakwater_barnacles`, `markers/inscription`, `markers/scribe_curse`, `projectiles/scrap_drone` (and the `eye/` / `empire/` kinds the Act II and III audits cover) | n | - | outside this audit | belongs to the Act II / III audits |
| O07 | **Necromancer ground ring** (always on) and the **priest ward bubble** (Warder / Mender shield on the player) | `necromancer.gd:264` `_draw_ground_ring`, `:251` `_draw_over` | code: a squashed 12% green disc and a 1.5 px arc (a readability aid, `ViewData.PLAYER_RING_*`), a flat 10 - 20% blue disc with a green 1 - 3 px arc for the ward | y | every shot | low (the ring is a UI marker by design; the ward bubble is a flat disc) | a 48 x 22 px soft ground ring sprite; a 56 px ward bubble sprite with a 2-frame shimmer (the Eclipse orb pattern) |

## 7. Top 15 to fix (by what a player sees most, weighted by how many sites one asset fixes)

1. **A60 shared telegraphs** (circle, lane, cone): one tile-based set fixes every boss and elite warning in all three stages (9 call sites in Act I, and Acts II and III call the same three `Effect` kinds).
2. **A40 holy zones** (Chaplain consecrations and Alaric's Consecrated Ground): the Graveyard's signature hazard, flat gold discs with a hand-drawn cross (`pestilence_holy_zones`, `templar_lane_holy_zones`).
3. **A57 / A58 sanctified and cleansed chambers** (r 220): the biggest persistent AoE in the game, on screen for most of the Sanctum (`sanctified_chamber`).
4. **A01 / A02 Plague Cloud and Pestilence**: the most-seen spell AoE of any evolve / spell build, overlapping flat discs (`wither_plague`, `pestilence_holy_zones`).
5. **A04 Wither / Necrotic Blight aura**: flat disc and dashes on the necromancer for the whole run (`wither_plague`).
6. **A52 suppression seals** (Radiant Inquisitor r 160, Seraphine r 220): ten line-pair crosses and flat discs (`suppression_arming_chamber`).
7. **A62 - A66 Seraphine**: nova field and safe circles, beams, collapsing arena fire band (dozens of polygons a frame), aura and bloom; the final boss's whole hazard set is code (`seraphine_fan_cone`, `seraphine_collapse_band_aura`).
8. **A55 Cathedral Guardian**: beam (three lines), fists, telegraphs: the Sanctum miniboss (`guardian_beam`).
9. **A11 Mage splash ring**: the most frequent AoE of a default army, a faint violet disc + ring on every volley.
10. **A20 / A21 Abomination stomp and Bone Colossus stomp**: ring and wind-up disc (`colossus_stomp_rings`, `abomination_stomp`).
11. **A27 Hellhound fire patches** and **A26 shard fields / boulder rings**: flat ember discs and dark discs under a pack (the boulder rings are in `holy_zone_boulder_rings`).
12. **A47 Marshal Vael cleave and Standard ring**, **A46 boss death burst**: the Crimson March boss's attacks are a slash arc and a flat flash (`vael_standard_ring`).
13. **A31 summon evolution transform glow**: the reward moment of a chest (about five a run) is a translucent rect and a disc.
14. **A53 Confessor revival pillar and holy shield**: gold rects and a flat bubble.
15. **A22 / A23 / A24 Deep Freeze, Gargoyle dive, Banshee wail** impacts (one strip each) and **T01 Graveyard fog patches** (hard-edged flat discs in every Graveyard frame).


## 8. Asset families (how the rows group into work)

The same few pieces of art would fix most rows, which keeps the generation budget small (the Harbour
pass made 20 decals from two sheets and four AI sprites):

| family | rows it fixes | pieces (art px) |
|---|---|---|
| **Telegraph set** (circle, lane, cone) | A60, A44, A47 (cone), A51, A55 (circle and cone), A56, A28 (lane), A62 - A65 (circles, cone), the wind-up discs of A20 - A24 | a hatched warning-fill tile 32 x 32, an edge crest tile 16 x 8, a 6-frame impact flash 128 |
| **Sanctified ground** (Covenant holy circles) | A40, A41, A42, A52, A54, A57, A58, A59, A43 | one holy-circle ground decal 192 and one 512, an arming strip (6 x 192), a looping seal (4 x 256), a rot-stained 512 variant, a 64 x 96 light-pillar loop, a 40 px shield overlay |
| **Spell zone loops** | A01, A02, A04, A05, A10 | cloud loop 6 x 192 / 256, a sigil-aura loop 4 x 256 (Wither and Blight tints), an eruption field 6 x 192, a ring-band texture 256 |
| **Summon special impacts** | A11, A20, A21, A22, A23, A24, A26, A29, A31, A34, A37 | one impact strip each, 8 x 128 - 192 (stomp, freeze bloom, dive dust, wail ripples, boulder crater, transform column, splash), tinted per class |
| **Fire and field patches** | A26 (shard field), A27 (Hellhound fire) | a looping flame patch 4 x 48 (3 variants), a crater decal 96 |
| **Boss specials** | A45, A46, A47, A55, A62 - A66 | Seraphine aura loops 6 x 192, a beam tile 32 x 24 plus head 48, a flame-edge tile strip 48 x 32, Vael cleave crescent 8 x 192, a boss-death strip 10 x 256 |
| **Small effect strips** | A03, A07, A08, A12, A13, A14, A25, A32, O01, O02, O03 | slash 5 x 64, beam tile 16 x 6, siphon pulse, curse pop |
| **Walk strips** | U01, U02, U03 | 8-frame strips for 5 Sanctum kinds, 9 summon bodies, Alaric, Vael, the Inquisitor (a `walk_cycle.py` job, no generation) |
| **Cheap code changes** (no art) | K01, T01 (use the soft fog decal), A32, A35, A06, A13 | swap `draw_circle` glows for `SpriteBank.draw_disc`, pass existing anim ids to `spawn_ring` / `ring`, drop the duplicate code rings under existing strips |

## 9. Screenshots

Crops of 1280x720 windowed frames (game pixels, quantised to 128 colours to keep the files small), under
`docs/art/audit/act1_shots/`. Each shows a code-drawn AoE next to pixel art.

| file | run, game second | what it shows | rows |
|---|---|---|---|
| `wither_plague.png` | R1, 330 | a Wither aura (dashed rim) and Plague Clouds over the flat teal fog patches | A01, A04, T01 |
| `pestilence_holy_zones.png` | R1, 660 | an evolved Pestilence cloud (stacked discs) and Chaplain holy zones | A02, A40 |
| `abomination_stomp.png` | R3, 320 | the Abomination's stomp wind-up: flat flesh disc and bone rim | A20 |
| `holy_zone_boulder_rings.png` | R3, 640 | a holy zone, boulder splash rings and a landing disc | A40, A26 |
| `templar_lane_holy_zones.png` | R3, 880 | a Templar charge lane (polygon), holy zones | A60, A40 |
| `colossus_stomp_rings.png` | R3, 1160 | Bone Colossus stomp rings and the summons' flat translucent discs (a Winter Revenant frost nova is art) | A21, A35 |
| `vael_standard_ring.png` | R4, 1053 | the Holy Standard's flat gold ring (r 110) round Marshal Vael, his flame slash and a Frost Wraith nova | A47, A49 |
| `sanctified_chamber.png` | R5, 190 | the 220 px sanctified chamber: flat gold disc, ring, squares | A57 |
| `suppression_arming_chamber.png` | R5, 385 | an arming suppression circle and a chamber with its crystal beam | A52, A57 |
| `guardian_beam.png` | R5, 415 | the Cathedral Guardian's beam (three lines) | A55 |
| `seraphine_fan_cone.png` | R5, 1066 | Seraphine's fan cone telegraph | A65, A60 |
| `seraphine_collapse_band_aura.png` | R8, 1063 | the collapsing arena's fire band (a gradient and triangle flames) and her gold halo | A64, A66 |

## 10. Runs

All runs: `xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720
--fixed-fps 60 --quit-after N -- --autotest --speed=16 --art-misses --art-shots=T,... --shot-dir=DIR`
plus the flags below (seed 1337, non-mortal, fresh save, Gravecaller; the CI-style `--quit-after 15000` where a run was to finish, a shorter one where it was stopped after its shots). `--speed=16` and the shot lists
only change how fast the run goes and when the window is saved; they are drawing-only flags. Raw
screenshots stay out of the repository; the 12 kept ones are crops in `act1_shots/`.

| run | flags | what it was for | `[art-miss]` |
|---|---|---|---|
| R1 | `--stage=graveyard --policy=evolve --spells=corpse_explosion,plague_cloud,wither,bone_wall,soul_chains`, 26 shots 240 - 1260 s | the spell AoEs and their evolutions (Pestilence, Blight, Charnel Bastion), holy zones, Alaric, the Reckoning | 0 missing keys; strip gaps: `bosses/alaric_walk`, `enemies/inquisitor_walk` |
| R2 | `--stage=crimson_march --policy=evolve --spells=death_mark,soul_siphon,bone_spear,raise_dead,shadow_blast`, 26 shots | Crimson March zones, outposts, Vael, Raise Dead / Death Mark | 3 "missing" `tiles/march_road_<zone>` (optional per-zone road overrides, fall back to `tiles/march_road`); strip gaps: `bosses/vael_walk`, `enemies/inquisitor_walk`, five structure keys (stationary) |
| R3 | `--stage=graveyard --policy=summon --classes=abomination,gargoyle,frost_wraith,corpse_catapult,bone_hound --passives=bone_plating,unholy_resilience,soul_recycling,siegecraft,blood_scent`, 29 shots | summon specials and evolutions (Bone Colossus 8:31, Cathedral Horror 9:20, Ossuary Engine 10:15, Winter Revenant 10:51, Death Knight 13:20), Templar lanes, Alaric | 0 missing keys; 9 summon bodies without a walk strip (U02) |
| R4 | `--stage=crimson_march --policy=naive`, 37 shots 1018 - 1188 s (stopped after the shots) | Marshal Vael's fight | not printed (stopped early) |
| R5 | `--stage=sanctum --policy=naive --spawn=high_confessor@200x2,radiant_inquisitor@260x2,sun_paladin@330x2`, 61 shots | chambers, Guardian, Inquisitor suppression, zone change, Confessors, altars, Seraphine, Dawn's Wrath | 0 missing keys; strip gaps: the five Sanctum kinds (U01), `frost_wraith`, `inquisitor` (U03), two structures (stationary) |
| R6 | `--stage=graveyard --policy=army --speed=8`, 51 shots 40 - 132 s (stopped after the shots) | default-army effects (Mage splash) | not printed (stopped early) |
| R7 | `--stage=graveyard --policy=summon --classes=bone_hound --passives=blood_scent`, 45 shots 420 - 850 s (stopped there) | the Hound and the Hellhound's fire patches (12 Hellhounds by 9:20, Death Knight at 8:11) | not printed (stopped early) |
| R8 | `--stage=sanctum --policy=army --meta=max`, 55 shots 1018 - 1180 s every 3 s | Seraphine's later phases (beams, nova, collapse, Avatar and Last Light auras) with a build that kills her faster | not printed (stopped by the frame limit, 4600 frames) |

## 11. What was not checked or not caught

- Short effects (0.2 - 0.6 s) are only caught by luck at the shot interval, so **A14 (Dread Rally burst), A16 Soul Nova, A17 Grave Step, the Rogue dash lane (A28), the Gargoyle dive (A23), Deep Freeze (A22) and the Banshee wail (A24)** were read in the code, not seen.
- **Seraphine's Judgment nova (A62)**, Alaric's Wrath halo (A45), the Dirge mark (A25), structure-destroyed bursts (A50) and the cleansed-chamber stain (A58) did not happen in a shot window; they were read in the code. Her beams (A63) show only as thin lines in R8 at 1054 s.
- **Ultimates** (A15) and **character innates** (A37) were not run: the Sovereign's Decree, Eclipse and Grave Tide need their unlocks (the `--ultimate=` flag exists); they were read in the code.
- **Hyper mode and skins**: skins are keyed to character art that exists (`ArtMissLog` printed no skin key); not looked at one by one.
- **Windows and iOS / Android Web builds** draw the same code; the Web perf cost of each polygon row was judged from the code, not measured here.
- The report's `unit bodies drawn without a walk strip` lines for structures (`ward_generator`, `outpost`, `supply_cart`, `holy_standard`, `watchtower`) are noise: structures are stationary and need no walk strip.
- The three `tiles/march_road_<zone>` lines in the Crimson March report are optional per-zone road overrides that fall back to `tiles/march_road` (`EnvironmentArtData`), not missing art.


