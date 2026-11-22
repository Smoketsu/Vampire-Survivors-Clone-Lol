## Stampede — the STAMPEDE spell (AbilityData "stampede"; temporary Act XIV, the
## Great Plain; GDD §15.0 "Stampede, Herd of Ages, Calcified Hide and the
## Herd-Warden"; owner-approved proposal: "a spectral horned charger tramples a
## line"). Unlocked by slaying Old Ironbrow (UnlockData), then offered on every
## stage; driven by NecroSpellBook's one dispatch (GREAT_PLAIN_IDS, stepped
## only) with its EFFECTIVE stats (AbilityManager.spell_stats(): its path's half
## width is the row's "radius", so every spell-area modifier widens it).
##   * Every `cooldown` s, once a foe stands within `range` px, a spectral
##     horned CHARGER starts BACK px behind the necromancer and runs at `speed`
##     px/s for `length` px toward the thickest foes in reach (of the first
##     AIM_SAMPLES foes, the one with the most foes within AIM_RADIUS px).
##     Every foe within `radius` px of the charger is TRAMPLED once a run:
##     `damage` through CombatResolver.damage_enemy() and a knockback along
##     the run.
##   * Calcified Hide (its paired passive, PassiveData "calcified_hide", read
##     only here): x 1 + hide_bonus on the damage, + width_bonus px.
##   * The Herd-Warden's Lead Bull (CharacterData "stampede_length_bonus"):
##     x 1 + bonus on the run length (0 for every other character).
## Evolved into HERD OF AGES (EvolutionData "herd_of_ages", detected by the
## "herd" key): `herd` chargers run abreast, HERD_SPACING px apart, and every
## foe they trample is stunned `stun` s (CombatResolver.stun_enemy()).
## Deterministic: no RNG; the foes in the spatial hash's order, each run's
## hits generation-checked. Stats: stampede_casts, stampede_hits,
## stampede_stuns, stampede_innate_px; damage as dmg_stampede /
## dmg_herd_of_ages.
class_name Stampede
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Chargers running: {from (Vector2), dir (Vector2), t0 (game s), len (px),
## hit (Dictionary: Enemy -> its generation when trampled)}.
var _runs: Array[Dictionary] = []
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## px/s the chargers run (the last step's effective "speed"; for drawing).
var _speed: float = 520.0


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the chargers run on their clocks.
func step(delta: float, stats: Dictionary) -> void:
	_speed = float(stats["speed"])
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < _runs.size():
		if _advance(stats, _runs[i]):
			i += 1
		else:
			_runs.remove_at(i)
	var busy := not _runs.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: the charger(s) toward the thickest foes in reach. Returns false
## when none is near (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null
	var best_n := -1
	var seen := 0
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian or p.distance_to(e.position) - e.radius > reach:
			continue
		var n := count_enemies(e.position, StampedeData.AIM_RADIUS)
		if n > best_n:
			best_n = n
			best = e
		seen += 1
		if seen >= StampedeData.AIM_SAMPLES:
			break
	if best == null:
		return false
	var to := best.position - p
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var bonus := game.character.innate_value(StampedeData.INNATE_KEY)
	var len := float(stats["length"]) * (1.0 + bonus)
	var n_runs := int(stats.get("herd", 1))
	for k in n_runs:
		if _runs.size() >= StampedeData.MAX_RUNS:
			break
		var side := dir.orthogonal() * StampedeData.HERD_SPACING * (float(k) - float(n_runs - 1) * 0.5)
		_runs.append({"from": p - dir * StampedeData.BACK + side, "dir": dir, "t0": game.elapsed, "len": len, "hit": {}})
	game.stat_add("stampede_casts", 1.0)
	if bonus > 0.0:
		game.stat_add("stampede_innate_px", float(stats["length"]) * bonus)
	game.player.cast_motion(best.position)  # Engine motion: toward the charge (visual only).
	Sfx.play("lance_cast", p, StampedeData.CAST_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## The charger `r` runs on: every foe it reaches is trampled once. Returns
## false when its run is over.
func _advance(stats: Dictionary, r: Dictionary) -> bool:
	var run := float(stats["speed"]) * (game.elapsed - float(r["t0"]))
	var done := run >= float(r["len"])
	var at := _pos(r, minf(run, float(r["len"])))
	var src := StampedeData.EVOLVED_SOURCE if stats.has("herd") else StampedeData.SOURCE
	var dmg := float(stats["damage"]) * (1.0 + game.abilities.passive_value(StampedeData.CALCIFIED_HIDE, StampedeData.DAMAGE_KEY))
	var w := float(stats["radius"]) + game.abilities.passive_value(StampedeData.CALCIFIED_HIDE, StampedeData.WIDTH_KEY)
	var hit: Dictionary = r["hit"]
	var dir: Vector2 = r["dir"]
	var near: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, w + ProjectileManager.MAX_BODY_RADIUS, near)
	for o: Enemy in near:
		if not o.active or o.untargetable or o.civilian or int(hit.get(o, -1)) == o.generation or o.position.distance_to(at) > w + o.radius:
			continue
		hit[o] = o.generation
		game.combat.damage_enemy(o, dmg, src)
		game.stat_add("stampede_hits", 1.0)
		if not o.active:
			continue
		o.knockback += dir * StampedeData.KNOCK / maxf(o.mass, 0.1)
		if stats.has("stun") and game.combat.stun_enemy(o, float(stats["stun"]), StampedeData.STUN_BOSS_MULT, StampedeData.STUN_ELITE_MULT) > 0.0:
			game.stat_add("stampede_stuns", 1.0)
	return not done


## Charger `r`'s position after `run` px.
func _pos(r: Dictionary, run: float) -> Vector2:
	return (r["from"] as Vector2) + (r["dir"] as Vector2) * run


## Autotest counters (GreatPlainReport's Stampede line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d hits=%d stuns=%d innate_px=%d" % [int(st.get("stampede_casts", 0.0)), int(st.get("stampede_hits", 0.0)),
		int(st.get("stampede_stuns", 0.0)), int(st.get("stampede_innate_px", 0.0))]


## The running chargers (a soul-teal spirit body, bone-white horns, a dust
## trail). Visual only: rects and disc textures, in world axes (the spell node
## sits at the origin).
func _draw() -> void:
	for r: Dictionary in _runs:
		var dir: Vector2 = r["dir"]
		var run := minf(_speed * (game.elapsed - float(r["t0"])), float(r["len"]))
		var at := _pos(r, run)
		for j in 3:
			SpriteBank.draw_disc(self, at - dir * (10.0 + 9.0 * float(j)), 6.0 - 1.5 * float(j), Color(StampedeData.SPIRIT, 0.25 - 0.06 * float(j)))  # The dust trail.
		SpriteBank.draw_disc(self, at, 9.0, Color(StampedeData.SPIRIT, 0.75))  # The body.
		SpriteBank.draw_disc(self, at + dir * 7.0, 5.0, Color(StampedeData.SPIRIT, 0.9))  # The head.
		var side := dir.orthogonal()
		for s: float in [-1.0, 1.0]:
			var tip := at + dir * 15.0 + side * s * 4.0
			draw_rect(Rect2(tip - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), StampedeData.CORE)  # A horn.

