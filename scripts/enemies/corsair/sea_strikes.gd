## SeaStrikes — STRIKES FROM THE SEA, the third of the Black Tide's shared rules
## (Act X; GDD §15.0 "Strikes from the Sea"; owner-approved proposal: "Water
## creatures swim freely around and under the ship ... They strike the rail
## band (120 px inside the rail) and sometimes beyond it. A strike is a
## telegraphed circle (1.0 s, dark-water ring) that hits both armies"). Owned
## by Game.corsair; ONE SCHEDULER in the style of DivineWrath, seeded, with at
## most `cap` (8) swimmers alive:
##   * THE SWIMMERS: a water kind the timeline asks for
##     (CorsairRules.route_spawn() -> spawn_swimmer()) appears at a seeded
##     point of the hull (refused at the cap, counted) and circles it
##     `swim_offset` px out in the water at `swim_speed` (its side from its
##     think slot), SUBMERGED: untargetable (out of the enemy grid, so shots
##     and blows pass over it) and drawn as a dark shape and a fin. THIS is the
##     one place that moves a swimmer.
##   * THE STRIKE: every `strike_every` s (+- strike_jitter, seeded) a swimmer
##     picks a target within `reach` px (its row's "strike" "type" decides
##     which), stops at the hull point nearest it and SURFACES (hittable) for
##     the telegraph and `surface_time` s more; the circle (radius) shows
##     `telegraph` s and then hits everything inside it, BOTH ARMIES (summons
##     and the necromancer x the enemies' damage scaling, deck enemies x their
##     HP scaling) through CombatResolver.
##       - LEAP (the reef shark): the target is the nearest summon (else the
##         necromancer) at least LEAP inset px inside the rail; the telegraph is
##         the 0.8 s shadow; the shark lands there as an ORDINARY DECK ENEMY
##         (CorsairKit.leave_water(); it leaves the swimmer count) and can be
##         knocked back overboard like any boarder.
##       - TENTACLE (the kraken arm): the target is the nearest summon in the
##         RAIL BAND (rail_band px inside the rail; else the nearest summon or
##         necromancer in reach); when the circle lands the arm GRABS the
##         nearest grabbable summon in it: held through
##         SummonedUnit.held_until (renewed each tick by carry(), the one place
##         that moves it: dragged to the rail over the hold) and kept out of
##         the fight by ONE CombatResolver.stun_unit(u, hold, "tentacle_grab");
##         the arm stays surfaced TENTACLE surfaced s (3 s). Kill the arm and
##         the summon drops with a short daze (a rescue); after TENTACLE hold s
##         (5 s) it is DRAGGED OVERBOARD: u.director.on_unit_died(u, false)
##         (no death counted, no corpse; the class queue replaces it at its
##         next replenish). Grabbable: never airborne or flying, spawning,
##         dead, charmed, compelled or already held, never bigger than
##         TENTACLE max_radius (the Abomination, Colossus and Golem).
##   * strike(at, overrides) starts an OWNERLESS strike (a plain circle; the
##     Black Tide's rail strikes, phase 2's serpent breach and the Voodoo
##     Navigator's marks).
## Determinism: the seeded gameplay RNG only (spawn points, strike jitter),
## ordered lists with pooling generations. Stats: sea_swimmers,
## sea_refused_cap, sea_strikes_<type>, sea_leaps_landed, sea_grabs,
## sea_grab_rescues, sea_dragged, sea_strike_hits_summons, sea_strike_hits_you,
## sea_strike_enemy_dmg; the damage is CombatResolver's
## summon_dmg_from_sea_strike / player_dmg_from_sea_strike.
class_name SeaStrikes
extends RefCounted

