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
## `ultimates` (UltimateSystem, content wave 2) says which ultimate the one
## meter casts (run_config.ultimate_id: Dread Rally by default, or Sovereign's
## Decree, Eclipse, Grave Tide) and runs the new ones, stepped right after
## `dread_rally`; a locked choice falls back to Dread Rally.
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
## Victory screen (content wave 2, VictoryData): a won run plays the last stand
## (LastStand, visual only, after the death is counted and the summary built)
## and then the victory results card; the summary carries the few counters the
## card's highlights need (boss_kill_time, peak_army, evolution_log), kept out
## of `stats` so the autotest summary lines stay as they were. The card's Next
## button raises next_stage_requested for Main. A --victory-preview debug run
## (VictoryPreview) ends as a scripted victory after a few seconds.
## Act III (GDD §15.0 "Act III foundation (phase 1)"): `empire` (EmpireRules)
## runs the Electronic Empire's shared rules (Line of Fire, Lock-On, Steel has
## no soul, the Purge Protocol), stepped right after the projectiles; null on
## Acts I and II unless an Empire kind forced there asks for it (empire_rules()).
## Online co-op (docs/coop/DESIGN.md): `coop` (CoopSession) holds two player
## slots in this one simulation; the per-player fields below (player, horde,
## abilities, grave_step, dread_rally, ultimates, stance, character, innates,
## meta, volleys, dread, rewards) then point at the BOUND slot (bind_slot()),
## and _physics_process() hands the tick to CoopSession.step(). `all_players`
## / `all_hordes` list every necromancer / army (one each in solo), for shared
## code that must test them all. With no co-op `coop` is null and nothing of it
## runs: solo plays bit-for-bit as before.
class_name Game
extends Node2D

## Pause menu / end screen asked to restart the run.
signal restart_requested
## Pause menu / end screen asked to return to the main menu.
signal main_menu_requested
## The victory card's Next: start stage `stage_id` with the same pre-run choices.
signal next_stage_requested(stage_id: String)

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
## Game time (s) the stage boss fell at (-1 = not slain; the victory card's highlight).
var boss_kill_time: float = -1.0
## Most summons alive at once this run (the victory card's "Largest army"; 0..army cap).
var peak_army: int = 0
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
## The chest beacon: chevrons over the chests, edge arrows to the ones off
## screen, the autotest's "chest beacon" counts (ChestBeacon; visual only).
var chest_beacon: ChestBeacon
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
## The run's chosen ultimate (UltimateSystem; never null once _ready ran).
var ultimates: UltimateSystem
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
## Act II Dread on the necromancer (DreadMeter; null unless the stage's STAGE
## has "dread": true, so Act I never runs it).
var dread: DreadMeter = null
## Act II Claims, the Ancient Eye stealing the fallen (EyeClaims; null unless
## the stage's STAGE has "claims": true).
var claims: EyeClaims = null
## Act III, the Electronic Empire's shared rules (EmpireRules; null unless the
## stage's STAGE has "empire": true, or an Empire kind spawned on another stage
## asked for it through empire_rules(); Acts I and II never create it).
var empire: EmpireRules = null
## Content wave 2: the run counters of the one-run achievements (RunRewards;
## never null once _ready ran; reads the run only, never changes gameplay).
var rewards: RunRewards
## Online co-op: the two player slots and their binding (CoopSession); null in
## a solo run, so nothing of co-op exists there.
var coop: CoopSession = null
## Every necromancer of the run ([player] in solo; both slots' in co-op), for
## shared code that tests each one (hazards, pickups, obstacle push-out).
var all_players: Array[Necromancer] = []
## Every undead army of the run ([horde] in solo; both slots' in co-op).
var all_hordes: Array[HordeDirector] = []
## Opt-in per-tick timing of the simulation (--perf; PerfProbe), null otherwise.
var perf: PerfProbe = null
## Co-op start message (CoopNet.start_info: seed, config, loadouts, local_slot,
## version), set by Main before add_child for an online co-op run; empty = no
## network co-op (the --coop-bot autotest builds its own loadouts).
var coop_start: Dictionary = {}

# --- UI ---------------------------------------------------------------------------

