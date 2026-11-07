## OniBehavior — the Bound Oni's KANABŌ SMASH ("kanabo", UnitData "bound_oni";
## Act V, the Road to the Sun's finale reward; GDD §15.0 "The Bound Oni, the
## Oni Lord and Oni's Resolve"; owner-approved proposal: "bound oni brutes with
## kanabō (a heavy blocker with a stun smash)"). The oni itself is an ordinary
## melee "guard" summon and a physical blocker (block_radius / block_mass, like
## the Abomination). On top of its club blows:
##   1. think(): when the smash is ready and its target (or any foe) stands
##      within smash_trigger px of it (edge to edge), it raises the iron club
##      (CASTING) and a circle of smash_radius px is telegraphed in front of it
##      for smash_windup s;
##   2. impact: every foe in the circle takes smash_damage (source
##      "oni_kanabo", a minion special) and is STUNNED smash_stun_duration s
##      through CombatResolver.stun_enemy() (bosses and minibosses STUN_BOSS of
##      it, elites STUN_ELITE; Spirit Binding lengthens it as every stun);
##      evolved into the ONI LORD (SummonEvolutionData "oni_lord", special_set
##      quake_radius / quake_fraction), the blow also sends a QUAKE around it:
##      every other foe within quake_radius px takes quake_fraction of the smash
##      ("oni_quake") and is knocked back (no stun);
##   3. it stands still for smash_recover s, then rejoins the shared FSM.
## Works the same on every stage (owner rule: summons never get act-only rules).
## Its paired passive Oni's Resolve (RESOLVE) is read by
## CombatResolver.stun_unit() (stuns on summons wear off sooner).
## Stats: bound_oni_smashes, bound_oni_smash_hits, bound_oni_stuns, oni_lord_quakes,
## oni_lord_quake_hits; damage as dmg_oni_kanabo / dmg_oni_quake (the enemy Oni's own counters are OniKit's).
class_name OniBehavior
extends SummonBehavior

## Phase: the club is raised (the circle telegraphed).
const WINDUP: int = 1
## Phase: the blow landed; a short recovery.
const RECOVER: int = 2
## Damage source tag of the smash (a minion special, PassiveData).
const SMASH_SOURCE: String = "oni_kanabo"
## Damage source tag of the Oni Lord's quake (a minion special, PassiveData).
const QUAKE_SOURCE: String = "oni_quake"
## Share of the stun a boss or a miniboss suffers.
const STUN_BOSS: float = 0.25  # TUNING (not in GDD)
## Share of the stun an elite suffers.
const STUN_ELITE: float = 0.5  # TUNING (not in GDD)
## Knockback impulse (px/s, divided by the foe's mass) of the Oni Lord's quake.
const QUAKE_KNOCKBACK: float = 200.0  # TUNING (not in GDD)
## Passive id of Oni's Resolve (PassiveData, UnlockData; read by
## CombatResolver.stun_unit()).
const RESOLVE: String = "onis_resolve"
## Its level-row key: share (0..1) of a stun on a summon it shrugs off.
const RESOLVE_KEY: String = "stun_resist"

## Where the club comes down (world px; locked at the windup).
var _at: Vector2 = Vector2.ZERO
## Reusable enemy query buffer.
var _buf: Array = []


## Full smash cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("smash_cooldown", 5.5))


## Raises the club when a foe is in reach.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var reach := float(u.special["smash_trigger"]) + u.radius
	var foe: Enemy = u.target if u.target_alive() else null
	if foe == null or foe.position.distance_to(u.position) > reach + foe.radius:
		foe = null
		u.game.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
		for e: Enemy in _buf:
			if e.active and not e.untargetable and e.position.distance_to(u.position) <= reach + e.radius:
				foe = e
				break
	if foe == null:
		return false
	var to := foe.position - u.position
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	_at = u.position + dir * (u.radius + float(u.special["smash_radius"]) * 0.5)
	begin_special(u, WINDUP)
	return true


## Windup -> impact -> recovery.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	match phase:
		WINDUP:
			if phase_time >= float(u.special["smash_windup"]):
				_impact(u)
				next_phase(RECOVER)
		RECOVER:
			if phase_time >= float(u.special["smash_recover"]):
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## The club comes down: damage and a stun to every foe in the circle (and the
## Oni Lord's quake around it).
func _impact(u: SummonedUnit) -> void:
	var game := u.game
	var r := float(u.special["smash_radius"])
	var dmg := float(u.special["smash_damage"])
	var stun := float(u.special["smash_stun_duration"])
	u.motion_lunge((_at - u.position).normalized(), MotionData.POWER_MELEE)
	var hit: Dictionary = {}  # Foes the smash struck (the quake skips them).
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(_at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var stuns := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.position.distance_to(_at) > r + e.radius:
			continue
		hit[e] = true
		if game.combat.stun_enemy(e, stun, STUN_BOSS, STUN_ELITE) > 0.0:
			stuns += 1
		game.combat.damage_enemy(e, dmg, SMASH_SOURCE, u.director.slot, u.position)
	var quake := float(u.special.get("quake_radius", 0.0))  # The Oni Lord's (0 for the Bound Oni).
	if quake > 0.0:
		var qd := dmg * float(u.special.get("quake_fraction", 0.5))
		var qh: Array = []
		game.enemy_grid.query(u.position, quake + ProjectileManager.MAX_BODY_RADIUS, qh)
		var n := 0
		for e: Enemy in qh:
			if not e.active or e.untargetable or hit.has(e) or e.position.distance_to(u.position) > quake + e.radius:
				continue
			var away := e.position - u.position
			e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.RIGHT) * QUAKE_KNOCKBACK / maxf(e.mass, 0.1)
			game.combat.damage_enemy(e, qd, QUAKE_SOURCE, u.director.slot, u.position)
			n += 1
		game.effects.art_ring(u.position, quake, Palette.BONE, 0.4, "stomp")
		game.stat_add("oni_lord_quakes", 1.0)
		game.stat_add("oni_lord_quake_hits", float(n))
	game.effects.impact(_at, r, Palette.BONE)
	Juice.fx.burst(_at, Palette.BONE, Palette.CORPSE_FLESH, 10, r * 2.0, 0.5, 3.0)
	game.shake(3.0)
	Sfx.play("abom_stomp", _at, 0.85)  # A startup-bank sound: the class plays on every stage.
	game.volleys.on_special(u, _at, _at + Vector2.RIGHT, dmg)  # Bullet heaven: stone shards.
	game.stat_add("bound_oni_smashes", 1.0)
	game.stat_add("bound_oni_smash_hits", float(hit.size()))
	game.stat_add("bound_oni_stuns", float(stuns))


## Telegraph: the circle where the club will land, filling in. Visual only.
func draw_under(u: SummonedUnit) -> void:
	if phase != WINDUP:
		return
	var r := float(u.special["smash_radius"])
	var k := clampf(phase_time / maxf(float(u.special["smash_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	var c := (_at - u.position) * Vector2(u.scale.x, 1.0)  # The circle's centre in the unit's (mirrored) frame.
	if AoeArt.telegraph(u, "mark_bone", c, r, k, Palette.CORPSE_FLESH, AoeArt.crack_for(r)):
		return  # Pixel-art rim marks and ground cracks (GDD §15.0 "Player AoE art").
	u.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.CORPSE_FLESH, 0.12 + 0.18 * k))
