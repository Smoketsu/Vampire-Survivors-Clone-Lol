## IronjawKit — the kit of IRONJAW, THE NEST MOTHER, the Fern Basin's miniboss
## (FernBasinEnemyData "ironjaw"; temporary Act XIV, the Age of Titans; GDD
## §15.0 "The Fern Basin (Act XIV phase 2)"; owner-approved proposal: "Ironjaw,
## the Nest Mother (female), a bulky predator who defends a nest: the nest
## spawns Scuttlers until it is destroyed"). A bulky tar-dark predator with an
## iron-grey jaw (a beast: no figure style). FernBasinDirector lays her nest
## beside her and links it (`nest`). The shared melee AI walks her in; then:
##   * THE IRON JAW: every bite_every s, once a summon or necromancer stands
##     within bite_trigger px, she rears for bite_windup s (a line shows the
##     lunge) and LUNGES bite_len px at bite_speed px/s: the first summon or
##     necromancer she touches takes bite_damage / bite_player once (x the time
##     scaling; BogCrocKit.bite_first(), the one lunge bite).
##   * THE NEST MOTHER: while her nest stands she takes x nest_ward damage
##     (taken_mult(), the kit's one damage read): break the nest first.
## She registers on the HUD's miniboss bar and drops her XP burst (reward_xp in
## reward_crystals) when she falls; ChestManager drops the miniboss chest.
## Determinism: no RNG, no instance ids. Stats: ironjaw_bites, ironjaw_bite_hits,
## ironjaw_bite_on_you, ironjaw_warded_hits, ironjaw_kills, ironjaw_ttk.
class_name IronjawKit
extends PrimevalKit

## Phase: rearing before the lunge (the telegraph).
const WINDUP: int = 1
## Phase: the lunge.
const LUNGE: int = 2
## px between two drawn marks of the lunge's line (visual only).
const MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only

## Her nest (null before the director links it / after it falls; generation-checked).
var nest: Enemy = null
## Pool generation of `nest` when linked.
var nest_gen: int = 0
## Seconds until the next lunge may start.
var cd: float = 0.0
## The lunge's direction (unit).
var lunge_dir: Vector2 = Vector2.RIGHT
## px of the lunge run so far.
var lunge_run: float = 0.0
## Game time (s) she arrived (the miniboss's time to kill).
var spawned_at: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	nest = null
	cd = first_cd(e, float(d.get("bite_first", 3.0)))
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## Links her nest `n` (FernBasinDirector, when it lays them).
func link_nest(n: Enemy) -> void:
	nest = n
	nest_gen = n.generation


## True while her nest stands.
func nest_stands() -> bool:
	return nest != null and nest.active and nest.generation == nest_gen


## Every tick (see the header): true while the lunge owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	match phase:
		WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("bite_windup", 0.8)):
				lunge_run = 0.0
				e.motion_lunge(lunge_dir, MotionData.POWER_CAST)
				set_phase(e, LUNGE)
			return true
		LUNGE:
			var spd := float(d.get("bite_speed", 360.0))
			e.velocity = lunge_dir * spd
			e.position += lunge_dir * spd * delta
			e._update_facing()
			lunge_run += spd * delta
			var ts := hit_scale(e)
			var hit := BogCrocKit.bite_first(e, float(d.get("bite_damage", 20.0)) * ts, float(d.get("bite_player", 12.0)) * ts, _buf)
			if hit == 1:
				g.stat_add("ironjaw_bite_hits", 1.0)
			elif hit == 2:
				g.stat_add("ironjaw_bite_on_you", 1.0)
			if hit > 0 or lunge_run >= float(d.get("bite_len", 120.0)):
				set_phase(e, IDLE)
			return true
	if cd <= 0.0:
		var t := e.target if e.target != null and e._target_valid() else g.nearest_player(e.position)
		if t != null and t.position.distance_to(e.position) <= float(d.get("bite_trigger", 200.0)):
			cd = float(d.get("bite_every", 6.0))
			var to := t.position - e.position
			lunge_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
			g.stat_add("ironjaw_bites", 1.0)
			rules(e).play_sound("ironjaw_bite", e.position, 0.3)
			set_phase(e, WINDUP)
			hold(e)
			return true
	return false


## THE NEST MOTHER: x nest_ward while her nest stands.
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if nest_stands():
		e.game.stat_add("ironjaw_warded_hits", 1.0)
		return m * float(d.get("nest_ward", 0.5))
	return m


## The miniboss's XP burst and the stats of her fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.PRIMEVAL_BONE)
	g.shake(8.0)
	g.stat_add("ironjaw_kills", 1.0)
	g.stat_add("ironjaw_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	nest = null
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the lunge's line while she rears.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var rel := p - e.position
	var along := rel.dot(lunge_dir)
	if along < 0.0 or along > float(d.get("bite_len", 120.0)) + 24.0:
		return Vector2.ZERO
	var lat := rel.dot(lunge_dir.orthogonal())
	if absf(lat) > e.radius + 24.0:
		return Vector2.ZERO
	return lunge_dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)


## Overlay: the lunge's line while she rears, and a bone-white thread to her
## nest while it stands (visual only, rects in world axes).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	if phase == WINDUP:
		var k := clampf(phase_time / maxf(0.01, float(d.get("bite_windup", 0.8))), 0.0, 1.0)
		var s := e.radius
		while s < float(d.get("bite_len", 120.0)):
			ci.draw_rect(Rect2(lunge_dir * s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.PRIMEVAL_LAVA, 0.3 + 0.55 * k))
			s += MARK_STEP
	if nest_stands():
		var to := nest.position - e.position
		var n := int(to.length() / 14.0)
		for i in n:
			ci.draw_rect(Rect2(to * (float(i) / float(maxi(1, n))) - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.PRIMEVAL_BONE, 0.35))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
