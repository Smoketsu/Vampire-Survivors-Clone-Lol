## Abduction — ABDUCTION, the second of the Concord of Stars' shared rules (Act
## IX; GDD §15.0 "Abduction"; owner-approved proposal: "Saucers hover over the
## ring and lift a summon in a tractor beam. The summon is held for 8 s; shoot
## the saucer down in time and it drops back, otherwise it is gone until the
## next replenish. It is the act's anti-army rule, answered by Archers,
## Gargoyles, Mages and spells. One path through the existing summon hook
## held_until, capped at 3 summons held at once"; the proposal's "or a corpse"
## is dropped by the brief). Owned by Game.concord. AN ENEMY EFFECT ON A
## SUMMON through hooks that already exist, never a new summon rule:
##   * THE ONE CALL: lift(saucer, u). Every abduction goes through it: any
##     "abducts" kit (SaucerKit), phase 2's Harvester (the Reaping) and the
##     Final Harvest. The kit hovers, picks the nearest liftable summon
##     (pick(), deterministic: the ally hash's order, the nearest wins), shows
##     its tractor cone for ABDUCTION windup s and then calls lift().
##   * LIFTABLE (liftable()): never airborne or flying, spawning, dead, charmed,
##     compelled or already held; never a body larger than lift_max_radius (the
##     Abomination, Colossus and Golem are too heavy); never the necromancer.
##   * THE HOLD: the summon is held through SummonedUnit.held_until, renewed
##     each tick by carry(), THE ONE PLACE that moves it (it rises to lift_px
##     under the saucer over rise_time s, as ChiropteranKingKit.carry()), and
##     kept out of the fight by ONE CombatResolver.stun_unit(u, hold, source)
##     at the lift (Oni's Resolve shortens that stun as it does every stun; the
##     hold stays).
##   * RESCUE: if the saucer dies or is pooled during the hold, the summon drops
##     at Arena.free_point() with a short daze (as the King's _drop_all()).
##   * TAKEN: after `hold` s (x Anchored's hook) the summon is gone:
##     u.director.on_unit_died(u, false). No death is counted, no corpse, no
##     claim; the class queue replaces it at its next replenish.
##   * CAP: at most ABDUCTION cap summons held at once across both armies; the
##     Final Harvest lifts the cap (`uncapped`).
## Anchored hooks: ConcordRules.anchored_hold_mult() (x the hold; 1 today) and
## anchored_breaks() (false today; when true a hit on the saucer ends the hold:
## on_saucer_hit()).
## Determinism: no RNG; holds are an ordered list with pooling generations.
## Stats (the "abduction" line): abduction_lifts, abduction_rescues,
## abduction_taken, abduction_refused_cap, abduction_refused_heavy,
## abduction_saucers_down, abduction_lifts_uncapped, abduction_anchored_breaks.
class_name Abduction
extends RefCounted

## Owning run.
var game: Game
## Abduction's numbers (ConcordRulesData.ABDUCTION).
var cfg: Dictionary = {}
## Live holds, in lift order: each [saucer Enemy, saucer generation, summon,
## summon generation, game s lifted, game s it is taken, ground position at the
## lift (Vector2)].
var holds: Array = []
## True while the Final Harvest runs: the cap is gone.
var uncapped: bool = false
## Most summons held at once this run (the report).
var peak: int = 0
## Summons lifted this run.
var lifts: int = 0
## Summons dropped back by a rescue (the saucer died or was pooled).
var rescues: int = 0
## Summons taken (gone until the next replenish).
var taken: int = 0


## Builds Abduction for `p_game` (ConcordRules keeps it).
func _init(p_game: Game) -> void:
	game = p_game
	cfg = ConcordRulesData.ABDUCTION.duplicate()


## Summons held now.
func held_count() -> int:
	return holds.size()


## True when one more summon may be lifted (under the cap, or the Final
## Harvest lifted it).
func has_room() -> bool:
	return uncapped or holds.size() < int(cfg["cap"])


## True when summon `u` can be lifted (see the header).
func liftable(u: SummonedUnit) -> bool:
	if not u.active or u.airborne or u.flies or u.charmed or u.is_compelled():
		return false
	if u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
		return false
	if u.held_until > game.elapsed:
		return false  # Already held (a net, a carry, another tractor beam).
	return u.radius <= float(cfg["lift_max_radius"])


## The nearest liftable summon within `reach` px of `at` (deterministic: the
## ally hash's order, the nearest wins; ties keep the first), or null. Counts a
## refusal when only a too-heavy body was nearer.
func pick(at: Vector2, reach: float) -> SummonedUnit:
	var tmp: Array = []  # Own buffer (a kit may call this inside another query).
	game.ally_grid.query(at, reach + UnitData.MAX_BLOCK_RADIUS, tmp)
	var best: SummonedUnit = null
	var best_d := INF
	var heavy_d := INF  # Nearest too-heavy summon.
	for u: SummonedUnit in tmp:
		var dist := u.position.distance_to(at)
		if dist > reach:
			continue
		if liftable(u):
			if dist < best_d:
				best = u
				best_d = dist
		elif u.active and u.state != SummonedUnit.State.DEAD and u.radius > float(cfg["lift_max_radius"]):
			heavy_d = minf(heavy_d, dist)
	if heavy_d < best_d:
		game.stat_add("abduction_refused_heavy", 1.0)
	return best


