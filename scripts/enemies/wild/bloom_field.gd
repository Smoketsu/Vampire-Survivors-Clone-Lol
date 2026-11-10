## BloomField — BLOOM AND BLIGHT, the Turning Year's living ground (temporary
## Act XV; GDD §15.0 "Bloom and Blight"; owner-approved proposal: "Where the
## necromancer and his army stand, the grass slowly dies into blight; the
## Wild's creatures heal on living ground and not on blight. ... Spring regrows
## blight quickly; Autumn spreads it. One ground path (BloomField, a coarse
## grid)"), owned by Game.wild as `bloom`. THE one ground path: blight_at().
##   * A coarse grid of `cell` px cells holds blight 0..1 (sparse: only cells
##     with blight are stored). Every `sample` s, the cell under each standing
##     necromancer rises `rise_player` a second and every cell with a summon in
##     it `rise_army` a second (x (1 + Fallow Ground) once phase 2 builds it);
##     every cell regrows `regrow` a second (x spring_regrow_mult in Spring,
##     x autumn_regrow_mult in Autumn, when a full cell also gives each of its
##     4 neighbours `autumn_spread` a second).
##   * Every Wild kind (row faction "wild", not "no_bloom", never a boss) on
##     LIVING ground (blight under `living`) heals `heal` of its max HP a
##     second (CombatResolver.heal_enemy(), the one enemy-heal path); on blight
##     it does not.
##   * A cell at `full` is dead ground: thickets there wither (Thickets reads
##     blight_at()); Spring Returns wipes it all (wipe()).
## Drawn under the units (WildRules' under layer): a dark grey patch per
## blighted cell in view (rects only, redrawn every sample). Off the act (a
## forced Wild kind on another stage) it never runs. Determinism: game time and
## positions only; the grid is a Dictionary filled in a fixed order. Stats:
## bloom_heal (HP healed), blight_peak_cells, blight_full_peak.
class_name BloomField
extends RefCounted

## Owning run.
var game: Game
## True on a Wild stage: the ground lives; false off the act.
var enabled: bool = false
## The ground's numbers (WildRulesData.BLOOM + the stage's "bloom").
var cfg: Dictionary = {}
## Vector2i cell -> blight (0..1); only blighted cells, oldest first.
var cells: Dictionary = {}
## Most blighted cells at once this run (the report; Scorched Earth reads the area).
var peak_cells: int = 0
## Most full (dead) cells at once this run.
var peak_full: int = 0
## HP the Wild healed on living ground this run.
var healed: float = 0.0
## Game time (s) of the next sample.
var _next: float = 0.0
## 1 / cell, cached.
var _inv: float = 1.0


## Builds the ground for `p_game`; `p_enabled`: a Wild stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = WildRulesData.BLOOM.duplicate()
	var over: Dictionary = p_game.stage_def.get("bloom", {})
	for key: String in over:
		cfg[key] = over[key]
	_inv = 1.0 / float(cfg["cell"])


## The cell of world point `p`.
func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x * _inv), floori(p.y * _inv))


## THE ground read: blight (0 living .. 1 dead) under world point `p`.
func blight_at(p: Vector2) -> float:
	return float(cells.get(cell_of(p), 0.0))


## True when `p` is dead ground (blight at `full` or more).
func is_dead(p: Vector2) -> bool:
	return blight_at(p) >= float(cfg["full"])


## Spring Returns: every blighted cell grows back at once.
func wipe() -> void:
	cells.clear()


## THE one path that lowers blight (phase 2, the Spore Mother's blight-killing
## mould): every blighted cell whose centre lies within `r` px of `at` loses
## `cut` blight (a cell at 0 is living ground again). Returns the cells touched.
func mould(at: Vector2, r: float, cut: float) -> int:
	var size := float(cfg["cell"])
	var c0 := cell_of(at - Vector2.ONE * r)
	var c1 := cell_of(at + Vector2.ONE * r)
	var n := 0
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var c := Vector2i(cx, cy)
			if not cells.has(c) or (Vector2(c) * size + Vector2.ONE * size * 0.5).distance_to(at) > r:
				continue
			var v := float(cells[c]) - cut
			if v <= 0.0:
				cells.erase(c)
			else:
				cells[c] = v
			n += 1
	return n


