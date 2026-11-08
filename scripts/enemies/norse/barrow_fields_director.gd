## BarrowFieldsDirector — the stage systems of the Barrow Fields (Stage 16 in the
## final order; the Hall of the Slain, temporarily Act XI; GDD §15.0 "The Barrow
## Fields (the Hall of the Slain phase 2)"; the act's section "Stage 16" of
## docs/proposals/LAST_SIX_ACTS.md, docs/norse/BRIEF_PHASE2.md "Agent A"), owned
## and stepped by EnemyDirector on a stage whose STAGE has a "barrow_fields"
## config (BarrowFieldsStage.BARROW_FIELDS; `game.enemies.barrow_fields`, null
## elsewhere). The zones are MarchDirector's; the Long Winter, Berserkergang,
## the Rune-Stones and Ragnarök the shared NorseRules'. Here:
##   * THE BRAZIERS BY THE MAP (the foundation's note: the seeded ring left the
##     army bot cold 60-75% of the run): the Longshore's are the STAGE
##     "long_winter" "points" (LongWinter places them at the start); at each
##     later zone change the zone's own set (`braziers`: offsets from where the
##     necromancer stands as the zone's terrain is rebuilt around him) is placed
##     through LongWinter.place() (THE brazier call), and the braziers left
##     more than retire_dist px behind are retired (LongWinter.retire_far()), so
##     warmth stays near the fight and is fought over: the Barrows' braziers
##     stand by the mounds (the open barrows crack beside them), the Fjord's on
##     its banks, the Jarl's Hall's in two rows of hearths.
##   * OPEN BARROWS: THE ONE BARROW PATH, open_barrow(): an open_barrow
##     structure (BarrowFieldsEnemyData, OpenBarrowKit: a 2 s crack, then draugr
##     until it is broken) at a free point, at most barrow_cap standing. The
##     timeline's "barrow" events crack `count` of them, beside the lit braziers
##     nearest the necromancer when there are some (warmth is contested), else on
##     a ring; the Barrow-Wight's howl and Hrimgar's Grave call it too
##     (open_barrow_anywhere(), which works on any stage).
##   * THE FROZEN FJORD's DRIFTS (the proposal: "snow slows everyone through
##     TerrainSlow"): in a zone with `drifts`, `count` drifts of deep snow lie
##     around the necromancer; every `tick` s the necromancer and his summons
##     in one are slowed through TerrainSlow (THE one ground-slow path:
##     Brinewalker applies) and the enemies in one through Enemy.apply_slow()
##     (their own slow path; the berserk shrug it off, fliers pass over). They
##     melt at the next zone change. Drawn once as soft white textures.
##   * KEEP THE FIRES (the stage's achievement; owner decision Nov 7, 2026:
##     "finish the Barrow Fields with no brazier ever out for more than 30 s"):
##     judged when the countdown reaches 0:00 (the run is finished: a victory),
##     from LongWinter.longest_out() against NorseRulesData
##     .KEEP_THE_FIRES_MAX_OUT; earned, the run stat
##     barrow_fields_keep_the_fires is set (MetaProgress counts the runs:
##     lifetime keep_the_fires_runs, MetaData "keep_the_fires"; it unlocks
##     Fur-Lined Bones).
##   * THE BARROW-WIGHT ("wight" event): the stage miniboss, spawned on the
##     spawn ring with an escort and tracked (objective, kill time).
## Deterministic: the seeded global RNG only (the drifts and the Wight's
## side), game time only. Stats: barrow_fields_braziers_<zone>,
## barrow_fields_braziers_retired, barrows_<tag>, barrows_refused,
## drift_slows_you, drift_slows_summons, drift_slows_enemies,
## barrow_fields_keep_the_fires, barrow_fields_wight_spawned,
## barrow_fields_wight_killed.
class_name BarrowFieldsDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (BarrowFieldsStage.BARROW_FIELDS).
var config: Dictionary = {}
## Log of Barrow Fields events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Open barrows cracked this run (by this path).
var barrows: int = 0
## True once Keep the Fires was judged (at 0:00).
var judged: bool = false
## True once Keep the Fires was earned this run.
var keep_the_fires: bool = false
## Longest brazier outage (s) when it was judged (-1 before).
var judged_out: float = -1.0
## "m:ss" the Barrow-Wight fell ("" while alive / never spawned).
var wight_time: String = ""
## Deep snow drifts of the current zone: [centre (world px), radius (px)].
var drifts: Array = []
## Zone index the braziers / drifts were last laid for (MarchDirector).
var _zone: int = 0
## Seconds until the next drift check.
var _drift_left: float = 0.0
## Standing open barrows (stale ones dropped as they go).
var _barrows: Array[Enemy] = []
## Pool generation of each entry of `_barrows`.
var _barrow_gens: PackedInt32Array = PackedInt32Array()
## The Barrow-Wight once spawned (null before / after; generation-checked).
var _wight: Enemy = null
## Generation of `_wight` when he spawned.
var _wight_gen: int = 0
## Reusable query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false


