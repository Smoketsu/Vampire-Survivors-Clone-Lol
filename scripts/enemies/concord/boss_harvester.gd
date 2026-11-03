## BossHarvester — THE HARVESTER, the boss of the Ark of the Concord and of Act
## IX (the Concord of Stars; GDD §15.0 "The Harvester (Act IX)"; owner-approved
## proposal: "the oldest of its kind, the one who planted the world. The
## Council (it fights with the Concord's powers in turn: the Brood's swarms,
## the Vrask's cloak, the Luminous beams), the Reaping (it opens a tractor
## beam over the whole ring, and every summon starts rising. Four beam
## emitters around the arena must be destroyed before the army is gone), the
## Gardener (it reveals its true form, a vast being of light and rings, and
## turns the world below into its weapon). When it falls, the stars go dark
## too"; owner: a plain finale, no twist, no epilogue). Loaded by name for the
## boss id "harvester" (EnemyDirector.CONCORD_BOSS_DIR + "boss_harvester.gd");
## it arrives at 17:00 (3:00 left). A tall grey, sex unmarked as the greys
## are, floating above a throne of rings. Extends Boss, so summons, spells and
## the spatial hash treat it like any enemy. Every number is
## HarvesterData.BOSS's; the phases are documented in HarvesterData. Every
## attack goes through the act's one paths: its beams through
## ConcordBeams.fire() (boss override), the Reaping's lifts through
## Abduction.lift() (ReapEmitterKit), the Gardener's turf through
## Terraforming.seed(); its swarms and adds are ordinary spawns. The shared
## rules are created on first use (Game.concord_rules()), so --boss=harvester
## works on any stage (the turf then grows and heals there too; the Final
## Harvest stays off). Killing it drops a big XP burst and the boss chest;
## slaying it unlocks Tractor Beam and Starseed, the Ghost Saucer and Crop
## Circles (UnlockData, boss "harvester"); THE LAST HARVEST (MetaData) counts
## a boss kill on the Ark (the stage record). Attack pose (BossPoseData, when
## the art has one): pose 1 while it calls a power or reaps.
## Determinism: no RNG (fixed turns for the emitters and the rings).
## Stats: boss_atk_<special>, harvester_reaping_at, harvester_reaping_time,
## harvester_gardener_at, harvester_kill_time, harvester_cloak_cut,
## harvester_reveals, harvester_rings, harvester_adds.
class_name BossHarvester
extends Boss

## Its phases.
enum Phase { ARRIVING, COUNCIL, REAPING, GARDENER }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds in the current phase.
var phase_time: float = 0.0
## Seconds until its next Council power.
var power_cd: float = 0.0
## Index of its next Council power (HarvesterData.COUNCIL_POWERS, cycling).
var power_index: int = 0
## Game time (s) until which it is cloaked (the Vrask's cloak).
var cloak_until: float = 0.0
## Game time (s) until which a spell hit reveals it.
var revealed_until: float = 0.0
## The Reaping's emitters (generation-checked).
var _emitters: Array[Enemy] = []
## Pool generation of each entry of `_emitters`.
var _emitter_gens: PackedInt32Array = PackedInt32Array()
## True when this boss set Abduction.uncapped for the Reaping (it clears it).
var _uncapped_by_me: bool = false
## Seconds until the Gardener's next ring of turf.
var ring_cd: float = INF
## Seconds until the Gardener's next adds.
var adds_cd: float = INF
## Seconds until the Gardener's next luminous beams.
var beam_cd: float = INF
## Rings of turf grown so far (turns the next ring: no RNG).
var rings: int = 0
## Adds calls so far (picks the next HarvesterData.ADDS kind).
var adds_calls: int = 0
## Its walking speed (px/s) of the current phase.
var _base_speed: float = 44.0
## Game time (s) it arrived (kill time).
var _spawn_time: float = 0.0


