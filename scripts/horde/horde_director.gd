## HordeDirector — owns the undead army (GDD §22 / §32 / §39 HORDE DIRECTOR):
##   * living unit registry + object pool of SummonedUnit nodes,
##   * per-class skill level, capacity and effective stats (skill bonuses x
##     passive bonuses x meta upgrades, GDD §34 stacking rule; meta values
##     come from game.meta, see MetaModifiers), including the numbers of the
##     later classes' specials (_special_stats(), SummonBehavior),
##   * per-ability sequential replenishment queues (GDD §24; a replaced unit
##     rises with a Bone Reserve barrier when that Ossuary upgrade is owned, and
##     Commander's Presence adds minion damage per distinct class owned),
##   * soft formation anchors at 4 Hz (GDD §26),
##   * player threat evaluation at 5 Hz (GDD §32),
##   * staggered 5 Hz AI ticks: each unit thinks on 1 of 12 physics ticks,
##   * army synergies (GDD §6.3) through its SynergyManager.
##   * temporary summons from stage events (empowered graves, Crypt Defender
##     guardians): same shared AI, but outside caps / HUD counts, and they
##     crumble after their duration (GDD §15.0 decision on open question 14).
##   * summon evolutions (Death Knight, Lich, Profane Bishop) through its
##     SummonEvolutions: the evolution overlay on effective stats, in-place
##     transformation and the Mender + Warder merge (SummonEvolutionData);
##     the Bone Colossus taunt and death burst through its ColossusKit.
##     transformation and the Mender + Warder merge (SummonEvolutionData).
##   * army stances (game.stance, ArmyStance / StanceData): the effective
##     stats take the stance's leash, soft recall, formation pull and (when
##     switched on) flavour bonuses; the formation anchors use its shape
##     (Escort = the original layout below, the others StanceFormations).
##   * holy suppression (GDD §7.3) through its SuppressionField
##     (`suppression`), reached through ONE call, add_suppression(): no
##     replacement spawns inside an armed zone, and deaths inside it are held
##     (that class's replacement pauses) until it ends.
##   * the ground and air effects of the newest classes through its
##     HordeHazards (`hazards`): Corpse Catapult boulders in flight, Hellhound
##     fire trails and Ossuary Engine bone shards.
##   * Act II: the Fallen Seraph's feather rings through SeraphFeathers
##     (`feathers`, created on first use by seraph_feathers()).
##   * Content wave 2: the Bone Golem's Ossuary Hunger and the Ossuary
##     Titan's heal, barrier and death wall through GolemKit (`golems`,
##     created by the first Golem, golem_kit()); Grave Masonry's hold bonus in
##     compute_stats().
##   * Act VI, the Inferno: TEMPTATION through ONE call, charm() (and
##     break_charms() when the charmer dies), run by the Inferno's Temptation
##     (game.inferno): a charmed summon is parked (SummonedUnit.charmed: it is
##     skipped by step(), the grids and the ring posts) while a hostile body
##     wearing its look fights for hell, then comes back. An enemy effect on a
##     unit, like Act II's Claims: no summon has an act rule of its own.
## Ranged overkill reservations are stored on the enemies themselves
## (Enemy.incoming_damage) and managed by ProjectileManager.
class_name HordeDirector
extends Node2D

## A summon finished being created (GDD §37 summon_created).
signal summon_created(unit: SummonedUnit)
## A summon died (GDD §37 summon_died).
signal summon_died(unit: SummonedUnit)
## Live summon count of any class changed (GDD §37 summon_count_changed).
signal summon_count_changed
## Capacity of any class changed (GDD §37 summon_cap_changed).
signal summon_cap_changed

## Owning run.
var game: Game
## Co-op slot of the player this army belongs to (0 in solo; CoopSession).
## CombatResolver binds it before resolving a hit on one of its summons.
var slot: int = 0
## Living (or spawning) units. Dead units are removed immediately.
var units: Array[SummonedUnit] = []
## Pooled, inactive unit nodes ready for reuse.
var _pool: Array[SummonedUnit] = []
## Class id -> summon ability level (0 = not learned).
var class_levels: Dictionary = {}
## Class id -> effective stats Dictionary (see compute_stats()).
var class_stats: Dictionary = {}
## Class id -> number of living units of that class.
var class_counts: Dictionary = {}
## Class id -> seconds accumulated toward the next replacement.
var replenish_timer: Dictionary = {}
## Class id -> units to spawn immediately (newly learned / capacity raised).
var immediate_spawns: Dictionary = {}
## Normalised direction from the player toward the main threat.
var threat_dir: Vector2 = Vector2.RIGHT
## 0..1 how much pressure the player is under.
var threat_level: float = 0.0
## True when enemies swarm the player or the player is low on HP.
var player_in_danger: bool = false
## Physics ticks since the run started (drives staggering).
var _frame: int = 0
## Next think slot handed to a new unit (round-robin).
var _next_slot: int = 0
## Total SummonedUnit nodes ever instantiated (debug: pool health).
var created_nodes: int = 0
## Total summons spawned (including reuse).
var total_spawned: int = 0
## Total summon deaths.
var total_deaths: int = 0
## Total hard recalls (should stay rare, GDD §24).
var hard_recalls: int = 0
## Of those, stall recalls: units teleported because they were wedged and
## made no progress (UnitData.STALL_TIME); also counted in hard_recalls.
var stall_recalls: int = 0
## Temporary summons currently alive (not in class_counts).
var temp_alive: int = 0
## Temporary summons spawned this run.
var temp_spawned: int = 0
## Reusable query buffer.
var _tmp: Array = []
## Army synergies (activation + effects, GDD §6.3).
var synergies: SynergyManager
## Summon evolutions (state, stat overlay, transformation / merge).
var evolutions: SummonEvolutions
## Bone Colossus taunt list and death burst (ColossusKit).
var colossi: ColossusKit
## Holy suppression zones (Radiant Inquisitor, Seraphine; add_suppression()).
var suppression: SuppressionField
## Catapult boulders, Hellhound fire trails and Ossuary Engine shards (HordeHazards).
var hazards: HordeHazards
## Act II: the Fallen Seraph's feather rings (SeraphFeathers); null until the
## first ring is laid (seraph_feathers()), so runs without her never create it.
var feathers: SeraphFeathers = null
## Content wave 2: the Bone Golem's army-wide rules (GolemKit); null until the
## first Golem rises (golem_kit()), so runs without one never create it.
var golems: GolemKit = null
# --- Act VI: the Palace of Silk and Ash ---
## The thralls of this army (Enthrall: foes turned by the Temptation spell and
## the Succubus class); null until the first turn (enthrall_foe()).
var enthrall: Enthrall = null
## Radius (px) Enemy.resolve_blocking() adds to its own to find blockers:
## UnitData.MAX_BLOCK_RADIUS, raised to the widest block_radius ever spawned
## this run (the Corpse Abomination's), never lowered.
var block_query_radius: float = UnitData.MAX_BLOCK_RADIUS
# --- Act III: the Iron Citadel ---
## Radius (px) of the Bone Ring's posts at the last formation pass
## (StanceFormations._ring(); StanceData.RING_MIN before the first): the Scrap
## Swarm spell orbits just outside it. Read only; it changes no unit.
var ring_radius: float = StanceData.RING_MIN
# --- Act V: Castle Kurogane ---
## Banner of the Dead: this army's standing banners, (x, y, radius px) each,
## written every tick by the spell (set_banners(); empty = none). Read only
## through attack_haste().
var banner_zones: PackedVector3Array = PackedVector3Array()
## Banner of the Dead: the attack-speed share (fraction) a summon inside a
## banner's radius gains (0 = no banner).
var banner_haste: float = 0.0
## Warlord's Seal: the attack-speed share (fraction) a summon within
## BannerData.SEAL_RADIUS px of this army's necromancer gains (cached at the
## start of each step from the bound player's passive; 0 = not owned).
var _seal_haste: float = 0.0
## Warlord's Seal: where this army's necromancer stood at the start of the step.
var _seal_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	for cls: String in UnitData.CLASS_ORDER:
		class_levels[cls] = 0
		class_counts[cls] = 0
		replenish_timer[cls] = 0.0
		immediate_spawns[cls] = 0
	synergies = SynergyManager.new(self)
	evolutions = SummonEvolutions.new(self)
	colossi = ColossusKit.new(self)


