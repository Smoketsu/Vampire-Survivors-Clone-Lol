## Enemy — one Crimson Covenant soldier, driven by EnemyDirector. A single
## data-driven script covers every regular kind (Recruit, Footman, Zealous
## Archer, Chaplain, Purifier, Templar Knight); EnemyData supplies stats and a
## `behavior` key:
##   melee     close in on the player, divert onto summons in the way.
##   purifier  hunt undead summons first (GDD §35), bonus damage vs undead.
##   ranged    walk at the player and shoot arrows (player or a nearer summon)
##             whenever a target is in range.
##   healer    walk at the player and heal the most wounded OTHER enemy in
##             range (§10).
##   templar   melee that periodically telegraphs a short rush lane and
##             charges along it, shoving summons aside; a warrior in the lane
##             stops the rush (GDD §10 "knockback/disruption", §35).
##   consecrator  set at runtime by StageDirector on a desecration-event
##             Chaplain: walks to its grave (`post_pos`) and holds there
##             while it channels (GDD §11 desecration events).
## Crimson March kinds (MarchEnemyData, GDD §8.2) add:
##   banner    walk at the player like a Chaplain and buff every other
##             Covenant soldier inside `aura_radius` (Banner Bearer).
##   structure stand still, never pick targets (watchtowers, outposts, ward
##             generators, Vael's Holy Standard); an aura structure buffs too.
##   cart      roll in a straight line toward `post_pos` (supply carts);
##             MarchDirector removes it when its time is up.
##   and optional data keys: projectile_resist (tower shield), the aura_*
##   buff, cleave_* (a halberd hit on a summon also hits its neighbours) and
##   is_structure. A buffed soldier (`buff_time` > 0) deals, moves and takes
##   damage with the aura's multipliers. damage_taken_mult() is the one hook
##   CombatResolver asks before applying damage (Marshal Vael overrides it
##   for his Shieldwall).
## Sanctum of Judgment kinds (SanctumEnemyData, GDD §8.3) add optional keys
## read here (absent = off): `kit` (a CovenantKit with the kind's specials:
## Sentinel sweep, Inquisitor zones and suppression, Confessor shields and
## revival, Paladin ward, Guardian slams and beam, the Sister of the
## Scourge's lash and zeal (BattleSisterData); hooks in activate(),
## deactivate(), think(), physics_step() and _draw()), always_elite,
## construct (never healed), flat_armor, miniboss, projectile "radiant" and
## heal_stat. Every enemy can carry a holy shield (absorb, High Confessor)
## and a sun ward (damage resistance, Sun Paladin), both applied by
## CombatResolver; set_heal_override() points a healer at a chosen ally.
## Electronic Empire kinds (EmpireEnemyData, Act III) add the optional key
## `body` ("machine" / "cyborg": leaves_corpse(), rises_as_gunner(); Steel has
## no soul) and fire their ranged attacks through their kit's fire_ranged()
## hook into EmpireShots (Line of Fire) instead of ProjectileManager.
## Survivor convention (user brief): enemies ALWAYS advance on the player;
## nobody kites or holds at range. Ranged units only slow down briefly after
## each shot (EnemyData.SHOOT_SLOW_*).
## Sir Alaric (BossAlaric) extends this class so every targeting / damage
## system treats the boss like any enemy.
##
## Like summons, enemies are pooled; `generation` guards stale references and
## `incoming_damage` is the rough ranged-damage reservation the horde uses to
## avoid overkill (GDD §27/§32).
class_name Enemy
extends Node2D

# --- Identity / lifecycle -----------------------------------------------------------

## Owning run.
var game: Game
## Kind id from EnemyData.ORDER ("boss" for Sir Alaric).
var kind: String = ""
## True while alive in the world (false = pooled).
var active: bool = false
## Incremented on each activation; lets holders detect a recycled enemy.
var generation: int = 0
## Elite variant (more HP, bigger, gold ring, more XP).
var is_elite: bool = false
## True only for the boss.
var is_boss: bool = false
## Which of the AI_TICK_DIVISOR physics ticks this enemy thinks on.
var think_slot: int = 0

# --- Stats (from EnemyData, scaled by time) -------------------------------------

