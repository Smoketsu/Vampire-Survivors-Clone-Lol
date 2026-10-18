## BossArchivist — THE ARCHIVIST, KEEPER OF THE UNWRITTEN, the boss of the
## Hollow Archive (Act II, Stage 5; StageRegistry boss id "archivist", loaded
## by name from this folder by EnemyDirector; --boss=archivist sends her to
## any stage). She arrives at 17:00 (3:00 left) like every boss. A robed
## figure whose face is an open book. Extends Boss, so summons, spells and the
## spatial hash treat her like any enemy. Every number is ArchivistData.BOSS:
##   Recitation — she stands reading (recitation_cast s, the cast pose), then
##                pages rise around her, hover (the telegraph) and home on the
##                necromancer (ArchiveHazards pages: a hit hurts him or the
##                summon in the way and bursts into a short-lived ink pool).
##   Footnotes  — from the second phase: a splitting glow (footnote_cast s,
##                the three spots marked), then she stands at one of three
##                spots around the necromancer and two copies (ArchivistCopy)
##                at the others, for footnote_time s. Only she casts a shadow;
##                only she takes damage.
##   Erasure    — from erasure_start s after her arrival until she falls:
##                the field's edge, a circle around where the necromancer
##                stood, steps erasure_step px inward every erasure_interval
##                s (the next edge glows erasure_telegraph s first), down to
##                erasure_min. Every tick the necromancer and the summons
##                beyond it are pushed back inside (Arena.free_point(): never
##                into an obstacle); the Eye walks in from the void freely.
## Fight phases: 0 the Reading (Recitation), 1 the Footnotes (from
## footnote_hp_fraction), 2 the Last Page (from last_page_hp_fraction: more
## pages, shorter gaps, Footnotes more often). Between specials she walks at
## the necromancer (faster beyond advance_range: she never kites) and strikes
## in reach (inherited melee). On death: the pages crumble, the copies fade,
## the edge stops, and the usual boss reward fires (EnemyDirector: XP burst,
## chest, power-up; Unlocks: Forbidden Verse and Marginalia).
## Deterministic: the seeded global RNG only (which spot she takes).
class_name BossArchivist
extends Boss

## Attack phases.
enum Phase { WALK, RECITE, FOOTNOTE_CAST, RECOVER }

## Draws the Erasure in world space, under the bodies.
class ErasureLayer:
	extends Node2D
	## The boss whose edge it draws.
	var boss: BossArchivist

	func _draw() -> void:
		if boss.erase_on:
			ArchiveGlyphs.draw_erasure(self, boss.erase_center, boss.erase_radius, boss.erase_next_radius(), boss.erase_warning(), boss.game.elapsed)

## Current attack phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current attack phase.
var phase_time: float = 0.0
## Fight phase: 0 the Reading, 1 the Footnotes, 2 the Last Page.
var fight_phase: int = 0
## Seconds until the next special may start (counts down while walking).
var special_cd: float = 2.0
## Seconds until Recitation may be used again.
var recite_cd: float = 0.0
## Seconds until Footnotes may be used again.
var footnote_cd: float = 0.0
## Seconds the current copies still walk (0 = no copies out).
var footnote_left: float = 0.0
## The three spots of the coming split (locked at the cast).
var _spots: Array[Vector2] = []
## The two Footnote copies (reused each split).
var _copies: Array[ArchivistCopy] = []
## True while the Erasure runs.
var erase_on: bool = false
## Centre of the erased circle.
var erase_center: Vector2 = Vector2.ZERO
## Current radius (px) of the edge.
var erase_radius: float = 0.0
## Game time of the next step inward.
var _erase_next: float = INF
## Walking speed before the forced march (px/s).
var _base_speed: float = 46.0
## Game time she arrived.
var _spawn_time: float = 0.0
## The Erasure's draw layer.
var _erase_layer: ErasureLayer = null


