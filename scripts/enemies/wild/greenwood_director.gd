## GreenwoodDirector — the stage systems of THE GREENWOOD (temporary Act XV stage
## 43, final stage 43; GDD §15.0 "The Greenwood (Act XV phase 2)"; owner-approved
## proposal docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 43: The
## Greenwood"), owned and stepped by EnemyDirector on a stage whose STAGE has a
## "greenwood" config (GreenwoodStage.GREENWOOD; `game.enemies.greenwood`, null
## elsewhere). The zones' floors and obstacles are MarchDirector's; the seasons,
## the blight, the thickets and Spring Returns the shared WildRules'. Here:
##   * THE SACRED GROVES (the stage mechanic: "rings of standing trees that heal
##     the Wild inside them; blighting a grove (holding the ring in it for
##     10 s) kills it for the run"): a grove may stand in each grove_cell px
##     cell (grove_in(), a pure hash: grove_chance, its centre kept grove_margin
##     px inside the cell, none within grove_clear px of the arena's centre), a
##     ring of grove_radius px drawn with grove_trees trees (drawing only: the
##     trees never collide). Every grove_every s, every Wild kind (not a boss,
##     a miniboss or a "no_bloom" row) inside a LIVING grove near a necromancer
##     heals grove_heal of its max HP a second (CombatResolver.heal_enemy(), on
##     top of the living ground's heal). A grove whose ground is blighted
##     (BloomField.blight_at(), the one ground read: the mean over its centre and
##     four points half its radius out, at grove_blight or more) for grove_kill
##     s in a row DIES for the run (it heals no more; drawn dead).
##   * THE HUNTSMAN OF THE WILD HUNT ("huntsman" event): the stage miniboss
##     comes in huntsman_dist px ahead of the necromancer with his three riders
##     (HuntsmanKit brings them); tracked for the objective and the report.
##   * SCORCHED EARTH (the stage's achievement: "blight half the Greenwood in
##     one run"): the Greenwood's area is scorched_area blight cells; once the
##     blight's peak (BloomField.peak_cells) reaches half of it the run stat
##     SCORCHED_STAT is set (MetaProgress counts it) and a banner shows.
## Deterministic: game time, pure hashes and positions only. Stats:
## grove_heal, groves_killed, groves_nearby_peak, huntsman_spawned,
## huntsman_killed.
class_name GreenwoodDirector
extends Node2D

## Run stat set (1) by a Greenwood run whose blight covered half the Greenwood
## (Scorched Earth; MetaProgress).
const SCORCHED_STAT: String = "greenwood_scorched_earth"
## Grove cells looked at round each necromancer, each way (the groves near him).
const NEAR_CELLS: int = 2

## Owning run.
var game: Game
## The stage's config (GreenwoodStage.GREENWOOD).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Grove cell (Vector2i) -> game time (s) it died.
var dead: Dictionary = {}
## Grove cell (Vector2i) -> seconds its ground has been blighted in a row.
var blighted: Dictionary = {}
## "m:ss" the Huntsman fell ("" while alive / never spawned).
var huntsman_time: String = ""
## "EARNED" / "" (open): Scorched Earth.
var scorched: String = ""
## Game time (s) of the next grove check.
var _next: float = 0.0
## The Huntsman once spawned (null before / after; generation-checked).
var _huntsman: Enemy = null
## Generation of `_huntsman` when he spawned.
var _huntsman_gen: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## The grove cell under the necromancer's view last drawn (redraw on a change).
var _drawn_at: Vector2i = Vector2i(2147483647, 0)


func _ready() -> void:
	z_index = -7  # Over the blight (-8), under the obstacles (-6) and every body.
	z_as_relative = false
	_draws = DisplayServer.get_name() != "headless"


## The grove of cell `c` (a pure hash of the cell): Vector3(x, y, radius) in
## world px, radius 0 when the cell holds none. Read by the director (heal,
## blight, drawing) and the autopilot alike.
static func grove_in(c: Vector2i, cfg: Dictionary) -> Vector3:
	var size := float(cfg["grove_cell"])
	var h := absi(hash(Vector3i(c.x, c.y, int(cfg["grove_salt"]))))
	if float(h % 1000) / 1000.0 >= float(cfg["grove_chance"]):
		return Vector3.ZERO
	var m := float(cfg["grove_margin"]) + float(cfg["grove_radius"])
	var span := size - 2.0 * m
	var p := Vector2(c) * size + Vector2(m + float((h >> 10) % 1000) / 1000.0 * span, m + float((h >> 20) % 1000) / 1000.0 * span)
	if p.length() < float(cfg["grove_clear"]):
		return Vector3.ZERO
	return Vector3(p.x, p.y, float(cfg["grove_radius"]))


