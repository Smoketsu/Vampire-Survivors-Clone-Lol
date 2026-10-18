## CallOfTheDrowned — the Call of the Drowned spell (AbilityData
## "call_of_the_drowned"; Act II, GDD §15.0 "Ul-Thalos, the Risen Spire";
## unlocked by slaying Vhal'Neth, offered on every stage at the later-item card
## weight): the Ancient Eye's Claim turned against it. Every `cooldown` s
## tendrils rise under the strongest foes within `range` px of the necromancer
## (the `targets` with the most HP; structures are never chosen). Each target
## is marked by a drowned ring for CallDrownedData.TENDRIL_DELAY s (it follows
## the target), then the tendrils burst up: `damage` to every foe within
## `radius` px, each slowed (CombatResolver.slow_enemy()). A foe the tendrils
## KILL rises as the necromancer's Drowned Thrall for `life` s: a temporary
## summon through HordeDirector.spawn_temporary() (outside the army cap; so
## Restless Dead and the Grave Herald's innate lengthen it), with `thrall_hp` /
## `thrall_damage` of a Skeleton Warrior's current stats, drawn as a drowned
## cultist with the necromancer's green in its eye. At most
## CallDrownedData.THRALL_MAX stand at once. Bosses, minibosses, structures,
## Reckoning foes and the Eye's own Thralls never rise.
## Evolved into Tidecaller's Host (EvolutionData "tidecallers_host", detected by
## the "host" key): the drowned rise as Spawns of the Deep (CallDrownedData.
## HOST_CLASS, the summon class's kit: bigger, and their Grasp seizes and holds
## a foe), drowned-tinted so they read apart from the class's own units.
## The Tide Widow's innate (CharacterData "thrall_hp_bonus", "thrall_cap_bonus";
## 0 for every other character) makes them sturdier and allows more at once.
## Determinism: the seeded global RNG is never used; targets are ordered by HP,
## ties in the spatial hash's order. Stats: drowned_casts, drowned_tendrils,
## drowned_risen, drowned_host_risen, drowned_cap_refusals,
## drowned_widow_extra (innate Thralls beyond the cap); damage as
## dmg_drowned_tendril / dmg_tide_tendril and the Thralls' own sources.
class_name CallOfTheDrowned
extends NecroSpell

## Seconds until the next cast.
var _timer: float = 1.0
## Tendrils about to rise: [enemy, generation, seconds left, last position].
var _pending: Array = []
## Thralls standing: [SummonedUnit, generation].
var _risen: Array = []
## Tendril rings just risen, for drawing: [position, game time, radius].
var _fx: Array = []
## Candidate [hp, enemy] pairs of a cast.
var _cands: Array = []


## Tracks the Thralls, raises the pending tendrils and casts on cooldown.
func step(delta: float, stats: Dictionary) -> void:
	_track()
	_step_pending(delta, stats)
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	if not _pending.is_empty() or not _fx.is_empty():
		queue_redraw()


