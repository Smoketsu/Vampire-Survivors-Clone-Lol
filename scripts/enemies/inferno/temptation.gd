## Temptation — TEMPTATION, the third of the Inferno's shared rules (Act VI; GDD
## §15.0 "Temptation"; owner-approved proposal: "Succubi and lilim charm
## summons: a charmed summon (pink hearts over it) fights for hell for 6 s, then
## comes back. One path, HordeDirector.charm(), built on Act II's Claims
## pattern, capped at 3 charmed at once. Counters: kill the charmer and its
## charms break; Faithless shortens them"), owned by Game.inferno. Reached
## ONLY through HordeDirector.charm() / break_charms() (the one path):
##   * charm(u, by, duration, opts): summon `u` is PARKED (SummonedUnit
##     .set_charmed(true): hidden, out of the ally grid and the ring, it neither
##     thinks nor steps, damage_unit() ignores it), and a hostile body of kind
##     TEMPTATION kind (InfernoEnemyData "charmed", a CharmedKit) rises where it
##     stood, wearing its art tinted pink with hearts over it (the Claims
##     pattern: Enemy.wears, like Act II's Drowned Thrall). The body has the
##     summon's HP and body, the row's time-scaled hit damage, and fights
##     through the shared melee AI: it attacks summons and the necromancer
##     through the normal combat paths (damage tagged "charmed"), and the army,
##     the spells and the volleys fight it like any foe.
##   * The charm ENDS after `duration` s (x Faithless): the body leaves
##     without a kill and the summon comes back where it stands, with the
##     body's share of HP (at least TEMPTATION return_min).
##   * BROKEN when the charmer dies (break_by(), from InfernoKit.on_killed()):
##     the same return, at once.
##   * FREED when the body is broken (killed by the army, the spells, the
##     necromancer): the charm breaks and the summon comes back at once with
##     TEMPTATION return_min of its HP (own decision, GDD §15.0 "Temptation":
##     a first pass that killed the summon lost 93 summons in one stub run, the
##     army breaking its own comrades; freeing it makes hitting the body a
##     counter, like killing the charmer). The body gives no XP (row xp 0).
##   * At most TEMPTATION max_charmed at once, every army together (refused
##     beyond it unless opts "ignore_cap"); the necromancer cannot be charmed
##     (only a SummonedUnit can). In co-op a charmed summon stays in its owner's
##     army (its slot) and comes back to it.
##   * FAITHLESS hook (the future Act VI counter-passive; not built in phase
##     1): faithless_mult() shortens the charm (exactly 1 while the passive does
##     not exist).
## An enemy effect on a unit, like Act II's Claims: summons get no act rule.
## Determinism: no RNG; records in a fixed order, bodies guarded by their
## pooling generation. Stats: charm_charms, charm_refused_cap, charm_refused,
## charm_expired, charm_broken, charm_freed, charm_by_<charmer kind>,
## charm_class_<summon class>.
class_name Temptation
extends RefCounted

## One charmed summon.
class Charm:
	extends RefCounted
	## The parked summon.
	var unit: SummonedUnit = null
	## Its generation when charmed (stale guard).
	var unit_gen: int = 0
	## The hostile body fighting in its place.
	var body: Enemy = null
	## The body's generation (stale guard).
	var body_gen: int = 0
	## The charmer (null for a boss effect with no charmer).
	var by: Enemy = null
	## The charmer's generation (stale guard).
	var by_gen: int = 0
	## Game time (s) the charm ends.
	var until: float = 0.0
	## True once the body was broken (CharmedKit.on_killed()): the summon is freed.
	var killed: bool = false
	## Last world position of the body (the summon comes back there).
	var at: Vector2 = Vector2.ZERO


## Owning run.
var game: Game
## Charms held now (in the order they were made).
var charms: Array[Charm] = []
## Charms made this run.
var made: int = 0
## Most summons charmed at once this run.
var peak: int = 0
## Charms broken by the charmer's death.
var broken: int = 0
## Charms that ran their time out.
var expired: int = 0
## Summons freed by breaking their body (it was killed while charmed).
var freed: int = 0
## Charms refused at the max_charmed cap.
var refused_cap: int = 0


func _init(p_game: Game) -> void:
	game = p_game


## FAITHLESS (the future Act VI counter-passive; the one read): the share of a
## charm's duration summon `u` still serves hell, 1 - PassiveData row
## FAITHLESS's value of the player who owns it (co-op: its army's slot).
## Exactly 1 while the passive does not exist.
func faithless_mult(u: SummonedUnit) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return clampf(1.0 - ab.passive_value(InfernoRulesData.FAITHLESS, InfernoRulesData.FAITHLESS_KEY), 0.0, 1.0)


## Charmed summons right now.
func charmed_now() -> int:
	return charms.size()


## True while summon `u` is charmed.
func is_charmed(u: SummonedUnit) -> bool:
	return u != null and u.charmed


