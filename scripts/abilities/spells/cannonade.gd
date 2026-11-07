## Cannonade — the Cannonade spell (AbilityData "cannonade"; Act X, the
## Treasure Galleon; GDD §15.0 "Cannonade, Dead Men's Broadside, Black Powder
## and the Corsair Queen (Act X)"; owner-approved proposal: "spectral
## cannonballs arc down on three marked groups"; unlocked by slaying Admiral
## Marrec, then offered on every stage at the later-item card weight). Every
## `cooldown` s it MARKS up to `marks` groups of foes within `range` px of the
## necromancer (plus the Corsair Queen's Queen's Ransom, innate value
## cannonade_extra_marks): each the open foe with the most others within
## `radius` px, CannonadeData.GROUP_APART px from the marks already chosen; a
## soul-lit circle shows on each for CannonadeData.FALL_TIME s while a
## spectral ball arcs down, then it LANDS: `damage` to every foe within
## `radius` px (CombatResolver.damage_enemy(), a spell source). BLACK POWDER
## (the paired passive): every blast is powder_blast_radius wider and knocks
## the foes it hits powder_knock px outward (their knockback: on a deck, a
## blast at the rail tips them overboard; DeckBounds does the rest). Evolved
## into DEAD MEN'S BROADSIDE (EvolutionData "dead_mens_broadside", detected by
## the "salvo" key): more marks, wider blasts, and every mark takes a second
## ball `salvo` s later dealing `salvo_share` of the damage (a double broadside). Works the same on every stage
## (no act rule).
## Determinism: no RNG; groups by count, ties by distance in the spatial
## hash's order. Stats: cannonade_volleys, cannonade_balls, cannonade_hits,
## cannonade_knocks, cannonade_extra_marks; damage as dmg_cannonade /
## dmg_dead_mens_broadside.
class_name Cannonade
extends NecroSpell

## Balls in the air: {from (world px), at (world px), t (game s it lands), r,
## dmg, src, span (s of its arc)}.
var falling: Array[Dictionary] = []
## Seconds until the next volley.
var _cd: float = 0.0
## Second scratch query buffer (the group counts).
var _tmp2: Array = []
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Volleys on its cooldown; lands the balls.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := 0
	while i < falling.size():
		if now >= float(falling[i]["t"]):
			_land(falling[i])
			falling.remove_at(i)
			continue
		i += 1
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _volley(stats) else CannonadeData.WAIT_RETRY
	var busy := not falling.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One volley: the marks and their balls (false when no foe is in range).
