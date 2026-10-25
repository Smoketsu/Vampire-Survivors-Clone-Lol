## PantheonRules — the Olympian Republic's shared rules (Act IV; GDD §15.0
## "Act IV foundation (phase 1)", "Wrath of the Gods", "Phalanx" and "Glory"),
## run as `Game.pantheon`. Null on Acts I, II and III (created in Game._ready()
## only for a stage whose STAGE has "pantheon": true), except that a Pantheon
## kind forced onto any other stage with --spawn= creates it on its first
## activation through Game.pantheon_rules() (PantheonKit.reset()), so a kind
## works anywhere (as Act III's Empire kinds do). Owns ONE path per rule:
##   wrath   — DivineWrath: WRATH OF THE GODS. One scheduler of the stage's
##             telegraphed hazard (STAGE "wrath": Poseidon's waves, Zeus's
##             lightning or Hades' fissures), hitting both armies through
##             CombatResolver; at 0:00 the Twilight of the Gods fires every
##             kind together, faster each minute (RECKONING "twilight").
##   phalanx — Phalanx: PHALANX. Shield walls lock and break; the front test is
##             hit_from_front() below (the ONE direction test, also for phase
##             2's Achilles' heel and the Legionary's testudo), applied once in
##             CombatResolver.damage_enemy() through directed_hit_mult().
##   glory   — Glory: GLORY. Heroes' stacks (the summon-kill hook in
##             CombatResolver.damage_unit()) and their payout on death (the
##             kill hook in CombatResolver._kill_enemy()).
## Stepped by Game after the enemies and before the obstacle push-out (the
## waves carry bodies, then Arena.resolve_all() pushes them out of obstacles).
## Determinism: only the seeded gameplay RNG, and only while it exists (Act IV,
## or a forced Pantheon kind).
class_name PantheonRules
extends Node2D

## Owning run.
var game: Game
## Wrath of the Gods (child node, the hazards' telegraphs on the ground).
var wrath: DivineWrath
## Phalanx (child node, the locked shield lines above the units).
var phalanx: Phalanx
## Glory (the heroes' stacks and payouts; no drawing of its own).
var glory: Glory
## Heroes named so far (the next named variant: names[n % size]).
var heroes_named: int = 0


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "PantheonRules"
	wrath = DivineWrath.new(p_game)
	add_child(wrath)
	phalanx = Phalanx.new(p_game)
	add_child(phalanx)
	glory = Glory.new(p_game)


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## the wrath's scheduler and hazards, then the shield walls.
func step(delta: float) -> void:
	wrath.step(delta)
	phalanx.step(delta)


# =====================================================================================
# The direction test (Phalanx; phase 2: Achilles' heel, the Legionary's testudo)
# =====================================================================================

## The way enemy `e` faces (unit vector): its PantheonKit's facing, else a
## boss's `pantheon_facing` property when it has one (phase 2's Achilles),
## else its sprite's left / right mirror.
static func facing_of(e: Enemy) -> Vector2:
	if e.kit is PantheonKit:
		return (e.kit as PantheonKit).facing
	var f: Variant = e.get("pantheon_facing")  # A Pantheon boss's own facing (null when none).
	if f is Vector2:
		return f
	return Vector2(signf(e.scale.x) if e.scale.x != 0.0 else 1.0, 0.0)


## THE one direction test: true when a hit coming from world point `origin`
## strikes enemy `e`'s FRONT, the cone of `half_angle` rad each side of its
## facing (PantheonRulesData.PHALANX front_half_angle by default). A hit from
## the body's own centre counts as the front.
static func hit_from_front(e: Enemy, origin: Vector2, half_angle: float = -1.0) -> bool:
	var to := origin - e.position  # From the body toward where the hit came from.
	if to.length_squared() < 0.0001:
		return true
	var h := half_angle if half_angle >= 0.0 else float(PantheonRulesData.PHALANX["front_half_angle"])
	return to.normalized().dot(facing_of(e)) >= cos(h)


# --- Act IV: the Shores of Ilion ---
## True when a hit coming from world point `origin` strikes enemy `e` from
## BEHIND: within `half_angle` rad of straight behind it (the same facing as
## hit_from_front(), the rear cone; PantheonRulesData.PHALANX front_half_angle
## by default). False for a hit from the body's own centre and for an arcing
## hit (CombatResolver.FROM_ABOVE). Mortal Heel and Achilles' back read it.
static func hit_from_behind(e: Enemy, origin: Vector2, half_angle: float = -1.0) -> bool:
	if origin == CombatResolver.FROM_ABOVE:
		return false
	var to := origin - e.position  # From the body toward where the hit came from.
	if to.length_squared() < 0.0001:
		return false
	var h := half_angle if half_angle >= 0.0 else float(PantheonRulesData.PHALANX["front_half_angle"])
	return to.normalized().dot(-facing_of(e)) >= cos(h)


## Multiplier on a DIRECTED hit (CombatResolver.damage_enemy() with an origin)
## of `amount` on `e` from `origin`, `shot` true for a projectile, tagged
## `source`: the Phalanx's locked fronts (Phalanx.directed_hit_mult()), else a
## Pantheon boss's own `directed_hit_mult(origin, shot, source)` method when
## it has one (phase 2's Achilles), else 1.
func directed_hit_mult(e: Enemy, origin: Vector2, shot: bool, source: String) -> float:
	if e.kit is PantheonKit:
		return phalanx.directed_hit_mult(e, origin, shot, source)
	# --- Act IV: the Shores of Ilion --- an arcing hit from above
	# (CombatResolver.FROM_ABOVE) reaches a boss only through its own
	# above_hit_mult(source) (Achilles); every other boss ignores it.
	if origin == CombatResolver.FROM_ABOVE:
		return float(e.call("above_hit_mult", source)) if e.has_method("above_hit_mult") else 1.0
	if e.has_method("directed_hit_mult"):
		return float(e.call("directed_hit_mult", origin, shot, source))
	return 1.0


# =====================================================================================
# Hooks (CombatResolver, Enemy)
# =====================================================================================

## A summon `u` was killed by enemy `by` (CombatResolver.damage_unit()): Glory.
func on_summon_killed(_u: SummonedUnit, by: Enemy) -> void:
	glory.on_summon_killed(by)


## Enemy `e` was killed (CombatResolver._kill_enemy()): a corpse swallowed by an
## open fissure is counted, a hero pays out its Glory.
func on_enemy_killed(e: Enemy) -> void:
	if wrath.swallows(e.position, e.radius):
		game.stat_add("wrath_corpses_swallowed", 1.0)
	glory.on_enemy_killed(e)


## True when a corpse at `pos` (body radius `r`) is swallowed (an open Hades
## fissure under it): Enemy.leaves_corpse(), the one corpse gate, reads it.
func swallows_corpse(pos: Vector2, r: float) -> bool:
	return wrath.swallows(pos, r)


## The next named variant of `names` (in turn, no RNG).
func next_hero_name(names: Array) -> String:
	var n := String(names[heroes_named % names.size()])
	heroes_named += 1
	return n


## Plays the sound of Pantheon event `event` (PantheonRulesData.SOUNDS) at `pos`.
func play_sound(event: String, pos: Vector2 = Vector2.INF) -> void:
	var id := String(PantheonRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


# =====================================================================================
# Autotest
# =====================================================================================

## Autopilot hint (the autotest bot): a push off every telegraphed bolt circle
## and every telegraphed or open fissure at `p` (the waves cannot be dodged).
func danger_push(p: Vector2) -> Vector2:
	return wrath.danger_push(p)
