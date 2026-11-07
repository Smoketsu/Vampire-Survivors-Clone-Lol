## NightSwarm — the Night Swarm spell (AbilityData "night_swarm"; Act VII,
## Castle Sanguis; GDD §15.0 "Night Swarm, Nocturne, Old Blood and the
## Dhampir"; owner-approved proposal: "a cloud of spectral bats circles the
## necromancer and darts at enemies"; unlocked by defeating Queen Carmilla and
## the Elder, then offered on every stage at the later-item card weight).
## A swarm of `bats` spectral bats (plus the Dhampir's Half-Blood innate, at
## most NightSwarmData.MAX_BATS) circles the necromancer `orbit` px out
## (NightSwarmData.ORBIT_SPEED rad/s). Each bat, every `cooldown` s (staggered
## around the swarm), DARTS at the nearest open foe within AIM_RANGE px of the
## necromancer (DART_SPEED px/s, following it), BITES it for `damage`
## (CombatResolver.damage_enemy(), the friendly damage path) and flies back to
## its place. Evolved into NOCTURNE (EvolutionData "nocturne", detected by the
## "chain" key): more bats, and after each bite the bat LEAPS on to up to
## `chain` more foes within CHAIN_RANGE px (`chain_share` x the damage each).
## OLD BLOOD (the paired passive): its cooldown share is applied by
## AbilityManager.apply_spell_mods(), and each bite heals the necromancer for
## `bite_heal` x its damage (CombatResolver.heal_player(), at most
## HEAL_CAP_PER_S HP a second).
## Determinism: no RNG; the nearest foe, ties in the spatial hash's order; the
## swarm's angle runs on game time. Stats: swarm_darts, swarm_bites,
## swarm_leaps, swarm_heal, swarm_whiffs; damage as dmg_night_swarm /
## dmg_nocturne / dmg_nocturne_leap.
class_name NightSwarm
extends NecroSpell

## Bat state: circling the necromancer.
const ORBIT: int = 0
## Bat state: darting at a foe.
const DART: int = 1
## Bat state: flying back to its place.
const BACK: int = 2

## The swarm: {state, pos (world px), cd (s to its next dart), target (Enemy),
## gen (int), left (leaps left), t (s away), hit (Array of foes bitten this dart)}.
var bats: Array[Dictionary] = []
## Angle (rad) of the first bat's place on the circle.
var _angle: float = 0.0
## HP Old Blood may still heal this second (refilled each second).
var _heal_budget: float = 0.0
## Seconds until the heal budget refills.
var _heal_refill: float = 0.0


## Moves the swarm, launches and lands its darts.
func step(delta: float, stats: Dictionary) -> void:
	var n := mini(int(stats.get("bats", 3)) + int(game.character.innate_value(NightSwarmData.EXTRA_KEY)), NightSwarmData.MAX_BATS)
	_resize(n, float(stats["cooldown"]))
	_angle = fmod(_angle + NightSwarmData.ORBIT_SPEED * delta, TAU)
	_heal_refill -= delta
	if _heal_refill <= 0.0:
		_heal_refill = 1.0
		_heal_budget = NightSwarmData.HEAL_CAP_PER_S
	var p := game.player.position
	var orbit := float(stats["orbit"])
	for i in bats.size():
		var b := bats[i]
		var home := p + Vector2.from_angle(_angle + TAU * float(i) / float(maxi(1, bats.size()))) * orbit
		match int(b["state"]):
			ORBIT:
				b["pos"] = home
				b["cd"] = float(b["cd"]) - delta
				if float(b["cd"]) <= 0.0:
					var foe := _nearest(p, NightSwarmData.AIM_RANGE, [])
					if foe == null:
						b["cd"] = AbilityData.SPELL_RETRY
					else:
						_launch(b, foe, int(stats.get("chain", 0)))
			DART:
				_step_dart(b, delta, stats)
			BACK:
				var to := home - Vector2(b["pos"])
				var stepl := NightSwarmData.DART_SPEED * delta
				if to.length() <= stepl:
					b["pos"] = home
					b["state"] = ORBIT
					b["cd"] = float(stats["cooldown"])
				else:
					b["pos"] = Vector2(b["pos"]) + to.normalized() * stepl
	queue_redraw()


## Grows or shrinks the swarm to `n` bats (new ones staggered over `cd` s).
func _resize(n: int, cd: float) -> void:
	while bats.size() > n:
		bats.pop_back()
	while bats.size() < n:
		var k := bats.size()
		bats.append({"state": ORBIT, "pos": game.player.position, "cd": cd * (0.3 + 0.7 * float(k) / float(maxi(1, n))),
			"target": null, "gen": 0, "left": 0, "t": 0.0, "hit": []})


