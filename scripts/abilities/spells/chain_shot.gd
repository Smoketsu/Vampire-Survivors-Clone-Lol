## ChainShot — the Chain Shot spell (AbilityData "chain_shot"; Act X, the
## Smuggler's Cutter; GDD §15.0 "Chain Shot, Keelhauler, Bosun's Whistle and the
## Marooned Quartermaster (Act X)"; owner-approved proposal: "a spectral
## chain-shot spins through a line of enemies and returns"; unlocked by slaying
## Captain Crow, then offered on every stage at the later-item card weight).
## Every `cooldown` s (x 1 - Bosun's Whistle's cooldown_cut), `shots` spectral
## chain-shots (plus the Marooned Quartermaster's Spare Shot, innate value
## chain_extra) are thrown, each at one of the nearest foes within `range` px
## (targets at least ChainShotData.LINE_APART px apart): a shot flies straight
## out `range` px at `speed` px/s through its foe, hangs a moment
## (ChainShotData.TURN_TIME) and spins back to the necromancer, striking every
## foe within `width` px of it ONCE ON THE WAY OUT and ONCE ON THE WAY BACK for
## `damage` (CombatResolver.damage_enemy(), the one damage path). Evolved into
## KEELHAULER (EvolutionData "keelhauler", detected by the "knock" key): every
## foe a shot strikes is also knocked `knock` px off its line (its knockback;
## never a boss, miniboss or structure): on the Black Tide's decks that throws
## them overboard. No pull (owner: the act's spells knock back, chain and
## bombard; none pull). Works the same on every stage (no act rule).
## Determinism: no RNG; targets by distance in the spatial hash's order.
## Stats: chain_casts, chain_shots, chain_extra, chain_hits, chain_knocks,
## chain_whistle_s; damage as dmg_chain_shot / dmg_keelhauler.
class_name ChainShot
extends NecroSpell

## Shots in flight: {from (world px, the throw point), dir (unit), range
## (px), speed (px/s), width (px), dmg,
## knock (px; 0 = none), t0 (game s thrown), out_hit (Enemy -> true), back_hit
## (Enemy -> true), pos (world px, last), back (bool), turn_at (game s it
## turned; -1 before)}.
var shots: Array[Dictionary] = []
## Seconds until the next cast.
var _cd: float = 0.0
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; flies the shots.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := 0
	while i < shots.size():
		if _fly(shots[i], delta, now):
			shots.remove_at(i)
			continue
		i += 1
	_cd -= delta
	if _cd <= 0.0:
		_cd = _cooldown(stats) if _cast(stats) else AbilityData.SPELL_RETRY
	var busy := not shots.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The cooldown after a cast: the row's x Bosun's Whistle.
func _cooldown(stats: Dictionary) -> float:
	var cut := clampf(game.abilities.passive_value(ChainShotData.WHISTLE, ChainShotData.WHISTLE_KEY), 0.0, 0.9)  # 0 when not owned.
	var cd := float(stats["cooldown"])
	if cut > 0.0:
		game.stat_add("chain_whistle_s", cd * cut)
	return cd * (1.0 - cut)