## UI name.
var display_name: String = ""
## Maximum HP (after time scaling / elite multiplier).
var max_hp: float = 1.0
## Current HP.
var hp: float = 1.0
## Movement speed in px/s.
var move_speed: float = 50.0
## Damage per attack before the director's time-scaling multiplier.
var damage: float = 5.0
## Seconds between attacks.
var attack_interval: float = 1.0
## Melee reach (px, edge-to-edge) or max firing distance (ranged).
var attack_range: float = 4.0
## Body radius in px.
var radius: float = 9.0
## Fraction of incoming damage ignored (0..0.9).
var armor: float = 0.0
## XP crystal value dropped on death.
var xp_value: int = 1
## AI branch: "melee" | "purifier" | "ranged" | "healer".
var behavior: String = "melee"
## Arrow speed in px/s.
var projectile_speed: float = 0.0
## Damage multiplier against undead summons.
var undead_damage_mult: float = 1.0
## HP healed per chaplain cast.
var heal_amount: float = 0.0
## Seconds between chaplain heals.
var heal_interval: float = 0.0
## Chaplain heal search radius in px.
var heal_radius: float = 0.0
## 0..1 role priority summons use when scoring this enemy.
var target_priority: float = 0.2
## Fraction of slow effects ignored (boss only).
var slow_resist: float = 0.0
## Weight vs blocking warriors (overlap correction is mass-weighted).
var mass: float = 1.0
## True for Reckoning enemies (spawned after the countdown ends).
var is_reckoning: bool = false
## True for stage-objective enemies (consecrators): never recycled.
var is_objective: bool = false
## True for an elite promoted by the difficulty level (DifficultyData
## elite_chance): elite HP and size, but the base soldier's XP and no elite
## chest / power-up chance (EnemyDirector._spawn_trickle sets it).
var is_promoted: bool = false
## World point a "consecrator" walks to and holds ("cart": where it rolls to).
var post_pos: Vector2 = Vector2.ZERO
## True for buildings and carts (MarchEnemyData `is_structure`): no target
## picking, no separation steering, never recycled; Soul Nova treats them
## like elites.
var is_structure: bool = false
## Fraction (0..1) of damage ignored from projectile sources (tower shield,
## MarchEnemyData.PROJECTILE_SOURCES).
var projectile_resist: float = 0.0
## Radius (px) of the buff aura this unit projects (0 = none).
var aura_radius: float = 0.0
## Damage-dealt multiplier the aura grants.
var aura_damage_mult: float = 1.0
## Move-speed multiplier the aura grants.
var aura_speed_mult: float = 1.0
## Damage-taken multiplier the aura grants.
var aura_taken_mult: float = 1.0
## Radius (px) around a struck summon that a cleave also hits (0 = none).
var cleave_radius: float = 0.0
## Extra summons a cleave can hit.
var cleave_targets: int = 0
## Fraction of the damage the extra cleave targets take.
var cleave_mult: float = 0.0
## Seconds left of an aura buff on this unit (0 = not buffed).
var buff_time: float = 0.0
## Damage-dealt multiplier while buffed.
var buff_damage: float = 1.0
## Move-speed multiplier while buffed.
var buff_speed: float = 1.0
## Damage-taken multiplier while buffed.
var buff_taken: float = 1.0
## Sanctum kit (SanctumEnemyData "kit"; null for every other kind).
var kit: CovenantKit = null
## Sprite key this enemy wears instead of its own kind's art ("" = its own):
## a Drowned Thrall wears the claimed summon's ("summons/<class>"; EyeClaims).
var wears: String = ""
## Summon class drawn by the code glyph when `wears` has no sprite art.
var wears_class: String = ""
## Colour multiplied over the worn sprite (EyeEnemyData.CLAIM.tint).
var wear_tint: Color = Color.WHITE
# --- Act II: Ul-Thalos, the Risen Spire ---
## True while nothing can target, hit or block this enemy: it is left out of
## the enemy spatial hash (Game._rebuild_grids()). Vhal'Neth's face while it
## lies under the sea (BossVhalneth); false for every other enemy.
var untargetable: bool = false
## px; a summon dying this close is claimed by the Ancient Eye (EyeEnemyData
## "claim_radius"; 0 = this enemy claims nothing). EyeClaims reads it.
var claim_radius: float = 0.0
## Game time (s) until which this enemy is a marked claimer (a Scribe's curse,
## reach EyeEnemyData.CLAIM.curse_radius); 0 = never marked.
var claimer_until: float = 0.0
## Act II, the Hollow Archive (ArchiveEnemyData "phases"): true for a body
## that slips through obstacles (the Ink Wraith, the Unwritten): Arena
## .resolve_all() skips it.
var phases_obstacles: bool = false
## Act II (ArchiveEnemyData "floating"): true for a body drawn hovering (the
## Ink Wraith, the Librarian; visual only).
var floating: bool = false
# --- Act III: the Electronic Empire ---
## Body of an Electronic Empire kind (EmpireEnemyData "body"): "machine"
## (leaves no corpse), "cyborg" (raised, rises as a Grave Gunner) or "" for
## every flesh-and-bone kind of Acts I and II. Read through leaves_corpse() and
## rises_as_gunner(), the one Steel-has-no-soul gate.
var body: String = ""
## Forbidden Verse inscribe mark: game time (s) until which this enemy is
## inscribed (it bursts into ink when it dies). Written only by the
## ForbiddenVerse spell node, i.e. only while someone owns the spell; timed on
## Game.elapsed like Rot. 0 = never inscribed / expired.
var inscribed_until: float = 0.0
## True for animated stone (Sentinel, Guardian): never healed, shielded or
## raised by Covenant priests.
var is_construct: bool = false
## True for a miniboss (Cathedral Guardian): HUD bar, boss-like crowd-control
## resistance, never recycled, guaranteed chest.
var is_miniboss: bool = false
## HP of damage ignored from every hit after armour (0 = none; see
## SanctumEnemyData.FLAT_ARMOR_MIN_FRACTION).
var flat_armor: float = 0.0
## Holy shield HP left (High Confessor; absorbs damage before HP; 0 = none).
var holy_shield: float = 0.0
## Seconds before an unbroken holy shield fades.
var holy_shield_time: float = 0.0
## Sun Paladin ward: game time (s) until which it holds (0 = none). Compared
## with Game.elapsed like the curse.
var ward_until: float = 0.0
## Sun Paladin ward: fraction (0..1) of incoming damage removed while it holds.
var ward_resist: float = 0.0
## True for a soldier raised by a High Confessor (no XP, never raised again).
var is_revived: bool = false
## Healer only: an ally this healer prefers whenever it is wounded and within
## heal_override_radius (set_heal_override(); null = none).
var heal_override: Enemy = null
## Generation of `heal_override` when set (stale guard).
var heal_override_gen: int = 0
## Healer only: reach (px) of the override heal.
var heal_override_radius: float = 0.0
## Game.stats key counted per heal (SanctumEnemyData heal_stat; default
## "chaplain_heals").
var heal_stat: String = "chaplain_heals"
## True when a "ranged" kind fires radiant bolts (SanctumEnemyData
## "projectile": "radiant") instead of arrows.
var _radiant: bool = false

# --- Runtime --------------------------------------------------------------------------

