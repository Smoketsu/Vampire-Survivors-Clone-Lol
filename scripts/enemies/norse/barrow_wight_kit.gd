## BarrowWightKit — THE BARROW-WIGHT, the Barrow Fields' miniboss
## (BarrowFieldsEnemyData "barrow_wight"; the Hall of the Slain, temporarily
## Act XI; GDD §15.0 "The Barrow Fields (the Hall of the Slain phase 2)"; the
## brief: "a draugr chieftain whose howl stuns the ring for 1 s"). A towering
## male draugr chieftain, spawned by BarrowFieldsDirector's "wight" event; he
## registers as EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager
## drops the miniboss chest on his fall: the row's "miniboss"). He walks in with
## the shared melee AI and his blow chills like a draugr's (the row's
## chill_slow, NorseRules.on_unit_struck()). His special:
##   * THE HOWL: every howl_every s (the first after half of it) he throws back
##     his head for howl_windup s (he stands; a frost ring grows out to
##     howl_radius: the telegraph) and howls: every summon within howl_radius
##     px of him is stunned howl_stun s (CombatResolver.stun_unit(), THE one
##     summon stun path) and each necromancer in reach is slowed howl_slow for
##     howl_slow_time s (TerrainSlow.slow_player(), the cold of the barrow);
##     the howl cracks open howl_barrows open barrows near the ring
##     (BarrowFieldsDirector.open_barrow(), only on the Barrow Fields).
## Already dead: no warrior of the hall (never berserk). On death: an XP burst
## (reward_xp in reward_crystals), the miniboss chest.
## Determinism: no RNG. Stats: wight_howls, wight_howl_stuns, wight_howl_on_you,
## wight_kills, wight_ttk.
class_name BarrowWightKit
extends NorseKit

## Phase: he throws back his head to howl.
const HOWL: int = 1

## Seconds until his next howl.
var howl_cd: float = 0.0
## Howls this life (turns the barrows it cracks).
var howls: int = 0
## Game time (s) he arrived (his time to kill).
var spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	howl_cd = first_cd(e, float(def.get("howl_every", 9.0)) * 0.5)
	howls = 0
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


## Every tick: the howl's windup and the howl on his cooldown.
func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	howl_cd -= delta
	if phase == HOWL:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("howl_windup", 1.0)):
			_howl(e)
			set_phase(e, IDLE)
		return true
	if howl_cd <= 0.0:
		howl_cd = float(d.get("howl_every", 9.0))
		set_phase(e, HOWL)
		hold(e)
		e.game.effects.telegraph_circle(e.position, float(d.get("howl_radius", 170.0)), float(d.get("howl_windup", 1.0)), e)
		return true
	return false


## The howl: the ring in reach is stunned, the necromancer slowed, barrows crack.
func _howl(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("howl_radius", 170.0))
	var stunned := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.position.distance_to(e.position) > r + u.radius:
			continue
		if g.combat.stun_unit(u, float(d.get("howl_stun", 1.0)), BarrowFieldsEnemyData.HOWL_SOURCE) > 0.0:
			stunned += 1
	for pl in g.all_players:
		if pl.dead or pl.position.distance_to(e.position) > r + pl.radius:
			continue
		var prev := g.coop.bound if g.coop != null else 0  # Co-op: the slow reads that necromancer's passives.
		if g.coop != null:
			g.coop.bind(g.coop.slot_of(pl))
		TerrainSlow.slow_player(g, float(d.get("howl_slow", 0.3)), float(d.get("howl_slow_time", 1.5)))
		if g.coop != null:
			g.coop.bind(prev)
		g.stat_add("wight_howl_on_you", 1.0)
	howls += 1
	g.stat_add("wight_howls", 1.0)
	g.stat_add("wight_howl_stuns", float(stunned))
	g.stat_add("boss_atk_howl", 1.0)
	g.effects.ring(e.position, r, Palette.NORSE_RUNE, 0.6)
	g.shake(4.0)
	rules(e).play_sound("horn", e.position, 0.5)
	var bf := g.enemies.barrow_fields  # The stage's director (null off the Barrow Fields).
	if bf != null:
		var pl0 := g.nearest_player(e.position)
		for k in int(d.get("howl_barrows", 1)):
			var a := float(howls) * 1.7 + float(k) * PI
			bf.open_barrow(pl0.position + Vector2.from_angle(a) * 240.0, "howl")


## The XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.NORSE_RUNE)
	g.shake(8.0)
	g.stat_add("wight_kills", 1.0)
	g.stat_add("wight_ttk", g.elapsed - spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autotest autopilot hint: out of the howl's reach while he winds up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != HOWL:
		return Vector2.ZERO
	var reach := float(d.get("howl_radius", 170.0)) + 20.0
	var rel := p - e.position
	var dist := rel.length()
	if dist >= reach:
		return Vector2.ZERO
	return (rel / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