## Owning run.
var game: Game
## True on an Act X stage (the sea runs).
var enabled: bool = false
## The sea's numbers (CorsairRulesData.SEA + the STAGE "sea").
var cfg: Dictionary = {}
## Live swimmers in spawn order: [Enemy, generation].
var swimmers: Array = []
## Telegraphed strikes: {type, owner (Enemy or null), gen, at, land (game s), c}.
var strikes: Array[Dictionary] = []
## Tentacle grabs: [arm Enemy, arm gen, summon, summon gen, grabbed at (s),
## dragged at (s), grab position, rail point].
var grabs: Array = []
## Most swimmers alive at once (the report).
var peak: int = 0
## Scratch query buffer.
var _tmp: Array = []


## Builds the sea for `p_game`; `p_enabled` false off Act X.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = CorsairRulesData.SEA.duplicate()
	var st: Dictionary = p_game.stage_def.get("sea", {})
	for k: String in st:
		cfg[k] = st[k]


## The strike numbers of swimmer `e` (SEA + its row's "strike"), or SEA.
func _c(e: Enemy) -> Dictionary:
	var c := cfg.duplicate()
	if e != null and e.kit is CorsairKit:
		var over: Dictionary = (e.kit as CorsairKit).d.get("strike", {})
		for k: String in over:
			c[k] = over[k]
	return c


## Swimmers alive now.
func alive() -> int:
	var n := 0
	for s: Array in swimmers:
		if _alive(s[0], int(s[1])) and CorsairKit.is_in_water(s[0]):
			n += 1
	return n


## A water kind the timeline asked for comes from the sea at a seeded point of
## the hull (false when refused at the cap).
func spawn_swimmer(kind: String, hp_scale: float, elite: bool, dmg_scale: float, reckoning: bool, force: bool = false) -> bool:
	if game.deck == null:
		return false
	if not force and alive() >= int(cfg["cap"]):  # Act X, the Treasure Galleon: `force` (a miniboss and its arms) ignores the cap.
		game.stat_add("sea_refused_cap", 1.0)
		return false
	var deck := game.deck
	var s := randf() * deck.perimeter_length  # Where along the hull it appears.
	var e := game.enemies.spawn_routed(kind, deck.center, hp_scale, elite)
	if dmg_scale != 1.0:
		e.damage *= dmg_scale
	if reckoning:
		e.is_reckoning = true
	var k := e.kit as CorsairKit
	if k == null or not k.in_water:
		return true  # Not a swimmer after all (no kit): it stays on the deck.
	k.swim_s = s
	k.next_strike = game.elapsed + float(_c(e)["first_strike"]) * (0.75 + 0.5 * randf())
	e.position = _swim_point(e, s)
	e.untargetable = true  # Submerged.
	swimmers.append([e, e.generation])
	peak = maxi(peak, alive())
	game.stat_add("sea_swimmers", 1.0)
	return true


## Where swimmer `e` is at hull arc length `s`: swim_offset px out in the water.
func _swim_point(e: Enemy, s: float) -> Vector2:
	var deck := game.deck
	return deck.perimeter_point(s) + deck.perimeter_normal(s) * (float(cfg["swim_offset"]) + e.radius * 0.5)


# =====================================================================================
# The clock
# =====================================================================================

## Per-tick update (CorsairRules.step()): swimmers swim, surface and strike;
## telegraphs land; grabs carry.
func step(delta: float) -> void:
	if not enabled or game.deck == null:
		return
	var now := game.elapsed
	var i := 0
	while i < swimmers.size():
		var e: Enemy = swimmers[i][0]
		if not _alive(e, int(swimmers[i][1])) or not CorsairKit.is_in_water(e):
			swimmers.remove_at(i)  # Killed, pooled, or landed on the deck.
			continue
		_step_swimmer(e, e.kit as CorsairKit, now, delta)
		i += 1
	_step_strikes(now)
	_step_grabs(now)


