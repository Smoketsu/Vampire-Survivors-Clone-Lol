## BossOdin — ODIN AND FENRIR, the boss of Vigrid, the Last Field, and the
## finale of the Hall of the Slain (the Norse act, temporarily Act XI; GDD
## §15.0 "Odin and Fenrir (Vigrid)"; owner-approved proposal: "the one-eyed
## god, male, and the great wolf: the Wolf, the All-Father, Ragnarök"). Loaded
## by name for the boss id "odin" (EnemyDirector.NORSE_BOSS_DIR +
## "boss_odin.gd"); he arrives at 17:00 (3:00 left) with Fenrir (the kind
## "fenrir", FenrirKit, on the miniboss bar) beside him. Extends Boss, so
## summons, spells and the spatial hash treat Odin like any enemy. Every number
## is OdinData.BOSS's; the phases are documented in OdinData:
##   THE WOLF       Fenrir hunts and swallows (FenrirKit); Odin stands watch,
##                  untargetable and unharmed;
##   THE ALL-FATHER Fenrir is chained at his side (FenrirKit.set_leash());
##                  Odin walks at the necromancer, throws GUNGNIR (the spear
##                  that homes on the strongest summon, or on the necromancer
##                  while his ravens mark him; only a Bone Wall across its path,
##                  EmpireShots.wall_block_t(), or Grave Step's i-frames stop
##                  it) and sends his RAVENS (OdinRavenKit, mark_player());
##   RAGNARÖK       both fight; the arena burns (rings of fire through
##                  EnemyDirector.province_hazards().add_fire(), the pooled
##                  enemy fire path); when one falls the other follows within
##                  doom_time s (Fenrir's doom: FenrirKit.doom_at; Odin's: here).
## The shared Norse rules are created on first use (Game.norse_rules()), so
## --boss=odin works on any stage. Killing Odin drops a big XP burst and the
## boss chest; slaying him unlocks Gungnir and Runecraft, the Draugr Thane and
## Cold Iron (UnlockData, boss "odin"); TWILIGHT OF THE WOLF (MetaData) counts a
## boss kill on Vigrid (the stage record): Fenrir always follows him. Attack
## pose (BossPoseData, when the art has one): pose 1 while he aims Gungnir.
## Determinism: no RNG (fixed turns for the rings of fire and the ravens).
## Stats: boss_atk_<special>, odin_wolf_time, odin_allfather_at,
## odin_ragnarok_at, odin_gungnir_throws, odin_gungnir_at_you,
## odin_gungnir_hits, odin_gungnir_hits_you, odin_gungnir_walled,
## odin_gungnir_dodged, odin_ravens, odin_marks,
## odin_doomed (he followed the wolf), fenrir_doomed (FenrirKit),
## odin_kill_time.
class_name BossOdin
extends Boss

## His phases.
enum Phase { ARRIVING, WOLF, ALLFATHER, RAGNAROK }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds in the current phase.
var phase_time: float = 0.0
## Fenrir (generation-checked; null once he is gone).
var fenrir: Enemy = null
## Pool generation of `fenrir`.
var fenrir_gen: int = 0
## True once Fenrir fell (Odin's doom then runs).
var fenrir_fell: bool = false
## Game time (s) the doom of Ragnarok takes Odin (INF = none).
var doom_at: float = INF
## Seconds until the next Gungnir.
var gungnir_cd: float = INF
## Seconds until the next ravens.
var raven_cd: float = INF
## Seconds until the next ring of fire (Ragnarok).
var fire_cd: float = INF
## Rings of fire so far (turns the next ring: no RNG).
var fire_rings: int = 0
## Necromancers his ravens marked: [Necromancer, until (game s)] pairs.
var _marks: Array = []
## The spear: 0 none, 1 aiming (the telegraphed line), 2 in flight.
var _spear: int = 0
## Seconds into the spear's current state.
var _spear_t: float = 0.0
## The spear's mark (a summon or a necromancer).
var _spear_target: Node2D = null
## Pool generation of a summon mark (0 for a necromancer).
var _spear_gen: int = 0
## Where the spear is (world px).
var _spear_pos: Vector2 = Vector2.ZERO
## Where the spear flies to (its mark's last known spot, world px).
var _spear_to: Vector2 = Vector2.ZERO
## His walking speed (px/s) of the current phase.
var _base_speed: float = 50.0
## Game time (s) he arrived (kill time).
var _spawn_time: float = 0.0