## Sets up the Harvester at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = HarvesterData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	power_cd = float(boss_def["council_first"])
	power_index = 0
	cloak_until = 0.0
	revealed_until = 0.0
	_emitters.clear()
	_emitter_gens.clear()
	_uncapped_by_me = false
	ring_cd = INF
	adds_cd = INF
	beam_cd = INF
	rings = 0
	adds_calls = 0
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	game.concord_rules().play_sound("harvest_eye", position)  # The shared rules exist wherever it fights.
	game.enemies.boss_defeated.connect(_on_defeated)


## Its abilities in report order (Boss hook).
func special_ids() -> Array:
	return HarvesterData.SPECIALS


## True while it glides at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return phase == Phase.COUNCIL or phase == Phase.GARDENER


## True during the Reaping (ArkDirector's objective line).
func is_reaping() -> bool:
	return phase == Phase.REAPING


## True while the Vrask's cloak hides it (moving, not revealed).
func is_cloaked() -> bool:
	return game.elapsed < cloak_until and game.elapsed >= revealed_until


## Its fall (or any removal) ends the Reaping's hold on the cap.
func deactivate() -> void:
	_end_reaping_cap()
	super.deactivate()


## Immune while it descends and through the Reaping; its health never falls
## past the Reaping's threshold before the Reaping begins. While cloaked
## (the Vrask's cloak, the hunter's rule and numbers): a spell hit lands in
## full and reveals it; any other hit deals cloaked_taken of itself.
func damage_taken_mult(source: String) -> float:
	match phase:
		Phase.ARRIVING, Phase.REAPING:
			return 0.0
		Phase.COUNCIL:
			if hp <= max_hp * float(boss_def["reaping_hp"]) + 1.0:
				return 0.0
	var m := super.damage_taken_mult(source)
	if is_cloaked():
		var c: Dictionary = ConcordEnemyData.ENEMIES[ConcordEnemyData.VRASK_HUNTER]["cloak"]  # The Vrask cloak's numbers.
		if HundredShadowsData.is_spell_source(source):
			revealed_until = game.elapsed + float(c["reveal_time"])
			game.stat_add("harvester_reveals", 1.0)
			queue_redraw()
		else:
			game.stat_add("harvester_cloak_cut", 1.0)
			m *= float(c["cloaked_taken"])
	return m


# =====================================================================================
# Physics
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	match phase:
		Phase.ARRIVING:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.COUNCIL)
		Phase.COUNCIL:
			_step_council(delta)
			if hp <= max_hp * float(boss_def["reaping_hp"]) + 1.0:
				_begin_reaping()
		Phase.REAPING:
			_step_reaping(delta)
		Phase.GARDENER:
			_step_gardener(delta)


## Starts phase `p`.
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Glides at the necromancer (the shared walk and touch; faster from afar).
func _walk(delta: float, mult: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed * mult
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)


# =====================================================================================
# The Council
# =====================================================================================

## The Council: it glides at the necromancer and calls a power every turn.
func _step_council(delta: float) -> void:
	power_cd -= delta
	_walk(delta, float(boss_def["cloak_speed_mult"]) if is_cloaked() else 1.0)
	if power_cd > 0.0 or game.ultimates.player_untargetable():
		return
	power_cd = float(boss_def["council_turn"])
	var power := String(HarvesterData.COUNCIL_POWERS[power_index % HarvesterData.COUNCIL_POWERS.size()])
	power_index += 1
	match power:
		"brood":
			_brood_swarms()
		"vrask":
			_vrask_cloak()
		_:
			_luminous_beams()


## The Brood's swarms: broodlings burst from the ring's edge round him.
func _brood_swarms() -> void:
	game.stat_add("boss_atk_brood_swarm", 1.0)
	for _s in int(boss_def["brood_swarms"]):
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		game.enemies.spawn_formation("ring", [{"kind": ConcordEnemyData.BROODLING, "count": int(boss_def["brood_count"]), "elite": false}])
	game.enemies.show_banner("The Harvester calls the Brood!")
	game.concord_rules().play_sound("brood_chitter", position, 0.3)
	motion_lunge(Vector2.UP, MotionData.POWER_CAST)


