## CrashSiteDirector — the stage systems of the Crash Site (Stage 25; Act IX,
## the Concord of Stars; GDD §15.0 "The Crash Site (Act IX phase 2)";
## owner-approved proposal docs/act9/PROPOSAL.md "Stage 25: The Crash Site"
## with the owner's phase 2 answers of Nov 3, 2026), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "crash_site" config
## (CrashSiteStage.CRASH_SITE; `game.enemies.crash_site`, null elsewhere). The
## zones are MarchDirector's; Beams, Abduction, Terraforming and the Final
## Harvest the shared ConcordRules'. Here:
##   * THE CRATER: at the stage's start the crater's alien ground is seeded
##     (Terraforming.seed(), THE one public call; tag "crater"): a disc of
##     live turf `crater` offset px from the necromancer's start.
##   * INFESTATION (owner answer, Nov 3, 2026): THE ONE EGG PATH, lay_egg():
##     a brood_egg structure (CrashSiteEnemyData) where a Concord enemy fell
##     (on_concord_death(), the kill hook in CombatResolver.damage_enemy(),
##     beside GhoulKit.claim_corpse(), only while Game.concord exists), where
##     the Brood Matriarch's egg sacs land and where the Hive Mother lays her
##     egg waves. Which deaths lay: Concord kinds that are not structures,
##     bosses or eggs, and never a broodling that hatched from an egg
##     (BroodlingKit.hatched: no chains). At most `egg_cap` eggs alive (over
##     it no egg is laid; counted as skipped). An egg sits for its row's
##     hatch_time s (BroodEggKit); any hit that reaches it clears it
##     (clear_egg(), from CombatResolver before the kill path: no kill, no XP,
##     no drop, no corpse; counted by spell / by summon / by anything else);
##     otherwise a broodling hatches (on_egg_hatched()).
##   * NOTHING HATCHED (the stage's achievement; owner's Act IX call, eased
##     after Act IX playtest pass 1: "at most 10 eggs hatch before the Hive
##     Mother falls", was "no egg"): when the stage boss (the Hive Mother)
##     falls with at most `nothing_hatched_limit` eggs hatched so far on the
##     Crash Site, the run stat
##     crash_site_nothing_hatched is set (MetaProgress counts the runs:
##     lifetime nothing_hatched_runs, MetaData "nothing_hatched"; it unlocks
##     Anchored).
##   * THE BROOD MATRIARCH ("matriarch" event): the stage miniboss, spawned on
##     the spawn ring with an escort and tracked (objective, kill time); her
##     kit registers her on the HUD's miniboss bar and pays her XP burst.
##   * The HUD objective while the Brood Matriarch stands.
## Eggs count apart from the regular alive cap (regular_alive() subtracts
## them, as the civilians on Act VIII). Deterministic: only the seeded global
## RNG (where the Matriarch comes in). Stats: crash_site_eggs_laid,
## crash_site_eggs_laid_<tag>, crash_site_eggs_cleared,
## crash_site_eggs_cleared_spell / _summon / _other,
## crash_site_eggs_hatched, crash_site_eggs_skipped,
## crash_site_eggs_hatched_before_boss, crash_site_nothing_hatched,
## crash_site_matriarch_spawned, crash_site_matriarch_killed.
class_name CrashSiteDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (CrashSiteStage.CRASH_SITE).
var config: Dictionary = {}
## Log of Crash Site events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Eggs laid this run.
var laid: int = 0
## Eggs cleared by a hit this run.
var cleared: int = 0
## Eggs that hatched a broodling this run.
var hatched: int = 0
## Eggs not laid because the egg cap was reached.
var skipped: int = 0
## Most eggs alive at once this run.
var peak: int = 0
## Eggs that hatched before the stage boss fell (Nothing Hatched counts these
## against CrashSiteStage.CRASH_SITE "nothing_hatched_limit").
var hatched_before_boss: int = 0
## True once the stage boss (the Hive Mother) fell this run.
var boss_down: bool = false
## True once Nothing Hatched was earned this run.
var nothing_hatched: bool = false
## "m:ss" the Brood Matriarch fell ("" while alive / never spawned).
var matriarch_time: String = ""
## Standing eggs (stale ones dropped as they go).
var _eggs: Array[Enemy] = []
## Pool generation of each entry of `_eggs`.
var _egg_gens: PackedInt32Array = PackedInt32Array()
## True once the crater was seeded.
var _seeded: bool = false
## The Brood Matriarch once spawned (null before / after; generation-checked).
var _mat: Enemy = null
## Generation of `_mat` when she spawned.
var _mat_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector). The first tick
## seeds the crater and listens for the stage boss's fall.
func step(_delta: float) -> void:
	if not _seeded:
		game.enemies.boss_defeated.connect(_on_boss_defeated)
		_seed_crater()
	_prune()
	if _mat != null and not (_mat.active and _mat.generation == _mat_gen):
		_mat = null
		game.stat_add("crash_site_matriarch_killed", 1.0)
		matriarch_time = _clock()
		_log("matriarch_killed")


