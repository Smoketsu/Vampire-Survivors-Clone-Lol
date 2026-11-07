## Moonfang — the Moonfang spell (AbilityData "moonfang"; Act VII, Ravensmoor;
## GDD §15.0 "Moonfang, Wolf of the Red Moon, Pack Blood and the Moon-Cursed
## Huntress (Act VII)"; owner-approved proposal: "spectral wolf jaws snap at the
## nearest group and leave bleeds"; unlocked by slaying Vargr, then offered on
## every stage at the later-item card weight). Every `cooldown` s, `jaws`
## spectral wolf jaws (plus the Moon-Cursed Huntress's Hunter's Moon, innate
## value moonfang_extra_jaws) open over the NEAREST GROUPS of foes within
## `range` px of the necromancer (each group the nearest open foe, the next
## jaw at least MoonfangData.GROUP_APART px from the others), close in
## MoonfangData.SNAP_TIME s and bite: `damage` to every foe within `radius` px,
## and each bitten foe BLEEDS for `bleed_time` s, `bleed_share` x the damage
## per s (a new bite keeps the stronger bleed and the later end), ticking every
## MoonfangData.BLEED_TICK s through CombatResolver.damage_enemy() (source
## moonfang_bleed, so the spell-damage modifiers reach it). Evolved into WOLF OF
## THE RED MOON (EvolutionData "wolf_of_the_red_moon", detected by the "chain"
## key): bigger, harder jaws, and every jaw that bit something leaps on to the
## nearest group within `chain_reach` px it has not bitten yet and snaps again,
## `chain` more times, `chain_gap` s apart. PACK BLOOD (the paired passive) is
## read by CombatResolver.damage_enemy() through bleeding() below. Works the
## same on every stage (no act rule).
## Determinism: no RNG; groups by distance in the spatial hash's order. Stats:
## moonfang_casts, moonfang_jaws, moonfang_hits, moonfang_bleeds,
## moonfang_bleed_ticks, moonfang_chains, moonfang_extra_jaws; damage as
## dmg_moonfang / dmg_wolf_of_the_red_moon / dmg_moonfang_bleed.
class_name Moonfang
extends NecroSpell

