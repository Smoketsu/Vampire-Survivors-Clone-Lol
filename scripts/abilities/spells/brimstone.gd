## Brimstone — the Brimstone spell (AbilityData "brimstone"; Act VI, the
## Burning Gate; GDD §15.0 "Brimstone, Rain of Fire, Furnace Heart and the
## Furnace Priest (Act VI)"; owner-approved proposal: "burning stones fall on
## the densest group and leave a short pit"; unlocked by slaying Moloch, then
## offered on every stage at the later-item card weight). Every `cooldown` s,
## `stones` burning stones (plus the Furnace Priest's Stoker, innate value
## brimstone_extra_stones) fall on the DENSEST GROUPS of foes within `range` px
## of the necromancer: each stone's shadow grows for BrimstoneData.FALL_TIME s,
## then it lands, dealing `damage` to every foe within `radius` px, and leaves a
## burning pit of `pit_radius` px for `pit_life` s that burns `pit_share` x the
## damage per s (so Soul Conduit and the other spell-damage modifiers reach it).
## THE SPELL'S PITS ARE ITS OWN: they burn ENEMIES ONLY (source brimstone_pit,
## through CombatResolver.damage_enemy()), never a summon or the necromancer,
## and they are not Hell Pits (the Bone Ring does not flow around them), so the
## spell works the same on every stage. Evolved into RAIN OF FIRE (EvolutionData
## "rain_of_fire", detected by the "rain_gap" key): more, harder stones that
## fall one after another `rain_gap` s apart over the groups (extra stones
## scatter `rain_spread` px around the densest), wider, longer pits. FURNACE
## HEART (the paired passive) is read by CombatResolver.damage_enemy() through
## in_fire() below. A foe in two pits burns once a tick.
## Determinism: no RNG; groups by count, ties by distance in the spatial hash's
## order; the scatter on a fixed golden angle. Stats: brimstone_volleys,
## brimstone_stones, brimstone_hits, brimstone_pits, brimstone_pit_burns,
## brimstone_extra_stones; damage as dmg_brimstone / dmg_rain_of_fire /
## dmg_brimstone_pit.
class_name Brimstone
extends NecroSpell

## Golden angle (rad): the scatter of extra stones around a group.
const GOLDEN: float = 2.39996

## Stones in the air: {at (world px), t (game s it lands), r, dmg, pit_r,
## pit_life, pit_dps, evolved (bool)}.
var falling: Array[Dictionary] = []
## Centre (world px) of each burning pit.
var _pit_pos: PackedVector2Array = PackedVector2Array()
## Radius (px) of each pit.
var _pit_rad: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each pit stops burning.
var _pit_until: PackedFloat32Array = PackedFloat32Array()
## Damage per second of each pit.
var _pit_dps: PackedFloat32Array = PackedFloat32Array()
## Seconds until the next volley.
var _cd: float = 0.0
## Seconds toward the next pit burn.
var _tick_acc: float = 0.0
## Foes already burned this tick (scratch: a foe in two pits burns once).
var _burned: Dictionary = {}
## Second query buffer (the group search nests two queries).
var _tmp2: Array = []
## True once Rain of Fire (drawing).
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Fires on its cooldown; lands the falling stones; burns and ages the pits.
func step(delta: float, stats: Dictionary) -> void:
	_evolved = stats.has("rain_gap")
	var now := game.elapsed
	var i := 0
	while i < falling.size():
		if now >= float(falling[i]["t"]):
			_land(falling[i])
			falling.remove_at(i)
			continue
		i += 1
	i = 0
	while i < _pit_pos.size():
		if now >= _pit_until[i] + BrimstoneData.COOL_TIME:
			_remove_pit(i)
			continue
		i += 1
	_tick_acc += delta
	if _tick_acc >= BrimstoneData.PIT_TICK:
		_tick_acc -= BrimstoneData.PIT_TICK
		_burn(BrimstoneData.PIT_TICK)
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _volley(stats) else AbilityData.SPELL_RETRY
	var busy := not falling.is_empty() or not _pit_pos.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One volley: the stones pick their groups and start to fall. False when no
