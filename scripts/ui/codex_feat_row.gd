## CodexFeatRow — one row of the Codex screen's Achievements page: a
## focusable card Button (so the pad can scroll the list) showing the badge,
## the name (gold and stamped "Earned" once earned), the one-line goal, a
## kit progress bar with "progress / goal", and the reward (text and a
## preview: the skin it unlocks, the Hyper badge or the Soul Ash icon).
## Built from a CodexEntries.feats() row; read-only (earning is unchanged:
## Meta.award_run() decides). Locked rows use the violet card, earned rows
## the gold one (gold = victory). Purely visual.
class_name CodexFeatRow
extends Button

## The feat row this card shows (CodexEntries.feats() keys).
var feat: Dictionary = {}


## A kit progress bar: the recessed slider track with the violet fill (gold
## once complete) over `frac` of its width.
class KitBar:
	extends Control

	## Filled fraction 0..1.
	var frac: float = 0.0
	## True: the bar is complete (drawn gold).
	var done: bool = false

	func _init(p_frac: float, p_done: bool) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		done = p_done
		custom_minimum_size = Vector2(CodexData.BAR_WIDTH, CodexData.BAR_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		SpriteBank.apply_sharp(self)
		var r := Rect2(Vector2.ZERO, size)  # Whole bar (px).
		draw_style_box(UiTheme.style("track"), r)
		var w := floorf((r.size.x - 4.0) * frac)  # Filled width inside the rim (px).
		if w < 1.0:
			return
		var fill := Rect2(Vector2(2.0, 2.0), Vector2(w, r.size.y - 4.0))  # Fill rect (px).
		if done:
			draw_rect(fill, Palette.GOLD.darkened(0.15))
			draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), Palette.GOLD.lightened(0.35))
		else:
			draw_style_box(UiTheme.style("fill"), fill)


## A skin preview in a dark socket (dimmed while `locked`).
class SkinThumb:
	extends Control

	## SkinData id drawn.
	var skin_id: String = ""
	## True while the skin is locked.
	var locked: bool = false

	func _init(id: String, is_locked: bool, min_size: Vector2) -> void:
		skin_id = id
		locked = is_locked
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		SpriteBank.apply_sharp(self)
		draw_style_box(UiTheme.style("slot"), Rect2(Vector2.ZERO, size))
		SpriteBank.icon_cap = size.y * 0.82
		SkinGlyphs.draw_skin(self, skin_id, size * 0.5 + Vector2(0.0, size.y * 0.04), size.y * 0.28, false)
		SpriteBank.icon_cap = 0.0
		if locked:
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.02, 0.0, 0.04, 0.55))


func _init(p_feat: Dictionary) -> void:
	feat = p_feat
	custom_minimum_size = Vector2(0.0, CodexData.ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	set_meta(UiMotion.META_LIFT, false)  # A list row: no card lift.
	set_meta(UiMotion.META_SQUASH, false)


func _ready() -> void:
	var earned := bool(feat["earned"])  # Gold card, stamp and bar.
	UiTheme.style_button(self, "card", "gold" if earned else "violet")
	add_theme_stylebox_override("pressed", UiTheme.style("card", "gold" if earned else "violet", "hover"))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = CodexData.ROW_PAD.x
	row.offset_right = -CodexData.ROW_PAD.x
	row.offset_top = CodexData.ROW_PAD.y
	row.offset_bottom = -CodexData.ROW_PAD.y
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(_badge(earned))
	row.add_child(_texts(earned))
	row.add_child(_reward(earned))


## The badge: the achievement's icon at x2 (dim until earned), or a skin.
func _badge(earned: bool) -> Control:
	if String(feat.get("badge_skin", "")) != "":
		var t := SkinThumb.new(String(feat["badge_skin"]), not earned, CodexData.BADGE_SIZE)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return t
	var art := CodexArt.new(CodexData.BADGE_SIZE)
	art.max_scale = 2
	var icon := String(feat["badge"])  # Badge art, else the drawn fallback.
	if not SpriteBank.has("icons/" + icon):
		icon = String(feat["badge_fallback"])
	art.show_entry("", icon, not earned, false)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return art


## Name (+ "Earned" stamp), goal and progress bar.
func _texts(earned: bool) -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(UiTheme.tier_label(String(feat["name"]), UiTheme.Tier.NAME, UiTheme.TEXT_GOLD if earned else UiTheme.TEXT))
	if earned:
		var stamp := UiTheme.tier_label(CodexData.EARNED_TEXT, UiTheme.Tier.LABEL, UiTheme.TEXT_GOLD)
		stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(stamp)
	vb.add_child(head)
	var goal := UiTheme.tier_label(String(feat["goal"]), UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	goal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	goal.clip_text = true
	vb.add_child(goal)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 10)
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target := maxf(1.0, float(feat["target"]))  # Goal count.
	var prog := minf(float(feat["progress"]), target)  # Progress, capped at the goal.
	var bar := KitBar.new(prog / target, earned)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(bar)
	bar_row.add_child(UiTheme.tier_label("%s / %s" % [CodexEntries.group(int(prog)), CodexEntries.group(int(target))], UiTheme.Tier.BODY, UiTheme.TEXT_GOLD if earned else UiTheme.TEXT))
	vb.add_child(bar_row)
	return vb


## Reward label and text, with a preview on the right.
func _reward(earned: bool) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(CodexData.REWARD_WIDTH, 0.0)
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(UiTheme.tier_label(CodexData.REWARD_LABEL, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM))
	var text := UiTheme.para(String(feat["reward"]), 0.0, UiTheme.TEXT_GOLD if earned else UiTheme.TEXT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(text)
	h.add_child(vb)
	var preview: Control
	if String(feat["reward_skin"]) != "":
		preview = SkinThumb.new(String(feat["reward_skin"]), not earned, CodexData.REWARD_PREVIEW)
	else:
		preview = IconGlyph.new(String(feat["reward_icon"]), CodexData.REWARD_PREVIEW)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(preview)
	return h
