## EnemyDirector — spawns and updates the Crimson Covenant (GDD §22
## "EnemyDirector: Enemy waves, enemy density and event escalation").
##   * Reads the run's stage (`game.stage_def`, StageRegistry): its
##     data-driven 20-minute timeline of continuous trickle segments +
##     one-shot formation events + the stage boss at 17:00 (Sir Alaric or
##     Marshal Vael), with the shared enemy HP / damage scaling over time
##     (WaveData) times the stage's own multipliers.
##   * Pools Enemy nodes; dead enemies leave `active` at compaction and can
##     be reused only after the next spatial-grid clear (solo and co-op).
##   * Staggers enemy AI: think() at 5 Hz, separation at 10 Hz, movement at
##     60 Hz.
##   * Recycles enemies left far behind to the spawn ring ahead of the player.
##   * Owns the StageDirector (graveyard stage events, empowered graves and
##     holy zones) and hands it the "consecration" / "crypt" timeline events;
##     on the Crimson March it also owns the MarchDirector (zones, outposts,
##     ward generators, supply carts) and hands it "outposts" /
##     "generators" / "cart" events; on the Sanctum of Judgment it also owns
##     the SanctumDirector (sanctified chambers, the Cathedral Guardian, the
##     sacred altars, corruption) and hands it "chamber" / "guardian" /
##     "altars" events. A stage may name enemy kinds by short aliases
##     (StageRegistry "kind_aliases"); resolve_kind() maps them when a kind
##     is looked up or spawned.
##   * Never places an enemy inside an obstacle (Arena.free_point).
##   * Applies the difficulty (game.difficulty: the GDD §8.4 level, the §8.5
##     run modifiers and the Profane Pact / Oath) in the existing scaling
##     path: hp_mult / damage_mult (and the growth of their time scaling),
##     the trickle rate, soft cap and kind weights, the enemy move speed,
##     trickle elites, and the boss's HP (a share of the HP bonus).
##   * Skips the AI and movement of enemies held by a Stasis power-up
##     (game.powerups.freezes(); Reckoning enemies are immune, the boss is
##     frozen for part of the duration) or by a Frost Wraith Deep Freeze
##     (Enemy.freeze_timer, set by CombatResolver.freeze_enemy()) or a
##     Cathedral Horror dive stun (Enemy.stun_timer, CombatResolver.stun_enemy()).
##   * Looks enemy kinds up (after a stage alias) in EnemyData, then
##     SanctumObjectiveData.STRUCTURES, then MarchEnemyData, then
##     SanctumEnemyData (the Sanctum of Judgment's kinds: any stage can spawn
##     them), owns the CovenantRites (`rites`: the Sanctum kits' death record,
##     High Confessor revivals and danger hints) and tracks the living
##     miniboss (the Cathedral Guardian: its kit registers it with
##     set_miniboss() for the HUD's one miniboss bar; never recycled).
##   * Act II, Gullhaven Harbour (GDD §15.0 "Gullhaven Harbour (Act II phase
##     2)"): on a stage with a "tide" config it owns the TideDirector (the
##     rising water, surges, High Water; `tide`), and with a "harbour" config
##     the HarbourDirector (bell buoys, smugglers' caches, the Harbourmaster;
##     `harbour`), and hands it the "buoys" / "caches" / "harbourmaster"
##     events. Each sunk buoy shrinks later scripted waves and the trickle
##     (HarbourDirector.wave_mult() / trickle_mult(), applied once here). Both
##     are null on every other stage, so Act I is unchanged.
##   * Act III, the Electronic Empire (GDD §15.0 "Act III foundation (phase
##     1)"): its kinds are looked up through empire_def() (EmpireEnemyData,
##     then each Act III stage's table) and its bosses load by name from
##     EMPIRE_BOSS_DIR. Its shared rules (Line of Fire, Lock-On, Steel has no
##     soul, the Purge Protocol) live in EmpireRules (Game.empire), not here.
##     The Assembly Halls (an "assembly" config) add the AssemblyDirector
##     (`assembly`: conveyors, furnace channels, fabricators, the Beta Build;
##     its "fabricators" / "beta_build" events, its guest aliases, and each
##     smashed fabricator's cut of the waves and the trickle, applied once here).
##   * Act III, the Scrap Wastes (GDD §15.0 "The Scrap Wastes (Act III phase
##     2)"): on a stage with a "wastes" config it owns the WastesDirector (the
##     Signal Pylons, the scrap storms, the Trojan Horse; `wastes`) and hands it
##     the "pylons" / "storm" / "trojan" events. Null on every other stage.
##   * Act IV, the Shores of Ilion (GDD §15.0 "The Shores of Ilion (Act IV
##     phase 2)"): on a stage with an "ilion" config it owns the IlionDirector
##     (the siege towers, Polyphemus the Cyclops; `ilion`) and hands it the
##     "siege_towers" / "polyphemus" events. Null on every other stage.
##   * Act IV, the Olympian Republic (GDD §15.0 "Act IV foundation (phase
##     1)"): its kinds are looked up through pantheon_def() (PantheonEnemyData,
##     then each Act IV stage's table) after the Empire's, and its bosses load
##     by name from PANTHEON_BOSS_DIR after the Empire's folder. Its shared
##     rules (Wrath of the Gods, Phalanx, Glory, the Twilight of the Gods) live
##     in PantheonRules (Game.pantheon), not here.
##   * Act IV, Mount Olympus (GDD §15.0 "Mount Olympus (Act IV phase 2)"): on a
##     stage with an "olympus" config it owns the OlympusDirector (the Pantheon
##     Trial's gods and Artemis's groves; `olympus`) and hands it the "god"
##     events. Null on every other stage.
##   * Act V, the Shogunate of the Rising Sun (GDD §15.0 "Act V foundation
##     (phase 1)"): its kinds are looked up through shogunate_def()
##     (ShogunateEnemyData, then each Act V stage's table) after the
##     Pantheon's, and its bosses load by name from SHOGUNATE_BOSS_DIR after
##     the Pantheon's folder. Its shared rules (the Sun's Course, the Draw, From
##     the Shadows, the Endless Night) live in ShogunateRules (Game.shogunate);
##     this director only asks them, while they exist, for the trickle's and
##     the waves' night kinds (SunCourse.timeline_weights() / filter_groups(),
##     the one timeline helper), hands the "ambush" events and the segments'
##     "ambush" trickle to ShadowAmbush, and lets the Endless Night quicken
##     each Reckoning enemy (ShogunateRules.on_reckoning_spawn()).
##   * Act V, the Burning Province (GDD §15.0 "The Burning Province (Act V
##     phase 2)"): on a stage with a "province" config it owns the
##     ProvinceDirector (the paddy water, the village fires, Shuten-dōji;
##     `province`) and hands it the "shuten_doji" events; the Province kinds'
##     fire patches and smoke clouds live in ProvinceHazards
##     (province_hazards(), created on first use on any stage, stepped here).
##   * Online co-op (CoopSession; docs/coop/DESIGN.md): every enemy steps with
##     its NEAREST standing necromancer bound (CoopSession.bind_nearest()), so
##     it advances on, aims at and recycles around that one (bosses and kits
##     too); the stage directors step with the primary slot bound. The trickle
##     rings each standing necromancer in turn (CoopSession.spawn_anchor()),
##     formation and Reckoning waves spawn one copy around each, the hard cap is
##     hard_cap() (x CoopData alive_cap) and a miniboss gets CoopData's HP
##     (set_miniboss()). The doubled trickle and soft cap come through
##     DifficultyModifiers.coop_mult(). In solo none of it runs.
class_name EnemyDirector
extends Node2D

