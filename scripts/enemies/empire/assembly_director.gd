## AssemblyDirector — the Assembly Halls' stage systems (Act III, Stage 8; GDD
## §15.0 "The Assembly Halls (Act III phase 2)"; owner-approved proposal),
## owned and stepped by EnemyDirector on a stage whose StageRegistry "assembly"
## config is not empty (AssemblyStage.ASSEMBLY; null elsewhere). Data:
## AssemblyStage (ASSEMBLY, the zones' "belts" / "channels", the "fabricators"
## and "beta_build" timeline events) and AssemblyEnemyData (the structures, the
## miniboss).
##   * Conveyors: the current zone's belt lanes (repeating world strips, see
##     AssemblyStage.BELTS_*) carry everyone standing on them along at the
##     belt's speed, neighbouring belts running opposite ways: the necromancer,
##     every summon on the ground and every walking enemy, through the ONE
##     ground path (TerrainSlow.push_player / push_summon / push_enemy), before
##     Arena.resolve_all() pushes them out of obstacles (no obstacle is ever
##     generated on a belt: the zone's arena "free_bands").
##   * Furnace channels: the current zone's channels lie cold, glow (the
##     telegraph) and burn on a fixed rhythm, each channel offset from its
##     neighbours; while one burns, the necromancer, the summons on the ground
##     and the walking enemies in it take damage every tick (the Empire burns
##     too). Flying drones, Grave Drones and structures pass over.
##   * Fabricators (optional, but each one standing builds more enemies):
##     structures placed by the "fabricators" events, each building the kinds of
##     its event in turn every few seconds (FabricatorKit calls fabricate()).
##     Each one destroyed makes every LATER scripted wave smaller (wave_mult(),
##     applied once in EnemyDirector._run_event()) and the trickle thinner
##     (trickle_mult()), pays an XP burst and Soul Ash. Destroying every
##     fabricator of the run sets the run stat assembly_all_fabricators
##     (achievement Cold Assembly, MetaProgress).
##   * The Beta Build: the miniboss ("beta_build" event; BetaBuildKit registers
##     it on the HUD's miniboss bar and patches it from standing_fabricators()).
##   * Guests: guest_aliases() resolves the timeline's guest aliases (another
##     Act III stage's kinds) once at run start.
## Structures are ordinary pooled Enemy nodes (is_structure, is_objective:
## never recycled), polled with generation checks; every placed structure asks
## Arena.keep_clear() so a later zone never rebuilds an obstacle on it.
## Deterministic: positions, game time and the seeded global RNG only. The belts
## and channels are drawn here (world space, over the floor and under the
## obstacles and bodies; purely visual).
## Stats: assembly_belt_player_s, assembly_belt_summon_s, assembly_belt_enemy_s
## (body-seconds carried), assembly_furnace_flares, assembly_furnace_player_hits
## / _dmg, assembly_furnace_summon_hits, assembly_furnace_enemy_hits / _dmg /
## _kills, assembly_fabricators_placed / _destroyed, assembly_fabricated,
## assembly_fabricated_<kind>, assembly_beta_spawned / _killed, objective_ash.
class_name AssemblyDirector
extends Node2D

## One tracked fabricator.
class Fab:
	extends RefCounted
	## The fabricator's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it was placed (stale / death guard).
	var gen: int = 0
	## The timeline event that placed it (its builds, rewards).
	var ev: Dictionary = {}
	## Last known world position (rewards spawn here once it falls).
	var pos: Vector2 = Vector2.ZERO
	## Index of the next kind of ev.builds it builds.
	var next_build: int = 0
	## Enemies it has built.
	var built: int = 0

## Furnace channel state: cold.
const DORMANT: int = 0
## Furnace channel state: glowing (the telegraph).
const WARNING: int = 1
## Furnace channel state: burning.
const BURNING: int = 2
## Damage source tag of the furnace channels (CombatResolver stats; an area hit
## for Unholy Resilience, PassiveData.AREA_HOLY_SOURCES).
const FURNACE_SOURCE: String = "furnace"
## Margin (px) around the view inside which the belts and channels are drawn.
const DRAW_MARGIN: float = 96.0
## Spacing (px) of the chevrons painted on a belt (drawing only).
const CHEVRON_STEP: float = 28.0
## Spacing (px) of the rollers along a belt's rails (drawing only).
const ROLLER_STEP: float = 16.0

