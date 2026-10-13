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

## --- Pixel fonts (owner choice, GDD §15.0 "Pixel fonts", option 13) --------
## Pixelify Sans Bold is a pixel-style font whose "pixels" sit on an em of
## about 11.5 px, with bold strokes and thin gaps off that grid. A scratch
## glyph-topology check (every digit, letter, %, + and : rasterised in mono at
## 1:1, sizes 9-48, compared with the true outline: same strokes, same holes)
## found it clean only at 11, 23, 24 and 27+ px; at 12-22 px a "2" fills into
## an "8", "C" closes into "O", "G" into "Q" (grayscale anti-aliasing at the
## window resolution does not save those sizes either: the gaps fade out).
## Godot's default oversampling also rasterises at layout size x window
## scale (x1.5 at 1080p), i.e. often at those broken sizes. So the glyphs are
## always rasterised at one of the font's clean pixel ems (PIXEL_EMS, through
## FontFile.fixed_size: the raster is scaled to whatever size a label asks
## for), mono, and the sharp-pixel shader on every Label, Button and HUD
## widget (UiTheme._SharpHook, SpriteBank.apply_sharp()) enlarges them evenly
## at any window scale, like the sprites. Every label keeps its own size, so
## the layouts do not move; every glyph is correct at every window size.
## Long descriptions keep a smooth body font instead (UiTheme.body()).

## Pixelify Sans Bold: the HUD, numbers, headings, labels, buttons and card
## names (the theme's default font).
const FONT_PIXEL: String = "res://assets/fonts/PixelifySans-Bold.ttf"

## Jacquard 24: zone and event banners (the HUD event banner, the stance
## banner, the synergy / evolution announcement).
const FONT_BANNER: String = "res://assets/fonts/Jacquard24-Regular.ttf"

## The clean raster sizes (px) of Pixelify Sans Bold used: its pixel em x1
## (1 px strokes) and x2 (bold 2-3 px strokes). Text smaller than the second
## one is drawn from the x1 raster (enlarged), larger text from the x2 raster
## (never shrunk, so never blurred). At 11 px every letter, digit and
## punctuation mark checked is clean except "=" (its bars merge): draw an
## "=" at 23 px or more.
const PIXEL_EMS: Array[int] = [11, 23]  # TUNING (not in GDD) font pass: measured clean sizes

## Jacquard 24's pixel em: its outlines sit on a 30-unit grid of a 1290-unit
## em, so 43 px = 1 font px per layout px, its only clean size short of 86.
const BANNER_SIZE: int = 43  # TUNING (not in GDD) GDD §15.0 "Pixel fonts": whole multiples of the 43 px em

## Width (layout px) at which a Jacquard event banner wraps (between the
## top-left HP block and the top-right modifiers block).
const BANNER_WRAP: float = 680.0  # TUNING (not in GDD) font pass

## Title logo PNG (pixel art at 1 texel per art px; NECROPATHY wordmark).
const LOGO: String = "res://assets/ui/logo.png"

## Whole-number scale the logo is drawn at (layout px per art px): 2 makes the
## 246 x 90 art a 492 x 180 px title at the 1280x720 layout, 3 screen px per
## art px in a 1080p window.
const LOGO_SCALE: int = 2  # TUNING (not in GDD) art pass UI kit