func _ready() -> void:
	suppression = SuppressionField.new()
	suppression.game = game
	add_child(suppression)
	hazards = HordeHazards.new()
	hazards.game = game
	add_child(hazards)


## THE suppression API (GDD §7.3, §15.0): a zone at `pos`, `radius` px, that
## arms for `telegraph` s (a gold warning ring, no effect yet) and then for
## `duration` s blocks summon replacement inside it, holds the replacement of
## every summon that dies inside it until it ends, and makes minion attacks
## on enemies inside it deal `damage_mult` of their damage (1 = unchanged).
## `source` tags it for the stats ("inquisitor", "seraphine"...). Replacement
## resumes normally afterwards (SuppressionField).
func add_suppression(pos: Vector2, radius: float, duration: float, damage_mult: float = 1.0, telegraph: float = 0.0, source: String = "inquisitor") -> void:
	if game.coop != null:
		for h in game.all_hordes:
			h.suppression.add(pos, radius, duration, damage_mult, telegraph, source)  # Co-op: holy ground holds every army.
		return
	suppression.add(pos, radius, duration, damage_mult, telegraph, source)


## Act II: the Fallen Seraph's feather rings, created on first use (a run
## without a Fallen Seraph never calls this).
func seraph_feathers() -> SeraphFeathers:
	if feathers == null:
		feathers = SeraphFeathers.new()
		feathers.game = game
		add_child(feathers)
	return feathers


## Content wave 2: the Bone Golem's kit, created on first use (the first
## Golem's activation; a run without a Golem never calls this).
func golem_kit() -> GolemKit:
	if golems == null:
		golems = GolemKit.new(self)
	return golems


# =====================================================================================
# Per-tick update (GDD §39 update_horde)
# =====================================================================================

## Fixed-order update called by Game every physics tick.
func step(delta: float) -> void:
	_frame += 1
	_seal_haste = game.abilities.passive_value(BannerData.SEAL, BannerData.SEAL_KEY)  # Act V: Warlord's Seal (0 when not owned).
	_seal_pos = game.player.position
	if temp_alive > 0:
		_update_temporaries(delta)
	suppression.step(delta)
	hazards.step(delta)
	if feathers != null:
		feathers.step(delta)  # Act II: Fallen Seraph feather rings.
	if enthrall != null:
		enthrall.step()  # Act VI: thralls slain, charms run out (Enthrall).
	_update_replenishment(delta)
	synergies.step(delta)
	if _frame % UnitData.FORMATION_TICK_DIVISOR == 0:
		_calculate_formation_anchors()
		colossi.refresh()  # Bone Colossus taunters (4 Hz).
	# Offset by half a period so threat checks never share a tick with the
	# formation update.
	if _frame % UnitData.THREAT_TICK_DIVISOR == (UnitData.THREAT_TICK_DIVISOR >> 1):
		_evaluate_player_threats()
	var slot := _frame % UnitData.AI_TICK_DIVISOR
	# Safe to iterate directly: units only die from enemy / projectile / boss
	# damage, which never runs inside this loop.
	for u in units:
		if u.charmed:
			continue  # Act VI: parked by Temptation (its hostile body fights instead).
		if u.think_slot == slot:
			u.think()
		u.physics_step(delta)


# =====================================================================================
# Levels, capacity and effective stats
# =====================================================================================

## Sets the summon ability level of `cls` (1..5) and queues the extra units
## the new capacity allows ("Buy Warrior -> exactly two spawn", GDD §40).
func set_class_level(cls: String, level: int) -> void:
	var old_cap := capacity(cls)
	# Commander's Presence (Ossuary): a new class raises every class's damage, so
	# all of them are recomputed (capacities taken before the change).
	var presence_caps: Dictionary = capacity_snapshot() if int(class_levels[cls]) <= 0 and level > 0 and game.meta.value("presence_damage") > 0.0 else {}
	class_levels[cls] = level
	if level > 0:
		if game.records_here():
			game.codex.meet(CodexData.SUMMON, cls)  # Codex: a summon class raised (records only).
			Meta.record_class_level(cls, level)  # Ossuary Masteries: Lv 5 opens that class's mastery (Meta [class_lv5]).
	if not presence_caps.is_empty():
		recompute_all(presence_caps)
	else:
		_refresh_class(cls, old_cap)
	synergies.evaluate()


## Class id -> current capacity. Take this snapshot BEFORE changing a passive
## and pass it to recompute_all() so only real capacity growth spawns units.
func capacity_snapshot() -> Dictionary:
	var caps := {}
	for cls: String in UnitData.CLASS_ORDER:
		caps[cls] = capacity(cls)
	return caps


## Recomputes every learned class after a passive changed. `old_caps` is the
## capacity_snapshot() taken before the change: only the capacity increase
## (new cap - old cap) spawns immediately; units that were already dead keep
## waiting for their normal replacement timer (GDD §24).
func recompute_all(old_caps: Dictionary) -> void:
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) > 0:
			_refresh_class(cls, int(old_caps.get(cls, capacity(cls))))


