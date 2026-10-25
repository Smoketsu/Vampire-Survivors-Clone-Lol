## CoopBust: a co-op player's head-and-shoulders portrait (GDD §15.0 "Co-op
## HUD and visuals"): the necromancer of one CoopSlot drawn at his world size
## (1 art px = 1 px, crisp) with his character's look and worn skin, dropped so
## the head and shoulders fill the box, and clipped to it (clip_contents). Used
## by the partner plate (in the kit's recessed slot frame), the off-screen
## arrow's badge (no frame, inside the round badge) and the results card.
## `downed` greys and reddens him. Purely visual: it reads the necromancer's
## character, skin and recolour ids only.
class_name CoopBust
extends Control

## Character id drawn (CharacterData; "" = the default necromancer).
var character_id: String = ""
## Worn skin id ("" = the character's own look).
var skin_id: String = ""
## Worn recolour id (RecolourData; "" = the skin's own colours).
var recolour_id: String = ""
## Distance (px) from the box's top to the sprite's centre (the drop that puts
## the head and shoulders in view).
var drop: float = CoopHudData.PORTRAIT_DROP
## True: draw the kit's recessed slot frame and a dark plate behind the bust.
var framed: bool = true
## True: the necromancer lies downed (greyed, reddened).
var downed: bool = false


func _init(p_size: Vector2 = CoopHudData.PLATE_PORTRAIT, p_drop: float = CoopHudData.PORTRAIT_DROP, p_framed: bool = true) -> void:
	custom_minimum_size = p_size
	size = p_size
	drop = p_drop
	framed = p_framed
	clip_contents = true  # Only the head and shoulders show.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	SpriteBank.apply_sharp(self)  # Crisp sprite art.


## Shows necromancer `p` (his character and skin); redraws on change.
func show_player(p: Necromancer, is_downed: bool) -> void:
	if p == null:
		return
	if p.character_id == character_id and p.skin_id == skin_id and p.recolour_id == recolour_id and is_downed == downed:
		return
	character_id = p.character_id
	skin_id = p.skin_id
	recolour_id = p.recolour_id
	downed = is_downed
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)  # The box (px).
	if framed:
		draw_rect(r, CoopHudData.PLATE)
		var frame := UiTheme.style("slot")  # Recessed kit frame.
		if frame is StyleBoxTexture:
			draw_style_box(frame, r)
		else:
			draw_rect(r, UiTheme.BORDER, false, 1.0)
	var tint := Color(0.75, 0.45, 0.48) if downed else Color.WHITE  # Downed: greyed and reddened.
	var o := Vector2(roundf(size.x * 0.5), roundf(drop))  # Sprite centre (whole px: crisp art).
	var id := character_id if character_id != "" else CharacterData.DEFAULT_ID
	if skin_id == "" or not SkinGlyphs.draw_skin(self, skin_id, o, 12.0, false, recolour_id):
		CharacterGlyphs.draw_player(self, id, o, 12.0, false, tint, recolour_id)
	if downed:
		draw_rect(r, Color(CoopHudData.DOWNED, 0.22))  # A crimson veil (also over a skin drawn untinted).