## The grove cell of world point `p`.
func cell_of(p: Vector2) -> Vector2i:
	var size := float(config["grove_cell"])
	return Vector2i(floori(p.x / size), floori(p.y / size))


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	if _huntsman != null and not (_huntsman.active and _huntsman.generation == _huntsman_gen):
		_huntsman = null
		game.stat_add("huntsman_killed", 1.0)
		huntsman_time = _clock()
		_log("huntsman_down")
	if scorched == "" and game.wild != null and game.wild.bloom.enabled \
			and game.wild.bloom.peak_cells * 2 >= int(config["scorched_area"]):
		scorched = "EARNED"
		game.stats[SCORCHED_STAT] = 1.0
		game.enemies.show_banner(String(config.get("scorched_banner", "SCORCHED EARTH")))
		_log("scorched_earth")
	if now >= _next and game.wild != null:
		var dt := float(config["grove_every"])
		_next = now + dt
		_step_groves(dt)
	if _draws:
		var c := cell_of(game.player.position)
		if c != _drawn_at:
			_drawn_at = c
			queue_redraw()


# =====================================================================================
# The sacred groves
# =====================================================================================

## The groves near every standing necromancer: their heal and their blight.
func _step_groves(dt: float) -> void:
	var seen: Dictionary = {}  # Grove cells handled this check.
	for pl in game.all_players:
		if pl.dead:
			continue
		var pc := cell_of(pl.position)
		for dy in range(-NEAR_CELLS, NEAR_CELLS + 1):
			for dx in range(-NEAR_CELLS, NEAR_CELLS + 1):
				var c := pc + Vector2i(dx, dy)
				if seen.has(c) or dead.has(c):
					continue
				seen[c] = true
				var g := grove_in(c, config)
				if g.z <= 0.0:
					continue
				_grove_blight(c, Vector2(g.x, g.y), g.z, dt)
				if not dead.has(c):
					_grove_heal(Vector2(g.x, g.y), g.z, dt)
	game.stats["groves_nearby_peak"] = maxf(float(game.stats.get("groves_nearby_peak", 0.0)), float(seen.size()))


## The blight over grove `c` (centre `at`, radius `r`): held at grove_blight or
## more for grove_kill s in a row, it dies.
func _grove_blight(c: Vector2i, at: Vector2, r: float, dt: float) -> void:
	var b := game.wild.bloom
	var mean := b.blight_at(at)
	for k in 4:
		mean += b.blight_at(at + Vector2.from_angle(TAU * float(k) / 4.0) * r * 0.5)
	mean /= 5.0
	if mean < float(config["grove_blight"]):
		blighted.erase(c)
		return
	var t := float(blighted.get(c, 0.0)) + dt
	blighted[c] = t
	if t >= float(config["grove_kill"]):
		blighted.erase(c)
		dead[c] = game.elapsed
		game.stat_add("groves_killed", 1.0)
		game.wild.play_sound("grove_dies", at, 0.5)
		game.effects.ring(at, r, Palette.WILD_ASH, 0.6)
		game.enemies.show_banner(String(config.get("grove_banner", "A sacred grove dies")))
		_log("grove_dies")
		if _draws:
			queue_redraw()


## A living grove at `at` (radius `r`) heals the Wild inside it.
func _grove_heal(at: Vector2, r: float, dt: float) -> void:
	var share := float(config["grove_heal"]) * dt
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_miniboss or e.hp >= e.max_hp or not (e.kit is WildKit) or bool((e.kit as WildKit).d.get("no_bloom", false)):
			continue
		if e.position.distance_to(at) <= r:
			game.stat_add("grove_heal", game.combat.heal_enemy(e, e.max_hp * share))


