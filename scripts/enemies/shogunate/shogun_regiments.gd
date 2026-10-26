## ShogunRegiments — Shogun Kurogane's army, which IS his health bar (Act V,
## Castle Kurogane; GDD §15.0 "Shogun Kurogane: his army is his health bar";
## owner-approved proposal docs/act5/PROPOSAL.md "Stage 14"), owned and stepped
## by BossShogun while he stands on his command platform. Numbers in ShogunData
## (REGIMENTS and the march constants). The ONE count of "soldiers he has
## left" (left()):
##   left = the sum over the regiments still in the fight of (reserve not yet
##   sent + its soldiers on the field), where the field count is:
##     * the members it spawned itself (tracked with their generations: one
##       that is no longer active and was not taken off by us was KILLED), and
##     * for an "ambush" regiment sent through ShadowAmbush (its ninja appear
##       out of the shadows later, untracked), an estimate: the squads sent
##       minus the ninja killed since (the kill_ninja stat).
##   Every OTHER Shogunate kill (the timeline's trickle and waves: "every
##   Shogunate kill takes a point off it") takes a point off the reserve of the
##   first regiment that still has one (a marching one first, else the next to
##   march). The kills are read from the run's kill_<kind> stats over every
##   Shogunate kind (no hook in the kill path).
## The march: regiment i marches FIRST_MARCH + i x MARCH_EVERY s after his
## arrival, or as soon as no regiment is on the field, at most MAX_ACTIVE at
## once, each from its own side (MARCH_TURN apart); its Hatamoto comes with its
## first batch (HatamotoKit.set_regiment(): his banner in the regiment's colour),
## then a batch of `batch` soldiers every `every` s in a line on the spawn ring
## while fewer than `field` of them are out and its reserve lasts (never past
## the hard cap). Its order is its kinds (ShogunData.REGIMENTS "order").
## BREAK: when its Hatamoto falls, the regiment breaks: every soldier of it
## still on the field flees (taken off the field, EnemyDirector.despawn(), a
## puff where each stood) and its reserve is lost; the banner counts as broken
## (Regiments Broken). A regiment whose soldiers all fell but whose Hatamoto
## still stands keeps its last point until he falls.
## stop() (the Shogun comes down to duel) ends the march: no more batches, no
## more regiments; the soldiers on the field fight on.
## Determinism: the seeded gameplay RNG only (a soldier's kind by weight).
## Stats: shogun_regiments_marched, shogun_soldiers_sent, shogun_member_kills,
## shogun_ambush_kills, shogun_trickle_points, shogun_fled, shogun_reserve_lost,
## shogun_banners_broken, shogun_regiment_<i>_broken_at, shogun_regiment_<i>_order.
class_name ShogunRegiments
extends RefCounted

## A regiment that has not marched yet.
const WAITING: int = 0
## A regiment on the field.
const MARCHING: int = 1
## A regiment whose Hatamoto fell (its banner is broken).
const BROKEN: int = 2

## One regiment of the Shogun's army.
class Regiment:
	extends RefCounted
	## Index in ShogunData.REGIMENTS.
	var index: int = 0
	## Its ShogunData.REGIMENTS row.
	var def: Dictionary = {}
	## WAITING, MARCHING or BROKEN.
	var state: int = 0
	## Soldiers not yet sent (points of the bar).
	var reserve: int = 0
	## Soldiers it spawned that are on the field.
	var members: Array[Enemy] = []
	## Generation of each member when it spawned.
	var gens: PackedInt32Array = PackedInt32Array()
	## Its Hatamoto (null before he marches).
	var hatamoto: Enemy = null
	## Generation of the Hatamoto when he spawned.
	var hat_gen: int = 0
	## Estimated ninja of it on the field, sent through ShadowAmbush.
	var ambush_out: int = 0
	## Seconds until its next batch.
	var batch_cd: float = 0.0
	## Unit direction from the necromancer it marches in from.
	var dir: Vector2 = Vector2.RIGHT
	## Game time (s) it marched (-1 = not yet).
	var marched_at: float = -1.0

	## Its soldiers on the field (tracked + the ambush estimate).
	func out() -> int:
		return members.size() + ambush_out

