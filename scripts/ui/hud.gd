## Hud — in-run heads-up display laid out per GDD §16:
##   Top edge      : XP bar.
##   Top left      : level, HP, shields (Orb Shield intercept charges).
##   Top center    : timer, objective / event banner, boss HP when present.
##   Top right     : kill count, pause hint, modifiers (the Profane Pact
##                   level and Profane Oath tier with their combined effect,
##                   from game.difficulty).
##   Left, under HP: timed power-up buffs (Hyper, Stasis, Dark Frenzy) with
##                   their remaining time (game.powerups).
##   Bottom center : active ability slots (6) and passive slots (6) with levels.
##   Bottom left   : army total / capacity and per-class counts with
##                   replacement progress bars (an evolved class shows its
##                   evolution's icon and name); active army synergies
##                   (GDD §6.3) listed above them.
##   Upper middle  : progression banner announcing a synergy activation or a
##                   spell evolution (announce()).
## Built entirely in code and refreshed at 10 Hz by polling the Game (cheaper
## and simpler than wiring dozens of per-frame signals).
class_name Hud
extends Control

## HUD refresh period in seconds.
const REFRESH: float = 0.1
## Seconds of game time the progression banner stays fully visible.
const ANNOUNCE_TIME: float = 3.5  # TUNING (not in GDD)
## Seconds the progression banner takes to fade out afterwards.
const ANNOUNCE_FADE: float = 0.8  # TUNING (not in GDD)

## Owning run.
var game: Game
## Time accumulated toward the next refresh.
var _accum: float = 0.0
## XP bar along the top edge.
var _xp_bar: HudBar
## "Lv N" label.
var _level_label: Label
## Player HP bar.
var _hp_bar: HudBar
## Orb Shield charges ("shields") label.
var _ward_label: Label
## Ward on the necromancer label (cast by Warders / Profane Bishops).
var _shield_label: Label
## Run timer.
var _timer_label: Label
## Current objective text.
var _objective_label: Label
## Event banner (gold, temporary).
var _banner_label: Label
## Container for the boss name + HP bar (hidden until the boss arrives).
var _boss_box: VBoxContainer
## Boss HP bar.
var _boss_bar: HudBar
## Kill counter.
var _kills_label: Label
## "Army N / cap" label.
var _army_label: Label
## Class id -> {"row": HBoxContainer, "icon": IconGlyph, "label": Label, "bar": HudBar}.
var _class_rows: Dictionary = {}
## Active ability slot icons.
var _active_icons: Array[IconGlyph] = []
## Passive ability slot icons.
var _passive_icons: Array[IconGlyph] = []
## Shadow Bolt aim mode label above the ability bar.
var _aim_label: Label
## Synergy id -> HBoxContainer row (icon + name), shown while active.
var _synergy_rows: Dictionary = {}
## Progression banner container (title, name, description).
var _announce_box: VBoxContainer
## Progression banner small title ("SYNERGY AWAKENED" / "EVOLUTION").
var _announce_title: Label
## Progression banner big name line.
var _announce_name: Label
## Progression banner effect description line.
var _announce_desc: Label
## Game time (Game.elapsed) at which the current banner was shown (-1 = none).
var _announce_at: float = -1.0
## "Modifiers" label (top right): "none", or the Pact / Oath and their effect.
var _mods_label: Label
## Timed buff id -> {"row": HBoxContainer, "label": Label, "bar": HudBar}.
var _buff_rows: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_refresh()


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= REFRESH:
		_accum = 0.0
		_refresh()


## Creates a Box container anchored at (ax, ay) with the given pixel rect
## offsets. Children align to `align` inside it.
func _box(vertical: bool, ax: float, ay: float, l: float, t: float, r: float, b: float, align: BoxContainer.AlignmentMode) -> BoxContainer:
	var box: BoxContainer
	if vertical:
		box = VBoxContainer.new()
	else:
		box = HBoxContainer.new()
	box.anchor_left = ax
	box.anchor_right = ax
	box.anchor_top = ay
	box.anchor_bottom = ay
	box.offset_left = l
	box.offset_top = t
	box.offset_right = r
	box.offset_bottom = b
	box.alignment = align
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	return box


