# Necropathy: Art Bible and Prompt Pack

This document defines how Necropathy's art is made, processed, checked and wired into the game. It is
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
   motion); the main units also have 8-frame walk strips cut from their stills (see "Walk cycles").

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

**The locked palette** (`tools/palette.json`, the single source of truth; 47 colours: 37 for sprites,
10 floors). Ramps run dark to light; the first colour of each ramp is its **outline ink**. Colours
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
| **floor** | floor_soil `#161A1C` 0.21 · floor_earth `#221C17` 0.23 · floor_grass `#1A2218` 0.24 · floor_ochre `#2E2615` 0.27 · floor_slate `#26272A` 0.27 · floor_ash `#2A2724` 0.28 · floor_dirt `#30261B` 0.28 · floor_moss `#26301F` 0.29 · floor_marble `#2D2E33` 0.30 · floor_stone `#312E2B` 0.30 | ground colours of the three stages (tiles only, never sprites); the seven middle shades came with the zone floor tiles |

`prepare_sprite.py` limits each folder to its faction's ramps (player: everything but skin and warm
steel; summons: bone, grey, soul, moss, arcane, ice, brown, with flame only for the Hellhound and the
Ossuary Engine, no ice for the Mage and Lich and no arcane for the frost summons; enemies and bosses:
bone, steel, crimson, brown, gold, skin, flame; structures: the same without skin); `--ramps a,b`
overrides it. The
zone floor tiles added seven close floor shades (grass, ochre, slate, ash, dirt, moss, marble), all
inside the 0.21-0.30 floor band. Today's code-drawn Sanctum floors are mid-grey (OKLab L 0.34-0.40,
lighter than `floor_stone`); the Sanctum tiles bring them down to a mean L of 0.26-0.29 so violet and
crimson units clear them.

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

### Converting small figures (figure redesign, Oct 2026)

A detailed AI figure is about 19 source px per art px at 48 px, and `prepare_sprite.py`'s cell vote
fattens thin shapes and drops one-pixel dark lines: the redesigned Banshee's neckline and the gap
between her bust and her hair vanished into one bone-white torso. Two fixes, used on the Banshee and
the Keening Lady: `python3 tools/pixelate_source.py <source> <art height> <grid copy>` puts the source
on the exact art grid first (premultiplied box downscale, one flat block per art pixel), and
`prepare_sprite.py <grid copy> <key> --ink-l 0.15 --no-cleanup` keeps a dark slate gown as cloth
(the default `INK_L` 0.27 turned it into outline ink) and keeps the single-pixel neckline (the check
then warns about specks; the floors still pass). Keep the levels on for these two: with
`--no-levels` the Keening Lady's dark gown failed every March and Sanctum floor. As with any
pre-processed source, copy the untouched original back to `art_source/<key>.png`.

### Converting skin (figure redesign, Oct 2026)

