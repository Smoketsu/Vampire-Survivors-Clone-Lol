## Game — root node of ONE run (GDD §36 "Game (Node2D)"). It builds the world
## and every manager in code, then drives the simulation in a fixed order each
## physics tick:
##   rebuild spatial hashes -> player -> spells -> horde -> enemies ->
##   projectiles -> XP pickups -> effects
## and routes run-level flow (level-up pause, Esc pause, end of run).
## Run rules (user brief): a 6:00 countdown; Sir Alaric arrives at 1:00 left;
## at 0:00 the Reckoning starts. Dying after 0:00 completes the run (victory
## screen), dying before 0:00 is a defeat.
## Restarting frees this node and builds a fresh one, so no state can leak
## between runs. Managers hold a typed `game` reference instead of using
## global singletons.
class_name Game
extends Node2D

## Pause menu / end screen asked to restart the run.
signal restart_requested
## Pause menu / end screen asked to return to the main menu.
signal main_menu_requested

## High-level run state.
enum RunState { PLAYING, LEVEL_UP, PAUSED, ENDED }

## Camera zoom (higher = closer). Shows roughly 850x480 world px at 720p.
const CAMERA_ZOOM: float = 1.5  # TUNING (not in GDD)
## Cell size (px) of both spatial hashes.
const GRID_CELL: float = 64.0  # TUNING (not in GDD)

## Current run state.
var run_state: RunState = RunState.PLAYING
## Game time elapsed in seconds (pauses excluded).
var elapsed: float = 0.0
## Enemies killed this run.
var kills: int = 0
## Necromancer level.
var level: int = 1
## XP accumulated toward the next level.
var xp: int = 0
## XP required for the next level.
var xp_to_next: int = PlayerData.xp_to_next(1)
## Level-ups earned but not yet resolved by picking a card.
var pending_level_ups: int = 0
## True if the run ended after surviving the countdown ("Run Complete").
var victory: bool = false
## True once Sir Alaric has been killed.
var boss_defeated: bool = false
## Why the run ended: "run_complete" | "defeat" | "timeout" ("" while running).
var end_reason: String = ""
## Free-form counters (damage dealt, heals, intercepts...) for the summary.
var stats: Dictionary = {}
## Duration of the last simulation step in microseconds (debug overlay).
var last_step_usec: int = 0
## Worst simulation step so far in microseconds.
var worst_step_usec: int = 0
## Sum of all step durations (for the average).
var _step_usec_total: int = 0
## Number of simulation steps measured.
var _step_count: int = 0
## Remaining camera shake strength in px.
var _shake: float = 0.0
## Separate RNG for cosmetic shake so frame-rate dependent visuals never
## disturb the (seeded) gameplay RNG used by the autotest.
var _fx_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- Systems (GDD §36 scene/class tree) ----------------------------------------

## The player character.
var player: Necromancer
## World camera (follows the player; not a child so sprite flipping is safe).
var camera: Camera2D
## Procedural graveyard floor.
var ground: Ground
## Undead army.
var horde: HordeDirector
## Crimson Covenant spawner / updater.
var enemies: EnemyDirector
## All projectiles.
var projectiles: ProjectileManager
## Spells, passives and level-up offers.
var abilities: AbilityManager
## XP crystals.
var pickups: XpManager
## Cosmetic effects and telegraphs.
var effects: EffectManager
## Damage / healing rules.
var combat: CombatResolver
## Spatial index of living enemies (rebuilt every tick).
var enemy_grid: SpatialHash
## Spatial index of living summons (rebuilt every tick).
var ally_grid: SpatialHash
## Headless self-test driver (null in normal play).
var autotest: Autotest = null

# --- UI ---------------------------------------------------------------------------

## In-run HUD.
var hud: Hud
## Level-up card picker.
var level_up_panel: LevelUpPanel
## Esc pause menu.
var pause_menu: PauseMenu
## Victory / defeat screen.
var end_screen: EndScreen
## F3 debug overlay.
var debug_overlay: DebugOverlay