## Sets up the Archivist at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ArchivistData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	fight_phase = 0
	special_cd = float(boss_def["first_special"])
	recite_cd = 0.0
	footnote_cd = 0.0
	footnote_left = 0.0
	erase_on = false
	_erase_next = INF
	_base_speed = move_speed
	_spawn_time = game.elapsed
	game.stats["archivist_spawn_time"] = game.elapsed
	_erase_layer = ErasureLayer.new()
	_erase_layer.boss = self
	_erase_layer.z_index = -6  # On the ground, under bodies.
	game.enemies.add_child(_erase_layer)
	for i in 2:
		var c := ArchivistCopy.new()
		game.enemies.add_child(c)
		_copies.append(c)
	game.enemies.boss_defeated.connect(_on_defeated)


## The Archivist's specials in report order (Boss hook).
func special_ids() -> Array:
	return ArchivistData.SPECIALS


## True while she walks at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


# =====================================================================================
# Choosing specials
# =====================================================================================

## Footnotes first when due (from the second phase), else Recitation.
func think() -> void:
	super.think()
	if phase != Phase.WALK or special_cd > 0.0:
		return
	if fight_phase >= 1 and footnote_cd <= 0.0 and footnote_left <= 0.0:
		_start_footnotes()
	elif recite_cd <= 0.0:
		_start_recitation()


## Boss physics: walk / melee in WALK, otherwise the special; the Erasure
## runs every tick.
func physics_step(delta: float) -> void:
	phase_time += delta
	recite_cd -= delta
	footnote_cd -= delta
	_update_fight_phase()
	_step_erasure(delta)
	_step_copies(delta)
	match phase:
		Phase.WALK:
			special_cd -= delta
			var far := position.distance_to(game.player.position) > float(boss_def["advance_range"])  # Left behind.
			move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if far else 1.0)
			super.physics_step(delta)
		Phase.RECITE:
			_hold(delta)
			if phase_time >= float(boss_def["recitation_cast"]):
				_release_pages()
				_set_phase(Phase.RECOVER)
		Phase.FOOTNOTE_CAST:
			_hold(delta)
			if phase_time >= float(boss_def["footnote_cast"]):
				_split()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold(delta)
			if phase_time >= float(boss_def["recover_time"]):
				special_cd = float(boss_def["attack_gap"]) * float((boss_def["phase_gap_mult"] as Array)[fight_phase])
				_set_phase(Phase.WALK)


## Held by Stasis / a Deep Freeze: the Erasure and the copies still run.
func step_frozen(delta: float) -> void:
	super.step_frozen(delta)
	_step_erasure(delta)
	_step_copies(delta)


## Standing still during a cast / recovery (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	if p == Phase.RECOVER and game != null:
		motion_lunge(game.player.position - position, MotionData.POWER_CAST)  # Engine motion (visual only).
	queue_redraw()


## Enters the Footnotes / the Last Page as her HP falls.
func _update_fight_phase() -> void:
	var frac := hp / maxf(1.0, max_hp)
	var target := 0
	if frac <= float(boss_def["last_page_hp_fraction"]):
		target = 2
	elif frac <= float(boss_def["footnote_hp_fraction"]):
		target = 1
	if target <= fight_phase:
		return
	fight_phase = target
	footnote_cd = minf(footnote_cd, 1.0)
	game.stats["archivist_phase%d_time" % fight_phase] = game.elapsed - _spawn_time
	game.enemies.show_banner(String((boss_def["phase_banners"] as Array)[fight_phase]))
	game.effects.ring(position, radius * 4.0, ArchiveEnemyData.INK_SHEEN, 0.6)
	queue_redraw()


# =====================================================================================
# Recitation
# =====================================================================================

## Recitation: she stands and reads.
func _start_recitation() -> void:
	recite_cd = float(boss_def["recitation_cooldown"])
	game.stat_add("boss_atk_recitation", 1.0)
	_set_phase(Phase.RECITE)


## The pages rise around her and hover, then hunt (ArchiveHazards).
func _release_pages() -> void:
	var n := int((boss_def["pages"] as Array)[fight_phase])
	var hz := game.enemies.archive_hazards()
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x aura buff.
	var a0 := float(game.stats.get("boss_atk_recitation", 0.0)) * 0.41  # Turn each volley (no RNG).
	for i in n:
		var a := a0 + TAU * float(i) / float(n)
		hz.add_page(position, position + Vector2.from_angle(a) * float(boss_def["page_rise_radius"]), boss_def, mult)
	Sfx.play("plague_cast", position, 0.7)


# =====================================================================================
# Footnotes
# =====================================================================================

