## CoopResults: the co-op column of the results card (GDD §15.0 "Co-op HUD
## and visuals"; sizes and texts in CoopHudData). In a co-op run EndScreen puts
## it where the portrait (defeat) or the stage seal (victory) stands, so the
## card keeps its three columns and its size (inside 1280 x 600 layout px; a
## short phone screen shrinks it with the rest, TouchSupport.fit_to_screen()).
## It shows:
##   * a LABEL caption "Co-op" and the stage / difficulty lines (the portrait
##     column's, which it replaces; difficulty crimson when not the standard run);
##   * one card per player, THIS machine's player first (its frame violet and a
##     soul-teal "You" tag; the partner's frame dim): his bust, name and
##     character, a line "N slain · Lv N · N downs · N raised" (the level is the
##     shared one), and his build as small icons with level pips (summon
##     classes and spells, a gap, then passives; as the HUD's slots show them).
## Read-only: it reads each CoopSlot (kills, downs, revives, the slot's own
## horde and abilities) and changes nothing.
class_name CoopResults
extends RefCounted


## The co-op column for the finished run `game` and its `summary`
## (Game.build_summary()). Empty VBox without a session.
static func column(game: Game, summary: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.custom_minimum_size = Vector2(CoopHudData.RESULTS_WIDTH, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if game == null or game.coop == null:
		return col
	col.add_child(RunBuild.caption("Co-op"))
	var stage := UiTheme.tier_label(String(summary.get("stage_name", "")), UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	stage.clip_text = true
	stage.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(stage)
	var label := String(summary.get("difficulty_label", summary.get("difficulty_name", "Necromancer")))  # Difficulty (+ Hyper).
	var mods: PackedStringArray = summary.get("modifier_names", PackedStringArray())
	var standard := String(summary.get("difficulty_id", "necromancer")) == "necromancer" and mods.is_empty() and not bool(summary.get("hyper", false))
	var dif := UiTheme.tier_label(label + ("" if mods.is_empty() else " · %d modifier%s" % [mods.size(), "" if mods.size() == 1 else "s"]),
		UiTheme.Tier.BODY, UiTheme.TEXT_DIM if standard else Palette.CRIMSON.lightened(0.45))
	col.add_child(dif)
	for s in order(game.coop):
		col.add_child(card(game, s, s.index == game.coop.view_slot))
	return col


## The slots in card order: this machine's player first, then the others.
static func order(co: CoopSession) -> Array[CoopSlot]:
	var out: Array[CoopSlot] = []
	if co.view_slot >= 0 and co.view_slot < co.slots.size():
		out.append(co.slots[co.view_slot])
	for s in co.slots:
		if s.index != co.view_slot:
			out.append(s)
	return out


## One player's card (`local`: this machine's player).
static func card(game: Game, s: CoopSlot, local: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.style("panel", "violet" if local else "dim"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var head := HBoxContainer.new()  # Bust | name, character.
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(head)
	var bust := CoopBust.new(CoopHudData.RESULTS_PORTRAIT, CoopHudData.RESULTS_PORTRAIT_DROP, true)
	bust.show_player(s.player, s.downed)
	head.add_child(bust)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -4)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(names)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 8)
	nrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(nrow)
	var n := UiTheme.tier_label(s.display_name, UiTheme.Tier.NAME, UiTheme.TEXT if local else CoopHudData.PARTNER)
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(n)
	if local:
		var you := UiTheme.tier_label(CoopHudData.TEXT_YOU, UiTheme.Tier.BODY, CoopHudData.PARTNER)
		you.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nrow.add_child(you)
	var ch := UiTheme.tier_label(s.character.display_name() if s.character != null else "", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	names.add_child(ch)
	vb.add_child(UiTheme.tier_label(stats_line(game, s), UiTheme.Tier.BODY, UiTheme.TEXT))
	vb.add_child(build_row(s))
	return panel


## "812 slain · Lv 32 · 1 down · 2 raised" for slot `s` (the shared level).
static func stats_line(game: Game, s: CoopSlot) -> String:
	return "%d slain · Lv %d · %d down%s · %d raised" % [s.kills, game.level, s.downs, "" if s.downs == 1 else "s", s.revives_given]


## Slot `s`'s build as one row of small icons with level pips: summon classes
## and spells (as the HUD's active slots), a gap, then passives.
static func build_row(s: CoopSlot) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var acts := actives(s)
	var pas: Array[Dictionary] = []  # Owned passives.
	if s.abilities != null:
		pas = s.abilities.owned_passives()
	var shown := 0  # Icons placed (capped to fit the column).
	for e: Dictionary in acts:
		if shown >= CoopHudData.RESULTS_ICONS_PER_ROW:
			break
		row.add_child(_icon(e))
		shown += 1
	if not acts.is_empty() and not pas.is_empty():
		var gap := Control.new()  # Sets the passives apart.
		gap.custom_minimum_size = Vector2(6, 0)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(gap)
	for e: Dictionary in pas:
		if shown >= CoopHudData.RESULTS_ICONS_PER_ROW:
			break
		row.add_child(_icon(e))
		shown += 1
	return row


## Slot `s`'s actives (summon classes, then spells): [{icon, level, max}], as
## AbilityManager.owned_actives() lists them but from the slot's own army.
static func actives(s: CoopSlot) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if s.horde != null:
		for cls: String in UnitData.CLASS_ORDER:
			var lvl := int(s.horde.class_levels[cls])
			if lvl > 0:
				out.append({"icon": s.horde.evolutions.class_icon(cls), "level": lvl, "max": 5})
	if s.abilities != null:
		for id: String in AbilityData.SPELL_ORDER:
			var lvl := s.abilities.spell_level(id)
			if lvl > 0:
				var evo := String(s.abilities.evolved.get(id, ""))  # Evolution id ("" = not evolved).
				var icon := String(EvolutionData.EVOLUTIONS[evo]["icon"]) if evo != "" else String(AbilityData.SPELLS[id]["icon"])
				out.append({"icon": icon, "level": lvl, "max": (AbilityData.SPELLS[id]["levels"] as Array).size()})
	return out


## One small build icon (RESULTS_ICON px, its level pips under it).
static func _icon(e: Dictionary) -> IconGlyph:
	var side := CoopHudData.RESULTS_ICON
	var g := IconGlyph.new(String(e["icon"]), Vector2(side, side + RunBuild.PIP_BAND))
	g.set_icon(String(e["icon"]), int(e["level"]), int(e["max"]))
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g
