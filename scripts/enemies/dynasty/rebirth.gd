## Rebirth — REBIRTH, the headline rule of the Necropolis Dynasty (temporary Act
## XII; GDD §15.0 "Rebirth"; owner-approved proposal: "When a mummy or a
## guardian falls, a gold cartouche floats over the corpse for 6 s. If it is
## not raised in that time, or smashed (one hit from any source), the body
## returns at 70% HP with a +20% damage stamp (at most twice per body).
## Raising it with HordeDirector.raise_corpse() steals the Name ... Embalmers
## speed the timer. Canopic Jars (structures) hold the Names of every body
## within 300 px: break the jar and its bodies return no more ... Scarabs and
## animals do not return"), owned by Game.dynasty. THE one path of every Name:
##   * on_death(e): called ONCE from the kill path (CombatResolver
##     .damage_enemy() -> DynastyRules.on_enemy_died(), before the raise
##     paths). A body whose row has "rebirth", that is no boss or miniboss
##     and leaves a corpse (Enemy.leaves_corpse(), the one corpse gate), with
##     returns left (REBIRTH max_returns; no limit in the Devourer's Hour),
##     gets a CARTOUCHE: a 1-hit structure enemy (DynastyEnemyData
##     "cartouche", CartoucheKit) where it fell. Past max_cartouches the body
##     simply stays dead (counted).
##   * THE TIMER (CartoucheKit): REBIRTH duration s, x embalm_speed while an
##     Embalmer stands near it (DynastyRules.embalm_rate()); then return_body():
##     the cartouche goes and the body stands again (EnemyDirector.spawn_at(),
##     the same kind and elite flag) at return_hp of its max HP, its returns
##     one higher (Enemy.reborn: Enemy.hit_mult() multiplies its every hit by
##     damage_mult per return).
##   * THE RAISE (on_raise(), from HordeDirector.raise_corpse(), the one raise
##     path): the nearest cartouche within steal_radius of the raise is
##     STOLEN: it goes without a return (the raise itself makes the
##     necromancer's summon). Raising is the counter, sealed or not.
##   * THE SMASH (smash(), from CombatResolver.damage_enemy() before the kill
##     path): any hit that reaches a cartouche (its HP is CARTOUCHE_HP) ends
##     it WITHOUT a kill (no XP, drop or kill count).
##   * THE JARS: a cartouche laid within jar_radius of a live Canopic Jar is
##     SEALED by it: untargetable (Enemy.untargetable: no hit reaches it, so
##     only a raise or the jar's fall stops it). When the jar falls, every
##     cartouche it seals crumbles at once (its body returns no more). On a
##     stage with "jars_required" only a sealed body gets a cartouche. The
##     stubs raise their own jars on a clock (JARS); place_jar(at) is THE
##     public call for phase 2 (jars beside the tombs).
##   * The Devourer's Hour: unlimited (no return limit) and eat() (a lane eats
##     a cartouche: no return).
## Drawing: the cartouches and jars are enemies and draw themselves
## (CartoucheKit, CanopicJarKit). Determinism: game time and the seeded
## gameplay RNG (the stub jars' points), only while the rules exist. Stats:
## rebirth_* (the report's "rebirth" line).
class_name Rebirth
extends RefCounted

## Owning run.
var game: Game
## True on a Dynasty stage: the stub jars may rise (JARS "every" > 0).
var enabled: bool = false
## Rebirth's numbers (REBIRTH with the STAGE's "rebirth").
var cfg: Dictionary = {}
## The stub jars' numbers (JARS with the STAGE's "jars").
var jars_cfg: Dictionary = {}
## Live cartouches (enemies of kind "cartouche"), in laying order.
var cartouches: Array[Enemy] = []
## Live Canopic Jars (rows with "holds_names"), in activation order.
var jars: Array[Enemy] = []
## True in the Devourer's Hour: a body returns without limit.
var unlimited: bool = false
## Game time (s) the next stub jar starts rising (INF = none).
var _next_jar: float = INF
## Stub jars rising: [at (Vector2), game time it stands (float)].
var _rising: Array = []

# --- Counters (the report) -----------------------------------------------------------------
## Bodies with "rebirth" that fell.
var fallen: int = 0
## Cartouches laid.
var laid: int = 0
## Of those, sealed by a jar.
var sealed: int = 0
## Bodies that returned, by their new return count: [first, second, later].
var returned: Array[int] = [0, 0, 0]
## Cartouches stolen by a raise.
var stolen: int = 0
## Cartouches smashed, by who: "spell", "summon", "other".
var smashed: Dictionary = {}
## Cartouches that crumbled when their jar fell.
var crumbled: int = 0
## Cartouches the Devourer ate.
var eaten: int = 0
## Bodies refused: out of returns.
var spent: int = 0
## Bodies refused: the cartouche cap.
var capped: int = 0
## Bodies refused: no jar held them (jars_required).
var unheld: int = 0
## Most cartouches at once.
var peak: int = 0
# --- Act XII (temporary number): the Necropolis of Sand ---
## True during Anubis's PROCESSION (set_procession()): every live jar holds
## every Name on the map and only a held body gets a cartouche.
var procession: bool = false
## Jars that stood up (stub clock and place_jar()).
var jars_placed: int = 0
## Jars broken.
var jars_broken: int = 0


