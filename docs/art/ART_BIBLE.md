# Gravebound: Art Bible and ChatGPT Prompt Pack

This document defines how Gravebound's sprites are generated in ChatGPT, saved and wired into the game.
It is the single reference for every art request.

## Workflow

1. **Approve the style first.** Generate the **necromancer** with the two style prompts below (A and
   B), pick one, and save the chosen image as `assets/sprites/player/necromancer.png`. That image
   becomes the **style reference** for everything else.
2. **Generate the rest in small related batches** (e.g. Warrior, Archer and Mage together) using the
   *reference-matching template* at the bottom: attach `necromancer.png` and say "match this style".
3. **Process each PNG** with `python3 tools/prepare_sprite.py <downloaded image> <key>` (e.g.
   `summons/warrior`). It keeps the original in `art_source/` (ignored by Godot), crops the
   transparent border and writes a game-ready copy to `assets/sprites/<key>.png` at 3x its on-screen
   height (`scripts/data/sprite_data.gd`). Or just send the images to Claude to do it.
4. The game shows a sprite whenever the file exists, and otherwise keeps the current code-drawn
   shape. Art can arrive a piece at a time and the game never breaks. Movement, hit flashes, facing
   and shadows are animated in code, so **one still image per unit** is enough.

## Global rules (repeat these in every prompt)

- **View:** top-down three-quarter view (camera above and slightly in front), like Vampire
  Survivors or Diablo. The character's **full body** is visible.
- **Facing:** the character **faces right**. The game mirrors it for left.
- **Canvas:** square **1024 × 1024**, the subject **centered** and filling about 80% of the height.
- **Background:** **fully transparent** PNG. No ground, no cast shadow (the game draws its own), no
  scenery, no frame, no text, no watermark.
- **Readability:** sprites are shown at **40–128 px**. Use a **bold, simple silhouette**, a **thick
  dark outline**, large readable shapes, and no fine detail that disappears when small.
- **Lighting:** light from the top-left. Moody, but the subject must stand out against a very dark
  ground (`#161A1C`).
- **One subject per image.** No poses with motion blur. A neutral "ready" stance.

## Colour language (from `scripts/data/palette.gd`)

The undead side is **blue / violet / green / bone**; the Crimson Covenant is **crimson / ivory /
silver / gold**. Never mix the two sides' signature colours on one unit.

| Name | Hex | Used for |
|---|---|---|
| Bone | `#DED9C2` | skulls, skeletal limbs |
| Undead steel | `#6B7A94` | skeletal armour |
| Cold blue | `#619EFA` | warrior shields, frost-adjacent accents |
| Necro green | `#6BF28C` | archers, heals, soul fire |
| Violet | `#A35CFA` | shadow magic, mages |
| Necromancer robe | `#3D1F57` | the player's robe |
| Mender robe | `#295C5C` | Grave Mender |
| Warder robe | `#243B6B` | Crypt Warder |
| Bishop robe | `#451F61` | Profane Bishop |
| Death steel | `#30364A` | Death Knight armour |
| Lich robe | `#361A54` | Lich |
| Corpse flesh | `#788F6B` | Abomination |
| Rogue cloak | `#291A3D` | Grave Rogue |
| Gargoyle stone | `#758094` | Crypt Gargoyle |
| Frost | `#9ED6FF` | Frost Wraith |
| Crimson | `#C71A29` | Covenant tabards, banners |
| Dark crimson | `#730D17` | Covenant shadows, trim |
| Ivory | `#F5EDD4` | Covenant robes, holy cloth |
| Silver | `#CCD1DE` | Covenant armour |
| Gold | `#FFD14C` | holy trim, halos, elites |
| Flame | `#FF8C26` | Purifier fire, burning swords |

## Asset manifest

**Size** is the approximate on-screen height. Generate everything at 1024 × 1024 anyway.

### Player
| File | Subject | Size |
|---|---|---|
| `assets/sprites/player/necromancer.png` | The necromancer (style reference; prompt below) | 56 px |

