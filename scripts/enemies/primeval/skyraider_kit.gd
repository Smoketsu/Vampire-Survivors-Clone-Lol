## SkyraiderKit — the kit of the SKYRAIDER (male; PrimevalEnemyData
## "skyraider"; temporary Act XIV, the Age of Titans; GDD §15.0 "Scavengers";
## proposal: "Dives, snatches a pile (Scavengers) | Archers, Gargoyles,
## spells"). A pterosaur thief that owns its every tick and never bites:
##   IDLE  — it circles `hover_radius` px from the nearest standing necromancer
##           (row "flies": over the Bone Ring);
##   DIVE  — Scavengers sent it at a pile (dive()): it flies there at
##           `dive_speed` under its shadow circle; once there and `warn` s
##           passed, it snatches the pile (Scavengers.snatch());
##   FLEE  — it flies away from the nearest necromancer with the pile at
##           `flee_speed`; at its nest (Scavengers.at_nest()) it leaves the
##           field with it. An empty snatch sends it back to IDLE.
## Killed while it carries, the pile drops where it dies (on_killed() ->
## Scavengers.drop()). Hoarder's Bones (Act XIV, the Great Plain's
## counter-passive): a carrier drops its pile where it is after
## PrimevalRules.hoarders_bones_drop_after() s of flight (0 = never). Determinism: no RNG (its circle's angle is its own
## bearing).
class_name SkyraiderKit
extends PrimevalKit

## Phase: diving on a pile.
const DIVE: int = 1
## Phase: flying to its nest with the pile.
const FLEE: int = 2

## The pile's point (px) it dives on.
var dive_at: Vector2 = Vector2.ZERO
## The crystal values it carries (empty = none).
var carry: PackedInt32Array = PackedInt32Array()


func reset(e: Enemy, def: Dictionary) -> void:
	carry = PackedInt32Array()
	super.reset(e, def)


func on_killed(e: Enemy) -> void:
	if not carry.is_empty() and e.game.primeval != null:
		e.game.primeval.scavengers.drop(e, carry)
	carry = PackedInt32Array()
	super.on_killed(e)


func on_deactivate(e: Enemy) -> void:
	carry = PackedInt32Array()
	super.on_deactivate(e)


## Scavengers sends it diving on the pile at `at`.
func dive(e: Enemy, at: Vector2) -> void:
	dive_at = at
	set_phase(e, DIVE)


func physics(e: Enemy, delta: float) -> bool:
	var sc := rules(e).scavengers
	var cfg := sc.cfg
	var pl := e.game.nearest_player(e.position)
	phase_time += delta
	match phase:
		DIVE:
			var to := dive_at - e.position
			if to.length() > 6.0:
				PrimevalKit.move(e, to.normalized(), float(cfg["dive_speed"]), delta)
			elif phase_time >= float(cfg["warn"]):
				carry = sc.snatch(e, dive_at)
				set_phase(e, FLEE if not carry.is_empty() else IDLE)
			else:
				e.velocity = Vector2.ZERO
		FLEE:
			var drop_after := rules(e).hoarders_bones_drop_after()  # Hoarder's Bones (0 when not owned).
			if drop_after > 0.0 and phase_time >= drop_after:
				var dropped := carry
				carry = PackedInt32Array()
				sc.drop(e, dropped)
				e.game.stat_add("scav_hoarder_drops", 1.0)
				set_phase(e, IDLE)
				return true
			if sc.at_nest(e):
				var carried := carry
				carry = PackedInt32Array()
				sc.nested(e, carried)
				return true
			var away := (e.position - pl.position) if pl != null else Vector2.RIGHT
			PrimevalKit.move(e, away.normalized() if away.length() > 0.5 else Vector2.RIGHT, float(cfg["flee_speed"]), delta)
		_:
			if pl == null:
				e.velocity = Vector2.ZERO
				return true
			var rel := e.position - pl.position
			var ang := (rel.angle() if rel.length() > 0.5 else 0.0) + float(cfg["hover_orbit"]) * delta * 4.0  # A little ahead on the circle.
			var post := pl.position + Vector2.from_angle(ang) * float(cfg["hover_radius"])
			var to := post - e.position
			if to.length() > 2.0:
				PrimevalKit.move(e, to.normalized(), minf(e.move_speed, to.length() / maxf(delta, 0.001)), delta)
	return true


## A carrier's pile: a few small bone-white glints under its body (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if carry.is_empty():
		return
	for i in mini(carry.size(), 5):
		ci.draw_rect(Rect2(Vector2(-5.0 + 2.5 * float(i), e.radius * 0.6), Vector2(2.0, 2.0)), Palette.PRIMEVAL_BONE)