## Builds every widget.
func _build() -> void:
	# XP bar: full width along the top edge.
	_xp_bar = HudBar.new(Palette.XP, Vector2(0, 12))
	_xp_bar.anchor_right = 1.0
	_xp_bar.offset_bottom = 12.0
	_xp_bar.font_size = 11
	add_child(_xp_bar)

	# Top left: level, HP, shields.
	var top_left := _box(true, 0.0, 0.0, 16, 20, 300, 110, BoxContainer.ALIGNMENT_BEGIN)
	_level_label = UiTheme.label("Lv 1", 22, UiTheme.TEXT_GOLD)
	top_left.add_child(_level_label)
	_hp_bar = HudBar.new(Palette.HP_FRIENDLY, Vector2(240, 18))
	top_left.add_child(_hp_bar)
	_ward_label = UiTheme.label("", 13, Palette.VIOLET.lightened(0.3))
	top_left.add_child(_ward_label)
	_shield_label = UiTheme.label("", 13, Palette.NECRO_GREEN)
	top_left.add_child(_shield_label)

	# Top center: timer, objective, banner, boss.
	var tc := _box(true, 0.5, 0.0, -260, 16, 260, 160, BoxContainer.ALIGNMENT_BEGIN)
	_timer_label = UiTheme.label("00:00", 32)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_timer_label)
	_objective_label = UiTheme.label("", 14, UiTheme.TEXT_DIM)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_objective_label)
	_banner_label = UiTheme.label("", 20, UiTheme.TEXT_GOLD)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_banner_label)
	_boss_box = VBoxContainer.new()
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	var boss_name := UiTheme.label(String(EnemyData.BOSS["display_name"]), 16, UiTheme.TEXT_GOLD)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(boss_name)
	_boss_bar = HudBar.new(Palette.GOLD, Vector2(520, 14))
	_boss_box.add_child(_boss_bar)
	tc.add_child(_boss_box)

	# Top right: kills, pause hint, modifiers.
	var top_right := _box(true, 1.0, 0.0, -300, 20, -16, 110, BoxContainer.ALIGNMENT_BEGIN)
	_kills_label = UiTheme.label("Kills: 0", 20)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(_kills_label)
	var hint := UiTheme.label("Esc: Pause   T / Y: Bolt aim   F3: Debug", 13, UiTheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(hint)
	_mods_label = UiTheme.label("Modifiers: none  |  Difficulty: Necromancer", 13, UiTheme.TEXT_DIM)
	_mods_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(_mods_label)

	# Left, under the HP block: running power-up buffs with time left.
	var buffs := _box(true, 0.0, 0.0, 16, 116, 300, 220, BoxContainer.ALIGNMENT_BEGIN)  # Buff rows column.
	for kind: String in PowerupData.TIMED:
		var def: Dictionary = PowerupData.POWERUPS[kind]  # Buff definition.
		var brow := HBoxContainer.new()  # Icon + "Name 7.2s" + time bar.
		brow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brow.add_child(IconGlyph.new(String(def["icon"]), Vector2(24, 24)))
		var blabel := UiTheme.label("", 14, (def["color"] as Color).lightened(0.25))  # "Hyper 7.2s".
		blabel.custom_minimum_size = Vector2(130, 0)
		brow.add_child(blabel)
		var bbar := HudBar.new(def["color"], Vector2(70, 6))  # Remaining-time bar.
		bbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bbar.border_color = Color(0, 0, 0, 0)
		brow.add_child(bbar)
		brow.visible = false
		buffs.add_child(brow)
		_buff_rows[kind] = {"row": brow, "label": blabel, "bar": bbar}

	# Bottom left: army panel (up to 6 owned classes, one per active slot).
	var bl := _box(true, 0.0, 1.0, 16, -206, 300, -16, BoxContainer.ALIGNMENT_END)
	_army_label = UiTheme.label("Army 0 / 0", 18, Palette.NECRO_GREEN)
	bl.add_child(_army_label)
	for cls: String in UnitData.CLASS_ORDER:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := IconGlyph.new(cls, Vector2(24, 24))  # Class (or evolution) icon.
		row.add_child(icon)
		var lbl := UiTheme.label("", 14)
		lbl.custom_minimum_size = Vector2(120, 0)
		row.add_child(lbl)
		var bar := HudBar.new(Palette.NECRO_GREEN, Vector2(70, 6))
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.border_color = Color(0, 0, 0, 0)
		row.add_child(bar)
		row.visible = false
		bl.add_child(row)
		_class_rows[cls] = {"row": row, "icon": icon, "label": lbl, "bar": bar}

	# Bottom left, above the army panel: active synergies.
	var syn := _box(true, 0.0, 1.0, 16, -316, 300, -210, BoxContainer.ALIGNMENT_END)
	for id: String in SynergyData.ORDER:
		var srow := HBoxContainer.new()
		srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		srow.add_child(IconGlyph.new(String(SynergyData.SYNERGIES[id]["icon"]), Vector2(22, 22)))
		srow.add_child(UiTheme.label(String(SynergyData.SYNERGIES[id]["short_name"]), 13, Palette.NECRO_GREEN.lightened(0.2)))
		srow.visible = false
		syn.add_child(srow)
		_synergy_rows[id] = srow

	# Upper middle: progression banner (synergy activation / evolution).
	_announce_box = _box(true, 0.5, 0.0, -360, 170, 360, 290, BoxContainer.ALIGNMENT_BEGIN)
	_announce_title = UiTheme.label("", 15, UiTheme.TEXT_DIM)
	_announce_name = UiTheme.label("", 30, UiTheme.TEXT_GOLD)
	_announce_desc = UiTheme.label("", 14, UiTheme.TEXT)
	for l: Label in [_announce_title, _announce_name, _announce_desc]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_announce_box.add_child(l)
	_announce_box.visible = false

	# Bottom center: ability bar (actives row, passives row).
	var bc := _box(true, 0.5, 1.0, -200, -130, 200, -12, BoxContainer.ALIGNMENT_END)
	_aim_label = UiTheme.label("", 13, Palette.VIOLET.lightened(0.35))
	_aim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bc.add_child(_aim_label)
	var actives := HBoxContainer.new()
	actives.alignment = BoxContainer.ALIGNMENT_CENTER
	actives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.add_child(actives)
	for i in PlayerData.ACTIVE_SLOTS:
		var g := IconGlyph.new("", Vector2(42, 48))
		actives.add_child(g)
		_active_icons.append(g)
	var passives := HBoxContainer.new()
	passives.alignment = BoxContainer.ALIGNMENT_CENTER
	passives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.add_child(passives)
	for i in PlayerData.PASSIVE_SLOTS:
		var g := IconGlyph.new("", Vector2(32, 38))
		passives.add_child(g)
		_passive_icons.append(g)


## Pulls current values from the Game into the widgets.
func _refresh() -> void:
	if game == null or game.player == null:
		return
	var p := game.player
	_xp_bar.set_values(float(game.xp) / float(game.xp_to_next), "XP %d / %d" % [game.xp, game.xp_to_next])
	_level_label.text = "Lv %d" % game.level
	_hp_bar.set_values(p.hp / p.max_hp, "%d / %d" % [ceili(p.hp), int(p.max_hp)])
	var orbs := game.abilities.orb_shield
	if orbs != null:
		_ward_label.text = "Orb shields ready: %d / %d" % [orbs.charges_ready(), orbs.recharge.size()]
	else:
		_ward_label.text = ""
	_shield_label.text = "Ward: %d HP (%.1fs)" % [ceili(p.shield_hp), p.shield_time] if p.shield_hp > 0.0 else ""
	# Countdown (user brief): 20:00 -> 0:00, then "RECKONING +m:ss".
	if game.countdown_finished():
		var over := int(game.elapsed - WaveData.RUN_DURATION)
		_timer_label.text = "RECKONING +%d:%02d" % [floori(float(over) / 60.0), over % 60]
		_timer_label.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.25))
	else:
		var t := ceili(game.time_remaining())
		_timer_label.text = "%02d:%02d" % [floori(float(t) / 60.0), t % 60]
	_objective_label.text = game.enemies.objective_text()
	_banner_label.text = game.enemies.banner_text if game.elapsed < game.enemies.banner_until else ""
	var boss := game.enemies.boss
	_boss_box.visible = boss != null and boss.active
	if _boss_box.visible:
		_boss_bar.set_values(boss.hp / boss.max_hp, "%d / %d" % [ceili(boss.hp), int(boss.max_hp)])
	_kills_label.text = "Kills: %d" % game.kills
	var h := game.horde
	_army_label.text = "Army %d / %d" % [h.units.size(), h.total_capacity()]
	for cls: String in UnitData.CLASS_ORDER:
		var row: Dictionary = _class_rows[cls]
		var owned := int(h.class_levels[cls]) > 0
		(row["row"] as Control).visible = owned
		if owned:
			(row["icon"] as IconGlyph).set_icon(h.evolutions.class_icon(cls))
			(row["label"] as Label).text = "%s %d/%d" % [h.evolutions.class_plural(cls), h.count_of(cls), h.capacity(cls)]
			(row["bar"] as HudBar).set_values(h.replenish_progress(cls))
	_aim_label.text = "%s aim: %s  [T / Y]" % [game.abilities.spell_name("shadow_bolt"), game.abilities.bolt_aim_name()] if game.abilities.spell_level("shadow_bolt") > 0 else ""
	for id: String in SynergyData.ORDER:
		(_synergy_rows[id] as Control).visible = h.synergies.is_active(id)
	_refresh_announce()
	_refresh_modifiers()
	var actives := game.abilities.owned_actives()
	for i in _active_icons.size():
		if i < actives.size():
			_active_icons[i].set_icon(actives[i]["icon"], actives[i]["level"], actives[i]["max"])
		else:
			_active_icons[i].set_icon("")
	var passives := game.abilities.owned_passives()
	for i in _passive_icons.size():
		if i < passives.size():
			_passive_icons[i].set_icon(passives[i]["icon"], passives[i]["level"], passives[i]["max"])
		else:
			_passive_icons[i].set_icon("")


