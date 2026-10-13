# Gravebound: Art Bible and Prompt Pack

This document defines how Gravebound's art is made, processed, checked and wired into the game. It is
the single reference for every art request. The owner decision behind it is GDD §15.0 "Art pass (true
pixel art)": the first AI placeholders are replaced by **true pixel art made at its real size**, so
every unit stays clear at the small in-game sizes. The grid is **1 art px = 1 screen px** at the
1280×720 layout (GDD §15.0 "Art pass grid": the owner compared renders; at 28 art px the necromancer
lost its skull pauldrons and staff skull, at 56 it reads clearly, and the AI image tools naturally
draw figures about 60-95 px tall).

## Workflow

1. **Prompt.** Copy the asset's prompt (the anchors below, or the *prompt template* filled from the
   manifest) into the image AI (ChatGPT or similar). Attach the **approved anchor sprites** as style
   references once they exist (see "Anchors").
2. **Generate** a square image (1024 px or larger) with a **transparent background**.
3. **Process** it with grid mode:
   `python3 tools/prepare_sprite.py <downloaded image> <key>` (e.g. `summons/warrior`). The tool keeps
   the original in `art_source/<key>.png`, rebuilds the sprite at its real size on the art grid, snaps
   every pixel to the locked palette, draws the outline and the top-left rim, puts the feet on the
   bottom row, centres the body and writes `assets/sprites/<key>.png`. It prints a report (size,
   colours, cleaned pixels, colours the palette had to move far).
4. **Check** it: `python3 tools/art_check.py <key>` writes one check sheet: the sprite **drawn by the
   game** on all 9 stage floors next to the necromancer, a Skeleton Warrior and a Covenant Recruit, at
   Normal (×1) and Close (×2) zoom, plus a big zoom, a greyscale copy and a silhouette, with the rule
   checks (height, alpha, palette, feet, lightness on every floor, faction colours, specks).
5. **Approve or iterate.** If the sheet fails or reads badly, regenerate (simpler shapes, flatter
   colours, see "Getting good conversions") or touch up the small PNG by hand in any pixel editor
   (Aseprite, LibreSprite, Pixelorama), using only palette colours, and re-run the check.
6. The game shows a sprite whenever the file exists, and otherwise keeps the code-drawn glyph, so art
   lands one piece at a time. Movement, hit flashes, facing and shadows are done in code (engine
   motion); walk cycles come later as 4-frame sheets (see "Walk cycles").

Or send the images to Claude to run steps 3-4.

## Global rules (readability)

- **The grid.** 1 art px = **1 screen px** at the 1280×720 layout (`SpriteData.ART_SCALE` = 1). Art is
  made at its real size and drawn through the game's **sharp-pixel filter** (a shader: every art pixel
  stays a crisp square, its edges anti-aliased over half a screen pixel), so the pixels stay even at
  any window scale (a 1080p window is ×1.5 the layout) and at Zoom Close ×2 (1 art px = 2 screen px);
  Normal zoom is ×1. The stored PNG is exactly `SpriteData.HEIGHTS[key]` art px tall (the HEIGHTS
  value itself), 1 texel = 1 art px, every pixel fully opaque or fully transparent.
- **Sizes by tier** (art px tall = `SpriteData.HEIGHTS`): fodder **40-44**; soldiers and summons
  **44-52**; the necromancer and the other characters **56**; heavies **60-72**; structures **72-100**;
  minibosses and bosses **120-156**. Outside the tiers: the small summons (Bone Hound 32, Risen 36,
  Hellhound 40) and the giant summons (Corpse Abomination 88, Bone Colossus 100). The manifest's "Art
  px" column is the exact height. **The tiers measure the body, head to feet.** The sprite height is the
  whole image, so a weapon, banner or flame that rises well above the head adds its overhang to the
  sprite height (owner check on the anchors: the Covenant Recruit at 40 had a 32 px body under his spear
  and read three-quarter size next to the warrior; at 50 his body is 40). Set such a unit's `HEIGHTS`
  when its art lands.
- **Palette.** Only the locked palette (`tools/palette.json`, below). At most **3 shades per
  material**. No gradients, no dithering, no texture noise.
- **Detail.** Every readable feature (a face, a hand, a skull pauldron, a weapon head, a buckle) is at
  least **2 art px**; **single pixels** only for **eyes, glints, highlights** and a skull's eye sockets.
  Why: at 1:1 a 2 art px feature is 2 screen px, about the smallest shape the eye reads as a shape in
  motion, while one pixel is 1 screen px at Normal zoom, which reads only as an accent (bright on dark,
  or dark on bright), and a scatter of single pixels reads as noise. `prepare_sprite.py` merges stray
  single pixels and keeps those accents. One readable idea per part: a hood, a face, a weapon, a
  shield. 1 px trims, belts and engravings still turn to noise; leave them out.
- **Outline and rim.** A **1 art px outline** (1 screen px at Normal zoom, 2 at Close: the usual
  weight for pixel art at this resolution) in the **darkest shade of the part's own hue** (the ramp's
  ink), **never pure black**; a **1 px light rim** (one shade lighter) on the top-left edges. Light
  comes from the top-left. `prepare_sprite.py` draws both.
- **Value contrast.** Unit main shapes sit clearly **above the near-black floors** (the Graveyard soil
  is `#161A1C`): the check sheet wants the main shape's median OKLab lightness at least **+0.15** above
  every floor. Dark cloth uses the ramp's mid shade, with the darkest shade only for shadow.
