## CorsairRules — the Black Tide's shared rules (Act X, the pirate act's
## temporary number until the reorder moves it to slot II; GDD §15.0 "Act X
## foundation: the Black Tide (phase 1)", "Boarding", "The Deck", "Strikes from
## the Sea" and "The Black Tide"), run as `Game.corsair`. Null on Acts I to IX
## (created in Game._ready() only for a stage whose STAGE has "corsair": true),
## except that a Black Tide kind forced onto any other stage with --spawn=
## creates it on its first activation through Game.corsair_rules()
## (CorsairKit.reset()); there `enabled` is false: no deck, no boats, no sea,
## no Black Tide, and routes() is false (the timeline spawns at the ring as
## usual).
## Owns ONE path per rule:
##   deck     — DeckBounds (also Game.deck): THE BOUNDS PATH (the clamp in
##              Arena.resolve_all(), the drowning, the fliers' band, the ring
##              posts' walkable_point(), the camera clamp).
##   boarding — BoardingParty: THE ONLY SPAWN ROUTE of the timeline on a
##              corsair stage (route_spawn() below hands it every crew spawn):
##              boats with lanes, hooks, the pour, repel and sink, the capped
##              queue, the pooled boats (cap 4).
##   sea      — SeaStrikes: THE STRIKES (the swimmers' scheduler: leaps,
##              tentacles, surfacing, at most 8 swimmers; strike() for phase 2).
##   tide     — BlackTide: the shared Act X Reckoning (RECKONING "black_tide"):
##              the whole rail boards, the rail band is struck every 3 s, a
##              great wave every 20 s.
## Hooks for the future counter-passives (exactly 1 today): sea_legs_mult()
## (Sea Legs: the army ignores part of a drift or a pull) and barnacle_mult()
## (Barnacle Bones: summon hits on boats, hooks and swimmers).
## Stepped by Game after the enemies (and the Concord's rules) and before the
## obstacle push-out (whose last step is the deck clamp). Draws the boats'
## lanes and ropes, the strike circles and the wave on one node (z -5: on the
## deck and the sea, under every body).
## Determinism: game time and the seeded gameplay RNG only (the boats' lanes,
## the swimmers' places and strike jitter, the wave's side), and only while it
## exists (Act X, or a forced Black Tide kind).
class_name CorsairRules
extends Node2D

## Owning run.
var game: Game
## True on an Act X stage (STAGE "corsair" with a "deck"): the deck, the boats,
## the sea and the Black Tide run; false when a forced kind made the rules elsewhere.
var enabled: bool = false
## The deck (DeckBounds; also Game.deck; null when not enabled).
var deck: DeckBounds = null
## Boarding (the boats, the queue).
var boarding: BoardingParty
## Strikes from the Sea (the swimmers).
var sea: SeaStrikes
## The Black Tide (the Reckoning).
var tide: BlackTide
## Black Tide kind -> game time (s) of its first activation this run (the
## autotest's "corsair kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}
## Act X, the Treasure Galleon: grenadoes in the air (lob()): each {at, land
## (game s), keg}; they burst through powder_blast() even if their thrower
## fell (a thrown grenado is out of her hands).
var _lobs: Array[Dictionary] = []


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "CorsairRules"
	enabled = bool(p_game.stage_def.get("corsair", false)) and p_game.stage_def.has("deck")
	if enabled:
		deck = DeckBounds.new(p_game, p_game.stage_def.get("deck", {}))
		p_game.deck = deck
	boarding = BoardingParty.new(p_game, enabled)
	sea = SeaStrikes.new(p_game, enabled)
	tide = BlackTide.new(p_game, enabled)


func _ready() -> void:
	z_index = -5  # On the deck and the sea (-10), over the furniture (-6), under every body.


## Per-tick update (Game, after the enemies, before the obstacle push-out): the
## Black Tide's clock, the boats, the swimmers and their strikes.
func step(delta: float) -> void:
	if not enabled:
		return
	tide.step(delta)
	boarding.step(delta)
	sea.step(delta)
	_step_lobs()
	queue_redraw()


# =====================================================================================
# The spawn route (EnemyDirector)
# =====================================================================================