### Summons (`assets/sprites/summons/`)
| File | Subject | Size |
|---|---|---|
| `warrior.png` | Skeleton warrior, undead-steel armour, round cold-blue shield, short sword | 44 px |
| `archer.png` | Skeleton archer, hooded, bone bow, green soul-fire arrow nocked | 44 px |
| `mage.png` | Skeleton mage, tattered violet robe, staff with a violet orb | 44 px |
| `mender.png` | Grave Mender: teal-robed skeletal priest, green halo, bone censer | 44 px |
| `warder.png` | Crypt Warder: cold-blue-robed skeleton holding a glowing ward sigil | 44 px |
| `bishop.png` | Profane Bishop: tall violet vestments, bone mitre, green-and-blue halo | 52 px |
| `death_knight.png` | Death Knight: massive death-steel plate, skull helm, greatsword, violet eye glow | 52 px |
| `lich.png` | Lich: crowned skeletal sorcerer, deep violet robe, floating phylactery | 52 px |
| `abomination.png` | Corpse Abomination: huge stitched hulk of grey-green corpse flesh, bone spikes | 88 px |
| `rogue.png` | Grave Rogue: lean skeleton in a dark hooded cloak, twin curved daggers | 44 px |
| `gargoyle.png` | Crypt Gargoyle: stone gargoyle, wings half-spread, long claws | 56 px |
| `frost_wraith.png` | Frost Wraith: icy translucent spectre, tattered robe trailing into mist | 48 px |
| `risen.png` | Lich-raised temporary skeleton: plain, ragged, faint violet glow | 36 px |
| `winter_revenant.png` | Winter Revenant (Frost Wraith evolution): a towering crowned ice wraith in tattered frost robes, a staff of black ice, pale blue (`#9ED6FF`) glow; pixel art, faces right, transparent background | 56 px |
| `shadow_reaper.png` | Shadow Reaper (Grave Rogue evolution): a hooded skeletal assassin wreathed in shadow, bone skull mask with violet (`#A35CFA`) eyes, twin curved scythe-blades (one forward, one swept back), violet trailing smoke behind it, deep rogue-cloak violet-black (`#291A3D`) | 48 px |
| `cathedral_horror.png` | Cathedral Horror (Crypt Gargoyle evolution): a huge winged stone gargoyle torn from a cathedral, cracked pale marble body, wide ribbed stone wings, ram horns, violet (`#A35CFA`) glowing runes carved into its chest, gripping a broken plinth; clearly bigger and bulkier than the Crypt Gargoyle | 64 px |
| `gravebow.png` | Gravebow (evolved archer): an ornate skeletal archer in a tall tattered dark-green hood (`#2B453D`) with a ragged hem, violet (`#A35CFA`) eye glow, a bone quiver; it draws a HUGE bone longbow (`#DED9C2`, taller than itself, bone spikes at the tips) with an arrow wreathed in violet curse-fire nocked. Bigger and more ornate than `archer.png` | 52 px |
| `bone_colossus.png` | Bone Colossus (evolved abomination): a towering hulk of grey-green corpse flesh (`#788F6B`) armoured in fused bone plates (`#DED9C2`): a ribbed bone breastplate, spiked bone pauldrons, a horned bone helm over a small skull with green (`#6BF28C`) eyes, a bone-slab club for an arm, thick plated legs. Clearly bigger and more armoured than `abomination.png` | 100 px |

### Covenant enemies (`assets/sprites/enemies/`)
| File | Subject | Size |
|---|---|---|
| `recruit.png` | Covenant Recruit: young soldier, crimson tabard, spear, light helm | 40 px |
| `footman.png` | Crimson Footman: heavy silver armour, crimson kite shield, sword | 48 px |
| `archer.png` | Zealous Archer: ivory-and-crimson archer with a longbow | 40 px |
| `chaplain.png` | Covenant Chaplain: ivory robes, gold censer, healing glow | 42 px |
| `purifier.png` | Purifier: silver mask, flaming torch / flamethrower censer | 44 px |
| `templar.png` | Templar Knight: gold-trimmed heavy knight, lance, crimson cape | 52 px |
| `inquisitor.png` | Inquisitor of the End (Reckoning): towering, radiant gold, faceless | 64 px |
| `shieldbearer.png` | Covenant Shieldbearer: huge crimson tower shield | 50 px |
| `banner_bearer.png` | Banner Bearer: tall crimson-and-gold war banner | 50 px |
| `halberdier.png` | Crimson Halberdier: long halberd, silver half-plate | 50 px |