## Recomputes stats for `cls`, pushes them to living units (HP % preserved)
## and queues immediate spawns for the capacity gained since `old_cap`.
func _refresh_class(cls: String, old_cap: int) -> void:
	var level: int = class_levels[cls]
	if level <= 0:
		return
	var stats := compute_stats(cls, level)
	class_stats[cls] = stats
	for u in units:
		if u.unit_class == cls and not u.is_temporary:
			u.apply_stats(stats, true)
	var new_cap := capacity(cls)
	if new_cap > old_cap:
		immediate_spawns[cls] = int(immediate_spawns[cls]) + (new_cap - old_cap)
	summon_cap_changed.emit()


## Population cap for `cls`: ability level count + global bonuses (GDD §23
## "Army cap = sum of equipped summon abilities' class caps + global
## bonuses"). Pass `dominion_level` to preview another passive level.
func capacity(cls: String, dominion_level: int = -1) -> int:
	var level: int = class_levels[cls]
	if level <= 0:
		return 0
	var row := level_row(cls, level)
	return int(row["count"]) + bonus_capacity(cls, dominion_level)


## UnitData.LEVELS row of `cls` at skill `level`, clamped to the rows the
## class has (the Profane Bishop has a single row).
func level_row(cls: String, level: int) -> Dictionary:
	var rows: Array = UnitData.LEVELS[cls]
	return rows[clampi(level, 1, rows.size()) - 1]


## Global capacity bonus of `cls` on top of its level count: Grave Dominion
## (optionally previewed at `dominion_level`) plus meta upgrades, times the
## class's capacity_bonus_mult (UnitData; rounded down, 1 for the GDD classes).
func bonus_capacity(cls: String, dominion_level: int = -1) -> int:
	var cap := game.meta.capacity_bonus(cls)
	var dl := dominion_level if dominion_level >= 0 else game.abilities.passive_level("grave_dominion")
	if dl > 0:
		cap += int(PassiveData.PASSIVES["grave_dominion"]["levels"][dl - 1]["capacity_per_class"])
	var share := float(UnitData.UNITS[cls].get("capacity_bonus_mult", 1.0))  # Share of global bonuses.
	return cap if share >= 1.0 else floori(float(cap) * share + 0.001)


## Total army capacity across all classes (optionally previewing a different
## Grave Dominion level).
func total_capacity(dominion_level: int = -1) -> int:
	var total := 0
	for cls: String in UnitData.CLASS_ORDER:
		total += capacity(cls, dominion_level)
	return total


## Seconds between replacements for `cls` (GDD §24 base x Soul Recycling x
## meta Grave Call x the Charnel Menagerie synergy for the newer classes,
## SynergyManager.replenish_mult(); 1 while inactive).
func replenish_interval(cls: String) -> float:
	var base: float = UnitData.UNITS[cls]["replenish_interval"]
	return base * (1.0 - game.abilities.passive_value("soul_recycling", "replace_reduction")) \
			* (1.0 - game.meta.value("replace_reduction")) * synergies.replenish_mult(cls)


