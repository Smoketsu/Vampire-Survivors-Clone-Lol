## DivineWrath — WRATH OF THE GODS, the Olympian Republic's headline rule (Act
## IV; GDD §15.0 "Wrath of the Gods"), owned by PantheonRules
## (`Game.pantheon.wrath`). ONE scheduler for every telegraphed hazard the gods
## throw at the arena; every hazard hits BOTH armies through CombatResolver:
## enemies (damage_enemy(), x the enemies' HP scaling), summons (damage_unit())
## and the necromancer (damage_player(); both x the enemies' damage scaling).
## The stage's STAGE "wrath" ({"kind": ..., plus overrides of
## PantheonRulesData.WRATH[kind]}) picks its kind; the other kinds keep their
## defaults for the Twilight. Three kinds:
##   waves     — Poseidon (Ilion): a wall of water from one edge (a random
##               heading), its foam line shown `telegraph` s ahead; it rolls
##               2 x start_dist px across the necromancer's position at `speed`.
##               A body the front crosses this tick is hit once (fodder,
##               PantheonKit.is_fodder(), is DROWNED outright); a body inside
##               the band behind the front is carried along at push_speed
##               through TerrainSlow.push_player() / push_summon() /
##               push_enemy() (the one ground push path; Arena.resolve_all()
##               runs right after, so nobody ends inside an obstacle, and the
##               Bone Ring re-forms by itself). Bosses, minibosses, structures
##               and floating bodies are not carried (TerrainSlow's rules).
##   lightning — Zeus (Olympus): salvos of bolts on marked circles (`telegraph`
##               s); the first lands near the necromancer, `bronze_aim` aim at
##               a bronze enemy near him when there is one (the lure), the rest
##               scatter. A strike hits everything inside its circle and
##               CHAINS hop by hop to the nearest bronze-clad enemy
##               (PantheonKit.is_bronze()) within chain_range, up to
##               chain_count of them.
##   fissures  — Hades (Underworld): red telegraph lines that open into cracks
##               for `open` s (one across the necromancer). An open crack burns
##               whoever stands on it every `tick` s, SWALLOWS CORPSES (no
##               corpse and no raise on it: swallows(), read by
##               Enemy.leaves_corpse(), the one corpse gate) and, for its first
##               spit_time s, spits a Shade of the Dead every spit_every s.
## THE TWILIGHT OF THE GODS (the shared Act IV Reckoning hook): on a stage whose
## RECKONING has a "twilight" dictionary, from 0:00 every kind in its "kinds"
## fires, each on interval x interval_mult x speedup ^ minutes past 0:00 (never
## under interval x interval_min_mult); the Bronze Titans are the RECKONING kind.
## Grounded Bones hook (counter-passive, NOT built): grounded_mult(), the one
## read, cuts the lightning and wave damage to the army and the necromancer.
## Stats: wrath_salvos_<kind>, wrath_waves, wrath_bolts, wrath_fissures,
## wrath_drowned, wrath_chains, wrath_shades_spat, wrath_corpses_swallowed
## (PantheonRules), wrath_enemy_dmg_<kind>, wrath_capped; the damage to summons
## and the necromancer is CombatResolver's summon_dmg_from_wrath_* /
## player_dmg_from_wrath_*. Determinism: the seeded gameplay RNG only (it
## exists only on Act IV); drawing uses none.
class_name DivineWrath
extends Node2D

## Damage source tag of each hazard (CombatResolver stats).
const SRC_WAVE: String = "wrath_wave"
## Damage source tag of a bolt's circle.
const SRC_BOLT: String = "wrath_lightning"
## Damage source tag of a chained hit.
const SRC_CHAIN: String = "wrath_chain"
## Damage source tag of an open fissure's burn.
const SRC_FISSURE: String = "wrath_fissure"