## One swimmer: surfacing, swimming along the hull, starting its strike.
func _step_swimmer(e: Enemy, k: CorsairKit, now: float, delta: float) -> void:
	e.untargetable = now >= k.surfaced_until
	if k.striking:
		return  # Holding at the hull while its strike is out (or its grab holds).
	k.swim_s = fposmod(k.swim_s + k.swim_dir * float(cfg["swim_speed"]) * delta, game.deck.perimeter_length)
	e.position = _swim_point(e, k.swim_s)
	e.velocity = Vector2.ZERO
	if now < k.next_strike:
		return
	var c := _c(e)
	var target := _target(e, String(c.get("type", "leap")), float(c["reach"]))
	if target == Vector2.INF:
		k.next_strike = now + 1.0  # Nothing in reach: look again in a second.
		return
	var s := game.deck.perimeter_s(target)
	k.swim_s = s
	e.position = _swim_point(e, s)
	k.striking = true
	var tel := float(CorsairRulesData.LEAP["telegraph"]) if String(c.get("type", "leap")) == "leap" else float(c["telegraph"])
	k.surfaced_until = now + tel + float(c["surface_time"])
	e.untargetable = false
	strikes.append({"type": String(c.get("type", "leap")), "owner": e, "gen": e.generation, "at": target, "land": now + tel, "c": c})
	game.stat_add("sea_strikes_" + String(c.get("type", "leap")), 1.0)
	if game.corsair != null:
		var ev := "shark_leap" if String(c.get("type", "")) == "leap" else "kraken_rise"
		if String(c.get("type", "")) == "climb":
			ev = "crab_climb"  # Act X, the Treasure Galleon: a hull crab climbs.
		game.corsair.play_sound(ev, e.position, 0.3)


## The point swimmer `e` strikes for a strike of `type`, or Vector2.INF.
func _target(e: Enemy, type: String, reach: float) -> Vector2:
	if type == "climb":
		return _climb_target(e, reach)  # Act X, the Treasure Galleon: the hull crab.
	var deck := game.deck
	var band := float(deck.cfg["rail_band"])
	var best := Vector2.INF
	var best_d := INF
	var any := Vector2.INF  # Fallback: nearest body in reach.
	var any_d := INF
	game.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
			continue
		var dist := u.position.distance_to(e.position)
		if dist > reach:
			continue
		var depth := deck.rail_depth(u.position)
		if type == "leap":
			if depth >= float(CorsairRulesData.LEAP["inset"]) and dist < best_d:
				best = u.position
				best_d = dist
		elif depth <= band and (type == "breach" or grabbable(u)) and dist < best_d:  # (Act X, the Maelstrom: a breach needs no grab)
			best = u.position
			best_d = dist
		if dist < any_d:
			any = u.position
			any_d = dist
	if best != Vector2.INF:
		return best
	if any != Vector2.INF and type != "leap":
		return any
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= reach:
			return pl.position
	return Vector2.INF


## True when summon `u` can be grabbed by a tentacle (see the header).
func grabbable(u: SummonedUnit) -> bool:
	if not u.active or u.airborne or u.flies or u.charmed or u.is_compelled():
		return false
	if u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
		return false
	if u.held_until > game.elapsed:
		return false
	return u.radius <= float(CorsairRulesData.TENTACLE["max_radius"])


## Lands every strike whose telegraph ran out.
func _step_strikes(now: float) -> void:
	var i := 0
	while i < strikes.size():
		var st := strikes[i]
		if now < float(st["land"]):
			i += 1
			continue
		strikes.remove_at(i)
		var owner: Enemy = st["owner"]
		var owned := owner != null and _alive(owner, int(st["gen"]))
		if owner != null and not owned:
			if String(st["type"]) == "mark":
				game.stat_add("sea_marks_failed", 1.0)  # Act X, the Treasure Galleon: the Voodoo Navigator died first.
			continue  # The swimmer died during its telegraph: the strike fizzles.
		_land(st, owner if owned else null, now)


