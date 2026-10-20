## TerrainSlow — the ONE path for slows that come from the GROUND under a body
## (Act II, GDD §15.0 "Gullhaven Harbour (Act II phase 2)"): the Harbour's tide
## water today, the Archive's ink tomorrow. Whatever lays slowing ground calls
## these helpers instead of touching the bodies' speed fields itself, so the
## counter-passive Brinewalker (PassiveData "brinewalker": "water and ink slow
## the necromancer less, and summons from Lv 3") applies in one place:
##   slow_player(game, f, linger)    — the necromancer (Necromancer.terrain_slow,
##                                     read once in Necromancer.step()).
##   slow_summon(game, u, f, linger) — a summon, through the ground-slow fields
##                                     the holy zones already use
##                                     (SummonedUnit.holy_slow / holy_slow_timer,
##                                     read in SummonedUnit._step_movement()).
## Enemies are slowed by their own data path (Enemy.apply_slow(); the swimmers
## are skipped by the caller), never through here: Brinewalker is the
## necromancer's passive and only helps his side.
## Like every slow, a stronger one already running wins (no stacking); the
## timer is refreshed to at least `linger` s. Deterministic, no RNG; a no-op
## unless something calls it (Act I never does).
## Act III, the Assembly Halls (GDD §15.0 "The Assembly Halls (Act III phase
## 2)"): the ground can also PUSH. A conveyor belt carries everyone standing on
## it along at a steady speed (owner-approved proposal: "belt lanes carry
## everyone along ... which drags enemies and your army out of position"), one
## ground rule for every body, so it lives here too:
##   push_player(game, v, delta)     — the necromancer (never during Grave Step).
##   push_summon(game, u, v, delta)  — a summon on the ground (not a flying
##                                     Grave Drone or a swooping Gargoyle).
##   push_enemy(game, e, v, delta)   — an enemy on the ground (not a flying
##                                     drone, a structure, the boss or a miniboss).
## `v` is the belt's velocity (px/s); each call moves the body by v * delta
## before Arena.resolve_all() pushes it out of obstacles. Brinewalker is about
## water and ink and does not touch a belt. Only AssemblyDirector calls these,
## so every other stage is unchanged.
class_name TerrainSlow
extends RefCounted


## Fraction (0..1) of move speed the necromancer loses on slowing ground of
## base strength `fraction`, after Brinewalker (PassiveData "water_slow_cut").
static func player_fraction(game: Game, fraction: float) -> float:
	var cut := game.abilities.passive_value("brinewalker", "water_slow_cut")  # 0 when not owned; 1 at Lv 5.
	return maxf(0.0, fraction * (1.0 - cut))


## Fraction (0..1) a summon loses on the same ground: Brinewalker helps the
## army too once it reaches PassiveData.BRINEWALKER_SUMMON_LEVEL.
static func summon_fraction(game: Game, fraction: float) -> float:
	if game.abilities.passive_level("brinewalker") >= PassiveData.BRINEWALKER_SUMMON_LEVEL:
		return player_fraction(game, fraction)
	return fraction


## Slows the necromancer by `fraction` (before Brinewalker) for at least
## `linger` s. Returns the fraction applied (0 = fully resisted).
static func slow_player(game: Game, fraction: float, linger: float) -> float:
	var p := game.player
	var f := player_fraction(game, fraction)  # After Brinewalker.
	if f <= 0.0:
		return 0.0
	p.terrain_slow = maxf(p.terrain_slow if p.terrain_slow_timer > 0.0 else 0.0, f)
	p.terrain_slow_timer = maxf(p.terrain_slow_timer, linger)
	return f


## Slows summon `u` by `fraction` (before Brinewalker) for at least `linger` s.
## Returns the fraction applied (0 = fully resisted).
static func slow_summon(game: Game, u: SummonedUnit, fraction: float, linger: float) -> float:
	var f := summon_fraction(game, fraction)  # After Brinewalker (Lv 3+).
	if f <= 0.0:
		return 0.0
	u.holy_slow = maxf(u.holy_slow if u.holy_slow_timer > 0.0 else 0.0, f)
	u.holy_slow_timer = maxf(u.holy_slow_timer, linger)
	return f


# --- Act III: the Assembly Halls (conveyor belts) ---

## Carries the necromancer by belt velocity `v` (px/s) for `delta` s; never
## while he Grave Steps (the step is his own move). Returns true when moved.
static func push_player(game: Game, v: Vector2, delta: float) -> bool:
	if game.grave_step.is_dashing() or game.player.dead:
		return false
	game.player.position += v * delta
	return true


## Carries summon `u` by belt velocity `v` (px/s) for `delta` s: only a body on
## the ground (a spawning, flying or swooping summon rides nothing). Returns
## true when moved.
static func push_summon(_game: Game, u: SummonedUnit, v: Vector2, delta: float) -> bool:
	if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.SPAWNING:
		return false
	u.position += v * delta
	return true


## Carries enemy `e` by belt velocity `v` (px/s) for `delta` s: only a walker on
## the ground (a flying drone, a structure, the boss and a miniboss are not
## moved: they stand too heavy or fly over the belt). Returns true when moved.
static func push_enemy(_game: Game, e: Enemy, v: Vector2, delta: float) -> bool:
	if not e.active or e.is_structure or e.is_boss or e.is_miniboss or e.floating or e.untargetable:
		return false
	e.position += v * delta
	return true
