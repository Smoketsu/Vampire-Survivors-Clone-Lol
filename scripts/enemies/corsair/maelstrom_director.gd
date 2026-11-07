## MaelstromDirector — the Maelstrom's own rules (Act X, the Black Tide's finale;
## GDD §15.0 "The Maelstrom (Act X phase 2)"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Stage C: The Maelstrom"),
## switched on by the STAGE key "maelstrom" (MaelstromStage.MAELSTROM), created
## and stepped by EnemyDirector after the MarchDirector (null on every other
## stage). It owns ONE path each for:
##   * THE HEAVE ("The whirlpool tilts the deck. Everyone slides toward the low
##     side at 30 px/s, and the low side flips every 12 s with a 3 s creaking
##     telegraph and a HUD arrow"): from heave "first" s the deck lists toward
##     a LOW SIDE (a rail; the first one seeded) that flips every `period` s;
##     for the last `telegraph` s before a flip the hull creaks and the HUD
##     objective names the coming side (an arrow in text, never a screen
##     effect). Each tick everything slides toward the low rail at `speed`
##     x the zone's "heave" (MaelstromStage.ZONES: the Eye of the Storm lies
##     level): the necromancer (stopped at the rail by DeckBounds), the army
##     through TerrainSlow.push_summon() x CorsairRules.sea_legs_mult() (Sea
##     Legs halves it; fliers and airborne units are spared, as by every
##     push), and every deck enemy through its knockback, held at
##     `enemy_knock` toward the low rail (a blow at the low rail tips it over:
##     DeckBounds drowns from 70 px/s; bosses, minibosses, structures and
##     swimmers stand). Vandermere's Maelstrom (set_peak()) multiplies the
##     slide and the knock by peak_mult (80 px/s: the low rail drowns what is
##     pressed on it) and flips every peak_period s. When Vandermere falls the
##     whirlpool closes: the deck lies level for the rest of the run.
##   * THE BROTHERHOOD'S OWN DEAD ("Ghost crews do leave corpses ... so the
##     necromancer raises the Brotherhood's own dead here"): a ghost crewman
##     (MaelstromEnemyData "ghost") that falls ON THE DECK within raise "reach"
##     px of a standing necromancer rises for him at once through
##     HordeDirector.raise_corpse() (the one raise path; co-op: the nearest
##     necromancer's army, bound for the call), a temporary `class` for `life`
##     s, at most `cap` at once (a fall past the cap, or one that drowned,
##     stays dead). Every raise chips Vandermere's Oath (BossVandermere
##     .oath_chip()) while he stands.
##   * THE GHOST BOSUN (the miniboss, EVENTS type "ghost_bosun"): he climbs
##     over a seeded rail point near the necromancer (EnemyDirector.spawn_at():
##     not a boat) and his whistle (GhostBosunKit) calls bosun_whistle(): a
##     spectral longboat with his drowned crew (BoardingParty.launch_boat()).
##   * VANDERMERE'S CREW: launch_crew() (the same longboats); the ghost boats
##     circling the gyre are drawn here (visual only).
## The autotest bot leans uphill and away from the low rail (danger_push(),
## through CorsairRules.danger_push()). Draws the low rail's chevrons and the
## circling ghost boats (z -5, under every body; rects and sprites only).
## Determinism: game time and the seeded gameplay RNG (the first low side, the
## Bosun's rail point), only while it exists (the Maelstrom). Stats: heave_*,
## ghost_raised, ghost_raise_*, ghost_bosun_*, maelstrom_* (the report's
## "maelstrom" line).
class_name MaelstromDirector
extends Node2D

## Owning run.
var game: Game
## The stage's MAELSTROM dictionary (MaelstromStage.MAELSTROM).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## The Heave's low side: +1 the lower rail, -1 the upper rail (0 = level).
var side: int = 0
## Game time (s) of the next flip (-1 = not scheduled: the deck is level).
var next_flip: float = -1.0
## True while Vandermere's Maelstrom makes the tilt peak.
var peak: bool = false
## True once the whirlpool closed (Vandermere fell): the deck stays level.
var closed: bool = false
## Flips so far (the report).
var flips: int = 0
## True once this flip's telegraph creaked.
var _creaked: bool = false
## Raised ghosts standing: [SummonedUnit, generation].
var _raised: Array = []
## The Ghost Bosun while he stands (null otherwise).
var _bosun: Enemy = null
## His generation at the spawn (stale-reference guard).
var _bosun_gen: int = 0
## True once the boss's fall was hooked (EnemyDirector.boss_defeated).
var _hooked: bool = false
## Overboard count at the last tick (the Heave's drownings).
var _drowned_seen: int = 0
## Angle (rad) of the circling ghost boats (visual only).
var _boats_a: float = 0.0


