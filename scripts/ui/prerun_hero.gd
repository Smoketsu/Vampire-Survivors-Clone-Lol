## PreRunHero — the hero panel of the pre-run setup (PreRunSetup's left
## column; GDD §15.0 "Front door screens"): an ornate panel in which the
## character being looked at stands big, at FrontDoorData.HERO_SCALE (3x),
## walking in place on its walk cycle over a pedestal of the chosen stage's
## floor, in the skin it would wear; under it its name, its one innate
## passive and its starting spell (with the spell's icon) and stat line. A
## locked character stands still as a dark silhouette with a padlock, and its
## unlock condition replaces the innate. PreRunSetup calls show_character()
## when a character tile or a skin tile is focused, and slots the skin / Hyper
## row (PreRunHyperSkins) under the texts through add_extra(). Content wave 2:
## the worn title (TitleData) sits under the name, and its portrait frame
## (TitleFrame) over the hero box (show_title()). Purely visual:
## real time, no gameplay state.
class_name PreRunHero
extends PanelContainer

## Stage id whose floor the pedestal shows.
var stage_id: String = StageRegistry.DEFAULT_ID
## The stage box (pedestal and walking character).
var _stage: HeroStage
## Name line.
var _name_l: Label
## Innate name (LABEL tier, soul colour) or the lock headline.
var _innate_name: Label
## Innate description, or the unlock condition.
var _innate_desc: Label
## Starting spell icon.
var _spell_icon: IconGlyph
## Starting spell name.
var _spell_l: Label
## Stat modifier line.
var _stats_l: Label
## The column holding everything (add_extra() appends to it).
var _col: VBoxContainer
## Content wave 2: the worn title under the name (TitleData; shown once any
## title is earned, empty while None is worn).
var _title_l: Label
## Content wave 2: the worn title's portrait frame over the hero box
## (TitleFrame; Heretic's Bane's gold Chaplain-skull frame).
var _frame: TitleFrame


## The pedestal box: the stage floor, a soul glow and the character walking
## in place at HERO_SCALE (or a padlocked silhouette).
class HeroStage:
	extends Control
	## Character shown.
	var char_id: String = CharacterData.DEFAULT_ID
	## Skin worn (SkinData id).
	var skin_id: String = ""
	## True when the character is locked (silhouette, no walk).
	var locked: bool = false
	## Floor tile key under the hero.
	var tile_key: String = ""
	## Real seconds (walk frames).
	var _t: float = 0.0

	func _init() -> void:
		custom_minimum_size = FrontDoorData.HERO_STAGE_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		clip_contents = true

	func _ready() -> void:
		SpriteBank.apply_sharp(self)

	func _process(delta: float) -> void:
		if locked or not UiMotion.enabled():
			return
		_t += delta / Engine.time_scale if Engine.time_scale > 0.0 else delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.03))
		var fb := FrontDoorData.HERO_FLOOR_BRIGHT  # Floor brightness.
		var tile := EnvironmentArt.texture(tile_key, true) if tile_key != "" else null  # Repeating floor, or null.
		if tile != null:
			draw_texture_rect(tile, Rect2(Vector2.ZERO, size), true, Color(fb, fb, fb))
		var tint: Color = CharacterModifiers.def(char_id)["tint"]  # School colour.
		var feet := Vector2(roundf(size.x * 0.5), size.y - FrontDoorData.HERO_FEET_UP)  # Feet (px).
		var glow := EnvironmentArt.texture(MenuBackdropData.ART + "glow")  # Stepped glow disc, or null.
		if glow != null and not locked:
			var gs := Vector2(float(glow.get_width()), float(glow.get_height())) * FrontDoorData.HERO_GLOW_SCALE  # Glow size (px).
			draw_texture_rect(glow, Rect2((feet - Vector2(0.0, gs.y * 0.3) - gs * 0.5).round(), gs), false, Color(tint.lightened(FrontDoorData.HERO_GLOW_LIGHTEN), FrontDoorData.HERO_GLOW_ALPHA))
		var k := float(FrontDoorData.HERO_SCALE)  # Layout px per art px.
		var art := _art()  # [still, strip or null, tint].
		if art.is_empty():
			return
		var still: Texture2D = art[0]
		var fw := float(still.get_width())  # Frame width (art px).
		var fh := float(still.get_height())  # Frame height (art px).
		draw_set_transform(feet + Vector2(0.0, -2.0), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, fw * k * 0.36, Color(0.0, 0.0, 0.0, 0.45))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var dst := Rect2(Vector2(feet.x - roundf(fw * 0.5) * k, feet.y - fh * k), Vector2(fw, fh) * k)  # On the art grid (px).
		var mod: Color = FrontDoorData.LOCK_SILHOUETTE if locked else (art[2] as Color)
		var strip: Texture2D = art[1]
		if strip != null and not locked:
			var n := int(strip.get_width() / still.get_width())  # Frames.
			var f := int(_t * FrontDoorData.HERO_WALK_FPS) % maxi(1, n)  # Walk frame.
			draw_texture_rect_region(strip, dst, Rect2(fw * float(f), 0.0, fw, fh), mod)
		else:
			draw_texture_rect(still, dst, false, mod)
		_edges()
		if locked:
			var s := MaskIcon.art_size("padlock") * float(FrontDoorData.LOCK_ICON_SCALE)  # Padlock (px).
			MaskIcon.paint(self, "padlock", (dst.get_center() - s * 0.5).round(), FrontDoorData.LOCK_ICON_SCALE)

	## The art to draw: [still, walk strip (or null), colour]: the skin's own
	## sprite, else the character's sprite in the skin's tint. [] without art.
	func _art() -> Array:
		var row := SkinData.skin(skin_id)  # The skin ({} = default look).
		var keys: Array = []  # [key, tint] candidates in order.
		if not row.is_empty():
			keys.append([String(row["sprite"]), Color.WHITE])
		var base := SkinData.base_sprite(char_id)  # The character's own sprite.
		keys.append([base, (row.get("tint", Color.WHITE) as Color) if not row.is_empty() else Color.WHITE])
		keys.append(["player/necromancer", (CharacterModifiers.def(char_id)["tint"] as Color).lerp(Color.WHITE, CharacterGlyphs.SPRITE_TINT_LIGHTEN)])
		for kt: Array in keys:
			var still := EnvironmentArt.texture(String(kt[0]))
			if still == null:
				continue
			var strip := EnvironmentArt.texture(String(kt[0]) + WalkData.SUFFIX)  # Walk strip, or null.
			if strip != null and (strip.get_height() != still.get_height() or strip.get_width() % still.get_width() != 0):
				strip = null
			return [still, strip, kt[1]]
		return []

	## Stepped dark bands along the box's edges (pixel-art vignette).
	func _edges() -> void:
		var a := FrontDoorData.VIGNETTE_EDGE_ALPHA / float(FrontDoorData.VIGNETTE_EDGE_STEPS.size())  # Alpha per step.
		for w: float in FrontDoorData.VIGNETTE_EDGE_STEPS:
			var c := Color(0.02, 0.01, 0.04, a)
			draw_rect(Rect2(0.0, 0.0, size.x, w), c)
			draw_rect(Rect2(0.0, size.y - w, size.x, w), c)
			draw_rect(Rect2(0.0, w, w, size.y - 2.0 * w), c)
			draw_rect(Rect2(size.x - w, w, w, size.y - 2.0 * w), c)


