## SummonedUnit — the ONE shared AI script for every undead summon class
## (Warrior, Archer, Mage, Mender, Warder, Profane Bishop, and the evolved
## Death Knight / Lich). GDD §36: "Share unit logic in a base
## scene/script and parameterize per-class behavior with data resources.
## Avoid four independent unrelated AI implementations."
## Class differences come only from the data row in UnitData (attack_profile,
## target_profile, ranges, steering weights, heal amount...). A class with a
## special action (Abomination stomp, Rogue dash, Gargoyle swoop, Frost Wraith
## Deep Freeze, Bone Hound Pack Hunt, Banshee Dirge, Corpse Catapult Bone
## Barrage) also gets a per-unit SummonBehavior (`behavior`), the one
## dispatch point for class-specific code: it may start a special in think(),
## own the tick in physics_step() while the unit is CASTING it, release a
## custom attack profile, scale a melee strike and react to it, add a
## target-score bonus and draw extras.
##
## Update model (GDD §25 / §39), both driven by HordeDirector:
##   think()        ~5 Hz, staggered across units: FSM decisions, leash checks,
##                  threat sampling, target / heal-target selection.
##   physics_step() 60 Hz: steering, attack timing, cast windups, animation.
##
## FSM (GDD §25): SPAWNING -> FOLLOWING -> ACQUIRING -> ENGAGING
##   <-> REPOSITIONING / RETREATING (kite) -> CASTING -> ...; RETURNING when
##   leashed; DEAD at 0 HP (HordeDirector pools the node).
##
## Units are pooled: `generation` increments on every activation so stale
## references held by enemies, projectiles or healers can be detected.
##
## Support and evolution kits are data too (zero = off) and run through small
## hooks into SummonAbilities: the instant ally barrier (Warder / Bishop), the
## aura pulse (Bishop) and the cleave + life drain after a melee hit (Death
## Knight). Statistics are tagged with `dmg_source` (class or evolution id).
class_name SummonedUnit
extends Node2D

## FSM states, names match GDD §25.
enum State { SPAWNING, FOLLOWING, ACQUIRING, ENGAGING, REPOSITIONING, CASTING, RETREATING, RETURNING, DEAD }

# --- Identity / lifecycle -----------------------------------------------------------

## Owning horde director.
var director: HordeDirector
## Owning run.
var game: Game
## Class id (UnitData.CLASS_ORDER): "warrior" | "archer" | "mage" | "mender" |
## "warder" | "bishop" | "abomination" | "rogue" | "gargoyle" | "frost_wraith" |
## "bone_hound" | "banshee" | "corpse_catapult".
var unit_class: String = ""
## True while alive in the world (false = pooled).
var active: bool = false
## Incremented on each activation; lets holders detect a recycled unit.
var generation: int = 0
## Current FSM state.
var state: State = State.DEAD
## Seconds spent in the current state.
var state_time: float = 0.0
## Stall check (UnitData.STALL_TIME): where the current no-progress window
## started (world px) ...
var _stall_pos: Vector2 = Vector2.ZERO
## ... and when (game s; -1 = no window, the unit is not trying to move).
var _stall_since: float = -1.0
## Which of the AI_TICK_DIVISOR physics ticks this unit thinks on (stagger).
var think_slot: int = 0

# --- Effective stats (pushed by HordeDirector after upgrades) ---------------------

## Maximum HP after skill + passive bonuses.
var max_hp: float = 1.0
## Current HP.
var hp: float = 1.0
## Damage per attack.
var damage: float = 0.0
## Seconds between attacks / heals.
var attack_interval: float = 1.0
## Preferred attack range in px (melee: edge-to-edge; ranged: centre-to-edge).
var attack_range: float = 20.0
## Target search radius in px.
var acquisition_range: float = 150.0
## Movement speed in px/s.
var move_speed: float = 80.0
## Engagement leash (px from the player): UnitData.ENGAGE_RADIUS, widened by
## Bound Souls. Targets beyond it are not chased.
var engage_radius: float = UnitData.ENGAGE_RADIUS
## Soft-recall distance (px from the player): UnitData.SOFT_RECALL, widened
## by Bound Souls. Beyond it the unit drops its target and RETURNs.
var soft_recall: float = UnitData.SOFT_RECALL
## Speed multiplier while RETURNING: UnitData.RETURN_SPEED_MULT, raised by
## Bound Souls (shorter return time).
var return_speed_mult: float = UnitData.RETURN_SPEED_MULT
## Body radius in px.
var radius: float = 10.0
## Inner edge of this class's formation band (px from player).
var band_min: float = 35.0
## Outer edge of this class's formation band (px from player).
var band_max: float = 85.0
## Steering weight toward the current target.
var w_pursuit: float = 1.0
## Steering weight toward the formation anchor.
var w_formation: float = 0.5
## Steering weight away from overlapping allies.
var w_separation: float = 0.8
## Steering weight away from nearby enemies.
var w_threat: float = 0.0
## Windup seconds between starting an attack and its effect.
var windup: float = 0.2
## Projectile speed in px/s (ranged profiles).
var projectile_speed: float = 0.0
## Mage explosion radius in px.
var splash_radius: float = 0.0
## HP restored per heal cast (priests).
var heal_amount: float = 0.0
## Archers kite away from enemies closer than this many px.
var kite_distance: float = 0.0
## Extra enemies an arrow can pass through.
var pierce: int = 0
## >0 makes this unit a physical blocker of this radius (warriors).
var block_radius: float = 0.0
## Blocker mass vs Enemy.mass (overlap correction split).
var block_mass: float = 0.0
## Speed multiplier applied to enemies touching this blocker.
var engaged_speed_mult: float = 1.0
## Shield-bash damage on contact.
var bash_damage: float = 0.0
## Seconds between shield bashes.
var bash_cooldown: float = 0.0
## Shield-bash knockback impulse in px/s (divided by enemy mass).
var bash_knockback: float = 0.0
## HP absorbed by a ward this unit casts on the necromancer (Warder, Bishop).
var shield_amount: float = 0.0
## Seconds a ward lasts.
var shield_duration: float = 0.0
## Seconds between wards from this unit.
var shield_cooldown: float = 0.0
## Healing role priority of THIS unit's class (0..1, GDD §31).
var heal_role_priority: float = 0.5
## Attack branch: "melee" | "arrow" | "aoe" | "heal" | "ward", or a
## class-specific profile released by the behaviour ("frost", "dirge",
## "boulder").
var attack_profile: String = "melee"
## Barrier HP this unit casts on a threatened ally (Warder / Bishop; 0 = none).
var ally_shield_amount: float = 0.0
## Seconds between ally barriers from this unit.
var ally_shield_cooldown: float = 0.0
## Seconds between aura pulses (Profane Bishop; 0 = no aura).
var aura_interval: float = 0.0
## Aura pulse radius in px.
var aura_radius: float = 0.0
## HP every ally (and the necromancer) inside the aura regains per pulse.
var aura_heal: float = 0.0
## Damage every enemy inside the aura takes per pulse.
var aura_damage: float = 0.0
## Death Knight cleave radius in px around the struck enemy (0 = no cleave).
var cleave_radius: float = 0.0
## Fraction of a melee hit dealt to the other enemies inside the cleave.
var cleave_fraction: float = 0.0
## Fraction of melee damage dealt that heals this unit (Death Knight drain).
var lifesteal: float = 0.0
## Summon evolution of this unit ("" = none, or a SummonEvolutionData
## "transform" id: "death_knight", "lich", "gravebow", "bone_colossus").
var evolution: String = ""
## Bullet heaven pass: attack releases since this unit's last volley (VolleyDirector).
var volley_count: int = 0
## Statistics tag of this unit's damage, heals and shields: the evolution id
## if evolved, else the class id ("lich_risen" for Lich-raised skeletons).
var dmg_source: String = ""
## Glyph drawn for this unit: the class id, the evolution id or "risen".
var glyph_kind: String = ""
## Target scoring profile key into UnitData.TARGET_WEIGHTS.
var target_profile: String = "guard"
## Effective numbers of the class special (HordeDirector._special_stats();
## empty for classes without one). Shared read-only with the director.
var special: Dictionary = {}
## Class special action (null for the GDD classes); reused while pooled.
var behavior: SummonBehavior = null
## True while flying (Gargoyle swoop): no obstacle collision, not in the ally
## grid (enemies cannot target or be blocked by it) and immune to damage.
var airborne: bool = false
## True while a Cathedral Horror stands as stone after a swoop
## (GargoyleBehavior): on the ground and body-blocking, but immune to damage
## (CombatResolver.damage_unit()).
var stone_form: bool = false
## Volleys this unit fired as a Gravebow (GravebowKit: every split_every-th
## splits); 0 on every activation.
var evo_volleys: int = 0