- **Silhouette.** One **signature shape per kind** that reads in solid black (the necromancer's tall
  flame staff and pointed hood, the Warrior's round shield, the Recruit's tall spear, the Archer's bow,
  the Shieldbearer's tower shield). The check sheet shows the silhouette.
- **Glow** only on the player, spells, telegraphs, elites and bosses (the `violet_flare`, `soul_glow`
  and `holy_white` colours). Soldiers and summons get at most an eye glint.
- **Elites** use the **same sprite**: the game draws them larger with a gold rim.
- **View and pose.** Top-down three-quarter view (camera above and slightly in front), full body,
  **facing right** (the game mirrors it), neutral ready stance, no cast shadow (the game draws one).

## Colour language

**Faction colours.** Never mix the two sides' signature colours on one unit.

| Side | Colours | Notes |
|---|---|---|
| **The player** (necromancer and the 12 characters) | **violet** (robe, soul-flame, eyes, spells), with bone | Violet is **reserved for the player**: nothing else may be violet, so the player is found at a glance. Each character keeps violet somewhere, plus its spell school's accent. |
| **The undead army** | **bone ivory**, **cold grey**, **teal-green soul fire**, one accent per class | Warrior: lit cold steel (`grey_light`). Archer: moss green. Priests (Mender, Warder, Bishop): teal. **Undead Mage and Lich: deep arcane blue.** **Frost Wraith and Winter Revenant: pale icy cyan**, kept apart from the arcane blue. Hellhound and the Ossuary Engine: fire. |
| **The Crimson Covenant** | **crimson**, **ivory**, **warm steel** | **Gold** for elites, the Sanctum kinds and the bosses; skin tones on faces; fire for the Purifier. |
| **Floors** | dark, low-saturation, narrow-value | Each stage keeps its floor within a few close darks so every unit stands out. |

**The locked palette** (`tools/palette.json`, the single source of truth; 40 colours: 37 for sprites,
3 floors). Ramps run dark to light; the first colour of each ramp is its **outline ink**. Colours
marked * are borrowed from another ramp. Numbers are OKLab lightness (0-1). A labelled swatch sheet:
`python3 tools/pixel_palette.py --preview palette.png`.

| Ramp (dark -> light) | Colours (name `hex` OKLab L) | Used for |
|---|---|---|
| **violet** | ink_violet `#160A21` 0.18 · violet_deep `#4A2569` 0.35 · violet `#7A42AD` 0.50 · violet_glow `#A35CFA` 0.63 · violet_flare `#DDBDFF` 0.85 | the player only: necromancer, the 12 characters, their spells and icons |
| **bone** | ink_warm `#1C110B` 0.19 · bone_shade `#7F785F` 0.57 · bone_mid `#B4AA8A` 0.74 · bone `#E8E1C8` 0.91 | undead bone ivory and Covenant ivory cloth |
| **grey** | ink_cold `#0F141C` 0.19 · grey_dark `#3B4352` 0.38 · grey `#6B7A94` 0.58 · grey_light `#A7B3C6` 0.76 | undead cold grey: armour, crypt stone, gargoyles, the Warrior's steel accent |
| **soul** | ink_green `#081814` 0.19 · soul_dark `#1C6B58` 0.48 · soul `#3DCC94` 0.76 · soul_glow `#A8FFD2` 0.93 | teal-green soul fire, priests (Mender, Warder trim), heals |
| **moss** | ink_green* `#081814` 0.19 · moss_dark `#3B5529` 0.42 · moss `#76984A` 0.64 | the Archer's moss green accent, rot, wither |
| **arcane** | ink_cold* `#0F141C` 0.19 · arcane_dark `#243A99` 0.40 · arcane `#4F78EB` 0.60 · arcane_light `#9FB8FF` 0.79 | deep arcane / frost blue: Undead Mage, Lich, Crypt Warder ward |
| **ice** | ink_cold* `#0F141C` 0.19 · grey* `#6B7A94` 0.58 · ice `#A6D9EA` 0.86 · ice_light `#E4FAFF` 0.97 | pale icy cyan: Frost Wraith, Winter Revenant, chill and freeze |
| **steel** | ink_warm* `#1C110B` 0.19 · steel_dark `#5C5852` 0.46 · steel `#9C978C` 0.68 · steel_light `#D4D0C6` 0.86 | Covenant warm steel |
| **crimson** | ink_red `#26070C` 0.19 · crimson_dark `#7A0E1B` 0.37 · crimson `#C71A29` 0.53 | Covenant crimson |
| **brown** | ink_warm* `#1C110B` 0.19 · brown `#4F3320` 0.35 · brown_light `#8C6040` 0.53 | leather and wood |
| **gold** | ink_warm* `#1C110B` 0.19 · brown_light* `#8C6040` 0.53 · gold `#E0A92E` 0.77 · gold_light `#FFDC66` 0.90 · holy_white `#FFFAE8` 0.98 | Covenant gold (elites, Sanctum kinds, bosses), halos, holy white glow |
| **skin** | ink_warm* `#1C110B` 0.19 · brown_light* `#8C6040` 0.53 · skin `#E0A882` 0.77 · bone* `#E8E1C8` 0.91 | Covenant faces and hands |
| **flame** | ink_red* `#26070C` 0.19 · crimson* `#C71A29` 0.53 · flame `#FF8C26` 0.75 · gold_light* `#FFDC66` 0.90 | fire and embers |
| **floor** | floor_soil `#161A1C` 0.21 · floor_earth `#221C17` 0.23 · floor_stone `#312E2B` 0.30 | ground colours of the three stages (tiles only, never sprites) |

`prepare_sprite.py` limits each folder to its faction's ramps (player: everything but skin and warm
steel; summons: bone, grey, soul, moss, arcane, ice, brown, with flame only for the Hellhound and the
Ossuary Engine, no ice for the Mage and Lich and no arcane for the frost summons; enemies and bosses:
bone, steel, crimson, brown, gold, skin, flame; structures: the same without skin); `--ramps a,b`
overrides it. The
floors will need one or two more close shades per stage when the floor tiles are made (to be added to
`palette.json` with the anchor tile). Today's code-drawn Sanctum floors are mid-grey (OKLab L 0.34-0.40,
lighter than `floor_stone`); the floor pass brings them down so violet and crimson units clear them.

## Prompt template (every asset after the anchors)

What converts best from an image AI to this grid: **flat colours from a short list, no gradients or
texture noise, a clean 1-pixel dark outline, chunky shapes with no detail under two pixels, a big
readable silhouette**, and a pixel size close to the real grid (the AI tools tend to draw figures 60-95
px tall; asking for the exact height keeps the conversion near 1:1). Fill in `<...>` from the manifest; the colour
list is the palette names and hex of the ramps the unit uses.

```
Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter
top-down view (camera above and slightly in front), FULL BODY, FACING RIGHT, neutral ready stance.

LOW-RESOLUTION pixel art: the whole figure is only <ART PX> pixels tall, drawn on a coarse pixel grid
and shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple,
readable shapes; no detail smaller than 2 pixels except the eyes and small glints. No anti-aliasing,
no gradients, no dithering, no texture noise, no soft glow haze, no fine trims or engravings.

Subject: <SUBJECT FROM THE MANIFEST>.
Signature shape that must read in silhouette: <SIGNATURE>.

Colours: ONLY flat fills from this list, at most 3 shades per material: <PALETTE NAMES AND HEX>.
Outline: a clean 1-pixel dark outline around the whole figure in the darkest shade of each part's own
colour (never pure black). Light from the top-left: the top-left edges one shade lighter. Keep the main
shapes clearly brighter than a near-black ground (#161A1C).

Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white),
one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no
scenery, no text, no frame, no watermark.
Attached: the approved sprites of this game. Match their pixel size, outline weight and palette exactly.
```

Tips:
- Generate 2-4 related units in one conversation so the style holds, and re-attach the anchors if it
  drifts.
- If the background comes out white or checkered: "Regenerate with a truly transparent background
  (alpha channel), not a checkerboard pattern."
- If the image comes out as a detailed illustration "in a pixel style", ask again: "Much lower
  resolution: about <ART PX> pixels tall in total, each pixel a big square block, fewer details, flat
  colours only."

### Getting good conversions (measured on the first sources)

The tool turns any image into palette-correct grid art, but **what it can keep depends on the source**:

- **Detailed AI illustrations** (today's 31 placeholders: ~1,000 px figures "in a pixel style", with
  gold trims, belts, engraved armour and soft glows) are shrunk about 18× to 56 px (they were 36× to
  28 px on the old 2:1 grid, where the faces, eyes and trims were lost). The big masses come out clean;
  fine trims still blur into blotches. Usable as placeholders, not as final art.
- **Chunky sources drawn close to the target grid** convert almost losslessly: on the old grid a 28 px
  sprite blown up to 1,000 px with blur, colour noise and an off-grid scale came back **95%
  pixel-identical** (92% after the speck cleanup). That is why the prompt asks for a figure "only N
  pixels tall" with big blocks, flat colours and a clean 1-pixel outline.
- **The owner's chunky necromancer** (~65 px native, 16 source px per pixel, converted to 56) keeps the
  hood, the robe's tattered hem, both skull pauldrons with their eye sockets, the hand and the staff
  skull in its flame. Because 65 → 56 is not a whole ratio, a few 1-pixel details merge with a
  neighbour (the two hood eyes become one short band): touch those up by hand.
- When a source was already drawn at (or near) the grid with its own outline, `--inside-outline` keeps
  the sprite's own edge as the outline instead of adding a second one (otherwise the outline comes out
  2 px thick in places); it gave the cleaner necromancer.
- The last 10% (eyes, a face, a clean hand) is fastest done by hand on the small PNG in a pixel
  editor; the check sheet shows whether it is needed.
