## PackLeap — the PACK LEAP spell (AbilityData "pack_leap"; temporary Act XIV,
## the Fern Basin; GDD §15.0 "Pack Leap, Apex Pack, Pack Instinct and the Fern
## Huntress"; owner-approved proposal: "three spectral raptors leap at marked
## enemies"). Unlocked by slaying Scarmaw (UnlockData), then offered on every
## stage; driven by NecroSpellBook's one dispatch (FERN_BASIN_IDS, stepped only)
## with its EFFECTIVE stats (AbilityManager.spell_stats(): its pounce is the
## row's "radius", so every spell-area modifier widens it).
##   * Every `cooldown` s, once a foe stands within `range` px, it MARKS the
##     `raptors` strongest foes in reach (the most HP first; distinct while
##     there are enough, then the strongest again). MARK_TIME s later a
##     spectral raptor lands on each mark still alive: `damage` to it and
##     pounce_share of it to every other foe within `radius` px, through
##     CombatResolver.damage_enemy().
##   * Pack Instinct (its paired passive, PassiveData "pack_instinct", read
##     only here): x 1 + instinct_bonus on the damage, + pounce_bonus px.
##   * The Fern Huntress's Hunter's Mark (CharacterData "pack_leap_raptors"):
##     + raptors (0 for every other character).
## Evolved into APEX PACK (EvolutionData "apex_pack", detected by the
## "chain_share" key): each raptor that lands leaps on, CHAIN_DELAY s later, to
## the nearest unmarked foe within chain_reach px for chain_share of the damage.
## Deterministic: no RNG; the foes in the spatial hash's order, marks
## generation-checked. Stats: pack_leap_casts, pack_leap_hits,
## pack_leap_pounce_hits, pack_leap_chains, pack_leap_innate_raptors; damage as
## dmg_pack_leap / dmg_apex_pack.
class_name PackLeap
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Raptors in flight: {e (Enemy), gen (int), from (Vector2), t0 (game s),
## land (game s), share (float), chain (bool: a second leap)}.
var _leaps: Array[Dictionary] = []
## Effective stats of the last step.
var _stats: Dictionary = {}
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the raptors land on their clocks.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < _leaps.size():
		var l := _leaps[i]
		if game.elapsed >= float(l["land"]):
			_leaps.remove_at(i)
			_land(stats, l)
		else:
			i += 1
	var busy := not _leaps.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: marks the strongest foes in reach. Returns false when none is
## near (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var foes: Array[Enemy] = []
	for e: Enemy in _cand:
		if e.active and not e.untargetable and not e.civilian and p.distance_to(e.position) - e.radius <= reach:
			foes.append(e)
	if foes.is_empty():
		return false
	foes.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.hp > b.hp)
	var bonus := int(game.character.innate_value(PackLeapData.INNATE_KEY))
	var n := int(stats["raptors"]) + bonus
	for k in n:
		if _leaps.size() >= PackLeapData.MAX_LEAPS:
			break
		var e := foes[k % foes.size()]
		_leaps.append({"e": e, "gen": e.generation, "from": p, "t0": game.elapsed, "land": game.elapsed + PackLeapData.MARK_TIME,
				"share": 1.0, "chain": false})
	game.stat_add("pack_leap_casts", 1.0)
	if bonus > 0:
		game.stat_add("pack_leap_innate_raptors", float(bonus))
	game.player.cast_motion(foes[0].position)  # Engine motion: toward the strongest (visual only).
	Sfx.play("bolt_cast", p, PackLeapData.LEAP_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## Raptor `l` lands: its mark (if alive) takes the damage, the foes round it
## the pounce; an evolved first leap leaps on.
func _land(stats: Dictionary, l: Dictionary) -> void:
	var e: Enemy = l["e"]
	if not e.active or e.generation != int(l["gen"]) or e.untargetable:
		return
	var src := PackLeapData.EVOLVED_SOURCE if stats.has("chain_share") else PackLeapData.SOURCE
	var dmg := float(stats["damage"]) * (1.0 + game.abilities.passive_value(PackLeapData.PACK_INSTINCT, PackLeapData.DAMAGE_KEY)) * float(l["share"])
	var at := e.position
	game.combat.damage_enemy(e, dmg, src)
	game.stat_add("pack_leap_hits", 1.0)
	var pounce := float(stats["radius"]) + game.abilities.passive_value(PackLeapData.PACK_INSTINCT, PackLeapData.POUNCE_KEY)
	var near: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, pounce + ProjectileManager.MAX_BODY_RADIUS, near)
	for o: Enemy in near:
		if o == e or not o.active or o.untargetable or o.civilian or o.position.distance_to(at) > pounce + o.radius:
			continue
		game.combat.damage_enemy(o, dmg * float(stats["pounce_share"]), src)
		game.stat_add("pack_leap_pounce_hits", 1.0)
	if stats.has("chain_share") and not bool(l["chain"]) and _leaps.size() < PackLeapData.MAX_LEAPS:
		var next := _nearest_unmarked(at, float(stats.get("chain_reach", 160.0)), e)
		if next != null:
			_leaps.append({"e": next, "gen": next.generation, "from": at, "t0": game.elapsed, "land": game.elapsed + PackLeapData.CHAIN_DELAY,
					"share": float(stats["chain_share"]), "chain": true})
			game.stat_add("pack_leap_chains", 1.0)


