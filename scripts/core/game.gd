## Game — root node of ONE run (GDD §36 "Game (Node2D)"). It builds the world
## and every manager in code, then drives the simulation in a fixed order each
## physics tick:
##   rebuild spatial hashes -> player -> spells -> horde -> enemies (and
##   stage events) -> obstacle collision -> projectiles -> XP pickups ->
##   power-up drops -> effects
## and routes run-level flow (level-up pause, Esc pause, end of run).
## Run rules (user brief): a 20:00 countdown; Sir Alaric arrives at 3:00 left;
## at 0:00 the Reckoning starts. Dying after 0:00 completes the run (victory
## screen), dying before 0:00 is a defeat.
## Meta-progression (GDD §9.2): `meta` holds the purchased Soul Ash upgrades
## for this run (built once by Meta.run_modifiers(), read by the stat code),
## and end_run() hands the summary to Meta.award_run() (ash is kept on death).
## Restarting frees this node and builds a fresh one, so no state can leak
## between runs. Managers hold a typed `game` reference instead of using
## global singletons.
## Difficulty: `difficulty` is the one path through which the difficulty
## level (GDD §8.4), the run modifiers (§8.5), the Profane Pact passive and
## the Profane Oath meta upgrade scale enemies, the player, the horde and the
## rewards (DifficultyModifiers, built from run_config);
## `powerups` owns the power-up drops and buffs.
## Treasure chests (`chests`, ChestData): walking over one pauses the run in
## RunState.CHEST while the ChestPanel reveals its rewards (evolutions are
## delivered only by chests).
## Stages (GDD §8, §10.2): Main hands in `run_config` (RunConfig: the stage,
## the difficulty level and the run modifiers) before the node enters the
## tree; `stage_def` is that stage's StageRegistry dictionary, read by the
## directors, the arena, the ground and the HUD.
## Manual abilities (GDD §5.5): `grave_step` (GraveStep, Shift / RB dash,
## stepped by the player) and `dread_rally` (DreadRally, Space / LB ultimate
## with a kill-charged soul meter, stepped right after the player); both are
## requested from _unhandled_input(), so they only fire while PLAYING.
## On a phone or tablet the same actions come from TouchControls (added to
## the UI layer outside the autotest), which injects them as input events.
## The army formation (StanceData): `stance` (ArmyStance) holds the Bone Ring's numbers
## for this run (the only formation; there is no switching).
## Playable characters (CharacterData): `character` (CharacterModifiers,
## built once from run_config.character_id) is the one character path: the
## starting spell, the stat modifiers (applied once, after the Soul Ash
## upgrades) and the innate values; `innates` (CharacterInnates) runs the
## innate passive and is stepped right after the spells. The Gravecaller
## (the default) has no innate and baseline stats.
## Hyper mode (HyperData) is part of `difficulty`; the cosmetic skin
## (SkinData, run_config.skin_id or --skin=) is resolved once into
## player.skin_id and only changes how the necromancer is drawn.
class_name Game
extends Node2D

## Pause menu / end screen asked to restart the run.
signal restart_requested
## Pause menu / end screen asked to return to the main menu.
signal main_menu_requested

## High-level run state.
enum RunState { PLAYING, LEVEL_UP, PAUSED, ENDED, CHEST }

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
## Fractional XP left over by the meta XP-gain bonus (paid out once whole).
var _xp_carry: float = 0.0
## Pre-run choices (set by Main before add_child; null = the default stage).
var run_config: RunConfig = null
## The run's stage (StageRegistry dictionary of run_config.stage_id).
var stage_def: Dictionary = {}
## Sacred altars destroyed this run (Sanctum of Judgment, 0..3; always 0 on
## other stages). Set by SanctumDirector; Grand Inquisitor Seraphine brings
## that many fewer healers.
var altars_destroyed: int = 0

# --- Systems (GDD §36 scene/class tree) ----------------------------------------