## Sets up Odin at `pos` with HP scaled by `hp_mult`, and Fenrir beside him.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = OdinData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	fenrir_fell = false
	doom_at = INF
	gungnir_cd = INF
	raven_cd = INF
	fire_cd = INF
	fire_rings = 0
	_marks.clear()
	_spear = 0
	_spear_target = null
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	untargetable = true  # He stands at the field's edge until the Wolf is loosed.
	var rules := game.norse_rules()  # The shared rules exist wherever he fights.
	var at := position + Vector2.from_angle((game.player.position - position).angle() + PI * 0.5) * float(boss_def["fenrir_offset"])
	fenrir = game.enemies.spawn_at(VigridEnemyData.FENRIR, at, false)
	if fenrir != null:
		fenrir_gen = fenrir.generation
		fenrir.max_hp = float(boss_def["fenrir_hp"]) * hp_mult
		fenrir.hp = fenrir.max_hp
		fenrir.untargetable = true
		if fenrir.kit is FenrirKit:
			(fenrir.kit as FenrirKit).set_leash(fenrir, true)
			(fenrir.kit as FenrirKit).leash_to = fenrir.position
	rules.play_sound("ragnarok", position, 1.0)
	game.enemies.boss_defeated.connect(_on_defeated)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return OdinData.SPECIALS


## The sprite key of his art.
func motion_sprite_key() -> String:
	return OdinData.SPRITE


## True while he walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.ALLFATHER or phase == Phase.RAGNAROK) and _spear != 1


## Fenrir, alive (stale entries dropped), else null.
func fenrir_alive() -> Enemy:
	if fenrir != null and (not fenrir.active or fenrir.generation != fenrir_gen):
		fenrir = null
	return fenrir


## The ravens' touch (OdinRavenKit): necromancer `pl` is marked for `secs` s
## (his next Gungnir goes at him).
func mark_player(pl: Necromancer, secs: float) -> void:
	for m: Array in _marks:
		if m[0] == pl:
			m[1] = maxf(float(m[1]), game.elapsed + secs)
			return
	_marks.append([pl, game.elapsed + secs])
	game.stat_add("odin_marks", 1.0)
	queue_redraw()


## A marked, standing necromancer (the first), else null.
func marked() -> Necromancer:
	for m: Array in _marks:
		var pl: Necromancer = m[0]
		if float(m[1]) > game.elapsed and not pl.dead:
			return pl
	return null


## His fall (or any removal) ends the spear and the marks.
func deactivate() -> void:
	_spear = 0
	_spear_target = null
	_marks.clear()
	super.deactivate()


## Unharmed while he stands watch; his health never falls past Ragnarok's
## threshold before Ragnarok begins; doomed, every hit lands harder.
func damage_taken_mult(source: String) -> float:
	if source == OdinData.DOOM_SOURCE:
		return 1.0
	match phase:
		Phase.ARRIVING, Phase.WOLF:
			return 0.0
		Phase.ALLFATHER:
			if hp <= max_hp * float(boss_def["ragnarok_hp"]) + 1.0:
				return 0.0
	var m := super.damage_taken_mult(source)
	if doom_at < INF:
		m *= float(boss_def["doom_taken"])
	return m