## Owning run.
var game: Game
## The stage's assembly config (AssemblyStage.ASSEMBLY).
var config: Dictionary = {}
## Live fabricators.
var fabs: Array[Fab] = []
## Fabricators placed so far.
var fabs_placed: int = 0
## Fabricators destroyed so far.
var fabs_destroyed: int = 0
## Fabricators the stage's timeline places in a full run (the Cold Assembly goal).
var fabs_planned: int = 0
## Game time each fabricator fell, "m:ss" (summary).
var fab_times: PackedStringArray = PackedStringArray()
## Game time the Beta Build fell ("" while alive / never spawned).
var beta_time: String = ""
## Log of Assembly events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The Beta Build once spawned (null before / after; generation-checked).
var _beta: Enemy = null
## Generation of `_beta` when it spawned.
var _beta_gen: int = 0
## Seconds until the next furnace damage tick.
var _furnace_cd: float = 0.0
## Channel index -> the state it had last tick (counts the flares).
var _channel_seen: Dictionary = {}
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -9  # Over the floor (-10), under the obstacles (-6) and the bodies.
	for ev: Dictionary in game.stage_def["events"]:
		if String(ev.get("type", "")) == "fabricators":
			fabs_planned += int(ev["count"])


## Per-tick update, called by EnemyDirector after the MarchDirector.
func step(delta: float) -> void:
	_step_belts(delta)
	_step_furnace(delta)
	_step_fabs()
	_step_beta()
	queue_redraw()  # The belts scroll and the channels glow (visual only).


# =====================================================================================
# Zones: belts and channels
# =====================================================================================

## The current battle zone (AssemblyStage.ZONES entry; the first before the
## MarchDirector exists).
func zone() -> Dictionary:
	var zones: Array = game.stage_def["march"].get("zones", [])
	if zones.is_empty():
		return {}
	var i := game.enemies.march.zone_index if game.enemies.march != null else 0
	return zones[clampi(i, 0, zones.size() - 1)]


## Index of the strip of band `b` nearest to `p` and the signed distance (px)
## from its centre line (Vector2(index, offset)).
static func strip_of(b: Dictionary, p: Vector2) -> Vector2:
	var across := p.y if String(b["axis"]) == "x" else p.x  # Coordinate across the strip (px).
	var period := float(b["period"])
	var k := floorf((across - float(b["offset"])) / period + 0.5)  # Nearest strip index.
	return Vector2(k, across - float(b["offset"]) - k * period)


## The belt velocity (px/s) under a body of radius `r` at `p` in the current
## zone (zero off the belts): it rides a belt while its centre is on the lane.
func belt_velocity(p: Vector2, _r: float = 0.0) -> Vector2:
	var b: Dictionary = zone().get("belts", {})
	if b.is_empty():
		return Vector2.ZERO
	var s := strip_of(b, p)
	if absf(s.y) > float(b["half"]):
		return Vector2.ZERO
	var run := 1.0 if int(s.x) % 2 == 0 else -1.0  # Neighbouring belts run opposite ways.
	var axis := Vector2.RIGHT if String(b["axis"]) == "x" else Vector2.DOWN
	return axis * run * float(b["speed"])


## Moves every body standing on a belt (the one ground path, TerrainSlow).
func _step_belts(delta: float) -> void:
	if (zone().get("belts", {}) as Dictionary).is_empty():
		return
	var v := Vector2.ZERO  # Belt velocity under the body being moved (px/s).
	for k in game.all_players.size():  # Each necromancer and his army (co-op: bound in turn).
		var prev := game.bind_index(k)
		v = belt_velocity(game.player.position)
		if v != Vector2.ZERO and TerrainSlow.push_player(game, v, delta):
			game.stat_add("assembly_belt_player_s", delta)
		for u in game.horde.units:
			v = belt_velocity(u.position)
			if v != Vector2.ZERO and TerrainSlow.push_summon(game, u, v, delta):
				game.stat_add("assembly_belt_summon_s", delta)
		game.unbind(prev)
	for e in game.enemies.active:
		v = belt_velocity(e.position)
		if v != Vector2.ZERO and TerrainSlow.push_enemy(game, e, v, delta):
			game.stat_add("assembly_belt_enemy_s", delta)


