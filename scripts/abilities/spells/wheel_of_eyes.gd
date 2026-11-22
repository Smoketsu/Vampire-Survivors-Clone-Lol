## WheelOfEyes — the WHEEL OF EYES spell (AbilityData "wheel_of_eyes"; temporary
## Act XIII, the Wheel of Thrones; GDD §15.0 "Wheel of Eyes, Ophanim, All-Seeing
## and the Blind Saint"; owner-approved proposal: "a burning wheel rolls out in
## a line and rebounds off walls"). Unlocked by slaying the Throne (UnlockData),
## then offered on every stage; driven by NecroSpellBook's one dispatch
## (WHEEL_OF_THRONES_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): the wheel's size is the row's "radius", so
## every spell-area modifier widens it).
##   * Every `cooldown` s, a foe within WheelOfEyesData.AIM_RANGE, `count`
##     burning wheels roll out from the necromancer toward the nearest foe
##     (fanned FAN_DEG apart), `speed` px/s for `life` s, `radius` px wide.
##     Every foe under a wheel takes `damage` (CombatResolver.damage_enemy();
##     the spell is its own Grace kind), at most once each HIT_GAP s per wheel.
##   * THE REBOUND ("rebounds off walls"): a wheel that meets an obstacle (the
##     solid world, Arena) or the edge of the sight round the necromancer
##     (Game.view_size(), EDGE_PAD) bounces off it, mirrored about the wall's
##     normal.
##   * All-Seeing (its paired passive, PassiveData "all_seeing", read only
##     here): x 1 + wheel_damage on every strike, x 1 + wheel_life on the life.
##   * The Blind Saint's Inner Sight (CharacterData "wheel_radius_bonus"): + px
##     on every wheel's radius (0 for every other character).
## Evolved into OPHANIM (EvolutionData "ophanim", detected by the "flare_share"
## key): more and larger wheels, and every rebound FLARES: every foe within
## flare_radius px of the wall takes flare_share of the damage.
## Deterministic: no RNG; the nearest foe in the spatial hash's order. Stats:
## wheel_casts, wheel_hits, wheel_rebounds, wheel_flares, wheel_radius_bonus_px;
## damage as dmg_wheel_of_eyes / dmg_ophanim.
class_name WheelOfEyes
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Rolling wheels: {p (Vector2), v (Vector2, px/s), left (s), r (px), hit
## (Array of [Enemy, generation, game time of its last strike]), spin (rad)}.
var _wheels: Array[Dictionary] = []
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the wheels roll, strike and rebound.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := _wheels.size() - 1
	while i >= 0:
		var w: Dictionary = _wheels[i]
		w["left"] = float(w["left"]) - delta
		if float(w["left"]) <= 0.0:
			_wheels.remove_at(i)
		else:
			_roll(w, stats, delta)
		i -= 1
	var busy := not _wheels.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Damage of one strike now: the row's damage x All-Seeing.
func _damage(stats: Dictionary) -> float:
	return float(stats["damage"]) * (1.0 + game.abilities.passive_value(WheelOfEyesData.ALL_SEEING, WheelOfEyesData.DAMAGE_KEY))


## The damage tag now (the evolution has its own).
func _source(stats: Dictionary) -> String:
	return WheelOfEyesData.EVOLVED_SOURCE if stats.has("flare_share") else WheelOfEyesData.SOURCE


## One cast at the nearest foe in range. Returns false when none is near (the
## spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	game.enemy_grid.query(p, WheelOfEyesData.AIM_RANGE, _cand)
	var best: Enemy = null  # The nearest open foe.
	var best_d := INF
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian:
			continue
		var d := p.distance_to(e.position)
		if d <= WheelOfEyesData.AIM_RANGE and d < best_d:
			best_d = d
			best = e
	if best == null:
		return false
	var aim := (best.position - p).angle()
	var n := maxi(1, int(stats["count"]))
	var bonus := game.character.innate_value(WheelOfEyesData.INNATE_KEY)  # The Blind Saint's Inner Sight.
	var life := float(stats["life"]) * (1.0 + game.abilities.passive_value(WheelOfEyesData.ALL_SEEING, WheelOfEyesData.LIFE_KEY))
	for k in n:
		while _wheels.size() >= WheelOfEyesData.MAX_WHEELS:
			_wheels.pop_front()  # The oldest wheel ends first.
		var a := aim + deg_to_rad(WheelOfEyesData.FAN_DEG) * (float(k) - float(n - 1) * 0.5)
		_wheels.append({"p": p, "v": Vector2.from_angle(a) * float(stats["speed"]), "left": life,
			"r": float(stats["radius"]) + bonus, "hit": [], "spin": 0.0})
	game.stat_add("wheel_casts", 1.0)
	if bonus > 0.0:
		game.stat_add("wheel_radius_bonus_px", bonus)
	game.player.cast_motion(best.position)  # Engine motion: toward the foe (visual only).
	Sfx.play("bolt_cast", p, 0.7)  # A startup-bank sound: the spell plays on every stage.
	return true


## One wheel's tick: it rolls, rebounds off a wall, strikes the foes under it.
func _roll(w: Dictionary, stats: Dictionary, delta: float) -> void:
	var r := float(w["r"])
	var v: Vector2 = w["v"]
	var p: Vector2 = w["p"]
	var nxt := p + v * delta
	var wall := Vector2.ZERO  # The normal of the wall it meets (zero = none).
	var o := game.arena.obstacle_at(nxt)
	if o != null:
		var push := Arena.separation(o, nxt, r * WheelOfEyesData.OBSTACLE_PAD)
		if push != Vector2.ZERO:
			wall = push.normalized()
	var half := game.view_size() * 0.5 + Vector2.ONE * WheelOfEyesData.EDGE_PAD  # The sight round the necromancer.
	var rel := nxt - game.player.position
	if absf(rel.x) > half.x and rel.x * v.x > 0.0:
		wall += Vector2(-signf(rel.x), 0.0)
	if absf(rel.y) > half.y and rel.y * v.y > 0.0:
		wall += Vector2(0.0, -signf(rel.y))
	if wall != Vector2.ZERO and v.dot(wall) < 0.0:
		var n := wall.normalized()
		v = v - 2.0 * v.dot(n) * n  # REBOUND: mirrored about the wall.
		w["v"] = v
		nxt = p + v * delta
		game.stat_add("wheel_rebounds", 1.0)
		if stats.has("flare_share"):
			game.stat_add("wheel_flares", 1.0)
			damage_area(p, float(stats["flare_radius"]), _damage(stats) * float(stats["flare_share"]), _source(stats))
			game.effects.ring(p, float(stats["flare_radius"]), WheelOfEyesData.FIRE, 0.25)
	w["p"] = nxt
	w["spin"] = wrapf(float(w["spin"]) + v.length() * delta / maxf(1.0, r), 0.0, TAU)
	var now := game.elapsed
	var hit: Array = w["hit"]
	var j := hit.size() - 1
	while j >= 0:
		if now - float(hit[j][2]) >= WheelOfEyesData.HIT_GAP:
			hit.remove_at(j)
		j -= 1
	var found: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(nxt, r + ProjectileManager.MAX_BODY_RADIUS, found)
	var dmg := _damage(stats)
	var src := _source(stats)
	for e: Enemy in found:
		if not e.active or e.untargetable or e.civilian or nxt.distance_to(e.position) > r + e.radius:
			continue
		var seen := false
		for h: Array in hit:
			if h[0] == e and int(h[1]) == e.generation:
				seen = true
				break
		if seen:
			continue
		hit.append([e, e.generation, now])
		game.combat.damage_enemy(e, dmg, src)
		game.stat_add("wheel_hits", 1.0)


## Autotest counters (WheelOfThronesReport's Wheel of Eyes line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d hits=%d rebounds=%d flares=%d radius_bonus_px=%d" % [int(st.get("wheel_casts", 0.0)), int(st.get("wheel_hits", 0.0)),
		int(st.get("wheel_rebounds", 0.0)), int(st.get("wheel_flares", 0.0)), int(st.get("wheel_radius_bonus_px", 0.0))]


## Every wheel: a ring of soul-teal fire round a bone rim of closed eyes,
## turning as it rolls. Visual only: disc textures.
func _draw() -> void:
	for w: Dictionary in _wheels:
		var p: Vector2 = w["p"]
		var r := float(w["r"])
		SpriteBank.draw_disc(self, p, r, Color(WheelOfEyesData.FIRE, 0.28))
		SpriteBank.draw_disc(self, p, r * 0.45, Color(WheelOfEyesData.RIM, 0.5))
		for k in WheelOfEyesData.EYES:
			var a := float(w["spin"]) + TAU * float(k) / float(WheelOfEyesData.EYES)
			SpriteBank.draw_disc(self, p + Vector2.from_angle(a) * r * 0.78, 2.2, WheelOfEyesData.RIM)  # A closed eye on the rim.