## Marks the strongest foes in range. Returns false when nobody is in range.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach, _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not e.active or e.is_structure or p.distance_to(e.position) > reach:
			continue
		var marked := false  # Already under rising tendrils.
		for t: Array in _pending:
			marked = marked or (t[0] == e and int(t[1]) == e.generation)
		if not marked:
			_cands.append([e.hp, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var n := mini(int(stats["targets"]), _cands.size())
	for k in n:
		if _pending.size() >= CallDrownedData.MAX_PENDING:
			break
		var e: Enemy = _cands[k][1]
		_pending.append([e, e.generation, CallDrownedData.TENDRIL_DELAY, e.position])
	game.stat_add("drowned_casts", 1.0)
	game.player.cast_motion(p)  # Engine motion: a pulse as the sea answers (visual only).
	return true


## Counts down the marked tendrils (their ring follows a living target) and
## raises the ones that are due.
func _step_pending(delta: float, stats: Dictionary) -> void:
	var i := _pending.size() - 1
	while i >= 0:
		var t: Array = _pending[i]
		var e: Enemy = t[0]
		if e.active and e.generation == int(t[1]):
			t[3] = e.position
		t[2] = float(t[2]) - delta
		if float(t[2]) <= 0.0:
			_pending.remove_at(i)
			_erupt(t[3], stats)
		i -= 1


## The tendrils burst up at `pos`: damage and a slow to every foe in reach;
## the ones they kill rise as Thralls.
func _erupt(pos: Vector2, stats: Dictionary) -> void:
	var host := stats.has("host")  # Evolved into Tidecaller's Host.
	var r := float(stats["radius"])
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var src := CallDrownedData.HOST_SOURCE if host else CallDrownedData.SOURCE
	for e: Enemy in hits:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var gen := e.generation  # To tell a kill from a survivor.
		var at := e.position  # Where it would rise.
		var can_rise := _can_rise(e)  # Read before the hit pools it.
		game.combat.slow_enemy(e, CallDrownedData.SLOW, CallDrownedData.SLOW_TIME)
		game.combat.damage_enemy(e, float(stats["damage"]), src)
		if can_rise and (not e.active or e.generation != gen):
			_raise(at, stats, host)
	game.stat_add("drowned_tendrils", 1.0)
	_fx.append([pos, game.elapsed, r])
	if _fx.size() > CallDrownedData.MAX_PENDING * 2:
		_fx.pop_front()
	game.effects.ring(pos, r, SpireGlyphs.HOST_TINT if host else Palette.EYE_DROWNED, 0.35, "drowned_tendrils")
	Sfx.play("corpse_burst", pos, 0.7)


## True when a foe the tendrils kill may rise as a Thrall.
static func _can_rise(e: Enemy) -> bool:
	return not (e.is_boss or e.is_miniboss or e.is_structure or e.is_reckoning or e.is_objective \
			or e.kind in CallDrownedData.NEVER_RISE)


## A drowned foe rises at `pos` as the necromancer's Thrall (a Spawn of the
## Deep once evolved), unless the cap is full.
func _raise(pos: Vector2, stats: Dictionary, host: bool) -> void:
	var extra := int(game.character.innate_value("thrall_cap_bonus"))  # The Tide Widow's extra Thralls (0 for the others).
	var cap := (CallDrownedData.HOST_MAX if host else CallDrownedData.THRALL_MAX) + extra
	if _risen.size() >= cap:
		game.stat_add("drowned_cap_refusals", 1.0)
		return
	if extra > 0 and _risen.size() >= cap - extra:
		game.stat_add("drowned_widow_extra", 1.0)  # A Thrall only the innate allowed (autotest).
	var hp := float(stats["thrall_hp"]) * (1.0 + game.character.innate_value("thrall_hp_bonus"))  # HP share (+ the innate).
	var cls := CallDrownedData.HOST_CLASS if host else CallDrownedData.THRALL_CLASS
	var u := game.horde.spawn_temporary(cls, pos, float(stats["life"]), hp, float(stats["thrall_damage"]))
	u.dmg_source = CallDrownedData.HOST_TAG if host else CallDrownedData.THRALL_TAG
	u.glyph_kind = CallDrownedData.HOST_GLYPH if host else CallDrownedData.THRALL_TAG
	u.queue_redraw()
	_risen.append([u, u.generation])
	game.stat_add("drowned_host_risen" if host else "drowned_risen", 1.0)
	game.effects.ring(pos, 22.0, Palette.NECRO_GREEN, 0.45)


## Drops the Thralls that crumbled or fell.
func _track() -> void:
	var i := _risen.size() - 1
	while i >= 0:
		var rec: Array = _risen[i]
		var u: SummonedUnit = rec[0]
		if not u.active or u.generation != int(rec[1]):
			_risen.remove_at(i)
		i -= 1


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d tendrils=%d thralls=%d host=%d cap_refused=%d thrall_dmg=%d host_dmg=%d thrall_kills=%d widow_extra=%d" % [
		int(st.get("drowned_casts", 0.0)), int(st.get("drowned_tendrils", 0.0)), int(st.get("drowned_risen", 0.0)),
		int(st.get("drowned_host_risen", 0.0)), int(st.get("drowned_cap_refusals", 0.0)),
		int(st.get("dmg_" + CallDrownedData.THRALL_TAG, 0.0)), int(st.get("dmg_" + CallDrownedData.HOST_TAG, 0.0)),
		int(st.get("kills_by_" + CallDrownedData.THRALL_TAG, 0.0)) + int(st.get("kills_by_" + CallDrownedData.HOST_TAG, 0.0)),
		int(st.get("drowned_widow_extra", 0.0))]


## The tendril rings: closing on the marked foes, then the tendrils rising.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for t: Array in _pending:
		var k := 1.0 - clampf(float(t[2]) / CallDrownedData.TENDRIL_DELAY, 0.0, 1.0)
		SpireGlyphs.draw_tendril_mark(self, t[3], 30.0, k)
	var i := _fx.size() - 1
	while i >= 0:
		var f: Array = _fx[i]
		var age := now - float(f[1])
		if age > CallDrownedData.RISE_FX_TIME:
			_fx.remove_at(i)
		else:
			SpireGlyphs.draw_tendrils(self, f[0], float(f[2]), age / CallDrownedData.RISE_FX_TIME)
		i -= 1
