## Hud — in-run heads-up display laid out per GDD §16:
##   Top edge      : XP bar.
##   Top left      : level, HP, shields (Orb Shield intercept charges).
##   Top center    : timer, battle zone (Crimson March, Sanctum; the Sanctum
##                   adds its corruption), objective, boss HP
##                   when present (named after the stage boss), and a smaller
##                   miniboss bar under it while a stage miniboss lives (the
##                   Sanctum's Cathedral Guardian, registered by its kit:
##                   EnemyDirector.miniboss_alive(), named by its display
##                   name).
##   Top right     : kill count, modifiers (the difficulty level, the
##                   active run modifiers and their Soul Ash multiplier,
##                   then the Profane Pact level and Profane Oath tier with
##                   their combined effect; game.difficulty), shown only
##                   when something differs from the standard run (no
##                   permanent developer hint line: the pause menu shows
##                   the controls as InputHints chips). It moves left while
##                   the touch controls' pause button holds the corner
##                   (set_top_right_inset(); phones and tablets).
##   Left, under HP: timed power-up buffs (Hyper, Stasis, Dark Frenzy) with
##                   their remaining time (game.powerups).
##   Bottom center : active ability slots (6) and passive slots (6) with levels,
##                   flanked by the Grave Step charges (left) and the Dread
##                   Rally soul meter / ready state (right; HudAbilities).
##   Bottom left   : army total / capacity and per-class counts with
##                   replacement progress bars (an evolved class shows its
##                   evolution's icon and name); active army synergies
##                   (GDD §6.3) listed above them.
##   Upper middle  : the ONE banner slot (HudBanners): event banners from the
##                   enemy director and the announcements (announce(): a
##                   synergy, an evolution, a zone, a revive), one at a time
##                   from a short queue, on a ribbon plate (gold evolution /
##                   synergy, crimson Covenant events, violet otherwise),
##                   hidden while a panel pauses the run.
##   Bottom left   : beside the army list, the army stance column (four
##                   stance icons with their keys) and, under the
##                   necromancer, the stance banner (StanceBar).
## Built entirely in code and refreshed at 10 Hz by polling the Game (cheaper
## and simpler than wiring dozens of per-frame signals). Text sizes are
## UiTheme type tiers; the Shadow Bolt aim line carries the aim key's
## InputHints chip (current device and bindings). The XP bar is inset from
## the screen edge in its kit frame with room for its numbers, and the HP
## bar has quarter notches and a damage trail (HudBar; InRunUiData).
class_name Hud
extends Control