func _ready() -> void:
	z_index = -5  # On the deck and the sea, under every body (as CorsairRules).


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	if not _hooked:
		_hooked = true
		game.enemies.boss_defeated.connect(_on_boss_defeated)
	if game.deck == null:
		return
	_step_heave(delta)
	_prune()
	if _bosun != null and not (_bosun.active and _bosun.generation == _bosun_gen):
		_bosun = null
		game.stat_add("ghost_bosun_killed", 1.0)
		_log("bosun_killed")
	_boats_a += float((config["ghost_boats"] as Dictionary)["turn"]) * delta
	queue_redraw()


# =====================================================================================
# The Heave
# =====================================================================================

## The Heave's numbers (MaelstromStage.MAELSTROM "heave").
func _cfg() -> Dictionary:
	return config["heave"]


## x the slide of the current zone (MaelstromStage.ZONES "heave"; 1 without zones).
func zone_mult() -> float:
	var m := game.enemies.march
	if m == null:
		return 1.0
	var zones: Array = m.config["zones"]
	return float((zones[m.zone_index] as Dictionary).get("heave", 1.0))


## True while the deck lists (the Heave runs and slides everything).
func heaving() -> bool:
	return side != 0


## The rail the deck lists toward (+1 lower, -1 upper; 0 while level).
func low_side() -> int:
	return side


## Vandermere's Maelstrom: the tilt peaks (on) or eases back (off).
func set_peak(on: bool) -> void:
	if peak == on:
		return
	peak = on
	_log("maelstrom_peak" if on else "maelstrom_eased")
	if on and next_flip > game.elapsed + _period():
		next_flip = game.elapsed + _period()


## Seconds between two flips (shorter while the tilt peaks).
func _period() -> float:
	return float(_cfg()["peak_period"] if peak else _cfg()["period"])


## x the slide and the knock now (the zone, the peak).
func _mult() -> float:
	return zone_mult() * (float(_cfg()["peak_mult"]) if peak else 1.0)


## The Heave's clock, the flips and the slide.
func _step_heave(delta: float) -> void:
	var now := game.elapsed
	var want := not closed and now >= float(_cfg()["first"]) and zone_mult() > 0.0
	if not want:
		if side != 0:
			side = 0
			next_flip = -1.0
			_log("level")
		_drowned_seen = game.deck.drowned
		return
	if side == 0:
		side = 1 if randf() < 0.5 else -1  # The first low side of this list: seeded.
		next_flip = now + _period()
		_creaked = false
		_log("heave_" + ("down" if side > 0 else "up"))
	if not _creaked and now >= next_flip - float(_cfg()["telegraph"]):
		_creaked = true
		game.stat_add("heave_telegraphs", 1.0)
		if game.corsair != null:
			game.corsair.play_sound("heave_creak", game.player.position, 1.0)
	if now >= next_flip:
		side = -side
		flips += 1
		next_flip = now + _period()
		_creaked = false
		game.stat_add("heave_flips", 1.0)
		game.shake(1.5)
	_slide(delta)
	var d := game.deck.drowned - _drowned_seen  # Overboard since the last tick (this tick's contain ran after it).
	if d > 0:
		game.stat_add("heave_drowned", float(d))
	_drowned_seen = game.deck.drowned
	game.stat_add("heave_time", delta)


## Everything slides toward the low rail this tick (see the header).
func _slide(delta: float) -> void:
	var dir := Vector2(0.0, float(side))
	var v := dir * float(_cfg()["speed"]) * _mult()
	for pl in game.all_players:
		if not pl.dead and not game.grave_step.is_dashing():
			pl.position += v * delta
	for h in game.all_hordes:
		for u in h.units:
			TerrainSlow.push_summon(game, u, v * game.corsair.sea_legs_mult(u), delta)
	var knock := float(_cfg()["enemy_knock"]) * _mult()
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.untargetable or e.flies or CorsairKit.is_in_water(e):
			continue
		var along := e.knockback.dot(dir)
		if along < knock:
			e.knockback += dir * (knock - along)


# =====================================================================================
# The Brotherhood's own dead
# =====================================================================================