# =====================================================================================
# Physics
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	_step_spear(delta)
	match phase:
		Phase.ARRIVING:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			_leash_fenrir()
			if phase_time >= float(boss_def["arrive_time"]):
				_begin_wolf()
		Phase.WOLF:
			_step_watch(delta)
			var f := fenrir_alive()
			if f == null or f.hp <= f.max_hp * float(boss_def["fenrir_retreat_hp"]) + 1.0 or phase_time >= float(boss_def["wolf_max"]):
				_begin_allfather()
		Phase.ALLFATHER:
			_leash_fenrir()
			_step_fight(delta, 1.0, float(boss_def["gungnir_every"]))
			if hp <= max_hp * float(boss_def["ragnarok_hp"]) + 1.0 or phase_time >= float(boss_def["allfather_max"]):
				_begin_ragnarok()
		Phase.RAGNAROK:
			_step_fight(delta, float(boss_def["ragnarok_speed_mult"]), float(boss_def["gungnir_every_ragnarok"]))
			_step_fires(delta)
	if not fenrir_fell and phase != Phase.ARRIVING and phase != Phase.WOLF and fenrir_alive() == null:
		_wolf_fell()
	if doom_at < INF and game.elapsed >= doom_at:
		doom_at = INF
		game.stat_add("odin_doomed", 1.0)
		game.combat.damage_enemy(self, hp * 100.0 + 1000000.0, OdinData.DOOM_SOURCE)  # He follows the wolf.
	if _spear != 0 or not _marks.is_empty():
		queue_redraw()


## Keeps Fenrir chained at his side (the arrival, the All-Father).
func _leash_fenrir() -> void:
	var f := fenrir_alive()
	if f == null or not (f.kit is FenrirKit):
		return
	var k := f.kit as FenrirKit
	if not k.leashed:
		k.set_leash(f, true)
	var side := (game.player.position - position).normalized().orthogonal() if position.distance_to(game.player.position) > 1.0 else Vector2.RIGHT
	k.leash_to = position + side * float(boss_def["fenrir_offset"])


## The Wolf: Fenrir breaks his chain; Odin stands watch.
func _begin_wolf() -> void:
	phase = Phase.WOLF
	phase_time = 0.0
	game.stat_add("boss_atk_wolf", 1.0)
	var f := fenrir_alive()
	if f != null and f.kit is FenrirKit:
		var k := f.kit as FenrirKit
		k.set_leash(f, false)
		k.hp_floor = f.max_hp * float(boss_def["fenrir_retreat_hp"])
	game.enemies.show_banner("THE WOLF: Fenrir breaks his chain and hunts your ring! He swallows your dead whole")
	game.effects.impact(f.position if f != null else position, 60.0, Palette.NORSE_IRON)
	game.shake(5.0)
	game.norse_rules().play_sound("wolf_lunge", position)
	queue_redraw()


## The Wolf: he stands watch watch_dist px from the necromancer, beyond reach.
func _step_watch(delta: float) -> void:
	_tick_timers(delta)
	var to := position - game.player.position
	var goal := game.player.position + (to.normalized() if to.length() > 1.0 else Vector2.UP) * float(boss_def["watch_dist"])
	var off := goal - position
	velocity = Vector2.ZERO
	if off.length() > 4.0:
		position += off.normalized() * minf(off.length(), _base_speed * 1.5 * delta)
	_update_facing()


## The All-Father: the wolf is chained at his side; he takes the field.
func _begin_allfather() -> void:
	game.stats["odin_wolf_time"] = phase_time
	phase = Phase.ALLFATHER
	phase_time = 0.0
	untargetable = false
	game.stat_add("boss_atk_allfather", 1.0)
	game.stats["odin_allfather_at"] = game.elapsed
	gungnir_cd = float(boss_def["gungnir_first"])
	raven_cd = float(boss_def["raven_first"])
	var f := fenrir_alive()
	if f != null and f.kit is FenrirKit:
		(f.kit as FenrirKit).hp_floor = 0.0
	_leash_fenrir()
	game.enemies.show_banner("THE ALL-FATHER: Odin takes up Gungnir! Only Grave Step or a Bone Wall turns his spear, and his ravens mark you for it")
	game.effects.ring(position, 120.0, Palette.NORSE_VALKYRIE_GOLD, 0.6)
	game.shake(4.0)
	queue_redraw()