# =====================================================================================
# The crater
# =====================================================================================

## Seeds the crater's live turf once, `crater` offset px from the necromancer's start.
func _seed_crater() -> void:
	_seeded = true
	var cr: Dictionary = config.get("crater", {})
	if cr.is_empty():
		return
	var at := game.player.position + Vector2(cr.get("offset", Vector2.ZERO))
	var n := game.concord_rules().terraforming.seed(at, float(cr.get("radius", 200.0)), {"live": true, "tag": "crater"})
	_log("crater_%d" % n)


# =====================================================================================
# Infestation: the one egg path
# =====================================================================================

## THE KILL HOOK (CombatResolver.damage_enemy()'s kill path, only while
## Game.concord exists): a Concord enemy `e` fell; on the Crash Site an egg is
## laid where it fell (see the header for which deaths lay). Returns at once
## off the Crash Site.
static func on_concord_death(g: Game, e: Enemy) -> void:
	var cs := g.enemies.crash_site  # The Crash Site's director (null elsewhere).
	if cs == null:
		return
	if not (e.kit is ConcordKit) or e.is_structure or e.is_boss or e.kind == CrashSiteEnemyData.EGG:
		return
	if e.kit is BroodlingKit and (e.kit as BroodlingKit).hatched:
		return  # A hatchling lays none (no chains).
	cs.lay_egg(e.position, "death")


## THE ONE EGG PATH: lays an Infestation egg at `at` (tag `tag` for the stats:
## "death", "sac", "wave"). On a stage without this director (a Matriarch or a
## Hive Mother forced elsewhere) use lay_anywhere(). Returns the egg, or null
## when the cap was reached (counted) or the spawn failed.
func lay_egg(at: Vector2, tag: String) -> Enemy:
	_prune()
	if _eggs.size() >= int(config.get("egg_cap", 24)):
		skipped += 1
		game.stat_add("crash_site_eggs_skipped", 1.0)
		return null
	var e := game.enemies.spawn_at(CrashSiteEnemyData.EGG, at, false)
	if e == null:
		return null
	_eggs.append(e)
	_egg_gens.append(e.generation)
	laid += 1
	peak = maxi(peak, _eggs.size())
	game.stat_add("crash_site_eggs_laid", 1.0)
	game.stat_add("crash_site_eggs_laid_" + tag, 1.0)
	return e


## Lays an egg at `at` through the Crash Site's path when it runs, else spawns
## one plainly (it still hatches: BroodEggKit is self-contained), so the
## Matriarch's sacs and the Hive Mother's waves work on any stage.
static func lay_anywhere(g: Game, at: Vector2, tag: String) -> Enemy:
	if g.enemies.crash_site != null:
		return g.enemies.crash_site.lay_egg(at, tag)
	return g.enemies.spawn_at(CrashSiteEnemyData.EGG, at, false)


## THE EGG CLEAR (CombatResolver.damage_enemy(), before the kill path, only
## while Game.concord exists): when `e` is an egg brought to 0 HP by a hit
## tagged `source`, it leaves the field WITHOUT a kill (EnemyDirector.despawn():
## no XP, drop, corpse or kill count) and true is returned; false for anything
## else (the kill path then runs as usual).
static func clear_egg(g: Game, e: Enemy, source: String) -> bool:
	if e.kind != CrashSiteEnemyData.EGG:
		return false
	var by := "other"  # Who cleared it (the report).
	if HundredShadowsData.is_spell_source(source):
		by = "spell"
	elif SynergyData.SOURCE_CLASS.has(source):
		by = "summon"
	g.stat_add("crash_site_eggs_cleared", 1.0)
	g.stat_add("crash_site_eggs_cleared_" + by, 1.0)
	if g.enemies.crash_site != null:
		g.enemies.crash_site.cleared += 1
	g.effects.pop(e.position, Palette.CONCORD_CHITIN_LIGHT, e.radius * 1.4)
	g.enemies.despawn(e)
	return true


