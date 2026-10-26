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
| **chrome** (Act III) | ink_chrome `#0B1220` 0.18 · chrome_dark `#2C3A50` 0.35 · chrome `#5B7397` 0.55 · chrome_light `#9DB6D6` 0.77 · chrome_glint `#E2EEFF` 0.95 | the Electronic Empire's machines and cyborg plating (bluer, more polished than the undead grey) |
| **signal** (Act III) | ink_signal `#240A04` 0.19 · signal_dark `#962410` 0.44 · signal_red `#E0391E` 0.60 · signal_amber `#FFAE1A` 0.81 · signal_glow `#FFEBA8` 0.94 | the Empire's lights, lasers, visors, screens and tracers (more orange than the Covenant crimson) |
| **bronze** (Act IV) | bronze_ink `#1E1408` 0.20 · bronze_dark `#6B4423` 0.42 · bronze `#A8702E` 0.59 · bronze_light `#E0A955` 0.77 | the Olympian Republic's bronze: helmets, cuirasses, round shields, the Titans (warmer and duller than the gold, which keeps its meaning) |
| **marble** (Act IV) | bronze_ink* `#1E1408` 0.20 · marble_dark `#8E8A86` 0.64 · marble `#CFCBC4` 0.84 · marble_light `#F4F1EA` 0.96 | the Republic's marble white: linen, crests, statues, the pale shades of the dead (cooler and greyer than the bone ivory) |
| **aegean** (Act IV) | ink_cold* `#0F141C` 0.19 · aegean_dark `#123E66` 0.36 · aegean `#2C77B8` 0.56 · aegean_light `#6FB6E8` 0.75 | the Republic's Aegean blue: cloaks, crests, emblems, the gods' pale glow (eyes); apart from the arcane blue and the ice |
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