## Folder of the Ancient Eye's boss scripts ("boss_<id>.gd", each a Boss; Act II).
const EYE_BOSS_DIR: String = "res://scripts/enemies/eye/"
## Folder of the Electronic Empire's boss scripts ("boss_<id>.gd", each a Boss; Act III).
const EMPIRE_BOSS_DIR: String = "res://scripts/enemies/empire/"
# --- Act IV: the Olympian Republic ---
## Folder of the Olympian Republic's boss scripts ("boss_<id>.gd", each a Boss; Act IV).
const PANTHEON_BOSS_DIR: String = "res://scripts/enemies/pantheon/"
# --- Act V: the Shogunate of the Rising Sun ---
## Folder of the Shogunate's boss scripts ("boss_<id>.gd", each a Boss; Act V).
const SHOGUNATE_BOSS_DIR: String = "res://scripts/enemies/shogunate/"

## The boss entered the arena.
signal boss_spawned(boss: Boss)
## The boss died (big reward; the run continues).
signal boss_defeated
## The countdown hit 0:00 and the Reckoning began.
signal reckoning_started

## Owning run.
var game: Game
## Enemies in the world (may briefly contain inactive ones until compaction).
var active: Array[Enemy] = []
## Inactive enemies ready for reuse.
var _pool: Array[Enemy] = []
## Killed or despawned enemies awaiting removal from `active` at compaction.
var _retired: Array[Enemy] = []
## Compacted enemies still referenced by this tick's spatial grid; reusable
## only after the next grid clear, through release_retired().
var _awaiting_grid_clear: Array[Enemy] = []
## The run's stage (Game.stage_def, StageRegistry keys).
var stage_def: Dictionary = {}
## The stage's trickle segments (stage_def "segments").
var segments: Array = []
## The stage's timeline events (stage_def "events").
var events: Array = []
## The stage's boss arrival data (stage_def "boss").
var boss_info: Dictionary = {}
## Index of the current `segments` entry.
var segment_index: int = 0
## Index of the next `events` entry to fire.
var event_index: int = 0
## Fractional enemies accumulated by the trickle spawner.
var spawn_accum: float = 0.0
## Current enemy HP multiplier from time scaling.
var hp_mult: float = 1.0
## Current enemy damage multiplier from time scaling.
var damage_mult: float = 1.0
## The boss once spawned (null before the stage's boss time).
var boss: Boss = null
## Event banner text shown on the HUD.
var banner_text: String = ""
## Game time (s) until which the banner is shown.
var banner_until: float = 0.0
## Total Enemy nodes ever instantiated (debug: pool health).
var created_nodes: int = 0
## Total enemies spawned (including reuse).
var total_spawned: int = 0
## Number of times far-away enemies were recycled ahead of the player.
var total_recycled: int = 0
## Reckoning waves spawned so far (0 before the countdown ends).
var reckoning_wave: int = 0
## Game time of the next Reckoning wave.
var _next_reckoning: float = WaveData.RUN_DURATION
## Physics ticks since run start (drives staggering).
var _frame: int = 0
## Next think slot handed to a new enemy (round-robin).
var _next_slot: int = 0
## Graveyard stage mechanics and holy zones (GDD §11).
var stage: StageDirector
## Crimson March mechanics (GDD §8.2; null on stages without them). The
## Sanctum of Judgment uses it for its battle zones.
var march: MarchDirector = null
## Sanctum of Judgment objectives (GDD §8.3; null on stages without them).
var sanctum: SanctumDirector = null
## Gullhaven Harbour's tide (Act II; null on stages without a "tide" config).
var tide: TideDirector = null
## Gullhaven Harbour's stage events (Act II; null on stages without a
## "harbour" config).
var harbour: HarbourDirector = null
# --- Act II: Ul-Thalos, the Risen Spire ---
## The sinking island of Ul-Thalos (StageRegistry "sinking"; null elsewhere).
var sinking: SinkingDirector = null
## Ul-Thalos objectives: dream pillars, guest squads (StageRegistry "spire"; null elsewhere).
var spire: SpireDirector = null
## The stage's enemy kind aliases (StageRegistry "kind_aliases"; alias ->
## real kind id; {} = none).
var _kind_aliases: Dictionary = {}
## The Hollow Archive's mechanics (Act II: ink wells, the orrery, forbidden
## tomes, rifts; null on stages without its "archive" config).
var archive: ArchiveDirector = null
## The Archive kinds' world hazards (ink pools, spore clouds, pending mass
## splits; ArchiveHazards): created on first use on ANY stage (an Archive kind
## can be spawned anywhere), null until then; archive_hazards() creates it.
var archive_haz: ArchiveHazards = null
# --- Act III: the Iron Citadel ---
## The Iron Citadel's mechanics (Act III: Shield Gates, laser grids, the
## Citadel's guns, Sentry Turrets, Valkyrie 2.0, guest squads; StageRegistry
## "citadel"; null on every other stage).
var citadel: CitadelDirector = null
# --- Act IV: the Asphodel Underworld ---
## The Asphodel Underworld's mechanics (Act IV: the River Styx, Cerberus, guest
## squads; StageRegistry "underworld"; null on every other stage).
var underworld: UnderworldDirector = null


