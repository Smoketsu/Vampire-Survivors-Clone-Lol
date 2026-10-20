## LastStand — the ~3 s visual beat between a won run's last breath and the
## victory results card (content wave 2, GDD §15.0 "Victory screen (content wave
## 2)"; numbers in VictoryData). Game.end_run() has already counted the death,
## built the summary, paid the Soul Ash and frozen the world (the tree is paused,
## so nothing in the run moves again) when play() starts it; then, on real time:
##   * the frozen world dims toward a warm grey, easing out so the change slows
##     to a stop (a full-screen rect multiplied over the screen: CanvasItemMaterial
##     BLEND_MODE_MUL, never a shader that reads the screen back; GDD §15.0
##     "Web death crash: no screen-reading shaders"), and the HUD fades away;
##   * the surviving summons turn outward and kneel in the Bone Ring, nearest
##     first, the kneel rippling out through the ring (each body layer is
##     crouched about its feet and mirrored to face away from the necromancer;
##     UnitMotion's body transform, which nothing in the paused run rewrites);
##   * a gold wash rises over everything;
##   * the stage's title card (VictoryData title on a gold ribbon, and the boss
##     line when the boss fell) fades in;
## then `finished` is emitted and Game opens the results card over it (the
## title card steps aside, the gold-washed world stays behind the card).
## Any key, pad button, click or tap skips to the end at once. It never runs
## under the autotest or with Reduce motion (wanted() is false: the card opens
## at once). Purely visual: it writes only canvas transforms, modulates and its
## own wash colours, reads the run, and uses no RNG.
class_name LastStand
extends Control

## The beat is over (or was skipped): the results card may open.
signal finished

## Owning run (read for the summons and the necromancer's position).
var game: Game
## Full-screen rect multiplied over the screen (the drain and the gold tint).
var _wash: ColorRect
## Full-screen rect added over the screen (the gold wash's lift of the darks).
var _lift: ColorRect
## The title card (ribbon, title and boss line), centred across the screen at
## VictoryData.CARD_Y of its height (above the army ring at the centre).
var _card: VBoxContainer
## The stage title label on the ribbon.
var _title: Label
## The boss line under the ribbon (hidden when the boss lives).
var _boss_line: Label
## Kneeling summons: Array of [UnitLayer body, feet px, facing flip (+1/-1),
## start delay s].
var _kneel: Array = []
## Real time (usec, Time.get_ticks_usec) the beat started at; -1 = idle.
var _start_usec: int = -1
## True once `finished` was emitted (the beat holds its last frame).
var _done: bool = false
## Real time (usec) until which input is swallowed after a skip (-1 = off; the
## skipping press's own release ends it sooner).
var _guard_usec: int = -1


## True when the beat should play: UI motion is on (not the autotest, not
## Reduce motion). Otherwise Game opens the results card at once.
static func wanted() -> bool:
	return UiMotion.enabled()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_wash = _blend_rect(CanvasItemMaterial.BLEND_MODE_MUL, Color.WHITE)
	_lift = _blend_rect(CanvasItemMaterial.BLEND_MODE_ADD, Color.BLACK)
	_card = VBoxContainer.new()  # Placed by hand in _apply() (above the ring, never over it).
	_card.add_theme_constant_override("separation", 8)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var ribbon := UiTheme.ribbon("gold")
	ribbon.custom_minimum_size = Vector2(VictoryData.CARD_RIBBON_WIDTH, 0)
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.add_child(ribbon)
	_title = UiTheme.title("")
	ribbon.add_child(_title)
	_boss_line = UiTheme.tier_label("", UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)
	_boss_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(_boss_line)


## Starts the beat for the finished run `summary` (a victory). `finished`
## follows after VictoryData.LAST_STAND_TIME s, or at once when skipped.
func play(summary: Dictionary) -> void:
	var info := VictoryResults.build(summary)
	_title.text = String(info["title"])
	_boss_line.text = String(info["boss_line"])
	_boss_line.visible = _boss_line.text != ""
	_collect_kneelers()
	_card.modulate.a = 0.0
	_done = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks and taps skip (and never reach the world).
	_start_usec = Time.get_ticks_usec()
	_apply(0.0)


## The surviving summons on the ring, nearest first, with their kneel delays
## and the mirror that turns each one outward.
func _collect_kneelers() -> void:
	_kneel.clear()
	if game == null or game.horde == null or game.player == null:
		return
	var c := game.player.position  # The ring's centre (px).
	var units: Array = []  # [distance px, unit].
	for u: SummonedUnit in game.horde.units:
		if u.active and u.motion != null:
			units.append([c.distance_to(u.position), u])
	units.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if units.size() > VictoryData.KNEEL_MAX:
		units.resize(VictoryData.KNEEL_MAX)
	var far := maxf(1.0, float(units[-1][0])) if not units.is_empty() else 1.0  # Farthest distance (px).
	for e: Array in units:
		var u: SummonedUnit = e[1]
		var dx := u.position.x - c.x  # Outward is this way.
		var cur := 1.0 if u.scale.x >= 0.0 else -1.0  # Facing now (the node's mirror).
		var want := cur if absf(dx) < 1.0 else signf(dx)  # Facing away from the necromancer.
		_kneel.append([u.motion.body, u.motion.feet, want * cur, VictoryData.KNEEL_START + VictoryData.KNEEL_RIPPLE * float(e[0]) / far])