## State of channel `k` of the current zone's channels at game time `t`
## (DORMANT / WARNING / BURNING) and its progress 0..1 through that state
## (Vector2(state, progress)).
func channel_state(k: int, t: float) -> Vector2:
	var f: Dictionary = config["furnace"]
	var cold := float(f["dormant"])
	var warn := float(f["warning"])
	var burn := float(f["burning"])
	var cycle := cold + warn + burn  # One full rhythm (s).
	var ph := fposmod(t + float(k) * float(f["stagger"]), cycle)  # Time into this channel's rhythm (s).
	if ph < cold:
		return Vector2(DORMANT, ph / cold)
	if ph < cold + warn:
		return Vector2(WARNING, (ph - cold) / warn)
	return Vector2(BURNING, (ph - cold - warn) / burn)


## Channel index at `p` and whether `p` (a body of radius `r`) is inside it
## (Vector2(index, 1 if inside else 0)); index meaningless when no channels.
func channel_at(p: Vector2, r: float) -> Vector2:
	var c: Dictionary = zone().get("channels", {})
	if c.is_empty():
		return Vector2(0, 0)
	var s := strip_of(c, p)
	return Vector2(s.x, 1.0 if absf(s.y) <= float(c["half"]) + r * 0.5 else 0.0)


## True when a body of radius `r` at `p` stands in a burning channel.
func burning_at(p: Vector2, r: float) -> bool:
	var ch := channel_at(p, r)
	return ch.y > 0.0 and int(channel_state(int(ch.x), game.elapsed).x) == BURNING


## Burns everything standing in a burning channel every furnace tick.
func _step_furnace(delta: float) -> void:
	var c: Dictionary = zone().get("channels", {})
	if c.is_empty():
		return
	_count_flares(c)
	_furnace_cd -= delta
	if _furnace_cd > 0.0:
		return
	var f: Dictionary = config["furnace"]
	_furnace_cd += float(f["tick"])
	var dm := game.enemies.damage_mult  # Time scaling of enemy hits.
	for p in game.all_players:  # (Co-op: either necromancer.)
		if not p.dead and burning_at(p.position, p.radius):
			game.combat.damage_player(float(f["damage_player"]) * dm, FURNACE_SOURCE, p)
			game.stat_add("assembly_furnace_player_hits", 1.0)
	for h in game.all_hordes:  # (Co-op: every army.)
		for u in h.units:
			if u.active and not u.airborne and not u.flies and u.state != SummonedUnit.State.SPAWNING and burning_at(u.position, u.radius):
				game.combat.damage_unit(u, float(f["damage_summon"]) * dm, FURNACE_SOURCE)
				game.stat_add("assembly_furnace_summon_hits", 1.0)
	var hits: Array = []  # Own buffer: a kill may change the active list's bodies.
	for e in game.enemies.active:
		if e.active and not e.is_structure and not e.floating and not e.untargetable and burning_at(e.position, e.radius):
			hits.append(e)
	for e: Enemy in hits:
		if not e.active:
			continue
		var amount := float(f["damage_enemy"]) * game.enemies.hp_mult * (float(f["boss_share"]) if (e.is_boss or e.is_miniboss) else 1.0)
		var dealt := game.combat.damage_enemy(e, amount, FURNACE_SOURCE)
		game.stat_add("assembly_furnace_enemy_hits", 1.0)
		game.stat_add("assembly_furnace_enemy_dmg", dealt)
		if not e.active:
			game.stat_add("assembly_furnace_enemy_kills", 1.0)


## Counts each channel near the necromancer that just began to burn (stats,
## a flare sound).
func _count_flares(c: Dictionary) -> void:
	var s := strip_of(c, game.player.position)
	var k0 := int(s.x)
	for k in range(k0 - 2, k0 + 3):
		var st := int(channel_state(k, game.elapsed).x)
		if st == BURNING and int(_channel_seen.get(k, BURNING)) != BURNING:
			game.stat_add("assembly_furnace_flares", 1.0)
			var at := _channel_point(c, k, game.player.position)
			Sfx.play("furnace_flare", at)
		_channel_seen[k] = st


## A point on channel `k` of band `c` level with `p` (world px).
static func _channel_point(c: Dictionary, k: int, p: Vector2) -> Vector2:
	var centre := float(c["offset"]) + float(k) * float(c["period"])  # Strip centre line (px).
	return Vector2(p.x, centre) if String(c["axis"]) == "x" else Vector2(centre, p.y)


# =====================================================================================
# Timeline events
# =====================================================================================

