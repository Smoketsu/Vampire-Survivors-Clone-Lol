## Enthrall — THE ONE PATH THAT TURNS A FOE TO THE NECROMANCER'S SIDE FOR A WHILE
## (Act VI, the Palace of Silk and Ash; GDD §15.0 "Temptation, Unholy Desire,
## Velvet Chains and the Succubus Queen" and "The Succubus, the Lilim Matriarch
## and Sweet Surrender"). The player's mirror of the Inferno's Temptation rule
## (which turns SUMMONS, HordeDirector.charm()): a spell, so it never touches the
## summon charm path. Owned by an army (HordeDirector.enthrall, made on first use
## by HordeDirector.enthrall_foe(), the only caller) and stepped by it; the same
## on every stage. Callers: the Temptation spell (TemptSpell) and the Succubus
## summon class (BoundSuccubusBehavior).
##   * turn(e, duration, opts): foe `e` (never a boss, miniboss, structure,
##     objective, Reckoning foe, untargetable body or TemptData.NEVER kind) LEAVES
##     its side (EnemyDirector.despawn(): no kill) and stands where it stood as
##     a THRALL: a temporary summon (HordeDirector.spawn_temporary(), outside the
##     army cap) of TemptData.MELEE_CLASS (a melee foe: it body-blocks) or
##     RANGED_CLASS, with the foe's HP (at least MIN_HP) x opts hp_mult, hitting
##     for opts damage, drawn as the foe itself tinted charm pink with a heart
##     over it (glyph "enthralled:<kind>"), its blows tagged opts source.
##   * The CHARM ENDS after `duration` s: the thrall leaves (no death) and the
##     foe comes back to its side where the thrall stands (EnemyDirector
##     .spawn_at(), its elite flag kept) with the thrall's share of its HP; opts
##     heartbreak (0..1) then strikes it for that share of its max HP (source
##     TemptData.HEARTBREAK_SOURCE: the Succubus Queen's innate), and opts
##     burst_damage strikes every foe within TemptData.BURST_RADIUS px of it
##     (source TemptData.BURST_SOURCE: Unholy Desire).
##   * A thrall SLAIN while charmed: the foe dies with it (its XP drops where
##     it fell, it counts as a kill) and opts burst_damage bursts there too.
##   * At most TemptData.MAX_THRALLS at once per army (refused beyond it).
## Determinism: no RNG; records in a fixed order, units guarded by their pooling
## generation. Stats: enthrall_turned, enthrall_by_<source>, enthrall_returned,
## enthrall_slain, enthrall_refused, enthrall_heartbreaks, enthrall_bursts,
## enthrall_burst_hits, enthrall_xp.
class_name Enthrall
extends RefCounted

## One thrall.
class Thrall:
	extends RefCounted
	## The temporary summon fighting for the necromancer.
	var unit: SummonedUnit = null
	## Its generation when raised (death guard).
	var gen: int = 0
	## The foe's kind (it comes back as this).
	var kind: String = ""
	## True when the foe was an elite.
	var elite: bool = false
	## The foe's XP (paid if the thrall is slain).
	var xp: int = 0
	## Game time (s) the charm ends.
	var until: float = 0.0
	## Last world position of the thrall.
	var at: Vector2 = Vector2.ZERO
	## The turn's options (source, heartbreak, burst_damage).
	var opts: Dictionary = {}

## Owning run.
var game: Game
## The army the thralls fight in.
var horde: HordeDirector
## Thralls standing now (in the order they were turned).
var thralls: Array[Thrall] = []


func _init(p_game: Game, p_horde: HordeDirector) -> void:
	game = p_game
	horde = p_horde


## True for a foe Enthrall may turn (see the header).
static func can_turn(e: Enemy) -> bool:
	return e != null and e.active and not (e.is_boss or e.is_miniboss or e.is_structure or e.is_objective or e.is_reckoning \
			or e.untargetable or e.kind in TemptData.NEVER or e.kind in PuppetData.NEVER)


## Thralls standing now.
func count() -> int:
	return thralls.size()


