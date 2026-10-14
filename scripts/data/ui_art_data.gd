## UiArtData: numbers of the pixel-art UI kit and the title logo (art pass,
## docs/art/ART_BIBLE.md "UI kit and title logo"). The PNGs live in
## res://assets/ui/ and are drawn by tools/ui_kit.py from the locked palette;
## UiTheme turns them into 9-slice StyleBoxTextures (and keeps its code
## StyleBoxFlat look as the fallback when a PNG is missing). Data only, no logic.
##
## 9-slice contract with tools/ui_kit.py (it parses SLICE from this file): a
## frame PNG "<kind>_<accent>_<state>.png" is (2 * SLICE[kind] + CENTER) texels
## square; its outer SLICE[kind] texels on each side are the border (corners
## kept, edges stretched), the CENTER texels in the middle are the flat fill.
## 1 texel = 1 layout px (the 1280x720 grid, like every sprite), drawn sharp
## through the sharp-pixel shader at any window scale.
class_name UiArtData
extends RefCounted

## Folder of the UI kit PNGs and the logo.
const ROOT: String = "res://assets/ui/"

## Texels (= layout px) between the two 9-slice margins of every frame PNG
## (the stretched centre fill).
const CENTER: int = 4  # TUNING (not in GDD) art pass UI kit

## 9-slice margin (texels = layout px, all four sides) per frame kind. The
## border art of a kind lies inside this margin.
##   button: buttons and selectable tiles (2 px bevelled ring, chamfered corners).
##   panel : panels and windows (double ring with bone corner studs).
##   card  : level-up cards (panel ring with bone corner brackets).
##   focus : keyboard / controller focus ring, drawn over a focused control and
##           FOCUS_EXPAND px outside it (soul-teal ring with corner brackets).
##   slot  : HUD ability slot socket (recessed grey ring).
##   bar   : HUD bar frame (transparent centre: the code fill shows through).
##   tip   : tooltip panel (bone ring).
##   scroll: scroll bar track; grab: its grabber.
##   line  : horizontal separator (3 px tall, stretched sideways).
const SLICE: Dictionary = {
	"button": 5,  # TUNING (not in GDD) art pass UI kit
	"panel": 7,  # TUNING (not in GDD) art pass UI kit
	"card": 10,  # TUNING (not in GDD) art pass UI kit
	"focus": 6,  # TUNING (not in GDD) art pass UI kit
	"slot": 4,  # TUNING (not in GDD) art pass UI kit
	"bar": 3,  # TUNING (not in GDD) art pass UI kit
	"tip": 4,  # TUNING (not in GDD) art pass UI kit
	"scroll": 3,  # TUNING (not in GDD) art pass UI kit
	"grab": 3,  # TUNING (not in GDD) art pass UI kit
	"line": 2,  # TUNING (not in GDD) art pass UI kit
}

## Layout px the focus ring is drawn outside the focused control (its
## StyleBoxTexture expand margin), so it frames the control's own border.
const FOCUS_EXPAND: float = 3.0  # TUNING (not in GDD) art pass UI kit

## Layout px the HUD slot socket extends outside the 42 / 32 px icon square
## it holds (IconGlyph.slot_frame).
const SLOT_EXPAND: float = 2.0  # TUNING (not in GDD) art pass UI kit

## --- Pixel fonts (owner choices, GDD §15.0 "Pixel fonts") ---------------
## Jersey 10 is a true grid pixel font: every outline point sits on a
## 75-unit grid of its 1400-unit em, so one font pixel = em / 18.67 and its
## capitals are 10 font px tall. Rasterised in mono at 19 px, one font pixel
## is 1.018 texels, so every glyph (well under 27 font px) lands exactly 1
## texel per font pixel (a scratch glyph-topology check over sizes 9-48 found
## every digit, letter, %, + and = clean from 18 px up; at 9-17 px 3, 5, 6, G
## and S break). So:
##   * the font is imported mono, unhinted, without subpixel positioning and
##     with oversampling 1.0, and UiTheme draws it from ONE raster at
##     PIXEL_EM px (FontFile.fixed_size), scaled to each label's size;
##   * labels only use the sizes in PIXEL_SIZES (the em x1, x1.5, x2, x3), so
##     a font pixel is a whole (or half) number of layout px, and the
##     sharp-pixel shader on every Label, Button and HUD widget
##     (UiTheme._SharpHook, SpriteBank.apply_sharp()) keeps the pixels crisp
##     and even at any window scale, like the sprites;
##   * the sizes in the UI scripts are still the ones they were written for
##     (a 0.70-em cap height); UiTheme.font_px() turns each into the PIXEL_SIZES
##     entry nearest the same cap height (x CAP_MATCH), so the hierarchy holds.
## Long descriptions use Jersey 10 too, at the BODY tier (owner: "Jersey,
## let's keep it cohesive"; UiTheme.body()): no smooth font is left in the UI.