## Effective stats of class `cls` at skill `level` with the CURRENT passives
## and synergies. Stacking (GDD §34): like-category bonuses add, categories
## multiply: stat = base * (1 + skill_bonus) * (1 + passive_bonus) *
## (1 + synergy_bonus) * (1 + meta_bonus). Attack interval divides by the
## attack-speed multipliers. The Dark Frenzy power-up is one more category
## (x (1 + frenzy) on damage and attack speed) while `with_buffs` is true;
## level-up card previews pass false so they show the lasting stats. The
## Dread Rally ultimate (game.dread_rally) is another such timed category:
## damage and attack speed during its buff, move speed during its surge.
## Blood Scent adds a move-speed and an attack-speed category for the fast
## classes (PassiveData.FAST_SUMMON_SPEED). The Baying of the Damned frenzy
## (SynergyManager.frenzy_value(), timed like the Dread Rally, only with
## `with_buffs`) adds one more attack- and move-speed category to its class.
## Bound Souls adds the move-speed category and sets the per-unit leash keys
## (engage_radius, soft_recall: the army stance's leash x (1 + leash_range);
## Escort's leash is UnitData's) and the RETURNING speed (return_speed_mult).
## The army stance (ArmyStance) also scales w_formation and, only while
## StanceData.BONUSES_ENABLED, adds its flavour bonus as one more category
## (attack speed; block mass / bash knockback of the "front" classes).
## SummonEvolutions.modify_stats() then applies the summon-evolution passives
## (Forbidden Knowledge, Dark Benediction: own categories) and, while
## `with_evolution` is true, the class's evolution overlay (Death Knight /
## Lich); temporary summons pass false and keep the base class.
func compute_stats(cls: String, level: int, with_buffs: bool = true, with_evolution: bool = true) -> Dictionary:
	var base: Dictionary = UnitData.UNITS[cls]
	var row := level_row(cls, level)
	var ab := game.abilities
	var hp_mult := (1.0 + float(row.get("hp_bonus", 0.0))) * (1.0 + ab.passive_value("necrotic_vigor", "minion_hp")) \
			* (1.0 + game.meta.value("minion_hp"))
	var dmg_mult := (1.0 + float(row.get("damage_bonus", 0.0))) * (1.0 + ab.passive_value("dark_command", "minion_damage")) \
			* (1.0 + game.meta.value("minion_damage"))
	# Commander's Presence (Ossuary expansion step 3): its own category, per distinct
	# summon class owned (exactly 1 without the upgrade).
	var presence := game.meta.value("presence_damage")  # Minion damage per class (0 = not owned).
	if presence > 0.0:
		dmg_mult *= 1.0 + presence * float(distinct_classes())
	var spd_mult := (1.0 + float(row.get("speed_bonus", 0.0))) * (1.0 + ab.passive_value("dark_command", "minion_speed")) \
			* (1.0 + synergies.value("unholy_host", "attack_speed"))
	# Ossuary Mastery of this class (MasteryData; an evolved form is its base class):
	# its own category on HP and damage, exactly 1 while the class has none.
	hp_mult *= 1.0 + game.meta.mastery_value(cls, "hp")
	dmg_mult *= 1.0 + game.meta.mastery_value(cls, "damage")
	# Run modifiers (Vengeful Dead, DifficultyModifiers): own category, 1 when off.
	hp_mult *= game.difficulty.minion_hp_mult()
	dmg_mult *= game.difficulty.minion_damage_mult()
	# Army formation (ArmyStance, always the Bone Ring): leash, soft recall and
	# formation pull overrides (UnitData's numbers outside a run) and its flavour
	# bonuses (0 while off).
	var st := game.stance  # Current army stance (null only outside a run).
	var engage := st.engage_radius() if st != null else UnitData.ENGAGE_RADIUS  # Chase leash before Bound Souls (px).
	var recall := st.soft_recall() if st != null else UnitData.SOFT_RECALL  # Soft recall before Bound Souls (px).
	var pull := st.formation_pull() if st != null else 1.0  # Formation pull multiplier.
	var stance_speed := st.bonus("attack_speed") if st != null else 0.0  # Formation attack-speed bonus (the ring has none: 0).
	if stance_speed != 0.0:
		spd_mult *= 1.0 + stance_speed
	var push := 1.0  # Block mass / bash knockback multiplier of a "front" class (formation bonus; the ring has none).
	if st != null and StanceFormations.role(cls) == "front":
		push += st.bonus("front_push")
	if with_buffs and game.powerups != null:
		dmg_mult *= 1.0 + game.powerups.frenzy_bonus("damage_bonus")
		spd_mult *= 1.0 + game.powerups.frenzy_bonus("attack_speed_bonus")
	# Dread Rally (the ultimate, DreadRally.bonus): its own timed category on
	# damage and attack speed while the buff runs, and on move speed (below)
	# during its surge.
	var rally: DreadRally = game.dread_rally if with_buffs else null  # Null in card previews / before setup.
	if rally != null:
		dmg_mult *= 1.0 + rally.bonus("damage")
		spd_mult *= 1.0 + rally.bonus("attack_speed")
	# Bound Souls (later horde passive): move speed is its own category; the
	# leash scales the engagement radius and soft recall, and the return trip
	# takes (1 - return_reduction) of the time (RETURNING speed divided by it).
	var move_mult := (1.0 + synergies.value("deathless", "move_speed")) * (1.0 + ab.passive_value("bound_souls", "minion_move_speed"))
	# Blood Scent (paired with the Bone Hounds): the fast classes (base move
	# speed >= PassiveData.FAST_SUMMON_SPEED) move and attack faster, each its
	# own category.
	if float(base["move_speed"]) >= PassiveData.FAST_SUMMON_SPEED:
		move_mult *= 1.0 + ab.passive_value("blood_scent", "fast_move_speed")
		spd_mult *= 1.0 + ab.passive_value("blood_scent", "fast_attack_speed")
	# Overclock (Act III, paired with the Grave Drone): the ranged classes
	# (base attack range >= PassiveData.OVERCLOCK_MIN_RANGE) attack faster, its
	# own category (exactly 1 while it is not owned, so every other run is unchanged).
	if float(base["attack_range"]) >= PassiveData.OVERCLOCK_MIN_RANGE:
		var oc := ab.passive_value("overclock", "ranged_attack_speed")  # 0 when not owned.
		if oc > 0.0:
			spd_mult *= 1.0 + oc
	if rally != null:
		move_mult *= 1.0 + rally.bonus("move_speed")  # Dread Rally surge.
	# Baying of the Damned (synergy): the hounds' timed frenzy after a Dirge,
	# its own category on attack and move speed (0 unless it runs).
	if with_buffs:
		var fr_spd := synergies.frenzy_value(cls, "attack_speed")  # Frenzy attack-speed bonus.
		if fr_spd > 0.0:
			spd_mult *= 1.0 + fr_spd
			move_mult *= 1.0 + synergies.frenzy_value(cls, "move_speed")
	var leash_mult := 1.0 + ab.passive_value("bound_souls", "leash_range")  # Leash distance multiplier.
	var return_mult := 1.0 / maxf(0.1, 1.0 - ab.passive_value("bound_souls", "return_reduction"))  # RETURNING speed multiplier (the 0.1 floor only guards a 100% value).
	# Content wave 2 (UnitData "rejoin_speed_mult", the Bone Golem; 1 for every
	# other class): a slow anchor lumbers faster only to rejoin its post.
	var rejoin := float(base.get("rejoin_speed_mult", 1.0))  # Catch-up / return speed factor.
	var heal_mult := 1.0 + float(row.get("heal_bonus", 0.0))
	var splash_mult := 1.0 + float(row.get("splash_bonus", 0.0))
	var shield_mult := 1.0 + float(row.get("shield_bonus", 0.0))
	var out := {
		"count": int(row["count"]),
		"max_hp": float(base["max_hp"]) * hp_mult,
		"damage": float(base["damage"]) * dmg_mult,
		"attack_interval": float(base["attack_interval"]) / spd_mult,
		"attack_range": float(base["attack_range"]),
		"acquisition_range": float(base["acquisition_range"]),
		"move_speed": float(base["move_speed"]) * move_mult,
		"engage_radius": engage * leash_mult,
		"soft_recall": recall * leash_mult,
		"return_speed_mult": UnitData.RETURN_SPEED_MULT * return_mult * rejoin,
		"catchup_mult": UnitData.CATCHUP_SPEED_MULT * rejoin,
		"radius": float(base["radius"]),
		"band_min": float(base["band_min"]) * UnitData.FORMATION_SPREAD,
		"band_max": float(base["band_max"]) * UnitData.FORMATION_SPREAD,
		"w_pursuit": float(base["w_pursuit"]),
		"w_formation": float(base["w_formation"]) * pull,
		"w_separation": float(base["w_separation"]),
		"w_threat": float(base["w_threat"]),
		"windup": float(base["windup"]),
		"projectile_speed": float(base["projectile_speed"]),
		"splash_radius": float(base["splash_radius"]) * splash_mult,
		"heal_amount": float(base["heal_amount"]) * heal_mult,
		"kite_distance": float(base["kite_distance"]),
		"pierce": int(row.get("pierce", 0)),
		"block_radius": float(base.get("block_radius", 0.0)),
		"block_mass": float(base.get("block_mass", 0.0)) * push,
		"engaged_speed_mult": float(base.get("engaged_speed_mult", 1.0)),
		"bash_damage": float(base.get("bash_damage", 0.0)) * dmg_mult,
		"bash_cooldown": float(base.get("bash_cooldown", 0.0)),
		"bash_knockback": float(base.get("bash_knockback", 0.0)) * push,
		"shield_amount": float(base.get("shield_amount", 0.0)) * shield_mult,
		"shield_duration": float(base.get("shield_duration", 0.0)),
		"shield_cooldown": float(base.get("shield_cooldown", 0.0)),
		"heal_role_priority": float(base["heal_role_priority"]),
		"attack_profile": String(base["attack_profile"]),
		"target_profile": String(base["target_profile"]),
		# Support / evolution keys (optional in UnitData rows; 0 = none).
		"ally_shield_amount": float(base.get("ally_shield_amount", 0.0)) * shield_mult,
		"ally_shield_cooldown": float(base.get("ally_shield_cooldown", 0.0)),
		"aura_interval": float(base.get("aura_interval", 0.0)),
		"aura_radius": float(base.get("aura_radius", 0.0)),
		"aura_heal": float(base.get("aura_heal", 0.0)) * heal_mult,
		"aura_damage": float(base.get("aura_damage", 0.0)) * dmg_mult,
		"cleave_radius": 0.0,
		"cleave_fraction": 0.0,
		"lifesteal": 0.0,
		"evolution": "",
		# Class special numbers (later classes; empty for the others).
		"special": _special_stats(base, row, dmg_mult),
	}
	evolutions.modify_stats(cls, out, with_evolution)
	# Grave Masonry (content wave 2): its blockers hold longer, after the
	# evolution overlay (a Death Knight / Bone Colossus / Ossuary Titan sets its
	# own block mass first). 0 when not owned, so every other run is unchanged.
	var hold := ab.passive_value("grave_masonry", "hold_bonus") if cls in PassiveData.MASONRY_CLASSES else 0.0  # Hold bonus fraction.
	if hold > 0.0:
		out["block_mass"] = float(out["block_mass"]) * (1.0 + hold)
		var sp: Dictionary = out["special"]  # This class's special numbers (fresh per call).
		if sp.has("bulwark_duration"):
			sp["bulwark_duration"] = float(sp["bulwark_duration"]) * (1.0 + hold)
	# Recoil Frame (Act III, the Iron Citadel): the ranged summons fire faster and
	# farther, after the evolution overlay. 0 when not owned (every run unchanged).
	if String(out["attack_profile"]) in PassiveData.RECOIL_PROFILES:
		var haste := ab.passive_value("recoil_frame", "ranged_haste")  # Attack-speed fraction.
		if haste > 0.0:
			out["attack_interval"] = float(out["attack_interval"]) / (1.0 + haste)
			out["attack_range"] = float(out["attack_range"]) * (1.0 + ab.passive_value("recoil_frame", "ranged_reach"))
	# --- Act IV: the Asphodel Underworld --- Myrmidon Oath: the front-line
	# classes (PassiveData.OATH_CLASSES) gain max HP and damage, its own
	# category. 0 when not owned, so every other run is unchanged.
	if cls in PassiveData.OATH_CLASSES:
		var oath_hp := ab.passive_value("myrmidon_oath", "front_hp")  # Max HP fraction.
		if oath_hp > 0.0:
			out["max_hp"] = float(out["max_hp"]) * (1.0 + oath_hp)
			out["damage"] = float(out["damage"]) * (1.0 + ab.passive_value("myrmidon_oath", "front_damage"))
	return out


