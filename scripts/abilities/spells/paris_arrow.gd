## ParisArrow — the Paris's Arrow spell (AbilityData "paris_arrow"; Act IV, the
## Shores of Ilion; owner-approved Act IV proposal "Rewards": "a spectral arrow
## that always strikes its target from behind (full damage through phalanx
## fronts)"). Unlocked by slaying Achilles (UnlockData), then offered on every
## stage; driven by NecroSpellBook's one dispatch (ACT4_IDS) with its EFFECTIVE
## stats (AbilityManager.spell_stats(): Soul Conduit, Abyssal Focus...).
##   * Every `cooldown` s (start to start; AbilityData.SPELL_RETRY while no foe
##     is in range) it looses `arrows` violet ghost arrows at the strongest
##     foes within `range` px of the necromancer (most max HP first, each arrow
##     its own target while there are enough; structures last).
##   * Each arrow flies `flight` s on a curve that swings past its target
##     (ParisArrowData.SWING) and comes back at it from BEHIND: it strikes with
##     the origin ParisArrowData.BEHIND px behind the target's facing
##     (PantheonRules.facing_of(), any enemy) as a shot, through
##     CombatResolver.damage_enemy(), so a locked shield front, a Legionary's
##     testudo and Achilles' front never cut it, it breaks the wall it hits and
##     Mortal Heel (its paired passive) raises it. A target that dies before the
##     arrow arrives lets the arrow fade.
##   * The Doomed Prophetess's innate (CharacterData "arrow_elite_bonus"): her
##     arrows deal that much more to elites, minibosses and bosses.
## Evolved into Arrow of Fate (EvolutionData "arrow_of_fate", detected by the
## "fate_jumps" key): more arrows, and an arrow that kills its target flies on
## from the body to the strongest foe within `fate_range` px it has not struck
## yet, up to `fate_jumps` times, each time from behind.
## Drawn as violet ghost arrows with a short trail and a bone head.
## Deterministic: no RNG (targets by max HP, then distance, then spawn order).
## Stats: paris_volleys, paris_arrows, paris_hits, paris_kills, paris_faded,
## fate_jumps, prophetess_bonus_dmg.
class_name ParisArrow
extends NecroSpell

## One ghost arrow in flight (pooled through `_pool`).
class Arrow:
	extends RefCounted
	## Its target.
	var target: Enemy = null
	## Generation of `target` when it was aimed (stale / death guard).
	var gen: int = 0
	## Where this leg of its flight began (world px).
	var from: Vector2 = Vector2.ZERO
	## Seconds flown on this leg.
	var t: float = 0.0
	## Seconds this leg takes.
	var flight: float = 0.5
	## Damage of its strike (effective, before the innate).
	var damage: float = 0.0
	## Damage source tag ("paris_arrow" or "arrow_of_fate").
	var source: String = ""
	## Fated jumps still allowed after a kill (Arrow of Fate).
	var jumps_left: int = 0
	## Px from a body to the next fated target.
	var fate_range: float = 0.0
	## Side of the swing (+1 / -1).
	var side: float = 1.0
	## Foes this arrow already struck (a fated arrow never strikes one twice).
	var struck: Array[Enemy] = []
	## Its current position (world px; drawing).
	var pos: Vector2 = Vector2.ZERO
	## Its last positions (world px; the trail, newest last).
	var trail: PackedVector2Array = PackedVector2Array()