func _process(_delta: float) -> void:
	if _start_usec < 0 or _done:
		return
	var t := float(Time.get_ticks_usec() - _start_usec) / 1000000.0  # Real seconds since the start.
	_apply(t)
	if t >= VictoryData.LAST_STAND_TIME:
		_finish()


## Every layer of the beat at real time `t` s.
func _apply(t: float) -> void:
	var freeze := _ease_out(t / VictoryData.FREEZE_TIME)  # 0..1, slowing to a stop.
	var wash := _smooth((t - VictoryData.WASH_START) / VictoryData.WASH_TIME)  # 0..1.
	var gold := VictoryData.WASH_STRENGTH * wash  # 0..WASH_STRENGTH, the gold wash's share.
	var drain := Color.WHITE.lerp(VictoryData.DRAIN_COLOR, VictoryData.DESATURATE * freeze)  # Dims toward a warm grey.
	var tint := Color.WHITE.lerp(VictoryData.WASH_COLOR * VictoryData.WASH_TINT_GAIN, gold)  # The gold multiply (clamped at 1 per channel).
	_wash.color = Color(drain.r * tint.r, drain.g * tint.g, drain.b * tint.b, 1.0)
	var lift := VictoryData.WASH_COLOR * gold * VictoryData.WASH_LIFT  # Lifts the darks a little, so it reads as light.
	_lift.color = Color(lift.r, lift.g, lift.b, 1.0)
	if game != null and game.hud != null:
		game.hud.modulate.a = 1.0 - clampf(t / VictoryData.HUD_FADE, 0.0, 1.0)
	for k: Array in _kneel:
		var body: UnitLayer = k[0]
		if not is_instance_valid(body):
			continue
		var p := _smooth((t - float(k[3])) / VictoryData.KNEEL_TIME)  # This unit's kneel 0..1.
		var flip := float(k[2]) if t >= float(k[3]) else 1.0  # Turns outward as it starts.
		var sx := lerpf(1.0, VictoryData.KNEEL_SCALE.x, p) * flip
		var sy := lerpf(1.0, VictoryData.KNEEL_SCALE.y, p)
		var feet := float(k[1])
		body.transform = Transform2D(Vector2(sx, 0.0), Vector2(0.0, sy), Vector2(0.0, feet * (1.0 - sy)))  # About the feet.
		var dim := lerpf(1.0, VictoryData.KNEEL_DIM, p)
		body.modulate = Color(dim, dim, dim, body.modulate.a)
	var cp := _smooth((t - VictoryData.CARD_START) / VictoryData.CARD_FADE)  # Title card 0..1.
	_card.modulate.a = cp
	_card.reset_size()  # Its minimum size (the texts may have changed).
	var at := Vector2(size.x * 0.5, size.y * VictoryData.CARD_Y) - _card.size * 0.5  # Rest top-left (px).
	_card.position = (at + Vector2(0.0, (1.0 - cp) * VictoryData.CARD_RISE)).round()


## Jumps to the last frame and hands over to the results card (once).
func _finish() -> void:
	if _done:
		return
	_done = true
	_apply(VictoryData.LAST_STAND_TIME)
	_card.visible = false  # The results card carries the title from here.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()


func _input(event: InputEvent) -> void:
	var is_button := event is InputEventKey or event is InputEventJoypadButton \
			or event is InputEventMouseButton or event is InputEventScreenTouch  # A key / button / click / tap.
	if not is_button:
		return
	if _guard_usec >= 0:
		# The press that skipped: swallow it until its release (or the guard times
		# out), so its release (and a tap's emulated click) never presses a card button.
		get_viewport().set_input_as_handled()
		if not event.is_pressed() or Time.get_ticks_usec() > _guard_usec:
			_guard_usec = -1
		return
	if not visible or _done or _start_usec < 0:
		return
	if event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_guard_usec = Time.get_ticks_usec() + int(VictoryData.SKIP_GUARD_TIME * 1000000.0)
		_finish()


## Ease out (quadratic) of `x` clamped to 0..1.
## A full-screen rect drawn with blend `mode` in `color` (no shader, nothing
## read back from the screen).
func _blend_rect(mode: CanvasItemMaterial.BlendMode, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := CanvasItemMaterial.new()
	m.blend_mode = mode
	r.material = m
	r.color = color
	add_child(r)
	return r


static func _ease_out(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return 1.0 - (1.0 - c) * (1.0 - c)


## Smoothstep of `x` clamped to 0..1.
static func _smooth(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
