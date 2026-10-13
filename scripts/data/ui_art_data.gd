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

## Title logo PNG (pixel art at 1 texel per art px; NECROPATHY wordmark).
const LOGO: String = "res://assets/ui/logo.png"

## Whole-number scale the logo is drawn at (layout px per art px): 2 makes the
## 246 x 90 art a 492 x 180 px title at the 1280x720 layout, 3 screen px per
## art px in a 1080p window.
const LOGO_SCALE: int = 2  # TUNING (not in GDD) art pass UI kit