## The player character.
var player: Necromancer
## World camera (follows the player; not a child so sprite flipping is safe).
var camera: Camera2D
## Procedural floor (Ground in the Graveyard, MarchGround on the Crimson
## March, SanctumGround in the Sanctum of Judgment).
var ground: Ground
## Solid obstacles (gravestones, dead trees, crypt walls) and their collision.
var arena: Arena
## Undead army.
var horde: HordeDirector
## Crimson Covenant spawner / updater.
var enemies: EnemyDirector
## All projectiles.
var projectiles: ProjectileManager
## The bullet heaven pass's volley shots (VolleyDirector; idle when volleys_on is false).
var volleys: VolleyDirector
## True when this run plays with the bullet heaven pass (VolleyData): the Volleys setting,
## or --volleys= under the autotest (default on). Read once, before the systems are built.
var volleys_on: bool = true
## Spells, passives and level-up offers.
var abilities: AbilityManager
## XP crystals.
var pickups: XpManager
## Power-up drops and the timed buffs they grant (PowerupManager).
var powerups: PowerupManager
## Difficulty level, run modifiers and Profane Pact / Oath multipliers (never null).
var difficulty: DifficultyModifiers
## Treasure chests (ChestManager).
var chests: ChestManager
## Cosmetic effects and telegraphs.
var effects: EffectManager
## Engine motion of every unit and the pooled death dissolves (visual only).
var motion: MotionDirector
## Damage / healing rules.
var combat: CombatResolver
## Spatial index of living enemies (rebuilt every tick).
var enemy_grid: SpatialHash
## Spatial index of living summons (rebuilt every tick).
var ally_grid: SpatialHash
## Headless self-test driver (null in normal play).
var autotest: Autotest = null
## Purchased meta upgrades for this run (never null; empty = no upgrades).
var meta: MetaModifiers
## The necromancer's dash (Grave Step; also draws its shadow trail).
var grave_step: GraveStep
## The necromancer's ultimate (Dread Rally: soul meter, army buff).
var dread_rally: DreadRally
## The army's formation this run (ArmyStance, always the Bone Ring; never null once _ready ran).
var stance: ArmyStance
## The playable character of this run (CharacterModifiers; never null).
var character: CharacterModifiers
## The character's innate passive (CharacterInnates; every hook is a no-op
## for a character without one).
var innates: CharacterInnates
## What this run has met for the Codex (CodexLog; never null once _ready
## ran; records only, never changes gameplay).
var codex: CodexLog

# --- UI ---------------------------------------------------------------------------

## In-run HUD.
var hud: Hud
## Level-up card picker.
var level_up_panel: LevelUpPanel
## Esc pause menu.
var pause_menu: PauseMenu
## Victory / defeat screen.
var end_screen: EndScreen
## Treasure-chest reveal.
var chest_panel: ChestPanel
## F3 debug overlay.
var debug_overlay: DebugOverlay


