## CityRules — the Last Line's shared rules (Act VIII; GDD §15.0 "Act VIII
## foundation (phase 1)", "Armour", "Supers", "Civilians" and "The
## escalation"), run as `Game.city`. Null on Acts I to VII (created in
## Game._ready() only for a stage whose STAGE has "city": true), except that a
## City kind forced onto any other stage with --spawn= creates it on its first
## activation through Game.city_rules() (CityKit.reset()), so a kind works
## anywhere (as the Act III to VII kinds do); there the escalation, the
## civilians' crowd and trickle and Martial Law stay off (`enabled` false: they
## read the STAGE "city" key) and only what the kind itself uses (its armour
## front, its vehicle, its Super kit) runs.
## Owns ONE path per rule:
##   escalation — Escalation: THE CLOCK (owner: "the escalation is a plain
##                clock"): the current tier for the HUD badge and the report,
##                the banner 10 s ahead, a Super every 90 s from the heroes.
##                The timeline itself spawns each tier's kinds.
##   armour     — Armour: THE FRONT (armour_mult(), called once from
##                CombatResolver.damage_enemy() after the Phalanx block) and the
##                Kevlar Bones hook (kevlar_mult(), once from damage_unit()).
##   convoy     — Convoy: THE VEHICLES' counters, wrecks and explosions (the
##                driving itself is the vehicle's CityKit: an enemy attack, not
##                a summon rule).
##   supers     — SuperRoster: the Supers' met list and call(); each Super is a
##                SuperKit (guarded / exposed, the plate, expose()).
##   civilians  — Civilians: the crowd at 0:00, the trickle until the army, the
##                fled / killed counts, their own alive cap.
##   shells     — CityShells: every telegraphed landing circle (the tank's
##                cannon, the breacher's flashbang, Martial Law's artillery).
##   martial    — MartialLaw: the shared Act VIII Reckoning (RECKONING
##                "martial_law"): artillery lines along the streets, the met
##                Supers return.
## Stepped by Game after the enemies (and the Court's rules) and before the
## obstacle push-out, so a civilian or a Super spawned this tick is pushed out
## of any building before it is drawn.
## Determinism: game time and the seeded gameplay RNG only, and only while it
## exists (Act VIII, or a forced City kind).
class_name CityRules
extends Node2D

## Owning run.
var game: Game
## True on an Act VIII stage (STAGE "city"): the escalation, the civilians and
## Martial Law may run; false when a forced City kind made the rules elsewhere.
var enabled: bool = false
## The escalation (the clock and the HUD badge).
var escalation: Escalation
## Armour (the fronts, the Kevlar hook).
var armour: Armour
## The vehicles' counters, wrecks and explosions.
var convoy: Convoy
## The Supers' roster (the met list).
var supers: SuperRoster
## The civilians.
var civilians: Civilians
## The landing circles (child node: drawn on the ground).
var shells: CityShells
## Martial Law (the Reckoning).
var martial: MartialLaw
## City kind -> game time (s) of its first activation this run (the
## autotest's "city kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}
## Scratch buffer for grid queries.
var _buf: Array = []


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "CityRules"
	enabled = bool(p_game.stage_def.get("city", false))
	escalation = Escalation.new(p_game, enabled)
	armour = Armour.new(p_game)
	convoy = Convoy.new(p_game)
	supers = SuperRoster.new(p_game)
	civilians = Civilians.new(p_game, enabled)
	shells = CityShells.new(p_game)
	add_child(shells)
	martial = MartialLaw.new(p_game, enabled)
	if p_game.arena != null and p_game.arena.city_blocks != null:
		_check_body_radii()


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## the clock, the civilians, the Supers' arrivals, the wrecks' explosions, the
## landing circles, Martial Law.
func step(delta: float) -> void:
	escalation.step(delta)
	civilians.step(delta)
	convoy.step(delta)
	shells.step(delta)
	martial.step(delta)


# =====================================================================================
# Hooks (CombatResolver, kits)
# =====================================================================================

