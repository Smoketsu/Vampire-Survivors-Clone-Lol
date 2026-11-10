## OssuaryOakBehavior — the Ossuary Oak's ROOTED LASH ("root_lash", UnitData
## "ossuary_oak"; temporary Act XV, the World-Tree's finale reward and the
## campaign's; GDD §15.0 "The Ossuary Oak, World-Root Warden and Heartwood";
## owner-approved proposal: "Finale summon class the Ossuary Oak: a slow tree of
## bone that roots in place as a blocker and lashes everything around it with
## thorns (evolution World-Root Warden)"). A slow blocker of bone with soul-teal
## knots, the necromancer's own, on the Bone Ring's front posts. Its special,
## the same on every stage (owner rule: summons never get act-only rules), a
## ground body all the way (the arena's push-out keeps it out of the obstacles,
## enemies can hit it):
##   1. ROOTED: while lash_trigger or more foes (or an elite / the boss) stand
##      within root_reach px of it, it roots in place (rooted():
##      SummonedUnit._step_movement() keeps it still; it still thinks and
##      strikes) and blocks with root_mass (Enemy.resolve_blocking());
##   2. THE LASH: while rooted, every lash_cooldown s its thorns lash EVERY foe
##      within lash_radius px for lash_damage (its own source, SOURCE /
##      EVOLVED_SOURCE), then the class volley (VolleyDirector.on_special());
##   3. evolved into the WORLD-ROOT WARDEN (SummonEvolutionData
##      "world_root_warden", special_set warden / root_slow / root_time): every
##      foe its lash strikes is held by its roots, slowed root_slow for
##      root_time s (CombatResolver.slow_enemy(); bosses through their own slow
##      resist).
## With no foe near it uproots and walks slowly back to its post. Heartwood (its
## paired passive, PassiveData "heartwood", read only here): x 1 +
## heart_damage on the lash, + heart_radius px.
## Determinism: no RNG beyond the base class's first cooldown (the seeded
## global RNG); the foes in the spatial hash's order. Stats: oak_lashes,
## oak_lash_hits, oak_rooted_s, warden_roots, dmg_ossuary_oak_lash /
## dmg_world_root_lash.
class_name OssuaryOakBehavior
extends SummonBehavior

## Class id (UnitData, UnlockData, mastery).
const CLASS_ID: String = "ossuary_oak"
## Its evolution's id (SummonEvolutionData).
const EVOLUTION_ID: String = "world_root_warden"
## Damage-source tag of the lash (the base Oak; a minion special, PassiveData).
const SOURCE: String = "ossuary_oak_lash"
## Damage-source tag of the World-Root Warden's lash.
const EVOLVED_SOURCE: String = "world_root_lash"
## Passive id of Heartwood (its paired passive; PassiveData, UnlockData).
const HEARTWOOD: String = "heartwood"
## Heartwood's level-row key: share more lash damage (0..1).
const HEARTWOOD_DAMAGE_KEY: String = "heart_damage"
## Heartwood's level-row key: px more lash radius.
const HEARTWOOD_RADIUS_KEY: String = "heart_radius"

## True while it stands rooted.
var _rooted: bool = false
## Seconds until the next lash.
var _lash_cd: float = 0.0
## The unit's block mass while not rooted (restored when it uproots).
var _base_mass: float = 0.0
## Game time (s) of its last lash (the lash ring is drawn a moment).
var _lash_at: float = -INF
## Reusable enemy query buffer.
var _buf: Array = []


## The lash's cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("lash_cooldown", 2.5))


## Fresh activation: not rooted.
func reset(u: SummonedUnit) -> void:
	super.reset(u)
	_rooted = false
	_lash_cd = cooldown(u) * 0.5
	_base_mass = u.block_mass
	_lash_at = -INF


## Dies / is pooled: its block mass back.
func on_deactivate(u: SummonedUnit) -> void:
	if _rooted:
		u.block_mass = _base_mass
	_rooted = false
	super.on_deactivate(u)


## 5 Hz: roots when foes stand near it, uproots when none.
func think(u: SummonedUnit) -> bool:
	var want := _foes_near(u)
	if want and not _rooted:
		_rooted = true
		_base_mass = u.block_mass
		u.block_mass = maxf(u.block_mass, float(u.special.get("root_mass", u.block_mass)))
		u.queue_redraw()
	elif not want and _rooted:
		_rooted = false
		u.block_mass = _base_mass
		u.queue_redraw()
	return false


## True when lash_trigger foes (or an elite / the boss) stand within root_reach px.
func _foes_near(u: SummonedUnit) -> bool:
	var reach := float(u.special.get("root_reach", 90.0))
	u.game.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var n := 0
	for e: Enemy in _buf:
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(u.position) > reach + e.radius:
			continue
		if e.is_elite or e.is_boss:
			return true
		n += 1
	return n >= int(u.special.get("lash_trigger", 2))


## Per tick: the lash on its clock while rooted (the shared FSM keeps the tick).
func physics(u: SummonedUnit, delta: float) -> bool:
	super.physics(u, delta)
	if not _rooted:
		return false
	u.game.stat_add("oak_rooted_s", delta)
	_lash_cd -= delta
	if _lash_cd <= 0.0:
		_lash_cd = cooldown(u)
		_lash(u)
	return false


## The thorns lash every foe in reach (see the header).
func _lash(u: SummonedUnit) -> void:
	var g := u.game
	var r := float(u.special["lash_radius"]) + g.abilities.passive_value(HEARTWOOD, HEARTWOOD_RADIUS_KEY)
	var dmg := float(u.special["lash_damage"]) * (1.0 + g.abilities.passive_value(HEARTWOOD, HEARTWOOD_DAMAGE_KEY))
	var warden := u.special.has("warden")
	var src := EVOLVED_SOURCE if warden else SOURCE
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	g.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(u.position) > r + e.radius:
			continue
		g.combat.damage_enemy(e, dmg, src, u.director.slot, u.position)
		n += 1
		if warden and e.active:
			g.combat.slow_enemy(e, float(u.special["root_slow"]), float(u.special["root_time"]))
			g.stat_add("warden_roots", 1.0)
	if n == 0:
		return
	g.stat_add("oak_lashes", 1.0)
	g.stat_add("oak_lash_hits", float(n))
	_lash_at = g.elapsed
	g.volleys.on_special(u, u.position, u.position + Vector2.RIGHT, dmg)  # Bullet heaven: a ring of thorns.
	u.queue_redraw()


## A stat refresh while rooted keeps the rooted block mass (apply_stats()
## copies the director's mass back first).
func adjust_stats(u: SummonedUnit) -> void:
	if _rooted:
		_base_mass = u.block_mass
		u.block_mass = maxf(u.block_mass, float(u.special.get("root_mass", u.block_mass)))


## Rooted on purpose: SummonedUnit._step_movement() keeps it still.
func rooted() -> bool:
	return _rooted


## Under the body: its roots while rooted, the lash's ring a moment after it
## lashed (disc textures and rects only).
func draw_under(u: SummonedUnit) -> void:
	if not _rooted:
		return
	world_space(u)
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		u.draw_rect(Rect2(Vector2(cos(a), sin(a)) * u.radius - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.BONE, 0.7))  # A root of bone.
	if u.game.elapsed - _lash_at < 0.25:
		var r := float(u.special["lash_radius"])
		u.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(RootAndRotData.ROT, 0.16))
	body_space(u)