## Per tick (WildRules.step()): one sample every `sample` s.
func step(_delta: float) -> void:
	if not enabled or game.elapsed < _next:
		return
	var dt := float(cfg["sample"])
	_next = game.elapsed + dt
	_rise(dt)
	_regrow(dt)
	_heal(dt)


## The army kills the ground under it (see the header).
func _rise(dt: float) -> void:
	var touched: Dictionary = {}  # Cells raised this sample (once each by the army).
	for pl in game.all_players:
		if not pl.dead:
			var c := cell_of(pl.position)
			cells[c] = minf(1.0, float(cells.get(c, 0.0)) + float(cfg["rise_player"]) * dt)
	var army := float(cfg["rise_army"]) * dt * game.wild.fallow_mult()  # Fallow Ground: exactly 1 until phase 2 builds it.
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies:
				continue
			var c := cell_of(u.position)
			if touched.has(c):
				continue
			touched[c] = true
			cells[c] = minf(1.0, float(cells.get(c, 0.0)) + army)


## The ground regrows (Spring faster, Autumn not at all and the blight spreads).
func _regrow(dt: float) -> void:
	var s := game.wild.seasons.season()
	var mult := 1.0
	if s == WildRulesData.SPRING:
		mult = float(cfg["spring_regrow_mult"])
	elif s == WildRulesData.AUTUMN:
		mult = float(cfg["autumn_regrow_mult"])
	var full := float(cfg["full"])
	var spread: Dictionary = {}  # Cell -> blight it gains from a full neighbour (Autumn).
	if s == WildRulesData.AUTUMN:
		var gift := float(cfg["autumn_spread"]) * dt
		for c: Vector2i in cells:
			if float(cells[c]) >= full:
				for n: Vector2i in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.UP, c + Vector2i.DOWN]:
					spread[n] = float(spread.get(n, 0.0)) + gift
	for n: Vector2i in spread:
		cells[n] = minf(1.0, float(cells.get(n, 0.0)) + float(spread[n]))
	var loss := float(cfg["regrow"]) * mult * dt
	var dead_cells := 0
	for c: Vector2i in cells.keys():
		var v := float(cells[c]) - loss
		if v <= 0.0:
			cells.erase(c)
		else:
			cells[c] = v
			if v >= full:
				dead_cells += 1
	while cells.size() > int(cfg["max_cells"]):
		cells.erase(cells.keys()[0])  # The oldest regrows first.
	if cells.size() > peak_cells:
		peak_cells = cells.size()
		game.stats["blight_peak_cells"] = float(peak_cells)
	if dead_cells > peak_full:
		peak_full = dead_cells
		game.stats["blight_full_peak"] = float(peak_full)


## The Wild heals on living ground (see the header).
func _heal(dt: float) -> void:
	var share := float(cfg["heal"]) * dt
	var living := float(cfg["living"])
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.hp >= e.max_hp or not (e.kit is WildKit) or bool((e.kit as WildKit).d.get("no_bloom", false)):
			continue
		if blight_at(e.position) < living:
			var h := game.combat.heal_enemy(e, e.max_hp * share)
			healed += h
			game.stat_add("bloom_heal", h)


## Draws every blighted cell within `reach` px of `around` on `ci` (the under
## layer): dead grey, darker with the blight (rects only).
func draw(ci: CanvasItem, around: Vector2, reach: float) -> void:
	var size := float(cfg["cell"])
	var full := float(cfg["full"])
	for c: Vector2i in cells:
		var at := Vector2(c) * size
		if absf(at.x - around.x) > reach or absf(at.y - around.y) > reach:
			continue
		var v := float(cells[c])
		ci.draw_rect(Rect2(at, Vector2(size, size)), Color(Palette.WILD_BLIGHT, 0.2 + 0.5 * v))
		if v >= full:
			ci.draw_rect(Rect2(at + Vector2(size * 0.3, size * 0.4), Vector2(size * 0.25, 2.0)), Color(Palette.WILD_ASH, 0.6))  # Dead grass.
