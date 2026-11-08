## FenrirKit — the kit of FENRIR, the great wolf (VigridEnemyData "fenrir";
## the Hall of the Slain, temporarily Act XI; GDD §15.0 "Odin and Fenrir
## (Vigrid)"; owner-approved proposal: "the Wolf (Fenrir breaks his chain and
## hunts the ring; he swallows a summon whole and spits it out 4 s later)").
## Odin's companion in the boss fight (BossOdin spawns him, sets his HP and
## drives his chain); a --spawn=fenrir hunts alone. He walks and bites with the
## shared enemy AI, plus:
##   * THE SWALLOW: every swallow_every s (swallow_every_ragnarok while
##     `frenzied`) he picks the STRONGEST summon within swallow_reach px (the
##     most max HP; ties to the nearest; never an airborne, charmed, spawning
##     or dead one), crouches on a telegraphed line for swallow_windup s and
##     lunges at it; landing beside it he SWALLOWS it whole: an enemy hold
##     through the existing hooks (SummonedUnit.held_until renewed each tick,
##     THE one place that moves it is _step_maw(), one
##     CombatResolver.stun_unit() for swallow_hold s, so it neither walks nor
##     strikes; it is hidden and out of every fight inside him, through the
##     summon's own out-of-reach flag SummonedUnit.airborne, as a Gargoyle's
##     swoop: nothing targets or hits it there). After swallow_hold s he SPITS
##     IT OUT spit_dist px in front of him, toward the necromancer, and it
##     takes spit_share of its max HP (CombatResolver.damage_unit(),
##     MAW_SOURCE). One summon at a time. With no summon in reach the lunge
##     goes at the necromancer (a bite, lunge_damage_player).
##   * THE CHAIN: while `leashed` (BossOdin: the All-Father's phase) he is
##     bound at his master's side: untargetable, unharmed, idle; whatever he
##     holds is spat out first.
## He dying or leaving the field spits out what he holds at once. Summons
## never get an act rule: the hold, stun and damage are enemy effects through
## the shared paths. No RNG. Stats: fenrir_lunges, fenrir_swallows,
## fenrir_spat, fenrir_digested, fenrir_lunge_on_you.
class_name FenrirKit
extends NorseKit

## Phase: crouched on the line to his prey.
const WINDUP: int = 1
## Phase: the lunge in the air.
const LUNGE: int = 2
## True while BossOdin keeps him chained at his side.
var leashed: bool = false
## Where his chain holds him while leashed (world px; BossOdin writes it).
var leash_to: Vector2 = Vector2.ZERO
## True in Ragnarok (BossOdin): he swallows more often.
var frenzied: bool = false
## x every hit he takes (BossOdin's doom of Ragnarok; 1 otherwise).
var taken_bonus: float = 1.0
## HP below which no hit harms him (BossOdin: the Wolf's phase ends there
## and the chain takes him; 0 = none).
var hp_floor: float = 0.0
## Game time (s) the doom of Ragnarok takes him (his master fell first;
## INF = none): he falls then (a killing hit tagged OdinData.DOOM_SOURCE).
var doom_at: float = INF
## Seconds until the next swallow may start.
var _cd: float = 0.0
## The lunge's prey (a summon or a necromancer).
var _prey: Node2D = null
## Pool generation of a summon prey (stale guard).
var _prey_gen: int = 0
## Where the lunge starts / lands (world px).
var _from: Vector2 = Vector2.ZERO
## Where the lunge lands (world px; locked at the windup).
var _to: Vector2 = Vector2.ZERO
## The summon in his maw (null when none).
var _maw: SummonedUnit = null
## Pool generation of `_maw` (stale guard).
var _maw_gen: int = 0
## Game time (s) he spits it out.
var _maw_until: float = 0.0
## Scratch for the grid queries.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	leashed = false
	frenzied = false
	taken_bonus = 1.0
	hp_floor = 0.0
	doom_at = INF
	_cd = first_cd(e, float(def.get("swallow_first", 4.0)))
	_prey = null
	_maw = null
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("fenrir_spawned", 1.0)


func on_deactivate(e: Enemy) -> void:
	spit(e)
	e.game.enemies.clear_miniboss(e)
	_prey = null
	super.on_deactivate(e)