## True when the timeline's spawns go through route_spawn() (an Act X stage).
func routes() -> bool:
	return enabled


## THE ONE SPAWN ROUTE of a corsair stage (EnemyDirector's trickle, wave events
## and Reckoning call it instead of spawning at the ring): a swimmer kind (row
## "water") comes from the sea (SeaStrikes.spawn_swimmer(); refused at the
## swimmer cap), every other kind waits in BoardingParty's queue and comes
## aboard by boat. `hp_scale` is the director's HP scaling at the request;
## `dmg_scale` and `reckoning` the Reckoning's; `promoted` a trickle elite
## promoted by the difficulty (base XP).
func route_spawn(kind: String, hp_scale: float, elite: bool, dmg_scale: float, reckoning: bool, promoted: bool) -> void:
	var row := game.enemies.enemy_def(kind)
	if bool(row.get("gunboat", false)):
		GunboatKit.launch(game, hp_scale, dmg_scale, reckoning)  # Act X, the Treasure Galleon: a gunboat comes alongside (never boards).
		return
	if bool(row.get("water", false)):
		sea.spawn_swimmer(kind, hp_scale, elite, dmg_scale, reckoning)
		return
	boarding.enqueue(kind, hp_scale, elite, dmg_scale, reckoning, promoted)


## EnemyDirector.regular_alive()'s correction: the crew waiting in the queue and
## aboard the boats count as alive (the budget is spent when the timeline asks),
## the boats and hooks do not (they are the door, not the crew).
func alive_adjust() -> int:
	return boarding.waiting() - boarding.structures_alive()


# =====================================================================================
# Hooks (kits)
# =====================================================================================

## A Black Tide kind's enemy `e` was activated (CorsairKit.reset()): its first
## time is recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## A Black Tide kind's enemy `e` left the field (CorsairKit.on_deactivate()):
## a tentacle lets go of what it holds.
func note_gone(e: Enemy) -> void:
	sea.release_all(e)


## Plays the sound of Black Tide event `event` (CorsairRulesData.SOUNDS) at
## `pos`, at most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(CorsairRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## THE POWDER BLAST (the Powder Runner's keg; phase 2's powder barrels and
## grenadoes may call it): everything within `keg` radius of `at` is hit, both
## sides, and knocked `keg` push px outward: enemies through their knockback
## (so a blast at the rail tips them overboard: DeckBounds), the necromancer
## and the army through TerrainSlow's push (they stop at the rail). `skip` is
## spared (the runner himself). Damage x the enemies' damage scaling (summons,
## necromancer) or HP scaling (enemies).
func powder_blast(at: Vector2, keg: Dictionary, skip: Enemy = null) -> void:
	var r := float(keg["radius"])
	var push := float(keg["push"])
	var v := sqrt(2.0 * EnemyData.KNOCKBACK_DECAY * push)  # px/s that carries an enemy `push` px.
	var dm := game.enemies.damage_mult
	game.stat_add("powder_blasts", 1.0)
	game.effects.impact(at, r, Palette.CORSAIR_LANTERN)
	game.shake(2.0)
	play_sound("powder_blast", at, 0.1)
	for pl in game.all_players:
		var off := pl.position - at
		if off.length() <= r + pl.radius:
			game.combat.damage_player(float(keg["dmg_player"]) * dm, CorsairRulesData.POWDER_SOURCE, pl)
			if not game.grave_step.is_dashing() and not pl.dead:
				pl.position += (off.normalized() if off.length() > 0.01 else Vector2.UP) * push
	var tmp: Array = []
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		var off := u.position - at
		if u.active and off.length() <= r + u.radius:
			game.combat.damage_unit(u, float(keg["dmg_summon"]) * dm, CorsairRulesData.POWDER_SOURCE)
			TerrainSlow.push_summon(game, u, (off.normalized() if off.length() > 0.01 else Vector2.UP) * push * sea_legs_mult(u), 1.0)
	var hits: Array[Enemy] = []
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, tmp)
	for e: Enemy in tmp:
		if e.active and e != skip and not CorsairKit.is_in_water(e) and e.position.distance_to(at) <= r + e.radius:
			hits.append(e)
	var hp := game.enemies.hp_mult
	for e in hits:
		if not e.active:
			continue
		var off := e.position - at
		if not (e.is_boss or e.is_structure or e.is_miniboss):
			e.knockback += (off.normalized() if off.length() > 0.01 else Vector2.UP) * v / maxf(e.mass, 0.1)
		game.stat_add("powder_enemy_dmg", game.combat.damage_enemy(e, float(keg["dmg_enemy"]) * hp, CorsairRulesData.POWDER_SOURCE))