# --- Act V: the Burning Province ---
## The Burning Province's stage systems: the paddies, the village fires,
## Shuten-dōji (StageRegistry "province"; null elsewhere).
var province: ProvinceDirector = null
## The Province kinds' world hazards (fire patches, smoke clouds;
## ProvinceHazards), created on first use (province_hazards()); null until then.
var province_haz: ProvinceHazards = null
# --- Act V: the Road to the Sun ---
## The Road to the Sun's mechanics (Act V: the Kirin, guest squads;
## StageRegistry "sun_road"; null on every other stage).
var sun_road: SunRoadDirector = null
## Sanctum kit bookkeeping: recent deaths, Confessor revivals, danger hints.
var rites: CovenantRites
## The living miniboss shown on the HUD's miniboss bar (the Cathedral
## Guardian, registered by its GuardianKit; null = none; read it through
## miniboss_alive(), the node is pooled).
var miniboss: Enemy = null
## Generation of `miniboss` when it registered (stale guard).
var miniboss_gen: int = 0
# --- Act III: the Assembly Halls ---
## The Assembly Halls' systems: conveyors, furnace channels, fabricators, the
## Beta Build (StageRegistry "assembly"; null on every other stage).
var assembly: AssemblyDirector = null
# --- Act III: the Scrap Wastes ---
## The Scrap Wastes' stage systems: Signal Pylons, scrap storms, the Trojan
## Horse (StageRegistry "wastes"; null elsewhere).
var wastes: WastesDirector = null
# --- Act IV: Mount Olympus ---
## Mount Olympus's stage systems: the Pantheon Trial's gods, Artemis's groves
## (StageRegistry "olympus"; null elsewhere).
var olympus: OlympusDirector = null


# --- Act IV: the Shores of Ilion ---
## The Shores of Ilion's stage systems: siege towers, Polyphemus the Cyclops
## (StageRegistry "ilion"; null elsewhere).
var ilion: IlionDirector = null


func _ready() -> void:
	stage_def = game.stage_def
	segments = stage_def["segments"]
	events = stage_def["events"]
	boss_info = stage_def["boss"]
	_kind_aliases = stage_def.get("kind_aliases", {})
	stage = StageDirector.new()
	stage.game = game
	add_child(stage)
	rites = CovenantRites.new()
	rites.game = game
	add_child(rites)
	if not (stage_def["march"] as Dictionary).is_empty():
		march = MarchDirector.new()
		march.game = game
		march.config = stage_def["march"]
		add_child(march)
	if not (stage_def.get("sanctum", {}) as Dictionary).is_empty():
		sanctum = SanctumDirector.new()
		sanctum.game = game
		sanctum.config = stage_def["sanctum"]
		add_child(sanctum)
	# --- Act II: Gullhaven Harbour ---
	if not (stage_def.get("tide", {}) as Dictionary).is_empty():
		tide = TideDirector.new()
		tide.game = game
		tide.config = stage_def["tide"]
		add_child(tide)
	if not (stage_def.get("harbour", {}) as Dictionary).is_empty():
		harbour = HarbourDirector.new()
		harbour.game = game
		harbour.config = stage_def["harbour"]
		add_child(harbour)
	if not (stage_def.get("archive", {}) as Dictionary).is_empty():
		archive = ArchiveDirector.new()  # Act II, the Hollow Archive.
		archive.game = game
		archive.config = stage_def["archive"]
		add_child(archive)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	if not (stage_def.get("sinking", {}) as Dictionary).is_empty():
		sinking = SinkingDirector.new()
		sinking.game = game
		sinking.config = stage_def["sinking"]
		add_child(sinking)
	if not (stage_def.get("spire", {}) as Dictionary).is_empty():
		spire = SpireDirector.new()
		spire.game = game
		spire.config = stage_def["spire"]
		add_child(spire)
	# --- Act III: the Assembly Halls ---
	if not (stage_def.get("assembly", {}) as Dictionary).is_empty():
		assembly = AssemblyDirector.new()
		assembly.game = game
		assembly.config = stage_def["assembly"]
		add_child(assembly)
		_kind_aliases = AssemblyDirector.guest_aliases(_kind_aliases, assembly.config)  # Guest kinds of the other Act III stages.
	# --- Act III: the Scrap Wastes ---
	if not (stage_def.get("wastes", {}) as Dictionary).is_empty():
		wastes = WastesDirector.new()
		wastes.game = game
		wastes.config = stage_def["wastes"]
		add_child(wastes)
	# --- Act III: the Iron Citadel ---
	if not (stage_def.get("citadel", {}) as Dictionary).is_empty():
		citadel = CitadelDirector.new()
		citadel.game = game
		citadel.config = stage_def["citadel"]
		add_child(citadel)
	# --- Act IV: the Shores of Ilion ---
	if not (stage_def.get("ilion", {}) as Dictionary).is_empty():
		ilion = IlionDirector.new()
		ilion.game = game
		ilion.config = stage_def["ilion"]
		add_child(ilion)
	# --- Act IV: Mount Olympus ---
	if not (stage_def.get("olympus", {}) as Dictionary).is_empty():
		olympus = OlympusDirector.new()
		olympus.game = game
		olympus.config = stage_def["olympus"]
		add_child(olympus)
	# --- Act IV: the Asphodel Underworld ---
	if not (stage_def.get("underworld", {}) as Dictionary).is_empty():
		underworld = UnderworldDirector.new()
		underworld.game = game
		underworld.config = stage_def["underworld"]
		add_child(underworld)
	# --- Act V: the Burning Province ---
	if not (stage_def.get("province", {}) as Dictionary).is_empty():
		province = ProvinceDirector.new()
		province.game = game
		province.config = stage_def["province"]
		add_child(province)
	# --- Act V: the Road to the Sun ---
	if not (stage_def.get("sun_road", {}) as Dictionary).is_empty():
		sun_road = SunRoadDirector.new()
		sun_road.game = game
		sun_road.config = stage_def["sun_road"]
		add_child(sun_road)


# =====================================================================================
# Main update
# =====================================================================================