## Strike `st` lands (see the header).
func _land(st: Dictionary, owner: Enemy, now: float) -> void:
	var c: Dictionary = st["c"]
	var at: Vector2 = st["at"]
	# --- Act X: the Maelstrom --- the Sea Serpent's breach sweeps its lane, not a circle.
	if String(st["type"]) == "breach" and owner != null and owner.kit is CorsairKit:
		_breach(owner, at, c)
		_end_strike(owner, owner.kit as CorsairKit, now)
		return
	var r := float(c["radius"])
	game.effects.ring(at, r, Palette.CORSAIR_FOAM, 0.3)
	_hit_circle(at, r, c, owner)
	var type := String(st["type"])
	if type == "mark":
		return  # Act X, the Treasure Galleon: a Voodoo Navigator's mark is a plain circle (its owner only cancels it).
	var k: CorsairKit = owner.kit as CorsairKit if owner != null else null
	if k == null:
		return
	if type == "leap":
		owner.position = game.deck.clamp_point(at, owner.radius)
		k.leave_water(owner)
		game.stat_add("sea_leaps_landed", 1.0)
		return
	if type == "climb":
		_climb_aboard(owner, k, at)  # Act X, the Treasure Galleon: the hull crab heaves itself over the rail.
		return
	if type == "tentacle":
		var u := _grab_target(at, r)
		if u != null:
			var hold := float(CorsairRulesData.TENTACLE["hold"])
			var rail: Array = game.deck.nearest_rail(owner.position)
			grabs.append([owner, owner.generation, u, u.generation, now, now + hold, u.position, (rail[0] as Vector2) - (rail[1] as Vector2) * 6.0])
			u.held_until = maxf(u.held_until, now + float(CorsairRulesData.TENTACLE["renew"]))
			game.combat.stun_unit(u, hold, CorsairRulesData.GRAB_SOURCE)
			k.surfaced_until = now + float(CorsairRulesData.TENTACLE["surfaced"])
			game.stat_add("sea_grabs", 1.0)
			if game.corsair != null:
				game.corsair.play_sound("tentacle_grab", u.position, 0.3)
			return  # It holds still at the hull until the grab ends (_step_grabs()).
	_end_strike(owner, k, now)


## The swimmer's strike is over: it submerges and swims on.
func _end_strike(swimmer: Enemy, k: CorsairKit, now: float) -> void:
	k.striking = false
	var c := _c(swimmer)
	k.next_strike = now + float(c["strike_every"]) * (1.0 + (randf() * 2.0 - 1.0) * float(c["strike_jitter"]))


## Everything inside the circle at `at` (radius `r`) is hit: summons and the
## necromancer x the damage scaling, deck enemies x the HP scaling. `skip` is spared.
func _hit_circle(at: Vector2, r: float, c: Dictionary, skip: Enemy) -> void:
	var dm := game.enemies.damage_mult
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(c["dmg_player"]) * dm, CorsairRulesData.STRIKE_SOURCE, pl)
			game.stat_add("sea_strike_hits_you", 1.0)
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(at) <= r + u.radius:
			game.combat.damage_unit(u, float(c["dmg_summon"]) * dm, CorsairRulesData.STRIKE_SOURCE)
			game.stat_add("sea_strike_hits_summons", 1.0)
	var hits: Array[Enemy] = []
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e.active and e != skip and not e.is_structure and not CorsairKit.is_in_water(e) and e.position.distance_to(at) <= r + e.radius:
			hits.append(e)
	var hp := game.enemies.hp_mult
	for e in hits:
		if e.active:
			game.stat_add("sea_strike_enemy_dmg", game.combat.damage_enemy(e, float(c["dmg_enemy"]) * hp, CorsairRulesData.STRIKE_SOURCE))


## The nearest grabbable summon inside the circle at `at` (radius `r`), or null.
func _grab_target(at: Vector2, r: float) -> SummonedUnit:
	var best: SummonedUnit = null
	var best_d := INF
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		var dist := u.position.distance_to(at)
		if dist <= r + u.radius and grabbable(u) and dist < best_d:
			best = u
			best_d = dist
	return best


