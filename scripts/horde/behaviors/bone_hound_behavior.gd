## BoneHoundBehavior — the Bone Hounds' Pack Hunt ("pack", UnitData). A hound
## is an ordinary fast melee summon (it never kites: w_threat 0); this
## behaviour only changes WHOM it bites and HOW HARD:
##   * Shared target: every think (5 Hz, before the shared target choice) the
##     hound counts which enemies its packmates are biting (`_pack`), and
##     score_bonus() adds focus_bonus x (packmates on that foe / pack_cap),
##     so the pack converges on one prey. Its "pack" weights and the
##     backline_bonus (archers, casters, priests, banner bearers:
##     Enemy.behavior in BACKLINE) and edge_bonus (foe distance to the player /
##     the engagement leash) make that prey the backline at the edge of the
##     crowd.
##   * Pack bite: melee_bonus() counts the OTHER hounds biting the same foe
##     right now (their target is it and their body is within pack_radius px
##     of its edge, found through the ally grid); each adds pack_bonus to the
##     bite, at most pack_cap of them.
## Hellhound (summon evolution; keys from SummonEvolutionData "special_set",
## absent / 0 on the base hound, which keeps exactly the behaviour above):
##   * burning bites: on_melee_hit() sets the bitten foe burning for
##     burn_fraction of the bite in total over burn_ticks ticks of burn_tick s
##     (source "hellhound_burn"); a new bite by the same Hellhound refreshes
##     it. Burns are ticked by the Hellhound that set them and stop if it dies
##     (like the Rogue bleed).
##   * fire trail: while running (moving faster than TRAIL_MIN_SPEED), every
##     trail_interval s, once it has covered trail_spacing px since its last
##     patch, it drops a HordeHazards fire patch (trail_radius px, trail_life
##     s, trail_fraction x its bite damage every trail_tick s to every foe in
##     it, source "hellhound_trail").
##   * split pack: with pack_split 2 the pack is two halves (think slot
##     parity); each half focuses its own prey, and a hound is steered off the
##     other half's lead prey (minus focus_bonus).
## Synergies: with The Wild Hunt a swooped foe (Enemy.swooped_until) within
## prey_reach px of the hound gets prey_bonus on its score, so the pack
## turns on what the Gargoyles dive on (its bite bonus is in
## SynergyManager.hit_mult()); Baying of the Damned speeds the pack up after
## each Dirge through HordeDirector.compute_stats().
## Stats: hound_bites, hound_pack_bites (bites with a packmate on the foe),
## hound_pack_bonus_dmg; Hellhound: hellhound_burns, dmg_hellhound_burn,
## hellhound_trail_patches, dmg_hellhound_trail (HordeHazards).
class_name BoneHoundBehavior
extends SummonBehavior

## Enemy behaviours counted as backline prey (archers, casters, priests,
## banner bearers, consecrating Chaplains).
const BACKLINE := ["ranged", "healer", "banner", "consecrator"]
## A Hellhound drops fire only while moving faster than this (px/s).
const TRAIL_MIN_SPEED: float = 40.0
## Safety cap on burns ticked by one Hellhound (not a balance number).
const MAX_BURNS: int = 24

## Enemy -> packmates (same half) targeting it, rebuilt every think.
var _pack: Dictionary = {}
## Lead prey of the OTHER half of a split pack (null = none / not split).
var _rival: Enemy = null
## Running burns: {"e": Enemy, "gen": int, "left": ticks, "t": s to next tick, "dmg": per tick}.
var _burns: Array[Dictionary] = []
## Seconds until the next fire patch may drop.
var _trail_cd: float = 0.0
## Where the last fire patch dropped.
var _trail_at: Vector2 = Vector2.ZERO
## Bite multiplier of the strike in progress (melee_bonus() -> on_melee_hit()).
var _last_mult: float = 1.0
## Reusable ally query buffer.
var _buf: Array = []


## Clears the pack state, burns and trail on every (re)activation.
func reset(u: SummonedUnit) -> void:
	super(u)
	_pack.clear()
	_rival = null
	_burns.clear()
	_trail_cd = 0.0
	_trail_at = u.position
	_last_mult = 1.0


## Drops burns when the hound dies (they stop with it).
func on_deactivate(u: SummonedUnit) -> void:
	super(u)
	_burns.clear()
	_pack.clear()
	_rival = null


## Half of a split pack this hound runs with (0 or 1; 0 when not split).
static func pack_side(u: SummonedUnit) -> int:
	return u.think_slot % 2 if int(u.special.get("pack_split", 1)) > 1 else 0


## Rebuilds the pack map (who bites what) before the shared target choice.
## Never starts a special: always false.
func think(u: SummonedUnit) -> bool:
	_pack.clear()
	_rival = null
	var side := pack_side(u)  # This hound's half of the pack.
	var split := int(u.special.get("pack_split", 1)) > 1  # Hellhound split pack.
	var rival_counts: Dictionary = {}  # Other half: enemy -> hounds on it.
	for h in u.director.units:
		if h == u or not h.active or h.unit_class != u.unit_class or not h.target_alive():
			continue
		if pack_side(h) == side:
			_pack[h.target] = int(_pack.get(h.target, 0)) + 1
		elif split:
			rival_counts[h.target] = int(rival_counts.get(h.target, 0)) + 1
	var best := 0  # Hounds on the other half's lead prey.
	for e: Enemy in rival_counts:
		if int(rival_counts[e]) > best:
			best = int(rival_counts[e])
			_rival = e
	return false