## The Vrask's cloak: a shimmer for cloak_time s.
func _vrask_cloak() -> void:
	game.stat_add("boss_atk_vrask_cloak", 1.0)
	cloak_until = game.elapsed + float(boss_def["cloak_time"])
	revealed_until = 0.0
	game.enemies.show_banner("The Harvester takes the Vrask's cloak! Spells reveal it")
	game.effects.ring(position, radius * 2.0, Palette.CONCORD_VRASK, 0.4)
	queue_redraw()


## The Luminous beams: a fan of sweep beams and an eye beam at the necromancer
## (ConcordBeams.fire(), the boss override).
func _luminous_beams() -> void:
	game.stat_add("boss_atk_luminous_beams", 1.0)
	var beams := game.concord_rules().beams
	var to := game.player.position - position
	var base := to.angle() if to.length() > 1.0 else 0.0
	var n := int(boss_def["lumen_beams"])
	var spread := float(boss_def["lumen_spread"])
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * spread
		var over: Dictionary = (boss_def["lumen_overrides"] as Dictionary).duplicate()
		over["source"] = HarvesterData.SRC_BEAM
		beams.fire(self, Vector2.from_angle(base + off), "sweep", over, true)
	var eye: Dictionary = (boss_def["eye_overrides"] as Dictionary).duplicate()
	eye["source"] = HarvesterData.SRC_BEAM
	eye["target"] = game.player
	beams.fire(self, Vector2.from_angle(base), "eye", eye, true)
	motion_lunge(Vector2.from_angle(base), MotionData.POWER_CAST)


# =====================================================================================
# The Reaping
# =====================================================================================

## The Reaping: it rises, immune; the emitters land round the necromancer and
## the abduction cap is lifted for the phase.
func _begin_reaping() -> void:
	_enter(Phase.REAPING)
	cloak_until = 0.0
	velocity = Vector2.ZERO
	game.stat_add("boss_atk_reaping", 1.0)
	game.stats["harvester_reaping_at"] = game.elapsed
	var ab := game.concord_rules().abduction
	if not ab.uncapped:
		ab.uncapped = true
		_uncapped_by_me = true
	var p := game.player.position
	var n := int(boss_def["emitters"])
	for i in n:
		var at := p + Vector2.from_angle(PI * 0.25 + TAU * float(i) / float(maxi(1, n))) * float(boss_def["emitter_dist"])
		var e := game.enemies.spawn_at(HarvesterData.EMITTER, at, false)
		if e != null:
			_emitters.append(e)
			_emitter_gens.append(e.generation)
	game.enemies.show_banner("THE REAPING: the Harvester's tractor beam covers your ring! Destroy the emitters before your army is gone!")
	game.concord_rules().play_sound("tractor_beam", position)
	game.effects.ring(p, 160.0, Palette.CONCORD_PLASMA, 0.8)
	game.shake(4.0)


## Living emitters now (stale entries dropped).
func emitters_left() -> int:
	var i := _emitters.size() - 1
	while i >= 0:
		if not _emitters[i].active or _emitters[i].generation != _emitter_gens[i]:
			_emitters.remove_at(i)
			_emitter_gens.remove_at(i)
		i -= 1
	return _emitters.size()


## The Reaping: it hovers immune near the necromancer until the emitters have
## fallen (or reaping_max s pass: the last ones fall silent and drop what they
## hold), then the Gardener.
func _step_reaping(delta: float) -> void:
	_tick_timers(delta)
	var to := game.player.position - position
	var keep := 170.0  # px it hovers from the necromancer while it reaps.
	if to.length() > keep + 10.0:
		position += to.normalized() * minf(to.length() - keep, _base_speed * delta)
	velocity = Vector2.ZERO
	var left := emitters_left()
	if (left == 0 and phase_time >= 1.0) or phase_time >= float(boss_def["reaping_max"]):
		for e in _emitters:
			game.enemies.despawn(e)  # Silenced: each drops what it holds (the rescue).
		_emitters.clear()
		_emitter_gens.clear()
		game.stats["harvester_reaping_time"] = phase_time
		_end_reaping_cap()
		_begin_gardener()


## Gives the abduction cap back (unless the Final Harvest holds it lifted).
func _end_reaping_cap() -> void:
	if not _uncapped_by_me or game == null or game.concord == null:
		_uncapped_by_me = false
		return
	_uncapped_by_me = false
	game.concord.abduction.uncapped = game.concord.harvest.running()


