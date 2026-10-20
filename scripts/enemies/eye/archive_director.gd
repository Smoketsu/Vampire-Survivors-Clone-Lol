## ArchiveDirector — the Hollow Archive's own mechanics (Act II, Stage 5; GDD
## §15.0 "Act II: the Hollow Archive"), owned and stepped by EnemyDirector on
## a stage whose StageRegistry `archive` config is not empty (the zones
## themselves are MarchDirector's). Data: ArchiveStage (ARCHIVE, ZONES, the
## "tomes" / "librarian" / "rift" timeline events).
##   * Zone I, the Reading Halls: the shelves are the zone's arena layout
##     (aligned rows, ArchiveStage.ZONES); nothing to run here.
##   * Zone II, the Ink Wells: pools of black ink in the floor, one per hashed
##     cell (well_cell, well_chance: the same wells every run), filling at the
##     zone change and draining at the next. ArchiveHazards treats a well as
##     ink (in_well()): the necromancer is slowed and his Dread rises; Ink
##     Wraiths rise out of them (wells_near()).
##   * Zone III, the Orrery: a huge brass orrery rises around the necromancer
##     (the zone's wide clear circle keeps obstacles off it). Its arms are
##     MOVING WALLS: they rest hold_time s, the next sweep is telegraphed for
##     telegraph s (the swept sectors glow), then they turn turn_step rad in
##     turn_time s (the direction alternates). Bodies touching an arm or the
##     hub are pushed out of it (a turning arm sweeps them along), never into
##     an obstacle: a body the arm would press into one is left where it is,
##     so nobody is ever trapped. If the necromancer has wandered farther
##     than reassemble_range from the hub when a turn ends, the orrery folds
##     and rises around him again. It folds away for good at Zone IV.
##   * Forbidden tomes (optional, "tomes" events): lecterns, each guarded by a
##     Scribe. Standing on one for burn_time s burns its tome: a free
##     level-up card (Game.pending_level_ups) and tome_dread Dread ("tome").
##     Unburned, it is resealed after tome_life s. Burning every tome the run
##     places (tome_total) earns the achievement Nothing Unwritten (the
##     archive_all_tomes stat, MetaProgress).
##   * The Librarian ("librarian" event): the miniboss from the spawn ring;
##     its kit registers it on the HUD's miniboss bar (LibrarianKit).
##   * Rifts: the child RiftDirector ("rift" events and Zone IV's periodic
##     rifts).
##   * The Reckoning: an ink darkness pooled around the necromancer (cosmetic).
## Deterministic: the seeded global RNG and stable cell hashes only.
## Everything is drawn here in world space, under bodies.
class_name ArchiveDirector
extends Node2D

## Orrery phase: not on the field.
const ORR_NONE: int = 0
## Orrery phase: rising (arms extend; not solid yet).
const ORR_RISE: int = 1
## Orrery phase: resting.
const ORR_HOLD: int = 2
## Orrery phase: the next sweep is telegraphed.
const ORR_TELEGRAPH: int = 3
## Orrery phase: turning (the arms sweep).
const ORR_TURN: int = 4
## Orrery phase: folding away (not solid).
const ORR_FOLD: int = 5

## One forbidden tome on its lectern.
class Tome:
	extends RefCounted
	## World position of the lectern.
	var pos: Vector2 = Vector2.ZERO
	## Seconds left before it is resealed.
	var life: float = 90.0
	## Seconds of burning done (the channel).
	var burn: float = 0.0