func _ready() -> void:
	name = "BarrowFieldsDirector"
	z_index = -7  # The drifts lie on the ground, under the braziers and the bodies.
	z_as_relative = false
	_draws = DisplayServer.get_name() != "headless"


## Per-tick update (EnemyDirector, after the MarchDirector): the zone's braziers
## and drifts, the drifts' slow, the Wight, Keep the Fires at 0:00.
func step(delta: float) -> void:
	var m := game.enemies.march
	if m != null and m.zone_index != _zone:
		_zone = m.zone_index
		_enter_zone(_zone)
	if not drifts.is_empty():
		_drift_left -= delta
		if _drift_left <= 0.0:
			var t := float((config.get("drifts", {}) as Dictionary).get("tick", 0.5))
			_drift_left += t
			_step_drifts(t)
	if _wight != null and not (_wight.active and _wight.generation == _wight_gen):
		_wight = null
		game.stat_add("barrow_fields_wight_killed", 1.0)
		wight_time = _clock()
		_log("wight_killed")
	if not judged and game.countdown_finished():
		_judge_fires()


# =====================================================================================
# The zones: braziers by the map, the Fjord's drifts
# =====================================================================================

## The march entered zone `idx`: its braziers (the ones far behind retired) and
## its drifts (the last zone's melt).
func _enter_zone(idx: int) -> void:
	var zones: Array = (game.stage_def.get("march", {}) as Dictionary).get("zones", [])
	if idx < 0 or idx >= zones.size():
		return
	var zid := String((zones[idx] as Dictionary).get("id", ""))
	var p := game.player.position
	if game.norse != null:
		var w := game.norse.winter
		var gone := w.retire_far(p, float(config.get("retire_dist", 900.0)))
		game.stat_add("barrow_fields_braziers_retired", float(gone))
		var sets: Dictionary = config.get("braziers", {})
		for off: Vector2 in sets.get(zid, []):
			w.place(p + off)
			game.stat_add("barrow_fields_braziers_" + zid, 1.0)
	drifts.clear()
	var dc: Dictionary = config.get("drifts", {})
	if zid == String(dc.get("zone", "")):
		_lay_drifts(p, dc)
	if _draws:
		queue_redraw()
	_log("zone_" + zid)


## Lays the zone's deep snow drifts around `p` (seeded angles and distances),
## clear of the necromancer's spot.
func _lay_drifts(p: Vector2, dc: Dictionary) -> void:
	var n := int(dc.get("count", 0))
	var offset := randf() * TAU
	for i in n:
		var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.3, 0.3)
		var dd := randf_range(float(dc.get("dist_min", 200.0)), float(dc.get("dist_max", 700.0)))
		var r := randf_range(float(dc.get("radius_min", 60.0)), float(dc.get("radius_max", 110.0)))
		drifts.append([p + Vector2.from_angle(a) * dd, r])
	game.stat_add("barrow_fields_drifts", float(n))


## The drifts' slow (every `t` s): the necromancer and his summons through
## TerrainSlow, enemies on the ground through their own slow.
func _step_drifts(t: float) -> void:
	var dc: Dictionary = config.get("drifts", {})
	var f := float(dc.get("slow", 0.3))
	var linger := t * 1.6  # The slow outlasts the tick a little (no flicker).
	if game.coop == null:
		_drift_slot(f, linger)
	else:
		var prev := game.coop.bound  # Co-op: each necromancer's own Brinewalker.
		for i in game.coop.slots.size():
			game.coop.bind(i)
			_drift_slot(f, linger)
		game.coop.bind(prev)
	for dr: Array in drifts:
		var c: Vector2 = dr[0]
		var r := float(dr[1])
		game.enemy_grid.query(c, r + 20.0, _tmp)
		for e: Enemy in _tmp:
			if not e.active or e.is_structure or e.is_boss or e.floating or e.flies or e.untargetable:
				continue
			if e.position.distance_squared_to(c) <= r * r:
				e.apply_slow(f, linger)
				game.stat_add("drift_slows_enemies", 1.0)