## Owning run.
var game: Game
## The stage's own wrath kind ("" when the stage has none: a Pantheon kind forced elsewhere).
var stage_kind: String = ""
## Wrath kind -> its settings (PantheonRulesData.WRATH defaults, the stage's
## own kind with the STAGE "wrath" overrides).
var cfg: Dictionary = {}
## Wrath kind -> game time (s) its next strike starts (absent = not scheduled).
var next_at: Dictionary = {}
## The Twilight settings (PantheonRulesData.TWILIGHT + the RECKONING
## "twilight" overrides; {} = no Twilight on this stage).
var twilight: Dictionary = {}
## True once the Twilight began (0:00 on a stage that has one).
var twilight_on: bool = false
## Rolling or telegraphed waves: {dir, origin, t0 (game time it starts to
## roll), c (its settings), rolled (bool)}.
var waves: Array[Dictionary] = []
## Pending bolts: {pos, land (game time), c}.
var bolts: Array[Dictionary] = []
## Telegraphed or open fissures: {a, b, open_t, close_t, next_tick, next_spit,
## spit_until, opened (bool), c}.
var fissures: Array[Dictionary] = []
## Short-lived lightning lines (visual only): {a, b, until (game time), sky (bool)}.
var flashes: Array[Dictionary] = []
## Reusable spatial-hash query buffer.
var _tmp: Array = []
## Bodies already struck by the current bolt (chain scratch).
var _struck: Array[Enemy] = []
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Builds the scheduler for `p_game` (PantheonRules adds it as a child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "DivineWrath"
	z_index = -1  # Telegraphs, water and cracks lie on the ground, under the units.
	for k: String in PantheonRulesData.WRATH_KINDS:
		cfg[k] = (PantheonRulesData.WRATH[k] as Dictionary).duplicate()
	var w: Dictionary = p_game.stage_def.get("wrath", {})  # The stage's wrath.
	stage_kind = String(w.get("kind", ""))
	if cfg.has(stage_kind):
		for key: String in w:
			if key != "kind":
				(cfg[stage_kind] as Dictionary)[key] = w[key]
		next_at[stage_kind] = float(cfg[stage_kind]["first"])
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if r.has("twilight"):
		twilight = PantheonRulesData.TWILIGHT.duplicate()
		var over: Dictionary = r["twilight"]  # The stage's own overrides.
		for key: String in over:
			twilight[key] = over[key]


## Per-tick update: the schedule (and the Twilight), then every hazard.
func step(delta: float) -> void:
	var t := game.elapsed  # Game time (s).
	if not twilight.is_empty() and not twilight_on and game.countdown_finished():
		twilight_on = true
		var kinds: Array = twilight["kinds"]
		for i in kinds.size():
			var k := String(kinds[i])
			var first := t + float(twilight["first_delay"]) * float(i)  # This kind's first Twilight strike.
			next_at[k] = minf(float(next_at.get(k, INF)), first)
	for k: String in PantheonRulesData.WRATH_KINDS:
		if next_at.has(k) and t >= float(next_at[k]):
			_strike(k, t)
			next_at[k] = t + interval(k)
	_step_waves(delta, t)
	_step_bolts(t)
	_step_fissures(t)
	var i := flashes.size() - 1
	while i >= 0:
		if t >= float(flashes[i]["until"]):
			flashes.remove_at(i)
		i -= 1
	var busy := not (waves.is_empty() and bolts.is_empty() and fissures.is_empty() and flashes.is_empty())
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Seconds from one strike of kind `k` to the next (the Twilight's faster
## rhythm after 0:00 for its kinds).
func interval(k: String) -> float:
	var base := float(cfg[k]["interval"])  # The kind's own interval (s).
	if twilight_on and (twilight["kinds"] as Array).has(k):
		var m := maxf(0.0, game.elapsed - WaveData.RUN_DURATION) / 60.0  # Minutes past 0:00.
		return maxf(base * float(twilight["interval_min_mult"]), base * float(twilight["interval_mult"]) * pow(float(twilight["speedup"]), m))
	return base


## Grounded Bones hook (counter-passive, NOT built): the share of lightning
## and wave damage the army and the necromancer still take, 1 - PassiveData
## row GROUNDED_BONES's value (exactly 1 while no such passive exists).
func grounded_mult() -> float:
	return maxf(0.0, 1.0 - game.abilities.passive_value(PantheonRulesData.GROUNDED_BONES, PantheonRulesData.GROUNDED_BONES_KEY))


## Starts one strike of kind `k` at game time `t` (its telegraph).
func _strike(k: String, t: float) -> void:
	var c: Dictionary = cfg[k]
	var cap := int(PantheonRulesData.WRATH_CAPS[k])  # Most pending of this kind.
	var p := _aim_player().position  # The necromancer it strikes around.
	match k:
		"waves":
			if waves.size() >= cap:
				game.stat_add("wrath_capped", 1.0)
				return
			waves.append({"dir": Vector2.from_angle(randf() * TAU), "origin": p, "t0": t + float(c["telegraph"]), "c": c, "rolled": false})
		"lightning":
			var n := int(c["count"])  # Bolts this salvo.
			var aim := _bronze_near(p, float(c["scatter"]))  # Bronze bodies the storm may favour.
			for i in n:
				if bolts.size() >= cap:
					game.stat_add("wrath_capped", 1.0)
					break
				var at := p + Vector2.from_angle(randf() * TAU) * randf_range(0.0, float(c["near"]))  # The first: near him.
				if i > 0:
					if i <= int(c["bronze_aim"]) and not aim.is_empty():
						at = aim[randi() % aim.size()].position
					else:
						at = p + Vector2.from_angle(randf() * TAU) * randf_range(float(c["radius"]), float(c["scatter"]))
				bolts.append({"pos": at, "land": t + float(c["telegraph"]), "c": c})
		"fissures":
			var n := int(c["count"])  # Fissures this salvo.
			for i in n:
				if fissures.size() >= cap:
					game.stat_add("wrath_capped", 1.0)
					break
				var centre := p + Vector2.from_angle(randf() * TAU) * randf_range(0.0, float(c["first_scatter"]))  # The first: across him.
				if i > 0:
					centre = p + Vector2.from_angle(randf() * TAU) * randf_range(float(c["min_scatter"]), float(c["scatter"]))
				var half := Vector2.from_angle(randf() * TAU) * float(c["length"]) * 0.5  # Half the crack.
				var open_t := t + float(c["telegraph"])  # Game time it opens.
				fissures.append({"a": centre - half, "b": centre + half, "open_t": open_t, "close_t": open_t + float(c["open"]),
					"next_tick": open_t, "next_spit": open_t, "spit_until": open_t + float(c["spit_time"]), "opened": false, "c": c})
	game.stat_add("wrath_salvos_" + k, 1.0)


## The necromancer a salvo strikes around: solo, the player; co-op, one of the
## standing necromancers picked with the run's seeded RNG (a downed one is
## skipped; with both down, the bound one).
func _aim_player() -> Necromancer:
	if game.coop == null:
		return game.player
	var standing: Array[Necromancer] = []  # Necromancers still on their feet.
	for s in game.coop.slots:
		if not s.downed:
			standing.append(s.player)
	if standing.is_empty():
		return game.player
	if standing.size() == 1:
		return standing[0]
	return standing[randi() % standing.size()]


## Active bronze enemies within `reach` px of `p` (the lightning's lure).
func _bronze_near(p: Vector2, reach: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	game.enemy_grid.query(p, reach, _tmp)
	for e: Enemy in _tmp:
		if e.active and e.kit is PantheonKit and (e.kit as PantheonKit).is_bronze() and not e.is_boss:
			out.append(e)
	return out


# =====================================================================================
# Waves (Poseidon)
# =====================================================================================

## Rolls every wave: hits the bodies its front crosses this tick, carries the
## bodies inside its band, retires it once it has crossed.
func _step_waves(delta: float, t: float) -> void:
	var i := waves.size() - 1
	while i >= 0:
		var w := waves[i]
		if t < float(w["t0"]):
			i -= 1
			continue
		var c: Dictionary = w["c"]
		if not bool(w["rolled"]):
			w["rolled"] = true
			game.stat_add("wrath_waves", 1.0)
			game.pantheon.play_sound("wave", game.player.position)
			game.shake(4.0)
		var sd := float(c["start_dist"])  # Start distance behind the necromancer's line (px).
		var f := (t - float(w["t0"])) * float(c["speed"]) - sd  # Front, along the heading from the origin (px).
		var f_prev := maxf(-sd - 1.0, f - float(c["speed"]) * delta)  # Front a tick ago.
		_wave_bodies(w, f_prev, f, delta)
		if f - float(c["band"]) > sd:
			waves.remove_at(i)
		i -= 1


## Applies wave `w` (front moved from `f_prev` to `f` this tick) to every body.
func _wave_bodies(w: Dictionary, f_prev: float, f: float, delta: float) -> void:
	var c: Dictionary = w["c"]
	var dir: Vector2 = w["dir"]
	var perp := Vector2(-dir.y, dir.x)  # Along the wall.
	var origin: Vector2 = w["origin"]
	var half := float(c["half_len"])  # Half the wall's length (px).
	var band := float(c["band"])  # Water depth behind the front (px).
	var push := dir * float(c["push_speed"])  # Carry velocity (px/s).
	var dm := game.enemies.damage_mult * grounded_mult()  # Army / necromancer damage scaling.
	# The necromancer(s): co-op binds each slot so the push reads its own dash.
	for pl in game.all_players:
		var rel := pl.position - origin
		if absf(rel.dot(perp)) > half:
			continue
		var proj := rel.dot(dir)  # Along the heading (px).
		if proj > f_prev and proj <= f:
			game.combat.damage_player(float(c["dmg_player"]) * dm, SRC_WAVE, pl)
		if proj >= f - band and proj <= f:
			_push_player(pl, push, delta)
	# Summons of every army (index loop from the end: a death may remove one).
	for h in game.all_hordes:
		var j := h.units.size() - 1
		while j >= 0:
			if j < h.units.size():
				var u := h.units[j]
				var rel := u.position - origin
				if u.active and absf(rel.dot(perp)) <= half:
					var proj := rel.dot(dir)
					if proj >= f - band and proj <= f:
						TerrainSlow.push_summon(game, u, push, delta)
					if proj > f_prev and proj <= f:
						game.combat.damage_unit(u, float(c["dmg_summon"]) * dm, SRC_WAVE)
			j -= 1
	# Enemies (killed ones stay in the list until compaction).
	var dmg_e := float(c["dmg_enemy"]) * game.enemies.hp_mult  # Damage to a non-fodder enemy.
	for e in game.enemies.active:
		if not e.active or e.is_structure or e.untargetable:
			continue
		var rel := e.position - origin
		if absf(rel.dot(perp)) > half:
			continue
		var proj := rel.dot(dir)
		if proj >= f - band and proj <= f:
			TerrainSlow.push_enemy(game, e, push, delta)
		if proj > f_prev and proj <= f:
			var fodder := e.kit is PantheonKit and (e.kit as PantheonKit).is_fodder() and not e.is_boss and not e.is_miniboss
			if fodder:
				game.combat.damage_enemy(e, e.max_hp * float(c["drown_hp_mult"]), SRC_WAVE)  # Drowned outright.
				game.stat_add("wrath_drowned", 1.0)
			else:
				game.stat_add("wrath_enemy_dmg_waves", game.combat.damage_enemy(e, dmg_e, SRC_WAVE))


## Carries necromancer `pl` by `v` px/s for `delta` s through the one ground
## push path (TerrainSlow.push_player(), which reads the BOUND player: co-op
## binds `pl`'s slot around the call).
func _push_player(pl: Necromancer, v: Vector2, delta: float) -> void:
	if game.coop == null:
		TerrainSlow.push_player(game, v, delta)
		return
	var prev := game.coop.bound
	game.coop.bind(game.coop.slot_of(pl))
	TerrainSlow.push_player(game, v, delta)
	game.coop.bind(prev)


# =====================================================================================
# Lightning (Zeus)
# =====================================================================================

## Lands every bolt whose time has come (in the order they were queued).
func _step_bolts(t: float) -> void:
	var i := 0
	while i < bolts.size():
		var b := bolts[i]
		if t >= float(b["land"]):
			bolts.remove_at(i)
			_land_bolt(b, t)
		else:
			i += 1


## Bolt `b` strikes: everything inside its circle, then the chain to bronze.
func _land_bolt(b: Dictionary, t: float) -> void:
	var c: Dictionary = b["c"]
	var at: Vector2 = b["pos"]
	var r := float(c["radius"])  # Circle radius (px).
	game.stat_add("wrath_bolts", 1.0)
	game.effects.impact(at, r, Palette.PANTHEON_AEGEAN_LIGHT)
	game.pantheon.play_sound("thunder", at)
	game.shake(2.5)
	flashes.append({"a": at + Vector2(0.0, -260.0), "b": at, "until": t + 0.22, "sky": true})
	var dm := game.enemies.damage_mult * grounded_mult()  # Army / necromancer damage scaling.
	for pl in game.all_players:
		if pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(c["dmg_player"]) * dm, SRC_BOLT, pl)
	game.ally_grid.query(at, r + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(at) <= r + u.radius:
			game.combat.damage_unit(u, float(c["dmg_summon"]) * dm, SRC_BOLT)
	_struck.clear()
	var hp := game.enemies.hp_mult  # Enemy damage scaling.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and e.position.distance_to(at) <= r + e.radius:
			_struck.append(e)
	for e in _struck:
		if e.active:
			game.stat_add("wrath_enemy_dmg_lightning", game.combat.damage_enemy(e, float(c["dmg_enemy"]) * hp, SRC_BOLT))
	# The chain: hop by hop to the nearest bronze body not yet struck.
	var from := at  # Where the current hop starts.
	for k in int(c["chain_count"]):
		var best: Enemy = null
		var best_d := INF
		game.enemy_grid.query(from, float(c["chain_range"]), _tmp)
		for e: Enemy in _tmp:
			if not e.active or _struck.has(e) or not (e.kit is PantheonKit) or not (e.kit as PantheonKit).is_bronze():
				continue
			var d := from.distance_to(e.position)
			if d <= float(c["chain_range"]) and d < best_d:
				best = e
				best_d = d
		if best == null:
			break
		_struck.append(best)
		flashes.append({"a": from, "b": best.position, "until": t + 0.25, "sky": false})
		from = best.position
		game.stat_add("wrath_chains", 1.0)
		game.stat_add("wrath_enemy_dmg_lightning", game.combat.damage_enemy(best, float(c["chain_damage"]) * hp, SRC_CHAIN))


# =====================================================================================
# Fissures (Hades)
# =====================================================================================

## Opens, burns, spits and closes every fissure on its clock.
func _step_fissures(t: float) -> void:
	var i := fissures.size() - 1
	while i >= 0:
		var fz := fissures[i]
		if t >= float(fz["close_t"]):
			fissures.remove_at(i)
			i -= 1
			continue
		if t >= float(fz["open_t"]):
			var c: Dictionary = fz["c"]
			if not bool(fz["opened"]):
				fz["opened"] = true
				game.stat_add("wrath_fissures", 1.0)
				game.pantheon.play_sound("fissure", (fz["a"] as Vector2).lerp(fz["b"], 0.5))
				game.shake(2.0)
			if t >= float(fz["next_tick"]):
				fz["next_tick"] = float(fz["next_tick"]) + float(c["tick"])
				_burn(fz)
			if t >= float(fz["next_spit"]) and t < float(fz["spit_until"]):
				fz["next_spit"] = float(fz["next_spit"]) + float(c["spit_every"])
				_spit(fz)
		i -= 1


## One burn of open fissure `fz`: everything standing on it.
func _burn(fz: Dictionary) -> void:
	var c: Dictionary = fz["c"]
	var a: Vector2 = fz["a"]
	var b: Vector2 = fz["b"]
	var hw := float(c["width"]) * 0.5  # Half the crack's width (px).
	var mid := a.lerp(b, 0.5)
	var reach := a.distance_to(b) * 0.5 + hw  # Query radius around the middle (px).
	var dm := game.enemies.damage_mult  # Army / necromancer damage scaling.
	for pl in game.all_players:
		if _seg_dist(pl.position, a, b) <= hw + pl.radius:
			game.combat.damage_player(float(c["dmg_player"]) * dm, SRC_FISSURE, pl)
	game.ally_grid.query(mid, reach + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and _seg_dist(u.position, a, b) <= hw + u.radius:
			game.combat.damage_unit(u, float(c["dmg_summon"]) * dm, SRC_FISSURE)
	_struck.clear()
	game.enemy_grid.query(mid, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and not e.floating and _seg_dist(e.position, a, b) <= hw + e.radius:
			_struck.append(e)
	var hp := game.enemies.hp_mult  # Enemy damage scaling.
	for e in _struck:
		if e.active:
			game.stat_add("wrath_enemy_dmg_fissures", game.combat.damage_enemy(e, float(c["dmg_enemy"]) * hp, SRC_FISSURE))


## Open fissure `fz` spits one shade at a point along it (never beyond the
## enemy hard cap).
func _spit(fz: Dictionary) -> void:
	if game.enemies.regular_alive() >= game.enemies.hard_cap():
		return
	var at := (fz["a"] as Vector2).lerp(fz["b"], randf_range(0.15, 0.85))  # Where it climbs out.
	game.enemies.spawn_at(String((fz["c"] as Dictionary)["spit_kind"]), at, false)
	game.stat_add("wrath_shades_spat", 1.0)


## True when a body of radius `r` at `pos` lies on an OPEN fissure (a corpse
## there is swallowed: Enemy.leaves_corpse()).
func swallows(pos: Vector2, r: float) -> bool:
	var t := game.elapsed
	for fz in fissures:
		if t >= float(fz["open_t"]) and _seg_dist(pos, fz["a"], fz["b"]) <= float((fz["c"] as Dictionary)["width"]) * 0.5 + r * float((fz["c"] as Dictionary)["swallow_body"]):
			return true
	return false


## Distance (px) from `p` to the segment `a`-`b`.
static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


# =====================================================================================
# Autotest and drawing
# =====================================================================================

## Autopilot hint: a push off every pending bolt circle and every telegraphed
## or open fissure at `p` (a wall of water cannot be dodged).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var pr := game.player.radius + PantheonRulesData.DANGER_REACH  # Margin (px).
	for b in bolts:
		var off: Vector2 = p - (b["pos"] as Vector2)
		var reach := float((b["c"] as Dictionary)["radius"]) + pr
		var d := off.length()
		if d < reach:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / reach) * 1.5
	for fz in fissures:
		var q := Geometry2D.get_closest_point_to_segment(p, fz["a"], fz["b"])
		var off := p - q
		var reach := float((fz["c"] as Dictionary)["width"]) * 0.5 + pr
		var d := off.length()
		if d < reach:
			var ab: Vector2 = (fz["b"] as Vector2) - (fz["a"] as Vector2)
			var side := Vector2(-ab.y, ab.x).normalized()  # Off the crack, sideways.
			push += (off / d if d > 0.01 else side) * (1.0 - d / reach) * 1.5
	return push


## The telegraphs and the hazards (visual only; no RNG):
##   waves     — the foam line at the starting edge with chevrons along the
##               heading while it telegraphs; then the band of dark water with
##               a bright foam crest at its front.
##   lightning — an Aegean circle that fills as the bolt nears, a white cross;
##               the bolt and its chains as short jagged white-blue lines.
##   fissures  — a red line that thickens during the telegraph; then a black
##               crack with a red glowing rim.
func _draw() -> void:
	var t := game.elapsed
	for w in waves:
		var c: Dictionary = w["c"]
		var dir: Vector2 = w["dir"]
		var perp := Vector2(-dir.y, dir.x)
		var o: Vector2 = w["origin"]
		var half := float(c["half_len"])
		var sd := float(c["start_dist"])
		if t < float(w["t0"]):
			var k := clampf(1.0 - (float(w["t0"]) - t) / maxf(0.01, float(c["telegraph"])), 0.0, 1.0)  # 0 -> 1 as it nears.
			var line_c := o - dir * sd
			var blink := 0.55 + 0.45 * absf(sin(t * 9.0))
			draw_line(line_c - perp * half, line_c + perp * half, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.5 * blink + 0.3 * k), 3.0 + 3.0 * k)
			draw_line(line_c - perp * half - dir * 10.0, line_c + perp * half - dir * 10.0, Color(Palette.PANTHEON_AEGEAN, 0.3 + 0.3 * k), 8.0)
			var step := 120.0
			var s := -half
			while s <= half:
				var q := line_c + perp * s + dir * (14.0 + 30.0 * k)  # Chevron tip.
				draw_line(q - dir * 12.0 + perp * 8.0, q, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.6), 2.0)
				draw_line(q - dir * 12.0 - perp * 8.0, q, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.6), 2.0)
				s += step
			continue
		var f := (t - float(w["t0"])) * float(c["speed"]) - sd
		var back := maxf(-sd, f - float(c["band"]) * 2.5)  # Trailing edge of the drawn water (px).
		var pts := PackedVector2Array([o + dir * back - perp * half, o + dir * f - perp * half, o + dir * f + perp * half, o + dir * back + perp * half])
		draw_colored_polygon(pts, Color(Palette.PANTHEON_AEGEAN_DARK, 0.45))
		var band_pts := PackedVector2Array([o + dir * (f - float(c["band"])) - perp * half, o + dir * f - perp * half, o + dir * f + perp * half, o + dir * (f - float(c["band"])) + perp * half])
		draw_colored_polygon(band_pts, Color(Palette.PANTHEON_AEGEAN, 0.4))
		draw_line(o + dir * f - perp * half, o + dir * f + perp * half, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.95), 5.0)
		draw_line(o + dir * (f + 3.0) - perp * half, o + dir * (f + 3.0) + perp * half, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.8), 2.0)
	for b in bolts:
		var c: Dictionary = b["c"]
		var r := float(c["radius"])
		var at: Vector2 = b["pos"]
		var k := clampf(1.0 - (float(b["land"]) - t) / maxf(0.01, float(c["telegraph"])), 0.0, 1.0)
		draw_circle(at, r * k, Color(Palette.PANTHEON_AEGEAN, 0.16 + 0.16 * k))
		draw_arc(at, r, 0.0, TAU, 36, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.85), 2.0)
		draw_arc(at, r * 0.55, 0.0, TAU, 24, Color(Palette.PANTHEON_MARBLE_LIGHT, 0.45), 1.0)
		draw_line(at - Vector2(r * 0.3, 0), at + Vector2(r * 0.3, 0), Color(Palette.PANTHEON_MARBLE_LIGHT, 0.8), 1.0)
		draw_line(at - Vector2(0, r * 0.3), at + Vector2(0, r * 0.3), Color(Palette.PANTHEON_MARBLE_LIGHT, 0.8), 1.0)
	for fz in fissures:
		var c: Dictionary = fz["c"]
		var a: Vector2 = fz["a"]
		var b2: Vector2 = fz["b"]
		var wdt := float(c["width"])
		if t < float(fz["open_t"]):
			var k := clampf(1.0 - (float(fz["open_t"]) - t) / maxf(0.01, float(c["telegraph"])), 0.0, 1.0)
			var blink := 0.5 + 0.5 * absf(sin(t * 10.0))
			draw_line(a, b2, Color(Palette.CRIMSON, 0.25 + 0.5 * k * blink), 2.0 + wdt * 0.6 * k)
			draw_line(a, b2, Color(Palette.FLAME, 0.6 * blink), 1.0)
		else:
			draw_line(a, b2, Color(Palette.CRIMSON, 0.55), wdt + 6.0)
			draw_line(a, b2, Color(0.02, 0.0, 0.0, 0.95), wdt)
			draw_line(a, b2, Color(Palette.FLAME, 0.7), 2.0)
	for fl in flashes:
		var a: Vector2 = fl["a"]
		var b2: Vector2 = fl["b"]
		var n := 6  # Zigzag segments.
		var prev := a
		var side := (b2 - a).orthogonal().normalized()
		for s in range(1, n + 1):
			var q := a.lerp(b2, float(s) / float(n))
			if s < n:
				q += side * (7.0 if s % 2 == 0 else -7.0)
			draw_line(prev, q, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.8), 4.0)
			draw_line(prev, q, Palette.PANTHEON_MARBLE_LIGHT, 1.5)
			prev = q