## Owning run.
var game: Game
## The stage's Archive config (ArchiveStage.ARCHIVE).
var config: Dictionary = {}
## The rifts (child).
var rifts: RiftDirector
## Zone index last seen (MarchDirector.zone_index; -1 before the first step).
var _zone: int = -1
## Ink wells' fill (0..1): 1 while the Ink Wells hold, easing at the changes.
var wells_fill: float = 0.0
## Fill the wells head for (0 or 1).
var _wells_target: float = 0.0
## Redraw cell the wells were drawn around (the necromancer's 256 px cell).
var _wells_cell: Vector2i = Vector2i(1 << 30, 1 << 30)
## Orrery phase (ORR_*).
var orr_phase: int = ORR_NONE
## Seconds spent in the orrery phase.
var orr_t: float = 0.0
## World centre of the orrery's hub.
var orr_hub: Vector2 = Vector2.ZERO
## Angle (rad) of the first arm (the others are spread evenly).
var orr_angle: float = 0.0
## Angle at the start of the current turn.
var _orr_from: float = 0.0
## +1 / -1: direction of the next turn (alternates).
var orr_dir: float = 1.0
## 0..1 how far the arms reach out (rising / folding).
var orr_extend: float = 0.0
## True while the orrery should fold away for good (Zone IV).
var _orr_leaving: bool = false
## Live tomes.
var tomes: Array[Tome] = []
## Tomes placed this run.
var tomes_placed: int = 0
## Tomes the necromancer burned this run (Nothing Unwritten counts them).
var tomes_burned: int = 0
## Tomes resealed unburned this run.
var tomes_lost: int = 0
## Game times tomes burned, "m:ss" (summary).
var burn_times: PackedStringArray = PackedStringArray()
## The Librarian once spawned (null before / after; generation-checked).
var _librarian: Enemy = null
## Generation of `_librarian` when it spawned.
var _librarian_gen: int = 0
## Game time the Librarian fell ("" while alive / never spawned).
var librarian_time: String = ""
## Log of Archive events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## True if something animated was drawn last frame.
var _drew: bool = false
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -8  # On the floor, under the hazards and the bodies.
	rifts = RiftDirector.new()
	rifts.game = game
	rifts.config = config["rifts"]
	add_child(rifts)


## Per-tick update, called by EnemyDirector after the MarchDirector.
func step(delta: float) -> void:
	_track_zone()
	_ease_wells(delta)
	_step_orrery(delta)
	_step_tomes(delta)
	_step_librarian()
	rifts.step(delta)
	var busy := orr_phase != ORR_NONE or not tomes.is_empty() or (wells_fill > 0.0 and wells_fill < 1.0) or game.enemies.reckoning_wave > 0
	var cell := Vector2i(floori(game.player.position.x / 256.0), floori(game.player.position.y / 256.0))
	if wells_fill > 0.0 and cell != _wells_cell:
		_wells_cell = cell
		busy = true
	if busy or _drew:
		queue_redraw()
	_drew = busy


# =====================================================================================
# Zones
# =====================================================================================

## Reacts to MarchDirector's zone changes: the wells fill / drain, the
## orrery rises / folds away.
func _track_zone() -> void:
	var m := game.enemies.march  # Zones (always present on the Archive).
	if m == null or m.zone_index == _zone:
		return
	_zone = m.zone_index
	_wells_target = 1.0 if _zone == int(config["wells_zone"]) else 0.0
	if _zone == int(config["orrery_zone"]):
		_orr_assemble(game.player.position)
	elif orr_phase != ORR_NONE:
		_orr_leaving = true
		_orr_set(ORR_FOLD)
	_log("zone_%d" % (_zone + 1))


## The wells fill and drain over well_fade s.
func _ease_wells(delta: float) -> void:
	wells_fill = move_toward(wells_fill, _wells_target, delta / maxf(0.05, float(config["well_fade"])))


## The well of cell (cx, cy): Vector3(x, y, radius), or z = 0 when the cell
## has none (a stable hash: the same wells every run).
func _well(cx: int, cy: int) -> Vector3:
	var h := absi(hash(Vector3i(cx, cy, 9137)))
	if float(h % 1000) / 1000.0 >= float(config["well_chance"]):
		return Vector3.ZERO
	var cell := float(config["well_cell"])
	var rmax := float(config["well_radius_max"])
	var span := cell - 2.0 * (rmax + 8.0)  # Room for the centre inside the cell.
	var x := float(cx) * cell + rmax + 8.0 + float((h >> 10) % 1000) / 1000.0 * span
	var y := float(cy) * cell + rmax + 8.0 + float((h >> 20) % 1000) / 1000.0 * span
	var r := lerpf(float(config["well_radius_min"]), rmax, float((h >> 5) % 997) / 997.0)
	return Vector3(x, y, r)