## Fixed-order update called by Game every physics tick.
func step(delta: float) -> void:
	_frame += 1
	_compact()
	var t := game.elapsed
	_update_segment(t)
	var m := t / 60.0  # Elapsed minutes (time scaling, see WaveData).
	# Difficulty level (DifficultyData): hs / ds scale only the growth part of
	# the time scaling (exactly 1 on the standard level, so the products are
	# bit-identical to the unscaled formula).
	var hs := game.difficulty.hp_scaling()  # Level HP growth factor.
	var ds := game.difficulty.damage_scaling()  # Level damage growth factor.
	hp_mult = (1.0 + m * WaveData.HP_SCALE_PER_MINUTE * hs + m * m * WaveData.HP_SCALE_PER_MINUTE_SQ * hs) * game.difficulty.enemy_hp_mult()
	damage_mult = (1.0 + m * WaveData.DAMAGE_SCALE_PER_MINUTE * ds + m * m * WaveData.DAMAGE_SCALE_PER_MINUTE_SQ * ds) * game.difficulty.enemy_damage_mult()
	# Stage step-up (StageRegistry enemy_hp_mult / enemy_damage_mult; 1 in the Graveyard),
	# from the stage's enemy_mult_from time on (the boss always gets it, _spawn_boss()).
	if t >= float(stage_def.get("enemy_mult_from", 0.0)):
		hp_mult *= float(stage_def["enemy_hp_mult"])
		damage_mult *= float(stage_def["enemy_damage_mult"])
	# Stage objectives (the one place they touch enemy stats): every sacred
	# altar destroyed in the Sanctum cuts the max HP of soldiers spawned from
	# now on (SanctumDirector.objective_hp_mult(); 1 elsewhere).
	if sanctum != null:
		hp_mult *= sanctum.objective_hp_mult()
	_run_events(t)
	if boss == null and t >= float(boss_info["time"]):
		_spawn_boss()
	if t >= _next_reckoning:
		_spawn_reckoning_wave()
	_spawn_trickle(delta)
	var slot := _frame % UnitData.AI_TICK_DIVISOR
	var sep_slot := _frame % 6
	var player_pos := game.player.position
	# Never recycle inside the spawn ring (tall / narrow windows can make the
	# ring larger than RECYCLE_DISTANCE, which would recycle forever).
	var recycle := maxf(WaveData.RECYCLE_DISTANCE, _ring_radius() + WaveData.RECYCLE_MARGIN)
	var recycle2 := recycle * recycle
	var pw := game.powerups  # Stasis check (power-up freeze).
	var co := game.coop  # Co-op session (null in solo).
	for e in active:
		if not e.active:
			continue
		if co != null:
			co.bind_nearest(e.position)  # Co-op: this enemy acts on its nearest standing necromancer.
			player_pos = game.player.position
		var frozen := pw.freezes(e) or e.freeze_timer > 0.0 or e.stun_timer > 0.0  # Held by Stasis, a Deep Freeze or a Cathedral Horror stun this tick.
		e.set_frozen(frozen)
		if frozen:
			e.step_frozen(delta)
			e.resolve_blocking()
			continue
		if e.think_slot == slot:
			e.think()
		if e.think_slot % 6 == sep_slot:
			e.update_separation()
		e.physics_step(delta)
		e.resolve_blocking()
		if not e.is_boss and not e.is_objective and not e.is_miniboss and e.position.distance_squared_to(player_pos) > recycle2:
			_recycle(e)
	if co != null:
		co.bind_primary()  # Co-op: the stage directors act around the primary necromancer.
	stage.step(delta)
	rites.step(delta)
	if march != null:
		march.step(delta)
	if sanctum != null:
		sanctum.step(delta)
	if tide != null:
		tide.step(delta)  # Act II: the Harbour's water.
	if harbour != null:
		harbour.step(delta)  # Act II: buoys, caches, the Harbourmaster.
	if archive != null:
		archive.step(delta)
	if archive_haz != null:
		archive_haz.step(delta)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	if sinking != null:
		sinking.step(delta)
	if spire != null:
		spire.step(delta)
	if assembly != null:
		assembly.step(delta)  # Act III: belts, furnace channels, fabricators, the Beta Build.
	# --- Act III: the Scrap Wastes ---
	if wastes != null:
		wastes.step(delta)
	# --- Act III: the Iron Citadel ---
	if citadel != null:
		citadel.step(delta)
	# --- Act IV: the Shores of Ilion ---
	if ilion != null:
		ilion.step(delta)  # Siege towers, Polyphemus.
	# --- Act IV: Mount Olympus ---
	if olympus != null:
		olympus.step(delta)
	# --- Act IV: the Asphodel Underworld ---
	if underworld != null:
		underworld.step(delta)
	# --- Act V: the Burning Province ---
	if province != null:
		province.step(delta)  # The paddies, the village fires, Shuten-dōji.
	if province_haz != null:
		province_haz.step(delta)  # Fire patches and smoke clouds of the Province kinds.
	# --- Act V: the Road to the Sun ---
	if sun_road != null:
		sun_road.step(delta)


## The Archive kinds' world hazards (ArchiveHazards), created on first use.
func archive_hazards() -> ArchiveHazards:
	if archive_haz == null:
		archive_haz = ArchiveHazards.new()
		archive_haz.game = game
		add_child(archive_haz)
	return archive_haz


# --- Act V: the Burning Province ---
## The Province kinds' world hazards (ProvinceHazards: the sake fires, the
## village fires, the smoke clouds), created on first use, on any stage (a
## Province kind forced elsewhere with --spawn= brings its own fire and smoke).
func province_hazards() -> ProvinceHazards:
	if province_haz == null:
		province_haz = ProvinceHazards.new()
		province_haz.game = game
		add_child(province_haz)
	return province_haz


## Removes inactive enemies from `active`, preserving the existing swap-pop
## order. They must remain inert while this tick's spatial grid can list them.
func _compact() -> void:
	var i := 0
	while i < active.size():
		if active[i].active:
			i += 1
		else:
			active[i] = active[active.size() - 1]
			active.pop_back()
	_awaiting_grid_clear.append_array(_retired)
	_retired.clear()


## Called immediately AFTER the enemy spatial grid is cleared, before it is
## rebuilt (Game / CoopSession). Only already-compacted nodes are reusable:
## no node can be reactivated while either `active` or an old bucket lists it.
func release_retired() -> void:
	_pool.append_array(_awaiting_grid_clear)
	_awaiting_grid_clear.clear()


## Number of living regular (non-boss) enemies.
func regular_alive() -> int:
	var n := 0
	for e in active:
		if e.active and not e.is_boss:
			n += 1
	return n


## Current HUD objective text from the active segment.
func objective_text() -> String:
	if reckoning_wave > 0:
		return String(stage_def["reckoning_objective"])
	var stage_text := stage.objective_override()
	if stage_text != "":
		return stage_text
	if march != null:
		var march_text := march.objective_override()  # Live outposts / generators / carts.
		if march_text != "":
			return march_text
	if sanctum != null:
		var sanctum_text := sanctum.objective_override()  # Ward crystals / Guardian / altars.
		if sanctum_text != "":
			return sanctum_text
	if harbour != null:
		var harbour_text := harbour.objective_override()  # Harbourmaster / caches / buoys.
		if harbour_text != "":
			return harbour_text
	if archive != null:
		var archive_text := archive.objective_override()  # Rifts / the Librarian / tomes.
		if archive_text != "":
			return archive_text
	# --- Act II: Ul-Thalos, the Risen Spire ---
	if sinking != null and sinking.objective_override() != "":
		return sinking.objective_override()  # The sea is rising.
	if spire != null and spire.objective_override() != "":
		return spire.objective_override()  # Dream pillars.
	if assembly != null and assembly.objective_override() != "":
		return assembly.objective_override()  # Act III: the Beta Build, fabricators.
	# --- Act III: the Scrap Wastes ---
	if wastes != null and wastes.objective_override() != "":
		return wastes.objective_override()  # The Trojan Horse, a storm, Signal Pylons.
	# --- Act III: the Iron Citadel ---
	if citadel != null and citadel.objective_override() != "":
		return citadel.objective_override()  # Shield Gates, sentry turrets.
	# --- Act IV: the Shores of Ilion ---
	if ilion != null and ilion.objective_override() != "":
		return ilion.objective_override()  # Polyphemus, the siege towers.
	# --- Act IV: Mount Olympus ---
	if olympus != null and olympus.objective_override() != "":
		return olympus.objective_override()  # The Pantheon Trial's god in play.
	# --- Act IV: the Asphodel Underworld ---
	if underworld != null and underworld.objective_override() != "":
		return underworld.objective_override()  # Cerberus's heads.
	# --- Act V: the Burning Province ---
	if province != null and province.objective_override() != "":
		return province.objective_override()  # Shuten-dōji.
	# --- Act V: the Road to the Sun ---
	if sun_road != null and sun_road.objective_override() != "":
		return sun_road.objective_override()  # The Kirin.
	if boss != null and not boss.active:
		return String(boss_info["dead_objective"])
	return segments[segment_index]["objective"]