## In-run HUD.
var hud: Hud
## Level-up card picker.
var level_up_panel: LevelUpPanel
## Esc pause menu.
var pause_menu: PauseMenu
## Victory / defeat screen.
var end_screen: EndScreen
## The last stand before the victory card (LastStand; visual only).
var last_stand: LastStand
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
	_make_coop()  # Online co-op / --coop-bot only (coop stays null in solo).
	if GameState.autotest and GameState.autotest_perf:
		perf = PerfProbe.new(self)  # --perf: per-tick timing (reads the clock only).
	meta = Meta.run_modifiers() if coop == null else coop.meta_for(0)
	character = CharacterModifiers.for_id(run_config.character_id) if coop == null else coop.character_for(0)
	enemy_grid = SpatialHash.new(GRID_CELL)
	ally_grid = SpatialHash.new(GRID_CELL)
	volleys_on = GameState.autotest_volleys if GameState.autotest else Settings.volleys  # Before DifficultyModifiers (denser fodder).
	if coop != null and coop.lockstep != null and not GameState.autotest:
		volleys_on = bool((coop_start.get("config", {}) as Dictionary).get("volleys", true))  # Online co-op: the host's setting on both machines.
	combat = CombatResolver.new(self)
	codex = CodexLog.new(self)  # Codex records (first, so every hook below can reach it).
	difficulty = DifficultyModifiers.new(self)
	dread_rally = DreadRally.new(self)
	ultimates = UltimateSystem.new(self, _resolve_ultimate() if coop == null else coop.ultimate_for(0))  # Co-op: slot 0's own (the host's) choice.
	stance = ArmyStance.new(self)
	if bool(stage_def.get("dread", false)):
		dread = DreadMeter.new(self)  # Act II only.
	if bool(stage_def.get("claims", false)):
		claims = EyeClaims.new(self)  # Act II only.

	# World layers, back to front (tree order + z_index).
	match String(stage_def["ground"]):
		"march":
			ground = MarchGround.new()
		"sanctum":
			ground = SanctumGround.new()
		"harbour":
			ground = HarbourGround.new()  # Act II: Gullhaven Harbour.
		"archive":
			ground = ArchiveGround.new()  # Act II, the Hollow Archive.
		"spire":
			ground = SpireGround.new()  # Act II: Ul-Thalos, the Risen Spire.
		"citadel":
			ground = CitadelGround.new()  # Act III: the Iron Citadel (its four zone floors).
		"empire":
			var eg := EmpireGround.new()  # Act III placeholder floor (the STAGE's "floor").
			eg.look = stage_def.get("floor", {})
			ground = eg
		# --- Act III: the Assembly Halls ---
		"assembly":
			ground = AssemblyGround.new()  # The four zone floors (AssemblyStage.ZONES).
		# --- Act III: the Scrap Wastes ---
		"wastes":
			ground = WastesGround.new()  # Act III: the Scrap Wastes' four zone floors.
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
	player.dash = grave_step  # His own dash (drawing: MotionDirector).
	add_child(player)
	all_players = [player]
	all_hordes = [horde]
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
	chest_beacon = ChestBeacon.new()  # Over the units (its own z) with its edge-arrow layer; read only.
	chest_beacon.game = self
	add_child(chest_beacon)
	if not ultimates.is_default():
		add_child(UltimateOverlay.new(self))  # The new ultimates' screen overlays (visual only).
	if bool(stage_def.get("empire", false)):
		empire_rules()  # Act III: the Electronic Empire's shared rules.

	if autotest != null:
		player.invulnerable = not GameState.autotest_mortal
	if coop == null:
		player.died.connect(_on_player_died)  # Co-op: the downed rule instead (CoopSession).
	enemies.boss_defeated.connect(_on_boss_defeated)
	enemies.boss_spawned.connect(codex.on_boss_spawned)  # Codex: the boss was faced.
	rewards = RunRewards.new(self)  # Content wave 2: one-run achievement counters (read-only).
	# Counters that should appear in the summary even when they stay at 0.
	for key: String in ["priest_wards", "ward_absorbed", "priest_heals", "player_healing"]:
		stats[key] = 0.0
	# GDD brief: the run starts with 2 Skeleton Warriors (warrior level 1).
	horde.set_class_level("warrior", 1)
	if coop != null:
		_build_coop_slots()
	if GameState.victory_preview:
		VictoryPreview.setup(self)  # Debug: a small army for the scripted victory.
	_build_ui()
	if coop != null and coop.lockstep != null:
		level_up_panel.coop_net = true  # Its choices become lockstep commands.
		level_up_panel.coop_action.connect(coop.lockstep.on_panel_action)
		pause_menu.set_coop(true)  # Leave instead of Restart / Main Menu.
		coop.lockstep.start()
	ground.update_view(player.position)