## The Shogun.
var boss: Enemy
## Owning run.
var game: Game
## The six regiments, in marching order.
var regiments: Array[Regiment] = []
## True once the Shogun came down (no more marching).
var stopped: bool = false
## Game time (s) he arrived (the march clock).
var start: float = 0.0
## Every Shogunate kind id (the kill stats summed each tick).
var _kinds: PackedStringArray = PackedStringArray()
## Sum of the Shogunate kill stats at the last step.
var _last_kills: float = 0.0
## kill_ninja stat at the last step (the ambush regiment's estimate).
var _last_ninja: float = 0.0
## Index of the next regiment to march.
var _next: int = 0
## Angle (rad) the first regiment marches in from (then MARCH_TURN on).
var _base_angle: float = 0.0
## Banners broken (Hatamoto killed) so far.
var banners_broken: int = 0


## Builds the army of `p_boss` (call once, at his arrival).
func _init(p_boss: Enemy) -> void:
	boss = p_boss
	game = p_boss.game
	start = game.elapsed
	for table: Dictionary in [ShogunateEnemyData.ENEMIES, ProvinceEnemyData.ENEMIES, KuroganeEnemyData.ENEMIES, SunRoadEnemyData.ENEMIES]:
		for k: String in table:
			_kinds.append(k)
	_last_kills = _kill_sum()
	_last_ninja = float(game.stats.get("kill_" + ShogunateEnemyData.NINJA, 0.0))
	var to := boss.position - game.player.position
	_base_angle = to.angle() + PI * 0.5 if to.length() > 1.0 else 0.0  # The first regiment marches in beside his platform.
	for i in ShogunData.REGIMENTS.size():
		var r := Regiment.new()
		r.index = i
		r.def = ShogunData.REGIMENTS[i]
		r.reserve = int(r.def["size"])
		r.dir = Vector2.from_angle(_base_angle + ShogunData.MARCH_TURN * float(i))
		regiments.append(r)


## Total soldiers (the bar's full length).
func total() -> int:
	var n := 0
	for r in regiments:
		n += int(r.def["size"])
	return n


## Soldiers he has left (the bar; see the header).
func left() -> int:
	var n := 0
	for r in regiments:
		if r.state != BROKEN:
			n += r.reserve + r.out()
	return n


## Regiments on the field now.
func marching() -> int:
	var n := 0
	for r in regiments:
		if r.state == MARCHING:
			n += 1
	return n


## Per-tick update (BossShogun on his platform): deaths, breaks, the trickle's
## points, the march and the batches.
func step(delta: float) -> void:
	var member_deaths := 0  # Tracked soldiers killed this tick.
	for r in regiments:
		if r.state == MARCHING:
			member_deaths += _poll(r)
	var ninja := float(game.stats.get("kill_" + ShogunateEnemyData.NINJA, 0.0))
	var ninja_new := int(ninja - _last_ninja)  # Ninja killed this tick.
	_last_ninja = ninja
	var ambush_deaths := 0  # Of them, counted against an ambush regiment.
	for r in regiments:
		if r.state == MARCHING and r.ambush_out > 0 and ninja_new > 0:
			var k := mini(ninja_new, r.ambush_out)
			r.ambush_out -= k
			ninja_new -= k
			ambush_deaths += k
	var kills := _kill_sum()
	var trickle := int(kills - _last_kills) - member_deaths - ambush_deaths  # Other Shogunate kills this tick.
	_last_kills = kills
	if member_deaths > 0:
		game.stat_add("shogun_member_kills", float(member_deaths))
	if ambush_deaths > 0:
		game.stat_add("shogun_ambush_kills", float(ambush_deaths))
	if trickle > 0:
		_take_points(trickle)
	if stopped:
		return
	_march()
	for r in regiments:
		if r.state != MARCHING:
			continue
		r.batch_cd -= delta
		if r.batch_cd <= 0.0 and r.reserve > 0 and r.out() < int(r.def["field"]):
			r.batch_cd = float(r.def["every"])
			_send(r)


