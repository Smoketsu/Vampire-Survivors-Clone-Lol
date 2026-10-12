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
| `bone_hound.png` | Bone Hound: a lean, low skeletal hound seen from the side, long ribcage barrel, thin legs, a long snouted skull with a green (`#6BF28C`) eye, a curled bone tail; small, fast, feral | 32 px |
| `hellhound.png` | Hellhound (Bone Hound evolution): the hound charred black-brown (`#4D3329`) with glowing ember (`#FF6B1F`) cracks along the ribs, a mane of orange flame along the neck and back, burning yellow-orange eyes. Bigger and fiercer than `bone_hound.png` | 40 px |
| `banshee.png` | Banshee: a legless floating spectre in a pale translucent veil (`#CCE0FA`) that frays into wisps, long white hair streaming back, arms raised, a dark wide-open wailing mouth; faint violet (`#A35CFA`) glow | 48 px |
| `keening_lady.png` | Keening Lady (Banshee evolution): a taller, regal banshee in a flowing dark violet gown (`#4D2969`), a silver circlet with a violet gem, pale face with a screaming mouth, lilac sound ripples rolling out of it. Bigger and more ornate than `banshee.png` | 56 px |
| `corpse_catapult.png` | Corpse Catapult: a squat siege engine of old coffin wood (`#5C4533`) and bone beams on two bone wheels, sinew ropes, a diagonal throwing arm whose cup holds a skull boulder with green eyes | 56 px |
| `ossuary_engine.png` | Ossuary Engine (Corpse Catapult evolution): a bigger siege engine built from ribcages and spines, ember-lit (`#FF6B1F`) sinew, a triple cup loaded with three burning skulls. Clearly bigger and grimmer than `corpse_catapult.png` | 72 px |

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
| `sanctified_sentinel.png` | Sanctified Sentinel (Stage 3 construct): a squat, blocky animated statue of pale cathedral stone (`#BDB8A8`) inlaid with gold (`#FFD14C`) lines, a narrow glowing gold eye slit in a square head, one arm ending in a long stone blade held forward; heavy, slow, no cloth | 72 px |
| `radiant_inquisitor.png` | Radiant Inquisitor (Stage 3 elite caster): a tall robed inquisitor in ivory (`#F5EDD4`) robes with a crimson (`#C71A29`) stole, face hidden in shadow under a hood, a gold sunburst halo of rays behind the head, holding a gold-bound tome; smaller and more human than the Reckoning's `inquisitor.png` | 60 px |
| `high_confessor.png` | High Confessor (Stage 3 elite priest): a broad figure in wide ivory (`#F5EDD4`) vestments with a crimson (`#C71A29`) stole, a tall gold (`#FFD14C`) mitre, a gold crook staff topped by a faint halo; serene, imposing, clearly grander than `chaplain.png` | 56 px |
| `sun_paladin.png` | Sun Paladin (Stage 3 elite): a heavily armoured knight in gilded plate, a gold (`#FFD14C`) heater shield bearing a crimson sun emblem with rays, a gold great helm with an ivory plume, a lance; a gold-heavy cousin of `templar.png` | 56 px |
| `cathedral_guardian.png` | Cathedral Guardian (Stage 3 miniboss): a giant colossus of pale cathedral stone (`#BDB8A8`) with gold (`#FFD14C`) trim, a stained-glass rose window (deep blue, crimson, gold) set in its chest, a small square head crowned with three gold spires, two huge stone fists; towering, slow, monumental | 140 px |

### Bosses (`assets/sprites/bosses/`)
| File | Subject | Size |
|---|---|---|
| `alaric.png` | Sir Alaric, the Gravebreaker: giant paladin, holy warhammer, gold and ivory | 120 px |
| `vael.png` | Marshal Vael, the Crimson Bulwark: great kite shield, flaming sword, crimson plume | 120 px |
| `seraphine.png` | Grand Inquisitor Seraphine, Voice of the Dawn (Stage 3): a radiant winged Inquisitor in a white-and-gold bell robe with a crimson stole and a gold sun on the chest, a white veil and gold circlet, a gold **sun halo** with rays behind her head, two feathered ivory wings spread up behind her shoulders, a tall gold **relic staff** crowned by a blazing sunburst reliquary in her front hand | 130 px |
| `seraphine_avatar.png` | *Optional.* Her **Avatar of the Dawn** form (phases 2-3): the same figure larger and brighter, wings spread wide with gold-edged feathers, a long-rayed halo, the relic blazing white-gold, a soft gold aura around her. Without it the game draws `seraphine.png` with a drawn aura | 156 px |