**Status:** 54 strips: the necromancer and the 11 other characters, their 16 skins (since the wave 2 art
review also the 30 Untouchable and Deathlord skins of all 15 characters, from the derived skin rigs); Grand Inquisitor
Seraphine, her Avatar of the Dawn, the Banshee and the Keening Lady (glides: robe hem sway, bob and bust bounce; figure redesign,
Oct 2026); the summons
Warrior, Archer, Mage, Mender, Warder, Rogue, Risen and Bone Hound and the walking evolutions Death
Knight, Gravebow, Shadow Reaper and Hellhound; the Covenant Recruit, Footman, Archer, Chaplain,
Purifier, Shieldbearer, Halberdier, Templar and Banner Bearer, and the Sister of the Scourge (legs, 2 px
bust bounce). **Act I walk strips (Oct 2026, art audit U01 - U03): 18 more**, the summons Corpse Abomination, Bone Colossus,
Corpse Catapult, Ossuary Engine, Crypt Gargoyle, Cathedral Horror, Frost Wraith, Winter Revenant, Profane Bishop and Lich,
the Covenant Sanctified Sentinel, Radiant Inquisitor, High Confessor, Sun Paladin, Cathedral Guardian and the Reckoning
Inquisitor, and the bosses Sir Alaric and Marshal Vael (see "Act I walk strips" below). Every other unit (the other
bosses, structures, the Cathedral Horror's stone form) keeps its still plus the engine motion. A skin's rig is derived from its character's
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

**Hover rigs (flyers; Act III art review, round 1).** The owner: a flying unit's "walk" is a hover,
not a stepping hem. A rig with `mode="hover"` cuts nothing at a hip: the whole sprite rises and sinks
`bob` px once per cycle (`HOVER_BOB`), so the still keeps `bob` empty rows on top (its lowest part
stays on the bottom row, the feet rule; `SpriteData.HEIGHTS` counts the empty rows). Only the rig's
`parts` move: a `flap` part (a wing) drops `FLAP` x `amp` px at its tip, sheared from its `root`
column (the hinge), two beats a cycle; a `spin` part (a rotor seen side-on) is squeezed toward its hub
column to `SPIN` of its width, two turns a cycle. A part is a box of the still, optionally only the
pixels of its `colors` (a bone rotor lifted off the flame behind it); lone pixels left in a part's
box are dropped. Pixels are only moved, never recoloured. Used by the Scout Drone (bob only), the
Grave Drone (wingbeat) and the Wraith Drone (three spinning rotors).

**Stride rigs (Act IV art review, round 1).** The Bronze Titan's still stands with crossed legs, which the legs mode
can only close and open ("mirror his legs so it looks like he's walking"). A rig with `mode="stride"` cuts the legs
off at `hip` (low fists in `keep` ride with the body), takes the near leg (the largest blob right of `near_x0`) as
the forward pose and its mirror image about its own hip as the backward pose, swings it between the two on a cosine
(`STRIDE_SWING`, each frame the nearer pose sheared at most half the way, so the shear stays small), and draws a
one-shade-darker copy (`STRIDE_FAR_SHADE`) half a cycle behind it as the far leg (`far_dx` px aside); the leg swinging
forward lifts (`STRIDE_LIFT_*`). Only colours of the still; frame 0 is the stride, not the still (the approved still
stays as it is and shows when he stands). Round 2 rejected the result ("not even close"); since round 3 no rig uses the
mode (the Titan got a new still with his legs apart and the normal legs rig), it stays in the tool for a later figure.

**Sideways bounce (Act IV art review, round 2).** A rig with `bust_axis="x"` moves its bounce box sideways instead of up
and down: the same field (the bell across the columns, the ramp down the rows, the tail below), but each pixel takes the
pixel |d| columns aside in its own row (+ = right). The walk times it by `BUST_SWAY` (the step's spring, its kick on the
other side every step, as the weight changes feet), the idle by `IDLE_BUST` (one way on the exhale, the other on the
inhale). Used by the Amazon's hip box (one bell: two lobes swaying the same way tore her skirt at the centre column).
**Act I walk strips (Oct 2026, art audit follow-up; GDD §15.0 "Act I walk strips").** The audit's
"walk strips" findings (U01 - U03) were a `walk_cycle.py` job, no generation: 18 rigs added to `RIGS`,
strips built with `python3 tools/walk_cycle.py build <key>`, no code or data changed (a strip is found
by its file name). Review folder `docs/art/act1_walks_review/` (per strip: the still, the strip at 1x
and 4x, a 4x GIF walking in place, `manifest.json`).

| key | rig | notes |
|---|---|---|
| `summons/abomination` | legs, hip 66, spread 3, lift 2 | both huge fists (cols 0-35 and 66-88, rows 66-80) are rigid so they ride with the body; only the two short legs step |
| `summons/bone_colossus` | legs, hip 70, spread 2, lift 2 | club arm (cols 76-98) rigid; the teal loincloth streak (cols 41-49, rows 70-86) rigid, or the back leg's lift cut it |
| `summons/corpse_catapult`, `summons/ossuary_engine` | legs, **spread 0**, lift 1 | **rocking cart**: a wheel cannot turn without being redrawn, so the body dips and each side's wheels take turns riding up a 1 px bump (the Engine's hip 48, the Catapult's 38) |
| `summons/gargoyle`, `summons/cathedral_horror` | hover, **bob 0**, `flap` parts | the wing tips touch row 0, so there is no room to bob; the Gargoyle's big left wing (cols 0-18, root 18, 4 px) and the Horror's two wings (roots 30 and 54, 5 px) drop and rise twice a cycle |
| `summons/frost_wraith`, `summons/winter_revenant` | robe, sway 2 | glides like the Banshee; the Revenant's lightning staff above the hip rides with the body |
| `summons/bishop`, `summons/lich` | legs on the hem lobes, 1 / 1 | the crook / staff and orb rigid (cols 34+ / 34+) |
| `enemies/sanctified_sentinel` | legs, hip 48, 2 / 2 | the groin tassel (cols 34-42) is rigid; the sword arm is above the hip |
| `enemies/radiant_inquisitor`, `enemies/high_confessor`, `enemies/inquisitor` | legs on the hem lobes, 1 / 1 | the Confessor's crook rigid; the Inquisitor's wide sleeves end above the hip |
| `enemies/sun_paladin` | legs, hip 52, 1 / 1 | the lance (cols 0-9) and the shield's lower edge (rows 52-57) rigid |
| `enemies/cathedral_guardian` | legs, hip 106, spread 3, lift 2 | both fists end above the hip |
| `bosses/alaric` | legs, hip 78, 2 / 2 | the cape (cols 0-54, rows 78-102, rigid only down to the boot top: the left boot's toe reaches col 51, and a first version tore it off) and the tabard (cols 86-110) rigid |
| `bosses/vael` | legs, hip 70, 2 / 2 | the tower shield and tabard (cols 46-94, rows 70-106) rigid; the right boot under the shield steps |

Left as stills on purpose: the Cathedral Horror's stone form (it never moves), the Act II / III bosses
(own audits) and structures. Checks: every frame is one connected body (except the specks the still
already has), frame 0 is the still, no new colour, `art_check.py <key>_walk --no-render` (alpha, palette,
feet, lightness all pass; the only FAIL is the Corpse Catapult's Sanctum IV lightness, which its approved
still has too; the height warning is expected for a strip).

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
Seraphine and her Avatar (3 px), the floating Banshee and Keening Lady (2 px, glide strips like
Seraphine's) and the Sister of the Scourge (2 px). The walk bounce plays while the unit moves; standing,
these units play their idle strip (below).

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

**Idle strips (idle breathing bounce, Oct 2026; owner request).** Every rig with a `bust` box also has
an idle loop, `assets/sprites/<key>_idle.png` (`python3 tools/walk_cycle.py idle <key> | --all`;
`idle-preview <key> --out-dir DIR` writes a GIF at the game's rate and a frame sheet). Same contract as
a walk strip: **24 frames** (`IdleData.FRAMES`), each the still's exact size, frame 0 the still, no
colour the still lacks. The stills fill their frame up to row 0 (hats, halos, staff heads), so the
breath cannot rise above the still: the still is the full breath, and the exhale sinks every row above
the hip by 1 art px (`IDLE_SINK`; the last row above the hip is the one taken out, `IDLE_FIX` "waist"
to choose another), so the hip, the legs or hem and the feet never move. The bust reacts through the
same `_bounce()` field, kicked by each sink and rise like a damped spring (`IDLE_BUST` = lag -0.5,
overshoot +0.75, a smaller rebound -0.375 that only moves the box's centre, then rest; mirrored on the
inhale). The loop at `IdleData.FPS` (8 frames a second, 3.0 s a breath): 0.75 s at rest, the exhale
and its wobble, 1.5 s exhaled, the inhale and its wobble, 0.75 s at rest. In the game (`UnitMotion`)
a standing unit (not walking by the `WalkData` hysteresis) plays it on game time from the moment it
stopped (frame 0 first, so stopping never pops and units fall out of step with no RNG or id); a walk
frame always wins, and frozen, stunned, stone, dead, dashing, airborne and structure bodies show the
still. Boss attack poses keep their pose stills. Nine strips: the Wither Witch, the Soulbinder, their
Hyper skins, Seraphine, her Avatar, the Banshee, the Keening Lady and the Sister of the Scourge (who
stands only while she lashes). The wave 2 art review added ten: the Untouchable and Deathlord skins of
the Soulbinder, the Wither Witch, the Brine Widow, the Tide Widow and (round 2, redrawn in the figure-redesign
style) the Voidcaller.

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

**Wave 2 art review: the Untouchable and Deathlord skins (drawn art for every character).** The two
universal skins (`SkinData.UNIVERSAL_SKINS`) began as palette variants of each character's sprite; the
owner's review: "Don't just tint here, let's make a cool new skin", and the owner chose full drawn art for
every character (GDD §15.0 "Wave 2 art review: Untouchable and Deathlord skins"). All 30 are in;
`SkinGlyphs` draws a skin's PNG as-is, and the tint (sprite × `Color(2.2, 3.2, 3.0, 0.78)` for Untouchable,
× `Color(0.4, 0.33, 0.4)` plus the gold `crown` emblem for Deathlord, with an aura ring) is only the
fallback for a missing PNG.

- **Untouchable**, a ghost-white phantom: pale luminous robes and armour in ice white and pale blue
  (`ice_light`, `ice`, `grey` shadow), the hem and loose cloth dissolving into a few big wisp tails (at
  least 3 px wide), soul-teal eyes, flames and weapon glows, a pale lavender lining (`violet_flare`) so
  the player's violet stays. Main-shape OKLab L about 0.76-0.86: it clears every floor.
- **Deathlord**, a crowned dread-king: a big spiked or horned gold crown (spikes 2+ px), a **flat
  mid-violet** robe or gown (`violet` main: black cloth sank into the floors), black-iron armour pieces
  (`grey_dark` with `grey` edges), gold only on a few large pieces (crown, one band, the weapon head:
  scattered gold trim converted into specks), a crimson-lined mantle. Main-shape L 0.50-0.53, like the
  violet base characters (the same two code-drawn Sanctum floors fall short, as for every violet sprite).

Process: `tools/gen_image.py` with two references, the character's own sprite enlarged ×12 (square
canvas) and the anchors sheet; the prompt template with "a NEW costume skin of the character in the
first attached image: same pose, silhouette and proportions; redesign the costume completely, not a
recolour". Converted with `--inside-outline --no-prune --no-levels` (variant "b") at the art height that
keeps the character's body height; a crown or drifting ghost hair adds rows on top. Two review redraws
(prompt additions): the four female ghosts ("v2 (face)": the face uncovered in warm bone skin against
the cold white, outlined, teal eyes, the veil behind it, a darker icy bodice so the hourglass reads; the
v1 faces vanished pale-on-pale) and eleven Deathlords ("v2 (clean)": flat mid-violet cloth, black iron
on a few big pieces, gold on a few large pieces, no scattered specks). Walk strips come from the derived
skin rigs (`walk_cycle.py` `SKINS`); the 10 bust skins also get idle strips; `SKIN_FIX` sets the bust
box of the ghost Wither Witch (her wisps widen her lower body, so the derived columns slid right), of
the crowned Brine Widow (her bust sits no lower than the base widow's) and, after the owner's review round
2, of the crowned Tide Widow (her derived box ended on the belt) and of both Voidcaller skins (her base
rig has no bust box). Check a box with a motion map: only the bust's underside (and the few rows of fade
below it) may change between the rest frames of a strip. Every still passes
`art_check.py` (height, alpha, palette, feet, lightness on the Graveyard and March floors, no speck
warning).

| File | Skin (character) | Subject | Art px (W×H) | Status |
|---|---|---|---|---|
| `gravecaller_untouchable.png` | Untouchable (Gravecaller) | The Gravecaller as a ghost-white phantom: the skull pauldrons become pale spectral skulls with teal eye sockets; the staff is pale ghost-bone and its skull burns with soul-teal flame | 42x56 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `gravecaller_deathlord.png` | Deathlord (Gravecaller) | The Gravecaller as a crowned dread-king: a tall black-iron HORNED CROWN with gold spikes on top of the hood (two curved horns); black-iron plate pauldrons with gold edges instead of the skulls; a heavy crimson-lined mantle fastened by a gold skull clasp; the staff black iron with gold bands, its skull burning in violet flame | 46x60 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `umbral_warden_untouchable.png` | Untouchable (Umbral Warden) | The Umbral Warden as a ghost-white phantom: the plate armour becomes pale moonlit ghost-steel; the black sun on the staff becomes a white ghost-sun ringed with soul-teal light, the orbs pale teal wisps | 44x63 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `umbral_warden_deathlord.png` | Deathlord (Umbral Warden) | The Umbral Warden as a crowned dread-king: a black-iron great helm under a gold spiked crown; heavy black plate armour with gold edges; a crimson-lined black mantle; the staff's black sun ringed with a gold-and-crimson corona | 40x63 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `voidcaller_untouchable.png` | Untouchable (Voidcaller) | The Voidcaller as a ghost-white phantom **in the figure-redesign style** (owner's review round 2): an exaggerated hourglass (very large bust, cinched waist, very wide hips and a full rear) in a fitted low-necked ghost gown with a high slit, fully clothed; long ghost-white hair framing a warm bone face with teal eyes; the void ring a ring of soul-teal light | 34x53 | done (round 2): source r2a, refs = her sprite + the Soulbinder's Untouchable (figure guide) + the anchors; `pixelate_source.py`, then `--no-prune --no-levels` (the `--inside-outline` copies flattened the bust white-on-white); one eye hand-painted (18, 10); walk + idle, `SKIN_FIX` bust box (14-25, rows 13-19, two lobes) |
| `voidcaller_deathlord.png` | Deathlord (Voidcaller) | The Voidcaller as a crowned dread-king **in the figure-redesign style** (owner's review round 2): the same hourglass figure in a fitted mid-violet gown with a high slit, black-iron pauldrons and corset plate, a tall gold spiked crown on her dark hair, a crimson-lined collar and mantle, gold bracers; the void ring crimson and violet | 40x56 | done (round 2): source r2b, refs = her sprite + the Soulbinder's Deathlord (figure guide) + the anchors; `--inside-outline --no-prune --no-levels` (the pixelate path turned the gold crown brown); one eye hand-painted (23, 11); walk + idle, `SKIN_FIX` bust box (17-28, rows 16-21, two lobes) |
| `bone_oracle_untouchable.png` | Untouchable (Bone Oracle) | The Bone Oracle as a ghost-white phantom: the skull mask is polished white with teal eye glints; the spear is pale ghost-bone with a teal-glowing tip; the floating shards become pale glowing spirit shards | 38x57 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `bone_oracle_deathlord.png` | Deathlord (Bone Oracle) | The Bone Oracle as a crowned dread-king: a black skull mask under a tall gold horned crown; black robes with gold trim and a crimson sash; the spear black iron with a gold head; the floating shards gold | 36x56 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `fallen_confessor_untouchable.png` | Untouchable (Fallen Confessor) | The Fallen Confessor as a ghost-white phantom: the stole becomes pale ice-blue; the censer is ghost-silver leaking soul-teal smoke; teal soul wisps in his open hand | 42x48 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `fallen_confessor_deathlord.png` | Deathlord (Fallen Confessor) | The Fallen Confessor as a crowned dread-king: a black hood with a gold spiked crown over it; black vestments with a crimson stole edged in gold; the censer gold, leaking crimson smoke | 48x53 | done: source v2 (clean), `--inside-outline` (levels on: the no-levels copy sank to L 0.38); walk |
| `carrion_lord_untouchable.png` | Untouchable (Carrion Lord) | The Carrion Lord as a ghost-white phantom: the heavy mantle becomes a pale spectral shroud; the bone plates and ribcage pauldron glow faintly teal at the joints; the cleaver is a pale ghost-blade with a teal edge | 58x52 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `carrion_lord_deathlord.png` | Deathlord (Carrion Lord) | The Carrion Lord as a crowned dread-king: a massive black-iron horned crown; black-iron plates edged in gold and a crimson fur-trimmed mantle; the cleaver a black-iron blade with gold edge | 58x56 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `plague_scholar_untouchable.png` | Untouchable (Plague Scholar) | The Plague Scholar as a ghost-white phantom: the long beaked mask is bone-white with two teal-glowing lenses; the censer leaks pale teal ghost-smoke; the vials glow teal | 62x49 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `plague_scholar_deathlord.png` | Deathlord (Plague Scholar) | The Plague Scholar as a crowned dread-king: a black beaked mask under a small gold crown; a black mantle lined crimson; the censer gold leaking violet smoke; gold vials | 54x52 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `doomsayer_untouchable.png` | Untouchable (Doomsayer) | The Doomsayer as a ghost-white phantom: the eye sigil on the hood glows teal; the branding iron burns with soul-teal fire | 30x53 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `doomsayer_deathlord.png` | Deathlord (Doomsayer) | The Doomsayer as a crowned dread-king: a tall black-iron crown with gold spikes over the hood; a heavy crimson mantle; the eye sigil gold; the branding iron gold-hot | 32x55 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `barrow_warden_untouchable.png` | Untouchable (Barrow Warden) | The Barrow Warden as a ghost-white phantom: the slab shield is pale ghost-stone with a glowing teal skull rune; the armour pale spectral bone; the shovel staff pale ghost-wood | 40x59 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `barrow_warden_deathlord.png` | Deathlord (Barrow Warden) | The Barrow Warden as a crowned dread-king: a black-iron horned crown over the hood; black-iron armour with gold edges; the slab shield black stone with a gold skull; a crimson mantle | 44x61 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `soulbinder_untouchable.png` | Untouchable (Soulbinder) | The Soulbinder as a ghost-white phantom: her hair ghost-white and drifting; the chains are pale glowing soul-teal spirit chains; teal lightning from the raised hand | 40x61 | done: source v2 (face), `--inside-outline --no-prune --no-levels`; one eye hand-painted (22, 14); walk + idle (bust) |
| `soulbinder_deathlord.png` | Deathlord (Soulbinder) | The Soulbinder as a crowned dread-king: a tall black-and-gold spiked crown; a regal black gown with gold trim and a high crimson-lined collar; gold chains; violet lightning from the raised hand | 40x63 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk + idle (bust) |
| `wither_witch_untouchable.png` | Untouchable (Wither Witch) | The Wither Witch as a ghost-white phantom: the wide hat and shawl become pale ghost-white and frayed into wisps; the branch staff is bleached ghost-wood with a teal glow at its tip | 34x49 | done: source v2 (face), `--inside-outline --no-prune --no-levels`; `SKIN_FIX` bust box; walk + idle (bust) |
| `wither_witch_deathlord.png` | Deathlord (Wither Witch) | The Wither Witch as a crowned dread-king: the wide hat black with a gold crown band and gold thorn spikes; a black corset dress with crimson lining and gold trim; a crimson shawl; the branch staff black with a gold tip | 32x50 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk + idle (bust) |
| `grave_herald_untouchable.png` | Untouchable (Grave Herald) | The Grave Herald as a ghost-white phantom: the tabard is ghost-white with a teal skull mark; the horn pale ghost-bone; the banner a pale spectral banner whose end frays into wisps, the skull on the pole glowing teal | 48x62 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `grave_herald_deathlord.png` | Deathlord (Grave Herald) | The Grave Herald as a crowned dread-king: a black-iron horned crown over the hood; a black tabard with a gold skull; the horn gold; the banner crimson with a gold skull and the pole's skull crowned in gold | 44x63 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `brine_widow_untouchable.png` | Untouchable (Brine Widow) | The Brine Widow as a ghost-white phantom: the veil becomes a long pale ice-blue spirit veil; the crown is a pale pearl crown; the hooked staff is bleached driftwood with soul-teal water curling around it | 46x58 | done: source v2 (face), `--inside-outline --no-prune --no-levels`; walk + idle (bust) |
| `brine_widow_deathlord.png` | Deathlord (Brine Widow) | The Brine Widow as a crowned dread-king: a tall black-and-gold spiked crown over a crimson veil; a regal black gown with gold trim; the hooked staff black iron with gold bands | 48x60 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; `SKIN_FIX` bust box; walk + idle (bust) |
| `heretic_scribe_untouchable.png` | Untouchable (Heretic Scribe) | The Heretic Scribe as a ghost-white phantom: the quill-staff's feather glows soul-teal; the scroll is pale and glowing with teal writing | 46x60 | done: source v1, `--inside-outline --no-prune --no-levels`; walk |
| `heretic_scribe_deathlord.png` | Deathlord (Heretic Scribe) | The Heretic Scribe as a crowned dread-king: a black hood under a gold spiked crown; black robes with gold trim and a crimson mantle; the quill-staff gold with a crimson feather; a black scroll with gold writing | 44x61 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk |
| `tide_widow_untouchable.png` | Untouchable (Tide Widow) | The Tide Widow as a ghost-white phantom: the shawl and veil are pale ghost-white and frayed into wisps; the coral crown is pale pearl-white; the conch on the staff glows soul-teal | 38x56 | done: source v2 (face), `--inside-outline --no-prune --no-levels`; walk + idle (bust) |
| `tide_widow_deathlord.png` | Deathlord (Tide Widow) | The Tide Widow as a crowned dread-king: a tall black-and-gold spiked crown; a regal black gown with gold trim and a crimson shawl; the conch staff black with a gold conch | 42x58 | done: source v2 (clean), `--inside-outline --no-prune --no-levels`; walk + idle (bust); round 2: `SKIN_FIX` bust box moved up onto the bust (19-28, rows 17-23; the derived box ended on her gold belt: "she's jiggling her belt"), both strips rebuilt |

**Content wave 2: the title frame (code only, no PNG; owner review).** The Heretic's Bane frame is drawn
in code on the pixel grid (`TitleFrame`).

| Look | Where | How it is drawn | Status |
|---|---|---|---|
| **Heretic's Bane frame** | pre-run hero box | a 4 px gold band with 10 px cut corners and a darker inner line, a 9 × 8 px gold skull (×2) on each corner, a Chaplain's skull under a holy cross (×3) at the top centre | code, for review |

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
| `fallen_seraph.png` | Fallen Seraph (Act II, Seraphine's gift; figure redesign): a hovering corrupted angel with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips), fully clothed in a fitted, low-necked ash-grey gown with a high slit fraying into wisps, pale bone skin, long ash-white hair down her back, teal eyes, a cracked pale halo above her head, two broken black wings (the far one raised, the near one snapped and hanging), a black feather blade in her near hand. Never Covenant gold: bone, grey and a teal glint only. Generated with Seraphine and the Banshee attached, then redrawn from that design on a 52-block grid; `deglow.py` (the AI's soft dark haze dropped below alpha 230), `pixelate_source.py`, `prepare_sprite.py --ink-l 0.15 --no-cleanup --no-prune --ramps bone,grey,soul`; the wing pixels shaded one step down by hand (`grey_light` -> `grey` -> `grey_dark`) so the wings read black against the ash gown (passes every floor). Glide strip (robe rig, the hanging wing rigid) and idle strip with a 2 px bust bounce | 52 | done |
| `ruin_seraph.png` | Seraph of Ruin (Fallen Seraph evolution): the same figure taller in a charcoal gown, both black wings whole and spread wide, a cracked halo with a crown of black thorns. Generated from the Fallen Seraph source with the Keening Lady attached; converted and wing-shaded like her. Glide and idle strips (both wings rigid, 2 px bust bounce) | 60 | done |

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
| `battle_sister.png` | Sister of the Scourge (Crimson March and Sanctum; owner request, Oct 2026, the figure-redesign style): an alluring battle-nun with an exaggerated hourglass figure (a very large bust, cinched waist, wide hips) in a fitted, low-necked crimson corset gown with ivory trim and a very high slit, an ivory veil with a gold circlet, a warm-steel pauldron, gauntlets and greave boot, a three-tailed crimson scourge with steel barbs trailing from her front hand; fully clothed. Signature: the veil, the figure and the trailing scourge. Generated with Seraphine and the Halberdier attached (enlarged), then once more from that design asking for a 52-block grid (much cleaner conversion); `skin_cap.py` then `--no-levels`; the ivory panels that snapped to `holy_white` repainted `bone` by hand (no glow on soldiers). Walk strip with a 2 px bust bounce | 52 | done |
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
| `empowered_grave.png` | The Graveyard's empowered grave: an open earthen grave pit pouring green soul-light, a small cracked tombstone at its head, bones and a skull at the lip (stage data `sprite`; the claim ring, glow and reward icon stay drawn in code) | 40 | done |
| `battlefield_dead.png` | The Crimson March's empowered grave: a heap of fallen Covenant soldiers (crimson-and-ivory shields, a helmet, a broken spear, skulls) seeping green soul-light. Converted through `pixelate_source.py` and `--no-cleanup` (the direct conversion turned the shields into crimson blotches) | 36 | done |
| `sanctum_crypt.png` | The Sanctum's empowered grave: white marble flagstones with gold inlay cracking open over a dark crypt slab, green soul-light through the cracks (the marble's whites take the gold ramp's holy white: `art_check` warns about glow, kept for the marble) | 36 | done |
| `crypt_door.png` | The Crypt Defender's crypt: a half-sunk stone crypt facade, an arched door ajar with green light in the gap, three green runes and a skull keystone, moss | 56 | done |
| `consecration_grave.png` | A grave the Chaplains try to consecrate: a plain earthen mound and a weathered tombstone, no glow (the gold target ring and channel arc stay drawn in code) | 30 | done |

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
| `seraph_feather.png` | One black feather blade of the Fallen Seraph's feather ring (drawn rotated around the expanding ring, `SeraphGlyphs.draw_ring()`): hand-placed 14x5 pixels, `ink_cold` outline, `grey_dark` vane, `grey` and `grey_light` spine | 14 | done |

### Volley shots and bursts (`assets/sprites/volleys/`, two `effects/` strips)

The bullet heaven pass (GDD §15.0 "Bullet heaven pass" and "Volley art") fires hundreds of shots at
once, in every class's colour, so its art breaks the palette rule on purpose: each file is a **grey
tint mask** (white = the hot core, stepped greys = glow and trail, binary alpha, no hue). The game
multiplies it by the shot's colour (lightened 30% toward white for a hot core, `VolleyData.ART_WHITEN`)
and draws it **additively** with linear filtering, so one image serves all twelve classes, their
evolutions and the spell echoes. Shots point **right** (head right, trail left) and include their own
trail. Converted with `tools/volley_art.py` (crop, scale to 40 px on the longest side, 72 for the
wave, 5 stepped greys, binary alpha; strips: frames split at the transparent gaps, centred on their
alpha centroid in one shared square, 64 px frames). Sizes and timing are in `scripts/data/volley_data.gd`
(`ART_*`, `HIT_*`, `FLASH_*`); without a file the code shapes stay.

| File | Subject | Stored px | Used by | Status |
|---|---|---|---|---|
| `volleys/shard.png` | A jagged bone splinter with a crackling comet trail and two flying sparks | 40×14 | Warrior, Archer, Warder, Frost Wraith, catapult and spell shards | done |
| `volleys/orb.png` | A blazing orb with a ring halo, two orbiting motes and a flared tail | 40×21 | Abomination / Colossus chunks, Bone Hound / Hellhound wolves, Bishop / Profane Bishop orbs, spell orbs | done |
| `volleys/dagger.png` | A spectral thrown dagger with speed streaks and a star glint on the tip | 40×15 | Rogue, Shadow Reaper | done |
| `volleys/spark.png` | A four-pointed starburst with lightning arcs and a short tail | 40×22 | Mage forks, Mender seekers, Lich spiral, spell sparks | done |
| `volleys/note.png` | A bright sound-wave crescent with two fading echo arcs | 40×31 | Banshee, Keening Lady | done |
| `volleys/feather.png` | A pointed stone feather dart with a wispy trail | 40×15 | Gargoyle, Cathedral Horror | done |
| `volleys/wave.png` | A broad crescent sword slash, white edge, streaks behind | 72×50 | Death Knight showpiece | done |
| `effects/volley_hit.png` | Impact: a white-hot starburst, then a ring breaking into sparkles (6 frames) | 64 | every volley hit, tinted with the shot | done |
| `effects/volley_flash.png` | Launch: a rune ring flaring open with rays, then spinning into motes (6 frames) | 64 | every volley fired (at the landing point for a rain), at 45% opacity | done |

**How it was made** (Oct 2026, `tools/gen_image.py`, 9 images, about $0.29): one prompt per shot
(1024×1024, "ONLY pure white and light-to-mid greys: the game tints it") and one 6-frame sheet each for
the impact and the launch flash (1536×1024, the effects-sheet prompt above with the same colour line),
references `art_source/projectiles/shadow_bolt.png` and `art_source/effects/shadow_blast.png`
(`bolt_impact.png` for the sheets). Every image was used as it came. First in-game look: the launch
flashes at full opacity stacked over a 45-unit ring into a white blob, so they draw at 45%, and the
sword wave's glow halo is capped at 12 px.

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

**Synergy badges** (Synergies for the newer classes, Oct 2026): the thirteen army synergies `syn_<id>`
(the four original ones, which were code-drawn until then, the eight setter / finisher pairs and the
Charnel Menagerie) made the same way on the **violet** border: one symbol per prompt (26 art px,
`--ref icons/shadow_bolt.png`), `prepare_sprite.py --no-center --no-prune --no-levels` (`--no-cleanup`
for the skull faces and eyes: Killing Field, The Wild Hunt, Baying, the Menagerie, Deathless, Unholy
Host), composited on the cut-corner badge template. Each pair shows its setter's material (flesh,
stone wing, ice, wail) meeting its finisher's (sword, boulder, dagger, hound skull, mage orb). Shown at
22 px in the HUD list. `ProgressionGlyphs` keeps code-drawn fallbacks. 13 images, about $0.20.

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
| `fallen_seraph.png` | A pale fallen angel in profile with a cracked halo and a broken black wing |
| `ruin_seraph.png` | Two spread black wings under a thorn-crowned cracked halo (evolution frame) |
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
| `fallen_grace.png` | A cracked pale halo with a black feather falling through it, teal sparks at the crack |
| `profane_pact.png` | Torn scroll with a crimson seal (the curse: the one icon allowed crimson) |
| `powerup_magnet.png` | Teal soul vortex |
| `powerup_feast.png` | Roasted meat on a bone |
| `powerup_hyper.png` | Violet lightning rune |
| `powerup_stasis.png` | Frozen hourglass |
| `powerup_frenzy.png` | Flaming skull |
| `powerup_nova.png` | Violet starburst |
| `grave_step.png` | Grave Step (dash): a hooded violet shadow stepping sideways, two fading afterimages behind it |
| `dread_rally.png` | Dread Rally (ultimate): a skull inside a dark violet burst ring, soul wisps rising |
| `sovereigns_decree.png` | Sovereign's Decree (content wave 2 ultimate): a bone skull with teal eyes under a big three-pointed violet crown (symbol at 26 px, `--no-cleanup` keeps the sockets and teeth) |
| `eclipse.png` | Eclipse (content wave 2 ultimate): a black sun disc inside a thick violet corona ring with four short rays and a pale crescent on its upper-left rim |
| `grave_tide.png` | Grave Tide (content wave 2 ultimate): a curling soul-teal wave with two bone skeletal hands reaching up out of it |
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
| `syn_shieldwall.png` | Synergy Shieldwall of the Damned: a round bone shield behind a teal barrier arc |
| `syn_volley.png` | Synergy Volley of the Fallen: a bone arrow flying into a violet diamond mark |
| `syn_deathless.png` | Synergy March of the Deathless: a bone skull rushing right with teal speed streaks |
| `syn_unholy_host.png` | Synergy The Unholy Host: three bone skulls in a violet aura ring |
| `syn_flesh_rampart.png` | Synergy Flesh Rampart: a bone sword striking down into a moss-green flesh shockwave |
| `syn_killing_field.png` | Synergy Killing Field: a skull-faced bone boulder falling onto a flesh shockwave |
| `syn_death_from_above.png` | Synergy Death from Above: a stone gargoyle diving with a bone dagger |
| `syn_wild_hunt.png` | Synergy The Wild Hunt: a stone gargoyle wing over a snarling hound skull with a teal eye |
| `syn_cold_blood.png` | Synergy Cold Blood: a bone dagger stabbed through an ice crystal |
| `syn_shatterfall.png` | Synergy Shatterfall: a bone boulder smashing an ice crystal into shards |
| `syn_requiem.png` | Synergy Requiem: an arcane-blue orb bursting between two pale wail ripples |
| `syn_baying.png` | Synergy Baying of the Damned: a howling hound skull with pale wail ripples |
| `syn_charnel_menagerie.png` | Synergy The Charnel Menagerie: a skull-topped rib cage holding a teal soul flame |
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

### Placeholder art batch (markers, overlays, spell props; Oct 2026)

The last code-drawn things a player sees in a run (and four icons the code asked for without a PNG)
got pixel art, exactly like the empowered graves: each drawing site names its key in
`scripts/data/marker_art_data.gd` (`MarkerArtData`, with the placement numbers), draws it through
`SpriteBank.draw()` / `draw_flat()` / `draw_rising()` / the icon path, and **keeps its code drawing as
the fallback** when the PNG is missing. Rings, telegraphs, zones, glows and progress arcs stay in code
(retired for the Covenant's area effects: see "Act I enemy AoE art" below) (the rally's closing ring, the brand's turning sigil, the stun ring, the nova's safe rings, the cold
(retired for the necromancer side's ground effects by "Player AoE art" below; the rally's closing ring, the brand's turning sigil, the stun ring, the nova's safe rings, the cold
disc under the ice shell, the ember glow under a burning boulder). Flat sprites are drawn 1:1 without
a shadow (`SpriteData.FLAT_SIZES` = the longest side); the two wall segments and the stone still are
world sprites (`SpriteData.HEIGHTS`). Purely visual: no gameplay state, no RNG (the corpse variant is
the corpse's pool slot `k % 3`, the wall segment's mirror its index `k % 2`).

| Key | Subject | Art px (w × h) | Drawn by | Status |
|---|---|---|---|---|
| `markers/rally_pennant` | A boss's Call to Arms rally point: a warm-steel pole with a gold knob and a crimson swallow-tailed pennant with a gold stripe | 28 × 30 | `StageDirector._draw_mark()` (the crimson closing ring stays code) | done |
| `markers/buff_chevron` | Gold up-chevron over a Covenant soldier buffed by a Banner Bearer / Holy Standard aura | 10 × 7 | `MarchGlyphs.draw_buffed()` | done |
| `markers/sun_ward` | Sun Paladin ward: a tiny gold heater shield with a crimson sun | 8 × 10 | `SanctumGlyphs.draw_ward()` | done |
| `markers/sanctuary_cross` | Seraphine's nova safe spot: an ivory cross with a ring round its crossing, icy glints | 20 × 28 | `SeraphineHazards._draw_overlay()` (the safe rings and countdown arc stay code) | done |
| `markers/mage_mark` | Volley of the Fallen mark: a violet diamond with a soul-green core | 8 × 10 | `Enemy._draw_over()` (the code diamond stays the synergy icon fallback) | done |
| `markers/death_brand` | Death Mark: a bone skull with violet eye sockets and a small violet flame | 12 × 14 | `GraveSpellGlyphs.draw_brand()` (the turning sigil stays code) | done |
| `markers/death_brand_doom` | Doom Brand: the skull with soul-green eyes under a taller violet flame | 12 × 16 | same | done |
| `markers/stun_stars` | Three pale-gold four-point stars in an arc (a still: the overlay layer redraws only when a unit's look changes, so a loop would need per-frame redraws) | 16 × 11 | `ReaperHorrorGlyphs.draw_stun()` (the faint ring stays code) | done |
| `overlays/frozen_shell` | Stasis / Deep Freeze: a ring of jagged ice crystals with three spikes, the centre open | 36 × 40 | `PowerupGlyphs.draw_frozen()`: a whole-number scale of body radius × 3.2 / 40 (`FROZEN_SHELL_PER_RADIUS`; ×1 for soldiers up to a radius of ~18 px, ×2 for the bosses, so its pixels stay even), alpha 0.9 over the code's translucent cold disc | done |
| `decals/corpse`, `_2`, `_3` | Corpse Explosion corpses: crossed bones and a skull; a skull by a broken ribcage; scattered bones on a torn crimson rag. Unlike the floor decals they keep an outline (they are spell targets, not floor texture) | 12 × 12, 16 × 10, 16 × 10 | `SpellGlyphs.draw_corpse()`, variant by pool slot, fading 1.0 → 0.35 | done |
| `structures/bone_wall_segment` | One Bone Wall segment: three curved bone spikes erupting from a cold-grey rubble mound, a violet glint | 20 × 26 | `GraveSpellGlyphs.draw_wall_segment()` through `SpriteBank.draw_rising()` (grows out of the ground as it rises and sinks as it crumbles; odd segments mirrored) | done |
| `structures/bone_wall_bastion` | One Charnel Bastion segment: four spikes, a skull with teal eyes at their base, soul-teal light in the mound's cracks | 24 × 30 | same | done |
| `projectiles/corpse_boulder` | Corpse Catapult boulder: a big bone skull with teal eyes and a cranium crack (the catapult's own cup skull) | 16 × 14 | `WarbandGlyphs.draw_boulder()`: upright (no spin), 1:1 up to a radius of 7 px, larger high in its arc | done |
| `projectiles/corpse_boulder_burning` | Ossuary Engine boulder: the skull with burning orange eyes under a crown of flames | 14 × 23 | same (centred on the skull; the code ember glow stays) | done |
| `projectiles/oracle_shard` | Bone Oracle Ossuary Ward shard: a polished bone splinter with a violet tip glint | 20 × 6 | `CharacterInnates._draw()`, turned along the orbit | done |
| `projectiles/eclipse_orb` | Eclipse Ward orb: a black orb in a violet corona with a soul-green crescent | 20 × 18 | `OrbShield._draw_eclipse()`, its crescent turned outward, dim while recharging (the band, segments and charge arc stay code) | done |
| `summons/cathedral_horror_stone` | The Cathedral Horror's stone form: its still with every colour on the grey ramp by lightness, its teal runes dark (derived, not generated) | 72 × 64 | `SummonedUnit._draw_body()` while `stone_form` (`summons/<kind>_stone`; the code stone shell is skipped) | done |
| `icons/heal` | Dark Restoration fallback card: a violet heart with a soul-teal plus, two teal soul wisps curling into it | 32 × 32 | icon path | done |
| `icons/grave_fortitude` | Grave Fortitude fallback card: a rounded grey tombstone shield with a carved soul-teal plus on a heap of grave earth | 32 × 32 | icon path | done |
| `icons/call_of_the_grave` | Call of the Grave fallback card: three skeletal hands clawing up out of one grave mound, teal soul fire between them | 32 × 32 | icon path | done |
| `icons/tree_oath` | The Ossuary's Oath tree emblem: a copy of `icons/profane_oath` (the tree's only upgrade) | 32 × 32 | icon path | done |
| `ui/rotate_phone` | The "turn your device" overlay's phone: a soul-teal case with cut corners, a dark screen, a speaker slit and a home bar (procedural) | 35 × 60 | `RotateOverlay._phone()`, drawn ×2 upright (faded) and turned | done |

Not made: `summons/gargoyle_stone` (only the Cathedral Horror has a stone form: `stone_duration` is
set only in its evolution recipe, so a Crypt Gargoyle never turns to stone).

**How they were made** (10 images, about $0.20, `tools/gen_image.py`; prompts in
`art_source/placeholders/prompts/`). Small markers were **batched**: one 1536×1024 sheet per family
(Covenant marks, player / undead marks, projectiles, corpses, bone walls) with 2-4 subjects in a row
and wide transparent gaps, the approved sprites ×8 attached, each subject's art px size in the
prompt; the sheets were cut apart at their empty columns and each piece converted with
`prepare_sprite.py --art-height N --ramps ... --no-levels` (the folder has no faction set, so the
ramps are always given). The image AI drew these sheets as chunky pixel art with its own outline
(12-17 source px per block), so: the tiny marks convert well directly (add `--no-cleanup` for eyes
and star cores); the corpses, the sun ward, the boulders and the Call of the Grave symbol came out
cleaner with **`--inside-outline`** (the source's own outline kept, no second ring), while
`pixelate_source.py` first gave blotches here. The first corpse boulder (a lumpy flesh ball with a
bone through it) was unreadable at 14 px and was regenerated as a plain skull matching the
catapult's cup (`p_boulders.txt`). The icons follow the icon rules (one symbol per prompt at 26 px,
`--no-center --no-prune --no-levels`). The derived pieces are rebuilt by
`python3 art_source/placeholders/make_placeholder_art.py` (deterministic): the three fallback badges
(the 26 px symbols in `art_source/placeholders/symbols/` centred on the violet cut-corner badge cut
from `icons/tree_survival`), the Oath tree copy, the stone still and the procedural phone.

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
| Gullhaven (Act II) | tide puddle → code (every zone); shells → `harbour_mudflats_shells` (8x8, 8x7), kelp → `harbour_mudflats_kelp` (14x8, mirrored); fish scales → `harbour_market_scales` (14x10, 11x7), rope coil → `harbour_market_rope` (20x16, 16x13), dropped fish → `harbour_market_fish` (19x7, 16x6); coral crust → `harbour_chapel_coral` (16x15, 13x11), barnacles → `harbour_chapel_barnacles` (17x11, 14x9), the Eye's sigil → `harbour_chapel_sigil` (25x24); mooring ring → `harbour_seawall_ring` (10x12), rusted chain → `harbour_seawall_chain` (22x11, 20x10), gull feather → `harbour_seawall_feather` (6x5, mirrored) |

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
| `seraph_dive` | Fallen Seraph dive impact: a pale flash, then a ring of black feathers and ash dust flung outward with a thin ash shock ring, fading to wisps (teal sparks) | 8 | 128 | `burst()` at each dive impact (`SeraphBehavior._impact()`) | done |
| `sovereigns_decree` | Sovereign's Decree cast (content wave 2): a bone crown of light flaring at the centre while a ring of chunky violet rune marks spreads outward, then the runes break into sparks (the hazy sheet had its alpha below 32 keyed out) | 10 | 256 | `UltimateSystem.cast()` ring (`DECREE_RING_TIME` 0.6 s) | done |
| `eclipse` | Eclipse cast (content wave 2): a black sun with a pale violet corona; the disc grows and swallows the corona while dark violet smoke rolls outward, ending as a thin crescent | 10 | 256 | `UltimateSystem.cast()` ring (`ECLIPSE_RING_TIME` 0.7 s) | done |
| `grave_tide` | Grave Tide cast (content wave 2): a ring of soul-teal fire rolling outward with bone skeletal hands breaking its front, thinning into teal wisps and bone specks | 10 | 256 | `UltimateSystem.cast()` ring (`TIDE_RING_TIME` 0.65 s) | done |

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


### Act I enemy AoE art (Covenant telegraphs, holy ground, Seraphine's hazards; Oct 2026)

GDD §15.0 "Act I enemy AoE art". The old rule "rings, telegraphs, zones and glows stay in code" is
**retired for these effects**. Every piece is **procedural pixel art** in the locked palette, made by
`python3 tools/covenant_aoe_art.py` (deterministic; `--review DIR` writes the 1× / ×4 / GIF review
images) and drawn by `CovenantFx` (`scripts/fx/covenant_fx.gd`; keys and numbers in
`scripts/data/covenant_fx_data.gd`), always with the code shape as the fallback. Rules of this family:

- **Crisp at any size:** nothing big is stretched. Band pieces are tiled at 1:1 along the exact danger
  edge (row 0 outside, turned along the edge); the hatch is a seamless 8 px tile laid as 2 px rows clipped
  to the shape (circle, cone) or one turned rect (lane); discs are baked at the radii the game uses and
  drawn at radius / baked radius (×1 for the shipped radii).
- **Readability:** the danger shape is the exact hit shape: a gold band with crimson teeth pointing into
  the danger on the edge, the hatch over the whole area, denser (with a tint) inside the part the timing
  has filled, a holy-white timing front, chevrons along a lane lit as the timing passes them.
- **Alpha:** telegraph pieces, stills and strips are fully opaque or transparent; translucent ground
  pieces (zones, chambers, seals, the scorch, smoke, fog, glow, columns) use 2-4 stepped alpha levels
  (`art_check.py` flags them on purpose). Grey masks (`structure_break`, the smoke banks, the soft disc)
  are tinted in the game.
- **Colour:** Covenant gold, light gold, holy white and crimson with warm ink; the cleansed chamber is the
  player's violet and soul green (his corruption); Seraphine's safe circles cold blue and ice.

| Key | Subject | Art px | Drawn by |
|---|---|---|---|
| `telegraphs/edge`, `edge_tooth` | Warning band piece (ink rim, 4 px gold band with a holy-white heart, dark crimson inner row) and the same with a crimson tooth into the danger (every other piece) | 10 × 6 / 10 × 10 | `CovenantFx.ring()` / `edge_run()` in every shared telegraph, the nova edge |
| `telegraphs/front` | Timing front (holy white in gold) | 8 × 3 | circle / cone at r × progress, across a lane; pillar and teleport rings |
| `telegraphs/hatch` | Seamless diagonal warning stripes | 8 × 8 | `hatch_disc()`, `hatch_sector()`, lanes |
| `telegraphs/chevron`, `target` | Lane direction chevron; impact point mark | 11 × 13, 13 × 13 | lanes, Seraphine's sweep arrows; warning circles ≥ 30 px |
| `holy/zone_62`, `_85`, `_105` | Holy zone rune circle: script ribbon, eight-point star, inner ring, ivory cross | 130-216 | `StageDirector._draw_zone()` (+ 8 turning `holy/glint`) |
| `holy/chamber_220` | Sanctified chamber: grouted gold / ivory mosaic rim with crimson tesserae, inlay star, diamond inlays, sun mosaic | 446 | `SanctumDirector._draw_chamber()` (+ 12 turning `holy/rune`, `holy/light_beam` rays) |
| `holy/cleansed_220` | Cleansed chamber: ragged violet rot stain, blotches, soul-green cracks | 446 | `_draw_cleansed()` |
| `holy/seal_160`, `_220` | Suppression seal: ivory script ribbon, dashed ring, studs, twelve-point star | 326 / 446 | `SanctumGlyphs.draw_suppression()` (+ 10 turning `holy/seal_cross`) |
| `holy/altar_48` | Altar sigil ribbon, dashed ring, four diamonds | 102 | `_draw_altar_sigil()` (+ 4 turning `holy/ray`) |
| `holy/glint`, `rune`, `seal_cross`, `ray` | Four-point star, mosaic diamond, gold cross, short ray | 7-10 | orbiting pieces, lash tip, pillar crown, sun ticks, Seraphine's halo |
| `holy/aura_dash`, `rally_edge`, `warn_line` | Dashed aura ring piece, crimson ring piece, dashed beam warning | 12 × 2, 8 × 3, 8 × 3 | Banner / Standard / Paladin reach, beam range; Call to Arms ring, zeal ring; beam warnings |
| `holy/light_beam`, `beam_core`, `beam_glow`, `beam_cap` | Thin light ray; great beam body (24 px), its stepped glow, its blazing head | 8 × 5, 16 × 24, 8 × 16, 32 × 32 | crystal rays, Sentinel blade; `CovenantFx.great_beam()` (Guardian, Seraphine) |
| `holy/light_column`, `sunburst`, `guardian_fist` | Light column (stretched), casting sunburst, the Guardian's raised stone fist | 24 × 64, 18, 16 × 15 | revival pillar, teleport mark; casters; slam windup |
| `overlays/holy_shield` | High Confessor's shield bubble | 40 | `SanctumGlyphs.draw_holy_shield()` scaled to r × 1.35 |
| `holy/wrath_halo` | Alaric's Wrath flame ring (r 35 = 1.6 × his radius) | 86 | `BossAlaric._draw_under()` |
| `holy/lash` | Sister's lash cord piece | 6 × 4 | `SisterGlyphs.draw_lash_windup()` |
| `holy/nova_wave`, `safe_62`, `safe_rim_62`, `safe_tick` | Nova pulse dash; safe circle ground (cold hole, pool, ice crosses), its icy rim, countdown piece | 12 × 3, 130, 142, 6 × 4 | `SeraphineHazards._draw()` / `_draw_overlay()` |
| `holy/collapse_edge`, `collapse_flame`, `collapse_scorch` | Burning edge piece; 6-frame flame tongue strip; burning ground with a 128 px hole | 12 × 6, 6 × (12 × 30), 512 | collapsing arena; Last Light aura |
| `holy/smoke_bank` (+ `_2`, `_3`) | Zone-change smoke (grey masks) | 120-176 | `MarchDirector._draw()` |
| `holy/dawn_shaft`, `holy/soft_disc` | Dawn's Wrath shaft; 512 px soft disc mask (smooth alpha, not pixel art) | 64 × 240, 512 | `_draw_dawn()`; `CovenantFx.soft_disc()` (every big translucent fill) |
| `decals/graveyard_fog` (+ `_2`, `_3`) | Wispy fog patch, stepped faint soul-green alphas | 112-144 wide | `Ground._draw_cell()` on the tile floor |
| `effects/boss_death` | Boss falls: holy flash, cross of rays, gold ring breaking into motes | 10 × 256 | `EnemyDirector.on_enemy_killed()` impact |
| `effects/vael_cleave`, `sentinel_sweep` | Crescent swing (holy flame; ivory gold), turned toward the swing | 6 × 128 | `EffectManager.slash(..., anim)` |
| `effects/structure_break` | Flash, splinters, dust ring (grey mask, tinted) | 8 × 128 | March structures, ward crystals, altars |

Review folder for the owner: `docs/art/act1_enemy_review/` (`manifest.json`).
### Player AoE art (`assets/sprites/aoe/`; Oct 2026)

Owner report: "quite a few placeholder graphics for some of the AoEs in act one" (audit:
`docs/art/audit/act1_shared.md` on `audit/act1-art`; GDD §15.0 "Player AoE art"). The old rule above
("rings, telegraphs, zones, glows stay in code") is **retired for the player side's ground effects**:
the spells' clouds and auras, the summon specials' wind-ups and impacts, the fire and shard patches,
the Rogue's lane, the evolution column, the ultimates' overlays. A ground area must show its real hit
radius at every size (levels and area passives grow it), so these are **not** stretched strips: they
are small **pieces drawn 1:1** on the art grid through the sharp-pixel shader and placed by
`AoeArt` (`scripts/fx/aoe_art.gd`, numbers in `AoeArtData`): ring pieces repeated along the rim and
turned outward (their +x points away from the centre, their outer edge on the radius, every other one
mirrored; the Undertow crest pattern), gas puffs scattered over the area and round its rim, centre
pieces in two or three sizes, lane tiles plus a head cap. Pieces are palette colours (each shape is
drawn in ramp levels and written once per colour ramp) with binary alpha; the game only fades them.
Each frame keeps a 1 px clear border (no neighbour-frame bleed under the shader). Lower visual tiers
space the pieces wider (`AoeArtData.TIER_DENSITY`); the soft area tints are the shared disc texture
(batched, no polygon). Every code drawing stays as the fallback. All drawn procedurally and
deterministically by `python3 tools/aoe_art.py` (no image generation, no cost);
`python3 tools/aoe_preview.py OUT [--code]` renders them composed at game size in the engine.
`art_check.py`: palette and alpha pass for all 59; height / feet do not apply (flat pieces); the
dark ones (scorch, Pestilence puffs, cracks, violet crests) are darker than the lightest Sanctum IV
floor by design (they are ground marks, drawn under the bodies).

| Piece(s) | Subject | Art px | Used by |
|---|---|---|---|
| `crest_stomp`, `crest_bone`, `crest_stone` | Heavy impact crest: big dust puffs rolling outward with flung rocks (earth / bone / gargoyle stone), 4 frames | 18 × 20 per frame | Abomination and Bone Colossus stomps; boulder landings, Colossus shrapnel; Gargoyle / Cathedral Horror dive |
| `crest_rubble` | Earth band and chunks, 4 frames | 14 × 16 | Corpse Explosion accent |
| `crest_frost` | Ice crystals growing outward, then shattering | 14 × 16 | Deep Freeze |
| `crest_wail`, `crest_wail_violet`, `crest_ivory` | Two sound-wave arcs thinning and breaking | 14 × 16 | Dirge waves, Keening Lady silence, Cathedral Horror stun |
| `crest_arcane` | Arcane band with four-point sparks | 14 × 16 | Mage / Lich splash |
| `crest_spore` | Moss spore puffs with teal highlights | 14 × 16 | Pestilence death nova |
| `crest_soul`, `crest_violet` | Flame wisps licking outward | 14 × 16 | soul / violet rings (summon transforms, evolutions, heals, Bastion, Echoing Dark, the Pestilence nova core and charge rim, the Grave Eruption accent) |
| `mark_bone`, `mark_ice`, `mark_wail`, `mark_violet`, `mark_soul` | Telegraph rim mark: a 3 px dial segment with an inward tick; frame 1 lit. The marks light up round the rim over the wind-up (no growing disc) | 8 × 14 | stomp, freeze, wail, dive and boulder wind-ups; the Grave Eruption edge |
| `puff_plague_0..2`, `puff_pest_0..2` | Gas puffs (one shaded mass, no outline: overlapping puffs never stack hard rims, which read as foliage) | 20 / 28 / 36 | Plague Cloud (42 %), Pestilence (55 %) |
| `bubble_plague`, `mote_soul`, `mote_plague` | Rising bubble, soul and plague motes (3 frames) | 7 | clouds, Wither / Blight drips |
| `rune_plague`, `rune_soul` | Thorny vine with an outward thorn and a rune mark / a drip (2 variants) | 10 × 16 | Wither, Necrotic Blight rim |
| `crack_0..2`, `crack_soul_0..2` | Zig-zag ground fissures (ink with a lit lip / a glowing soul seam) | 32 / 48 / 64 | stomp and boulder centres; Grave Eruption field |
| `frost_star`, `flash_arcane`, `flash_wail`, `flash_violet` | Centre flashes (3 frames) | 29 / 25 | Deep Freeze, splash, wail, dive |
| `flame_0..2`, `scorch_0`, `scorch_1` | Flame loop from a heat field (4 frames); scorch marks with a smouldering rim | 14 × 20; 28 / 60 | Hellhound fire patches, Ossuary shard fields |
| `spike_0`, `spike_1` | Bone spikes growing out of the ground row by row | 11 × 18, 13 × 23 | Grave Eruption, Ossuary shard fields |
| `lane_body`, `lane_head`, `dash_streak` | Dashed lane tile with a chevron (frame 1 charged), arrowhead, dash smear | 8 × 24, 30 × 12 | Rogue / Shadow Reaper dash |
| `transform_column` | Soul light column with rising violet runes (4 frames) | 26 × 64 | summon evolving in place |
| `black_sun`, `halo_0..2`, `tide_edge` | Black sun; crown-point taunt halos; edge-mist tile (2 frames) | 50; 30 / 42 / 58; 24 × 40 | Eclipse, Sovereign's Decree, Grave Tide overlays |
| `bolt_violet`, `bolt_soul_glow` | Soul lightning segment stretched along each hop; the Damned's green under-glow | 16 × 9, 16 × 13 | Soul Chains |
| `eclipse_band` | Dark barrier band with soul runes (2 variants) | 12 × 14 | Eclipse Ward |
| `chill_film`, `dirge_veil` | Ice crust over a chilled body; Dirge veil and tears (frame 1 with the silence halo), scaled to the body | 32; 32 × 42 | Frost Wraith chill, Banshee Dirge |

Also in this pass (no new art): Dread Rally's second ring and vortex, the new ultimates' second ring,
the Winter Revenant's and Doom Brand's second rings show only without their strips (`ring_under`);
the hard-recall and Death Knight spawn rings play `summon_rise`. Left as they were: Shadow Blast,
the Soul Nova, the Grave Step puff, the Bone Wall and Raise Dead strips (approved art); the Soul
Siphon / Rapture tethers (a beam, its drained-life magenta has no palette ramp), the orbit and charge
arcs (progress arcs), the temporary-summon aura. Review: `docs/art/act1_player_review/`.

### Gullhaven Harbour (Act II, Stage 4; Oct 2026)

Every Gullhaven asset (GDD §15.0 "Gullhaven Harbour (Act II phase 2)"), generated through
`tools/gen_image.py` (the ledger in the main checkout) with enlarged approved sprites attached
as style references (the Warrior and the Halberdier for soldiers, the Wither Witch and the Sister
of the Scourge for the figure-redesign women, Vael and the Cathedral Guardian for the big ones, the
fountain / barricade obstacles for the props, the Grim Ledger badge for the icons). The Ancient
Eye's units use the `eye` ramp set (drowned teal, biolume, bone, grey, brown, skin, moss); the
bosses and props were converted with `--ramps` of the same set. Prompts and contact sheets were
kept outside the repository; the sources are in `art_source/`.

| File | Subject | Art px | Notes |
|---|---|---|---|
| `eye/deep_kin.png` (+ `_walk`) | Deep Kin: a hunched, scaled fisherman halfway into the sea, a spiny fin ridge, one magenta eye, ragged oilskin trousers | 56 | walk rig: legs, the long arms rigid |
| `eye/tide_caller.png` (+ `_walk`, `_idle`) | Tide Caller: a fishwife priestess in the figure-redesign style (fitted drowned-teal oilskin gown, kelp shawl, bone cowl), a conch-topped staff | 54 | `pixelate_source.py` then `--ink-l 0.15 --no-cleanup`; glide strip and idle breathing with a 2 px bust bounce |
| `eye/netcaster.png` (+ `_walk`) | Netcaster: a hooded net-mender, a weighted net over one arm, a gaff hook | 50 | walk rig: legs, the gaff rigid |
| `eye/deep_herald.png` | Herald of the Deep (the Harbour's Reckoning kind): coral-horned, shell-plated sea horror, redrawn after the owner's review with fewer, bigger details (three horns, three eyes, three shell plates, broad kelp strips) | 64 | still only (54 wide) |
| `eye/harbourmaster.png` | the Harbourmaster miniboss: a hulking Deep Kin in a peaked cap and torn oilskin, a giant anchor on a chain; after the owner's review a Deep Kin fish head (wide fish mouth, needle teeth, gills, one huge eye) | 124 | still only (132 wide) |
| `bosses/merrow.png` | Abbot Silas Merrow before The Change: an ordinary elderly human priest (owner's review: "more human, so the change is horrific"): human face and hands, grey beard, drowned-teal cassock, bone stole with the Eye, tall mitre, only barnacles on the hem; pixelated first (`pixelate_source.py`), `--no-prune` keeps the small skin ramp | 130 | 56 wide |
| `bosses/merrow_sermon.png` | pose 1: the same human Merrow preaching, both arms raised, the Eye sigil above | 150 | `BossPoseData`; made like the still |
| `bosses/merrow_changed.png` | after The Change: a gaunt scaled horror, frill crown, four long spotted tentacle limbs | 136 | 160 wide |
| `bosses/merrow_changed_strike.png` | pose 3 of the changed form: lunging, the limbs lashing forward | 120 | `BossPoseData` |
| `structures/bell_buoy.png` | a bell buoy: a weathered float with the Eye painted on it, an open frame of four iron struts and a bell hanging free inside it (owner's review: room to swing) | 64 | |
| `structures/smuggler_cache.png` | an iron-bound, padlocked crate with rope and bottles | 40 | |
| `player/brine_widow.png` (+ `_walk`, `_idle`) | The Brine Widow (Undertow's character): figure-redesign style, a fitted violet mourning gown, an icy-blue veil under a shell crown, a hooked driftwood staff curling with water | 58 | `pixelate_source.py` then `--ink-l 0.15 --no-cleanup`; glide strip and idle with a 2 px bust bounce |
| `tiles/harbour_mudflats.png` | wet sand ripples | 128 | `make_tile.py` quilt, new source; mean L 0.26 |
| `tiles/harbour_market.png` | wet market cobbles | 128 | `make_tile.py` voronoi layout on the fortress source; mean L 0.27 |
| `tiles/harbour_chapel.png` | the village chapel's old hardwood floor (owner's review; was slimed flagstones) | 128 | 8 px plank courses on `harbour_chapel_wood.png`; mean L 0.26 |
| `tiles/harbour_seawall.png` | the promenade's long paving stones | 128 | courses layout on the courtyard source; mean L 0.29 |
| `obstacles/mooring_post_s/_l` | a roped mooring post | 22x39 / 28x50 | circle r 9 / 12 |
| `obstacles/wreck_ribs_s/_l` | a wrecked boat's ribs and keel | 50x44 / 64x55 | r 24 / 30 |
| `obstacles/net_pile_s/_l` | a heap of net: a diamond rope mesh with see-through holes, a scalloped hem, cork floats and a glass float | 30x23 / 38x29 | r 14 / 18; drawn by `tools/mesh_props.py` (owner's review: AI mesh read as sand) |
| `obstacles/fish_stall_s/_m/_l` | a round stall heaped with fish under a striped awning | 44x56 / 52x67 / 60x78 | r 20 / 24 / 28 |
| `obstacles/barrel_stack_s/_l` | three fish barrels | 26x28 / 34x35 | r 12 / 15 |
| `obstacles/crate_stack_s/_l` | fish crates | 32x29 / 38x35 | r 14 / 17 |
| `obstacles/drowned_idol_s/_l` | a barnacled idol of the Eye in a basin | 36x41 / 44x50 | r 16 / 20 |
| `obstacles/coral_pillar_s/_l` | a coral-grown pillar in a basin | 30x34 / 36x41 | r 13 / 16 |
| `obstacles/tide_font_s/_l` | the cult's holy-water font | 44x46 / 52x55 | r 20 / 24 |
| `obstacles/bollard_s/_l` | an iron bollard | 20x22 / 24x27 | r 8 / 10 |
| `obstacles/anchor_monument_s/_l` | an anchor set in a stone base | 44x50 / 52x59 | r 20 / 24 |
| `obstacles/lobster_pots_s/_l` | three stacked lobster traps: rope-grid cages on wooden hoops and base boards | 26x20 / 32x25 | r 12 / 15; drawn by `tools/mesh_props.py` (owner's review: AI cages read as chests) |
| `icons/undertow.png` | a breaking wave (violet badge) | 32 | symbol at 26 px composited on the badge cut from `grim_ledger` |
| `icons/maelstrom.png` | a whirlpool (gold evolution badge) | 32 | |
| `icons/salt_of_the_deep.png` | salt crystals and a violet spark (violet badge) | 32 | |
| `icons/brinewalker.png` | a boot on a wave (violet badge) | 32 | |
| `icons/ach_low_tide.png` | a crescent moon over calm water with an anchor (gold achievement badge) | 32 | |
| `effects/tide_splash.png` | a splash of sea water spreading into a foam ring (6 frames) | 128 frames | `--anim --grid 3x2`; `AnimData` "tide_splash" (0.4 s, the `impact()` duration): Deep Kin landings, the Harbourmaster's anchor, Merrow's wave and whirl, a buoy sinking |

The water itself is not art: `scripts/fx/tide_water.gdshader` draws it (flat teal bands on a 2 px
grid, the foam line, sparse glints, the seawall lip and the surge telegraph).

**Harbour placeholder art pass** (Oct 2026, owner report "quite a bit of placeholder art" on
Gullhaven; GDD §15.0 "Harbour placeholder art pass"). Found with the art audit (`--art-misses`
in a window, `ArtMissLog`) and by reading the harbour's `_draw()` code; keys and placement in
`MarkerArtData` "Gullhaven Harbour", sizes in `SpriteData`; every code drawing stays the fallback.

| File | Subject | Art px | Notes |
|---|---|---|---|
| `eye/eye_initiate.png` (+ `_walk`) | Initiate of the Eye (Act II fodder, every Act II stage): a hunched cultist in a ragged drowned-teal hood with the Eye's magenta sigil, the hood pulled over the eyes (owner's review, round 2: "just show his mouth"), only the gaunt mouth showing, a rusty gutting knife | 46 | the most drawn sprite of every Act II run, was the code cultist; AI source, `pixelate_source.py`, the hood brim, mouth and sigil pupil hand-placed; walk rig: legs |
| `eye/eye_chanter.png` (+ `_walk`) | Chanter of the Eye (squad leader, claims the dead): a bone-white stole with the Eye, a shell necklace, the mouth open in a chant, a tall driftwood staff topped by a bone ring holding a glowing eye | 64 | was the code cultist with a staff; face and staff eye hand-placed; walk rig: robe, staff rigid |
| `eye/deep_herald_walk.png`, `eye/harbourmaster_walk.png` | walk strips of the two stills (legs step, the claws ride with the body; the anchor swings like a pendulum from his fist, owner's review round 2) | 64 / 124 | `walk_cycle.py` rigs (the new `swing` key: a row-by-row shear from the pivot row) |
| `structures/merrow_pulpit.png` | Abbot Merrow's driftwood pulpit (drowned book, shell string, the Eye carved and glowing), in front of him while he preaches | 42 × 40 | AI source, `--ramps brown,bone,drowned,biolume`; eye recoloured to `biolume` |
| `structures/harbour_pier.png` | a smugglers' dry pier: cross planks between side beams, nails, two worn gaps, wet boards at the sea end, pilings | 152 × 40 | drawn on the grid by `tools/harbour_props.py`; turned along the pier |
| `projectiles/harbour_anchor.png` | the Harbourmaster's anchor, raised in the wind-ups and hurled on its chain | 24 × 28 | AI source |
| `projectiles/anchor_chain_link.png` | one rusted link of the anchor chain | 7 × 5 | `harbour_props.py`; every other link tilted |
| `overlays/harbour_net.png` | the Netcaster's weighted net (diamond rope mesh, rim rope, lead weights) | 33 × 33 | `harbour_props.py` (a mesh is drawn on the grid); `art_check` flags its 1 px ropes by design |
| `overlays/tide_wall.png` | the Tide Caller's line of rising sea water, foam crest and spray | 152 × 28 | AI source, no outline; rises row by row with the crest |
| `overlays/undertow_crest.png` | one foam crest of the Undertow wave, repeated along its 120° arc | 10 × 14 | `harbour_props.py` |
| `overlays/maelstrom_whirl.png` | a Maelstrom whirlpool from above: foam arms spiralling into a violet heart | 92 × 96 | AI source, no outline; turns as it spins, sized to the grind radius |
| (shallows) | the Undertow shallows: the code's soft pool (now the shared disc texture) inside a rim of `undertow_crest` foam crests | — | an AI pool sprite (`overlays/undertow_shallows`, 124 × 128) was tried and dropped: scaled up at 55% it read as coarse grey blocks in play |
| `decals/harbour_*` (20) | the floor decorations: shells, kelp (Mudflats); fish scales, rope coils, a dropped fish (Market); coral crust, barnacles, the Eye's carved sigil (Chapel); mooring ring, rusted chain, gull feather (Seawall); most with a variant | 5-25 | two AI sheets (`art_source/decals/sheets/harbour_shore`, `harbour_chapel`) through `make_decals.py` recipes; the tide puddles stay code (soft translucent pools) |
### Act II: the Hollow Archive (Stage 5; Oct 2026)

Made in one pass through the usual pipeline (`gen_image.py` with enlarged anchors attached,
`prepare_sprite.py`, `walk_cycle.py`, `make_tile.py`); the Ancient Eye's units use the `eye` ramp
set (drowned teal, bone, biolume magenta, grey, brown, moss); the boss, the lectern, the rift and
the orrery use it too (`--ramps bone,drowned,biolume,grey,brown[,gold]`). Small props, icons and
pages were generated as sheets of separate sprites, cut apart at their empty columns and converted
one by one to their exact sizes. None of the Archive's characters is female, so none needs the
figure-redesign rig.

| File | Subject | Art px | Status |
|---|---|---|---|
| `eye/scribe.png` | Scribe of the Unwritten: a hooded drowned-teal cultist with ONE HUGE EYE for a head inside the hood (owner's review, round 2: "his face looks messed up"), an open book held out, a raised quill. Walk strip (robe shuffle); pixelated first, `--no-prune` | 48 | done |
| `eye/ink_wraith.png` | Ink Wraith: a floating hooded ghost of blue-black ink, reaching claws, a dripping tail. Glide strip | 44 | done |
| `eye/spore_pilgrim.png` | Pilgrim of the Spore: a tattered teal-and-brown pilgrim, mushroom-capped staff, moss spore sacs. Walk strip (staff rigid) | 50 | done |
| `eye/gibbering_mass.png`, `_lesser`, `_least` | Gibbering Mass: a lumpy teal mound of eyes and mouths; the two splits are the same source at 44 and 32 | 60 / 44 / 32 | done |
| `eye/librarian.png` | The Librarian (miniboss): a giant floating eyeball wrapped in hanging teal tentacles, torn pages caught in them | 110 | done |
| `eye/unwritten_one.png` | The Unwritten (the Archive's Reckoning): a gaunt horror wrapped in blank parchment, one magenta slit | 60 | done |
| `bosses/archivist.png` + `_cast`, `_split`, `_strike` | The Archivist: a tall robed figure whose head is an open book, a parchment stole, a chained tome and a quill staff; poses: Recitation (both raised, pages flying), Footnotes (arms wide, pages fanned), the tome slammed forward (BossPoseData). Footnote copies draw the still pale and without its shadow | 130 / 152 / 134 / 124 | done |
| `player/heretic_scribe.png` | The Heretic Scribe: a hooded violet scholar with a tall violet quill-staff and a written scroll. Walk strip; his Hyper skin uses the tint fallback | 60 | done |
| `structures/forbidden_lectern.png`, `structures/archive_rift.png` | A chained open tome with a magenta eye sigil on a carved lectern; a vertical tear of magenta light | 52 / 64 | done |
| `structures/orrery_hub.png`, `obstacles/orrery_arm.png`, `obstacles/orrery_planet.png` | The orrery from above: a brass hub, a 62 px brass arm tile repeated along each arm, a teal planet on its tip (flat sprites) | 75 / 62 / 24 | done |
| `obstacles/bookshelf_*`, `reading_desk_*`, `toppled_shelf_*`, `book_pile_*`, `brass_globe_*`, `chart_table_*`, `blank_shelf_*`, `page_heap_*` | The zones' obstacles (every rect horizontal: the stage layouts' `orient` "h", so no `_v`) | footprint + height | done |
| `tiles/archive_halls.png`, `archive_wells.png`, `archive_orrery.png`, `archive_stacks.png` | Zone floors: dark parquet (layout courses), black marble with ink (quilt), dark observatory stone, pale worn stone (no variants) | 128 | done |
| `decals/ink_pool.png`, `decals/ink_well.png` | An ink blot from above (flat, scaled to the pool's radius; the well reuses it) | 64 | done |
| `projectiles/archive_page.png`, `verse_page.png`, `unwritten_page.png` | A Recitation page; Forbidden Verse's violet page; the gilded page of The Unwritten Word | 12 / 13 / 14 | done |
| `icons/forbidden_verse.png`, `unwritten_word.png`, `marginalia.png`, `iron_mind.png`, `ach_nothing_unwritten.png` | Spell, evolution, passives and achievement badges | 32 | done |
| `effects/spore_cloud.png`, `effects/ink_burst.png` (`--anim`) | A billowing spore cloud (drawn by ArchiveHazards); the ink burst of an inscribed death (AnimData "ink_burst") | 6 x 128 | done |

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

### Epilogue panels (`assets/sprites/epilogue/`; content wave 2)

**Status:** in the game (Oct 2026), waiting for the owner's art review. The illustrated campaign
epilogue (`EpilogueScreen`, data in `scripts/data/epilogue_data.gd`, GDD §15.0 "Illustrated
epilogue (content wave 2)") shows one picture panel per paragraph and a closing card, each panning
slowly in a 944×424 window. Panels are whole opaque scenes, **1024×576 art px** (16:9), drawn
1 art px = 1 layout px through the sharp-pixel shader like the menu diorama (loaded through
`EnvironmentArt.texture()`, so they need no `SpriteData.HEIGHTS` entry).

| File | Paragraph / scene | Made by | Notes |
|---|---|---|---|
| `act1_1` | Act I ¶1: the Sanctum burns, the relic shattered | AI source, converted | white-gold cathedral in flat flames, smoke; the broken gold sun relic on the floor; the necromancer and three skeletons watching from the left |
| `act1_2` | Act I ¶2: the dawn goes out, the dead walk the pilgrim roads | AI source, converted | a dark crimson-ringed sun sinking, shuttered village, toppled sun shrine, a long column of undead down the winding road |
| `act1_3` | Act I ¶3: the army drifts toward the coast | AI source, converted | cliff path to the shore, the necromancer on the cliff edge, a teal and violet eye-glow under the black sea, moon |
| `act2_1` | Act II ¶1: the tide pulls back from Gullhaven | AI source, converted | drained mudflats, stranded boats and chains, the harbour town and chapel, the Eye's faithful praying on the pier, a wall of water and a vast eye on the horizon |
| `act2_2` | Act II ¶2: the Archive's last page burns | AI source, converted | towering shelves and the brass orrery, the giant book on a lectern in violet / soul-teal fire, the Archivist kneeling, the necromancer's raised hand |
| `act2_3` | Act II ¶3: Ul-Thalos sinks | AI source, converted | the drowned spire city tilting into foam rings under a full moon, abyssal violet windows; the necromancer and two skeletons on the rocks |
| `act2_4` | Act II ¶4: Vhal'Neth kneels | AI source (three edits of the first one; round 3: plunging neckline with cleavage, pushed hourglass, rim light, left side brightened), converted | the goddess bowing on the shore, bone hands on the sand; the army with bone banners and the necromancer raising his staff. **Wave 2 art review redo** (owner: "more undead looking and hotter"): a drowned dead goddess (dead blue-grey skin, rotted cheek, glowing violet eyes, skeletal forearms and hands, ribs through a tear in her gown, barnacled coral, frayed tentacles) in the figure-redesign style (hourglass figure, fully covered by a high-necked kelp gown); converted with 64 clusters and flame / crimson dropped (`PANEL_OPTS`) so the gown stays flat shades |
| `act3_1` | Act III ¶1: the Empire's citizens rebuilt in steel | AI source, converted (Act III epilogue, Oct 2026) | a chrome city avenue under hard amber window lights and red beacons, cyborg citizens with amber visors walking toward the viewer, a rebuilding cradle on the right fitting a body with chrome limbs (amber sparks), Deus Ex Machina and a drone far down the avenue; no undead |
| `act3_2` | Act III ¶2: the god they built falls to its knees | AI source, converted | the Core's dark chrome chamber with red alarm lights; Deus Ex Machina (its sprite's red plates, rotary guns, rocket pod) kneeling, chest cracked open on Varn's soul-teal face; the violet necromancer standing on its fallen gun arm and reaching in, a skeleton warrior and archer behind him |
| `act3_3` | Act III ¶3: the machines go dark, Varn rises to serve | AI source (second try: the first was too murky to read), converted | a steel parade ground in soul-teal light; ranks of switched-off troopers with black visors and bowed heads, some fallen; Varn (grey hair, chrome coat, cables, teal soul in his chest) kneeling to the necromancer's raised hand, two skeleton archers behind. The mech in the background and a few city windows still glow (open for the owner's review) |
| `act3_4` | Act III ¶4: the dead are the only empire left | AI source, converted. **Round 4 redo** (owner: "the main character's head looks weird"; then: "in game his face is just the two glowing purple dots in the darkness, make it closer to the game sprite"): `tools/epilogue_face.py` paints the hood opening of the AI source (kept unpainted in `art_source/epilogue/raw/act3_4.png`) black and puts in two violet eyes (#A35CFA, #DDBDFF core) by hand, like `player/necromancer.png`; every other pixel is the approved source. A first try (an AI edit giving him a skull face, about $0.03 in the ledger) was dropped as too far from the sprite | under a violet dusk and a red sun: the burnt ivory-and-gold cathedral, the Eye's toppled spire with its stone eye, a fallen chrome tower and mech; the army of the dead (warriors, archers, a bone golem, a raised drone, sun-banners taken as trophies) marching toward the viewer around the necromancer |
| `close` | Closing card: "The Beacons Burn": the holy orders' knights marching out of the gate under the beacon fires | AI source, converted. **Act III art review round 4** (owner): the old knights card is kept (the Empire redo is only a spare source, `art_source/epilogue/close_empire.png`), and the right knight's blue star is repainted gold by hand on the converted PNG (527 px, then 37 blue edge specks in round 5; redo it after any rebuild from the source). |
| `close_act3` | Closing card after Act III: "The River Runs Dry": a dried river of the dead far below, an empty ferry and a lone lantern, the gods watching from a marble mountain | AI source (Act IV audio / story phase, Oct 2026; one generation, 1536x1024, one reference panel for the pixel style), converted with `epilogue_panel.py` (`PANEL_OPTS`: `y_bias` 0.12 keeps the gods on the peak, skin and ice dropped) | the cavern mouth frames a golden sky over a white marble mountain and temple with the dark silhouettes of crowned gods (a bolt, a trident); below, grey cracked mud, the beached ferry, a lantern on a pole, a trail of footprints leading away, bones and a mooring post. No necromancer, no living figures: it names Act IV's gods without showing one. The converter turns the silhouettes brown (the palette's nearest) |
| `act4_1` | Act IV ¶1: the army fills the emptied Underworld | AI source (Act IV epilogue, Oct 2026; one generation, 1536x1024, refs: the `act3_3` panel and the necromancer sprite), converted (default drops) | grey asphodel fields under an ash sky, the dry cracked bed of the Styx winding through, ranks of skeletons with teal eyes shrinking to the horizon, the necromancer from behind at the left, empty marble gate pillars far away |
| `act4_2` | Act IV ¶2: the gods descend against the undead | AI source, converted | Olympian gods (a bolt, a trident, a bow) falling from a golden break in the clouds over a sea horizon; the skeleton line below with the necromancer at its centre, broken legion shields |
| `act4_3` | Act IV ¶3: Hades kneels with his crown | AI source, converted | the Underworld hall with a black throne and teal braziers; Hades in violet robes kneeling with his bident, offering the gold crown to the necromancer, two skeletons behind him |
| `act4_4` | Act IV ¶4: Olympus silent, the dead below | AI source, converted | the dusk marble palace with empty thrones, a toppled statue and cold braziers; a teal river from the Underworld and the army gathered at the foot of the stairs, the necromancer looking up |
| `close_act4` | Closing card after Act IV: "The Sun Still Rises" | AI source (one generation, ref: `close_act3`), converted (default drops) | a huge red sun rising over a dark sea behind a red torii in the water, a goddess's two gold eyes opening in the clouds above it; in the dim foreground the fallen marble of Olympus and an empty throne with a crown on its steps. No necromancer, nothing of the Shogunate shown clearly |

**How they are made.** `art_source/epilogue/<id>.png` (1536×1024, `tools/gen_image.py`, prompt in
`<id>.txt`: a shared style block plus the scene; references were sheets of the game's sprites ×5,
the necromancer, skeletons, the stage boss of the scene, and floor tiles of the act's stages) are
converted by `python3 tools/epilogue_panel.py <source> <id>` (`--all` rebuilds every panel exactly):
composited over ink_cold, cropped to 16:9 (`y_bias` per panel), a 3×3 mode filter merges the AI's
colour noise inside its blocks, a box downscale (1.5 source px per art px: the AI's 4-5 px blocks
become ~3 art px, so shapes stay 2+ art px), then 128 median-cut / k-means colour clusters, each
snapped (OKLab nearest) to the locked palette (floor colours included as the scene's dark grounds;
ramps dropped per panel in the tool's `PANEL_OPTS`, e.g. skin and ice everywhere, violet on the
closing card), and a lone-pixel cleanup (a pixel sharing its colour with at most one neighbour takes
the majority of 4+). Clustering first keeps a wall one or two shades instead of a scatter of
near-equal hues (the owner's "no busy specks" note); no outline is added, the sources have them.

### Act II: Ul-Thalos, the Risen Spire (Stage 6; Oct 2026)

Generated with `tools/gen_image.py` (prompts in the ART_BIBLE template; the anchors and the nearest
approved sprites as `--ref`), converted with `prepare_sprite.py` (the `eye/` folder ramps for the
Ancient Eye; `--ramps bone,drowned,biolume,moss` for Vhal'Neth; the summons and player sets for the
bound undead and the Tide Widow, both heroines at `--ink-l 0.20` so their figures do not sink into
the outline ink). Walk / glide strips by `walk_cycle.py` (rigs under `# --- Act II: Ul-Thalos ---`),
idle breathing strips for the two bust rigs. All **done**.

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `eye/eye_siren` | Siren of the Eye: an alluring sea priestess (figure redesign, fully clothed), kelp hair streaming back, one hand at her lips, a kelp hem instead of feet | 36x56 | robe glide + bust bounce (`_walk`), idle breathing (`_idle`) |
| `eye/eye_spawn` | Spawn of the Deep (the Eye's): a barnacled tentacled heavy, one biolume eye | 68x66 | robe sway (`_walk`) |
| `eye/eye_hierophant` | Hierophant of the Eye: a tall eye mitre, barnacled bone plates, a ringed driftwood staff | 38x64 | robe sway, staff rigid |
| `eye/eye_waking_horror` | Dreamspawn of the Waking (the Reckoning kind): a gaunt drowned figure with a head of eyes and long claws | 62x70 | legs walk |
| `eye/dream_pillar` | Dream pillar: a slanted cyclopean obelisk with a glowing eye glyph | 88 tall | structure, no strip |
| `eye/vhalneth_arm` | One of Vhal'Neth's arms: a tentacle rising from a ring of foam, biolume suckers | 124 tall | no strip |
| `bosses/vhalneth` | Vhal'Neth, the Dreaming Mother: her face, neck and shoulders above the sea, tendril hair, coral circlet, eyes open (Stirring) | 150 tall | `_dreaming` (eyes shut, 148x150) and `_waking` (roaring, two arms, 156x156) made with the face as reference |
| `summons/spawn_of_the_deep` | The bound Spawn of the Deep (summon class): grey-bone shell, shackled tentacles, a soul-fire eye | 64x60 | robe sway |
| `summons/leviathan` | Leviathan (its evolution): a spiked bone-crowned shell, eight tentacles, two soul-fire eyes | 76x76 | robe sway |
| `summons/drowned_thrall_ally` | Drowned Thrall raised by Call of the Drowned: a hunched sea-soaked corpse in grey with seaweed | 36x44 | legs walk; Tidecaller's Host's Spawns use the class sprite tinted (`SpireGlyphs.HOST_TINT`) |
| `player/tide_widow` | The Tide Widow (figure redesign, fully clothed): violet gown with a slit, seaweed shawl, widow's veil, coral crown, conch staff | 44x56 | robe walk (staff rigid) + bust, idle breathing |
| `player/tide_widow_hyper` | Gilded Tide Widow (Hyper skin): the same with gold coral, gold trim and bangles | 44x58 | walk + idle through `SKINS`; `SKIN_FIX` bust box rows 17-25, cols 19-32, two lobes (owner's review: both sides bounce) |
| `tiles/spire_breakwater` (+ `_2`, `_3`) | Zone I floor: wet green drowned flagstones, slime, tide pools | 128 | `make_tile.py` quilt; the API sources came back with alpha, flattened to RGB |
| `tiles/spire_steps` (+ `_2`, `_3`) | Zone II floor: one wet green-grey stone, slime streaks | 128 | quilt |
| `tiles/spire_gate` (+ `_2`, `_3`) | Zone III floor: dark basalt with thin biolume veins | 128 | quilt, `biolume_dark` kept as accents |
| `tiles/spire_spire` | Zone IV floor: smooth dark stone at the spire's foot | 128 | quilt, no variants |
| `tiles/spire_water` | The sea around the island (`SinkingDirector`) | 128 | quilt by shares (ink / drowned_dark / drowned 30 / 66 / 4%) |
| `obstacles/cyclopean_block_{s,m,l}` (+ `_v`) | A slab of wet green cyclopean stone at wrong angles, barnacles at its base | 60x42 / 72x52 / 92x65; `_v` 36 wide | footprint + 2 wide |
| `obstacles/barnacle_pillar_{s,m,l}` | A broken barnacled column | 28x52 / 32x62 / 40x79 | |
| `obstacles/fallen_idol_{s,l}` (+ `_v`) | A fallen idol with a closed-eye relief | 46x26 / 56x32; `_v` 28 wide | |
| `obstacles/step_ruin_{s,m,l}` (+ `_v`) | A broken flight of sunken steps | 64x52 / 84x66 / 96x77; `_v` 28 wide | |
| `obstacles/sunken_idol_{s,l}` | A squat sea-god idol with one closed eye | 42x52 / 50x62 | |
| `obstacles/gate_pylon_{s,m,l}` | A leaning basalt pylon with a biolume eye glyph | 32x58 / 36x70 / 44x83 | |
| `obstacles/toppled_arch_{s,l}` | A toppled arch segment with a small glyph | 64x29 / 76x36 | no `_v` (the portrait source read as a tower: the vertical one keeps its code glyph) |
| `obstacles/spire_shard_{s,l}` | A jagged shard of the spire thrust up at a slant | 24x41 / 32x52 | |
| `icons/call_of_the_drowned`, `abyssal_pact`, `crushing_depths`, `spawn_of_the_deep` | Badges (violet border): tendrils from a whirlpool; a skull in a soul ring; a tentacle crushing a shield; the bound Spawn's head | 32 | symbols 26 px on the cut-corner template |
| `icons/tidecallers_host`, `leviathan`, `ach_the_dead_god_serves` | Gold-border badges: the evolutions and the achievement (the goddess's face under a violet chain) | 32 | |
| `effects/vhalneth_slam` | An arm crashing down: a ring of dark sea spray and foam | 8 x 192 | `ArmKit` impact |
| `effects/drowned_tendrils` | Call of the Drowned: tendrils lashing up out of a whirlpool | 8 x 128 | eruption ring |
| `effects/vhalneth_gaze` | Her gaze opening on the ground: a biolume eye of light | 8 x 256 | gaze telegraph ring (1.4 s) |

Code-drawn on purpose: the floor decals (`decals/spire_<style>_<name>`: barnacles, kelp, glyphs,
bones; soft and sparse, they read well drawn), the sea's flood band, foam and telegraph ring, the
Ascension pillar, the slam lanes, the gaze and roar rings and the binding finale.

### Content wave 2: the Bone Golem (Oct 2026)

Generated with `tools/gen_image.py` (the template above; `--ref` the Warrior, the Corpse Abomination
and the Bone Colossus for the Golem, the Golem's own source and the Colossus for the Titan, the Shadow
Bolt and Bone Colossus badges for the symbols). The API sources come back on a soft dark glow: every
alpha below 230 was dropped first (the Fallen Seraph's "deglow"), and the skulls' eye sockets, thinner
than one art px, were grown 6 source px before the conversion so the battlements keep their faces.
Stills converted with `prepare_sprite.py --art-height <h> --no-cleanup` (summon ramps), walk strips by
`walk_cycle.py` (rigs under `# --- Content wave 2: Bone Golem ---`: two stumping legs, both low fists
rigid). Badges: the symbol converted to fit 26 px (`--no-center --no-prune --no-levels --no-cleanup`)
and composited on the cut-corner template cut from an approved badge (violet border; gold for the
evolution). The Ossuary Hunger growth is a sprite scale in the engine (`UnitMotion.set_size()`, up to
x1.25), no extra art. Not a female character (no bust rig, no idle strip). **For the owner's review.**
7 images, about $0.11.

**Wave 2 art review redo (Oct 2026).** The owner asked for bigger details: the Golem's torso became one
huge skull, the Titan followed, the class badge's skull fills the frame, and the slam's crater no longer
drifts. Sources by `tools/gen_image.py` (Golem: `--ref` the old Golem and the Bone Colossus; Titan: the new
Golem's source and the old Titan; symbol: the new Golem and an approved badge), deglowed (alpha < 230
dropped) and converted with `prepare_sprite.py --art-height <h>` (summon ramps, cleanup on); the badges were
then hand-pixelled on the palette. 3 images, about $0.10.

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `summons/bone_golem` | Bone Golem (summon class), **redone after the wave 2 art review** (owner: "make his torso a huge skull"): the whole torso is one huge bone skull (no separate head), enormous eye sockets with teal soul flames, the jaw at the belly with teal fire between the teeth, arms of stacked bones bound with brown grave dirt ending in huge low fists of bone and grey stone, two stumpy stacked-bone legs | 84x80 | legs walk (`_walk`, rig re-cut: hip 60, the fists rigid boxes over the leg tops) |
| `summons/ossuary_titan` | Ossuary Titan (its evolution), **redone with the Golem**: the same huge-skull torso grown grander, a crown of five bone spikes on the cranium, cracked grey gravestone pauldrons, heavier stacked-bone arms and colossal fists, pillar legs | 108x104 | legs walk (`_walk`, rig hip 80); the tallest summon (Bone Colossus 100) |
| `icons/bone_golem` | Badge (violet border), **redone** (owner: "make the skull bigger"): the Golem's huge skull filling the badge (26 px wide), teal flames in the sockets, a teal glow between the teeth, the tops of both fists at its lower corners | 32 | hand-pixelled on the palette from the AI symbol (`art_source/icons/bone_golem.png`): at 26 px the conversion lost the sockets' dark rims |
| `icons/ossuary_titan` | Gold-border badge, **redone to match the new Titan**: the Golem badge's skull under a crown of three bone spikes, gravestone pauldrons at its sides | 32 | hand-pixelled from the Golem badge (28 rows) |
| `icons/grave_masonry` | Badge (violet border): a wall of stacked bone bricks with a skull keystone | 32 | |
| `icons/syn_bone_bastion` | Synergy badge Bone Bastion (violet border): a squat ring wall of stacked bone blocks with a skull keystone, teal soul fire sheltered inside (replaced the Charnel House fist, owner decision) | 32 | HUD list at 22 px |
| `effects/golem_slam` | A Golem slam: an impact flash, then a ring of cracked grave dirt with bone shards flying out, settling | 8 x 128 | `GolemBehavior` slam ring (0.3 s). **Wave 2 art review fix** (owner: the crater moved about 3 frames in): every frame shifted by whole px so the crater's centre sits on the frame centre, the slam point (`AnimBursts` draws centred); shifts (dx, dy) per frame (-2,-10) (5,-8) (3,-9) (1,-9) (0,15) (-2,15) (-1,13) (-1,13), applied after `prepare_sprite.py --anim` (a reconversion must reapply them) |

Code-drawn on purpose: the Bulwark's ring of bone stakes around a planted Golem and its faint taunt
reach (`GolemGlyphs.draw_bulwark_stakes()`), the absorb beam and the Titan's collapse wall (the Bone
Wall spell's own segments).

### Act III: the Electronic Empire, the shared kinds (foundation, Oct 2026)

The Empire's style for the stage agents (GDD §15.0 "Act III foundation (phase 1)"): **chrome bodies**
(the new `chrome` ramp: cold steel greys with a blue cast, bluer and more polished than the undead's
`grey`), **signal lights** (the new `signal` ramp: hard amber to warning red, for visors, sensor eyes,
lasers and screens), hard clean machine-made silhouettes with big flat panels and no wires or bolts;
a cyborg keeps a little `skin` so its face reads. Never the player's violet, the undead's bone or
soul teal. `prepare_sprite.py` folder `empire/`: ramps chrome, signal, skin, brown.

Generated with `tools/gen_image.py` (the template above; `--ref` the Covenant Recruit's source and the
Deep Kin's, then the Line Trooper's own source for the other two). Pipeline that worked: drop every
alpha below 230 (the API's dark glow), `tools/pixelate_source.py` onto the art grid, then
`prepare_sprite.py --no-levels --no-prune --ink-l 0.15 --no-cleanup` (with levels the signal ramp's
amber visor snapped to warning red; with the default ink cut the gun metal sank into outline ink).
Hand touch-ups on the palette (scripted, deterministic): the AI's orange-brown glow edges set to the
signal ramp (the Trooper's visor, shoulder and rifle lights; the Drone's eye ring, antenna and zapper);
the Trooper's interior `chrome_dark` lifted to `chrome` and the Spotter's chrome shifted one shade up
(both failed the floor-lightness check at L 0.35). Walk / glide strips by `walk_cycle.py` (rigs under
`# --- Act III ---`). 4 API images (one Spotter redo for a lighter coat and a bigger eye), about $0.16.
**For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `empire/scout_drone` | Scout Drone (fodder, a machine): a round chrome disc body, one big amber camera eye, two flat rotor discs on stubby arms, an antenna with a red light, a two-pronged zapper | 50x32 | hover (`_walk`: the whole drone bobs 2 px). **Round 1 redo** (owner: "it flies, its walk should just be a bob"): the still gained 2 empty rows on top (HEIGHTS 30 -> 32), the hem sway is gone |
| `empire/line_trooper` | Line Trooper (soldier, a cyborg): rounded chrome helmet with one wide amber visor band, the pale chin under it, big chrome shoulder pads, a red shoulder light, a boxy rifle levelled forward with an amber side light | 48x50 | legs walk (`_walk`, hip 27; the rifle rides with the body) |
| `empire/spotter` | Spotter (elite, a cyborg): a tall coated marksman, round chrome dome with one big red sensor eye and an antenna, chrome forearms and shins, a very long rail rifle with two amber coils | 62x56 | legs walk (`_walk`, hip 41: only the chrome legs step under the coat) |
| `summons/grave_gunner` | Grave Gunner (a raised Line Trooper, the undead's now). **Round 1 redo** (owner: "muddy; I don't like the colours, they stop the parts from looking good"; it was the Trooper recoloured to bone and soul teal): its own drawing, a skull-faced iron trooper in the undead's grey with bone-white parts that separate the shapes (skull, ribcage plate, knee pads, rifle bands), a brown belt, soul-teal eyes and muzzle; no chrome, amber or violet, so it never reads as an Empire soldier. Generated (`--ref` the Line Trooper and the Iron Revenant), then a "simplify" pass on its own image (big flat areas); converted with levels on | 48x50 | legs walk (hip 27) |

Code-drawn on purpose: the Empire's shots (amber tracers, the warning-red rail slug, arcing shells),
the Lock-On lines and reticles, the orbital strike circles, the Spotter's red glow, the Kill-Drone
(`EmpireGlyphs`, red-eyed; it has its own sprite since "Act III missing sprites" below) and the stubs' placeholder floors and obstacles; phase 2 brings the
stages' own art.

### Act III: the Assembly Halls (Stage 8; Oct 2026)

<!-- --- Act III: the Assembly Halls --- -->
The Assembly Halls' art and its rewards' art (GDD §15.0 "The Assembly Halls (Act III phase 2)"), in the
Empire style above: chrome bodies, signal lights; the Motherboard adds the `gold` ramp for its circuit
board chest, plus `moss` for the board itself (`--ramps chrome,signal,moss,steel,gold`: without gold its
traces snapped to signal red). Pipeline for the Empire sprites as above (alpha cut 230,
`pixelate_source.py`, `prepare_sprite.py --no-levels --no-prune --ink-l 0.15 --no-cleanup`).
**Shade lift:** every machine first failed the floor-lightness check at L 0.35, so each chrome / steel
pixel below the top two shades was moved one shade lighter, by a deterministic script over the stills,
strips and poses. After the lift they measure L 0.5 and up. The Marionette and her skins come from
the `_cut` sources with `--ink-l 0.20 --ramps violet,bone,soul,brown,gold,ice,crimson,grey,skin`, because
without `skin` her face read as blotches. Hyper uses `--inside-outline --no-prune --no-levels`. She is in
the figure-redesign style (hourglass figure, fully clothed), with a bust box in her walk and idle rigs.
Icons were generated as two 4-up sheets, cut, converted at 30 px and centred on 32×32 canvases.

**No API cost for the floors and props:**
- **Floors.** `make_tile.py` recipes from existing sources:
  - `assembly_docks`: the Sanctum courtyard flags, as a staggered 64 px plate grid;
  - `assembly_conveyor`: flat slate with a 16 px plate grid;
  - `assembly_fabricator`: grated steel;
  - `assembly_furnace`: scorched brick courses.
- **Obstacles.** `tools/assembly_props.py` draws all 24 obstacle PNGs on the palette: round props
  at `_s` / `_l`, and rect props also as `_s_v` / `_l_v`.
- **Code-drawn on purpose** (`AssemblyGlyphs`):
  - the belts (moving chevrons) and the furnace channels (dormant / glowing / burning);
  - the jam field, the arc beams and the Juggernaut's flame cone;
  - the fabricator build frames, the press-stamp squares, the crane claws and cables, and the
    magnet field;
  - the puppets' soul strings. A puppet is the seized foe's own sprite, tinted violet
    (`PuppetData.TINT`).

**Cost:** 20 API images, $0.66 in all (rows of 2026-10-20 06:12–06:16 in the ledger).
**For the owner's review.** A known weak spot: the Juggernaut's tank pack sits beside its helmet and
can read as a second head at game size.

| Key | What it is | Art px | Cost | Notes |
|---|---|---|---|---|
| `empire/arc_engineer` | Arc Engineer (support, a cyborg): chrome suit, amber visor, an arc tool levelled forward. **Round 1 redo** (owner: "monochromatic, it looks like a blob when it's all silver"): electric-blue (`arcane`) chest, shoulder and knee plates, dark gunmetal joints, a hazard-gold band on the tool, blue-white arc tip; chrome stays the base | 52x50 | $0.024 | legs walk (hip 30) |
| `empire/juggernaut` | Juggernaut (heavy elite, a machine): bulky chrome walker with a flamethrower and a fuel pack. **Round 1 redo** (same note as the Arc Engineer): warning-red (`crimson`) chest and shoulder armour, hazard-yellow striped fuel tanks (no longer read as a second head), dark joints, a red band on the barrel; chrome limbs. The interior `chrome_dark` of the legs below row 33 lifted one shade (it failed the Sanctum IV floor check by 0.02) | 66x62 | $0.024 | legs walk (hip 31) |
| `empire/fabricator` | Fabricator (structure): a chrome bay with an amber-lit hatch, hazard lights and a small build arm | 50x54 | $0.032 | still |
| `empire/motherboard_turret` | Motherboard turret (structure the boss builds): a small chrome gun post | 24x32 | $0.032 | still |
| `empire/beta_build` | The Beta Build (miniboss): a tall, half-finished chrome war machine with an amber visor slot and an arm cannon. **Round 1 redo** (same note): hazard-yellow test plating with dark stripes on the chest and thighs (the unfinished parts), dark frame joints, a red status light, a red muzzle band; converted with levels on (without them it failed the floor check) | 102x104 | $0.024 | legs walk (hip 69, spread 3) |
| `bosses/motherboard` | The Motherboard (boss): a walking factory on two tracks, a circuit board chest, red eyes, two raised crane arms | 120x150 | $0.032 | still |
| `bosses/motherboard_windup` | its windup pose (arms up, claws open) | 124x150 | $0.024 | BossPoseData index 1 |
| `bosses/motherboard_strike` | its strike pose (both cranes slammed down) | 190x150 | $0.024 | BossPoseData index 3 |
| `summons/grave_drone` | Grave Drone (summon): a bone skull on crossed-bone rotors, soul-teal eyes | 44x28 | $0.036 | hover: bob + wingbeat. **Round 1 redo** (owner: "it flies, make the wings move, not the mouth"): the two crossed-bone wings flap from the skull (4 px at the tip), the jaw stays; 2 empty rows on top (HEIGHTS 26 -> 28) |
| `summons/wraith_drone` | Wraith Drone (its evolution): the skull wreathed in soul-teal wraith flame | 38x32 | $0.036 | hover: bob + rotors. **Round 1 redo** (owner: "spin the propellers, not the bottom"): its three bone propellers spin (squeezed toward their hubs), the flame stays; 2 empty rows on top (HEIGHTS 30 -> 32) |
| `player/marionette` | The Marionette (character): violet harlequin gown, a black corset bodice with a deep plunging V neckline (fully clothed), a simple swept-back bun, a puppeteer's control bar with soul-teal strings | 40x56 | $0.037 + $0.033 | walk + idle (bust 18–29, 14–20, two lobes). **Round 1 redo** ("a bit too much detail on the head, give her some more chest and plunging neckline"; idle "one pixel to the right"): new source (no jester baubles or ruffled collar, a much larger bust), `--ink-l 0.20 --ramps violet,bone,soul,brown,crimson,skin` (levels on); the face (one dark eye, crimson lips) and the neckline (two skin mounds, a shadow cleavage line, violet cups) hand-painted on the grid, the face being 4 px wide |
| `player/marionette_hyper` | Hyper skin: a gold gown and crown | 36x58 | $0.032 | walk + idle |
| `player/marionette_untouchable` | Untouchable skin: white and ice, long lavender hair, a small bone tiara | 36x56 | $0.032 | walk + idle (bust 14–23, 14–19, two lobes). **Round 1 redo** ("she looks bald and chest isn't big enough"; strips "too low"): image generation was unavailable (the API key was invalidated mid-batch), so the still was fixed by hand on the grid (deterministic script): the hair round the head and down her back recoloured `violet_flare` / `violet_glow` (it was ice-white like her bone dome, so she read bald), the tall bone dome cut to a three-point tiara on the hair, the face repainted (teal eye), and a larger bust with the base Marionette's plunging V; bust box raised (was rows 15-21) |
| `player/marionette_deathlord` | Deathlord skin: violet and crimson, a crimson cape and a gold crown | 44x60 | $0.032 | walk + idle. **Round 1 redo** ("the jiggle is on her belt, not her chest"): bust box cols 19-29, rows 16-20, two lobes (was cols 18-30, rows 17-24, over the belt at rows 23-26) |
| `icons/hollow_puppet`, `icons/puppet_king`, `icons/strings_of_the_dead`, `icons/overclock` | spell, evolution, two passives | 32x32 | $0.031 (sheet) | one 4-up sheet |
| `icons/grave_drone`, `icons/wraith_drone`, `icons/signal_ghost`, `icons/ach_cold_assembly` | class, evolution, passive, achievement | 32x32 | $0.031 (sheet) | one 4-up sheet |
| `tiles/assembly_docks`, `_conveyor`, `_fabricator`, `_furnace` | the four zone floors | 128x128 | $0 | `make_tile.py`. **`assembly_conveyor` round 1 redo** (owner: "conveyor belts don't look like this"; it was a 16 px slate grid): the new `belts` layout, two long rubber belts per tile running along x like the zone's live belts, ridged slats every 8 px, steel side rails (lit top edge, shaded bottom edge) with a roller hub every 16 px, a dark floor gap between belts; mean L 0.27. The live belts (`AssemblyGlyphs`: near-black rubber, scrolling amber chevrons, 80 px wide) still stand out on it |
| `obstacles/cargo_crate`, `press_machine`, `servo_cabinet`, `ingot_stack` (`_s`, `_l`, `_s_v`, `_l_v`); `fuel_drum`, `parts_bin`, `robot_arm`, `crucible` (`_s`, `_l`) | the four zones' obstacles | 22x27–64x47 | $0 | `tools/assembly_props.py` |
### Act III: the Scrap Wastes (Stage 7; Act III phase 2, Oct 2026)

Generated with `tools/gen_image.py` (the template above; `--ref` the Line Trooper's and Scout Drone's
sources for the machines, the Spotter's and Seraphine's for Kestrel, the Tide Widow's and the
necromancer's for the Lightning Abbess, then each new source as the reference of its own poses and
skins; the cyclopean block and the Aegis Bot for the obstacles; Ul-Thalos's spire floor for the tiles;
an approved badge for the symbols). The Empire's pipeline (foundation): alpha below 230 dropped,
`tools/pixelate_source.py` onto the art grid, then `prepare_sprite.py --no-levels --no-prune --ink-l 0.15
--no-cleanup` (Kestrel with `--ramps chrome,signal,skin`); the Abbess at `--ink-l 0.20` (levels on for
the base and the ghost, off for the gold Hyper and Deathlord skins), one face pixel group hand-painted
on the base still (her eye and cheek; the veil hid it). Obstacles: one source per kind, the three rect
kinds as an H + V pair on one image (split at the widest transparent gap), every size converted from
it to its footprint width (`--ramps brown,chrome,signal,grey,steel`). Tiles: `make_tile.py` quilt
recipes (`wastes_*`, no variants). Badges: symbol at 26 px composited on a cut-corner template cleared
from an approved badge (violet border; gold for the evolution and the achievement). Walk / idle strips
by `walk_cycle.py` (rigs under `# --- Act III: the Scrap Wastes ---`; Kestrel and the Abbess have
bust boxes and idle breathing strips). 28 API images, about $0.75 (ledger estimate). **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `empire/aegis_bot` | Aegis Bot: a squat chrome walker behind a big round amber-rimmed shield plate | 40x48 | legs walk, the shield rigid; the energy arc in front is code-drawn (AegisKit) |
| `empire/mortar_walker` | Mortar Walker: a low four-legged chrome walker, a stubby mortar tube on its back, a red eye | 60x48 | legs walk (the two leg pairs) |
| `empire/signal_pylon` | Signal Pylon: a chrome mast on a tripod, two amber dishes, a red beacon on top | 96 tall | structure; the beacon blink and the reach ring are code-drawn (PylonKit) |
| `empire/trojan_horse` | The Trojan Horse: a horse-shaped four-legged drone tank, two missile pods, a red eye. **Round 1 redo** (owner: "the pods should face the front of the horse; too much side, closer to 3/4"): a three-quarter front view (chest and head toward the lower right), both pods turned forward with their 2x2 amber tube grids facing the way the head looks, a warning-red chest plate and pod sides | 108x104 | legs walk (hind pair left, front pair right; the chest plate rides with the body) |
| `empire/trojan_horse_split` | The same with its flank hull split open, glowing amber drone bays inside. **Round 1 redo**: redrawn from the new three-quarter Horse (`--ref` it) | 108x104 | legs walk (the Horse's rig); drawn once the hull splits |
| `bosses/kestrel` | Kestrel, the Dead Pixel (figure redesign, fully clothed): a chrome-plated bodysuit, tall collar, a short cape ending at the waist, silver hair, a red cyber eye, a very long sniper rifle; **pear-shaped** (very wide hips, a full round rear, thick thighs) | 144x124 | legs walk + bust bounce (two lobes, cols 64-87, rows 24-37), idle breathing. **Round 1 redo** (owner: "make her butt bigger, more of a pear shape"; idle jiggle "about 2 px to the right"): new source with the old sprite and the Sister of the Scourge attached, converted **with levels on** (`--no-prune --ink-l 0.15 --no-cleanup --ramps chrome,signal,skin`; with `--no-levels` the dark chrome failed every floor at L 0.35, now L 0.55, passes all) |
| `bosses/kestrel_aim` | Her perch pose: kneeling, the rifle raised to the shoulder, the wide hips and rear prominent | 144x108 | pose 1 (BossPoseData). **Round 1 redo** ("see above"): regenerated from the new still and the old pose, converted like the still. **Round 2 redo** (same note as the blades): by hand on the grid, the dark crease between the rear and the kneeling thigh (cols 51-60, rows 56-78) taken out, the raised front thigh 1-4 px deeper (its underside dropped, cols 79-88) and the kneeling thigh 2 px wider toward the front (rows 77-84) |
| `bosses/kestrel_blades` | Her last phase: two amber energy arm blades, one raised high, one low; the pear-shaped figure in a wide lunge | 120x124 | the blades still (legs walk, the low blade rigid, + bust, idle); its strike pose falls back on it. **Round 1 redo** ("love the arm blades, but redesign with what's above"; jiggle "extend more to the left"): regenerated from the new still and the old blades pose; converted with levels on, then the `signal` (blades, eye) and `skin` pixels taken from a `--no-levels` conversion of the same grid (levels turned the amber blades red and the face brown); bust box two lobes, cols 44-71, rows 38-50 (was 48-73, 34-47). **Round 2 redo** ("there's an extra line where her butt meets her leg, fix it; make the thighs thicker", matching the approved still): fixed by hand on the grid (deterministic script): the dark crease between the rear and the back thigh (cols 37-43, rows 57-79) taken out, so they read as one form; the back thigh 1-2 px wider on its inner side (rows 82-92) and the front thigh 2 px wider on both edges (rows 62-88). Rig legs split at col 61 (was 60), since the back thigh now reaches col 60; walk and idle strips rebuilt; the bust box still sits on the chest **Round 3 redo** (owner: "the spike coming off her butt"): the cape wedge below the rear (rows 84-91) trimmed back to the thigh outline; strips rebuilt. |
| `player/lightning_abbess` | The Lightning Abbess (figure redesign, fully clothed): a long violet habit with a slit, veil and wimple, a bone rib collar, a crescent staff crackling with violet lightning | 44x56 | robe glide + bust, idle breathing. **Round 1 redo**: bust box 2 px right (cols 20-30, was 18-28), strips rebuilt |
| `player/lightning_abbess_hyper` | Gilded Stormbride (Hyper): a plain violet habit and veil, gold on three big pieces only (a three-spike crown, one waist sash, a plain staff with a crescent and violet orb) | 32x58 | through `SKINS`. **Round 1 redo** ("a bit unclear with all the detail, make it clearer"): new source asking for big flat shapes and no scattered gold; `--ink-l 0.20 --no-prune --ramps violet,bone,gold`; hand fixes (deterministic): the gold's dark shade (`brown_light`, the 2 px pole) set to gold, the crown spikes and the face (bone, the near eye dark, the far one a shade, violet lips) painted on the grid; `SKIN_FIX` bust box cols 13-22, rows 17-23 (ends above the sash). Fails only Sanctum I / IV lightness, like the necromancer and every violet character (the old one failed all 13 floors) |
| `player/lightning_abbess_untouchable` | Untouchable: a ghost-white phantom, wisp tails, soul-teal eyes and staff | 44x56 | through `SKINS`. **Round 1 redo** ("jiggle needs extending to the right"): `SKIN_FIX` bust box cols 19-30, rows 18-24 (the derived box stopped at col 28) |
| `player/lightning_abbess_deathlord` | Deathlord: a spiked gold crown, iron pauldrons, crimson mantle, mid-violet gown | 38x58 | through `SKINS`. **Round 1 redo** ("jiggle is too far down, needs to be up and to the right"): `SKIN_FIX` bust box cols 14-23, rows 17-23 (the derived box, cols 12-22 rows 20-26, ended on the gold belt). **Round 2 redo** ("a little bit more to the right, maybe 1 pixel"): box cols 15-24 (1 px right), walk and idle strips rebuilt **Round 3 redo** ("extend bounce window 2 pixels to the right"): bust box cols 15-26 (was 15-24); strips rebuilt. |
| `tiles/wastes_slag`, `wastes_gullies`, `wastes_ridge`, `wastes_wall` | The four zone floors: slag crust, rust grit, cracked ash rock, concrete slabs | 128 | quilt; mean L 0.23 / 0.24 / 0.25 / 0.26 |
| `obstacles/slag_mound_{s,m,l}` | A heap of slag and scrap with a red seam | 28 / 36 / 44 wide | circle |
| `obstacles/ridge_boulder_{s,m,l}` | A cracked ash boulder under a snapped cable | 32 / 40 / 52 wide | circle |
| `obstacles/tank_trap_{s,l}` | A rusted steel tank trap | 24 / 30 wide | circle |
| `obstacles/wreck_plate_{s,l}` (+ `_v`) | A rusted armour slab half sunk in the ground | 48 / 64; `_v` 28 wide | H + V pair |
| `obstacles/titan_hull_{s,l}` (+ `_v`) | A fallen war titan's chrome limb segment | 84 / 104; `_v` 36 wide | H + V pair |
| `obstacles/wall_segment_{s,l}` (+ `_v`) | A broken concrete wall length with rebar and hazard stripes | 88 / 104; `_v` 32 wide | H + V pair (a little wider than the footprint: the rebar) |
| `icons/death_ray`, `conductive_marrow`, `lead_lined_bones` | Badges (violet border): a skull firing a soul laser; **round 1 redo** a plain bone with violet lightning bolts shooting off it (owner: "lightning shooting off the bone"); **round 1 redo** a heavy lead-grey shield plate over crossed bones, a flattened amber bullet and spark on it (owner: "no visual identity") | 32 | |
| `icons/event_horizon`, `ach_static_in_the_wastes` | Gold-border badges: two opposite beams round a skull; **round 1 redo** (owner: "doesn't look like anything") a cracked boxy CRT monitor showing a big bone-white skull, one red glitch bar across its jaw | 32 | |
| `effects/wastes_blast` | A rocket / shell blast: amber flash, fire and chrome shards, a smoke ring | 10 x 128 | `AnimData` (rockets, the stomp, pylons falling, the Trojan Horse) |

Code-drawn on purpose: the Swarm Rocket (turned along its heading, `WastesGlyphs.draw_rocket()`), the
Aegis shield arc, the pylon beacon and reach ring, the dead zones, the scrap storm's dust veil (rings
and grit streaks, no shader), Kestrel's decoy holograms (her sprite drawn see-through in amber with
scan lines), the Death Ray beams and the lightning (Soul Chains' arcs).

### Chest beacon (owner request, Oct 2026)

The chest beacon's two markers (GDD §15.0 "Chest beacon"; keys in `scripts/data/chest_beacon_data.gd`). Shapes this
small read best with every edge on a whole art pixel, so they are **drawn on the grid** by `python3 tools/chest_beacon_art.py`
(deterministic, like `tools/mesh_props.py`), not generated: gold (the chest's colour in the UI colour language) with a
gold_light rim on the top-left, a brown_light shade on the bottom-right, one holy_white glint and a solid 8-neighbour
ink_warm outline, so they read on the light Sanctum floors as well as on the Graveyard soil. Flat sprites
(`SpriteData.FLAT_SIZES`), drawn 1:1; each site keeps a code drawing as its fallback. The ground glow and pulse ring under
the chest, the badge's pulse ring and the pointer that turns toward the chest stay code-drawn. No image generation ($0).

| Key | Subject | Art px (w × h) | Drawn by | Status |
|---|---|---|---|---|
| `markers/chest_beacon` | A thick gold down-chevron (a V with a notch cut from its top) | 19 × 15 | `ChestBeacon._draw()`: over every chest lying in the world, 26 px above its centre, bobbing 3 px on real time (still with Reduce motion), z 18 above the units | done |
| `markers/chest_badge` | A round gold ring on a dark brown plate holding a little gold chest (lid, band, keyhole, a glint) | 21 × 21 | `ChestArrows._draw_arrow()`: upright on the screen edge for a chest off screen, a code pointer beside it, fading with distance (never below 55%) | done |

### Act III: the Iron Citadel (Stage 9; Oct 2026)

The campaign finale's art (GDD §15.0 "The Iron Citadel (Act III phase 2)" and the rows after it), in
the Empire's style above (chrome + signal; the cyborgs keep a little skin). The two Valkyries are in
the **figure-redesign style** (exaggerated hourglass figures, fully clothed, bust bounce in the walk
and a 24-frame idle breathing strip). Units, characters and the boss: `tools/gen_image.py` (the unit
template, `--ref` the approved Act III sprites), alpha below 230 dropped, then for the small detailed
figures `tools/pixelate_source.py` first, then `prepare_sprite.py --no-levels --no-prune --ink-l 0.15
--no-cleanup` (0.20 for the Rust Prophet and his skins; `--ramps chrome,signal` for Deus, plus skin
for the Founder's Varn); the revenants went straight through `prepare_sprite.py` (cleaner than
pixelated). Floors: two API textures through `make_tile.py` recipes (`# --- Act III: the Iron
Citadel ---`): one riveted deck-plate texture laid out three ways (32 px staggered plates, a 16 px
panel grid, 8 px grating slats) and a circuit-etched plate quilted for the Core. Obstacles: two prop
sheets (four round props in a row; the two rects, horizontal and end-on) split by empty gaps, each
drawing scaled to its sizes (rects: the middle cut out to each length so a short barricade keeps its
end caps). Badges: two symbol sheets, each symbol pixelated to 24 px and set on the cut-corner frame
copied from an approved badge (violet `abyssal_pact`, gold `tidecallers_host`). Walk / idle strips:
`walk_cycle.py` rigs and skins under `# --- Act III: the Iron Citadel ---`. 21 API images, about
**$0.50** at the tool's estimate (rows in the ledger). **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `empire/valkyrie_duelist` | Valkyrie Duelist (elite cyborg, female): signal-red bodysuit under a chrome breastplate, winged helmet with an amber visor band, twin jet pods, a long forearm blade pointing forward | 52x52 | legs walk + bust (box 22-34 x 13-21), idle breathing |
| `empire/valkyrie_prime` | Valkyrie 2.0 (miniboss): heavy chrome armour over red, crested helmet, big jet pack, tower shield with an amber stripe, arm blade | 76x104 | legs walk (blade arm and shield rigid) + bust (two lobes), idle breathing. **Round 1 redo** ("jiggle needs to be extended upward a few pixels"): bust box rows 27-38, cols 28-43 (was rows 30-39, cols 28-45: it began below the top of the breastplate and its right edge held the amber shoulder light), strips rebuilt. **Round 2 redo** ("her feet split as part of the animation"): the rig held the blade (cols 0-14) and shield (cols 52-76) rigid down to the bottom row, so the toes inside those columns (cols 6-13 and 52-55) stayed still while the rest of each foot moved; now the blade (cols 0-10) and shield (cols 49-75) are rigid only to row 85, where they end, and the legs own every column below (back 0-35, front 36-75). Every walk frame checked: both feet whole. Walk strip rebuilt; the idle strip comes out identical |
| `empire/sentry_turret` | Sentry Turret (structure): a chrome dome on a tripod base with an amber eye; the turning gun is code-drawn on its top (`CitadelGlyphs.draw_turret_barrel()`) | 44 | still |
| `empire/shield_generator` | Shield Generator (structure): a squat chrome pylon with an amber energy coil | 64 | still |
| `empire/deus_leg_plate`, `empire/deus_shield_drone` | Deus's armour plate (rides a knee) and Siege Core shield drone (one sheet split at x 537) | 32 / 24 | stills |
| `bosses/deus_ex_machina` (+ `_fire`) | Deus Ex Machina, the Walker: a four-legged chrome war engine with a missile pod and a cannon arm, an amber reactor core; `_fire` the attack pose (BossPoseData 1: chaingun and salvo) | 202x156 | the knees set `DeusData.LEGS` (the plates ride them). **Round 2 redo** (all four Deus stills, owner: "add some more color, a bit monochrome"; the Arc Engineer / Juggernaut / Beta Build fix): recoloured by hand on the existing pixels (deterministic script, no new image, sizes and anchors unchanged so the leg plates still line up). Chrome stays the base (torso, missile pod, legs, cannon); one accent hue, warning red from the `signal` / `crimson` ramps (chrome -> `signal_red`, its shadow `crimson_dark`, glints `flame`), on the same parts in every pose: the crenellated head hull, both shoulder plates, the toe caps and a band on the cannon; the visor slot darkened to gunmetal and its light turned amber so it reads on the red hull; four framed amber light panels (4x3) on the shins; the dark frame stays as the joints. Single-pixel specks the recolour made are merged into their neighbours. art_check: the Walker now fails 8 floors (the March roads and the Sanctum, main shape L 0.37; it failed all 13 before), `_fire` passes every floor (as before) |
| `bosses/deus_ex_machina_siege` | The Siege Core: the engine kneeling, planted, its core shielded | 140 | phase look 1. **Round 2 redo**: as the Walker (the hull, the shoulder plate, toes, cannon band, visor, shin panels); fails the same 13 floors as before (L 0.35, its dark kneeling frame) |
| `bosses/deus_ex_machina_founder` | The Founder: the cracked frame with Varn, the Root User, in its open core | 156 | phase look 2. **Round 2 redo**: as the Walker; Varn's reactor core and amber eyes keep their glow, his open cockpit stays dark so his face reads (a glow behind him was tried and dropped: it hid him); passes every floor (as before) |
| `player/rust_prophet` | The Rust Prophet: hooded violet robe, rusted chrome arm, visor lens, a staff of scrap and bone topped by a gear and a violet flame | 42x58 | robe walk (staff rigid) |
| `player/rust_prophet_hyper` / `_untouchable` / `_deathlord` | Gilded Prophet (Hyper skin, gold trim and cog crown), Untouchable (white phantom), Deathlord (spiked crown, black iron) | 58 / 58 / 60 | walk through `SKINS` |
| `summons/iron_revenant` | Iron Revenant: a squat iron walker bound with bones, a horned skull cockpit with soul-fire eyes, one cannon arm | 58x58 | legs walk |
| `summons/deus_revenant` | Deus Revenant: horned skull cockpit, twin cannons, a bone missile rack. **Round 1 redo** (owner: "too much detail; I can't see the missile racks, the cannons don't look right"): simplified to big flat parts, a box missile rack above the back shoulder with a 2x3 grid of bone tips, one thick twin cannon with bone bands and teal muzzles, bone knee plates; converted with levels on (`--ramps grey,bone,soul,brown`), the two eye pixels set to `soul` | 62x70 | legs walk (hip 44) |
| `tiles/citadel_gates`, `_courts`, `_lifts`, `_core` | The four zone floors: deck plates, a panel grid, grating slats, circuit-etched plating with dim red traces | 128 | `make_tile.py`; the decals stay code-drawn |
| `obstacles/signal_bollard_{s,m,l}`, `emitter_pylon_{s,m,l}`, `lift_winch_{s,m,l}`, `core_conduit_{s,l}` | A hazard-striped bollard, a pylon with a red lens, a cable winch, a pipe junction with red seams | footprint + 2 wide | circles |
| `obstacles/iron_barricade_{s,m,l}` (+ `_v`) | A low barricade of steel plates with a hazard-striped top | 54 / 68 / 84 x 32; `_v` 28 wide | rects |
| `obstacles/citadel_crate_{s,m,l}` (+ `_v`) | A ribbed steel shipping crate with a red stripe | 50 / 66 / 78 x 36-39; `_v` 32 wide | rects |
| `icons/scrap_swarm`, `machine_soul`, `recoil_frame`, `iron_revenant` | Violet badges: drones round a violet flame; a cracked gear with a soul flame; a bone cannon in a spring; the skull cockpit | 32 | |
| `icons/deathless_swarm`, `deus_revenant`, `ach_nothing_is_deathless` | Gold badges: the gilded swarm; the crowned twin-cannon cockpit; a split machine mask with a violet flame | 32 | |

Code-drawn on purpose: the shield wall and its cables, the laser bands and beams, the citadel gun
circles (the shared strike code's), the Judgment Lance, the overload pulses, the teleport glow, the
blade storm and jets, the shield drones' tethers, the scrap drones and bolts, the iron shells, the
soul-binding finale and the floor decals: telegraphs and effects that must read at a glance.

### Act III art review, round 1: machines, summons, icons, the conveyor floor (Oct 2026)

The owner's first Act III review asked for redos; this batch is every key except the female figures
(Kestrel, Valkyrie 2.0, the Lightning Abbess, the Marionette: their own batch). The rows above carry
a "Round 1 redo" note per key. Pipeline as in the Act III sections: `tools/gen_image.py` (each
machine with its own old source as `--ref` and a "redraw with colour blocking" prompt; the Trojan Horse
from its first redo with a "turn it 45 degrees" prompt), alpha below 230 dropped, `pixelate_source.py`,
`prepare_sprite.py --no-prune --ink-l 0.15 --no-cleanup` (levels on for the Beta Build and the two
summons, off for the rest). Colour rule for the machines: chrome stays the base, one accent hue per
kind (Arc Engineer electric blue, Juggernaut warning red, Beta Build hazard yellow, Trojan Horse
warning red), dark gunmetal joints; never bone, soul teal or violet on an enemy. Summons stay in the
undead's grey + bone + soul teal (no violet, like every other summon). Badges: symbol at 26 px on
the frame of an approved badge, as before. Walk strips: `walk_cycle.py` (new `hover` mode for the
three flyers). Floor: `make_tile.py` (new `belts` layout), no API image. 15 API images, $0.37 at the
tool's estimate (ledger rows 2026-10-20 15:04-15:11). **For the owner's review.**

### Act III art review, round 2: Deus, Kestrel's poses, Valkyrie 2.0's walk, the Deathlord Abbess (Oct 2026)

The owner's second review: the four Deus Ex Machina stills recoloured (more colour, the Arc Engineer /
Juggernaut / Beta Build rule: chrome base, one accent hue, amber lights, dark joints), Kestrel's aim and
blades poses without the crease between rear and thigh and with thicker thighs, Valkyrie 2.0's walk rig
fixed so the feet stay whole, the Deathlord Abbess's bounce box 1 px right. All by hand on the existing
PNGs (deterministic scripts, no image generation, $0); strips rebuilt with `walk_cycle.py`. Each key's
row above carries a "Round 2 redo" note. **For the owner's review.**

### Act IV: the Olympian Republic, the shared kinds (foundation, Oct 2026)

<!-- --- Act IV: the Olympian Republic --- -->
The Republic's style for the stage agents (GDD §15.0 "Act IV art: the shared kinds"; `docs/act4/PROPOSAL.md`):
**bronze** armour (the new `bronze` ramp, warm and dull, so the existing `gold` keeps its meaning: evolution, chest,
victory and Glory, worn only by heroes and gods), **marble** white for linen, crests, statues and the dead (the new
`marble` ramp, cooler and greyer than the undead's bone ivory), **Aegean blue** for cloaks, crests and emblems and as
the gods' pale glow (the new `aegean` ramp; eyes and cracks of light, never the undead's soul teal or arcane blue),
skin on faces and arms, brown wood for spear shafts. Hard, clean silhouettes with one big signature shape each (the
hoplite's round aspis, the hero's plume and cloak, the Titan's shoulders and fists, the shade's hood and tail). Never
the player's violet, the undead's bone or teal, or the Covenant's crimson and warm steel. `prepare_sprite.py` folder
`pantheon/`: ramps bronze, marble, aegean, gold, skin, brown. Concept references: `art_source/concepts/act4_lineup.png`
(costumes), prompts beside each source in `art_source/pantheon/<id>.txt` (the template above, the sex named).

Generated with `tools/gen_image.py` (`--ref` the Line Trooper's source for the pixel look, plus a crop of the concept
lineup for the hoplite and the hero, the hoplite's own source for the shade and the Titan). The sources come back on
the grid at ~12 source px per art px (~78 art px figures) with a dark glow. Pipeline that worked (better than
`pixelate_source.py` here, which blurred the bronze into mud): a **pre-snap** (alpha cut 230; skin found by
`skin_cap.skin_mask()` set to exactly `skin` / `brown_light`; near-white, low-saturation pixels set to the nearest
marble shade, so plumes, linen and the shade never snap to the bone ivory), then `prepare_sprite.py` straight on the
source with `--ink-l 0.15` and an explicit `--ramps` (levels on for the hoplite, shade and Titan; `--no-levels` for
the hero, whose gold sank to bronze with levels). Scripted hand touch-ups (palette colours only): the hoplite's aspis
repainted as a clean disc (ink ring, dark rim, bronze face lit top-left, a big Aegean boss: the Phalanx's front must
read) and a face in his helmet (eye slit, cheek, beard); the shade's fold noise flattened by a 3x3 majority filter, a
dark hood opening with two Aegean eyes painted, two empty rows added on top for the hover bob. Walk / hover strips by
`walk_cycle.py` (rigs under `# --- Act IV ---`). 4 API images, about $0.12. All four pass `art_check.py` (0 fail, 0
warning). **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `pantheon/shade_of_dead` | Shade of the Dead (fodder, male): a pale ghost in a marble-grey burial shroud pulled up as a hood, a dark face opening with two pale Aegean eyes, both arms reaching forward, no legs: the shroud tapers into a curling wisp tail | 40x36 | hover (`_walk`: the whole ghost bobs 2 px; the still keeps two empty rows on top, body 34) |
| `pantheon/hoplite` | Hoplite (soldier, male): bronze Corinthian helmet with a tall Aegean crest, the face in its opening, bronze cuirass over a marble linen tunic, a big round bronze aspis held forward (Aegean boss), an upright spear | 30x56 | legs walk (`_walk`, hip 42; the spear rigid). Body ~50 under the spear head |
| `pantheon/hero` | Hero (elite, male demigod, Hector-like): a gold open-faced helmet with a tall white plume, face and arms in skin, a gold cuirass, bronze greaves, a billowing Aegean-blue cloak, a bronze sword held forward | 58x58 | legs walk (`_walk`, hip 41; the cloak's low hem rigid). Grander than the hoplite: the gold is the hero's (Glory) |
| `pantheon/bronze_titan` | Bronze Titan (the Reckoning's heavy, male colossus): a walking bronze statue, huge shoulders and low fists, a small crested head with glowing Aegean eyes, Aegean cracks of light on the chest, a marble kilt and marble plinth chunks on his shins and feet | 74x96 | legs walk (hip 64, spread 3, lift 4; both low fists rigid). Round 3 (round 2: the mirrored-leg stride "not even close"): a new source of the same titan, legs apart in a square front stance (`art_source/pantheon/bronze_titan_r3.txt`, the approved source and still as references; the crossed-leg source kept as `bronze_titan_crossed.png`), `--ramps bronze,marble,aegean --ink-l 0.12` (fewer inner ink lines, like the approved still); the still replaced so still and walk match. Stepping out of the ground is drawn by code |

Code-drawn on purpose (phase 1): the wrath telegraphs and strikes, the phalanx's locked shield line, the Glory aura
and the stubs' placeholder floors and obstacles (`PantheonGlyphs`, `PantheonGround`); phase 2 brings the stages' own
art (the legionary, wolf, centaur, Amazon, Gorgon and Cyclops from the concept lineup, the female kinds in the
figure-redesign style with a `bust` box and idle strip).

### Act IV: the Shores of Ilion (Stage 10; Act IV phase 2, Oct 2026)

<!-- --- Act IV: the Shores of Ilion --- -->
Generated with `tools/gen_image.py` (prompts beside each source, `art_source/<key>.txt`, the sex named in every
figure prompt; `--ref` the Hoplite's source for the pixel look plus a crop of `act4_lineup.png` for the legionary,
wolf, cyclops and Achilles; Achilles' own source for his two poses; the Tide Widow's and the necromancer's sources
for the Doomed Prophetess, then her source for her three skins; the Scrap Wastes' obstacle sources and `wastes_slag`
for the obstacles and tiles; `death_ray` for the icon symbols). The Republic's pipeline (foundation section above):
a **pre-snap** (alpha cut 230; skin by `skin_cap.skin_mask()` set to exactly `skin` / `brown_light`; near-white,
low-saturation pixels to the nearest marble shade), then `prepare_sprite.py` straight on the source with
`--ink-l 0.15` and explicit ramps (`bronze,marble,aegean,gold,skin,brown`, `+grey` for the boulders); Achilles and his
poses `--no-levels` (his gold, like the Hero's). The wolf went through `pixelate_source.py` (36 rows, `--ink-l 0.22`).
The Doomed Prophetess and her skins: `prepare_sprite.py` straight on the source, `--ink-l 0.20` (levels on for the base
and the ghost and Deathlord skins, `--no-levels` for the gold Hyper skin): the `pixelate_source.py` route came out
noisier on her. Scripted hand touch-ups (palette colours only): the wolf's Aegean eye and two marble fangs, a single
cyclopean eye (marble white, an Aegean iris) painted on the Cyclops and on Polyphemus (the conversion lost both).
Obstacles: one source per kind, the rect kinds as an H + V pair (split at the widest transparent gap), each size
converted to its footprint width with `--no-center` (V: the long side x 1.12 tall). Tiles: `make_tile.py` quilt
recipes `ilion_*` (the API returned them nearly transparent; stored opaque). Icons: the symbol at 26 px on a
cut-corner badge cleared from an approved one (violet border; gold for the evolution and the achievement). Walk /
idle strips by `walk_cycle.py` (rigs under `# --- Act IV: the Shores of Ilion ---`; the Prophetess and her skins
have bust boxes and idle breathing strips; the siege tower has no strip: it rolls). 28 API images (one icon redone: Paris's Arrow's first symbol read as a ghost), about $0.62
(ledger estimate). `art_check.py`: every unit passes on every floor except the siege tower, Achilles' rage form and
the Prophetess's Hyper skin (lightness fails on the March road and the Sanctum floors, where they never or rarely
stand; the violet characters fail the same floors), Achilles' strike pose and the Deathlord skin on Sanctum IV only.
**For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `pantheon/legionary` | Legionary (soldier, male): bronze helmet with a white transverse crest, bronze bands, a tall Aegean scutum with a bronze boss and wings, a gladius | 32x56 | legs walk (hip 41); the testudo's raised roof and the shield line are code-drawn (LegionaryKit, Phalanx) |
| `pantheon/wolf_of_rome` | Wolf of Rome (fodder pack): a bronze statue wolf loping, Aegean eye, marble fangs | 68x36 | legs walk (hind / fore split at col 30) Round 1 redo (owner: "not clear that it's a statue"): regenerated (one API image, ~$0.03; `art_source/pantheon/wolf_of_rome.txt`), converted by `prepare_sprite.py` (levels on, ramps bronze, marble, aegean, drowned), then hand touch-ups (palette colours): verdigris seams (drowned ramp) between the sculpted plates and under the belly, curled ruff locks, a glowing Aegean eye, marble fangs, broken marble plinth stumps on a fore and a hind paw. |
| `pantheon/cyclops` | Cyclops (heavy, male): a hulking marble-pale giant, a single eye, a boulder held up beside his head, leather loincloth | 56x70 | legs walk; the thrown boulders are code-drawn (IlionGlyphs) |
| `pantheon/polyphemus` | Polyphemus the Cyclops (miniboss, male): a bigger giant in a ram fleece, a huge boulder over his head, one eye with an Aegean iris | 60x112 | legs walk Round 1 redo (owner: fleece too close to the skin): the fleece (chest, shoulders and hip, a hand-drawn polygon) remapped from marble greys to the bone ramp's olive shades (bone_mid / bone_shade) and steel_dark, so wool and skin separate; the walk strip re-derived. |
| `pantheon/siege_tower` | Siege Tower (structure): a timber tower on four wheels, bronze-plated front, folded drawbridge, an Aegean banner | 50x104 | no strip (it rolls; the dust and ruts are code-drawn, SiegeTowerKit) |
| `bosses/achilles` | Achilles, the Unkillable (male): a gold lion helmet with a tall Aegean crest, gold cuirass, white skirt, bronze greaves, bare heels, a round gold shield, a long spear | 64x120 | legs walk (the spear rigid); the gold heel mark, the front arc, the rage's gold fire are code-drawn |
| `bosses/achilles_strike` | His lunge: low, the spear thrust far ahead, the shield slung | 80 tall | pose 3 (BossPoseData), converted at 80 art px so his scale matches the still |
| `bosses/achilles_rage` | His rage: helmet and shield gone, long wild hair, war cry, the spear raised high, torn cloak | 92x120 | its own still (motion key in the rage), legs walk |
| `player/doomed_prophetess` | The Doomed Prophetess (female, figure redesign, fully clothed): long violet hair, a bone laurel circlet, a deep violet peplos with a slit, a tall bone bow with a violet string | 36x56 | robe glide (bow rigid) + bust (cols 16-25, rows 15-21), idle breathing |
| `player/doomed_prophetess_hyper` | Gilded Sibyl (Hyper): plain violet gown, gold laurel crown, gold sash, gold bow | 34x58 | through `SKINS` (derived rig) Round 1 redo: bust box extended 2 px left (`SKIN_FIX`, cols 12-24). |
| `player/doomed_prophetess_untouchable` | Untouchable: a ghost-white phantom, wisp hem, soul-teal bow | 32x56 | through `SKINS` |
| `player/doomed_prophetess_deathlord` | Deathlord: a gold crown, iron pauldrons, crimson mantle, mid-violet gown, an iron bow with a crimson string | 36x58 | through `SKINS` Round 1 redo: bust box extended 2 px left (`SKIN_FIX`, cols 15-27). |
| `tiles/ilion_beach`, `ilion_camp`, `ilion_gate`, `ilion_walls` | The four zone floors: wet sand, trampled camp earth, worn flagstones, limestone slabs | 128 | quilt; mean L 0.23 / 0.23 / 0.24 / 0.24 |
| `obstacles/beached_warship_{s,l}` (+ `_v`) | A beached trireme: a dark hull with oar ports, a bronze ram, a painted eye, the furled sail | 80 / 96; `_v` 32 / 38 wide | H + V pair |
| `obstacles/sea_rock_{s,l}` | A wet sea rock with weed and a bronze anchor | 30 / 36 wide | circle |
| `obstacles/siege_tent_{s,l}` | A round white army tent with blue stripes | 38 / 44 wide | circle |
| `obstacles/palisade_{s,l}` (+ `_v`) | A row of sharpened stakes lashed with rope | 56 / 76; `_v` 22 / 30 | H + V pair Round 1 redo (owner: "just looks like a blob"): all four redrawn by script as upright logs with pointed tops, an ink outline per log, a lit left side, a shaded right side, two rope bands and a few bronze tips (the `_v` pair as a receding line of stakes). |
| `obstacles/troy_wall_{s,l}` (+ `_v`) | A broken length of the walls of Troy, limestone courses with a blue band | 76 / 92; `_v` 30 / 36 | H + V pair |
| `obstacles/fallen_column_{s,l}` | A fallen fluted column on cut blocks | 28 / 36 wide | circle Round 1 redo (same note): redrawn by script as a fluted drum on two cut blocks, a continuous `bronze_ink` outline, lit top, four shade bands, flute lines, an end face with rings and cracks on the blocks. |
| `icons/paris_arrow`, `mortal_heel`, `bronze_breaker` | Badges (violet border): a violet arrow with a bone head and a looping trail; a bare heel struck by a ghost arrow; a bronze shield cracked by a bone club | 32 | |
| `icons/arrow_of_fate`, `ach_heel_found` | Gold-border badges: three ghost arrows around a skull; a gold lion helmet knocked over, pierced by a ghost arrow | 32 | |

Code-drawn on purpose: the boulders (held and in flight), the landing circles and stomps, the testudo's raised
roof, the siege tower's dust and ruts, Achilles' heel mark and front arc, Paris's Arrow's ghost arrows and trails.
### Act IV: Mount Olympus (Stage 11; Act IV phase 2, Oct 2026)

<!-- --- Act IV: Mount Olympus --- -->
The Pantheon Trial's art (GDD §15.0 "Mount Olympus art (Act IV phase 2)"), in the Republic's style above. The
gods and Zeus are bigger than any soldier (92–124 px; the colossal form 176) and wear the act's gold; Artemis, the
Amazon and the Gorgon are in the **figure-redesign style** (bust bounce in the walk, a 24-frame idle breathing
strip). Units and characters: `tools/gen_image.py` with `--ref art_source/pantheon/hero.png` (the pixel look) and a
crop of the concept lineup or the concept boss scene for the costume (prompts beside each source); Zeus's cast pose
and colossal form and the Oathbreaker's three skins are edits with the approved source attached. Conversion: a
pre-snap (alpha cut 230; lit skin to `skin` / `brown_light`; near-white, low-saturation pixels to the nearest marble
shade), then `prepare_sprite.py --ink-l 0.15` with explicit `--ramps`, `--no-levels` for Artemis, Poseidon, Zeus, the
Amazon and the Gorgon (their gold and skin). Fixes: Ares's dark red cloak re-snapped to the `grey` ramp before
conversion (never the Covenant's crimson; it also parts him from his bronze); the AI's navy rim around Zeus's three
sprites stripped and re-outlined in bronze ink, the stills dropped onto the bottom row. Obstacles are drawn on the
grid by `tools/olympus_props.py` (deterministic, no API image). 19 API images, about **$0.53**. **For the owner's
review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `pantheon/ares` | Ares, God of War (god, male): crested bronze Corinthian helmet with gold crest and eye slits, bronze armour, iron-grey cloak, a long spear held low for the charge, a round shield | 94x96 | legs walk (the spear tip rigid). Round 1 redo ("too dark, muddy, not bronze"): re-converted from the same source, no new image: warm pixels brightened (HSV value ^0.6), no skin pre-snap (it had caught the dark cuirass), `--ramps bronze,gold,grey,skin` with levels (no `brown`, which had made the armour mud), the cloak moved one shade down (grey_light -> grey, grey -> grey_dark); now mostly bronze / bronze_light |
| `pantheon/artemis` | Artemis, the Huntress (goddess, female, figure redesign, slim-thick and muscular since round 1): ponytail, silver crescent circlet, short white chiton with a gold belt, laced sandals, drawing a tall silver bow held far forward | 62x92 | legs walk (the bow's lower limb rigid) + bust (cols 23-37, rows 31-39, two lobes; round 1: the old box sat on her bow), idle breathing. Round 1 redo: new image (old source as reference), skin pre-snapped by hue (skin below hue 0.08, value >= 0.6; lit -> `skin`, shade -> `brown_light`, the muscle shading), `--no-levels --no-prune --ramps marble,skin,brown,gold`, the quiver's bone fletching -> marble_light |
| `pantheon/poseidon` | Poseidon, Lord of the Sea (god, male): sea-green hair and beard, gold crown, Aegean and sea-green robe, a gold trident | 68x100 | robe walk (the trident rigid) |
| `bosses/zeus` (+ `_cast`) | Zeus, King of the Gods: white hair and beard, gold laurel crown, glowing blue eyes, white toga with gold belt and hem, a thunderbolt at his side; `_cast` the bolt raised above his head (BossPoseData 1) | 88x124 / 100x128 | robe walk (the bolt rigid) |
| `bosses/zeus_colossus` | Zeus's true form: a marble giant veined with blue lightning, a cloud beard, gold crown and bands, lightning around one fist | 164x176 | legs walk |
| `pantheon/centaur_archer` | Centaur Archer (male): bronze cuirass and crested helmet, a bow drawn forward, a brown horse body mid-gallop | 54x60 | legs walk (front and back leg pairs) |
| `pantheon/amazon` | Amazon (female, figure redesign, a tall "muscle mommy" since round 1: broad shoulders, big arms, abs, thick thighs): Aegean-crested bronze helmet over long hair, bronze breastplate, Aegean war skirt, a double axe and a crescent shield | 64x70 | legs walk (the skirt's front flap rigid) + a **hip** bounce box (cols 18-37, rows 27-37: the owner liked her old idle jiggling the hips, kept on purpose), idle breathing. Round 3 ("jiggling side to side rather than up and down"): the box sways sideways (`bust_axis="x"`, one bell), the still unchanged. Round 1 redo: new image, 58 tall (was 54), skin pre-snapped by hue (below 0.068, sat 0.4-0.8: her tan skin sat next to the bronze and converted to it), `--no-levels --no-prune --ramps bronze,marble,aegean,skin,brown,gold` **Round 4** (owner: the narrow front flap hanging between her bare thighs read as a crotch): the still's war skirt now covers both thighs in clean pleats (`aegean` strips, `aegean_dark` every fourth column and on the shadow side) down to a flat `aegean_dark` hem at row 40, with an ink edge under it and open air between the legs below; the flap is gone. The idle and walk strips re-derived (the hip box still sways; the rigid part is only the hem's ink row 41). **Round 5** (owner: "skirt is way too long now; regenerate the figure: a muscle mommy with huge tits and hips and abs; bigger, just smaller than a boss"): a new image (`art_source/pantheon/amazon_r5.txt`, refs the Hero and the old source) at **70 px** (was 58; `SpriteData.HEIGHTS`), now 66x70: `pixelate_source.py` 70, the skin pre-snap (`amazon_presnap.py`), `prepare_sprite.py --ink-l 0.15 --no-levels --no-prune --no-cleanup --ramps bronze,marble,aegean,skin,brown,gold`, one despeck pass (`amazon_despeck.py`), then on the grid (`amazon_r5_fix.py`): the war skirt as one closed band from a bronze belt (rows 33-34) to mid-thigh, Aegean pleats flaring over the hips, a straight bronze hem across both thighs (row 42) with ink under it (row 43): no slit, flap or notch, checked in every walk and idle frame; a face (brow, one clear eye, mouth) and a six-pack. Rig: legs split at col 34, hip 44, the shield's foot rigid, the box sways sideways on the skirt over her hips (cols 21-45, rows 35-40, `bust_axis="x"`). 2 images, ~$0.066. **Round 6** (owner: "the skirt is too boxy... it should swish in front of her, and show off her thighs"): only the skirt of the round 5 still repainted on the grid (`art_source/pantheon/amazon_r6_skirt.py`; the shape after one image-tool edit of the round 5 source, `amazon_r6_skirt.txt`, used only as a guide, ~$0.023): two short side flaps flaring out from the belt, cut high (hems rows 39-41, rising toward their tips) so the thighs show, and a wide front panel (cols 26-41) hanging over the crotch to one rounded hem (row 46, below where the thighs part), ink under its six middle columns: no slit, gap, notch or point; pleats straight on the panel, fanning on the flaps. Rig: hip 42 (the thighs walk), the panel below the hip on per-column rigid rects, the hip box at 1 px (rows 35-38) and a new `swish` box (`walk_cycle.py`: a second sideways box, one frame behind the hips, walk and idle; cols 21-46, rows 35-45) so the skirt follows the hips and the hem flutters. Every walk and idle frame checked by script: under the drape where the thighs meet there is only ink, then the gap. **Round 7** (owner, round 6: "start again with fresh generation, go back to the first prompt... you're focusing too much on the skirt; the original style, just a bit stronger and more voluptuous; a bit scandalous"): rounds 3-6 dropped; a fresh image from her round 1 prompt (`art_source/pantheon/amazon_r7.txt`, the sex named; refs the round 1 source and Artemis): a little more muscle (shoulders, arms, abs), more curves (bust, hips, thighs), a daring but fully clothed outfit (a small bronze breastplate with cleavage, bare midriff, a short war skirt cut high on the thighs with a solid front), a smirk. 2 candidates, the stronger one kept (~$0.067). Converted by material, not through `pixelate_source.py` / `prepare_sprite.py` (both muddied her skin into the bronze again): `art_source/pantheon/amazon_r7_build.py` labels every source pixel with a palette colour by hue / saturation / value, takes each 70-row cell's majority (ink at 38% so the lines survive), then on the grid repaints the face (eye, nose, smirk), the belt and the skirt (pleats to a curved hem: the side tips high over the hips at row 39, one straight solid front across both thighs at row 44, ink under it, open air between the thighs below; the back drape that hung between them removed), and places her like `prepare_sprite` (64x70). `art_check.py` 0 fail, 0 warning. Rig: hip 46 (under the skirt's hem, so the skirt rides with the body and never tears), legs split at col 33, the shield's foot rigid, the hip box swaying sideways on the skirt (cols 22-42, rows 36-42, `bust_axis="x"`, the owner-liked sway) and a 1 px `swish` box (rows 37-45) one frame behind; no separate bust bounce (one box per rig, the hips kept). Walk and idle frames checked at 12x: the skirt stays closed. |
| `pantheon/gorgon` | Gorgon (female, figure redesign, slim-thick and a bit chubby since round 1: round tummy, soft arms, very wide hips): living snakes for hair, pale green skin, gold eyes, white chiton with gold, a coiled serpent tail | 42x54 | robe (tail) sway + bust (cols 21-31, rows 17-21, two lobes; round 1: the old box sat too low), idle breathing. Round 1 redo: two new images (the first came back slim; the second asked for chubby with the first as reference), `--no-levels --ramps moss,marble,gold`; her face painted by hand (the conversion loses it in the snakes). Round 3 ("her face is so silly"): the face repainted by hand after a face-only regeneration (`art_source/pantheon/gorgon_r3.txt` -> `gorgon_r3_face_ref.png`, not converted: at 54 px it lost the face again, used as the painting reference): a tapering jaw and pointed chin over a neck, heavy-lidded gold_light eyes with ink pupils under dark brows raised at the outer ends, a nose bump on the right edge, brown_light lips with an ink smirk corner; body unchanged, strips rebuilt |
| `pantheon/moon_hound` | Hound of Artemis: a lean silver greyhound / saluki seen from the side, a long muzzle, folded ears, an Aegean collar | 56x30 | legs walk (hind legs left, forelegs right, the chin rigid). Round 1 redo ("looks strange"): a new image in side view (the Wolf of Rome's source as the pixel reference), `--no-levels --no-prune --ramps marble,grey,aegean`, the eye (aegean_light) painted by hand |
| `pantheon/sea_serpent` | Sea Serpent: Aegean scales, a pale belly, a finned head, reared over its coil | 46x64 | robe sway |
| `player/oathbreaker` | The Oathbreaker (male, a fallen demigod): cracked bronze laurel, violet hooded cloak over tarnished bronze, a staff with a stolen thunderbolt bound in violet cords | 52x58 | robe walk |
| `player/oathbreaker_hyper` / `_untouchable` / `_deathlord` | Gilded Oathbreaker (gold armour and laurel, sun emblem), Untouchable (white phantom with pale-blue trims), Deathlord (black iron and crimson, spiked crown) | 58 / 58 / 60 | walk through `SKINS` |
| `tiles/olympus_field`, `_grove`, `_terrace`, `_summit` | The four zone floors: trampled earth and dry grass; moss and cypress needles; marble courses; square marble slabs with dark gold joints | 128 | `make_tile.py` (`# --- Act IV: Mount Olympus ---`); the decals stay code-drawn |
| `obstacles/war_trophy_{s,m,l}` (round 1: bronze leaf heads on the crossed spears), `cypress_{s,m,l}`, `moon_shrine_{s,l}` (round 1: the crescent a shade lighter, `ice_light`), `fountain_{s,l}`, `broken_column_{s,m,l}`, `bronze_brazier_{s,l}` | A trophy post with a shield, crossed spears and a crested helmet; a dark cypress; a marble shrine with a silver crescent; a marble fountain basin; a broken fluted column; a bronze brazier with fire | footprint + 2 wide | circles, `tools/olympus_props.py` |
| `obstacles/chariot_wreck_{s,l}`, `balustrade_{s,m,l}`, `marble_block_{s,m,l}` (+ `_v`) | A bronze war chariot on its side with a broken wheel; a marble terrace balustrade; a fallen marble block with a gold band and a crack | long side + 4 x short; `_v` short + 2 wide | rects, `tools/olympus_props.py` |
| `icons/stolen_thunder`, `titans_blood`, `grounded_bones` | Violet badges: a bolt in a violet hand; a violet drop of blood with a spark; a ribcage under a lightning rod | 32 | symbol sheet split, each pixelated to 24 px on the frame of `machine_soul` |
| `icons/gigantomachy`, `ach_twilight_of_the_gods` | Gold badges: a titan's fist among bolts; a cracked laurel over a setting sun | 32 | on the frame of `ach_nothing_is_deathless` |

**Art review, round 1 redo (Oct 2026).** The owner's eight Olympus notes (GDD §15.0 "Act IV art review, round 1"):
the Amazon, Artemis and the Gorgon redrawn in the figure-redesign style with the requested builds and their bounce
boxes checked against the new pixels (the Amazon's on her hips, as the owner liked; Artemis's and the Gorgon's on the
bust), Ares re-converted bright (no new image), the Hound of Artemis regenerated, the Bronze Titan's walk rebuilt as a
stride (`walk_cycle.py` mode `stride`, under the Act IV foundation table), spear heads on the war trophies and a lighter
moon on the shrines (`tools/olympus_props.py`). 5 API images, about $0.16 (ledger). `art_check.py`: the Amazon,
Artemis and the hound pass every floor; Ares fails only Sanctum IV (+0.13), the Gorgon the March roads and the
Sanctum floors (as before; she only stands on Olympus).

Code-drawn on purpose: the lightning storms' circles (the wrath's), the thunderbolt beam and its lanes, the
trident in flight, the war-cry ring, the volley's aim fan, the gaze cone, the leap arc and landing circle, the
moonlit groves, Stolen Thunder's charging orb and its arcs.
### Act IV: the Asphodel Underworld (Stage 12; Act IV phase 2, Oct 2026)

<!-- --- Act IV: the Asphodel Underworld --- -->
The Act IV finale's art (GDD §15.0 "The Asphodel Underworld (Act IV phase 2)" and the rows after it), in the
Republic's style above: grey ash, marble shades, cold Aegean light and dark bronze, with Hades' black. Prompts
in `art_source/underworld/<id>.txt` (the unit template, the sex named), sources archived by `prepare_sprite.py`
under `art_source/<key>.png`, the raw sheets in `art_source/underworld/`. Pipeline: `tools/gen_image.py`
(`--ref` an approved sprite of the same tier: the Hero and the stage concept for Hades, the Hoplite for
Cerberus, the Lightning Abbess for the Ferrywoman, the Warrior and the Hoplite for the Myrmidon; each pose and
skin with its own approved base as the reference), then `prepare_sprite.py --ink-l 0.15` with explicit
`--ramps` (Hades `grey,marble,aegean,bronze`; Cerberus `grey,flame,crimson,marble,bronze`). With `--no-levels`
Hades' robe and Cerberus' fur went flat (every detail lost), with levels they came out mid-grey, so the levels
version was kept and its grey shifted one step darker by script (`grey_light` -> `grey`, `grey` ->
`grey_dark`; Cerberus only the light step). The Ferrywoman and her skins (figure-redesign style: hourglass
figure, fully clothed, bust bounce, idle breathing) went through `pixelate_source.py` first, then
`--ink-l 0.15 --no-cleanup`; the Deathlord skin's grey darkened one step the same way. Badges: two symbol
sheets split by empty columns, each symbol through `prepare_sprite.py --art-height 24` and set on the frame
of an approved badge (violet `abyssal_pact`, gold `tidecallers_host`; its inner 26 px cleared to the fill).
Floors: two textures through `make_tile.py` recipes (`# --- Act IV: the Asphodel Underworld ---`). Obstacles:
two prop sheets split by empty gaps, each prop converted at each size (circles: footprint + 4 wide; rects:
length + 2 wide, the end-on `_v` stretched to length + 14 tall). 16 API images, about **$0.35** (ledger).
art_check: every unit sprite passes height, alpha, palette and feet (the badges warn only that icons are not
in `SpriteData.HEIGHTS`, like every badge). **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `bosses/hades` | Hades (male): a tall gaunt god in a black robe and cloak, ashen face, cold blue flames over a dark bronze spiked crown, an upright bronze bident | 76x116 | robe walk (the bident rigid). The fork came out with three prongs: for review Round 1 redo (owner: cloak blends with the cloak behind): the inner robe (a hand-drawn polygon per pose) recoloured aegean_dark with aegean folds, an ink seam and a bronze_dark trim along its edge, the outer cape left grey; same on `hades_bident` and `hades_kneel`, the walk strip re-derived. **Round 3 redo** (owner: "just regenerate this"): regenerated as a new set (`art_source/underworld/r3/`, ref the Achilles sprite; the two poses with the new standing source as their reference): a dark Aegean-blue robe with bronze trim and belt in front of a deep violet cloak (owner's colour suggestion; only the cloak, so it reads against the blue robe), a crown of cold blue flame, a two-pronged bident. Converted with `--ramps aegean,violet,marble,bronze,ice --ink-l 0.15`, then the cloak one step darker at the top (`violet_glow` -> `violet`) and its inner `ink_violet` raised to `violet_deep` (so it does not vanish on the dark floors); the head (crown band and spikes, pale face, glowing eye, black hair and beard) hand-painted on the grid, as the converter merged the beard into the crown. Now 64x116; the walk strip re-derived (rigid bident cols 12-18). **Round 4 redo** (owner: "closer to the original, just with different colors that actually work together and show differences... the original head was better"): back to the round 1 sprites (76x116; poses, head, crown, face, hair and bident pixel for pixel) with only the cloth greys remapped by `art_source/underworld/r4/hades_recolour.py` (scheme C): a **bone-grey robe** (`bone_shade`, `bone_mid` folds) edged in `bronze` where it meets the cloak, under a **midnight Aegean cloak** (`aegean_dark`, `aegean` folds); the robe region per pose is round 2's, the hair round the face and the bident's iron shaft keep their greys. Chosen over scheme E (the round 1 charcoal robe under the same cloak: closer to the original but no value step between robe and cloak) for the warm/cool and light/dark split. The walk strip re-derived with the round 1 rig (bident cols 56-70); sources back to the round 1 ones. **Round 5 redo** (owner: "not very precise... just regenerate the same image with different colors... you're getting his beard"; scheme E's colours chosen): each round 1 source regenerated through the image tool as an EDIT of itself (`--ref` the round 1 source, prompts `art_source/underworld/r5/<key>.txt`: the identical figure, head, beard, crown and bident, only a charcoal-grey robe with a bronze trim and a midnight-blue cloak), converted with round 1's settings (`--ink-l 0.15 --ramps grey,marble,aegean,bronze`, levels on), then `art_source/underworld/r5/hades_shift.py`: whole-sprite colour steps only (round 1's grey one step darker, `aegean_light` -> `aegean`, so the cloak is `aegean_dark` with `aegean` folds) and the approved round 1 head pasted back pixel for pixel in fixed rectangles (flames, crown, hair, face, beard; the converter had redrawn the face and greyed the beard); no cloth masks. 76x116; the walk strip rebuilt with the same rig. art_check: like round 1 and scheme E it is darker than the Act I march / Sanctum floors (lightness FAIL there; it only appears on the Underworld, where it passes). ~$0.023 an edit. |
| `bosses/hades_bident` | His attack pose (BossPoseData 1): leaning into a sweep of the bident | 116x108 | the bident sweep's windup and the phase changes Round 3: regenerated with the new still (120x108): the same recolour steps and a hand-painted head; the fork has two prongs. Round 4: the round 1 pose recoloured the same way (scheme C). Round 5: an edit of the round 1 source the same way (116x108), the round 1 head pasted back. |
| `bosses/hades_kneel` | The ending: kneeling, head bowed, holding out his crown, the bident on the ground | 82x84 | drawn by `HadesHazards` for 14 s after his defeat Round 3: regenerated with the new still (92x84): head bowed with bare black hair and the crown held out in both hands; the same recolour steps, a hand-painted head, the fallen bident redrawn on the grid with two prongs (the AI drew three and a dark halo), and an aegean mid-tone between the robe's dark and light shades (reads on the dark floors). Round 4: the round 1 pose recoloured the same way (scheme C; the fallen bident keeps its greys). Round 5: an edit of the round 1 source the same way (80x84, 2 px narrower: the head and the held crown pasted from round 1 at a -2 px offset, the fallen bident's doubled `bronze_ink` outline thinned to one pixel). |
| `pantheon/cerberus` | Cerberus (male): a huge black hound with three heads in a fan, ember eyes, a mane of fire, spiked bronze collars, a flame tail | 94x92 | legs walk (hind / fore halves). The heads' hit bodies sit on its three heads (`head_offsets`); a dead head is a smoking stump drawn over it |
| `player/ferrywoman` | The Ferrywoman (female, figure-redesign style): hooded violet cloak, fitted grey corset dress, silver hair, violet eyes, a gold obol, a tall oar with a violet soul lantern | 44x56 | robe walk (oar rigid) + bust (cols 19-29, rows 18-25), idle breathing Round 1 redo: bust box moved 2 px right (cols 21-31). Round 2 redo: box widened 2 px left (cols 19-31), right edge kept. |
| `player/ferrywoman_hyper` / `_untouchable` / `_deathlord` | Golden Ferrywoman (gold trim and circlet), Untouchable (white phantom, soul-teal lantern), Deathlord (black iron, spiked crown, crimson lantern) | 40x56 / 40x56 / 42x58 | walk + idle through `SKINS` with their own oar and bust boxes (`SKIN_FIX`) Round 1 redo: the Deathlord skin's bust box moved 2 px right (cols 20-29). Round 2 redo: the Deathlord box widened 4 px left (cols 16-29). |
| `summons/myrmidon_shade` | Myrmidon Shade: a skeleton hoplite, grey crested helmet, skull face with soul-teal eyes, a round grey shield with a soul-teal boss, an upright spear | 26x46 | legs walk (spear and shield rigid) Round 1 redo (owner: body too detailed): torso, arm, tunic and legs repainted as big flat shapes (lit left, shadow right, one ink outline); the head, spear head and shield are the approved pixels. **Round 3 redo** (owner rejected the flat round 2 body: "more like the original"): restarted from the round 1 pixels (commit 16ea7aa) and only cleaned gently: colour islands of 1-2 px in the body took their neighbours' majority colour (7 islands; head, spear and shield untouched), the original shading and outline kept; the walk strip re-derived. **Round 4 redo** (owner: "regenerate from the start... from the original prompt again"): regenerated from the round 1 prompt (`art_source/underworld/r4/myrmidon_shade.txt`, the owner's first note added: a simple body, the detail on the head and the shield; refs the Warrior and the Hoplite), through `pixelate_source.py` and `prepare_sprite.py --ink-l 0.15 --ramps bone,grey,soul,brown --no-prune`; the crest and the Corinthian bone face plate with two soul-glow eyes hand-painted on the grid (`myrmidon_shade_head.txt`), as the converter blurred the face. Now 24x46; rig: spear (cols 0-4, to row 37) and shield rigid. **Round 5** (owner: "face looks a bit silly but the rest is fine"): only the face repainted on the grid (`art_source/underworld/r5/myrmidon_shade_face.py`, 36 px in cols 8-14, rows 11-17): the helmet's cheek guards close round a short skull plate (bone brow, two `ink_green` sockets with `soul_glow` eyes, a nose hole, teeth, the chin rim), the Legion of Tartarus's treatment; every other pixel is round 4's. The walk strip rebuilt (only those columns differ). |
| `summons/legion_of_tartarus` | Legion of Tartarus: bigger, darker, a glowing soul-teal spear head and a skull on the shield | 32x54 | legs walk Round 1 redo (same note): body repainted as flat shapes; the head, spear head and shield kept. **Round 3 redo** (same note): restarted from the round 1 pixels and cleaned the same gentle way (13 islands of 1-2 px; head, spear and shield untouched); the walk strip re-derived. **Round 4 redo** (same note): regenerated from its round 1 prompt (`r4/legion_of_tartarus.txt`, "grander" added) with the new Shade source as the reference: a bigger, darker hoplite with a bone-striped crest, a glowing soul-teal spear head and a skull on a larger shield. Converted like the Shade; the face plate and the shield skull hand-painted (`legion_of_tartarus_head.txt`, `_emblem.txt`), the body's `grey_light` one step darker (the shield and rim light kept; two steps failed the +0.15 floor check on Sanctum IV). Now 36x54; rig: spear (cols 2-5, to the ground) and shield rigid. |
| `icons/river_styx`, `ferrymans_toll`, `myrmidon_shade`, `myrmidon_oath` | Violet badges: the black river with a violet current; an obol on its cord over an oar; the shield and the skull helmet; spear, shield and bone hand | 32 | |
| `icons/lethes_flood`, `legion_of_tartarus`, `ach_empty_throne` | Gold badges: two crossing rivers; the skull shield with a gold rim; the empty black throne with the crown at its foot | 32 | |
| `tiles/underworld_asphodel`, `_styx`, `_hall`, `_throne` | Grey ash; dark wet banks; cracked marble flags (32 px staggered); obsidian slabs (64 px) with dark bronze joints | 128 | `make_tile.py`; the asphodel flowers, the Styx and the floor details are code-drawn (`UnderworldGround`, `UnderworldGlyphs`) |
| `obstacles/dead_poplar_{s,m,l}`, `styx_rock_{s,m,l}`, `judges_column_{s,m,l}`, `obsidian_spire_{s,l}`, `soul_brazier_{s,l}`, `ferry_post_{s,l}` | A dead grey tree; a black wet boulder; a broken marble column; an obsidian spike; a bronze brazier with a cold flame; a mooring post with a lantern | footprint + 4 wide | circles |
| `obstacles/grave_stele_{s,m,l}` (+ `_v`), `judgement_bench_{s,m,l}` (+ `_v`) | A low marble grave slab with asphodels; the judges' marble bench with bronze trim | length + 2 wide; `_v` 26 / 28 wide | rects |

Code-drawn on purpose: the River Styx (bands of black water, banks and drifting glints), the River Styx spell's
rivers, Hades' footprints, the Helm's shimmer, his sigils over marked summons, the gods' shades (the god's own
art tinted pale when it exists, else the shade glyph scaled up), the crown at the finale, Cerberus's fire breath
glow and smoking stumps, the Myrmidon wall's ring. The Shade Hoplite and the Tartarus Warden wear the Hoplite's
art tinted pale / dark (no art of their own).
### Act III AoE art (the Empire's warnings, beams and zones; Oct 2026)

GDD §15.0 "Act III AoE art" (audit `docs/art/audit/act3.md` section A, branch `audit/act3-art`). Every
piece is **procedural pixel art** in the locked palette, made by `python3 tools/empire_aoe_art.py`
(deterministic; `--review DIR` writes the 1× / ×4 / GIF review images) and drawn by `EmpireFx`
(`scripts/fx/empire_fx.gd`; keys and numbers in `scripts/data/empire_fx_data.gd`), always with the code
shape as the fallback. It follows the Act I rules above (band pieces at 1:1 on the exact hit edge, fills
as clipped 2 px rows, beam bodies scrolled at the beam's real width, no stretched big images, textured
rects only) and adds the **Empire's own visual language**, so an Act III warning never reads as the
Covenant's:

- **Colour:** chrome and signal ramps; warning red and hard amber for danger, **cyan-white**
  (`chrome_glint`) for targeting (ticks, scan line, brackets, crosshair, uplink); white-hot `signal_glow`
  cores. The Death Ray stays the necromancer's violet; the finale's binding his soul green.
- **Motifs:** hazard stripes in the band (period 5, seamless), a **hex grid** fill (14 × 24 seamless),
  a scan-line timing front, **targeting brackets** closing from 1.45 × to the area's bounding box with
  the timing, hex-segmented shock rings, sparks and chrome shards.
- **Where:** every Act III circle / lane / cone warning, including the shared Effect telegraphs on an
  Act III stage (`EffectManager.empire_look`).
- **Alpha:** warning pieces, stills and strips are binary; glows, the gate field, the furnace haze and
  the pulse wake use 2-4 stepped alphas; `storm_veil` / `storm_grit` are smooth grey masks tinted with
  the dust colour (not pixel art, like `holy/soft_disc`).

| Key | Subject | Art px | Drawn by |
|---|---|---|---|
| `empire_fx/edge`, `edge_tick` | Warning band piece (signal ink, red, two rows of amber hazard stripes, red, dark), and with a cyan-white tick into the danger (every other piece) | 10 × 6 / 10 × 10 | every Empire circle, lane, cone, square, sector |
| `empire_fx/front`, `hex`, `chevron`, `target`, `bracket` | Scan-line front; seamless red hex grid with amber nodes; double chevron; crosshair; targeting box corner | 8 × 3, 14 × 24, 13 × 13, 15 × 15, 9 × 9 | `EmpireFx.telegraph_circle()` / `_line()` / `_cone()`, `square()`, `sweep()`, `build_frame()` |
| `empire_fx/uplink` | Orbital uplink column (stepped alphas, base on the bottom row) | 16 × 96 | `EmpireFx.orbital()`: the last 28 % of a strike |
| `effects/empire_blast`, `_red`, `_chrome` | Strike / slam landing: flash and lens glint, hex-segmented shock ring (ends at 0.84 of the half: fill 1.2), sparks, shards, smoke ring | 8 × 128 | `EffectManager.impact(..., anim)` at the Act III sites |
| `effects/empire_boss_death` | An Empire boss falls: red blast, four amber secondary blasts, cyan-white shock (0.91 of the half: fill 1.1) | 10 × 256 | `EnemyDirector.on_enemy_killed()` on Act III stages |
| `empire_fx/ray_body`, `ray_glow`, `ray_tip` | Death Ray soul laser body (scrolled, at the beam width), stepped glow and afterglow, tip burst | 16 × 10, 8 × 12, 4 × 24 | `EmpireFx.death_ray()` |
| `empire_fx/laser_body`, `laser_glow`, `laser_warn`, `laser_cap` | Laser grid body (= its 10 px width), red glow, armed sight dash, emitter (armed / firing) | 16 × 10, 8 × 12, 8 × 3, 2 × 16 | `EmpireFx.laser()`, `laser_band()` |
| `empire_fx/lance_body`, `lance_glow`, `lance_tip` | Judgment Lance body (= its 30 px width), amber glow, head | 16 × 30, 8 × 16, 4 × 32 | `EmpireFx.lance()` |
| `empire_fx/gate_wall`, `gate_glow`, `gate_post`, `gate_cable` | Shield Gate hex energy wall (= its 18 px), outer glow, chrome end emitter, power cable | 22 × 18, 8 × 28, 22, 8 × 5 | `EmpireFx.gate_wall()`, `gate_cable()` |
| `empire_fx/belt_68`, `_72`, `_80` | Conveyor belt repeat per belt width: rails and rollers, rubber, slats, dim amber chevrons (112 px holds 4 chevrons and 7 rollers) | 112 × W | `EmpireFx.belt()`: one scrolled rect per belt |
| `empire_fx/furnace_slag`, `furnace_embers`, `furnace_molten_0..2`, `furnace_rim`, `furnace_warn`, `furnace_haze`, `furnace_flame` | Channel slag, glowing seams, molten metal (3 flicker frames), iron rim, hazard stripes, heat haze, flame tongue | 64 seamless; 12 × 3, 10 × 2, 8 × 6, 4 × 9 × 14 | `EmpireFx.channel()` (world-anchored) |
| `empire_fx/storm_veil`, `storm_grit` | Scrap storm veil (hole at 0.2393 of the half = the 230 px clear radius) and drifting grit | 256, 256 | `EmpireFx.storm()` |
| `empire_fx/jug_flame_0..2` | Juggernaut flame billows | 4 × 10 / 16 / 22 | `EmpireFx.jug_flame()` |
| `empire_fx/static_edge`, `spark` | Arc Engineer field rim; static spark | 10 × 5, 2 × 7 | `EmpireFx.jam_field()` (arming), `static_field()` (its armed suppression zone, `SuppressionField`) |
| `empire_fx/mortar_shell`, `lock_open`, `lock_locked`, `pylon_stump` | Mortar shell; Lock-On reticles (red / white-hot blink); fallen pylon decal | 2 × 10, 2 × 35, 2 × 29, 30 × 14 | `EmpireShots`, `LockOn`, `WastesDirector` |
| `empire_fx/shock_edge`, `pulse_front`, `pulse_charge`, `binding_edge`, `hangar_door` | Deus footfall shock; overload pulse front (= its 26 px, middle row on the radius); charge ring; soul-binding chain; hangar door (shut / opening / open) | 10 × 4, 12 × 26, 8 × 3, 10 × 5, 3 × 36 × 24 | `DeusHazards`, `CitadelGlyphs` hooks |
| `empire_fx/magnet_edge`, `claw` | Motherboard magnet ring piece; crane claw (open / clamped) | 10 × 3, 2 × 16 | `AssemblyGlyphs` hooks |

Left as code (low in the audit, or the intended look): Lock-On laser lines, pylon reach ring, repair
arcs, Aegis shield arc, Spotter glow, Valkyrie's jets and blade storm, pop / slash / spawn rings, shot
tracers. Review folder for the owner: `docs/art/act3_aoe_review/` (`manifest.json`).
### Act III missing sprites (owner report, Oct 2026)

The Act III art audit (`docs/art/audit/act3.md`, branch `audit/act3-art`) found two kinds and four projectile
keys without a PNG (`[art-miss]` totals in the audit), the Scrap Wastes' stage card on a borrowed floor, and
a few optional shot looks. Everything below is wired through the keys the code already asked for
(`SpriteBank` / `EnvironmentArt`); the code drawings stay as fallbacks. Visual only. **The Kill-Drone** is the one
AI image (`tools/gen_image.py`, the template above, `--ref` the Scout Drone's source; one image, $0.024, ledger
`empire/kill_drone`; prompt `art_source/empire/kill_drone_prompt.txt`, source `art_source/empire/kill_drone.png`):
`pixelate_source.py` to 30 rows, `prepare_sprite.py --no-levels --no-prune --ink-l 0.15` (cleanup on), then by
hand: the bone / skin / brown / amber specks the AI's red plate and arms left snapped to the `signal` ramp,
a clean 7 x 7 lens ring (ink, dark red, red, a 2 x 2 hot core) drawn on the grid, two empty rows on top for the hover
bob. Every other sprite is **hand-built on the grid** by `tools/act3_projectiles.py` (letter maps and small
procedural shapes, exact palette colours, one-pixel ink outline in the part's own ramp; rebuild with
`python3 tools/act3_projectiles.py [id]`): no generation, so each pixel is intentional. Flat sprites face +x;
`SpriteBank.draw_flat_frame()` draws one frame of a strip. **For the owner's review**
(`docs/art/act3_sprites_review/`).

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `empire/kill_drone` | Kill-Drone (the Purge Protocol Reckoning kind, a machine): the Scout Drone's chrome disc and two flat rotors made heavy: a broad warning-red armour plate across the top, one big red lens with a hot core, two gun barrels under the body | 70x32 | hover (`_walk`, rig `hover` bob 2); `HEIGHTS` 32 |
| `projectiles/trojan_rocket` | Swarm Rocket: a chrome missile with swept warning-red fins and band, an amber warhead light | 24x12 | `FLAT_SIZES` 24; drawn turned along its heading by `RocketKit` |
| `projectiles/trojan_rocket_flame` | its exhaust: a tapering amber / red flame, glow core | 3 x 12x8 | strip, `RocketKit` picks the frame from its age (50 ms) |
| `projectiles/scrap_drone` | Scrap Swarm drone (also the Rust Prophet's): a bone skull-body with one violet eye and a scrap jaw, two grey rotor discs | 2 x 22x14 | rotor strip, `ScrapSwarm.ROTOR_FPS` 14 Hz from game time; the player's violet and bone, no Empire colour |
| `projectiles/scrap_drone_bright` | the Deathless Swarm kill drone: the same with violet rotors and a flare eye | 2 x 22x14 | replaces the old violet ring |
| `projectiles/scrap_bolt` | a bone shard wrapped in violet with a violet trail | 14x6 | `Projectile.Kind.SCRAP_BOLT` |
| `projectiles/iron_shell` | an Iron Revenant cannon shell: an iron ogive shell with a driving band, a soul-teal fire trail | 20x8 | `Projectile.Kind.IRON_SHELL` |
| `projectiles/soul_round` | a Grave Gunner's rifle round: a soul-teal fire slug with a bright core | 12x5 | `Projectile.Kind.SOUL_ROUND` |
| `projectiles/empire_rail` | the Lock-On rail slug: a warning-red needle, amber sleeve, white-hot core | 46x7 | `SHOT_STYLES` rail `art`; its head on the shot |
| `projectiles/empire_missile` | Deus Ex Machina's missile: chrome body, red fins and band, amber nose, a static exhaust | 26x10 | `SHOT_STYLES` missile `art` |
| `projectiles/mortar_shell` | the Mortar Walker's lobbed shell: a chrome bomb, red band, amber fuse light | 12x12 | `SHOT_STYLES` mortar `art`, drawn at the lob's height |
| `projectiles/deus_missile` | the Deus Revenant's missile (the undead's): iron body, bone nose, soul-teal exhaust | 26x10 | `HordeHazards` draws a boulder with source `deus_revenant_missile` as it, nose along its arc |

The Scrap Wastes' stage-select card is data only (`FrontDoorData.VIGNETTES["wastes"]`, no new PNG): `tiles/wastes_slag`,
`obstacles/titan_hull_s`, `wreck_plate_s`, `slag_mound_m`, `tank_trap_s`, `empire/signal_pylon`, `empire/aegis_bot`,
`empire/scout_drone`, `summons/warrior` + `archer`, and `bosses/kestrel_aim` facing them. The small tracers (zap, round,
arc bolt, rivet, turret bolt, chaingun), Kestrel's decoy projectors and the sentry / turret barrels stay code
(audit: acceptable / low).

### Act V: the Shogunate of the Rising Sun, the shared kinds (foundation, Oct 2026)

<!-- --- Act V: the Shogunate of the Rising Sun --- -->
The Shogunate's style for the stage agents (GDD §15.0 "Act V art: the shared kinds"; `docs/act5/PROPOSAL.md`): **red lacquer**
armour (the new `lacquer` ramp: harder and warmer than the Covenant crimson), **steel** (the existing `grey` ramp), **indigo**
cloth (the new `indigo` ramp; its light shade is the rim that keeps a ninja readable on a dark ground), **sakura pink** (the new
`sakura` ramp: petals, trims; the oni's ivory horns use `sakura_light`), and **gold** for the sun and crests (the existing
gold keeps its meaning). Hard, clean silhouettes with one big shape each (the ashigaru's conical hat and long yari, the samurai's
crescent crest and broad shoulder plates with the hand on the hilt, the gunner's level arquebus, the ninja's masked crouch, the
onryo's curtain of black hair, the oni's horns and spiked kanabo). Never the player's violet, the undead's bone or teal or the
Covenant's crimson. `prepare_sprite.py` folder `shogunate/`: ramps lacquer, indigo, sakura, grey, gold, skin, brown. Concept
references: `art_source/concepts/act5_lineup.png` (costumes); prompts beside each source in `art_source/shogunate/<id>.txt`
(the Act IV template, the sex named).

Generated with `tools/gen_image.py` (`--ref` the Hoplite's source for the pixel look plus a crop of the concept lineup for the
costume; the Shade of the Dead's source for the onryo). Pipeline: `prepare_sprite.py` straight on the source with explicit
`--ramps` and `--ink-l 0.22` (0.15 for the ninja, whose indigo cloth must stay cloth; 0.3 and `--ramps marble,indigo` for the
onryo, the Republic's marble giving the ghost a pale white; the lantern `--ramps grey,gold`), then scripted palette-colour
touch-ups (`art_source/shogunate/touchups.py`, run by `build.sh` right after a fresh conversion: it is not idempotent):
holy_white / bone remapped to grey_light (sakura_light for the oni's horns), the samurai's two crest prongs joined into a
crescent, the gunner's helmet one indigo shade down, the onryo's hair filled with indigo_dark inside its ink edge and two empty
rows added on top for the hover bob, the lantern's window recoloured gold for the lit state. Walk strips by `walk_cycle.py`
(rigs under `# --- Act V: the Shogunate of the Rising Sun (the shared kinds) ---`). 7 API images, about $0.20. `art_check.py`: 0
warnings; the only failure is lightness on Sanctum IV's light floor (the dark indigo ninja and gunner, the red kinds nearly),
where Act V units never stand. **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `shogunate/ashigaru` | Ashigaru (fodder, male): jingasa hat, red do over an indigo jacket, a very long yari | 22x46 | legs walk (hip 39; the yari, cols 3-5, rigid). Body ~32 |
| `shogunate/samurai` | Samurai (soldier, male): black-and-red lacquered o-yoroi, kabuto with a gold crescent crest, hand near the hilt of the katana | 32x56 | legs walk (hip 40). The Draw telegraph is code |
| `shogunate/teppo_gunner` | Teppo Gunner (ranged, male): indigo jacket, red lacquer chest plate, a level arquebus, a smouldering match cord | 62x46 | legs walk (hip 33; the gun rides with the body) |
| `shogunate/ninja` | Ninja (soldier, male): indigo-black hood and face wrap, a crouch, a steel shuriken | 36x40 | legs walk (hip 28) |
| `shogunate/onryo` | Onryo (night fodder, female ghost): pale white burial kimono, long black hair over the face, reaching arms, a wisp tail | 38x36 | hover (the whole ghost bobs 2 px; two empty rows on top). No bust rig |
| `shogunate/oni` | Oni (night heavy, male): red-skinned ogre, ivory horns, tiger-skin loincloth, an iron kanabo held low | 64x80 | legs walk (hip 66, spread 3, lift 3; the club rides above the hip) |
| `obstacles/stone_lantern` (+ `_lit`) | A stone toro: base, post, lantern box with a window, wide roof, finial; `_lit` has a warm gold window | 28x40 | no strip; the glow pool is code |

### Act V: Castle Kurogane (Stage 14; Act V phase 2, Oct 2026)

<!-- --- Act V: Castle Kurogane --- -->
Castle Kurogane's art (GDD §15.0 "Castle Kurogane (Act V phase 2)" and the rows after it), in the Shogunate's style
above: black and red lacquer, steel, indigo and gold, with the castle's grey stone, white plaster and dark timber.
Prompts in `art_source/kurogane/<id>.txt` (the Act V unit template, the sex named in every figure prompt: all male
here), raw API images in `art_source/kurogane/raw/`, converted sources archived by `prepare_sprite.py` under
`art_source/<key>.png`. Generated with `tools/gen_image.py`: `--ref` the Samurai's source for the pixel look plus a crop
of `act5_lineup.png` (the banner bearer, for the Hatamoto) or of `act5_boss.png` (the cavalry for the Kiba-musha and the
General; the Shogun on his platform for the Shogun); the Shogun's source for his duel pose; the Oathbreaker's and the
Samurai's sources for the Ronin Revenant, then his source for his three skins; the stone lantern for the props and
the platform; `ilion_gate` for the floors; `river_styx` / `lethes_flood` for the badges. Pipeline:
`prepare_sprite.py` straight on the source with `--ramps lacquer,grey,gold,skin,brown,sakura` (no indigo: with it
the black lacquer came out navy blue) and `--ink-l 0.15`; `--no-levels` for the Hatamoto and the Shogun's two poses
(levels turned the black armour grey-blue), levels on for the two horsemen (their dark horses failed the lightness
check without); the Ronin `--ramps violet,lacquer,grey,gold,skin,brown --ink-l 0.2`, his Hyper skin `--no-levels`, the
Untouchable `--ramps marble,soul,grey,skin`, the Deathlord `--ramps crimson,grey,lacquer,gold,skin`. Prop and badge
sheets split by `art_source/kurogane/split_sheet.py` (connected pieces), the props converted at each size by
`make_props.py` (circles: footprint x 2 + 4 wide; rects: length + 2 wide, the end-on `_v` length + 14 tall; the
command platform's stray palisade cut away by hand), the badges by `make_badges.py` (each symbol at 24 art px on the
frame of an approved badge: violet `abyssal_pact`, gold `tidecallers_host`). Floors: `make_tile.py` recipes
`kurogane_*` (the bailey and courtyard sources came back nearly transparent and are stored opaque; the keep as a
staggered-plank layout). Walk strips by `walk_cycle.py` (rigs under `# --- Act V: Castle Kurogane ---`; the Ronin's
skins through `SKINS`; no bust rigs: every figure here is male). The Hatamoto's banner is white on purpose: the game
multiplies his sprite by his regiment's banner colour (HatamotoKit). 18 API images (2 prop sheets, 2 badge sheets),
about **$0.37** (ledger). `art_check.py`: every sprite passes height, alpha, palette and feet; lightness passes on the
dark floors and fails only on the light Act I March road / Sanctum floors (the Shogun, his duel pose, the General,
the Kiba-musha), where Act V units never stand. **For the owner's review.**

| Key | What it is | Art px | Notes |
|---|---|---|---|
| `shogunate/hatamoto` | Hatamoto (elite banner guard, male): black lacquer laced red, a low kabuto with a gold crest, a red sash, a short yari, a tall plain white sashimono banner on his back | 32x72 | legs walk (hip 61; the yari, cols 22-28, rigid); the banner takes the regiment's colour by tint |
| `shogunate/kiba_musha` | Kiba-musha (mounted samurai cavalry, male): crescent kabuto, black-and-red lacquer, a levelled yari, a brown war horse with a red lacquer saddle cloth | 74x60 | legs walk (hip 46; hind legs left, forelegs right); the charge lane is code (EffectManager.telegraph_line) |
| `shogunate/general_left` | The General of the Left (miniboss, male): antler crests, a red menpo, gold-trimmed black lacquer, a red war cloak, a levelled naginata, an indigo sashimono, a huge black war horse in red barding | 110x100 | legs walk (hip 77) |
| `shogunate/command_platform` | The Shogun's command platform: a timber war platform with a red lacquered railing, gold post caps, a stair and four nobori (black and white, gold circles) | 106x124 | drawn by BossShogun under his feet (ShogunData.PLATFORM_DECK_RISE) and left where it stood |
| `bosses/shogun` | Shogun Kurogane (male): black-and-gold o-yoroi, a huge gold crescent crest, black beard, crimson cloak, an open black-and-gold war fan raised high | 116x116 | legs walk (hip 94) |
| `bosses/shogun_duel` | His duel pose (BossPoseData 3): a low iai stance, the long blade drawn level, the cloak flaring | 120x100 | the leap down and every cut he stands to draw; the white lines are DrawCuts' |
| `player/ronin_revenant` | The Ronin Revenant (male): a battered straw sandogasa, a pale face with violet eyes, a tattered violet kimono and dark hakama over cracked black lacquer plates, a red sash, a katana, a small black banner with a violet skull on his back | 32x58 | robe walk (hip 50, hem sway) |
| `player/ronin_revenant_hyper` / `_untouchable` / `_deathlord` | Gilded Ronin (gold kimono, gilded hat and banner), Untouchable (white phantom with soul-teal trims), Deathlord (black iron kabuto with a spiked crest, crimson) | 32x58 each | walk through `SKINS` (derived rig) |
| `tiles/kurogane_bailey`, `_gatehouse`, `_courtyard`, `_keep` | Trampled earth; fitted granite paving; raked gravel; dark floorboards (staggered planks) | 128 | mean L 0.22 / 0.26 / 0.26 / 0.25 |
| `obstacles/castle_wall_{s,l}` (+ `_v`), `palisade_gate_{s,l}` (+ `_v`) | A length of castle wall (fitted grey stone, white plaster band, dark tiled cap); a timber gate fence with iron studs and a red beam | 64 / 86; `_v` 22 / 30 wide | rects, H + V |
| `obstacles/black_pine_{s,l}`, `garden_rock_{s,l}`, `sake_barrels_m`, `taiko_drum_m` | A twisted garden pine; a mossy boulder; three straw-wrapped sake barrels; a red war drum on its stand | footprint x 2 + 4 wide | circles; the stone lanterns are the shared Act V toro |
| `icons/banner_of_the_dead`, `warlord_seal`, `unbending` | Violet badges: a black war banner with a violet skull on a bone pole; a red lacquer seal with a violet skull; a bone forearm breaking a katana blade | 32 | |
| `icons/hundred_banners`, `ach_regiments_broken` | Gold badges: three banners in a fan; a snapped banner over a gold war fan | 32 | |

Code-drawn on purpose: the Banner of the Dead's planted banners and aura (rects and a texture disc), the regiments'
banner colours (a tint), the charge lanes, the Draw lines of the Shogun's iai and triple cuts (DrawCuts), the war fan's
flourish, the fallbacks (KuroganeGlyphs).