# =====================================================================================
# Timeline
# =====================================================================================

## Advances `segment_index` to the last segment that has started.
func _update_segment(t: float) -> void:
	while segment_index + 1 < segments.size() and t >= float(segments[segment_index + 1]["start"]):
		segment_index += 1


## The current soft cap on living regular enemies: the segment's max_alive
## scaled by the difficulty spawn multiplier (level x Pact / Oath / run
## modifiers), never above HARD_CAP. The trickle and other continuous sources
## (Crimson March outposts) stop at it; scripted waves only respect HARD_CAP.
func soft_cap() -> int:
	var seg: Dictionary = segments[segment_index]
	return mini(roundi(float(seg["max_alive"]) * game.difficulty.enemy_spawn_mult()), hard_cap())


## Trickle spawner: `rate` enemies/s up to soft_cap(), both scaled by the
## difficulty spawn multiplier (level x Pact / Oath / run modifiers;
## HARD_CAP still applies). The difficulty may change the kind weights
## (Purge the Unholy) and promote a soldier to an elite (level elite_chance;
## that roll is skipped entirely when the chance is 0). A promoted elite keeps
## the base soldier's XP and never rolls the elite chest / power-up chance
## (Enemy.is_promoted): with elite loot, Deathlord's extra elites completed
## builds about a minute early.
func _spawn_trickle(delta: float) -> void:
	var seg: Dictionary = segments[segment_index]
	var spawn_mult := game.difficulty.enemy_spawn_mult()  # Difficulty spawn multiplier.
	if harbour != null:
		spawn_mult *= harbour.trickle_mult()  # Act II: sunk bell buoys thin the trickle.
	if assembly != null:
		spawn_mult *= assembly.trickle_mult()  # Act III: smashed fabricators thin the trickle.
	spawn_accum += float(seg["rate"]) * spawn_mult * delta
	var cap: int = soft_cap()
	var alive := regular_alive()
	var elite_chance := game.difficulty.elite_chance()  # Level trickle-elite chance.
	while spawn_accum >= 1.0:
		spawn_accum -= 1.0
		if alive >= cap:
			continue
		var weights: Dictionary = seg["weights"]  # The segment's kind weights.
		if game.shogunate != null:
			weights = game.shogunate.sun.timeline_weights(seg)  # Act V: night kinds only at night (the one timeline helper).
		var kind := _pick_kind(game.difficulty.trickle_weights(weights, game.elapsed))
		var pos := _ring_point(randf() * TAU) if game.coop == null else _ring_point_at(game.coop.spawn_anchor(), randf() * TAU)  # Spawn point on the ring (co-op: each necromancer in turn).
		var elite := elite_chance > 0.0 and randf() < elite_chance  # Promoted by the level.
		var e := _spawn_enemy(kind, pos, elite)  # The new soldier.
		if elite:
			# A threat, not a loot source: base XP, no elite chest / drop chance.
			e.is_promoted = true
			e.xp_value = int(enemy_def(kind)["xp"])
			game.stat_add("elites_promoted", 1.0)
		alive += 1


## Weighted random choice of an enemy kind.
func _pick_kind(weights: Dictionary) -> String:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var roll := randf() * total
	for k: String in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return "recruit"


## Fires every timeline event whose time has come.
func _run_events(t: float) -> void:
	while event_index < events.size() and t >= float(events[event_index]["time"]):
		_run_event(events[event_index])
		event_index += 1


## Runs one timeline event: stage events go to the StageDirector (Graveyard)
## or the MarchDirector (Crimson March), "wave" events spawn their groups in
## formation and show the banner.
func _run_event(ev: Dictionary) -> void:
	match String(ev.get("type", "wave")):
		"consecration":
			stage.start_consecration(ev)
			game.stat_add("wave_events", 1.0)
			return
		"crypt":
			stage.start_crypt(ev)
			game.stat_add("wave_events", 1.0)
			return
		"outposts", "generators", "cart":
			if march != null:
				march.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		"chamber", "guardian", "altars":
			if sanctum != null:
				sanctum.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		"buoys", "caches", "harbourmaster":
			if harbour != null:
				harbour.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		"tomes", "librarian", "rift":
			if archive != null:
				archive.start_event(ev)  # Act II, the Hollow Archive.
			game.stat_add("wave_events", 1.0)
			return
		# --- Act II: Ul-Thalos, the Risen Spire ---
		"pillars":
			if spire != null:
				spire.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act III: the Assembly Halls ---
		"fabricators", "beta_build":
			if assembly != null:
				assembly.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act III: the Scrap Wastes ---
		"pylons", "storm", "trojan":
			if wastes != null:
				wastes.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act III: the Iron Citadel ---
		"gate", "turrets", "valkyrie":
			if citadel != null:
				citadel.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act IV: the Shores of Ilion ---
		"siege_towers", "polyphemus":
			if ilion != null:
				ilion.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act IV: Mount Olympus ---
		"god":
			if olympus != null:
				olympus.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act IV: the Asphodel Underworld ---
		"cerberus":
			if underworld != null:
				underworld.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return
		# --- Act V: the Shogunate of the Rising Sun ---
		"ambush":
			if game.shogunate != null:
				game.shogunate.ambush.start_event(ev)  # From the Shadows (it shows the banner when the squad appears).
			game.stat_add("wave_events", 1.0)
			return
		# --- Act V: the Burning Province ---
		"shuten_doji":
			if province != null:
				province.start_event(ev)  # Night only: it waits for the night.
			game.stat_add("wave_events", 1.0)
			return
		# --- Act V: the Road to the Sun ---
		"kirin":
			if sun_road != null:
				sun_road.start_event(ev)
			game.stat_add("wave_events", 1.0)
			return  # The Kirin's event (SunRoadDirector).
	show_banner(ev["banner"])
	var groups: Array = ev["groups"]
	if game.shogunate != null:
		groups = game.shogunate.sun.filter_groups(groups)  # Act V: night kinds only at night (the one timeline helper).
	if harbour != null and harbour.wave_mult() < 1.0:
		groups = _scaled_groups(groups, harbour.wave_mult())  # Act II: sunk bell buoys shrink the Eye's waves.
	if assembly != null and assembly.wave_mult() < 1.0:
		groups = _scaled_groups(groups, assembly.wave_mult())  # Act III: smashed fabricators shrink the Empire's waves.
	spawn_formation(String(ev["formation"]), groups)
	game.stat_add("wave_events", 1.0)


