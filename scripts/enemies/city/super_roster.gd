## SuperRoster — the Last Line's SUPERS in play (Act VIII; GDD §15.0
## "Supers"; owner-approved proposal: "Named superheroes, each with one power
## and one weakness, both shown on their plate ... They are the act's elites
## and its bosses' allies"), owned by Game.city as `supers`. What it owns:
##   * THE MET LIST (`met`): every Super the run has met, alive or dead, in the
##     order met (phase 2's Paragon calls them to his side in Hope; Martial Law
##     brings them back at 0:00);
##   * call(id, at): THE way a Super is brought in (the escalation's heroes,
##     Martial Law, phase 2's bosses): spawned at a free point near `at`, its
##     arrival banner ("Blitz: Fast. Can't turn.") and sound;
##   * call_next(): the stage's next Super in turn (STAGE "supers", else
##     CityRulesData.SUPERS "roster") on the spawn ring around the necromancer;
##   * the living Supers (alive_count()) and the counters (arrived, exposed by
##     what, damage taken exposed and guarded; SuperKit reports them).
## Each Super is a SuperKit (guarded until its weakness is read, then exposed;
## its plate; expose()). Phase 2 adds Supers as rows plus kits.
## Determinism: the seeded gameplay RNG only (the arrival angle).
class_name SuperRoster
extends RefCounted

## Owning run.
var game: Game
## The Super ids the escalation sends here, in turn.
var roster: Array[String] = []
## Every Super id the run met (alive or dead), in the order met.
var met: Array[String] = []
## The living Supers (stale entries are dropped on each read).
var alive: Array[Enemy] = []
## Pool generation of each entry of `alive`.
var _gens: PackedInt32Array = PackedInt32Array()
## Index of the next roster Super call_next() sends.
var _next: int = 0
## Supers that arrived this run (any path).
var arrived: int = 0
## Weakness trigger -> times a Super was exposed by it.
var exposed_by: Dictionary = {}
## Damage Supers took while exposed (HP, SuperKit).
var dmg_exposed: float = 0.0
## Damage Supers took while guarded (HP, SuperKit).
var dmg_guarded: float = 0.0


## Builds the roster for `p_game`.
func _init(p_game: Game) -> void:
	game = p_game
	for id: String in p_game.stage_def.get("supers", CityRulesData.SUPERS["roster"]):
		roster.append(id)
	if roster.is_empty():
		for id: String in CityRulesData.SUPERS["roster"]:
			roster.append(id)


## THE CALL: brings Super `id` in at a free point near `at`; returns it (null
## when `id` is no known kind).
func call_super(id: String, at: Vector2) -> Enemy:
	if not EnemyDirector.is_known_kind(id):
		return null
	var row := game.enemies.enemy_def(id)
	return game.enemies.spawn_at(id, game.arena.free_point(at, float(row["radius"])), false)


## The stage's next Super in turn, on the spawn ring around the necromancer.
func call_next() -> Enemy:
	if roster.is_empty():
		return null
	var id := roster[_next % roster.size()]
	_next += 1
	return call_super(id, game.enemies.ring_point(randf() * TAU))


## A Super `e` was activated (SuperKit.reset(), whatever brought it): it joins
## the living and the met list; its arrival banner and sound.
func note_arrival(e: Enemy) -> void:
	_compact()
	alive.append(e)
	_gens.append(e.generation)
	arrived += 1
	game.stat_add("city_supers_arrived", 1.0)
	if not met.has(e.kind):
		met.append(e.kind)
	var sup: Dictionary = game.enemies.enemy_def(e.kind).get("super", {})
	game.enemies.show_banner("%s: %s %s" % [e.display_name, String(sup.get("power", "")), String(sup.get("weakness", ""))])
	game.city.play_sound("super_arrive", e.position, 0.5)
	if game.enemies.miniboss_alive() == null:
		game.enemies.set_miniboss(e)  # The HUD's miniboss bar shows the Super.


## A Super was exposed by `by` (SuperKit.expose()).
func note_exposed(by: String) -> void:
	exposed_by[by] = int(exposed_by.get(by, 0)) + 1


## Living Supers now.
func alive_count() -> int:
	_compact()
	return alive.size()


## Drops dead or recycled entries of `alive`.
func _compact() -> void:
	var i := alive.size() - 1
	while i >= 0:
		if not alive[i].active or alive[i].generation != _gens[i]:
			alive.remove_at(i)
			_gens.remove_at(i)
		i -= 1