## Jaws closing now: {at (world px), t (game s it bites), r, dmg, bleed_dps,
## bleed_time, chains (snaps left after this one), reach (px), gap (s),
## evolved (bool), bitten (Dictionary of the foes this jaw already bit)}.
var snapping: Array[Dictionary] = []
## Jaws that bit, fading (drawn only): {at, t (game s it bit), r, evolved}.
var _fading: Array[Dictionary] = []
## Bleeding foes: Enemy -> [generation, game s the bleed ends, damage per s].
var _bleeds: Dictionary = {}
## Seconds until the next cast.
var _cd: float = 0.0
## Seconds toward the next bleed tick.
var _tick_acc: float = 0.0
## True once Wolf of the Red Moon (drawing).
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; closes the jaws; ticks the bleeds.
func step(delta: float, stats: Dictionary) -> void:
	_evolved = stats.has("chain")
	var now := game.elapsed
	var i := 0
	while i < snapping.size():
		if now >= float(snapping[i]["t"]):
			var s: Dictionary = snapping[i]
			snapping.remove_at(i)
			_bite(s)
			continue
		i += 1
	i = 0
	while i < _fading.size():
		if now >= float(_fading[i]["t"]) + MoonfangData.FADE_TIME:
			_fading.remove_at(i)
			continue
		i += 1
	_tick_acc += delta
	if _tick_acc >= MoonfangData.BLEED_TICK:
		_tick_acc -= MoonfangData.BLEED_TICK
		_bleed(MoonfangData.BLEED_TICK)
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var busy := not snapping.is_empty() or not _fading.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: the jaws pick their groups and open. False when no foe is in range.
func _cast(stats: Dictionary) -> bool:
	var base := int(stats["jaws"])
	var n := base + roundi(game.character.innate_value(MoonfangData.EXTRA_JAWS_KEY))
	var targets := _groups(game.player.position, float(stats["range"]), n, [])
	if targets.is_empty():
		return false
	var evolved := stats.has("chain")
	var now := game.elapsed
	for k in n:
		var at: Vector2 = targets[k % targets.size()]
		snapping.append(_jaw(at, now + MoonfangData.SNAP_TIME + 0.06 * float(k), stats, int(stats.get("chain", 0)), evolved, {}))
	game.stat_add("moonfang_casts", 1.0)
	game.stat_add("moonfang_jaws", float(n))
	if n > base:
		game.stat_add("moonfang_extra_jaws", float(n - base))
	Sfx.play("lance_cast", game.player.position, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## A jaw dictionary (see `snapping`).
func _jaw(at: Vector2, t: float, stats: Dictionary, chains: int, evolved: bool, bitten: Dictionary) -> Dictionary:
	return {"at": at, "t": t, "r": float(stats["radius"]), "dmg": float(stats["damage"]),
		"bleed_dps": float(stats["damage"]) * float(stats["bleed_share"]), "bleed_time": float(stats["bleed_time"]),
		"chains": chains, "reach": float(stats.get("chain_reach", 0.0)), "gap": float(stats.get("chain_gap", 0.0)),
		"evolved": evolved, "bitten": bitten}


## Up to `n` group centres within `reach` px of `from`: each the nearest open
## foe at least GROUP_APART px from the centres already chosen, skipping foes
## in `skip` (a chain's bitten foes). Empty when no foe is in reach.
func _groups(from: Vector2, reach: float, n: int, skip: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cands: Array = []  # [distance, Enemy] of the open foes in reach.
	game.enemy_grid.query(from, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e) or e.untargetable or skip.has(e):
			continue
		var dist := from.distance_to(e.position)
		if dist <= reach:
			cands.append([dist, e])
	if cands.is_empty():
		return out
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c in cands:
		if out.size() >= n or out.size() >= MoonfangData.GROUP_SAMPLES:
			break
		var p: Vector2 = (c[1] as Enemy).position
		var free := true
		for q in out:
			free = free and q.distance_to(p) >= MoonfangData.GROUP_APART
		if free:
			out.append(p)
	return out


## A jaw closes: every foe in its radius is bitten and bleeds; Wolf of the Red
## Moon's jaw then leaps on to the next group.
func _bite(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	var r := float(s["r"])
	var evolved := bool(s["evolved"])
	var src := MoonfangData.EVOLVED_SOURCE if evolved else MoonfangData.SOURCE
	var bitten: Dictionary = s["bitten"]
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not is_open_target(e) or e.position.distance_to(at) > r + e.radius:
			continue
		bitten[e] = true
		game.combat.damage_enemy(e, float(s["dmg"]), src)
		n += 1
		if e.active:
			_add_bleed(e, float(s["bleed_dps"]), float(s["bleed_time"]))
	game.stat_add("moonfang_hits", float(n))
	_fading.append({"at": at, "t": game.elapsed, "r": r, "evolved": evolved})
	game.effects.ring(at, r, Palette.COURT_MOON_LIGHT if not evolved else Palette.COURT_BLOOD_LIGHT, 0.2)
	if n > 0 and int(s["chains"]) > 0:
		var next := _groups(at, float(s["reach"]), 1, bitten.keys())
		if not next.is_empty():
			var j := s.duplicate()
			j["at"] = next[0]
			j["t"] = game.elapsed + float(s["gap"])
			j["chains"] = int(s["chains"]) - 1
			snapping.append(j)
			game.stat_add("moonfang_chains", 1.0)


## Foe `e` bleeds `dps` per s for `time` s (the stronger bleed and the later
## end are kept), unless MAX_BLEEDS foes already bleed.
func _add_bleed(e: Enemy, dps: float, time: float) -> void:
	var until := game.elapsed + time
	var b: Array = _bleeds.get(e, [])
	if not b.is_empty() and int(b[0]) == e.generation and float(b[1]) > game.elapsed:
		b[1] = maxf(float(b[1]), until)
		b[2] = maxf(float(b[2]), dps)
		return
	if not _bleeds.has(e) and _bleeds.size() >= MoonfangData.MAX_BLEEDS:
		return
	_bleeds[e] = [e.generation, until, dps]
	game.stat_add("moonfang_bleeds", 1.0)


## The bleeds tick (stale and finished ones leave).
func _bleed(tick: float) -> void:
	if _bleeds.is_empty():
		return
	var now := game.elapsed
	var done: Array = []  # Foes whose bleed ended.
	var live: Array = []  # [Enemy, damage] of this tick (dealt after the walk).
	for e: Enemy in _bleeds:
		var b: Array = _bleeds[e]
		if not e.active or e.generation != int(b[0]) or now >= float(b[1]):
			done.append(e)
			continue
		live.append([e, float(b[2]) * tick])
	for e in done:
		_bleeds.erase(e)
	for x in live:
		var e: Enemy = x[0]
		if e.active:
			game.combat.damage_enemy(e, float(x[1]), MoonfangData.BLEED_SOURCE)
			game.stat_add("moonfang_bleed_ticks", 1.0)


## True while foe `e` bleeds from this spell.
func is_bleeding(e: Enemy) -> bool:
	var b: Array = _bleeds.get(e, [])
	return not b.is_empty() and int(b[0]) == e.generation and float(b[1]) > game.elapsed


## PACK BLOOD's bleed test (CombatResolver.damage_enemy(), the one read): true
## when foe `e` bleeds from the bound necromancer's Moonfang.
static func bleeding(g: Game, e: Enemy) -> bool:
	var node: NecroSpell = g.abilities.spells.nodes.get(MoonfangData.ID)  # The spell's node, if it ever stepped.
	return node is Moonfang and (node as Moonfang).is_bleeding(e)


## Autotest counters (RavensmoorReport's Moonfang line).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d jaws=%d (extra %d) hits=%d bleeds=%d bleed_ticks=%d chains=%d" % [int(st.get("moonfang_casts", 0.0)), int(st.get("moonfang_jaws", 0.0)),
		int(st.get("moonfang_extra_jaws", 0.0)), int(st.get("moonfang_hits", 0.0)), int(st.get("moonfang_bleeds", 0.0)),
		int(st.get("moonfang_bleed_ticks", 0.0)), int(st.get("moonfang_chains", 0.0))]


## The jaws: two moonlit fangs closing over a faint shadow, then a fading bite
## mark (blood-red once evolved). Textures and short lines only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for s in snapping:
		var at: Vector2 = s["at"]
		var r := float(s["r"])
		var k := clampf(1.0 - (float(s["t"]) - now) / MoonfangData.SNAP_TIME, 0.0, 1.0)  # 0 open .. 1 shut.
		var col: Color = Palette.COURT_BLOOD_LIGHT if bool(s["evolved"]) else Palette.COURT_MOON_LIGHT
		SpriteBank.draw_disc(self, at, r * 0.9, Color(0.0, 0.0, 0.0, 0.18 + 0.12 * k))
		var gap := r * (1.0 - k) * 0.9 + 2.0  # Px between the upper and lower jaw.
		for side: float in [-1.0, 1.0]:
			var y := at.y + side * gap
			draw_line(Vector2(at.x - r, y), Vector2(at.x + r, y), Color(col, 0.7), 2.0)
			for f in 4:
				var x := at.x - r * 0.75 + r * 0.5 * float(f)
				draw_line(Vector2(x, y), Vector2(x + 1.5, y - side * r * 0.35), Color(col, 0.9), 2.0)
	for f in _fading:
		var a := clampf(1.0 - (now - float(f["t"])) / MoonfangData.FADE_TIME, 0.0, 1.0)
		var c: Color = Palette.COURT_BLOOD if bool(f["evolved"]) else Palette.COURT_MOON
		SpriteBank.draw_disc(self, f["at"], float(f["r"]) * 0.8, Color(c, 0.25 * a))