### Bosses (`assets/sprites/bosses/`)
| File | Subject | Size |
|---|---|---|
| `alaric.png` | Sir Alaric, the Gravebreaker: giant paladin, holy warhammer, gold and ivory | 120 px |
| `vael.png` | Marshal Vael, the Crimson Bulwark: great kite shield, flaming sword, crimson plume | 120 px |

### Structures (`assets/sprites/structures/`)
| File | Subject | Size |
|---|---|---|
| `outpost.png` | Siege outpost: crimson-banner palisade tent | 96 px |
| `ward_generator.png` | Holy Ward Generator: gold-ringed obelisk with a radiant core | 80 px |
| `supply_cart.png` | Covenant supply cart (seen from above) | 72 px |
| `holy_standard.png` | Vael's Holy Standard: ornate gold banner pole | 72 px |
| `watchtower.png` | Checkpoint watchtower: wooden tower, crimson pennant | 96 px |

### Pickups (`assets/sprites/pickups/`)
| File | Subject | Size |
|---|---|---|
| `xp_crystal.png` | Small glowing cyan soul crystal (`#73D9FF`) | 16 px |
| `chest.png` | Bone-and-iron treasure chest with a violet lock glow | 40 px |
| `pu_magnet.png` | Soul Magnet: swirling cyan vortex charm | 28 px |
| `pu_feast.png` | Grave Feast: dark roasted meat on a bone | 28 px |
| `pu_hyper.png` | Hyper: crackling violet lightning rune | 28 px |
| `pu_stasis.png` | Stasis: frozen hourglass | 28 px |
| `pu_frenzy.png` | Dark Frenzy: green flaming skull | 28 px |
| `pu_nova.png` | Soul Nova: radiant violet starburst | 28 px |

Ground tiles and obstacles (gravestones, crypt walls, the march road) come in a later pass, as
seamless tiles.

### Projectiles (`assets/sprites/projectiles/`)

Flat sprites that the game **rotates along their flight path**. Draw each one **pointing right**
(the head at the right, the trail to the left), with no character, no ground and a transparent
background. Size is the length of the longest side on screen.

