## CoopPartnerBar: the partner's plate on the HUD (GDD §15.0 "Co-op HUD and
## visuals"; sizes in CoopHudData). It sits in the HUD's top-right block under
## the kill count (Hud adds it there), so it moves left with that block for the
## touch pause button and never covers the local player's own bars (top left).
## Right-aligned, about 220 x 40 px:
##   [name ........ status]  [bust]
##   [====== HP bar ======]
## The name is in the partner's soul-teal; the status is his HP ("312 / 420",
## dim). Downed, the plate turns crimson: the bust greys and reddens, the
## status reads "Downed" and pulses slowly, and the bar shows the revive
## progress in green over a crimson track ("Raising" while the local player
## stands in reach). Refreshed by CoopUi at the HUD's rate. Purely visual: it
## reads the partner's slot only.
class_name CoopPartnerBar
extends HBoxContainer

## The partner's bust portrait.
var bust: CoopBust
## The partner's name.
var _name: Label
## HP numbers, or "Downed" / "Raising".
var _status: Label
## The partner's HP bar (the revive progress while downed).
var _bar: HudBar


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", CoopHudData.PLATE_GAP)
	var col := VBoxContainer.new()  # Name / status row over the bar.
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(CoopHudData.PLATE_BAR.x, 0)
	col.add_child(row)
	_name = UiTheme.tier_label("", UiTheme.Tier.BODY, CoopHudData.PARTNER)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_name)
	_status = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_status)
	_bar = HudBar.new(Palette.HP_FRIENDLY, CoopHudData.PLATE_BAR)
	_bar.notch = InRunUiData.HP_NOTCH
	_bar.trail = true
	col.add_child(_bar)
	bust = CoopBust.new()
	bust.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(bust)


## Shows slot `s` (the partner); `raising` is true while the local player
## stands in revive reach of him.
func refresh(s: CoopSlot, raising: bool) -> void:
	if s == null or s.player == null:
		visible = false
		return
	visible = true
	var p := s.player
	_name.text = s.display_name
	bust.show_player(p, s.downed)
	if s.downed:
		var share := clampf(s.revive_progress / CoopData.REVIVE_TIME, 0.0, 1.0)  # Revive progress (0..1).
		_status.text = CoopHudData.TEXT_RAISING if raising or share > 0.0 else CoopHudData.TEXT_DOWNED
		_status.add_theme_color_override("font_color", CoopHudData.REVIVE if raising else CoopHudData.DOWNED_LIGHT)
		_name.add_theme_color_override("font_color", CoopHudData.DOWNED_LIGHT)
		_bar.fill_color = CoopHudData.REVIVE
		_bar.back_color = Color(CoopHudData.DOWNED, 0.55)
		_bar.set_values(share)
		# A slow crimson pulse on the status (real time; still with Reduce motion).
		var k := 1.0
		if UiMotion.enabled():
			var ph := fmod(float(Time.get_ticks_msec()) / 1000.0, CoopHudData.PLATE_PULSE_PERIOD) / CoopHudData.PLATE_PULSE_PERIOD
			k = lerpf(CoopHudData.PLATE_PULSE_MIN, 1.0, 0.5 + 0.5 * cos(TAU * ph))
		_status.modulate.a = 1.0 if raising else k
	else:
		_status.text = "%d / %d" % [ceili(p.hp), int(p.max_hp)]
		_status.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
		_status.modulate.a = 1.0
		_name.add_theme_color_override("font_color", CoopHudData.PARTNER)
		_bar.fill_color = Palette.HP_FRIENDLY
		_bar.back_color = Color(0, 0, 0, 0.6)
		_bar.set_values(p.hp / maxf(p.max_hp, 1.0))
		_bar.queue_redraw()  # A colour change alone does not redraw it.