## Pushes the current army stance's numbers to every unit (ArmyStance
## changed): learned classes get fresh effective stats through the usual
## refresh (HP % kept, no capacity change); temporary summons keep their
## spawn-time multipliers and only take the stance keys (leash, soft
## recall, formation pull). Anchors are re-placed at once.
func apply_stance() -> void:
	recompute_all(capacity_snapshot())
	for u in units:
		if u.is_temporary:
			var fresh := compute_stats(u.unit_class, maxi(1, int(class_levels[u.unit_class])), true, false)  # Stance keys source.
			u.engage_radius = float(fresh["engage_radius"])
			u.soft_recall = float(fresh["soft_recall"])
			u.w_formation = float(fresh["w_formation"])
	_calculate_formation_anchors()


## Effective numbers of a class special (UnitData "special" dictionary;
## empty for classes without one), scaled by key suffix: *_damage by the same
## damage multiplier as attacks (`dmg_mult`: skill level x Dark Command x meta
## x Dark Frenzy) and the level row's special_bonus; *_radius / *_length by
## special_area; *_cooldown divided by (1 + special_haste); *_duration by
## special_duration. Attack-speed bonuses do not shorten special cooldowns.
## Fallen Grace (Act II passive, paired with the Fallen Seraph) divides every
## *_cooldown again by (1 + its special_haste): its own category (exactly 1
## while it is not owned, so every other run is unchanged).
func _special_stats(base: Dictionary, row: Dictionary, dmg_mult: float) -> Dictionary:
	var out := {}  # Effective special numbers.
	var src: Dictionary = base.get("special", {})  # Base special numbers.
	var dmg := dmg_mult * (1.0 + float(row.get("special_bonus", 0.0)))  # Special damage multiplier.
	var area := 1.0 + float(row.get("special_area", 0.0))  # Radius / length multiplier.
	var haste := 1.0 + float(row.get("special_haste", 0.0))  # Cooldown divisor.
	haste *= 1.0 + game.abilities.passive_value("fallen_grace", "special_haste")  # Fallen Grace (0 when not owned).
	var dur := 1.0 + float(row.get("special_duration", 0.0))  # Status duration multiplier.
	for key: String in src:
		var v := float(src[key])  # Base value of this key.
		if key.ends_with("_damage"):
			v *= dmg
		elif key.ends_with("_radius") or key.ends_with("_length"):
			v *= area
		elif key.ends_with("_cooldown"):
			v /= haste
		elif key.ends_with("_duration"):
			v *= dur
		out[key] = v
	return out


# =====================================================================================
# Replenishment (GDD §24 / §39 REPLENISHMENT)
# =====================================================================================

## Each summon ability runs its own queue: missing units come back one at a
## time per interval; capacity increases spawn immediately. A failed spawn
## does not consume the timer (GDD §24 "Failed spawns retry"). While every
## missing unit of a class is held by a holy suppression zone, that class's
## timer pauses (SuppressionField.holds_class()).
func _update_replenishment(delta: float) -> void:
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) <= 0:
			continue
		var cap := capacity(cls)
		var count: int = class_counts[cls]
		if count >= cap:
			replenish_timer[cls] = 0.0
			immediate_spawns[cls] = 0
			continue
		if int(immediate_spawns[cls]) > 0:
			if _try_spawn(cls):
				immediate_spawns[cls] = int(immediate_spawns[cls]) - 1
			continue
		if suppression.holds_class(cls, count, cap):
			game.stat_add("suppression_paused_seconds", delta)
			continue
		replenish_timer[cls] = float(replenish_timer[cls]) + delta
		if float(replenish_timer[cls]) >= replenish_interval(cls):
			if _try_spawn(cls):
				replenish_timer[cls] = 0.0
				game.stat_add("replacements", 1.0)
				_bone_reserve(units[units.size() - 1])