| File | Subject | Size |
|---|---|---|
| `shadow_bolt.png` | Shadow Bolt: a violet (`#A35CFA`) magic bolt with a short fading trail | 22 px |
| `void_bolt.png` | Void Barrage bolt: a black core ringed in necrotic green with a violet trail | 30 px |
| `void_shard.png` | Void shard: a tiny green crystal splinter | 14 px |
| `bone_spear.png` | Bone Spear: a sharpened bone javelin (`#DED9C2`) | 26 px |
| `ossuary_lance.png` | Ossuary Lance: a huge bone lance wrapped in violet energy | 44 px |
| `arrow.png` | Skeletal Archer arrow: a bone shaft with a green soul-fire head | 20 px |
| `mage_orb.png` | Undead Mage orb: a violet orb with a green spark | 20 px |
| `priest_bolt.png` | Mender / Warder bolt: a small green (`#6BF28C`) glowing mote | 14 px |
| `frost_bolt.png` | Frost Wraith bolt: an icy blue (`#9ED6FF`) shard | 20 px |
| `orb.png` | Shadow Orb Shield orb: a round violet orb (not pointed; it doesn't rotate) | 18 px |
| `enemy_arrow.png` | Covenant arrow: an ivory (`#F5EDD4`) shaft with a gold (`#FFD14C`) head | 20 px |
| `radiant_bolt.png` | Covenant holy bolt: a radiant gold-and-ivory spark | 20 px |

Prompt tip: *"a single pixel-art projectile sprite for a top-down game, pointing right, glowing,
transparent background, centred, no character, readable at 20 px"*. Several can be generated on one
sheet and split up afterwards.

### Icons (`assets/sprites/icons/`)

Square **badge icons** shown on level-up cards, the HUD ability bar and buff timers. Each one is a
**dark rounded-square badge** with one **bold, simple symbol** that reads at 24 px, in the same pixel
style. Undead and necromancy icons use violet, green and bone; never use Covenant gold or crimson on
the player's icons. Size: generate at 1024 × 1024; they are shown at 22-64 px.

| File | Subject |
|---|---|
| `shadow_bolt.png` | Violet bolt |
| `orb_shield.png` | Three violet orbs circling |
| `shadow_blast.png` | Violet shockwave ring |
| `bone_spear.png` | Crossed bone javelins |
| `soul_siphon.png` | Green soul stream flowing into a skeletal hand |
| `corpse_explosion.png` | Bursting corpse / bone shrapnel |
| `plague_cloud.png` | Sickly green miasma cloud with a skull |
| `void_barrage.png` | Black-and-green void bolts (evolution: add a gold-trimmed frame) |
| `eclipse_ward.png` | Eclipsed black orbs in a ring (evolution frame) |
| `abyssal_detonation.png` | Imploding violet vortex (evolution frame) |
| `ossuary_lance.png` | Huge bone lance (evolution frame) |
| `soul_rapture.png` | Many soul tethers to a skull (evolution frame) |
| `grave_eruption.png` | Bone spikes erupting from a grave (evolution frame) |
| `pestilence.png` | Swirling plague with a death's-head (evolution frame) |
| `death_knight.png` | Skull helm with a greatsword (evolution frame) |
| `lich.png` | Crowned skull with a phylactery (evolution frame) |
| `profane_bishop.png` | Bone mitre with a green halo (evolution frame) |
| `winter_revenant.png` | Ice-crowned wraith head with a black-ice staff (evolution frame) |
| `shadow_reaper.png` | Hooded skull mask between two crossed scythe-blades (evolution frame) |
| `cathedral_horror.png` | Horned marble gargoyle head with a glowing violet rune (evolution frame) |
| `gravebow.png` | Bone longbow with a violet curse-fire arrow (evolution frame) |
| `bone_colossus.png` | Horned bone helm over a ribbed bone breastplate (evolution frame) |
| `grave_dominion.png` | Gravestone with a green rune |
| `necrotic_vigor.png` | Green heart made of bone |
| `dark_command.png` | Violet crown |
| `soul_recycling.png` | Green circular soul arrow |
| `soul_conduit.png` | Violet crystal channelling energy |
| `warding_ritual.png` | Runic shield circle |
| `abyssal_focus.png` | Violet eye in a void |
| `forbidden_knowledge.png` | Chained grimoire |
| `dark_benediction.png` | Inverted halo over cupped bone hands |
| `shade_stride.png` | Shadowy boot / footprints |
| `vampiric_rite.png` | Blood-red drop in a chalice (one deep red accent is fine) |
| `necrotic_expanse.png` | Expanding green rings |
| `lingering_malediction.png` | Hourglass with green mist |
| `bone_plating.png` | Shield of overlapping bone plates with a small green rune |
| `unholy_precision.png` | Bone arrowhead under a violet crosshair eye |
| `unholy_resilience.png` | Cracked, drained holy sun behind a dark undead shield |
| `bound_souls.png` | Green soul wisp held by a short iron chain |
| `profane_pact.png` | Torn scroll with a crimson seal (the curse: the one icon allowed crimson) |
| `powerup_magnet.png` | Cyan soul vortex |
| `powerup_feast.png` | Roasted meat on a bone |
| `powerup_hyper.png` | Violet lightning rune |
| `powerup_stasis.png` | Frozen hourglass |
| `powerup_frenzy.png` | Green flaming skull |
| `powerup_nova.png` | Violet starburst |
| `grave_step.png` | Grave Step (dash): a hooded violet shadow stepping sideways, two fading afterimages behind it |
| `dread_rally.png` | Dread Rally (ultimate): a green-eyed skull inside a dark violet burst ring, green soul wisps rising |
| `twin_shadow.png` | Ossuary Twin Shadow: two overlapping hooded shadow silhouettes (second dash charge) |
| `restless_shade.png` | Ossuary Restless Shade: a hooded shadow inside a green clock arc (shorter dash cooldown) |

Prompt tip: *"a pixel-art game ability icon, a dark rounded-square badge with a thin violet border,
one bold simple symbol: <subject>, readable at 24 pixels, transparent background outside the badge"*.
Keep the badge shape and border identical across all icons; generating them 4-6 at a time in one
conversation helps.

### Effects (`assets/sprites/effects/`)

Short **one-shot animations** (explosions, bursts, flashes) that play once, centred on the effect
and scaled to its gameplay radius. Each is a **sprite sheet of 6-10 frames** (or a short GIF),
seen **straight from above**, on a transparent background. Process it with
`python3 tools/prepare_sprite.py --anim <sheet or GIF> <id>`; the tool finds the frames (by the
transparent gaps between them, or `--frames N` for N equal frames in a row, or `--grid CxR`), crops
them to one square around the effect and writes a strip of 128 px frames. Timing and on-screen fill
are set per effect in `scripts/data/anim_data.gd`. Without the file, the game keeps today's drawn
shape. **Shadow Blast** (the test), **Dread Rally** and the **Grave Step** puff are wired so far;
the rest get their code hook when their art arrives.

| Id | Effect | Frames |
|---|---|---|
| `shadow_blast` | **Test first.** Shadow Blast: a violet (`#A35CFA`) shockwave ring bursting outward from a dark centre, then fading to wisps | 8 |
| `abyssal_detonation` | Abyssal Detonation: a black-violet vortex imploding, then exploding with green (`#6BF28C`) sparks | 10 |
| `corpse_explosion` | Corpse Explosion: a burst of bone shrapnel and green gore mist | 8 |
| `grave_eruption` | Grave Eruption: bone spikes stabbing up from the ground in a ring, then crumbling | 8 |
| `bolt_impact` | Shadow Bolt hit: a small violet splash with sparks | 6 |
| `summon_rise` | Summon rising: green soul-fire swirling up from a grave-dirt circle | 8 |
| `undead_death` | Undead destroyed: bones scattering and a green soul wisp rising | 6 |
| `enemy_death` | Covenant soldier dies: a crimson-and-ivory burst fading into gold motes | 6 |
| `holy_impact` | Covenant hammer / boss slam: a gold (`#FFD14C`) radiant shockwave with ivory dust | 8 |
| `soul_nova` | Soul Nova: a huge violet-and-green ring of souls expanding across the screen | 10 |
| `level_up` | Level-up: a column of violet light with rising green runes | 8 |
| `frost_shatter` | Winter Revenant shatter: a frozen body bursting into pale blue (`#9ED6FF`) ice shards flying outward, then glittering frost (wired) | 6 |
| `frost_nova` | Winter Revenant death nova: a ring of freezing frost (`#9ED6FF`) racing outward from a cold-white centre, leaving ice crystals (wired) | 8 |
| `chest_open` | Treasure chest bursting open with violet light and bone-coloured sparks | 8 |
| `evolution` | Evolution: a dark vortex collapsing into a bright violet-gold flash | 10 |
| `dread_rally` | **Hooked.** Dread Rally: a deep violet (`#4D1473`) shockwave bursting out of a green (`#6BF28C`) skull-shaped flare, souls streaking outward, then fading to dark wisps | 10 |
| `grave_step_trail` | **Hooked.** Grave Step departure: a puff of violet (`#A35CFA`) shadow smoke left where the necromancer stepped from, curling and thinning away | 6 |

**Sprite-sheet prompt** (ChatGPT; attach `necromancer.png` as the style reference):
```
Using the attached image only as the pixel-art style reference (same pixel size, outline weight
and palette treatment), create a SPRITE SHEET for a one-shot visual effect in a top-down 2D
horde-survival game, seen straight from above.

Effect: <EFFECT DESCRIPTION FROM THE TABLE, with its hex colours>.

Layout: exactly <N> frames in ONE horizontal row, left to right in play order, every frame the same
size, the effect centred in each frame, with clear empty transparent space between frames. Frame 1
is the very start (small), the middle frames are the peak, and the last frames fade and break up.
Crisp pixel art (clean pixel clusters, no anti-aliased blur), bright and readable on a very dark
ground (#161A1C). Fully transparent background (real alpha, not a checkerboard). No ground, no
characters, no text, no frame numbers, no watermark.
```

Tips:
- The frames must line up: the centre of the burst should stay in the same place in every frame.
  If ChatGPT drifts or changes the design between frames, ask it to "redraw the same effect with
  identical centre and design in every frame, only the expansion changes", or send the sheet to
  Claude to make the same effect with **SpriteCook** (image to animation) instead.
- A short GIF works as well as a sheet; send whichever comes out cleaner.

---

## Prompt 1: the Necromancer (style test; run both)

### Style A: dark painterly
```
A single fantasy game character sprite for a top-down 2D horde-survival game, shown from a
three-quarter top-down view (camera above and slightly in front), full body visible, facing right,
in a neutral ready stance.

Subject: a hooded necromancer in a flowing deep purple robe (#3D1F57) with tattered edges, bone
pauldrons shaped like small skulls (#DED9C2), a pale gaunt face mostly hidden in the hood's shadow
with faint glowing violet eyes (#A35CFA). He holds a tall gnarled bone staff topped with a skull
wreathed in violet soul-fire (#A35CFA), with subtle necrotic green runes (#6BF28C) glowing along the
robe's hem.

Style: dark fantasy, hand-painted, rich but limited palette, strong top-left rim lighting, bold
simple silhouette with a thick dark outline so it reads clearly when scaled down to 56 pixels tall.
No fine detail that would be lost at small size.

Output: square 1024x1024 PNG with a fully transparent background, the character centered and
filling about 80% of the height. No ground, no cast shadow, no scenery, no frame, no text, no
watermark.
```

### Style B: pixel art
```
A single pixel-art game character sprite for a top-down 2D horde-survival game, three-quarter
top-down view, full body, facing right, neutral ready stance. Crisp pixel art in the style of a
64x64 sprite (clean pixel clusters, no anti-aliased blur, 1-pixel dark outline), upscaled to
1024x1024 with nearest-neighbour so the pixels stay sharp.

Subject: a hooded necromancer in a deep purple robe (#3D1F57), small bone skull pauldrons
(#DED9C2), glowing violet eyes in the hood (#A35CFA), holding a tall bone staff topped by a skull
in violet soul-fire (#A35CFA), faint green runes (#6BF28C) on the robe hem.

Limited palette (about 12-16 colours), strong readable silhouette, light from the top-left.

Output: square 1024x1024 PNG, fully transparent background, character centered, about 80% of the
height. No ground, no shadow, no scenery, no frame, no text, no watermark.
```

---

## Reference-matching template (for every later asset)

Attach the approved `necromancer.png` and use:

```
Using the attached image as the exact art-style reference (same rendering style, outline weight,
lighting from the top-left, level of detail and colour treatment), create a NEW single game sprite
for the same top-down 2D horde-survival game.

Subject: <SUBJECT DESCRIPTION FROM THE MANIFEST, with its hex colours>.

Same camera: three-quarter top-down view, full body, facing right, neutral ready stance. Bold
silhouette readable at <SIZE> tall. Square 1024x1024 PNG, fully transparent background, subject
centered, about 80% of the height. No ground, no shadow, no scenery, no text, no watermark.
```

Tips:
- Generate 2–4 related units in one conversation so the style stays consistent, and re-attach the
  reference if it starts to drift.
- If the background comes out white or checkered instead of transparent, ask: "Regenerate with a
  truly transparent background (alpha channel), not a checkerboard pattern."
- Keep undead and Covenant colour language separate (see the table above).