## Ragnarok: the wolf is loosed again; the arena burns.
func _begin_ragnarok() -> void:
	phase = Phase.RAGNAROK
	phase_time = 0.0
	game.stat_add("boss_atk_ragnarok", 1.0)
	game.stats["odin_ragnarok_at"] = game.elapsed
	fire_cd = float(boss_def["fire_first"])
	var f := fenrir_alive()
	if f != null and f.kit is FenrirKit:
		var k := f.kit as FenrirKit
		k.set_leash(f, false)
		k.frenzied = true
	game.enemies.show_banner("RAGNAROK: the god and the wolf fight as one, and the field burns! When one falls, the other follows")
	game.effects.impact(position, 140.0, Palette.NORSE_FIRE)
	game.shake(8.0)
	game.norse_rules().play_sound("ragnarok", position)


## Fenrir fell first: the doom of Ragnarok takes Odin within doom_time s.
func _wolf_fell() -> void:
	fenrir_fell = true
	fenrir = null
	if phase == Phase.RAGNAROK or phase == Phase.ALLFATHER:
		doom_at = game.elapsed + float(boss_def["doom_time"])
		game.enemies.show_banner("Fenrir falls! The All-Father will follow him within 30 seconds")
		game.effects.ring(position, 90.0, Palette.NORSE_BERSERK, 0.6)


## Walking and fighting (the All-Father, Ragnarok): the shared walk and blow,
## Gungnir, the ravens.
func _step_fight(delta: float, speed_mult: float, gungnir_every: float) -> void:
	gungnir_cd -= delta
	raven_cd -= delta
	if _spear == 1:
		_tick_timers(delta)
		velocity = Vector2.ZERO
	else:
		var dist := position.distance_to(game.player.position)
		var spd := _base_speed * speed_mult
		if dist > float(boss_def["advance_range"]):
			spd *= float(boss_def["advance_speed_mult"])
			game.stat_add("boss_advance_time", delta)
		move_speed = spd
		super.physics_step(delta)
	if gungnir_cd <= 0.0 and _spear == 0 and not game.ultimates.player_untargetable():
		if _aim_gungnir():
			gungnir_cd = gungnir_every
		else:
			gungnir_cd = 1.0
	if raven_cd <= 0.0:
		raven_cd = float(boss_def["raven_every"])
		_send_ravens()


# =====================================================================================
# Gungnir
# =====================================================================================

## Picks the spear's mark (the marked necromancer, else the strongest summon in
## range, else the nearest necromancer in range) and starts the aim.
func _aim_gungnir() -> bool:
	var t: Node2D = marked()
	_spear_gen = 0
	if t == null:
		var reach := float(boss_def["gungnir_range"])
		game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
		var best: SummonedUnit = null
		for u: SummonedUnit in _tmp:
			if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if not u.visible or u.position.distance_to(position) > reach:
				continue
			if best == null or u.max_hp > best.max_hp or (u.max_hp == best.max_hp and u.position.distance_squared_to(position) < best.position.distance_squared_to(position)):
				best = u
		if best != null:
			t = best
			_spear_gen = best.generation
	if t == null:
		var pl := game.player
		if pl.dead or pl.position.distance_to(position) > float(boss_def["gungnir_range"]):
			return false
		t = pl
	if t is Necromancer:
		_clear_mark(t as Necromancer)
		game.stat_add("odin_gungnir_at_you", 1.0)
	_spear_target = t
	_spear = 1
	_spear_t = 0.0
	_spear_to = t.position
	_spear_pos = position
	var w := 10.0  # The line's lane (px each side).
	game.effects.telegraph_line(position, t.position, w, float(boss_def["gungnir_windup"]), self)
	motion_lunge(-(t.position - position).normalized(), MotionData.POWER_CAST)
	game.stat_add("boss_atk_gungnir", 1.0)
	game.stat_add("odin_gungnir_throws", 1.0)
	queue_redraw()
	return true


## The mark on `pl` is spent by the throw at him.
func _clear_mark(pl: Necromancer) -> void:
	var i := _marks.size() - 1
	while i >= 0:
		if _marks[i][0] == pl:
			_marks.remove_at(i)
		i -= 1


