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