## The bound slot's necromancer and summons standing in a drift are slowed.
func _drift_slot(f: float, linger: float) -> void:
	var pl := game.player
	if not pl.dead and in_drift(pl.position):
		if TerrainSlow.slow_player(game, f, linger) > 0.0:
			game.stat_add("drift_slows_you", 1.0)
	for u in game.horde.units:
		if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if in_drift(u.position):
			TerrainSlow.slow_summon(game, u, f, linger)
			game.stat_add("drift_slows_summons", 1.0)


## True when world point `p` lies in a drift of deep snow.
func in_drift(p: Vector2) -> bool:
	for dr: Array in drifts:
		var r := float(dr[1])
		if (dr[0] as Vector2).distance_squared_to(p) <= r * r:
			return true
	return false


# =====================================================================================
# Open barrows: the one barrow path
# =====================================================================================

## THE ONE BARROW PATH: cracks an open barrow at a free point near `at` (tag
## `tag` for the stats: "event", "howl", "hrimgar"). Returns it, or null when
## barrow_cap barrows stand (counted) or the spawn failed.
func open_barrow(at: Vector2, tag: String) -> Enemy:
	_prune()
	if _barrows.size() >= int(config.get("barrow_cap", 6)):
		game.stat_add("barrows_refused", 1.0)
		return null
	var e := game.enemies.spawn_at(BarrowFieldsEnemyData.OPEN_BARROW, game.arena.free_point(at, 22.0), false)
	if e == null:
		return null
	_barrows.append(e)
	_barrow_gens.append(e.generation)
	barrows += 1
	game.stat_add("barrows_" + tag, 1.0)
	return e


## Cracks a barrow through the Barrow Fields' path when it runs, else spawns
## one plainly (it still lets draugr out: OpenBarrowKit is self-contained), so
## the Wight's howl and Hrimgar's Grave work on any stage.
static func open_barrow_anywhere(g: Game, at: Vector2, tag: String) -> Enemy:
	if g.enemies.barrow_fields != null:
		return g.enemies.barrow_fields.open_barrow(at, tag)
	return g.enemies.spawn_at(BarrowFieldsEnemyData.OPEN_BARROW, g.arena.free_point(at, 22.0), false)


## Open barrows standing now.
func barrows_standing() -> int:
	_prune()
	return _barrows.size()


## Drops the barrows that left the field from the standing list.
func _prune() -> void:
	var i := _barrows.size() - 1
	while i >= 0:
		var e := _barrows[i]
		if not e.active or e.generation != _barrow_gens[i]:
			_barrows.remove_at(i)
			_barrow_gens.remove_at(i)
		i -= 1


## Where the `k`-th barrow of an event cracks: beside the k-th lit brazier
## nearest `p` (within brazier_reach px) when there is one, else on a ring.
func _barrow_point(p: Vector2, k: int, n: int, base: float) -> Vector2:
	var reach := float(config.get("brazier_reach", 700.0))
	var lit: Array = []
	if game.norse != null:
		for b in game.norse.winter.braziers:
			if b.lit and b.pos.distance_to(p) <= reach:
				lit.append(b.pos)
	lit.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(p) < b.distance_squared_to(p))
	if k < lit.size():
		var bpos: Vector2 = lit[k]
		var away := (bpos - p).normalized() if bpos.distance_to(p) > 1.0 else Vector2.RIGHT
		return bpos + away.rotated(0.9 * (1.0 if k % 2 == 0 else -1.0)) * float(config.get("brazier_side", 90.0))
	var a := base + TAU * float(k) / float(maxi(1, n))
	return p + Vector2.from_angle(a) * float(config.get("ring_dist", 260.0))


# =====================================================================================
# Keep the Fires
# =====================================================================================