## An egg `e` hatched (BroodEggKit, before it leaves): counted, and Nothing
## Hatched is lost while the Hive Mother still lives.
func on_egg_hatched(_e: Enemy) -> void:
	hatched += 1
	game.stat_add("crash_site_eggs_hatched", 1.0)
	if not boss_down:
		hatched_before_boss += 1
		game.stat_add("crash_site_eggs_hatched_before_boss", 1.0)


## Most eggs that may hatch before the Hive Mother falls for Nothing Hatched
## (CrashSiteStage.CRASH_SITE "nothing_hatched_limit").
func hatch_limit() -> int:
	return int(config.get("nothing_hatched_limit", 0))


## Eggs alive now (EnemyDirector.regular_alive() leaves them out of the cap).
func eggs_alive() -> int:
	_prune()
	return _eggs.size()


## Drops the eggs that left the field from the standing list.
func _prune() -> void:
	var i := _eggs.size() - 1
	while i >= 0:
		var e := _eggs[i]
		if not e.active or e.generation != _egg_gens[i]:
			_eggs.remove_at(i)
			_egg_gens.remove_at(i)
		i -= 1


## The stage boss fell (EnemyDirector.boss_defeated): Nothing Hatched when at
## most `nothing_hatched_limit` eggs hatched before her fall and she is the
## Hive Mother.
func _on_boss_defeated() -> void:
	if boss_down:
		return
	boss_down = true
	_log("boss_down")
	if String(game.enemies.boss_info.get("id", "")) != HiveMotherData.ARRIVAL["id"]:
		return
	if String(game.stage_def.get("id", "")) != CrashSiteStage.ID or hatched_before_boss > hatch_limit():
		return
	nothing_hatched = true
	game.stats["crash_site_nothing_hatched"] = 1.0
	game.enemies.show_banner(String(config["nothing_hatched_banner"]))
	_log("nothing_hatched")


# =====================================================================================
# The Brood Matriarch
# =====================================================================================

## Runs a Crash Site timeline event (EnemyDirector forwards the "matriarch"
## type; keys in CrashSiteStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"matriarch":
			var a := randf() * TAU
			var e := game.enemies.spawn_at(String(ev.get("kind", CrashSiteEnemyData.MATRIARCH)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
			if e != null:
				_mat = e
				_mat_gen = e.generation
				game.stat_add("crash_site_matriarch_spawned", 1.0)
				game.shake(5.0)
				game.concord_rules().play_sound("hive_scream", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				var escort: Array = ev.get("escort", [])
				var k := 0
				for grp: Dictionary in escort:
					for j in int(grp.get("count", 0)):
						var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (30.0 + 18.0 * float(k / 6))
						game.enemies.spawn_at(String(grp["kind"]), at, false)
						k += 1
				if ev.has("banner"):
					game.enemies.show_banner(String(ev["banner"]))
				_log("matriarch")


## The HUD objective while the Brood Matriarch stands ("" otherwise).
func objective_override() -> String:
	if _mat != null and _mat.active and _mat.generation == _mat_gen:
		return String(config.get("matriarch_objective", ""))
	return ""


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "crater seeded %d cells | eggs laid %d (deaths %d, sacs %d, waves %d), cleared %d (spell %d, summon %d, other %d), hatched %d (before the boss %d of at most %d), skipped at the cap %d, peak %d | nothing hatched %s | matriarch spawned %d, killed %d%s | events: %s" % [
		int(st.get("terra_seeded_crater", 0.0)), laid, int(st.get("crash_site_eggs_laid_death", 0.0)),
		int(st.get("crash_site_eggs_laid_sac", 0.0)), int(st.get("crash_site_eggs_laid_wave", 0.0)),
		cleared, int(st.get("crash_site_eggs_cleared_spell", 0.0)), int(st.get("crash_site_eggs_cleared_summon", 0.0)),
		int(st.get("crash_site_eggs_cleared_other", 0.0)), hatched, hatched_before_boss, hatch_limit(), skipped, peak,
		"EARNED" if nothing_hatched else ("lost" if hatched_before_boss > hatch_limit() else "open"),
		int(st.get("crash_site_matriarch_spawned", 0.0)), int(st.get("crash_site_matriarch_killed", 0.0)),
		(" at " + matriarch_time) if matriarch_time != "" else "", ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