- **Small coloured features** (glowing eyes, a gem) are kept automatically: a strongly saturated
  colour can win its art pixel even when it is no brighter than its surroundings, and such accent
  colours are never pruned as stray (`ACCENT_CHROMA` in the tool). Eyes smaller than one art pixel in
  the source can still vanish; put them back by hand (the warrior's teal eyes).
- **When a material comes out wrong** (a steel helmet turned bone-white, a face lost its skin colour),
  convert with `--no-prune --no-levels`: no ramp is dropped for being rare and each colour keeps its own
  shade instead of being stretched over the ramp. It gave the clean Covenant Recruit.
- **Features thinner than one art pixel** (a spear shaft one source block wide between two outline
  blocks) come out as outline only. Repaint the lit column by hand (the recruit's shaft: the left
  column in wood brown, the right one kept as its outline).

## Anchors (the first six, approved in-game before everything else)

**Status:** anchors 1-3 are in the game: the necromancer (owner's ~65 px image, `--inside-outline`, hood
eyes separated by hand), the Skeleton Warrior (~54 px image, `--inside-outline`, eyes restored by hand)
and the Covenant Recruit (~60 px image, `--inside-outline --no-prune --no-levels`, 50 art px so his
body is 40 under the spear, a few shaft pixels repainted by hand). Next: the Graveyard floor tile, the gravestone and the Shadow Bolt icon.

The anchors fix the style for everything else. Approve them **in order**, each on its check sheet and
in the game, then attach the approved ones to every later prompt. Each prompt is ready to paste.

### Anchor 1: the necromancer (`player/necromancer`, 56 art px)
```
Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter
top-down view (camera above and slightly in front), FULL BODY, FACING RIGHT, neutral ready stance.

LOW-RESOLUTION pixel art: the whole figure is only 56 pixels tall, drawn on a coarse pixel grid and
shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable
shapes; no detail smaller than 2 pixels except the eyes and small glints. No anti-aliasing, no
gradients, no dithering,
no texture noise, no soft glow haze, no fine trims or engravings.

Subject: a hooded necromancer in a long flowing robe with a tattered hem, a tall pointed hood with his
face in deep shadow and two small glowing violet eyes, two small bone skull pauldrons on the shoulders,
holding (in his front hand, on the right) a tall bone staff taller than himself, topped by a small
skull wreathed in violet soul-flame.
Signature shape that must read in silhouette: the tall staff with the flame at its top, and the
pointed hood.

Colours: ONLY flat fills from this list, at most 3 shades per material:
robe violet #4A2569 (shadow), #7A42AD (main), #A35CFA (lit edges and the soul-flame);
flame core #DDBDFF; bone #7F785F (shadow), #B4AA8A, #E8E1C8 (lit);
outlines #160A21 (robe) and #1C110B (bone).
Outline: a clean 1-pixel dark outline around the whole figure in the darkest shade of each part's own
colour (never pure black). Light from the top-left: the top-left edges one shade lighter. The robe's main
colour is the mid violet #7A42AD, not the dark one, so he stands out on a near-black ground (#161A1C).

Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white),
one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no
scenery, no text, no frame, no watermark.
```
Process: `python3 tools/prepare_sprite.py <image> player/necromancer` (add `--inside-outline` when the
image already has its own clean outline), then `python3 tools/art_check.py player/necromancer`.

### Anchor 2: the Skeleton Warrior (`summons/warrior`, 44 art px)
```
Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter
top-down view (camera above and slightly in front), FULL BODY, FACING RIGHT, neutral ready stance.

LOW-RESOLUTION pixel art: the whole figure is only 44 pixels tall, drawn on a coarse pixel grid and
shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable
shapes; no detail smaller than 2 pixels except the eyes and small glints. No anti-aliasing, no
gradients, no dithering,
no texture noise, no fine trims or engravings.

Subject: a skeleton warrior: a bone-white skull with two small teal-green glowing eye sockets, a
simple cold-grey iron helmet and breastplate, bone arms and legs, a big ROUND cold-grey shield with a
bone-white boss held in front on the left, a short straight sword in the right hand.
Signature shape that must read in silhouette: the big round shield.

Colours: ONLY flat fills from this list, at most 3 shades per material:
bone #7F785F (shadow), #B4AA8A, #E8E1C8 (lit); cold grey iron #3B4352 (shadow), #6B7A94, #A7B3C6 (lit);
eye glint #3DCC94; outlines #0F141C (iron) and #1C110B (bone).
Outline: a clean 1-pixel dark outline around the whole figure in the darkest shade of each part's own
colour (never pure black). Light from the top-left: the top-left edges one shade lighter.

Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white),
one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no
scenery, no text, no frame, no watermark.
Attached: the approved necromancer of this game. Match its pixel size, outline weight and palette exactly.
```
Process: `python3 tools/prepare_sprite.py <image> summons/warrior`.

### Anchor 3: the Covenant Recruit (`enemies/recruit`, 40 art px)
```
Pixel-art game sprite for a top-down 2D horde-survival game (like Vampire Survivors). Three-quarter
top-down view (camera above and slightly in front), FULL BODY, FACING RIGHT, neutral ready stance.

LOW-RESOLUTION pixel art: the whole figure is only 40 pixels tall, drawn on a coarse pixel grid and
shown enlarged so every pixel is a big crisp square block (nearest-neighbour). Chunky, simple, readable
shapes; no detail smaller than 2 pixels except the eyes and small glints. No anti-aliasing, no
gradients, no dithering,
no texture noise, no fine trims or engravings.

Subject: a young holy-order foot soldier: a round warm-steel kettle helmet over a plain face, a bright
crimson tabard over an ivory padded tunic, brown leather boots and belt, holding upright a LONG spear
(brown wooden shaft, steel tip) that rises well above his head.
Signature shape that must read in silhouette: the tall spear.

Colours: ONLY flat fills from this list, at most 3 shades per material:
crimson #7A0E1B (shadow), #C71A29 (main); ivory #B4AA8A (shadow), #E8E1C8; warm steel #5C5852,
#9C978C, #D4D0C6 (lit); skin #8C6040 (shadow), #E0A882; leather and wood #4F3320, #8C6040;
outlines #26070C (crimson) and #1C110B (everything else).
Outline: a clean 1-pixel dark outline around the whole figure in the darkest shade of each part's own
colour (never pure black). Light from the top-left: the top-left edges one shade lighter.

Output: a square PNG with a FULLY TRANSPARENT background (real alpha, not a checkerboard, not white),
one subject only, centred, filling about 85% of the image height. No ground, no cast shadow, no
scenery, no text, no frame, no watermark.
Attached: the approved sprites of this game. Match their pixel size, outline weight and palette exactly.
```
Process: `python3 tools/prepare_sprite.py <image> enemies/recruit`.

### Anchor 4: a Graveyard floor tile (`tiles/graveyard`, 128×128 art px, seamless)
```
A SEAMLESS, tileable ground texture for a top-down 2D pixel-art game, seen straight from above.
LOW-RESOLUTION pixel art: exactly 128 x 128 pixels, shown enlarged so every pixel is a big square
block. The left edge must continue the right edge and the top edge the bottom edge.

Subject: dark, damp graveyard soil at night: packed earth with a few faint cracks, a few small
pebbles and the odd tuft of dead grass. Very DARK and LOW CONTRAST: it is a background that every
character must stand out from. No objects that look solid, no gravestones, no paths, no characters.

Colours: ONLY flat fills from this list: soil #161A1C (most of the tile), earth #221C17, cracks
#0F141C, rare pebbles and grass #3B4352 (a few pixels only). No gradients, no dithering, no noise.

Output: a square PNG, the tile filling the whole image edge to edge. No border, no text, no watermark.
Attached: the approved sprites of this game, for the pixel size.
```
Process: `python3 tools/prepare_sprite.py <image> tiles/graveyard --art-height 128 --method mean
--no-outline --no-rim --no-prune --allow-floor --ramps floor,grey --no-center`. (Tiles are not drawn
by the game yet; the floor pass hooks them up.)

### Anchor 5: a gravestone, two sizes (`obstacles/gravestone_s`, `obstacles/gravestone_l`)
Collision radius 11 and 15 world px today, so the footprint is **22 and 30 art px wide**; the stones
stand **32 and 44 art px tall**.
```
Pixel-art game sprite for a top-down 2D horde-survival game. Three-quarter top-down view (camera above
and slightly in front), on a transparent background. TWO gravestones side by side with a wide
transparent gap between them, same style:
1) a small one, only 32 pixels tall and 22 pixels wide; 2) a large one, only 44 pixels tall and 30
pixels wide.
LOW-RESOLUTION pixel art, shown enlarged so every pixel is a big crisp square block. Chunky simple
shapes, no detail under 2 pixels, no anti-aliasing, no gradients, no dithering, no texture noise. A
clean 1-pixel dark outline.

Subject: old weathered headstones with a rounded top, slightly tilted, a dark chipped crack, a patch of
moss at the foot and a faint carved cross; the front face and the top visible.
Signature shape: the rounded headstone outline.

Colours: ONLY flat fills from this list: crypt stone #3B4352 (shadow), #6B7A94 (main), #A7B3C6 (lit
top edge); moss #3B5529, #76984A; outline #0F141C (never pure black). Light from the top-left.

Output: a PNG with a FULLY TRANSPARENT background, no ground, no cast shadow, no text, no watermark.
Attached: the approved sprites of this game. Match their pixel size, outline weight and palette exactly.
```
Process: cut the two stones apart (or ask for one per image), then
`python3 tools/prepare_sprite.py <small> obstacles/gravestone_s --art-height 32 --ramps grey,moss` and
`... obstacles/gravestone_l --art-height 44 --ramps grey,moss`. (Obstacles are not drawn from sprites
yet; the environment pass hooks them up.)

### Anchor 6: the Shadow Bolt icon (`icons/shadow_bolt`, 32×32 art px)
```
A pixel-art game ability icon, exactly 32 x 32 pixels, shown enlarged so every pixel is a big crisp
square block. A dark rounded-square badge filling the whole icon, with a clean 1-pixel border, and ONE
bold simple symbol in the middle: a violet magic bolt flying diagonally up-right, a pale core and a
short trail; no detail under 2 pixels. Readable at its real size of 32 pixels. No anti-aliasing, no
gradients, no dithering, no text.

Colours: ONLY flat fills from this list: badge #160A21, border #4A2569, bolt #7A42AD and #A35CFA,
bolt core #DDBDFF.

Output: a square PNG, the badge filling the image, transparent outside the badge's rounded corners.
Attached: the approved sprites of this game, for the pixel size and palette.
```
Process: `python3 tools/prepare_sprite.py <image> icons/shadow_bolt --art-height 32 --no-outline
--no-rim --ramps violet --no-center`.

## Walk cycles (`--frames`)

Walk cycles come after the stills (characters and summon classes first). A walk sheet is **4 poses in
one row**, same facing (right), same size and ground line, with transparent gaps between them:

1. **Idle / passing** (the still sprite's pose: feet together, body upright),
2. **left foot forward** (body 2 art px lower; 1 for units 40 art px or shorter),
3. **passing** (as 1, body 2 art px higher; 1 for the small units),
4. **right foot forward** (body 2 art px lower; 1 for the small units).

Ask for it with the prompt template plus: "a WALK CYCLE SPRITE SHEET: exactly 4 poses of the same
character in ONE horizontal row, left to right: 1 neutral stance, 2 left foot forward, 3 passing, 4
right foot forward; identical size, design, colours and ground line in every pose, clear empty
transparent space between the poses". Attach the approved still.

Process: `python3 tools/prepare_sprite.py <sheet> <key> --frames 4`. The poses are found by the
transparent gaps (or split into 4 equal columns), processed with one shared scale, ramp set and
shading, aligned (feet on the bottom row, body centred) and written to `assets/sprites/<key>_walk.png`:
4 frames side by side, no gaps, each the still's height (HEIGHTS) and the same even width (the
height when every pose fits in a square), so the frame width is the strip width / 4. The tool header
documents the layout for the engine.

## Effects (unchanged for now)

Effects stay short **smooth** animations processed with `--anim` (strips of 128 px frames in
`assets/sprites/effects/`, timing in `scripts/data/anim_data.gd`) until the effects pass. The pixel
art versions (palette colours, on the 1:1 art grid) come with that pass; the `--anim` table below lists the hooks.

---

## Asset manifest

**Art px** is the exact height of the stored PNG (= the on-screen `SpriteData.HEIGHTS`, drawn 1:1;
for flat sprites the longest side). **Status:** *to redo* = one of the 31 AI placeholders made before the pixel
art pass, to be regenerated with the new rules; *new* = no art yet. Colour words name palette ramps.

### Player (`assets/sprites/player/`)

Every character is the player: **violet** is theirs alone, and each keeps violet somewhere (robe,
eyes, flame) next to its school's accent, so the twelve read apart on the character picker yet all
read as "you" in a crowd. Until a file exists the game draws the necromancer tinted with the school
colour.

| File | Subject | Art px | Status |
|---|---|---|---|
| `necromancer.png` | The necromancer (Anchor 1) | 56 | to redo |
| `umbral_warden.png` | **The Umbral Warden** (Shadow Orb Shield): a broad hooded necromancer in layered dark violet robes over cold-grey plate, a tall staff topped by a black sun ringed with a violet corona, three small dark orbs orbiting the staff head; sturdier than the necromancer. Signature: the black-sun staff | 56 | new |
| `voidcaller.png` | **The Voidcaller** (Shadow Blast): a gaunt sorceress in an abyssal violet robe with a star-speckled hem, hood thrown back over a pale bone face, one hand raised with a ring of violet void energy, violet eyes. Signature: the raised void ring | 56 | new |
| `bone_oracle.png` | **The Bone Oracle** (Bone Spear): a necromancer in a carved bone skull mask and pale bone robes with violet trim, a bone spear held upright, three bone shards floating around him, violet eye glints. Signature: the upright spear and floating shards | 56 | new |
| `fallen_confessor.png` | **The Fallen Confessor** (Soul Siphon): a necromancer in corrupted clerical robes (stained ivory and violet), a torn crimson stole, a broken gold censer on a chain, teal-and-violet soul wisps drawn into his open hand. Signature: the hanging censer | 56 | new |
| `carrion_lord.png` | **The Carrion Lord** (Corpse Explosion): a hulking hooded necromancer in a gore-stained leather mantle with bone plates and a ribcage pauldron over violet robes, a cleaver-headed bone staff. Signature: the broad mantle and cleaver | 56 | new |
| `plague_scholar.png` | **The Plague Scholar** (Plague Cloud): a hunched necromancer in decaying moss-green alchemist robes over violet, a beaked plague mask, vials at the belt, a staff hung with a smoking censer leaking moss-green fumes. Signature: the beak and censer | 56 | new |
| `doomsayer.png` | **The Doomsayer** (Death Mark): a tall gaunt prophet in a near-black violet robe lined with crimson, a branding iron glowing in one hand, a crimson eye sigil on the hood. Signature: the tall thin hooded shape and branding iron | 56 | new |
| `barrow_warden.png` | **The Barrow Warden** (Bone Wall): a heavy-set warden in a mossy cold-grey cloak over violet, stacked bone-and-stone armour, a bone-slab tower shield, a shovel-headed staff. Signature: the slab shield | 56 | new |
| `soulbinder.png` | **The Soulbinder** (Soul Chains): a slender necromancer in a dark violet robe wrapped in spectral chains, pale icy lightning crackling along the chains and from her raised hand, robe edges lifting. Signature: the chains and raised hand | 56 | new |
| `wither_witch.png` | **The Wither Witch** (Wither): a crooked witch in a withered brown shawl over a violet robe, a wide frayed hat, dead leaves falling, a twisted dead-branch staff, a faint moss-green aura at her feet. Signature: the wide hat | 56 | new |
| `grave_herald.png` | **The Grave Herald** (Raise Dead): a necromancer herald in a dark violet tabard over bone mail, a raised bone horn, a banner pole topped with a skull, teal soul fire at his feet. Signature: the skull banner | 56 | new |

### Player skins (`assets/sprites/player/<character>_<skin>.png`, 56 art px)

Cosmetic skins (`scripts/data/skin_data.gd`; purely visual, never a stat). Until a file exists the game
draws the character's own sprite with the skin's palette tint, a small emblem and a faint aura. Use the
prompt template and attach **the character's own approved sprite** so the silhouette, pose and
proportions stay the same; only the costume and colours change. The twelve **Hyper skins** share one
theme: the character's regalia **gilded** (or, for the three shadow characters, **eclipsed** dark with
a gold corona), earned by clearing the Sanctum of Judgment on Hyper. Skins are the one place the player
may wear gold.