# Cached target weights (floats, faster than dictionary lookups in hot loops).
## Weight of normalised distance in target scoring.
var _wd: float = 1.0
## Weight of threat-to-player in target scoring.
var _wt: float = 1.0
## Weight of enemy role priority in target scoring.
var _wr: float = 0.0
## Weight of tactical value in target scoring.
var _wv: float = 0.0
## Weight of cluster value (mages) in target scoring.
var _wc: float = 0.0
## Weight of the overkill penalty in target scoring.
var _wo: float = 1.0

# --- Runtime AI state ---------------------------------------------------------------

## Current enemy target (null if none).
var target: Enemy = null
## Generation of `target` when it was chosen (stale-reference guard).
var target_gen: int = 0
## Seconds the current target (or heal target) has been held (commitment).
var target_hold: float = 0.0
## Priest heal target: a SummonedUnit or the Necromancer (null if none).
var heal_target: Node2D = null
## Generation of `heal_target` when chosen (0 for the player).
var heal_target_gen: int = 0
## Seconds until the next attack is allowed.
var attack_cd: float = 0.0
## Seconds left in the current cast / swing windup.
var cast_time: float = 0.0
## World position a mage explosion is aimed at (locked at cast start).
var cast_point: Vector2 = Vector2.ZERO
## Formation anchor relative to the player (assigned at 4 Hz by the director).
var anchor_offset: Vector2 = Vector2.ZERO
## Stable per-unit random 0..1 for angular slot offset.
var slot_jitter: float = 0.5
## Stable per-unit random 0..1 for position inside the band.
var band_jitter: float = 0.5
## Current velocity in px/s.
var velocity: Vector2 = Vector2.ZERO
## Remaining hit-flash time in seconds.
var flash: float = 0.0
## HP of heals already "in flight" toward this unit (priest reservations).
var incoming_heal: float = 0.0
## Shieldwall of the Damned barrier (GDD §6.3): absorbed before HP.
var barrier_hp: float = 0.0
## Heal amount this priest reserved on its target during the current cast.
var _reserved_heal: float = 0.0
## Unit or Necromancer holding this priest's heal reservation.
var _reserved_heal_on: Node2D = null
## Generation of `_reserved_heal_on` at reservation time.
var _reserved_heal_gen: int = 0
## Normalised direction away from nearby enemies (sampled in think()).
var _threat_away: Vector2 = Vector2.ZERO
## Edge distance in px to the closest enemy (sampled in think()).
var _threat_dist: float = INF
## Seconds until an archer may kite again.
var _kite_cd: float = 0.0
## Seconds until this warrior may shield-bash again.
var bash_cd: float = 0.0
## Seconds until this unit may ward the necromancer again.
var _shield_cd: float = 0.0
## Seconds until this unit may cast an ally barrier again.
var ally_shield_cd: float = 0.0
## Seconds until this unit's next aura pulse.
var aura_cd: float = 0.0
## Seconds since this unit last took a hit (ally-barrier threat check).
var since_hit: float = 99.0
## Seconds left of the summon-evolution transformation glow.
var transform_time: float = 0.0
## Facing sign (+1 right / -1 left).
var _facing: float = 1.0
## Reusable query buffer for target candidates.
var _cand: Array = []
## Reusable query buffer for neighbours (separation, clusters, threats).
var _neigh: Array = []
## Score of the best candidate found by the last acquisition.
var _best_score: float = 0.0
## Engine motion (UnitMotion: body / overlay layers, bob, lean, squashes,
## lunges, the rise); created on the first activation, purely visual.
var motion: UnitMotion = null

# --- Stage effects --------------------------------------------------------------------

## True for a temporary stage-event summon (empowered grave / crypt
## guardian): outside caps, never replaced, crumbles after temp_life.
var is_temporary: bool = false
## Seconds a temporary summon has left (HordeDirector ages it).
var temp_life: float = 0.0
## Fraction of speed lost while standing on holy ground.
var holy_slow: float = 0.0
## Seconds the holy-ground slow still applies (refreshed by StageDirector).
var holy_slow_timer: float = 0.0
## Act II, the Hollow Archive (the Librarian's beam, misdirect()): game time
## (s) until which this summon is TURNED AROUND: it walks along
## `misdirect_dir` and neither thinks nor fights (0 = never / expired).
var misdirect_until: float = 0.0
## Unit direction a turned-around summon walks in.
var misdirect_dir: Vector2 = Vector2.ZERO
## Fraction (0..1) of its move speed a turned-around summon walks at.
var misdirect_speed: float = 1.0