func _exit_tree() -> void:
	if coop != null and coop.lockstep != null:
		coop.lockstep.stop()  # CoopNet outlives the run.
		coop.lockstep = null  # Breaks the session <-> lockstep reference cycle (both RefCounted).


## Online co-op: the window lost focus or the page went to the background
## (a phone tab, a turned screen): pause both machines at once, since this one
## may stop running (never under the autotest).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if coop != null and coop.lockstep != null and not GameState.autotest:
			coop.lockstep.request_pause_now()


## The skin the necromancer wears this run (purely cosmetic, SkinData): the
## autotest's --skin= (forced, for screenshots), else run_config.skin_id
## when it belongs to the run's character and is unlocked. A default skin
## (or none) returns "" so the normal necromancer drawing is used.
func _resolve_skin() -> String:
	var id := run_config.skin_id  # Requested skin.
	if (GameState.autotest or GameState.victory_preview) and GameState.autotest_skin != "":
		id = GameState.autotest_skin
	elif not SkinData.skins_for(run_config.character_key()).has(id) or not Meta.is_skin_unlocked(id):
		return ""
	return "" if String(SkinData.skin(id).get("kind", "default")) == "default" else id


## The ultimate this run casts (UltimateData id): run_config.ultimate_id when
## it is open (Unlocks.is_open(); the autotest's --ultimate= bypasses the
## lock), else Dread Rally.
func _resolve_ultimate() -> String:
	var uid := run_config.ultimate_id  # Requested ultimate.
	if not UltimateData.ULTIMATES.has(uid) or (not GameState.autotest and not Unlocks.is_open(uid)):
		return UltimateData.DEFAULT_ID
	return uid


## Creates the co-op session when this run is co-op: the --coop-bot autotest
## (both slots driven by the bots, the camera on slot 0) or an online start
## (`coop_start`, CoopNet.start_info). Leaves `coop` null otherwise (solo).
func _make_coop() -> void:
	if GameState.autotest and GameState.autotest_coop:
		var lo0 := {"character_id": run_config.character_id, "name": "P1"}  # Slot 0: the usual --character=.
		var lo1 := {"character_id": GameState.autotest_character2, "name": "P2"}  # Slot 1: --character2=.
		coop = CoopSession.new(self, [lo0, lo1], 0, true, GameState.autotest_seed)
	elif not coop_start.is_empty():
		var los: Array = coop_start.get("loadouts", [])
		if los.size() >= CoopData.SLOTS:
			coop = CoopSession.new(self, los, int(coop_start.get("local_slot", 0)), false, int(coop_start.get("seed", 0)))
			seed(coop.run_seed)  # Both machines run the same global stream.
			coop.lockstep = CoopLockstep.new(self, coop, coop.view_slot)  # Only inputs travel (CoopLockstep).
			if autotest != null:
				autotest.slot = coop.view_slot  # --coop-net: the run's bot plays this machine's slot,
				autotest.net = true  # through the lockstep.


## Co-op: takes the solo-built objects as slot 0's, builds slot 1's beside them,
## starts slot 1's army like slot 0's (two Skeleton Warriors) and hooks the
## downed rule. Slot 0 stays bound afterwards.
func _build_coop_slots() -> void:
	coop.adopt_slot0()
	for i in range(1, coop.slots.size()):
		coop.build_slot(i)
		coop.bind(i)
		horde.set_class_level("warrior", 1)
		if autotest != null:
			player.invulnerable = not GameState.autotest_mortal
		coop.bind(0)
	coop.finish_setup()
	if coop.view_slot != 0:
		coop.bind(coop.view_slot)


