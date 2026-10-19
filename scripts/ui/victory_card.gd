## VictoryCard — the widgets of the victory results card (content wave 2, GDD
## §15.0 "Victory screen (content wave 2)"), built by EndScreen's victory path
## from a VictoryResults.build() dictionary; sizes and texts in VictoryData.
##   * seal(): the stage seal stamped on the card: the stage-select vignette
##     (StageVignette, the same composed scene, no new art) in a violet frame,
##     or a gold frame with a soft gold wash and the Hyper badge on a Hyper clear;
##   * middle(): the time survived past 0:00 as a HERO number with the run time
##     and the stage's Best record, a "New record" ribbon that stamps in when this
##     run beat it, two small stat tiles (enemies slain, level), and the run
##     highlights (top-damage class, evolutions with their game times in gold,
##     chests opened, largest army, the boss kill time).
## Read-only: it shows numbers the run already produced and changes nothing.
## Motion (the stamp and the ribbon) goes through UiMotion, so it is instant
## under the autotest and with Reduce motion.
class_name VictoryCard
extends RefCounted


## The stage seal for `info` (VictoryResults.build()): the framed vignette, and
## on a Hyper clear the gold wash and a Hyper badge under it.
static func seal(info: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.style("panel", String(info["seal_accent"])))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(frame)
	var holder := Control.new()  # The vignette and its wash share one rect.
	holder.custom_minimum_size = FrontDoorData.VIGNETTE_SIZE
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(holder)
	var vig := StageVignette.new(String(info["stage_id"]), false)
	vig.set_focused(true)  # Full brightness: the stage is won.
	holder.add_child(vig)
	if bool(info["hyper_clear"]):
		var wash := ColorRect.new()  # Gold seal: a soft gold wash over the scene.
		wash.color = Color(UiTheme.TEXT_GOLD, VictoryData.SEAL_HYPER_WASH)
		wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(wash)
		var badge := HyperBadge.row(HyperData.DISPLAY_NAME, 18)
		badge.alignment = BoxContainer.ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(badge)
	return col


## The middle column for `info` and `summary`: time past 0:00 and the Best
## record, two stat tiles, then the highlights. Returns [column, record ribbon
## (null when this run set no record)] so the caller can stamp the ribbon in.
static func middle(info: Dictionary, summary: Dictionary) -> Array:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(VictoryData.MIDDLE_WIDTH, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var time_box := PanelContainer.new()
	time_box.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))
	col.add_child(time_box)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	time_box.add_child(tv)
	tv.add_child(RunBuild.caption(VictoryData.TEXT_PAST_ZERO))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	tv.add_child(row)
	var hero := UiTheme.tier_label("+%s" % RunBuild.clock(float(info["overtime"])), UiTheme.Tier.HERO, UiTheme.TEXT_GOLD)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hero)
	var record: Control = null  # The "New record" ribbon (null = none).
	if bool(info["new_record"]):
		var rib := UiTheme.ribbon("gold")
		rib.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var rl := UiTheme.tier_label(VictoryData.TEXT_NEW_RECORD, UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rib.add_child(rl)
		row.add_child(rib)
		record = rib
	var sub := "%s   ·   %s" % [VictoryData.TEXT_SURVIVED % RunBuild.clock(float(summary.get("time", 0.0))),
		VictoryData.TEXT_BEST % RunBuild.clock(float(info["best"]))]
	tv.add_child(UiTheme.tier_label(sub, UiTheme.Tier.BODY, UiTheme.TEXT_DIM))
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 8)
	col.add_child(tiles)
	tiles.add_child(_tile("Enemies slain", "%d" % int(summary.get("kills", 0))))
	tiles.add_child(_tile("Level", "%d" % int(summary.get("level", 1))))
	col.add_child(RunBuild.caption(VictoryData.TEXT_HIGHLIGHTS))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", -2)
	col.add_child(list)
	for h: Array in info["highlights"]:
		list.add_child(_row(h))
	return [col, record]


## One small stat tile: a LABEL caption over a NAME value (half the column).
static func _tile(caption: String, value: String) -> Control:
	var t := PanelContainer.new()
	t.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))
	t.custom_minimum_size = Vector2((VictoryData.MIDDLE_WIDTH - 8.0) * 0.5, VictoryData.TILE_HEIGHT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -4)
	t.add_child(vb)
	vb.add_child(RunBuild.caption(caption))
	vb.add_child(UiTheme.tier_label(value, UiTheme.Tier.NAME, UiTheme.TEXT))
	return t


## One highlight row [caption, value, kind]: the caption on the left (gold for
## an evolution, gold = evolution), the value on the right.
static func _row(h: Array) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var evo := String(h[2]) == "evolution"  # An evolution row.
	var n := UiTheme.tier_label(String(h[0]), UiTheme.Tier.BODY, UiTheme.TEXT_GOLD if evo else UiTheme.TEXT_DIM)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(n)
	var v := UiTheme.tier_label(String(h[1]), UiTheme.Tier.BODY, UiTheme.TEXT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row