## A copy of wave `groups` with every count scaled by `mult` (rounded down,
## at least 1 per group; Gullhaven's sunk bell buoys, HarbourDirector).
static func _scaled_groups(groups: Array, mult: float) -> Array:
	var out: Array = []
	for g: Dictionary in groups:
		var c := g.duplicate()
		c["count"] = maxi(1, floori(float(g["count"]) * mult))
		out.append(c)
	return out


## The hard cap on living regular enemies: WaveData.HARD_CAP, x CoopData's
## alive_cap in co-op (DifficultyModifiers.coop_mult(); exactly HARD_CAP solo).
func hard_cap() -> int:
	if game.coop == null:
		return WaveData.HARD_CAP
	return roundi(float(WaveData.HARD_CAP) * game.difficulty.coop_mult("alive_cap"))


## Spawns `groups` (list of {kind, count, elite}) in `formation` ("ring",
## "arc" or "line") on the spawn ring around the player (HARD_CAP respected).
## Used by "wave" events and by MarchDirector's escort waves. Co-op: one copy
## around each standing necromancer (CoopData: the doubled enemies).
func spawn_formation(formation: String, groups: Array) -> void:
	if game.coop != null:
		var co := game.coop
		var prev := co.bound
		var alive := co.alive_slots()
		for k in mini(alive.size(), CoopData.WAVE_COPIES_MAX):
			co.bind(alive[k])
			_spawn_formation_here(formation, groups)
		co.bind(prev)
		return
	_spawn_formation_here(formation, groups)


## One copy of a formation wave around the bound necromancer (spawn_formation()).
func _spawn_formation_here(formation: String, groups: Array) -> void:
	var members: Array[Dictionary] = []
	for g: Dictionary in groups:
		for i in int(g["count"]):
			members.append({"kind": g["kind"], "elite": g["elite"]})
	var n := members.size()
	var center := randf() * TAU
	var ring := _ring_radius()
	var p := game.player.position
	var alive := regular_alive()
	var cap := hard_cap()  # Living regular enemies allowed.
	for i in n:
		if alive >= cap:
			break
		var pos: Vector2
		match formation:
			"ring":
				pos = p + Vector2.from_angle(TAU * float(i) / float(n) + randf_range(-0.05, 0.05)) * ring
			"arc":
				var a := center + (float(i) / maxf(1.0, float(n - 1)) - 0.5) * WaveData.ARC_SPREAD
				pos = p + Vector2.from_angle(a) * (ring + randf_range(0.0, 40.0))
			_:
				# "line": rows of 8 marching in from one direction.
				var dir := Vector2.from_angle(center)
				var perp := Vector2(-dir.y, dir.x)
				var row := floori(float(i) / 8.0)
				var col := i % 8
				pos = p + dir * (ring + float(row) * WaveData.LINE_SPACING) + perp * (float(col) - 3.5) * WaveData.LINE_SPACING
		var m := members[i]
		_spawn_enemy(m["kind"], pos, m["elite"])
		alive += 1


## Shows `text` as the HUD event banner.
func show_banner(text: String) -> void:
	banner_text = text
	banner_until = game.elapsed + WaveData.BANNER_TIME


## Spawns the stage boss (stage_def boss.id: "alaric" -> BossAlaric,
## "vael" -> BossVael, "seraphine" -> BossSeraphine) at the spawn ring (HP
## not time-scaled, but scaled by
## the difficulty level's boss_hp and a share of the opt-in HP bonus,
## DifficultyModifiers.boss_hp_mult, and by the stage's enemy HP multiplier).
func _spawn_boss() -> void:
	# The boss script: the arrival's "script" when given (an Act II stub's
	# placeholder), else its id. Act I bosses by name; any other id is an
	# Ancient Eye boss loaded from EYE_BOSS_DIR + "boss_<id>.gd" (each Act II
	# stage adds its boss as a new file), else an Electronic Empire boss from
	# EMPIRE_BOSS_DIR (Act III, the same way), else an Olympian Republic boss
	# from PANTHEON_BOSS_DIR (Act IV), else a Shogunate boss from
	# SHOGUNATE_BOSS_DIR (Act V); Sir Alaric when none exists.
	var sid := String(boss_info.get("script", boss_info["id"]))  # Boss script id.
	match sid:
		"vael":
			boss = BossVael.new()
		"seraphine":
			boss = BossSeraphine.new()
		"alaric":
			boss = BossAlaric.new()
		_:
			var path := EYE_BOSS_DIR + "boss_" + sid + ".gd"  # An Ancient Eye boss script.
			if not ResourceLoader.exists(path):
				path = EMPIRE_BOSS_DIR + "boss_" + sid + ".gd"  # Act III: an Electronic Empire boss script.
			if not ResourceLoader.exists(path):
				path = PANTHEON_BOSS_DIR + "boss_" + sid + ".gd"  # Act IV: an Olympian Republic boss script.
			if not ResourceLoader.exists(path):
				path = SHOGUNATE_BOSS_DIR + "boss_" + sid + ".gd"  # Act V: a Shogunate boss script.
			boss = (load(path) as Script).new() as Boss if ResourceLoader.exists(path) else BossAlaric.new()
	add_child(boss)
	boss.setup_boss(game, _ring_point(randf() * TAU), game.difficulty.boss_hp_mult() * float(stage_def["enemy_hp_mult"]), _next_slot)
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	active.append(boss)
	show_banner(String(boss_info["arrive_banner"]))
	boss_spawned.emit(boss)


## Spawns the next Reckoning wave around the player: count and HP/damage
## compound every wave (the stage's "reckoning" data), ignoring the regular caps.
## A stage's optional `companions` (Dawn's Wrath: Sun Paladins) march with
## each wave's Inquisitors, scaled the same way.
func _spawn_reckoning_wave() -> void:
	var r: Dictionary = stage_def["reckoning"]
	if reckoning_wave == 0:
		show_banner(r["banner"])
		reckoning_started.emit()
	if game.coop != null:
		var co := game.coop  # Co-op: one wave around each standing necromancer (the doubling).
		var prev := co.bound
		var alive := co.alive_slots()
		for k in mini(alive.size(), CoopData.WAVE_COPIES_MAX):
			co.bind(alive[k])
			_reckoning_wave_here(r)
		co.bind(prev)
	else:
		_reckoning_wave_here(r)
	reckoning_wave += 1
	_next_reckoning += float(r["interval"])