## Pending ranged damage already "in flight" toward this enemy (overkill
## reservation, approximate by design).
var incoming_damage: float = 0.0
## Seconds until the next attack.
var attack_cd: float = 0.0
## Seconds until the next chaplain heal.
var heal_cd: float = 0.0
## Current attack/approach target: the Necromancer or a SummonedUnit.
var target: Node2D = null
## Generation of `target` if it is a SummonedUnit.
var target_gen: int = 0
## True when this enemy is attacking the player up close (warrior scoring).
var targeting_player: bool = false
## True when this enemy is attacking a nearby summon (warrior scoring).
var targeting_summon: bool = false
## Chaplain heal target.
var heal_target: Enemy = null
## Generation of `heal_target` when chosen.
var heal_target_gen: int = 0
## Cached separation push from nearby enemies (refreshed at ~10 Hz).
var sep: Vector2 = Vector2.ZERO
## Current velocity in px/s.
var velocity: Vector2 = Vector2.ZERO
## Remaining slow duration in seconds.
var slow_timer: float = 0.0
## Fraction of speed removed while slowed.
var slow_factor: float = 0.0
## Remaining hit-flash time in seconds.
var flash: float = 0.0
## Seconds before Orb Shield orbs may hit this enemy again.
var orb_hit_cd: float = 0.0
## Seconds left "engaged" by a blocking warrior (slowed, fights it).
var engaged_timer: float = 0.0
## Speed multiplier while engaged (the touching blocker's engaged_speed_mult,
## the lowest one when several touch it in the same tick).
var engaged_mult: float = 1.0
## Knockback velocity in px/s (shield bashes), decays over time.
var knockback: Vector2 = Vector2.ZERO
## Seconds left of a mage mark (Volley of the Fallen synergy, GDD §6.3):
## skeletal arrows deal bonus damage while it is > 0.
var mark_time: float = 0.0
## Plague Cloud Rot: game time (s) until which this enemy rots (takes
## `rot_amp` more damage from every source in CombatResolver.damage_enemy).
## Set by PlagueCloud.apply_rot(); compared with Game.elapsed, so it needs
## no ticking (and keeps running through Stasis).
var rot_until: float = 0.0
## Plague Cloud Rot: extra damage fraction taken while rotting (0..~0.3).
var rot_amp: float = 0.0
## Gravebow curse: game time (s) until which this enemy is cursed (takes
## `curse_amp` more damage from every undead source in
## CombatResolver.damage_enemy). Set by CombatResolver.curse_enemy(); timed on
## Game.elapsed like Rot. 0 = never cursed / expired.
var curse_until: float = 0.0
## Gravebow curse: extra damage fraction taken while cursed (0..1).
var curse_amp: float = 0.0
## Eclipse exposure (ultimate, CombatResolver.expose_enemy()): game time (s)
## from which this enemy takes `expose_amp` more damage from every source
## (the end of the darkness that caught it; also marks the catch). 0 = never.
var expose_from: float = 0.0
## Eclipse exposure: game time (s) until which it lasts. 0 = never / expired.
var expose_until: float = 0.0
## Eclipse exposure: extra damage fraction taken while exposed (0..1).
var expose_amp: float = 0.0
## Wither aura: game time (s) until which this enemy's armour is shredded
## (set by the Wither spell each pulse it stands inside; timed on
## Game.elapsed like Rot, so it needs no ticking). 0 = never / expired.
var wither_until: float = 0.0
## Wither aura: fraction (0..1) of armour and flat armour removed while
## shredded (CombatResolver.damage_enemy()).
var wither_shred: float = 0.0
## Banshee Dirge: game time (s) until which this enemy is weakened (its hits
## deal `weaken_cut` less, hit_mult()). Set by CombatResolver.weaken_enemy();
## timed on Game.elapsed like the curse. 0 = never weakened / expired.
var weaken_until: float = 0.0
## Banshee Dirge: fraction (0..1) of damage removed from this enemy's hits
## while weakened.
var weaken_cut: float = 0.0
## Keening Lady Dirge: game time (s) until which this enemy is silenced (its
## heals fail, CombatResolver.heal_enemy()). 0 = never silenced.
var silence_until: float = 0.0
## Banshee Dirge: length (s, after Mournsong) of the longest Dirge on this
## enemy since it was last unweakened; Requiem (CombatResolver.
## extend_weaken()) never stretches weaken_until beyond now + this.
var weaken_span: float = 0.0
## Synergy mark: game time (s) until which this enemy is staggered by an
## Abomination / Bone Colossus stomp (SynergyManager.mark_staggered(); only
## written while Flesh Rampart or Killing Field is active). 0 = never.
var staggered_until: float = 0.0
## Synergy mark: game time (s) until which this enemy is swooped by a
## Gargoyle / Cathedral Horror dive (SynergyManager.mark_swooped(); only
## written while Death from Above or The Wild Hunt is active). 0 = never.
var swooped_until: float = 0.0
## Death from Above: true once a rogue hit spent this swoop mark's dash reset
## (a new swoop mark re-arms it).
var swoop_reset_spent: bool = false
## Seconds left of the brief slowdown after a ranged unit fires.
var _shoot_slow_timer: float = 0.0
## True while a Stasis power-up holds this enemy (EnemyDirector skips its
## think() / physics_step(); drawn with an ice overlay).
var frozen: bool = false
## Seconds left of a Frost Wraith Deep Freeze (CombatResolver.freeze_enemy):
## while > 0 EnemyDirector freezes this enemy exactly like Stasis.
var freeze_timer: float = 0.0
## Seconds left of a Cathedral Horror dive stun (CombatResolver.stun_enemy):
## while > 0 EnemyDirector holds this enemy exactly like a Deep Freeze.
var stun_timer: float = 0.0
## Seconds left of a Frost Wraith chill (the slow itself is slow_timer; this
## only drives the frost tint).
var chill_timer: float = 0.0
## Facing sign (+1 right / -1 left).
var _facing: float = 1.0
## Reusable query buffer.
var _tmp: Array = []
## Engine motion (UnitMotion: body / overlay layers, bob, lean, squashes,
## lunges); created on the first activation, purely visual.
var motion: UnitMotion = null

# --- Templar rush (behavior "templar") ----------------------------------------------

## Rush state: 0 = walking, 1 = windup (lane telegraphed), 2 = rushing.
var rush_state: int = 0
## Seconds spent in the current rush state.
var rush_timer: float = 0.0
## Seconds until the next rush may start.
var rush_cd: float = 0.0
## Unit direction of the current rush.
var rush_dir: Vector2 = Vector2.RIGHT
## Distance (px) still to rush.
var rush_left: float = 0.0
## Rush data (the templar's EnemyData row; empty for other kinds).
var _rush_def: Dictionary = {}
## Instance ids of summons already hit by the current rush.
var _rush_hits: Dictionary = {}
## Whether the player was already hit by the current rush.
var _rush_hit_player: bool = false