## Chains him at his master's side (`on` true) or looses him (false); a chain
## spits out what he holds.
func set_leash(e: Enemy, on: bool) -> void:
	leashed = on
	e.untargetable = on
	if on:
		spit(e)
		_prey = null
		set_phase(e, IDLE)
	else:
		_cd = minf(_cd, float(d.get("swallow_first", 4.0)))
	e.queue_redraw()


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	e.knockback = Vector2.ZERO  # The great wolf: blows do not shove him.
	_step_maw(e, delta)
	if g.elapsed >= doom_at:
		doom_at = INF
		hp_floor = 0.0
		g.stat_add("fenrir_doomed", 1.0)
		g.combat.damage_enemy(e, e.hp * 100.0 + 1000000.0, OdinData.DOOM_SOURCE)  # The other follows within 30 s.
		return true
	if leashed:
		var to := leash_to - e.position
		var step := minf(to.length(), e.move_speed * delta)
		e.velocity = to.normalized() * e.move_speed if to.length() > 6.0 else Vector2.ZERO
		if step > 0.5:
			e.position += to.normalized() * step
		return true
	_cd -= delta
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("swallow_windup", 0.7)):
				_from = e.position
				set_phase(e, LUNGE)
			return true
		LUNGE:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d.get("swallow_time", 0.35))), 0.0, 1.0)  # 0 -> 1 to the mark.
			e.position = _from.lerp(_to, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e)
				set_phase(e, IDLE)
			return true
	if _cd <= 0.0 and _maw == null and _start(e):
		return true
	if g.ultimates.player_untargetable() and e.target == g.player:
		return false
	return false