## Charms `u` for `duration` s (see the header; HordeDirector.charm() is the
## only caller). Returns true when it took hold.
func charm(u: SummonedUnit, by: Enemy, duration: float, opts: Dictionary = {}) -> bool:
	var t: Dictionary = InfernoRulesData.TEMPTATION
	if u == null or not u.active or u.charmed or u.is_temporary and bool(opts.get("no_temporary", false)):
		game.stat_add("charm_refused", 1.0)
		return false
	if charms.size() >= int(t["max_charmed"]) and not bool(opts.get("ignore_cap", false)):
		refused_cap += 1
		game.stat_add("charm_refused_cap", 1.0)
		return false
	var at := u.position
	if not u.set_charmed(true, at):
		game.stat_add("charm_refused", 1.0)
		return false
	var e := game.enemies.spawn_at(String(t["kind"]), at, false)
	if e == null:
		u.set_charmed(false, at)
		return false
	var row: Dictionary = game.enemies.enemy_def(String(t["kind"]))  # Floors of the body's stats.
	e.max_hp = maxf(1.0, u.max_hp)
	e.hp = clampf(u.hp, 1.0, e.max_hp)
	e.move_speed = maxf(float(row["move_speed"]), u.move_speed * float(t["speed_mult"]))
	e.radius = u.radius
	e.is_objective = true  # Never recycled: the charm decides when it leaves.
	var look := u.glyph_kind if u.glyph_kind != "" else u.unit_class  # The summon's art key (an evolved form has its own).
	e.wears = "summons/" + look
	e.wears_class = look
	e.wear_tint = opts.get("tint", t["tint"])
	e.display_name = String(opts.get("name", "Charmed " + String(UnitData.UNITS[u.unit_class].get("display_name", u.unit_class))))
	e.queue_redraw()
	var c := Charm.new()
	c.unit = u
	c.unit_gen = u.generation
	c.body = e
	c.body_gen = e.generation
	c.by = by
	c.by_gen = by.generation if by != null else 0
	c.until = game.elapsed + maxf(0.1, duration * faithless_mult(u))
	c.at = at
	charms.append(c)
	if e.kit is CharmedKit:
		(e.kit as CharmedKit).charm_ends = c.until
	made += 1
	peak = maxi(peak, charms.size())
	game.stat_add("charm_charms", 1.0)
	game.stat_add("charm_by_" + String(opts.get("source", by.kind if by != null else "boss")), 1.0)
	game.stat_add("charm_class_" + u.unit_class, 1.0)
	game.effects.spawn_ring(at, Palette.INFERNO_CHARM)
	if game.inferno != null:
		game.inferno.play_sound("charm_kiss", at)
	return true


## Breaks every charm charmer `by` holds (its summons come back at once).
## Returns the summons freed.
func break_by(by: Enemy) -> int:
	var n := 0
	var i := 0
	while i < charms.size():
		var c := charms[i]
		if c.by == by and c.by_gen == by.generation:
			_end(c, "broken")
			charms.remove_at(i)
			n += 1
			continue
		i += 1
	return n


## The body `e` of a charm was killed (CharmedKit.on_killed()): its summon is freed.
func on_body_killed(e: Enemy) -> void:
	for c in charms:
		if c.body == e and c.body_gen == e.generation:
			c.killed = true
			c.at = e.position


## Per-tick update (InfernoRules.step()): the parked summons follow their
## bodies; charms end on time, on a dead body or a vanished summon.
func step(_delta: float) -> void:
	var i := 0
	var now := game.elapsed
	while i < charms.size():
		var c := charms[i]
		var u := c.unit
		if not u.active or u.generation != c.unit_gen:
			_drop_body(c)  # The summon left the field some other way (a merge): the body goes too.
			charms.remove_at(i)
			continue
		var body_ok := c.body.active and c.body.generation == c.body_gen
		if body_ok:
			c.at = c.body.position
			u.position = c.at  # Parked where its body fights (it comes back there).
		if c.killed or not body_ok:
			_end(c, "freed" if c.killed else "expired")
			charms.remove_at(i)
			continue
		if now >= c.until:
			_end(c, "expired")
			charms.remove_at(i)
			continue
		i += 1


## Ends charm `c`: the summon comes back with its body's share of HP ("freed":
## the body was broken, so at TEMPTATION return_min of it).
func _end(c: Charm, how: String) -> void:
	var u := c.unit
	var frac := 0.0  # Share of its max HP it comes back with (floored at return_min).
	var body_ok := c.body.active and c.body.generation == c.body_gen
	if body_ok:
		frac = c.body.hp / maxf(c.body.max_hp, 1.0)
		c.at = c.body.position
	u.set_charmed(false, c.at)
	match how:
		"freed":
			freed += 1
			game.stat_add("charm_freed", 1.0)
		"broken":
			broken += 1
			game.stat_add("charm_broken", 1.0)
		_:
			expired += 1
			game.stat_add("charm_expired", 1.0)
	u.hp = clampf(u.max_hp * frac, u.max_hp * float(InfernoRulesData.TEMPTATION["return_min"]), u.max_hp)
	_drop_body(c)
	game.effects.spawn_ring(c.at, Palette.INFERNO_CHARM_LIGHT)
	if game.inferno != null:
		game.inferno.play_sound("charm_break", c.at)


## Takes charm `c`'s body off the field without a kill (no XP, no drops).
func _drop_body(c: Charm) -> void:
	if c.body.active and c.body.generation == c.body_gen:
		game.enemies.despawn(c.body)