## The autotest autopilot's push away from every live Black Tide telegraph at
## `p`: the rail (DeckBounds: stay mid-deck), the strike circles (SeaStrikes)
## and the wave's far rail (BlackTide).
func danger_push(p: Vector2) -> Vector2:
	if not enabled:
		return Vector2.ZERO
	var push := deck.danger_push(p) + sea.danger_push(p) + tide.danger_push(p)
	# --- Act X: the Smuggler's Cutter --- off the ram longboat's point while its lane shows.
	if game.enemies.cutter != null:
		push += game.enemies.cutter.danger_push(p)
	push += lob_danger(p)  # Act X, the Treasure Galleon: out of the grenadoes' landing circles.
	if game.enemies.galleon != null:
		push += game.enemies.galleon.danger_push(p)  # Act X, the Treasure Galleon: out of the broadside lanes.
	# --- Act X: the Maelstrom --- the Heave: lean uphill, off the low rail.
	if game.enemies.maelstrom != null:
		push += game.enemies.maelstrom.danger_push(p)
	return push


# =====================================================================================
# Counter-passive hooks (Sea Legs, Barnacle Bones: not built in phase 1)
# =====================================================================================

## SEA LEGS (hook): x the drift / pull summon `u` takes (1 - the passive's
## drift_cut of the player who owns it; co-op: its army's slot). Exactly 1
## while the passive does not exist. Read by the powder push (phase 1), the
## Heave and the Grappler's pull (phase 2).
func sea_legs_mult(u: SummonedUnit = null) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return clampf(1.0 - ab.passive_value(CorsairRulesData.SEA_LEGS, CorsairRulesData.SEA_LEGS_KEY), 0.0, 1.0)


## BARNACLE BONES (hook): x a summon's hit on a boat, a hook or a swimmer (1 +
## the bound player's sea_damage). Exactly 1 while the passive does not exist.
func barnacle_mult() -> float:
	return 1.0 + game.abilities.passive_value(CorsairRulesData.BARNACLE_BONES, CorsairRulesData.BARNACLE_KEY)


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## The boats' lanes, lanterns and ropes, the strike circles and the wave.
func _draw() -> void:
	if not enabled:
		return
	boarding.draw(self)
	sea.draw(self)
	tide.draw(self)


# --- Act X: the Treasure Galleon ---
## A GRENADO is thrown (the Gunnery Mate's lob, GunneryMateKit): it bursts at
## `at` after `flight` s through THE POWDER BLAST with `keg`'s numbers, its
## landing circle telegraphed until then. Off Act X it bursts too (the rules
## step only on a deck stage, so there the kit bursts it itself).
func lob(at: Vector2, flight: float, keg: Dictionary) -> void:
	_lobs.append({"at": at, "land": game.elapsed + flight, "keg": keg})
	game.effects.telegraph_circle(at, float(keg.get("radius", 46.0)), flight)


## Bursts every grenado whose flight ended.
func _step_lobs() -> void:
	var i := 0
	while i < _lobs.size():
		var g: Dictionary = _lobs[i]
		if game.elapsed < float(g["land"]):
			i += 1
			continue
		_lobs.remove_at(i)
		powder_blast(g["at"], g["keg"], null)
		game.stat_add("gunnery_grenadoes", 1.0)


## The autotest bot's push out of every grenado's landing circle at `p`.
func lob_danger(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for g in _lobs:
		var reach := float((g["keg"] as Dictionary).get("radius", 46.0)) + 18.0
		var off: Vector2 = p - (g["at"] as Vector2)
		var d := off.length()
		if d < reach:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / reach) * 2.0
	return push