## Turns foe `e` for `duration` s (see the header). opts: "source" (String),
## "damage" (the thrall's hit), "hp_mult" (x the foe's HP, default 1),
## "heartbreak" (0..1), "burst_damage" (0 = none). Returns the thrall, or null
## when refused.
func turn(e: Enemy, duration: float, opts: Dictionary) -> SummonedUnit:
	if not can_turn(e) or thralls.size() >= TemptData.MAX_THRALLS:
		game.stat_add("enthrall_refused", 1.0)
		return null
	var cls := TemptData.RANGED_CLASS if e.attack_range >= TemptData.RANGED_MIN_RANGE else TemptData.MELEE_CLASS
	var base := horde.compute_stats(cls, maxi(1, int(horde.class_levels[cls])), true, false)  # The class's stats as spawn_temporary() sees them.
	var hp := maxf(TemptData.MIN_HP, e.hp * float(opts.get("hp_mult", 1.0)))
	var dmg := float(opts.get("damage", 10.0))
	var t := Thrall.new()
	t.kind = e.kind
	t.elite = e.is_elite
	t.xp = e.xp_value
	t.opts = opts
	t.until = game.elapsed + duration
	var pos := e.position
	game.effects.pop(pos, Palette.INFERNO_CHARM, e.radius * 1.2)
	game.enemies.despawn(e)  # It leaves its side (no kill: it comes back, or dies as a thrall).
	var u := horde.spawn_temporary(cls, pos, duration + TemptData.LIFE_SLACK, hp / maxf(1.0, float(base["max_hp"])), dmg / maxf(0.1, float(base["damage"])))
	u.dmg_source = String(opts.get("source", TemptData.SOURCE))
	u.glyph_kind = TemptData.GLYPH_PREFIX + t.kind
	u.queue_redraw()
	t.unit = u
	t.gen = u.generation
	t.at = u.position
	thralls.append(t)
	game.stat_add("enthrall_turned", 1.0)
	game.stat_add("enthrall_by_" + u.dmg_source, 1.0)
	return u


## Per-tick update (HordeDirector.step()): slain thralls take their foe with
## them; charms that ran out send the foe back.
func step() -> void:
	var i := 0
	while i < thralls.size():
		var t := thralls[i]
		var u := t.unit
		if not u.active or u.generation != t.gen:
			thralls.remove_at(i)
			_slain(t)
			continue
		t.at = u.position
		if game.elapsed >= t.until:
			thralls.remove_at(i)
			_return(t)
			continue
		i += 1


## The thrall fell while charmed: the foe dies with it (XP, a kill), and bursts.
func _slain(t: Thrall) -> void:
	if t.xp > 0:
		game.pickups.spawn(t.at, t.xp)
		game.stat_add("enthrall_xp", float(t.xp))
	game.kills += 1
	game.stat_add("enthrall_slain", 1.0)
	_burst(t)


## The charm ends: the thrall leaves and the foe comes back with its share of HP.
func _return(t: Thrall) -> void:
	var u := t.unit
	var frac := clampf(u.hp / maxf(1.0, u.max_hp), 0.05, 1.0)  # Share of HP it comes back with.
	horde.on_unit_died(u, false)  # Leaves without a death.
	game.stat_add("enthrall_returned", 1.0)
	var e := game.enemies.spawn_at(t.kind, t.at, t.elite)
	if e != null:
		e.hp = clampf(e.max_hp * frac, 1.0, e.max_hp)
		var hb := float(t.opts.get("heartbreak", 0.0))  # The Succubus Queen's Heartbreaker.
		if hb > 0.0:
			game.stat_add("enthrall_heartbreaks", 1.0)
			game.combat.damage_enemy(e, e.max_hp * hb, TemptData.HEARTBREAK_SOURCE)
	game.effects.pop(t.at, Palette.INFERNO_CHARM_LIGHT, 12.0)
	_burst(t)


## Unholy Desire: a burst of desire around a thrall whose charm ended.
func _burst(t: Thrall) -> void:
	var dmg := float(t.opts.get("burst_damage", 0.0))
	if dmg <= 0.0:
		return
	var r := TemptData.BURST_RADIUS
	var buf: Array = []
	game.enemy_grid.query(t.at, r + ProjectileManager.MAX_BODY_RADIUS, buf)
	var hits := 0
	for e: Enemy in buf:
		if e.active and e.position.distance_to(t.at) <= r + e.radius:
			game.combat.damage_enemy(e, dmg, TemptData.BURST_SOURCE)
			hits += 1
	game.stat_add("enthrall_bursts", 1.0)
	game.stat_add("enthrall_burst_hits", float(hits))
	game.effects.impact(t.at, r, Palette.INFERNO_CHARM)