### Structures (`assets/sprites/structures/`)
| File | Subject | Size |
|---|---|---|
| `outpost.png` | Siege outpost: crimson-banner palisade tent | 96 px |
| `ward_generator.png` | Holy Ward Generator: gold-ringed obelisk with a radiant core | 80 px |
| `supply_cart.png` | Covenant supply cart (seen from above) | 72 px |
| `holy_standard.png` | Vael's Holy Standard: ornate gold banner pole | 72 px |
| `watchtower.png` | Checkpoint watchtower: wooden tower, crimson pennant | 96 px |
| `ward_crystal.png` | Sanctum ward crystal: a tall faceted ivory-and-gold crystal on a round pale-stone plinth, soft radiant gold glow; pixel art, top-down three-quarter view, transparent background | 56 px |
| `sacred_altar.png` | Sanctum sacred altar: a wide pale-stone altar block draped in gold cloth with a crimson stripe, two lit candles, a radiant gold sun disc standing behind it; pixel art, top-down three-quarter view, transparent background | 72 px |

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

### Sanctum of Judgment ground tiles (`assets/sprites/tiles/`, later pass)
Stage 3's four battle-zone floors (GDD §8.3: "cathedral halls, cloisters, sacred courtyards,
stained glass, giant statues, golden mosaics"). Palette: ivory, gold and pale stone with
Covenant crimson accents, kept **mid-dark** (the code-drawn floors sit around `#3D3A35`-`#4A4743`)
so ivory-and-silver Covenant soldiers and bone-white undead stay readable on them. Seamless,
pixel art, top-down three-quarter view; no characters, no objects that look solid (obstacles are
drawn separately). The game later blends each tile toward purple (`#2B1236`) as the Sanctum
is corrupted, so avoid baking purple in. Not hooked up yet: `SanctumGround` draws these looks in
code until the tiles land.
| File | Subject | Size |
|---|---|---|
| `sanctum_courtyard.png` | Zone I, the Outer Courtyards: pale flagstones in staggered courses, moss in the joints, the odd gold inlay star; pixel art, top-down three-quarter, seamless tile | 128 px |
| `sanctum_halls.png` | Zone II, the Sanctified Halls: a dark-gold mosaic floor of small tesserae with rosettes; pixel art, top-down three-quarter, seamless tile | 128 px |
| `sanctum_cloisters.png` | Zone III, the Cloisters: a square grid of stone walks around trimmed turf and small flower beds; pixel art, top-down three-quarter, seamless tile | 128 px |
| `sanctum_sanctuary.png` | Zone IV, the Final Sanctuary: grey-white marble slabs with veins, crossed by translucent pools of stained-glass light (red, blue, gold, green); pixel art, top-down three-quarter, seamless tile | 128 px |

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
| `death_mark.png` | Death Mark: a violet brand sigil (ring with an inverted triangle) around a small green-eyed skull |
| `doom_brand.png` | Doom Brand: three linked sickly-green brand sigils around a violet core (evolution frame) |
| `bone_wall.png` | Bone Wall: a row of jagged bone spikes rising from a stone base |
| `charnel_bastion.png` | Charnel Bastion: a closed ring of bone spikes around a green-eyed skull (evolution frame) |
| `soul_chains.png` | Soul Chains: a jagged violet soul-lightning bolt arcing between three small green souls |
| `chains_of_the_damned.png` | Chains of the Damned: a forked violet-and-green lightning burst ending in bone chain links (evolution frame) |
| `wither.png` | Wither: a sickly yellow-green (`#A8CC3D`) aura ring with drooping decay motes around a small robed figure |
| `necrotic_blight.png` | Necrotic Blight: a wide green aura ring feeding a dark magenta heart (evolution frame) |
| `raise_dead.png` | Raise Dead: a bare skeleton clawing out of a grave-dirt line, green soul-fire at its feet |
| `legion_of_bones.png` | Legion of Bones: three green-eyed skulls rising together over a grave line (evolution frame) |
| `death_knight.png` | Skull helm with a greatsword (evolution frame) |
| `lich.png` | Crowned skull with a phylactery (evolution frame) |
| `profane_bishop.png` | Bone mitre with a green halo (evolution frame) |
| `winter_revenant.png` | Ice-crowned wraith head with a black-ice staff (evolution frame) |
| `shadow_reaper.png` | Hooded skull mask between two crossed scythe-blades (evolution frame) |
| `cathedral_horror.png` | Horned marble gargoyle head with a glowing violet rune (evolution frame) |
| `gravebow.png` | Bone longbow with a violet curse-fire arrow (evolution frame) |
| `bone_colossus.png` | Horned bone helm over a ribbed bone breastplate (evolution frame) |
| `bone_hound.png` | Snarling skeletal hound head in profile |
| `banshee.png` | Pale wailing veiled face with streaming hair |
| `corpse_catapult.png` | Bone catapult arm with a skull in its cup |
| `hellhound.png` | Flaming charred hound head (evolution frame) |
| `keening_lady.png` | Crowned banshee face with lilac sound ripples (evolution frame) |
| `ossuary_engine.png` | Triple cup of burning skulls on a rib-cage arm (evolution frame) |
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
| `grim_ledger.png` | Grim Ledger: an open bone-bound ledger, a small violet crown above it and a green-eyed skull on the page |
| `spirit_binding.png` | Spirit Binding: a pale soul held in a loop of spectral violet-and-bone chain links |
| `restless_dead.png` | Restless Dead: a bone hourglass with green mist, a small skull in its lower bulb |
| `blood_scent.png` | Blood Scent: a blood drop with bone-white speed streaks (one deep red accent is fine) |
| `mournsong.png` | Mournsong: a pale weeping spectral face with two violet notes |
| `siegecraft.png` | Siegecraft: a cracked grey tower struck by a bone boulder |
| `stance_escort.png` | Army stance Escort (HUD stance bar, 26 px): a green guard arc of bone escorts sheltering a small violet necromancer mark |
| `stance_onslaught.png` | Army stance Onslaught: three orange-flame arrows bursting outward from a small violet mark |
| `stance_spearhead.png` | Army stance Spearhead (also its Ossuary unlock): a V-wedge of bone pointing up, the violet mark behind its tip |
| `stance_bone_ring.png` | Army stance Bone Ring: a closed ring of bone around a small violet mark, cold-blue glow |
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
shape. **Shadow Blast** (the test), **Dread Rally**, the **Grave Step** puff and Seraphine's
**nova**, **holy beam** flare and **relic shatter** are wired so far; the rest get their code hook
when their art arrives.

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
| `seraphine_nova` | **Hooked.** Seraphine's Judgment nova: a huge gold (`#FFD14C`) and ivory (`#F5EDD4`) ring of holy light racing outward from a white-hot centre, sun-ray streaks, then fading to gold motes (played at the full nova radius, so keep the ring thin and the centre mostly empty) | 10 |
| `holy_beam` | **Hooked.** Seraphine's holy beams igniting: a white-gold flare bursting from her relic, with short gold rays (the beams themselves stay drawn) | 6 |
| `relic_shatter` | **Hooked.** Seraphine's death: the radiant sunburst relic cracking and exploding into gold and ivory shards and a ring of white light, then the light guttering out | 10 |
| `soul_lightning` | **Hooked.** Soul Chains strike: a small violet (`#A35CFA`) lightning flash with a pale white-violet core and crackling sparks, played on each struck foe (the arcs between foes stay drawn) | 6 |
| `bone_wall_rise` | **Hooked.** Bone Wall: one cluster of bone spikes bursting up out of cracked grave dirt, with a puff of dust | 6 |
| `bone_wall_burst` | **Hooked.** Charnel Bastion expiring: a bone-spike cluster exploding into flying bone shrapnel with a green (`#6BF28C`) flash | 8 |
| `wither_aura` | **Hooked.** One Wither pulse: a thin ring of sickly yellow-green (`#A8CC3D`) decay mist racing outward and dissolving into falling motes (played at the aura radius, keep the centre empty) | 8 |
| `doom_burst` | **Hooked.** Doom Brand detonation: a sickly green (`#8CFF73`) brand sigil flaring and bursting into a ring of violet doom-fire | 8 |
| `raise_dead` | **Hooked.** Raise Dead: grave dirt cracking open and a green soul-fire swirl as a skeletal hand claws up | 8 |
| `legion_burst` | **Hooked.** Legion of Bones: a crumbling skeleton bursting into a ring of bone shards and green dust | 8 |

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