## True while the spear's mark is still the summon / necromancer it was.
func _mark_ok() -> bool:
	var t := _spear_target
	if t == null or not is_instance_valid(t):
		return false
	if t is SummonedUnit:
		var u := t as SummonedUnit
		return u.active and u.generation == _spear_gen and u.state != SummonedUnit.State.DEAD
	return not (t as Necromancer).dead


## The spear: the aim, then the flight that homes on its mark; a Bone Wall
## across its path stops it; on its mark it strikes (Grave Step's i-frames
## dodge it).
func _step_spear(delta: float) -> void:
	if _spear == 0:
		return
	_spear_t += delta
	if _spear == 1:
		_spear_pos = position
		if _mark_ok():
			_spear_to = _spear_target.position
		if _spear_t >= float(boss_def["gungnir_windup"]):
			_spear = 2
			_spear_t = 0.0
			game.norse_rules().play_sound("valkyrie_dive", position, 0.3)
		return
	if _mark_ok():
		_spear_to = _spear_target.position
	var to := _spear_to - _spear_pos
	var step := float(boss_def["gungnir_speed"]) * delta
	var nxt := _spear_pos + to.normalized() * minf(step, to.length()) if to.length() > 0.01 else _spear_pos
	var wt := EmpireShots.wall_block_t(game, _spear_pos, nxt, 3.0)  # THE wall loop: a Bone Wall across its path.
	if wt < INF:
		var at := _spear_pos.lerp(nxt, clampf(wt, 0.0, 1.0))
		game.stat_add("odin_gungnir_walled", 1.0)
		game.effects.impact(at, 26.0, Palette.NORSE_VALKYRIE_GOLD)
		game.shake(2.0)
		_spear = 0
		_spear_target = null
		return
	_spear_pos = nxt
	if _spear_pos.distance_to(_spear_to) <= 2.0 or _spear_t > 3.0:
		_strike()


## The spear reaches its mark.
func _strike() -> void:
	var t := _spear_target
	var ok := _mark_ok()
	_spear = 0
	_spear_target = null
	game.effects.impact(_spear_pos, 30.0, Palette.NORSE_VALKYRIE_GOLD)
	if not ok:
		return
	var mult := game.enemies.damage_mult * hit_mult()  # Time scaling x buffs.
	if t is Necromancer:
		var pl := t as Necromancer
		if pl.iframes > 0.0:
			game.stat_add("odin_gungnir_dodged", 1.0)  # Grave Step's i-frames (or a hit's): it passes through his shadow.
			return
		game.combat.damage_player(float(boss_def["gungnir_damage_player"]) * mult, OdinData.SRC_GUNGNIR, pl, self)
		game.stat_add("odin_gungnir_hits_you", 1.0)
		game.shake(4.0)
		return
	var u := t as SummonedUnit
	game.combat.damage_unit(u, float(boss_def["gungnir_damage_summon"]) * mult * undead_damage_mult, OdinData.SRC_GUNGNIR, self)
	game.stat_add("odin_gungnir_hits", 1.0)
	if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne:
		var dir := (u.position - position).normalized() if u.position.distance_to(position) > 1.0 else Vector2.RIGHT
		u.position += dir * game.arena.clear_length(u.position, dir, float(boss_def["gungnir_push"]), u.radius)
	game.shake(2.5)


# =====================================================================================
# The ravens and the burning field
# =====================================================================================

## Huginn and Muninn leave his shoulders and fly at the necromancer.
func _send_ravens() -> void:
	var n := int(boss_def["ravens"])
	var side := (game.player.position - position).normalized().orthogonal() if position.distance_to(game.player.position) > 1.0 else Vector2.RIGHT
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * float(boss_def["raven_spread"])
		var e := game.enemies.spawn_at(VigridEnemyData.RAVEN, position + side * off + Vector2(0.0, -radius), false)
		if e != null:
			game.stat_add("odin_ravens", 1.0)
	game.stat_add("boss_atk_ravens", 1.0)


