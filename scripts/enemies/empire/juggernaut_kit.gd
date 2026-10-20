## JuggernautKit — the Juggernaut's flamethrower (AssemblyEnemyData
## "juggernaut", a heavy elite MACHINE; Act III, the Assembly Halls; GDD §15.0
## "The Assembly Halls (Act III phase 2)"; owner-approved proposal: "Armoured
## flamethrower walker with flat armour, like the Sanctified Sentinel"). It walks
## at the necromancer on the shared melee AI and punches what it reaches; when
## its target (the necromancer or a summon) is within flame_trigger px it stops,
## shows a warning cone toward it for flame_telegraph s (EffectManager
## .telegraph_cone, paused while it is frozen), then burns the cone for
## flame_duration s: every flame_tick s each summon inside takes
## flame_damage_summon and the necromancer inside flame_damage_player (time
## scaled, x its aura / Dirge multiplier). Flames are not shots: Line of Fire
## does not stop them, but the summons in the cone shield nothing behind them
## either (undead do not dodge). Its flat armour is CombatResolver's
## (Enemy.flat_armor, the Sentinel's stat): Wither's shred, Grim Ledger and
## Siegecraft are the answers. A MACHINE: no corpse. No RNG.
## Stats: juggernaut_flames, juggernaut_flame_summon_hits, juggernaut_flame_player_hits.
class_name JuggernautKit
extends EmpireKit

## Phase: the cone is telegraphed.
const WINDUP: int = 1
## Phase: the stream burns.
const FLAME: int = 2
## Phase: standing after the stream.
const RECOVER: int = 3
## Damage source tag of the flames (an area hit for Unholy Resilience).
const SOURCE: String = "juggernaut_flame"

## Seconds until the next stream may start (counts down while idle).
var cd: float = 0.0
## Unit direction of the current stream (locked at the windup).
var dir: Vector2 = Vector2.RIGHT
## Seconds until the next burn tick of the stream.
var _tick: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["flame_first"]))


## Starts a stream at a target in reach.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var t := e.target  # Current target (the necromancer or a summon).
	if t == null or (t is SummonedUnit and not (t as SummonedUnit).active):
		return
	var rel := t.position - e.position
	if rel.length() - e.radius - body_radius(e, t) > float(d["flame_trigger"]):
		return
	dir = rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT
	e.game.effects.telegraph_cone(e.position, dir, float(d["flame_range"]), float(d["flame_half_angle"]), float(d["flame_telegraph"]), e)
	e.game.stat_add("juggernaut_flames", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	match phase:
		WINDUP:
			if phase_time >= float(d["flame_telegraph"]):
				_tick = 0.0
				Sfx.play("flamethrower", e.position)
				set_phase(e, FLAME)
		FLAME:
			e.queue_redraw()
			_tick -= delta
			if _tick <= 0.0:
				_tick += float(d["flame_tick"])
				_burn(e)
			if phase_time >= float(d["flame_duration"]):
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["flame_recover"]):
				cd = float(d["flame_cooldown"])
				set_phase(e, IDLE)
	return true


## One burn tick: every summon and the necromancer in the cone.
func _burn(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["flame_range"])
	var half := float(d["flame_half_angle"])
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	var hits := 0  # Summons burned this tick.
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		if not in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			continue
		hits += 1
		g.combat.damage_unit(u, float(d["flame_damage_summon"]) * mult * e.undead_damage_mult, SOURCE)
	g.stat_add("juggernaut_flame_summon_hits", float(hits))
	var p := g.player
	if in_sector(e.position, dir, reach, half, e.radius, p.position, p.radius):
		g.stat_add("juggernaut_flame_player_hits", 1.0)
		g.combat.damage_player(float(d["flame_damage_player"]) * mult, SOURCE)


## Autopilot hint: out of the telegraphed or burning cone.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP and phase != FLAME:
		return Vector2.ZERO
	if not in_sector(e.position, dir, float(d["flame_range"]) + 24.0, float(d["flame_half_angle"]) + 0.15, e.radius, p, 12.0):
		return Vector2.ZERO
	var away := p - e.position
	return away.normalized() if away.length() > 0.1 else -dir


## The flame stream while it burns (drawn on its overlay layer).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == FLAME:
		unmirror(e, ci)
		AssemblyGlyphs.draw_flame(ci, dir, float(d["flame_range"]), float(d["flame_half_angle"]), e.game.elapsed)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
