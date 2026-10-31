## PitCultistKit — the kit of the PIT CULTIST (BurningGateEnemyData
## "pit_cultist"; Act VI, the Burning Gate; GDD §15.0 "The Burning Gate (Act VI
## phase 2)"; owner-approved roster: "Pit Cultist: Support. Living humans who
## open new portals; Priority target"). A living man: NOT a demon, so the Hell
## Pits burn him. His RITE: when it is ready (rite_first s after he appears,
## then every rite_every s from the end of his last chant), a necromancer stands
## within rite_range px and the portals have room (fewer than PORTALS max_open
## standing), he stops and chants for rite_time s over a charm-pink summoning
## circle rite_ahead px toward the necromancer (the shared telegraph circle,
## the portal's own radius); if he lives to the end, a demon portal tears open
## there through the ONE portal path (DemonPortals.open(): it pours squads and
## can be destroyed or sealed like any portal). Killing him during the chant
## stops it (the priority target: target_priority 0.95). He never kites: he
## advances like every enemy and chants where he stands. No RNG. Stats:
## cultist_rites, cultist_portals, cultist_rites_broken, cultist_rites_refused.
class_name PitCultistKit
extends InfernoKit

## Phase: chanting the rite (the windup).
const CHANT: int = 1

## Seconds until the next rite may start.
var _cd: float = 0.0
## World point the portal opens at (locked at the start of the chant).
var _at: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("rite_first", 4.0)))


## Killed mid-chant: the rite is broken (no portal).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if phase == CHANT:
		e.game.stat_add("cultist_rites_broken", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == CHANT:
		phase_time += delta
		hold(e)
		if int(phase_time * 10.0) != int((phase_time - delta) * 10.0):
			e.queue_redraw()  # The circle fills (drawing only).
		if phase_time >= float(d.get("rite_time", 3.0)):
			_open(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	var g := e.game
	var pl := g.player  # The bound necromancer (co-op: the slot being stepped).
	if pl.dead or e.position.distance_to(pl.position) > float(d.get("rite_range", 420.0)):
		_cd = 0.5
		return false
	var portals := rules(e).portals
	if portals.standing() >= int(portals.cfg["max_open"]):
		_cd = 2.0  # The gate is crowded: try again soon (not counted: only a finished rite that finds no room is).
		return false
	var to := pl.position - e.position
	_at = g.arena.free_point(e.position + (to.normalized() if to.length() > 1.0 else Vector2.RIGHT) * float(d.get("rite_ahead", 40.0)),
			float(g.enemies.enemy_def(String(portals.cfg["kind"]))["radius"]))
	_cd = float(d.get("rite_every", 24.0)) + float(d.get("rite_time", 3.0))
	g.effects.telegraph_circle(_at, float(g.enemies.enemy_def(String(portals.cfg["kind"]))["radius"]) * 1.3, float(d.get("rite_time", 3.0)), e)
	g.stat_add("cultist_rites", 1.0)
	rules(e).play_sound("cultist_chant", e.position)
	set_phase(e, CHANT)
	hold(e)
	return true


## The rite is complete: a portal tears open at the circle.
func _open(e: Enemy) -> void:
	if rules(e).portals.open(_at) != null:
		e.game.stat_add("cultist_portals", 1.0)
	else:
		e.game.stat_add("cultist_rites_refused", 1.0)


func is_busy() -> bool:
	return phase == CHANT


## The chant: charm-pink sparks rising from his raised hands. Visual only
## (the circle on the ground is the shared telegraph).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != CHANT:
		return
	var k := clampf(phase_time / maxf(float(d.get("rite_time", 3.0)), 0.01), 0.0, 1.0)
	for i in 3:
		var f := fmod(k * 3.0 + float(i) / 3.0, 1.0)  # Height of this spark.
		SpriteBank.draw_disc(ci, Vector2((float(i) - 1.0) * e.radius * 0.6, -e.radius * (1.6 + 1.4 * f)), 1.6 + k, Color(Palette.INFERNO_CHARM, 0.8 * (1.0 - f)))