## Footnotes: a splitting glow and the three spots marked around the necromancer.
func _start_footnotes() -> void:
	footnote_cd = float((boss_def["footnote_cooldown"] as Array)[fight_phase])
	if footnote_cd <= 0.0:
		footnote_cd = INF
		return
	game.stat_add("boss_atk_footnotes", 1.0)
	var p := game.player.position
	var off := position - p
	if off.length() < 60.0:
		off = Vector2.RIGHT * 120.0
	elif off.length() > 260.0:
		off = off.normalized() * 260.0
	var spread := float(boss_def["footnote_spread"])
	_spots.clear()
	for k in [0.0, 1.0, -1.0]:
		var at := game.arena.free_point(p + off.rotated(spread * float(k)), radius)
		_spots.append(at)
		game.effects.telegraph_circle(at, radius * 1.4, float(boss_def["footnote_cast"]), self)
	_set_phase(Phase.FOOTNOTE_CAST)


## She splits: she takes one spot (seeded), her copies the others.
func _split() -> void:
	var real := randi() % _spots.size()  # Her spot.
	position = _spots[real]
	game.effects.ring(position, radius * 2.0, ArchiveEnemyData.INK_SHEEN, 0.4)
	var k := 0
	for i in _spots.size():
		if i == real or k >= _copies.size():
			continue
		_copies[k].appear(game, self, _spots[i], _next_copy_slot(k))
		k += 1
	footnote_left = float(boss_def["footnote_time"])
	game.stat_add("archivist_footnotes", 1.0)
	queue_redraw()


## Think slot of copy `k` (staggered off hers).
func _next_copy_slot(k: int) -> int:
	return (think_slot + 3 + 4 * k) % UnitData.AI_TICK_DIVISOR


## The copies walk with her until footnote_time runs out.
func _step_copies(delta: float) -> void:
	if footnote_left <= 0.0:
		return
	footnote_left -= delta
	if footnote_left <= 0.0:
		_dismiss_copies()


## The copies fade into blank pages.
func _dismiss_copies() -> void:
	footnote_left = 0.0
	for c in _copies:
		if c.active:
			game.effects.pop(c.position, ArchivistData.PAGE_COLOR, radius * 1.4)
			c.vanish()
	queue_redraw()


# =====================================================================================
# Erasure
# =====================================================================================

## Starts the Erasure, steps the edge inward and pushes the necromancer and
## the summons back inside it.
func _step_erasure(_delta: float) -> void:
	var now := game.elapsed
	if not erase_on:
		if now - _spawn_time < float(boss_def["erasure_start"]):
			return
		erase_on = true
		erase_center = game.player.position
		erase_radius = float(boss_def["erasure_radius"])
		_erase_next = now + float(boss_def["erasure_interval"])
		game.enemies.show_banner("ERASURE: the edges of the Archive are being unwritten!")
		game.stat_add("archivist_erasure_started", 1.0)
	if now >= _erase_next:
		_erase_next += float(boss_def["erasure_interval"])
		var nr := maxf(float(boss_def["erasure_min"]), erase_radius - float(boss_def["erasure_step"]))
		if nr < erase_radius:
			erase_radius = nr
			game.stat_add("archivist_erasure_steps", 1.0)
			game.shake(4.0)
	_contain(game.player)
	for u in game.horde.units:
		if u.active and u.state != SummonedUnit.State.SPAWNING and not u.airborne:
			_contain(u)
	_erase_layer.queue_redraw()


## Pushes `n` (the necromancer or a summon) back inside the edge.
func _contain(n: Node2D) -> void:
	var r: float = (n as SummonedUnit).radius if n is SummonedUnit else game.player.radius
	var off := n.position - erase_center
	var d := off.length()
	var lim := erase_radius - r - 1.0
	if d <= lim:
		return
	var at := erase_center + (off / d if d > 0.01 else Vector2.RIGHT) * lim
	if game.arena.is_blocked(at, r):
		at = game.arena.free_point(at, r)
	n.position = at
	game.stat_add("archivist_erasure_pushes", 1.0)


## The radius the next step will leave (the telegraphed edge).
func erase_next_radius() -> float:
	return maxf(float(boss_def["erasure_min"]), erase_radius - float(boss_def["erasure_step"]))


