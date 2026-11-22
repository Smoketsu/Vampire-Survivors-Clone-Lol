## RuneStones — THE RUNE-STONES, the third of the Hall of the Slain's shared
## rules (the Norse act, temporarily Act XI; GDD §15.0 "Rune-Stones"; the act's
## section of docs/proposals/LAST_SIX_ACTS.md: "Three or four carved stones per
## stage. Held by the hall, a stone wards Norse warriors within 300 px (-25%
## damage taken) and blows a horn that calls a squad every 60 s. The necromancer
## takes one by standing within 120 px with more bodies than the hall for 3 s
## (a ring fills around it): its ward and horn stop and it pays Soul Ash. Seers
## walk back to re-carve it. Taking a stone never buffs the army (summons never
## get act-only rules). One structure path, RuneStones."), owned by Game.norse
## as `stones`. THE ONE PATH of every stone (a stone is not an Enemy: nothing
## targets, hurts or kills it; it is drawn and run here):
##   * raise_stone(at, opts): THE public call. A stone rises at `at` (moved out
##     of obstacles, kept clear of new ones: Arena.keep_clear()), HELD by the
##     hall, at most max_stones standing. The stage timelines raise them
##     through the event type "rune_stone" (start_event(): `count` stones
##     around the necromancer between dist_min and dist_max px, spaced, at
##     seeded angles); --spawn=rune_stone raises one where it spawns
##     (RuneStoneKit).
##   * THE WARD: ward_mult(e) — every Norse kind (NorseKit.taken_mult(), the
##     one read) within ward_radius px of a held stone takes ward_taken of
##     every hit (counted: rune_ward_hits). Never the army's.
##   * THE HORN: horn_first s after it rises, then every horn_every s, a held
##     stone within horn_reach px of a necromancer calls a squad (a seeded
##     weighted pick of its table, out of the stone's edge, while the hard cap
##     leaves room) and emits `horn_blown` (phase 2's Feast wakes the
##     Einherjar at the tables on it).
##   * THE CAPTURE: while a standing necromancer is within capture_radius px of
##     a held stone and the necromancers plus the summons inside outnumber the
##     Norse enemies inside, its capture fills (a ring of dots); capture_time s
##     takes it: its ward and horn stop and, the first time only, it pays
##     ash_per_take Soul Ash through the objective bounty path (stat
##     "objective_ash"). Otherwise the capture drains at capture_decay s per s.
##   * THE RE-CARVING: carve(stone, amount) — a seer standing within
##     carve_radius px of a taken stone (SeerKit; nearest_taken() finds it
##     within carve_seek px) carves it; carve_time s of carving gives it back
##     to the hall (its horn restarts after horn_first s).
##   * The autotest bot's one stone-taking behaviour: seek_point().
## A stage's STAGE "rune_stones" dictionary overrides any RUNE_STONES key ({}
## = the defaults). Determinism: the seeded gameplay RNG only (placements,
## squads), only while the Norse rules exist. Drawing: textures only (the
## stone's sprite, else its glyph; the rings of disc textures), never headless.
## Stats: rune_stones_raised, rune_stones_refused, rune_stones_taken,
## rune_stones_recarved, rune_take_ash, rune_horns, rune_horn_units,
## rune_horns_capped, rune_ward_hits.
class_name RuneStones
extends Node2D

## A horn sounded at world point `at` (phase 2: the Feast wakes on it).
signal horn_blown(at: Vector2)

## One standing stone.
class Stone:
	extends RefCounted
	## World position (px).
	var pos: Vector2 = Vector2.ZERO
	## True while the hall holds it (ward and horn on); false once taken.
	var held: bool = true
	## Capture progress (s of the necromancer's side outnumbering the hall).
	var capture: float = 0.0
	## Re-carving progress (s of seers carving a taken stone).
	var carve: float = 0.0
	## Game time (s) of its next horn.
	var next_horn: float = 0.0
	## True once it paid its Soul Ash (the first take only).
	var paid: bool = false
	## Times it was taken.
	var taken: int = 0
	## Its squad table (rows {kind, count, weight[, elite]}).
	var table: Array = []


