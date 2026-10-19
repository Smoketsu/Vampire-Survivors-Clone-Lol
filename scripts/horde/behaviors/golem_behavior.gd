## GolemBehavior — the Bone Golem's kit ("bulwark", UnitData; content wave 2,
## GDD §15.0 "Bone Golem (content wave 2)"). The Golem is an ordinary melee
## "guard" summon and a physical blocker (block_radius / block_mass, resolved
## by Enemy.resolve_blocking() like a warrior's). On top of that:
##   * The slam: every landed melee strike is a two-handed slam. After the hit
##     on its target (the shared melee path), on_melee_hit() splashes
##     slam_fraction of the unit's damage onto every OTHER foe within
##     slam_radius px of the struck one (source "golem_slam"). The slam's volley (a ring of bone shards) is
##     the class's attack-triggered volley (VolleyData, from class Lv 3).
##   * Bulwark: think() plants the Golem every bulwark_cooldown s once
##     bulwark_min_enemies foes stand within bulwark_trigger px (or an elite /
##     the boss). It is NOT a CASTING special: for bulwark_duration s the
##     Golem is rooted (rooted(): SummonedUnit._step_movement() keeps it still,
##     but it still thinks and slams), its block mass is bulwark_mass (nothing
##     shoves it or walks through it: Enemy.resolve_blocking()'s push-out on
##     the spatial hash, no physics engine) and taunt_reach() reports
##     bulwark_reach, so ColossusKit's taunt list draws every foe within it onto
##     the Golem (bosses, Reckoning foes and structures ignore taunts).
##   * Ossuary Hunger: GolemKit (HordeDirector.golems) calls absorb() when one
##     of the army's summons dies near this Golem: +hunger_hp max HP per body,
##     up to hunger_cap, applied as a per-unit multiplier on the director's
##     effective max HP (adjust_stats(), called at the end of every
##     SummonedUnit.apply_stats(), so a stat refresh keeps the growth; HP % is
##     preserved, GDD §34), and the body is drawn up to hunger_size bigger
##     (UnitMotion.set_size(), visual only).
## The Ossuary Titan (its evolution, SummonEvolutionData special_set) keeps this
## kit; GolemKit adds its heal, barrier and death wall.
## Determinism: positions and game time only; the first cooldown is randomised
## by the seeded global RNG (SummonBehavior.reset()).
## Stats: golem_slams, golem_slam_hits, golem_bulwarks, golem_bulwark_seconds.
class_name GolemBehavior
extends SummonBehavior

## Damage source tag of the slam's splash (PassiveData.MINION_SPECIAL_SOURCES).
const SLAM_SOURCE: String = "golem_slam"
## Effect strip played where a slam lands (assets/sprites/effects/<id>.png; a
## plain ring without the art).
const SLAM_ANIM: String = "golem_slam"

## Seconds of Bulwark left (0 = not planted).
var planted_left: float = 0.0
## Bodies this Golem absorbed since it rose (Ossuary Hunger).
var absorbed: int = 0
## Max-HP growth from Ossuary Hunger (fraction, 0..hunger_cap).
var growth: float = 0.0
## The unit's block mass without the Bulwark (restored when the plant ends).
var _base_mass: float = 0.0
## Game time (s) until which the Ossuary Titan's absorb barrier is recharging.
var barrier_ready_at: float = 0.0
## Reusable enemy query buffer.
var _buf: Array = []


## Full Bulwark cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("bulwark_cooldown", 12.0))


## Fresh activation: no plant, no growth; registers with the director's
## GolemKit (created on the first Golem, so runs without one never make it).
func reset(u: SummonedUnit) -> void:
	super.reset(u)
	planted_left = 0.0
	absorbed = 0
	growth = 0.0
	barrier_ready_at = 0.0
	_base_mass = u.block_mass
	u.director.golem_kit().on_golem_risen(u)


## Death / pooling: drops the plant and the growth (a stale behaviour on a
## pooled node must change nothing in adjust_stats()).
func on_deactivate(u: SummonedUnit) -> void:
	super.on_deactivate(u)
	planted_left = 0.0
	absorbed = 0
	growth = 0.0