## Carries every grab: the held summon is dragged toward the rail; a dead arm
## drops it (a rescue); a grab whose time is up drags it overboard.
func _step_grabs(now: float) -> void:
	var i := 0
	while i < grabs.size():
		var g: Array = grabs[i]
		var arm: Enemy = g[0]
		var u: SummonedUnit = g[2]
		if not u.active or u.generation != int(g[3]) or u.state == SummonedUnit.State.DEAD:
			grabs.remove_at(i)
			_free_arm(arm, int(g[1]), now)
			continue
		if not _alive(arm, int(g[1])):
			grabs.remove_at(i)
			_drop(u)
			continue
		if now >= float(g[5]):
			grabs.remove_at(i)
			game.stat_add("sea_dragged", 1.0)
			game.effects.ring(g[7], 16.0, Palette.CORSAIR_FOAM, 0.35)
			if game.corsair != null:
				game.corsair.play_sound("splash", g[7], 0.2)
			u.director.on_unit_died(u, false)  # Dragged overboard: gone until the next replenish.
			_free_arm(arm, int(g[1]), now)
			continue
		u.held_until = maxf(u.held_until, now + float(CorsairRulesData.TENTACLE["renew"]))
		var k := clampf((now - float(g[4])) / maxf(float(g[5]) - float(g[4]), 0.01), 0.0, 1.0)  # 0 at the grab .. 1 at the rail.
		u.position = (g[6] as Vector2).lerp(g[7], k)
		u.velocity = Vector2.ZERO
		i += 1


## The arm's grab ended: it submerges and swims on.
func _free_arm(arm: Enemy, gen: int, now: float) -> void:
	if _alive(arm, gen) and arm.kit is CorsairKit:
		_end_strike(arm, arm.kit as CorsairKit, now)


## RESCUE: summon `u` drops where it is (on the deck) with a short daze.
func _drop(u: SummonedUnit) -> void:
	var daze := float(CorsairRulesData.TENTACLE["drop_daze"])
	u.position = game.arena.free_point(u.position, u.radius)
	u.held_until = game.elapsed + daze
	u.stunned_until = minf(u.stunned_until, game.elapsed + daze)
	game.stat_add("sea_grab_rescues", 1.0)


## Every grab of `arm` ends as a rescue (CorsairRules.note_gone(): it died or was pooled).
func release_all(arm: Enemy) -> void:
	var i := 0
	while i < grabs.size():
		var g: Array = grabs[i]
		if g[0] == arm:
			var u: SummonedUnit = g[2]
			grabs.remove_at(i)
			if u.active and u.generation == int(g[3]) and u.state != SummonedUnit.State.DEAD:
				_drop(u)
			continue
		i += 1


## AN OWNERLESS STRIKE (the Black Tide's rail strikes; phase 2's serpent
## breach and the Voodoo Navigator's marks): a plain telegraphed circle at
## `at`, the SEA numbers with `overrides` (radius, telegraph, damage).
## Act X, the Treasure Galleon: with an `owner` (the Voodoo Navigator) it is
## her MARK (type "mark"): the same circle, cancelled if she dies before it lands.
func strike(at: Vector2, overrides: Dictionary = {}, owner: Enemy = null) -> void:
	var c := cfg.duplicate()
	for k: String in overrides:
		c[k] = overrides[k]
	var type := "sea" if owner == null else "mark"
	strikes.append({"type": type, "owner": owner, "gen": owner.generation if owner != null else 0, "at": at, "land": game.elapsed + float(c["telegraph"]), "c": c})
	game.stat_add("sea_strikes_" + type, 1.0)


## True while `e` is the same living enemy it was at generation `gen`.
static func _alive(e: Enemy, gen: int) -> bool:
	return e != null and e.active and e.generation == gen


## The autotest autopilot's push out of every telegraphed circle at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for st in strikes:
		if String(st["type"]) == "breach":
			push += _breach_push(st, p)  # Act X, the Maelstrom: out of the serpent's lane.
			continue
		var off: Vector2 = p - (st["at"] as Vector2)
		var reach := float((st["c"] as Dictionary)["radius"]) + game.player.radius + 18.0
		var d := off.length()
		if d < reach:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / reach) * 1.5
	return push