## Binds co-op slot `i` (CoopSession.bind(): Game's per-player fields point at
## that slot's objects). No-op in solo.
func bind_slot(i: int) -> void:
	if coop != null:
		coop.bind(i)


## Shared code acting on each necromancer in turn (hazards, ground, stage
## rules) loops `for k in all_players.size()` and calls this first: in co-op it
## binds slot `k` (so `player`, `horde`, `abilities`... are that player's) and
## returns the slot bound before, for unbind(); in solo it does nothing and
## returns -1 (k is 0, the one player, already bound).
func bind_index(k: int) -> int:
	if coop == null:
		return -1
	var prev := coop.bound
	coop.bind(k)
	return prev


## Restores the binding bind_index() returned (no-op for -1, i.e. solo).
func unbind(prev: int) -> void:
	if prev >= 0 and coop != null:
		coop.bind(prev)


## The standing necromancer nearest to `pos` (enemy targeting): `player` in
## solo; in co-op the nearest one not downed (CoopSession.nearest_player()).
func nearest_player(pos: Vector2) -> Necromancer:
	return player if coop == null else coop.nearest_player(pos)


## True when the bound player's progress is this machine's to record (Meta
## unlocks, the recipe book, the Codex): always in solo; in co-op only for the
## slot this machine plays (each player records their own, on their own device).
func records_here() -> bool:
	return coop == null or coop.bound == coop.view_slot


## True when the run's private random streams are seeded (the autotest, or an
## online co-op run, whose two machines must draw the same numbers).
func seeded() -> bool:
	return GameState.autotest or (coop != null and not coop.bots)


## Seed of the run's private random streams (see seeded()).
func run_seed() -> int:
	return coop.run_seed if coop != null and not GameState.autotest else GameState.autotest_seed


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
	pause_menu.main_menu_pressed.connect(_on_pause_main_menu)
	root.add_child(pause_menu)
	last_stand = LastStand.new()  # Over the frozen world and the HUD, under the results card.
	last_stand.game = self
	root.add_child(last_stand)
	end_screen = EndScreen.new()
	end_screen.game = self  # Read-only: the results card's build and army icons.
	end_screen.restart_pressed.connect(func() -> void: restart_requested.emit())
	end_screen.main_menu_pressed.connect(func() -> void: main_menu_requested.emit())
	end_screen.next_pressed.connect(func(id: String) -> void: next_stage_requested.emit(id))
	root.add_child(end_screen)


# =====================================================================================
# Simulation
# =====================================================================================

## In-run hotkeys. Only reached while playing (Game pauses with the tree).
func _unhandled_input(event: InputEvent) -> void:
	if coop != null and coop.lockstep != null:
		_unhandled_input_net(event)  # Online co-op: the presses travel as lockstep inputs.
		return
	if event.is_action_pressed("toggle_aim") and run_state == RunState.PLAYING:
		abilities.toggle_bolt_aim()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash") and run_state == RunState.PLAYING:
		grave_step.request()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ultimate") and run_state == RunState.PLAYING:
		dread_rally.request()
		get_viewport().set_input_as_handled()