## THE ARMOUR FRONT (CombatResolver.damage_enemy(), once, after the Phalanx
## block, only for a hit with an origin): the share of the hit on `e` from
## `origin` that lands (Armour.front_mult(); 1 = no front, a side or back hit,
## or an arcing hit from above).
func armour_mult(e: Enemy, origin: Vector2, shot: bool, source: String) -> float:
	return armour.front_mult(e, origin, shot, source)


## A City kind's enemy `e` was activated (CityKit.reset()): its first time is
## recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## Plays the sound of City event `event` (CityRulesData.SOUNDS) at `pos`, at
## most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(CityRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## True when the city's own blasts may hurt enemy `e`: never a civilian (owner
## brief: "never hit by the city's own forces"), never a boss or structure.
static func hits_enemy(e: Enemy) -> bool:
	return e.active and not e.civilian and not e.is_boss and not e.is_structure


## THE CITY BLAST: `dmg` (already scaled) to every summon and necromancer
## within `radius` px of `pos`, tagged `source`; with `both` also to every enemy
## there except civilians, bosses and structures (a wreck's explosion, the
## artillery: "hurting both sides"). Returns the bodies hit.
func blast(pos: Vector2, radius: float, dmg: float, source: String, both: bool) -> int:
	var hits := 0
	game.ally_grid.query(pos, radius + UnitData.MAX_BLOCK_RADIUS + 8.0, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if u.active and u.state != SummonedUnit.State.DEAD and u.position.distance_to(pos) <= radius + u.radius:
			game.combat.damage_unit(u, dmg, source)
			hits += 1
			game.stat_add("city_blast_hits_summons", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(pos) <= radius + pl.radius:
			game.combat.damage_player(dmg, source, pl)
			hits += 1
			game.stat_add("city_blast_hits_you", 1.0)
	if both:
		game.enemy_grid.query(pos, radius + CityBlockData.MAX_BODY_RADIUS, _buf)
		for e: Enemy in _buf.duplicate():
			if hits_enemy(e) and e.position.distance_to(pos) <= radius + e.radius:
				game.combat.damage_enemy(e, dmg, source)
				hits += 1
				game.stat_add("city_blast_hits_enemies", 1.0)
	return hits


## The autotest autopilot's push away from every live City telegraph at `p`:
## the vehicles' headlight lanes (Convoy) and the landing circles (CityShells).
func danger_push(p: Vector2) -> Vector2:
	return convoy.danger_push(p) + shells.danger_push(p)


## Stage-load check of the city blocks' one-lookup invariant
## (CityBlockData.MAX_BODY_RADIUS): push_error() for every kind the stage can
## spawn (its segments, events and Reckoning, its Supers) whose body is larger.
func _check_body_radii() -> void:
	var sd := game.stage_def
	var kinds: Dictionary = {}  # Kind id -> true.
	for seg: Dictionary in sd.get("segments", []):
		for k: String in (seg["weights"] as Dictionary):
			kinds[k] = true
	for ev: Dictionary in sd.get("events", []):
		for g: Dictionary in ev.get("groups", []):
			kinds[String(g["kind"])] = true
	var r: Dictionary = sd.get("reckoning", {})
	if r.has("kind"):
		kinds[String(r["kind"])] = true
	for c: Dictionary in r.get("companions", []):
		kinds[String(c["kind"])] = true
	for s: String in sd.get("supers", []):
		kinds[s] = true
	for k: String in kinds:
		var real := game.enemies.resolve_kind(k)
		if not EnemyDirector.is_known_kind(real):
			continue
		var rad := float(game.enemies.enemy_def(real)["radius"]) * EnemyData.ELITE_RADIUS_MULT
		if rad > CityBlockData.MAX_BODY_RADIUS:
			push_error("CityBlocks: kind %s (radius %.1f px as an elite) is larger than CityBlockData.MAX_BODY_RADIUS %.1f: the one-lookup invariant breaks" % [real, rad, CityBlockData.MAX_BODY_RADIUS])