## Activates a pooled enemy of `p_kind` using definition `def`.
## `hp_mult` is the director's time-scaling multiplier.
func activate(p_game: Game, p_kind: String, def: Dictionary, pos: Vector2, hp_mult: float, elite: bool, slot: int) -> void:
	game = p_game
	kind = p_kind
	generation += 1
	active = true
	is_elite = elite
	position = pos
	think_slot = slot
	wears = ""
	wears_class = ""
	wear_tint = Color.WHITE
	untargetable = false
	claim_radius = float(def.get("claim_radius", 0.0))
	claimer_until = 0.0
	phases_obstacles = bool(def.get("phases", false))
	floating = bool(def.get("floating", false))
	body = String(def.get("body", ""))  # Act III: machine / cyborg ("" elsewhere).
	inscribed_until = 0.0
	display_name = def["display_name"]
	max_hp = float(def["max_hp"]) * hp_mult
	move_speed = def["move_speed"]
	damage = def["damage"]
	attack_interval = def["attack_interval"]
	attack_range = def["attack_range"]
	radius = def["radius"]
	armor = def["armor"]
	xp_value = def["xp"]
	behavior = def["behavior"]
	projectile_speed = def["projectile_speed"]
	undead_damage_mult = def["undead_damage_mult"]
	heal_amount = def["heal_amount"]
	heal_interval = def["heal_interval"]
	heal_radius = def["heal_radius"]
	target_priority = def["target_priority"]
	slow_resist = float(def.get("slow_resist", 0.0))
	mass = float(def.get("mass", 1.0))
	is_reckoning = false
	is_objective = false
	is_promoted = false
	post_pos = pos
	_rush_def = def if behavior == "templar" else {}
	rush_state = 0
	rush_timer = 0.0
	rush_cd = randf_range(1.0, maxf(1.0, float(def.get("charge_cooldown", 1.0))))
	_rush_hits.clear()
	# Crimson March optional keys (absent in every Graveyard row: all off).
	is_structure = bool(def.get("is_structure", false))
	projectile_resist = float(def.get("projectile_resist", 0.0))
	aura_radius = float(def.get("aura_radius", 0.0))
	aura_damage_mult = float(def.get("aura_damage_mult", 1.0))
	aura_speed_mult = float(def.get("aura_speed_mult", 1.0))
	aura_taken_mult = float(def.get("aura_taken_mult", 1.0))
	cleave_radius = float(def.get("cleave_radius", 0.0))
	cleave_targets = int(def.get("cleave_targets", 0))
	cleave_mult = float(def.get("cleave_mult", 0.0))
	buff_time = 0.0
	buff_damage = 1.0
	buff_speed = 1.0
	buff_taken = 1.0
	# Sanctum of Judgment optional keys (absent in every Graveyard and Crimson
	# March row: all off). An always-elite kind's numbers are final.
	var always_elite := bool(def.get("always_elite", false))  # Elite by design.
	is_construct = bool(def.get("construct", false))
	is_miniboss = bool(def.get("miniboss", false))
	flat_armor = float(def.get("flat_armor", 0.0))
	_radiant = String(def.get("projectile", "")) == "radiant"
	heal_stat = String(def.get("heal_stat", "chaplain_heals"))
	holy_shield = 0.0
	holy_shield_time = 0.0
	ward_until = 0.0
	ward_resist = 0.0
	is_revived = false
	heal_override = null
	heal_override_gen = 0
	heal_override_radius = 0.0
	if always_elite:
		is_elite = true
	elif elite:
		max_hp *= EnemyData.ELITE_HP_MULT
		radius *= EnemyData.ELITE_RADIUS_MULT
		xp_value *= EnemyData.ELITE_XP_MULT
		heal_amount *= EnemyData.ELITE_HEAL_MULT
		target_priority = minf(1.0, target_priority + 0.2)
	hp = max_hp
	incoming_damage = 0.0
	attack_cd = randf() * attack_interval
	heal_cd = randf() * maxf(heal_interval, 0.1)
	target = game.player
	target_gen = 0
	targeting_player = false
	targeting_summon = false
	heal_target = null
	sep = Vector2.ZERO
	velocity = Vector2.ZERO
	slow_timer = 0.0
	slow_factor = 0.0
	flash = 0.0
	orb_hit_cd = 0.0
	engaged_timer = 0.0
	engaged_mult = 1.0
	knockback = Vector2.ZERO
	mark_time = 0.0
	rot_until = 0.0
	rot_amp = 0.0
	curse_until = 0.0
	curse_amp = 0.0
	expose_from = 0.0
	expose_until = 0.0
	expose_amp = 0.0
	wither_until = 0.0
	wither_shred = 0.0
	weaken_until = 0.0
	weaken_cut = 0.0
	silence_until = 0.0
	weaken_span = 0.0
	staggered_until = 0.0
	swooped_until = 0.0
	swoop_reset_spent = false
	_shoot_slow_timer = 0.0
	frozen = false
	freeze_timer = 0.0
	stun_timer = 0.0
	chill_timer = 0.0
	visible = true
	kit = CovenantKits.for_enemy(kit, String(def.get("kit", "")))
	if kit != null:
		kit.reset(self, def)
		game.enemies.rites.register(self)
		game.stat_add("spawned_" + kind, 1.0)
	if motion == null:
		motion = UnitMotion.new(self, _draw_body, _draw_over)
	var mscale := MotionData.BOSS_SCALE if self is Boss else (MotionData.MINIBOSS_SCALE if is_miniboss else 1.0)  # Big units move less.
	motion.reset(UnitMotion.feet_of(motion_sprite_key(), "structures/" + kind, radius), radius, mscale, is_structure)
	queue_redraw()


## Returns the enemy to an inert state (EnemyDirector pools it).
func deactivate() -> void:
	active = false
	visible = false
	incoming_damage = 0.0
	target = null
	heal_target = null
	heal_override = null
	if kit != null:
		kit.on_deactivate(self)
		game.enemies.rites.unregister(self)


## Points this healer at `ally`: whenever `ally` is wounded and within
## `reach` px it is healed first (for an external owner, e.g. Grand
## Inquisitor Seraphine on her High Confessors; the normal ally search
## already includes bosses within heal_radius). Pass null to clear.
func set_heal_override(ally: Enemy, reach: float) -> void:
	heal_override = ally
	heal_override_gen = ally.generation if ally != null else 0
	heal_override_radius = reach


## Sets the Stasis freeze state (redraws only when it changes).
func set_frozen(f: bool) -> void:
	if f != frozen:
		frozen = f
		queue_redraw()


## Tick while frozen by Stasis: only the cosmetic hit flash and the Orb
## Shield re-hit timer run; attacks, heals, rushes, slows and knockback wait.
func step_frozen(delta: float) -> void:
	orb_hit_cd -= delta
	if freeze_timer > 0.0:
		# Frost Wraith Deep Freeze (frozen-enemy-seconds stat for the autotest).
		game.stat_add("frost_frozen_seconds", minf(delta, freeze_timer))
		freeze_timer -= delta
	if stun_timer > 0.0:
		# Cathedral Horror stun (stunned-enemy-seconds stat for the autotest).
		game.stat_add("enemy_stunned_seconds", minf(delta, stun_timer))
		stun_timer -= delta
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()


## Visual hit reaction.
func on_hit() -> void:
	flash = 0.08
	if motion != null:
		motion.hit(game.elapsed)  # Engine motion: hit squash with the flash.
	queue_redraw()


## Engine motion: an attack toward world direction `dir` (zero = a slam or
## pulse) with MotionData power `power`. Visual only.
func motion_lunge(dir: Vector2, power: float) -> void:
	if motion != null:
		motion.lunge(dir, power, game.elapsed)


## Sprite key of this enemy's art (the engine-motion pivot); bosses override.
## An Ancient Eye kind's art lives in eye/ (Act II) and an Electronic Empire
## kind's in empire/ (Act III): used when it has no enemies/ art (visual only;
## every Act I kind keeps its enemies/ key).
func motion_sprite_key() -> String:
	var key := "enemies/" + kind  # Covenant soldier art.
	if not SpriteBank.has(key):
		if SpriteBank.has("eye/" + kind):
			return "eye/" + kind
		if SpriteBank.has("empire/" + kind):
			return "empire/" + kind
	return key


## Steel has no soul (Act III, EmpireRulesData.STEEL): false for a MACHINE
## (drones, turrets, mechs) and for a structure (rubble, not a corpse); true
## for every other foe. THE one gate of every corpse and raise path: Corpse
## Explosion's corpses, Raise Dead's anchors, Death Mark's Risen, the Lich's
## raise, Grave Tide and Call of the Drowned. Exactly `not is_structure` on
## Acts I and II (no machines there).
func leaves_corpse() -> bool:
	return not is_structure and body != EmpireEnemyData.MACHINE