## HUD refresh period in seconds.
const REFRESH: float = 0.1

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
## Crimson March battle zone under the timer ("Zone II - The Fortified
## Checkpoint"; hidden on stages without zones).
var _zone_label: Label
## Current objective text.
var _objective_label: Label
## The one banner slot (event banners and announcements).
var _banners: HudBanners
## Container for the boss name + HP bar (hidden until the boss arrives).
var _boss_box: VBoxContainer
## Boss HP bar.
var _boss_bar: HudBar
## Container for the miniboss name + HP bar (hidden while none lives; shown
## under the boss bar if both live).
var _mini_box: VBoxContainer
## Miniboss name label (its display name).
var _mini_name: Label
## Miniboss HP bar (red, smaller than the gold boss bar).
var _mini_bar: HudBar
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
## Row holding the aim label and the aim key chip (hidden without the bolt).
var _aim_row: HBoxContainer
## Synergy id -> HBoxContainer row (icon + name), shown while active.
var _synergy_rows: Dictionary = {}
## "Modifiers" label (top right): difficulty, run modifiers, Pact / Oath;
## hidden while the run is the standard one.
var _mods_label: Label
## Timed buff id -> {"row": HBoxContainer, "label": Label, "bar": HudBar}.
var _buff_rows: Dictionary = {}
## Top-right block (kills, modifiers); moved left while the touch controls'
## pause button sits in that corner (set_top_right_inset()).
var _top_right: BoxContainer
## The top-right block's left / right offsets from the right edge (layout
## px, before any inset).
var _top_right_offsets := Vector2(-300.0, -16.0)


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
	# XP bar: full width along the top edge, inset so its kit frame shows.
	_xp_bar = HudBar.new(Palette.XP, Vector2(0, InRunUiData.XP_HEIGHT))
	_xp_bar.anchor_right = 1.0
	_xp_bar.offset_left = InRunUiData.XP_INSET_X
	_xp_bar.offset_right = -InRunUiData.XP_INSET_X
	_xp_bar.offset_top = InRunUiData.XP_TOP
	_xp_bar.offset_bottom = InRunUiData.XP_TOP + InRunUiData.XP_HEIGHT
	_xp_bar.font_size = 11
	add_child(_xp_bar)

	# Top left: level, HP, shields.
	var top_left := _box(true, 0.0, 0.0, 16, 24, 300, 114, BoxContainer.ALIGNMENT_BEGIN)
	_level_label = UiTheme.tier_label("Lv 1", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	top_left.add_child(_level_label)
	_hp_bar = HudBar.new(Palette.HP_FRIENDLY, InRunUiData.HP_SIZE)
	_hp_bar.notch = InRunUiData.HP_NOTCH
	_hp_bar.trail = true
	top_left.add_child(_hp_bar)
	_ward_label = UiTheme.tier_label("", UiTheme.Tier.BODY, Palette.VIOLET.lightened(0.3))
	top_left.add_child(_ward_label)
	_shield_label = UiTheme.tier_label("", UiTheme.Tier.BODY, Palette.NECRO_GREEN)
	top_left.add_child(_shield_label)

	# Top center: timer, zone, objective, boss (the banner slot sits under it).
	var tc := _box(true, 0.5, 0.0, -260, 20, 260, 160, BoxContainer.ALIGNMENT_BEGIN)
	tc.grow_horizontal = Control.GROW_DIRECTION_BOTH  # Stays centred when the banner widens it.
	_timer_label = UiTheme.tier_label("00:00", UiTheme.Tier.HEADER)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_timer_label)
	var zone_col := Palette.CRIMSON.lightened(0.45)  # Zone line colour (the stage's zone colour if set).
	if game.enemies.march != null and game.enemies.march.config.has("zone_color"):
		zone_col = game.enemies.march.zone_color()
	_zone_label = UiTheme.tier_label("", UiTheme.Tier.BODY, zone_col)
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_label.visible = false
	tc.add_child(_zone_label)
	_objective_label = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_objective_label)
	_boss_box = VBoxContainer.new()
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	var boss_name := UiTheme.tier_label(String(game.stage_def["boss"]["display_name"]), UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)  # The stage boss.
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(boss_name)
	_boss_bar = HudBar.new(Palette.GOLD, Vector2(520, 14))
	_boss_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Keeps 520 px under a wider banner.
	_boss_box.add_child(_boss_bar)
	tc.add_child(_boss_box)
	_mini_box = VBoxContainer.new()
	_mini_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_box.visible = false
	_mini_name = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	_mini_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mini_box.add_child(_mini_name)
	_mini_bar = HudBar.new(Palette.HP_ENEMY, Vector2(360, 10))
	_mini_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_mini_bar.font_size = 10
	_mini_box.add_child(_mini_bar)
	tc.add_child(_mini_box)

	# Top right: kills, modifiers (only when not the standard run).
	var top_right := _box(true, 1.0, 0.0, _top_right_offsets.x, 24, _top_right_offsets.y, 114, BoxContainer.ALIGNMENT_BEGIN)
	_top_right = top_right
	_kills_label = UiTheme.tier_label("Kills: 0", UiTheme.Tier.NAME)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(_kills_label)
	_mods_label = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_mods_label.visible = false
	_mods_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Many run modifiers wrap.
	_mods_label.custom_minimum_size = Vector2(284, 0)
	top_right.add_child(_mods_label)

	# Left, under the HP block: running power-up buffs with time left.
	var buffs := _box(true, 0.0, 0.0, 16, 120, 300, 224, BoxContainer.ALIGNMENT_BEGIN)  # Buff rows column.
	for kind: String in PowerupData.TIMED:
		var def: Dictionary = PowerupData.POWERUPS[kind]  # Buff definition.
		var brow := HBoxContainer.new()  # Icon + "Name 7.2s" + time bar.
		brow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brow.add_child(IconGlyph.new(String(def["icon"]), Vector2(24, 24)))
		var blabel := UiTheme.tier_label("", UiTheme.Tier.BODY, (def["color"] as Color).lightened(0.25))  # "Hyper 7.2s".
		blabel.custom_minimum_size = Vector2(130, 0)
		brow.add_child(blabel)
		var bbar := HudBar.new(def["color"], Vector2(70, 6))  # Remaining-time bar.
		bbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bbar.border_color = Color(0, 0, 0, 0)
		brow.add_child(bbar)
		brow.visible = false
		buffs.add_child(brow)
		_buff_rows[kind] = {"row": brow, "label": blabel, "bar": bbar}

	# Bottom left: army panel. There is one row per class id in CLASS_ORDER
	# (10 with the split priest and the later classes), but only OWNED classes
	# are visible and each takes an active slot, so at most
	# PlayerData.ACTIVE_SLOTS (6) rows show at once. Compact rows (22 px icons,
	# 2 px gaps) keep the worst case, header + 6 rows = ~25 + 6 x 24 = 169 px,
	# inside the 190 px box (24 px rows with the default 4 px gaps would not).
	var bl := _box(true, 0.0, 1.0, 16, -206, 300, -16, BoxContainer.ALIGNMENT_END)
	bl.add_theme_constant_override("separation", 2)
	_army_label = UiTheme.tier_label("Army 0 / 0", UiTheme.Tier.NAME, Palette.NECRO_GREEN)
	bl.add_child(_army_label)
	for cls: String in UnitData.CLASS_ORDER:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := IconGlyph.new(cls, Vector2(22, 22))  # Class (or evolution) icon.
		row.add_child(icon)
		var lbl := UiTheme.tier_label("", UiTheme.Tier.BODY)
		lbl.custom_minimum_size = Vector2(130, 0)  # Fits "Frost Wraiths 3/3".
		row.add_child(lbl)
		var bar := HudBar.new(Palette.NECRO_GREEN, Vector2(70, 6))
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.border_color = Color(0, 0, 0, 0)
		row.add_child(bar)
		row.visible = false
		bl.add_child(row)
		_class_rows[cls] = {"row": row, "icon": icon, "label": lbl, "bar": bar}

	# Bottom left, above the army panel: active synergies (only the active
	# ones show). With the newer classes' synergies up to 7 can be active at
	# once (6 active slots); compact rows (22 px icons, 2 px gaps) fit 8 in
	# the 200 px box (8 x 24 = 192 px), which ends 4 px above the army panel
	# and starts well below the buff rows (y 120-224).
	var syn := _box(true, 0.0, 1.0, 16, -410, 300, -210, BoxContainer.ALIGNMENT_END)
	syn.add_theme_constant_override("separation", 2)
	for id: String in SynergyData.ORDER:
		var srow := HBoxContainer.new()
		srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		srow.add_child(IconGlyph.new(String(SynergyData.SYNERGIES[id]["icon"]), Vector2(22, 22)))
		srow.add_child(UiTheme.tier_label(String(SynergyData.SYNERGIES[id]["short_name"]), UiTheme.Tier.BODY, Palette.NECRO_GREEN.lightened(0.2)))
		srow.visible = false
		syn.add_child(srow)
		_synergy_rows[id] = srow

	# Upper middle, under the top-centre block: the one banner slot.
	_banners = HudBanners.new()
	_banners.game = game
	_banners.anchor_box = tc
	add_child(_banners)

	# Bottom left, beside the army list: the army stance bar and its banner.
	var stance_bar := StanceBar.new()  # Stance icons + banner overlay.
	stance_bar.game = game
	add_child(stance_bar)

	# Bottom center: ability bar (actives row, passives row).
	var bc := _box(true, 0.5, 1.0, -200, -130, 200, -12, BoxContainer.ALIGNMENT_END)
	_aim_row = HBoxContainer.new()
	_aim_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_aim_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aim_row.add_theme_constant_override("separation", 6)
	_aim_row.visible = false
	bc.add_child(_aim_row)
	_aim_label = UiTheme.tier_label("", UiTheme.Tier.BODY, Palette.VIOLET.lightened(0.35))
	_aim_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_aim_row.add_child(_aim_label)
	_aim_row.add_child(InputHints.chip("toggle_aim"))  # Aim toggle key (T / Y), follows rebinds.
	var actives := HBoxContainer.new()
	actives.alignment = BoxContainer.ALIGNMENT_CENTER
	actives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.add_child(actives)
	for i in PlayerData.ACTIVE_SLOTS:
		var g := IconGlyph.new("", Vector2(42, 48))
		g.slot_frame = true  # UI kit slot socket.
		actives.add_child(g)
		_active_icons.append(g)
	var passives := HBoxContainer.new()
	passives.alignment = BoxContainer.ALIGNMENT_CENTER
	passives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.add_child(passives)
	for i in PlayerData.PASSIVE_SLOTS:
		var g := IconGlyph.new("", Vector2(32, 38))
		g.slot_frame = true  # UI kit slot socket.
		passives.add_child(g)
		_passive_icons.append(g)

	# Bottom center, flanking the ability bar: Grave Step charges and the
	# Dread Rally meter (HudAbilities draws and refreshes itself).
	add_child(HudAbilities.new(game))


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
	if game.enemies.march != null:
		_zone_label.visible = true
		_zone_label.text = game.enemies.march.zone_label()
		if game.enemies.sanctum != null:
			_zone_label.text += game.enemies.sanctum.hud_suffix()
	_objective_label.text = game.enemies.objective_text()
	var boss := game.enemies.boss
	_boss_box.visible = boss != null and boss.active
	if _boss_box.visible:
		_boss_bar.set_values(boss.hp / boss.max_hp, "%d / %d" % [ceili(boss.hp), int(boss.max_hp)])
	var mb := game.enemies.miniboss_alive()  # Living miniboss (null = none).
	_mini_box.visible = mb != null
	if _mini_box.visible:
		_mini_name.text = mb.display_name
		_mini_bar.set_values(mb.hp / mb.max_hp, "%d / %d" % [ceili(mb.hp), ceili(mb.max_hp)])
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
	_aim_row.visible = game.abilities.spell_level("shadow_bolt") > 0
	_aim_label.text = "%s aim: %s" % [game.abilities.spell_name("shadow_bolt"), game.abilities.bolt_aim_name()] if _aim_row.visible else ""
	for id: String in SynergyData.ORDER:
		(_synergy_rows[id] as Control).visible = h.synergies.is_active(id)
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


