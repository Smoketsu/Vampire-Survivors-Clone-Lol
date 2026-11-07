## FallFromGrace — the Fall from Grace spell (AbilityData "fall_from_grace";
## Act VI, Pandemonium; GDD §15.0 "Fall from Grace, Lightbringer, Pride and the
## Fallen Saint"; owner-approved proposal: "a fallen star crashes on the
## strongest enemy"; unlocked by defeating the Morning Star, then offered on
## every stage at the later-item card weight). Every `cooldown` s it calls
## `stars` falling star(s) (1 before the evolution) down on the STRONGEST foes:
## the open foes with the most HP left within FallFromGraceData.AIM_RANGE px of
## the necromancer, one star each. A star falls for `fall_time` s, following its
## target (it lands where the target last stood if it died first), then
## CRASHES: the target takes `damage` and every other foe within
## `radius` px takes `splash` x that (CombatResolver.damage_enemy(), the
## friendly damage path). Evolved into LIGHTBRINGER (EvolutionData
## "lightbringer", detected by the "flare" key): three stars a cast, harder and
## wider, and each crash sends a FLARE ring out to FLARE_RADIUS_MULT x the
## crash radius (`flare` x the damage to every foe in the ring beyond the
## crash). PRIDE (the paired passive): its cooldown share is applied by
## AbilityManager.apply_spell_mods(), and a star deals `pride_bonus` more to an
## ELITE, a miniboss or a boss it strikes (the effective stat it writes). The
## Fallen Saint's innate (Second Fall, innate value grace_second_star): every
## cast also drops a SECOND star on the next-strongest foe for that share of
## the damage.
## Determinism: no RNG; the strongest foe by HP, ties in the spatial hash's
## order. Stats: grace_casts, grace_stars, grace_crashes, grace_hits,
## grace_proud_hits, grace_second_stars, grace_flares; damage as
## dmg_fall_from_grace / dmg_lightbringer / dmg_lightbringer_flare.
class_name FallFromGrace
extends NecroSpell