func _ready() -> void:
	# The autotest must exist first: it seeds the RNG before anything random.
	if GameState.autotest:
		autotest = Autotest.new()
		autotest.game = self
		add_child(autotest)
	enemy_grid = SpatialHash.new(GRID_CELL)
	ally_grid = SpatialHash.new(GRID_CELL)
	combat = CombatResolver.new(self)

	# World layers, back to front (tree order + z_index).
	ground = Ground.new()
	add_child(ground)
	pickups = XpManager.new()
	pickups.game = self
	add_child(pickups)
	effects = EffectManager.new()
	add_child(effects)
	horde = HordeDirector.new()
	horde.game = self
	add_child(horde)
	enemies = EnemyDirector.new()
	enemies.game = self
	add_child(enemies)
	player = Necromancer.new()
	player.game = self
	add_child(player)
	abilities = AbilityManager.new()
	add_child(abilities)
	abilities.setup(self)
	projectiles = ProjectileManager.new()
	projectiles.game = self
	projectiles.z_index = 2
	add_child(projectiles)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

	if autotest != null:
		player.invulnerable = not GameState.autotest_mortal
	player.died.connect(_on_player_died)
	enemies.boss_defeated.connect(_on_boss_defeated)
	# Counters that should appear in the summary even when they stay at 0.
	for key: String in ["priest_wards", "ward_absorbed", "priest_heals", "player_healing"]:
		stats[key] = 0.0
	# GDD brief: the run starts with 2 Skeleton Warriors (warrior level 1).
	horde.set_class_level("warrior", 1)
	_build_ui()
	ground.update_view(player.position)


## Builds the CanvasLayer UI. It processes while the tree is paused so menus
## and the level-up panel stay interactive.
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	layer.add_child(root)
	hud = Hud.new()
	hud.game = self
	root.add_child(hud)
	debug_overlay = DebugOverlay.new()
	debug_overlay.game = self
	root.add_child(debug_overlay)
	level_up_panel = LevelUpPanel.new()
	level_up_panel.game = self
	level_up_panel.card_chosen.connect(_on_card_chosen)
	root.add_child(level_up_panel)
	pause_menu = PauseMenu.new()
	pause_menu.game = self
	pause_menu.resume_pressed.connect(toggle_pause)
	pause_menu.restart_pressed.connect(func() -> void: restart_requested.emit())
	pause_menu.main_menu_pressed.connect(func() -> void: main_menu_requested.emit())
	root.add_child(pause_menu)
	end_screen = EndScreen.new()
	end_screen.restart_pressed.connect(func() -> void: restart_requested.emit())
	end_screen.main_menu_pressed.connect(func() -> void: main_menu_requested.emit())
	root.add_child(end_screen)


# =====================================================================================
# Simulation
# =====================================================================================

func _physics_process(delta: float) -> void:
	if run_state != RunState.PLAYING:
		return
	var t0 := Time.get_ticks_usec()
	elapsed += delta
	_rebuild_grids()
	player.step(delta)
	abilities.step(delta)
	horde.step(delta)
	enemies.step(delta)
	projectiles.step(delta)
	pickups.step(delta)
	effects.step(delta)
	last_step_usec = Time.get_ticks_usec() - t0
	worst_step_usec = maxi(worst_step_usec, last_step_usec)
	_step_usec_total += last_step_usec
	_step_count += 1
	if autotest != null:
		autotest.step(delta)
	if pending_level_ups > 0 and run_state == RunState.PLAYING:
		_open_level_up()


func _process(delta: float) -> void:
	# Camera follow + decaying screen shake (cosmetic, frame-rate based).
	var offset := Vector2.ZERO
	if _shake > 0.1:
		offset = Vector2(_fx_rng.randf_range(-_shake, _shake), _fx_rng.randf_range(-_shake, _shake))
		_shake = move_toward(_shake, 0.0, 30.0 * delta)
	camera.position = player.position
	camera.offset = offset
	ground.update_view(player.position)


## Re-inserts every living enemy and summon into the spatial hashes.
func _rebuild_grids() -> void:
	enemy_grid.clear()
	for e in enemies.active:
		if e.active:
			enemy_grid.insert(e, e.position)
	ally_grid.clear()
	for u in horde.units:
		ally_grid.insert(u, u.position)


## Adds to a summary counter.
func stat_add(key: String, amount: float) -> void:
	stats[key] = float(stats.get(key, 0.0)) + amount


## Adds camera shake of `amount` px (strongest request wins).
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Visible world size in px (viewport / zoom). Used for the spawn ring.
func view_size() -> Vector2:
	return get_viewport_rect().size / camera.zoom


