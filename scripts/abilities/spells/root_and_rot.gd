## RootAndRot — the ROOT AND ROT spell (AbilityData "root_and_rot"; temporary Act
## XV, the World-Tree; GDD §15.0 "Root and Rot, Return to Earth, Compost Heart and
## the Gravegardener"; owner-approved proposal: "a ring of roots grows at the
## strongest enemy and rots everything inside"). Unlocked by slaying the Green
## Mother (UnlockData), then offered on every stage; driven by NecroSpellBook's
## one dispatch (WORLD_TREE_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): its "radius" widens with every spell-area
## modifier).
##   * Every `cooldown` s, once a foe stands within `range` px, a ring of roots
##     of `radius` px grows at the STRONGEST foe in reach (the most HP now, of
##     the first AIM_SAMPLES): every foe inside takes `damage` once as it grows,
##     then every TICK s while it stands (`duration` s) every foe inside is
##     ROTTED (CombatResolver.rot_enemy(), the one Rot path: `rot` more damage
##     taken) and held by the roots (CombatResolver.slow_enemy(): `slow`). It
##     never hurts the necromancer's own. Rot burns the Wild's thickets back
##     (rot_enemy()'s own hook).
##   * Compost Heart (its paired passive, PassiveData "compost_heart", read only
##     here): + compost_rot on the rot, + compost_time s on every ring.
##   * The Gravegardener's Green Thumb (CharacterData
##     "root_and_rot_radius_bonus"): x 1 + bonus on the radius (0 for every
##     other character).
## Evolved into RETURN TO EARTH (EvolutionData "return_to_earth", detected by
## the "rings" key): `rings` rings a cast, each at a distinct strong foe
## (SPACING px apart), and every tick the roots bite every foe inside for
## `bite` (the earth takes them back).
## Deterministic: no RNG; the foes in the spatial hash's order. Stats:
## root_and_rot_casts, root_and_rot_rings, root_and_rot_hits,
## root_and_rot_rots, root_and_rot_innate_px; damage as dmg_root_and_rot /
## dmg_return_to_earth.
class_name RootAndRot
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Rings standing: [centre (Vector2), game s it ends, radius (px), game s of its next tick] each.
var _rings: Array = []
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = -1  # The roots grow on the ground, under the bodies.


## Casts on the cooldown; the rings tick on their clocks.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := _rings.size() - 1
	while i >= 0:
		var r: Array = _rings[i]
		if game.elapsed >= float(r[1]):
			_rings.remove_at(i)
		elif game.elapsed >= float(r[3]):
			r[3] = float(r[3]) + RootAndRotData.TICK
			_tick(stats, r[0], float(r[2]), false)
		i -= 1
	var busy := not _rings.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: a ring (or Return to Earth's several) at the strongest foes in
## reach. Returns false when no foe is near (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var picks: Array = []  # [hp, position] of the aim candidates.
	var seen := 0
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian or p.distance_to(e.position) - e.radius > reach:
			continue
		picks.append([e.hp, e.position])
		seen += 1
		if seen >= RootAndRotData.AIM_SAMPLES:
			break
	if picks.is_empty():
		return false
	var bonus := game.character.innate_value(RootAndRotData.INNATE_KEY)
	var r := float(stats["radius"]) * (1.0 + bonus)
	var life := float(stats["duration"]) + game.abilities.passive_value(RootAndRotData.COMPOST_HEART, RootAndRotData.TIME_KEY)
	var want := int(stats.get("rings", 1))
	var chosen: Array[Vector2] = []
	while chosen.size() < want:
		var best_i := -1
		for k in picks.size():
			var at: Vector2 = picks[k][1]
			var free := true
			for c in chosen:
				if c.distance_to(at) < RootAndRotData.SPACING:
					free = false
					break
			if free and (best_i < 0 or float(picks[k][0]) > float(picks[best_i][0])):
				best_i = k
		if best_i < 0:
			break
		chosen.append(picks[best_i][1])
	for at in chosen:
		if _rings.size() >= RootAndRotData.MAX_RINGS:
			break
		_rings.append([at, game.elapsed + life, r, game.elapsed + RootAndRotData.TICK])
		_tick(stats, at, r, true)
		game.stat_add("root_and_rot_rings", 1.0)
	game.stat_add("root_and_rot_casts", 1.0)
	if bonus > 0.0:
		game.stat_add("root_and_rot_innate_px", float(stats["radius"]) * bonus)
	game.player.cast_motion(chosen[0])  # Engine motion: toward the ring (visual only).
	Sfx.play("lance_cast", p, RootAndRotData.CAST_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## A ring's tick at `at` (`r` px): every foe inside is rotted and held; as it
## grows (`grow`) each takes the damage, and Return to Earth bites each tick.
func _tick(stats: Dictionary, at: Vector2, r: float, grow: bool) -> void:
	var evolved := stats.has("rings")
	var src := RootAndRotData.EVOLVED_SOURCE if evolved else RootAndRotData.SOURCE
	var rot := float(stats["rot"]) + game.abilities.passive_value(RootAndRotData.COMPOST_HEART, RootAndRotData.ROT_KEY)
	var hold := RootAndRotData.TICK + 0.15  # s: to the next tick and a little more.
	var near: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, near)
	for o: Enemy in near:
		if not o.active or o.untargetable or o.civilian or o.position.distance_to(at) > r + o.radius:
			continue
		game.combat.rot_enemy(o, rot, game.elapsed + hold)
		game.stat_add("root_and_rot_rots", 1.0)
		if o.active:
			game.combat.slow_enemy(o, float(stats["slow"]), hold)
		if grow:
			game.combat.damage_enemy(o, float(stats["damage"]), src)
			game.stat_add("root_and_rot_hits", 1.0)
		elif evolved and o.active:
			game.combat.damage_enemy(o, float(stats["bite"]), src)
	if grow:
		game.effects.ring(at, r, RootAndRotData.ROT, 0.35)


## Autotest counters (WorldTreeReport's Root and Rot line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d rings=%d hits=%d rots=%d innate_px=%d" % [int(st.get("root_and_rot_casts", 0.0)), int(st.get("root_and_rot_rings", 0.0)),
		int(st.get("root_and_rot_hits", 0.0)), int(st.get("root_and_rot_rots", 0.0)), int(st.get("root_and_rot_innate_px", 0.0))]


## The rings: a faint soul-teal disc and its roots round the rim. Visual only:
## disc textures and rects in world axes (the spell node sits at the origin).
func _draw() -> void:
	for ring: Array in _rings:
		var at: Vector2 = ring[0]
		var r := float(ring[2])
		SpriteBank.draw_disc(self, at, r, Color(RootAndRotData.ROT, 0.10))
		for k in RootAndRotData.ROOTS_DRAWN:
			var a := TAU * float(k) / float(RootAndRotData.ROOTS_DRAWN)
			draw_rect(Rect2(at + Vector2(cos(a), sin(a)) * r * 0.85 - Vector2(1.5, 4.0), Vector2(3.0, 8.0)), RootAndRotData.ROOT)  # A root shoot.