## True if `p` stands in a filled ink well (half full or more).
func in_well(p: Vector2) -> bool:
	if wells_fill < 0.5:
		return false
	var cell := float(config["well_cell"])
	var w := _well(floori(p.x / cell), floori(p.y / cell))
	return w.z > 0.0 and p.distance_squared_to(Vector2(w.x, w.y)) <= w.z * w.z


## Centres of the filled wells within `reach` px of `p` (Ink Wraith risings).
func wells_near(p: Vector2, reach: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if wells_fill < 0.5:
		return out
	var cell := float(config["well_cell"])
	var c0 := Vector2i(floori((p.x - reach) / cell), floori((p.y - reach) / cell))
	var c1 := Vector2i(floori((p.x + reach) / cell), floori((p.y + reach) / cell))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var w := _well(cx, cy)
			if w.z > 0.0 and p.distance_to(Vector2(w.x, w.y)) <= reach:
				out.append(Vector2(w.x, w.y))
	return out


# =====================================================================================
# The Orrery
# =====================================================================================

## The orrery rises with its hub at `at`.
func _orr_assemble(at: Vector2) -> void:
	orr_hub = at
	orr_extend = 0.0
	_orr_leaving = false
	_orr_set(ORR_RISE)
	game.stat_add("orrery_assembled", 1.0)
	game.effects.ring(at, float(config["orrery"]["arm_length"]), ArchiveGlyphs.BRASS, 0.8)
	_log("orrery_rises")


## Changes the orrery phase.
func _orr_set(p: int) -> void:
	orr_phase = p
	orr_t = 0.0


## Orrery cycle: rise, rest, telegraph, turn; refold around a far necromancer.
func _step_orrery(delta: float) -> void:
	if orr_phase == ORR_NONE:
		return
	var o: Dictionary = config["orrery"]
	orr_t += delta
	match orr_phase:
		ORR_RISE:
			orr_extend = clampf(orr_t / float(o["fold_time"]), 0.0, 1.0)
			if orr_t >= float(o["fold_time"]):
				orr_extend = 1.0
				_orr_set(ORR_HOLD)
		ORR_HOLD:
			if orr_t >= float(o["hold_time"]):
				_orr_set(ORR_TELEGRAPH)
				game.stat_add("orrery_telegraphs", 1.0)
		ORR_TELEGRAPH:
			if orr_t >= float(o["telegraph"]):
				_orr_from = orr_angle
				_orr_set(ORR_TURN)
				Sfx.play("boss_impact", orr_hub, 0.5)
		ORR_TURN:
			var k := clampf(orr_t / float(o["turn_time"]), 0.0, 1.0)
			orr_angle = _orr_from + orr_dir * float(o["turn_step"]) * smoothstep(0.0, 1.0, k)
			if k >= 1.0:
				orr_dir = -orr_dir
				game.stat_add("orrery_turns", 1.0)
				if game.player.position.distance_to(orr_hub) > float(o["reassemble_range"]):
					_orr_set(ORR_FOLD)
				else:
					_orr_set(ORR_HOLD)
		ORR_FOLD:
			orr_extend = 1.0 - clampf(orr_t / float(o["fold_time"]), 0.0, 1.0)
			if orr_t >= float(o["fold_time"]):
				if _orr_leaving:
					orr_phase = ORR_NONE
					_log("orrery_folds")
				else:
					_orr_assemble(game.player.position)
					game.stat_add("orrery_reassembled", 1.0)
	if orr_phase in [ORR_HOLD, ORR_TELEGRAPH, ORR_TURN]:
		_orr_push(delta)


## Unit direction of arm `i` (rad offset of the first arm: orr_angle).
func _arm_dir(i: int) -> Vector2:
	var n := int(config["orrery"]["arms"])
	return Vector2.from_angle(orr_angle + TAU * float(i) / float(n))


## Pushes the necromancer, the summons and the walking enemies out of the
## hub and the arms (a turning arm sweeps them along its way). Summons and
## enemies held against a resting arm also slide along it toward its tip
## (orrery slide_speed px/s), so a body walking into an arm finds its way
## around the end instead of pressing on it for ever.
func _orr_push(delta: float) -> void:
	var o: Dictionary = config["orrery"]
	var reach := float(o["arm_length"]) + 30.0
	var slide := float(o["slide_speed"]) * delta  # px a held body slides along the arm this tick.
	for pl in game.all_players:  # (Co-op: each necromancer.)
		pl.position = _push_body(pl.position, pl.radius, 0.0)
	game.ally_grid.query(orr_hub, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and not u.airborne:
			u.position = _push_body(u.position, u.radius, slide)
	game.enemy_grid.query(orr_hub, reach + 30.0, _tmp)
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and not e.phases_obstacles and not e.is_boss:
			e.position = _push_body(e.position, e.radius, slide)


## Where a body of radius `r` at `p` ends up after the hub and the arms push
## it out (unchanged when nothing touches it, or when the push would put it
## in an obstacle: nobody is ever trapped); `slide` px along a resting arm
## toward its tip.
func _push_body(p: Vector2, r: float, slide: float) -> Vector2:
	var o: Dictionary = config["orrery"]
	var hub_r := float(o["hub_radius"])
	var off := p - orr_hub
	var d := off.length()
	if d > float(o["arm_length"]) + r + 2.0:
		return p
	var out := p
	if d < hub_r + r:
		var n := off / d if d > 0.01 else Vector2.RIGHT
		out = orr_hub + n * (hub_r + r + 0.5)
	var half := float(o["arm_width"]) * 0.5
	var length := float(o["arm_length"]) * orr_extend
	for i in int(o["arms"]):
		var dir := _arm_dir(i)
		var rel := out - orr_hub
		var along := rel.dot(dir)
		if along < hub_r * 0.5 or along > length + r:
			continue
		var side := rel.cross(dir)  # Signed distance to the arm's line (px).
		if absf(side) >= half + r:
			continue
		var nrm := Vector2(-dir.y, dir.x)  # Left normal (cross < 0 side).
		var sgn := -1.0 if side > 0.0 else 1.0
		if orr_phase == ORR_TURN:
			sgn = orr_dir  # A turning arm sweeps bodies the way it turns.
		var target := orr_hub + dir * along + nrm * sgn * (half + r + 0.5)
		if orr_phase != ORR_TURN:
			target += dir * slide  # Held against a resting arm: slide toward its open tip.
		if game.arena.is_blocked(target, r):
			game.stat_add("orrery_push_skipped", 1.0)
			continue  # The arm would press it into an obstacle: let it through.
		out = target
		game.stat_add("orrery_pushes", 1.0)
	if out != p and game.arena.is_blocked(out, r):
		return p
	return out


# =====================================================================================
# Forbidden tomes
# =====================================================================================

## Runs an Archive timeline event (EnemyDirector forwards "tomes",
## "librarian" and "rift"; keys in ArchiveStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"tomes":
			_place_tomes(ev)
		"librarian":
			_spawn_librarian(ev)
		"rift":
			rifts.start_rift(ev["groups"])
	game.enemies.show_banner(String(ev["banner"]))


## Places `ev.count` lecterns around the necromancer (spread evenly, spaced,
## out of obstacles), each with its guards.
func _place_tomes(ev: Dictionary) -> void:
	var n := int(ev["count"])
	var offset := randf() * TAU
	var placed: Array[Vector2] = []
	var p := game.player.position
	for i in n:
		var pos := p
		for _try in int(config["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			pos = game.arena.free_point(p + Vector2.from_angle(a) * randf_range(float(ev["distance_min"]), float(ev["distance_max"])), 22.0)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(config["structure_spacing"])
			if spaced and not game.arena.is_blocked(pos, 22.0):
				break
		placed.append(pos)
		game.arena.keep_clear(pos, ArenaData.MAX_HALF_EXTENT * 1.5)
		var t := Tome.new()
		t.pos = pos
		t.life = float(config["tome_life"])
		tomes.append(t)
		tomes_placed += 1
		game.effects.spawn_ring(pos, ArchiveEnemyData.INK_SHEEN)
		var k := 0
		for grp: Dictionary in config["tome_guards"]:
			for _g in int(grp["count"]):
				if game.enemies.regular_alive() >= game.enemies.hard_cap():
					break
				var at := pos + Vector2.from_angle(TAU * float(k) / 4.0 + offset) * 34.0
				game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
				k += 1
	game.stat_add("tomes_placed", float(n))
	_log("tomes_%d" % n)


## True when a necromancer (co-op: either) stands on tome `t` (it burns).
func _on_tome(t: Tome) -> bool:
	for pl in game.all_players:
		if pl.position.distance_to(t.pos) <= float(config["burn_radius"]) + pl.radius:
			return true
	return false


## Tomes age; the necromancer standing on one burns it.
func _step_tomes(delta: float) -> void:
	var i := tomes.size() - 1
	while i >= 0:
		var t := tomes[i]
		t.life -= delta
		if _on_tome(t):
			t.burn += delta
			if t.burn >= float(config["burn_time"]):
				_burn(t)
				tomes.remove_at(i)
				i -= 1
				continue
		else:
			t.burn = maxf(0.0, t.burn - delta * 2.0)
		if t.life <= 0.0:
			tomes_lost += 1
			game.stat_add("tomes_lost", 1.0)
			game.effects.pop(t.pos, ArchiveEnemyData.INK_SHEEN, 20.0)
			game.enemies.show_banner("A forbidden tome seals itself away!")
			_log("tome_sealed")
			tomes.remove_at(i)
		i -= 1


## A tome burns: a free level-up card and Dread; the last of the run earns
## Nothing Unwritten.
func _burn(t: Tome) -> void:
	tomes_burned += 1
	game.pending_level_ups += 1  # A free card (Game opens the panel at the end of the tick).
	game.stat_add("tomes_burned", 1.0)
	game.stat_add("objective_ash", float(config["tome_ash"]))
	if game.dread != null:
		game.dread.add(float(config["tome_dread"]), "tome")
	game.effects.impact(t.pos, 48.0, Palette.FLAME)
	game.effects.ring(t.pos, 70.0, ArchiveEnemyData.INK_SHEEN, 0.6)
	Sfx.play("corpse_burst", t.pos, 0.8)
	var s := int(game.elapsed)
	burn_times.append("%d:%02d" % [floori(float(s) / 60.0), s % 60])
	_log("tome_burned")
	if tomes_burned >= int(config["tome_total"]):
		game.stats["archive_all_tomes"] = 1.0  # Nothing Unwritten (MetaProgress lifetime counter).
		game.enemies.show_banner("NOTHING UNWRITTEN: every forbidden tome is ash!")
		_log("nothing_unwritten")
	else:
		game.enemies.show_banner("The tome burns: forbidden knowledge floods your mind (+%d Dread)!" % roundi(float(config["tome_dread"])))


# =====================================================================================
# The Librarian
# =====================================================================================

## Spawns the Librarian on the spawn ring.
func _spawn_librarian(ev: Dictionary) -> void:
	var e := game.enemies.spawn_at(String(ev["kind"]), game.enemies.ring_point(randf() * TAU), bool(ev["elite"]))
	_librarian = e
	_librarian_gen = e.generation
	_log("librarian_arrived")


## Notes when the Librarian fell (its XP burst and banner are LibrarianKit's,
## its chest ChestManager's miniboss rule).
func _step_librarian() -> void:
	if _librarian == null or (_librarian.active and _librarian.generation == _librarian_gen):
		return
	_librarian = null
	var s := int(game.elapsed)
	librarian_time = "%d:%02d" % [floori(float(s) / 60.0), s % 60]
	_log("librarian_killed")


# =====================================================================================
# Queries (HUD, autopilot, summary)
# =====================================================================================

## HUD objective for the live Archive objective ("" if none): an open rift,
## the Librarian, then the optional tomes.
func objective_override() -> String:
	if rifts.live_count() > 0:
		return "A rift tears the stacks open: break it to seal it"
	if _librarian != null:
		return "Slay the Librarian: it guards a treasure"
	if not tomes.is_empty():
		return "Optional: burn the forbidden tomes for power, at a price in Dread (%d left)" % tomes.size()
	return ""


## Autopilot hint: the nearest live tome within `reach` px of `p`
## (Vector2.INF when none).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for t in tomes:
		var d := p.distance_to(t.pos)
		if d < best_d:
			best_d = d
			best = t.pos
	return best


## Records an Archive event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])


## One-line autotest summary: tomes, wells, the orrery, the Librarian.
func summary_line() -> String:
	var st := game.stats
	return "tomes burned %d/%d (%s), resealed %d, all burned: %s | ink seconds %.0f, spore seconds %.0f | orrery: risen %d (re-assembled %d), turns %d, bodies pushed %d (skipped at obstacles %d) | librarian %s (beams %d, summons turned %d, lashes %d)" % [
		tomes_burned, tomes_placed, ", ".join(burn_times) if not burn_times.is_empty() else "-", tomes_lost,
		"yes" if st.has("archive_all_tomes") else "no",
		float(st.get("archive_ink_seconds", 0.0)), float(st.get("archive_spore_seconds", 0.0)),
		int(st.get("orrery_assembled", 0.0)), int(st.get("orrery_reassembled", 0.0)), int(st.get("orrery_turns", 0.0)),
		int(st.get("orrery_pushes", 0.0)), int(st.get("orrery_push_skipped", 0.0)),
		("killed at " + librarian_time) if librarian_time != "" else ("alive" if _librarian != null else "not spawned"),
		int(st.get("librarian_beams", 0.0)), int(st.get("librarian_turned", 0.0)), int(st.get("librarian_lashes", 0.0))]


# =====================================================================================
# Drawing (world space, under bodies)
# =====================================================================================

func _draw() -> void:
	var now := game.elapsed
	if wells_fill > 0.0:
		_draw_wells(now)
	if orr_phase != ORR_NONE:
		_draw_orrery(now)
	for t in tomes:
		ArchiveGlyphs.draw_tome(self, t.pos, now, t.burn / maxf(0.05, float(config["burn_time"])), t.life)
	if game.enemies.reckoning_wave > 0:
		ArchiveGlyphs.draw_ink_darkness(self, game.player.position, now, game.stage_def["reckoning"].get("ink", ArchiveEnemyData.INK_COLOR))


## The wells around the necromancer.
func _draw_wells(now: float) -> void:
	var cell := float(config["well_cell"])
	var p := game.player.position
	var reach := 1100.0  # px drawn around him (beyond the view at Normal zoom).
	var c0 := Vector2i(floori((p.x - reach) / cell), floori((p.y - reach) / cell))
	var c1 := Vector2i(floori((p.x + reach) / cell), floori((p.y + reach) / cell))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var w := _well(cx, cy)
			if w.z > 0.0:
				ArchiveGlyphs.draw_ink_well(self, Vector2(w.x, w.y), w.z * (0.4 + 0.6 * wells_fill), wells_fill, now)


## The orrery: the hub, the arms and, while telegraphed, the sweep ahead.
func _draw_orrery(now: float) -> void:
	var o: Dictionary = config["orrery"]
	var n := int(o["arms"])
	var length := float(o["arm_length"]) * orr_extend
	var solid := orr_phase in [ORR_HOLD, ORR_TELEGRAPH, ORR_TURN]
	if orr_phase == ORR_TELEGRAPH:
		var k := clampf(orr_t / float(o["telegraph"]), 0.0, 1.0)  # Telegraph progress.
		for i in n:
			var a0 := orr_angle + TAU * float(i) / float(n)
			ArchiveGlyphs.draw_orrery_sweep(self, orr_hub, a0, orr_dir * float(o["turn_step"]), length, k, now)
	ArchiveGlyphs.draw_orrery(self, orr_hub, orr_angle, n, length, float(o["arm_width"]), float(o["hub_radius"]), solid, now)