## Ends the march (the Shogun comes down to duel): no more batches; a regiment
## that never marched sends its Hatamoto alone (so every banner can still be
## broken: Regiments Broken), its reserve stays where it is.
func stop() -> void:
	stopped = true
	for r in regiments:
		if r.state == WAITING and r.reserve > 0:
			r.state = MARCHING
			r.marched_at = game.elapsed
			_send_hatamoto(r)


## Drops regiment `r`'s dead members (returns how many were killed) and breaks
## it when its Hatamoto fell.
func _poll(r: Regiment) -> int:
	var dead := 0
	var i := 0
	while i < r.members.size():
		var m := r.members[i]
		if m.active and m.generation == r.gens[i]:
			i += 1
			continue
		r.members.remove_at(i)
		r.gens.remove_at(i)
		dead += 1
	if r.hatamoto != null and not (r.hatamoto.active and r.hatamoto.generation == r.hat_gen):
		r.hatamoto = null
		_break(r)
	return dead


## Regiment `r`'s Hatamoto fell: its soldiers flee, its reserve is lost.
func _break(r: Regiment) -> void:
	r.state = BROKEN
	banners_broken += 1
	game.stat_add("shogun_banners_broken", 1.0)
	game.stats["shogun_regiment_%d_broken_at" % r.index] = game.elapsed
	var fled := 0
	for m in r.members:
		if m.active:
			game.effects.spawn_ring(m.position, Palette.SHOGUN_INDIGO_LIGHT)
			game.enemies.despawn(m)
			fled += 1
	r.members.clear()
	r.gens = PackedInt32Array()
	if r.ambush_out > 0:
		fled += _flee_ninja(r.ambush_out)
		r.ambush_out = 0
	game.stat_add("shogun_fled", float(fled))
	game.stat_add("shogun_reserve_lost", float(r.reserve))
	r.reserve = 0
	game.enemies.show_banner("A Hatamoto falls: %s breaks and flees! (%d / %d banners)" % [String(r.def["name"]).get_slice(":", 0), banners_broken, regiments.size()])
	(boss as BossShogun).play_sound("regiment_break", boss.position)


## The ambush regiment's ninja on the field vanish in smoke (at most `n`, in
## the order of the enemy list); returns how many.
func _flee_ninja(n: int) -> int:
	var gone := 0
	for e: Enemy in game.enemies.active:
		if gone >= n:
			break
		if e.active and e.kind == ShogunateEnemyData.NINJA and not e.is_reckoning:
			game.effects.spawn_ring(e.position, Palette.SHOGUN_INDIGO_LIGHT)
			game.enemies.despawn(e)
			gone += 1
	return gone


## `n` other Shogunate kills: off the first reserve that lasts.
func _take_points(n: int) -> void:
	game.stat_add("shogun_trickle_points", float(n))
	for pass_state: int in [MARCHING, WAITING]:
		for r in regiments:
			if n <= 0:
				return
			if r.state == pass_state and r.reserve > 0:
				var k := mini(n, r.reserve - (1 if r.state == WAITING else 0))  # A waiting regiment keeps its Hatamoto.
				if k > 0:
					r.reserve -= k
					n -= k


