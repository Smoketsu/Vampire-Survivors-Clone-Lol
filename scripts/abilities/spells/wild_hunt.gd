## WildHunt — the WILD HUNT spell (AbilityData "wild_hunt"; temporary Act XV, the
## Greenwood; GDD §15.0 "Wild Hunt, The Endless Hunt, Horn of the Hunt and the
## Horned Herald"; owner-approved proposal: "spectral riders sweep across the
## screen in a line"). Unlocked by slaying the Stag King (UnlockData), then
## offered on every stage; driven by NecroSpellBook's one dispatch
## (GREENWOOD_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): a rider's reach is the row's "radius", so every
## spell-area modifier widens it).
##   * Every `cooldown` s, once a foe stands within `range` px, a LINE of
##     `riders` spectral riders abreast (WildHuntData.RIDER_SPACING px apart)
##     rides in from BACK px behind the necromancer and sweeps `length` px at
##     `speed` px/s toward the thickest foes in reach (of the first AIM_SAMPLES
##     foes, the one with the most foes within AIM_RADIUS px). Every foe within
##     `radius` px of a rider is struck ONCE a sweep: `damage` through
##     CombatResolver.damage_enemy() and a knockback along the ride.
##   * Horn of the Hunt (its paired passive, PassiveData "horn_of_the_hunt",
##     read only here): x 1 + horn_bonus on the damage, + width_bonus px reach.
##   * The Horned Herald's Call of the Horn (CharacterData "wild_hunt_riders"):
##     riders more in every line (0 for every other character).
## Evolved into THE ENDLESS HUNT (EvolutionData "the_endless_hunt", detected by
## the "returns" key): at the end of its sweep the line turns and rides back
## `returns` more times, striking every foe again.
## Deterministic: no RNG; the foes in the spatial hash's order, each sweep's hits
## generation-checked. Stats: wild_hunt_casts, wild_hunt_hits,
## wild_hunt_returns, wild_hunt_innate_riders; damage as dmg_wild_hunt /
## dmg_the_endless_hunt.
class_name WildHunt
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Lines riding: {from (Vector2), dir (Vector2), t0 (game s), len (px), n
## (riders), back (sweeps left to ride back), hit (Dictionary: Enemy -> its
## generation when struck this sweep)}.
var _lines: Array[Dictionary] = []
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## px/s the riders ride (the last step's effective "speed"; for drawing).
var _speed: float = 600.0


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the lines ride on their clocks.
func step(delta: float, stats: Dictionary) -> void:
	_speed = float(stats["speed"])
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < _lines.size():
		if _advance(stats, _lines[i]):
			i += 1
		else:
			_lines.remove_at(i)
	var busy := not _lines.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: a line toward the thickest foes in reach. Returns false when none
## is near (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	if _lines.size() >= WildHuntData.MAX_LINES:
		return false
	var p := game.player.position  # The necromancer.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null
	var best_n := -1
	var seen := 0
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian or p.distance_to(e.position) - e.radius > reach:
			continue
		var n := count_enemies(e.position, WildHuntData.AIM_RADIUS)
		if n > best_n:
			best_n = n
			best = e
		seen += 1
		if seen >= WildHuntData.AIM_SAMPLES:
			break
	if best == null:
		return false
	var to := best.position - p
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var extra := int(game.character.innate_value(WildHuntData.INNATE_KEY))
	var n_riders := mini(int(stats["riders"]) + extra, WildHuntData.MAX_RIDERS)
	_lines.append({"from": p - dir * WildHuntData.BACK, "dir": dir, "t0": game.elapsed, "len": float(stats["length"]),
		"n": n_riders, "back": int(stats.get("returns", 0)), "hit": {}})
	game.stat_add("wild_hunt_casts", 1.0)
	if extra > 0:
		game.stat_add("wild_hunt_innate_riders", float(extra))
	game.player.cast_motion(best.position)  # Engine motion: toward the sweep (visual only).
	Sfx.play("lance_cast", p, WildHuntData.CAST_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## Line `ln` rides on: every foe a rider reaches is struck once a sweep.
## Returns false when its last sweep is over.
func _advance(stats: Dictionary, ln: Dictionary) -> bool:
	var run := float(stats["speed"]) * (game.elapsed - float(ln["t0"]))
	var len := float(ln["len"])
	if run >= len:
		if int(ln["back"]) <= 0:
			return false
		ln["back"] = int(ln["back"]) - 1
		ln["from"] = (ln["from"] as Vector2) + (ln["dir"] as Vector2) * len
		ln["dir"] = -(ln["dir"] as Vector2)
		ln["t0"] = game.elapsed
		ln["hit"] = {}
		game.stat_add("wild_hunt_returns", 1.0)
		run = 0.0
	var src := WildHuntData.EVOLVED_SOURCE if stats.has("returns") else WildHuntData.SOURCE
	var dmg := float(stats["damage"]) * (1.0 + game.abilities.passive_value(WildHuntData.HORN, WildHuntData.DAMAGE_KEY))
	var w := float(stats["radius"]) + game.abilities.passive_value(WildHuntData.HORN, WildHuntData.WIDTH_KEY)
	var hit: Dictionary = ln["hit"]
	var dir: Vector2 = ln["dir"]
	var n := int(ln["n"])
	var mid := (ln["from"] as Vector2) + dir * run
	var half := WildHuntData.RIDER_SPACING * float(n - 1) * 0.5 + w
	var near: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(mid, half + ProjectileManager.MAX_BODY_RADIUS, near)
	for o: Enemy in near:
		if not o.active or o.untargetable or o.civilian or int(hit.get(o, -1)) == o.generation:
			continue
		var rel := o.position - mid
		if absf(rel.dot(dir)) > w + o.radius or absf(rel.dot(dir.orthogonal())) > half + o.radius:
			continue
		hit[o] = o.generation
		game.combat.damage_enemy(o, dmg, src)
		game.stat_add("wild_hunt_hits", 1.0)
		if o.active:
			o.knockback += dir * WildHuntData.KNOCK / maxf(o.mass, 0.1)
	return true


## Autotest counters (GreenwoodReport's Wild Hunt line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d hits=%d returns=%d innate_riders=%d" % [int(st.get("wild_hunt_casts", 0.0)), int(st.get("wild_hunt_hits", 0.0)),
		int(st.get("wild_hunt_returns", 0.0)), int(st.get("wild_hunt_innate_riders", 0.0))]


## The riding lines (soul-teal spectral riders, bone-white helms and spears, a
## mist trail). Visual only: rects and disc textures, in world axes (the spell
## node sits at the origin).
func _draw() -> void:
	for ln: Dictionary in _lines:
		var dir: Vector2 = ln["dir"]
		var run := minf(_speed * (game.elapsed - float(ln["t0"])), float(ln["len"]))
		var n := int(ln["n"])
		var side := dir.orthogonal()
		for k in n:
			var at := (ln["from"] as Vector2) + dir * run + side * WildHuntData.RIDER_SPACING * (float(k) - float(n - 1) * 0.5)
			for j in 3:
				SpriteBank.draw_disc(self, at - dir * (10.0 + 9.0 * float(j)), 6.0 - 1.5 * float(j), Color(WildHuntData.SPIRIT, 0.25 - 0.06 * float(j)))  # The mist trail.
			SpriteBank.draw_disc(self, at, 8.0, Color(WildHuntData.SPIRIT, 0.7))  # The steed.
			SpriteBank.draw_disc(self, at + dir * 2.0 - side * 3.0, 4.0, Color(WildHuntData.SPIRIT, 0.9))  # The rider.
			draw_rect(Rect2(at + dir * 8.0 - Vector2(1.0, 1.0), Vector2(2.0, 2.0)) , WildHuntData.CORE)  # The spear's point.