## 0..1 strength of the next edge's warning glow (only in the last
## erasure_telegraph s before a step; 0 at the minimum radius).
func erase_warning() -> float:
	if erase_radius <= float(boss_def["erasure_min"]):
		return 0.0
	var left := _erase_next - game.elapsed
	var tele := float(boss_def["erasure_telegraph"])
	return clampf(1.0 - left / tele, 0.0, 1.0) if left <= tele else 0.0


## Ends the Erasure, drops the pages and the copies (she fell).
func _end_fight() -> void:
	erase_on = false
	if _erase_layer != null:
		_erase_layer.queue_redraw()
	_dismiss_copies()
	if game.enemies.archive_haz != null:
		game.enemies.archive_haz.clear_pages()


## She fell: the edge stops, the pages crumble, the copies fade.
func _on_defeated() -> void:
	game.stats["archivist_kill_time"] = game.elapsed - _spawn_time
	_end_fight()
	if game.hud != null:
		game.hud.announce("THE LAST PAGE BURNS", "The Archivist falls", "You know now where the god sleeps.", ArchivistData.PAGE_COLOR)
	game.enemies.banner_until = game.elapsed + ArchivistData.ENDING_BANNER_TIME


func deactivate() -> void:
	super.deactivate()
	_end_fight()


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: away from the closing edge.
func danger_push(p: Vector2) -> Vector2:
	if not erase_on:
		return Vector2.ZERO
	var off := p - erase_center
	var d := off.length()
	var edge := (erase_next_radius() if erase_warning() > 0.0 else erase_radius) - 50.0
	if d > edge and d > 0.1:
		return -off / d
	return Vector2.ZERO


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/archivist"


## Ground layer (Enemy._draw()): nothing under her.
func _draw_under() -> void:
	pass


## Body layer on `ci`: the Archivist in the pose of her current phase.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 0
	match phase:
		Phase.RECITE:
			pose = 1
		Phase.FOOTNOTE_CAST:
			pose = 2
		Phase.RECOVER:
			pose = 3
	if not SpriteBank.draw_pose(ci, "bosses/archivist", pose, Vector2.ZERO, flash > 0.0):
		ArchiveGlyphs.draw_archivist(ci, Vector2.ZERO, radius, flash > 0.0, pose, true)


## Overlay layer on `ci`: the reading glow, the aura chevron and the Stasis ice.
func _draw_over(ci: CanvasItem) -> void:
	if phase == Phase.RECITE or phase == Phase.FOOTNOTE_CAST:
		ArchiveGlyphs.draw_reading_glow(ci, Vector2(0, -radius * 1.6), radius)
	if buff_time > 0.0:
		MarchGlyphs.draw_buffed(ci, Vector2(0, -radius * 2.6), 5.0)  # A cult aura buff.
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)  # Stasis / Deep Freeze.


## One-line autotest summary of her fight (times relative to her arrival).
static func summary_line(st: Dictionary) -> String:
	var phases := PackedStringArray()
	for i in [1, 2]:
		var key := "archivist_phase%d_time" % i
		phases.append(("phase %d at +%.0f s" % [i, float(st[key])]) if st.has(key) else ("phase %d never" % i))
	return "%s | killed %s | recitations %d (pages %d: hit the necromancer %d, summons %d, crumbled %d; ink pools %d) | footnotes %d (blows on copies %d, damage wasted %d) | erasure steps %d, pushes %d" % [
		", ".join(phases), ("at +%.0f s" % float(st["archivist_kill_time"])) if st.has("archivist_kill_time") else "no",
		int(st.get("boss_atk_recitation", 0.0)), int(st.get("archivist_pages", 0.0)), int(st.get("archivist_page_player_hits", 0.0)),
		int(st.get("archivist_page_summon_hits", 0.0)), int(st.get("archivist_pages_crumbled", 0.0)), int(st.get("archive_ink_pools", 0.0)),
		int(st.get("archivist_footnotes", 0.0)), int(st.get("archivist_copy_hits", 0.0)), int(st.get("dmg_resisted_" + ArchiveEnemyData.COPY, 0.0)),
		int(st.get("archivist_erasure_steps", 0.0)), int(st.get("archivist_erasure_pushes", 0.0))]