## Jersey 10: the HUD, numbers, headings, labels, buttons, card names and the
## in-world damage numbers (the theme's default font).
const FONT_PIXEL: String = "res://assets/fonts/Jersey10-Regular.ttf"

## Raster size (px) of Jersey 10: its pixel em (18.67 px) rounded, where every
## glyph is drawn exactly 1 texel per font pixel.
const PIXEL_EM: int = 19  # TUNING (not in GDD) font pass: measured, pixel-exact

## The only Jersey 10 sizes (layout px) used: the raster x1, x1.5, x2 and x3
## (1, 1.5, 2 and 3 layout px per font pixel). x1 is the smallest: shrinking
## the raster would blur it.
const PIXEL_SIZES: Array[int] = [19, 28, 38, 57]  # TUNING (not in GDD) font pass

## Line slack (px at the 19 px raster, per side) trimmed from Jersey 10's
## line height: its 1500-unit line box (20 font px) holds ASCII glyphs that
## span only 1050 units (14 font px), so each line would be ~45% taller than
## its text; trimming 2 px top and bottom keeps 2 px of leading.
const LINE_TRIM: int = 2  # TUNING (not in GDD) font pass

## Requested size -> Jersey size factor that keeps the cap height the UI
## scripts were sized for (their sizes assume caps of 0.70 em; Jersey's caps
## are 750 / 1400 = 0.536 em: 0.70 / 0.536 = 1.31).
const CAP_MATCH: float = 1.31  # TUNING (not in GDD) font pass

## Jacquard 24: zone and event banners (the HUD event banner, the stance
## banner, the synergy / evolution announcement).
const FONT_BANNER: String = "res://assets/fonts/Jacquard24-Regular.ttf"

## Jacquard 24's pixel em: its outlines sit on a 30-unit grid of a 1290-unit
## em, so 43 px = 1 font px per layout px, its only clean size short of 86.
const BANNER_SIZE: int = 43  # TUNING (not in GDD) GDD §15.0 "Pixel fonts": whole multiples of the 43 px em

## Width (layout px) at which a Jacquard event banner wraps (between the
## top-left HP block and the top-right modifiers block).
const BANNER_WRAP: float = 680.0  # TUNING (not in GDD) font pass

## --- Type tiers (menu modernization, GDD §15.0 "Type tiers") ------------
## Five named sizes give every screen the same hierarchy (UiTheme.Tier,
## UiTheme.tier_label(), UiTheme.set_tier()). Jersey 10 tiers are PIXEL_SIZES
## entries only (1, 1.5, 2 or 3 layout px per font pixel); the TITLE tier is
## Jacquard 24 at BANNER_SIZE (its 43 px em).
##   TITLE : screen titles and banners (Jacquard 24, title case).
##   HERO  : big numbers (Soul Ash totals, end-screen headline numbers).
##   HEADER: section headers, the HUD timer.
##   NAME  : item / card / upgrade names, buttons.
##   BODY  : descriptions, stats, secondary lines, hints.
##   LABEL : small section labels ("DIFFICULTY"): BODY size, upper case,
##           letter-spaced LABEL_SPACING px.

## Jersey 10 size (layout px) of the HERO tier: big numbers.
const TYPE_HERO: int = 57  # TUNING (not in GDD) menu modernization type tiers
## Jersey 10 size (layout px) of the HEADER tier: section headers.
const TYPE_HEADER: int = 38  # TUNING (not in GDD) menu modernization type tiers
## Jersey 10 size (layout px) of the NAME tier: item names and buttons.
const TYPE_NAME: int = 28  # TUNING (not in GDD) menu modernization type tiers
## Jersey 10 size (layout px) of the BODY tier: descriptions and secondary text.
const TYPE_BODY: int = 19  # TUNING (not in GDD) menu modernization type tiers
## Jersey 10 size (layout px) of the LABEL tier: small upper-case section labels.
const TYPE_LABEL: int = 19  # TUNING (not in GDD) menu modernization type tiers
## Extra space (layout px = whole font px at 19 px, so the glyphs stay on
## the pixel grid) after every letter of the LABEL tier: the letter-spaced
## small-caps look of section labels. 0..3 px.
const LABEL_SPACING: int = 2  # TUNING (not in GDD) menu modernization type tiers

## Title logo PNG (pixel art at 1 texel per art px; NECROPATHY wordmark).
const LOGO: String = "res://assets/ui/logo.png"

## Whole-number scale the logo is drawn at (layout px per art px): 2 makes the
## 246 x 90 art a 492 x 180 px title at the 1280x720 layout, 3 screen px per
## art px in a 1080p window.
const LOGO_SCALE: int = 2  # TUNING (not in GDD) art pass UI kit