## Bone Reserve (Ossuary expansion step 3, MetaModifiers "reserve_barrier"): a
## summon replaced after falling (the replacement timer above) rises with a barrier
## of that share of its max HP (SummonedUnit.barrier_hp, absorbed before HP like
## the Shieldwall's). No-op without the upgrade.
func _bone_reserve(u: SummonedUnit) -> void:
	var share := game.meta.value("reserve_barrier")  # Barrier share of max HP (0 = not owned).
	if share <= 0.0:
		return
	var amount := u.max_hp * share  # Barrier HP.
	if amount > u.barrier_hp:
		game.stat_add("bone_reserve_barrier", amount - u.barrier_hp)
		u.barrier_hp = amount
		u.queue_redraw()


## Number of summon classes owned (level 1+): Commander's Presence.
func distinct_classes() -> int:
	var n := 0
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) > 0:
			n += 1
	return n


## Number of missing units across all owned classes (capacity - alive).
func missing_count() -> int:
	var n := 0
	for cls: String in UnitData.CLASS_ORDER:
		n += maxi(0, capacity(cls) - int(class_counts[cls]))
	return n


## "Call of the Grave" fallback card: every missing unit is queued for an
## immediate spawn instead of waiting for its replacement timer.
func raise_all_missing() -> void:
	for cls: String in UnitData.CLASS_ORDER:
		if int(class_levels[cls]) > 0:
			immediate_spawns[cls] = maxi(int(immediate_spawns[cls]), capacity(cls) - int(class_counts[cls]))


## Fraction 0..1 of the current replacement timer for HUD display.
func replenish_progress(cls: String) -> float:
	if int(class_counts[cls]) >= capacity(cls):
		return 1.0
	return clampf(float(replenish_timer[cls]) / replenish_interval(cls), 0.0, 1.0)


## Tries to spawn one unit of `cls` 35–80 px from the player, not inside an
## enemy body. Returns false (retry next frame) if no spot was found.
func _try_spawn(cls: String) -> bool:
	var stats: Dictionary = class_stats[cls]
	var r: float = stats["radius"]
	for _attempt in UnitData.SPAWN_RETRIES:
		var pos := game.player.position + Vector2.from_angle(randf() * TAU) * randf_range(UnitData.SPAWN_MIN, UnitData.SPAWN_MAX)
		# Never inside an enemy, an obstacle, a holy zone or a suppression
		# zone (holy ground suppresses replacement locally, GDD §10).
		if _blocked_by_enemy(pos, r) or game.arena.is_blocked(pos, r) or game.enemies.stage.in_holy_zone(pos) or suppression.blocks(pos):
			continue
		var u: SummonedUnit
		if _pool.is_empty():
			u = SummonedUnit.new()
			add_child(u)
			created_nodes += 1
		else:
			u = _pool.pop_back()
		u.activate(self, game, cls, stats, pos, _next_slot)
		block_query_radius = maxf(block_query_radius, u.block_radius)
		_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
		units.append(u)
		class_counts[cls] = int(class_counts[cls]) + 1
		total_spawned += 1
		game.effects.spawn_ring(pos, Palette.NECRO_GREEN, "summon_rise")  # Animation when its art exists (visual only).
		summon_created.emit(u)
		summon_count_changed.emit()
		return true
	return false


## Spawns a temporary summon of `cls` near `pos` for `duration` seconds,
## using the class's current effective stats (level 1 if not learned) times
## `hp_mult` / `dmg_mult`. It runs the shared AI but is not counted in
## class_counts (caps, HUD) and is never replaced. It always keeps the base
## class look and kit (no summon-evolution overlay).
## Restless Dead (passive, the one path for every temporary summon: Death
## Mark Risen, Raise Dead skeletons, Lich raises, stage reinforcements)
## lengthens `duration` by temp_duration and raises `dmg_mult` by
## temp_damage (its own stacking category). The Grave Herald's Restless
## innate (CharacterData temp_summon_duration; 0 for every other character)
## lengthens `duration` as a separate category, so the two multiply:
## duration x (1 + temp_duration) x (1 + temp_summon_duration).
## Strings of the Dead (Act III) adds temp_hp to its HP and its taunt_reach as
## a taunt (ColossusKit), here too.
func spawn_temporary(cls: String, pos: Vector2, duration: float, hp_mult: float, dmg_mult: float) -> SummonedUnit:
	duration *= 1.0 + game.abilities.passive_value("restless_dead", "temp_duration")
	var herald := duration * game.character.innate_value("temp_summon_duration")  # Restless extra seconds (0 unless the Grave Herald).
	duration += herald
	dmg_mult *= 1.0 + game.abilities.passive_value("restless_dead", "temp_damage")
	# Strings of the Dead (Act III passive, paired with Hollow Puppet): every
	# temporary summon rises sturdier (its own category) and draws the foes
	# around it (a taunt reach on its special, read by ColossusKit.refresh()).
	# Both 0 while it is not owned, so every other run is unchanged.
	var strings_hp := game.abilities.passive_value("strings_of_the_dead", "temp_hp")  # HP fraction (0 when not owned).
	var strings_reach := game.abilities.passive_value("strings_of_the_dead", "taunt_reach")  # Taunt reach (px; 0 when not owned).
	hp_mult *= 1.0 + strings_hp
	var stats := compute_stats(cls, maxi(1, int(class_levels[cls])), true, false)
	if strings_reach > 0.0:
		var sp: Dictionary = stats["special"]  # This call's own special numbers (fresh per compute_stats()).
		sp["taunt_radius"] = maxf(float(sp.get("taunt_radius", 0.0)), strings_reach)
	stats["max_hp"] = float(stats["max_hp"]) * hp_mult
	stats["damage"] = float(stats["damage"]) * dmg_mult
	stats["bash_damage"] = float(stats["bash_damage"]) * dmg_mult
	var at := game.arena.free_point(pos, float(stats["radius"]))
	var u: SummonedUnit
	if _pool.is_empty():
		u = SummonedUnit.new()
		add_child(u)
		created_nodes += 1
	else:
		u = _pool.pop_back()
	u.activate(self, game, cls, stats, at, _next_slot)
	block_query_radius = maxf(block_query_radius, u.block_radius)
	u.is_temporary = true
	u.temp_life = duration
	_next_slot = (_next_slot + 1) % UnitData.AI_TICK_DIVISOR
	units.append(u)
	temp_alive += 1
	temp_spawned += 1
	if herald > 0.0:
		game.stat_add("restless_extra_seconds", herald)  # Grave Herald innate (autotest).
	game.innates.on_temporary_spawned(u)  # Act III: the Rust Prophet's scrap bolts (no-op for every other character).
	game.effects.spawn_ring(at, Palette.NECRO_GREEN, "summon_rise")  # Animation when its art exists (visual only).
	return u