## One Reckoning wave (stage data `r`) around the bound necromancer.
func _reckoning_wave_here(r: Dictionary) -> void:
	var count: int = int(r["base_count"]) + int(r["count_growth"]) * reckoning_wave
	var hp_scale := hp_mult * pow(float(r["hp_growth"]), float(reckoning_wave))
	var dmg_scale := pow(float(r["damage_growth"]), float(reckoning_wave))
	var offset := randf() * TAU
	var rk := String(r.get("kind", ""))  # Optional main kind (an Act II stage's own); "" = the Reckoning Inquisitor.
	var rkind := resolve_kind(rk) if rk != "" else "inquisitor"  # Real kind of the main wave.
	var rdef: Dictionary = enemy_def(rk) if rk != "" else EnemyData.RECKONING_ENEMY  # Its design row.
	for i in count:
		var e := _spawn_enemy_def(rkind, rdef, _ring_point(offset + TAU * float(i) / float(count)), hp_scale, false)
		e.damage *= dmg_scale
		e.is_reckoning = true
		if game.shogunate != null:
			game.shogunate.on_reckoning_spawn(e)  # Act V: the Endless Night quickens it.
	for comp: Dictionary in r.get("companions", []):
		var n := int(comp["count"]) + floori(float(reckoning_wave) * float(comp["growth"]))  # Companions this wave.
		var kind := resolve_kind(String(comp["kind"]))  # Real kind of the companion.
		for i in n:
			var c := _spawn_enemy_def(kind, enemy_def(kind), _ring_point(offset + TAU * (float(i) + 0.5) / float(maxi(1, n))), hp_scale, false)
			c.damage *= dmg_scale
			c.is_reckoning = true
			if game.shogunate != null:
				game.shogunate.on_reckoning_spawn(c)  # Act V: the Endless Night quickens it.
		count += n
	game.stat_add("reckoning_spawned", float(count))


# =====================================================================================
# Spawning, recycling, death
# =====================================================================================

## Radius (px) of the off-screen spawn ring around the player.
func _ring_radius() -> float:
	return game.gameplay_view_size().length() * 0.5 + WaveData.SPAWN_MARGIN  # Co-op: one fixed size on every machine.


## Point on the spawn ring at `angle`.
func _ring_point(angle: float) -> Vector2:
	return game.player.position + Vector2.from_angle(angle) * _ring_radius()


## Point at `angle` on the spawn ring around `center` (co-op: another necromancer).
func _ring_point_at(center: Vector2, angle: float) -> Vector2:
	return center + Vector2.from_angle(angle) * _ring_radius()


## Public spawn-ring point (StageDirector sends consecrators from it).
func ring_point(angle: float) -> Vector2:
	return _ring_point(angle)


## Spawns a regular enemy of `kind` at `pos` (moved out of obstacles) for the
## StageDirector, the MarchDirector and the bosses' summons. Ignores the
## caps; callers check regular_alive() themselves.
func spawn_at(kind: String, pos: Vector2, elite: bool) -> Enemy:
	return _spawn_enemy(kind, pos, elite)


## Design row of enemy `kind` (a stage alias is resolved first):
## EnemyData.ENEMIES (Graveyard roster) first, then
## SanctumObjectiveData.STRUCTURES (Sanctum ward crystals and altars), then
## MarchEnemyData.ENEMIES (Crimson March soldiers and structures), then
## BattleSisterData.ENEMIES (the Sister of the Scourge, March and Sanctum),
## then the Ancient Eye's tables (Act II: EyeEnemyData, then each stage's own
## HarbourEnemyData / ArchiveEnemyData / SpireEnemyData), then the
## Electronic Empire's (Act III: empire_def()), then the Olympian Republic's
## (Act IV: pantheon_def()), then the Shogunate's (Act V: shogunate_def()),
## then SanctumEnemyData.ENEMIES (the Sanctum of Judgment's soldiers and the
## Cathedral Guardian).
func enemy_def(kind: String) -> Dictionary:
	kind = resolve_kind(kind)
	if EnemyData.ENEMIES.has(kind):
		return EnemyData.ENEMIES[kind]
	if SanctumObjectiveData.STRUCTURES.has(kind):
		return SanctumObjectiveData.STRUCTURES[kind]
	if MarchEnemyData.ENEMIES.has(kind):
		return MarchEnemyData.ENEMIES[kind]
	if BattleSisterData.ENEMIES.has(kind):
		return BattleSisterData.ENEMIES[kind]
	var eye := eye_def(kind)  # Act II kinds ({} when not an Eye kind).
	if not eye.is_empty():
		return eye
	var empire := empire_def(kind)  # Act III kinds ({} when not an Empire kind).
	if not empire.is_empty():
		return empire
	var pantheon := pantheon_def(kind)  # Act IV kinds ({} when not a Pantheon kind).
	if not pantheon.is_empty():
		return pantheon
	var shogunate := shogunate_def(kind)  # Act V kinds ({} when not a Shogunate kind).
	if not shogunate.is_empty():
		return shogunate
	return SanctumEnemyData.ENEMIES[kind]


## Design row of Ancient Eye kind `kind` (real id), or {} when it is none:
## EyeEnemyData (the shared kinds and the Drowned Thrall) first, then each
## Act II stage's own table.
static func eye_def(kind: String) -> Dictionary:
	if EyeEnemyData.ENEMIES.has(kind):
		return EyeEnemyData.ENEMIES[kind]
	if HarbourEnemyData.ENEMIES.has(kind):
		return HarbourEnemyData.ENEMIES[kind]
	if ArchiveEnemyData.ENEMIES.has(kind):
		return ArchiveEnemyData.ENEMIES[kind]
	if SpireEnemyData.ENEMIES.has(kind):
		return SpireEnemyData.ENEMIES[kind]
	return {}


## Design row of Electronic Empire kind `kind` (real id), or {} when it is
## none: EmpireEnemyData (the shared kinds and the Purge Protocol's kill-drone)
## first, then each Act III stage's own table (phase 2 fills them).
static func empire_def(kind: String) -> Dictionary:
	if EmpireEnemyData.ENEMIES.has(kind):
		return EmpireEnemyData.ENEMIES[kind]
	if WastesEnemyData.ENEMIES.has(kind):
		return WastesEnemyData.ENEMIES[kind]
	if AssemblyEnemyData.ENEMIES.has(kind):
		return AssemblyEnemyData.ENEMIES[kind]
	if CitadelEnemyData.ENEMIES.has(kind):
		return CitadelEnemyData.ENEMIES[kind]
	return {}