## A ghost crewman fell (GhostCrewKit.on_killed()): on the deck and near a
## standing necromancer, he rises for him (see the header).
func on_ghost_died(e: Enemy) -> void:
	var rc: Dictionary = config["raise"]
	if game.deck.is_water(e.position):
		game.stat_add("ghost_raise_drowned", 1.0)
		return
	var pl := game.nearest_player(e.position)
	if pl == null or pl.dead or pl.position.distance_to(e.position) > float(rc["reach"]):
		game.stat_add("ghost_raise_far", 1.0)
		return
	_prune()
	if _raised.size() >= int(rc["cap"]):
		game.stat_add("ghost_raise_capped", 1.0)
		return
	var prev := -1
	if game.coop != null:
		prev = game.coop.bound
		game.coop.bind_nearest(e.position)
	var u := game.horde.raise_corpse(String(rc["class"]), e.position, float(rc["life"]), float(rc["hp_mult"]), float(rc["dmg_mult"]),
			String(rc["tag"]), "risen", false)
	if prev >= 0:
		game.coop.bind(prev)
	if u == null:
		return
	_raised.append([u, u.generation])
	game.stat_add("ghost_raised", 1.0)
	game.effects.ring(u.position, 18.0, Palette.CORSAIR_SPECTRE_LIGHT, 0.4)
	if game.corsair != null:
		game.corsair.play_sound("ghost_rise", u.position, 0.35)
	var b := game.enemies.boss
	if b is BossVandermere and b.active:
		(b as BossVandermere).oath_chip()


## Drops raised ghosts that crumbled or fell.
func _prune() -> void:
	var i := 0
	while i < _raised.size():
		var u: SummonedUnit = _raised[i][0]
		if not u.active or u.generation != int(_raised[i][1]):
			_raised.remove_at(i)
			continue
		i += 1


# =====================================================================================
# The Ghost Bosun, the spectral longboats
# =====================================================================================

## Runs a Maelstrom timeline event (EnemyDirector forwards the "ghost_bosun"
## type; keys in MaelstromStage.EVENTS): he climbs over a seeded rail point near
## the necromancer.
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "ghost_bosun":
		return
	var rail_side := 1 if randf() < 0.5 else -1
	var x := game.player.position.x - game.deck.center.x + (randf() - 0.5) * 300.0
	var at := game.deck.rail_point(x, rail_side) - Vector2(0.0, float(rail_side)) * 30.0
	var e := game.enemies.spawn_at(String(ev.get("kind", MaelstromEnemyData.GHOST_BOSUN)), at, false)
	if e == null:
		return
	_bosun = e
	_bosun_gen = e.generation
	game.stat_add("ghost_bosun_spawned", 1.0)
	game.effects.ring(at, 30.0, Palette.CORSAIR_SPECTRE_LIGHT, 0.5)
	game.shake(3.0)
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("ghost_bosun")


## The Ghost Bosun's whistle (GhostBosunKit): a spectral longboat with his crew.
func bosun_whistle(_e: Enemy, w: Dictionary) -> void:
	game.stat_add("ghost_bosun_boats", float(launch_crew(1, int(w.get("crew", 8)), int(w.get("gunners", 2)))))


## Launches `boats` spectral longboats, each with `size` drowned crewmen
## (`gunners` of them Ghost Gunners, the rest Ghost Deckhands) through
## BoardingParty.launch_boat(). Returns how many launched.
func launch_crew(boats: int, size: int, gunners: int) -> int:
	if game.corsair == null or not game.corsair.enabled:
		return 0
	var kinds: Array = []  # The deckhands step aboard first, the gunners last.
	for i in size:
		kinds.append(MaelstromEnemyData.GHOST_GUNNER if i >= size - gunners else MaelstromEnemyData.GHOST_DECKHAND)
	var n := 0
	for b in boats:
		if game.corsair.boarding.launch_boat(MaelstromEnemyData.GHOST_LONGBOAT, kinds, game.enemies.hp_mult):
			n += 1
	game.stat_add("maelstrom_ghost_boats", float(n))
	return n


## The HUD objective: the Ghost Bosun while he stands, else the Heave's arrow
## (the low side, or the side it is about to tip to); "" when level.
func objective_override() -> String:
	if _bosun != null and _bosun.active and _bosun.generation == _bosun_gen:
		return String((config["bosun"] as Dictionary)["objective"])
	if side == 0:
		return ""
	if _creaked:
		return "The hull creaks: the deck tips %s" % _arrow(-side)
	return "The deck heaves: sliding %s" % _arrow(side)


