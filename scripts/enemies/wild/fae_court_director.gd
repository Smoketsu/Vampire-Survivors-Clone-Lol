## FaeCourtDirector — the stage systems of THE FAE COURT (temporary Act XV stage
## 44, final stage 44; GDD §15.0 "The Fae Court (Act XV phase 2)"; owner-approved
## proposal docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 44: The Fae
## Court"), owned and stepped by EnemyDirector on a stage whose STAGE has a
## "fae_court" config (FaeCourtStage.FAE_COURT; `game.enemies.fae_court`, null
## elsewhere). The zones' floors and obstacles are MarchDirector's; the seasons,
## the blight, the thickets and Spring Returns the shared WildRules'. Here:
##   * THE ENDLESS SUMMER ("a court of endless summer under a sky that never
##     sets"): on its first tick the year is forced to Summer until summer_until
##     (the run's end) through SeasonCycle.set_override(), the one season path;
##     the Winter Prince's minute overrides it to Winter, then it comes back.
##   * THE FAIRY RINGS (the stage mechanic: "mushroom circles where time runs at
##     half speed for whatever is inside, both armies"): a ring may lie in each
##     ring_cell px cell (ring_in(), a pure hash: ring_chance, wholly inside its
##     cell, none within ring_clear px of the arena's centre), ring_radius px.
##     Every ring_every s every body inside one is slowed ring_slow for
##     ring_linger s: a necromancer through WildRules.slow_player() (TerrainSlow,
##     the one ground-slow path, bound to his slot), a grounded summon through
##     TerrainSlow.slow_summon(), an enemy through Enemy.apply_slow() (never a
##     boss, a miniboss, a structure or a flier). Drawn on the director's own
##     layer just over the blight (a disc of moss and its mushrooms, or the
##     tiles/wild_fairy_ring patch).
##   * THE WINTER PRINCE ("winter_prince" event): the stage miniboss comes in
##     prince_dist px ahead of the necromancer and his row's winter_time s of
##     WINTER begin (set_override(WINTER, now + winter_time): the snow, the
##     blizzards and the Winter Court come with it); then the summer returns.
##   * A FAIR BARGAIN (the stage's achievement: "accept every bargain the Summer
##     Queen offers and still win"): MetaProgress reads the Summer Queen's
##     bargain stats (BossSummerQueen) with the run's victory.
## Deterministic: game time, pure hashes and positions only. Stats:
## ring_slows_you, ring_slows_summons, ring_slows_enemies,
## prince_spawned, prince_killed, prince_winter_s.
class_name FaeCourtDirector
extends Node2D

## Ring cells looked at round each necromancer, each way (the rings near him).
const NEAR_CELLS: int = 2

## Owning run.
var game: Game
## The stage's config (FaeCourtStage.FAE_COURT).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the Winter Prince fell ("" while alive / never spawned).
var prince_time: String = ""
## True once the endless summer has been set.
var _summer_set: bool = false
## Game time (s) the Winter Prince's winter ends (0 = none running).
var _winter_until: float = 0.0
## Game time (s) of the next ring check.
var _next: float = 0.0
## The Winter Prince once spawned (null before / after; generation-checked).
var _prince: Enemy = null
## Generation of `_prince` when he spawned.
var _prince_gen: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## The ring cell under the necromancer last drawn (redraw on a change).
var _drawn_at: Vector2i = Vector2i(2147483647, 0)


func _ready() -> void:
	z_index = -7  # Over the blight (-8), under the obstacles (-6) and every body.
	z_as_relative = false
	_draws = DisplayServer.get_name() != "headless"


## The fairy ring of cell `c` (a pure hash of the cell): Vector3(x, y, radius)
## in world px, radius 0 when the cell holds none. The ring lies wholly inside
## its cell, so a body's own cell is the only one to test.
static func ring_in(c: Vector2i, cfg: Dictionary) -> Vector3:
	var size := float(cfg["ring_cell"])
	var h := absi(hash(Vector3i(c.x, c.y, int(cfg["ring_salt"]))))
	if float(h % 1000) / 1000.0 >= float(cfg["ring_chance"]):
		return Vector3.ZERO
	var m := float(cfg["ring_margin"]) + float(cfg["ring_radius"])
	var span := size - 2.0 * m
	var p := Vector2(c) * size + Vector2(m + float((h >> 10) % 1000) / 1000.0 * span, m + float((h >> 20) % 1000) / 1000.0 * span)
	if p.length() < float(cfg["ring_clear"]):
		return Vector3.ZERO
	return Vector3(p.x, p.y, float(cfg["ring_radius"]))


## The ring cell of world point `p`.
func cell_of(p: Vector2) -> Vector2i:
	var size := float(config["ring_cell"])
	return Vector2i(floori(p.x / size), floori(p.y / size))


## True when world point `p` lies inside a fairy ring.
func in_ring(p: Vector2) -> bool:
	var g := ring_in(cell_of(p), config)
	return g.z > 0.0 and p.distance_to(Vector2(g.x, g.y)) <= g.z


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var now := game.elapsed
	if game.wild == null:
		return
	var sc := game.wild.seasons
	if not _summer_set:
		_summer_set = true
		sc.set_override(WildRulesData.SUMMER, float(config["summer_until"]))
	if _winter_until > 0.0 and now >= _winter_until:
		_winter_until = 0.0
		sc.set_override(WildRulesData.SUMMER, float(config["summer_until"]))
		game.enemies.show_banner(String(config.get("summer_banner", "")))
		_log("summer_returns")
	if _winter_until > 0.0:
		game.stat_add("prince_winter_s", delta)
	if _prince != null and not (_prince.active and _prince.generation == _prince_gen):
		_prince = null
		game.stat_add("prince_killed", 1.0)
		prince_time = _clock()
		_log("prince_down")
	if now >= _next:
		var dt := float(config["ring_every"])
		_next = now + dt
		_step_rings()
	if _draws:
		var c := cell_of(game.player.position)
		if c != _drawn_at:
			_drawn_at = c
			queue_redraw()