## Owning run.
var game: Game
## The stones' numbers (RUNE_STONES, then the stage's "rune_stones").
var cfg: Dictionary = {}
## Standing stones, in rising order.
var stones: Array[Stone] = []
## Stones raised this run.
var raised: int = 0
## Takes this run (re-takes included).
var taken: int = 0
## Re-carvings this run.
var recarved: int = 0
## Horns blown this run.
var horns: int = 0
## Soul Ash the stones paid this run.
var take_ash: float = 0.0
## "m:ss" of each take (the autotest line).
var take_times: PackedStringArray = PackedStringArray()
## Rune-stone bodies to take off the field on the next step ([Enemy,
## generation] pairs; RuneStoneKit, --spawn=rune_stone).
var _discard: Array = []
## Scratch for the grid queries.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false


## Builds the stones for `p_game` (NorseRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "RuneStones"
	z_index = -6  # The rings and the stones lie on the ground layer, under the bodies (as the braziers).
	z_as_relative = false
	cfg = NorseRulesData.RUNE_STONES.duplicate()
	var over: Dictionary = p_game.stage_def.get("rune_stones", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE public call: a stone the hall holds rises at world point `at`. opts (all
## optional): "table" (its squad rows), "horn_first" (s), "silent" (bool).
## Returns its index, or -1 when max_stones stand.
func raise_stone(at: Vector2, opts: Dictionary = {}) -> int:
	if stones.size() >= int(cfg["max_stones"]):
		game.stat_add("rune_stones_refused", 1.0)
		return -1
	var r := float(cfg["body_radius"])
	var s := Stone.new()
	s.pos = game.arena.free_point(at, r)
	game.arena.keep_clear(s.pos, r + ArenaData.MAX_HALF_EXTENT * 1.5)
	s.table = opts.get("table", cfg["table"])
	s.next_horn = game.elapsed + float(opts.get("horn_first", cfg["horn_first"]))
	stones.append(s)
	raised += 1
	game.stat_add("rune_stones_raised", 1.0)
	game.effects.ring(s.pos, 40.0, Palette.NORSE_RUNE, 0.6)
	if not bool(opts.get("silent", false)) and game.norse != null:
		game.norse.play_sound("stone_carved", s.pos)
	if _draws:
		queue_redraw()
	return stones.size() - 1


## A timeline "rune_stone" event (EnemyDirector forwards it): `count` stones
## around the necromancer, spread from a seeded angle, between distance_min
## and distance_max px (RUNE_STONES dist_min / dist_max when absent), spaced;
## then the banner. Event keys: count, banner, distance_min, distance_max,
## table (all optional but count).
func start_event(ev: Dictionary) -> void:
	var n := int(ev.get("count", 1))
	var p := game.player.position
	var offset := randf() * TAU  # Angle of the first stone.
	var opts := {}
	if ev.has("table"):
		opts["table"] = ev["table"]
	var made := 0
	for i in n:
		var best := p
		for _try in int(cfg["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			var dd := randf_range(float(ev.get("distance_min", cfg["dist_min"])), float(ev.get("distance_max", cfg["dist_max"])))
			var pos := game.arena.free_point(p + Vector2.from_angle(a) * dd, float(cfg["body_radius"]))
			var spaced := true
			for s in stones:
				spaced = spaced and s.pos.distance_to(pos) >= float(cfg["spacing"])
			best = pos
			if spaced:
				break
		if raise_stone(best, opts) >= 0:
			made += 1
	if made > 0 and String(ev.get("banner", "")) != "":
		game.enemies.show_banner(String(ev["banner"]))


## THE WARD (NorseKit.taken_mult(), the one read): the share of a hit Norse
## enemy `e` takes: ward_taken within ward_radius px of a stone the hall holds,
## else 1.
func ward_mult(e: Enemy) -> float:
	if stones.is_empty():
		return 1.0
	var wr := float(cfg["ward_radius"])
	for s in stones:
		if s.held and s.pos.distance_squared_to(e.position) <= wr * wr:
			game.stat_add("rune_ward_hits", 1.0)
			return float(cfg["ward_taken"])
	return 1.0


## True when world point `p` lies in the ward of a stone the hall holds.
func warded(p: Vector2) -> bool:
	var wr := float(cfg["ward_radius"])
	for s in stones:
		if s.held and s.pos.distance_squared_to(p) <= wr * wr:
			return true
	return false


## Index of the nearest TAKEN stone within `reach` px of `p` (a seer's walk), or -1.
func nearest_taken(p: Vector2, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for i in stones.size():
		var s := stones[i]
		if s.held:
			continue
		var dsq := s.pos.distance_squared_to(p)
		if dsq < best_d:
			best_d = dsq
			best = i
	return best


## A seer carves stone `idx` for `amount` s (SeerKit). carve_time s give it
## back to the hall. Returns true when this carve finished it.
func carve(idx: int, amount: float) -> bool:
	if idx < 0 or idx >= stones.size():
		return false
	var s := stones[idx]
	if s.held:
		return false
	s.carve += amount
	if s.carve < float(cfg["carve_time"]):
		return false
	s.held = true
	s.carve = 0.0
	s.capture = 0.0
	s.next_horn = game.elapsed + float(cfg["horn_first"])
	recarved += 1
	game.stat_add("rune_stones_recarved", 1.0)
	game.effects.ring(s.pos, 50.0, Palette.NORSE_RUNE, 0.6)
	game.enemies.show_banner("A seer re-carves a rune-stone! The hall holds it again")
	if game.norse != null:
		game.norse.play_sound("stone_carved", s.pos, 1.0)
	if _draws:
		queue_redraw()
	return true


## Autotest bot (the one stone-taking behaviour): the nearest stone the hall
## holds within `reach` px of `p` (its centre), or Vector2.INF. A stone whose
## capture is under way counts as half as far (the bot finishes it).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for s in stones:
		if not s.held:
			continue
		var dd := p.distance_to(s.pos) * (0.5 if s.capture > 0.0 else 1.0)  # Effective distance (px).
		if dd < best_d:
			best = s.pos
			best_d = dd
	return best


## A rune_stone ENEMY body `e` (RuneStoneKit) handed its spot to raise_stone():
## it leaves the field without a kill on the next step.
func discard_body(e: Enemy) -> void:
	_discard.append([e, e.generation])


## Stones the hall holds now.
func held_count() -> int:
	var n := 0
	for s in stones:
		if s.held:
			n += 1
	return n


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (NorseRules.step()): captures and horns.
func step(delta: float) -> void:
	for pair: Array in _discard:
		var b: Enemy = pair[0]
		if b.active and b.generation == int(pair[1]):
			game.enemies.despawn(b)
	_discard.clear()
	if stones.is_empty():
		return
	var now := game.elapsed
	var cr := float(cfg["capture_radius"])
	var hr := float(cfg["horn_reach"])
	var busy := false  # Something to redraw.
	for s in stones:
		if not s.held:
			busy = busy or s.carve > 0.0
			continue
		var inside := 0  # Standing necromancers in the capture ring.
		var near := false  # A necromancer within horn_reach.
		for pl in game.all_players:
			if pl.dead:
				continue
			var dsq := pl.position.distance_squared_to(s.pos)
			near = near or dsq <= hr * hr
			if dsq <= cr * cr:
				inside += 1
		if inside > 0 and _ours(s.pos, cr) + inside > _theirs(s.pos, cr):
			s.capture += delta
			busy = true
			if s.capture >= float(cfg["capture_time"]):
				_on_taken(s)
				continue
		elif s.capture > 0.0:
			s.capture = maxf(0.0, s.capture - float(cfg["capture_decay"]) * delta)
			busy = true
		if now >= s.next_horn:
			s.next_horn = now + float(cfg["horn_every"])
			if near:
				_horn(s)
	if _draws and (busy or Engine.get_physics_frames() % 6 == 0):
		queue_redraw()


## Summons standing inside the ring of radius `r` at `at`.
func _ours(at: Vector2, r: float) -> int:
	var n := 0
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.DEAD and u.state != SummonedUnit.State.SPAWNING \
				and u.position.distance_squared_to(at) <= r * r:
			n += 1
	return n


## Norse enemies standing inside the ring of radius `r` at `at`.
func _theirs(at: Vector2, r: float) -> int:
	var n := 0
	game.enemy_grid.query(at, r + 30.0, _tmp)
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and e.kit is NorseKit and e.position.distance_squared_to(at) <= r * r:
			n += 1
	return n


## Stone `s` is taken: its ward and horn stop; the first time it pays its Soul Ash.
func _on_taken(s: Stone) -> void:
	s.held = false
	s.capture = 0.0
	s.carve = 0.0
	s.taken += 1
	taken += 1
	take_times.append(EmpireReport._clock(game.elapsed))
	game.stat_add("rune_stones_taken", 1.0)
	game.codex.meet(CodexData.ENEMY, NorseRulesData.STONE_KIND)  # Codex: the stone is "slain" when first taken.
	game.effects.impact(s.pos, 70.0, Palette.NORSE_RUNE)
	game.shake(2.5)
	if game.norse != null:
		game.norse.play_sound("stone_taken", s.pos)
	if s.paid:
		game.enemies.show_banner("The rune-stone is yours again! Its ward and horn fall silent")
		return
	s.paid = true
	var ash := float(cfg["ash_per_take"])
	take_ash += ash
	game.stat_add("rune_take_ash", ash)
	game.stat_add("objective_ash", ash)  # The bounty path every stage objective pays through.
	game.enemies.show_banner("A rune-stone is taken! Its ward and horn fall silent. +%d Soul Ash" % int(ash))


## Held stone `s` blows its horn: a squad out of its edge (a seeded weighted
## pick), while the hard cap leaves room.
func _horn(s: Stone) -> void:
	horn_blown.emit(s.pos)
	horns += 1
	game.stat_add("rune_horns", 1.0)
	if game.norse != null:
		game.norse.play_sound("horn", s.pos, 2.0)
	if s.table.is_empty():
		return
	var total := 0.0
	for row: Dictionary in s.table:
		total += float(row.get("weight", 1.0))
	var roll := randf() * total
	var pick: Dictionary = s.table[s.table.size() - 1]
	for row: Dictionary in s.table:
		roll -= float(row.get("weight", 1.0))
		if roll <= 0.0:
			pick = row
			break
	var n := int(pick.get("count", 1))
	if game.enemies.regular_alive() + n + int(cfg["cap_margin"]) > game.enemies.hard_cap():
		game.stat_add("rune_horns_capped", 1.0)
		return
	var base := randf() * TAU
	var r := float(cfg["body_radius"]) + float(cfg["squad_spread"])
	for k in n:
		game.enemies.spawn_at(String(pick["kind"]), s.pos + Vector2.from_angle(base + TAU * float(k) / float(maxi(1, n))) * r,
				bool(pick.get("elite", false)))
	game.stat_add("rune_horn_units", float(n))


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Each stone: its ward ring while held (faint rune dots), its capture ring with
## the progress (bright dots filling clockwise from the top), its carving
## progress, and the stone itself (its sprite, else a carved-stone glyph).
func _draw() -> void:
	var n := NorseRulesData.CAPTURE_DOTS
	var cr := float(cfg["capture_radius"])
	var wr := float(cfg["ward_radius"])
	var spin := game.elapsed * 0.3  # The rune ring turns slowly (rad).
	for s in stones:
		if s.held:
			for i in n * 2:
				var a := spin + TAU * float(i) / float(n * 2)
				SpriteBank.draw_disc(self, s.pos + Vector2.from_angle(a) * wr, 1.4, Color(Palette.NORSE_RUNE, 0.18))
			for i in n:
				var a := -spin + TAU * float(i) / float(n)
				SpriteBank.draw_disc(self, s.pos + Vector2.from_angle(a) * cr, 1.6, Color(Palette.NORSE_FROST, 0.3))
			var k := clampf(s.capture / maxf(float(cfg["capture_time"]), 0.01), 0.0, 1.0)  # Capture progress.
			for i in ceili(k * float(n)):
				var a := -PI * 0.5 + TAU * float(i) / float(n)
				SpriteBank.draw_disc(self, s.pos + Vector2.from_angle(a) * cr, 3.2, Color(Palette.NECRO_GREEN, 0.95))
		elif s.carve > 0.0:
			var kc := clampf(s.carve / maxf(float(cfg["carve_time"]), 0.01), 0.0, 1.0)  # Carving progress.
			for i in ceili(kc * float(n)):
				var a := -PI * 0.5 + TAU * float(i) / float(n)
				SpriteBank.draw_disc(self, s.pos + Vector2.from_angle(a) * 30.0, 2.4, Color(Palette.NORSE_RUNE, 0.9))
		var key := NorseRulesData.STONE_SPRITE if s.held else NorseRulesData.STONE_TAKEN_SPRITE
		if not SpriteBank.draw(self, key, s.pos, false):
			NorseGlyphs.draw_stone(self, s.pos, float(cfg["body_radius"]), s.held)