## Updates the power-up buff rows and the Modifiers (Pact / Oath) label.
func _refresh_modifiers() -> void:
	for kind: String in PowerupData.TIMED:
		var row: Dictionary = _buff_rows[kind]  # Widgets of this buff.
		var left := game.powerups.time_left(kind)  # Seconds of this buff left.
		(row["row"] as Control).visible = left > 0.0
		if left > 0.0:
			(row["label"] as Label).text = "%s %.1fs" % [PowerupData.POWERUPS[kind]["display_name"], left]
			(row["bar"] as HudBar).set_values(left / float(PowerupData.POWERUPS[kind]["duration"]))
	var lines := game.difficulty.describe_lines()  # Empty while no Pact / Oath.
	if lines.is_empty():
		_mods_label.text = "Modifiers: none  |  Difficulty: Necromancer"
		_mods_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	else:
		_mods_label.text = "\n".join(lines)
		_mods_label.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.45))


## Shows the progression banner: `title` (small), `item_name` (big, in `color`)
## and `desc`. It stays ANNOUNCE_TIME s of game time, so a banner raised
## while the level-up panel pauses the game is seen after resuming.
func announce(title: String, item_name: String, desc: String, color: Color) -> void:
	_announce_title.text = title
	_announce_name.text = item_name
	_announce_name.add_theme_color_override("font_color", color)
	_announce_desc.text = desc
	_announce_at = game.elapsed
	_announce_box.visible = true
	_announce_box.modulate.a = 1.0


## Fades out and hides the progression banner once its time is over.
func _refresh_announce() -> void:
	if _announce_at < 0.0:
		return
	var age := game.elapsed - _announce_at
	if age > ANNOUNCE_TIME + ANNOUNCE_FADE:
		_announce_box.visible = false
		_announce_at = -1.0
	else:
		_announce_box.modulate.a = clampf(1.0 - (age - ANNOUNCE_TIME) / ANNOUNCE_FADE, 0.0, 1.0)
