## DebugOverlay — F3 toggled performance / AI panel (GDD "NEXT RECOMMENDED
## WORK": "a live debug overlay"; GDD §40 stress metrics). Shows FPS,
## simulation cost, entity and pool counts, horde threat state and how many
## summons are in each FSM state. Visibility persists across restarts via
## GameState.
class_name DebugOverlay
extends PanelContainer

## Text refresh period in seconds.
const REFRESH: float = 0.25

## Owning run.
var game: Game
## Text body.
var _label: Label
## Time accumulated toward the next refresh.
var _accum: float = 0.0


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -340.0
	offset_right = -16.0
	offset_top = 118.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiTheme.label("", 13)
	add_child(_label)
	visible = GameState.debug_overlay_visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible
		GameState.debug_overlay_visible = visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible or game == null:
		return
	_accum += delta
	if _accum < REFRESH:
		return
	_accum = 0.0
	var h := game.horde
	var lines := PackedStringArray()
	lines.append("FPS: %d   sim step: %.2f ms (avg %.2f, worst %.2f)" % [
		Engine.get_frames_per_second(), float(game.last_step_usec) / 1000.0, game.avg_step_ms(), float(game.worst_step_usec) / 1000.0])
	lines.append("Time scale: %.2f   physics: %d Hz" % [Engine.time_scale, Engine.physics_ticks_per_second])
	lines.append("Enemies: %d  (nodes %d, spawned %d, recycled %d)" % [
		game.enemies.active.size(), game.enemies.created_nodes, game.enemies.total_spawned, game.enemies.total_recycled])
	lines.append("Boss: %s" % ("none" if game.enemies.boss == null else "%d / %d HP" % [int(game.enemies.boss.hp), int(game.enemies.boss.max_hp)]))
	lines.append("Summons: %d / %d  (nodes %d, deaths %d, hard recalls %d)" % [
		h.units.size(), h.total_capacity(), h.created_nodes, h.total_deaths, h.hard_recalls])
	lines.append("Projectiles: %d  (nodes %d)" % [game.projectiles.active.size(), game.projectiles.created])
	lines.append("XP crystals: %d   Effects: %d" % [game.pickups.active.size(), game.effects.active.size()])
	lines.append("Threat level: %.2f   Player in danger: %s" % [h.threat_level, "YES" if h.player_in_danger else "no"])
	lines.append("Unit FSM states:")
	var counts := h.state_counts()
	for state_name: String in SummonedUnit.State.keys():
		if counts.has(state_name):
			lines.append("   %-14s %d" % [state_name, int(counts[state_name])])
	_label.text = "\n".join(lines)
