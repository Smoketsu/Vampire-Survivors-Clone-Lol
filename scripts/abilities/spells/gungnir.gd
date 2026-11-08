## Gungnir — the Gungnir spell (AbilityData "gungnir"; Vigrid, the Hall of the
## Slain's finale, temporarily Act XI; GDD §15.0 "Gungnir, Spear of the
## Hanged, Runecraft and the Berserker"; owner-approved proposal: "Gungnir: a
## spear thrown at the strongest enemy on screen that pierces everything in its
## line"; unlocked by defeating Odin, then offered on every stage at the
## later-item card weight). Every `cooldown` s a spear of soul-light is thrown
## from the necromancer at the STRONGEST open foe within GungnirData.AIM_RANGE
## px (the most HP left; one more spear at the next strongest for each extra:
## the evolution's `spears`, the Berserker's Bear-Shirt, at most MAX_SPEARS):
## it flies `length` px along that line at once and strikes EVERY foe whose
## body it crosses (within `spear_width` px of the line) for `damage`
## (CombatResolver.damage_enemy(), the friendly damage path; no shield or body
## stops it). Evolved into SPEAR OF THE HANGED (EvolutionData
## "spear_of_the_hanged", detected by the "return_share" key): two spears a
## cast, wider and longer, and each RETURNS to the thrower's hand along its
## line return_delay s later, striking everything on it again for return_share
## x the damage. RUNECRAFT (the paired passive): its cooldown share and its
## width are applied by AbilityManager.apply_spell_mods() on the spell's own
## keys. Determinism: no RNG; the strongest foes by HP, ties in the spatial
## hash's order. Stats: gungnir_casts, gungnir_spears, gungnir_hits,
## gungnir_returns; damage as dmg_gungnir / dmg_spear_of_the_hanged.
class_name Gungnir
extends NecroSpell

## One thrown spear's line (drawn while it shows; a return waits on it).
class Throw:
	extends RefCounted
	## Where it was thrown from (world px).
	var from: Vector2 = Vector2.ZERO
	## Where its line ends (world px).
	var to: Vector2 = Vector2.ZERO
	## Px each side of the line it strikes.
	var width: float = 10.0
	## Game time (s) it was thrown.
	var t: float = 0.0
	## Game time (s) it comes back (INF = it does not).
	var back_at: float = INF
	## Damage of the return pass.
	var back_dmg: float = 0.0

## Seconds until the next cast.
var _cd: float = 0.0
## Spears drawn or waiting to return.
var throws: Array[Throw] = []
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


## Casts when ready; brings the evolved spears back.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		var n := mini(int(stats.get("spears", 1)) + int(game.character.innate_value(GungnirData.EXTRA_KEY)), GungnirData.MAX_SPEARS)
		_cd = float(stats["cooldown"]) if _cast(n, stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < throws.size():
		var th := throws[i]
		if game.elapsed >= th.back_at:
			th.back_at = INF
			th.t = game.elapsed  # Drawn again on its way back.
			var hits := _strike_line(th.to, th.from, th.width, th.back_dmg, GungnirData.EVOLVED_SOURCE)
			game.stat_add("gungnir_returns", 1.0)
			game.stat_add("gungnir_hits", float(hits))
		if th.back_at == INF and game.elapsed - th.t > GungnirData.STREAK_TIME:
			throws.remove_at(i)
			continue
		i += 1
	var busy := not throws.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Throws `n` spears at the strongest open foes in reach. False when none is
## in reach.
func _cast(n: int, stats: Dictionary) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, GungnirData.AIM_RANGE, _tmp)
	var picked: Array[Enemy] = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or e.civilian or picked.has(e) or e.position.distance_to(p) > GungnirData.AIM_RANGE:
				continue
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		picked.append(best)
	if picked.is_empty():
		return false
	var evolved := stats.has("return_share")
	var src := GungnirData.EVOLVED_SOURCE if evolved else GungnirData.SOURCE
	var dmg := float(stats["damage"])
	var length := float(stats.get("length", 640.0))
	var width := float(stats.get("spear_width", 10.0))
	for e in picked:
		var dir := (e.position - p).normalized() if e.position.distance_to(p) > 1.0 else Vector2.RIGHT
		var th := Throw.new()
		th.from = p
		th.to = p + dir * length
		th.width = width
		th.t = game.elapsed
		if evolved:
			th.back_at = game.elapsed + float(stats.get("return_delay", 0.35))
			th.back_dmg = dmg * float(stats["return_share"])
		throws.append(th)
		var hits := _strike_line(th.from, th.to, width, dmg, src)
		game.stat_add("gungnir_spears", 1.0)
		game.stat_add("gungnir_hits", float(hits))
	game.stat_add("gungnir_casts", 1.0)
	return true


## Strikes every foe whose body the line a -> b (`w` px each side) crosses for
## `dmg` (tag `src`); returns how many it struck.
func _strike_line(a: Vector2, b: Vector2, w: float, dmg: float, src: String) -> int:
	var ab := b - a
	var len2 := maxf(ab.length_squared(), 1.0)
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(a.lerp(b, 0.5), sqrt(len2) * 0.5 + w + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active:
			continue
		var k := clampf((e.position - a).dot(ab) / len2, 0.0, 1.0)
		if e.position.distance_to(a + ab * k) > w + e.radius:
			continue
		game.combat.damage_enemy(e, dmg, src, -1, a)
		n += 1
	return n


## Autotest counters (the Gungnir line of VigridReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d spears=%d hits=%d returns=%d" % [int(st.get("gungnir_casts", 0.0)), int(st.get("gungnir_spears", 0.0)),
		int(st.get("gungnir_hits", 0.0)), int(st.get("gungnir_returns", 0.0))]


## The spears' streaks: a long soft line of soul-light with a bright head,
## fading (textures only, under a rotation). Visual only.
func _draw() -> void:
	if game == null:
		return
	for th in throws:
		var k := clampf((game.elapsed - th.t) / GungnirData.STREAK_TIME, 0.0, 1.0)
		if th.back_at < INF and k >= 1.0:
			continue  # Waiting to come back: nothing shows.
		var back := th.back_at == INF and th.back_dmg > 0.0 and game.elapsed - th.t <= GungnirData.STREAK_TIME and game.elapsed > th.t
		var a := th.to if back else th.from
		var b := th.from if back else th.to
		var ab := b - a
		var head := a + ab * clampf(k * 2.5, 0.0, 1.0)  # The spear flies out fast, the streak lingers.
		draw_set_transform(a, ab.angle(), Vector2.ONE)
		var l := a.distance_to(head)
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(0.0, -th.width * 0.5), Vector2(l, th.width)), false, Color(GungnirData.COLOR, 0.35 * (1.0 - k)))
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(l - 14.0, -2.5), Vector2(18.0, 5.0)), false, Color(GungnirData.COLOR, 0.95 * (1.0 - k * 0.6)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
