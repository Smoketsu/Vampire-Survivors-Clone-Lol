## OphanKit — the kit of the OPHAN (HostEnemyData "ophan", a guardian, a heavy;
## temporary Act XIII, the Celestial Host; GDD §15.0 "The Wheel of Thrones (Act
## XIII phase 2)"; owner-approved proposal: "A burning wheel within a wheel that
## rolls straight through the ring, then turns | Bone Wall; Grave Step"). Its
## row's "roll":
##   * every `every` s (the first `first` s after it arrives), once its target
##     (a summon or the necromancer) is within `trigger` px, it stops and marks
##     its line for `windup` s (a line of marks; the autotest bot steps aside);
##   * then it ROLLS STRAIGHT along that line at `speed` px/s for `length` px:
##     the ring does not stop it (it moves itself, not the shared AI), only the
##     solid world does (obstacles and Bone Wall segments push it out like any
##     enemy, so a Bone Wall in its line ends the roll early in practice);
##     every summon and necromancer under its rim (its radius + theirs) takes
##     damage_summon / damage_player (x the time scaling and its aura buff)
##     every `tick` s while it rolls;
##   * then it stands `turn` s, turning toward its next line ("then turns").
## Determinism: no RNG (the think-slot stagger only). Stats: ophan_rolls,
## ophan_summon_hits, ophan_player_hits; damage as
## player_dmg_from_ophan_roll / summon_dmg_from_ophan_roll.
class_name OphanKit
extends HostKit

## Phase: stopped, the line showing.
const WINDUP: int = 1
## Phase: rolling along the line.
const ROLL: int = 2
## Phase: standing, turning after a roll.
const TURN: int = 3
## Damage source tag of the roll (stats, the death line).
const SOURCE: String = "ophan_roll"
## px between two drawn marks of its line (visual only).
const MARK_STEP: float = 8.0  # TUNING (not in GDD) visual only

## Seconds until it may roll again.
var cd: float = 0.0
## The roll's direction (unit vector, set at the windup).
var dir: Vector2 = Vector2.RIGHT
## px still to roll.
var left: float = 0.0
## Seconds until the rim strikes again.
var strike_cd: float = 0.0
## The rim's turn (rad, visual only: it spins while rolling).
var spin: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(_roll()["first"]))
	dir = Vector2.RIGHT
	left = 0.0
	strike_cd = 0.0
	spin = 0.0


## The row's roll dictionary.
func _roll() -> Dictionary:
	return d["roll"]


func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Current target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - body_radius(e, t) > float(_roll()["trigger"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.stat_add("ophan_rolls", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	var rl := _roll()
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	match phase:
		WINDUP:
			hold(e)
			e.queue_redraw()  # The line brightens.
			if phase_time >= float(rl["windup"]):
				left = float(rl["length"])
				strike_cd = 0.0
				e.game.host_rules().play_sound("ophan_roll", e.position, 0.3)
				set_phase(e, ROLL)
		ROLL:
			var step_len := minf(float(rl["speed"]) * delta, left)
			e.position += dir * step_len
			e.velocity = dir * float(rl["speed"])
			left -= step_len
			spin = wrapf(spin + step_len / maxf(1.0, e.radius), 0.0, TAU)
			strike_cd -= delta
			if strike_cd <= 0.0:
				strike_cd = float(rl["tick"])
				_strike(e, rl)
			e.queue_redraw()
			if left <= 0.01:
				set_phase(e, TURN)
		TURN:
			hold(e)
			if phase_time >= float(rl["turn"]):
				cd = float(rl["every"])
				set_phase(e, IDLE)
	return true


## The rim strikes every summon and necromancer under it.
func _strike(e: Enemy, rl: Dictionary) -> void:
	var g := e.game
	var mult := hit_scale(e)  # Time scaling x aura buff.
	g.ally_grid.query(e.position, e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp.duplicate():
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(e.position) <= e.radius + u.radius:
			g.stat_add("ophan_summon_hits", 1.0)
			g.combat.damage_unit(u, float(rl["damage_summon"]) * mult * e.undead_damage_mult, SOURCE, e)
	for pl in g.all_players:  # (Co-op: either necromancer can be in its path.)
		if not pl.dead and pl.position.distance_to(e.position) <= e.radius + pl.radius:
			g.stat_add("ophan_player_hits", 1.0)
			g.combat.damage_player(float(rl["damage_player"]) * mult, SOURCE, pl, e)


## The autotest autopilot's push out of its line while it shows or rolls.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP and phase != ROLL:
		return Vector2.ZERO
	var rel := p - e.position
	var along := rel.dot(dir)
	var reach := float(_roll()["length"]) if phase == WINDUP else left
	if along < -e.radius or along > reach + e.radius or absf(rel.cross(dir)) > e.radius + 22.0:
		return Vector2.ZERO
	var side := dir.orthogonal()
	return side if rel.dot(side) >= 0.0 else -side


## Its line of marks while it winds up, a ring of turning eyes while it rolls,
## then the halo. Visual only: rects and disc textures.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WINDUP or phase == ROLL:
		unmirror(e, ci)
		if phase == WINDUP:
			var k := clampf(phase_time / maxf(0.01, float(_roll()["windup"])), 0.0, 1.0)
			var s := e.radius
			while s < float(_roll()["length"]):
				ci.draw_rect(Rect2(dir * s - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.HOST_CERULEAN, 0.35 + 0.55 * k))
				s += MARK_STEP
		else:
			for i in 6:
				var p := Vector2.from_angle(spin + TAU * float(i) / 6.0) * e.radius * 0.85
				SpriteBank.draw_disc(ci, p, 2.0, Palette.HOST_STARLIGHT)  # Its eyes, turning.
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	super.draw_over(e, ci)