## Runs an Assembly timeline event (EnemyDirector forwards the "fabricators"
## and "beta_build" types; keys in AssemblyStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"fabricators":
			_place_fabs(ev)
		"beta_build":
			_spawn_beta(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Places `ev.count` fabricators around the necromancer, spread evenly, spaced,
## out of obstacles and off the belts and channels, each with its guards.
func _place_fabs(ev: Dictionary) -> void:
	var cfg: Dictionary = config["fabricators"]
	var n := int(ev["count"])
	var offset := randf() * TAU  # Angle of the first fabricator.
	var kind := String(ev["kind"])
	var r := float(game.enemies.enemy_def(kind)["radius"])  # Body radius.
	var p := game.player.position
	var placed: Array[Vector2] = []
	for i in n:
		var best := p  # Chosen spot.
		for _try in int(cfg["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.4, 0.4)
			var pos := game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(cfg["spacing"])
			best = pos
			if spaced and belt_velocity(pos) == Vector2.ZERO and channel_at(pos, r * 2.0).y <= 0.0:
				break  # Spaced, off the belts and channels.
		placed.append(best)
		var e := game.enemies.spawn_at(kind, best, false)
		e.is_objective = true
		game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
		var f := Fab.new()
		f.enemy = e
		f.gen = e.generation
		f.ev = ev
		f.pos = e.position
		fabs.append(f)
		fabs_placed += 1
		game.effects.spawn_ring(e.position, Palette.EMPIRE_SIGNAL_AMBER)
		for grp: Dictionary in ev.get("guards", []):
			for _k in int(grp["count"]):
				if game.enemies.regular_alive() >= game.enemies.hard_cap():
					break
				game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 30.0), bool(grp["elite"]))
	game.stat_add("assembly_fabricators_placed", float(n))
	_log("fabricators_placed_%d" % n)


## Spawns the Beta Build on the spawn ring and tracks it. Its kit registers it
## on the HUD's miniboss bar (Enemy.is_miniboss: never recycled).
func _spawn_beta(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev["kind"]), game.enemies.ring_point(randf() * TAU), bool(ev["elite"]))
	_beta = e
	_beta_gen = e.generation
	game.stat_add("assembly_beta_spawned", 1.0)
	_log("beta_build_arrived")


# =====================================================================================
# Fabricators, the Beta Build
# =====================================================================================

## FabricatorKit asks this when fabricator `e` is due to build: spawns the next
## kind of its event beside it, unless the living enemies are near the soft cap.
## Returns the kind built ("" when it skipped this cycle, or when `e` is not one
## of this director's fabricators: the kit then builds its own row's kind).
func fabricate(e: Enemy) -> String:
	var f := _fab_of(e)
	if f == null:
		return ""
	var builds: Array = f.ev.get("builds", [])
	if builds.is_empty():
		return ""
	if game.enemies.regular_alive() >= game.enemies.soft_cap() - int(config["fabricators"]["build_cap_margin"]):
		game.stat_add("assembly_fabricate_capped", 1.0)
		return "-"
	var kind := String(builds[f.next_build % builds.size()])
	f.next_build += 1
	f.built += 1
	_build_at(e, kind)
	return kind


## Builds one enemy of `kind` at fabricator `e`'s bay (on its open side, toward
## the necromancer). Also used by FabricatorKit off this stage.
func _build_at(e: Enemy, kind: String) -> void:
	build_enemy(game, e, kind)