## True for a CYBORG: raised as a temporary Risen it keeps its weapon and
## rises as a Grave Gunner (HordeDirector.raise_corpse()). False on Acts I and II.
func rises_as_gunner() -> bool:
	return body == EmpireEnemyData.CYBORG


# --- Act III: the Scrap Wastes ---
## True when this enemy's kit shield stops a friendly PROJECTILE moving with
## velocity `shot_vel` that would deal `dmg` (the Aegis Bot's frontal shield,
## AegisKit.blocks_shot()). The ONE projectile-shield check, asked by the
## friendly projectiles (ProjectileManager), the volley shots (VolleyDirector)
## and Bone Spear before they deal damage; false for every kind without such a
## kit (every Act I and II kind), so nothing changes there.
func shield_blocks(shot_vel: Vector2, dmg: float) -> bool:
	return kit != null and kit.blocks_shot(self, shot_vel, dmg)


## Local y (px, negative = up) of an over-the-head marker's centre: just
## above the top of this enemy's drawn sprite (MarkerArtData.MARKER_LIFT), or
## `fallback` (the old body-radius placement) when that is higher or the
## enemy has no sprite art. Visual only.
func marker_y(fallback: float) -> float:
	var key := motion_sprite_key()  # This enemy's art key.
	if not SpriteBank.has(key):
		return fallback
	var top := -SpriteBank.drawn_height(key) * (0.5 - SpriteData.CENTER_OFFSET)  # Sprite top (px, the sprite centre sits CENTER_OFFSET of its height above the origin).
	return minf(fallback, top - MarkerArtData.MARKER_LIFT)


## Marks this enemy for `duration` s (Volley of the Fallen mage mark).
func apply_mark(duration: float) -> void:
	if mark_time <= 0.0:
		queue_redraw()
	mark_time = maxf(mark_time, duration)


## Applies a slow of `fraction` (0..1 of speed removed) for `duration` s.
func apply_slow(fraction: float, duration: float) -> void:
	var f := fraction * (1.0 - slow_resist)
	if slow_timer <= 0.0 or f > slow_factor:
		slow_factor = f
	slow_timer = maxf(slow_timer, duration)


## Shows the Frost Wraith chill tint for `duration` s (the slow is apply_slow()).
func apply_chill(duration: float) -> void:
	if chill_timer <= 0.0:
		queue_redraw()
	chill_timer = maxf(chill_timer, duration)


# =====================================================================================
# AI
# =====================================================================================

## ~5 Hz decision step: choose what to attack / whom to heal. Aura units
## (Banner Bearer, Holy Standard) refresh their buff on nearby soldiers;
## structures pick no target.
func think() -> void:
	if aura_radius > 0.0:
		_pulse_aura()
	if kit != null:
		kit.think(self)  # Sanctum specials (CovenantKit).
	if is_structure:
		targeting_player = false
		targeting_summon = false
		return
	# Engaged by a blocking warrior: keep fighting it (user brief).
	if engaged_timer > 0.0 and target is SummonedUnit and _target_valid():
		targeting_player = false
		targeting_summon = true
		return
	match behavior:
		"purifier":
			_pick_target(EnemyData.PURIFIER_HUNT_RADIUS, true)
		"ranged":
			_pick_target(EnemyData.RANGED_DIVERT_RADIUS, false)
		"healer":
			_pick_heal_target()
			_pick_target(EnemyData.MELEE_DIVERT_RADIUS, false)
		_:
			_pick_target(EnemyData.MELEE_DIVERT_RADIUS, false)
	var d := position.distance_to(target.position)
	targeting_player = target is Necromancer and d < EnemyData.ATTACKING_PLAYER_RADIUS  # (Co-op: either necromancer.)
	targeting_summon = target is SummonedUnit and d < radius * 2.0 + 40.0


## Targets the player unless a summon within `search` px is closer (or, for
## Purifiers, unless any summon is within `search` px at all). A Bone
## Colossus in taunt reach (ColossusKit) wins over both, and a summon taunting
## under Sovereign's Decree (UltimateSystem.taunt_target()) wins over that: each
## changes only the target choice, so every kind keeps its own movement
## (enemies always advance).
func _pick_target(search: float, prefer_undead: bool) -> void:
	var decreed := game.ultimates.taunt_target(self)  # Sovereign's Decree taunt (null unless it runs).
	if decreed != null:
		if target != decreed:
			game.stat_add("decree_taunts", 1.0)
		_set_target(decreed)
		return
	var taunter := game.horde.colossi.taunt_target(self)  # null = no taunt applies.
	if taunter == null and game.coop != null:
		taunter = game.coop.taunt_target(self)  # Co-op: the other army's Decree / Colossus taunts too.
	if taunter != null:
		if target != taunter:
			game.stat_add(ColossusKit.taunt_stat(taunter), 1.0)
		_set_target(taunter)
		return
	var player := game.player
	var best: Node2D = player
	var best_d := position.distance_to(player.position)
	game.ally_grid.query(position, search, _tmp)
	var nearest: SummonedUnit = null
	var nearest_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var d := position.distance_to(u.position)
		if d < nearest_d:
			nearest_d = d
			nearest = u
	if nearest != null and (prefer_undead or nearest_d < best_d):
		best = nearest
	_set_target(best)


## Sets the attack target, remembering summon generation.
func _set_target(n: Node2D) -> void:
	target = n
	target_gen = (n as SummonedUnit).generation if n is SummonedUnit else 0


## True if `target` still refers to the same living summon / the player.
func _target_valid() -> bool:
	if target == null:
		return false
	if target is SummonedUnit:
		var u := target as SummonedUnit
		return u.active and u.generation == target_gen
	if game.coop != null:
		return not (target as Necromancer).dead  # Co-op: a downed necromancer is no target.
	return true


## Chaplain: picks the most wounded other enemy in heal radius (never a
## construct). A wounded heal override in its reach wins (set_heal_override()).
func _pick_heal_target() -> void:
	heal_target = null
	var o := heal_override  # External heal target (null = none).
	if o != null and o.active and o.generation == heal_override_gen and o.hp < o.max_hp \
			and o.position.distance_to(position) <= heal_override_radius:
		heal_target = o
		heal_target_gen = o.generation
		return
	var best_frac := EnemyData.HEAL_MIN_MISSING_FRACTION
	game.enemy_grid.query(position, heal_radius, _tmp)
	for e: Enemy in _tmp:
		if e == self or not e.active or e.is_construct:
			continue
		var frac := 1.0 - e.hp / e.max_hp
		if frac >= best_frac:
			best_frac = frac
			heal_target = e
			heal_target_gen = e.generation