## foe is in range.
func _volley(stats: Dictionary) -> bool:
	var n := int(stats["stones"]) + roundi(game.character.innate_value(BrimstoneData.EXTRA_STONES_KEY))
	var r := float(stats["radius"])
	var targets := _groups(game.player.position, float(stats["range"]), r, n)
	if targets.is_empty():
		return false
	var spread := float(stats.get("rain_spread", r * 0.5))
	var gap := float(stats.get("rain_gap", 0.0))
	var evolved := stats.has("rain_gap")
	var now := game.elapsed
	for k in n:
		var at: Vector2 = targets[k] if k < targets.size() else targets[0] + Vector2.from_angle(GOLDEN * float(k)) * spread * (0.5 + 0.5 * float(k % 3) / 2.0)
		falling.append({"at": at, "t": now + BrimstoneData.FALL_TIME + gap * float(k), "r": r, "dmg": float(stats["damage"]),
			"pit_r": float(stats["pit_radius"]), "pit_life": float(stats["pit_life"]), "pit_dps": float(stats["damage"]) * float(stats["pit_share"]), "evolved": evolved})
	game.stat_add("brimstone_volleys", 1.0)
	game.stat_add("brimstone_stones", float(n))
	if n > int(stats["stones"]):
		game.stat_add("brimstone_extra_stones", float(n - int(stats["stones"])))
	Sfx.play("lance_cast", game.player.position, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## Up to `n` group centres within `reach` px of `from`: each the open foe with
## the most others within `r` px (ties: nearer), each GROUP_APART px from the
## centres already chosen. Empty when no foe is in reach.
func _groups(from: Vector2, reach: float, r: float, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var samples: Array[Enemy] = []
	game.enemy_grid.query(from, reach, _tmp)
	for e: Enemy in _tmp:
		if is_open_target(e) and not e.untargetable and from.distance_to(e.position) <= reach:
			samples.append(e)
			if samples.size() >= BrimstoneData.GROUP_SAMPLES:
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
				free = free and q.distance_to(samples[j].position) >= BrimstoneData.GROUP_APART
			if not free:
				continue
			if best < 0 or counts[j] > counts[best] or (counts[j] == counts[best] and from.distance_squared_to(samples[j].position) < from.distance_squared_to(samples[best].position)):
				best = j
		if best < 0:
			break
		out.append(samples[best].position)
	return out


## A stone lands: its blast, then its pit.
func _land(s: Dictionary) -> void:
	var at: Vector2 = s["at"]
	var src := BrimstoneData.EVOLVED_SOURCE if bool(s["evolved"]) else BrimstoneData.SOURCE
	game.stat_add("brimstone_hits", float(damage_area(at, float(s["r"]), float(s["dmg"]), src)))
	if _pit_pos.size() >= BrimstoneData.MAX_PITS:
		_remove_pit(0)  # The oldest goes out first.
	_pit_pos.append(at)
	_pit_rad.append(float(s["pit_r"]))
	_pit_until.append(game.elapsed + float(s["pit_life"]))
	_pit_dps.append(float(s["pit_dps"]))
	game.stat_add("brimstone_pits", 1.0)
	game.effects.impact(at, float(s["r"]), Palette.INFERNO_LAVA)


## Removes pit `i` (keeps the order: the oldest first).
func _remove_pit(i: int) -> void:
	_pit_pos.remove_at(i)
	_pit_rad.remove_at(i)
	_pit_until.remove_at(i)
	_pit_dps.remove_at(i)


## The spell's pits burn every foe in them (enemies only), each foe once.
func _burn(tick: float) -> void:
	if _pit_pos.is_empty():
		return
	_burned.clear()
	var now := game.elapsed
	var src := BrimstoneData.PIT_SOURCE
	for i in _pit_pos.size():
		if now >= _pit_until[i]:
			continue
		var hits: Array = []  # Own buffer: kill hooks may query the grid again.
		game.enemy_grid.query(_pit_pos[i], _pit_rad[i] + ProjectileManager.MAX_BODY_RADIUS, hits)
		for e: Enemy in hits:
			if not e.active or _burned.has(e) or e.position.distance_to(_pit_pos[i]) > _pit_rad[i] + e.radius * 0.5:
				continue
			_burned[e] = true
			game.combat.damage_enemy(e, _pit_dps[i] * tick, src)
			game.stat_add("brimstone_pit_burns", 1.0)


## True when world point `p` (a body of radius `r`) stands in one of the
## spell's burning pits.
func burning_at(p: Vector2, r: float) -> bool:
	var now := game.elapsed
	for i in _pit_pos.size():
		if now < _pit_until[i] and p.distance_to(_pit_pos[i]) < _pit_rad[i] + r * 0.5:
			return true
	return false


## FURNACE HEART's fire test (CombatResolver.damage_enemy(), the one read):
## true when foe `e` stands in a burning Brimstone pit of the bound
## necromancer's spell, or in a burning Hell Pit (an Act VI stage).
static func in_fire(g: Game, e: Enemy) -> bool:
	var node: NecroSpell = g.abilities.spells.nodes.get(BrimstoneData.ID)  # The spell's node, if it ever stepped.
	if node is Brimstone and (node as Brimstone).burning_at(e.position, e.radius):
		return true
	return g.inferno != null and g.inferno.enabled and g.inferno.pits.burning_at(e.position, e.radius * 0.5)


## Autotest counters (BurningGateReport's Brimstone line).
func summary_extra() -> String:
	var st := game.stats
	return "volleys=%d stones=%d (extra %d) hits=%d pits=%d pit_burns=%d" % [int(st.get("brimstone_volleys", 0.0)), int(st.get("brimstone_stones", 0.0)),
		int(st.get("brimstone_extra_stones", 0.0)), int(st.get("brimstone_hits", 0.0)), int(st.get("brimstone_pits", 0.0)), int(st.get("brimstone_pit_burns", 0.0))]


## The falling stones (a growing shadow, a burning stone dropping onto it) and
## the pits (the Hell Pits' lava texture, gold-rimmed once evolved). Textures
## only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for i in _pit_pos.size():
		var a := 1.0
		if now >= _pit_until[i]:
			a = clampf(1.0 - (now - _pit_until[i]) / BrimstoneData.COOL_TIME, 0.0, 1.0)
		InfernoGlyphs.draw_pit(self, _pit_pos[i], _pit_rad[i], a, now + float(i) * 0.7)
		if _evolved:
			SpriteBank.draw_disc(self, _pit_pos[i], _pit_rad[i] * 1.1, Color(Palette.GOLD, 0.12 * a))
	for s in falling:
		var at: Vector2 = s["at"]
		var k := clampf(1.0 - (float(s["t"]) - now) / BrimstoneData.FALL_TIME, 0.0, 1.0)  # 0 high .. 1 landing.
		if k <= 0.0:
			continue
		SpriteBank.draw_disc(self, at, float(s["r"]) * (0.3 + 0.7 * k), Color(0.0, 0.0, 0.0, 0.25 + 0.2 * k))
		var drop := at - Vector2(0.0, 120.0 * (1.0 - k))
		SpriteBank.draw_disc(self, drop, 7.0, Color(Palette.INFERNO_LAVA, 0.5))
		SpriteBank.draw_disc(self, drop, 4.5, Palette.INFERNO_OBSIDIAN_DARK)
		SpriteBank.draw_disc(self, drop + Vector2(-1.5, -1.5), 2.0, Palette.INFERNO_LAVA_LIGHT)
