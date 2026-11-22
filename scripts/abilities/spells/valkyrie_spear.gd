## ValkyrieSpear — the Valkyrie Spear spell (AbilityData "valkyrie_spear";
## Valgard, the Hall of the Slain temporarily Act XI; GDD §15.0 "Valkyrie Spear,
## Chooser of the Slain, Einherjar's Oath and the Shield-Maiden (Valgard)";
## owner-approved proposal: "a spectral spear dives on the strongest enemy and
## chains to the next"; unlocked by slaying Sigrun, then offered on every stage
## at the later-item card weight). Every `cooldown` s a spectral spear falls
## (ValkyrieSpearData.FALL_TIME) on the enemy with the most HP left within
## `range` px of the necromancer (then the nearest, then by position), strikes
## it for `damage` (CombatResolver.damage_enemy(), a spell source), then LEAPS
## to the nearest enemy it has not struck within `chain` px of the last strike,
## `jumps` times, CHAIN_GAP s apart, each strike x `falloff` of the last.
## EINHERJAR'S OATH (the paired passive): oath_jumps more leaps and
## +oath_damage on every strike. The Shield-Maiden's Shield-Sister (innate
## value valkyrie_spear_extra_jumps): one more leap. Evolved into CHOOSER OF
## THE SLAIN (EvolutionData "chooser_of_the_slain", detected by the
## "risen_time" key): more leaps and damage, x elite_mult on elites, minibosses
## and bosses, and every chosen_every-th foe it kills that leaves a corpse
## rises where it fell as a temporary Warrior for risen_time s
## (HordeDirector.spawn_temporary(), the one path; at most risen_cap at once).
## Works the same on every stage (no act rule).
## Determinism: no RNG; targets sorted by HP, distance, then position.
## Stats: valkyrie_spears, valkyrie_spear_strikes, valkyrie_spear_kills,
## valkyrie_spear_extra, chosen_risen, chosen_capped; damage as
## dmg_valkyrie_spear / dmg_chooser_of_the_slain.
class_name ValkyrieSpear
extends NecroSpell

## Strikes waiting to land: {t (game s), e (Enemy), gen (int), at (Vector2:
## where its target stood when chosen), dmg (float), left (leaps after it),
## from (Vector2: where the spear comes from, drawing)}.
var _strikes: Array[Dictionary] = []
## Enemies this cast struck (Enemy -> generation): no strike twice.
var _struck: Dictionary = {}
## Seconds until the next cast may start.
var _cd: float = 0.0
## Strike flashes fading (drawing only): {a, b (Vector2), t (game s)}.
var _flashes: Array[Dictionary] = []
## Kills of the evolved spear this run (Chooser of the Slain's count).
var _kills_evolved: int = 0
## Where chosen foes fell, waiting to rise (evolved).
var _pending: PackedVector2Array = PackedVector2Array()
## Living chosen warriors as [SummonedUnit, generation] pairs.
var _risen: Array = []
## The current effective stats (the last step's row).
var _stats: Dictionary = {}
## True once Chooser of the Slain.
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; lands the strikes and their leaps; raises the chosen.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_evolved = stats.has("risen_time")
	var now := game.elapsed
	var i := 0
	while i < _flashes.size():
		if now >= float(_flashes[i]["t"]) + ValkyrieSpearData.FLASH_FADE:
			_flashes.remove_at(i)
			continue
		i += 1
	i = 0
	while i < _strikes.size():
		if now >= float(_strikes[i]["t"]):
			var s: Dictionary = _strikes[i]
			_strikes.remove_at(i)
			_strike(s)
			continue
		i += 1
	if _strikes.is_empty():
		_cd -= delta
		if _cd <= 0.0:
			_cd = float(stats["cooldown"]) if _cast() else ValkyrieSpearData.WAIT_RETRY
	if _evolved:
		_raise_pending()
	var busy := not _strikes.is_empty() or not _flashes.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## A new spear on the strongest enemy in range. False when none stands there.
func _cast() -> bool:
	var at := game.player.position
	var r := float(_stats["range"])
	var found: Array = []  # Own buffer.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, found)
	var best: Enemy = null
	var best_hp := -INF
	var best_d := INF
	for e: Enemy in found:
		if not is_open_target(e):
			continue
		var d := e.position.distance_to(at)
		if d > r + e.radius:
			continue
		var left := e.hp - e.incoming_damage
		if left > best_hp or (left == best_hp and (d < best_d or (d == best_d and (e.position.x < best.position.x \
				or (e.position.x == best.position.x and e.position.y < best.position.y))))):
			best = e
			best_hp = left
			best_d = d
	if best == null:
		return false
	var ab := game.abilities
	var extra := roundi(game.character.innate_value(ValkyrieSpearData.EXTRA_KEY))
	var jumps := int(_stats["jumps"]) + roundi(ab.passive_value(ValkyrieSpearData.OATH, ValkyrieSpearData.OATH_JUMPS_KEY)) + extra
	var dmg := float(_stats["damage"]) * (1.0 + ab.passive_value(ValkyrieSpearData.OATH, ValkyrieSpearData.OATH_DAMAGE_KEY))
	_struck.clear()
	_struck[best] = best.generation
	_strikes.append({"t": game.elapsed + ValkyrieSpearData.FALL_TIME, "e": best, "gen": best.generation, "at": best.position,
		"dmg": dmg, "left": jumps, "from": best.position + Vector2(0.0, -ValkyrieSpearData.FALL_HEIGHT)})
	game.stat_add("valkyrie_spears", 1.0)
	if extra > 0:
		game.stat_add("valkyrie_spear_extra", float(extra))
	Sfx.play("lance_cast", best.position, 0.8)  # A startup-bank sound: the spell plays on every stage.
	return true