## Online co-op: the in-run hotkeys become the local slot's next input
## (CoopLockstep.press()); both machines apply them at the same tick.
func _unhandled_input_net(event: InputEvent) -> void:
	if run_state != RunState.PLAYING:
		return
	var bit := 0
	if event.is_action_pressed("toggle_aim"):
		bit = CoopLockstep.BTN_AIM
	elif event.is_action_pressed("dash"):
		bit = CoopLockstep.BTN_DASH
	elif event.is_action_pressed("ultimate"):
		bit = CoopLockstep.BTN_ULT
	if bit != 0:
		coop.lockstep.press(bit)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if coop != null and coop.lockstep != null:
		coop.lockstep.frame(delta)  # Online co-op: the lockstep runs the ticks (frozen ones too).
		return
	if run_state != RunState.PLAYING:
		return
	if coop != null:
		_physics_coop(delta)
		return
	var t0 := Time.get_ticks_usec()
	var pf := perf  # --perf: section laps (reads the clock only; null otherwise).
	var tl := t0  # Start of the current section (usec).
	elapsed += delta
	_rebuild_grids()
	player.step(delta)
	dread_rally.step(delta)
	ultimates.step(delta)  # The new ultimates (no-op with Dread Rally).
	stance.step(delta)
	if dread != null:
		dread.step(delta)  # Act II Dread statistics (no-op elsewhere).
	abilities.step(delta)
	innates.step(delta)
	horde.step(delta)
	peak_army = maxi(peak_army, horde.units.size())  # Victory card highlight (read only).
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_ARMY, tl)
	enemies.step(delta)
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_ENEMIES, tl)
	arena.resolve_all(delta)
	abilities.spells.after_physics(delta)  # Bone Wall holds enemies on their final positions.
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_OBSTACLES, tl)
	projectiles.step(delta)
	if empire != null:
		empire.step(delta)  # Act III: Empire shots, Lock-On lines, the Purge Protocol.
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_PROJECTILES, tl)
	volleys.step(delta)  # Bullet heaven pass (no-op when off).
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_VOLLEYS, tl)
	pickups.step(delta)
	powerups.step(delta)
	chests.step(delta)
	effects.step(delta)
	if pf != null:
		pf.lap(PerfProbe.SEC_PICKUPS, tl)
	last_step_usec = Time.get_ticks_usec() - t0
	worst_step_usec = maxi(worst_step_usec, last_step_usec)
	_step_usec_total += last_step_usec
	_step_count += 1
	if perf != null:
		perf.record(last_step_usec)  # --perf only (reads the clock, never gameplay).
	if autotest != null:
		autotest.step(delta)
	if pending_level_ups > 0 and run_state == RunState.PLAYING:
		_open_level_up()
	if GameState.victory_preview and elapsed >= VictoryData.PREVIEW_DELAY:
		VictoryPreview.fire(self)  # Debug: the scripted victory (no-op once ended).


