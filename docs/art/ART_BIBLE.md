# Gravebound: Art Bible and ChatGPT Prompt Pack

This document defines how Gravebound's sprites are generated in ChatGPT, saved and wired into the game.
It is the single reference for every art request.

## Workflow

1. **Approve the style first.** Generate the **necromancer** with the two style prompts below (A and
   B), pick one, and save the chosen image as `assets/sprites/player/necromancer.png`. That image
   becomes the **style reference** for everything else.
2. **Generate the rest in small related batches** (e.g. Warrior, Archer and Mage together) using the
   *reference-matching template* at the bottom: attach `necromancer.png` and say "match this style".
3. **Save each PNG** at the path given in the manifest (exact filename, lowercase). Commit them or
   send them to Claude.
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
| `skeleton_risen.png` | Lich-raised temporary skeleton: plain, ragged, faint violet glow | 36 px |

### Covenant enemies (`assets/sprites/enemies/`)
| File | Subject | Size |
|---|---|---|
| `recruit.png` | Covenant Recruit: young soldier, crimson tabard, spear, light helm | 40 px |
| `footman.png` | Crimson Footman: heavy silver armour, crimson kite shield, sword | 48 px |
| `archer.png` | Zealous Archer: ivory-and-crimson archer with a longbow | 40 px |
| `chaplain.png` | Covenant Chaplain: ivory robes, gold censer, healing glow | 42 px |
| `purifier.png` | Purifier: silver mask, flaming torch / flamethrower censer | 44 px |
| `templar.png` | Templar Knight: gold-trimmed heavy knight, lance, crimson cape | 52 px |
| `inquisitor_end.png` | Inquisitor of the End (Reckoning): towering, radiant gold, faceless | 64 px |
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