func _init() -> void:
	add_theme_stylebox_override("panel", UiTheme.style("ornate", "violet"))
	custom_minimum_size.x = FrontDoorData.HERO_WIDTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 5)
	_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_col)
	_stage = HeroStage.new()
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_col.add_child(_stage)
	_name_l = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_col.add_child(_name_l)
	_title_l = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)  # Content wave 2: the worn title.
	_col.add_child(_title_l)
	_frame = TitleFrame.new()  # Content wave 2: the worn title's portrait frame.
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_frame)
	var spell := HBoxContainer.new()  # Spell icon, name and stats.
	spell.add_theme_constant_override("separation", 6)
	spell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_icon = IconGlyph.new("", Vector2(22, 22))
	_spell_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spell.add_child(_spell_icon)
	_spell_l = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT)
	_spell_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spell.add_child(_spell_l)
	_stats_l = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_stats_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stats_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats_l.clip_text = true
	spell.add_child(_stats_l)
	_col.add_child(spell)
	_innate_name = UiTheme.tier_label("", UiTheme.Tier.LABEL, Palette.NECRO_GREEN)
	_col.add_child(_innate_name)
	_innate_desc = UiTheme.para("", FrontDoorData.HERO_TEXT_WIDTH, UiTheme.TEXT)
	_innate_desc.custom_minimum_size.y = float(UiTheme.tier_px(UiTheme.Tier.BODY)) * 2.0  # Two lines kept: no jump.
	_col.add_child(_innate_desc)


## Appends `c` under the hero's texts (the skin / Hyper row), after a divider.
func add_extra(c: Control) -> void:
	_col.add_child(UiTheme.divider())
	_col.add_child(c)


## Content wave 2: shows the worn title (Meta.selected_title()) under the
## name and its frame over the hero box. The line takes its place once any
## title is earned (so wearing None does not make the panel jump).
func show_title() -> void:
	var t := Meta.selected_title()  # Worn title ("" = none).
	_title_l.text = TitleData.display_text(t)
	_title_l.visible = not Meta.unlocked_titles().is_empty()
	var fk := TitleData.frame_of(t)  # Its frame ("" = none).
	_frame.kind = fk
	_frame.visible = fk != ""
	_frame.queue_redraw()


## Shows character `id` in skin `skin` (`chosen`: the current choice, gold name).
func show_character(id: String, skin: String, chosen: bool) -> void:
	var d := CharacterModifiers.def(id)  # Character row.
	var locked := not Meta.is_character_unlocked(id)  # Cannot be chosen yet.
	_stage.char_id = id
	_stage.skin_id = skin
	_stage.locked = locked
	_stage.tile_key = String(FrontDoorData.VIGNETTES.get(stage_id, {}).get("tile", ""))
	_stage.queue_redraw()
	_name_l.text = String(d["display_name"])
	_name_l.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if chosen else (UiTheme.TEXT_DIM if locked else UiTheme.TEXT))
	tooltip_text = String(d["title"])  # The flavour line.
	show_title()
	var sid := String(d["spell"])  # Starting spell id.
	_spell_icon.set_icon(String(AbilityData.SPELLS[sid]["icon"]) if AbilityData.SPELLS.has(sid) else "")
	_spell_l.text = CharacterModifiers.spell_name(id)
	var st: Dictionary = d["stats"]
	_stats_l.text = CharacterModifiers.stats_text(id) if not st.is_empty() else ""
	var inn: Dictionary = d["innate"]  # {} = none.
	if locked:
		_innate_name.text = "Locked"
		_innate_name.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.4))
		_innate_desc.text = CharacterModifiers.unlock_text(id)
	elif inn.is_empty():
		_innate_name.text = "No innate"
		_innate_name.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
		_innate_desc.text = "The classic necromancer: baseline stats."
	else:
		_innate_name.text = String(inn["name"])
		_innate_name.add_theme_color_override("font_color", Palette.NECRO_GREEN)
		_innate_desc.text = String(inn["description"])