## Raises a fallen enemy's corpse as a temporary Risen: THE one path of every
## effect that raises a slain foe (Death Mark's Risen, the Lich's raise, Grave
## Tide, Call of the Drowned's Thralls), always through spawn_temporary(), so
## Restless Dead and the Grave Herald's Restless apply. It rises as class `cls`
## at `pos` for `duration` s with `hp_mult` / `dmg_mult`, tagged `tag`
## (SummonedUnit.dmg_source) and drawn as `glyph` (glyph_kind). Act III, Steel
## has no soul (EmpireRulesData.STEEL): when `gunner` is true (the foe was a
## cyborg, Enemy.rises_as_gunner()) it rises instead as a GRAVE GUNNER: the
## ranged class STEEL.class keeping its rifle's reach (attack range x
## STEEL.range_mult), firing for you as STEEL.tag; counted in
## steel_gunners_raised and steel_gunners_from_<tag>. A machine never gets here
## (Enemy.leaves_corpse() gates every caller). `gunner` is false on Acts I and
## II, where this is exactly spawn_temporary() plus the two tags.
func raise_corpse(cls: String, pos: Vector2, duration: float, hp_mult: float, dmg_mult: float,
		tag: String, glyph: String, gunner: bool) -> SummonedUnit:
	var steel := EmpireRulesData.STEEL  # Grave Gunner rules.
	var u := spawn_temporary(String(steel["class"]) if gunner else cls, pos, duration, hp_mult, dmg_mult)
	if gunner:
		u.attack_range *= float(steel["range_mult"])
		u.dmg_source = String(steel["tag"])
		u.glyph_kind = String(steel["glyph"])
		game.stat_add("steel_gunners_raised", 1.0)
		game.stat_add("steel_gunners_from_" + tag, 1.0)
	else:
		u.dmg_source = tag
		u.glyph_kind = glyph
	u.queue_redraw()
	return u


## Ages temporary summons and crumbles the expired ones (outside the unit
## loop, which must not see the array change).
func _update_temporaries(delta: float) -> void:
	var i := units.size() - 1
	while i >= 0:
		var u := units[i]
		if u.is_temporary:
			u.temp_life -= delta
			if u.temp_life < 5.0:
				u.queue_redraw()  # aura dims as it expires
			if u.temp_life <= 0.0:
				game.stat_add("temporary_expired", 1.0)
				on_unit_died(u)
		i -= 1


## True if `pos` overlaps a living enemy body.
func _blocked_by_enemy(pos: Vector2, r: float) -> bool:
	game.enemy_grid.query(pos, r + 30.0, _tmp)
	for e: Enemy in _tmp:
		if e.active and e.position.distance_to(pos) < e.radius + r:
			return true
	return false


## Death handling (GDD §24): stop AI, deregister, release reservations, play
## FX, pool the node; the class queue then replaces it after its interval.
## `as_death` false removes the unit without counting a death or emitting
## summon_died (units dissolved by the Mender + Warder merge). A real death
## is reported to the character innates first (CharacterInnates
## .on_summon_died, the Carrion Lord's summon corpses).
func on_unit_died(u: SummonedUnit, as_death: bool = true) -> void:
	if not u.active:
		return
	var idx := units.find(u)
	if idx >= 0:
		units[idx] = units[units.size() - 1]
		units.pop_back()
	if as_death:
		game.innates.on_summon_died(u)  # Carrion Lord corpses (no-op without the innate).
		claim_fallen(u)  # Act II: the Ancient Eye may claim it (no-op elsewhere).
		if golems != null:
			golems.on_summon_died(u)  # Content wave 2: Ossuary Hunger / a Titan's wall (no-op without a Golem).
	if u.is_temporary:
		temp_alive -= 1
		AbyssalPact.on_temporary_gone(game, u)  # Act II: the Abyssal Pact's soul burst (no-op unless owned).
	else:
		class_counts[u.unit_class] = maxi(0, int(class_counts[u.unit_class]) - 1)
		if as_death:
			total_deaths += 1
			suppression.on_unit_died(u)  # Held if it fell inside a suppression zone.
	game.effects.pop(u.position, Palette.COLD_BLUE, u.radius * 1.2, "undead_death")  # Animation when its art exists (visual only).
	if as_death:
		game.motion.on_summon_died(u)  # Collapses into bone dust (visual only).
	u.deactivate()
	_pool.append(u)
	if as_death:
		summon_died.emit(u)
	summon_count_changed.emit()


## Act II Claims (EyeClaims, GDD §15.0 "Act II: the Ancient Eye"): the ONE path
## through which a fallen summon can be claimed and rise as a hostile Drowned
## Thrall. Does nothing on a stage without claims (game.claims null). Returns
## true when `u` was claimed.
func claim_fallen(u: SummonedUnit) -> bool:
	return game.claims != null and game.claims.claim_fallen(u)


# --- Act VI: the Inferno ---
## TEMPTATION (Act VI, GDD §15.0 "Temptation"): THE one path that charms a
## summon. `unit` (a summon of this army) is parked and a hostile body wearing
## its look fights for hell for `duration` s (x Faithless), then the summon
## comes back with the body's share of HP; breaking the body frees it at once
## (weakened), killing the charmer `by` (an Enemy, or null for a boss effect that names no
## charmer) breaks its charms at once (break_charms()). At most
## InfernoRulesData.TEMPTATION max_charmed at once across every army. `opts`
## (all optional) for phase 2: "tint" (Color of the body), "name" (its display
## name), "source" (stats tag; default the charmer's kind), "ignore_cap"
## (bool; Moloch's swallow), "no_temporary" (bool: refuse temporary summons). Creates the Inferno's rules on first use (an
## Inferno kind forced onto another stage). Returns true when it took hold.
func charm(unit: SummonedUnit, by: Enemy, duration: float, opts: Dictionary = {}) -> bool:
	if unit == null or unit.director != self:
		return unit != null and unit.director != null and unit.director.charm(unit, by, duration, opts)  # Co-op: the summon's own army.
	return game.inferno_rules().temptation.charm(unit, by, duration, opts)