# =====================================================================================
# Lifecycle
# =====================================================================================

## Activates a pooled unit as class `cls` at `pos` with effective `stats`.
func activate(p_director: HordeDirector, p_game: Game, cls: String, stats: Dictionary, pos: Vector2, slot: int) -> void:
	director = p_director
	game = p_game
	unit_class = cls
	generation += 1
	active = true
	position = pos
	velocity = Vector2.ZERO
	_stall_since = -1.0  # No stall window carried over from the pooled unit's last life.
	volley_count = 0  # Bullet heaven pass: attack releases toward the next volley.
	max_hp = 0.0
	apply_stats(stats, false)
	hp = max_hp
	target = null
	heal_target = null
	incoming_heal = 0.0
	barrier_hp = 0.0
	_reserved_heal = 0.0
	_reserved_heal_on = null
	attack_cd = randf() * 0.5
	flash = 0.0
	_kite_cd = 0.0
	bash_cd = 0.0
	_shield_cd = 0.0
	ally_shield_cd = 0.0
	aura_cd = aura_interval
	since_hit = 99.0
	transform_time = 0.0
	_threat_away = Vector2.ZERO
	_threat_dist = INF
	is_temporary = false
	temp_life = 0.0
	holy_slow = 0.0
	holy_slow_timer = 0.0
	misdirect_until = 0.0
	slot_jitter = randf()
	band_jitter = randf()
	anchor_offset = pos - game.player.position
	think_slot = slot
	visible = true
	airborne = false
	stone_form = false
	self_modulate = Color.WHITE  # A pooled node may have been stone-tinted.
	evo_volleys = 0
	behavior = SummonBehaviors.for_unit(behavior, String(UnitData.UNITS[cls].get("behavior", "")))
	if behavior != null:
		behavior.reset(self)
	_enter(State.SPAWNING)
	if motion == null:
		motion = UnitMotion.new(self, _draw_body, _draw_over)
	motion.reset(_motion_feet(), radius, 1.0, false)
	game.motion.on_summon_rise(self)  # Rises out of the ground (visual only).
	queue_redraw()


## Engine-motion pivot: the feet line of this unit's sprite or glyph (a
## floating Banshee's feet are its lift above the ground).
func _motion_feet() -> float:
	var lift := behavior.body_lift(self) if behavior != null else 0.0  # Drawn height (px).
	return UnitMotion.feet_of("summons/" + (glyph_kind if glyph_kind != "" else unit_class), "", radius, lift)


## Per-frame engine motion (MotionDirector) at game time `now`, `dt` game
## seconds after the last frame: stone form holds still, an airborne swoop
## drops the bob, lean and lunge; the stone tint follows onto the layers.
func update_motion(now: float, dt: float) -> void:
	if motion.body.self_modulate != self_modulate:
		motion.body.self_modulate = self_modulate
		motion.over.self_modulate = self_modulate
	motion.update(now, dt, stone_form, airborne)


## Engine motion: an attack toward world direction `dir` (zero = a slam or
## pulse) with MotionData power `power`. Visual only.
func motion_lunge(dir: Vector2, power: float) -> void:
	if motion != null:
		motion.lunge(dir, power, game.elapsed)


## Copies effective stats from the director. When `preserve_pct` is true the
## current HP fraction is preserved (GDD §34 "Health percentage is preserved
## on max HP increase unless healing explicitly occurs").
func apply_stats(stats: Dictionary, preserve_pct: bool = true) -> void:
	var frac := hp / max_hp if max_hp > 0.0 else 1.0
	max_hp = stats["max_hp"]
	damage = stats["damage"]
	attack_interval = stats["attack_interval"]
	attack_range = stats["attack_range"]
	acquisition_range = stats["acquisition_range"]
	move_speed = stats["move_speed"]
	engage_radius = float(stats.get("engage_radius", UnitData.ENGAGE_RADIUS))
	soft_recall = float(stats.get("soft_recall", UnitData.SOFT_RECALL))
	return_speed_mult = float(stats.get("return_speed_mult", UnitData.RETURN_SPEED_MULT))
	radius = stats["radius"]
	band_min = stats["band_min"]
	band_max = stats["band_max"]
	w_pursuit = stats["w_pursuit"]
	w_formation = stats["w_formation"]
	w_separation = stats["w_separation"]
	w_threat = stats["w_threat"]
	windup = stats["windup"]
	projectile_speed = stats["projectile_speed"]
	splash_radius = stats["splash_radius"]
	heal_amount = stats["heal_amount"]
	kite_distance = stats["kite_distance"]
	pierce = stats["pierce"]
	block_radius = stats["block_radius"]
	block_mass = stats["block_mass"]
	engaged_speed_mult = stats["engaged_speed_mult"]
	bash_damage = stats["bash_damage"]
	bash_cooldown = stats["bash_cooldown"]
	bash_knockback = stats["bash_knockback"]
	shield_amount = stats["shield_amount"]
	shield_duration = stats["shield_duration"]
	shield_cooldown = stats["shield_cooldown"]
	heal_role_priority = stats["heal_role_priority"]
	attack_profile = stats["attack_profile"]
	target_profile = stats["target_profile"]
	ally_shield_amount = float(stats.get("ally_shield_amount", 0.0))
	ally_shield_cooldown = float(stats.get("ally_shield_cooldown", 0.0))
	aura_interval = float(stats.get("aura_interval", 0.0))
	aura_radius = float(stats.get("aura_radius", 0.0))
	aura_heal = float(stats.get("aura_heal", 0.0))
	aura_damage = float(stats.get("aura_damage", 0.0))
	cleave_radius = float(stats.get("cleave_radius", 0.0))
	cleave_fraction = float(stats.get("cleave_fraction", 0.0))
	lifesteal = float(stats.get("lifesteal", 0.0))
	evolution = String(stats.get("evolution", ""))
	dmg_source = evolution if evolution != "" else unit_class
	glyph_kind = dmg_source
	special = stats.get("special", {})
	var w: Dictionary = UnitData.TARGET_WEIGHTS[target_profile]
	_wd = w["distance"]
	_wt = w["threat"]
	_wr = w["role"]
	_wv = w["tactical"]
	_wc = w["cluster"]
	_wo = w["overkill"]
	if preserve_pct:
		hp = max_hp * frac
	if motion != null:
		motion.feet = _motion_feet()  # An evolution changes the look.
	queue_redraw()