func _volley(stats: Dictionary) -> bool:
	var extra := roundi(game.character.innate_value(CannonadeData.EXTRA_MARKS_KEY))
	var n := int(stats["marks"]) + extra
	var r := float(stats["radius"]) * (1.0 + game.abilities.passive_value(CannonadeData.BLACK_POWDER, CannonadeData.BLAST_KEY))
	var marks := _groups(game.player.position, float(stats["range"]), r, n)
	if marks.is_empty():
		return false
	var evolved := stats.has("salvo")
	var src := CannonadeData.EVOLVED_SOURCE if evolved else CannonadeData.SOURCE
	var now := game.elapsed
	var from := game.player.position + Vector2(0.0, -24.0)
	for k in marks.size():
		var span := CannonadeData.FALL_TIME + 0.06 * float(k)
		falling.append({"from": from, "at": marks[k], "t": now + span, "r": r, "dmg": float(stats["damage"]), "src": src, "span": span})
		if evolved:
			falling.append({"from": from, "at": marks[k], "t": now + span + float(stats["salvo"]), "r": r, "dmg": float(stats["damage"]) * float(stats.get("salvo_share", 1.0)), "src": src, "span": span + float(stats["salvo"])})
	game.stat_add("cannonade_volleys", 1.0)
	game.stat_add("cannonade_balls", float(marks.size() * (2 if evolved else 1)))
	if extra > 0:
		game.stat_add("cannonade_extra_marks", float(extra))
	Sfx.play("lance_cast", game.player.position, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## Up to `n` group centres within `reach` px of `from` (see the header).
func _groups(from: Vector2, reach: float, r: float, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var samples: Array[Enemy] = []
	game.enemy_grid.query(from, reach, _tmp)
	for e: Enemy in _tmp:
		if is_open_target(e) and not e.untargetable and from.distance_to(e.position) <= reach:
			samples.append(e)
			if samples.size() >= CannonadeData.GROUP_SAMPLES:
				break
	if samples.is_empty():
		return out
	var counts: Array[int] = []
	for e in samples:
		game.enemy_grid.query(e.position, r + ProjectileManager.MAX_BODY_RADIUS, _tmp2)
		var c := 0
		for o: Enemy in _tmp2:
			if is_open_target(o) and o.position.distance_to(e.position) <= r + o.radius:
				c += 1
		counts.append(c)
	for _k in n:
		var best := -1
		for j in samples.size():
			var free := true
			for q in out:
				free = free and q.distance_to(samples[j].position) >= CannonadeData.GROUP_APART
			if not free:
				continue
			if best < 0 or counts[j] > counts[best] or (counts[j] == counts[best] and from.distance_squared_to(samples[j].position) < from.distance_squared_to(samples[best].position)):
				best = j
		if best < 0:
			break
		out.append(samples[best].position)
	return out


## A ball lands: its blast (and Black Powder's knock).
func _land(b: Dictionary) -> void:
	var at: Vector2 = b["at"]
	var r := float(b["r"])
	var knock := game.abilities.passive_value(CannonadeData.BLACK_POWDER, CannonadeData.KNOCK_KEY)
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.position.distance_to(at) > r + e.radius:
			continue
		if knock > 0.0 and not (e.is_boss or e.is_miniboss or e.is_structure):
			var off := e.position - at
			e.knockback += (off.normalized() if off.length() > 0.5 else Vector2.UP) * sqrt(2.0 * EnemyData.KNOCKBACK_DECAY * knock) / maxf(e.mass, 0.1)
			game.stat_add("cannonade_knocks", 1.0)
		game.combat.damage_enemy(e, float(b["dmg"]), String(b["src"]))
		n += 1
	game.stat_add("cannonade_hits", float(n))
	game.effects.impact(at, r, CannonadeData.SOUL_COLOR)


## Autotest counters (GalleonReport's Cannonade line).
func summary_extra() -> String:
	var st := game.stats
	return "volleys=%d balls=%d hits=%d knocks=%d extra_marks=%d" % [int(st.get("cannonade_volleys", 0.0)),
		int(st.get("cannonade_balls", 0.0)), int(st.get("cannonade_hits", 0.0)), int(st.get("cannonade_knocks", 0.0)),
		int(st.get("cannonade_extra_marks", 0.0))]


## Each mark's circle (a ring texture filling as the ball nears) and the ball
## on its arc. Textures only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var ring := CityGlyphs.ring_texture()
	for b in falling:
		var span := maxf(0.01, float(b["span"]))
		var k := clampf(1.0 - (float(b["t"]) - now) / span, 0.0, 1.0)  # 0 -> 1 as it lands.
		var at: Vector2 = b["at"]
		var r := float(b["r"])
		draw_texture_rect(ring, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(CannonadeData.SOUL_COLOR, 0.3 + 0.5 * k))
		var from: Vector2 = b["from"]
		var p := from.lerp(at, k) + Vector2(0.0, -CannonadeData.ARC_HEIGHT * 4.0 * k * (1.0 - k))
		SpriteBank.draw_disc(self, p, 5.0, Color(0.05, 0.07, 0.08, 0.9))
		SpriteBank.draw_disc(self, p, 3.5, Color(CannonadeData.SOUL_COLOR, 0.8))