## One cast: the shots pick their foes and fly. False when no foe is in range.
func _cast(stats: Dictionary) -> bool:
	var base := int(stats["shots"])
	var n := base + roundi(game.character.innate_value(ChainShotData.EXTRA_KEY))
	var me := game.player.position
	var targets := _targets(me, float(stats["range"]), n)
	if targets.is_empty():
		return false
	var made := 0
	for k in n:
		if shots.size() >= ChainShotData.MAX_SHOTS:
			break
		var t: Vector2 = targets[k % targets.size()]
		var dir := (t - me).normalized() if t.distance_to(me) > 1.0 else Vector2.RIGHT
		if k >= targets.size():
			dir = dir.rotated(0.35 * float(k / targets.size()))  # More shots than foes: fan out.
		shots.append({"dir": dir, "range": float(stats["range"]), "speed": float(stats["speed"]), "width": float(stats["width"]),
			"dmg": float(stats["damage"]), "knock": float(stats.get("knock", 0.0)), "t0": game.elapsed, "out_hit": {}, "back_hit": {},
			"from": me, "pos": me, "back": false, "turn_at": -1.0, "evolved": stats.has("knock")})
		made += 1
	game.stat_add("chain_casts", 1.0)
	game.stat_add("chain_shots", float(made))
	if made > base:
		game.stat_add("chain_extra", float(made - base))
	Sfx.play("lance_cast", me, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return made > 0


## Up to `n` targets within `reach` px of `from`: each the nearest open foe at
## least LINE_APART px from those already chosen. Empty when no foe is in reach.
func _targets(from: Vector2, reach: float, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cands: Array = []  # [distance, Enemy] of the open foes in reach.
	game.enemy_grid.query(from, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e) or e.untargetable or e.civilian:
			continue
		var dist := from.distance_to(e.position)
		if dist <= reach:
			cands.append([dist, e])
	if cands.is_empty():
		return out
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c in cands:
		if out.size() >= n or out.size() >= ChainShotData.TARGET_SAMPLES:
			break
		var p: Vector2 = (c[1] as Enemy).position
		var free := true
		for q in out:
			free = free and q.distance_to(p) >= ChainShotData.LINE_APART
		if free:
			out.append(p)
	return out


## Flies shot `s` on by `delta` s: out along its line, a short turn, then home
## to the necromancer (who may have moved). True when it is caught.
func _fly(s: Dictionary, delta: float, now: float) -> bool:
	var me := game.player.position
	var p: Vector2 = s["pos"]
	var step := float(s["speed"]) * delta
	if not bool(s["back"]):
		var out := (now - float(s["t0"])) * float(s["speed"])  # px thrown so far.
		p = (s["from"] as Vector2) + (s["dir"] as Vector2) * minf(out, float(s["range"]))
		if out >= float(s["range"]):
			if float(s["turn_at"]) < 0.0:
				s["turn_at"] = now
			elif now - float(s["turn_at"]) >= ChainShotData.TURN_TIME:
				s["back"] = true
	else:
		var to := me - p
		if to.length() <= ChainShotData.CATCH_RADIUS + step:
			return true
		p += to.normalized() * step
	s["pos"] = p
	_strike(s, p)
	return false


## Shot `s` at `at` strikes every open foe in reach it has not struck on this
## leg (out or back).
func _strike(s: Dictionary, at: Vector2) -> void:
	var hit: Dictionary = s["back_hit"] if bool(s["back"]) else s["out_hit"]
	var width := float(s["width"])
	var src := ChainShotData.EVOLVED_SOURCE if bool(s["evolved"]) else ChainShotData.SOURCE
	var knock := float(s["knock"])
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, width + ProjectileManager.MAX_BODY_RADIUS, hits)
	for e: Enemy in hits:
		if not e.active or e.untargetable or hit.has(e) or e.position.distance_to(at) > width + e.radius:
			continue
		hit[e] = true
		var off := e.position - at
		game.combat.damage_enemy(e, float(s["dmg"]), src)
		game.stat_add("chain_hits", 1.0)
		if knock > 0.0 and e.active and not (e.is_boss or e.is_miniboss or e.is_structure):
			var dir: Vector2 = s["dir"]
			var side := Vector2(-dir.y, dir.x)
			side *= signf(off.dot(side)) if absf(off.dot(side)) > 0.5 else 1.0
			e.knockback += side * sqrt(2.0 * EnemyData.KNOCKBACK_DECAY * knock) / maxf(e.mass, 0.1)
			game.stat_add("chain_knocks", 1.0)


## Autotest counters (CutterReport's Chain Shot line).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d shots=%d (extra %d) hits=%d knocks=%d whistle_s=%.0f" % [int(st.get("chain_casts", 0.0)), int(st.get("chain_shots", 0.0)),
		int(st.get("chain_extra", 0.0)), int(st.get("chain_hits", 0.0)), int(st.get("chain_knocks", 0.0)), float(st.get("chain_whistle_s", 0.0))]


## The chain-shots: two spectral iron balls on a short chain, spinning, a pale
## green glow (Keelhauler's a brighter, barnacled bone). Disc textures and one
## line each; visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for s in shots:
		var p: Vector2 = s["pos"]
		var a := now * ChainShotData.SPIN + float(s["t0"])
		var off := Vector2.from_angle(a) * ChainShotData.BALL_SPREAD
		var glow := Color(0.55, 1.0, 0.8, 0.28) if not bool(s["evolved"]) else Color(0.85, 1.0, 0.9, 0.36)
		SpriteBank.draw_disc(self, p, ChainShotData.BALL_SPREAD + 6.0, glow)
		draw_line(p - off, p + off, Color(0.75, 0.95, 0.85, 0.9), 1.5)
		for b: Vector2 in [p - off, p + off]:
			SpriteBank.draw_disc(self, b, 4.0, Palette.CORSAIR_INK)
			SpriteBank.draw_disc(self, b, 3.0, Palette.CORSAIR_POWDER if not bool(s["evolved"]) else Palette.BONE)
