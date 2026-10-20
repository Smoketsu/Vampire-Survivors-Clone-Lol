## CoopPlayerCard — one seat of the co-op lobby (CoopLobby; GDD §15.0 "Online
## co-op: relay and lobby"): a panel with the player's character portrait
## (CharacterPicker.Portrait, the same art as the pre-run grid), the name and
## seat ("Host" / "Guest", "· You" on our own card), the character, the
## ultimate, the worn title (gold), the ready state (soul-teal "Ready", dim
## "Not ready"; the host is always ready) and the round-trip time (soul-teal
## when good, crimson when slow; CoopNetData.PING_*). An empty seat reads
## "Waiting..." with no portrait. Purely visual: the lobby feeds it.
class_name CoopPlayerCard
extends PanelContainer

## Box holding the portrait (kept so the card keeps its shape when empty).
var _portrait_box: Control
## The portrait (null for an empty seat).
var _portrait: Control = null
## Character the portrait shows ("" = none).
var _portrait_char: String = ""
## Name line (NAME tier).
var _name: Label
## Seat line (LABEL tier): "Host", "Guest", "· You".
var _role: Label
## Character line (BODY).
var _char: Label
## Ultimate line (BODY).
var _ult: Label
## Title line (BODY, gold; "" hides it).
var _title: Label
## Ready state (BODY).
var _status: Label
## Round trip (BODY).
var _ping: Label


func _ready() -> void:
	custom_minimum_size = CoopNetData.CARD_SIZE
	add_theme_stylebox_override("panel", UiTheme.style("panel", "violet"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_portrait_box = Control.new()
	_portrait_box.custom_minimum_size = CoopNetData.PORTRAIT_SIZE
	_portrait_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait_box)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	_role = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	texts.add_child(_role)
	_name = _line(texts, UiTheme.Tier.NAME, UiTheme.TEXT)
	_char = _line(texts, UiTheme.Tier.BODY, UiTheme.TEXT)
	_ult = _line(texts, UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	_title = _line(texts, UiTheme.Tier.BODY, UiTheme.TEXT_GOLD)
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 12)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(st)
	_status = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	st.add_child(_status)
	_ping = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT_DIM)
	st.add_child(_ping)
	set_empty(1)


## A clipped one-line label of tier `t` added to `parent`.
static func _line(parent: Control, t: UiTheme.Tier, color: Color) -> Label:
	var l := UiTheme.tier_label("", t, color)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(l)
	return l


## Shows an empty seat `slot` (0 = host, 1 = guest).
func set_empty(slot: int) -> void:
	_set_portrait("")
	_role.text = "Host" if slot == 0 else "Guest"
	_name.text = CoopNetData.EMPTY_SLOT_TEXT
	_name.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	for l: Label in [_char, _ult, _title, _status, _ping]:
		l.text = ""
	modulate.a = 0.7


## Shows seat `slot` holding loadout `lo` (CoopNet.make_loadout() form):
## `me` = our own card, `ready` its flag, `ping_ms` the round trip (-1 = unknown).
func set_player(slot: int, lo: Dictionary, me: bool, ready: bool, ping_ms: float) -> void:
	modulate.a = 1.0
	var char_id := String(lo.get("character_id", CharacterData.DEFAULT_ID))
	if not CharacterData.CHARACTERS.has(char_id):
		char_id = CharacterData.DEFAULT_ID
	_set_portrait(char_id)
	_role.text = ("Host" if slot == 0 else "Guest") + (" · You" if me else "")
	_name.text = String(lo.get("name", ""))
	_name.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if me else UiTheme.TEXT)
	_char.text = String(CharacterData.CHARACTERS[char_id]["display_name"])
	var ult := String(lo.get("ultimate_id", UltimateData.DEFAULT_ID))
	_ult.text = "Ultimate: %s" % String((UltimateData.ULTIMATES.get(ult, UltimateData.ULTIMATES[UltimateData.DEFAULT_ID]) as Dictionary)["display_name"])
	var title := String(lo.get("title_id", ""))
	_title.text = TitleData.display_text(title) if title != "" else ""
	_title.visible = title != ""
	if slot == 0:
		_status.text = "Hosting"
		_status.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	else:
		_status.text = "Ready" if ready else "Not ready"
		_status.add_theme_color_override("font_color", UiTheme.TEXT_GOOD if ready else UiTheme.TEXT_DIM)
	if ping_ms < 0.0:
		_ping.text = ""
	else:
		_ping.text = "Ping %d ms" % roundi(ping_ms)
		var col := UiTheme.TEXT_GOOD if ping_ms <= CoopNetData.PING_GOOD_MS else (UiTheme.TEXT if ping_ms <= CoopNetData.PING_FAIR_MS else Palette.CRIMSON.lightened(0.4))
		_ping.add_theme_color_override("font_color", col)


## Replaces the portrait with character `id`'s ("" = none).
func _set_portrait(id: String) -> void:
	if id == _portrait_char:
		return
	_portrait_char = id
	if _portrait != null:
		_portrait.queue_free()
		_portrait = null
	if id == "":
		return
	_portrait = CharacterPicker.Portrait.new(id, false, Vector2.ZERO)
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_box.add_child(_portrait)
