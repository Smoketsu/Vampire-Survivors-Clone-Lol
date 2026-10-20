## MaskIconData: the small pixel-art UI icons of the front door screens (main
## menu, stage select, pre-run setup; GDD §15.0 "Front door screens"), stored
## as character masks so they need no PNG: one string per art row, one
## character per art px, each character a colour of PALETTE ("." is clear).
## MaskIcon (scripts/ui/mask_icon.gd) turns a mask into a cached grid-art
## texture drawn at a whole-number scale through the sharp-pixel shader, so the
## icons stay as crisp as the sprites. Colours come from the locked art palette
## (docs/art/ART_BIBLE.md "Colour language"). Data only, no logic.
class_name MaskIconData
extends RefCounted

## Mask character -> colour (alpha 1 unless noted).
const PALETTE: Dictionary = {
	"k": Color8(22, 10, 33),  # TUNING (not in GDD) ink outline (the logo's outline colour)
	"b": Color8(232, 225, 200),  # TUNING (not in GDD) bone (lit)
	"B": Color8(170, 160, 130),  # TUNING (not in GDD) bone (shade)
	"g": Color8(255, 209, 77),  # TUNING (not in GDD) gold (lit)
	"G": Color8(176, 116, 38),  # TUNING (not in GDD) gold (shade)
	"s": Color8(61, 204, 148),  # TUNING (not in GDD) soul teal (the logo's flame colour)
	"S": Color8(28, 107, 88),  # TUNING (not in GDD) soul teal (shade)
	"r": Color8(214, 40, 52),  # TUNING (not in GDD) crimson (lit)
	"R": Color8(115, 13, 23),  # TUNING (not in GDD) crimson (shade)
	"v": Color8(163, 92, 250),  # TUNING (not in GDD) violet (lit)
	"V": Color8(74, 37, 105),  # TUNING (not in GDD) violet (shade)
	"w": Color8(255, 250, 230),  # TUNING (not in GDD) highlight
	"e": Color8(128, 124, 140),  # TUNING (not in GDD) iron (lit)
	"E": Color8(62, 58, 74),  # TUNING (not in GDD) iron (shade)
	"f": Color8(255, 140, 38),  # TUNING (not in GDD) candle flame
}

## Icon id -> mask rows (all rows of one icon are the same length).
##   padlock    : locked stage cards and locked tiles (iron shackle, gold body).
##   hourglass  : best time (main-menu stats, stage cards).
##   tomb       : runs played (main-menu stats).
##   skull      : the Necromancer difficulty.
##   skull_crown: bosses slain (main-menu stats, stage cards).
##   trophy     : achievements (main-menu stats).
##   candle     : the Initiate difficulty.
##   lich       : the Lich difficulty (a skull under a soul-fire crown).
##   deathlord  : the Deathlord difficulty (a horned skull with crimson eyes).
##   rune_on / rune_off: a run modifier's toggle pip (lit crimson / dark iron).
##   ember      : the Soul Ash bonus mark of a stage card.
##   quill      : the main menu's Feedback button (a bone quill over a pool
##                of violet ink: it leaves the game for the feedback form).
const ICONS: Dictionary = {
	"padlock": [
		"...kkkkk...",
		"..keeeeek..",
		".keEkkkEek.",
		".kek...kek.",
		".kek...kek.",
		"kkkkkkkkkkk",
		"kggggggggGk",
		"kgGGGkGGGGk",
		"kgGGkkkGGGk",
		"kgGGGkGGGGk",
		"kgGGGkGGGGk",
		"kGGGGGGGGGk",
		"kkkkkkkkkkk",
	],
	"hourglass": [
		"kkkkkkkkk",
		"kGgggggGk",
		".kbBBBbk.",
		".kbsssbk.",
		"..kbsbk..",
		"...kbk...",
		"..kbBbk..",
		".kbBsBbk.",
		".kbsssbk.",
		"kGgggggGk",
		"kkkkkkkkk",
	],
	"tomb": [
		"..kkkkk..",
		".kBbbbBk.",
		"kBbbkbbBk",
		"kbbkkkbbk",
		"kbbbkbbbk",
		"kbbbkbbbk",
		"kbbbbbbbk",
		"kBbbbbbBk",
		"kBBBBBBBk",
		"kkkkkkkkk",
		"kSsSsSsSk",
		"kkkkkkkkk",
	],
	"skull": [
		"..kkkkk..",
		".kbbbbbk.",
		"kbbbbbbbk",
		"kbkkbkkbk",
		"kbkkbkkbk",
		"kBbbkbbBk",
		".kBbbbBk.",
		".kbkbkbk.",
		"..kkkkk..",
	],
	"skull_crown": [
		"k..k.k..k",
		"gk.kgk.kg",
		"ggkgggkgg",
		"GgggrgggG",
		"kGGGGGGGk",
		"kbbbbbbbk",
		"kbkkbkkbk",
		"kbkkbkkbk",
		"kBbbkbbBk",
		".kBbbbBk.",
		".kbkbkbk.",
		"..kkkkk..",
	],
	"trophy": [
		"kkkkkkkkkkk",
		"kgkgwgggkgk",
		"kgkgwgggkgk",
		".kkgggggkk.",
		"..kgggggk..",
		"..kGgggGk..",
		"...kGgGk...",
		"....kgk....",
		"...kkGkk...",
		"..kgggggk..",
		"..kGGGGGk..",
		"..kkkkkkk..",
	],
	"candle": [
		"....k....",
		"...kfk...",
		"..kfgfk..",
		"..kgwgk..",
		"...kkk...",
		"..kbbbk..",
		"..kbBbk..",
		"..kbbbk..",
		"..kbbBk..",
		"..kbbbk..",
		".kBbbbBk.",
		"kkkkkkkkk",
	],
	"lich": [
		"s...s...s",
		"Sk.ksk.kS",
		"SskSsSksS",
		"kSSSSSSSk",
		"kbbbbbbbk",
		"kbkkbkkbk",
		"kbksbskbk",
		"kBbbkbbBk",
		".kBbbbBk.",
		".kbkbkbk.",
		"..kkkkk..",
	],
	"deathlord": [
		"k.......k",
		"Bk.....kB",
		"kBkkkkkBk",
		".kbbbbbk.",
		"kbbbbbbbk",
		"kbkkbkkbk",
		"kbkrbrkbk",
		"kBbbkbbBk",
		".kBbbbBk.",
		".kbkbkbk.",
		"..kkkkk..",
	],
	"rune_on": [
		"...k...",
		"..krk..",
		".krwrk.",
		"krwwwrk",
		".krwrk.",
		"..krk..",
		"...k...",
	],
	"rune_off": [
		"...k...",
		"..kEk..",
		".kEeEk.",
		"kEeEeEk",
		".kEeEk.",
		"..kEk..",
		"...k...",
	],
	"ember": [
		"..k..",
		".kfk.",
		"kfgfk",
		"kgwgk",
		".kgk.",
		"..k..",
	],
	"quill": [
		"........kkk",
		".......kbwk",
		"......kbbBk",
		".....kbbBbk",
		"....kbbBbk.",
		"...kbbBbk..",
		"..kbbBbk...",
		"..kbBbk....",
		".kbBkk.....",
		".kGk.......",
		"kgk..kvvk..",
		"kk..kvVVvk.",
		"....kkkkkk.",
	],
}