func _ready() -> void:
	if run_config == null:
		run_config = RunConfig.new()
	stage_def = run_config.stage_def()
	if GameState.autotest and GameState.autotest_boss != "":
		# --boss=ID: another boss in this stage's slot, at the stage's boss time.
		var arrival: Dictionary = (StageRegistry.BOSS_ARRIVALS[GameState.autotest_boss] as Dictionary).duplicate()
		arrival["time"] = stage_def["boss"]["time"]
		stage_def = stage_def.duplicate()
		stage_def["boss"] = arrival
	# The autotest must exist first: it seeds the RNG before anything random.
	if GameState.autotest:
		autotest = Autotest.new()
		autotest.game = self
		add_child(autotest)
	meta = Meta.run_modifiers()
	character = CharacterModifiers.for_id(run_config.character_id)
	enemy_grid = SpatialHash.new(GRID_CELL)
	ally_grid = SpatialHash.new(GRID_CELL)
	volleys_on = GameState.autotest_volleys if GameState.autotest else Settings.volleys  # Before DifficultyModifiers (denser fodder).
	combat = CombatResolver.new(self)
	codex = CodexLog.new(self)  # Codex records (first, so every hook below can reach it).
	difficulty = DifficultyModifiers.new(self)
	dread_rally = DreadRally.new(self)
	stance = ArmyStance.new(self)

	# World layers, back to front (tree order + z_index).
	match String(stage_def["ground"]):
		"march":
			ground = MarchGround.new()
		"sanctum":
			ground = SanctumGround.new()
		_:
			ground = Ground.new()
	add_child(ground)
	arena = Arena.new()
	arena.game = self
	add_child(arena)
	pickups = XpManager.new()
	pickups.game = self
	add_child(pickups)
	powerups = PowerupManager.new()
	powerups.game = self
	add_child(powerups)
	chests = ChestManager.new()
	chests.game = self
	add_child(chests)
	effects = EffectManager.new()
	add_child(effects)
	motion = MotionDirector.new()  # Before the horde and enemies: dissolving bodies sit under the living.
	motion.game = self
	add_child(motion)
	horde = HordeDirector.new()
	horde.game = self
	# Depth sorting: summons lower on screen draw in front, so a packed army reads
	# as a formation. Only same-z_index children are reordered (ground decals,
	# telegraphs and fog keep their own layers). Purely visual.
	horde.y_sort_enabled = true
	add_child(horde)
	enemies = EnemyDirector.new()
	enemies.game = self
	enemies.y_sort_enabled = true  # Same depth sorting for the Covenant.
	add_child(enemies)
	grave_step = GraveStep.new()  # Before the player: its trail draws under him.
	grave_step.game = self
	add_child(grave_step)
	player = Necromancer.new()
	player.game = self
	add_child(player)
	meta.apply_to_player(player)
	character.apply_to_player(player)  # Character stats; no-op for the Gravecaller.
	difficulty.apply_to_player(player)  # Frail Master (run modifier); no-op otherwise.
	innates = CharacterInnates.new()
	innates.game = self
	add_child(innates)
	player.skin_id = _resolve_skin()  # Cosmetic only (SkinData); "" = the default look.
	abilities = AbilityManager.new()
	add_child(abilities)
	abilities.setup(self)
	projectiles = ProjectileManager.new()
	projectiles.game = self
	projectiles.z_index = 2
	add_child(projectiles)
	volleys = VolleyDirector.new()
	add_child(volleys)
	volleys.setup(self)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * Settings.zoom_value()
	Settings.changed.connect(_on_settings_changed)
	# Smoothing steps by speed x delta; at the autotest's 8x time scale a slow
	# rendered frame pushes that past 2, the smoothing diverges and the camera
	# goes to NaN (blank screen, NaN sound volumes). The autotest follows the
	# player directly instead; players (1x) keep the smooth camera.
	camera.position_smoothing_enabled = not GameState.autotest
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

	if autotest != null:
		player.invulnerable = not GameState.autotest_mortal
	player.died.connect(_on_player_died)
	enemies.boss_defeated.connect(_on_boss_defeated)
	enemies.boss_spawned.connect(codex.on_boss_spawned)  # Codex: the boss was faced.
	# Counters that should appear in the summary even when they stay at 0.
	for key: String in ["priest_wards", "ward_absorbed", "priest_heals", "player_healing"]:
		stats[key] = 0.0
	# GDD brief: the run starts with 2 Skeleton Warriors (warrior level 1).
	horde.set_class_level("warrior", 1)
	_build_ui()
	ground.update_view(player.position)


## The skin the necromancer wears this run (purely cosmetic, SkinData): the
## autotest's --skin= (forced, for screenshots), else run_config.skin_id
## when it belongs to the run's character and is unlocked. A default skin
## (or none) returns "" so the normal necromancer drawing is used.
func _resolve_skin() -> String:
	var id := run_config.skin_id  # Requested skin.
	if GameState.autotest and GameState.autotest_skin != "":
		id = GameState.autotest_skin
	elif not SkinData.skins_for(run_config.character_key()).has(id) or not Meta.is_skin_unlocked(id):
		return ""
	return "" if String(SkinData.skin(id).get("kind", "default")) == "default" else id


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
	if not GameState.autotest:
		# Phones / tablets: joystick and buttons that inject the usual input
		# actions (shown only on touch input; under the panels below).
		var touch := TouchControls.new()
		touch.game = self
		root.add_child(touch)
	level_up_panel = LevelUpPanel.new()
	level_up_panel.game = self
	level_up_panel.card_chosen.connect(_on_card_chosen)
	root.add_child(level_up_panel)
	chest_panel = ChestPanel.new()
	chest_panel.game = self
	chest_panel.closed.connect(_on_chest_closed)
	root.add_child(chest_panel)
	pause_menu = PauseMenu.new()
	pause_menu.game = self
	pause_menu.resume_pressed.connect(toggle_pause)
	pause_menu.restart_pressed.connect(func() -> void: restart_requested.emit())
	pause_menu.main_menu_pressed.connect(func() -> void: main_menu_requested.emit())
	root.add_child(pause_menu)
	end_screen = EndScreen.new()
	end_screen.game = self  # Read-only: the results card's build and army icons.
	end_screen.restart_pressed.connect(func() -> void: restart_requested.emit())
	end_screen.main_menu_pressed.connect(func() -> void: main_menu_requested.emit())
	root.add_child(end_screen)