## One co-op tick: CoopSession.step() runs both slots and the shared systems
## in its fixed order, then the bots and the shared level-ups (both pick).
func _physics_coop(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	coop.step(delta)
	last_step_usec = Time.get_ticks_usec() - t0
	worst_step_usec = maxi(worst_step_usec, last_step_usec)
	_step_usec_total += last_step_usec
	_step_count += 1
	if perf != null:
		perf.record(last_step_usec)
	if autotest != null:
		autotest.step(delta)  # Slot 0's bot and the run-level checks (slot 0 is bound).
		coop.step_bots(delta)
	if pending_level_ups > 0 and run_state == RunState.PLAYING:
		coop.resolve_level_ups()


## Online co-op: one simulation tick, run by CoopLockstep when both players'
## inputs for it are known and the run is not frozen: both slots and the
## shared systems (CoopSession.step()), the step timing, the autotest's run
## checks. The level-up rounds and chest reveals are the lockstep's.
func coop_sim_tick(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	coop.step(delta)
	last_step_usec = Time.get_ticks_usec() - t0
	worst_step_usec = maxi(worst_step_usec, last_step_usec)
	_step_usec_total += last_step_usec
	_step_count += 1
	if perf != null:
		perf.record(last_step_usec)
	if autotest != null and run_state != RunState.ENDED:
		autotest.step(delta)  # This machine's bot (slot bound: this machine's) and the run-level checks.


func _process(_delta: float) -> void:
	# Camera follow + trauma-based screen shake (Juice autoload, cosmetic).
	camera.position = player.position
	camera.offset = Juice.camera_offset()
	ground.update_view(player.position)
	if perf != null:
		perf.frame()  # --perf: rendered-frame times (the Web measurement).


## The Electronic Empire's shared rules (Act III), created on first use: at
## the start of an Act III run, or when an Empire kind forced onto another
## stage fires its first shot (so its shots and Lock-On still work there).
func empire_rules() -> EmpireRules:
	if empire == null:
		empire = EmpireRules.new(self)
		add_child(empire)
	return empire


## Re-inserts every living enemy and summon into the spatial hashes.
func _rebuild_grids() -> void:
	enemy_grid.clear()
	for e in enemies.active:
		if e.active and not e.untargetable:  # Act II: Vhal'Neth's submerged face is out of reach.
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


## World size in px treated as "on screen" (solo gameplay through
## gameplay_view_size(), and drawing): the real visible area, but never smaller
## than at ViewData.GAMEPLAY_ZOOM, so zooming in (Close) does not change gameplay.
func view_size() -> Vector2:
	var size := get_viewport_rect().size  # Visible layout area (px).
	if GameState.autotest and GameState.autotest_view != Vector2.ZERO:
		size = GameState.autotest_view  # --view=WxH: a test window size (headless is always 1280 x 1280).
	return size / minf(camera.zoom.x, ViewData.GAMEPLAY_ZOOM)


## World size in px that GAMEPLAY treats as "on screen" (the enemy spawn ring,
## the recycle distance, the Soul Nova): view_size() in solo; in co-op one fixed
## size (CoopLockstepData.GAMEPLAY_VIEW, the headless autotest's 1280 x 1280 at
## GAMEPLAY_ZOOM) on every machine, so the same seed plays the same whatever
## each player's window, browser or phone. Drawing keeps view_size().
func gameplay_view_size() -> Vector2:
	if coop != null:
		return CoopLockstepData.GAMEPLAY_VIEW
	return view_size()


## The pause menu's Main Menu (Leave in co-op: the partner is told first, his
## game hands this necromancer to the bot).
func _on_pause_main_menu() -> void:
	if coop != null and coop.lockstep != null:
		coop.lockstep.leave()
	main_menu_requested.emit()


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
	var scaled := base * difficulty.xp_mult()  # XP after the difficulty rewards.
	if coop != null:
		scaled *= difficulty.coop_mult("xp")  # Co-op: the ONE shared bar (CoopData.SCALING).
		coop.slots[coop.bound].xp_collected += amount
	var gained := scaled + _xp_carry
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
	if coop != null:
		coop.open_chest(pos)  # Co-op: the opener's rewards, no pause (CoopSession).
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
	if coop != null and coop.lockstep != null:
		coop.lockstep.on_local_chest_closed()  # Online: the confirm travels; both resume at the same tick.
		return
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
	if coop != null and coop.lockstep != null:
		coop.lockstep.request_toggle_pause()  # Online: a pause / resume command for both machines.
		return
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
	if boss_kill_time < 0.0:
		boss_kill_time = elapsed  # Victory card highlight.
	stat_add("boss_kills", 1.0)
	# Dread Sovereign achievement (GDD §9.4): boss slain with all 4 GDD
	# summon roles (MetaData.DREAD_SOVEREIGN_CLASSES = UnitData.CORE_CLASSES;
	# either priest order or the Profane Bishop counts as the priest; the
	# later classes are not required).
	if SynergyManager.classes_met(MetaData.DREAD_SOVEREIGN_CLASSES, horde.class_levels, 1):
		stat_add("boss_kill_full_army", 1.0)


## Ends the run: freezes the world and shows the victory / defeat screen. A
## victory with UI motion on plays the last stand first (LastStand; the summary,
## the Soul Ash and the autotest report are all done before it starts).
func end_run(won: bool, reason: String) -> void:
	if run_state == RunState.ENDED:
		return
	if coop != null:
		coop.bind(coop.view_slot)  # The summary, the Soul Ash and the autotest report are this machine's player's.
		if coop.lockstep != null:
			coop.lockstep.on_run_end()  # Online: the last frames out, no more ticks.
	run_state = RunState.ENDED
	victory = won
	end_reason = reason
	get_tree().paused = true
	level_up_panel.close()
	pause_menu.close()
	var summary := build_summary()
	summary["soul_ash"] = Meta.award_run(summary, meta)
	GameState.last_run_summary = summary
	if won and LastStand.wanted():
		last_stand.finished.connect(end_screen.open.bind(summary), CONNECT_ONE_SHOT)
		last_stand.play(summary)
	else:
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
		"boss_kill_time": boss_kill_time,  # Victory card highlight (s, -1 = not slain).
		"peak_army": peak_army,  # Victory card highlight.
		"evolution_log": abilities.evolution_history.duplicate(),  # "id@m:ss" (victory card).
		"kills": kills if coop == null else coop.slots[coop.view_slot].kills,  # Co-op: this player's own kills (his Soul Ash).
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
		"run_rewards": rewards.counters(),  # Content wave 2: the one-run achievement counters (RunRewards).
		"stats": stats.duplicate(),
	}