## The countdown reached 0:00: Keep the Fires is judged once (Barrow Fields only).
func _judge_fires() -> void:
	judged = true
	if game.norse == null or String(game.stage_def.get("id", "")) != BarrowFieldsStage.ID:
		return
	judged_out = game.norse.winter.longest_out()
	if judged_out > NorseRulesData.KEEP_THE_FIRES_MAX_OUT:
		_log("fires_lost")
		return
	keep_the_fires = true
	game.stats["barrow_fields_keep_the_fires"] = 1.0
	game.enemies.show_banner(String(config.get("keep_the_fires_banner", "KEEP THE FIRES")))
	_log("keep_the_fires")


# =====================================================================================
# Events: barrows and the Barrow-Wight
# =====================================================================================

## Runs a Barrow Fields timeline event (EnemyDirector forwards the "barrow" and
## "wight" types; keys in BarrowFieldsStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	var p := game.player.position
	match String(ev["type"]):
		"barrow":
			var n := int(ev.get("count", 1))
			var base := randf() * TAU
			var made := 0
			for k in n:
				if open_barrow(_barrow_point(p, k, n, base), "event") != null:
					made += 1
			if ev.has("banner"):
				game.enemies.show_banner(String(ev["banner"]))
			_log("barrows_%d" % made)
		"wight":
			var a := randf() * TAU
			var e := game.enemies.spawn_at(String(ev.get("kind", BarrowFieldsEnemyData.WIGHT)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
			if e != null:
				_wight = e
				_wight_gen = e.generation
				game.stat_add("barrow_fields_wight_spawned", 1.0)
				game.shake(5.0)
				game.norse_rules().play_sound("horn", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				var k := 0
				for grp: Dictionary in ev.get("escort", []):
					for j in int(grp.get("count", 0)):
						var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (30.0 + 18.0 * float(k / 6))
						game.enemies.spawn_at(String(grp["kind"]), at, false)
						k += 1
				if ev.has("banner"):
					game.enemies.show_banner(String(ev["banner"]))
				_log("wight")


## The HUD objective while the Barrow-Wight stands ("" otherwise).
func objective_override() -> String:
	if _wight != null and _wight.active and _wight.generation == _wight_gen:
		return String(config.get("wight_objective", ""))
	return ""


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The drifts: soft white mounds of deep snow (disc textures; world space,
## redrawn only when they change).
func _draw() -> void:
	for dr: Array in drifts:
		var c: Vector2 = dr[0]
		var r := float(dr[1])
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6)), false, Color(Palette.NORSE_FROST, 0.55))
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r * 0.7, r * 0.6), Vector2(r * 1.4, r * 1.0)), false, Color(Palette.NORSE_FROST_SHADE, 0.35))


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	var zones := PackedStringArray()
	for z: String in ["barrows", "frozen_fjord", "jarls_hall"]:
		zones.append("%s %d" % [z, int(st.get("barrow_fields_braziers_" + z, 0.0))])
	return "braziers by zone (%s), retired %d | open barrows %d (events %d, howls %d, hrimgar %d; refused at the cap %d), opened %d, broken %d, draugr let out %d (capped %d) | drifts %d: slows you %d, summons %d, enemies %d | keep the fires %s (longest out %.1f s of at most %.0f) | wight spawned %d, killed %d%s | events: %s" % [
		", ".join(zones), int(st.get("barrow_fields_braziers_retired", 0.0)),
		barrows, int(st.get("barrows_event", 0.0)), int(st.get("barrows_howl", 0.0)), int(st.get("barrows_hrimgar", 0.0)),
		int(st.get("barrows_refused", 0.0)), int(st.get("barrows_opened", 0.0)), int(st.get("barrows_broken", 0.0)),
		int(st.get("barrow_draugr", 0.0)), int(st.get("barrow_draugr_capped", 0.0)),
		int(st.get("barrow_fields_drifts", 0.0)), int(st.get("drift_slows_you", 0.0)), int(st.get("drift_slows_summons", 0.0)),
		int(st.get("drift_slows_enemies", 0.0)),
		"EARNED" if keep_the_fires else ("lost" if judged else "open"), judged_out if judged else (game.norse.winter.longest_out() if game.norse != null else 0.0),
		NorseRulesData.KEEP_THE_FIRES_MAX_OUT,
		int(st.get("barrow_fields_wight_spawned", 0.0)), int(st.get("barrow_fields_wight_killed", 0.0)),
		(" at " + wight_time) if wight_time != "" else "", ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