## Pack prey preference (see the header).
func score_bonus(u: SummonedUnit, e: Enemy, dp: float) -> float:
	var s := float(u.special["edge_bonus"]) * clampf(dp / maxf(u.engage_radius, 1.0), 0.0, 1.0)  # The edge of the crowd.
	if e.behavior in BACKLINE:
		s += float(u.special["backline_bonus"])
	var n := int(_pack.get(e, 0))  # Packmates already on this foe.
	if n > 0:
		s += float(u.special["focus_bonus"]) * clampf(float(n) / maxf(float(u.special["pack_cap"]), 1.0), 0.0, 1.0)
	if e == _rival and n == 0:
		s -= float(u.special["focus_bonus"])  # Split pack: leave it to the other half.
	if e.swooped_until > u.game.elapsed:
		# The Wild Hunt (synergy): a swooped foe within reach is the prey.
		var syn := u.director.synergies  # Army synergies (0 values while inactive).
		var prey := syn.value("wild_hunt", "prey_bonus")  # Score bonus (0 = inactive).
		if prey > 0.0 and u.position.distance_to(e.position) <= syn.value("wild_hunt", "prey_reach"):
			s += prey
	return s


## Pack bite: +pack_bonus per other hound biting `e` now (at most pack_cap).
func melee_bonus(u: SummonedUnit, e: Enemy) -> float:
	var reach := float(u.special["pack_radius"])  # px beyond the foe's edge.
	u.game.ally_grid.query(e.position, e.radius + reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0  # Packmates biting the same foe.
	for h: SummonedUnit in _buf:
		if h == u or not h.active or h.unit_class != u.unit_class or h.target != e or not h.target_alive():
			continue
		if h.position.distance_to(e.position) - h.radius - e.radius <= reach:
			n += 1
	n = mini(n, int(u.special["pack_cap"]))
	_last_mult = 1.0 + float(u.special["pack_bonus"]) * float(n)
	u.game.stat_add("hound_bites", 1.0)
	if n > 0:
		u.game.stat_add("hound_pack_bites", 1.0)
	return _last_mult


## Counts the pack bonus and, as a Hellhound, sets the foe burning.
func on_melee_hit(u: SummonedUnit, e: Enemy, dealt: float) -> void:
	if _last_mult > 1.0:
		u.game.stat_add("hound_pack_bonus_dmg", dealt * (1.0 - 1.0 / _last_mult))
	_last_mult = 1.0
	var frac := float(u.special.get("burn_fraction", 0.0))  # Hellhound burn share (0 = none).
	if frac <= 0.0 or not e.active:
		return
	var ticks := maxi(1, int(u.special["burn_ticks"]))  # Ticks of a fresh burn.
	var per := u.damage * frac / float(ticks)  # Damage per burn tick.
	for b in _burns:
		if b["e"] == e and int(b["gen"]) == e.generation:
			b["left"] = ticks
			b["dmg"] = maxf(float(b["dmg"]), per)
			return
	if _burns.size() >= MAX_BURNS:
		return
	_burns.append({"e": e, "gen": e.generation, "left": ticks, "t": float(u.special["burn_tick"]), "dmg": per})
	u.game.stat_add("hellhound_burns", 1.0)


## Ticks burns and drops the fire trail, then the base special handling
## (the hound has no CASTING special of its own).
func physics(u: SummonedUnit, delta: float) -> bool:
	if not _burns.is_empty():
		_tick_burns(u, delta)
	if float(u.special.get("trail_interval", 0.0)) > 0.0:
		_step_trail(u, delta)
	return super(u, delta)


## Applies due burn ticks and drops finished / stale burns.
func _tick_burns(u: SummonedUnit, delta: float) -> void:
	var tick := float(u.special["burn_tick"])  # Seconds between ticks.
	var i := 0  # Index (swap-remove while iterating).
	while i < _burns.size():
		var b := _burns[i]  # One running burn.
		var e: Enemy = b["e"]
		if not e.active or e.generation != int(b["gen"]) or int(b["left"]) <= 0:
			_burns[i] = _burns[_burns.size() - 1]
			_burns.pop_back()
			continue
		b["t"] = float(b["t"]) - delta
		if float(b["t"]) <= 0.0:
			b["t"] = float(b["t"]) + tick
			b["left"] = int(b["left"]) - 1
			u.game.combat.damage_enemy(e, float(b["dmg"]), "hellhound_burn")
		i += 1


## Hellhound fire trail: a patch every trail_interval s while running.
func _step_trail(u: SummonedUnit, delta: float) -> void:
	_trail_cd -= delta
	if _trail_cd > 0.0 or u.velocity.length() < TRAIL_MIN_SPEED or u.state == SummonedUnit.State.SPAWNING:
		return
	if u.position.distance_to(_trail_at) < float(u.special["trail_spacing"]):
		return
	_trail_cd = float(u.special["trail_interval"])
	_trail_at = u.position
	var dmg := u.damage * float(u.special["trail_fraction"])  # Damage per tick.
	if u.director.hazards.add_patch(HordeHazards.KIND_FIRE, u.position, float(u.special["trail_radius"]),
			float(u.special["trail_life"]), float(u.special["trail_tick"]), dmg, "hellhound_trail"):
		u.game.stat_add("hellhound_trail_patches", 1.0)


## Hellhound ember ring at its feet (burning bites read at a glance).
func draw_under(u: SummonedUnit) -> void:
	if float(u.special.get("burn_fraction", 0.0)) > 0.0:
		u.draw_arc(Vector2(0, u.radius * 0.6), u.radius * 1.2, 0.0, TAU, 16, Color(HordeHazards.EMBER, 0.45), 1.5)