# =====================================================================================
# Simulation
# =====================================================================================

## In-run hotkeys. Only reached while playing (Game pauses with the tree).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_aim") and run_state == RunState.PLAYING:
		abilities.toggle_bolt_aim()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash") and run_state == RunState.PLAYING:
		grave_step.request()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ultimate") and run_state == RunState.PLAYING:
		dread_rally.request()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if run_state != RunState.PLAYING:
		return
	var t0 := Time.get_ticks_usec()
	elapsed += delta
	_rebuild_grids()
	player.step(delta)
	dread_rally.step(delta)
	stance.step(delta)
	abilities.step(delta)
	innates.step(delta)
	horde.step(delta)
	enemies.step(delta)
	arena.resolve_all(delta)
	abilities.spells.after_physics(delta)  # Bone Wall holds enemies on their final positions.
	projectiles.step(delta)
	volleys.step(delta)  # Bullet heaven pass (no-op when off).
	pickups.step(delta)
	powerups.step(delta)
	chests.step(delta)
	effects.step(delta)
	last_step_usec = Time.get_ticks_usec() - t0
	worst_step_usec = maxi(worst_step_usec, last_step_usec)
	_step_usec_total += last_step_usec
	_step_count += 1
	if autotest != null:
		autotest.step(delta)
	if pending_level_ups > 0 and run_state == RunState.PLAYING:
		_open_level_up()


func _process(_delta: float) -> void:
	# Camera follow + trauma-based screen shake (Juice autoload, cosmetic).
	camera.position = player.position
	camera.offset = Juice.camera_offset()
	ground.update_view(player.position)


## Re-inserts every living enemy and summon into the spatial hashes.
func _rebuild_grids() -> void:
	enemy_grid.clear()
	for e in enemies.active:
		if e.active:
			enemy_grid.insert(e, e.position)
	ally_grid.clear()
	for u in horde.units:
		if not u.airborne:  # Flying Gargoyles cannot be targeted, blocked or hit.
			ally_grid.insert(u, u.position)


## Adds to a summary counter.
func stat_add(key: String, amount: float) -> void:
	stats[key] = float(stats.get(key, 0.0)) + amount


## Adds camera shake for a request of `amount` px (trauma-based, see Juice).
func shake(amount: float) -> void:
	Juice.shake(amount)


## World size in px treated as "on screen" by gameplay (spawn ring, off-screen
## checks): the real visible area, but never smaller than at
## ViewData.GAMEPLAY_ZOOM, so zooming in (Close) does not change gameplay.
func view_size() -> Vector2:
	return get_viewport_rect().size / minf(camera.zoom.x, ViewData.GAMEPLAY_ZOOM)


## Applies a zoom change made in the Settings menu during a run.
func _on_settings_changed() -> void:
	if camera != null:
		camera.zoom = Vector2.ONE * Settings.zoom_value()


## Average simulation step in milliseconds.
func avg_step_ms() -> float:
	return 0.0 if _step_count == 0 else float(_step_usec_total) / float(_step_count) / 1000.0


# =====================================================================================
# XP and level-ups
# =====================================================================================

## Grants XP; each threshold crossed queues one level-up card pick.
## The meta XP-gain bonus (Grave Tithe) scales `amount`; fractions carry over.
## The Profane Pact / Oath XP reward is its own category on top
## (DifficultyModifiers.xp_mult()); its extra XP is counted in the
## pact_bonus_xp / oath_bonus_xp stats.
func add_xp(amount: int) -> void:
	var base := float(amount) * (1.0 + meta.value("xp_gain"))  # XP before the Pact / Oath reward.
	if difficulty.is_active():
		stat_add("pact_bonus_xp", base * difficulty.pact_value("xp_gain"))
		stat_add("oath_bonus_xp", base * difficulty.oath_value("xp_gain"))
	if difficulty.level_value("xp_mult") != 1.0:
		stat_add("difficulty_bonus_xp", base * (difficulty.xp_mult() - 1.0 - difficulty.value("xp_gain")))
	var gained := base * difficulty.xp_mult() + _xp_carry
	amount = floori(gained)
	_xp_carry = gained - float(amount)
	xp += amount
	stat_add("xp_collected", float(amount))
	var level_before := level  # To play the level-up column once per gain.
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = PlayerData.xp_to_next(level)
		pending_level_ups += 1
	if level > level_before:
		# Column of violet light on the necromancer (art-only, visual).
		effects.burst(AnimData.LEVEL_UP_OFFSET, AnimData.LEVEL_UP_RADIUS, "level_up", player)


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