## Aura (Banner Bearer / Holy Standard, GDD §7.2-§7.5): every other living
## Covenant soldier (structures and Reckoning enemies excepted, the boss
## included) inside aura_radius is buffed for MarchEnemyData.AURA_LINGER s.
## Overlapping auras keep the strongest value of each multiplier.
func _pulse_aura() -> void:
	game.enemy_grid.query(position, aura_radius, _tmp)
	var buffed := 0  # Soldiers refreshed this pulse (stat).
	for e: Enemy in _tmp:
		if e == self or not e.active or e.is_structure or e.is_reckoning:
			continue
		if e.position.distance_to(position) > aura_radius:
			continue
		if e.buff_time <= 0.0:
			e.buff_damage = aura_damage_mult
			e.buff_speed = aura_speed_mult
			e.buff_taken = aura_taken_mult
			e.queue_redraw()
		else:
			e.buff_damage = maxf(e.buff_damage, aura_damage_mult)
			e.buff_speed = maxf(e.buff_speed, aura_speed_mult)
			e.buff_taken = minf(e.buff_taken, aura_taken_mult)
		e.buff_time = MarchEnemyData.AURA_LINGER
		buffed += 1
	if buffed > 0:
		game.stat_add("march_aura_buff_pulses", float(buffed))


## Damage-dealt multiplier from an aura buff (1 when not buffed), times the
## Banshee Dirge's damage cut while weakened (CombatResolver.weaken_enemy()).
func hit_mult() -> float:
	var m := buff_damage if buff_time > 0.0 else 1.0  # Aura buff.
	if weaken_until > game.elapsed:
		m *= 1.0 - weaken_cut  # Dirge: weakened hits.
	return m


## Multiplier on incoming damage from `source`, asked by CombatResolver
## before armour: an aura buff and a tower shield against projectiles
## (MarchEnemyData.PROJECTILE_SOURCES). A Soul Nova ignores both. Graveyard
## kinds have neither, so this is exactly 1 for them.
func damage_taken_mult(source: String) -> float:
	if source == "nova":
		return 1.0
	var m := buff_taken if buff_time > 0.0 else 1.0  # Aura buff.
	if projectile_resist > 0.0 and source in MarchEnemyData.PROJECTILE_SOURCES:
		m *= 1.0 - projectile_resist
	return m


## Recomputes the cached separation push from overlapping enemies.
## Called by EnemyDirector at ~10 Hz (staggered) to keep the crowd spread.
func update_separation() -> void:
	game.enemy_grid.query(position, radius * 2.0 + 14.0, _tmp)
	var push := Vector2.ZERO
	for o: Enemy in _tmp:
		if o == self or not o.active:
			continue
		var diff := position - o.position
		var d := diff.length()
		var min_d := radius + o.radius
		if d >= min_d:
			continue
		if d < 0.01:
			diff = _overlap_dir()
			d = 1.0
		push += diff / d * (1.0 - d / min_d)
	sep = push.limit_length(1.0)


## Per-physics-tick update: movement and attacks.
func physics_step(delta: float) -> void:
	_tick_timers(delta)
	if kit != null and kit.physics(self, delta):
		return  # A Sanctum windup / cast holds still.
	if is_structure:
		_step_structure(delta)
		return
	if behavior == "templar" and _step_rush(delta):
		return
	if behavior == "consecrator":
		_step_consecrator(delta)
		return
	if not _target_valid():
		_set_target(game.player)
	var t := target
	var to_t := t.position - position
	var d := to_t.length()
	var dir := to_t / d if d > 0.001 else Vector2.ZERO
	var edge := d - radius - _radius_of(t)
	var move := Vector2.ZERO
	if behavior == "ranged" or behavior == "healer" or behavior == "banner":
		# Always advance on the player (even while shooting a summon), stopping
		# only on contact so they don't overlap him.
		var to_p := game.player.position - position
		var dp := to_p.length()
		if dp - radius - game.player.radius > EnemyData.ADVANCE_STOP_GAP and dp > 0.001:
			move = to_p / dp
		if behavior == "ranged":
			if d <= attack_range and attack_cd <= 0.0:
				attack_cd = attack_interval
				_shoot_slow_timer = EnemyData.SHOOT_SLOW_TIME
				motion_lunge(dir, MotionData.POWER_SHOT)
				if kit != null and kit.fire_ranged(self, t, dir, damage * game.enemies.damage_mult * hit_mult()):
					pass  # Act III: an Empire kit fired through EmpireShots (Line of Fire).
				elif _radiant:
					game.projectiles.fire_hostile(position, dir, damage * game.enemies.damage_mult * hit_mult(), projectile_speed, undead_damage_mult,
							Projectile.Kind.RADIANT_BOLT, kind)
				else:
					game.projectiles.fire_hostile(position, dir, damage * game.enemies.damage_mult * hit_mult(), projectile_speed, undead_damage_mult)
		elif behavior == "healer":
			_try_heal()
	elif edge > attack_range:
		move = dir
	# Anyone in contact can strike except archers (chaplains swing weakly).
	if behavior != "ranged" and edge <= attack_range and attack_cd <= 0.0:
		_melee_hit(t, dir)
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	if engaged_timer > 0.0:
		spd *= engaged_mult
	if _shoot_slow_timer > 0.0:
		spd *= EnemyData.SHOOT_SLOW_MULT
	if buff_time > 0.0:
		spd *= buff_speed  # Banner / Holy Standard aura.
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH
	position += (velocity + knockback) * delta
	_update_facing()


## Structures stand still (no knockback, no separation); a supply cart rolls
## toward `post_pos` at its move speed (slows apply) until MarchDirector
## takes it off the field.
func _step_structure(delta: float) -> void:
	knockback = Vector2.ZERO
	if behavior != "cart":
		velocity = Vector2.ZERO
		return
	var to := post_pos - position  # Remaining path.
	var d := to.length()
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)  # Cart speed this tick.
	velocity = to / d * spd if d > 2.0 else Vector2.ZERO
	position += velocity * delta
	_update_facing()


## Desecration-event Chaplain: walk to the grave and hold position there
## while StageDirector runs the channel. Never attacks.
func _step_consecrator(delta: float) -> void:
	var to := post_pos - position
	var d := to.length()
	var move := to / d if d > 2.0 else Vector2.ZERO
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH * 0.5
	position += (velocity + knockback) * delta
	_update_facing()