## One strike lands (if its target still stands), then the spear leaps on.
func _strike(s: Dictionary) -> void:
	var e: Enemy = s["e"]
	var at: Vector2 = s["at"]
	if e.active and e.generation == int(s["gen"]):
		at = e.position
		var hit := float(s["dmg"])
		if _evolved and (e.is_elite or e.is_boss or e.is_miniboss):
			hit *= float(_stats["elite_mult"])
		var corpse := e.leaves_corpse()
		var gen := e.generation
		game.combat.damage_enemy(e, hit, ValkyrieSpearData.EVOLVED_SOURCE if _evolved else ValkyrieSpearData.SOURCE)
		game.stat_add("valkyrie_spear_strikes", 1.0)
		if not e.active or e.generation != gen:
			game.stat_add("valkyrie_spear_kills", 1.0)
			if _evolved:
				_kills_evolved += 1
				if corpse and _kills_evolved % maxi(1, int(_stats["chosen_every"])) == 0:
					_pending.append(at)
	_flashes.append({"a": s["from"], "b": at, "t": game.elapsed})
	var left := int(s["left"])
	if left <= 0:
		return
	var next := _next_target(at, float(_stats["chain"]))
	if next == null:
		return
	_struck[next] = next.generation
	_strikes.append({"t": game.elapsed + ValkyrieSpearData.CHAIN_GAP, "e": next, "gen": next.generation, "at": next.position,
		"dmg": float(s["dmg"]) * float(_stats["falloff"]), "left": left - 1, "from": at})


## The nearest open enemy within `reach` px of `p` this cast has not struck
## (ties by position), or null.
func _next_target(p: Vector2, reach: float) -> Enemy:
	var found: Array = []  # Own buffer.
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, found)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in found:
		if not is_open_target(e) or (_struck.has(e) and int(_struck[e]) == e.generation):
			continue
		var d := e.position.distance_to(p)
		if d > reach + e.radius:
			continue
		if d < best_d or (d == best_d and best != null and (e.position.x < best.position.x \
				or (e.position.x == best.position.x and e.position.y < best.position.y))):
			best = e
			best_d = d
	return best


## Chooser of the Slain: the chosen rise where they fell (at most risen_cap at once).
func _raise_pending() -> void:
	var i := 0
	while i < _risen.size():
		var u: SummonedUnit = _risen[i][0]
		if not u.active or u.generation != int(_risen[i][1]) or u.state == SummonedUnit.State.DEAD:
			_risen.remove_at(i)
			continue
		i += 1
	while not _pending.is_empty():
		var p := _pending[0]
		_pending.remove_at(0)
		if _risen.size() >= int(_stats["risen_cap"]):
			game.stat_add("chosen_capped", 1.0)
			continue
		var u := game.horde.spawn_temporary(ValkyrieSpearData.RISEN_CLASS, p, float(_stats["risen_time"]),
				float(_stats["risen_hp"]), float(_stats["risen_damage"]))
		if u != null:
			_risen.append([u, u.generation])
			game.stat_add("chosen_risen", 1.0)


## Autotest counters (ValgardReport's Valkyrie Spear line).
func summary_extra() -> String:
	var st := game.stats
	return "spears=%d strikes=%d kills=%d (extra leaps %d) chosen risen=%d capped=%d" % [int(st.get("valkyrie_spears", 0.0)),
		int(st.get("valkyrie_spear_strikes", 0.0)), int(st.get("valkyrie_spear_kills", 0.0)), int(st.get("valkyrie_spear_extra", 0.0)),
		int(st.get("chosen_risen", 0.0)), int(st.get("chosen_capped", 0.0))]


## The falling spear and each strike's fading leap line. Textures only (a
## stretched disc for the shaft and the lines).
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var col := ValkyrieSpearData.SPEAR_COLOR
	for s in _strikes:
		var k := clampf(1.0 - (float(s["t"]) - now) / maxf(ValkyrieSpearData.FALL_TIME, 0.01), 0.0, 1.0)  # 0 -> 1 as it lands.
		var from: Vector2 = s["from"]
		var to: Vector2 = s["at"]
		var tip := from.lerp(to, k)
		var d := tip - from
		if d.length() < 1.0:
			d = (to - from).normalized() * 12.0
		var tail := tip - d.normalized() * 22.0
		_line(tail, tip, 3.0, Color(col, 0.9))
		SpriteBank.draw_disc(self, tip, 2.5, Color(1.0, 1.0, 1.0, 0.95))
	for f in _flashes:
		var a := clampf(1.0 - (now - float(f["t"])) / ValkyrieSpearData.FLASH_FADE, 0.0, 1.0)
		_line(f["a"], f["b"], 2.0, Color(col, 0.75 * a))
		SpriteBank.draw_disc(self, f["b"], 4.0 + 6.0 * (1.0 - a), Color(col, 0.55 * a))


## A line of `width` px from `a` to `b` as a stretched disc texture.
func _line(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var d := b - a
	var len := d.length()
	if len < 1.0:
		return
	draw_set_transform(a, d.angle(), Vector2.ONE)
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(0.0, -width * 0.5), Vector2(len, width)), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