# =====================================================================================
# The fairy rings
# =====================================================================================

## Every body inside a ring is slowed (see the header).
func _step_rings() -> void:
	var f := float(config["ring_slow"])
	var linger := float(config["ring_linger"])
	for pl in game.all_players:
		if not pl.dead and in_ring(pl.position) and game.wild.slow_player(pl, f, linger):
			game.stat_add("ring_slows_you", 1.0)
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and not u.airborne and not u.flies and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD \
					and in_ring(u.position) and TerrainSlow.slow_summon(game, u, f, linger) > 0.0:
				game.stat_add("ring_slows_summons", 1.0)
	for e in game.enemies.active:
		if e.active and not e.is_boss and not e.is_miniboss and not e.is_structure and not e.flies and not e.floating and in_ring(e.position):
			e.apply_slow(f, linger)
			game.stat_add("ring_slows_enemies", 1.0)


## The autotest autopilot's push out of a fairy ring it stands in (the bot
## walks round them: inside, its army and it would crawl).
func danger_push(p: Vector2) -> Vector2:
	var g := ring_in(cell_of(p), config)
	if g.z <= 0.0:
		return Vector2.ZERO
	var rel := p - Vector2(g.x, g.y)
	if rel.length() > g.z + 20.0:
		return Vector2.ZERO
	return (rel.normalized() if rel.length() > 1.0 else Vector2.RIGHT) * 0.8


# =====================================================================================
# The Winter Prince
# =====================================================================================

## Runs a Fae Court timeline event (EnemyDirector forwards the "winter_prince"
## type; keys in FaeCourtStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "winter_prince":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.RIGHT
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("prince_dist", 300.0)), 20.0)
	var kind := String(ev.get("kind", FaeCourtEnemyData.WINTER_PRINCE))
	var e := game.enemies.spawn_at(kind, at, bool(ev.get("elite", false)))
	if e != null:
		_prince = e
		_prince_gen = e.generation
		game.stat_add("prince_spawned", 1.0)
	if game.wild != null:
		var winter := float(EnemyDirector.wild_def(kind).get("winter_time", 60.0))
		_winter_until = game.elapsed + winter
		game.wild.seasons.set_override(WildRulesData.WINTER, _winter_until)
		game.wild.play_sound("blizzard", at, 1.0)
	game.shake(6.0)
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("winter_prince")


## The HUD objective while the Winter Prince's winter holds ("" otherwise).
func objective_override() -> String:
	if _prince != null:
		return String(config.get("prince_objective", ""))
	return ""


# =====================================================================================
# Drawing and report
# =====================================================================================

## The rings near the necromancer: a faint disc of trodden moss ringed with
## mushrooms (the ring art's patch once it exists). Disc textures and rects;
## redrawn only when he crosses into another ring cell.
func _draw() -> void:
	var pc := cell_of(game.player.position)
	var tex := SpriteBank.texture(String(config["ring_art"]))
	for dy in range(-NEAR_CELLS, NEAR_CELLS + 1):
		for dx in range(-NEAR_CELLS, NEAR_CELLS + 1):
			var g := ring_in(pc + Vector2i(dx, dy), config)
			if g.z <= 0.0:
				continue
			var at := Vector2(g.x, g.y)
			if tex != null:
				SpriteBank.apply_sharp(self)
				draw_texture_rect(tex, Rect2(at - Vector2(g.z, g.z), Vector2(g.z, g.z) * 2.0), false)
				continue
			SpriteBank.draw_disc(self, at, g.z, Color(Palette.WILD_MOSS, 0.14))
			var n := int(config["ring_mushrooms"])
			for i in n:
				var mp := at + Vector2.from_angle(TAU * float(i) / float(n)) * g.z
				SpriteBank.draw_disc(self, mp + Vector2(1.0, 2.0), 5.0, Color(0, 0, 0, 0.3))
				draw_rect(Rect2(mp + Vector2(-1.0, 0.0), Vector2(2.0, 4.0)), Palette.WILD_BONE)  # The stalk.
				SpriteBank.draw_disc(self, mp, 4.0, Palette.WILD_BLOSSOM if i % 2 == 0 else Palette.WILD_FROST)  # The cap.


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "fairy rings: slowed you %d, summons %d, enemies %d | winter prince spawned %d, killed %d%s (winter %d s, fans %d, bolts %d) | events: %s" % [
		int(st.get("ring_slows_you", 0.0)), int(st.get("ring_slows_summons", 0.0)), int(st.get("ring_slows_enemies", 0.0)),
		int(st.get("prince_spawned", 0.0)), int(st.get("prince_killed", 0.0)), (" at " + prince_time) if prince_time != "" else "",
		int(st.get("prince_winter_s", 0.0)), int(st.get("prince_fans", 0.0)), int(st.get("prince_bolts", 0.0)),
		", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