## THE ONE CALL: `saucer` lifts summon `u` (its tractor beam). Refused (false)
## when `u` is not liftable or the cap is reached (counted).
func lift(saucer: Enemy, u: SummonedUnit) -> bool:
	if u == null or saucer == null or not liftable(u):
		return false
	if not has_room():
		game.stat_add("abduction_refused_cap", 1.0)
		return false
	var hold := float(cfg["hold"]) * (game.concord.anchored_hold_mult(u) if game.concord != null else 1.0)  # Anchored (x1 today).
	holds.append([saucer, saucer.generation, u, u.generation, game.elapsed, game.elapsed + hold, u.position])
	u.held_until = maxf(u.held_until, game.elapsed + float(cfg["renew"]))
	game.combat.stun_unit(u, hold, ConcordRulesData.ABDUCTION_SOURCE)
	lifts += 1
	peak = maxi(peak, holds.size())
	game.stat_add("abduction_lifts", 1.0)
	if holds.size() > int(cfg["cap"]):
		game.stat_add("abduction_lifts_uncapped", 1.0)  # Only the Final Harvest goes past the cap.
	if game.concord != null:
		game.concord.play_sound("abduction", u.position, 0.3)
	return true


## True while `saucer` holds a summon.
func holding(saucer: Enemy) -> bool:
	for h: Array in holds:
		if h[0] == saucer and int(h[1]) == saucer.generation:
			return true
	return false


## Per-tick update (ConcordRules.step()): every hold is carried (carry()); a
## hold whose saucer is gone is a rescue; a hold whose time is up is taken.
func step(_delta: float) -> void:
	var i := 0
	while i < holds.size():
		var h: Array = holds[i]
		var s: Enemy = h[0]
		var u: SummonedUnit = h[2]
		if not u.active or u.generation != int(h[3]) or u.state == SummonedUnit.State.DEAD:
			holds.remove_at(i)  # It died while held (a beam, a blast): nothing to drop.
			continue
		if not s.active or s.generation != int(h[1]):
			_drop(u, true)
			holds.remove_at(i)
			continue
		if game.elapsed >= float(h[5]):
			holds.remove_at(i)
			_take(u)
			continue
		carry(h)
		i += 1


## THE ONE PLACE that moves a lifted summon: it is held a moment longer and set
## on its way up to lift_px under its saucer (rising over rise_time s).
func carry(h: Array) -> void:
	var s: Enemy = h[0]
	var u: SummonedUnit = h[2]
	u.held_until = maxf(u.held_until, game.elapsed + float(cfg["renew"]))
	var k := clampf((game.elapsed - float(h[4])) / maxf(float(cfg["rise_time"]), 0.01), 0.0, 1.0)  # 0 on the ground .. 1 under the saucer.
	var top := s.position + Vector2(0.0, float(cfg["lift_px"]))  # Under the saucer.
	u.position = (h[6] as Vector2).lerp(top, k)
	u.velocity = Vector2.ZERO


## A hit landed on `saucer` (ConcordKit.taken_mult(); ANCHORED's hook): when
## the passive is owned, every hold of that saucer breaks (a rescue). Never
## while the passive does not exist.
func on_saucer_hit(saucer: Enemy) -> void:
	if game.concord == null:
		return
	var i := 0
	while i < holds.size():
		var h: Array = holds[i]
		if h[0] == saucer and int(h[1]) == saucer.generation and game.concord.anchored_breaks(h[2] as SummonedUnit):
			var u: SummonedUnit = h[2]
			holds.remove_at(i)
			game.stat_add("abduction_anchored_breaks", 1.0)  # Act IX, the Crash Site: Anchored broke the hold (its report line).
			if u.active and u.generation == int(h[3]):
				_drop(u, true)
			continue
		i += 1


## Every hold of `saucer` ends as a rescue (ConcordRules.note_gone(): it died or
## was pooled).
func release_all(saucer: Enemy) -> void:
	var i := 0
	while i < holds.size():
		var h: Array = holds[i]
		if h[0] == saucer:
			var u: SummonedUnit = h[2]
			holds.remove_at(i)
			if u.active and u.generation == int(h[3]) and u.state != SummonedUnit.State.DEAD:
				_drop(u, true)
			continue
		i += 1


## RESCUE: summon `u` drops at the nearest free point with a short daze: its
## hold and the lift's stun are both cut to drop_daze s from now (a longer stun
## from elsewhere still running is cut too: the drop wakes it). `count` adds it
## to the rescues.
func _drop(u: SummonedUnit, count: bool) -> void:
	u.position = game.arena.free_point(u.position, u.radius)
	u.held_until = game.elapsed + float(cfg["drop_daze"])
	u.stunned_until = minf(u.stunned_until, game.elapsed + float(cfg["drop_daze"]))
	game.effects.ring(u.position, u.radius * 1.6, Palette.CONCORD_PLASMA, 0.25)
	if count:
		rescues += 1
		game.stat_add("abduction_rescues", 1.0)


## TAKEN: summon `u` is gone until its class's next replenish (no death, no
## corpse, no claim).
func _take(u: SummonedUnit) -> void:
	taken += 1
	game.stat_add("abduction_taken", 1.0)
	game.effects.pop(u.position, Palette.CONCORD_PLASMA, u.radius * 1.4)
	u.director.on_unit_died(u, false)