## Ragnarok's rings of fire round the necromancer.
func _step_fires(delta: float) -> void:
	fire_cd -= delta
	if fire_cd > 0.0:
		return
	fire_cd = float(boss_def["fire_every"])
	var p := game.player.position
	var n := maxi(1, int(boss_def["fire_points"]))
	var turn := float(fire_rings) * 0.45  # A fixed turn per ring (no RNG).
	fire_rings += 1
	var mult := game.enemies.damage_mult * hit_mult()
	var haz := game.enemies.province_hazards()
	for i in n:
		var at := p + Vector2.from_angle(turn + TAU * float(i) / float(n)) * float(boss_def["fire_ring"])
		haz.add_fire(game.arena.free_point(at, 4.0), float(boss_def["fire_patch"]), float(boss_def["fire_life"]), 0.5,
				float(boss_def["fire_dmg_player"]) * mult, float(boss_def["fire_dmg_summon"]) * mult, 0.0, OdinData.SRC_FIRE)
	game.stat_add("boss_atk_burning", 1.0)
	game.effects.ring(p, float(boss_def["fire_ring"]), Palette.NORSE_FIRE, 0.5)


# =====================================================================================
# Death, autopilot, drawing, report
# =====================================================================================

## His defeat (EnemyDirector.boss_defeated, after the reward burst): the ending
## text; the wolf follows him within doom_time s.
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 240.0, Palette.NORSE_VALKYRIE_GOLD, 1.0)
	Juice.fx.burst(pos, Palette.NORSE_VALKYRIE_GOLD, Palette.NORSE_FROST, 24, 300.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var f := fenrir_alive()
	if f != null and f.kit is FenrirKit:
		var k := f.kit as FenrirKit
		k.set_leash(f, false)
		k.hp_floor = 0.0
		k.frenzied = true
		k.taken_bonus = float(boss_def["doom_taken"])
		k.doom_at = game.elapsed + float(boss_def["doom_time"])
	var late := game.countdown_finished()
	game.enemies.show_banner(String(OdinData.ARRIVAL["defeat_banner"]) + (" Fenrir will follow within 30 seconds!" if f != null else ""))
	game.enemies.banner_until = game.elapsed + OdinData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = OdinData.LATE_ANNOUNCE if late else OdinData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.NORSE_VALKYRIE_GOLD)
	game.stats[OdinData.KILL_TIME_STAT] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: sideways off Gungnir's line while it
## is aimed at (or flies at) the necromancer.
func danger_push(p: Vector2) -> Vector2:
	if _spear == 0 or not (_spear_target is Necromancer):
		return Vector2.ZERO
	var a := _spear_pos
	var b := _spear_to
	var ab := b - a
	if ab.length() < 1.0:
		return Vector2.ZERO
	var k := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var off := p - a.lerp(b, k)
	var reach := 40.0
	if off.length() >= reach:
		return Vector2.ZERO
	var side := off.normalized() if off.length() > 0.5 else ab.normalized().orthogonal()
	return side * (1.0 - off.length() / reach) * 2.5


## Body layer on `ci`: his sprite (pose 1 while he aims Gungnir), dim while he
## stands watch beyond reach.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 1 if _spear == 1 else 0
	var tint := Color(0.75, 0.78, 0.86, 0.85) if untargetable else Color.WHITE
	if doom_at < INF:
		tint = Color(1.0, 0.7, 0.62)
	if not SpriteBank.draw_pose(ci, OdinData.SPRITE, pose, Vector2.ZERO, flash > 0.0, tint):
		NorseGlyphs.draw_enemy(ci, NorseEnemyData.SKALD, Vector2.ZERO, radius, flash > 0.0)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: his shadow, the spear in flight and the ravens' marks over the