## Templar Knight rush. Returns true while a windup / rush owns this tick.
## Walking templars start a rush when the player is within the charge range
## and the lane is long enough (obstacles cut it short).
func _step_rush(delta: float) -> bool:
	match rush_state:
		1:
			rush_timer += delta
			velocity = Vector2.ZERO
			if rush_timer >= float(_rush_def["charge_telegraph"]):
				rush_state = 2
				rush_timer = 0.0
			return true
		2:
			_rush_move(delta)
			return true
	rush_cd -= delta
	if rush_cd > 0.0 or engaged_timer > 0.0:
		return false
	var to_p := game.player.position - position
	var d := to_p.length()
	if d < float(_rush_def["charge_range_min"]) or d > float(_rush_def["charge_range_max"]):
		return false
	rush_dir = to_p / d
	rush_left = game.arena.clear_length(position, rush_dir, float(_rush_def["charge_length"]), radius * 0.8)
	rush_cd = float(_rush_def["charge_cooldown"])
	if rush_left < float(_rush_def["charge_range_min"]):
		return false
	rush_state = 1
	rush_timer = 0.0
	_rush_hits.clear()
	_rush_hit_player = false
	velocity = Vector2.ZERO
	game.effects.telegraph_line(position, position + rush_dir * rush_left, float(_rush_def["charge_width"]), float(_rush_def["charge_telegraph"]), self)
	game.stat_add("templar_charges", 1.0)
	return true


