## Grace — GRACE, the Celestial Host's halos (temporary Act XIII; GDD §15.0
## "Grace"; proposal: "Every angel arrives wearing a halo that shrugs off the
## first hit from each kind of damage: each summon class and each spell is its
## own kind. An army of one class chips through halos one hit at a time; a
## mixed army and a full spell bar break them at once. One stat in
## CombatResolver.damage_enemy()"), owned by Game.host as `grace`.
##   * absorbs(): THE ONE READ, called once from CombatResolver.damage_enemy()
##     before every other modifier: a Host kind wearing a halo (HostKit.halo)
##     that has not yet shrugged off a hit of this hit's KIND (damage_kind():
##     the summon class through SynergyData.SOURCE_CLASS, so every attack,
##     volley and special of one class is one kind; any other source, a spell,
##     a DoT, an innate, is its own tag) shrugs it off: the hit deals 0, the
##     kind is remembered on the halo (HostKit.seen). Every later hit of that
##     kind lands in full. Works wherever a Host kind is (a forced --spawn=).
##   * step(): THE REGROWTH (the Dominion's: "their halos come back after
##     10 s"): every regrow_check s, every halo within a live regrower's
##     aura_radius (its row's regrow_radius when it has one: the Wheel of
##     Thrones' Dominion of the Spheres, "across the whole zone") that
##     shrugged nothing off for GRACE regrow s is whole again (its seen kinds
##     forgotten).
## Never touches the army: summons get no act-only rule. Determinism: game
## time only (no RNG).
class_name Grace
extends RefCounted

## Owning run.
var game: Game
## Grace's numbers (HostRulesData.GRACE, the stage's "grace" over it).
var cfg: Dictionary = {}
## Live regrowers (rows with "regrows": the Dominions), in activation order.
var regrowers: Array[Enemy] = []
## Halos that came down this run (a Host kind with "halo" activated).
var halos: int = 0
## Hits shrugged off this run.
var absorbed: int = 0
## Damage kind -> hits of it shrugged off (the report's top kinds).
var by_kind: Dictionary = {}
## Halos made whole again by a regrower.
var regrown: int = 0
## Seconds until the next regrowth check.
var _check_left: float = 0.0
## Enemy query buffer.
var _tmp: Array = []


## Builds Grace for `p_game`.
func _init(p_game: Game) -> void:
	game = p_game
	cfg = HostRulesData.GRACE.duplicate()
	var over: Dictionary = p_game.stage_def.get("grace", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]


## The damage KIND of a hit tagged `source`: its summon class
## (SynergyData.SOURCE_CLASS: every attack, volley and special of one class),
## else the tag itself (each spell, DoT and innate is its own kind).
static func damage_kind(source: String) -> String:
	return String(SynergyData.SOURCE_CLASS.get(source, source))


## THE ONE READ (CombatResolver.damage_enemy()): true when enemy `e`'s halo
## shrugs off this hit tagged `source` (the first of its kind on that halo).
func absorbs(e: Enemy, source: String) -> bool:
	var k := e.kit as HostKit
	if k == null or not k.halo:
		return false
	var kind := damage_kind(source)
	if k.seen.has(kind):
		return false
	k.seen[kind] = true
	k.last_absorb = game.elapsed
	absorbed += 1
	by_kind[kind] = int(by_kind.get(kind, 0)) + 1
	e.queue_redraw()
	game.host.play_sound("halo_absorb", e.position, 0.12)
	return true


## A Host kind's enemy `e` came down (HostRules.note_spawn()).
func note_spawn(e: Enemy, row: Dictionary) -> void:
	if bool(row.get("halo", false)):
		halos += 1
	if bool(row.get("regrows", false)) and not regrowers.has(e):
		regrowers.append(e)


## A Host kind's enemy `e` left the field (HostRules.note_gone()).
func note_gone(e: Enemy) -> void:
	regrowers.erase(e)


## Per tick (HostRules.step()): the regrowth check.
func step(delta: float) -> void:
	if regrowers.is_empty():
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = float(cfg["regrow_check"])
	var wait := float(cfg["regrow"])
	for r in regrowers:
		if not r.active:
			continue
		var reach := r.aura_radius  # px of the regrowth round him (his aura).
		if r.kit != null:
			reach = float(r.kit.d.get("regrow_radius", reach))  # The Wheel of Thrones' miniboss: the whole zone.
		game.enemy_grid.query(r.position, reach, _tmp)
		for e: Enemy in _tmp:
			if not e.active or e.position.distance_to(r.position) > reach:
				continue
			var k := e.kit as HostKit
			if k == null or k.seen.is_empty() or game.elapsed - k.last_absorb < wait:
				continue
			k.seen.clear()
			regrown += 1
			e.queue_redraw()
			game.host.play_sound("halo_regrow", e.position, 0.5)