## Text arrow of a rail side (+1 lower, -1 upper).
static func _arrow(s: int) -> String:
	return "DOWN  v v v" if s > 0 else "UP  ^ ^ ^"


# =====================================================================================
# The boss, the autopilot
# =====================================================================================

## The stage boss fell (EnemyDirector.boss_defeated): the whirlpool closes;
## Vandermere fallen with his Oath broken three times sets Dead Men Tell Tales.
func _on_boss_defeated() -> void:
	on_boss_down()
	var b := game.enemies.boss
	if b is BossVandermere and (b as BossVandermere).breaks >= VandermereData.TALES_BREAKS:
		game.stats[VandermereData.TALES_STAT] = 1.0
		_log("dead_men_tell_tales")


## The whirlpool closes: the deck lies level for the rest of the run.
func on_boss_down() -> void:
	if closed:
		return
	closed = true
	peak = false
	_log("whirlpool_closed")


## The autotest autopilot's lean uphill while the deck lists (stronger near
## the low rail), and toward the coming high side while it creaks.
func danger_push(p: Vector2) -> Vector2:
	if side == 0:
		return Vector2.ZERO
	var down := float(-side if _creaked else side)
	var depth := absf(game.deck.center.y + game.deck.half_beam * down - p.y)  # px from the (coming) low rail.
	var near := 1.0 - clampf(depth / (game.deck.half_beam * 2.0), 0.0, 1.0)
	return Vector2(0.0, -down) * float(_cfg()["lean"]) * (0.5 + near)


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## The low rail's chevrons (the slide's direction) and the ghost boats circling
## the gyre. Rects and sprites only.
func _draw() -> void:
	if game == null or game.deck == null:
		return
	var deck := game.deck
	var gb: Dictionary = config["ghost_boats"]
	if not closed:
		var n := int(gb["count"])
		for i in n:
			var a := _boats_a + TAU * float(i) / float(n)
			var at := deck.center + Vector2(cos(a) * (deck.half_length + float(gb["out"])), sin(a) * (deck.half_beam + float(gb["out"])))
			SpriteBank.draw(self, "corsair/ghost_longboat", at, false, Color(Palette.CORSAIR_SPECTRE_LIGHT, float(gb["alpha"])))
	if side == 0:
		return
	var s := float(-side if _creaked else side)
	var col := Color(Palette.CORSAIR_LANTERN, 0.55) if _creaked else Color(Palette.CORSAIR_SPECTRE_LIGHT, 0.35)
	var k := int(_cfg()["chevrons"])
	var y := deck.center.y + s * (deck.half_beam - 26.0)
	var span := deck.half_length * 1.4
	for i in k:
		var x := deck.center.x - span * 0.5 + span * float(i) / float(maxi(1, k - 1))
		var tip := Vector2(x, y + s * 6.0)
		draw_rect(Rect2(tip + Vector2(-7.0, -s * 6.0 - 1.5), Vector2(6.0, 3.0)), col)
		draw_rect(Rect2(tip + Vector2(1.0, -s * 6.0 - 1.5), Vector2(6.0, 3.0)), col)
		draw_rect(Rect2(tip + Vector2(-2.0, -1.5), Vector2(4.0, 3.0)), col)


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "heave flips %d (telegraphs %d, listing %.0f s, drowned while listing %d) | peak %s, whirlpool closed %s | ghosts raised %d (far %d, capped %d, drowned %d) | spectral longboats %d | ghost bosun spawned %d, whistles %d, boats %d, killed %d | events: %s" % [
		flips, int(st.get("heave_telegraphs", 0.0)), float(st.get("heave_time", 0.0)), int(st.get("heave_drowned", 0.0)),
		str(peak), str(closed), int(st.get("ghost_raised", 0.0)), int(st.get("ghost_raise_far", 0.0)),
		int(st.get("ghost_raise_capped", 0.0)), int(st.get("ghost_raise_drowned", 0.0)), int(st.get("maelstrom_ghost_boats", 0.0)),
		int(st.get("ghost_bosun_spawned", 0.0)), int(st.get("ghost_bosun_whistles", 0.0)), int(st.get("ghost_bosun_boats", 0.0)),
		int(st.get("ghost_bosun_killed", 0.0)), ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	var t := int(game.elapsed)
	fired.append("%d:%02d %s" % [t / 60, t % 60, what])
