## HollowPuppet — the Hollow Puppet spell (AbilityData "hollow_puppet"; Act III,
## GDD §15.0 "The Assembly Halls (Act III phase 2)"; owner-approved proposal:
## "curses the strongest nearby non-boss enemy: for 8 s it fights for you, then
## dies"; unlocked by slaying the Motherboard, offered on every stage at the
## later-item card weight). Every `cooldown` s the `puppets` strongest foes (the
## most HP) within `range` px of the necromancer are cut loose from their side:
## never a boss, miniboss, structure, objective, Reckoning foe or a foe already
## puppeted. Each one leaves the field (EnemyDirector.despawn(): no kill yet) and
## rises where it stood as YOUR puppet: a temporary summon through
## HordeDirector.spawn_temporary() (so Restless Dead, the Grave Herald's innate
## and Strings of the Dead apply; outside the army cap), fighting as a Warrior
## (a melee foe: it body-blocks) or an Archer (a ranged one, attack range
## >= PuppetData.RANGED_MIN_RANGE), with `puppet_hp` of the foe's HP, hitting for
## `damage`, for `puppet_life` s, drawn as the foe itself on soul strings. When
## its life runs out (or it is destroyed) the puppet DIES: the foe's XP drops
## where it fell and it counts as a kill.
## Evolved into Puppet King (EvolutionData "puppet_king", detected by the "king"
## key): two puppets, and a puppet that dies bursts: `burst` x its damage to
## every foe within `burst_radius` px (source PuppetData.BURST_SOURCE).
## The Marionette's innate (CharacterData "puppet_duration", "puppet_damage";
## 0 for every other character) makes them last longer and hit harder.
## Determinism: no RNG; targets are ordered by HP, ties in the spatial hash's
## order. Stats: puppet_casts, puppets_raised, puppet_deaths, puppet_xp,
## puppet_bursts, puppet_burst_hits, puppet_cap_refusals.
class_name HollowPuppet
extends NecroSpell

## Seconds until the next cast.
var _timer: float = 1.5
## Puppets dancing: [SummonedUnit, generation, foe XP, last position, foe
## kind, the puppet's hit damage].
var _puppets: Array = []
## Candidate [hp, enemy] pairs of a cast.
var _cands: Array = []
## Soul strings being drawn from the necromancer to a fresh puppet: [world
## position, game time].
var _fx: Array = []


## Tracks the puppets, casts on cooldown.
func step(delta: float, stats: Dictionary) -> void:
	_track(stats)
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	if not _fx.is_empty():
		queue_redraw()