The `skin` ramp's lightest shade is the ivory `bone`, and on a source with a lot of skin (the
redesigned Seraphine) the default conversion's per-material lightness stretch also sank her gold to
`brown_light`. Seraphine's four sprites are converted with `--no-levels` (her gold stays gold), after
`python3 tools/skin_cap.py <source> <capped copy>`, which sets every skin pixel brighter than the
palette's `skin` (found by a warm-peach hue band between the ivory cloth and the gold trim) to exactly
`skin`, so no highlight turns into ivory. Copy the untouched source back to `art_source/<key>.png`
afterwards (prepare_sprite archives whatever it was given). The violet characters need neither (their
ramps have no `skin`: the necromancers' pale skin is `bone` by design).

## Anchors (the first six, approved in-game before everything else)

**Status:** anchors 1-3 are in the game: the necromancer (owner's ~65 px image, `--inside-outline`, hood
eyes separated by hand), the Skeleton Warrior (~54 px image, `--inside-outline`, eyes restored by hand)
and the Covenant Recruit (~60 px image, `--inside-outline --no-prune --no-levels`, 50 art px so his
body is 40 under the spear, a few shaft pixels repainted by hand). The Graveyard floor tile (anchor 4)
and the two gravestones (anchor 5) are made and drawn in the game by the environment hookup; to
approve in-game.

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
--no-outline --no-rim --no-prune --allow-floor --ramps floor,grey --no-center`. **Hooked up:** the
Graveyard floor is drawn as a grid of this tile (see "Environments" below).

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
`... obstacles/gravestone_l --art-height 44 --ramps grey,moss`. **Hooked up:** the gravestone kind
now has exactly these two sizes (collision radius 11 and 15), and both are drawn from these sprites.

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

## Walk cycles (`tools/walk_cycle.py`)

**Status:** 53 strips: the necromancer and the 11 other characters, their 16 skins; Grand Inquisitor
Seraphine, her Avatar of the Dawn, the Banshee and the Keening Lady (glides: robe hem sway, bob and bust bounce; figure redesign,
Oct 2026); the summons
Warrior, Archer, Mage, Mender, Warder, Rogue, Risen and Bone Hound and the walking evolutions Death
Knight, Gravebow, Shadow Reaper and Hellhound; the Covenant Recruit, Footman, Archer, Chaplain,
Purifier, Shieldbearer, Halberdier, Templar and Banner Bearer. Every other unit (the other bosses, structures,
the floating Frost Wraith, Winter Revenant and Lich, the airborne Gargoyle and
Cathedral Horror, the Bishop, the giant summons, the Corpse Catapult and Ossuary Engine, the Inquisitor
and the Sanctum kinds) keeps its still plus the engine motion. A skin's rig is derived from its character's
(`SKINS` / `skin_rig()`: the same hip height above the feet, the columns moved by the offset between
the two lower bodies; `SKIN_FIX` for per-skin corrections), since a skin keeps its character's body
and pose.

**Method (the pilot, Oct 2026).** Two methods were compared on the necromancer, the Warrior and the
Recruit. (a) AI: the approved still enlarged x16 as the reference, a prompt for 4 poses of "the same
character" (`gen_image.py`, 3 images), converted with `prepare_sprite.py --frames 4`. Every sheet
redrew the character: the Warrior lost its skull face, the Recruit his face and kettle helm, the
necromancer's hood and staff moved between poses, and the images came back on a dark glow; converted,
no pose matched the still, so the strip would flicker against the approved sprite. (b) Procedural: the
frames are cut from the still itself. (b) keeps every approved pixel and palette colour, cannot drift
and is deterministic, so **all strips use (b)**; the AI images were not used.

**How the tool animates a still.** Each unit has a *rig* in `tools/walk_cycle.py` (`RIGS`): a `hip`
row, the column ranges of the `back` and `front` leg (or, on a robe, the two hem lobes with the feet
under them) and `rigid` rectangles below the hip that ride with the body (a spear or staff foot, a
sword tip, a shield rim, a censer). Rows above the hip move only as one block, 1 art px down on the
"down" pose. Each leg is re-laid row by row: whole rows taken out near its middle (the knee bends,
the swinging foot lifts by `lift` px) and sheared sideways from 0 px at the hip to `spread` px at the
foot (the feet come together, then part). Rows move intact, so outlines, rims and colours are the
approved ones; the tool refuses a strip whose frame 0 differs from the still or that holds a colour
the still does not. One cycle is **8 frames** (`WalkData.FRAMES`), two steps of four poses: contact
(the still itself), down, passing (feet together, swinging foot lifted), up; the first step swings the
back leg, the second the front one. Typical rigs: `spread` 2-3 and `lift` 2 for legged soldiers and
skeletons, 1 and 1 for the long robes, `dip` 1 everywhere.

**Bust bounce (figure redesign, Oct 2026; owner request).** A rig may carry `bust = (x0, x1, y0, y1,
px)`: the box holding the bust (y0 the neckline, y1 - 1 the underside) and the bounce in art px. Each
frame warps that box vertically (`_bounce()`): the neckline stays, the underside moves `BUST_BOUNCE`
x `px` at the box's centre column and less toward its sides (a sine bell), fading back to 0 over
`BUST_TAIL_PER_PX` x `px` rows below it, so the belly takes up the motion and nothing tears. The timing
is a damped spring driven by the step (`BUST_BOUNCE` = 0, -0.5, +1, -0.5 per pose: it lags the dip,
overshoots as the body rises, rebounds, settles on the contact, so frame 0 stays the still). Pixels
are only moved within their column (nearest, inverse mapping), never recoloured, so the strip passes
the same checks. Used on the Wither Witch (2 px; her box starts right of her near arm, which shook
when it was inside), the Soulbinder (2 px), their Hyper skins (boxes derived by `skin_rig()`),
Seraphine and her Avatar (3 px), and the floating Banshee and Keening Lady (2 px, glide strips like
Seraphine's). A bounce plays only while the unit moves; standing shows the still.

**Strip layout (the engine contract).** `assets/sprites/<key>_walk.png` = 8 frames side by side, no
gaps, **each exactly the still's width and height** (frame i at x = i x W), feet on the same bottom row
and the body at the same x, so a frame drawn where the still is drawn lines up pixel for pixel.
`SpriteBank.draw()` uses a strip only for grid art whose strip height equals the still's and whose width
is a whole multiple (at least 2) of it; otherwise it draws the still.

**In the game.** The frame follows the engine-motion step phase (`UnitMotion`: the phase advances by
PI per step at the measured speed over the unit's stride), so the legs keep time with the bob and the
speed: frame i is centred on phase i x TAU / 8, contact on the bob's low points, passing on its tops.
A unit counts as walking above `WalkData.START_SPEED` (14 px/s) and stops below `STOP_SPEED` (8 px/s),
showing its still; frozen, stunned, stone and dead bodies hold their frame, airborne ones show the
still. The body layer is redrawn only when the frame changes (a Recruit at 58 px/s about 9 times a
second), and the stretch bob drops to `WalkData.BOB_SCALE` (35%) since the strip carries its own 1 px
dip. Hit flash, tints (skins, characters), elites, facing and the sharp-pixel shader work as for the
still. Visual only: game time and positions, no RNG.

**Adding a unit.** Look at the still on a grid (rows and columns), write its rig, then
`python3 tools/walk_cycle.py build <key>`, `python3 tools/walk_cycle.py preview <key> --out-dir DIR`
(a GIF walking in place at 4x and a frame sheet) and `sheet <keys> --out PNG` (a review sheet), and
`godot --headless --import` for the `.import` file. Tune `hip` (higher = more of the legs move),
`spread` and `lift`; put anything that must not bend below the hip in `rigid`.

## Effects (smooth by design)

Effects are short **smooth** animations processed with `--anim` (strips of square frames in
`assets/sprites/effects/`, timing and fill in `scripts/data/anim_data.gd`). They are drawn in
pixel-art style with palette colours, but the engine scales each one to its gameplay radius with
plain linear filtering (`SpriteBank.draw_anim()`), not through the sharp-pixel shader. That is
deliberate: the same strip plays at many sizes (area passives, Zoom Close), from a 40 px Soul Chains
flash to Seraphine's 1300 px nova, so no fixed 1:1 grid fits. After the effects pass (Oct 2026) 28
strips exist; the `--anim` table below lists them, their hooks and the process notes.

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
| `umbral_warden.png` | **The Umbral Warden** (Shadow Orb Shield): a broad hooded necromancer in layered dark violet robes over cold-grey plate, a tall staff topped by a black sun ringed with a violet corona, three small dark orbs orbiting the staff head; sturdier than the necromancer. Signature: the black-sun staff | 63 (body 48, staff above) | done |
| `voidcaller.png` | **The Voidcaller** (Shadow Blast): a gaunt sorceress in an abyssal violet robe with a star-speckled hem, hood thrown back over a pale bone face, one hand raised with a ring of violet void energy, violet eyes. Signature: the raised void ring | 53 (body 48, void ring above) | done |
| `bone_oracle.png` | **The Bone Oracle** (Bone Spear): a necromancer in a carved bone skull mask and pale bone robes with violet trim, a bone spear held upright, three bone shards floating around him, violet eye glints. Signature: the upright spear and floating shards | 54 (body 48, spear above) | done |
| `fallen_confessor.png` | **The Fallen Confessor** (Soul Siphon): a necromancer in corrupted clerical robes (stained ivory and violet), a torn crimson stole, a broken gold censer on a chain, teal-and-violet soul wisps drawn into his open hand. Signature: the hanging censer | 48 | done |
| `carrion_lord.png` | **The Carrion Lord** (Corpse Explosion): a hulking hooded necromancer in a gore-stained leather mantle with bone plates and a ribcage pauldron over violet robes, a cleaver-headed bone staff. Signature: the broad mantle and cleaver | 52 | done |
| `plague_scholar.png` | **The Plague Scholar** (Plague Cloud): a hunched necromancer in decaying moss-green alchemist robes over violet, a beaked plague mask, vials at the belt, a staff hung with a smoking censer leaking moss-green fumes. Signature: the beak and censer | 48 | done |
| `doomsayer.png` | **The Doomsayer** (Death Mark): a tall gaunt prophet in a near-black violet robe lined with crimson, a branding iron glowing in one hand, a crimson eye sigil on the hood. Signature: the tall thin hooded shape and branding iron | 53 (body 48, branding iron above) | done |
| `barrow_warden.png` | **The Barrow Warden** (Bone Wall): a heavy-set warden in a mossy cold-grey cloak over violet, stacked bone-and-stone armour, a bone-slab tower shield, a shovel-headed staff. Signature: the slab shield | 59 (body 48, shovel staff above) | done |
| `soulbinder.png` | **The Soulbinder** (Soul Chains): an alluring sorceress with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips) in a fitted, low-necked dark violet gown with a high slit, spectral chains around her waist and hips, pale icy lightning crackling along the chains and from her raised hand. Signature: the chains, the raised hand and the figure (figure redesign, Oct 2026) | 61 (body 48, lightning hand above) | done |
| `wither_witch.png` | **The Wither Witch** (Wither): an alluring witch standing tall with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips) in a fitted, low-necked violet corset dress with a high slit under a withered brown shawl, a wide frayed hat, dead leaves falling, a twisted dead-branch staff, a faint moss-green aura at her feet. Signature: the wide hat and the figure (figure redesign, Oct 2026; she was crooked before) | 48 | done |
| `grave_herald.png` | **The Grave Herald** (Raise Dead): a necromancer herald in a dark violet tabard over bone mail, a raised bone horn, a banner pole topped with a skull, teal soul fire at his feet. Signature: the skull banner | 62 (body 48, skull banner above) | done |

### Player skins (`assets/sprites/player/<character>_<skin>.png`, body as the character's)

Cosmetic skins (`scripts/data/skin_data.gd`; purely visual, never a stat). Until a file exists the game
draws the character's own sprite with the skin's palette tint, a small emblem and a faint aura. Use the
prompt template and attach **the character's own approved sprite** so the silhouette, pose and
proportions stay the same; only the costume and colours change. The twelve **Hyper skins** share one
theme: the character's regalia **gilded** (or, for the three shadow characters, **eclipsed** dark with
a gold corona), earned by clearing the Sanctum of Judgment on Hyper. Skins are the one place the player
may wear gold.

**Status:** all sixteen are in. Each was generated (`tools/gen_image.py`) with two attachments: the
character's own sprite, enlarged ×12 with nearest-neighbour, and the anchors sheet. The prompt said "a
costume skin of the character in the first attached image: same pose, silhouette and proportions, body
48 px". Each was converted with `--inside-outline --no-prune --no-levels` at the art height that gives
the skin **the same body height (head to feet) as its character**: Art px = character body × source
height ÷ source body. A crown, halo or corona above the head therefore grows the sprite, not the body.
Hand fixes: the Ivory Seer's icy eyes, and the Heretic Saint's cracked halo repainted crimson (it
converted almost black). At this size the corona's thin rays merge into a gold rim with a few spikes
behind the head; ask for "a 2-pixel-thick ring with chunky rays" if one is redone.

| File | Skin (character) | Subject (for the template) | Art px | Status |
|---|---|---|---|---|
| `gravecaller_dread_sovereign.png` | The Dread Sovereign (Gravecaller) | The necromancer in **black plate armour** with gold trim and a crimson-lined black cloak, a spiked **gold crown** over the hood, skull staff with gold fittings, violet eyes | 56 (body 49, flame staff above) | done |
| `bone_oracle_ivory_seer.png` | The Ivory Seer (Bone Oracle) | The Bone Oracle in a **polished ivory** bone mask and mantle, bleached robes, a thin ivory **halo**, pale icy eyes | 60 (body 48, spear and halo above) | done |
| `plague_scholar_plague_doctor.png` | The Plague Doctor (Plague Scholar) | The Plague Scholar as a **plague doctor**: long **beaked leather mask** with green lenses, wide-brimmed black hat, waxed brown coat, a swinging censer with moss-green smoke | 48 (body 48, no overhang) | done |
| `fallen_confessor_heretic_saint.png` | The Heretic Saint (Fallen Confessor) | The Fallen Confessor in **defiled ivory vestments** stained crimson, a **cracked crimson halo**, torn holy stole | 56 (body 48, cracked halo above) | done |
| `gravecaller_hyper.png` | Eclipsed Gravecaller (Gravecaller) | The necromancer **eclipsed**: robes darkened to near-black violet, a **gold sun corona** behind the hood, gold-rimmed staff orb | 58 (body 49, staff and corona above) | done |
| `umbral_warden_hyper.png` | Sunless Warden (Umbral Warden) | The Umbral Warden eclipsed: armour darkened to black, a **gold corona** behind the helm, gold edges on the shield | 69 (body 49, black-sun staff above) | done |
| `voidcaller_hyper.png` | Starless Voidcaller (Voidcaller) | The Voidcaller eclipsed: a starless black robe, a **gold corona** ring behind the head, a gold-framed void orb | 55 (body 48, void ring and corona above) | done |
| `bone_oracle_hyper.png` | Gilded Oracle (Bone Oracle) | The Bone Oracle **gilded**: gold-leaf skull mask and ornaments, gold trim, a gold sun corona | 59 (body 48, spear and corona above) | done |
| `carrion_lord_hyper.png` | Crowned Carrion Lord (Carrion Lord) | The Carrion Lord **gilded**: tarnished-gold armour, a gold crown, gold sun corona | 60 (body 52, crown and corona above) | done |
| `fallen_confessor_hyper.png` | Fallen Seraph (Fallen Confessor) | The Fallen Confessor as a **fallen seraph**: gilded vestments, broken **gold wings**, a gold sun corona | 54 (body 48, corona above) | done |
| `plague_scholar_hyper.png` | Blighted Scholar (Plague Scholar) | The Plague Scholar **blighted gold**: robes of sickly gold-green, gold vials, a gold sun corona | 53 (body 48, corona above) | done |
| `doomsayer_hyper.png` | Final-Hour Doomsayer (Doomsayer) | The Doomsayer **gilded**: gold hourglass and chains, gold trim, a gold sun corona | 54 (body 45, branding iron and corona above) | done |
| `barrow_warden_hyper.png` | Gilded Barrow King (Barrow Warden) | The Barrow Warden as a **barrow king**: gold grave-goods armour, a gold circlet, a gold sun corona | 63 (body 49, shovel staff and corona above) | done |
| `soulbinder_hyper.png` | Radiant Soulbinder (Soulbinder) | The Soulbinder **gilded** (her redesigned figure): gold soul chains, radiant gold trim, a gold sun corona | 63 (body 49, lightning hand and corona above) | done |
| `wither_witch_hyper.png` | Thorn-Crowned Witch (Wither Witch) | The Wither Witch **gilded** (her redesigned figure): a crown of gold thorns, gold-dusted withered robes, a gold sun corona | 50 (body 48, thorn tips above the hat) | done |
| `grave_herald_hyper.png` | Golden Herald (Grave Herald) | The Grave Herald **gilded**: a gold horn and tabard, gold trim, a gold sun corona | 63 (body 48, skull banner and corona above) | done |

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
| `banshee.png` | Banshee: a floating spectre with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips; figure redesign, Oct 2026), pale bone-white skin, a fitted low-necked slate gown with a high slit that frays into wisps below the hips, long silver-blue hair streaming back (kept off her chest so the bust reads at 48 px), arms out, mouth open mid-wail, teal eyes. Converted through `pixelate_source.py`, then `--ink-l 0.15 --no-cleanup` | 48 | done |
| `keening_lady.png` | Keening Lady (Banshee evolution): a taller, regal banshee with the same redesigned figure, a fitted low-necked dark cold-grey gown with a high slit fraying into wisps, a bone circlet with a teal gem, silver-blue hair, a pale screaming face, teal sound ripples. Converted like the Banshee | 56 | done |
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
| `seraphine.png` | Grand Inquisitor Seraphine, Voice of the Dawn (Stage 3): a statuesque winged Inquisitor with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips; figure redesign, Oct 2026) in a fitted, low-necked white-and-gold bodice gown with a high slit, a crimson stole and a gold sun on the chest, a white veil and gold circlet, a gold **sun halo** with rays, two feathered ivory wings spread up behind her shoulders, a tall gold **relic staff** crowned by a sunburst reliquary | 130 | done |
| `seraphine_avatar.png` | *Optional.* Her **Avatar of the Dawn** form (phases 2-3): the same figure larger and brighter, wings spread wide with gold-edged feathers, a long-rayed halo, the relic blazing holy white | 156 | done |
| `alaric_windup.png` | **Attack pose** (`BossPoseData` pose 1): both hands raise the warhammer high overhead, leaning back | 177 | done |
| `alaric_charge.png` | Attack pose 2: a shoulder-first charge, hammer trailing low, cape streaming | 117 | done |
| `alaric_strike.png` | Attack pose 3: crouched, the hammer slammed into the ground in front | 108 | done |
| `vael_windup.png` | Attack pose 1: the flaming sword raised high behind her head, shield forward | 133 | done |
| `vael_guard.png` | Attack pose 2 (Shieldwall): crouched behind the planted kite shield | 104 | done |
| `vael_strike.png` | Attack pose 3: the cleave's follow-through, the flaming sword swept low to the right | 118 | done |
| `seraphine_cast.png` | Attack pose 1 (every cast): the relic staff raised high, wings wider | 156 | done |
| `seraphine_avatar_cast.png` | The Avatar's cast: the blazing staff thrust overhead, wings fully spread | 176 | done |

**Attack poses** (`scripts/data/boss_pose_data.gd`, drawn by `SpriteBank.draw_pose()`): the boss scripts already report a pose from their attack phase (0 walk, 1 windup / cast, 2 special stance, 3 strike); a listed pose with a PNG replaces the still, its bottom edge on the still's bottom edge so the feet never jump, under the still's shadow; a missing pose shows the still. Generated with the boss's own still attached (enlarged) and converted at the still's scale (the body the same height; a raised weapon makes the sprite taller, a crouch shorter).

### Structures (`assets/sprites/structures/`)
| File | Subject | Art px | Status |
|---|---|---|---|
| `outpost.png` | Siege outpost: a crimson-banner palisade tent | 96 | done |
| `ward_generator.png` | Holy Ward Generator: a gold-ringed obelisk with a radiant core | 80 | done |
| `supply_cart.png` | Covenant supply cart (seen from above) | 60 | done |
| `holy_standard.png` | Vael's Holy Standard: an ornate gold banner pole | 72 | done |
| `watchtower.png` | Checkpoint watchtower: a wooden tower with a crimson pennant | 96 | done |
| `ward_crystal.png` | Sanctum ward crystal: a tall faceted ivory-and-gold crystal on a round pale-stone plinth, gold glow | 64 | done |
| `sacred_altar.png` | Sanctum sacred altar: a wide pale-stone altar block draped in gold cloth with a crimson stripe, two lit candles, a gold sun disc standing behind it | 72 | done |

(`ward_crystal` and `sacred_altar` have their `SpriteData.HEIGHTS` entries now; the supply cart is 60 tall so the wide side-on cart keeps its old ~84 px width.)
on screen.)

### Pickups (`assets/sprites/pickups/`)

Drawn centred and unrotated through `SpriteBank.draw_flat()` (art px = the longest side, `SpriteData.FLAT_SIZES`). The XP crystal keeps the code colour language by value (teal, blue, violet) over its faint glow; the power-ups are **round medallions** (a dark disc in an accent rim) over the code's pulsing ring, so a drop never reads as a crystal or an enemy; the world chest keeps the code's gold pulse (the ChestPanel reveal stays code-drawn).
| File | Subject | Art px | Status |
|---|---|---|---|
| `xp_crystal_s.png` | XP crystal worth 1-2: a small soul crystal (soul teal, a glint) | 12 | done |
| `xp_crystal_m.png` | XP crystal worth 3-7: arcane blue, three facets | 16 | done |
| `xp_crystal_l.png` | XP crystal worth 8+: player violet, a white-violet core, two chips at its base | 20 | done |
| `chest.png` | Bone-and-iron treasure chest with a violet lock glint (the player's reward) | 32 | done |
| `pu_magnet.png` | Soul Magnet: a teal soul vortex charm | 24 | done |
| `pu_feast.png` | Grave Feast: dark roasted meat on a bone | 24 | done |
| `pu_hyper.png` | Hyper: a violet lightning rune | 26 | done |
| `pu_stasis.png` | Stasis: a frozen hourglass (ice) | 24 | done |
| `pu_frenzy.png` | Dark Frenzy: a flaming skull (flame) | 24 | done |
| `pu_nova.png` | Soul Nova: a violet starburst | 24 | done |

### Projectiles (`assets/sprites/projectiles/`)

Flat sprites the game **rotates along their flight path**: draw each **pointing right** (head at the
right, trail to the left), transparent background. Art px = the longest side (`SpriteData.FLAT_SIZES`). Player spells are violet; summon shots use their class colours.

| File | Subject | Art px | Status |
|---|---|---|---|
| `shadow_bolt.png` | Shadow Bolt: a violet bolt with a pale core and a short trail | 22 | done |
| `void_bolt.png` | Void Barrage bolt: a black-violet core with a violet trail | 32 | done |
| `void_shard.png` | Void shard: a tiny violet crystal splinter | 16 | done |
| `bone_spear.png` | Bone Spear: a sharpened bone javelin | 26 | done |
| `ossuary_lance.png` | Ossuary Lance: a huge bone lance wrapped in violet energy | 46 | done |
| `arrow.png` | Skeleton Archer arrow: a bone shaft with a teal soul-fire head | 22 | done |
| `mage_orb.png` | Undead Mage orb: an arcane-blue orb with a pale core (the Mage's colour since the art pass) | 22 | done |
| `priest_bolt.png` | Mender / Warder bolt: a small teal mote | 14 | done |
| `frost_bolt.png` | Frost Wraith bolt: a pale icy shard | 22 | done |
| `orb.png` | Shadow Orb Shield orb: a round violet orb (not pointed; it doesn't rotate) | 18 | done |
| `enemy_arrow.png` | Covenant arrow: an ivory shaft with a gold head | 20 | done |
| `radiant_bolt.png` | Covenant holy bolt: a gold and holy-white spark | 20 | done |

### Icons (`assets/sprites/icons/`, 32×32 art px)

Square **badge icons** for level-up cards, the HUD ability bar and buff timers: a **dark cut-corner square
badge** with a 1 px border and **one bold symbol**, 32×32 art px (shown about 1× to 2× in the 32, 48
and 64 px boxes). Player
spells and passives use violet with bone; summon icons use their class colours; never Covenant gold or
crimson on the player's icons (the Hyper badge and the Profane Pact excepted). Evolutions add a
gold-trimmed frame. The Shadow Bolt icon is Anchor 6. **Status: all done** (Oct 2026): the API generated each **symbol alone** on a transparent background, converted to fit 26×26 art px, and composited onto one badge template: a 32×32 frame with Anchor 6's **cut corners** (owner decision: cut corners on every UI element; a brief square version was reverted), a 1 px border, an ink-violet face: a **violet** border for ordinary icons, a **gold** border for the evolutions (spell and summon). Small skull faces keep their eye sockets with `prepare_sprite.py --no-cleanup` or `--method mode`, picked per icon. The **Hyper badge** is the exception: a bare 16×16 gold sun (no badge frame), drawn 1:1 by `HyperBadge` at its 16-18 px sizes.

**Ossuary and Soul Ash icons** (menu modernization wave 2, Oct 2026): the Soul Ash currency, the four
tree emblems and every Ossuary upgrade that was still code-drawn (`MetaGlyphs`, now only the fallback) got
badges the same way: one symbol per prompt (26 art px, `--ref icons/shadow_bolt.png`), converted with
`prepare_sprite.py --no-center --no-prune --no-levels` (`--no-cleanup` where embers or eyes need their
single pixels: Soul Ash, Undying Will, Ash Harvest, Profane Oath) and composited on the badge template cut
from an approved badge (its cut-corner alpha and violet ring). Upgrade symbols use their tree's colour
(Necromancy soul teal + bone, Shadowcraft violet + bone, Survival cold blue, Fortune gold + teal crystals);
the Fortune gold is the meta tree's colour, not Covenant gold. **Soul Ash** also has a bare 16×16
`soul_ash_small` for inline costs. API for every screen: `IconGlyph.new("soul_ash", Vector2(32, 32))` (the
badge, 1:1; 64 for x2) and `IconGlyph.new("soul_ash_small", Vector2(16, 16))`. 31 images (24 symbols, 5
retries, 2 Soul Ash variants), about $0.47.

**Achievement badges** (menu modernization wave 2, the Codex's Achievements tab, `CodexData`): four badges
`ach_<achievement>` made the same way but on a **gold** border (an achievement is a reward, like an evolution),
shown at x2 (64 px). 4 images, about $0.06.

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
| `soul_ash.png` | **Soul Ash** (the currency: main menu, Ossuary, end screen): a heap of grey soul ash with orange embers glowing through it and a teal soul flame rising from its peak |
| `soul_ash_small.png` | The same Soul Ash symbol **bare, 16×16** (no badge, like the Hyper badge), for inline costs next to a number |
| `tree_necromancy.png` | Ossuary tree emblem: a bone skull with teal eyes over crossed bones |
| `tree_shadowcraft.png` | Ossuary tree emblem: a violet crescent moon cradling a white-hot star |
| `tree_survival.png` | Ossuary tree emblem: a cold-blue kite shield with a bone heart |
| `tree_fortune.png` | Ossuary tree emblem: a gold skull coin with a white sparkle |
| `necrotic_marrow.png` | Ossuary: a thick bone with a glowing teal marrow crack |
| `sharpened_bones.png` | Ossuary: two crossed bone blades with a teal glint |
| `grave_call.png` | Ossuary: a bone war horn pouring teal soul mist |
| `risen_vanguard.png` | Ossuary: a helmed skeleton head with teal eyes and a teal plus |
| `legion_of_bone.png` | Ossuary: a skull-topped bone standard with a tattered teal pennant |
| `umbral_potency.png` | Ossuary: a tall violet flame rising from a bone rune circle |
| `quickened_rites.png` | Ossuary: an open book under a violet circular refresh arrow |
| `widening_dark.png` | Ossuary: a violet orb with four bone arrows pointing outward |
| `shadow_mastery.png` | Ossuary: a violet eight-pointed star sigil inside a bone ring |
| `grave_flesh.png` | Ossuary: a stone-grey heart with an ice-blue plus |
| `bone_mail.png` | Ossuary: a bone ribcage breastplate with a cold-blue gem |
| `fleet_shade.png` | Ossuary: a cold-blue hooded shade dashing right with ice speed streaks |
| `undying_will.png` | Ossuary: a bone skull rising out of cold-blue soul flames |
| `soul_magnet.png` | Ossuary: a grey horseshoe magnet with gold tips pulling teal crystals |
| `grave_tithe.png` | Ossuary: a gold offering bowl heaped with teal soul crystals |
| `ash_harvest.png` | Ossuary: a bone scythe over a heap of ash with embers |
| `fates_thread.png` | Ossuary: a wooden spool of glowing gold thread, its loose end looping |
| `banishing_rite.png` | Ossuary: a bone card with a violet sigil cut by a violet slash |
| `ach_bone_legion.png` | Achievement *Bone Legion* (gold border): a helmed skull with teal eyes over crossed bones |
| `ach_heretics_bane.png` | Achievement *Heretic's Bane* (gold border): a gold holy sunburst cracked through by a violet rift |
| `ach_dread_sovereign.png` | Achievement *Dread Sovereign* (gold border): a bone skull with teal eyes under a gold crown |
| `ach_dawn_extinguished.png` | Achievement *Dawn Extinguished* (gold border): a gold sun eclipsed by a violet disc |
| `profane_oath.png` | Ossuary Profane Oath: a skeletal hand raised in an oath under a crimson flame (the Oath is the one crimson Ossuary icon, like the Pact) |
| `warrior.png` | Summon class badge (hotbar and army list): a skeleton warrior's helmed skull behind a round shield |
| `archer.png` | Summon class badge: a moss-hooded skeleton drawing a bone bow with a teal arrow |
| `mage.png` | Summon class badge: a skull in an arcane-blue hood beside an orb staff |
| `mender.png` | Summon class badge: a teal-hooded skeletal priest under a teal halo, a bone censer |
| `warder.png` | Summon class badge: a bony hand raising a teal ward sigil |
| `rogue.png` | Summon class badge: a hooded skeleton with crossed bone daggers |
| `gargoyle.png` | Summon class badge: a stone gargoyle head with half-spread wings |
| `frost_wraith.png` | Summon class badge: a pale icy hooded wraith trailing frost |
| `abomination.png` | Summon class badge: a stitched corpse-flesh brute with bone spikes |

### Environments (later pass, no prompts yet)

Floors, decals and obstacles come after the units. Floors are **dark, low-saturation and
narrow-value**; nothing on the floor may look solid unless it collides.

**Hookup (done; `scripts/core/environment_art.gd`, numbers and the key scheme in
`scripts/data/environment_art_data.gd`).** Every file below is optional and lands on its own: without
it the game draws today's code floor or obstacle glyph. Environment art is always grid art, drawn at
its own texel size (1 art px = 1 layout px) through the sharp-pixel shader, so make each PNG exactly
the size in its row.
- **Floors:** when a zone's base tile exists, the floor is one repeating rect of it on the world tile
  grid (seamless across tile edges), plus the variants `tiles/<zone>_2.png` and `tiles/<zone>_3.png`
  (optional, same size, each on 20% of the 128 px cells, picked from the floor's stable cell hash, so
  the same cell always shows the same tile). On it the code decorations become floor decals, are
  dropped or stay code-drawn ("Decals" below); the Graveyard's solid-looking ones (tombstone, stone
  cross, dead tree) are skipped on the tile floor because they looked like the gravestone obstacles but never collide. The March road strip is drawn over the zone tile along y = 0 (`march_road_<style>.png`
  overrides it in one zone, e.g. `march_road_fortress.png`). The Sanctum corruption lerps the tiles
  toward the same purple as the code floor (one translucent overlay of the corruption colour at the
  code floor's blend strength), so no purple goes into the tiles.
- **Obstacles:** `obstacles/<kind>_<size>.png`, where `<size>` is `s` / `l` for a kind with two sizes
  and `s` / `m` / `l` for three (smallest first, the rows below). The sprite is centred on the
  collision shape horizontally and its **bottom edge sits on the bottom of the collision shape**
  (circle: centre + r; rect: centre + half the short side), so the footprint rows at the base of the
  sprite cover the shape and the rest stands above it; the game adds a flat drop shadow, so draw none.
  Make the sprite as wide as the footprint plus the 1 px outline each side (gravestone_s: 22 → 24).
  **Long walls** (crypt wall, barricade, fort wall, cloister arch) and every other rect are **whole
  fixed-length sprites**, one PNG per length (no cap-and-middle assembly: three lengths are three
  drawings, and nothing can seam). A rect is laid out horizontally or vertically per cell; the
  sprite above is the horizontal one, and `obstacles/<kind>_<size>_v.png` is the vertical one
  (footprint S × L): without it a vertical rect keeps its code glyph.

**Zone floors** (`assets/sprites/tiles/`, 128×128 art px seamless, up to 2 variants each
`<file>_2.png`, `<file>_3.png` whose edges are identical to the base tile's). **Done (Oct 2026)**
for every zone and both roads, built by `tools/make_tile.py` (process below):

| File | Zone | Look (today's code floor) | Status |
|---|---|---|---|
| `graveyard.png` | The Desecrated Graveyard | dark soil, faint cracks, pebbles, dead grass (Anchor 4) | anchor |
| `march_burned.png` | March I, the Burned Road | ash-grey scorched earth, soot, embers | **done**, `_2` `_3` (soot scorch marks); mean L 0.24 |
| `march_checkpoint.png` | March II, the Fortified Checkpoint | dark forest grass and mud | **done**, `_2` `_3` (mud with boot prints); mean L 0.24 |
| `march_camp.png` | March III, the Siege Camp | trampled brown dirt | **done**, `_2` `_3` (darker trampled patches; a first source with wheel tracks read as a pattern and was replaced); mean L 0.25 |
| `march_fortress.png` | March IV, the Fortress Approach | dark cobbles and grit | **done**, no variant (the variant source's cobbles came out inverted); mean L 0.25 |
| `sanctum_courtyard.png` | Sanctum I, the Outer Courtyards | pale-stone flagstones in staggered courses, moss in the joints (kept dark) | **done**, layout: 4 courses of 32 px, slabs 36-56 px, `_2` `_3`; mean L 0.29 |
| `sanctum_halls.png` | Sanctum II, the Sanctified Halls | a dark-gold mosaic of small tesserae | **done**, layout: 8 px tesserae, a 64 px diamond lattice with gold nodes, `_2` `_3`; mean L 0.26 |
| `sanctum_cloisters.png` | Sanctum III, the Cloisters | stone walks around trimmed turf | **done**, layout: a 16 px walk on the tile edges (a walk grid every 128 px, like the code's), `_2` `_3`; mean L 0.25 |
| `sanctum_sanctuary.png` | Sanctum IV, the Final Sanctuary | grey marble slabs with veins | **done**, layout: 64 px slabs in staggered rows, no variant (every slab reaches a tile edge, so a variant would equal the base); mean L 0.29 |
| `march_road.png` | The March road along y = 0 | a horizontal strip **140 art px tall** (road width 140 world px) tiling left-right: packed earth with darker verges and wheel ruts | **done**, 192×140, top / bottom 4 px frayed into transparency so it sits on every zone floor |
| `march_road_fortress.png` | The road in the Fortress Approach | the paved variant | **done**, 192×140, layout: 4 courses of paving between two kerbs (stone texture from the courtyard source) |

**Process (`tools/make_tile.py`, the floor counterpart of `prepare_sprite.py`).** Each output has a
recipe in the tool (source, colours, layout, shares), so `python3 tools/make_tile.py build --all`
rebuilds every tile exactly (deterministic) and `python3 tools/make_tile.py sheet <name>` writes a check
sheet (3×3 repeat ×2, a base / variant mix at ×1 and ×2 with the anchors on it, the half-offset tile and
the colour shares). Sources in `art_source/tiles/` (`<zone>.png` 1024×1024, `<zone>_v.png` 1536×1024
for the variants, `march_road.png` 1536×1024), generated through `tools/gen_image.py` with the graveyard
tile ×8 attached. Prompt pattern (fill in the subject and the colour list from the recipe):
```
A SEAMLESS, tileable ground texture for a top-down 2D pixel-art game, seen straight from above
(orthographic, no perspective, no horizon). LOW-RESOLUTION pixel art: about 160 x 160 pixels in all,
shown enlarged so every pixel is a big crisp square block (nearest-neighbour). The texture fills the
WHOLE image edge to edge, fully opaque, evenly lit everywhere (no vignette, no light falloff, no frame,
no border). The left edge must continue the right edge and the top edge the bottom edge.

Subject: <the zone's look; for a layout zone only the MATERIAL: "one big area of the same stone,
NOT slabs: no joints, no tiles, no grid lines">.

Very DARK, LOW CONTRAST and QUIET: it is a background that every character must stand out from, so
keep every colour close to the others and the details small and sparse. Nothing may look solid or
raised: no rocks, no walls, no objects, no characters, no text. No gradients, no dithering, no soft
blur, no texture noise: flat colour areas with a few chunky details of 2-4 pixels.

Output: the texture filling the whole image edge to edge. No border, no text, no watermark.
Attached: an approved floor tile of this game (a different place: do not copy its content), for the
pixel size and the darkness (match its darkness).

Colours: ONLY flat fills from this list: <names and hex, the main one marked "most of the image">.
```
(The variant source: "about 240 x 160 pixels", "a second, different patch of the same ground", plus
one distinctive line: a scorch mark, a mud patch, a trampled patch; avoid long straight features such as wheel tracks, which repeat as a pattern.) The AI images are never seamless, so
the tool makes them tile: it reduces the source to the grid (~6.5 source px per art px), removes light
falloff (lightness minus a wide blur), stretches the lightness and hue onto the recipe's floor colours,
then either **quilts** it (organic floors: minimum-error cut paths through a 24 px overlap, so the
wrap column continues the opposite edge exactly and the switch hides where the two candidates agree)
or fills a **layout** that is periodic by construction (courses, a grid, walks, mosaic tesserae: regular
joints must line up, which no cut can promise), each stone reading the texture at its own offset with a
small lightness offset and a bevel. Then it snaps to the palette (nearest colour, or exact shares by
lightness rank with hue-chosen patches) and merges single pixels. A variant goes through the same steps
with its histogram matched to the base source, then is cut into the base tile along minimum-error paths
in a 28 px band on each edge (the outer 2 px always the base's; a layout swaps whole stones that stay clear of the edges), so its edges equal the base tile's and
any cell mixes with any other. All floors stay inside the floor band (mean OKLab L 0.24-0.29, mostly the
new floor shades), so every unit's main shape keeps its +0.15 contrast. On the tile floors the code
decorations became decals (see "Decals" below).

The Sanctum floors are blended toward purple as the Sanctum is corrupted, so do not bake purple in.

**Decals** (`assets/sprites/decals/`, **done Oct 2026**): small flat floor details lying on the tile
floors, seen from straight above, transparent background, **no outline, no rim light, no cast shadow**
and nothing that looks solid (a standing stake, crate or banner post would read as an obstacle, so
those are drawn fallen or smashed flat). They stay dark and quiet like the floors (mean OKLab L
0.19-0.35 except the tiny petals and flowers; only small accents are bright: embers, gold glints,
the arrow's fletching), in palette colours with the floor shades allowed.

*Hookup* (`scripts/data/decal_data.gd`, `EnvironmentArt.draw_decal()` / `draw_strip()`): the code
floors place one decoration per 128 px cell at a hashed point and roll. On a zone's tile floor each
decoration is either (a) its decal `decals/<zone>_<name>.png`, drawn at its own texel size through the
sharp-pixel shader and centred on the code decoration's own hashed point (plus `DecalData.OFFSETS`,
the centre of what the code drew), with optional variants `<key>_2`, `<key>_3` picked from the same
cell hash, so layout and determinism are unchanged; (b) dropped when the tile already shows it
(`DecalData.DROPPED`); or (c) still code-drawn: soft translucent effects pixel art cannot do better.
A missing decal PNG falls back to the code decoration; a zone without its tile PNG keeps every code
decoration exactly as before. The Sanctum corruption overlay is drawn last on the tile floor, so it
covers the decals exactly like the tiles.

| Zone | Decoration → decision (decal key, size in art px) |
|---|---|
| Graveyard | fog patch → code; grass tufts → `graveyard_grass` (15x10, 9x8, 17x7); open grave → `graveyard_grave` (20x14, 15x13); tombstone, stone cross, dead tree → skipped (solid-looking, unchanged rule) |
| March I | ash drift → `march_burned_ash` (38x28, 27x20); charred stump → `march_burned_stump` (cut flush, 11x13, 10x11); embers → `march_burned_embers` (15x8 x2); spent arrow → `march_arrow` (11x11, 12x10; also the odd arrow on the road in every March zone); broken plank → `march_burned_plank` (13x7, 10x7) |
| March II | grass tufts, mud → dropped (the tile is grass with mud patches); stakes → `march_checkpoint_stakes` (fallen flat, 15x12, 12x12); pennant → `march_checkpoint_pennant` (trampled, 18x9, 13x9) |
| March III | trampled dirt → dropped (tile variants); campfire → `march_camp_campfire` (burnt-out ring with embers, glow included, 18x16, 16x14); rope and peg → `march_camp_rope` (20x8, and mirrored); small crate → `march_camp_crate` (smashed flat, 18x14, 14x11) |
| March IV | cobbles, rubble → dropped (cobbled tile; rubble is an obstacle kind); banner post → `march_fortress_banner` (a trampled banner cloth, 19x15, 17x13); tower shadow → code |
| Sanctum I | cracked slab, paler slab → dropped (the slabs have their own cracks and shades); moss → `sanctum_courtyard_moss` (24x14, 16x10); gold inlay star → `sanctum_courtyard_star` (19x19, 14x15); petals → `sanctum_courtyard_petals` (12x9, 7x7) |
| Sanctum II | gold tesserae, diamond inlay → dropped (mosaic tile with a diamond lattice); rosette → `sanctum_halls_rosette` (32x32, 24x24, snapped to the tile's 8 px tesserae, `DecalData.SNAP`); carpet runner → `sanctum_halls_carpet` (a 128x36 strip, one piece per cell along every fourth cell row) |
| Sanctum III | turf → dropped (turf tile inside stone walks); flowers → `sanctum_cloisters_flowers` (26x12, 21x10); sundial ring → `sanctum_cloisters_sundial` (28x28, 24x24); leaves → `sanctum_cloisters_leaves` (16x8, 15x7) |
| Sanctum IV | stained-glass light pool → code; marble vein → dropped (veined marble tile); inlaid square → `sanctum_sanctuary_inlay` (18x18) |

*Process* (`art_source/decals/make_decals.py`, deterministic: `python3 art_source/decals/make_decals.py`
rebuilds every decal). Eight AI sheets (`art_source/decals/sheets/<sheet>.png`, 1536x1024, prompt in
`<sheet>.txt`, generated through `tools/gen_image.py` with the zone tile x8 attached): each holds 2-6
decals in a grid of equal cells, every decal "a flat detail LYING ON THE GROUND, seen STRAIGHT FROM
ABOVE ... NO cast shadow ... nothing may look like a standing object", low-resolution pixel art in a
short colour list. The script cuts each cell, crops it, downscales it to the recipe's height (block
mean, an opaque threshold per recipe so thin arrows and ropes survive), colours it from the recipe's
own few palette names (accents such as embers or gold only where the source really is that colour,
the rest snapped, optionally after a lightness stretch or a darkening shift), cleans single pixels,
and can mirror or turn it for a variant. prepare_sprite.py was tried first: its unit-oriented ramps
and level stretch turned ash into ink and lost thin features, hence the decal recipes. The carpet
runner is built (periodic by construction, like the tile layouts): a dark-red field between dull-gold
borders, a crimson diamond every 32 px.

**Obstacles** (`assets/sprites/obstacles/<kind>_<size>.png`, later pass): each kind comes in **2-3
fixed size variants** (`sizes` in `scripts/data/stages/*.gd` "kinds", inside the old random ranges),
each with a collision shape that matches it exactly; each obstacle picks one per cell, deterministic
per seed. Footprint in art px (1 art px = 1 world px): a circle of collision radius *r* world px is *2r*
art px across; a rect of *L* × *S* world px is *L* × *S* art px. Sprites stand taller than their
footprint (a tree's canopy, a wall's face). **Long kinds (done):** one drawing per length for the horizontal sprite (as wide as the length + 2); the vertical `_v` sprites are the same objects turned to run away from the camera (generated portrait), as tall as the length plus the face height of their horizontal twin and as wide as the depth + 2: the AI draws them too thin, so each source is stretched horizontally before conversion until the width fits. **Round kinds (done, Oct 2026):** one design per kind, converted to every size; compact kinds (stakes, tent, tower base, rubble, fountain) are as wide as the footprint + 2, the trees take set heights (their trunks are narrower than the footprint, their canopies wider), and the slim statues and columns are capped (saint statue 64-80, pillar 80-90, marble column 72-88, giant statue 100-124 art px tall), so their plinths are ~10-15% narrower than the collision circle (the code drop shadow still marks the footprint). Keys: `<kind>_s` / `_l` for two sizes, `<kind>_s` / `_m`
/ `_l` for three, plus `_v` for a vertical rect (see "Hookup" above). Long walls are whole sprites,
one per length.

| Stage / zone | Kind | Shape | Variants (world px) → footprint (art px) |
|---|---|---|---|
| Graveyard | `gravestone` | circle | r 11 / 15 → 22 / 30 wide (`_s` / `_l`, Anchor 5: **done**, 24×32 and 32×44) |
| Graveyard | `dead_tree` | circle (trunk) | r 13 / 15 / 18 → trunk 26 / 30 / 36 wide, tree ~80-100 tall (**done**, 60x80 / 68x90 / 76x104) |
| Graveyard | `crypt_wall` | rect | 64 / 80 / 96 × 20 → 64 / 80 / 96 × 20 (horizontal **done**, 64x30 / 82x23 / 96x33; vertical `_v` **done**, depth + 2 wide) |
| March I | `burned_house` | rect | 64 / 78 / 92 × 44 → 64 / 78 / 92 × 44 (horizontal **done**, 64x52 / 80x50 / 92x62; vertical `_v` **done**, depth + 2 wide) |
| March I | `charred_tree` | circle | r 12 / 14 / 17 → 24 / 28 / 34 (**done**, 36x60 / 44x68 / 50x80) |
| March I | `cart_wreck` | rect | 40 / 48 / 56 × 22 → 40 / 48 / 56 × 22 (horizontal **done**, 42x29 / 48x35 / 58x38; vertical `_v` **done**, depth + 2 wide) |
| March II | `barricade` | rect | 64 / 80 / 96 × 16 → 64 / 80 / 96 × 16 (horizontal **done**, 66x29 / 82x39 / 100x43; vertical `_v` **done**, depth + 2 wide) |
| March II | `pine` | circle | r 14 / 16 / 19 → 28 / 32 / 38 (**done**, 40x72 / 44x80 / 48x92) |
| March II | `stakes` | circle | r 12 / 15 → 24 / 30 (**done**, 28x33 / 34x40) |
| March III | `tent` | circle | r 22 / 26 / 30 → 44 / 52 / 60 (**done**, 48x48 / 56x56 / 64x64) |
| March III | `crates` | rect | 36 / 44 / 52 × 26 → 36 / 44 / 52 × 26 (horizontal **done**, 36x34 / 44x37 / 52x40; vertical `_v` **done**, depth + 2 wide) |
| March III | `siege_engine` | rect | 70 / 80 / 90 × 34 → 70 / 80 / 90 × 34 (horizontal **done**, 72x53 / 84x53 / 92x77; vertical `_v` **done**, depth + 2 wide) |
| March IV | `fort_wall` | rect | 80 / 96 × 24 → 80 / 96 × 24 (horizontal **done**, 84x40 / 98x44; vertical `_v` **done**, depth + 2 wide) |
| March IV | `tower_base` | circle | r 26 / 30 / 34 → 52 / 60 / 68 (**done**, 56x60 / 64x69 / 72x78) |
| March IV | `rubble` | circle | r 12 / 15 / 18 → 24 / 30 / 36 (**done**, 28x22 / 32x27 / 40x32) |
| Sanctum I | `saint_statue` | circle | r 13 / 15 / 17 → 26 / 30 / 34 (**done**, 26x64 / 28x72 / 32x80) |
| Sanctum I | `fountain` | circle | r 28 / 32 / 36 → 56 / 64 / 72 (**done**, 58x62 / 68x71 / 76x79) |
| Sanctum I | `stone_bench` | rect | 44 / 52 / 60 × 16 → 44 / 52 / 60 × 16 (horizontal **done**, 46x20 / 56x20 / 62x23; vertical `_v` **done**, depth + 2 wide) |
| Sanctum II | `pillar` | circle | r 13 / 15 → 26 / 30 (**done**, 26x80 / 30x90) |
| Sanctum II | `pew` | rect | 60 / 68 / 76 × 14 → 60 / 68 / 76 × 14 (horizontal **done**, 64x26 / 70x39 / 78x45; vertical `_v` **done**, depth + 2 wide) |
| Sanctum III | `cloister_arch` | rect | 72 / 82 / 92 × 18 → 72 / 82 / 92 × 18 (horizontal **done**, 76x38 / 84x32 / 96x39; vertical `_v` **done**, depth + 2 wide) |
| Sanctum III | `garden_bed` | rect | 44 / 52 / 60 × 30 → 44 / 52 / 60 × 30 (horizontal **done**, 44x16 / 56x19 / 60x21; vertical `_v` **done**, depth + 2 wide) |
| Sanctum III | `cypress` | circle | r 11 / 14 → 22 / 28 (**done**, 20x60 / 24x72) |
| Sanctum IV | `giant_statue` | circle | r 28 / 32 / 36 → 56 / 64 / 72 (**done**, 52x100 / 56x112 / 64x124) |
| Sanctum IV | `marble_column` | circle | r 15 / 17 / 19 → 30 / 34 / 38 (**done**, 28x72 / 32x80 / 36x88) |
| Sanctum IV | `reliquary` | rect | 40 / 46 / 52 × 26 → 40 / 46 / 52 × 26 (horizontal **done**, 42x47 / 48x43 / 52x47; vertical `_v` **done**, depth + 2 wide) |

### Effects (`assets/sprites/effects/`, `--anim`)

Short **one-shot animations** (explosions, bursts, flashes) that play once, centred on the effect and
scaled to its gameplay radius. Each is a **sprite sheet of 6-10 frames** (or a short GIF), seen
**straight from above**, on a transparent background. Process it with
`python3 tools/prepare_sprite.py --anim <sheet or GIF> <id>`; the tool finds the frames (by the
transparent gaps between them, or `--frames N` for N equal frames in a row, or `--grid CxR`), crops
them to one square around the effect and writes a strip of 128 px frames (`--frame-px P` stores
larger frames for effects drawn far above 128 px). Timing and on-screen fill are set per effect in
`scripts/data/anim_data.gd`: each duration equals the code duration of the call that plays it, so
an effect lives as long with or without its art. Without the file, the game keeps today's drawn
shape. Use palette colours; player effects are violet, undead teal, Covenant gold.

**Status:** *done* = strip in the game and hooked. **Px** = stored frame size. **Hook** = where it
plays (all through `EffectManager`: `ring()`, `pop()`, `spawn_ring()`, `abyss()`, `impact()` with an
anim id, or `burst()` for the art-only effects that never had a drawn shape: `bolt_impact`,
`level_up`, `evolution`, drawn by `AnimBursts` outside the Effect pool, nothing without the art).
`ring_under()` is a drawn ring that hides while a strip covers it (the inner rings under
`abyssal_burst` and `soul_nova`).

| Id | Effect | Frames | Px | Hook | Status |
|---|---|---|---|---|---|
| `shadow_blast` | Shadow Blast: a violet shockwave ring bursting outward from a dark centre, then fading to wisps | 8 | 128 | Shadow Blast cast | done |
| `abyssal_detonation` | Abyssal Detonation first hit: the black-violet vortex spinning inward and collapsing (the sheet's largest vortex turned 150° and shrunk over 8 frames) | 8 | 256 | `abyss()` at the first hit | done |
| `abyssal_burst` | Abyssal Detonation second hit: the vortex exploding into pale violet sparks and a thin ring, fading to wisps (frames 4-10 of the same sheet) | 7 | 256 | second-hit ring | done |
| `corpse_explosion` | Corpse Explosion: a burst of bone shrapnel and dark gore mist | 8 | 192 | burst ring | done |
| `grave_eruption` | Grave Eruption: bone spikes stabbing up from the ground in a ring around an empty centre, then crumbling | 8 | 192 | burst ring (evolved) | done |
| `bolt_impact` | Shadow Bolt hit: a small violet splash with sparks (subtle, about 20 px) | 6 | 128 | `burst()` on each Shadow Bolt / Void Bolt / Void Shard hit (`ProjectileManager._friendly_hits()`) | done |
| `summon_rise` | Summon rising: teal soul-fire swirling up from a grave-dirt circle (circle at the feet) | 8 | 128 | `spawn_ring()` of a summon / temporary summon | done |
| `undead_death` | Undead destroyed: bones scattering and a teal soul wisp rising | 6 | 128 | `pop()` when a summon falls | done |
| `enemy_death` | Covenant soldier dies: a crimson-and-ivory burst fading into gold motes | 6 | 128 | `pop()` in `CombatResolver._kill_enemy()` | done |
| `holy_impact` | Covenant hammer / boss slam: a gold radiant shockwave with ivory dust | 8 | 192 | `impact()`: Alaric's Hammerfall and Judgment, the Cathedral Guardian's slam, Seraphine's holy circles and nova centre | done |
| `soul_nova` | Soul Nova: a huge thin violet ring with teal and violet soul wisps riding it, expanding across the screen, then dissolving (built from one 1024 px ring image, `art_source/effects/soul_nova_ring.png`) | 10 | 512 | Soul Nova power-up ring | done |
| `level_up` | Level-up: a tall column of violet light with rising runes, its base on the frame's bottom row (at the necromancer's feet) | 8 | 192 | `burst()` following the necromancer when `Game.add_xp()` gains a level (plays on once the card is picked) | done |
| `frost_shatter` | Winter Revenant shatter: a frozen body bursting into pale icy shards, then glittering frost | 6 | 128 | Revenant shatter | done |
| `frost_nova` | Winter Revenant death nova: a ring of freezing frost racing outward from a cold-white centre | 8 | 128 | Revenant death nova | done |
| `chest_open` | Treasure chest bursting open with violet light and bone-coloured sparks (light only, no chest) | 8 | 192 | `Game.open_chest()` ring (plays once the reveal closes) | done |
| `evolution` | Evolution: a dark vortex collapsing into a bright violet-gold flash (vortex frames reordered into a collapse) | 10 | 192 | `burst()` following the necromancer when a chest grants an evolution (`Game.open_chest()`) | done |
| `dread_rally` | Dread Rally: a deep violet shockwave bursting out of a skull-shaped flare, souls streaking outward, then fading to dark wisps | 10 | 256 | Dread Rally burst | done |
| `grave_step_trail` | Grave Step departure: a puff of violet shadow smoke left where the necromancer stepped from, curling and thinning away | 6 | 128 | Grave Step | done |
| `seraphine_nova` | Seraphine's Judgment nova: a thin gold and ivory ring of holy light racing outward with sun-ray streaks, then dissolving into motes (centre empty: the `holy_impact` flash plays there) | 9 | 512 | Judgment nova | done |
| `holy_beam` | Seraphine's holy beams igniting: a white-gold flare bursting from her relic, with short gold rays (the beams themselves stay drawn) | 6 | 192 | beams igniting | done |
| `relic_shatter` | Seraphine's death: the sunburst relic cracking and exploding into gold and ivory shards and a ring of white light, then guttering out | 10 | 256 | Seraphine's death | done |
| `soul_lightning` | Soul Chains strike: a small violet lightning flash with a pale core and crackling sparks, played on each struck foe | 6 | 128 | each struck foe | done |
| `bone_wall_rise` | Bone Wall: one cluster of bone spikes bursting up out of cracked grave dirt, with a puff of dust | 6 | 128 | each segment rising | done |
| `bone_wall_burst` | Charnel Bastion expiring: a bone-spike cluster exploding into flying bone shrapnel with a violet flash | 8 | 128 | each segment bursting | done |
| `wither_aura` | One Wither pulse: a thin ring of moss-green decay mist racing outward and dissolving into falling motes (centre empty) | 8 | 256 | each pulse | done |
| `doom_burst` | Doom Brand detonation: a violet brand sigil (Death Mark is the player's violet) flaring and bursting into a ring of violet doom-fire | 8 | 128 | each branded death | done |
| `raise_dead` | Raise Dead: grave dirt cracking open and a teal soul-fire swirl as a skeletal hand claws up (mound at the feet) | 8 | 128 | each raised skeleton | done |
| `legion_burst` | Legion of Bones: a crumbling skeleton bursting into a ring of bone shards and dust | 8 | 128 | each skeleton's burst | done |

**How the effects pass made them** (Oct 2026, `tools/gen_image.py`, 24 images for 24 strips, then
a second pass of 3 images for `bolt_impact`, `level_up` and `evolution`): one
API sheet per effect at 1536×1024 with the anchors and the Shadow Blast sheet as style references:
6 frames in one row, 8 as a 4×2 grid, 10 as a 5×2 grid (grids give larger frames). Each sheet was
then normalised before `--anim --frames N`: rows and frames split at the widest transparent gaps
(robust to sparks), each frame centred on its alpha centroid (or, for effects on the ground such as
`summon_rise` and `raise_dead`, bottom-aligned so the dirt does not jump), laid out as equal cells.
A few strips were touched up there: frames reordered or split (the Abyssal sheet's burst is a
second strip, and its largest vortex is turned and shrunk over 8 frames for a smooth implosion; the
evolution vortex reversed into a collapse), the Doom Brand sigil's green recoloured onto the violet
ramp by lightness, the last frames faded where a bright core would pop off
(`doom_burst`, `holy_impact`), and one sheet that came back on a dark semi-transparent haze
(`chest_open`) had the dark pixels keyed out. Seraphine's nova first came out as a blocky band at
1300 px, so it and the Soul Nova are built from ONE 1024 px ring image each
(`art_source/effects/*_ring.png`) scaled over the frames and dissolved by a fixed segment mask;
huge thin rings need that, a sheet's frames are too small. Fills were measured on each strip (the outer edge of 95% of its alpha at about the gameplay
radius) and checked in-game.

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

### UI kit and title logo (`assets/ui/`)

**Status:** in the game. The UI stays Godot Controls built in code; the kit only reskins them through
`UiTheme` (same content margins, sizes and focus paths as the old flat boxes; a missing PNG falls back to
the old `StyleBoxFlat` look).

**Title logo** (`assets/ui/logo.png`, 246×90 art px, drawn at `UiArtData.LOGO_SCALE` = 2 on the main
menu through the sharp-pixel shader; the plain "NECROPATHY" label is the fallback). Made from four
image-AI wordmark candidates (all spelled correctly, checked letter by letter); the pick has violet
gothic capitals with a bone bevel, teal soul flames and a skull in the O. Converted with
`python3 tools/prepare_sprite.py <source> ui/logo --art-height 90 --ramps violet,bone,soul
--inside-outline --no-prune --no-levels --no-center --out <png>`, then
`python3 tools/ui_kit.py logo <png>` applies the hand fix (the skull redrawn symmetric with soul-glow eye
glints). Source: `art_source/ui/logo.png`. Prompt essentials: "pixel-art title logo reading exactly
NECROPATHY, about 300 px wide, chunky gothic capitals, violet with a bone bevel and a 2 px ink outline,
teal soul wisps, a skull in the O, transparent background".

**App icon** (`assets/ui/icon.png`, project.godot `config/icon`): `python3 tools/ui_kit.py icon` cuts the
logo's O (shield, skull, flame) onto a 64×64 dark violet badge, saved 2× (128 px).

**Frames** are drawn by code, not by the image AI (AI frames are ornate and uneven and do not 9-slice):
`python3 tools/ui_kit.py frames [--preview sheet.png]` writes `<kind>_<accent>_<state>.png`, each
`2 × UiArtData.SLICE[kind] + CENTER` texels wide and `2 × SLICE_V[kind] + CENTER` tall (SLICE_V defaults
to SLICE), 1 texel = 1 layout px; the preview sheet shows every kind at typical sizes with its crests.
The ornamented kit (menu modernization, owner: "I like the ornaments, we don't want it to look plain and
unappealing") rules:

- **Rings** from the outside in, 1 texel each: an ink outline, bevels lit one shade lighter on the top /
  left (like the sprites), ink gaps; **cut (chamfered) corners on every element**.
- **Fills**: an ordered-dither (4×4 Bayer) **vertical gradient**, lighter at the top (the fill mixed
  `TINT_STEP` per level toward the accent's tint), darker at the bottom (`DARK_STEP` toward black),
  living in the top / bottom 9-slice margins (`SLICE_V`) so it keeps its pixel size at any control
  height; a pressed button or card inverts it (lit from below), sockets (slot, slider track, the off
  toggle) are shadowed at the top. The gradient shades are UI-only fills, like `UiTheme.BG`.
- **Tiling**: `UiTheme` tiles (never stretches) the edges and the centre
  (`AXIS_STRETCH_MODE_TILE`), so the dither stays 1:1. Every edge must repeat cleanly: edges are uniform
  along their length (or periodic in CENTER = 4, like the ribbon's stitching), and every ornament texel
  *and its outline* stays inside the corner squares **one texel clear of the tiled band** (at a tile
  seam the filter reads the texel beside it; `shade_layer()` raises otherwise). The sharp-pixel shader
  falls back to linear sampling per axis, so tile seams do not blur the 1-texel rings.
- **Ornaments** are material masks (`B` bone, `W` white bone, `G` gem, `K` ink) mirrored to the corners
  (and across the diagonal) and only then shaded by one light from the top left (edges facing up / left
  lit, down / right shaded) and outlined in ink, so every mirrored corner is lit correctly. Bone uses
  bone / bone_mid / bone_shade; gems use the accent ramp (violet flare-glow-violet, gold light-gold-brown,
  crimson flame-crimson-dark, soul glow-soul-dark) with a holy-white glint.
- **Crests** (art that must sit mid-edge and never stretch) are separate PNGs `<kind>_<accent>_<crest>`
  drawn on top at their own size by `KitStyleBox` (`UiArtData.CRESTS`: an anchor fraction of the rect
  plus a px offset).
- Palette colours only for rings, ornaments and outlines.
- Accents: **violet** (default), **gold** (evolution cards, chest panel, victory screen, selected
  tiles), **crimson** (active run modifier, Profane Oath, danger, defeat), **soul** (affordable Ossuary
  upgrade, focus), **dim** (locked / disabled), **grey** (HUD slot sockets), **bone** (tooltips).
- Kinds (content margins unchanged for the older kinds, so no layout moved):
  - `button` (normal / hover / pressed / disabled; violet, gold, crimson, soul, dim): ring + bevel,
    gradient, a 3-texel glint by the top-left cut.
  - `panel` (violet, gold, dim): raised moulding, a bone rosette with a gem in each cut corner.
  - `card` (level-up cards; violet / gold × normal / hover / pressed): a double frame (moulding, dark
    channel, inner rail), the corner rosette plus a bone bracket with serif ends on the inner rail.
  - `focus`: ink, soul-glow and soul rings drawn 3 px outside the focused control, thick soul-glow
    corner brackets outlined in ink.
  - `slot` (recessed HUD socket), `bar` (open centre), `tip` (bone ring), `scroll` / `grab`, `line`, the
    CheckButton `toggle_on` / `toggle_off` icons (32×16: socket + bone knob with a gem).
  - **`ornate`** (violet / gold / crimson; `UiTheme.ornate_panel()`): a 5-ring moulding, a bone inlay
    line, a dark channel and an inner rail, chamfer 6; **bone filigree corners** (a rosette with a large
    gem, a knuckled 3-texel bone arm with a thorn, ending in a spiral curl) and the **skull keystone**
    crest (`keystone`, 60×26: a wedge in the frame colours holding a skull with gem eyes, with bone wings
    lying on the inlay that end in small gem rosettes; it rises 9 px above the top edge).
  - **`header`** (`UiTheme.header_band()`): a title band with 45° pointed end caps and a double rule,
    plus the `cap` crest (a 14×14 bone diamond with a gem) sitting on each end.
  - **`ribbon`** (`UiTheme.ribbon()`): a banner backing for the Jacquard banners: a cloth band with
    hems and a stitched bone line, and swallow-tail cloth tails hanging behind its lower half (wholly in
    the bottom margin, so the ribbon keeps its shape at any height), joined by a shaded fold.
  - **`divider`** (`UiTheme.divider()`): a thin ink / accent / ink rule tapering to bone dots, with the
    `crest` (33×15: the skull between bone bars ending in gem diamonds) in the middle.
  - **Slider** (Theme default for every HSlider): `track` (recessed socket), `fill` (raised violet bar,
    brighter on hover / focus) and the `grabber_normal / _hover / _disabled` icons (12×20 bone-rimmed gem
    pommel: violet, soul-teal while hovered / focused, dim), replacing Godot's white round knob.
- Crispness: `UiTheme` gives Buttons, panels, scroll bars and sliders the shared sharp-pixel material as
  they enter the tree, so 1 px rings stay even at the ×1.5 1080p scale; crests are drawn by the same
  node, so they are sharp too.
- **Small UI marks drawn in code** (menu modernization), all on whole layout pixels through the same
  sharp-pixel shader, in palette colours, with cut corners: `MaskIcon` (pixel icons from character masks
  in `mask_icon_data.gd`: padlock, hourglass, tomb, skulls, trophy, candle, rune pips, ember; drawn at
  whole-number scales), `PixelMarks` (level pips, the → arrow Jersey 10 lacks, padlock, empty recipe
  socket), `LevelPips` (card and reward level pips) and the `InputHints` chips (bone keycaps; Xbox-style
  A / B / X / Y octagons in green / red / blue / yellow, grey LB / RB / Start / stick chips, never round).

**Fonts** (font pass; numbers in `UiArtData`, logic in `UiTheme`):

- **Jersey 10** (HUD, numbers, headings, labels, buttons, card names, the recipe row's signs and the
  in-world damage numbers; owner pick from 9 pixel fonts, replacing Pixelify Sans Bold, whose "2" read
  as "8" and "5" as "S"). It is a true grid font: every outline point sits on a 75-unit grid of its
  1400-unit em, so 1 font pixel = em / 18.67, capitals are 10 font px tall. Rasterised in mono at
  **19 px** (`UiArtData.PIXEL_EM`, through `FontFile.fixed_size`) one font pixel is 1.018 texels, so
  every glyph lands exactly 1 texel per font pixel (a glyph-topology check over sizes 9-48 found every
  digit, letter, `%`, `+`, `=` clean from 18 px up; at 9-17 px 3, 5, 6, G and S break). Labels use only
  **19, 28, 38 and 57 px** (`UiArtData.PIXEL_SIZES`: 1, 1.5, 2 and 3 layout px per font pixel; never
  smaller, shrinking would blur), drawn from that one raster through the sharp-pixel shader on every
  Label, Button, HUD widget and the effects layer. The UI scripts keep their old sizes;
  `UiTheme.font_px()` maps each to the nearest of those with the same cap height (× 1.31), so small
  labels grew about 20-30% and the screens were checked to still fit at 1280×720. The font's empty
  line slack (a 20 font px line box for 14 font px of ASCII) is trimmed by 2 px top and bottom
  (`UiArtData.LINE_TRIM`, a FontVariation).
- **Jacquard 24** (screen titles and the event, zone, stance and evolution banners: the TITLE tier): its
  outlines sit on a 30-unit grid of a 1290-unit em, so it is drawn only at **43 px** (its pixel em,
  rasterised at layout size). Titles and the stance word are in title case (blackletter capitals read
  poorly). HUD banners never wrap: a long headline splits at its colon, then steps down to Jersey 38 / 28
  (GDD §15.0 "HUD banner queue").
- **Long descriptions** are Jersey 10 too, at the BODY tier (19 px; owner: "Jersey, let's keep it
  cohesive"): no smooth font is left in the UI. Every label is sized by role through the type tiers
  (`UiTheme.Tier`: TITLE Jacquard 43, HERO 57, HEADER 38, NAME 28, BODY 19, LABEL 19 upper case with
  +2 px letter spacing; sizes in `UiArtData.TYPE_*`; GDD §15.0 "Type tiers").
- Both pixel fonts are imported with anti-aliasing, hinting and subpixel positioning off and
  oversampling 1.0 (rasterised at layout size, not at layout size × window scale).
- Credits: Jersey 10 © 2023 The Soft Type Project Authors and Jacquard 24, both SIL Open Font License
  1.1 (`assets/fonts/OFL-Jersey10.txt`, `OFL-Jacquard24.txt`).

### Menu diorama (`assets/sprites/menu/`)

**Status:** in the game (Oct 2026, menu modernization). The main menu's backdrop (behind every
screen opened from it; the stage select turns it to the focused stage's mood) is a living
pixel-art graveyard at night (`scripts/ui/menu_backdrop.gd`, every number in
`scripts/data/menu_backdrop_data.gd`, GDD §15.0 "Menu diorama"), built mostly from art the game
already has: the gravestones, dead trees, crypt walls, cypresses, saint statue, ruined tower base
and rubble from `obstacles/`, the Graveyard floor tile and its grass and open-grave decals, and the
walk strips of the Warrior, Archer, Mage, Rogue, Risen, Bone Hound and the necromancer. Everything
is grid art drawn 1 art px = 1 layout px through the sharp-pixel shader (loaded through
`EnvironmentArt.texture()`, which always wraps a PNG as grid art, so the menu keys need no
`SpriteData.HEIGHTS` entry). Depth comes from **tints** (the mood's far / mid / near multipliers push
lit art back into the night) and from **draw order**, never from scaling.

New art, all rebuilt by `python3 art_source/menu/make_menu_art.py` (deterministic, `--sheet OUT.png`
writes a x3 review sheet):

| File | Size (art px) | Made by | Notes |
|---|---|---|---|
| `moon` | 104×104 | procedural | bone ramp disc (bone, bone_mid maria, bone_shade crater shadows, holy_white rim on the upper left), no outline against the sky |
| `moon_halo` | 320×320 | procedural | white, 4 stepped alpha discs (255 / 150 / 85 / 40); tinted and faded in game |
| `stars` | 3 frames of 5×5 | procedural | dot, small plus, bright plus; white, tinted |
| `cloud_1..3` | 220×22, 300×28, 150×16 | procedural | long lens-shaped bands, lit white top over a grey body, stepped alpha; tinted |
| `hills_far`, `hills_mid` | 320×70, 384×60 | procedural | tileable silhouette masks (periodic ridge), crosses, stones, dead trees and cypresses on the ridge; tinted flat |
| `ground_lip` | 128×18 | procedural | tileable soil edge with dead grass tufts (floor_soil, floor_moss, moss_dark, moss); its bottom breaks up over the Graveyard tile |
| `fog_1`, `fog_2` | 512×44, 384×34 | procedural | tileable fog banks, white, 3 alpha steps, densest at the bottom; tinted, scrolled |
| `fence` | 64×30 | procedural | wrought-iron section, 2 px bars with spear tips, one bent bar; ink_cold + grey_dark |
| `wisp` | 4 frames of 9×14 | procedural | soul flame teardrop (soul_dark, soul, soul_glow core), swaying tip |
| `flame_soul`, `flame_fire` | 3 frames of 5×8 | procedural | lantern flames (soul ramp / crimson, flame, gold_light) |
| `candle_flame` | 3 frames of 3×5 | procedural | gold_light, holy_white, flame |
| `glow` | 48×48 | procedural | white, 4 stepped alpha discs; tinted under flames, wisps and torches |
| `lantern` | 13×46 | procedural | iron grave lantern on a post (ink_cold, grey), glass lit soul_dark; the flame is drawn over the cage |
| `candles` | 15×11 | procedural | three melted candles (bone, bone_mid, ink_warm) |
| `bat` | 2 frames of 13×7 | procedural | ink silhouette, wings up / down |
| `cathedral` | 200×130 | AI source, converted | the Covenant's cathedral on a hill: a near-silhouette (ink_cold, floor_soil, floor_slate, grey_dark) with gold windows and a crimson rose window |
| `mausoleum` | 55×64 | AI source, converted | stone crypt (grey ramp), moss, iron door ajar with a soul-teal glow |

**Glow and fog rule.** The tintable masks (halo, glow, clouds, fog) use 2-4 **stepped** alpha levels
with hard edges on the art grid, never a smooth gradient, so they stay pixel art. The game tints them
per mood (`MenuBackdropData.MOODS`: `graveyard` night, `crimson_march` dusk, `sanctum` dawn), so no
mood colour is baked in.

**AI sources** (`art_source/menu/sources/<name>.png`, prompt in `<name>.txt`, generated through
`tools/gen_image.py` with three graveyard sprites x6 as the style reference; the moon source was
generated too but the procedural moon was rounder and cleaner). Both sources came back as chunky pixel
art on a regular block grid, so `make_menu_art.py` converts them at their **native grid** (6.4 and
13.5 source px per art px): each art px takes the median colour of its block's central samples,
snapped (OKLab nearest) to a short palette list, then lone pixels are removed. No outline or rim is
added: the sources already had them. `prepare_sprite.py` was not used because its faction ramps and
level stretch would light the near-silhouette cathedral.