## The autopilot's errand when calm: the nearest living grove within `reach` px
## of `p` (its centre, to blight it), Vector2.INF when none.
func seek_point(p: Vector2, reach: float) -> Vector2:
	var pc := cell_of(p)
	var best := Vector2.INF
	var best_d := reach
	for dy in range(-NEAR_CELLS, NEAR_CELLS + 1):
		for dx in range(-NEAR_CELLS, NEAR_CELLS + 1):
			var c := pc + Vector2i(dx, dy)
			if dead.has(c):
				continue
			var g := grove_in(c, config)
			if g.z <= 0.0:
				continue
			var d := p.distance_to(Vector2(g.x, g.y))
			if d < best_d:
				best_d = d
				best = Vector2(g.x, g.y)
	return best


# =====================================================================================
# The Huntsman of the Wild Hunt
# =====================================================================================

## Runs a Greenwood timeline event (EnemyDirector forwards the "huntsman"
## type; keys in GreenwoodStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "huntsman":
		return
	var pl := game.player
	var ahead := pl.velocity.normalized() if pl.velocity.length() > 5.0 else Vector2.RIGHT
	var at := game.arena.free_point(pl.position + ahead * float(ev.get("huntsman_dist", 300.0)), 22.0)
	var e := game.enemies.spawn_at(String(ev.get("kind", GreenwoodEnemyData.HUNTSMAN)), at, bool(ev.get("elite", false)))
	if e != null:
		_huntsman = e
		_huntsman_gen = e.generation
		game.stat_add("huntsman_spawned", 1.0)
	game.shake(6.0)
	if game.wild != null:
		game.wild.play_sound("hunt_horn", at, 1.0)
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("huntsman")


## The HUD objective while the Huntsman rides ("" otherwise).
func objective_override() -> String:
	if _huntsman != null:
		return String(config.get("huntsman_objective", ""))
	return ""


# =====================================================================================
# Drawing and report
# =====================================================================================

## The groves near the necromancer: a soft ring of moss and its trees (living:
## green crowns; dead: grey stumps). Disc textures, rects and the tree sprite;
## redrawn only when he crosses into another grove cell or a grove dies.
func _draw() -> void:
	var pc := cell_of(game.player.position)
	var tree := SpriteBank.texture(String(config["grove_tree_art"]))
	for dy in range(-NEAR_CELLS, NEAR_CELLS + 1):
		for dx in range(-NEAR_CELLS, NEAR_CELLS + 1):
			var c := pc + Vector2i(dx, dy)
			var g := grove_in(c, config)
			if g.z <= 0.0:
				continue
			var at := Vector2(g.x, g.y)
			var alive := not dead.has(c)
			SpriteBank.draw_disc(self, at, g.z, Color(Palette.WILD_MOSS if alive else Palette.WILD_BLIGHT, 0.16))
			var n := int(config["grove_trees"])
			for i in n:
				var tp := at + Vector2.from_angle(TAU * float(i) / float(n)) * g.z
				if tree != null and alive:
					SpriteBank.apply_sharp(self)
					draw_texture(tree, tp - Vector2(tree.get_width() * 0.5, tree.get_height() - 6.0))
					continue
				SpriteBank.draw_disc(self, tp + Vector2(2.0, 3.0), 9.0, Color(0, 0, 0, 0.3))
				SpriteBank.draw_disc(self, tp, 7.0, Palette.WILD_INK)
				SpriteBank.draw_disc(self, tp, 5.5, Palette.WILD_BARK if alive else Palette.WILD_ASH)  # The trunk.
				if alive:
					SpriteBank.draw_disc(self, tp + Vector2(0.0, -8.0), 9.0, Color(Palette.WILD_MOSS, 0.9))  # Its crown.


## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "sacred groves: near at most %d, killed %d, healed the Wild %d | huntsman spawned %d, killed %d%s (lines %d, riders %d) | scorched earth %s (blight peak %d of %d cells) | events: %s" % [
		int(st.get("groves_nearby_peak", 0.0)), int(st.get("groves_killed", 0.0)), int(st.get("grove_heal", 0.0)),
		int(st.get("huntsman_spawned", 0.0)), int(st.get("huntsman_killed", 0.0)), (" at " + huntsman_time) if huntsman_time != "" else "",
		int(st.get("huntsman_lines", 0.0)), int(st.get("huntsman_riders", 0.0)),
		scorched if scorched != "" else "open", game.wild.bloom.peak_cells if game.wild != null else 0, int(config["scorched_area"]),
		", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