## Updates the power-up buff rows and the Modifiers label (difficulty level,
## run modifiers, Pact / Oath).
func _refresh_modifiers() -> void:
	for kind: String in PowerupData.TIMED:
		var row: Dictionary = _buff_rows[kind]  # Widgets of this buff.
		var left := game.powerups.time_left(kind)  # Seconds of this buff left.
		(row["row"] as Control).visible = left > 0.0
		if left > 0.0:
			(row["label"] as Label).text = "%s %.1fs" % [PowerupData.POWERUPS[kind]["display_name"], left]
			(row["bar"] as HudBar).set_values(left / float(PowerupData.POWERUPS[kind]["duration"]))
	var dif := game.difficulty  # The one difficulty path.
	_mods_label.text = "\n".join(dif.hud_lines())
	var hot := dif.is_active() or dif.has_run_setup()  # Anything beyond the standard run.
	_mods_label.visible = hot  # The standard run shows nothing here.
	_mods_label.add_theme_color_override("font_color", Palette.CRIMSON.lightened(0.45))


## Shows an announcement in the banner slot: `title` (the small kicker),
## `item_name` (the headline, in `color` unless it is an evolution /
## synergy, which are gold) and `desc` (the sub-line). Queued behind a
## banner on show; timed in game time, so one raised while the level-up
## panel pauses the game is seen after resuming (HudBanners).
func announce(title: String, item_name: String, desc: String, color: Color) -> void:
	_banners.push_announce(title, item_name, desc, color)


## Moves the top-right block (kills, modifiers) `px` layout px to the left,
## clear of the touch controls' pause button (TouchControls; 0 = its usual
## place). Purely layout.
func set_top_right_inset(px: float) -> void:
	if _top_right == null:
		return
	_top_right.offset_left = _top_right_offsets.x - px
	_top_right.offset_right = _top_right_offsets.y - px