## Picks his prey (the strongest summon in reach, else the necromancer) and
## crouches on the line to it. False when nothing is in reach.
func _start(e: Enemy) -> bool:
	var g := e.game
	var reach := float(d.get("swallow_reach", 220.0))
	g.ally_grid.query(e.position, reach + e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var best: SummonedUnit = null
	for u: SummonedUnit in _tmp:
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		var dist := u.position.distance_to(e.position)
		if dist - e.radius - u.radius > reach:
			continue
		if best == null or u.max_hp > best.max_hp or (u.max_hp == best.max_hp and dist < best.position.distance_to(e.position)):
			best = u
	var t: Node2D = best
	if t == null:
		var pl := g.player
		if pl.dead or g.ultimates.player_untargetable() or pl.position.distance_to(e.position) - e.radius - pl.radius > reach:
			_cd = 1.0  # Nothing to hunt: look again soon.
			return false
		t = pl
	_prey = t
	_prey_gen = best.generation if best != null else 0
	var to := t.position - e.position
	var dist2 := maxf(to.length(), 0.01)
	_to = g.arena.free_point(t.position - to / dist2 * (e.radius + body_radius(e, t)), e.radius * 0.5)
	_cd = float(d.get("swallow_every_ragnarok" if frenzied else "swallow_every", 9.0))
	g.effects.telegraph_line(e.position, _to, e.radius * 1.2, float(d.get("swallow_windup", 0.7)), e)
	e.motion_lunge(-to / dist2, MotionData.POWER_CAST)
	g.stat_add("fenrir_lunges", 1.0)
	if g.norse != null:
		g.norse.play_sound("wolf_lunge", e.position, 0.4)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The lunge lands: he swallows his summon prey, or bites the necromancer.
func _land(e: Enemy) -> void:
	var g := e.game
	var t := _prey
	_prey = null
	if t == null or not is_instance_valid(t):
		return
	if t is SummonedUnit:
		var u := t as SummonedUnit
		if not u.active or u.generation != _prey_gen or u.state == SummonedUnit.State.DEAD or u.charmed or u.airborne:
			return
		if u.position.distance_to(e.position) - e.radius - u.radius > 30.0:
			return
		_swallow(e, u)
		return
	var pl := t as Necromancer
	if pl.dead or pl.position.distance_to(e.position) - e.radius - pl.radius > e.attack_range + 14.0:
		return
	g.combat.damage_player(float(d.get("lunge_damage_player", 9.0)) * hit_scale(e), VigridEnemyData.LUNGE_SOURCE, pl, e)
	g.stat_add("fenrir_lunge_on_you", 1.0)
	g.effects.slash(e.position, pl.position - e.position, Palette.NORSE_FROST, e.radius * 1.4)


## Summon `u` goes into his maw (the hold, one stun, hidden).
func _swallow(e: Enemy, u: SummonedUnit) -> void:
	var g := e.game
	var hold_s := float(d.get("swallow_hold", 4.0))
	_maw = u
	_maw_gen = u.generation
	_maw_until = g.elapsed + hold_s
	g.combat.stun_unit(u, hold_s, VigridEnemyData.MAW_SOURCE)
	u.held_until = maxf(u.held_until, g.elapsed + 0.1)
	u.position = e.position
	u.velocity = Vector2.ZERO
	u.airborne = true  # Out of reach inside him (out of the ally grid, unharmed), as a swooping Gargoyle.
	u.visible = false
	g.stat_add("fenrir_swallows", 1.0)
	g.effects.impact(e.position, e.radius * 1.4, Palette.NORSE_IRON)
	g.shake(3.0)
	e.queue_redraw()


## THE one place that moves a swallowed summon: held at his maw, spat out
## when its time is up. A summon gone meanwhile (a recall to the pool) is let go.
func _step_maw(e: Enemy, _delta: float) -> void:
	if _maw == null:
		return
	var u := _maw
	var g := e.game
	if not u.active or u.generation != _maw_gen or u.state == SummonedUnit.State.DEAD:
		_maw = null
		g.stat_add("fenrir_digested", 1.0)
		e.queue_redraw()
		return
	u.position = e.position
	u.velocity = Vector2.ZERO
	u.held_until = maxf(u.held_until, g.elapsed + 0.1)
	if g.elapsed >= _maw_until and _maw != null:
		spit(e)


## Spits out what he holds (if anything) spit_dist px toward the necromancer.
func spit(e: Enemy) -> void:
	if _maw == null:
		return
	var u := _maw
	_maw = null
	if e.game == null or not u.active or u.generation != _maw_gen:
		return
	var g := e.game
	var to := g.player.position - e.position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.DOWN
	u.position = g.arena.free_point(e.position + dir * (e.radius + float(d.get("spit_dist", 80.0))), u.radius)
	u.held_until = minf(u.held_until, g.elapsed)
	u.airborne = false
	u.visible = not u.charmed
	g.stat_add("fenrir_spat", 1.0)
	g.combat.damage_unit(u, u.max_hp * float(d.get("spit_share", 0.18)), VigridEnemyData.MAW_SOURCE, e)
	g.effects.ring(u.position, u.radius * 2.0, Palette.NORSE_FROST, 0.3)
	e.queue_redraw()


## True while a summon is in his maw.
func has_prey_inside() -> bool:
	return _maw != null


## Chained: nothing harms him; the doom of Ragnarok: every hit lands harder.
func taken_mult(e: Enemy, source: String) -> float:
	if leashed or (hp_floor > 0.0 and e.hp <= hp_floor + 1.0 and source != OdinData.DOOM_SOURCE):
		return 0.0
	return super.taken_mult(e, source) * taken_bonus


func is_busy() -> bool:
	return phase != IDLE or leashed


## Autopilot hint: sideways off the lunge's line when it goes at the necromancer.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if (phase != WINDUP and phase != LUNGE) or not (_prey is Necromancer):
		return Vector2.ZERO
	var off := p - _to
	var reach := e.radius + 28.0
	if off.length() >= reach:
		return Vector2.ZERO
	return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.0


## Under the body: his broken chain's dim ring while bound (a texture).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	if leashed:
		var r := e.radius * 1.6
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.4), Vector2(r * 2.0, r * 0.8)), false, Color(Palette.NORSE_IRON_DARK, 0.4))


## Over the body: a soul-light in his throat while a summon is inside.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	if _maw != null:
		unmirror(e, ci)
		var pulse := 0.6 + 0.4 * sin(e.game.elapsed * 8.0)
		SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.3), e.radius * 0.5, Color(SpellGlyphs.SOUL, 0.45 * pulse))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