## Moves along the rush lane: hurts the player once, shoves summons aside,
## and stops dead on a warrior heavy enough to body-block it.
func _rush_move(delta: float) -> void:
	var spd := float(_rush_def["charge_speed"])
	var step_len := minf(spd * delta, rush_left)
	position += rush_dir * step_len
	rush_left -= step_len
	velocity = rush_dir * spd
	var hit_r := float(_rush_def["charge_width"]) * 0.5
	var dmg := float(_rush_def["charge_damage"]) * game.enemies.damage_mult * hit_mult()
	var player := game.player
	if not _rush_hit_player and player.position.distance_to(position) <= hit_r + player.radius:
		_rush_hit_player = true
		game.combat.damage_player(dmg, "templar_charge")
	game.ally_grid.query(position, hit_r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _rush_hits.has(u.get_instance_id()):
			continue
		var rel := u.position - position
		if rel.length() > hit_r + u.radius:
			continue
		_rush_hits[u.get_instance_id()] = true
		if u.block_mass >= float(_rush_def["charge_block_mass"]):
			# Body-blocked by a warrior: the rush ends here.
			rush_left = 0.0
			game.effects.slash(position + rush_dir * radius, rush_dir, Palette.COLD_BLUE, radius * 1.6)
			game.stat_add("templar_charges_blocked", 1.0)
			game.combat.damage_unit(u, dmg * undead_damage_mult * 0.5, "templar_charge")
			break
		var side := rel - rush_dir * rel.dot(rush_dir)
		var push := side.normalized() if side.length() > 0.1 else Vector2(-rush_dir.y, rush_dir.x)
		u.position += push * float(_rush_def["charge_knockback"])
		game.combat.damage_unit(u, dmg * undead_damage_mult, "templar_charge")
	if rush_left <= 0.0:
		rush_state = 0
		velocity = Vector2.ZERO


## Warrior blocking (user brief): pushes this enemy out of any overlapping
## blocker using the spatial hash (no physics bodies). The correction is split
## by mass so warriors hold the line while the boss can shove them. Touching
## a blocker "engages" the enemy: it is slowed, retargets that warrior and may
## eat a shield bash. When several blockers touch it in the same tick
## (warriors, Death Knights, Corpse Abominations) the STRONGEST slow applies
## (lowest engaged_speed_mult); slows never multiply together, and the order
## the spatial hash returns blockers in no longer matters. Called by
## EnemyDirector right after physics_step().
func resolve_blocking() -> void:
	var reach := game.horde.block_query_radius if game.coop == null else game.coop.block_query_radius()  # Widest blocker (co-op: of every army).
	game.ally_grid.query(position, radius + reach, _tmp)
	var touched := false  # A blocker already engaged this enemy this tick.
	for u: SummonedUnit in _tmp:
		if not active:
			return
		if not u.active or u.block_radius <= 0.0 or u.state == SummonedUnit.State.SPAWNING:
			continue
		var diff := position - u.position
		var d := diff.length()
		var min_d := radius + u.block_radius
		if d >= min_d:
			continue
		var n := diff / d if d > 0.01 else _overlap_dir()
		var overlap := min_d - d
		# A standing structure never moves: the warrior takes the whole correction.
		var enemy_share := 0.0 if (is_structure and behavior != "cart") else u.block_mass / (u.block_mass + mass)
		position += n * overlap * enemy_share
		u.position -= n * overlap * (1.0 - enemy_share)
		engaged_timer = EnemyData.ENGAGED_TIME
		engaged_mult = minf(engaged_mult, u.engaged_speed_mult) if touched else u.engaged_speed_mult
		touched = true
		if target != u:
			_set_target(u)
		u.try_bash(self, n)


## Shared countdowns (flash, slow, cooldowns).
func _tick_timers(delta: float) -> void:
	attack_cd -= delta
	heal_cd -= delta
	orb_hit_cd -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
	if engaged_timer > 0.0:
		engaged_timer -= delta
	if _shoot_slow_timer > 0.0:
		_shoot_slow_timer -= delta
	if mark_time > 0.0:
		mark_time -= delta
		if mark_time <= 0.0:
			queue_redraw()
	if chill_timer > 0.0:
		chill_timer -= delta
		if chill_timer <= 0.0:
			queue_redraw()
	if curse_until > 0.0 and curse_until <= game.elapsed:
		curse_until = 0.0  # Gravebow curse expired: drop its tint.
		queue_redraw()
	if weaken_until > 0.0 and weaken_until <= game.elapsed:
		weaken_until = 0.0  # Banshee Dirge expired: drop its mark.
		weaken_cut = 0.0
		queue_redraw()
	if buff_time > 0.0:
		buff_time -= delta
		if buff_time <= 0.0:
			buff_damage = 1.0
			buff_speed = 1.0
			buff_taken = 1.0
			queue_redraw()
	if holy_shield_time > 0.0:
		holy_shield_time -= delta
		if holy_shield_time <= 0.0:
			holy_shield = 0.0  # The Confessor's shield fades unbroken.
			queue_redraw()
	if ward_until > 0.0 and ward_until <= game.elapsed:
		ward_until = 0.0  # Out of every Sun Paladin's aura: the ward drops.
		ward_resist = 0.0
		queue_redraw()
	if knockback != Vector2.ZERO:
		knockback = knockback.move_toward(Vector2.ZERO, EnemyData.KNOCKBACK_DECAY * delta)
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()


## Mirrors the sprite to face the movement direction.
func _update_facing() -> void:
	if absf(velocity.x) > 5.0:
		var f := signf(velocity.x)
		if f != _facing:
			_facing = f
			scale.x = _facing
			if hp < max_hp:
				queue_redraw()  # HP bar counter-flip depends on facing


## Stable pseudo-random push direction for an exactly overlapping body.
## Derived from the think slot and pool generation, not the instance id:
## ids depend on thread timing (audio synthesis allocates objects on worker
## threads), which made autotest runs non-deterministic.
func _overlap_dir() -> Vector2:
	return Vector2.from_angle(float((think_slot * 157 + generation * 61) % 628) * 0.01)


## Body radius of the player or a summon.
func _radius_of(n: Node2D) -> float:
	if n is SummonedUnit:
		return (n as SummonedUnit).radius
	return game.player.radius


## Melee strike on the player or a summon (undead bonus applies to summons).
func _melee_hit(t: Node2D, dir: Vector2) -> void:
	attack_cd = attack_interval
	var dmg := damage * game.enemies.damage_mult * hit_mult()
	game.effects.slash(position + dir * radius, dir, Palette.SILVER, radius * 1.2)
	motion_lunge(dir, MotionData.POWER_MELEE)
	if t is SummonedUnit:
		game.combat.damage_unit(t as SummonedUnit, dmg * undead_damage_mult, kind)
		if cleave_radius > 0.0:
			_cleave(t as SummonedUnit, dmg * undead_damage_mult * cleave_mult)
	else:
		game.combat.damage_player(dmg, kind, t as Necromancer)  # (Co-op: that necromancer.)


## Halberd sweep (MarchEnemyData cleave_*): up to cleave_targets OTHER
## summons within cleave_radius px of the struck one take `dmg`.
func _cleave(struck: SummonedUnit, dmg: float) -> void:
	game.ally_grid.query(struck.position, cleave_radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0  # Extra summons hit so far.
	for u: SummonedUnit in _tmp:
		if hits >= cleave_targets:
			break
		if u == struck or not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(struck.position) > cleave_radius + u.radius:
			continue
		game.combat.damage_unit(u, dmg, kind + "_cleave")
		hits += 1
	if hits > 0:
		game.stat_add("march_cleave_hits", float(hits))
		game.effects.slash(struck.position, struck.position - position, Palette.FLAME, cleave_radius)


## Chaplain heal on the chosen wounded ally.
func _try_heal() -> void:
	if heal_cd > 0.0 or heal_target == null:
		return
	if not heal_target.active or heal_target.generation != heal_target_gen:
		heal_target = null
		return
	var reach := heal_override_radius if heal_target == heal_override else heal_radius  # Heal range (px).
	if heal_target.position.distance_to(position) > reach:
		return
	heal_cd = heal_interval
	if game.combat.heal_enemy(heal_target, heal_amount, self) > 0.0:  # Fails while silenced (Keening Lady).
		game.effects.beam(position, heal_target.position, Palette.GOLD)
		game.stat_add(heal_stat, 1.0)
		motion_lunge(heal_target.position - position, MotionData.POWER_CAST)


## Draws in three layers (engine motion, UnitMotion): this node draws what
## lies on the ground under the body, then queues the body layer (the only
## one that moves) and the overlay layer above it. Before the first
## activation (no layers yet) everything is drawn here.
func _draw() -> void:
	_draw_under()
	if motion != null:
		motion.redraw_layers()
	else:
		_draw_body(self)
		_draw_over(self)


## Ground layer (this node): aura reach and Sanctum auras. Bosses override.
func _draw_under() -> void:
	if aura_radius > 0.0:
		MarchGlyphs.draw_aura(self, aura_radius)  # Banner / Holy Standard reach.
	if kit != null:
		kit.draw_under(self)  # Sanctum auras.


## Body layer on `ci`: the sprite or glyph. Bosses override.
func _draw_body(ci: CanvasItem) -> void:
	if wears != "":
		# A Drowned Thrall: the claimed summon's sprite, tinted; its code
		# glyph with a drowned wash when it has no art.
		if not SpriteBank.draw(ci, wears, Vector2.ZERO, flash > 0.0, wear_tint):
			Glyphs.draw_summon(ci, wears_class, Vector2.ZERO, radius, flash > 0.0)
			ci.draw_circle(Vector2.ZERO, radius * 1.05, Color(wear_tint, 0.35))
		return
	if kit != null and kit.draws_body(self):
		kit.draw_body(self, ci)  # Act III, the Scrap Wastes: a kit that draws its own body (rockets, decoys).
		return
	Glyphs.draw_enemy(ci, kind, Vector2.ZERO, radius, flash > 0.0, is_elite)


## Overlay layer on `ci`: casting glows, shields, marks, the HP bar and the
## frozen / stunned / chilled look. Bosses override.
func _draw_over(ci: CanvasItem) -> void:
	if kit != null:
		kit.draw_over(self, ci)  # Sanctum casting glows, beams.
	if holy_shield > 0.0:
		SanctumGlyphs.draw_holy_shield(ci, radius)  # High Confessor shield.
	if ward_until > 0.0:
		SanctumGlyphs.draw_ward(ci, Vector2(-radius * 1.05, -radius * 1.2), 3.5)  # Sun Paladin ward.
	var head := marker_y(-radius * 2.4)  # Over-the-head marker height (px).
	if buff_time > 0.0:
		MarchGlyphs.draw_buffed(ci, Vector2(0, head), 4.0)  # Aura buff chevron.
	if mark_time > 0.0:
		var my := head - (MarkerArtData.MARKER_STACK if buff_time > 0.0 else 0.0)  # Above the chevron when both show.
		if not SpriteBank.draw_flat(ci, MarkerArtData.MAGE_MARK, Vector2(0, my), 0.0):
			ProgressionGlyphs.draw_mage_mark(ci, Vector2(0, my), 4.0)  # Volley mark (code shape without its art).
	if curse_until > 0.0:
		GravebowColossusGlyphs.draw_curse(ci, Vector2.ZERO, radius)  # Gravebow curse tint.
	if weaken_until > 0.0:
		WarbandGlyphs.draw_dirge(ci, Vector2.ZERO, radius, silence_until > game.elapsed)  # Banshee Dirge mark.
	if hp < max_hp:
		# The node is mirrored via scale.x; counter-flip so the bar always
		# fills left-to-right.
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
		Glyphs.hp_bar(ci, Vector2(0, -radius * 1.8), radius * 2.0, hp / max_hp, Palette.HP_ENEMY)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen and stun_timer > 0.0 and freeze_timer <= 0.0:
		ReaperHorrorGlyphs.draw_stun(ci, Vector2(0, marker_y(-radius * 1.35)), radius)  # Stunned, not frozen (Stasis on top shows the stun too).
	elif frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)
	elif chill_timer > 0.0:
		SummonGlyphs.draw_chill(ci, Vector2.ZERO, radius)