## Opens a treasure chest collected at `pos`: rolls its size, applies the
## rewards (ready evolutions first, AbilityManager.chest_rewards), pauses the
## run and shows the reveal. Resumes in _on_chest_closed().
func open_chest(pos: Vector2) -> void:
	if run_state != RunState.PLAYING:
		return
	var count := chests.roll_count()  # 1, 3 or 5 upgrades.
	var rewards := abilities.chest_rewards(count)  # Applied rewards, in order.
	chests.record_opened(count, rewards)
	effects.ring(pos, 90.0, Palette.GOLD, 0.6, "chest_open")  # Animation when its art exists (visual only).
	for o: Dictionary in rewards:
		if String(o["kind"]) == "evolution":
			# Dark vortex collapsing into a violet-gold flash on the necromancer (art-only, visual).
			effects.burst(Vector2.ZERO, AnimData.EVOLUTION_RADIUS, "evolution", player)
			break
	run_state = RunState.CHEST
	get_tree().paused = true
	chest_panel.open(rewards, count)


## The chest reveal was closed: resume (a pending level-up opens next tick).
func _on_chest_closed() -> void:
	if run_state != RunState.CHEST:
		return
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
	# Dread Sovereign achievement (GDD §9.4): boss slain with all 4 GDD
	# summon roles (MetaData.DREAD_SOVEREIGN_CLASSES = UnitData.CORE_CLASSES;
	# either priest order or the Profane Bishop counts as the priest; the
	# later classes are not required).
	if SynergyManager.classes_met(MetaData.DREAD_SOVEREIGN_CLASSES, horde.class_levels, 1):
		stat_add("boss_kill_full_army", 1.0)


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
	summary["soul_ash"] = Meta.award_run(summary, meta)
	GameState.last_run_summary = summary
	end_screen.open(summary)
	if autotest != null:
		autotest.finish(summary)


## Snapshot of the run for the end screen and the autotest report.
func build_summary() -> Dictionary:
	var counts := {}
	var caps := {}
	var names := {}  # Class id -> UI plural (an evolved class's evolution name).
	for cls: String in UnitData.CLASS_ORDER:
		counts[cls] = horde.count_of(cls)
		caps[cls] = horde.capacity(cls)
		names[cls] = horde.evolutions.class_plural(cls)
	var boss := enemies.boss
	var boss_info: Dictionary = stage_def["boss"]  # The stage boss's names.
	return {
		"victory": victory,
		"reason": end_reason,
		"stage_id": String(stage_def["id"]),
		"stage_name": String(stage_def["display_name"]),
		"stage_ash_mult": float(stage_def["ash_mult"]),
		"character_id": character.id,
		"character_name": character.display_name(),
		"unlocked_characters": character.unlocked_this_run.duplicate(),
		"boss_name": String(boss_info["short_name"]),
		"time": elapsed,
		"countdown": WaveData.RUN_DURATION,
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
		"horde_names": names,
		"boss_spawned": boss != null,
		"boss_hp": boss.hp if boss != null else 0.0,
		"boss_max_hp": boss.max_hp if boss != null else 0.0,
		"player_hp": player.hp,
		"player_max_hp": player.max_hp,
		"picks": abilities.pick_history,
		"pact_level": difficulty.pact_level(),
		"oath_tier": difficulty.oath_tier(),
		"pact_ash_gain": float(difficulty.ash_parts()["pact"]),
		"oath_ash_gain": float(difficulty.ash_parts()["oath"]),
		"difficulty_id": difficulty.difficulty_id(),
		"difficulty_name": difficulty.difficulty_name(),
		"difficulty_ash_pct": float(difficulty.ash_parts()["difficulty"]),
		"modifiers": difficulty.modifier_ids(),
		"modifier_names": difficulty.modifier_names(),
		"modifiers_ash_gain": float(difficulty.ash_parts()["modifiers"]),
		"hyper": difficulty.is_hyper(),
		"hyper_ash_gain": float(difficulty.ash_parts()["hyper"]),
		"difficulty_label": difficulty.difficulty_label(),
		"boss_id": String(boss_info.get("id", "")),
		"skin_id": player.skin_id,
		"stats": stats.duplicate(),
	}