## Stars in the sky: {target (Enemy), gen (int), at (world px, the landing
## point, following the target), land (game time), dmg, radius, splash, flare,
## evolved (bool), second (bool)}.
var stars: Array[Dictionary] = []
## Crashes still drawn: {at, r, t (game time), evolved}. Visual only.
var shown: Array[Dictionary] = []
## Seconds until the next cast.
var _cd: float = 0.0
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; moves and crashes the falling stars.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := shown.size() - 1
	while i >= 0:
		if now - float(shown[i]["t"]) > FallFromGraceData.CRASH_SHOW:
			shown.remove_at(i)
		i -= 1
	i = stars.size() - 1
	while i >= 0:
		var s := stars[i]
		var t: Enemy = s["target"]
		if t != null and t.active and t.generation == int(s["gen"]):
			s["at"] = t.position  # The star follows its target down.
		if now >= float(s["land"]):
			stars.remove_at(i)
			_crash(s)
		i -= 1
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var busy := not stars.is_empty() or not shown.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: a star on each of the `stars` strongest foes (and, with Second
## Fall, one more on the next-strongest). False when no foe is in range.
func _cast(stats: Dictionary) -> bool:
	if stars.size() >= FallFromGraceData.MAX_STARS:
		return false
	var n := int(stats.get("stars", 1))
	var second := game.character.innate_value(FallFromGraceData.SECOND_KEY)  # Second Fall (0 for every other character).
	var picks := _strongest(game.player.position, n + (1 if second > 0.0 else 0))
	if picks.is_empty():
		return false
	var evolved := stats.has("flare")
	for k in picks.size():
		var is_second := k >= n
		var e: Enemy = picks[k]
		var dmg := float(stats["damage"]) * (second if is_second else 1.0)
		stars.append({"target": e, "gen": e.generation, "at": e.position, "land": game.elapsed + float(stats["fall_time"]),
			"dmg": dmg, "radius": float(stats["radius"]), "splash": float(stats["splash"]),
			"flare": float(stats.get("flare", 0.0)), "evolved": evolved, "second": is_second,
			"proud": float(stats.get(FallFromGraceData.PROUD_KEY, 0.0))})
		game.stat_add("grace_stars", 1.0)
		if is_second:
			game.stat_add("grace_second_stars", 1.0)
	game.stat_add("grace_casts", 1.0)
	Sfx.play("lance_cast", game.player.position, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## The `n` open foes with the most HP left within AIM_RANGE of `p`, strongest first.
func _strongest(p: Vector2, n: int) -> Array:
	var reach := FallFromGraceData.AIM_RANGE
	game.enemy_grid.query(p, reach, _tmp)
	var out: Array = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or out.has(e) or p.distance_to(e.position) > reach:
				continue
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		out.append(best)
	return out


## A star crashes: its target (if still standing on the mark) takes the full
## blow, every other foe in the crash the splash; Lightbringer's flare ring.
func _crash(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	var r := float(s["radius"])
	var dmg := float(s["dmg"])
	var evolved := bool(s["evolved"])
	var src := FallFromGraceData.EVOLVED_SOURCE if evolved else FallFromGraceData.SOURCE
	var t: Enemy = s["target"]
	var struck: Enemy = null  # The target, still standing on the mark.
	if t != null and t.active and t.generation == int(s["gen"]) and t.position.distance_to(at) <= r + t.radius:
		struck = t
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	var reach := r * (FallFromGraceData.FLARE_RADIUS_MULT if evolved else 1.0)
	game.enemy_grid.query(at, reach + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	var flared := 0
	if struck != null:
		var proud := float(s["proud"]) if (struck.is_elite or struck.is_boss or struck.is_miniboss) else 0.0  # Pride (0 when not owned).
		if proud > 0.0:
			game.stat_add("grace_proud_hits", 1.0)
		game.combat.damage_enemy(struck, dmg * (1.0 + proud), src)
		n += 1
	for e: Enemy in hits:
		if not e.active or e == struck:
			continue
		var dd := e.position.distance_to(at)
		if dd <= r + e.radius:
			game.combat.damage_enemy(e, dmg * float(s["splash"]), src)
			n += 1
		elif evolved and dd <= reach + e.radius:
			game.combat.damage_enemy(e, dmg * float(s["flare"]), FallFromGraceData.FLARE_SOURCE)
			flared += 1
	game.stat_add("grace_crashes", 1.0)
	game.stat_add("grace_hits", float(n))
	if evolved:
		game.stat_add("grace_flares", float(flared))
		game.effects.ring(at, reach, Palette.GOLD, 0.35)
	game.effects.impact(at, r, Palette.GOLD)
	Sfx.play("corpse_burst", at, 0.8)  # A startup-bank sound.
	shown.append({"at": at, "r": r, "t": game.elapsed, "evolved": evolved})


## Autotest counters (the Fall from Grace line of PandemoniumReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d stars=%d crashes=%d hits=%d proud=%d second=%d flares=%d" % [int(st.get("grace_casts", 0.0)), int(st.get("grace_stars", 0.0)),
		int(st.get("grace_crashes", 0.0)), int(st.get("grace_hits", 0.0)), int(st.get("grace_proud_hits", 0.0)),
		int(st.get("grace_second_stars", 0.0)), int(st.get("grace_flares", 0.0))]


## The falling stars (a gold-white disc with a violet trail, the landing mark
## on the ground) and the crashes' light. Textures only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var disc := SpriteBank.disc()
	var now := game.elapsed
	for s in stars:
		var at: Vector2 = s["at"]
		var fall := maxf(0.01, float(s["land"]) - now)  # s left.
		var k := clampf(1.0 - fall / 0.6, 0.0, 1.0)  # 0 high up -> 1 landing.
		var r := float(s["radius"])
		draw_texture_rect(disc, Rect2(at - Vector2(r, r * 0.5), Vector2(r * 2.0, r)), false, Color(Palette.GOLD, 0.10 + 0.2 * k))  # The mark.
		var p := at + FallFromGraceData.FALL_FROM * (1.0 - k)  # The star in the sky.
		for j in 4:
			var q := p - FallFromGraceData.FALL_FROM.normalized() * float(j + 1) * 9.0  # The trail behind it.
			var w := 7.0 - float(j) * 1.4
			draw_texture_rect(disc, Rect2(q - Vector2(w, w), Vector2(w, w) * 2.0), false, Color(Palette.VIOLET, 0.5 - 0.1 * float(j)))
		var sz := 9.0 if bool(s["evolved"]) else 7.0
		draw_texture_rect(disc, Rect2(p - Vector2(sz, sz), Vector2(sz, sz) * 2.0), false, Color(Palette.GOLD, 0.9))
		draw_texture_rect(disc, Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(1.0, 0.98, 0.85, 1.0))
	for c in shown:
		var fade := clampf(1.0 - (now - float(c["t"])) / FallFromGraceData.CRASH_SHOW, 0.0, 1.0)
		var r := float(c["r"]) * (1.2 if bool(c["evolved"]) else 1.0)
		draw_texture_rect(disc, Rect2(Vector2(c["at"]) - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.GOLD, 0.35 * fade))