# --- Act IV: the Olympian Republic ---
## Design row of Olympian Republic kind `kind` (real id), or {} when it is
## none: PantheonEnemyData (the shared kinds and the Twilight's Bronze Titan)
## first, then each Act IV stage's own table (phase 2 fills them).
static func pantheon_def(kind: String) -> Dictionary:
	if PantheonEnemyData.ENEMIES.has(kind):
		return PantheonEnemyData.ENEMIES[kind]
	if IlionEnemyData.ENEMIES.has(kind):
		return IlionEnemyData.ENEMIES[kind]
	if OlympusEnemyData.ENEMIES.has(kind):
		return OlympusEnemyData.ENEMIES[kind]
	if UnderworldEnemyData.ENEMIES.has(kind):
		return UnderworldEnemyData.ENEMIES[kind]
	return {}


# --- Act V: the Shogunate of the Rising Sun ---
## Design row of Shogunate kind `kind` (real id), or {} when it is none:
## ShogunateEnemyData (the shared kinds, the Endless Night's Oni among them)
## first, then each Act V stage's own table (phase 2 fills them).
static func shogunate_def(kind: String) -> Dictionary:
	if ShogunateEnemyData.ENEMIES.has(kind):
		return ShogunateEnemyData.ENEMIES[kind]
	if ProvinceEnemyData.ENEMIES.has(kind):
		return ProvinceEnemyData.ENEMIES[kind]
	if KuroganeEnemyData.ENEMIES.has(kind):
		return KuroganeEnemyData.ENEMIES[kind]
	if SunRoadEnemyData.ENEMIES.has(kind):
		return SunRoadEnemyData.ENEMIES[kind]
	return {}


## True if `kind` is a spawnable enemy kind of any stage's data (real ids;
## stage aliases are not resolved here).
static func is_known_kind(kind: String) -> bool:
	return EnemyData.ENEMIES.has(kind) or SanctumObjectiveData.STRUCTURES.has(kind) \
			or MarchEnemyData.ENEMIES.has(kind) or BattleSisterData.ENEMIES.has(kind) \
			or SanctumEnemyData.ENEMIES.has(kind) or not eye_def(kind).is_empty() \
			or not empire_def(kind).is_empty() or not pantheon_def(kind).is_empty() \
			or not shogunate_def(kind).is_empty()  # Act V


## Registers `e` as the living miniboss (GuardianKit; the HUD shows its bar
## under its display name).
func set_miniboss(e: Enemy) -> void:
	if game.coop != null and (miniboss != e or miniboss_gen != e.generation):
		var m := game.difficulty.coop_mult("miniboss_hp")  # Co-op: tougher for two armies (CoopData).
		e.max_hp *= m
		e.hp *= m
	miniboss = e
	miniboss_gen = e.generation


## Releases the miniboss slot if `e` holds it (it died or was despawned).
func clear_miniboss(e: Enemy) -> void:
	if miniboss == e:
		miniboss = null


## The living miniboss, or null.
func miniboss_alive() -> Enemy:
	if miniboss != null and miniboss.active and miniboss.generation == miniboss_gen:
		return miniboss
	return null


## The real enemy kind of `kind`: the stage's alias target (StageRegistry
## "kind_aliases", e.g. the Sanctum's "sentinel"), else `kind` itself.
func resolve_kind(kind: String) -> String:
	return String(_kind_aliases.get(kind, kind))


## Takes an enemy from the pool (or creates one) and activates it.
func _spawn_enemy(kind: String, pos: Vector2, elite: bool) -> Enemy:
	kind = resolve_kind(kind)
	return _spawn_enemy_def(kind, enemy_def(kind), pos, hp_mult, elite)


## Takes a living enemy off the field WITHOUT a kill (no XP, no drops, no
## kill count): a supply cart that escaped, a Holy Standard whose time ran
## out. Like a kill, it waits for compaction AND the following spatial-grid
## clear before reuse, so no old active-list or bucket reference sees it alive.
func despawn(e: Enemy) -> void:
	if not e.active or e.is_boss:
		return
	e.deactivate()
	_retired.append(e)


## As _spawn_enemy() but with an explicit definition and HP multiplier.
## The position is moved out of any obstacle first.
func _spawn_enemy_def(kind: String, def: Dictionary, pos: Vector2, hp_scale: float, elite: bool) -> Enemy:
	var body_r := float(def["radius"]) * (EnemyData.ELITE_RADIUS_MULT if elite else 1.0)
	if sinking != null:
		pos = sinking.spawn_point(pos)  # Act II, Ul-Thalos: a cultist spawned at sea climbs out at the shore.
	pos = game.arena.free_point(pos, body_r)
	var e: Enemy
	if _pool.is_empty():
		e = Enemy.new()
		add_child(e)
		created_nodes += 1
	else:
		e = _pool.pop_back()
	e.activate(game, kind, def, pos, hp_scale, elite, _next_slot)
	var speed_mult := game.difficulty.enemy_speed_mult()  # Level "aggression".
	if speed_mult != 1.0:
		e.move_speed *= speed_mult
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	active.append(e)
	total_spawned += 1
	return e


## Moves a far-away enemy to the spawn ring ahead of the player's movement.
func _recycle(e: Enemy) -> void:
	var v := game.player.velocity
	var angle := v.angle() + randf_range(-1.0, 1.0) if v.length() > 1.0 else randf() * TAU
	var at := _ring_point(angle)  # Recycle point on the spawn ring.
	if sinking != null:
		at = sinking.spawn_point(at)  # Act II, Ul-Thalos: out of the sea at the shore.
	e.position = game.arena.free_point(at, e.radius)
	e.sep = Vector2.ZERO
	total_recycled += 1


## Called by CombatResolver when an enemy dies.
func on_enemy_killed(e: Enemy) -> void:
	rites.on_enemy_killed(e)  # Sanctum kit death actions and the revival record.
	e.deactivate()
	if e.is_boss:
		# Big reward burst (user brief: no longer the win condition).
		# Its strip when the art exists (visual only): an Empire boss falls as a machine (GDD §15.0 "Act III AoE art").
		game.effects.impact(e.position, 120.0, Palette.GOLD, EmpireFxData.BOSS_DEATH if game.effects.empire_look else "boss_death")
		var bdef: Dictionary = (e as Boss).boss_def  # The fallen boss's data (reward burst).
		var n: int = bdef["reward_crystals"]
		var each: int = maxi(1, floori(float(bdef["reward_xp"]) / float(n)))
		for i in n:
			game.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * randf_range(20.0, 70.0), each)
		show_banner(String(boss_info["defeat_banner"]))
		boss_defeated.emit()
	else:
		_retired.append(e)