## The nearest open foe within `reach` px of `p` not in `skip` (null = none).
func _nearest(p: Vector2, reach: float, skip: Array) -> Enemy:
	game.enemy_grid.query(p, reach, _tmp)
	var best: Enemy = null
	var bd := INF
	for e: Enemy in _tmp:
		if not is_open_target(e) or skip.has(e):
			continue
		var d := p.distance_to(e.position)
		if d <= reach and d < bd:
			bd = d
			best = e
	return best


## Sends bat `b` darting at `foe` (`chain` leaps after the bite: Nocturne).
func _launch(b: Dictionary, foe: Enemy, chain: int) -> void:
	b["state"] = DART
	b["target"] = foe
	b["gen"] = foe.generation
	b["left"] = chain
	b["t"] = 0.0
	b["hit"] = []
	game.stat_add("swarm_darts", 1.0)


## A darting bat flies at its foe; at reach it bites (and Nocturne's leaps on).
func _step_dart(b: Dictionary, delta: float, stats: Dictionary) -> void:
	b["t"] = float(b["t"]) + delta
	var foe: Enemy = b["target"]
	if foe == null or not foe.active or foe.generation != int(b["gen"]) or float(b["t"]) > NightSwarmData.DART_MAX_TIME:
		if (b["hit"] as Array).is_empty():
			game.stat_add("swarm_whiffs", 1.0)
		b["state"] = BACK
		return
	var to := foe.position - Vector2(b["pos"])
	var stepl := NightSwarmData.DART_SPEED * delta
	if to.length() - foe.radius - NightSwarmData.BITE_REACH > stepl:
		b["pos"] = Vector2(b["pos"]) + to.normalized() * stepl
		return
	b["pos"] = foe.position - to.normalized() * (foe.radius * 0.5)
	var evolved := stats.has("chain")
	var leap := not (b["hit"] as Array).is_empty()
	var dmg := float(stats["damage"]) * (float(stats.get("chain_share", 1.0)) if leap else 1.0)
	var src := NightSwarmData.CHAIN_SOURCE if leap else (NightSwarmData.EVOLVED_SOURCE if evolved else NightSwarmData.SOURCE)
	(b["hit"] as Array).append(foe)
	var dealt := game.combat.damage_enemy(foe, dmg, src)
	game.stat_add("swarm_leaps" if leap else "swarm_bites", 1.0)
	_old_blood(dealt, float(stats.get(NightSwarmData.HEAL_KEY, 0.0)))
	if int(b["left"]) > 0:
		var next := _nearest(Vector2(b["pos"]), NightSwarmData.CHAIN_RANGE, b["hit"])
		if next != null:
			b["left"] = int(b["left"]) - 1
			b["target"] = next
			b["gen"] = next.generation
			b["t"] = 0.0
			return
	b["state"] = BACK


## Old Blood: a bite heals the necromancer for `share` x the damage it dealt
## (0 when the passive is not owned), within this second's budget.
func _old_blood(dealt: float, share: float) -> void:
	if share <= 0.0 or dealt <= 0.0 or _heal_budget <= 0.0:
		return
	var amt := minf(dealt * share, _heal_budget)
	_heal_budget -= amt
	var got := game.combat.heal_player(amt)
	game.stat_add("swarm_heal", got)


## Autotest counters (the Night Swarm line of CastleSanguisReport).
func summary_extra() -> String:
	var st := game.stats
	return "bats=%d darts=%d bites=%d leaps=%d whiffs=%d heal=%d" % [bats.size(), int(st.get("swarm_darts", 0.0)), int(st.get("swarm_bites", 0.0)),
		int(st.get("swarm_leaps", 0.0)), int(st.get("swarm_whiffs", 0.0)), int(st.get("swarm_heal", 0.0))]


## The bats: a small dark-violet body with two wing flicks and red eyes,
## spectral (soul-teal edges: they are the necromancer's). Textures only.
## Visual only.
func _draw() -> void:
	if game == null:
		return
	var disc := SpriteBank.disc()
	var s := NightSwarmData.BAT_SIZE
	var flap := absf(sin(game.elapsed * 18.0))  # Wing beat 0..1.
	for b in bats:
		var p: Vector2 = b["pos"]
		var w := s * (0.8 + 0.6 * flap)
		draw_texture_rect(disc, Rect2(p - Vector2(w * 1.6, s * 0.35), Vector2(w * 3.2, s * 0.7)), false, Color(Palette.NECRO_GREEN, 0.35))  # The spectral wings.
		draw_texture_rect(disc, Rect2(p - Vector2(s * 0.7, s * 0.7), Vector2(s, s) * 1.4), false, Color(Palette.COURT_VELVET_LIGHT, 0.95))  # The body.
		draw_rect(Rect2(p + Vector2(-2, -1), Vector2(1, 1)), Palette.COURT_BLOOD_LIGHT)
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 1)), Palette.COURT_BLOOD_LIGHT)