## Builds Rebirth for `p_game`; `p_enabled`: a Dynasty stage (the stub jars).
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = DynastyRulesData.REBIRTH.duplicate()
	var over: Dictionary = p_game.stage_def.get("rebirth", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	jars_cfg = DynastyRulesData.JARS.duplicate()
	var jover: Dictionary = p_game.stage_def.get("jars", {})  # The stage's own jar clock.
	for key: String in jover:
		jars_cfg[key] = jover[key]
	if enabled and float(jars_cfg["every"]) > 0.0:
		_next_jar = float(jars_cfg["first"])


# =====================================================================================
# Public API
# =====================================================================================

## THE CARTOUCHE (see the header): enemy `e` was killed.
func on_death(e: Enemy) -> void:
	if not (e.kit is DynastyKit):
		return
	var k := e.kit as DynastyKit
	if not bool(k.d.get("rebirth", false)) or e.is_boss or e.is_miniboss or not e.leaves_corpse():
		return
	fallen += 1
	if k.returns >= int(cfg["max_returns"]) and not unlimited:
		spent += 1
		return
	if cartouches.size() >= int(cfg["max_cartouches"]):
		capped += 1
		return
	var jar := jar_near(e.position)  # The jar that holds this Name (null = none).
	if (bool(cfg["jars_required"]) or procession) and jar == null:
		unheld += 1
		return
	var c := game.enemies.spawn_at(DynastyRulesData.CARTOUCHE, e.position, false)
	if c == null or not (c.kit is CartoucheKit):
		return
	(c.kit as CartoucheKit).setup(c, e.kind, e.is_elite, k.returns, jar)
	cartouches.append(c)
	laid += 1
	if jar != null:
		sealed += 1
	peak = maxi(peak, cartouches.size())
	game.dynasty.play_sound("cartouche", e.position, 0.25)


## THE RAISE (HordeDirector.raise_corpse(), the one raise path): a raise at
## `pos` steals the Name of the nearest cartouche within steal_radius. True
## when one was stolen.
func on_raise(pos: Vector2) -> bool:
	var best: Enemy = null
	var best_d := float(cfg["steal_radius"])
	for c in cartouches:
		if not c.active:
			continue
		var d := c.position.distance_to(pos)
		if d <= best_d:
			best_d = d
			best = c
	if best == null:
		return false
	stolen += 1
	game.stat_add("rebirth_stolen", 1.0)
	game.effects.pop(best.position, Palette.NECRO_GREEN, best.radius * 2.2)
	game.dynasty.play_sound("name_stolen", best.position, 0.2)
	_remove(best)
	return true


## THE SMASH (CombatResolver.damage_enemy(), before the kill path, only while
## Game.dynasty exists): when `e` is a cartouche brought to 0 HP by a hit
## tagged `source`, it leaves the field WITHOUT a kill and true is returned;
## false for anything else (the kill path then runs as usual).
static func smash(g: Game, e: Enemy, source: String) -> bool:
	if e.kind != DynastyRulesData.CARTOUCHE:
		return false
	var by := "other"  # Who smashed it (the report).
	if HundredShadowsData.is_spell_source(source):
		by = "spell"
	elif g.combat.is_minion_source(source):
		by = "summon"
	var rb := g.dynasty.rebirth
	rb.smashed[by] = int(rb.smashed.get(by, 0)) + 1
	g.stat_add("rebirth_smashed", 1.0)
	g.effects.pop(e.position, Palette.DYN_BRONZE_DARK, e.radius * 1.6)
	g.dynasty.play_sound("smash", e.position, 0.15)
	rb._remove(e)
	return true


## THE RETURN (CartoucheKit, when its timer ran out): cartouche `c` goes and
## its body stands again where it lay, at return_hp of its max HP, one return
## higher (Enemy.reborn: its hits x damage_mult per return).
func return_body(c: Enemy) -> void:
	var ck := c.kit as CartoucheKit
	var at := c.position
	var kind := ck.dead_kind
	var elite := ck.elite
	var n := ck.returns + 1  # The body's returns after this one.
	_remove(c)
	var b := game.enemies.spawn_at(kind, at, elite)
	if b == null:
		return
	b.hp = b.max_hp * float(cfg["return_hp"])
	b.reborn = n
	if b.kit is DynastyKit:
		(b.kit as DynastyKit).returns = n
	returned[mini(n, 3) - 1] += 1
	game.stat_add("rebirth_returned", 1.0)
	game.effects.pop(at, Palette.DYN_BRONZE_LIGHT, b.radius * 2.0)
	game.dynasty.play_sound("rebirth", at, 0.25)


## The Devourer's lane ate cartouche `c`: it goes, and its body never returns.
func eat(c: Enemy) -> void:
	eaten += 1
	game.stat_add("rebirth_eaten", 1.0)
	_remove(c)


## THE public call for phase 2 (the Necropolis's jars beside its tombs): a
## Canopic Jar stands at `at` now. Returns it (null if it could not spawn).
func place_jar(at: Vector2) -> Enemy:
	var j := game.enemies.spawn_at(DynastyEnemyData.CANOPIC_JAR, at, false)
	if j != null:
		game.dynasty.play_sound("jar_rise", at, 0.5)
	return j


## The live jar that holds a Name at `p` (the nearest within jar_radius, or
## the nearest anywhere during Anubis's Procession; null = none).
func jar_near(p: Vector2) -> Enemy:
	var best: Enemy = null
	var best_d := INF if procession else float(cfg["jar_radius"])  # The Procession: every jar holds every Name.
	for j in jars:
		if not j.active:
			continue
		var d := j.position.distance_to(p)
		if d <= best_d:
			best_d = d
			best = j
	return best


## Live cartouches now.
func alive_count() -> int:
	return cartouches.size()


# =====================================================================================
# Bookkeeping (DynastyRules, the kits)
# =====================================================================================

## A Canopic Jar `j` stood up (DynastyRules.note_spawn()).
func note_jar(j: Enemy) -> void:
	if not jars.has(j):
		jars.append(j)
		jars_placed += 1
		game.stat_add("rebirth_jars", 1.0)


## Enemy `e` left the field (DynastyRules.note_gone()): when it was a jar,
## every cartouche it sealed crumbles (its body returns no more).
func on_jar_gone(e: Enemy) -> void:
	if not jars.has(e):
		return
	jars.erase(e)
	if e.hp <= 0.0:
		jars_broken += 1
		game.stat_add("rebirth_jars_broken", 1.0)
		game.dynasty.play_sound("jar_break", e.position, 0.3)
	var i := cartouches.size() - 1
	while i >= 0:
		var c := cartouches[i]
		if c.active and (c.kit as CartoucheKit).sealed_by(e):
			crumbled += 1
			game.stat_add("rebirth_crumbled", 1.0)
			game.effects.pop(c.position, Palette.DYN_LAPIS, c.radius * 1.4)
			_remove(c)
		i -= 1


## A cartouche `c` left the field by any path (CartoucheKit.on_deactivate()).
func forget(c: Enemy) -> void:
	cartouches.erase(c)


## Per tick (DynastyRules.step()): the stub jars' clock.
func step(_delta: float) -> void:
	var now := game.elapsed
	var i := _rising.size() - 1
	while i >= 0:
		if now >= float(_rising[i][1]):
			place_jar(_rising[i][0])
			_rising.remove_at(i)
		i -= 1
	if now >= _next_jar:
		_next_jar = now + float(jars_cfg["every"])
		if now < WaveData.RUN_DURATION:
			_announce_jar()


# =====================================================================================
# Internals
# =====================================================================================

## Ends cartouche `c` without a return (it leaves the list and the field).
func _remove(c: Enemy) -> void:
	cartouches.erase(c)
	game.enemies.despawn(c)


## A stub jar starts rising `min`..`max` px from a standing necromancer (the
## seeded gameplay RNG), unless max_alive stand or rise already.
func _announce_jar() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var live := 0
	for j in jars:
		if j.active:
			live += 1
	if live + _rising.size() >= int(jars_cfg["max_alive"]):
		game.stat_add("rebirth_jars_refused", 1.0)
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var a := randf() * TAU
	var dist := randf_range(float(jars_cfg["min"]), float(jars_cfg["max"]))
	var r := float(DynastyEnemyData.ENEMIES[DynastyEnemyData.CANOPIC_JAR]["radius"])
	var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, r)
	var warn := float(jars_cfg["warn"])
	_rising.append([at, game.elapsed + warn])
	game.effects.telegraph_circle(at, r * 2.0, warn)


# --- Act XII (temporary number): the Necropolis of Sand ---
## ANUBIS'S PROCESSION (BossAnubis, the brief's "one Rebirth method of
## yours": "every jar must be broken to end Rebirth"): while `on`, jar_near()
## finds the nearest live jar ANYWHERE (every jar holds every Name, sealed:
## no blow smashes it) and a body no jar holds gets no cartouche (as
## jars_required), so once every jar is broken Rebirth ends until it is
## switched off. Off: the rule's own jar radius again.
func set_procession(on: bool) -> void:
	if procession != on:
		procession = on
		game.stat_add("rebirth_procession_on" if on else "rebirth_procession_off", 1.0)