## Seconds until the next volley may be loosed.
var _timer: float = ParisArrowData.FIRST_VOLLEY
## Arrows in flight.
var _arrows: Array[Arrow] = []
## Idle Arrow records ready for reuse.
var _pool: Array[Arrow] = []
## Volleys loosed so far (alternates the swing side; no RNG).
var _volleys: int = 0
## Own query buffer of the target search.
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Looses volleys on cooldown and flies the arrows.
func step(delta: float, stats: Dictionary) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _loose(stats) else AbilityData.SPELL_RETRY
	var i := 0  # Index into _arrows (swap-remove).
	while i < _arrows.size():
		var a := _arrows[i]
		if _fly(a, delta):
			i += 1
		else:
			_arrows[i] = _arrows[_arrows.size() - 1]
			_arrows.pop_back()
			a.target = null
			a.struck.clear()
			_pool.append(a)
	var busy := not _arrows.is_empty()  # Something to draw.
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Looses one volley at the strongest foes in range. Returns false when no foe
## is in range (the spell then waits).
func _loose(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var none: Array[Enemy] = []  # Nothing skipped.
	var targets := _strongest(p, float(stats["range"]), int(stats["arrows"]), none)
	if targets.is_empty():
		return false
	var fate := stats.has("fate_jumps")  # Arrow of Fate.
	var n := int(stats["arrows"])  # Arrows this volley.
	_volleys += 1
	for k in n:
		if _arrows.size() >= ParisArrowData.MAX_ARROWS:
			break
		var a := _take()
		a.target = targets[k % targets.size()]
		a.gen = a.target.generation
		a.from = p
		a.pos = p
		a.t = 0.0
		a.flight = float(stats["flight"])
		a.damage = float(stats["damage"])
		a.source = "arrow_of_fate" if fate else "paris_arrow"
		a.jumps_left = int(stats.get("fate_jumps", 0))
		a.fate_range = float(stats.get("fate_range", 0.0))
		a.side = 1.0 if (k + _volleys) % 2 == 0 else -1.0
		a.trail.clear()
		_arrows.append(a)
	game.stat_add("paris_volleys", 1.0)
	game.stat_add("paris_arrows", float(n))
	Sfx.play("bolt_cast", p, ParisArrowData.LOOSE_PITCH)
	return true


## A pooled (or new) Arrow record.
func _take() -> Arrow:
	if _pool.is_empty():
		return Arrow.new()
	return _pool.pop_back()


## Up to `n` of the strongest live foes within `reach` px of `at` (most max HP
## first, then nearest), skipping `skip`; structures only when nothing else.
func _strongest(at: Vector2, reach: float, n: int, skip: Array[Enemy]) -> Array[Enemy]:
	game.enemy_grid.query(at, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var picks: Array[Enemy] = []
	var scores: PackedFloat32Array = PackedFloat32Array()
	for e: Enemy in _cand:
		if not is_open_target(e) or skip.has(e):
			continue
		var d := at.distance_to(e.position)
		if d > reach + e.radius:
			continue
		var score := e.max_hp - d * 0.01 - (100000.0 if e.is_structure else 0.0)  # Strongest first, structures last.
		var idx := picks.size()  # Insertion point (descending).
		while idx > 0 and scores[idx - 1] < score:
			idx -= 1
		if idx >= n:
			continue
		picks.insert(idx, e)
		scores.insert(idx, score)
		if picks.size() > n:
			picks.resize(n)
			scores.resize(n)
	return picks


## The point `BEHIND` px behind enemy `e`'s facing (world px): every arrow's
## last stretch comes from here.
static func behind_point(e: Enemy) -> Vector2:
	return e.position - PantheonRules.facing_of(e) * (e.radius + ParisArrowData.BEHIND)


## Flies arrow `a` one tick; strikes at the end of its leg. Returns false when
## the arrow is spent.
func _fly(a: Arrow, delta: float) -> bool:
	var e := a.target
	if e == null or not e.active or e.generation != a.gen:
		game.stat_add("paris_faded", 1.0)
		return false
	a.t += delta
	var k := clampf(a.t / maxf(0.01, a.flight), 0.0, 1.0)  # 0 -> 1 along this leg.
	var end := behind_point(e)  # Where it strikes from.
	var across := (e.position - a.from)  # From the launch toward the target.
	var fwd := across.normalized() if across.length() > 1.0 else Vector2.RIGHT
	var ctrl := e.position + fwd * ParisArrowData.SWING + fwd.orthogonal() * a.side * ParisArrowData.SWING  # The swing past the target.
	var u := 1.0 - k
	a.pos = a.from * (u * u) + ctrl * (2.0 * u * k) + end * (k * k)  # Quadratic curve: around the target to its back.
	a.trail.append(a.pos)
	if a.trail.size() > ParisArrowData.TRAIL:
		a.trail.remove_at(0)
	if k < 1.0:
		return true
	return _strike(a)


## The arrow strikes its target from behind; a fated arrow that kills flies on.
## Returns false when the arrow is spent.
func _strike(a: Arrow) -> bool:
	var e := a.target
	var dmg := a.damage
	var bonus := game.character.innate_value("arrow_elite_bonus")  # The Doomed Prophetess (0 for everyone else).
	if bonus > 0.0 and (e.is_elite or e.is_miniboss or e.is_boss):
		game.stat_add("prophetess_bonus_dmg", dmg * bonus)
		dmg *= 1.0 + bonus
	var at := e.position  # Where it struck (the body may be pooled by the hit).
	a.struck.append(e)
	game.combat.damage_enemy(e, dmg, a.source, -1, behind_point(e), true)
	game.stat_add("paris_hits", 1.0)
	game.effects.pop(at, ParisArrowData.GLOW, 10.0)
	Sfx.play("bolt_hit", at, ParisArrowData.HIT_PITCH)
	if e.active:
		return false
	game.stat_add("paris_kills", 1.0)
	if a.jumps_left <= 0:
		return false
	var next := _strongest(at, a.fate_range, 1, a.struck)  # The next fated foe.
	if next.is_empty():
		return false
	a.jumps_left -= 1
	a.target = next[0]
	a.gen = a.target.generation
	a.from = at
	a.t = 0.0
	a.flight *= ParisArrowData.JUMP_FLIGHT
	a.side = -a.side
	game.stat_add("fate_jumps", 1.0)
	return true


## Spell-specific counters for the autotest summary.
func summary_extra() -> String:
	var st := game.stats
	return "volleys=%d arrows=%d hits=%d kills=%d faded=%d fate_jumps=%d" % [int(st.get("paris_volleys", 0.0)), int(st.get("paris_arrows", 0.0)),
		int(st.get("paris_hits", 0.0)), int(st.get("paris_kills", 0.0)), int(st.get("paris_faded", 0.0)), int(st.get("fate_jumps", 0.0))]


## The ghost arrows: a fading violet trail, a bright shaft and a bone head
## pointing along their flight. Visual only.
func _draw() -> void:
	for a in _arrows:
		var n := a.trail.size()
		for i in range(1, n):
			var w := float(i) / float(maxi(1, n - 1))  # 0 (oldest) -> 1.
			draw_line(a.trail[i - 1], a.trail[i], Color(ParisArrowData.GLOW, 0.15 + 0.45 * w), 1.0 + 2.0 * w)
		if n < 2:
			continue
		var dir := (a.trail[n - 1] - a.trail[n - 2])
		dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
		var tip := a.pos + dir * 5.0
		draw_line(a.pos - dir * 7.0, tip, ParisArrowData.CORE, 2.0)
		draw_colored_polygon(PackedVector2Array([tip + dir * 4.0, tip + dir.orthogonal() * 2.5, tip - dir.orthogonal() * 2.5]), ParisArrowData.HEAD)
		draw_circle(a.pos, 3.0, Color(ParisArrowData.GLOW, 0.35))