## Act VI, the Palace of Silk and Ash: THE ONE PATH that turns foe `e` to this
## army's side for `duration` s (Enthrall.turn(); opts there): the Temptation
## spell (TemptSpell) and the Succubus class (BoundSuccubusBehavior). The
## player's own charm, a spell's effect on an ENEMY: the summon charm path above
## is never used. Returns the thrall, or null when refused.
func enthrall_foe(e: Enemy, duration: float, opts: Dictionary) -> SummonedUnit:
	if enthrall == null:
		enthrall = Enthrall.new(game, self)
	return enthrall.turn(e, duration, opts)


## TEMPTATION: breaks every charm charmer `by` holds (its summons come back at
## once). Called by InfernoKit.on_killed() when a charmer dies; a no-op off
## Act VI (no Inferno rules). Returns the summons freed.
func break_charms(by: Enemy) -> int:
	if game.inferno == null or by == null:
		return 0
	return game.inferno.temptation.break_by(by)


## Number of living units of `cls`.
func count_of(cls: String) -> int:
	return class_counts[cls]


# =====================================================================================
# Formation (GDD §26) and threat evaluation (GDD §32)
# =====================================================================================

## Assigns each unit a player-relative anchor inside its class band.
## Warriors spread in an arc facing the threat (or a full ring when calm);
## archers + mages share the midline ring; the support classes (Mender,
## Warder, Profane Bishop) sit on the side away from the threat, and the
## "back" classes (Corpse Catapults) in their own farther band behind them. Stable per-unit jitter keeps it from looking geometric.
## In a run the Bone Ring places every post instead (StanceFormations); this banded
## layout is the fallback when no formation exists.
func _calculate_formation_anchors() -> void:
	if game.stance != null:
		# The Bone Ring (the only formation; StanceFormations). The banded layout below
		# is only the fallback outside a run.
		StanceFormations.assign(self, game.stance.shape(), game.stance.jitter())
		return
	var warriors: Array[SummonedUnit] = []
	var midline: Array[SummonedUnit] = []
	var support: Array[SummonedUnit] = []
	var rear: Array[SummonedUnit] = []  # UnitData formation "back" (Corpse Catapults).
	for u in units:
		match u.unit_class:
			"warrior":
				warriors.append(u)
			"mender", "warder", "bishop":
				support.append(u)
			_:
				# Later classes pick their band group in data (UnitData "formation").
				match String(UnitData.UNITS[u.unit_class].get("formation", "mid")):
					"front":
						warriors.append(u)
					"back":
						rear.append(u)
					_:
						midline.append(u)
	var threat_angle := threat_dir.angle()
	var calm_rot := float(_frame) * 0.0005
	# Warriors: arc toward the threat, narrowing as pressure rises.
	var w_spread := lerpf(TAU, PI * 0.8, threat_level)
	_assign_arc(warriors, threat_angle if threat_level > 0.05 else calm_rot, w_spread if threat_level > 0.05 else TAU)
	# Midline: full ring, offset half a slot so it interleaves with warriors.
	_assign_arc(midline, threat_angle + PI / maxf(1.0, float(midline.size())), TAU)
	# Support: behind the army relative to the threat.
	if threat_level > 0.05:
		_assign_arc(support, threat_angle + PI, PI * 0.7)
	else:
		_assign_arc(support, calm_rot + PI * 0.5, TAU)
	# Rear (siege artillery, in its own farther band): behind the necromancer
	# relative to the threat, a little wider than the support arc; a full
	# ring when calm. Empty (no change) without a "back" class.
	if threat_level > 0.05:
		_assign_arc(rear, threat_angle + PI, PI * 0.9)
	else:
		_assign_arc(rear, calm_rot + PI * 1.5, TAU)


## Distributes `list` evenly over an arc of `spread` radians centred on
## `center_angle`, each unit at a stable radius inside its own band. Anchors
## that would fall inside an obstacle are moved out of it.
func _assign_arc(list: Array[SummonedUnit], center_angle: float, spread: float) -> void:
	var n := list.size()
	if n == 0:
		return
	var pp := game.player.position
	for i in n:
		var u := list[i]
		var t := (float(i) + 0.5) / float(n) - 0.5
		var angle := center_angle + t * spread + (u.slot_jitter - 0.5) * UnitData.FORMATION_JITTER_ANGLE
		var r := lerpf(u.band_min, u.band_max, 0.2 + 0.6 * u.band_jitter)
		u.anchor_offset = game.arena.free_point(pp + Vector2.from_angle(angle) * r, u.radius) - pp


## Summarises enemies near the player into a direction + pressure level and
## the "player in danger" flag used by warrior targeting.
func _evaluate_player_threats() -> void:
	var p := game.player.position
	game.enemy_grid.query(p, UnitData.THREAT_RADIUS, _tmp)
	var sum := Vector2.ZERO
	var weight := 0.0
	var close := 0
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var diff := e.position - p
		var d := diff.length()
		var w := 1.0 - d / UnitData.THREAT_RADIUS
		if d > 0.01:
			sum += diff / d * w
		weight += w
		if d <= UnitData.DANGER_RADIUS:
			close += 1
	if sum.length() > 0.01:
		threat_dir = sum.normalized()
	threat_level = clampf(weight / 6.0, 0.0, 1.0)
	player_in_danger = close >= UnitData.DANGER_COUNT or game.player.hp < game.player.max_hp * UnitData.DANGER_HP_FRACTION


## Number of living units in each FSM state (debug overlay).
func state_counts() -> Dictionary:
	var counts := {}
	for u in units:
		var key: String = SummonedUnit.State.keys()[u.state]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


# --- Act V: Castle Kurogane ---
## Banner of the Dead (the spell, every tick): this army's standing banners
## `zones` ((x, y, radius px) each) and their attack-speed share `haste`.
func set_banners(zones: PackedVector3Array, haste: float) -> void:
	banner_zones = zones
	banner_haste = haste


## THE one per-summon attack-speed read (SummonedUnit's attack timer runs this
## much faster): 1 + Banner of the Dead's haste when `u` stands inside one of
## this army's banners (the strongest, not added up) + Warlord's Seal's when it
## stands within BannerData.SEAL_RADIUS px of its necromancer. Exactly 1 when
## neither the spell nor the passive is owned (every older run unchanged). The
## same on every stage (no act-only rule).
func attack_haste(u: SummonedUnit) -> float:
	if banner_haste <= 0.0 and _seal_haste <= 0.0:
		return 1.0
	var h := 0.0  # Extra share.
	if banner_haste > 0.0:
		for z in banner_zones:
			if u.position.distance_squared_to(Vector2(z.x, z.y)) <= z.z * z.z:
				h += banner_haste
				break
	if _seal_haste > 0.0 and u.position.distance_squared_to(_seal_pos) <= BannerData.SEAL_RADIUS * BannerData.SEAL_RADIUS:
		h += _seal_haste
	return 1.0 + h