# =====================================================================================
# The Gardener
# =====================================================================================

## The Gardener: its true form; rings of live turf, adds, beams.
func _begin_gardener() -> void:
	_enter(Phase.GARDENER)
	game.stat_add("boss_atk_gardener", 1.0)
	game.stats["harvester_gardener_at"] = game.elapsed
	ring_cd = float(boss_def["ring_first"])
	adds_cd = float(boss_def["adds_first"])
	beam_cd = 3.0
	game.enemies.show_banner("THE GARDENER: the Harvester reveals its true form, and the world below becomes its weapon! Burn the turf with your spells")
	game.effects.impact(position, radius * 5.0, Palette.CONCORD_LUMEN)
	game.shake(8.0)
	game.concord_rules().play_sound("harvest_eye", position)


## The Gardener's turns: rings of turf round the necromancer, adds, beams.
func _step_gardener(delta: float) -> void:
	ring_cd -= delta
	adds_cd -= delta
	beam_cd -= delta
	_walk(delta, float(boss_def["gardener_speed_mult"]))
	if ring_cd <= 0.0:
		ring_cd = float(boss_def["ring_every"])
		_grow_ring()
	if adds_cd <= 0.0:
		adds_cd = float(boss_def["adds_every"])
		_call_adds()
	if beam_cd <= 0.0 and not game.ultimates.player_untargetable():
		beam_cd = float(boss_def["gardener_beam_every"])
		_luminous_beams()


## A ring of live turf round the necromancer (THE ground: Terraforming.seed()).
func _grow_ring() -> void:
	var t := game.concord_rules().terraforming
	var p := game.player.position
	var n := maxi(1, int(boss_def["ring_points"]))
	var turn := float(rings) * 0.4  # A fixed turn per ring (no RNG).
	rings += 1
	for i in n:
		var at := p + Vector2.from_angle(turn + TAU * float(i) / float(n)) * float(boss_def["ring_radius"])
		t.seed(at, float(boss_def["ring_patch"]), {"live": true, "tag": "gardener"})
	game.stat_add("boss_atk_gardener_ring", 1.0)
	game.stat_add("harvester_rings", 1.0)
	game.effects.ring(p, float(boss_def["ring_radius"]), Palette.CONCORD_TURF, 0.6)


## Adds that heal on its turf (the shared heal), the kinds in turn.
func _call_adds() -> void:
	var kind := String(HarvesterData.ADDS[adds_calls % HarvesterData.ADDS.size()])
	adds_calls += 1
	if game.enemies.regular_alive() >= game.enemies.hard_cap():
		return
	var n := int(boss_def["adds_count"]) * (2 if kind == ConcordEnemyData.BROODLING else 1)
	if kind == ConcordEnemyData.LUMEN_SENTINEL:
		n = maxi(1, n / 3)
	game.enemies.spawn_formation("arc", [{"kind": kind, "count": n, "elite": false}])
	game.stat_add("boss_atk_gardener_adds", 1.0)
	game.stat_add("harvester_adds", float(n))


# =====================================================================================
# Death, drawing, report
# =====================================================================================