## marked necromancer (textures; world points through the unmirror transform).
func _draw_under() -> void:
	super._draw_under()
	var r := radius * 1.3
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, radius * 0.6), Vector2(r * 2.0, r * 0.6)), false, Color(0.0, 0.0, 0.0, 0.3))
	if game == null:
		return
	if _spear == 0 and _marks.is_empty():
		return
	var xf := CourtGlyphs.unmirror_xf(self)
	if _spear == 2:
		var dir := (_spear_to - _spear_pos)
		var ang := dir.angle() if dir.length() > 0.01 else 0.0
		draw_set_transform_matrix(xf * Transform2D(ang, _spear_pos - position))
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-18.0, -1.5), Vector2(28.0, 3.0)), false, Palette.NORSE_VALKYRIE_GOLD)
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(6.0, -3.0), Vector2(8.0, 6.0)), false, Palette.NORSE_VALK_GLOW)
	for m: Array in _marks:
		var pl: Necromancer = m[0]
		if float(m[1]) <= game.elapsed or pl.dead:
			continue
		var a := game.elapsed * 3.0
		var at := pl.position + Vector2(cos(a) * 14.0, -34.0 + sin(a) * 4.0) - position
		draw_set_transform_matrix(xf)
		if not SpriteBank.draw_flat(self, VigridEnemyData.RAVEN_SPRITE, at, 0.0):
			SpriteBank.draw_disc(self, at, 4.0, Palette.NORSE_INK)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var af := float(st.get("odin_allfather_at", -1.0))
	var rg := float(st.get("odin_ragnarok_at", -1.0))
	return "the wolf %ds (fenrir lunges %d, swallows %d, spat %d, died inside %d) | the all-father %s (gungnir %d: at summons %d, at you %d, hits %d / on you %d, walled %d, dodged %d; ravens %d, marks %d) | ragnarok %s (rings of fire %d) | doom: odin %d, fenrir %d | killed in %ds | dmg to you %d (gungnir %d, fire %d, fenrir %d, touch %d), to summons %d (gungnir %d, maw %d, fire %d)" % [
		int(st.get("odin_wolf_time", 0.0)), int(st.get("fenrir_lunges", 0.0)), int(st.get("fenrir_swallows", 0.0)), int(st.get("fenrir_spat", 0.0)), int(st.get("fenrir_digested", 0.0)),
		EmpireReport._clock(af) if af >= 0.0 else "not reached", int(st.get("odin_gungnir_throws", 0.0)),
		int(st.get("odin_gungnir_throws", 0.0)) - int(st.get("odin_gungnir_at_you", 0.0)), int(st.get("odin_gungnir_at_you", 0.0)),
		int(st.get("odin_gungnir_hits", 0.0)), int(st.get("odin_gungnir_hits_you", 0.0)), int(st.get("odin_gungnir_walled", 0.0)), int(st.get("odin_gungnir_dodged", 0.0)),
		int(st.get("odin_ravens", 0.0)), int(st.get("odin_marks", 0.0)),
		EmpireReport._clock(rg) if rg >= 0.0 else "not reached", int(st.get("boss_atk_burning", 0.0)),
		int(st.get("odin_doomed", 0.0)), int(st.get("fenrir_doomed", 0.0)), int(st.get(OdinData.KILL_TIME_STAT, 0.0)),
		int(st.get("player_dmg_from_" + OdinData.SRC_GUNGNIR, 0.0)) + int(st.get("player_dmg_from_" + OdinData.SRC_FIRE, 0.0)) + int(st.get("player_dmg_from_fenrir", 0.0)) + int(st.get("player_dmg_from_" + VigridEnemyData.LUNGE_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("player_dmg_from_" + OdinData.SRC_GUNGNIR, 0.0)), int(st.get("player_dmg_from_" + OdinData.SRC_FIRE, 0.0)),
		int(st.get("player_dmg_from_fenrir", 0.0)) + int(st.get("player_dmg_from_" + VigridEnemyData.LUNGE_SOURCE, 0.0)), int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + OdinData.SRC_GUNGNIR, 0.0)) + int(st.get("summon_dmg_from_" + VigridEnemyData.MAW_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + OdinData.SRC_FIRE, 0.0)) + int(st.get("summon_dmg_from_fenrir", 0.0)) + int(st.get("summon_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + OdinData.SRC_GUNGNIR, 0.0)), int(st.get("summon_dmg_from_" + VigridEnemyData.MAW_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + OdinData.SRC_FIRE, 0.0))]