## The strike circles (a dark-water ring filling as it nears; a leap's shadow)
## and the grabbing arms' reach, on `ci` (CorsairRules; textures, visual only).
func draw(ci: CanvasItem) -> void:
	var t := game.elapsed
	var ring := CityGlyphs.ring_texture()
	for st in strikes:
		var c: Dictionary = st["c"]
		if String(st["type"]) == "breach":
			_draw_breach(ci, st, t)  # Act X, the Maelstrom: the serpent's lane.
			continue
		var r := float(c["radius"])
		var at: Vector2 = st["at"]
		var span := float(CorsairRulesData.LEAP["telegraph"]) if String(st["type"]) == "leap" else float(c["telegraph"])
		var k := clampf(1.0 - (float(st["land"]) - t) / maxf(span, 0.01), 0.0, 1.0)  # 0 -> 1 as it lands.
		SpriteBank.draw_disc(ci, at, r * (0.35 + 0.65 * k), Color(Palette.CORSAIR_INK, 0.25 + 0.3 * k))  # The dark water (a shadow for a leap).
		ci.draw_texture_rect(ring, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.CORSAIR_LANTERN, 0.5 + 0.4 * k))
	for g: Array in grabs:
		var arm: Enemy = g[0]
		var u: SummonedUnit = g[2]
		if _alive(arm, int(g[1])) and u.active:
			ci.draw_line(arm.position, u.position, Palette.CORSAIR_KRAKEN, 4.0)
			ci.draw_line(arm.position, u.position, Palette.CORSAIR_KRAKEN_LIGHT, 1.5)


