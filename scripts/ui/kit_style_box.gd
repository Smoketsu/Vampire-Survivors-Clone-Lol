## KitStyleBox: a UI kit frame with fixed-size crests (ornamented UI kit, GDD
## §15.0 "Ornamented UI kit"; art in docs/art/ART_BIBLE.md "UI kit").
##
## A 9-slice StyleBoxTexture stretches nothing in the corners but tiles its
## edges and centre, so art that must sit in the MIDDLE of an edge (the ornate
## panel's skull keystone, the header band's gem finials, the divider's skull)
## cannot live in the 9-slice PNG. This StyleBox draws the 9-slice `frame`, then
## each crest texture on top at its own size, placed relative to the drawn rect
## (UiArtData.CRESTS: an anchor as a fraction of the rect plus a pixel offset,
## floored to whole layout px so the art stays on the pixel grid). A crest may
## overhang the rect (the keystone rises above the panel's top edge).
##
## Built by UiTheme.style() for the kinds listed in UiArtData.CRESTS (and the
## divider); used like any StyleBox (panels, buttons, draw_style_box()). The
## owner Control draws it, so its sharp-pixel material (UiTheme's hook) keeps the
## crests crisp too. Content margins are set by UiTheme from UiArtData.CONTENT.
## Purely visual: no state, no input, no gameplay.
class_name KitStyleBox
extends StyleBox

## The 9-slice frame drawn first (a StyleBoxTexture of the kit PNG).
var frame: StyleBox = null
## Height (layout px) the frame is drawn at, centred vertically in the rect;
## 0 = the whole rect (the divider draws its thin line strip through the
## middle of a taller Control).
var frame_height: float = 0.0
## Crest textures, drawn in order over the frame (same length as the arrays below).
var crest_textures: Array[Texture2D] = []
## Per crest: anchor as a fraction of the rect size (0-1 on each axis).
var crest_anchors: Array[Vector2] = []
## Per crest: offset (layout px) of the crest's top-left from its anchor point.
var crest_offsets: Array[Vector2] = []


## StyleBox virtual: draws the frame, then the crests, into `to_canvas_item`.
func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if frame != null:
		var r := rect  # Frame rect (the whole rect, or a centred strip).
		if frame_height > 0.0:
			r = Rect2(rect.position.x, rect.position.y + floorf((rect.size.y - frame_height) * 0.5),
					rect.size.x, frame_height)
		frame.draw(to_canvas_item, r)
	for i in crest_textures.size():
		var tex := crest_textures[i]  # Crest art (never null once built).
		var pos := (rect.position + rect.size * crest_anchors[i] + crest_offsets[i]).floor()  # Top-left, whole px.
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(pos, tex.get_size()), tex.get_rid())