## Plants the Bulwark when enough foes crowd the Golem. Never takes the
## decision (returns false): a planted Golem keeps choosing targets and slams.
func think(u: SummonedUnit) -> bool:
	if planted_left > 0.0 or special_cd > 0.0 or u.special.is_empty():
		return false
	var r := float(u.special["bulwark_trigger"])  # Trigger radius (px).
	u.game.enemy_grid.query(u.position, r + u.radius + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var n := 0  # Foes inside the trigger radius.
	var heavy := false  # An elite or the boss is inside.
	for e: Enemy in _buf:
		if e.active and not e.is_structure and e.position.distance_to(u.position) <= r + u.radius + e.radius * 0.5:
			n += 1
			heavy = heavy or e.is_elite or e.is_boss or e.is_miniboss
	if n < int(u.special["bulwark_min_enemies"]) and not heavy:
		return false
	_plant(u)
	return false


## Ticks the cooldown (base class) and the plant.
func physics(u: SummonedUnit, delta: float) -> bool:
	if planted_left > 0.0:
		planted_left -= delta
		u.game.stat_add("golem_bulwark_seconds", delta)
		if planted_left <= 0.0:
			_unplant(u)
	return super.physics(u, delta)


## While planted, foes within slam reach score planted_reach_bonus and the
## others lose planted_far_penalty (it cannot walk to them), so a rooted Golem
## slams what the taunt draws in; 0 otherwise (the shared "guard" scoring).
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	if planted_left <= 0.0:
		return 0.0
	var edge := u.position.distance_to(e.position) - u.radius - e.radius  # Edge gap (px).
	if edge <= u.attack_range + UnitData.MELEE_TOLERANCE:
		return float(u.special.get("planted_reach_bonus", 0.0))
	return -float(u.special.get("planted_far_penalty", 0.0))


## True while the Bulwark roots the Golem (SummonedUnit._step_movement()).
func rooted() -> bool:
	return planted_left > 0.0


## Taunt reach while planted (ColossusKit.refresh()); 0 otherwise.
func taunt_reach(u: SummonedUnit) -> float:
	return float(u.special.get("bulwark_reach", 0.0)) if planted_left > 0.0 else 0.0


## Per-unit stats after the director's stats were applied (SummonedUnit.
## apply_stats()): the Ossuary Hunger growth on max HP, the Bulwark's block
## mass while planted and the drawn size. A no-op after a reset.
func adjust_stats(u: SummonedUnit) -> void:
	_base_mass = u.block_mass
	if growth > 0.0:
		u.max_hp *= 1.0 + growth
	if planted_left > 0.0 and u.special.has("bulwark_mass"):
		u.block_mass = float(u.special["bulwark_mass"])
	_apply_size(u)


## Ossuary Hunger: one body absorbed. Raises the growth (capped), keeps the HP
## fraction (GDD §34) and grows the drawing. Returns the growth gained (0 at
## the cap; the body is still counted).
func absorb(u: SummonedUnit) -> float:
	absorbed += 1
	var cap := float(u.special.get("hunger_cap", 0.6))  # Max growth.
	var old := growth  # Growth before this body.
	growth = minf(cap, float(absorbed) * float(u.special.get("hunger_hp", 0.04)))
	if growth <= old:
		return 0.0
	var frac := u.hp / maxf(u.max_hp, 1.0)  # HP fraction kept.
	u.max_hp = u.max_hp / (1.0 + old) * (1.0 + growth)
	u.hp = u.max_hp * frac
	_apply_size(u)
	u.queue_redraw()
	return growth - old


## The slam's splash and impact after a landed melee strike on `e`.
func on_melee_hit(u: SummonedUnit, e: Enemy, _dealt: float) -> void:
	var game := u.game
	var center := e.position  # Impact point (the struck foe may have died).
	var r := float(u.special.get("slam_radius", 40.0))  # Splash radius (px).
	var dmg := u.damage * float(u.special.get("slam_fraction", 0.6))  # Splash damage per foe.
	game.enemy_grid.query(center, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var victims: Array = []  # Own copy: kills may run other queries.
	for o: Enemy in _buf:
		if o != e and o.active and o.position.distance_to(center) <= r + o.radius:
			victims.append(o)
	for o: Enemy in victims:
		if o.active:
			game.combat.damage_enemy(o, dmg, SLAM_SOURCE)
	game.effects.ring(center, r, Palette.BONE, 0.3, SLAM_ANIM)
	Juice.fx.burst(center, Palette.BONE, Palette.STONE, 8, r * 1.6, 0.4, 2.0)
	game.shake(float(u.special.get("slam_shake", 1.5)))
	Sfx.play("abom_stomp", center, 1.25)
	game.stat_add("golem_slams", 1.0)
	game.stat_add("golem_slam_hits", float(victims.size() + 1))


## Starts a Bulwark plant.
func _plant(u: SummonedUnit) -> void:
	var game := u.game
	special_cd = cooldown(u)
	planted_left = float(u.special["bulwark_duration"])
	_base_mass = u.block_mass
	u.block_mass = float(u.special["bulwark_mass"])
	u.velocity = Vector2.ZERO
	u.clear_target()  # Re-chosen in this same think() with the planted scoring (score_bonus()).
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_MELEE)  # Engine motion: it sets its feet (visual only).
	game.effects.ring(u.position, float(u.special["bulwark_reach"]), Palette.BONE, 0.45)
	game.effects.ring(u.position, u.block_radius * 1.4, Palette.STONE, 0.5)
	Sfx.play("abom_stomp", u.position, 0.8)
	game.stat_add("golem_bulwarks", 1.0)
	u.queue_redraw()


## Ends the plant: the normal block mass returns.
func _unplant(u: SummonedUnit) -> void:
	planted_left = 0.0
	u.block_mass = _base_mass
	u.queue_redraw()


## Drawn size of the body: 1 + hunger_size x (growth / hunger_cap).
func _apply_size(u: SummonedUnit) -> void:
	if u.motion == null:
		return
	var cap := float(u.special.get("hunger_cap", 0.6))  # Max growth.
	var k := 1.0 + float(u.special.get("hunger_size", 0.0)) * clampf(growth / maxf(cap, 0.01), 0.0, 1.0)  # Size factor.
	u.motion.set_size(k)


## While planted: a ring of bone stakes at its feet and the faint taunt reach.
func draw_under(u: SummonedUnit) -> void:
	if planted_left <= 0.0:
		return
	world_space(u)
	var reach := float(u.special.get("bulwark_reach", 120.0))  # Taunt reach (px).
	var k := clampf(planted_left / 0.4, 0.0, 1.0)  # Fades out over the last 0.4 s.
	u.draw_arc(Vector2.ZERO, reach, 0.0, TAU, 48, Color(Palette.BONE, 0.18 * k), 1.5)
	GolemGlyphs.draw_bulwark_stakes(u, Vector2(0, u.radius * 0.55), u.block_radius, k)
	body_space(u)