| File | Skin (character) | Subject (for the template) | Art px | Status |
|---|---|---|---|---|
| `gravecaller_dread_sovereign.png` | The Dread Sovereign (Gravecaller) | The necromancer in **black plate armour** with gold trim and a crimson-lined black cloak, a spiked **gold crown** over the hood, skull staff with gold fittings, violet eyes | 56 | new |
| `bone_oracle_ivory_seer.png` | The Ivory Seer (Bone Oracle) | The Bone Oracle in a **polished ivory** bone mask and mantle, bleached robes, a thin ivory **halo**, pale icy eyes | 56 | new |
| `plague_scholar_plague_doctor.png` | The Plague Doctor (Plague Scholar) | The Plague Scholar as a **plague doctor**: long **beaked leather mask** with green lenses, wide-brimmed black hat, waxed brown coat, a swinging censer with moss-green smoke | 56 | new |
| `fallen_confessor_heretic_saint.png` | The Heretic Saint (Fallen Confessor) | The Fallen Confessor in **defiled ivory vestments** stained crimson, a **cracked crimson halo**, torn holy stole | 56 | new |
| `gravecaller_hyper.png` | Eclipsed Gravecaller (Gravecaller) | The necromancer **eclipsed**: robes darkened to near-black violet, a **gold sun corona** behind the hood, gold-rimmed staff orb | 56 | new |
| `umbral_warden_hyper.png` | Sunless Warden (Umbral Warden) | The Umbral Warden eclipsed: armour darkened to black, a **gold corona** behind the helm, gold edges on the shield | 56 | new |
| `voidcaller_hyper.png` | Starless Voidcaller (Voidcaller) | The Voidcaller eclipsed: a starless black robe, a **gold corona** ring behind the head, a gold-framed void orb | 56 | new |
| `bone_oracle_hyper.png` | Gilded Oracle (Bone Oracle) | The Bone Oracle **gilded**: gold-leaf skull mask and ornaments, gold trim, a gold sun corona | 56 | new |
| `carrion_lord_hyper.png` | Crowned Carrion Lord (Carrion Lord) | The Carrion Lord **gilded**: tarnished-gold armour, a gold crown, gold sun corona | 56 | new |
| `fallen_confessor_hyper.png` | Fallen Seraph (Fallen Confessor) | The Fallen Confessor as a **fallen seraph**: gilded vestments, broken **gold wings**, a gold sun corona | 56 | new |
| `plague_scholar_hyper.png` | Blighted Scholar (Plague Scholar) | The Plague Scholar **blighted gold**: robes of sickly gold-green, gold vials, a gold sun corona | 56 | new |
| `doomsayer_hyper.png` | Final-Hour Doomsayer (Doomsayer) | The Doomsayer **gilded**: gold hourglass and chains, gold trim, a gold sun corona | 56 | new |
| `barrow_warden_hyper.png` | Gilded Barrow King (Barrow Warden) | The Barrow Warden as a **barrow king**: gold grave-goods armour, a gold circlet, a gold sun corona | 56 | new |
| `soulbinder_hyper.png` | Radiant Soulbinder (Soulbinder) | The Soulbinder **gilded**: gold soul chains, radiant gold trim, a gold sun corona | 56 | new |
| `wither_witch_hyper.png` | Thorn-Crowned Witch (Wither Witch) | The Wither Witch **gilded**: a crown of gold thorns, gold-dusted withered robes, a gold sun corona | 56 | new |
| `grave_herald_hyper.png` | Golden Herald (Grave Herald) | The Grave Herald **gilded**: a gold horn and tabard, gold trim, a gold sun corona | 56 | new |

