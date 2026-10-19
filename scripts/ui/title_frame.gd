## TitleFrame — the gold Chaplain-skull portrait frame worn with the title
## Heretic's Bane (content wave 2, owner-approved Proposal 2; TitleData
## "frame": "chaplain_skull"). PreRunHero lays it over its hero box when the
## worn title has that frame. Drawn in code on the pixel grid (no PNG): a gold
## band with cut corners (UI rule: chamfered corners), a small gold skull on
## each corner and a mitred Chaplain skull crowning the top centre, each
## stamped from a tiny bitmap at a whole-number scale so it reads as pixel
## art. Purely visual: it never touches gameplay state.
class_name TitleFrame
extends Control

## Skull bitmap ('#' gold, 'o' dark socket, '.' empty), 9 x 8 px.
const SKULL := [
	"..#####..",
	".#######.",
	"#########",
	"#oo###oo#",
	"#oo###oo#",
	"####o####",
	".#######.",
	"..#.#.#..",
]
## The Chaplain's mitre (with its cross cut out) set on the crest skull, 9 x 6 px.
const MITRE := [
	"....#....",
	"...###...",
	"..##o##..",
	".##ooo##.",
	".###o###.",
	"#########",
]
## Frame kind drawn ("chaplain_skull"; anything else draws nothing).
var kind: String = "chaplain_skull"


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if kind != "chaplain_skull":
		return
	var gold := Palette.GOLD  # Band and skulls.
	var deep := Palette.GOLD.darkened(0.45)  # Outer edge and sockets.
	var b := TitleData.FRAME_BAND  # Band width (px).
	var c := TitleData.FRAME_CHAMFER  # Corner cut (px).
	var w := size.x  # Frame width (px).
	var h := size.y  # Frame height (px).
	# The band: four straight runs between the cut corners, then the corner diagonals.
	draw_rect(Rect2(c, 0.0, w - 2.0 * c, b), gold)
	draw_rect(Rect2(c, h - b, w - 2.0 * c, b), gold)
	draw_rect(Rect2(0.0, c, b, h - 2.0 * c), gold)
	draw_rect(Rect2(w - b, c, b, h - 2.0 * c), gold)
	for i in int(c):
		var f := float(i)  # Step along the diagonal (px).
		draw_rect(Rect2(c - f - 1.0, f, b, 1.0), gold)  # Top left.
		draw_rect(Rect2(w - c + f + 1.0 - b, f, b, 1.0), gold)  # Top right.
		draw_rect(Rect2(c - f - 1.0, h - f - 1.0, b, 1.0), gold)  # Bottom left.
		draw_rect(Rect2(w - c + f + 1.0 - b, h - f - 1.0, b, 1.0), gold)  # Bottom right.
	# A darker inner line so the band reads against any floor.
	draw_rect(Rect2(c, b, w - 2.0 * c, 1.0), deep)
	draw_rect(Rect2(c, h - b - 1.0, w - 2.0 * c, 1.0), deep)
	draw_rect(Rect2(b, c, 1.0, h - 2.0 * c), deep)
	draw_rect(Rect2(w - b - 1.0, c, 1.0, h - 2.0 * c), deep)
	# Corner skulls, then the mitred crest at the top centre.
	var cs := TitleData.FRAME_CORNER_SCALE  # Corner skull scale.
	var sk := Vector2(9.0, 8.0) * float(cs)  # Corner skull size (px).
	var inset := b + 2.0  # Corner skull inset from the edge (px).
	for p: Vector2 in [Vector2(inset, inset), Vector2(w - inset - sk.x, inset),
			Vector2(inset, h - inset - sk.y), Vector2(w - inset - sk.x, h - inset - sk.y)]:
		_stamp(SKULL, p.round(), cs, gold, deep)
	var k := TitleData.FRAME_CREST_SCALE  # Crest scale.
	var crest := Vector2(roundf(w * 0.5 - 4.5 * float(k)), b + 1.0)  # Mitre top-left (px).
	_stamp(MITRE, crest, k, gold, deep)
	_stamp(SKULL, crest + Vector2(0.0, 6.0 * float(k)), k, gold, deep)


## Stamps `bitmap` (rows of '#', 'o', '.') with its top-left at `at`, `s`
## screen px per bitmap px, '#' in `fill` and 'o' in `dark`.
func _stamp(bitmap: Array, at: Vector2, s: int, fill: Color, dark: Color) -> void:
	var px := float(s)  # Pixel size (px).
	for y in bitmap.size():
		var line := String(bitmap[y])  # One bitmap row.
		for x in line.length():
			var ch := line[x]  # Pixel code.
			if ch == "#":
				draw_rect(Rect2(at + Vector2(float(x), float(y)) * px, Vector2(px, px)), fill)
			elif ch == "o":
				draw_rect(Rect2(at + Vector2(float(x), float(y)) * px, Vector2(px, px)), dark)