## Average simulation step in milliseconds.
func avg_step_ms() -> float:
	return 0.0 if _step_count == 0 else float(_step_usec_total) / float(_step_count) / 1000.0


# =====================================================================================
# XP and level-ups
# =====================================================================================

## Grants XP; each threshold crossed queues one level-up card pick.
func add_xp(amount: int) -> void:
	xp += amount
	stat_add("xp_collected", float(amount))
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = PlayerData.xp_to_next(level)
		pending_level_ups += 1


## Pauses combat and shows three cards (GDD §16 "Level-up panel: Pause combat").
func _open_level_up() -> void:
	run_state = RunState.LEVEL_UP
	get_tree().paused = true
	level_up_panel.open(abilities.build_offers(PlayerData.CARDS_PER_LEVEL), level - pending_level_ups + 1)


## Applies the picked card, then shows the next pending level-up or resumes.
func _on_card_chosen(offer: Dictionary) -> void:
	if run_state != RunState.LEVEL_UP:
		return
	abilities.apply_offer(offer)
	pending_level_ups -= 1
	if pending_level_ups > 0:
		level_up_panel.open(abilities.build_offers(PlayerData.CARDS_PER_LEVEL), level - pending_level_ups + 1)
	else:
		level_up_panel.close()
		run_state = RunState.PLAYING
		get_tree().paused = false


# =====================================================================================
# Pause / end of run
# =====================================================================================

## True when Esc may open / close the pause menu.
func can_toggle_pause() -> bool:
	return run_state == RunState.PLAYING or run_state == RunState.PAUSED


## Esc pause menu toggle (GDD §4 "Esc: Pause/settings").
func toggle_pause() -> void:
	if run_state == RunState.PLAYING:
		run_state = RunState.PAUSED
		get_tree().paused = true
		pause_menu.open()
	elif run_state == RunState.PAUSED:
		run_state = RunState.PLAYING
		pause_menu.close()
		get_tree().paused = false


## Seconds left on the countdown (negative during the Reckoning).
func time_remaining() -> float:
	return WaveData.RUN_DURATION - elapsed


## True once the countdown has reached 0:00.
func countdown_finished() -> bool:
	return elapsed >= WaveData.RUN_DURATION


func _on_player_died() -> void:
	if countdown_finished():
		end_run(true, "run_complete")
	else:
		end_run(false, "defeat")


## Boss kill: reward only (dropped by EnemyDirector); the run goes on.
func _on_boss_defeated() -> void:
	boss_defeated = true
	stat_add("boss_kills", 1.0)


## Ends the run: freezes the world and shows the victory / defeat screen.
func end_run(won: bool, reason: String) -> void:
	if run_state == RunState.ENDED:
		return
	run_state = RunState.ENDED
	victory = won
	end_reason = reason
	get_tree().paused = true
	level_up_panel.close()
	pause_menu.close()
	var summary := build_summary()
	GameState.last_run_summary = summary
	end_screen.open(summary)
	if autotest != null:
		autotest.finish(summary)


## Snapshot of the run for the end screen and the autotest report.
func build_summary() -> Dictionary:
	var counts := {}
	var caps := {}
	for cls: String in UnitData.CLASS_ORDER:
		counts[cls] = horde.count_of(cls)
		caps[cls] = horde.capacity(cls)
	var boss := enemies.boss
	return {
		"victory": victory,
		"reason": end_reason,
		"time": elapsed,
		"time_past_zero": maxf(0.0, elapsed - WaveData.RUN_DURATION),
		"time_remaining": maxf(0.0, WaveData.RUN_DURATION - elapsed),
		"reckoning_waves": enemies.reckoning_wave,
		"boss_defeated": boss_defeated,
		"kills": kills,
		"level": level,
		"horde_total": horde.units.size(),
		"horde_capacity": horde.total_capacity(),
		"horde_counts": counts,
		"horde_caps": caps,
		"boss_spawned": boss != null,
		"boss_hp": boss.hp if boss != null else 0.0,
		"boss_max_hp": boss.max_hp if boss != null else 0.0,
		"player_hp": player.hp,
		"player_max_hp": player.max_hp,
		"picks": abilities.pick_history,
		"stats": stats.duplicate(),
	}