## The nearest live foe within `reach` px of `at` that no raptor is after and
## is not `skip` (null when none).
func _nearest_unmarked(at: Vector2, reach: float, skip: Enemy) -> Enemy:
	var near: Array = []
	game.enemy_grid.query(at, reach + ProjectileManager.MAX_BODY_RADIUS, near)
	var best: Enemy = null
	var best_d := reach
	for o: Enemy in near:
		if o == skip or not o.active or o.untargetable or o.civilian:
			continue
		var dd := o.position.distance_to(at) - o.radius
		if dd >= best_d:
			continue
		var marked := false
		for l in _leaps:
			if l["e"] == o:
				marked = true
				break
		if not marked:
			best_d = dd
			best = o
	return best


## Autotest counters (FernBasinReport's Pack Leap line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d hits=%d pounce=%d chains=%d innate_raptors=%d" % [int(st.get("pack_leap_casts", 0.0)), int(st.get("pack_leap_hits", 0.0)),
		int(st.get("pack_leap_pounce_hits", 0.0)), int(st.get("pack_leap_chains", 0.0)), int(st.get("pack_leap_innate_raptors", 0.0))]


## The marks and the leaping raptors (soul-teal spirits on an arc, a
## bone-white core). Visual only: rects and disc textures.
func _draw() -> void:
	for l: Dictionary in _leaps:
		var e: Enemy = l["e"]
		if not e.active or e.generation != int(l["gen"]):
			continue
		var to := e.position  # World axes: the spell node sits at the origin.
		var from: Vector2 = l["from"]
		var k := clampf((game.elapsed - float(l["t0"])) / maxf(0.01, float(l["land"]) - float(l["t0"])), 0.0, 1.0)
		_draw_mark(to, k)
		var at := from.lerp(to, k) + Vector2(0.0, -sin(k * PI) * 28.0)  # The leap's arc.
		SpriteBank.draw_disc(self, at, 5.0, Color(PackLeapData.SPIRIT, 0.7))
		SpriteBank.draw_disc(self, at + Vector2(3.0, -2.0), 2.5, PackLeapData.CORE)
		draw_rect(Rect2(at + Vector2(-8.0, -1.0), Vector2(5.0, 2.0)), Color(PackLeapData.SPIRIT, 0.5))  # Its tail.


## The mark over a foe at `p`: a teal claw-mark that closes as the raptor comes.
func _draw_mark(p: Vector2, k: float) -> void:
	var r := 9.0 - 4.0 * k
	for s: float in [-1.0, 0.0, 1.0]:
		draw_rect(Rect2(p + Vector2(s * 3.0 - 1.0, -r), Vector2(2.0, r * 2.0)), Color(PackLeapData.SPIRIT, 0.55 + 0.35 * k))
