## FeathersVerdict — the Feather's Verdict spell (AbilityData "feathers_verdict";
## temporary Act XII, the Hall of Two Truths; GDD §15.0 "Feather's Verdict, Heart
## Devoured, Heavy Heart and the Pharaoh's Shade"; owner-approved proposal: "a
## gold feather lands on the strongest enemy and executes weak enemies in a ring
## around it"; unlocked by defeating Osiris and Ammit, then offered on every
## stage at the later-item card weight). Every `cooldown` s a gold feather (the
## player's: true gold) falls on the STRONGEST open foe within `range` px of the
## necromancer (the most HP left; the Sandstorm halves the reach through the
## spells' "range", the one path) and, after FeathersVerdictData.FALL_TIME s,
## lands: `damage` to it, then every OTHER foe within `ring` px whose health is
## at or under `execute` of its max HP is EXECUTED (CombatResolver.damage_enemy(),
## the friendly damage path, with EXECUTE_OVERKILL x its max HP: a kill through
## its armour). Bosses, minibosses and structures are struck but never
## executed. HEART DEVOURED (EvolutionData "heart_devoured", detected by the
## "feathers" key): `feathers` feathers a cast on the strongest foes in turn, a
## higher line and a wider ring, and every execution heals the necromancer
## `devour_heal` HP (at most devour_cap a cast). HEAVY HEART (the paired
## passive): its execute line and its ring through
## AbilityManager.apply_spell_mods() on the spell's own keys; the Pharaoh's
## Shade's Crook and Flail adds to the line here (FeathersVerdictData.INNATE_KEY).
## Determinism: no RNG; the strongest foes by HP, ties in the spatial hash's
## order; the fall on game time. Stats: verdict_casts, verdict_feathers,
## verdict_executions, verdict_healed; damage as dmg_feathers_verdict /
## dmg_feathers_verdict_execute / dmg_heart_devoured /
## dmg_heart_devoured_execute.
class_name FeathersVerdict
extends NecroSpell

## Seconds until the next cast.
var _cd: float = 0.0
## Falling feathers: {e (Enemy), gen (int), at (world px), t (s fallen)}.
var falling: Array[Dictionary] = []
## Landed rings drawn fading: {at, r, t (game s)}.
var _rings: Array[Dictionary] = []
## The stats row of the last step (a landing strikes with it).
var _stats: Dictionary = {}
## HP healed by Heart Devoured during the current cast (its cap).
var _healed_cast: float = 0.0
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


## Casts when ready; the feathers fall and land.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_cd -= delta
	if _cd <= 0.0:
		if _cast(mini(int(stats.get("feathers", 1)), FeathersVerdictData.MAX_FEATHERS), stats):
			_cd = float(stats["cooldown"])
		else:
			_cd = AbilityData.SPELL_RETRY
	_step_falling(delta)
	while not _rings.is_empty() and game.elapsed - float(_rings[0]["t"]) > FeathersVerdictData.RING_FADE:
		_rings.pop_front()
	var busy := not falling.is_empty() or not _rings.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Picks the `n` strongest open foes within reach; a feather starts falling on
## each. False when none is in reach.
func _cast(n: int, stats: Dictionary) -> bool:
	var p := game.player.position
	var reach := float(stats.get("range", 300.0))
	game.enemy_grid.query(p, reach, _tmp)
	var picked: Array[Enemy] = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or e.civilian or picked.has(e) or e.position.distance_to(p) > reach:
				continue
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		picked.append(best)
	if picked.is_empty():
		return false
	for e in picked:
		falling.append({"e": e, "gen": e.generation, "at": e.position, "t": 0.0})
		game.stat_add("verdict_feathers", 1.0)
	_healed_cast = 0.0
	game.stat_add("verdict_casts", 1.0)
	return true


## Ages every falling feather; one whose fall ended lands where its foe stands
## (or where it fell, if the foe died meanwhile).
func _step_falling(delta: float) -> void:
	var i := 0
	while i < falling.size():
		var f := falling[i]
		var e: Enemy = f["e"]
		var alive := e != null and e.active and e.generation == int(f["gen"])
		if alive:
			f["at"] = e.position
		f["t"] = float(f["t"]) + delta
		if float(f["t"]) < FeathersVerdictData.FALL_TIME:
			i += 1
			continue
		falling.remove_at(i)
		_land(e if alive else null, f["at"])


## The feather lands at `at` on `e` (null when it died meanwhile): its blow,
## then the executions in its ring.
func _land(e: Enemy, at: Vector2) -> void:
	var evolved := _stats.has("feathers")
	var src := FeathersVerdictData.EVOLVED_SOURCE if evolved else FeathersVerdictData.SOURCE
	var ex_src := FeathersVerdictData.EVOLVED_EXECUTE_SOURCE if evolved else FeathersVerdictData.EXECUTE_SOURCE
	if e != null and e.active:
		game.combat.damage_enemy(e, float(_stats.get("damage", 40.0)), src)
	var line := float(_stats.get("execute", 0.2)) + game.character.innate_value(FeathersVerdictData.INNATE_KEY)
	var r := float(_stats.get("ring", 60.0))
	var hits: Array = []
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	for o: Enemy in hits:
		if o == e or not o.active or o.is_boss or o.is_miniboss or o.is_structure or o.civilian:
			continue
		if o.position.distance_to(at) > r + o.radius or o.hp > o.max_hp * line:
			continue
		game.effects.pop(o.position, TwoTruthsGlyphs.FEATHER, 8.0)
		game.combat.damage_enemy(o, o.max_hp * FeathersVerdictData.EXECUTE_OVERKILL, ex_src)
		game.stat_add("verdict_executions", 1.0)
		if evolved:
			_devour_heal()
	game.effects.ring(at, r, TwoTruthsGlyphs.FEATHER, 0.3)
	_rings.append({"at": at, "r": r, "t": game.elapsed})


## Heart Devoured: an execution heals the necromancer (capped a cast).
func _devour_heal() -> void:
	var room := float(_stats.get("devour_cap", 6.0)) - _healed_cast
	var amt := minf(float(_stats.get("devour_heal", 0.5)), room)
	if amt <= 0.0:
		return
	var healed := game.combat.heal_player(amt)  # The one heal path.
	_healed_cast += amt
	game.stat_add("verdict_healed", healed)


## Autotest counters (the Feather's Verdict line of TwoTruthsReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d feathers=%d executions=%d healed=%d" % [int(st.get("verdict_casts", 0.0)), int(st.get("verdict_feathers", 0.0)),
		int(st.get("verdict_executions", 0.0)), int(st.get("verdict_healed", 0.0))]


## The falling feathers and the fading rings. Textures and rects only.
## Visual only.
func _draw() -> void:
	if game == null:
		return
	for f in falling:
		var k := clampf(float(f["t"]) / FeathersVerdictData.FALL_TIME, 0.0, 1.0)
		var at: Vector2 = f["at"]
		TwoTruthsGlyphs.draw_feather(self, at + Vector2(sin(k * 9.0) * 6.0 * (1.0 - k), -FeathersVerdictData.FALL_PX * (1.0 - k) - 10.0), 0.9)
		SpriteBank.draw_disc(self, at, 6.0 + 8.0 * k, Color(TwoTruthsGlyphs.FEATHER, 0.18 * k))
	for b in _rings:
		var k := clampf((game.elapsed - float(b["t"])) / FeathersVerdictData.RING_FADE, 0.0, 1.0)
		SpriteBank.draw_disc(self, b["at"], float(b["r"]) * (0.6 + 0.4 * k), Color(TwoTruthsGlyphs.FEATHER, 0.22 * (1.0 - k)))