## Spawns one enemy of `kind` out of fabricator `e`'s bay (just in front of it,
## toward the necromancer), with the build flash and the stats.
static func build_enemy(g: Game, e: Enemy, kind: String) -> void:
	var to_p := g.player.position - e.position
	var dir := to_p.normalized() if to_p.length() > 1.0 else Vector2.DOWN
	var at := e.position + dir * (e.radius + 16.0)
	var made := g.enemies.spawn_at(kind, at, false)
	g.effects.spawn_ring(made.position, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("fabricate", e.position)
	g.stat_add("assembly_fabricated", 1.0)
	g.stat_add("assembly_fabricated_" + made.kind, 1.0)


## The record of fabricator `e` (null when it is not a live one of ours).
func _fab_of(e: Enemy) -> Fab:
	for f in fabs:
		if f.enemy == e and f.gen == e.generation:
			return f
	return null


## Living fabricators (the Beta Build patches itself from these).
func standing_fabricators() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for f in fabs:
		if f.enemy.active and f.enemy.generation == f.gen:
			out.append(f.enemy)
	return out


## Fallen fabricators pay their rewards.
func _step_fabs() -> void:
	var i := 0
	while i < fabs.size():
		var f := fabs[i]
		var e := f.enemy
		if not e.active or e.generation != f.gen:
			_on_destroyed(f)
			fabs.remove_at(i)
			continue
		f.pos = e.position
		i += 1


## A fabricator fell: rewards, banner, stats, the Cold Assembly check.
func _on_destroyed(f: Fab) -> void:
	var cfg: Dictionary = config["fabricators"]
	fabs_destroyed += 1
	fab_times.append(_clock())
	_xp_burst(f.pos, f.ev)
	game.stat_add("objective_ash", float(cfg["ash"]))
	game.stat_add("assembly_fabricators_destroyed", 1.0)
	game.effects.impact(f.pos, 60.0, Palette.EMPIRE_SIGNAL_AMBER)
	Sfx.play("orbital_strike", f.pos, 1.4)
	game.shake(5.0)
	game.enemies.show_banner("A fabricator is smashed: the Empire's waves thin (-%d%%)!" % roundi((1.0 - wave_mult()) * 100.0))
	_log("fabricator_destroyed")
	if fabs_planned > 0 and fabs_destroyed >= fabs_planned and not game.stats.has("assembly_all_fabricators"):
		game.stats["assembly_all_fabricators"] = 1.0  # Cold Assembly (MetaProgress lifetime counter assembly_cold_runs).
		game.enemies.show_banner("COLD ASSEMBLY: every fabricator in the halls is scrap!")
		_log("cold_assembly")


## Notes when the Beta Build fell (its XP burst and banner are its kit's, its
## chest ChestManager's miniboss rule).
func _step_beta() -> void:
	if _beta == null or (_beta.active and _beta.generation == _beta_gen):
		return
	_beta = null
	game.stat_add("assembly_beta_killed", 1.0)
	beta_time = _clock()
	_log("beta_build_killed")


## XP burst of a fallen fabricator (`ev` reward_xp in reward_crystals crystals).
func _xp_burst(pos: Vector2, ev: Dictionary) -> void:
	var xp := int(ev.get("reward_xp", 0))
	var n := maxi(1, int(ev.get("reward_crystals", 1)))
	if xp <= 0:
		return
	var each := maxi(1, floori(float(xp) / float(n)))
	for k in n:
		game.pickups.spawn(pos + Vector2.from_angle(TAU * float(k) / float(n)) * randf_range(18.0, 50.0), each)


## Records an Assembly event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Queries (enemy director, HUD, autopilot)
# =====================================================================================

## Multiplier on the size of every scripted wave from now on: -wave_cut per
## destroyed fabricator (additive), at least min_mult.
func wave_mult() -> float:
	var cfg: Dictionary = config["fabricators"]
	return maxf(float(cfg["min_mult"]), 1.0 - float(cfg["wave_cut"]) * float(fabs_destroyed))


## Multiplier on the trickle rate from now on: -trickle_cut per destroyed fabricator.
func trickle_mult() -> float:
	var cfg: Dictionary = config["fabricators"]
	return maxf(float(cfg["min_mult"]), 1.0 - float(cfg["trickle_cut"]) * float(fabs_destroyed))


## HUD objective for the live Assembly objective ("" if none): the Beta Build
## first, then the fabricators.
func objective_override() -> String:
	if _beta != null:
		var n := standing_fabricators().size()
		if n > 0:
			return "The Beta Build patches itself from %d fabricator%s: smash them!" % [n, "" if n == 1 else "s"]
		return "Destroy the Beta Build"
	var live := standing_fabricators().size()
	if live > 0:
		return "Smash the fabricators: each one builds more soldiers (%d left)" % live
	return ""


## Autopilot hint: the nearest live fabricator within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for f in fabs:
		var d := p.distance_to(f.pos)
		if d < best_d:
			best_d = d
			best = f.pos
	return best


## Autopilot hint: a push out of a glowing or burning channel at `p`.
func danger_push(p: Vector2) -> Vector2:
	var c: Dictionary = zone().get("channels", {})
	if c.is_empty():
		return Vector2.ZERO
	var s := strip_of(c, p)
	var reach := float(c["half"]) + 26.0  # Feel the heat this far from the centre line (px).
	if absf(s.y) > reach or int(channel_state(int(s.x), game.elapsed).x) == DORMANT:
		return Vector2.ZERO
	var out := 1.0 if s.y >= 0.0 else -1.0  # The nearer edge.
	var dir := Vector2(0.0, out) if String(c["axis"]) == "x" else Vector2(out, 0.0)
	return dir * (1.0 - absf(s.y) / reach) * 1.5


## The run's timeline aliases plus the guest aliases of `cfg` (ASSEMBLY
## "guests"): each alias maps to the first of its ids that is a known kind
## (EnemyDirector.is_known_kind(): another Act III stage's table once it has
## merged), else to its fallback. `base` is not changed.
static func guest_aliases(base: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := base.duplicate()
	for g: Dictionary in cfg.get("guests", []):
		var real := String(g["fallback"])
		for id: String in g["ids"]:
			if EnemyDirector.is_known_kind(id):
				real = id
				break
		out[String(g["alias"])] = real
	return out


## The autotest "assembly" line: fabricators, the Beta Build, Cold Assembly.
func summary_line() -> String:
	var st := game.stats
	return "fabricators destroyed %d/%d placed (of %d planned; %s) | built %d (capped %d) | wave size now x%.2f, trickle x%.2f | cold assembly %s | beta build %s | objective ash %d" % [
		fabs_destroyed, fabs_placed, fabs_planned, ", ".join(fab_times) if not fab_times.is_empty() else "-",
		int(st.get("assembly_fabricated", 0.0)), int(st.get("assembly_fabricate_capped", 0.0)), wave_mult(), trickle_mult(),
		"yes" if st.has("assembly_all_fabricators") else "no",
		("killed at " + beta_time) if beta_time != "" else ("alive" if _beta != null else "not spawned"),
		int(st.get("objective_ash", 0.0))]


## The autotest "assembly floor" line: belts and furnace channels.
func floor_line() -> String:
	var st := game.stats
	return "belts carried you %.0f s, summons %.0f s, enemies %.0f s | furnace flares %d | burned you %d times (dmg %d), summons %d times (dmg %d), enemies %d times (dmg %d, kills %d)" % [
		float(st.get("assembly_belt_player_s", 0.0)), float(st.get("assembly_belt_summon_s", 0.0)), float(st.get("assembly_belt_enemy_s", 0.0)),
		int(st.get("assembly_furnace_flares", 0.0)), int(st.get("assembly_furnace_player_hits", 0.0)), int(st.get("player_dmg_from_" + FURNACE_SOURCE, 0.0)),
		int(st.get("assembly_furnace_summon_hits", 0.0)), int(st.get("summon_dmg_from_" + FURNACE_SOURCE, 0.0)),
		int(st.get("assembly_furnace_enemy_hits", 0.0)), int(st.get("assembly_furnace_enemy_dmg", 0.0)), int(st.get("assembly_furnace_enemy_kills", 0.0))]


# =====================================================================================
# Drawing (the belts and channels in view; world space, visual only)
# =====================================================================================

func _draw() -> void:
	if game == null or game.player == null:
		return
	var half := game.view_size() * 0.5 + Vector2.ONE * DRAW_MARGIN
	var view := Rect2(game.player.position - half, half * 2.0)
	var z := zone()
	var b: Dictionary = z.get("belts", {})
	if not b.is_empty():
		_draw_bands(b, view, true)
	var c: Dictionary = z.get("channels", {})
	if not c.is_empty():
		_draw_bands(c, view, false)


## Draws every strip of band `b` crossing `view`: belts (`belt` true) or
## furnace channels.
func _draw_bands(b: Dictionary, view: Rect2, belt: bool) -> void:
	var along_x := String(b["axis"]) == "x"
	var lo := view.position.y if along_x else view.position.x  # View span across the strips (px).
	var hi := view.end.y if along_x else view.end.x
	var period := float(b["period"])
	var off := float(b["offset"])
	var k0 := floori((lo - off) / period - 0.5)
	var k1 := ceili((hi - off) / period + 0.5)
	for k in range(k0, k1 + 1):
		var centre := off + float(k) * period  # Strip centre line (px).
		var hw := float(b["half"])
		var rect := Rect2(view.position.x, centre - hw, view.size.x, hw * 2.0) if along_x else Rect2(centre - hw, view.position.y, hw * 2.0, view.size.y)
		rect.position = rect.position.floor()
		if belt:
			AssemblyGlyphs.draw_belt(self, rect, along_x, 1.0 if k % 2 == 0 else -1.0, game.elapsed * float(b["speed"]))
		else:
			var stv := channel_state(k, game.elapsed)
			AssemblyGlyphs.draw_channel(self, rect, along_x, int(stv.x), stv.y, game.elapsed)