## Marches the next regiment when its time came (or nothing is on the field).
func _march() -> void:
	if _next >= regiments.size():
		return
	var due := start + ShogunData.FIRST_MARCH + ShogunData.MARCH_EVERY * float(_next)  # Its marching time.
	var m := marching()
	if m >= ShogunData.MAX_ACTIVE or (game.elapsed < due and m > 0) or game.elapsed < start + ShogunData.FIRST_MARCH:
		return
	var r := regiments[_next]
	_next += 1
	r.state = MARCHING
	r.marched_at = game.elapsed
	r.batch_cd = 0.0
	game.stat_add("shogun_regiments_marched", 1.0)
	game.stat_add("boss_atk_regiment", 1.0)
	game.stats["shogun_regiment_%d_order" % r.index] = float(r.index)
	game.enemies.show_banner(String(r.def["name"]))
	(boss as BossShogun).signal_fan()


## Sends one batch of regiment `r` (its Hatamoto with the first).
func _send(r: Regiment) -> void:
	var g := game
	var ring := g.gameplay_view_size().length() * 0.5 + WaveData.SPAWN_MARGIN  # The spawn ring (px).
	var at0 := g.player.position + r.dir * ring  # The line's centre.
	var side := r.dir.orthogonal()
	var n := mini(int(r.def["batch"]), r.reserve)
	if r.hatamoto == null and r.reserve > 0:
		_send_hatamoto(r)
		n = mini(n, r.reserve)
	if String(r.def["order"]) == "ambush" and g.shogunate != null and g.shogunate.sun.enabled and g.shogunate.sun.is_dusk_or_later():
		g.shogunate.ambush.start_event({"groups": [{"kind": ShogunateEnemyData.NINJA, "count": n, "elite": false}], "banner": ""})
		r.ambush_out += n
		r.reserve -= n
		g.stat_add("shogun_soldiers_sent", float(n))
		return
	var elites := int(r.def["elites"])
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := at0 + side * (float(i) - float(n - 1) * 0.5) * ShogunData.LINE_SPACING
		var e := g.enemies.spawn_at(_pick(r.def["kinds"]), at, i < elites)
		r.members.append(e)
		r.gens.append(e.generation)
		r.reserve -= 1
		g.stat_add("shogun_soldiers_sent", 1.0)


## Regiment `r`'s Hatamoto marches in at the head of its line (his banner in
## the regiment's colour; he is a point of its reserve).
func _send_hatamoto(r: Regiment) -> void:
	var g := game
	var ring := g.gameplay_view_size().length() * 0.5 + WaveData.SPAWN_MARGIN  # The spawn ring (px).
	var h := g.enemies.spawn_at(KuroganeEnemyData.HATAMOTO, g.player.position + r.dir * (ring + 26.0), true)
	if h.kit is HatamotoKit:
		(h.kit as HatamotoKit).set_regiment(h, r.index, r.def["color"])
	r.hatamoto = h
	r.hat_gen = h.generation
	r.members.append(h)
	r.gens.append(h.generation)
	r.reserve -= 1
	g.stat_add("shogun_soldiers_sent", 1.0)


## A soldier kind by weight (the seeded gameplay RNG).
func _pick(kinds: Dictionary) -> String:
	var sum := 0.0
	for k: String in kinds:
		sum += float(kinds[k])
	var roll := randf() * sum
	for k: String in kinds:
		roll -= float(kinds[k])
		if roll <= 0.0:
			return k
	return String(kinds.keys()[0])


## The sum of every Shogunate kind's kill stat.
func _kill_sum() -> float:
	var s := 0.0
	for k in _kinds:
		s += float(game.stats.get("kill_" + k, 0.0))
	return s


## One autotest summary of the regiments: "order state (sent/left)".
func summary() -> String:
	var parts := PackedStringArray()
	for r in regiments:
		var st := "waiting" if r.state == WAITING else ("marching" if r.state == MARCHING else "BROKEN at %s" % EmpireReport._clock(float(game.stats.get("shogun_regiment_%d_broken_at" % r.index, 0.0))))
		parts.append("%s %s (left %d)" % [String(r.def["order"]), st, (r.reserve + r.out()) if r.state != BROKEN else 0])
	return ", ".join(parts)