## Seizes the strongest foes in range. Returns false when nobody was taken.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach, _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not _can_puppet(e) or p.distance_to(e.position) > reach:
			continue
		_cands.append([e.hp, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var taken := 0
	for k in mini(int(stats["puppets"]), _cands.size()):
		if _puppets.size() >= PuppetData.MAX_PUPPETS:
			game.stat_add("puppet_cap_refusals", 1.0)
			break
		var e: Enemy = _cands[k][1]
		if e.active:
			_raise(e, stats)
			taken += 1
	if taken > 0:
		game.stat_add("puppet_casts", 1.0)
		game.player.cast_motion(p)  # Engine motion: the necromancer pulls the strings (visual only).
		Sfx.play("summon_rise", p, 0.8)  # The strings pull taut (the startup bank: the spell is offered on every stage).
	return taken > 0


## True for a foe Hollow Puppet may seize (see the header).
static func _can_puppet(e: Enemy) -> bool:
	return e.active and not (e.is_boss or e.is_miniboss or e.is_structure or e.is_objective or e.is_reckoning \
			or e.untargetable or e.kind in PuppetData.NEVER)


## Cuts foe `e` loose and raises it as a puppet where it stood.
func _raise(e: Enemy, stats: Dictionary) -> void:
	var ch := game.character  # The Marionette's innate (0 for the others).
	var life := float(stats["puppet_life"]) * (1.0 + ch.innate_value("puppet_duration"))  # s.
	var dmg := float(stats["damage"]) * (1.0 + ch.innate_value("puppet_damage"))  # Per hit.
	var cls := PuppetData.RANGED_CLASS if e.attack_range >= PuppetData.RANGED_MIN_RANGE else PuppetData.MELEE_CLASS
	var base := game.horde.compute_stats(cls, maxi(1, int(game.horde.class_levels[cls])), true, false)  # The class's stats as spawn_temporary() sees them.
	var hp := maxf(PuppetData.MIN_HP, e.hp * float(stats["puppet_hp"]))
	var pos := e.position
	var kind := e.kind
	var xp := e.xp_value
	game.effects.pop(pos, Palette.VIOLET, e.radius * 1.2)
	game.enemies.despawn(e)  # It leaves its side (no kill yet: it dies as a puppet).
	var u := game.horde.spawn_temporary(cls, pos, life, hp / maxf(1.0, float(base["max_hp"])), dmg / maxf(0.1, float(base["damage"])))
	u.dmg_source = PuppetData.SOURCE
	u.glyph_kind = PuppetData.GLYPH_PREFIX + kind
	u.queue_redraw()
	_puppets.append([u, u.generation, xp, u.position, kind, u.damage])
	_fx.append([u.position, game.elapsed])
	game.stat_add("puppets_raised", 1.0)


## Drops the puppets that died; each death pays the foe's XP (and bursts once
## evolved).
func _track(stats: Dictionary) -> void:
	var i := _puppets.size() - 1
	while i >= 0:
		var rec: Array = _puppets[i]
		var u: SummonedUnit = rec[0]
		if u.active and u.generation == int(rec[1]):
			rec[3] = u.position
		else:
			_puppets.remove_at(i)
			_on_death(rec, stats)
		i -= 1


## A puppet died at its last position: the foe's XP drops, it counts as a
## kill, and a Puppet King's puppet bursts.
func _on_death(rec: Array, stats: Dictionary) -> void:
	var at: Vector2 = rec[3]
	var xp := int(rec[2])
	if xp > 0:
		game.pickups.spawn(at, xp)
		game.stat_add("puppet_xp", float(xp))
	game.kills += 1
	game.stat_add("puppet_deaths", 1.0)
	game.effects.pop(at, Palette.VIOLET, 14.0)
	if stats.has("king"):
		var hits := damage_area(at, float(stats["burst_radius"]), float(stats["burst"]) * float(rec[5]), PuppetData.BURST_SOURCE)
		game.stat_add("puppet_bursts", 1.0)
		game.stat_add("puppet_burst_hits", float(hits))
		game.effects.impact(at, float(stats["burst_radius"]), Palette.VIOLET)
		Sfx.play("corpse_burst", at, 0.85)


## Autotest counters (NecroSpellBook.act2_summary_line(), EmpireReport).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d puppets=%d deaths=%d xp=%d bursts=%d burst_hits=%d cap_refused=%d puppet_dmg=%d puppet_kills=%d" % [
		int(st.get("puppet_casts", 0.0)), int(st.get("puppets_raised", 0.0)), int(st.get("puppet_deaths", 0.0)),
		int(st.get("puppet_xp", 0.0)), int(st.get("puppet_bursts", 0.0)), int(st.get("puppet_burst_hits", 0.0)),
		int(st.get("puppet_cap_refusals", 0.0)), int(st.get("dmg_" + PuppetData.SOURCE, 0.0)),
		int(st.get("kills_by_" + PuppetData.SOURCE, 0.0))]


## The soul strings reaching out to a freshly seized foe (drawing only).
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var from := caster_pos() + Vector2(0, -18)
	var i := _fx.size() - 1
	while i >= 0:
		var f: Array = _fx[i]
		var age := now - float(f[1])
		if age > PuppetData.CAST_FX_TIME:
			_fx.remove_at(i)
		else:
			var k := 1.0 - age / PuppetData.CAST_FX_TIME
			var to: Vector2 = f[0]
			for j in 3:
				var off := Vector2(float(j - 1) * 6.0, -20.0)
				draw_line(from, to + off, Color(PuppetData.STRING_COLOR, 0.9 * k), 1.0)
		i -= 1
