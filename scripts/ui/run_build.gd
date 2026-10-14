## RunBuild — read-only snapshots of the current run's build for the pause
## screen and the results card: the spells, the passives and the army, each
## as plain entries, plus the small widgets that show them (an icon row with
## level pips, an army row of class icons with "x7" counts, a LABEL-tier
## section caption). It only READS the run (AbilityManager levels, the
## horde's class levels, counts and evolutions): no state is changed and no
## RNG is drawn. Icons go through IconGlyph (the 32 px badge art).
class_name RunBuild
extends RefCounted

## Gap (px) between two icons in a row.
const GAP: int = 6
## Height (px) of the level pips under an IconGlyph (IconGlyph draws them
## 4 px tall in a 6 px band).
const PIP_BAND: float = 6.0


## Owned spells in the spell order: [{icon, level, max, name}] (an evolved
## spell shows its evolution's icon and name).
static func spells(game: Game) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null or game.abilities == null:
		return out
	var ab := game.abilities
	for id: String in AbilityData.SPELL_ORDER:
		var lvl := ab.spell_level(id)  # 0 = not owned.
		if lvl <= 0:
			continue
		var evo := String(ab.evolved.get(id, ""))  # Evolution id ("" = not evolved).
		var icon := String(EvolutionData.EVOLUTIONS[evo]["icon"]) if evo != "" else String(AbilityData.SPELLS[id]["icon"])
		out.append({"icon": icon, "level": lvl, "max": (AbilityData.SPELLS[id]["levels"] as Array).size(), "name": ab.spell_name(id)})
	return out


## Owned passives: [{icon, level, max, name}].
static func passives(game: Game) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null or game.abilities == null:
		return out
	for id: String in PassiveData.ORDER:
		var lvl := game.abilities.passive_level(id)  # 0 = not owned.
		if lvl > 0:
			var def: Dictionary = PassiveData.PASSIVES[id]
			out.append({"icon": String(def["icon"]), "level": lvl, "max": (def["levels"] as Array).size(), "name": String(def["display_name"])})
	return out


## Owned summon classes: [{icon, level, count, name}] (an evolved class shows
## its evolution's icon and plural).
static func army(game: Game) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if game == null or game.horde == null:
		return out
	var h := game.horde
	for cls: String in UnitData.CLASS_ORDER:
		var lvl := int(h.class_levels[cls])  # 0 = not owned.
		if lvl > 0:
			out.append({"icon": h.evolutions.class_icon(cls), "level": lvl, "count": h.count_of(cls), "name": h.evolutions.class_plural(cls)})
	return out


## A row of IconGlyphs (`side` px squares) for `entries` (spells() /
## passives() format), each with its level pips under it and its name as a
## tooltip.
static func icon_row(entries: Array[Dictionary], side: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", GAP)
	for e: Dictionary in entries:
		var g := IconGlyph.new(String(e["icon"]), Vector2(side, side + PIP_BAND))
		g.set_icon(String(e["icon"]), int(e["level"]), int(e["max"]))
		g.tooltip_text = String(e["name"])
		g.mouse_filter = Control.MOUSE_FILTER_PASS  # Shows the name on hover.
		row.add_child(g)
	return row


## A row of class icons (`side` px) with their unit counts ("x7") for
## `entries` (army() format); the class name is the tooltip.
static func army_row(entries: Array[Dictionary], side: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", GAP + 4)
	for e: Dictionary in entries:
		var cell := HBoxContainer.new()  # Icon + count.
		cell.add_theme_constant_override("separation", 2)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.tooltip_text = String(e["name"])
		var g := IconGlyph.new(String(e["icon"]), Vector2(side, side))
		g.mouse_filter = Control.MOUSE_FILTER_PASS
		g.tooltip_text = String(e["name"])
		cell.add_child(g)
		var n := UiTheme.tier_label("×%d" % int(e["count"]), UiTheme.Tier.BODY, Palette.NECRO_GREEN.lightened(0.15))
		n.size_flags_vertical = Control.SIZE_SHRINK_END
		cell.add_child(n)
		row.add_child(cell)
	return row


## A LABEL-tier section caption ("SPELLS") in the dim text colour.
static func caption(s: String) -> Label:
	return UiTheme.tier_label(s, UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)


## Frees every child of `box` after detaching it at once, so a rebuilt
## Container never measures the old and the new children together (a
## CenterContainer above it would grow to that sum and keep the size).
static func clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


## "m:ss" for `seconds` (>= 0).
static func clock(seconds: float) -> String:
	var t := maxi(0, int(seconds))
	return "%d:%02d" % [floori(float(t) / 60.0), t % 60]