## Its defeat (EnemyDirector.boss_defeated, after the reward burst): the
## ending text (the stars go dark). The Last Harvest is the stage record's
## boss kill (MetaData), no epilogue.
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 260.0, Palette.CONCORD_LUMEN, 1.0)
	game.effects.ring(pos, 150.0, Palette.CONCORD_PLASMA, 0.8)
	Juice.fx.burst(pos, Palette.CONCORD_LUMEN, Palette.CONCORD_HULL, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var late := game.countdown_finished()  # It fell during the Final Harvest.
	game.enemies.show_banner(String(HarvesterData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + HarvesterData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = HarvesterData.LATE_ANNOUNCE if late else HarvesterData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.CONCORD_LUMEN)
	game.stats[HarvesterData.KILL_TIME_STAT] = game.elapsed - _spawn_time


## Body layer on `ci`: its throne of rings, then its sprite (its true form in
## the Gardener; pose 1 while it reaps), raised during the Reaping, a shimmer
## while cloaked.
func _draw_body(ci: CanvasItem) -> void:
	var lift := Vector2(0.0, -6.0)
	if phase == Phase.ARRIVING:
		var k := clampf(phase_time / maxf(float(boss_def["arrive_time"]), 0.01), 0.0, 1.0)
		lift = Vector2(0.0, -220.0 * (1.0 - k))
	elif phase == Phase.REAPING:
		var k := clampf(phase_time / maxf(float(boss_def["rise_time"]), 0.01), 0.0, 1.0)
		lift = Vector2(0.0, -6.0 - 30.0 * k)
	var a := 1.0
	if is_cloaked():
		var c: Dictionary = ConcordEnemyData.ENEMIES[ConcordEnemyData.VRASK_HUNTER]["cloak"]
		a = float(c["alpha"]) * (0.75 + 0.25 * sin(game.elapsed * 9.0))
	var true_form := phase == Phase.GARDENER
	ArkGlyphs.draw_throne(ci, lift, radius, game.elapsed, true_form, a)
	var pose := 1 if phase == Phase.REAPING else 0
	var tint := Color(1.0, 1.0, 1.0, a)
	if true_form and SpriteBank.draw(ci, HarvesterData.TRUE_SPRITE, lift, flash > 0.0, tint):
		return
	if SpriteBank.draw_pose(ci, HarvesterData.SPRITE, pose, lift, flash > 0.0, tint):
		if true_form:
			ArkGlyphs.draw_true_glow(ci, lift, radius, game.elapsed)
		return
	ArkGlyphs.draw_harvester(ci, lift, radius, flash > 0.0, a, true_form)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: its shadow and, during the Reaping, the tractor glow over the
## ring round the necromancer (a texture).
func _draw_under() -> void:
	super._draw_under()
	var r := radius * 1.4
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, radius * 0.6), Vector2(r * 2.0, r * 0.7)), false, Color(0.0, 0.0, 0.0, 0.3))
	if phase == Phase.REAPING and game != null:
		var xf := CourtGlyphs.unmirror_xf(self)
		draw_set_transform_matrix(xf)
		var at := game.player.position - position
		var k := 0.5 + 0.2 * sin(game.elapsed * 3.0)
		var rr := StanceData.RING_MAX + 20.0
		draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(rr, rr * 0.7), Vector2(rr * 2.0, rr * 1.4)), false, Color(Palette.CONCORD_PLASMA, 0.10 * k))
		draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of its fight.
static func summary_line(st: Dictionary) -> String:
	var reap := float(st.get("harvester_reaping_at", -1.0))
	var garden := float(st.get("harvester_gardener_at", -1.0))
	return "council: swarms %d, cloaks %d (hits cut %d, spell reveals %d), luminous beams %d | reaping %s (lasted %ds, emitter lifts %d, emitters destroyed %d) | gardener %s (rings %d, cells seeded %d, adds %d) | killed in %ds | dmg to you %d (beams %d, touch %d), to summons %d" % [
		int(st.get("boss_atk_brood_swarm", 0.0)), int(st.get("boss_atk_vrask_cloak", 0.0)), int(st.get("harvester_cloak_cut", 0.0)),
		int(st.get("harvester_reveals", 0.0)), int(st.get("boss_atk_luminous_beams", 0.0)),
		EmpireReport._clock(reap) if reap >= 0.0 else "not reached", int(st.get("harvester_reaping_time", 0.0)),
		int(st.get("reap_emitter_lifts", 0.0)), int(st.get("reap_emitters_down", 0.0)),
		EmpireReport._clock(garden) if garden >= 0.0 else "not reached", int(st.get("harvester_rings", 0.0)),
		int(st.get("terra_seeded_gardener", 0.0)), int(st.get("harvester_adds", 0.0)),
		int(st.get(HarvesterData.KILL_TIME_STAT, 0.0)),
		int(st.get("player_dmg_from_" + HarvesterData.SRC_BEAM, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("player_dmg_from_" + HarvesterData.SRC_BEAM, 0.0)), int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + HarvesterData.SRC_BEAM, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
