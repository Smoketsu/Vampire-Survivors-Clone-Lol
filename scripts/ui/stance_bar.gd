## StanceBar — the HUD part of the army stances (StanceData, ArmyStance):
##   * a column of four stance icons beside the army list (bottom left), in
##     key order 1-4, each with its key; the active stance is lit with a
##     border in its colour (and a thin bar for the switch lockout), the
##     others are dimmed, and a locked stance (Spearhead before its Ossuary
##     unlock) is dark with a padlock. Icons go through Glyphs.draw_icon(),
##     so icon art (icons/stance_<id>.png) plugs in by itself.
##   * the one-word banner on a stance change ("ONSLAUGHT") under the
##     necromancer, and the once-per-run "Locked: ..." banner.
## A full-screen, input-transparent overlay added by the Hud; it polls the
## run like the rest of the HUD.
class_name StanceBar
extends Control

## Size (px) of one stance icon.
const ICON_SIZE := Vector2(26, 26)
## Vertical gap (px) between icons.
const ICON_GAP: float = 4.0
## Left edge (px) of the column: just right of the army rows (16 px margin
## + 22 px icon + 130 px label + 70 px bar + gaps end at ~246 px).
const LEFT: float = 256.0
## Bottom margin (px) of the column (same as the army panel).
const BOTTOM: float = 16.0
## Font size of the key hints next to the icons.
const KEY_FONT: int = 11
## Font size of the stance banner.
const BANNER_FONT: int = 26
## Font size of the locked banner.
const LOCKED_FONT: int = 16
## Banner centre below the screen centre (px), i.e. under the necromancer.
const BANNER_DROP: float = 70.0

## Owning run.
var game: Game
## Banner label (stance word or the locked text).
var _banner: Label
## Last state drawn: [current id, spearhead unlocked, lockout active] (redraw on change).
var _drawn: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner = UiTheme.label("", BANNER_FONT, UiTheme.TEXT_GOLD)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 0.5
	_banner.anchor_bottom = 0.5
	_banner.offset_left = -300.0
	_banner.offset_right = 300.0
	_banner.offset_top = BANNER_DROP
	_banner.offset_bottom = BANNER_DROP + 34.0
	_banner.visible = false
	add_child(_banner)


func _process(_delta: float) -> void:
	if game == null or game.stance == null:
		return
	var st := game.stance
	var state := [st.current, st.is_unlocked("spearhead"), st.lockout_left() > 0.0]
	if state != _drawn or st.lockout_left() > 0.0:
		_drawn = state
		queue_redraw()
	_refresh_banner(st)


## Shows / fades the stance banner (or the locked banner, whichever is newer).
func _refresh_banner(st: ArmyStance) -> void:
	var locked := st.locked_banner_at > st.changed_at  # The newest banner is the locked one.
	var at := st.locked_banner_at if locked else st.changed_at  # Game time it was raised.
	var age := game.elapsed - at
	var hold := StanceData.LOCKED_BANNER_TIME if locked else StanceData.BANNER_TIME  # Fully visible seconds.
	var total := hold + StanceData.BANNER_FADE
	if age < 0.0 or age > total:
		_banner.visible = false
		return
	_banner.visible = true
	if locked:
		_banner.text = StanceData.LOCKED_TEXT
		_banner.add_theme_font_size_override("font_size", LOCKED_FONT)
		_banner.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4))
	else:
		_banner.text = String(st.def()["display_name"]).to_upper()
		_banner.add_theme_font_size_override("font_size", BANNER_FONT)
		_banner.add_theme_color_override("font_color", (st.def()["color"] as Color).lightened(0.2))
	_banner.modulate.a = clampf(1.0 - (age - hold) / StanceData.BANNER_FADE, 0.0, 1.0)


func _draw() -> void:
	if game == null or game.stance == null:
		return
	var st := game.stance
	var n := StanceData.ORDER.size()
	var top := size.y - BOTTOM - float(n) * ICON_SIZE.y - float(n - 1) * ICON_GAP  # Top of the column.
	var font := get_theme_default_font()
	for i in n:
		var id: String = StanceData.ORDER[i]
		var d := StanceData.def(id)
		var rect := Rect2(Vector2(LEFT, top + float(i) * (ICON_SIZE.y + ICON_GAP)), ICON_SIZE)
		Glyphs.draw_icon(self, String(d["icon"]), rect)
		var col: Color = d["color"]
		if id == st.current:
			draw_rect(rect.grow(1.5), col, false, 2.0)
			var left := st.lockout_left() / StanceData.SWITCH_LOCKOUT  # 1 -> 0 lockout bar.
			if left > 0.0:
				draw_rect(Rect2(rect.position + Vector2(0, rect.size.y + 1.0), Vector2(rect.size.x * left, 2.0)), Color(col, 0.8))
		elif not st.is_unlocked(id):
			draw_rect(rect, Color(0, 0, 0, 0.62))
			StanceGlyphs.draw_lock(self, rect.get_center() + Vector2(rect.size.x * 0.18, rect.size.y * 0.18), rect.size.x * 0.32)
		else:
			draw_rect(rect, Color(0, 0, 0, 0.38))
		var key := Settings.key_name(StanceData.ACTIONS[i])  # Bound key ("1").
		var key_col := UiTheme.TEXT if id == st.current else UiTheme.TEXT_DIM
		draw_string(font, Vector2(rect.end.x + 4.0, rect.get_center().y + 4.0), key, HORIZONTAL_ALIGNMENT_LEFT, -1.0, KEY_FONT, key_col)