### Summons (`assets/sprites/summons/`)

The undead army: bone, cold grey and teal soul fire, one accent per class, **no violet**.

| File | Subject | Art px | Status |
|---|---|---|---|
| `warrior.png` | Skeleton Warrior (Anchor 2): bone skull and limbs, cold-grey iron, a round cold-grey shield with a bone boss, short sword, teal eye glints. Signature: the round shield | 44 | done |
| `archer.png` | Skeleton Archer: bone body, a **moss-green** hood and short cloak (the Archer's accent), a bone bow drawn with a teal soul-fire arrow. Signature: the bow | 44 | done |
| `mage.png` | Undead Mage: skeleton in a tattered **deep arcane-blue** robe, a staff with an arcane-blue orb (pale blue core). Signature: the orb staff | 46 (body 44, orb above) | done |
| `mender.png` | Grave Mender: skeletal priest in a round **teal** robe, a teal halo, a swinging bone censer. Signature: the halo | 52 (body 44, halo above) | done |
| `warder.png` | Crypt Warder: skeleton in a cold-grey robe with **teal** trim, holding up a shield-shaped teal ward sigil. Signature: the raised sigil | 48 (body 44, sigil raised) | done |
| `bishop.png` | Profane Bishop: tall teal-and-grey vestments, a bone mitre, a teal halo, a bone crook | 64 (body 52, halo above) | done |
| `death_knight.png` | Death Knight: massive dark cold-grey plate, a skull helm with teal eye glow, a bone-white greatsword | 52 | done |
| `lich.png` | Lich: a crowned skeletal sorcerer in a **deep arcane-blue** robe, a floating phylactery with a pale blue core, bone crown. Signature: the phylactery | 52 | done |
| `abomination.png` | Corpse Abomination: a huge stitched hulk of sickly moss-grey corpse flesh, bone spikes, tiny skull head, teal eyes | 88 | done |
| `rogue.png` | Grave Rogue: a lean skeleton in a near-black cold-grey hooded cloak, twin curved bone daggers, teal eyes | 44 | done |
| `gargoyle.png` | Crypt Gargoyle: cold-grey weathered stone gargoyle, wings half-spread, long claws | 56 | done |
| `frost_wraith.png` | Frost Wraith: a **pale icy cyan** spectre (ice ramp, grey shadows), a tattered robe trailing into frost mist, cold white eyes. Kept clearly apart from the Mage's arcane blue | 48 | done |
| `risen.png` | Raised temporary skeleton: plain, ragged, bone with faint teal eyes | 36 | done |
| `winter_revenant.png` | Winter Revenant (Frost Wraith evolution): a towering crowned ice wraith in tattered **pale icy cyan** frost robes, a staff of dark ice, the brightest ice highlights | 56 | done |
| `shadow_reaper.png` | Shadow Reaper (Grave Rogue evolution): a hooded skeletal assassin in a near-black cold-grey cloak with dark smoke trailing, a bone skull mask with teal eyes, twin scythe-blades (one forward, one swept back) | 48 | done |
| `cathedral_horror.png` | Cathedral Horror (Crypt Gargoyle evolution): a huge winged gargoyle of cracked pale stone (light grey and bone), wide ribbed stone wings, ram horns, teal runes carved into its chest, gripping a broken plinth; clearly bigger than the Gargoyle | 64 | done |
| `gravebow.png` | Gravebow (Archer evolution): an ornate skeletal archer in a tall ragged **moss-green** hood, teal eye glow, a bone quiver, drawing a HUGE bone longbow (taller than itself, bone spikes at the tips) with a teal soul-fire arrow | 54 (body 48, longbow above) | done |
| `bone_colossus.png` | Bone Colossus (Abomination evolution): a towering hulk of moss-grey corpse flesh armoured in fused bone plates: a ribbed bone breastplate, spiked bone pauldrons, a horned bone helm with teal eyes, a bone-slab club arm | 100 | done |
| `bone_hound.png` | Bone Hound: a lean, low skeletal hound seen from the side, long ribcage, thin legs, a long snouted skull with a teal eye, a curled bone tail; small, fast, feral | 32 | done |
| `hellhound.png` | Hellhound (Bone Hound evolution): the hound charred dark brown with glowing fire cracks along the ribs, a mane of flame along the neck and back, burning eyes; bigger and fiercer | 40 | done |
| `banshee.png` | Banshee: a legless floating spectre in a pale bone-white veil that frays into wisps, long white hair streaming back, arms raised, a dark wide-open wailing mouth, faint teal glow | 48 | done |
| `keening_lady.png` | Keening Lady (Banshee evolution): a taller, regal banshee in a flowing dark cold-grey gown, a bone circlet with a teal gem, a pale screaming face, teal sound ripples | 56 | done |
| `corpse_catapult.png` | Corpse Catapult: a squat siege engine of old coffin wood (brown) and bone beams on two bone wheels, sinew ropes, a diagonal throwing arm with a skull boulder (teal eyes) in its cup | 56 | done |
| `ossuary_engine.png` | Ossuary Engine (Corpse Catapult evolution): a bigger siege engine of ribcages and spines, fire-lit sinew, a triple cup of three burning skulls | 72 | done |

### Covenant enemies (`assets/sprites/enemies/`)

Crimson, ivory and warm steel; gold for elites, the Sanctum kinds and the Reckoning.

| File | Subject | Art px | Status |
|---|---|---|---|
| `recruit.png` | Covenant Recruit (Anchor 3): kettle helm, crimson tabard over ivory, a tall spear. Signature: the spear | 50 (body 40, spear above) | done |
| `footman.png` | Crimson Footman: heavy warm-steel armour, a crimson kite shield, a sword. Signature: the kite shield | 48 | done |
| `archer.png` | Zealous Archer: ivory-and-crimson archer with a tall longbow. Signature: the longbow | 50 (body 40, longbow above) | done |
| `chaplain.png` | Covenant Chaplain: ivory robes, a gold censer, a faint holy glint. Signature: the censer | 42 | done |
| `purifier.png` | Purifier: a warm-steel mask, a flaming torch-censer (flame). Signature: the flame | 44 | done |
| `templar.png` | Templar Knight: gold-trimmed heavy knight, a lance, a crimson cape. Signature: the lance | 78 (body 52, lance above) | done |
| `inquisitor.png` | Inquisitor of the End (Reckoning): towering, radiant gold and holy white, faceless (glow allowed) | 64 | done |
| `shieldbearer.png` | Covenant Shieldbearer: a huge crimson tower shield covering the body. Signature: the tower shield | 56 (body 50, spear tip above) | done |
| `banner_bearer.png` | Banner Bearer: a tall crimson-and-gold war banner on a pole. Signature: the banner | 84 (body 44, banner above) | done |
| `halberdier.png` | Crimson Halberdier: a long halberd, warm-steel half-plate. Signature: the halberd | 60 (body 46, halberd above) | done |
| `sanctified_sentinel.png` | Sanctified Sentinel (Stage 3 construct): a squat, blocky animated statue of pale cathedral stone (bone ramp) inlaid with gold lines, a glowing gold eye slit in a square head, one arm a long stone blade held forward; no cloth | 72 | done |
| `radiant_inquisitor.png` | Radiant Inquisitor (Stage 3 elite caster): a tall inquisitor in ivory robes with a crimson stole, face hidden under a hood, a gold sunburst halo of rays, a gold-bound tome | 68 (body 56, halo above) | done |
| `high_confessor.png` | High Confessor (Stage 3 elite priest): a broad figure in wide ivory vestments with a crimson stole, a tall gold mitre, a gold crook staff with a faint halo | 64 (body 52, mitre and crook above) | done |
| `sun_paladin.png` | Sun Paladin (Stage 3 elite): gilded heavy plate, a gold heater shield with a crimson sun, a gold great helm with an ivory plume, a lance | 70 (body 56, lance above) | done |
| `cathedral_guardian.png` | Cathedral Guardian (Stage 3 miniboss): a giant colossus of pale cathedral stone with gold trim, a stained-glass rose window in its chest (arcane blue, crimson, gold), a square head crowned with three gold spires, two huge stone fists | 140 | done |

### Bosses (`assets/sprites/bosses/`)
| File | Subject | Art px | Status |
|---|---|---|---|
| `alaric.png` | Sir Alaric, the Gravebreaker: a giant paladin, a holy warhammer, gold, ivory and warm steel | 120 | done |
| `vael.png` | Marshal Vael, the Crimson Bulwark: a great crimson kite shield, a flaming sword, a crimson plume | 120 | done |
| `seraphine.png` | Grand Inquisitor Seraphine, Voice of the Dawn (Stage 3): a winged Inquisitor in a white-and-gold bell robe with a crimson stole and a gold sun on the chest, a white veil and gold circlet, a gold **sun halo** with rays, two feathered ivory wings spread up behind her shoulders, a tall gold **relic staff** crowned by a sunburst reliquary | 130 | done |
| `seraphine_avatar.png` | *Optional.* Her **Avatar of the Dawn** form (phases 2-3): the same figure larger and brighter, wings spread wide with gold-edged feathers, a long-rayed halo, the relic blazing holy white | 156 | done |

### Structures (`assets/sprites/structures/`)
| File | Subject | Art px | Status |
|---|---|---|---|
| `outpost.png` | Siege outpost: a crimson-banner palisade tent | 96 | to redo |
| `ward_generator.png` | Holy Ward Generator: a gold-ringed obelisk with a radiant core | 80 | to redo |
| `supply_cart.png` | Covenant supply cart (seen from above) | 72 | to redo |
| `holy_standard.png` | Vael's Holy Standard: an ornate gold banner pole | 72 | to redo |
| `watchtower.png` | Checkpoint watchtower: a wooden tower with a crimson pennant | 96 | to redo |
| `ward_crystal.png` | Sanctum ward crystal: a tall faceted ivory-and-gold crystal on a round pale-stone plinth, gold glow | 56 | new |
| `sacred_altar.png` | Sanctum sacred altar: a wide pale-stone altar block draped in gold cloth with a crimson stripe, two lit candles, a gold sun disc standing behind it | 72 | new |

(`ward_crystal` and `sacred_altar` have no `SpriteData.HEIGHTS` entry yet; the art px assume 56 and 72
on screen.)

### Pickups (`assets/sprites/pickups/`)
| File | Subject | Art px | Status |
|---|---|---|---|
| `xp_crystal.png` | Small soul crystal (soul ramp, a glint of soul_glow) | 16 | new |
| `chest.png` | Bone-and-iron treasure chest with a violet lock glint (the player's reward) | 40 | new |
| `pu_magnet.png` | Soul Magnet: a teal soul vortex charm | 28 | new |
| `pu_feast.png` | Grave Feast: dark roasted meat on a bone | 28 | new |
| `pu_hyper.png` | Hyper: a violet lightning rune | 28 | new |
| `pu_stasis.png` | Stasis: a frozen hourglass (ice) | 28 | new |
| `pu_frenzy.png` | Dark Frenzy: a flaming skull (flame) | 28 | new |
| `pu_nova.png` | Soul Nova: a violet starburst | 28 | new |

### Projectiles (`assets/sprites/projectiles/`)

Flat sprites the game **rotates along their flight path**: draw each **pointing right** (head at the
right, trail to the left), transparent background. Art px = the longest side (`SpriteData.FLAT_SIZES`). Player spells are violet; summon shots use their class colours.

| File | Subject | Art px | Status |
|---|---|---|---|
| `shadow_bolt.png` | Shadow Bolt: a violet bolt with a pale core and a short trail | 22 | new |
| `void_bolt.png` | Void Barrage bolt: a black-violet core with a violet trail | 30 | new |
| `void_shard.png` | Void shard: a tiny violet crystal splinter | 14 | new |
| `bone_spear.png` | Bone Spear: a sharpened bone javelin | 26 | new |
| `ossuary_lance.png` | Ossuary Lance: a huge bone lance wrapped in violet energy | 44 | new |
| `arrow.png` | Skeleton Archer arrow: a bone shaft with a teal soul-fire head | 20 | new |
| `mage_orb.png` | Undead Mage orb: an arcane-blue orb with a pale core | 20 | new |
| `priest_bolt.png` | Mender / Warder bolt: a small teal mote | 14 | new |
| `frost_bolt.png` | Frost Wraith bolt: a pale icy shard | 20 | new |
| `orb.png` | Shadow Orb Shield orb: a round violet orb (not pointed; it doesn't rotate) | 18 | new |
| `enemy_arrow.png` | Covenant arrow: an ivory shaft with a gold head | 20 | new |
| `radiant_bolt.png` | Covenant holy bolt: a gold and holy-white spark | 20 | new |

### Icons (`assets/sprites/icons/`, 32×32 art px)

Square **badge icons** for level-up cards, the HUD ability bar and buff timers: a **dark rounded-square
badge** with a 1 px border and **one bold symbol**, 32×32 art px (shown about 1× to 2× in the 32, 48
and 64 px boxes). Player
spells and passives use violet with bone; summon icons use their class colours; never Covenant gold or
crimson on the player's icons (the Hyper badge and the Profane Pact excepted). Evolutions add a
gold-trimmed frame. The Shadow Bolt icon is Anchor 6; the rest come in the icons pass. Status: all new.

| File | Subject |
|---|---|
| `shadow_bolt.png` | Violet bolt (Anchor 6) |
| `hyper_badge.png` | **Hyper clear badge**: a gold sun disc with eight short rays and a dark five-pointed star in the middle (the one player-side icon that may use gold) |
| `orb_shield.png` | Three violet orbs circling |
| `shadow_blast.png` | Violet shockwave ring |
| `bone_spear.png` | Crossed bone javelins |
| `soul_siphon.png` | A violet soul stream flowing into a skeletal hand |
| `corpse_explosion.png` | Bursting corpse / bone shrapnel |
| `plague_cloud.png` | Moss-green miasma cloud with a skull |
| `void_barrage.png` | Black-and-violet void bolts (evolution frame) |
| `eclipse_ward.png` | Eclipsed black orbs in a ring (evolution frame) |
| `abyssal_detonation.png` | Imploding violet vortex (evolution frame) |
| `ossuary_lance.png` | Huge bone lance (evolution frame) |
| `soul_rapture.png` | Many soul tethers to a skull (evolution frame) |
| `grave_eruption.png` | Bone spikes erupting from a grave (evolution frame) |
| `pestilence.png` | Swirling plague with a death's-head (evolution frame) |
| `death_mark.png` | Death Mark: a violet brand sigil (ring with an inverted triangle) around a small skull |
| `doom_brand.png` | Doom Brand: three linked brand sigils around a violet core (evolution frame) |
| `bone_wall.png` | Bone Wall: a row of jagged bone spikes rising from a stone base |
| `charnel_bastion.png` | Charnel Bastion: a closed ring of bone spikes around a skull (evolution frame) |
| `soul_chains.png` | Soul Chains: a jagged violet soul-lightning bolt arcing between three small souls |
| `chains_of_the_damned.png` | Chains of the Damned: a forked violet lightning burst ending in bone chain links (evolution frame) |
| `wither.png` | Wither: a moss-green aura ring with drooping decay motes around a small robed figure |
| `necrotic_blight.png` | Necrotic Blight: a wide moss-green aura ring feeding a dark violet heart (evolution frame) |
| `raise_dead.png` | Raise Dead: a bare skeleton clawing out of a grave-dirt line, teal soul-fire at its feet |
| `legion_of_bones.png` | Legion of Bones: three skulls rising together over a grave line (evolution frame) |
| `death_knight.png` | Skull helm with a greatsword (evolution frame) |
| `lich.png` | Crowned skull with an arcane-blue phylactery (evolution frame) |
| `profane_bishop.png` | Bone mitre with a teal halo (evolution frame) |
| `winter_revenant.png` | Ice-crowned wraith head with a dark-ice staff (evolution frame) |
| `shadow_reaper.png` | Hooded skull mask between two crossed scythe-blades (evolution frame) |
| `cathedral_horror.png` | Horned stone gargoyle head with a glowing teal rune (evolution frame) |
| `gravebow.png` | Bone longbow with a teal soul-fire arrow (evolution frame) |
| `bone_colossus.png` | Horned bone helm over a ribbed bone breastplate (evolution frame) |
| `bone_hound.png` | Snarling skeletal hound head in profile |
| `banshee.png` | Pale wailing veiled face with streaming hair |
| `corpse_catapult.png` | Bone catapult arm with a skull in its cup |
| `hellhound.png` | Flaming charred hound head (evolution frame) |
| `keening_lady.png` | Crowned banshee face with teal sound ripples (evolution frame) |
| `ossuary_engine.png` | Triple cup of burning skulls on a rib-cage arm (evolution frame) |
| `grave_dominion.png` | Gravestone with a violet rune |
| `necrotic_vigor.png` | A heart made of bone with a violet glint |
| `dark_command.png` | Violet crown |
| `soul_recycling.png` | Teal circular soul arrow |
| `soul_conduit.png` | Violet crystal channelling energy |
| `warding_ritual.png` | Runic shield circle |
| `abyssal_focus.png` | Violet eye in a void |
| `forbidden_knowledge.png` | Chained grimoire |
| `dark_benediction.png` | Inverted halo over cupped bone hands |
| `shade_stride.png` | Shadowy boot / footprints |
| `vampiric_rite.png` | Blood-red drop in a chalice (one crimson accent is fine) |
| `necrotic_expanse.png` | Expanding violet rings |
| `lingering_malediction.png` | Hourglass with moss-green mist |
| `bone_plating.png` | Shield of overlapping bone plates with a small teal rune |
| `unholy_precision.png` | Bone arrowhead under a violet crosshair eye |
| `unholy_resilience.png` | Cracked, drained holy sun behind a dark undead shield |
| `bound_souls.png` | Teal soul wisp held by a short iron chain |
| `grim_ledger.png` | An open bone-bound ledger, a small violet crown above it |
| `spirit_binding.png` | A pale soul held in a loop of violet-and-bone chain links |
| `restless_dead.png` | A bone hourglass with teal mist, a small skull in its lower bulb |
| `blood_scent.png` | A blood drop with bone-white speed streaks (one crimson accent is fine) |
| `mournsong.png` | A pale weeping spectral face with two teal notes |
| `siegecraft.png` | A cracked grey tower struck by a bone boulder |
| `stance_escort.png` | Army stance Escort (HUD stance bar): a teal guard arc of bone escorts sheltering a small violet necromancer mark |
| `stance_onslaught.png` | Army stance Onslaught: three flame arrows bursting outward from a small violet mark |
| `stance_spearhead.png` | Army stance Spearhead (also its Ossuary unlock): a V-wedge of bone pointing up, the violet mark behind its tip |
| `stance_bone_ring.png` | Army stance Bone Ring: a closed ring of bone around a small violet mark |
| `profane_pact.png` | Torn scroll with a crimson seal (the curse: the one icon allowed crimson) |
| `powerup_magnet.png` | Teal soul vortex |
| `powerup_feast.png` | Roasted meat on a bone |
| `powerup_hyper.png` | Violet lightning rune |
| `powerup_stasis.png` | Frozen hourglass |
| `powerup_frenzy.png` | Flaming skull |
| `powerup_nova.png` | Violet starburst |
| `grave_step.png` | Grave Step (dash): a hooded violet shadow stepping sideways, two fading afterimages behind it |
| `dread_rally.png` | Dread Rally (ultimate): a skull inside a dark violet burst ring, soul wisps rising |
| `twin_shadow.png` | Ossuary Twin Shadow: two overlapping hooded shadow silhouettes (second dash charge) |
| `restless_shade.png` | Ossuary Restless Shade: a hooded shadow inside a teal clock arc (shorter dash cooldown) |

### Environments (later pass, no prompts yet)

Floors, decals and obstacles come after the units. Floors are **dark, low-saturation and
narrow-value**; nothing on the floor may look solid unless it collides. Not hooked up yet: the floors
are code-drawn by `Ground`, `MarchGround` and `SanctumGround`, the obstacles by the stage glyphs.

**Zone floors** (`assets/sprites/tiles/`, 128×128 art px seamless, 2-4 variants each, later pass):

| File | Zone | Look (today's code floor) | Status |
|---|---|---|---|
| `graveyard.png` | The Desecrated Graveyard | dark soil, faint cracks, pebbles, dead grass (Anchor 4) | anchor |
| `march_burned.png` | March I, the Burned Road | ash-grey scorched earth, soot, embers | later pass |
| `march_checkpoint.png` | March II, the Fortified Checkpoint | dark forest grass and mud | later pass |
| `march_camp.png` | March III, the Siege Camp | trampled brown dirt | later pass |
| `march_fortress.png` | March IV, the Fortress Approach | dark cobbles and grit | later pass |
| `sanctum_courtyard.png` | Sanctum I, the Outer Courtyards | pale-stone flagstones in staggered courses, moss in the joints (kept dark) | later pass |
| `sanctum_halls.png` | Sanctum II, the Sanctified Halls | a dark-gold mosaic of small tesserae | later pass |
| `sanctum_cloisters.png` | Sanctum III, the Cloisters | stone walks around trimmed turf | later pass |
| `sanctum_sanctuary.png` | Sanctum IV, the Final Sanctuary | grey marble slabs with veins | later pass |
| `march_road.png` | The March road along y = 0 | a horizontal strip **140 art px tall** (road width 140 world px) tiling left-right: packed earth with darker verges and wheel ruts; a paved variant for the Fortress Approach | later pass |

The Sanctum floors are blended toward purple as the Sanctum is corrupted, so do not bake purple in.

**Decals** (small flat floor details scattered by hash, transparent background, later pass): per zone,
the ones the code draws today:
- Graveyard: fog patch (soft, translucent: stays code-drawn), grass tufts, open grave, small flat
  tombstone, stone cross.
- March I: ash drift, charred stump, embers, spent arrow, broken plank. March II: grass tufts, mud
  patch, sharpened stakes, crimson pennant. March III: trampled dirt, campfire, tent rope and peg,
  small crate. March IV: cobbles, rubble, gold-and-crimson banner post, tower shadow.
- Sanctum I: moss, cracked slab, gold inlay star, fallen petals. Sanctum II: gold tesserae, mosaic
  rosette, diamond inlay, crimson carpet runner. Sanctum III: turf, flowers, sundial ring, leaves.
  Sanctum IV: stained-glass light pool (translucent: stays code-drawn), marble vein, inlaid square.

**Obstacles** (`assets/sprites/obstacles/<kind>_<size>.png`, later pass): each kind comes in **2-3
fixed size variants**, each with a collision shape that matches it exactly (inside today's random
size ranges, `scripts/data/stages/*.gd` "kinds"). Footprint in art px (1 art px = 1 world px): a
circle of collision radius *r* world px is *2r* art px across; a rect of *L* × *S* world px is *L* × *S*
art px. Sprites stand taller than their footprint (a tree's canopy, a wall's face). Long walls are built
from a left cap, a repeatable middle and a right cap.

| Stage / zone | Kind | Shape | Variants (world px) → footprint (art px) |
|---|---|---|---|
| Graveyard | `gravestone` | circle | r 11 / 13 / 15 → 22 / 26 / 30 wide (Anchor 5: S and L) |
| Graveyard | `dead_tree` | circle (trunk) | r 13 / 15 / 18 → trunk 26 / 30 / 36 wide, tree ~80-100 tall |
| Graveyard | `crypt_wall` | rect | 64 / 80 / 96 × 20 → 64 / 80 / 96 × 20 (caps + middle) |
| March I | `burned_house` | rect | 64 / 78 / 92 × 44 → 64 / 78 / 92 × 44 |
| March I | `charred_tree` | circle | r 12 / 14 / 17 → 24 / 28 / 34 |
| March I | `cart_wreck` | rect | 40 / 48 / 56 × 22 → 40 / 48 / 56 × 22 |
| March II | `barricade` | rect | 64 / 80 / 96 × 16 → 64 / 80 / 96 × 16 (caps + middle) |
| March II | `pine` | circle | r 14 / 16 / 19 → 28 / 32 / 38 |
| March II | `stakes` | circle | r 12 / 15 → 24 / 30 |
| March III | `tent` | circle | r 22 / 26 / 30 → 44 / 52 / 60 |
| March III | `crates` | rect | 36 / 44 / 52 × 26 → 36 / 44 / 52 × 26 |
| March III | `siege_engine` | rect | 70 / 80 / 90 × 34 → 70 / 80 / 90 × 34 |
| March IV | `fort_wall` | rect | 80 / 96 × 24 → 80 / 96 × 24 (caps + middle) |
| March IV | `tower_base` | circle | r 26 / 30 / 34 → 52 / 60 / 68 |
| March IV | `rubble` | circle | r 12 / 15 / 18 → 24 / 30 / 36 |
| Sanctum I | `saint_statue` | circle | r 13 / 15 / 17 → 26 / 30 / 34 |
| Sanctum I | `fountain` | circle | r 28 / 32 / 36 → 56 / 64 / 72 |
| Sanctum I | `stone_bench` | rect | 44 / 52 / 60 × 16 → 44 / 52 / 60 × 16 |
| Sanctum II | `pillar` | circle | r 13 / 15 → 26 / 30 |
| Sanctum II | `pew` | rect | 60 / 68 / 76 × 14 → 60 / 68 / 76 × 14 |
| Sanctum III | `cloister_arch` | rect | 72 / 82 / 92 × 18 → 72 / 82 / 92 × 18 (caps + middle) |
| Sanctum III | `garden_bed` | rect | 44 / 52 / 60 × 30 → 44 / 52 / 60 × 30 |
| Sanctum III | `cypress` | circle | r 11 / 14 → 22 / 28 |
| Sanctum IV | `giant_statue` | circle | r 28 / 32 / 36 → 56 / 64 / 72 |
| Sanctum IV | `marble_column` | circle | r 15 / 17 / 19 → 30 / 34 / 38 |
| Sanctum IV | `reliquary` | rect | 40 / 46 / 52 × 26 → 40 / 46 / 52 × 26 |

### Effects (`assets/sprites/effects/`, `--anim`)

Short **one-shot animations** (explosions, bursts, flashes) that play once, centred on the effect and
scaled to its gameplay radius. Each is a **sprite sheet of 6-10 frames** (or a short GIF), seen
**straight from above**, on a transparent background. Process it with
`python3 tools/prepare_sprite.py --anim <sheet or GIF> <id>`; the tool finds the frames (by the
transparent gaps between them, or `--frames N` for N equal frames in a row, or `--grid CxR`), crops
them to one square around the effect and writes a strip of 128 px frames. Timing and on-screen fill
are set per effect in `scripts/data/anim_data.gd`. Without the file, the game keeps today's drawn
shape. **Shadow Blast** (the test), **Dread Rally**, the **Grave Step** puff and Seraphine's
**nova**, **holy beam** flare and **relic shatter** are wired so far; the rest get their code hook
when their art arrives. Use palette colours; player effects are violet, undead teal, Covenant gold.

| Id | Effect | Frames |
|---|---|---|
| `shadow_blast` | **Test first.** Shadow Blast: a violet shockwave ring bursting outward from a dark centre, then fading to wisps | 8 |
| `abyssal_detonation` | Abyssal Detonation: a black-violet vortex imploding, then exploding with pale violet sparks | 10 |
| `corpse_explosion` | Corpse Explosion: a burst of bone shrapnel and dark gore mist | 8 |
| `grave_eruption` | Grave Eruption: bone spikes stabbing up from the ground in a ring, then crumbling | 8 |
| `bolt_impact` | Shadow Bolt hit: a small violet splash with sparks | 6 |
| `summon_rise` | Summon rising: teal soul-fire swirling up from a grave-dirt circle | 8 |
| `undead_death` | Undead destroyed: bones scattering and a teal soul wisp rising | 6 |
| `enemy_death` | Covenant soldier dies: a crimson-and-ivory burst fading into gold motes | 6 |
| `holy_impact` | Covenant hammer / boss slam: a gold radiant shockwave with ivory dust | 8 |
| `soul_nova` | Soul Nova: a huge violet-and-teal ring of souls expanding across the screen | 10 |
| `level_up` | Level-up: a column of violet light with rising runes | 8 |
| `frost_shatter` | Winter Revenant shatter: a frozen body bursting into pale icy shards, then glittering frost (wired) | 6 |
| `frost_nova` | Winter Revenant death nova: a ring of freezing frost racing outward from a cold-white centre (wired) | 8 |
| `chest_open` | Treasure chest bursting open with violet light and bone-coloured sparks | 8 |
| `evolution` | Evolution: a dark vortex collapsing into a bright violet-gold flash | 10 |
| `dread_rally` | **Hooked.** Dread Rally: a deep violet shockwave bursting out of a skull-shaped flare, souls streaking outward, then fading to dark wisps | 10 |
| `grave_step_trail` | **Hooked.** Grave Step departure: a puff of violet shadow smoke left where the necromancer stepped from, curling and thinning away | 6 |
| `seraphine_nova` | **Hooked.** Seraphine's Judgment nova: a huge gold and ivory ring of holy light racing outward from a white-hot centre, sun-ray streaks, then fading to gold motes (played at the full nova radius: keep the ring thin and the centre empty) | 10 |
| `holy_beam` | **Hooked.** Seraphine's holy beams igniting: a white-gold flare bursting from her relic, with short gold rays (the beams themselves stay drawn) | 6 |
| `relic_shatter` | **Hooked.** Seraphine's death: the sunburst relic cracking and exploding into gold and ivory shards and a ring of white light, then guttering out | 10 |
| `soul_lightning` | **Hooked.** Soul Chains strike: a small violet lightning flash with a pale core and crackling sparks, played on each struck foe | 6 |
| `bone_wall_rise` | **Hooked.** Bone Wall: one cluster of bone spikes bursting up out of cracked grave dirt, with a puff of dust | 6 |
| `bone_wall_burst` | **Hooked.** Charnel Bastion expiring: a bone-spike cluster exploding into flying bone shrapnel with a violet flash | 8 |
| `wither_aura` | **Hooked.** One Wither pulse: a thin ring of moss-green decay mist racing outward and dissolving into falling motes (played at the aura radius, keep the centre empty) | 8 |
| `doom_burst` | **Hooked.** Doom Brand detonation: a brand sigil flaring and bursting into a ring of violet doom-fire | 8 |
| `raise_dead` | **Hooked.** Raise Dead: grave dirt cracking open and a teal soul-fire swirl as a skeletal hand claws up | 8 |
| `legion_burst` | **Hooked.** Legion of Bones: a crumbling skeleton bursting into a ring of bone shards and dust | 8 |

**Sprite-sheet prompt** (attach the approved anchors as the style reference):
```
Using the attached images only as the pixel-art style reference (same pixel size, outline weight and
palette), create a SPRITE SHEET for a one-shot visual effect in a top-down 2D horde-survival game,
seen straight from above.

Effect: <EFFECT DESCRIPTION FROM THE TABLE>.

Layout: exactly <N> frames in ONE horizontal row, left to right in play order, every frame the same
size, the effect centred in each frame, with clear empty transparent space between frames. Frame 1 is
the very start (small), the middle frames are the peak, and the last frames fade and break up.
Crisp pixel art (big square pixels, no anti-aliased blur), flat colours, bright and readable on a very
dark ground (#161A1C). Fully transparent background (real alpha, not a checkerboard). No ground, no
characters, no text, no frame numbers, no watermark.
```

Tips:
- The frames must line up: the centre of the burst should stay in the same place in every frame. If
  the AI drifts, ask it to "redraw the same effect with identical centre and design in every frame,
  only the expansion changes", or send the sheet to Claude.
- A short GIF works as well as a sheet; send whichever comes out cleaner.