## Called by HordeDirector when HP reaches 0: stop AI, release reservations
## and hide (GDD §24 "On death").
func deactivate() -> void:
	_drop_target()
	if behavior != null:
		behavior.on_deactivate(self)
	airborne = false
	stone_form = false
	active = false
	state = State.DEAD
	visible = false
	velocity = Vector2.ZERO
	incoming_heal = 0.0


## Visual hit reaction (also restarts the ally-barrier threat window).
func on_hit() -> void:
	flash = 0.1
	since_hit = 0.0
	if motion != null:
		motion.hit(game.elapsed)  # Engine motion: hit squash with the flash.
	queue_redraw()


## Enters `new_state` and resets the state timer.
func _enter(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_time = 0.0


## Public FSM transition for SummonBehavior (same as _enter()).
func set_state(new_state: State) -> void:
	_enter(new_state)


## Public target release for SummonBehavior (same as _drop_target()).
func clear_target() -> void:
	_drop_target()


## True if `target` still refers to the same living enemy (for SummonBehavior).
func target_alive() -> bool:
	return _target_valid()


## Act II, the Hollow Archive (the Librarian's beam; the one path that turns a
## summon around): for `duration` s the summon drops its target, stops
## fighting and walks along `dir` at `speed_mult` x its move speed; the leash
## (hard recall) still applies. A spawning, airborne or special-casting unit
## is not turned. Returns true when it was turned.
func misdirect(dir: Vector2, duration: float, speed_mult: float) -> bool:
	if not active or state == State.SPAWNING or state == State.DEAD or airborne:
		return false
	if behavior != null and behavior.is_busy():
		return false
	_drop_target()
	if state == State.CASTING:
		cast_time = 0.0
	_enter(State.FOLLOWING)
	misdirect_until = game.elapsed + duration
	misdirect_dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	misdirect_speed = speed_mult
	queue_redraw()
	return true


# =====================================================================================
# think() — 5 Hz decisions (GDD §39 UNIT pseudocode)
# =====================================================================================

## Staggered AI decision step.
func think() -> void:
	if not active or state == State.DEAD or state == State.SPAWNING:
		return
	var player_pos := game.player.position
	var d_player := position.distance_to(player_pos)
	# Leash (GDD §24): hard recall teleports, soft recall returns.
	if d_player > UnitData.HARD_RECALL:
		_safe_recall()
		return
	if misdirect_until > game.elapsed:
		return  # Turned around (misdirect()): no decisions until it wears off.
	_update_threat_avoidance()
	if _check_stall(player_pos):
		return
	if state == State.RETURNING:
		if d_player <= band_max + UnitData.RETURN_ARRIVE_MARGIN:
			_enter(State.FOLLOWING)
		return
	if d_player > soft_recall:
		_drop_target()
		_enter(State.RETURNING)
		game.stat_add("summon_soft_recalls", 1.0)
		return
	# Warders / Bishops: instant ward on a threatened necromancer and an
	# instant barrier on a threatened ally (never cost a heal or an attack).
	if shield_amount > 0.0:
		_try_ward()
	if ally_shield_amount > 0.0 and ally_shield_cd <= 0.0:
		SummonAbilities.try_ally_barrier(self)
	if state == State.CASTING:
		return
	# Class special (SummonBehavior): may start one and take this decision.
	if behavior != null and behavior.think(self):
		return
	# Priests: healing has priority over everything else (GDD §31).
	if attack_profile == "heal" and _think_heal():
		return
	if not _target_valid():
		if target != null:
			_drop_target()
	# ENGAGING -> RETURNING when pursuit exceeds the engagement leash.
	if target != null and d_player > engage_radius:
		_drop_target()
		_enter(State.RETURNING)
		return
	# Target commitment (GDD §27): hold >= 1 s, switch early only for a
	# significantly better target.
	if target == null or target_hold >= UnitData.TARGET_COMMIT_TIME:
		var best := _acquire_best_target()
		if best != null and best != target:
			if target == null:
				_set_target(best)
			else:
				var best_score := _best_score
				var current := _score_enemy(target, target.position.distance_to(player_pos))
				if best_score > current + UnitData.SWITCH_MARGIN:
					_set_target(best)
				else:
					target_hold = 0.0
	if target != null:
		if state == State.FOLLOWING or state == State.ACQUIRING:
			_enter(State.ENGAGING)
	elif state != State.FOLLOWING:
		_enter(State.FOLLOWING)


## Priest heal logic (GDD §31 / §39). Returns true if the priest has a heal
## job. Wards are handled separately by _try_ward() so they never replace a
## heal cast.
func _think_heal() -> bool:
	if _heal_target_valid() and target_hold < UnitData.TARGET_COMMIT_TIME:
		return true
	var best := _choose_heal_target()
	if best == null:
		heal_target = null
		return false
	if best != heal_target:
		target_hold = 0.0
	heal_target = best
	heal_target_gen = (best as SummonedUnit).generation if best is SummonedUnit else 0
	target = null
	if state == State.FOLLOWING or state == State.ACQUIRING:
		_enter(State.ENGAGING)
	return true


## Sets a new enemy target and resets commitment.
func _set_target(e: Enemy) -> void:
	target = e
	target_gen = e.generation
	target_hold = 0.0
	heal_target = null


## Clears enemy and heal targets and releases any heal reservation.
func _drop_target() -> void:
	_release_heal_reservation()
	target = null
	heal_target = null
	target_hold = 0.0


## True if `target` still refers to the same living enemy.
func _target_valid() -> bool:
	return target != null and target.active and target.generation == target_gen


## True if the heal target still exists and still needs healing (or, for a
## ward job, still has no ward).
func _heal_target_valid() -> bool:
	if heal_target == null:
		return false
	if heal_target is SummonedUnit:
		var u := heal_target as SummonedUnit
		return u.active and u.generation == heal_target_gen and u.state != State.DEAD and u.hp < u.max_hp - 0.5
	var p := heal_target as Necromancer
	if p == null or p.dead:
		return false
	return p.hp < p.max_hp - 0.5


## Ward on the necromancer (user brief; the old priest ward, now cast by
## Warders and Profane Bishops). An instant secondary cast
## with its own cooldown, so it never delays or replaces a heal:
##   * fires whenever the necromancer is under threat (recently hit, or an
##     enemy within WARD_THREAT_RADIUS) even if he is somewhat hurt,
##   * only while no ward is active and this priest's ward cooldown is ready
##     (no stacking).
## It is NOT suppressed while someone is critical (balance pass fix): the
## ward is instant and never delays a heal, and in the boss fight some
## summon was almost always critical, so wards stopped exactly when the
## necromancer needed them (army runs dipped to 36-43 HP at 19:00).
func _try_ward() -> void:
	if not _can_shield_player():
		return
	var p := game.player
	p.apply_shield(shield_amount, shield_duration)
	_shield_cd = shield_cooldown
	game.effects.beam(position, p.position, Palette.COLD_BLUE)
	game.stat_add("priest_wards", 1.0)
	game.stat_add("shield_by_" + dmg_source, shield_amount)


## True if this priest may cast a ward on the necromancer right now: it has
## a ward, its cooldown is ready (no stacking), no ward is active, the player
## is in reach, and the player is under threat.
func _can_shield_player() -> bool:
	var p := game.player
	if shield_amount <= 0.0 or _shield_cd > 0.0 or p.dead or p.shield_hp > 0.0:
		return false
	if position.distance_to(p.position) > acquisition_range:
		return false
	if p.time_since_hit <= UnitData.SHIELD_TRIGGER_WINDOW or director.player_in_danger:
		return true
	game.enemy_grid.query(p.position, UnitData.WARD_THREAT_RADIUS, _neigh)
	for e: Enemy in _neigh:
		if e.active:
			return true
	return false


## Stall recall (UnitData.STALL_TIME): true (and recalls the unit) when it
## is trying to rejoin the player but has moved less than STALL_DISTANCE px for
## STALL_TIME s. Deterministic: positions and game time only.
func _check_stall(player_pos: Vector2) -> bool:
	var moving := state == State.RETURNING or (state == State.FOLLOWING \
			and position.distance_to(player_pos + anchor_offset) > UnitData.STALL_MIN_GAP)  # Trying to get somewhere.
	if not moving:
		_stall_since = -1.0
		return false
	if _stall_since < 0.0 or position.distance_to(_stall_pos) > UnitData.STALL_DISTANCE:
		_stall_pos = position
		_stall_since = game.elapsed
		return false
	if game.elapsed - _stall_since < UnitData.STALL_TIME:
		return false
	_stall_since = -1.0
	director.stall_recalls += 1
	if GameState.autotest:
		print("[autotest] stall recall: %s %s at %s, %.0f px from the player, touching an obstacle: %s" % [unit_class, State.keys()[state], str(position.round()), position.distance_to(player_pos), str(game.arena.is_blocked(position, radius + 3.0))])
	_safe_recall()
	return true


## Teleports a stranded unit next to the player (GDD §24 hard recall).
func _safe_recall() -> void:
	_drop_target()
	game.effects.spawn_ring(position, Palette.NECRO_GREEN)
	position = game.arena.free_point(game.player.position + anchor_offset, radius)
	velocity = Vector2.ZERO
	game.effects.spawn_ring(position, Palette.NECRO_GREEN)
	director.hard_recalls += 1
	_enter(State.FOLLOWING)


## Samples nearby enemies once per think: direction to flee and the closest
## enemy edge distance (used for threat avoidance and archer kiting).
func _update_threat_avoidance() -> void:
	_threat_away = Vector2.ZERO
	_threat_dist = INF
	if w_threat <= 0.0 and kite_distance <= 0.0:
		return
	game.enemy_grid.query(position, UnitData.THREAT_AVOID_RADIUS, _neigh)
	for e: Enemy in _neigh:
		if not e.active:
			continue
		var diff := position - e.position
		var d := maxf(diff.length() - e.radius, 0.01)
		_threat_dist = minf(_threat_dist, d)
		_threat_away += diff.normalized() * (1.0 - clampf(d / UnitData.THREAT_AVOID_RADIUS, 0.0, 1.0))
	_threat_away = _threat_away.limit_length(1.0)


# =====================================================================================
# Target scoring (GDD §27)
# =====================================================================================

## Returns the best-scoring enemy in acquisition range (or null) and stores
## its score in `_best_score` (GDD §39 TARGET SELECTOR).
func _acquire_best_target() -> Enemy:
	var best: Enemy = null
	_best_score = -INF
	var player_pos := game.player.position
	game.enemy_grid.query(position, acquisition_range, _cand)
	var examined := 0
	for e: Enemy in _cand:
		if not e.active:
			continue
		var dp := e.position.distance_to(player_pos)
		if not _candidate_allowed(dp):
			continue
		var s := _score_enemy(e, dp)
		if s > _best_score:
			_best_score = s
			best = e
		if attack_profile == "aoe":
			examined += 1
			if examined >= UnitData.MAGE_MAX_CANDIDATES:
				break
	return best


## Leash-based candidate filter. `dp` = enemy distance to the player.
func _candidate_allowed(dp: float) -> bool:
	if target_profile == "guard":
		if dp > engage_radius:
			return false
		# "Don't chase distant targets while necromancer is surrounded."
		if director.player_in_danger and dp > UnitData.WARRIOR_INTERCEPT_RADIUS:
			return false
		return true
	return dp <= engage_radius + attack_range * 0.5


## score = distance*Wd + threat*Wt + role*Wr + tactical*Wv + cluster*Wc
##         - overkill*Wo, every term normalised to 0..1 (GDD §27).
func _score_enemy(e: Enemy, dp: float) -> float:
	var d := position.distance_to(e.position)
	var dist_v := 1.0 - clampf(d / acquisition_range, 0.0, 1.0)
	var threat := 1.0 - clampf(dp / UnitData.THREAT_NORM_DISTANCE, 0.0, 1.0)
	if e.targeting_player:
		threat = minf(1.0, threat + 0.3)
	var tactical := 0.0
	if target_profile == "guard":
		# Enemies already hitting our summons are worth intercepting.
		tactical = 1.0 if e.targeting_summon else 0.0
	elif target_profile == "ranged":
		# Near-death finishable enemies (GDD §27 archer preference).
		tactical = 1.0 - e.hp / e.max_hp
	var cluster := 0.0
	if _wc > 0.0:
		cluster = _cluster_value(e)
	var overkill := 1.0 if e.hp - e.incoming_damage <= 0.0 else 0.0
	var wt := _wt
	if target_profile == "guard" and director.player_in_danger:
		wt *= 1.5
	var bonus := behavior.score_bonus(self, e, dp) if behavior != null else 0.0  # Class preference.
	return dist_v * _wd + threat * wt + e.target_priority * _wr + tactical * _wv + cluster * _wc - overkill * _wo + bonus


## Mage cluster value of an explosion centred on `e`: enemy count inside the
## splash (normalised) plus the value of support/elite units caught in it.
func _cluster_value(e: Enemy) -> float:
	game.enemy_grid.query(e.position, splash_radius, _neigh)
	var count := 0
	var value := 0.0
	for n: Enemy in _neigh:
		if n.active:
			count += 1
			value += n.target_priority
	return clampf(float(count) / UnitData.MAGE_CLUSTER_NORM, 0.0, 1.0) * 0.8 + clampf(value / UnitData.MAGE_CLUSTER_NORM, 0.0, 1.0) * 0.2


## Priest heal target choice (GDD §31 / §39 PRIEST TARGETING): highest
## 0.6*missing_frac + 0.2*missing_raw_norm + 0.2*role (+ critical bonus).
## The necromancer is a candidate too (role PLAYER_HEAL_ROLE) and a critical
## necromancer gets an extra bonus so he has top priority.
## Full-HP (or already fully covered by in-flight heals) targets are skipped.
func _choose_heal_target() -> Node2D:
	var player := game.player
	var best: Node2D = null
	var best_score := 0.0
	if not player.dead and position.distance_to(player.position) <= acquisition_range:
		var p_missing := player.max_hp - player.hp - player.incoming_heal
		if p_missing > 0.5:
			best_score = _heal_score(p_missing, player.max_hp, UnitData.PLAYER_HEAL_ROLE)
			if player.hp < player.max_hp * UnitData.HEAL_CRITICAL_FRACTION:
				best_score += UnitData.HEAL_CRITICAL_BONUS + UnitData.PLAYER_CRITICAL_BONUS
			best = player
	game.ally_grid.query(position, acquisition_range, _cand)
	for a: SummonedUnit in _cand:
		if not a.active or a.state == State.DEAD or a.state == State.SPAWNING:
			continue
		var missing := a.max_hp - a.hp - a.incoming_heal
		if missing <= 0.5:
			continue
		var s := _heal_score(missing, a.max_hp, a.heal_role_priority)
		if a.hp < a.max_hp * UnitData.HEAL_CRITICAL_FRACTION:
			s += UnitData.HEAL_CRITICAL_BONUS
		if s > best_score:
			best_score = s
			best = a
	return best


## GDD §31 normalised heal score (without the critical bonus).
static func _heal_score(missing: float, max_health: float, role: float) -> float:
	return UnitData.HEAL_W_MISSING_FRACTION * (missing / max_health) \
			+ UnitData.HEAL_W_MISSING_RAW * clampf(missing / UnitData.HEAL_MISSING_RAW_NORM, 0.0, 1.0) \
			+ UnitData.HEAL_W_ROLE * role


## Warrior shield bash on an enemy pressed against this blocker (called by
## Enemy.resolve_blocking): damage + knockback along `normal`, on cooldown.
func try_bash(e: Enemy, normal: Vector2) -> void:
	if bash_damage <= 0.0 or bash_cd > 0.0 or state == State.SPAWNING:
		return
	bash_cd = bash_cooldown
	e.knockback += normal * bash_knockback / maxf(e.mass, 0.1)
	game.effects.slash(position + normal * radius, normal, Palette.COLD_BLUE if evolution == "" else Palette.VIOLET, radius * 1.6)
	game.stat_add("warrior_bashes", 1.0)
	game.combat.damage_enemy(e, bash_damage, "bash" if evolution == "" else evolution + "_bash")


# =====================================================================================
# physics_step() — 60 Hz movement and combat timing
# =====================================================================================

## Per-physics-tick update (movement, attack timing, casting, animation).
func physics_step(delta: float) -> void:
	if not active:
		return
	state_time += delta
	target_hold += delta
	attack_cd -= delta
	_kite_cd -= delta
	bash_cd -= delta
	_shield_cd -= delta
	ally_shield_cd -= delta
	since_hit += delta
	if transform_time > 0.0:
		transform_time -= delta
		queue_redraw()
	if holy_slow_timer > 0.0:
		holy_slow_timer -= delta
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()
	if state == State.SPAWNING:
		queue_redraw()
		if state_time >= UnitData.SPAWN_DURATION:
			_enter(State.FOLLOWING)
		return
	if aura_interval > 0.0:
		aura_cd -= delta
		if aura_cd <= 0.0:
			aura_cd = aura_interval
			SummonAbilities.aura_pulse(self)
	if misdirect_until > game.elapsed:
		velocity = misdirect_dir * move_speed * misdirect_speed  # Turned around (misdirect()).
	elif behavior != null and behavior.physics(self, delta):
		pass  # A class special owns this tick (it set the velocity).
	elif state == State.CASTING:
		_step_cast(delta)
	else:
		_step_movement(delta)
	position += velocity * delta
	if absf(velocity.x) > 8.0:
		var f := signf(velocity.x)
		if f != _facing:
			_facing = f
			scale.x = _facing
			queue_redraw()  # HP bar counter-flip depends on facing


## Blends steering behaviours into a velocity (GDD §26: formation
## attraction, target pursuit, ally separation, threat avoidance; weighted and
## clamped). Obstacles are handled by Arena.resolve_all (push-out + slide
## along the obstacle), so there is no separate obstacle term here. Holy
## ground slows the unit.
func _step_movement(delta: float) -> void:
	var player_pos := game.player.position
	var anchor := player_pos + anchor_offset
	var desired := Vector2.ZERO
	var speed := move_speed
	match state:
		State.FOLLOWING, State.ACQUIRING:
			desired = _arrive(anchor)
			if position.distance_to(anchor) > UnitData.CATCHUP_DISTANCE:
				speed *= UnitData.CATCHUP_SPEED_MULT
		State.RETURNING:
			desired = (anchor - position).normalized()
			speed *= return_speed_mult
		_:
			desired = _combat_desire(anchor, player_pos)
	if holy_slow_timer > 0.0:
		speed *= 1.0 - holy_slow
	if state != State.RETURNING:
		desired += _threat_away * w_threat
	desired += _separation() * w_separation
	desired = desired.limit_length(1.0) * speed
	velocity = velocity.move_toward(desired, speed * UnitData.STEER_ACCEL * delta)


## Combat steering + attack triggering for ENGAGING / REPOSITIONING /
## RETREATING. Returns the (unclamped) desired direction.
func _combat_desire(anchor: Vector2, player_pos: Vector2) -> Vector2:
	var goal: Node2D = null
	var goal_radius := 0.0
	if heal_target != null:
		if _heal_target_valid():
			goal = heal_target
			goal_radius = (heal_target as SummonedUnit).radius if heal_target is SummonedUnit else game.player.radius
	elif _target_valid():
		goal = target
		goal_radius = target.radius
	if goal == null:
		# ENGAGING -> ACQUIRING when the target dies (resolved next think).
		_drop_target()
		_enter(State.ACQUIRING)
		return _arrive(anchor)
	var to_goal := goal.position - position
	var d := to_goal.length()
	var dir := to_goal / d if d > 0.001 else Vector2.ZERO
	var formation := _arrive(anchor) * w_formation
	if attack_profile == "melee":
		var edge := d - radius - goal_radius
		if edge <= attack_range:
			if state != State.ENGAGING:
				_enter(State.ENGAGING)
			if attack_cd <= 0.0:
				_begin_cast()
			return formation * 0.2
		if state != State.ENGAGING:
			_enter(State.ENGAGING)
		return dir * w_pursuit + formation
	# Ranged / heal profiles.
	if kite_distance > 0.0:
		if state == State.RETREATING:
			if state_time >= UnitData.KITE_DURATION:
				_kite_cd = UnitData.KITE_COOLDOWN
				_enter(State.ENGAGING)
			else:
				return _threat_away * 1.5 + (player_pos - position).normalized() * 0.4
		elif _threat_dist <= kite_distance and _kite_cd <= 0.0:
			_enter(State.RETREATING)
			return _threat_away * 1.5
	var reach := attack_range + goal_radius
	if d > reach:
		if state != State.REPOSITIONING:
			_enter(State.REPOSITIONING)
		var approach := 1.0 if heal_target != null else maxf(w_pursuit, 0.4)
		return dir * approach + formation * 0.3
	if state != State.ENGAGING:
		_enter(State.ENGAGING)
	if attack_cd <= 0.0:
		_begin_cast()
	return formation * 0.5


## Arrival steering toward `point`: full strength far away, easing in close.
func _arrive(point: Vector2) -> Vector2:
	var v := point - position
	var d := v.length()
	if d < 4.0:
		return Vector2.ZERO
	return v / d * clampf(d / 40.0, 0.0, 1.0)


## Soft ally separation (GDD §26: friendly<->friendly no hard collisions,
## steering separation only).
func _separation() -> Vector2:
	var reach := radius * 2.0 * UnitData.SEPARATION_SPREAD + UnitData.SEPARATION_PADDING
	game.ally_grid.query(position, reach, _neigh)
	var push := Vector2.ZERO
	for o: SummonedUnit in _neigh:
		if o == self or not o.active:
			continue
		var diff := position - o.position
		var d := diff.length()
		var min_d := (radius + o.radius) * UnitData.SEPARATION_SPREAD + UnitData.SEPARATION_PADDING
		if d >= min_d:
			continue
		if d < 0.01:
			# Exactly overlapping: push in a stable pseudo-random direction.
			# Derived from the think slot and pool generation, not the
			# instance id: ids depend on thread timing (audio synthesis
			# allocates objects on worker threads), which broke determinism.
			diff = Vector2.from_angle(float((think_slot * 157 + generation * 61) % 628) * 0.01)
			d = 1.0
		push += diff / d * (1.0 - d / min_d)
	return push


# =====================================================================================
# Attacks
# =====================================================================================

## Starts a windup (CASTING). Ranged units first check the overkill
## reservation and redirect if their target is already expected to die
## (GDD §27 "redirect new shots when target is already expected to die").
func _begin_cast() -> void:
	if heal_target == null and attack_profile != "melee" and _target_valid() \
			and target.hp - target.incoming_damage <= 0.0:
		game.stat_add("overkill_redirects", 1.0)
		var alt := _acquire_best_target()
		if alt == null or alt == target or alt.hp - alt.incoming_damage <= 0.0:
			attack_cd = 0.2
			return
		_set_target(alt)
		if position.distance_to(alt.position) > attack_range + alt.radius:
			return
	if attack_profile == "aoe" and _target_valid():
		cast_point = target.position
	if heal_target is SummonedUnit:
		var u := heal_target as SummonedUnit
		_reserved_heal = minf(heal_amount, u.max_hp - u.hp)
		_reserved_heal_on = u
		_reserved_heal_gen = u.generation
		u.incoming_heal += _reserved_heal
	elif heal_target is Necromancer:
		var pl := heal_target as Necromancer
		_reserved_heal = minf(heal_amount, pl.max_hp - pl.hp)
		_reserved_heal_on = pl
		_reserved_heal_gen = 0
		pl.incoming_heal += _reserved_heal
	_enter(State.CASTING)
	cast_time = windup


## Holds still while the windup runs, then releases the attack.
func _step_cast(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 10.0 * delta)
	cast_time -= delta
	if cast_time > 0.0:
		return
	_release_attack()
	game.volleys.on_attack(self)  # Bullet heaven pass: every Nth release fires the class volley.
	attack_cd = attack_interval
	if _target_valid() or _heal_target_valid():
		_enter(State.ENGAGING)
	else:
		_drop_target()
		_enter(State.ACQUIRING)


## Applies the attack at the end of the windup, per attack_profile.
func _release_attack() -> void:
	_attack_motion()
	match attack_profile:
		"melee":
			if _target_valid():
				var edge := position.distance_to(target.position) - radius - target.radius
				if edge <= attack_range + UnitData.MELEE_TOLERANCE:
					var dir := (target.position - position).normalized()
					var hit_at := target.position  # Cleave centre (the target may die).
					var struck := target  # The struck enemy (the target may die).
					game.effects.slash(position + dir * radius, dir, Palette.BONE, radius * 1.4)
					var mult := behavior.melee_bonus(self, struck) if behavior != null else 1.0  # Class bonus (Pack Hunt).
					var dealt := game.combat.damage_enemy(struck, damage * mult, dmg_source)
					if behavior != null:
						behavior.on_melee_hit(self, struck, dealt)  # Hellhound burn.
					if cleave_radius > 0.0 or lifesteal > 0.0:
						SummonAbilities.after_melee(self, target, hit_at, dir, dealt)
		"arrow":
			if _target_valid():
				if GravebowKit.is_gravebow(self):
					GravebowKit.release_volley(self)  # Piercing, splitting, cursing arrows.
				else:
					game.projectiles.fire_friendly(Projectile.Kind.ARROW, position, target, damage, projectile_speed, pierce, dmg_source)
		"aoe":
			game.projectiles.fire_aoe(position, cast_point, damage, projectile_speed, splash_radius, target if _target_valid() else null, dmg_source)
		"heal":
			if heal_target != null:
				_release_heal_reservation()
				if _heal_target_valid():
					var healed := 0.0
					if heal_target is SummonedUnit:
						healed = game.combat.heal_unit(heal_target as SummonedUnit, heal_amount)
					else:
						healed = game.combat.heal_player(heal_amount)
					if healed > 0.0:
						game.effects.beam(position, heal_target.position, Palette.NECRO_GREEN)
						game.stat_add("priest_heals", 1.0)
						game.stat_add("heal_by_" + dmg_source, healed)
			elif _target_valid():
				# Minor unholy offense when nothing needs healing (GDD §7).
				game.projectiles.fire_friendly(Projectile.Kind.PRIEST_BOLT, position, target, damage, projectile_speed, 0, dmg_source)
		"ward":
			# Warder: minor unholy offense; its wards and barriers are instant
			# side casts in think(), so they never wait on this cooldown.
			if _target_valid():
				game.projectiles.fire_friendly(Projectile.Kind.PRIEST_BOLT, position, target, damage, projectile_speed, 0, dmg_source)
		_:
			# Class-specific profiles (e.g. "frost") are released by the behaviour.
			if behavior != null:
				behavior.release_attack(self)


## Engine motion of a released attack: a lunge toward the struck enemy, the
## aimed point or the healed ally (a shot or a cast lunges less).
func _attack_motion() -> void:
	var at := position  # Where the attack goes (world px).
	if attack_profile == "heal" and heal_target != null and is_instance_valid(heal_target):
		at = heal_target.position
	elif attack_profile == "aoe":
		at = cast_point
	elif _target_valid():
		at = target.position
	var power := MotionData.POWER_MELEE if attack_profile == "melee" else (MotionData.POWER_CAST if attack_profile == "heal" or attack_profile == "ward" else MotionData.POWER_SHOT)  # Lunge power.
	motion_lunge(at - position, power)


## Removes this healer's pending heal from its target's incoming_heal.
func _release_heal_reservation() -> void:
	if _reserved_heal_on is SummonedUnit:
		var u := _reserved_heal_on as SummonedUnit
		if u.generation == _reserved_heal_gen:
			u.incoming_heal = maxf(0.0, u.incoming_heal - _reserved_heal)
	elif _reserved_heal_on is Necromancer:
		var pl := _reserved_heal_on as Necromancer
		pl.incoming_heal = maxf(0.0, pl.incoming_heal - _reserved_heal)
	_reserved_heal_on = null
	_reserved_heal = 0.0


# =====================================================================================
# Drawing
# =====================================================================================

## Draws in three layers (engine motion, UnitMotion): this node draws what
## lies on the ground under the body (telegraphs, flight shadow, auras, the
## spawn glow), then queues the body layer (the only one that moves; the
## rise out of the ground is its transform) and the overlay layer above it.
## Before the first activation (no layers yet) everything is drawn here.
func _draw() -> void:
	if behavior != null:
		behavior.draw_under(self)  # Telegraphs and flight shadow, under the body.
	if director != null and director.synergies.is_active("unholy_host"):
		ProgressionGlyphs.draw_host_aura(self, Vector2(0, radius * 0.6), radius)
	if state == State.SPAWNING:
		var rise := clampf(state_time / UnitData.SPAWN_DURATION, 0.0, 1.0)  # Spawn progress.
		draw_circle(Vector2(0, radius * 0.9), radius * (1.3 - 0.4 * rise), Color(Palette.NECRO_GREEN, 0.3 * (1.0 - rise)))
	if is_temporary:
		# Stage-event summon: spectral green aura that dims as it expires.
		var k := clampf(temp_life / 5.0, 0.3, 1.0)
		draw_circle(Vector2.ZERO, radius * 1.5, Color(Palette.NECRO_GREEN, 0.12 * k))
		draw_arc(Vector2.ZERO, radius * 1.5, 0.0, TAU, 20, Color(Palette.NECRO_GREEN, 0.7 * k), 1.5)
	if transform_time > 0.0:
		SummonGlyphs.draw_transform_glow(self, radius, transform_time / SummonEvolutionData.TRANSFORM_FX_TIME)
	if motion != null:
		motion.redraw_layers()
	else:
		_draw_body(self)
		_draw_over(self)


## Body layer on `ci`: the sprite or glyph, lifted while it flies / floats.
func _draw_body(ci: CanvasItem) -> void:
	var lift := behavior.body_lift(self) if behavior != null else 0.0  # px the body is drawn above the ground (Gargoyle flight).
	if stone_form and SpriteBank.draw(ci, stone_key(), Vector2(0, -lift), flash > 0.0):
		return  # Stone-form still (the Cathedral Horror turned to grey stone).
	Glyphs.draw_summon(ci, glyph_kind if glyph_kind != "" else unit_class, Vector2(0, -lift), radius, flash > 0.0)


## Sprite key of this unit's stone-form still ("summons/<kind>_stone",
## MarkerArtData.STONE_SUFFIX), drawn while stone_form when its PNG exists.
func stone_key() -> String:
	return "summons/" + (glyph_kind if glyph_kind != "" else unit_class) + MarkerArtData.STONE_SUFFIX


## Overlay layer on `ci`: class overlays, the barrier and the HP bar.
func _draw_over(ci: CanvasItem) -> void:
	if behavior != null:
		behavior.draw_over(self, ci)  # Overlays on the body (Cathedral Horror stone).
	if barrier_hp > 0.0:
		ProgressionGlyphs.draw_barrier(ci, Vector2.ZERO, radius, barrier_hp / maxf(max_hp, 1.0))
	if hp < max_hp - 0.5 and state != State.SPAWNING:
		# The node is mirrored via scale.x; counter-flip so the bar always
		# fills left-to-right.
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
		Glyphs.hp_bar(ci, Vector2(0, -radius * 1.9), radius * 2.0, hp / max_hp, Palette.HP_FRIENDLY)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