# --- Act X: the Treasure Galleon ---
## THE CLIMB (the Hull Crab's strike type "climb"): the point in the rail band
## nearest its target (the nearest standing summon in the rail band, else the
## nearest summon or necromancer in `reach`), or Vector2.INF. The crab comes
## over the rail there.
func _climb_target(e: Enemy, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := INF
	game.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
			continue
		var dist := u.position.distance_to(e.position)
		if dist <= reach and dist < best_d:
			best = u.position
			best_d = dist
	if best == Vector2.INF:
		for pl in game.all_players:
			var dist := pl.position.distance_to(e.position)
			if not pl.dead and dist <= reach and dist < best_d:
				best = pl.position
				best_d = dist
	if best == Vector2.INF:
		return best
	var rail: Array = game.deck.nearest_rail(best)
	var depth := minf(float(CorsairRulesData.CLIMB["inset"]), maxf(game.deck.rail_depth(best), e.radius))
	return (rail[0] as Vector2) - (rail[1] as Vector2) * depth


## The climb lands: the crab stands on the deck in the rail band, an ordinary
## deck enemy from now on.
func _climb_aboard(owner: Enemy, k: CorsairKit, at: Vector2) -> void:
	owner.position = game.deck.clamp_point(at, owner.radius)
	k.leave_water(owner)
	game.stat_add("sea_climbs_landed", 1.0)
# =====================================================================================
# --- Act X: the Maelstrom --- the Sea Serpent's BREACH (strike type "breach")
# =====================================================================================

## The lane of a breach by `serpent` toward `at`: [from (its hull point), unit
## direction, length px] (CorsairRulesData.BREACH).
func _breach_lane(serpent_pos: Vector2, at: Vector2) -> Array:
	var dir := at - serpent_pos
	dir = dir.normalized() if dir.length() > 0.5 else Vector2.UP
	return [serpent_pos, dir, float(CorsairRulesData.BREACH["length"])]


## True when a body of radius `r` at `p` lies in the lane [from, dir, length].
static func _in_lane(lane: Array, p: Vector2, r: float) -> bool:
	var rel := p - (lane[0] as Vector2)
	var along := rel.dot(lane[1] as Vector2)
	if along < -r or along > float(lane[2]) + r:
		return false
	return absf(rel.dot((lane[1] as Vector2).orthogonal())) <= float(CorsairRulesData.BREACH["half_width"]) + r


## THE BREACH lands: the serpent's body sweeps its lane once, BOTH ARMIES (the
## strike's damage keys: summons and the necromancer x the damage scaling, deck
## enemies x the HP scaling), then it submerges (the caller ends the strike).
func _breach(serpent: Enemy, at: Vector2, c: Dictionary) -> void:
	var lane := _breach_lane(serpent.position, at)
	var dm := game.enemies.damage_mult
	var mid: Vector2 = (lane[0] as Vector2) + (lane[1] as Vector2) * float(lane[2]) * 0.5
	var reach := float(lane[2]) * 0.5 + float(CorsairRulesData.BREACH["half_width"])
	game.stat_add("sea_breaches", 1.0)
	game.effects.ring(mid, reach * 0.6, Palette.CORSAIR_SERPENT_LIGHT, 0.3)
	game.shake(1.5)
	if game.corsair != null:
		game.corsair.play_sound("serpent_breach", mid, 0.4)
	for pl in game.all_players:
		if not pl.dead and _in_lane(lane, pl.position, pl.radius):
			game.combat.damage_player(float(c["dmg_player"]) * dm, CorsairRulesData.STRIKE_SOURCE, pl)
			game.stat_add("sea_strike_hits_you", 1.0)
	game.ally_grid.query(mid, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and not u.airborne and _in_lane(lane, u.position, u.radius):
			game.combat.damage_unit(u, float(c["dmg_summon"]) * dm, CorsairRulesData.STRIKE_SOURCE)
			game.stat_add("sea_strike_hits_summons", 1.0)
			game.stat_add("sea_breach_hits", 1.0)
	var hits: Array[Enemy] = []
	game.enemy_grid.query(mid, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e.active and e != serpent and not e.is_structure and not CorsairKit.is_in_water(e) and _in_lane(lane, e.position, e.radius):
			hits.append(e)
	var hp := game.enemies.hp_mult
	for e in hits:
		if e.active:
			game.stat_add("sea_strike_enemy_dmg", game.combat.damage_enemy(e, float(c["dmg_enemy"]) * hp, CorsairRulesData.STRIKE_SOURCE))


## The autotest autopilot's push out of a telegraphed breach lane at `p`.
func _breach_push(st: Dictionary, p: Vector2) -> Vector2:
	var owner: Enemy = st["owner"]
	if owner == null or not _alive(owner, int(st["gen"])):
		return Vector2.ZERO
	var lane := _breach_lane(owner.position, st["at"])
	if not _in_lane(lane, p, game.player.radius + 16.0):
		return Vector2.ZERO
	var side := (lane[1] as Vector2).orthogonal()
	var off := (p - (lane[0] as Vector2)).dot(side)
	return side * (1.5 if off >= 0.0 else -1.5)


## A breach's telegraph on `ci`: the lane darkening as it nears, its edges in
## lantern amber (rects in the lane's frame; visual only).
func _draw_breach(ci: CanvasItem, st: Dictionary, t: float) -> void:
	var owner: Enemy = st["owner"]
	if owner == null or not _alive(owner, int(st["gen"])):
		return
	var c: Dictionary = st["c"]
	var k := clampf(1.0 - (float(st["land"]) - t) / maxf(float(c["telegraph"]), 0.01), 0.0, 1.0)  # 0 -> 1 as it lands.
	var lane := _breach_lane(owner.position, st["at"])
	var hw := float(CorsairRulesData.BREACH["half_width"])
	var length := float(lane[2])
	ci.draw_set_transform(lane[0], (lane[1] as Vector2).angle(), Vector2.ONE)
	ci.draw_rect(Rect2(Vector2(0.0, -hw), Vector2(length * (0.3 + 0.7 * k), hw * 2.0)), Color(Palette.CORSAIR_INK, 0.2 + 0.3 * k))
	ci.draw_rect(Rect2(Vector2(0.0, -hw), Vector2(length, 2.0)), Color(Palette.CORSAIR_LANTERN, 0.5 + 0.4 * k))
	ci.draw_rect(Rect2(Vector2(0.0, hw - 2.0), Vector2(length, 2.0)), Color(Palette.CORSAIR_LANTERN, 0.5 + 0.4 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
